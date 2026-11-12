---
phase: 04-booking-payment-and-discovery
plan: 08
subsystem: payments
tags: [swiftui, stripe, booking, retry, idempotency, swift-testing]

requires:
  - phase: 01-backend-fixes
    provides: "BACK-15 confirm replay (an ownership-checked 201 replay on payment_intent_id)"
  - phase: 04-booking-payment-and-discovery
    provides: "04-04 availability guard on the same Make a Booking view model"
provides:
  - "ConfirmOutcome: classifier for a failed POST /bookings/confirm (outcome unknown vs server-coded)"
  - "ConfirmRetryPolicy: bounded same-request retry (2 s, 4 s) with RunResult"
  - "ErrorCode.paymentInProgress and its outcome-unknown handling (D-17)"
  - "PaidFlowAlert.confirmUnknown, retryConfirm(), dismissConfirmAlert(), showsConfirmingStatus"
  - "Confirming your booking line and the We couldn't confirm your booking alert on Make a Booking"
affects: [04-13, 04-14]

actuals:
  tokens: 9500
  tasks: 3
  commits: 3
plan_head_before: bc94670730fb7ec4853380a61aee64fc778d9806
plan_head_after: 894e14237f3cd88758a2e596728bb54d9667a311

tech-stack:
  added: []
  patterns:
    - "Classify a failure by error type, status and code (never message text) to decide whether a lost response may hide a server-side success"
    - "Retry only an idempotent request, with the same arguments on every attempt, behind an injectable delay list (test seam)"

key-files:
  created:
    - ClickMe2026/Utils/ConfirmOutcome.swift
    - ClickMe2026/Utils/ConfirmRetryPolicy.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
    - ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift
    - ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
    - ClickMe2026/Model/Enums/ErrorCode.swift

key-decisions:
  - "A confirm failure is an unknown outcome for any URLError, CancellationError, NetworkError.invalidResponse or .decodingFailed, and an HTTP 5xx whose code handlePaidFlowError does not map; a false unknown costs one idempotent replay, a false coded loses the booking from view"
  - "D-17: 409 PAYMENT_IN_PROGRESS is the only 4xx in ConfirmOutcome.outcomeUnknownCodes; it is checked before the status rules and never shows server copy"
  - "completePaidBooking ignores a call while a confirm run is in progress (isConfirmRunning), so Try again, Book Now and an SCA retry cannot start a second confirm"
  - "The confirm-unknown alert binding has a no-op setter: only Not now resets the flow; Try again clears the alert itself and Check My Bookings leaves the screen"

patterns-established:
  - "ConfirmRetryPolicy.run(_:) returns RunResult (succeeded, serverCoded, outcomeUnknown); the view model keeps every id on outcomeUnknown and stays on .confirming"

requirements-completed: [PAY-02, PAY-04]

coverage:
  - id: D1
    description: "Confirm failures are classified: URLError, CancellationError, invalidResponse, decodingFailed and unmapped 5xx are outcome unknown; mapped codes (including a 503 DIRECT_CHARGE_DISABLED) stay server-coded"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift (classifier rows)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The retry policy resends the same request twice (2 s, 4 s) on an unknown outcome and stops at the first success or coded error"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift (retry-policy rows)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A timed-out confirm keeps the PaymentIntent, pm_ id and booking attempt id, retries, and a replayed 201 opens Request Sent for that booking; server-coded errors keep today's mapping with no retry"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#timeoutsThenReplay"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#slotUnavailableIsNotRetried"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift (regression)"
        status: pass
    human_judgment: false
  - id: D4
    description: "When the retries run out the confirm-unknown alert is raised; Try again reuses the same PaymentIntent and card, Not now resets silently, Book Now and a second Try again cannot start a second confirm"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift (retriesExhaustedRaisesAlert, tryAgainReplays, notNowResetsSilently, bookIsBlockedWhileAlertIsUp, retryConfirmGuards, alertCopy)"
        status: pass
    human_judgment: false
  - id: D5
    description: "409 PAYMENT_IN_PROGRESS on confirm takes the same outcome-unknown path (D-17): same ids on every request, bounded retries, then the alert; no server copy"
    requirement: PAY-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift#paymentInProgressThenReplay, #paymentInProgressExhausted"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift (PAYMENT_IN_PROGRESS rows)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The stale backend to-do and SCAChallenge wording are gone and ErrorCode names detail.stripe_account as shipped"
    requirement: PAY-04
    verification:
      - kind: other
        ref: "grep gates: TODO(backend) x0 app-wide, 'Nil until backend adds it' x0, the shipped-wording line in ErrorCode.swift x1"
        status: pass
    human_judgment: false
  - id: D7
    description: "The Confirming your booking line, its VoiceOver announcement, the alert layout and the airplane-mode flow on a real iPhone (UAT L2, E2, D-11); the 409 PAYMENT_IN_PROGRESS case cannot be forced from the app"
    requirement: PAY-02
    verification: []
    human_judgment: true
    rationale: "SwiftUI rendering, the announcement and a real network drop with one hold in the Stripe Dashboard need a device; logged in WINDOWS.md as an unrun-verify entry for the 04-14 session"

duration: 13min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 08: Confirm Retry and Unknown-Outcome Alert Summary

**A paid confirm that times out (or is answered 5xx or 409 PAYMENT_IN_PROGRESS) now keeps the PaymentIntent, card and attempt id, resends the same confirm twice, lands on Request Sent when the server replays the booking, and otherwise shows a Try again / Check My Bookings / Not now alert.**

## Performance

- **Duration:** about 13 min (the start time was not recorded; taken from the last STATE.md update at 05:17Z)
- **Started:** 2026-11-12T05:18Z (approximate)
- **Completed:** 2026-11-12T05:31Z
- **Tasks:** 3
- **Files modified:** 8 (5 created, 3 modified), 903 insertions, 24 deletions

## Accomplishments

- `ConfirmOutcome.classify` separates "the server answered with a code the flow handles" from "we do not know whether the booking exists", and `ConfirmRetryPolicy` resends the same request 2 s and 4 s later while the answer stays unknown (PAY-02, D-03).
- `completePaidBooking` runs through the policy. On an unknown outcome it does not call `resetPaidFlow()`, does not touch `bookingAttemptId` and stays on `.confirming`, so no second PaymentIntent or hold can be created (T-04-21). A replayed 201 opens Request Sent like a first-time success.
- When the retries run out, the alert "We couldn't confirm your booking" shows the UI-SPEC sentence and `Payment reference: pi_…`, with Try again (same PI and card), Check My Bookings (shell action) and Not now (silent reset, form intact). The "Confirming your booking…" line sits 8 pt above the Book button and posts one VoiceOver announcement.
- D-17: `409 PAYMENT_IN_PROGRESS` decodes to the new `ErrorCode.paymentInProgress` and is the only 4xx classified as outcome unknown (T-04-35).
- PAY-04 (view-model half): the stale backend to-do and the `SCAChallenge` wording are gone, and `ErrorCode.paymentRequiresAction` says `detail.stripe_account` is shipped. App-wide `TODO(backend)` count is 0.

## Task Commits

1. **Task 1: Tracer, a timed-out confirm keeps the payment and retries** - `f0d4105` (fix)
2. **Task 2: Retries exhausted, alert, Confirming line, PAY-04 comments** - `3fbcf3d` (feat)
3. **Task 3: 409 PAYMENT_IN_PROGRESS keeps the payment and retries (D-17)** - `894e142` (fix)

**Plan metadata:** committed with this summary (docs).

## Files Created/Modified

- `ClickMe2026/Utils/ConfirmOutcome.swift` - classifier, `explicitlyMappedCodes`, `outcomeUnknownCodes`
- `ClickMe2026/Utils/ConfirmRetryPolicy.swift` - `delays`, `standard`, `RunResult<Value>`, `run(_:)`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift` - `PaidFlowAlert`, `retryConfirm()`, `dismissConfirmAlert()`, `showsConfirmingStatus`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` - `confirmRetryPolicy`, `confirmPaymentMethodId`, `isConfirmRunning`, `paidFlowAlert`; rewritten `completePaidBooking`; `resetPaidFlow()` now internal; PAY-04 comments
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift` - status line, announcement, alert
- `ClickMe2026/Model/Enums/ErrorCode.swift` - `paymentInProgress`; `paymentRequiresAction` comment
- `ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift` - classifier and retry-policy rows (including D-17)
- `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift` - 10 view-model rows through a mocked URLSession

## Decisions Made

- Followed the plan's classification and copy. `explicitlyMappedCodes` is exactly the set of codes `handlePaidFlowError` has cases for, so a 5xx carrying one of them stays server-coded (for example 503 `DIRECT_CHARGE_DISABLED`).
- The alert binding's setter does nothing: SwiftUI also writes `false` when any button dismisses the alert, and only Not now may reset the flow.
- Known limit, unchanged and recorded: `NetworkService`'s 120 s request timeout stays, so three attempts against a black-holed network can take about 6 minutes. Airplane mode fails in milliseconds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Re-entry guard for a running confirm**
- **Found during:** Task 1 (completePaidBooking rewrite)
- **Issue:** The plan says `retryConfirm()` runs only when "no attempt is running" (Pitfall 11) but gives no state to check; two overlapping `completePaidBooking` calls would send two confirms for an attempt whose first outcome is unknown.
- **Fix:** Added `private(set) var isConfirmRunning`, set for the duration of `completePaidBooking`; the method returns at once if it is already true, and `retryConfirm()` also checks it.
- **Files modified:** `MakeABookingViewModel.swift`, `MakeABookingViewModel+PaidFlow.swift`
- **Verification:** `retryConfirmGuards` and `bookIsBlockedWhileAlertIsUp` rows pass.
- **Committed in:** `f0d4105`, `3fbcf3d`

**2. [Rule 2 - Missing critical] `resetPaidFlow()` also clears the stored pm_ id and the alert**
- **Found during:** Tasks 1 and 2
- **Issue:** The plan clears `confirmPaymentMethodId` only on the success, coded and Not now paths. Other resets (SCA cancel, the guard-failure path) would leave a stale pm_ id or alert behind.
- **Fix:** `resetPaidFlow()` clears both. The three explicit clears in the plan remain.
- **Files modified:** `MakeABookingViewModel.swift`
- **Committed in:** `f0d4105`, `3fbcf3d`

---

**Total deviations:** 2 auto-fixed (2 missing critical). **Impact on plan:** both harden the Pitfall 11 double-submit rule; no scope creep.

### Process notes

- Tasks 2 and 3 are `tdd="true"`, but the plan specifies one commit per task with the tests and the code together, so I did not split RED and GREEN commits. Tests and code were written in the same task and the suites were run green before each commit.
- The tracer's `<verify>` is automated-only under `human_verify_mode: end-of-phase`, so there was no mid-flight checkpoint: the tracer verify was re-run (both suites and the grep gates passed) and the plan continued to Task 2.

## Issues Encountered

None blocking. The warning baseline for the six app files was empty and the post-change builds and test builds showed no warnings in them (the only warning seen is the pre-existing `handleNextAction` deprecation in `MakeABookingStripePaymentSheet.swift`, out of scope).

Check My Bookings leaves the paid-flow state as it is, relying on the shell's `showMyBookings` action to pop the screen (the plan's rule that only Not now resets). If that action were nil outside a shell, the alert would stay up; in the app the shell is always present. Plan 04-13 records the abandoned confirm (D-04) when the screen is left.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or schema changes. T-04-21, T-04-22, T-04-24 and T-04-35 are mitigated and covered by tests (same `pi_test` and `pm_test` on every request body, unchanged `bookingAttemptId`, only the `pi_` id in the alert text, no second confirm while one runs). T-04-23 is accepted as planned.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Android follow-up

Logged, not built: D-03 retry behavior and copy (Android's `make_a_booking_error_unconfirmed` wording differs); D-17 `PAYMENT_IN_PROGRESS` as outcome unknown (Android's `PaidFlowError.kt` treats only network, decoding and unmapped 5xx as unknown). No backend change was needed or made.

## Next Phase Readiness

- Plan 04-13 can add the D-04 abandoned-confirm record and a second `PaidFlowAlert` case; it must not clear the record on an outcome-unknown `PAYMENT_IN_PROGRESS`.
- The device check (airplane mode during Confirming, restore, Try again; one booking, one hold) is logged in `.planning/WINDOWS.md` as an `unrun-verify` entry for the 04-14 session. The 409 `PAYMENT_IN_PROGRESS` case cannot be forced from the app, so it is proven by unit tests only.
- Full app test run: 557 tests in 59 suites pass (`xcodebuild test`, `-only-testing:ClickMe2026Tests`, the three non-compiling files excluded as before).

## Self-Check: PASSED

- Created files exist: `ConfirmOutcome.swift`, `ConfirmRetryPolicy.swift`, `MakeABookingViewModel+PaidFlow.swift`, `ConfirmOutcomeTests.swift`, `MakeABookingPaidFlowTests.swift`.
- Commits `f0d4105`, `3fbcf3d`, `894e142` are on `main`; `git rev-list --count bc94670..HEAD` was 3 at the last task commit.
- Acceptance criteria re-run: one top-level type in each of the two new util files; `enum RunResult<Value>` x1; `func retryConfirm() async` x1; `func dismissConfirmAlert()` x1; `Payment reference:` in the extension x1; `case paymentInProgress` x1; `"PAYMENT_IN_PROGRESS"` x1; `outcomeUnknownCodes` x4 in `ConfirmOutcome.swift`; `TODO(backend)` x0 app-wide.
- Plan verification: `ConfirmOutcomeTests` + `BookingErrorMapperTests` (26 tests), `MakeABookingPaidFlowTests` (12 tests in the final run), `BookingErrorCopyParityTests` (6 tests) pass; BUILD SUCCEEDED with no new warnings in the six app files.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
