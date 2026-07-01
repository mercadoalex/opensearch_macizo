# Puente: De Novato a Intermedio

> **Opinión del autor:** Si llegaste hasta aquí, ya tienes las bases. Sabes levantar un clúster, indexar datos, buscar y definir mappings. Ahora viene lo interesante: queries complejas, agregaciones y patrones que separan un prototipo de un sistema en producción. No avances al siguiente nivel si algún concepto de esta Parte te quedó flojo — vuelve al capítulo correspondiente.

## Objetivo

Consolidar los conceptos clave de la Parte I, verificar que dominas los prerequisitos necesarios para el nivel intermedio, y aplicar tus conocimientos en un ejercicio integrador.

## Lo que aprendiste en Parte I

### Capítulo 1 — ¿Qué es OpenSearch?

OpenSearch es un motor de búsqueda y analítica distribuido, fork de Elasticsearch 7.10.2, bajo licencia Apache 2.0. Su arquitectura se basa en clústeres de nodos con datos distribuidos en shards primarios y réplicas.

Cubre cuatro pilares: búsqueda full-text, observabilidad, SIEM y analítica operacional. Incluye seguridad, alerting y ML sin costo de licencia adicional.

### Capítulo 2 — Tu Primer Laboratorio

Levantaste un clúster OpenSearch de un nodo con Docker Compose usando el perfil `novato`. Verificaste su estado con `_cluster/health` y exploraste Dev Tools en Dashboards.

Aprendiste a destruir el entorno con `down -v` para empezar limpio. El laboratorio usa OpenSearch 2.17.0 con TLS auto-firmado.

### Capítulo 3 — CRUD con la REST API

Dominaste las cuatro operaciones fundamentales: crear índices, indexar documentos, buscar y eliminar. Usaste `match` para texto analizado, `term` para valores exactos y `range` para intervalos.

Cargaste datos masivos con la Bulk API. Actualizaste documentos con `doc` parcial y scripts Painless. Entendiste que OpenSearch no actualiza in-place sino que reemplaza documentos internamente.

### Capítulo 4 — Mappings y Analizadores

Definiste mappings explícitos con los seis tipos fundamentales: `text`, `keyword`, `integer`, `float`, `boolean` y `date`. Entendiste por qué el mapping dinámico genera problemas en producción.

Configuraste analizadores de texto: `standard`, `spanish` y custom. Usaste la API `_analyze` para diagnosticar tokenización. Aprendiste el patrón multi-fields para combinar búsqueda full-text con agregaciones.

## Checklist de Prerequisitos para Parte II

Antes de avanzar al nivel intermedio, verifica que dominas cada concepto. Si alguno te genera dudas, regresa al capítulo indicado.

| # | Concepto | ¿Lo dominas? | Capítulo de referencia |
|---|----------|:---:|---|
| 1 | Sabes qué es un clúster, un nodo, un shard y una réplica | ☐ | Capítulo 1 |
| 2 | Puedes levantar y destruir el laboratorio con Docker Compose | ☐ | Capítulo 2 |
| 3 | Sabes verificar el estado del clúster con `_cluster/health` | ☐ | Capítulo 2 |
| 4 | Puedes usar Dev Tools en Dashboards para ejecutar queries | ☐ | Capítulo 2 |
| 5 | Dominas las operaciones CRUD con curl: PUT, GET, POST, DELETE | ☐ | Capítulo 3 |
| 6 | Sabes la diferencia entre `match` (texto analizado) y `term` (valor exacto) | ☐ | Capítulo 3 |
| 7 | Puedes cargar datos masivos con la Bulk API | ☐ | Capítulo 3 |
| 8 | Entiendes los seis tipos de datos fundamentales y cuándo usar cada uno | ☐ | Capítulo 4 |
| 9 | Sabes definir un mapping explícito al crear un índice | ☐ | Capítulo 4 |
| 10 | Comprendes cómo los analizadores transforman texto en tokens | ☐ | Capítulo 4 |
| 11 | Puedes usar multi-fields para combinar búsqueda y agregaciones | ☐ | Capítulo 4 |

Si marcaste los 11 puntos, estás listo para el nivel intermedio.

## Ejercicio de Transición: Diseña un Índice para E-commerce

Este ejercicio integra todo lo aprendido en la Parte I y te prepara para los temas de la Parte II. Diseña el mapping para un catálogo de productos de una tienda online real.

### Requisitos del índice

Tu tienda vende productos electrónicos. Necesitas:

- Buscar productos por nombre y descripción en español (full-text)
- Filtrar por categoría exacta, rango de precio y disponibilidad
- Ordenar resultados por precio o fecha de publicación
- Agregar productos por categoría para mostrar conteos en la navegación

### Tu tarea

1. **Define el mapping explícito** para un índice `catalogo-tienda` con al menos estos campos:
   - `nombre`: búsqueda full-text en español + keyword para sorting
   - `descripcion`: búsqueda full-text con analizador spanish
   - `categoria`: valor exacto para filtros y agregaciones
   - `precio`: numérico para rangos y sorting
   - `disponible`: filtro booleano
   - `fecha_publicacion`: ordenamiento temporal
   - `tags`: lista de keywords para filtros múltiples

2. **Crea el índice** en tu laboratorio con el mapping diseñado.

3. **Carga al menos 10 productos** usando la Bulk API. Incluye variedad en categorías, rangos de precio y disponibilidad.

4. **Ejecuta estas queries** para validar tu diseño:
   - Buscar por texto en `nombre` (usa `match`)
   - Filtrar por `categoria` exacta (usa `term`)
   - Filtrar por rango de `precio` entre 100 y 500 (usa `range`)
   - Combinar filtro de `disponible: true` con búsqueda de texto

5. **Reflexiona:** La cuarta query requiere combinar condiciones. Con lo que sabes hoy (`match`, `term`, `range`), ¿cómo combinarías dos filtros en una sola query? En el Capítulo 6 aprenderás `bool` queries — la herramienta que resuelve exactamente este problema.

### Solución del mapping

```bash
curl -sk -X PUT "https://localhost:9200/catalogo-tienda" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "analysis": {
      "analyzer": {
        "spanish_with_folding": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "spanish_stop", "spanish_stemmer"]
        }
      },
      "filter": {
        "spanish_stop": { "type": "stop", "stopwords": "_spanish_" },
        "spanish_stemmer": { "type": "stemmer", "language": "spanish" }
      }
    }
  },
  "mappings": {
    "properties": {
      "nombre": {
        "type": "text",
        "analyzer": "spanish_with_folding",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "descripcion": { "type": "text", "analyzer": "spanish_with_folding" },
      "categoria": { "type": "keyword" },
      "precio": { "type": "float" },
      "disponible": { "type": "boolean" },
      "fecha_publicacion": { "type": "date", "format": "yyyy-MM-dd" },
      "tags": { "type": "keyword" }
    }
  }
}'
```

Este mapping aplica todo lo aprendido: analizador custom para español, multi-fields para búsqueda + sorting, keywords para filtros exactos, y tipos numéricos para rangos.

## Lo que viene en Parte II

El nivel intermedio te lleva de queries simples a patrones de diseño para sistemas reales. Esto es lo que cubrirás:

| Capítulo | Tema | Lo que resuelve |
|----------|------|----------------|
| 6 | Query DSL Avanzado | Combinar condiciones con `bool`, búsquedas anidadas, scoring personalizado |
| 7 | Agregaciones | Métricas, agrupaciones, pipelines — analítica real sobre tus datos |
| 8 | Estrategias de Indexación | Templates, aliases, ISM y rollover para gestionar índices a escala |
| 9 | Ingest Pipelines | Transformar datos en tiempo de indexación sin código externo |
| 10 | Rendimiento de Búsqueda | Caches, routing, shard allocation y tuning de relevancia |
| 11 | Clientes Oficiales | Integración con Python, Java y Go en aplicaciones reales |

El ejercicio de transición ya te mostró la limitación: combinar filtros requiere `bool` queries. Ese es exactamente el punto de partida del Capítulo 6.

## Resumen

- La Parte I te dio los fundamentos: arquitectura, laboratorio, operaciones CRUD y mappings
- Los 11 prerequisitos del checklist son necesarios para abordar el nivel intermedio con fluidez
- El ejercicio de transición integra todos los conceptos y expone la necesidad de queries compuestas
- La Parte II escala desde queries simples hacia patrones de diseño para sistemas en producción
- Si algún punto del checklist te genera inseguridad, es mejor consolidar ahora que arrastrar lagunas
