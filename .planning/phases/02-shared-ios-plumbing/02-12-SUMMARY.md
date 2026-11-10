---
phase: 02-shared-ios-plumbing
plan: 12
subsystem: push
tags: [push, fcm, firebase-messaging, logout, session, swift-testing, uat-checklist]

requires:
  - phase: 02-10
    provides: PushRouter.shared.pending (queued push tap cleared on logout)
  - phase: 02-11
    provides: ChatPresence.shared.clearSessionData() (visible-chat marker cleared on logout)
provides:
  - PushTokenCleanup: ordered, 3 s-bounded logout push cleanup (DELETE with the live bearer, clear session, Firebase deleteToken) with a deleteToken-only retry marker (D-17, D-18)
  - UserManager.logout() rebuilt on PushTokenCleanup.signOut; forceLogout() for the four involuntary paths; retryPushCleanupIfNeeded() at signed-out launch and awaited by login/signup; isLoggingOut guard on both register paths
  - 02-DEVICE-UAT-CHECKLIST.md: every deferred Phase 2 device check in one list with the latest wording
  - Q3 recorded as settled route only (D-01) in REQUIREMENTS.md and ROADMAP.md
affects: [phase-02-device-uat, verify-work-02, phase-05-sign-in-flows, android-parity]

plan_head_before: 1add41b34fbd9a8eb4bcb1a44dd04479d58b7ab9
plan_head_after: 28af9548359cf1bcd5749be37bce28e82f9e1ca7

# Actuals (#2632): chars/4 over the realized diff 1add41b..28af954 (code + docs, 8 files)
actuals:
  tokens: 15500
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Session cleanup as an injectable, main-actor class with closure steps (unregister / deleteToken / clearSession) so order, timeouts and failures are unit-tested with fakes and no Firebase"
    - "Worker-versus-timer race (`runBounded`) returns false at the timeout even when the work ignores cancellation (completion-handler bridges)"
    - "A retry owed across launches is a plain Bool in UserDefaults, never a credential (D-18)"

key-files:
  created:
    - ClickMe2026/Managers/PushTokenCleanup.swift
    - ClickMe2026Tests/Push/PushTokenCleanupTests.swift
    - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md
    - .planning/phases/02-shared-ios-plumbing/02-12-tdd-red-evidence-t2.json
  modified:
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/Managers/ChatPresence.swift
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/WINDOWS.md

key-decisions:
  - "PUSH-04 retry is Firebase deleteToken only, at launch and login only; the server DELETE is never retried because the old bearer is gone, and the residual window after an offline logout is accepted (D-17, D-18)"
  - "Involuntary logouts (suspension, rejected stored token, refresh 401, no refresh token) skip the DELETE the server would reject: session cleared synchronously, deleteToken in the background"
  - "login/signup await the owed retry before apply(...) so it can never delete the token the new account is about to register"
  - "The RED commit for Task 2 carries a compile-only seam (empty forceSignOut / retryIfPending) so the suite fails on assertions, not on a build error, matching the 02-15 precedent"
  - "WINDOWS.md phase-02 entries are annotated as carried into the checklist and stay open; none waived or marked fixed because none has run on device"

patterns-established:
  - "Pattern: device checks deferred at tracer gates are collected by the phase's last plan into a single checklist that cites the WINDOWS.md entry id per item"

requirements-completed: [PUSH-04, BOOK-15]

coverage:
  - id: D1
    description: "A user logout sends DELETE /notifications/tokens/:device_id while the bearer is still set, then clears the session, then calls Firebase deleteToken; each network step is cut off at 3 s and a failure never stops logout"
    requirement: PUSH-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#signOutOrder, unregisterThrows, unregisterTimesOut, deleteTokenThrows, markerIsOnlyABool"
        status: pass
    human_judgment: true
    rationale: "Order and timeouts are pinned with fakes; whether FCM actually stops delivering to the logged-out device needs real APNs/FCM on a device (checklist item 14a, PENDING)"
  - id: D2
    description: "Involuntary logouts clear the session synchronously without the DELETE and run deleteToken in the background; an unfinished cleanup leaves a deleteToken-only marker retried at the next signed-out launch and before the next login/signup registers a token"
    requirement: PUSH-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#forceSignOutClearsFirstThenDeletesToken, forceSignOutDeleteTokenThrows, retryWithMarkerSucceeds, retryWithoutMarkerIsNoOp, retryWithMarkerThrows"
        status: pass
      - kind: other
        ref: "grep gates: forceLogout() 5 (>=5), isLoggingOut 6 (>=4) in UserManager.swift"
        status: pass
    human_judgment: true
    rationale: "The airplane-mode logout and the involuntary paths are device checks (checklist item 14c/14d, PENDING)"
  - id: D3
    description: "No credential survives logout for the retry; registerPushToken and fetchAndUploadFCMToken return early while a logout runs; a queued push tap is cleared"
    requirement: PUSH-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift#markerIsOnlyABool"
        status: pass
      - kind: other
        ref: "diff review: the two added DEBUG lines print no token, bearer or refresh token; PushRouter.shared.pending = nil count 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "02-DEVICE-UAT-CHECKLIST.md lists every Phase 2 device check with the latest wording, CALL-05 recorded as passed, PUSH-04 pending"
    verification:
      - kind: other
        ref: "Task 3 <automated>: all 20 IDs present; 15 numbered items, 15 Result lines"
        status: pass
    human_judgment: false
  - id: D5
    description: "REQUIREMENTS.md BOOK-15 and ROADMAP.md Q3 record Q3 as settled route only (D-01)"
    requirement: BOOK-15
    verification:
      - kind: other
        ref: "grep 'BOOK-15.*D-01' REQUIREMENTS.md and '| Q3 .*D-01' ROADMAP.md"
        status: pass
    human_judgment: true
    rationale: "BOOK-15's route itself (payment_actions push opens the booking) is a device check owned by 02-10 (checklist item 13, PENDING)"

duration: 23min
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 12: PUSH-04 logout push cleanup, Phase 2 device checklist, Q3 record Summary

**Logout now sends the device-token DELETE with the live bearer before clearing the session, then kills the FCM token, with a credential-free deleteToken-only retry at launch and login; plus the one checklist for every deferred Phase 2 device check and the Q3 route-only record.**

## Performance

- **Duration:** about 23 min of execution (Task 1 by the previous executor from 2026-11-10T17:22:38Z to the tracer gate; this continuation 17:30Z to 17:45Z), plus the gate pause
- **Started:** 2026-11-10T17:22:38Z
- **Completed:** 2026-11-10T17:45:00Z
- **Tasks:** 3 (Task 2 as RED then GREEN)
- **Files modified:** 8 in task commits (4 created, 4 modified) plus `.planning/WINDOWS.md` in the plan metadata commit

## Accomplishments

- `PushTokenCleanup` runs the logout cleanup in order (unregister with the bearer still set, marker, clear session, Firebase `deleteToken`), each network step bounded at 3 s by a worker-versus-timer race that returns at the timeout even if the work ignores cancellation. The marker is a plain Bool under `pendingPushCleanup`; no bearer, refresh token or other credential is kept (D-18).
- `UserManager.logout()` (signature unchanged for its three external callers) is a no-op while a logout runs, sets `isLoggingOut`, and awaits `pushCleanup.signOut`. The old fire-and-forget unregister and its helper are gone. `clearLocalSession()` also removes the cached push token, clears `PushRouter.shared.pending` and `ChatPresence.shared.clearSessionData()`, and is idempotent.
- The four involuntary paths (`handleAccountSuspended`, the auth-rejection branch of `tryAutoLogin`, both 401 sites in `performRefreshCycle`) go through `forceLogout()`: no DELETE the server would reject, session cleared before returning, `deleteToken` in the background.
- `retryPushCleanupIfNeeded()` starts the deleteToken-only retry at a signed-out launch and is awaited by `login` and `signup` after the API call and before `apply(...)`, so the retry cannot delete the token the new account registers (D-17). `registerPushToken` and `fetchAndUploadFCMToken` return early while `isLoggingOut`, with DEBUG `push:` logs that print no token.
- `02-DEVICE-UAT-CHECKLIST.md`: 15 items covering every deferred check from WINDOWS.md #13–#20 and the 02-01…02-15 SUMMARYs, with the latest wording (see Decisions). CALL-05 recorded as passed on device 2026-11-09; PUSH-04 PENDING with the Task 2 retry and involuntary paths added.
- REQUIREMENTS.md BOOK-15 and ROADMAP.md Q3 row and Phase 2 note record Q3 as settled route only (D-01); nothing else in either file changed.

## Task Commits

1. **Task 1: Tracer, a user logout unregisters the device before the bearer is cleared** - `48edd28` (fix) — previous executor; tracer gate answered "approve and defer"
2. **Task 2 RED: pin involuntary logout cleanup and the credential-free retry** - `f481106` (test)
3. **Task 2 GREEN: involuntary logouts and a credential-free push cleanup retry** - `21bc12b` (fix)
4. **Task 3: Phase 2 device checklist and the Q3 route-only record** - `28af954` (docs)

**Plan metadata:** the `docs(02-12): complete ...` commit that follows this file.

## TDD Gate Compliance (Task 2, `tdd="true"`)

- **RED (`f481106`):** five new rows in `PushTokenCleanupTests` (forceSignOut success and failure; retryIfPending with marker + success, without marker, with marker + failure). The commit carries a compile-only seam, as 02-15 did: `forceSignOut(deleteToken:clearSession:)` and `retryIfPending(deleteToken:)` exist with empty bodies so the suite compiles and fails on its assertions. Run: exit 65, 10 tests in 1 suite, 4 failed (8 issues), 6 passed (the five Task 1 rows and the no-marker guard). Evidence: `02-12-tdd-red-evidence-t2.json`; `gsd_run check tdd-red-evidence` verdict **`RED_EVIDENCE_OK`** (`target_test_failed`, format `swift-testing`).
- **Semantic assessment:** the target ("an involuntary sign-out clears the session before returning, sends no unregister, then deletes the token in the background") executed and failed on its planned assertion for the intended reason: `events.first` was nil where "clear" was expected and `events` was `[]` where `["clear", "deleteToken"]` was expected. The sibling forceSignOut-throws row and both marker-set retry rows failed the same way. No build, load or fixture failure.
- **GREEN (`21bc12b`):** real bodies plus the UserManager wiring; `PushTokenCleanupTests` + `PushRoutePlannerTests`: "Test run with 24 tests in 2 suites passed". Commit type is `fix`, as the plan specified, not `feat`.
- **REFACTOR:** none needed; no commit.

## Files Created/Modified

- `ClickMe2026/Managers/PushTokenCleanup.swift` - `signOut`, `forceSignOut`, `retryIfPending`, `isPending`, `pendingKey`, bounded `runBounded` race; docs on the order, the no-credential rule and the accepted residual window
- `ClickMe2026/Managers/UserManager.swift` - `logout()` on `PushTokenCleanup`, `isLoggingOut`, `clearLocalSession()`, `forceLogout()`, `pushCleanupRetry` / `retryPushCleanupIfNeeded()`, early returns in `registerPushToken` and `fetchAndUploadFCMToken`; retry awaited in `login` / `signup`, started at the signed-out launch
- `ClickMe2026/Managers/ChatPresence.swift` - `clearSessionData()` called from `clearLocalSession()` (Task 1)
- `ClickMe2026Tests/Push/PushTokenCleanupTests.swift` - 10 rows against a per-row `UserDefaults` suite, with fakes and a `waitUntil` poller for the background deleteToken
- `.planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md` - the Phase 2 device checklist
- `.planning/phases/02-shared-ios-plumbing/02-12-tdd-red-evidence-t2.json` - RED evidence record
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` - Q3 route-only record (D-01)
- `.planning/WINDOWS.md` - entry #21 (PUSH-04 unrun-verify) appended; #13–#20 annotated as carried into the checklist

## Decisions Made

- **Checklist wording follows the latest SUMMARY/WINDOWS.md text where it conflicts with this plan's Task 3 list:** BOOK-14 shows all days with dimmed, untappable slots past now + 6 days and a fixed note (not hidden days); CALL-02 / D-12 shows Join visible but disabled on a `pending_reschedule` booking (not hidden) on the Dashboard strip, Explore strip, My Bookings and expert Upcoming; BOOK-10 uses CAD wording and the Client Profile history shows real net earnings `CA$x.xx` for gated statuses and `—` otherwise (02-15 supersedes the plan's "— until EXP-14" item); PUSH-01 includes the booking_id-only fallback; CHAT-09 includes its edge cases. CALL-05 is recorded as passed on device (2026-11-09).
- **UI-SPEC drift is noted, not fixed:** the checklist preamble says 02-UI-SPEC.md still describes hidden days (W1-9, W1-10, §4, E1/A1) and hidden Join (D-12 rows) and must be revised after the UAT.
- **EXP-17 stays Pending:** commits `e43ef50` / `73e729e` (CAD/USD topic currency picker, iOS half, another session) were left untouched; the Android half is outstanding, so the checklist only notes it.
- **WINDOWS.md carry-over:** the CLI has only `status`/`append`/`waive`/`fixed`, so each phase-02 entry's description gained "Carried into 02-DEVICE-UAT-CHECKLIST.md item N by 02-12 (2026-11-10); stays open until run on device", in both the table and the JSON block; `windows status` parses (open 14, total 21). Nothing was waived, fixed or deleted.
- **Involuntary logouts do not set `isLoggingOut`:** the session is cleared synchronously, so the existing `hasStoredToken` guards already stop any re-registration; the flag is for the ~3 s window a user logout keeps the bearer alive.

## Plan-vs-Android conflicts

None found for this plan. Android's `FcmPushTokenRegistrar` already uses a 3000 ms DELETE timeout followed by `deleteToken`, and skips a register after an unregister in the same session, which is what `isLoggingOut` does here; the plan records that Android needs no change. The checklist items that changed wording during the phase (BOOK-14, CALL-02, BOOK-10 history) all changed *toward* Android parity, per the user's preference.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Compile-only seam in the RED commit**
- **Found during:** Task 2 RED
- **Issue:** Swift cannot compile a test that calls `forceSignOut` / `retryIfPending` before they exist; a build failure is `INVALID_RED` (`build_failure`), not RED.
- **Fix:** the RED commit adds the two signatures with empty bodies so the rows fail on assertions; the classifier returned `RED_EVIDENCE_OK`. Same shape as 02-15's RED.
- **Files modified:** `PushTokenCleanup.swift`
- **Committed in:** `f481106`

**2. [Rule 2 - Missing critical] `registerPushToken` returns before storing the token while logging out**
- **Found during:** Task 2
- **Issue:** the plan says "return early while isLoggingOut"; storing the token first would let a token that arrives mid-logout survive `clearLocalSession()` in UserDefaults.
- **Fix:** the `isLoggingOut` guard runs before the `UserDefaults` write.
- **Files modified:** `UserManager.swift`
- **Committed in:** `21bc12b`

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical). **Impact:** none on scope; both serve the plan's own truths.

## Issues Encountered

None. The `appintentsmetadataprocessor` warnings in the logs are tooling noise unrelated to the touched files; the only warning in `UserManager.swift` is the pre-existing `describe` isolation warning from the baseline.

## Verification Results

- Task 2: `PushTokenCleanupTests` + `PushRoutePlannerTests`: "Test run with 24 tests in 2 suites passed" (`/tmp/02-12-t2.log`). Grep gates: `forceLogout()` 5, `isLoggingOut` 6. Added lines print no token, bearer or refresh token.
- Task 3: all 20 IDs present in the checklist; 15 numbered items with 15 `Result:` lines; `BOOK-15.*D-01` and `| Q3 .*D-01` match; `git diff --stat` shows 1 changed line in REQUIREMENTS.md and 2 in ROADMAP.md.
- BUILD: `xcodebuild build` → `BUILD SUCCEEDED` (`/tmp/02-12-build.log`); warning comparison for `UserManager.swift` and `PushTokenCleanup.swift` against `/tmp/02-12-warn-before.txt` with `comm -13` prints nothing.
- Phase gate: one `xcodebuild test` over the 18 named suites → "Test run with 194 tests in 20 suites passed", `TEST SUCCEEDED` (`/tmp/02-12-gate.log`).
- Full unit suite (smoke suites skipped, never calling production): "Test run with 227 tests in 26 suites passed", `TEST SUCCEEDED` (`/tmp/02-12-full.log`).
- Commits measured from the plan ledger `1add41b..28af954`: 4.

## Pending device checks (UAT) — PENDING, not passed

**PUSH-04 has NOT been run on a device** (user "approve and defer" at the Task 1 tracer gate, 2026-11-10). Recorded as WINDOWS.md #21 and as `02-DEVICE-UAT-CHECKLIST.md` item 14:

- (a) Sign in as A, log out from Profile, then from another device send A a chat message. Expected: nothing arrives on the logged-out device.
- (b) Sign in as B on the same device: B gets B's pushes, A's do not arrive.
- (c) Airplane-mode logout, relaunch online, sign in as B: B gets B's pushes and A's do not arrive. **Accepted residual window (D-17, D-18):** between the offline logout and that relaunch/login a push to A may arrive; the retry is `deleteToken` only, runs at launch and login only, never re-sends the server DELETE and keeps no credential.
- (d) Involuntary logout, only if a safe production trigger exists: the app returns to Login at once and A's pushes stop.

Every other deferred Phase 2 check is in the checklist (items 1, 3–13, 15 PENDING; item 2 CALL-05 PASSED 2026-11-09; items 5 and 8 optional).

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-02-23/24/25/26 mitigations are in place: DELETE awaited with the live bearer, no credential kept (only a Bool marker), `isLoggingOut` blocks re-registration, retry awaited before the new login registers, DEBUG logs print no token.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 2 plans are all summarized; `/gsd-verify-work 02` can run. The device UAT (`02-DEVICE-UAT-CHECKLIST.md`) is the remaining Phase 2 work and gates PUSH-04, CALL-01, CALL-02, BOOK-10, BOOK-14, BOOK-18, PUSH-01/02/03, BOOK-15 and CHAT-09 from Pending to verified.
- 02-UI-SPEC.md needs the revision noted above (WINDOWS.md #14) before or during the UAT.
- No Android or backend change was made or is needed for this plan.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*

## Self-Check: PASSED

- Created files exist: PushTokenCleanup.swift, PushTokenCleanupTests.swift, 02-DEVICE-UAT-CHECKLIST.md, 02-12-tdd-red-evidence-t2.json.
- Commits 48edd28, f481106, 21bc12b, 28af954 are ancestors of HEAD; `git rev-list --count 1add41b..HEAD` is 4 before this docs commit.
- Task 2 and Task 3 acceptance greps, the BUILD warning comparison, the phase gate (194 tests / 20 suites) and the full suite (227 tests / 26 suites) all pass.
