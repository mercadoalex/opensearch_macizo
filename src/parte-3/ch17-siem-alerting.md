# SIEM y Alerting

> **Opinión del autor:** OpenSearch como SIEM es la opción con mejor relación costo-funcionalidad para equipos medianos. No compite con Splunk Enterprise en features de compliance corporativo, pero cubre detección de amenazas, correlación y alerting sin pagar por GB ingestado. Si tu presupuesto de seguridad es limitado pero tus requisitos de detección son reales, OpenSearch Security Analytics es la respuesta.

## Objetivo

Implementar OpenSearch como SIEM: configurar detectores de amenazas con reglas Sigma, correlation engine para correlacionar eventos, y alerting para notificaciones automáticas.

## Prerequisitos

- Capítulo 14: Seguridad (roles, permisos, audit logging)
- Laboratorio con perfil `ninja`

## Contenido

### Security Analytics: Visión General

OpenSearch Security Analytics incluye:

| Componente | Función |
|-----------|---------|
| Detectors | Ejecutan reglas contra logs en tiempo real |
| Rules | Reglas tipo Sigma para detectar amenazas |
| Findings | Alertas generadas cuando una regla matchea |
| Correlation Engine | Correlaciona findings entre log sources |
| Alerting | Notificaciones a Slack, email, webhook |

### Reglas Sigma

Las reglas Sigma son un formato estándar open-source para describir detecciones. OpenSearch las importa nativamente.

```yaml
# Regla: Detección de brute force SSH
title: SSH Brute Force Attempt
status: stable
description: Detecta múltiples intentos fallidos de login SSH
logsource:
  product: linux
  service: auth
detection:
  selection:
    event.action: "authentication_failure"
    process.name: "sshd"
  condition: selection | count() > 5
  timeframe: 5m
level: high
tags:
  - attack.credential_access
  - attack.t1110
```

OpenSearch convierte estas reglas a queries internas que se ejecutan contra índices de logs.

> 📁 Código fuente: [`code/ch17/sigma-rules/ssh-brute-force.yml`](../../code/ch17/sigma-rules/ssh-brute-force.yml)

### Crear un Detector

```bash
curl -sk -X POST "https://localhost:9200/_plugins/_security_analytics/detectors" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "name": "linux-auth-detector",
  "enabled": true,
  "detector_type": "linux",
  "schedule": {
    "period": {"interval": 1, "unit": "MINUTES"}
  },
  "inputs": [
    {
      "detector_input": {
        "indices": ["logs-auth-*"],
        "custom_rules": [],
        "pre_packaged_rules": [
          {"id": "rule-ssh-brute-force"}
        ]
      }
    }
  ],
  "triggers": [
    {
      "name": "high-severity-trigger",
      "severity": "1",
      "condition": {
        "script": {"source": "ctx.results[0].hits.total.value > 0"}
      },
      "actions": [
        {
          "name": "slack-notification",
          "destination_id": "slack-webhook-dest",
          "message_template": {
            "source": "Alerta: {{ctx.results[0].hits.total.value}} detecciones de brute force SSH"
          }
        }
      ]
    }
  ]
}'
```

### Alerting: Monitors y Destinations

El sistema de alerting funciona independientemente de Security Analytics. Puedes crear alertas sobre cualquier condición:

```bash
# Crear destination (webhook)
curl -sk -X POST "https://localhost:9200/_plugins/_alerting/destinations" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "name": "slack-ops",
  "type": "slack",
  "slack": {
    "url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  }
}'
```

```bash
# Crear monitor
curl -sk -X POST "https://localhost:9200/_plugins/_alerting/monitors" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "name": "high-error-rate",
  "type": "monitor",
  "enabled": true,
  "schedule": {"period": {"interval": 5, "unit": "MINUTES"}},
  "inputs": [{
    "search": {
      "indices": ["logs-*"],
      "query": {
        "size": 0,
        "query": {"bool": {"filter": [
          {"term": {"level": "error"}},
          {"range": {"@timestamp": {"gte": "now-5m"}}}
        ]}},
        "aggs": {"error_count": {"value_count": {"field": "_id"}}}
      }
    }
  }],
  "triggers": [{
    "name": "too-many-errors",
    "severity": "2",
    "condition": {"script": {"source": "ctx.results[0].aggregations.error_count.value > 100"}},
    "actions": [{
      "name": "notify-slack",
      "destination_id": "slack-ops-id",
      "message_template": {"source": "⚠️ {{ctx.results[0].aggregations.error_count.value}} errores en últimos 5 min"}
    }]
  }]
}'
```

> 📁 Código fuente: [`code/ch17/01-alerting.sh`](../../code/ch17/01-alerting.sh)

### Correlation Engine

Correlaciona findings de múltiples fuentes para detectar ataques multi-etapa:

```bash
curl -sk -X POST "https://localhost:9200/_plugins/_security_analytics/correlation/rules" \
  -u admin:Admin123! \
  -H "Content-Type: application/json" \
  -d '{
  "name": "brute-force-then-lateral-movement",
  "correlate": [
    {
      "index": "logs-auth-*",
      "query": "rule.name:SSH_Brute_Force",
      "category": "credential_access"
    },
    {
      "index": "logs-network-*",
      "query": "rule.name:Unusual_Lateral_Movement",
      "category": "lateral_movement"
    }
  ],
  "time_window": 30,
  "time_unit": "MINUTES"
}'
```

Si un brute force SSH es seguido de lateral movement dentro de 30 minutos, la correlación genera un finding de alta severidad.

## Cuándo Usar y Cuándo NO

| ✅ Usar OpenSearch como SIEM... | ❌ NO usar cuando... |
|---|---|
| Presupuesto limitado para herramientas de seguridad | Necesitas certificaciones específicas que solo proveen vendors enterprise |
| Ya centralizas logs en OpenSearch | Tu organización tiene <100 endpoints y un EDR basta |
| Necesitas reglas Sigma compatibles con tu equipo SOC | El equipo no tiene capacidad para operar y mantener reglas |
| Quieres correlación de eventos cross-source | Requieres SOAR avanzado con playbooks automatizados |

## Ejercicios

1. Crea un monitor de alerting que detecte más de 50 errores en 5 minutos en el índice `logs-*`. Configura un webhook como destino.

2. Escribe una regla Sigma que detecte logins desde IPs no conocidas. Impórtala en un detector y genera datos de prueba para disparar la alerta.

3. Configura una regla de correlación entre "login fallido" y "acceso a datos sensibles" dentro de una ventana de 10 minutos.

## Resumen

- OpenSearch Security Analytics implementa SIEM con detección tipo Sigma, correlación y alerting
- Las reglas Sigma son estándar open-source — portables entre herramientas
- Los detectores ejecutan reglas contra índices de logs en intervalos configurables
- El correlation engine detecta ataques multi-etapa correlacionando findings entre log sources
- El sistema de alerting soporta Slack, email, webhooks y custom scripts
- Ideal para equipos con presupuesto limitado que necesitan detección real de amenazas
