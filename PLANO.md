# Estudo de Caso: MariaDB vs PostgreSQL

## Objetivo
Comparar o desempenho de MariaDB e PostgreSQL sob as mesmas condições:
- Mesma tabela, mesma quantidade de dados (dump do MariaDB será fornecido)
- Mesmo hardware (VPS)
- Mesma API FastAPI
- Mesmo teste de estresse (Locust)
- Análise via gráficos do Locust + `htop` (CPU/RAM)

## Estrutura do Projeto

```
/opt/debian-mariadb-postgresql/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── database.py          # Conectores: MariaDB e PostgreSQL
│   └── queries.py           # Função com SELECT para buscar dados
├── locustfile.py            # Script de teste de estresse
├── requirements.txt         # Dependências
├── docker-compose.yml       # MariaDB + PostgreSQL
├── .env                     # DB_ENGINE=mariadb ou postgresql
└── PLANO.md                 # Este arquivo
```

## Stack

| Componente     | Tecnologia                   |
|---------------|------------------------------|
| API           | FastAPI + Uvicorn             |
| Conector      | asyncpg (Postgres) / aiomysql (MariaDB) |
| DB 1          | MariaDB                       |
| DB 2          | PostgreSQL                    |
| Stress Test   | Locust                        |
| Monitoramento | htop                          |

## Mecanismo de Troca de Banco

Arquivo `.env`:

```env
DB_ENGINE=mariadb
# ou
DB_ENGINE=postgresql
```

A aplicação lê `DB_ENGINE` e seleciona o conector adequado no `database.py`.

## Endpoint da API

| Método | Rota        | Descrição                              |
|--------|------------|----------------------------------------|
| GET    | /dados     | Executa query SELECT e retorna resultados |

Fluxo: `GET /dados` → `queries.py::buscar_dados()` → SELECT no banco → retorna JSON

## Containers

Ambos os bancos sobem via `docker-compose.yml` com volumes persistentes.

| Serviço    | Porta | Usuário | Senha   | Database    |
|-----------|-------|---------|---------|-------------|
| mariadb   | 3306  | root    | root    | estudo      |
| postgres  | 5432  | postgres| postgres| estudo      |

## Plano de Teste

### Fase 1: Preparação
1. Subir containers: `docker compose up -d`
2. Importar dump no MariaDB
3. Converter e importar dump no PostgreSQL
4. Popular dados (via dump do usuário)

### Fase 2: Teste MariaDB
1. Configurar `.env`: `DB_ENGINE=mariadb`
2. Rodar API: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
3. Rodar Locust com 50, 100, 200, 500 usuários simultâneos
4. Acompanhar `htop` durante o teste
5. Salvar screenshots/CSV dos resultados

### Fase 3: Teste PostgreSQL
1. Configurar `.env`: `DB_ENGINE=postgresql`
2. Rodar API: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
3. Rodar Locust com os mesmos parâmetros da Fase 2
4. Acompanhar `htop` durante o teste
5. Salvar screenshots/CSV dos resultados

### Fase 4: Análise
- Comparar gráficos de latência (p50, p95, p99)
- Comparar throughput (RPS)
- Comparar uso de CPU/RAM via `htop`
- Documentar conclusões

## Locust

Interface web em `http://localhost:8089` com gráficos em tempo real.

### locustfile.py
```python
from locust import HttpUser, task, between

class ApiUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def buscar_dados(self):
        self.client.get("/dados")
```

## Comandos

```bash
# Subir bancos
docker compose up -d

# Iniciar API
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Iniciar Locust
locust -f locustfile.py --host http://localhost:8000

# Monitorar (outro terminal)
htop
```

## Métricas a Coletar

| Métrica               | MariaDB | PostgreSQL |
|----------------------|---------|------------|
| RPS médio            |         |            |
| Latência p50         |         |            |
| Latência p95         |         |            |
| Latência p99         |         |            |
| CPU médio (%)        |         |            |
| RAM média (MB)       |         |            |
| Falhas (%)           |         |            |
| Conexões simultâneas |         |            |
