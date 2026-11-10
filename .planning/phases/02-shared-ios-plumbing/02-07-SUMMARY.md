---
phase: 02-shared-ios-plumbing
plan: 07
subsystem: booking
tags: [swiftui, error-mapping, booking, stripe, swift-testing]

requires:
  - phase: 01-backend-fixes
    provides: "Backend long-lead refusals (LONG_LEAD_NOT_AVAILABLE, RESCHEDULE_TOO_FAR_AHEAD) live since 2026-10-28"
provides:
  - "BookingErrorMapper: one ErrorCode to copy table for booking and reschedule errors"
  - "PaidBookingWindow: the 6-day paid booking limit (inclusive edge)"
  - "ErrorCode.longLeadNotAvailable and .rescheduleTooFarAhead"
  - "MakeABookingViewModel.isBookableStart(_:) and isBeyondBookingWindow(_:)"
affects: [02-08 reschedule pickers, 03 expert reschedule picker (EXP-13)]

# Actuals (#2632): chars/4 over the realized diff
actuals:
  tokens: 10800
  tasks: 3
  commits: 3
plan_head_before: 01edabe1674d00473fc0d6755f4f5c4b72392fbb
plan_head_after: 5450ddaea3a27ca88bb46d9bd29dcdd0ffaefeda

tech-stack:
  added: []
  patterns:
    - "Branch on ErrorCode through BookingErrorMapper; the paid copy is the base, context-specific copy stays in the owning view model"
    - "Limit helpers never read the clock; callers pass Date() at each evaluation"

key-files:
  created:
    - ClickMe2026/Utils/BookingErrorMapper.swift
    - ClickMe2026/Utils/PaidBookingWindow.swift
    - ClickMe2026Tests/Utils/BookingErrorMapperTests.swift
    - ClickMe2026Tests/Utils/PaidBookingWindowTests.swift
    - ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift
  modified:
    - ClickMe2026/Model/Enums/ErrorCode.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift

key-decisions:
  - "Both long-lead codes are terminal in handlePaidFlowError: clear the slot, new attempt, show the 6-day copy, reset the paid flow; the no-PaymentIntent confirm method and preferredPaymentMethodId are deleted"
  - "Paid cap is inclusive at exactly now + 6 days, matching the backend's strictly-greater refusal; the limit is recomputed from Date() on every read"
  - "Days past the limit render blank and disabled (not greyed); the selected-day circle is not drawn on a blank day"

patterns-established:
  - "BookingErrorMapper.message(for:fallback:) for any booking-side error alert; Error.userMessage as the fallback"
  - "Tests that share MockURLProtocol live in one .serialized suite; suites that never reach the API must not call APITestFactory"

requirements-completed: [BOOK-14, PAY-05]

coverage:
  - id: D1
    description: "A paid booking refused with LONG_LEAD_REQUIRES_SAVED_CARD or LONG_LEAD_NOT_AVAILABLE shows the 6-day copy, clears the slot, and makes no POST /bookings/confirm call"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift#longLeadNeverConfirms, longLeadNotAvailableNeverConfirms"
        status: pass
    human_judgment: false
  - id: D2
    description: "ErrorCode decodes LONG_LEAD_NOT_AVAILABLE and RESCHEDULE_TOO_FAR_AHEAD with the plan's copy"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingErrorMapperTests.swift#newCodesDecode, rescheduleCopy"
        status: pass
    human_judgment: false
  - id: D3
    description: "Free and paid paths show the same text for SLOT_UNAVAILABLE, MEETING_LINK_UNAVAILABLE and unmapped codes, and both clear the slot on SLOT_UNAVAILABLE"
    requirement: PAY-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift#slotUnavailable, meetingLinkUnavailable, unmappedCodeShowsServerMessage"
        status: pass
    human_judgment: false
  - id: D4
    description: "Paid pickers offer no slot beyond now + 6 days (edge and edge + 1 s), blank the days past it, leave free topics uncapped, and clear a far slot on a free-to-paid topic switch"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/PaidBookingWindowTests.swift#paidEdge, dayBeyond, slotsAreFiltered, switchingTopicClearsFarSlot"
        status: pass
    human_judgment: false
  - id: D5
    description: "The calendar cell for a day past the paid limit renders blank and cannot be tapped on a real device"
    requirement: BOOK-14
    verification: []
    human_judgment: true
    rationale: "SwiftUI cell rendering and tap behavior is not asserted by any unit test; the device UAT item BOOK-14 covers it"

duration: 10min
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 07: Booking Error Copy and the 6-Day Paid Cap Summary

**Shared BookingErrorMapper for free and paid booking errors, long-lead codes made terminal (no more confirm without a PaymentIntent), and a 6-day paid picker cap driven by PaidBookingWindow**

Every test in this plan mocks the API through `MockURLProtocol`; no real hold, charge or request reaches the live backend.

## Performance

- **Duration:** about 10 min
- **Started:** 2026-11-10T01:50Z
- **Completed:** 2026-11-10T01:59Z
- **Tasks:** 3
- **Files modified:** 8 (5 created, 3 modified)

## Accomplishments

- A paid booking the server refuses as long-lead now ends in "Paid sessions can be booked up to 6 days ahead. Please choose an earlier time.", the picked slot is cleared, and no `/bookings/confirm` request is made. The retired save-card path (`performLongLeadBooking`, `preferredPaymentMethodId`) is deleted, so the app can no longer create a booking without a payment hold (T-02-13).
- `ErrorCode` decodes `LONG_LEAD_NOT_AVAILABLE` and `RESCHEDULE_TOO_FAR_AHEAD`. Backend contract checked against `booking.controller.js` L477-482 / L1217, `reschedule.js` L76-83 and the OpenAPI file; no backend change.
- Free and paid booking paths share `BookingErrorMapper`. The free path used to show raw server text; it now shows the same written copy as the paid path and clears the slot on `SLOT_UNAVAILABLE`. The private `message(for:)` and `errorCode(for:)` helpers are gone (`Error.userMessage` and `BookingErrorMapper.code(for:)` replace them).
- Paid topics hide slots past now + 6 days and the calendar blanks days past it. Exactly 6 days is offered, 6 days + 1 second is not. Free topics are not capped. The limit is read from `Date()` at every evaluation.

## Task Commits

1. **Task 1: Tracer, long-lead refusal shows a clear error and never confirms without a PaymentIntent** - `b52159c` (fix)
2. **Task 2: Free and paid paths share the same error copy (PAY-05)** - `af0abe2` (fix)
3. **Task 3: Paid picker hides slots and days beyond 6 days (BOOK-14)** - `5450dda` (fix)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified

- `ClickMe2026/Utils/BookingErrorMapper.swift` - ErrorCode to copy table; `code(for:)`, `message(for:fallback:)`, `message(for:)`
- `ClickMe2026/Utils/PaidBookingWindow.swift` - nonisolated 6-day limit helper mirroring backend `LONG_LEAD_THRESHOLD_MS`
- `ClickMe2026/Model/Enums/ErrorCode.swift` - two new cases; long-lead comment rewritten (save-card branch retired 2026-10-28)
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` - long-lead fall-through deleted, mapper wired into both paths, cap applied to slots, topic switch and `book()`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift` - days past the limit are blank and disabled
- `ClickMe2026Tests/Utils/BookingErrorMapperTests.swift` (8 tests), `ClickMe2026Tests/Utils/PaidBookingWindowTests.swift` (4 + 6 view-model rows), `ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift` (6 tests through the real view model)

## Decisions Made

- Both long-lead codes are terminal and share one message; `RESCHEDULE_TOO_FAR_AHEAD` has its own reschedule copy for plan 02-08 to use.
- The 6-day limit is inclusive at the edge, matching the backend's strictly-greater refusal.
- The selected-day circle is not drawn on a blank (beyond-limit) day, so a selected date that ends up past the limit after a topic switch does not show a green circle on an empty cell.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test suites raced on the shared MockURLProtocol handler**
- **Found during:** Task 3 (first combined test run)
- **Issue:** The view-model rows I first wrote built their API with `APITestFactory.make`, which resets and replaces the shared `MockURLProtocol.handler`. Suites run in parallel, so it overwrote the handler while the parity suite was awaiting a response, and the free SLOT_UNAVAILABLE parity test failed once.
- **Fix:** The view-model rows no longer touch the mock (they never call the API). The "book() refuses a far slot and makes no request" row moved into the `.serialized` parity suite, where it records request paths. View-model rows are nested in `PaidBookingWindowTests` so the plan's single `-only-testing:` filter still runs them.
- **Files modified:** ClickMe2026Tests/Utils/PaidBookingWindowTests.swift, ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift
- **Verification:** Two consecutive combined runs, 24 tests in 4 suites passed each time.
- **Committed in:** 5450dda (part of the Task 3 commit)

**2. [Rule 2 - Missing critical] Guard in book() for a slot past the limit**
- **Found during:** Task 3
- **Issue:** The plan asked for this guard; recorded here because it is the only place a stale slot (screen left open past a day boundary) is caught, and it makes no API call.
- **Fix:** `book()` clears the slot and sets the long-lead copy before branching free or paid.
- **Committed in:** 5450dda

---

**Total deviations:** 1 auto-fixed bug (test isolation), 1 plan-directed guard noted
**Impact on plan:** No scope change; the test fix made the suites deterministic.

## Issues Encountered

- A pre-existing deprecation warning in `MakeABookingStripePaymentSheet.swift:197` (`handleNextAction(forPayment:...)`) shows in builds. It is outside this plan's files and was not touched. Warning comparison for this plan's files: baseline 0, after 0.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or schema changes. T-02-13 (no-PI confirm) is mitigated and covered by the parity tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-08 can use `PaidBookingWindow` and `BookingErrorMapper.rescheduleTooFarAheadMessage` for the client reschedule pickers.
- Device check pending (UAT item BOOK-14): on a paid topic the calendar shows nothing selectable after day 6 and no slot chip past now + 6 days; a free topic shows the full month again.
- Android: no change needed (it already caps paid pickers and maps both codes).

## Self-Check: PASSED

- Created files exist: BookingErrorMapper.swift, PaidBookingWindow.swift, three test files.
- Commits `b52159c`, `af0abe2`, `5450dda` are ancestors of HEAD.
- Acceptance greps: `paymentIntentId: nil` count 0, `preferredPaymentMethodId` count 0, `longLeadNotAvailable` count 1 in ErrorCode.swift, `private static func message(for` count 0, `"That time slot was just taken` count 0 in the view model, `isBeyondBookingWindow` present in the calendar card.
- Final BUILD SUCCEEDED; 24 tests in 4 suites passed; no new warnings.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
