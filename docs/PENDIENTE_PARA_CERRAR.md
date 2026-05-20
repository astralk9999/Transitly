# Transitly — Pendiente para cerrar (todo, en un sitio)

> **Para qué sirve este documento:** lo que falta para que el lote actual
> quede cerrado y verde, y para completar el plan de producción. Es el
> *playbook* exhaustivo y autocontenido — no hace falta abrir otros docs
> para actuar.
> **Estado verificado:** `master @ f5fee4c` (último push) · árbol con
> **108 ficheros sin commitear** intentando atacar PROD/A11Y/P1 · `flutter
> analyze` **5 issues (rojo)** · `flutter test` **170/170 verdes** · CI no
> ha visto nada de esto (sigue en `f5fee4c`).
> **Cómo usarlo:** ejecuta §1 para cerrar el lote (cambio mínimo,
> mecánico). §2 son refinos. §3 es lo que sigue pendiente del plan.

---

## 1. Cierre del lote actual (URGENTE — necesario antes de pushear)

Estos 4 pasos, en orden. Tras ellos, `analyze` vuelve a 0 y CI debería
ponerse verde de nuevo.

### 1.1 Arreglar los 5 lints `prefer_const_constructors` (5 minutos)

Son `info` triviales en tests **nuevos** añadidos por la última tanda.
Añade `const` al constructor en cada línea exacta:

- `test/data/operator/operator_remote_error_test.dart:10:9`
- `test/data/operator/operator_remote_error_test.dart:20:9`
- `test/data/operator/operator_remote_error_test.dart:30:9`
- `test/data/operator/operator_remote_error_test.dart:40:9`
- `test/widget/a11y_semantics_test.dart:35:16`

Patrón: localiza el constructor en cada línea y antepón `const`. Si el
lint sigue, es porque alguno de los argumentos no es `const` — en ese caso,
o haces `const` también el argumento o ignoras la línea con
`// ignore: prefer_const_constructors` *solo si es justificable*.

### 1.2 Quitar la dependencia muerta `flutter_dotenv` (2 minutos)

- `pubspec.yaml:52` declara `flutter_dotenv: ^5.1.0` pero **no la usa nadie**
  (ya migrado a `String.fromEnvironment` en `lib/core/env.dart`).
- **Acción:** borrar esa línea de `pubspec.yaml`, luego:
  ```bash
  flutter pub get
  ```

### 1.3 Verificar y commitear

```bash
flutter analyze            # debe decir: No issues found!
flutter test               # debe decir: All tests passed! (170 actuales)
git add -A
git commit -m "fix: close PROD/A11Y/P1 batch (lints + drop dotenv)"
git push origin master
```

Después, en GitHub: comprobar que CI cierra verde (los 3 jobs: Analyze,
Test, Build Web).

### 1.4 (Opcional pero recomendado) APK release real

Hoy `android/key.properties` **no existe** → el ternario de firma de
`android/app/build.gradle.kts:52` cae al **fallback debug**. Para que sea
release real:

```bash
# 1. Generar keystore propio (NO commitear el .jks)
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear android/key.properties (gitignored — comprueba .gitignore)
# Plantilla en android/key.properties.example. Contenido:
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks

# 3. Build
flutter build apk --release       # ~73 MB esperado
# o, mejor para Play Store:
flutter build appbundle --release
```

**Bloqueador real de producción** mientras no se haga: el APK que se genere
sin `key.properties` no es publicable.

---

## 2. Refinos sobre lo recién aplicado (calidad, no bloqueante)

Lo nuevo está bien hecho en general (ChannelManager con multiplex + jitter,
Pressable 48dp via tokens, textScaler compuesto, SEC2 a `--dart-define`,
A11Y-4 mayoritariamente migrado, 7 modelos a freezed, +22 tests). Refinos:

1. **A11Y-4 residual:** `lib/features/home/tabs/home_tab.dart:347` sigue con
   `label: '${route.code}, $time'` — no es ES pero tampoco l10n. Migra a una
   clave (`homeAlternativeRouteSemantics(code, time)`).
2. **Realtime stop/route sin multiplex:** `stop_remote_repository.dart:76` y
   `route_remote_repository.dart:63` usan `.channel().onPostgresChanges()`
   directamente, **sin** pasar por un `ChannelManager`. Con muchas
   suscripciones concurrentes saturan canales. **Acción:** factorizar un
   `StopChannelManager`/`RouteChannelManager` siguiendo el patrón de
   `bus_position_channel_manager.dart` (multiplex + backoff con jitter).
3. **F13 cobertura incompleta:** **3 de 12** repos `remote/` con Realtime
   (`bus_location`, `stop`, `route`). Los 9 restantes
   (`incident`, `route_feedback`, `route_suggestion`, `feature_request`,
   `operator`, `schedule`, `notification`, `user_preferences`,
   `offline_region`) siguen *snapshot*. Decide cuáles necesitan en vivo.
4. **Paginación incompleta (4 de 12 repos):** ya tienen `range`/`limit`:
   `operator`, `bus_location` (limit 1), `notification` (limit 50),
   `schedule` (limit count). **Faltan paginar:**
   - `lib/data/stop/remote/stop_remote_repository.dart`
   - `lib/data/route/remote/route_remote_repository.dart`
   - `lib/data/incident/remote/incident_remote_repository.dart`
   - `lib/data/route_feedback/remote/route_feedback_remote_repository.dart`
   - `lib/data/route_suggestion/remote/route_suggestion_remote_repository.dart`
   - `lib/data/feature_request/remote/feature_request_remote_repository.dart`
   - `lib/data/user_preferences/remote/user_preferences_remote_repository.dart`
   - `lib/data/offline_region/remote/offline_region_remote_repository.dart`
   Patrón: parámetros `int? offset, int? limit` con `range(offset, offset+limit-1)`
   y por defecto un tope sano (p.ej. 100). Listas en UI con paginación
   `.builder` + carga al final.
5. **`bus_location_remote_repository.dart:39-54`:** el `streamForRoute` mezcla
   snapshot inicial + canal en un `StreamController` propio aunque el
   `ChannelManager` ya devuelve `Stream`. Simplificar (usar `prepend` del
   snapshot o `concat`) para no tener dos controllers anidados.
6. **`l10n.yaml` no declara `ar`:** `flutter gen-l10n` lo detecta por archivo,
   pero conviene fijar `synthetic-package: false` o documentar la lista de
   locales. Verifica que `MaterialApp.supportedLocales` incluye `ar` (debería
   por `AppLocalizations.supportedLocales`) y prueba RTL en runtime.
7. **Cobertura no re-medida** tras los +22 tests:
   ```bash
   flutter test --coverage
   awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
   ```
   Actualiza la cifra en `docs/00_MAESTRO.md`, `docs/tfg/05`,
   `docs/PLAN_ACCION_REMEDIACION.md`.
8. **Tests del ChannelManager:** el código nuevo (`bus_position_channel_manager.dart`)
   es lógica con reintentos/jitter — añade tests deterministas con
   `fake_async` o inyección de `Random`/`Duration`.
9. **Doc del nuevo flujo de claves:** crear `android/README.md` (o ampliar
   `docs/PLATFORM_SETUP.md`) explicando cómo generar `upload-keystore.jks`,
   subirlo a Play App Signing y configurar `key.properties`.

---

## 3. Pendiente del plan general (PROD / A11Y / P1 / P2 / P3)

Lo que **no** ha tocado esta tanda. Está priorizado y con criterio de
aceptación en `docs/PLAN_ACCION_REMEDIACION.md` (PROD/A11Y/P1/P2/P3); aquí
solo el resumen para que sepas qué queda.

### Bloqueadores de producción (PROD)

- **PROD-1 ⚠️ a medias** — La lógica de firma está bien, pero **falta
  generar el keystore real** y subirlo a Play App Signing (§1.4).
- **PROD-2 ⚠️ a medias** — Paginar los 8 repos `remote/` restantes (§2.4).
- **PROD-3 ⚠️ a medias** — F13 cubre 3/12; refactorizar stop/route con
  ChannelManager (§2.2); decidir qué repos más necesitan Realtime (§2.3).
- **PROD-4 SEC1 ⏳ externo** — Rotar el PAT de Supabase de `.mcp.json` en el
  dashboard. **Sigue siendo exposición activa** mientras no se rote.
- **PROD-5 ❌ no hecho** — `autoDispose` en providers críticos
  (`nfcScanProvider`, `notificationStreamProvider`, `realtimeTripsProvider`,
  `privacyConsentsProvider`, providers `.family`). Sin esto, fugas de
  memoria y canales/timers vivos tras salir de pantalla.
- **PROD-6 ❌ no hecho** — Mapa a escala (clustering por zoom,
  `RepaintBoundary`, LOD de markers).
- **PROD-7 ❌ no hecho** — Observabilidad: tracing cliente↔Edge↔DB,
  métricas de negocio, SLO/alertas, logs estructurados para agregación.
- **PROD-8 ⚠️ a medias** — CI actual solo construye web; falta build
  Android/iOS firmado, gate de cobertura, SAST, Dependabot, smoke E2E.
- **PROD-9 ❌ no hecho** — Caché/tenant a escala: tamaño/evicción/cifrado
  Hive; partición por `operator_id`; cifrar `live_recorder_draft`.
- **PROD-10 ❌ no hecho** — Backend a escala: FORCE RLS + auditoría,
  pooling, idempotencia Edge, GTFS streaming, plan no-free / multi-región.

### Accesibilidad (A11Y)

- **A11Y-1 ❌ no hecho** — Alternativa accesible al mapa (lista equivalente
  enlazada + semántica del mapa). El mapa sigue sin `Semantics`.
- **A11Y-3 ❌ no hecho** — Verificación REAL con TalkBack/VoiceOver/Switch
  + checklist por release. Sin esto no es defendible "AA".
- **A11Y-4 ⚠️ casi** — Queda el caso de `home_tab.dart:347` (§2.1).
- **A11Y-6 ❌ no hecho** — Errores accesibles y claros (no `e.toString()`).
  Archivos con `e.toString()` crudo visibles:
  `route_feedback_sheet.dart:207`,
  `incidents/report_incident_sheet.dart:141`,
  `operator_admin/drivers_screen.dart:59,109`,
  `operator_admin/invitation_codes_screen.dart:60,89,157`,
  `route_detail/widgets/route_officialize_modal.dart:75`,
  `route_detail/widgets/route_share_sheet.dart:82,95,97,123`.
- **A11Y-7 ❌ no hecho** — Verificar contrastes de tokens en
  `lib/core/theme/transit_colors.dart` con herramienta (Stark, axe). Texto
  secundario sobre `GlassCard` translúcido es sospechoso. No usar color como
  único indicador (añadir icono/forma a `status_badge`/`capacity_indicator`).
- **A11Y-8 ❌ no hecho (F26)** — Empaquetar fuentes DM Sans + IBM Plex Mono
  como assets locales y poner `_fontsBundled = true` en `lib/main.dart:22`.
  Reducir APK con `--split-per-abi` o app bundle.
- **A11Y-9 ❌ no hecho** — Foco: `FocusTraversalGroup` por sección,
  visibilidad de foco, soporte teclado/switch.
- **A11Y-10 ⚠️ parcial** — `app_ar.arb` añadido; falta probar RTL en
  runtime, verificar que `MaterialApp` lo lista en `supportedLocales`, y
  cubrir lectura fácil / localización completa de números/fechas/moneda.

### P1 (calidad)

- **P1-1 ❌** — Strings ES visibles → l10n (≈17 críticos; lista exacta en
  PLAN §P1-1).
- **P1-2 ✅ mayoritariamente** — A11Y-4 en home/profile (queda detalle §2.1).
- **P1-5 ✅** — 7 modelos a freezed (hecho en esta tanda).
- **P1-6 ❌** — Tokens en `lib/shared/widgets/` (11 usos de `GoogleFonts.*`
  inline en 7 widgets: `empty_state`, `error_card`, `reputation_badge`,
  `route_card`, `status_badge`, `transit_button`, `transit_chip`).
- **P1-7 ❌** — Tokens en widgets extraídos por la descomposición I1
  (≈15 widgets de `features/appearance/` + `features/management/`).
- **P1-8 ❌** — Eliminar `lib/features/management/widgets/action_button.dart`
  y reemplazar por `TransitButton(isPrimary:false, isSmall:true)`.
- **P1-9 ❌** — `inbox_action_sheets.dart`: 3 `showModalBottomSheet`
  inline → `showTransitBottomSheet`.
- **P1-10 ❌** — `privacy_screen._setConsent`: `if (!mounted) return;`
  antes de `ref.invalidate`; `unawaited(...)` explícito en el caller.
- **P1-11 ❌** — Issues F16/F22 de `PENDIENTES.md` (validación inline,
  unique-violation, dedupe mapping, loading en botones de estado, cola
  offline en `updateStatus`).

### P2 (núcleo + cobertura)

- **P2-1/2-2 ⚠️ a medias** — F13 Realtime: bus_location con multiplex (✅);
  stop/route sin multiplex (refinar §2.2); el resto sin migrar (§2.3).
- **P2-3 ❌** — Unificar modelo de usuario: provider de perfil que lea
  `profiles` (con `role`) de Supabase; `currentUserProvider` → real si
  `AuthAuthenticated`, mock si guest; guard del router pasa a rol real.
- **P2-4 ❌** — Tests de la capa `remote/` (auth_supabase, stop, route,
  bus_location, etc.) con mocks de `SupabaseClient`/`PostgrestClient`.
- **P2-5 ✅** — SEC2 hecho en esta tanda (Env por `--dart-define`).
- **P2-6 ❌ (F26)** — Fuentes locales (ver A11Y-8).
- **P2-7 ❌** — CI: gate de cobertura (umbral declarado, p.ej. 25%).

### P3 (deuda de fondo)

- **P3-1 ❌** — `autoDispose` selectivo (ver PROD-5).
- **P3-2 ❌** — Semantics para el mapa (ver A11Y-1).
- **P3-3 ⚪ deuda asumida** — Barrido de `EdgeInsets`/`Color(0x` a tokens
  (≈342/≈29 ocurrencias) — explícitamente NO se hará sin tu decisión.
- **P3-4 ❌** — `live_recorder_draft`: `shared_preferences` → Hive cifrado.
- **P3-5 ❌** — `MockRealtimeService`: pausar `Timer.periodic` en
  `AppLifecycleState.paused`.
- **P3-6 ❌** — Completar patrón canónico de `lib/data/auth/` (faltan
  `local`/`mock`/`provider`; nomenclatura `abstract_…`) o documentar la
  excepción en AGENTS.md.
- **P3-7 ❌** — Descomponer `privacy_screen.dart` (>300 LoC) e
  `inbox_action_sheets.dart` (347 LoC).
- **P3-8 ⚠️ a medias (CI)** — Dependabot/Renovate; build APK/iOS en CI.

---

## 4. Comandos exactos de verificación (copy-paste)

Al cerrar cada lote, ejecuta esto y todo debe estar verde:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze                     # → No issues found!
flutter test --coverage             # → All tests passed!
awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "cov=%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
flutter build apk --release         # → √ Built app-release.apk (~73 MB)
# Si tienes key.properties: comprueba con jarsigner que el APK NO está
# firmado por debug:
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk | head -20
```

Tras pushear: consulta `https://github.com/astralk9999/Transitly/actions`
y verifica los 3 jobs en `success` para el commit pusheado.

---

## 5. Resumen ejecutivo

- **Lo que falta para que CI vuelva verde:** 4 pasos triviales de §1
  (5 lints + quitar `flutter_dotenv` + commit + push). 15 minutos.
- **Lo que falta para que sea release real publicable:** generar keystore
  y `key.properties` (§1.4). Otros 15 minutos + alta en Play Console.
- **Lo que falta para "producción a escala" en serio:** los bloques PROD,
  A11Y, P2 — son **semanas de trabajo** y ninguno es opcional para escalar.
- **Lo que falta para "AA" defendible en accesibilidad:** A11Y-1, A11Y-3,
  A11Y-6, A11Y-7, A11Y-9 mínimos — sin un paso REAL con lector de
  pantalla, "AA" no es defendible aunque rellenes todo lo demás.
- **Acción externa única e imprescindible (no automatizable):** rotar el
  PAT de Supabase del `.mcp.json` (PROD-4). Tú, en el dashboard. Ya.

> Si pasa una semana y el PAT sigue sin rotar, asume que un atacante con
> acceso al disco lo tiene.
