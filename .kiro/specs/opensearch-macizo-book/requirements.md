# Requirements Document

## Introduction

"OpenSearch: Macizo y Conciso" es un libro técnico en español que sigue la misma línea editorial de "eBPF: Macizo y Conciso". Es una referencia técnica opinionada sobre OpenSearch que lleva al lector desde sus primeros índices hasta arquitecturas de producción con observabilidad, seguridad y analítica avanzada. Sin relleno corporativo, sin rodeos académicos — código que funciona, explicaciones que van al punto, y ejercicios que obligan a ensuciarse las manos.

El proyecto usa mdBook para la generación del libro, con código fuente en Markdown y ejemplos ejecutables en un directorio `code/`.

## Glossary

- **Libro**: El producto final "OpenSearch: Macizo y Conciso" en formato mdBook (HTML + PDF)
- **Sistema_Generación**: El pipeline basado en mdBook que transforma Markdown en el libro final
- **Capítulo**: Una unidad temática autocontenida dentro de una Parte del libro
- **Ejemplo_Código**: Fragmento funcional de código (queries, configuraciones, scripts) incluido en el libro
- **Laboratorio**: Entorno reproducible con Docker Compose para que el lector practique
- **Parte**: Una agrupación de capítulos por nivel de progresión (Novato, Intermedio, Ninja)
- **Lector**: El usuario final que consume el libro para aprender OpenSearch
- **Repositorio**: El repositorio Git que contiene todo el código fuente del libro
- **CI_Pipeline**: El workflow de GitHub Actions que valida y construye el libro

## Requirements

### Requirement 1: Estructura progresiva del libro en tres partes

**User Story:** Como lector, quiero que el libro tenga una progresión clara por niveles de dificultad, para poder avanzar desde conceptos básicos hasta arquitecturas de producción sin saltos abruptos.

#### Acceptance Criteria

1. THE Libro SHALL organizar su contenido en tres Partes: Novato (capítulos 1-5), Intermedio (capítulos 6-12), y Ninja (capítulos 13-18)
2. WHEN un Lector termina una Parte, THE Libro SHALL incluir un capítulo puente que contenga un resumen de los conceptos clave de la Parte completada, una introducción a los conceptos de la siguiente Parte, y al menos un ejercicio de transición que utilice conocimientos previos en el contexto del nuevo nivel
3. THE Libro SHALL incluir un Prefacio, un Mapa de Progresión que muestre para cada capítulo su título, los temas cubiertos y los capítulos prerrequisito, y una sección de Apéndices
4. THE Libro SHALL incluir un subtítulo de máximo 60 caracteres que combine al menos un término técnico de OpenSearch con una palabra que denote brevedad o solidez
5. IF un capítulo introduce un concepto que depende de conocimientos de una Parte anterior, THEN THE Libro SHALL incluir una referencia explícita al capítulo donde se trató dicho concepto

### Requirement 2: Contenido de Parte I — Nivel Novato

**User Story:** Como lector que nunca ha usado OpenSearch, quiero entender qué es, para qué sirve, y hacer mis primeras operaciones, para tener una base sólida antes de avanzar.

#### Acceptance Criteria

1. THE Libro SHALL incluir un capítulo introductorio que explique qué es OpenSearch, su origen (fork de Elasticsearch), y por qué elegirlo
2. THE Libro SHALL incluir un capítulo de laboratorio con Docker Compose que levante un clúster OpenSearch + Dashboards en menos de 5 minutos, verificable mediante respuesta HTTP 200 al endpoint _cluster/health del nodo y carga exitosa de la interfaz de Dashboards en el navegador
3. WHEN un Lector completa el capítulo de laboratorio, THE Laboratorio SHALL proveer un clúster de un nodo con OpenSearch Dashboards accesible, donde accesible significa que el nodo responde al endpoint _cluster/health con status green o yellow y Dashboards carga su página de inicio sin errores
4. THE Libro SHALL incluir un capítulo que enseñe operaciones CRUD básicas con la REST API (indexar, buscar, actualizar, eliminar documentos), proporcionando al menos un ejemplo ejecutable con su respuesta esperada por cada operación
5. THE Libro SHALL incluir un capítulo sobre mappings, analizadores de texto, y tipos de datos fundamentales cubriendo como mínimo los tipos text, keyword, integer, float, boolean y date
6. THE Libro SHALL incluir un capítulo puente que resuma los conceptos aprendidos y liste explícitamente los prerequisitos necesarios para el nivel intermedio, confirmando en qué capítulo previo se cubrió cada uno

### Requirement 3: Contenido de Parte II — Nivel Intermedio

**User Story:** Como lector con conocimientos básicos de OpenSearch, quiero dominar búsquedas avanzadas, agregaciones y patrones de indexación, para resolver problemas reales de búsqueda y analítica.

#### Acceptance Criteria

1. THE Libro SHALL incluir un capítulo sobre Query DSL avanzado: bool queries, nested, multi-match, function_score, y búsqueda semántica, con al menos dos ejercicios prácticos por tipo de query
2. THE Libro SHALL incluir un capítulo sobre agregaciones: métricas, buckets, pipelines, y composite aggregations, con al menos un caso de uso de analítica real por tipo de agregación
3. THE Libro SHALL incluir un capítulo sobre estrategias de indexación: index templates, aliases, index lifecycle management (ISM), y rollover
4. THE Libro SHALL incluir un capítulo sobre ingest pipelines y procesamiento de datos en tiempo de indexación
5. THE Libro SHALL incluir un capítulo sobre rendimiento de búsqueda: caches, routing, shard allocation, y tuning de relevancia
6. THE Libro SHALL incluir un capítulo sobre los clientes oficiales (Python, Java, Go) con al menos dos patrones de integración por cliente en escenarios de aplicaciones reales
7. THE Libro SHALL incluir un capítulo puente de intermedio a ninja que resuma los patrones de diseño cubiertos y liste los conceptos que se asumen dominados para el nivel Ninja

### Requirement 4: Contenido de Parte III — Nivel Ninja

**User Story:** Como lector con dominio intermedio de OpenSearch, quiero aprender arquitecturas de producción, observabilidad, seguridad y casos de uso avanzados, para diseñar y operar clústeres a escala.

#### Acceptance Criteria

1. THE Libro SHALL incluir un capítulo sobre arquitectura de clústeres en producción que cubra: sizing (con ejemplos para clústeres de 3, 9 y 30+ nodos), roles de nodos (master, data, ingest, coordinating, ML), replicación cross-cluster, y disaster recovery (snapshots, restore, y estrategias de failover)
2. THE Libro SHALL incluir un capítulo sobre seguridad: Security plugin, roles, permisos, autenticación (SAML, OIDC), cifrado en tránsito y en reposo
3. THE Libro SHALL incluir un capítulo sobre observabilidad con OpenSearch: logs, traces y métricas usando Data Prepper y el modelo OTEL
4. THE Libro SHALL incluir un capítulo sobre Machine Learning y búsqueda vectorial: k-NN, modelos de embedding, semantic search con neural plugins
5. THE Libro SHALL incluir un capítulo sobre OpenSearch como SIEM: detección de amenazas, alerting, y correlation engine
6. THE Libro SHALL incluir un capítulo sobre optimización avanzada: JVM tuning, circuit breakers, slow logs, profiling de queries, y operaciones day-2 (rolling upgrades, backup y restore automatizado, reindexación sin downtime, y capacity planning)
7. THE Libro SHALL incluir un capítulo de cierre que sintetice los patrones de arquitectura cubiertos en el nivel Ninja y presente un checklist de validación para puesta en producción de un clúster OpenSearch

### Requirement 5: Línea editorial "Macizo y Conciso"

**User Story:** Como lector, quiero un libro directo y sin relleno, para aprender de forma eficiente sin perder tiempo en contenido superficial.

#### Acceptance Criteria

1. THE Libro SHALL usar un tono técnico en todos los capítulos, donde cada párrafo contiene al menos una afirmación verificable, un ejemplo de código, un comando, o una referencia a configuración de OpenSearch
2. THE Libro SHALL incluir, para cada feature de OpenSearch presentada en un capítulo, una opinión explícita del autor indicando al menos un escenario recomendado de uso y al menos un escenario donde NO se recomienda su uso
3. THE Libro SHALL evitar contenido sin respaldo técnico, definido como: afirmaciones de beneficio sin evidencia medible, descripciones de funcionalidad que repitan la documentación oficial sin añadir contexto práctico, o frases promocionales sin caso de uso concreto
4. WHEN un concepto tiene múltiples formas de implementarse, THE Libro SHALL recomendar una forma preferida indicando los trade-offs en al menos dos dimensiones (entre rendimiento, complejidad operativa, escalabilidad, o costo de mantenimiento)
5. THE Libro SHALL estar escrito íntegramente en español, usando un glosario bilingüe (español-inglés) para términos técnicos cuya traducción al español no aparezca de forma consistente en la documentación oficial de OpenSearch ni en al menos dos libros técnicos publicados en español sobre el mismo dominio
6. THE Libro SHALL limitar las oraciones a un máximo de 35 palabras y los párrafos a un máximo de 6 oraciones, salvo en bloques de código o tablas comparativas

### Requirement 6: Ejemplos de código funcionales

**User Story:** Como lector, quiero que todos los ejemplos de código del libro sean funcionales y ejecutables, para poder replicarlos en mi laboratorio sin ajustes.

#### Acceptance Criteria

1. THE Repositorio SHALL almacenar todos los Ejemplo_Código en un directorio `code/` con subdirectorios por capítulo siguiendo la convención `code/chNN/` (e.g., `code/ch01/`, `code/ch02/`)
2. WHEN un Ejemplo_Código aparece en un capítulo, THE Ejemplo_Código SHALL ser ejecutable sin errores contra la versión de OpenSearch especificada en el Laboratorio y producir la salida documentada en el libro o en un comentario dentro del propio archivo de código
3. THE Libro SHALL especificar la versión exacta de OpenSearch (major.minor.patch, e.g., "2.17.0") contra la cual se probaron los ejemplos, y dicha versión SHALL coincidir con la imagen Docker usada en el Laboratorio
4. THE Ejemplo_Código SHALL incluir queries REST (curl/httpie), configuraciones YAML, y scripts en Python o Go según el capítulo lo requiera
5. IF un Ejemplo_Código requiere datos de prueba, THEN THE Repositorio SHALL incluir un script o dataset en el mismo subdirectorio del capítulo que cargue los datos necesarios con un tamaño máximo de 10 MB por dataset; IF los datos esenciales para el ejemplo exceden 10 MB, THEN THE Repositorio SHALL permitir la excepción documentando la justificación en el README del capítulo
6. WHEN un Ejemplo_Código utiliza dependencias externas (paquetes Python, módulos Go), THE Repositorio SHALL incluir un archivo de dependencias (`requirements.txt` o `go.mod`) en el subdirectorio del capítulo correspondiente con versiones fijadas
7. WHEN un Ejemplo_Código aparece en el texto del Libro, THE Libro SHALL incluir una referencia al archivo fuente en el Repositorio indicando la ruta relativa dentro de `code/`

### Requirement 7: Laboratorio reproducible

**User Story:** Como lector, quiero un entorno de práctica que pueda levantar y destruir fácilmente, para experimentar sin riesgo y sin depender de infraestructura externa.

#### Acceptance Criteria

1. THE Laboratorio SHALL basarse en Docker Compose con archivos organizados en el directorio `code/`, utilizando un archivo base `docker-compose.yml` y perfiles (profiles) de Compose para seleccionar la configuración deseada: `novato` (un nodo), `intermedio` (multi-nodo con 3 nodos), y `ninja` (clúster de 3 nodos con seguridad habilitada)
2. WHEN un Lector ejecuta `docker compose --profile <perfil> up`, THE Laboratorio SHALL responder con estado healthy en el endpoint `_cluster/health` dentro de un máximo de 2 minutos para el perfil `novato` y de 3 minutos para los perfiles `intermedio` y `ninja`
3. THE Laboratorio SHALL incluir OpenSearch Dashboards preconfigurado con al menos un index pattern y un dashboard de ejemplo cargados automáticamente al iniciar
4. WHEN un Lector ejecuta `docker compose --profile <perfil> down -v`, THE Laboratorio SHALL eliminar todos los contenedores y volúmenes asociados, dejando el sistema en estado limpio sin datos residuales
5. IF el Lector no tiene Docker instalado, THEN THE Libro SHALL proveer instrucciones alternativas indicando al menos un sandbox cloud gratuito con nombre específico y los pasos necesarios para replicar los ejercicios del nivel Novato en dicho entorno
6. THE Laboratorio SHALL documentar en un archivo README dentro del directorio `code/` los requisitos mínimos del sistema host: versión mínima de Docker Engine, versión mínima de Docker Compose, y memoria RAM mínima recomendada para cada perfil

### Requirement 8: Sistema de generación con mdBook

**User Story:** Como autor, quiero usar mdBook para generar el libro, para mantener consistencia con el proyecto eBPF Macizo y aprovechar su ecosistema de plugins.

#### Acceptance Criteria

1. THE Sistema_Generación SHALL usar mdBook como herramienta de build con configuración en `book.toml`
2. WHEN el autor ejecuta el comando de build, THE Sistema_Generación SHALL generar salida HTML en el directorio de salida por defecto de mdBook y SHALL generar salida PDF mediante un backend de generación PDF configurado en `book.toml`
3. WHEN un capítulo contiene un bloque de código con lenguaje `mermaid`, THE Sistema_Generación SHALL renderizar el diagrama como imagen visible en la salida HTML generada mediante un preprocesador Mermaid configurado en `book.toml`
4. THE Repositorio SHALL organizar el código fuente Markdown en un directorio `src/` con un archivo `SUMMARY.md` como tabla de contenidos
5. WHEN se genera la salida HTML, THE Sistema_Generación SHALL incluir el archivo `theme/custom.css` de modo que los estilos definidos en él se apliquen a todas las páginas del libro generado
6. IF el proceso de build falla por sintaxis Markdown inválida, diagrama Mermaid malformado o error en la generación PDF, THEN THE Sistema_Generación SHALL terminar el build con un código de salida distinto de cero e indicar un mensaje de error que identifique el archivo y el tipo de fallo, incluso cuando la salida HTML se haya generado correctamente

### Requirement 9: CI/CD y validación automática

**User Story:** Como autor, quiero un pipeline de CI que valide la estructura y los ejemplos del libro automáticamente, para detectar errores antes de publicar.

#### Acceptance Criteria

1. WHEN se realiza un push a la rama main, THE CI_Pipeline SHALL ejecutarse en GitHub Actions
2. THE CI_Pipeline SHALL compilar el libro con mdBook y verificar que el proceso finaliza sin errores (exit code 0)
3. WHEN un Ejemplo_Código es modificado, THE CI_Pipeline SHALL verificar la sintaxis del código modificado utilizando un linter apropiado para el lenguaje del ejemplo y reportar los errores detectados en el resultado del pipeline
4. WHEN todas las validaciones del pipeline finalizan sin errores y se realiza un merge a main, THE CI_Pipeline SHALL desplegar la versión HTML del libro a GitHub Pages
5. IF la compilación de mdBook falla, THEN THE CI_Pipeline SHALL indicar el error en el resultado del workflow de GitHub Actions y bloquear el merge mediante un check de estado fallido
6. IF el despliegue a GitHub Pages falla, THEN THE CI_Pipeline SHALL indicar el error en el resultado del workflow de GitHub Actions y mantener la última versión desplegada sin cambios
7. WHEN la validación de linting de un Ejemplo_Código falla, THE CI_Pipeline SHALL reportar el error pero SHALL NOT bloquear el merge

### Requirement 10: Apéndices y material de referencia

**User Story:** Como lector, quiero material de referencia rápida que pueda consultar sin releer capítulos completos, para resolver dudas puntuales de forma eficiente.

#### Acceptance Criteria

1. THE Libro SHALL incluir un Apéndice con glosario bilingüe (español-inglés) que contenga al menos 50 términos técnicos, cubriendo todos los conceptos introducidos por primera vez en cada capítulo, ordenados alfabéticamente y con definición de máximo 2 oraciones por término
2. THE Libro SHALL incluir un Apéndice con cheatsheet de la REST API de OpenSearch que cubra al menos 15 endpoints, cada uno documentado con método HTTP, ruta, descripción de una línea y ejemplo de request mínimo funcional
3. THE Libro SHALL incluir un Apéndice con referencia rápida del Query DSL que contenga al menos 10 patrones de consulta, cada uno con nombre del patrón, caso de uso en una línea, y ejemplo de query ejecutable contra un índice de prueba
4. THE Libro SHALL incluir un Apéndice con troubleshooting de al menos 8 errores de clúster (incluyendo red/yellow status, circuit breakers y shard allocation), donde cada entrada siga el formato: síntoma observable, causa probable y comando o acción de resolución
5. THE Libro SHALL incluir un Apéndice con recursos y comunidad que liste al menos 10 recursos categorizados por tipo (documentación oficial, foros, repositorios, herramientas), cada uno con nombre, URL y descripción de una línea sobre su utilidad

### Requirement 11: Audiencia objetivo y prerequisitos

**User Story:** Como lector potencial, quiero saber claramente si este libro es para mí, para no invertir tiempo en algo que no se ajusta a mi nivel o intereses.

#### Acceptance Criteria

1. THE Libro SHALL definir explícitamente en el Prefacio los prerequisitos mínimos: capacidad de realizar requests HTTP con herramientas de línea de comandos (curl o httpie), capacidad de leer y escribir documentos JSON, y capacidad de navegar el sistema de archivos y ejecutar comandos en una terminal
2. THE Libro SHALL especificar que NO es un manual de referencia exhaustivo de la API, sino una guía opinionada de aprendizaje progresivo
3. THE Libro SHALL indicar que cubre desde principiantes con experiencia general en desarrollo hasta ingenieros senior que quieren dominar OpenSearch
4. WHEN el Libro presenta un concepto que requiere conocimiento previo externo, THE Libro SHALL proveer una explicación inline de máximo 2 párrafos; IF la explicación requeriría más de 2 párrafos, THEN THE Libro SHALL proveer una referencia externa con título y URL
5. THE Libro SHALL incluir una sección "¿Es este libro para ti?" en el Prefacio con indicadores explícitos de "sí es para ti si..." y "no es para ti si..." que permitan al lector autoevaluar su adecuación en menos de 1 minuto de lectura
