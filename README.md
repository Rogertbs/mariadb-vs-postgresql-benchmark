# MariaDB vs PostgreSQL — Estudo de Performance com FastAPI + Locust

> **mariadb-vs-postgresql-benchmark**

## Sobre

Projeto de benchmark para comparar o desempenho do **MariaDB** e **PostgreSQL** sob carga de estresse idêntica. A mesma API FastAPI consulta a mesma tabela (`registers`) com a mesma quantidade de dados (340 mil registros) em ambos os bancos, rodando no mesmo hardware (VPS). O objetivo é analisar latência, throughput, consumo de CPU/RAM e queries lentas de cada banco.

**Stack:** FastAPI + asyncpg/aiomysql + Locust + Docker + vmstat

**Fluxo do teste:**
1. API conecta no **MariaDB** → teste de estresse com Locust → coleta de métricas (monitor.sh + slow query log)
2. Troca `.env` para **PostgreSQL** → repete o mesmo teste
3. Compara resultados: RPS, latência (p50/p95/p99), CPU, RAM, queries lentas

## Dependências

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Endpoints da API

| Método | Rota                 | Peso  | Descrição                                      |
|--------|---------------------|-------|------------------------------------------------|
| GET    | `/dados`            | Leve  | `SELECT * LIMIT 500`                           |
| GET    | `/dados-data`       | Médio | `WHERE calldate BETWEEN` (indexado)            |
| GET    | `/dados-disposicao` | Médio | `WHERE disposition = 'ANSWERED'` (indexado)    |
| GET    | `/dados-texto`      | Pesado| `LIKE '%gateway%'` (full table scan)           |
| GET    | `/dados-agregado`   | Pesado| `GROUP BY + COUNT/AVG/SUM`                     |
| GET    | `/dados-ordenado`   | Pesado| `ORDER BY duration` (sem índice, filesort)     |
| GET    | `/dados-src`        | Médio | `GROUP BY src` ranking de ramais               |
| GET    | `/dados-contagem`   | Leve  | `COUNT(*)`                                     |
| POST   | `/dados-inserir`    | Médio | `INSERT` com dados aleatórios                  |
| GET    | `/health`           | Leve  | Healthcheck                                    |

## Subir os bancos

```bash
docker compose up -d
```

> MariaDB na porta **3306** / PostgreSQL na porta **5432**

## Acessar o CLI dos bancos

```bash
# MariaDB
docker exec -it estudo-mariadb mariadb -u root -proot estudo

# PostgreSQL
docker exec -it estudo-postgres psql -U postgres -d estudo
```

## Configuração de cache dos bancos

Ambos os bancos partem de configurações equivalentes, mas suas **arquiteturas de cache são radicalmente diferentes**. Isso impacta diretamente os resultados do benchmark.

### Tamanho do buffer

| Banco      | Parâmetro                | Valor        |
|-----------|--------------------------|--------------|
| MariaDB   | `innodb_buffer_pool_size`| **512MB**    |
| PostgreSQL| `shared_buffers`         | 128MB        |

> O MariaDB padrão viria com **128MB** — valor idêntico ao PostgreSQL. Aumentamos para **512MB** no `docker-compose.yml` para tornar o teste mais justo, já que o PostgreSQL se beneficia de um cache externo que o MariaDB não possui (veja abaixo).

### Por que o PostgreSQL tem vantagem com o mesmo valor?

**MariaDB (InnoDB)** — gerencia o cache sozinho. O `innodb_buffer_pool_size` é **tudo que ele tem**. O InnoDB tipicamente usa `O_DIRECT`, ignorando o page cache do sistema operacional. Se o working set (dados + índices acessados pelas queries) for maior que o buffer pool, o banco **vai a disco**. Com queries pesadas (full table scan, LIKE, ORDER BY sem índice, GROUP BY), o working set estoura o buffer pool facilmente, causando alto IO wait e latência elevada.

**PostgreSQL** — arquitetura de **cache duplo**: `shared_buffers` (128MB) **+ page cache do SO**. O PostgreSQL delega ao kernel o cache de páginas de dados. O parâmetro `effective_cache_size` (padrão 4GB) informa ao query planner quanto cache do SO está disponível. Na prática, se a máquina tem RAM sobrando, o **dataset inteiro fica no page cache do SO** — mesmo com `shared_buffers` pequeno. Isso explica os resultados do primeiro teste: zero IO wait para o PostgreSQL.

> **Conclusão:** o teste não é apenas "MariaDB vs PostgreSQL", mas também **"buffer pool próprio vs buffer pool + page cache do SO"**. O aumento para 512MB no MariaDB reduz (mas não elimina) essa desvantagem arquitetural.

## Trocar de banco

Edite o arquivo `.env`:

```env
DB_ENGINE=mariadb     # ou postgresql
```

## Rodar a API

```bash
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Fluxo completo de teste

São necessários **3 terminais** abertos simultaneamente.

### MariaDB

```bash
# 1. Configure o banco
#    Edite .env → DB_ENGINE=mariadb

# 2. Suba os containers
docker compose up -d
```

**Terminal 1 — Monitor de recursos:**

```bash
cd /opt/debian-mariadb-postgresql
bash monitor.sh 180 mariadb
```

**Terminal 2 — API:**

```bash
cd /opt/debian-mariadb-postgresql
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Terminal 3 — Locust (headless):**

```bash
cd /opt/debian-mariadb-postgresql
source venv/bin/activate
mkdir -p resultados
locust -f locustfile.py --headless \
  --run-time 2m \
  --csv=resultados/mariadb \
  --host http://localhost:8000
```

> `--headless` = modo terminal, sem interface web
> `--run-time 2m` = duracao total do teste (2 minutos)
> `--csv=resultados/mariadb` = prefixo dos CSVs de saida (RPS, latencias)
> `--host` = URL da API FastAPI
>
> **Estágios de usuários** (definidos no `LoadTestShape`):
> 0→15s: 10 usuários | 15→30s: 50 usuários | 30→50s: 200 usuários | 50→80s: 500 usuários | 80→120s: 500 usuários

### PostgreSQL

```bash
# 1. Altere .env → DB_ENGINE=postgresql

# 2. Reinicie os containers (limpa caches)
docker compose restart

# 3. Repita os 3 terminais do teste MariaDB
```

**Terminal 1 — Monitor de recursos:**

```bash
bash monitor.sh 180 postgres
```

**Terminal 2 — API:**

```bash
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Terminal 3 — Locust (headless):**

```bash
source venv/bin/activate
locust -f locustfile.py --headless \
  --run-time 2m \
  --csv=resultados/postgres \
  --host http://localhost:8000
```

> `--headless` = modo terminal, sem interface web
> `--run-time 2m` = duracao total do teste (2 minutos)
> `--csv=resultados/postgres` = prefixo dos CSVs de saida (RPS, latencias)
> `--host` = URL da API FastAPI
>
> **Estágios de usuários** (definidos no `LoadTestShape`):
> 0→15s: 10 usuários | 15→30s: 50 usuários | 30→50s: 200 usuários | 50→80s: 500 usuários | 80→120s: 500 usuários

## Parâmetros do Locust

Com o `LoadTestShape`, os usuários sobem automaticamente em estágios. Basta definir `--run-time` e `--csv`:

| Parâmetro      | Valor | Descrição                        |
|---------------|-------|----------------------------------|
| `--run-time`  | 2m    | Duração do teste                 |
| `--csv`       | ...   | Prefixo dos CSVs de resultado    |
| `--host`      | ...   | URL da API                       |
| `--headless`  |       | Modo terminal (sem interface web)|

> **Estágios do `LoadTestShape`:**
> | Tempo    | Usuários |
> |---------|----------|
> | 0→15s   | 10       |
> | 15→30s  | 50       |
> | 30→50s  | 200      |
> | 50→80s  | 500      |
> | 80→120s | 500      |
>
> Para usar controle manual com `-u`/`-r`, remova a classe `StagesShape` do `locustfile.py`.

## Locust com interface web

Se preferir visualizar os gráficos em tempo real, substitua o comando headless por:

```bash
locust -f locustfile.py --host http://localhost:8000
```

Abra `http://localhost:8089` no navegador, defina os parâmetros e clique em **Start**.

## Coleta de métricas (monitor.sh)

```bash
bash monitor.sh <duracao_segundos> <prefixo_saida>

# Exemplo: 3 minutos com prefixo "mariadb"
bash monitor.sh 180 mariadb
```

Gera na pasta `metricas/`:

| Arquivo                        | Conteúdo                                    |
|-------------------------------|---------------------------------------------|
| `<prefixo>_docker.csv`       | CPU%, RAM, Network IO, Block IO dos containers a cada 1s |
| `<prefixo>_vmstat.txt`       | CPU do host, IO wait, swap, memória a cada 1s           |

Ao final do tempo, o script exibe um resumo com a média de CPU e RAM de cada container e CPU/IO wait do host.

## Resultados gerados

Após rodar ambos os testes, compare:

```
metricas/
├── mariadb_docker.csv
├── mariadb_vmstat.txt
├── postgres_docker.csv
└── postgres_vmstat.txt

resultados/
├── mariadb_stats.csv        ← RPS, latência p50/p95/p99
├── mariadb_stats_history.csv
├── postgres_stats.csv
└── postgres_stats_history.csv
```

## Métricas a comparar

| Métrica               | MariaDB | PostgreSQL |
|----------------------|---------|------------|
| RPS médio            |         |            |
| Latência p50         |         |            |
| Latência p95         |         |            |
| Latência p99         |         |            |
| CPU médio (%)        |         |            |
| RAM média (%)        |         |            |
| IO wait médio (%)    |         |            |
| Falhas (%)           |         |            |

## Estrutura do projeto

```
├── app/
│   ├── main.py           # FastAPI (10 endpoints)
│   ├── database.py       # Conectores MariaDB/PostgreSQL + pool
│   └── queries.py        # 9 tipos de query (leves a pesadas)
├── locustfile.py         # Teste de estresse (9 tasks com pesos)
├── monitor.sh            # Coleta CPU, RAM, IO → CSV
├── benchmark.sh          # Script guiado com pausas (teste completo)
├── docker-compose.yml    # MariaDB + PostgreSQL
├── .env                  # DB_ENGINE=mariadb ou postgresql
└── requirements.txt      # Dependências Python
```
