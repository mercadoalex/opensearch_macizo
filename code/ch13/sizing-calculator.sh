#!/usr/bin/env bash
# sizing-calculator.sh — Calcula storage y nodos para un clúster OpenSearch.
# Uso: bash sizing-calculator.sh

echo "=== OpenSearch Sizing Calculator ==="
echo ""

# Parámetros (modifica según tu caso)
INGESTA_DIARIA_GB=50
RETENCION_DIAS=30
REPLICAS=1
OVERHEAD=1.2
DISCO_POR_NODO_GB=2000
UTILIZACION_MAXIMA=0.85
SHARD_IDEAL_GB=40

STORAGE=$(echo "$INGESTA_DIARIA_GB * $RETENCION_DIAS * (1 + $REPLICAS) * $OVERHEAD" | bc)
NODOS_DATA=$(echo "$STORAGE / ($DISCO_POR_NODO_GB * $UTILIZACION_MAXIMA)" | bc)
SHARDS_PRIMARIOS=$(echo "$INGESTA_DIARIA_GB * $RETENCION_DIAS / $SHARD_IDEAL_GB" | bc)

echo "Parámetros:"
echo "  Ingesta diaria: ${INGESTA_DIARIA_GB} GB"
echo "  Retención: ${RETENCION_DIAS} días"
echo "  Réplicas: ${REPLICAS}"
echo "  Overhead: ${OVERHEAD}x"
echo ""
echo "Resultados:"
echo "  Storage total: ${STORAGE} GB"
echo "  Nodos data necesarios: ${NODOS_DATA} (disco ${DISCO_POR_NODO_GB} GB, ${UTILIZACION_MAXIMA} util.)"
echo "  Shards primarios: ~${SHARDS_PRIMARIOS} (target ${SHARD_IDEAL_GB} GB/shard)"
echo ""
echo "Recomendación:"
echo "  3 cluster_manager + ${NODOS_DATA} data nodes"
