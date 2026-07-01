# Prefacio

## De índices a clústeres: sin rodeos

Este libro te lleva de cero a producción con OpenSearch. Sin relleno. Sin rodeos académicos. Código que funciona, explicaciones que van al punto.

OpenSearch es un motor de búsqueda y analítica distribuido. Nació como fork de Elasticsearch en 2021. Hoy es un proyecto independiente con licencia Apache 2.0 y un ecosistema en crecimiento activo.

"Macizo y Conciso" no repite la documentación oficial. Cada capítulo presenta una opinión del autor, trade-offs reales, y ejercicios que te obligan a ensuciarte las manos. El objetivo es que construyas criterio propio para tomar decisiones arquitectónicas informadas.

El libro progresa en tres niveles: Novato, Intermedio y Ninja. Cada parte construye sobre la anterior. Los capítulos puente te confirman que estás listo antes de saltar al siguiente nivel.

## ¿Es este libro para ti?

### Sí es para ti si...

- Sabes hacer requests HTTP con `curl` o `httpie` y entiendes qué es un status code.
- Puedes leer y escribir JSON sin ayuda de un generador visual.
- Navegas el sistema de archivos y ejecutas comandos en terminal sin fricción.
- Tienes experiencia general en desarrollo de software y quieres aprender OpenSearch desde cero.
- Eres ingeniero senior y necesitas dominar OpenSearch para diseñar arquitecturas de producción.
- Prefieres guías opinadas con trade-offs explícitos sobre documentación neutral que no toma partido.

### No es para ti si...

- Buscas un manual de referencia exhaustivo de cada endpoint de la API. Este libro no lo es.
- No te sientes cómodo ejecutando comandos en una terminal o levantando contenedores Docker.
- Necesitas un tutorial que explique qué es HTTP, qué es JSON, o cómo funciona un sistema de archivos.
- Prefieres contenido que evite opiniones y presente todas las opciones como igualmente válidas.
- Buscas cobertura de Elasticsearch. Este libro cubre exclusivamente OpenSearch.

## Qué es este libro

Una guía opinionada de aprendizaje progresivo. No es un manual de referencia de la API. No es una traducción de la documentación oficial.

Cada capítulo incluye una recomendación clara del autor sobre cuándo usar y cuándo evitar cada feature. Los trade-offs se presentan en al menos dos dimensiones: rendimiento, complejidad operativa, escalabilidad, o costo de mantenimiento.

El libro está escrito íntegramente en español. Los términos técnicos sin traducción consolidada se mantienen en inglés con definición en el glosario bilingüe del apéndice.

## Prerequisitos mínimos

Antes de empezar necesitas tres habilidades básicas:

1. **Requests HTTP** — Saber ejecutar `curl` o `httpie` contra un endpoint. Entender métodos GET, POST, PUT, DELETE y leer respuestas con status codes.
2. **JSON** — Leer y escribir documentos JSON. Entender objetos, arrays, tipos de datos, y anidar estructuras sin errores de sintaxis.
3. **Terminal** — Navegar el sistema de archivos, ejecutar scripts, y operar Docker Compose desde línea de comandos.

No se asume conocimiento previo de OpenSearch, Elasticsearch, ni Lucene. El libro cubre todo desde el primer índice hasta clústeres de producción con observabilidad y seguridad.

## Cómo usar este libro

El contenido está organizado en tres partes progresivas:

- **Parte I — Novato** (capítulos 1-5): Qué es OpenSearch, laboratorio local, CRUD, mappings.
- **Parte II — Intermedio** (capítulos 6-12): Query DSL avanzado, agregaciones, indexación, rendimiento, clientes.
- **Parte III — Ninja** (capítulos 13-18): Arquitectura de producción, seguridad, observabilidad, ML, SIEM.

Si nunca usaste OpenSearch, empieza por el capítulo 1. Si ya operas clústeres en producción, salta directo a la Parte III. El mapa de progresión te muestra las dependencias entre capítulos para que armes tu propia ruta.

Cada capítulo incluye un laboratorio Docker Compose reproducible. Los ejemplos de código viven en el directorio `code/` del repositorio y son ejecutables contra OpenSearch 2.17.0.

## Convenciones del libro

- Los bloques de código son ejecutables tal cual contra el laboratorio incluido.
- Las opiniones del autor aparecen en callouts destacados al inicio de cada capítulo.
- Las referencias a archivos del repositorio siguen el formato: 📁 `code/chNN/archivo.sh`.
- Los términos técnicos en inglés se definen en el glosario bilingüe del apéndice.
