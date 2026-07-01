#!/usr/bin/env bash
# 03-runqlat-opensearch.sh — Medir scheduling latency de threads OpenSearch.
# Detecta CPU starvation que la JVM no reporta.
# Requiere: bcc-tools, acceso root.

set -euo pipefail

OS_PID=$(pgrep -f opensearch 2>/dev/null || echo "")
if [ -z "$OS_PID" ]; then
  echo "ERROR: No se encontró proceso OpenSearch corriendo."
  exit 1
fi

echo "==> Midiendo run queue latency para OpenSearch (PID: $OS_PID)..."
echo "    Duración: 10 segundos"
echo "    Valores > 1ms (1024 usecs) indican CPU starvation."
echo ""

sudo runqlat -p "$OS_PID" 10
