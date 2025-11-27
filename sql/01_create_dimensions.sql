-- =========================================
-- CRIAÇÃO DAS DIMENSÕES DO DATA WAREHOUSE
-- =========================================

-- Dimensão Tempo
CREATE TABLE IF NOT EXISTS dim_tempo (
    tempo_id SERIAL PRIMARY KEY,
    data DATE NOT NULL UNIQUE,
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    mes_nome VARCHAR(20) NOT NULL,
    dia INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    dia_semana_nome VARCHAR(20) NOT NULL,
    semana_ano INTEGER NOT NULL,
    is_fim_semana BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_tempo_data ON dim_tempo(data);
CREATE INDEX idx_dim_tempo_ano_mes ON dim_tempo(ano, mes);

-- Dimensão Cliente
CREATE TABLE IF NOT EXISTS dim_cliente (
    cliente_id SERIAL PRIMARY KEY,
    cliente_sk INTEGER NOT NULL UNIQUE, -- Surrogate Key do source
    tipo_cliente VARCHAR(50),
    nome_completo VARCHAR(200),
    territory_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_cliente_sk ON dim_cliente(cliente_sk);

-- Dimensão Produto
CREATE TABLE IF NOT EXISTS dim_produto (
    produto_id SERIAL PRIMARY KEY,
    produto_sk INTEGER NOT NULL UNIQUE, -- Surrogate Key do source
    nome_produto VARCHAR(200) NOT NULL,
    numero_produto VARCHAR(50),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    cor VARCHAR(50),
    tamanho VARCHAR(20),
    peso NUMERIC(10,2),
    classe VARCHAR(10),
    estilo VARCHAR(10),
    linha_produto VARCHAR(50),
    custo_padrao NUMERIC(19,4),
    preco_lista NUMERIC(19,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_produto_sk ON dim_produto(produto_sk);
CREATE INDEX idx_dim_produto_categoria ON dim_produto(categoria);

-- Dimensão Território (Região de Vendas)
CREATE TABLE IF NOT EXISTS dim_territorio (
    territorio_id SERIAL PRIMARY KEY,
    territorio_sk INTEGER NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    country_code VARCHAR(10),
    grupo VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_territorio_sk ON dim_territorio(territorio_sk);

-- Dimensão Vendedor
CREATE TABLE IF NOT EXISTS dim_vendedor (
    vendedor_id SERIAL PRIMARY KEY,
    vendedor_sk INTEGER NOT NULL UNIQUE,
    nome_completo VARCHAR(200),
    cargo VARCHAR(100),
    territorio_nome VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_vendedor_sk ON dim_vendedor(vendedor_sk);

-- Dimensão Método de Envio
CREATE TABLE IF NOT EXISTS dim_metodo_envio (
    metodo_envio_id SERIAL PRIMARY KEY,
    metodo_envio_sk INTEGER NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    custo_base NUMERIC(19,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_metodo_envio_sk ON dim_metodo_envio(metodo_envio_sk);
