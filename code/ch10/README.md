# Capítulo 10 — Rendimiento de Búsqueda

Ejemplos de caches, routing, profiling y slow logs.

## Prerequisitos

- Laboratorio con perfil `novato` levantado
- Índice `ventas` cargado (ver `code/ch07/load-data.sh`)

## Archivos

| # | Archivo | Descripción |
|---|---------|-------------|
| 1 | `01-caches.sh` | Verificar estado de caches y request_cache |
| 2 | `02-routing.sh` | Routing custom para búsquedas dirigidas |
| 3 | `03-profiling.sh` | Profile API para diagnosticar queries lentas |

## Ejecución

```bash
bash code/ch10/01-caches.sh
bash code/ch10/02-routing.sh
bash code/ch10/03-profiling.sh
```
