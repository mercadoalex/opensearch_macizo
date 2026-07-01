# Optimización y Cierre

> **Opinión del autor:** Este capítulo es un survival kit para el day-2 de operaciones. Sizing, tuning de JVM, circuit breakers, y upgrades sin downtime. Si solo lees un capítulo antes de poner algo en producción, que sea este. Los conceptos anteriores te enseñan a construir — este te enseña a mantener vivo lo que construiste.

## Objetivo

Dominar JVM tuning, circuit breakers, slow logs, profiling avanzado y operaciones day-2: rolling upgrades, backup automatizado, reindexación sin downtime, y capacity planning. Cerrar con un checklist de producción.

## Prerequisitos

- Capítulos 13-17 completados (toda la Parte III)
- Experiencia operando el clúster del laboratorio

## Contenido

### JVM Tuning

OpenSearch corre sobre la JVM. La configuración de heap es la decisión más impactante.

**Regla de oro del heap:**
- Asigna máximo 50% de la RAM del nodo al heap
- Nunca excedas 32 GB de heap (compressed oops threshold)
- El 50% restante queda para el OS page cache (critical para búsquedas)

```yaml
# jvm.options o variable de entorno
-Xms16g
-Xmx16g
```

Siempre `Xms == Xmx`. Si difieren, la JVM gasta tiempo redimensionando el heap.

**GC Tuning:**

OpenSearch 2.x usa G1GC por defecto. Ajustes comunes:

```yaml
-XX:+UseG1GC
-XX:G1HeapRegionSize=16m
-XX:InitiatingHeapOccupancyPercent=40
-XX:MaxGCPauseMillis=200
```

Señales de que necesitas ajustar GC:
- GC pauses > 500ms en logs del nodo
- Old gen usage consistentemente > 75%
- Node disconnects por GC pauses largas

> 📁 Código fuente: [`code/ch18/jvm-options-example.txt`](../../code/ch18/jvm-options-example.txt)

### Circuit Breakers

Los circuit breakers previenen OutOfMemoryError rechazando operaciones que excederían el heap disponible.

| Breaker | Límite default | Protege contra |
|---------|---------------|---------------|
| `parent` | 95% heap | Suma de todos los breakers |
| `request` | 60% heap | Requests individuales grandes (aggs masivas) |
| `fielddata` | 40% heap | Field data cache (sorting en text fields) |
| `in_flight_requests` | 100% heap | Requests HTTP en vuelo |

Consultar estado:

```bash
curl -sk "https://localhost:9200/_nodes/stats/breaker" \
  -u admin:Admin123! | python3 -m json.tool
```

Si un breaker se dispara frecuentemente:
- `request`: optimiza aggregations (reduce `size`, usa `composite`)
- `fielddata`: usa `.keyword` en vez de `text` para sorting/aggs
- `parent`: necesitas más heap o más nodos

### Rolling Upgrades

Actualizar OpenSearch sin downtime:

```bash
# 1. Deshabilitar shard allocation
curl -sk -X PUT "https://localhost:9200/_cluster/settings" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"persistent": {"cluster.routing.allocation.enable": "primaries"}}'

# 2. Flush synced
curl -sk -X POST "https://localhost:9200/_flush/synced" -u admin:Admin123!

# 3. Detener el nodo, actualizar, reiniciar

# 4. Esperar que el nodo rejoin
curl -sk "https://localhost:9200/_cat/nodes?v" -u admin:Admin123!

# 5. Re-habilitar allocation
curl -sk -X PUT "https://localhost:9200/_cluster/settings" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"persistent": {"cluster.routing.allocation.enable": "all"}}'

# 6. Esperar green
curl -sk "https://localhost:9200/_cluster/health?wait_for_status=green&timeout=5m" \
  -u admin:Admin123!

# 7. Repetir para cada nodo
```

> 📁 Código fuente: [`code/ch18/rolling-upgrade.sh`](../../code/ch18/rolling-upgrade.sh)

### Reindexación sin Downtime

Cuando necesitas cambiar un mapping o reestructurar datos:

1. Crea el nuevo índice con el mapping correcto
2. Usa `_reindex` para copiar datos
3. Swap el alias atómicamente

```bash
# Reindex
curl -sk -X POST "https://localhost:9200/_reindex" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "source": {"index": "productos-v1"},
  "dest": {"index": "productos-v2"}
}'

# Swap alias (atómico)
curl -sk -X POST "https://localhost:9200/_aliases" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "actions": [
    {"remove": {"index": "productos-v1", "alias": "productos"}},
    {"add": {"index": "productos-v2", "alias": "productos"}}
  ]
}'
```

### Capacity Planning

Monitorea estas métricas para planificar escala:

| Métrica | Umbral de alerta | Acción |
|---------|-----------------|--------|
| Disk usage | > 75% | Agregar nodos data o reducir retención |
| Heap usage | > 70% promedio | Agregar nodos o aumentar heap |
| CPU usage | > 80% sostenido | Agregar coordinating nodes |
| Search latency P95 | > SLO | Profiling + optimización de queries |
| Indexing rate declining | < baseline | Verificar backpressure y queue sizes |

```bash
# Dashboard de capacidad rápido
curl -sk "https://localhost:9200/_cat/allocation?v" -u admin:Admin123!
curl -sk "https://localhost:9200/_cat/nodes?v&h=name,heap.percent,disk.used_percent,cpu,load_1m" -u admin:Admin123!
```

## Checklist de Producción

Antes de poner un clúster en producción, verifica:

### Infraestructura
- [ ] Mínimo 3 cluster_manager nodes para quorum
- [ ] Roles de nodos separados en clústeres > 9 nodos
- [ ] Heap = 50% RAM, máximo 32 GB, Xms == Xmx
- [ ] Disable swap (`bootstrap.memory_lock: true`)
- [ ] File descriptors ≥ 65536 (`ulimit -n`)
- [ ] `vm.max_map_count = 262144`

### Datos
- [ ] Mappings explícitos en todos los índices de producción
- [ ] Index templates con ISM policies asociadas
- [ ] Shards entre 30-50 GB (ni más grandes ni más chicos)
- [ ] Al menos 1 réplica por índice
- [ ] Aliases para desacoplar aplicaciones

### Operaciones
- [ ] Snapshots automatizados (mínimo diarios)
- [ ] Slow logs configurados en todos los índices
- [ ] Alertas en disk watermarks (high: 85%, flood: 95%)
- [ ] Procedimiento de rolling upgrade documentado y probado
- [ ] Runbook para recovery: nodo caído, cluster red, disk full

### Seguridad
- [ ] Security plugin habilitado (nunca desactivar)
- [ ] Usuarios con mínimo privilegio (no compartir admin)
- [ ] TLS en tránsito (nodo-nodo y cliente-nodo)
- [ ] Audit logging habilitado para compliance
- [ ] Contraseñas rotadas desde los defaults

### Monitoring
- [ ] Métricas de clúster exportadas (Prometheus/CloudWatch)
- [ ] Dashboards de health, performance y capacity
- [ ] Alertas configuradas en las 5 métricas clave
- [ ] Logs de OpenSearch centralizados (no solo en disco local)

## Cuándo Usar y Cuándo NO

| ✅ Optimizar... | ❌ NO optimizar... |
|---|---|
| Cuando las métricas indican degradación | Sin haber medido primero |
| JVM cuando GC pauses exceden 500ms | Si el heap nunca supera 60% |
| Circuit breakers si se disparan en producción | Preventivamente sin datos de uso real |
| Capacity planning cada trimestre | Solo cuando ya estás en crisis |

## Ejercicios

1. Verifica el estado de los circuit breakers del laboratorio. ¿Alguno se ha disparado? ¿Cuál tiene el estimated más alto?

2. Ejecuta el procedimiento de rolling upgrade simulado: deshabilita allocation, flush, espera green. No necesitas actualizar realmente — practica el procedimiento.

3. Completa el checklist de producción para tu clúster de laboratorio. ¿Cuántos puntos cumple? ¿Cuáles faltan?

## Resumen

- Heap = 50% RAM, máximo 32 GB, siempre Xms == Xmx — es la regla más importante de JVM tuning
- Los circuit breakers protegen contra OOM — monitoréalos, no los desactives
- Rolling upgrades permiten actualizar sin downtime: disable allocation → upgrade node → re-enable
- Reindexación sin downtime = nuevo índice + _reindex + swap alias atómico
- Capacity planning es continuo: monitorea disk, heap, CPU, latencia y throughput
- El checklist de producción cubre infra, datos, operaciones, seguridad y monitoring
- Sin monitoring no hay optimización — solo adivinanza
