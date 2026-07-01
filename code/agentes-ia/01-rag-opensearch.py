"""
Apéndice Agentes IA: RAG completo con OpenSearch como vector store.
Requiere: pip install opensearch-py sentence-transformers boto3
"""
from opensearchpy import OpenSearch
from sentence_transformers import SentenceTransformer
import json

# --- Configuración ---
client = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "Admin123!"),
    use_ssl=True, verify_certs=False, ssl_show_warn=False,
)
model = SentenceTransformer("all-MiniLM-L6-v2")

INDEX = "knowledge-base"

# --- Crear índice k-NN ---
if not client.indices.exists(INDEX):
    client.indices.create(INDEX, body={
        "settings": {"index.knn": True, "number_of_shards": 1, "number_of_replicas": 0},
        "mappings": {
            "properties": {
                "text": {"type": "text", "analyzer": "spanish"},
                "embedding": {
                    "type": "knn_vector", "dimension": 384,
                    "method": {"name": "hnsw", "space_type": "cosinesimil", "engine": "lucene"}
                },
                "source": {"type": "keyword"},
                "category": {"type": "keyword"},
            }
        }
    })
    print(f"Índice '{INDEX}' creado.")

# --- Indexar conocimiento ---
docs = [
    ("OpenSearch soporta búsqueda vectorial con k-NN usando engines Lucene, nmslib y Faiss.", "features"),
    ("ISM permite automatizar el ciclo de vida de índices con políticas hot-warm-delete.", "operations"),
    ("Data Prepper es el pipeline para ingesta de datos OTEL en OpenSearch.", "observability"),
    ("El Security Plugin incluye RBAC, DLS, FLS y audit logging sin costo adicional.", "security"),
    ("Los agentes de IA pueden usar OpenSearch como tool para RAG y analytics.", "ai"),
]

for i, (text, category) in enumerate(docs):
    embedding = model.encode(text).tolist()
    client.index(INDEX, body={
        "text": text, "embedding": embedding,
        "source": "opensearch-macizo", "category": category,
    }, id=str(i))

print(f"{len(docs)} documentos indexados.")


# --- Retrieval ---
def retrieve(query: str, k: int = 3) -> list[str]:
    """Búsqueda híbrida: k-NN + BM25."""
    query_vec = model.encode(query).tolist()
    body = {
        "size": k,
        "query": {"bool": {"should": [
            {"knn": {"embedding": {"vector": query_vec, "k": k, "boost": 0.7}}},
            {"match": {"text": {"query": query, "boost": 0.3}}}
        ]}}
    }
    resp = client.search(index=INDEX, body=body)
    return [hit["_source"]["text"] for hit in resp["hits"]["hits"]]


# --- Demo ---
if __name__ == "__main__":
    query = "¿Cómo automatizo el ciclo de vida de índices?"
    results = retrieve(query)
    print(f"\nQuery: {query}")
    print(f"Contexto recuperado ({len(results)} docs):")
    for r in results:
        print(f"  → {r}")
