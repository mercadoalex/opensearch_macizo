#!/bin/bash
# Capítulo 8: Aliases — Lectura y Escritura
# Prerequisito: Clúster OpenSearch corriendo (perfil novato o superior)

BASE_URL="https://localhost:9200"
AUTH="admin:Admin123!"

echo "=== 1. Crear índices para demostrar aliases ==="
# Simular un escenario real: índices de logs por fecha
curl -sk -X PUT "$BASE_URL/logs-2024.03.01" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "message": { "type": "text" },
      "level": { "type": "keyword" }
    }
  }
}'

echo ""
curl -sk -X PUT "$BASE_URL/logs-2024.03.02" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "message": { "type": "text" },
      "level": { "type": "keyword" }
    }
  }
}'

echo ""
curl -sk -X PUT "$BASE_URL/logs-2024.03.03" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "message": { "type": "text" },
      "level": { "type": "keyword" }
    }
  }
}'

echo ""
echo "=== 2. Crear alias de lectura sobre múltiples índices ==="
# Un alias de lectura agrupa varios índices bajo un solo nombre
curl -sk -X POST "$BASE_URL/_aliases" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "actions": [
    { "add": { "index": "logs-2024.03.01", "alias": "logs-marzo" } },
    { "add": { "index": "logs-2024.03.02", "alias": "logs-marzo" } },
    { "add": { "index": "logs-2024.03.03", "alias": "logs-marzo" } }
  ]
}'
# Respuesta esperada: {"acknowledged":true}
# Ahora puedes buscar en "logs-marzo" y OpenSearch busca en los 3 índices

echo ""
echo "=== 3. Buscar usando el alias de lectura ==="
# Primero indexar datos de prueba
curl -sk -X POST "$BASE_URL/logs-2024.03.01/_doc" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"@timestamp":"2024-03-01T10:00:00Z","message":"Servidor iniciado","level":"INFO"}'

echo ""
curl -sk -X POST "$BASE_URL/logs-2024.03.02/_doc" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"@timestamp":"2024-03-02T14:30:00Z","message":"Error de conexión","level":"ERROR"}'

echo ""
curl -sk -X POST "$BASE_URL/logs-2024.03.03/_doc" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"@timestamp":"2024-03-03T08:15:00Z","message":"Backup completado","level":"INFO"}'

echo ""
# Buscar a través del alias — busca en los 3 índices
curl -sk "$BASE_URL/logs-marzo/_search?pretty" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} } }'
# Respuesta esperada: 3 hits (uno por cada índice)

echo ""
echo "=== 4. Alias con filtro — solo errores ==="
curl -sk -X POST "$BASE_URL/_aliases" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "actions": [
    {
      "add": {
        "index": "logs-2024.03.*",
        "alias": "logs-errores",
        "filter": {
          "term": { "level": "ERROR" }
        }
      }
    }
  ]
}'
# Respuesta esperada: {"acknowledged":true}
# Buscar en "logs-errores" solo devuelve documentos con level:ERROR

echo ""
echo "=== 5. Alias de escritura (write index) ==="
# Solo UN índice puede ser el write index de un alias
curl -sk -X POST "$BASE_URL/_aliases" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "actions": [
    {
      "add": {
        "index": "logs-2024.03.03",
        "alias": "logs-current",
        "is_write_index": true
      }
    },
    {
      "add": {
        "index": "logs-2024.03.01",
        "alias": "logs-current"
      }
    },
    {
      "add": {
        "index": "logs-2024.03.02",
        "alias": "logs-current"
      }
    }
  ]
}'
# Respuesta esperada: {"acknowledged":true}

echo ""
echo "=== 6. Escribir usando el alias ==="
# Los documentos nuevos van al write index (logs-2024.03.03)
curl -sk -X POST "$BASE_URL/logs-current/_doc" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"@timestamp":"2024-03-03T22:00:00Z","message":"Documento via alias","level":"INFO"}'
# Respuesta esperada: {"_index":"logs-2024.03.03",...}
# Nota: el _index en la respuesta confirma que fue al write index

echo ""
echo "=== 7. Swap atómico de alias (zero-downtime) ==="
# Mover el alias de un índice viejo a uno nuevo — operación atómica
curl -sk -X POST "$BASE_URL/_aliases" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
  "actions": [
    { "remove": { "index": "logs-2024.03.03", "alias": "logs-current", "is_write_index": true } },
    { "add":    { "index": "logs-2024.03.03", "alias": "logs-current" } },
    { "add":    { "index": "logs-2024.03.03", "alias": "logs-archive" } }
  ]
}'
# Respuesta esperada: {"acknowledged":true}
# El swap es atómico: no hay momento donde el alias no exista

echo ""
echo "=== 8. Listar aliases ==="
curl -sk "$BASE_URL/_cat/aliases?v&s=alias" -u "$AUTH"
# Muestra todos los aliases, sus índices asociados y filtros

echo ""
echo "Done. Aliases configurados y verificados."
