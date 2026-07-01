# ML y Búsqueda Vectorial

> **Opinión del autor:** La búsqueda vectorial con k-NN es el feature más transformador de OpenSearch en los últimos años. Combinar BM25 + vectores en una sola plataforma elimina la necesidad de un vector database separado para el 80% de los casos. Pero no todo necesita embeddings — si tus usuarios buscan por keywords exactos y están contentos, no compliques tu stack.

## Objetivo

Implementar búsqueda vectorial con k-NN, registrar modelos de embedding, configurar neural search plugins, y diseñar flujos de búsqueda híbrida (texto + semántica).

## Prerequisitos

- Capítulo 6: Query DSL avanzado (sección de búsqueda semántica)
- Laboratorio con perfil `ninja`

## Contenido

### k-NN: Fundamentos

k-Nearest Neighbors busca los K vectores más similares a un vector de consulta. OpenSearch soporta tres engines:

| Engine | Algoritmo | Trade-off |
|--------|-----------|-----------|
| Lucene | HNSW | Integrado, sin dependencias extra. Bueno hasta ~10M vectores |
| nmslib | HNSW | Alto rendimiento, más memoria. Para datasets grandes |
| Faiss | HNSW/IVF | Facebook Research. Soporta IVF para datasets masivos |

Recomendación: empieza con Lucene. Migra a Faiss solo si necesitas >50M vectores o IVF.

### Crear Índice k-NN

```bash
curl -sk -X PUT "https://localhost:9200/products-vectors" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "index.knn": true,
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "title": {"type": "text", "analyzer": "spanish"},
      "description": {"type": "text", "analyzer": "spanish"},
      "category": {"type": "keyword"},
      "embedding": {
        "type": "knn_vector",
        "dimension": 384,
        "method": {
          "name": "hnsw",
          "space_type": "cosinesimil",
          "engine": "lucene",
          "parameters": {"ef_construction": 128, "m": 16}
        }
      }
    }
  }
}'
```

Parámetros HNSW:
- `ef_construction`: calidad del grafo al indexar (128-512). Más alto = más preciso, más lento al indexar
- `m`: conexiones por nodo (16-64). Más alto = más preciso, más memoria
- `space_type`: `cosinesimil` (dirección), `l2` (distancia euclidiana), `linf` (Chebyshev)

> 📁 Código fuente: [`code/ch16/01-create-knn-index.sh`](../../code/ch16/01-create-knn-index.sh)

### Indexar Vectores

Los vectores vienen de un modelo de embedding (Sentence-BERT, OpenAI, etc.):

```bash
curl -sk -X POST "https://localhost:9200/products-vectors/_doc/1" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "title": "Laptop para desarrollo de software",
  "description": "Ideal para programadores y DevOps",
  "category": "laptops",
  "embedding": [0.12, -0.34, 0.56, ...]
}'
```

En producción, generas embeddings con un modelo antes de indexar. El pipeline típico:

```
Texto → Modelo embedding → Vector [dim] → OpenSearch k-NN index
```

### Búsqueda k-NN

```bash
curl -sk -X POST "https://localhost:9200/products-vectors/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "size": 5,
  "query": {
    "knn": {
      "embedding": {
        "vector": [0.11, -0.33, 0.55, ...],
        "k": 5
      }
    }
  }
}'
```

### Neural Search: Automatización de Embeddings

El plugin neural search automatiza la generación de embeddings. Registras un modelo y OpenSearch genera vectores automáticamente al indexar y buscar.

**Flujo:**

1. Registrar modelo ML en OpenSearch
2. Crear ingest pipeline con procesador `text_embedding`
3. Indexar documentos — el pipeline genera embeddings
4. Buscar con `neural` query — OpenSearch genera el vector de la query

```bash
# Neural query (OpenSearch genera el vector automáticamente)
curl -sk -X POST "https://localhost:9200/products-vectors/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "neural": {
      "embedding": {
        "query_text": "computadora para programar",
        "model_id": "model-id-registrado",
        "k": 10
      }
    }
  }
}'
```

> 📁 Código fuente: [`code/ch16/02-knn-search.sh`](../../code/ch16/02-knn-search.sh)

### Búsqueda Híbrida: BM25 + k-NN

El patrón más robusto combina ambos:

```bash
curl -sk -X POST "https://localhost:9200/products-vectors/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "should": [
        {"match": {"title": {"query": "laptop programación", "boost": 0.3}}},
        {"knn": {"embedding": {"vector": [0.11, -0.33, ...], "k": 10, "boost": 0.7}}}
      ]
    }
  }
}'
```

Ajusta boost según tu caso. Documentación técnica suele beneficiarse más de BM25 (keywords exactos). E-commerce y contenido creativo se benefician más de vectores (similitud conceptual).

## Cuándo Usar y Cuándo NO

| ✅ Usar búsqueda vectorial... | ❌ NO usar cuando... |
|---|---|
| Usuarios buscan por concepto, no por keywords exactos | El contenido es altamente estructurado (IDs, códigos) |
| Necesitas sinonimia implícita (coche ↔ automóvil) | BM25 ya da buenos resultados y los usuarios están satisfechos |
| Tienes un modelo de embedding entrenado/preentrenado | No puedes operar infraestructura ML (modelos, GPUs) |
| Quieres búsqueda multiidioma con un solo modelo | Dimensionalidad alta + volumen masivo sin hardware adecuado |

## Ejercicios

1. Crea un índice k-NN con vectores de dimensión 3 (para simplificar). Indexa 10 documentos con vectores manuales representando categorías. Busca los 3 más cercanos a un vector de query.

2. Implementa búsqueda híbrida que combine match en título con k-NN en embeddings. Experimenta con boost 0.2/0.8, 0.5/0.5 y 0.8/0.2. Documenta cómo cambia el ranking.

3. Genera embeddings reales usando `sentence-transformers/all-MiniLM-L6-v2` en Python. Indexa 20 frases y busca semánticamente.

## Resumen

- k-NN busca vectores similares usando HNSW (approximate nearest neighbors)
- Tres engines: Lucene (default), nmslib (high perf), Faiss (massive scale)
- Neural search automatiza embeddings: registro de modelo → ingest pipeline → query neural
- La búsqueda híbrida (BM25 + k-NN) captura coincidencias exactas Y conceptuales
- Parámetros HNSW: `ef_construction` y `m` controlan precisión vs velocidad
- Empieza con Lucene engine y migra a Faiss solo cuando el volumen lo justifique
