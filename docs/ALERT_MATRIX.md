# Alert Matrix — Transitly

> **Version:** 1.0 · **Owner:** Platform · **Reference:** `docs/slo/slo_catalog.md`

## Severity Levels

| Level | Definition | Response time | Escalation |
|:-----:|-----------|:------------:|-----------|
| **P0** | Complete outage. Core functionality unavailable for all users. | 15 min | All hands |
| **P1** | Critical degradation. Major feature broken for most users. | 30 min | Platform team |
| **P2** | Partial degradation. Feature degraded for some users. | 2 hours | On-call engineer |
| **P3** | Minor issue. Cosmetic or edge case. | Next business day | Backlog |

---

## Alert Catalog

### P0 — Critical

| Alert | Condition | Source | Runbook |
|-------|-----------|--------|---------|
| Crash rate spike >0.5% | `crash_free < 99.5%` for any day | Sentry Releases | [sentry_spike.md](runbooks/sentry_spike.md) |
| Supabase completely unreachable | All queries fail for > 5 min | Supabase status + Sentry | [supabase_down.md](runbooks/supabase_down.md) |
| Auth service down | `login_success < 90%` for 15 min | Supabase Auth + Sentry | [supabase_down.md](runbooks/supabase_down.md) |

### P1 — High

| Alert | Condition | Source | Runbook |
|-------|-----------|--------|---------|
| Map tile server degraded | p95 render > 3s for 1 hour | Sentry Performance | [supabase_down.md](runbooks/supabase_down.md) |
| Edge function failure spike | `success_rate < 95%` for 1 hour | Supabase Edge Functions | [push_down.md](runbooks/push_down.md) |
| Auth token refresh failing | `refresh_success < 99%` for 1 hour | Supabase Auth + Sentry | [supabase_down.md](runbooks/supabase_down.md) |

### P2 — Medium

| Alert | Condition | Source | Runbook |
|-------|-----------|--------|---------|
| Login error rate elevated | `login_success < 99%` for 1 hour | Supabase Auth | [supabase_down.md](runbooks/supabase_down.md) |
| Push delivery delayed | p95 > 120s for 1 hour | FCM dashboard | [push_down.md](runbooks/push_down.md) |
| Error budget < 20% | Any SLO burn rate > 80% | Sentry dashboards | [error_budget_policy.md](runbooks/error_budget_policy.md) |

### P3 — Low

| Alert | Condition | Source | Runbook |
|-------|-----------|--------|---------|
| Map initial render slow | p95 > 2s for 7 days | Sentry Performance | Technical debt backlog |
| Sentry quota approaching | > 80% of monthly quota before mid-month | Sentry Usage | Evaluate sampling rate |
| Storage approaching limit | > 80% of Supabase storage quota | Supabase Dashboard | Purge old data (see [DATA_RETENTION.md](../DATA_RETENTION.md)) |

---

## Notification Channels

| Severity | Channel | Recipients |
|:--------:|---------|-----------|
| P0 | Sentry → Slack `#incidents` + email | Platform team |
| P1 | Sentry → Slack `#incidents` | Platform team |
| P2 | Sentry → Slack `#alerts` | On-call engineer |
| P3 | Sentry issue creation | Backlog triage |

---

## Review Cadence

This matrix is reviewed quarterly with the SLO catalog.
Alerts are tuned based on false-positive rate and incident postmortems.
