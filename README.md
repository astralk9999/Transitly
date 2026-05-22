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

> **Honest scope note (read before evaluating).** Phases F0–F27 (28/28
> completed) added a full Supabase backend, auth, FCM push, telemetry,
> an Astro SSR site and native home widgets. Real-time updates (F13) are
> implemented on the critical repos (5 of 12: `bus_location`, `stop`,
> `route`, `incident`, `route_feedback`) via a shared
> `RealtimeChannelManager` with exponential backoff + jitter. APK
> release builds and CI is green on 4 jobs (incl. Build Android APK).
> The remaining production gaps are documented in
> [`docs/00_MAESTRO.md`](./docs/00_MAESTRO.md) — start there.

---

## Documentation entry-point

All documentation is indexed in **[`docs/README.md`](./docs/README.md)**,
which maps each TFG required deliverable to the corresponding file and
points to the audit dossiers (`00_MAESTRO`, `SCALABILITY`,
`ACCESSIBILITY`) and the action plan.

---

## Status

The project completed 28/28 incremental phases (**F0 → F27**); state in
`multiagent/state/project.json`. Development was assisted by an autonomous
multi-agent system (Queen / Developer / Review / Git / Documentation),
documented in `multiagent/ARCHITECTURE.md` and in the TFG memory
(`docs/tfg/03–05`).

Verified quality metrics (2026-05-22):

| Metric | Value |
|--------|-------|
| `flutter analyze` | **0 issues** |
| `flutter test` | **201 / 201 passing** |
| Line coverage | **~25,5 %** — known debt |
| `flutter build apk --release` | **OK** (73,5 MB) |
| CI GitHub Actions | **4 jobs green** (Analyze, Test, Build Web, Build Android APK) |

[![codecov](https://codecov.io/gh/astralk9999/Transitly/branch/master/graph/badge.svg)](https://codecov.io/gh/astralk9999/Transitly)

> Coverage is the remaining lever: the `remote/` data layer (auth + 7
> repos) is at ~0 %. Plan in
> [`docs/MEGA_PLAN_REFINAMIENTO.md §P2-4`](./docs/MEGA_PLAN_REFINAMIENTO.md).

---

## Architecture / Stack

- **Flutter** 3.9.2+ / **Dart** 3 (strict casts + strict raw types)
- **Riverpod** 2.6 (StateProviders, derived providers, `autoDispose` on
  streams/timers/futures, `overrideWith` in tests)
- **go_router** 17.2 with `StatefulShellRoute` and per-route `redirect`
- **Supabase** (`supabase_flutter` 2.8) — auth, 13 SQL migrations, 2 Edge
  Functions; `domain/local/mock/remote` repository pattern per entity
- **Firebase / FCM** (`firebase_messaging`) — push, with graceful degradation
- **Sentry + PostHog** — crash reporting / analytics, consent-gated
- **flutter_map** 7.0 + `latlong2`; **MapTiler** + FMTC offline tile caching
- **nfc_manager** 3.5 over Mifare Classic (sector keys via `--dart-define`)
- **Astro** SSR marketing site (`astro/`)
- Native Android/iOS home widgets (`home_widget`, `workmanager`)
- **DM Sans + IBM Plex Mono** bundled as local assets (F26 closed)
- **flutter_localizations** + ARB generation (`flutter gen-l10n`) — **ES / EN / AR (RTL)**, 343 keys/locale

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
flutter test                       # 175 tests
flutter test --coverage            # writes coverage/lcov.info (24,30 % lines)
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

Strings live in `lib/l10n/app_es.arb` (template), `lib/l10n/app_en.arb`
and `lib/l10n/app_ar.arb` (Arabic / RTL), generated into
`lib/l10n/generated/`. The selector is at **Profile → Accessibility →
Idioma** (`localeProvider`). The three ARB files are **complete and in
sync** (343 keys each). The driver-side route editor remains
single-locale (`es`) — internal tooling for the demo persona.

---

## Accessibility

The app implements real accessibility work: `Semantics` nodes localized
to ES/EN/AR, high-contrast theme, color-blind matrices
(protanopia/deuteranopia/tritanopia), an OpenDyslexic font option,
`textScaler` that composes with the OS setting, reduced-motion handling,
a WCAG-AA contrast validator for custom palettes, and a `Pressable`
widget enforcing the 48 dp minimum tap target.

The **"WCAG 2.2 AA"** claim is qualified to **"AA partial / in
progress"**: there is no manual TalkBack/VoiceOver pass yet, the map
(`flutter_map`) still needs an accessible alternative integration, and
contrast ratios for base tokens are not verified with tooling. Full
audit and remediation plan in
[`docs/ACCESSIBILITY.md`](./docs/ACCESSIBILITY.md).

---

## Scope decisions (what this project deliberately is / is not)

This is an academic project (TFG). Conscious boundaries:

- The Supabase backend is **scaffolded with real-time on the 5 critical
  repos**, not yet production-hardened at scale: no FORCE RLS, Edge
  Functions with best-effort anti-SSRF + rate-limit (documented as
  known debt), single-region project. See
  [`docs/SCALABILITY.md`](./docs/SCALABILITY.md).
- Mock data is the primary demonstrable surface; the other ~9 Spanish
  operators referenced in the design depend on a populated Supabase and
  are **future work**.
- No A → B route planner. No migration away from Riverpod.
- No `very_good_analysis`. Lint rules are layered on top of
  `flutter_lints` (`prefer_single_quotes`, `unawaited_futures`,
  `use_build_context_synchronously`, etc.) — strict but not noisy.

The full critical self-review (production-lens scoring, trajectory and
remediation plan) lives in **[`docs/00_MAESTRO.md`](./docs/00_MAESTRO.md)**
with detailed dossiers in [`docs/SCALABILITY.md`](./docs/SCALABILITY.md)
and [`docs/ACCESSIBILITY.md`](./docs/ACCESSIBILITY.md). The historical
trace of the four critical review passes is preserved under
[`docs/historico/`](./docs/historico/).

---

## License & data

The COMUJESA timetable / stop / line data shipped under `assets/mock/` is
sourced from publicly available timetables and reformatted for educational
use. This project does not claim authorship of the underlying data.
