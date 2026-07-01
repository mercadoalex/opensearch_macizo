# Mappings y Analizadores

> **Opinión del autor:** El mapping es el contrato entre tus datos y OpenSearch. Dejarlo en manos del mapping dinámico es como desplegar código sin tests — funciona hasta que no funciona. En producción, siempre define mappings explícitos. El mapping dinámico es útil para exploración rápida, pero si llega a producción sin supervisión, vas a pagar con reindexaciones dolorosas.

## Objetivo

Entender cómo OpenSearch almacena y analiza datos. Dominar los tipos de datos fundamentales, configurar analizadores de texto, y saber cuándo usar mapping dinámico vs explícito.

## Prerequisitos

- Capítulo 2: Laboratorio levantado y funcionando
- Capítulo 3: Familiaridad con operaciones CRUD y la REST API

## Contenido

### Qué es un Mapping

Un mapping define la estructura de un índice. Especifica qué campos existen, qué tipo de dato tiene cada uno, y cómo se analizan los campos de texto. Es el equivalente a un schema en bases de datos relacionales.

La diferencia clave: en OpenSearch, una vez que un campo tiene un tipo asignado, no puedes cambiarlo sin reindexar todos los documentos. Piensa dos veces antes de indexar el primer documento.

```json
GET productos/_mapping
```

### Tipos de Datos Fundamentales

OpenSearch soporta decenas de tipos. Estos seis cubren el 90% de los casos de uso:

#### text

Para contenido que necesita búsqueda full-text. El texto se analiza (tokeniza, normaliza, aplica stemming) antes de almacenarse en el índice invertido.

```json
{
  "descripcion": {
    "type": "text",
    "analyzer": "spanish"
  }
}
```

Usa `text` para: descripciones, títulos, contenido de artículos, logs. OpenSearch descompone el valor en tokens individuales para búsqueda.

#### keyword

Para valores exactos que no deben analizarse. Se almacenan tal cual — sin tokenización, sin normalización.

```json
{
  "categoria": {
    "type": "keyword"
  }
}
```

Usa `keyword` para: IDs, códigos postales, emails, estados (activo/inactivo), tags, valores para filtros exactos y agregaciones.

#### integer y float

Tipos numéricos para valores enteros y decimales respectivamente.

```json
{
  "cantidad_stock": { "type": "integer" },
  "precio": { "type": "float" }
}
```

OpenSearch también ofrece `long`, `double`, `short`, y `byte`. Usa el tipo más pequeño que cubra tu rango de valores — menos memoria, mejor rendimiento.

#### boolean

Valores verdadero/falso. Acepta `true`, `false`, `"true"`, `"false"`.

```json
{
  "disponible": { "type": "boolean" }
}
```

Parece trivial, pero es crítico para filtros. Un `term` query sobre un boolean es la forma más eficiente de filtrar documentos activos/inactivos.

#### date

Fechas y timestamps. Por defecto acepta formato ISO 8601, pero puedes configurar formatos custom.

```json
{
  "fecha_creacion": {
    "type": "date",
    "format": "yyyy-MM-dd||yyyy-MM-dd HH:mm:ss||epoch_millis"
  }
}
```

Internamente OpenSearch almacena las fechas como `epoch_millis`. El formato solo define cómo las parsea al indexar y cómo las presenta al buscar.

### Mapping Explícito

El mapping explícito se define al crear el índice. Tú decides los tipos, analizadores, y configuraciones de cada campo.

```bash
curl -sk -X PUT https://localhost:9200/productos \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "nombre": {
        "type": "text",
        "analyzer": "spanish",
        "fields": {
          "keyword": {
            "type": "keyword",
            "ignore_above": 256
          }
        }
      },
      "categoria": { "type": "keyword" },
      "precio": { "type": "float" },
      "cantidad_stock": { "type": "integer" },
      "disponible": { "type": "boolean" },
      "fecha_creacion": {
        "type": "date",
        "format": "yyyy-MM-dd||yyyy-MM-dd HH:mm:ss||epoch_millis"
      }
    }
  }
}'
```

El patrón `fields` con subcampo `keyword` es común. Te permite buscar full-text sobre `nombre` y al mismo tiempo hacer agregaciones exactas sobre `nombre.keyword`.

> 📁 Código fuente: [`code/ch04/01-explicit-mapping.sh`](../../code/ch04/01-explicit-mapping.sh)

### Mapping Dinámico

Si indexas un documento sin mapping previo, OpenSearch infiere los tipos automáticamente. Esto se llama mapping dinámico.

```bash
curl -sk -X POST https://localhost:9200/ventas-demo/_doc/1 \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "producto": "Laptop Gamer X",
  "precio": 1299.99,
  "cantidad": 5,
  "en_oferta": true,
  "fecha_venta": "2024-03-15",
  "codigo_postal": "28001"
}'
```

OpenSearch analiza el JSON y asigna tipos:

| Campo | Valor enviado | Tipo inferido |
|-------|---------------|---------------|
| `producto` | `"Laptop Gamer X"` | text + keyword |
| `precio` | `1299.99` | float |
| `cantidad` | `5` | long |
| `en_oferta` | `true` | boolean |
| `fecha_venta` | `"2024-03-15"` | date |
| `codigo_postal` | `"28001"` | text + keyword |

Los problemas saltan a la vista. El código postal se mapeó como `text` — OpenSearch lo tokenizará y buscará coincidencias parciales. Pero un código postal es un valor exacto: debería ser `keyword`. Este tipo de errores silenciosos se acumulan y explotan cuando necesitas hacer agregaciones o filtros exactos.

> 📁 Código fuente: [`code/ch04/04-dynamic-mapping.sh`](../../code/ch04/04-dynamic-mapping.sh)

### Analizadores de Texto

Un analizador transforma texto crudo en tokens indexables. Todo campo `text` pasa por un analizador. El proceso tiene tres etapas:

```
Texto original → [Character Filters] → [Tokenizer] → [Token Filters] → Tokens
```

1. **Character Filters**: Limpian el texto antes de tokenizar (e.g., eliminar HTML)
2. **Tokenizer**: Divide el texto en tokens (palabras individuales)
3. **Token Filters**: Transforman tokens (lowercase, stemming, eliminar stopwords)

#### El analizador standard

Por defecto, OpenSearch usa el analizador `standard`:

- Tokeniza por espacios y puntuación
- Convierte a minúsculas
- No aplica stemming ni elimina stopwords

```bash
curl -sk -X POST https://localhost:9200/_analyze \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "analyzer": "standard",
  "text": "Los servidores están funcionando correctamente"
}'
```

Resultado: `["los", "servidores", "están", "funcionando", "correctamente"]`

Cinco tokens. Incluye stopwords ("los") y conserva conjugaciones ("están", "funcionando").

#### El analizador spanish

El analizador `spanish` está optimizado para texto en español:

- Elimina stopwords españolas (el, la, los, de, en, que...)
- Aplica stemming (reduce palabras a su raíz)
- Convierte a minúsculas

```bash
curl -sk -X POST https://localhost:9200/_analyze \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "analyzer": "spanish",
  "text": "Los servidores están funcionando correctamente"
}'
```

Resultado: `["servidor", "funcionar", "correct"]`

Tres tokens. Sin stopwords, con raíces. Buscar "servidores" o "servidor" encontrará este documento. Eso es stemming en acción.

> 📁 Código fuente: [`code/ch04/02-analyze-text.sh`](../../code/ch04/02-analyze-text.sh)

#### La API _analyze

La API `_analyze` es tu herramienta de diagnóstico. Úsala para entender exactamente qué tokens genera un analizador antes de indexar datos.

Puedes probar contra un índice existente (usa la configuración del campo):

```bash
curl -sk -X POST https://localhost:9200/productos/_analyze \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "field": "nombre",
  "text": "Laptops gaming de última generación"
}'
```

O probar combinaciones específicas de tokenizer y filtros:

```bash
curl -sk -X POST https://localhost:9200/_analyze \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "tokenizer": "standard",
  "filter": ["lowercase", "asciifolding"],
  "text": "OpenSearch es RÁPIDO y potente"
}'
```

Resultado: `["opensearch", "es", "rapido", "y", "potente"]`. El filtro `asciifolding` convierte "RÁPIDO" a "rapido" — útil cuando tus usuarios buscan sin tildes.

### Analizadores Personalizados

Cuando los analizadores built-in no cubren tu caso, creas uno custom. Se define en los `settings` del índice:

```bash
curl -sk -X PUT https://localhost:9200/blog \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "analysis": {
      "char_filter": {
        "html_cleaner": {
          "type": "html_strip",
          "escaped_tags": ["code"]
        }
      },
      "filter": {
        "spanish_stop": {
          "type": "stop",
          "stopwords": "_spanish_"
        },
        "spanish_stemmer": {
          "type": "stemmer",
          "language": "spanish"
        }
      },
      "analyzer": {
        "blog_spanish": {
          "type": "custom",
          "char_filter": ["html_cleaner"],
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "spanish_stop", "spanish_stemmer"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "titulo": { "type": "text", "analyzer": "blog_spanish" },
      "contenido": { "type": "text", "analyzer": "blog_spanish" }
    }
  }
}'
```

Este analizador `blog_spanish`:
1. Elimina tags HTML (excepto `<code>`)
2. Tokeniza con `standard`
3. Convierte a minúsculas
4. Elimina tildes (`asciifolding`)
5. Elimina stopwords en español
6. Aplica stemming español

Resultado de analizar `"Los <b>Servidores</b> están funcionando"`:

Tokens: `["servidor", "funcionar"]`

Los tags HTML desaparecen, las stopwords se eliminan, y las palabras se reducen a su raíz. Exactamente lo que necesitas para un blog con contenido HTML.

> 📁 Código fuente: [`code/ch04/03-custom-analyzer.sh`](../../code/ch04/03-custom-analyzer.sh)

### Multi-fields: Lo Mejor de Dos Mundos

Un patrón esencial en OpenSearch es mapear el mismo campo con múltiples tipos usando `fields`:

```json
{
  "nombre": {
    "type": "text",
    "analyzer": "spanish",
    "fields": {
      "keyword": {
        "type": "keyword",
        "ignore_above": 256
      }
    }
  }
}
```

Esto te da:
- `nombre` → Búsqueda full-text con stemming
- `nombre.keyword` → Agregaciones, sorting, filtros exactos

Sin multi-fields tendrías que elegir entre buscar y agregar. Con ellos, tienes ambos sobre el mismo dato.

### Limitaciones del Mapping

Tres reglas que no puedes romper:

1. **No puedes cambiar el tipo de un campo existente.** Si `precio` es `float`, no puedes convertirlo a `integer`. La única salida es reindexar.

2. **Puedes añadir campos nuevos**, pero no modificar los existentes. Un mapping crece, nunca se encoge.

3. **El mapping dinámico es aditivo.** Cada campo nuevo que aparece en un documento se agrega permanentemente al mapping. En un índice de logs con campos dinámicos, tu mapping puede crecer a miles de campos — esto consume memoria del cluster state.

## Cuándo Usar y Cuándo NO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|---|---|
| **Mapping explícito** | |
| Defines un índice para producción | Exploras datos nuevos sin schema conocido |
| Necesitas control total sobre análisis de texto | Prototipos rápidos donde los tipos no importan |
| Optimizas uso de memoria (tipos precisos) | Datos efímeros que se borran en horas |
| **Mapping dinámico** | |
| Exploras un dataset por primera vez | Cualquier entorno de producción |
| Prototipos y pruebas rápidas | Índices con retención mayor a días |
| Carga inicial de datos para evaluar estructura | Cuando necesitas agregaciones numéricas precisas |
| **Analizador custom** | |
| Contenido HTML o con caracteres especiales | Campos keyword (no se analizan) |
| Idioma específico (español) con stemming | Datos que solo necesitan filtros exactos |
| Requisitos de búsqueda sin tildes o case-insensitive | Cuando el analizador built-in ya cubre tu caso |

## Ejercicios

1. Crea un índice `empleados` con mapping explícito que incluya: `nombre` (text con analizador spanish), `departamento` (keyword), `salario` (float), `activo` (boolean), `fecha_ingreso` (date). Indexa 3 documentos y verifica el mapping con `GET empleados/_mapping`.

2. Usa la API `_analyze` para comparar cómo tokeniza la frase "Las búsquedas rápidas en OpenSearch son eficientes" con los analizadores `standard`, `spanish`, y `simple`. Anota las diferencias.

3. Crea un analizador custom que: elimine HTML, aplique `lowercase`, use `edge_ngram` como token filter (min_gram: 2, max_gram: 10). Pruébalo con la frase "Buscador" y verifica que genera tokens parciales para autocompletado.

4. Indexa un documento en un índice nuevo sin mapping previo. Incluye un campo `codigo` con valor `"001"` y un campo `monto` con valor `"1500.50"` (como string). Revisa el mapping generado y explica por qué esto causaría problemas en producción.

## Resumen

- Un mapping define la estructura y tipos de datos de un índice — es irreversible una vez creado
- Los seis tipos fundamentales (`text`, `keyword`, `integer`, `float`, `boolean`, `date`) cubren la mayoría de casos
- Los analizadores transforman texto en tokens: character filters → tokenizer → token filters
- El analizador `spanish` aplica stemming y elimina stopwords — ideal para contenido en español
- Los analizadores custom combinan componentes individuales para casos específicos (HTML, autocompletado)
- La API `_analyze` es tu herramienta de diagnóstico para entender la tokenización
- El mapping dinámico infiere tipos pero genera problemas silenciosos — usa mapping explícito en producción
- Multi-fields (`text` + `keyword`) te dan búsqueda full-text y agregaciones sobre el mismo campo
