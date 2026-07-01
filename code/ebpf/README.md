# Apéndice: Observando OpenSearch con eBPF

Scripts de ejemplo para profiling y observabilidad a nivel de kernel.

## Prerequisitos

- Linux kernel 4.9+ (recomendado 5.x+)
- bcc-tools: `apt install bpfcc-tools` o `yum install bcc-tools`
- bpftrace: `apt install bpftrace`
- Acceso root (sudo)
- OpenSearch corriendo localmente o en container con acceso al host

## Archivos

| Archivo | Herramienta | Qué observa |
|---------|-------------|-------------|
| `01-biosnoop-opensearch.sh` | biosnoop (bcc) | Disk I/O por operación |
| `02-tcp-latency.bt` | bpftrace | Latencia TCP de OpenSearch |
| `03-runqlat-opensearch.sh` | runqlat (bcc) | Scheduling latency (CPU starvation) |
| `04-cilium-policy.yaml` | Cilium | Network policy para Kubernetes |

## Nota sobre Docker

Si OpenSearch corre en Docker, los scripts eBPF se ejecutan en el **host**, no dentro del contenedor. El PID que necesitas es el del proceso Java visto desde el host:

```bash
# Encontrar PID del proceso OpenSearch dentro de Docker
docker top opensearch-node1 | grep java
```

## Referencia

Para profundizar en eBPF: [eBPF: Macizo y Conciso](https://github.com/mercadoalex/ebpf_macizo)
