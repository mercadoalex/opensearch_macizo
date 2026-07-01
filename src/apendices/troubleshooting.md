# Troubleshooting

Guía de resolución para los 8 problemas más comunes en clústeres OpenSearch.

---

## 1. Cluster en estado RED

**Síntoma:** `_cluster/health` devuelve `"status": "red"`. Hay pérdida de datos potencial.

**Causa probable:** Al menos un shard primario no está asignado. Puede ser por nodo caído, disco lleno, o corrupción de datos.

**Resolución:**
```bash
# Identificar shards no asignados
curl -sk "https://localhost:9200/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason" -u admin:Admin123! | grep UNASSIGNED

# Ver razón detallada
curl -sk "https://localhost:9200/_cluster/allocation/explain" -u admin:Admin123!

# Si el nodo vuelve, los shards se re-asignan automáticamente.
# Si el nodo no vuelve y no hay réplicas: datos perdidos. Restaurar de snapshot.
```

---

## 2. Cluster en estado YELLOW

**Síntoma:** `_cluster/health` devuelve `"status": "yellow"`. Todos los primarios asignados, pero réplicas pendientes.

**Causa probable:** No hay suficientes nodos para asignar las réplicas (e.g., 1 réplica configurada pero solo 1 nodo). O un nodo se recupera y aún no terminó de copiar.

**Resolución:**
```bash
# En lab con 1 nodo: es normal. Configura replicas=0.
curl -sk -X PUT "https://localhost:9200/mi-indice/_settings" -u admin:Admin123! \
  -H "Content-Type: application/json" -d '{"index": {"number_of_replicas": 0}}'

# En producción: agregar nodos o esperar que el nodo se recupere.
```

---

## 3. Circuit Breaker Tripped

**Síntoma:** Respuesta HTTP 429 con mensaje `"[parent] Data too large"`.

**Causa probable:** Una query o agregación intenta usar más memoria que el límite del circuit breaker. Típico en aggregations con `size` alto sobre campos de alta cardinalidad.

**Resolución:**
```bash
# Ver estado de breakers
curl -sk "https://localhost:9200/_nodes/stats/breaker" -u admin:Admin123!

# Soluciones:
# 1. Reducir size en terms aggregations
# 2. Usar composite aggregation con paginación
# 3. Agregar más memoria/nodos
# 4. Si es fielddata: usar .keyword en vez de text para sorting
```

---

## 4. Disk Watermark Exceeded

**Síntoma:** Logs muestran `"flood stage disk watermark exceeded"`. Índices pasan a read-only.

**Causa probable:** Disco al 95% (flood stage). OpenSearch bloquea escrituras para prevenir corrupción.

**Resolución:**
```bash
# Verificar uso de disco
curl -sk "https://localhost:9200/_cat/allocation?v" -u admin:Admin123!

# Liberar espacio: eliminar índices viejos o reducir retención
curl -sk -X DELETE "https://localhost:9200/logs-2024.01.*" -u admin:Admin123!

# Desbloquear índices read-only (después de liberar espacio)
curl -sk -X PUT "https://localhost:9200/_all/_settings" -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"index.blocks.read_only_allow_delete": null}'
```

---

## 5. Unassigned Shards (persistentes)

**Síntoma:** `_cat/shards` muestra shards en estado UNASSIGNED por más de 10 minutos.

**Causa probable:** Restricciones de allocation (awareness, disk watermark, max retries), nodos sin espacio, o index cerrado con allocation deshabilitada.

**Resolución:**
```bash
# Diagnóstico
curl -sk "https://localhost:9200/_cluster/allocation/explain" -u admin:Admin123!

# Forzar retry de allocation
curl -sk -X POST "https://localhost:9200/_cluster/reroute?retry_failed=true" -u admin:Admin123!

# Si el shard está corrupto: aceptar pérdida y asignar shard vacío
curl -sk -X POST "https://localhost:9200/_cluster/reroute" -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"commands":[{"allocate_empty_primary":{"index":"mi-indice","shard":0,"node":"node-1","accept_data_loss":true}}]}'
```

---

## 6. GC Pauses Prolongadas

**Síntoma:** Nodos se desconectan intermitentemente. Logs JVM muestran GC pauses > 1 segundo.

**Causa probable:** Heap demasiado grande (> 32 GB triggers no-compressed oops), queries pesadas cargando mucho en memoria, o field data cache saturado.

**Resolución:**
```bash
# Verificar GC stats
curl -sk "https://localhost:9200/_nodes/stats/jvm" -u admin:Admin123!

# Soluciones:
# 1. Reducir heap a ≤ 32 GB
# 2. Revisar field data usage y migrar a .keyword
# 3. Aumentar G1HeapRegionSize si heap > 16 GB
# 4. Agregar más nodos (distribuir carga)
```

---

## 7. Queries Lentas (Latencia alta)

**Síntoma:** `took` en respuestas > 1 segundo. Usuarios reportan lentitud.

**Causa probable:** Queries sin filtros eficientes, aggregations sobre todo el dataset, wildcard al inicio (`*texto`), scripts complejos en function_score.

**Resolución:**
```bash
# Activar slow logs
curl -sk -X PUT "https://localhost:9200/_all/_settings" -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"index.search.slowlog.threshold.query.warn":"1s","index.search.slowlog.threshold.query.info":"500ms"}'

# Profiling de query específica
curl -sk "https://localhost:9200/mi-indice/_search" -u admin:Admin123! \
  -H "Content-Type: application/json" -d '{"profile":true,"query":{...}}'

# Soluciones comunes:
# 1. Mover condiciones binarias de must a filter (cacheable)
# 2. Usar routing para reducir fan-out
# 3. Reducir size en aggregations
# 4. Evitar wildcards al inicio del patrón
```

---

## 8. Node Disconnect / Master Not Discovered

**Síntoma:** Logs muestran `"master not discovered"` o `"node left the cluster"`.

**Causa probable:** Problemas de red entre nodos, GC pauses que exceden discovery timeout, o cluster managers insuficientes para mantener quorum.

**Resolución:**
```bash
# Verificar nodos visibles
curl -sk "https://localhost:9200/_cat/nodes?v&h=name,master,heap.percent" -u admin:Admin123!

# Ajustar timeouts si la red es inestable
# opensearch.yml:
# cluster.fault_detection.follower_check.interval: 2s
# cluster.fault_detection.follower_check.timeout: 10s
# cluster.fault_detection.follower_check.retry_count: 5

# Si perdiste quorum (2 de 3 cluster_managers caídos):
# Hay que reiniciar nodos con configuración de bootstrap manual.
```
