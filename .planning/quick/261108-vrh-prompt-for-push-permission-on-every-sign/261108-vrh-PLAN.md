---
phase: quick-261108-vrh
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ClickMe2026/Managers/UserManager.swift
autonomous: true
requirements:
  - QUICK-261108-vrh

estimate:
  tokens: 20000
  raw_tokens: 20000
  tasks: 1
  confidence: low

must_haves:
  truths:
    - "While a session token is stored, every cold launch checks notification permission and shows the OS prompt when the status is .notDetermined, including when /me fails for a transient reason"
    - "A launch that ends logged out never prompts: no stored token, a rejected token (the logout() branch), or a 403 ACCOUNT_SUSPENDED"
    - "Users who already denied permission are not asked again"
    - "Authorized users still get registerForRemoteNotifications() plus fetchAndUploadFCMToken() on cold launch"
    - "After a grant on this path, the FCM token reaches POST /notifications/tokens through the existing delegate chain"
  artifacts:
    - path: "ClickMe2026/Managers/UserManager.swift"
      provides: "tryAutoLogin runs the prompting permission check on every launch that stays signed in"
      contains: "requestPushPermissionIfNeeded()"
  key_links:
    - from: "ClickMe2026/Views/Screens/Splash/SplashViewModel.swift"
      to: "ClickMe2026/Managers/UserManager.swift"
      via: "SplashViewModel.start() awaits tryAutoLogin() on every cold launch; it is the only caller"
      pattern: "userManager\\.tryAutoLogin\\(\\)"
    - from: "ClickMe2026/Managers/UserManager.swift"
      to: "ClickMe2026/ClickMe2026AppDelegate.swift"
      via: "A grant calls registerForRemoteNotifications(); didRegister sets Messaging.apnsToken; the MessagingDelegate callback calls registerPushToken"
      pattern: "Messaging\\.messaging\\(\\)\\.apnsToken = deviceToken"
---

<objective>
Make every signed-in cold launch run the prompting push permission check, so a user who deleted and reinstalled the app is asked for permission and gets pushes again.

Purpose: iOS resets notification permission when an app is deleted, but the Valet keychain session survives. After a reinstall the app auto-logs in through a silent path that never prompts, so the user never gets pushes. Confirmed on a real iPhone on TestFlight build 6.

Output: one code commit changing `ClickMe2026/Managers/UserManager.swift` only. This is a single-path, single-file fix, so the one task is the whole slice and there is no separate tracer.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@ClickMe2026/Managers/UserManager.swift

Findings from reading the code at HEAD. Rely on these rather than re-deriving them.

**The launch hook is right.** `SplashViewModel.start()` (`ClickMe2026/Views/Screens/Splash/SplashViewModel.swift:56`) is the only caller of `tryAutoLogin`, and the app route always starts at `.splash` (`ClickMe2026/ClickMe2026App.swift:15`). It runs after the 3-second splash delay, so the app is in the foreground. `tryAutoLogin` is also the only place that knows the auth outcome, so there is no better single hook.

**Suspended launches reach the transient path.** `NetworkService.send` (`ClickMe2026/Network/NetworkService.swift:164-170`) awaits `suspensionHandler`, which calls `logout()`, and then rethrows. `isAuthRejection` deliberately returns false for `ACCOUNT_SUSPENDED`, so that launch falls into the transient path with the token already cleared. A prompt placed there with no check would prompt a logged-out user, which is why the task's guard is required.

**Use `hasStoredToken`, not `isLoggedIn`, for that guard.** On the transient path `me` and `authUser` are both nil, so `isLoggedIn` is false for a user who is still signed in. Guarding on it would skip exactly the branch this fix must cover.

**The FCM chain after a grant has no gap, so no extra code is needed.** Traced at HEAD:
1. A grant in `requestPushPermissionIfNeeded` calls `registerForRemoteNotifications()` on main.
2. `didRegisterForRemoteNotificationsWithDeviceToken` sets `Messaging.messaging().apnsToken` (`ClickMe2026/ClickMe2026AppDelegate.swift:82`).
3. Firebase 12.17.0 fetches a token when it has none cached (`FIRMessagingTokenManager setAPNSToken:withUserInfo:`, the fresh-install case), which fires `messaging(_:didReceiveRegistrationToken:)` (`ClickMe2026/ClickMe2026AppDelegate.swift:128`).
4. `registerPushToken` passes its `hasStoredToken` guard, because `UserManager.init` restored the bearer from the keychain at launch, and POSTs to `/notifications/tokens`.

The manual-login test on the device exercised this same chain and a push arrived. If that POST fails, `applicationDidBecomeActive` retries it through `refreshPushTokenBinding` on the next foreground. `fetchAndUploadFCMToken()` is expected to no-op right after the prompt fires, because `apnsToken` is still nil at that point.

**An offline grant recovers on its own.** If APNs registration fails during a transient launch, the next cold launch takes the `.authorized` branch and registers again.

**No new unit tests.** No test references `UserManager` today, and `UserManager` has a private init, the real `ClickMeAPI.shared`, the real keychain and `UNUserNotificationCenter`. A seam around `tryAutoLogin` would be far larger than this fix. Extracting the status switch into a pure function would only test logic this fix does not change. This behavior needs the device check named in the task, and the SUMMARY must say so plainly.

**Build command.** Use `ClickMe.xcodeproj`. The `PROJECT` default in `scripts/run-smoke-tests.sh` (`ClickMe2026.xcodeproj`) does not exist in this repo. Do not fix the script here.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Run the prompting permission check on every signed-in cold launch</name>
  <files>ClickMe2026/Managers/UserManager.swift</files>
  <action>
All edits are in `ClickMe2026/Managers/UserManager.swift`. Line numbers refer to HEAD.

**Step 1: record the warning baseline before editing anything.** Run `touch ClickMe2026/Managers/UserManager.swift`, then `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 2>&1 | tee "${TMPDIR:-/tmp}/261108-vrh-before.log" | tail -n 1`. Use a 600000 ms timeout, or run it in the background if package resolution makes it slower. Confirm the log contains `BUILD SUCCEEDED`; if it fails at HEAD, stop and report that rather than editing. Then save the normalized warnings: `grep -E 'UserManager\.swift:[0-9]+:[0-9]+: warning:' "${TMPDIR:-/tmp}/261108-vrh-before.log" | sed -E 's/:[0-9]+:[0-9]+:/:/' | sort -u > "${TMPDIR:-/tmp}/261108-vrh-before.txt"`. Only this file changes and its internal API does not, so new warnings can only appear in this file.

**Step 2: restructure `tryAutoLogin` (lines 231-258).** Keep the opening `guard hasStoredToken else { return false }`. The `do` block now holds only `try await refreshMe()`. The `catch` keeps the `isAuthRejection` check, with its `logout()` and `return false`, and keeps the existing transient comment, but the transient path no longer returns from inside the `catch`; it falls through. After the `do`/`catch`, add `if hasStoredToken { ... }` containing `requestPushPermissionIfNeeded()` followed by `fetchAndUploadFCMToken()`, in that order, and then `return true`. Use `hasStoredToken` rather than `isLoggedIn`, for the reason given in the context section.

Do not change the suspended-launch return value: it stays `true`, as it is today. The guard only stops the push work. Do not change `SplashViewModel`, `ClickMe2026AppDelegate`, `applicationDidBecomeActive` or `refreshPushTokenBinding`. Do not add the prompt to any foreground path, because dismissing an OS prompt fires didBecomeActive again. Do not change the `switch` inside `requestPushPermissionIfNeeded`: its `.notDetermined`, `.authorized`/`.provisional`/`.ephemeral` and `.denied` branches already do what this fix needs.

**Step 3: delete the dead helper.** Its only caller was the line removed in Step 2. Remove the private silent re-register function and its doc comment (lines 531-545, the doc comment beginning "Same as above but silent"). Leave no mention of it in any comment.

**Step 4: update the comments that are now wrong.**
- `tryAutoLogin` doc comment: keep the opening sentence ("Attempts to restore a session...") and the existing return-value text. Append a short paragraph saying that every launch that stays signed in, including the transient-failure case, also runs the push permission check, because iOS resets notification permission on delete-and-reinstall while the keychain session survives. Add that a launch ending logged out never prompts.
- Comment above the new `if hasStoredToken` block: replace the old "silently refresh" comment (lines 235-238) with why the check is here and why it is guarded. A 403 `ACCOUNT_SUSPENDED` reaches this point after the suspension handler has already logged out, and `isLoggedIn` cannot be used because it is false on the transient path. Keep the existing `apply(loginData:)` reasoning (lines 240-242) above `fetchAndUploadFCMToken()`.
- `requestPushPermissionIfNeeded` doc comment (lines 471-475): keep the opening sentence ("Fires the OS permission prompt..."). Replace "safe to call from every login / signup path" so it also names `tryAutoLogin`, and state that denied users are not asked again. Add one line saying it must stay on the cold-launch path and out of `applicationDidBecomeActive`, because dismissing the prompt fires didBecomeActive again.

Match the surrounding comment style and explain why rather than restating the code. Add no new logging.

**Step 5: commit.** After the verify block passes, stage only `ClickMe2026/Managers/UserManager.swift` and make one commit. Do not stage `.DS_Store` files, `.planning/config.json`, `.planning/milestone.lock` or `.planning/state.json`. Do not push and do not change the build number.
  </action>
  <verify>
    <automated>
set -e
F=ClickMe2026/Managers/UserManager.swift
L="${TMPDIR:-/tmp}/261108-vrh"
# baseline at HEAD: 2
test "$(grep -v '^ *//' "$F" | grep -c 'reRegisterPushIfAuthorized')" = 0
# baseline at HEAD: "hasStoredToken fetchAndUploadFCMToken() logout() "
test "$(awk '/func tryAutoLogin/,/^    }$/' "$F" | grep -v '^ *//' | grep -oE 'logout\(\)|hasStoredToken|requestPushPermissionIfNeeded\(\)|fetchAndUploadFCMToken\(\)' | tr '\n' ' ')" = "hasStoredToken logout() hasStoredToken requestPushPermissionIfNeeded() fetchAndUploadFCMToken() "
# baseline at HEAD: 0
test "$(awk '/Attempts to restore a session/,/func tryAutoLogin/' "$F" | grep -ci 'push')" -ge 1
# baseline at HEAD: 0
test "$(grep -B10 'func requestPushPermissionIfNeeded' "$F" | grep -c 'tryAutoLogin')" -ge 1
touch "$F"
xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 2>&1 | tee "$L-after.log" | tail -n 1
grep -q 'BUILD SUCCEEDED' "$L-after.log"
grep -E 'UserManager\.swift:[0-9]+:[0-9]+: warning:' "$L-after.log" | sed -E 's/:[0-9]+:[0-9]+:/:/' | sort -u > "$L-after.txt"
test -z "$(comm -13 "$L-before.txt" "$L-after.txt")"
    </automated>
    <human-check>
      <test>Install a build containing this commit on a real iPhone and sign in. Delete the app, reinstall it and open it. The session survives in the keychain, so it should go to home without a login screen. Tap Allow on the prompt, then send a test push to that account. Then force-quit and reopen the app.</test>
      <expected>The OS notification prompt appears during or just after the splash, with no login. After Allow, the test push arrives. Reopening the app does not prompt again.</expected>
      <why_human>The OS prompt and APNs/FCM delivery need a real device and cannot be driven from unit tests. This is the user's check, not an automated gate on this plan.</why_human>
    </human-check>
  </verify>
  <done>
- `tryAutoLogin` runs `requestPushPermissionIfNeeded()` then `fetchAndUploadFCMToken()` on the `/me` success path and the transient path, and on neither the rejected path nor the suspended path.
- The silent helper is gone and the three comments in Step 4 describe the new behavior.
- `xcodebuild` reports `BUILD SUCCEEDED` with no warning in `UserManager.swift` that was not in the baseline.
- One commit exists that touches only `ClickMe2026/Managers/UserManager.swift`.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| client to API (`POST /notifications/tokens`) | The device's FCM token is bound to whichever account's bearer sends it |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-261108-vrh-01 | Spoofing | `UserManager.tryAutoLogin` push step | low | mitigate | The `hasStoredToken` guard skips push work on a launch that ended logged out, including `ACCOUNT_SUSPENDED`, and `registerPushToken` keeps its own `hasStoredToken` guard, so no token is sent without a bearer |
| T-261108-vrh-02 | Information Disclosure | Push diagnostics logging | low | accept | This fix adds no logging; existing token logs stay behind `#if DEBUG` |
| T-261108-vrh-SC | Tampering | SwiftPM dependencies | low | accept | No dependency changes and no package installs; `Package.resolved` is untouched |
</threat_model>

<verification>
- The automated block in Task 1 passes.
- `git show --name-only --format= <code commit>` prints only `ClickMe2026/Managers/UserManager.swift`.
- `git status --short` still shows the unrelated dirty files unstaged.
- The device check in Task 1 is listed as outstanding for the user. It does not gate this plan.
</verification>

<success_criteria>
| Requirement | How it is met |
|-------------|---------------|
| Signed-in cold launch prompts on `.notDetermined` | `tryAutoLogin` calls `requestPushPermissionIfNeeded()` after the auth outcome is known |
| Transient-failure launches included | The transient path falls through to the same step |
| `.denied` users not asked again | Existing `switch` branch, unchanged |
| Logged-out users not prompted | The opening guard returns before any push work |
| Rejected-auth launches not prompted | `logout()` and `return false` happen before the push step |
| Suspended launches not prompted | The `hasStoredToken` guard after the `do`/`catch` |
| Authorized users keep today's behavior | Existing `.authorized` branch, then `fetchAndUploadFCMToken()` |
| No prompt on foreground paths | `ClickMe2026/ClickMe2026AppDelegate.swift` and `refreshPushTokenBinding` unchanged |
| Dead code and wrong comments handled | Steps 3 and 4 |
| FCM token reaches the backend after a grant | Chain traced in the context section; no gap, no code needed |
</success_criteria>

<output>
Create `.planning/quick/261108-vrh-prompt-for-push-permission-on-every-sign/261108-vrh-SUMMARY.md` when done. It must state:
- No unit tests were added and why; this behavior needs the device check.
- The FCM chain was traced and needed no code.
- The device check is outstanding and is the user's to run.
- Two existing issues found and left alone:
  - On a suspended cold launch `tryAutoLogin` still returns `true`, so `SplashViewModel` routes to the dashboard with the token cleared, and nothing outside `UserManager` reads `wasSuspended`.
  - The `PROJECT` default in `scripts/run-smoke-tests.sh` names a project that does not exist.
</output>
