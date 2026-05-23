# ABI Splits — Android App Bundle

**File:** `android/app/build.gradle.kts`
**Last updated:** 2026-05-22

---

## Configuration

ABI splitting is enabled in the `bundle` block of `build.gradle.kts`:

```kotlin
bundle {
    language {
        enableSplit = true
    }
    abi {
        enableSplit = true
    }
}
```

This applies to **Android App Bundle (.aab)** builds only (not APK). The Google Play Store uses these splits to serve device-specific APKs.

---

## ABI Targets

The Flutter Gradle plugin produces native libraries for these ABIs by default:

| ABI | Target Devices |
|-----|---------------|
| `arm64-v8a` | Modern Android phones (2015+) — ~98% of active devices |
| `armeabi-v7a` | Older 32-bit ARM devices — legacy support |
| `x86_64` | Android emulators, some Chromebooks, Intel-based tablets |

Each ABI gets its own native `.so` library slice within the bundle. At install time, Google Play delivers **only the ABI matching the user's device**.

---

## APK Size Reduction

Without splits, all three ABI libraries are packaged into a single APK, roughly tripling native code size. With splits:

| Scenario | Native lib size (approx.) |
|----------|--------------------------|
| Universal APK (no splits) | ~3× baseline |
| Per-ABI split | ~1× baseline |

On a typical Flutter app, native `.so` files account for 15–25 MiB. Splits save 10–17 MiB per install on arm64 devices (the vast majority of users).

Additionally, `language { enableSplit = true }` splits locale resources so users only download their language's strings.

---

## How to Verify in CI

### 1. Build the App Bundle

```bash
flutter build appbundle
```

### 2. Inspect Split APKs

Use `bundletool` to extract and measure:

```bash
bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks \
  --mode=universal

bundletool get-size total --apks=app.apks
```

### 3. Verify in GitHub Actions

The CI workflow (`.github/workflows/ci.yml`) can run:

```yaml
- name: Build App Bundle
  run: flutter build appbundle

- name: Verify ABI splits
  run: |
    bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks --mode=universal
    bundletool get-size total --apks=app.apks
```

### 4. Manual Check

List the ABIs present in the built bundle:

```bash
unzip -l build/app/outputs/bundle/release/app-release.aab | grep -E "lib/(arm64-v8a|armeabi-v7a|x86_64)"
```

---

## Notes

- ABI splits only affect **release** builds published via Google Play. Debug/development builds use the full universal native library set.
- `isMinifyEnabled = true` and `isShrinkResources = true` are also enabled in the release build type, further reducing APK size.
- The `ndkVersion` is managed by the Flutter Gradle plugin (`flutter.ndkVersion`).
- If a new ABI needs support (e.g., `riscv64` in the future), it must be added to the Flutter engine build — no changes needed in this project.
