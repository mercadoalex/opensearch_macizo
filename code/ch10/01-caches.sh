#!/usr/bin/env bash
# 01-caches.sh — Demuestra request cache y query cache.
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Estado de caches antes..."
curl -sk "${OPENSEARCH_URL}/_nodes/stats/indices/query_cache,request_cache,fielddata" \
  -u "$AUTH" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for node, info in d['nodes'].items():
    print(f\"  Node: {info['name']}\")
    print(f\"    Query cache: {info['indices']['query_cache']}\")
    print(f\"    Request cache: {info['indices']['request_cache']}\")
"

echo ""
echo "==> Ejecutando query con request_cache=true (aggregation)..."
curl -sk "${OPENSEARCH_URL}/ventas/_search?request_cache=true&size=0" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"aggs": {"total": {"sum": {"field": "precio"}}}}' > /dev/null

echo "==> Ejecutando misma query de nuevo (debería usar cache)..."
curl -sk "${OPENSEARCH_URL}/ventas/_search?request_cache=true&size=0" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"aggs": {"total": {"sum": {"field": "precio"}}}}' > /dev/null

echo ""
echo "==> Estado de caches después..."
curl -sk "${OPENSEARCH_URL}/_nodes/stats/indices/query_cache,request_cache" \
  -u "$AUTH" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for node, info in d['nodes'].items():
    rc = info['indices']['request_cache']
    print(f\"  Request cache - hit: {rc['hit_count']}, miss: {rc['miss_count']}, size: {rc['memory_size_in_bytes']}B\")
"
