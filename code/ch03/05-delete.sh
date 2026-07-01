#!/usr/bin/env bash
# 05-delete.sh — Elimina un documento y un índice completo.
#
# Uso: bash code/ch03/05-delete.sh
#
# Respuesta esperada (eliminar documento):
# {
#     "_index": "productos",
#     "_id": "6",
#     "_version": 2,
#     "result": "deleted",
#     ...
# }
#
# Respuesta esperada (eliminar índice):
# {
#     "acknowledged": true
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Eliminar documento con ID=6..."

curl -sk -X DELETE "${OPENSEARCH_URL}/productos/_doc/6" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

echo ""
echo "==> Verificar que el documento ya no existe..."

curl -sk "${OPENSEARCH_URL}/productos/_doc/6" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

echo ""
echo "==> Eliminar el índice completo..."

curl -sk -X DELETE "${OPENSEARCH_URL}/productos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool
