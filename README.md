# 🏢 Data Warehouse AdventureWorks - Projeto Acadêmico

## 📖 Descrição
Projeto acadêmico de construção de um Data Warehouse completo com processos ETL automatizados utilizando Apache Airflow. Baseado no banco de dados AdventureWorks (empresa fictícia de venda de bicicletas), este projeto implementa um modelo dimensional (esquema estrela) para análise de vendas.

## 🎯 Objetivo
Construir um Data Warehouse funcional que permita análise de dados de vendas através de 10 indicadores-chave (KPIs), demonstrando:
- Modelagem dimensional
- Processos ETL automatizados
- Cálculo de métricas de negócio
- Boas práticas de engenharia de dados

## 🛠️ Tecnologias Utilizadas
- **PostgreSQL 15** - Banco de dados relacional
- **Apache Airflow 2.7.3** - Orquestração de workflows ETL
- **Python 3.11** - Linguagem de programação para ETL
- **Docker & Docker Compose** - Containerização
- **psycopg2** - Driver Python para PostgreSQL

## 🏗️ Arquitetura do Projeto

### Bancos de Dados
1. **postgres-source (porta 5435)** - Banco fonte com dados originais do AdventureWorks
2. **postgres-dw (porta 5434)** - Data Warehouse com modelo dimensional
3. **postgres-airflow (porta 5433)** - Metadados do Airflow

### Modelo Dimensional (Esquema Estrela)

**Dimensões:**
- 🗓️ `dim_tempo` - Dimensão temporal (2011-2014)
- 📦 `dim_produto` - Produtos comercializados
- 👤 `dim_cliente` - Clientes (individuais e lojas)
- 🌍 `dim_territorio` - Regiões de vendas
- 👔 `dim_vendedor` - Vendedores
- 🚚 `dim_metodo_envio` - Métodos de entrega

**Fato:**
- 💰 `fato_vendas` - Transações de vendas com métricas

## 📊 10 Indicadores (KPIs) Implementados

1. **Total de vendas por região** - Receita e lucro por território
2. **Produtos mais vendidos (Top 20)** - Ranking por quantidade e receita
3. **Ticket médio por cliente** - Valor médio gasto por cliente
4. **Taxa de crescimento mensal** - Variação percentual mês a mês
5. **Margem de lucro por categoria** - Rentabilidade por categoria de produto
6. **Taxa de conversão online** - Percentual de pedidos online vs total
7. **Clientes mais valiosos (Top 10)** - Maiores geradores de receita
8. **Desempenho de vendedores** - Performance individual de vendedores
9. **Sazonalidade de vendas** - Padrões ao longo dos meses
10. **Vendas por dia da semana** - Análise de demanda por dia

## 🚀 Como Executar

### Pré-requisitos
- Docker instalado
- Docker Compose instalado
- 4GB de RAM disponível
- 10GB de espaço em disco

### 1. Subir o ambiente
```bash
cd /home/marcogalter/olap
docker-compose up -d
```

Aguarde 2-3 minutos para todos os serviços iniciarem.

### 2. Verificar containers
```bash
docker-compose ps
```

Todos devem estar com status "Up".

### 3. Acessar o Airflow
- **URL:** http://localhost:8080
- **Usuário:** `admin`
- **Senha:** `admin`

### 4. Executar ETL

**Passo 1:** Execute a DAG `etl_dimensions`
- Carrega todas as dimensões
- Tempo estimado: 1-2 minutos

**Passo 2:** Execute a DAG `etl_fact_sales`
- Carrega a tabela fato de vendas
- Tempo estimado: 2-3 minutos
- ⚠️ **Só execute após a DAG de dimensões ter sucesso!**

### 5. Consultar KPIs
```bash
# Conectar no Data Warehouse
docker exec -it olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw

# Executar queries de KPIs
\i /opt/airflow/sql/03_kpis_queries.sql
```

## 📁 Estrutura do Projeto
```
olap/
├── dags/
│   ├── etl_dimensions.py          # DAG: Carga de dimensões
│   ├── etl_fact_sales.py          # DAG: Carga da tabela fato
│   └── etl_utils.py               # Funções auxiliares para ETL
├── sql/
│   ├── 01_create_dimensions.sql   # DDL das tabelas dimensionais
│   ├── 02_create_fact_table.sql   # DDL da tabela fato e views
│   └── 03_kpis_queries.sql        # Queries dos 10 KPIs
├── docs/
│   ├── GUIA_EXECUCAO.md          # Guia detalhado de execução
│   └── DICIONARIO_DADOS.md       # Dicionário completo de dados
├── data/
│   └── adventureworks.sql         # Dump do banco fonte
├── logs/                          # Logs do Airflow
├── plugins/                       # Plugins customizados
├── docker-compose.yml             # Orquestração dos containers
├── .gitignore                     # Arquivos ignorados pelo Git
└── README.md                      # Este arquivo
```

## 📈 Validação de Dados

Execute para validar a carga:
```bash
docker exec olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw -c "
SELECT 'dim_tempo' as tabela, COUNT(*) as registros FROM dim_tempo
UNION ALL SELECT 'dim_produto', COUNT(*) FROM dim_produto
UNION ALL SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL SELECT 'dim_territorio', COUNT(*) FROM dim_territorio
UNION ALL SELECT 'dim_vendedor', COUNT(*) FROM dim_vendedor
UNION ALL SELECT 'dim_metodo_envio', COUNT(*) FROM dim_metodo_envio
UNION ALL SELECT 'fato_vendas', COUNT(*) FROM fato_vendas;
"
```

**Valores esperados:**
- dim_tempo: ~1,461 registros
- dim_produto: ~504 registros
- dim_cliente: ~19,820 registros
- dim_territorio: 10 registros
- dim_vendedor: 17 registros
- dim_metodo_envio: 5 registros
- fato_vendas: ~121,317 registros

## 🔧 Troubleshooting

### Containers não sobem
```bash
docker-compose down
docker-compose up -d
```

### DAGs não aparecem no Airflow
```bash
docker-compose restart airflow-scheduler
```

### Resetar dados do DW
```bash
docker exec olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw -c "
TRUNCATE TABLE fato_vendas CASCADE;
TRUNCATE TABLE dim_tempo CASCADE;
TRUNCATE TABLE dim_produto CASCADE;
TRUNCATE TABLE dim_cliente CASCADE;
TRUNCATE TABLE dim_territorio CASCADE;
TRUNCATE TABLE dim_vendedor CASCADE;
TRUNCATE TABLE dim_metodo_envio CASCADE;
"
```

### Ver logs do Airflow
```bash
docker-compose logs -f airflow-scheduler
docker-compose logs -f airflow-webserver
```

## 📚 Documentação Adicional

- **[Guia de Execução Completo](docs/GUIA_EXECUCAO.md)** - Instruções detalhadas
- **[Dicionário de Dados](docs/DICIONARIO_DADOS.md)** - Descrição completa das tabelas

