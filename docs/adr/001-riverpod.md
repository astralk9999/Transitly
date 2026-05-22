# ADR-001: Riverpod como gestor de estado

## Estado
Aceptado

## Contexto
Transitly necesita un gestor de estado que:
- Sea reactivo (cambios en datos → UI se actualiza automáticamente)
- Soportase inyección de dependencias para testing
- Permita invalidación y refresco de caché (stale-while-revalidate en repos)
- No dependa de BuildContext (acceso desde capa de datos)
- Tenga buen rendimiento con colecciones grandes (598 paradas, rutas)

## Decisión
Usamos **Riverpod 2.x** (`flutter_riverpod`) como gestor de estado único.

## Alternativas consideradas

### Provider
Descartado. Acoplado a BuildContext, sin soporte nativo para autoDispose, sin `.family` para providers parametrizados.

### BLoC
Descartado. Demasiado boilerplate para el número de streams que necesitamos (12 repos × múltiples métodos). La separación Event/State añade fricción sin beneficio proporcional.

### GetX
Descartado. Inyección global oculta, difícil de testear, viola varias reglas de nuestra arquitectura de capas.

## Consecuencias

### Positivas
- Providers tipados con genéricos → seguridad en tiempo de compilación
- `ref.watch` / `ref.read` sin BuildContext → capa de datos puede reaccionar
- `autoDispose` libera memoria cuando pantallas se desmontan
- `.family` permite providers parametrizados (ej. `routeDetailProvider(id)`)
- `overrideWithValue` simplifica inyección en tests

### Negativas
- Curva de aprendizaje para `ref` vs `context`
- `ProviderObserver` no captura todos los errores por defecto (solucionado con `TransitProviderObserver`)

## Referencias
- [Riverpod documentation](https://riverpod.dev)
- `lib/core/utils/transit_provider_observer.dart` — captura errores → Sentry
- `lib/shared/providers/` — providers globales
