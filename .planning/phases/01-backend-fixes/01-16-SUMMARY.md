---
phase: 01-backend-fixes
plan: 16
subsystem: payments
tags: [stripe, saved-cards, connect, clones, default-card, express, jest, openapi, wave-3a]

requires:
  - phase: 01-backend-fixes
    provides: "01-15 closed wave 2; production and master were both at ddfe5bf when this plan started"
provides:
  - "GET /me/payment-methods makes a lone card with no default the Stripe default and returns it with is_default true; a failure there is still a 200 with is_default false"
  - "DELETE /me/payment-methods/:id returns 409 PAYMENT_METHOD_IN_USE, and changes nothing, when an active booking of the caller's references the card"
  - "A card with no dependent booking has its connected-account clones detached and its connected_pm_clones rows deleted before the platform card is detached"
  - "evictClonesForPlatformPaymentMethod, the single allowed eviction path, and detachPaymentMethod(pmId, stripeAccountId?)"
  - "After a delete, a lone remaining card becomes the default; a deleted default with two or more cards left is cleared"
affects: [01-17 (wave 3a handoff and saved-card smoke), Phase 4 payment methods UI, Android PAYMENT_METHOD_IN_USE follow-up]

# Measured in the BACKEND repo, where both code commits live:
# git -C "<backend>" rev-list --count ddfe5bf..d356fdc = 2. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (53504 bytes). The iOS repo holds planning
# docs only and had no commits at SUMMARY write (iOS HEAD b2717ea).
actuals:
  tokens: 13376
  tasks: 2
  commits: 2
plan_head_before: ddfe5bf338b12f9af1518ed1c09606269678a1b5
plan_head_after: d356fdc8475e69f3a15d686f62133a6335acf514

tech-stack:
  added: []
  patterns:
    - "The clone cache stays append-only for every booking path; one guarded function evicts, and only DELETE /me/payment-methods/:id calls it"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/stripe.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/connectedPaymentMethodClone.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/paymentMethods.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/stripe.paymentMethods.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/services/connectedPaymentMethodClone.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/paymentMethods.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md"

key-decisions:
  - "BACK-07: an in-use card returns 409 PAYMENT_METHOD_IN_USE for bookings in pending_approval, confirmed, pending_reschedule or in_progress, with no time filter (user decision, Open Q3)"
  - "BACK-07: a Stripe error other than resource_missing or payment_method_unexpected_state stops the delete with a 502 and keeps the card saved"
  - "BACK-06: once the card is detached, a failure to list the remaining cards or promote one does not fail the DELETE, because a retry would 404 and clients would put the removed card back on screen; GET promotes on its next read"
  - "D-13 deviation (user decision 2026-11-07, Open Q7): no local live-Stripe run because no non-production Supabase exists; verified with mocked Stripe here and the post-deploy smoke in 01-17"

patterns-established: []

requirements-completed: [BACK-06, BACK-07]

coverage:
  - id: D1
    description: "GET promotes a lone card with no default and returns is_default true; an existing default, two cards, zero cards and a caller with no customer promote nothing; a failed promotion is a 200 with is_default false"
    requirement: BACK-06
    verification:
      - kind: integration
        ref: "tests/paymentMethods.test.js#GET /api/v1/me/payment-methods lone-card default (BACK-06)"
        status: pass
    human_judgment: false
  - id: D2
    description: "DELETE returns 409 PAYMENT_METHOD_IN_USE with the agreed message and touches nothing when an active booking uses the card; the query uses the exact status list, is scoped to the caller and has no time filter; a DB error is a 500 and detaches nothing"
    requirement: BACK-07
    verification:
      - kind: integration
        ref: "tests/paymentMethods.test.js#DELETE /api/v1/me/payment-methods/:id in-use block (BACK-07)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Eviction detaches each clone on its own connected account and deletes its row by id; already-gone codes are tolerated, any other Stripe error stops with that row kept, no rows means no Stripe call, and a select or delete error rejects with dbError"
    requirement: BACK-07
    verification:
      - kind: unit
        ref: "tests/services/connectedPaymentMethodClone.test.js#evictClonesForPlatformPaymentMethod (BACK-07)"
        status: pass
      - kind: unit
        ref: "tests/stripe.paymentMethods.test.js#detachPaymentMethod"
        status: pass
    human_judgment: false
  - id: D4
    description: "DELETE evicts before the platform detach, and a rejected eviction leaves the card saved; a foreign or missing card is a 404 with no bookings query and no eviction"
    requirement: BACK-07
    verification:
      - kind: integration
        ref: "tests/paymentMethods.test.js#DELETE /api/v1/me/payment-methods/:id clone eviction (BACK-07)"
        status: pass
    human_judgment: false
  - id: D5
    description: "After a delete, one remaining card becomes the default and two remaining with a deleted default clears it; no test in the file sees a bookings UPDATE"
    requirement: BACK-06
    verification:
      - kind: integration
        ref: "tests/paymentMethods.test.js#DELETE /api/v1/me/payment-methods/:id default after delete (BACK-06)"
        status: pass
    human_judgment: false
  - id: D6
    description: "OpenAPI and STRIPE-INTEGRATION.md document the 409, the new error code and the lone-card default"
    requirement: BACK-07
    verification:
      - kind: other
        ref: "grep -c PAYMENT_METHOD_IN_USE reports 4 in openapi and 2 in STRIPE-INTEGRATION.md; check-openapi-coverage and check-doc-coverage report all 128 endpoints; the YAML parsed"
        status: pass
    human_judgment: false
  - id: D7
    description: "On live Stripe with a real card: a clone detach on a connected account works, the already-gone codes are the right ones, and a removed card cannot be charged"
    requirement: BACK-07
    verification: []
    human_judgment: true
    rationale: "All tests mock Stripe and Supabase, and D-13's local test-mode run was dropped by user decision. The behavior needs the post-deploy smoke in 01-17, which uses a real card the user owns."

duration: 6 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 16: Saved-Card Default and Safe Delete Summary

**A lone saved card becomes the Stripe default; deleting a card an active booking uses returns 409 PAYMENT_METHOD_IN_USE; any other delete detaches its connected-account clones and their cache rows before the platform card.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-11-09T00:20:53Z
- **Completed:** 2026-11-09T00:26:55Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Removing a card now also removes its copies on experts' connected accounts, so the T-24h sweep cannot reuse a cached clone of it.
- A card that an active booking depends on stays saved, and the client gets a message it can show.
- A lone card is the default after PaymentSheet adds it and after a delete leaves one card. The default only changes the Stripe customer's `invoice_settings`, so no booking moves to another card.

## Task Commits

Backend repo, branch `master`. Nothing was pushed: `origin/main` is still `ddfe5bf`, and master is 2 commits ahead of it.

1. **Task 1: Connected-account detach and the single allowed clone eviction path** - `0a18772` (fix)
2. **Task 2: Card delete blocks in-use cards, evicts clones, and lone cards become default** - `d356fdc` (fix)

**Plan metadata:** recorded by the iOS repo docs commit for this summary.

## Test Results

| Run | Result |
|-----|--------|
| Task 1 verify: `tests/stripe.paymentMethods.test.js`, `tests/services/connectedPaymentMethodClone.test.js`, `tests/cron/longLeadChargeSweep.test.js` | 3 suites, 60 tests, all passed; sweep tests unchanged |
| Task 2 verify: `tests/paymentMethods.test.js`, `tests/contract.responseShapes.test.js` | 2 suites, 40 tests, all passed |
| Full gate: `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | 128 suites, 2959 tests, all passed, no flakes in this run |
| `check-openapi-coverage`, `check-doc-coverage` | All 128 endpoints covered |

`tests/services/redis.test.js` was excluded because it needs `REDIS_URL`. Every test uses a mocked Stripe and Supabase. No script or call reached production Stripe or Supabase, and no `.env` file was read.

**Tests written first:** Task 1's new tests ran before the code: 8 failed and 28 passed in the two files, and all 8 failures were the new behavior (`evictClonesForPlatformPaymentMethod` missing, detach without the connected-account options). Task 2's ran before the code: 11 failed and 22 passed, and the new tests that passed pin behavior that did not change. Each task is one commit, as the plan specifies, so there are no separate `test(...)` commits. The plan is `type: execute`, so the `tdd-red-evidence` classifier was not run.

## Files Created/Modified

All in `/Users/LeonChen/Documents/ClickMe2026 Backend`.

- `src/services/stripe.js` - `detachPaymentMethod` takes an optional `stripeAccountId`, passed in the options argument
- `src/services/connectedPaymentMethodClone.js` - adds `evictClonesForPlatformPaymentMethod`; the header now records the one exception to append-only
- `src/controllers/paymentMethods.controller.js` - in-use 409, eviction before detach, lone-card default on GET and after delete, updated PM-01 and PM-03 lines and threat ids
- `tests/stripe.paymentMethods.test.js`, `tests/services/connectedPaymentMethodClone.test.js`, `tests/paymentMethods.test.js` - the behavior cases
- `openapi/clickme-api.yaml` - error enum value, DELETE 409, GET and DELETE descriptions
- `docs/ios/STRIPE-INTEGRATION.md` - section 4 rows and a section 6 error row

## Decisions Made

- The eviction failure status is 502 `PAYMENT_PROVIDER_ERROR`, from the existing global handler for Stripe errors. The plan only asked for "an error response". A cache row read or delete failure is a 500.
- Delete settles the default after the detach by re-reading the customer (WR-01) and then listing the remaining cards.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] A failure after the detach does not fail the delete**
- **Found during:** Task 2
- **Issue:** The plan adds a list and a promotion after the platform detach and states non-fatal handling only for GET. If either threw, the client would get an error for a card that is already gone. iOS and Android would keep showing it, and a retry would return 404.
- **Fix:** Listing and promoting after the detach log and continue. If promotion or the listing fails and the deleted card was the default, the default is cleared as today. GET promotes the lone card on its next read.
- **Files modified:** `src/controllers/paymentMethods.controller.js`, `tests/paymentMethods.test.js`
- **Verification:** Two added tests, "still returns 200 and clears the old default when promotion fails after the detach" and "...when listing the remaining cards fails"
- **Committed in:** `d356fdc`

**2. [Rule 3 - Blocking] Two pre-existing tests assumed the old behavior**
- **Found during:** Task 2
- **Issue:** The brand-normalization test used a lone card with no default and expected `is_default` false, which BACK-06 now promotes. The two existing delete tests had no bookings, eviction or list mocks.
- **Fix:** The brand test now has a default elsewhere, and its brand assertion is unchanged. The delete tests queue the new calls and keep their assertions. `beforeEach` also resets the Stripe and query mocks, so an unconsumed `mock...Once` value cannot leak into the next test.
- **Files modified:** `tests/paymentMethods.test.js`
- **Verification:** The file and the full gate pass.
- **Committed in:** `d356fdc`

### Recorded deviation from D-13 (user decision)

D-13 asked for a local backend run with Stripe test-mode keys. The user dropped it on 2026-11-07 (Open Q7): no non-production Supabase exists, and production uses live keys. Stripe behavior here is proven only against mocks. The real check is the 01-17 post-deploy smoke, with a real card the user owns.

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking), plus the recorded D-13 deviation.
**Impact on plan:** All 15 behavior lines hold as written, except that failures after the detach no longer return an error.

## Issues Encountered

Three limits to weigh before the wave 3a push. The first two are logged in `deferred-items.md`.

- **A card can become undeletable.** The plan keeps the card on any Stripe error it does not list. If a client's card has a clone on a connected account that Stripe no longer lets the platform reach, every delete would return 502 until that is resolved. I did not establish which error Stripe returns for a closed or rejected account, and that row is the one that would block.
- **A narrow race remains.** The in-use check and the eviction are separate steps with no lock. A long-lead confirm for the same card landing between them could create a booking, or a new clone row after the eviction. If the clone is cached, the T-24h sweep could charge it. It needs the same client to book and delete the same card at the same moment.
- **Not covered by eviction:** fresh-card confirm Path 3 clones are unattached and never cached, so eviction cannot see them. The code comments describe them as single-use. I took that from the comments and did not test it against Stripe.

Also noted, unchanged: `retrieveCustomer` or `clearDefaultPaymentMethod` failing after the detach still returns an error, as it did before this plan.

## Client Handling (read this session)

- **iOS build 6:** `PaymentMethodsViewModel.deletePaymentMethod` removes the row, and on any error restores the list and shows the server message. Confirmed in the code on `main`. It does not reload after a successful delete, so a newly promoted card shows as default only after the next load. Phase 4 can decide whether that matters.
- **Android:** `remove` reloads only on success, so the card stays on an error. I read `remove` and the start of `runCardOperation`, not the dialog code; that part comes from the plan. Custom copy for the code stays the logged Android follow-up.

## Threat Coverage

| Threat | Result |
|--------|--------|
| T-01-32 deleted card charged via clone | Eviction runs before the platform detach and after the in-use check; tests assert the order. See the race above for the residual |
| T-01-33 IDOR on pm id | Ownership runs first; tests assert a foreign or missing card reaches no bookings query and no eviction, and that the query is scoped to `client_id` |
| T-01-34 Stripe failure during eviction | Accepted: fails closed and the card stays saved; a test asserts no platform detach |
| T-01-35 silent default change | Promotion only calls `setDefaultPaymentMethod`, failures are logged with the message only, and an `afterEach` asserts no bookings UPDATE across the whole test file |
| T-01-SC npm installs | No packages installed |

No new security surface outside the threat model.

## User Setup Required

None for this plan: no migration and no new environment variable. These commits go out with wave 3a. The handoff and the real-card smoke are in 01-17, and the user pushes (D-11).

## Next Phase Readiness

- Ready for 01-17, the wave 3a handoff. Backend master is at `d356fdc`, 2 commits ahead of `origin/main`.
- The 01-17 smoke should confirm that deleting a card with a real clone succeeds on live Stripe, since that call has only been run against mocks.
- Android follow-up already logged: map `PAYMENT_METHOD_IN_USE` on card delete.

## Self-Check: PASSED

- All eight modified files exist in the backend repo.
- `git merge-base --is-ancestor` confirms `0a18772` and `d356fdc` are on backend `master`.
- `git rev-list --count ddfe5bf..d356fdc` is 2, matching `actuals.commits`.
- `git status -sb` showed `master...origin/main [ahead 2]`: nothing pushed.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*
