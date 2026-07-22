# ADR-010 (Fase 1): Frontends con stacks tecnológicos independientes por dominio

## Estado
Aceptado (histórico)

## Contexto
Core y Switch necesitaban interfaces web separadas (intranet de operadores para el Core; portal empresarial para el Switch), construidas por sub-equipos que trabajaban en paralelo sobre dominios distintos.

## Decisión
Frontend del Core: React 19 + JSX + Context API + Tailwind, con axios y un interceptor de request central. Frontend del Switch: TypeScript sin framework de componentes — manipulación directa del DOM (`document.querySelector`), estado global propio persistido en `localStorage`, servido originalmente por un servidor Node.js HTTP nativo (reemplazado por Nginx en el despliegue final).

## Por qué no unificar ambos frontends en el mismo stack
Unificar hubiera exigido que uno de los dos sub-equipos abandonara la herramienta con la que ya tenía velocidad de desarrollo, a mitad de un plazo de un mes, para adoptar la del otro equipo. Dado que cada frontend consume una API completamente distinta (Core vs. Switch) y no comparten componentes de UI entre sí, el costo de estandarizar no se traducía en beneficio real de reutilización de código — cada equipo entregó más rápido usando la herramienta que ya dominaba.

## Consecuencias
- (+) Cada sub-equipo pudo avanzar en paralelo sin bloquearse esperando decisiones de arquitectura frontend compartidas.
- (-) Mayor costo de mantenimiento a largo plazo: un desarrollador que rota entre ambos frontends debe operar con dos paradigmas de UI completamente distintos (componentes declarativos vs. manipulación imperativa del DOM).
- (-) El interceptor de axios del Core prueba 4 nombres distintos de clave de `localStorage` "por compatibilidad histórica" — señal textual, encontrada directamente en el código, de que el nombre de la clave de sesión cambió varias veces durante el desarrollo sin una limpieza posterior del código legado.
- (-) El servidor Node.js propio del Switch, reemplazado por Nginx en producción, quedó como código muerto en el repositorio — vestigio de una decisión de despliegue temprana que se abandonó sin eliminar el código asociado.
