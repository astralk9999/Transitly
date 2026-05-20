# Propuestas Futuras — Transitly

> Cajón de ideas, mejoras pospuestas y propuestas que surgen durante el desarrollo.
> Cada entrada con: fecha, autor, prioridad (P0-P3), esfuerzo (S/M/L), tag de fase si aplica.
>
> **Convención:** no se borran entradas. Las implementadas se marcan ✅ con el commit.
> Lo pospuesto se deja abierto con su tag de fase actualizado.

---

## Features

| Fecha | Idea | Prioridad | Esfuerzo | Tag | Estado |
|-------|------|-----------|----------|-----|--------|
| 2026-05-14 | `SuggestionContributeScreen` — pantalla para enriquecer sugerencias existentes con más paradas, horas, notas | P2 | M | [F19] | ⏸️ pospuesto |
| 2026-05-14 | `FeedbackMessageModel` — threading de mensajes entre gestor y usuario sobre un feedback | P2 | M | [F16] | ⏸️ pospuesto |
| 2026-05-14 | Adjuntos (fotos) en incidentes y feedback → Storage bucket `report-attachments` | P1 | M | [F17] | ⏸️ pospuesto |
| 2026-05-14 | OAuth Google sign-in en Android e iOS (pendiente de F4) | P1 | M | [F22] | ⏸️ pospuesto |
| 2026-05-14 | `ManageUsersScreen` para admin: buscar usuarios, cambiar rol, banear, forzar logout | P1 | L | [F16] | ⏸️ pospuesto (F5 parcial) |
| 2026-05-14 | `DriverHistoryScreen` — historial de viajes del conductor | P2 | M | [F19] | ⏸️ pospuesto |
| 2026-05-14 | `DriverStatsScreen` — estadísticas de conductor (viajes, puntualidad, reputación) | P2 | M | [F19] | ⏸️ pospuesto |
| 2026-05-14 | `FilterPresetsScreen` — filtros guardables y compartibles | P2 | M | [F19] | ⏸️ pospuesto |
| 2026-05-14 | Extraer `_OptionCard` duplicado (admin_screen.dart + operator_dashboard_screen.dart) a `shared/widgets/admin_option_card.dart` y unificar implementación (Pressable vs InkWell) | P1 | S | [F16] | ⏸️ abierto |
| 2026-05-14 | Cobertura ARB para `features/admin/` y `features/operator_admin/` (~45 strings hardcodeados en español — 10 en admin_screen, 6 en operator_dashboard, ~15 en drivers_screen, ~14 en invitation_codes_screen) | P1 | M | [F16] | ⏸️ abierto |

---

## Mejoras UX/UI

| Fecha | Idea | Prioridad | Esfuerzo | Tag | Estado |
|-------|------|-----------|----------|-----|--------|
| 2026-05-14 | UI para dead letter queue — listar acciones fallidas (>10 reintentos) y permitir reintento manual | P1 | S | [F22] | ⏸️ abierto |
| 2026-05-14 | Indicador visual de calidad de señal GPS (ya existe `gpsAccuracyProvider`, falta widget) | P2 | S | [F19] | ⏸️ abierto |
| 2026-05-14 | Pull-to-refresh en `MyContributionsScreen` (ya tiene botón refresh, falta gesture) | P3 | S | — | ⏸️ abierto |
| 2026-05-14 | Animación de transición al votar en `SuggestionDetailScreen` (contador animado) | P3 | S | [F17] | ⏸️ abierto |
| 2026-05-14 | Feedback háptico al enviar formularios (incidente, feedback, sugerencia) | P3 | S | [F18] | ⏸️ abierto |

---

## Técnico / Infra

| Fecha | Idea | Prioridad | Esfuerzo | Tag | Estado |
|-------|------|-----------|----------|-----|--------|
| 2026-05-14 | Bug `_error = 'e'` en admin_users_screen.dart:99 — asignar `e.toString()` en lugar del literal `'e'` | P0 | S | [F16] | ⏸️ abierto |
| 2026-05-14 | Añadir `AppLogger.warn` a 10 `catch (_)` silenciosos en `features/` (auth, driver_dashboard, map_filter_controller, profile_about_section) | P1 | S | [F16] | ⏸️ abierto |
| 2026-05-14 | Añadir `.limit(50)` a queries Supabase directas sin paginación en `admin_users_screen`, `drivers_screen`, `invitation_codes_screen`, `driver_dashboard_screen` | P1 | M | [F16] | ⏸️ abierto |
| 2026-05-14 | Edge Function GTFS-realtime — feed real cada 30s metiendo posiciones en `bus_positions` | P0 | L | [F13] | ⏸️ pospuesto (F13 parcial) |
| 2026-05-14 | Rate-limiting cliente + servidor para contribuciones (evitar spam) | P1 | M | [F22] | ⏸️ pospuesto |
| 2026-05-14 | Detección de duplicados en sugerencias/feedback (sugerir "¿ya existe?") | P1 | M | [F22] | ⏸️ pospuesto |
| 2026-05-14 | Migrar `live_recorder_draft` de `shared_preferences` a Hive con cifrado AES | P1 | S | [SIN ASIGNAR] | ⏸️ abierto |
| 2026-05-14 | Cifrado AES en trazas GPS almacenadas en Hive (`editor_drafts`) | P1 | S | [F25] | ⏸️ abierto |
| 2026-05-14 | Pausar timers de `MockRealtimeService` en `AppLifecycleState.paused` (wakelocks en release) | P1 | S | [F26] | ⏸️ abierto |
| 2026-05-14 | CI con GitHub Actions: `flutter analyze` + `flutter test` + `build_runner --verify-only` | P1 | M | [F26] | ⏸️ abierto |
| 2026-05-14 | Bundle `google_fonts` en assets para evitar fetch en runtime y habilitar golden tests | P1 | M | [F17] [F26] | ⏸️ abierto |
| 2026-05-14 | Smoke test real end-to-end de la cola offline (tirar red → encolar → restaurar → drenar) | P1 | M | [F22] | ⏸️ abierto |
| 2026-05-14 | Pre-commit hook: `flutter analyze` + `dart format --check` | P2 | S | [F26] | ⏸️ abierto |
| 2026-05-14 | `MockRealtimeService` reemplazar por Supabase Realtime en `bus_positions` (ya existe canal) | P2 | M | [F21] | ⏸️ abierto |
| 2026-05-14 | Minificar `assets/mock/comujesa_data.json` (~1.2 MB) o eliminar del bundle (ya en Supabase) | P2 | S | [F26] | ⏸️ abierto |

---

## Plataformas

| Fecha | Idea | Prioridad | Esfuerzo | Tag | Estado |
|-------|------|-----------|----------|-----|--------|
| 2026-05-14 | Web híbrida Astro + Flutter Web islands (landing + mapa embebido) | P2 | L | [F23] | ⏸️ sin empezar |
| 2026-05-14 | Widgets nativos: Android home widget (próximas salidas), iOS Live Activity | P2 | L | [F24] | ⏸️ sin empezar |
| 2026-05-14 | Wearable nivel 1: notificaciones en reloj (parada cercana, bus aproximándose) | P3 | M | [F27] | ⏸️ sin empezar |

---

## Community / Growth

| Fecha | Idea | Prioridad | Esfuerzo | Tag | Estado |
|-------|------|-----------|----------|-----|--------|
| 2026-05-14 | Sistema de reputación visible con rangos e insignias (más allá del `ReputationBadge` actual) | P1 | L | [F19] | ⏸️ sin empezar |
| 2026-05-14 | Notificaciones push: "Tu sugerencia fue aceptada", "Nuevo comentario en tu reporte" | P1 | M | [F21] | ⏸️ sin empezar |
| 2026-05-14 | Gamificación ligera: rachas, logros por contribuciones (modelos `Achievement` ya existen) | P2 | L | [F19] | ⏸️ sin empezar |
| 2026-05-14 | Compartir ruta como imagen (captura del mapa + datos) para redes sociales | P3 | M | [F23] | ⏸️ abierto |
| 2026-05-14 | Onboarding interactivo para nuevos usuarios (3 pantallas con ilustraciones) | P2 | M | [F17] | ⏸️ sin empezar |

---

## Apariencia (F17)

| Fecha | Idea | Prioridad | Esfuerzo | Estado |
|-------|------|-----------|----------|--------|
| 2026-05-14 | Selector de paleta de colores (5-6 temas predefinidos + custom) | P1 | M | ⏸️ sin empezar |
| 2026-05-14 | Fondos dinámicos configurables (más allá de `SmokeBackground`) | P2 | M | ⏸️ sin empezar |
| 2026-05-14 | Modo alto contraste | P2 | S | ⏸️ sin empezar |
| 2026-05-14 | Fuente alternativa para dislexia (`dyslexiaFontEnabled` ya existe en `UserPreferences`) | P2 | S | ⏸️ sin empezar |

---

## GDPR / Privacidad (F25)

| Fecha | Idea | Prioridad | Esfuerzo | Estado |
|-------|------|-----------|----------|--------|
| 2026-05-14 | Pantalla de consentimientos (analítica, crash reporting, marketing) | P0 | M | ⏸️ sin empezar |
| 2026-05-14 | Exportación de datos del usuario (tabla `data_exports` ya existe) | P1 | M | ⏸️ sin empezar |
| 2026-05-14 | Solicitud de borrado de cuenta (tabla `data_deletion_requests` ya existe) | P1 | M | ⏸️ sin empezar |
| 2026-05-14 | Pantalla "Mis datos" — listar trazas GPS locales y permitir borrado manual | P1 | M | ⏸️ sin empezar |

---

## Notas

- Las entradas con tag `[F<n>]` están mapeadas a una fase del plan v2 (`docs/historico/PLAN_TRANSITLY_V2.md`).
- Las entradas `[SIN ASIGNAR]` no tienen fase — asignar antes de implementar.
- Prioridad: **P0** = bloqueante para release, **P1** = importante, **P2** = deseable, **P3** = nice-to-have.
- Esfuerzo: **S** = <2h, **M** = medio día, **L** = 1-2 días.

**Última actualización:** 2026-05-14 · post F15.
