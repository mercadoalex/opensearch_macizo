#!/usr/bin/env bash
# 04-function-score.sh — Ejemplos de function_score para personalizar relevancia.
#
# Uso: bash code/ch06/04-function-score.sh
#
# Prerequisitos:
#   - Laboratorio levantado (perfil novato o intermedio)
#   - Datos cargados con: bash code/ch06/load-data.sh

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "============================================"
echo "  FUNCTION SCORE — Capítulo 6"
echo "============================================"

echo ""
echo "--- Ejemplo 1: field_value_factor ---"
echo "Buscar artículos sobre 'OpenSearch', boosteando por número de visitas"
echo ""

# field_value_factor: multiplica el score por un valor del documento
# modifier: log1p suaviza el efecto de valores muy altos
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": {
        "match": { "contenido": "OpenSearch" }
      },
      "field_value_factor": {
        "field": "visitas",
        "modifier": "log1p",
        "factor": 1.5,
        "missing": 1
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 2: Decay function (gauss) por fecha ---"
echo "Artículos recientes son más relevantes (decay temporal)"
echo ""

# gauss decay: reduce el score a medida que la fecha se aleja del origen
# origin: fecha de referencia, scale: ventana donde el score decae al 50%
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": { "match_all": {} },
      "functions": [
        {
          "gauss": {
            "fecha_publicacion": {
              "origin": "2024-04-15",
              "scale": "30d",
              "offset": "5d",
              "decay": 0.5
            }
          }
        }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 3: Script score ---"
echo "Score personalizado: combinar valoración y visitas con fórmula custom"
echo ""

# script_score: control total sobre el cálculo del score
# Fórmula: (valoración * 10) + log(visitas + 1)
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": { "match_all": {} },
      "script_score": {
        "script": {
          "source": "doc['\''valoracion'\''].value * 10 + Math.log(doc['\''visitas'\''].value + 1)"
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 4: Múltiples funciones con score_mode ---"
echo "Combinar popularidad + recencia + valoración"
echo ""

# Múltiples funciones combinadas con score_mode
# multiply: multiplica todos los scores parciales
# sum: los suma
# avg: promedio
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": {
        "match": { "contenido": "búsqueda datos" }
      },
      "functions": [
        {
          "field_value_factor": {
            "field": "valoracion",
            "modifier": "square",
            "factor": 1.2
          },
          "weight": 2
        },
        {
          "gauss": {
            "fecha_publicacion": {
              "origin": "2024-04-15",
              "scale": "60d"
            }
          },
          "weight": 1.5
        },
        {
          "field_value_factor": {
            "field": "visitas",
            "modifier": "log1p"
          },
          "weight": 1
        }
      ],
      "score_mode": "sum",
      "boost_mode": "multiply",
      "max_boost": 50
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 5: Random score para diversificación ---"
echo "Resultados aleatorios pero deterministas por sesión"
echo ""

# random_score: útil para A/B testing o diversificar resultados
# seed: garantiza misma aleatorización para la misma sesión
curl -sk -X POST "${OPENSEARCH_URL}/articulos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": { "match_all": {} },
      "functions": [
        {
          "random_score": {
            "seed": 12345,
            "field": "_seq_no"
          }
        }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 6: Boost condicional con filter ---"
echo "Boost x3 a productos de la marca TechCorp"
echo ""

# weight + filter: aplica boost solo a documentos que coincidan con el filtro
curl -sk -X POST "${OPENSEARCH_URL}/productos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": {
        "match": { "descripcion": "procesador" }
      },
      "functions": [
        {
          "filter": { "term": { "marca": "TechCorp" } },
          "weight": 3
        },
        {
          "filter": { "range": { "valoracion_promedio": { "gte": 4.5 } } },
          "weight": 2
        }
      ],
      "score_mode": "multiply",
      "boost_mode": "multiply"
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Fin de ejemplos de function_score."
