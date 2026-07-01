#!/usr/bin/env bash
# 02-knn-search.sh — Búsqueda k-NN y búsqueda híbrida.
set -euo pipefail
URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Búsqueda k-NN: documentos cercanos a 'seguridad' [0.1, 0.1, 0.9]..."
curl -sk "$URL/demo-vectors/_search" -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "size": 3,
  "query": {"knn": {"embedding": {"vector": [0.1, 0.1, 0.9], "k": 3}}}
}' | python3 -c "
import sys, json
r = json.load(sys.stdin)
for h in r['hits']['hits']:
    print(f\"  {h['_score']:.4f} - {h['_source']['title']} [{h['_source']['category']}]\")
"

echo ""
echo "==> Búsqueda híbrida: texto 'seguridad' + vector [0.1, 0.1, 0.9]..."
curl -sk "$URL/demo-vectors/_search" -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "size": 3,
  "query": {
    "bool": {
      "should": [
        {"match": {"title": {"query": "seguridad", "boost": 0.3}}},
        {"knn": {"embedding": {"vector": [0.1, 0.1, 0.9], "k": 3, "boost": 0.7}}}
      ]
    }
  }
}' | python3 -c "
import sys, json
r = json.load(sys.stdin)
for h in r['hits']['hits']:
    print(f\"  {h['_score']:.4f} - {h['_source']['title']} [{h['_source']['category']}]\")
"
