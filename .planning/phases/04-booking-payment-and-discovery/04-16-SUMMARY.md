---
phase: 04-booking-payment-and-discovery
plan: 16
subsystem: payments
tags: [stripe, cron, off-session-charge, backend, gap-closure, cr-02, d-12]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "04-01 D-12: platform-card check in longLeadChargeSweep.chargeOne (backend ae3ec1a)"
provides:
  - "Backend 28da165: profiles read and platform-card check run before stampAttempt in chargeOne, so a transient error leaves the row unstamped and the next 5-minute run retries it"
  - "A profiles read error is re-thrown (no null-customer fallback); a card whose customer is not the profile's stripe_customer_id, a profile with none included, counts as gone (confirmLongLead's ownership rule)"
  - "Two-run tests that also run scaRecoveryWindowSweep; profiles-error rows for attached, foreign and detached cards; call-order and lost-claim rows"
  - "Comments and docs/ios/STRIPE-INTEGRATION.md state the real guarantee"
  - "Merge todo names the CR-02 commit; follow-up todo for transient errors after the stamp"
affects: [04-VERIFICATION, 04-14-device-uat, backend-master-merge]

actuals:
  tokens: 70000
  tasks: 3
  commits: 1
plan_head_before: 2d08a686e21f434689253a404b97327332a4b930
plan_head_after: 15e7a9b7e49046ad9bb4e1fabad4fd698501104f

key-files:
  created:
    - .planning/todos/pending/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md
  modified:
    - .planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md
    - "backend (ClickMe2026 Backend D12, branch ios-p4-d12): src/cron/longLeadChargeSweep.js"
    - "backend: tests/cron/longLeadChargeSweep.test.js"
    - "backend: docs/ios/STRIPE-INTEGRATION.md"

key-decisions:
  - "Fix shape is the reorder (read-only checks before the single claim), not a stamp reset after a failed check: one claim per run, no new DB write"
  - "A profiles read error is retried on the next run instead of degrading to a null customer; a missing stripe_customer_id is a mismatch, the same rule as confirmLongLead at insert"
  - "Transient errors after the stamp are out of scope and recorded in a follow-up todo (T-04-45)"
  - "A persistent check error is retried every 5 minutes with no deadline (T-04-44), accepted by the user before the push"

requirements-completed: []

duration: multi-session (user deploy wait)
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 16: CR-02 platform-card check before the stamp Summary

**The T-24h sweep now reads the client's platform customer and the saved card before it stamps the booking, so a transient Stripe or database error at that check is retried on the next 5-minute run instead of being cancelled six hours later. Live in production as backend commit `28da165`, the only commit added on top of D-12.**

## Accomplishments

- CR-02 closed for the card check. In `chargeOne` the order is now: no-card branch unchanged, profiles select (error logged and re-thrown), `retrievePaymentMethod`, one `stampAttempt` claim, then the cancel (card gone) or the charge. Only read-only calls run before the claim.
- A profiles read error no longer falls through with a null customer. That fallback skipped the foreign-card comparison and could have let a card attached to another customer be cloned and charged. The gone test now treats a missing `stripe_customer_id` as a mismatch.
- Tests prove both runs: run 1 leaves the stamp NULL and cancels nothing; the 6 h window sweep's query (`eq payment_status scheduled`, `lte off_session_attempted_at cutoff`) cannot match a NULL stamp; run 2 stamps once and creates one PaymentIntent. The NULL-never-matches step is Postgres semantics, modelled by the `modelWindowSqlFilter` helper, not proved by the test.
- Comments in `longLeadChargeSweep.js` and the "Card removed inside PaymentSheet" bullet in `docs/ios/STRIPE-INTEGRATION.md` now say what is guaranteed: a card-check error is retried; only errors after the stamp still reach the 6 h window.
- No route, response field, error code or push payload changed, so App Store build 6 and the current Android build are unaffected. No iOS or Android code changed.

## Task Commits

1. **Task 1 (tracer): transient card-check error leaves the booking unstamped** - folded into the single CR-02 backend commit, per plan (one commit per repo per change).
2. **Task 2: comments, contract note, todos, single CR-02 commit** - backend `28da165ebe66a973008560f689c469389279c25f` on `ios-p4-d12` (`fix(ios-p4): retry the T-24h platform-card check instead of cancelling (CR-02)`, three files); iOS `15e7a9b7e49046ad9bb4e1fabad4fd698501104f` (`docs(04-16): record the CR-02 commit and the post-stamp transient-error follow-up`, two todo files).
3. **Task 3 (checkpoint:human-action): user deploy and confirmation** - no commit; the user ran the guarded push (below).

`commits: 1` is measured in the iOS repo (`2d08a68..HEAD` at SUMMARY write); the backend commit is in the other repo.

## Test evidence

| Run | Result |
|-----|--------|
| Baseline (longLeadChargeSweep + scaRecoveryWindowSweep suites, before changes) | 45/45 passed |
| RED (new CR-02 rows on the old order) | 14 failed, 24 passed of 38 (run 1 wrote the stamp; in the profiles-error rows the attached and foreign cards were charged and the detached card cancelled in run 1) |
| GREEN (cron suites after the reorder) | 50/50 passed |
| Full backend suite, D12 worktree | 153 suites, 3809 tests passed |
| `check-docs` | OK, 126 endpoints |

## Master state re-derived in Task 2

Recorded in the merge todo: master tip `c3c6ebc`, merge base `32fa6ec`, 14 commits ahead of the base, D-12 not an ancestor of master, and the three-file diff `32fa6ec..master` empty (no conflict expected in the CR-02 files). Re-check at the 2026-11-12 close of this plan: `origin/main..master` is 14 commits and none of them has an `ios-p4` subject (nothing went to master).

## Task 3: user deploy and confirmation

- **Q-CR02 (read-only, run by the user):** `select ... from bookings where payment_status = 'scheduled' and off_session_attempted_at is not null and payment_intent_id is null;` returned **0 rows**. No booking was found already in the CR-02 state.
- **Push:** the user ran the guarded one-line script (fetch; `origin/main == ios-p4-cr02-rollback`; ancestor check; exactly 1 commit; exactly the 3 files). Output: `ae3ec1a..28da165  28da165ebe66a973008560f689c469389279c25f -> main`.
- **Rollback base:** `ios-p4-cr02-rollback` = `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d`.
- **Resume-time verification (Claude, read-only):**
  - `origin/main` == `ios-p4-d12` == `28da165ebe66a973008560f689c469389279c25f` (pass)
  - `ios-p4-cr02-rollback..origin/main` = 1 commit; changed files exactly `docs/ios/STRIPE-INTEGRATION.md`, `src/cron/longLeadChargeSweep.js`, `tests/cron/longLeadChargeSweep.test.js` (pass)
  - `ae3ec1a` is still an ancestor of `origin/main` (pass)
  - `/health` returned `{"status":"success","commit":"28da165"}` (pass)
  - The merge todo names the deployed SHA (3 occurrences) and "ios-p4 CR-02" (2 occurrences) (pass)
  - Master unshipped: `origin/main..master` = 14 commits, 0 with `ios-p4` (master was not pushed)
  - Optional deploy-window query: no result was reported; it was optional and is not claimed.
- No Railway logs were shared, so the check for a new `[cron:longLeadChargeSweep]` error spike was not done.

### Step 6 re-check against the shipped code (D12 worktree, clean, on `ios-p4-d12`)

- `longLeadChargeSweep.js` `chargeOne`: the profiles-error log (chargeOne line 34) and its `throw new Error('profiles lookup error: ...')` (line 37) sit above the main `stampAttempt` (line 68; line 8 is the no-card branch's stamp). A persistent profiles fault is retried like a card-check fault and never stamped.
- Candidate query `.is('off_session_attempted_at', null)` at `longLeadChargeSweep.js:127`; `start_time` appears 0 times in `sweepLongLeadCharges`, so there is no start-time bound.
- `bookingStatusSets.js:25` chargeable = confirmed, pending_reschedule; `:52` joinable = confirmed, in_progress, completed.
- `scaRecoveryWindowSweep.js:72` `lte('off_session_attempted_at', cutoffIso)`: the 6 h window selects only stamped rows.
- `call.controller.js:94` joining checks booking status, not payment.
- `expirePastSessions.js:190` capture takes only `requires_capture` rows; `:346` a missed session calls `cancelScheduledPayment`.

### Limits as stated to the user before the push, and accepted

The user replied "Q-CR02 0 rows, limits accepted", accepting:

- (a) A profiles read error or platform-card check error that persists is retried every 5 minutes with no deadline; that booking is neither charged nor cancelled until the error clears (logged per run with its booking id). A database fault now delays the charge instead of letting an unverified card be charged.
- (b) If the error lasts past the session start, nothing cancels the booking (the 6 h window never sees an unstamped row). While the booking is still confirmed the sweep keeps retrying, so a charge can land after the start. Joining checks only booking status, so the session can go ahead with no PaymentIntent and no hold; once the call connects or the session completes the sweep stops, the completion capture takes only `requires_capture` rows, and the session is delivered uncharged with the expert unpaid. If nobody joins, the booking is marked missed after the end time and the scheduled payment is cancelled with no charge.
- (c) Errors after the stamp still cancel at about 6 h (T-04-45, `.planning/todos/pending/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md`).

## 04-VERIFICATION truth 17: PARTIALLY CLOSED, not VERIFIED

"D-12: a removed card is refused at T-24h and a transient Stripe error never cancels."

- Closed (CR-02 tests, live in production): a transient Stripe error or a profiles read error at the profiles read and the platform-card check no longer cancels a booking, in the same run or through the 6 h window.
- Still open end to end: a transient error after the stamp (connected customer, clone, pre-charge recheck, `createManualPI`, a non-card confirm error) leaves the row stamped with no PaymentIntent and `scaRecoveryWindowSweep` cancels about 6 h later. This predates D-12 and is tracked in the follow-up todo. Real-Stripe proof of the whole path remains the D-11 session. Phase re-verification will re-score the truth.

## Requirements

D-12 is a decision with no REQUIREMENTS.md row, so `requirements-completed` is empty. BACK-06, BACK-07, BACK-15 and BACK-19 stay Pending until the D-11 session. PAY-02 is not marked complete here; phase re-verification is pending.

## Deviations from Plan

None - plan executed as written. The Task 1 tracer commit was folded into Task 2's single backend commit, as the plan specifies. Work resumed after the Task 3 checkpoint in a new executor; Tasks 1 and 2 results above come from the prior executor's handoff, and only Task 3 verification and this SUMMARY were done in this session.

## Known Stubs

None.

## Threat Flags

None. The change reorders existing reads and adds no new endpoint, auth path or schema.

## Self-Check: PASSED

- Backend commit `28da165ebe66a973008560f689c469389279c25f` is `origin/main` and `ios-p4-d12` (verified).
- iOS commit `15e7a9b7e49046ad9bb4e1fabad4fd698501104f` exists on `main`.
- Both todo files exist in `.planning/todos/pending/`.
