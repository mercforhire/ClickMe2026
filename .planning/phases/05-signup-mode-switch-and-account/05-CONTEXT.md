# Phase 5: Signup, Mode Switch and Account - Context

**Gathered:** 2026-11-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can finish signup, enter Expert mode only with a complete setup, and edit or close their account with saves that stick and copy that tells the truth. Requirements: SIGN-01, SIGN-02, SIGN-03, SIGN-04, SIGN-05, SIGN-06, SET-01, SET-02, SET-03, SET-04, SET-05, SET-06, SET-07, plus the Q1 remember-login-email change (T8), which this discussion moved into scope (D-16).

This phase is iOS only. **No backend change is planned**: BACK-13 is deferred (D-04), and every other item works against the current production contract. Android mirrors iOS behavior (root `CLAUDE.md`), so each behavior change below is a likely Android follow-up, to be logged as a todo and never assumed done. The ones named in this discussion are listed under Deferred Ideas.

These items are mechanical and were not discussed. Build them as the requirement and the inventory row say (`.planning/IOS-BUG-INVENTORY.md` rows S1, S3–S6, T1–T5):
- **SIGN-01 (S1):** Publish requires an avatar (server 422 at `onboarding.controller.js:176-187`).
- **SIGN-02 (S3):** on resume, seed the verified-email state from `email_verified` and `GET /auth/email/status`. `checkEmailVerified()` exists but has no callers.
- **SIGN-03 (S4):** expertise tags and languages keep tap order. The server marks `idx===0` as primary (`onboarding.controller.js:127`). The server doesn't store language order.
- **SIGN-04 (S5):** `Countries.normalize` on the publish `country_code`.
- **SIGN-05 (S6):** render the user's zoom/crop into the uploaded image, not only the preview.
- **SET-01 (T1):** language edits auto-save via `languages.{language_ids, custom_languages}` (`schemas/userProfile.schema.js:59-61`). Fix both `ClientProfileSettingsViewModel` and `ExpertProfileSettingsViewModel` (the roadmap note says to check the expert one for the same gap).
- **SET-02 (T2):** Help > Email Us goes to `clickmeapp@uptrendinvestments.net`.
- **SET-03 (T3):** remove the Pause Account card. There's no backend pause route.
- **SET-04 (T4):** Notification preferences skip auto-save until the first load is applied.
- **SET-05 (T5):** Feedback needs at least 10 characters (`schemas/feedback.schema.js:20` `min(10)`). Staying on a cleared form after sending is by design (P16.5 D-06).

Status notes that don't block planning: the Phase 2, 3 and 4 device UATs are partial (Phase 4: 20 device items deferred on 2026-11-13), and they must run before Phase 8.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- **No backend change may break App Store build 6 or the current Android build** (PROJECT.md; the reason wave 3c was dropped).
- **Errors:** display text comes from `Error.userMessage`, and UI branches on `ErrorCode` values, never on `message` text (CONVENTIONS).
- **Tab-owned stacks (Phase 2 D-04):** a destination opens on the stack of the tab that owns it.
- **Single-call invariant:** a mode switch during a call stays blocked by `CallCenter` (Android `callGuard.attempt(RestrictedAction.SwitchModes)` is the same rule).

### Q5 / SIGN-06: the Expert-mode setup gate
- **D-01:** Switching to Expert mode when the expert profile's `setup_completed` is false opens the **setup hub** (the existing `.signupSetup` route, hydrated, resuming where the user left off). This matches Android D-17. The hub offers **Not now** (Android D-27), which returns the user to Client mode. The deferral is remembered for this login, so Splash and foreground re-checks don't push setup again. Asking for Expert again clears the deferral and reopens the hub. Logout clears it.
- **D-02:** If the setup-status lookup **fails** during a switch (offline, server error), let the user into Expert mode. This fails open, the same as `SplashViewModel.isExpertProfileIncomplete()` and Android, so a network blip never sends a finished expert back into signup. The next launch or foreground re-checks.
- **D-03:** **One shared gate** covers every route into Expert mode: the Mode Switch screen (`HomeClientView`, `ClientProfileHomeScreen`, `HomeExpertView`, `ExpertProfileHomeScreen` call sites of `setMode`), a push plan's `switchToMode`, and Splash's landing decision. No path reaches an incomplete expert dashboard. Put the decision in one place, as Android does (`UserManager.requestModeSwitch`), not in each view. — **Reversibility:** costly — every `setMode(.expert)` call site moves to the shared entry point
- **D-04:** **BACK-13 is deferred past this release.** It stays parked on backend branch `wave-3c`, and the iOS gate (D-01 to D-03) fixes the user-facing bug. Record it in REQUIREMENTS.md as deferred, with the reason recorded in REL-02 (build 6 and current Android rely on `ensureExpert`'s implicit promotion). Note that the gate's own setup lookup (`refreshExpertProfile`, an `/expert/*` GET) still promotes a client-only account through `ensureExpert` once they pick Expert. That's accepted: an explicit switch to Expert is consent (Android D-23). No *background* lookup may run for a client-only account outside Expert mode (Android `recheckSetupIfPending` role guard).

### Q5 / S2: optional province
- **D-05:** Province/state is **optional** at signup, matching the server contract and Android (`SignupDraft.kt`, D-03). Remove it from `SignupAccumulator.isReadyToPublish` and from the Basic Info checklist row. City, country, timezone and languages stay required.
- **D-06:** When province is empty, an expert's location reads **"City, Country"** with no stray comma or blank. Planning audits every place that formats a location: expert cards, expert profile, the client profile an expert sees (`ClientProfilePersonalInfo`), and the signup review.
- **D-07:** A saved province **can be cleared** in client and expert profile settings, as Android does (`clearProvince`). Research confirms how `userProfile.schema.js` accepts a clear (null vs empty string) before planning.

### SET-06 / T6: Delete Account copy
- **D-08:** Replace the current paragraph (`DeleteAccountWarningHeader.swift:22`) with **one permanence line plus three short groups**, matching what `services/accountCascade.js` does:
  - **Deleted:** your profile details (name, photo, bio, location), devices, notifications and preferences, and uploaded files.
  - **Kept without your personal details:** your past bookings, shown as from "Deleted user".
  - **Kept:** messages, reviews and payment records.
  Research checks each claim against `purgeAndLockAccount` (steps F1–F11, I) and the no-DML note for reviews, messages and reports, and adjusts the wording if any claim is wrong. Copy follows the project's plain-English style.
- **D-09:** Say plainly that **messages and reviews you've written stay visible to the other person, shown as from "Deleted user"**.
- **D-10:** Add one upfront line saying deletion needs upcoming bookings cancelled or finished first. Make sure each self-delete 409 shows a clear message with a way to My Bookings: `EXPERT_HAS_UPCOMING_BOOKINGS`, `CLIENT_HAS_UPCOMING_BOOKINGS` (**missing from `ErrorCode.swift`, so add it**) and `SESSION_IN_PROGRESS`. Source: `account.controller.js` `assertNoBlockingBookings`, D-17/D-18/D-19.
- **D-11:** Android has the same wrong copy (`delete_account_body`). **Log an Android follow-up todo containing the final iOS strings**, so the port copies them word for word. No Android commit in this phase.

### Q7 / SET-07: dead screens
- **D-12:** **Wire `CancellationPoliciesView` into the client cancel-booking flow** with a "Cancellation policy" link on the cancel confirmation. Before linking, research checks its copy (`CancellationDeadlinesCard`, `RefundEligibilityCard`, `HowToInitiateCard`) against the backend's current client-cancel refund rule (D-16 binary 24 h in `accountCascade.js` and the booking cancel controller) and the hold model, and fixes any mismatch. The expert-cancel refund question (Q2) is Phase 6 and must not be decided here.
- **D-13:** **Delete `ReadyToStartCallView`**, `ReadyToStartCallViewModel` and any helper only they use. It's a legacy Skype meeting-link screen; calls run through Agora and `CallCenter`. — **Reversibility:** reversible — recoverable from git

### Q1 / T8: remember last login email
- **D-14:** **Bring `feature/remember-login-email` (`b0629d9`) into this phase.** It pre-fills the last email on Login after sign-out and clears it on Delete Account, with `RememberedLoginEmailTests`. The branch is 405 commits behind `main`, and a merge conflicts in `ClickMe2026/Managers/UserManager.swift`, so **port the change onto current main** as its own plan rather than merging the branch. Re-run its tests, and check it against Phase 4 logout and suspension changes (`SuspensionNotice`, `AutoLoginOutcome`).
- **D-15:** The ported change touches `DeleteAccountViewModel.swift`, which SET-03 and SET-06 also edit. The planner orders these plans so they don't conflict.
- **D-16:** Log an Android follow-up todo for the matching Android branch (`0c9ecc55`, also unmerged).

### Claude's Discretion
- How the shared gate is structured in Swift (a `UserManager` method vs a small coordinator), as long as D-03's single entry point holds.
- The exact wording of the D-08/D-10 copy within the agreed structure. The final strings go into the Android todo (D-11).
- Where the "Cancellation policy" link sits inside the cancel confirmation (D-12).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and bug sources
- `.planning/ROADMAP.md` § Phase 5 — goal, success criteria, notes (Q1/Q5/Q7, SET-06 copy rule, SET-01 expert check)
- `.planning/REQUIREMENTS.md` — SIGN-01..06, SET-01..07, BACK-13, REL-02
- `.planning/IOS-BUG-INVENTORY.md` — rows S1–S8, T1–T8, K13 (file:line evidence for every item) and Q1/Q5/Q7
- `.planning/PROJECT.md` — Key Decisions (wave 3c drop) and Open product questions

### Expert-mode gate (Android reference implementation)
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/AppViewModel.kt` — `switchMode` (D-17), Not now (D-27), foreground re-check
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/managers/UserManager.kt` — `requestModeSwitch`, `recheckSetupIfPending` (role guard, deferral)
- `../ClickMe2026 Backend/src/middleware/ensureExpert.js` — implicit promotion (why BACK-13 matters, D-04)

### Signup
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/signup/SignupDraft.kt` — server-aligned completion rules (province optional, photo required)
- `../ClickMe2026 Backend/src/controllers/onboarding.controller.js` — publish 422 (avatar), `is_primary: idx===0`
- `../ClickMe2026 Backend/src/schemas/userProfile.schema.js` — languages field, province clear semantics

### Account and settings
- `../ClickMe2026 Backend/src/services/accountCascade.js` — what delete purges, scrubs and keeps (SET-06)
- `../ClickMe2026 Backend/src/controllers/account.controller.js` — self-delete 409 guards (D-10)
- `../ClickMe2026 Backend/src/schemas/feedback.schema.js` — `min(10)`
- `../ClickMe2026 Backend/openapi/clickme-api.yaml` — REST contract

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SplashViewModel.isExpertProfileIncomplete()` / `UserManager.refreshExpertProfile()`: the existing setup check, which fails open. The shared gate reuses it.
- `ClickMe2026App` `.signupSetup` route with `LoginView(startAtSignupSetup: true, hydrateFrom:)`: the setup hub D-01 opens.
- `Countries.normalize` (`Constants/Countries.swift`): SIGN-04.
- `ErrorCode` (`Model/Enums/ErrorCode.swift`): already has `sessionInProgress` and `expertHasUpcomingBookings`; add `CLIENT_HAS_UPCOMING_BOOKINGS`.
- `CancellationPoliciesView` and its subviews in `Views/Screens/Client Mode/Cancellation Policies/`: complete; only a link is missing.

### Established Patterns
- `UserManager.setMode(_:)` is called from about 8 view sites. D-03 routes the Expert direction through one gate.
- `ClickMe2026App` mirrors `currentMode` onto `AppRoute` only on home routes (the architecture's mode-mirroring constraint). The gate must keep both observers in sync and must not move the route away from `.signupSetup` or Login.
- Auto-save view models skip fields on purpose: `ClientProfileSettingsViewModel.swift:261-263` (languages) and the snapshot at `:194`.

### Integration Points
- `SignupAccumulator.swift` (`isReadyToPublish`, `checklist`, publish payload ~`:197`), `SignupVerifyEmailViewModel`, `SignupTagsViewModel`, `LanguageSelectionViewModel`, `SignupProfilePhotoViewModel` / `ProfileAvatarRing`.
- `HelpView.swift:20`, `NotificationSettingsView.swift:59` / VM `:90`, `FeedbackViewModel.swift:158`, `DeleteAccountView.swift:35,95`, `AccountSecurityView.swift:207`, `DeleteAccountWarningHeader.swift:22`.
- `Views/Screens/Call/Ready/` (to delete, D-13).
- `feature/remember-login-email` (`b0629d9`): `UserManager.swift`, `LoginViewModel.swift`, `DeleteAccountViewModel.swift`, `ClickMe2026Tests/.../RememberedLoginEmailTests.swift`.

</code_context>

<specifics>
## Specific Ideas

- Android is the reference for the gate's behavior (D-17, D-23, D-27). iOS should feel identical: setup hub, Not now back to Client, and a deferral remembered for the login.
- Delete Account copy must be accurate enough for App Store privacy review. It should read as three short scannable groups, not a wall of text.

</specifics>

<deferred>
## Deferred Ideas

- **BACK-13 explicit-promotion backend change:** after App Store build 6 and the current Android build no longer rely on implicit promotion. Recorded in REL-02 (D-04).
- **Android follow-ups (todos, not this phase):** the setup gate is already on Android. To log: Delete Account copy with the final iOS strings (D-11); the 409 messages if Android lacks `CLIENT_HAS_UPCOMING_BOOKINGS`; the remember-login-email port (`0c9ecc55`, D-16); and the cancellation-policy link if Android has no equivalent (D-12).
- **S8 (Android requires a digit in passwords):** still by design, not discussed.

### Reviewed Todos (not folded)
- `2026-11-08-check-the-android-push-prompt-after-a-reinstall.md`: a Phase 4 device check (checklist item 20), not signup or settings.
- `2026-11-11-merge-d12-into-backend-master.md`: backend payments housekeeping.
- `2026-11-12-long-lead-sweep-transient-errors-after-stamp.md`: backend payments sweep.

</deferred>

---

*Phase: 05-signup-mode-switch-and-account*
*Context gathered: 2026-11-13*
