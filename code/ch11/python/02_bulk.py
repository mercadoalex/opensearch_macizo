"""Capítulo 11: Bulk indexing con helpers."""
from opensearchpy import OpenSearch, helpers

client = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "Admin123!"),
    use_ssl=True,
    verify_certs=False,
    ssl_show_warn=False,
)


def generate_actions():
    """Generador de documentos para bulk indexing."""
    for i in range(1000):
        yield {
            "_index": "metrics-python",
            "_source": {
                "metric_name": "cpu_usage",
                "value": 45.0 + (i % 50),
                "host": f"server-{i % 10}",
                "@timestamp": f"2024-03-15T{i % 24:02d}:00:00Z",
            },
        }


# Bulk index con reintentos
success, errors = helpers.bulk(
    client,
    generate_actions(),
    chunk_size=200,
    max_retries=3,
    raise_on_error=False,
)

print(f"Indexados: {success}")
if errors:
    print(f"Errores: {len(errors)}")
    for err in errors[:5]:
        print(f"  {err}")
