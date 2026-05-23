# Home Widgets Decision

## Status: NOT implementing native home widgets

### Rationale
- workmanager was removed (broke APK build, API v1-embedding removed in Flutter 3.x)
- Maintenance burden vs value
- Push notifications provide better real-time updates

### Alternatives considered
- home_widget package: requires periodic background refresh
- FCM data-only notifications: already implemented
