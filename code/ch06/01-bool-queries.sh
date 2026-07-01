#!/usr/bin/env bash
# 01-bool-queries.sh — Ejemplos de bool queries con must, should, must_not y filter.
#
# Uso: bash code/ch06/01-bool-queries.sh
#
# Prerequisitos:
#   - Laboratorio levantado (perfil novato o intermedio)
#   - Datos cargados con: bash code/ch06/load-data.sh

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "============================================"
echo "  BOOL QUERIES — Capítulo 6"
echo "============================================"

echo ""
echo "--- Ejemplo 1: must + filter ---"
echo "Buscar artículos sobre 'búsqueda' en categoría 'avanzado'"
echo ""

# Respuesta esperada: artículos 2 y 3 (búsqueda/optimización en categoría avanzado)
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "match": { "contenido": "búsqueda" } }
      ],
      "filter": [
        { "term": { "categoria": "avanzado" } }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 2: must + must_not ---"
echo "Artículos de María García que NO sean de seguridad"
echo ""

# Respuesta esperada: artículo 1 (tutorial de María, excluyendo el de seguridad)
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "term": { "autor": "María García" } }
      ],
      "must_not": [
        { "term": { "categoria": "seguridad" } }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 3: should con minimum_should_match ---"
echo "Artículos que contengan 'OpenSearch' O 'búsqueda' O 'vectores' (al menos 2 de 3)"
echo ""

# Respuesta esperada: artículos que coincidan con al menos 2 de las 3 condiciones
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "should": [
        { "match": { "contenido": "OpenSearch" } },
        { "match": { "contenido": "búsqueda" } },
        { "match": { "contenido": "vectores" } }
      ],
      "minimum_should_match": 2
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 4: Bool compuesto con boost ---"
echo "Productos disponibles con precio < 500, priorizando alta valoración"
echo ""

# Respuesta esperada: productos económicos disponibles, ordenados por relevancia + boost
curl -sk -X POST "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "match": { "descripcion": "laptop teclado mouse" } }
      ],
      "filter": [
        { "term": { "disponible": true } },
        { "range": { "precio": { "lte": 500 } } }
      ],
      "should": [
        { "range": { "valoracion_promedio": { "gte": 4.5, "boost": 2.0 } } }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 5: Bool anidado (bool dentro de bool) ---"
echo "Artículos avanzados publicados en 2024 Q1, con alta valoración o muchas visitas"
echo ""

# Respuesta esperada: artículos avanzados de Q1 2024 con valoración >= 4.5 o visitas >= 3000
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "term": { "categoria": "avanzado" } }
      ],
      "filter": [
        {
          "range": {
            "fecha_publicacion": {
              "gte": "2024-01-01",
              "lte": "2024-03-31"
            }
          }
        }
      ],
      "should": [
        { "range": { "valoracion": { "gte": 4.5 } } },
        { "range": { "visitas": { "gte": 3000 } } }
      ],
      "minimum_should_match": 1
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Fin de ejemplos de bool queries."
