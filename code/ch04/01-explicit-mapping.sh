#!/usr/bin/env bash
# 01-explicit-mapping.sh — Crea un índice con mapping explícito.
#
# Uso: bash code/ch04/01-explicit-mapping.sh
#
# Este script crea un índice "productos" con tipos de datos definidos
# explícitamente: text, keyword, integer, float, boolean, date.
#
# Respuesta esperada:
# {
#     "acknowledged": true,
#     "shards_acknowledged": true,
#     "index": "productos"
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Eliminando índice 'productos' si existe..."
curl -sk -X DELETE "${OPENSEARCH_URL}/productos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" > /dev/null 2>&1 || true

echo "==> Creando índice 'productos' con mapping explícito..."

curl -sk -X PUT "${OPENSEARCH_URL}/productos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "nombre": {
        "type": "text",
        "analyzer": "spanish",
        "fields": {
          "keyword": {
            "type": "keyword",
            "ignore_above": 256
          }
        }
      },
      "categoria": {
        "type": "keyword"
      },
      "descripcion": {
        "type": "text",
        "analyzer": "spanish"
      },
      "precio": {
        "type": "float"
      },
      "cantidad_stock": {
        "type": "integer"
      },
      "disponible": {
        "type": "boolean"
      },
      "fecha_creacion": {
        "type": "date",
        "format": "yyyy-MM-dd||yyyy-MM-dd HH:mm:ss||epoch_millis"
      },
      "tags": {
        "type": "keyword"
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Verificando mapping del índice..."
curl -sk "${OPENSEARCH_URL}/productos/_mapping" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool
