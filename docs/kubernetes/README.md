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
| 7 | [fase-07-despliegue-frontends.md](fase-07-despliegue-frontends.md) | Despliegue de frontends en VM/Nginx fuera de GKE |
| 8 | [fase-08-acceso-externo-apigee.md](fase-08-acceso-externo-apigee.md) | Gateway de GKE, rutas HTTP y exposicion para Apigee |
| 9 | [fase-09-servicios-externos.md](fase-09-servicios-externos.md) | Cloud SQL, MongoDB, Pub/Sub, OAuth, SMTP y Secrets reales |
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
| [anexo-l-validacion-frontends-gateway.md](anexo-l-validacion-frontends-gateway.md) | Historico: validacion anterior de frontends por GKE Gateway |
| [anexo-n-validacion-completa-gke.md](anexo-n-validacion-completa-gke.md) | Validacion completa de Core, Switch y Frontends ejecutandose en GKE |
| [anexo-o-https-duckdns-gateway.md](anexo-o-https-duckdns-gateway.md) | Historico: HTTPS con DuckDNS cuando los frontends estaban en GKE Gateway |
| [anexo-p-secret-manager-csi-party-service.md](anexo-p-secret-manager-csi-party-service.md) | Lectura de `identity-platform-api-key` desde Secret Manager para `party-service` con Secret Sync |
| [anexo-q-validacion-identity-platform-party.md](anexo-q-validacion-identity-platform-party.md) | Validacion funcional de creacion de usuarios Identity Platform desde `party-service` |
| [anexo-r-separacion-switch-pubsub.md](anexo-r-separacion-switch-pubsub.md) | Separacion logica del Switch: recepcion, clasificacion, publicacion, Pub/Sub y subscriber |
| [anexo-s-frontends-vm-cicd.md](anexo-s-frontends-vm-cicd.md) | Frontends fuera de GKE, servidos por VM/Nginx y desplegados con GitHub Actions |
| [anexo-t-gke-standard-backends-vm-frontends.md](anexo-t-gke-standard-backends-vm-frontends.md) | Opcion de migracion a GKE Standard solo para backends, manteniendo frontends en VM |
| [anexo-u-autopilot-namespaces-pubsub.md](anexo-u-autopilot-namespaces-pubsub.md) | Implementacion actual en GKE Autopilot con namespace separado para adaptadores Pub/Sub |
| [anexo-v-comandos-creacion-autopilot.md](anexo-v-comandos-creacion-autopilot.md) | Comandos ejecutados para crear GKE Autopilot, namespaces, Gateway, HPA y workloads |
| [anexo-w-analisis-bounded-context-switch.md](anexo-w-analisis-bounded-context-switch.md) | Analisis de bounded context del Switch, responsabilidades por microservicio y diagramas de flujo |
| [anexo-x-clearing-banco-externo-secret-manager.md](anexo-x-clearing-banco-externo-secret-manager.md) | Configuracion de `clearinghouse-service` para banco externo BanQuil con Secret Manager |
| [anexo-y-lista-repositorios.md](anexo-y-lista-repositorios.md) | Lista consolidada de repositorios, ramas, URLs y ultimo commit validado |

## Estado actual resumido

| Elemento | Estado |
| --- | --- |
| Cluster | `banquito-cluster-autopilot` |
| Modo | GKE Autopilot |
| Region | `us-east1` |
| Proyecto GKE | `project-47695a8e-7cb2-4352-af2` |
| Artifact Registry | `us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito` |
| Namespaces | `banquito-core`, `banquito-switch`, `banquito-pubsub`, `banquito-gateway` |
| API Manager | Apigee, dominio `https://136.68.89.25.nip.io` |
| Gateway GKE | `banquito-public-gateway`, IP publica `8.233.141.65` |
| Frontends | VM/Nginx, fuera del cluster GKE |

## Documentos historicos

Los documentos largos generados durante pruebas se conservaron en:

```text
banquito-infra/docs/historico-kubernetes
```

Esos archivos son evidencia de trabajo, pero el documento final debe basarse en esta carpeta `docs/kubernetes`.
