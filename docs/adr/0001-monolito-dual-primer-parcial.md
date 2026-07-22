# 0001. Arquitectura monolítica dual en el primer parcial

## Estado
Aceptado (histórico — superado por ADR-0016 en el segundo parcial)

## Contexto
El equipo no tenía experiencia previa en sistemas distribuidos, el plazo de entrega era de aproximadamente un mes, y el dominio bancario (Core + Switch de pagos) todavía no estaba completamente entendido al inicio del proyecto.

## Decisión
Se construyeron dos monolitos (Core Bancario y Switch de Pagos), cada uno en un solo proceso Spring Boot con arquitectura en capas clásica (Controller → Service → Repository), en vez de descomponer el sistema en microservicios desde el inicio.

## Alternativas consideradas
- Microservicios desde el inicio — descartado por el riesgo de definir bounded contexts incorrectos sin conocer aún el dominio a fondo, lo que hubiera exigido rediseñar la separación varias veces.

## Consecuencias
- Iteración rápida sobre la lógica de negocio sin el overhead de comunicación entre servicios.
- Patrón "Monolith First" (Martin Fowler): separar prematuramente sin bounded contexts claros suele costar más que unificar primero y separar después con el dominio ya validado.
- Costo: todo el Core se redespliega aunque cambie una sola clase; sin escalado independiente por módulo; un fallo de memoria/CPU en un módulo afecta a los demás dentro del mismo proceso.
