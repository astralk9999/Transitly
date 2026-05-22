# Accessibility Report Template — Transitly

> **Version:** 1.0 · **Standard:** WCAG 2.2 AA · **Per-release checklist**

## Release Information

| Field | Value |
|-------|-------|
| Release version | `vX.Y.Z` |
| Date | YYYY-MM-DD |
| Tester | [Name] |
| Device / OS | [e.g. Pixel 9 / Android 15] |

---

## 1. Screen Reader Verification (Manual)

| Check | TalkBack (Android) | VoiceOver (iOS) | Status |
|-------|:---:|:---:|:---:|
| All tappable elements have descriptive labels | ☐ | ☐ | |
| Images have alt text (`Semantics.label`) | ☐ | ☐ | |
| Form fields have labels | ☐ | ☐ | |
| Error messages are announced | ☐ | ☐ | |
| Navigation is logical (FocusTraversalGroup) | ☐ | ☐ | |
| Loading states are announced | ☐ | ☐ | |
| SnackBar messages are announced | ☐ | ☐ | |

## 2. Automated Checks

| Check | Tool | Result |
|-------|------|--------|
| Tap targets ≥ 48dp | `flutter test test/widget/a11y_guidelines_test.dart` | ☐ Pass / ☐ Fail |
| Contrast ratios ≥ 4.5:1 | `flutter test test/widget/a11y_guideline_helper_test.dart` | ☐ Pass / ☐ Fail |
| textScaler 2.0x no overflow | `flutter test test/widget/textscaler_200_test.dart` | ☐ Pass / ☐ Fail |
| RTL layout correct (AR) | `flutter test test/widget/rtl_undo_test.dart` | ☐ Pass / ☐ Fail |
| ARB key parity es/en | `flutter test test/smoke/arb_parity_test.dart` | ☐ Pass / ☐ Fail |
| Architecture layer rules | `flutter test test/smoke/architecture_layer_test.dart` | ☐ Pass / ☐ Fail |
| Lint rules active | `flutter analyze` (0 issues) | ☐ Pass / ☐ Fail |

## 3. Color Blindness

| Mode | Visual check (UI not broken) | Status |
|------|:---:|:---:|
| Protanopia | ☐ | |
| Deuteranopia | ☐ | |
| Tritanopia | ☐ | |
| Protanomaly | ☐ | |
| Deuteranomaly | ☐ | |
| Tritanomaly | ☐ | |
| Achromatopsia | ☐ | |
| Achromatomaly | ☐ | |

## 4. Motion & Timing

| Check | Status |
|-------|:---:|
| `reduceMotion` disables animations | ☐ |
| `extendedTimers` extends SnackBar to 8s | ☐ |
| `dyslexiaFontEnabled` switches font | ☐ |

## 5. Known Issues

| # | Description | Severity | WCAG criterion |
|---|-------------|:--------:|:--------------:|
| 1 | | | |
| 2 | | | |

## 6. Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer | | | |
| QA / Tester | | | |
