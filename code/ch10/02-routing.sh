#!/usr/bin/env bash
# 02-routing.sh — Demuestra routing custom para búsquedas dirigidas a un shard.
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Búsqueda SIN routing (fan-out a todos los shards)..."
curl -sk "${OPENSEARCH_URL}/ventas/_search" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"query": {"term": {"region": "CDMX"}}}' | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f\"  took: {r['took']}ms, shards: {r['_shards']['total']} total, {r['_shards']['successful']} successful\")
print(f\"  hits: {r['hits']['total']['value']}\")
"

echo ""
echo "==> Búsqueda CON routing=CDMX (solo un shard)..."
curl -sk "${OPENSEARCH_URL}/ventas/_search?routing=CDMX" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"query": {"term": {"region": "CDMX"}}}' | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f\"  took: {r['took']}ms, shards: {r['_shards']['total']} total, {r['_shards']['successful']} successful\")
print(f\"  hits: {r['hits']['total']['value']}\")
"
