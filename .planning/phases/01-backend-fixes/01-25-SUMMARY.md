---
phase: 01-backend-fixes
plan: 25
subsystem: payments
tags: [stripe, refund, client-cancel, transactions-ledger, openapi, BACK-19, D-17, gap-closure, mocked-stripe]

requires:
  - phase: 01-backend-fixes/01-24
    provides: "Expert cancel saves the intended refund with refund_failed; refundReconciliation reads the PaymentIntent and Charge first and decides void, refund or clear; backend commits b547f0c and e5243dd"
provides:
  - "Client cancel saves computeRefundAmountMinorUnits with refund_failed when createRefund fails, and returns 200 with refund_amount 0"
  - "Client cancel flags the row (saved amount 0) when retrievePI fails and nothing was refunded, so a possible live hold is voided by the sweep instead of left behind (WINDOWS #10)"
  - "GET /client/transactions reports refunded_amount 0 while refund_failed is true, with the same 12 keys per row"
  - "openapi and the two iOS docs state that refund_amount and refunded_amount are 0 while a failed refund is being retried, and guarantee no completion time"
affects: [01-26 (deploys, records deferred items, closes WINDOWS #8 and #10), Phase 4 payment UAT, BACK-19 verification]

actuals:
  # chars/4 over the '+' lines in backend src and tests (git diff e5243dd..HEAD -- src tests), the same scale as the plan estimate; the docs add about 570 more
  tokens: 3371
  tasks: 3
  # measured: git rev-list --count e5243dd..HEAD in the backend repo
  commits: 3

plan_head_before: e5243dd3559a5553785a35bf8836fc77393b0515
plan_head_after: d86bf97328a81d34b9533b0aee4234fc5522e272

tech-stack:
  added: []
  patterns:
    - "Handler saves the intended amount with the failure flag; the sweep treats a saved amount as intent, never as a fact"
    - "A state read that fails is a reason to flag the row, not to assume no money is owed"
    - "A read path never reports a refund while refund_failed is true"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/clientBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/clientTransactions.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/clientBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/clientTransactions.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/CLIENT-TRANSACTIONS.md"

key-decisions:
  - "The client 24-hour rule is unchanged: intendedRefundMinorUnits is set right after computeRefundAmountMinorUnits, so a captured booking inside 24 hours saves 0 and the sweep never refunds it."
  - "An unreadable PaymentIntent with nothing refunded throws inside the existing try, so the existing catch writes the flag; the sweep decides from the real Stripe state (void a live hold, clear the flag on a captured booking)."
  - "The ledger selects refund_failed but does not return it, and payment_status stays the raw column, so a captured row with a failed refund still reads captured."

patterns-established:
  - "Retry timing is stated once, verbatim, and never without the 24-hour replay caveat; three grep gates enforce it"

requirements-completed: []  # BACK-19 stays Pending: every test mocks Stripe and plan 01-26 has not deployed this. The plan's requirements field is [BACK-19].

coverage:
  - id: D1
    description: "A failed client-cancel refund more than 24 hours out saves the computed amount with refund_failed true and returns 200 with refund_amount 0 and the unchanged response shape"
    requirement: BACK-19
    verification:
      - kind: unit
        ref: "tests/clientBooking.test.js#BACK-19 failed refund or void on a client cancel: 3 days out, PI succeeded, createRefund rejects"
        status: pass
      - kind: unit
        ref: "tests/clientBooking.test.js#BACK-19 ...: confirmed, 3 days out, retrievePI rejects, createRefund rejects"
        status: pass
    human_judgment: false
  - id: D2
    description: "A failed void flags exactly { refund_failed: true }; REFUND_AMOUNT_MISSING on an unreadable PI keeps the amount NULL"
    requirement: BACK-19
    verification:
      - kind: unit
        ref: "tests/clientBooking.test.js#BACK-19 ...: PI requires_capture, cancelPI rejects; a captured booking with a null amount and an unreadable PI"
        status: pass
    human_judgment: false
  - id: D3
    description: "A retrievePI failure inside 24 hours makes no Stripe money call and flags the row with a saved amount of 0; a retrievePI failure that is followed by a working refund or void flags nothing"
    requirement: BACK-19
    verification:
      - kind: unit
        ref: "tests/clientBooking.test.js#BACK-19 ...: confirmed, 2 hours out, retrievePI rejects; 3 days out createRefund resolves; pending_approval voids"
        status: pass
    human_judgment: false
  - id: D4
    description: "The 24-hour rule is unchanged: a working retrievePI on a captured PaymentIntent inside 24 hours makes no Stripe call and sets no flag"
    requirement: BACK-19
    verification:
      - kind: unit
        ref: "tests/clientBooking.test.js#BACK-19 ...: 2 hours out, retrievePI resolves succeeded; and the D-17 regression describe, unedited"
        status: pass
    human_judgment: false
  - id: D5
    description: "GET /client/transactions reports refunded_amount 0 while refund_failed is true and the saved amount once the flag is false or null; the select string contains refund_failed; the row keeps exactly 12 keys and never returns refund_failed"
    requirement: BACK-19
    verification:
      - kind: unit
        ref: "tests/clientTransactions.test.js#reports refunded_amount 0 while refund_failed is true; reports the saved refunded_amount once refund_failed is false; ... is null; selects refund_failed but never returns it"
        status: pass
    human_judgment: false
  - id: D6
    description: "openapi and the iOS docs state that refund_amount and refunded_amount are 0 while a failed refund is being retried, and openapi and STRIPE-INTEGRATION.md guarantee no completion time (30-minute job, replayed Stripe error for 24 hours or more)"
    requirement: BACK-19
    verification:
      - kind: command
        ref: "grep gates: 'being retried' 5 in openapi, 2 in CLIENT-TRANSACTIONS.md; 'When Stripe fails' 1; timing sentence 2 in openapi, 1 in STRIPE-INTEGRATION.md; 30-minute lines without the 24-hour caveat 0"
        status: pass
      - kind: command
        ref: "npm run check-openapi-coverage and check-doc-coverage: OK, all 128 endpoints"
        status: pass
    human_judgment: true
    rationale: "Whether the wording is clear to the iOS and Android teams is a reading judgment. A reviewer should confirm it before the client copy for a failed refund is written."
  - id: D7
    description: "On App Store build 6 and current Android, a cancel response with refund_amount 0 and a ledger row with refunded_amount 0 display without error"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "Backstop truth. It rests on a code read of both clients (iOS decodes only status and message on cancel and a required Int for refunded_amount; Android treats refund_amount 0 as the plain cancelled notice and refunded_amount as a Long defaulting to 0). It was not run on a device or against the shipped build, and Android HEAD 2d04c4ce is not a shipped binary."

duration: ~10min (approximate; the start time was not captured)
completed: 2026-11-09
status: complete
---

# Phase 1 Plan 25: Retry a failed client-cancel refund and stop the ledger overstating it Summary

**A failed client-cancel refund is now saved with the amount the 24-hour rule gave and retried by the plan 01-24 sweep, an unreadable PaymentIntent no longer leaves a live hold with nothing retrying it, and the transactions ledger and docs report 0 until the refund has gone through; all of it proven on mocked Stripe only.**

## Performance

- **Duration:** about 10 min wall clock (approximate, start not captured)
- **Completed:** 2026-11-09
- **Tasks:** 3
- **Files modified:** 7, all in the backend repo (two controllers, two test files, openapi, two iOS docs)

## Accomplishments

- `cancel` in `clientBooking.controller.js` keeps `intendedRefundMinorUnits` (set right after `computeRefundAmountMinorUnits`) and `piReadFailed` (set in the inner `retrievePI` catch). The flag write adds `refund_amount_minor_units` only when the intended amount is not null, and the response amount becomes 0 on any Stripe failure.
- When `retrievePI` failed and the computed refund is 0, the handler throws inside the existing try so the existing catch flags the row with a saved amount of 0. The sweep from 01-24 then voids a live hold or clears the flag on a captured booking. The 24-hour rule, the BACK-12 guard, the atomic UPDATE, the already-cancelled 200, the void branch and the response shape are untouched.
- `clientTransactions.controller.js` selects `refund_failed` and maps `refunded_amount` to 0 while it is true. `refund_failed` is not in the row and `payment_status` stays the raw column.
- openapi (both cancel operations, both `refund_amount` properties, `refunded_amount`), `STRIPE-INTEGRATION.md` (new "When Stripe fails" paragraph) and `CLIENT-TRANSACTIONS.md` (the `refunded_amount` row and a note under the refund-detection list) carry the behavior. The timing sentence appears once per operation or paragraph, verbatim, and the 30-minute figure never appears without the 24-hour replay caveat.

## Task Commits

Backend repo `/Users/LeonChen/Documents/ClickMe2026 Backend`, branch `master`. Nothing pushed, nothing deployed (D-11).

1. **Task 1 (tdd): Client cancel saves the intended amount and flags an unknown PaymentIntent state** - `6dc7256` (fix)
2. **Task 2 (tdd): The ledger reports no refund until it has gone through** - `51f1c0f` (fix)
3. **Task 3 (auto): Document the failed-refund behavior and run the full gate** - `d86bf97` (docs)

**Plan metadata:** recorded in the iOS repo docs commit that adds this file.

Backend `master` is 5 commits ahead of `origin/main` (215adcb): the two 01-24 commits and these three. Every test mocks Stripe.

## TDD Gate Compliance

The plan is `type: execute`, so the RED/GREEN commit gate does not apply; the plan sets one commit per task. RED was still checked for Task 1: with `clientBooking.controller.js` swapped back to HEAD and the new tests kept, 44 tests failed (the new cases plus later cases hit by unconsumed one-shot mocks), and with the new controller back all 156 passed. The swap was done by copying files, not with the RED-evidence classifier. Task 2 was not given a separate RED run.

## Files Created/Modified

- `src/controllers/clientBooking.controller.js` - saves the intended refund, flags an unknown PI state, response amount 0 on failure, docblock updated
- `src/controllers/clientTransactions.controller.js` - selects `refund_failed`, reports `refunded_amount` 0 while it is set, JSDoc sentence added
- `tests/clientBooking.test.js` - new describe "BACK-19 failed refund or void on a client cancel" with 8 cases covering every behavior line plus REFUND_AMOUNT_MISSING
- `tests/clientTransactions.test.js` - 4 new cases, including the select-string and 12-key assertions
- `openapi/clickme-api.yaml`, `docs/ios/STRIPE-INTEGRATION.md`, `docs/ios/CLIENT-TRANSACTIONS.md` - failed-refund wording

## Decisions Made

- The client rule stays as it was. The amount saved on a failure is exactly what the cancel computed, so a captured booking inside 24 hours saves 0 and the sweep clears the flag rather than refunding it.
- An unreadable PaymentIntent is treated as unknown, not as "nothing owed". The handler flags it and lets the sweep read Stripe.
- The ledger hides the unreturned amount at read time instead of changing what the cancel writes, so the sweep still sees the intended amount.

## Deviations from Plan

None - plan executed exactly as written.

One addition inside a planned file, not a behavior change: a test for a captured booking with a null `amount_paid_minor_units` and an unreadable PI, which checks that the flag write stays exactly `{ refund_failed: true }`. The doc notes also added a one-sentence explanation under the refund-detection list in `CLIENT-TRANSACTIONS.md` that a captured row can read `refunded_amount` 0 while a failed refund is being retried.

## Issues Encountered

- A per-plan commit ledger for the backend repo was not written: the `git rev-parse --git-dir` call returned a relative path from the iOS cwd, so the backend base was taken from 01-24's recorded head (`e5243dd`) instead. The `commits` and `plan_head_*` values above are measured from that base with `git rev-list --count`.
- The full backend run passed on the first attempt this time: 130 of 130 suites, 3019 of 3019 tests (3007 before, plus 12 new). The known `connectWebhooks` flake did not appear.
- Tests mock Stripe throughout. Nothing here shows what real Stripe does for a client-cancel refund that is later retried; that stays unproven until the 01-19 checklist is run after 01-26 deploys.
- `scripts/uat-seed-profile.js`, `assets/app-store-screenshots/` and `.planning/` files in the backend were left untracked and out of every commit. Nothing from `wave-3c` was used.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path, file access or schema change. The saved amount comes from `computeRefundAmountMinorUnits` on the client-scoped row, never from the request (T-01-56). No log line was added.

Threat register status: T-01-56 mitigated (tested: 2 hours out saves 0, 3 days out saves 5000); T-01-57 mitigated at the handler level (flag with saved 0, the sweep's behavior is covered by 01-24); T-01-58 mitigated (response 0 after a failure, ledger 0 while flagged, select string asserted).

## User Setup Required

None. No migration: `refund_failed` and `refund_amount_minor_units` already exist.

## Self-Check

Acceptance criteria re-run after the Task 3 commit:

- PASS `tests/clientBooking.test.js` covers all eight behavior lines of Task 1 and passes, including the unchanged within-24-hours case; the D-17 regression and success-path cancel tests pass without edits (156 of 156 in the file).
- PASS `grep -c piReadFailed` on `clientBooking.controller.js` prints 3 (baseline 0); `grep -c intendedRefundMinorUnits` prints 4 (baseline 0, needed at least 3).
- PASS `tests/clientTransactions.test.js` covers the four behavior lines, asserts the select string, and the existing exact-12-key case passes without edits (29 of 29).
- PASS `grep -c refund_failed` on `clientTransactions.controller.js` prints 4 (baseline 0).
- PASS `grep -c "being retried"`: 5 in openapi (needs 3), 2 in `CLIENT-TRANSACTIONS.md` (needs 1); `grep -c "When Stripe fails"` prints 1 in `STRIPE-INTEGRATION.md`.
- PASS `grep -c "every 30 minutes.*24 hours or more"`: 2 in openapi (needs 2), 1 in `STRIPE-INTEGRATION.md` (needs 1).
- PASS `grep -h "every 30 minutes" <three files> | grep -vc "24 hours or more"` prints 0.
- PASS full gate: `REDIS_URL=redis://localhost:6379 npm test` 130 of 130 suites, 3019 of 3019 tests; `check-openapi-coverage` OK for 128 endpoints; `check-doc-coverage` OK for 128 endpoints. The openapi file also parses with js-yaml.
- PASS `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" status --porcelain -- src tests openapi docs supabase` prints nothing.
- PASS `git rev-list --count origin/main..master` prints 5 in the backend; nothing pushed.
- PASS commits `6dc7256`, `51f1c0f` and `d86bf97` are ancestors of backend HEAD; `git rev-list --count e5243dd..HEAD` is 3. No file deletions in any of them.
- PASS the three docs name no field other than `refund_amount` and `refunded_amount`; `refund_failed` does not appear in any response, doc or key list.

## Self-Check: PASSED

## Next Phase Readiness

- Plan 01-26 deploys. WINDOWS #8 (client cancel leaves the amount NULL on a failed refund) and #10 (a client cancel inside 24 hours with a failed `retrievePI` leaves a live hold) are fixed in code on mocked Stripe and ready for that deploy. Do not push before 01-26.
- 01-26 should also record in `deferred-items.md` the two items 01-24 named: a refund Stripe accepted but the bank later fails is not retried anywhere in the backend, and a sweep-keyed refund that fails can replay its error until the key is pruned (at least 24 hours). The "Client cancel can leave a hold with no flag" entry in `deferred-items.md` is still marked open and should be closed there.
- No iOS or Android change is needed: build 6 does not read the cancel `refund_amount`, and 0 is already a value both clients meet for voided, free and already-cancelled bookings. Client copy for a failed refund, if wanted later, must not promise a time.
- BACK-19 stays Pending until the 01-19 checklist has been run on real Stripe.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-09*
