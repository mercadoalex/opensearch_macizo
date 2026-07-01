"""Capítulo 11: Conexión y búsqueda con opensearch-py."""
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

print(f"\nResultados: {response['hits']['total']['value']}")
for hit in response["hits"]["hits"]:
    print(f"  {hit['_id']}: {hit['_source']['nombre']} - ${hit['_source']['precio']}")
