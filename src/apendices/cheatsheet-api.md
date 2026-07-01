# Cheatsheet REST API

Referencia rápida de los endpoints más usados de OpenSearch. Todos los ejemplos asumen:

```bash
BASE="https://localhost:9200"
AUTH="-u admin:Admin123!"
```

## Cluster y Nodos

| Método | Endpoint | Descripción | Ejemplo |
|--------|----------|-------------|---------|
| GET | `_cluster/health` | Estado del clúster (green/yellow/red) | `curl -sk $BASE/_cluster/health $AUTH` |
| GET | `_cat/nodes?v` | Lista de nodos con métricas | `curl -sk $BASE/_cat/nodes?v $AUTH` |
| GET | `_cat/indices?v` | Lista de índices con estado y tamaño | `curl -sk $BASE/_cat/indices?v&s=store.size:desc $AUTH` |
| GET | `_cat/shards?v` | Distribución de shards entre nodos | `curl -sk $BASE/_cat/shards?v&s=store:desc $AUTH` |
| GET | `_cat/allocation?v` | Uso de disco por nodo | `curl -sk $BASE/_cat/allocation?v $AUTH` |
| GET | `_nodes/stats` | Estadísticas detalladas de nodos | `curl -sk $BASE/_nodes/stats/jvm,os $AUTH` |

## Índices

| Método | Endpoint | Descripción | Ejemplo |
|--------|----------|-------------|---------|
| PUT | `/<index>` | Crear índice con settings y mappings | `curl -sk -X PUT $BASE/mi-indice $AUTH -H "Content-Type: application/json" -d '{"settings":{"number_of_shards":1}}'` |
| DELETE | `/<index>` | Eliminar índice (irreversible) | `curl -sk -X DELETE $BASE/mi-indice $AUTH` |
| GET | `/<index>/_mapping` | Ver mapping del índice | `curl -sk $BASE/mi-indice/_mapping $AUTH` |
| GET | `/<index>/_settings` | Ver settings del índice | `curl -sk $BASE/mi-indice/_settings $AUTH` |
| GET | `/<index>/_count` | Contar documentos | `curl -sk $BASE/mi-indice/_count $AUTH` |

## Documentos

| Método | Endpoint | Descripción | Ejemplo |
|--------|----------|-------------|---------|
| POST | `/<index>/_doc` | Indexar documento (ID auto) | `curl -sk -X POST $BASE/mi-indice/_doc $AUTH -H "Content-Type: application/json" -d '{"campo":"valor"}'` |
| PUT | `/<index>/_doc/<id>` | Indexar documento (ID explícito) | `curl -sk -X PUT $BASE/mi-indice/_doc/1 $AUTH -H "Content-Type: application/json" -d '{"campo":"valor"}'` |
| GET | `/<index>/_doc/<id>` | Obtener documento por ID | `curl -sk $BASE/mi-indice/_doc/1 $AUTH` |
| POST | `/<index>/_update/<id>` | Actualizar documento parcialmente | `curl -sk -X POST $BASE/mi-indice/_update/1 $AUTH -H "Content-Type: application/json" -d '{"doc":{"campo":"nuevo"}}'` |
| DELETE | `/<index>/_doc/<id>` | Eliminar documento | `curl -sk -X DELETE $BASE/mi-indice/_doc/1 $AUTH` |
| POST | `/_bulk` | Operaciones masivas (NDJSON) | `curl -sk -X POST $BASE/_bulk $AUTH -H "Content-Type: application/x-ndjson" --data-binary @data.json` |

## Búsqueda

| Método | Endpoint | Descripción | Ejemplo |
|--------|----------|-------------|---------|
| GET/POST | `/<index>/_search` | Buscar documentos | `curl -sk $BASE/mi-indice/_search $AUTH -H "Content-Type: application/json" -d '{"query":{"match_all":{}}}'` |
| POST | `/_analyze` | Probar tokenización | `curl -sk -X POST $BASE/_analyze $AUTH -H "Content-Type: application/json" -d '{"analyzer":"spanish","text":"servidores rápidos"}'` |
| POST | `/_reindex` | Copiar documentos entre índices | `curl -sk -X POST $BASE/_reindex $AUTH -H "Content-Type: application/json" -d '{"source":{"index":"v1"},"dest":{"index":"v2"}}'` |

## Pipelines y Snapshots

| Método | Endpoint | Descripción | Ejemplo |
|--------|----------|-------------|---------|
| PUT | `/_ingest/pipeline/<id>` | Crear ingest pipeline | `curl -sk -X PUT $BASE/_ingest/pipeline/mi-pipe $AUTH -H "Content-Type: application/json" -d '{"processors":[...]}'` |
| POST | `/_ingest/pipeline/<id>/_simulate` | Probar pipeline | `curl -sk -X POST $BASE/_ingest/pipeline/mi-pipe/_simulate $AUTH -d '{"docs":[...]}'` |
| PUT | `/_snapshot/<repo>/<snap>` | Crear snapshot | `curl -sk -X PUT "$BASE/_snapshot/backups/snap-1?wait_for_completion=true" $AUTH` |
| POST | `/_snapshot/<repo>/<snap>/_restore` | Restaurar snapshot | `curl -sk -X POST $BASE/_snapshot/backups/snap-1/_restore $AUTH` |
