#!/bin/bash
# Capítulo 7: Agregaciones de buckets
# Prerequisito: Ejecutar load-data.sh primero
# Casos: terms, histogram, date_histogram, range

set -e

echo "=== 1. Ventas por categoría (terms) ==="
# Caso de uso: Top categorías por volumen de ventas para priorización de inventario
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "por_categoria": {
      "terms": {
        "field": "categoria",
        "size": 10,
        "order": { "_count": "desc" }
      }
    }
  }
}'
# Respuesta esperada: buckets con perifericos (7), laptops (4), monitores (3), etc.

echo ""
echo ""

echo "=== 2. Ventas por categoría con ingreso promedio (terms + sub-agg) ==="
# Caso de uso: Comparar ticket promedio entre categorías
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "por_categoria": {
      "terms": { "field": "categoria", "size": 10 },
      "aggs": {
        "precio_promedio": {
          "avg": { "field": "precio" }
        },
        "ingreso_total": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        }
      }
    }
  }
}'
# Respuesta esperada: cada bucket incluye precio_promedio y ingreso_total

echo ""
echo ""

echo "=== 3. Distribución de precios (histogram) ==="
# Caso de uso: Segmentación de productos por rango de precios para estrategia comercial
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "distribucion_precios": {
      "histogram": {
        "field": "precio",
        "interval": 200,
        "min_doc_count": 1
      }
    }
  }
}'
# Respuesta esperada: buckets [0-200, 200-400, 400-600, 600-800, ...] con doc_count

echo ""
echo ""

echo "=== 4. Ventas por mes (date_histogram) ==="
# Caso de uso: Tendencia mensual de ventas para planificación de campañas
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ventas_mensuales": {
      "date_histogram": {
        "field": "fecha_venta",
        "calendar_interval": "month",
        "format": "yyyy-MM"
      },
      "aggs": {
        "ingresos": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        }
      }
    }
  }
}'
# Respuesta esperada: buckets 2024-01 y 2024-02 con doc_count e ingresos

echo ""
echo ""

echo "=== 5. Ventas por semana (date_histogram con fixed_interval) ==="
# Caso de uso: Granularidad semanal para detectar patrones de compra
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ventas_semanales": {
      "date_histogram": {
        "field": "fecha_venta",
        "fixed_interval": "7d",
        "format": "yyyy-MM-dd"
      }
    }
  }
}'
# Respuesta esperada: buckets semanales con doc_count

echo ""
echo ""

echo "=== 6. Segmentación por rango de precio (range) ==="
# Caso de uso: Clasificar productos en económico/medio/premium para análisis de márgenes
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "segmento_precio": {
      "range": {
        "field": "precio",
        "ranges": [
          { "key": "economico", "to": 100 },
          { "key": "medio", "from": 100, "to": 500 },
          { "key": "premium", "from": 500 }
        ]
      },
      "aggs": {
        "cantidad_total": {
          "sum": { "field": "cantidad" }
        }
      }
    }
  }
}'
# Respuesta esperada: 3 buckets (economico, medio, premium) con doc_count y cantidad_total

echo ""
echo ""

echo "=== 7. Segmentos de negocio con criterios distintos (filters) ==="
# Caso de uso: Comparar métricas entre segmentos definidos por condiciones heterogéneas
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "segmentos_negocio": {
      "filters": {
        "filters": {
          "ventas_grandes": { "range": { "precio": { "gte": 500 } } },
          "ventas_recurrentes": { "range": { "cantidad": { "gte": 3 } } },
          "region_cdmx": { "term": { "region": "CDMX" } }
        }
      },
      "aggs": {
        "ingresos": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        }
      }
    }
  }
}'
# Respuesta esperada: 3 buckets con criterios distintos, cada uno con doc_count e ingresos

echo ""
echo ""
echo "=== Agregaciones de buckets completadas ==="
