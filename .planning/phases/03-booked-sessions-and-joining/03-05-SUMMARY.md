---
phase: 03-booked-sessions-and-joining
plan: 05
subsystem: api
tags: [backend, express, supabase, stripe, openapi, expert-booking, payment-keys]

requires:
  - phase: 01-backend-contract-fixes
    provides: "scaRecovery paymentActionFields helper, convertToLongLead, and the expert cancel refund behavior (BACK-19)"
provides:
  - "GET /expert/bookings/:id/details returns payment_action_required and payment_action_deadline (D-14)"
  - "GET /expert/bookings/:id/details returns payment_not_charged (D-16), derived by paymentNotCharged(booking)"
  - "ExpertBookingDetail openapi documents all three keys as additive"
  - "Backend commit 65bb2ed, deployed to production 2026-11-10 (/health = 65bb2ed)"
affects: [03-08 expert cancel refund line, 03-UAT, android-parity]

actuals:
  tokens: 2842
  tasks: 2
  commits: 1
plan_head_before: f1424d651b79fbd343ab36674a86168f8f5074eb
plan_head_after: 65bb2ed4979b31dc8a1dcb68f0909951d678b1cc

tech-stack:
  added: []
  patterns:
    - "Derived booleans instead of raw payment columns: payment_status, payment_intent_id and off_session_attempted_at are selected as inputs only and never returned"
    - "Money-state allow-list (MONEY_HELD_OR_TAKEN_PAYMENT_STATUSES): unknown or null status reads as not charged, so the expert app makes no client-money claim (fail closed)"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expertBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "One backend commit carries both D-14 and D-16 keys; the response change is additive only"
  - "payment_not_charged is false only for a PaymentIntent in requires_capture, processing, captured, partially_refunded or refunded; every other case (no PaymentIntent, scheduled, canceled, auth_expired, failed, unknown) reads true"
  - "Deploy decision (user, 2026-11-10): deploy-now"

patterns-established:
  - "Backend keys the iOS app needs for copy are derived booleans documented in openapi as safe for clients to ignore"

requirements-completed: []  # EXP-11 stays Pending: plan 03-08 also lists it; only its backend half is done here

coverage:
  - id: D1
    description: "Expert booking details return payment_action_required and an ISO payment_action_deadline for an SCA-pending scheduled booking, false and null for a live hold"
    requirement: "EXP-11"
    verification:
      - kind: unit
        ref: "tests/expertBooking.test.js#payment keys (ios-p3 D-14, D-16)"
        status: pass
    human_judgment: false
  - id: D2
    description: "payment_not_charged is true for free, failed, SCA-pending and converted long-lead rows, and false for requires_capture and captured rows with a PaymentIntent"
    requirement: "EXP-11"
    verification:
      - kind: unit
        ref: "tests/expertBooking.test.js#payment keys (ios-p3 D-14, D-16)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Raw payment_status, payment_intent_id and off_session_attempted_at are absent from the expert details response"
    requirement: "EXP-11"
    verification:
      - kind: unit
        ref: "tests/expertBooking.test.js#payment keys (ios-p3 D-14, D-16)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Production serves the new keys: backend deployed and /health reports 65bb2ed"
    requirement: "EXP-11"
    verification:
      - kind: other
        ref: "curl -s https://clickme-backend-production.up.railway.app/health -> commit 65bb2ed"
        status: pass
    human_judgment: false

duration: n/a (Task 2 waited on a user decision)
completed: 2026-11-10
status: complete
---

# Phase 3 Plan 05: Expert Booking Payment Keys (backend) Summary

**GET /expert/bookings/:id/details now returns `payment_action_required`, `payment_action_deadline` and a derived `payment_not_charged`, so the expert cancel sheet can tell a held or charged booking from a never-charged one; live in production at backend `65bb2ed`.**

## Performance

- **Duration:** not tracked (Task 2 waited on a user decision)
- **Completed:** 2026-11-10
- **Tasks:** 2 of 2 (Task 1 tracer, Task 2 deploy decision)
- **Files modified:** 3, all in the backend repo (175 insertions); the iOS repo has no code change from this plan

## Accomplishments

- The expert details response spreads `paymentActionFields(booking)` (D-14, card authentication pending, nothing charged) and adds `payment_not_charged` (D-16). The derivation reads false only when a PaymentIntent exists and its `payment_status` is one of `requires_capture`, `processing`, `captured`, `partially_refunded`, `refunded`.
- A booking converted to long-lead by an accepted reschedule (`convertToLongLead` nulls `payment_intent_id` and voids the hold) now reads `payment_not_charged: true`, `payment_action_required: false`, `authorization_expires_at: null`. Without D-16 the expert sheet would have promised that client a refund of money never taken.
- Tests cover the seven planned rows (SCA pending, live hold, captured, converted long-lead, free, failed, and the no-raw-columns check). `npm test -- tests/expertBooking.test.js` gave 153 passed, 0 failed.
- `ExpertBookingDetail` in `openapi/clickme-api.yaml` documents all three keys as additive and safe for clients to ignore, and says plainly that a live hold reads `payment_not_charged: false`.

## Task Commits

1. **Task 1: Tracer, expert booking details report payment_action_required and payment_not_charged** - `65bb2ed` (feat, backend repo `ClickMe2026 Backend`, branch master)
2. **Task 2: Deploy decision** - no commit of its own; the user chose **deploy-now**

**Plan metadata:** docs commit in the iOS repo (this SUMMARY, STATE.md, ROADMAP.md).

`plan_head_before` and `plan_head_after` above are backend SHAs (`f1424d6` to `65bb2ed`, `git rev-list --count` = 1) because this plan made no iOS code commit and wrote no iOS ledger.

## Deploy outcome

**Deployed to production 2026-11-10; `/health` = `65bb2ed`.**

- Decision: the user chose deploy-now. The orchestrator ran `git push origin master:main`, moving `origin/main` from `36f35bf` to `65bb2ed`.
- Check: `curl -s https://clickme-backend-production.up.railway.app/health` returned `{"status":"success","commit":"65bb2ed"}` about 75 seconds after the push. A later `ls-remote` read of `origin/main` also shows `65bb2ed`.
- The push shipped these 4 commits (live list, 4 of 4). Only the first changes runtime code; the other three are `.planning` docs:
  - `65bb2ed` feat(ios-p3): expert booking details report payment_action_required and payment_not_charged (D-14, D-16)
  - `f1424d6` docs(phase-30): add research and validation strategy
  - `6d8f54e` docs(state): record phase 30 context session
  - `1f7fb2b` docs(30): capture phase context
- Because the change is additive, App Store build 6 and the current Android build keep working. No "local only, deploy before Phase 8" blocker is recorded in STATE.md, since the commit is live.
- Result for the iOS side: plan 03-08 can read both keys in production and show the D-07 client-money lines only where both read false. It still fails closed (no money line) if either key is missing from a response.

## Files Created/Modified

- `/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expertBooking.controller.js` - selects `payment_intent_id` and `off_session_attempted_at` as inputs only; adds `paymentNotCharged(booking)` and `MONEY_HELD_OR_TAKEN_PAYMENT_STATUSES`; returns the three keys
- `/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertBooking.test.js` - new `payment keys (ios-p3 D-14, D-16)` describe block in EBOOK-03
- `/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml` - three additive keys on `ExpertBookingDetail`

## Decisions Made

- One commit for both keys, because they are additive, touch the same three files and ship as one unit.
- `payment_not_charged` lists the money-holding states rather than the no-money ones, so an unknown or null status with a PaymentIntent reads true and the expert app makes no claim. Known consequence from the plan: a legacy row with a captured PaymentIntent but a null `payment_status` loses its D-07 line; that is a missing line, never a wrong claim.
- Free bookings read `payment_not_charged: true`, which agrees with the iOS rule of showing no line for a zero amount.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The deploy shipped 3 extra docs-only commits from phase 30 planning that were already on backend master; the checkpoint listed them before the user decided.

## Android follow-up (logged, not built)

Android's expert cancel line could apply the same D-14/D-16 rule: show a client-money line only when `payment_action_required` and `payment_not_charged` both read false. Android does not read either key today, and no Android change is needed for compatibility because the keys are additive. This is a parity item for the Phase 3 Android list.

## Threat Flags

None. The only new surface is three derived booleans on an existing authenticated route (T-03-09 mitigated by the raw-column-absent test; T-03-10 mitigated by additive-only keys and the live commit list shown before the push; T-03-26 mitigated by the allow-list derivation).

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03-08 (expert cancel refund line) can run against the live keys. EXP-11 stays Pending until 03-08 lands; its backend half is done here.
- Device check of the D-07 lines and the converted long-lead no-line case can happen during Phase 3 UAT, since production already returns the keys.

## Self-Check: PASSED

- FOUND: `/Users/LeonChen/Documents/ClickMe2026 Backend` commit `65bb2ed` (ancestor of backend HEAD, `origin/main` = `65bb2ed`)
- FOUND: the three backend files changed by `65bb2ed` (175 insertions)
- FOUND: production `/health` = `65bb2ed`

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-10*
