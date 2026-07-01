# OpenSearch: Macizo y Conciso

Referencia técnica opinionada sobre OpenSearch — desde tus primeros índices hasta arquitecturas de producción.

## Estructura del Proyecto

```
src/           → Código fuente Markdown del libro (mdBook)
code/          → Ejemplos de código ejecutables por capítulo
theme/         → Tema CSS personalizado
.github/       → Workflows de CI/CD
```

## Build Local

```bash
# Instalar mdBook y plugins
cargo install mdbook mdbook-mermaid mdbook-pdf

# Construir el libro
mdbook build

# Servir localmente con hot-reload
mdbook serve
```

## Laboratorio

```bash
# Perfil novato (1 nodo)
docker compose --profile novato up

# Destruir y limpiar
docker compose --profile novato down -v
```

## Licencia

Todos los derechos reservados.
