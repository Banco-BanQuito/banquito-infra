# Data Plane, Worker Nodes, Pods y Contenedores

## Contexto del cluster BanQuito

El cluster usado para el despliegue es:

| Elemento | Valor del proyecto |
| --- | --- |
| Nombre del cluster | `banquito-cluster-east` |
| Proveedor cloud | Google Cloud Platform |
| Servicio de orquestacion | Google Kubernetes Engine |
| Modo de operacion | Autopilot |
| Region | `us-east1` |
| Version Kubernetes | `1.35.5-gke.1241004` |
| Endpoint del API Server | `34.148.92.193` |
| Red | `default` |
| Subred | `default` |
| Workload Identity | Habilitado |

Imagen para la presentacion:

```text
data-plane-pods-contenedores.svg
```

## Lectura general del diagrama Kubernetes

El diagrama representa la arquitectura base de un cluster de Kubernetes. Un cluster esta compuesto por dos grandes partes:

1. **Control plane** o plano de control.
2. **Data plane** o plano de datos.

La idea principal es:

| Plano | Rol principal | Analogia | En BanQuito |
| --- | --- | --- | --- |
| Control plane | Decide, coordina y mantiene el estado deseado. | Cerebro del cluster. | Recibe `kubectl`, GitHub Actions y manifiestos; coordina Deployments, Services, HPA y rutas. |
| Data plane | Ejecuta las aplicaciones reales en pods y contenedores. | Cuerpo del cluster. | Ejecuta Core, Switch y Frontends dentro de pods sobre worker nodes administrados por GKE. |

En otras palabras, Kubernetes separa la administracion del cluster de la ejecucion de las aplicaciones. El plano de control no ejecuta el negocio bancario directamente; su trabajo es orquestar. El plano de datos es donde se ejecutan los microservicios de BanQuito.

## Kubernetes Cluster

Un cluster de Kubernetes es el conjunto completo de recursos que permite ejecutar aplicaciones contenerizadas.

En un cluster tradicional, este conjunto incluye:

| Elemento del cluster | Para que sirve |
| --- | --- |
| Nodos de control | Administran el estado del cluster y coordinan la ejecucion de cargas. |
| Nodos worker | Ejecutan pods y contenedores. |
| Red interna | Permite comunicacion entre pods, Services y namespaces. |
| Pods | Unidad minima de despliegue en Kubernetes. |
| Services | Punto estable de comunicacion hacia pods. |
| Controladores | Mantienen el estado deseado, por ejemplo replicas de Deployments. |
| Almacenamiento | Volumenes, discos o integraciones con servicios de persistencia. |
| Runtime de contenedores | Ejecuta los contenedores dentro de los pods. |

En BanQuito, el cluster es:

```text
banquito-cluster-east
```

Este cluster esta desplegado en Google Kubernetes Engine en modo Autopilot. Eso significa que Google Cloud administra gran parte de la infraestructura interna, especialmente el aprovisionamiento de nodos y la operacion del plano de control.

## Control Plane - Plano de control

El plano de control es el cerebro de Kubernetes.

Su responsabilidad es mantener el estado deseado del cluster. Por ejemplo, si se define que `account-core-service` debe tener una replica, el plano de control se encarga de que exista un pod corriendo para cumplir esa definicion.

En el diagrama, el plano de control contiene estos componentes:

| Componente | Explicacion | Funcion en BanQuito |
| --- | --- | --- |
| API Server | Es la puerta de entrada al cluster. Recibe comandos de `kubectl`, GitHub Actions y manifiestos Kubernetes. | Cuando ejecutamos `kubectl apply`, `kubectl scale` o el pipeline despliega, la solicitud llega al API Server. |
| Scheduler | Decide en que worker node debe ejecutarse cada pod. | Decide donde ubicar pods como `account-core-service`, `party-service` o `file-reception-service`. |
| Controller Manager | Supervisa que el estado real coincida con el estado deseado. | Si un pod falla o se elimina, ordena crear otro para mantener las replicas del Deployment. |
| etcd | Base de datos interna de Kubernetes donde se guarda el estado del cluster. | Guarda recursos como namespaces, deployments, services, HPA, gateway y rutas. En GKE lo administra Google. |

En GKE Autopilot no administramos manualmente los nodos master. Google Cloud opera el plano de control por nosotros.

Por eso, en la sustentacion se debe decir:

> En nuestro proyecto, el plano de control esta administrado por Google Kubernetes Engine Autopilot. Nosotros interactuamos con el cluster mediante `kubectl` y GitHub Actions, pero no administramos directamente los master nodes ni instalamos manualmente componentes como API Server, Scheduler, Controller Manager o etcd.

### Ejemplo practico del control plane

Cuando ejecutamos:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
```

ocurre lo siguiente:

1. `kubectl` envia la solicitud al API Server.
2. El API Server actualiza el estado deseado del Deployment.
3. El Controller Manager detecta que debe existir un pod.
4. El Scheduler decide donde ubicar ese pod.
5. El Data Plane ejecuta el pod en un worker node.

## Data Plane - Plano de datos

El plano de datos es la parte de Kubernetes donde se ejecuta el trabajo real de las aplicaciones. Mientras el plano de control decide el estado deseado del cluster, el plano de datos ejecuta los contenedores, atiende red interna, mantiene los pods activos y responde a la carga de las aplicaciones.

En BanQuito, el plano de datos ejecuta los microservicios y frontends:

- Core Bancario.
- Switch de Pagos Masivos.
- Aplicaciones web.

En el diagrama, el plano de datos esta formado por varios worker nodes. Cada worker node puede alojar uno o mas pods. Cada pod contiene uno o mas contenedores.

Aplicado a BanQuito:

| Capa | Ejemplo en BanQuito | Explicacion |
| --- | --- | --- |
| Data Plane | Worker nodes administrados por GKE Autopilot | Capa donde se ejecutan los workloads reales. |
| Worker Node | Nodo creado automaticamente por Autopilot | Maquina Linux administrada por Google Cloud. |
| Pod | `account-core-service-xxxxx`, `file-reception-service-xxxxx` | Unidad minima que Kubernetes ejecuta. |
| Container | `account-core-service`, `file-reception-service` | Proceso real de la aplicacion dentro del Pod. |
| Service | `account-core-service`, `party-service` | DNS interno estable para comunicacion entre servicios. |

## Worker Nodes

Un worker node es una maquina Linux donde Kubernetes ejecuta pods.

En un cluster tradicional, el equipo de infraestructura administra los nodos worker, instala runtime de contenedores, kubelet, kube-proxy y configura red.

En nuestro caso usamos GKE Autopilot, por lo tanto:

| Caracteristica | Kubernetes tradicional | BanQuito con GKE Autopilot |
| --- | --- | --- |
| Administracion de nodos | El equipo crea y administra VMs worker. | Google Cloud crea y administra los worker nodes. |
| Runtime de contenedores | Se instala y mantiene en cada nodo. | Lo administra GKE; normalmente compatible con `containerd`. |
| Docker manual | Puede requerirse en entornos antiguos o manuales. | No se instala Docker manualmente en nodos. |
| Escalado de nodos | Se configura node pool/autoscaler manualmente. | Autopilot crea capacidad cuando hay pods pendientes. |
| Reduccion de costos | El equipo debe apagar o reducir nodos. | Autopilot puede liberar nodos cuando los deployments estan en `0`. |
| Acceso a VM worker | Puede existir acceso directo por SSH. | No se administra el nodo como VM propia. |

Por eso, cuando todos los pods estan apagados, este comando puede mostrar:

```powershell
kubectl get nodes
```

Resultado posible:

```text
No resources found
```

Esto no significa que el cluster este eliminado. Significa que no hay nodos worker activos porque no hay pods de aplicacion ejecutandose.

Cuando levantamos pods, Autopilot vuelve a crear o asignar worker nodes. Por ejemplo:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
```

Luego se puede verificar:

```powershell
kubectl get pods -n banquito-core -o wide
kubectl get nodes -o wide
```

La columna `NODE` muestra en que worker node se ejecuto cada pod.

## Componentes del Worker Node

Conceptualmente, cada worker node tiene:

| Componente | Funcion general | Como aplica en BanQuito |
| --- | --- | --- |
| Kubelet | Agente que recibe ordenes del control plane y se encarga de ejecutar pods en el nodo. | Ejecuta pods como `party-service`, `account-core-service` o `web-empresas-frontend` cuando el Scheduler los asigna a un nodo. |
| Kube proxy | Maneja reglas de red para permitir comunicacion con Services. | Permite que llamadas a `party-service.banquito-core.svc.cluster.local` lleguen al pod correcto. |
| Container runtime | Ejecuta los contenedores dentro de los pods. | Ejecuta las imagenes publicadas en Artifact Registry. En GKE moderno se usa runtime compatible con CRI, normalmente `containerd`. |

### Kubelet

El kubelet es el agente principal del worker node. Se comunica con el plano de control y se encarga de que los pods asignados a ese nodo realmente se ejecuten.

Si el Scheduler decide que `party-service` debe correr en un nodo, el kubelet de ese nodo recibe la instruccion y coordina con el runtime de contenedores para iniciar el contenedor.

### Kube proxy

Kube proxy se encarga de la parte de red de Kubernetes. Permite que los Services funcionen y que el trafico llegue al pod correcto.

En BanQuito esto es clave porque los microservicios no llaman directamente a una IP de pod. Llaman a nombres de Service como:

```text
party-service.banquito-core.svc.cluster.local
accounting-service.banquito-core.svc.cluster.local
tariff-service.banquito-switch.svc.cluster.local
```

Kube proxy ayuda a que ese trafico sea encaminado hacia los pods disponibles.

### Container runtime

El runtime es el componente que realmente ejecuta los contenedores.

Antes era comun decir que el worker node ejecutaba Docker. Sin embargo, Kubernetes moderno ya no depende directamente de Docker. En GKE se usa un runtime compatible con Kubernetes, normalmente `containerd`.

Para la defensa:

> Aunque muchos diagramas antiguos mencionan Docker, en Kubernetes moderno lo importante es el runtime compatible con CRI. En GKE Autopilot ese runtime lo administra Google Cloud.

## Contenedores en Kubernetes

Un contenedor en Kubernetes es una instancia ligera de una aplicacion empaquetada con sus dependencias.

En BanQuito, cada microservicio se empaqueta como imagen Docker y se publica en Artifact Registry. Luego Kubernetes descarga esa imagen y la ejecuta dentro de un Pod.

Ejemplos:

| Dominio | Contenedor / aplicacion | Funcion |
| --- | --- | --- |
| Core Bancario | `account-core-service` | Gestion de cuentas, saldos, movimientos y operaciones bancarias. |
| Core Bancario | `accounting-service` | Registro de asientos contables y reglas contables. |
| Core Bancario | `party-service` | Gestion de clientes, sucursales y datos de personas/empresas. |
| Switch de Pagos | `file-reception-service` | Recepcion, validacion y procesamiento inicial de lotes. |
| Switch de Pagos | `clearinghouse-service` | Consumo de eventos Pub/Sub y procesamiento de clearing. |
| Switch de Pagos | `tariff-service` | Calculo de tarifas/comisiones. |
| Switch de Pagos | `notification-service` | Notificaciones. |
| Switch de Pagos | `report-service` | Reportes de lotes y resultados. |
| Frontend | `web-empresas-frontend` | Portal web de empresas. |
| Frontend | `web-personas-frontend` | Portal web de personas. |
| Frontend | `teller-frontend` | Portal de ventanilla/cajero. |
| Frontend | `operador-frontend` | Portal de operador. |

Cada contenedor tiene:

| Configuracion del contenedor | Ejemplo | Para que sirve |
| --- | --- | --- |
| Imagen | `us-central1-docker.pkg.dev/.../account-core-service:<sha>` | Define el artefacto ejecutable que Kubernetes descarga y ejecuta. |
| Puertos | HTTP `8081`, gRPC `9091` | Permiten exponer la aplicacion dentro del pod. |
| Variables de entorno | `DB_URL`, `SERVER_PORT`, `API_MANAGER_URL` | Parametrizan la aplicacion sin cambiar codigo. |
| Secretos | Credenciales desde Secret Manager/Kubernetes Secrets | Evitan guardar passwords y API keys en codigo. |
| Recursos | CPU y memoria requests/limits | Ayudan a Autopilot a programar capacidad y controlar consumo. |
| Probes | Readiness/Liveness sobre `/actuator/health` | Permiten saber si el contenedor esta listo y sano. |

Ejemplo aplicado:

```text
Imagen:
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:<sha>

Contenedor:
account-core-service

Puertos:
HTTP 8081
gRPC 9091

Configuracion:
ConfigMap + Secret Manager/Kubernetes Secret
```

## Pods

El Pod es la unidad minima que Kubernetes despliega.

Un Pod puede contener uno o mas contenedores, pero en BanQuito la regla principal es:

| Regla usada | Significado |
| --- | --- |
| 1 microservicio | Una responsabilidad tecnica o funcional concreta. |
| 1 Deployment | Recurso que define como se despliega ese microservicio. |
| 1 o mas Pods | Instancias ejecutables del microservicio. |
| 1 contenedor principal por Pod | Proceso de la aplicacion dentro del pod. |

Ejemplo:

```text
Deployment: account-core-service
  Pod: account-core-service-xxxxx
    Container: account-core-service
```

Si el pod falla, Kubernetes lo vuelve a crear para mantener el numero de replicas deseado.

Esto permite tolerancia a fallos a nivel basico. Si un pod se elimina, Kubernetes compara el estado real con el estado deseado del Deployment y crea un pod nuevo.

Ejemplo:

```powershell
kubectl delete pod <pod-account-core> -n banquito-core
kubectl get pods -n banquito-core
```

El pod eliminado vuelve a aparecer con otro nombre porque el Deployment mantiene la replica deseada.

## Relacion entre Deployment, ReplicaSet, Pod y Container

| Nivel | Que representa | Ejemplo | Responsabilidad |
| --- | --- | --- | --- |
| Deployment | Estado deseado del microservicio. | `account-core-service` con `replicas=1`. | Define imagen, variables, puertos, recursos y estrategia de despliegue. |
| ReplicaSet | Controla la cantidad de pods generados por un Deployment. | `account-core-service-bf8ccbfd5`. | Mantiene el numero de pods requerido. |
| Pod | Unidad minima desplegable. | `account-core-service-bf8ccbfd5-56z7n`. | Aloja el contenedor y comparte red/volumenes internos. |
| Container | Proceso real de la aplicacion. | Contenedor `account-core-service`. | Ejecuta el JAR Spring Boot o el frontend Nginx. |

Aplicado al Core:

```text
Deployment: account-core-service
ReplicaSet: account-core-service-xxxxx
Pod: account-core-service-xxxxx-yyyyy
Container: account-core-service
```

Aplicado al Switch:

```text
Deployment: file-reception-service
ReplicaSet: file-reception-service-xxxxx
Pod: file-reception-service-xxxxx-yyyyy
Container: file-reception-service
```

## Services ClusterIP

Los pods pueden cambiar de IP cada vez que se recrean. Por eso Kubernetes usa Services.

En BanQuito todos los microservicios backend y frontends tienen Services de tipo `ClusterIP`.

| Caracteristica | Significado |
| --- | --- |
| Tipo `ClusterIP` | El servicio solo es accesible dentro del cluster. |
| Sin IP publica directa | No se expone cada microservicio a Internet. |
| DNS interno | Kubernetes crea nombres estables para comunicacion interna. |
| Balanceo interno | Si hay varias replicas, el Service distribuye trafico entre pods disponibles. |
| Desacoplamiento | El cliente llama al Service, no a la IP cambiante del pod. |

Los Services separan la identidad del servicio de la vida util del pod.

Un pod puede cambiar:

- Nombre.
- IP.
- Nodo donde corre.

Pero el Service conserva el mismo nombre DNS. Por eso la comunicacion interna no se rompe.

Ejemplo:

| Service DNS interno | Namespace | Uso |
| --- | --- | --- |
| `account-core-service.banquito-core.svc.cluster.local` | `banquito-core` | Operaciones de cuentas del Core. |
| `accounting-service.banquito-core.svc.cluster.local` | `banquito-core` | Registro contable por HTTP/gRPC. |
| `party-service.banquito-core.svc.cluster.local` | `banquito-core` | Consulta y gestion de clientes. |
| `file-reception-service.banquito-switch.svc.cluster.local` | `banquito-switch` | Recepcion de archivos/lotes. |
| `tariff-service.banquito-switch.svc.cluster.local` | `banquito-switch` | Calculo de tarifas via HTTP/gRPC. |

## Como se relaciona con Apigee y Gateway

El diagrama base de Kubernetes muestra el cluster internamente, pero en BanQuito tambien existe entrada externa controlada.

El flujo publico es:

```text
Frontend
  -> Apigee
  -> GKE Gateway
  -> Service ClusterIP
  -> Pod
  -> Container
```

Esto significa que no exponemos cada microservicio con una IP publica. Los microservicios permanecen internos y Apigee controla el acceso con OAuth 2 y API Keys.

## Como verlo en el cluster

| Que se quiere ver | Comando | Que demuestra |
| --- | --- | --- |
| Nodos worker activos | `kubectl get nodes -o wide` | Muestra los nodos del plano de datos. En Autopilot puede salir vacio si no hay pods activos. |
| Pods y nodo donde corren | `kubectl get pods -A -o wide` | Muestra en que worker node se programo cada pod. |
| Deployments | `kubectl get deployments -A` | Muestra workloads y replicas deseadas/disponibles. |
| Services | `kubectl get svc -A` | Muestra los puntos de acceso internos `ClusterIP`. |
| Gateway | `kubectl get gateway -A` | Muestra la entrada publica administrada por GKE. |
| Rutas HTTP | `kubectl get httproute -A` | Muestra rutas de frontends, Core y Switch. |
| HPA | `kubectl get hpa -A` | Muestra autoescalamiento de pods. |
| Consumo de nodos | `kubectl top nodes` | Muestra CPU/memoria por nodo si hay metricas disponibles. |
| Consumo de pods | `kubectl top pods -A` | Muestra CPU/memoria por pod si hay metricas disponibles. |

## Como demostrarlo en la demo

Primero levantar un bloque:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
```

Luego verificar:

```powershell
kubectl get pods -n banquito-core -o wide
kubectl get nodes -o wide
```

Cuando los pods esten corriendo, en la columna `NODE` se vera el worker node donde Kubernetes ubico cada pod.

## Guion para defender

El plano de datos es donde se ejecutan realmente nuestras aplicaciones. En BanQuito, cada microservicio esta empaquetado como contenedor y Kubernetes lo ejecuta dentro de un Pod. Los Pods son creados por los Deployments y se comunican mediante Services internos de tipo ClusterIP.

Como usamos GKE Autopilot, no administramos manualmente los worker nodes. Google Cloud crea los nodos cuando hay pods pendientes y puede liberarlos cuando apagamos los deployments. Por eso, si todos los pods estan en cero, `kubectl get nodes` puede no mostrar nodos activos.

En resumen, el control plane decide, y el data plane ejecuta. El control plane recibe el estado deseado; el data plane crea nodos, ejecuta pods y mantiene los contenedores de BanQuito funcionando.

## Explicacion completa para la diapositiva

Un cluster de Kubernetes se divide en dos planos: el plano de control y el plano de datos.

El plano de control es el cerebro del cluster. Ahi se encuentran componentes como el API Server, Scheduler, Controller Manager y etcd. Su responsabilidad es recibir solicitudes, guardar el estado deseado y coordinar que el cluster funcione correctamente. En BanQuito, este plano de control esta administrado por Google Kubernetes Engine Autopilot, por lo que no administramos nodos master directamente.

El plano de datos es donde se ejecutan las aplicaciones. Esta formado por worker nodes. Cada worker node tiene componentes como kubelet, kube-proxy y un runtime de contenedores. El kubelet ejecuta los pods indicados por el control plane; kube-proxy maneja la comunicacion de red; y el runtime ejecuta los contenedores.

En BanQuito, los microservicios del Core, del Switch y los frontends se ejecutan como contenedores dentro de pods. Cada pod es creado por un Deployment y se comunica mediante Services internos de tipo ClusterIP. Esto permite que los microservicios se llamen por DNS interno sin depender de IPs de pods.

Como usamos GKE Autopilot, los worker nodes no se crean manualmente. Google Cloud los aprovisiona cuando existen pods pendientes y puede liberarlos cuando los deployments se escalan a cero. Por eso, si el sistema esta apagado para ahorrar costos, `kubectl get nodes` puede mostrar que no hay nodos activos, aunque el cluster siga existiendo.

La idea principal para defender es:

| Concepto | Explicacion corta para decir en exposicion |
| --- | --- |
| Control plane | Decide y mantiene el estado deseado del cluster. |
| Data plane | Ejecuta pods y contenedores. |
| Worker nodes | Maquinas Linux donde corren los pods; en Autopilot las administra Google. |
| Pods | Unidad minima desplegable en Kubernetes. |
| Contenedores | Proceso real de cada microservicio o frontend. |
| Services | Punto de acceso estable para comunicacion interna entre pods. |
| Gateway | Entrada publica controlada hacia frontends y rutas que usa Apigee. |

## Explicacion sencilla para entenderlo rapido

Kubernetes se puede entender como un sistema que organiza y cuida aplicaciones en contenedores.

En lugar de ejecutar cada microservicio manualmente en una maquina, nosotros le decimos a Kubernetes:

```text
Quiero que este microservicio este corriendo.
Quiero que use esta imagen Docker.
Quiero que tenga estas variables.
Quiero que escuche en este puerto.
Quiero que si se cae, se vuelva a levantar.
```

Kubernetes recibe esa instruccion y se encarga de cumplirla.

Para explicarlo facil:

| Parte | Explicacion simple | Ejemplo BanQuito |
| --- | --- | --- |
| Cluster | Es el ambiente completo donde viven las aplicaciones. | `banquito-cluster-east` en GKE. |
| Control plane | Es quien toma decisiones y coordina todo. | Decide crear pods cuando aplicamos manifiestos. |
| Data plane | Es donde realmente corren las aplicaciones. | Aqui corren Core, Switch y Frontends. |
| Worker node | Es la maquina donde se ejecutan los pods. | GKE Autopilot crea estas maquinas cuando hacen falta. |
| Pod | Es como una cajita donde corre un microservicio. | Un pod de `account-core-service`. |
| Contenedor | Es la aplicacion ejecutandose dentro del pod. | El JAR Spring Boot o el Nginx del frontend. |
| Deployment | Es la regla que dice como debe ejecutarse el microservicio. | Imagen, replicas, puertos, variables y recursos. |
| Service | Es el nombre fijo para llamar a un microservicio. | `party-service.banquito-core.svc.cluster.local`. |

La diferencia mas importante es esta:

| Pregunta | Respuesta sencilla |
| --- | --- |
| Quien decide que debe correr? | El control plane. |
| Donde corre realmente? | En el data plane. |
| Que corre? | Pods. |
| Que hay dentro del pod? | Contenedores. |
| Como se comunican los microservicios? | Mediante Services internos de Kubernetes. |
| Como entra trafico externo? | Por Apigee y luego por el Gateway de GKE. |

En nuestro proyecto no se publica cada microservicio con una IP externa. Eso seria mas costoso y menos seguro. Lo correcto es que los microservicios queden internos mediante `ClusterIP`, y que el acceso desde fuera pase por Apigee y el Gateway.

La forma mas simple de decirlo en la exposicion seria:

> Nuestro cluster GKE funciona como el ambiente donde se ejecutan las aplicaciones BanQuito. El plano de control decide que debe existir, por ejemplo un pod de account-core o file-reception. El plano de datos es donde esos pods realmente corren. Cada pod contiene un contenedor con la aplicacion. Los microservicios se comunican internamente por Services ClusterIP y el acceso externo se controla por Apigee y Gateway, evitando exponer cada servicio con una IP publica.

## Worker nodes y namespaces

Los worker nodes y los namespaces no son lo mismo.

Un **worker node** es una maquina donde Kubernetes ejecuta Pods. En GKE Autopilot, esas maquinas son creadas y administradas automaticamente por Google Cloud.

Un **namespace** es una separacion logica dentro del cluster. Sirve para organizar recursos, separar responsabilidades y consultar los componentes por dominio.

En BanQuito se usan namespaces para separar las aplicaciones:

| Namespace | Que contiene | Ejemplos |
| --- | --- | --- |
| `banquito-core` | Microservicios del Core Bancario. | `account-core-service`, `accounting-service`, `party-service`. |
| `banquito-switch` | Microservicios del Switch de Pagos Masivos. | `file-reception-service`, `clearinghouse-service`, `tariff-service`, `report-service`, `notification-service`. |
| `banquito-frontend` | Aplicaciones web. | `web-personas-frontend`, `web-empresas-frontend`, `teller-frontend`, `operador-frontend`. |
| `banquito-gateway` | Entrada publica al cluster. | `banquito-public-gateway`, `HTTPRoute`. |

La relacion es:

```text
Cluster GKE
  Worker Node 1
    Pod account-core-service     namespace banquito-core
    Pod web-personas-frontend    namespace banquito-frontend

  Worker Node 2
    Pod file-reception-service   namespace banquito-switch
    Pod party-service            namespace banquito-core
```

Esto significa que:

| Idea | Explicacion |
| --- | --- |
| Un namespace no es una maquina. | Es una division logica dentro del cluster. |
| Un worker node si es infraestructura de ejecucion. | Es donde realmente corren los pods. |
| Un mismo worker node puede tener pods de varios namespaces. | Por ejemplo, un pod de Core y uno de Frontend pueden compartir nodo. |
| Un namespace puede distribuir sus pods en varios worker nodes. | Kubernetes decide donde ubicar cada pod segun recursos disponibles. |
| En Autopilot no elegimos manualmente el nodo. | GKE decide y aprovisiona capacidad cuando hace falta. |

Para defenderlo:

> Los namespaces organizan los recursos dentro del cluster, pero no representan nodos fisicos. Los worker nodes son la infraestructura donde realmente se ejecutan los Pods. Un mismo worker node puede ejecutar Pods de varios namespaces, y un namespace puede tener Pods distribuidos en varios worker nodes.

## Comandos para ver worker nodes y pods por nodo

Ver los worker nodes activos:

```powershell
kubectl get nodes -o wide
```

Este comando muestra los nodos del data plane. En GKE Autopilot puede no mostrar nodos si todos los Deployments estan escalados a `0`, porque no hay cargas ejecutandose.

Ver todos los pods con el nodo donde estan corriendo:

```powershell
kubectl get pods -A -o wide
```

La columna importante es `NODE`.

Ejemplo de lectura:

```text
NAMESPACE          NAME                         READY   STATUS    NODE
banquito-core      account-core-service-xxxxx   1/1     Running   gk3-banquito-cluster-east-pool-...
banquito-switch    file-reception-service-xxx   1/1     Running   gk3-banquito-cluster-east-pool-...
```

Esto demuestra en que worker node fue ubicado cada pod.

Ver pods solo del Core con su nodo:

```powershell
kubectl get pods -n banquito-core -o wide
```

Ver pods solo del Switch con su nodo:

```powershell
kubectl get pods -n banquito-switch -o wide
```

Ver pods solo de Frontend con su nodo:

```powershell
kubectl get pods -n banquito-frontend -o wide
```

Ver los pods agrupados por nodo:

```powershell
kubectl get pods -A -o wide --sort-by=.spec.nodeName
```

Ver detalle de un worker node:

```powershell
kubectl describe node <nombre-del-node>
```

En ese detalle se puede revisar:

| Seccion | Que muestra |
| --- | --- |
| `Capacity` | CPU y memoria total del nodo. |
| `Allocatable` | CPU y memoria disponible para pods. |
| `Non-terminated Pods` | Pods que estan corriendo en ese nodo. |
| `Allocated resources` | Recursos solicitados por los pods del nodo. |
| `Events` | Eventos relevantes del nodo. |

Ver consumo de nodos:

```powershell
kubectl top nodes
```

Ver consumo de pods:

```powershell
kubectl top pods -A
```

Si `kubectl top` no devuelve informacion, significa que las metricas aun no estan disponibles o que no hay pods/nodos activos en ese momento.
