#!/usr/bin/env bash
# 01-biosnoop-opensearch.sh — Trazar disk I/O del proceso OpenSearch.
# Requiere: bcc-tools instalado, acceso root.
# Uso: sudo bash code/ebpf/01-biosnoop-opensearch.sh

set -euo pipefail

OS_PID=$(pgrep -f opensearch 2>/dev/null || echo "")
if [ -z "$OS_PID" ]; then
  echo "ERROR: No se encontró proceso OpenSearch corriendo."
  echo "Levanta el laboratorio primero: docker compose --profile novato up"
  exit 1
fi

echo "==> Trazando disk I/O del proceso OpenSearch (PID: $OS_PID) por 30 segundos..."
echo "    Busca operaciones con LAT > 5ms en SSDs como señal de contención."
echo ""

sudo biosnoop -p "$OS_PID" --duration 30
