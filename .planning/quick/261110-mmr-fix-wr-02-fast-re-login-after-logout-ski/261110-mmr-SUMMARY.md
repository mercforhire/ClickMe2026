---
phase: quick-261110-mmr
plan: 01
subsystem: push
tags: [push, fcm, logout, push-token-cleanup, user-manager, swift-testing, android-parity]

# Dependency graph
requires:
  - phase: 02-shared-ios-plumbing
    provides: "02-12 PushTokenCleanup (bounded DELETE, deleteToken-only retry marker, forceSignOut), UserManager.isLoggingOut guard, PushTokenCleanupTests harness"
provides:
  - "User logout in Android order: server DELETE (bearer live, 3 s cap), retry marker, Firebase deleteToken (3 s cap), then clearLocalSession; Login appears only after the cleanup"
  - "One serialized deleteToken lane (PushTokenCleanup.deleteTokenRun) shared by signOut, forceSignOut and retryIfPending; the retry awaits the run in flight before reading the marker"
  - "UserManager.isLoggingOut reset in clearLocalSession(), so it never outlives the session and never blocks the next sign-in"
  - "Log out in-progress state (spinner, disabled) on the client and expert Profile Log Out row and the delete-account farewell's Back to Login button (IN-02)"
  - "WR-02 and IN-02 recorded fixed; UAT item 14 (e) and 02-UAT test 10 describe the fast re-login as a pass condition"
affects: [push, logout, phase-02-uat, android-follow-ups]

# Actuals (#2632): estimateTokens scale, chars/4 over the realized diff of this plan's files
actuals:
  tokens: 12134
  tasks: 2
  commits: 4
plan_head_before: 8c0cd9dad2687553bb412e7bc0330076d2fb8b14
plan_head_after: d3d6bc66c0f7baa334d0d183ebe32bc94d64abe3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Serialized async lane: a stored Task<Bool, Never> that each new run awaits first, enqueued synchronously so a non-awaiting caller still leaves it where the next awaiter finds it"
    - "In-progress UI state read straight from an @Observable manager through a view-model computed property (no @Published mirror)"

key-files:
  created: []
  modified:
    - ClickMe2026/Managers/PushTokenCleanup.swift
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026Tests/Push/PushTokenCleanupTests.swift
    - ClickMe2026/Views/Screens/Client Mode/Profile/Subviews/ClientProfileHomeListItem.swift
    - ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift
    - ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift
    - ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountFarewell.swift
    - .planning/phases/02-shared-ios-plumbing/02-REVIEW-DISPOSITION.md
    - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md
    - .planning/phases/02-shared-ios-plumbing/02-UAT.md

key-decisions:
  - "quick 261110-mmr: user logout waits for the whole push cleanup before clearing the session (DELETE, then deleteToken, each capped at 3 s, then clearLocalSession), matching Android UserManager.logout() (user decision 2026-11-10); supersedes the 02-12 order that routed to Login right after the DELETE. Login cannot appear while the cleanup runs, so a fast re-login never overlaps it (WR-02)"
  - "quick 261110-mmr: every Firebase deleteToken goes through one serialized lane in PushTokenCleanup, and retryIfPending awaits the run in flight before reading the marker; forceSignOut enqueues its background run synchronously. Kept for the one overlap left (a sign-in right after an involuntary logout), not for the user-logout window the Android order closes"
  - "quick 261110-mmr: involuntary logouts keep the 02-12 behavior (no DELETE, session cleared synchronously, deleteToken in the background). Android's single logout() path waits on deleteToken for them too; iOS does not match that part because its suspension handler is a synchronous interceptor closure and the 02-12 immediate clear is a recorded user decision (D-17, D-18). Needs a user call if parity there is wanted"
  - "quick 261110-mmr: Log out shows an in-progress state (spinner, disabled) for the whole wait on all three Log out sites (IN-02 fixed). Android has no such state, so this is iOS-only and a candidate Android follow-up"

patterns-established:
  - "Lane pattern for a step that must never overlap itself: store the latest Task, have the next Task await the previous one's value first, enqueue synchronously, and settle shared state (the retry marker) inside the Task so awaiters observe the final state"

requirements-completed: [QUICK-261110-mmr, PUSH-04]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "User logout runs DELETE while signed in, then deleteToken while still signed in, then clears the session; a failed or hung step never stops logout and the clear lands within the cap"
    requirement: PUSH-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#signOutOrder"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#aHungDeleteTokenStillFinishesLogoutWithinTheCap"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#unregisterTimesOut"
        status: pass
    human_judgment: false
  - id: D2
    description: "A sign-in right after an involuntary logout waits for its background deleteToken (success, failure and hang, all bounded) and no two deleteTokens ever run at once"
    requirement: PUSH-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#userAndInvoluntaryDeleteTokensNeverOverlap"
        status: pass
    human_judgment: false
  - id: D3
    description: "The next sign-in on the device registers its push token (isLoggingOut cleared with the session; a completed logout owes the retry nothing) and the old account gets no pushes"
    requirement: PUSH-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#aCompletedLogoutLeavesNothingForTheNextSignInToWaitOn"
        status: pass
      - kind: other
        ref: "grep: isLoggingOut = false inside clearLocalSession() and absent from logout() (task verify 2)"
        status: pass
    human_judgment: true
    rationale: "UserManager cannot be unit-tested (singleton over Keychain and Firebase); the flag reset is verified by code inspection and the registration on a real re-login is UAT item 14 (e)"
  - id: D4
    description: "Log out shows a spinner and cannot be tapped twice for the whole wait (up to about 6 s), on the client and expert Profile rows and the delete-account farewell"
    verification: []
    human_judgment: true
    rationale: "Visual state on a device; no snapshot test exists for these screens. UAT item 14 (a) step 2 and (e) step 7"
  - id: D5
    description: "WR-02 and IN-02 recorded fixed; UAT item 14 (e) and 02-UAT test 10 describe the fast re-login as a pass"
    verification:
      - kind: other
        ref: "Task 2 <automated> grep over 02-REVIEW-DISPOSITION.md, 02-DEVICE-UAT-CHECKLIST.md and 02-UAT.md"
        status: pass
    human_judgment: false

# Metrics
duration: 22min
completed: 2026-11-10
status: complete
---

# Quick 261110-mmr: Fix WR-02, fast re-login after logout skips push registration Summary

**User logout now waits for the whole push cleanup (server DELETE, then Firebase deleteToken, each capped at 3 s) before clearing the session, in Android's order, with a serialized deleteToken lane for the involuntary path and a spinner on every Log out control for the wait.**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-11-10T21:38:02Z
- **Completed:** 2026-11-10T22:00:00Z
- **Tasks:** 2
- **Files modified:** 13 (10 Swift, 3 planning docs)

## Accomplishments

- `PushTokenCleanup.signOut` runs DELETE (bearer live, 3 s cap), sets the retry marker, runs `deleteToken` (3 s cap) and only then calls `clearSession()`. The shell routes to Login after the cleanup, so a re-login cannot overlap it: WR-02's window no longer exists for a user logout. Worst case is about 6 s and never hangs.
- One `deleteToken` lane (`deleteTokenRun`) in `PushTokenCleanup`: `signOut`, `forceSignOut` and `retryIfPending` enqueue their run through `enqueueDeleteToken`, each run awaits the previous one, and the marker is cleared inside the run. `retryIfPending` awaits the run in flight before reading `isPending`, so `login`/`signup` (which already await the retry before `apply(...)`) wait for an involuntary logout's background `deleteToken` and register against a fresh token. `forceSignOut` enqueues synchronously, so an immediate retry finds the run instead of getting ahead of it.
- `UserManager.isLoggingOut` is reset in `clearLocalSession()`, never after `signOut`, so it cannot outlive the session it protects. During the logout it now also covers the `deleteToken` step while the bearer is still live, which is the only thing keeping a foreground re-upload or the regenerated-token callback from re-binding the leaving account.
- Log out feedback (IN-02): `ClientProfileHomeListItem.isBusy` shows a spinner in place of the trailing icon and disables the row; both Profile screens pass `viewModel.isLoggingOut` (a computed property over the `@Observable` manager). `DeleteAccountFarewell` gets the same for Back to Login. The `logout()` guard still makes a second call a no-op.
- `PushTokenCleanupTests`: 16 rows (10 before). RED commit first, `RED_EVIDENCE_OK` from the classifier, then GREEN.
- WR-02 and IN-02 marked fixed in `02-REVIEW-DISPOSITION.md` (open 6 to 4); UAT item 14 step 2 and new sub-item (e), and 02-UAT test 10, describe the Log Out spinner and the fast re-login as a pass.

## Task Commits

1. **Task 1 (RED): pin the Android logout order and one deleteToken lane** - `70a2649` (test)
2. **Task 1 (GREEN): wait for the push cleanup before logout lands on Login and show its progress** - `1824a11` (fix)
3. **Task 2: mark WR-02 and IN-02 fixed and update the PUSH-04 logout UAT wording** - `d3d6bc6` (docs)

**Plan metadata:** not committed by the executor (orchestrator handles the docs commit).

**Measured commits (#3968):** `git rev-list --count 8c0cd9d..d3d6bc6` = 4. One of those, `419374d docs(03,06): add booking ID on client and expert Booking Summary (BOOK-20, EXP-18)` (REQUIREMENTS.md, ROADMAP.md), is not this plan's work; it was committed on `main` by the user between the RED and GREEN commits. This plan's own commits are the three above.

## TDD

- **RED** (`70a2649`): rewrote the `signOut` rows to the new order and added seven rows for the lane and the bounds. Run against HEAD: 16 tests discovered, 8 failed on their `#expect` for the planned behavior (order rows: `["unregister", "clear", "deleteToken"]` instead of `["unregister", "deleteToken", "clear"]`; lane rows: the retry returned before the in-flight `deleteToken` and `maxConcurrentDeleteTokens` was 2). Classifier: `gsd_run check tdd-red-evidence` on `261110-mmr-red-evidence.json` returned `RED_EVIDENCE_OK` (`target_test_failed`, format `swift-testing`, 16 tests, 8 pass, 8 fail). Semantic assessment: the target row (`retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken`) executed and failed on its assertion, not on a build, load or fixture fault; no unexpected green. Two bound rows (`aHungDeleteTokenStillFinishesLogoutWithinTheCap`, `aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout`) already held at HEAD and are regression guards for the new waits.
- **GREEN** (`1824a11`): first attempt left two lane rows red because `forceSignOut` created its run inside an outer `Task`, so `deleteTokenRun` was still `nil` when it returned and an immediate retry ran first. Fixed by making `enqueueDeleteToken` synchronous (the Task is stored before any await) and calling it directly from `forceSignOut`. 16/16 green.
- **REFACTOR:** none needed.
- Commit prefixes are `test(quick-261110-mmr)` / `fix(quick-261110-mmr)` per the orchestrator's instruction (the plan said `test(261110-mmr)`; the GREEN type is `fix`, not `feat`, because this is a bug fix).

## Files Created/Modified

- `ClickMe2026/Managers/PushTokenCleanup.swift` - Android order in `signOut`; `deleteTokenRun` lane and `enqueueDeleteToken`; `retryIfPending` awaits the in-flight run; type doc rewritten (order, lane, bounded waits, residual past the cap)
- `ClickMe2026/Managers/UserManager.swift` - `isLoggingOut` reset in `clearLocalSession()`, removed from `logout()`; docs for the flag, `logout()`, `retryPushCleanupIfNeeded()`, `registerPushToken`, `fetchAndUploadFCMToken`
- `ClickMe2026Tests/Push/PushTokenCleanupTests.swift` - 16 rows; harness gains `slowDeleteToken(_:taking:throwing:)` with a concurrency counter and `deleteTokenSawSignedIn`
- `ClickMe2026/Views/Screens/Client Mode/Profile/Subviews/ClientProfileHomeListItem.swift` - `isBusy` (spinner, disabled)
- `ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift`, `.../Expert Mode/Profile/ExpertProfileHomeScreen.swift` - Log Out row passes `isBusy: viewModel.isLoggingOut`
- `ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeViewModel.swift`, `.../Expert Mode/Profile/ExpertProfileHomeViewModel.swift` - `var isLoggingOut: Bool { userManager.isLoggingOut }`
- `ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountFarewell.swift` - `isLoggingOut` parameter: Back to Login shows a spinner and is disabled
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift` - passes `UserManager.shared.isLoggingOut` to the farewell
- `.planning/phases/02-shared-ios-plumbing/02-REVIEW-DISPOSITION.md` - WR-02 and IN-02 fixed at `1824a11`, `open: 4`
- `.planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md` - item 14: Status line, step 2 (spinner, up to about 6 s), sub-item (e), Not-a-failure line
- `.planning/phases/02-shared-ios-plumbing/02-UAT.md` - test 10 `expected:` line only

## Decisions Made

- **Android order on logout (user decision 2026-11-10).** The plan kept the 02-12 order (Login right after the DELETE, `deleteToken` in the background) and made the next sign-in wait. The user chose Android's order instead: wait on the Log out tap, so Login is never visible while the cleanup runs. Both changes the plan proposed were still needed in reduced form: the flag reset in `clearLocalSession()` (so a flag can never outlive the session, and so an involuntary logout during the wait releases it) and the lane (because an involuntary logout's background `deleteToken` can still overlap a sign-in; without the lane the awaited retry would start a second `deleteToken` alongside it and could return before the first lands).
- **Dropped from the plan's design:** nothing structural was added only for the "wait on re-login" design, so nothing had to be removed. The plan's truth "a sign-in inside the window waits for the old deleteToken through the awaited retry" now applies only to the involuntary path; for a user logout there is no window. The plan's `retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished` and hang rows are pinned on `forceSignOut` rather than `signOut`, since that is where the overlap still exists.
- **Involuntary logouts: 02-12 behavior kept, Android differs.** Android has one `logout()` path (`SessionEvent.Rejected -> logout()`, `handleAccountSuspended -> logout()`), so on a rejection or suspension it also runs `unregister()` (a DELETE with whatever token is left, then `deleteToken`) and flips `_isLoggedIn` only afterwards. iOS keeps `forceSignOut` as in 02-12: no DELETE (the bearer is dead), session cleared synchronously, `deleteToken` in the background on the lane. Reasons: the suspension handler is a synchronous closure inside `NetworkService`'s interceptor and the refresh-failure sites sit inside the 401 retry path, so delaying the clear would leave the app signed in with a dead bearer for up to 3 s while other requests fail and re-trigger the same path; the immediate clear is a recorded 02-12 user decision (D-17, D-18); and the lane plus the awaited retry already give a re-login after an involuntary logout the same protection. If the user wants exact parity there as well, it is a follow-up decision, not done here.
- **IN-02 presentation.** Android's `ProfileHubLogOutButton` and `LogOutConfirmDialog` only launch `userManager.logout()`; there is no in-progress state anywhere in the Android app (`callGuard` is the only gate). So there was nothing to match: iOS shows a spinner on the row (trailing icon slot) and disables it, reusing the `DeleteAccountBottomButtons` spinner pattern rather than `AsyncSaveButton` (whose Saved state does not fit a one-way action). Candidate Android follow-up.
- **`deleteTokenRun` keeps the last finished run instead of resetting to nil.** Awaiting a finished Task returns at once, and the synchronous enqueue needs no self-reference to clear it. Simpler than the plan's "nil only if still this run" and equally correct.

## Deviations from Plan

### User-directed

**1. Android order on logout, Log out progress state, extra files**
- **Found during:** Task 1 (orchestrator `<user_decision>` block)
- **Issue:** the plan's design kept Login right after the DELETE and made the next sign-in wait; the user chose Android's wait-on-logout order and asked for Log out feedback (IN-02)
- **Fix:** `signOut` reordered; in-progress state on the three Log out sites; `02-REVIEW-DISPOSITION.md` also marks IN-02 fixed; the plan's "GREEN lists only the three files" acceptance criterion is superseded (the GREEN commit lists nine)
- **Files modified:** the seven UI files listed above, plus the two managers and the tests
- **Verification:** 16/16 rows green; Debug build with no new warning; full unit target 244/244
- **Committed in:** `1824a11`

### Auto-fixed Issues

**1. [Rule 1 - Bug] `forceSignOut` enqueued its lane run asynchronously**
- **Found during:** Task 1 GREEN (two lane rows still red)
- **Issue:** the run was created inside an outer `Task`, so `deleteTokenRun` was still `nil` when `forceSignOut` returned; an immediate `retryIfPending` saw no run, read the marker and started its own `deleteToken` first, which in the app would have let the new account register before the old background `deleteToken` ran
- **Fix:** `enqueueDeleteToken` is synchronous and stores the Task before any await; `forceSignOut` calls it directly
- **Files modified:** `ClickMe2026/Managers/PushTokenCleanup.swift`
- **Verification:** `retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken` and `retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished` green
- **Committed in:** `1824a11` (part of the GREEN commit)

---

**Total deviations:** 1 user-directed, 1 auto-fixed (Rule 1).
**Impact on plan:** the user-directed change is the plan's own documented alternative ("Android's exact ordering ... a one-line reorder in `signOut`"), chosen by the user; the auto-fix was necessary for correctness of the lane. No scope creep beyond the IN-02 feedback the user asked for.

## Accepted residual

If Firebase is unreachable for longer than the cap during a logout, the abandoned `deleteToken` is cut off at 3 s (counted as failed, marker kept) but Firebase may still complete it later, possibly after the next account has registered. The `MessagingDelegate` callback for the regenerated token and the foreground re-upload (`refreshPushTokenBinding`) then re-register the new account. Same class as the D-17 window the user accepted in 02-12. Logged in the `PushTokenCleanup` type doc and in UAT item 14's Not-a-failure line.

## Android

- No Android change is needed for WR-02: Android already waits on `unregister()` (DELETE capped at 3000 ms, then `deleteToken`) before flipping `_isLoggedIn`, and iOS now does the same for a user logout.
- Where iOS still differs: (1) involuntary logouts clear at once on iOS and wait on Android (see Decisions); (2) iOS shows a Log out in-progress state, Android shows none. Both are candidate Android follow-ups, not blockers.

## Issues Encountered

- A commit by the user (`419374d`, REQUIREMENTS.md and ROADMAP.md) landed on `main` between the RED and GREEN commits, so the measured ledger count (4) is one higher than this plan's own commits (3). No conflict; this plan did not touch those files.

## Verification

- `xcodebuild test ... -only-testing:ClickMe2026Tests/PushTokenCleanupTests`: `Test run with 16 tests in 1 suite passed` (task verify 1: PASS).
- Task verify 2 (flag reset inside `clearLocalSession()`, absent from `logout()`, `deleteTokenRun` present): PASS.
- BUILD: `xcodebuild build ... Debug` succeeded; the only warning in the whole build is the pre-existing `describe` isolation warning in `UserManager.swift:618`; zero warnings in `PushTokenCleanup.swift` and the seven UI files.
- Full unit target with the smoke suites skipped: `Test run with 244 tests in 28 suites passed` (02-12 baseline 227 in 26).
- Diff scan: no added line prints a token, bearer or refresh token.
- Task 2 `<automated>` grep: PASS; every disposition row other than WR-02 and IN-02 byte-identical to HEAD; `02-UAT.md` changed on the test 10 `expected:` line only.
- Device: UAT item 14 (a) step 2 and (e), PENDING (Phase 2 device UAT).

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- WR-02 and IN-02 closed; `02-REVIEW-DISPOSITION.md` has 4 open findings left (WR-03, WR-04, IN-01, IN-03).
- Device check for the new logout wait and the fast re-login is UAT item 14 (a) step 2 and (e).
- Two Android parity questions for the user: whether Android should get a Log out in-progress state, and whether iOS involuntary logouts should wait on `deleteToken` like Android's single `logout()` path.

---
*Quick task: 261110-mmr*
*Completed: 2026-11-10*

## Self-Check: PASSED

Files present, commits 70a2649 / 1824a11 / d3d6bc6 are ancestors of HEAD, frontmatter `status: complete`.
