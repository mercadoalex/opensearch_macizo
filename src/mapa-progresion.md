# Mapa de Progresión

Este mapa muestra la ruta de aprendizaje del libro. Cada capítulo lista los temas que cubre y los capítulos que debes dominar antes de abordarlo. Úsalo para planificar tu lectura o saltar directamente al nivel que necesitas.

## Tabla de Progresión por Capítulos

| Cap | Título | Temas | Prerequisitos |
|-----|--------|-------|---------------|
| 1 | ¿Qué es OpenSearch? | Historia, arquitectura, casos de uso | Ninguno |
| 2 | Tu Primer Laboratorio | Docker, cluster health, Dashboards | Cap 1 |
| 3 | CRUD con la REST API | Indexar, buscar, actualizar, eliminar | Cap 2 |
| 4 | Mappings y Analizadores | Tipos de datos, analizadores, mappings | Cap 3 |
| 5 | Puente Novato-Intermedio | Resumen, transición | Caps 1-4 |
| 6 | Query DSL Avanzado | Bool, nested, multi-match, function_score, semantic | Cap 5 |
| 7 | Agregaciones | Métricas, buckets, pipelines, composite | Cap 6 |
| 8 | Estrategias de Indexación | Templates, aliases, ISM, rollover | Cap 5 |
| 9 | Ingest Pipelines | Procesamiento en indexación | Cap 8 |
| 10 | Rendimiento de Búsqueda | Caches, routing, shards, relevancia | Caps 6-7 |
| 11 | Clientes Oficiales | Python, Java, Go | Cap 5 |
| 12 | Puente Intermedio-Ninja | Resumen, transición | Caps 6-11 |
| 13 | Arquitectura de Producción | Sizing, roles, cross-cluster, DR | Cap 12 |
| 14 | Seguridad | Security plugin, roles, auth, cifrado | Cap 13 |
| 15 | Observabilidad con OTEL | Logs, traces, métricas, Data Prepper | Cap 13 |
| 16 | ML y Búsqueda Vectorial | k-NN, embeddings, neural plugins | Cap 6 |
| 17 | SIEM y Alerting | Detección, alertas, correlación | Cap 14 |
| 18 | Optimización y Cierre | JVM, circuit breakers, day-2 ops, checklist | Caps 13-17 |

## Cómo Leer Este Mapa

- **Lectura secuencial**: Si eres nuevo en OpenSearch, empieza por el Cap 1 y avanza en orden. Cada Parte construye sobre la anterior.
- **Salto directo**: Si ya tienes experiencia, consulta la columna Prerequisitos para verificar qué necesitas dominar antes de saltar a un capítulo específico.
- **Capítulos puente** (5, 12): Resumen lo aprendido y preparan la transición al siguiente nivel. No los saltes — consolidan el conocimiento y verifican que estás listo para avanzar.

## Estructura por Partes

| Parte | Nivel | Capítulos | Perfil de Laboratorio |
|-------|-------|-----------|----------------------|
| I | Novato | 1-5 | `novato` (1 nodo) |
| II | Intermedio | 6-12 | `intermedio` (3 nodos) |
| III | Ninja | 13-18 | `ninja` (3 nodos + seguridad) |
