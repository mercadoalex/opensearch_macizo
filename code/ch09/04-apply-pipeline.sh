#!/usr/bin/env bash
# 04-apply-pipeline.sh — Indexa documentos usando la pipeline.
#
# Demuestra dos formas: parámetro ?pipeline= y default_pipeline en settings.

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Indexando documento con pipeline explícita..."

curl -sk -X POST "${OPENSEARCH_URL}/logs/_doc?pipeline=logs-pipeline" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "message": "2024-03-15T14:22:10.789Z WARN Disk usage above 80%"
}' | python3 -m json.tool

echo ""
echo "==> Verificando documento transformado..."

curl -sk "${OPENSEARCH_URL}/logs/_search?pretty" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query": {"match_all": {}}}' | python3 -m json.tool

echo ""
echo "==> Creando índice con default_pipeline..."

curl -sk -X PUT "${OPENSEARCH_URL}/app-logs" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "default_pipeline": "logs-pipeline"
  }
}' | python3 -m json.tool

echo ""
echo "==> Indexando en app-logs (pipeline se aplica automáticamente)..."

curl -sk -X POST "${OPENSEARCH_URL}/app-logs/_doc" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "message": "2024-03-15T15:00:00.000Z INFO User login successful"
}' | python3 -m json.tool
