# Matriz y sustentacion de requisitos no funcionales

## Responsable

Alan.

## Alcance

Este documento explica como se implementan y sustentan los requisitos no funcionales del proyecto BanQuito usando la infraestructura desplegada para la demo en Google Cloud Platform.

El proyecto tiene dos aplicaciones principales:

1. Core Bancario.
2. Switch de Pagos Masivos.

Ambas aplicaciones fueron llevadas a una arquitectura cloud-native usando contenedores, Kubernetes, servicios administrados de nube, API Manager, OAuth 2, Secret Manager, Pub/Sub, observabilidad y pipelines CI/CD.

## Resumen ejecutivo para sustentacion

Los requisitos no funcionales no representan una funcionalidad puntual del negocio, sino atributos de calidad del sistema: seguridad, disponibilidad, escalabilidad, mantenibilidad, observabilidad, configurabilidad, portabilidad y automatizacion del despliegue.

En BanQuito estos atributos se implementaron principalmente desde la capa de infraestructura cloud. Los microservicios backend del Core Bancario y del Switch de Pagos Masivos se despliegan como contenedores en Google Kubernetes Engine Autopilot. Los frontends se publican como archivos estaticos en una VM con Nginx y consumen APIs mediante Apigee. Las bases de datos, el API Manager, OAuth 2, los secretos y el broker de mensajeria se consumen como servicios administrados de nube. El despliegue se automatiza mediante GitHub Actions.

## Matriz de requisitos no funcionales

| RNF | Requisito solicitado | Implementacion en BanQuito | Evidencia tecnica | Estado |
| --- | --- | --- | --- | --- |
| Orquestacion de contenedores | Las dos aplicaciones deben desplegarse en un orquestador de contenedores provisto por la nube. | Core Bancario y Switch de Pagos Masivos se despliegan en Google Kubernetes Engine Autopilot. Los frontends se sirven desde VM/Nginx porque son estaticos. | `kubectl get deployments -A`, consola de GKE. | Implementado |
| Separacion logica | Mantener separacion entre dominios de la solucion. | Se usan namespaces separados: `banquito-core`, `banquito-switch` y `banquito-gateway`. | `kubectl get namespaces`. | Implementado |
| Bases de datos cloud | Todos los servicios SQL y NoSQL deben ser provistos por la nube. | PostgreSQL y MySQL se consumen desde Cloud SQL. MongoDB se consume desde MongoDB Atlas. | Consola Cloud SQL, MongoDB Atlas, variables en Secret Manager. | Implementado |
| API Manager cloud | El API Manager debe ser un servicio provisto por la nube. | Las APIs publicas se exponen mediante Google Apigee. Los frontends no llaman directamente a los servicios internos de Kubernetes. | Consola Apigee, URL base `https://136.68.89.25.nip.io`. | Implementado |
| Message Broker cloud | El servidor de colas debe ser provisto por la nube. | RabbitMQ fue reemplazado por Google Cloud Pub/Sub para el procesamiento asincrono del Switch. | Topics y subscriptions en Pub/Sub. | Implementado |
| Seguridad OAuth 2 | Las aplicaciones Web y el Switch deben invocar APIs protegidas con OAuth 2. | Google Identity Platform emite JWT. Apigee valida los tokens antes de enrutar hacia GKE. | Politica VerifyJWT en Apigee, login contra Identity Platform. | Implementado |
| Integracion OAuth en API Manager | El API Manager debe integrarse con OAuth 2. | Apigee valida firma, issuer, audience y expiracion del JWT emitido por Identity Platform. | Trace de Apigee, politica VerifyJWT. | Implementado |
| API Key por aplicacion | Cada aplicacion que llame APIs expuestas en API Manager debe tener su propia API Key. | Se definieron API Keys separadas para Teller, Operador, Web Personas y Web Empresas. | Apps/Consumer Keys en Apigee y secretos en Secret Manager. | Implementado |
| Baul de secretos | Conexiones a BD y variables sensibles deben almacenarse en Key Vault cloud. | Google Secret Manager almacena credenciales de BD, API keys, Identity Platform y passwords. | Consola Secret Manager. | Implementado |
| Configurabilidad | Los endpoints y credenciales no deben estar quemados en codigo. | ConfigMaps almacenan configuracion no sensible. Secret Manager y Kubernetes Secrets almacenan valores sensibles. | `kubectl get configmap -A`, Secret Manager. | Implementado |
| Despliegue automatizado | Crear pipelines para despliegue automatizado en el orquestador. | Los backends usan GitHub Actions para compilar, construir imagen Docker, publicar en Artifact Registry y desplegar en GKE. Los frontends usan GitHub Actions para compilar Vite y publicar `dist` en VM/Nginx. | Workflows de GitHub Actions, imagenes en Artifact Registry, despliegue SSH a VM. | Implementado |
| Portabilidad | Las aplicaciones deben poder ejecutarse como artefactos desplegables por ambiente. | Los microservicios backend se empaquetan como imagenes Docker. Los frontends se empaquetan como artefactos estaticos `dist`. | Dockerfiles backend, Artifact Registry, workflows `deploy-vm.yml`. | Implementado |
| Escalabilidad horizontal | El sistema debe poder crecer ante carga. | Se configuraron HPA con minimo 1 y maximo 3 replicas. GKE Autopilot administra nodos segun capacidad disponible. | `kubectl get hpa -A`. | Implementado |
| Disponibilidad | Los servicios deben mantenerse operativos ante fallos de pods. | Kubernetes recrea pods si fallan o son eliminados. Los Services mantienen nombres DNS internos estables. | Prueba de eliminacion de pod y recreacion automatica. | Implementado |
| Comunicacion interna | Los microservicios deben comunicarse sin exponer todo publicamente. | Los backends usan Services `ClusterIP`; la comunicacion interna se resuelve por DNS de Kubernetes y gRPC/HTTP interno. | `kubectl get svc -A`. | Implementado |
| Exposicion controlada | No se deben crear muchas IPs publicas innecesarias. | Se usa entrada controlada por Gateway/Ingress y Apigee como puerta publica principal para APIs. | `kubectl get gateway -A`, `kubectl get httproute -A`, Apigee. | Implementado |
| Observabilidad | Se deben implementar metricas para servicios contratados. | GKE, Cloud SQL, Pub/Sub, Apigee y Secret Manager generan metricas/logs en Google Cloud Monitoring/Logging. Los pods pueden revisarse con `kubectl logs` y `kubectl top`. | Cloud Monitoring, Cloud Logging, `kubectl logs`, `kubectl top`. | Implementado |
| Eficiencia de recursos | Controlar consumo y costos durante la demo. | Los deployments backend pueden escalarse a `0` cuando no se usan. Los frontends se retiraron de GKE para reducir Pods, HPA e IPs asociadas. | `kubectl scale deployment --all --replicas=0`, `kubectl get deploy -A`. | Implementado para operacion |
| Pruebas unitarias | Se deben implementar pruebas unitarias para microservicios Core y Switch. | Los pipelines contemplan etapa de build/test. El cumplimiento real depende de cada repositorio de microservicio. | Reportes Maven, JaCoCo o Sonar. | En progreso por equipos de desarrollo |
| Cobertura 70% | Las pruebas deben tener al menos 70% de coverage en controladores y servicios. | Debe validarse con JaCoCo/Sonar en cada microservicio. Infraestructura CI/CD puede ejecutar la validacion. | Reporte de coverage por repositorio. | Brecha pendiente |

## Sustentacion por requisito

### 1. Orquestacion en la nube

El requisito pide que las dos aplicaciones sean desplegadas en un orquestador de contenedores provisto por la nube.

La solucion usa Google Kubernetes Engine Autopilot. En GKE se despliegan los microservicios propios del Core y del Switch. Los frontends se publican desde una VM con Nginx, porque son aplicaciones estaticas generadas por Vite. No se despliegan bases de datos ni broker dentro del cluster, porque esos componentes se consumen como servicios administrados.

Namespaces utilizados:

- `banquito-core`: microservicios del Core Bancario.
- `banquito-switch`: microservicios del Switch de Pagos Masivos.
- Frontends: fuera de GKE, publicados en VM/Nginx.

Comando de evidencia:

```powershell
kubectl get namespaces
kubectl get deployments -A
kubectl get pods -A
```

### 2. Bases de datos como servicios cloud

El requisito indica que todos los servicios de base de datos SQL y NoSQL deben ser provistos por la nube.

La implementacion usa:

- Cloud SQL PostgreSQL para servicios que usan PostgreSQL.
- Cloud SQL MySQL para servicios que usan MySQL.
- MongoDB Atlas para persistencia NoSQL.

Los microservicios no usan bases locales dentro de Kubernetes. Las conexiones se inyectan por variables de entorno y secretos.

Ejemplos:

- `account-core-service` y `accounting-service` usan PostgreSQL.
- `party-service`, `file-reception-service` y `tariff-service` usan MySQL.
- `file-reception-service`, `clearinghouse-service`, `report-service` y `notification-service` usan MongoDB Atlas.

### 3. API Manager provisto por la nube

El API Manager se implementa con Google Apigee.

Los frontends no consumen directamente los Services internos de Kubernetes. La ruta esperada es:

```text
Frontend
  -> Apigee
  -> Gateway/Ingress de GKE
  -> Service interno de Kubernetes
  -> Pod del microservicio
```

Apigee permite centralizar:

- Enrutamiento.
- API Keys.
- Validacion OAuth/JWT.
- CORS.
- Control de acceso.
- Trazabilidad de llamadas.

URL base usada para APIs:

```text
https://136.68.89.25.nip.io
```

### 4. Message Broker cloud

El requisito pide que el servidor de colas sea provisto por la nube.

Inicialmente existia RabbitMQ en despliegues locales, pero para la arquitectura cloud se migro el procesamiento asincrono a Google Cloud Pub/Sub.

Pub/Sub se utiliza especialmente en el flujo de pagos masivos:

```text
file-reception-service
  -> publica lineas o eventos de procesamiento
  -> Pub/Sub
  -> clearinghouse-service consume mensajes
  -> procesa compensacion / clearing
```

Esto evita operar RabbitMQ dentro de Kubernetes y cumple el requisito de broker administrado por nube.

### 5. Seguridad OAuth 2 e Identity Platform

El esquema de seguridad usa Google Identity Platform como proveedor OAuth 2 / identidad.

Flujo general:

```text
Usuario inicia sesion en frontend
  -> Identity Platform valida credenciales
  -> devuelve idToken JWT
  -> frontend llama Apigee con Authorization: Bearer <JWT>
  -> Apigee valida JWT
  -> si es valido enruta a GKE
```

Apigee valida:

- Firma del token.
- Issuer.
- Audience.
- Expiracion.
- Formato JWT.

Ademas, los frontends implementan refresco de token usando `refreshToken`, para evitar que el usuario tenga que iniciar sesion nuevamente cada vez que vence el `idToken`.

### 6. API Key por aplicacion

El requisito pide que cada aplicacion que consuma APIs expuestas por el API Manager tenga su propia API Key.

Se definieron API Keys separadas para:

- Teller.
- Operador.
- Web Personas.
- Web Empresas.

Cada frontend envia:

```text
Authorization: Bearer <JWT>
x-api-key: <API_KEY_DE_LA_APP>
apikey: <API_KEY_DE_LA_APP>
```

Esto permite que Apigee identifique la aplicacion consumidora, aplique politicas por cliente y trace el consumo por frontend.

### 7. Secret Manager como Key Vault

Las credenciales y valores sensibles no se dejan quemados en el codigo ni en manifiestos publicos.

Se almacenan en Google Secret Manager:

- URLs de bases de datos.
- Usuarios y passwords.
- API Keys.
- Credenciales de Identity Platform.
- Passwords temporales.
- Variables sensibles de integracion.

En Kubernetes se consumen como Secrets o mediante integracion con Secret Manager.

Comandos de evidencia:

```powershell
gcloud secrets list --project project-47695a8e-7cb2-4352-af2
kubectl get secrets -A
```

### 8. CI/CD

El requisito pide pipelines para despliegue automatizado en el orquestador.

Los pipelines de GitHub Actions siguen el flujo:

```text
git push
  -> checkout
  -> build/test
  -> docker build
  -> push a Artifact Registry
  -> kubectl set image / rollout en GKE
```

El uso de Artifact Registry permite integrar el registro de imagenes con Google Cloud IAM y GKE.

Evidencias:

- Workflows en `.github/workflows`.
- Ejecuciones en GitHub Actions.
- Imagenes publicadas en Artifact Registry.
- Deployments actualizados con tags por commit SHA.

Comando para ver imagenes desplegadas:

```powershell
kubectl get deployment -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image
```

### 9. Escalabilidad

La escalabilidad se implementa en dos niveles:

1. Kubernetes HPA escala pods.
2. GKE Autopilot administra la capacidad de nodos.

Los HPA se configuraron con:

- Minimo: 1 pod.
- Maximo: 3 pods.
- Escalamiento segun CPU y memoria.

Comando de evidencia:

```powershell
kubectl get hpa -A
```

Importante para la sustentacion:

HPA no crea nodos directamente. HPA crea mas replicas de pods cuando hay carga. Si no hay capacidad suficiente, GKE Autopilot intenta aprovisionar nodos. Si existe limite de cuota en GCP, algunos pods pueden quedar en `Pending` hasta que se libere capacidad o se aumente la cuota.

### 10. Disponibilidad y tolerancia a fallos

Kubernetes aporta disponibilidad basica porque mantiene el estado deseado de los Deployments.

Si un pod falla o se elimina, Kubernetes crea otro automaticamente.

Comandos de evidencia:

```powershell
kubectl get pods -n banquito-core
kubectl delete pod <nombre-pod> -n banquito-core
kubectl get pods -n banquito-core
```

La defensa tecnica es:

El sistema no depende de un proceso manual para reiniciar un microservicio. Kubernetes detecta que el numero de replicas reales no coincide con el numero deseado y crea un nuevo pod.

### 11. Observabilidad

El requisito indica que se deben implementar metricas para los servicios contratados.

La solucion usa la observabilidad nativa de Google Cloud:

- GKE entrega logs y metricas de pods, nodos y workloads.
- Cloud SQL entrega metricas de conexiones, CPU, memoria, almacenamiento y latencia.
- Pub/Sub entrega metricas de mensajes publicados, mensajes no reconocidos y edad del mensaje mas antiguo.
- Apigee entrega trazas, errores, latencias y consumo por API Key.
- Secret Manager registra accesos y auditoria.

Comandos de evidencia operativa:

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl logs -n banquito-switch deployment/file-reception-service --tail=100
kubectl get hpa -A
kubectl top pods -A
```

Nota:

`kubectl top` requiere que las metricas esten disponibles en el cluster. En GKE Autopilot normalmente se integran con Cloud Monitoring.

### 12. Eficiencia de costos para demo

Como GKE Autopilot factura recursos solicitados por los pods, para controlar costos durante pruebas se apagan workloads cuando no se usan.

Ejemplo:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

Esto no elimina:

- Manifiestos.
- Services.
- Ingress/Gateway.
- Certificados.
- Secretos.
- Imagenes.
- Bases de datos.

Solo reduce a cero los pods de aplicacion.

## Brechas y riesgos identificados

| Brecha | Impacto | Accion recomendada |
| --- | --- | --- |
| Cobertura de pruebas unitarias no confirmada al 70% en todos los microservicios. | Puede incumplir el requisito de testing. | Configurar JaCoCo/Sonar y agregar pruebas en controladores y servicios. |
| Cuota de GCP limitada para correr todos los pods con HPA activo. | Algunos pods pueden quedar `Pending` si Autopilot no puede crear nodos. | Solicitar aumento de cuota o levantar por bloques durante la demo. |
| Algunas rutas requieren ajuste en Apigee. | Puede devolver 403 si la API Key o el producto no incluyen la ruta. | Validar API Products, rutas, CORS, VerifyAPIKey y VerifyJWT. |
| Dependencia de servicios externos. | Si Cloud SQL, MongoDB Atlas, Pub/Sub o Apigee tienen problemas, impactan flujos. | Monitorear servicios administrados y documentar dependencias. |

## Evidencias recomendadas para la presentacion

### Kubernetes

```powershell
kubectl get namespaces
kubectl get deployments -A
kubectl get pods -A
kubectl get svc -A
kubectl get hpa -A
```

### Imagenes desplegadas

```powershell
kubectl get deployment -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image
```

### Logs

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl logs -n banquito-switch deployment/file-reception-service --tail=100
```

### Apagar para no consumir

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

### Levantar por bloques

Core:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
```

Switch minimo para pagos:

```powershell
kubectl scale deployment file-reception-service clearinghouse-service --replicas=1 -n banquito-switch
```

Frontends:

```text
Los frontends se levantan en la VM/Nginx mediante el workflow deploy-vm.yml de cada repositorio.
```

## Guion corto para defender

Mi responsabilidad fue sustentar los requisitos no funcionales desde la infraestructura desplegada.

Primero, el requisito de orquestacion se cumple porque las dos aplicaciones principales, Core Bancario y Switch de Pagos Masivos, se desplegaron sobre Google Kubernetes Engine Autopilot. Las aplicaciones se separaron por namespaces para mantener orden y aislamiento logico.

Segundo, los servicios de plataforma no se ejecutan como contenedores propios. Las bases de datos se consumen como servicios cloud: PostgreSQL y MySQL en Cloud SQL, y MongoDB en MongoDB Atlas. El broker de mensajeria se implementa con Google Cloud Pub/Sub. El API Manager es Google Apigee y OAuth 2 se implementa con Google Identity Platform.

Tercero, la seguridad se centraliza en Apigee. Los frontends y las integraciones consumen APIs enviando un JWT emitido por Identity Platform y una API Key propia por aplicacion. Apigee valida el token y la API Key antes de permitir el paso hacia GKE.

Cuarto, los secretos se manejan con Google Secret Manager. Esto evita guardar passwords, conexiones a bases de datos o API keys directamente en el codigo o en archivos expuestos.

Quinto, el despliegue automatizado se cumple con GitHub Actions. Cada push construye la imagen Docker, la publica en Artifact Registry y actualiza el deployment correspondiente en GKE.

Finalmente, la observabilidad se cubre con Cloud Logging y Cloud Monitoring, ademas de comandos operativos de Kubernetes como `kubectl logs`, `kubectl get hpa` y `kubectl top`. Tambien se implemento HPA para escalabilidad horizontal, aunque en la demo se debe considerar la cuota disponible de Google Cloud.

## Frase de cierre

La arquitectura cumple los RNF principales porque no depende de infraestructura manual ni servicios locales. Usa servicios administrados de nube para orquestacion, seguridad, mensajeria, secretos, bases de datos, observabilidad y despliegue automatizado. Las brechas pendientes estan relacionadas principalmente con cobertura de pruebas unitarias y ajustes finos de cuota/rutas, no con el modelo de arquitectura cloud propuesto.

