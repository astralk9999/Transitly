# 05 — Seguimiento, Evaluación y Documentación

**Proyecto:** Transitly
**Estado verificado:** `master @ 3a31fb3` · 28/28 fases · `flutter analyze` 0 issues · 175/175 tests · cobertura 24,30 % · APK release 73,5 MB · CI verde

---

## 1. Procedimientos de control y seguimiento

### 1.1. Control diario

Antes de cada commit:

- `flutter analyze` — **0 errors, 0 warnings, 0 info** obligatorios.
- `flutter test` — **100 % verde**.
- `git status` — árbol limpio (sin cambios sin commitear al final de sesión).

### 1.2. Control por fase

- Checklist de "Hecho cuando" inicialmente en
  `docs/historico/PLAN_TRANSITLY_V2.md` (plan original archivado al
  cierre F27).
- Verificación cruzada con el **Review Agent** del sistema multiagente
  (revisiones críticas independientes documentadas).
- Commit semántico (`feat:`, `fix:`, `docs:`, `refactor:`) y push
  inmediato.

### 1.3. Control multiagente

- **Queen Agent** supervisa el progreso global y asigna tareas.
- Máximo 3 reintentos por tarea antes de bloquear y pedir intervención
  humana.
- Estado documentado en `multiagent/state/queue.json` y
  `multiagent/state/project.json`.

### 1.4. Control externo (CI)

- **GitHub Actions** con 4 jobs ejecutados en cada push a `master`:
  Analyze, Test, Build Web (release), Build Android APK.
- Si CI rojo → bloqueo de avance hasta verde de nuevo.
- Cobertura subida como artifact (`coverage/lcov.info`) en cada test
  run.

### 1.5. Revisiones críticas independientes

A lo largo del proyecto se realizaron **4 pasadas críticas
independientes** documentadas en
`docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md`. Cada pasada
descubrió deuda real que se trasladó al plan vivo
(`docs/PLAN_ACCION_REMEDIACION.md`) y se cerró en ciclos sucesivos
(Workstream R, ciclos P0/P1, etc.).

---

## 2. Registro de incidencias

### 2.1. Incidencias detectadas y resueltas

| ID | Fecha | Descripción | Severidad | Estado |
|----|-------|-------------|:--:|--------|
| 1.17 | 2026-05-04 | Bug de routing en `driver_panel.dart` | S | ✅ `e4af39e` |
| 1.5 | 2026-05-04 | "Elegir otra" en `start_route_screen` sin funcionar | S | ✅ `fa531e1` |
| 1.14 | 2026-05-04 | Botón INCIDENCIA sin handler | S | ✅ `0491f79` |
| 3.2 | 2026-05-04 | `MockDataException` sin tipar | M | ✅ `1f16f12` |
| 3.4.1-5 | 2026-05-04 | Providers extraíbles de widgets | M | ✅ F0.5.B |
| 1.19 | 2026-05-10 | MapTab filtros inertes | M | ✅ `2c52f25` |
| 3.6.5 | 2026-05-10 | `_findClosestRoute` sin early return | S | ✅ `2c52f25` |
| 3.6.6 | 2026-05-14 | Sin CI, sin pre-commit hook | M | ✅ F26 (`.github/workflows/ci.yml`) |
| 3.6.1 | 2026-05-14 | `MockRealtimeService` no pausa timers en background | M | ✅ P3-5 (`WidgetsBindingObserver` en `main.dart:154-173`) |
| 3.6.3 | 2026-05-14 | `google_fonts` con fetch en runtime | M | ✅ F26 (fuentes locales bundleadas) |
| 3.6.4 | 2026-05-14 | `SmokeBackground` con Ticker permanente | S | ✅ |
| — | 2026-05-14 | `live_recorder_draft` en `shared_preferences` (no Hive) | M | ⏸️ Diferido a producción real (P3-4) |
| **CRIT-1** | 2026-05-18 | APK release nunca había compilado (workmanager + desugaring + Gradle OOM) | **S** | ✅ Resuelto en ciclo R |
| **CRIT-2** | 2026-05-18 | CI nunca había pasado verde (asset `.env` ausente + Flutter version mismatch) | **S** | ✅ Resuelto |
| **CRIT-3** | 2026-05-19 | Sintaxis Groovy mezclada en `build.gradle.kts` (Kotlin DSL) | **S** | ✅ Resuelto |

**Totales:** 15 incidencias registradas — **14 cerradas / 1 diferida**.

### 2.2. Incidencias diferidas (deuda consciente)

- `live_recorder_draft` en `shared_preferences` sin cifrar — el dato es
  un borrador GPS, mitigado por no contener PII vinculada; cifrado a
  Hive AES queda como P3-4 del plan vivo.

### 2.3. Bloqueadores conocidos (no incidencias del desarrollo, sino del
producto cara a producción)

Documentados en `docs/SCALABILITY.md §Top-10` y
`docs/ACCESSIBILITY.md §Top-10`. Resumen:

- 🔴 Keystore real ausente → APK no publicable (B1).
- 🟠 Sin verificación con TalkBack/VoiceOver → "AA" no defendible (A11Y-3).
- 🟠 Cobertura 24,30 % con la capa `remote/` casi sin tests (P2-4).
- 🟠 Mapa sin clustering ni LOD a escala (PROD-6).
- 🟠 Sin observabilidad de negocio / SLO (PROD-7).

---

## 3. Cambios y mejoras documentados

### 3.1. Mejoras estructurales (F0.5)

- Migración de modelos a `@freezed` (20 inicialmente, 27+ tras P1-5).
- `MockDataService` tipado con errores.
- Providers extraídos de widgets monolíticos.
- Flujos de demo continua funcionales.

### 3.2. Mejoras de arquitectura (F1-F3)

- 12 repositorios con patrón canónico (`domain/remote/local/mock/provider`).
- Caché Hive.
- Cola offline con backoff exponencial y dead-letter.
- SWR (*stale-while-revalidate*) en providers de selección.

### 3.3. Mejoras de producto (F4-F15)

- Auth multi-método (email/password, magic link, activación por código).
- 5 roles con permisos granulares (passenger, driver, operator_admin,
  moderator, admin).
- 10 operadores españoles identificados con GTFS (COMUJESA poblado).
- Sistema de contribuciones comunitarias.
- Tracking GPS de conductor en vivo.

### 3.4. Mejoras de experiencia (F16-F25)

- Panel admin con CRUD de operadores, usuarios y moderación.
- Sistema de apariencia: 6 paletas, 5 fondos, custom palette con
  validación WCAG AA.
- Accesibilidad multidimensional: alto contraste, color-blind matrix,
  OpenDyslexic, screen reader (Semantics localizados).
- Reputación: 7 rangos, 9 logros, barra de progreso.
- Mapas offline: MapTiler + FMTC + región export.
- Notificaciones push: FCM + in-app, quiet hours, toggles por categoría.
- Telemetría: Sentry + PostHog con consent-gating real (revocación
  efectiva en caliente).
- Web híbrida: Astro SSR con páginas marketing.
- Widgets nativos: Android home widget + iOS widget.
- Privacidad GDPR: consents, export, deletion con plazo 30 días.

### 3.5. Mejoras post-cierre (Workstream R y ciclos P0/P1)

- Stack modernizado: `freezed` 2→3, `go_router` 14→17,
  `json_serializable` 6.8→6.14.
- Kotlin DSL puro en `build.gradle.kts` con signing condicional.
- F13 Realtime real en 5/12 repos con `RealtimeChannelManager`
  compartido + multiplexación + backoff jitter.
- Paginación añadida a 11/11 repos de lista (`user_preferences` excluido
  por diseño — objeto singular).
- `autoDispose` en 6 providers críticos (streams Realtime, timers,
  futures que conviene re-fetchear).
- **Modelo de usuario unificado**: `userProfileFromSupabaseProvider`
  con fallback gradual a mock; guard del router consume rol REAL.
- A11Y: `Pressable` 48 dp, `textScaler` compone con el del SO,
  `Semantics` localizados (ES/EN/AR), fuentes locales bundleadas,
  `e.toString()` crudo eliminado.
- SEC2: `.env` → `--dart-define`, fuera del bundle.
- i18n: 33 strings ES residuales migrados a l10n, soporte árabe + RTL.
- `MockRealtimeService.pause/resume` con `WidgetsBindingObserver` real.

---

## 4. Feedback de usuarios

### 4.1. Usuarios reales

No se realizó beta con usuarios reales en el alcance del TFG; se utilizó
**mock data con perfiles simulados** que cubren los casos de uso
principales (pasajero anónimo, pasajero registrado, conductor, admin) y
la **demo presencial** ante el tutor.

### 4.2. Usuarios simulados (mock)

| Fuente | Tipo | Feedback | Acción |
|--------|------|----------|--------|
| Mock data | Usuario simulado | Interfaz de filtros confusa | Rediseñados en F9 |
| Mock data | Usuario simulado | Sin forma de reportar incidencias | Añadido en F15 |
| Plan v2 | Auto-revisión | Pantallas placeholder sin wiring | Cerradas en F0.5 |
| Review Agent | Automático | l10n definido pero no consumido | Corregido en F16-002 |
| Revisión crítica independiente | Externo simulado | F13 Realtime sin implementar | Cerrado parcialmente (5/12 repos) |
| Revisión crítica independiente | Externo simulado | Doble modelo de usuario | Cerrado en P2-3 |
| Revisión crítica independiente | Externo simulado | `e.toString()` crudo en errores visibles | Cerrado |

### 4.3. Beta planificada para producción

- **Beta cerrada** con 5-10 usuarios reales de Jerez recomendados por
  conocidos.
- **Distribución:** Play Store interno (track Internal Testing) + URL
  TestFlight iOS.
- **Recolección:** Sentry feedback, formulario en la propia app, sesión
  presencial con cada beta-tester.
- **Métricas a recolectar:** crash-free rate, tiempo medio de sesión,
  paradas favoritas, tasa de uso de NFC.

---

## 5. Indicadores de calidad (verificados)

### 5.1. Indicadores técnicos

| Indicador | Objetivo | Actual | Estado |
|-----------|----------|--------|:--:|
| Cobertura de tests | > 60 % | **24,30 %** (4 004/16 476 líneas) | 🟥 deuda declarada |
| Issues de lint | 0 errors | **0 issues** (0/0/0) | 🟩 |
| Tests verdes | 100 % | **175/175** | 🟩 |
| Build time (debug) | < 3 min | ~2 min | 🟩 |
| Build APK release | OK | **OK** (73,5 MB) | 🟩 |
| CI verde | Sí | **4/4 jobs verdes** | 🟩 |
| Tamaño APK | < 50 MB | 73,5 MB | 🟨 (deuda: app bundle + splits ABI) |
| Tiempo de arranque | < 2 s | Por medir formalmente | ⬜ |
| Crash-free rate | > 99 % | Por medir tras publicación (Sentry F22) | ⬜ |

### 5.2. Indicadores de producto

| Indicador | Objetivo | Actual | Estado |
|-----------|----------|--------|:--:|
| Accesibilidad WCAG 2.2 AA | Cumplir AA | **AA parcial / en progreso** (gaps en `docs/ACCESSIBILITY.md`) | 🟨 |
| i18n cobertura | 100 % | **343/343 claves en ES/EN/AR** | 🟩 |
| F13 Realtime | 12/12 repos | **5/12 repos** | 🟨 |
| Paginación | Todos los repos de lista | **11/11** | 🟩 |
| `autoDispose` | Providers críticos | **6 cerrados** | 🟨 (queda `.family`) |

### 5.3. Indicadores documentales

| Indicador | Estado |
|-----------|:--:|
| README al día con métricas reales | 🟩 (actualizado al estado actual) |
| Mapa de documentación con TFG | 🟩 (`docs/README.md`) |
| Doc maestra única (fuente de verdad) | 🟩 (`docs/00_MAESTRO.md`) |
| Plan de remediación vivo | 🟩 (`docs/PLAN_ACCION_REMEDIACION.md`) |
| Histórico archivado | 🟩 (`docs/historico/` con 6 docs) |

---

## 6. Documentación entregada

### 6.1. Documentos exigidos por la guía TFG (mapeo en `docs/README.md`)

| Entregable guía | Fichero |
|-----------------|---------|
| Memoria del Proyecto | `docs/tfg/01..08` |
| Aplicación Final | Repositorio + `app-release.apk` |
| Documentación Técnica | `docs/tfg/06_manual_tecnico.md` + `docs/PLATFORM_SETUP.md` + `docs/FCM_SETUP.md` + `docs/HOME_WIDGETS.md` + `docs/WEB_SETUP.md` + `docs/FONTS_F26.md` + `docs/SECURITY_PAT_ROTATION.md` + `android/README.md` |
| Manual de Usuario | `docs/tfg/07_manual_usuario.md` |
| Presentación Final | `docs/tfg/08_presentacion.md` |
| Diagrama de Gantt | `docs/tfg/03_planificacion.md` |
| Evaluación del Proyecto | `docs/tfg/05_evaluacion_documentacion.md` (este documento) + `docs/00_MAESTRO.md` |

### 6.2. Documentación crítica adicional (más allá del mínimo)

- `docs/SCALABILITY.md` — dossier de escalabilidad para producción.
- `docs/ACCESSIBILITY.md` — dossier WCAG 2.2 AA.
- `docs/PLAN_ACCION_REMEDIACION.md` — plan vivo de 57 ítems.
- `docs/PENDIENTE_PARA_CERRAR.md` — playbook táctico próximo ciclo.

---

## 7. Honestidad académica

El proyecto **declara explícitamente** el uso de un sistema multiagente
IA durante el desarrollo (Queen / Developer / Review / Git /
Documentation) — documentado en `multiagent/ARCHITECTURE.md` y
referenciado en este TFG. Esta declaración es parte del compromiso de
**integridad académica**: el proyecto se evalúa por las decisiones
tomadas, la arquitectura defendida y los resultados verificables, no
por la negación de herramientas.

Las **revisiones críticas independientes** documentadas en
`docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md` (4 pasadas) son la
mejor garantía de que el proyecto se evalúa con rigor: cada pasada
descubrió deuda real y se cerró con commits verificables.

---

## 8. Lecciones aprendidas

1. **Verificar siempre con pipeline completo.** El APK release no
   compilaba durante semanas porque solo se ejecutaba `flutter build
   web` localmente. Lección: **un CI que construye todos los targets
   relevantes es no negociable**.
2. **Cifras en docs siempre cruzadas con código.** En varias pasadas se
   descubrieron docs con "143 tests" cuando había 175; "WCAG 2.1 AA"
   cuando solo era parcial; "F13 implementado" cuando 0/12 repos lo
   tenían. Lección: **una fuente única de verdad (`00_MAESTRO.md`) y
   regenerar métricas, no copiarlas**.
3. **Asistencia IA exige verificación independiente.** El sistema
   multiagente genera mucho código de calidad alta, pero también puede
   introducir errores sutiles (sintaxis Kotlin mezclada con Groovy,
   plugins obsoletos). Lección: **revisar siempre, especialmente en
   capas que no compila el `flutter analyze` (Gradle, Edge Functions
   Deno)**.
4. **Honestidad documental supera el pulido visual.** Declarar "AA
   parcial" es mejor que reclamar "AA pleno" sin pase de lector — el
   tribunal valora rigor, no marketing.

---

## 9. Conclusión

El proyecto cumple los objetivos planteados en F0, está documentado con
mapeo explícito a los entregables de la guía TFG, y mantiene un plan
vivo para llevar el producto desde "TFG aprobado" hasta "producción
real". La trayectoria de progreso es medible (148 → 175 tests, F13 0/12
→ 5/12, modelo de usuario unificado, paginación 4 → 11/11, SEC2
cerrado, AGENTS saneada). Los próximos pasos están priorizados en
`docs/PLAN_ACCION_REMEDIACION.md` y `docs/PENDIENTE_PARA_CERRAR.md`.
