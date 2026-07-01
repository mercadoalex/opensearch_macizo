# Implementation Plan: OpenSearch Macizo y Conciso

## Overview

Implementación incremental del libro "OpenSearch: Macizo y Conciso" usando mdBook. Se comienza con la infraestructura del repositorio (configuración de build, Docker Compose, CI/CD, tema CSS), luego se crean los capítulos progresivamente por Parte (Novato → Intermedio → Ninja), y se finaliza con apéndices y wiring de referencias cruzadas.

## Tasks

- [x] 1. Scaffold del repositorio y configuración de build
  - [x] 1.1 Crear estructura de directorios y archivos base del repositorio
    - Crear directorios: `src/`, `src/parte-1/`, `src/parte-2/`, `src/parte-3/`, `src/apendices/`, `code/`, `code/dashboards-setup/`, `theme/`, `.github/workflows/`
    - Crear archivos placeholder: `README.md`, `.gitignore`
    - El `.gitignore` debe incluir: `book/`, `code/certs/*.pem`, `code/certs/*.key`, `.env`
    - _Requirements: 8.4, 6.1_

  - [x] 1.2 Crear `book.toml` con configuración completa de mdBook
    - Configurar título, autor, idioma `es`, directorio src
    - Configurar preprocesador `mdbook-mermaid`
    - Configurar `output.html` con `additional-css = ["theme/custom.css"]` y `git-repository-url`
    - Configurar `output.pdf` con backend `mdbook-pdf`
    - Configurar `output.html.fold.enable = true`
    - _Requirements: 8.1, 8.3, 8.5_

  - [x] 1.3 Crear `src/SUMMARY.md` con la tabla de contenidos completa
    - Incluir Prefacio y Mapa de Progresión como páginas iniciales
    - Organizar 18 capítulos en 3 Partes con separadores mdBook (`# Parte I — Novato`, etc.)
    - Incluir 5 apéndices en sección separada
    - Todas las rutas deben coincidir con la estructura de archivos planificada
    - _Requirements: 8.4, 1.1, 1.3_

  - [x] 1.4 Crear `theme/custom.css` con el tema visual del libro
    - Definir variables CSS: `--macizo-primary` (#005EB8), `--macizo-accent` (#FF9900), `--macizo-bg`, `--macizo-text`
    - Estilo de tipografía densa con `JetBrains Mono` / `Fira Code` como fallback
    - Estilo para callouts de opinión del autor (`blockquote.opinion`)
    - Estilo para referencias a código fuente (`blockquote.code-ref`)
    - `line-height: 1.6`, `max-width: 48rem` para legibilidad
    - _Requirements: 8.5, 5.1_

- [x] 2. Infraestructura Docker Compose para laboratorio
  - [x] 2.1 Crear `code/docker-compose.yml` con perfiles novato, intermedio y ninja
    - Servicio `opensearch-node1` con imagen `opensearchproject/opensearch:2.17.0`, profiles `[novato, intermedio, ninja]`
    - Healthcheck con curl a `_cluster/health`, interval 10s, timeout 5s, retries 12
    - Servicios `opensearch-node2` y `opensearch-node3` con profiles `[intermedio, ninja]`
    - Configurar discovery y cluster_manager_nodes para multi-nodo
    - Servicio `dashboards` con imagen `opensearchproject/opensearch-dashboards:2.17.0`
    - Servicio `dashboards-setup` para carga automática de index patterns
    - Volúmenes nombrados para cada nodo
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 6.3, 2.2, 2.3_

  - [x] 2.2 Crear scripts de setup de Dashboards en `code/dashboards-setup/`
    - Crear `code/dashboards-setup/init.sh` que espere a Dashboards y cargue configuración
    - Crear index pattern de ejemplo y dashboard básico via API de Saved Objects
    - El script debe reintentar hasta que Dashboards responda
    - _Requirements: 7.3_

  - [x] 2.3 Crear `code/README.md` con requisitos del sistema host
    - Tabla con requisitos por perfil: Docker Engine ≥ 24.0, Docker Compose ≥ 2.20
    - RAM mínima: novato 4GB, intermedio 8GB, ninja 12GB
    - Instrucciones de uso: `docker compose --profile <perfil> up` y `down -v`
    - Instrucciones alternativas para sandbox cloud (Req 7.5)
    - _Requirements: 7.6, 7.5_

  - [x] 2.4 Crear script de generación de certificados TLS para perfil ninja
    - Crear `code/certs/generate.sh` que genere certificados auto-firmados
    - Agregar `code/certs/*.pem` y `code/certs/*.key` a `.gitignore`
    - Documentar que los certs son SOLO para desarrollo
    - _Requirements: 7.1 (perfil ninja)_

- [x] 3. Pipeline CI/CD con GitHub Actions
  - [x] 3.1 Crear `.github/workflows/build.yml` para validación en PRs y pushes a main
    - Trigger: push a main y pull_request a main
    - Steps: checkout, instalar mdBook + mdbook-mermaid + mdbook-pdf, ejecutar `mdbook build`
    - Lint de ejemplos: shellcheck, py_compile, yamllint con `continue-on-error: true`
    - El build de mdBook NO debe tener `continue-on-error` (bloquea merge si falla)
    - _Requirements: 9.1, 9.2, 9.3, 9.5, 9.7_

  - [x] 3.2 Crear `.github/workflows/deploy.yml` para deploy a GitHub Pages
    - Trigger: push a main solamente
    - Permissions: `pages: write`, `id-token: write`
    - Steps: checkout, instalar mdBook, build, upload-pages-artifact, deploy-pages
    - Configurar environment `github-pages`
    - Si deploy falla, la versión anterior se mantiene automáticamente
    - _Requirements: 9.4, 9.6_

- [x] 4. Checkpoint - Verificar infraestructura base
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Contenido del Prefacio y Mapa de Progresión
  - [x] 5.1 Crear `src/prefacio.md` con prefacio completo del libro
    - Sección "¿Es este libro para ti?" con indicadores "sí es para ti si..." y "no es para ti si..."
    - Prerequisitos mínimos: HTTP requests (curl/httpie), JSON, terminal
    - Indicar que NO es manual de referencia exhaustivo sino guía opinionada
    - Audiencia: desde principiantes con experiencia en desarrollo hasta ingenieros senior
    - Subtítulo del libro (máx 60 caracteres, combinando término OpenSearch + solidez/brevedad)
    - _Requirements: 11.1, 11.2, 11.3, 11.5, 1.4_

  - [x] 5.2 Crear `src/mapa-progresion.md` con tabla de progresión por capítulos
    - Tabla con columnas: Cap, Título, Temas, Prerequisitos
    - Cubrir los 18 capítulos con sus dependencias
    - _Requirements: 1.3_

- [x] 6. Contenido Parte I — Nivel Novato (capítulos 1-5)
  - [x] 6.1 Crear `src/parte-1/ch01-que-es-opensearch.md` — ¿Qué es OpenSearch?
    - Explicar qué es OpenSearch, su origen como fork de Elasticsearch, y por qué elegirlo
    - Seguir estructura de capítulo: opinión del autor, objetivo, contenido, cuándo usar/no usar, ejercicios, resumen
    - Incluir opinión explícita del autor con escenario recomendado y no recomendado
    - Limitar oraciones a máx 35 palabras, párrafos a máx 6 oraciones
    - _Requirements: 2.1, 5.1, 5.2, 5.6_

  - [x] 6.2 Crear `src/parte-1/ch02-laboratorio.md` y ejemplos en `code/ch02/`
    - Capítulo de laboratorio con Docker Compose: levantar clúster en < 5 min
    - Verificación: HTTP 200 en `_cluster/health` + Dashboards accesible
    - Crear `code/ch02/verify-cluster.sh` con curl al endpoint health
    - Incluir referencia al código fuente con formato `📁 Código fuente: [...]`
    - _Requirements: 2.2, 2.3, 6.7, 5.1_

  - [x] 6.3 Crear `src/parte-1/ch03-crud-rest-api.md` y ejemplos en `code/ch03/`
    - Operaciones CRUD: indexar, buscar, actualizar, eliminar
    - Al menos un ejemplo ejecutable por operación con respuesta esperada
    - Crear scripts: `code/ch03/01-create-index.sh`, `02-index-document.sh`, `03-search.sh`, `04-update.sh`, `05-delete.sh`
    - Crear `code/ch03/sample-data.json` y `code/ch03/load-data.sh`
    - Incluir `code/ch03/README.md` con instrucciones
    - _Requirements: 2.4, 6.1, 6.2, 6.4, 6.5, 6.7_

  - [x] 6.4 Crear `src/parte-1/ch04-mappings-analizadores.md` y ejemplos en `code/ch04/`
    - Cubrir tipos: text, keyword, integer, float, boolean, date
    - Explicar analizadores de texto y mappings
    - Crear ejemplos ejecutables en `code/ch04/`
    - Opinión del autor sobre cuándo usar dynamic vs explicit mappings
    - _Requirements: 2.5, 5.2, 6.1, 6.7_

  - [x] 6.5 Crear `src/parte-1/ch05-puente-novato-intermedio.md`
    - Resumen de conceptos clave de Parte I
    - Lista explícita de prerequisitos para nivel intermedio con referencia a capítulo previo
    - Ejercicio de transición que combine conocimientos previos
    - _Requirements: 1.2, 2.6_

- [x] 7. Checkpoint - Verificar Parte I completa
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Contenido Parte II — Nivel Intermedio (capítulos 6-12)
  - [x] 8.1 Crear `src/parte-2/ch06-query-dsl-avanzado.md` y ejemplos en `code/ch06/`
    - Bool queries, nested, multi-match, function_score, búsqueda semántica
    - Al menos 2 ejercicios prácticos por tipo de query
    - Ejemplos ejecutables en `code/ch06/` con datos de prueba
    - _Requirements: 3.1, 6.1, 6.2, 6.5, 6.7_

  - [x] 8.2 Crear `src/parte-2/ch07-agregaciones.md` y ejemplos en `code/ch07/`
    - Métricas, buckets, pipelines, composite aggregations
    - Al menos un caso de uso de analítica real por tipo de agregación
    - Ejemplos ejecutables con datasets en `code/ch07/`
    - _Requirements: 3.2, 6.1, 6.5, 6.7_

  - [x] 8.3 Crear `src/parte-2/ch08-estrategias-indexacion.md` y ejemplos en `code/ch08/`
    - Index templates, aliases, ISM, rollover
    - Ejemplos de configuración YAML y REST calls
    - _Requirements: 3.3, 6.1, 6.4, 6.7_

  - [x] 8.4 Crear `src/parte-2/ch09-ingest-pipelines.md` y ejemplos en `code/ch09/`
    - Procesamiento de datos en tiempo de indexación
    - Ejemplos de pipelines con procesadores comunes
    - _Requirements: 3.4, 6.1, 6.7_

  - [x] 8.5 Crear `src/parte-2/ch10-rendimiento-busqueda.md` y ejemplos en `code/ch10/`
    - Caches, routing, shard allocation, tuning de relevancia
    - Comparativas con trade-offs en rendimiento vs complejidad
    - _Requirements: 3.5, 5.4, 6.7_

  - [x] 8.6 Crear `src/parte-2/ch11-clientes-oficiales.md` y ejemplos en `code/ch11/`
    - Clientes Python, Java, Go
    - Al menos 2 patrones de integración por cliente en escenarios reales
    - Crear `code/ch11/python/requirements.txt` y `code/ch11/go/go.mod` con versiones pinned
    - _Requirements: 3.6, 6.4, 6.6, 6.7_

  - [x] 8.7 Crear `src/parte-2/ch12-puente-intermedio-ninja.md`
    - Resumen de patrones de diseño cubiertos en Parte II
    - Lista de conceptos que se asumen dominados para nivel Ninja
    - Referencia a capítulos previos donde se cubrió cada concepto
    - _Requirements: 1.2, 3.7_

- [x] 9. Checkpoint - Verificar Parte II completa
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Contenido Parte III — Nivel Ninja (capítulos 13-18)
  - [x] 10.1 Crear `src/parte-3/ch13-arquitectura-produccion.md` y ejemplos en `code/ch13/`
    - Sizing: ejemplos para clústeres de 3, 9 y 30+ nodos
    - Roles de nodos: master, data, ingest, coordinating, ML
    - Replicación cross-cluster, disaster recovery, snapshots, restore, failover
    - _Requirements: 4.1, 6.7_

  - [x] 10.2 Crear `src/parte-3/ch14-seguridad.md` y ejemplos en `code/ch14/`
    - Security plugin, roles, permisos
    - Autenticación: SAML, OIDC
    - Cifrado en tránsito y en reposo
    - Configuraciones YAML de ejemplo
    - _Requirements: 4.2, 6.4, 6.7_

  - [x] 10.3 Crear `src/parte-3/ch15-observabilidad-otel.md` y ejemplos en `code/ch15/`
    - Logs, traces, métricas con Data Prepper y modelo OTEL
    - Configuración de Data Prepper como pipeline
    - _Requirements: 4.3, 6.7_

  - [x] 10.4 Crear `src/parte-3/ch16-ml-busqueda-vectorial.md` y ejemplos en `code/ch16/`
    - k-NN, modelos de embedding, semantic search con neural plugins
    - Ejemplo de indexación y búsqueda vectorial
    - _Requirements: 4.4, 6.7_

  - [x] 10.5 Crear `src/parte-3/ch17-siem-alerting.md` y ejemplos en `code/ch17/`
    - OpenSearch como SIEM: detección de amenazas, alerting, correlation engine
    - Reglas de detección y configuración de alertas
    - _Requirements: 4.5, 6.7_

  - [x] 10.6 Crear `src/parte-3/ch18-optimizacion-cierre.md` y ejemplos en `code/ch18/`
    - JVM tuning, circuit breakers, slow logs, profiling de queries
    - Operaciones day-2: rolling upgrades, backup/restore, reindexación sin downtime, capacity planning
    - Checklist de validación para puesta en producción
    - _Requirements: 4.6, 4.7, 6.7_

- [x] 11. Checkpoint - Verificar Parte III completa
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Apéndices y material de referencia
  - [x] 12.1 Crear `src/apendices/glosario-bilingue.md`
    - Al menos 50 términos técnicos español-inglés
    - Cubrir todos los conceptos introducidos por primera vez en cada capítulo
    - Ordenados alfabéticamente, definición de máx 2 oraciones por término
    - _Requirements: 10.1, 5.5_

  - [x] 12.2 Crear `src/apendices/cheatsheet-api.md`
    - Al menos 15 endpoints de la REST API
    - Cada uno con: método HTTP, ruta, descripción de una línea, ejemplo de request mínimo
    - _Requirements: 10.2_

  - [x] 12.3 Crear `src/apendices/referencia-query-dsl.md`
    - Al menos 10 patrones de consulta
    - Cada uno con: nombre, caso de uso en una línea, ejemplo ejecutable
    - _Requirements: 10.3_

  - [x] 12.4 Crear `src/apendices/troubleshooting.md`
    - Al menos 8 errores de clúster: red/yellow status, circuit breakers, shard allocation, etc.
    - Formato: síntoma, causa probable, comando/acción de resolución
    - _Requirements: 10.4_

  - [x] 12.5 Crear `src/apendices/recursos-comunidad.md`
    - Al menos 10 recursos categorizados por tipo
    - Cada uno con: nombre, URL, descripción de una línea
    - _Requirements: 10.5_

- [x] 13. Integración final y verificación de referencias
  - [x] 13.1 Verificar y completar referencias cruzadas entre capítulos
    - Asegurar que cada capítulo que introduce un concepto dependiente incluya referencia explícita
    - Verificar que las rutas en `📁 Código fuente:` apunten a archivos existentes
    - _Requirements: 1.5, 6.7_

  - [x] 13.2 Crear `README.md` raíz del proyecto
    - Descripción del libro y cómo contribuir
    - Instrucciones de build local: instalar mdBook, `mdbook build`, `mdbook serve`
    - Instrucciones del laboratorio
    - Links al libro desplegado en GitHub Pages
    - _Requirements: 8.1_

- [x] 14. Final checkpoint - Verificar build completo
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP — no optional tasks in this plan since all content is required per requirements
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation of each Part
- El contenido de cada capítulo debe seguir el modelo de estructura definido en el diseño (opinión, objetivo, prerequisitos, contenido, cuándo usar/no usar, ejercicios, resumen)
- Todos los ejemplos de código deben incluir comentario con respuesta esperada
- La versión de OpenSearch es `2.17.0` en todo el proyecto
- Los capítulos puente (5, 12) son cruciales para la progresión — no omitir

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3", "1.4"] },
    { "id": 2, "tasks": ["2.1", "3.1", "3.2"] },
    { "id": 3, "tasks": ["2.2", "2.3", "2.4", "5.1", "5.2"] },
    { "id": 4, "tasks": ["6.1", "6.2"] },
    { "id": 5, "tasks": ["6.3", "6.4"] },
    { "id": 6, "tasks": ["6.5"] },
    { "id": 7, "tasks": ["8.1", "8.2", "8.3"] },
    { "id": 8, "tasks": ["8.4", "8.5", "8.6"] },
    { "id": 9, "tasks": ["8.7"] },
    { "id": 10, "tasks": ["10.1", "10.2", "10.3"] },
    { "id": 11, "tasks": ["10.4", "10.5", "10.6"] },
    { "id": 12, "tasks": ["12.1", "12.2", "12.3", "12.4", "12.5"] },
    { "id": 13, "tasks": ["13.1", "13.2"] }
  ]
}
```
