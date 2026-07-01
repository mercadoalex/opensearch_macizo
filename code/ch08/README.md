# Capítulo 8: Estrategias de Indexación

Ejemplos ejecutables para index templates, aliases, ISM policies y rollover.

## Prerequisitos

- Laboratorio levantado con perfil `novato` o superior (Capítulo 2)
- Familiaridad con mappings y tipos de datos (Capítulo 4)
- Conocimiento del capítulo puente (Capítulo 5)

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `01-index-templates.sh` | Component templates y composable index templates |
| `02-aliases.sh` | Aliases de lectura y escritura |
| `03-ism-policy.sh` | Crear y aplicar ISM policies |
| `04-rollover.sh` | Rollover automático con alias y ISM |
| `05-ism-config.yml` | Configuración declarativa YAML (GitOps) |
| `06-deploy-config.sh` | Script para desplegar configuración desde YAML |
| `ism-policy.json` | Definición JSON de ISM policy reutilizable |

## Orden de ejecución

```bash
# 1. Templates (base para los demás ejemplos)
bash 01-index-templates.sh

# 2. Aliases
bash 02-aliases.sh

# 3. ISM policy
bash 03-ism-policy.sh

# 4. Rollover (depende de alias y template)
bash 04-rollover.sh

# 5. (Alternativa) Desplegar todo desde configuración YAML
bash 06-deploy-config.sh
```

## Conexión al clúster

Todos los scripts usan:

```
-sk https://localhost:9200 -u admin:Admin123!
```

## Limpieza

Para eliminar los recursos creados:

```bash
curl -sk -X DELETE https://localhost:9200/logs-*,metrics-* -u admin:Admin123!
curl -sk -X DELETE https://localhost:9200/_index_template/logs-template -u admin:Admin123!
curl -sk -X DELETE https://localhost:9200/_component_template/base-settings -u admin:Admin123!
curl -sk -X DELETE https://localhost:9200/_component_template/logs-mappings -u admin:Admin123!
curl -sk -X DELETE https://localhost:9200/_plugins/_ism/policies/logs-lifecycle -u admin:Admin123!
```
