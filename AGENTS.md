# AGENTS.md · Transitly

> Instrucciones compactas para sesiones de OpenCode. Cada línea responde a:
> "¿Un agente se equivocaría sin saber esto?" Si no, se omite.

---

## Arranque rápido

```bash
flutter pub get
flutter gen-l10n                          # Obligatorio: genera lib/l10n/generated/
tool/build.sh                             # Codegen freezed + json_serializable
flutter run --dart-define-from-file=dart_defines.json  # Necesita dart-defines (ver abajo)
```

- `.env` es **obligatorio** (copiar de `.env.example`). Sin `SUPABASE_URL` y `SUPABASE_ANON_KEY` la app crashea al `EnvErrorScreen`.
- ⚠️ **`dart_defines.json` es OBLIGATORIO para `flutter run` y `flutter build`.** Se genera desde `.env` una sola vez con: `Get-Content .env | Where-Object { $_ -match '^([A-Z_]+)=(.*)$' } | ForEach-Object { $env[$matches[1]] = $matches[2] }; $env | ConvertTo-Json | Set-Content dart_defines.json -Encoding UTF8`. Sin este archivo, la app crashea en arranque con `EnvException(missing, key=SUPABASE_URL)`. El archivo está en `.gitignore`. VSCode ya está configurado (`.vscode/launch.json`) para usarlo automáticamente. Para CLI siempre pasar `--dart-define-from-file=dart_defines.json`.
- `tool/build.sh` = `dart run build_runner build --delete-conflicting-outputs`. Usar `tool/build_watch.sh` durante edición de modelos.
- `flutter gen-l10n` debe ejecutarse al menos una vez tras checkout fresco.

---

## Comandos diarios

```bash
flutter analyze          # 0 issues — no commits con warnings
flutter test             # 175 tests
flutter test --coverage  # Escribe coverage/lcov.info
```

- `flutter analyze` tiene `strict-casts: true` y `strict-raw-types: true`. Sin margen.
- `avoid_print: true` en `lib/`. Solo se permite `print()` en `test/`.
- CI activo en GitHub Actions con 4 jobs (Analyze, Test, Build Web, Build Android APK). Sin pre-commit hook local.

---

## Ecosistema de documentos

Cuatro archivos vivos en `docs/` que se actualizan en cada fase:

| Documento | Rol | ¿Cuándo actualizar? |
|-----------|-----|---------------------|
| `historico/PLAN_TRANSITLY_V2.md` | Plan de 27 fases con prompts copiables | Al completar/retroceder una fase |
| `ARCHITECTURE.md` | Reglas de oro, capas, entidades, errores, logging | Si cambia una decisión estructural |
| `PENDIENTES.md` | Cola de items bloqueantes/mejora con tags `[F<n>]` | Cada vez que se cierra/pospone/destapa un item |
| `DATA_INVENTORY.md` | Catálogo de assets, JSON mock, pipeline de datos | Cada vez que se toca un asset o script |

**Regla de sincronía:** al actualizar `PENDIENTES.md`, sincronizar `historico/AUDIT_2026_04.md §4` y `historico/PLAN_TRANSITLY_V2.md` si cambia el tag de fase. Las tres fuentes deben coincidir.

**Contexto adicional (solo lectura):**
- `docs/historico/SESSION_AUDIT_2026_05.md` — registro de la sesión 02-12 mayo 2026 (49 commits, F0→F3.3)
- `docs/historico/AUDIT_2026_04.md` — auditoría estática pre-sesión (30 items numerados)

---

## Cómo ejecutar el plan

`historico/PLAN_TRANSITLY_V2.md` contiene prompts numerados por fase. Cada sesión nueva arranca con:

```
Estoy ejecutando el Plan v2 de Transitly, fase <N>. Ya está hecho:
<lista>. Vamos con el prompt <N.x>:

<pega el prompt>

Antes de tocar nada lee docs/ARCHITECTURE.md y docs/historico/PLAN_TRANSITLY_V2.md.
```

Estado actual (20 mayo 2026):
- ✅ 28/28 fases del plan completadas
- ✅ `flutter analyze` 0 issues · `flutter test` 175/175
- ✅ CI GitHub verde (Analyze, Test, Build Web, Build Android APK)
- ✅ F13 Realtime implementado (5/12 repos con canales Supabase)
- ✅ Paginación en 10/12 repos
- ✅ SEC2: `.env` → `--dart-define`
- ✅ F26: fuentes locales (DM Sans + IBM Plex Mono bundled)
- ✅ i18n: ES + EN + AR (RTL)
- ⏳ 3 items externos: PAT rotation, release keystore, TalkBack verification

---

## Arquitectura (reglas de oro)

Feature-first con `core/` + `shared/` + `data/` transversales:

```
lib/
├── main.dart              # bootstrap: Env → Hive → Supabase → MockData → ProviderScope
├── app.dart               # MaterialApp.router (themeMode + locale + go_router)
├── core/
│   ├── router/            # go_router + redirects + errorBuilder
│   ├── theme/             # transit_colors, transit_typography, transit_spacing, transit_animations
│   └── utils/             # AppLogger, uuid, helpers
├── data/                  # Capa más profunda. NO depende de features/.
│   ├── mock/              # MockDataService + MockRealtimeService
│   ├── cache/             # Hive adapters + boxes + HiveInit
│   ├── nfc/               # NfcCardService + l10n de errores
│   ├── <entity>/          # Repositorios: 5 archivos c/u (abstract, remote, local, mock, provider)
│   └── sync/              # Cola offline: PendingAction, PendingActionsQueue, OfflineSyncService
├── features/              # UNA carpeta por dominio funcional
│   └── <feature>/
│       ├── *_screen.dart  # Punto de entrada navegable
│       ├── widgets/       # Piezas internas (NO compartidas)
│       └── *_controller.dart
├── l10n/                  # ARB sources + generated/
└── shared/
    ├── models/            # Entidades de dominio (@freezed)
    ├── providers/         # Estado global Riverpod + derived/
    └── widgets/           # Widgets usados en ≥2 features
```

**Reglas no obvias:**
1. `shared/widgets/` solo si se usa en ≥2 features. Si solo una feature, vive dentro de ella.
2. `shared/providers/` solo para estado global. Estado local → `StatefulWidget`/`setState` o `ChangeNotifier` local.
3. `data/` no depende de `features/`. La UI consume datos a través de providers Riverpod.
4. Design tokens en `core/theme/` se consumen, nunca se duplican.
5. Cada archivo `*_screen.dart` ≤ ~300 LoC; si crece → descomponer en `widgets/` o `steps/` de la misma feature.

---

## Codegen (freezed + json_serializable)

- Modelos críticos usan `@freezed`. El `.freezed.dart` y `.g.dart` **se commitean** junto a la fuente.
- `build.yaml` en raíz: `explicit_to_json: true` + `include_if_null: false`.
- Cuándo regenerar: al añadir/renombrar/borrar campos, tras `git pull` que toque `lib/shared/models/`, o si ves `Undefined name '_$ModelImpl'`.
- `fromJson` en modelos migrados del mock es `static` (no `factory`) → sin `.g.dart` autogenerado. Modelos nuevos sí usan `factory.fromJson => _$XFromJson(json)`.
- `build.yaml` previene conflicto con `flutter pub run` que usa `build.yaml` propio de Flutter. Usar `tool/build.sh`.

---

## Testing

```bash
flutter test                           # Todos
flutter test test/data/                # Solo tests de datos (sin widgets)
flutter test test/widget/              # Solo widget tests
flutter test --plain-name "nombre"     # Un test concreto
```

- Helper universal: `test/helpers/pump_app.dart` → `pumpApp(tester, child:, overrides:, themeDark:, locale:)`.
- `disableAnimations: true` (default) evita que `StaggerList` y `SmokeBackground` programen futures.
- Siempre llamar a `unmount(tester)` al final para liberar tickers/streams.
- `loadMockData()` carga el asset bundle real. Requiere `TestWidgetsFlutterBinding.ensureInitialized()`.
- `mockDataOverride(svc)` crea override para `mockDataServiceProvider`.
- No hay pixel goldens porque `google_fonts` resuelve fuentes por red.
- Para tests de providers: `ProviderContainer(overrides: [...])` sin widget tree.

---

## i18n

- Strings en `lib/l10n/app_es.arb` (template) + `app_en.arb`.
- Selector en Profile → Accessibility → Idioma via `localeProvider`.
- Config: `l10n.yaml`. Generado a `lib/l10n/generated/app_localizations.dart`.
- Scope actual: ES + EN + AR (RTL). Mayoría de pantallas con cobertura completa.

---

## Patrón de errores (template obligatorio)

```dart
enum FooError { notFound, malformed, networkUnavailable, unknown }

class FooException implements Exception {
  const FooException(this.error, [this.message]);
  final FooError error;
  final String? message;
}

extension FooErrorL10n on FooError {
  String localizedMessage(AppLocalizations l10n, {String? fallback}) {
    return switch (this) {
      FooError.notFound => l10n.fooErrorNotFound,
      FooError.malformed => l10n.fooErrorMalformed,
      FooError.networkUnavailable => l10n.fooErrorOffline,
      FooError.unknown => fallback ?? l10n.fooErrorUnknown,
    };
  }
}
```

- Errores tipados en `data/`, mensajes localizados en UI.
- Nada de `catch (_) {}` silencioso. Si se ignora → `logger.warn('contexto', e)`.
- Validación en los bordes, confianza en el interior.

---

## Logging (AppLogger)

Wrapper en `lib/core/utils/app_logger.dart`. Cuatro niveles: `debug`, `info`, `warn`, `error`.

Formato: `[Tag] mensaje (key=value)`. Ejemplo: `[NfcCardService] read failed (sector=9, error=authFailed)`.

- PII fuera del log: nunca número de tarjeta, lat/lng exactos, email, NFC UID.
- Tags por capa: `[Servicio]`, `[Provider:nombre]`, `[Router]`, `[Feature:nombre]`.
- No usar `print()` en `lib/`. El lint `avoid_print` está activo.

---

## Supabase

- Proyecto remoto: `mmzahxtiaurkgtmtehxk` (https://mmzahxtiaurkgtmtehxk.supabase.co)
- 13 migraciones SQL en `supabase/migrations/`. Aplicar con `supabase db push`.
- MCP supabase (si configurado) permite `apply_migration` + `execute_sql` vía `@supabase/mcp-server-supabase`.
- Nunca commitear `.env` ni `.mcp.json`. `.mcp.json.example` como plantilla.
- RLS default-deny activo (recuento exacto de tablas/policies a re-verificar
  tras las últimas migraciones; ver `docs/SCALABILITY.md §B`). Storage con
  buckets configurados. `workmanager` fue eliminado; stack en freezed 3 /
  go_router 17 (ver `docs/00_MAESTRO.md`).

---

## Hive (caché local)

- Inicializado en `main.dart` entre `Env.load()` y `Supabase.initialize()`.
- Si una caja está corrupta → se borra del disco y se recrea.
- TypeIds append-only. Nunca reutilizar un `typeId`, aunque el modelo se elimine.
- Convención de claves: `<scope>:<id>` (ej. `op:comujesa:route:L1`, `user:<uid>:pref`).
- Cada adapter delega en `fromJson`/`toJson` del modelo freezed.

---

## NFC

- Claves Mifare por defecto en `lib/data/nfc/nfc_card_service.dart` (uso académico).
- Override en build: `--dart-define=NFC_KEY_SECTOR0=<hex>` y `--dart-define=NFC_KEY_SECTOR9=<hex>`.
- iOS requiere `NFCReaderUsageDescription` + entitlements en `Info.plist`.

---

## Cola offline (`lib/data/sync/`)

- `PendingAction` + `PendingActionKind` (11 tipos) → Hive.
- `OfflineSyncService` con executors registrados por `kind`. Drenado FIFO con backoff exponencial.
- Disparo automático: `ref.listen` sobre `isOfflineProvider` → al volver online → `drainNow()`.
- Dead letter tras 10 reintentos. Sin UI aún para reintento manual (pendiente F15/F22).
- `OfflineBanner` en `lib/shared/widgets/offline_banner.dart`.

---

## Widgets compartidos

En `lib/shared/widgets/`, importar, no recrear:
`Pressable`, `GlassCard`, `StaggerList`, `RouteCard`, `StatusBadge`, `ReputationBadge`, `TransitButton`, `SmokeBackground`, `GradientText`, `SingleFieldDialog`, `ResponsiveScaffold`, `OfflineBanner`, `EmptyState`, `ErrorCard`, `ShimmerSkeleton`, `TransitInput`, `TransitCheckbox`, `TransitChip`, `TransitAppBar`, `TransitBottomSheet`, `StopTimeline`, `RouteSearchBar`, `StopListItem`, `DataFreshnessIndicator`, `CapacityIndicator`.

---

## Repositorios (patrón canónico)

Cada entidad en `lib/data/<entity>/` con 5 archivos:
1. `abstract_<entity>_repository.dart` — interfaz
2. `<entity>_remote_repository.dart` — Supabase
3. `<entity>_local_repository.dart` — Hive
4. `<entity>_mock_repository.dart` — guest fallback (usa MockDataService)
5. `<entity>_repository_provider.dart` — provider Riverpod con SWR

Template de referencia: `lib/data/operator/` (el primero implementado).

**Excepción: `data/auth/`** — Auth no sigue el patrón de 5 archivos porque:
- El estado de sesión es efímero (tokens, no datos persistentes).
- `AuthRepositorySupabase` usa `onAuthStateChange` de Supabase internamente.
- El provider ya existe en `features/auth/auth_provider.dart` (no en `data/`).
- No hay versión mock: el modo invitado no simula sesión; los repos de datos
  seleccionan mock cuando `currentSession == null`.
- No hay versión Hive: los tokens de sesión los gestiona Supabase SDK.
Esta excepción está documentada y es intencional (no es deuda pendiente).

---

## Git

- Sin ramas de feature. Todo sobre `master` con conventional commits.
- No hay CI, no hay pre-commit. Cada commit debe tener `flutter analyze` limpio y tests verdes.
- Commits atómicos por item/fase. No amend sobre commits ya pusheados.
- `.env`, `.mcp.json`, `.supabase/` en `.gitignore`.

---

## Referencias rápidas

| Necesito... | Archivo/Comando |
|-------------|-----------------|
| Design tokens | `lib/core/theme/transit_colors.dart`, `transit_typography.dart`, `transit_spacing.dart`, `transit_animations.dart` |
| Test helper | `test/helpers/pump_app.dart` |
| Plantilla de errores | `ARCHITECTURE.md` §4.3 |
| Template de repositorio | `lib/data/operator/` |
| ARB template | `lib/l10n/app_es.arb` |
| Schema Supabase | `supabase/migrations/001_init.sql` |
| Plan de acción | `docs/historico/PLAN_TRANSITLY_V2.md` |
| Próximo prompt a ejecutar | `docs/historico/PLAN_TRANSITLY_V2.md` §3 (buscar primer prompt no completado) |
