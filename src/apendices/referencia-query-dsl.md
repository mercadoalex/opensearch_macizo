# Referencia Rápida del Query DSL

11 patrones de consulta con caso de uso y ejemplo ejecutable.

---

## 1. match — Búsqueda full-text

**Caso de uso:** Buscar texto libre en campos analizados (descripción, nombre, contenido).

```json
{"query": {"match": {"nombre": "laptop gaming"}}}
```

---

## 2. term — Coincidencia exacta

**Caso de uso:** Filtrar por valores keyword exactos (categoría, estado, ID).

```json
{"query": {"term": {"categoria": "laptops"}}}
```

---

## 3. range — Intervalos numéricos/fecha

**Caso de uso:** Filtrar productos por precio o logs por rango de fecha.

```json
{"query": {"range": {"precio": {"gte": 100, "lte": 500}}}}
```

---

## 4. bool — Combinar condiciones

**Caso de uso:** Búsqueda con filtros, exclusiones y boost por relevancia.

```json
{"query": {"bool": {
  "must": [{"match": {"contenido": "OpenSearch"}}],
  "filter": [{"term": {"categoria": "tutorial"}}],
  "must_not": [{"term": {"status": "draft"}}],
  "should": [{"range": {"valoracion": {"gte": 4.5}}}]
}}}
```

---

## 5. nested — Objetos anidados

**Caso de uso:** Consultar campos correlacionados dentro de un array de objetos.

```json
{"query": {"nested": {
  "path": "comentarios",
  "query": {"bool": {"must": [
    {"term": {"comentarios.usuario": "pedro"}},
    {"match": {"comentarios.texto": "producción"}}
  ]}},
  "inner_hits": {}
}}}
```

---

## 6. multi_match — Múltiples campos

**Caso de uso:** Barra de búsqueda que busca en título, descripción y tags simultáneamente.

```json
{"query": {"multi_match": {
  "query": "búsqueda rendimiento",
  "fields": ["titulo^3", "contenido", "tags^2"],
  "type": "best_fields",
  "tie_breaker": 0.3
}}}
```

---

## 7. function_score — Relevancia personalizada

**Caso de uso:** Boostear resultados recientes o populares.

```json
{"query": {"function_score": {
  "query": {"match": {"contenido": "OpenSearch"}},
  "functions": [
    {"gauss": {"fecha": {"origin": "now", "scale": "30d"}}},
    {"field_value_factor": {"field": "visitas", "modifier": "log1p"}}
  ],
  "score_mode": "sum"
}}}
```

---

## 8. knn — Búsqueda vectorial

**Caso de uso:** Encontrar documentos semánticamente similares.

```json
{"query": {"knn": {"embedding": {"vector": [0.1, 0.2, 0.9], "k": 5}}}}
```

---

## 9. match_phrase — Frase exacta

**Caso de uso:** Buscar una secuencia exacta de palabras (citas, nombres compuestos).

```json
{"query": {"match_phrase": {"titulo": "búsqueda vectorial"}}}
```

---

## 10. exists — Campo presente

**Caso de uso:** Encontrar documentos que tengan (o no) un campo específico.

```json
{"query": {"exists": {"field": "error_message"}}}
```

---

## 11. wildcard — Patrón con comodines

**Caso de uso:** Buscar por patrones en campos keyword (IDs parciales, dominios).

```json
{"query": {"wildcard": {"email": {"value": "*@empresa.com"}}}}
```

**Nota:** Wildcard es lento en campos con alta cardinalidad. Evítalo en producción si hay alternativas.
