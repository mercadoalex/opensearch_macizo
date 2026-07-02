# Pendientes — OpenSearch: Macizo y Conciso

## Deploy

- [ ] Configurar GitHub Pages source como "GitHub Actions" en Settings → Pages del repo
- [ ] Verificar que el workflow de deploy pase correctamente después del cambio
- [ ] Confirmar URL pública del libro: https://mercadoalex.github.io/opensearch_macizo/

## Contenido

- [ ] Revisar los 18 capítulos secuencialmente (tono, flow, ejercicios)
- [ ] Verificar que todos los scripts en `code/` corran contra el laboratorio Docker
- [ ] Completar datos de prueba faltantes en capítulos 9-18 (`sample-data.json` donde aplique)
- [ ] Revisar glosario: confirmar que cubre todos los términos nuevos de cada capítulo

## Mejoras futuras

- [ ] Agregar generación PDF (evaluar mdbook-pdf o Pandoc post-proceso)
- [ ] Crear Makefile con targets: `build`, `serve`, `test-examples`, `clean`
- [ ] Smoke test en CI: levantar Docker Compose novato y correr scripts de ch02-ch04
- [ ] Agregar search index para la versión HTML (mdBook lo soporta nativamente)
