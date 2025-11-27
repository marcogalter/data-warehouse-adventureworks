# 🚀 Guia de Execução do Projeto

## 📊 Modelo Dimensional

### Dimensões
1. **dim_tempo** - Dimensão temporal (2011-2014)
2. **dim_produto** - Produtos da empresa
3. **dim_cliente** - Clientes (individuais e lojas)
4. **dim_territorio** - Regiões de venda
5. **dim_vendedor** - Vendedores da empresa
6. **dim_metodo_envio** - Métodos de entrega

### Fato
**fato_vendas** - Vendas realizadas com métricas de receita, lucro, quantidade, etc.

---

## 🔧 Como Executar o ETL

### 1. Acessar o Airflow
```
URL: http://localhost:8080
Usuário: admin
Senha: admin
```

### 2. Executar ETL das Dimensões
1. No Airflow, localize a DAG **`etl_dimensions`**
2. Clique no botão de "Play" (▶️) à direita
3. Selecione **"Trigger DAG"**
4. Aguarde a execução (leva cerca de 1-2 minutos)
5. Verifique se todas as tarefas ficaram verdes ✅

**Ordem de execução das tarefas:**
- load_dim_tempo
- load_dim_produto
- load_dim_cliente
- load_dim_territorio
- load_dim_vendedor
- load_dim_metodo_envio

### 3. Executar ETL da Tabela Fato
**⚠️ IMPORTANTE: Só execute após a DAG de dimensões ter sucesso!**

1. Localize a DAG **`etl_fact_sales`**
2. Clique no botão de "Play" (▶️)
3. Selecione **"Trigger DAG"**
4. Aguarde a execução (leva cerca de 2-3 minutos)
5. Verifique se as tarefas ficaram verdes ✅

**Tarefas executadas:**
- load_fato_vendas (carrega dados de vendas)
- validate_fato_vendas (valida a carga)

---

## 📈 10 Indicadores (KPIs) Implementados

### 1. Total de vendas por região
Receita, lucro e quantidade de pedidos por território de vendas.

### 2. Produtos mais vendidos (Top 20)
Ranking de produtos por quantidade vendida e receita gerada.

### 3. Ticket médio por cliente
Valor médio gasto por cada cliente.

### 4. Taxa de crescimento mensal de vendas
Comparação mês a mês do crescimento de receita (%).

### 5. Margem de lucro por categoria de produto
Rentabilidade de cada categoria de produto.

### 6. Taxa de conversão de pedidos online
Percentual de pedidos feitos online vs total.

### 7. Clientes mais valiosos (Top 10)
Clientes que mais geraram receita.

### 8. Desempenho de vendedores
Performance individual de cada vendedor.

### 9. Sazonalidade de vendas
Padrões de venda ao longo dos meses do ano.

### 10. Análise por dia da semana
Em quais dias há mais vendas.

---

## 🔍 Como Executar os KPIs

### Opção 1: Via Terminal
```bash
# Conectar no banco DW
docker exec -it olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw

# Executar qualquer query do arquivo 03_kpis_queries.sql
# Exemplo: Total de vendas por região
SELECT 
    dter.nome as territorio,
    SUM(fv.valor_liquido) as receita_total
FROM fato_vendas fv
LEFT JOIN dim_territorio dter ON fv.territorio_id = dter.territorio_id
GROUP BY dter.nome
ORDER BY receita_total DESC;
```

### Opção 2: Executar arquivo completo
```bash
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < sql/03_kpis_queries.sql
```

---

## ✅ Checklist de Validação

Após executar as DAGs, valide:

- [ ] Dimensão Tempo tem ~1461 registros (4 anos)
- [ ] Dimensão Produto tem ~504 produtos
- [ ] Dimensão Cliente tem ~19000+ clientes
- [ ] Dimensão Território tem 10 territórios
- [ ] Dimensão Vendedor tem 17 vendedores
- [ ] Dimensão Método Envio tem 5 métodos
- [ ] Fato Vendas tem ~121000+ registros
- [ ] Todas as queries de KPI executam sem erro

### Comandos de Validação Rápida
```bash
# Ver quantidade de registros em cada tabela
docker exec olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw -c "
SELECT 'dim_tempo' as tabela, COUNT(*) as registros FROM dim_tempo
UNION ALL
SELECT 'dim_produto', COUNT(*) FROM dim_produto
UNION ALL
SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL
SELECT 'dim_territorio', COUNT(*) FROM dim_territorio
UNION ALL
SELECT 'dim_vendedor', COUNT(*) FROM dim_vendedor
UNION ALL
SELECT 'dim_metodo_envio', COUNT(*) FROM dim_metodo_envio
UNION ALL
SELECT 'fato_vendas', COUNT(*) FROM fato_vendas;
"
```

---

## 🐛 Troubleshooting

### DAG não aparece no Airflow
```bash
# Reiniciar scheduler
docker-compose restart airflow-scheduler
```

### Erro de conexão com banco
```bash
# Verificar se containers estão rodando
docker-compose ps

# Ver logs
docker-compose logs postgres-dw
docker-compose logs postgres-source
```

### Limpar dados e reexecutar
```bash
# Truncar todas as tabelas
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

---

## 📁 Estrutura de Arquivos

```
olap/
├── dags/
│   ├── etl_dimensions.py      # DAG para carregar dimensões
│   ├── etl_fact_sales.py      # DAG para carregar fato
│   └── etl_utils.py           # Funções auxiliares
├── sql/
│   ├── 01_create_dimensions.sql   # DDL das dimensões
│   ├── 02_create_fact_table.sql   # DDL da tabela fato
│   └── 03_kpis_queries.sql        # Queries dos 10 KPIs
├── docs/                      # Documentação adicional
├── data/                      # Dados fonte
├── docker-compose.yml         # Configuração dos containers
└── README.md                  # Este arquivo
```

---

## 📊 Para o Artigo Acadêmico

### Prints Necessários
1. ✅ Diagrama do modelo estrela (pode fazer no draw.io ou lucidchart)
2. ✅ Print das DAGs no Airflow (Graph View)
3. ✅ Print das execuções bem-sucedidas (verde)
4. ✅ Print dos resultados de pelo menos 3 KPIs
5. ✅ Estrutura das tabelas (pode usar \d no psql)

### Seções do Artigo
**Introdução**
- Contexto do Data Warehouse
- Objetivos do projeto
- Justificativa dos KPIs escolhidos

**Desenvolvimento**
- Análise do banco AdventureWorks
- Modelo dimensional proposto (diagrama estrela)
- Dicionário de dados
- Descrição do processo ETL
- Implementação no Apache Airflow
- Resultados dos KPIs

**Considerações Finais**
- Desafios enfrentados
- Resultados obtidos
- Possíveis melhorias futuras

---

## 🔗 Links Úteis
- Airflow: http://localhost:8080
- PostgreSQL DW: localhost:5434
- PostgreSQL Source: localhost:5435
- Repositório GitHub: [seu-link-aqui]
