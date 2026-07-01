#!/bin/bash
# Capítulo 8: Desplegar configuración de indexación desde YAML
# Demuestra cómo aplicar la configuración declarativa de 05-ism-config.yml
# En producción usarías herramientas como Terraform o scripts CI/CD
#
# Prerequisito: Clúster OpenSearch corriendo (perfil novato o superior)
# Prerequisito: yq instalado (https://github.com/mikefarah/yq)

BASE_URL="https://localhost:9200"
AUTH="admin:Admin123!"
CONFIG="05-ism-config.yml"

echo "=== Desplegando configuración de indexación ==="
echo "Archivo: $CONFIG"
echo ""

# --- 1. Aplicar cluster settings ---
echo "--- Paso 1: Cluster settings ---"
curl -sk -X PUT "$BASE_URL/_cluster/settings" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "persistent": {
    "plugins.index_state_management.enabled": true,
    "plugins.index_state_management.job_interval": 5
  }
}'
# Respuesta esperada: {"acknowledged":true,...}
echo ""

# --- 2. Crear component templates ---
echo ""
echo "--- Paso 2: Component templates ---"

echo "Creando: base-settings"
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
echo ""

echo "Creando: logs-mappings"
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
echo ""

echo "Creando: metrics-mappings"
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
echo ""

# --- 3. Crear index templates ---
echo ""
echo "--- Paso 3: Index templates ---"

echo "Creando: logs-template"
curl -sk -X PUT "$BASE_URL/_index_template/logs-template" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["logs-*"],
  "priority": 100,
  "composed_of": ["base-settings", "logs-mappings"],
  "template": {
    "settings": { "number_of_replicas": 0 },
    "aliases": { "logs-read": {} }
  },
  "_meta": { "description": "Template para índices de logs", "author": "opensearch-macizo" }
}'
echo ""

echo "Creando: metrics-template"
curl -sk -X PUT "$BASE_URL/_index_template/metrics-template" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["metrics-*"],
  "priority": 100,
  "composed_of": ["base-settings", "metrics-mappings"],
  "template": { "settings": { "number_of_replicas": 0 } }
}'
echo ""

# --- 4. Crear ISM policies ---
echo ""
echo "--- Paso 4: ISM policies ---"

echo "Creando: logs-lifecycle"
curl -sk -X PUT "$BASE_URL/_plugins/_ism/policies/logs-lifecycle" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d @ism-policy.json
echo ""

echo "Creando: metrics-lifecycle"
curl -sk -X PUT "$BASE_URL/_plugins/_ism/policies/metrics-lifecycle" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "description": "Ciclo de vida métricas: hot → cold → delete",
    "default_state": "hot",
    "ism_template": [{ "index_patterns": ["metrics-*"], "priority": 100 }],
    "states": [
      {
        "name": "hot",
        "actions": [{ "rollover": { "min_size": "5gb", "min_index_age": "1d" } }],
        "transitions": [{ "state_name": "cold", "conditions": { "min_index_age": "7d" } }]
      },
      {
        "name": "cold",
        "actions": [{ "replica_count": { "number_of_replicas": 0 } }, { "close": {} }],
        "transitions": [{ "state_name": "delete", "conditions": { "min_index_age": "90d" } }]
      },
      {
        "name": "delete",
        "actions": [{ "delete": {} }],
        "transitions": []
      }
    ]
  }
}'
echo ""

# --- 5. Verificar ---
echo ""
echo "--- Paso 5: Verificación ---"
echo "Templates:"
curl -sk "$BASE_URL/_cat/templates?v&s=name" -u "$AUTH"
echo ""
echo "ISM Policies:"
curl -sk "$BASE_URL/_plugins/_ism/policies" -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_plugins/_ism/policies" -u "$AUTH"

echo ""
echo "Done. Configuración desplegada desde YAML."
echo "En producción, automatiza este proceso con CI/CD (GitHub Actions, Jenkins, etc.)"
