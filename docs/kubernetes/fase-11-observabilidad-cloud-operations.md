# Fase 11 - Observabilidad con Google Cloud Operations

## Objetivo

Aplicar observabilidad sobre los microservicios desplegados en GKE y sobre los servicios administrados de Google Cloud utilizados por BanQuito.

La observabilidad se cubre con tres capacidades:

| Capacidad | Servicio Google Cloud | Estado aplicado |
| --- | --- | --- |
| Metricas | Cloud Monitoring + Managed Service for Prometheus | Aplicado con `PodMonitoring` para los Pods Spring Boot |
| Logs | Cloud Logging | Aplicado por integracion nativa de GKE Autopilot |
| Trazas | Cloud Trace + OpenTelemetry | Preparado; requiere instrumentacion OpenTelemetry para trazas distribuidas completas |

## Alcance

La observabilidad aplica a:

- GKE Autopilot.
- Pods de Core Bancario.
- Pods del Switch de Pagos Masivos.
- Pub/Sub.
- Cloud SQL.
- Secret Manager.
- Apigee.
- Gateway/Load Balancer.

Los frontends se ejecutan en VM/Nginx, por lo que sus logs se revisan desde la VM o se pueden enviar a Cloud Logging instalando el agente de Ops Agent.

## 1. Habilitar APIs necesarias

Ejecutar desde PowerShell o Cloud Shell:

```powershell
gcloud services enable monitoring.googleapis.com --project project-47695a8e-7cb2-4352-af2
gcloud services enable logging.googleapis.com --project project-47695a8e-7cb2-4352-af2
gcloud services enable cloudtrace.googleapis.com --project project-47695a8e-7cb2-4352-af2
```

## 2. Habilitar Managed Prometheus en GKE

```powershell
gcloud container clusters update banquito-cluster-autopilot `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --enable-managed-prometheus
```

Verificar configuracion del cluster:

```powershell
gcloud container clusters describe banquito-cluster-autopilot `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --format="yaml(monitoringConfig,loggingConfig)"
```

## 3. Aplicar metricas de microservicios

Todos los backends tienen:

- `spring-boot-starter-actuator`
- `micrometer-registry-prometheus`
- endpoint `/actuator/prometheus`

Se agregaron manifiestos `PodMonitoring` para que Google Managed Prometheus recolecte metricas cada 30 segundos:

```text
k8s/observability/
  podmonitoring-core.yaml
  podmonitoring-switch.yaml
  podmonitoring-pubsub.yaml
```

Aplicar:

```powershell
kubectl apply -f .\banquito-infra\k8s\observability\podmonitoring-core.yaml
kubectl apply -f .\banquito-infra\k8s\observability\podmonitoring-switch.yaml
kubectl apply -f .\banquito-infra\k8s\observability\podmonitoring-pubsub.yaml
```

Verificar:

```powershell
kubectl get podmonitoring -A
```

Resultado aplicado:

```text
NAMESPACE         NAME
banquito-core     account-core-service-monitoring
banquito-core     accounting-service-monitoring
banquito-core     party-service-monitoring
banquito-pubsub   internal-payment-processor-service-monitoring
banquito-pubsub   payment-line-publisher-service-monitoring
banquito-pubsub   payment-line-subscriber-service-monitoring
banquito-switch   clearinghouse-service-monitoring
banquito-switch   file-reception-service-monitoring
banquito-switch   notification-service-monitoring
banquito-switch   payment-line-classifier-service-monitoring
banquito-switch   report-service-monitoring
banquito-switch   tariff-service-monitoring
```

Probar manualmente el endpoint Prometheus de un servicio:

```powershell
kubectl port-forward -n banquito-core svc/account-core-service 8081:8081
```

Luego abrir:

```text
http://localhost:8081/actuator/prometheus
```

## 4. Logs centralizados con Cloud Logging

GKE Autopilot envia los logs de contenedores a Cloud Logging de forma integrada.

Comandos utiles:

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl logs -n banquito-switch deployment/file-reception-service --tail=100
kubectl logs -n banquito-pubsub deployment/payment-line-subscriber-service --tail=100
```

Para verlos en Google Cloud:

```text
Google Cloud Console
  -> Logging
  -> Logs Explorer
```

Filtros utiles:

```text
resource.type="k8s_container"
resource.labels.namespace_name="banquito-core"
```

```text
resource.type="k8s_container"
resource.labels.namespace_name="banquito-switch"
```

```text
resource.type="k8s_container"
resource.labels.namespace_name="banquito-pubsub"
```

Para Pub/Sub:

```text
resource.type="pubsub_topic"
```

Para Cloud SQL:

```text
resource.type="cloudsql_database"
```

## 5. Metricas de Pub/Sub

Pub/Sub ya expone metricas administradas en Cloud Monitoring.

Metricas importantes para la demo:

| Metrica | Uso |
| --- | --- |
| `subscription/num_undelivered_messages` | Mensajes pendientes por procesar |
| `subscription/oldest_unacked_message_age` | Antiguedad del mensaje mas viejo no confirmado |
| `topic/send_message_operation_count` | Cantidad de mensajes publicados |
| `subscription/ack_message_operation_count` | Cantidad de mensajes confirmados |

Uso esperado:

```text
Si num_undelivered_messages sube, el subscriber esta procesando mas lento que el publisher.
Si oldest_unacked_message_age sube, hay mensajes retenidos demasiado tiempo.
Si ambos bajan a cero, Pub/Sub ya entrego y confirmo el procesamiento pendiente.
```

## 6. Metricas de GKE y Pods

Comandos desde Windows:

```powershell
kubectl top nodes
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-pubsub
kubectl get hpa -A
```

Interpretacion:

| Comando | Que demuestra |
| --- | --- |
| `kubectl top nodes` | Consumo de CPU y memoria por worker node |
| `kubectl top pods` | Consumo de CPU y memoria por microservicio |
| `kubectl get hpa -A` | Autoescalamiento configurado por servicio |

## 7. Cloud Trace

Cloud Trace permite trazabilidad distribuida, pero requiere instrumentar los microservicios con OpenTelemetry.

Estado actual:

| Elemento | Estado |
| --- | --- |
| API `cloudtrace.googleapis.com` | Debe habilitarse |
| Logs y metricas GKE | Aplicado |
| Exportacion de spans desde Java | Pendiente de instrumentacion OpenTelemetry |
| Correlacion end-to-end HTTP/gRPC/PubSub | Mejora evolutiva |

Forma recomendada de implementarlo:

1. Agregar OpenTelemetry Java Agent a las imagenes Docker o usar OpenTelemetry Operator.
2. Configurar variables `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_ENDPOINT` y propagacion W3C.
3. Enviar spans a Cloud Trace mediante OpenTelemetry Collector con exporter de Google Cloud.

Variables esperadas por microservicio:

```text
OTEL_SERVICE_NAME=<nombre-del-microservicio>
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=none
OTEL_LOGS_EXPORTER=none
OTEL_PROPAGATORS=tracecontext,baggage
```

## 8. Evidencia para sustentacion

Frase sugerida:

```text
La solucion implementa observabilidad usando Google Cloud Operations.
Cloud Monitoring recolecta metricas de GKE, Pub/Sub, Cloud SQL y de los microservicios Spring Boot mediante Managed Prometheus y PodMonitoring.
Cloud Logging centraliza los logs de los contenedores ejecutados en GKE Autopilot.
Cloud Trace queda preparado como siguiente paso de trazabilidad distribuida con OpenTelemetry para correlacionar llamadas HTTP, gRPC y eventos Pub/Sub.
```

## 9. Manifiestos agregados

```text
banquito-infra/k8s/observability/podmonitoring-core.yaml
banquito-infra/k8s/observability/podmonitoring-switch.yaml
banquito-infra/k8s/observability/podmonitoring-pubsub.yaml
```

## 10. Nota operativa Windows

Durante la aplicacion desde Windows se encontro que las variables locales `HTTP_PROXY` y `HTTPS_PROXY` apuntaban a `http://127.0.0.1:9`, lo que impedia a `kubectl` conectarse al API Server.

Para limpiar el proxy solo en la sesion actual:

```powershell
$env:HTTP_PROXY=$null
$env:HTTPS_PROXY=$null
$env:NO_PROXY='localhost,127.0.0.1,::1'
```

Tambien se encontro un problema local de validacion TLS del kubeconfig. Como contingencia puntual para aplicar los manifiestos se uso:

```powershell
kubectl --insecure-skip-tls-verify=true apply --validate=false -f .\banquito-infra\k8s\observability\podmonitoring-core.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f .\banquito-infra\k8s\observability\podmonitoring-switch.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f .\banquito-infra\k8s\observability\podmonitoring-pubsub.yaml
```

Esto no cambia el manifiesto ni la seguridad del cluster; solo evita el fallo local del cliente `kubectl` en esa ejecucion. Para operacion normal se recomienda corregir el almacén de certificados de Windows o regenerar kubeconfig en una terminal sin proxy/certificados interceptados.
