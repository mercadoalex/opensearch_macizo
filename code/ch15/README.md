# Capítulo 15 — Observabilidad con OTEL

Configuración de Data Prepper y ejemplo de envío de traces.

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `data-prepper-config.yaml` | Pipelines de Data Prepper (logs, traces, metrics) |
| `docker-compose-observability.yml` | Docker Compose override con Data Prepper |
| `send-traces.py` | Enviar traces de ejemplo con OTEL SDK |

## Prerequisitos

- Laboratorio levantado con perfil `ninja`
- Python: `pip install opentelemetry-sdk opentelemetry-exporter-otlp`

## Ejecución

```bash
# Levantar Data Prepper (agregar al compose o usar override)
docker compose -f docker-compose.yml -f code/ch15/docker-compose-observability.yml up

# Enviar traces
python code/ch15/send-traces.py
```
