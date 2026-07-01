#!/usr/bin/env bash
# 01-create-index.sh — Crea el índice "productos" con mapping explícito.
#
# Uso: bash code/ch03/01-create-index.sh
#
# Respuesta esperada:
# {
#     "acknowledged": true,
#     "shards_acknowledged": true,
#     "index": "productos"
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando índice 'productos'..."

curl -sk -X PUT "${OPENSEARCH_URL}/productos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "nombre": { "type": "text" },
      "categoria": { "type": "keyword" },
      "precio": { "type": "float" },
      "en_stock": { "type": "boolean" },
      "fecha_agregado": { "type": "date" }
    }
  }
}' | python3 -m json.tool
