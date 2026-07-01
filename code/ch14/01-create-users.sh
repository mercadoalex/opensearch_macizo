#!/usr/bin/env bash
# 01-create-users.sh — Crear usuarios internos con el Security Plugin.
set -euo pipefail
URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando usuario app-reader..."
curl -sk -X PUT "${URL}/_plugins/_security/api/internalusers/app-reader" \
  -u "$AUTH" -H "Content-Type: application/json" \
  -d '{"password":"Reader#2024!","backend_roles":["readall"]}'
echo ""

echo "==> Creando usuario app-writer..."
curl -sk -X PUT "${URL}/_plugins/_security/api/internalusers/app-writer" \
  -u "$AUTH" -H "Content-Type: application/json" \
  -d '{"password":"Writer#2024!","backend_roles":["writeall"]}'
echo ""

echo "==> Listando usuarios..."
curl -sk "${URL}/_plugins/_security/api/internalusers" -u "$AUTH" | python3 -m json.tool
