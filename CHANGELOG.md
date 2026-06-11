# Changelog

All notable changes to Transitly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.13.0](https://github.com/astralk9999/Transitly/compare/v1.12.4...v1.13.0) (2026-06-11)


### Features

* **widgets:** refresco periódico real en segundo plano (intervalo configurable) ([12b2c9c](https://github.com/astralk9999/Transitly/commit/12b2c9c6ef59f466d9c6178d5d22d8b9b24caffb))


### Bug Fixes

* **mapa:** filtros de líneas/zonas/paradas comunitarias funcionales y ampliables ([5614809](https://github.com/astralk9999/Transitly/commit/5614809863f987bd239f2c4bb81f777b226ecd4f))

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
