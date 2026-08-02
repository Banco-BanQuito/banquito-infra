# Anexo V - Comandos para creacion de GKE Autopilot

Este anexo documenta los comandos usados para recrear el despliegue backend de BanQuito sobre Google Kubernetes Engine en modo Autopilot.

El objetivo fue dejar el cluster limpio, con namespaces separados y con los adaptadores de Pub/Sub fuera del namespace principal del Switch.

## Variables de referencia

```powershell
$PROJECT_ID="project-47695a8e-7cb2-4352-af2"
$REGION="us-east1"
$CLUSTER="banquito-cluster-autopilot"
```

## 1. Crear cluster Autopilot

```powershell
gcloud container clusters create-auto banquito-cluster-autopilot `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --release-channel regular `
  --enable-secret-manager
```

## 2. Obtener credenciales del cluster

```powershell
gcloud container clusters get-credentials banquito-cluster-autopilot `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2
```

## 3. Habilitar Gateway API

```powershell
gcloud container clusters update banquito-cluster-autopilot `
  --region us-east1 `
  --gateway-api=standard `
  --project project-47695a8e-7cb2-4352-af2
```

## 4. Habilitar Secret Sync

```powershell
gcloud beta container clusters update banquito-cluster-autopilot `
  --region us-east1 `
  --enable-secret-sync `
  --project project-47695a8e-7cb2-4352-af2
```

## 5. Verificar cluster

```powershell
gcloud container clusters list `
  --project project-47695a8e-7cb2-4352-af2
```

```powershell
kubectl --insecure-skip-tls-verify=true get nodes
```

```powershell
kubectl --insecure-skip-tls-verify=true cluster-info
```

## 6. Aplicar namespaces

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\namespace.yaml
```

Namespaces aplicados:

```text
banquito-core
banquito-switch
banquito-pubsub
banquito-gateway
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get namespaces
```

## 7. Aplicar ConfigMaps

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\configmap.yaml
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get configmap -n banquito-core
kubectl --insecure-skip-tls-verify=true get configmap -n banquito-switch
kubectl --insecure-skip-tls-verify=true get configmap -n banquito-pubsub
```

## 8. Aplicar ServiceAccounts de Pub/Sub

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\pubsub-serviceaccounts.yaml
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get serviceaccount -n banquito-pubsub
```

## 9. Crear cuentas de servicio de Google para Pub/Sub

```powershell
gcloud iam service-accounts create payment-line-publisher-pubsub `
  --project project-47695a8e-7cb2-4352-af2
```

```powershell
gcloud iam service-accounts create payment-line-subscriber-pubsub `
  --project project-47695a8e-7cb2-4352-af2
```

Si ya existen, el comando devuelve error de existencia y se continua con los permisos.

## 10. Dar permisos IAM para Pub/Sub

Publicador:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:payment-line-publisher-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/pubsub.publisher"
```

Suscriptor:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:payment-line-subscriber-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/pubsub.subscriber"
```

## 11. Vincular Workload Identity

Publicador:

```powershell
gcloud iam service-accounts add-iam-policy-binding `
  payment-line-publisher-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com `
  --project project-47695a8e-7cb2-4352-af2 `
  --role="roles/iam.workloadIdentityUser" `
  --member="serviceAccount:project-47695a8e-7cb2-4352-af2.svc.id.goog[banquito-pubsub/payment-line-publisher-pubsub-ksa]"
```

Suscriptor:

```powershell
gcloud iam service-accounts add-iam-policy-binding `
  payment-line-subscriber-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com `
  --project project-47695a8e-7cb2-4352-af2 `
  --role="roles/iam.workloadIdentityUser" `
  --member="serviceAccount:project-47695a8e-7cb2-4352-af2.svc.id.goog[banquito-pubsub/payment-line-subscriber-pubsub-ksa]"
```

## 12. Aplicar ServiceAccounts de Secret Manager

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\secret-manager-serviceaccounts.yaml
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get serviceaccount -n banquito-core
kubectl --insecure-skip-tls-verify=true get serviceaccount -n banquito-switch
```

## 13. Crear Kubernetes Secrets desde Secret Manager

No se aplico `k8s/secret.yaml` porque contiene placeholders.

Los secretos reales se toman desde Google Secret Manager y se sincronizan como Kubernetes Secrets nativos por namespace.

Verificar secretos existentes en Google Secret Manager:

```powershell
gcloud secrets list `
  --project project-47695a8e-7cb2-4352-af2
```

Verificar secretos creados en Kubernetes:

```powershell
kubectl --insecure-skip-tls-verify=true get secrets -n banquito-core
kubectl --insecure-skip-tls-verify=true get secrets -n banquito-switch
kubectl --insecure-skip-tls-verify=true get secrets -n banquito-pubsub
```

## 14. Aplicar Secret Sync de Party

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\party\identity-platform-secretsync.yaml
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get secretsync -n banquito-core
```

## 15. Aplicar microservicios del Core

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\account-core
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\accounting
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\party
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
kubectl --insecure-skip-tls-verify=true get svc -n banquito-core
```

## 16. Aplicar microservicios del Switch

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\file-reception
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\payment-line-classifier
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\clearinghouse
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\tariff
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\report
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\notification
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
kubectl --insecure-skip-tls-verify=true get svc -n banquito-switch
```

## 17. Aplicar adaptadores Pub/Sub

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\payment-line-publisher
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\payment-line-subscriber
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-pubsub
kubectl --insecure-skip-tls-verify=true get svc -n banquito-pubsub
```

## 18. Aplicar Gateway

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\gateway
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get gateway -A
kubectl --insecure-skip-tls-verify=true get httproute -A
```

Resultado esperado:

```text
banquito-public-gateway   8.233.141.65   Programmed=True
```

## 19. Aplicar HPA

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\hpa
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get hpa -A
```

## 20. Validacion general

Pods por namespace:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
kubectl --insecure-skip-tls-verify=true get pods -n banquito-pubsub
```

Services:

```powershell
kubectl --insecure-skip-tls-verify=true get svc -n banquito-core
kubectl --insecure-skip-tls-verify=true get svc -n banquito-switch
kubectl --insecure-skip-tls-verify=true get svc -n banquito-pubsub
```

Consumo:

```powershell
kubectl --insecure-skip-tls-verify=true top nodes
kubectl --insecure-skip-tls-verify=true top pods -A
```

Eventos si algun Pod queda en `Pending` o `CrashLoopBackOff`:

```powershell
kubectl --insecure-skip-tls-verify=true describe pod <pod-name> -n <namespace>
kubectl --insecure-skip-tls-verify=true logs <pod-name> -n <namespace>
```

## 21. Reinicios usados durante ajuste

Reiniciar un Deployment:

```powershell
kubectl --insecure-skip-tls-verify=true rollout restart deployment/tariff-service -n banquito-switch
```

Esperar despliegue:

```powershell
kubectl --insecure-skip-tls-verify=true rollout status deployment/tariff-service -n banquito-switch
```

## 22. Estado final esperado

Core:

```text
account-core-service   1/1 Running
accounting-service     1/1 Running
party-service          1/1 Running
```

Switch:

```text
clearinghouse-service             1/1 Running
file-reception-service            1/1 Running
notification-service              1/1 Running
payment-line-classifier-service   1/1 Running
report-service                    1/1 Running
tariff-service                    1/1 Running
```

Pub/Sub:

```text
payment-line-publisher-service    1/1 Running
payment-line-subscriber-service   1/1 Running
```

Gateway:

```text
banquito-public-gateway   8.233.141.65   Programmed=True
```

## 23. Target para Apigee

Apigee debe apuntar al Gateway publico de GKE:

```text
http://8.233.141.65
```

El consumo externo sigue siendo:

```text
Frontend VM -> Apigee -> GKE Gateway -> Services ClusterIP -> Pods backend
```
