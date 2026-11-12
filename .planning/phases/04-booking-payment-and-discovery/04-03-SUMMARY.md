---
phase: 04-booking-payment-and-discovery
plan: 03
subsystem: ui
tags: [swiftui, navigation, tab-stacks, uikit-bridge, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "Tab-owned navigation stacks (D-04), HomeNavigationPath, showMyBookings/returnToHome shell actions"
provides:
  - "HomeShellExit pure exit planner (Action x source tab)"
  - "Shell exits that reset the tab that started the booking flow"
  - "Request Sent as a one-way screen: Back hidden, swipe-back locked, both exits in loading, error and loaded states"
  - "Request Sent loading copy 'Loading booking…'"
affects: [04-08, 04-10, 04-13, 04-14]

actuals:
  tokens: 2700
  tasks: 2
  commits: 2
plan_head_before: eefde8041ba20bd64ccfae08092f4f4c7a65e836
plan_head_after: 3c0ce9a23897cfb5a35d57e97d5ba182746eae69

tech-stack:
  added: []
  patterns:
    - "Pure planner value type (HomeShellExit) decides tab-stack resets; the shell only applies the result"
    - "UIViewControllerRepresentable bridge that saves and restores UIKit state on appear/disappear"

key-files:
  created:
    - ClickMe2026/Utils/HomeShellExit.swift
    - ClickMe2026Tests/Utils/HomeShellExitTests.swift
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentPopGestureLock.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentActions.swift

key-decisions:
  - "The source tab is the tab selected at tap time; the exit buttons exist only on the visible tab, so a tab switch before the tap cannot reset the wrong stack"
  - "Pinned exits are written out at both the loading and error call sites (not a shared helper) so the three-placement source assertion for T-04-11 holds"
  - "interactiveContentPopGestureRecognizer is optional in the SDK, so the lock uses optional chaining and restores only what it saved"

patterns-established:
  - "Shell actions delegate to HomeShellExit.plan(_:selectedTab:) then applyExit; plans 04-08, 04-10 and 04-13 extend the planner rather than the view"

requirements-completed: [BOOK-01, BOOK-05, BOOK-19]

coverage:
  - id: D1
    description: "Exit planner resets the source tab (and Bookings for View My Bookings) and shows Explore or Bookings, for all five source tabs, with a repeated tap giving an equal plan"
    requirement: BOOK-19
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeShellExitTests.swift (HomeShellExitTests, 7 tests)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeNavigationPathTests.swift (regression)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Request Sent has no Back button and the edge and iOS 26 content swipes do not pop it, from each source tab; exits reset that tab on a real iPhone"
    requirement: BOOK-01
    verification:
      - kind: other
        ref: "grep: navigationBarBackButtonHidden(true) and BookingRequestSentPopGestureLock() each appear once in BookingRequestSentView.swift"
        status: pass
    human_judgment: true
    rationale: "Swipe-back behaviour is UIKit/SwiftUI runtime behaviour that only a device can confirm (UAT D2); device check is deferred to the end-of-phase session and logged in WINDOWS.md"
  - id: D3
    description: "Loading state reads 'Loading booking…' and both exits are pinned in loading and error states with a 16 pt gap; loaded layout unchanged"
    requirement: BOOK-05
    verification:
      - kind: other
        ref: "grep: 'Loading booking…' x1, 'Sending your booking' x0, BookingRequestSentActions( x3, 'yOffset: 0, spacing: 16' x2; xcodebuild build succeeded with no new warnings"
        status: pass
    human_judgment: true
    rationale: "Visual placement (centered spinner, bottom-pinned capsules, no overlap at large Dynamic Type) needs a device or preview check (UAT L1, E1)"

duration: 10min
completed: 2026-11-11
status: complete
---

# Phase 4 Plan 03: Request Sent One-Way Screen and Source-Tab Exits Summary

**Request Sent hides Back and locks both pop gestures, pins View My Bookings / Back to Home in loading, error and loaded states, and both exits now reset whichever of the five tabs started the booking via a pure `HomeShellExit` planner.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-11-12T04:46Z
- **Tasks:** 2
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `HomeShellExit.plan(_:selectedTab:)` decides the exit as a value: Back to Home resets `{source}` and shows Explore; View My Bookings resets `{source, Bookings}` and shows Bookings. A set is used, so Explore as source (or Bookings as source) is reset once. `HomeClientView` only applies the result through `applyExit` and `path(for:)`; the hard-coded Explore-only resets are gone (BOOK-19).
- Request Sent can no longer lead back to the booking form: the Back button is hidden and `BookingRequestSentPopGestureLock` disables `interactivePopGestureRecognizer` and, on iOS 26, `interactiveContentPopGestureRecognizer`, restoring each to its saved state on disappear (BOOK-01, D-05).
- With Back hidden, a slow or failed detail load can no longer trap the client: loading and error states pin both exits (16 pt gap, 20 pt side, 48 pt bottom, no entry animation). The loaded layout keeps its 14 pt spacing and animation through the new `spacing` parameter default (BOOK-01, T-04-11).
- Loading copy is now "Loading booking…" (BOOK-05).

## Task Commits

1. **Task 1: Tracer, Request Sent is one-way and its exits reset the tab that started the flow** - `74bd92e` (fix)
2. **Task 2: Both exits in every Request Sent state, "Loading booking…", and the swipe lock** - `3c0ce9a` (fix)

**Plan metadata:** committed with this summary (docs).

## Files Created/Modified

- `ClickMe2026/Utils/HomeShellExit.swift` - pure exit planner (`resetTabs`, `showTab`, `showsPastBookings`, `Action`)
- `ClickMe2026Tests/Utils/HomeShellExitTests.swift` - 7 tests; both actions across all five tabs, the overlapping-set cases and idempotency
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` - `showMyBookings` / `returnToHome` apply the plan; `applyExit(_:)` and `path(for:)`
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift` - Back hidden, lock attached, pinned exits, new loading copy
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentActions.swift` - `spacing` parameter (default 14)
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentPopGestureLock.swift` - UIKit bridge for the pop recognizers

## Decisions Made

- Followed the plan. The source tab is the tab selected at tap time; the exit buttons exist only on the visible tab.
- The pinned exits are written at both call sites instead of a shared helper so the plan's source assertion (three `BookingRequestSentActions(` placements) holds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `interactiveContentPopGestureRecognizer` is optional**
- **Found during:** Task 2 (first build)
- **Issue:** The plan's interface note listed the iOS 26 recognizer as a plain property; in the SDK it is `UIGestureRecognizer?`, so `.isEnabled` did not compile.
- **Fix:** Optional chaining on read, disable and restore.
- **Files modified:** `BookingRequestSentPopGestureLock.swift`
- **Verification:** `xcodebuild build` succeeded; no new warnings against the baseline.
- **Committed in:** `3c0ce9a` (part of the Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Compile fix only; behaviour is as specified.

### Tracer gate handled without a mid-flight stop

The tracer's `<verify>` carries a `<human-check>`, which under `human_verify_mode: end-of-phase` would normally stop at a `checkpoint:human-verify`. The plan assigns that check to the end-of-phase device session (it needs a real iPhone to confirm swipe-back and source-tab resets), as 04-02 did for its tracer. I re-ran the tracer's automated verify (HomeShellExitTests, HomeNavigationPathTests and the source assertions, all passing) and continued to Task 2. The device checks are recorded as two `unrun-verify` entries in `.planning/WINDOWS.md` and as D2 and D3 above with `human_judgment: true`. If this should have stopped for the user, the work is two small reversible commits.

## Issues Encountered

None beyond the compile fix above.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths or schema changes. T-04-10 (resubmit after Request Sent) and T-04-11 (client trapped) are mitigated as planned; the backend's DUPLICATE_BOOKING and confirm replay remain the server-side backstop.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Android follow-up (logged, not built)

Check Android's back stack after Request Sent and the source-tab reset (D-05, D-06).

## Next Phase Readiness

- `HomeShellExit` is ready for plan 04-10 (`Explore Experts`, `View My History`, `showsPastBookings`) and for `Check My Bookings` in plans 04-08 and 04-13, which reuse `.viewMyBookings`.
- Device checks (UAT D2, L1, E1, BOOK-19 from each source tab) are pending for the end-of-phase session.

## Self-Check: PASSED

- Created files exist: HomeShellExit.swift, HomeShellExitTests.swift, BookingRequestSentPopGestureLock.swift (verified on disk).
- Commits `74bd92e` and `3c0ce9a` are on `main`; `git rev-list --count eefde80..HEAD` was 2 at the last task commit.
- Acceptance criteria re-run: all pass (`struct HomeShellExit` x1, `private func applyExit` x1, `var spacing: CGFloat = 14`, `interactiveContentPopGestureRecognizer` present, all automated checks).
- Plan verification: HomeShellExitTests (7 tests) and HomeNavigationPathTests pass; build succeeded with no new warnings in the five app files.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-11*
