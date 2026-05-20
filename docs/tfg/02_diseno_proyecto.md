# 02 — Diseño del Proyecto

**Proyecto:** Transitly
**Estado verificado:** `master @ 3a31fb3` · 28/28 fases · `flutter analyze` 0 issues · 175/175 tests · cobertura 24,30 % · APK release 73,5 MB · CI verde

---

## 1. Información técnica de la aplicación

### 1.1. Visión general

Transitly es una **aplicación multiplataforma de transporte público en
tiempo real**. Una sola base de código produce binarios para:

- **Android** (APK release verificado, 73,5 MB).
- **iOS** (`flutter build ios` configurado; requiere keystore Apple para
  publicación).
- **Web** (`flutter build web` ejecutado en CI en cada push).
- **Linux / macOS / Windows** (targets soportados aunque no priorizados).

La capa de datos es **mock-first con backend Supabase opcional**: si
existe sesión autenticada, los repositorios consumen Supabase; si no, se
sirven datos mock (operador piloto COMUJESA) para que la app sea
operativa sin red.

### 1.2. Stack tecnológico (versiones verificadas)

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| UI / runtime | **Flutter 3.9.2+ / Dart 3** con `strict-casts` y `strict-raw-types` | Multiplataforma real (móvil, web, desktop) desde un solo codebase; estable y maduro |
| Gestión de estado | **Riverpod 2.6.1** (con `autoDispose` en streams/timers/futures) | Compile-safe, testeable, sin dependencia de `BuildContext` |
| Navegación | **go_router 17.2** con `StatefulShellRoute` + `redirect` por ruta | Declarativa, deep-linking, guards por rol |
| Modelos | **freezed 3.x + json_serializable 6.14** | Inmutabilidad, `copyWith`, igualdad por valor, serialización |
| Backend principal | **Supabase** (`supabase_flutter 2.8`) | PostgreSQL + Auth + RLS + Realtime + Storage + Edge Functions |
| Migraciones SQL | 13 migraciones en `supabase/migrations/` | RLS default-deny; `search_path` fijado en todas las `SECURITY DEFINER` |
| Edge Functions | 2 (`import_gtfs`, `send_notification`) en Deno | Anti-SSRF con resolución DNS, validación de invocador, rate-limit |
| Caché local | **Hive 2.2** + `hive_flutter` | NoSQL embebido, rápido; con `live_recorder_draft` cifrado pendiente |
| Cola offline | `OfflineSyncService` propio con backoff exponencial | Drenado FIFO, dead-letter tras 10 reintentos |
| Mapas | **flutter_map 7.0** + **MapTiler** + **FMTC** offline | Tiles externos sin lock-in con Google |
| NFC | `nfc_manager 3.5` (Mifare Classic) | Lectura del saldo de la *Tarjeta del Consorcio Andaluz* |
| Push | **Firebase Messaging** + `flutter_local_notifications` | FCM HTTP v1 desde Edge Function con OAuth JWT |
| Telemetría | **Sentry 8.14** + **PostHog 5.24** | Crash reporting y producto, con consent-gating GDPR |
| Tipografía | **DM Sans + IBM Plex Mono** bundleadas como assets locales (F26) | Privacidad: sin petición a Google en runtime |
| Internacionalización | `flutter_localizations` + ARB | **es / en / ar (RTL)**, 343 claves por locale |
| Tests | `flutter_test` + `mocktail` | 175 tests pasando |
| CI/CD | **GitHub Actions** con 4 jobs | Analyze, Test, Build Web, Build Android APK |
| Marketing | **Astro** SSR en `astro/` | Páginas estáticas SEO-friendly |

### 1.3. Arquitectura de capas (resumen)

```
lib/
├── main.dart           # Bootstrap: Env → Hive → Supabase → MockData → ProviderScope
├── app.dart            # MaterialApp.router (themeMode + locale + go_router)
├── core/
│   ├── router/         # go_router + redirect_guards
│   ├── theme/          # transit_colors, transit_typography, transit_spacing, transit_animations
│   └── utils/          # AppLogger, sentry_setup, uuid, helpers
├── data/               # Capa más profunda; NO depende de features/
│   ├── auth/           # Excepción documentada al patrón (ver AGENTS.md §Arquitectura)
│   ├── mock/           # MockDataService + MockRealtimeService (con pause/resume por lifecycle)
│   ├── cache/          # Hive adapters + boxes + HiveInit
│   ├── nfc/            # NfcCardService + i18n de errores
│   ├── <entity>/       # 5 ficheros: abstract, remote, local, mock, repository_provider
│   └── sync/           # PendingAction, PendingActionsQueue, OfflineSyncService, RealtimeChannelManager
├── features/           # Una carpeta por dominio funcional (feature-first)
│   └── <feature>/
│       ├── *_screen.dart
│       ├── widgets/
│       └── *_controller.dart (opcional)
├── l10n/               # ARB es/en/ar + generated/
└── shared/
    ├── models/         # Entidades de dominio (27+ con @freezed)
    ├── providers/      # Estado global Riverpod (autoDispose en streams/timers críticos)
    └── widgets/        # Reusables (≥2 features): TransitButton, Pressable, GlassCard…
```

Detalle completo en `docs/ARCHITECTURE.md`.

### 1.4. Modelo de datos (entidades principales)

- **User / Profile** — id, display_name, email, **role**
  (`passenger` / `driver` / `operator_admin` / `moderator` / `admin`),
  reputación, idioma. La fuente real es `profiles` en Supabase; el guard
  del router consume el rol real con fallback gradual a mock.
- **Operator** — id, slug, nombre, región, web, urls GTFS, bounding box
  geográfico. Pilot: COMUJESA (Jerez).
- **Route** — id, operador, código, nombre, color, polyline, paradas
  ordenadas por sentido, origen del dato (`official` / `community`).
- **Stop** — id, código, nombre, lat/lng (PostGIS), rutas que pasan.
- **Schedule** — ruta, parada, hora salida, día de la semana, dirección.
- **BusLocation** — ruta, lat/lng, timestamp, fuente
  (`gps_driver` / `simulated` / `interpolated`).
- **Incident** / **RouteFeedback** / **RouteSuggestion** —
  contribuciones comunitarias con votación, estado y autor.
- **Notification** — in-app + canal Supabase Realtime + FCM push.
- **PendingAction** — encolada cuando falla la red; drenada offline.

### 1.5. Estado de F13 — Realtime real

5 de 12 repositorios `remote/` tienen suscripción Supabase Realtime
funcional vía `RealtimeChannelManager` compartido (`lib/data/sync/`) con
backoff exponencial + jitter:

- `bus_location` (con su propio `BusPositionChannelManager` para filtros
  por `route_id`).
- `stop`, `route`, `incident`, `route_feedback` (manager compartido).

Los 7 restantes siguen patrón snapshot + refresh manual; decidir caso a
caso si necesitan vivo (`route_suggestion`, `feature_request`,
`operator`, `schedule`, `user_preferences`, `offline_region`,
`notification` — esta última tiene Realtime fuera del repo, en
`notification_stream_provider`).

---

## 2. Objetivos funcionales y no funcionales

### 2.1. Objetivos funcionales (qué debe hacer la aplicación)

Marcados ✅ los cerrados a fecha actual:

| ID | Objetivo | Estado |
|----|----------|:--:|
| F-1 | Autenticación email/contraseña + magic link + activación por código de conductor | ✅ |
| F-2 | Modelo de roles con guard real del router consumiendo `profiles.role` de Supabase | ✅ |
| F-3 | Importación masiva GTFS multi-operador (`import_gtfs` Edge Function) | ✅ |
| F-4 | Detección geográfica y *lazy loading* de operador relevante | ✅ |
| F-5 | Mapa con filtros (oficial/comunitario, incidencias, capacidad) | ✅ |
| F-6 | Editor de rutas comunitarias (wizard de varios pasos + autosave en `live_recorder_draft`) | ✅ |
| F-7 | Grabación GPS en vivo para nuevas rutas (driver) | ✅ |
| F-8 | Estimación de posición de bus por horario cuando no hay vivo | ✅ |
| F-9 | Tracking GPS del conductor en vivo + canal Realtime | ✅ |
| F-10 | Sistema de contribuciones: incidencias, feedback, sugerencias, votos | ✅ |
| F-11 | Panel de administración (operadores, usuarios, moderación) | ✅ |
| F-12 | Sistema de reputación: rangos, logros, progreso | ✅ |
| F-13 | NFC lectura saldo Tarjeta del Consorcio Andaluz | ✅ |
| F-14 | Mapas offline (FMTC) | ✅ |
| F-15 | Notificaciones push (FCM + in-app + quiet hours) | ✅ |
| F-16 | Telemetría (Sentry + PostHog) con consent-gating GDPR | ✅ |
| F-17 | Privacidad GDPR: consents, export, deletion con plazo de 30 días | ✅ |
| F-18 | Web SSR (Astro) + widgets nativos Android/iOS | ✅ |

### 2.2. Objetivos no funcionales (cómo debe comportarse)

| Categoría | Objetivo | Estado real |
|-----------|----------|-------------|
| **Rendimiento** | Arranque < 2 s en frío | Mediable; sin perf tests automatizados aún |
| **Rendimiento** | 60 fps en mapa con gestos | Sin perf tests; `RepaintBoundary` ausente en `features/` — deuda |
| **Offline** | Funcionalidad básica sin red | ✅ (caché Hive + cola offline + tiles FMTC) |
| **Escalabilidad** | Soporte multi-operador con RLS | Arquitectura preparada; ~9 operadores no poblados |
| **Seguridad** | RLS default-deny + `search_path` SECURITY DEFINER | ✅ verificado en migraciones |
| **Seguridad** | Sin secretos en bundle | ✅ `.env` removido de assets; `Env` lee `--dart-define` |
| **Accesibilidad** | WCAG 2.2 AA *parcial / en progreso* — los fundamentos cerrados (Pressable 48 dp, textScaler del SO, Semantics localizados, fuentes locales, contraste configurable, daltonismo, dislexia, reduce-motion, RTL/árabe) | Verificado en código; **falta paso real con TalkBack/VoiceOver** para defender AA pleno (ver `docs/ACCESSIBILITY.md`) |
| **i18n** | Múltiples idiomas | ✅ es / en / ar (RTL), 343 claves por locale |
| **Privacidad** | GDPR-compliant | ✅ consent-gating real; revocación efectiva en caliente; export + deletion vía `data_deletion_requests` |
| **Testabilidad** | Tests reproducibles | ✅ 175 tests, sin red, sin tiempo real (`fake_async` donde aplica) |
| **Mantenibilidad** | `flutter analyze` siempre a 0 | ✅ verificado en cada commit y CI |

### 2.3. Casos de uso clave

1. **Pasajero anónimo (guest)**: abre la app, ve el mapa de Jerez, busca
   una línea, comprueba el próximo bus simulado/estimado, lee el saldo de
   su tarjeta NFC, todo sin registrarse.
2. **Pasajero registrado**: además de lo anterior, contribuye incidencias,
   vota sugerencias, recibe notificaciones push, configura preferencias
   de accesibilidad sincronizadas.
3. **Conductor**: introduce su código de invitación, activa modo
   conductor para su ruta, su posición se publica al canal Realtime de la
   ruta.
4. **Admin / operator_admin**: gestiona operadores, modera incidencias y
   sugerencias, importa feeds GTFS desde URL pública.

---

## 3. Fases y cronograma

El proyecto se ejecutó en **28 fases incrementales (F0 → F27)**. Detalle
completo del Gantt y dependencias en `docs/tfg/03_planificacion.md`. Bloques
agrupados por temática:

| Bloque | Fases | Contenido | Estado |
|--------|-------|-----------|--------|
| I. Cimientos | F0 → F3 | Auditoría, `@freezed`, Supabase, repositorios con SWR | ✅ |
| II. Identidad | F4 → F6 | Auth, roles, códigos de conductor | ✅ |
| III. Datos | F7 → F8 | GTFS importer + multi-operador | ✅ |
| IV. Experiencia | F9 → F12 | Filtros, editor, GPS, compartir | ✅ |
| V. Ojos del bus | F13 → F14 | Realtime (5/12 repos) + driver en vivo + estimación | ✅ |
| VI. Comunidad | F15 → F16 | Contribuciones, votación, panel admin | ✅ |
| VII. Pulido | F17 → F19 | Apariencia, accesibilidad multidimensional, reputación | ✅ |
| VIII. Infra | F20 → F22 | Mapas offline, push, monitoring/telemetría | ✅ |
| IX. Plataformas | F23 → F24 | Astro Web SSR, widgets nativos Android/iOS | ✅ |
| X. Cierre | F25 → F27 | Privacidad GDPR, QA, publicación | ✅ |

---

## 4. Estudio de viabilidad técnica

### 4.1. Viabilidad confirmada

- **Flutter 3.x** es maduro para producción (BMW, Alibaba, Google Pay,
  ByteDance lo usan). El proyecto compila release sin issues conocidos.
- **Supabase** plan gratuito cubre desarrollo y MVP (500 MB DB, 2 GB
  storage, 50.000 usuarios autenticados, 500.000 invocaciones de
  funciones/mes). Plan Pro a partir de 25 €/mes cuando se necesite
  escalar.
- **GTFS** es estándar abierto (Google + MobilityData consortium).
  Datos de COMUJESA y de la mayoría de operadores españoles están
  disponibles públicamente.
- **NFC Mifare Classic** solo lectura, no requiere certificación
  bancaria. La librería `nfc_manager 3.5` soporta Android nativo e iOS
  Core NFC.
- **MapTiler** ofrece 100.000 cargas de tiles/mes en plan gratuito;
  fallback a CartoDB sin clave si se agotan.

### 4.2. Riesgos identificados y mitigaciones

| Riesgo | Impacto | Mitigación implementada |
|--------|---------|-------------------------|
| Dependencia de Supabase | Pérdida de servicio si el proveedor falla | Caché Hive + modo invitado con mock; los repos seleccionan automáticamente |
| Datos GTFS desactualizados | Información incorrecta al usuario | Sistema comunitario de correcciones (incidencias y sugerencias) |
| Fragmentación de operadores | Difícil escalar a otros operadores | Modelo de datos común basado en GTFS |
| Adopción por conductores | Sin conductores reales no hay Realtime | UX simplificada (1 botón = iniciar ruta); modo simulado para demo |
| Cuotas plan free Supabase | Bloqueo al escalar | Plan de migración a Pro/Team documentado |
| Coste futuro de Sentry/PostHog | Telemetría costosa | Consent-gating real (solo se factura por opt-in) |

Riesgos en escalabilidad y operación viva quedan recogidos en
`docs/SCALABILITY.md` (top-10 bloqueadores).

### 4.3. Viabilidad legal

- **GDPR / LOPDGDD** — implementado: consent-gating, exportación de
  datos vía `data_exports`, borrado vía `data_deletion_requests` con
  plazo de 30 días, encriptación en reposo (Supabase) y en tránsito
  (TLS).
- **Real Decreto 1112/2018** (accesibilidad sector público) — el reclamo
  honesto es "AA en progreso" (`docs/ACCESSIBILITY.md`).
- **Licencias** — proyecto bajo MIT; dependencias compatibles
  (Apache 2.0, BSD, MIT). Datos GTFS bajo licencia individual del
  operador.

---

## 5. Recursos, personal y financiación

### 5.1. Personal

- **Desarrollo:** 1 estudiante TFG (individual). Trabajo asistido por un
  sistema multiagente IA documentado (Queen / Developer / Review / Git /
  Documentation), declarado con transparencia en `multiagent/ARCHITECTURE.md`
  y referenciado en este TFG por integridad académica.
- **Tutoría:** sesiones presenciales con el profesor del módulo.

### 5.2. Recursos técnicos (coste real)

| Recurso | Coste actual | Coste a escala |
|---------|--------------|----------------|
| Supabase Free | 0 € | 25 €/mes (Pro) si crece |
| MapTiler Free | 0 € | 49 €/mes desde 500k tiles |
| Sentry Developer | 0 € | 26 €/mes desde 50k errores |
| PostHog Free | 0 € | Variable según eventos |
| Firebase FCM | 0 € | 0 € (FCM es gratuito) |
| GitHub Actions | 0 € (repositorio privado: 2000 min/mes) | 0 € o pago por uso |
| Google Play | 25 € (one-time) | 25 € |
| Apple Developer | 99 €/año | 99 €/año |
| **Total MVP** | **~25 €** (Play) | **~150–200 €/mes** para escalar |

### 5.3. Equipo y entorno de desarrollo

- IDE: Visual Studio Code / IntelliJ IDEA + plugin Flutter/Dart.
- VCS: Git + GitHub (control de versiones obligatorio por la guía).
- Tracker: GitHub Issues + plan vivo en `docs/PLAN_ACCION_REMEDIACION.md`.
- Comunicación con tutores: presencial + correo institucional.

---

## 6. Indicadores de calidad

| Indicador | Objetivo | Actual | Estado |
|-----------|----------|--------|:--:|
| Cobertura de tests | > 60 % (objetivo nominal) | **24,30 %** (4 004/16 476) | 🟥 deuda declarada |
| Issues de lint | 0 errors | **0 issues** (0 errors, 0 warnings, 0 info) | 🟩 |
| Tests verdes | 100 % | **175/175** | 🟩 |
| Build APK release | OK | **OK** (73,5 MB) | 🟩 |
| CI verde | Sí | **4 jobs verdes** | 🟩 |
| Crash-free rate | > 99 % | Por medir tras publicación (Sentry) | ⬜ |
| Accesibilidad | WCAG 2.2 AA | **AA parcial / en progreso** | 🟨 |
| i18n cobertura | 100 % | **343/343 claves en 3 locales** | 🟩 |
| Tamaño APK | < 50 MB | 73,5 MB (deuda: app bundle + splits ABI) | 🟨 |
| Tiempo de build debug | < 3 min | ~2 min | 🟩 |

La cobertura es el indicador más rojo: la palanca real es escribir tests
para la capa `remote/` (P2-4 en el plan). Detalle en
`docs/PENDIENTE_PARA_CERRAR.md §2.2`.

---

## 7. Requisitos legales y conformidad

### 7.1. Protección de datos

- **Base legal del tratamiento:** consentimiento explícito para
  analítica/crash-reporting; ejecución de contrato para datos de cuenta
  (necesarios para auth) ; interés legítimo para logs técnicos
  pseudonimizados (UID truncado a 8 chars).
- **Derechos del usuario implementados:** acceso (export `data_exports`),
  rectificación (perfil editable), supresión
  (`data_deletion_requests` con borrado en 30 días), portabilidad (export
  en JSON/CSV), oposición (revocación de consent en caliente, sin
  reinicio).
- **DPO:** no aplica en MVP (umbral GDPR no alcanzado), pero contacto
  publicado en la pantalla de Privacidad.

### 7.2. Accesibilidad

Conformidad declarada en la propia app:
- *"Accesibilidad en progreso (WCAG 2.2 AA parcial): contraste
  configurable, daltonismo, dislexia, reduce-motion, objetivos táctiles
  ≥48 dp, Semantics localizados, fuentes locales, RTL/árabe; pendientes
  conocidos: paso con lector de pantalla, alternativa accesible al
  mapa, foco."*

Trazabilidad en `docs/ACCESSIBILITY.md`.

### 7.3. Propiedad intelectual y licencias

- Código bajo licencia MIT (permisiva).
- Dependencias revisadas: todas con licencias permisivas (MIT, Apache 2.0,
  BSD-3) compatibles con uso comercial.
- Datos GTFS de COMUJESA: bajo licencia de uso público (consultado en
  fuentes oficiales del ayuntamiento de Jerez).
- Recursos gráficos: iconos Lucide (ISC), tipografías DM Sans y IBM Plex
  Mono (OFL).

---

## 8. Conclusión del diseño

El diseño técnico está cerrado y validado por un MVP funcional: stack
elegido es maduro, arquitectura por capas se respeta (`flutter analyze`
0, regla "data no depende de features" verificada), objetivos
funcionales cumplidos al 100 % en las 28 fases planificadas, y los
indicadores no funcionales tienen los fundamentos en su sitio salvo
**cobertura** (deuda declarada con palanca identificada) y
**accesibilidad pleno AA** (requiere paso manual con lector). El
siguiente documento (`03_planificacion.md`) detalla cronograma, recursos
y riesgos.
