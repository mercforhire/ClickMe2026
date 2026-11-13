---
phase: 05-signup-mode-switch-and-account
plan: 10
subsystem: auth
tags: [swiftui, mode-switch, expert-setup, call-guard, push, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-07 requestModeSwitch, ModeSwitchGate, lookUpSetupCompleted; plan 05-16 setup deferral (isSetupDeferred, deferSetup, completeSetup); plan 05-14 generic HomeShellExit on both shells
provides:
  - All four Mode Switch screens go through ModeSwitchGate.request (in-call guard everywhere)
  - Both shells' push handlers go through requestModeSwitch(_:source: .push) and replay a tap held by a call when the call ends
  - UserManager.resolvePostAuthLanding(roles:) and PostAuthLanding, the one launch and login landing decision
  - ExpertModeGate.shouldCheckSetupAtLaunch, shouldLookUpTopics, landingMode
  - Private mode setter (no Swift file outside UserManager.swift can set the mode)
affects: [05-12 foreground re-check (reuses lookUpSetupCompleted, depends on this plan), 05-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 5000
  tasks: 2
  commits: 2
plan_head_before: 440db2341572a67b17372c1a93064722babf5294
plan_head_after: a4c997b475caf1b15e5d4b56e931375e57166cf9

tech-stack:
  added: []
  patterns:
    - "Every route into Expert mode is one of requestModeSwitch, resolvePostAuthLanding, deferSetup or completeSetup; the setter is private so a new view cannot bypass the gate"
    - "A push blocked by a call returns without clearing pushRouter.pending; the shell observes CallCenter.isCallActive (CallOverlayHost pattern) and replays the tap when the call ends"
    - "Launch rules are pure ExpertModeGate predicates; resolvePostAuthLanding only calls /expert/* behind them"

key-files:
  created: []
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift
    - ClickMe2026/Views/Screens/Settings/Mode Switching/ModeSwitchView.swift
    - ClickMe2026/Views/Screens/Splash/SplashViewModel.swift
    - ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/Utils/ExpertModeGate.swift
    - ClickMe2026Tests/Utils/ExpertModeGateTests.swift

key-decisions:
  - "Push handlers call requestModeSwitch(source: .push) directly, not ModeSwitchGate: a replay on every foreground must not raise the 'switch modes' alert; the gate itself refuses the switch during a call"
  - "A .setupRequired result on a push plans the tap again; the gate has fetched the incomplete profile, so PushRoutePlanner (unchanged, fail closed) opens the notifications list and the recursion cannot loop"
  - "resolvePostAuthLanding checks setup for an expert or a stored Expert mode that has not deferred, fails open through lookUpSetupCompleted (never the cached profile), and makes no /expert/* call for a client-only account in Client mode (D-04)"
  - "Mode Switch busy state is .disabled on the card stack only, reading UserManager.shared.isSwitchingMode (05-UI-SPEC A2)"

requirements-completed: [SIGN-06]

coverage:
  - id: D1
    description: "Launch and login rules: an expert or stored Expert mode that has not deferred is checked; a deferred setup and a client-only account in Client mode are not (D-01, D-04)"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#expertIsChecked, storedExpertModeIsChecked, clientOnlyIsNotChecked, deferredIsNotChecked"
        status: pass
    human_judgment: false
  - id: D2
    description: "Landing mode: stored mode restored; first boot is Expert only for an expert with a topic; topics lookup only for an expert on first boot (D-04)"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#storedModeWins, firstBootLanding, topicsLookupRule"
        status: pass
    human_judgment: false
  - id: D3
    description: "resolvePostAuthLanding makes exactly one setup lookup behind shouldCheckSetupAtLaunch and one topics lookup behind shouldLookUpTopics, and never reads the cached profile"
    requirement: "SIGN-06"
    verification:
      - kind: grep
        ref: "region gate on resolvePostAuthLanding (order, counts, no expertProfile/refreshExpertProfile)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No Swift file outside UserManager.swift calls the mode setter, and it is private; Splash and Login hold no duplicate setup check"
    requirement: "SIGN-06"
    verification:
      - kind: grep
        ref: "Task 2 grep gate A (setMode( outside UserManager.swift empty, private func setMode, no isExpertProfileIncomplete, no refreshExpertProfile in Splash or Login)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A push that needs a switch during a call keeps its tap queued with no alert and replays when the call ends; all four Mode Switch screens use the gate"
    requirement: "SIGN-06"
    verification:
      - kind: grep
        ref: "Task 1 gates (call guard ahead of setMode in requestModeSwitch, separate .blockedByCall case in both shells with no pending clearing, onChange(of: callCenter.isCallActive) in both shells, ModeSwitchGate.request on three screens)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests (14 tests, planner unchanged)"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real iPhone: Not now then relaunch lands on client home with no hub; Mode Switch > Expert clears it and a relaunch with setup unfinished opens the hub; sign out and in opens the hub; an expert-targeted push for an unfinished expert opens the notifications list; on a dual-role account a push for the other mode tapped during a call leaves mode and call screen unchanged, then opens its destination when the call ends; Mode Switch from the shell routes during a call shows 'End the call to switch modes.'; cards are dimmed while a slow Expert lookup runs"
    requirement: "SIGN-06"
    verification: []
    human_judgment: true
    rationale: "Relaunch landing, live setup lookup, call state and push delivery need a real device; the push-replay-on-call-end behavior is wired and grep-gated but not exercised by a test"

duration: 16min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 10: Remaining callers on the Expert-mode gate Summary

**Every Mode Switch screen, both push handlers, Splash and Login now enter Expert mode through one gate (`requestModeSwitch` or the shared `resolvePostAuthLanding`), a call blocks every switch and holds a push tap until the call ends, and the mode setter is private.**

## Performance

- **Duration:** 16 min
- **Completed:** 2026-11-13T22:31:16Z
- **Tasks:** 2
- **Files modified:** 9 (0 created, 9 modified)

## Accomplishments

- The two shell `.modeSwitch` routes and `ExpertProfileHomeScreen` call `ModeSwitchGate.request(_:)`, so the "End the call to switch modes." guard now covers all four Mode Switch entry points (the two shell routes had none).
- Push handlers in both shells switch on `requestModeSwitch(mode, source: .push)`: `.switched` returns, `.setupRequired` plans the tap again (it then opens the notifications list), `.blockedByCall` returns with the tap still queued and no alert, `.sessionEnded` and `.superseded` return. Both shells observe `CallCenter` and replay the tap on `.onChange(of: callCenter.isCallActive)` when it turns false.
- `ModeSwitchView` disables its card stack while `UserManager.shared.isSwitchingMode` is true.
- `ExpertModeGate` gains `shouldCheckSetupAtLaunch`, `shouldLookUpTopics` and `landingMode`; `UserManager` gains `PostAuthLanding` and `resolvePostAuthLanding(roles:)`. Splash and Login use it; `resolveLandingMode`, `SplashViewModel`'s setup check and `LoginView`'s setup check are deleted.
- `setMode` is `private`. The only callers left are inside `UserManager.swift`.
- `ExpertModeGateTests`: 22 tests (15 before, 7 new rows).

## Task Commits

1. **Task 1 (tracer): every Mode Switch screen and push switch uses the gate** - `e5a1cd8` (refactor)
2. **Task 2: Splash and Login land through one shared check; the setter becomes private** - `a4c997b` (refactor)

## TDD notes

- RED (Task 2): the seven new `ExpertModeGateTests` rows with compiling stubs returning `false` / `.client`: 22 tests ran and 9 issues were recorded on the planned assertions. Not a build failure, so a valid RED. The stub was never committed.
- GREEN: real rules; "Test run with 22 tests in 1 suite passed".
- The plan prescribes one commit per task, so there is no separate `test(05-10)` commit.

## Verification

- Task 1 gates: all three pass (`PushRoutePlannerTests`: 14 tests in 1 suite passed; both grep chains pass).
- Task 2 gates: `ExpertModeGateTests` 22 tests passed; grep gate A and the `resolvePostAuthLanding` region gate (setup lookup after the predicate's `if`, one topics call at the topics predicate, no cached-profile read) pass; `grep -c "enum PostAuthLanding"` prints 1.
- Build gate: `BUILD SUCCEEDED`; warning comparison for the eight app files against `/tmp/05-10-warn-before.txt` shows no new warnings (the one baseline warning, `describe` in `UserManager.swift`, is pre-existing).
- Regression: `AutoLoginOutcomeTests` passed (5 tests in 1 suite, `/tmp/05-10-reg.log`).
- Tracer gate: auto mode off, `human_verify_mode` is `end-of-phase`, the tracer's `<verify>` is automated-only, so it was re-run against the committed tree, passed, and expansion continued.

## Deviations from Plan

None - plan executed exactly as written.

UI-SPEC: delta 2 and A2 (Mode Switch busy state is `.disabled` only, no spinner, no toast, no text) match the plan's `.disabled(...)` instruction, so nothing in `05-UI-SPEC.md` changed the implementation.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint: the setup and topics lookups already existed and are now called only behind `shouldCheckSetupAtLaunch` and `shouldLookUpTopics`, which closes T-05-24 (a client-only account in Client mode makes no `/expert/*` call at launch or login).

## Notes for later plans

- `ClickMe2026/Localizable.xcstrings` and `.planning/config.json` carried pre-existing uncommitted edits; neither was touched or staged by this plan.
- `05-DEVICE-UAT-CHECKLIST.md` still does not exist. The device checks in coverage D6 (Not now relaunch, Mode Switch re-opens the hub, push during a call replays after the call, switch during a call from the shell routes, dimmed cards) must go into it when it is created.
- Behavior change to be aware of: a stored Expert mode on an account whose roles lack expert (possible on build 6) is now setup-checked at launch, as the plan's assumption states.
- Plan 05-12 (foreground re-check) can reuse `lookUpSetupCompleted()` and `isSetupDeferred`; it is unchanged by this plan.
- No backend or Android change was made in this plan. Android already has `resolvePostAuthDestination` with the same rules.

## Self-Check: PASSED

- FOUND: ClickMe2026/Managers/UserManager.swift (`resolvePostAuthLanding`, `enum PostAuthLanding`, `private func setMode`), ClickMe2026/Utils/ExpertModeGate.swift, ClickMe2026Tests/Utils/ExpertModeGateTests.swift
- FOUND commits: e5a1cd8, a4c997b (both ancestors of HEAD)
