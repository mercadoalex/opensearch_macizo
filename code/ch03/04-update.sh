#!/usr/bin/env bash
# 04-update.sh — Actualiza un documento existente en el índice "productos".
#
# Uso: bash code/ch03/04-update.sh
#
# Respuesta esperada:
# {
#     "_index": "productos",
#     "_id": "1",
#     "_version": 2,
#     "result": "updated",
#     ...
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Actualización parcial: cambiar precio del documento ID=1..."

curl -sk -X POST "${OPENSEARCH_URL}/productos/_update/1" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "doc": {
    "precio": 1149.99,
    "en_stock": false
  }
}' | python3 -m json.tool

echo ""
echo "==> Verificar la actualización (GET por ID)..."

curl -sk "${OPENSEARCH_URL}/productos/_doc/1" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

echo ""
echo "==> Actualización con script: incrementar precio en 10%..."

curl -sk -X POST "${OPENSEARCH_URL}/productos/_update/2" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "script": {
    "source": "ctx._source.precio = ctx._source.precio * 1.10",
    "lang": "painless"
  }
}' | python3 -m json.tool
