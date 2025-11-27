-- =========================================
-- QUERIES DOS 10 INDICADORES (KPIs)
-- =========================================

-- KPI 1: Total de vendas por região
-- Mostra o desempenho de vendas em cada território
SELECT 
    dter.nome as territorio,
    dter.grupo,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    SUM(fv.valor_liquido) as receita_total,
    SUM(fv.lucro_bruto) as lucro_total,
    ROUND(AVG(fv.valor_liquido), 2) as ticket_medio
FROM fato_vendas fv
LEFT JOIN dim_territorio dter ON fv.territorio_id = dter.territorio_id
GROUP BY dter.nome, dter.grupo
ORDER BY receita_total DESC;

-- KPI 2: Produtos mais vendidos (Top 20)
-- Identifica os produtos com maior volume de vendas
SELECT 
    dp.nome_produto,
    dp.categoria,
    dp.subcategoria,
    SUM(fv.quantidade) as quantidade_vendida,
    SUM(fv.valor_liquido) as receita_total,
    SUM(fv.lucro_bruto) as lucro_total,
    ROUND(SUM(fv.lucro_bruto) / NULLIF(SUM(fv.valor_liquido), 0) * 100, 2) as margem_percentual
FROM fato_vendas fv
JOIN dim_produto dp ON fv.produto_id = dp.produto_id
GROUP BY dp.nome_produto, dp.categoria, dp.subcategoria
ORDER BY quantidade_vendida DESC
LIMIT 20;

-- KPI 3: Ticket médio por cliente
-- Calcula o valor médio gasto por cliente
SELECT 
    dc.nome_completo,
    dc.tipo_cliente,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    SUM(fv.valor_liquido) as valor_total_gasto,
    ROUND(AVG(fv.valor_liquido), 2) as ticket_medio,
    MAX(dt.data) as ultima_compra
FROM fato_vendas fv
JOIN dim_cliente dc ON fv.cliente_id = dc.cliente_id
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY dc.nome_completo, dc.tipo_cliente
HAVING COUNT(DISTINCT fv.salesorder_id) > 0
ORDER BY valor_total_gasto DESC
LIMIT 50;

-- KPI 4: Taxa de crescimento mensal de vendas
-- Compara vendas mês a mês
WITH vendas_mensais AS (
    SELECT 
        dt.ano,
        dt.mes,
        dt.mes_nome,
        SUM(fv.valor_liquido) as receita_mensal
    FROM fato_vendas fv
    JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
    GROUP BY dt.ano, dt.mes, dt.mes_nome
),
vendas_com_lag AS (
    SELECT 
        ano,
        mes,
        mes_nome,
        receita_mensal,
        LAG(receita_mensal) OVER (ORDER BY ano, mes) as receita_mes_anterior
    FROM vendas_mensais
)
SELECT 
    ano,
    mes,
    mes_nome,
    ROUND(receita_mensal, 2) as receita_atual,
    ROUND(receita_mes_anterior, 2) as receita_anterior,
    ROUND(((receita_mensal - receita_mes_anterior) / NULLIF(receita_mes_anterior, 0) * 100), 2) as crescimento_percentual
FROM vendas_com_lag
ORDER BY ano, mes;

-- KPI 5: Margem de lucro por categoria de produto
-- Analisa a rentabilidade por categoria
SELECT 
    dp.categoria,
    SUM(fv.valor_liquido) as receita_total,
    SUM(fv.custo_produto * fv.quantidade) as custo_total,
    SUM(fv.lucro_bruto) as lucro_bruto_total,
    ROUND(SUM(fv.lucro_bruto) / NULLIF(SUM(fv.valor_liquido), 0) * 100, 2) as margem_percentual
FROM fato_vendas fv
JOIN dim_produto dp ON fv.produto_id = dp.produto_id
WHERE fv.lucro_bruto IS NOT NULL
GROUP BY dp.categoria
ORDER BY margem_percentual DESC;

-- KPI 6: Taxa de conversão de pedidos (pedidos online vs total)
-- Percentual de pedidos feitos online
SELECT 
    dt.ano,
    dt.trimestre,
    COUNT(DISTINCT CASE WHEN fv.is_online = TRUE THEN fv.salesorder_id END) as pedidos_online,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    ROUND(
        COUNT(DISTINCT CASE WHEN fv.is_online = TRUE THEN fv.salesorder_id END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT fv.salesorder_id), 0) * 100, 
        2
    ) as taxa_online_percentual
FROM fato_vendas fv
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY dt.ano, dt.trimestre
ORDER BY dt.ano, dt.trimestre;

-- KPI 7: Clientes mais valiosos (Top 10)
-- Identifica os clientes que mais geraram receita
SELECT 
    dc.cliente_sk,
    dc.nome_completo,
    dc.tipo_cliente,
    dc.territory_name,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    SUM(fv.quantidade) as total_itens,
    SUM(fv.valor_liquido) as receita_total,
    SUM(fv.lucro_bruto) as lucro_total,
    ROUND(AVG(fv.valor_liquido), 2) as ticket_medio,
    MIN(dt.data) as primeira_compra,
    MAX(dt.data) as ultima_compra
FROM fato_vendas fv
JOIN dim_cliente dc ON fv.cliente_id = dc.cliente_id
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY dc.cliente_sk, dc.nome_completo, dc.tipo_cliente, dc.territory_name
ORDER BY receita_total DESC
LIMIT 10;

-- KPI 8: Produtos com maior margem de lucro (Top 20)
-- Identifica produtos mais rentáveis para o negócio
SELECT 
    dp.nome_produto,
    dp.categoria,
    dp.subcategoria,
    SUM(fv.quantidade) as quantidade_vendida,
    SUM(fv.valor_liquido) as receita_total,
    SUM(fv.lucro_bruto) as lucro_total,
    ROUND(SUM(fv.lucro_bruto) / NULLIF(SUM(fv.valor_liquido), 0) * 100, 2) as margem_percentual,
    ROUND(SUM(fv.lucro_bruto) / NULLIF(SUM(fv.quantidade), 0), 2) as lucro_por_unidade
FROM fato_vendas fv
JOIN dim_produto dp ON fv.produto_id = dp.produto_id
WHERE fv.lucro_bruto IS NOT NULL
GROUP BY dp.nome_produto, dp.categoria, dp.subcategoria
HAVING SUM(fv.quantidade) > 10
ORDER BY margem_percentual DESC, lucro_total DESC
LIMIT 20;

-- KPI 9: Sazonalidade de vendas (vendas por mês do ano)
-- Identifica padrões sazonais nas vendas
SELECT 
    dt.mes,
    dt.mes_nome,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    SUM(fv.quantidade) as total_itens_vendidos,
    SUM(fv.valor_liquido) as receita_total,
    ROUND(AVG(fv.valor_liquido), 2) as ticket_medio,
    COUNT(DISTINCT fv.cliente_id) as clientes_unicos
FROM fato_vendas fv
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY dt.mes, dt.mes_nome
ORDER BY dt.mes;

-- KPI 10: Análise de vendas por dia da semana
-- Mostra em quais dias da semana há mais vendas
SELECT 
    dt.dia_semana,
    dt.dia_semana_nome,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    SUM(fv.valor_liquido) as receita_total,
    ROUND(AVG(fv.valor_liquido), 2) as ticket_medio,
    SUM(fv.quantidade) as total_itens
FROM fato_vendas fv
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY dt.dia_semana, dt.dia_semana_nome
ORDER BY dt.dia_semana;

-- =========================================
-- QUERIES EXTRAS PARA ANÁLISES AVANÇADAS
-- =========================================

-- Análise de Pareto (80/20) - Produtos que geram 80% da receita
WITH produtos_receita AS (
    SELECT 
        dp.produto_id,
        dp.nome_produto,
        dp.categoria,
        SUM(fv.valor_liquido) as receita,
        SUM(SUM(fv.valor_liquido)) OVER () as receita_total
    FROM fato_vendas fv
    JOIN dim_produto dp ON fv.produto_id = dp.produto_id
    GROUP BY dp.produto_id, dp.nome_produto, dp.categoria
),
produtos_acumulado AS (
    SELECT 
        produto_id,
        nome_produto,
        categoria,
        receita,
        receita_total,
        SUM(receita) OVER (ORDER BY receita DESC) as receita_acumulada,
        ROUND(SUM(receita) OVER (ORDER BY receita DESC) / receita_total * 100, 2) as percentual_acumulado
    FROM produtos_receita
)
SELECT 
    nome_produto,
    categoria,
    ROUND(receita, 2) as receita,
    percentual_acumulado
FROM produtos_acumulado
WHERE percentual_acumulado <= 80
ORDER BY receita DESC;

-- Taxa de recompra (clientes que fizeram mais de uma compra)
WITH clientes_compras AS (
    SELECT 
        cliente_id,
        COUNT(DISTINCT salesorder_id) as num_compras
    FROM fato_vendas
    GROUP BY cliente_id
)
SELECT 
    CASE 
        WHEN num_compras = 1 THEN 'Cliente Único'
        WHEN num_compras BETWEEN 2 AND 5 THEN 'Cliente Recorrente'
        ELSE 'Cliente VIP'
    END as tipo_cliente,
    COUNT(*) as quantidade_clientes,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentual
FROM clientes_compras
GROUP BY 
    CASE 
        WHEN num_compras = 1 THEN 'Cliente Único'
        WHEN num_compras BETWEEN 2 AND 5 THEN 'Cliente Recorrente'
        ELSE 'Cliente VIP'
    END
ORDER BY quantidade_clientes DESC;
