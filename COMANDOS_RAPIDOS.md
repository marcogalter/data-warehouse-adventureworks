# ⚡ Comandos Rápidos - Referência

## 🐳 Docker

### Gerenciar containers
```bash
# Subir todos os serviços
docker-compose up -d

# Ver status
docker-compose ps

# Parar tudo
docker-compose stop

# Parar e remover tudo
docker-compose down

# Parar e remover tudo (incluindo volumes/dados)
docker-compose down -v

# Reiniciar um serviço específico
docker-compose restart airflow-scheduler

# Ver logs em tempo real
docker-compose logs -f airflow-scheduler
docker-compose logs -f airflow-webserver
docker-compose logs -f postgres-dw
```

---

## 🗄️ PostgreSQL

### Conectar nos bancos
```bash
# Data Warehouse (destino)
docker exec -it olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw

# Banco Fonte (AdventureWorks original)
docker exec -it olap_postgres-source_1 psql -U source_user -d adventureworks

# Banco do Airflow
docker exec -it olap_postgres-airflow_1 psql -U airflow -d airflow
```

### Queries úteis dentro do psql
```sql
-- Listar todas as tabelas
\dt

-- Descrever uma tabela
\d fato_vendas

-- Ver quantidade de registros
SELECT COUNT(*) FROM fato_vendas;

-- Sair
\q
```

### Executar SQL de arquivo
```bash
# Executar arquivo SQL no DW
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < sql/03_kpis_queries.sql
```

---

## ✈️ Airflow

### CLI do Airflow
```bash
# Listar DAGs
docker exec olap_airflow-scheduler_1 airflow dags list

# Executar uma DAG
docker exec olap_airflow-scheduler_1 airflow dags trigger etl_dimensions
docker exec olap_airflow-scheduler_1 airflow dags trigger etl_fact_sales

# Ver estado de uma DAG
docker exec olap_airflow-scheduler_1 airflow dags state etl_dimensions

# Listar tarefas de uma DAG
docker exec olap_airflow-scheduler_1 airflow tasks list etl_dimensions

# Ver erros de import
docker exec olap_airflow-scheduler_1 airflow dags list-import-errors
```

---

## 📊 Validação de Dados

### Contar registros (rápido)
```bash
docker exec olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw -t -c "
SELECT 'dim_tempo', COUNT(*) FROM dim_tempo
UNION ALL SELECT 'dim_produto', COUNT(*) FROM dim_produto
UNION ALL SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL SELECT 'dim_territorio', COUNT(*) FROM dim_territorio
UNION ALL SELECT 'dim_vendedor', COUNT(*) FROM dim_vendedor
UNION ALL SELECT 'dim_metodo_envio', COUNT(*) FROM dim_metodo_envio
UNION ALL SELECT 'fato_vendas', COUNT(*) FROM fato_vendas;
"
```

### Validação com script Python
```bash
python3 check_data.py
```

---

## 🔄 Limpar e Recarregar Dados

### Limpar tabelas do DW
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

### Recriar estrutura do DW
```bash
# Dropar e recriar dimensões
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < sql/01_create_dimensions.sql

# Dropar e recriar fato
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < sql/02_create_fact_table.sql
```

---

## 📈 KPIs

### Executar KPI específico (exemplo: KPI 1)
```bash
docker exec olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw -c "
SELECT 
    dter.nome as territorio,
    dter.grupo,
    COUNT(DISTINCT fv.salesorder_id) as total_pedidos,
    SUM(fv.valor_liquido) as receita_total
FROM fato_vendas fv
LEFT JOIN dim_territorio dter ON fv.territorio_id = dter.territorio_id
GROUP BY dter.nome, dter.grupo
ORDER BY receita_total DESC;
"
```

### Executar todos os KPIs
```bash
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < sql/03_kpis_queries.sql > resultados_kpis.txt
```

---

## 🔍 Debug

### Ver logs do scheduler
```bash
docker-compose logs -f airflow-scheduler | tail -100
```

### Ver logs do webserver
```bash
docker-compose logs -f airflow-webserver | tail -100
```

### Ver logs de um container específico
```bash
docker logs olap_postgres-dw_1
```

### Entrar no container (shell)
```bash
# Airflow
docker exec -it olap_airflow-scheduler_1 bash

# PostgreSQL DW
docker exec -it olap_postgres-dw_1 bash
```

---

## 📁 Arquivos

### Ver conteúdo de arquivo
```bash
cat sql/01_create_dimensions.sql
cat dags/etl_dimensions.py
```

### Editar arquivo (nano)
```bash
nano dags/etl_dimensions.py
# Ctrl+O para salvar, Ctrl+X para sair
```

### Contar linhas de código
```bash
find . -name "*.py" -o -name "*.sql" | xargs wc -l
```

---

## 🚀 Scripts Prontos

### Executar ETL completo
```bash
./run_etl.sh
```

### Validar dados
```bash
python3 check_data.py
```

---

## 🌐 URLs

```bash
# Airflow Web UI
http://localhost:8080
# Usuário: admin | Senha: admin

# PostgreSQL DW (via cliente externo como DBeaver)
Host: localhost
Port: 5434
Database: adventureworks_dw
User: dw_user
Password: dw_password

# PostgreSQL Source
Host: localhost
Port: 5435
Database: adventureworks
User: source_user
Password: source_password
```

---

## 🎯 Workflow Completo

```bash
# 1. Subir ambiente
docker-compose up -d

# 2. Aguardar inicialização (2-3 minutos)
sleep 180

# 3. Verificar se está tudo rodando
docker-compose ps

# 4. Acessar Airflow
# Abrir navegador: http://localhost:8080

# 5. Executar DAG de dimensões
# Via interface web ou:
docker exec olap_airflow-scheduler_1 airflow dags trigger etl_dimensions

# 6. Aguardar 2 minutos
sleep 120

# 7. Executar DAG de fato
docker exec olap_airflow-scheduler_1 airflow dags trigger etl_fact_sales

# 8. Aguardar 3 minutos
sleep 180

# 9. Validar dados
python3 check_data.py

# 10. Executar KPIs
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < sql/03_kpis_queries.sql
```

---

## 💾 Backup

### Fazer backup do DW
```bash
docker exec olap_postgres-dw_1 pg_dump -U dw_user adventureworks_dw > backup_dw.sql
```

### Restaurar backup
```bash
docker exec -i olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw < backup_dw.sql
```

---

## 🔧 Troubleshooting

### Problema: Containers não sobem
```bash
docker-compose down
docker-compose up -d
docker-compose ps
```

### Problema: DAG não aparece
```bash
docker-compose restart airflow-scheduler
sleep 30
docker exec olap_airflow-scheduler_1 airflow dags list
```

### Problema: Erro de permissão
```bash
sudo chmod -R 777 logs dags plugins
```

### Problema: Porta já em uso
```bash
# Ver o que está usando a porta 8080
sudo lsof -i :8080

# Matar processo
sudo kill -9 [PID]
```

### Problema: Espaço em disco
```bash
# Limpar containers antigos
docker system prune -a

# Ver uso de espaço
docker system df
```

---

## 📝 Git (para GitHub)

### Inicializar repositório
```bash
cd /home/marcogalter/olap
git init
git add .
git commit -m "Initial commit - Data Warehouse AdventureWorks"
```

### Conectar com GitHub
```bash
git remote add origin https://github.com/SEU-USUARIO/SEU-REPO.git
git branch -M main
git push -u origin main
```

### Atualizar
```bash
git add .
git commit -m "Descrição das mudanças"
git push
```

---

## ⚡ Atalhos Úteis

```bash
# Alias úteis (adicione no ~/.bashrc)
alias dc='docker-compose'
alias dps='docker-compose ps'
alias dlogs='docker-compose logs -f'
alias dw='docker exec -it olap_postgres-dw_1 psql -U dw_user -d adventureworks_dw'
alias af='http://localhost:8080'
```

---

## 📞 Comandos de Emergência

### Resetar tudo do zero
```bash
cd /home/marcogalter/olap
docker-compose down -v
docker-compose up -d
sleep 180
# Re-carregar AdventureWorks no source
docker cp data/adventureworks.sql olap_postgres-source_1:/tmp/
docker exec olap_postgres-source_1 psql -U source_user -d adventureworks -f /tmp/adventureworks.sql
```

### Ver uso de recursos
```bash
docker stats
```

### Limpar logs
```bash
rm -rf logs/*
```

---

**Salve este arquivo para referência rápida!** 🚀
