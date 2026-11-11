---
phase: 03-booked-sessions-and-joining
plan: 11
subsystem: ui
tags: [swiftui, reschedule, availability, navigation, toast, empty-state, swift-testing]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: ToastCenter with injectable instance (03-06), ClientBookingFixtures and bodyDataForTest (03-01), "Settings > Payment" removed from Booking Summary (03-13)
provides:
  - getExpertAvailability(id:month:excludeBookingId:), sending exclude_booking_id only when given
  - Client reschedule picker that excludes the booking being moved, posts "Reschedule request sent" and returns one level
  - Reschedule error copy that names Profile > Payment and gives accurate advice for RESCHEDULE_OUTSIDE_AUTH_WINDOW
  - MyBookingsView.pop(), used by Reschedule and Keep Booking
  - PastEmptyState and MyBookingsViewModel.showsPastEmptyState
affects: [03-12 device UAT, 03-07, android-parity]

actuals:
  tokens: 4500   # chars/4 over the added lines of the realized diff (18,073 chars)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Optional query parameter added to an endpoint method with a nil default, so existing callers are untouched"
    - "Producer posts the toast after the 2xx and immediately before the pop callback"
    - "Screen-level pop() next to popToRoot() so each return chooses its depth"

key-files:
  created:
    - ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/PastEmptyState.swift
    - ClickMe2026Tests/Booking/RescheduleAvailabilityTests.swift
    - ClickMe2026Tests/Booking/MyBookingsEmptyStateTests.swift
  modified:
    - ClickMe2026/Network/ClickMeAPI+Availability.swift
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsView.swift
    - ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift
    - ClickMe2026Tests/Booking/RescheduleWindowTests.swift

key-decisions:
  - "RescheduleViewModel takes toasts: ToastCenter = .shared by injection (runtime init only), like RescheduleResponder, so tests never touch the shell's toast"
  - "The toast is posted on both success paths (first attempt and the saved-card retry), immediately before onSuccess"
  - "showsPastEmptyState is true only for state == .loaded, selectedTab == 1 and no past bookings; idle, loading and failed never show it"

patterns-established:
  - "Reschedule-only error copy stays in RescheduleViewModel and always names Profile > Payment"

requirements-completed: [BOOK-11]

coverage:
  - id: D1
    description: "The client reschedule picker's availability request carries exclude_booking_id for the booking being moved; Make a Booking and the expert picker send none"
    requirement: BOOK-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleAvailabilityTests.swift#apiSendsExclude, apiOmitsExclude, loadExcludesOwnBooking"
        status: pass
    human_judgment: false
  - id: D2
    description: "A sent reschedule request posts 'Reschedule request sent' and calls onSuccess once; a failure posts no toast and does not return"
    requirement: BOOK-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleAvailabilityTests.swift#submitPostsToastAndReturns, outsideAuthWindowShowsNoToast, emptyVaultNamesProfilePayment"
        status: pass
    human_judgment: false
  - id: D3
    description: "The three changed reschedule errors read the UI-SPEC copy and no 'Settings > Payment' remains in the app target or tests"
    requirement: BOOK-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleWindowTests.swift (ErrorCopyRows#clientKeepsOwnCopy), RescheduleAvailabilityTests#unusableCardCopyNamesProfilePayment"
        status: pass
      - kind: other
        ref: "grep -rn 'Settings > Payment' ClickMe2026 ClickMe2026Tests == 0; 'authorize a new payment' == 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Keep Booking pops one level; a confirmed cancel still pops to the root; the reschedule return pops one level"
    requirement: BOOK-12
    verification:
      - kind: other
        ref: "grep gates on MyBookingsView.swift: onKeepBooking: { pop() } 1, onKeepBooking: { popToRoot() } 0, onConfirmCancellation popToRoot 1, onRescheduled: { pop() } 1"
        status: pass
    human_judgment: true
    rationale: "SwiftUI navigation depth has no unit seam (the destination closures are private to the view); the grep gate proves the wiring and a device run proves the screen reached. On the Phase 3 UAT checklist"
  - id: D5
    description: "The Past tab empty state shows only after a successful load with no past bookings, never while loading or after a failed load"
    requirement: BOOK-11
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MyBookingsEmptyStateTests.swift (pastTabEmpty, upcomingTabEmpty, pastTabWithBooking, notWhileLoading, notAfterFailure)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Layout of the Past empty state (illustration, 22 pt title, wrapping at large Dynamic Type) and the on-device return flows"
    verification: []
    human_judgment: true
    rationale: "Visual layout and navigation feel need a real iPhone; listed under Deferred device checks (human_verify_mode is end-of-phase)"

duration: 15min
completed: 2026-11-11
plan_head_before: 82c996274bf468f632f9f67c427a8bfbc37ec2e0
plan_head_after: f59c3ba57b3e4e076ce463ce475de7f454994e8b
commits: 2
status: complete
---

# Phase 3 Plan 11: Reschedule request return, exclude own slot, Keep Booking, Past empty state Summary

**The client reschedule picker now sends `exclude_booking_id` so a booking's own slot is not greyed, a sent request pops exactly one level and shows "Reschedule request sent", its errors name Profile > Payment with accurate held-booking advice, Keep Booking returns one screen, and an empty Past tab explains itself.**

## Performance

- **Duration:** about 15 min
- **Completed:** 2026-11-11 (UTC)
- **Tasks:** 2 of 2
- **Files modified:** 8 (3 created, 5 modified), 2 commits

## Accomplishments

- `ClickMeAPI.getExpertAvailability(id:month:excludeBookingId:)` adds `exclude_booking_id` only when given; the three existing callers (Make a Booking, expert reschedule) keep the default and send nothing new.
- `RescheduleViewModel` passes `excludeBookingId: bookingId` in `fetchAvailability`, takes an injectable `toasts: ToastCenter`, and posts "Reschedule request sent" before `onSuccess()` on both success paths.
- Copy: no saved card and unusable card now read "Profile > Payment"; `RESCHEDULE_OUTSIDE_AUTH_WINDOW` reads "This time is past the payment hold on your original booking. Choose a different time, or cancel this booking and book again. Cancelling releases the hold on your card, so you won't be charged." The doc comment describes the code as a live hold whose move cannot be converted, with booking and hold untouched. "Settings > Payment" and "authorize a new payment" are gone from the app target and tests.
- `MyBookingsView.pop()` (one level via `navPath.pop()` or `_localPath.removeLast()`) now serves `.rescheduleBooking` (`onRescheduled`) and the cancel screen's `onKeepBooking`; the confirmed cancel still calls `popToRoot()`.
- `PastEmptyState` (calendar illustration, 22 pt semibold title, callout body, no button) renders from `loadedContent` when `showsPastEmptyState` is true; the Past preview gained an empty variant.
- 12 new tests (7 availability and return, 5 empty state); the 15 `RescheduleWindowTests` rows pass with the updated copy constants.

## Task Commits

1. **Task 1: Tracer, a reschedule request returns one level with "Reschedule request sent", and the picker no longer blocks the booking's own slot** - `9fdb991` (fix)
2. **Task 2: Keep Booking goes back one screen; the Past tab has an empty state** - `f59c3ba` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Network/ClickMeAPI+Availability.swift` - optional `excludeBookingId`, doc citing `availability.controller.js`
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift` - exclude parameter, injected toasts, toast on both success paths, new copy and doc comment
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsView.swift` - `pop()`, one-level returns, Past empty branch and preview
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift` - `showsPastEmptyState`
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/PastEmptyState.swift` - the Past tab empty state
- `ClickMe2026Tests/Booking/RescheduleAvailabilityTests.swift` - exclude parameter, toast and return, copy rows
- `ClickMe2026Tests/Booking/MyBookingsEmptyStateTests.swift` - empty-state predicate rows
- `ClickMe2026Tests/Booking/RescheduleWindowTests.swift` - the two client copy constants

## Decisions Made

- The toast is injected into `RescheduleViewModel` (runtime init only; the preview init uses `.shared` and has no booking id, so it never posts).
- The toast is posted on the first-attempt and the saved-card-retry success paths, so the confirmation never depends on which path the server took.
- The empty-state predicate lives on the view model so it is unit tested; the view only branches on it.

## Deviations from Plan

None - plan executed exactly as written.

Task 2 is marked `tdd="true"`, but the predicate and its rows were written in one commit as the plan specifies one commit per task; the rows passed on first run. Same pattern as plans 03-01, 03-06 and 03-13. The navigation-depth change has no unit seam (the destination closures are private to the view), so it is covered by the grep gates and the device checks.

## Issues Encountered

None. Baseline and final warning sets for the five plan files were both empty (no new warnings).

## Verification

- `RescheduleAvailabilityTests`: 7 tests in 1 suite passed. `RescheduleWindowTests`: 15 tests in 2 suites passed. `MyBookingsEmptyStateTests`: 5 tests passed. Regression `ClientBookingStatusFallbackTests`: 5 tests passed (`/tmp/03-11-reg.log`).
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded; the warning comparison printed nothing.
- Acceptance greps: `exclude_booking_id` in the API file 2 (baseline 0); `Reschedule request sent` in the view model 3; the new auth-window sentence 1; `Settings > Payment` 0 (3 at plan start after 03-13, 5 at HEAD baseline); `authorize a new payment` 0; `onRescheduled: { pop() }` 1; `onKeepBooking: { popToRoot() }` 0, `onKeepBooking: { pop() }` 1, `onConfirmCancellation: { _, _ in popToRoot() }` 1; `PastEmptyState(` 1; `No past bookings yet` 1; `showsPastEmptyState` 1.

## Known Stubs

None.

## Deferred device checks (Phase 3 UAT)

Standing user approval 2026-11-10: the tracer device check is deferred to UAT; the Task 1 automated verification passed before expansion. On a real iPhone:

1. **BOOK-16:** from Upcoming details and from a My Bookings card, reschedule a booking to a new time. The app returns to the screen where Reschedule was tapped (not the My Bookings root), "Reschedule request sent" shows above the tab bar, and the status pill there reads Pending reschedule after the refetch. The booking's own time is not greyed in the picker. The push-opened Upcoming details route is wired by plan 03-12 on the HomeRoute path.
2. **BOOK-16 errors:** with a held paid booking, pick a time the backend cannot convert; the alert reads the new RESCHEDULE_OUTSIDE_AUTH_WINDOW copy and wraps cleanly at the largest Dynamic Type size. With no saved card, the alert says "Profile > Payment".
3. **BOOK-12:** open Cancel from Upcoming details and tap Keep Booking; Upcoming details is back. A confirmed cancel still lands on the My Bookings list.
4. **BOOK-11:** on an account with no past bookings, the Past tab shows the empty state (illustration, "No past bookings yet", body, no button). A failed load still shows "Couldn't load bookings", never the empty state. The empty state is not scrollable, so there is no pull-to-refresh on it; the same holds for the existing Upcoming empty state.

## Requirements

- **BOOK-11:** only this plan lists it, so it is marked complete in REQUIREMENTS.md (device check pending in UAT).
- **BOOK-12 and BOOK-16:** plan 03-12 (the device UAT plan, no summary yet) also lists both, so they are left Pending in REQUIREMENTS.md for 03-12 to close.

## Cross-repo and follow-ups

No backend change. Android follow-up (logged, not built): Android's `RESCHEDULE_OUTSIDE_AUTH_WINDOW` copy should match the new wording ("Choose a different time, or cancel this booking and book again. Cancelling releases the hold on your card, so you won't be charged.").

## Threat Flags

None. T-03-20 accepted as planned: the only new request field is `exclude_booking_id`, set to the caller's own booking; the backend ignores invalid or non-matching values and still enforces slot conflicts at PATCH reschedule.

## Next Phase Readiness

Plan 03-12 can run the BOOK-11, BOOK-12 and BOOK-16 device checks above. No blockers.

## Self-Check: PASSED

`PastEmptyState.swift`, `RescheduleAvailabilityTests.swift` and `MyBookingsEmptyStateTests.swift` exist; commits `9fdb991` and `f59c3ba` are ancestors of HEAD.

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
