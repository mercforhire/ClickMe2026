---
phase: 08-release
plan: "06"
subsystem: android-parity
tags: [android, kotlin, profile-settings, meeting-link, validation, parity, tdd]

requires:
  - phase: 08
    provides: "backend BACK-04 (df7fb18) accepts meeting_url \"\" and stores NULL; iOS CR-01 and G-05-6 rules as the source of truth"
provides:
  - "Android expert settings can clear a saved Skype/Zoom link: PATCH /expert/profile sends professional_details.meeting_url \"\""
  - "Android client and expert Profile Settings never send an empty first_name / last_name and hold a cleared set name with the iOS required-name messages"
  - "Android ProfileSaveErrorMapper: a 422 VALIDATION_ERROR on a profile save reads 'Check {fields}, then try again.' in iOS labels and screen order, never server text"
affects: [08-21, android-release, 08-REGRESSION-CHECKLIST]

actuals:
  tokens: 13129
  tasks: 3
  commits: 3

plan_head_before: 50626142e5e57f50aea0108bd7895588404a5cf0
plan_head_after: 337f4c0c659f25bf39c073a8238e628c4872c670
commits: 3

tech-stack:
  added: []
  patterns:
    - "Android meeting-link snapshot: blank text enters as \"\" (a clear), valid text as trimmed, invalid text keeps the saved link; linkWillSend() is the single predicate for the save and for sendsNothing"
    - "buildProfilePatch drops empty name keys; the view model holds the server's names (serverFirstName / serverLastName) to decide when to show the required-name message"
    - "ProfileSaveErrorMapper.messageFor / toProfileSaveDialogError: branch on status 422 plus ErrorCode.ValidationError, never on message text"

key-files:
  created:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ProfileSaveErrorMapper.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ProfileSaveErrorMapperTest.kt"
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsViewModel.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsRepository.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ProfileSnapshot.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ClientProfileSettingsViewModel.kt"
    - "../ClickMe_Android/app/src/main/res/values/strings_profile_settings.xml"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsViewModelTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ClientProfileSettingsViewModelTest.kt"
    - ".planning/todos/completed/2026-11-15-android-expert-settings-clear-meeting-link.md"
    - ".planning/todos/completed/2026-11-14-android-profile-settings-empty-name-save.md"

key-decisions:
  - "The 422 alert sentence and the nine field labels live in ProfileSaveErrorMapper.kt as plain English, not in string resources: the view models have no Context and FieldError.Res takes no format arguments, and the plan fixes the mapper as a pure message(fieldPaths): String. The generic fallback sentence is the same words the backend sends."
  - "Only a 422 that carries code VALIDATION_ERROR is mapped (iOS validationFieldErrors rule); a 422 without the code keeps the server message through the old path"
  - "A cleared set name is held in the view model (serverFirstName / serverLastName, updated when a name is sent), not in the AutoSaver baseline, so ProfileAutoSave.kt stays untouched"
  - "The expert AutoSaver gained a sendsNothing hook so an edit that sends no request (a held cleared name) is adopted silently instead of flashing Saving/Saved"
  - "The meeting_url 422 still shows its server message under the link field; only profile-field 422s moved to the alert"
  - "Commit trailer is the 'Claude Opus 5.5' text the dispatch required, regardless of the model that ran"

patterns-established:
  - "Empty name key is never sent; a changed basic group carries only non-empty names plus the bio"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Android expert can clear a saved meeting link: PATCH sends meeting_url \"\"; no saved link never sends the key; non-blank links are sent trimmed and still gated by isAllowedMeetingUrl (javascript: never sent, even after a clear)"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ExpertProfileSettingsViewModelTest#clearingTheSavedLinkSendsAnEmptyMeetingUrl, aWhitespaceOnlyFieldClearsTheSavedLink, anExpertWithNoSavedLinkNeverSendsTheKey, aNewLinkIsSentTrimmed, aJavascriptLinkIsNeverSentEvenAfterAClear, blankRestoredMeetingLinkOverASavedLinkIsAClear, anInvalidRestoredMeetingLinkKeepsTheServersLink"
        status: pass
    human_judgment: false
  - id: D2
    description: "Android client and expert settings send only changed groups and never an empty first_name / last_name; a Bio-only edit on an empty-last-name account has no last_name key"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ClientProfileSettingsViewModelTest#bioEditOnAnEmptyLastNameAccountSendsNoLastNameKey, firstNameEditOnAnEmptyLastNameAccountSendsFirstNameOnly; ExpertProfileSettingsViewModelTest#bioEditOnAnEmptyLastNameAccountSendsNoLastNameKey"
        status: pass
    human_judgment: false
  - id: D3
    description: "Clearing a set name holds the server value and shows 'Please enter your first name.' / 'Please enter your last name.' under the field (client and expert); an account that is empty on the server shows no message"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ClientProfileSettingsViewModelTest#clearingASetFirstNameHolds..., clearingASetLastNameHolds..., anEmptyNameOnAnEmptyAccountShowsNoMessage, aClearedNameRestoredAfterRecreation...; ExpertProfileSettingsViewModelTest#clearingASetFirstNameHolds..., clearingASetLastNameHolds..., anEmptyNameOnAnEmptyAccountShowsNoMessage"
        status: pass
    human_judgment: false
  - id: D4
    description: "A 422 VALIDATION_ERROR on a profile save shows 'Check {fields}, then try again.' with the iOS labels and screen order, never the server text; unknown paths ignored; none known gives the generic sentence"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ProfileSaveErrorMapperTest (8 rows); ClientProfileSettingsViewModelTest#validationErrorNamesTheFieldsAndNeverShowsServerText, validationErrorFieldsComeInScreenOrder, validationErrorWithOnlyUnknownFieldsGivesTheGenericSentence, aValidationErrorWithoutTheCodeKeepsTheServerMessage; ExpertProfileSettingsViewModelTest#aProfileValidationErrorNamesTheFieldsAndNeverShowsServerText"
        status: pass
    human_judgment: false
  - id: D5
    description: "The Android settings behavior on a real device: clearing the link, saving on an empty-name account, the 422 alert wording"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Nothing here was run on an Android device; the todos ask for a device check (08-REGRESSION-CHECKLIST.md Android section)."

duration: 30min
completed: 2026-11-20
status: complete
---

# Phase 08 Plan 06: Android meeting-link clear and empty-name saves Summary

**Android expert settings now clear a saved meeting link with `meeting_url ""`, and client and expert Profile Settings never send an empty name and show iOS-style "Check First Name and Last Name, then try again." alerts instead of raw server text.**

## Performance

- **Duration:** about 30 min (start time was not recorded; estimated from the Gradle run timestamps)
- **Completed:** 2026-11-20T04:45Z
- **Tasks:** 3 (1 tracer, 2 TDD)
- **Files modified:** 9 in the Android repo (2 created), 2 todos moved in the iOS repo
- **Android unit suite:** 5369 tests, 0 failures, 0 skipped; ktlintCheck clean

## Accomplishments

- A blank meeting-link field over a saved link, typed or restored after process recreation, is sent as `professional_details.meeting_url ""`. An expert with no saved link never sends the key. A non-blank link is sent trimmed and still has to pass `isAllowedMeetingUrl`, so the `javascript:` guard is intact (T-08-15); only `""` bypasses it.
- `buildProfilePatch` drops an empty `first_name` / `last_name`; the `basic` group goes out only when a non-empty name or the bio changed. A Bio-only edit on an account with an empty last name no longer carries `last_name ""`, which the backend rejected with 422.
- Clearing a set name sends nothing and shows "Please enter your first name." / "Please enter your last name." under the field, in both the client and the expert view model.
- New `ProfileSaveErrorMapper` and `toProfileSaveDialogError()`: a 422 VALIDATION_ERROR names the fields in iOS labels and screen order. The raw server text is never shown (T-08-16).
- Both todos are in `.planning/todos/completed/` with a Resolution that lists the Android SHAs.

## Task Commits

All code commits are in the Android repo (`/Users/LeonChen/Documents/ClickMe_Android`, branch `main`, local only, nothing pushed). Each carries the `Co-Authored-By: Claude Opus 5.5` trailer.

1. **Task 1 (tracer): clearing the expert meeting link** - `ad190070` (fix)
2. **Task 2 (tdd): never send an empty profile name** - `9ce71b80` (fix)
3. **Task 3 (tdd): 422 alert names fields; close todos** - `337f4c0c` (fix); iOS repo `7ef85e5` (docs, todo closure)

**Plan metadata:** the docs commit that holds this SUMMARY, STATE.md and ROADMAP.md (iOS repo).

## TDD Notes

The plan fixes one commit per task, so RED was not committed separately. RED was run and observed before GREEN for the two TDD tasks; the tracer task (Task 1) wrote its tests with the change and its verify run is the end-to-end proof.

- **Task 2 RED** (`/tmp/08-06-t2-red.log`): 69 tests ran, 8 failed on the planned assertions, 0 compile errors. Failing: `ClientProfileSettingsViewModelTest` bioEditOnAnEmptyLastNameAccountSendsNoLastNameKey (L799), firstNameEditOnAnEmptyLastNameAccountSendsFirstNameOnly (L818), clearingASetFirstName... (L835), clearingASetLastName... (L868), aClearedNameRestoredAfterRecreation... (L897); `ExpertProfileSettingsViewModelTest` bioEditOnAnEmptyLastNameAccountSendsNoLastNameKey (L716), clearingASetFirstName... (L735), clearingASetLastName... (L764). The two `anEmptyNameOnAnEmptyAccountShowsNoMessage` rows passed in RED by design: they are negative controls for the no-message case. Semantic assessment: each failure was an `AssertionError` on the expected request body or `fieldErrors` map, so the target behavior was missing, not a harness fault.
- **Task 3 RED** (`/tmp/08-06-t3-red.log`): with a stub mapper returning "", 165 tests ran and 12 failed on assertions (8 `ProfileSaveErrorMapperTest` rows; `validationErrorNamesTheFieldsAndNeverShowsServerText`, `validationErrorFieldsComeInScreenOrder`, `aValidationErrorWithoutTheCodeKeepsTheServerMessage`; the expert `aProfileValidationErrorNamesTheFieldsAndNeverShowsServerText`). `validationErrorWithOnlyUnknownFieldsGivesTheGenericSentence` passed in RED because the old path already showed the backend's generic message. The format-based `gsd_run check tdd-red-evidence` classifier was not run: Gradle's console output is not one of its supported report formats, so the assessment above is the manual semantic check.
- **TDD Gate Compliance:** no separate `test(...)` commit precedes the `fix(...)` commits, by the plan's one-commit-per-change rule. This is intentional and recorded here, not a missed gate.

## Files Created/Modified

- `ExpertProfileSettingsViewModel.kt` - blank link is a clear, `linkWillSend` / `sendsNothing`, required-name errors, 422 to alert
- `ExpertProfileSettingsRepository.kt` - KDoc only: `updateMeetingUrl("")` sends `""` (Moshi writes it as-is; no code change needed)
- `ProfileSnapshot.kt` - `buildProfilePatch` name rules, `requiredNameErrors`
- `ClientProfileSettingsViewModel.kt` - held names, required-name errors, 422 to alert; removed the now unused `fieldForServerName` / `fieldMessages`
- `ProfileSaveErrorMapper.kt` (new) and its test - label table, joiner, `messageFor`, `toProfileSaveDialogError`
- `strings_profile_settings.xml` - the two name-required strings
- Both view-model test files - new rows, and the old rows that encoded the bug rewritten

## Decisions Made

See `key-decisions` above. The two worth repeating: the alert text is built in code, not in string resources, and the held-name state lives in the view model rather than the AutoSaver.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two existing tests asserted the bug**
- **Found during:** Task 1
- **Issue:** `invalidOrBlankLinkNotSent` expected a blank field to send nothing, and `blankMeetingLinkNeverSent` expected blank restored text to keep the server link. Both are the behavior the plan removes.
- **Fix:** Renamed the first to `invalidLinkNotSent` (dropped its blank step) and rewrote the second as `blankRestoredMeetingLinkOverASavedLinkIsAClear`; added `anInvalidRestoredMeetingLinkKeepsTheServersLink` so the invalid-restore case keeps coverage.
- **Files modified:** `ExpertProfileSettingsViewModelTest.kt`
- **Committed in:** `ad190070`

**2. [Rule 2 - Missing critical] Expert saver flashed Saving/Saved for an edit that sends nothing**
- **Found during:** Task 2
- **Issue:** The client saver had `sendsNothing`; the expert one did not. With a held cleared name the expert would show "Changes saved" although nothing was sent.
- **Fix:** Added `sendsNothing` to the expert saver (no patch and the link will not send), sharing `linkWillSend` with `persist`.
- **Files modified:** `ExpertProfileSettingsViewModel.kt`
- **Committed in:** `9ce71b80`

**3. [Rule 3 - Blocking] 422 alert copy cannot be a string resource**
- **Found during:** Task 3
- **Issue:** The plan's artifact list names "the 422 alert strings" in `strings_profile_settings.xml`, but the plan also fixes `ProfileSaveErrorMapper.message(fieldPaths): String` as pure. The view models have no `Context`, and `FieldError.Res` carries no format arguments, so resource strings could not reach the dialog without changing the shared `FieldError` type.
- **Fix:** Kept the pure signature and put the label table and sentence in the mapper (documented there). No unused 422 strings were added to the XML. The two name-required strings are resources.
- **Files modified:** `ProfileSaveErrorMapper.kt`
- **Committed in:** `337f4c0c`

**4. [Process] Name-required strings added in Task 2, not Task 3**
- The plan allowed either; Task 2's tests needed them to compile, so they landed in `9ce71b80`.

**5. [Process] The todo-closure commit was amended once**
- A `git add` with a stale pending path failed, so the first `docs(08-06)` commit held only the renames. I amended my own unpushed commit to include the Resolution text (`7ef85e5`). Nothing else was affected.

---

**Total deviations:** 5 (1 bug, 1 missing critical, 1 blocking, 2 process)
**Impact on plan:** None changes the delivered behavior; the third trades the plan's "alert strings in XML" for a pure mapper, as the plan's own signature required.

## Issues Encountered

- ktlint rejected several long lines and a `?.` chain in new code; each was reflowed and the run repeated. No logic changes.
- `08-REGRESSION-CHECKLIST.md`, cited by the plan for the device check, does not exist yet in `.planning/phases/08-release/`. The Resolution text names it as the plan said; whoever writes that checklist should add the three Android checks (clear the link, empty-name Bio edit, the 422 alert wording).
- Disk stayed at about 5.5 GiB free throughout; no Gradle run failed for space and nothing was deleted.

## Known Stubs

None.

## Threat Flags

None. No new endpoint or trust boundary; T-08-15 (the `javascript:` guard) and T-08-16 (no server text in the alert) are both covered by tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Android now matches iOS 1.1 for meeting-link clears and empty-name saves. The three device checks above still need a real Android phone.
- The Android repo has local commits from 08-03 and 08-06 that are not pushed; pushing is a separate decision.
- No backend change was needed (BACK-04 is already live per the todo).

## Self-Check: PASSED

- Android commits `ad190070`, `9ce71b80`, `337f4c0c` are ancestors of HEAD (checked with `git merge-base --is-ancestor`).
- `ProfileSaveErrorMapper.kt` and `ProfileSaveErrorMapperTest.kt` exist; `ProfileSaveErrorMapper.kt` contains "then try again.".
- "Please enter your first name." and "Please enter your last name." each appear once in the Android resources.
- Both todos are in `.planning/todos/completed/` and gone from `pending/`.
- `./gradlew :app:testDevDebugUnitTest ktlintCheck` finished BUILD SUCCESSFUL (5369 tests, 0 failures) after the last code change; `git log origin/main..main` shows the commits are local only.

---
*Phase: 08-release*
*Completed: 2026-11-20*
