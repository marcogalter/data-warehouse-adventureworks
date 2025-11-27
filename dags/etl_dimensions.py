"""
DAG para carregar as tabelas de dimensões do Data Warehouse
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from etl_utils import (
    get_source_connection, 
    get_dw_connection, 
    truncate_table, 
    bulk_insert,
    get_row_count,
    log_etl_execution
)

# Configurações padrão da DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}


def extract_and_load_dim_tempo(**context):
    """Popula dimensão tempo com datas de 2011 a 2014"""
    print("Iniciando carga da dimensão tempo...")
    
    conn_dw = get_dw_connection()
    
    query = """
    INSERT INTO dim_tempo (data, ano, trimestre, mes, mes_nome, dia, dia_semana, dia_semana_nome, semana_ano, is_fim_semana)
    SELECT 
        date_series::DATE as data,
        EXTRACT(YEAR FROM date_series) as ano,
        EXTRACT(QUARTER FROM date_series) as trimestre,
        EXTRACT(MONTH FROM date_series) as mes,
        TO_CHAR(date_series, 'Month') as mes_nome,
        EXTRACT(DAY FROM date_series) as dia,
        EXTRACT(DOW FROM date_series) as dia_semana,
        TO_CHAR(date_series, 'Day') as dia_semana_nome,
        EXTRACT(WEEK FROM date_series) as semana_ano,
        CASE WHEN EXTRACT(DOW FROM date_series) IN (0, 6) THEN TRUE ELSE FALSE END as is_fim_semana
    FROM generate_series('2011-01-01'::DATE, '2014-12-31'::DATE, '1 day'::INTERVAL) as date_series
    ON CONFLICT (data) DO NOTHING;
    """
    
    try:
        cur = conn_dw.cursor()
        cur.execute(query)
        conn_dw.commit()
        rows = cur.rowcount
        cur.close()
        
        total = get_row_count(conn_dw, 'dim_tempo')
        log_etl_execution('etl_dimensions', 'load_dim_tempo', 'SUCCESS', rows)
        print(f"✓ Dimensão Tempo: {total} registros no total")
    except Exception as e:
        conn_dw.rollback()
        log_etl_execution('etl_dimensions', 'load_dim_tempo', 'ERROR', 0, str(e))
        raise
    finally:
        conn_dw.close()


def extract_and_load_dim_produto(**context):
    """Extrai produtos do source e carrega no DW"""
    print("Iniciando carga da dimensão produto...")
    
    conn_source = get_source_connection()
    conn_dw = get_dw_connection()
    
    query_extract = """
    SELECT 
        p.productid,
        p.name as nome_produto,
        p.productnumber,
        pc.name as categoria,
        psc.name as subcategoria,
        p.color,
        p.size,
        p.weight,
        p.class,
        p.style,
        p.productline,
        p.standardcost,
        p.listprice
    FROM production.product p
    LEFT JOIN production.productsubcategory psc ON p.productsubcategoryid = psc.productsubcategoryid
    LEFT JOIN production.productcategory pc ON psc.productcategoryid = pc.productcategoryid
    WHERE p.productid IS NOT NULL
    ORDER BY p.productid;
    """
    
    try:
        # Extração
        cur_source = conn_source.cursor()
        cur_source.execute(query_extract)
        produtos = cur_source.fetchall()
        cur_source.close()
        
        print(f"✓ Extraídos {len(produtos)} produtos do source")
        
        # Truncar tabela destino
        truncate_table('dim_produto')
        
        # Preparar dados para inserção
        columns = [
            'produto_sk', 'nome_produto', 'numero_produto', 'categoria', 'subcategoria',
            'cor', 'tamanho', 'peso', 'classe', 'estilo', 'linha_produto',
            'custo_padrao', 'preco_lista'
        ]
        
        # Load
        rows = bulk_insert(conn_dw, 'dim_produto', columns, produtos)
        
        total = get_row_count(conn_dw, 'dim_produto')
        log_etl_execution('etl_dimensions', 'load_dim_produto', 'SUCCESS', rows)
        print(f"✓ Dimensão Produto: {total} registros carregados")
        
    except Exception as e:
        log_etl_execution('etl_dimensions', 'load_dim_produto', 'ERROR', 0, str(e))
        raise
    finally:
        conn_source.close()
        conn_dw.close()


def extract_and_load_dim_cliente(**context):
    """Extrai clientes do source e carrega no DW"""
    print("Iniciando carga da dimensão cliente...")
    
    conn_source = get_source_connection()
    conn_dw = get_dw_connection()
    
    query_extract = """
    SELECT 
        c.customerid,
        CASE 
            WHEN c.personid IS NOT NULL THEN 'Individual'
            ELSE 'Store'
        END as tipo_cliente,
        COALESCE(
            p.firstname || ' ' || COALESCE(p.middlename || ' ', '') || p.lastname,
            s.name
        ) as nome_completo,
        st.name as territory_name
    FROM sales.customer c
    LEFT JOIN person.person p ON c.personid = p.businessentityid
    LEFT JOIN sales.store s ON c.storeid = s.businessentityid
    LEFT JOIN sales.salesterritory st ON c.territoryid = st.territoryid
    WHERE c.customerid IS NOT NULL
    ORDER BY c.customerid;
    """
    
    try:
        # Extração
        cur_source = conn_source.cursor()
        cur_source.execute(query_extract)
        clientes = cur_source.fetchall()
        cur_source.close()
        
        print(f"✓ Extraídos {len(clientes)} clientes do source")
        
        # Truncar tabela destino
        truncate_table('dim_cliente')
        
        # Preparar dados
        columns = ['cliente_sk', 'tipo_cliente', 'nome_completo', 'territory_name']
        
        # Load
        rows = bulk_insert(conn_dw, 'dim_cliente', columns, clientes)
        
        total = get_row_count(conn_dw, 'dim_cliente')
        log_etl_execution('etl_dimensions', 'load_dim_cliente', 'SUCCESS', rows)
        print(f"✓ Dimensão Cliente: {total} registros carregados")
        
    except Exception as e:
        log_etl_execution('etl_dimensions', 'load_dim_cliente', 'ERROR', 0, str(e))
        raise
    finally:
        conn_source.close()
        conn_dw.close()


def extract_and_load_dim_territorio(**context):
    """Extrai territórios do source e carrega no DW"""
    print("Iniciando carga da dimensão território...")
    
    conn_source = get_source_connection()
    conn_dw = get_dw_connection()
    
    query_extract = """
    SELECT 
        territoryid,
        name,
        countryregioncode,
        "group"
    FROM sales.salesterritory
    ORDER BY territoryid;
    """
    
    try:
        # Extração
        cur_source = conn_source.cursor()
        cur_source.execute(query_extract)
        territorios = cur_source.fetchall()
        cur_source.close()
        
        print(f"✓ Extraídos {len(territorios)} territórios do source")
        
        # Truncar tabela destino
        truncate_table('dim_territorio')
        
        # Preparar dados
        columns = ['territorio_sk', 'nome', 'country_code', 'grupo']
        
        # Load
        rows = bulk_insert(conn_dw, 'dim_territorio', columns, territorios)
        
        total = get_row_count(conn_dw, 'dim_territorio')
        log_etl_execution('etl_dimensions', 'load_dim_territorio', 'SUCCESS', rows)
        print(f"✓ Dimensão Território: {total} registros carregados")
        
    except Exception as e:
        log_etl_execution('etl_dimensions', 'load_dim_territorio', 'ERROR', 0, str(e))
        raise
    finally:
        conn_source.close()
        conn_dw.close()


def extract_and_load_dim_vendedor(**context):
    """Extrai vendedores do source e carrega no DW"""
    print("Iniciando carga da dimensão vendedor...")
    
    conn_source = get_source_connection()
    conn_dw = get_dw_connection()
    
    query_extract = """
    SELECT 
        sp.businessentityid,
        p.firstname || ' ' || COALESCE(p.middlename || ' ', '') || p.lastname as nome_completo,
        e.jobtitle as cargo,
        st.name as territorio_nome
    FROM sales.salesperson sp
    JOIN humanresources.employee e ON sp.businessentityid = e.businessentityid
    JOIN person.person p ON sp.businessentityid = p.businessentityid
    LEFT JOIN sales.salesterritory st ON sp.territoryid = st.territoryid
    ORDER BY sp.businessentityid;
    """
    
    try:
        # Extração
        cur_source = conn_source.cursor()
        cur_source.execute(query_extract)
        vendedores = cur_source.fetchall()
        cur_source.close()
        
        print(f"✓ Extraídos {len(vendedores)} vendedores do source")
        
        # Truncar tabela destino
        truncate_table('dim_vendedor')
        
        # Preparar dados
        columns = ['vendedor_sk', 'nome_completo', 'cargo', 'territorio_nome']
        
        # Load
        rows = bulk_insert(conn_dw, 'dim_vendedor', columns, vendedores)
        
        total = get_row_count(conn_dw, 'dim_vendedor')
        log_etl_execution('etl_dimensions', 'load_dim_vendedor', 'SUCCESS', rows)
        print(f"✓ Dimensão Vendedor: {total} registros carregados")
        
    except Exception as e:
        log_etl_execution('etl_dimensions', 'load_dim_vendedor', 'ERROR', 0, str(e))
        raise
    finally:
        conn_source.close()
        conn_dw.close()


def extract_and_load_dim_metodo_envio(**context):
    """Extrai métodos de envio do source e carrega no DW"""
    print("Iniciando carga da dimensão método de envio...")
    
    conn_source = get_source_connection()
    conn_dw = get_dw_connection()
    
    query_extract = """
    SELECT 
        shipmethodid,
        name,
        shipbase
    FROM purchasing.shipmethod
    ORDER BY shipmethodid;
    """
    
    try:
        # Extração
        cur_source = conn_source.cursor()
        cur_source.execute(query_extract)
        metodos = cur_source.fetchall()
        cur_source.close()
        
        print(f"✓ Extraídos {len(metodos)} métodos de envio do source")
        
        # Truncar tabela destino
        truncate_table('dim_metodo_envio')
        
        # Preparar dados
        columns = ['metodo_envio_sk', 'nome', 'custo_base']
        
        # Load
        rows = bulk_insert(conn_dw, 'dim_metodo_envio', columns, metodos)
        
        total = get_row_count(conn_dw, 'dim_metodo_envio')
        log_etl_execution('etl_dimensions', 'load_dim_metodo_envio', 'SUCCESS', rows)
        print(f"✓ Dimensão Método Envio: {total} registros carregados")
        
    except Exception as e:
        log_etl_execution('etl_dimensions', 'load_dim_metodo_envio', 'ERROR', 0, str(e))
        raise
    finally:
        conn_source.close()
        conn_dw.close()


# Definição da DAG
with DAG(
    'etl_dimensions',
    default_args=default_args,
    description='ETL para carregar dimensões do Data Warehouse',
    schedule_interval=None,  # Manual trigger
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'dimensions', 'adventureworks'],
) as dag:
    
    task_dim_tempo = PythonOperator(
        task_id='load_dim_tempo',
        python_callable=extract_and_load_dim_tempo,
    )
    
    task_dim_produto = PythonOperator(
        task_id='load_dim_produto',
        python_callable=extract_and_load_dim_produto,
    )
    
    task_dim_cliente = PythonOperator(
        task_id='load_dim_cliente',
        python_callable=extract_and_load_dim_cliente,
    )
    
    task_dim_territorio = PythonOperator(
        task_id='load_dim_territorio',
        python_callable=extract_and_load_dim_territorio,
    )
    
    task_dim_vendedor = PythonOperator(
        task_id='load_dim_vendedor',
        python_callable=extract_and_load_dim_vendedor,
    )
    
    task_dim_metodo_envio = PythonOperator(
        task_id='load_dim_metodo_envio',
        python_callable=extract_and_load_dim_metodo_envio,
    )
    
    # Definir dependências - todas as dimensões podem rodar em paralelo
    # Mas vamos executar em sequência para evitar sobrecarga
    task_dim_tempo >> task_dim_produto >> task_dim_cliente >> task_dim_territorio >> task_dim_vendedor >> task_dim_metodo_envio
