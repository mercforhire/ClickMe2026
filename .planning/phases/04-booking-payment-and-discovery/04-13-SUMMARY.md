---
phase: 04-booking-payment-and-discovery
plan: 13
subsystem: payments
tags: [swiftui, booking, stripe, duplicate-booking, ledger, swift-testing]

requires:
  - phase: 01-backend-fixes
    provides: "BACK-15: payment-intent 409 DUPLICATE_BOOKING with detail.booking_id for the caller's own active booking"
  - phase: 04-booking-payment-and-discovery
    provides: "04-08 confirm retry, outcome-unknown classification and the PaidFlowAlert type"
provides:
  - "UnconfirmedBookingLedger: session-only record of an expert and slot whose paid confirm may have succeeded"
  - "D-15 smart route: a matching DUPLICATE_BOOKING opens Request Sent for detail.booking_id with no confirm call"
  - "PaidFlowAlert.mayAlreadyBeBooked (Couldn't book / You may already have this booking. Check My Bookings.)"
affects: [04-14]

actuals:
  tokens: 11500
  tasks: 2
  commits: 2
plan_head_before: 2eb6a35f2be00187495e819a2fe2d1c463c212c9
plan_head_after: 2a166d93b0c449f38825f896a3f70fc320445542

tech-stack:
  added: []
  patterns:
    - "A @MainActor session-only singleton injected through the view-model init (default .shared), with tests passing their own instance"
    - "Keep rule as a static function on the ledger (keepsRecord(afterServerCode:)) so the view model and tests share one definition"

key-files:
  created:
    - ClickMe2026/Managers/UnconfirmedBookingLedger.swift
    - ClickMe2026Tests/Utils/UnconfirmedBookingLedgerTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
    - ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift

key-decisions:
  - "D-04: the record is keyed by expert id and slot start to the second (no topic), held in memory only, and does not survive a relaunch"
  - "D-17: keepsRecord(afterServerCode:) is true for SLOT_UNAVAILABLE and PAYMENT_IN_PROGRESS only; an unknown outcome, Not now and leaving the screen never clear the record"
  - "D-15: detail.booking_id is used only when it parses as a UUID and the ledger holds the expert and slot; the record is cleared and the flow reset before Request Sent opens"
  - "K4: after the D-04 alert (either source) the slot is cleared and a new attempt id is generated, as for every SLOT_UNAVAILABLE"

patterns-established:
  - "Paid-flow alerts are set after resetPaidFlow(), because the reset clears paidFlowAlert"

requirements-completed: [PAY-02]

coverage:
  - id: D1
    description: "The ledger records an expert and slot at confirm start, clears on a 201 and on coded errors that prove no booking, and keeps the record on an unknown outcome, 409 PAYMENT_IN_PROGRESS (D-17), SLOT_UNAVAILABLE, Not now"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/UnconfirmedBookingLedgerTests.swift (key and keepsRecord rows)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#unknownKeepsRecord, #paymentInProgressKeepsRecord, #paymentInProgressThenCreatedClearsRecord, #createdClearsRecord, #intentExpiredClearsRecord, #slotUnavailableKeepsRecord"
        status: pass
    human_judgment: false
  - id: D2
    description: "After a lost confirm, booking the same slot again with a DUPLICATE_BOOKING answer opens Request Sent for detail.booking_id, resets the flow and makes no confirm call"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#duplicateRoutesToExistingBooking"
        status: pass
    human_judgment: false
  - id: D3
    description: "A matching SLOT_UNAVAILABLE (either phase) and an unmatched or unparseable DUPLICATE_BOOKING show 'Couldn't book / You may already have this booking. Check My Bookings.'; any other SLOT_UNAVAILABLE keeps the plain copy; the slot is cleared"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift (intentSlotUnavailableWithRecord, confirmSlotUnavailableWithRecord, intentSlotUnavailableWithoutRecord, duplicateWithoutRecord, duplicateWithUnparseableId, differentSlotDoesNotMatch, mayAlreadyBeBookedCopy)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift (free and paid slot-taken copy regression)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The alert layout, its two buttons (Check My Bookings default, Close Alert cancel) and the end-to-end retry-after-lost-confirm flow on a real iPhone (UAT E5, D-11)"
    requirement: PAY-02
    verification: []
    human_judgment: true
    rationale: "SwiftUI alert rendering and a real lost confirm with one hold in Stripe need a device; logged in WINDOWS.md as an unrun-verify entry for the 04-14 session"

duration: 9min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 13: Unconfirmed-Booking Ledger and D-15 Duplicate Route Summary

**A session-only ledger of paid confirms whose booking may exist routes a retried booking's DUPLICATE_BOOKING to the existing booking's Request Sent screen, and replaces "slot taken" with "You may already have this booking. Check My Bookings." wherever the slot may be the client's own.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-11-12T05:52Z (approximate; first command at 05:54:35Z)
- **Completed:** 2026-11-12T06:02Z
- **Tasks:** 2
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments

- `UnconfirmedBookingLedger` (`@MainActor`, `shared`, `Key` of expert id plus start second) records at confirm start and is cleared on a 201 or on a coded error for which `keepsRecord(afterServerCode:)` is false. SLOT_UNAVAILABLE and PAYMENT_IN_PROGRESS keep it (D-04, D-17); so do an unknown outcome, Not now and leaving the screen.
- D-15: a payment-intent `409 DUPLICATE_BOOKING` with a UUID `detail.booking_id` and a matching record clears the record, resets the paid flow silently and sets `completedBookingId`, so Request Sent opens for the booking the server already has. The test asserts no `/bookings/confirm` request is made after the route.
- D-04: `PaidFlowAlert.mayAlreadyBeBooked` ("Couldn't book", "You may already have this booking. Check My Bookings.") with Check My Bookings and Close Alert. It shows for a matching SLOT_UNAVAILABLE in either phase and for a DUPLICATE_BOOKING with no record or no parseable id. Every other SLOT_UNAVAILABLE keeps the plain copy; the free path is untouched.
- Full app test run: 623 tests in 64 suites pass; BUILD SUCCEEDED with no new warnings in the four app files (baseline was empty).

## Task Commits

1. **Task 1: Tracer, a lost confirm's retry opens the existing booking (D-04, D-15)** - `301ccd5` (feat)
2. **Task 2: "You may already have this booking" alert (D-04)** - `2a166d9` (feat)

**Plan metadata:** committed with this summary (docs).

## Files Created/Modified

- `ClickMe2026/Managers/UnconfirmedBookingLedger.swift` - ledger, key and keep rule
- `ClickMe2026Tests/Utils/UnconfirmedBookingLedgerTests.swift` - 7 key and keep-rule rows
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` - `ledger` init parameter on both inits, record/clear in `completePaidBooking`, D-15 route and D-04 alerts in `handlePaidFlowError`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift` - `mayAlreadyBeBooked`, `dismissMayAlreadyBeBookedAlert()`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift` - alert actions switch on the case
- `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift` - fresh ledger per view model, 15 new rows

## Decisions Made

- Followed the plan's key, keep rule and copy.
- The DUPLICATE_BOOKING D-04 path also calls `newBookingAttempt()`, not only `selectedTimeSlot = nil` as the plan text lists: K4 says it behaves "as for every SLOT_UNAVAILABLE", which includes a fresh attempt id, and the cleared slot makes the old id meaningless anyway.
- The alert is set after `resetPaidFlow()` in both branches, since the reset clears `paidFlowAlert`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Existing `slotUnavailableIsNotRetried` row expected the plain copy**
- **Found during:** Task 2
- **Issue:** The row (from 04-08) confirms a paid booking that answers 409 SLOT_UNAVAILABLE and expected `bookingError == "That time slot was just taken..."`. Because the confirm now records the slot, the plan's own rule ("a SLOT_UNAVAILABLE, in either phase, for an expert and slot the ledger holds") makes this the D-04 alert case.
- **Fix:** The row now expects `paidFlowAlert == .mayAlreadyBeBooked` and `bookingError == nil`; the plain-copy case is covered by `intentSlotUnavailableWithoutRecord` and `BookingErrorCopyParityTests`.
- **Files modified:** `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`
- **Committed in:** `2a166d9`

---

**Total deviations:** 1 auto-fixed (1 test expectation updated to the planned behavior). **Impact:** none on scope.

### Process notes

- Task 2 is `tdd="true"`, but the plan specifies one commit per task with tests and code together, as in 04-08, so there is no separate RED commit.
- The tracer's `<verify>` is automated-only under `human_verify_mode: end-of-phase`; both suites and the grep gates were re-run and passed, then Task 2 started.

## Issues Encountered

None. The commit guard reported `main` as not protected (`git.allow_default_branch_commits` is true), consistent with earlier plans in this phase.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or schema changes. T-04-29 (id parsed as UUID, ownership re-checked by GET /client/bookings/:id), T-04-30 (ledger-backed copy, PAYMENT_IN_PROGRESS rows) are mitigated and covered by tests; T-04-31 accepted as planned.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Android follow-up

Logged, not built: route DUPLICATE_BOOKING to `detail.booking_id` (already logged from BACK-15) and the D-04 copy (Android's `make_a_booking_error_slot_taken_check_bookings` wording differs). No backend change was needed or made.

## Next Phase Readiness

- The device check (confirm-unknown alert, Not now, Book Now on the same slot lands on Request Sent; a slot someone else holds still shows the plain alert) is logged in `.planning/WINDOWS.md` as an `unrun-verify` entry for the 04-14 D-11 session (UAT E5).
- Plans 04-01 and 04-12 remain paused at their checkpoints; this plan touched neither.

## Self-Check: PASSED

- Created files exist: `UnconfirmedBookingLedger.swift`, `UnconfirmedBookingLedgerTests.swift`.
- Commits `301ccd5` and `2a166d9` are on `main`; `git rev-list --count 2eb6a35..HEAD` was 2 at the last task commit.
- Acceptance criteria re-run: `final class UnconfirmedBookingLedger` x1; `UnconfirmedBookingLedger.shared` in `MakeABookingPaidFlowTests.swift` x0; `case mayAlreadyBeBooked` x1; D-04 copy x1 in the extension; `Close Alert` x1 in the view; `ledger.record(expertId:`, `booking_id`, `keepsRecord(afterServerCode:)` present in the view model; `paymentInProgress` in the ledger.
- Plan verification: `UnconfirmedBookingLedgerTests` (7), `MakeABookingPaidFlowTests` (27), `BookingErrorCopyParityTests` (6) pass; full `ClickMe2026Tests` run 623 tests in 64 suites; BUILD SUCCEEDED, `comm -13` of warnings is empty.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
