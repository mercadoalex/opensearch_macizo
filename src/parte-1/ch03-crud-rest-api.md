# CRUD con la REST API

> **Opinión del autor:** La REST API de OpenSearch es brutalmente simple. Cuatro verbos HTTP cubren el 90% de tus operaciones diarias. No necesitas un SDK para empezar — curl y JSON son suficientes. Domina la API REST antes de tocar cualquier cliente oficial; cuando algo falle en producción, vas a depurar con curl, no con abstracciones.

## Objetivo

Dominar las cuatro operaciones fundamentales contra OpenSearch: crear índices, indexar documentos, buscar, actualizar y eliminar. Cada operación con un ejemplo ejecutable y su respuesta esperada.

## Prerequisitos

- Capítulo 2: Laboratorio levantado con perfil `novato` y clúster respondiendo en `https://localhost:9200`
- Familiaridad básica con JSON y curl

## Contenido

### La REST API en 30 segundos

OpenSearch expone toda su funcionalidad a través de una REST API sobre HTTP. La convención es directa:

| Operación | Verbo HTTP | Endpoint |
|-----------|-----------|----------|
| Crear índice | `PUT` | `/<índice>` |
| Indexar documento | `PUT` / `POST` | `/<índice>/_doc/<id>` |
| Obtener documento | `GET` | `/<índice>/_doc/<id>` |
| Buscar | `GET` / `POST` | `/<índice>/_search` |
| Actualizar | `POST` | `/<índice>/_update/<id>` |
| Eliminar documento | `DELETE` | `/<índice>/_doc/<id>` |
| Eliminar índice | `DELETE` | `/<índice>` |

Todos los ejemplos de este capítulo usan curl con estas opciones base:

```bash
curl -sk https://localhost:9200 -u admin:Admin123!
```

El flag `-s` silencia la barra de progreso. El flag `-k` ignora el certificado TLS auto-firmado del laboratorio. En producción, nunca uses `-k`.

### Create: Crear un índice

Antes de indexar documentos, necesitas un índice. Puedes dejar que OpenSearch lo cree automáticamente (dynamic mapping), pero un mapping explícito te da control sobre los tipos de datos.

```bash
curl -sk -X PUT "https://localhost:9200/productos" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "nombre": { "type": "text" },
      "categoria": { "type": "keyword" },
      "precio": { "type": "float" },
      "en_stock": { "type": "boolean" },
      "fecha_agregado": { "type": "date" }
    }
  }
}'
```

Respuesta esperada:

```json
{
    "acknowledged": true,
    "shards_acknowledged": true,
    "index": "productos"
}
```

`acknowledged: true` confirma que el clúster aceptó la creación. Un shard, cero réplicas — configuración ideal para un laboratorio de un nodo. En producción usarías al menos una réplica.

> 📁 Código fuente: [`code/ch03/01-create-index.sh`](../../code/ch03/01-create-index.sh)

### Create: Indexar documentos

Con el índice creado, indexa tu primer documento. Tienes dos opciones: asignar un ID explícito con `PUT`, o dejar que OpenSearch genere uno con `POST`.

**Con ID explícito:**

```bash
curl -sk -X PUT "https://localhost:9200/productos/_doc/6" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "nombre": "Teclado mecánico RGB",
  "categoria": "perifericos",
  "precio": 89.99,
  "en_stock": true,
  "fecha_agregado": "2024-03-15"
}'
```

Respuesta esperada:

```json
{
    "_index": "productos",
    "_id": "6",
    "_version": 1,
    "result": "created",
    "_shards": {
        "total": 1,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 5,
    "_primary_term": 1
}
```

El campo `result: "created"` confirma que el documento es nuevo. Si envías el mismo request con el mismo ID, `result` cambia a `"updated"` y `_version` incrementa.

**Con ID auto-generado:**

```bash
curl -sk -X POST "https://localhost:9200/productos/_doc" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "nombre": "Webcam 4K con micrófono",
  "categoria": "perifericos",
  "precio": 129.50,
  "en_stock": false,
  "fecha_agregado": "2024-04-01"
}'
```

OpenSearch genera un ID único tipo `_id: "a1b2c3..."`. Usa IDs explícitos cuando tu aplicación necesita control de deduplicación. Usa IDs auto-generados para logs o eventos donde la unicidad no importa.

> 📁 Código fuente: [`code/ch03/02-index-document.sh`](../../code/ch03/02-index-document.sh)

#### Carga masiva con Bulk API

Para cargar múltiples documentos de golpe, la Bulk API es órdenes de magnitud más eficiente que indexar uno por uno. El formato es NDJSON: cada operación ocupa dos líneas (acción + documento).

```bash
curl -sk -X POST "https://localhost:9200/_bulk" \
  -u admin:Admin123! \
  -H "Content-Type: application/x-ndjson" \
  --data-binary "@code/ch03/sample-data.json"
```

Respuesta esperada (campos clave):

```json
{
    "took": 45,
    "errors": false,
    "items": [
        { "index": { "_id": "1", "result": "created", "status": 201 } },
        { "index": { "_id": "2", "result": "created", "status": 201 } }
    ]
}
```

El campo `errors: false` confirma que todos los documentos se indexaron correctamente. Si alguno falla, `errors` será `true` y el item correspondiente tendrá un campo `error` con detalles.

> 📁 Código fuente: [`code/ch03/load-data.sh`](../../code/ch03/load-data.sh)

### Read: Buscar documentos

Buscar es la razón de existir de OpenSearch. La forma más básica es `match_all`, que devuelve todos los documentos del índice:

```bash
curl -sk "https://localhost:9200/productos/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": { "match_all": {} }
}'
```

Respuesta esperada (estructura):

```json
{
    "took": 5,
    "timed_out": false,
    "hits": {
        "total": { "value": 5, "relation": "eq" },
        "max_score": 1.0,
        "hits": [
            {
                "_index": "productos",
                "_id": "1",
                "_score": 1.0,
                "_source": {
                    "nombre": "Laptop ThinkPad X1 Carbon",
                    "categoria": "laptops",
                    "precio": 1299.99,
                    "en_stock": true,
                    "fecha_agregado": "2024-01-15"
                }
            }
        ]
    }
}
```

La respuesta tiene tres niveles: metadatos (`took`, `timed_out`), totales (`hits.total`), y los documentos en `hits.hits[]`. El campo `_source` contiene el documento original tal como lo indexaste.

#### Búsqueda por texto (match)

Para buscar texto analizado, usa `match`. OpenSearch tokeniza tu query y busca coincidencias:

```bash
curl -sk "https://localhost:9200/productos/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "match": { "nombre": "monitor" }
  }
}'
```

`match` analiza el texto de búsqueda con el mismo analizador del campo. Encuentra "Monitor curvo 34 pulgadas" aunque la query sea "monitor" en minúsculas.

#### Búsqueda exacta (term)

Para campos `keyword` — donde necesitas coincidencia exacta — usa `term`:

```bash
curl -sk "https://localhost:9200/productos/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "term": { "categoria": "laptops" }
  }
}'
```

`term` no analiza la query. El valor debe coincidir exactamente con lo almacenado. Usa `term` para keywords, IDs, y enums. Usa `match` para texto libre.

#### Búsqueda por rango

Para campos numéricos o de fecha, `range` filtra por intervalos:

```bash
curl -sk "https://localhost:9200/productos/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "range": {
      "precio": { "gte": 500, "lte": 1500 }
    }
  }
}'
```

Operadores disponibles: `gt` (mayor que), `gte` (mayor o igual), `lt` (menor que), `lte` (menor o igual). Funcionan con números, fechas y strings.

> 📁 Código fuente: [`code/ch03/03-search.sh`](../../code/ch03/03-search.sh)

### Update: Actualizar documentos

OpenSearch no actualiza documentos in-place. Internamente, marca el documento viejo como eliminado y crea uno nuevo. Pero la API de Update te abstrae de eso.

#### Actualización parcial

Envía solo los campos que cambian:

```bash
curl -sk -X POST "https://localhost:9200/productos/_update/1" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "doc": {
    "precio": 1149.99,
    "en_stock": false
  }
}'
```

Respuesta esperada:

```json
{
    "_index": "productos",
    "_id": "1",
    "_version": 2,
    "result": "updated",
    "_shards": {
        "total": 1,
        "successful": 1,
        "failed": 0
    }
}
```

`_version: 2` confirma que el documento se actualizó. Si envías el mismo update sin cambios, `result` será `"noop"` — OpenSearch detecta que no hay diferencia y evita reindexar.

#### Actualización con script

Para lógica más compleja, usa Painless — el lenguaje de scripting de OpenSearch:

```bash
curl -sk -X POST "https://localhost:9200/productos/_update/2" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "script": {
    "source": "ctx._source.precio = ctx._source.precio * 1.10",
    "lang": "painless"
  }
}'
```

Este script incrementa el precio en 10%. `ctx._source` accede al documento completo. Painless es un lenguaje seguro con sintaxis similar a Java — el Capítulo 9 profundiza en su uso dentro de ingest pipelines.

> 📁 Código fuente: [`code/ch03/04-update.sh`](../../code/ch03/04-update.sh)

### Delete: Eliminar documentos

#### Eliminar un documento específico

```bash
curl -sk -X DELETE "https://localhost:9200/productos/_doc/6" \
  -u admin:Admin123!
```

Respuesta esperada:

```json
{
    "_index": "productos",
    "_id": "6",
    "_version": 2,
    "result": "deleted",
    "_shards": {
        "total": 1,
        "successful": 1,
        "failed": 0
    }
}
```

`result: "deleted"` confirma la eliminación. Si intentas eliminar un documento que no existe, recibes `result: "not_found"` con HTTP 404.

#### Verificar eliminación

```bash
curl -sk "https://localhost:9200/productos/_doc/6" \
  -u admin:Admin123!
```

Respuesta:

```json
{
    "_index": "productos",
    "_id": "6",
    "found": false
}
```

#### Eliminar un índice completo

Para eliminar un índice con todos sus documentos, settings y mappings:

```bash
curl -sk -X DELETE "https://localhost:9200/productos" \
  -u admin:Admin123!
```

Respuesta:

```json
{
    "acknowledged": true
}
```

Esta operación es irreversible. No hay papelera de reciclaje. En producción, protege índices críticos con `index.blocks.read_only` o usa aliases para evitar borrados accidentales.

> 📁 Código fuente: [`code/ch03/05-delete.sh`](../../code/ch03/05-delete.sh)

### Obtener un documento por ID

Además de buscar, puedes obtener un documento directamente si conoces su ID:

```bash
curl -sk "https://localhost:9200/productos/_doc/1" \
  -u admin:Admin123!
```

Respuesta:

```json
{
    "_index": "productos",
    "_id": "1",
    "_version": 1,
    "_source": {
        "nombre": "Laptop ThinkPad X1 Carbon",
        "categoria": "laptops",
        "precio": 1299.99,
        "en_stock": true,
        "fecha_agregado": "2024-01-15"
    },
    "found": true
}
```

`GET _doc/<id>` es O(1) — va directo al shard que contiene el documento. Es más eficiente que una búsqueda cuando conoces el ID exacto.

## Cuándo Usar y Cuándo NO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|---|---|
| Necesitas indexar documentos JSON semi-estructurados | Tus datos son puramente relacionales con JOINs complejos |
| Requieres búsqueda full-text con relevancia | Solo necesitas key-value lookup (usa Redis) |
| Quieres búsquedas por rango en fechas o números | Tu volumen es < 1000 docs y no necesitas búsqueda (usa un archivo JSON) |
| Necesitas cargar datos masivos con Bulk API | Tus documentos cambian cada segundo (alta tasa de updates) |

## Ejercicios

1. Crea un índice `libros` con campos: `titulo` (text), `autor` (keyword), `paginas` (integer), `publicado` (date). Indexa 3 documentos con datos reales.

2. Usa la Bulk API para cargar los 5 productos del archivo `sample-data.json`. Verifica con `_count` que se cargaron correctamente.

3. Busca todos los productos con precio mayor a 100. Luego busca los que contengan "inalámbrico" en el nombre. Compara el `_score` de los resultados.

4. Actualiza el precio de un producto usando un script Painless que aplique un descuento del 15%. Verifica el resultado con un GET por ID.

5. Elimina un documento y luego intenta buscarlo con GET. Observa la diferencia entre HTTP 404 y `found: false`.

## Resumen

- La REST API usa verbos HTTP estándar: PUT para crear, GET para leer, POST para actualizar, DELETE para eliminar
- `match` busca texto analizado; `term` busca valores exactos en keywords; `range` filtra por intervalos
- La Bulk API (`_bulk`) carga múltiples documentos en un solo request — siempre preferible a indexar uno por uno
- Los updates son internamente un delete + reindex; usa `doc` para parciales y `script` para lógica compleja
- `GET _doc/<id>` es O(1) y más eficiente que `_search` cuando conoces el ID exacto
- Eliminar un índice es irreversible — protege índices de producción con blocks o aliases
