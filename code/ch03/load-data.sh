#!/usr/bin/env bash
# load-data.sh — Carga los datos de ejemplo usando la Bulk API.
#
# Uso: bash code/ch03/load-data.sh
#
# Respuesta esperada:
# {
#     "took": ...,
#     "errors": false,
#     "items": [ ... ]
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Cargando datos de ejemplo desde sample-data.json..."

curl -sk -X POST "${OPENSEARCH_URL}/_bulk" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary "@${SCRIPT_DIR}/sample-data.json" | python3 -m json.tool

echo ""
echo "==> Verificando documentos cargados..."

curl -sk "${OPENSEARCH_URL}/productos/_count" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool
