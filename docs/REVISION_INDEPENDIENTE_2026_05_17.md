# Transitly Flutter Project — Revisión Independiente

**Proyecto:** Transitly — Transporte público en tiempo real
**Revisor:** Sistema multiagente (Review Agent independiente)
**Fecha:** 17 de mayo de 2026
**Rama:** `master` (commit `bfa3b89`)

---

## Resumen Ejecutivo

| Métrica | Valor | Estado |
|---------|-------|--------|
| `flutter analyze` | 6 info, 0 errors, 0 warnings | 🟡 Limpio |
| `flutter test` | **143 passed, 0 failed** | 🟢 Verde |
| `.dart` files (lib) | 320 | — |
| Test files | 26 (~8% ratio) | 🟡 Bajo |
| `print()` violaciones | **0** | 🟢 Cumple |
| `.env.example` ↔ `env.dart` | 7/7 claves sincronizadas | 🟢 Correcto |
| Commits esta sesión | 112 | 🟢 Alta velocidad |

---

## Issues CRÍTICOS (P0)

### C1. 44+ strings hardcodeados en español en auth screens

Los siguientes archivos de `lib/features/auth/` contienen texto en español hardcodeado sin usar `AppLocalizations`:

| Archivo | Strings ES | Usa l10n | Usa AppLogger |
|---------|-----------|----------|---------------|
| `signin_screen.dart` | 12 | No | No |
| `signup_screen.dart` | 8 | No | No |
| `recover_password_screen.dart` | 7 | No | No |
| `activate_driver_screen.dart` | 8 | No | No |
| `magic_link_screen.dart` | 5 | No | No |
| `email_verify_pending_screen.dart` | 4 | No | No |

**Impacto:** Los usuarios en inglés ven toda la experiencia de auth en español. Viola AGENTS.md §i18n.

### C2. 13 bloques `catch (_)` silenciosos

AGENTS.md: *"Nada de `catch (_) {}` silencioso. Si se ignora → `logger.warn('contexto', e)`."*

| Archivo | Línea | Contexto |
|---------|-------|----------|
| `data/push/firebase_setup.dart` | 11 | Firebase init falla en silencio |
| `features/auth/signin_screen.dart` | 49, 182 | Sign-in + Google sign-in |
| `features/auth/signup_screen.dart` | 52 | Sign-up |
| `features/auth/recover_password_screen.dart` | 50 | Recuperación |
| `features/auth/magic_link_screen.dart` | 49 | Magic link |
| `features/auth/email_verify_pending_screen.dart` | 36 | Verificación email |
| `features/driver/driver_dashboard_screen.dart` | 85, 105 | Driver |
| `shared/providers/theme_notifier.dart` | 428 | Tema |
| `shared/widgets/smoke_background.dart` | 78 | Shader |
| `data/operator/local/operator_mock_repository.dart` | 27 | Mock asset |
| `features/home/widgets/profile_about_section.dart` | 96 | Versión check |

### C3. Auth repository ubicado en `features/auth/` en vez de `data/auth/`

AGENTS.md: *"data/ no depende de features/"*. Todos los demás repositorios siguen `lib/data/<entidad>/` (operator, route, stop, incident, etc.). Auth es el único que rompe este patrón.

**Archivos a mover:** `auth_repository.dart`, `auth_repository_supabase.dart` → `lib/data/auth/`

---

## Issues IMPORTANTES (P1)

### I1. Dos pantallas exceden masivamente las 300 líneas

| Archivo | Líneas | Exceso |
|---------|--------|--------|
| `appearance_screen.dart` | **1,171** | 871 (3.9x) |
| `manager_inbox_screen.dart` | **785** | 485 (2.6x) |

### I2. Cobertura de tests baja (26 tests / 320 archivos)

Áreas sin cobertura: auth (0), route detail (0), map (0), driver editor (0), offline (0), notifications (0), reputation (0), privacy (0).

### I3. 67 paquetes desactualizados

Principales: `riverpod` 2.6→3.3, `go_router` 14→17, `sentry_flutter` 8→9, `freezed` 2→3, `google_fonts` 6→8.

---

## Issues MENORES (P2-P3)

### M1. 6 lint warnings info-level

| Archivo | Issue |
|---------|-------|
| `driver_dashboard_screen.dart:253` | prefer_conditional_assignment |
| `route_officialize_modal.dart:176-185` | 4 prefer_const_constructors |
| `accessibility_settings_screen_test.dart:14` | no_leading_underscores |

### M2. `app_router.dart` (514 líneas) candidato a split

### M3. Test warnings no críticos (`[WARN][StaggerList] reduceMotion`)

---

## Hallazgos POSITIVOS

1. ✅ **0 `print()` en `lib/`** — `avoid_print: true` estrictamente cumplido
2. ✅ **0 TODO/FIXME/HACK** — código limpio de marcadores de deuda
3. ✅ **143 tests verdes** — sin regresiones
4. ✅ **`.env.example` ↔ `env.dart`** perfectamente sincronizados (7/7 claves)
5. ✅ **0 unused imports** — código limpio
6. ✅ **Patrón canónico de repositorio** consistente en 12 entidades
7. ✅ **Cola offline (F3.3) smoke tests** pasan (enqueue, drain, retry)
8. ✅ **112 commits esta sesión** — conventional commits, alta velocidad
9. ✅ **Separación limpia de capas** — core (1,714 lines), data (6,928), features (21,557), shared (11,886)

---

## Plan de Acción Priorizado

| Prioridad | ID | Acción | Esfuerzo |
|-----------|-----|--------|----------|
| **P0** | C1 | Migrar 44+ strings auth a ARB (ES+EN) + `flutter gen-l10n` | 2h |
| **P0** | C2 | Reemplazar 13 `catch (_)` con `AppLogger.warn` | 30min |
| **P1** | C3 | Migrar auth_repository a `lib/data/auth/` | 1h |
| **P1** | I1 | Descomponer `appearance_screen.dart` (1,171L) | 1h |
| **P1** | I2 | Añadir tests auth (mínimo 5 tests) | 1h |
| **P2** | M1 | Corregir 6 lint warnings | 15min |
| **P3** | M2 | Split `app_router.dart` redirect logic | 30min |

---

**Firma:** Review Agent independiente · Sistema multiagente Transitly
**Hash del commit auditado:** `bfa3b89`
**Próxima revisión programada:** Tras resolver P0
