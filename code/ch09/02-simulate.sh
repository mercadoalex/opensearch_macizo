#!/usr/bin/env bash
# 02-simulate.sh — Prueba la pipeline con _simulate sin indexar documentos.
#
# Respuesta esperada: documentos transformados con @timestamp, level (lowercase), log_message

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Simulando pipeline 'logs-pipeline'..."

curl -sk -X POST "${OPENSEARCH_URL}/_ingest/pipeline/logs-pipeline/_simulate" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "docs": [
    {
      "_source": {
        "message": "2024-03-15T10:30:45.123Z ERROR Connection timeout to database"
      }
    },
    {
      "_source": {
        "message": "2024-03-15T10:31:00.456Z INFO Request processed successfully"
      }
    }
  ]
}' | python3 -m json.tool
