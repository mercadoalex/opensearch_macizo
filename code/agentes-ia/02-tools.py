"""
Apéndice Agentes IA: OpenSearch como Tool para frameworks de agentes.
Define tools que un LLM puede invocar para buscar y analizar datos.
"""
from opensearchpy import OpenSearch
from sentence_transformers import SentenceTransformer

client = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "Admin123!"),
    use_ssl=True, verify_certs=False, ssl_show_warn=False,
)
model = SentenceTransformer("all-MiniLM-L6-v2")


# --- Tool 1: Búsqueda semántica ---
def opensearch_search_tool(query: str, index: str = "knowledge-base", k: int = 3) -> str:
    """Busca información relevante en la base de conocimiento.

    Args:
        query: Texto de búsqueda en lenguaje natural.
        index: Índice OpenSearch donde buscar.
        k: Cantidad de resultados a retornar.

    Returns:
        Documentos relevantes separados por ---
    """
    query_vec = model.encode(query).tolist()
    body = {
        "size": k,
        "query": {"bool": {"should": [
            {"knn": {"embedding": {"vector": query_vec, "k": k, "boost": 0.7}}},
            {"match": {"text": {"query": query, "boost": 0.3}}}
        ]}}
    }
    resp = client.search(index=index, body=body)
    results = [hit["_source"]["text"] for hit in resp["hits"]["hits"]]
    return "\n---\n".join(results) if results else "No se encontraron resultados."


# --- Tool 2: Analytics ---
def opensearch_analytics_tool(index: str, field: str, metric: str = "avg") -> str:
    """Ejecuta una agregación sobre un índice OpenSearch.

    Args:
        index: Índice sobre el cual agregar.
        field: Campo numérico para la métrica.
        metric: Tipo (avg, sum, min, max, stats).

    Returns:
        Resultado de la agregación como texto.
    """
    body = {"size": 0, "aggs": {"result": {metric: {"field": field}}}}
    resp = client.search(index=index, body=body)
    value = resp["aggregations"]["result"]
    if isinstance(value, dict) and "value" in value:
        return f"{metric}({field}) en '{index}' = {value['value']}"
    return f"{metric}({field}) en '{index}' = {json.dumps(value)}"


# --- Tool 3: Logs search (observabilidad) ---
def opensearch_logs_tool(service: str, level: str = "error", timeframe: str = "1h") -> str:
    """Busca logs recientes de un servicio.

    Args:
        service: Nombre del servicio.
        level: Nivel de severidad (error, warn, info).
        timeframe: Ventana de tiempo (1h, 6h, 24h).

    Returns:
        Últimos mensajes de log del servicio.
    """
    body = {
        "size": 10,
        "query": {"bool": {"filter": [
            {"term": {"service": service}},
            {"term": {"level": level}},
            {"range": {"@timestamp": {"gte": f"now-{timeframe}"}}}
        ]}},
        "sort": [{"@timestamp": "desc"}]
    }
    resp = client.search(index="otel-logs-*", body=body)
    messages = [hit["_source"].get("message", "sin mensaje") for hit in resp["hits"]["hits"]]
    if not messages:
        return f"No se encontraron logs {level} para '{service}' en las últimas {timeframe}."
    return "\n".join(f"[{level.upper()}] {msg}" for msg in messages)


# --- Demo ---
if __name__ == "__main__":
    import json

    print("=== Tool: Search ===")
    print(opensearch_search_tool("seguridad y permisos"))
    print()
    print("=== Tool: Analytics ===")
    print(opensearch_analytics_tool("ventas", "precio", "avg"))
