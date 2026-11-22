---
phase: 08-release
plan: "14"
subsystem: backend-payments
tags: [long-lead, off-session-charge, d-29, rel-02, backend, not-deployed]
status: complete

requires:
  - phase: 08
    provides: "Plan 08-08: deploy X1 live at 412f1aa (= origin/main), plan 08-11 smoke passed"
provides:
  - "Backend branch ios-p8-x2 (one commit 1d18aac, not pushed): a transient error before createManualPI resets the long-lead stamp and is retried, up to 6 h before the session"
  - "Todo 2026-11-12-long-lead-sweep-transient-errors-after-stamp closed"
affects: [08-16]

actuals:
  tokens: 9000
  tasks: 3
  commits: 1

commits: 1
plan_head_before: 412f1aa649f5aa72fb853e40e87ab5e0998eb926
plan_head_after: 1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594
# The counts above are for the backend repo (the code commit). The iOS repo took two docs commits
# (todo move 670d7ed, then this SUMMARY), from iOS HEAD 29e253b.

tech-stack:
  added: []
  patterns: ["Guarded stamp reset (same guard style as stampAttempt) bounded by a deadline derived from SCA_RECOVERY_WINDOW_MS"]

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend D12/tests/cron/longLeadChargeSweep.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend D12/docs/ios/STRIPE-INTEGRATION.md"
    - ".planning/todos/completed/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md"

key-decisions:
  - "A missing or unreadable start_time counts as NOT beyond the 6 h window: no reset, and the pre-stamp checks stamp before re-throwing. That is the pre-D-29 behavior, the conservative choice for a live-payment path. start_time is selected by the candidate query, so this is a defensive branch only."
  - "Reset is driven by a local flag set immediately before createManualPI, so the reset can only ever happen when no PaymentIntent request was made in this run."

requirements-completed: [REL-02]

duration: one session
completed: 2026-11-22
---

# Phase 08 Plan 14: Retry transient long-lead charge errors (D-29) Summary

**A transient error in the T-24h long-lead charge, after the stamp but before any PaymentIntent exists, now resets the stamp and is retried on the next 5-minute run, up to 6 h before the session; a persistent card-check error follows the same deadline; errors at or after createManualPI are unchanged. One backend commit on `ios-p8-x2`, not pushed.**

## What changed (backend `longLeadChargeSweep.js`)

- `resetStampAttempt(booking, nowIso)`: UPDATE `off_session_attempted_at = NULL` guarded by `id`, `payment_status = 'scheduled'`, `payment_intent_id IS NULL` and `off_session_attempted_at = <this run's stamp>`. A reset that matches no row, or a Supabase error or throw, logs `stamp reset skipped for booking <id>` (booking id only) and the original error is re-thrown.
- `isBeyondRecoveryWindow(booking)`: true only when `start_time - now` is strictly greater than `SCA_RECOVERY_WINDOW_MS`.
- `chargeOne`: `piCallStarted` is set immediately before `createManualPI`. In the final `throw err` path (not SCA, not StripeCardError) the stamp is reset only when `piCallStarted` is false and the session is beyond the window.
- Profiles-read and platform-card-retrieve errors (before the stamp since CR-02) go through `rethrowCheckError`: unstamped re-throw while beyond the window (CR-02 retry unchanged), `stampAttempt` then re-throw within it (a lost claim re-throws without a write).
- The candidate select now includes `start_time`.
- Header, per-row catch comment and the comment above the final re-throw state the D-29 guarantee. `docs/ios/STRIPE-INTEGRATION.md` (the "Card removed inside PaymentSheet" bullet) is updated the same way. No route, response, error code, push or migration change.

## Verification

- RED (Task 1, old code, new rows added): `Tests: 10 failed, 57 passed, 67 total` (the three two-run reset rows, the two reset-skipped rows, the 5 h and boundary stamp rows, the lost-claim row, the one-millisecond-beyond reset row). Log: `/Users/LeonChen/.claude/jobs/b11d00cc/tmp/08-14-red.log`.
- GREEN, targeted (`longLeadChargeSweep.test.js` + `scaRecoveryWindowSweep.test.js`): `Test Suites: 2 passed, 2 total` / `Tests: 67 passed, 67 total`. The D-12 and CR-02 describe blocks pass with their assertions unchanged.
- Full backend suite (`REDIS_URL=redis://localhost:6379 npm test -- --silent`): `Test Suites: 153 passed, 153 total`, `Tests: 3881 passed, 3881 total`. Zero `FAIL ` lines (so none in redis.test.js either). Log: `/Users/LeonChen/.claude/jobs/b11d00cc/tmp/08-14-full.log`.
- `npm run check-docs`: `OK: all 126 endpoints covered 1:1`.
- `git rev-list --count origin/main..ios-p8-x2` = 1; worktree clean; no `supabase/migrations` change; `git show --stat` lists exactly the three backend files.
- The sandbox refused long chained verify commands, so each gate was run as a separate command, and logs went to `/Users/LeonChen/.claude/jobs/b11d00cc/tmp` instead of `/tmp`.

## New test rows (describe `transient error before the PaymentIntent is retried (ios-p8 D-29)`)

- Two runs for each of connected-customer lookup, clone lookup and recheck read errors: run 1 stamps then resets (guards asserted), no PaymentIntent, no cancel; run 2 selects the row again, one stamp, one `createManualPI` with the t24h idempotency key, one confirm, final `requires_capture`.
- Reset matching no row, and reset erroring: nothing further written, booking id only in the log, original error surfaced.
- Deadline: 5 h away leaves the stamp and `scaRecoveryWindowSweep` (via `modelWindowSqlFilter`) selects it after 6 h; exactly 6 h keeps the stamp; 6 h + 1 ms resets.
- Card-check errors: 30 h away is re-thrown unstamped (profiles read, platform-card retrieve); 5 h away stamps and re-throws with no Stripe write and no cancel; boundary exactly 6 h stamps, 6 h + 1 ms does not; a lost claim inside the window re-throws with no further write.
- At or after `createManualPI`: a non-card `createManualPI` error and a non-card `confirmPIOffSession` error do no reset (stamp stays, one `createManualPI` ever); the pre-charge recheck skipping a no-longer-chargeable booking does not reset.

## Deviations from Plan

**1. [Rule 3 - process] Tasks 1 and 2 were built in one pass.** All the D-29 rows (Task 1 and Task 2 behaviors) were written first, one RED run was recorded against the old code, then the whole implementation went in and one GREEN run followed. The tracer gate is satisfied by the end-to-end two-run rows passing, which is the same check Task 1's `<verify>` runs.

**2. [Rule 1 - test fixture] Existing test fixture adjusted.** `makeLongLeadBooking` now defaults `start_time` to 30 h ahead, so the pre-existing rows stay on the "far from the session" path, and the "handles per-row errors without stopping the loop" row queues one more chain (the bad row's reset) and asserts it. Only setup changed; no existing assertion was relaxed or removed, and the D-12 and CR-02 describe blocks are untouched.

**3. Log prefix.** The skipped-reset log reads `[cron:longLeadChargeSweep] stamp reset skipped for booking <id>` (the file's existing prefix) rather than the plan's `[longLeadChargeSweep]`.

**4. Commit trailer.** The backend and iOS commits carry `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` (the attribution this session was given), not the plan's `Claude Opus 5.5`.

**5. Todo commit amended once.** The first todo-close commit missed the Resolution text because it was appended before `git mv` (the index held the old blob); the unpushed commit was amended to include it. Final: `670d7ed`.

None of these changes behavior beyond the plan.

## Preconditions and gates

- Precondition met: `git fetch origin` succeeded, backend `origin/main` = `412f1aa649f5aa72fb853e40e87ab5e0998eb926` = the SHA plan 08-08 deployed, and a read-only `GET /health` returned `{"status":"success","commit":"412f1aa"}`. The worktree was clean.
- `ios-p8-x2` was created from `origin/main` (412f1aa), so the 08-16 push is a fast-forward.
- Nothing was pushed to any remote (backend or iOS). Deploy is plan 08-16 with the user's own approval.
- STATE.md and ROADMAP.md were not touched.

## Known Stubs

None.

## Threat Flags

None. The change adds no endpoint, auth path, file access or schema change. T-08-28 (double charge / stranded hold): reset is flag-gated before `createManualPI` and guarded by `payment_intent_id IS NULL` and this run's stamp; post-PaymentIntent errors unchanged; tests assert one `createManualPI` per booking. T-08-29 (session starts uncharged): 6 h deadline for resets and card-check errors with strict-inequality boundary rows. T-08-30: logs carry the booking id only (a test asserts no `pm_`, `pi_` or `cus_` in the reset-skipped log).

## Self-Check: PASSED

- FOUND: backend commit `1d18aac` (branch `ios-p8-x2`, one ahead of origin/main 412f1aa)
- FOUND: iOS commit `670d7ed` (todo moved to completed with Resolution)
- FOUND: `/Users/LeonChen/Documents/ClickMe2026/.planning/todos/completed/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md`; pending copy gone
- FOUND: `resetStampAttempt` in `longLeadChargeSweep.js`, `ios-p8 D-29` describe in the test file
