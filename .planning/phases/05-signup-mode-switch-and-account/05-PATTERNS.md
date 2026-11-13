# Phase 5: Signup, Mode Switch and Account - Pattern Map

**Mapped:** 2026-11-13
**Files analyzed:** 30 (new and modified, iOS repo only)
**Analogs found:** 28 / 30
**Tracked-source gate:** every analog path below was confirmed with `git ls-files` (no `.gsd` mirrors involved).

All paths are relative to `/Users/LeonChen/Documents/ClickMe2026/`. Line numbers were read this session.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `ClickMe2026/Utils/ExpertModeGate.swift` (new) | utility (pure decision) | transform | `ClickMe2026/Utils/AutoLoginOutcome.swift` | exact |
| `ClickMe2026/Utils/SetupDeferralStore.swift` (new) | utility (UserDefaults store) | CRUD | `UserManager.swift` currentMode persistence (lines 129-130, 519-522) | role-match |
| `ClickMe2026/Managers/UserManager.swift` (mod) | manager | request-response | itself, `setMode` / `clearLocalSession` / `refreshExpertProfile` | exact |
| `ClickMe2026/Managers/ModeSwitchGate.swift` (new, optional wrapper) | manager | request-response | `ClickMe2026/Managers/PushRouter.swift` (`PushRoutePlanner` plus account source) | role-match |
| `ClickMe2026/ClickMe2026App.swift` (mod) | app shell | event-driven | itself, `onChange` observers (lines 24-35) | exact |
| `ClickMe2026/Views/Screens/Splash/SplashViewModel.swift` (mod) | view model | request-response | itself (lines 70-126) | exact |
| `LoginView.swift`, `HomeClientView.swift`, `HomeExpertView.swift`, `ClientProfileHomeScreen.swift`, `ExpertProfileHomeScreen.swift` (mod, `setMode` sites) | view | event-driven | `ClickMe2026/Utils/HomeShellExit.swift` style (pure plan, thin view call) | role-match |
| `ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift` (mod) | model/state | transform | itself (lines 85-205) | exact |
| `SignupBasicInfoViewModel.swift` (mod, clearProvince) | view model | CRUD | itself (`provinceState: trimmedProvince.isEmpty ? nil : ...`, line ~123) | exact |
| `Signup Flow/Setup Tags/SignupTagsViewModel.swift` (mod) | view model | CRUD | itself (lines 96-120) | exact |
| `Signup Flow/Basic Info/Language Selection/LanguageSelectionViewModel.swift` (mod) | view model | CRUD | `SignupTagsViewModel.swift` (same Set-plus-catalog shape) | exact |
| `Signup Flow/Profile Photo/Subviews/ProfileAvatarRing.swift` + `SignupProfilePhotoViewModel.swift` (mod) | component + VM | file-I/O | themselves | exact |
| `ClickMe2026/Utils/ProfilePhotoCropper.swift` (new) | utility | transform / file-I/O | `ClickMe2026/Utils/AutoLoginOutcome.swift` (pure `nonisolated enum` shape) | partial |
| `ClickMe2026/Utils/LocationFormatter.swift` (new) | utility | transform | `ClickMe2026/Utils/BookingShortID.swift` (small pure util) | role-match |
| `ClientProfileSettingsViewModel.swift` / `ExpertProfileSettingsViewModel.swift` (mod, SET-01, D-07) | view model | CRUD (auto-save) | `ClientProfileSettingsViewModel.swift` lines 236-291 | exact |
| `Settings/Client Profile Settings/Subviews/LanguageEditorSheet.swift` (delete) | component | n/a | replaced by `LanguageSelectionView` | n/a |
| `Settings/Help/HelpView.swift` (mod, SET-02) | view | request-response | `ClickMe2026/Utils/SuspensionNotice.swift` (shared support-address constant) | role-match |
| `Settings/Notifications/NotificationSettingsViewModel.swift` (mod, SET-04) | view model | CRUD (auto-save) | `ClientProfileSettingsViewModel.swift` `lastAppliedSnapshot` pattern | exact |
| `Settings/Feedback/FeedbackViewModel.swift` (mod, SET-05) | view model | request-response | itself (lines 105-125) | exact |
| `Settings/Delete account/DeleteAccountViewModel.swift` (mod) | view model | request-response | itself (lines 83-150) | exact |
| `Settings/Delete account/DeleteAccountView.swift`, `Subviews/DeleteAccountWarningHeader.swift` (mod) | view | request-response | themselves | exact |
| `Settings/Delete account/Subviews/DeleteAccountPauseCard.swift` (delete) | component | n/a | n/a | n/a |
| `ClickMe2026/Utils/AccountDeletionBlocker.swift` (new) | utility | transform | `ClickMe2026/Utils/BookingErrorMapper.swift` | role-match |
| `ClickMe2026/Utils/AccountDeletionCopy.swift` (new) | utility (strings) | transform | `ClickMe2026/Utils/SuspensionNotice.swift` | exact |
| `ClickMe2026/Model/Enums/ErrorCode.swift` (mod) | model | n/a | itself (lines 41-42 entries) | exact |
| `Client Mode/Cancellation/ClientCancellationView.swift` (mod, D-12) | view | event-driven | itself (lines 201-232) | exact |
| `Client Mode/Cancellation Policies/*` (mod copy) | view | n/a | themselves | exact |
| `Views/Screens/Call/Ready/` (delete folder) | view | n/a | n/a | n/a |
| `LoginViewModel.swift` (mod, T8) | view model | request-response | itself | exact |
| `ClickMe2026Tests/Utils/ExpertModeGateTests.swift` and other pure-type suites (new) | test | transform | `ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift` | exact |
| `ClickMe2026Tests/Settings/*`, `Signup/*`, `Auth/RememberedLoginEmailTests.swift` (new) | test | request-response | `ClickMe2026Tests/Support/APITestFactory.swift` plus `PushRoutePlannerTests.swift` | role-match |

## Pattern Assignments

### `ClickMe2026/Utils/ExpertModeGate.swift` (utility, transform)

**Analog:** `ClickMe2026/Utils/AutoLoginOutcome.swift`

Copy the file header, `nonisolated enum`, `Equatable` outcome, doc comment citing the decision id, and one `static` resolver (lines 1-49):

```swift
import Foundation

/// Whether a cold launch ends signed in or signed out (D-13).
nonisolated enum AutoLoginOutcome: Equatable {
    case signedIn
    case signedOut

    enum RefreshResult: Equatable { case succeeded, authRejected, suspended, transientFailure }

    /// - Parameters:
    ///   - hadStoredToken: Whether the keychain held a token at launch.
    ///   - refresh: How the `/me` refresh ended. Ignored without a token.
    static func resolve(hadStoredToken: Bool, refresh: RefreshResult) -> AutoLoginOutcome {
        guard hadStoredToken else { return .signedOut }
        switch refresh {
        case .succeeded, .transientFailure: return .signedIn
        case .authRejected, .suspended:     return .signedOut
        }
    }
}
```

Apply: `nonisolated enum ExpertModeGate { enum Outcome: Equatable { case enterExpert, openSetupHub } ... }` with `decide(setupCompleted: Bool?)`, `shouldCheckSetupAtLaunch`, `shouldRecheckInBackground` as in RESEARCH Pattern 1. A failed lookup is `nil`, which fails open (D-02). Inputs are plain values only. `UserManager` has a private init and cannot be built in tests.

**Test analog:** `ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift` lines 10-45: `@MainActor @Suite("...")`, `@testable import ClickMe2026`, a `private static let everyResult` loop for the truth table, one `@Test("sentence")` per row, `#expect(... == ...)`.

---

### `ClickMe2026/Managers/UserManager.swift` (manager, request-response)

**Analog:** itself. Excerpts to copy from or modify:

**Mode persistence** (lines 519-522), the existing setter to make non-public for `.expert`:
```swift
func setMode(_ mode: AppMode) {
    currentMode = mode
    UserDefaults.standard.set(mode == .expert ? "expert" : "client", forKey: currentModeKey)
}
```

**Lookup that the gate reuses** (lines 509-512):
```swift
func refreshExpertProfile() async throws {
    let response = try await api.getExpertProfile()
    expertProfile = response.data
}
```

**Session clear: add `setupDeferred` removal here, NOT `lastLoginEmail`** (lines 439-464). The existing style is one `UserDefaults.standard.removeObject(forKey:)` per key (lines 454-457), so add the deferral clear next to them, before `currentMode = .client`.

**Valet read at init** (lines 142-145), the place and style for reading `lastLoginEmail` (T8):
```swift
if let token = try? valet.string(forKey: tokenKey) {
    api.bearerToken = token
    ...
}
```
Valet writes use `try? valet.setString(...)` / `try? valet.removeObject(forKey:)` (lines 556-580). `login()` and `signup()` now await `retryPushCleanupIfNeeded().value` before `apply(loginData:)` (around lines 188-235). Call `rememberLoginEmail(email)` after `apply`.

Class attributes: `@Observable` (line 17), `private init()` (line 122). Use `@ObservationIgnored` on non-UI state such as `lastLoginEmail`. Add `private(set) var setupHubRequested = false` as an observed property.

---

### `ClickMe2026/ClickMe2026App.swift` (app shell, event-driven)

**Analog:** itself, lines 24-35. Add the new `onChange` in the same chain and with the same route guard style:

```swift
.onChange(of: userManager.isLoggedIn) { _, isLoggedIn in
    guard !isLoggedIn else { return }
    if route == .clientHome || route == .expertHome || route == .signupSetup {
        route = .login
    }
}
.onChange(of: userManager.currentMode) { _, newMode in
    guard route == .clientHome || route == .expertHome else { return }
    route = newMode == .expert ? .expertHome : .clientHome
}
```

The `.splash` case maps `.setupIncomplete` to `route = .signupSetup` (about line 50). The new `setupHubRequested` observer must use that same destination and consume the flag. Do not change `currentMode` when opening the hub, so the mirror observer does not fight it.

---

### `ClickMe2026/Views/Screens/Splash/SplashViewModel.swift` (view model, request-response)

**Analog:** itself. Fail-open check to hoist into the shared place (lines 119-126):
```swift
private func isExpertProfileIncomplete() async -> Bool {
    do {
        try await userManager.refreshExpertProfile()
    } catch {
        return false
    }
    return userManager.expertProfile?.setupCompleted == false
}
```
Call-site structure (lines 76-84): `if isExpert { ... destination = .setupIncomplete }` then `destination = .dashboard(await resolveLandingMode(isExpert: isExpert))`. Wrap the `isExpert` branch with `ExpertModeGate.shouldCheckSetupAtLaunch(isExpert:deferred:)`. `LoginView.swift:288` holds a duplicate local `isExpertProfileIncomplete()`; delete it and call the shared one.

---

### `ClickMe2026/Managers/ModeSwitchGate.swift` (manager wrapper) and the `setMode` call sites

**Analog:** `ClickMe2026/Managers/PushRouter.swift`, the pure-planner-plus-source pattern (`PushRoutePlanner`, about lines 95-135):

```swift
enum PushRoutePlanner {
    static func canUseExpertMode(roles: [UserRole]?, setupCompleted: Bool?) -> Bool {
        guard let roles, roles.contains(.expert) else { return false }
        return setupCompleted == true
    }
    static func plan(_ pending: PendingPush, currentMode: AppMode, canUseExpertMode: Bool) -> PushPlan { ... }
}
```

Leave the planner untouched (RESEARCH R5). Route only its final `setMode` through the gate. For the six view call sites, follow the existing `CallCenter.attempt` guard already used in `ClientProfileHomeScreen.swift:249` and `ExpertProfileHomeScreen.swift:261`, and move that guard into the wrapper so the two `.modeSwitch` route sites (`HomeClientView.swift:332`, `HomeExpertView.swift:248`) gain it. Enforce with the grep gate: no `setMode(` outside `Managers/UserManager.swift`.

---

### `ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift` (state, transform)

**Analog:** itself.

**Completeness rule to edit** (lines 93-101): drop `!provinceState.isEmpty` (line 96), replace `!countryCode.isEmpty` with `Countries.normalize(countryCode) != nil`, add `avatarUrl != nil`.

**Checklist row** (lines 117-121): drop `&& !provinceState.isEmpty` (line 119).

**Publish builder** (lines 190-203): `guard isReadyToPublish else { return nil }`, `countryCode: countryCode` at line 197 becomes the normalized value, `provinceState` sent only when non-empty. Tag order: `expertiseTags.map { $0.id.uuidString }` (line 201) already treats index 0 as primary.

**Hydrate** (lines 141-182): province is skipped when empty (line 154), so `""` from a clear is already read as empty. Lines 174-177 re-sort non-primary tags alphabetically; leave as is.

**Email-verified seed:** new `refreshEmailVerified(using:)` calls `api.checkEmailVerified()` (exists, no callers). Use `try?` only for this best-effort read, per CLAUDE.md conventions.

---

### `SignupTagsViewModel.swift` and `LanguageSelectionViewModel.swift` (view models, CRUD)

**Analog:** `SignupTagsViewModel.swift` lines 101-120. The Set-plus-catalog-resort shape that loses tap order:
```swift
var selectedTags: [ExpertiseTagItem] {
    allTags.filter { selectedIds.contains($0.id) }
}
func toggleTag(_ tag: ExpertiseTagItem) {
    if selectedIds.contains(tag.id) { selectedIds.remove(tag.id) }
    else { selectedIds.insert(tag.id) }
    syncToAccumulator()
}
```
Fix: add an ordered `[ID]` array next to `selectedIds`. Append on select, remove on deselect, seed from `initialTags` in `init`. Map `order` through the catalog for output. Also set it in the preview seed (line 64 `vm.selectedIds = Set(selected.map(\.id))`). `LanguageSelectionViewModel.swift:84-87` has the identical shape. Keep labels from the initial selection as a fallback when the catalog has not loaded (RESEARCH Pitfall 6).

---

### `ClientProfileSettingsViewModel.swift` / `ExpertProfileSettingsViewModel.swift` (view model, CRUD auto-save)

**Analog:** `Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift` lines 236-291.

**Dedupe plus debounce** (lines 243-256):
```swift
func scheduleAutoSave() {
    if currentSnapshot() == lastAppliedSnapshot { return }
    autoSaveTask?.cancel()
    if didAutoSave { didAutoSave = false }
    autoSaveTask = Task { [weak self] in
        guard let debounce = self?.autoSaveDebounce else { return }
        try? await Task.sleep(nanoseconds: debounce)
        guard !Task.isCancelled else { return }
        await self?.performAutoSave()
    }
}
```

**Body build, success, and error** (lines 264-290): build `UpdateUserProfileRequest`, set `body.location = .init(city:stateProvince:countryCode:)` (province already sent as the trimmed string, so `""` clears), then
```swift
do {
    _ = try await api.updateUserProfile(body)
    lastAppliedSnapshot = currentSnapshot()
    withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
} catch {
    autoSaveError = error.userMessage
}
```
Add `body.languages = .init(languageIds:customLanguages:)` only when the selection changed (the `languages` group is a full replace on the server). Delete the comment at lines 261-263. Add the language ids to `currentSnapshot` and to the view's `autoSaveSnapshot`. The expert VM has the same gap at `ExpertProfileSettingsViewModel.swift:266-269` and `:330-333`. It uses `@Observable`; match its neighbours, not the client VM's `ObservableObject`.

---

### `NotificationSettingsViewModel.swift` (view model, CRUD auto-save, SET-04)

**Analog:** the `lastAppliedSnapshot` mechanism above. Current code to change:

`apply(preferences:)` mutates `sections` (about lines 88-101), which trips the view's `.onChange`. `scheduleAutoSave()` (about lines 108-120) has no dedupe guard. Copy the guard line `if currentSnapshot() == lastAppliedSnapshot { return }`. Set `lastAppliedSnapshot` after `apply` and after a successful `performAutoSave` (which currently ends with `didAutoSave = true` / `autoSaveError = error.userMessage`). Make `autoSaveDebounce` an init parameter so a test can shorten it.

---

### `FeedbackViewModel.swift` (view model, request-response, SET-05)

**Analog:** itself. The submit guard is `guard !trimmedDetails.isEmpty` (about line 112). Replace it with a `static let minimumDetailsLength = 10` check on the trimmed string, setting the existing `showDetailsError`. `detailsDidChange()` must clear the error only once the trimmed count reaches 10. Error text via `error.userMessage` as elsewhere in the file (line ~118 `loadState = .failed(error.userMessage)`).

---

### `DeleteAccountViewModel.swift` (view model, request-response)

**Analog:** itself.

**Init and dependency style** (lines 34-52): `private let api: ClickMeAPI` with a defaulted init parameter `api: ClickMeAPI = .shared`. Add `userManager: UserManager = .shared` the same way.

**Success tail** (line 121): `withAnimation { step = .deleted }`. Call `userManager.forgetLastLoginEmail()` immediately before it.

**Error mapping** (lines 126-150): both handlers use
```swift
guard case let NetworkError.httpError(statusCode, data) = error else {
    deletionError = Self.message(for: error)
    return
}
switch statusCode { case 401, 403: ...; case 429: ...; default: deletionError = Self.decodeStandardMessage(from: data) ?? "..." }
```
Add a 409 case in both handlers. Decode `StandardErrorResponse.code` into `ErrorCode`, build an `AccountDeletionBlocker`, and publish it as `@Published var blocker`. Branch on the code, never on message text. CLAUDE.md asks for `error.userMessage` rather than a new helper, so do not add another `Self.message(for:)`.

Plan order (D-15): T8 edit to this file first, then the 409 handling, then the SET-03 and SET-06 view edits.

---

### `ClickMe2026/Utils/AccountDeletionBlocker.swift` and `AccountDeletionCopy.swift` (utility)

**Analog:** `ClickMe2026/Utils/SuspensionNotice.swift` (lines 16-28) for the copy constants:
```swift
nonisolated enum SuspensionNotice {
    static let title = "Your account has been suspended"
    static let message = "You can't use ClickMe with this account right now. If you think this is a mistake, contact clickmeapp@uptrendinvestments.net."
    static let dismissLabel = "Close Alert"
    static func shouldPresent(wasSuspended: Bool, alreadyPresented: Bool) -> Bool { wasSuspended && !alreadyPresented }
}
```
Use the same shape: `static let` strings with a doc comment citing the decision, plus pure helpers. `AccountDeletionBlocker` follows the RESEARCH "Blocker mapping" example. `ClickMe2026/Utils/BookingErrorMapper.swift` is the closer analog for mapping an error code to display text; read it before writing.

**ErrorCode.swift** (lines 41-42 region): entries are column-aligned with explicit raw values, for example `case sessionInProgress       = "SESSION_IN_PROGRESS"`. Add `case clientHasUpcomingBookings = "CLIENT_HAS_UPCOMING_BOOKINGS"` in the Bookings group. A test must prove it decodes.

---

### `ClientCancellationView.swift` (view, event-driven, D-12)

**Analog:** itself, `confirmStepContent` (lines 201-232), between `CancellationConfirmCard` and `CancellationActionButtons`. Add `@State private var showPolicy = false`, a small text button, and a local `.navigationDestination(isPresented: $showPolicy) { CancellationPoliciesView() }`. The view is a destination on two stacks (`HomeRoute.cancelBooking` at `HomeClientView.swift:363`, `BookingRoute.cancelBooking` at `MyBookingsView.swift:139`), which is why a local destination is used instead of a new route case. Assumption A5: check on a device; the fallback is a sheet with its own `NavigationStack`.

Copy fixes (RESEARCH R4): `HowToInitiateCard` step 3 becomes "Tap Cancel." and the intro "until the session ends". `CancellationConfirmCard` footnote becomes "Your bank decides how long a refund takes to appear." The expert-cancel refund wording is Phase 6; leave it alone.

---

### `HelpView.swift` (SET-02)

Already fixed on main (`private static let supportEmail = "clickmeapp@uptrendinvestments.net"`). Only add a regression test and share one constant with `SuspensionNotice.message`, which hard-codes the same address in its string at line 18.

---

### `ProfilePhotoCropper.swift` (utility, file-I/O) and `LocationFormatter.swift` (utility, transform)

No close analog for the cropper beyond the `nonisolated enum` pure-type shape of `AutoLoginOutcome.swift`. Use RESEARCH Pattern 7. For `LocationFormatter`, replace the formatters at `SignupReviewViewModel.formatLocation` (lines ~105-111) and `ClientProfilePersonalInfo.locationLabel` (lines ~53-58) with one helper. Small utilities such as `ClickMe2026/Utils/BookingShortID.swift` are the file-shape reference.

---

### Tests (new suites)

**Pure-type tests:** copy `AutoLoginOutcomeTests.swift` (above).

**Stubbed-network tests:** copy the `APITestFactory.make` usage (`ClickMe2026Tests/Support/APITestFactory.swift` lines 22-37):
```swift
let api = APITestFactory.make { request in
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                   headerFields: ["Content-Type": "application/json"])!
    return (response, data)
}
```
Assert bodies with `MockURLProtocol.recordedRequests` and `ClickMe2026Tests/Support/URLRequest+Body.swift`. Suites touching the mock are `@MainActor @Suite(..., .serialized)` as in `ClickMe2026Tests/Push/PushRoutePlannerTests.swift` lines 17-19.

**Fake-source tests:** `PushRoutePlannerTests.swift` lines 28-60 show a `@MainActor private final class FakeAccount` that scripts roles and setup state, which is the model for testing anything that needs `UserManager`-like input.

The test target is a synchronized group, so new files need no `project.pbxproj` edit.

## Shared Patterns

### Error display and branching
**Source:** `ClickMe2026/Network/Error+UserMessage.swift`, `ClickMe2026/Model/Enums/ErrorCode.swift`
**Apply to:** all new VM error paths (delete 409, feedback, auto-save). Show `error.userMessage` in `apiError` / `autoSaveError`; branch on `ErrorCode`, not on message text.

### Pure decision type plus thin manager glue
**Source:** `ClickMe2026/Utils/AutoLoginOutcome.swift`, `ClickMe2026/Utils/SuspensionNotice.swift`, `PushRoutePlanner` in `ClickMe2026/Managers/PushRouter.swift`
**Apply to:** `ExpertModeGate`, `AccountDeletionBlocker`, `AccountDeletionCopy`, `LocationFormatter`, `ProfilePhotoCropper`.
Shape: `nonisolated enum`, `static` functions on plain values, decision ids in the doc comment.

### Auto-save snapshot dedupe
**Source:** `ClientProfileSettingsViewModel.swift` lines 243-256 and 286
**Apply to:** `NotificationSettingsViewModel`, language save in both profile VMs.

### File header and structure
Every new Swift file starts with the Xcode header block (see `AutoLoginOutcome.swift` lines 1-6). Use `// MARK: -` sections and `///` doc comments that explain why. Use `Id` rather than `ID` in names.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `ClickMe2026/Utils/ProfilePhotoCropper.swift` | utility | file-I/O | No existing image-rendering utility; use RESEARCH Pattern 7 (`UIGraphicsImageRenderer`). |
| `ClickMe2026/Utils/SetupDeferralStore.swift` | utility | CRUD | Only inline `UserDefaults.standard` use exists; make the suite injectable (`UserDefaults(suiteName:)`) so it is testable. |
| Foreground setup re-check (`setupCheckPending`, `scenePhase` hook in `ClickMe2026App`) | app shell | event-driven | iOS has no foreground re-check today; shells' `scenePhase` handlers only call `consumePendingPush` (`HomeClientView.swift:157`, `HomeExpertView.swift:100`). Android reference: `UserManager.kt` `recheckSetupIfPending`. |
| Expert-shell `showMyBookings` environment action | view | event-driven | The client shell provides it at `HomeClientView.swift:96`; the expert shell has none. Copy the client wiring and `HomeShellExit.plan(.viewMyBookings, ...)` from `ClickMe2026/Utils/HomeShellExit.swift`. |

## Notes for the Planner

- Port the T8 change by hand from `b0629d9`; do not merge the branch. Do not touch `clearLocalSession()` for the email. Do not port the two `userManager.logout()` test lines, because `logout()` is now async and touches Firebase.
- `ClickMe2026/Localizable.xcstrings` is already dirty in the working tree. Stage by explicit path only.
- Android and backend repos are read-only. Android follow-ups are todos only (D-11, D-12, D-16).

## Metadata

**Analog search scope:** `ClickMe2026/Utils`, `Managers`, `Views/Screens/{Splash, Settings, Signup Flow, Client Mode}`, `ClickMe2026Tests/{Utils, Push, Support}`
**Files scanned:** about 25 read in full or in part
**Pattern extraction date:** 2026-11-13
