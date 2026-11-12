---
phase: 04-booking-payment-and-discovery
plan: 07
subsystem: auth
tags: [swiftui, auto-login, suspension, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "Involuntary-logout path (suspension handler, forceLogout) that this plan reads"
provides:
  - "AutoLoginOutcome.resolve(hadStoredToken:refresh:): pure cold-launch decision; a suspension resolves to signedOut"
  - "UserManager.tryAutoLogin returns false on a 403 ACCOUNT_SUSPENDED, so the splash routes to Login"
  - "SuspensionNotice: fixed UI-SPEC copy and the one-shot presentation rule"
  - "Login shows 'Your account has been suspended' once; Close Alert clears UserManager.wasSuspended"
affects: [04-14, phase-08-release-pass, android-parity]

actuals:
  tokens: 3600
  tasks: 2
  commits: 2
plan_head_before: 53bf55163cf779b5e7838f760e6f789b4a69fc6a
plan_head_after: a48c5a444c67001c209b2c3f1e3e0f2c81f4a8fc

tech-stack:
  added: []
  patterns:
    - "Pure decision enum behind an async manager method (classify the failure, then resolve), as PaymentSheetOutcome does"
    - "One-shot alert: @State presented flag plus a pure shouldPresent rule, flag cleared by the dismiss button"

key-files:
  created:
    - ClickMe2026/Utils/AutoLoginOutcome.swift
    - ClickMe2026/Utils/SuspensionNotice.swift
    - ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift
    - ClickMe2026Tests/Utils/SuspensionNoticeTests.swift
  modified:
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift

key-decisions:
  - "A suspension is detected by wasSuspended or by a 403 whose StandardErrorResponse.code is accountSuspended (private isSuspension), checked before isAuthRejection; forceLogout is not called again because the handler already cleared the session"
  - "The Login alert is a second .alert on the same container as the apiError alert; it compiled and needed no separate container"
  - "Android's OK versus iOS Close Alert is a logged copy difference, not aligned (UI-SPEC)"

requirements-completed: [D-13]

coverage:
  - id: D1
    description: "A cold launch whose /me refresh returns 403 ACCOUNT_SUSPENDED resolves to signed out, so tryAutoLogin returns false and the splash routes to Login (no home shell)"
    requirement: "D-13"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift#a suspension is signed out, so no home shell is shown"
        status: pass
    human_judgment: false
  - id: D2
    description: "No token, a rejected token, a success and a transient failure resolve as before (offline tolerance kept)"
    requirement: "D-13"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift (4 other rows)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The suspension notice copy matches UI-SPEC exactly and presents once; a fresh sign-in after dismissal does not show it again"
    requirement: "D-13"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/SuspensionNoticeTests.swift"
        status: pass
    human_judgment: false
  - id: D4
    description: "The alert on a real cold launch of a suspended account, and the mid-session case (handler logs out, app routes to Login, alert shows)"
    verification: []
    human_judgment: true
    rationale: "tryAutoLogin and LoginView need the real app and a suspended production account; the singleton UserManager cannot be unit tested. Logged as unrun-verify in WINDOWS.md for the Phase 8 release pass (UI-SPEC D4)"

duration: 15min
completed: 2026-11-12
status: complete
---

# Phase 04 Plan 07: Suspension on cold launch Summary

**A 403 ACCOUNT_SUSPENDED on the cold-launch /me refresh now resolves to signed out through a pure AutoLoginOutcome, so the splash routes to Login, where a one-shot "Your account has been suspended" alert clears UserManager.wasSuspended on Close Alert.**

## Performance

- **Duration:** about 15 min
- **Started:** 2026-11-12T05:03:00Z (approximate)
- **Completed:** 2026-11-12T05:18:00Z
- **Tasks:** 2
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments

- `tryAutoLogin` classifies the refresh failure as suspended, auth-rejected or transient and asks `AutoLoginOutcome.resolve`; a suspension returns false instead of falling into the transient branch after the handler had already logged out (T-04-19).
- Login reads `UserManager.wasSuspended` on appear and shows the UI-SPEC alert once; it covers both the cold launch and the mid-session case, since both end on Login with the flag set.
- Offline tolerance is unchanged: a network error, 5xx or timeout still keeps the token and lands on the home shell.
- The stale `wasSuspended` doc ("cleared on the next successful login") now says it is cleared when the Login alert is dismissed.

## Task Commits

1. **Task 1 (tracer): a suspended account lands on Login with the notice** - `404f95c` (fix)
2. **Task 2: suspension notice shows once, copy locked by tests** - `a48c5a4` (test)

**Plan metadata:** recorded in the docs(04-07) commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Utils/AutoLoginOutcome.swift` - `signedIn` / `signedOut`, nested `RefreshResult`, `resolve(hadStoredToken:refresh:)`
- `ClickMe2026/Utils/SuspensionNotice.swift` - title, message, `Close Alert` label, `shouldPresent(wasSuspended:alreadyPresented:)`
- `ClickMe2026/Managers/UserManager.swift` - `tryAutoLogin` classification, private `isSuspension(_:)`, doc fixes
- `ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift` - two `@State` flags, `onAppear` check, suspension `.alert`
- `ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift` - 5 rows (decision table)
- `ClickMe2026Tests/Utils/SuspensionNoticeTests.swift` - 4 rows (presentation rule, exact copy)

## Android

Android already routes a suspended cold launch to Login and shows the dialog, so **no Android follow-up is needed for behavior**. `UserManager.restore()` calls `afterMeFailure`; when the transport cleared the tokens and the error is `ACCOUNT_SUSPENDED` it runs `handleAccountSuspended()` (sets `wasSuspended`, logs out) and returns `LaunchDestination.Login`. `ClickMeApp.kt` shows `SuspendedAccountDialog` (`suspended_title`, `suspended_body` with the support email, `suspended_ok`) from `showSuspendedDialog`, and `onSuspendedDialogDismissed()` calls `clearSuspensionFlag()`. Differences, logged and not aligned: the button reads `OK` on Android versus `Close Alert` on iOS (UI-SPEC contract), Android's dialog also has a contact-support action, it is hosted at the app level rather than on Login, and `startSession` also resets the flag on login. No Android code was changed.

## Decisions Made

- Suspension is checked before auth rejection and uses both `wasSuspended` and the decoded error code, so the decision holds whether or not the handler ran first.
- `forceLogout()` is not called again for a suspension; the handler already cleared the session before the 403 was rethrown.
- The second `.alert` sits on the same container as the `apiError` alert (the plan allowed a separate container only if needed). It compiled and the build is clean; two alerts are never raised together because the suspension one is set on appear.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0.
**Impact on plan:** none.

## Issues Encountered

None. The warning baseline for the four app files was one pre-existing `UserManager.swift` warning (`describe` main-actor call); the post-change build shows the same single warning and no new ones.

## Verification

- `AutoLoginOutcomeTests`: 5 tests in 1 suite passed. `SuspensionNoticeTests`: 4 tests in 1 suite passed.
- Debug build for iPhone 17 simulator: BUILD SUCCEEDED; no warning outside the baseline.
- Acceptance greps: `enum AutoLoginOutcome` count 1; `AutoLoginOutcome.resolve(` in `UserManager.swift`; `clearSuspensionFlag()` and `SuspensionNotice.shouldPresent` in `LoginView.swift`; `wasSuspended` now referenced outside `UserManager.swift` (`LoginView.swift`, `SuspensionNotice.swift`); `Close Alert` count 2.

## Known Stubs

None.

## Threat Flags

None. T-04-19 is mitigated (a suspension resolves to signed out and the token was already cleared by the handler). T-04-20 accepted: the copy shows only the public support address.

## User Setup Required

None - no external service configuration required.

## Follow-ups

- The flag is in memory only: after a relaunch with the token already cleared, Login appears without the alert (plan assumption; the alert showed in the session where the suspension happened).
- If the sign-in request itself returns ACCOUNT_SUSPENDED while Login is on screen, the existing `apiError` alert shows the server message; no second alert was added.
- Device check on a real cold launch: logged as `unrun-verify` in `.planning/WINDOWS.md` for the Phase 8 release pass and plan 04-14's checklist.
- The pending todo "Show the suspension message on a cold launch" moved to `.planning/todos/completed/`.

## Next Phase Readiness

Ready for the next Phase 04 plan. No blockers from this plan.

## Self-Check: PASSED

- Created files exist: AutoLoginOutcome.swift, SuspensionNotice.swift, AutoLoginOutcomeTests.swift, SuspensionNoticeTests.swift.
- Commits `404f95c` and `a48c5a4` are ancestors of HEAD.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
