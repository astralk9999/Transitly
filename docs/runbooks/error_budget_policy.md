# Error Budget Policy — Transitly

> **Version:** 1.0 · **Owner:** Platform team

## Principle

Each SLO has an error budget: `1 - target`. This budget is the acceptable
amount of failure over the measurement window.

When the error budget is **exhausted** or **critically low**, releases are
frozen until reliability is restored.

---

## Error Budgets by SLO

| SLO | Target | Budget/month | Exhausted at |
|-----|--------|-------------|-------------|
| Login success | 99.5 % | 0.5 % (3.6 h downtime) | > 0.5 % failures in 30 days |
| Map p95 | ≤ 2000 ms | — (latency, not error) | p95 > 2000 ms for 7 days |
| Crash-free | 99.9 % | 0.1 % | > 0.1 % sessions with crash |
| Edge success | 99 % | 1 % (7.2 h downtime) | > 1 % invocations fail |
| Push p95 | ≤ 30 s | — (latency) | > 30 s p95 for 7 days |
| Auth refresh | 99.9 % | 0.1 % | > 0.1 % refresh failures |

---

## Escalation

1. **Budget > 50 % remaining:** Normal operations. Releases proceed.
2. **Budget 20–50 % remaining:** Warning. Release manager notified.
   No new infrastructure changes.
3. **Budget < 20 % remaining:** Critical. Release freeze. Only hotfixes
   targeting the degraded SLO are allowed.
4. **Budget exhausted:** Incident declared. All hands on reliability.

---

## Release Freeze Protocol

When a freeze is declared:

1. **Stop all non-hotfix deploys** (mobile releases, Edge Function deploys,
   DB migration changes).
2. **Root cause analysis** within 24 hours.
3. **Remediation plan** committed within 48 hours.
4. **Freeze lifted** when the SLO returns to ≥ target for 2 consecutive
   measurement windows, OR the error budget resets (new window).

---

## Monitoring

Error budget burn rate is tracked via:
- Sentry dashboards (crash-free, performance)
- Supabase dashboards (auth, edge functions)
- Firebase console (push delivery)

Automated burn-rate alerts are configured in Sentry.
