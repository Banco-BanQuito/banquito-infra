# ADR-001 (Fase 1): Monolito dual — Core y Switch como dos procesos separados

## Estado
Aceptado (histórico)

## Contexto
El enunciado del primer parcial exige entregar un Core Bancario y un Switch de Pagos Masivos funcionales en aproximadamente un mes, con un equipo que no tenía experiencia previa construyendo sistemas distribuidos. El dominio bancario (qué es exactamente responsabilidad del Core y qué del Switch) tampoco estaba completamente cerrado al arrancar el proyecto — se fue precisando durante el desarrollo.

## Decisión
Se construyen **dos procesos Spring Boot independientes** — `banquito-core` (cuentas, clientes, transacciones) y `switch-pagos` (procesamiento de lotes, tarifas, notificaciones) — cada uno con arquitectura interna en capas (Controller → Service → Repository), en vez de descomponer el sistema en microservicios desde el inicio.

## Por qué monolito y no microservicios desde el inicio
Descomponer en microservicios exige tener **bounded contexts establecidos** antes de trazar las fronteras de red entre servicios, si el límite está mal puesto, corregirlo implica mover código, tablas y contratos entre procesos, no solo entre paquetes. Con el dominio todavía en definición (¿la validación de fraude es del Switch o del Core? ¿la tarifa se calcula antes o después de consultar el saldo?), fijar fronteras de red prematuramente hubiera significado pagar el costo de una migración de servicios varias veces durante el mismo mes de desarrollo. Este es exactamente el razonamiento detrás del patrón "Monolith First" (Martin Fowler, 2015): postergar la descomposición en servicios hasta que el dominio esté suficientemente validado reduce el riesgo de trazar fronteras equivocadas que luego cuestan mucho más corregir en producción que en código.

## Por qué SÍ separar en dos procesos (y no un monolito único)
A pesar de no ir a microservicios, tampoco se optó por un monolito verdaderamente único. Core y Switch tienen ciclos de cambio estructuralmente distintos: el Core cambia con reglas de negocio bancarias que se mueven lento (apertura de cuentas, tipos de transacción), mientras el Switch cambia con cada ajuste de tarifario o integración con un banco externo. Mantenerlos en un solo proceso hubiera acoplado el despliegue de ambos ritmos de cambio. Separarlos en dos procesos, cada uno con su propia base de datos (ver ADR-002 de Fase 1), es la forma más barata de obtener aislamiento de despliegue sin pagar aún el costo operativo de una arquitectura de microservicios completa (service discovery, observabilidad distribuida, contratos versionados).

## Compensaciones
- (+) Iteración rápida sobre la lógica de negocio de cada dominio sin el overhead de una llamada de red por cada operación.
- (+) El aislamiento de despliegue mínimo (dos procesos, no uno) ya reduce el radio de fallo comparado con un monolito único.
- (+) Sienta la base conceptual (separación de dominios + base de datos propia) que la Fase 2 extiende directamente a microservicios reales.
- (-) Todo el Core se redespliega aunque cambie una sola clase — no hay despliegue independiente por módulo dentro de cada proceso.
- (-) Sin escalado independiente: si la carga de transacciones del Core sube pero el Switch está ocioso, no hay forma de escalar solo el Core sin duplicar también el Switch.
