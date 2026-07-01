# Laboratorio OpenSearch — Requisitos y Uso

Este directorio contiene el laboratorio Docker Compose del libro "OpenSearch: Macizo y Conciso" y todos los ejemplos de código organizados por capítulo.

## Requisitos del Sistema Host

| Perfil        | Docker Engine | Docker Compose | RAM mínima |
|---------------|---------------|----------------|------------|
| `novato`      | ≥ 24.0        | ≥ 2.20         | 4 GB       |
| `intermedio`  | ≥ 24.0        | ≥ 2.20         | 8 GB       |
| `ninja`       | ≥ 24.0        | ≥ 2.20         | 12 GB      |

### Verificar versiones instaladas

```bash
docker --version
docker compose version
```

Si tu versión de Docker Compose es inferior a 2.20, los perfiles (`--profile`) no funcionarán correctamente. Actualiza Docker Desktop o instala el plugin de Compose por separado.

## Uso del Laboratorio

### Levantar un perfil

```bash
docker compose --profile <perfil> up
```

Donde `<perfil>` es uno de: `novato`, `intermedio`, `ninja`.

Ejemplo para el nivel novato:

```bash
docker compose --profile novato up
```

El laboratorio estará listo cuando el healthcheck pase. Puedes verificarlo manualmente:

```bash
curl -sk https://localhost:9200/_cluster/health | jq .
```

OpenSearch Dashboards estará disponible en: [http://localhost:5601](http://localhost:5601)

### Destruir el entorno

Para detener los contenedores y eliminar todos los volúmenes (estado limpio):

```bash
docker compose --profile <perfil> down -v
```

Ejemplo:

```bash
docker compose --profile novato down -v
```

Esto elimina contenedores, redes y volúmenes asociados. No quedan datos residuales.

## Alternativa sin Docker: Sandbox Cloud Gratuito

Si no tienes Docker instalado o tu máquina no cumple los requisitos mínimos, puedes usar un sandbox cloud gratuito para replicar los ejercicios del nivel Novato.

### Amazon OpenSearch Playground

Amazon ofrece un entorno interactivo gratuito donde puedes ejecutar queries contra un clúster OpenSearch sin instalar nada:

1. Accede a [Amazon OpenSearch Playground](https://playground.opensearch.org)
2. Usa la consola de Dev Tools integrada (equivalente a Dashboards)
3. Ejecuta las queries de los capítulos 1-5 directamente en el playground

**Limitaciones del Playground:**
- No puedes modificar la configuración del clúster
- Los datos se reinician periódicamente
- Solo cubre ejercicios del nivel Novato (CRUD, mappings, queries básicas)
- No soporta perfiles `intermedio` ni `ninja`

### Binder / Gitpod (alternativa con Docker en la nube)

Si necesitas un entorno completo con Docker pero no tienes recursos locales:

1. Abre el repositorio en [Gitpod](https://gitpod.io) o un entorno similar basado en la nube
2. El workspace incluye Docker preinstalado
3. Ejecuta `docker compose --profile novato up` como lo harías localmente

## Estructura de Directorios

```
code/
├── docker-compose.yml       # Laboratorio con profiles
├── README.md                # Este archivo
├── dashboards-setup/        # Scripts de configuración automática de Dashboards
├── certs/                   # Certificados TLS (perfil ninja, generados localmente)
├── ch01/                    # Ejemplos del Capítulo 1
├── ch02/                    # Ejemplos del Capítulo 2
├── ...
└── ch18/                    # Ejemplos del Capítulo 18
```

Cada subdirectorio `chNN/` contiene los ejemplos ejecutables del capítulo correspondiente con su propio `README.md` de instrucciones.

## Versión de OpenSearch

Todos los ejemplos están probados contra **OpenSearch 2.17.0**. Esta es la versión fija usada en el `docker-compose.yml` para garantizar reproducibilidad.
