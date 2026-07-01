#!/usr/bin/env bash
# verify-cluster.sh — Verifica que el clúster OpenSearch está operativo.
#
# Uso: bash code/ch02/verify-cluster.sh
#
# Respuesta esperada:
# {
#     "cluster_name": "opensearch-macizo",
#     "status": "green",
#     "number_of_nodes": 1,
#     ...
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Verificando clúster en ${OPENSEARCH_URL}..."

RESPONSE=$(curl -sk -w "\n%{http_code}" \
  "${OPENSEARCH_URL}/_cluster/health" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "==> HTTP 200 OK"
  echo "$BODY" | python3 -m json.tool
  STATUS=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
  if [ "$STATUS" = "green" ] || [ "$STATUS" = "yellow" ]; then
    echo "==> Clúster saludable (status: ${STATUS})"
    exit 0
  else
    echo "==> ADVERTENCIA: clúster en status ${STATUS}"
    exit 1
  fi
else
  echo "==> ERROR: HTTP ${HTTP_CODE}"
  echo "$BODY"
  exit 1
fi
