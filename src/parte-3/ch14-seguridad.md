# Seguridad

> **Opinión del autor:** La seguridad de OpenSearch no es opcional — viene habilitada por defecto desde 2.x. El Security Plugin es potente pero tiene curva de aprendizaje. No desactives la seguridad "para simplificar" — aprende a configurarla bien una vez y reutiliza los roles. Un clúster expuesto sin auth es un incidente de seguridad esperando suceder.

## Objetivo

Configurar autenticación, autorización, roles granulares y cifrado en OpenSearch. Entender el Security Plugin, RBAC, y opciones de integración con IdPs externos.

## Prerequisitos

- Capítulo 13: Arquitectura de producción (roles de nodos, certificados TLS)
- Perfil `ninja` del laboratorio (TLS habilitado)

## Contenido

### El Security Plugin

El Security Plugin es un componente integrado que maneja autenticación, autorización, audit logging y cifrado. Está habilitado por defecto en OpenSearch 2.x.

Componentes principales:

| Componente | Función |
|-----------|---------|
| Internal Users DB | Usuarios locales con hashes bcrypt |
| Roles | Permisos sobre índices, clúster y tenants |
| Role Mappings | Asociación entre usuarios/backend_roles y roles |
| Action Groups | Agrupaciones de permisos reutilizables |
| Auth Backends | HTTP basic, SAML, OIDC, LDAP, proxy |
| Audit Logs | Registro de accesos y cambios |

### Usuarios Internos

Crear un usuario con la Security API:

```bash
curl -sk -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/app-reader" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "password": "Reader#2024!",
  "backend_roles": ["readall"],
  "attributes": {
    "team": "backend",
    "env": "production"
  }
}'
```

> 📁 Código fuente: [`code/ch14/01-create-users.sh`](../../code/ch14/01-create-users.sh)

### Roles y Permisos (RBAC)

Un rol define qué puede hacer un usuario sobre qué recursos:

```bash
curl -sk -X PUT "https://localhost:9200/_plugins/_security/api/roles/logs-reader" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "cluster_permissions": ["cluster_composite_ops_ro"],
  "index_permissions": [
    {
      "index_patterns": ["logs-*"],
      "allowed_actions": ["read", "search"]
    }
  ]
}'
```

Luego mapear el rol al usuario:

```bash
curl -sk -X PUT "https://localhost:9200/_plugins/_security/api/rolesmapping/logs-reader" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "users": ["app-reader"],
  "backend_roles": ["readall"]
}'
```

#### Action Groups predefinidos

| Action Group | Permisos incluidos |
|-------------|-------------------|
| `read` | get, mget, search, msearch |
| `write` | index, bulk, update, delete |
| `crud` | read + write |
| `manage` | create_index, manage_aliases, indices_monitor |
| `cluster_all` | Todos los permisos de clúster |

> 📁 Código fuente: [`code/ch14/02-roles.sh`](../../code/ch14/02-roles.sh)

### Document-Level Security (DLS)

Restringe qué documentos puede ver un usuario basándose en una query:

```bash
curl -sk -X PUT "https://localhost:9200/_plugins/_security/api/roles/team-backend-logs" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "index_permissions": [
    {
      "index_patterns": ["logs-*"],
      "dls": "{\"term\": {\"service\": \"backend\"}}",
      "allowed_actions": ["read"]
    }
  ]
}'
```

El usuario solo ve documentos donde `service: backend`. DLS se aplica transparentemente — el usuario no sabe que existen otros documentos.

### Field-Level Security (FLS)

Restringe qué campos puede ver un usuario:

```bash
curl -sk -X PUT "https://localhost:9200/_plugins/_security/api/roles/logs-no-pii" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "index_permissions": [
    {
      "index_patterns": ["logs-*"],
      "fls": ["~user_email", "~ip_address"],
      "allowed_actions": ["read"]
    }
  ]
}'
```

El prefijo `~` excluye campos. El usuario ve todos los campos excepto `user_email` e `ip_address`.

### Autenticación Externa (SAML/OIDC)

Para integrar con Identity Providers corporativos, configura backends en `config.yml`:

```yaml
# config.yml del Security Plugin
config:
  dynamic:
    authc:
      oidc_auth:
        http_enabled: true
        transport_enabled: false
        order: 1
        http_authenticator:
          type: openid
          config:
            openid_connect_url: "https://idp.example.com/.well-known/openid-configuration"
            subject_key: "email"
            roles_key: "groups"
        authentication_backend:
          type: noop
```

Los claims del token OIDC se mapean a backend_roles. Luego usas role_mappings para asociar grupos del IdP a roles de OpenSearch.

> 📁 Código fuente: [`code/ch14/03-oidc-config.yml`](../../code/ch14/03-oidc-config.yml)

### Cifrado

Dos niveles de cifrado:

**En tránsito (TLS):** Comunicación entre nodos y entre clientes/nodos. Configurado con los certificados del Capítulo 2.4.

**En reposo:** OpenSearch no cifra datos en disco por defecto. Opciones:
- Cifrado a nivel de filesystem (LUKS, dm-crypt)
- Cifrado del volumen (AWS EBS encryption, GCP disk encryption)
- `index.codec: best_compression` + cifrado de volumen (recomendado)

### Audit Logging

Registra quién hizo qué y cuándo:

```bash
curl -sk -X PUT "https://localhost:9200/_plugins/_security/api/audit/config" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "enabled": true,
  "audit": {
    "enable_rest": true,
    "disabled_rest_categories": ["AUTHENTICATED"],
    "enable_transport": false,
    "resolve_indices": true,
    "log_request_body": true
  }
}'
```

## Cuándo Usar y Cuándo NO

| ✅ Configurar siempre... | ❌ Evitar... |
|---|---|
| Autenticación (nunca exponer sin auth) | Desactivar security plugin "para simplificar" |
| Roles con mínimo privilegio por aplicación | Un usuario admin compartido entre servicios |
| DLS cuando datos contienen info multi-tenant | DLS sobre índices con queries ya lentas (agrega overhead) |
| Audit logging para compliance | Loguear request bodies en producción de alto volumen (performance) |

## Ejercicios

1. Crea tres usuarios: `writer-app`, `reader-dashboard`, `admin-ops`. Asigna roles que permitan: escritura solo en `app-*`, lectura solo en `metrics-*`, y acceso completo respectivamente.

2. Configura DLS para que el usuario `team-frontend` solo vea logs donde `service: frontend`. Verifica que al buscar con ese usuario, los logs de otros servicios no aparecen.

3. Crea un rol con FLS que excluya campos sensibles (`password_hash`, `credit_card`). Mapéalo a un usuario y verifica que los campos no aparecen en las respuestas.

## Resumen

- El Security Plugin viene habilitado por defecto — aprende a configurarlo, no a desactivarlo
- RBAC con roles granulares es la base: cluster_permissions + index_permissions
- DLS restringe documentos; FLS restringe campos — multitenancy sin partición física
- SAML y OIDC integran con IdPs corporativos via claims → backend_roles → role_mappings
- Audit logging registra accesos para compliance — filtra categorías para no saturar logs
- Cifrado en tránsito (TLS) es obligatorio; cifrado en reposo se delega al filesystem/volumen
