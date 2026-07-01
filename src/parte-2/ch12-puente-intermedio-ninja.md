# Puente: De Intermedio a Ninja

> **Opinión del autor:** Si dominas bool queries, agregaciones, ISM, pipelines y clientes oficiales, ya puedes operar un clúster OpenSearch con confianza. Lo que viene en la Parte III son las decisiones que definen si tu sistema sobrevive a la realidad: producción, seguridad, observabilidad, ML y optimización bajo presión.

## Objetivo

Consolidar los patrones de diseño cubiertos en la Parte II y verificar que dominas los conceptos necesarios para abordar arquitecturas de producción.

## Lo que aprendiste en Parte II

### Capítulo 6 — Query DSL Avanzado

Dominaste las cuatro herramientas de búsqueda avanzada. Las bool queries combinan condiciones con must/filter/should/must_not. Las nested queries preservan relaciones en objetos anidados. Multi-match busca en múltiples campos con control de boost. Function score personaliza la relevancia con funciones matemáticas y decay temporal.

### Capítulo 7 — Agregaciones

Aprendiste los cuatro tipos: métricas (avg, sum, stats, cardinality), buckets (terms, date_histogram, range, filters), pipelines (derivative, cumulative_sum, avg_bucket), y composite para paginación. Combinaste queries con agregaciones para dashboards interactivos.

### Capítulo 8 — Estrategias de Indexación

Construiste templates composables, usaste aliases para desacoplar aplicaciones de índices físicos, definiste ISM policies para automatizar ciclos de vida, y configuraste rollover para rotación transparente.

### Capítulo 9 — Ingest Pipelines

Transformaste datos en tiempo de indexación sin código externo. Usaste grok, dissect, date, set, rename y scripts. Testeaste con _simulate y configuraste default_pipeline en templates.

### Capítulo 10 — Rendimiento de Búsqueda

Entendiste los tres niveles de cache, routing custom para búsquedas dirigidas, profiling para diagnosticar queries lentas, y slow logs para detección proactiva.

### Capítulo 11 — Clientes Oficiales

Integraste OpenSearch con Python, Go y Java. Aprendiste patrones de bulk indexing, manejo de errores, y las diferencias de rendimiento entre clientes.

## Checklist de Prerequisitos para Parte III

| # | Concepto | Capítulo |
|---|----------|----------|
| 1 | Construir bool queries complejas con anidamiento | 6 |
| 2 | Usar function_score para personalizar relevancia | 6 |
| 3 | Agregar datos con date_histogram y pipeline aggregations | 7 |
| 4 | Diseñar templates composables con component templates | 8 |
| 5 | Configurar ISM policies con rollover automático | 8 |
| 6 | Crear ingest pipelines con grok y manejo de errores | 9 |
| 7 | Diagnosticar queries con profile API y slow logs | 10 |
| 8 | Indexar masivamente con bulk helpers en al menos un lenguaje | 11 |

Si dominas los 8 puntos, estás listo para el nivel Ninja.

## Lo que viene en Parte III

| Capítulo | Tema | Problema que resuelve |
|----------|------|----------------------|
| 13 | Arquitectura de Producción | Sizing, roles de nodos, HA, disaster recovery |
| 14 | Seguridad | Autenticación, autorización, cifrado |
| 15 | Observabilidad con OTEL | Logs, traces, métricas con Data Prepper |
| 16 | ML y Búsqueda Vectorial | k-NN, embeddings, neural search |
| 17 | SIEM y Alerting | Detección de amenazas, correlación |
| 18 | Optimización y Cierre | JVM tuning, day-2 ops, checklist producción |

El nivel Ninja combina todo lo anterior con decisiones de infraestructura. Vas a necesitar el perfil `ninja` del laboratorio (3 nodos + seguridad).

## Resumen

- La Parte II te dio las herramientas para construir sistemas de búsqueda y analítica funcionales
- Los 8 prerequisitos del checklist son la base para tomar decisiones arquitectónicas informadas
- La Parte III escala desde un solo clúster de desarrollo a infraestructura de producción real
- Levanta el perfil `ninja` del laboratorio antes de empezar el Capítulo 13
