---
phase: 02-shared-ios-plumbing
plan: 08
subsystem: booking
tags: [swiftui, reschedule, booking, error-mapping, swift-testing, android-parity]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "02-07: PaidBookingWindow, BookingErrorMapper, ErrorCode.rescheduleTooFarAhead"
provides:
  - "PaidBookingWindow.isPaidReschedule(paymentStatus:topicIsFree:)"
  - "Client reschedule picker capped at now + 6 days for paid bookings: every day visible, far slots dimmed, fixed paid note"
  - "Make a Booking picker reworked the same way (02-07 follow-up): no blank days, far slots dimmed, fixed paid note"
  - "isSelectableSlot(_:) and an internal latestBookableStart on both client picker view models"
  - "Both reschedule view models route non-reschedule-only codes through BookingErrorMapper"
affects: [02-12 device UAT checklist, 03 expert reschedule picker (EXP-13), 02-UI-SPEC section 4]

# Actuals (#2632): chars/4 over the realized diff (eaeb92a..2045935)
actuals:
  tokens: 11589
  tasks: 2
  commits: 5
plan_head_before: eaeb92abc3a51a25ee22c66c65e25283344a3af4
plan_head_after: 204593585ca094ec9b17ec69cf317e8c7e14f15c

tech-stack:
  added: []
  patterns:
    - "Picker caps never hide: a slot the server would refuse stays listed and dims through isSelectableSlot(_:); a non-nil latestBookableStart also shows the fixed window note (Android latestSelectableStart)"
    - "Reschedule-only copy stays in the owning view model; every other code goes through BookingErrorMapper"

key-files:
  created:
    - ClickMe2026Tests/Booking/RescheduleWindowTests.swift
    - .planning/phases/02-shared-ios-plumbing/02-08-tdd-red-evidence.json
  modified:
    - ClickMe2026/Utils/PaidBookingWindow.swift
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleView.swift
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleTimeSlotsCard.swift
    - ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift
    - ClickMe2026/Localizable.xcstrings
    - ClickMe2026Tests/Utils/PaidBookingWindowTests.swift

key-decisions:
  - "User decision 2026-11-10: the paid 6-day cap on both client pickers matches Android exactly. Days are never hidden or blanked; slots past now + 6 days stay listed and render dimmed and untappable; a fixed note shows for a paid topic or paid booking. This supersedes the 02-07 blank-day decision (W1-9, W1-10) and the hidden-day half of this plan's Task 1"
  - "Note copy is Android's verbatim: 'Paid sessions can be booked up to 6 days ahead.' (Make a Booking) and 'Paid sessions can be rescheduled up to 6 days ahead.' (Reschedule), both added to Localizable.xcstrings; the on-selection warning 'Only 6 days are bookable.' was considered and dropped by the user"
  - "A reschedule day with an available slot stays tappable even when every slot is past the limit; only past days and days with no available slot dim (pre-existing rule)"
  - "The expert reschedule picker passes neither isBookable nor showsPaidWindowNote and is unchanged (D-13; EXP-13 in Phase 3)"

patterns-established:
  - "isSelectableSlot(_:) = available AND start > now AND inside the paid limit; the chip's disabled state and the scroll-to-first jump both read it"
  - "Nested @Suite structs inside the plan's test struct so one -only-testing: filter runs every row"

requirements-completed: [BOOK-14]

coverage:
  - id: D1
    description: "A booking counts as paid for the reschedule limit when payment_status is not none or the topic is not free"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleWindowTests.swift#paidFlag"
        status: pass
    human_judgment: false
  - id: D2
    description: "Client reschedule, paid booking: exactly now + 6 days is bookable and one second later is not; a day past the limit stays tappable with its slots listed, none selectable, and select(time:) refuses them; a day inside the limit keeps selectable slots"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleWindowTests.swift#paidEdge, dayAfterLimit, dayInsideLimit, unavailableOrPastSlot"
        status: pass
    human_judgment: false
  - id: D3
    description: "The paid window note flag (latestBookableStart != nil) is set for a paid booking or paid topic and nil for a free one, on both pickers"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleWindowTests.swift#paidBookingShowsNote, freeBookingNotCapped; ClickMe2026Tests/Utils/PaidBookingWindowTests.swift#paidTopicShowsNote, freeTopicNotCapped"
        status: pass
    human_judgment: false
  - id: D4
    description: "A free reschedule is not capped, and the runtime view model is uncapped until the detail loads"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleWindowTests.swift#freeBookingNotCapped, runtimeDefaultsToUncapped"
        status: pass
    human_judgment: false
  - id: D5
    description: "RESCHEDULE_TOO_FAR_AHEAD shows the shared reschedule copy on both screens; SLOT_UNAVAILABLE reads as on Make a Booking; the reschedule-only client and expert copy is kept; an unmapped code shows the server message"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleWindowTests.swift#ErrorCopyRows (7 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Make a Booking, paid topic (02-07 rework): far slots stay listed but are not selectable, a far day has zero selectable slots, a far slot held under a free topic is cleared on the switch to paid, past and unavailable slots are never selectable"
    requirement: BOOK-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/PaidBookingWindowTests.swift#farSlotsStayListedButDimmed, dayPastLimitHasNoSelectableSlot, selectableSlotRules, switchingTopicClearsFarSlot, switchingTopicKeepsNearSlot"
        status: pass
    human_judgment: false
  - id: D7
    description: "The expert reschedule calendar and slots card are not capped and show no note"
    requirement: BOOK-14
    verification:
      - kind: other
        ref: "grep -c 'showsPaidWindowNote' 'ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleView.swift' prints 0, and its RescheduleTimeSlotsCard call (L120-125) passes only slots, selectedTime, isCurrent and onSelect; RescheduleCalendarCard has no hiding parameter any more"
        status: pass
    human_judgment: false
  - id: D8
    description: "On a real device, both pickers show every day, the paid note under the slots title, and dimmed untappable chips past 6 days for a paid (CAD) booking; a free booking shows no note and nothing dimmed by the cap"
    requirement: BOOK-14
    verification: []
    human_judgment: true
    rationale: "SwiftUI chip rendering, dimming and tap rejection are not asserted by unit tests; deferred to the 02-12 device UAT checklist (see Next Phase Readiness)"

duration: 21min
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 08: Reschedule Paid Cap and Shared Error Copy Summary

**Client reschedule picker capped at 6 days for paid bookings the Android way (every day visible, far slots dimmed, a fixed paid note), the 02-07 Make a Booking picker reworked to the same rule, and both reschedule view models routing error copy through BookingErrorMapper**

Every test in this plan runs against in-memory view models or a static mapping function; none reaches the API and no real hold or request is made.

## Performance

- **Duration:** about 21 min of execution (Task 1 segment 2026-11-10T04:11Z to 04:16Z by the previous executor; this continuation 04:20Z to 04:37Z), plus the tracer gate pause in between
- **Started:** 2026-11-10T04:11Z
- **Completed:** 2026-11-10T04:37Z
- **Tasks:** 2 (plus the user-directed rework of Task 1 and of 02-07 Task 3)
- **Files modified:** 13 (2 created, 11 modified)

## Accomplishments

- `PaidBookingWindow.isPaidReschedule(paymentStatus:topicIsFree:)` decides the paid flag from `payment_status != "none" || !topic.isFree`, so a long-lead paid booking with no PaymentIntent yet is still capped (mirrors Android `RescheduleRules.isPaid`).
- Client reschedule, paid booking: slots past now + 6 days stay in the list and render dimmed and untappable (`isSelectableSlot(_:)`, new `isBookable` closure on `RescheduleTimeSlotsCard`); `select(time:)` refuses them; a held slot that falls past the limit on a reload is cleared; `submit` still refuses locally with the `RESCHEDULE_TOO_FAR_AHEAD` copy and makes no request. The calendar shows every day; the `isHidden` hiding from `9cf8c0d` is removed. A paid booking shows "Paid sessions can be rescheduled up to 6 days ahead." under the Time Slots title. Free bookings are unchanged.
- Make a Booking (02-07 follow-up, same user decision): the blank-day branch and `isBeyondBookingWindow(_:)` are removed, `slotsForSelectedDate` keeps every slot, chips dim through `isSelectableSlot(_:)`, and a paid topic shows "Paid sessions can be booked up to 6 days ahead." in the slots card. The free-to-paid topic switch still clears a far slot; `book()` still refuses locally.
- Both strings are in `Localizable.xcstrings`; both calendars' month chevrons carry `Previous month` / `Next month` accessibility labels (02-UI-SPEC C1).
- `RescheduleViewModel.rescheduleErrorMessage(for:)` and `ExpertRescheduleViewModel.rescheduleErrorMessage(for:)` are internal and send every code except their reschedule-only cases through `BookingErrorMapper`, so `RESCHEDULE_TOO_FAR_AHEAD` reads "Paid sessions can be rescheduled up to 6 days ahead. Please choose a time within the next 6 days." on both screens and `SLOT_UNAVAILABLE` reads as on Make a Booking. The client's private `errorCode(for:)` helper and the expert's inline `StandardErrorResponse` decode are gone.

## Task Commits

1. **Task 1 (tracer, as planned): cap the client reschedule picker at 6 days for paid bookings** - `9cf8c0d` (fix) by the previous executor; stopped at the tracer gate
2. **Rework (a), user-directed: Make a Booking keeps days past the limit visible and dims their slots** - `1ddd0d0` (fix(02-07))
3. **Rework (b), user-directed: Reschedule keeps days past the limit visible and dims their slots** - `9f85dc2` (fix(02-08))
4. **Task 2 RED: failing tests for the shared reschedule error copy** - `73b92da` (test)
5. **Task 2 GREEN: reschedule screens share the booking error copy** - `2045935` (fix)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## TDD Gate Compliance (Task 2, `tdd="true"`)

- **RED** `73b92da`: 7 error-copy rows added; 3 failed on the planned assertions (client and expert `RESCHEDULE_TOO_FAR_AHEAD`, client `SLOT_UNAVAILABLE`, each returning the server text), 12 of 15 rows in the suite passed. Classifier: `RED_EVIDENCE_OK` (`target_test_failed`, swift-testing format, exit 65). Semantic assessment: valid RED, no load/syntax/fixture fault. Record: `02-08-tdd-red-evidence.json` next to this file.
- **GREEN** `2045935`: 23 tests in 3 suites pass (`RescheduleWindowTests`, `ErrorCopyRows`, `BookingErrorMapperTests`).
- **REFACTOR:** none needed; no commit.
- Note: the GREEN commit uses the plan's prescribed `fix(02-08): …` message rather than `feat(02-08)`, because the plan's `<action>` names it and `workflow.tdd_mode` is off. Recorded so the sequence reads correctly.

## Files Created/Modified

- `ClickMe2026/Utils/PaidBookingWindow.swift` - `isPaidReschedule(paymentStatus:topicIsFree:)`
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift` - `isPaidBooking`, internal `latestBookableStart`, `isBookableStart(_:)`, `isSelectableSlot(_:)`, `select(time:)` guard, held-slot clear on load, local submit refusal, mapper-backed error copy
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleView.swift` - passes `isBookable` and `showsPaidWindowNote` to the slots card
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift` - chevron accessibility labels; no hiding parameter
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleTimeSlotsCard.swift` - defaulted `isBookable` and `showsPaidWindowNote`; the paid note
- `ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleViewModel.swift` - internal `rescheduleErrorMessage(for:)` through the mapper
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` - unfiltered `slotsForSelectedDate`, internal `latestBookableStart`, `isSelectableSlot(_:)`; `isBeyondBookingWindow(_:)` removed
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift` - blank-day branch removed; chevron labels
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift` - paid note; chips dim through `isSelectableSlot`
- `ClickMe2026/Localizable.xcstrings` - the two note strings
- `ClickMe2026Tests/Booking/RescheduleWindowTests.swift` (8 window rows + 7 error-copy rows), `ClickMe2026Tests/Utils/PaidBookingWindowTests.swift` (view-model rows reworked, 4 + 8)
- `.planning/phases/02-shared-ios-plumbing/02-08-tdd-red-evidence.json` - RED evidence record

## Decisions Made

See `key-decisions` in the frontmatter. In short: Android parity for the paid cap on both client pickers (user, 2026-11-10); Android's note copy verbatim; a reschedule day with an available slot stays tappable; the expert picker is untouched.

## Deviations from Plan

### User-directed

**1. [User decision 2026-11-10] Paid cap matches Android: nothing hidden, far slots dimmed, fixed note**
- **Found during:** The tracer gate after Task 1. The user reviewed the Make a Booking screen (02-07 behavior, mirrored by Task 1 here), rejected the blank/hidden days, first asked for an on-selection warning ("Only 6 days are bookable."), then settled on exact Android parity.
- **Issue:** 02-07 Task 3 and this plan's Task 1 implemented "hide" as blank, untappable day cells and dropped slot chips (02-CONTEXT discretion note; 02-UI-SPEC W1-9, W1-10, section 4). The user wants Android's behavior: every day visible and tappable, slots past now + 6 days dimmed and untappable but never hidden, and a fixed note in the slots card for a paid topic or booking.
- **Fix:** Commits `1ddd0d0` (Make a Booking, `fix(02-07)`) and `9f85dc2` (Reschedule, `fix(02-08)`), described above. The inclusive edge, the paid/free detection, the free-to-paid slot clear, the local submit refusals and the server 422 backstop are unchanged. Tests were rewritten to pin the new behavior.
- **Files modified:** the nine app files and two test files listed above, plus `Localizable.xcstrings`
- **Verification:** 26 tests in 4 suites (Make a Booking side) and 20 tests in 3 suites (Reschedule side) pass; BUILD SUCCEEDED; warning comparison prints nothing.
- **Follow-up for the UI contract:** `02-UI-SPEC.md` still records the blank-day rule (W1-9, W1-10, section 4 table, the month-blank caption rows in E1/A1, D5 of 02-07-SUMMARY). The month-blank caption and the blank-cell `accessibilityHidden` deltas are now moot (no cell is ever blank); the chevron labels (C1) are done on both calendars. The spec should be revised to the parity behavior before the Phase 02 UAT.

### Auto-fixed Issues

**2. [Rule 2 - Missing critical] Chevron accessibility labels on both calendars**
- **Found during:** Rework (a) and (b)
- **Issue:** 02-UI-SPEC marks `Previous month` / `Next month` labels as required (C1), owned by 02-08 for Reschedule and an open gap for Make a Booking.
- **Fix:** `accessibilityLabel` on the four chevron buttons, in the same commits.
- **Committed in:** `1ddd0d0`, `9f85dc2`

---

**Total deviations:** 1 user-directed behavior change (reworks 02-07 Task 3 and 02-08 Task 1), 1 auto-added accessibility requirement.
**Impact on plan:** BOOK-14 is still delivered on both client pickers, with Android's presentation instead of blank days. No API or backend change. Plan 02-07's artifacts change: `MakeABookingViewModel.isBeyondBookingWindow(_:)` no longer exists; `isSelectableSlot(_:)` replaces it.

## Issues Encountered

- `9cf8c0d` (Task 1 as planned) remains in history and is superseded by `9f85dc2`; history was not rewritten.
- A pre-existing deprecation warning in `MakeABookingStripePaymentSheet.swift` (outside this plan) did not re-emit on the incremental build; the plan files have 0 warnings before and after (baselines `/tmp/02-08-warn-before.txt` and `/tmp/02-08-warn-before-rework.txt`, both empty; after: empty).

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or schema changes. T-02-15 (paid reschedule beyond 6 days) stays mitigated: the client refuses submit locally for a slot past the limit and the server's 422 `RESCHEDULE_TOO_FAR_AHEAD` is the authority, now with clear copy on both screens. Dimming instead of hiding does not widen the surface: a dimmed chip is disabled and `select(time:)` refuses it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Device check PENDING (UAT item BOOK-14), deferred to 02-12's `02-DEVICE-UAT-CHECKLIST.md`.** On a paid (CAD) booking, check both Make a Booking and client Reschedule: all calendar days are visible and tappable, including the next month; the note ("Paid sessions can be booked up to 6 days ahead." / "Paid sessions can be rescheduled up to 6 days ahead.") is shown under the slots title whatever day is selected; slot chips starting after now + 6 days are dimmed and cannot be tapped; a chip at or before now + 6 days can. A free booking shows no note and nothing dimmed by the cap. The expert reschedule picker is unchanged.
- **Android follow-up: none for copy.** The earlier note (Android fixed note versus an iOS on-selection warning) is resolved by parity; iOS now uses Android's strings and presentation.
- **02-UI-SPEC revision** needed for section 4 and W1-9/W1-10 (see deviation 1).
- Phase 3 EXP-13 can reuse `RescheduleTimeSlotsCard.isBookable` / `showsPaidWindowNote` and `RescheduleViewModel.isSelectableSlot(_:)` for the expert picker.

## Self-Check: PASSED

- Created files exist: `RescheduleWindowTests.swift`, `02-08-tdd-red-evidence.json`; modified files present (`PaidBookingWindow.swift`, `RescheduleTimeSlotsCard.swift`, `Localizable.xcstrings` parses as JSON).
- Commits `9cf8c0d`, `1ddd0d0`, `9f85dc2`, `73b92da`, `2045935` are ancestors of HEAD; `git rev-list --count eaeb92a..2045935` = 5 (matches `commits:` above).
- Acceptance and verify gates: `isPaidReschedule` count in `RescheduleViewModel.swift` = 2 (baseline 0); `private static func errorCode(for` count = 0 (baseline 1); `BookingErrorMapper.message` present in `ExpertRescheduleViewModel.swift`; `ExpertRescheduleView.swift` has no `showsPaidWindowNote`; no `isBeyondBookingWindow` or `isHidden` left in app or test code.
- Tests: 26 tests in 4 suites (Make a Booking side), 20 in 3 (Reschedule window side), 23 in 3 (Task 2) all passed; RED classifier `RED_EVIDENCE_OK`.
- Final BUILD SUCCEEDED; warning comparison for the plan's files prints nothing against both baselines.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
