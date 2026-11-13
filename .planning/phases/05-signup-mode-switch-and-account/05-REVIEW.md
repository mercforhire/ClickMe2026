---
phase: 05-signup-mode-switch-and-account
reviewed: 2026-11-13T00:00:00Z
depth: standard
files_reviewed: 68
files_reviewed_list:
  - ClickMe2026/ClickMe2026App.swift
  - ClickMe2026/Managers/ModeSwitchGate.swift
  - ClickMe2026/Managers/UserManager.swift
  - ClickMe2026/Model/Enums/ErrorCode.swift
  - ClickMe2026/Utils/AccountDeletionBlocker.swift
  - ClickMe2026/Utils/AccountDeletionCopy.swift
  - ClickMe2026/Utils/ExpertModeGate.swift
  - ClickMe2026/Utils/HomeShellExit.swift
  - ClickMe2026/Utils/LocationFormatter.swift
  - ClickMe2026/Utils/ProfilePhotoCropper.swift
  - ClickMe2026/Utils/SetupDeferralStore.swift
  - ClickMe2026/Utils/SupportContact.swift
  - ClickMe2026/Utils/SuspensionNotice.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation Policies/Subviews/HowToInitiateCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift
  - ClickMe2026/Views/Screens/Expert Mode/Client Profile/Subviews/ClientProfilePersonalInfo.swift
  - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift
  - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift
  - ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift
  - ClickMe2026/Views/Screens/Login Flow/Login/LoginViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsView.swift
  - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/ProfileLanguageField.swift
  - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift
  - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountWarningHeader.swift
  - ClickMe2026/Views/Screens/Settings/Feedback/FeedbackViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Feedback/Subviews/FeedbackDetailsField.swift
  - ClickMe2026/Views/Screens/Settings/Help/HelpView.swift
  - ClickMe2026/Views/Screens/Settings/Mode Switching/ModeSwitchView.swift
  - ClickMe2026/Views/Screens/Settings/Notifications/NotificationSettingsViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Basic Info/Language Selection/LanguageSelectionView.swift
  - ClickMe2026/Views/Screens/Signup Flow/Basic Info/Language Selection/LanguageSelectionViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Basic Info/SignupBasicInfoView.swift
  - ClickMe2026/Views/Screens/Signup Flow/Basic Info/SignupBasicInfoViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Initial/SignupInitialViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift
  - ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoView.swift
  - ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Setup Tags/SignupTagsViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/Signup Review/SignupReviewViewModel.swift
  - ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift
  - ClickMe2026/Views/Screens/Splash/SplashViewModel.swift
  - ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift
  - ClickMe2026Tests/Settings/DeleteAccountViewModelTests.swift
  - ClickMe2026Tests/Settings/FeedbackValidationTests.swift
  - ClickMe2026Tests/Settings/NotificationSettingsAutoSaveTests.swift
  - ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift
  - ClickMe2026Tests/Signup/SelectionOrderTests.swift
  - ClickMe2026Tests/Signup/SignupAccumulatorTests.swift
  - ClickMe2026Tests/Signup/SignupBasicInfoProvinceTests.swift
  - ClickMe2026Tests/Signup/SignupEmailVerifiedSeedTests.swift
  - ClickMe2026Tests/Signup/SignupProfilePhotoSaveTests.swift
  - ClickMe2026Tests/Utils/AccountDeletionBlockerTests.swift
  - ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift
  - ClickMe2026Tests/Utils/ExpertModeGateTests.swift
  - ClickMe2026Tests/Utils/HomeShellExitTests.swift
  - ClickMe2026Tests/Utils/LocationFormatterTests.swift
  - ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift
  - ClickMe2026Tests/Utils/SetupDeferralStoreTests.swift
  - ClickMe2026Tests/Utils/SupportContactTests.swift
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-11-13
**Depth:** standard
**Files Reviewed:** 68
**Status:** issues_found

## Summary

I read the diffs against `607c691` for the non-test app sources and checked the API contracts against the backend (`account.controller.js`, `userProfile.schema.js`, `onboarding.schema.js`, `feedback.schema.js`). I skimmed the test files for reliability problems and did not review them line by line.

The pure decision layer is sound: `ExpertModeGate`, `AccountDeletionBlocker`, `SetupDeferralStore` and the 409 error codes all match the backend. The province-clear contract (`province_state: ""` is accepted), the feedback minimum length, the three blocker codes with the 15-minute window, and the `PATCH /user/profile` languages full-replace are all consistent with the backend. I found no crashes, security holes or data-loss bugs.

The problems are in `UserManager`'s async state handling. Several writes happen after an `await` with no check that the session still exists. The "Not now" deferral can be cleared by a push replay. Two settings and signup flows have races that leave the UI and the server out of step.

## Warnings

### WR-01: `resolvePostAuthLanding` writes state after the session may have ended

**File:** `ClickMe2026/Managers/UserManager.swift:819-846`
**Issue:** The method awaits up to two network lookups, `lookUpSetupCompleted()` and `expertHasTopics()`. It then runs `setupCheckPending = (setupCompleted == nil)` (line 830) and `setMode(mode)` (line 845) with no `isLoggedIn` or generation check.

- `requestModeSwitch` handles this case and returns `.sessionEnded`. This path does not.
- If a forced logout runs during either lookup, `clearLocalSession()` has already removed the `currentMode` key and reset `setupCheckPending`.
- The late `setMode` then re-persists a mode for a signed-out device. The next login finds `hasStoredModePreference == true`, skips the first-boot smart landing, and can land a different account straight in Expert mode.
- It also returns `.home(mode)`, so Splash or Login routes to a home shell while logged out. `ClickMe2026App`'s `isLoggedIn` observer does not fire because the flag is already false.
- The `setupCheckPending` write can likewise leave a stale `true` for the next account.

**Fix:**
```swift
let setupCompleted = await lookUpSetupCompleted()
guard isLoggedIn else { return .home(.client) } // or add a .signedOut case that routes to Login
setupCheckPending = (setupCompleted == nil)
// ...after the topics lookup:
guard isLoggedIn else { return .home(.client) }
setMode(mode)
```
A dedicated `.sessionEnded` landing that the callers map to `.login` is cleaner than returning `.home`.

### WR-02: `refreshExpertProfile` repopulates `expertProfile` after logout

**File:** `ClickMe2026/Managers/UserManager.swift:568-571` (and its callers in `lookUpSetupCompleted`, line 643)
**Issue:** `refreshExpertProfile()` does `expertProfile = response.data` after its `await`.

- `clearLocalSession()` sets `expertProfile = nil` (line 467). A lookup that was in flight at sign-out writes the old account's expert profile back into the singleton.
- `requestModeSwitch` returns `.sessionEnded` and `lookUpSetupCompleted` returns the value, but the stale profile stays.
- `PushAccountSource.live` (`PushRouter.swift:89`) reads `expertProfile?.setupCompleted` and only reloads when it is nil. A stale `true` from account A therefore makes the planner treat account B as "can use Expert mode" and switch to Expert on a push tap.
- The gate re-looks it up afterwards, so impact is limited. It is still cross-account state leakage in a path the phase added.

**Fix:** Capture a session identity before the request and discard the response if it changed. For example, compare `api.bearerToken` or a new `sessionGeneration` counter bumped in `clearLocalSession()`:
```swift
func refreshExpertProfile() async throws {
    let generation = sessionGeneration
    let response = try await api.getExpertProfile()
    guard generation == sessionGeneration else { return }
    expertProfile = response.data
}
```
`lookUpSetupCompleted` would then return nil for an ended session.

### WR-03: A push-initiated Expert switch clears the user's "Not now" deferral

**File:** `ClickMe2026/Managers/UserManager.swift:729`
**Issue:** `requestModeSwitch` calls `setupDeferral.clear()` for every Expert target, including `source: .push`.

- The comment justifies this as "asking for Expert ends a Not now". A push tap is not the user asking for Expert mode.
- Push replays run on every foreground and on call end (`consumePendingPush`). When the planner switches client to Expert, the gate silently drops the deferral.
- When setup is still unfinished, the result is `.setupRequired(opensHub: false)`. The user stays on Client home with the deferral gone. The next cold launch or login then calls `shouldCheckSetupAtLaunch(... deferred: false)` and sends them back to the setup hub, which they already declined.

**Fix:** Clear the deferral only for `source == .user`, or only once the lookup resolves to `.enterExpert`:
```swift
if source == .user { setupDeferral.clear() }
```

### WR-04: A wrong password on `delete-request` triggers a token refresh and a second request

**File:** `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift:144` (interacts with `NetworkService.swift:172-188`)
**Issue:** The backend answers a wrong password with `401` (`account.controller.js:219`). That endpoint is authenticated, so `NetworkService.send` treats any 401 as an expired token.

- It runs `refresher.refresh()`, which rotates the refresh token, and then retries the same `delete-request`.
- Each wrong-password attempt therefore costs two requests against `deleteLimiter` (5 per 15 minutes per IP), so the user gets about 2 real attempts before the 429.
- It also performs a needless token rotation on every wrong password.
- `passwordError` mapping works, but the cost is real. The same pattern applies to change-password.

**Fix:** Add a per-request opt-out in `NetworkService`, or give `requestAccountDeletion` an endpoint flag so a 401 is not retried. A second option is to have the backend return 403 or a coded 401 for a wrong password, which needs an additive backend change that is safe for Android. At minimum, document the 2x limiter cost in the plan.

### WR-05: `loadExistingAvatarIfNeeded` can overwrite a photo the user picked while it downloads

**File:** `ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoViewModel.swift:65-77`
**Issue:** The `profileImage == nil` guard runs before `URLSession.shared.data(from:)`. After the await, line 72 sets `profileImage` unconditionally.

- If the user picks a photo during the download, `usePickedImage` sets `pickedImage` and `profileImage`. The late download then replaces `profileImage` with the old avatar.
- The preview shows the old avatar while Save uploads `pickedImage`. This is the preview/upload mismatch SIGN-05 set out to remove.
- Separately, a downloaded avatar is shown with `zoomScale == 0.5` (the `ProfileAvatarRing` scale of 1.5x), but `canZoom` is false and Save never re-crops it. The ring misrepresents the stored image, and the disabled slider cannot reset it.

**Fix:**
```swift
let (data, _) = try await URLSession.shared.data(from: url)
guard pickedImage == nil, profileImage == nil, let uiImage = UIImage(data: data) else { return }
withAnimation { zoomScale = 0 } // show the stored avatar as saved
profileImage = Image(uiImage: uiImage)
```

### WR-06: Flipping a notification toggle back during an in-flight save cancels it and skips the resave

**File:** `ClickMe2026/Views/Screens/Settings/Notifications/NotificationSettingsViewModel.swift:123-148`
**Issue:** `scheduleAutoSave()` calls `autoSaveTask?.cancel()` and then returns early when `currentSnapshot() == lastAppliedSnapshot` (line 126).

- `autoSaveTask` is the task that is awaiting `performAutoSave()` (the PATCH). The user flips a toggle on and then off while the request is in flight.
- Cancelling the task cancels the URLSession call. If the server has already applied the intermediate state, the early return means nothing re-sends the final state. The UI then shows the original value and the server holds the flipped one.
- If the cancel lands first, the user instead sees a "cancelled" error alert through `autoSaveError = error.userMessage`.
- `ClientProfileSettingsViewModel.scheduleAutoSave` checks the snapshot before cancelling, so it does not cancel an in-flight save this way. The two view models behave differently.

**Fix:** Track an `isSaveInFlight` flag. Do not cancel an in-flight save, and compare against the snapshot the in-flight save sends, so a flip-back schedules a corrective save:
```swift
func scheduleAutoSave() {
    if currentSnapshot() == lastAppliedSnapshot && !isAutoSaving { autoSaveTask?.cancel(); return }
    // otherwise (re)schedule; performAutoSave re-reads the snapshot after the in-flight one completes
}
```

## Info

### IN-01: The checklist and the publish gate disagree on an empty `avatarUrl`

**File:** `ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift:142` vs `:98`
**Issue:** `checklist.profilePhoto` is `avatarUrl != nil`, but `missingForPublish` treats `""` as missing (`avatarUrl?.isEmpty ?? true`). Both `hydrate` and `uploadAvatar` avoid storing `""` today, so this is latent. If `""` ever gets in, the Overview shows the photo as done while Publish is refused with "Add profile picture".
**Fix:** Use one predicate for both, for example `private var hasPhoto: Bool { !(avatarUrl?.isEmpty ?? true) }`.

### IN-02: Tapping the already-active Expert mode triggers a lookup and can open the setup hub

**File:** `ClickMe2026/Views/Screens/Settings/Mode Switching/ModeSwitchView.swift:66-79`, `ClickMe2026/Managers/UserManager.swift:717`
**Issue:** `ModeSwitchView` always calls `onConfirm(mode)`, even for the active mode, and `dismiss()` runs in the same tick. In Expert mode, tapping Expert again does a `GET /expert/profile`, clears the deferral, and can raise the hub. The new `.disabled(isSwitchingMode)` is also ineffective, because the screen is dismissed before it can be seen. There is no feedback during a slow lookup.
**Fix:** Skip the request when `mode == userManager.currentMode`. Optionally delay `dismiss()` until the gate returns.

### IN-03: `DeleteAccountView` reads `UserManager.shared` directly instead of the view model's injected manager

**File:** `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift:95,102`
**Issue:** `DeleteAccountViewModel` takes an injectable `userManager`, but the blocker alert reads `UserManager.shared.currentMode`. This breaks the injection seam, so previews and tests cannot drive the mode-dependent blocker copy.
**Fix:** Expose `var currentMode: AppMode { userManager.currentMode }` on the view model and use it.

### IN-04: `RememberedLoginEmailTests` mutates the real Keychain through the singleton

**File:** `ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift:21-26`
**Issue:** The suite calls `UserManager.shared.forgetLastLoginEmail()` in `init()`, and every test restores state with `defer`. Running it against a simulator that holds a real remembered email wipes it. The suite is `.serialized`, so it is not flaky, but it depends on global Keychain state. A test that fails before its `defer` leaves state behind.
**Fix:** If `UserManager` gains an injectable `Valet` or a test identifier, point the suite at an isolated store. Otherwise leave as is and note the limitation.

---

_Reviewed: 2026-11-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
