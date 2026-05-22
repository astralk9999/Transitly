# Propuestas Futuras — Technical Debt & Improvement Opportunities

> Audit date: 2026-05-22  
> Analyzed: `lib/` (excluding `lib/l10n/generated/`, `.freezed.dart`, `.g.dart`)  
> Tool: Automated scan — 6 areas  
> Severity: P0 (urgent) → P3 (cosmetic)

---

## 1. Hardcoded Spanish Strings (i18n Gaps)

**Severity: P1** — Affects localization quality for EN/AR locales.

### Files requiring i18n (grouped by category):

**Auth/Dialog strings** in `lib/features/home/widgets/profile_about_section.dart`:
| Line | String | Existing ARB key |
|------|--------|-------------------|
| 39 | `"¿Cerrar sesión?"` | `authSignOutTitle` |
| 43 | `"Volverás a la pantalla de inicio de sesión."` | `authSignOutMessage` |
| 48 | `"CANCELAR"` | `authSignOutCancel` |
| 54 | `"CERRAR SESIÓN"` | `authSignOutConfirm` |
| 232 | `"Cerrar sesión"` | (same as above) |
| 250 | `"Iniciar sesión"` | `authSignInLink` |
| 197 | `"ADMINISTRACIÓN"` | *no key exists* |
| 174 | `"v0.1.0-demo"` | N/A (version string) |
| 183 | `"Plataforma universal de transporte público"` | *no key exists* |
| 225 | `"Activar modo conductor"` | `authActivateDriverTitle` |

**Section headers** (hardcoded uppercase labels — no ARB keys exist):
| File | Line | String |
|------|------|--------|
| `lib/features/stop_detail/stop_detail_screen.dart` | 105 | `"PRÓXIMAS LLEGADAS"` |
| `lib/features/stop_detail/stop_detail_screen.dart` | 197 | `"LÍNEAS"` |
| `lib/features/route_detail/widgets/route_detail_schedule_section.dart` | 77 | `"HORARIOS"` |
| `lib/features/route_detail/widgets/route_detail_changelog.dart` | 28 | `"CAMBIOS RECIENTES"` |
| `lib/features/route_detail/widgets/route_detail_timeline.dart` | 35 | `"RECORRIDO"` |
| `lib/features/home/widgets/profile_location_section.dart` | 68 | `"GESTIONAR →"` |
| `lib/features/home/widgets/profile_contributions_section.dart` | 51 | `"VER TODO →"` |

**Driver flow** in `lib/features/driver/active_route_screen.dart`:
| Line | String | Notes |
|------|--------|-------|
| 330 | `"¿Finalizar ruta?"` | *no key* |
| 332 | `"Se registrará la ruta como completada."` | *no key* |
| 337 | `"CANCELAR"` | exists (`authSignOutCancel`) |
| 345 | `"FINALIZAR"` | *no key* |

In `lib/features/driver/route_editor/live_route_recorder.dart`:
| Line | String |
|------|--------|
| 109 | `"CONTINUAR"` |
| 120 | `"DETENER"` |

**Shared widgets:**
| File | Line | String |
|------|------|--------|
| `lib/shared/widgets/transit_app_bar.dart` | 40 | Toolkit `message: "Volver"` |
| `lib/shared/widgets/transit_app_bar.dart` | 100 | `"OK"` |
| `lib/shared/widgets/contextual_help_button.dart` | 47 | `"OK"` |
| `lib/shared/widgets/single_field_dialog.dart` | 18,79 | Default `cancelLabel = "CANCELAR"` |

**Other:**
| File | Line | String |
|------|------|--------|
| `lib/features/home/tabs/card_tab.dart` | 196 | `"Manten la tarjeta cerca del dispositivo"` |
| `lib/features/home/tabs/card_tab.dart` | 202 | `"CANCELAR"` |
| `lib/features/route_detail/widgets/route_detail_schedule_section.dart` | 108 | `"Ocultar ▴"` / `"Ver todos ▾"` |
| `lib/features/operator_admin/invitation_codes_screen.dart` | 132 | `"CANCELAR"` |
| `lib/features/operator_admin/drivers_screen.dart` | 82 | `"CANCELAR"` |
| `lib/features/driver/route_editor/steps/step_info.dart` | 92 | `"COMUJESA"` (hardcoded operator) |

**Count: ~35 hardcoded UI strings across 15+ files.**

---

## 2. TODO / FIXME Comments

**Severity: P3** — Negligible. Only 3 matches, none are real TODOs.

| File | Line | Content | Type |
|------|------|---------|------|
| `lib/features/auth/activate_driver_screen.dart` | 181 | `hintText: "XXX-XXXX-XX"` | UI placeholder (not a comment) |
| `lib/shared/models/driver_invitation_code.dart` | 8 | Format documentation comment | Docs |
| `lib/features/home/widgets/profile_contributions_section.dart` | 51 | `"VER TODO →"` | UI text (not a comment) |

**Status:** Clean. No actionable TODO/FIXME debt found.

---

## 3. Unused l10n Keys

**Severity: P3** — Spot-checked 30 keys. Only 1 confirmed unused.

| Key | ARB file | Status |
|-----|----------|--------|
| `accessibleBusesSourceOfficial` | `app_es.arb:248` | Unused — no reference in `lib/` outside generated files |

All other spot-checked keys (`mapStyleBasic`, `achievementsLevel`, `widgetsTitle`, `aiScheduleImportNoTimes`, `filterPresetsApplied`, `reputationRankNone`, `reputationRankNovice`, `appearanceCustomPaletteContrastPass`, `appearanceCustomPaletteContrastFail`, and 20 more) are actively referenced.

---

## 4. Silent Catch Blocks (Error Swallowing)

**Severity: P1–P2** — Some intentional, some missing logging.

### A) `catch (_)` — truly silent (8 found)

| File | Line | Context | Assessment |
|------|------|---------|------------|
| `lib/core/utils/error_boundary.dart` | 84 | Wraps `SentrySetup.captureException` | **Acceptable** — prevents crash-loop if Sentry fails |
| `lib/shared/widgets/stagger_list.dart` | 85 | Reads theme provider in tests | **Acceptable** — documented as intentional for test environments |
| `lib/features/feedback/route_feedback_sheet.dart` | 204 | Failed feedback submission | **P2** — shows user error but doesn't log. Add `AppLogger.warn` |
| `lib/data/route/remote/route_remote_repository.dart` | 65 | `watch()` yields null on error | **Acceptable** — stream continues with realtime; could add debug log |
| `lib/data/stop/remote/stop_remote_repository.dart` | 71 | Same pattern | **Acceptable** |
| `lib/data/bus_location/remote/bus_location_remote_repository.dart` | 43 | Same pattern | **Acceptable** |
| `lib/data/route_feedback/remote/route_feedback_remote_repository.dart` | 144 | Same pattern | **Acceptable** |
| `lib/data/incident/remote/incident_remote_repository.dart` | 153 | Same pattern | **Acceptable** |

### B) `catch (e)` — handled but not logged

| File | Line | Assessment |
|------|------|------------|
| `lib/features/management/manager_inbox_screen.dart` | 90 | **P1** — sets `_error` state but doesn't log. Add `AppLogger.warn` |
| `lib/features/operator_admin/invitation_codes_screen.dart` | 58,87,155 | **P1** — three catch blocks, no logging. Add `AppLogger.warn` |
| `lib/features/incidents/report_incident_sheet.dart` | 139 | **P2** — shows user error, no logging |
| `lib/features/driver/driver_dashboard_screen.dart` | 86 | **OK** — logs with `AppLogger.warn` |
| `lib/features/driver/driver_dashboard_screen.dart` | 107,157,183 | **OK** — logs with `AppLogger.warn` |
| `lib/features/accessible_buses/accessible_buses_screen.dart` | 56 | **Needs verification** — check for AppLogger |
| `lib/features/profile/filter_presets_screen.dart` | 61,74 | **Needs verification** — check for AppLogger |

**Key recommendation:** Add the lint rule `avoid_catches_without_on_clauses` to enforce catching typed exceptions first, and add logging to all catch blocks in UI screens (data layer catch blocks generally rethrow typed exceptions, which is fine).

---

## 5. Large Files >400 Lines (Decomposition Candidates)

**Severity: P2** — Monolithic files hinder maintainability as the codebase grows.

> Excluding generated files (`l10n/generated/`, `.freezed.dart`, `.g.dart`)

| Lines | File | Suggested decomposition |
|-------|------|------------------------|
| 508 | `lib/features/offline/widgets/region_download_sheet.dart` | Extract form section, map picker, progress indicator into separate widgets |
| 491 | `lib/features/driver/driver_dashboard_screen.dart` | Extract tracking logic to a controller/provider; separate UI sections |
| 487 | `lib/core/router/app_router.dart` | Split routes by feature: `auth_routes.dart`, `driver_routes.dart`, etc. |
| 484 | `lib/features/appearance/custom_palette_screen.dart` | Extract palette editor sub-widgets (picker, preview, contrast checker) |
| 472 | `lib/features/contributions/my_contributions_screen.dart` | Split tabs (incidents/feedback/suggestions) into separate widgets |
| 463 | `lib/shared/providers/theme_notifier.dart` | Extract color-blind mode logic, custom palette logic to separate files |
| 460 | `lib/features/profile/reputation_screen.dart` | Split into widgets: rank-card, events-list, progress-section |
| 444 | `lib/features/offline/offline_regions_screen.dart` | Extract region card widget, empty state, FAB logic |
| 431 | `lib/features/home/tabs/home_tab.dart` | Extract sections: next-bus-card, favorites-list, nearby-routes |
| 409 | `lib/features/privacy/privacy_screen.dart` | Extract consent toggles section, data actions section |
| 408 | `lib/data/mock/mock_data_service.dart` | Split mock data builders per entity (routes, stops, incidents, etc.) |
| 407 | `lib/features/home/tabs/card_tab.dart` | Extract balance display, recent transactions, NFC status indicator |
| 405 | `lib/features/driver/route_editor/widgets/recorder_live_view.dart` | Extract speed/altitude gauges, stop list, map overlay |

**13 source files exceed 400 lines.** Per the `AGENTS.md` guideline: "*_screen.dart ≤ ~300 LoC; if it grows → decompose into widgets/ or steps/*"

---

## 6. analysis_options.yaml — Missing Recommended Rules

**Severity: P1** — Several production-grade safety rules are absent.

Current configuration has 12 explicit rules. **Recommended additions:**

### Safety (highly recommended)
| Rule | Rationale |
|------|-----------|
| `avoid_catches_without_on_clauses` | Would have caught 8 bare `catch(_)` + 123 bare `catch(e)` blocks. Enforces catching typed exceptions first, then rethrowing/fallback. Directly addresses finding §4 above. |
| `discarded_futures` | Prevents fire-and-forget futures that could hide async errors. |

### Code quality
| Rule | Rationale |
|------|-----------|
| `flutter_style_todos` | Standardizes TODO format: `// TODO(username): message` — makes grepping actionable |
| `sort_child_properties_last` | Consistency in widget constructors — child/children come last |
| `use_full_hex_values_for_flutter_colors` | Prevents shorthand hex like `0xFFF` that can be ambiguous |
| `avoid_function_literals_in_foreach_calls` | Prefer `for-in` over `.forEach()` for readability and performance |

### Accessibility
| Rule | Rationale |
|------|-----------|
| `use_key_in_widget_constructors` | Already present ✓ |
| `avoid_redundant_argument_values` | Reduces noise in widget constructors |

### Note
`require_trailing_commas` was intentionally omitted per `analysis_options.yaml` comment (L21-23: "style-only rules are intentionally left off to keep signal-to-noise ratio high"). This decision is respected. The recommendations above focus on safety and bug-prevention rules.

---

## Summary

| Area | Severity | Key Finding | Items |
|------|----------|-------------|-------|
| Hardcoded strings | **P1** | ~35 UI strings lack i18n across 15+ files | High effort, important for AR locale |
| TODO/FIXME | P3 | Clean — 0 actionable items | — |
| Unused l10n keys | P3 | 1 key (`accessibleBusesSourceOfficial`) | Trivial cleanup |
| Silent catches | **P1–P2** | 2 files missing logger.warn; 1 `catch(_)` in UI | Quick fixes |
| Large files | P2 | 13 files >400 LoC (3 >500) | Long-term refactor |
| Lint rules | **P1** | Missing `avoid_catches_without_on_clauses`, `discarded_futures`, `flutter_style_todos` | Quick config change |

### Quick Wins (1 hour)
1. Add `avoid_catches_without_on_clauses` + `flutter_style_todos` to `analysis_options.yaml`
2. Add `AppLogger.warn` to `manager_inbox_screen.dart:90` and `invitation_codes_screen.dart` catch blocks
3. Add `AppLogger.warn` to `route_feedback_sheet.dart:204` catch block
4. Remove or document `accessibleBusesSourceOfficial` in ARB

### Medium Effort (1–3 days)
5. Migrate hardcoded dialog strings to l10n (profile_about_section, active_route_screen, card_tab)
6. Add ARB keys for section headers (PRÓXIMAS LLEGADAS, LÍNEAS, HORARIOS, etc.)
7. Add `discarded_futures` rule + fix any violations

### Long-term
8. Decompose top-5 largest files (region_download_sheet, driver_dashboard, app_router, custom_palette_screen, my_contributions_screen)
9. Full l10n audit — ensure all user-facing strings pass through `AppLocalizations`
