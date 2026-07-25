# Guia de defensa Kubernetes - BanQuito

## Objetivo del documento

Este documento sirve para entender y defender como se desplego BanQuito en Kubernetes usando Google Cloud.

La idea principal es explicar de forma clara:

- Que es el cluster.
- Como se organizan los microservicios.
- Que hace el control plane.
- Que hace el data plane.
- Como funcionan los pods, containers, deployments y services.
- Como se comunican Core, Switch, Frontends, VM/Nginx y Apigee.
- Como se cumple el requisito de orquestador de contenedores.

## Resumen ejecutivo

BanQuito se desplego en un orquestador de contenedores provisto por la nube: **Google Kubernetes Engine Autopilot**.

El cluster utilizado es:

| Elemento | Valor |
| --- | --- |
| Proveedor | Google Cloud Platform |
| Servicio | Google Kubernetes Engine |
| Modo | Autopilot |
| Cluster | `banquito-cluster-east` |
| Region | `us-east1` |
| Proyecto GCP | `project-47695a8e-7cb2-4352-af2` |
| Version Kubernetes | `1.35.5-gke.1241004` |
| Gateway publico | `banquito-public-gateway` |
| IP publica del Gateway | `8.233.141.65` |

La arquitectura separa los backends y el gateway en namespaces principales:

| Namespace | Responsabilidad |
| --- | --- |
| `banquito-core` | Microservicios del Core Bancario. |
| `banquito-switch` | Microservicios del Switch de Pagos Masivos. |
| `banquito-gateway` | Gateway publico de entrada al cluster. |

## Idea principal para defender

La frase clave para la exposicion es:

> BanQuito usa GKE Autopilot como orquestador de contenedores para los backends del Core Bancario y del Switch de Pagos Masivos. Kubernetes mantiene el estado deseado mediante Deployments, expone comunicacion interna mediante Services ClusterIP y controla la entrada desde Apigee mediante un Gateway. Los frontends se sirven desde una VM con Nginx y consumen las APIs por Apigee, que valida OAuth 2 y API Keys antes de enrutar hacia GKE.

## Arquitectura general

El flujo general del sistema es:

```text
Usuario
  -> Frontend BanQuito en VM/Nginx
  -> Apigee API Manager
  -> GKE Gateway
  -> Service ClusterIP
  -> Pod
  -> Container del microservicio
  -> Servicios administrados de nube
```

Los servicios administrados de nube no se ejecutan dentro del cluster:

| Necesidad | Servicio usado |
| --- | --- |
| Orquestador | Google Kubernetes Engine Autopilot |
| API Manager | Apigee |
| OAuth 2 | Google Identity Platform |
| Base de datos SQL | Cloud SQL PostgreSQL / Cloud SQL MySQL |
| Base de datos NoSQL | MongoDB Atlas |
| Message broker | Google Cloud Pub/Sub |
| Secretos | Google Secret Manager |
| Imagenes Docker | Google Artifact Registry |
| Logs y metricas | Cloud Logging / Cloud Monitoring |

## Control plane y data plane

Un cluster Kubernetes se divide en dos partes:

| Plano | Que hace | En BanQuito |
| --- | --- | --- |
| Control plane | Decide y mantiene el estado deseado del cluster. | Recibe `kubectl`, GitHub Actions y manifiestos. Coordina pods, deployments, services, HPA y gateway. |
| Data plane | Ejecuta las aplicaciones reales. | Corre los pods del Core y Switch. |

Explicacion simple:

> El control plane es el cerebro. Decide que debe existir. El data plane es el cuerpo. Ejecuta los pods y contenedores.

En GKE Autopilot, Google administra el control plane y los worker nodes. El equipo no instala manualmente Kubernetes, Docker, kubelet, scheduler ni etcd.

## Worker nodes y namespaces

Un punto importante es no confundir worker nodes con namespaces.

| Concepto | Que es | Ejemplo |
| --- | --- | --- |
| Worker node | Maquina donde corren los pods. | Nodo creado automaticamente por GKE Autopilot. |
| Namespace | Division logica dentro del cluster. | `banquito-core`, `banquito-switch`, `banquito-gateway`. |

La relacion correcta es:

```text
Cluster GKE
  Worker Node 1
    Pod account-core-service     namespace banquito-core
  Worker Node 2
    Pod file-reception-service   namespace banquito-switch
    Pod party-service            namespace banquito-core
```

Por lo tanto:

| Pregunta | Respuesta |
| --- | --- |
| Un namespace es un nodo? | No. Es una separacion logica. |
| Un worker node es una maquina? | Si. Es infraestructura de ejecucion. |
| Un nodo puede tener pods de varios namespaces? | Si. |
| Un namespace puede tener pods en varios nodos? | Si. |
| En Autopilot elegimos el nodo manualmente? | No. GKE lo decide automaticamente. |

## Pods, containers, deployments y services

La relacion principal es:

```text
Deployment
  -> ReplicaSet
  -> Pod
  -> Container
```

| Recurso | Funcion | Ejemplo |
| --- | --- | --- |
| Deployment | Define como debe ejecutarse un microservicio. | `account-core-service` con imagen, puertos, variables y replicas. |
| ReplicaSet | Mantiene la cantidad de pods requerida. | Crea un pod nuevo si uno se elimina. |
| Pod | Unidad minima que Kubernetes ejecuta. | `account-core-service-xxxxx`. |
| Container | Aplicacion real ejecutandose. | JAR Spring Boot o Nginx frontend. |
| Service | Nombre estable para llamar a los pods. | `party-service.banquito-core.svc.cluster.local`. |

Ejemplo:

```text
Deployment: account-core-service
  ReplicaSet: account-core-service-xxxxx
    Pod: account-core-service-xxxxx-yyyyy
      Container: account-core-service
```

## Distribucion de aplicaciones

### Core Bancario

| Microservicio | Namespace | Puertos | Funcion |
| --- | --- | --- | --- |
| `account-core-service` | `banquito-core` | HTTP `8081`, gRPC `9091` | Cuentas, saldos, movimientos y operaciones bancarias. |
| `accounting-service` | `banquito-core` | HTTP `8082`, gRPC `9092` | Asientos contables. |
| `party-service` | `banquito-core` | HTTP `8083`, gRPC `9093` | Clientes, personas, empresas y sucursales. |

### Switch de Pagos Masivos

| Microservicio | Namespace | Puertos | Funcion |
| --- | --- | --- | --- |
| `file-reception-service` | `banquito-switch` | HTTP `8084` | Recibe y procesa archivos de pagos masivos. |
| `clearinghouse-service` | `banquito-switch` | HTTP `8087` | Procesa compensacion y consume eventos Pub/Sub. |
| `tariff-service` | `banquito-switch` | HTTP `8086`, gRPC `9090` | Calcula tarifas. |
| `report-service` | `banquito-switch` | HTTP `8088` | Genera reportes. |
| `notification-service` | `banquito-switch` | HTTP `8089`, gRPC `9092` | Envia notificaciones. |

### Frontends

Los frontends ya no se ejecutan como Pods. Se publican desde una VM con Nginx y consumen las APIs mediante Apigee.

| Frontend | Ubicacion | Funcion |
| --- | --- | --- |
| `web-personas-frontend` | VM/Nginx | Banca web personas. |
| `web-empresas-frontend` | VM/Nginx | Banca web empresas. |
| `teller-frontend` | VM/Nginx | Ventanilla/cajero. |
| `operador-frontend` | VM/Nginx | Operador bancario. |

## Comunicacion interna

Los microservicios se comunican internamente usando Services de Kubernetes.

Ejemplos:

| Origen | Destino | Protocolo | Forma de comunicacion |
| --- | --- | --- | --- |
| `account-core-service` | `accounting-service` | gRPC | `accounting-service.banquito-core.svc.cluster.local:9092` |
| `account-core-service` | `party-service` | gRPC | `party-service.banquito-core.svc.cluster.local:9093` |
| `file-reception-service` | `tariff-service` | gRPC | `tariff-service.banquito-switch.svc.cluster.local:9090` |
| `file-reception-service` | `notification-service` | gRPC | `notification-service.banquito-switch.svc.cluster.local:9092` |

Esto evita depender de IPs de pods, porque las IPs de pods cambian cuando Kubernetes recrea una instancia.

## Comunicacion externa con Apigee

Apigee no esta dentro de Kubernetes. Apigee es un servicio cloud externo que actua como API Manager.

El flujo correcto es:

```text
Frontend
  -> Apigee
  -> GKE Gateway
  -> Service interno ClusterIP
  -> Pod del microservicio
```

Responsabilidades:

| Componente | Responsabilidad |
| --- | --- |
| Frontend | Llama APIs publicas y envia `Authorization` + `x-api-key`. |
| Apigee | Valida OAuth 2, valida API Key, aplica seguridad y enruta. |
| GKE Gateway | Recibe trafico permitido desde Apigee y lo enruta al Service. |
| Service ClusterIP | Entrega el trafico al pod disponible. |
| Pod | Ejecuta la logica del microservicio. |

Punto importante para defender:

> Los microservicios no se exponen individualmente con LoadBalancer. Se mantienen internos con ClusterIP. La entrada publica se centraliza en Gateway y el control de seguridad se realiza en Apigee.

## Seguridad

La seguridad se implementa en varias capas:

| Capa | Implementacion |
| --- | --- |
| Autenticacion | Google Identity Platform emite tokens OAuth 2 / JWT. |
| API Manager | Apigee valida JWT y API Keys. |
| API Key por aplicacion | Cada frontend tiene su propia API Key. |
| Secretos | Credenciales y variables sensibles se almacenan en Google Secret Manager. |
| Kubernetes | Los pods consumen configuracion mediante Secrets/ConfigMaps. |
| Red interna | Services ClusterIP evitan exponer microservicios directamente. |

## Escalamiento y disponibilidad

BanQuito usa dos mecanismos:

| Mecanismo | Que escala | Para que sirve |
| --- | --- | --- |
| HPA | Escala pods segun CPU/memoria. | Si un servicio tiene mas carga, puede crear mas replicas. |
| GKE Autopilot | Escala infraestructura/nodos. | Si no hay capacidad, Google puede crear worker nodes. |

La configuracion esperada del HPA es:

| Valor | Configuracion |
| --- | --- |
| Minimo | 1 pod |
| Maximo | 3 pods |
| Metrica CPU | 70% |
| Metrica memoria | 80% |

Explicacion simple:

> El HPA escala pods, no nodos. Autopilot escala nodos si hacen falta recursos para ejecutar esos pods.

## CI/CD

El despliegue automatizado se hace con GitHub Actions.

El flujo esperado es:

```text
git push
  -> GitHub Actions
  -> Build
  -> Test
  -> Docker Build
  -> Push a Artifact Registry
  -> Deploy a GKE
```

Esto cumple el requisito:

> Se debe crear flujos pipeline para despliegue automatizado de las aplicaciones en el orquestador de contenedores.

## Observabilidad

La observabilidad se apoya en servicios administrados de Google Cloud:

| Necesidad | Servicio |
| --- | --- |
| Logs | Cloud Logging |
| Metricas | Cloud Monitoring |
| Consumo de pods | Kubernetes Metrics / `kubectl top pods` |
| Consumo de nodos | Kubernetes Metrics / `kubectl top nodes` |
| Estado de workloads | `kubectl get pods`, `kubectl describe`, `kubectl logs` |

## Comandos para demostrar

Ver namespaces:

```powershell
kubectl get namespaces
```

Ver deployments:

```powershell
kubectl get deployments -A
```

Ver pods:

```powershell
kubectl get pods -A
```

Ver pods con worker node:

```powershell
kubectl get pods -A -o wide
```

Ver worker nodes:

```powershell
kubectl get nodes -o wide
```

Ver services:

```powershell
kubectl get svc -A
```

Ver gateway:

```powershell
kubectl get gateway -A
```

Ver rutas HTTP:

```powershell
kubectl get httproute -A
```

Ver HPA:

```powershell
kubectl get hpa -A
```

Ver logs de un backend:

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
```

Ver detalle de un pod:

```powershell
kubectl describe pod <nombre-del-pod> -n <namespace>
```

Ver consumo:

```powershell
kubectl top pods -A
kubectl top nodes
kubectl top pods -n banquito-switch

```

## Guion corto de defensa

BanQuito esta desplegado en Google Kubernetes Engine Autopilot. Kubernetes funciona como el orquestador de contenedores, porque se encarga de ejecutar, reiniciar, escalar y conectar los microservicios.

El cluster se divide en namespaces para separar responsabilidades: Core, Switch, Frontends y Gateway. Los namespaces son divisiones logicas; los worker nodes son las maquinas reales donde corren los pods.

Cada microservicio se ejecuta como un contenedor dentro de un pod. Los Deployments definen como debe correr cada aplicacion y los Services ClusterIP permiten que los microservicios se comuniquen internamente usando DNS estable.

El trafico externo no entra directo a cada microservicio. Primero pasa por Apigee, donde se valida OAuth 2 y API Key. Luego Apigee enruta hacia el Gateway de GKE, y el Gateway envia la peticion al Service interno correspondiente.

Las bases de datos, Pub/Sub, OAuth, Secret Manager y Apigee son servicios provistos por la nube, por lo que no se instalan como contenedores dentro del cluster. Esto reduce carga operativa y cumple el requisito de usar servicios administrados.

Para automatizacion, GitHub Actions construye imagenes, las publica en Artifact Registry y despliega los cambios en GKE. Para escalamiento, HPA aumenta replicas de pods cuando hay carga, y Autopilot aprovisiona capacidad cuando el cluster necesita recursos.

## Respuesta rapida ante preguntas

| Pregunta | Respuesta para defender |
| --- | --- |
| Por que GKE Autopilot? | Porque reduce administracion de nodos y permite enfocarse en los microservicios. |
| Donde corren los microservicios? | En pods dentro del data plane del cluster GKE. |
| Que es un namespace? | Una division logica para organizar recursos. |
| Que es un worker node? | La maquina donde Kubernetes ejecuta pods. |
| Apigee esta dentro del cluster? | No. Es un servicio cloud externo que protege y enruta APIs. |
| Por que usar ClusterIP? | Para evitar exponer cada microservicio con IP publica. |
| Como se comunican los servicios? | Internamente por Services DNS y gRPC/HTTP. |
| Como entra el trafico externo? | Frontend -> Apigee -> GKE Gateway -> Service -> Pod. |
| Como se escalan los pods? | Con HPA segun CPU/memoria. |
| Como se escalan los nodos? | Autopilot los administra automaticamente. |
| Donde estan los secretos? | En Google Secret Manager. |
| Donde estan las imagenes? | En Artifact Registry. |
| Como se despliega automaticamente? | Con pipelines de GitHub Actions. |
