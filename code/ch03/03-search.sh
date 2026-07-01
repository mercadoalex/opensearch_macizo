#!/usr/bin/env bash
# 03-search.sh — Busca documentos en el índice "productos".
#
# Uso: bash code/ch03/03-search.sh
#
# Respuesta esperada (match_all):
# {
#     "hits": {
#         "total": { "value": N, "relation": "eq" },
#         "hits": [ { "_source": { "nombre": "...", ... } }, ... ]
#     }
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Búsqueda: match_all (todos los documentos)..."
echo ""

curl -sk "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": { "match_all": {} }
}' | python3 -m json.tool

echo ""
echo "==> Búsqueda: match por nombre..."
echo ""

curl -sk "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "match": { "nombre": "monitor" }
  }
}' | python3 -m json.tool

echo ""
echo "==> Búsqueda: term por categoría (keyword exacto)..."
echo ""

curl -sk "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "term": { "categoria": "laptops" }
  }
}' | python3 -m json.tool

echo ""
echo "==> Búsqueda: rango de precio..."
echo ""

curl -sk "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "range": {
      "precio": { "gte": 500, "lte": 1500 }
    }
  }
}' | python3 -m json.tool
