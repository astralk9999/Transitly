# Transitly · `nexto-stop-v2`

> Academic Flutter project (TFG) — a public-transit companion app built around
> **COMUJESA**, the urban bus operator of Jerez de la Frontera (Cádiz, Spain).

Transitly is a portfolio-grade transit companion: live(-ish) arrivals, a real
route catalogue, an NFC card reader for the *Consorcio de Transportes de
Andalucía* prepaid card, a route editor for drivers, community contributions,
and a polished motion / typography system.

The data layer is **mock-first with an optional Supabase backend**: COMUJESA
timetable/stop/line data ships as mock JSON (`assets/mock/comujesa_data.json`)
and is served by the mock repositories when there is no authenticated session;
when a Supabase session exists, the same repositories read/write the remote
backend. Telemetry (Sentry/PostHog), push (FCM) and the Astro web surface are
present but optional and consent/env-gated.

> **Honest scope note (read before evaluating).** This README previously
> claimed "no backend, no auth, no push". That is no longer true: phases
> F1–F27 added a full Supabase backend, auth, FCM push, telemetry, an Astro
> SSR site and native home widgets. See *Status* and *Architecture* below for
> the real picture. Real-time updates (F13) are **not** implemented yet — the
> `watch()` streams in `lib/data/*/remote/` emit an initial snapshot plus
> manual refresh, not live subscriptions.

---

## Status

The project tracks 28 incremental phases (**F0 → F27**); state lives in
`multiagent/state/project.json`. Development was assisted by an autonomous
multi-agent system (Queen / Developer / Review / Git / Documentation),
documented in `multiagent/ARCHITECTURE.md` and in the TFG memory
(`docs/tfg/03–05`).

Verified quality metrics (2026-05-15):

| Metric | Value |
|--------|-------|
| `flutter analyze` | **0 errors, 6 info** (const/conditional/underscore lints) |
| `flutter test` | **143 / 143 passing** |
| Line coverage (`coverage/lcov.info`) | **~23 %** (3 580 / 15 424 lines) — known debt |

> The previous "0 issues / 56 tests" line was stale. Coverage is low for the
> codebase size (~49 K LOC); raising it on critical modules (`bus_estimator`,
> offline sync, repositories) is tracked as technical debt.

---

## Architecture / Stack

- **Flutter** 3.9.2+ / **Dart** 3 (strict casts + strict raw types)
- **Riverpod** 2.6 (StateProviders, derived providers, `overrideWith` in tests)
- **go_router** 14.8 with `StatefulShellRoute` and per-route `redirect`
- **Supabase** (`supabase_flutter` 2.8) — auth, 16 SQL migrations, 2 Edge
  Functions; `domain/local/mock/remote` repository pattern per entity
- **Firebase / FCM** (`firebase_messaging`) — push, with graceful degradation
- **Sentry + PostHog** — crash reporting / analytics, consent-gated
- **flutter_map** 7.0 + `latlong2`; **MapTiler** + FMTC offline tile caching
- **nfc_manager** 3.5 over Mifare Classic (sector keys via `--dart-define`)
- **Astro** SSR marketing site + Flutter Web islands (`astro/`, `lib/web_entry/`)
- Native Android/iOS home widgets (`home_widget`, `workmanager`)
- **google_fonts** for IBM Plex Mono + DM Sans (runtime fetch; bundling = TODO F26)
- **flutter_localizations** + ARB generation (`flutter gen-l10n`)

---

## Getting started

```bash
cp .env.example .env       # fill SUPABASE_URL / SUPABASE_ANON_KEY (required to boot)
flutter pub get
flutter gen-l10n           # one-shot; generated files live in lib/l10n/generated
flutter run                # Android emulator or connected device
```

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are **required** (`lib/core/env.dart`
validates them and the app shows an env-error screen if missing). Telemetry
(`SENTRY_DSN`, `POSTHOG_API_KEY`) and `MAPTILER_API_KEY` are optional and
degrade silently. `.env` is gitignored and must never be committed.

### NFC (sensitive)

The default Mifare keys for the *Consorcio* card live in
`lib/data/nfc/nfc_card_service.dart`. They were reverse-engineered from the
public `saldotarjetas` Android app and are kept here for **academic** use
only. To override them at build time, pass:

```bash
flutter run \
  --dart-define=NFC_KEY_SECTOR0=<6-byte-hex> \
  --dart-define=NFC_KEY_SECTOR9=<6-byte-hex>
```

iOS additionally needs the entitlements declared in `ios/Runner/Info.plist`
(`NFCReaderUsageDescription` + `com.apple.developer.nfc.readersession.formats:
TAG`).

---

## Tests

```bash
flutter test                       # 143 tests
flutter test --coverage            # writes coverage/lcov.info (~23 % lines)
```

The suite covers `MockDataService`, the NFC parser and error mapping
(`test/data/`), Riverpod state transitions (`test/shared/providers/`), router
deeplinks/redirects and design-system widgets (`test/widget/`), plus offline
queue smoke tests (`test/smoke/`). Coverage of business logic
(`bus_estimator`, offline sync, the remote repositories) is **partial** and is
acknowledged technical debt rather than a finished safety net.

Pixel goldens were intentionally **not** committed: `google_fonts` resolves
fonts over the network, so byte-identical output across machines is not
realistic. Structural assertions cover the same surface.

---

## i18n

Strings live in `lib/l10n/app_es.arb` (template) and `lib/l10n/app_en.arb`,
generated into `lib/l10n/generated/`. The selector is at **Profile →
Accessibility → Idioma** (`localeProvider`). Both ARB files are **complete and
in sync** (275 keys each, verified by key — the earlier "~60 %" figure was a
miscount of a multiline ARB by line, not by key). A few widgets still build
Spanish strings inline rather than via l10n; the driver-side route editor is
also single-locale (`es`) — internal tooling for the demo persona.

---

## Accessibility

The app implements real accessibility work: `Semantics` nodes, high-contrast
theme, color-blind matrices (protanopia/deuteranopia/tritanopia), an
OpenDyslexic font option, `textScaler` support, reduced-motion handling, and a
WCAG-AA contrast validator for custom palettes (`custom_palette_screen.dart`).

The **"WCAG 2.1 AA"** claim is qualified to **"WCAG 2.1 AA partial"**: there is
no manual TalkBack/VoiceOver pass, the map (`flutter_map`) is not accessible,
some `Semantics` labels are hardcoded in Spanish, and there are no
accessibility golden tests in CI. Known gaps are listed honestly in
`docs/A11Y_AUDIT.md`.

---

## Scope decisions (what this project deliberately is / is not)

This is an academic project. Conscious boundaries:

- The Supabase backend is **scaffolded and partially wired**, not production-
  hardened: no FORCE RLS, Edge Functions lack rate-limiting / `user_id`
  validation, real-time (F13) is unimplemented. See `docs/REVISION_CRITICA.md`.
- Mock data is the primary demonstrable surface; the other ~9 Spanish
  operators referenced in the design depend on a populated Supabase and are
  **future work**, not shipped in the local build.
- No A → B route planner. No migration away from Riverpod.
- No `very_good_analysis`. Lint rules are layered on top of `flutter_lints`
  (`prefer_single_quotes`, `unawaited_futures`,
  `use_build_context_synchronously`, etc.) — strict but not noisy.

A full critical self-review (scoring, severity-ranked findings, remediation
plan) lives in **`docs/REVISION_CRITICA.md`**.

---

## License & data

The COMUJESA timetable / stop / line data shipped under `assets/mock/` is
sourced from publicly available timetables and reformatted for educational
use. This project does not claim authorship of the underlying data.
