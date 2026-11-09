---
phase: 01-backend-fixes
plan: 18
subsystem: payments
tags: [stripe, refunds, expert-cancel, express, jest, openapi, wave-3b]

requires:
  - phase: 01-backend-fixes
    provides: "01-17 closed wave 3a; production and master were both at d356fdc when this plan started"
provides:
  - "POST /expert/bookings/:id/cancel refunds amount_paid_minor_units in full on a captured PaymentIntent, at any time before the session, and moves payment_status captured to refunded"
  - "Tests that lock the expert policy and the unchanged client 24-hour rule"
  - "Expert and client refund policies documented in openapi/clickme-api.yaml and docs/ios/STRIPE-INTEGRATION.md"
affects: [01-19 (wave 3b handoff and smoke), Phase 3 EXP-11 and BOOK-08 copy, Android expert-cancel copy follow-up]

# Measured in the BACKEND repo, where both code commits live:
# git -C "<backend>" rev-list --count d356fdc..3899d63 = 2. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (23879 bytes). The iOS repo holds planning
# docs only and had no commits at SUMMARY write (iOS HEAD c35b505).
actuals:
  tokens: 5970
  tasks: 2
  commits: 2
plan_head_before: d356fdc8475e69f3a15d686f62133a6335acf514
plan_head_after: 3899d63ca77828f1b432b1473ed2913fe037c13b

tech-stack:
  added: []
  patterns:
    - "Refund policy belongs to who cancels: expert cancel uses the captured amount directly, client cancel uses computeRefundAmountMinorUnits"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expertBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/clientBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md"

key-decisions:
  - "01-18 BACK-19: the expert cancel captured branch refunds amount_paid_minor_units and always transitions captured to refunded; the amount > 0 guard stays, so a zero amount makes no Stripe call"
  - "01-18 BACK-19: a retrievePI failure on a non-pending booking still falls back to the captured branch, so that case now attempts a full refund at any time; a rejected refund flags refund_failed and the sweep's cancelPI then applies to an uncaptured hold"
  - "01-18 BACK-19: a failed captured refund is not retried by refundReconciliation; left as is because the plan keeps CR-06 untouched, and raised as an open user decision before wave 3b ships"

patterns-established: []

# BACK-19 stays Pending in REQUIREMENTS.md: requirements.ready-ids blocks it because 01-19 also declares it.
requirements-completed: [BACK-19]

coverage:
  - id: D1
    description: "Expert cancel of a captured booking refunds the full amount 2 hours or 3 days out, moves captured to refunded and returns the full refund_amount, including a zero-decimal currency"
    requirement: BACK-19
    verification:
      - kind: integration
        ref: "tests/expertBooking.test.js#D-17 full refund or release"
        status: pass
    human_judgment: false
  - id: D2
    description: "An authorized booking is voided within 24 hours, a free booking makes no Stripe call, a null amount keeps the REFUND_AMOUNT_MISSING path, and a failed refund flags refund_failed and returns 200"
    requirement: BACK-19
    verification:
      - kind: integration
        ref: "tests/expertBooking.test.js#D-17 full refund or release"
        status: pass
    human_judgment: false
  - id: D3
    description: "A second expert cancel that loses the atomic UPDATE returns 409 ALREADY_CANCELLED with no Stripe call"
    requirement: BACK-19
    verification:
      - kind: integration
        ref: "tests/expertBooking.test.js#a second cancel that loses the atomic UPDATE returns 409 ALREADY_CANCELLED with no Stripe call"
        status: pass
    human_judgment: false
  - id: D4
    description: "Client cancel of a captured booking refunds exactly what computeRefundAmountMinorUnits returns, 0 at 2 hours and 5000 at 3 days"
    requirement: BACK-19
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#D-17 regression: client cancel of a captured booking keeps the 24-hour rule"
        status: pass
    human_judgment: false
  - id: D5
    description: "OpenAPI and STRIPE-INTEGRATION.md state both policies and the void-before-capture note"
    requirement: BACK-19
    verification:
      - kind: other
        ref: "check-openapi-coverage and check-doc-coverage report all 128 endpoints; grep -c D-17 reports 2 in STRIPE-INTEGRATION.md; the YAML parsed"
        status: pass
    human_judgment: false
  - id: D6
    description: "Refund and void behavior against real Stripe"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "Only mocked Stripe tests ran (D-13 deviation). The void path can be checked in the 01-19 smoke; the captured branch cannot be reached safely on live data."

duration: 5 min
completed: 2026-11-09
status: complete
---

# Phase 1 Plan 18: Expert Cancel Full Refund Summary

**An expert cancel of a captured booking now refunds the full amount paid at any time before the session, while the client 24-hour rule is unchanged. Committed locally only and proven only against mocked Stripe.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-09T01:01:44Z
- **Completed:** 2026-11-09T01:06:43Z
- **Tasks:** 2
- **Files modified:** 5 in the backend repo

## Accomplishments

- The captured branch of the expert cancel refunds `amount_paid_minor_units` and moves `payment_status` from `captured` to `refunded`. Before, a captured booking starting within 24 hours refunded 0.
- `computeRefundAmountMinorUnits` is no longer imported in `expertBooking.controller.js`. `refund.js` and the client cancel code are unchanged.
- The void, canceled and free paths, the status-guarded UPDATE, CR-06 handling, `cancelScheduledPayment` and the dispatch were not changed.
- Both policies are documented for the client teams.

## Task Commits

Both commits are in the backend repo, on `master`, not pushed:

1. **Task 1: Expert cancel refunds the full captured amount (D-17)** - `ccd586e` (fix)
2. **Task 2: Document the expert-cancel refund policy** - `3899d63` (docs)

## Files Created/Modified

- `src/controllers/expertBooking.controller.js` - full refund in the captured branch, updated docblocks, removed import
- `tests/expertBooking.test.js` - new D-17 cases; removed the old test that expected no refund within 24 hours
- `tests/clientBooking.test.js` - regression cases against the real util
- `openapi/clickme-api.yaml` - expert policy, `refund_amount` description, contrast sentence on the client operation
- `docs/ios/STRIPE-INTEGRATION.md` - policy table in section 2.5, void-before-capture note, EXP-11 and BOOK-08 line

## Verification

- Task 1 gate, `tests/expertBooking.test.js tests/clientBooking.test.js tests/refund.test.js`: 3 suites, 292 tests, all passed.
- Full gate, `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js`: 128 suites, 2968 tests, all passed. This was one run, with no flaky failures, after both tasks' changes and before the docs commit. No source changed after it.
- `check-openapi-coverage` and `check-doc-coverage`: `OK: all 128 endpoints` on both.
- Acceptance grep for `computeRefundAmountMinorUnits(booking)` in code: 0.
- `grep -c "D-17" docs/ios/STRIPE-INTEGRATION.md`: 2.
- **The tests can fail:** with the old 24-hour formula put back in the expert handler and a full refund put in the client handler, the D-17 run failed on the 2-hour expert refund, the zero-decimal refund, the failed refund and the 2-hour client case. Two more failures in that run came from unused mock queue entries leaking between tests. Both controllers were then restored, and the client controller has no diff.
- Backend `status -sb`: `master...origin/main [ahead 2]`. Nothing pushed or deployed.

**TDD:** the tests were written and run before the implementation, and the target cases failed. The plan asks for one commit with all three files, so there is no separate `test(...)` commit. `workflow.tdd_mode` is not set and the plan type is `execute`, so the RED/GREEN gate does not apply.

## Decisions Made

- **Kept the `amount > 0` guard.** A zero amount has nothing to refund, and removing the guard could add a false `refund_failed` flag.
- **Tests use one-shot Stripe mocks.** `jest.clearAllMocks` does not reset implementations, and an earlier test leaves `retrievePI` at `requires_capture`, so a persistent mock would change later tests.

## Deviations from Plan

**1. [Recorded in the plan - D-13] Mocked Stripe tests only**
- No local Stripe test-mode run happened, as the plan's Open Q7 records. The captured branch has never run against real Stripe. The 01-19 smoke can check the void path only. Ledger entry 6.

**2. [Dispatch instruction] Full gate command**
- The plan's `REDIS_URL=redis://localhost:6379 npm test` was replaced by the dispatch's gate, which excludes `tests/services/redis.test.js`. That file needs Redis and was not run. Ledger entry 7.

**3. [Test scope] Extra test cases beyond the behavior list**
- Added a zero-decimal currency case and a failed-refund case in `tests/expertBooking.test.js`. No production code came from them.

**Total deviations:** 0 auto-fixed, 3 recorded. **Impact on plan:** no scope added to production code.

## Issues Encountered

None during execution. See the open items below.

## Open Items for the User

These reach the 01-19 handoff. **The first one needs a decision before wave 3b is pushed.**

1. **A failed refund is not retried as a refund.** When `createRefund` throws, the handler sets `refund_failed` but leaves `refund_amount_minor_units` NULL. `refundReconciliation` reads NULL as a failed void and calls `cancelPI`. On a captured PaymentIntent that call should keep failing every 30 minutes (not run against real Stripe), so the client gets no money unless someone refunds by hand, and the handler's comment that the cron retries is wrong here. The response also reports the full `refund_amount` in this case. The behavior predates this plan and affects client cancels too, but BACK-19 sends more bookings down the path. The plan said to leave CR-06 untouched, so it was not changed. A plain write of the amount in the catch would break the void retry for a `retrievePI` failure on an uncaptured booking. Ledger entry 8 and `deferred-items.md`.
2. **`PATCH /expert/bookings/:id/status` with `cancelled` moves no money.** An expert can mark a past session cancelled while a captured charge stands. D-17 was applied to `POST /expert/bookings/:id/cancel` only. Whether it covers this route is a product question. `accountCascade` was checked and already refunds in full when the user is the expert.
3. **A changed edge:** if `retrievePI` fails on a non-pending booking within 24 hours, the handler now attempts a refund where it used to make no Stripe call. If the PaymentIntent was only authorized, the expected path is a Stripe rejection, then `refund_failed`, then a sweep void. No test exercises that sequence against real Stripe.
4. **Stale comments** in `refund.js`, the `createRefund` docblock in `stripe.js` and `tests/refund.test.js` still describe the old expert rule. They are outside this plan and are logged in `deferred-items.md`.

**Commits on default branches:** backend commits are on `master` as D-11 and the dispatch direct. iOS planning commits are on `main`, where `git.base-branch --is-protected` returns `true`, but `branching_strategy` is `none`, the dispatch named this branch, and plans 01-01 to 01-17 ran the same way. Config was not changed.

## User Setup Required

None. This plan needs no migration or environment variable. Wave 3b is not deployed: the user pushes after the 01-19 handoff (D-11).

## Next Phase Readiness

- Ready for 01-19, the wave 3b handoff. `master` is 2 commits ahead of `origin/main`.
- BACK-19 stays Pending until 01-19 finishes, because that plan also declares it.
- BACK-06 and BACK-07 were not touched and stay Pending. Their code is live, but its real-card smoke was not run.
- The Android expert-cancel copy follow-up is already logged in STATE.md.

## Self-Check: PASSED

- All five modified backend files exist.
- `ccd586e` and `3899d63` are ancestors of backend HEAD.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-09*
