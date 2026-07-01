# Capítulo 9 — Ingest Pipelines

Ejemplos ejecutables para crear, probar y aplicar ingest pipelines.

## Prerequisitos

- Laboratorio levantado con perfil `novato`
- Capítulo 8 completado (templates para `default_pipeline`)

## Archivos

| # | Archivo | Descripción |
|---|---------|-------------|
| 1 | `01-create-pipeline.sh` | Crear pipeline con grok, date, remove, lowercase |
| 2 | `02-simulate.sh` | Probar pipeline con _simulate sin indexar |
| 3 | `03-error-handling.sh` | Pipeline con on_failure para errores graceful |
| 4 | `04-apply-pipeline.sh` | Indexar documentos usando pipeline |

## Ejecución

```bash
bash code/ch09/01-create-pipeline.sh
bash code/ch09/02-simulate.sh
bash code/ch09/03-error-handling.sh
bash code/ch09/04-apply-pipeline.sh
```

## Limpieza

```bash
curl -sk -X DELETE "https://localhost:9200/_ingest/pipeline/logs-pipeline" -u admin:Admin123!
curl -sk -X DELETE "https://localhost:9200/logs" -u admin:Admin123!
```
