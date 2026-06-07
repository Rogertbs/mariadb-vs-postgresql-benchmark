#!/bin/bash
# benchmark.sh — Teste comparativo MariaDB vs PostgreSQL (guiado, com pausas)
# Ideal para video: cada passo espera ENTER para continuar, explicando o que acontece.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

BOLD='\033[1m'
RESET='\033[0m'

USERS=500
SPAWN_RATE=50
RUN_TIME="5m"

pausa() {
  echo ""
  echo -e "${YELLOW}>>> Pressione ENTER para continuar...${NC}"
  read -r
}

banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║   BENCHMARK: MariaDB vs PostgreSQL                   ║"
  echo "║   FastAPI + Locust + Docker                          ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo "Config: ${USERS} usuarios | spawn ${SPAWN_RATE}/s | duracao ${RUN_TIME}"
  echo ""
}

troca_banco() {
  local engine=$1
  sed -i "s/^DB_ENGINE=.*/DB_ENGINE=${engine}/" .env
  echo -e "${GREEN}[ok] .env → DB_ENGINE=${engine}${NC}"
}

# ══════════════════════════════════════════════════════════
#  PASSO 1: Verificar ambiente
# ══════════════════════════════════════════════════════════
banner
echo -e "${BOLD} PASSO 1: Verificando ambiente${NC}"
echo "----------------------------------------"
pausa

docker compose ps 2>/dev/null || echo "(containers nao estao rodando ainda)"
echo ""
echo "Endpoints disponiveis:"
echo "  GET  /dados              → SELECT * LIMIT 500"
echo "  GET  /dados-data         → WHERE calldate BETWEEN"
echo "  GET  /dados-disposicao   → WHERE disposition = ANSWERED"
echo "  GET  /dados-texto        → WHERE lastdata LIKE '%gateway%'"
echo "  GET  /dados-agregado     → GROUP BY + COUNT/AVG/SUM"
echo "  GET  /dados-ordenado     → ORDER BY duration (sem indice)"
echo "  GET  /dados-src          → GROUP BY src (ranking)"
echo "  GET  /dados-contagem     → COUNT(*)"
echo "  POST /dados-inserir      → INSERT"
echo "  GET  /health             → healthcheck"
echo ""
echo "Locust tasks (com pesos):"
echo "  3x busca_simples       2x busca_data"
echo "  2x busca_disposicao    1x busca_texto"
echo "  1x busca_agregado      1x busca_ordenado"
echo "  1x busca_src           1x insere"
echo "  1x contagem"
pausa

# ══════════════════════════════════════════════════════════
#  PASSO 2: Subir containers
# ══════════════════════════════════════════════════════════
banner
echo -e "${BOLD} PASSO 2: Subindo MariaDB + PostgreSQL${NC}"
echo "----------------------------------------"
echo "docker compose up -d"
pausa

docker compose up -d
echo -e "${GREEN}[ok] Containers iniciados${NC}"
echo ""
echo "Aguardando bancos ficarem prontos..."
sleep 10
docker compose ps
pausa

# ══════════════════════════════════════════════════════════
#  PASSO 3: Teste MariaDB
# ══════════════════════════════════════════════════════════
banner
echo -e "${BOLD}${RED} PASSO 3: TESTE MariaDB${NC}"
echo "----------------------------------------"
troca_banco "mariadb"
pausa

echo -e "${YELLOW} Abra outro terminal e execute:${NC}"
echo ""
echo -e "  ${CYAN}cd /opt/debian-mariadb-postgresql && source venv/bin/activate${NC}"
echo -e "  ${CYAN}uvicorn app.main:app --host 0.0.0.0 --port 8000${NC}"
echo ""
echo -e "${YELLOW} Em um terceiro terminal, inicie o monitor:${NC}"
echo ""
echo -e "  ${CYAN}cd /opt/debian-mariadb-postgresql && bash monitor.sh 360 mariadb${NC}"
echo ""
pausa

banner
echo -e "${RED} MARIADB — Iniciando Locust (headless)${NC}"
echo "----------------------------------------"
echo "Comando:"
echo "  locust -f locustfile.py --headless \\"
echo "    -u ${USERS} -r ${SPAWN_RATE} \\"
echo "    --run-time ${RUN_TIME} \\"
echo "    --csv=resultados/mariadb \\"
echo "    --host http://localhost:8000"
echo ""
pausa

mkdir -p resultados
locust -f locustfile.py --headless \
  -u "$USERS" -r "$SPAWN_RATE" \
  --run-time "$RUN_TIME" \
  --csv=resultados/mariadb \
  --host http://localhost:8000

echo ""
echo -e "${GREEN}[ok] Teste MariaDB concluido!${NC}"
echo "Resultados em: resultados/mariadb_*.csv"
echo ""
echo -e "${YELLOW}>> Pare o monitor.sh (Ctrl+C) e o uvicorn (Ctrl+C) antes de continuar${NC}"
pausa

# ══════════════════════════════════════════════════════════
#  PASSO 4: Limpar caches / reiniciar
# ══════════════════════════════════════════════════════════
banner
echo -e "${BOLD} PASSO 4: Reiniciando containers (limpa caches)${NC}"
echo "----------------------------------------"
echo "docker compose restart"
pausa

docker compose restart
sleep 10
echo -e "${GREEN}[ok] Containers reiniciados — caches limpos${NC}"
pausa

# ══════════════════════════════════════════════════════════
#  PASSO 5: Teste PostgreSQL
# ══════════════════════════════════════════════════════════
banner
echo -e "${BOLD}${RED} PASSO 5: TESTE PostgreSQL${NC}"
echo "----------------------------------------"
troca_banco "postgresql"
pausa

echo -e "${YELLOW} Abra outro terminal e execute:${NC}"
echo ""
echo -e "  ${CYAN}cd /opt/debian-mariadb-postgresql && source venv/bin/activate${NC}"
echo -e "  ${CYAN}uvicorn app.main:app --host 0.0.0.0 --port 8000${NC}"
echo ""
echo -e "${YELLOW} Em um terceiro terminal, inicie o monitor:${NC}"
echo ""
echo -e "  ${CYAN}cd /opt/debian-mariadb-postgresql && bash monitor.sh 360 postgres${NC}"
echo ""
pausa

banner
echo -e "${RED} POSTGRESQL — Iniciando Locust (headless)${NC}"
echo "----------------------------------------"
echo "Comando:"
echo "  locust -f locustfile.py --headless \\"
echo "    -u ${USERS} -r ${SPAWN_RATE} \\"
echo "    --run-time ${RUN_TIME} \\"
echo "    --csv=resultados/postgres \\"
echo "    --host http://localhost:8000"
echo ""
pausa

mkdir -p resultados
locust -f locustfile.py --headless \
  -u "$USERS" -r "$SPAWN_RATE" \
  --run-time "$RUN_TIME" \
  --csv=resultados/postgres \
  --host http://localhost:8000

echo ""
echo -e "${GREEN}[ok] Teste PostgreSQL concluido!${NC}"
echo "Resultados em: resultados/postgres_*.csv"
echo ""
echo -e "${YELLOW}>> Pare o monitor.sh (Ctrl+C) e o uvicorn (Ctrl+C)${NC}"
pausa

# ══════════════════════════════════════════════════════════
#  PASSO 6: Comparação
# ══════════════════════════════════════════════════════════
banner
echo -e "${BOLD}${GREEN} PASSO 6: COMPARAÇÃO DOS RESULTADOS${NC}"
echo "========================================"
echo ""
echo "Arquivos gerados:"
ls -la resultados/ 2>/dev/null || echo "(diretorio resultados vazio)"
echo ""
echo "Para comparar, veja:"
echo "  → resultados/mariadb_stats.csv     (RPS, latencia p50/p95/p99)"
echo "  → resultados/postgres_stats.csv"
echo "  → metricas/mariadb_docker.csv      (CPU, RAM dos containers)"
echo "  → metricas/postgres_docker.csv"
echo "  → metricas/mariadb_vmstat.txt      (CPU host, IO wait)"
echo "  → metricas/postgres_vmstat.txt"
echo ""
echo -e "${GREEN}${BOLD} BENCHMARK CONCLUIDO!${NC}"
