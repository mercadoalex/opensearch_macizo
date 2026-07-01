#!/usr/bin/env bash
# 01-create-pipeline.sh — Crea una ingest pipeline para parsear logs.
#
# Procesadores: grok, date, remove, lowercase
# Respuesta esperada: {"acknowledged": true}

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando pipeline 'logs-pipeline'..."

curl -sk -X PUT "${OPENSEARCH_URL}/_ingest/pipeline/logs-pipeline" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "description": "Pipeline para parsear logs de aplicación",
  "processors": [
    {
      "grok": {
        "field": "message",
        "patterns": ["%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}"]
      }
    },
    {
      "date": {
        "field": "timestamp",
        "formats": ["ISO8601"],
        "target_field": "@timestamp"
      }
    },
    {
      "remove": {
        "field": "timestamp"
      }
    },
    {
      "lowercase": {
        "field": "level"
      }
    }
  ]
}' | python3 -m json.tool

echo "==> Pipeline creada exitosamente."
