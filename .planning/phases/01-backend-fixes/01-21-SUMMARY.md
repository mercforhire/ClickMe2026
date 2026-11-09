---
phase: 01-backend-fixes
plan: 21
subsystem: auth
tags: [expert-gate, stripe-connect, tax-profile, express, jest, wave-3c, BACK-08, BACK-13]

requires:
  - phase: 01-backend-fixes
    provides: "01-20's method-aware expert gate, expertWriteGate export and provisionExpert"
provides:
  - "A 38-route table test pinning every mounted /expert/* route for a client-only account: 17 reads, 20 refused, 1 setup"
  - "postOnboard refuses a caller without the expert role before any payout_accounts or Stripe call"
  - "GET /expert/tax-profile returns 403 EXPERT_SETUP_REQUIRED for a client-only account (option-a, D-08 amendment for this one route)"
affects: [01-22 (OpenAPI 403 on the 20 refused operations, EXPERT-SETUP-GATE.md, route table below), 01-23 (wave 3c handoff and smoke), Phase 5 SIGN-06]

# Measured in the BACKEND repo, where all code commits live:
# git -C "<backend>" rev-list --count bdc580f..e1eb483 = 2. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (35896 bytes). The iOS repo holds planning docs only.
actuals:
  tokens: 8974
  tasks: 2
  commits: 2
plan_head_before: bdc580f5bc995b4acb4dcc822dd82245d721b40c
plan_head_after: e1eb4837fb9f3887b31cac0cfcbc8475939bbef0

tech-stack:
  added: []
  patterns:
    - "A route table test mocks only the controllers, so the real app, routers and gate decide the outcome and a 200 means the request reached that handler"
    - "A money or identity seam repeats the role check inside the controller, so a route edit that drops the gate cannot open it"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertRoutesGate.test.js"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/connect.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/expertTaxProfile.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/connect.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/payouts.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/earnings.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/connect.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertTaxProfile.test.js"

key-decisions:
  - "01-21-D1 BACK-08: GET /expert/tax-profile refuses a client-only account with 403 EXPERT_SETUP_REQUIRED by mounting expertWriteGate. Option-a, decided by the user on 2026-11-07 (reply \"option-a\"). This amends D-08 for this one route only; the other 17 GET routes keep D-08's pass-through. Committed locally at e1eb483, not deployed, mocks only"
  - "01-21 BACK-08: postOnboard refuses a caller whose req.user.roles lacks expert, including missing or empty roles, before any payout_accounts or Stripe call. getConnectStatus and postRefreshLink need no such check because they only act on an existing payout_accounts row and only postOnboard creates one"

patterns-established:
  - "A /expert/* route added or reclassified later must change a row in tests/expertRoutesGate.test.js; moving a row changes a group size, which fails until updated"

# BACK-08 and BACK-13 are also declared by 01-22 and 01-23, so they stay Pending until those have SUMMARYs.
requirements-completed: [BACK-08, BACK-13]

coverage:
  - id: D1
    description: "All 38 mounted /expert/* routes are pinned for a client-only account: 17 reach their controllers with no promotion, 20 return 403 EXPERT_SETUP_REQUIRED without running the controller, and PATCH /expert/profile/setup promotes"
    requirement: BACK-13
    verification:
      - kind: integration
        ref: "tests/expertRoutesGate.test.js (real app and gate, mocked controllers and Supabase)"
        status: pass
      - kind: other
        ref: "REDIS_URL=redis://localhost:6379 npm test (130 suites, 3099 tests, second run; see Verification for the first run)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A client-only account cannot get a Stripe Connect account: refused at the gate, and postOnboard itself refuses roles ['client'], [] and undefined before any database or Stripe call"
    requirement: BACK-08
    verification:
      - kind: integration
        ref: "tests/connect.test.js#postOnboard, called directly — BACK-08 seam"
        status: pass
      - kind: integration
        ref: "tests/expertRoutesGate.test.js#BACK-08 seams, client-only"
        status: pass
    human_judgment: false
  - id: D3
    description: "A client-only account gets 403 from both tax-profile routes, and no TIN is stored"
    requirement: BACK-08
    verification:
      - kind: integration
        ref: "tests/expertTaxProfile.test.js#/api/v1/expert/tax-profile by role — BACK-08"
        status: pass
    human_judgment: false
  - id: D4
    description: "JWT experts and stale-token experts keep every Connect and tax-profile action"
    requirement: BACK-08
    verification:
      - kind: integration
        ref: "tests/expertTaxProfile.test.js (JWT expert, DB-role expert); tests/expertRoutesGate.test.js (JWT expert on all 38 routes, stale token); tests/connect.test.js (existing expert cases)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Build 6 and current Android show their error state with the setup message on GET /expert/tax-profile, instead of the TIN form"
    requirement: BACK-08
    verification: []
    human_judgment: true
    rationale: "Tests use mocks, and no shipped client has run against this response. The wave 3c smoke in plan 01-23 covers it, and nothing is deployed yet."

duration: 5 min
completed: 2026-11-09
status: complete
---

# Phase 1 Plan 21: BACK-08 Seams and Expert Route Classification Summary

**A client-only account can no longer reach a tax-ID prompt through the backend: Connect onboarding is refused at the gate and again in `postOnboard`, both tax-profile routes return 403 `EXPERT_SETUP_REQUIRED`, and a 38-route test pins the final 17 / 20 / 1 classification. Committed locally; not deployed.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-09T02:27:06Z
- **Completed:** 2026-11-09T02:32:47Z
- **Tasks:** 2 of 2
- **Files modified:** 8 (all in the backend repo)

## Accomplishments

- `postOnboard` refuses any caller without the expert role before it touches `payout_accounts` or Stripe, so a later route edit that drops the gate still cannot create a Connect account.
- `GET /expert/tax-profile` now mounts `expertWriteGate`, which closes the one surface left on build 6: Expert, then Profile, then Tax & Payout Info.
- `tests/expertRoutesGate.test.js` drives all 38 routes as a client-only account and again as a JWT expert, and adds the stale-token, setup and BACK-08 cases.
- The `connect.js`, `payouts.js`, `earnings.js` and `expertTaxProfile.js` headers describe the BACK-13 gate instead of convert-on-demand. The first three changed in comments only.

## Decision Record 01-21-D1

**Option-a, chosen by the user on 2026-11-07 (reply "option-a").** `GET /expert/tax-profile` returns 403 `EXPERT_SETUP_REQUIRED` for a client-only account. This amends D-08 for this one route; every other GET keeps D-08's pass-through. `CONTEXT.md` is not edited, per the plan. The tradeoff the user accepted: a client-only user who opens Tax & Payout Info on build 6 sees an error screen rather than an empty form.

## Final Route Classification (client-only account)

**17 reads** reach their controller, with no promotion:

| Routes |
|--------|
| `GET /expert/profile` |
| `GET /expert/topics`, `GET /expert/topics/:id` |
| `GET /expert/booking-requests`, `GET /expert/booking-requests/:id` |
| `GET /expert/bookings`, `GET /expert/bookings/:id/details`, `GET /expert/bookings/:id/summary` |
| `GET /expert/availability` |
| `GET /expert/earnings/weekly`, `GET /expert/earnings/transactions` |
| `GET /expert/payouts/summary` |
| `GET /expert/connect/status` |
| `GET /expert/analytics/summary`, `GET /expert/analytics/trends`, `GET /expert/analytics/popular-topics` |
| `GET /expert/clients/:id` |

**20 refused** with 403 `EXPERT_SETUP_REQUIRED`, and the controller does not run:

| Routes |
|--------|
| `PATCH /expert/profile`, `POST /expert/profile/avatar` |
| `POST /expert/topics`, `PATCH /expert/topics/:id`, `DELETE /expert/topics/:id` |
| `POST /expert/booking-requests/:id/accept`, `POST /expert/booking-requests/:id/decline` |
| `PUT /expert/bookings/:id/takeaways`, `PATCH /expert/bookings/:id/status`, `PATCH /expert/bookings/:id/reschedule` |
| `POST /expert/bookings/:id/cancel`, `/accept`, `/decline`, `/accept-reschedule`, `/decline-reschedule` |
| `PUT /expert/availability` |
| `POST /expert/connect/onboard`, `POST /expert/connect/refresh-link` |
| `POST /expert/tax-profile` |
| `GET /expert/tax-profile` (the one refused read, option-a) |

**1 setup:** `PATCH /expert/profile/setup` validates, then promotes, then runs the controller.

Not in the table: `POST /expert/payouts/withdraw` is a retired 410 with no gate.

## Task Commits

All in `/Users/LeonChen/Documents/ClickMe2026 Backend`, branch `master`, not pushed:

1. **Task 1: Lock the /expert/* classification and close the Stripe Connect seam** - `de662e9` (fix)
2. **Task 2: Refuse GET /expert/tax-profile for client-only accounts (option-a)** - `e1eb483` (fix)

Each task committed its test and code together, because the plan specifies one commit per task with named files. RED results:

- **Task 1:** the 3 direct `postOnboard` cases failed on the planned assertion (the promise resolved instead of rejecting). The route table passed at once, because 01-20's gate already behaves that way, so in Task 1 it locks existing behavior and was not driven by a failure.
- **Task 2:** exactly 3 tests failed, all on the tax-profile GET returning 200: the role case, the BACK-08 route case and the moved table row. The moved row failing shows the table catches a route that differs from its classification.

## Verification

| Check | Result |
|-------|--------|
| Task 1 targeted (`expertRoutesGate`, `connect`, `payouts`, `earnings`) | 4 suites, 128 tests, all passed |
| Task 2 targeted (`expertTaxProfile`, `expertRoutesGate`) | 2 suites, 108 tests, all passed |
| `REDIS_URL=redis://localhost:6379 npm test`, first run | **130 suites: 2 failed. 3099 tests: 16 failed** (see below) |
| `REDIS_URL=redis://localhost:6379 npm test`, second run, same code | 130 suites, 3099 tests, all passed |
| `check-openapi-coverage` and `check-doc-coverage` | `OK: all 128 endpoints` on both |
| Acceptance greps for Tasks 1 and 2 | All pass; route changes in Task 1 are comment-only |
| Backend `git status -sb` | `master...origin/main [ahead 5]`; nothing pushed, nothing deployed |

**First full run failures.** Neither failing file is one this plan changed. Rerun alone, each passed: `connectWebhooks.test.js` 107 of 107, `expertBooking.test.js` 143 of 143.

- `tests/expertBooking.test.js`, 1 test: `Reschedule accept/decline + enrichment (quick 260804-0sb) — expert › POST /api/v1/expert/bookings/:id/accept-reschedule › slot_keys (quick 260804-qo6): sets NEW keys in the guarded UPDATE and releases OLD holds (array form)`. It reported "Expected: 4, Received: 3". There is a likely cause, read from the code and not reproduced: `futureStart` and `futureEnd` call `Date.now()` separately, so a millisecond tick between them makes the duration 60 minutes plus 1 ms. Logged in `deferred-items.md`.
- `tests/connectWebhooks.test.js`, 15 tests. The one 5 s timeout was `charge.dispute.closed: account mismatch is an ACK, never a park (200, single SELECT, no fee reversal)`. Root cause not established. The rest:
  - `charge.dispute.* — WHK-04`: `WR-01: a { error } on reconcileDisputeCreated's bookings.dispute_status write yields 500, markProcessed not called`
  - `charge.refunded (direct)`, 8 tests: backfills `stripe_charge_id`; already `refunded` no-op; `payment_intent_id` fallback; fully refunded from `captured`; fully refunded from `partially_refunded`; no booking row on either lookup; `payment_model 'legacy'`; `transition()` generic Error
  - `WHK-03 canonical re-fetch`, 5 tests: `account.updated`, `charge.dispute.created`, `payout.failed`, `payout.paid`, `payout.updated`

This verifies the code against mocks only: no client and no real Supabase or Stripe has run against these changes.

## Files Created/Modified

- `tests/expertRoutesGate.test.js` - the 38-route table and the JWT expert, stale-token, setup and BACK-08 cases
- `src/controllers/connect.controller.js` - the `postOnboard` role check and the header's threat list
- `src/routes/expertTaxProfile.js` - the GET's write gate and the refreshed header
- `src/routes/connect.js`, `src/routes/payouts.js`, `src/routes/earnings.js` - headers only
- `tests/connect.test.js` - `postOnboard` called directly with each role value
- `tests/expertTaxProfile.test.js` - mutable auth user, `profiles` table handling in the Supabase mock, and the role cases

## Decisions Made

- Beyond the plan's list, the route test also runs all 38 routes as a JWT expert and asserts none is refused and no `profiles` read happens. The plan requires that experts keep their actions, and this is the broadest cheap proof. A validated route may answer 422 there because the request has no body.
- In `payouts.js`, the plan's replacement dropped "Both routes require ensureExpert", which was already wrong: only the summary route is gated.

## Deviations from Plan

None - plan executed exactly as written.

**Plan text note:** the plan's verify commands for targeted suites omit `REDIS_URL`. All runs here set it, per the orchestrator's instruction.

## Issues Encountered

None blocking. Two items are logged in `deferred-items.md`: the likely cause of the `expertBooking` flake, and the `ensureExpert.js` header not mentioning the one read that uses the write gate (comment only; 01-22 can add a line).

The full-suite flakiness above recurred in this plan. Its `connectWebhooks` half stays unexplained.

## User Setup Required

None. No migration or environment variable is needed.

## Next Phase Readiness

- Ready for 01-22, which documents the 20 refused operations in OpenAPI and writes `EXPERT-SETUP-GATE.md`. The final route table is above.
- For 01-23's wave 3c smoke: build 6 and Android have not been run against the 403 on `GET /expert/tax-profile`. The plan expects their error states to show the setup message, and only a device check can confirm it.
- Production stays at 3899d63. Wave 3c is now five local commits: `2b5f9ea`, `f14f9d0`, `bdc580f`, `de662e9`, `e1eb483`. BACK-06, BACK-07 and BACK-19 are untouched and stay Pending.

## Self-Check: PASSED

- All 8 files exist in the backend repo.
- `de662e9` and `e1eb483` are ancestors of backend HEAD.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-09*
