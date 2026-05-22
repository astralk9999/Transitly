# Runbook: Sentry Spike (Crash Rate)

> **Severity:** P1 · **Owner:** Platform · **Version:** 1.0

## Symptoms

- Sentry alert: crash-free session rate drops below 99.5 %
- Multiple users reporting app crashes
- `Sentry.captureException` spike in logs
- New release deployed in the last 24 hours

## Immediate actions (first 5 minutes)

1. **Open Sentry:** https://sentry.io → Transitly project → Issues
2. **Identify top crash:** sort by event count, last 24h
3. **Check release:** is the spike tied to a specific release?
4. **Affected surface:**
   - Android only? → likely platform-specific (NFC, permissions, Gradle)
   - iOS only? → likely entitlements, privacy manifest, deployment target
   - Both? → likely Dart logic error (models, providers, routing)

## If tied to a new release

1. **Rollback immediately** (Google Play: halt rollout; App Store: expedite previous build)
2. **Revert the commit** in `master`:
   ```bash
   git revert <bad-commit>
   ```
3. **Rebuild and deploy** the rollback

## If not tied to a release (infrastructure)

1. Check Supabase schema: migration could have broken model parsing
2. Check `--dart-define` variables in CI: missing env var → `EnvException` at boot
3. Check third-party service status (Supabase, Firebase, MapTiler)

## Common crash patterns and fixes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `EnvException` at boot | Missing `--dart-define` in CI | Verify secrets in GitHub |
| `FormatException` in `fromJson` | Schema change without model update | Run `tool/build.sh` + deploy |
| `StateError` in Hive | Corrupt box | Auto-healed by `HiveInit._open()` |
| `MissingPluginException` | Platform channel not registered | Check `MainActivity` / `AppDelegate` |
| `SocketException` in `supabase_flutter` | Network unavailable | Offline mode handles; verify DNS |

## Postmortem

After resolution (within 48h):
1. Crash signature and affected release
2. Root cause analysis
3. Impact: user count, session count, duration
4. Action items: test coverage gap, lint rule, CI gate
