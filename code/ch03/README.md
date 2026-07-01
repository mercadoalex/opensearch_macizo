# Capítulo 3 — CRUD con la REST API

Ejemplos ejecutables para las operaciones básicas de OpenSearch: crear índices, indexar documentos, buscar, actualizar y eliminar.

## Prerequisitos

- Laboratorio levantado con perfil `novato` (ver Capítulo 2):
  ```bash
  docker compose --profile novato up
  ```
- Clúster respondiendo en `https://localhost:9200`

## Orden de ejecución

| # | Script | Descripción |
|---|--------|-------------|
| 1 | `01-create-index.sh` | Crear el índice `productos` con mapping explícito |
| 2 | `load-data.sh` | Cargar datos de ejemplo desde `sample-data.json` |
| 3 | `02-index-document.sh` | Indexar un documento individual |
| 4 | `03-search.sh` | Buscar documentos con diferentes queries |
| 5 | `04-update.sh` | Actualizar un documento existente |
| 6 | `05-delete.sh` | Eliminar un documento |

## Datos de prueba

El archivo `sample-data.json` contiene 5 productos en formato bulk API. El script `load-data.sh` los carga automáticamente.

## Notas

- Todos los comandos usan `-sk` porque el nodo usa TLS auto-firmado
- Credenciales por defecto: `admin:Admin123!`
- Si un script falla con "index_not_found", ejecuta primero `01-create-index.sh`
