# Arquitectura de Producción

> **Opinión del autor:** Sizing es la pregunta que todos hacen primero y la que menos sentido tiene responder sin datos. "¿Cuántos nodos necesito?" depende de tu volumen de ingesta, retención, queries por segundo, y SLOs. Este capítulo te da las fórmulas y patrones — no recetas mágicas. Empieza con 3 nodos, mide, y escala basándote en métricas reales.

## Objetivo

Diseñar clústeres OpenSearch para producción. Dominar sizing, roles de nodos, replicación cross-cluster, snapshots y estrategias de disaster recovery.

## Prerequisitos

- Capítulo 12: Puente intermedio-ninja (todos los conceptos intermedios dominados)
- Laboratorio con perfil `ninja` levantado (`docker compose --profile ninja up`)

## Contenido

### Sizing: La Fórmula Base

El sizing parte de cuatro variables:

| Variable | Pregunta |
|----------|----------|
| Ingesta diaria | ¿Cuántos GB/día indexas? |
| Retención | ¿Cuántos días mantienes los datos? |
| Réplicas | ¿Cuántas copias por shard? |
| Overhead | Factor de compresión y metadata (~15-20%) |

**Fórmula de almacenamiento:**

```
Storage = Ingesta_diaria × Retención × (1 + Réplicas) × 1.2
```

**Ejemplo:** 50 GB/día, 30 días retención, 1 réplica:

```
50 × 30 × (1 + 1) × 1.2 = 3,600 GB = 3.6 TB
```

Con shards de 30-50 GB ideales, necesitas ~72-120 shards primarios distribuidos entre nodos data.

**Nodos necesarios (storage-bound):**

```
Nodos_data = Storage / Disco_por_nodo × 0.85
```

El factor 0.85 deja margen para peaks y operaciones de merge. Nunca llenes un nodo al 100%.

> 📁 Código fuente: [`code/ch13/sizing-calculator.sh`](../../code/ch13/sizing-calculator.sh)

### Roles de Nodos

En producción, los nodos deben tener roles dedicados:

| Rol | Función | Recursos típicos |
|-----|---------|-----------------|
| cluster_manager | Gestiona estado del clúster, asigna shards | 4 vCPU, 16 GB RAM, SSD pequeño |
| data | Almacena datos, ejecuta queries y agregaciones | 8+ vCPU, 64 GB RAM, SSD grande |
| ingest | Ejecuta ingest pipelines | 4 vCPU, 16 GB RAM |
| coordinating | Distribuye requests, agrega resultados | 4 vCPU, 32 GB RAM |
| ml | Ejecuta modelos ML | 8+ vCPU, 32 GB RAM, GPU opcional |

**Configuración de roles en opensearch.yml:**

```yaml
# Nodo cluster_manager dedicado
node.roles: [cluster_manager]

# Nodo data dedicado
node.roles: [data]

# Nodo ingest dedicado  
node.roles: [ingest]

# Nodo coordinating (sin roles = coordinating-only)
node.roles: []
```

**Regla de mínimos para producción:**

| Tamaño clúster | Cluster managers | Data nodes | Coordinating |
|----------------|-----------------|------------|--------------|
| 3 nodos | 3 (compartido con data) | 3 | 0 (innecesario) |
| 9 nodos | 3 dedicados | 5 | 1 |
| 30+ nodos | 3 dedicados | 20+ | 3-5 |

Con 3 nodos, cada uno tiene roles `[cluster_manager, data]`. Es el mínimo para tolerar la pérdida de un nodo. Con 9+, separar roles evita que operaciones pesadas de data afecten la estabilidad del cluster state.

> 📁 Código fuente: [`code/ch13/node-roles.yml`](../../code/ch13/node-roles.yml)

### Replicación Cross-Cluster (CCR)

Cross-Cluster Replication replica índices entre clústeres independientes. Casos de uso: disaster recovery en otra región, lecturas locales para reducir latencia, separación de cargas.

```bash
# Configurar conexión al clúster remoto
curl -sk -X PUT "https://localhost:9200/_cluster/settings" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "persistent": {
    "cluster.remote.cluster-dr": {
      "seeds": ["remote-node1:9300", "remote-node2:9300"]
    }
  }
}'
```

```bash
# Crear regla de replicación
curl -sk -X PUT "https://localhost:9200/_plugins/_replication/logs-replica/_start" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "leader_alias": "cluster-dr",
  "leader_index": "logs-production",
  "use_roles": {
    "leader_cluster_role": "cross_cluster_replication_leader_full_access",
    "follower_cluster_role": "cross_cluster_replication_follower_full_access"
  }
}'
```

El follower index es read-only y se actualiza con lag mínimo. Si el clúster primario falla, promueves el follower a writer.

### Disaster Recovery: Snapshots

Los snapshots son la forma estándar de backup en OpenSearch. Se almacenan en repositories externos (S3, GCS, filesystem compartido).

```bash
# Registrar repository S3
curl -sk -X PUT "https://localhost:9200/_snapshot/backups" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "type": "s3",
  "settings": {
    "bucket": "opensearch-backups-prod",
    "region": "us-east-1",
    "base_path": "snapshots"
  }
}'

# Crear snapshot
curl -sk -X PUT "https://localhost:9200/_snapshot/backups/snap-2024-03-15" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "indices": "logs-*,metrics-*",
  "include_global_state": false
}'

# Restore
curl -sk -X POST "https://localhost:9200/_snapshot/backups/snap-2024-03-15/_restore" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "indices": "logs-2024.03.*",
  "rename_pattern": "(.+)",
  "rename_replacement": "restored-$1"
}'
```

**Estrategia de DR recomendada:**

| RPO objetivo | Estrategia |
|--------------|-----------|
| < 1 min | CCR (replicación continua) |
| < 1 hora | Snapshots cada hora a S3 |
| < 24 horas | Snapshot diario nocturno |

> 📁 Código fuente: [`code/ch13/snapshots.sh`](../../code/ch13/snapshots.sh)

### Failover: Qué Hacer Cuando un Nodo Cae

Con réplicas configuradas, OpenSearch maneja automáticamente la pérdida de un data node:

1. El cluster manager detecta el nodo caído (timeout configurable, default 1 min)
2. Promueve réplicas a primarios
3. Re-asigna shards a nodos disponibles
4. El clúster pasa a `yellow` temporalmente hasta rebalancear

Con cluster managers dedicados (3 nodos), toleras la pérdida de 1. Si caen 2 de 3, el clúster pierde quorum y no puede escribir. Configuración crítica:

```yaml
# opensearch.yml — quorum para 3 cluster managers
discovery.seed_hosts: ["cm-1", "cm-2", "cm-3"]
cluster.initial_cluster_manager_nodes: ["cm-1", "cm-2", "cm-3"]
```

## Cuándo Usar y Cuándo NO

| ✅ Hacer en producción... | ❌ NO hacer... |
|---|---|
| Separar roles de nodos en clústeres 9+ | Poner cluster_manager y data en el mismo nodo con 30+ nodos |
| Configurar al menos 1 réplica por índice | Operar sin réplicas en producción |
| Automatizar snapshots con ISM o cron | Confiar solo en CCR sin snapshots (CCR no protege contra deletes accidentales) |
| Monitorear disk watermarks y shard balance | Ignorar alertas de disk until es demasiado tarde |

## Ejercicios

1. Calcula el sizing para: 100 GB/día de ingesta, 90 días de retención, 1 réplica, nodos con 2 TB de disco cada uno. ¿Cuántos data nodes necesitas?

2. Diseña la arquitectura de un clúster de 9 nodos: asigna roles, define cuántos nodos por rol, y justifica tus decisiones.

3. Configura un snapshot repository tipo `fs` en el laboratorio y crea un snapshot del índice `productos`. Luego restaura con un prefijo `restored-` y verifica que los datos están intactos.

## Resumen

- El sizing parte de ingesta diaria × retención × réplicas × overhead — no de adivinanzas
- Los roles dedicados (cluster_manager, data, ingest, coordinating) mejoran estabilidad en clústeres grandes
- 3 cluster managers es el mínimo para tolerar pérdida de un nodo con quorum
- CCR replica índices entre clústeres para DR activo con lag mínimo
- Los snapshots son backup point-in-time — imprescindibles incluso con CCR
- Shards de 30-50 GB son el sweet spot para balance entre rendimiento y recovery time
