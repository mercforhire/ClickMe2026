---
phase: 05-signup-mode-switch-and-account
verified: 2026-11-15T07:30:00Z
status: passed
score: 13/16 must-haves verified
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
    ".planning/phases/05-signup-mode-switch-and-account/05-21-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-21-SUMMARY.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-22-PLAN.md",
    ".planning/phases/05-signup-mode-switch-and-account/05-22-SUMMARY.md",
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
    "ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift",
    "ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift",
    "ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift",
    "ClickMe2026Tests/Settings/ExpertMeetingLinkBodyTests.swift",
    "ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift",
    "ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift"
  ]
covered_digest: "v3:sha256:731a00094a97ce3e4d1a36d62cc02db2bf755b861130f1c0a845d91c8efca188"
behavior_unverified: 2
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/16
  gaps_closed:
    - "CR-01 / truth 16: clearing the expert meeting link is sent as meeting_url \"\" and a reload takes the server's link, nil read as \"\" (plan 05-21)"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "WR-01 (05-REVIEW.md): forceLoad() takes the held expert profile as the server's word even when this load's refreshExpertProfile() failed (try?). Two consecutive failed refreshes after a link save can leave a stale link, or a cached nil can blank a just-saved link, and the baseline is set to match so nothing corrects it. A pull to refresh inside the 1.2 s debounce window can also drop a pending edit"
    category: other
    reason: "Edge case that needs two network failures in a row, or a refresh inside the debounce window. The pre-05-21 code had the same stale-cache flaw for a non-nil link; 05-21 widened it to a nil link. No failing test exists, and the forceLoad call site has no test (IN-02). Fix is small: take the held profile only when the refresh succeeded"
    evidence_status: "none provided (code-read only)"
  - finding: "WR-02 (05-REVIEW.md): a 422 on professional_details.meeting_url is not in ProfileSaveErrorMapper's label table"
    category: other
    reason: "My earlier read stands: the backend promotes the hand-written message to the top level, so the alert still says 'Meeting link must be a valid URL.' The mixed-field case only"
    evidence_status: "none provided"
  - finding: "WR-03 (05-REVIEW.md): overlapping auto-saves are not serialised"
    category: other
    reason: "Edge race on a slow network (clear then retype quickly). No deterministic failing test"
    evidence_status: "none provided"
behavior_unverified_items:
  - truth: "SIGN-06: switching to Expert with incomplete setup opens the setup hub, and no switch is applied during a call, a superseded request writes nothing, and sign-out mid-lookup writes nothing"
    test: "05-DEVICE-UAT-CHECKLIST.md items 1 to 17"
    expected: "Hub opens for an unfinished expert, finished expert enters Expert, airplane mode fails open, no switch during a call, a push waits until the call ends, foreground re-check opens the hub"
    why_human: "ExpertModeGate decisions are unit-tested, but UserManager.requestModeSwitch, lookUpSetupCompleted, recheckSetupIfPending and the shells' call-end replay have no behavioral test. 05-UAT.md test 1 records items 1-3, 4, 5-11, 13-16 as PASS on a device (12 and 17 skipped as optional), so the evidence exists in the UAT record but not as an automated test."
  - truth: "SET-06 / UI-SPEC LT1: at maximum scroll the last line of the Delete Account 'Kept' group sits fully above the pinned buttons at every text size"
    test: "05-DEVICE-UAT-CHECKLIST.md item 34, block 'Re-test for SET-06 legibility (plan 05-22)'"
    expected: "On a small iPhone at the default and the largest accessibility size, scrolled to the bottom, the last Kept line reads in full above the buttons and the buttons look and behave as before"
    why_human: "Scroll geometry at accessibility sizes is a layout invariant. DeleteAccountView.swift now uses safeAreaInset(edge: .bottom, spacing: 0), the standard mechanism, but no unit test or grep can show where the last line lands. Result line is empty in the checklist."
coincidental_reliance_items: []
human_verification:
  - test: "SET-06 legibility re-test (checklist item 34 block, plan 05-22; UAT test 2 was skipped): Settings > Delete Account on a small iPhone at the default and the largest Dynamic Type size, scroll to the bottom of the confirmation step; tap Cancel, reopen, tap Delete Account (feedback step opens), leave without deleting"
    expected: "The last line of the Kept group is fully visible above the Delete Account and Cancel buttons, no group is cut off, the buttons look and behave as before"
    why_human: "Layout at accessibility sizes cannot be asserted in code or unit tests. Needs a build at or after 01e55f4."
  - test: "CR-01 device re-test (checklist section 'Re-test for CR-01 (plan 05-21)' after item 47): on an expert with a link, clear it, wait for the checkmark, reopen; type a link back; on an expert with no link, edit City only; with a second device, clear the link there, pull to refresh here, then edit City and reopen"
    expected: "No alert on any step. Cleared link stays empty after reopen. A typed link persists. After the pull to refresh the field is empty with no checkmark on its own, and it stays empty after a City edit and reopen"
    why_human: "The wire body and the reload rule are unit-tested, but a real PATCH to production and a second-device refresh are not. Needs a build at or after baad5a0, and production /health still reporting a commit that contains df7fb18 (28da165 when I checked)."
  - test: "G-05-1 re-test (checklist item 46): iPhone on iOS 26, Light appearance with Reduce Transparency on, then Liquid Glass Tinted, then Dark; open the setup hub with an unfinished expert"
    expected: "Not now reads as pale text on a dark capsule, never on a light grey one; still the quiet style; tapping it lands on client home"
    why_human: "The contrast of the iOS 26 glass capsule cannot be asserted in code. The three pins are present; only a device shows the render. Result line is PENDING."
  - test: "G-05-6 re-test (checklist item 22): account with empty names, client Profile Settings: clear State/Province, edit Bio, edit a language. Expert Profile Settings: edit City and the meeting link for an expert with an empty last name. Clear a set first name."
    expected: "No alert on any save. Clearing a set first name shows 'Please enter your first name.' under the field, keeps the old name on the server, and still saves a City edit. The reopened screen shows the saved values."
    why_human: "Unit rows run against a mock that copies the backend's min(1) 422, and the private expert performAutoSave cannot be driven without UserManager.shared. Result line is PENDING."
  - test: "Optional checklist items still unrun: 12 (slow network), 17 (live call on an unfinished account), 24 and 45 (resume signup email flash), 27 (language custom edit)"
    expected: "Each item's Expected block"
    why_human: "Skipped in UAT as optional or as needing another unpublished account"
---

# Phase 5: Signup, Mode Switch and Account Verification Report

**Phase Goal:** Users can finish signup, enter Expert mode only with a complete setup, and edit or close their account with saves that stick and copy that tells the truth
**Verified:** 2026-11-15T07:30:00Z
**Status:** human_needed
**Re-verification:** Yes, after gap-closure plans 05-21 (CR-01) and 05-22 (SET-06 legibility)

The one recorded gap, CR-01 (truth 16), is closed in code and covered by a passing wire-level test. The Delete Account layout fix is in place as a `safeAreaInset`, and its result can only be seen on a device. No truth fails. Status is `human_needed`, not `passed`, because two truths are present and wired but not behaviorally provable by tests (SIGN-06 orchestration, SET-06 scroll clearance), one render check is uncertain (G-05-1), and the project's definition of done requires the device re-tests that are still empty in the checklist. No device re-test of either gap-closure fix has been run.

## Re-check of the two items you named

### CR-01 (truth 16): closed

I read the code at HEAD, not the summary.

- `ExpertProfileSettingsViewModel.swift:363-378`: `meetingLinkBody(current:baseline:)` trims both sides, returns nil when equal, and otherwise builds a body with `meetingUrl: link`. A cleared link therefore goes out as `""`. The old nil-mapping local and the "server 422s on empty" comment are gone (`grep` for `meetingUrlForPatch` and `422s` returns nothing). The doc comment cites BACK-04, the schema refine and the controller's `|| null`.
- `makeExpertProfileUpdateBody()` (line 345) is the one-line delegation. `performAutoSave()` (lines 380-408) is unchanged in shape: both bodies built first, early return when both nil, `baselineMeetingUrl = sentMeetingUrl` only after the expert PATCH returns, mapper on failure. Because every non-nil body now carries `meeting_url`, the old empty `{"professional_details":{}}` request that was reported as saved can no longer be produced.
- Reload half: `forceLoad()` lines 244-245 assign `meetingUrl = Self.loadedMeetingLink(...)` and set `baselineMeetingUrl = trimmedMeetingUrl` on the very next line with no `await` between them. `loadedMeetingLink` (261-264) returns `current` only when no profile is held and otherwise `details.meetingUrl ?? ""`. `init` is unchanged (line 157, falls back to the argument, which every production call site leaves at `""`).
- Backend contract, read by me: `expertProfile.schema.js` accepts `""` and `null` for `meeting_url` (BACK-04 comment at lines 44-47); `expert.controller.js:158-160` stores `meeting_url || null`. `df7fb18` is an ancestor of backend `origin/main`. A read-only `GET /health` on production just now returned `{"status":"success","commit":"28da165"}`, the same commit the plan recorded, and the plan's merge-base check showed it contains `df7fb18`. So BACK-04 is live.
- Tests, run by me: `xcodebuild test` on `ExpertMeetingLinkReloadTests`, `ExpertMeetingLinkBodyTests`, `ProfileSettingsSaveTests` and `ProfileLanguagesSaveTests`: `Test run with 40 tests in 4 suites passed`, `** TEST SUCCEEDED **`. The named rows `CR-01: clearing a set meeting link sends an empty meeting_url`, `clearing a set link sends an empty string (BACK-04)` and `a reload where the server holds no link empties the field` each show a passed line. I read the tracer row: it takes a literal baseline, sends the body through `api.updateExpertProfile` against the mock, and asserts the captured wire keys are exactly `professional_details` then `meeting_url` with value `""`. It builds no view model, so it does not depend on `UserManager.shared`. That is a real behavioral check of the send half.
- Limit of that evidence: no test drives `forceLoad()` or `performAutoSave()` end to end (review IN-02). The reload rows compute the baseline themselves. I closed that gap by reading the two adjacent lines, which are straight-line code on the main actor. The device re-test (checklist section after item 47) is still the proof of the whole path.

Verdict on truth 16: VERIFIED, with the WR-01 advisory below.

### SET-06 legibility (truth 12): fix in place, result unproven

`DeleteAccountView.swift:108-132` now has the `ScrollView` with `.padding(.bottom, 24)` and `DeleteAccountBottomButtons` in `.safeAreaInset(edge: .bottom, spacing: 0)`, with every argument unchanged: the `CallCenter.shared.attempt("delete your account")` guard, `viewModel.advanceToFeedback()`, `isDeleting`, `secondaryAction: { dismiss() }`. The 80 pt `Spacer` and the bottom-aligned `ZStack` are gone. `feedbackView` is untouched. This is the correct mechanism for the occlusion that 05-UI-REVIEW.md found, and the previous failure (a fixed 80 pt under a bar of about 163 pt) cannot recur by construction. What I cannot show is where the last line lands on a small iPhone at the largest text size. That is a layout invariant, so it stays `PRESENT_BEHAVIOR_UNVERIFIED` and is routed to the checklist block under item 34, whose Result line is empty. The orchestrator's gate (build, no new warnings in the file, 883 tests green) says nothing about layout.

## REQUIREMENTS.md state: SET-06 is marked Complete prematurely

I diffed `.planning/REQUIREMENTS.md` from `2a93fdf` to HEAD. The only change is commit `8d363ee` (the 05-22 completion commit), which flipped `SET-06` from `[ ]` to `[x]` and its traceability row from `Pending` to `Complete`. My assessment:

- **It is not supported by the evidence.** The legibility check that this plan exists to close has no device result, and the plan's own SUMMARY (Next Phase Readiness) says SET-06 legibility "closes when the device re-test under item 34 passes". The prior verification said SET-06 "should stay pending until the Delete Account legibility check runs". The checklist, line 23, says nothing in the phase ticks a box in `REQUIREMENTS.md` and that `/gsd-verify-work 05` decides after the Results are filled in. The 05-22 plan did not list `REQUIREMENTS.md` in `files_modified`; the tick came from the completion bookkeeping, not from the task.
- **It is inconsistent with 05-21.** That plan also lists a requirement (SET-01), also has a code fix and an unrun device re-test, and was left reopened (`Gaps Found`). Two gap-closure plans in the same wave are treated opposite ways.
- **It is inconsistent with the table.** SIGN-01 to SIGN-06, SET-01, SET-03, SET-04 and SET-05 all read `Gaps Found`, and SET-02 and SET-07 read `Pending`, so SET-06 is the only requirement of the 13 ticked. And `2a93fdf` ("revert premature Complete requirements after gaps found") was needed once already for the same pattern.
- **The counter-argument, and why it does not rescue it.** The text of SET-06 is about copy accuracy, and the copy is verified in code and passed on a device (truth 11, UAT items 29, 30, 32, 35, 37-39, 43). On that narrow reading the requirement is met. But the whole point of 05-22 is that a user could not read the last "Kept" lines, so the copy did not reliably reach the user. The project's definition of done requires a device check, and none exists for this fix.

**Recommendation (not applied by me, since REQUIREMENTS.md is the orchestrator's bookkeeping):** revert SET-06 to `[ ]` and `Gaps Found`, the state of its neighbours, until checklist item 34's re-test passes. SET-01 is correctly left reopened by 05-21 and should stay so until the CR-01 section and item 22 pass. Separately, SET-02 and SET-07 have device PASS in UAT (tests 3 and 5) and can be ticked by `/gsd-verify-work 05`, and the other `Gaps Found` rows can be resolved the same way.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SIGN-01: an expert cannot publish without a photo | VERIFIED (regression check) | `SignupAccumulator.swift` is not in the diff since the last verification. |
| 2 | SIGN-05: the uploaded photo matches the crop the user set | VERIFIED (regression check) | Unchanged. Device UAT test 4 PASS. |
| 3 | SIGN-03: tags and languages saved in tap order | VERIFIED (regression check) | Unchanged files. |
| 4 | SIGN-04: country code normalized on publish | VERIFIED (regression check) | Unchanged. |
| 5 | SIGN-02: resuming signup keeps a verified email | VERIFIED (regression check) | Unchanged. |
| 6 | SIGN-06: Expert entered only through the gate; incomplete setup opens the hub | PRESENT_BEHAVIOR_UNVERIFIED | Unchanged since last verification: present and wired, `UserManager` orchestration has no automated behavioral test. UAT test 1 records device runs. Routed to human. |
| 7 | SET-01: language edits save to the server on both profile screens | VERIFIED | `ProfileLanguagesSaveTests` passed in my run (part of the 40). UAT items 23, 25, 26, 28 PASS. |
| 8 | SET-04: opening Notification preferences sends no save | VERIFIED (regression check) | Unchanged. |
| 9 | SET-02: Help > Email Us opens mail to the support address | VERIFIED | Unchanged. UAT test 3 PASS. |
| 10 | SET-05: Feedback needs at least 10 characters | VERIFIED (regression check) | Unchanged. |
| 11 | SET-03 and SET-06: no Pause card; Delete Account copy matches what the backend deletes and keeps | VERIFIED | `AccountDeletionCopy.swift` and `AccountDeletionBlocker.swift` unchanged; `DeleteAccountView` change touches layout only, the warning header and copy are not edited. UAT items 29, 30, 32, 35, 37-39, 43 PASS. |
| 12 | SET-06: the full Delete Account disclosure is readable above the pinned buttons | PRESENT_BEHAVIOR_UNVERIFIED (code closed in 05-22) | `safeAreaInset(edge: .bottom, spacing: 0)` at `DeleteAccountView.swift:120`, spacer and overlay removed. No test can show the rendered clearance. Device re-test (item 34 block) has no result. |
| 13 | SET-07: `CancellationPoliciesView` reachable, `ReadyToStartCallView` removed | VERIFIED | Unchanged. UAT test 5 PASS. |
| 14 | G-05-1: the setup hub's `Not now` button is legible | UNCERTAIN (code closed, render unproven) | `SignupOverviewView.swift` not changed since last verification. Device re-test (item 46) PENDING. |
| 15 | G-05-6: empty-name profile saves with no alert; 422 names the fields; a cleared set name shows an inline error and is not sent | VERIFIED (device re-test pending) | Passed in my run (`ProfileSettingsSaveTests`). `ProfileSettingsSnapshot.swift`, `ProfileSaveErrorMapper.swift` unchanged. Item 22 empty-profile re-test PENDING. |
| 16 | A Profile Settings edit the screen reports as saved is sent and persists, including clearing the expert meeting link and showing the server's link on reload | VERIFIED (device re-test pending, WR-01 advisory) | See "CR-01: closed" above. |

**Score:** 13/16 truths verified (2 present, behavior-unverified: 6 and 12; 1 uncertain, routed to human: 14)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | BACK-13: a client is promoted to expert only by an explicit setup call | Not scheduled (deferred past this release, D-04) | `REQUIREMENTS.md` BACK-13 and REL-02 record the reason. Accepted descope. |
| 2 | Backend `min(1)` on names versus OpenAPI and signup `''`; product decision on an empty last name; Android parity for the empty-name save | Todos logged by plan 05-20 | `.planning/todos/pending/2026-11-14-backend-profile-name-validation.md` and `...-android-profile-settings-empty-name-save.md`. |
| 3 | Availability settings toolbar Save button has the same unpinned-bar pattern | Todo logged by plan 05-18 | `.planning/todos/pending/2026-11-14-availability-settings-toolbar-dark-pin.md`. |
| 4 | Android never sends a cleared meeting link | Todo logged by plan 05-21 | `.planning/todos/pending/2026-11-15-android-expert-settings-clear-meeting-link.md`. Other repo, no code changed there, by design. |

### Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | WR-01: `forceLoad()` trusts the cached expert profile even when this load's refresh failed, so a stale link, or a cached nil blanking a just-saved link, can be shown and baselined; a refresh inside the 1.2 s debounce can drop a pending edit | other | Needs two failures in a row or a refresh inside the debounce. No deterministic failing test; the call site is untested (IN-02). Fix is small (use the held profile only when the refresh succeeded) and worth doing before the release build, but it does not contradict a truth I checked. |
| 2 | WR-02: a 422 on `meeting_url` is not in the mapper's label table | other | The stated case still shows the backend's own sentence. Mixed-field case only. |
| 3 | WR-03: overlapping auto-saves are not serialised | other | Edge race, no failing test. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ExpertProfileSettingsViewModel.swift` | `meetingLinkBody`, `loadedMeetingLink`, delegation, `forceLoad` rewire | VERIFIED | Read lines 150-275 and 322-410. |
| `DeleteAccountView.swift` | Confirmation step with bottom safe-area inset | VERIFIED (render needs device) | Lines 108-132. |
| `ExpertMeetingLinkBodyTests.swift` | 8 pure body rows | VERIFIED | 8 `@Test`, passed. |
| `ExpertMeetingLinkReloadTests.swift` | 5 pure reload rows | VERIFIED | 5 `@Test`, passed. |
| `ProfileSettingsSaveTests.swift` | Tracer row on the wire bytes | VERIFIED | Read the row; passed. |
| Android meeting-link todo | Parity follow-up | VERIFIED | Present under `.planning/todos/pending/`. |
| `05-DEVICE-UAT-CHECKLIST.md` | CR-01 section after item 47, SET-06 block under item 34 | VERIFIED | Both present (lines 434 and 614); items 34, 35, 47 headings intact, no item 48. Both Result lines empty. |
| Phase 5 first-round artifacts | As before | VERIFIED | Unchanged since the last verification. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `makeExpertProfileUpdateBody()` | `meetingLinkBody(current:baseline:)` | `Self.meetingLinkBody(current: meetingUrl, baseline: baselineMeetingUrl)` | WIRED | Line 345 |
| `performAutoSave()` | `PATCH /expert/profile` | `makeExpertProfileUpdateBody()` then `api.updateExpertProfile` | WIRED | Lines 383-398 |
| `meetingLinkBody` clear | backend `meeting_url` refine (BACK-04) | `""` passes the refine, controller stores NULL | WIRED | Read both backend files; live per `/health` |
| `forceLoad()` | `loadedMeetingLink(from:current:)` | held profile's professional details, rebaseline on the next line | WIRED | Lines 244-245 |
| `confirmationView` ScrollView | `DeleteAccountBottomButtons` | `.safeAreaInset(edge: .bottom, spacing: 0)` | WIRED | Line 120 |
| Earlier gap-closure links (snapshot patch, error mapper, name errors, hub bar pins) | | | WIRED | Files unchanged since the last verification. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Expert meeting link field | `meetingUrl`, `baselineMeetingUrl` | `GET /expert/profile` via `refreshExpertProfile()`, then the static rule | Yes for set, change, clear and reload; stale only if the refresh fails (WR-01) | FLOWING |
| Clear request | `professional_details.meeting_url` | `meetingLinkBody` | Yes, `""` reaches the wire (tracer row) | FLOWING |
| Delete Account disclosure | `DeleteAccountWarningHeader` content | `AccountDeletionCopy` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Clear sends `meeting_url: ""`; reload and body rules; save and language suites | `xcodebuild test -only-testing:` `ExpertMeetingLinkReloadTests`, `ExpertMeetingLinkBodyTests`, `ProfileSettingsSaveTests`, `ProfileLanguagesSaveTests` (iPhone 17 simulator) | `Test run with 40 tests in 4 suites passed`, `** TEST SUCCEEDED **` | PASS |
| Stale artifacts of the old rule are gone | `grep` for `meetingUrlForPatch` and `422s` in the view model | no matches | PASS |
| TBD/FIXME/XXX/TODO/HACK in the five changed Swift files | `grep -n` | no matches | PASS |
| BACK-04 live in production | read-only `GET /health` | `commit: 28da165`, which the plan showed contains `df7fb18` | PASS |
| Rendered clearance of the Kept group | none possible without a device | not testable | SKIP, routed to human |

I did not re-run the full suite. The orchestrator's post-merge run (883 tests in 90 suites passed, no warnings in the two changed source files) is taken as given and is consistent with my 40-test run.

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
| SIGN-06 | 05-07, 05-10, 05-12, 05-16, 05-18 | Expert switch with incomplete setup opens the hub | SATISFIED on device (UAT test 1); no automated orchestration test; G-05-1 render pending | Truths 6, 14 |
| SET-01 | 05-09, 05-19, 05-20, 05-21 | Language edits save | SATISFIED in code and unit tests; device re-tests (item 22, CR-01 section) pending | Truths 7, 15, 16 |
| SET-02 | 05-05 | Email Us opens mail to the support address | SATISFIED (UAT PASS) | Truth 9 |
| SET-03 | 05-15 | Pause card removed | SATISFIED | Truth 11 |
| SET-04 | 05-05 | No save on opening notification preferences | SATISFIED | Truth 8 |
| SET-05 | 05-05 | Feedback needs 10 characters | SATISFIED | Truth 10 |
| SET-06 | 05-08, 05-14, 05-15, 05-22 | Accurate Delete Account copy and 409 blockers | SATISFIED for copy; legibility fix in code, device re-test not run | Truths 11, 12 |
| SET-07 | 05-06, 05-17 | Dead screens wired in or deleted | SATISFIED (UAT PASS) | Truth 13 |

All 13 IDs from the roadmap appear in at least one plan's `requirements` field (05-21 lists SET-01, 05-22 lists SET-06). `REQUIREMENTS.md` maps no other ID to Phase 5, so there are no orphans.

Bookkeeping, current `REQUIREMENTS.md` against the evidence: SET-06 `[x]`/`Complete` is premature (see the section above). SET-01 `Gaps Found` is consistent with the pending device re-tests. SET-02 and SET-07 are `Pending` despite device PASS and can be ticked. SIGN-01 to SIGN-06, SET-03, SET-04 and SET-05 read `Gaps Found` and need `/gsd-verify-work 05` to settle them once the Results are filled in.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ExpertProfileSettingsViewModel.swift` | 242-245, 261-264 | Held profile treated as the server's word even when the refresh failed (`try?`) | Warning (WR-01, advisory) | Edge case, see Advisory |
| `ExpertProfileSettingsViewModel.swift` | 435-436 | Empty trailing `// MARK: - Error mapping` section | Info | Dead scaffolding |
| `ExpertProfileSettingsViewModel.swift` | 365 | Baseline trimmed again in the static (baseline is already trimmed) | Info | IN-01, harmless |
| `ProfileSettingsSnapshot.swift` | 52-59 | Names trimmed with `.whitespaces`, not newlines | Info | IN-03 |
| Five changed Swift files | - | TBD, FIXME, XXX, TODO, HACK | none | No debt markers |
| `UserManager.swift` and others | - | PRIOR-WR-03 to PRIOR-WR-06, PRIOR-IN-04 | Warning | Still `open` in `05-REVIEW-DISPOSITION.md` (11 of 12 findings open). None contradicts a roadmap success criterion. Decide before the release build. |

### Human Verification Required

See the `human_verification` frontmatter list. These are required for the project's definition of done and none has a result yet:

1. **SET-06 legibility** (item 34 block, plan 05-22): last Kept line above the buttons, small iPhone, default and largest text size.
2. **CR-01 re-test** (section after item 47, plan 05-21): clear a link and reopen, type it back, no-link City edit, second-device clear then pull to refresh. Re-check production `/health` before the session.
3. **G-05-1 re-test** (item 46): `Not now` legible in Light plus Reduce Transparency, Liquid Glass Tinted and Dark.
4. **G-05-6 re-test** (item 22): empty-name account saves with no alert, inline name error, expert City and meeting-link edits.
5. **Optional unrun items**: 12, 17, 24, 27, 45.

### Gaps Summary

No gaps remain. CR-01 is closed and was independently confirmed from the code, the backend schema and controller, production `/health`, and a passing wire-level test. The SET-06 legibility fix is correctly built and awaits its device check. Actions before the phase counts as done:

- Run the device re-tests above on a build at or after `baad5a0` and `01e55f4`.
- Revert SET-06 to unticked and `Gaps Found` in `REQUIREMENTS.md` until item 34's re-test passes; leave SET-01 reopened until the CR-01 section and item 22 pass.
- Decide on WR-01 (a small `forceLoad()` change) before the release build, and re-check BACK-04 in production read-only at release time.

---

_Verified: 2026-11-15T07:30:00Z_
_Verifier: Claude (gsd-verifier)_
