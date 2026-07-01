#!/usr/bin/env bash
# 01-create-knn-index.sh — Crear índice con k-NN habilitado e indexar vectores de ejemplo.
set -euo pipefail
URL="${OPENSEARCH_URL:-https://localhost:9200}"
AUTH="${OPENSEARCH_USER:-admin}:${OPENSEARCH_PASS:-Admin123!}"

echo "==> Creando índice k-NN 'demo-vectors'..."
curl -sk -X DELETE "$URL/demo-vectors" -u "$AUTH" > /dev/null 2>&1 || true
curl -sk -X PUT "$URL/demo-vectors" -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {"index.knn": true, "number_of_shards": 1, "number_of_replicas": 0},
  "mappings": {
    "properties": {
      "title": {"type": "text", "analyzer": "spanish"},
      "category": {"type": "keyword"},
      "embedding": {
        "type": "knn_vector",
        "dimension": 3,
        "method": {"name": "hnsw", "space_type": "cosinesimil", "engine": "lucene"}
      }
    }
  }
}'
echo ""

echo "==> Indexando documentos con vectores..."
for i in 1 2 3 4 5; do
  case $i in
    1) TITLE="Seguridad en APIs REST"; VEC="[0.1, 0.1, 0.9]"; CAT="seguridad" ;;
    2) TITLE="Cifrado TLS para microservicios"; VEC="[0.15, 0.1, 0.85]"; CAT="seguridad" ;;
    3) TITLE="Despliegue con Kubernetes"; VEC="[0.1, 0.9, 0.1]"; CAT="infraestructura" ;;
    4) TITLE="Docker Compose en producción"; VEC="[0.1, 0.85, 0.15]"; CAT="infraestructura" ;;
    5) TITLE="Python para data science"; VEC="[0.9, 0.1, 0.1]"; CAT="programacion" ;;
  esac
  curl -sk -X POST "$URL/demo-vectors/_doc/$i" -u "$AUTH" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$TITLE\",\"category\":\"$CAT\",\"embedding\":$VEC}" > /dev/null
done
echo "  5 documentos indexados."
