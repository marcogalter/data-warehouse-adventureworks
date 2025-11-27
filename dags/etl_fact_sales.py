"""
DAG para carregar a tabela fato de vendas
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from etl_utils import (
    get_source_connection, 
    get_dw_connection, 
    truncate_table,
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


def extract_and_load_fato_vendas(**context):
    """
    Extrai dados de vendas do source e carrega na tabela fato.
    Faz os JOINs necessários para obter as chaves das dimensões.
    """
    print("Iniciando carga da tabela fato de vendas...")
    
    conn_source = get_source_connection()
    conn_dw = get_dw_connection()
    
    # Query que extrai vendas e já calcula métricas
    query_extract = """
    SELECT 
        soh.salesorderid,
        sod.salesorderdetailid,
        soh.orderdate,
        soh.customerid,
        sod.productid,
        soh.territoryid,
        soh.salespersonid,
        soh.shipmethodid,
        sod.orderqty,
        sod.unitprice,
        sod.unitpricediscount,
        sod.orderqty * sod.unitprice as valor_bruto,
        sod.orderqty * sod.unitprice * sod.unitpricediscount as valor_desconto,
        sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount) as valor_liquido,
        p.standardcost,
        sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount) - (sod.orderqty * p.standardcost) as lucro_bruto,
        soh.subtotal,
        soh.taxamt,
        soh.freight,
        soh.totaldue,
        soh.onlineorderflag
    FROM sales.salesorderheader soh
    JOIN sales.salesorderdetail sod ON soh.salesorderid = sod.salesorderid
    JOIN production.product p ON sod.productid = p.productid
    WHERE soh.orderdate IS NOT NULL
    ORDER BY soh.salesorderid, sod.salesorderdetailid;
    """
    
    # Query para inserir na fato, fazendo lookup das chaves das dimensões
    query_insert = """
    INSERT INTO fato_vendas (
        tempo_id, cliente_id, produto_id, territorio_id, vendedor_id, metodo_envio_id,
        salesorder_id, salesorderdetail_id,
        quantidade, preco_unitario, desconto_unitario,
        valor_bruto, valor_desconto, valor_liquido,
        custo_produto, lucro_bruto,
        subtotal_pedido, taxa_pedido, frete_pedido, total_pedido,
        is_online
    )
    VALUES (
        (SELECT tempo_id FROM dim_tempo WHERE data = %s::DATE),
        (SELECT cliente_id FROM dim_cliente WHERE cliente_sk = %s),
        (SELECT produto_id FROM dim_produto WHERE produto_sk = %s),
        (SELECT territorio_id FROM dim_territorio WHERE territorio_sk = %s),
        (SELECT vendedor_id FROM dim_vendedor WHERE vendedor_sk = %s),
        (SELECT metodo_envio_id FROM dim_metodo_envio WHERE metodo_envio_sk = %s),
        %s, %s,
        %s, %s, %s,
        %s, %s, %s,
        %s, %s,
        %s, %s, %s, %s,
        %s
    )
    ON CONFLICT (salesorder_id, salesorderdetail_id) DO NOTHING;
    """
    
    try:
        # Truncar tabela fato
        truncate_table('fato_vendas')
        
        # Extração
        cur_source = conn_source.cursor()
        cur_source.execute(query_extract)
        
        # Processar e inserir em lotes
        cur_dw = conn_dw.cursor()
        batch_size = 1000
        batch = []
        total_rows = 0
        
        print("Processando e carregando vendas...")
        
        for row in cur_source:
            # Preparar tupla para inserção
            data_tuple = (
                row[2],   # orderdate
                row[3],   # customerid
                row[4],   # productid
                row[5],   # territoryid
                row[6],   # salespersonid
                row[7],   # shipmethodid
                row[0],   # salesorderid
                row[1],   # salesorderdetailid
                row[8],   # orderqty
                row[9],   # unitprice
                row[10],  # unitpricediscount
                row[11],  # valor_bruto
                row[12],  # valor_desconto
                row[13],  # valor_liquido
                row[14],  # standardcost
                row[15],  # lucro_bruto
                row[16],  # subtotal
                row[17],  # taxamt
                row[18],  # freight
                row[19],  # totaldue
                row[20],  # onlineorderflag
            )
            
            batch.append(data_tuple)
            
            # Inserir quando atingir o tamanho do lote
            if len(batch) >= batch_size:
                for item in batch:
                    try:
                        cur_dw.execute(query_insert, item)
                    except Exception as e:
                        print(f"⚠ Erro ao inserir registro: {e}")
                        continue
                
                conn_dw.commit()
                total_rows += len(batch)
                print(f"✓ {total_rows} registros processados...")
                batch = []
        
        # Inserir registros restantes
        if batch:
            for item in batch:
                try:
                    cur_dw.execute(query_insert, item)
                except Exception as e:
                    print(f"⚠ Erro ao inserir registro: {e}")
                    continue
            
            conn_dw.commit()
            total_rows += len(batch)
        
        cur_source.close()
        cur_dw.close()
        
        # Contar registros finais
        final_count = get_row_count(conn_dw, 'fato_vendas')
        log_etl_execution('etl_fact_sales', 'load_fato_vendas', 'SUCCESS', final_count)
        print(f"✓ Fato Vendas: {final_count} registros carregados com sucesso!")
        
    except Exception as e:
        log_etl_execution('etl_fact_sales', 'load_fato_vendas', 'ERROR', 0, str(e))
        raise
    finally:
        conn_source.close()
        conn_dw.close()


def validate_fato_vendas(**context):
    """Valida a carga da tabela fato"""
    print("Validando carga da tabela fato...")
    
    conn_dw = get_dw_connection()
    
    try:
        cur = conn_dw.cursor()
        
        # Validação 1: Total de registros
        cur.execute("SELECT COUNT(*) FROM fato_vendas")
        total = cur.fetchone()[0]
        print(f"✓ Total de vendas: {total}")
        
        # Validação 2: Vendas com valores nulos
        cur.execute("SELECT COUNT(*) FROM fato_vendas WHERE valor_liquido IS NULL")
        nulls = cur.fetchone()[0]
        print(f"✓ Registros com valor_liquido NULL: {nulls}")
        
        # Validação 3: Receita total
        cur.execute("SELECT SUM(valor_liquido) FROM fato_vendas")
        receita = cur.fetchone()[0]
        print(f"✓ Receita total: R$ {receita:,.2f}")
        
        # Validação 4: Lucro total
        cur.execute("SELECT SUM(lucro_bruto) FROM fato_vendas WHERE lucro_bruto IS NOT NULL")
        lucro = cur.fetchone()[0]
        print(f"✓ Lucro bruto total: R$ {lucro:,.2f}")
        
        # Validação 5: Quantidade de pedidos únicos
        cur.execute("SELECT COUNT(DISTINCT salesorder_id) FROM fato_vendas")
        pedidos = cur.fetchone()[0]
        print(f"✓ Pedidos únicos: {pedidos}")
        
        # Validação 6: Produtos únicos vendidos
        cur.execute("SELECT COUNT(DISTINCT produto_id) FROM fato_vendas")
        produtos = cur.fetchone()[0]
        print(f"✓ Produtos únicos vendidos: {produtos}")
        
        # Validação 7: Clientes únicos
        cur.execute("SELECT COUNT(DISTINCT cliente_id) FROM fato_vendas")
        clientes = cur.fetchone()[0]
        print(f"✓ Clientes únicos: {clientes}")
        
        cur.close()
        
        print("\n✅ Validação concluída com sucesso!")
        log_etl_execution('etl_fact_sales', 'validate_fato_vendas', 'SUCCESS', 0)
        
    except Exception as e:
        log_etl_execution('etl_fact_sales', 'validate_fato_vendas', 'ERROR', 0, str(e))
        raise
    finally:
        conn_dw.close()


# Definição da DAG
with DAG(
    'etl_fact_sales',
    default_args=default_args,
    description='ETL para carregar tabela fato de vendas',
    schedule_interval=None,  # Manual trigger
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'fact', 'sales', 'adventureworks'],
) as dag:
    
    task_load_fato = PythonOperator(
        task_id='load_fato_vendas',
        python_callable=extract_and_load_fato_vendas,
    )
    
    task_validate = PythonOperator(
        task_id='validate_fato_vendas',
        python_callable=validate_fato_vendas,
    )
    
    # Dependência: validar após carregar
    task_load_fato >> task_validate
