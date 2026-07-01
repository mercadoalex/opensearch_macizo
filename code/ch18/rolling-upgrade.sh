#!/usr/bin/env bash
# rolling-upgrade.sh — Procedimiento de rolling upgrade sin downtime.
# NOTA: Este script simula el procedimiento. En producción, aplica a cada nodo.
set -euo pipefail
URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "=== Rolling Upgrade Procedure ==="
echo ""

echo "1. Disable shard allocation..."
curl -sk -X PUT "$URL/_cluster/settings" -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"persistent":{"cluster.routing.allocation.enable":"primaries"}}' | python3 -m json.tool
echo ""

echo "2. Flush synced..."
curl -sk -X POST "$URL/_flush" -u "$AUTH" | python3 -m json.tool
echo ""

echo "3. [MANUAL] Stop node, upgrade binary, restart node"
echo "   En producción: systemctl stop opensearch && yum upgrade opensearch && systemctl start opensearch"
echo ""

echo "4. Verify node rejoined..."
curl -sk "$URL/_cat/nodes?v" -u "$AUTH"
echo ""

echo "5. Re-enable allocation..."
curl -sk -X PUT "$URL/_cluster/settings" -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"persistent":{"cluster.routing.allocation.enable":"all"}}' | python3 -m json.tool
echo ""

echo "6. Wait for green..."
curl -sk "$URL/_cluster/health?wait_for_status=green&timeout=2m" -u "$AUTH" | python3 -m json.tool
echo ""

echo "=== Done. Repeat for each node. ==="
