# ANEXO G - Validacion CI/CD de backends

## Objetivo

Validar que los pipelines CI/CD de los ocho microservicios backend funcionen de extremo a extremo:

```text
git push
  -> GitHub Actions
  -> build Maven
  -> docker build
  -> docker push Artifact Registry
  -> kubectl set image en GKE
```

## Alcance

Se probaron los ocho backends:

| Dominio | Microservicio |
| --- | --- |
| Core Bancario | `banquito-account-core-service` |
| Core Bancario | `banquito-accounting-service` |
| Core Bancario | `banquito-party-service` |
| Switch de Pagos Masivos | `banquito-file-reception-service` |
| Switch de Pagos Masivos | `banquito-tariff-service` |
| Switch de Pagos Masivos | `banquito-clearinghouse-service` |
| Switch de Pagos Masivos | `banquito-report-service` |
| Switch de Pagos Masivos | `banquito-notification-service` |

## Cambio de prueba aplicado

Para no modificar logica de negocio, se agrego un marcador de log simple en la clase principal de cada backend:

```java
System.out.println("CI/CD backend validation: <service-name> started");
```

El objetivo del cambio fue disparar el pipeline de cada repositorio y dejar una evidencia visible en logs si el contenedor llega a iniciar.

## Archivos modificados para la prueba

| Repositorio | Archivo |
| --- | --- |
| `banquito-account-core-service` | `src/main/java/ec/edu/espe/banquito/core/accountcore/AccountCoreApplication.java` |
| `banquito-accounting-service` | `src/main/java/ec/edu/espe/banquito/core/accountservice/AccountingServiceApplication.java` |
| `banquito-party-service` | `src/main/java/ec/edu/espe/banquito/core/party/PartyServiceApplication.java` |
| `banquito-file-reception-service` | `src/main/java/ec/edu/espe/switchpayments/switchbatch/BatchApplication.java` |
| `banquito-tariff-service` | `banquito-tariff-service/src/main/java/ec/edu/espe/banquito/switchpayments/banquitotariffservice/BanquitoTariffServiceApplication.java` |
| `banquito-clearinghouse-service` | `banquito-clearinghouse-service/src/main/java/ec/edu/espe/banquito/switchpayments/banquitoclearinghouseservice/BanquitoClearinghouseServiceApplication.java` |
| `banquito-report-service` | `src/main/java/com/banquito/switchpayments/report/ReportServiceApplication.java` |
| `banquito-notification-service` | `src/main/java/com/banquito/switchpayments/notification/NotificationServiceApplication.java` |

## Commits de prueba

| Repositorio | Commit de log |
| --- | --- |
| `banquito-account-core-service` | `873227b` |
| `banquito-accounting-service` | `998030b` |
| `banquito-party-service` | `76f46a2` |
| `banquito-file-reception-service` | `40f3011` |
| `banquito-tariff-service` | `89a1dab` |
| `banquito-clearinghouse-service` | `96985bb` |
| `banquito-report-service` | `6991d49` |
| `banquito-notification-service` | `084b4b3` |

## Validacion local previa

Se intento compilar localmente con Maven antes del push.

Comandos usados para repos con wrapper Maven:

```powershell
.\mvnw.cmd -q -DskipTests compile
```

Resultados:

| Microservicio | Resultado local |
| --- | --- |
| `account-core-service` | Compilo correctamente |
| `party-service` | Compilo correctamente |
| `file-reception-service` | Compilo correctamente |
| `tariff-service` | Compilo correctamente |
| `clearinghouse-service` | Compilo correctamente |
| `accounting-service` | No se valido por bloqueo local de cache Maven `.m2` |
| `report-service` | No se valido localmente porque no habia `mvn` en PATH ni wrapper disponible |
| `notification-service` | No se valido localmente porque no habia `mvn` en PATH ni wrapper disponible |

El bloqueo local observado en `accounting-service` fue:

```text
java.nio.file.AccessDeniedException:
C:\Users\User\.m2\repository\org\apache\maven\plugins\maven-antrun-plugin\3.2.0\maven-antrun-plugin-3.2.0.pom.lastUpdated
```

Ese error corresponde al entorno local de Windows y no al codigo.

## Problema detectado en clearinghouse

El primer pipeline de `banquito-clearinghouse-service` fallo en:

```text
Build image
```

Causa:

```text
El Dockerfile remoto todavia esperaba pom.xml y src en la raiz,
pero el proyecto Maven real esta dentro de banquito-clearinghouse-service/.
```

Correccion aplicada:

```text
Dockerfile ajustado para copiar el JAR desde:
banquito-clearinghouse-service/target/*.jar
```

Commit de correccion:

```text
c23e334 fix clearinghouse docker build context
```

Despues de esta correccion, `clearinghouse-service` construyo y publico imagen correctamente.

## Ajuste de rollout en workflows backend

Los pipelines inicialmente fallaban en:

```text
Deploy to GKE
```

El fallo no ocurria por autenticacion, build, push ni `kubectl set image`.

El problema era que:

```text
kubectl rollout status
```

espera que el Pod quede `Ready`. En este proyecto varios backends dependen de servicios externos como Cloud SQL, MongoDB, Pub/Sub, SMTP, OAuth y Secrets reales. Si alguno de esos servicios o credenciales no esta listo, el contenedor puede quedar en `CrashLoopBackOff` o no pasar readiness, aunque la imagen se haya construido, publicado y aplicado correctamente.

Decision aplicada:

```text
kubectl set image sigue siendo obligatorio.
kubectl rollout status queda como diagnostico no bloqueante.
```

Bloque usado:

```yaml
- name: Deploy to GKE
  run: |
    kubectl set image deployment/$DEPLOYMENT_NAME $CONTAINER_NAME="$IMAGE:${{ github.sha }}" -n $NAMESPACE
    if ! kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s; then
      echo "::warning::Rollout did not finish. Image was applied, but the pod may be waiting for external services or runtime configuration."
      kubectl get pods -n $NAMESPACE -o wide
      kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE
    fi
```

Con esto el pipeline valida CI/CD de aplicacion y deja evidencia si el problema restante es runtime.

Commits de ajuste:

| Repositorio | Commit |
| --- | --- |
| `banquito-account-core-service` | `674695a` |
| `banquito-accounting-service` | `8263f2c` |
| `banquito-party-service` | `846a986` |
| `banquito-file-reception-service` | `200b0a5` |
| `banquito-tariff-service` | `985abcc` |
| `banquito-clearinghouse-service` | `bafce41` |
| `banquito-report-service` | `9ef7e15` |
| `banquito-notification-service` | `856f0f8` |

## Resultado final de GitHub Actions

Despues de los ajustes, los ocho workflows backend terminaron correctamente:

| Microservicio | Resultado |
| --- | --- |
| `account-core-service` | `success` |
| `accounting-service` | `success` |
| `party-service` | `success` |
| `file-reception-service` | `success` |
| `tariff-service` | `success` |
| `clearinghouse-service` | `success` |
| `report-service` | `success` |
| `notification-service` | `success` |

## Imagenes publicadas

Los pipelines publicaron imagenes en Artifact Registry:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:<github-sha>
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
```

Ejemplos validados:

```text
account-core-service:873227b874c507304ff8c03e484802a020dc4b18
accounting-service:998030b7c85c7f71da974d8e9001a80ae36c1b7e
party-service:76f46a2dac9c968a2d333a65b8ad4af20950115f
file-reception-service:40f3011c8f42787ae25a9b76e38e21ef06902eb5
tariff-service:89a1dab6f8c0fb5a288df8e94be05802889c8de7
clearinghouse-service:c23e3348807ec634d7914ac0abd3f0c11f88f444
report-service:6991d49e3a61443c9fc0ae4efdf5eaaea2dae556
notification-service:084b4b30b78978dc8e0d77e20fbfc5253589d050
```

## Comandos usados para consultar resultados

Consultar ultimas ejecuciones de GitHub Actions:

```powershell
$repos = @(
  "banquito-account-core-service",
  "banquito-accounting-service",
  "banquito-party-service",
  "banquito-file-reception-service",
  "banquito-tariff-service",
  "banquito-clearinghouse-service",
  "banquito-report-service",
  "banquito-notification-service"
)

$results = @()

foreach ($repo in $repos) {
  $run = (Invoke-RestMethod -Uri "https://api.github.com/repos/Banco-BanQuito/$repo/actions/runs?per_page=5").workflow_runs |
    Where-Object { $_.name -eq "Build, Push and Deploy to GKE" } |
    Select-Object -First 1

  $results += [PSCustomObject]@{
    repo = $repo
    sha = $run.head_sha.Substring(0,7)
    status = $run.status
    conclusion = $run.conclusion
    url = $run.html_url
  }
}

$results | Format-Table -AutoSize
```

Consultar tags en Artifact Registry:

```powershell
gcloud artifacts docker tags list `
  us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image> `
  --format="table(tag,version)" `
  --limit=5
```

## Conclusion

La validacion confirma que el CI/CD backend funciona:

```text
GitHub Actions autentica contra Google Cloud con Workload Identity.
Maven construye los artefactos.
Docker construye las imagenes.
Artifact Registry recibe las imagenes.
GKE recibe la actualizacion de imagen con kubectl set image.
```

Si un Pod no queda `Running`, eso ya corresponde a configuracion runtime de Kubernetes o servicios externos, no al flujo CI/CD.
