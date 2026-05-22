# Security Policy

## Supported versions

| Version | Supported          |
|---------|--------------------|
| 1.x     | :white_check_mark: |

## Reporting a vulnerability

Please report security vulnerabilities to **security@transitly.app**.

Do NOT open public issues for security vulnerabilities.

Response time: within 72 hours.

## Security measures

- Secrets are injected via `--dart-define`, never bundled
- `.env` is gitignored
- Supabase RLS is default-deny
- Crash reporting is GDPR consent-gated (Sentry)
- Analytics is opt-in only (PostHog)
- NFC card UIDs are never logged
- PII-free logging (no emails, locations, card numbers in logs)
