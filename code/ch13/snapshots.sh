#!/usr/bin/env bash
# snapshots.sh — Crear y restaurar snapshots (usando repo tipo fs para lab).
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Registrando snapshot repository (tipo fs para lab)..."
curl -sk -X PUT "${OPENSEARCH_URL}/_snapshot/lab-backups" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "type": "fs",
  "settings": {
    "location": "/usr/share/opensearch/snapshots"
  }
}' | python3 -m json.tool

echo ""
echo "==> Creando snapshot de índices productos y ventas..."
curl -sk -X PUT "${OPENSEARCH_URL}/_snapshot/lab-backups/snap-lab-01?wait_for_completion=true" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "indices": "productos,ventas",
  "include_global_state": false
}' | python3 -m json.tool

echo ""
echo "==> Listando snapshots..."
curl -sk "${OPENSEARCH_URL}/_snapshot/lab-backups/_all" \
  -u "$AUTH" | python3 -m json.tool

echo ""
echo "==> Para restaurar (descomenta y ejecuta):"
echo '# curl -sk -X POST "${OPENSEARCH_URL}/_snapshot/lab-backups/snap-lab-01/_restore" \'
echo '#   -u "$AUTH" -H "Content-Type: application/json" \'
echo '#   -d {"indices": "productos", "rename_pattern": "(.+)", "rename_replacement": "restored-\$1"}'
