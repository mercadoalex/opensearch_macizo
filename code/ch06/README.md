# Capítulo 6 — Query DSL Avanzado

Ejemplos ejecutables para queries avanzadas en OpenSearch: bool queries, nested queries, multi-match, function_score, y búsqueda semántica.

## Prerequisitos

- Laboratorio levantado con perfil `novato` o `intermedio` (ver Capítulo 2):
  ```bash
  docker compose --profile novato up
  ```
- Clúster respondiendo en `https://localhost:9200`

## Orden de ejecución

| # | Script | Descripción |
|---|--------|-------------|
| 0 | `load-data.sh` | Crear índices y cargar datos de prueba |
| 1 | `01-bool-queries.sh` | Bool queries: must, should, must_not, filter |
| 2 | `02-nested-queries.sh` | Nested queries con inner_hits |
| 3 | `03-multi-match.sh` | Multi-match: best_fields, cross_fields, phrase_prefix |
| 4 | `04-function-score.sh` | Function score: decay, script, field_value_factor |
| 5 | `05-semantic-search.sh` | Búsqueda semántica con k-NN y vectores |

## Datos de prueba

El archivo `sample-data.json` contiene:
- **8 artículos** en índice `articulos` — con campos nested (comentarios), fechas, valoraciones
- **7 productos** en índice `productos` — con precios, stock, descripciones

El script `load-data.sh` crea ambos índices con mappings apropiados (incluyendo tipo `nested` para comentarios) y carga todos los documentos.

## Notas

- Todos los comandos usan `-sk` porque el nodo usa TLS auto-firmado
- Credenciales por defecto: `admin:Admin123!`
- Los ejemplos de búsqueda semántica (script 05) crean su propio índice con vectores k-NN
- Para búsqueda neural con modelos ML completos, ver Capítulo 16
- Si un script falla con "index_not_found", ejecuta primero `load-data.sh`
