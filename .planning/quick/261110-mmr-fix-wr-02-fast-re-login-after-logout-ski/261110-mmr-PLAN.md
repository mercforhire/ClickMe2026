---
phase: quick-261110-mmr
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ClickMe2026/Managers/PushTokenCleanup.swift
  - ClickMe2026/Managers/UserManager.swift
  - ClickMe2026Tests/Push/PushTokenCleanupTests.swift
  - .planning/phases/02-shared-ios-plumbing/02-REVIEW-DISPOSITION.md
  - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md
  - .planning/phases/02-shared-ios-plumbing/02-UAT.md
autonomous: true
requirements:
  - QUICK-261110-mmr
  - PUSH-04

estimate:
  tokens: 28000
  raw_tokens: 28000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "A login or signup that lands inside the ~3 s window after a user logout registers the new account's push token in that same session: fetchAndUploadFCMToken and registerPushToken are no longer skipped once the old session has been cleared"
    - "During the unregister step of a user logout (the only time the leaving account's bearer is still live) no push token is registered or stored, so the old account can never re-bind this device (02-12 prohibition kept)"
    - "A login or signup that lands while a logout's deleteToken is still running waits for it (bounded by the 3 s cap) before apply(...) registers a token, so the old logout's deleteToken cannot finish after the new registration and invalidate the new account's token"
    - "Two Firebase deleteToken calls never run at the same time: the retry awaits the in-flight cleanup and runs only if a retry is still owed once it has finished"
    - "A hanging deleteToken never holds the next sign-in for longer than the cleanup timeout(s): every wait on the cleanup lane is bounded"
    - "02-12 guarantees unchanged: the server DELETE runs before the bearer is cleared, the deleteToken-only retry marker is set before the clear and removed only on success, retryPushCleanupIfNeeded is still awaited by login and signup after the API call and before apply(...), and the four involuntary forceLogout paths still clear synchronously with no DELETE (D-06, D-17, D-18)"
    - "WR-02 is recorded as fixed in 02-REVIEW-DISPOSITION.md; UAT item 14 and 02-UAT.md test 10 describe the fast re-login as an expected pass, not as a case that reproduces the bug"
  artifacts:
    - path: "ClickMe2026/Managers/PushTokenCleanup.swift"
      provides: "One serialized deleteToken lane shared by signOut, forceSignOut and retryIfPending; retryIfPending awaits the in-flight run before deciding whether a retry is owed"
      contains: "deleteTokenRun"
    - path: "ClickMe2026/Managers/UserManager.swift"
      provides: "isLoggingOut scoped to the leaving session: set in logout(), cleared in clearLocalSession()"
      contains: "private func clearLocalSession()"
    - path: "ClickMe2026Tests/Push/PushTokenCleanupTests.swift"
      provides: "Rows for the fast re-login wait, no overlapping deleteToken, the failed-in-flight retry, the involuntary background run and the bounded hang"
      contains: "@Suite(\"Push token cleanup\")"
  key_links:
    - from: "ClickMe2026/Managers/UserManager.swift (login, signup)"
      to: "PushTokenCleanup.retryIfPending(deleteToken:) via retryPushCleanupIfNeeded().value"
      via: "retryIfPending awaits deleteTokenRun before the isPending check, so the awaited retry doubles as the wait on the old logout's deleteToken"
      pattern: "await retryPushCleanupIfNeeded\\(\\)\\.value"
    - from: "ClickMe2026/Managers/UserManager.swift (clearLocalSession)"
      to: "UserManager.isLoggingOut"
      via: "the flag is reset where the bearer is dropped, so it never outlives the session it protects"
      pattern: "isLoggingOut = false"
    - from: "PushTokenCleanup.signOut / forceSignOut / retryIfPending"
      to: "PushTokenCleanup.deleteTokenRun"
      via: "every deleteToken step goes through the one lane helper that awaits the previous run first"
      pattern: "deleteTokenRun"
---

<objective>
Fix code-review finding WR-02 (02-REVIEW.md): after a user logout the shell routes to Login as soon as `clearLocalSession()` runs, but `UserManager.isLoggingOut` stays `true` until `PushTokenCleanup.signOut` has also finished its bounded Firebase `deleteToken` step (up to ~3 s). A sign-in inside that window calls `fetchAndUploadFCMToken()` exactly once from `apply(loginData:)` / `apply(signupData:)`, that call returns early on the flag, and the new account receives no pushes until the next foreground activation. Two related hazards from the same window: `login()` awaits `retryPushCleanupIfNeeded()`, whose marker is already set during the deleteToken step, so it starts a second `deleteToken` in parallel with the first; and if the new account registers its token before the old logout's `deleteToken` lands, that late delete invalidates the token the new account just bound.

Purpose: PUSH-04's account-switch scenario on a shared device is exactly the fast re-login case. The fix must keep every 02-12 guarantee (DELETE before the bearer is cleared, the deleteToken-only retry marker, the awaited retry in login/signup, the involuntary `forceLogout` paths) while making a new sign-in always register, and never for the old account.

Output: `isLoggingOut` scoped to the leaving session (cleared in `clearLocalSession()`), a serialized deleteToken lane in `PushTokenCleanup` that the new sign-in awaits through the already-awaited retry, unit tests with fakes and no Firebase, WR-02 marked fixed, UAT wording updated.

Approach (Claude's discretion, two coordinated changes):
1. **Scope the guard to the leaving account.** Reset `isLoggingOut` inside `clearLocalSession()` instead of after `signOut` returns. Once the bearer is gone, `hasStoredToken` already keeps the old account out of `registerPushToken`; the flag's only remaining effect was to block the next sign-in, which is the bug. The flag still covers the unregister step, the only time the old bearer is live.
2. **Serialize deleteToken on one lane and make the new sign-in wait on it.** `PushTokenCleanup` tracks the deleteToken step in flight (`deleteTokenRun`); `signOut`, `forceSignOut` and `retryIfPending` all run their deleteToken through one helper that awaits the previous run first, and `retryIfPending` awaits the in-flight run before reading `isPending`. Because `login` / `signup` already await `retryPushCleanupIfNeeded().value` before `apply(...)`, a sign-in inside the window now waits for the old deleteToken to finish or time out, then registers against a fresh token. No two deleteTokens overlap. Every wait is bounded by the existing 3 s cap, so a hanging Firebase costs the sign-in at most one or two timeouts, never a hang.

Residual (document, not fixed): if Firebase is unreachable for longer than the cap, the abandoned deleteToken may still complete after the new account registered; the `MessagingDelegate` callback for the regenerated token (no longer skipped by the flag) and the foreground re-upload re-register the new account. Same class as the D-17 window the user accepted.

Android reference (read-only, `ClickMe_Android/.../managers/UserManager.kt` L200-219 and `FcmPushTokenRegistrar.kt`): Android's `logout()` is a `suspend fun` that awaits `pushTokenRegistrar.unregister()` in full (DELETE capped at 3000 ms, then `deleteToken`) before it clears the tokens and flips `_isLoggedIn`, so its Login screen cannot appear while the cleanup runs and a fast re-login cannot overlap it; `register` and `unregister` share one `Mutex`, and the skip after an unregister is keyed to the leaving session's access token, so a new login (new token) always registers. iOS keeps the 02-12 ordering (route to Login after the DELETE; the credential-free deleteToken runs in the background so the user is not held for it) and reaches the same outcome: change 1 is the access-token-keyed skip, change 2 is the Mutex. The one visible difference remains where the wait sits: Android holds the Log out tap for the deleteToken, iOS holds the next sign-in for the remainder of it, and only when that sign-in lands inside the window. No Android change is needed. If the user prefers Android's exact ordering (Login only after deleteToken), it is a one-line reorder in `signOut` (clear the session after deleteToken), but it reverts a 02-12 assumption and doubles the IN-02 wait; not done here.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/02-shared-ios-plumbing/02-REVIEW.md
@.planning/phases/02-shared-ios-plumbing/02-12-SUMMARY.md

<interfaces>
From ClickMe2026/Managers/PushTokenCleanup.swift (HEAD, 188 lines): `@MainActor final class PushTokenCleanup`; `static let pendingKey = "pendingPushCleanup"`; `init(defaults: UserDefaults = .standard, timeout: Duration = .seconds(3))`; `var isPending: Bool`; `signOut(unregister:deleteToken:clearSession:) async` (L81-93: bounded unregister, set marker, `clearSession()`, bounded deleteToken, remove marker only when both succeeded); `forceSignOut(deleteToken:clearSession:)` (L109-121: set marker, `clearSession()`, background Task runs bounded deleteToken and removes the marker on success); `retryIfPending(deleteToken:) async` (L133-138: `guard isPending`, bounded deleteToken, remove marker on success); `private func runBounded(_:) async -> Bool` (L147-165, worker-versus-timer `Race`, returns false at the timeout even if the work ignores cancellation). Closures are `@escaping @MainActor () async throws -> Void`.

From ClickMe2026/Managers/UserManager.swift (HEAD, 781 lines): `private let pushCleanup = PushTokenCleanup()` (L84); `private(set) var isLoggingOut = false` (L90, doc L85-89); `private var pushCleanupRetry: Task<Void, Never>?` (L96); `login` awaits `retryPushCleanupIfNeeded().value` then `apply(loginData:)` (L180-188); `signup` the same (L215-227); `apply(loginData:)` / `apply(signupData:)` call `fetchAndUploadFCMToken()` once (L206, L236); `tryAutoLogin` starts the retry at a signed-out launch (L266); `logout()` (L340-359): guard on the flag, set it, Task awaits `pushCleanup.signOut(...)`, then resets the flag at L357; `forceLogout()` (L369-374); `retryPushCleanupIfNeeded()` (L381-393); `clearLocalSession()` (L401-420); `registerPushToken(_:)` guard on the flag at L662-667 before the UserDefaults write; `fetchAndUploadFCMToken()` guard at L740-745 (doc L735-738 says the guard covers "the ~3 s cleanup").

From ClickMe2026/ClickMe2026AppDelegate.swift: `messaging(_:didReceiveRegistrationToken:)` (L128-134) calls `UserManager.shared.registerPushToken`; `applicationDidBecomeActive` (L115-117) calls `refreshPushTokenBinding()`.

From ClickMe2026Tests/Push/PushTokenCleanupTests.swift (HEAD, 252 lines, 10 `@Test` rows): `@MainActor @Suite("Push token cleanup") struct PushTokenCleanupTests`; private `Harness` with a per-row `UserDefaults(suiteName:)`, `events: [String]`, `signedIn`, fakes `unregister()`, `deleteToken()`, `clearSession()`, `tearDown()`; `waitUntil(timeout:_:)` poller (10 ms, default 1 s); `StepFailed` error.

Swift notes for the lane: `Task` is `Hashable`, so `deleteTokenRun == run` compiles. A `Task { @MainActor in ... }` created inside a main-actor method runs its body on the main actor; synchronous statements before the first `await` in `signOut` run with no interleaving.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Scope isLoggingOut to the leaving session and serialize deleteToken on one lane the next sign-in awaits</name>
  <files>ClickMe2026/Managers/PushTokenCleanup.swift, ClickMe2026/Managers/UserManager.swift, ClickMe2026Tests/Push/PushTokenCleanupTests.swift</files>
  <read_first>
    - ClickMe2026/Managers/PushTokenCleanup.swift (whole file)
    - ClickMe2026/Managers/UserManager.swift (L81-96, L175-237, L328-420, L651-773)
    - ClickMe2026Tests/Push/PushTokenCleanupTests.swift (whole file)
    - .planning/phases/02-shared-ios-plumbing/02-REVIEW.md (WR-02, L154-160)
  </read_first>
  <behavior>
    New rows in PushTokenCleanupTests, each on a fresh Harness (fakes append to `events`; a slow fake sleeps then appends; a counting fake tracks `concurrentDeleteTokens` and `maxConcurrentDeleteTokens`):
    - fastReLoginWaitsForTheRunningDeleteToken: start `signOut` in a Task with a deleteToken that sleeps 300 ms then appends "deleteToken"; `waitUntil` events contains "clear"; then `await retryIfPending(deleteToken: appends "retryDeleteToken")`, append "retryReturned", await the signOut Task. Expect events == ["unregister", "clear", "deleteToken", "retryReturned"] (the retry returned only after the in-flight deleteToken finished and started no second one) and isPending == false.
    - retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished: same shape, but the in-flight deleteToken sleeps 200 ms, appends "deleteToken" and throws; the retry's deleteToken appends "retryDeleteToken" and succeeds; both fakes go through the concurrency counter. Expect events == ["unregister", "clear", "deleteToken", "retryDeleteToken", "retryReturned"], maxConcurrentDeleteTokens == 1, isPending == false.
    - retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken: `forceSignOut` with a deleteToken that sleeps 200 ms then appends "deleteToken"; immediately `await retryIfPending(deleteToken: appends "retryDeleteToken")`, append "retryReturned". Expect events == ["clear", "deleteToken", "retryReturned"] and isPending == false.
    - aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout: Harness(timeout: .milliseconds(200)); `signOut` in a Task with a deleteToken that sleeps 10 s (never appends); after "clear", time `await retryIfPending(deleteToken: appends "retryDeleteToken")`. Expect it returns in under 2 s, events == ["unregister", "clear", "retryDeleteToken"], isPending == false (the retry ran because the hung run was counted as failed, and it succeeded).
    - The ten existing rows keep passing unchanged (signOut order, unregister throws, unregister timeout, deleteToken throws, marker is only a Bool, both forceSignOut rows, three retry rows).
  </behavior>
  <action>
    RED first: add the four rows above to `ClickMe2026Tests/Push/PushTokenCleanupTests.swift` (extend `Harness` with the sleeping and counting fakes; keep the per-row defaults suite and `tearDown`). Run the suite: the three serialization rows must fail on their assertions (at HEAD `retryIfPending` does not wait, so "retryReturned" lands before "deleteToken" and a second deleteToken runs). Commit `test(261110-mmr): pin that a sign-in waits for the running push cleanup (WR-02)`.

    GREEN, `ClickMe2026/Managers/PushTokenCleanup.swift`: add `private var deleteTokenRun: Task<Bool, Never>?`, the deleteToken step currently in flight from any of the three entry points. Add a private lane helper, for example `runDeleteTokenOnLane(_ work: @escaping @MainActor () async throws -> Void, clearMarkerOnSuccess: Bool) async -> Bool`: capture the previous `deleteTokenRun`, create a main-actor Task that awaits the previous run's value (ignoring it), then runs `runBounded(work)`, and, when it succeeded and `clearMarkerOnSuccess` is true, removes `pendingKey` inside that same Task before it returns; store the Task in `deleteTokenRun` synchronously (before the first await), await its value, set `deleteTokenRun` back to nil only if it is still this run, and return the result. The marker must be cleared inside the lane Task, not by the caller afterwards, so anyone awaiting the run observes the final marker state and cannot start a redundant retry. Rewire: `signOut` passes `clearMarkerOnSuccess: unregistered` and drops its own marker removal; `forceSignOut`'s background Task calls the helper with `clearMarkerOnSuccess: true`; `retryIfPending` first awaits `deleteTokenRun?.value`, then `guard isPending`, then calls the helper with `clearMarkerOnSuccess: true`. Keep `runBounded`, `Race`, `pendingKey`, `isPending`, `init` and every signature unchanged. Update the type doc: one deleteToken at a time; the retry doubles as the wait a sign-in inside the window performs; every wait is bounded by `timeout`; the residual when Firebase is unreachable past the cap (the abandoned call may land after the next registration; the regenerated-token callback and the foreground re-upload re-register the new account) and that it is the same class as the D-17 window.

    `ClickMe2026/Managers/UserManager.swift`: in `clearLocalSession()` assign false to `isLoggingOut` (with a comment: the leaving account has no bearer from here, so `hasStoredToken` keeps it out of `registerPushToken`; a flag that outlived the clear blocked the next sign-in, WR-02). In `logout()` delete the flag reset that follows the `signOut` await, so the Task body is only the `await pushCleanup.signOut(...)` call; do not mention the reset in a comment inside `logout()`. Rewrite the `isLoggingOut` doc (L85-89): true from the start of a user logout until the session is cleared, that is for the unregister step while the bearer is still live; the next sign-in is never blocked by it; a second `logout()` during that step is a no-op, and one after the clear only re-runs the idempotent clear and queues another bounded deleteToken on the lane. Update the `logout()` doc, the `retryPushCleanupIfNeeded()` doc (the awaited retry also waits for the deleteToken of a logout still in flight, so login and signup inside the window register against a fresh token and never race it), and the `fetchAndUploadFCMToken()` / `registerPushToken` docs that currently say the guard covers "the ~3 s cleanup" (it covers the unregister step). No new logging; the existing DEBUG `push:` lines stay and print no token. `login`, `signup`, `tryAutoLogin`, `forceLogout`, the four `forceLogout()` call sites and the `registerPushToken` / `fetchAndUploadFCMToken` guards are otherwise unchanged (D-06, D-17, D-18).

    Run the suite green, then the BUILD check in `<verification>`. Commit `fix(261110-mmr): let a fast re-login register its push token and wait for the old cleanup (WR-02, PUSH-04)` with the three files.
  </action>
  <verify>
    <automated>set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'id=E8F9FD72-750B-4888-8F47-91AE12B58F65' -only-testing:ClickMe2026Tests/PushTokenCleanupTests 2>&1 | tee /tmp/261110-mmr-t1.log | tail -30 && grep -Eq 'Test run with (1[4-9]|[2-9][0-9]) tests? in [0-9]+ suites? passed' /tmp/261110-mmr-t1.log</automated>
    <fails_when>non-zero exit, or the log has no "Test run with N tests in M suite(s) passed" line with N of at least 14 (baseline at HEAD: 10 rows)</fails_when>
    <automated>test "$(sed -n '/private func clearLocalSession()/,/^    }$/p' ClickMe2026/Managers/UserManager.swift | grep -c 'isLoggingOut = false')" -eq 1 && test "$(sed -n '/func logout()/,/^    }$/p' ClickMe2026/Managers/UserManager.swift | grep -c 'isLoggingOut = false')" -eq 0 && test "$(grep -c 'deleteTokenRun' ClickMe2026/Managers/PushTokenCleanup.swift)" -ge 3</automated>
    <fails_when>non-zero exit: the flag reset is not inside clearLocalSession (baseline at HEAD: 0 there), or still sits inside logout() (baseline at HEAD: 1 there), or PushTokenCleanup has no lane (baseline at HEAD: 0 occurrences of deleteTokenRun)</fails_when>
  </verify>
  <acceptance_criteria>
    - PushTokenCleanupTests passes every row, old and new (at least 14).
    - The RED commit exists before the GREEN commit and the suite failed on assertions, not on a build error.
    - `git show --stat --format= <green sha>` for the GREEN commit lists only the three files in `<files>`.
    - No added line in UserManager.swift or PushTokenCleanup.swift prints a token, bearer or refresh token (read the diff).
    - The BUILD check in `<verification>` succeeds with no new warning on UserManager.swift or PushTokenCleanup.swift.
  </acceptance_criteria>
  <done>A sign-in inside the post-logout window registers its push token after the old cleanup has finished or timed out; the old account is still never registered once its logout started; no two deleteTokens overlap; every wait is bounded.</done>
</task>

<task type="auto">
  <name>Task 2: Record WR-02 as fixed and update the PUSH-04 UAT wording</name>
  <files>.planning/phases/02-shared-ios-plumbing/02-REVIEW-DISPOSITION.md, .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md, .planning/phases/02-shared-ios-plumbing/02-UAT.md</files>
  <read_first>
    - .planning/phases/02-shared-ios-plumbing/02-REVIEW-DISPOSITION.md (whole file; the WR-01 row is the format to copy)
    - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md (L197-223, item 14)
    - .planning/phases/02-shared-ios-plumbing/02-UAT.md (L57-59, test 10)
  </read_first>
  <action>
    Use `Edit` (scoped replacements), never a whole-file `Write`, on all three files.

    `02-REVIEW-DISPOSITION.md`: in the frontmatter set the WR-02 block's `disposition` to `fixed` and `open: 6` to `open: 5`; in the table replace the WR-02 row's `open | -` cells with `fixed` and a Source cell in the WR-01 row's shape: the Task 1 GREEN commit hash, then "isLoggingOut now resets in clearLocalSession; PushTokenCleanup runs every deleteToken on one serialized lane and retryIfPending awaits it before the isPending check; PushTokenCleanupTests rows fastReLoginWaitsForTheRunningDeleteToken, retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished, retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken, aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout green (quick 261110-mmr, 2026-11-10)". Change no other row and leave `recorded:` alone.

    `02-DEVICE-UAT-CHECKLIST.md`, item 14: append to the Status line "; (e) fast re-login added by quick 261110-mmr (WR-02 fix)". After sub-item (d) and before the "**Not a failure:**" line add sub-item "**(e) Fast re-login (WR-02):**" with steps: sign in as A; log out from Profile and, as soon as the Login screen appears, sign in as B (within about 3 seconds); expected: the sign-in may take up to about 3 seconds longer than usual while the old cleanup's deleteToken finishes; once Home appears, trigger a push to B from the other device without backgrounding the app first: B receives it; a push to A does not arrive. Extend the "**Not a failure:**" line with: a sign-in inside that window taking up to about 3 seconds longer; and, if Firebase was unreachable for longer than that during the logout, B's pushes starting only after the next token callback or foreground (same class as the D-17 window; record it in Result if seen).

    `02-UAT.md`, test 10: keep the heading; replace the `expected:` line so it reads that no push for A arrives after logout, that B receives B's pushes even when the re-login is immediate and without backgrounding the app first, that this sign-in may take up to about 3 s longer while the old cleanup's deleteToken finishes, and that WR-02 was fixed by quick 261110-mmr so B getting nothing until the next foreground activation is now a regression. Drop the old trailing parenthetical that called the case a reproduction to be fixed. Change nothing else in the file (the `status`, `updated` and other tests belong to the UAT tool).

    Commit `docs(261110-mmr): mark WR-02 fixed and update the PUSH-04 fast re-login UAT wording` with the three files.
  </action>
  <verify>
    <automated>D=.planning/phases/02-shared-ios-plumbing; test "$(grep -c '^| WR-02 | warning | fixed |' $D/02-REVIEW-DISPOSITION.md)" -eq 1 && grep -q '^open: 5$' $D/02-REVIEW-DISPOSITION.md && test "$(grep -c '(e) Fast re-login' $D/02-DEVICE-UAT-CHECKLIST.md)" -eq 1 && test "$(grep -c 'should be fixed' $D/02-UAT.md)" -eq 0 && grep -q '261110-mmr' $D/02-UAT.md</automated>
    <fails_when>non-zero exit: the WR-02 row is not fixed (baseline at HEAD: 0 matching rows, `open: 6`), the checklist has no (e) sub-item (baseline at HEAD: 0), or 02-UAT.md test 10 still carries the reproduction wording (baseline at HEAD: 1 match of the old phrase, 0 of the quick id)</fails_when>
  </verify>
  <acceptance_criteria>
    - `git show --stat --format= <task-2 sha>` lists exactly the three planning files; `git show --format= <task-2 sha> -- .planning/phases/02-shared-ios-plumbing/02-UAT.md` touches only the test 10 `expected:` line.
    - The WR-01 row and every other disposition row are byte-identical to HEAD.
  </acceptance_criteria>
  <done>The review record shows WR-02 fixed with its evidence, and both UAT documents describe the fast re-login as a pass condition with the one visible side effect (a slightly longer sign-in inside the window).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| app to Firebase Messaging | deleteToken invalidates this install's FCM token; a late one can invalidate the next account's token |
| app to POST /notifications/tokens | binds this device's token to the signed-in account |
| shared device between accounts | A's logout and B's sign-in overlap by up to ~3 s |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-quick-261110-mmr-01 | Denial of service | new account's FCM token invalidated by the old logout's late deleteToken | medium | mitigate | One serialized lane in PushTokenCleanup; retryIfPending awaits the in-flight run, and login/signup already await the retry before apply(...); pinned by fastReLoginWaitsForTheRunningDeleteToken and the forceSignOut row. Residual past the 3 s cap (Firebase unreachable) accepted: the regenerated-token callback and foreground re-upload re-register, same class as D-17 |
| T-quick-261110-mmr-02 | Information disclosure | old account re-binds this device during logout | high | mitigate | isLoggingOut still guards the unregister step (bearer live) and the UserDefaults write; after clearLocalSession the bearer is nil so hasStoredToken keeps the old account out; 02-12 prohibition unchanged |
| T-quick-261110-mmr-03 | Denial of service | sign-in held by a hanging Firebase deleteToken | low | mitigate | Every lane wait goes through runBounded (3 s cap); pinned by aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout |
| T-quick-261110-mmr-04 | Information disclosure | tokens in logs | low | mitigate | No new logging; existing DEBUG push: lines print no token, bearer or refresh token (diff review) |
| T-quick-261110-mmr-SC | Tampering | npm/pip/cargo installs | low | accept | No packages are installed or upgraded in this plan |
</threat_model>

<verification>
- BUILD: `set -o pipefail; xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'id=E8F9FD72-750B-4888-8F47-91AE12B58F65' 2>&1 | tee /tmp/261110-mmr-build.log | tail -5 && grep -q 'BUILD SUCCEEDED' /tmp/261110-mmr-build.log && test "$(grep -E 'UserManager\.swift|PushTokenCleanup\.swift' /tmp/261110-mmr-build.log | grep 'warning:' | grep -vc "'describe'")" -eq 0` exits 0 (the only allowed warning on UserManager.swift is the pre-existing `describe` isolation warning).
- Full unit target, smoke suites skipped (they hit live production and must never run): `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'id=E8F9FD72-750B-4888-8F47-91AE12B58F65' -only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/SignupSmokeTests -skip-testing:ClickMe2026Tests/AuthSmokeTests 2>&1 | tee /tmp/261110-mmr-full.log | tail -30 && grep -q 'TEST SUCCEEDED' /tmp/261110-mmr-full.log` exits 0 (02-12 baseline: 227 tests in 26 suites; expect at least 231 tests).
- Device (deferred to the Phase 2 UAT, item 14 (e); not run here): log out A, sign in as B within about 3 seconds, trigger a push to B without backgrounding: B receives it; A's pushes do not arrive.
</verification>

<success_criteria>
- WR-02 fixed: a sign-in inside the post-logout window registers its token in that session; the old account is never registered once its logout started; deleteToken never overlaps; every wait is bounded by the 3 s cap; all 02-12 PUSH-04 guarantees intact.
- PushTokenCleanupTests at least 14 rows green; full unit target green; clean build with no new warning.
- WR-02 recorded as fixed; UAT item 14 (e) and 02-UAT.md test 10 describe the fast re-login as a pass condition.
</success_criteria>

<output>
Create `.planning/quick/261110-mmr-fix-wr-02-fast-re-login-after-logout-ski/261110-mmr-SUMMARY.md` when done. Record: the two coordinated changes and why both are needed (the flag race alone and the lane alone each leave a window); the accepted residual when Firebase is unreachable past the cap; that Android needs no change and where iOS still differs from Android (the wait sits on the next sign-in, not on the Log out tap); that the device check is UAT item 14 (e), pending.
</output>

## Plan deviation (user-directed: Android order)

Executed 2026-11-10 under the user decision "Match Android (wait on logout)", which overrides this plan where they differ:

- `PushTokenCleanup.signOut` now runs the server DELETE (bearer live, 3 s cap), sets the retry marker, runs Firebase `deleteToken` (3 s cap), and only then calls `clearSession()`; the shell routes to Login after the whole cleanup, as Android's `UserManager.logout()` does. The plan's order (clear after the DELETE, deleteToken in the background) and the truth "a sign-in inside the window waits for the old deleteToken through the awaited retry" no longer apply to a user logout, because Login cannot appear while it runs. The lane and the awaited retry are kept for the one overlap left, an involuntary logout's background `deleteToken`.
- `isLoggingOut` is still reset in `clearLocalSession()` (now the last step), never after `signOut`, so the next sign-in is never blocked.
- Added, outside the plan's `<files>`: the Log out in-progress state (code review IN-02) on the client and expert Profile Log Out row (`ClientProfileHomeListItem.isBusy`) and the delete-account farewell's Back to Login button, driven by `UserManager.isLoggingOut`. IN-02 is marked fixed in `02-REVIEW-DISPOSITION.md`. Android has no such state (its button only launches the coroutine), so this is an iOS-only addition and a candidate Android follow-up.
- Involuntary logouts keep the 02-12 behavior (no DELETE, session cleared synchronously, `deleteToken` in the background on the lane). Android runs its single `logout()` path for them too and therefore waits on `deleteToken` before flipping `isLoggedIn`; iOS does not match that part (see the SUMMARY for the reasoning).
- Test rows differ from `<behavior>`: the `signOut` rows pin the new order, the "fast re-login waits" row is replaced by `retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken`, `retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished` and `aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout` on the `forceSignOut` path, and `userAndInvoluntaryDeleteTokensNeverOverlap`, `aHungDeleteTokenStillFinishesLogoutWithinTheCap` and `aCompletedLogoutLeavesNothingForTheNextSignInToWaitOn` are new. UAT wording describes the Log Out spinner (up to about 6 s) instead of a longer sign-in.
- Commit prefixes follow the orchestrator's `test(quick-261110-mmr)` / `fix(quick-261110-mmr)` form rather than the plan's `test(261110-mmr)`.
