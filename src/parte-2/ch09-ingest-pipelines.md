# Ingest Pipelines

> **Opinión del autor:** Las ingest pipelines eliminan la necesidad de un servicio externo de transformación para el 80% de los casos. Si estás levantando un Logstash o un script Python solo para parsear logs y enriquecer campos, probablemente puedes hacerlo dentro de OpenSearch. Menos infraestructura, menos puntos de fallo, menos latencia entre ingesta y disponibilidad de búsqueda.

## Objetivo

Dominar las ingest pipelines de OpenSearch para transformar, enriquecer y normalizar datos en tiempo de indexación sin código externo.

## Prerequisitos

- Capítulo 8: Estrategias de indexación (templates e ISM)
- Capítulo 3: Operaciones CRUD con la REST API

## Contenido

### Qué es una Ingest Pipeline

Una ingest pipeline es una secuencia de procesadores que transforma un documento antes de indexarlo. El documento entra crudo, pasa por cada procesador en orden, y sale transformado.

```mermaid
graph LR
    A[Documento original] --> B[Procesador 1]
    B --> C[Procesador 2]
    C --> D[Procesador N]
    D --> E[Documento indexado]
```

Los casos de uso más comunes: parsear logs no estructurados con grok, extraer fechas de strings, renombrar campos para estandarizar schemas, y enriquecer documentos con campos calculados.

### Crear una Pipeline

```bash
curl -sk -X PUT "https://localhost:9200/_ingest/pipeline/logs-pipeline" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "description": "Pipeline para parsear logs de aplicación",
  "processors": [
    {
      "grok": {
        "field": "message",
        "patterns": ["%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}"]
      }
    },
    {
      "date": {
        "field": "timestamp",
        "formats": ["ISO8601"],
        "target_field": "@timestamp"
      }
    },
    {
      "remove": {
        "field": "timestamp"
      }
    },
    {
      "lowercase": {
        "field": "level"
      }
    }
  ]
}'
```

Esta pipeline: extrae timestamp y level del mensaje con grok, convierte el timestamp a fecha, elimina el campo temporal, y normaliza el level a minúsculas.

> 📁 Código fuente: [`code/ch09/01-create-pipeline.sh`](../../code/ch09/01-create-pipeline.sh)

### Probar con _simulate

Antes de aplicar una pipeline a datos reales, pruébala con `_simulate`:

```bash
curl -sk -X POST "https://localhost:9200/_ingest/pipeline/logs-pipeline/_simulate" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "docs": [
    {
      "_source": {
        "message": "2024-03-15T10:30:45.123Z ERROR Connection timeout to database"
      }
    },
    {
      "_source": {
        "message": "2024-03-15T10:31:00.456Z INFO Request processed successfully"
      }
    }
  ]
}'
```

La respuesta muestra el documento transformado sin indexarlo. Úsalo como unit test para tus pipelines.

> 📁 Código fuente: [`code/ch09/02-simulate.sh`](../../code/ch09/02-simulate.sh)

### Procesadores Esenciales

#### grok — Parsear texto no estructurado

Grok extrae campos de texto usando patrones regex con nombres. OpenSearch incluye patrones predefinidos para logs comunes.

```json
{
  "grok": {
    "field": "message",
    "patterns": ["%{IP:client_ip} - %{USER:user} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:method} %{URIPATHPARAM:request}\""]
  }
}
```

Patrones comunes: `%{IP}`, `%{TIMESTAMP_ISO8601}`, `%{LOGLEVEL}`, `%{WORD}`, `%{GREEDYDATA}`, `%{NUMBER}`.

#### dissect — Parseo por delimitadores

Más rápido que grok para formatos con estructura fija. No usa regex — solo delimitadores.

```json
{
  "dissect": {
    "field": "message",
    "pattern": "%{timestamp} [%{level}] %{service}: %{log_message}"
  }
}
```

Usa `dissect` cuando tu formato es predecible. Usa `grok` cuando necesitas flexibilidad regex. Dissect es 5-10x más rápido que grok en benchmarks.

#### set — Agregar campos

```json
{
  "set": {
    "field": "environment",
    "value": "production"
  }
}
```

Acepta templates con `{{{campo}}}` para valores dinámicos:

```json
{
  "set": {
    "field": "full_name",
    "value": "{{{first_name}}} {{{last_name}}}"
  }
}
```

#### rename — Renombrar campos

```json
{
  "rename": {
    "field": "hostname",
    "target_field": "host.name"
  }
}
```

Útil para normalizar schemas de distintas fuentes al mismo mapping.

#### convert — Cambiar tipos

```json
{
  "convert": {
    "field": "status_code",
    "type": "integer"
  }
}
```

Tipos soportados: `integer`, `long`, `float`, `double`, `string`, `boolean`, `auto`.

#### script — Lógica custom con Painless

```json
{
  "script": {
    "source": "ctx.duration_ms = ctx.duration_ns / 1000000"
  }
}
```

Los scripts acceden al documento via `ctx`. Úsalos cuando ningún procesador built-in cubre tu caso.

### Manejo de Errores

Si un procesador falla, el documento no se indexa por defecto. Usa `on_failure` para manejar errores gracefully:

```json
{
  "grok": {
    "field": "message",
    "patterns": ["%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}"],
    "on_failure": [
      {
        "set": {
          "field": "_tags",
          "value": ["_grok_parse_failure"]
        }
      }
    ]
  }
}
```

El documento se indexa con un tag que indica el fallo. Puedes buscar documentos con errores de parseo filtrando por `_tags`.

> 📁 Código fuente: [`code/ch09/03-error-handling.sh`](../../code/ch09/03-error-handling.sh)

### Aplicar Pipeline a un Índice

Dos formas de usar una pipeline:

**1. En cada request de indexación:**

```bash
curl -sk -X POST "https://localhost:9200/logs/_doc?pipeline=logs-pipeline" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{"message": "2024-03-15T10:30:45.123Z ERROR Connection timeout"}'
```

**2. Como pipeline por defecto del índice (via template):**

```json
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "default_pipeline": "logs-pipeline"
    }
  }
}
```

Con `default_pipeline`, todo documento que llegue al índice pasa por la pipeline automáticamente.

> 📁 Código fuente: [`code/ch09/04-apply-pipeline.sh`](../../code/ch09/04-apply-pipeline.sh)

## Cuándo Usar y Cuándo NO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|---|---|
| Parsear logs no estructurados (grok, dissect) | La transformación requiere datos de fuentes externas (APIs, DBs) |
| Normalizar campos entre fuentes heterogéneas | El procesamiento es tan complejo que necesita un lenguaje completo |
| Agregar campos calculados simples | El volumen de ingesta es extremo y cada ms de latencia importa |
| Convertir tipos de datos antes de indexar | Necesitas lógica condicional compleja con múltiples branches |
| Eliminar campos sensibles antes de almacenar | El enriquecimiento necesita lookup en otro índice |

## Ejercicios

1. Crea una pipeline que parsee logs de Apache (`%{COMMONAPACHELOG}`) y extraiga IP, método, path, status code y bytes. Pruébala con `_simulate` antes de indexar.

2. Crea una pipeline con `dissect` que procese líneas CSV: `"producto,precio,cantidad,fecha"`. Convierte precio a float, cantidad a integer, y fecha a tipo date.

3. Implementa manejo de errores: crea una pipeline que intente parsear con grok. Si falla, use `on_failure` para mover el mensaje original a un campo `raw_message` y agregar un tag `_parse_error`.

4. Configura un index template que aplique tu pipeline automáticamente a todo índice `app-logs-*`. Indexa 5 documentos y verifica que se transformaron correctamente.

## Resumen

- Las ingest pipelines transforman documentos en tiempo de indexación sin código externo
- `grok` parsea texto flexible con regex; `dissect` parsea formatos fijos sin regex (5-10x más rápido)
- `_simulate` es tu herramienta de testing — nunca apliques una pipeline sin probarla primero
- `on_failure` permite manejar errores sin perder documentos
- `default_pipeline` en el index template automatiza la aplicación de pipelines
- Los procesadores se ejecutan en orden — el output de uno es el input del siguiente
