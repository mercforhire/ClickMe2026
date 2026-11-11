---
phase: 03-booked-sessions-and-joining
plan: 12
subsystem: ui
tags: [swiftui, navigation, homeroute, cancel, reschedule, review, uat, swift-testing]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: "ClientCancellationView and RescheduleView toasts before their callbacks (03-10, 03-11), UpcomingBookingView starts its own call (03-09), BookingSummaryViewModel.showsLeaveReview (03-07), the expert shell homeStack(nav:) destination handler (03-04)"
provides:
  - "HomeRoute.cancelBooking, .rescheduleBooking and .writeReview, rendered by the client shell against the originating tab's path"
  - "HomeNavigationPath.pop(_:), safe past the tab root"
  - "EnvironmentValues.hostsClientBookingFlows (default true; the expert shell sets false)"
  - "Cancel, Reschedule and Leave a Review that work on push-, chat-, Explore- and Payments-opened screens"
  - "03-DEVICE-UAT-CHECKLIST.md: 24 numbered Phase 3 device checks"
affects: [phase-3-uat, 03-verification, android-parity]

actuals:
  tokens: 8300   # chars/4 over the added lines of the realized diff (8,953 code + 24,224 checklist chars)
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Optional action closures: nil means the screen pushes its own HomeRoute on the tab path; a caller-supplied closure (My Bookings) overrides it"
    - "A shell that stubs a route group as EmptyView() sets an environment flag so client-only screens hide the actions that would push those routes"
    - "homeRouteDestination(route, nav:) hands each destination the tab path it was pushed on, so a flow can pop its own levels"

key-files:
  created:
    - ClickMe2026Tests/Utils/HomeNavigationPathTests.swift
    - .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md
  modified:
    - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
    - ClickMe2026/Views/Screens/Client Mode/Payments/ClientTransactionsView.swift

key-decisions:
  - "A confirmed cancel opened from a HomeRoute entry pops two levels (the cancel screen and the cancelled booking's details); My Bookings keeps its pop-to-root"
  - "The expert shell keeps the three new routes as EmptyView() stubs and hides the client actions through hostsClientBookingFlows instead of rerouting its chat-row pushes to the expert summary"
  - "Payments links by HomeRoute value so the details screen sits on the Profile tab's path"

requirements-completed: [BOOK-12, BOOK-16, BOOK-17]

coverage:
  - id: D1
    description: "pop(_:) removes up to N entries, never crashes past the root, and is a no-op for 0 and on an empty path"
    requirement: BOOK-12
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeNavigationPathTests.swift#popTwoOfThree, popPastRoot, popZero, popEmpty"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cancel, Reschedule and Keep Booking on an Upcoming details screen opened outside My Bookings push and pop on the tab's own stack"
    requirement: BOOK-16
    verification:
      - kind: other
        ref: "grep gates on UpcomingBookingView, HomeClientView and HomeNavigationPath (see Verification); xcodebuild build succeeded with exhaustive switches in both shells"
        status: pass
    human_judgment: true
    rationale: "SwiftUI navigation depth has no unit seam; a device run proves the screen reached. Items 6 and 8 of the Phase 3 UAT checklist"
  - id: D3
    description: "Leave a Review opens the review form from a push- or chat-opened Booking Summary, for completed sessions only"
    requirement: BOOK-17
    verification:
      - kind: unit
        ref: "ClickMe2026Tests BookingSummaryViewModelTests (showsLeaveReview rows) pass"
        status: pass
    human_judgment: true
    rationale: "The route push and form presentation need a device. Item 9 of the UAT checklist"
  - id: D4
    description: "Inside the expert shell the client Upcoming details and Booking Summary show no Cancel, Reschedule or Leave a Review and no tap reaches a stubbed route"
    requirement: BOOK-12
    verification:
      - kind: other
        ref: "grep gates: hostsClientBookingFlows, false in HomeExpertView; offersClientActions defined and used in UpcomingBookingView; hostsClientBookingFlows gates Leave a Review in BookingSummaryView"
        status: pass
    human_judgment: true
    rationale: "Visual absence and no blank screen need a device. Item 24 of the UAT checklist"
  - id: D5
    description: "One checklist lists every Phase 3 device check, the UI-SPEC backstops, the open risks and the BACK-19 and deploy state"
    verification:
      - kind: other
        ref: "03-DEVICE-UAT-CHECKLIST.md: 30 required ids present, 25 Result lines, 'converted to long-lead' and 'expert shell' present"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-11-11
plan_head_before: d7f5ea46786877e0ecca66502af62475594ff8fc
plan_head_after: 6a8fb82a46d6cd1d2f25b8cc67c1ae5b26d557eb
commits: 3
status: complete
---

# Phase 3 Plan 12: Push-opened booking actions and the Phase 3 device UAT checklist Summary

**Cancel, Reschedule, Keep Booking and Leave a Review now work on Upcoming details and Booking Summary screens opened from a push, a chat row, Explore or Payments, through three new `HomeRoute` cases and `HomeNavigationPath.pop(_:)`, with the actions hidden inside the expert shell; all Phase 3 device checks are collected in one 24-item UAT checklist.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-11 (UTC)
- **Tasks:** 3 of 3
- **Files modified:** 8 (2 created, 6 modified), 3 commits

## Accomplishments

- `HomeNavigationPath.pop(_ count:)` removes `min(count, path.count)` entries; 4 pure tests cover three-entry, past-root, zero and empty paths.
- `HomeRoute.cancelBooking(bookingId:)`, `.rescheduleBooking(bookingId:)` and `.writeReview(bookingId:expertName:)`. `HomeClientView.homeRouteDestination(_:nav:)` renders them: Keep Booking pops one level, a sent reschedule pops one level (toast already posted by the view model), a confirmed cancel pops two (past the cancelled booking), and the review form opens with `.completed`.
- `UpcomingBookingView.onReschedule` and `onCancel` are optional; nil pushes the matching `HomeRoute`. `BookingSummaryView.onLeaveReview` is optional; nil pushes `HomeRoute.writeReview` (no-op without a booking id). My Bookings still passes its closures, so its `BookingRoute` flows are unchanged.
- `EnvironmentValues.hostsClientBookingFlows` (default true). The expert shell's `homeStack` sets it to false and stubs the three routes as `EmptyView()`; `UpcomingBookingView.offersClientActions` and the Leave a Review gate in `BookingSummaryView` use it, so no button in the expert shell pushes a blank route.
- `ClientTransactionsView` links with `NavigationLink(value: HomeRoute.upcomingBooking(...))`, so the Payments-opened details screen sits on the Profile tab's path.
- `03-DEVICE-UAT-CHECKLIST.md`: 24 numbered items (every Phase 3 requirement with a device check, the D-15 end + 55 notice, BACK-02 decline note, the D2/L2/L3 backstops with D3 and D4 inside CALL-08 and CALL-10, and the expert shell chat-row item), plus Setup and Notes before you start.

## Task Commits

1. **Task 1: Tracer, a push-opened Upcoming Booking details screen can cancel and reschedule on its own tab** - `e4b70f6` (feat)
2. **Task 2: Leave a Review works on a push-opened Booking Summary; Payments opens details on the tab path** - `8115d3b` (fix)
3. **Task 3: Phase 3 device UAT checklist** - `6a8fb82` (docs)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Views/Extensions/HomeNavigationPath.swift` - `pop(_:)`, three routes, `hostsClientBookingFlows`
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` - `homeRouteDestination(_:nav:)` and the three destinations
- `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift` - three `EmptyView()` stubs, `hostsClientBookingFlows` false on every tab stack
- `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift` - optional closures, route fallbacks, `offersClientActions`
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift` - optional `onLeaveReview`, route fallback, expert-shell gate
- `ClickMe2026/Views/Screens/Client Mode/Payments/ClientTransactionsView.swift` - value-based link
- `ClickMe2026Tests/Utils/HomeNavigationPathTests.swift` - `pop(_:)` rows
- `.planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md` - the Phase 3 device checks

## Decisions Made

- A confirmed cancel from a HomeRoute entry pops two levels. This follows the plan's assumption and is recorded in the checklist notes and item 6.
- The expert shell is not rerouted to `ExpertBookingSummaryView`. It keeps the client screens for chat rows and hides the client actions, as the plan's checker revision decided. A chat row for a booking the user is the expert on still opens a client screen that fails to load (client endpoint 404); this is pre-existing and noted on item 24.
- The Leave a Review route push skips silently when `viewModel.bookingId` is nil (the preview seed), as the plan specifies.

## Deviations from Plan

None - plan executed exactly as written.

Task 1 is marked `type="tracer"` and carries a `<behavior>` block for `pop(_:)`; the method and its rows were committed together, as the plan specifies one commit per task, and the rows passed on first run.

## Issues Encountered

None. The warning baseline and final sets for the six app files were both empty (no new warnings).

## Verification

- Task 1 gate: `HomeNavigationPathTests` ran 4 tests in 1 suite, passed. Grep gates: inert `onCancel` default 0 (baseline 2), `HomeRoute.cancelBooking` in `UpcomingBookingView` 1, `homeRouteDestination(route, nav: nav)` in `HomeClientView` 1, `case cancelBooking(bookingId: UUID)` 1, `@Entry var hostsClientBookingFlows` 1, `hostsClientBookingFlows, false` in `HomeExpertView` (non-comment) 1, `offersClientActions` in `UpcomingBookingView` (non-comment) 2, `func pop(_ count: Int)` 1, `case .cancelBooking` in `HomeExpertView` 1.
- Task 2 gate: `BUILD SUCCEEDED`; inert `onLeaveReview` default 0 (baseline 2), `HomeRoute.writeReview` in `BookingSummaryView` 3, value `NavigationLink` in `ClientTransactionsView` 1, `hostsClientBookingFlows` in `BookingSummaryView` (non-comment) 2. `BookingSummaryViewModelTests`, `UpcomingBookingViewModelTests` and `HomeNavigationPathTests` each passed in their own run.
- Task 3 gate: all 30 required ids present, "converted to long-lead" and "expert shell" present, 25 `Result:` lines.
- Plan-level: `xcodebuild build` succeeded and the warning comparison printed nothing.
- Phase gate, one run per MockURLProtocol suite, all passed: `ClientCancellationViewModelTests`, `RescheduleResponderTests`, `RescheduleAvailabilityTests`, `ExpertRescheduleWindowTests`, `RescheduleWindowTests`, `ClientBookingStatusFallbackTests`, `BookingSummaryViewModelTests`, `UpcomingBookingViewModelTests`. One combined run of the pure suites passed: 56 tests in 7 suites (`JoinWindowTests`, `MoneyTests`, `ReloadGenerationTests`, `BookingErrorMapperTests`, `ExternalMeetingProviderTests`, `UpcomingActionPolicyTests`, `ToastCenterTests`). `AuthSmokeTests` and `SignupSmokeTests` were not run.

## Known Stubs

None. The three `EmptyView()` cases in `HomeExpertView` are intentional client-only destination stubs (the same pattern as the client shell's expert-only stubs), and the actions that would reach them are hidden there.

## Deferred device checks (Phase 3 UAT)

Standing user approval 2026-11-10: the tracer device check is deferred to UAT; the Task 1 automated verification passed before expansion. The full list for the whole phase is `03-DEVICE-UAT-CHECKLIST.md`. This plan's own items:

1. **BOOK-12, BOOK-16 (checklist items 6 and 8):** tap a booking push to open Upcoming details. Cancel then Keep Booking returns to details; Reschedule and send returns to details with "Reschedule request sent"; Cancel and confirm returns past the cancelled booking with the cancel toast. Repeat once from a chat system-event row.
2. **BOOK-17 (item 9):** tap a review-nudge push for a completed session; Leave a Review opens the form. From Profile > Payment history, open a future booking; Cancel and Keep Booking return to the details screen.
3. **Expert shell (item 24):** in expert mode, open a chat with a client and tap a booking system-event row (upcoming and completed). No Cancel, Reschedule or Leave a Review shows and no tap opens a blank screen.

## Requirements

- **BOOK-12, BOOK-16, BOOK-17:** this is the last Phase 3 plan that lists them (03-11 listed BOOK-12 and BOOK-16, 03-07 listed BOOK-17), so all three are marked complete in REQUIREMENTS.md. The code half is delivered; the device checks stay pending in UAT.
- Phase 3 requirements that were already complete from earlier plans are untouched. BACK-19 stays Pending (its production smoke has not been run), and the checklist says so next to the EXP-11 item.

## Cross-repo and follow-ups

No backend change and no Android change in this plan, and no new Android follow-up. The Android follow-ups from Phase 3 are already in STATE.md under "Android follow-ups from Phase 3": the expert cancel money-line rule (03-05, 03-08), the D-13 Cancel rule on Upcoming details (03-09), and the `RESCHEDULE_OUTSIDE_AUTH_WINDOW` wording (03-11). Android keeps "Accept" and "New time proposed" (logged copy differences).

## Threat Flags

None. T-03-21 accepted as planned: the new routes reuse existing views that call client endpoints returning 404 for a booking the caller does not own; no new endpoint or id source.

## Next Phase Readiness

Phase 3 plans are all done. The next step is phase verification and the user's device run of `03-DEVICE-UAT-CHECKLIST.md`. Phase 2's `02-UAT.md` tests 6-17 are still outstanding and must run before Phase 8.

## Self-Check: PASSED

`HomeNavigationPathTests.swift` and `03-DEVICE-UAT-CHECKLIST.md` exist; commits `e4b70f6`, `8115d3b` and `6a8fb82` are ancestors of HEAD.

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
