---
phase: 08-release
plan: "29"
subsystem: android-parity
tags: [android, kotlin, signup, publish, feedback, parity, tdd]

requires:
  - phase: 08
    provides: "Plan 08-26: the user's Android parity port requests; P3 (photo required to publish) and P4 (feedback minimum wording)"
  - phase: 05
    provides: "iOS 05-04 (SIGN-01): Publish Profile stays usable and refuses locally with the missing checklist titles; iOS 05-05 (SET-05): the feedback minimum message"
provides:
  - "Android Profile Review keeps Publish Profile usable while a required step is missing; the button is inert only while a publish is in flight"
  - "Tapping Publish with a missing step sends no request and opens \"Couldn't publish profile\": \"Finish these first: Add profile picture.\" (missing hub titles in hub order, joined with \", \"); OK stays on Review"
  - "The Android-only still-needed line and the labels only it used (SetupStep.neededRes, five signup_needed_* strings) are removed"
  - "Android feedback minimum message reads exactly \"Please enter at least 10 characters.\""
affects: [08-15, 08-30, 08-31, android-release]

actuals:
  tokens: 4400
  tasks: 3
  commits: 3

# commits is measured in the Android repo, where this plan's code commits live:
# git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count 5a044d0a..HEAD
commits: 3
plan_head_before: 5a044d0ab5cf50b73194b75ae5aab0f5db2f769c
plan_head_after: 68509208a1c49e1bd208ce360389e204933ee2d8

tech-stack:
  added: []
  patterns:
    - "A client-side precondition refusal is a UI-state field (publishRefusal) set by the view model before any repository call, cleared by the shared dismissDialog, and carried across draft updates like the other dialog fields"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/signup/review/SignupReviewViewModel.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/signup/review/SignupReviewScreen.kt"
    - "../ClickMe_Android/app/src/main/res/values/strings_signup_review.xml"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/signup/review/SignupReviewViewModelTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/signup/review/SignupReviewScreenTest.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/signup/SetupStep.kt"
    - "../ClickMe_Android/app/src/main/res/values/strings_signup_common.xml"
    - "../ClickMe_Android/app/src/main/res/values/strings_feedback.xml"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/feedback/FeedbackScreenTest.kt"

key-decisions:
  - "The refusal reuses AuthErrorDialog, the existing title string and the existing dismissDialog callback, so SignupReviewContent's signature is unchanged and SignupBottomBarInsetRegressionTest compiles untouched"
  - "The refusal lists current.missing (hub order, never VerifyEmail), the same list the old still-needed line showed, so the dialog names exactly the steps iOS missingForPublish names"
  - "The server-422 path (missingFieldsDialog, 'Finish these steps first', return to hub) is unchanged; the server stays the enforcer"
  - "Task 1 commit holds the still-needed string removal together with the screen change that stopped using it, so no commit leaves an unused or missing resource"

patterns-established:
  - "Local refusal before network: publish() returns before repository.publish() when canPublish is false, asserted by setupProfileCalls == 0"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Publish Profile with a missing step (photo) refuses locally with \"Finish these first: Add profile picture.\" and sends no request; several missing steps are listed in hub order"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewViewModelTest.kt#publishWithAMissingPhotoRefusesLocallyAndSendsNothing"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewViewModelTest.kt#publishWithSeveralMissingStepsListsThemInHubOrder"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewViewModelTest.kt#publishRefusalSurvivesDraftUpdates"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Review screen keeps the Publish button usable with a step missing, shows the refusal dialog with the iOS title and text, OK dismisses it, and the still-needed line is gone"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewScreenTest.kt#missingItemsKeepPublishUsableWithNoStillNeededLine"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewScreenTest.kt#publishRefusalDialogNamesTheStepsAndOkDismisses"
        status: pass
    human_judgment: false
  - id: D3
    description: "A server 422 with missing_fields, a server error and a full draft keep their existing behavior"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewViewModelTest.kt#missingFieldsFrom422MapToHubStepsInOrderWithoutDuplicates"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/review/SignupReviewScreenTest.kt#missingFieldsDialogNamesTheStepsAndOkDismisses"
        status: pass
    human_judgment: false
  - id: D4
    description: "The feedback too-short message reads \"Please enter at least 10 characters.\" while the error shows and is gone when it clears"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/settings/feedback/FeedbackScreenTest.kt#detailsErrorShowsAndClears"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real Android device the Publish refusal and the feedback minimum behave as on iOS, and a refused publish publishes nothing on production"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Unit and Robolectric rows prove the logic and the dialog text; only a device run against the real backend proves that nothing is published and that the dialog reads and dismisses correctly; the (P3) and (P4) device checks below cover it"

duration: 20min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 29: Android Publish Refusal (P3) and Feedback Minimum Wording (P4) Summary

**Android Profile Review no longer disables Publish Profile when a step such as the photo is missing: tapping it refuses locally with "Finish these first: Add profile picture." and sends nothing (iOS 05-04 parity), and the feedback too-short message now reads "Please enter at least 10 characters." (iOS 05-05 parity).**

## Performance

- **Duration:** about 20 min (start time not captured at launch; estimated from the first command to this write)
- **Completed:** 2026-11-20T06:35Z
- **Tasks:** 3 (publish refusal tracer, label cleanup, feedback copy plus full run)
- **Files modified:** 9 (all in the Android repo; no iOS code, no backend change)

## Accomplishments

- Closed port request P3: before this plan Android disabled Publish Profile and showed an Android-only "Still needed: profile picture." line, while iOS keeps the button usable (`.disabled(isLoading)` only) and refuses on tap. `SignupReviewViewModel.publish()` now sets `publishRefusal = current.missing` and returns before `repository.publish()` when `canPublish` is false, so a missing photo can never reach production as a request the client knows is incomplete. The Publish `AsyncSaveButton` follows only `saveState`.
- The refusal renders as an `AuthErrorDialog` titled "Couldn't publish profile" with "Finish these first: " plus the missing hub titles joined with ", " plus "."; OK calls the shared `dismissDialog`, which clears both `dialogError` and `publishRefusal` and never returns to the hub. The draft collector carries `publishRefusal` across draft updates like the other dialog fields.
- Removed the dead code the change left behind: the still-needed text block and `signup_review_still_needed`, `SetupStep.neededRes` and the five `signup_needed_*` strings; `titleRes` is untouched and the hub compiles unchanged.
- Closed port request P4: `feedback_details_too_short` is exactly "Please enter at least 10 characters." (the iOS `FeedbackDetailsField` text); the 10 trimmed UTF-16 unit rule and the keep-the-text behavior are unchanged.
- Full Android unit suite plus ktlint green: 400 test classes, 5413 tests, 0 failures (up from 5409; +3 view model rows, +1 net screen row).

## Task Commits

All commits are local on Android `main`; nothing was pushed (Android `origin/main` is still `27e024bf`).

1. **Task 1: Tracer, Publish with a missing photo stays usable and refuses with the iOS message, sending nothing** - `3634f415` (fix; the five planned paths)
2. **Task 2: Remove the labels only the old still-needed line used** - `4ca8326b` (refactor; two paths)
3. **Task 3: The feedback minimum message uses the iOS words; full Android run** - `68509208` (fix; two paths)

`git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count 5a044d0a..HEAD` prints 3 (08-28's last commit is `5a044d0a`). `.idea/*` and the untracked `.planning/` files were never staged.

**Plan metadata:** the iOS repo docs commit that holds this SUMMARY (docs: complete plan).

## TDD evidence (RED)

RED was run first for Tasks 1 and 3 and is recorded here, not committed separately (the plan calls for one commit per task). Both RED runs compiled and failed on the planned assertions, not on compilation, setup or discovery. The repo's classifier (`gsd_run check tdd-red-evidence`) has no adapter for Gradle's console output, so the semantic assessment below is the evidence. (Task 2 is `type="auto"` without `tdd`; it removes dead code and has no RED.)

**Task 1 (publish refusal), 26 tests, 5 failed:**

```
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest \
  --tests 'com.uptrendinvestments.clickmeapp.screens.signup.review.*'
SignupReviewViewModelTest > publishWithAMissingPhotoRefusesLocallyAndSendsNothing FAILED   expected:<[ProfilePhoto]> but was:<null>
SignupReviewViewModelTest > publishWithSeveralMissingStepsListsThemInHubOrder FAILED       expected:<[PersonalDetails, ProfilePhoto, Expertise]> but was:<null>
SignupReviewViewModelTest > publishRefusalSurvivesDraftUpdates FAILED                      AssertionError (assertNotNull(publishRefusal) after publish())
SignupReviewScreenTest > publishRefusalDialogNamesTheStepsAndOkDismisses FAILED            the component contains 'Couldn't publish profile' is not displayed!
SignupReviewScreenTest > missingItemsKeepPublishUsableWithNoStillNeededLine FAILED        Did not expect any node but found '1' node: contains 'Still needed'
26 tests completed, 5 failed
```

The red run compiled because the defaulted field `publishRefusal: List<SetupStep>? = null` and the string `signup_review_finish_first` were added first. Semantic assessment: each of the five targets executed and failed on the planned behavior (the refusal was never set, no refusal dialog rendered, the old still-needed line was still present); the other 21 tests passed, so nothing failed for an unrelated reason.

**Task 3 (feedback copy), 22 tests, 1 failed:**

```
./gradlew ... :app:testDevDebugUnitTest --tests 'com.uptrendinvestments.clickmeapp.screens.settings.feedback.FeedbackScreenTest'
FeedbackScreenTest > detailsErrorShowsAndClears FAILED
  Expected exactly '1' node but could not find any node that satisfies: Text contains 'Please enter at least 10 characters.'
22 tests completed, 1 failed
```

Semantic assessment: the target ran and failed on the planned assertion (the new text is not on screen while the old longer wording still is); no setup or load fault.

## Verification

- Task 1 verify (as written in the plan, filtered review classes plus the inset regression test plus ktlint, then the grep checks): BUILD SUCCESSFUL, all checks true.
- Task 2 verify (filtered `screens.signup.*` plus ktlint, then no `neededRes`, `signup_needed_` or `Still needed` under `app/src/main`): BUILD SUCCESSFUL, no hits.
- Task 3 verify (full `:app:testDevDebugUnitTest ktlintCheck`): BUILD SUCCESSFUL in 1m 27s; 400 classes, 5413 tests, 0 failures. The plan's single long-line check chain was refused by the tool shell, so the Gradle run and each grep/`git rev-parse` check were run as equivalent separate commands: the new text appears in `strings_feedback.xml` exactly once, the old wording appears 0 times under `app/src`, and Android `origin/main` is still `27e024bf`.
- Tracer gate: Task 1's verify was green on the exact tree that was committed, so the tracer was treated as verified end to end before expansion.

## Files Created/Modified

- `SignupReviewViewModel.kt` - `publishRefusal` on `SignupReviewUiState`; `publish()` refuses locally when `canPublish` is false; the draft collector and `dismissDialog()` handle the field
- `SignupReviewScreen.kt` - refusal `AuthErrorDialog`; still-needed block and the button's `enabled` argument removed; three unused imports dropped
- `strings_signup_review.xml` - added `signup_review_finish_first`; removed `signup_review_still_needed`
- `SetupStep.kt`, `strings_signup_common.xml` - `neededRes` and the five `signup_needed_*` labels removed, KDoc and XML comment reworded
- `strings_feedback.xml`, `FeedbackScreenTest.kt` - the iOS too-short wording
- `SignupReviewViewModelTest.kt`, `SignupReviewScreenTest.kt` - three view model rows and two screen rows added, the old disabled-button row replaced, a stale comment updated

## Decisions Made

See `key-decisions` above. In short: reuse `AuthErrorDialog`, the existing title and `dismissDialog` so the screen signature and the inset regression test are untouched; list `current.missing` (hub order, never Verify email); leave the server-422 path alone.

## Deviations from Plan

None - plan executed exactly as written. Two small notes, neither a deviation: Task 1's screen test also dropped two imports (`LiveRegionMode`, `assertIsNotEnabled`) and the screen dropped three (`LiveRegionMode`, `liveRegion`, `semantics`) that the removed code was the last user of, so ktlint stays green; and the screen test `canPublishHidesStillNeededAndPublishCallsBack` became `canPublishAndPublishCallsBack` because its "still needed" half is now covered by the new keep-usable row.

**Total deviations:** 0
**Impact on plan:** none.

## Issues Encountered

- The tool shell refused the one-line verify for Task 3 (nested command substitution); it was run as separate equivalent commands, recorded above.
- Disk stayed between 6.8 and 6.9 GiB free through all Gradle runs; nothing was deleted.

## Known Stubs

None.

## Threat Flags

None. T-08-59 is mitigated: `publish()` returns before `repository.publish()` when `canPublish` is false and the view model row asserts `setupProfileCalls == 0`; the server 422 handling is unchanged.

## Device checks for 08-15 (Android section)

Use an Android dev build from `ClickMe_Android` `main` (local commits `3634f415`, `4ca8326b`, `68509208`).

1. **(P3)** Use a dedicated, unpublished test expert signup with every step done except the photo (if the refusal failed, the profile would be published on production). On Profile Review the Publish Profile button is usable and no "Still needed" line shows; tap it: "Couldn't publish profile" with "Finish these first: Add profile picture."; OK stays on Review and nothing is published (the expert is not live, the setup hub still shows the photo step open).
2. **(P4)** Help, Feedback: type fewer than 10 characters and send: "Please enter at least 10 characters." shows and the typed text is kept.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Android lane is ready for 08-30. The two device items above go into plan 08-15's Android section.
- Nothing pushed: Android `origin/main` is still `27e024bf`, with this plan's three commits local on `main`.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Created/modified files exist: the six main-source files and strings checked with `[ -f ]`, all FOUND.
- Commits are ancestors of HEAD: `3634f415`, `4ca8326b`, `68509208`, all FOUND; `rev-list --count 5a044d0a..HEAD` is 3.
- Nothing staged beyond the planned paths; `.idea/*` still modified and unstaged.
