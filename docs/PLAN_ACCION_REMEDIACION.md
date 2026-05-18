# Plan de Acción Remedial — Transitly

**Origen:** `docs/REVISION_INDEPENDIENTE_2026_05_17.md`
**Fecha:** 17-may-2026
**Estado P0+P1:** ✅ Resuelto (commit `5077099`)

---

## Issues pendientes (P2-P3)

| ID | Severidad | Descripción | Esfuerzo |
|----|-----------|-------------|----------|
| **I3** | P2 | 67 paquetes desactualizados. Principales: riverpod 2.6→3.3, freezed 2.5→3.2, go_router 14→17, google_fonts 6→8, sentry_flutter 8→9 | L |
| **M2** | P2 | Split `app_router.dart` (514 líneas). Separar redirects en `redirect_guards.dart` | S |
| **M3** | P3 | Suprimir `[WARN][StaggerList] reduceMotion unavailable` en tests | S |
| **M4** | P2-P3 | Pantallas placeholder con `'PANTALLA: ...'` hardcodeado: `filter_presets_screen.dart`, `driver_stats_screen.dart`, `driver_history_screen.dart`, `planned_trips_screen.dart`, `ai_schedule_import.dart`, `suggestion_contribute_screen.dart` | M |
| **R1** | P2 | `appearance_screen.dart` recién descompuesto: verificar que `flutter analyze` sigue a 0 | S |

---

## Fases del plan

### Fase R1 — Paquetes críticos + lint post-split
1. Actualizar riverpod (2→3), freezed (2→3), go_router (14→17)
2. Regenerar código: `tool/build.sh`
3. Verificar 0 issues + tests pasan

### Fase R2 — Router + placeholders + tests
1. Split `app_router.dart` redirect logic → `redirect_guards.dart`
2. Eliminar placeholders `'PANTALLA: ...'` y reemplazar con EmptyState + l10n
3. Suprimir warning StaggerList en tests
4. Verificar 0 issues + tests pasan

### Fase R3 — Paquetes restantes + verificación final
1. Actualizar resto de paquetes no-breaking (sentry_flutter, google_fonts, etc.)
2. `flutter analyze` + `flutter test` final
3. Commit + push

---

## Ejecución

Cada fase se ejecuta con el pipeline multiagente:
```
Queen → Developer + Innovation → Review → Git → Docs+Tracker
```
