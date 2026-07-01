#!/bin/bash
# Capítulo 8: Index State Management (ISM) Policies
# Prerequisito: Clúster OpenSearch corriendo (perfil novato o superior)

BASE_URL="https://localhost:9200"
AUTH="admin:Admin123!"

echo "=== 1. Crear ISM Policy: logs-lifecycle ==="
# Política de ciclo de vida: hot → warm → delete
curl -sk -X PUT "$BASE_URL/_plugins/_ism/policies/logs-lifecycle" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "description": "Ciclo de vida para logs: hot (escritura) → warm (solo lectura) → delete",
    "default_state": "hot",
    "ism_template": [
      {
        "index_patterns": ["logs-*"],
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
              "min_doc_count": 5000000,
              "min_index_age": "1d"
            }
          }
        ],
        "transitions": [
          {
            "state_name": "warm",
            "conditions": {
              "min_index_age": "2d"
            }
          }
        ]
      },
      {
        "name": "warm",
        "actions": [
          {
            "replica_count": {
              "number_of_replicas": 0
            }
          },
          {
            "force_merge": {
              "max_num_segments": 1
            }
          }
        ],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": {
              "min_index_age": "30d"
            }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [
          {
            "delete": {}
          }
        ],
        "transitions": []
      }
    ]
  }
}'
# Respuesta esperada: {"_id":"logs-lifecycle","_version":1,...,"policy":{...}}

echo ""
echo "=== 2. Verificar la policy creada ==="
curl -sk "$BASE_URL/_plugins/_ism/policies/logs-lifecycle" \
  -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_plugins/_ism/policies/logs-lifecycle" -u "$AUTH"

echo ""
echo "=== 3. Crear un índice que aplique la policy via ism_template ==="
# El campo ism_template en la policy asocia automáticamente índices que matcheen logs-*
curl -sk -X PUT "$BASE_URL/logs-ism-demo-000001" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "aliases": {
    "logs-ism-demo": {
      "is_write_index": true
    }
  }
}'
# Respuesta esperada: {"acknowledged":true,...}

echo ""
echo "=== 4. Aplicar policy manualmente a un índice existente ==="
# Útil para índices que ya existían antes de crear la policy
curl -sk -X POST "$BASE_URL/_plugins/_ism/add/logs-ism-demo-000001" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "policy_id": "logs-lifecycle"
}'
# Respuesta esperada: {"updated_indices":1,"failures":false,...}

echo ""
echo "=== 5. Verificar estado ISM del índice ==="
curl -sk "$BASE_URL/_plugins/_ism/explain/logs-ism-demo-000001" \
  -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_plugins/_ism/explain/logs-ism-demo-000001" -u "$AUTH"
# Muestra: state (hot), action (rollover), step, retry info

echo ""
echo "=== 6. Cambiar policy en índices existentes (policy migration) ==="
# Crear una policy v2 con retención más larga
curl -sk -X PUT "$BASE_URL/_plugins/_ism/policies/logs-lifecycle-v2" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "description": "Ciclo de vida v2: retención extendida a 60 días",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [
          {
            "rollover": {
              "min_size": "20gb",
              "min_index_age": "2d"
            }
          }
        ],
        "transitions": [
          {
            "state_name": "warm",
            "conditions": { "min_index_age": "3d" }
          }
        ]
      },
      {
        "name": "warm",
        "actions": [
          { "replica_count": { "number_of_replicas": 0 } },
          { "force_merge": { "max_num_segments": 1 } }
        ],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": { "min_index_age": "60d" }
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

echo ""
# Migrar el índice a la nueva policy
curl -sk -X POST "$BASE_URL/_plugins/_ism/change_policy/logs-ism-demo-000001" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "policy_id": "logs-lifecycle-v2"
}'
# Respuesta esperada: {"updated_indices":1,"failures":false,...}

echo ""
echo "=== 7. Remover policy de un índice ==="
curl -sk -X POST "$BASE_URL/_plugins/_ism/remove/logs-ism-demo-000001" \
  -u "$AUTH"
# Respuesta esperada: {"updated_indices":1,"failures":false,...}

echo ""
echo "=== 8. Listar todas las ISM policies ==="
curl -sk "$BASE_URL/_plugins/_ism/policies" \
  -u "$AUTH" | python3 -m json.tool 2>/dev/null || \
curl -sk "$BASE_URL/_plugins/_ism/policies" -u "$AUTH"

echo ""
echo "Done. ISM policies creadas y demostradas."
