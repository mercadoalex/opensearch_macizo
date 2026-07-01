# Agregaciones

> **Opinión del autor:** Las agregaciones son la feature más subestimada de OpenSearch. La mayoría de equipos las descubren tarde, después de haber montado pipelines de ETL innecesarios hacia herramientas de BI. OpenSearch puede calcular métricas, histogramas y tablas pivot directamente sobre los datos indexados — en milisegundos. Si tu caso de uso involucra analítica sobre datos semi-estructurados, las agregaciones te ahorran una capa completa de infraestructura.

## Objetivo

Dominar los cuatro tipos de agregaciones en OpenSearch: métricas, buckets, pipelines y composite. Al terminar este capítulo sabrás construir dashboards analíticos, reportes de negocio y exportaciones paginadas sin salir de la REST API.

## Prerequisitos

- Capítulo 6: Query DSL avanzado (filtros y queries combinadas)
- Capítulo 3: CRUD y Bulk API (para cargar datos de prueba)
- Clúster OpenSearch corriendo con perfil `novato`

## Contenido

### Anatomía de una agregación

Toda agregación vive dentro del campo `aggs` (o `aggregations`) de un request `_search`. Puedes combinar queries con agregaciones: la query filtra los documentos y las agregaciones operan sobre ese subconjunto.

```json
{
  "size": 0,
  "query": { "match_all": {} },
  "aggs": {
    "nombre_agregacion": {
      "tipo_agregacion": { "field": "campo" }
    }
  }
}
```

`size: 0` evita devolver hits — solo quieres los resultados de la agregación. OpenSearch soporta agregaciones anidadas: un bucket puede contener sub-agregaciones de métricas u otros buckets. Esta composición es lo que hace al sistema tan potente.

Los cuatro tipos fundamentales:

| Tipo | Propósito | Ejemplo |
|------|-----------|---------|
| Metric | Calcular un valor numérico | avg, sum, min, max, stats, cardinality |
| Bucket | Agrupar documentos en conjuntos | terms, date_histogram, range, filters |
| Pipeline | Operar sobre resultados de otras agregaciones | cumulative_sum, derivative, avg_bucket |
| Composite | Paginar combinaciones de buckets | composite con múltiples sources |

### Dataset de trabajo

Los ejemplos usan un índice `ventas` con 20 transacciones de e-commerce. Carga los datos antes de continuar:

```bash
bash code/ch07/load-data.sh
```

El dataset incluye productos de tecnología vendidos en tres regiones de México. Cada documento tiene precio, cantidad, categoría, vendedor, método de pago y fecha de venta.

> 📁 Código fuente: [`code/ch07/load-data.sh`](../../code/ch07/load-data.sh)

---

### Agregaciones de métricas

Las metric aggregations calculan un valor numérico sobre un campo. Son las más simples y las que usarás con mayor frecuencia para KPIs.

#### avg — Precio promedio

Calcula el promedio aritmético de un campo numérico. Caso de uso: ticket promedio en un dashboard de ventas.

```bash
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
```

Respuesta (campos relevantes):

```json
{
  "aggregations": {
    "precio_promedio": {
      "value": 384.4895
    }
  }
}
```

OpenSearch ignora documentos donde el campo es `null`. Si necesitas tratar nulls como cero, usa el parámetro `missing`:

```json
"avg": { "field": "precio", "missing": 0 }
```

#### sum — Ingresos totales con script

Cuando necesitas combinar campos, usa un script en vez de un campo directo. Caso de uso: calcular revenue multiplicando precio por cantidad.

```bash
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
```

Los scripts en agregaciones usan Painless y acceden a los campos via `doc['campo'].value`. Son más lentos que operaciones directas sobre campos — úsalos solo cuando la lógica lo requiera.

#### min y max — Rango de precios

Útiles para construir filtros dinámicos en UIs de e-commerce. Un solo request obtiene ambos extremos.

```bash
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "precio_minimo": { "min": { "field": "precio" } },
    "precio_maximo": { "max": { "field": "precio" } }
  }
}'
```

Respuesta esperada:

```json
{
  "aggregations": {
    "precio_minimo": { "value": 39.99 },
    "precio_maximo": { "value": 1599.99 }
  }
}
```

Puedes combinar múltiples agregaciones de métricas en un solo request sin penalización significativa de rendimiento. OpenSearch las calcula en una sola pasada sobre los datos.

#### cardinality — Valores únicos

Calcula una estimación del número de valores distintos usando HyperLogLog++. Caso de uso: contar cuántas categorías de producto, vendedores activos o regiones tienen actividad.

```bash
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
```

Respuesta esperada:

```json
{
  "aggregations": {
    "categorias_unicas": { "value": 5 }
  }
}
```

`cardinality` es una estimación probabilística, no un conteo exacto. Con el `precision_threshold` por defecto (3000), el error es < 5% para cardinalidades menores a ese umbral. Para datasets con millones de valores únicos, la precisión disminuye pero la velocidad se mantiene constante.

#### stats — Todas las métricas básicas en un request

Devuelve count, min, max, avg y sum en una sola llamada. Caso de uso: obtener un resumen estadístico completo del precio para un dashboard ejecutivo sin múltiples requests.

```bash
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
```

Respuesta esperada:

```json
{
  "aggregations": {
    "resumen_precio": {
      "count": 20,
      "min": 39.99,
      "max": 1599.99,
      "avg": 384.489,
      "sum": 7689.78
    }
  }
}
```

`stats` es una conveniencia — internamente calcula las mismas operaciones que harías con agregaciones individuales. Si solo necesitas una métrica, usa la específica. Si necesitas tres o más, `stats` reduce el boilerplate sin costo adicional.

> 📁 Código fuente: [`code/ch07/01-metric-aggs.sh`](../../code/ch07/01-metric-aggs.sh)

---

### Agregaciones de buckets

Las bucket aggregations agrupan documentos en conjuntos basándose en criterios. Cada bucket puede contener sub-agregaciones de métricas. Son el equivalente de un `GROUP BY` en SQL.

#### terms — Agrupación por valor

Agrupa documentos por los valores de un campo keyword. Caso de uso: ventas por categoría para identificar qué segmentos generan más transacciones.

```bash
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
```

Respuesta esperada:

```json
{
  "aggregations": {
    "por_categoria": {
      "buckets": [
        { "key": "perifericos", "doc_count": 7 },
        { "key": "laptops", "doc_count": 4 },
        { "key": "monitores", "doc_count": 3 },
        { "key": "almacenamiento", "doc_count": 3 },
        { "key": "audio", "doc_count": 3 }
      ]
    }
  }
}
```

El parámetro `size` controla cuántos buckets devolver (top N). El campo `doc_count_error_upper_bound` indica el error máximo posible en los conteos — relevante en índices distribuidos en múltiples shards.

#### terms con sub-agregaciones

La verdadera potencia emerge al anidar agregaciones. Caso de uso: ingreso promedio y total por categoría para comparar rendimiento entre segmentos.

```bash
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "aggs": {
    "por_categoria": {
      "terms": { "field": "categoria", "size": 10 },
      "aggs": {
        "precio_promedio": { "avg": { "field": "precio" } },
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
```

Cada bucket de categoría ahora incluye su precio promedio y el ingreso total. Esto reemplaza una query SQL con `GROUP BY categoria` seguida de `AVG(precio)` y `SUM(precio * cantidad)`.

#### histogram — Distribución numérica

Crea buckets de tamaño fijo sobre un campo numérico. Caso de uso: distribución de precios para segmentación de productos en económico, medio y premium.

```bash
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
```

Respuesta esperada:

```json
{
  "aggregations": {
    "distribucion_precios": {
      "buckets": [
        { "key": 0.0, "doc_count": 7 },
        { "key": 200.0, "doc_count": 4 },
        { "key": 400.0, "doc_count": 3 },
        { "key": 600.0, "doc_count": 1 },
        { "key": 1000.0, "doc_count": 2 },
        { "key": 1200.0, "doc_count": 2 },
        { "key": 1400.0, "doc_count": 1 }
      ]
    }
  }
}
```

`min_doc_count: 1` omite buckets vacíos. Si necesitas todos los buckets incluso sin documentos (para gráficas continuas), usa `min_doc_count: 0` con `extended_bounds`.

#### date_histogram — Series temporales

Agrupa documentos por intervalos de tiempo. Es la agregación estrella para dashboards de monitoreo y tendencias. Caso de uso: ingresos mensuales para planificación de campañas de marketing.

```bash
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
```

Respuesta esperada:

```json
{
  "aggregations": {
    "ventas_mensuales": {
      "buckets": [
        { "key_as_string": "2024-01", "doc_count": 10, "ingresos": { "value": 7159.7 } },
        { "key_as_string": "2024-02", "doc_count": 10, "ingresos": { "value": 5829.7 } }
      ]
    }
  }
}
```

Usa `calendar_interval` para meses, trimestres y años (duración variable). Usa `fixed_interval` para intervalos exactos como `7d`, `1h` o `30m`. No mezcles — OpenSearch los trata como tipos distintos.

#### range — Rangos personalizados

Define buckets con rangos arbitrarios. Caso de uso: segmentar productos en económico/medio/premium para análisis de márgenes por segmento.

```bash
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
        "cantidad_total": { "sum": { "field": "cantidad" } }
      }
    }
  }
}'
```

Los rangos son inclusivos en `from` y exclusivos en `to`. Un documento con `precio: 100` cae en el bucket "medio" (from 100), no en "economico" (to 100). Usa `key` para dar nombres legibles a cada rango.

#### filters — Buckets con queries explícitas

Define buckets usando queries arbitrarias como criterio de agrupación. Caso de uso: comparar métricas entre segmentos definidos por condiciones de negocio distintas.

```bash
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
```

Respuesta esperada:

```json
{
  "aggregations": {
    "segmentos_negocio": {
      "buckets": {
        "ventas_grandes": { "doc_count": 6, "ingresos": { "value": 5149.93 } },
        "ventas_recurrentes": { "doc_count": 9, "ingresos": { "value": 3249.69 } },
        "region_cdmx": { "doc_count": 7, "ingresos": { "value": 4469.83 } }
      }
    }
  }
}
```

A diferencia de `terms`, `filters` permite criterios heterogéneos — cada bucket responde a una pregunta distinta. Un documento puede caer en múltiples buckets si cumple varias condiciones. Usa `other_bucket` para capturar documentos que no caen en ningún filtro definido.

> 📁 Código fuente: [`code/ch07/02-bucket-aggs.sh`](../../code/ch07/02-bucket-aggs.sh)

---

### Agregaciones de pipeline

Las pipeline aggregations operan sobre los resultados de otras agregaciones, no sobre documentos directamente. Requieren que exista una agregación padre cuyos buckets contienen métricas calculadas.

Hay dos subtipos:
- **Parent**: calcula sobre los buckets de una agregación hermana (avg_bucket, max_bucket, sum_bucket)
- **Sibling**: calcula sobre los buckets del padre directo (derivative, cumulative_sum)

#### avg_bucket — Promedio entre buckets

Calcula el promedio de una métrica calculada en múltiples buckets. Caso de uso: ingreso promedio entre todas las categorías para identificar cuáles están por encima o debajo de la media.

```bash
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
```

El `buckets_path` usa la sintaxis `agregacion_bucket>metrica`. El separador `>` navega la jerarquía de agregaciones. `ingreso_promedio_categorias` vive al mismo nivel que `por_categoria` — es una agregación sibling.

#### derivative — Tasa de cambio

Calcula la diferencia entre valores consecutivos en un histograma. Caso de uso: detectar si los ingresos semanales están creciendo o cayendo, para activar alertas de negocio.

```bash
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
        "cambio_ingresos": {
          "derivative": {
            "buckets_path": "ingresos_semana"
          }
        }
      }
    }
  }
}'
```

La `derivative` se coloca dentro del `date_histogram` como sub-agregación. El primer bucket no tiene derivada (no hay bucket anterior con qué comparar). Un valor positivo indica crecimiento; negativo indica descenso.

#### max_bucket — Bucket con valor máximo

Identifica cuál bucket tiene el valor más alto de una métrica. Caso de uso: encontrar la categoría top performer del período.

```bash
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
```

La respuesta incluye tanto el valor máximo como las keys del bucket ganador. `min_bucket` funciona de forma análoga para encontrar el peor performer.

#### cumulative_sum — Acumulado progresivo

Calcula la suma acumulada de una métrica a lo largo de los buckets de un histograma. Caso de uso: visualizar el revenue acumulado del período para tracking de metas de ventas.

```bash
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
```

El `cumulative_sum` se coloca dentro del histograma como sub-agregación hermana de la métrica base. El primer bucket tiene `cumulative_sum` igual a su valor; cada siguiente bucket suma todos los anteriores. Es ideal para gráficos de progreso hacia un target.

> 📁 Código fuente: [`code/ch07/03-pipeline-aggs.sh`](../../code/ch07/03-pipeline-aggs.sh)

---

### Agregaciones composite

Las composite aggregations resuelven un problema específico: paginar eficientemente sobre todas las combinaciones posibles de múltiples campos. A diferencia de `terms` que devuelve los top N, `composite` permite iterar sobre todos los buckets en orden determinístico.

Caso de uso principal: generar reportes completos para exportación a BI, tablas pivot con múltiples dimensiones, o alimentar data lakes.

#### Composite básico — Categoría × Región

```bash
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
        "unidades": { "sum": { "field": "cantidad" } }
      }
    }
  }
}'
```

Respuesta (estructura):

```json
{
  "aggregations": {
    "ventas_cruzadas": {
      "after_key": { "categoria": "audio", "region": "Monterrey" },
      "buckets": [
        {
          "key": { "categoria": "almacenamiento", "region": "CDMX" },
          "doc_count": 0,
          "ingresos": { "value": 0 },
          "unidades": { "value": 0 }
        }
      ]
    }
  }
}
```

El campo `after_key` es la clave de paginación. Para obtener la siguiente página, inclúyelo en el request:

#### Paginación con after

```bash
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
        "after": { "categoria": "audio", "region": "Monterrey" }
      }
    }
  }
}'
```

Repite el ciclo hasta que la respuesta no incluya `after_key` — eso indica que no quedan más buckets. Este patrón es ideal para scripts que exportan datos completos.

#### Composite con date_histogram

Puedes combinar `terms` con `date_histogram` como sources. Caso de uso: reporte mensual de desempeño por vendedor para cálculo de comisiones.

```bash
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
        }
      }
    }
  }
}'
```

Las composite aggregations son la única forma eficiente de obtener todas las combinaciones posibles entre dos o más campos. `terms` con sub-aggregations de `terms` está limitado por el parámetro `size` y puede perder buckets en índices grandes.

> 📁 Código fuente: [`code/ch07/04-composite-aggs.sh`](../../code/ch07/04-composite-aggs.sh)

---

### Combinando queries con agregaciones

Las agregaciones operan sobre los documentos que la query selecciona. Esto permite filtrar antes de agregar — un patrón esencial para dashboards interactivos.

```bash
curl -sk "https://localhost:9200/ventas/_search?size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "filter": [
        { "term": { "region": "CDMX" } },
        { "range": { "fecha_venta": { "gte": "2024-01-01", "lte": "2024-01-31" } } }
      ]
    }
  },
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
    }
  }
}'
```

Usa `bool.filter` en vez de `bool.must` para filtros en contexto de agregaciones. Los filtros no calculan `_score`, lo cual ahorra CPU. Este patrón es exactamente lo que OpenSearch Dashboards ejecuta cuando seleccionas un filtro en un dashboard.

### Rendimiento de agregaciones

Reglas prácticas para agregaciones eficientes:

1. **Usa `size: 0`** siempre que no necesites hits. Evita transferir documentos innecesariamente.
2. **Campos keyword** para terms aggregations. Nunca agregues sobre campos `text` — usa el sub-campo `.keyword`.
3. **Filtra antes de agregar**. Una query `bool.filter` reduce el dataset antes de calcular.
4. **Evita scripts donde puedas**. Un campo pre-calculado en indexación es siempre más rápido que un script en query time.
5. **Cuidado con alta cardinalidad**. `terms` con `size: 10000` en un campo con millones de valores únicos consume memoria significativa.
6. **Usa `shard_size`** para mejorar precisión en `terms` distribuido. El valor por defecto es `size * 1.5 + 10`.

## Cuándo Usar y Cuándo NO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|---|---|
| Necesitas métricas de negocio en tiempo real sobre datos indexados | Tus cálculos requieren JOINs entre múltiples índices (usa una base relacional) |
| Quieres dashboards interactivos con Dashboards/Grafana | Necesitas precisión exacta en cardinality con billones de valores únicos |
| Requieres series temporales con date_histogram | Tu dataset es < 100 docs y puedes calcular en la aplicación |
| Necesitas exportar todas las combinaciones de dimensiones (composite) | Requieres agregaciones sobre datos no indexados en OpenSearch |
| Quieres detectar tendencias con derivative sobre períodos | Necesitas cálculos matriciales complejos (usa un motor de analytics como Spark) |

## Ejercicios

1. **Métricas combinadas**: Calcula en un solo request el precio promedio, mínimo, máximo y la suma total de ingresos (precio × cantidad). Verifica con `stats` que tus resultados coincidan.

2. **Terms con filtro**: Filtra ventas de enero 2024 y calcula el top 3 de vendedores por ingreso total. Usa `bool.filter` con `range` en la query y `terms` + `sum` en las agregaciones.

3. **Date histogram con derivada**: Crea un reporte semanal de ingresos con la variación respecto a la semana anterior. Identifica la semana con mayor caída.

4. **Composite multi-dimensión**: Genera un reporte completo de ventas agrupado por {mes, categoría, región}. Itera con `after` hasta obtener todos los buckets. Cuenta cuántas combinaciones existen.

5. **Pipeline comparison**: Usa `avg_bucket` para encontrar el ingreso promedio entre regiones. Luego usa `max_bucket` y `min_bucket` para identificar la región mejor y peor. Calcula la diferencia manualmente.

## Resumen

- Las metric aggregations (avg, sum, min, max, stats, cardinality) calculan valores numéricos sobre campos — son la base de cualquier KPI
- Las bucket aggregations (terms, date_histogram, range, filters) agrupan documentos como un `GROUP BY` — soportan sub-agregaciones anidadas
- Las pipeline aggregations (cumulative_sum, derivative, avg_bucket) operan sobre resultados de otras agregaciones — útiles para tendencias y comparaciones
- Las composite aggregations permiten paginar eficientemente sobre todas las combinaciones de múltiples dimensiones — ideales para exportación y BI
- Siempre usa `size: 0` y `bool.filter` en contexto de agregaciones para maximizar rendimiento
- `cardinality` es una estimación probabilística — acepta el trade-off de precisión por velocidad en datasets grandes
