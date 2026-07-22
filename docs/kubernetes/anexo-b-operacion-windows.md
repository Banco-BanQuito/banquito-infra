# Anexo B - Operacion desde Windows 11

## Contexto

Estos comandos se ejecutan desde PowerShell.

## Conectarse al cluster

```powershell
gcloud config set project project-47695a8e-7cb2-4352-af2
gcloud container clusters get-credentials banquito-cluster-east --region us-east1 --project project-47695a8e-7cb2-4352-af2
kubectl config current-context
```

## Ver recursos

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get pods -n banquito-frontend
kubectl get deployments -n banquito-core
kubectl get deployments -n banquito-switch
kubectl get deployments -n banquito-frontend
kubectl get svc -n banquito-core
kubectl get svc -n banquito-switch
kubectl get svc -n banquito-frontend
```

Todos los namespaces:

```powershell
kubectl get pods -A
```

## Logs y eventos

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl describe pod -n banquito-core <pod>
kubectl get events -n banquito-core --sort-by=.lastTimestamp
```

## Consumo y rendimiento

```powershell
kubectl top nodes
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-frontend
```

## Levantar o apagar por bloques

Core:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-core
```

Switch:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

Frontends:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-frontend
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

## Apagar backends para no consumir

Cuando los Pods esten en `CrashLoopBackOff`, `Pending` o no se este probando runtime, se pueden dejar los backends en `0/0` para reducir consumo mientras se corrigen Secrets, bases de datos o RabbitMQ.

Esta operacion no elimina recursos. Solo cambia la cantidad de replicas de los `Deployments`.

No se afecta DuckDNS si solo se apagan pods:

```text
banquito-personas.duckdns.org
banquito-empresas.duckdns.org
banquito-teller.duckdns.org
banquito-operador.duckdns.org
```

DuckDNS solo resuelve los dominios hacia la IP publica del Gateway. Esa IP se mantiene mientras no se eliminen los recursos de entrada.

No eliminar si se quiere conservar DuckDNS/HTTPS:

```text
Gateway
HTTPRoute
Services
Namespaces
IP publica
Certificado administrado
```

Comandos usados en este entorno:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-switch
```

Verificar:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-core
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-switch
```

El resultado esperado en Deployments es:

```text
READY   UP-TO-DATE   AVAILABLE
0/0     0            0
```

Si tambien se quieren apagar los frontends:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-frontend
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-frontend
```

Para volver a levantar:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-switch
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-frontend
```

Nota: `--insecure-skip-tls-verify=true` se uso solo por un problema local de confianza TLS de `kubectl` contra el endpoint del cluster. En un entorno limpio se deben usar los mismos comandos sin esa bandera.

Apagar todo:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

Verificar que los dominios siguen resolviendo:

```powershell
nslookup banquito-personas.duckdns.org
nslookup banquito-empresas.duckdns.org
nslookup banquito-teller.duckdns.org
nslookup banquito-operador.duckdns.org
```

Resultado esperado:

```text
Address: 8.233.141.65
```

Verificar que el Gateway sigue existiendo:

```powershell
kubectl get gateway -A
kubectl get httproute -A
```

Nota:

```text
Con los pods apagados, los dominios pueden abrir pero devolver 503/404/timeout porque no hay backend disponible.
Eso es normal. El DNS y la IP no estan rotos; solo no hay Pods atendiendo trafico.
```

## Error comun

No ejecutar desde la raiz del workspace:

```powershell
kubectl apply --recursive -f .
```

Debe ejecutarse desde:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply --recursive -f .
```

Mejor opcion para no pisar Secrets:

```powershell
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f gateway
kubectl apply -f account-core
kubectl apply -f accounting
kubectl apply -f party
kubectl apply -f file-reception
kubectl apply -f tariff
kubectl apply -f clearinghouse
kubectl apply -f report
kubectl apply -f notification
kubectl apply -f teller
kubectl apply -f personas
kubectl apply -f empresas
kubectl apply -f operador
```
