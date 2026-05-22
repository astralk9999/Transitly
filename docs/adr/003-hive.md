# ADR-003: Hive como caché local

## Estado
Aceptado

## Contexto
La app necesita caché local para:
- Funcionamiento offline-first (red intermitente en transporte público)
- Arranque rápido sin esperar red (rutas, paradas, horarios ya cacheados)
- Cola de sincronización offline (pending actions)
- Preferencias de usuario persistentes

## Decisión
Usamos **Hive 2.x** (`hive_flutter`) como base de datos local clave-valor.

## Alternativas consideradas

### SQLite (sqflite)
Descartado. Los modelos son value objects con serialización JSON; no necesitamos queries relacionales. El modelo clave-valor con prefijos (`op:comujesa:route:L1`) cubre nuestros patrones de acceso. Sin migraciones de esquema.

### SharedPreferences
Usado para datos simples (drafts, preferencias ligeras). Descartado como caché principal: sin tipos complejos, sin filtrado por prefijo, ~1MB de datos no cabe.

### Isar
Descartado. Isar 3.x incompatible con nuestra versión de Dart; Isar 4 en alpha. Hive 2.x es estable y mantenido.

## Consecuencias

### Positivas
- Clave-valor con prefijos permite filtrar/borrar por scope
- TypeAdapters delegando en `fromJson`/`toJson` del modelo freezed → sin acoplamiento binario
- Corruption recovery: si una caja no abre, se borra y recrea
- Sin migraciones de esquema (typeIds append-only)
- `hive_flutter` inicializa path_provider automáticamente

### Negativas
- TypeIds append-only: nunca reutilizar aunque el modelo se borre
- Sin queries: filtrar requiere cargar todo y filtrar en Dart (aceptable con ~600 stops)
- Sin cifrado integrado (pendiente para datos sensibles: `live_recorder_draft`)

### Cajas activas (9)
`routes`, `stops`, `schedules`, `operators`, `userPreferences`, `offlineRegions`, `alerts`, `pendingActions`, `authSessionMeta`

### Convención de claves
`<scope>:<id>` — ej. `op:comujesa:route:L1`, `user:<uid>:pref`

## Referencias
- `lib/data/cache/hive_adapters.dart` — TypeAdapters
- `lib/data/cache/hive_init.dart` — inicialización y recovery
- `lib/data/cache/hive_box_provider.dart` — providers Riverpod por caja
