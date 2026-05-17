# 02 — Diseño del Proyecto

**Proyecto:** Transitly
**Fecha:** 2026-05-14

---

## 1. Información técnica

### Stack tecnológico

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| Frontend | Flutter 3.x + Dart | Multiplataforma real (iOS, Android, Web) desde un solo codebase |
| Backend | Supabase (PostgreSQL) | Auth, RLS, Realtime, Storage, Edge Functions, PostGIS |
| Estado | Riverpod 2.x | Compile-safe, testeable, sin dependencia de BuildContext |
| Routing | go_router | Navegación declarativa con redirects y deep linking |
| Modelos | freezed + json_serializable | Inmutabilidad, copyWith, serialización automática |
| Caché local | Hive | NoSQL rápido, tipado, con cifrado AES |
| Mapas | MapTiler / flutter_map | Tiles offline, sin dependencia de Google |
| NFC | flutter_nfc_kit | Lectura de tarjetas de transporte Mifare |
| Testing | flutter_test + mocktail | Widget tests, unit tests, provider tests |
| CI/CD | GitHub Actions (planificado F26) | Analyze + test + build runner verify |
| Monitoring | Sentry + PostHog (planificado F22) | Crash reporting + analítica |

### Arquitectura

```
lib/
├── main.dart              # Bootstrap: Env → Hive → Supabase → MockData → ProviderScope
├── app.dart               # MaterialApp.router (themeMode + locale + go_router)
├── core/
│   ├── router/            # go_router + redirects + errorBuilder
│   ├── theme/             # transit_colors, transit_typography, transit_spacing
│   └── utils/             # AppLogger, uuid, helpers
├── data/                  # Capa de datos (NO depende de features/)
│   ├── mock/              # MockDataService + MockRealtimeService
│   ├── cache/             # Hive adapters + boxes
│   ├── nfc/               # NfcCardService
│   ├── <entity>/          # Repositorios: abstract, remote, local, mock, provider
│   └── sync/              # Cola offline: PendingAction, OfflineSyncService
├── features/              # Feature-first: una carpeta por dominio
│   └── <feature>/
│       ├── *_screen.dart
│       ├── widgets/
│       └── *_controller.dart
├── l10n/                  # ARB sources + generated (es, en)
└── shared/
    ├── models/            # Entidades de dominio (@freezed)
    ├── providers/         # Estado global Riverpod
    └── widgets/           # Widgets reusables (≥2 features)
```

### Modelo de datos (entidades principales)

- **User:** id, name, email, role (passenger/driver/operatorAdmin/moderator/admin), reputation
- **Operator:** id, slug, name, region, website, GTFS urls, bbox geográfico
- **Route:** id, operator, name, color, polyline, paradas, tipo (oficial/comunitaria)
- **Stop:** id, name, lat/lng, operador, rutas que pasan
- **Schedule:** ruta, parada, hora salida, día de la semana
- **BusLocation:** ruta, lat/lng actual, timestamp, origen del dato
- **Incident:** ruta/parada, tipo, descripción, estado, autor
- **RouteFeedback/RouteSuggestion:** contribuciones comunitarias con votos

---

## 2. Objetivos funcionales y no funcionales

### Funcionales
- [x] Autenticación (email, magic link, OAuth planificado)
- [x] Roles de usuario con permisos granulares
- [x] Códigos de invitación para conductores
- [x] Importación GTFS multioperador (10 operadores españoles)
- [x] Detección geográfica y lazy loading de operadores
- [x] Mapa con filtros (oficial/comunitario, incidentes, capacidad)
- [x] Editor de rutas comunitarias (wizard + autosave)
- [x] Grabación GPS en vivo para nuevas rutas
- [x] Estimación de posición de bus por horario
- [x] Tracking GPS de conductor en vivo
- [x] Sistema de contribuciones: incidencias, feedback, sugerencias, votos
- [ ] Panel de administración (F16 — en progreso)
- [ ] Personalización visual y accesibilidad (F17-F18)
- [ ] Mapas offline (F20)
- [ ] Notificaciones push (F21)

### No funcionales
- **Rendimiento:** < 2s arranque en frío, 60fps en mapa con gestos
- **Offline-first:** Funcionalidad básica sin conexión, sincronización al reconectar
- **Escalabilidad:** Soporte para 100+ operadores, 10k+ rutas, RLS en 25 tablas
- **Seguridad:** Row-Level Security en PostgreSQL, cifrado AES en caché local
- **Accesibilidad:** WCAG 2.1 AA parcial — contraste 4.5:1 validado, fuente dislexia, color-blind, soporte lector de pantalla; sin verificación manual TalkBack/VoiceOver (gaps en `docs/A11Y_AUDIT.md`)
- **i18n:** Español + Inglés (ARB),arquitectura preparada para más idiomas

---

## 3. Fases y cronograma

Ver `docs/tfg/03_planificacion.md` para el diagrama de Gantt completo.

| Bloque | Fases | Contenido | Estado |
|--------|-------|-----------|--------|
| I. Cimientos | F0 → F3 | Auditoría, freezed, Supabase, repositorios | ✅ |
| II. Identidad | F4 → F6 | Auth, roles, códigos conductor | ✅ |
| III. Datos | F7 → F8 | GTFS importer, multioperador | ✅ |
| IV. Experiencia | F9 → F12 | Filtros, editor, GPS, compartir | ✅ |
| V. Ojos del bus | F13 → F14 | Estimación + driver en vivo ✅; **GTFS-Realtime de buses pendiente** (stub snapshot+refresh) | 🟨 |
| VI. Comunidad | F15 → F16 | Contribuciones, panel admin | 🟨 |
| VII. Pulido | F17 → F19 | Apariencia, accesibilidad, reputación | ⏳ |
| VIII. Infra | F20 → F22 | Mapas offline, push, monitoring | ⏳ |
| IX. Plataformas | F23 → F24 | Web, widgets nativos | ⏳ |
| X. Cierre | F25 → F27 | Privacidad, QA, publicación | ⏳ |

---

## 4. Estudio de viabilidad técnica

### Viabilidad
- Flutter 3.x es maduro para producción (Google, BMW, Alibaba)
- Supabase ofrece plan gratuito generoso (500MB DB, 2GB storage, 50k usuarios)
- GTFS es estándar abierto con datos públicos disponibles
- NFC solo lectura (no requiere certificación de seguridad bancaria)
- MapTiler ofrece 100k tiles/mes gratis

### Riesgos
- **Dependencia de Supabase:** Mitigado con caché Hive local + modo invitado mock
- **Datos GTFS desactualizados:** Mitigado con sistema comunitario de correcciones
- **Fragmentación de operadores:** Mitigado con modelo de datos común (GTFS)
- **Adopción por conductores:** Mitigado con UX simplificada (1 botón = iniciar ruta)

---

## 5. Indicadores de calidad

| Indicador | Objetivo | Medición |
|-----------|----------|----------|
| Cobertura de tests | > 60% | flutter test --coverage |
| Issues de lint | 0 warnings, 0 errors | flutter analyze |
| Tiempo de build | < 5 min | flutter build apk --release |
| Tamaño APK | < 50 MB | flutter build apk --analyze-size |
| Crash-free rate | > 99% | Sentry |
| Accesibilidad | WCAG 2.1 AA parcial (sin pase manual TalkBack/VoiceOver) | Audit `docs/A11Y_AUDIT.md` |

---

## 6. Requisitos legales

- **GDPR / LOPD:** Consentimiento explícito para analítica y crash reporting (F25)
- **Licencias:** Código abierto (MIT), datos GTFS bajo licencia de cada operador
- **Protección de datos:** Datos personales en Supabase RLS, cifrado AES en Hive local
- **NFC:** Solo lectura, no almacena datos de tarjeta

---

**Última actualización:** 2026-05-14 · Documentation Agent
