# Capítulo 7: Agregaciones

Ejemplos ejecutables del capítulo de agregaciones. Dataset de 20 ventas de e-commerce.

## Prerequisitos

- Clúster OpenSearch corriendo con perfil `novato` (ver `code/docker-compose.yml`)
- Capítulo 6 completado (conceptos de Query DSL)

## Orden de ejecución

1. `load-data.sh` — Crea el índice `ventas` y carga 20 documentos de prueba
2. `01-metric-aggs.sh` — Agregaciones de métricas: avg, sum, min, max, stats, cardinality
3. `02-bucket-aggs.sh` — Agregaciones de buckets: terms, histogram, date_histogram, range, filters
4. `03-pipeline-aggs.sh` — Agregaciones de pipeline: avg_bucket, derivative, max_bucket, cumulative_sum
5. `04-composite-aggs.sh` — Agregaciones composite con paginación

## Dataset

El archivo `sample-data.json` contiene 20 transacciones de ventas con los campos:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| producto | text + keyword | Nombre del producto |
| categoria | keyword | laptops, monitores, perifericos, audio, almacenamiento |
| precio | float | Precio unitario en USD |
| cantidad | integer | Unidades vendidas |
| vendedor | keyword | Nombre del vendedor |
| region | keyword | CDMX, Guadalajara, Monterrey |
| metodo_pago | keyword | tarjeta_credito, tarjeta_debito, transferencia, efectivo |
| fecha_venta | date | Fecha de la transacción (enero-febrero 2024) |

## Limpieza

```bash
curl -sk -X DELETE "https://localhost:9200/ventas" -u admin:Admin123!
```
