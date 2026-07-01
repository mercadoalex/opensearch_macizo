#!/bin/bash
# Capítulo 7: Cargar datos de ventas e-commerce para ejercicios de agregaciones
# Prerequisito: Clúster OpenSearch corriendo en localhost:9200

set -e

echo "=== Creando índice 'ventas' con mapping explícito ==="
curl -sk -X PUT "https://localhost:9200/ventas" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "producto": { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
      "categoria": { "type": "keyword" },
      "precio": { "type": "float" },
      "cantidad": { "type": "integer" },
      "vendedor": { "type": "keyword" },
      "region": { "type": "keyword" },
      "metodo_pago": { "type": "keyword" },
      "fecha_venta": { "type": "date" }
    }
  }
}'

echo ""
echo ""
echo "=== Cargando 20 documentos de ventas via Bulk API ==="
curl -sk -X POST "https://localhost:9200/_bulk" \
  -u admin:Admin123! \
  -H "Content-Type: application/x-ndjson" \
  --data-binary "@$(dirname "$0")/sample-data.json"

echo ""
echo ""
echo "=== Refrescando índice ==="
curl -sk -X POST "https://localhost:9200/ventas/_refresh" \
  -u admin:Admin123!

echo ""
echo ""
echo "=== Verificando conteo de documentos ==="
curl -sk "https://localhost:9200/ventas/_count" \
  -u admin:Admin123!

echo ""
echo ""
echo "Datos cargados exitosamente. Listo para ejecutar agregaciones."
