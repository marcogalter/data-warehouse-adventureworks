# Diagrama do Modelo Estrela - Data Warehouse AdventureWorks

## Modelo Dimensional (Star Schema)

```mermaid
erDiagram
    FATO_VENDAS ||--o{ DIM_TEMPO : "tempo_id"
    FATO_VENDAS ||--o{ DIM_PRODUTO : "produto_id"
    FATO_VENDAS ||--o{ DIM_CLIENTE : "cliente_id"
    FATO_VENDAS ||--o{ DIM_TERRITORIO : "territorio_id"
    FATO_VENDAS ||--o{ DIM_VENDEDOR : "vendedor_id"
    FATO_VENDAS ||--o{ DIM_METODO_ENVIO : "metodo_envio_id"

    DIM_TEMPO {
        int tempo_id PK
        date data
        int ano
        int mes
        string mes_nome
        int trimestre
        int dia_semana
        string dia_semana_nome
    }

    DIM_PRODUTO {
        int produto_id PK
        int produto_sk
        string nome_produto
        string categoria
        string subcategoria
        string numero_produto
        decimal preco_lista
    }

    DIM_CLIENTE {
        int cliente_id PK
        int cliente_sk
        string nome_completo
        string tipo_cliente
        string territorio_name
    }

    DIM_TERRITORIO {
        int territorio_id PK
        int territorio_sk
        string nome
        string country_code
        string grupo
    }

    DIM_VENDEDOR {
        int vendedor_id PK
        int vendedor_sk
        string nome_completo
        string cargo
        string territorio_nome
    }

    DIM_METODO_ENVIO {
        int metodo_envio_id PK
        int metodo_envio_sk
        string nome
        decimal custo_base
    }

    FATO_VENDAS {
        bigint fato_vendas_id PK
        int tempo_id FK
        int produto_id FK
        int cliente_id FK
        int territorio_id FK
        int vendedor_id FK
        int metodo_envio_id FK
        int salesorder_id
        int salesorder_detail_id
        int quantidade
        decimal preco_unitario
        decimal desconto
        decimal valor_liquido
        decimal custo_produto
        decimal lucro_bruto
        boolean is_online
    }
```

## Descrição do Modelo

### Tabela Fato: fato_vendas
- **Granularidade**: Uma linha por item de pedido (orderdetail)
- **Métricas**: 
  - `quantidade`: Unidades vendidas
  - `valor_liquido`: Receita após desconto
  - `lucro_bruto`: Lucro (receita - custo)
  - `preco_unitario`: Preço por unidade
  - `desconto`: Valor do desconto aplicado

### Dimensões:
1. **dim_tempo**: Hierarquia temporal (ano → trimestre → mês → dia)
2. **dim_produto**: Hierarquia de produtos (categoria → subcategoria → produto)
3. **dim_cliente**: Informações de clientes
4. **dim_territorio**: Regiões de venda
5. **dim_vendedor**: Equipe de vendas (opcional)
6. **dim_metodo_envio**: Métodos de entrega

## Estatísticas do Data Warehouse

| Tabela | Registros | Descrição |
|--------|-----------|-----------|
| dim_tempo | 1.461 | 4 anos (2011-2014) |
| dim_produto | 504 | Catálogo de produtos |
| dim_cliente | 19.820 | Base de clientes |
| dim_territorio | 10 | Regiões de venda |
| dim_vendedor | 0 | Não utilizado |
| dim_metodo_envio | 5 | Opções de entrega |
| **fato_vendas** | **124.882** | **Transações de venda** |
