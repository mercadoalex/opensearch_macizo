#!/usr/bin/env bash
# 02-analyze-text.sh — Usa la API _analyze para ver cómo OpenSearch tokeniza texto.
#
# Uso: bash code/ch04/02-analyze-text.sh
#
# Muestra la diferencia entre el analizador standard y el spanish,
# y cómo se descompone un texto en tokens.
#
# Respuesta esperada (analizador standard):
# Tokens: ["los", "servidores", "están", "funcionando", "correctamente"]
#
# Respuesta esperada (analizador spanish):
# Tokens: ["servidor", "funcionar", "correct"]

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Analizador 'standard' (por defecto):"
echo "    Texto: 'Los servidores están funcionando correctamente'"
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/_analyze" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "analyzer": "standard",
  "text": "Los servidores están funcionando correctamente"
}' | python3 -m json.tool

echo ""
echo "=========================================="
echo ""
echo "==> Analizador 'spanish' (stemming + stopwords):"
echo "    Texto: 'Los servidores están funcionando correctamente'"
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/_analyze" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "analyzer": "spanish",
  "text": "Los servidores están funcionando correctamente"
}' | python3 -m json.tool

echo ""
echo "=========================================="
echo ""
echo "==> Analizando con tokenizer y filtros individuales:"
echo "    Texto: 'OpenSearch es RÁPIDO y potente'"
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/_analyze" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "tokenizer": "standard",
  "filter": ["lowercase", "asciifolding"],
  "text": "OpenSearch es RÁPIDO y potente"
}' | python3 -m json.tool

echo ""
echo "=========================================="
echo ""
echo "==> Analizando contra un campo específico del índice 'productos':"
echo "    Campo: nombre (usa analizador spanish)"
echo "    Texto: 'Laptops gaming de última generación'"
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/productos/_analyze" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "field": "nombre",
  "text": "Laptops gaming de última generación"
}' | python3 -m json.tool
