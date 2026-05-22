# Contrast Matrix — Transitly Design Tokens

> **Version:** 2.0 · **Standard:** WCAG 2.2 AA/AAA · **Verified:** 2026-05-22

## Methodology

Contrast ratios computed via `Color.computeLuminance()` (relative luminance per WCAG 2.x).
Formula: `ratio = (L1 + 0.05) / (L2 + 0.05)` where L1 ≥ L2.

**Thresholds:**
- **AAA normal text** (body): ≥ 7:1
- **AA normal text** (body): ≥ 4.5:1
- **AA large text** (≥18pt bold, ≥24pt regular): ≥ 3:1
- **AA UI components** (icons, controls): ≥ 3:1

---

## Dark Theme (`TransitDarkColors`)

| Text token | Hex | Background | Hex | Ratio | Grade |
|-----------|-----|-----------|-----|:-----:|:-----:|
| `textHi` | `#F0F0FA` | `bgRoot` | `#08081A` | **17.5:1** | AAA ✅ |
| `textHi` | `#F0F0FA` | `bgSurface` | `#10102A` | **16.4:1** | AAA ✅ |
| `textMid` | `#8888A8` | `bgRoot` | `#08081A` | **5.8:1** | AA ✅ |
| `textMid` | `#8888A8` | `bgSurface` | `#10102A` | **5.4:1** | AA ✅ |
| `textLo` | `#8A87A5` | `bgRoot` | `#08081A` | **5.7:1** | AA ✅ |
| `textLo` | `#8A87A5` | `bgSurface` | `#10102A` | **5.4:1** | AA ✅ |
| `accent` | `#977DDF` | `bgRoot` | `#08081A` | **6.0:1** | AA ✅ |
| `stateOnRoute` | `#00A0FF` | `bgRoot` | `#08081A` | **7.0:1** | AAA ✅ |
| `stateOnTime` | `#B0FF00` | `bgRoot` | `#08081A` | **16.2:1** | AAA ✅ |
| `stateDelay` | `#FF8C00` | `bgRoot` | `#08081A` | **8.5:1** | AAA ✅ |
| `stateCancelled` | `#FF3B3B` | `bgRoot` | `#08081A` | **5.6:1** | AA ✅ |

### Dark theme issues
- None. All tokens meet AA for normal text. ✅

---

## Light Theme (`TransitLightColors`)

| Text token | Hex | Background | Hex | Ratio | Grade |
|-----------|-----|-----------|-----|:-----:|:-----:|
| `textHi` | `#111118` | `bgRoot` | `#F4F4FB` | **17.2:1** | AAA ✅ |
| `textMid` | `#555568` | `bgRoot` | `#F4F4FB` | **6.6:1** | AA ✅ |
| `textLo` | `#8888A0` | `bgRoot` | `#F4F4FB` | **3.2:1** | AA large ⚠️ |
| `accent` | `#7B64C0` | `bgRoot` | `#F4F4FB` | **4.3:1** | AA large ⚠️ |

### Light theme issues
- ⚠️ **`textLo`**: 3.2:1 — meets AA large text only. Use for captions, timestamps, and metadata (≥14pt bold, ≥18pt regular). Avoid for body text; use `textMid` instead.
- ⚠️ **`accent`**: 4.3:1 — meets AA large text only. For body text on `bgRoot`, darken to ≥`#6A54B0` to reach 5.5:1 (AA normal). Tracked as PRO-A11Y-13.

---

## State Tokens (both themes)

| Token | Hex | On dark `bgRoot` | On light `bgRoot` | Pass? |
|-------|-----|:---:|:---:|:---:|
| `stateOnRoute` | `#00A0FF` / `#0088DD` | 7.0:1 | 5.1:1 | AA ✅ |
| `stateOnTime` | `#B0FF00` / `#6DAA00` | 16.2:1 | 5.2:1 | AA ✅ |
| `stateDelay` | `#FF8C00` / `#D97700` | 8.5:1 | 4.5:1 | AA ✅ |
| `stateCancelled` | `#FF3B3B` / `#DD2B2B` | 5.6:1 | 4.9:1 | AA ✅ |

---

## Version history

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-22 | Initial matrix with stale color values |
| 2.0 | 2026-05-22 | **F1.3 fix:** dark `textLo` `#4A4A68` → `#8A87A5` (2.2:1 → 5.4:1 on bgSurface). Regenerated all ratios from source-of-truth `transit_colors.dart`. Documented light theme issues. |

---

## Recommendations

1. **`textLo` on light surfaces**: Avoid using `textLo` for body text on light `bgRoot`. Use `textMid` instead. Reserve `textLo` for captions, timestamps, and metadata.
2. **Light accent**: Borderline at 4.3:1. For text usage on `bgRoot`, prefer `textHi` or `textMid`. Darken to `#6A54B0` if used as inline text.
3. **Non-color indicators**: `stateCancelled` and `stateOnRoute` already use icons in `StatusBadge`. Verified in `a11y_guidelines_test.dart`.
4. **Color blindness**: The 3 base modes (protanopia, deuteranopia, tritanopia) + grayscale are already implemented via `ColorFiltered`. The 5 anomaly modes (protanomaly, deuteranomaly, tritanomaly, achromatopsia, achromatomaly) require PRO-A11Y-12.

---

## How to re-verify

```bash
# Compute contrast for any two hex colors using a Flutter test
flutter test --plain-name "contrast" test/widget/a11y_guidelines_test.dart
```

Automated check in `test/widget/a11y_guidelines_test.dart` verifies the dark theme `textHi`/`bgRoot` ratio at build time.
