# SLO Catalog — Transitly

> **Owner:** Platform team · **Review cadence:** quarterly · **Version:** 1.0

## Overview

6 Service Level Objectives covering the critical user journeys. Each SLO defines
the SLI (metric), the target, and the measurement window.

---

## SLO-1: Login Success Rate

| Field | Value |
|-------|-------|
| **SLI** | `successful_logins / total_login_attempts` over 30 days |
| **Target** | ≥ 99.5 % |
| **Window** | 30 days rolling |
| **Alert** | < 99 % for 1 hour → P2 |
| **Dashboard** | Sentry / Supabase Auth dashboard |

**Rationale:** Login is the gate to all authenticated features. Below 99.5 %
indicates an auth service degradation requiring immediate attention.

---

## SLO-2: Map Initial Render (p95)

| Field | Value |
|-------|-------|
| **SLI** | p95 latency of `map.initial_render` span (ms) |
| **Target** | ≤ 2000 ms |
| **Window** | 7 days rolling |
| **Alert** | p95 > 3000 ms for 1 hour → P3 |
| **Dashboard** | Sentry Performance |

**Rationale:** The map is the core product surface. Users tolerate up to 2s for
cold-start map initialization. Above 3s indicates tile server issues or render
degradation.

---

## SLO-3: Crash-Free Session Rate

| Field | Value |
|-------|-------|
| **SLI** | `crash_free_sessions / total_sessions` over 30 days |
| **Target** | ≥ 99.9 % |
| **Window** | 30 days rolling |
| **Alert** | < 99.5 % for any day → P1 |
| **Dashboard** | Sentry Releases |

**Rationale:** Industry standard for mobile apps. 99.9 % allows ~1 crash per
1000 sessions. Below 99.5 % triggers an immediate release freeze.

---

## SLO-4: Edge Function Success Rate

| Field | Value |
|-------|-------|
| **SLI** | `successful_edge_invocations / total_edge_invocations` |
| **Target** | ≥ 99 % |
| **Window** | 7 days rolling |
| **Alert** | < 95 % for 1 hour → P2 |
| **Dashboard** | Supabase Edge Functions dashboard |

**Rationale:** `send_notification` and `import_gtfs` are critical backend
paths. 99 % accounts for cold starts and occasional timeouts.

---

## SLO-5: Push Notification Delivery (p95)

| Field | Value |
|-------|-------|
| **SLI** | p95 latency from `send_notification` invocation to FCM delivery (s) |
| **Target** | ≤ 30 s |
| **Window** | 7 days rolling |
| **Alert** | p95 > 120 s for 1 hour → P3 |
| **Dashboard** | Firebase Cloud Messaging dashboard |

**Rationale:** Push notifications for incident resolution and route changes
are time-sensitive. 30s p95 accounts for FCM delivery variance.

---

## SLO-6: Auth Token Refresh Success Rate

| Field | Value |
|-------|-------|
| **SLI** | `successful_refreshes / total_refresh_attempts` |
| **Target** | ≥ 99.9 % |
| **Window** | 7 days rolling |
| **Alert** | < 99 % for 1 hour → P2 |
| **Dashboard** | Supabase Auth / Sentry |

**Rationale:** Token refresh failures force users to re-authenticate. 99.9 %
ensures transparent session continuity for the vast majority of users.

---

## Error Budget Policy

See `docs/runbooks/error_budget_policy.md`.

## Release Freeze Policy

See `docs/runbooks/release_freeze_policy.md`.
