# Fase 5 - Revision de Dockerfiles para GKE

## Objetivo

Revisar y ajustar todos los Dockerfiles para que sean compatibles con despliegues en Google Kubernetes Engine.

En esta fase se revisaron:

- Imagen base.
- Copia del artefacto JAR generado por Maven.
- Puertos expuestos.
- Compatibilidad con ejecucion en Kubernetes.
- Defaults locales embebidos en imagenes frontend.

## Criterio aplicado para backends Spring Boot

Los backends quedaron alineados a este patron:

```Dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

COPY --chown=spring:spring target/*.jar app.jar

EXPOSE <HTTP_PORT>
EXPOSE <GRPC_PORT>

USER spring
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Beneficios:

- Imagen runtime ligera.
- No se incluye Maven en la imagen final.
- El contenedor ejecuta con usuario no root.
- El JAR debe ser construido previamente por el pipeline.
- Los puertos quedan declarados para documentacion y manifiestos Kubernetes.

## Dockerfiles backend actualizados

| Servicio | Dockerfile | Puertos expuestos |
| --- | --- | --- |
| account-core-service | `banquito-account-core-service/Dockerfile` | 8081, 9091 |
| accounting-service | `banquito-accounting-service/Dockerfile` | 8082, 9092 |
| party-service | `banquito-party-service/Dockerfile` | 8083, 9093 |
| file-reception-service | `banquito-file-reception-service/Dockerfile` | 8084 |
| tariff-service | `banquito-tariff-service/banquito-tariff-service/Dockerfile` | 8086, 9090 |
| clearinghouse-service | `banquito-clearinghouse-service/Dockerfile` | 8087 |
| report-service | `banquito-report-service/Dockerfile` | 8088 |
| notification-service | `banquito-notification-service/Dockerfile` | 8089, 9092 |

## Criterio aplicado para frontends

Los frontends conservan el patron multi-stage:

1. `node:18-alpine` para compilar Vite.
2. `nginxinc/nginx-unprivileged:alpine` para servir archivos estaticos.
3. Puerto expuesto `8080`.

Se eliminaron defaults `http://localhost:*` en argumentos `VITE_*` para evitar que la imagen construida quede apuntando a servicios locales.

## Dockerfiles frontend actualizados

| Frontend | Dockerfile | Puerto expuesto |
| --- | --- | --- |
| teller | `banquito-teller-frontend/Dockerfile` | 8080 |
| personas | `banquito-web-personas-frontend/Dockerfile` | 8080 |
| empresas | `banquito-web-empresas-frontend/Dockerfile` | 8080 |
| operador | `banquito-frontend-web-operador/Dockerfile` | 8080 |

## Validacion realizada

Se verifico que en los Dockerfiles:

- No queden referencias a `localhost`.
- No queden builders Maven en backends.
- Los backends usen `eclipse-temurin:21-jre-alpine`.
- Los backends copien `target/*.jar`.
- Los backends ejecuten con `USER spring`.
- Los frontends expongan `8080`.

## Importante para pipelines

Despues de esta fase, los Dockerfiles backend esperan que el JAR ya exista antes de construir la imagen.

Por eso, el pipeline de cada backend debe ejecutar antes:

```bash
mvn package -DskipTests
```

Luego:

```bash
docker build -t <image> .
```

Para repositorios con estructura anidada:

- `banquito-tariff-service`: el build debe ejecutarse dentro de `banquito-tariff-service/banquito-tariff-service`.
- `banquito-clearinghouse-service`: el build Docker usa el contexto del modulo Maven anidado.

## Estado de artefactos locales

Al momento de la revision no existen JARs en `target/` para los backends. Por tanto, no se ejecutaron builds Docker locales en esta fase.

La construccion real de imagenes debe hacerse despues de compilar los JARs o dentro del pipeline CI/CD.

## Pendiente tecnico

Algunos workflows actuales de `docker-publish.yml` no ejecutan `mvn package` antes del `docker build`. Esos pipelines deben corregirse en la fase de CI/CD para que sean compatibles con los Dockerfiles actualizados.

Tambien se debe revisar la configuracion Nginx de frontends que aun contiene upstreams pensados para Docker Compose, como `kong-core` o `kong-switch`, porque en nube el API Manager sera un servicio administrado.

## Ajuste posterior: .dockerignore

Durante la construccion real de `account-core-service`, Docker fallo con:

```text
COPY --chown=spring:spring target/*.jar app.jar
lstat /target: no such file or directory
CopyIgnoredFile: Attempting to Copy file "target/*.jar" that is excluded by .dockerignore
```

La causa fue que `.dockerignore` excluia:

```text
target/
```

Como los Dockerfiles backend ahora copian el JAR ya generado desde `target/*.jar`, no se puede excluir `target/` del contexto Docker.

Se corrigio o agrego `.dockerignore` en todos los contextos Java que copian JAR:

```text
banquito-account-core-service/.dockerignore
banquito-accounting-service/.dockerignore
banquito-party-service/.dockerignore
banquito-file-reception-service/.dockerignore
banquito-notification-service/.dockerignore
banquito-report-service/.dockerignore
banquito-clearinghouse-service/.dockerignore
banquito-tariff-service/banquito-tariff-service/.dockerignore
```

Tambien se ajusto `banquito-clearinghouse-service/Dockerfile`, porque su Dockerfile esta en la raiz del repo pero el modulo Maven es anidado. Ahora copia:

```Dockerfile
COPY --chown=spring:spring banquito-clearinghouse-service/target/*.jar app.jar
```

Resultado:

```text
account-core-service compilo con Maven y construyo imagen Docker correctamente.
```

Comandos ejecutados:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
```

Validacion de `.dockerignore`:

```powershell
rg -n "^target/?$|target/" banquito-account-core-service\.dockerignore banquito-accounting-service\.dockerignore banquito-party-service\.dockerignore banquito-file-reception-service\.dockerignore banquito-notification-service\.dockerignore banquito-report-service\.dockerignore banquito-clearinghouse-service\.dockerignore banquito-tariff-service\banquito-tariff-service\.dockerignore
```

Resultado:

```text
No se encontraron exclusiones de target/.
```

## Comandos utilizados

### Listar todos los Dockerfiles

Se uso este comando para ubicar los Dockerfiles en todos los repositorios:

```powershell
Get-ChildItem -Directory | ForEach-Object {
  $repo=$_.Name
  Get-ChildItem -Path $_.FullName -Recurse -File -Filter Dockerfile |
    ForEach-Object {
      [PSCustomObject]@{
        Repo=$repo
        Path=$_.FullName.Substring((Get-Location).Path.Length + 1)
      }
    }
} | Format-Table -AutoSize
```

### Leer el contenido de todos los Dockerfiles

Se uso este comando para revisar cada Dockerfile completo:

```powershell
foreach ($file in Get-ChildItem -Directory | ForEach-Object {
  Get-ChildItem -Path $_.FullName -Recurse -File -Filter Dockerfile
}) {
  Write-Output "### $($file.FullName.Substring((Get-Location).Path.Length + 1))"
  Get-Content $file.FullName
}
```

### Buscar patrones relevantes

Se uso `rg` para encontrar imagenes base, `COPY`, `EXPOSE`, Maven builders y referencias locales:

```powershell
rg -n "server.port|grpc.*port|EXPOSE|COPY target|FROM eclipse|FROM node|nginx-unprivileged" -S -g "Dockerfile" -g "application*.properties" -g "application*.yml" -g "application*.yaml" .
```

Despues de modificar, se verifico que no quedaran `localhost`, builders Maven ni copias desde builder Maven en los Dockerfiles backend:

```powershell
rg -n "localhost|127\.0\.0\.1|FROM maven|COPY --from=builder /app/target|COPY --from=builder /workspace/target" -S -g "Dockerfile" .
```

Resultado:

```text
No se encontraron coincidencias.
```

### Revisar si existian JARs locales

Se uso este comando para verificar si ya existian artefactos `target/*.jar` antes de construir imagenes:

```powershell
$rows = @()
$paths = @(
  'banquito-account-core-service\target\*.jar',
  'banquito-accounting-service\target\*.jar',
  'banquito-party-service\target\*.jar',
  'banquito-file-reception-service\target\*.jar',
  'banquito-notification-service\target\*.jar',
  'banquito-report-service\target\*.jar',
  'banquito-clearinghouse-service\banquito-clearinghouse-service\target\*.jar',
  'banquito-tariff-service\banquito-tariff-service\target\*.jar'
)
foreach ($path in $paths) {
  $files = @(Get-ChildItem -Path $path -ErrorAction SilentlyContinue)
  $rows += [PSCustomObject]@{
    Path=$path
    JarCount=$files.Count
  }
}
$rows | Format-Table -AutoSize
```

Resultado:

```text
JarCount fue 0 para todos los backends.
```

Por eso no se ejecuto `docker build` en esta fase. Primero se debe compilar con Maven.

### Revisar cambios por repositorio

Se uso este comando para confirmar que repositorios quedaron modificados:

```powershell
foreach ($repo in @(
  'banquito-account-core-service',
  'banquito-accounting-service',
  'banquito-party-service',
  'banquito-file-reception-service',
  'banquito-tariff-service',
  'banquito-clearinghouse-service',
  'banquito-report-service',
  'banquito-notification-service',
  'banquito-teller-frontend',
  'banquito-web-personas-frontend',
  'banquito-web-empresas-frontend',
  'banquito-frontend-web-operador'
)) {
  Write-Output "### $repo"
  git -C $repo status --short
}
```

## Ajustes adicionales durante build real

Durante la construccion real de imagenes se encontraron dos problemas:

1. Algunos `.dockerignore` excluian `target/`, por lo que Docker no podia copiar `target/*.jar`.
2. Los frontends fallaban en `npm ci` dentro de Docker por inspeccion SSL local de Avast.

Se ajustaron los `.dockerignore` de backends para permitir copiar el JAR generado y se corrigio el Dockerfile de `clearinghouse-service` porque su JAR se genera dentro del modulo anidado:

```text
banquito-clearinghouse-service/target/*.jar
```

Para los frontends se uso este workaround local:

```dockerfile
RUN npm config set strict-ssl false && npm install --include=dev --no-audit --no-fund
```

Nota: esto fue necesario por el entorno local con inspeccion SSL. En GitHub Actions normalmente no deberia ser necesario desactivar `strict-ssl`.

Comandos usados para construir y publicar imagenes:

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
```

Resultado:

```text
Se construyeron y publicaron las 12 imagenes en Artifact Registry.
```
