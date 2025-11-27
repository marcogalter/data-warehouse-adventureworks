-- Popula dim_vendedor no Data Warehouse
\c adventureworks_dw

-- Insere vendedores diretamente no DW
INSERT INTO dim_vendedor (vendedor_sk, nome_completo, cargo, territorio_nome)
VALUES 
    (1, 'João Silva Santos', 'Gerente Regional', 'Central'),
    (2, 'Maria Oliveira Costa', 'Vendedor Senior', 'Northeast'),
    (3, 'Pedro Souza Lima', 'Vendedor Pleno', 'Northwest'),
    (4, 'Ana Paula Rodrigues', 'Vendedor Junior', 'Southeast'),
    (5, 'Carlos Eduardo Ferreira', 'Gerente de Vendas', 'Southwest'),
    (6, 'Juliana Martins Alves', 'Vendedor Senior', 'Central'),
    (7, 'Roberto Carlos Pereira', 'Vendedor Pleno', 'Canada'),
    (8, 'Fernanda Lima Barbosa', 'Vendedor Junior', 'France'),
    (9, 'Marcos Vinícius Santos', 'Vendedor Senior', 'Germany'),
    (10, 'Patrícia Gomes Silva', 'Gerente Comercial', 'Australia'),
    (11, 'Lucas Henrique Costa', 'Vendedor Pleno', 'United Kingdom'),
    (12, 'Camila Ribeiro Dias', 'Vendedor Junior', 'Central'),
    (13, 'Rafael Augusto Moura', 'Vendedor Senior', 'Northeast'),
    (14, 'Tatiana Cristina Rocha', 'Vendedor Pleno', 'Northwest'),
    (15, 'Bruno César Cardoso', 'Vendedor Junior', 'Southeast');

-- Atualiza fato_vendas para associar vendedores aleatoriamente
UPDATE fato_vendas
SET vendedor_id = (
    SELECT vendedor_id 
    FROM dim_vendedor 
    ORDER BY RANDOM() 
    LIMIT 1
);

-- Verifica resultado
SELECT COUNT(*) as total_vendedores FROM dim_vendedor;
SELECT COUNT(*) as vendas_com_vendedor FROM fato_vendas WHERE vendedor_id IS NOT NULL;
