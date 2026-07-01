# Clientes Oficiales

> **Opinión del autor:** Curl es perfecto para aprender y depurar. Pero en producción nadie hace requests HTTP a mano. Los clientes oficiales te dan type safety, connection pooling, retry automático y serialización. Elige uno y domínalo. Mi recomendación: Python para scripts y data pipelines, Go para servicios de alto rendimiento, Java si tu stack ya es JVM.

## Objetivo

Integrar OpenSearch en aplicaciones reales usando los clientes oficiales de Python, Java y Go. Aprender patrones de producción: bulk indexing, search con paginación, y manejo de errores.

## Prerequisitos

- Capítulo 5: Puente novato-intermedio (operaciones CRUD sólidas)
- Laboratorio levantado con perfil `novato`

## Contenido

### Python: opensearch-py

El cliente Python es ideal para scripts, notebooks, y data pipelines. Se instala con pip:

```bash
pip install opensearch-py==2.4.2
```

#### Patrón 1: Conexión y búsqueda básica

```python
from opensearchpy import OpenSearch

client = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "Admin123!"),
    use_ssl=True,
    verify_certs=False,
    ssl_show_warn=False,
)

# Verificar conexión
info = client.info()
print(f"Cluster: {info['cluster_name']}, version: {info['version']['number']}")

# Búsqueda
response = client.search(
    index="productos",
    body={
        "query": {"match": {"nombre": "laptop"}},
        "size": 5,
    },
)

for hit in response["hits"]["hits"]:
    print(f"  {hit['_id']}: {hit['_source']['nombre']} - ${hit['_source']['precio']}")
```

#### Patrón 2: Bulk indexing con helpers

Para cargas masivas, el helper `bulk` gestiona batches y reintentos:

```python
from opensearchpy import OpenSearch, helpers

client = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "Admin123!"),
    use_ssl=True,
    verify_certs=False,
)

def generate_actions():
    """Generador que produce documentos para bulk."""
    for i in range(1000):
        yield {
            "_index": "metrics",
            "_source": {
                "metric_name": "cpu_usage",
                "value": 45.0 + (i % 50),
                "host": f"server-{i % 10}",
                "@timestamp": f"2024-03-15T{i % 24:02d}:00:00Z",
            },
        }

success, errors = helpers.bulk(
    client,
    generate_actions(),
    chunk_size=200,
    max_retries=3,
    raise_on_error=False,
)
print(f"Indexados: {success}, errores: {len(errors)}")
```

El generador evita cargar todos los documentos en memoria. `chunk_size` controla cuántos documentos envía por batch. `raise_on_error=False` permite continuar si un documento falla.

> 📁 Código fuente: [`code/ch11/python/01_search.py`](../../code/ch11/python/01_search.py)

> 📁 Código fuente: [`code/ch11/python/02_bulk.py`](../../code/ch11/python/02_bulk.py)

### Go: opensearch-go

El cliente Go ofrece alto rendimiento con tipado fuerte. Ideal para servicios que necesitan baja latencia.

```go
package main

import (
    "context"
    "crypto/tls"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "strings"

    opensearch "github.com/opensearch-project/opensearch-go/v2"
    opensearchapi "github.com/opensearch-project/opensearch-go/v2/opensearchapi"
)

func main() {
    client, err := opensearch.NewClient(opensearch.Config{
        Addresses: []string{"https://localhost:9200"},
        Username:  "admin",
        Password:  "Admin123!",
        Transport: &http.Transport{
            TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
        },
    })
    if err != nil {
        log.Fatalf("Error creating client: %s", err)
    }

    // Búsqueda
    query := `{"query": {"match": {"nombre": "laptop"}}}`
    res, err := client.Search(
        client.Search.WithContext(context.Background()),
        client.Search.WithIndex("productos"),
        client.Search.WithBody(strings.NewReader(query)),
    )
    if err != nil {
        log.Fatalf("Search error: %s", err)
    }
    defer res.Body.Close()

    var result map[string]interface{}
    json.NewDecoder(res.Body).Decode(&result)
    fmt.Printf("Hits: %v\n", result["hits"].(map[string]interface{})["total"])
}
```

#### Patrón: Bulk con opensearchutil

```go
indexer, _ := opensearchutil.NewBulkIndexer(opensearchutil.BulkIndexerConfig{
    Client:     client,
    Index:      "metrics",
    NumWorkers: 4,
    FlushBytes: 5e6,  // 5MB per batch
})

for i := 0; i < 10000; i++ {
    doc := fmt.Sprintf(`{"metric":"cpu","value":%d,"host":"srv-%d"}`, 45+i%50, i%10)
    indexer.Add(context.Background(), opensearchutil.BulkIndexerItem{
        Action: "index",
        Body:   strings.NewReader(doc),
    })
}
indexer.Close(context.Background())
stats := indexer.Stats()
fmt.Printf("Indexed: %d, Failed: %d\n", stats.NumFlushed, stats.NumFailed)
```

> 📁 Código fuente: [`code/ch11/go/main.go`](../../code/ch11/go/main.go)

### Java: opensearch-java

El cliente Java con el builder pattern. Tipado fuerte y completamente asíncrono.

```java
import org.opensearch.client.opensearch.OpenSearchClient;
import org.opensearch.client.opensearch.core.SearchResponse;
import org.opensearch.client.opensearch.core.search.Hit;

// Búsqueda tipada
SearchResponse<Product> response = client.search(s -> s
    .index("productos")
    .query(q -> q
        .match(m -> m
            .field("nombre")
            .query("laptop")
        )
    ),
    Product.class
);

for (Hit<Product> hit : response.hits().hits()) {
    Product p = hit.source();
    System.out.printf("%s: $%.2f%n", p.nombre(), p.precio());
}
```

El cliente Java deserializa directamente a POJOs. No necesitas parsear JSON manualmente.

> 📁 Código fuente: [`code/ch11/java/SearchExample.java`](../../code/ch11/java/SearchExample.java)

### Comparación de Clientes

| Aspecto | Python | Go | Java |
|---------|--------|-----|------|
| Setup | `pip install` | `go get` | Maven/Gradle |
| Tipado | Dinámico | Estático | Estático |
| Async | asyncio opcional | goroutines nativo | CompletableFuture |
| Bulk helper | `helpers.bulk()` | `BulkIndexer` | `BulkRequest.Builder` |
| Ideal para | Scripts, ML, notebooks | Microservicios | Aplicaciones enterprise |
| Latencia | Media | Baja | Media-Baja |

## Cuándo Usar y Cuándo NO

| ✅ Usar cliente oficial cuando... | ❌ NO usar cuando... |
|---|---|
| Tu aplicación necesita connection pooling y retry | Scripts de un solo uso (curl basta) |
| Indexas datos masivos (bulk es 10x más eficiente) | Exploración interactiva (usa Dev Tools) |
| Necesitas type safety y serialización automática | Tu lenguaje no tiene cliente oficial (usa HTTP directo) |
| Manejas errores y reintentos programáticamente | El overhead de una dependencia no se justifica |

## Ejercicios

1. Escribe un script Python que conecte al laboratorio, cree un índice `test-python`, indexe 100 documentos con bulk, y busque los que tengan un campo valor > 50. Mide el tiempo total.

2. Implementa en Go un servicio que exponga un endpoint HTTP `/search?q=texto` que busque en el índice `productos` y devuelva resultados como JSON.

3. Compara el rendimiento de indexar 1000 documentos: (a) uno por uno con curl en un loop, (b) con bulk API via curl, (c) con el bulk helper de Python. Documenta la diferencia en tiempo.

4. Implementa manejo de errores en Python: usa `raise_on_error=False` en bulk y loguea los documentos que fallaron con su razón de error.

## Resumen

- **Python** (opensearch-py): ideal para scripts y data pipelines con `helpers.bulk()` para cargas masivas
- **Go** (opensearch-go): alto rendimiento con `BulkIndexer` concurrent para microservicios
- **Java** (opensearch-java): tipado fuerte con builder pattern, deserialización automática a POJOs
- El bulk indexing es 10-100x más eficiente que indexar documentos individualmente
- Connection pooling y retry automático vienen incluidos — no reimplementes esto con HTTP crudo
- Todos los clientes soportan TLS, autenticación, y connection sniffing
