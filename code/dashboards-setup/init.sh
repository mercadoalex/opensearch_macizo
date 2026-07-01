#!/bin/sh
# =============================================================================
# OpenSearch Dashboards — Setup automático
# Espera a que Dashboards esté disponible, luego carga:
#   - Index pattern de ejemplo (opensearch-macizo-*)
#   - Dashboard básico de ejemplo
#
# Este script se ejecuta dentro del contenedor dashboards-setup (curlimages/curl)
# Credenciales: admin / Admin123!
# =============================================================================

set -e

DASHBOARDS_URL="http://opensearch-dashboards:5601"
USER="admin"
PASS="Admin123!"
MAX_RETRIES=60
RETRY_INTERVAL=5

# --- Healthcheck: esperar a que Dashboards responda ---
echo "==> Esperando a que OpenSearch Dashboards esté disponible..."
retries=0
until curl -s -o /dev/null -w "%{http_code}" -u "${USER}:${PASS}" \
  "${DASHBOARDS_URL}/api/status" | grep -q "200"; do
  retries=$((retries + 1))
  if [ "$retries" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Dashboards no respondió después de $((MAX_RETRIES * RETRY_INTERVAL))s"
    exit 1
  fi
  echo "    Dashboards no está listo (intento ${retries}/${MAX_RETRIES}). Reintentando en ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

echo "==> Dashboards está disponible."

# --- Crear index pattern: opensearch-macizo-* ---
echo "==> Creando index pattern 'opensearch-macizo-*'..."
curl -s -X POST \
  -u "${USER}:${PASS}" \
  "${DASHBOARDS_URL}/api/saved_objects/index-pattern/opensearch-macizo" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "opensearch-macizo-*",
      "timeFieldName": "@timestamp"
    }
  }' | head -c 200
echo ""

# --- Marcar el index pattern como default ---
echo "==> Configurando index pattern por defecto..."
curl -s -X POST \
  -u "${USER}:${PASS}" \
  "${DASHBOARDS_URL}/api/opensearch-dashboards/settings" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "changes": {
      "defaultIndex": "opensearch-macizo"
    }
  }' | head -c 200
echo ""

# --- Crear dashboard de ejemplo ---
echo "==> Creando dashboard de ejemplo 'Lab OpenSearch Macizo'..."
curl -s -X POST \
  -u "${USER}:${PASS}" \
  "${DASHBOARDS_URL}/api/saved_objects/dashboard/opensearch-macizo-lab" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Lab OpenSearch Macizo",
      "description": "Dashboard de ejemplo para el laboratorio del libro OpenSearch: Macizo y Conciso",
      "panelsJSON": "[]",
      "optionsJSON": "{\"useMargins\":true,\"hidePanelTitles\":false}",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    }
  }' | head -c 200
echo ""

# --- Crear una búsqueda guardada de ejemplo ---
echo "==> Creando búsqueda guardada de ejemplo..."
curl -s -X POST \
  -u "${USER}:${PASS}" \
  "${DASHBOARDS_URL}/api/saved_objects/search/opensearch-macizo-search" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Todos los documentos - opensearch-macizo",
      "description": "Búsqueda de ejemplo que muestra todos los documentos del índice de laboratorio",
      "columns": ["_source"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"opensearch-macizo\",\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    }
  }' | head -c 200
echo ""

echo ""
echo "==> ✅ Setup de Dashboards completado exitosamente."
echo "    - Index pattern: opensearch-macizo-*"
echo "    - Dashboard: Lab OpenSearch Macizo"
echo "    - Búsqueda guardada: Todos los documentos"
echo ""
echo "    Accede a Dashboards en: http://localhost:5601"
echo "    Usuario: admin / Contraseña: Admin123!"
