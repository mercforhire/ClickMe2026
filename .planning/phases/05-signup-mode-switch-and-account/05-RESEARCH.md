# Phase 5: Signup, Mode Switch and Account - Research

**Researched:** 2026-11-13
**Domain:** SwiftUI iOS 18 / Swift 6 app: expert-signup flow, mode-switch gate, profile/notification/feedback settings, account deletion copy, dead-screen cleanup, login-email memory. iOS only. Backend and Android are read-only references.
**Confidence:** HIGH for file:line evidence and backend contract; MEDIUM for UI-behaviour assumptions that need a device check (listed in the Assumptions Log).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward (not re-asked)**
- **No backend change may break App Store build 6 or the current Android build** (PROJECT.md; the reason wave 3c was dropped).
- **Errors:** display text comes from `Error.userMessage`, and UI branches on `ErrorCode` values, never on `message` text (CONVENTIONS).
- **Tab-owned stacks (Phase 2 D-04):** a destination opens on the stack of the tab that owns it.
- **Single-call invariant:** a mode switch during a call stays blocked by `CallCenter` (Android `callGuard.attempt(RestrictedAction.SwitchModes)` is the same rule).

**Q5 / SIGN-06: the Expert-mode setup gate**
- **D-01:** Switching to Expert mode when the expert profile's `setup_completed` is false opens the **setup hub** (the existing `.signupSetup` route, hydrated, resuming where the user left off). This matches Android D-17. The hub offers **Not now** (Android D-27), which returns the user to Client mode. The deferral is remembered for this login, so Splash and foreground re-checks don't push setup again. Asking for Expert again clears the deferral and reopens the hub. Logout clears it.
- **D-02:** If the setup-status lookup **fails** during a switch (offline, server error), let the user into Expert mode. This fails open, the same as `SplashViewModel.isExpertProfileIncomplete()` and Android, so a network blip never sends a finished expert back into signup. The next launch or foreground re-checks.
- **D-03:** **One shared gate** covers every route into Expert mode: the Mode Switch screen (`HomeClientView`, `ClientProfileHomeScreen`, `HomeExpertView`, `ExpertProfileHomeScreen` call sites of `setMode`), a push plan's `switchToMode`, and Splash's landing decision. No path reaches an incomplete expert dashboard. Put the decision in one place, as Android does (`UserManager.requestModeSwitch`), not in each view. — **Reversibility:** costly — every `setMode(.expert)` call site moves to the shared entry point
- **D-04:** **BACK-13 is deferred past this release.** It stays parked on backend branch `wave-3c`, and the iOS gate (D-01 to D-03) fixes the user-facing bug. Record it in REQUIREMENTS.md as deferred, with the reason recorded in REL-02 (build 6 and current Android rely on `ensureExpert`'s implicit promotion). Note that the gate's own setup lookup (`refreshExpertProfile`, an `/expert/*` GET) still promotes a client-only account through `ensureExpert` once they pick Expert. That's accepted: an explicit switch to Expert is consent (Android D-23). No *background* lookup may run for a client-only account outside Expert mode (Android `recheckSetupIfPending` role guard).

**Q5 / S2: optional province**
- **D-05:** Province/state is **optional** at signup, matching the server contract and Android (`SignupDraft.kt`, D-03). Remove it from `SignupAccumulator.isReadyToPublish` and from the Basic Info checklist row. City, country, timezone and languages stay required.
- **D-06:** When province is empty, an expert's location reads **"City, Country"** with no stray comma or blank. Planning audits every place that formats a location: expert cards, expert profile, the client profile an expert sees (`ClientProfilePersonalInfo`), and the signup review.
- **D-07:** A saved province **can be cleared** in client and expert profile settings, as Android does (`clearProvince`). Research confirms how `userProfile.schema.js` accepts a clear (null vs empty string) before planning.

**SET-06 / T6: Delete Account copy**
- **D-08:** Replace the current paragraph (`DeleteAccountWarningHeader.swift:22`) with **one permanence line plus three short groups**, matching what `services/accountCascade.js` does:
  - **Deleted:** your profile details (name, photo, bio, location), devices, notifications and preferences, and uploaded files.
  - **Kept without your personal details:** your past bookings, shown as from "Deleted user".
  - **Kept:** messages, reviews and payment records.
  Research checks each claim against `purgeAndLockAccount` (steps F1–F11, I) and the no-DML note for reviews, messages and reports, and adjusts the wording if any claim is wrong. Copy follows the project's plain-English style.
- **D-09:** Say plainly that **messages and reviews you've written stay visible to the other person, shown as from "Deleted user"**.
- **D-10:** Add one upfront line saying deletion needs upcoming bookings cancelled or finished first. Make sure each self-delete 409 shows a clear message with a way to My Bookings: `EXPERT_HAS_UPCOMING_BOOKINGS`, `CLIENT_HAS_UPCOMING_BOOKINGS` (**missing from `ErrorCode.swift`, so add it**) and `SESSION_IN_PROGRESS`. Source: `account.controller.js` `assertNoBlockingBookings`, D-17/D-18/D-19.
- **D-11:** Android has the same wrong copy (`delete_account_body`). **Log an Android follow-up todo containing the final iOS strings**, so the port copies them word for word. No Android commit in this phase.

**Q7 / SET-07: dead screens**
- **D-12:** **Wire `CancellationPoliciesView` into the client cancel-booking flow** with a "Cancellation policy" link on the cancel confirmation. Before linking, research checks its copy (`CancellationDeadlinesCard`, `RefundEligibilityCard`, `HowToInitiateCard`) against the backend's current client-cancel refund rule (D-16 binary 24 h in `accountCascade.js` and the booking cancel controller) and the hold model, and fixes any mismatch. The expert-cancel refund question (Q2) is Phase 6 and must not be decided here.
- **D-13:** **Delete `ReadyToStartCallView`**, `ReadyToStartCallViewModel` and any helper only they use. It's a legacy Skype meeting-link screen; calls run through Agora and `CallCenter`. — **Reversibility:** reversible — recoverable from git

**Q1 / T8: remember last login email**
- **D-14:** **Bring `feature/remember-login-email` (`b0629d9`) into this phase.** It pre-fills the last email on Login after sign-out and clears it on Delete Account, with `RememberedLoginEmailTests`. The branch is 405 commits behind `main`, and a merge conflicts in `ClickMe2026/Managers/UserManager.swift`, so **port the change onto current main** as its own plan rather than merging the branch. Re-run its tests, and check it against Phase 4 logout and suspension changes (`SuspensionNotice`, `AutoLoginOutcome`).
- **D-15:** The ported change touches `DeleteAccountViewModel.swift`, which SET-03 and SET-06 also edit. The planner orders these plans so they don't conflict.
- **D-16:** Log an Android follow-up todo for the matching Android branch (`0c9ecc55`, also unmerged).

### Claude's Discretion
- How the shared gate is structured in Swift (a `UserManager` method vs a small coordinator), as long as D-03's single entry point holds.
- The exact wording of the D-08/D-10 copy within the agreed structure. The final strings go into the Android todo (D-11).
- Where the "Cancellation policy" link sits inside the cancel confirmation (D-12).

### Deferred Ideas (OUT OF SCOPE)
- **BACK-13 explicit-promotion backend change:** after App Store build 6 and the current Android build no longer rely on implicit promotion. Recorded in REL-02 (D-04).
- **Android follow-ups (todos, not this phase):** the setup gate is already on Android. To log: Delete Account copy with the final iOS strings (D-11); the 409 messages if Android lacks `CLIENT_HAS_UPCOMING_BOOKINGS`; the remember-login-email port (`0c9ecc55`, D-16); and the cancellation-policy link if Android has no equivalent (D-12).
- **S8 (Android requires a digit in passwords):** still by design, not discussed.
- Reviewed todos not folded: `2026-11-08-check-the-android-push-prompt-after-a-reinstall.md`, `2026-11-11-merge-d12-into-backend-master.md`, `2026-11-12-long-lead-sweep-transient-errors-after-stamp.md`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGN-01 | Expert cannot publish without a photo | Backend 422 lists `profile_image_url` as missing (`onboarding.controller.js:57`, `:175-189`). Add `avatarUrl` to `isReadyToPublish`, plus a `missingForPublish` list (R7, Pattern 5). |
| SIGN-02 | Resuming signup keeps the verified email | Only source is `GET /auth/email/status` (`checkEmailVerified()`, no callers today). `GET /expert/profile` has no `email_verified`. Seed in the hub `.task` (Pattern 5). |
| SIGN-03 | Tags and languages keep tap order | Both pickers hold a `Set` and re-sort by catalog (`SignupTagsViewModel.swift:103-105`, `LanguageSelectionViewModel.swift:84-87`). Add an ordered array (Pattern 6). |
| SIGN-04 | Country code normalized on publish | `buildPublishRequest()` sends `countryCode: countryCode` raw (`SignupAccumulator.swift:197`). Use `Countries.normalize`; unrecognised = not ready (Pattern 5). |
| SIGN-05 | Upload matches the zoom/crop | Preview is a centred `scaledToFill` + `scaleEffect(1 + zoom)` circle with no pan (`ProfileAvatarRing.swift:53-57`). Render that square in a pure `ProfilePhotoCropper` at save time (Pattern 7). |
| SIGN-06 | Expert switch with incomplete setup opens the setup hub | One gate, Android shape, 10 `setMode` sites and the route handoff (R5, Pattern 1). |
| SET-01 | Language edits save (client and expert) | Both VMs skip languages; the editor sheet is a hard-coded 12-label list with no ids (R8, Pattern 8). Expert VM has the same gap. |
| SET-02 | Help > Email Us goes to `clickmeapp@uptrendinvestments.net` | **Already fixed on main** by `cae4090` (2026-11-12). Plan = regression test + shared constant (R8). |
| SET-03 | Remove Pause Account card | `DeleteAccountPauseCard`, `onPauseAccount`, "Before you go..." header (R3, Pattern 3). |
| SET-04 | No save on opening Notification preferences | `apply(preferences:)` mutates `sections`, which trips the view's `.onChange` (Pattern 9). |
| SET-05 | Feedback needs 10+ characters | Server `details: z.string().min(10)`; iOS only checks non-empty (Pattern 10). |
| SET-06 | Delete Account copy is accurate | Claim-by-claim audit and proposed strings (R2). |
| SET-07 | Dead screens wired or removed | Wire `CancellationPoliciesView` (copy audit R4), delete `Call/Ready/` (R9). |
| T8 (D-14) | Remember last login email | Port plan, conflicts and test changes (R6). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Extracted from `./CLAUDE.md` and `./.claude/CLAUDE.md`; treat as locked.

- **Stack:** SwiftUI, Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`), iOS 18+, Xcode 26. No rewrites.
- **Cross-repo:** the backend owns the API contract; read the route/schema before changing an API call. This phase makes **no backend or Android commit**; Android items are logged as todos only. Do not assume anything is done in another repo.
- **Backend compatibility:** nothing may break App Store build 6 or the current Android build.
- **Definition of done:** unit tests where the logic is testable, a clean `xcodebuild` with no new warnings, a real-iPhone check on the UAT checklist.
- **Conventions:** one primary type per file; `ViewModel` `@MainActor`; new shared managers use `@Observable`; match the neighbouring VM style (`ClientProfileSettingsViewModel` is `ObservableObject`, `ExpertProfileSettingsViewModel` is `@Observable`); `apiError` for new VM errors; use `Error.userMessage`, never a new `errorMessage(for:)`; branch on `ErrorCode`, not on message text; no `try?` for writes whose failure the user must see; `#if DEBUG` around any new logging, never log tokens or full payloads; `// MARK: -` sections; Xcode header block on each new file; `Id` not `ID`; new screen folders under `Views/Screens/` use spaces; do not wrap `#Preview` in `#if DEBUG`.
- **Dates:** use `DateUtil`, not new `DateFormatter`s. **Do not stage unrelated diffs:** `ClickMe2026/Localizable.xcstrings` is already modified in the working tree and Xcode will rewrite it on every build.
- **GSD workflow:** file changes go through a GSD command (plans), not direct edits.

## Summary

Phase 5 is a set of mostly small, well-evidenced fixes around one structural change (the Expert-mode gate). Every inventory row (S1, S3-S7, T1-T7) still matches current code, with four updates: **T2 (Help email) and the Cancellation Policy refund copy were already fixed on main on 2026-11-12** (`cae4090`, `510e7cb`), so SET-02 reduces to a regression guard and SET-07's copy audit finds only three small mismatches. `HomeClientView.swift:243-245` in the inventory is stale; the real `setMode` call sites are listed in R5.

The riskiest work is SIGN-06. There are ten `setMode(` call sites (six in views, plus Splash, Login x2 and the two push `switchToMode` handlers). Android's design (`UserManager.requestModeSwitch`, `deferSetup`, `completeSetup`, `recheckSetupIfPending`, persisted deferral flag) maps cleanly to iOS if the decision logic is a **pure type** (like `PushRoutePlanner` / `AutoLoginOutcome`, unit-testable without the `UserManager` singleton) and `UserManager` carries only state and glue. The route change to `.signupSetup` must be signalled to `ClickMe2026App` through an observable flag, because `route` is private `@State` there. iOS has no foreground setup re-check today; D-02's "foreground re-checks" requires adding a minimal `setupCheckPending` flag (Open Question 3).

Three findings change the plan shape: (1) SET-01 cannot be fixed by "also sending languages": the editor sheet (`LanguageEditorSheet`) uses a hard-coded 12-label list with no language ids and no English/Spanish, so it must be replaced with the id-backed `LanguageSelectionView` (which also needs the SIGN-03 tap-order fix), and custom (id-less) languages must be round-tripped as `custom_languages` or the full-replace PATCH deletes them. (2) D-07 needs no new wire behaviour: the schema accepts `""` and rejects `null`, and both settings VMs already send `""` when the field is emptied; the work is making every reader treat `""` as empty. (3) The ported `RememberedLoginEmailTests` call `userManager.logout()` synchronously, which is now an async Firebase/Keychain cleanup; do not port those lines.

**Primary recommendation:** Build a pure `ExpertModeGate` + `SetupDeferralStore` (testable), thin `UserManager` methods (`requestModeSwitch`, `deferSetup`, `completeSetup`, `recheckSetupIfPending`) and one observable `setupHubRequested` flag consumed by `ClickMe2026App`; make `setMode` non-public for `.expert`; do the other twelve items as small independent plans with one new Swift Testing suite each.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `setup_completed` truth | API / Backend (`GET /expert/profile`) | iOS cache `UserManager.expertProfile` | Server is authoritative; iOS only decides what to do with it (fail open per D-02). |
| Expert-mode gate decision and deferral | iOS client (pure type + `UserManager` state) | UserDefaults (persisted deferral) | Product rule is client-side; backend gate (BACK-13) is deferred. |
| Route to setup hub | iOS app shell (`ClickMe2026App.route`) | `UserManager` flag | Route is private state in the App struct; managers cannot set it directly. |
| Publish completeness | API (422 `missing_fields`) | iOS pre-check (`isReadyToPublish`) | iOS pre-check only avoids a doomed request; server stays the enforcer. |
| Verified-email state on resume | API (`GET /auth/email/status`) | `SignupAccumulator` | No other endpoint exposes it. |
| Photo crop | iOS client (pure renderer) | API stores bytes as given | Server does no cropping (`POST /user/profile/avatar`). |
| Language/province persistence | API (`PATCH /user/profile`, full-replace languages) | iOS builds the body | Replace semantics make the client responsible for sending customs back. |
| Account deletion cascade | API (`purgeAndLockAccount`) | iOS copy | Copy must describe exactly what the cascade does (SET-06). |
| Delete blockers (409) | API (`assertNoBlockingBookings`) | iOS maps `ErrorCode` to message + shell action | Server codes drive UI; text is iOS-owned (D-10). |
| Remembered login email | iOS Keychain (Valet) | — | Client-only PII convenience; deleted on account deletion. |
| Cancellation policy copy | iOS | Backend rule in `utils/refund.js` | Copy mirrors, never decides, the refund rule. |

## Standard Stack

**No new packages.** Everything uses what is already in the app target. [VERIFIED: ClickMe.xcodeproj/project.pbxproj, CLAUDE.md Technology Stack]

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI / Observation | iOS 18 SDK (Xcode 26.5, build 17F42) | Views, `@Observable` managers | Existing app stack [VERIFIED: `xcodebuild -version` output "Xcode 26.5"] |
| Valet | 5.1.0 | Keychain for remembered login email | Already holds tokens in `UserManager` [CITED: CLAUDE.md] |
| Swift Testing + `MockURLProtocol` | in-repo | Unit tests for VMs and request bodies | Phase 1-4 pattern (`APITestFactory.make`) [VERIFIED: ClickMe2026Tests/Support/APITestFactory.swift] |
| UIKit `UIGraphicsImageRenderer` / `CGImage.cropping` | system | Photo crop | Platform API, no dependency |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure `ExpertModeGate` + store | Logic inline in `UserManager` | `UserManager` has a private init and cannot be built in tests; the pure type can (as `PushRoutePlanner` is). |
| `.navigationDestination(isPresented:)` for the policy link | New `HomeRoute.cancellationPolicy` case | A new case needs exhaustive-switch edits in both shells and also `MyBookingsView`'s own `BookingRoute` stack; the local destination works on both stacks. |
| Custom PhotosPicker crop UI | Keep slider + render | Out of scope (no new UI); the slider already defines the crop. |

**Installation:** none. **Version verification:** not applicable (no packages added).

## Package Legitimacy Audit

No external packages are installed or changed in this phase, so no `package-legitimacy check` was run.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                      ENTRY POINTS INTO EXPERT MODE (D-03)
 ModeSwitchView tap ---+   push plan switchToMode(.expert) ---+   Splash/Login landing ---+
 (4 call sites)        |                                       |                           |
                       v                                       v                           v
              +-----------------------------------------------------------------------------+
              | ModeSwitchGate (MainActor): CallCenter.attempt("switch modes") guard         |
              +-----------------------------------------------------------------------------+
                                           |
                                           v
              UserManager.requestModeSwitch(.expert)  --(target .client: setMode(.client), done)
                 1. clear deferral (asking for Expert = consent, D-01)
                 2. refreshExpertProfile()  --> GET /expert/profile  (promotes client-only via ensureExpert, accepted D-04)
                 3. ExpertModeGate.decide(setupCompleted: Bool?)   nil(failed) -> enter (fail open, D-02)
                 4. isLoggedIn still true?  else .sessionEnded (write nothing)
                       |                                         |
          .enterExpert |                                         | .openSetupHub
                       v                                         v
        setMode(.expert) (persist)                    setupHubRequested = true   (mode NOT persisted)
        App mirrors currentMode -> .expertHome                |
                                                              v
                                       ClickMe2026App.onChange(setupHubRequested)
                                       route == home? -> route = .signupSetup; consume flag
                                                              |
                                                              v
                                  LoginView(startAtSignupSetup: true, hydrateFrom: expertProfile)
                                       Overview hub (.task: GET /auth/email/status -> emailVerified)
                                       [Not now]  -> UserManager.deferSetup(): setMode(.client), store deferral
                                                     -> onSuccess(.client) -> route .clientHome
                                       [Publish]  -> UserManager.completeSetup(): setMode(.client), clear deferral

 Splash:  tryAutoLogin -> roles -> (expert && !deferred) -> refreshExpertProfile -> incomplete? .setupIncomplete : landing
 Foreground (home route only): recheckSetupIfPending() -- role guard, no request for client-only outside Expert mode
 Logout/clearLocalSession: removes deferral key (but NOT lastLoginEmail)
```

### Recommended Project Structure
```
ClickMe2026/
├── Utils/
│   ├── ExpertModeGate.swift            # pure decision: (setupCompleted?, roles, mode, deferred) -> outcome
│   ├── SetupDeferralStore.swift        # UserDefaults-backed flag, injectable suite
│   ├── ProfilePhotoCropper.swift       # pure render of centred square crop at zoom
│   ├── LocationFormatter.swift         # trim + drop empty + "City, Country"
│   ├── AccountDeletionBlocker.swift    # ErrorCode -> message + whether a bookings action applies
│   └── AccountDeletionCopy.swift       # the final D-08/D-10 strings (also feed the Android todo)
├── Managers/UserManager.swift          # +requestModeSwitch/deferSetup/completeSetup/recheck, +lastLoginEmail
├── Managers/ModeSwitchGate.swift       # thin MainActor wrapper adding the CallCenter guard
ClickMe2026Tests/
├── Utils/ ExpertModeGateTests, SetupDeferralStoreTests, ProfilePhotoCropperTests, LocationFormatterTests,
│          AccountDeletionBlockerTests, FeedbackValidationTests
├── Signup/ SignupAccumulatorTests, SignupEmailVerifiedSeedTests, SelectionOrderTests
├── Settings/ ProfileLanguagesSaveTests, NotificationSettingsAutoSaveTests
└── Auth/ RememberedLoginEmailTests (ported)
```
The app and test targets are **file-system synchronized groups** (`PBXFileSystemSynchronizedRootGroup` for `ClickMe2026`, `ClickMe2026Tests`, `Constants`), so new and deleted files need no `project.pbxproj` edit. [VERIFIED: ClickMe.xcodeproj/project.pbxproj lines 53-77; grep for `ReadyToStart` and `CancellationPolic` in pbxproj returns nothing]

### Pattern 1: Single Expert-mode gate (SIGN-06, D-01..D-04)
**What:** pure decision + thin manager glue + flag for the route handoff. Mirrors Android `requestModeSwitch` / `deferSetup` / `completeSetup` / `recheckSetupIfPending`. [VERIFIED: ClickMe_Android/.../managers/UserManager.kt:383-437, AppViewModel.kt:194-225]
**When:** every path to Expert. `setMode` for `.expert` stops being callable from views.
**Example:**
```swift
// Utils/ExpertModeGate.swift  -- pure, no UserManager, unit-testable
nonisolated enum ExpertModeGate {
    enum Outcome: Equatable { case enterExpert, openSetupHub }

    /// - Parameter setupCompleted: nil when the lookup failed (offline, 5xx). D-02: fail open.
    static func decide(setupCompleted: Bool?) -> Outcome {
        setupCompleted == false ? .openSetupHub : .enterExpert
    }

    /// Splash/Login: should the post-auth check ask the server at all?
    /// Mirrors Android resolvePostAuthDestination: `isExpert && !setupDeferred`.
    static func shouldCheckSetupAtLaunch(isExpert: Bool, deferred: Bool) -> Bool { isExpert && !deferred }

    /// Foreground re-check role guard (D-04): a client-only account outside Expert mode makes NO request.
    static func shouldRecheckInBackground(roles: [UserRole]?, mode: AppMode) -> Bool {
        guard let roles else { return false }            // roles unknown: stay pending, no request
        return roles.contains(.expert) || mode == .expert
    }
}
```
```swift
// UserManager additions (MainActor, @Observable)
private(set) var setupHubRequested = false              // observed by ClickMe2026App
private let deferral = SetupDeferralStore()             // UserDefaults key "setupDeferred"

enum ModeSwitchResult: Equatable { case switched(AppMode), setupRequired, sessionEnded }

func requestModeSwitch(_ target: AppMode) async -> ModeSwitchResult {
    guard target == .expert else { setMode(.client); return .switched(.client) }
    deferral.clear()                                    // D-01: asking for Expert ends a deferral
    let completed: Bool?
    do { try await refreshExpertProfile(); completed = expertProfile?.setupCompleted }
    catch { completed = nil }                           // D-02 fail open
    guard isLoggedIn else { return .sessionEnded }      // logout during the lookup: write nothing
    switch ExpertModeGate.decide(setupCompleted: completed) {
    case .enterExpert:   setMode(.expert); return .switched(.expert)
    case .openSetupHub:  setupHubRequested = true; return .setupRequired   // do not persist Expert
    }
}
func deferSetup()   { deferral.set(); setMode(.client); setupHubRequested = false }
func completeSetup(){ deferral.clear(); setMode(.client) }
func consumeSetupHubRequest() { setupHubRequested = false }
```
`clearLocalSession()` must call `deferral.clear()` (D-01 "Logout clears it"); it already runs for user, forced and suspension logouts.

**Route handoff (ClickMe2026App):**
```swift
.onChange(of: userManager.setupHubRequested) { _, requested in
    guard requested else { return }
    userManager.consumeSetupHubRequest()
    if route == .clientHome || route == .expertHome { route = .signupSetup }
}
```
`currentMode` is not changed on `.setupRequired`, so the existing mirror `onChange(of: currentMode)` (guarded to home routes, `ClickMe2026App.swift:31-35`) does not fight the handoff, and a later `setMode(.client)` while on `.signupSetup` is ignored by the mirror. [VERIFIED: ClickMe2026App.swift:31-35]

### Pattern 2: Call-site migration table (D-03)
| Site | Today | After |
|------|-------|-------|
| `HomeClientView.swift:172` (push `switchToMode`) | `userManager.setMode(mode)` | `await gate.request(mode)`; planner stays as is (see R5 note) |
| `HomeClientView.swift:332` (`.modeSwitch` route) | `setMode(mode)`, **no call guard** | `gate.request(mode)` (guard now inside) |
| `ClientProfileHomeScreen.swift:249` | `attempt` guard then `setMode` | `gate.request(mode)` |
| `HomeExpertView.swift:116` (push) | `setMode(mode)` | `gate.request(mode)` |
| `HomeExpertView.swift:248` (`.modeSwitch` route) | `setMode(mode)`, **no call guard** | `gate.request(mode)` |
| `ExpertProfileHomeScreen.swift:261` | `attempt` guard then `setMode` | `gate.request(mode)` |
| `SplashViewModel.swift:115` | `setMode(mode)` after its own check | `deferral`-aware check, then internal landing call |
| `LoginView.swift:288` (login landing) | `setMode(mode)` after local `isExpertProfileIncomplete()` | same shared `UserManager` check (delete the duplicate local function) |
| `LoginView.swift:222` (publish) | `setMode(.client)` | `completeSetup()` |
Enforce with a grep gate: no `setMode(` outside `UserManager.swift` (the manager keeps a `private`/`fileprivate` setter). Note both `.modeSwitch` shell routes today skip `CallCenter.attempt`, so the call-time block is currently inconsistent; the shared wrapper fixes that. [VERIFIED: grep of `setMode(` across ClickMe2026]

### Pattern 3: Delete Account screen (SET-03, SET-06, D-10)
`DeleteAccountView.confirmationView` currently shows `DeleteAccountWarningHeader`, a "Before you go..." title and `DeleteAccountPauseCard(action: onPauseAccount)` (`DeleteAccountView.swift:96-101`). Remove the title, the card file, the `onPauseAccount` parameter and `AccountSecurityView`'s lack of a pause wiring (it only passes `onBackToLogin`, `AccountSecurityView.swift:207-209`). Put the new copy in `DeleteAccountWarningHeader` (shown on both steps) as `AccountDeletionCopy` constants. Blocker mapping lives in `AccountDeletionBlocker` (pure) and `DeleteAccountViewModel` exposes a `blocker` published value; the view shows an alert with a "View my bookings" button only when the shell can honour it (R3).

### Pattern 4: Remember login email (R6) -- see R6.

### Pattern 5: SignupAccumulator changes (SIGN-01/02/04, D-05)
```swift
var isReadyToPublish: Bool {                        // province removed (D-05); photo + valid country added
    !firstName.isEmpty && !city.isEmpty && Countries.normalize(countryCode) != nil
        && !timezone.isEmpty && !languages.isEmpty && !expertiseTags.isEmpty && avatarUrl != nil
}
var missingForPublish: [ChecklistItemKind] { ... }  // Android SignupDraft.missingForPublish; excludes .verifyEmail
func refreshEmailVerified(using api: ClickMeAPI = .shared) async {
    guard let status = try? await api.checkEmailVerified() else { return }   // read: best effort, keep current value
    emailVerified = emailVerified || status.data.verified                    // never downgrade a local success
}
```
`buildPublishRequest()` passes `Countries.normalize(countryCode)` and `provinceState` only when non-empty. Basic Info checklist row drops `!provinceState.isEmpty`. Call `refreshEmailVerified` from `SignupOverviewView.task` (covers Splash resume, post-login resume and the return from the verify screen); also set it from `SignupResponse.emailVerified` on signup (field is decoded but unused, `SignupResponse.swift:16`).

### Pattern 6: Tap order (SIGN-03)
Keep `Set` for O(1) membership, add `private(set) var order: [String]` (ids). `toggle` appends on select, removes on deselect; `init(initialSelection:)` seeds `order` from the passed array (preserves existing order). `orderedSelection` / `selectedTags` map `order` through the catalog. The accumulator already treats element 0 as primary for tags (`isPrimary: idx === 0`, `onboarding.controller.js:124-128`) and the server stores no language order, so for languages only the request order and the chip order change. `SignupAccumulator.hydrate` currently re-sorts non-primary tags alphabetically (`SignupAccumulator.swift:174-177`): acceptable (only the primary is meaningful) but do not re-save a re-sorted list unless the user edits.

### Pattern 7: Photo crop (SIGN-05)
Preview math: image `scaledToFill` in a `size-4` circle, then `scaleEffect(1 + zoom)` about the centre, zoom in `0...1` default `0.5`, no pan. So the visible region is the centred square of side `min(w,h) / (1 + zoom)` in oriented pixels. Render that square (Android's `CropMath.sourceRect` is also a square; the circle is a display mask). Keep the original `UIImage` (not only the pre-encoded JPEG) in the VM and render at `save()`; scale down so the longest side is at most 1024 px, JPEG 0.85. Hydrated photos (`loadExistingAvatarIfNeeded`) have no `pendingJpegData` today, so Save is a no-op for them; keep that (disable the slider for a downloaded avatar, or treat zoom as display-only).
```swift
nonisolated enum ProfilePhotoCropper {
    static func squareCrop(_ image: UIImage, zoom: CGFloat, maxSide: CGFloat = 1024) -> Data? {
        let upright = image.normalizedUpright()                       // draw into a renderer to bake orientation
        guard let cg = upright.cgImage else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let side = min(w, h) / (1 + max(0, min(1, zoom)))
        let rect = CGRect(x: (w - side) / 2, y: (h - side) / 2, width: side, height: side).integral
        guard let cropped = cg.cropping(to: rect) else { return nil }
        let out = min(maxSide, CGFloat(cropped.width))
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: out, height: out))
        return renderer.jpegData(withCompressionQuality: 0.85) { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(x: 0, y: 0, width: out, height: out))
        }
    }
}
```

### Pattern 8: Language save (SET-01)
VM state becomes `languageItems: [LanguageItem]` (catalog, with ids) plus `customLanguages: [String]` (entries whose `UserProfileData.LanguageEntry.id` is nil; the server returns `id: null` with the `custom_label` as `label`, `userProfile.controller.js:78-81`). Body: `languages: .init(languageIds: items.map(\.id), customLanguages: customLanguages)`. Always send both arrays together: the group is a **full replace** (`userProfile.controller.js:95-117`), so omitting `custom_languages` deletes customs. Send the `languages` group **only when the language selection changed** (compare to the hydrated ids), as Android does for WR-03/WR-07, so a profile text edit never rewrites languages. Replace `LanguageEditorSheet` (hard-coded labels) with `LanguageSelectionView(initialSelection:onDone:)` in both views, add the language ids to both `currentSnapshot` strings and both views' `autoSaveSnapshot`. Expert settings also write through `PATCH /user/profile`, so the same body serves both.

### Pattern 9: Notification preferences first-load (SET-04)
Mirror the profile VMs: keep `lastAppliedSnapshot` (string of `category.sub=isOn`), set it after `apply(preferences:)` and after each successful save, and make `scheduleAutoSave()` return when the current snapshot equals it. Make the debounce an init parameter (default `800_000_000`) so a test can set it to a few ms. Note the view's `.onChange(of: autoSaveSnapshot)` only fires when a server value differs from the all-`true` defaults, so the bug is intermittent (users with a toggle off); the test must seed one off.

### Pattern 10: Feedback minimum (SET-05)
Add `static let minimumDetailsLength = 10` and compute on the **trimmed** string; below it, set `showDetailsError = true` (copy "Please enter at least 10 characters.") and make no request. The server checks the untrimmed string (`details: z.string().min(10)`), iOS sends the trimmed one, so trimmed >= 10 is the safe client rule. `detailsDidChange()` currently clears the error when `!details.isEmpty`; change it to clear only when the trimmed count reaches 10. A live counter is optional.

### Anti-Patterns to Avoid
- **Per-view gate logic:** CONTEXT D-03 forbids it; and a view cannot set `AppRoute`.
- **Persisting Expert before the lookup returns:** a stored `.expert` with an incomplete profile misleads the next launch (Android comment, `UserManager.kt` requestModeSwitch doc).
- **Sending `null` for province:** 422 (R1).
- **Sending `languages` without `custom_languages`:** silently deletes custom languages.
- **A background `GET /expert/*` for a client-only account outside Expert mode:** promotes them via `ensureExpert` (D-04).
- **`try?` around the gate lookup result without treating it as nil:** a failed lookup must fail open, never default to `false`.
- **Calling `userManager.logout()` in tests:** it now runs Firebase `deleteToken` and a Keychain/UserDefaults wipe on the shared singleton.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Country code normalisation | A new alpha-2 map | `Countries.normalize` (`Constants/Countries.swift:71-81`) | Already trims, uppercases, maps alpha-2, returns nil when unknown |
| Error text / codes | New `errorMessage(for:)`, string-match on `message` | `Error.userMessage`, `StandardErrorResponse.code` / `ErrorCode` | Project rule |
| Auto-save dedupe | New debounce framework | The `lastAppliedSnapshot` pattern already in both profile VMs | Proven; just reuse in notifications |
| Language picker with ids | Another label list | `LanguageSelectionView` + `getLanguages()` | Already server-backed, searchable |
| Shell navigation to Bookings | New route plumbing | `\.showMyBookings` `HomeShellAction` + `HomeShellExit.plan(.viewMyBookings, ...)` | Already resets the source tab stack (BOOK-19) |
| Mailto | Custom mail composer | `openURL(mailto:)` as `HelpView.openSupportEmail` does | Works with any default mail client |
| Date/time in tests | Real clock | Pass `now` / injectable inputs like `CancelRefundPreview` | Deterministic tests |

**Key insight:** every item here already has a working analogue in the repo or on Android; the bugs come from one screen skipping the shared piece. Reuse, then add a pure helper and a test.

## Runtime State Inventory

Not a rename/migration phase, but three items add persisted state:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | New `UserDefaults` key `setupDeferred` (Bool); new Valet key `lastLoginEmail` (PII). Server `profiles.state_province` becomes `""` (not NULL) after a clear. | Clear `setupDeferred` in `clearLocalSession()`. Do **not** clear `lastLoginEmail` there (deliberate); clear it in `DeleteAccountViewModel` on success. Readers treat `""` as empty. |
| Live service config | None -- no backend change. | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | `ClickMe2026/Views/Screens/Call/Ready/` (9 files) compiled into the target; stale entries in `Localizable.xcstrings` for deleted strings (the catalog is already dirty in git). | Delete the folder (no pbxproj edit, synchronized group). Let Xcode regenerate the catalog; commit only intended string changes. |

## Research Answers (the nine assigned questions)

### R1. Clearing a saved province (D-07)
- Client PATCH `/user/profile`: `state_province:       z.string().optional(),` [VERIFIED: ../ClickMe2026 Backend/src/schemas/userProfile.schema.js:48]. Controller: `if (l.state_province !== undefined) update.state_province = l.state_province;` [VERIFIED: userProfile.controller.js:167]. So: omit = unchanged; `""` = accepted and **stored as `''`**; `null` = Zod rejects (the field is not `.nullable()`) -> 422 with `.strict()`.
- Expert PATCH `/expert/profile` `location_details`: `state_province: z.string().optional(),` [VERIFIED: expertProfile.schema.js:58], same semantics (`expert.controller.js:130-132` copies present keys).
- Signup `PATCH /expert/profile/setup`: `province_state: z.string().optional()` [VERIFIED: onboarding.schema.js:37], written at `onboarding.controller.js:84`.
- DB column: `state_province TEXT` [VERIFIED: migration 20260603000000_phase3_extend_profiles.sql:23]; no CHECK seen in that migration (other migrations not audited, [ASSUMED] none).
- **iOS today** already sends `""`: `stateProvince: state.trimmingCharacters(in: .whitespaces),` in both `ClientProfileSettingsViewModel.swift:272` and `ExpertProfileSettingsViewModel.swift:278` [VERIFIED]. Clearing works on the wire. Signup Basic Info does **not**: it sends `provinceState: trimmedProvince.isEmpty ? nil : trimmedProvince` (`SignupBasicInfoViewModel.swift:123`), so a cleared province stays on the server.
- **Android** `clearProvince`: `?: "".takeIf { clearProvince && current.provinceState.isNotBlank() }` with the doc "The server accepts `""` for both" [VERIFIED: SignupSetupRepository.kt:218-236]. It sends `""` only when the user emptied a field that had a value.
- **Plan:** (a) settings: no wire change, add a regression test that the encoded body contains `"state_province":""`; (b) signup Basic Info: port the `clearProvince` rule (send `""` only if the accumulator held a non-empty value and the field was edited to blank); (c) all readers already filter `""` (`SignupAccumulator.hydrate:154`, `ClientProfilePersonalInfo.locationLabel`, `SignupReviewViewModel.formatLocation`).

### R2. Delete Account copy audit (D-08/D-09, SET-06)
Source of truth read this session: `accountCascade.js` `purgeAndLockAccount` (lines 241-453) and `account.controller.js`.

| Claim | Verdict | Evidence |
|-------|---------|----------|
| Profile details deleted (name, photo, bio, location) | TRUE, with nuance: name becomes "Deleted user", email replaced. | F1: `email: \`deleted+${userId}@deleted.invalid\`, first_name: 'Deleted', last_name: 'user', avatar_url: null, bio: null, job_title: null, company: null, city: null, state_province: null, country_code: null, timezone: null` (:246-262). F2 also nulls `education`, `meeting_url`. |
| Devices deleted | TRUE | F6 `device_tokens` delete (:319-327) |
| Notifications and preferences deleted | TRUE | F7 `notifications`, F8 `notification_preferences` (:329-347). Also browsing history: F9 `discovery_interactions` both directions. |
| Uploaded files deleted | TRUE but narrow and best-effort | Step I `deleteUserAvatars` reaps objects under `{userId}/` in the avatars bucket; failure leaves `files_removed: null` and "files must be reaped manually" (:436-450). Say "profile photos". |
| Past bookings kept, shown as from "Deleted user" | TRUE | Bookings rows are not deleted; F3/F4 scrub notes (`client_notes`, `expert_message`, `expert_private_note`, `key_takeaways`, `internal_note`, `proposed_note`, `decline_reason_text`, `meeting_url`). Names come from the tombstoned profile. |
| Messages kept; reviews kept; reports kept | TRUE | `// ── reviews, messages, reports: NO DML (Pitfall 7 / D-06/D-07/D-09) ──` (:387). Only the chat-list preview is replaced by `[Message from deleted account]` where the user sent last (F5). |
| Shown as "Deleted user" to the other person (D-09) | TRUE for reviews and chat partner | Reviewer name is built from `first_name`/`last_name` (`publicProfile.controller.js:246`); chats batch-fetch `first_name, last_name, avatar_url` (`chats.controller.js:195`). |
| Payment records kept | TRUE (no DML on payment tables in the cascade) | Reason ("for legal/accounting purposes") is **not in code**: do not state a reason ([ASSUMED] policy). |
| **Original claim "payment details ... permanently removed"** | **FALSE** | No code in the cascade detaches saved cards; `detachPaymentMethod` is only reached from `paymentMethods.controller.js:304` (user removes a card) and the clone service. Saved cards stay with the payment provider. |
| Not mentioned in the draft but true | -- | Unanswered requests the user sent (`pending_approval`) are cancelled and any card hold is voided (`cancelActiveBookingsForUser`, client side, all `ACTIVE_STATUSES`, `retrievePI` -> `cancelPI` for uncaptured). Account is locked (ban + Redis denylist) and the email address is released for reuse (`updateUserById ... email: deleted+...`). Expert public profile 404s (`publicProfile.controller.js:66,386` filter `deleted_at`). |

**Proposed final strings** (plain English, for `AccountDeletionCopy` and the Android todo, D-11):
- Permanence line: "Deleting your account is permanent and can't be undone."
- Upfront (D-10): "Before you delete, cancel or finish any upcoming sessions. Requests that haven't been answered yet are cancelled for you and any hold on your card is released."
- Deleted: "Your name, photo, bio and location, your devices, notifications and preferences, and your profile photo files."
- Kept without your personal details: "Your past bookings stay on record, shown as from "Deleted user". Your private notes on them are erased."
- Kept: "Messages and reviews you've written stay visible to the other person, shown as from "Deleted user". Payment records are kept."
- Optional fourth line, **needs user confirmation (Open Question 1):** "Saved cards are not removed by deleting your account." Accurate per code; a privacy-review call.

### R3. Self-delete 409s and routing (D-10)
- Raised by `assertNoBlockingBookings` in **both** `POST /user/account/delete-request` (step 1, `account.controller.js:232-233`) and `DELETE /user/account` (step C, `:348-349`; the token is already burned there).
- Codes and server messages [VERIFIED: account.controller.js:98-102, 105-109, 150-154]:
  - `EXPERT_HAS_UPCOMING_BOOKINGS` -- 'You have upcoming bookings. Please complete or cancel them before deleting your account.' (expert side, `confirmed`/`pending_approval`/`pending_reschedule`/`in_progress`, future start)
  - `SESSION_IN_PROGRESS` -- 'A session is currently in progress or imminent. Please wait until it ends before deleting your account.' (either side, live or starting within 15 min)
  - `CLIENT_HAS_UPCOMING_BOOKINGS` -- 'You have upcoming sessions booked. Please cancel them before deleting your account.' (client side, `confirmed`/`pending_reschedule`; `pending_approval` does NOT block)
- iOS `ErrorCode` has `expertHasUpcomingBookings = "EXPERT_HAS_UPCOMING_BOOKINGS"` and `sessionInProgress       = "SESSION_IN_PROGRESS"` but **no** `CLIENT_HAS_UPCOMING_BOOKINGS` [VERIFIED: ErrorCode.swift:41,42; whole file read]. Add `case clientHasUpcomingBookings = "CLIENT_HAS_UPCOMING_BOOKINGS"` and a decode test (unknown codes decode to nil today, so the app currently cannot branch on it).
- Current handling: `DeleteAccountViewModel.handle(requestError:)` default branch shows `decodeStandardMessage(from:) ?? "Couldn't verify your password..."` in the "Couldn't delete account" alert (`DeleteAccountViewModel.swift:126-142`). `handle(deleteError:)` has no 409 case (falls to the same default). So the server text shows, with no action.
- Plan: decode `StandardErrorResponse.code` in both handlers; `AccountDeletionBlocker(code:)` -> own copy (final strings go to the Android todo) and `showsBookingsAction(mode:)`. Surface as an alert with "View my bookings" and "OK".
- **Routing:** the client shell provides `\.showMyBookings` (`HomeClientView.swift:96`); it resets the source tab (Profile) and selects Bookings via `HomeShellExit.plan(.viewMyBookings, selectedTab:)`. The expert shell provides **no** equivalent (`HomeNavigationPath.swift:205` doc: "consumers on the expert shell get `nil`"). Add `showMyBookings` to `HomeExpertView` (select `.bookings`, reset `profilePath` and `bookingsPath`); `MakeABookingView` is the only other consumer and exists only in the client shell. `DeleteAccountView` reads `@Environment(\.showMyBookings)`; the env propagates through the pushed `AccountSecurityView`.
- **Edge:** `EXPERT_HAS_UPCOMING_BOOKINGS` for a dual-role user who opened Delete from the *client* shell concerns *expert* bookings, which the client Bookings tab does not list. Rule: show the bookings action only when the blocker's side matches the active mode (`expert` blocker with `currentMode == .expert`; `client` blocker with `.client`; `SESSION_IN_PROGRESS` always). Otherwise message-only, e.g. "Switch to Expert mode to cancel or finish them."

### R4. Cancellation Policy copy vs backend (D-12)
Backend rule [VERIFIED: ../ClickMe2026 Backend/src/utils/refund.js:36-47 and clientBooking.controller.js:925-980 read]: `computeRefundAmountMinorUnits` returns the full `amount_paid_minor_units` only when `hoursUntilStart > 24`, else `0` (exactly 24 h = 0). An uncaptured hold (`requires_capture` etc.) is voided at any time with no refund round-trip. Capture happens at session end (`expirePastSessions.js` Sweep C, `end_time+15min`, eligible: completed / in_progress / missed with client-sole-no-show); a client-sole-no-show is charged, an expert no-show voids the hold. The copy was rewritten on 2026-11-12 (`510e7cb`) to match the published Terms and the backend FAQ migration `20261113000200_faq_content_match_terms.sql`.

| Card text | Matches backend? |
|-----------|------------------|
| Deadlines: ">24 h: Not charged, or a full refund if already charged" | YES |
| Deadlines: "Within 24 h: Not charged, but no refund if already charged" | YES |
| Deadlines: "After the session ends: Can't be cancelled; charged if the session went ahead" | YES for the app (`UpcomingActionPolicy.canShowCancel` requires `end > now`, `UpcomingActionPolicy.swift:37-39`); the backend itself has no end-time guard (K12), so say "in the app". Acceptable as is. |
| Refund Eligibility: Not Charged / Full Refund / No Refund (incl. "expert joins and you don't") | YES (Sweep C eligibility above) |
| "The same applies if the expert cancels or doesn't show up" | YES for an uncaptured hold. Says nothing about a *captured* booking cancelled by the expert, which is exactly the open Phase 6 question (E13/Q2). **Do not add or change anything about it.** |
| HowToInitiate step 3: "Click on the 'Cancel Booking' button." | **MISMATCH** -- the button label is "Cancel" (`UpcomingBookingSecondaryActions.swift:62` `Text("Cancel")`). Fix to "Tap Cancel." |
| HowToInitiate intro: "...at any time before the session starts." | **MISMATCH** -- Cancel is offered until the session *ends* (`end > now`) and the Deadlines card says so. Change to "until the session ends". |
| Adjacent, not in the policy view: `CancellationConfirmCard` footnote "Refunds typically appear in your account within 3–5 business days." | **Likely mismatch** -- the same backend FAQ migration removed the "5-10 business days" claim ("your bank decides how long they take"). Shown only for refund cases (`CancelRefundPreview.showsRefundFootnote`). Reword to "Your bank decides how long a refund takes to appear." and keep it with the link work since the link lands next to it. |

Where the link goes: `ClientCancellationView.confirmStepContent` (`ClientCancellationView.swift:201-232`), between `CancellationConfirmCard` and `CancellationActionButtons`. The view is a destination on **two different stacks**: `HomeRoute.cancelBooking` in the shells (`HomeClientView.swift:363`) and `BookingRoute.cancelBooking` in `MyBookingsView` (`:139`). Use a local `.navigationDestination(isPresented: $showPolicy) { CancellationPoliciesView() }` plus a small text button "Cancellation policy"; it pushes onto whichever tab stack owns the cancel flow (Phase 2 D-04), and Back returns with the VM state intact (`@StateObject`). The callbacks `onKeepBooking: pop()` / `nav.pop(2)` count from the cancel screen, so they are unaffected because the policy page is popped before either button can be tapped. Fallback if the local destination misbehaves on the `NavigationPath` stack: a sheet with its own `NavigationStack` and a Done button ([ASSUMED] A5, check on device).

### R5. Mode-switch call sites, Splash, push, `.signupSetup`, Android reference (D-01..D-03)
`setMode(` call sites in `ClickMe2026/` [VERIFIED: grep]: `UserManager.swift:519` (definition); `SplashViewModel.swift:115`; `LoginView.swift:222` (publish -> `.client`), `:288` (login landing); `HomeExpertView.swift:116` (push), `:248` (`.modeSwitch` route); `ExpertProfileHomeScreen.swift:261`; `HomeClientView.swift:172` (push), `:332` (`.modeSwitch` route); `ClientProfileHomeScreen.swift:249`. Push plans: `PushRouter.swift:70` (`switchToMode`), set at `:122-129`.

- **Push planner already fails closed**: `canUseExpertMode` requires the expert role **and** `setupCompleted == true` (nil = no), otherwise the plan is `.notificationsList` with no switch (`PushRouter.swift:101-103,127-131`; fetches the profile once, `:213-224`). So a push never reaches an incomplete dashboard today. Recommendation: leave the planner untouched (it is tested in `PushRoutePlannerTests` and deliberately fail-closed for a specific screen), and route only its final `setMode` through the gate for the single-door rule; one extra GET is harmless. Do **not** open the hub from a push.
- **Splash**: `SplashViewModel.start()` already returns `.setupIncomplete` for an expert whose `setup_completed == false` and fails open on error (`:77-84`, `:119-125`). Changes: skip the lookup when deferred (`ExpertModeGate.shouldCheckSetupAtLaunch`), set `setupCheckPending` on a failed lookup or unknown roles, call the shared check instead of a private copy.
- **`.signupSetup`**: `LoginView(startAtSignupSetup: true, hydrateFrom: userManager.expertProfile)` seeds `path` with `SignupRoute.overview`, with the login form as stack root (`LoginView.swift:81-92`). The hub is therefore the second screen: its back chevron returns to a Login form for a user who is logged in. Android's hub is the setup root with no back arrow and has Not now + overflow Log out (`SignupOverviewScreen.kt:84-86,152-157`). Do the same: hide the back button on Overview, add a "Not now" toolbar button that calls `UserManager.deferSetup()` then `onSuccess(.client)`.
- **Mode mirroring** (`ClickMe2026App.swift:24-35`): only mirrors on home routes, and `isLoggedIn == false` forces `.login` from `.signupSetup` too. The gate keeps `currentMode` unchanged when it opens the hub, so neither observer fights it. Leaving a shell destroys its tab state; after Not now the user lands on a fresh Explore tab (same as Android).
- **Android reference** [VERIFIED: UserManager.kt:383-437, AppViewModel.kt:194-225]: `requestModeSwitch` clears the deferral first, treats a failed lookup as complete and marks the check pending, persists Expert only on `Home`; `deferSetup` sets Client + persisted deferral; `completeSetup` sets Client + clears; `recheckSetupIfPending` role-guards with `UserRole.Expert !in roles && currentMode != Expert -> clear, no request`; the app calls it on every STARTED but only on a home route; `switchMode` cancels an in-flight switch and checks `callGuard.attempt(RestrictedAction.SwitchModes)`.
- **Foreground re-check**: iOS has none today (scenePhase handlers in both shells only call `consumePendingPush`, `HomeClientView.swift:157`, `HomeExpertView.swift:100`). D-02 promises one. Minimal port: `UserManager.setupCheckPending` (set by Splash/Login on a failed or skipped lookup), `recheckSetupIfPending() async -> Bool` with `ExpertModeGate.shouldRecheckInBackground`, called from `ClickMe2026App` on `scenePhase == .active` when `route` is a home route. Open Question 3.
- UX detail: `ModeSwitchView` calls `onConfirm(mode)` then `dismiss()` immediately (`ModeSwitchView.swift:75-76`), so a slow lookup shows nothing. Add a short busy state (disable the cards while a switch is in flight) and make the gate re-entrancy safe (cancel the previous request, like Android).

### R6. Port `feature/remember-login-email` (D-14)
`b0629d9` changes 4 files (`UserManager.swift` +31, `LoginViewModel.swift` +7/-3, `DeleteAccountViewModel.swift` +8/-3, new `RememberedLoginEmailTests.swift` +124); the merge-base is `370fcb4`, 407 commits behind current main [VERIFIED: `git show b0629d9 --stat`, `git rev-list --count 370fcb4..main`]. Port by hand:

1. `UserManager`: add `@ObservationIgnored private(set) var lastLoginEmail: String?`, Valet key `lastLoginEmailKey = "lastLoginEmail"`, `rememberLoginEmail(_:)` (trim, ignore empty, store) and `forgetLastLoginEmail()`. Read it in `init()` next to the token read (`UserManager.swift:142`).
2. **Placement conflicts with current code:** `login()` now awaits `retryPushCleanupIfNeeded().value` before `apply(loginData:)` (`:188-196`) -- call `rememberLoginEmail(email)` **after** `apply`, as in the branch. `signup(email:password:role:)` is the same shape (`:223-235`); the branch's old `username:` argument is gone.
3. **Do not touch `clearLocalSession()`** (`:439-464`). Every sign-out path funnels into it (user `logout()`, `forceLogout()`, suspension handler, rejected refresh) and the email must survive all of them. Phase 4's `SuspensionNotice` / `AutoLoginOutcome` need no change; Login after a suspension will simply show the prefilled email under the one-shot alert.
4. `LoginViewModel.init(email: String? = nil, ...)` with `self.email = email ?? userManager.lastLoginEmail ?? ""`. Existing explicit `email: ""` callers (the five previews in `LoginView.swift:387-427`) keep working; no test constructs `LoginViewModel` today.
5. `DeleteAccountViewModel`: add `private let userManager: UserManager` + `userManager: UserManager = .shared` init parameter; call `userManager.forgetLastLoginEmail()` after the DELETE succeeds, before `step = .deleted` (`:120-121` region today ends with `withAnimation { step = .deleted }`).
6. **Tests:** port the suite, with these changes: remove the two `userManager.logout()` calls (`prefillsAfterLogout`, `deletionForgetsEmail`). Current `logout()` is async and runs `Messaging.messaging().deleteToken()` plus a session wipe on the shared singleton (`UserManager.swift:375-393`); it would race the test and touch Firebase/Keychain. Replace with: remember -> `LoginViewModel()` prefills (and the `defer { forgetLastLoginEmail() }` cleanup); add a grep gate that `clearLocalSession` does not reference `lastLoginEmailKey`; deletion test asserts `userManager.lastLoginEmail == nil` and `LoginViewModel().email == ""` straight after `confirmDeletion()`. The suite stays `.serialized` (shared Keychain). `APITestFactory.make { request in ... }` and `DeleteAccountViewModel(step:selectedReason:password:api:)` still match the branch's usage.
7. Ordering vs D-15: edit `DeleteAccountViewModel.swift` in this plan first (init + success tail, ~6 lines), then SET-06's 409 handling, then SET-03/SET-06 view edits. SET-03 and SET-06 both edit `DeleteAccountView.swift`, so keep them in one plan or sequence them.
8. Privacy: the email is PII in the Keychain (`.whenUnlocked`), never logged. Android follow-up todo: branch `0c9ecc55`.

### R7. Location formatting and the province requirement (D-05, D-06)
Every place that formats a location in iOS today [VERIFIED: grep of `city`/`country`/`stateProvince` across Views, Model, Utils]: (1) `SignupReviewViewModel.formatLocation` (`:105-111`) -- already trims and drops empties, correct for an empty province; (2) `ClientProfilePersonalInfo.locationLabel` (`:53-58`) -- drops `nil` and `""`, **not** whitespace-only values. There is **no** expert-card or expert-profile location rendering in iOS (the public expert payloads decoded by the explore/profile models carry no city or province). So D-06's audit reduces to making both formatters share one helper (`LocationFormatter.format(city:province:country:)`: trim, drop empty, join with ", ") with a test for empty/whitespace/`nil` province. Note `ClientProfilePersonalInfo` receives `country` as the alpha-3 code (`UserProfileData.swift:12-13`), so it can show "CAN"; map through `Countries.find(byCode:)?.name` as the review formatter does (small improvement while there, optional).
Province requirement sites: `SignupAccumulator.swift:96` (`isReadyToPublish`) and `:119` (checklist `basicInfo`); `SignupBasicInfoView` placeholder "Province/State" stays but is optional (consider "Province/State (optional)" copy). `ExpertProfileSettingsView.swift:154` and `ClientProfileSettingsView.swift:145` are free-text fields with no requirement.

### R8. Inventory evidence still valid? Test seams
| Row | Inventory claim | Status now |
|-----|-----------------|------------|
| S1 | `SignupAccumulator.swift:92-100` | VALID (now `:93-101`; no `avatarUrl` in `isReadyToPublish`) |
| S2 | province `:96,119` | VALID (D-05 removes) |
| S3 | `:38,141-181`; Verify VM `:104,114`; `checkEmailVerified()` no callers | VALID |
| S4 | tags/languages alphabetical | VALID (`SignupTagsViewModel.swift:103-105`, `LanguageSelectionViewModel.swift:84-87`) |
| S5 | `SignupAccumulator.swift:197` | VALID |
| S6 | `ProfileAvatarRing.swift:57`, VM `:83,156` | VALID |
| S7 | `HomeClientView.swift:243-245` etc. | **STALE line numbers**; real sites in R5 |
| T1 | `ClientProfileSettingsViewModel.swift:261-263`, `:194` | VALID. **Worse than described:** the VM snapshot (`:194`) includes languages but the body omits them, so a language-only edit can show the "saved" checkmark with nothing saved; the *view's* `autoSaveSnapshot` (`:178-184`) excludes languages. Expert VM has the identical gap (`ExpertProfileSettingsViewModel.swift:266-269`, `:330-333`). |
| T2 | `HelpView.swift:20` `support@clickme.app` | **FIXED** on main: `private static let supportEmail = "clickmeapp@uptrendinvestments.net"` (`cae4090`, 2026-11-12). Remaining: regression test, shared constant with `SuspensionNotice.message`, tick REQUIREMENTS. |
| T3 | `DeleteAccountView.swift:35,95`, `AccountSecurityView.swift:207` | VALID |
| T4 | `NotificationSettingsView.swift:59`, VM `:90` | VALID |
| T5 | `FeedbackViewModel.swift:158` | VALID (`guard !trimmedDetails.isEmpty`, `:112-115`) |
| T6 | `DeleteAccountWarningHeader.swift:22` | VALID |
| T7 | both screens unreferenced | VALID (R9; policy view only referenced by its own preview) |

**Test seams** (Swift Testing, `@MainActor @Suite`, `.serialized` for `MockURLProtocol`): `APITestFactory.make { request in (HTTPURLResponse, Data) }` for request-body assertions via `MockURLProtocol.recordedRequests` and `URLRequest+Body.swift`; VMs take `api:` (all the ones in scope do). Gaps to close with small seams: (a) `ClientProfileSettingsViewModel.previewSeed` builds with default `.shared` api -- add an `api:` parameter or use `init(userManager:api:)`; its `apply(profile:)` is private (hydrate via a seeded `UserManager.profile` is not possible for the shared singleton), so add an internal `hydrateForTesting`-style entry or make `performAutoSave` `internal` plus an injectable debounce. (b) `ExpertProfileSettingsViewModel.forceLoad` calls `userManager.refreshExpertProfile()` on the real singleton; test `performAutoSave` directly instead of `load()`. (c) `NotificationSettingsViewModel`: make debounce injectable. (d) `UserManager` cannot be instantiated; keep decisions in pure types and `UserDefaults(suiteName:)`-backed stores. Existing patterns to copy: `PushRoutePlannerTests`, `AutoLoginOutcomeTests`, `HomeShellExitTests`, `SuspensionNoticeTests`.
`SignupSmokeTests` asserts `accumulator.isReadyToPublish` with no avatar (`:152`, `:178`) and expects `missing_fields` to contain `profile_image_url` (`:162`); those suites are excluded from runs and already do not compile (STATE.md "Before release"), so update their expectations only if touched.

### R9. Safe-delete list for `ReadyToStartCallView` (D-13)
Unreferenced from outside `Views/Screens/Call/Ready/` [VERIFIED: grep for `ReadyToStart` over `ClickMe2026`, `ClickMe2026Tests`, `ClickMe2026UITests`]. Delete the whole folder: `ReadyToStartCallView.swift` (incl. its private `LiveFetchReadyToStartCallBootstrap` preview helper), `ReadyToStartCallViewModel.swift`, `Subviews/` (`ReadyToStartCallBrand`, `Headline`, `JoinButton`, `LinkCard`, `MessageButton`, `SkypeIcon`, `SupportRow`). Everything else they touch is shared and stays: `api.joinCall(id:)` (`ClickMeAPI+Call.swift:13`, used by the call stack), `getExpertBookings`, `LoadState`, `PreviewNavHarness`, `PreviewSecrets`, `ExternalMeetingProvider`/`SkypeLinkActions` (live in `Call/Calling/`, untouched). No `project.pbxproj` entries exist (synchronized group). Strings only used there (e.g. "Ready to join your call", "Having trouble?", "Contact support.", "Preparing meeting link…") may linger in `Localizable.xcstrings` as stale; do not hand-edit the dirty catalog. Verify with `xcodebuild build` and a `grep -rn ReadyToStart ClickMe2026 ClickMe2026Tests` = 0 gate.

## Common Pitfalls

### Pitfall 1: Hub opened over a stale `expertProfile`
**What goes wrong:** the hub hydrates once in `LoginView.init`. If the route is built before the gate's lookup completes, fields are blank.
**Why:** `.signupSetup` reads `userManager.expertProfile` at view construction.
**How to avoid:** set `setupHubRequested` only after `refreshExpertProfile()` returned (the gate does). On a failed lookup the gate enters Expert (fail open), so a nil profile never opens the hub.
**Warning signs:** hub shows empty name/city after a switch.

### Pitfall 2: Persisting Expert then bouncing
**What goes wrong:** `setMode(.expert)` before the check leaves a stored `.expert`; a crash in the hub resumes into an incomplete dashboard.
**How to avoid:** persist only on `.enterExpert`; `deferSetup`/`completeSetup` always write `.client`.

### Pitfall 3: Deferral leaks across accounts
**What goes wrong:** a persisted `setupDeferred` survives logout and suppresses the setup check for the next login.
**How to avoid:** clear in `clearLocalSession()` (all logout paths) and test it; the same function must keep `lastLoginEmail`.

### Pitfall 4: Gate promotes a client-only account in the background
**What goes wrong:** foreground/Splash lookups call `GET /expert/profile`, which runs `ensureExpert` and silently makes a client an expert (`middleware/ensureExpert.js:65-106`).
**How to avoid:** Splash/Login already gate on `roles.contains(.expert)`; the new foreground re-check must use `shouldRecheckInBackground` and make no request otherwise. Only the explicit switch may look up for a non-expert (D-04).

### Pitfall 5: Language full-replace deletes custom languages
**What goes wrong:** sending only `language_ids` removes `custom_label` rows.
**How to avoid:** always send `custom_languages` with `language_ids`, and only send the `languages` group when the selection changed.

### Pitfall 6: `LanguageSelectionViewModel` and a catalog that is not loaded yet
**What goes wrong:** `orderedSelection` maps through `allLanguages`; before `load()` finishes a pre-selected language has no catalog entry and vanishes from the output.
**How to avoid:** build the ordered output from `order` plus the initial `LanguageItem`s (keep labels from `initialSelection` as a fallback), not only from the loaded catalog.

### Pitfall 7: Hiding the hub's back chevron strands the user
**What goes wrong:** without back or Not now the only exit is publish.
**How to avoid:** ship Not now in the same plan as the hidden back button; optionally mirror Android's overflow Log out.

### Pitfall 8: Notification test passes vacuously
**What goes wrong:** with all-`true` defaults and a server returning all `true`, the view's `.onChange` never fires, so a naive test never reproduces T4.
**How to avoid:** seed one `false` row in the stubbed GET and assert zero PATCH requests after load plus debounce; then flip a toggle and assert exactly one.

### Pitfall 9: Square crop fed by an unoriented image
**What goes wrong:** HEIC/portrait photos carry EXIF orientation; `cgImage.width/height` ignore it, so the "short side" and the crop are wrong.
**How to avoid:** bake orientation first (`UIGraphicsImageRenderer` redraw) and test with a rotated synthetic image.

### Pitfall 10: Xcode rewrites `Localizable.xcstrings`
**What goes wrong:** every build dirties the catalog (already modified in the tree), and a broad `git add` commits unrelated churn.
**How to avoid:** stage by explicit paths; review the catalog diff for only intended strings.

### Pitfall 11: Delete-flow 409 after the token is burned
**What goes wrong:** `DELETE /user/account` can return a 409 after the single-use token was consumed.
**How to avoid:** `confirmDeletion()` already mints a fresh token on every attempt; map the 409 in `handle(deleteError:)` too and keep the user on the feedback step.

## Code Examples

### Language body (SET-01)
```swift
// Source: schemas/userProfile.schema.js:59-62 (languages.{language_ids,custom_languages}), controller :95-117 (full replace)
func languagesGroup(items: [LanguageItem], customs: [String], changed: Bool) -> UpdateUserProfileRequest.Languages? {
    guard changed else { return nil }               // never rewrite languages on a text edit
    return .init(languageIds: items.map(\.id), customLanguages: customs)
}
```

### Blocker mapping (D-10)
```swift
// Source: account.controller.js:98-102,105-109,150-154; ErrorCode.swift (+ new clientHasUpcomingBookings)
nonisolated enum AccountDeletionBlocker: Equatable {
    case expertUpcoming, clientUpcoming, sessionInProgress

    init?(code: ErrorCode?) {
        switch code {
        case .expertHasUpcomingBookings: self = .expertUpcoming
        case .clientHasUpcomingBookings: self = .clientUpcoming
        case .sessionInProgress:         self = .sessionInProgress
        default: return nil
        }
    }
    /// True when the active shell's Bookings tab lists the blocking bookings.
    func offersBookingsAction(in mode: AppMode) -> Bool {
        switch self {
        case .expertUpcoming: return mode == .expert
        case .clientUpcoming: return mode == .client
        case .sessionInProgress: return true
        }
    }
}
```

### Request-body assertion (province clear regression, R1)
```swift
// Source: pattern of ClickMe2026Tests/Support (APITestFactory, MockURLProtocol.recordedRequests)
@Test("an emptied province is sent as an empty string, never null")
func provinceClearIsEmptyString() async throws {
    let api = APITestFactory.make { req in (okResponse(req), Self.profileJSON) }
    var body = UpdateUserProfileRequest()
    body.location = .init(city: "Toronto", stateProvince: "", countryCode: "CAN")
    _ = try await api.updateUserProfile(body)
    let sent = try #require(MockURLProtocol.recordedRequests.last?.bodyString)   // URLRequest+Body.swift
    #expect(sent.contains("\"state_province\":\"\""))
    #expect(!sent.contains("null"))
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Help support address `support@clickme.app` | `clickmeapp@uptrendinvestments.net` | `cae4090`, 2026-11-12 | SET-02 already satisfied in code |
| Cancellation copy promising 50% partial refund / 5-7 day window | Hold-until-session-end model, binary 24 h rule | `510e7cb`, 2026-11-12 | D-12 audit finds only 3 small mismatches |
| Delete = "all data removed" | Tombstone + keep bookings/messages/reviews/payments | accountCascade (backend quick 261016-m5y, 261017-kh8) | Copy must change (SET-06) |
| Backend gate `EXPERT_SETUP_REQUIRED` (BACK-13) | iOS-side gate until a later backend decision | wave 3c dropped 2026-11-08 | The iOS gate is the only protection this release |

**Deprecated/outdated:** the `LanguageEditorSheet` hard-coded label list (replaced by the catalog picker); `DeleteAccountPauseCard` (no backend route).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No DB CHECK forbids `profiles.state_province = ''` (only the phase-3 migration was read) | R1 | A clear would 500; settings already send `""` today with no reported error, so low risk |
| A2 | Payment records are kept for legal/accounting reasons -- the code only shows no DML; the **reason** is a policy statement | R2 | Copy states a reason the business may not hold; recommended copy states no reason |
| A3 | Apple App Store guideline 5.1.1(v) requires accurate account-deletion disclosure (CONTEXT says "accurate enough for App Store privacy review") | R2 | Low |
| A4 | `Saved cards are not removed` wording is acceptable to the product owner | R2 / Open Question 1 | Privacy/legal copy needs the user's confirmation |
| A5 | `.navigationDestination(isPresented:)` inside a destination view works on stacks bound to `NavigationPath` (iOS 18) | R4 | Link would not push; fallback is a sheet |
| A6 | `@Environment(\.scenePhase)` read in the `App` struct fires `.active` reliably for the foreground re-check | R5 | Re-check never runs; fallback: do it from the shells' existing `scenePhase` handlers |
| A7 | Backend accepts a 1024-px square JPEG for `POST /user/profile/avatar` (limits not read) | Pattern 7 | Upload rejected; check multer limits or lower `maxSide` |
| A8 | The expert Bookings tab is the right target for `EXPERT_HAS_UPCOMING_BOOKINGS` | R3 | User lands on a list not showing the blocker; message-only fallback is specified |

## Open Questions

1. **Saved-card wording in Delete Account.**
   - Known: the cascade never detaches saved cards (R2); original copy claimed payment details were removed.
   - Unclear: whether the product wants to state it, and whether a detach should be added to the backend (out of scope here).
   - Recommendation: ship the three groups without any card claim; add the optional fourth line only if the user approves. Log the backend question as a todo.

2. **Delete blocker routing for a dual-role user in the wrong shell (R3 edge).**
   - Recommendation: message-only unless the blocker's side matches the active mode (rule in R3).

3. **Foreground setup re-check scope.**
   - Known: D-02 promises a foreground re-check; iOS has none; it adds `setupCheckPending` state and an App-level `scenePhase` hook.
   - Recommendation: include it as its own small plan (after the gate), so it can be cut without touching the gate.

4. **Hub chrome.** Recommendation: hide the back chevron on Overview, add Not now; Log out overflow is optional (Not now already reaches Profile > Log out).

5. **Signup Basic Info `clearProvince` parity (R1b).** Recommendation: include; D-07 names only the settings screens but the same bug exists in signup and Android fixed it (WR-04).

6. **SET-01 picker replacement.** Recommendation: reuse `LanguageSelectionView` in both settings screens and delete `LanguageEditorSheet` if nothing else uses it (grep shows only the two settings views).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / `xcodebuild` | all builds and tests | yes | Xcode 26.5 (17F42) | -- |
| iOS Simulator "iPhone 17" | test destination | yes (3 devices with that name across runtimes; `OS=latest` selects one as in Phase 4) | -- | use the device UUID if ambiguous |
| `swiftformat` | optional formatting | yes (`/opt/homebrew/bin/swiftformat`) | -- | -- |
| `swiftlint` | CI lint | no (CI only: `cirruslabs/swiftlint-action`) | -- | review `.swiftlint.yml` rules by hand |
| Backend repo (read-only) | contract checks | yes (`master` at `35bc749`) | -- | -- |
| Real iPhone | UAT checklist | not checkable here | -- | device UAT remains a human step (deferred items from Phases 2-4 must also run before Phase 8) |

**Missing dependencies with no fallback:** none for automated work.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests` |
| Config file | `ClickMe2026/AllTests.xctestplan` (language en, region GB; `parallelizable: false`) |
| Quick run command | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| Full suite command | same, with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests -collect-test-diagnostics never` (smoke suites hit production; never run) |
| Build gate | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` -> `BUILD SUCCEEDED`, no new warnings in touched files (before/after `comm -13` diff as in Phase 4 plans) |
These are the commands Phase 4 actually ran [VERIFIED: 04-VALIDATION.md lines 24-27 and 04-10-PLAN.md `<automated>` blocks]. A run counts only with a non-zero test count; `MockURLProtocol` suites are `.serialized`; one suite per `xcodebuild`; rerun once on a simulator-busy error; about 180 s per single-suite run.

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command (`-only-testing:ClickMe2026Tests/...`) | File Exists? |
|--------|----------|-----------|--------------------------------|-------------|
| SIGN-01 | Not ready without avatar; ready with; `missingForPublish` lists photo, never verify-email | unit | `SignupAccumulatorTests` | no, Wave 0 |
| SIGN-02 | Status `verified:true` seeds `emailVerified`; failure leaves it; never downgrades | unit (stubbed) | `SignupEmailVerifiedSeedTests` | no, Wave 0 |
| SIGN-03 | Language and tag picker output and publish payload keep tap order; initial order kept | unit | `SelectionOrderTests` | no, Wave 0 |
| SIGN-04 | `"ca "` -> `CAN` in publish body; unknown code = not ready | unit | `SignupAccumulatorTests` | no, Wave 0 |
| SIGN-05 | Crop size and centre pixel for zoom 0, 0.5, 1; portrait/rotated source; max side | unit | `ProfilePhotoCropperTests` | no, Wave 0 |
| SIGN-06 | Gate truth table (incomplete -> hub, failed -> enter, complete -> enter, deferred, role guard); deferral store set/clear/logout | unit | `ExpertModeGateTests`, `SetupDeferralStoreTests` | no, Wave 0 |
| SIGN-06 | No `setMode(` outside `UserManager.swift` | grep gate | `! grep -rn 'setMode(' ClickMe2026 \| grep -v Managers/UserManager.swift` | n/a |
| D-05/D-06/D-07 | Province optional; `LocationFormatter` cases; `""` sent on clear | unit | `SignupAccumulatorTests`, `LocationFormatterTests`, `ProfileLanguagesSaveTests` (body test) | no, Wave 0 |
| SET-01 | Client and expert body carry `languages.language_ids` + `custom_languages`; omitted when unchanged; customs preserved | unit (stubbed) | `ProfileLanguagesSaveTests` | no, Wave 0 |
| SET-02 | `HelpView` support address equals `clickmeapp@uptrendinvestments.net`; one shared constant with `SuspensionNotice` | unit + grep | `SupportContactTests`; `! grep -rn 'support@clickme' ClickMe2026` | no, Wave 0 |
| SET-03 | No Pause Account code or copy | grep gate | `! grep -rniE 'PauseCard\|onPauseAccount\|Pause Account' ClickMe2026` | n/a |
| SET-04 | Load with one server `false` -> 0 PATCH; toggle -> exactly 1 | unit (stubbed) | `NotificationSettingsAutoSaveTests` | no, Wave 0 |
| SET-05 | 0, 9, whitespace-padded 9 chars -> no request; 10 -> request | unit (stubbed) | `FeedbackValidationTests` | no, Wave 0 |
| SET-06 | `ErrorCode` decodes `CLIENT_HAS_UPCOMING_BOOKINGS`; blocker mapping and `offersBookingsAction`; copy constants contain no "bookings ... permanently removed" claim; 409 on both steps shows the message | unit | `AccountDeletionBlockerTests`, `DeleteAccountViewModelTests` | no, Wave 0 |
| SET-07 | Policy view linked from `ClientCancellationView`; `ReadyToStart*` gone | grep gate + build | `grep -c 'CancellationPoliciesView()' '.../ClientCancellationView.swift'` >= 1; `grep -rn ReadyToStart ClickMe2026 ClickMe2026Tests` = 0; build gate | n/a |
| T8 | remember/trim/prefill/explicit wins/deletion forgets/failed deletion keeps | unit (stubbed, `.serialized`) | `RememberedLoginEmailTests` | ported from `b0629d9`, no `logout()` calls |
| Device | Gate over a real switch, Not now, deferral across relaunch, hub back chevron, crop result on a real photo, Mail opens, delete copy readable | manual UAT | `05-DEVICE-UAT-CHECKLIST.md` (Phase 4 format) | Wave 0 |

### Sampling Rate
- **Per task commit:** the single suite for the touched helper (quick run command).
- **Per wave merge:** every suite touched in the wave plus the build gate, plus the Phase 2-4 regressions that touch this area: `PushRoutePlannerTests`, `AutoLoginOutcomeTests`, `SuspensionNoticeTests`, `HomeShellExitTests`, `HomeNavigationPathTests`, `ClientCancellationViewModelTests`, `CancelRefundPreviewTests`, `UpcomingActionPolicyTests`.
- **Phase gate:** full suite green, grep gates, then `/gsd-verify-work` and the device checklist.

### Wave 0 Gaps
- [ ] New suites listed above (all `ClickMe2026Tests/`; no pbxproj edit needed).
- [ ] Seams: injectable debounce (`NotificationSettingsViewModel`, both profile VMs), `api:` on `ClientProfileSettingsViewModel.previewSeed`, an internal hook to run `performAutoSave` in tests, `userManager:` param on `DeleteAccountViewModel`.
- [ ] `05-DEVICE-UAT-CHECKLIST.md`.
- [ ] Todo files for the Android follow-ups (D-11, D-12, D-16): delete-account strings (final text from `AccountDeletionCopy`), `CLIENT_HAS_UPCOMING_BOOKINGS` message, remember-email `0c9ecc55`, cancellation-policy link.
- [ ] REQUIREMENTS.md: record BACK-13 as deferred with the REL-02 reason (D-04); tick SET-02 once its guard test lands.

## Security Domain

`security_enforcement` is enabled (absent = enabled; `security_asvs_level: 1`).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (delete re-auth, login prefill) | Delete keeps password re-verification (`POST /user/account/delete-request`); prefill never stores the password. |
| V3 Session Management | yes (logout/deferral clearing) | `clearLocalSession()` removes the deferral; token handling unchanged. |
| V4 Access Control | yes (Expert mode) | Mode gate is UX only; server `ensureExpert` remains the enforcer. Do not treat the iOS gate as authorisation. |
| V5 Input Validation | yes | Feedback >= 10 trimmed chars (server `min(10)` stays authoritative); crop output validated (size, non-nil); country via `Countries.normalize`. |
| V6 Cryptography | no new use | Keychain via Valet only; no hand-rolled crypto. |
| V8 Data Protection | yes | `lastLoginEmail` is PII: Keychain (`.whenUnlocked`), not UserDefaults, never logged (`#if DEBUG` only, no value), erased on account deletion. Accurate deletion copy is a privacy-disclosure control. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Next account sees previous account's setup deferral or email | Information disclosure | Clear `setupDeferred` in `clearLocalSession`; email is remembered by design but forgotten on deletion (D-14) |
| Background GET silently promotes a client to expert | Elevation of privilege | Role guard in re-check (D-04, Pitfall 4) |
| Misleading deletion copy (claims data removed that is kept) | Repudiation / compliance | Claim-by-claim audit against the cascade (R2) |
| Cropped image keeps EXIF location | Information disclosure | Re-rendering through `UIGraphicsImageRenderer` strips metadata; add an assertion in `ProfilePhotoCropperTests` that output has no EXIF GPS (improves on today's raw re-encode) [ASSUMED behaviour of `jpegData`, verify in test] |
| Logging email/tokens | Information disclosure | No new `print`; any debug log in `#if DEBUG` with no values |

## Sources

### Primary (HIGH confidence, read this session)
- Backend (read-only, `master` 35bc749): `src/schemas/userProfile.schema.js`, `expertProfile.schema.js`, `onboarding.schema.js`, `feedback.schema.js`; `src/controllers/userProfile.controller.js`, `expert.controller.js`, `onboarding.controller.js`, `account.controller.js`, `clientBooking.controller.js` (cancel), `auth.controller.js` (`getEmailStatus`); `src/services/accountCascade.js`, `storage.js`; `src/utils/refund.js`; `src/cron/expirePastSessions.js`; `supabase/migrations/20261113000200_faq_content_match_terms.sql`, `20260603000000_phase3_extend_profiles.sql`.
- Android (read-only): `AppViewModel.kt`, `managers/UserManager.kt`, `screens/signup/SignupDraft.kt`, `SignupSetupRepository.kt`, `profilephoto/CropMath.kt`, `overview/SignupOverviewScreen.kt`.
- iOS: all files cited inline with line numbers (`ClickMe2026App.swift`, `UserManager.swift`, `SplashViewModel.swift`, `LoginView.swift`, `PushRouter.swift`, `SignupAccumulator.swift`, signup VMs, settings VMs and views, delete-account files, cancellation files, `Call/Ready/`, `project.pbxproj`); git: `b0629d9`, `cae4090`, `510e7cb`.
- Planning: `05-CONTEXT.md`, `IOS-BUG-INVENTORY.md`, `REQUIREMENTS.md`, `STATE.md`, `04-VALIDATION.md`, Phase 4 plans' `<automated>` blocks.

### Secondary (MEDIUM)
- Terms/FAQ alignment is taken from the backend migration comments (published Terms sections 3, 5, 7), not from the Terms page itself.

### Tertiary (LOW)
- Platform behaviours tagged `[ASSUMED]` in the Assumptions Log (navigation destination on `NavigationPath` stacks, `scenePhase` in `App`, EXIF stripping).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies; all APIs exist in repo.
- Architecture (gate, handoff, call sites): HIGH for call-site inventory and Android shape; MEDIUM for SwiftUI handoff details (A5, A6).
- Backend contract (province, 409s, cascade, refund rule): HIGH -- code read directly.
- Pitfalls: HIGH for those derived from code; MEDIUM for device-only behaviour.

**Research date:** 2026-11-13
**Valid until:** 2026-11-27 (the backend repo moved twice on 2026-11-12/13; recheck `accountCascade.js` and `account.controller.js` before locking the delete copy if the backend changes).
