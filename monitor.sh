#!/bin/bash
# monitor.sh - Coleta CPU, RAM, IO durante o benchmark
# Uso: bash monitor.sh <duracao_segundos> <prefixo>
# Ex:  bash monitor.sh 300 mariadb_teste

DURATION=${1:-300}
PREFIX=${2:-"benchmark"}

OUTDIR="./metricas"
mkdir -p "$OUTDIR"

DOCKER_CSV="${OUTDIR}/${PREFIX}_docker.csv"
VMSTAT_TXT="${OUTDIR}/${PREFIX}_vmstat.txt"

echo "============================================"
echo "  MONITOR DE RECURSOS"
echo "============================================"
echo " Duração : ${DURATION}s"
echo " Prefixo : ${PREFIX}"
echo " Docker  : ${DOCKER_CSV}"
echo " Sistema : ${VMSTAT_TXT}"
echo "============================================"
echo ""

# ── docker stats ──────────────────────────────────────
echo "[*] Iniciando docker stats..."

# header manual para CSV limpo
echo "timestamp,container,cpu%,mem_usage,mem_limit,mem%,net_i,net_o,block_i,block_o,pids" > "$DOCKER_CSV"

{
  for i in $(seq 1 "$DURATION"); do
    ts=$(date +%H:%M:%S)
    docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}" \
      estudo-mariadb estudo-postgres 2>/dev/null | while IFS=',' read -r name cpu mem memp net block pids; do
      # parse MemUsage "xxxMiB / yyyMiB"
      mem_used=$(echo "$mem" | awk '{print $1}')
      mem_limit=$(echo "$mem" | awk '{print $3}')
      net_i=$(echo "$net" | awk '{print $1}')
      net_o=$(echo "$net" | awk '{print $3}')
      block_i=$(echo "$block" | awk '{print $1}')
      block_o=$(echo "$block" | awk '{print $3}')
      echo "$ts,$name,$cpu,${mem_used},${mem_limit},$memp,${net_i},${net_o},${block_i},${block_o},$pids"
    done >> "$DOCKER_CSV"
    sleep 1
  done
} &
DOCKER_PID=$!

# ── vmstat ─────────────────────────────────────────────
echo "[*] Iniciando vmstat..."
echo "# timestamp  r  b  swpd  free  buff  cache  si  so  bi  bo  in  cs  us  sy  id  wa  st" > "$VMSTAT_TXT"

{
  for i in $(seq 1 "$DURATION"); do
    ts=$(date +%H:%M:%S)
    # second line of vmstat is the actual data
    vmstat 1 2 | tail -1 | awk -v t="$ts" '{print t, $0}' >> "$VMSTAT_TXT"
  done
} &
VMSTAT_PID=$!

# ── aguarda ────────────────────────────────────────────
echo "[*] Coletando por ${DURATION}s... (Ctrl+C para parar antes)"
sleep "$DURATION"
kill $DOCKER_PID $VMSTAT_PID 2>/dev/null
wait $DOCKER_PID $VMSTAT_PID 2>/dev/null

# ── resumo rápido ──────────────────────────────────────
echo ""
echo "============================================"
echo "  RESUMO RÁPIDO"
echo "============================================"

# media de CPU dos containers (ignorando containers parados)
for container in estudo-mariadb estudo-postgres; do
  avg_cpu=$(awk -F',' -v c="$container" '$2==c && $3 ~ /[0-9]/ {gsub(/%/,"",$3); sum+=$3; n++} END { if(n>0) printf "%.2f", sum/n; else print "N/A" }' "$DOCKER_CSV")
  avg_mem=$(awk -F',' -v c="$container" '$2==c && $6 ~ /[0-9]/ {gsub(/%/,"",$6); sum+=$6; n++} END { if(n>0) printf "%.2f", sum/n; else print "N/A" }' "$DOCKER_CSV")
  echo " $container → CPU média: ${avg_cpu}%  |  RAM média: ${avg_mem}%"
done

echo ""
avg_cpu_host=$(awk 'NR>1 && $13 ~ /[0-9]/ {sum_us+=$13; sum_sy+=$14; n++} END { if(n>0) printf "%.2f", (sum_us+sum_sy)/n; else print "N/A" }' "$VMSTAT_TXT")
avg_iowait=$(awk 'NR>1 && $16 ~ /[0-9]/ {sum+=$16; n++} END { if(n>0) printf "%.2f", sum/n; else print "N/A" }' "$VMSTAT_TXT")
echo " Host CPU média: ${avg_cpu_host}%  |  IO wait médio: ${avg_iowait}%"

echo ""
echo "[ok] Arquivos salvos em ${OUTDIR}/"
