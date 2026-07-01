# Glosario Bilingüe

Términos técnicos ordenados alfabéticamente. Cada entrada incluye el término en inglés y su definición en español.

| Término (EN) | Definición (ES) |
|-------------|----------------|
| **Aggregation** | Operación que calcula métricas o agrupa documentos. Equivale a GROUP BY + funciones de agregación en SQL. |
| **Alias** | Nombre alternativo para uno o más índices. Permite desacoplar aplicaciones de la estructura física. |
| **Analyzer** | Componente que transforma texto en tokens indexables. Combina character filters, tokenizer y token filters. |
| **Bool query** | Query que combina condiciones con must, filter, should y must_not. La más usada en producción. |
| **Bucket** | Agrupación de documentos generada por una bucket aggregation (terms, date_histogram, range). |
| **Bulk API** | Endpoint `_bulk` para indexar múltiples documentos en un solo request. 10-100x más eficiente que indexar uno por uno. |
| **Circuit breaker** | Mecanismo que rechaza operaciones que excederían la memoria disponible para prevenir OOM. |
| **Cluster** | Conjunto de nodos OpenSearch que trabajan juntos. Comparten nombre de clúster y cluster state. |
| **Cluster manager** | Nodo responsable de gestionar el cluster state, asignar shards y coordinar operaciones de clúster. |
| **Composite aggregation** | Agregación que permite paginar eficientemente sobre todas las combinaciones de múltiples campos. |
| **Coordinating node** | Nodo sin roles que distribuye requests a los shards relevantes y agrega resultados. |
| **Cross-cluster replication (CCR)** | Replicación de índices entre clústeres independientes para DR o lecturas locales. |
| **Data node** | Nodo que almacena datos en shards y ejecuta operaciones de búsqueda y agregación. |
| **Data Prepper** | Pipeline de datos open-source optimizado para transformar datos OTEL al formato OpenSearch. |
| **Date histogram** | Bucket aggregation que agrupa documentos por intervalos de tiempo (día, semana, mes). |
| **Decay function** | Función en function_score que reduce el score según distancia a un valor de referencia (temporal, geográfica). |
| **Discovery** | Proceso por el cual los nodos se encuentran entre sí para formar un clúster. |
| **Dissect** | Procesador de ingest pipelines que parsea texto por delimitadores fijos. Más rápido que grok. |
| **Document** | Unidad de datos en OpenSearch. Un JSON almacenado en un índice con un `_id` único. |
| **Embedding** | Representación vectorial de texto donde la cercanía geométrica refleja similitud semántica. |
| **Field data** | Cache en memoria para valores de campo usados en sorting/aggregations sobre campos text. Costoso en RAM. |
| **Filter context** | Contexto de ejecución donde una query no calcula score. Los resultados se cachean automáticamente. |
| **Function score** | Query que permite manipular el score de relevancia usando funciones matemáticas. |
| **Grok** | Procesador de ingest pipelines que extrae campos de texto usando patrones regex con nombres. |
| **Healthcheck** | Verificación del estado del clúster vía `_cluster/health`. Estados: green, yellow, red. |
| **HNSW** | Hierarchical Navigable Small World. Algoritmo de búsqueda aproximada de vecinos más cercanos. |
| **Index** | Colección lógica de documentos con un mapping definido. Distribuido en shards entre nodos. |
| **Index template** | Configuración automática (settings, mappings, aliases) aplicada a índices nuevos que matcheen un patrón. |
| **Ingest pipeline** | Secuencia de procesadores que transforma documentos antes de indexarlos. |
| **ISM (Index State Management)** | Sistema de políticas para automatizar el ciclo de vida de índices (hot → warm → delete). |
| **k-NN** | k-Nearest Neighbors. Búsqueda de los K vectores más similares a un vector de consulta. |
| **Lucene** | Motor de búsqueda en Java subyacente a OpenSearch. Cada shard es una instancia de Lucene. |
| **Mapping** | Definición de la estructura de un índice: campos, tipos de datos y configuración de análisis. |
| **Match query** | Query que analiza el texto de búsqueda y busca coincidencias en campos text. |
| **Multi-match** | Query que busca el mismo término en múltiples campos con control de boost y combinación de scores. |
| **Nested** | Tipo de mapping que almacena objetos de un array como documentos Lucene independientes. |
| **Node** | Una instancia de OpenSearch ejecutándose. Puede tener uno o más roles (data, cluster_manager, etc.). |
| **OTEL (OpenTelemetry)** | Estándar open-source para instrumentación, generación y exportación de datos de telemetría. |
| **Pipeline** | Ver "Ingest pipeline". |
| **Primary shard** | Shard que recibe las escrituras originales. Cada índice tiene al menos un shard primario. |
| **Query cache** | Cache a nivel de nodo que almacena resultados de cláusulas filter para reutilización. |
| **Query DSL** | Domain Specific Language de OpenSearch para construir queries en formato JSON. |
| **Range query** | Query que filtra documentos por intervalos numéricos o de fecha (gt, gte, lt, lte). |
| **Replica** | Copia de un shard primario. Provee alta disponibilidad y distribuye carga de lectura. |
| **Rollover** | Operación que crea un nuevo índice y mueve el alias de escritura cuando se cumplen condiciones. |
| **Routing** | Mecanismo que determina en qué shard se almacena un documento. Custom routing dirige queries a un shard. |
| **Script** | Código Painless ejecutado en queries, aggregations o ingest pipelines para lógica custom. |
| **Shard** | Fragmento de un índice. Una instancia de Lucene. Los shards se distribuyen entre nodos. |
| **SIEM** | Security Information and Event Management. Sistema de detección y respuesta a amenazas. |
| **Sigma** | Formato estándar open-source para describir reglas de detección de amenazas. |
| **Slow log** | Log que registra queries u operaciones de indexación que exceden un umbral de latencia. |
| **Snapshot** | Backup point-in-time de uno o más índices. Se almacena en un repository externo (S3, filesystem). |
| **Span** | Unidad de trabajo en un trace distribuido. Tiene inicio, fin, atributos y parent span. |
| **Stemming** | Reducción de palabras a su raíz. "servidores" → "servidor". Mejora recall en búsquedas. |
| **Term query** | Query que busca coincidencia exacta en campos keyword. No analiza el texto de búsqueda. |
| **Terms aggregation** | Bucket aggregation que agrupa documentos por los valores de un campo keyword. |
| **Tokenizer** | Componente del analyzer que divide texto en tokens individuales (palabras). |
| **Trace** | Registro del flujo completo de un request a través de múltiples servicios. Compuesto por spans. |
| **Vector search** | Búsqueda basada en similitud de vectores numéricos (embeddings) en vez de coincidencia textual. |
