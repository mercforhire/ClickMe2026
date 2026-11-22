---
phase: 08-release
plan: "16"
subsystem: backend-deploy
tags: [deploy, production, railway, payments, stripe, d-29, rel-02]

requires:
  - phase: 08
    provides: "Plan 08-14: ios-p8-x2 at 1d18aac (D-29 long-lead retry)"
  - phase: 08
    provides: "Plan 08-08/08-11: deploy X1 live and smoked (412f1aa)"
provides:
  - "Production backend main at 1d18aac (deploy wave X2), live per /health"
  - "Local backend branch ios-p8-x2-rollback at 412f1aa649f5aa72fb853e40e87ab5e0998eb926 (D-16 rollback point)"
affects: [08-18, 08-21]

actuals:
  tasks: 3
  commits: 0

commits: 0

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "D-14: user approved this deploy only (answer verbatim: \"approve\", 2026-11-22), after reporting the stuck-row query"
  - "Stuck-row query (scheduled, off_session_attempted_at set, no payment_intent_id) returned 0 rows (user: \"Success. No rows returned\"), so no existing booking needs a manual fix"
  - "Task 3 run by the orchestrator (an executor will not push on a relayed approval; the user approved directly to the orchestrator)"

requirements-completed: []

duration: user wait
completed: 2026-11-22
---

# Phase 08 Plan 16: Deploy wave X2 Summary

**Production backend moved from 412f1aa (X1) to 1d18aac (D-29 long-lead transient-error retry) as one approved fast-forward, live on /health at 2026-11-22T22:23:02Z, with a rollback branch at 412f1aa.**

## Task 1: Tracer (executor)

- H (/health before) `412f1aa` = origin/main. Rollback branch `ios-p8-x2-rollback` at `412f1aa649f5aa72fb853e40e87ab5e0998eb926`.
- Ancestry: ios-p8-x1, origin/main, `ae3ec1a`, `28da165` are ancestors of ios-p8-x2; `d33c222` is not. No `supabase/migrations` change. Tree clean.
- Dry-run push: `412f1aa..1d18aac -> main` (fast-forward). Edges: none fired.
- Full suite (no REDIS_URL): `Tests: 6 failed, 3875 passed, 3881 total`; only FAIL is `tests/services/redis.test.js` (allowed). In 08-14 with Redis: 3881/3881.
- Gates run as separate commands (sandbox refuses long chains).

Commit deployed: `1d18aac fix(ios-p8): retry transient T-24h errors before the PaymentIntent, up to 6 h before the session (D-29)`. Diff: `docs/ios/STRIPE-INTEGRATION.md`, `src/cron/longLeadChargeSweep.js`, `tests/cron/longLeadChargeSweep.test.js` (3 files, +536 -20).

## Task 2: Approval (D-14, D-29)

- Stuck-row query result, user-reported: 0 rows.
- User answer, verbatim: `approve` (2026-11-22, before 22:22Z).

## Task 3: Push and confirm

- Recheck before push: /health `412f1aa`; origin/main `412f1aa`; ios-p8-x2 `1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594`; tree clean; fast-forward OK.
- Push at 2026-11-22T22:22:09Z: `git push origin 1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594:refs/heads/main` -> `412f1aa..1d18aac` (no --force).
- /health after: `{"status":"success","commit":"1d18aac"}`, live 2026-11-22T22:23:02Z (6th poll). GitHub main = `1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594`. Verify passed.
- Rollback: redeploy `412f1aa649f5aa72fb853e40e87ab5e0998eb926` (`ios-p8-x2-rollback`) in Railway (D-16). Claude does not roll back.

## Deviations from Plan

- Task 3 run inline by the orchestrator; same commands and gates.

## Next

- Plan 08-18: live check of X2 and the backend freeze (also waits on 08-15).
