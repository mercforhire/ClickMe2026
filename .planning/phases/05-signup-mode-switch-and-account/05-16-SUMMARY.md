---
phase: 05-signup-mode-switch-and-account
plan: 16
subsystem: auth
tags: [swiftui, expert-setup, setup-hub, not-now, userdefaults, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-07 expert-mode gate (requestModeSwitch, setupHubRequested, clearLocalSession gate resets)
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-11 hub email-verified seed (.task on SignupOverviewView, kept intact)
provides:
  - SetupDeferralStore (persisted Not-now flag, key "setupDeferred", injectable UserDefaults)
  - UserManager.isSetupDeferred, deferSetup(), completeSetup()
  - Setup hub Not now: back chevron and swipe-back removed, leading Not now button, on every hub entry
  - Publish routed through completeSetup(); a new Expert request clears the deferral before the setup lookup; every sign-out clears it
  - SetupDeferralStoreTests (6 tests)
affects: [05-10 remaining setMode callers and private setter, 05-12 foreground re-check, 05-13 verifier, 05-DEVICE-UAT-CHECKLIST SIGN-06 row]

actuals:
  tokens: 3070
  tasks: 2
  commits: 2
plan_head_before: cba34b56858004f7b23389ec058ca47f5cc5c99b
plan_head_after: c828abf57c829d8acdb751f5d79beec0e153584b

tech-stack:
  added: []
  patterns:
    - "Persisted flag behind a tiny injectable store (SetupDeferralStore) so UserManager glue, which cannot be built in tests, still has a unit-tested core"
    - "Optional exit closure on a shared screen drives its chrome: a private ViewModifier removes back and swipe-back only when onNotNow is set, so previews keep the system back button"

key-files:
  created:
    - ClickMe2026/Utils/SetupDeferralStore.swift
    - ClickMe2026Tests/Utils/SetupDeferralStoreTests.swift
  modified:
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift
    - ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift

key-decisions:
  - "Not now is wired once, in LoginView's .overview destination, which covers the .signupSetup resume, the hub after a login, the hub after a fresh signup and the hub the Mode Switch gate opens (all push the same SignupRoute.overview)"
  - "Asking for Expert clears the deferral after the call guard and before the setup lookup, so a request refused for an active call keeps the deferral, while one later superseded still ends it (the user did ask)"
  - "Not now uses .font(.brand(.body)) in Brand.onSurfaceVariant per UI-SPEC A1, not the accent"

patterns-established:
  - "Region-scoped awk gates over UserManager method bodies stand in for tests of code behind a private init"

requirements-completed: [SIGN-06]

coverage:
  - id: D1
    description: "SetupDeferralStore: not deferred when fresh, set persists across stores on the same suite, clear ends it, key is setupDeferred"
    requirement: "SIGN-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/SetupDeferralStoreTests.swift#freshStoreIsNotDeferred, setPersistsAcrossStores, clearEndsDeferral, clearWhenNotDeferredIsHarmless, keyIsSetupDeferred, setWritesUnderKey"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every sign-out path clears the deferral (clearLocalSession), so it never reaches the next account (T-05-15)"
    requirement: "SIGN-06"
    verification:
      - kind: other
        ref: "region gate: awk '/private func clearLocalSession/,/^    }$/' UserManager.swift contains setupDeferral.clear()"
        status: pass
    human_judgment: false
  - id: D3
    description: "deferSetup stores the deferral, sets Client mode and drops a pending hub request; completeSetup clears it and sets Client mode; requestModeSwitch clears it before the lookup"
    requirement: "SIGN-06"
    verification:
      - kind: other
        ref: "region gates on deferSetup, completeSetup and requestModeSwitch (clear line precedes lookUpSetupCompleted line)"
        status: pass
    human_judgment: false
  - id: D4
    description: "LoginView wires Not now to deferSetup() and Publish to completeSetup(); SignupOverviewView hides back and swipe-back and shows Not now; build has no new warnings in the touched files"
    requirement: "SIGN-06"
    verification:
      - kind: other
        ref: "grep gates for deferSetup(), completeSetup(), setMode( count 1, navigationBarBackButtonHidden, BookingRequestSentPopGestureLock(), Not now"
        status: pass
      - kind: other
        ref: "xcodebuild build Debug iPhone 17: BUILD SUCCEEDED, comm -13 of warning baselines empty"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real iPhone: the hub has Not now and no back chevron; swipe-back does nothing on every entry; Not now lands on client home; relaunch shows client home; Mode Switch > Expert reopens the hub; Publish lands on client home"
    requirement: "SIGN-06"
    verification: []
    human_judgment: true
    rationale: "Swipe-back suppression, the route handoff after Not now and the relaunch behavior are SwiftUI and UIKit navigation behavior that need a real device; 05-DEVICE-UAT-CHECKLIST.md does not exist yet at this point in the phase, so this SIGN-06 row must be added when it is created"

duration: 13min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 16: Setup hub Not now Summary

**Setup hub gets Android's Not now: back chevron and swipe-back removed on every entry, Not now stores a UserDefaults deferral and lands on client home, and Publish, a new Expert request and every sign-out clear it.**

## Performance

- **Duration:** about 13 min
- **Completed:** 2026-11-13T22:16Z
- **Tasks:** 2
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- `SetupDeferralStore` (`key` "setupDeferred", `init(defaults:)`, `isDeferred`, `set()`, `clear()`) with 6 Swift Testing tests on isolated `UserDefaults` suites, including a second store on the same suite reading the flag (relaunch persistence).
- `UserManager`: `isSetupDeferred`, `deferSetup()` (set flag, Client mode, drop `setupHubRequested`), `completeSetup()` (clear flag, Client mode); `clearLocalSession()` clears the flag (T-05-15); `requestModeSwitch` clears it right after the `isSwitchingMode = true` line and before the lookup, below the call guard.
- `SignupOverviewView`: optional `onNotNow` on both inits; when set, a private `OverviewNotNowChrome` modifier hides the back button, attaches `BookingRequestSentPopGestureLock()` and adds a leading `Not now` toolbar button. Plan 05-11's `.task` is untouched.
- `LoginView`: `onNotNow` passed to the `.overview` destination; Publish now calls `completeSetup()`, leaving one `setMode(` call (the login landing, owned by plan 05-10).

## TDD

Task 1 was `tdd="true"` but the plan prescribes a single commit with five files, so the cycle was run locally and committed once.

- **RED:** tests written against a stub store (`isDeferred` always false, `set()` and `clear()` no-ops). Run: 6 tests, 2 failed on the planned assertions (`set() defers, and a second store ... reads it` expected `true` got `false`; `set() writes under the documented key`), exit 65, no build or load error. The other 4 passed trivially against the stub. Semantic assessment: target tests executed and failed on the intended assertion. Log: `/tmp/05-16-red.log`. Not run through `gsd_run check tdd-red-evidence` (the swift-testing report was read directly; `tdd_mode` is not a plan-level `type: tdd` here).
- **GREEN:** `UserDefaults`-backed implementation; 6 of 6 pass (`/tmp/05-16-t1.log`).
- No separate `test(05-16)` commit exists; the plan's one-commit instruction was followed.

## Task Commits

1. **Task 1: Tracer, Not now on the setup hub** - `77cd9a5` (feat)
2. **Task 2: Publish and a new Expert request clear the deferral** - `c828abf` (feat)

**Plan metadata:** committed with this SUMMARY (docs).

## Files Created/Modified

- `ClickMe2026/Utils/SetupDeferralStore.swift` - persisted Not-now flag
- `ClickMe2026Tests/Utils/SetupDeferralStoreTests.swift` - set, persist, clear, key
- `ClickMe2026/Managers/UserManager.swift` - deferral state, `deferSetup()`, `completeSetup()`, sign-out clear, clear in `requestModeSwitch`
- `ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift` - `onNotNow`, hub chrome modifier
- `ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift` - Not now wiring, Publish through `completeSetup()`

## Decisions Made

See `key-decisions` above. The plan's "mode setter" is `UserManager.setMode(_:)` (still internal; plan 05-10 makes it private).

## Deviations from Plan

### UI-SPEC refinement (not a defect)

**1. [UI-SPEC delta 1 / A1] Not now styling**
- **Plan said:** "the screen's secondary text style".
- **Built:** leading toolbar button, `.font(.brand(.body))` (17 pt Regular), `Brand.onSurfaceVariant`, not the accent, per UI-SPEC assumption A1.
- **Files:** `SignupOverviewView.swift`
- **Committed in:** `77cd9a5`

Otherwise none - plan executed as written. No auto-fixes.

## Issues Encountered

- `ClickMe2026/Localizable.xcstrings` carried uncommitted edits before this run and was not touched or staged by this plan; the new `Not now` literal relies on the String Catalog's automatic extraction, so no catalog entry was added by hand. `.DS_Store`, `.planning/config.json`, `state.json` and `milestone.lock` were also left unstaged.
- Device-check row for SIGN-06 is open (see D5); `05-DEVICE-UAT-CHECKLIST.md` does not exist yet.

## Known Stubs

None.

## Threat Flags

None. T-05-15 (deferral leaking to the next account) is mitigated by `setupDeferral.clear()` in `clearLocalSession()`. No packages installed (T-05-SC).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05-10 can now remove the last `setMode(` call in `LoginView` and make the setter private; `deferSetup()` and `completeSetup()` call `setMode` inside `UserManager`, so they keep working.
- `isSetupDeferred` is available for the launch and login landing decisions (plans 05-10 and 05-12) but nothing reads it yet.
- Device UAT: Mode Switch > Expert on an unfinished expert opens the hub with no back chevron; swipe-back does nothing; Not now lands on client home; relaunch shows client home; Expert again reopens the hub; Publish lands on client home.

## Self-Check: PASSED

- Created files exist: `SetupDeferralStore.swift`, `SetupDeferralStoreTests.swift`, this SUMMARY.
- Commits `77cd9a5` and `c828abf` are ancestors of HEAD; measured `commits: 2` from `cba34b5..HEAD`.
- Task 1 and Task 2 acceptance criteria re-run: `grep -c "func deferSetup"` is 1, `grep -c "func completeSetup"` is 1; tests 6 of 6; both grep gates; build succeeded with no new warnings.

---
*Phase: 05-signup-mode-switch-and-account*
*Completed: 2026-11-13*
