---
phase: 05-signup-mode-switch-and-account
verified: 2026-11-15T06:00:00Z
status: gaps_found
score: 12/16 must-haves verified
covered_files: [
    ".planning/phases/05-signup-mode-switch-and-account/05-01-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-01-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-02-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-02-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-03-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-03-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-04-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-04-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-05-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-05-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-06-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-06-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-07-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-07-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-08-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-08-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-09-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-09-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-10-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-10-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-11-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-11-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-12-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-12-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-13-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-13-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-14-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-14-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-15-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-15-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-16-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-16-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-17-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-17-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-18-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-18-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-19-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-19-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-20-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-20-SUMMARY.md",
    "ClickMe2026/Managers/ModeSwitchGate.swift",
    "ClickMe2026/Managers/UserManager.swift",
    "ClickMe2026/Network/Error+UserMessage.swift",
    "ClickMe2026/Utils/AccountDeletionBlocker.swift",
    "ClickMe2026/Utils/AccountDeletionCopy.swift",
    "ClickMe2026/Utils/ExpertModeGate.swift",
    "ClickMe2026/Utils/LocationFormatter.swift",
    "ClickMe2026/Utils/ProfilePhotoCropper.swift",
    "ClickMe2026/Utils/ProfileSaveErrorMapper.swift",
    "ClickMe2026/Utils/ProfileSettingsSnapshot.swift",
    "ClickMe2026/Utils/SupportContact.swift",
    "ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift",
    "ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift",
    "ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/ProfileLabeledField.swift",
    "ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift",
    "ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift"
  ]
covered_digest: "v3:sha256:887c3e04d340dfe707b1b3ac334838da6105f3d08ddd8731fd4fda2274f0ee73"
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 11/13
  gaps_closed:
    - "G-05-6 (code): an empty-name profile can save a State/Province, bio or language edit; a 422 names the fields (plans 05-19, 05-20)"
    - "G-05-1 (code): the setup hub nav bar is pinned dark with the sibling-screen pattern (plan 05-18)"
  gaps_remaining:
    - "Clearing the expert meeting link is dropped and reported as saved (CR-01)"
  regressions: []
gaps:
  - truth: "A Profile Settings edit that the screen reports as saved is sent to the server and persists after reopening (G-05-6 truth wording), including clearing the expert meeting link"
    status: failed
    reason: "ExpertProfileSettingsViewModel.makeExpertProfileUpdateBody() turns an emptied link into meetingUrl nil, which the Encodable body omits, so the request is {\"professional_details\":{}}. The server keeps the old link. performAutoSave then sets baselineMeetingUrl to \"\", refreshes the profile and shows the saved checkmark. The old link returns on the next load(). The stale in-code comment says the server 422s on \"\", but BACK-04 (backend df7fb18, contained in origin/main) now accepts \"\" and null and stores NULL. The pre-05-19 code dropped the clear the same way, so this is pre-existing, not a regression, but plan 05-19 kept the rule knowingly and now treats the empty request as a successful save."
    artifacts:
      - path: "ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift"
        issue: "Lines 327-345: link.isEmpty ? nil : link; stale comment about a 422 on empty; performAutoSave rebaselines after the dropped clear"
    missing:
      - "Send meeting_url \"\" when the baseline held a link and the trimmed field is now empty (BACK-04 contract); keep omitting it when the baseline was already empty"
      - "Delete the stale 'server 422s on empty' comment"
      - "Unit test: clearing a previously set link produces a body whose professional_details.meeting_url is \"\" (makeExpertProfileUpdateBody is internal, so this is testable without UserManager)"
      - "Confirm BACK-04 is live on the production deploy before the release build (it is on origin/main of the backend repo)"
behavior_unverified_items:
  - truth: "SIGN-06: switching to Expert with incomplete setup opens the setup hub, and no switch is applied during a call, a superseded request writes nothing, and sign-out mid-lookup writes nothing"
    test: "05-DEVICE-UAT-CHECKLIST.md items 1 to 17"
    expected: "Hub opens for an unfinished expert, finished expert enters Expert, airplane mode fails open, no switch during a call, a push waits until the call ends, foreground re-check opens the hub"
    why_human: "ExpertModeGate decisions are unit-tested, but UserManager.requestModeSwitch, lookUpSetupCompleted, recheckSetupIfPending and the shells' call-end replay have no behavioral test. 05-UAT.md test 1 records items 1-3, 4, 5-11, 13-16 as PASS on a device (12 and 17 skipped as optional), so the evidence exists in the UAT record but not as an automated test."
coincidental_reliance_items: []
human_verification:
  - test: "G-05-1 re-test (checklist item 46): iPhone on iOS 26, Light appearance with Reduce Transparency on, then Liquid Glass set to Tinted, then Dark; open the setup hub with an unfinished expert"
    expected: "Not now reads as pale text on a dark capsule, never on a light grey one; still the quiet style; tapping it lands on client home"
    why_human: "The contrast of the iOS 26 glass capsule cannot be asserted in code or unit tests. The three pins are present, but only a device shows the render. Result line is PENDING in the checklist."
  - test: "G-05-6 re-test (checklist item 22): account with empty names, client Profile Settings: clear State/Province, edit Bio, edit a language. Expert Profile Settings: edit City and the meeting link for an expert with an empty last name. Clear a set first name."
    expected: "No alert on any of the saves. Clearing a set first name shows 'Please enter your first name.' under the field, keeps the old name on the server, and still saves a City edit. The reopened screen shows the saved values."
    why_human: "Unit rows run against a mock that copies the backend's min(1) 422, and the private expert performAutoSave cannot be driven without UserManager.shared. Result line is PENDING in the checklist."
  - test: "SET-06 legibility (UAT test 2, skipped): Settings > Delete Account on a small iPhone and at the largest Dynamic Type size, scroll to the bottom of the confirmation step"
    expected: "The last 'Kept' group is fully readable and not behind the pinned Delete and Cancel buttons"
    why_human: "DeleteAccountView.swift gives the scroll content an 80 pt spacer under a bar of about 163 pt, so up to about 83 pt of the last group may sit behind the bar. The geometry is code-derived, UAT test 2 was skipped with no reason, and 05-UI-REVIEW.md flags it as an open warning."
  - test: "Optional checklist items still unrun: 12 (slow network), 17 (live call on an unfinished account), 24 and 45 (resume signup email flash), 27 (language custom edit)"
    expected: "Each item's Expected block"
    why_human: "Skipped in UAT as optional or as needing another unpublished account"
---

# Phase 5: Signup, Mode Switch and Account Verification Report

**Phase Goal:** Users can finish signup, enter Expert mode only with a complete setup, and edit or close their account with saves that stick and copy that tells the truth
**Verified:** 2026-11-15T06:00:00Z
**Status:** gaps_found
**Re-verification:** Yes, after UAT and gap-closure plans 05-18, 05-19 and 05-20

All 13 requirement IDs have code that exists, is wired and is not a stub, and both UAT gaps (G-05-1, G-05-6) are closed in code. One new gap stands: clearing the expert meeting link is silently dropped while the screen shows a saved checkmark. This is the review's CR-01. I confirmed it independently from the code and the backend schema. It is small, fixable in one view-model method plus a test, and the backend side is already live. It does not touch any of the 13 requirement IDs or the five roadmap success criteria, but it contradicts the phase goal's "saves that stick" and the project's core value of not silently dropping user actions, so I record it as a gap, not a warning.

## Assessment of CR-01 against the phase goal

- **Confirmed in code.** `makeExpertProfileUpdateBody()` (ExpertProfileSettingsViewModel.swift:327-345) returns `meetingUrl: link.isEmpty ? nil : link`. `UpdateExpertProfileRequest` is a synthesized `Encodable`, so `nil` is omitted and the body is `{"professional_details":{}}`. `performAutoSave` (351-376) then sets `baselineMeetingUrl = sentMeetingUrl`, runs `refreshExpertProfile()` and sets `didAutoSave = true`.
- **Confirmed against the backend.** `expertProfile.schema.js:44-53` accepts `""` and `null` (BACK-04). `expert.controller.js:158-160` stores `meeting_url || null`. Backend commit `df7fb18` ("allow experts to clear meeting_url") is contained in `origin/main`, and Phase 1 recorded BACK-04 complete. The iOS comment claiming a 422 on `""` is stale.
- **Pre-existing, not introduced by the gap plans.** The code at `23da555` also coerced an empty link to nil and dropped the clear. 05-19 kept that rule on purpose ("existing empty-link-to-omitted-key rule") while it was written for a backend that has since changed. So this is not a Phase 5 regression, but it is the exact "saves that don't stick" failure the phase targets, now with a backend that can accept the fix.
- **Scope.** Expert-only, clear-only (setting or changing a link works), and the link is optional. No SIGN or SET requirement names it. That is why the other 12 verified truths stand, and why the severity is "one narrow gap" and not "phase goal not met".

I also checked the review's WR-01 claim and found it overstated for the stated case. An invalid meeting link 422 carries the hand-written message "Meeting link must be a valid URL." The backend's `validationSummaryMessage` (`utils/errors.js`) promotes any non-blank message that is not a raw Zod default to the top-level `message`. The mapper finds no mapped label and falls back to `userMessage`, so the alert does show that sentence. What remains of WR-01 is the mixed case (one 422 listing a mapped and an unmapped field names only the mapped one). That is minor.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SIGN-01: an expert cannot publish without a photo | VERIFIED (regression check) | `SignupAccumulator.missingForPublish` still present (line 94) and `isReadyToPublish` derives from it. Unchanged since the last verification. |
| 2 | SIGN-05: the uploaded photo matches the crop the user set | VERIFIED (regression check) | `ProfilePhotoCropper.swift` exists. Device UAT test 4 PASS. |
| 3 | SIGN-03: tags and languages saved in tap order | VERIFIED (regression check) | Unchanged files. |
| 4 | SIGN-04: country code normalized on publish | VERIFIED (regression check) | Unchanged. `Countries.normalize` is also used by the new snapshot patch. |
| 5 | SIGN-02: resuming signup keeps a verified email | VERIFIED (regression check) | Unchanged. |
| 6 | SIGN-06: Expert entered only through the gate; incomplete setup opens the hub | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Present and wired; `grep` for `setMode(` / `.currentMode =` outside `UserManager.swift` finds 0 matches. `UserManager` orchestration still has no automated behavioral test. UAT test 1 records the device runs (items 1-11, 13-16 PASS, 12 and 17 skipped). Counts as human-verified evidence, not as an automated one. |
| 7 | SET-01: language edits save to the server on both profile screens | VERIFIED | `ProfileSettingsSnapshot.patch(from:)` sends `languages` only when ids changed, with custom languages, never leaving zero (A9). `ProfileLanguagesSaveTests` passed in this run. UAT items 23, 25, 26, 28 PASS. |
| 8 | SET-04: opening Notification preferences sends no save | VERIFIED (regression check) | Unchanged. |
| 9 | SET-02: Help > Email Us opens mail to the support address | VERIFIED | Address is spelled in one Swift file (`SupportContact.swift:17`). UAT test 3 PASS on a device. |
| 10 | SET-05: Feedback needs at least 10 characters | VERIFIED (regression check) | Unchanged. |
| 11 | SET-03 and SET-06: no Pause card; Delete Account copy matches what the backend deletes and keeps | VERIFIED | `DeleteAccountPauseCard.swift` absent. `AccountDeletionBlocker.swift` and `AccountDeletionCopy.swift` present. Compared line by line in the first verification. UAT items 29, 30, 32, 35, 37-39, 43 PASS. |
| 12 | SET-06: the full Delete Account disclosure is readable above the pinned buttons | ? UNCERTAIN | Not resolved. UAT test 2 was skipped with no reason. The 80 pt spacer under a 163 pt bar is unchanged. Routed to human verification. |
| 13 | SET-07: `CancellationPoliciesView` reachable, `ReadyToStartCallView` removed | VERIFIED | `find` returns no `ReadyToStartCallView`, `LanguageEditorSheet` or `DeleteAccountPauseCard` file. UAT test 5 PASS on a device. |
| 14 | G-05-1: the setup hub's `Not now` button is legible (A1 quiet style kept) | ? UNCERTAIN (code closed, render unproven) | `SignupOverviewView.swift:117-119` has `toolbarBackground(Brand.surface, for: .navigationBar)`, `toolbarBackground(.visible, for: .navigationBar)` and `toolbarColorScheme(.dark, for: .navigationBar)`, identical to `SignupReviewView.swift:100-102`. `OverviewNotNowChrome` still has `navigationBarBackButtonHidden(true)` and `BookingRequestSentPopGestureLock()` once each (lines 155-156), body font and `Brand.onSurfaceVariant` unchanged, no `preferredColorScheme`. The 10.84:1 vs 1.52:1 contrast figures are the debug session's simulator measurement, not mine. Device re-test is PENDING. |
| 15 | G-05-6: on an empty-name profile a State/Province, bio or language edit saves with no alert; a 422 names the fields in iOS copy; a cleared set name shows an inline error and is not sent | VERIFIED (device re-test pending) | `ProfileSettingsSnapshot.patch(from:)` sends a name key only when non-empty and only changed groups; `merging(_:)` takes exactly the sent keys. Both view models build the body from it (`ClientProfileSettingsViewModel.swift:314-315, 322, 330`; `ExpertProfileSettingsViewModel.swift` `makeProfileUpdateBody`). Both `performAutoSave` catch blocks call `ProfileSaveErrorMapper.message(for:)`. `Error.validationFieldErrors` branches on status 422 and `ErrorCode.validationError`. `ProfileLabeledField(error:)` is wired for First and Last Name on both screens (Client view lines 130-131; Expert view lines 127-128); other call sites keep the nil default. I ran `ProfileSettingsSnapshotTests`, `ProfileSettingsSaveTests`, `ProfileSaveErrorMapperTests` and `ProfileLanguagesSaveTests`: 64 tests in 4 suites passed. I read the backend schema: `first_name` and `last_name` are `min(1)` and the group is `.strict()`, so the fix matches the real rule. UAT confirmed item 22 passes on a complete profile; the empty-profile re-test is PENDING. |
| 16 | A Profile Settings edit the screen reports as saved is sent and persists, including clearing the expert meeting link | ✗ FAILED | See the CR-01 assessment above and the `gaps:` entry. |

**Score:** 12/16 truths verified (1 present, behavior-unverified; 2 uncertain, routed to human; 1 failed)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | BACK-13: a client is promoted to expert only by an explicit setup call | Not scheduled (deferred past this release, D-04) | `REQUIREMENTS.md` BACK-13 and REL-02 record the reason. The iOS Expert-mode gate is the user-facing fix. Accepted descope, not a gap. |
| 2 | Backend `min(1)` on names versus OpenAPI and signup `''`; product decision on accepting an empty last name; Android parity for the empty-name save | Logged as todos by plan 05-20 | `.planning/todos/pending/2026-11-14-backend-profile-name-validation.md` and `...-android-profile-settings-empty-name-save.md`. Other repos, no code changed there, by design. |
| 3 | Availability settings toolbar Save button has the same unpinned-bar pattern | Logged as a todo by plan 05-18 | `.planning/todos/pending/2026-11-14-availability-settings-toolbar-dark-pin.md`. Out of the G-05-1 scope. |

### Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | WR-02: overlapping auto-saves are not serialised, so the baseline can go stale when responses arrive out of order | other | Real but an edge race on a slow network. No deterministic failing test exists. Not blocking. |
| 2 | WR-01 (remaining part): a 422 that lists one mapped and one unmapped field names only the mapped one | other | The stated meeting-link case is not a defect (see above). Mixed case only. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Utils/ProfileSettingsSnapshot.swift` | Trimmed snapshot, `patch(from:)`, `merging(_:)`, name errors | VERIFIED | Read in full. Used by both view models. |
| `Utils/ProfileSaveErrorMapper.swift` | Field labels for a 422, else `userMessage` | VERIFIED | Called from both catch blocks. |
| `Network/Error+UserMessage.swift` | `validationFieldErrors`, `userMessage` unchanged | VERIFIED | Branches on 422 and `ErrorCode`. |
| `ProfileLabeledField.swift` | Optional `error`, default nil | VERIFIED | All other call sites unchanged. |
| `SignupOverviewView.swift` | Hub bar pinned dark | VERIFIED (render needs device) | Three pins present. |
| Test files `ProfileSettingsSnapshotTests`, `ProfileSettingsSaveTests`, `ProfileSaveErrorMapperTests` | Pure and save-path rows | VERIFIED | Passed in this run. |
| Backend and Android todos, Availability todo | Follow-ups logged | VERIFIED | Present under `.planning/todos/pending/`. |
| Phase 5 first-round artifacts (cropper, support contact, gates, deletion copy and blocker, accumulator) | As before | VERIFIED | All files still present. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `makeProfileUpdateBody()` (both VMs) | `ProfileSettingsSnapshot.patch(from:)` | current snapshot vs baseline | WIRED | |
| `performAutoSave()` success (both VMs) | `baseline.merging(body)` | sent keys only | WIRED | |
| `performAutoSave()` catch (both VMs) | `ProfileSaveErrorMapper.message(for:)` | `autoSaveError` alert | WIRED | |
| `ProfileSaveErrorMapper` | `Error.validationFieldErrors` | 422 `VALIDATION_ERROR` | WIRED | |
| First/Last Name fields (both screens) | `firstNameError` / `lastNameError` | `ProfileLabeledField(error:)` | WIRED | |
| Expert meeting-link clear | `PATCH /expert/profile` `meeting_url: ""` | `makeExpertProfileUpdateBody()` | NOT_WIRED | Empty link becomes an omitted key (gap) |
| Hub body | navigation bar dark pins | three modifiers | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Profile settings baseline | `baseline` | `GET /user/profile` hydrate, then `merging` the sent body | Yes | FLOWING |
| Expert meeting link field | `meetingUrl`, `baselineMeetingUrl` | `refreshExpertProfile()` | Yes for set and change; a clear never reaches the server | ⚠️ HOLLOW for clear |
| Save error alert | `autoSaveError` | Decoded 422 `errors[]` through the mapper | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gap-closure suites | `xcodebuild test -only-testing` for ProfileSettingsSnapshotTests, ProfileSettingsSaveTests, ProfileSaveErrorMapperTests, ProfileLanguagesSaveTests (iPhone 17 Pro simulator) | `Test run with 64 tests in 4 suites passed`, `** TEST SUCCEEDED **` | PASS |
| `setMode` not reachable outside `UserManager` | grep `setMode(\|\.currentMode *=` outside `UserManager.swift` | 0 matches | PASS |
| Dead screens removed | `find` for `ReadyToStartCallView*`, `LanguageEditorSheet*`, `DeleteAccountPauseCard*` | none found | PASS |
| Support address in one Swift file | grep `clickmeapp@` | only `SupportContact.swift:17` | PASS |
| Meeting-link clear is sent | read `makeExpertProfileUpdateBody()` and the request type | empty link becomes nil, key omitted | FAIL |

The full suite was not re-run by me. The orchestrator reported 869 tests in 88 suites passing at HEAD, with only the pre-existing template UI test `ExampleUITests.testExample` failing; that failure is not a phase regression.

### Probe Execution

Step 7c: SKIPPED. No probes are declared in any PLAN or SUMMARY, and this is not a migration or tooling phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SIGN-01 | 05-04 | Expert cannot publish without a photo | SATISFIED | Truth 1 |
| SIGN-02 | 05-11 | Resuming signup keeps the verified email | SATISFIED | Truth 5 |
| SIGN-03 | 05-02 | Tags and languages keep tap order | SATISFIED | Truth 3 |
| SIGN-04 | 05-04 | Country code normalized | SATISFIED | Truth 4 |
| SIGN-05 | 05-03 | Photo matches the crop | SATISFIED (UAT PASS) | Truth 2 |
| SIGN-06 | 05-07, 05-10, 05-12, 05-16, 05-18 | Expert switch with incomplete setup opens the hub | SATISFIED on device (UAT test 1), no automated orchestration test; G-05-1 render pending | Truths 6, 14 |
| SET-01 | 05-09, 05-19, 05-20 | Language edits save | SATISFIED in code and unit tests; device re-test of item 22 pending. The adjacent meeting-link clear is a separate gap (truth 16) | Truths 7, 15, 16 |
| SET-02 | 05-05 | Email Us opens mail to the support address | SATISFIED (UAT PASS) | Truth 9 |
| SET-03 | 05-15 | Pause card removed | SATISFIED | Truth 11 |
| SET-04 | 05-05 | No save on opening notification preferences | SATISFIED | Truth 8 |
| SET-05 | 05-05 | Feedback needs 10 characters | SATISFIED | Truth 10 |
| SET-06 | 05-08, 05-14, 05-15 | Accurate Delete Account copy and 409 blockers | SATISFIED for copy; legibility unresolved | Truths 11, 12 |
| SET-07 | 05-06, 05-17 | Dead screens wired in or deleted | SATISFIED (UAT PASS) | Truth 13 |

All 13 IDs from the roadmap appear in at least one plan's `requirements` field (05-18 lists SIGN-06; 05-19 and 05-20 list SET-01). `REQUIREMENTS.md` maps no other ID to Phase 5, so there are no orphans.

Bookkeeping: `REQUIREMENTS.md` shows SIGN-01 to SIGN-06, SET-01, SET-03, SET-04 and SET-05 Complete, and SET-02, SET-06 and SET-07 Pending. SET-02 and SET-07 now have device PASS (UAT tests 3 and 5) and can be ticked. SET-06 should stay pending until the Delete Account legibility check runs. The 05-19 plan notes that SET-01 counts as closed again only after the item 22 device re-test and the CR-01 fix; the file still shows it Complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `Expert Mode/Settings/ExpertProfileSettingsViewModel.swift` | 327-345 | Empty meeting link coerced to nil, request sent with empty `professional_details`, then rebaselined | 🛑 Blocker (for truth 16) | Clear is silently lost, UI shows saved |
| `Expert Mode/Settings/ExpertProfileSettingsViewModel.swift` | 331-338 | Stale comment: "server 422s on empty" | ℹ️ Info | Misleads the next editor, contradicts BACK-04 |
| `Expert Mode/Settings/ExpertProfileSettingsViewModel.swift` | 406 | Empty trailing `// MARK: - Error mapping` section | ℹ️ Info | Dead scaffolding |
| `ProfileSettingsSnapshot.swift` | 52-59 | Names trimmed with `.whitespaces`, not newlines | ℹ️ Info | IN-01, a newline-only name would pass the iOS guard and 422, now named by the mapper |
| 13 changed Swift files in the gap plans | - | TBD, FIXME, XXX | none | No unreferenced debt markers |
| `DeleteAccountView.swift` | 115 | 80 pt spacer under a 163 pt pinned bar | ⚠️ Warning | Truth 12, unchanged |
| `UserManager.swift` | - | WR-03 to WR-06 from the first review | ⚠️ Warning | Still `open` in `05-REVIEW-DISPOSITION.md`. None contradicts a roadmap success criterion. |

All 11 findings in `05-REVIEW-DISPOSITION.md` are `open`. CR-01 is the only one I treat as a gap. WR-01 is mostly a false alarm. WR-02 is an edge race. The rest stay warnings for a decision before the release build.

### Human Verification Required

See the `human_verification` frontmatter list. These do not change the status while a gap exists, but they remain required for the project's definition of done (device check on a real iPhone):

1. **G-05-1 re-test** (checklist item 46): `Not now` legible in Light plus Reduce Transparency, Liquid Glass Tinted and Dark.
2. **G-05-6 re-test** (checklist item 22): empty-name account saves with no alert, inline name error, expert City and meeting-link edits.
3. **Delete Account legibility** (UAT test 2, skipped): last "Kept" group readable on a small iPhone and at the largest Dynamic Type size.
4. **Optional unrun items**: 12, 17, 24, 27, 45.

### Gaps Summary

One gap, small and well bounded:

- **Meeting-link clear is dropped (truth 16).** Fix `makeExpertProfileUpdateBody()` to send `""` when the baseline held a link and the field is now empty, remove the stale 422 comment, and add a unit test on the body builder. Confirm BACK-04 is live in production first (the commit is on the backend's `origin/main`, and Phase 1 recorded it complete). If it turns out not to be live, show an explicit "can't clear the link yet" message instead of a checkmark. Run `/gsd-plan-phase 5 --gaps` for a one-task closure plan.

Everything else in the gap-closure scope holds up: the changed-group patch matches the backend's `.strict()` and `min(1)` schema, the 422 mapper branches on `ErrorCode` and never shows raw validator text, the name errors are wired on both screens, and the hub bar pins match the sibling screens. The G-05-1 render and the G-05-6 empty-profile behavior still need their device re-tests.

---

_Verified: 2026-11-15T06:00:00Z_
_Verifier: Claude (gsd-verifier)_
