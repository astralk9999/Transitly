# ADR-002: Freezed para modelos de dominio

## Estado
Aceptado

## Contexto
Los modelos de dominio (Route, Stop, User, Incident, etc.) necesitan:
- Igualdad por valor (dos objetos con mismos campos = iguales)
- `copyWith` inmutable para actualizaciones parciales
- Serialización JSON (desde Supabase y a Hive)
- Bajo boilerplate (27+ modelos y creciendo)

## Decisión
Usamos **freezed** (`@freezed`) con `json_serializable` para todos los modelos de valor.

## Alternativas consideradas

### Clases Dart puras con equatable
Usado inicialmente. Descartado por:
- `copyWith` manual en cada modelo → propenso a errores
- `fromJson`/`toJson` manual → duplicación de nombres de campo
- Union types imposibles sin freezed

### built_value
Descartado. Más verboso que freezed, generación más lenta, comunidad más pequeña.

## Consecuencias

### Positivas
- `copyWith` autogenerado para campos anidados
- Union types para estados (ej. `AsyncValue`, estados de formulario)
- `fromJson`/`toJson` consistente con `explicit_to_json: true`
- `include_if_null: false` reduce payload en Hive

### Negativas
- Requiere `build_runner` → paso extra en CI y desarrollo local
- Archivos `.freezed.dart` y `.g.dart` commiteados (decisión consciente para clonar-y-ejecutar)
- Migrar modelos existentes requiere herramienta `tool/build.sh`

### Restricciones
- `build.yaml` con `explicit_to_json: true`, `include_if_null: false`
- `fromJson` en modelos migrados es `static`, no `factory`
- Regenerar tras: añadir/renombrar/borrar campos, `git pull` que toque modelos

## Referencias
- `build.yaml` — configuración de codegen
- `tool/build.sh` — script de regeneración
- `lib/shared/models/` — 27+ modelos @freezed
