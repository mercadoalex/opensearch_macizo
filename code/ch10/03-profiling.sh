#!/usr/bin/env bash
# 03-profiling.sh — Usa profile API para diagnosticar queries lentas.
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Ejecutando query con profile:true..."
curl -sk "${OPENSEARCH_URL}/ventas/_search" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "profile": true,
  "query": {
    "bool": {
      "must": [{"match": {"producto": "laptop"}}],
      "filter": [{"range": {"precio": {"gte": 500}}}]
    }
  }
}' | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f\"  took: {r['took']}ms\")
for shard in r.get('profile', {}).get('shards', []):
    for search in shard.get('searches', []):
        for q in search.get('query', []):
            print(f\"  Query type: {q['type']}, time: {q['time_in_nanos']/1e6:.2f}ms\")
            for child in q.get('children', []):
                print(f\"    └─ {child['type']}: {child['time_in_nanos']/1e6:.2f}ms\")
"
