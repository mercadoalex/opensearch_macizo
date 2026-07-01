#!/bin/bash
# Capítulo 7: Agregaciones de métricas
# Prerequisito: Ejecutar load-data.sh primero
# Casos: avg, sum, min, max, cardinality

set -e

echo "=== 1. Precio promedio de todas las ventas (avg) ==="
# Caso de uso: KPI de ticket promedio para dashboards de negocio
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "precio_promedio": {
      "avg": { "field": "precio" }
    }
  }
}'
# Respuesta esperada: "precio_promedio": { "value": ~380 }

echo ""
echo ""

echo "=== 2. Ingresos totales (sum de precio * cantidad) ==="
# Caso de uso: Calcular revenue total del período usando script
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ingresos_totales": {
      "sum": {
        "script": {
          "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
        }
      }
    }
  }
}'
# Respuesta esperada: "ingresos_totales": { "value": suma de precio*cantidad }

echo ""
echo ""

echo "=== 3. Producto más barato y más caro (min, max) ==="
# Caso de uso: Rango de precios para filtros de UI en e-commerce
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "precio_minimo": {
      "min": { "field": "precio" }
    },
    "precio_maximo": {
      "max": { "field": "precio" }
    }
  }
}'
# Respuesta esperada: "precio_minimo": { "value": 39.99 }, "precio_maximo": { "value": 1599.99 }

echo ""
echo ""

echo "=== 4. Número de categorías únicas (cardinality) ==="
# Caso de uso: Contar dimensiones únicas para reportes (vendedores activos, regiones, etc.)
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "categorias_unicas": {
      "cardinality": { "field": "categoria" }
    }
  }
}'
# Respuesta esperada: "categorias_unicas": { "value": 5 }

echo ""
echo ""

echo "=== 5. Estadísticas básicas combinadas (stats) ==="
# Caso de uso: Resumen estadístico completo del precio para dashboards ejecutivos
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "resumen_precio": {
      "stats": { "field": "precio" }
    }
  }
}'
# Respuesta esperada: count, min, max, avg, sum en un solo resultado

echo ""
echo ""

echo "=== 6. Estadísticas extendidas del precio (extended_stats) ==="
# Caso de uso: Análisis estadístico completo para detectar outliers
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "stats_precio": {
      "extended_stats": { "field": "precio" }
    }
  }
}'
# Respuesta esperada: incluye count, min, max, avg, sum, std_deviation, variance

echo ""
echo ""
echo "=== Agregaciones de métricas completadas ==="
