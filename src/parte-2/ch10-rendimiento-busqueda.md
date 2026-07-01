# Rendimiento de Búsqueda

> **Opinión del autor:** Tuning de rendimiento sin métricas es adivinanza. Antes de tocar un parámetro, mide. Antes de agregar shards, perfilá la query. El 90% de los problemas de rendimiento en OpenSearch son queries mal escritas o mappings incorrectos, no falta de hardware.

## Objetivo

Comprender los mecanismos de caching, routing, shard allocation y tuning de relevancia. Saber diagnosticar y resolver problemas de latencia en búsquedas.

## Prerequisitos

- Capítulo 6: Query DSL avanzado (bool queries, function_score)
- Capítulo 7: Agregaciones (impactan rendimiento significativamente)

## Contenido

### Caches de OpenSearch

OpenSearch tiene tres niveles de cache que aceleran búsquedas repetidas.

#### Request Cache

Cachea el resultado completo de un request `_search` con `size: 0` (solo agregaciones). Se invalida automáticamente al indexar nuevos documentos en el índice.

```bash
curl -sk "https://localhost:9200/ventas/_search?request_cache=true&size=0" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"aggs": {"total": {"sum": {"field": "precio"}}}}'
```

Trade-off: aceleración inmediata en queries repetidas vs invalidación en cada escritura. Útil para dashboards sobre datos históricos. Inútil para índices con alta tasa de ingesta.

#### Query Cache (Node Query Cache)

Cachea resultados de cláusulas `filter`. Al usar `bool.filter` en vez de `bool.must`, OpenSearch puede reusar el bitset de documentos que matchean sin recalcular.

```bash
curl -sk "https://localhost:9200/ventas/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "filter": [
        {"term": {"region": "CDMX"}},
        {"range": {"fecha_venta": {"gte": "2024-01-01"}}}
      ]
    }
  }
}'
```

Trade-off: los filtros cacheados son O(1) en queries subsecuentes. Requiere usar `filter` consistentemente en vez de `must`. El cache se comparte entre queries — un filtro `region: CDMX` cacheado beneficia a cualquier query que lo use.

#### Field Data Cache

Almacena valores de campo en memoria para sorting y aggregations sobre campos `text`. Es costoso en memoria y generalmente indeseable.

Recomendación: nunca hagas sorting o aggregations sobre campos `text`. Usa el sub-campo `.keyword`. Si necesitas field data por alguna razón, configura un límite:

```bash
curl -sk -X PUT "https://localhost:9200/_cluster/settings" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"persistent": {"indices.fielddata.cache.size": "20%"}}'
```

#### Verificar estado de caches

```bash
curl -sk "https://localhost:9200/_nodes/stats/indices/query_cache,request_cache,fielddata" \
  -u admin:Admin123! | python3 -m json.tool
```

> 📁 Código fuente: [`code/ch10/01-caches.sh`](../../code/ch10/01-caches.sh)

### Routing: Control de Distribución

Por defecto, OpenSearch usa el `_id` del documento para decidir en qué shard almacenarlo. Con routing custom, puedes garantizar que todos los documentos de un tenant o categoría vivan en el mismo shard.

```bash
curl -sk -X POST "https://localhost:9200/ventas/_doc?routing=CDMX" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"producto": "Laptop", "region": "CDMX", "precio": 1200}'
```

Al buscar con el mismo routing, OpenSearch solo consulta un shard en vez de todos:

```bash
curl -sk "https://localhost:9200/ventas/_search?routing=CDMX" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"query": {"term": {"region": "CDMX"}}}'
```

Trade-off: queries con routing son más rápidas (un shard vs todos). Pero si la distribución es desigual, un shard puede quedar sobrecargado (hot shard). Usa routing cuando tus queries siempre filtran por el campo de routing.

> 📁 Código fuente: [`code/ch10/02-routing.sh`](../../code/ch10/02-routing.sh)

### Shard Allocation y Sizing

Las reglas de oro para sizing de shards:

| Regla | Valor recomendado | Razón |
|-------|-------------------|-------|
| Tamaño por shard | 10-50 GB | Shards muy grandes = recovery lento; muy pequeños = overhead |
| Shards por nodo | < 1000 | Cada shard consume memory para metadata en cluster state |
| Shards por índice | 1 (lab) / 3-5 (prod) | Más shards = más paralelismo, más overhead |

Verificar distribución actual:

```bash
curl -sk "https://localhost:9200/_cat/shards?v&s=store:desc" \
  -u admin:Admin123!
```

### Profiling de Queries

La API `_search` con `profile: true` muestra exactamente dónde se gasta el tiempo:

```bash
curl -sk "https://localhost:9200/ventas/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "profile": true,
  "query": {
    "bool": {
      "must": [{"match": {"producto": "laptop"}}],
      "filter": [{"range": {"precio": {"gte": 500}}}]
    }
  }
}'
```

El resultado incluye tiempo por fase: `query`, `fetch`, `dfs`. Cada cláusula interna muestra su propio breakdown. Si una cláusula toma el 90% del tiempo, enfoca la optimización ahí.

> 📁 Código fuente: [`code/ch10/03-profiling.sh`](../../code/ch10/03-profiling.sh)

### Slow Logs

Configura slow logs para detectar queries que exceden un umbral de latencia:

```bash
curl -sk -X PUT "https://localhost:9200/ventas/_settings" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "index.search.slowlog.threshold.query.warn": "2s",
  "index.search.slowlog.threshold.query.info": "500ms",
  "index.search.slowlog.threshold.fetch.warn": "1s"
}'
```

Los slow logs aparecen en los logs del nodo. En producción, configúralos en todos los índices via template.

### Tuning de Relevancia

Cuando el rendimiento del scoring es el cuello de botella:

1. **Usa `filter` en vez de `must`** para condiciones binarias. Los filtros no calculan score.
2. **`terminate_after`** detiene la búsqueda tras N documentos encontrados. Útil cuando solo necesitas saber si hay resultados.
3. **`_source: false`** si solo necesitas IDs o scores. Evita leer el `_source` del disco.
4. **`stored_fields: []`** combinado con `_source: false` para máxima velocidad en count-like queries.

```bash
curl -sk "https://localhost:9200/ventas/_search" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "terminate_after": 100,
  "_source": false,
  "query": {"term": {"region": "CDMX"}}
}'
```

## Cuándo Usar y Cuándo NO

| ✅ Optimizar cuando... | ❌ NO optimizar cuando... |
|---|---|
| La latencia P95 excede tus SLOs | El rendimiento actual cumple los SLOs holgadamente |
| Los slow logs muestran queries > 1s consistentemente | No has medido — estás adivinando el cuello de botella |
| El profiling muestra un componente dominante | Agregarías complejidad operativa por <50ms de mejora |
| Tu request cache tiene hit rate < 30% | Tu caso de uso es write-heavy sin queries repetidas |

## Ejercicios

1. Activa slow logs en el índice `ventas` con umbral de 100ms para queries. Ejecuta varias queries y verifica cuáles aparecen en los slow logs del nodo.

2. Ejecuta la misma query compleja con y sin `profile: true`. Identifica la cláusula más costosa y propón una optimización (¿se puede mover a `filter`?).

3. Compara la latencia de buscar con `routing=CDMX` vs sin routing sobre el índice `ventas`. Usa `took` en la respuesta como métrica.

4. Verifica el estado del node query cache antes y después de ejecutar 10 veces la misma query con `bool.filter`. Confirma que el hit count incrementa.

## Resumen

- El **request cache** acelera agregaciones repetidas pero se invalida al indexar — ideal para datos históricos
- El **query cache** cachea resultados de `filter` — usa `bool.filter` consistentemente para beneficiarte
- El **routing custom** dirige documentos y búsquedas a un shard específico — reduce fan-out pero riesgo de hot shards
- El **profiling** (`profile: true`) muestra el desglose de tiempo por componente de la query
- Los **slow logs** detectan queries lentas en producción sin impacto en rendimiento
- Regla: mide primero, optimiza después. El 90% de los problemas son queries o mappings, no hardware
