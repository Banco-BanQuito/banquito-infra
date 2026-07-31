# ADR-003: Reservar REST solo para cruzar de dominio, gRPC para todo lo demás

## Estado
Aceptado

## Contexto
Que las llamadas entre microservicios fueran por gRPC (una forma de comunicación más rápida y compacta que el HTTP normal) fue una instrucción general del proyecto, no una decisión del equipo — de hecho, para la única llamada que el documento de requisitos describe con detalle (Cuentas hacia Contabilidad), el documento da a elegir entre REST o gRPC, tratándolos como intercambiables. Lo que sí fue decisión del equipo fue no usar gRPC en todos lados como el proyecto pedía en general: se reservó REST específicamente para las llamadas que cruzan de un dominio a otro (Core y Switch), tratando esa frontera distinto al resto.

## Decisión
- **Dentro del mismo dominio**: toda comunicación que espera respuesta usa gRPC.
  - Core: account-core-service se comunica con accounting-service y con party-service.
  - Switch: file-reception-service se comunica con tariff-service y con notification-service (ver ADR-008: el despacho de pagos, antes pensado como un servicio de ruteo aparte, ahora vive en file-reception-service).
- **Al cruzar de un dominio a otro**: se usa REST, el estilo normal de API por HTTP, tratando al otro dominio como si fuera un sistema externo.
  - file-reception-service (Switch) llama a account-core-service (Core) por REST.
  - clearinghouse-service (Switch) llama a accounting-service (Core) por REST.

## Por qué esta regla y no gRPC en todos lados
Un dominio no debería depender del contrato técnico interno de otro dominio — eso ataría la evolución de uno a la del otro. Tratar la frontera entre Core y Switch igual que se trataría una integración con un sistema externo, con un contrato HTTP versionado y estable, hace que cada dominio se consuma como una API pública, no como si fuera parte del mismo código interno.

## Consecuencias
- A favor: cada dominio puede cambiar y mejorar su comunicación interna por gRPC sin romper al otro dominio.
- A favor: las llamadas entre dominios son más fáciles de revisar y depurar, porque usan el HTTP estándar, y más fáciles de exponer después a través del API Gateway si hiciera falta.
- En contra: las llamadas entre dominios son un poco más lentas que gRPC, aceptable porque no son llamadas de muy alta frecuencia — son débitos y créditos puntuales, no un flujo continuo de datos.
