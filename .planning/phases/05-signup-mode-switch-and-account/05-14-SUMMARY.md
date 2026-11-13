---
phase: 05-signup-mode-switch-and-account
plan: 14
subsystem: navigation
tags: [swiftui, tabview, shell-exit, delete-account, swift-testing, generics]
status: complete

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: "05-08 Delete Account blocker alert reading @Environment(\\.showMyBookings)"
provides:
  - "HomeShellTab protocol and HomeShellExit<Tab: HomeShellTab>, shared by both shells"
  - "Expert shell installs showMyBookings through HomeShellExit.plan(.viewMyBookings, selectedTab:)"
  - "Expert rows in HomeShellExitTests"
affects: [05-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 4200
  tasks: 2
  commits: 2

commits: 2
plan_head_before: 9b4bec7f1b09ceca53c99b8a36be23f481809ed7
plan_head_after: 19a7f0a7931badb3dee028ebaf33af09ba6137f4

tech-stack:
  added: []
  patterns:
    - "One generic exit planner over a protocol the shell tab enums conform to, instead of a second expert-only planner"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/HomeShellExit.swift
    - ClickMe2026Tests/Utils/HomeShellExitTests.swift
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026/Views/Extensions/HomeNavigationPath.swift

key-decisions:
  - "HomeShellExit is generic over HomeShellTab (homeTab, bookingsTab) rather than duplicated for the expert shell"
  - "Only showMyBookings is installed on the expert shell; returnToHome and showMyHistory stay client-only"
  - "The expert applyExit ignores showsPastBookings: no exit that sets it is installed there"

patterns-established:
  - "A shell's applyExit(_:) and path(for:) mirror each other across client and expert shells"

requirements-completed: [SET-06]

coverage:
  - id: D1
    description: "In Expert mode, View my bookings resets the source tab and Bookings and opens the expert Bookings tab through the shared HomeShellExit plan"
    requirement: SET-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeShellExitTests.swift (expert rows over every HomeExpertTab, Profile, Bookings-once, Back to Home to Dashboard)"
        status: pass
      - kind: command
        ref: "grep gate: HomeExpertView installs showMyBookings via HomeShellExit.plan(.viewMyBookings"
        status: pass
    human_judgment: false
  - id: D2
    description: "Client shell exits unchanged: every existing client row passes, HomeClientView keeps its three plan calls"
    requirement: SET-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeShellExitTests.swift (existing client rows, assertions untouched)"
        status: pass
    human_judgment: false
  - id: D3
    description: "SET-06 device check: expert with an upcoming booking, Profile > Delete Account shows the blocker alert and View my bookings opens the expert Bookings tab with the Profile stack reset"
    requirement: SET-06
    verification: []
    human_judgment: true
    rationale: "Real navigation on a device with a live account; listed in 05-DEVICE-UAT-CHECKLIST.md"
---

# Phase 5 Plan 14: Expert shell View my bookings Summary

**HomeShellExit made generic over a HomeShellTab protocol so the expert shell installs showMyBookings through the same tested plan as the client shell, and Delete Account's blocker alert now shows "View my bookings" in Expert mode.**

## Performance

- **Started:** 2026-11-13T21:57Z (approx.)
- **Completed:** 2026-11-13T22:05Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- `HomeShellTab` protocol (`homeTab`, `bookingsTab`) with conformances for `HomeClientTab` (home `.explore`) and `HomeExpertTab` (home `.dashboard`); `HomeShellExit<Tab>` keeps every case's rule and `showsPastBookings`.
- `HomeExpertView` installs `showMyBookings` from `HomeShellExit.plan(.viewMyBookings, selectedTab:)`, with its own `applyExit(_:)` and `path(for:)` over the five tab paths. `HomeClientView` only changed the parameter type of `applyExit(_:)`, and its three plan calls are unchanged.
- Four expert rows in `HomeShellExitTests`: every tab as source, Profile, Bookings-once, Back to Home shows Dashboard.
- `showMyBookings` doc now says both shells install it and names `HomeExpertView`; the "expert consumers get nil" sentence is gone.

## Task Commits

1. **Task 1 (tracer): View my bookings in Expert mode opens the expert Bookings tab** - `dae96b0` (fix)
2. **Task 2: Environment doc says both shells install the bookings action** - `19a7f0a` (docs)

## Verification

- `HomeShellExitTests`: "Test run with 16 tests in 1 suite passed" (`/tmp/05-14-t1.log`).
- `HomeNavigationPathTests`: "Test run with 4 tests in 1 suite passed" (`/tmp/05-14-reg.log`).
- Build gate: BUILD SUCCEEDED, 0 warnings in the four app files before and after (`/tmp/05-14-warn-before.txt`, `/tmp/05-14-warn-after.txt` both empty).
- Grep gates for Task 1 and Task 2 and the acceptance criterion `extension HomeExpertTab: HomeShellTab` (1 match) all pass.
- Tracer: verify was automated-only under `end-of-phase` mode, so it was re-run green before Task 2; no checkpoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing client test rows specialised**
- **Found during:** Task 1 (first test build)
- **Issue:** Seven existing client rows call `HomeShellExit.plan(..., selectedTab: .explore/.bookings/.profile)` with a literal tab, and `invariants` names `HomeShellExit.Action`; with the generic type the tab type cannot be inferred.
- **Fix:** Specialised those calls as `HomeShellExit<HomeClientTab>.plan(...)` and `HomeShellExit<HomeClientTab>.Action`, as the plan's assumptions anticipated. No assertion changed.
- **Files modified:** `ClickMe2026Tests/Utils/HomeShellExitTests.swift`
- **Commit:** dae96b0

**2. [TDD note] RED was a build failure, committed once**
- The plan prescribes a single commit for the tracer. The expert rows referenced `HomeShellExit<HomeExpertTab>`, which did not exist, so the only possible RED was a compile failure (INVALID_RED by format rules), not an assertion failure. The tests and implementation went into one commit as the plan specified. The plan is `type: execute`, so the plan-level TDD gate does not apply.

**Total deviations:** 1 auto-fixed (1 blocking), 1 TDD note. **Impact:** none on behavior.

UI-SPEC refinements: none apply to this plan (no user-visible copy changed).

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. The new action only resets navigation stacks and selects a tab inside the signed-in expert shell (T-05-29, accepted).

## Notes

- `ClickMe2026/Localizable.xcstrings` carried pre-existing uncommitted edits; this plan did not touch it and did not stage it.

## Next Phase Readiness

Ready for the next plan in phase 05. The device check (expert, upcoming booking, Profile > Delete Account > View my bookings) belongs in 05-DEVICE-UAT-CHECKLIST.md.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/HomeShellExit.swift, ClickMe2026Tests/Utils/HomeShellExitTests.swift, HomeExpertView.swift, HomeClientView.swift, HomeNavigationPath.swift (all modified, committed)
- FOUND commits: dae96b0, 19a7f0a (ancestors of HEAD)
