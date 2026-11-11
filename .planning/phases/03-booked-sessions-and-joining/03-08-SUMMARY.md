---
phase: 03-booked-sessions-and-joining
plan: 08
subsystem: expert-bookings
tags: [swiftui, expert-cancel, refund-copy, fail-closed, payment-keys]
status: complete

requires:
  - phase: 01-backend-contract-fixes
    provides: "BACK-19: expert cancel always releases an uncaptured hold or refunds a captured payment in full"
  - phase: 03-booked-sessions-and-joining
    provides: "03-05: GET /expert/bookings/:id/details returns payment_action_required and payment_not_charged (backend 65bb2ed, live)"
provides:
  - "ExpertCancelRefundLine: pure rule for the client-money line on the expert cancel sheet"
  - "ExpertBookingDetail.paymentActionRequired and .paymentNotCharged (optional, absent key stays nil)"
  - "Expert cancel sheet shows full refund with amount, hold release with amount, or no money line, per D-07, D-14, D-16"
affects: [03-UAT, 03-12-checklist, android-parity]

actuals:
  tokens: 6837
  tasks: 2
  commits: 2
plan_head_before: e5010b65eb7062a2e29750b99ed6840a11a67299
plan_head_after: 0e26f5dde4ed396701274d0063e72999e46a8c4b

tech-stack:
  added: []
  patterns:
    - "Money-claim copy comes from a pure enum that returns a line only when every input proves it (switch on the optional pair; one money arm; all other combinations .none)"
    - "Required refundLine parameter with no default on the view model and both view inits, so no screen can show a refund no rule produced"

key-files:
  created:
    - ClickMe2026/Utils/ExpertCancelRefundLine.swift
    - ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift
  modified:
    - ClickMe2026/Model/Responses/ExpertBookingDetail.swift
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Cancellation/ExpertCancellationView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Cancellation/ExpertCancellationViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Cancellation/Subviews/ExpertCancellationClientBox.swift
    - ClickMe2026/Views/Screens/Expert Mode/Cancellation/Subviews/ExpertCancellationMainCard.swift

key-decisions:
  - "The only route to a money line is payment_action_required false AND payment_not_charged false (a switch on the Bool? pair); a missing key, either key true, or a zero amount returns .none, live hold included (D-14 fail closed, D-16)"
  - "A live hold whose amount cannot be formatted reads 'The client's hold will be released.' (planner choice from the plan, unreachable in practice)"
  - "The live-fetch bootstrap passes .none because its ExpertBookingItem carries neither key"

patterns-established:
  - "Pair-switch fail-closed rule: optional inputs from an additive backend key are matched as (false?, false?) so absence can never fall through to a claim"

requirements-completed: [EXP-11]

coverage:
  - id: D1
    description: "Expert cancel line states a full refund of {amount} for a paid booking with no live hold, and the hold release line for a live hold, only when both payment keys read false"
    requirement: "EXP-11"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift#Expert cancel refund line"
        status: pass
    human_judgment: false
  - id: D2
    description: "No money line and no footnote for a free booking, a missing key, payment_action_required true, or payment_not_charged true (converted long-lead)"
    requirement: "EXP-11"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift#Expert details payment keys"
        status: pass
    human_judgment: false
  - id: D3
    description: "No initializer supplies a default refund line; the refundType string and the 'according to our policy' sentence are gone"
    requirement: "EXP-11"
    verification:
      - kind: other
        ref: "grep gates in 03-08-PLAN.md Task 1 verify (refundType 0, policy sentence 0, default refundLine 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The sheet reads correctly on a device for hold, captured, free, converted long-lead and SCA-pending bookings"
    requirement: "EXP-11"
    verification: []
    human_judgment: true
    rationale: "Copy and layout on the real sheet against production data; deferred to Phase 3 UAT"

duration: 6 min
completed: 2026-11-11
---

# Phase 3 Plan 08: Expert Cancel Refund Line Summary

**The expert cancel sheet now says what happens to the client's money from one tested rule: "The client will get a full refund of CA$45.00" for a captured payment, "The client's CA$45.00 hold will be released." for a live hold, and nothing for free, never-charged, card-authentication-pending or unknown bookings.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-11-11T05:07:20Z
- **Completed:** 2026-11-11T05:13:15Z
- **Tasks:** 2
- **Files modified:** 8 (2 created, 6 modified)

## Accomplishments

- `ExpertCancelRefundLine.make` evaluates a zero amount first, then matches `(paymentActionRequired, paymentNotCharged)` as `(false?, false?)` for the only money arm. A nil in either key (backend payload without it), either key true, or a zero amount gives `.none`. With both false, `authorizationExpiresAt` set gives the hold release line (`lock.fill`), otherwise the full refund line (`creditcard`) with the footnote. An unformattable amount falls back to "The client will get a full refund." (UI-SPEC M4).
- `ExpertCancellationClientBox` renders the sentence in `onSurface` with the amount semibold in the same color, never accent, and no row for `.none`. `ExpertCancellationMainCard` shows "Refunds typically appear in the client's account within 3-5 business days." only for the full refund line. The old "according to our policy" sentence and the `refundType` string are removed everywhere.
- `ExpertCancellationViewModel` and both `ExpertCancellationView` inits take a required `refundLine` with no default, and the view-model init no longer defaults to a design view model. The live-fetch bootstrap passes `.none`. Previews: "Expert Cancellation" (full refund), "Hold Released" (renamed from "Partial Refund"), new "Free".
- `ExpertBookingDetail` decodes `payment_action_required` and `payment_not_charged` as independent optionals, and the Booking Summary sheet passes them through unchanged (no `??`, no `== true`).
- Production already returns both keys (backend `65bb2ed`), so the D-07 lines and the D-16 no-line case are live as soon as a build ships.

## Task Commits

1. **Task 1: Tracer, expert cancel money line from one rule that fails closed** - `5fd9f6b` (fix)
2. **Task 2: Expert details decode payment_action_required and payment_not_charged** - `0e26f5d` (fix)

**Plan metadata:** docs commit for this SUMMARY, STATE.md, ROADMAP.md, REQUIREMENTS.md.

## Verification

- `ExpertCancelRefundLineTests` (10 tests) and `ExpertDetailPaymentKeysTests` (7 tests): 17 tests in 2 suites passed.
- Regression: `ExpertJoinVisibilityTests` 7 tests passed (`/tmp/03-08-reg.log`).
- Debug build for iPhone 17 simulator: BUILD SUCCEEDED. Warning baseline for the seven touched app files was 0; after the change the comparison printed nothing, so no new warnings.
- Grep gates from the plan pass: `refundType` in Expert Mode 0 (was 13), policy sentence 0 (was 1), `ExpertCancelRefundLine.make` in the summary 1, no default on any `refundLine` parameter, no default view model on the view init, `refundLine: .none` in the view 2, no collapsed optional and no `nil` placeholder left in the summary.

## Decisions Made

- Followed the plan's rule order and fail-closed reading exactly. The hold-with-unformattable-amount sentence is the plan's recorded choice.
- The pair `switch` is the single money arm, which makes "either key absent" and "either key true" fall into `default` by construction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test suites marked `@MainActor`**
- **Found during:** Task 1 (first test run)
- **Issue:** The app target defaults to main-actor isolation, so `ExpertCancelRefundLine` and its `Equatable` conformance could not be used from the nonisolated Swift Testing suite (7 compile errors).
- **Fix:** Added `@MainActor` to the suites, the same convention `ExpertJoinVisibilityTests` and `JoinWindowTests` use. No change to the production enum.
- **Files modified:** ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift
- **Verification:** 10 tests passed.
- **Committed in:** 5fd9f6b

**2. [Minor] Decode rows live in a second suite in the same file**
- **Found during:** Task 2
- **Issue:** The plan puts the decode rows in `ExpertCancelRefundLineTests.swift` and its Task 2 verify filters on `ExpertCancelRefundLineTests` only. Decode rows need their own decoder helper, so they sit in `ExpertDetailPaymentKeysTests` (same file).
- **Fix:** Ran Task 2's tests with both `-only-testing` filters (17 tests). The plan's literal command would run only the first suite's 10 tests.
- **Committed in:** 0e26f5d

---

**Total deviations:** 1 auto-fixed (Rule 3), 1 minor test-organization note
**Impact on plan:** No scope change. Production code is exactly as planned.

## Issues Encountered

None.

## Deferred device checks (Phase 3 UAT)

Task 1's tracer feedback gate carried only an on-device `<human-check>`. Treated as approved under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT"); automated verification passed before Task 2.

## Pending device checks

1. **EXP-11, fail-closed state (Task 1):** now superseded by item 2, since production returns both keys and the decoded values replace the nil placeholders.
2. **EXP-11 (Task 2, production already returns the keys):** as the expert, open Cancel on:
   - a live-hold booking: "The client's CA$... hold will be released." with a lock icon and no footnote;
   - a captured booking: "The client will get a full refund of CA$..." plus the 3-5 business days footnote;
   - a free booking: no money line, no footnote;
   - a booking converted to long-lead by an accepted reschedule (BOOK-06 payment-conversion case: a paid booking whose hold is at least 2 days old, moved to a start about 5 days out so its end falls after the hold's 6-day window): no money line (D-16);
   - if one can be found, a booking whose T-24h charge is waiting on card authentication: no money line (D-14).
   Check both entries: the Booking Summary cancel sheet and any other path into `ExpertCancellationView`.
3. **BACK-19 production smoke has not been run** (Phase 1 plan 01-19, user skip). This copy promises its behavior; note the smoke result next to this item. Reversibility is costly: if the smoke finds a problem, this copy and Android's change together.
4. A legacy booking with a captured PaymentIntent but a null `payment_status` reads `payment_not_charged: true` on the backend and loses its line (a missing line, never a wrong claim).

## Android follow-ups from Phase 3 (logged, not built)

- Expert cancel copy: Android's expert cancel line should apply the same rule, a client-money line only where `payment_action_required` and `payment_not_charged` both read false, and match the wording: "The client will get a full refund of {amount}", "The client's {amount} hold will be released.", nothing for free or never-charged, footnote only on the refund line. Keys are live at backend `65bb2ed` and additive. (Already logged from 03-05; this plan adds the exact iOS wording.)

## Requirements

EXP-11 is fully delivered: backend half by 03-05, iOS half by this plan. No other Phase 3 plan lists it in its `requirements` (03-12 only references it in the checklist), so it is marked complete with the device check pending in UAT.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or trust-boundary changes. T-03-15 mitigated (money line only when both keys present and false, each case unit tested, optionals never collapsed). T-03-27 mitigated (no refund-line default in the view model or either view init, previews name their case, bootstrap passes `.none`).

## Next Phase Readiness

- Ready for the remaining Phase 3 plans. The 03-12 checklist should carry the EXP-11 items above and the BACK-19 smoke note.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ExpertCancelRefundLine.swift
- FOUND: ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift
- FOUND commits: 5fd9f6b, 0e26f5d
