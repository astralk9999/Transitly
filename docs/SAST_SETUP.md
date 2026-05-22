# SAST Toolchain — Transitly

> Static Application Security Testing setup. Version: `master @ 2026-05-22`.

## Overview

| Tool | Type | Status | CI Job | Config |
|------|------|:------:|--------|--------|
| **Semgrep** | SAST (pattern-based) | Active | `semgrep` | `.semgrep/rules.yaml` |
| **Gitleaks** | Secret detection | Active | `gitleaks` | `.gitleaks.toml` |
| **OWASP ZAP** | DAST (dynamic) | Optional | Not in CI (manual / cron) | `zaproxy/action-baseline` |
| **Trufflehog** | Secret detection (alt) | N/A | Not configured | `trufflehog --git` |

---

## 1. Semgrep

Detects code patterns: hardcoded Spanish strings, `print()` calls, hardcoded Supabase URLs.

### CI integration

`.github/workflows/ci.yml` → `semgrep` job. Triggers on every push and PR to `main`/`master`.

### Rules (`.semgrep/rules.yaml`)

| Rule ID | Severity | What it catches |
|---------|:--------:|-----------------|
| `no-hardcoded-es-strings` | WARNING | Spanish string literals in `lib/` (excludes l10n, env_error_screen, env.dart) |
| `no-print-in-lib` | ERROR | `print(` calls in `lib/` (use `AppLogger`) |
| `no-hardcoded-supabase-url` | ERROR | Hardcoded `*.supabase.co` URLs (use `Env.supabaseUrl` or `--dart-define`) |

### Run locally

```bash
# Install Semgrep CLI
pip install semgrep

# Run rules against the repo
semgrep --config .semgrep/rules.yaml

# Run with autofix (only for supported rules)
semgrep --config .semgrep/rules.yaml --autofix

# Run only ERROR rules
semgrep --config .semgrep/rules.yaml --severity ERROR
```

### Interpreting results

```
Findings:
  lib/features/home/home_screen.dart
    no-print-in-lib: print() is forbidden in lib/. Use AppLogger instead.
      42:   print('loaded');
```

Each finding shows: file path, rule ID, message, line number, and matched line.
- **ERROR** findings fail CI and must be fixed.
- **WARNING** findings are informational but should be reviewed.

---

## 2. Gitleaks

Scans git history for secrets (API keys, tokens, passwords) before they reach the remote.

### CI integration

`.github/workflows/ci.yml` → `gitleaks` job. Uses `gitleaks/gitleaks-action@v2` with full git history (`fetch-depth: 0`).

### Configuration (`.gitleaks.toml`)

| Allowlist rule | Pattern | Reason |
|---------------|---------|--------|
| Codegen files | `.*\.freezed\.dart$`, `.*\.g\.dart$` | Generated code may contain string patterns that look like secrets |
| l10n generated | `l10n/generated/.*` | Generated ARB output |
| pubspec.lock | `pubspec\.lock` | Dependency lock file |
| CI workflows | `\.github/workflows/.*` | Placeholder secrets in CI definitions |

### Run locally

```bash
# Install Gitleaks
# macOS:  brew install gitleaks
# Linux:  snap install gitleaks  or download from https://github.com/gitleaks/gitleaks/releases
# Windows: choco install gitleaks  or download release binary

# Scan current repo (uncommitted changes + git history)
gitleaks detect --source . --config .gitleaks.toml --verbose

# Scan last 50 commits only
gitleaks detect --source . --log-opts="-50"

# Pre-commit scan (staged changes only)
gitleaks protect --staged --config .gitleaks.toml
```

### Interpreting results

```
Finding:
  RuleID:     generic-api-key
  Secret:     sk_live_abc123def456
  File:       lib/core/env.dart
  Line:       12
  Commit:     a1b2c3d
  Author:     dev
  Date:       2026-05-20T10:30:00Z
```

- **RuleID** tells which pattern matched (see [Gitleaks default rules](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#configuration)).
- If the finding is a false positive, add an allowlist entry in `.gitleaks.toml`.
- **Never commit `.env` files** — they are in `.gitignore` already.
- If a real secret is found in git history, rotate it immediately and consider using `git filter-repo` to scrub history.

---

## 3. OWASP ZAP (Dynamic Analysis)

ZAP performs runtime security scanning against a live deployment — it spiders the app and sends attack payloads against endpoints. This is a DAST tool (Dynamic), complementing the SAST tools above.

### When to use

- After deploying to a staging environment (`https://transitly-staging.vercel.app` or similar).
- Before major releases as part of release checklist.
- Weekly cron scan for regression detection.

### CI setup (optional nightly)

Create `.github/workflows/nightly-security.yml`:

```yaml
name: Nightly Security Scan

on:
  schedule:
    - cron: '0 3 * * *'   # Daily at 03:00 UTC
  workflow_dispatch:        # Manual trigger

jobs:
  zap-baseline:
    name: OWASP ZAP Baseline Scan
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'https://transitly-staging.example.com'
          fail_on_risk: 'High'
          issue_title: 'ZAP Scan Results'
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Run locally

```bash
# Pull ZAP docker image
docker pull owasp/zap2docker-stable

# Baseline scan (quick, non-invasive)
docker run --rm owasp/zap2docker-stable zap-baseline.py \
  -t https://transitly-staging.example.com \
  -r baseline_report.html

# Full scan (more thorough, may modify data)
docker run --rm owasp/zap2docker-stable zap-full-scan.py \
  -t https://transitly-staging.example.com \
  -r full_scan_report.html
```

> **Warning:** Never run active/full scans against production. Use baseline scans only on production.

### Interpreting results

ZAP categorizes findings by risk level:

| Risk | Meaning | Action |
|:----:|---------|--------|
| High | Exploitable vulnerability | Fix immediately, block release |
| Medium | Potential vulnerability | Fix before next release |
| Low | Information disclosure | Review, fix in next cycle |
| Informational | Best practice deviation | Review, document or fix |

Common findings in Flutter/mobile backends:
- **Missing `Content-Security-Policy` header** → add to Supabase/nginx
- **Cookie without `HttpOnly` / `Secure` flags** → configure in GoTrue settings
- **X-Content-Type-Options missing** → add response headers in Edge Functions

### False positives with Supabase

Supabase PostgREST responses may trigger ZAP alerts that are not exploitable:
- Add `CSP` and `X-Frame-Options` headers via Edge Functions or CDN.
- For RLS-protected endpoints, document the finding and mark as false positive.

---

## 4. Trufflehog (Alternative Secret Scanner)

Trufflehog scans for verified secrets (not just regex matches — it checks if the secret is still live).

### Comparison with Gitleaks

| Aspect | Gitleaks | Trufflehog |
|--------|----------|------------|
| Method | Regex + entropy | Regex + **live verification** |
| Speed | Fast | Slower (network calls) |
| Languages | Go | Go |
| CI action | `gitleaks/gitleaks-action@v2` | `trufflesecurity/trufflehog-action@v1` |
| Current status | Configured | Not configured |

### When to consider Trufflehog

- As a second-opinion scanner before major releases.
- If you suspect a secret was leaked but Gitleaks didn't catch it (Trufflehog verifies against provider APIs).
- For periodic deep scans of full git history.

### Run locally

```bash
# Install
# macOS:  brew install trufflehog
# Linux:  curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh

# Scan current repo
trufflehog git file://. --only-verified

# Scan full history (slow)
trufflehog git file://. --only-verified --since-commit=HEAD~100
```

---

## Quick Reference

```bash
# Run all local SAST checks before committing
semgrep --config .semgrep/rules.yaml          # Code patterns
gitleaks detect --source . --config .gitleaks.toml  # Secrets in git
flutter analyze                                 # Dart static analysis
```

## Related Docs

- `docs/SECURITY_PAT_ROTATION.md` — PAT rotation procedure
- `docs/SECURITY_AUDIT_2026_06.md` — OWASP Mobile Top 10 checklist (F6.10)
- `docs/RELEASE_CHECKLIST.md` — Pre-release verification steps
- `docs/ARCHITECTURE.md` §4.3 — Error handling pattern (input validation)
