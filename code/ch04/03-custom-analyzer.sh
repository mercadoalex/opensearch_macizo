#!/usr/bin/env bash
# 03-custom-analyzer.sh — Crea un índice con un analizador personalizado.
#
# Uso: bash code/ch04/03-custom-analyzer.sh
#
# Define un analizador custom que combina:
# - char_filter: html_strip (elimina tags HTML)
# - tokenizer: standard
# - filter: lowercase, asciifolding, spanish_stop, spanish_stemmer
#
# Respuesta esperada al analizar "Los <b>Servidores</b> están funcionando":
# Tokens: ["servidor", "funcionar"]

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Eliminando índice 'blog' si existe..."
curl -sk -X DELETE "${OPENSEARCH_URL}/blog" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" > /dev/null 2>&1 || true

echo "==> Creando índice 'blog' con analizador personalizado..."

curl -sk -X PUT "${OPENSEARCH_URL}/blog" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "analysis": {
      "char_filter": {
        "html_cleaner": {
          "type": "html_strip",
          "escaped_tags": ["code"]
        }
      },
      "filter": {
        "spanish_stop": {
          "type": "stop",
          "stopwords": "_spanish_"
        },
        "spanish_stemmer": {
          "type": "stemmer",
          "language": "spanish"
        }
      },
      "analyzer": {
        "blog_spanish": {
          "type": "custom",
          "char_filter": ["html_cleaner"],
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "asciifolding",
            "spanish_stop",
            "spanish_stemmer"
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "titulo": {
        "type": "text",
        "analyzer": "blog_spanish",
        "fields": {
          "keyword": { "type": "keyword" }
        }
      },
      "contenido": {
        "type": "text",
        "analyzer": "blog_spanish"
      },
      "autor": {
        "type": "keyword"
      },
      "fecha_publicacion": {
        "type": "date"
      },
      "publicado": {
        "type": "boolean"
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "==> Probando el analizador custom con texto HTML:"
echo '    Texto: "Los <b>Servidores</b> están funcionando"'
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/blog/_analyze" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "analyzer": "blog_spanish",
  "text": "Los <b>Servidores</b> están funcionando"
}' | python3 -m json.tool

echo ""
echo "==> Probando con contenido que incluye <code> (tag preservado):"
echo '    Texto: "Usa <code>curl -sk</code> para consultar el <em>clúster</em>"'
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/blog/_analyze" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "analyzer": "blog_spanish",
  "text": "Usa <code>curl -sk</code> para consultar el <em>clúster</em>"
}' | python3 -m json.tool
