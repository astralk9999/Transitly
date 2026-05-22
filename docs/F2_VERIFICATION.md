# F2 Verification — Build & CI Infrastructure

**Date:** 2026-05-22
**Phase:** F2.11 — Verification
**Baseline:** master

---

## 1. `flutter analyze`

```
27 issues found. (ran in 16.6s)
```

| Severity | Count | Status |
|----------|-------|--------|
| error    | 1     | FAIL |
| warning  | 0     | PASS |
| info     | 26    | PASS |

**Sole error:**

| File | Line | Issue |
|------|------|-------|
| `lib/data/fmtc/fmtc_service.dart` | 89 | `The getter 'tilesCount' isn't defined for the type 'StoreStats'` (`undefined_getter`) |

Root cause: `FMTCStore.stats.tilesCount` references a getter that does not exist on `StoreStats` in the installed `flutter_map_tile_caching` version. Fix expected: either downgrade/pin the FMTC package, or remove/deprecate usage of `tilesCount`.

**Pass criteria:** 0 errors — **NOT YET MET**.

---

## 2. `flutter test`

```
304 tests passed, 1 skipped
```

| Metric | Value | Status |
|--------|-------|--------|
| Total passed | 304 | PASS (\(\ge 304\)) |
| Skipped | 1 (AR Arabic ARB parity) | Known external blocker |
| Test files | 60 | — |

**Pass criteria:** \(\ge 304\) — **MET**.

---

## 3. Migration Files

```
supabase/migrations/*.sql → 14 files
```

| Count | Status |
|-------|--------|
| 14 | PASS |

Migration files present:
- `001_init.sql` through migration numbering up to 14 cumulative files.

---

## 4. Edge Functions

```
supabase/functions/*/index.ts → 4 functions
```

| Function | Path |
|----------|------|
| `purge_old_data` | `supabase/functions/purge_old_data/index.ts` |
| `delete_user` | `supabase/functions/delete_user/index.ts` |
| `send_notification` | `supabase/functions/send_notification/index.ts` |
| `import_gtfs` | `supabase/functions/import_gtfs/index.ts` |

| Count | Status |
|-------|--------|
| 4 | PASS |

---

## 5. Coverage Baseline

```
Global coverage: 24.29% (4229 / 17413 lines)
```

| Metric | Value |
|--------|-------|
| Lines instrumented | 17,413 |
| Lines hit | 4,229 |
| Coverage | 24.29% |

See `docs/COVERAGE_TARGET.md` for per-module targets and the 60% roadmap (F6).

---

## Summary

| Check | Result |
|-------|--------|
| `flutter analyze` 0 errors | **FAIL** (1 error in `fmtc_service.dart:89`) |
| `flutter test` \(\ge 304\) | **PASS** (304 passed + 1 skip) |
| Migrations \(\ge 1\) | **PASS** (14) |
| Edge functions \(\ge 1\) | **PASS** (4) |
| Coverage baseline | 24.29% (baseline for F6) |

**Action required:** Fix the `tilesCount` undefined getter in `lib/data/fmtc/fmtc_service.dart:89` to reach 0 analyze errors.
