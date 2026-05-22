# Performance Budget — Transitly

> Quantitative performance targets enforced in CI and measured during
> development. Version: `master @ 2026-05-22`.

## Budget Summary

| Metric | Budget | Scope | Enforced |
|--------|:------:|-------|:--------:|
| **APK size** (arm64-v8a) | ≤ 80 MB | Release build, split-per-abi | CI (fail) |
| **Cold start** | ≤ 2 s | `Time to login button` from cold launch | SLO target |
| **Frame rate** | 60 fps | Scrolling, map interaction, route search | Dev target |
| **Web bundle (uncompressed)** | ≤ 15 MB | `build/web/` after `flutter build web --release` | CI (warn) |

---

## 1. APK Size Budget — 80 MB

### Current baseline

- **arm64-v8a release APK:** ~73.5 MB (as of 2026-05)
- Build flags: `--release --split-per-abi --obfuscate --split-debug-info`

### How it's measured

CI job `build-android` in `.github/workflows/ci.yml`:

```yaml
- name: Bundle size check
  run: |
    APK_SIZE=$(stat -c%s build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)
    APK_SIZE_MB=$((APK_SIZE / 1048576))
    echo "APK size (arm64-v8a): ${APK_SIZE_MB} MB"
    if [ "$APK_SIZE_MB" -gt 80 ]; then
      echo "::error::APK size ${APK_SIZE_MB} MB exceeds 80 MB budget"
      exit 1
    fi
```

### Measure locally

```bash
# Build release APK
flutter build apk --release --split-per-abi --analyze-size

# Check sizes
ls -lh build/app/outputs/flutter-apk/*.apk

# Analyze size breakdown (Flutter 3.27+)
flutter build apk --release --analyze-size
# Opens size analysis in browser with treemap
```

### What to check when budget is exceeded

1. **Assets**: Check `assets/` for uncompressed images or unused files.
2. **Fonts**: Bundled fonts (DM Sans, IBM Plex Mono) are ~1.3 MB — verify no duplicates.
3. **Dependencies**: Review `pubspec.lock` for heavy transitive deps.
4. **Native libs**: Check `android/app/build.gradle.kts` for unnecessary native deps.
5. **Icon/launcher**: ABIs (arm64-v8a, armeabi-v7a, x86_64) each carry their own `.so`.

---

## 2. Cold Start Budget — 2 seconds

Time from app icon tap to user-visible login/home screen under normal conditions.

### How to measure

**Android:**
```bash
# Measure cold start via adb (requires device/emulator)
adb shell am start -W com.transitly.transitly/.MainActivity | grep TotalTime

# Or use Android Studio Profiler → Startup Timing
```

**iOS:**
```bash
# Instruments → App Launch template
# Or Xcode Organizer → Metrics → Launch Time
```

**Programmatic (Sentry):**
- `SentrySetup` already captures `app_start_cold` spans.
- View in Sentry Performance → Mobile → App Start.
- Filter: `ttfd` (Time to First Display) and `ttid` (Time to Initial Display).

### SLO interpretation

- < 1.5 s: Excellent (within Android Vitals good threshold)
- 1.5–2.0 s: Acceptable
- 2.0–3.0 s: Requires investigation
- > 3.0 s: Breach — user-perceptible lag

### Known factors

- **Hive initialization** (9 boxes): < 100 ms typically.
- **MockDataService asset loading**: 200–500 ms first load (JSON parse).
- **Supabase client init**: depends on network; guest mode skips this.
- **Font loading**: pre-bundled, no network fetch (F26).

---

## 3. Frame Budget — 60 fps (16.67 ms per frame)

Target is consistent 60 fps during all user interactions. Jank = any frame > 16 ms.

### How to measure

**Flutter DevTools:**
```bash
flutter run --profile
# Open DevTools → Performance → Timeline
# Record a trace while interacting (scroll, navigate, tap)
# Look for frames in the "janky" zone (> 16 ms raster or UI thread)
```

**Sentry Performance:**
```bash
# SentrySetup already captures slow frames (>200ms)
# Dashboard: Sentry → Performance → Mobile → Frame Render
# Configure frame rate tracking in sentry_setup.dart
```

**CI (future):**
```bash
# Integration test with frame timing
flutter test integration_test/performance/scroll_perf_test.dart
```

### Known hotspots

- **Map with many markers** → no clustering yet (SCALABILITY.md §C).
- **StaggerList animations** → tested with `disableAnimations: true` in widget tests; at runtime uses `AnimatedList` with builder.
- **SmokeBackground shader** → uses `CustomPainter` with particle system; isolated via `RepaintBoundary`.

### Mitigation order

1. Enable clustering on map markers (highest impact).
2. Convert remaining `ListView()` to `ListView.builder()` with `itemExtent`.
3. Profile route search screen with large datasets.
4. Consider SkSL warmup for shader-heavy screens.

---

## 4. Web Bundle Budget — 15 MB

### How to measure

```bash
flutter build web --release
du -sh build/web/
```

### CI enforcement (proposed)

Add to `build` job in `ci.yml`:

```yaml
- name: Web bundle size check
  run: |
    SIZE=$(du -sb build/web/ | cut -f1)
    SIZE_MB=$((SIZE / 1048576))
    echo "Web bundle size: ${SIZE_MB} MB"
    echo "## Web bundle size" >> $GITHUB_STEP_SUMMARY
    echo "| Metric | Value | Budget |" >> $GITHUB_STEP_SUMMARY
    echo "|--------|-------|--------|" >> $GITHUB_STEP_SUMMARY
    echo "| Bundle size | ${SIZE_MB} MB | 15 MB |" >> $GITHUB_STEP_SUMMARY
```

---

## Monitoring Over Time

| Tool | What | Cadence |
|------|------|---------|
| CI (`build-android`) | APK size trend | Every commit |
| Sentry Performance | App start, slow frames, frozen frames | Continuous |
| DevTools | Jank profiling during development | On demand |
| Android Vitals (Play Console) | ANR rate, crash rate, start time | After release |

## Related Docs

- `docs/ABI_SPLITS.md` — APK architecture splits detail
- `docs/SCALABILITY.md` §C — Client perf and memory review
- `docs/RELEASE_CHECKLIST.md` — Pre-release verification steps
- `docs/service-catalog.md` — Service dependencies and health checks
