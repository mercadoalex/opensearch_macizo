#!/usr/bin/env bash
# load-data.sh — Carga los datos de ejemplo para el Capítulo 6 (Query DSL Avanzado).
#
# Uso: bash code/ch06/load-data.sh
#
# Crea los índices 'articulos' y 'productos' con mappings adecuados
# y carga los documentos desde sample-data.json.
#
# Respuesta esperada:
# {
#     "took": ...,
#     "errors": false,
#     "items": [ ... ]
# }

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Eliminando índices previos (si existen)..."
curl -sk -X DELETE "${OPENSEARCH_URL}/articulos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" 2>/dev/null || true
curl -sk -X DELETE "${OPENSEARCH_URL}/productos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" 2>/dev/null || true

echo ""
echo "==> Creando índice 'articulos' con mapping para nested comments..."

curl -sk -X PUT "${OPENSEARCH_URL}/articulos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "titulo": { "type": "text", "analyzer": "spanish" },
      "autor": { "type": "keyword" },
      "categoria": { "type": "keyword" },
      "tags": { "type": "keyword" },
      "fecha_publicacion": { "type": "date", "format": "yyyy-MM-dd" },
      "visitas": { "type": "integer" },
      "valoracion": { "type": "float" },
      "contenido": { "type": "text", "analyzer": "spanish" },
      "comentarios": {
        "type": "nested",
        "properties": {
          "usuario": { "type": "keyword" },
          "texto": { "type": "text", "analyzer": "spanish" },
          "fecha": { "type": "date", "format": "yyyy-MM-dd" }
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Creando índice 'productos' con mapping..."

curl -sk -X PUT "${OPENSEARCH_URL}/productos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "nombre": {
        "type": "text",
        "analyzer": "spanish",
        "fields": { "keyword": { "type": "keyword" } }
      },
      "marca": { "type": "keyword" },
      "categoria": { "type": "keyword" },
      "subcategoria": { "type": "keyword" },
      "precio": { "type": "float" },
      "stock": { "type": "integer" },
      "disponible": { "type": "boolean" },
      "descripcion": { "type": "text", "analyzer": "spanish" },
      "specs": {
        "type": "object",
        "properties": {
          "ram_gb": { "type": "integer" },
          "storage_gb": { "type": "integer" },
          "pantalla": { "type": "keyword" }
        }
      },
      "fecha_ingreso": { "type": "date", "format": "yyyy-MM-dd" },
      "valoracion_promedio": { "type": "float" }
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Cargando documentos desde sample-data.json..."

curl -sk -X POST "${OPENSEARCH_URL}/_bulk" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary "@${SCRIPT_DIR}/sample-data.json" | python3 -m json.tool

echo ""
echo "==> Verificando documentos cargados..."

curl -sk "${OPENSEARCH_URL}/articulos/_count" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

curl -sk "${OPENSEARCH_URL}/productos/_count" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

echo ""
echo "==> Datos listos. Índices: articulos (8 docs), productos (7 docs)"
