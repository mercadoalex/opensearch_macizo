# Query DSL Avanzado

> **Opinión del autor:** El Query DSL es donde OpenSearch deja de ser un almacén de documentos y se convierte en un motor de relevancia. El `match` básico te lleva lejos, pero las `bool` queries, `function_score` y la búsqueda semántica son lo que separa una barra de búsqueda mediocre de una experiencia que anticipa lo que el usuario necesita. Si solo dominas una cosa de este capítulo, que sean las bool queries — el 80% de las búsquedas en producción las usan.

## Objetivo

Dominar las queries avanzadas del Query DSL de OpenSearch. Al terminar este capítulo sabrás construir búsquedas compuestas con lógica booleana, consultar objetos anidados, buscar en múltiples campos, personalizar el scoring, y ejecutar búsquedas semánticas con vectores.

## Prerequisitos

- Capítulo 4: Mappings y tipos de datos (especialmente `text`, `keyword`, `nested`)
- Capítulo 5: Conceptos de búsqueda básica y relevancia
- Laboratorio levantado con perfil `novato` o `intermedio`

## Contenido

### Bool Queries: La Navaja Suiza

La `bool` query combina múltiples condiciones con lógica booleana. Es la query más usada en producción porque modela cualquier combinación de requisitos de búsqueda.

Tiene cuatro cláusulas:

| Cláusula | Función | Afecta score |
|----------|---------|:---:|
| `must` | El documento DEBE cumplir esta condición | ✅ Sí |
| `filter` | El documento DEBE cumplir, pero sin calcular score | ❌ No |
| `should` | El documento PUEDE cumplir (bonus de relevancia) | ✅ Sí |
| `must_not` | El documento NO DEBE cumplir | ❌ No |

La diferencia entre `must` y `filter` es sutil pero crítica para rendimiento. `filter` cachea resultados porque no necesita calcular relevancia. Usa `filter` para condiciones binarias (sí/no) como rangos de fecha o estados.

#### must + filter: El patrón más común

Buscar artículos que contengan "búsqueda" en su contenido, filtrados por categoría "avanzado":

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "match": { "contenido": "búsqueda" } }
      ],
      "filter": [
        { "term": { "categoria": "avanzado" } }
      ]
    }
  }
}'
```

El `must` calcula relevancia sobre el contenido. El `filter` descarta documentos que no son "avanzado" sin gastar CPU en scoring. En índices con millones de documentos, esta distinción reduce latencia de forma medible.

#### must_not: Exclusión sin impacto en score

Excluir documentos de seguridad de los resultados de María García:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "term": { "autor": "María García" } }
      ],
      "must_not": [
        { "term": { "categoria": "seguridad" } }
      ]
    }
  }
}'
```

`must_not` es ideal para excluir contenido flaggeado, documentos archivados, o resultados que el usuario ya vio. No contribuye al score — solo filtra.

#### should con minimum_should_match

`should` por defecto es opcional cuando hay un `must` presente. Si necesitas que al menos N condiciones del `should` se cumplan, usa `minimum_should_match`:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "should": [
        { "match": { "contenido": "OpenSearch" } },
        { "match": { "contenido": "búsqueda" } },
        { "match": { "contenido": "vectores" } }
      ],
      "minimum_should_match": 2
    }
  }
}'
```

Con `minimum_should_match: 2`, el documento debe cumplir al menos 2 de las 3 condiciones. Es perfecto para búsquedas tipo "artículos que cubran al menos dos de estos temas".

#### Bool anidado: Queries complejas

Las `bool` queries se anidan. Puedes meter una `bool` dentro de otra para expresar lógica arbitraria:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "term": { "categoria": "avanzado" } }
      ],
      "filter": [
        {
          "range": {
            "fecha_publicacion": {
              "gte": "2024-01-01",
              "lte": "2024-03-31"
            }
          }
        }
      ],
      "should": [
        { "range": { "valoracion": { "gte": 4.5 } } },
        { "range": { "visitas": { "gte": 3000 } } }
      ],
      "minimum_should_match": 1
    }
  }
}'
```

Esta query dice: "artículos avanzados del Q1 2024 que tengan alta valoración O muchas visitas". La lógica es clara porque cada cláusula tiene un propósito definido.

> 📁 Código fuente: [`code/ch06/01-bool-queries.sh`](../../code/ch06/01-bool-queries.sh)

### Nested Queries: Objetos con Identidad Propia

En OpenSearch, los objetos JSON se aplanan por defecto. Si un documento tiene un array de objetos, los campos pierden su relación interna. El tipo `nested` resuelve esto almacenando cada objeto como un documento Lucene separado, invisible al usuario pero consultable de forma independiente.

¿Cuándo necesitas `nested`? Cuando tienes arrays de objetos y necesitas consultar campos relacionados dentro del mismo objeto. Sin `nested`, buscar "comentario de pedro con texto sobre producción" podría devolver un documento donde pedro comentó algo diferente y otro usuario mencionó producción.

#### El mapping nested

El índice `articulos` tiene comentarios como tipo `nested`:

```json
{
  "comentarios": {
    "type": "nested",
    "properties": {
      "usuario": { "type": "keyword" },
      "texto": { "type": "text", "analyzer": "spanish" },
      "fecha": { "type": "date" }
    }
  }
}
```

Cada comentario se almacena como subdocumento independiente. Esto permite consultar "el comentario donde usuario=pedro Y texto contiene producción" sin falsos positivos.

#### Nested query básica

Buscar artículos donde "pedro" dejó un comentario:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "nested": {
      "path": "comentarios",
      "query": {
        "term": { "comentarios.usuario": "pedro" }
      }
    }
  }
}'
```

El `path` indica qué campo nested consultar. Sin el wrapper `nested`, OpenSearch trataría los campos como objetos planos y la consulta podría dar resultados incorrectos.

#### inner_hits: Ver qué coincidió

Por defecto, la nested query te dice que el documento padre coincidió, pero no cuál objeto nested específico. Con `inner_hits` ves exactamente qué comentario(s) matchearon:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "nested": {
      "path": "comentarios",
      "query": {
        "match": { "comentarios.texto": "producción" }
      },
      "inner_hits": {
        "highlight": {
          "fields": {
            "comentarios.texto": {}
          }
        }
      }
    }
  }
}'
```

`inner_hits` devuelve los objetos nested que coincidieron, con highlight opcional. Es esencial para UIs donde muestras "este comentario es relevante" dentro de un artículo.

#### Combinando nested con bool

La nested query se integra naturalmente con `bool`. Buscar artículos avanzados que tengan comentarios de "carlos":

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": [
        { "term": { "categoria": "avanzado" } }
      ],
      "filter": [
        {
          "nested": {
            "path": "comentarios",
            "query": {
              "term": { "comentarios.usuario": "carlos" }
            }
          }
        }
      ]
    }
  }
}'
```

El `must` busca por categoría (campo del documento padre). El `filter` usa una nested query para verificar que al menos un comentario sea de carlos. Ambas condiciones deben cumplirse.

> 📁 Código fuente: [`code/ch06/02-nested-queries.sh`](../../code/ch06/02-nested-queries.sh)

### Multi-Match: Búsqueda en Múltiples Campos

`multi_match` ejecuta la misma búsqueda contra varios campos simultáneamente. Es la alternativa limpia a construir un `bool` con múltiples `should` sobre el mismo término.

Tiene varios tipos que controlan cómo se combinan los scores:

| Tipo | Comportamiento | Caso de uso |
|------|---------------|-------------|
| `best_fields` | Score del campo que mejor coincide | Búsqueda general (default) |
| `most_fields` | Suma scores de todos los campos | Sinónimos en campos distintos |
| `cross_fields` | Trata múltiples campos como uno | Nombre + apellido, título + subtítulo |
| `phrase_prefix` | Coincide con prefix del último término | Autocompletado |

#### best_fields con boost

El tipo por defecto. Usa el score del campo con mejor coincidencia. Con `^N` puedes dar más peso a un campo:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "optimización rendimiento",
      "fields": ["titulo^3", "contenido"],
      "type": "best_fields"
    }
  }
}'
```

`titulo^3` significa que una coincidencia en el título vale 3x más que en el contenido. Refleja la realidad: si el título contiene tu término, el artículo probablemente trata sobre eso. Si solo lo menciona en el cuerpo, es menos relevante.

#### cross_fields: Campos como uno solo

Cuando la información está distribuida entre campos, `cross_fields` los trata como un campo unificado:

```bash
curl -sk -X POST https://localhost:9200/productos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "laptop profesional",
      "fields": ["nombre", "descripcion"],
      "type": "cross_fields",
      "operator": "and"
    }
  }
}'
```

Con `operator: "and"`, TODOS los términos deben aparecer, pero pueden estar en campos diferentes. "laptop" en nombre y "profesional" en descripción es un match válido. Sin `cross_fields`, necesitarías que ambos términos estén en el mismo campo.

#### phrase_prefix: Autocompletado

Ideal para search-as-you-type. Coincide con el prefix del último término:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "búsqueda sem",
      "fields": ["titulo^2", "contenido"],
      "type": "phrase_prefix"
    }
  }
}'
```

"búsqueda sem" encuentra "Búsqueda semántica con vectores" porque "sem" es prefix de "semántica". El usuario aún no terminó de escribir, pero ya ve resultados relevantes.

#### tie_breaker: Equilibrar campos secundarios

Con `best_fields`, los campos que no ganaron se ignoran completamente. `tie_breaker` les da participación parcial:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "multi_match": {
      "query": "seguridad permisos autenticación",
      "fields": ["titulo^3", "contenido", "tags^2"],
      "type": "best_fields",
      "tie_breaker": 0.3
    }
  }
}'
```

Con `tie_breaker: 0.3`, el score final es: `score(mejor_campo) + 0.3 * score(otros_campos)`. Valor 0 ignora campos secundarios. Valor 1 los suma completos (equivale a `most_fields`). El rango útil está entre 0.1 y 0.4.

> 📁 Código fuente: [`code/ch06/03-multi-match.sh`](../../code/ch06/03-multi-match.sh)

### Function Score: Control Total sobre Relevancia

`function_score` te permite manipular el score de los resultados usando funciones matemáticas, valores de campos del documento, o scripts custom. Es la herramienta para cuando BM25 no captura tu noción de "relevante".

Casos de uso típicos:
- Boostear documentos recientes (decay temporal)
- Priorizar contenido popular (visitas, likes)
- Personalizar resultados por usuario
- A/B testing con scores aleatorios

#### field_value_factor: Boost por popularidad

Usar el número de visitas como factor de relevancia:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": {
        "match": { "contenido": "OpenSearch" }
      },
      "field_value_factor": {
        "field": "visitas",
        "modifier": "log1p",
        "factor": 1.5,
        "missing": 1
      }
    }
  }
}'
```

El `modifier` controla cómo se transforma el valor:
- `none`: valor crudo (peligroso con valores altos)
- `log1p`: `log(1 + valor)` — suaviza diferencias grandes
- `sqrt`: raíz cuadrada — efecto intermedio
- `square`: cuadrado — amplifica diferencias

`missing: 1` es el fallback para documentos sin el campo. Sin esto, documentos sin visitas sacan score 0.

#### Decay functions: Relevancia temporal

Las funciones de decaimiento reducen el score según la distancia a un punto de referencia. Perfectas para "documentos recientes son más relevantes":

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": { "match_all": {} },
      "functions": [
        {
          "gauss": {
            "fecha_publicacion": {
              "origin": "2024-04-15",
              "scale": "30d",
              "offset": "5d",
              "decay": 0.5
            }
          }
        }
      ]
    }
  }
}'
```

Parámetros del decay:
- `origin`: punto de máxima relevancia (score 1.0)
- `scale`: distancia donde el score cae a `decay` (aquí, a 30 días el score es 0.5)
- `offset`: zona sin penalización alrededor del origin (5 días de gracia)
- `decay`: factor al que cae el score en el `scale` (0.5 = mitad)

Tres tipos de curva: `gauss` (campana suave), `linear` (caída constante), `exp` (caída rápida al inicio). En la práctica, `gauss` es el más útil porque da una transición natural.

#### Script score: Fórmulas custom

Cuando necesitas control total, `script_score` te permite definir fórmulas arbitrarias:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": { "match_all": {} },
      "script_score": {
        "script": {
          "source": "doc['\''valoracion'\''].value * 10 + Math.log(doc['\''visitas'\''].value + 1)"
        }
      }
    }
  }
}'
```

La fórmula `(valoración * 10) + log(visitas + 1)` combina calidad percibida con popularidad. Los scripts usan Painless, el lenguaje de scripting de OpenSearch. Tiene acceso a todos los campos del documento via `doc['campo'].value`.

Cuidado: los scripts se ejecutan por cada documento candidato. En índices grandes, un script complejo puede degradar la latencia. Mide antes de poner en producción.

#### Múltiples funciones combinadas

Puedes combinar varias funciones con `score_mode` y `boost_mode`:

```bash
curl -sk -X POST https://localhost:9200/articulos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "function_score": {
      "query": {
        "match": { "contenido": "búsqueda datos" }
      },
      "functions": [
        {
          "field_value_factor": {
            "field": "valoracion",
            "modifier": "square",
            "factor": 1.2
          },
          "weight": 2
        },
        {
          "gauss": {
            "fecha_publicacion": {
              "origin": "2024-04-15",
              "scale": "60d"
            }
          },
          "weight": 1.5
        }
      ],
      "score_mode": "sum",
      "boost_mode": "multiply",
      "max_boost": 50
    }
  }
}'
```

- `score_mode`: cómo combinar las funciones entre sí (`sum`, `multiply`, `avg`, `max`, `min`)
- `boost_mode`: cómo combinar el score de funciones con el score de la query (`multiply`, `sum`, `replace`)
- `max_boost`: tope al boost total (evita que una función domine todo)
- `weight`: peso relativo de cada función

> 📁 Código fuente: [`code/ch06/04-function-score.sh`](../../code/ch06/04-function-score.sh)

### Búsqueda Semántica: Más Allá del Texto

La búsqueda textual tradicional (BM25) encuentra documentos que contienen las palabras de la query. La búsqueda semántica encuentra documentos con significado similar, aunque no compartan palabras. "¿Cómo proteger mis APIs?" puede encontrar un documento sobre "autenticación OAuth2" sin que la query mencione OAuth.

El mecanismo: convertir texto en vectores numéricos (embeddings) donde la cercanía geométrica refleja similitud de significado. OpenSearch implementa esto con k-NN (k-Nearest Neighbors).

#### Configurar un índice con k-NN

Crear un índice habilitado para búsqueda vectorial:

```bash
curl -sk -X PUT https://localhost:9200/documentos-semanticos \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "index": { "knn": true }
  },
  "mappings": {
    "properties": {
      "titulo": { "type": "text", "analyzer": "spanish" },
      "contenido": { "type": "text", "analyzer": "spanish" },
      "embedding": {
        "type": "knn_vector",
        "dimension": 3,
        "method": {
          "name": "hnsw",
          "space_type": "cosinesimil",
          "engine": "lucene",
          "parameters": {
            "ef_construction": 128,
            "m": 16
          }
        }
      }
    }
  }
}'
```

Parámetros clave del vector:
- `dimension`: tamaño del vector (modelos reales usan 384-768)
- `space_type`: métrica de distancia (`cosinesimil`, `l2`, `linf`)
- `engine`: motor de búsqueda vectorial (`lucene`, `nmslib`, `faiss`)
- `hnsw`: algoritmo de búsqueda aproximada (rápido, buena precisión)
- `ef_construction`: calidad del grafo al indexar (más alto = más preciso, más lento)
- `m`: conexiones por nodo en el grafo HNSW

#### k-NN query básica

Buscar documentos semánticamente similares a un vector de consulta:

```bash
curl -sk -X POST https://localhost:9200/documentos-semanticos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "size": 3,
  "query": {
    "knn": {
      "embedding": {
        "vector": [0.9, 0.1, 0.1],
        "k": 3
      }
    }
  }
}'
```

`k` define cuántos vecinos más cercanos buscar. El resultado son los `k` documentos con vectores más similares al query vector. La similitud depende del `space_type` configurado — con `cosinesimil`, dos vectores apuntando en la misma dirección tienen score alto.

En producción, el vector de consulta viene de un modelo de embedding. El usuario escribe texto, el modelo lo convierte a vector, y ese vector se envía a OpenSearch. Este flujo completo se cubre en el Capítulo 16.

#### Búsqueda híbrida: Texto + Semántica

La búsqueda híbrida combina BM25 (textual) con k-NN (semántica) para capturar coincidencias exactas Y conceptuales:

```bash
curl -sk -X POST https://localhost:9200/documentos-semanticos/_search \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "size": 5,
  "query": {
    "bool": {
      "should": [
        {
          "match": {
            "contenido": {
              "query": "seguridad cifrado protección",
              "boost": 0.3
            }
          }
        },
        {
          "knn": {
            "embedding": {
              "vector": [0.2, 0.1, 0.9],
              "k": 5,
              "boost": 0.7
            }
          }
        }
      ]
    }
  }
}'
```

El `boost` en cada rama controla el balance. Con `boost: 0.7` en k-NN y `0.3` en texto, priorizas significado sobre palabras exactas. Ajusta según tu caso: catálogos de productos suelen beneficiarse más de semántica; búsquedas legales necesitan más peso textual.

#### Neural search: El flujo automatizado

OpenSearch tiene un plugin `neural_search` que automatiza la generación de embeddings. En vez de enviar vectores, envías texto y el plugin invoca un modelo registrado:

```json
{
  "query": {
    "neural": {
      "embedding_field": {
        "query_text": "¿cómo proteger mis APIs en producción?",
        "model_id": "<model-id-registrado>",
        "k": 5
      }
    }
  }
}
```

El flujo completo (registrar modelo, crear pipeline de ingestión con embeddings, y queries neurales) se detalla en el Capítulo 16 — ML y Búsqueda Vectorial.

> 📁 Código fuente: [`code/ch06/05-semantic-search.sh`](../../code/ch06/05-semantic-search.sh)

## Cuándo Usar y Cuándo NO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|---|---|
| **Bool queries** | |
| Necesitas combinar múltiples condiciones de búsqueda | Tu búsqueda es un simple match contra un campo |
| Quieres separar scoring (must) de filtrado (filter) | Solo necesitas un filtro exacto (usa term query) |
| Implementas faceted search con exclusiones | La query es tan simple que una bool agrega complejidad sin valor |
| **Nested queries** | |
| Tienes arrays de objetos con relaciones internas | Tus objetos no tienen campos correlacionados |
| Necesitas consultar campos del mismo sub-objeto | El array tiene valores simples (strings, números) |
| La integridad de cada objeto importa para la búsqueda | El overhead de documentos nested no justifica la precisión |
| **Multi-match** | |
| El usuario busca un término que puede estar en varios campos | Sabes exactamente en qué campo buscar |
| Implementas una barra de búsqueda global | Cada campo necesita lógica de búsqueda diferente |
| Quieres autocompletado con phrase_prefix | Los campos tienen analizadores incompatibles |
| **Function score** | |
| BM25 no captura tu noción de relevancia | El ranking por defecto ya satisface al usuario |
| Necesitas factores de negocio (popularidad, recencia) | No tienes datos numéricos para alimentar las funciones |
| Implementas personalización por usuario | La complejidad del scoring no justifica la mejora percibida |
| **Búsqueda semántica** | |
| El usuario busca por concepto, no por palabras exactas | Tu contenido es altamente estructurado (IDs, códigos) |
| Tienes un modelo de embedding entrenado o preentrenado | No tienes infraestructura para servir modelos ML |
| La sinonimia y paráfrasis son comunes en tus queries | La búsqueda textual ya da buenos resultados |

## Ejercicios

### Bool Queries

1. Construye una bool query que encuentre artículos publicados en 2024 que contengan "OpenSearch" en el contenido, excluyendo la categoría "operaciones", y dando bonus a los que tengan valoración mayor a 4.5. Usa las cuatro cláusulas: `must`, `filter`, `must_not`, y `should`.

2. Crea una query para el índice `productos` que encuentre items disponibles con precio entre 50 y 600, cuya descripción contenga "profesional" o "ergonómico", priorizando los de marca "TechCorp" con `should` y `boost`.

### Nested Queries

3. Usando el índice `articulos`, encuentra todos los artículos donde el usuario "ana" dejó un comentario después del 1 de marzo de 2024. Usa una nested query con bool interna y muestra los comentarios coincidentes con `inner_hits`.

4. Construye una query que combine un filtro por categoría "tutorial" con una nested query que busque comentarios que contengan la palabra "ejemplo". Verifica que los resultados solo incluyan artículos donde ambas condiciones se cumplen simultáneamente.

### Multi-Match

5. Implementa una búsqueda de autocompletado usando `phrase_prefix` que busque en los campos `titulo` (boost x3) y `contenido` del índice `articulos`. Prueba con las queries parciales "máquina", "seg", y "migr". Compara los resultados.

6. Compara los resultados de buscar "laptop gaming rendimiento" con tipos `best_fields`, `most_fields`, y `cross_fields` sobre los campos `nombre` y `descripcion` del índice `productos`. Explica por qué los scores difieren.

### Function Score

7. Crea un `function_score` para `articulos` que combine: decay gaussiano por fecha (origin hoy, scale 45 días), boost por valoración (`field_value_factor` con `sqrt`), y peso extra para artículos con más de 3000 visitas. Usa `score_mode: "sum"`.

8. Implementa un ranking personalizado para `productos` donde: productos con stock > 100 reciben weight 2, productos de marca "TechCorp" reciben weight 1.5, y el score base viene de una búsqueda por descripción. Usa `boost_mode: "replace"` y compara con `boost_mode: "multiply"`.

### Búsqueda Semántica

9. Usando el índice `documentos-semanticos`, ejecuta búsquedas k-NN con tres vectores: "seguridad" `[0.1, 0.1, 0.9]`, "infraestructura" `[0.1, 0.9, 0.1]`, y "programación" `[0.9, 0.1, 0.1]`. Verifica que los resultados reflejan la similitud esperada.

10. Implementa una búsqueda híbrida sobre `documentos-semanticos` que combine match textual con k-NN. Experimenta con boost (0.2/0.8, 0.5/0.5, 0.8/0.2) y documenta cómo cambia el ranking.

## Resumen

- Las **bool queries** combinan condiciones con `must`, `filter`, `should` y `must_not` — usa `filter` para condiciones binarias (cacheable, sin scoring)
- Las **nested queries** consultan objetos anidados preservando la relación entre sus campos — `inner_hits` revela qué sub-objetos coincidieron
- **Multi-match** busca en múltiples campos con un solo término — elige el `type` según tu caso: `best_fields` para general, `cross_fields` para información distribuida, `phrase_prefix` para autocompletado
- **Function score** manipula la relevancia con funciones: `field_value_factor` para popularidad, `gauss` decay para recencia, `script_score` para fórmulas custom
- La **búsqueda semántica** con k-NN encuentra documentos por similitud de significado usando vectores — combínala con BM25 en búsqueda híbrida para lo mejor de ambos mundos
- El patrón más robusto en producción es: `bool` + `function_score` + filtros cacheados — cubre el 95% de los casos de búsqueda avanzada
