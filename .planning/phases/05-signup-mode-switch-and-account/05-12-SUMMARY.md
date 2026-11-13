---
phase: 05-signup-mode-switch-and-account
plan: 12
subsystem: auth
tags: [swiftui, scenePhase, expert-setup, mode-gate, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-07 lookUpSetupCompleted and setupHubRequested handoff; plan 05-10 resolvePostAuthLanding; plan 05-16 setup deferral (isSetupDeferred)
provides:
  - ExpertModeGate.RecheckDecision and recheckDecision(pending:deferred:roles:mode:), the role-guarded foreground re-check decision
  - UserManager.setupCheckPending, markSetupCheckPending(), recheckSetupIfPending() (single-flight, call-guarded)
  - ClickMe2026App scenePhase observer that retries a pending setup check on a home route
  - SplashViewModel marks the check pending when the token is kept but roles are unknown
affects: [05-DEVICE-UAT-CHECKLIST (D-02 device check)]

actuals:
  tokens: 2900
  tasks: 2
  commits: 2
plan_head_before: 6ac9c82732ce5426a48f05d63af6ef4c6094e4f5
plan_head_after: 359c721e5bf5aee50059aec0b4ac90a071bc0b84

tech-stack:
  added: []
  patterns:
    - "Foreground work is decided by a pure ExpertModeGate function before any request, so the role guard is unit-tested without a UserManager"
    - "A pending flag stays set on a failed lookup or a live call and clears only on an answered lookup, a deferral, a client-only account or sign-out"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/ExpertModeGate.swift
    - ClickMe2026Tests/Utils/ExpertModeGateTests.swift
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/ClickMe2026App.swift
    - ClickMe2026/Views/Screens/Splash/SplashViewModel.swift

key-decisions:
  - "A client-only account outside Expert mode clears the pending flag with no request (D-04, Android role guard); a stored Expert mode on a client-only account still re-checks, matching the launch rule"
  - "After a successful lookup the re-check returns, flag still set, while a call is active, so the setup hub never replaces the shell that hosts the call screen (single-call invariant)"
  - "The hook lives at App level (scenePhase in ClickMe2026App); if the device check shows it does not report .active, move the call into the two shells' scenePhase handlers (RESEARCH A6)"

requirements-completed: [SIGN-06, D-02]

coverage:
  - id: D1
    description: "recheckDecision rows: not pending is none; deferred clears; unknown roles wait; client-only outside Expert clears with no request; client-only in Expert mode and an expert in either mode check (D-01, D-02, D-04)"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#recheckNotPending, recheckDeferredClears, recheckUnknownRolesWait, recheckClientOnlyClears, recheckClientOnlyInExpertChecks, recheckExpertChecks"
        status: pass
    human_judgment: false
  - id: D2
    description: "recheckSetupIfPending consults recheckDecision before its single lookUpSetupCompleted() call, stays pending on a failed lookup, returns on an active call before clearing the flag or raising the hub request, runs one at a time, and never reads the cached profile; sign-out, an answered Expert switch and the launch landing maintain the flag"
    requirement: "SIGN-06"
    verification:
      - kind: other
        ref: "Task 1 region gates (order of recheckDecision, lookup, call guard, flag clear, hub request; counts; no expertProfile or refreshExpertProfile in the body; flag writes in clearLocalSession, requestModeSwitch, resolvePostAuthLanding)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Splash marks the check pending on the transient branch and markSetupCheckPending makes no request; build succeeds with no new warnings in the four app files; PushRoutePlannerTests and AutoLoginOutcomeTests still pass"
    requirement: "SIGN-06"
    verification:
      - kind: other
        ref: "Task 2 grep gate, xcodebuild build + warning comparison against /tmp/05-12-warn-before.txt"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests (14 tests), AutoLoginOutcomeTests (5 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "On a real iPhone: an unfinished expert account launched in airplane mode lands on home, and after the network is back and the app is backgrounded and reopened the setup hub opens; a client-only account does the same with nothing happening and Expert not offered or entered; an active call keeps the hub from opening until a later foreground"
    requirement: "SIGN-06"
    verification: []
    human_judgment: true
    rationale: "scenePhase delivery at App level (RESEARCH A6), the airplane-mode launch and the live-call interaction need a real device; the App hook and the in-call return are grep-gated but not exercised by a test"

duration: 20min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 12: Foreground setup re-check Summary

**A setup lookup that failed or was skipped at launch is retried once when the app returns to the foreground, role-guarded so a client-only account never triggers a `/expert/*` call, and never opening the setup hub over a live call.**

## Performance

- **Duration:** about 20 min
- **Completed:** 2026-11-13T22:42:00Z
- **Tasks:** 2
- **Files modified:** 5 (0 created, 5 modified)

## Accomplishments

- `ExpertModeGate.recheckDecision` decides `none`, `wait`, `clearPending` or `check` before any request (Android `recheckSetupIfPending` role guard).
- `UserManager.recheckSetupIfPending()` runs one at a time, makes one `lookUpSetupCompleted()` call, and stays pending when the lookup fails or a call is active; otherwise it clears the flag and raises `setupHubRequested` for an unfinished profile.
- `setupCheckPending` is set by a failed launch or login lookup (`resolvePostAuthLanding`) and by Splash's transient branch, and cleared by sign-out and by an answered Expert switch (not one refused for a call, superseded or signed out).
- `ClickMe2026App` observes `scenePhase` and starts the re-check when the phase is `.active` on a home route.
- `ExpertModeGateTests`: 28 tests (22 before, 6 new rows).

## Task Commits

1. **Task 1 (tracer): re-check an unknown setup state on foreground** - `472468e` (feat)
2. **Task 2: an offline launch leaves the setup check pending** - `359c721` (feat)

## TDD notes

- RED (Task 1): the six new rows with a compiling stub returning `.none`: 28 tests ran, 8 issues on the planned assertions. The stub was never committed.
- GREEN: real decision; "Test run with 28 tests in 1 suite passed".
- The plan prescribes one commit per task, so there is no separate `test(05-12)` commit.

## Verification

- Task 1: `ExpertModeGateTests` 28 tests passed; all three grep chains pass (hook present, `recheckDecision` before the single lookup, guard on the failed lookup, no cached-profile read, three `isRecheckingSetup` references, flag maintenance in the three other functions, call guard between the lookup and both the flag clear and the hub request); `grep -c "enum RecheckDecision"` prints 1.
- Tracer gate: auto mode off, the tracer's `<verify>` is automated-only, so it was run against the tree before commit and passed; expansion continued.
- Task 2: grep gate passes (Splash marks pending, `markSetupCheckPending` has no refresh); `BUILD SUCCEEDED`, no warning outside the baseline (the one baseline warning, `describe` in `UserManager.swift`, did not reappear in the incremental build).
- Regression: `PushRoutePlannerTests` 14 tests passed (`/tmp/05-12-reg-a.log`); `AutoLoginOutcomeTests` 5 tests passed (`/tmp/05-12-reg-b.log`).

## Deviations from Plan

None - plan executed exactly as written.

UI-SPEC: this plan adds no visible UI, so `05-UI-SPEC.md` did not change the implementation.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. No new endpoint: the re-check reuses the existing expert profile lookup behind `recheckDecision`, which closes T-05-26 (no request for a client-only account outside Expert mode), T-05-27 (only while pending, one at a time) and T-05-32 (no hub over a live call).

## Notes for later plans

- `ClickMe2026/Localizable.xcstrings` and `.planning/config.json` carried pre-existing uncommitted edits; neither was touched or staged.
- `05-DEVICE-UAT-CHECKLIST.md` does not exist yet. Coverage D4 must go into it: airplane-mode launch of an unfinished expert, reopen with network opens the hub; client-only account does nothing; a call in progress at reopen leaves the hub closed until a later foreground. If the App-level `scenePhase` does not fire (RESEARCH A6), move the call into the `scenePhase` handlers of `HomeClientView` and `HomeExpertView`.
- Behavior to know: a pending check that the user completes through the setup hub is cleared by the next re-check's answered lookup, not by `completeSetup()` (one extra lookup on the next foreground at most).
- No backend or Android change was made.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ExpertModeGate.swift (`enum RecheckDecision`), ClickMe2026/Managers/UserManager.swift (`func recheckSetupIfPending`), ClickMe2026/ClickMe2026App.swift (`scenePhase`), ClickMe2026/Views/Screens/Splash/SplashViewModel.swift, ClickMe2026Tests/Utils/ExpertModeGateTests.swift
- FOUND commits: 472468e, 359c721 (both ancestors of HEAD)
