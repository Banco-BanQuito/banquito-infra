# Guia Kubernetes BanQuito

Esta carpeta contiene la documentacion limpia para explicar el despliegue de BanQuito en Google Kubernetes Engine.

La guia esta organizada en fases para que el documento final se entienda desde el levantamiento inicial hasta CI/CD.

## Indice

| Fase | Documento | Proposito |
| --- | --- | --- |
| 0 | [fase-00-levantamiento-analisis.md](fase-00-levantamiento-analisis.md) | Entendimiento inicial de repositorios, puertos, dependencias y brechas |
| 1 | [fase-01-entorno-desarrollo.md](fase-01-entorno-desarrollo.md) | Preparacion de Windows 11, Docker, gcloud, kubectl, Java, Maven y Git |
| 2 | [fase-02-google-cloud.md](fase-02-google-cloud.md) | Preparacion de GCP, GKE Autopilot y Artifact Registry |
| 3 | [fase-03-adecuacion-microservicios.md](fase-03-adecuacion-microservicios.md) | Ajustes de Dockerfiles, variables y configuracion para Pods |
| 4 | [fase-04-imagenes-artifact-registry.md](fase-04-imagenes-artifact-registry.md) | Build, tag y push de imagenes Docker |
| 5 | [fase-05-infraestructura-kubernetes.md](fase-05-infraestructura-kubernetes.md) | Namespaces, ConfigMap, Secret, estructura de manifiestos |
| 6 | [fase-06-despliegue-backends.md](fase-06-despliegue-backends.md) | Deployments y Services de microservicios backend |
| 7 | [fase-07-despliegue-frontends.md](fase-07-despliegue-frontends.md) | Deployments y Services de frontends |
| 8 | [fase-08-acceso-externo-apigee.md](fase-08-acceso-externo-apigee.md) | Gateway de GKE, rutas HTTP y exposicion para Apigee |
| 9 | [fase-09-servicios-externos.md](fase-09-servicios-externos.md) | Cloud SQL, MongoDB, RabbitMQ, OAuth, SMTP y Secrets reales |
| 10 | [fase-10-cicd.md](fase-10-cicd.md) | Automatizacion con GitHub Actions |

## Anexos

| Documento | Proposito |
| --- | --- |
| [anexo-a-rutas-backend-apigee.md](anexo-a-rutas-backend-apigee.md) | Inventario de rutas backend para configurar proxies en Apigee |
| [anexo-b-operacion-windows.md](anexo-b-operacion-windows.md) | Comandos diarios desde Windows 11 |
| [anexo-c-hpa-autoescalamiento.md](anexo-c-hpa-autoescalamiento.md) | Autoescalamiento horizontal con HPA y GKE Autopilot |
| [anexo-d-comandos-actualizacion.md](anexo-d-comandos-actualizacion.md) | Como subir mejoras individuales y por bloques |
| [anexo-e-api-keys-apigee.md](anexo-e-api-keys-apigee.md) | API Key propia por aplicacion consumidora |
| [anexo-f-workload-identity-github-actions.md](anexo-f-workload-identity-github-actions.md) | Autenticacion segura de GitHub Actions con Google Cloud sin JSON key |
| [anexo-g-validacion-cicd-backends.md](anexo-g-validacion-cicd-backends.md) | Prueba de CI/CD en los ocho backends y resultados de GitHub Actions |
| [anexo-h-secrets-bases-datos.md](anexo-h-secrets-bases-datos.md) | Configuracion de Secrets reales para PostgreSQL, MySQL y MongoDB Atlas |
| [anexo-i-secret-manager-key-vault.md](anexo-i-secret-manager-key-vault.md) | Baul de secretos de nube con Google Secret Manager para cumplir Key Vault |
| [anexo-j-entrega-secret-manager-companero.md](anexo-j-entrega-secret-manager-companero.md) | Informacion exacta para que el equipo cree secretos en Secret Manager |
| [anexo-k-pubsub-workload-identity.md](anexo-k-pubsub-workload-identity.md) | Migracion de RabbitMQ a Google Pub/Sub con Workload Identity |
| [anexo-l-validacion-frontends-gateway.md](anexo-l-validacion-frontends-gateway.md) | Validacion de los cuatro frontends por GKE Gateway con una sola IP publica |

## Estado actual resumido

| Elemento | Estado |
| --- | --- |
| Cluster | `banquito-cluster-east` |
| Modo | GKE Autopilot |
| Region | `us-east1` |
| Proyecto GKE | `project-47695a8e-7cb2-4352-af2` |
| Artifact Registry | `us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito` |
| Namespaces | `banquito-core`, `banquito-switch`, `banquito-frontend`, `banquito-gateway` |
| API Manager | Apigee, dominio `https://136.68.89.25.nip.io` |
| Gateway GKE | `banquito-public-gateway` creado, pendiente validar IP publica final |

## Documentos historicos

Los documentos largos generados durante pruebas se conservaron en:

```text
banquito-infra/docs/historico-kubernetes
```

Esos archivos son evidencia de trabajo, pero el documento final debe basarse en esta carpeta `docs/kubernetes`.
