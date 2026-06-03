#!/bin/bash
# Monitor PostgreSQL: docker stats + slow queries (via docker logs)
# Atualiza a cada 2 segundos

watch -n 2 '
echo "========================================"
echo "  DOCKER STATS - PostgreSQL"
echo "========================================"
docker stats --no-stream estudo-postgres 2>/dev/null
echo ""
echo "========================================"
echo "  SLOW QUERIES (últimas 15 linhas)"
echo "========================================"
docker logs estudo-postgres 2>&1 | grep "duration" | tail -15
'
