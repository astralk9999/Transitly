# Transitly · `nexto-stop-v2`

> Demo / academic Flutter project — companion app for **COMUJESA**, the urban
> bus operator of Jerez de la Frontera (Cádiz, Spain).

Transitly is a portfolio-grade transit companion: live arrivals, real route
catalogue, NFC card reader for the *Consorcio de Transportes de Andalucía*
prepaid card, route editor for drivers, and a polished motion / typography
system. The whole app runs on local mock data — no backend, no auth, no
push — so it can be cloned and run end-to-end without any infra.

---

## Status

This branch closes the P15 → P42 incremental arc. Highlights of the latest
phases:

| Phase | Theme |
|-------|-------|
| P37 | iOS NFC `Info.plist` hardening, targeted lints, error handling on `nfc_card_service.dart`, Mifare keys exposed via `--dart-define` |
| P38 | Test foundation — pure-Dart unit tests for NFC parsing / mock data / providers |
| P39 | Refactor of 5 monoliths > 500 LoC, fix of 4 latent bugs (cache-in-`build`, O(n²) on the route detail screen, unstable `ReorderableListView` keys, `TextEditingController` leaks) |
| P40 | Closing of stub screens (`AccessibilitySettings`, `OfflineData`), `is_dark_provider` to unify brightness reads |
| P41 | Router redirect on invalid deeplinks, widget + structural tests for the design system, ~56 tests green |
| P42 | i18n `es` / `en` via `flutter_localizations`, in-app locale selector, this README |

`flutter analyze` → 0 issues. `flutter test` → 56 / 56 passing.

---

## Stack

- **Flutter** 3.9.2+ / **Dart** 3 (strict casts + strict raw types)
- **Riverpod** 2.6 (StateProviders, derived providers, `overrideWith` in tests)
- **go_router** 14.8 with `StatefulShellRoute` and per-route `redirect`
- **flutter_map** 7.0 + `latlong2` for the map tab
- **nfc_manager** 3.5 over Mifare Classic (sector keys via `--dart-define`)
- **google_fonts** for IBM Plex Mono + DM Sans
- **flutter_localizations** + ARB-driven generation (`flutter gen-l10n`)

---

## Getting started

```bash
flutter pub get
flutter gen-l10n          # one-shot; generated files live in lib/l10n/generated
flutter run               # Android emulator or connected device
```

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

iOS additionally needs the entitlements declared in
`ios/Runner/Info.plist` (`NFCReaderUsageDescription` +
`com.apple.developer.nfc.readersession.formats: TAG`). The pre-P37 build
crashed on iOS without those keys.

---

## Tests

```bash
flutter test                       # 56 tests, ~10 s
flutter test --coverage            # writes coverage/lcov.info
```

The suite covers:

- `test/data/` — pure Dart unit tests for `MockDataService`, the NFC parser
  and the `_classify` error mapping (no platform channels, no fakes).
- `test/shared/providers/` — Riverpod state transitions for the NFC scan
  flow.
- `test/widget/` — widget tests for the router (deeplinks + redirect on
  invalid `routeId` / `stopId`), home tabs, profile screens, the closed
  stub screens (`AccessibilitySettings`, `OfflineData`) and the design
  system widgets (`StatusBadge`, `ReputationBadge`, `TransitButton`,
  `GlassCard`) in light and dark.

Pixel goldens were intentionally **not** committed: `google_fonts` resolves
fonts over the network, so byte-identical output across machines without a
bundled `.ttf` is not realistic. Structural assertions cover the same
surface (label uppercased, callback fires, render stays crash-free).

---

## i18n

Strings live in `lib/l10n/app_es.arb` (template) and `lib/l10n/app_en.arb`.
The generator is wired through `l10n.yaml` and writes to
`lib/l10n/generated/`. The selector lives at
**Profile → Accessibility → Idioma** and is backed by `localeProvider`.

Scope of P42 was deliberate: NFC error messages, bottom-nav labels,
profile section headers, the offline-data screen and the accessibility
screen. The driver-side route editor is still single-locale (`es`) — it's
internal tooling for the demo persona, not a user-facing flow.

---

## Scope decisions (what this project deliberately is not)

This is an academic project. The following were considered and explicitly
left out:

- No backend (Firebase / Supabase / custom REST). The mock JSON in
  `assets/mock/comujesa_data.json` is the product.
- No FCM / APNs push, no auth (OAuth / JWT).
- No A → B route planner.
- No migration away from Riverpod.
- No `very_good_analysis`. Lint rules are added on top of `flutter_lints`
  (`prefer_single_quotes`, `unawaited_futures`,
  `use_build_context_synchronously`, etc.) — strict but not noisy for the
  educational tone.

The data file (`comujesa_data.json`) and its generator
(`generate_enriched_data.js`) are the asset of value and are left
untouched.

---

## License & data

The COMUJESA timetable / stop / line data shipped under `assets/mock/` is
sourced from publicly available timetables and reformatted for educational
use. This project does not claim authorship of the underlying data.
