---
phase: 05-signup-mode-switch-and-account
plan: 07
subsystem: auth
tags: [swiftui, mode-switch, expert-setup, call-guard, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-01 UserManager additions (remembered email; nothing in the mode or session code)
provides:
  - ExpertModeGate pure decisions (decide, setupCompleted(from:), resolveSwitch)
  - UserManager.requestModeSwitch(_:source:) with setupHubRequested, isSwitchingMode, consumeSetupHubRequest() and the private lookUpSetupCompleted() helper
  - ModeSwitchGate.request(_:) call-guarded entry point for Mode Switch screens
  - ClickMe2026App handoff from a home route to the .signupSetup hub
  - ExpertModeGateTests (15 tests)
affects: [05-10 other setMode callers and private setter, 05-12 foreground re-check, 05-16 hub Not now and Publish completeSetup]

actuals:
  tokens: 3100
  tasks: 2
  commits: 2
plan_head_before: 1f99114f5e101ed7d148498e61c20a930faa9cd9
plan_head_after: e1d12c7c99c8f232c5e7cdaa3b4c7cdf1690654b

tech-stack:
  added: []
  patterns:
    - "Pure decision enum (ExpertModeGate) plus thin MainActor glue; UserManager cannot be built in tests, so every decision the glue makes is a table-tested pure function"
    - "Failed lookup becomes nil in exactly one place (ExpertModeGate.setupCompleted(from:)) and fails open; the cached expert profile is never a fallback"

key-files:
  created:
    - ClickMe2026/Utils/ExpertModeGate.swift
    - ClickMe2026/Managers/ModeSwitchGate.swift
    - ClickMe2026Tests/Utils/ExpertModeGateTests.swift
  modified:
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/ClickMe2026App.swift
    - ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift

key-decisions:
  - "requestModeSwitch refuses every switch (either mode, either source) while CallCenter reports a call, as its first statement, with no alert; the Expert path re-reads the call state after the lookup via resolveSwitch's isCallActive argument"
  - "The setup state comes only from lookUpSetupCompleted(); a thrown lookup is nil and fails open, so a stale cached profile (Publish does not refresh it) can never send a finished expert to the hub"
  - "A push-sourced request never raises the hub request (setupRequired(opensHub: false))"
  - "ModeSwitchGate adds only the in-call alert (before the request and again on a .blockedByCall result); decisions stay in ExpertModeGate and requestModeSwitch"

requirements-completed: [SIGN-06]

coverage:
  - id: D1
    description: "Expert switch with unfinished setup opens the hub decision; finished or failed lookup enters Expert"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#incompleteOpensHub, completeEntersExpert, failedLookupEntersExpert, resolveNilEntersExpert, resolveTrueEntersExpert, resolveFalseUserOpensHub"
        status: pass
    human_judgment: false
  - id: D2
    description: "A thrown lookup is nil and enters Expert even when a stale cached false exists (D-02)"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#offlineLookupIsNil, lookupFalse, lookupTrue, staleCacheDoesNotWin"
        status: pass
      - kind: grep
        ref: "region gate: requestModeSwitch body has no expertProfile/refreshExpertProfile and exactly one lookUpSetupCompleted() call"
        status: pass
    human_judgment: false
  - id: D3
    description: "Superseded and signed-out requests write nothing; a push never opens the hub"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#supersededWinsEverything, signedOutIsSessionEnded, resolveFalsePushDoesNotOpenHub"
        status: pass
    human_judgment: false
  - id: D4
    description: "No switch, from a user or a push, is applied during a call (single-call invariant)"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertModeGateTests.swift#callActiveIsBlocked, pushDuringCallIsBlocked"
        status: pass
      - kind: grep
        ref: "region gate: call guard precedes the generation bump and setMode( in requestModeSwitch; resolveSwitch receives a fresh CallCenter.shared.isCallActive"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real iPhone: incomplete setup opens the hub and the app never jumps back to a home route while it is open; finished setup enters Expert home; airplane mode enters Expert home, also right after Publish in the same session; a switch during a call shows the in-call alert and changes nothing"
    requirement: "SIGN-06"
    verification: []
    human_judgment: true
    rationale: "The route handoff, the live lookup and the in-call alert need a device; 05-DEVICE-UAT-CHECKLIST.md does not exist yet at this point in the phase, so these device checks must be added to it when it is created"

duration: 14min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 07: Expert-mode gate Summary

**One Expert-mode gate (`UserManager.requestModeSwitch`, decisions in the pure `ExpertModeGate`) sends an unfinished expert from Profile > Mode Switch to the setup hub, fails open on a failed lookup regardless of any cached profile, and refuses every switch during a call.**

## Performance

- **Duration:** 14 min
- **Completed:** 2026-11-13T21:35:36Z
- **Tasks:** 2
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `ExpertModeGate`: `decide(setupCompleted:)` (only `false` opens the hub), `setupCompleted(from:)` (the one place a thrown lookup becomes nil), `resolveSwitch(...)` (superseded, then sessionEnded, then blockedByCall, then the setup decision; a push never asks for the hub).
- `UserManager` gate section: nested `ModeSwitchSource` and `ModeSwitchResult`, observed `setupHubRequested` and `isSwitchingMode`, private `lookUpSetupCompleted()` (plans 05-10 and 05-12 reuse it), `requestModeSwitch(_:source:)` and `consumeSetupHubRequest()`. The call guard is the first statement. `clearLocalSession()` resets both flags.
- `ClickMe2026App` consumes `setupHubRequested` each time it turns true and moves to `.signupSetup` only from `.clientHome` or `.expertHome`, so the `currentMode` mirror and the logout observer never fight the handoff.
- `ModeSwitchGate.request(_:)` adds the in-call alert (before the request, and again when a call started during the lookup). Profile > Mode Switch on the client shell now uses it and no longer holds its own guard.
- `ExpertModeGateTests`: 15 tests in 1 suite.

## Task Commits

1. **Task 1 (tracer): Expert switch opens the hub; failed lookup enters Expert** - `c811481` (feat)
2. **Task 2: Mode Switch tap enters through one call-guarded gate** - `e1d12c7` (refactor)

## TDD notes

- RED: a compiling stub `ExpertModeGate` (always `.enterExpert` / nil) with the full suite: 15 tests ran and 48 issues were recorded on the planned assertions (for example `decide(setupCompleted: false) → .enterExpert` expected `.openSetupHub`; `lookup false → nil` expected `false`; every superseded row returned `.enterExpert`). Not a build failure, so a valid RED. The stub was never committed.
- GREEN: real implementation; 15 tests in 1 suite passed.
- The plan prescribes one commit per task, so there is no separate `test(05-07)` RED commit. `gsd_run check tdd-red-evidence` was not run: the plan is `type: execute`, not `type: tdd`.

## Verification

- `ExpertModeGateTests`: "Test run with 15 tests in 1 suite passed" (`/tmp/05-07-t1.log`).
- Task 1 region gates (call guard ahead of generation bump and `setMode(`, fresh `isCallActive` passed to `resolveSwitch`, exactly one `lookUpSetupCompleted()`, no cached-profile reads in `requestModeSwitch`, session reset in `clearLocalSession()`, App consumes the request, Profile uses the gate): pass. Acceptance counts 1, 1, 1.
- Task 2 grep gate pass; build gate `BUILD SUCCEEDED`; warning comparison for the five app files against `/tmp/05-07-warn-before.txt`: no new warnings (the one baseline warning, `describe` in `UserManager.swift`, is pre-existing).
- Tracer gate: auto mode off, `human_verify_mode` is `end-of-phase`, the tracer's `<verify>` is automated-only, so it was re-run against the committed tree, passed, and expansion continued.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] A sign-out now also replaces any in-flight mode request**
- **Found during:** Task 1
- **Issue:** `isLoggedIn` is true again after a quick sign-in, so an Expert lookup started before a sign-out could apply its result to the next account's session.
- **Fix:** `clearLocalSession()` bumps `modeSwitchGeneration`, so the old request resolves `.superseded` and writes nothing. It sits next to the plan's `setupHubRequested`/`isSwitchingMode` resets.
- **Files modified:** `ClickMe2026/Managers/UserManager.swift`
- **Commit:** c811481

**2. [Rule 3 - Blocking] `requestModeSwitch` is `@discardableResult`**
- **Found during:** Task 1
- **Issue:** The Profile call site (`Task { await UserManager.shared.requestModeSwitch(mode) }`) would produce an unused-result warning, which the "no new warnings" criterion forbids.
- **Fix:** Added `@discardableResult`, matching `ModeSwitchGate.request`.
- **Files modified:** `ClickMe2026/Managers/UserManager.swift`
- **Commit:** c811481

**Total deviations:** 2 auto-fixed. **Impact:** none on scope; both are internal to the gate.

UI-SPEC: this plan has no user-facing copy or layout, so nothing in `05-UI-SPEC.md` refined it.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. The only new network call is the existing `GET /expert/profile` inside an explicit Expert switch (T-05-16, D-04 consent); the server's `ensureExpert` remains the enforcer (T-05-14).

## Notes for later plans

- `ClickMe2026/Localizable.xcstrings` and `.planning/config.json` carried pre-existing uncommitted edits; neither was touched or staged by this plan.
- `05-DEVICE-UAT-CHECKLIST.md` does not exist yet. The device checks listed in coverage D5 (hub from Profile > Mode Switch, app never jumping back to a home route while the hub is open, airplane mode after Publish, switch during a call) must go into it.
- Until plan 05-16 lands the hub keeps its back chevron and has no Not now; leaving the client shell for the hub resets its tab state (fresh Explore tab on return, same as Android).
- Plan 05-10 moves the other three Mode Switch sites, both push handlers, Splash and Login onto the gate and makes `setMode` private. Plan 05-12 adds the foreground re-check on `lookUpSetupCompleted()`.
- No backend or Android change was made or is needed for this plan.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ExpertModeGate.swift, ClickMe2026/Managers/ModeSwitchGate.swift, ClickMe2026Tests/Utils/ExpertModeGateTests.swift
- FOUND commits: c811481, e1d12c7 (both ancestors of HEAD)
