---
phase: 08-release
plan: "17"
subsystem: android-parity
tags: [android, kotlin, compose, account-deletion, copy, privacy, parity, tdd]
status: complete

requires:
  - phase: 08
    provides: "08-13 final iOS saved-cards wording (D-23, option-a); 08-25 DeleteAccountRepository (api, tokens, io) constructor; 08-12"
provides:
  - "Android Delete Account no longer claims payment details or bookings are removed; the header carries the iOS AccountDeletionCopy strings word for word"
  - "Android saved-cards line equals iOS AccountDeletionCopy.savedCardsNote byte for byte, on the confirmation step only (D-23)"
  - "Android AccountDeletionBlocker: the three 409 codes by active mode to the iOS title, message and View My Bookings rule"
affects: [android-release, 08-REGRESSION-CHECKLIST, 08-24]

actuals:
  tokens: 36000
  tasks: 2
  commits: 3

plan_head_before: fa9057ad
plan_head_after: e311a74c60fbe37ee4c1746187acbdce84939861
commits: 3

tech-stack:
  added: []
  patterns:
    - "Deletion copy is one string resource per iOS string; a Robolectric test reflects over every R.string.delete_account_* value and forbids payment details, removed and saved card"
    - "Blocker state is an enum (AccountDeletionBlocker) held in the UI state; the active mode is applied at render, as iOS does, so the ViewModel constructor is unchanged"

key-files:
  created:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/AccountDeletionBlocker.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountNavigationTest.kt"
  modified:
    - "../ClickMe_Android/app/src/main/res/values/strings_delete_account.xml"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/subviews/DeleteAccountComponents.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountScreen.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountViewModel.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/SettingsEntries.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountScreenTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountViewModelTest.kt"
    - ".planning/todos/completed/2026-11-13-android-delete-account-copy-and-blockers.md"

key-decisions:
  - "Blocker table lives in its own AccountDeletionBlocker.kt (the file did not exist and the ViewModel held no blocker logic), as an enum with fromCode, offersBookingsAction(mode) and messageRes(mode)"
  - "The active mode reaches the screen from the shell that registers the entry (client shell: Client, expert shell: Expert), not from UserManager, so DeleteAccountViewModel keeps its constructor; AppViewModel already keeps the shell and currentMode in step"
  - "View My Bookings resets the Profile stack that holds Delete Account, then calls the existing showMyBookings / showExpertBookings; the Profile reset is an Android-only addition, as Request Sent's was (Phase 16.3 CR-01)"

requirements-completed: []

coverage:
  - id: A1
    description: "Confirmation step shows the permanence line, upfront line, three groups and the saved-cards line; the reason step shows the permanence line only"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "DeleteAccountScreenTest.confirmationStepShowsTheTrueDisclosureAndTheSavedCardsLine, reasonStepKeepsOnlyThePermanenceLine"
        status: pass
    human_judgment: false
  - id: A2
    description: "Saved-cards line and the other disclosure strings equal the iOS wording exactly; no delete_account_* string contains payment details, removed or saved card"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "DeleteAccountScreenTest.disclosureStringsAreTheIosWordsExactly, noDeleteAccountStringMakesAFalseRemovalClaim"
        status: pass
      - kind: other
        ref: "shell cmp of the Android string and the Swift literal, MATCH"
        status: pass
    human_judgment: false
  - id: A3
    description: "A 409 with any of the three blocker codes, from either call, shows the blocker (not the server message), keeps the reason and password step, and a retry mints a new token; an unknown 409 keeps the generic dialog"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "DeleteAccountViewModelTest.blockerConflictKeepsTheFormAndRetryMintsNewToken, everyBlockerCodeFromEitherCallSetsTheBlocker, unknownConflictCodeKeepsTheGenericDialogWithTheServerMessage"
        status: pass
    human_judgment: false
  - id: A4
    description: "Message and View My Bookings button per code and mode match the todo's five-row table; the dialog renders the exact text; the button resets Profile and opens Bookings of the active mode"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "DeleteAccountViewModelTest.blockerCopyFollowsTheTodoTableForEveryCodeAndMode; DeleteAccountScreenTest.blockerDialogShowsTheTodoTextAndButtonsForEveryCodeAndMode, blockerButtonsCallTheirCallbacks; DeleteAccountNavigationTest"
        status: pass
    human_judgment: false
  - id: A5
    description: "The screens look right and the blocker dialog appears on a real Android device"
    requirement: REL-02
    verification:
      - kind: other
        ref: "08-REGRESSION-CHECKLIST.md Android section, throwaway account only (Delete Account is irreversible on production)"
        status: not_run
    human_judgment: true
---

# Phase 08 Plan 17: Android Delete Account copy and blocker alert Summary

Android's Delete Account screen now tells the truth that iOS tells, including the D-23 line that cards added to pay for sessions are not deleted with the account, and a blocked deletion (409) explains itself by code and mode instead of showing the server text.

## Tasks

| Task | Name | Commit (Android `main`) | Files |
|------|------|--------|-------|
| 1 | Tracer: true iOS copy and the saved-cards line | `2a65e7c7` | strings_delete_account.xml, DeleteAccountComponents.kt, DeleteAccountScreen.kt, DeleteAccountScreenTest.kt |
| 2 | 409 blocker alert by code and mode; close the todo | `e311a74c` (Android), `10839fd` (iOS repo, docs) | AccountDeletionBlocker.kt, DeleteAccountViewModel.kt, DeleteAccountScreen.kt, DeleteAccountComponents.kt, SettingsEntries.kt, strings, three test files; the todo |

Android commits are local on `main` (branch convention of earlier Android lane plans); nothing was pushed in either repo. The iOS repo holds `10839fd` (todo moved to `completed/` with a Resolution naming both SHAs) and the commit of this SUMMARY.

## What changed

- **Copy.** `delete_account_body` is deleted; nine string resources carry the iOS strings (`permanence`, `bookings_first`, three group title/body pairs, `saved_cards_note`). `DeleteAccountWarningHeader(showsDetails)` mirrors iOS: the Warning step (iOS "confirmation") shows everything, the Reason step shows the headline and the permanence line only. There was no Pause Account card or "Before you go" title on Android to remove (an existing test already asserts that).
- **Blocker.** `AccountDeletionBlocker` has `fromCode(ErrorCode?)`, `offersBookingsAction(mode)` and `messageRes(mode)`; seven new strings hold the title, five messages and `View My Bookings`. `DeleteAccountViewModel.onFailure` maps a 409 whose decoded code is one of the three to `Failure.Blocked`; any other 409 still shows the server message. `confirmDeletion` clears the blocker, so a retry runs both calls again and mints a new token.
- **Dialog and navigation.** `AccountDeletionBlockerDialog` shows View My Bookings only when the table says so and keeps `Got it` as the dismiss button. `showBookingsFromDeleteAccount(mode)` resets the Profile stack that holds Delete Account, then calls `showMyBookings()` (client) or `showExpertBookings()` (expert).

## TDD (Task 2)

- **RED:** after adding the `blocker` UI-state field and `dismissBlocker()` (no 409 wiring), `DeleteAccountViewModelTest` ran 25 tests with 2 failures: `blockerConflictKeepsTheFormAndRetryMintsNewToken` (line 186) and `everyBlockerCodeFromEitherCallSetsTheBlocker` (line 222), both on `assertEquals(<blocker>, vm.uiState.value.blocker)` with the state null. The code compiled, the target tests ran and failed on the planned assertion; the pure table rows and the unknown-409 row already passed, as expected. Semantic assessment: valid RED. The `gsd_run check tdd-red-evidence` classifier was not run, because it has no adapter for Gradle's JUnit XML; the judgment above stands in for it.
- **GREEN:** the 409 branch in `onFailure`; 25 of 25, then the full unit run.
- **REFACTOR:** none needed.
- The plan prescribes a single `feat` commit for the task, so RED and GREEN share `e311a74c`.

## Verification

- Delete-account package: 55 tests, 0 failures (`DeleteAccountScreenTest` 22, `DeleteAccountViewModelTest` 25, `DeleteAccountNavigationTest` 2, `AccountDeletionFarewellTest` 6), `ktlintCheck` clean.
- Full Android run `:app:testDevDebugUnitTest ktlintCheck`: `BUILD SUCCESSFUL`, 401 result files, 5435 tests, 0 failures, 0 errors, 0 skipped.
- `payment details` appears nowhere under `app/src/main/res/values/` (grep 0); `You can\'t delete your account yet` is present.
- The Android saved-cards string and the Swift `savedCardsNote` literal are identical (shell `cmp`, MATCH).
- Tracer gate: Task 1's verify passed end to end before Task 2 started.

## Deviations from Plan

### Auto-fixed / scope notes

**1. [Rule 3 - Blocking] `DeleteAccountScreen.kt` added to Task 1's commit**
- **Found during:** Task 1
- **Issue:** the step-dependent header (details on the Warning step only) needs the screen to pass `showsDetails`; the file is not in the plan's `files_modified`.
- **Fix:** one-line change in `DeleteAccountScreen.kt`, committed with Task 1 (four paths, not three).
- **Commit:** `2a65e7c7`

**2. [Rule 3 - Blocking] Screen and entry signatures changed; extra test file**
- **Found during:** Task 2
- **Issue:** the blocker text depends on the active mode and "View My Bookings" needs the navigator, so `DeleteAccountScreen` and `DeleteAccountContent` gained `mode`, `onShowBookings` and `onDismissBlocker`, and `SettingsEntries.kt` (not listed) passes them. The navigation reset needed its own test, in a new `DeleteAccountNavigationTest.kt`.
- **Commit:** `e311a74c` (nine paths instead of three)

**3. [Rule 1 - Bug] Existing test updated to the new behavior**
- `conflictShowsServerMessageAndRetryMintsNewToken` asserted that an `EXPERT_HAS_UPCOMING_BOOKINGS` 409 shows the server message, which is exactly the old behavior this plan replaces. It became `blockerConflictKeepsTheFormAndRetryMintsNewToken` with the same form-preserved and new-token assertions.

**4. Commit trailer.** The plan names `Co-Authored-By: Claude Opus 5.5` for both Android commits and that is what they carry; the iOS-repo docs commit carries the trailer the session specified.

**5. Active mode source.** The plan's key link says the ErrorCode branch is "with the active mode". The ViewModel branches on the code only and the screen applies the mode (as iOS does at render time). The mode comes from the registering shell rather than `UserManager.currentMode`; the two agree because `AppViewModel` mirrors `currentMode` onto the shell route.

## Known Stubs

None.

## Threat Flags

None. T-08-36 is mitigated (word-for-word iOS strings, forbidden-phrase test across every `delete_account_*` string). T-08-37 is mitigated (the dialog text is client-owned, names no booking, person or amount; the branch is on the error code).

## Handoff

- Nothing was run on an Android device. The Android section of `08-REGRESSION-CHECKLIST.md` must cover: both Delete Account steps, and a blocker dialog for each code in each mode, on a throwaway account. Never delete a real account.
- REL-02 is deliberately not marked complete here; plan 08-24 ticks it.
- Android `main` is ahead by these two commits and was not pushed.

## Self-Check: PASSED

- Android `2a65e7c7` and `e311a74c` are ancestors of Android `HEAD`; iOS `10839fd` is an ancestor of iOS `HEAD`.
- `AccountDeletionBlocker.kt` and `DeleteAccountNavigationTest.kt` exist; `.planning/todos/completed/2026-11-13-android-delete-account-copy-and-blockers.md` exists and `.planning/todos/pending/` no longer holds it.
- `.idea/` was never staged in the Android repo.
