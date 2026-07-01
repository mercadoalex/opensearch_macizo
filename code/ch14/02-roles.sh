#!/usr/bin/env bash
# 02-roles.sh — Crear roles con permisos granulares y mapearlos a usuarios.
set -euo pipefail
URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando rol logs-reader..."
curl -sk -X PUT "${URL}/_plugins/_security/api/roles/logs-reader" \
  -u "$AUTH" -H "Content-Type: application/json" \
  -d '{
  "cluster_permissions": ["cluster_composite_ops_ro"],
  "index_permissions": [{"index_patterns": ["logs-*"], "allowed_actions": ["read","search"]}]
}'
echo ""

echo "==> Mapeando rol a usuario app-reader..."
curl -sk -X PUT "${URL}/_plugins/_security/api/rolesmapping/logs-reader" \
  -u "$AUTH" -H "Content-Type: application/json" \
  -d '{"users": ["app-reader"]}'
echo ""

echo "==> Verificando con app-reader..."
curl -sk "${URL}/logs-*/_search?size=1" -u "app-reader:Reader#2024!" | python3 -m json.tool 2>/dev/null || echo "  (Sin datos en logs-* aún)"
