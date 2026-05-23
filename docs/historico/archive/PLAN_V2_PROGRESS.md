# Plan v2 Progress — Transitly

> **Generated:** 2026-05-22 (final wrap-up)  
> **Source:** `docs/historico/PLAN_TRANSITLY_V2.md`  
> **Status:** 28/28 fases completadas (100 %)

---

## Progress Table

| # | Fase | Bloque | Objetivo | Estado |
|---|------|--------|----------|:------:|
| F0 | Auditoría in situ | I — Cimientos | Mapa real del código + inventario datos + PENDIENTES | ✅ |
| F0.5 | Higiene previa al backend | I — Cimientos | Cerrar items S del informe (routing, wiring, calidad) | ✅ |
| F1 | Migración selectiva a freezed | I — Cimientos | 13 modelos críticos → @freezed + 7 modelos nuevos | ✅ |
| F2 | Backend Supabase | I — Cimientos | Conexión, esquema 001_init.sql, RLS, storage, funciones | ✅ |
| F3 | Repositorios + caché Hive | I — Cimientos | Patrón Repository 5-archivos, Hive adapters, cache | ✅ |
| F4 | Auth | II — Identidad | Sign in/up, reset password, sesión, guest mode | ✅ |
| F5 | Roles tipados | II — Identidad | user_role enum, RLS per-role, profile→role binding | ✅ |
| F6 | Códigos de conductor | II — Identidad | Invitation codes, driver_assignments, claim flow | ✅ |
| F7 | Importador GTFS | III — Datos a escala | Edge Function import_gtfs, parseo, upsert masivo | ✅ |
| F8 | Detección geográfica + lazy | III — Datos a escala | nearby_operators, city picker, lazy loading geo | ✅ |
| F9 | Filtros + revisión | IV — Experiencia core | Filtros de mapa funcionales, revisión pendientes | ✅ |
| F10 | Editor manual de rutas | IV — Experiencia core | Route editor wizard, steps, post-recording | ✅ |
| F11 | LiveRecorder GPS real | IV — Experiencia core | GPS tracking, trace recording, session persistence | ✅ |
| F12 | Compartir + oficializar | IV — Experiencia core | Route shares, public links, promote_to_official | ✅ |
| F13 | GTFS-Realtime + estimador | V — Ojos del bus | Realtime bus positions, estimador, etiquetas de origen | ✅ |
| F14 | Driver en vivo | V — Ojos del bus | Driver dashboard, active route, live position push | ✅ |
| F15 | Contribuciones consolidadas | VI — Comunidad | Feedback, suggestions, incidents unified flow | ✅ |
| F16 | Panel admin | VI — Comunidad | Manager inbox, operator admin, moderation actions | ✅ |
| F17 | Apariencia | VII — Pulido visual | Theme system, palettes, custom colors, backgrounds | ✅ |
| F18 | Accesibilidad | VII — Pulido visual | Semantics→l10n, Pressable 48dp, textScaler, daltonism | ✅ |
| F19 | Reputación visible | VII — Pulido visual | Reputation scores, levels, badges, achievements UI | ✅ |
| F20 | Tiles MapTiler + offline | VIII — Infraestructura | Map tiles, offline regions, region download | ✅ |
| F21 | FCM + in-app + wearable 0 | VIII — Infraestructura | Push notifications, in-app notifications, FCM setup | ✅ |
| F22 | Sentry + PostHog | VIII — Infraestructura | Crash reporting, analytics, consent-gating | ✅ |
| F23 | Web híbrida | IX — Plataformas extra | Astro + Flutter Web islands | ✅ |
| F24 | Widgets nativos móvil | IX — Plataformas extra | Platform-specific widgets, haptics | ✅ |
| F25 | Privacidad + GDPR/LOPD | X — Cierre | Privacy screen, consents, data export, deletion | ✅ |
| F26 | QA, performance, TFG, beta | X — Cierre | Tests, coverage, fonts local, APK release, CI | ✅ |
| F27 | Wearable nivel 1 (opcional) | X — Cierre | Wear OS companion app scaffold | ✅ |

---

## Block Summary

| Bloque | Fases | Completado |
|--------|-------|:----------:|
| I — Cimientos | F0, F0.5, F1, F2, F3 | 5/5 (100 %) |
| II — Identidad | F4, F5, F6 | 3/3 (100 %) |
| III — Datos a escala | F7, F8 | 2/2 (100 %) |
| IV — Experiencia core | F9, F10, F11, F12 | 4/4 (100 %) |
| V — Ojos del bus | F13, F14 | 2/2 (100 %) |
| VI — Comunidad y moderación | F15, F16 | 2/2 (100 %) |
| VII — Pulido visual y accesibilidad | F17, F18, F19 | 3/3 (100 %) |
| VIII — Infraestructura de producto | F20, F21, F22 | 3/3 (100 %) |
| IX — Plataformas extra | F23, F24 | 2/2 (100 %) |
| X — Cierre | F25, F26, F27 | 3/3 (100 %) |

---

## Post-Plan v2: Mega-plan de Refinamiento (190 items)

| Bloque | Total | ✅ | ⏳ | % |
|---|---|---|---|---|
| P0 — Defensa inminente | 7 | 6 | 1 [EXT] | 85.7 |
| R — Refactor | 4 | 4 | 0 | 100 |
| P1 — Calidad/a11y | 11 | 10 | 1 | 90.9 |
| P2 — Núcleo | 7 | 4 | 3 | 57.1 |
| P3 — Deuda | 8 | 4 | 4 | 50.0 |
| PROD — Producción | 10 | 4 | 6 | 40.0 |
| A11Y — WCAG | 10 | 5 | 5 | 50.0 |
| PRO-Snr — Senior | 18 | 17 | 1 | 94.4 |
| PRO-Rel — Stores | 33 | 14 | 19 | 42.4 |
| PRO-QA — Testing | 25 | 13 | 12 | 52.0 |
| PRO-A11Y — AAA | 23 | 15 | 8 | 65.2 |
| PRO-Ops — SRE | 34 | 16 | 18 | 47.1 |
| **TOTAL** | **190** | **112+** | **78−** | **58.9+** |

---

## Steps Executed (multi-agent batches)

| Metric | Count | % |
|--------|------:|--:|
| Steps planned | **80** | 100 |
| Steps executed | **55+** | **68.8+** |
| Remaining | ~25 | 31.2 |

> Steps = ítems accionables ejecutados por agentes en batches paralelos (4 agentes × 5 tandas = 20 invocaciones). Los 55+ steps cubren 112+ ítems del mega-plan.

---

## External Blockers (remaining)

| # | Blocker | Effort | Dependency |
|---|---------|:------:|------------|
| B1 | Keystore real (APK no publicable) | 15 min | User action |
| B2 | TalkBack/VoiceOver verification | ~1 day | Physical device |
| B3 | PAT rotation (Supabase) | 5 min | Supabase dashboard |
| B4 | Apple Developer enrollment | — | $99/year |
| B5 | AR Arabic translation (272 keys) | — | Native translator |
| B6 | Store submissions (Play/App Store) | — | Forms + assets |

---

## Verification Snapshot (2026-05-22)

```
commit:      65a1fed
analyze:     0 errors, 0 warnings, 22 info
test:        304 passed, 1 skipped
coverage:    24.30 %
migrations:  14 SQL files
edge fn:     4 directories
test files:  63 Dart files
doc files:   73 Markdown files
ARB keys:    846 (es template)
source:      315 Dart files (non-generated)
APK:         73.5 MB (release)
CI:          4 jobs verde
```

---

> **Next:** `docs/PENDIENTE_PARA_CERRAR.md` for the playbook to close remaining items.  
> **Master:** `docs/00_MAESTRO.md` for the source of truth.  
> **Operational plan:** `docs/MEGA_PLAN_REFINAMIENTO.md` for the 190-item roadmap.
