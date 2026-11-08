---
phase: 01-backend-fixes
plan: 13
subsystem: payments
tags: [stripe, booking, confirm, idempotency, payment-intent, zod, express, jest, openapi, wave-2]

requires:
  - phase: 01-backend-fixes
    provides: "01-12 is the prior wave 2 plan on master; 01-07 added the free-path duration check that this plan mirrors on the paid path"
provides:
  - "POST /bookings/confirm replays 201 with the same booking_id and the current status when the same client retries an active booking"
  - "Concurrent confirms for one payment intent both end in 201 with one booking, answered from Step 3, 23505 or 23P01, and the 23P01 replay keeps the winner's slot keys"
  - "POST /bookings/payment-intent returns 409 DUPLICATE_BOOKING with detail.booking_id for the caller's own identical active booking"
  - "POST /bookings/payment-intent rejects a duration_minutes that differs from the topic's duration_mins with 422 VALIDATION_ERROR, before any hold or Stripe call"
affects: [01-15 (wave 2 gate and push), Phase 4 PAY-02, Android DUPLICATE_BOOKING routing]

# Measured in the BACKEND repo, where both code commits live:
# git -C "<backend>" rev-list --count 87d3c62..b982e0b = 2. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (52982 bytes). The iOS repo holds planning
# docs only and had no commits at SUMMARY write (iOS HEAD 9b48a64).
actuals:
  tokens: 13245
  tasks: 2
  commits: 2
plan_head_before: 87d3c622f4552f1eb4f1f1bb284d8f8702c82250
plan_head_after: b982e0ba506a87e9a260c2199ce6471ac2b8c3e0

tech-stack:
  added: []
  patterns:
    - "Replay tests assert the exact list of tables read, which proves no payout, topic, promo or insert work ran"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/booking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/booking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md"

key-decisions:
  - "BACK-15 replays by an ownership-checked lookup on payment_intent_id with no new column and no stored response; only pending_approval, confirmed, pending_reschedule and in_progress replay, with the booking's current status"
  - "On the 23P01 path the replay lookup runs before the slot keys are released, and a lookup error returns 500 and leaves the keys to their 900s TTL because they may be the winner's"
  - "Payment-intent matches the caller's own booking on client, expert, topic and exact start, so an own booking at that time for a different topic stays SLOT_UNAVAILABLE"

patterns-established: []

requirements-completed: [BACK-15]

coverage:
  - id: D1
    description: "A confirm retry by the owner of an active booking returns 201 with the same booking_id, the current status and the four expected keys, with no Stripe call, hold, insert, promo read or dispatch"
    requirement: BACK-15
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-15 ownership-checked replay Step 1: the booking for this PI already exists"
        status: pass
    human_judgment: false
  - id: D2
    description: "The caller's cancelled, declined, expired, completed or missed booking, and any other client's booking, keep the generic 409 DUPLICATE_BOOKING with no detail and no booking id in the body"
    requirement: BACK-15
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-15 ownership-checked replay Step 1: the booking for this PI already exists"
        status: pass
    human_judgment: false
  - id: D3
    description: "The loser of a concurrent confirm is answered by replay from the Step 3 conflict, 23505 or 23P01; the 23P01 replay does not release slot keys; without a replayable booking the existing 409s and the release are unchanged"
    requirement: BACK-15
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-15 ownership-checked replay Step 3: the slot conflict check fires"
        status: pass
      - kind: integration
        ref: "tests/booking.test.js#BACK-15 ownership-checked replay the insert loses the race"
        status: pass
    human_judgment: false
  - id: D4
    description: "Payment-intent answers a conflict with the caller's own identical active booking with 409 DUPLICATE_BOOKING and detail.booking_id, anyone else's with 409 SLOT_UNAVAILABLE, and holds nothing in either case; the lookup is scoped on client_id"
    requirement: BACK-15
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-15 own booking and duration a slot conflict"
        status: pass
    human_judgment: false
  - id: D5
    description: "Payment-intent rejects a mismatched duration_minutes with 422 before any hold, Stripe call or conflict read; a matching duration and a legacy null-length topic still succeed"
    requirement: BACK-15
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-15 own booking and duration duration_minutes must match the topic"
        status: pass
    human_judgment: false
  - id: D6
    description: "OpenAPI and STRIPE-INTEGRATION.md document the replay, the payment-intent 409 with detail.booking_id and the duration 422"
    requirement: BACK-15
    verification:
      - kind: other
        ref: "grep -c 'You already have a booking for this time.' docs/ios/STRIPE-INTEGRATION.md prints 2; npm run check-openapi-coverage reports all 128 endpoints; the YAML parsed"
        status: pass
    human_judgment: false
  - id: D7
    description: "A timed-out confirm on a real device lands on the existing booking on the deployed backend, on build 6 and current Android"
    requirement: BACK-15
    verification: []
    human_judgment: true
    rationale: "Tests use a mocked Stripe and Supabase. The code is not deployed, and the behavior needs the wave 2 smoke check in 01-15, which places real holds."

duration: 7 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 13: Idempotent Confirm Replay Summary

**A retried confirm now returns the client's own booking instead of a false "slot taken", checked by owner and status, and payment-intent points a restarted client to that booking and rejects mismatched durations before any money step.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-08T17:44:13Z
- **Completed:** 2026-11-08T17:50:47Z
- **Tasks:** 2
- **Files modified:** 4 (backend)

## Accomplishments

- **Confirm replay:** `findReplayableBooking(clientId, paymentIntentId)` reads the booking by `payment_intent_id` and returns it only to its own client and only while active. `confirmReplayBody(row)` builds the 201 body from the same two strings as the normal response. Step 1, the Step 3 conflict, 23505 and 23P01 all check it before failing.
- **Race handling:** two concurrent confirms for one payment intent both end in 201 with one booking. The 23P01 replay leaves the slot keys alone, since they belong to the winner.
- **Payment-intent:** a conflict with the caller's own booking for the same expert, topic and start returns 409 `DUPLICATE_BOOKING`, "You already have a booking for this time.", with `detail.booking_id`. Every other conflict stays `SLOT_UNAVAILABLE`.
- **Duration:** a `duration_minutes` that differs from the topic's `duration_mins` returns 422 before the conflict read, the hold and Stripe. Slot keys and end time now come from the topic.

## Task Commits

Backend repo, branch `master`. Nothing was pushed: `origin/main` is still `a92acba`, and master is 7 commits ahead of it.

1. **Task 1: Ownership-checked replay in POST /bookings/confirm** - `7aa4297` (fix)
2. **Task 2: payment-intent recognizes the caller's own booking and validates duration; document both** - `b982e0b` (fix)

**Plan metadata:** recorded by the iOS repo docs commit for this summary.

## Verification

| Gate | Result |
|------|--------|
| `npm test -- tests/booking.test.js tests/contract.responseShapes.test.js` (Task 1) | 2 suites passed, 161 tests passed |
| `npm test -- tests/booking.test.js tests/services/stripePaymentsContract.test.js` (Task 2) | 2 suites passed, 177 tests passed |
| Full gate `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | 126 suites passed, 2899 tests passed, with no flaky failures on this run |
| `npm run check-openapi-coverage` | All 128 endpoints present |
| OpenAPI YAML parse | Parsed |
| `grep -c "You already have a booking for this time." docs/ios/STRIPE-INTEGRATION.md` | 2 (baseline 0) |

`tests/services/redis.test.js` was excluded because it needs `REDIS_URL`. All tests use a mocked Stripe and Supabase, so nothing touched production and the behavior is unproven on a deployed backend (D7).

**Tests written first:** Task 1's new and updated tests ran before the code: 18 failed and 8 passed. The 8 passes are cases whose answer, 409 `DUPLICATE_BOOKING`, did not change. Task 2's new tests also ran before the code: 6 failed and 1 passed. Two of those 6 failures, the matching-duration and legacy-topic cases, were not evidence of missing behavior, because those paths already worked. They expected 2 held slot cells where a 60-minute topic holds 3, and I corrected them to 3. Each task is one commit, as the plan specifies, so there are no separate `test(...)` commits. The plan is `type: execute`, so the `tdd-red-evidence` classifier was not run.

## Files Created/Modified

- `src/controllers/booking.controller.js` - `ACTIVE_BOOKING_STATUSES`, `findReplayableBooking`, `confirmReplayBody`, `findOwnActiveBooking`, and the changes to `confirm` and `createPaymentIntent`
- `tests/booking.test.js` - two new describe blocks, plus three existing tests updated
- `openapi/clickme-api.yaml` - replay on confirm; 409 with `detail.booking_id` and duration 422 on payment-intent
- `docs/ios/STRIPE-INTEGRATION.md` - the same three points in sections 2.1, 2.2 and 6, plus the retry table

## Decisions Made

- The replay looks up the existing booking by `payment_intent_id`, with no new column and no stored response, as the plan chose under CONTEXT's discretion item.
- The replay body reports the booking's current status with the original message, so a retry after the expert accepted returns `confirmed`. iOS build 6 decodes all four active values.
- A failed replay lookup returns 500 rather than a 409 or a success. On the 23P01 path it also skips the release, so the keys wait for their 900s TTL, because they may be the winner's.
- Compatibility of `detail.booking_id` was read from the client code. iOS `StandardErrorResponse` ignores `detail`, and Android `ApiErrorEnvelope` has `detail` as an open map, so the new error decodes on both.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated three existing tests whose expectations the plan changes**
- **Found during:** Tasks 1 and 2
- **Issue:** two confirm tests expected 409 for an existing booking, using fixtures with no `client_id`. They would have kept passing by being treated as foreign bookings, under titles that no longer described the behavior. "A padded conflict short-circuits" failed because a payment-intent conflict now makes one more read.
- **Fix:** the two confirm tests now use the owner's booking and assert the 201 replay and the short-circuit. The conflict test has a mock for the new read, and its assertions are unchanged.
- **Files modified:** `tests/booking.test.js`
- **Verification:** full gate passes
- **Committed in:** `7aa4297`, `b982e0b`

**2. [Rule 2 - Missing Critical] Extra coverage beyond the listed behavior lines**
- **Found during:** Task 1
- **Issue:** the plan's behavior list does not cover a failed replay lookup, a case-different owner id or a `missed` booking.
- **Fix:** added tests for each. `missed` is not in the active set, so it keeps the 409.
- **Files modified:** `tests/booking.test.js`
- **Verification:** tests pass
- **Committed in:** `7aa4297`

### Small additions the plan implies but does not list

- `findOwnActiveBooking` is a private helper for the payment-intent lookup. The plan's artifact table does not name it.
- `isSlotConflicted` now uses `ACTIVE_BOOKING_STATUSES` instead of its inline array, with the same values.
- Step 1 makes two reads on the retry path, because the plan keeps the existing select and calls `findReplayableBooking` after it. The first-time path still makes one.

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical).
**Impact on plan:** test changes only. No scope added to production behavior.

## Issues Encountered

- A failed `&&` chain in my shell command wrote the plan ledger file to the iOS repo's `.git` directory. I deleted it and wrote the ledger to the backend's git directory, where the code commits live. No tracked file was affected.
- Two out-of-scope findings are logged in `deferred-items.md`. The more important one: when `confirm`'s insert fails with no replay (another client won the slot), the authorized PaymentIntent is not voided by this handler, so the hold appears to stay on the card until it expires. This predates the plan, I did not check whether a webhook or sweep handles it, and it is worth a decision before Phase 4 payment UAT.

## Threat Coverage

| Threat | Result |
|--------|--------|
| T-01-26 replay disclosure | `findReplayableBooking` returns a row only when `isSameUser(row.client_id, clientId)`; tests assert foreign responses have no `detail` and no booking id |
| T-01-27 financial tampering | Replay returns before `retrievePI`, `confirmPI`, the insert, promo and dispatch, and the 23P01 replay keeps the slot keys; tests assert each |
| T-01-28 payment-intent detail | The lookup filters on `client_id = req.user.id`; a test asserts the filters |

No new security surface outside the threat model.

## User Setup Required

None. No migration and no new environment variable. These commits go out with wave 2: the handoff and smoke check are in 01-15, and the user pushes (D-11).

## Next Phase Readiness

- Ready for 01-14, the remaining wave 2 work.
- Phase 4 PAY-02 can route `409 DUPLICATE_BOOKING` from payment-intent to `detail.booking_id`.
- Android follow-up logged: read `detail.booking_id` on that 409 to open the existing booking. Android already maps the code, so nothing breaks without it.

## Self-Check: PASSED

- All four modified files exist in the backend repo.
- `git merge-base --is-ancestor` confirms `7aa4297` and `b982e0b` are on backend `master`.
- `git rev-list --count 87d3c62..b982e0b` is 2, matching `actuals.commits`.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*
