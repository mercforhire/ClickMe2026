---
phase: 05-signup-mode-switch-and-account
verified: 2026-11-13T23:30:00Z
status: human_needed
score: 11/13 must-haves verified
covered_files: [
    "ClickMe2026/Managers/ModeSwitchGate.swift",
    "ClickMe2026/Managers/UserManager.swift",
    "ClickMe2026/Utils/AccountDeletionBlocker.swift",
    "ClickMe2026/Utils/AccountDeletionCopy.swift",
    "ClickMe2026/Utils/ExpertModeGate.swift",
    "ClickMe2026/Utils/LocationFormatter.swift",
    "ClickMe2026/Utils/ProfilePhotoCropper.swift",
    "ClickMe2026/Utils/SupportContact.swift",
    "ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift"
  ]
covered_digest: "v3:sha256:68473654cec7b81bab6dcc9e436f77613a5e71226afda40d9c851256344be064"
behavior_unverified: 1
overrides_applied: 0
behavior_unverified_items:
  - truth: "SIGN-06: switching to Expert with incomplete setup opens the setup hub, and no switch is applied during a call, a superseded request writes nothing, and sign-out mid-lookup writes nothing"
    test: "On a real iPhone: (a) unfinished expert in Client mode, Profile > Mode Switch > Expert; (b) finished expert; (c) airplane mode, including right after Publish in the same session; (d) tap Expert while a call is active; (e) dual-role account, push for the other mode tapped during a call; (f) airplane-mode launch of an unfinished expert, then network on and foreground. Items 1 to 17 of 05-DEVICE-UAT-CHECKLIST.md."
    expected: "(a) hub opens, mode stays Client; (b) Expert home; (c) Expert home (fail open); (d) nothing changes and the call screen stays; (e) mode and call unchanged until the call ends, then the push destination opens; (f) hub opens on foreground."
    why_human: "The pure ExpertModeGate decisions are unit-tested (ExpertModeGateTests), but UserManager.requestModeSwitch, lookUpSetupCompleted, recheckSetupIfPending, clearLocalSession resets and the shells' call-end replay have no behavioral test: UserManager's init is private and no test constructs it. They are verified present and wired by reading the code, not by running the transition."
coincidental_reliance_items: []
human_verification:
  - test: "SIGN-06 end to end on a device (see behavior_unverified_items; checklist items 1 to 17)"
    expected: "As listed above"
    why_human: "State transitions and a call-active invariant that no test exercises"
  - test: "SET-06 legibility: open Settings > Delete Account on a small iPhone and at the largest Dynamic Type size, scroll to the bottom of the confirmation step"
    expected: "All three groups, including the last 'Kept' group (messages, reviews, payment records), are fully readable and not covered by the pinned Delete and Cancel buttons"
    why_human: "DeleteAccountView.swift:115 gives the scroll content an 80 pt spacer under a bar of about 163 pt (divider 1, top 12, button 56, gap 10, cancel 48, bottom 36), so up to about 83 pt of the last group can sit behind the opaque bar at maximum scroll. 05-UI-REVIEW.md flags this and the layout cannot be measured from code. UI-SPEC LT1 and OV1 are device backstops."
  - test: "SET-02: Help > Email Us on a device with Mail set up"
    expected: "The default mail app opens addressed to clickmeapp@uptrendinvestments.net"
    why_human: "openURL on a mailto: URL needs a real mail handler; the simulator has none. SupportContactTests pins the address and the URL."
  - test: "SIGN-05: pick a camera-roll photo, zoom in on the slider, Save, view the public avatar"
    expected: "The uploaded avatar looks like the preview circle"
    why_human: "The crop maths is unit-tested and matches ProfileAvatarRing (scaledToFill, scaleEffect 1 + zoom, no pan), but visual equality needs eyes"
  - test: "SET-07: from both the Bookings tab and a Home-route cancel, tap 'Cancellation policy' on the cancel confirmation, then Back"
    expected: "The policy opens and Back returns to the confirmation with its state intact"
    why_human: "RESEARCH A5: pushing a destination from inside a NavigationPath stack needs a device check; fallback is a sheet with its own NavigationStack"
  - test: "Remaining unticked items in 05-DEVICE-UAT-CHECKLIST.md (SIGN-02 quit and relaunch, SET-01 reopen after language edit, SET-06 409 blocker alerts, T8 prefilled email)"
    expected: "Each item's Expected block"
    why_human: "Project definition of done requires a device check on a real iPhone; every Result line in the checklist is still empty"
---

# Phase 5: Signup, Mode Switch and Account Verification Report

**Phase Goal:** Users can finish signup, enter Expert mode only with a complete setup, and edit or close their account with saves that stick and copy that tells the truth
**Verified:** 2026-11-13T23:30:00Z
**Status:** human_needed
**Re-verification:** No, initial verification

All code paths for the 13 requirements exist, are wired and are not stubs. 149 unit tests in 17 phase suites passed in this run. Nothing FAILED. The status is `human_needed` for two reasons: one truth (SIGN-06 gate orchestration) is present and wired but its state transitions are not exercised by any test, and the Delete Account disclosure may be partly covered by the pinned buttons. The project's definition of done also requires a real-iPhone check, and every `Result:` line in `05-DEVICE-UAT-CHECKLIST.md` is empty.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SIGN-01: an expert cannot publish without a photo | VERIFIED | `SignupAccumulator.missingForPublish` appends `.profilePicture` when `avatarUrl` is nil or empty. `isReadyToPublish == missingForPublish.isEmpty`. `buildPublishRequest()` returns nil when not ready. `SignupReviewViewModel.publish()` sets "Finish these first: ..." and sends no PATCH. `SignupAccumulatorTests` passed. |
| 2 | SIGN-05: the uploaded photo matches the crop the user set | VERIFIED | `SignupProfilePhotoViewModel.save()` calls `ProfilePhotoCropper.squareCrop(pickedImage, zoom: zoomScale)` then `api.uploadAvatar(imageData:)`. The crop side is `min(w,h)/(1+zoom)`, centred, orientation baked in, 1024 px cap, fresh render so EXIF/GPS is dropped. This matches `ProfileAvatarRing` (`scaledToFill()` plus `scaleEffect(1 + zoomScale)`, no pan). `ProfilePhotoCropperTests` and `SignupProfilePhotoSaveTests` passed. Visual equality is a device item. |
| 3 | SIGN-03: expertise tags and languages are saved in tap order, first pick primary | VERIFIED | `SignupTagsViewModel.selectionOrder` is appended on select and removed on deselect, and feeds `selectedTags`, `syncToAccumulator()` and the `expertise_tags` body. `LanguageSelectionViewModel.orderedSelection` feeds `onDone(...)` and `setLanguages`. `SelectionOrderTests` passed. |
| 4 | SIGN-04: the country code is normalized on publish | VERIFIED | `buildPublishRequest()` sends `Countries.normalize(countryCode)`. `hasBasicInfo` requires a non-nil normalized country, so an unrecognised code makes the profile not ready. `normalize` trims, uppercases and maps alpha-2 to alpha-3. Tests passed. |
| 5 | SIGN-02: resuming signup keeps an already-verified email verified | VERIFIED | `SignupOverviewView .task` calls `refreshEmailVerified()`, which calls `GET /auth/email/status` once (route exists in backend `auth.js:53`) and never downgrades a true. A fresh signup seeds from `response.emailVerified`. `SignupEmailVerifiedSeedTests` passed. Quit-and-relaunch is a device item. |
| 6 | SIGN-06: switching to Expert with incomplete setup opens the setup hub; Expert is entered only through the gate | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Present and wired. `ModeSwitchGate.request` calls `UserManager.requestModeSwitch`, which calls `ExpertModeGate.resolveSwitch` after `lookUpSetupCompleted()`. `.setupRequired(opensHub:)` raises `setupHubRequested`, and `ClickMe2026App.onChange` routes to `.signupSetup` only from a home route. `setMode` is `private`, and a grep finds no `setMode(` or `currentMode =` write outside `UserManager.swift`. All four Mode Switch entry points, both push handlers, Splash and Login go through the gate (`resolvePostAuthLanding`). A failed lookup becomes nil and fails open, and the cached profile is never consulted. A call-active guard is the first statement, and `clearLocalSession` resets the flags. The pure rules are tested (`ExpertModeGateTests`, `SetupDeferralStoreTests`). The orchestration (supersede, sign-out mid-lookup, call guard, foreground re-check, push replay after a call) has no behavioral test. See Human Verification. |
| 7 | SET-01: language edits on the client and expert profiles save to the server | VERIFIED | Both settings screens use `LanguageSelectionView`, and `makeProfileUpdateBody()` sets `body.languages = .init(languageIds:customLanguages:)` only when ids changed. Custom languages are always sent back, an empty result is blocked ("Keep at least one language."), and `persistedLanguageIds` updates only after a successful PATCH. `LanguageEditorSheet` is deleted. `ProfileLanguagesSaveTests` passed. |
| 8 | SET-04: opening Notification preferences sends no save until the user changes something | VERIFIED | `apply(preferences:)` records `lastAppliedSnapshot`, and `scheduleAutoSave()` returns when the current snapshot equals it. `NotificationSettingsAutoSaveTests` (load sends nothing, one toggle sends one PATCH, a reload sends nothing) passed. |
| 9 | SET-02: Help > Email Us opens a mail to clickmeapp@uptrendinvestments.net | VERIFIED | `HelpView.openSupportEmail()` calls `openURL(SupportContact.mailtoURL)`. The address is spelled in exactly one Swift file (`SupportContact.swift`), and `SuspensionNotice` reads it from there. `SupportContactTests` passed. No other address variant exists in Swift sources, `Localizable.xcstrings` or `Info.plist`. Opening the mail app is a device item. |
| 10 | SET-05: Feedback cannot be sent with fewer than 10 characters | VERIFIED | `FeedbackViewModel.submit()` guards on `meetsMinimumLength` (trimmed UTF-16 count at least 10), shows "Please enter at least 10 characters." and sends no request. The text stays in the field. `FeedbackValidationTests` passed. |
| 11 | SET-03 and SET-06: Delete Account has no Pause Account card, and the copy matches what the backend deletes and keeps | VERIFIED | No pause view, callback or card remains. The only leftover is the unused token `DeleteAccountBrand.pauseIconBg`, which is info-level dead code. `AccountDeletionCopy` was compared line by line with the backend `purgeAndLockAccount`. Deleted (F1 profile tombstone, F6 devices, F7 notifications, F8 preferences, step I uploaded photos) matches. Kept without personal details (bookings kept, F3 and F4 erase private notes) matches. Kept (reviews and messages have no DML, payment records untouched) matches. Unanswered `pending_approval` requests are cancelled and their holds voided (`ACTIVE_STATUSES`, `isVoidFallback`), as the copy says. The 409 blockers `EXPERT_HAS_UPCOMING_BOOKINGS`, `CLIENT_HAS_UPCOMING_BOOKINGS` and `SESSION_IN_PROGRESS` exist in `account.controller.js` and are branched on `ErrorCode`. `View My Bookings` is installed on both shells' `showMyBookings`. `AccountDeletionBlockerTests`, `DeleteAccountViewModelTests` and `AccountDeletionCopyTests` passed. |
| 12 | SET-06: the user can read the full Delete Account disclosure (every group clear of the pinned buttons) | ? UNCERTAIN | `DeleteAccountView.confirmationView` overlays a bar of about 163 pt on a `ScrollView` whose content ends in an 80 pt spacer. At maximum scroll the last group can be partly behind the opaque bar. This is the open WARNING in `05-UI-REVIEW.md` and its geometry is code-derived, not measured. It depends on device height and Dynamic Type. It is routed to human verification, not marked FAILED. |
| 13 | SET-07: `CancellationPoliciesView` and `ReadyToStartCallView` are reachable or removed | VERIFIED | `ReadyToStartCallView` is deleted, and no reference remains in `ClickMe2026`, tests or `project.pbxproj`. `CancellationPoliciesView` is pushed from `ClientCancellationView` through `@State showPolicy` and `.navigationDestination(isPresented:)`. The "How to Initiate" copy and the "Your bank decides how long a refund takes to appear." footnote are present. |

**Score:** 11/13 truths verified (1 present, behavior-unverified; 1 uncertain, routed to human)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | BACK-13: a client is promoted to expert only by an explicit setup call | Not scheduled (deferred past this release, D-04) | `REQUIREMENTS.md` BACK-13 and REL-02 record the reason. The iOS Expert-mode gate is the user-facing fix. This is an accepted descope, not a gap. |

### Advisory (New Scope, Unevidenced)

None. This is an initial verification.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Utils/ProfilePhotoCropper.swift` | Pure square crop at the preview zoom | VERIFIED | 80 lines, used by `save()` |
| `Utils/LocationFormatter.swift` | One location formatter | VERIFIED | Used by the signup review and `ClientProfilePersonalInfo` |
| `Utils/SupportContact.swift` | One support address | VERIFIED | Used by `HelpView` and `SuspensionNotice` |
| `Utils/ExpertModeGate.swift` | Pure gate decisions | VERIFIED | Called from `UserManager` at four sites |
| `Managers/ModeSwitchGate.swift` | Call-guarded entry point | VERIFIED | Four Mode Switch call sites |
| `Utils/AccountDeletionBlocker.swift` and `AccountDeletionCopy.swift` | Blocker alert and disclosure copy | VERIFIED | Used by `DeleteAccountViewModel` and `DeleteAccountWarningHeader` |
| `Signup Flow/SignupAccumulator.swift` | Server-aligned publish rules | VERIFIED | `missingForPublish`, `buildPublishRequest`, `refreshEmailVerified` |
| Phase test files (17 suites) | Unit coverage | VERIFIED | 149 tests passed in this run |
| `CancellationPoliciesView.swift` | Reachable | VERIFIED | Linked from the cancel confirmation |
| `ReadyToStartCallView.swift`, `LanguageEditorSheet.swift`, `DeleteAccountPauseCard.swift` | Deleted | VERIFIED | Absent from the tree and `project.pbxproj` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Mode Switch (4 entry points) | `ModeSwitchGate.request` | `Task { await ModeSwitchGate.request(mode) }` | WIRED | `HomeClientView:363`, `HomeExpertView:308`, `ExpertProfileHomeScreen:260`, `ClientProfileHomeScreen:248` |
| Push plans | `requestModeSwitch(_:source: .push)` | `consumePendingPush()` | WIRED | Both shells; `.blockedByCall` leaves the tap queued; `onChange(of: callCenter.isCallActive)` replays |
| `requestModeSwitch` | `ExpertModeGate.resolveSwitch` | After `lookUpSetupCompleted()` | WIRED | Generation, `isLoggedIn` and a fresh `isCallActive` are passed in |
| `setupHubRequested` | `route = .signupSetup` | `ClickMe2026App.onChange` | WIRED | Only from a home route |
| `scenePhase == .active` | `recheckSetupIfPending()` | `ClickMe2026App.onChange` | WIRED | Only on a home route |
| Splash and Login | `resolvePostAuthLanding(roles:)` | Both call sites | WIRED | `SplashViewModel:76`, `LoginView:273` |
| Hub Not now and Publish | `deferSetup()` and `completeSetup()` | `LoginView:179` and `:230` | WIRED | |
| `SignupOverviewView .task` | `refreshEmailVerified` | `GET /auth/email/status` | WIRED | Endpoint exists in the backend |
| `HelpView` | `SupportContact.mailtoURL` | `openURL` | WIRED | |
| `DeleteAccountView` alert | `showMyBookings` environment | Both shells install it | WIRED | |
| `ClientCancellationView` | `CancellationPoliciesView` | `navigationDestination(isPresented:)` | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Setup hub checklist | `emailVerified` | `GET /auth/email/status` | Yes | FLOWING |
| Setup hub gate | `setupCompleted` | `GET /expert/profile` via `refreshExpertProfile()` (fresh read after the call) | Yes | FLOWING |
| Language settings | `languageItems`, `persistedLanguageIds` | `GET` profile, then `PATCH /user/profile` | Yes | FLOWING |
| Notification toggles | `sections` | Notification preferences endpoint | Yes | FLOWING |
| Delete Account alert | `blocker` | Decoded `ErrorCode` of a 409 | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 17 phase suites | `xcodebuild test -only-testing` for ExpertModeGate, AccountDeletionBlocker, AccountDeletionCopy, DeleteAccountViewModel, SignupAccumulator, ProfilePhotoCropper, FeedbackValidation, NotificationSettingsAutoSave, SupportContact, ProfileLanguagesSave, SelectionOrder, SignupEmailVerifiedSeed, RememberedLoginEmail, LocationFormatter, SignupBasicInfoProvince, SignupProfilePhotoSave and SetupDeferralStore (destination `id=E8F9FD72-...`, UI tests skipped) | `Test run with 149 tests in 17 suites passed`, `** TEST SUCCEEDED **` | PASS |
| `setMode` is not reachable outside `UserManager` | grep `setMode(\|\.currentMode *=` outside `UserManager.swift` | 0 matches | PASS |
| Support address in one file | grep of the address in `ClickMe2026` Swift files | Only `SupportContact.swift` | PASS |

The full suite was not re-run. The orchestrator reported 820/820 passing.

### Probe Execution

Step 7c: SKIPPED. No probes are declared in any PLAN or SUMMARY, and the phase is not a migration or tooling phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SIGN-01 | 05-04 | Expert cannot publish without a photo | SATISFIED | Truth 1 |
| SIGN-02 | 05-11 | Resuming signup keeps the verified email | SATISFIED (device check pending) | Truth 5 |
| SIGN-03 | 05-02 | Tags and languages keep tap order | SATISFIED | Truth 3 |
| SIGN-04 | 05-04 | Country code normalized on publish | SATISFIED | Truth 4 |
| SIGN-05 | 05-03 | Uploaded photo matches the crop | SATISFIED (device check pending) | Truth 2 |
| SIGN-06 | 05-07, 05-10, 05-12, 05-16 | Expert switch with incomplete setup opens the hub | NEEDS HUMAN | Truth 6 |
| SET-01 | 05-09 | Language edits save | SATISFIED | Truth 7 |
| SET-02 | 05-05 | Email Us opens mail to the support address | SATISFIED (device check pending) | Truth 9 |
| SET-03 | 05-15 | Pause Account card removed | SATISFIED | Truth 11 |
| SET-04 | 05-05 | No save on opening notification preferences | SATISFIED | Truth 8 |
| SET-05 | 05-05 | Feedback needs at least 10 characters | SATISFIED | Truth 10 |
| SET-06 | 05-08, 05-14, 05-15 | Accurate Delete Account copy and 409 blockers | NEEDS HUMAN (legibility) | Truths 11 and 12 |
| SET-07 | 05-06, 05-17 | Dead screens wired in or deleted | SATISFIED (device check pending) | Truth 13 |

All 13 IDs from the roadmap appear in at least one plan's `requirements` field. REQUIREMENTS.md maps no other ID to Phase 5, so there are no orphans. Plans 05-01 and 05-13 also claim `T8`, `D-02`, `D-04`, `D-11`, `D-12`, `D-14` and `D-16`. These are decision references (T8 was moved into the phase per the REQUIREMENTS.md note), not requirement IDs, and they are not an orphan problem.

Traceability bookkeeping: `REQUIREMENTS.md` still shows SIGN-06, SET-02, SET-06 and SET-07 unticked and "Pending", and the ROADMAP Phase 5 box is unchecked. SET-02 and SET-07 are code-complete by this verification. Tick them only after their device items pass. SIGN-06 and SET-06 are held back by Truths 6 and 12.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| 61 changed Swift files | - | TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER | none | No markers in any file changed in this phase |
| `Views/Screens/Settings/Delete account/DeleteAccountView.swift` | 115 | 80 pt spacer under a 163 pt pinned bar | Warning | Last disclosure group may be covered (Truth 12) |
| `Views/Screens/Settings/Delete account/Subviews/DeleteAccountBrand.swift` | 24 | Unused `pauseIconBg` token | Info | Dead code left after the Pause card removal |
| `SignupAccumulator.swift` | `checklist` | `profilePhoto: avatarUrl != nil` against `avatarUrl?.isEmpty ?? true` in `missingForPublish` | Info | Same as IN-01: an empty-string URL ticks the row but blocks Publish. Not reachable today because hydrate guards non-empty and the upload response is non-empty. |
| `UserManager.swift` | 718-730 | `setupDeferral.clear()` runs for a push-sourced request | Warning | Same as WR-03: a push-initiated switch clears the user's "Not now" |
| `UserManager.swift` | `refreshExpertProfile` | Can repopulate `expertProfile` after logout | Warning | Same as WR-02 and WR-01, open in `05-REVIEW-DISPOSITION.md` |

The six warnings in `05-REVIEW.md` (WR-01 to WR-06) and four info items (IN-01 to IN-04) are all recorded as `open` in `05-REVIEW-DISPOSITION.md`. None contradicts a roadmap success criterion. WR-03 and the WR-01 and WR-02 stale-write cases are edge races. They are worth a decision before the release build.

Other checks:
- `git status` shows an uncommitted `ClickMe2026/Localizable.xcstrings` change (75 insertions, 30 deletions of auto-extracted string-catalog entries). It is not part of any Phase 5 plan, and the UAT checklist already warns about it. Commit or discard it before building the release.
- 05-UI-SPEC.md was force-approved after two revisions. This does not affect the code verdict.

### Human Verification Required

See the `human_verification` frontmatter list. In short:

1. **SIGN-06 on a device** (checklist items 1 to 17): the hub opens for an unfinished expert, a finished expert enters Expert, airplane mode fails open (including right after Publish), no switch happens during a call, a push for the other mode waits until the call ends, and the foreground re-check opens the hub.
2. **Delete Account legibility:** scroll to the bottom of the confirmation step on a small iPhone and at the largest Dynamic Type size. If the "Kept" group is hidden, replace the fixed spacer with a bottom `safeAreaInset` (the fix proposed in `05-UI-REVIEW.md`). This would then become a gap for SET-06.
3. **Help > Email Us** opens Mail addressed to `clickmeapp@uptrendinvestments.net`.
4. **Avatar crop:** the public avatar looks like the preview circle at a non-default zoom.
5. **Cancellation policy link** from both the Bookings tab and a Home-route cancel, and Back.
6. **Remaining checklist items:** SIGN-02 relaunch, SET-01 reopen, 409 blocker alerts and the remembered email.

### Gaps Summary

No gaps are confirmed. No truth FAILED, and no artifact is missing, a stub or unwired. Two items stop this from being `passed`:

- **SIGN-06 (Truth 6):** the decision logic is tested, but the `UserManager` orchestration is not. It covers the call guard, the supersede and sign-out-mid-lookup cases, the re-check and the push replay. A device run is the only evidence available.
- **Delete Account disclosure legibility (Truth 12):** the copy is accurate against the backend cascade, but the pinned button bar may hide the last group on some devices. If the device check confirms it, record it as a gap and fix it before the iOS release.

Phase 5 should not be marked complete in ROADMAP.md or REQUIREMENTS.md until the device checklist results are recorded.

---

_Verified: 2026-11-13T23:30:00Z_
_Verifier: Claude (gsd-verifier)_
