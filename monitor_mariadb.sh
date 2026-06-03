#!/bin/bash
# Monitor MariaDB: docker stats + slow query log
# Atualiza a cada 2 segundos

watch -n 2 '
echo "========================================"
echo "  DOCKER STATS - MariaDB"
echo "========================================"
docker stats --no-stream estudo-mariadb 2>/dev/null
echo ""
echo "========================================"
echo "  SLOW QUERIES (últimas 15 linhas)"
echo "========================================"
docker exec estudo-mariadb tail -15 /var/log/mysql/mariadb-slow.log 2>/dev/null || echo "(nenhuma query lenta ainda)"
'
