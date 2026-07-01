#!/usr/bin/env bash
# 03-multi-match.sh — Ejemplos de multi_match queries para búsqueda en múltiples campos.
#
# Uso: bash code/ch06/03-multi-match.sh
#
# Prerequisitos:
#   - Laboratorio levantado (perfil novato o intermedio)
#   - Datos cargados con: bash code/ch06/load-data.sh

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "============================================"
echo "  MULTI-MATCH QUERIES — Capítulo 6"
echo "============================================"

echo ""
echo "--- Ejemplo 1: multi_match básico (best_fields) ---"
echo "Buscar 'OpenSearch búsqueda' en título y contenido"
echo ""

# Respuesta esperada: artículos que mencionan OpenSearch o búsqueda en título o contenido
# best_fields: usa el score del campo que mejor coincide
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "OpenSearch búsqueda",
      "fields": ["titulo", "contenido"],
      "type": "best_fields"
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 2: multi_match con boost por campo ---"
echo "Buscar 'optimización rendimiento' priorizando el título (x3)"
echo ""

# Respuesta esperada: prioriza coincidencias en título sobre contenido
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "optimización rendimiento",
      "fields": ["titulo^3", "contenido"],
      "type": "best_fields"
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 3: multi_match con cross_fields ---"
echo "Buscar 'laptop profesional' combinando nombre y descripción"
echo ""

# cross_fields: trata múltiples campos como si fueran uno solo
# Útil cuando la información está repartida entre campos
curl -sk -X POST "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "laptop profesional",
      "fields": ["nombre", "descripcion"],
      "type": "cross_fields",
      "operator": "and"
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 4: multi_match con phrase_prefix ---"
echo "Autocompletado: buscar artículos que empiecen con 'búsqueda sem'"
echo ""

# phrase_prefix: ideal para search-as-you-type
# Coincide con el prefix del último término
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "búsqueda sem",
      "fields": ["titulo^2", "contenido"],
      "type": "phrase_prefix"
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 5: multi_match con most_fields ---"
echo "Buscar 'monitor productividad' en nombre y descripción (suma de scores)"
echo ""

# most_fields: suma los scores de todos los campos que coinciden
# Útil cuando un documento es más relevante si coincide en múltiples campos
curl -sk -X POST "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "monitor productividad",
      "fields": ["nombre^2", "descripcion", "categoria"],
      "type": "most_fields",
      "fuzziness": "AUTO"
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 6: multi_match con tie_breaker ---"
echo "Equilibrar scores entre campos con tie_breaker"
echo ""

# tie_breaker: controla cuánto contribuyen los campos secundarios
# 0.0 = solo mejor campo, 1.0 = suma todos (como most_fields)
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "seguridad permisos autenticación",
      "fields": ["titulo^3", "contenido", "tags^2"],
      "type": "best_fields",
      "tie_breaker": 0.3
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Fin de ejemplos de multi-match queries."
