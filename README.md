# MariaDB vs PostgreSQL — Estudo de Performance com FastAPI + Locust

> **mariadb-vs-postgresql-benchmark**

## Sobre

Projeto de benchmark para comparar o desempenho do **MariaDB** e **PostgreSQL** sob carga de estresse idêntica. A mesma API FastAPI consulta a mesma tabela (`registers`) com a mesma quantidade de dados (340 mil registros) em ambos os bancos, rodando no mesmo hardware (VPS). O objetivo é analisar latência, throughput, consumo de CPU/RAM e queries lentas de cada banco.

**Stack:** FastAPI + asyncpg/aiomysql + Locust + Docker + htop

**Fluxo do teste:**
1. API conecta no **MariaDB** → teste de estresse com Locust → coleta de métricas (htop + slow query log)
2. Troca `.env` para **PostgreSQL** → repete o mesmo teste
3. Compara resultados: RPS, latência (p50/p95/p99), CPU, RAM, queries lentas

## Dependências

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Subir os bancos

```bash
docker compose up -d
```

> MariaDB na porta **3306** / PostgreSQL na porta **5432**

## Trocar de banco

Edite o arquivo `.env`:

```env
DB_ENGINE=mariadb     # ou postgresql
```

## Rodar a API

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Rodar o teste de estresse (Locust)

```bash
locust -f locustfile.py --host http://localhost:8000
```

Abra `http://localhost:8089` no navegador para ver os gráficos em tempo real.

## Monitorar recursos

```bash
htop
```

## Fluxo completo de teste

### MariaDB

```bash
# 1. Altere .env para mariadb
# 2. Suba os bancos
docker compose up -d

# 3. Rode a API
uvicorn app.main:app --host 0.0.0.0 --port 8000

# 4. Em outro terminal, rode o Locust
locust -f locustfile.py --host http://localhost:8000

# 5. Em outro terminal, monitore com htop
htop
```

### PostgreSQL

```bash
# 1. Altere .env para postgresql
# 2. Reinicie a API (Ctrl+C e suba de novo)
uvicorn app.main:app --host 0.0.0.0 --port 8000

# 3. Repita os passos 4 e 5 do teste MariaDB
```
