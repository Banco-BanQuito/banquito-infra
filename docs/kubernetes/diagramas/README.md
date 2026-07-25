# Diagramas Kubernetes BanQuito

## Diagrama principal

Archivo:

```text
cluster-banquito-gke.svg
```

Diagrama especifico de plano de datos, worker nodes, pods y contenedores:

```text
data-plane-pods-contenedores.svg
```

Uso:

- Insertar el SVG directamente en PowerPoint, Word o Canva.
- Tambien se puede abrir en el navegador y tomar captura.

## Explicacion corta del diagrama

El cluster `banquito-cluster-east` esta desplegado en Google Kubernetes Engine Autopilot, region `us-east1`.

La arquitectura separa el sistema en cuatro zonas principales:

1. Plano de control.
2. Plano de datos.
3. Entrada publica controlada.
4. Servicios administrados externos.

## Plano de control

El plano de control es administrado por Google Cloud. Incluye componentes como API Server, Scheduler, Controllers y etcd. En GKE Autopilot no administramos manualmente nodos master.

## Plano de datos

El plano de datos contiene los workloads del proyecto, organizados por namespaces:

- `banquito-core`
- `banquito-switch`
- `banquito-frontend`

Cada microservicio se despliega como un Deployment que genera Pods. Los Pods se acceden internamente mediante Services `ClusterIP`.

## Entrada publica

La entrada externa se realiza mediante un Gateway de GKE:

```text
banquito-public-gateway
IP: 8.233.141.65
```

Las rutas HTTP publicas apuntan a los frontends y a las APIs que Apigee necesita enrutar.

## Apigee e Identity Platform

Apigee actua como API Manager cloud. Valida:

- API Key por aplicacion.
- JWT emitido por Identity Platform.
- Rutas autorizadas.
- CORS y politicas de acceso.

## Servicios externos administrados

No se ejecutan dentro de Kubernetes:

- Cloud SQL PostgreSQL.
- Cloud SQL MySQL.
- MongoDB Atlas.
- Google Cloud Pub/Sub.
- Google Secret Manager.
- Artifact Registry.
- Cloud Logging y Cloud Monitoring.

## Comandos para evidenciar

```powershell
kubectl get namespaces
kubectl get deployments -A
kubectl get pods -A -o wide
kubectl get svc -A
kubectl get gateway -A
kubectl get httproute -A
kubectl get hpa -A
```
