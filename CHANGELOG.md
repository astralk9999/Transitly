# Changelog

All notable changes to Transitly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-05-21

### Added
- Multi-operator support (COMUJESA, TUSSAM, EMT Madrid, TMB, Bilbobus)
- Supabase backend with 12 data repositories (5/12 with Realtime channels)
- Offline-first architecture with Hive cache and sync queue
- NFC card reading (Mifare Classic, balance extraction)
- Driver live tracking with GPS and bus position broadcasting
- Community features: incident reports, route suggestions, feedback, voting
- Admin panel: operator CRUD, moderation inbox, driver invitation codes
- GTFS importer (Supabase Edge Function, TypeScript/Deno)
- i18n: Spanish, English, Arabic (RTL)
- Accessibility: color blindness modes, dyslexia font, text scaling, font scale
- Design system with token-based theming (TransitColorScheme)
- Privacy: GDPR consent-gated Sentry/PostHog, offline by default
- Push notifications via Firebase Cloud Messaging
- Home widget (Android)
- CI pipeline: analyze, test, web build, Android APK build

[1.0.0]: https://github.com/transitly/transitly/releases/tag/v1.0.0
