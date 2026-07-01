#!/usr/bin/env bash
# 03-error-handling.sh — Pipeline con on_failure para manejo de errores graceful.
#
# Si grok falla, el documento se indexa con tag _grok_parse_failure.

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando pipeline con manejo de errores..."

curl -sk -X PUT "${OPENSEARCH_URL}/_ingest/pipeline/logs-safe" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "description": "Pipeline con fallback para logs no parseables",
  "processors": [
    {
      "grok": {
        "field": "message",
        "patterns": ["%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}"],
        "on_failure": [
          {
            "set": {
              "field": "raw_message",
              "value": "{{{message}}}"
            }
          },
          {
            "set": {
              "field": "_tags",
              "value": ["_grok_parse_failure"]
            }
          }
        ]
      }
    }
  ]
}' | python3 -m json.tool

echo ""
echo "==> Simulando con documento que NO matchea el patrón grok..."

curl -sk -X POST "${OPENSEARCH_URL}/_ingest/pipeline/logs-safe/_simulate" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "docs": [
    {
      "_source": { "message": "Este mensaje no tiene formato de log estándar" }
    },
    {
      "_source": { "message": "2024-03-15T10:30:45.123Z ERROR Formato correcto" }
    }
  ]
}' | python3 -m json.tool
