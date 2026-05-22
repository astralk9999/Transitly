# Release Checklist — Transitly

**Target version:** 1.0.0+1
**Target date:** 2026-05-15
**Release type:** TFG presentation + internal beta

---

## Pre-flight

- [x] `flutter analyze` — 0 errors, 0 warnings, 6 info (prefer_const_constructors)
- [x] `flutter test` — 304 tests passing (1 skipped), 0 failing (2026-05-22)
- [x] `.env.example` — updated with all required keys (SUPABASE, POSTHOG, SENTRY, MAPTILER, FCM)
- [ ] google-fonts bundled as local assets (TODO F26 — currently network fetch via `google_fonts`)

---

## Android Release

### ProGuard / R8
- [ ] Verify `android/app/proguard-rules.pro` exists (or default R8 is sufficient)
- Hive requires: `-keep class com.transitly.** { *; }`
- Supabase/PostgREST not affected (pure Dart)

### Signing
- [ ] Keystore generated: `android/app/upload-keystore.jks` (NOT committed)
- [ ] `key.properties` with storePassword, keyPassword, keyAlias, storeFile (NOT committed)
- [ ] `android/app/build.gradle` configured for release signing via `key.properties`

### Build
- [ ] `flutter build appbundle` produces valid AAB
- [ ] `flutter build apk --split-per-abi` produces APKs per architecture
- [ ] APK size < 50 MB (target)

---

## Google Play Store

### Store listing
- [ ] App name: "Transitly — Transporte publico Espana"
- [ ] Short description: "Transporte publico en tiempo real para toda Espana"
- [ ] Full description with keywords
- [ ] Category: Maps & Navigation
- [ ] Content rating: PEGI 3
- [ ] Privacy policy URL: (to be published via Astro site or GitHub Pages)
- [ ] Screenshots: phone (6.5"), 7" tablet, 10" tablet

### Internal testing
- [ ] First AAB uploaded to Internal Testing track
- [ ] Tester list configured (personal + 2-3 testers)
- [ ] End-to-end verification on real device

---

## App Store (iOS) — Future

- [ ] Apple Developer Program enrollment ($99/year)
- [ ] App Store Connect: create app record
- [ ] Xcode archive + upload
- [ ] TestFlight internal testing
- [ ] App Review guidelines check (NFC usage description, location permissions)

---

## Documentation

- [x] `docs/ARCHITECTURE.md` — up to date
- [x] `docs/historico/PLAN_TRANSITLY_V2.md` — F0→F25 completed, F26 in progress
- [x] `docs/PENDIENTES.md` — synchronized
- [x] `docs/tfg/04_desarrollo_implementacion.md` — updated with F16-F25
- [x] `docs/tfg/05_evaluacion_documentacion.md` — incidences updated
- [x] `docs/tfg/08_presentacion.md` — final state confirmed
- [ ] `README.md` — updated description, screenshots, stack, setup instructions
- [ ] `CHANGELOG.md` — generated from conventional commits
- [ ] `LICENSE` — decided (academic vs proprietary)

---

## Known Gaps (TODO F26)

| Item | Priority | Notes |
|------|----------|-------|
| Google Fonts bundle | High | Currently fetch from network; must bundle for release |
| ProGuard rules verification | Medium | Hive + NFC may need keep rules |
| `mock/comujesa_data.json` minification | Low | 1.2 MB in APK; migrate to Supabase or minify |
| MockRealtimeService background pause | Low | Timers keep running in background |
| SmokeBackground ticker | Low | Cosmetic, affects tests only |

---

**Last updated:** 2026-05-15 · F26
