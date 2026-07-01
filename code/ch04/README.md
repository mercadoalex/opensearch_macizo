# Capítulo 4 — Mappings y Analizadores

Ejemplos de código para el capítulo sobre mappings, tipos de datos y analizadores de texto en OpenSearch.

## Prerequisitos

- Laboratorio levantado con perfil `novato`: `docker compose --profile novato up`
- Capítulo 3 completado (familiaridad con operaciones CRUD)

## Orden de Ejecución

| # | Archivo | Descripción |
|---|---------|-------------|
| 1 | `01-explicit-mapping.sh` | Crea índice con mapping explícito (todos los tipos de datos) |
| 2 | `02-analyze-text.sh` | Usa la API `_analyze` para ver tokenización |
| 3 | `03-custom-analyzer.sh` | Crea un analizador personalizado con filtros |
| 4 | `04-dynamic-mapping.sh` | Demuestra mapping dinámico y sus problemas |

## Ejecución

Desde la raíz del repositorio:

```bash
bash code/ch04/01-explicit-mapping.sh
bash code/ch04/02-analyze-text.sh
bash code/ch04/03-custom-analyzer.sh
bash code/ch04/04-dynamic-mapping.sh
```

## Variables de Entorno

Los scripts usan estas variables con valores por defecto:

| Variable | Valor por defecto | Descripción |
|----------|-------------------|-------------|
| `OPENSEARCH_URL` | `https://localhost:9200` | URL del nodo OpenSearch |
| `OPENSEARCH_USER` | `admin` | Usuario de autenticación |
| `OPENSEARCH_PASS` | `Admin123!` | Contraseña de autenticación |

## Índices Creados

Los scripts crean estos índices de prueba:

- `productos` — Índice con mapping explícito (tipos: text, keyword, integer, float, boolean, date)
- `blog` — Índice con analizador custom (char_filter HTML, stemming español)
- `ventas-demo` — Índice con mapping dinámico (demuestra problemas de inferencia)

## Limpieza

Los scripts eliminan y recrean los índices automáticamente. Para limpiar manualmente:

```bash
curl -sk -X DELETE https://localhost:9200/productos -u admin:Admin123!
curl -sk -X DELETE https://localhost:9200/blog -u admin:Admin123!
curl -sk -X DELETE https://localhost:9200/ventas-demo -u admin:Admin123!
```
