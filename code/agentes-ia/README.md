# Apéndice: OpenSearch como Backend de Agentes IA

Ejemplos de RAG, tools para agentes, y memoria conversacional con OpenSearch.

## Prerequisitos

- Laboratorio levantado con perfil `novato`
- Python 3.9+

## Instalación

```bash
pip install opensearch-py sentence-transformers boto3
```

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `01-rag-opensearch.py` | RAG completo: indexar embeddings + búsqueda híbrida |
| `02-tools.py` | OpenSearch como tool para frameworks de agentes |

## Ejecución

```bash
python code/agentes-ia/01-rag-opensearch.py
python code/agentes-ia/02-tools.py
```

## Modelo de Embedding

Los ejemplos usan `all-MiniLM-L6-v2` (384 dimensiones). Se descarga automáticamente
la primera vez (~80 MB). Para producción, evalúa modelos multilingüe como
`paraphrase-multilingual-MiniLM-L12-v2` para mejor soporte de español.
