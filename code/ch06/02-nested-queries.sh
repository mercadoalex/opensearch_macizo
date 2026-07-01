#!/usr/bin/env bash
# 02-nested-queries.sh — Ejemplos de nested queries para objetos anidados.
#
# Uso: bash code/ch06/02-nested-queries.sh
#
# Prerequisitos:
#   - Laboratorio levantado (perfil novato o intermedio)
#   - Datos cargados con: bash code/ch06/load-data.sh
#   - El índice 'articulos' tiene campo 'comentarios' como tipo nested

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "============================================"
echo "  NESTED QUERIES — Capítulo 6"
echo "============================================"

echo ""
echo "--- Ejemplo 1: Nested query básica ---"
echo "Artículos donde 'pedro' dejó un comentario"
echo ""

# Respuesta esperada: artículos 1, 5 (pedro comentó en ambos)
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "nested": {
      "path": "comentarios",
      "query": {
        "term": { "comentarios.usuario": "pedro" }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 2: Nested con múltiples condiciones ---"
echo "Artículos con comentarios de 'ana' que mencionen 'genial' o 'claro'"
echo ""

# Respuesta esperada: artículos donde ana comentó algo positivo
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "nested": {
      "path": "comentarios",
      "query": {
        "bool": {
          "must": [
            { "term": { "comentarios.usuario": "ana" } },
            { "match": { "comentarios.texto": "genial claro" } }
          ]
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 3: Nested con inner_hits ---"
echo "Ver qué comentarios específicos coincidieron"
echo ""

# Respuesta esperada: artículos con los comentarios que coincidieron resaltados en inner_hits
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "nested": {
      "path": "comentarios",
      "query": {
        "match": { "comentarios.texto": "producción" }
      },
      "inner_hits": {
        "highlight": {
          "fields": {
            "comentarios.texto": {}
          }
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 4: Nested con filtro por fecha ---"
echo "Artículos con comentarios realizados después del 1 de marzo 2024"
echo ""

# Respuesta esperada: artículos con comentarios de marzo 2024 en adelante
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "nested": {
      "path": "comentarios",
      "query": {
        "range": {
          "comentarios.fecha": {
            "gte": "2024-03-01"
          }
        }
      },
      "inner_hits": {}
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 5: Combinando nested con bool query ---"
echo "Artículos de categoría 'avanzado' que tengan al menos un comentario de 'carlos'"
echo ""

# Respuesta esperada: artículos avanzados donde carlos participó en los comentarios
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
          "nested": {
            "path": "comentarios",
            "query": {
              "term": { "comentarios.usuario": "carlos" }
            }
          }
        }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Fin de ejemplos de nested queries."
