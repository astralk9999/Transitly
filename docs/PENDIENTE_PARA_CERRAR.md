# Transitly — Pendiente para el próximo ciclo (todo, en un sitio)

> **Para qué sirve este documento:** lo que falta tras los ciclos cerrados
> hasta el **2026-05-20 (noche)**, listo para retomar. Es el *playbook*
> exhaustivo y autocontenido — no hace falta abrir otros docs.
> **Estado verificado (2026-05-20):** `master @ 9a0cc0b` ·
> `flutter analyze` **0 issues** ✅ · `flutter test` **175/175** ✅ ·
> cobertura **24,30 %** · `flutter build apk --release` **OK** (73,5 MB) ·
> **CI verde** (4 jobs, incl. Build Android APK) para los commits ya
> completados; los doc-only más recientes en `in_progress` al cierre.
> **Nota:** la rotación del PAT de Supabase (antes SEC1/PROD-4) queda
> **descartada** (dev / migración de BD próxima).

> **⚠️ Integridad documental:** este playbook se re-verifica con grep en
> código y comentarios cada ciclo. Ítems falsos detectados en versiones
> previas y eliminados aquí: paginación de `user_preferences` (singular,
> no aplica), P1-6 en `transit_button` (intencional documentado), P1-7
> en `map_style_section` (swatches intencionales), F26 fuentes, A11Y-6
> `e.toString()` crudo, P1-8 `ActionButton`, P1-9 `showTransitBottomSheet`,
> P1-10 `mounted`/`unawaited`, **P2-3 unificación de usuario** (hecho en
> `7550751`), **doc excepción `data/auth`** (en `AGENTS.md:259`).

---

## 1. Lo crítico que aún falta (acción manual del usuario)

### 1.1 🔴 Keystore real para APK publicable

El `build.gradle.kts` ya cae con elegancia a debug cuando `key.properties`
no existe (verificado: APK compila 73,5 MB), pero el APK no es publicable
en Play Store sin keystore real. **Único bloqueador de release.**

```bash
# 1. Generar keystore (NO commitear .jks ni key.properties)
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear android/key.properties (plantilla y guía en android/README.md)
#    storePassword=...
#    keyPassword=...
#    keyAlias=upload
#    storeFile=upload-keystore.jks

# 3. Build + verificación de firma real (no debug)
flutter build appbundle --release
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

Para CI con Play App Signing: secrets `KEYSTORE_BASE64`,
`KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` + step que reconstruya
los ficheros. Detalle en `android/README.md`.

### 1.2 🟠 Verificación REAL de accesibilidad con lector de pantalla

Mientras no se haga una pasada con **TalkBack** (Android) y **VoiceOver**
(iOS) en sesión grabada + checklist por release, **"WCAG 2.2 AA" no es
defendible**. Tiempo: ~1 día de pruebas + acta firmada.

---

## 2. Lo importante (días — código)

### 2.1 ⏳ `autoDispose` en providers críticos de streams/timers

Hechos en `home_providers.dart` y `nfc_provider.dart`. **Faltan los más
sensibles a recursos vivos**:

- `notificationStreamProvider` — Stream Supabase Realtime (cierre del canal
  al salir de pantalla).
- `realtimeTripsProvider` — `Timer.periodic`; ya hay `pause/resume` por
  lifecycle (`P3-5`), `autoDispose` lo remata cuando nadie observa.
- `privacyConsentsProvider` — `FutureProvider` que conviene re-fetchear.
- Todos los `.family` parametrizados (no acumular instancias por parámetro).

### 2.2 ⏳ Tests de la capa de datos de producción (P2-4)

**Es la palanca principal para subir cobertura (estancada en 24 %).** Con
`SupabaseClient`/`PostgrestClient` mockeados, cubrir:

- `auth_repository_supabase`
- `userProfileFromSupabaseProvider` (recién unificado en P2-3)
- `stop_remote_repository`
- `route_remote_repository`
- `bus_location_remote_repository`
- `bus_position_channel_manager` (ampliar el caso existente)
- `realtime_channel_manager` (ya tiene tests; añadir más casos de
  reconexión/backoff)

### 2.3 ⏳ Strings ES + issues F16/F22 residuales (P1-1, P1-11)

- **P1-1:** los 6 sitios más visibles con `e.toString()` ya están
  localizados; queda barrer pantallas secundarias con
  `grep -rnE "Text\(['\"][A-ZÁÉÍÓÚ]"` y migrar a l10n.
- **P1-11:** issues F16/F22 de `docs/PENDIENTES.md` (validación inline,
  unique-violation, dedupe mapping, loading en botones, cola offline en
  `updateStatus`).

### 2.4 ⏳ Refinos de calidad

- **`streamForRoute` doble controller** (`bus_location_remote_repository.dart`):
  simplificar con concat/prepend en vez de dos `StreamController` anidados.
- **RTL runtime**: probar `app_ar.arb` en dispositivo (Material flips
  automáticamente; verificar widgets custom y mapas).
- **Verificación de contrastes** de tokens en `transit_colors.dart` con
  Stark/axe; no usar color como único indicador en `status_badge`/
  `capacity_indicator` (añadir icono/forma).
- **Foco**: `FocusTraversalGroup` por sección, visibilidad de foco,
  navegación por teclado/switch.

---

## 3. Deuda de fondo (semanas — opcional TFG, obligatorio producción)

### 3.1 Bloqueadores de producción a escala

- **PROD-6** Mapa a escala: clustering por zoom, `RepaintBoundary`, LOD.
- **PROD-7** Observabilidad: tracing cliente↔Edge↔DB, métricas de
  negocio, SLO/alertas, logs estructurados.
- **PROD-9** Caché/tenant: tamaño/evicción/cifrado Hive; partición por
  `operator_id`; cifrar `live_recorder_draft` (**P3-4**).
- **PROD-10** Backend a escala: FORCE RLS + auditoría, pooling,
  idempotencia Edge, GTFS streaming, plan no-free / multi-región.

### 3.2 CI/CD producción

- Build iOS firmado en CI.
- Gate de cobertura con umbral declarado (sube tras §2.2).
- SAST + Dependabot/Renovate.
- Smoke E2E.

### 3.3 Accesibilidad full WCAG 2.2

- **A11Y-1** Alternativa accesible al mapa: lista equivalente enlazada
  + semántica del mapa (`AccessibleBusesScreen` ya existe; integrarla
  como ruta paralela).
- **A11Y-10** Lectura fácil + localización completa de
  números/fechas/moneda (más allá del ARB).

### 3.4 Deuda asumida (NO se hará sin decisión explícita)

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

Tras pushear, consulta `https://github.com/astralk9999/Transitly/actions` y
verifica los 4 jobs (Analyze, Test, Build Web, Build Android APK) en `success`.

---

## 5. Resumen ejecutivo

- **CI:** verde (4 jobs incl. Build Android APK). Kotlin DSL del ciclo
  anterior cerrado en `5141b39`.
- **APK release publicable:** falta solo §1.1 (~15 min — keystore + Play
  App Signing). **Único bloqueador real de release**.
- **"WCAG AA" defendible:** falta §1.2 (~1 día — pasada con
  TalkBack/VoiceOver + acta).
- **Cobertura ≥30 %:** requiere §2.2 (tests de la capa `remote/`).
- **Multi-tenant / producción a escala:** §3 (semanas de trabajo).
- **Acción externa:** ninguna obligatoria en este ciclo (PAT descartado).

### Lo cerrado en ciclos recientes (con evidencia verificada)

✅ **§1.1 Kotlin DSL** en `build.gradle.kts` (`5141b39`, CI Android verde).
✅ **§1.3 AGENTS.md saneado** (`6de6261`): tests=175, CI=4 jobs, fases=28/28,
   i18n=ES+EN+AR.
✅ **F26 / A11Y-8 / P2-6 Fuentes locales**: `_fontsBundled=true`,
   `assets/fonts/dm_sans/` + `assets/fonts/ibm_plex_mono/` con 4 `.ttf`,
   declaradas en `pubspec.yaml:101-111`.
✅ **A11Y-2** `Pressable` ≥48 dp (`TransitSpacing.minTapTarget`).
✅ **A11Y-4** Semantics ES → l10n en home_tab/card_tab/route_card/etc.
✅ **A11Y-5** `textScaler` compone con el del SO.
✅ **A11Y-6** `e.toString()` crudo eliminado de las 6 pantallas listadas
   (0 ocurrencias verificadas).
✅ **P1-2 / P1-5** Semantics→l10n; 7 modelos manuales→`@freezed`.
✅ **P1-6** GoogleFonts en `shared/widgets/`: **11→1 migrados**; el último
   (`transit_button.dart:69`) documentado como intencional
   (fontSize dinámico) en `782cec6`.
✅ **P1-7** Colores raw en `map_style_section.dart` documentados como
   intencionales (swatches de tile providers) en `f55a168`.
✅ **P1-8** `ActionButton` eliminado.
✅ **P1-9** `inbox_action_sheets` usa `showTransitBottomSheet` (3 sitios).
✅ **P1-10** `privacy_screen._setConsent`: `if (!mounted) return;`,
   `ref.invalidate`, `unawaited(...)` correctos.
✅ **P2-3 Modelo de usuario unificado** (`7550751`):
   `userProfileFromSupabaseProvider` (FutureProvider que lee `profiles` de
   Supabase con manejo de `PostgrestException`), `currentUserProvider`
   con fallback gradual (perfil real → mock guest), `currentUserRoleProvider`
   derivado, y el router (`redirect_guards.dart:31`) consume el rol REAL.
✅ **P2-5 / SEC2** `Env` via `String.fromEnvironment` (`--dart-define`);
   `.env` fuera del bundle.
✅ **P3-5** `MockRealtimeService.pause/resume` con `WidgetsBindingObserver`
   cableado en `main.dart:154-173`.
✅ **P3-6** Excepción de `data/auth` documentada con 4 razones en
   `AGENTS.md:259-265`.
✅ **PROD-1** Lógica de firma condicional en Kotlin DSL puro.
✅ **PROD-2** Paginación **completa (11/11 repos de lista)**:
   `user_preferences` excluido por diseño (objeto singular, no colección).
✅ **PROD-3** Realtime real en 5/12 repos (bus_location, stop, route,
   incident, route_feedback) vía `RealtimeChannelManager` compartido.
✅ **PROD-5 (parcial)** autoDispose en 2 providers (home_providers,
   nfc_provider).
✅ **PROD-8 (parcial)** CI con 4 jobs incl. Build Android APK firmado.
✅ Tests del `RealtimeChannelManager` en `test/data/sync/`.
✅ `android/README.md` con flujo de firma para release.
✅ Driver editor: l10n usado en al menos 5 archivos.

### Lo que sigue pendiente

Ver §1, §2, §3 arriba. **Único bloqueador real de release**: §1.1
(keystore). **Bloqueador conceptual de "AA"**: §1.2 (pasada con lector
de pantalla). **Palanca de cobertura**: §2.2 (tests de capa `remote/`).

### Cambios respecto al playbook anterior

Solo cambios documentales: marcar P2-3 (unificación de usuario) y la doc
de excepción `data/auth` como cerrados — ambos verificados con
evidencia `archivo:línea` directamente en el código de
`lib/shared/providers/user_provider.dart:17-65` y `AGENTS.md:259-265`.
El playbook anterior los tenía como pendientes por desactualización.
