#!/usr/bin/env bash
# 04-dynamic-mapping.sh — Demuestra el comportamiento del mapping dinámico.
#
# Uso: bash code/ch04/04-dynamic-mapping.sh
#
# Indexa documentos sin mapping previo y muestra cómo OpenSearch
# infiere los tipos automáticamente. Luego muestra los problemas
# que esto puede causar.
#
# Respuesta esperada: mapping generado dinámicamente con tipos inferidos.

set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-https://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-Admin123!}"

echo "==> Eliminando índice 'ventas-demo' si existe..."
curl -sk -X DELETE "${OPENSEARCH_URL}/ventas-demo" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" > /dev/null 2>&1 || true

echo "==> Indexando documento SIN mapping previo (mapping dinámico)..."
echo ""

curl -sk -X POST "${OPENSEARCH_URL}/ventas-demo/_doc/1" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "producto": "Laptop Gamer X",
  "precio": 1299.99,
  "cantidad": 5,
  "en_oferta": true,
  "fecha_venta": "2024-03-15",
  "codigo_postal": "28001",
  "nota_interna": "Cliente VIP - envío prioritario"
}' | python3 -m json.tool

echo ""
echo "==> Mapping generado dinámicamente por OpenSearch:"
echo ""

curl -sk "${OPENSEARCH_URL}/ventas-demo/_mapping" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

echo ""
echo "=========================================="
echo "==> PROBLEMA: El mapping dinámico infirió 'codigo_postal' como text+keyword."
echo "    Pero un código postal NO debería ser analizado como texto."
echo "    Esto desperdicía espacio y puede dar resultados inesperados en búsquedas."
echo "=========================================="
echo ""

echo "==> Indexando segundo documento con un campo nuevo..."

curl -sk -X POST "${OPENSEARCH_URL}/ventas-demo/_doc/2" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
  "producto": "Mouse Inalámbrico",
  "precio": 29.99,
  "cantidad": 150,
  "en_oferta": false,
  "fecha_venta": "2024-03-16",
  "codigo_postal": "08001",
  "nota_interna": "Stock alto",
  "descuento_porcentaje": "15"
}' | python3 -m json.tool

echo ""
echo "=========================================="
echo "==> PROBLEMA: 'descuento_porcentaje' se envió como string \"15\"."
echo "    OpenSearch lo mapeó como text+keyword en vez de integer o float."
echo "    No podrás hacer range queries ni agregaciones numéricas sobre este campo."
echo "=========================================="
echo ""

echo "==> Mapping final con los problemas acumulados:"
echo ""
curl -sk "${OPENSEARCH_URL}/ventas-demo/_mapping" \
  -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" | python3 -m json.tool

echo ""
echo "==> CONCLUSIÓN: El mapping dinámico es útil para exploración,"
echo "    pero en producción SIEMPRE define mappings explícitos."
echo "    Una vez creado, un campo NO puede cambiar de tipo sin reindexar."
