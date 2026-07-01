#!/bin/bash
# Capítulo 7: Agregaciones composite
# Prerequisito: Ejecutar load-data.sh primero
# Caso de uso: Paginación eficiente de grandes conjuntos de buckets

set -e

echo "=== 1. Composite: Ventas por categoría + región (página 1) ==="
# Caso de uso: Generar reporte cruzado categoría×región para BI, paginando resultados
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ventas_cruzadas": {
      "composite": {
        "size": 5,
        "sources": [
          { "categoria": { "terms": { "field": "categoria" } } },
          { "region": { "terms": { "field": "region" } } }
        ]
      },
      "aggs": {
        "ingresos": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        },
        "unidades": {
          "sum": { "field": "cantidad" }
        }
      }
    }
  }
}'
# Respuesta esperada: 5 buckets con after_key para paginación
# Cada bucket tiene composite key {categoria, region}, ingresos y unidades

echo ""
echo ""

echo "=== 2. Composite: Página 2 (usando after_key) ==="
# Caso de uso: Continuar iteración para exportar todos los buckets a CSV/BI
# NOTA: Reemplaza after_key con el valor real de la respuesta anterior
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ventas_cruzadas": {
      "composite": {
        "size": 5,
        "sources": [
          { "categoria": { "terms": { "field": "categoria" } } },
          { "region": { "terms": { "field": "region" } } }
        ],
        "after": { "categoria": "monitores", "region": "CDMX" }
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
# Respuesta esperada: siguientes 5 buckets después de la clave especificada

echo ""
echo ""

echo "=== 3. Composite con date_histogram: Ventas mensuales por vendedor ==="
# Caso de uso: Reporte de desempeño mensual por vendedor para comisiones
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "performance_vendedores": {
      "composite": {
        "size": 10,
        "sources": [
          {
            "mes": {
              "date_histogram": {
                "field": "fecha_venta",
                "calendar_interval": "month",
                "format": "yyyy-MM"
              }
            }
          },
          { "vendedor": { "terms": { "field": "vendedor" } } }
        ]
      },
      "aggs": {
        "total_vendido": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        },
        "num_transacciones": {
          "value_count": { "field": "producto.keyword" }
        }
      }
    }
  }
}'
# Respuesta esperada: buckets con keys {mes, vendedor}, total_vendido y num_transacciones

echo ""
echo ""
echo "=== Agregaciones composite completadas ==="
