---
phase: 03-booked-sessions-and-joining
plan: 04
subsystem: expert-bookings
tags: [swiftui, join-window, expert-booking-summary, reschedule, paid-booking-window]
status: complete

requires:
  - phase: 02-calls
    provides: "JoinWindow (CALL-02) and PaidBookingWindow (BOOK-14)"
provides:
  - "ExpertJoinVisibility: pure show/enable rule for Join Session on the expert Booking Summary (tested matrix)"
  - "Join Session above an outlined Message Client on ExpertBookingSummaryView, with join-failure and microphone alerts"
  - "Reschedule on an expert Upcoming card pushes HomeRoute.expertReschedule from the Bookings tab and the Dashboard"
  - "HomeExpertView route destinations receive the originating tab's path, so the reschedule form pops its own tab"
  - "Paid 6-day cap on the expert reschedule picker through PaidBookingWindow (ExpertRescheduleViewModel.isSelectableSlot / latestBookableStart)"
affects: [03-UAT, 03-12-checklist, android-parity]

actuals:
  tokens: 5750
  tasks: 3
  commits: 3
plan_head_before: d881de12c021c63558d20a4ef4e9bbffa405ce53
plan_head_after: 25f3374f71dcb8b9771c671c32338427b8141a9a

tech-stack:
  added: []
  patterns:
    - "Display gates over a shared window rule live in a pure caseless enum with injected now, so the status x window matrix is unit tested"
    - "Expert picker mirrors the client picker's cap members (latestBookableStart, isBookableStart, isSelectableSlot) over the one PaidBookingWindow helper"

key-files:
  created:
    - ClickMe2026/Utils/ExpertJoinVisibility.swift
    - ClickMe2026Tests/Utils/ExpertJoinVisibilityTests.swift
    - ClickMe2026Tests/Booking/ExpertRescheduleWindowTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleView.swift
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleTimeSlotsCard.swift

key-decisions:
  - "Join visibility on the expert summary is its own rule (confirmed, in_progress, pending_reschedule always; completed only inside JoinWindow.isOpen; everything else hidden), not JoinWindow.showsJoinButton, which also shows Join on cancelled, declined, missed and expired bookings"
  - "A booking is paid for the expert cap when session.consultationFee.amount > 0 (no payment_status on the expert details; mirrors Android ExpertBookingDetail.isPaid). Over-capping is safe; the server stays the backstop"
  - "The expert reschedule route pops the originating tab (nav.pop()) instead of always popping bookingsPath"

requirements-completed: [CALL-10, EXP-13]
---

# Phase 3 Plan 04: Expert Join on Booking Summary and Expert Reschedule Summary

**The expert Booking Summary now has a Join Session button gated by the shared join window, the expert Upcoming card's Reschedule opens the expert flow and returns to its own tab, and the expert picker refuses paid slots more than 6 days ahead through the same `PaidBookingWindow` the client pickers use.**

## Accomplishments

- **CALL-10:** `ExpertJoinVisibility.shows(...)` and `isEnabled(...)` sit over `JoinWindow.isOpen`. The summary renders Join Session directly above Message Client inside a 60 s `TimelineView`: accent fill with glow when enabled; 55% fill, no glow, disabled, hint "Available closer to the session start" when closed. A `pending_reschedule` booking shows it disabled. The tap calls `CallCenter.shared.startCall` with the client, topic, schedule and meeting type (`isRejoin` for a completed booking). While Join is shown, Message Client is outlined (transparent, accent label, 1.5 pt accent stroke at 50%, 50 pt). The summary hosts the "Couldn't join call" alert and the microphone alert bound to `CallCenter`.
- **EXP-13 routing:** `UpcomingBookingsView.handleReschedule(for:)` pushes `HomeRoute.expertReschedule` onto the tab's own path, replacing the no-op default; the Dashboard's embedded list gets it with no Dashboard edit. `HomeExpertView.homeRouteDestination(_:nav:)` passes the originating `nav`, and `onRescheduled` calls `nav.pop()`, so a reschedule started from the Dashboard no longer pops the Bookings tab.
- **EXP-13 cap (Phase 2 D-13):** `ExpertRescheduleViewModel` gains `isPaidBooking` (false until the detail loads), `isPaid(consultationFeeAmount:)`, `latestBookableStart`, `isBookableStart(_:)`, `isSelectableSlot(_:)`, a `select(time:)` guard and a local submit refusal with `BookingErrorMapper`'s `RESCHEDULE_TOO_FAR_AHEAD` copy and no request. `ExpertRescheduleView` passes `isBookable` and `showsPaidWindowNote` to the slots card, so far slots are dimmed and the note "Paid sessions can be rescheduled up to 6 days ahead." shows. There is no second 6-day constant in the expert code.

## Task Commits

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: expert joins from Booking Summary (CALL-10) | fcfbd2b |
| 2 | Expert Upcoming card opens reschedule on its own tab (EXP-13) | 352286e |
| 3 | Expert reschedule picker capped at 6 days for paid bookings (EXP-13) | 25f3374 |

## Verification

- `ExpertJoinVisibilityTests` + `JoinWindowTests`: 20 tests in 2 suites passed.
- `ExpertRescheduleWindowTests`: 8 tests passed. Regression run with `RescheduleWindowTests` and `PaidBookingWindowTests` plus both new suites: 42 tests in 6 suites passed.
- Debug build for iPhone 17 simulator: BUILD SUCCEEDED. Warning comparison against the pre-edit baseline (0 warnings in the touched files) printed nothing, so no new warnings.
- Plan grep checks pass: summary starts a call, uses the visibility rule and `joinError`; the card no longer passes the no-op `onReschedule`, pushes the route, the shell no longer pops `bookingsPath`, destinations receive `nav`; the expert view model uses `PaidBookingWindow.latestStart` and `.allows` with no hard-coded 6-day constant.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking test seam] Runtime init gained `isPaidBooking: Bool = false`**
- **Found during:** Task 3 (test for the local submit refusal)
- **Issue:** The preview init has no booking id, so `submit` stops at the missing-id guard before the limit check, and `isPaidBooking` is `private(set)`. The refusal row could not exercise the limit check.
- **Fix:** Added a defaulted `isPaidBooking` parameter to the runtime init, documented as a test seam. Production callers are unchanged and the default keeps the picker uncapped until the detail loads. The row builds `ExpertRescheduleViewModel(bookingId: UUID(), isPaidBooking: true)` and asserts the exact mapped copy.
- **Files modified:** ExpertRescheduleViewModel.swift, ExpertRescheduleWindowTests.swift
- **Commit:** 25f3374

**2. [Rule 1 - Layout] Join/Message block extracted to `joinAndMessageSection(detail:)` with an outer guard**
- **Found during:** Task 1
- **Issue:** An always-present `TimelineView` wrapping an empty `VStack` would add an extra 20 pt of stack spacing when neither button renders.
- **Fix:** The section renders only when Message is allowed, the server allows join, or the status is always-shown.
- **Commit:** fcfbd2b

Otherwise the plan was executed as written.

## Deferred device checks (Phase 3 UAT)

Tracer device check deferred under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT"). The Task 1 automated verification passed before expansion.

## Pending device checks

1. **CALL-10 (UI-SPEC D4):** on two accounts and a real iPhone, the expert opens Booking Summary inside the window; Join Session is the accent button above an outlined Message Client; tapping it connects both parties. Outside the window it is dimmed; on a pending reschedule it is visible and disabled. Also check that a refused join shows "Couldn't join call" once (the Bookings and Dashboard roots host an alert on the same `joinError`; SwiftUI presents one).
2. **EXP-13 routing:** from the expert Bookings tab and from Dashboard -> calendar, tap Reschedule on a card, pick a time and submit; the form closes back to the list on the same tab.
3. **EXP-13 cap:** as the expert, open Reschedule on a paid (CAD) booking; every day is visible, the note "Paid sessions can be rescheduled up to 6 days ahead." shows under Time Slots, and chips after now + 6 days are dimmed and untappable. On a free booking there is no note and no dimming from the cap.
4. **Plan 03-12 checklist note:** the Phase 2 BOOK-14 item says the expert picker is unchanged; this plan caps it.

## Android follow-up (not built)

- Check that Android's expert summary Join uses the same visibility set (confirmed, in_progress, pending_reschedule always; completed only inside the window).

## Requirements

CALL-10 and EXP-13 are fully delivered by this plan; no other Phase 3 plan lists them, so both are marked complete (device checks pending in UAT).

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or trust-boundary changes. T-03-07 and T-03-08 mitigated (matrix-tested visibility, `isEnabled` forwards to `JoinWindow.isOpen`, server authorizes `POST /join`). T-03-25 mitigated (dim, select guard and local refusal through `PaidBookingWindow`; server's `RESCHEDULE_TOO_FAR_AHEAD` remains authoritative). No backend change.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ExpertJoinVisibility.swift
- FOUND: ClickMe2026Tests/Utils/ExpertJoinVisibilityTests.swift
- FOUND: ClickMe2026Tests/Booking/ExpertRescheduleWindowTests.swift
- FOUND commits: fcfbd2b, 352286e, 25f3374
