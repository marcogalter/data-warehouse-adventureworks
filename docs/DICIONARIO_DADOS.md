# 📚 Dicionário de Dados - Data Warehouse AdventureWorks

## 🔷 Dimensões

### dim_tempo
**Descrição:** Dimensão temporal contendo todos os dias do período de análise (2011-2014).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| tempo_id | SERIAL (PK) | Chave primária surrogate |
| data | DATE (UNIQUE) | Data específica |
| ano | INTEGER | Ano (2011-2014) |
| trimestre | INTEGER | Trimestre do ano (1-4) |
| mes | INTEGER | Mês do ano (1-12) |
| mes_nome | VARCHAR(20) | Nome do mês por extenso |
| dia | INTEGER | Dia do mês (1-31) |
| dia_semana | INTEGER | Dia da semana (0=Domingo, 6=Sábado) |
| dia_semana_nome | VARCHAR(20) | Nome do dia da semana |
| semana_ano | INTEGER | Número da semana no ano |
| is_fim_semana | BOOLEAN | Indica se é fim de semana |
| created_at | TIMESTAMP | Data de criação do registro |

---

### dim_produto
**Descrição:** Dimensão contendo informações sobre os produtos comercializados.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| produto_id | SERIAL (PK) | Chave primária surrogate |
| produto_sk | INTEGER (UNIQUE) | Chave natural do sistema fonte |
| nome_produto | VARCHAR(200) | Nome do produto |
| numero_produto | VARCHAR(50) | Código/número do produto |
| categoria | VARCHAR(100) | Categoria principal (ex: Bikes, Accessories) |
| subcategoria | VARCHAR(100) | Subcategoria do produto |
| cor | VARCHAR(50) | Cor do produto |
| tamanho | VARCHAR(20) | Tamanho (S, M, L, etc.) |
| peso | NUMERIC(10,2) | Peso em unidades de medida |
| classe | VARCHAR(10) | Classe do produto (H, M, L) |
| estilo | VARCHAR(10) | Estilo (W, M, U) |
| linha_produto | VARCHAR(50) | Linha de produto |
| custo_padrao | NUMERIC(19,4) | Custo padrão de produção |
| preco_lista | NUMERIC(19,4) | Preço de lista sugerido |
| created_at | TIMESTAMP | Data de criação do registro |
| updated_at | TIMESTAMP | Data da última atualização |

---

### dim_cliente
**Descrição:** Dimensão contendo informações sobre os clientes.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| cliente_id | SERIAL (PK) | Chave primária surrogate |
| cliente_sk | INTEGER (UNIQUE) | Chave natural do sistema fonte |
| tipo_cliente | VARCHAR(50) | Tipo: Individual ou Store |
| nome_completo | VARCHAR(200) | Nome completo do cliente |
| territory_name | VARCHAR(100) | Nome do território do cliente |
| created_at | TIMESTAMP | Data de criação do registro |
| updated_at | TIMESTAMP | Data da última atualização |

---

### dim_territorio
**Descrição:** Dimensão contendo as regiões/territórios de vendas.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| territorio_id | SERIAL (PK) | Chave primária surrogate |
| territorio_sk | INTEGER (UNIQUE) | Chave natural do sistema fonte |
| nome | VARCHAR(100) | Nome do território |
| country_code | VARCHAR(10) | Código do país |
| grupo | VARCHAR(50) | Grupo de territórios (North America, Europe, Pacific) |
| created_at | TIMESTAMP | Data de criação do registro |

---

### dim_vendedor
**Descrição:** Dimensão contendo informações sobre os vendedores.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| vendedor_id | SERIAL (PK) | Chave primária surrogate |
| vendedor_sk | INTEGER (UNIQUE) | Chave natural do sistema fonte |
| nome_completo | VARCHAR(200) | Nome completo do vendedor |
| cargo | VARCHAR(100) | Cargo do vendedor |
| territorio_nome | VARCHAR(100) | Território de atuação |
| created_at | TIMESTAMP | Data de criação do registro |
| updated_at | TIMESTAMP | Data da última atualização |

---

### dim_metodo_envio
**Descrição:** Dimensão contendo os métodos de envio disponíveis.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| metodo_envio_id | SERIAL (PK) | Chave primária surrogate |
| metodo_envio_sk | INTEGER (UNIQUE) | Chave natural do sistema fonte |
| nome | VARCHAR(100) | Nome do método de envio |
| custo_base | NUMERIC(19,4) | Custo base do método |
| created_at | TIMESTAMP | Data de criação do registro |

---

## 📊 Tabela Fato

### fato_vendas
**Descrição:** Tabela fato contendo as transações de vendas e suas métricas.

**Chaves Estrangeiras:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| venda_id | SERIAL (PK) | Chave primária surrogate |
| tempo_id | INTEGER (FK) | Referência para dim_tempo |
| cliente_id | INTEGER (FK) | Referência para dim_cliente |
| produto_id | INTEGER (FK) | Referência para dim_produto |
| territorio_id | INTEGER (FK) | Referência para dim_territorio |
| vendedor_id | INTEGER (FK) | Referência para dim_vendedor |
| metodo_envio_id | INTEGER (FK) | Referência para dim_metodo_envio |

**Chaves de Negócio:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| salesorder_id | INTEGER | ID do pedido no sistema fonte |
| salesorderdetail_id | INTEGER | ID do item do pedido no sistema fonte |

**Métricas/Fatos:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| quantidade | INTEGER | Quantidade vendida |
| preco_unitario | NUMERIC(19,4) | Preço unitário do produto |
| desconto_unitario | NUMERIC(19,4) | Desconto aplicado por unidade |
| valor_bruto | NUMERIC(19,4) | Valor sem desconto (qtd × preço) |
| valor_desconto | NUMERIC(19,4) | Valor total do desconto |
| valor_liquido | NUMERIC(19,4) | Valor final após desconto |
| custo_produto | NUMERIC(19,4) | Custo do produto |
| lucro_bruto | NUMERIC(19,4) | Lucro bruto (valor líquido - custo) |
| subtotal_pedido | NUMERIC(19,4) | Subtotal do pedido completo |
| taxa_pedido | NUMERIC(19,4) | Taxa aplicada no pedido |
| frete_pedido | NUMERIC(19,4) | Valor do frete |
| total_pedido | NUMERIC(19,4) | Valor total do pedido |

**Flags:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| is_online | BOOLEAN | Indica se foi pedido online |

**Auditoria:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| created_at | TIMESTAMP | Data de criação do registro |

---

## 📋 Views Agregadas

### vw_vendas_diarias
**Descrição:** View agregada de vendas por dia, produto e território.

**Colunas:**
- data, ano, mes
- nome_produto, categoria, subcategoria
- territorio
- qtd_pedidos
- qtd_itens_vendidos
- receita_total
- lucro_total
- preco_medio

### vw_vendas_cliente
**Descrição:** View agregada de vendas por cliente.

**Colunas:**
- cliente_sk, nome_completo, tipo_cliente
- qtd_pedidos
- qtd_itens
- valor_total
- ticket_medio
- ultima_compra

---

## 🔑 Relacionamentos

```
dim_tempo (1) ─────────────┐
dim_cliente (1) ───────────┤
dim_produto (1) ───────────┤
dim_territorio (1) ────────┼──── (N) fato_vendas
dim_vendedor (1) ──────────┤
dim_metodo_envio (1) ──────┘
```

**Cardinalidade:** Cada venda (fato) está relacionada com uma e somente uma ocorrência de cada dimensão.

---

## 📊 Granularidade

A tabela fato está na **granularidade de item de pedido**, ou seja:
- Cada linha representa um produto específico vendido em um pedido
- Um pedido pode ter múltiplas linhas (um para cada produto)
- Permite análises detalhadas por produto e agregações por pedido

---

## 🎯 Métricas Calculadas

### Valor Bruto
```
valor_bruto = quantidade × preco_unitario
```

### Valor Desconto
```
valor_desconto = quantidade × preco_unitario × desconto_unitario
```

### Valor Líquido
```
valor_liquido = valor_bruto - valor_desconto
```

### Lucro Bruto
```
lucro_bruto = valor_liquido - (quantidade × custo_produto)
```

### Margem de Lucro (%)
```
margem = (lucro_bruto / valor_liquido) × 100
```

### Ticket Médio
```
ticket_medio = SUM(valor_liquido) / COUNT(DISTINCT pedido)
```

---

## 📈 Índices Criados

Para otimizar consultas OLAP, foram criados os seguintes índices:

**Dimensões:**
- Índices em chaves naturais (SK) para lookup durante ETL
- Índices em campos de filtro comum (categoria, ano/mês, etc.)

**Fato:**
- Índices em todas as foreign keys
- Índice composto (tempo_id, produto_id, territorio_id) para consultas comuns
- Constraint UNIQUE em (salesorder_id, salesorderdetail_id) para evitar duplicatas

---

## 🔄 Processo ETL

### Dimensões (SCD Tipo 1)
- **Estratégia:** Truncate and Load (carga full)
- **Frequência sugerida:** Diária
- **Ordem de carga:** Tempo → Produto → Cliente → Território → Vendedor → Método Envio

### Fato
- **Estratégia:** Truncate and Load (carga full) ou Incremental por data
- **Frequência sugerida:** Diária
- **Dependência:** Requer todas as dimensões carregadas

---

## 📝 Notas Importantes

1. **Chaves Surrogate:** Todas as dimensões usam chaves surrogate (IDs autoincrementais) para independência do sistema fonte.

2. **SCD Tipo 1:** Dimensões implementam Slowly Changing Dimension Tipo 1 (sobrescreve valores antigos).

3. **Valores NULL:** Territórios e vendedores podem ser NULL na tabela fato (vendas sem associação).

4. **Performance:** Views agregadas pré-calculam métricas comuns para melhor performance.

5. **Auditoria:** Timestamps de criação e atualização permitem rastreabilidade.
