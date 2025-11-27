# 🎯 Guia Rápido: Como Usar o Airflow

## 📱 Acessando a Interface

1. Abra seu navegador
2. Acesse: **http://localhost:8080**
3. Faça login:
   - **Usuário:** `admin`
   - **Senha:** `admin`

---

## 🔍 Entendendo a Interface Principal

### Tela Inicial (DAGs)
Você verá uma lista de DAGs disponíveis:
- ✅ **etl_dimensions** - Carga das dimensões
- ✅ **etl_fact_sales** - Carga da tabela fato

**Colunas importantes:**
- **DAG** - Nome da DAG
- **Owner** - Proprietário (airflow)
- **Runs** - Status das execuções
- **Schedule** - Agendamento (None = manual)
- **Actions** - Ações disponíveis

---

## ▶️ Como Executar uma DAG

### Método 1: Botão Play (Recomendado)

1. Localize a DAG **etl_dimensions** na lista
2. No lado direito, clique no botão **▶️ (Play)**
3. Aparecerá um menu, clique em **"Trigger DAG"**
4. Clique em **"Trigger"** novamente para confirmar
5. A DAG será executada!

### Método 2: Dentro da DAG

1. Clique no nome **etl_dimensions**
2. No canto superior direito, clique no botão **▶️ "Trigger DAG"**
3. Confirme

---

## 📊 Acompanhando a Execução

### Graph View (Visão em Grafo)

1. Clique no nome da DAG **etl_dimensions**
2. Clique na aba **"Graph"** no topo
3. Você verá um diagrama com as tarefas

**Cores das tarefas:**
- 🟢 **Verde** - Sucesso
- 🔵 **Azul claro** - Em execução
- 🟡 **Amarelo** - Em fila
- 🔴 **Vermelho** - Falha
- ⚪ **Branco** - Não executado

### Grid View (Visão em Grade)

1. Clique na aba **"Grid"**
2. Veja histórico de execuções
3. Cada linha é uma execução
4. Cada coluna é uma tarefa

---

## 📋 Ordem de Execução das DAGs

### 1️⃣ PRIMEIRO: etl_dimensions

Execute esta DAG primeiro! Ela carrega:
- ✅ dim_tempo
- ✅ dim_produto
- ✅ dim_cliente
- ✅ dim_territorio
- ✅ dim_vendedor
- ✅ dim_metodo_envio

**Tempo estimado:** 1-2 minutos

**Como saber se terminou:**
- Todas as 6 tarefas ficam verdes ✅
- Status geral da DAG fica "success"

### 2️⃣ DEPOIS: etl_fact_sales

⚠️ **IMPORTANTE:** Só execute após etl_dimensions ter sucesso!

Esta DAG carrega:
- ✅ fato_vendas (com lookup das dimensões)
- ✅ Validação dos dados

**Tempo estimado:** 2-3 minutos

---

## 🔍 Ver Logs de uma Tarefa

1. Clique na DAG
2. Vá para **Graph View**
3. Clique em uma tarefa (quadrado)
4. Clique em **"Log"**
5. Veja a saída detalhada

**Logs úteis mostram:**
- ✓ "X registros extraídos"
- ✓ "X registros inseridos"
- ✓ "Dimensão X: Y registros carregados"

---

## ❌ O que fazer se der erro?

### Tarefa ficou vermelha

1. Clique na tarefa vermelha
2. Clique em **"Log"**
3. Leia o erro na última parte do log
4. Anote a mensagem de erro

**Erros comuns:**

**"Connection refused"**
- Problema: Banco não está acessível
- Solução: Verifique se containers estão rodando
  ```bash
  docker-compose ps
  ```

**"Dag not found"**
- Problema: DAG não foi detectada
- Solução: Reinicie o scheduler
  ```bash
  docker-compose restart airflow-scheduler
  ```

**"No module named..."**
- Problema: Biblioteca Python faltando
- Solução: Instale no container do Airflow

### Reexecutar Tarefa com Falha

1. Clique na tarefa vermelha
2. Clique em **"Clear"**
3. Confirme
4. A tarefa será reexecutada

### Reexecutar DAG Inteira

1. Na tela da DAG, clique em **"Delete"** na execução com falha
2. Dispare novamente com o botão **▶️**

---

## 📸 Prints para o Artigo

### Print 1: Lista de DAGs
- Vá para tela inicial
- Mostre as 2 DAGs listadas
- **Caption:** "Lista de DAGs disponíveis no Apache Airflow"

### Print 2: Graph View - Dimensões
1. Abra **etl_dimensions**
2. Vá para **Graph**
3. Tire print com todas as tarefas verdes
4. **Caption:** "Fluxo de execução da DAG etl_dimensions"

### Print 3: Graph View - Fato
1. Abra **etl_fact_sales**
2. Vá para **Graph**
3. Tire print com tarefas verdes
4. **Caption:** "Fluxo de execução da DAG etl_fact_sales"

### Print 4: Log de Sucesso
1. Entre em uma tarefa
2. Abra o Log
3. Mostre mensagens de sucesso
4. **Caption:** "Log de execução bem-sucedida da tarefa load_dim_produto"

### Print 5: Grid View
1. Vá para Grid View
2. Mostre múltiplas execuções (se tiver)
3. **Caption:** "Histórico de execuções no Grid View"

---

## 🎨 Personalizando

### Pausar/Despausar DAG

- Botão de **toggle** (liga/desliga) ao lado do nome da DAG
- Pausado = DAG não será executada automaticamente
- Despausado = Pode ser executada

### Agendar Execução

Para agendar execução automática, edite o arquivo da DAG:

```python
schedule_interval='0 2 * * *',  # Diariamente às 2h da manhã
# schedule_interval='@daily',    # Alternativa
# schedule_interval=None,        # Manual (atual)
```

---

## 🐛 Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| DAG não aparece | `docker-compose restart airflow-scheduler` |
| Não consigo acessar http://localhost:8080 | Verifique se container está rodando: `docker-compose ps` |
| Tarefa demora muito | Normal! ETL processa muitos dados |
| Erro "import error" | Verifique se arquivo está em `/dags` |
| Quero limpar tudo | `docker-compose down -v` e suba novamente |

---

## 📱 Atalhos Úteis

- **F5** - Atualizar página
- **Ctrl + F** - Buscar DAG pelo nome
- **Esc** - Fechar modal/popup

---

## ✅ Checklist de Sucesso

Execute esta checklist após rodar as DAGs:

- [ ] etl_dimensions executou com sucesso (todas as 6 tarefas verdes)
- [ ] etl_fact_sales executou com sucesso (2 tarefas verdes)
- [ ] Consegui acessar os logs de pelo menos 1 tarefa
- [ ] Tirei print do Graph View de ambas as DAGs
- [ ] Validei a quantidade de registros (próximo passo)

---

## 🎓 Para o Artigo

**Elementos que o professor espera ver:**

1. ✅ Print da lista de DAGs
2. ✅ Print do Graph View (diagrama de execução)
3. ✅ Print de execução bem-sucedida (verde)
4. ✅ Explicação do fluxo de cada DAG
5. ✅ Menção ao Apache Airflow no texto

**Frase para o artigo:**
"Os processos ETL foram implementados no Apache Airflow versão 2.7.3, permitindo orquestração, monitoramento e agendamento automatizado das cargas de dados. Foram desenvolvidas duas DAGs (Directed Acyclic Graphs): etl_dimensions para carga das dimensões e etl_fact_sales para carga da tabela fato."

---

## 🚀 Próximos Passos

Depois de executar as DAGs com sucesso:

1. ✅ Validar dados carregados
2. ✅ Executar queries dos KPIs
3. ✅ Tirar prints dos resultados
4. ✅ Escrever o artigo
