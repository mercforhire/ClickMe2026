---
phase: 08-release
plan: "27"
subsystem: android-parity
tags: [android, kotlin, profile-settings, languages, data-loss, parity, tdd]

requires:
  - phase: 08
    provides: "Plan 08-26: the user's Android parity port requests; P5 (zero-language Done) is the data-loss item"
  - phase: 05
    provides: "iOS 05-09 (SET-01, UI-SPEC A9): applyLanguageSelection refuses a Done that leaves no language, and ProfileSettingsSnapshot never sends a group that leaves zero languages"
provides:
  - "Android client and expert Profile Settings refuse a language-sheet Done that would leave no language: the sheet closes, the previous list stays, no PATCH is sent, and the 'Couldn't save changes' dialog reads 'Keep at least one language.'"
  - "A profile that already has no language gets a silent no-op on Done with nothing selected: no dialog, no request"
  - "Deselecting every catalogue language while a custom language remains still saves language_ids [] with the custom labels"
  - "buildProfilePatch (shared by client and expert) never builds a languages group that would leave zero languages, even for a restored snapshot with an empty list"
affects: [08-28, 08-31, 08-15, android-release]

actuals:
  tokens: 5000
  tasks: 2
  commits: 2

# commits is measured in the Android repo, where this plan's code commits live:
# git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count 2d75fb97..HEAD
commits: 2
plan_head_before: 2d75fb974d394df2222c0f1d22dba04ab1acc557
plan_head_after: b1e37ca2c017212f60c1ee840f9e110c48ab52a3

tech-stack:
  added: []
  patterns:
    - "Two guards for a full-replace server group: the view model refuses the empty edit with a visible message, and the shared patch builder never emits the group, so a restored snapshot cannot bypass the first guard"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/res/values/strings_profile_settings.xml"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ProfileSnapshot.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ClientProfileSettingsViewModel.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsViewModel.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ClientProfileSettingsViewModelTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ProfileAutoSaveTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsViewModelTest.kt"

key-decisions:
  - "The dialog and the refusal live in each view model's applyLanguages (as on iOS applyLanguageSelection), with the sheet closed on refusal because the iOS sheet dismisses on Done; the patch-level rule is a second guard, not the primary one"
  - "The keep-one string reuses the existing profile_settings_save_error_title dialog and the Android 'Got it' confirm label; only the message is the iOS one"
  - "network/ProfileHelpApiTest#languagesGroupIsFullReplace stays unchanged: it pins the wire shape at the Retrofit layer and is not an app path"

patterns-established:
  - "Zero-language guard: applyLanguages computes the next list, and when it is empty closes the sheet, sets dialog only if the profile had languages, and returns without touching the snapshot, SavedStateHandle or the auto-saver"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Android client Profile Settings: Done in the language sheet with nothing selected keeps the previous list, sends no PATCH and opens the dialog 'Keep at least one language.'"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/settings/clientprofilesettings/ClientProfileSettingsViewModelTest.kt#doneWithNothingSelectedKeepsTheListAndExplains"
        status: pass
    human_judgment: false
  - id: D2
    description: "A client profile that already has no language gets a silent no-op on an empty Done; deselecting every catalogue language while a custom one remains still saves the customs"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/settings/clientprofilesettings/ClientProfileSettingsViewModelTest.kt#doneWithNothingSelectedOnAProfileWithNoLanguagesIsSilent"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/settings/clientprofilesettings/ClientProfileSettingsViewModelTest.kt#deselectingEveryCatalogueLanguageKeepsTheCustomsAndSaves"
        status: pass
    human_judgment: false
  - id: D3
    description: "buildProfilePatch never builds a languages group that would leave zero languages, even with another group changing"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/settings/clientprofilesettings/ProfileAutoSaveTest.kt#removingEveryLanguageSendsNothing"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/settings/clientprofilesettings/ProfileAutoSaveTest.kt#emptiedLanguagesWithABioChangeSendOnlyTheBio"
        status: pass
    human_judgment: false
  - id: D4
    description: "The same guard on Android expert Profile Settings (refusal with dialog, silent no-op on an empty profile, customs-only save)"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/expertmode/settings/ExpertProfileSettingsViewModelTest.kt#expertDoneWithNothingSelectedKeepsTheListAndExplains"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/expertmode/settings/ExpertProfileSettingsViewModelTest.kt#expertDoneWithNothingSelectedOnAProfileWithNoLanguagesIsSilent"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/expertmode/settings/ExpertProfileSettingsViewModelTest.kt#expertDeselectingEveryCatalogueLanguageKeepsTheCustomsAndSaves"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real Android device the language sheet closes, the dialog shows the iOS wording, and the server's languages survive leaving and reopening the screen"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Dialog presentation after the sheet closes and the real server round trip are not asserted by view model tests; the (P5) device check below covers them on a dedicated test account"

duration: 25min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 27: Android Zero-Language Guard (P5) Summary

**Android client and expert Profile Settings now refuse a language-sheet Done that would leave no language (iOS 05-09 A9): the previous list stays, no PATCH goes out, and the "Couldn't save changes" dialog reads "Keep at least one language.", with a second guard in the shared buildProfilePatch.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-20T06:20Z
- **Tasks:** 2 (client tracer, expert expansion)
- **Files modified:** 7 (all in the Android repo; no iOS code, no backend change)

## Accomplishments

- Closed port request P5, the only data-loss item from 08-26: before this plan, Done with nothing selected sent `language_ids: []`, which the backend accepts as a full replace and deletes every language row.
- `applyLanguages` in both view models returns early on an empty result: the sheet closes, the snapshot, `SavedStateHandle` and auto-saver are untouched, and the dialog opens only when the profile had languages (silent otherwise), exactly as iOS `applyLanguageSelection`.
- `buildProfilePatch` leaves the languages group out whenever the new list is empty, so a restored snapshot cannot bypass the view model guard (iOS `zeroLanguagesAreNeverSent`).
- The two Android tests that pinned the bug (`removingAllSendsEmptyLists`, `removingEveryLanguageSendsBothListsEmpty`) were replaced by behavior rows; the full Android unit suite passes (5403 tests, 0 failures, 0 skipped) with ktlint.

## Task Commits

All commits are local on Android `main`; nothing was pushed (Android `origin/main` is still `27e024bf`).

1. **Task 1: Tracer, client Done with no language keeps the list, sends nothing and says why** - `4bd04caa` (fix; five paths)
2. **Task 2: Expert Profile Settings gets the same guard; full Android run** - `b1e37ca2` (fix; two paths)

`git -C /Users/LeonChen/Documents/ClickMe_Android log --oneline 2d75fb97..HEAD` shows exactly these two commits. `.idea/*` was never staged.

**Plan metadata:** the iOS repo docs commit that holds this SUMMARY (docs: complete plan).

## TDD evidence (RED)

RED was run first for each task and is recorded here, not committed separately (the plan calls for one commit per task). Each RED run compiled and failed on assertions, not on compilation or setup.

**Task 1 (client + patch), 60 tests, 3 failed:**

```
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest \
  --tests '...clientprofilesettings.ClientProfileSettingsViewModelTest' --tests '...clientprofilesettings.ProfileAutoSaveTest'
ClientProfileSettingsViewModelTest > doneWithNothingSelectedKeepsTheListAndExplains FAILED  (java.lang.AssertionError)
ProfileAutoSaveTest > emptiedLanguagesWithABioChangeSendOnlyTheBio FAILED                   (java.lang.AssertionError)
ProfileAutoSaveTest > removingEveryLanguageSendsNothing FAILED                              (java.lang.AssertionError)
60 tests completed, 3 failed
```

Semantic assessment: the three failing tests are the planned targets, failing on the planned assertions (kept list and dialog for the view model, `null` patch and no languages group for the snapshot builder). The string resource was added first so the tests compile. The other two client rows, `doneWithNothingSelectedOnAProfileWithNoLanguagesIsSilent` and `deselectingEveryCatalogueLanguageKeepsTheCustomsAndSaves`, passed at RED because today's code already did those things; they pin behavior that must not regress.

**Task 2 (expert), 34 tests, 1 failed:**

```
ExpertProfileSettingsViewModelTest > expertDoneWithNothingSelectedKeepsTheListAndExplains FAILED  (java.lang.AssertionError)
34 tests completed, 1 failed
```

Semantic assessment: as the plan predicted, the no-request row passed at RED because the Task 1 patch guard already stops the request; the dialog and kept-list row failed on its assertions. The silent-no-op and customs-only rows pass at RED and pin non-regression.

GREEN for both tasks: the same filtered classes plus `ktlintCheck`, then one full `:app:testDevDebugUnitTest ktlintCheck`: BUILD SUCCESSFUL, 5403 tests, 0 failures, 0 errors, 0 skipped.

## Files Created/Modified

- `strings_profile_settings.xml` - `profile_settings_languages_keep_one` = "Keep at least one language." (exactly once, with an XML comment citing iOS 05-09 UI-SPEC A9)
- `ClientProfileSettingsViewModel.kt` - zero-language guard in `applyLanguages`, KDoc updated
- `ProfileSnapshot.kt` - `buildProfilePatch` omits a languages group that would leave zero languages, KDoc updated
- `ExpertProfileSettingsViewModel.kt` - same guard in the expert `applyLanguages`
- `ClientProfileSettingsViewModelTest.kt`, `ProfileAutoSaveTest.kt`, `ExpertProfileSettingsViewModelTest.kt` - the new rows replacing the two bug-pinning tests

## Decisions Made

- Refusal lives in each view model's `applyLanguages` and closes the sheet, matching the iOS sheet that dismisses on Done; the patch rule is the second guard.
- The confirm label stays the Android settings convention ("Got it"); only the title and message match iOS.
- `network/ProfileHelpApiTest#languagesGroupIsFullReplace` was left unchanged: it sends an empty body straight to the Retrofit API to pin the wire shape and is not an app path. The backend still accepts an empty list; the client is the only guard, as on iOS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ktlint line length in the first GREEN edit**
- **Found during:** Task 1 (first GREEN verify run)
- **Issue:** the one-line `_uiState.update { ... dialog = if (explain) FieldError.Res(...) else it.dialog }` exceeded the 120-column limit (`max-line-length`, `argument-list-wrapping`), so `ktlintCheck` failed.
- **Fix:** hoisted the message into a local `val message = FieldError.Res(...)`, giving a single line within the limit; the same shape was used in the expert view model from the start.
- **Files modified:** `ClientProfileSettingsViewModel.kt`
- **Verification:** the Task 1 verify command passed (BUILD SUCCESSFUL, all four grep checks), then the full run passed.
- **Committed in:** `4bd04caa` (part of the Task 1 commit; the failing form never reached a commit)

---

**Total deviations:** 1 auto-fixed (1 blocking, formatting only)
**Impact on plan:** none on behavior or scope.

## Issues Encountered

- One Bash call (the plan's single-line verify with `&&` chains and `tee`) was refused by the harness's old bash; the full run was re-issued as simpler separate commands with the same Gradle invocation and the same checks (BUILD SUCCESSFUL, string reference, test name, `origin/main` still `27e024bf`).
- Disk free was 7.1 GiB at the start and 6.3 GiB after the full run; no cleanup was needed and nothing was deleted.

## Device checks for 08-15 (Android section)

**(P5) Zero-language Done on Android client and expert Profile Settings.** Run on a dedicated test account with a throwaway profile, not a real user: if the guard failed, these steps would delete that account's languages on the live production backend. Use an Android dev build from `ClickMe_Android` `main` (at or after `b1e37ca2`).

1. Client mode: open Profile Settings, then Spoken Languages. Deselect every language in the sheet (including any custom ones that appear as chips, if the screen offers removal; otherwise a profile with only catalogue languages) and tap Done.
2. Expect: the sheet closes, a dialog titled "Couldn't save changes" shows "Keep at least one language.", and the Spoken Languages list is unchanged. The auto-save status icon shows no failure and no save runs.
3. Dismiss the dialog with "Got it", leave Profile Settings, and reopen it: the languages are still there. Force-quit the app and reopen to confirm the server still returns them.
4. Repeat steps 1 to 3 on expert Profile Settings (switch to expert mode with the same test account).
5. Restore note: no cleanup is needed if the guard works. If the languages were wiped, re-add them in the sheet and record the failure.

## Known Stubs

None. No placeholder values or unwired data in the changed files.

## Threat Flags

None. No new endpoint, auth path or trust-boundary file access; threat T-08-57 (languages full replace) is mitigated by the two guards and asserted by unit rows.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-28 to 08-31 chain after this plan on Android `main` at `b1e37ca2`; the Android lane stays sequential.
- 08-31 consolidates this section's (P5) item into its own `## Device checks for 08-15 (Android section)` for 08-15's checklist.
- Nothing is pushed in either repo; Android `origin/main` is `27e024bf`.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Android commits `4bd04caa` and `b1e37ca2` are on `main` (`git merge-base --is-ancestor`); every changed Android file exists.
- `git log --oneline 2d75fb97..HEAD` lists exactly two commits; `git show --stat` of each lists exactly the five and two planned paths (no `.idea/`).
- `Keep at least one language.` appears exactly once under `app/src/main/res/values/`; both view models reference `R.string.profile_settings_languages_keep_one`.
- Android `origin/main` is still `27e024bf`; no iOS app code or backend file was changed.
