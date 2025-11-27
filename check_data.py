#!/usr/bin/env python3
"""
Script para executar ETL diretamente (teste manual)
"""
import sys
sys.path.insert(0, '/home/marcogalter/olap/dags')

from etl_utils import get_dw_connection, get_row_count

def main():
    print("="*50)
    print("  Validação do Data Warehouse")
    print("="*50)
    print()
    
    conn = get_dw_connection()
    
    tables = [
        'dim_tempo',
        'dim_produto', 
        'dim_cliente',
        'dim_territorio',
        'dim_vendedor',
        'dim_metodo_envio',
        'fato_vendas'
    ]
    
    print("Contagem de registros:\n")
    
    for table in tables:
        try:
            count = get_row_count(conn, table)
            status = "✓" if count > 0 else "✗"
            print(f"{status} {table:20} {count:>10,} registros")
        except Exception as e:
            print(f"✗ {table:20} ERRO: {e}")
    
    conn.close()
    
    print()
    print("="*50)

if __name__ == '__main__':
    main()
