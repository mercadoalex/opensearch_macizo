#!/usr/bin/env bash
# 05-semantic-search.sh — Ejemplos de búsqueda semántica con k-NN y neural search.
#
# Uso: bash code/ch06/05-semantic-search.sh
#
# Prerequisitos:
#   - Laboratorio levantado (perfil novato o intermedio)
#   - Datos cargados con: bash code/ch06/load-data.sh
#
# NOTA: La búsqueda semántica real requiere un modelo ML registrado.
# Estos ejemplos demuestran la estructura de las queries.
# Para un pipeline completo con modelos, ver Capítulo 16.

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "============================================"
echo "  BÚSQUEDA SEMÁNTICA — Capítulo 6"
echo "============================================"

echo ""
echo "--- Paso 1: Crear índice con campo k-NN ---"
echo "Índice con vector de 3 dimensiones (simplificado para demostración)"
echo ""

# En producción usarías 384-768 dimensiones según el modelo de embedding
# Aquí usamos 3D para que los ejemplos sean legibles
curl -sk -X DELETE "${OPENSEARCH_URL}/documentos-semanticos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" 2>/dev/null || true

curl -sk -X PUT "${OPENSEARCH_URL}/documentos-semanticos" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "index": {
      "knn": true
    }
  },
  "mappings": {
    "properties": {
      "titulo": { "type": "text", "analyzer": "spanish" },
      "contenido": { "type": "text", "analyzer": "spanish" },
      "categoria": { "type": "keyword" },
      "embedding": {
        "type": "knn_vector",
        "dimension": 3,
        "method": {
          "name": "hnsw",
          "space_type": "cosinesimil",
          "engine": "lucene",
          "parameters": {
            "ef_construction": 128,
            "m": 16
          }
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Paso 2: Indexar documentos con embeddings ---"
echo "Vectores simulados que representan significado semántico"
echo ""

# Vectores simulados:
# [1, 0, 0] ≈ programación/código
# [0, 1, 0] ≈ infraestructura/operaciones
# [0, 0, 1] ≈ seguridad
# Combinaciones representan temas mixtos
curl -sk -X POST "${OPENSEARCH_URL}/_bulk" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/x-ndjson" \
  -d '{"index":{"_index":"documentos-semanticos","_id":"1"}}
{"titulo":"Guía de desarrollo con APIs REST","contenido":"Cómo diseñar e implementar APIs robustas con patrones de diseño modernos","categoria":"desarrollo","embedding":[0.95, 0.1, 0.05]}
{"index":{"_index":"documentos-semanticos","_id":"2"}}
{"titulo":"Kubernetes en producción","contenido":"Despliegue y gestión de contenedores en entornos productivos a gran escala","categoria":"infraestructura","embedding":[0.2, 0.9, 0.1]}
{"index":{"_index":"documentos-semanticos","_id":"3"}}
{"titulo":"Autenticación OAuth2 segura","contenido":"Implementación de flujos OAuth2 con mejores prácticas de seguridad","categoria":"seguridad","embedding":[0.4, 0.1, 0.85]}
{"index":{"_index":"documentos-semanticos","_id":"4"}}
{"titulo":"CI/CD pipelines automatizados","contenido":"Automatización de build test y deploy con herramientas modernas","categoria":"infraestructura","embedding":[0.5, 0.8, 0.15]}
{"index":{"_index":"documentos-semanticos","_id":"5"}}
{"titulo":"Cifrado de datos en tránsito","contenido":"TLS mTLS y cifrado end-to-end para proteger comunicaciones","categoria":"seguridad","embedding":[0.1, 0.3, 0.92]}
' | python3 -m json.tool

echo ""
echo "--- Ejemplo 1: k-NN query básica ---"
echo "Buscar documentos semánticamente similares a 'programación' [0.9, 0.1, 0.1]"
echo ""

# k-NN busca los k vectores más cercanos al query vector
# Resultado esperado: doc 1 (APIs REST) y doc 4 (CI/CD) son más similares a 'programación'
curl -sk -X POST "${OPENSEARCH_URL}/documentos-semanticos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "size": 3,
  "query": {
    "knn": {
      "embedding": {
        "vector": [0.9, 0.1, 0.1],
        "k": 3
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 2: k-NN con filtro ---"
echo "Documentos de seguridad más similares a 'desarrollo seguro' [0.6, 0.1, 0.7]"
echo ""

# Combinar similitud semántica con filtros estructurados
curl -sk -X POST "${OPENSEARCH_URL}/documentos-semanticos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "size": 3,
  "query": {
    "bool": {
      "must": [
        {
          "knn": {
            "embedding": {
              "vector": [0.6, 0.1, 0.7],
              "k": 3
            }
          }
        }
      ],
      "filter": [
        { "term": { "categoria": "seguridad" } }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 3: Búsqueda híbrida (textual + semántica) ---"
echo "Combinar BM25 (texto) con k-NN (semántica) usando bool query"
echo ""

# Búsqueda híbrida: lo mejor de ambos mundos
# - should[0]: búsqueda textual tradicional (BM25)
# - should[1]: similitud semántica (k-NN)
# Los scores se suman, dando resultados relevantes por texto Y por significado
curl -sk -X POST "${OPENSEARCH_URL}/documentos-semanticos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "size": 5,
  "query": {
    "bool": {
      "should": [
        {
          "match": {
            "contenido": {
              "query": "seguridad cifrado protección",
              "boost": 0.3
            }
          }
        },
        {
          "knn": {
            "embedding": {
              "vector": [0.2, 0.1, 0.9],
              "k": 5,
              "boost": 0.7
            }
          }
        }
      ]
    }
  }
}' | python3 -m json.tool

echo ""
echo "--- Ejemplo 4: Neural search con pipeline (estructura) ---"
echo "Cómo se vería una query con neural search plugin (requiere modelo registrado)"
echo ""

# NOTA: Esta query requiere un modelo ML registrado en OpenSearch.
# Se muestra la estructura para referencia.
# El Capítulo 16 cubre la configuración completa del pipeline ML.
cat << 'EOF'
# Estructura de neural search (requiere ml-commons plugin + modelo registrado):

POST /mi-indice-neural/_search
{
  "query": {
    "neural": {
      "embedding_field": {
        "query_text": "¿cómo proteger mis APIs en producción?",
        "model_id": "<model-id-registrado>",
        "k": 5
      }
    }
  }
}

# El plugin neural_search:
# 1. Toma el query_text
# 2. Lo envía al modelo registrado para generar el embedding
# 3. Ejecuta una búsqueda k-NN con el vector resultante
# 4. Devuelve los documentos más similares semánticamente
EOF

echo ""
echo "--- Ejemplo 5: Script score con cosine similarity ---"
echo "Calcular similitud coseno manualmente con script_score"
echo ""

# Alternativa a k-NN query: usar script_score para cálculo explícito
# Útil cuando necesitas combinar similitud vectorial con lógica custom
curl -sk -X POST "${OPENSEARCH_URL}/documentos-semanticos/_search" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "size": 3,
  "query": {
    "script_score": {
      "query": { "match_all": {} },
      "script": {
        "source": "cosineSimilarity(params.query_vector, '\''embedding'\'') + 1.0",
        "params": {
          "query_vector": [0.1, 0.85, 0.2]
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Fin de ejemplos de búsqueda semántica."
echo ""
echo "NOTA: Para búsqueda semántica completa con modelos ML,"
echo "consulta el Capítulo 16 (ML y Búsqueda Vectorial)."
