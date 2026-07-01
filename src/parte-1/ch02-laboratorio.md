# Tu Primer Laboratorio

> **Opinión del autor:** Docker Compose es la forma más rápida de tener OpenSearch corriendo sin contaminar tu máquina. No necesitas un clúster en la nube para aprender. Si no puedes levantar contenedores localmente, busca un sandbox cloud — pero el aprendizaje real viene de romper cosas en tu propia terminal.

## Objetivo

Levantar un clúster OpenSearch de un nodo con Dashboards en menos de 5 minutos. Verificar que funciona con un solo comando.

## Prerequisitos

- Capítulo 1: Entender qué es OpenSearch y para qué sirve
- Docker Engine ≥ 24.0 instalado
- Docker Compose ≥ 2.20 instalado
- Al menos 4 GB de RAM disponibles

## Contenido

### Levantar el laboratorio

El perfil `novato` inicia un nodo OpenSearch y una instancia de Dashboards. Un comando, sin configuración adicional:

```bash
docker compose --profile novato up
```

Docker descarga las imágenes (primera vez toma unos minutos), levanta los contenedores, y ejecuta healthchecks automáticamente. Cuando veas logs de OpenSearch diciendo `"started"`, el nodo está listo.

El laboratorio usa OpenSearch `2.17.0`. Esta versión está fija para garantizar que todos los ejemplos del libro funcionen sin sorpresas.

### Verificar el clúster

La forma canónica de saber si OpenSearch vive es consultar `_cluster/health`. Usa curl con `-sk` porque el nodo usa TLS auto-firmado:

```bash
curl -sk https://localhost:9200/_cluster/health \
  -u admin:Admin123! | python3 -m json.tool
```

Respuesta esperada (campos clave):

```json
{
    "cluster_name": "opensearch-macizo",
    "status": "green",
    "number_of_nodes": 1,
    "number_of_data_nodes": 1
}
```

El campo `status` debe ser `green` o `yellow`. Si ves `red`, algo falló — revisa los logs con `docker compose logs opensearch-node1`.

> 📁 Código fuente: [`code/ch02/verify-cluster.sh`](../../code/ch02/verify-cluster.sh)

### Acceder a Dashboards

OpenSearch Dashboards corre en el puerto 5601. Abre tu navegador:

```
http://localhost:5601
```

Credenciales por defecto:
- **Usuario:** `admin`
- **Contraseña:** `Admin123!`

Dashboards tarda unos segundos más que el nodo en estar disponible. Si ves un error de conexión, espera 30 segundos y recarga.

### Explorar Dev Tools

Una vez dentro de Dashboards, navega a **Management → Dev Tools**. Esta consola es tu mejor amigo para el resto del libro.

Prueba esta query directamente en Dev Tools:

```json
GET _cluster/health
```

La consola ejecuta la petición contra el nodo local y muestra la respuesta formateada. No necesitas curl para queries rápidas — Dev Tools autocompeta endpoints y valida JSON.

Prueba también listar los índices existentes:

```json
GET _cat/indices?v
```

Verás los índices internos del sistema. En los próximos capítulos crearás los tuyos.

### Detener y limpiar

Cuando termines de practicar, destruye el entorno completamente:

```bash
docker compose --profile novato down -v
```

El flag `-v` elimina los volúmenes. Esto borra todos los datos indexados. La próxima vez que levantes el lab, empiezas desde cero.

Si solo quieres detener sin borrar datos, omite `-v`:

```bash
docker compose --profile novato down
```

## Cuándo Usar y Cuándo NO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|---|---|
| Aprendes OpenSearch por primera vez | Necesitas un entorno de producción |
| Pruebas queries y mappings rápidamente | Manejas datos reales sensibles |
| Sigues los ejercicios de este libro | Requieres alta disponibilidad |
| Quieres experimentar sin riesgo | Tu máquina tiene menos de 4 GB de RAM libres |

## Ejercicios

1. Levanta el laboratorio y verifica que `_cluster/health` devuelve `status: green`. Anota cuánto tiempo tardó desde `docker compose up` hasta el primer response exitoso.

2. Desde Dev Tools en Dashboards, ejecuta `GET _nodes/stats/os` y revisa cuánta memoria está usando el nodo. Compara con la configuración `OPENSEARCH_JAVA_OPTS` en el `docker-compose.yml`.

3. Detén el laboratorio con `down -v`, vuelve a levantarlo, y confirma que los datos se borraron ejecutando `GET _cat/indices?v` (no debe haber índices de usuario).

## Resumen

- El perfil `novato` levanta un nodo OpenSearch + Dashboards con un solo comando
- `_cluster/health` es el endpoint canónico para verificar el estado del clúster
- Dashboards expone Dev Tools: una consola interactiva para queries REST
- `docker compose down -v` destruye todo y deja el sistema limpio
- El laboratorio usa TLS auto-firmado — siempre usa `-sk` con curl
