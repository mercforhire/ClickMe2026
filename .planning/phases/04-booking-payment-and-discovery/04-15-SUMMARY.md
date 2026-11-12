---
phase: 04-booking-payment-and-discovery
plan: 15
subsystem: payments
tags: [swiftui, booking, stripe, payment-intent, idempotency, swift-testing, gap-closure]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "04-08 confirm retry and Try again; 04-13 UnconfirmedBookingLedger and D-15 smart route"
provides:
  - "MakeABookingViewModel.PaidAttempt: topic, slot, PaymentIntent, meeting type and notes captured when the PaymentIntent is created"
  - "Every confirm (first call, automatic retries, Try again, 3DS retry) and the D-04 ledger key read only the snapshot"
  - "loadAvailability keeps the slot while a booking is in flight"
  - "Topic picker, calendar, time slots, meeting type and notes disabled while isSubmitting"
affects: [04-16, 04-VERIFICATION, device-uat]

actuals:
  tokens: 9200
  tasks: 3
  commits: 3
plan_head_before: e5d7eeeda689811ca7ecac6dd24eba702edaa882
plan_head_after: 2baa72d70324b81000cb489be69080203dace2a3

tech-stack:
  added: []
  patterns:
    - "Snapshot the values of an in-flight paid attempt when the PaymentIntent is created; later steps read the snapshot, never the live form"
    - "A computed accessor (paymentIntentId) over the snapshot keeps one source of truth and every old reader working"
    - "Lock the inputs of an in-flight operation with .disabled(isSubmitting) on the cards rather than editing each control"

key-files:
  created:
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
    - ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift
    - .planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md
    - .planning/phases/04-booking-payment-and-discovery/04-UI-SPEC.md

key-decisions:
  - "PaidAttempt holds topic, slot, PaymentIntent id, meeting type and trimmed notes (Android PaidContext parity); the pm_ id stays in confirmPaymentMethodId because the card is chosen later in the sheet"
  - "paidAttempt is a plain internal var (not published, no view renders it) so tests can install one; paymentIntentId became computed from it"
  - "loadAvailability is guarded on isSubmitting instead of moving the slot clear into the month arrows, so the WR-04 reappear behavior is not changed"
  - "The lock covers the meeting type and notes cards as well as the four controls the verification named, so the screen never shows a meeting type or note other than the one being confirmed"

patterns-established:
  - "New logic for the Make a Booking view model goes in sibling extension files; the main file went from 974 to 966 lines"

requirements-completed: [PAY-02]

coverage:
  - id: D1
    description: "CR-01: every paid confirm (first, automatic retry, Try again, 3DS retry) sends the payment_intent_id, topic_id, start_time, meeting_type and client_notes captured when Book Now created the PaymentIntent, whatever the form shows"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#bookCreatesPaidAttempt"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#retryKeepsOriginalSelection"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#scaRetryKeepsOriginalSelection"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#formEditWhileConfirmRunsKeepsRequest"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-04 under CR-01: the unconfirmed-booking ledger record, clear and keep decisions use the attempt's slot, so a changed slot never moves or loses the 'You may already have this booking' record"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#ledgerKeysOnPaidAttempt"
        status: pass
    human_judgment: false
  - id: D3
    description: "A calendar reload during an attempt keeps the slot, bookingAttemptId, PaymentIntent id and pm_ id; an idle reload still clears the slot; a confirm with no attempt makes no request"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#reloadDuringConfirmKeepsSlot"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#idleReloadClearsSlot"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#confirmWithoutAttemptMakesNoRequest"
        status: pass
    human_judgment: false
  - id: D4
    description: "One confirm at a time, and every way out of a paid attempt returns isSubmitting to false so the form unlocks"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#secondConfirmWhileRunningIsRejected"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#everyResetUnlocksTheForm"
        status: pass
    human_judgment: false
  - id: D5
    description: "The topic picker, calendar (day cells and month arrows), time slots, meeting type and notes are disabled while a booking is in flight, so the screen always shows the form being confirmed (D-11 step d on a real iPhone)"
    requirement: PAY-02
    verification: []
    human_judgment: true
    rationale: "View-level .disabled() on five cards is not asserted by any unit test; D-11 step d on a device with airplane mode is the evidence (UI-SPEC D1, backstop)"

duration: 11min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 15: CR-01 paid attempt snapshot Summary

**A PaidAttempt snapshot (topic, slot, PaymentIntent, meeting type, notes) taken when the PaymentIntent is created now feeds every confirm and the D-04 ledger key, the slot survives a calendar reload while submitting, and the five booking input cards are locked while a booking is in flight.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-11-12T18:38:00Z
- **Completed:** 2026-11-12T18:49:00Z
- **Tasks:** 3
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments

- CR-01 closed in the view model: `completePaidBooking` guards only on `paidAttempt` and sends `attempt.paymentIntentId`, `attempt.topic.id`, `attempt.slot.startTime`, `attempt.meetingType` and `attempt.clientNotes`. Changing the topic or time slot after the PaymentIntent exists can no longer change the request, so Try again and the 3DS retry confirm the booking the client paid for.
- The ledger record, clear and keep decisions, and the `SLOT_UNAVAILABLE` and `DUPLICATE_BOOKING` ledger checks of a confirm-phase error, are keyed on the attempt's slot.
- `loadAvailability(for:)` no longer clears the slot while `isSubmitting`, so a reload cannot trigger the silent `resetPaidFlow()` that dropped the PaymentIntent and card ids. While idle it clears the slot exactly as before.
- `MakeABookingView` disables the topic picker, calendar, time slots, meeting type and notes cards while `viewModel.isSubmitting`. Device step and UI-SPEC row added.
- `MakeABookingViewModel.swift` shrank from 974 to 966 lines: `cancelPaidBooking`, `retryConfirmAfterSCA` and `cancelSCA` moved unchanged to `MakeABookingViewModel+PaidFlow.swift`.

## Task Commits

1. **Task 1 (tracer): a confirm retry keeps the topic and slot the payment was made for** - `6184f6c` (fix)
2. **Task 2: a reload or 3DS retry keeps the paid attempt intact** - `50f55de` (fix)
3. **Task 3: lock the booking form while a paid booking is in flight** - `2baa72d` (fix)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Evidence recorded for the plan's output spec

- **RED run (Task 1, at HEAD e5d7eee):** `retryKeepsOriginalSelection` was added against the old helper and the suite run. Result: `Test run with 28 tests in 1 suite failed ... with 2 issues`; the only failing test was the target, on `body?["start_time"] ("2026-11-14T19:40:36Z") == first["start_time"] ("2026-11-14T18:40:36Z")` and `body?["topic_id"]` (new topic id vs the original). All 27 other rows passed. This is the planned assertion for the planned reason (the fourth confirm carried the changed form). The failing state was not committed, per the plan.
- **Planning-time facts confirmed before editing:** the view model was 974 lines (`wc -l` printed 974). Touching the three app files and building to `/tmp/04-15-build-before.log` gave BUILD SUCCEEDED and 0 warnings naming MakeABookingViewModel.swift, MakeABookingViewModel+PaidFlow.swift or MakeABookingView.swift (1 warning in the whole build, elsewhere).
- **View model line count:** 974 before, 966 after (gate: at most 974).
- **Warning comparison:** `/tmp/04-15-build.log` after the plan: BUILD SUCCEEDED, 1 warning in total (same as baseline), 0 naming the four app files. The test builds show the same single warning, a deprecated Stripe `handleNextAction` call in `Subviews/MakeABookingStripePaymentSheet.swift:202`, which this plan did not touch.
- **Per-suite results:** MakeABookingPaidFlowTests 38 tests passed (28 before the plan plus 10 new rows); MakeABookingAvailabilityTests 5 passed; BookingErrorCopyParityTests 6 passed.
- **Full suite (`/tmp/04-15-full.log`):** `Test run with 641 tests in 65 suites passed`, `** TEST SUCCEEDED **` (AuthSmokeTests and SignupSmokeTests skipped, the three non-compiling files excluded, as in 04-14).
- **Android parity (checked, no change needed):** `MakeABookingViewModel.kt` keeps `paidContext: PaidContext?` (L117) and returns early on `if (_uiState.value.isSubmitting) return` in the selection setters (L222, L287 to L342). Android already behaves as iOS now does, so there is no Android follow-up and no backend change.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift` - `PaidAttempt: Equatable` snapshot, only an extension with the nested struct
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` - `paidAttempt`, computed `paymentIntentId`, snapshot built in `beginPaidBooking`, confirm and ledger read the snapshot, `loadAvailability` keeps the slot while submitting, three methods removed
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift` - receives `cancelPaidBooking`, `retryConfirmAfterSCA`, `cancelSCA`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift` - `.disabled(viewModel.isSubmitting)` on five cards
- `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift` - ten new rows, fixtures `otherPaidTopic`, `intentCreated`, `setupCreated`, helper parameter `installingAttempt:`, `CallCounter`
- `.planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md` - D-11 step d lock check and the requirement cell
- `.planning/phases/04-booking-payment-and-discovery/04-UI-SPEC.md` - section 2 row "Form while it runs"

## Decisions Made

- Snapshot contents follow Android's `PaidContext`; the pm_ id stays in `confirmPaymentMethodId` and `bookingAttemptId` stays where it is.
- The slot-clear guard lives in `loadAvailability` (on `isSubmitting`), not in the month arrows, so WR-04 (the reappear reload) is unchanged.
- The lock includes meeting type and notes, beyond the four controls named in the verification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The race-sensitive rows (`formEditWhileConfirmRunsKeepsRequest`, `secondConfirmWhileRunningIsRejected`) use the 500 ms retry delay with `#require` guards and passed on every run.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust boundary; T-04-38 to T-04-41 are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 gap 1 (CR-01) is closed in code; plan 04-16 (CR-02) is next.
- Still open and not in this plan: the D-11 device step d (now includes the form-lock taps), WR-01 device 3DS check, the device UAT checklist, EXPL-03 and EXPL-07 device checks, WR-02 to WR-05.
- The assumption that a 3DS presentation can re-run the screen's `.task` (reappear reload) is still unchecked on a device; the `isSubmitting` guard covers it either way.

## Self-Check: PASSED

- Created and modified files exist on disk (MakeABookingViewModel+PaidAttempt.swift, MakeABookingViewModel+PaidFlow.swift, MakeABookingPaidFlowTests.swift checked).
- Commits `6184f6c`, `50f55de`, `2baa72d` are ancestors of HEAD.
- Plan-level checks pass: three focused suites, full suite, BUILD SUCCEEDED, 0 new warnings in the four app files, view model at 966 lines.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
