# Phase 05 — UI Review

**Audited:** 2026-11-13
**Baseline:** `05-UI-SPEC.md` (status: approved). Audited against the code at HEAD `b6fb341`. The spec's per-row "planned NN" status is stale: git history shows waves 2 to 6 (05-07 to 05-16) built and committed, so the spec's "not built" claims were checked against the code, not taken as true.
**Screenshots:** not captured (native SwiftUI iOS app; no web dev server; no simulator run per orchestrator constraint). Code-only audit.
**Interaction captures:** off (`interaction_capture: false`).

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Every shipped and planned Delete Account, blocker, cancel, publish and language string matches the contract word for word; Phase 05 literals are missing from the String Catalog |
| 2. Visuals | 3/4 | Hierarchy and focal points match the contract; the Delete Account confirmation's last disclosure lines sit under the pinned button bar at default text size |
| 3. Color | 3/4 | Accent is reserved as specified and no new color token is added; the cancel confirmation still uses a hard-coded `Color.orange` and raw `.black`/`.white` the contract says do not appear |
| 4. Typography | 3/4 | New Phase 05 text stays inside the declared 4 sizes and 2 weights; the feedback error is corrected to Regular; touched files carry many pre-existing styles |
| 5. Spacing | 2/4 | The Delete Account confirmation's 80 pt bottom spacer is shorter than the ~163 pt button bar, so the LT1 clearance contract fails; off-scale values remain on touched screens |
| 6. Experience Design | 2/4 | The Mode Switch busy state the contract says is "covered" is never visible: the screen dismisses before the lookup runs, and nothing shows progress during the lookup |

**Overall: 16/24**

No BLOCKER was found: no defect stops a user from completing book, pay, join, cancel, or delete. Each pillar below has at least one specific WARNING.

---

## Top 3 Priority Fixes

1. **Mode Switch gives no feedback during the setup lookup** — a switch to Expert makes a network round trip with no visible state, and the user can re-enter Mode Switch and start a second request — keep the screen up until the lookup resolves (move `dismiss()` after the awaited result in `ModeSwitchView.swift:74-76`, or have the four `onConfirm` call sites return the result), so the already-written `.disabled(UserManager.shared.isSwitchingMode)` at `ModeSwitchView.swift:86` actually applies. Then update `05-UI-SPEC.md` A2 and row L1, which assume a screen that is never visible.

2. **Delete Account's last disclosure lines hide under the pinned buttons** — at default text size, at maximum scroll, the bottom of the "Kept" group sits behind the opaque bar on the step whose purpose is an accurate disclosure — replace the fixed `Spacer().frame(height: 80)` at `DeleteAccountView.swift:115` with `.safeAreaInset(edge: .bottom) { DeleteAccountBottomButtons(...) }` on the `ScrollView` (the bar is ~163 pt: divider 1 + top 12 + button 56 + gap 10 + cancel 48 + bottom 36), so the scroll view insets itself. Verify LT1 on a device at the largest Dynamic Type size.

3. **Cancel confirmation uses off-token and off-contract colors** — the refund-changed notice is `Color.orange` (`ClientCancellationView.swift:218`), and the Retry and loading surfaces use raw `.black` and `.white` (`:141`, `:273`, `:276`, `:280`) — route them through the screen's `CancellationBrand` alias, and either add a named warning token or amend the Color section of `05-UI-SPEC.md` (which says Phase 05 surfaces use no orange element) so the contract matches the code.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Verified exact against the contract (no finding):**
- Delete Account strings in `AccountDeletionCopy.swift:26-36` match the contract's copy table word for word, including the permanence line, the upfront line, the three group titles and bodies, and `"Deleted user"`. No forbidden word (`removed`, `saved card`, `payment details`) appears.
- Blocker alert strings in `AccountDeletionBlocker.swift:27-68` match all five message rows and the title `You can't delete your account yet`. The button is `View My Bookings` (`:30`), per CP1 Title Case.
- Publish alert: `SignupReviewViewModel.swift:111` builds `Finish these first: {titles}.` from checklist titles in order, and `SignupReviewView.swift:104` uses `Couldn't publish profile`.
- Province placeholder `Province/State (optional)` at `SignupBasicInfoView.swift:80`.
- `Couldn't prepare this photo. Please choose another one.` at `SignupProfilePhotoViewModel.swift:160`.
- `Add languages` empty-row prompt at `ProfileLanguageField.swift:30`; `Keep at least one language.` at `ClientProfileSettingsViewModel.swift:295` and `ExpertProfileSettingsViewModel.swift:301`.
- `Please enter at least 10 characters.` at `FeedbackDetailsField.swift:49`.
- `Cancellation policy` link at `ClientCancellationView.swift:227`; `Tap 'Cancel'.` step in `HowToInitiateCard.swift:17`.
- `Not now` hub button at `SignupOverviewView.swift:153`.
- Help support address via the single `SupportContact.email` at `SupportContact.swift:17`.

**WARNING — Phase 05 literals absent from the String Catalog.** `Localizable.xcstrings` has no entry for `Add languages`, `Finish these first`, `Keep at least one language`, `Please enter at least 10 characters`, or `Cancellation policy`. The catalog's only language is `en`, so the source text renders today. Low risk, but the catalog should be regenerated when Xcode next builds, as the spec's Sources section already says. Do not hand-edit it.

**WARNING — stale casing comment.** `HomeExpertView.swift:75` says `"View my bookings"`, the superseded sentence-case form. The live constant `AccountDeletionBlocker.bookingsActionLabel` is correctly Title Case. Fix the comment so the next planner does not copy it.

### Pillar 2: Visuals (3/4)

**Met:** The Delete Account confirmation keeps the headline as the focal point, with the permanence line and three groups below it (`DeleteAccountWarningHeader.swift:21-37`). The feedback step shows the short header only (`DeleteAccountView.swift:141`). The Pause card and its title are removed (no matches for `Before you go` or `Pause Account` in app source). The Expert shell and Client shell both install `showMyBookings` (`HomeClientView.swift:99`, `HomeExpertView.swift:78`).

**WARNING — disclosure clipped by the pinned bar at default size.** `DeleteAccountView.swift:109-131` overlays `DeleteAccountBottomButtons` on the confirmation `ScrollView` with a `ZStack(alignment: .bottom)`. The scroll content ends with `Spacer().frame(height: 80)` (`:115`). The button bar is about 163 pt tall (`DeleteAccountBottomButtons.swift:22, 24, 27-29, 40-54`: divider 1, top padding 12, button 56, gap 10, cancel 48, bottom padding 36). At maximum scroll, the last ~80 pt of content is empty and the next ~83 pt is covered by the opaque bar, so the "Kept" group body sits behind the buttons. Contract row LT1 requires the spacer to keep the last line clear. This is code-derived; a device check at the default and largest Dynamic Type sizes is still required.

**WARNING — headline uses a hard line break.** `DeleteAccountWarningHeader.swift:22` has `"Are you sure you want to\ndelete your account?"`. The contract keeps the headline text, but the forced break fixes the wrap point, so at accessibility sizes it may produce a short orphan line. Consider letting the text wrap naturally.

### Pillar 3: Color (3/4)

**Met:** No new `Brand` token or color is added in Phase 05. The accent is reserved as specified: the `Cancellation policy` link uses `CancellationBrand.brandGreen` (`ClientCancellationView.swift:229`), the hub's `Not now` uses `Brand.onSurfaceVariant` (`SignupOverviewView.swift:155`), and the Delete Account group titles use `DeleteAccountBrand.onSurface` (`DeleteAccountWarningHeader.swift:55`), not red or accent. The only red stays on the existing primary button.

**WARNING — orange on a Phase 05 surface.** `ClientCancellationView.swift:216-219` shows the refund-changed notice in `Color.orange`. The contract's Color section says "uses no warning (orange) element" and lists the cancel confirmation as a Phase 05 surface. The line is pre-existing, not added by Phase 05, but the contract claims no orange here. Either move it onto a named token or amend the contract.

**WARNING — raw colors on the cancel flow.** `ClientCancellationView.swift:141` (`.foregroundColor(.black)` on Retry), `:273` (`.foregroundColor(.white)`), `:276` and `:280` (`.background(Color.black)`) bypass the `CancellationBrand` alias that the rest of the file uses. Pre-existing, on a screen Phase 05 changes.

### Pillar 4: Typography (3/4)

**Met:** The Phase 05 text uses the declared scale. Delete Account body and group titles use `.subheadline` Regular and Bold (`DeleteAccountWarningHeader.swift:44, 54`); the headline uses `.title` Bold (`:23`); the policy link uses `.subheadline` Regular (`ClientCancellationView.swift:228`). The feedback error follows the spec's follow-up: `FeedbackDetailsField.swift:50` uses `.brand(.caption)`, and `BrandFont.swift:37` defaults the weight to `.regular`, so the shipped weight matches the contract.

**Note — touched files carry more styles than the contract.** A grep over the 37 existing Phase 05 view files shows about 20 distinct `.brand` and system font calls, including `.caption2`, `.callout`, `.title2`, `.title3`, `.body`, and `.semibold`, `.medium` and `.light` weights. Almost all are pre-existing and outside the Phase 05 delta, which the contract exempts. No Phase 05 text was found outside the declared sizes.

### Pillar 5: Spacing (2/4)

**Met:** The Delete Account header stack is `spacing: 16` (`DeleteAccountWarningHeader.swift:21`), the group title gap is 4 (`:52`), and no new off-grid value was added in the changed code.

**WARNING — clearance contract failed.** `DeleteAccountView.swift:115` uses an 80 pt spacer under a ~163 pt pinned bar (see Pillar 2). The spec's LT1 backstop and the Delete Account layout rules both depend on this clearance. Replace the spacer with a bottom safe-area inset, as the top fix describes, so the scroll view measures the bar automatically.

**Note — off-scale pre-existing values on touched screens.** `DeleteAccountView.swift:112` and `:140` use `spacing: 28`; the scale is multiples of 4, and the contract lists Delete Account's existing layout as out of contract, so leave it. Off-grid values also remain on `ProfileLanguageField`, the settings screens and the feedback field, all pre-existing.

### Pillar 6: Experience Design (2/4)

**Met:** The 409 self-delete paths branch on `ErrorCode` (`DeleteAccountViewModel.swift:147-150`, `:174-177`) and keep the user on the feedback step. `CLIENT_HAS_UPCOMING_BOOKINGS` is added to `ErrorCode.swift:56`. The `View My Bookings` button is shown only when the blocker's side matches the active mode (`AccountDeletionBlocker.swift:47-53`). The language guard restores the previous list instead of saving an empty one (`ClientProfileSettingsViewModel.swift:295`). The gate fails open on a failed lookup (`ExpertModeGate.swift:31-48`). The Expert and Client Mode Switch paths all go through `ModeSwitchGate` (four call sites, see below). The zoom slider is disabled and dimmed for a downloaded photo (`ProfilePhotoZoomSlider` `.disabled(!isEnabled)` and `.opacity(isEnabled ? 1 : 0.35)`).

**WARNING — Mode Switch busy state is never visible.** The contract (section 2, and row L1 marked "covered") requires the two cards to be disabled while the switch lookup is in flight. In code, `ModeSwitchView.swift:74-76` calls `onConfirm(mode)` and then `dismiss()` synchronously. Each caller starts the work in a `Task` after the screen is already gone: `HomeClientView.swift:360-364`, `HomeExpertView.swift:305-309`, `ClientProfileHomeScreen.swift:242-249`, `ExpertProfileHomeScreen.swift:254-261`. The `.disabled(UserManager.shared.isSwitchingMode)` at `ModeSwitchView.swift:86` therefore never applies to a visible screen. The user gets no indicator while `lookUpSetupCompleted()` runs (a network round trip), and nothing stops them from re-entering Mode Switch and starting a second request (the generation counter in `UserManager.requestModeSwitch` keeps the state consistent, but the UI gives no hint). The contract's assumption A2 ("the screen dismisses on tap, so a spinner would rarely show") is the cause, and it leaves the user with no feedback at all, not just no spinner.

**UNRESOLVED (contract U2, accepted) — policy link hit area.** `ClientCancellationView.swift:226-232` has only a text-height tap target for `Cancellation policy`. Acceptable per the contract, but it is the one interactive element Phase 05 added below the 44 pt minimum. Revisit if the device check shows mis-taps.

**UNRESOLVED (contract U4, accepted) — hub email read.** The hub shows `Verify email` incomplete until `refreshEmailVerified()` returns. Accepted by the contract as a brief flash with no spinner.

---

## Contract drift to fix in the spec

- `05-UI-SPEC.md` status column says waves 2 to 6 (05-07 to 05-16) are "planned, not built". Git history shows them built (for example `c811481`, `e5a1cd8`, `77cd9a5`, `19a7f0a`, `342940a`, `1e35048`). Update the statuses before the device UAT, so testers do not check against a claim that the code no longer matches.
- Row L1 and the Mode Switch "busy state" row say the cards are disabled during the lookup; the code does not show that (see Pillar 6). Either restore the visible state or change the row.
- Colour section says "no warning (orange) element" on Phase 05 surfaces; `ClientCancellationView.swift:218` contradicts it (see Pillar 3).

---

## Files Audited

Delete Account:
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift`
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift`
- `ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountWarningHeader.swift`
- `ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountBottomButtons.swift`
- `ClickMe2026/Utils/AccountDeletionCopy.swift`
- `ClickMe2026/Utils/AccountDeletionBlocker.swift`
- `ClickMe2026/Model/Enums/ErrorCode.swift`

Mode switch and setup gate:
- `ClickMe2026/Views/Screens/Settings/Mode Switching/ModeSwitchView.swift`
- `ClickMe2026/Managers/ModeSwitchGate.swift`
- `ClickMe2026/Utils/ExpertModeGate.swift`
- `ClickMe2026/Managers/UserManager.swift` (`requestModeSwitch`, setup deferral)
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift`
- `ClickMe2026/Utils/HomeShellExit.swift`
- `ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift`

Cancellation:
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Cancellation Policies/Subviews/HowToInitiateCard.swift`

Signup:
- `ClickMe2026/Views/Screens/Signup Flow/Signup Review/SignupReviewView.swift`
- `ClickMe2026/Views/Screens/Signup Flow/Signup Review/SignupReviewViewModel.swift`
- `ClickMe2026/Views/Screens/Signup Flow/Basic Info/SignupBasicInfoView.swift`
- `ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoViewModel.swift`
- `ClickMe2026/Views/Screens/Signup Flow/Profile Photo/Subviews/ProfilePhotoZoomSlider.swift`
- `ClickMe2026/Utils/LocationFormatter.swift`
- `ClickMe2026/Utils/ProfilePhotoCropper.swift`

Settings:
- `ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsView.swift`
- `ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift`
- `ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/ProfileLanguageField.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsView.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift`
- `ClickMe2026/Views/Screens/Settings/Feedback/Subviews/FeedbackDetailsField.swift`
- `ClickMe2026/Views/Screens/Settings/Feedback/FeedbackViewModel.swift`
- `ClickMe2026/Views/Screens/Settings/Help/HelpView.swift`
- `ClickMe2026/Utils/SupportContact.swift`

Login and theme:
- `ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift`
- `ClickMe2026/Views/Screens/Login Flow/Login/LoginViewModel.swift`
- `ClickMe2026/Theme/BrandFont.swift`

Also read: `05-UI-SPEC.md`, `05-CONTEXT.md`, the 17 `05-NN-SUMMARY.md` files (key-files and deviations), and `git log` for the 05-xx commits. The `05-NN-PLAN.md` files were not read in full; the summaries and code were used to confirm what shipped.
