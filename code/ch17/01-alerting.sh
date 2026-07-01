#!/usr/bin/env bash
# 01-alerting.sh — Crear monitor de alerting para errores.
set -euo pipefail
URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando monitor 'high-error-rate'..."
curl -sk -X POST "$URL/_plugins/_alerting/monitors" \
  -u "$AUTH" -H "Content-Type: application/json" \
  -d '{
  "name": "high-error-rate",
  "type": "monitor",
  "enabled": true,
  "schedule": {"period": {"interval": 5, "unit": "MINUTES"}},
  "inputs": [{
    "search": {
      "indices": ["logs-*"],
      "query": {
        "size": 0,
        "query": {"bool": {"filter": [
          {"term": {"level": "error"}},
          {"range": {"@timestamp": {"gte": "now-5m"}}}
        ]}},
        "aggs": {"error_count": {"value_count": {"field": "_id"}}}
      }
    }
  }],
  "triggers": [{
    "name": "too-many-errors",
    "severity": "2",
    "condition": {"script": {"source": "ctx.results[0].aggregations.error_count.value > 100"}},
    "actions": []
  }]
}' | python3 -m json.tool

echo ""
echo "==> Monitor creado. Configurar destination (Slack/webhook) para actions."
