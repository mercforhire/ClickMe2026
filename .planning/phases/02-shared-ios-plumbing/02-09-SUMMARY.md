---
phase: 02-shared-ios-plumbing
plan: 09
subsystem: navigation
tags: [swiftui, navigationstack, push-routing, pushrouter, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: shell tab structure and PushRouter from earlier phase 2 plans
provides:
  - One homeStack helper per shell that registers HomeRoute on every tab
  - HomeNavigationPath.replace(with:) and HomeRoute.requestDecision
  - PushDestination.incomingRequest and PushDestination.bookingSummary
  - PushRouter.destination(category:subCategory:bookingId:threadId:), the one table for push taps and notification rows
affects: [02-10 real push payloads and mode switch, phase 3 booking and call actions]

actuals:
  tokens: 8230
  tasks: 3
  commits: 3
plan_head_before: a8aa753dc2554a2763e358a127ff62645ca9f95d
plan_head_after: 53d57160155ab377ebaeb81edfc9f10c7c67b509

tech-stack:
  added: []
  patterns:
    - "One private homeStack(_:path:root:) per shell registers HomeRoute exactly once for all five tabs"
    - "Open a routed destination with selectedTab = owner; ownerPath.replace(with: route) in one mutation"
    - "A single static table maps category/sub-category/ids to PushDestination; callers never keep their own copy"

key-files:
  created:
    - ClickMe2026Tests/Push/PushDestinationTableTests.swift
  modified:
    - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026/Managers/PushRouter.swift
    - ClickMe2026/Views/Screens/Notification/NotificationsListViewModel.swift

key-decisions:
  - "Single-mutation replace(with:) stands: the Task 1 device check showed no flash and no dropped push, so the reset()+push fallback was not needed"
  - "booking/payment_actions opens the booking detail only (D-01: route, no recovery flow); Phase 3 wires the actions"
  - "A notifications-list booking/requests row with a booking id now opens that request instead of the hub, because the list shares the push table"

patterns-established:
  - "Tab ownership: client booking detail, summary and leave-review on Bookings, chat on Chats, account security on Profile, notifications list and expert-only fallbacks on Explore; expert request hub, a single request, payouts and notifications list on Dashboard, booking destinations on Bookings, chat on Chats, account security on Profile"
  - "Unknown, empty or missing category returns nil and the caller opens the notifications list"

requirements-completed: [PUSH-01, PUSH-03, BOOK-15]

coverage:
  - id: D1
    description: "Both shells register HomeRoute exactly once, through one homeStack helper covering all five tabs, so no routed destination can show the unregistered-destination page (CR-01)"
    requirement: PUSH-01
    verification:
      - kind: other
        ref: "grep -c 'navigationDestination(for: HomeRoute.self)' on HomeClientView.swift and HomeExpertView.swift prints 1 each; xcodebuild build succeeded"
        status: pass
    human_judgment: true
    rationale: "Whether the warning page can still appear is a runtime UI outcome; the client path was confirmed on device, the expert path is a pending UAT device item"
  - id: D2
    description: "Each destination opens on the tab that owns it with a fresh stack, and Back returns to the tab root (D-04)"
    requirement: PUSH-01
    verification:
      - kind: other
        ref: "grep -c 'replace(with:' prints 8 (client) and 9 (expert); xcodebuild build succeeded"
        status: pass
    human_judgment: true
    rationale: "Tab switching and stack replacement are visual; client mode approved on a real iPhone at the Task 1 gate, expert mode still needs the device check"
  - id: D3
    description: "booking/requests with a booking id opens that request's decision screen; without an id it opens the requests hub"
    requirement: PUSH-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushDestinationTableTests.swift#booking/requests opens that request when a booking id is present, else the hub"
        status: pass
    human_judgment: true
    rationale: "The table is unit-tested, but the on-screen result (RequestDecisionView opening from a notification row) needs the PUSH-03 device check"
  - id: D4
    description: "booking/payment_actions opens the booking detail; declines, cancellations, expirations and refunds open the booking summary"
    requirement: BOOK-15
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushDestinationTableTests.swift#terminal booking rows open the booking summary"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushDestinationTableTests.swift#confirmations, reschedules and payment_actions open the booking detail"
        status: pass
    human_judgment: false
  - id: D5
    description: "Push taps and notifications-list rows share one destination table; unknown or empty categories map to nil"
    requirement: PUSH-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushDestinationTableTests.swift (11 tests, 1 suite)"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-11-09
status: complete
---

# Phase 2 Plan 09: Shell HomeRoute registration and shared push destination table Summary

**Every tab in both shells now registers HomeRoute through one `homeStack` helper, destinations open on the tab that owns them via a single-mutation `replace(with:)`, and push taps and notification rows share one tested category-to-destination table.**

## Performance

- **Duration:** about 55 min (Tasks 2 and 3 in this session; Task 1 and its device gate in the prior one)
- **Completed:** 2026-11-09
- **Tasks:** 3
- **Files modified:** 6 (5 app files, 1 new test file)

## Accomplishments

- CR-01 closed at the source: the client Search and Bookings stacks and the expert Topics stack gained the HomeRoute registration they lacked, and the per-tab registrations are gone. Each shell has exactly one `navigationDestination(for: HomeRoute.self)`.
- `handlePushDestination` in both shells selects the owning tab and calls `replace(with:)`, including the expert notifications list, which used to push without selecting Dashboard.
- `HomeRoute.requestDecision(requestId:)` opens `RequestDecisionView` in the expert shell. The client shell answers it with `EmptyView()`.
- `PushRouter.destination(category:subCategory:bookingId:threadId:)` is the one table. `destination(for event:)` and `NotificationsListViewModel.destination(for:)` both call it, so the hand-copied switch is deleted.
- `PushDestinationTableTests` covers every category and sub-category row, case-insensitivity, and the empty, missing and unknown cases (11 tests, all passing).

## Task Commits

1. **Task 1: Tracer, HomeRoute on every client tab, destinations open on their own tab** - `98eaabd` (fix)
2. **Task 2: Expert shell registers HomeRoute on every tab; request route** - `ce7e35a` (fix)
3. **Task 3: One destination table for pushes and notification rows** - `53d5716` (fix)

**Plan metadata:** committed separately (docs: complete plan).

## Tracer outcome

The Task 1 tracer gate was approved on a real iPhone: client mode, Explore bell, booking notification row switched to the Bookings tab and showed the booking, and Back returned to My Bookings. No flash and no dropped push were reported, so the one-mutation `NavigationPath([value])` assignment stands. The `reset()` followed by `push` fallback was **not** needed.

## Files Created/Modified

- `ClickMe2026/Views/Extensions/HomeNavigationPath.swift` - `replace(with:)`, `HomeRoute.requestDecision`, corrected per-tab ownership docs
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` - `homeStack` helper, five tabs on it, tab-owned `handlePushDestination`, `bookingSummary` and `incomingRequest` cases
- `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift` - same helper and handler pattern, `requestDecision` destination, `bookingSummary` and `incomingRequest` cases
- `ClickMe2026/Managers/PushRouter.swift` - two new `PushDestination` cases and the shared table
- `ClickMe2026/Views/Screens/Notification/NotificationsListViewModel.swift` - row routing delegates to the shared table
- `ClickMe2026Tests/Push/PushDestinationTableTests.swift` - table tests

## Decisions Made

- Kept the single-mutation `replace(with:)` (see Tracer outcome).
- `booking/payment_actions` maps to the booking detail only, per D-01. The payment recovery flow is not part of this plan.
- Unrecognised booking sub-categories with an id still fall back to the booking detail, matching the previous `booking/*` behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The warning baseline for the touched files was empty, and the after-build comparison printed nothing.

## Known Stubs

None.

## Threat Flags

None. T-02-16 (unregistered HomeRoute) is mitigated by the single registration and the grep gates; T-02-17 (crafted category or ids) is covered by the table returning nil for unknown values.

## User Setup Required

None - no external service configuration required.

## Pending device checks (UAT)

- Expert mode: tap a booking notification from the Dashboard bell. It should switch to Bookings and show the booking summary with no warning page, and Back should return to the Upcoming list (PUSH-01 / CR-01).
- Expert mode: tap a booking-request row in the notifications list. It should open that request's decision screen, and Back should return to the Dashboard (PUSH-03).
- A push-opened Upcoming Booking or Booking Summary may have inert Join, Cancel, Reschedule or Leave Review buttons until Phase 3 wires them. This is expected (Open Question 4).

## Next Phase Readiness

Plan 02-10 can feed real push payloads into the shared table and add the mode switch. Android needs no change (it routes on `category` with its own table). No backend or API change.

## Self-Check: PASSED

- Created file `ClickMe2026Tests/Push/PushDestinationTableTests.swift` exists.
- Commits `98eaabd`, `ce7e35a`, `53d5716` are ancestors of HEAD; `git rev-list --count a8aa753..HEAD` = 3.
- Plan verification: `xcodebuild build` succeeded; PushDestinationTableTests passed (11 tests, 1 suite); warning comparison printed nothing.
- Acceptance: `replace(with:` count 8 (client, needs 5+) and 9 (expert, needs 6+); `func replace` 1; `case requestDecision` 1; one HomeRoute registration per shell; `homeStack(` uses 6+ per shell.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-09*
