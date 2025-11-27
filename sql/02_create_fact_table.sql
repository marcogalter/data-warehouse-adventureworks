-- =========================================
-- CRIAÇÃO DA TABELA FATO DE VENDAS
-- =========================================

CREATE TABLE IF NOT EXISTS fato_vendas (
    venda_id SERIAL PRIMARY KEY,
    
    -- Foreign Keys para Dimensões
    tempo_id INTEGER NOT NULL REFERENCES dim_tempo(tempo_id),
    cliente_id INTEGER NOT NULL REFERENCES dim_cliente(cliente_id),
    produto_id INTEGER NOT NULL REFERENCES dim_produto(produto_id),
    territorio_id INTEGER REFERENCES dim_territorio(territorio_id),
    vendedor_id INTEGER REFERENCES dim_vendedor(vendedor_id),
    metodo_envio_id INTEGER REFERENCES dim_metodo_envio(metodo_envio_id),
    
    -- Chaves de Negócio (para rastreabilidade)
    salesorder_id INTEGER NOT NULL,
    salesorderdetail_id INTEGER NOT NULL,
    
    -- Métricas/Fatos
    quantidade INTEGER NOT NULL,
    preco_unitario NUMERIC(19,4) NOT NULL,
    desconto_unitario NUMERIC(19,4) DEFAULT 0,
    valor_bruto NUMERIC(19,4) NOT NULL,
    valor_desconto NUMERIC(19,4) DEFAULT 0,
    valor_liquido NUMERIC(19,4) NOT NULL,
    custo_produto NUMERIC(19,4),
    lucro_bruto NUMERIC(19,4),
    
    -- Métricas do Pedido (desnormalizadas para facilitar agregações)
    subtotal_pedido NUMERIC(19,4),
    taxa_pedido NUMERIC(19,4),
    frete_pedido NUMERIC(19,4),
    total_pedido NUMERIC(19,4),
    
    -- Flags
    is_online BOOLEAN DEFAULT FALSE,
    
    -- Auditoria
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint de unicidade
    UNIQUE(salesorder_id, salesorderdetail_id)
);

-- Índices para otimização de queries
CREATE INDEX idx_fato_vendas_tempo ON fato_vendas(tempo_id);
CREATE INDEX idx_fato_vendas_cliente ON fato_vendas(cliente_id);
CREATE INDEX idx_fato_vendas_produto ON fato_vendas(produto_id);
CREATE INDEX idx_fato_vendas_territorio ON fato_vendas(territorio_id);
CREATE INDEX idx_fato_vendas_vendedor ON fato_vendas(vendedor_id);
CREATE INDEX idx_fato_vendas_composite ON fato_vendas(tempo_id, produto_id, territorio_id);

-- =========================================
-- VIEWS PARA FACILITAR ANÁLISES
-- =========================================

-- View agregada por dia, produto e território
CREATE OR REPLACE VIEW vw_vendas_diarias AS
SELECT 
    dt.data,
    dt.ano,
    dt.mes,
    dp.nome_produto,
    dp.categoria,
    dp.subcategoria,
    dter.nome as territorio,
    COUNT(DISTINCT fv.salesorder_id) as qtd_pedidos,
    SUM(fv.quantidade) as qtd_itens_vendidos,
    SUM(fv.valor_liquido) as receita_total,
    SUM(fv.lucro_bruto) as lucro_total,
    AVG(fv.preco_unitario) as preco_medio
FROM fato_vendas fv
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
JOIN dim_produto dp ON fv.produto_id = dp.produto_id
LEFT JOIN dim_territorio dter ON fv.territorio_id = dter.territorio_id
GROUP BY dt.data, dt.ano, dt.mes, dp.nome_produto, dp.categoria, dp.subcategoria, dter.nome;

-- View agregada por cliente
CREATE OR REPLACE VIEW vw_vendas_cliente AS
SELECT 
    dc.cliente_sk,
    dc.nome_completo,
    dc.tipo_cliente,
    COUNT(DISTINCT fv.salesorder_id) as qtd_pedidos,
    SUM(fv.quantidade) as qtd_itens,
    SUM(fv.valor_liquido) as valor_total,
    AVG(fv.valor_liquido) as ticket_medio,
    MAX(dt.data) as ultima_compra
FROM fato_vendas fv
JOIN dim_cliente dc ON fv.cliente_id = dc.cliente_id
JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY dc.cliente_sk, dc.nome_completo, dc.tipo_cliente;
