#!/bin/bash
# Capítulo 8: Rollover — Rotación automática de índices
# Prerequisito: Clúster OpenSearch corriendo (perfil novato o superior)

BASE_URL="https://localhost:9200"
AUTH="admin:Admin123!"

echo "=== 1. Crear index template con rollover_alias ==="
# El template configura el alias para que rollover funcione automáticamente
curl -sk -X PUT "$BASE_URL/_index_template/events-template" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["events-*"],
  "priority": 100,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "event_type": { "type": "keyword" },
        "payload": { "type": "text" },
        "user_id": { "type": "keyword" },
        "duration_ms": { "type": "integer" }
      }
    }
  }
}'
# Respuesta esperada: {"acknowledged":true}

echo ""
echo "=== 2. Crear índice inicial con alias de escritura ==="
# Convención: el índice inicial termina en -000001
curl -sk -X PUT "$BASE_URL/events-000001" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "aliases": {
    "events-write": {
      "is_write_index": true
    },
    "events-read": {}
  }
}'
# Respuesta esperada: {"acknowledged":true,...}
# events-write → apunta a events-000001 (escritura)
# events-read  → apunta a events-000001 (lectura, crecerá con cada rollover)

echo ""
echo "=== 3. Indexar documentos usando el alias de escritura ==="
for i in $(seq 1 5); do
  curl -sk -X POST "$BASE_URL/events-write/_doc" \
    -u "$AUTH" \
    -H "Content-Type: application/json" \
    -d "{
    \"@timestamp\": \"2024-03-15T10:0${i}:00Z\",
    \"event_type\": \"page_view\",
    \"payload\": \"Usuario visitó la página ${i}\",
    \"user_id\": \"user-${i}\",
    \"duration_ms\": $((RANDOM % 5000))
  }"
  echo ""
done
# Todos los documentos van a events-000001 (el write index actual)

echo ""
echo "=== 4. Rollover manual por condición ==="
# Rollover cuando el índice tenga >= 3 documentos O >= 1 día de antigüedad
curl -sk -X POST "$BASE_URL/events-write/_rollover" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "conditions": {
    "max_docs": 3,
    "max_age": "1d",
    "max_size": "5gb"
  }
}'
# Respuesta esperada: {"acknowledged":true,"old_index":"events-000001",
#   "new_index":"events-000002","rolled_over":true,"condition":{...}}
# Si ninguna condición se cumple: "rolled_over":false

echo ""
echo "=== 5. Verificar el estado post-rollover ==="
curl -sk "$BASE_URL/_cat/indices/events-*?v&s=index" -u "$AUTH"
# Debería mostrar events-000001 y events-000002

echo ""
curl -sk "$BASE_URL/_cat/aliases/events-*?v" -u "$AUTH"
# events-write ahora apunta a events-000002 (nuevo write index)
# events-read apunta a AMBOS índices (búsquedas ven todo)

echo ""
echo "=== 6. Escribir después del rollover ==="
curl -sk -X POST "$BASE_URL/events-write/_doc" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "@timestamp": "2024-03-16T08:00:00Z",
  "event_type": "login",
  "payload": "Documento post-rollover",
  "user_id": "user-99",
  "duration_ms": 150
}'
# Respuesta esperada: {"_index":"events-000002",...}
# Confirma que la escritura va al nuevo índice

echo ""
echo "=== 7. Buscar a través del alias de lectura ==="
curl -sk "$BASE_URL/events-read/_search?pretty" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} }, "sort": [{ "@timestamp": "desc" }] }'
# Devuelve documentos de AMBOS índices — transparente para la aplicación

echo ""
echo "=== 8. Crear ISM policy con rollover automático ==="
# En producción, el rollover lo maneja ISM — no se ejecuta manualmente
curl -sk -X PUT "$BASE_URL/_plugins/_ism/policies/events-rollover" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "description": "Rollover automático + retención para events",
    "default_state": "hot",
    "ism_template": [
      {
        "index_patterns": ["events-*"],
        "priority": 100
      }
    ],
    "states": [
      {
        "name": "hot",
        "actions": [
          {
            "rollover": {
              "min_size": "10gb",
              "min_doc_count": 1000000,
              "min_index_age": "1d"
            }
          }
        ],
        "transitions": [
          {
            "state_name": "warm",
            "conditions": { "min_index_age": "7d" }
          }
        ]
      },
      {
        "name": "warm",
        "actions": [
          { "force_merge": { "max_num_segments": 1 } },
          { "replica_count": { "number_of_replicas": 0 } }
        ],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": { "min_index_age": "30d" }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [ { "delete": {} } ],
        "transitions": []
      }
    ]
  }
}'
# Respuesta esperada: {"_id":"events-rollover",...}
# ISM evalúa condiciones cada 5 minutos (configurable con plugins.index_state_management.job_interval)

echo ""
echo "=== 9. Verificar que ISM se asoció al índice ==="
curl -sk "$BASE_URL/_plugins/_ism/explain/events-*" \
  -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_plugins/_ism/explain/events-*" -u "$AUTH"

echo ""
echo "Done. Rollover manual y automático configurados."
