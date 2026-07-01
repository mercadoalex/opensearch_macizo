#!/bin/bash
# Capítulo 7: Agregaciones de pipeline
# Prerequisito: Ejecutar load-data.sh primero
# Casos: avg_bucket, derivative, max_bucket, sum_bucket

set -e

echo "=== 1. Ingreso promedio entre categorías (avg_bucket) ==="
# Caso de uso: Calcular el ingreso promedio por categoría para comparar rendimiento
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "por_categoria": {
      "terms": { "field": "categoria" },
      "aggs": {
        "ingresos": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        }
      }
    },
    "ingreso_promedio_categorias": {
      "avg_bucket": {
        "buckets_path": "por_categoria>ingresos"
      }
    }
  }
}'
# Respuesta esperada: "ingreso_promedio_categorias": { "value": promedio de ingresos entre categorías }

echo ""
echo ""

echo "=== 2. Derivada de ventas mensuales (derivative) ==="
# Caso de uso: Detectar aceleración o desaceleración en tendencia de ventas
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ventas_mensuales": {
      "date_histogram": {
        "field": "fecha_venta",
        "calendar_interval": "week",
        "format": "yyyy-MM-dd"
      },
      "aggs": {
        "ingresos_semana": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        },
        "cambio_ingresos": {
          "derivative": {
            "buckets_path": "ingresos_semana"
          }
        }
      }
    }
  }
}'
# Respuesta esperada: cada bucket semanal incluye ingresos y la diferencia respecto a la semana anterior

echo ""
echo ""

echo "=== 3. Categoría con mayor ingreso (max_bucket) ==="
# Caso de uso: Identificar la categoría top performer del período
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "por_categoria": {
      "terms": { "field": "categoria" },
      "aggs": {
        "ingresos": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        }
      }
    },
    "categoria_top": {
      "max_bucket": {
        "buckets_path": "por_categoria>ingresos"
      }
    }
  }
}'
# Respuesta esperada: "categoria_top": { "value": max_ingreso, "keys": ["laptops"] }

echo ""
echo ""

echo "=== 4. Ingreso total sumando todas las categorías (sum_bucket) ==="
# Caso de uso: Verificar consistencia entre suma directa y suma de buckets
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "por_region": {
      "terms": { "field": "region" },
      "aggs": {
        "ingresos_region": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        }
      }
    },
    "ingresos_todas_regiones": {
      "sum_bucket": {
        "buckets_path": "por_region>ingresos_region"
      }
    }
  }
}'
# Respuesta esperada: "ingresos_todas_regiones": { "value": suma total de ingresos }

echo ""
echo ""

echo "=== 5. Ingresos acumulados por semana (cumulative_sum) ==="
# Caso de uso: Tracking de revenue acumulado para metas de ventas
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "ventas_semanales": {
      "date_histogram": {
        "field": "fecha_venta",
        "calendar_interval": "week",
        "format": "yyyy-MM-dd"
      },
      "aggs": {
        "ingresos_semana": {
          "sum": {
            "script": {
              "source": "doc['"'"'precio'"'"'].value * doc['"'"'cantidad'"'"'].value"
            }
          }
        },
        "ingresos_acumulados": {
          "cumulative_sum": {
            "buckets_path": "ingresos_semana"
          }
        }
      }
    }
  }
}'
# Respuesta esperada: cada bucket incluye ingresos_semana y la suma acumulada hasta ese punto

echo ""
echo ""
echo "=== Agregaciones de pipeline completadas ==="
