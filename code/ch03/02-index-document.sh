#!/usr/bin/env bash
# 02-index-document.sh — Indexa un documento individual en el índice "productos".
#
# Uso: bash code/ch03/02-index-document.sh
#
# Respuesta esperada:
# {
#     "_index": "productos",
#     "_id": "6",
#     "_version": 1,
#     "result": "created",
#     "_shards": { "total": 1, "successful": 1, "failed": 0 },
#     "_seq_no": ...,
#     "_primary_term": 1
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Indexando documento con ID explícito..."

curl -sk -X PUT "${OPENSEARCH_URL}/productos/_doc/6" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "nombre": "Teclado mecánico RGB",
  "categoria": "perifericos",
  "precio": 89.99,
  "en_stock": true,
  "fecha_agregado": "2024-03-15"
}' | python3 -m json.tool

echo ""
echo "==> Indexando documento con ID auto-generado..."

curl -sk -X POST "${OPENSEARCH_URL}/productos/_doc" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "nombre": "Webcam 4K con micrófono",
  "categoria": "perifericos",
  "precio": 129.50,
  "en_stock": false,
  "fecha_agregado": "2024-04-01"
}' | python3 -m json.tool
