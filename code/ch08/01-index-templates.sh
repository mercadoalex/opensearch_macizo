#!/bin/bash
# Capítulo 8: Index Templates — Component Templates + Composable Templates
# Prerequisito: Clúster OpenSearch corriendo (perfil novato o superior)

BASE_URL="https://localhost:9200"
AUTH="admin:Admin123!"

echo "=== 1. Crear Component Template: base-settings ==="
# Define settings reutilizables para cualquier índice
curl -sk -X PUT "$BASE_URL/_component_template/base-settings" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "refresh_interval": "5s",
      "index.codec": "best_compression"
    }
  }
}'
# Respuesta esperada: {"acknowledged":true}

echo ""
echo "=== 2. Crear Component Template: logs-mappings ==="
# Define mappings específicos para índices de logs
curl -sk -X PUT "$BASE_URL/_component_template/logs-mappings" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "template": {
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message": { "type": "text", "analyzer": "standard" },
        "level": { "type": "keyword" },
        "service": { "type": "keyword" },
        "host": { "type": "keyword" },
        "trace_id": { "type": "keyword" }
      }
    }
  }
}'
# Respuesta esperada: {"acknowledged":true}

echo ""
echo "=== 3. Crear Component Template: metrics-mappings ==="
# Define mappings para índices de métricas
curl -sk -X PUT "$BASE_URL/_component_template/metrics-mappings" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "template": {
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "metric_name": { "type": "keyword" },
        "value": { "type": "double" },
        "unit": { "type": "keyword" },
        "host": { "type": "keyword" },
        "tags": { "type": "keyword" }
      }
    }
  }
}'
# Respuesta esperada: {"acknowledged":true}

echo ""
echo "=== 4. Crear Composable Index Template: logs-template ==="
# Combina component templates y añade configuración de alias
curl -sk -X PUT "$BASE_URL/_index_template/logs-template" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["logs-*"],
  "priority": 100,
  "composed_of": ["base-settings", "logs-mappings"],
  "template": {
    "settings": {
      "number_of_replicas": 0
    },
    "aliases": {
      "logs-read": {}
    }
  },
  "_meta": {
    "description": "Template para índices de logs con retención",
    "author": "opensearch-macizo"
  }
}'
# Respuesta esperada: {"acknowledged":true}
# Nota: number_of_replicas:0 sobreescribe el valor del component template (1)
# La prioridad 100 asegura que este template gana si hay conflictos con otros

echo ""
echo "=== 5. Crear Composable Index Template: metrics-template ==="
curl -sk -X PUT "$BASE_URL/_index_template/metrics-template" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["metrics-*"],
  "priority": 100,
  "composed_of": ["base-settings", "metrics-mappings"],
  "template": {
    "settings": {
      "number_of_replicas": 0
    }
  }
}'
# Respuesta esperada: {"acknowledged":true}

echo ""
echo "=== 6. Verificar: crear un índice que matchee el patrón ==="
curl -sk -X PUT "$BASE_URL/logs-2024.03.15" \
  -u "$AUTH"
# Respuesta esperada: {"acknowledged":true,"shards_acknowledged":true,"index":"logs-2024.03.15"}

echo ""
echo "=== 7. Verificar que el mapping y settings se aplicaron ==="
curl -sk "$BASE_URL/logs-2024.03.15/_settings" -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/logs-2024.03.15/_settings" -u "$AUTH"
# Debería mostrar: number_of_shards:1, number_of_replicas:0, refresh_interval:5s

echo ""
curl -sk "$BASE_URL/logs-2024.03.15/_mapping" -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/logs-2024.03.15/_mapping" -u "$AUTH"
# Debería mostrar los campos: @timestamp, message, level, service, host, trace_id

echo ""
echo "=== 8. Listar index templates ==="
curl -sk "$BASE_URL/_index_template/logs-template" -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_index_template/logs-template" -u "$AUTH"

echo ""
echo "=== 9. Listar component templates ==="
curl -sk "$BASE_URL/_component_template/base-settings" -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_component_template/base-settings" -u "$AUTH"

echo ""
echo "Done. Templates creados y verificados."
