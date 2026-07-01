# Observando OpenSearch con eBPF

> **Opinión del autor:** eBPF te da visibilidad que ningún slow log o API de stats puede darte. Cuando OpenSearch reporta que una query tomó 200ms pero el usuario percibe 800ms, la diferencia está en la red, en el kernel, o en GC pauses que OpenSearch no registra. eBPF ve todo eso desde fuera, sin instrumentar la JVM ni modificar configuración. Es el debugger definitivo para problemas que no aparecen en los dashboards.

> 📖 Este apéndice conecta con ["eBPF: Macizo y Conciso"](https://github.com/mercadoalex/ebpf_macizo) — el otro libro de esta serie. Si no conocés eBPF, ese libro es tu punto de partida.

## ¿Por Qué eBPF para OpenSearch?

OpenSearch expone métricas vía `_nodes/stats`, slow logs, y la Profile API. Pero hay una capa invisible:

| Lo que OpenSearch ve | Lo que eBPF ve |
|---------------------|---------------|
| Query time (tiempo dentro del motor) | Latencia total incluyendo red y kernel scheduling |
| GC pauses reportadas por la JVM | Pauses reales de CPU (off-CPU time) que la JVM no contabiliza |
| Disk I/O como "merge time" en stats | Latencia real por operación de disco, por archivo, por shard |
| Network como "transport time" | Latencia TCP exacta entre nodos, retransmisiones, congestion |
| Thread pool queue sizes | Context switches, run queue latency, CPU starvation |

eBPF opera en el kernel. No necesita permisos dentro de la JVM ni recompilación de OpenSearch. Funciona en cualquier clúster Linux sin side effects.

## Caso 1: Disk I/O por Shard con biosnoop

Cuando un shard es lento, ¿es por el disco o por la query? `biosnoop` (de bcc-tools) traza cada operación de block I/O:

```bash
# Trazar I/O del proceso OpenSearch (PID)
sudo biosnoop -p $(pgrep -f opensearch) --duration 30
```

Salida típica:

```
TIME(s)  COMM         PID    DISK  T  SECTOR   BYTES   LAT(ms)
0.001    java         12345  nvme0 R  4096000  65536   0.12
0.003    java         12345  nvme0 R  4097024  131072  0.45
0.015    java         12345  nvme0 W  8192000  262144  1.23
```

Qué buscar:
- **LAT > 5ms** en SSDs indica contención de disco o throttling
- **Writes grandes** durante queries sugieren merge activity compitiendo con búsquedas
- Correlaciona con el path del archivo para identificar qué shard genera I/O

Para ir más profundo, traza por archivo:

```bash
# Trazar qué archivos de shard generan más I/O
sudo bpftrace -e '
tracepoint:block:block_rq_issue /comm == "java"/ {
    @io_bytes[args->rwbs] = sum(args->bytes);
}'
```

> 📁 Código fuente: [`code/ebpf/01-biosnoop-opensearch.sh`](../../code/ebpf/01-biosnoop-opensearch.sh)

## Caso 2: Latencia TCP entre Nodos con tcplife

En clústeres multi-nodo, la comunicación inter-nodo (puerto 9300) puede ser el cuello de botella invisible. `tcplife` muestra la duración y throughput de cada conexión TCP:

```bash
# Trazar conexiones TCP del proceso OpenSearch
sudo tcplife -p $(pgrep -f opensearch) --duration 60
```

Salida:

```
PID    COMM    LADDR           LPORT  RADDR           RPORT  TX_KB  RX_KB  MS
12345  java    10.0.1.5        9300   10.0.1.6        9300   1024   512    45.2
12345  java    10.0.1.5        9300   10.0.1.7        9300   2048   256    123.8
```

Si una conexión entre nodos muestra latencia > 50ms consistentemente, investiga la red — puede ser MTU mismatch, buffer overflow, o routing sub-óptimo.

Para medir latencia de cada request HTTP entrante (puerto 9200):

```bash
sudo bpftrace -e '
kprobe:tcp_sendmsg /comm == "java"/ {
    @start[tid] = nsecs;
}
kretprobe:tcp_sendmsg /comm == "java" && @start[tid]/ {
    @latency_us = hist((nsecs - @start[tid]) / 1000);
    delete(@start[tid]);
}'
```

> 📁 Código fuente: [`code/ebpf/02-tcp-latency.bt`](../../code/ebpf/02-tcp-latency.bt)

## Caso 3: Detectar GC Pauses desde el Kernel con runqlat

La JVM reporta GC pauses, pero ¿cuánto tiempo real pasó el thread sin ejecutar? `runqlat` mide el tiempo que los threads de OpenSearch esperan en la run queue del scheduler:

```bash
# Histograma de latencia de scheduling para threads de OpenSearch
sudo runqlat -p $(pgrep -f opensearch) 10
```

Salida:

```
     usecs               : count    distribution
         0 -> 1          : 15234   |****************************************|
         2 -> 3          : 8921    |***********************                 |
         4 -> 7          : 3456    |*********                               |
         8 -> 15         : 1234    |***                                     |
        16 -> 31         : 567     |*                                       |
        32 -> 63         : 234     |                                        |
        64 -> 127        : 89      |                                        |
       128 -> 255        : 12      |                                        |
      1024 -> 2047       : 3       |                                        |
```

Si ves entradas significativas en > 1ms (1024+ usecs), tus threads están siendo starved por:
- CPU overcommit (más vCPUs asignadas que físicas)
- Noisy neighbors en VMs compartidas
- GC pauses que bloquean todos los threads simultáneamente

Comparar `runqlat` con los GC logs de OpenSearch revela si la latencia percibida es por GC (JVM) o por scheduling (kernel/hypervisor).

> 📁 Código fuente: [`code/ebpf/03-runqlat-opensearch.sh`](../../code/ebpf/03-runqlat-opensearch.sh)

## Caso 4: Network Policies con Cilium

Cilium usa eBPF para implementar network policies a nivel de kernel — sin iptables, sin overhead de userspace proxies. Para proteger un clúster OpenSearch en Kubernetes:

```yaml
# CiliumNetworkPolicy: Solo permitir acceso al puerto 9200 desde namespace "apps"
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: opensearch-ingress
  namespace: opensearch
spec:
  endpointSelector:
    matchLabels:
      app: opensearch
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: apps
      toPorts:
        - ports:
            - port: "9200"
              protocol: TCP
    - fromEndpoints:
        - matchLabels:
            app: opensearch
      toPorts:
        - ports:
            - port: "9300"
              protocol: TCP
```

Esta policy:
- Permite acceso al puerto 9200 solo desde pods en el namespace `apps`
- Permite comunicación inter-nodo en puerto 9300 solo entre pods de OpenSearch
- Todo otro tráfico se bloquea a nivel de kernel (eBPF) sin pasar por iptables

> 📁 Código fuente: [`code/ebpf/04-cilium-policy.yaml`](../../code/ebpf/04-cilium-policy.yaml)

## Caso 5: Profiling de Syscalls con funccount

¿Cuántas syscalls hace OpenSearch por segundo? ¿Predominan reads, writes, o epoll_waits?

```bash
# Top 10 syscalls de OpenSearch en 10 segundos
sudo funccount -p $(pgrep -f opensearch) -d 10 'sys_*'
```

Salida típica de un nodo data bajo carga de búsqueda:

```
FUNC                   COUNT
sys_epoll_wait         45230
sys_read               12456
sys_write              8934
sys_futex              6789
sys_mmap               234
sys_clock_gettime      189
```

Interpretación:
- **epoll_wait alto:** Normal — OpenSearch usa NIO con epoll para I/O asíncrono
- **futex alto:** Contención de locks. Puede indicar thread pool saturado
- **mmap alto:** Allocaciones frecuentes. Puede indicar churn de segments por merges

## Cuándo Usar eBPF con OpenSearch

| ✅ Usar eBPF cuando... | ❌ No necesario cuando... |
|---|---|
| Los dashboards de OpenSearch no explican la latencia percibida | Los slow logs ya identifican claramente las queries lentas |
| Sospechas que el problema es de red o disco, no de query | El problema es claramente un mapping o query mal escrita |
| Necesitas perfilar sin reiniciar ni reconfigurar OpenSearch | Puedes habilitar `profile: true` en la query |
| Operas en bare metal o VMs y tienes acceso root | Estás en un managed service sin acceso al host |
| Quieres implementar network policies sin overhead | Ya tienes iptables/security groups configurados y funcionan |

## Herramientas Recomendadas

| Herramienta | Uso con OpenSearch |
|-------------|-------------------|
| `biosnoop` / `biotop` | I/O de disco por shard/segment file |
| `tcplife` / `tcpretrans` | Latencia y retransmisiones entre nodos |
| `runqlat` | Scheduling latency de threads OpenSearch |
| `funccount` | Profiling de syscalls |
| `bpftrace` | Scripts custom para investigaciones específicas |
| Cilium | Network policies eBPF-based en Kubernetes |
| Falco | Detección de anomalías en runtime (accesos inesperados) |

## Resumen

- eBPF no extiende OpenSearch internamente — opera a nivel de kernel observando desde fuera
- Cubre la brecha entre lo que OpenSearch reporta (query time) y lo que el usuario experimenta (latencia total)
- `biosnoop` identifica I/O problems por shard, `tcplife` revela latencia de red entre nodos, `runqlat` detecta CPU starvation
- Cilium implementa network policies para OpenSearch en Kubernetes con overhead mínimo
- Combina eBPF con Profile API y slow logs para debugging end-to-end: kernel → JVM → query engine
- Para profundizar en eBPF, consulta ["eBPF: Macizo y Conciso"](https://github.com/mercadoalex/ebpf_macizo)
