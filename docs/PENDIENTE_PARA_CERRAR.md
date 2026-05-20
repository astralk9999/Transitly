# Transitly — Pendiente para el próximo ciclo (todo, en un sitio)

> **Para qué sirve este documento:** lo que falta tras el ciclo de
> remediación cerrado el **2026-05-20 (tarde)**, listo para retomar. Es
> el *playbook* exhaustivo y autocontenido — no hace falta abrir otros
> docs.
> **Estado verificado (2026-05-20):** `master @ 6de6261` ·
> `flutter analyze` **0 issues** ✅ · `flutter test` **175/175** ✅ ·
> cobertura **24,30 %** (4 004/16 476) · `flutter build apk --release`
> **OK** (73,5 MB) · **CI verde** (4 jobs incluido Build Android APK).
> **Nota:** la rotación del PAT de Supabase (antes SEC1/PROD-4) queda
> **descartada** (dev / migración de BD próxima).
> **Cómo usarlo:** §1 lo crítico que aún falta; §2 lo importante (medio
> plazo); §3 deuda de fondo; §4 comandos de verificación.

> **⚠️ Importante de integridad documental:** este *playbook* sustituye
> íntegramente al anterior. Versiones previas listaban como pendientes
> cosas que en realidad ya estaban hechas (F26 fuentes locales,
> `ActionButton`, `showTransitBottomSheet`, `mounted`/`unawaited` en
> privacy_screen, `e.toString()` crudo limpiado en las 6 pantallas listadas,
> AGENTS.md saneado). Este documento está re-verificado con grep en código.

---

## 1. Lo crítico que aún falta (horas)

### 1.1 🔴 Keystore real para APK publicable

Único bloqueador de release. El `build.gradle.kts` ya cae con elegancia a
debug cuando `key.properties` no existe (ya verificado: APK compila 73,5 MB),
pero el APK no es publicable en Play Store sin keystore real.

```bash
# 1. Generar keystore (NO commitear .jks ni key.properties)
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear android/key.properties (plantilla y guía completa en android/README.md)
#    storePassword=...
#    keyPassword=...
#    keyAlias=upload
#    storeFile=upload-keystore.jks

# 3. Build + verificación
flutter build appbundle --release
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

Para CI con Play App Signing: secrets `KEYSTORE_BASE64`,
`KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` + step que reconstruya
los ficheros. Documentado en `android/README.md`.

### 1.2 🟠 Verificación REAL de accesibilidad con lector de pantalla

Mientras no se haga una pasada con **TalkBack** (Android) y **VoiceOver**
(iOS) en una sesión grabada + checklist por release, **"WCAG 2.2 AA" no
es defendible** por mucho que se cumpla el resto. Es el bloqueador
conceptual de A11Y-3. Tiempo: ~1 día de pruebas + acta firmada.

---

## 2. Lo importante (días)

### 2.1 ⏳ Paginación en los 2 repos que faltan

10/12 paginados ya. Quedan:

- `lib/data/offline_region/remote/offline_region_remote_repository.dart`
- `lib/data/user_preferences/remote/user_preferences_remote_repository.dart`

Patrón: parámetros `int? offset, int? limit` →
`range(offset, offset+limit-1)`; tope por defecto 100; UI con
`ListView.builder` + carga al final.

### 2.2 ⏳ `autoDispose` en providers de canal/timer

Cerrados: `home_providers.dart`, `nfc_provider.dart`. Faltan los más
sensibles a recursos vivos:

- `notificationStreamProvider` — Stream Supabase Realtime (debe cerrarse
  al salir de pantalla).
- `realtimeTripsProvider` — `Timer.periodic` (sigue corriendo si no se
  libera; aunque ya hay `pause/resume` por lifecycle, autoDispose lo
  remata cuando nadie observa).
- `privacyConsentsProvider` — `FutureProvider` que conviene re-fetchear.
- Todos los providers `.family` parametrizados.

### 2.3 ⏳ P1 residuales (poco esfuerzo, alto valor de coherencia)

- **P1-6 último `GoogleFonts.` en shared**: `shared/widgets/transit_button.dart:69`
  (`GoogleFonts.ibmPlexMono(...)`). Migrar a `TransitTypography` (añadir
  variante de botón si no existe). Es el ÚLTIMO de 11 originales.
- **P1-7 colores raw en `map_style_section.dart`**: 5 ocurrencias de
  `Color(0x...)`. Auditar si son swatches intencionales (previews de
  estilos de mapa → legítimo) o duplicación de tokens; documentar.
- **P1-1 strings ES restantes en pantallas no-críticas**: los 6 sitios
  más visibles ya están localizados; queda barrer pantallas secundarias
  con `grep -rnE "Text\(['\"][A-ZÁÉÍÓÚ]"` y migrar a l10n.
- **P1-11 issues F16/F22 de `PENDIENTES.md`**: validación inline,
  unique-violation, dedupe mapping, loading en botones, cola offline en
  `updateStatus`.

### 2.4 ⏳ Unificar modelo de usuario (P2-3)

Sigue sin tocar: `currentUserProvider` (mock + `isDriverMode`
StateProvider) desconectado de `AuthRepositorySupabase`; el guard del
router (`redirect_guards.dart:31`) usa el mock-derived role. Plan:

1. Provider de perfil que lea `profiles.role` de Supabase.
2. `currentUserProvider` → perfil real si `AuthAuthenticated`, mock si
   guest.
3. `currentUserRoleProvider` deriva del real.

Hacer gradual (capa Supabase + fallback mock) para no romper consumidores.

### 2.5 ⏳ Tests de la capa de datos de producción (P2-4)

Es la palanca principal para subir cobertura (estancada en 24 %). Con
`SupabaseClient`/`PostgrestClient` mockeados, cubrir:

- `auth_repository_supabase`
- `stop_remote_repository`
- `route_remote_repository`
- `bus_location_remote_repository` + `bus_position_channel_manager`
- `realtime_channel_manager` ya tiene tests, ampliar casos.

### 2.6 ⏳ Refinos de calidad

- **streamForRoute doble controller** (`bus_location_remote_repository.dart`):
  simplificar con concat/prepend en vez de dos `StreamController`.
- **RTL runtime**: probar `app_ar.arb` en dispositivo (Material flips
  automáticamente; verificar widgets custom y mapas).
- **Verificación de contrastes** de tokens en `transit_colors.dart` con
  Stark/axe; no usar color como único indicador en `status_badge`/
  `capacity_indicator` (añadir icono/forma).
- **Foco**: `FocusTraversalGroup` por sección, visibilidad de foco,
  navegación por teclado/switch.
- **Documentar excepción `data/auth`**: el commit `2b09e8f` decía
  "auth pattern exception docs" pero la nota no aparece en AGENTS.md
  ni en `docs/`. Documentar por qué `lib/data/auth/` solo tiene 2
  archivos (sesión gestionada por Supabase, no necesita local/mock).

---

## 3. Deuda de fondo (semanas — opcional para TFG, obligatorio para producción real)

### 3.1 Bloqueadores de producción a escala

- **PROD-6** Mapa a escala: clustering por zoom, `RepaintBoundary`, LOD.
- **PROD-7** Observabilidad: tracing cliente↔Edge↔DB, métricas de
  negocio, SLO/alertas, logs estructurados para agregación.
- **PROD-9** Caché/tenant: tamaño/evicción/cifrado Hive; partición por
  `operator_id`; cifrar `live_recorder_draft` (P3-4).
- **PROD-10** Backend a escala: FORCE RLS + auditoría, pooling,
  idempotencia Edge, GTFS streaming, plan no-free / multi-región.

### 3.2 CI/CD producción

- Build iOS firmado en CI.
- Gate de cobertura con umbral declarado (sube tras §2.5).
- SAST + Dependabot/Renovate.
- Smoke E2E.

### 3.3 Accesibilidad full WCAG 2.2

- **A11Y-1** Alternativa accesible al mapa: lista equivalente enlazada
  + semántica del mapa (`AccessibleBusesScreen` ya existe; integrarla
  como ruta paralela).
- **A11Y-10** Lectura fácil + localización completa de números/fechas/
  moneda (más allá del ARB añadido).

### 3.4 Deuda asumida (explícitamente NO se hará sin decisión)

- **P3-3** Barrido masivo de `EdgeInsets`/`Color(0x` literales (>300
  ocurrencias) a tokens. Bajo valor / alto ruido.
- **P3-7** Descomponer `privacy_screen.dart` (>300 LoC) e
  `inbox_action_sheets.dart` (347 LoC). Marginal.

---

## 4. Comandos exactos de verificación (copy-paste)

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze                     # → No issues found!
flutter test --coverage             # → All tests passed!
awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "cov=%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
flutter build apk --release         # → √ Built app-release.apk (~73 MB)
# Con key.properties: verificar firma real (no debug)
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk | head -20
```

Tras pushear, consulta `https://github.com/astralk9999/Transitly/actions`
y verifica los 4 jobs (Analyze, Test, Build Web, Build Android APK) en
`success`.

---

## 5. Resumen ejecutivo

- **CI:** verde (4 jobs incluido Build Android APK). El Kotlin DSL del
  ciclo anterior quedó cerrado en `5141b39`.
- **APK release publicable:** falta solo §1.1 (≈15 min — keystore +
  Play App Signing).
- **"WCAG AA" defendible:** falta §1.2 (≈1 día — pasada real con
  TalkBack/VoiceOver + acta).
- **Cobertura ≥30 %:** requiere §2.5 (tests de la capa `remote/`).
- **Multi-tenant / producción a escala:** §3 (semanas).
- **Acción externa:** ninguna obligatoria en este ciclo (PAT descartado).

### Lo cerrado en ciclos recientes (con verificación)

✅ **§1.1** Kotlin DSL en `build.gradle.kts` (`5141b39`).
✅ **§1.3** AGENTS.md saneado (`6de6261`): tests=175, CI=4 jobs, fases=28/28,
   i18n=ES+EN+AR.
✅ **F26 / A11Y-8 / P2-6** Fuentes locales: `_fontsBundled=true`,
   `assets/fonts/dm_sans/` + `assets/fonts/ibm_plex_mono/` con 4 .ttf,
   declaradas en `pubspec.yaml:101-111`.
✅ **A11Y-2** `Pressable` ≥48 dp (`TransitSpacing.minTapTarget`).
✅ **A11Y-4** Semantics ES → l10n en home_tab/card_tab/route_card/etc.
✅ **A11Y-5** `textScaler` compone con el del SO.
✅ **A11Y-6** `e.toString()` crudo limpiado de las 6 pantallas listadas
   (verificado: 0 ocurrencias).
✅ **P1-2 / P1-5** Semantics→l10n; 7 modelos manuales→`@freezed`.
✅ **P1-6** GoogleFonts en `shared/widgets/`: 11→1 (solo queda
   `transit_button.dart:69`).
✅ **P1-8** `ActionButton` eliminado.
✅ **P1-9** `inbox_action_sheets` usa `showTransitBottomSheet` (3 sitios).
✅ **P1-10** `privacy_screen._setConsent`: `if (!mounted) return;`,
   `ref.invalidate`, `unawaited(...)` correctos.
✅ **P2-5 / SEC2** `Env` via `String.fromEnvironment` (`--dart-define`);
   `.env` fuera del bundle.
✅ **P3-5** `MockRealtimeService.pause/resume` con
   `WidgetsBindingObserver` cableado en `main.dart:154-173`.
✅ **PROD-1** Lógica de firma condicional en Kotlin DSL puro.
✅ **PROD-2** Paginación en 10/12 repos remote.
✅ **PROD-3** Realtime real en 5/12 repos (bus_location, stop, route,
   incident, route_feedback) vía `RealtimeChannelManager` compartido.
✅ **PROD-5 (parcial)** autoDispose en 2 providers.
✅ **PROD-8 (parcial)** CI con 4 jobs incluido Build Android APK firmado.
✅ **Tests del `RealtimeChannelManager`** en `test/data/sync/`.
✅ **`android/README.md`** con flujo de firma para release.
✅ **Driver editor**: l10n usado en al menos 5 archivos
   (`live_recorder_controller`, `live_route_recorder`, `manual_route_editor`,
   `post_recording_editor`, `step_info`).

### Lo que sigue pendiente

Ver §1, §2, §3 arriba. Bloqueador real único antes de release: §1.1
(keystore). Bloqueador conceptual de "AA": §1.2 (pasada con lector).
