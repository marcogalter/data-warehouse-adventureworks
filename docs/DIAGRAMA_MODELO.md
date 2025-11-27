# 📊 Diagrama do Modelo Dimensional (Esquema Estrela)

## Modelo Conceitual

```mermaid
erDiagram
    dim_tempo ||--o{ fato_vendas : "tempo_id"
    dim_cliente ||--o{ fato_vendas : "cliente_id"
    dim_produto ||--o{ fato_vendas : "produto_id"
    dim_territorio ||--o{ fato_vendas : "territorio_id"
    dim_vendedor ||--o{ fato_vendas : "vendedor_id"
    dim_metodo_envio ||--o{ fato_vendas : "metodo_envio_id"
    
    dim_tempo {
        int tempo_id PK
        date data UK
        int ano
        int trimestre
        int mes
        string mes_nome
        int dia
        int dia_semana
        string dia_semana_nome
        bool is_fim_semana
    }
    
    dim_cliente {
        int cliente_id PK
        int cliente_sk UK
        string tipo_cliente
        string nome_completo
        string territory_name
    }
    
    dim_produto {
        int produto_id PK
        int produto_sk UK
        string nome_produto
        string categoria
        string subcategoria
        string cor
        decimal custo_padrao
        decimal preco_lista
    }
    
    dim_territorio {
        int territorio_id PK
        int territorio_sk UK
        string nome
        string country_code
        string grupo
    }
    
    dim_vendedor {
        int vendedor_id PK
        int vendedor_sk UK
        string nome_completo
        string cargo
        string territorio_nome
    }
    
    dim_metodo_envio {
        int metodo_envio_id PK
        int metodo_envio_sk UK
        string nome
        decimal custo_base
    }
    
    fato_vendas {
        int venda_id PK
        int tempo_id FK
        int cliente_id FK
        int produto_id FK
        int territorio_id FK
        int vendedor_id FK
        int metodo_envio_id FK
        int quantidade
        decimal preco_unitario
        decimal valor_liquido
        decimal lucro_bruto
        bool is_online
    }
```

## Representação Textual (para o artigo)

```
                    ┌──────────────┐
                    │  dim_tempo   │
                    ├──────────────┤
                    │ tempo_id (PK)│
                    │ data         │
                    │ ano          │
                    │ mes          │
                    │ dia          │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
┌────────┴────────┐ ┌─────┴──────┐ ┌────────┴─────────┐
│  dim_cliente    │ │  dim_produto│ │  dim_territorio  │
├─────────────────┤ ├────────────┤ ├──────────────────┤
│ cliente_id (PK) │ │produto_id  │ │territorio_id (PK)│
│ nome_completo   │ │nome_produto│ │ nome             │
│ tipo_cliente    │ │categoria   │ │ grupo            │
└────────┬────────┘ └─────┬──────┘ └────────┬─────────┘
         │                │                  │
         └────────────────┼──────────────────┘
                          │
                  ┌───────▼───────┐
                  │ fato_vendas   │
                  ├───────────────┤
                  │ venda_id (PK) │
                  │ tempo_id (FK) │
                  │ cliente_id FK │
                  │ produto_id FK │
                  │ territorio FK │
                  │ vendedor_id FK│
                  │ metodo_env FK │
                  ├───────────────┤
                  │ quantidade    │
                  │ preco_unit    │
                  │ valor_liquido │
                  │ lucro_bruto   │
                  │ is_online     │
                  └───────┬───────┘
                          │
         ┌────────────────┼────────────────┐
         │                                 │
┌────────┴─────────┐            ┌─────────┴────────┐
│  dim_vendedor    │            │ dim_metodo_envio │
├──────────────────┤            ├──────────────────┤
│ vendedor_id (PK) │            │ metodo_envio_id  │
│ nome_completo    │            │ nome             │
│ cargo            │            │ custo_base       │
└──────────────────┘            └──────────────────┘
```

## 🎯 Características do Modelo

### Tipo: Estrela (Star Schema)
- Centro: Tabela fato (fato_vendas)
- Pontas: Dimensões desnormalizadas
- Vantagens: Queries simples, alta performance

### Granularidade
**Item de Pedido** - Cada linha representa um produto vendido em um pedido específico.

### Dimensões (6)
1. **Tempo** - Quando a venda ocorreu
2. **Cliente** - Quem comprou
3. **Produto** - O que foi comprado
4. **Território** - Onde foi vendido
5. **Vendedor** - Quem vendeu
6. **Método de Envio** - Como foi entregue

### Fato (1)
**Vendas** - Transações de vendas com métricas quantitativas

### Métricas na Tabela Fato
- **Aditivas:** quantidade, valor_liquido, lucro_bruto
- **Semi-aditivas:** preco_unitario (média)
- **Não-aditivas:** is_online (flag)

### Relacionamentos
- Cardinalidade: 1:N (dimensão:fato)
- Chaves: Surrogate keys (IDs autoincrementais)
- Integridade: Foreign keys com referências explícitas

## 📐 Para o Artigo

### Recomendação
Para o artigo acadêmico, recomendo criar o diagrama usando:
1. **Draw.io** (https://app.diagrams.net/) - Gratuito
2. **Lucidchart** (https://www.lucidchart.com/) - Versão estudante
3. **ERDPlus** (https://erdplus.com/) - Específico para ER

### Elementos a incluir no diagrama:
- ✅ Nome das tabelas
- ✅ Chaves primárias (PK)
- ✅ Chaves estrangeiras (FK)
- ✅ Principais atributos
- ✅ Relacionamentos (1:N)
- ✅ Legenda explicativa

### Caption sugerida:
"Figura 1 - Modelo Dimensional em Esquema Estrela do Data Warehouse AdventureWorks. A tabela fato central (fato_vendas) armazena as métricas de vendas e conecta-se a seis dimensões desnormalizadas, permitindo análises multidimensionais eficientes."
