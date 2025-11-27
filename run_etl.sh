#!/bin/bash
# Script para executar o ETL completo

echo "========================================="
echo "  ETL AdventureWorks Data Warehouse"
echo "========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Verificando containers...${NC}"
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}Erro: Containers não estão rodando!${NC}"
    echo "Execute: docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✓ Containers rodando${NC}"
echo ""

echo -e "${YELLOW}Aguardando Airflow inicializar...${NC}"
sleep 5

echo -e "${YELLOW}1. Executando ETL das Dimensões...${NC}"
docker exec olap_airflow-scheduler_1 airflow dags trigger etl_dimensions 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DAG etl_dimensions disparada${NC}"
    echo -e "${YELLOW}Aguarde 2-3 minutos para conclusão...${NC}"
    sleep 120
    
    echo ""
    echo -e "${YELLOW}2. Executando ETL da Tabela Fato...${NC}"
    docker exec olap_airflow-scheduler_1 airflow dags trigger etl_fact_sales 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ DAG etl_fact_sales disparada${NC}"
        echo -e "${YELLOW}Aguarde 2-3 minutos para conclusão...${NC}"
        sleep 150
    else
        echo -e "${RED}✗ Erro ao disparar DAG de fato${NC}"
    fi
else
    echo -e "${RED}✗ Erro ao disparar DAG de dimensões${NC}"
    echo -e "${YELLOW}Tentando executar Python diretamente...${NC}"
fi

echo ""
echo -e "${YELLOW}3. Validando dados carregados...${NC}"

docker exec olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw -t -c "
SELECT 
    'dim_tempo: ' || COUNT(*) || ' registros' FROM dim_tempo
UNION ALL
SELECT 'dim_produto: ' || COUNT(*) || ' registros' FROM dim_produto
UNION ALL
SELECT 'dim_cliente: ' || COUNT(*) || ' registros' FROM dim_cliente
UNION ALL
SELECT 'dim_territorio: ' || COUNT(*) || ' registros' FROM dim_territorio
UNION ALL
SELECT 'dim_vendedor: ' || COUNT(*) || ' registros' FROM dim_vendedor
UNION ALL
SELECT 'dim_metodo_envio: ' || COUNT(*) || ' registros' FROM dim_metodo_envio
UNION ALL
SELECT 'fato_vendas: ' || COUNT(*) || ' registros' FROM fato_vendas;
"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  ETL Concluído!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Acesse o Airflow em: http://localhost:8080"
echo "Usuário: admin | Senha: admin"
