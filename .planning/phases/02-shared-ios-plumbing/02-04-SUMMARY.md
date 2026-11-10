---
phase: 02-shared-ios-plumbing
plan: 04
subsystem: ui
tags: [swiftui, bookings, join-window, timelineview, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "BookingStatus decoding from plan 02-03 (pendingReschedule, unknown cases)"
provides:
  - "JoinWindow: the one CALL-02 join rule, equal to backend evaluateJoinWindow, with a tested edge and status matrix"
  - "Client My Bookings cards and the expert Upcoming list both gate Join on JoinWindow"
  - "Expert Upcoming list passes each booking's server can_join into the reconnect tier"
  - "Join button and NOW badge on the expert list update with time, with no refresh"
affects: [02-14 Explore and expert dashboard strips, 02-12 device UAT checklist, 03 client detail and expert summary join (CALL-03, CALL-08, CALL-10), Android JoinWindow port]

actuals:
  tokens: 5145
  tasks: 2
  commits: 2
plan_head_before: a448a919772de4f8c8cc18a6988c677b6e547633
plan_head_after: c2a9eaf748b149dbca48c8dc57f14af783dd11d2

tech-stack:
  added: []
  patterns:
    - "Display-gate helpers take `now` as a parameter and never read the clock; views forward `Date()` and sit in a 60 s TimelineView"
    - "Server flag is an optional input (`Bool?`): nil and false both close the reconnect tier"

key-files:
  created:
    - ClickMe2026/Utils/JoinWindow.swift
    - ClickMe2026Tests/Utils/JoinWindowTests.swift
  modified:
    - ClickMe2026/Model/UIModels/UpcomingBooking.swift
    - "ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift"

key-decisions:
  - "JoinWindow is a display gate only; POST /bookings/:id/join keeps the two-tier gate and status check server-side (T-02-08)"
  - "pending_reschedule is not joinable (D-12), so the list cards hide Join for it; this is an intentional behavior change for the Phase 2 UAT"
  - "A client who drops during overtime reconnects from the detail screen (Phase 3), not from the My Bookings list, which has no can_join (D-07)"

patterns-established:
  - "One rule, thin forwarders: model structs keep an `isWithinJoinWindow` property that is a one-line call to JoinWindow.isOpen"

requirements-completed: [CALL-02]

coverage:
  - id: D1
    description: "JoinWindow rule matches backend evaluateJoinWindow: open at start-60m, open through max(end, start+60m), reconnect to end+60m only with can_join true, inclusive edges, non-joinable statuses closed"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/JoinWindowTests.swift (suite JoinWindow, 18 tests with BookingStatus decoding, passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Client My Bookings card follows JoinWindow (Join from start-60m, still shown at start+90m on a session over an hour, hidden for pending_reschedule)"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "JoinWindowTests (rule); build succeeded"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT CALL-02 client My Bookings check (DEFERRED, not yet run)"
        status: unknown
    human_judgment: true
    rationale: "Visual Join/NOW behavior over elapsed time on a real iPhone; user chose to defer the device check to the Phase 2 UAT checklist (plan 02-12)"
  - id: D3
    description: "Expert Upcoming list uses JoinWindow with server can_join, and Join/NOW update live via a 60 s TimelineView"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "JoinWindowTests (rule); build succeeded, no new warnings"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT CALL-02 expert Upcoming check (pending)"
        status: unknown
    human_judgment: true
    rationale: "Live time-driven UI change needs eyes on a device"

duration: 20min
completed: 2026-11-09
status: complete
---

# Phase 2 Plan 04: Shared join window (CALL-02) Summary

**One tested `JoinWindow` rule (open start-60m, through max(end, start+60m), reconnect to end+60m only with server `can_join`, pending_reschedule never joinable) now drives Join on the client My Bookings cards and the expert Upcoming list, with live updates on the expert list.**

## Performance

- **Duration:** about 20 min (Task 2 and wrap-up in this continuation; Task 1 in the earlier run)
- **Started:** 2026-11-09T22:41Z (baseline capture)
- **Completed:** 2026-11-09
- **Tasks:** 2 of 2
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments

- `JoinWindow` replaces the symmetric plus-or-minus 3600 s rule that hid Join for the second half of any session longer than an hour. It equals the backend `evaluateJoinWindow`, including inclusive edges.
- The expert Upcoming list previously ignored status (a pending_reschedule booking could show Join) and the server flag. It now passes status and `actions.canJoin` through `UpcomingSession.serverCanJoin`.
- The expert card's Join Session button and NOW badge are each inside a `TimelineView(.periodic(from: .now, by: 60))`, so they flip as time passes without pull to refresh.
- Stale doc comments (the "tighter ~5 min server flag" text, "struct carries no status") were removed.

## Task Commits

1. **Task 1: Tracer, client My Bookings card follows the shared join rule** - `ea952c3` (fix)
2. **Task 2: Expert Upcoming list uses JoinWindow with the server reconnect flag** - `c2a9eaf` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Utils/JoinWindow.swift` - the CALL-02 rule (`lead`, `minFirstJoinSpan`, `reconnectGrace`, `joinableStatuses`, `isJoinableStatus`, `isOpen`)
- `ClickMe2026Tests/Utils/JoinWindowTests.swift` - edge and status matrix, one second either side of each edge, reconnect tier with true/false/nil
- `ClickMe2026/Model/UIModels/UpcomingBooking.swift` - `serverCanJoin` property, `isWithinJoinWindow` forwards to `JoinWindow.isOpen`
- `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift` - `UpcomingSession.serverCanJoin`, `isWithinJoinWindow` forwards to `JoinWindow.isOpen`
- `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift` - maps `serverCanJoin: item.actions.canJoin`
- `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift` - Join button and NOW badge in 60 s TimelineViews

## Decisions Made

- JoinWindow is a display gate, never an authorization (threat T-02-08, accepted).
- Local rule equals the backend rule and is tested one second either side of every edge (T-02-09, mitigated).

## Deviations from Plan

None - plan executed exactly as written. The one process variation was a human decision at the tracer gate: the user chose "approve and defer", so execution continued before the Task 1 device check was done.

## Deferred Device Checks (PENDING, not passed)

These need a real iPhone and have NOT been run. Plan 02-12 builds `02-DEVICE-UAT-CHECKLIST.md` and must pick them up as CALL-02 items:

1. **Client My Bookings (Task 1 tracer check, deferred by user "approve and defer"):** a confirmed booking shows Join from start minus 60 minutes; on a session longer than an hour, Join is still shown at start plus 90 minutes; no Join on a `pending_reschedule` booking.
2. **Expert Upcoming list (Task 2):** Join appears at start minus 60 minutes without pulling to refresh, and the NOW badge appears without a refresh.
3. **Intentional change to list in the UAT:** a `pending_reschedule` card no longer shows Join (D-12). Plan 02-14 applies the same rule to the Explore and expert dashboard strips.

## Android Follow-up (logged, not built)

Android `managers/JoinWindow.kt` treats `pending_reschedule` as joinable and ignores the server `can_join` flag, so it differs from D-07 and D-12 and from the backend rule. It needs the same change as `JoinWindow` here: remove `pending_reschedule` from the joinable statuses, open the window at start minus 60, run to max(end, start + 60), and use `can_join` for the reconnect tier to end plus 60. No Android change was made in this plan.

## Issues Encountered

None. Warning baseline was empty (`/tmp/02-04-warn-before.txt`) and the comparison after the build printed nothing, so no new warnings in the plan's files.

## Known Stubs

None.

## Threat Flags

None - no new network endpoints, auth paths or schema changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-14 can wire the Explore strip and expert dashboard strip to `JoinWindow` and add `ClientBookingDetail.canJoin`.
- Plan 02-12 must include the three deferred CALL-02 device checks above.
- CALL-02 is marked complete in requirements on the strength of the unit tests and clean build; the device verification remains outstanding and is tracked above.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/JoinWindow.swift
- FOUND: ClickMe2026Tests/Utils/JoinWindowTests.swift
- FOUND commit ea952c3, FOUND commit c2a9eaf (both ancestors of HEAD)
- Tests: 18 tests in 2 suites passed; BUILD SUCCEEDED; new-warning comparison empty

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-09*
