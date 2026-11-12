---
phase: 04-booking-payment-and-discovery
plan: 10
subsystem: ui
tags: [swiftui, navigation, tab-stacks, favorites, swift-testing]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "HomeShellExit planner and applyExit (plan 04-03)"
provides:
  - "HomeShellExit.Action.viewMyHistory (resets source tab and Bookings, shows Bookings on Past)"
  - "showMyHistory environment shell action"
  - "Shell-owned MyBookingsViewModel on HomeClientView"
  - "Working Favorites empty-state buttons (Explore Experts, View My History)"
affects: [04-13, 04-14]

actuals:
  tokens: 3200
  tasks: 2
  commits: 2
plan_head_before: 401047a9e1e3f3c3afe56ac4550bf6d49f4d2ca2
plan_head_after: bab2ef9aa9ce0f0cb50c87bdc786103ddf636cdb

tech-stack:
  added: []
  patterns:
    - "New shell exits extend HomeShellExit.Action and the planner, not the view; the shell applies the result"
    - "Shell owns a screen's view model when it must drive that screen's state (Bookings segment)"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/HomeShellExit.swift
    - ClickMe2026Tests/Utils/HomeShellExitTests.swift
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
    - ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift

key-decisions:
  - "Explore Experts reuses returnToHome: from Profile its plan is exactly reset Profile and show Explore, so no fourth shell action was added"
  - "HomeClientView owns one MyBookingsViewModel for the shell's lifetime (the Bookings tab's view model already lived that long), so the shell can select Past"

patterns-established:
  - "showsPastBookings on the exit plan selects the Bookings Past segment via myBookingsViewModel.selectedTab = 1"

requirements-completed: [EXPL-05]

coverage:
  - id: D1
    description: "viewMyHistory plan resets {source, Bookings}, shows Bookings and sets showsPastBookings; backToHome from Profile resets Profile only; only viewMyHistory sets showsPastBookings for any action and tab"
    requirement: EXPL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeShellExitTests.swift (12 tests, incl. invariants)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeNavigationPathTests.swift (4 tests, regression)"
        status: pass
    human_judgment: false
  - id: D2
    description: "My Bookings behaviour unchanged after the shell takes ownership of its view model"
    requirement: EXPL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MyBookingsEmptyStateTests.swift (5 tests, regression)"
        status: pass
    human_judgment: false
  - id: D3
    description: "On a real iPhone with no favorites: Explore Experts opens Explore and Profile returns to its root; View My History opens Bookings on Past and Profile returns to its root"
    requirement: EXPL-05
    verification:
      - kind: other
        ref: "grep: FavoritesView() x0, 'onViewHistory: { showMyHistory' x1, MyBookingsView() x0 in HomeClientView, 'myBookingsViewModel.selectedTab = 1' x1"
        status: pass
    human_judgment: true
    rationale: "Tab switching, stack reset and segment selection are SwiftUI runtime behaviour that only a device confirms (UAT EXPL-05, D-08, N2); deferred to the end-of-phase device session and logged in WINDOWS.md"

duration: 15min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 10: Favorites Empty-State Buttons Summary

**Both Favorites empty-state buttons now work: "Explore Experts" reuses the returnToHome shell action, and "View My History" runs a new `HomeShellExit.Action.viewMyHistory` that resets Profile and Bookings and opens Bookings on its Past segment through a shell-owned `MyBookingsViewModel`.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-11-12
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- `HomeShellExit` gains `viewMyHistory`, planned as `resetTabs: [source, .bookings]`, `showTab: .bookings`, `showsPastBookings: true`. The other two actions still never set `showsPastBookings`.
- New `showMyHistory` environment shell action beside `showMyBookings` and `returnToHome`, installed by `HomeClientView` only.
- `HomeClientView` owns `myBookingsViewModel` and passes it to `MyBookingsView(viewModel:)`; `applyExit` sets `selectedTab = 1` when the plan asks for Past. `MyBookingsView`'s own loading and refresh code is untouched.
- `ClientProfileHomeScreen` builds `FavoritesView(onExplore: { returnToHome?() }, onViewHistory: { showMyHistory?() })`, replacing the default no-ops (EXPL-05, D-08).
- Task 2 adds an invariants test that runs every action against every tab: `showTab` is Explore or Bookings, `resetTabs` contains the source tab, and only `viewMyHistory` sets `showsPastBookings` (T-04-26).

## Task Commits

1. **Task 1: Tracer, View My History on an empty Favorites opens Bookings on Past** - `04e93c7` (fix)
2. **Task 2: Regressions for the shell and My Bookings; no new warnings** - `bab2ef9` (test)

**Plan metadata:** committed with this summary (docs).

## Files Created/Modified

- `ClickMe2026/Utils/HomeShellExit.swift` - `viewMyHistory` action and plan, doc comment for the Favorites rule
- `ClickMe2026Tests/Utils/HomeShellExitTests.swift` - history plan rows, Explore-from-Profile row, invariants row (12 tests)
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` - shell-owned My Bookings view model, `showMyHistory` action, Past selection in `applyExit`
- `ClickMe2026/Views/Extensions/HomeNavigationPath.swift` - `@Entry var showMyHistory`
- `ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift` - reads the two shell actions and passes them to `FavoritesView`

## Decisions Made

- Followed the plan. Favorites is reachable only from Profile, so the selected tab at tap time is Profile and "Explore Experts" equals Back to Home from there; no new action was needed.

## Deviations from Plan

None - plan executed exactly as written.

### Tracer gate

The tracer's `<verify>` carries only automated checks (no `<human-check>`), so under `human_verify_mode: end-of-phase` I re-ran it (HomeShellExitTests, 11 tests, plus the five source assertions), logged it as verified, and expanded to Task 2. The device check sits on Task 2 and is deferred to the end-of-phase session (see D3 and the WINDOWS.md entry).

## Issues Encountered

- A compound verification command was refused by the shell tool (bash 3.2), so I ran each check as its own simple command. Same checks, same results.

## Known Stubs

None.

## Threat Flags

None. Client-side navigation only; no new endpoints, auth paths or schema. T-04-26 (stale Favorites stack on a tab) is mitigated by the planner resetting the source tab and covered by the invariants row.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Android follow-up (logged, not built)

Check the two Favorites empty-state buttons on Android (D-08).

## Next Phase Readiness

- Plan 04-10 is complete. The device check (Profile > Favorite Experts with no favorites, both buttons) is pending for the end-of-phase UAT session, logged as an `unrun-verify` entry in `.planning/WINDOWS.md`.
- Verification: HomeShellExitTests (12), HomeNavigationPathTests (4) and MyBookingsEmptyStateTests (5) pass; Debug build succeeded with 0 new warnings in the four app files (baseline also 0).

## Self-Check: PASSED

- Modified files exist on disk and are committed; no files were created.
- Commits `04e93c7` and `bab2ef9` are on `main`; `git rev-list --count 401047a..HEAD` was 2 at the last task commit.
- Acceptance criteria re-run: `case viewMyHistory` x1, both automated checks pass.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
