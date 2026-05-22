# Low Data Mode — Transitly

> **Version:** 1.0 · **Standard:** WCAG 2.2 · **Owner:** Product

## Overview

Low Data Mode reduces network usage for users with limited data plans or
slow connections. It disables non-essential network features and reduces
asset quality.

---

## Features affected

| Feature | Normal mode | Low data mode |
|---------|------------|:---:|
| Map tiles | 512px raster | 256px raster / cached only |
| Map tile prefetch | Pre-cache neighboring tiles | Disabled |
| Bus position polling | Every 5s | Every 30s or cached only |
| Realtime channels | WebSocket active | WebSocket disabled (polling fallback) |
| Incident photos | Full resolution upload | Resized to 50% quality |
| Profile avatars | Full resolution | Thumbnail (64px) |
| Push notifications | Full content | Title only (no image) |
| Offline sync | Immediate | Batch every 5 min |

---

## Implementation

### Detection

```dart
// Using connectivity_plus
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivity = Connectivity();
final result = await connectivity.checkConnectivity();

// On Android, check for metered connection
// On iOS, check for Low Data Mode via NSURLSessionConfiguration
```

### Provider

```dart
final lowDataModeProvider = StateProvider<bool>((ref) => false);

// Toggle from Settings → Accessibility → Low Data Mode
```

### Adapters

```dart
// Map tile quality
final tileSize = ref.watch(lowDataModeProvider) ? 256 : 512;

// Polling interval
final pollInterval = ref.watch(lowDataModeProvider)
    ? const Duration(seconds: 30)
    : const Duration(seconds: 5);
```

---

## Settings UI

Add to `AccessibilitySettingsScreen`:

```dart
TransitCheckbox(
  label: 'Low Data Mode',
  description: 'Reduce map quality, tile pre-fetching, '
      'and polling frequency to save data.',
  value: isLowData,
  onChanged: (v) => ref.read(lowDataModeProvider.notifier).state = v!,
),
```

---

## UserPreferences

```dart
// In UserPreferences model
@Default(false) bool lowDataMode,
```

## Network Awareness

- Show `OfflineBanner` when `connectivity == none`
- Show "Low Data Mode" indicator when enabled
- `DataFreshnessIndicator` reflects longer cache TTL in low data mode
