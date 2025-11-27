"""
Funções auxiliares para os processos ETL
"""
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import execute_batch


def get_source_connection():
    """Conexão com banco fonte (AdventureWorks original)"""
    return psycopg2.connect(
        host='postgres-source',
        port=5432,
        database='adventureworks',
        user='source_user',
        password='source_password'
    )


def get_dw_connection():
    """Conexão com Data Warehouse"""
    return psycopg2.connect(
        host='postgres-dw',
        port=5432,
        database='adventureworks_dw',
        user='dw_user',
        password='dw_password'
    )


def truncate_table(table_name):
    """Trunca uma tabela no DW (para recargas full)"""
    conn = get_dw_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"TRUNCATE TABLE {table_name} CASCADE;")
        conn.commit()
        print(f"✓ Tabela {table_name} truncada com sucesso")
    except Exception as e:
        conn.rollback()
        print(f"✗ Erro ao truncar {table_name}: {e}")
        raise
    finally:
        cur.close()
        conn.close()


def execute_query(connection, query, params=None):
    """Executa uma query e retorna os resultados"""
    cur = connection.cursor()
    try:
        if params:
            cur.execute(query, params)
        else:
            cur.execute(query)
        if cur.description:  # Se é uma query SELECT
            return cur.fetchall()
        else:  # Se é INSERT, UPDATE, DELETE
            connection.commit()
            return cur.rowcount
    except Exception as e:
        connection.rollback()
        raise e
    finally:
        cur.close()


def bulk_insert(connection, table_name, columns, data, batch_size=1000):
    """Insere dados em lote para melhor performance"""
    if not data:
        print(f"⚠ Nenhum dado para inserir em {table_name}")
        return 0
    
    placeholders = ','.join(['%s'] * len(columns))
    columns_str = ','.join(columns)
    query = f"INSERT INTO {table_name} ({columns_str}) VALUES ({placeholders})"
    
    cur = connection.cursor()
    try:
        execute_batch(cur, query, data, page_size=batch_size)
        connection.commit()
        rows_inserted = len(data)
        print(f"✓ {rows_inserted} registros inseridos em {table_name}")
        return rows_inserted
    except Exception as e:
        connection.rollback()
        print(f"✗ Erro ao inserir em {table_name}: {e}")
        raise
    finally:
        cur.close()


def get_row_count(connection, table_name):
    """Retorna quantidade de registros em uma tabela"""
    cur = connection.cursor()
    try:
        cur.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cur.fetchone()[0]
        return count
    finally:
        cur.close()


def log_etl_execution(dag_id, task_id, status, rows_processed=0, error_message=None):
    """Log de execução do ETL (pode ser expandido para tabela de auditoria)"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] DAG: {dag_id} | Task: {task_id} | Status: {status} | Rows: {rows_processed}")
    if error_message:
        print(f"[ERROR] {error_message}")
