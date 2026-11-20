---
phase: 08-release
plan: "09"
subsystem: android-parity
tags: [android, kotlin, encrypted-prefs, login, remember-email, parity, tdd]

requires:
  - phase: 08
    provides: "iOS 1.1 remembered-login-email behavior (ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift) as the contract; Android branch commit 0c9ecc55 as the source to port by hand"
provides:
  - "Android SecureTokenStore.lastLoginEmail and saveLastLoginEmail(email: String?) (null removes it), implemented in the Keystore-backed encrypted prefs and in FakeSecureTokenStore; clear() now removes only the token keys so the email survives every sign-out"
  - "Android UserManager stores the trimmed email after a successful login or signup (blank ignored), exposes rememberedLoginEmail() and forgetLastLoginEmail()"
  - "Android LoginViewModel pre-fills the remembered email with an empty password after any sign-out; an explicit prefill (password reset), a saved-state email or typing wins"
affects: [08-25, android-release, 08-REGRESSION-CHECKLIST]

actuals:
  tokens: 5350
  tasks: 2
  commits: 2

plan_head_before: 337f4c0c659f25bf39c073a8238e628c4872c670
plan_head_after: e3676ef18426dddd14830f982301dd4a1215abc3
commits: 2

tech-stack:
  added: []
  patterns:
    - "PII that must outlive a sign-out lives in the same EncryptedSharedPreferences file as the tokens; clear() removes named token keys instead of wiping the file"
    - "A view model's initial value from an async source uses an emailOwned flag: saved state, prefill and typing all set it, so a late async load never overwrites them"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/managers/SecureTokenStore.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/managers/EncryptedPrefsTokenStore.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/managers/UserManager.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/login/LoginViewModel.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/testing/FakeSecureTokenStore.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/managers/UserManagerTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/login/LoginViewModelTest.kt"

key-decisions:
  - "Manager accessor is named rememberedLoginEmail() (the plan's contract and verify grep), not lastLoginEmail() as in 0c9ecc55. The store slot keeps the branch names (lastLoginEmail / saveLastLoginEmail / forgetLastLoginEmail) that plan 08-25 depends on."
  - "startSession ignores a blank email (trim then isNotEmpty) so a whitespace-only value never overwrites the previous one, matching iOS ignoresWhitespaceOnlyEmail. 0c9ecc55 stored email.trim() unconditionally."

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "A successful login or signup stores the trimmed email in the encrypted store; blank is ignored; a failed login keeps the previous value"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../managers/UserManagerTest.kt#loginRemembersTrimmedEmailOfTheSuccessfulLogin, whitespaceOnlyEmailIsNotStoredAndKeepsThePreviousOne, failedLoginKeepsThePreviouslyRememberedEmail, signupRemembersEmail"
        status: pass
    human_judgment: false
  - id: D2
    description: "The email survives Log Out, a rejected refresh and a suspension; forgetLastLoginEmail removes it"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../managers/UserManagerTest.kt#rememberedEmailSurvivesLogoutRejectionAndSuspension, forgetLastLoginEmailRemovesIt"
        status: pass
    human_judgment: false
  - id: D3
    description: "Login pre-fills the remembered email with an empty password after any sign-out; reset email, saved state and typing win; the field stays editable"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/login/LoginViewModelTest.kt (10 remembered-email rows)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The remembered email is persisted in the Keystore-backed encrypted prefs and survives clear() on a real device"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "EncryptedPrefsTokenStore cannot run under Robolectric/JVM (KeyStoreException); the unit tests use FakeSecureTokenStore. Covered by the Android section of 08-REGRESSION-CHECKLIST.md on a device."

duration: 5min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 09: Android remembered login email Summary

**Android pre-fills the last signed-in email on Login after any sign-out, stored trimmed in the Keystore-backed encrypted prefs and ported by hand from 0c9ecc55 to match iOS 1.1.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-20T04:47:18Z
- **Completed:** 2026-11-20T04:52:30Z
- **Tasks:** 2
- **Files modified:** 7 (all in `/Users/LeonChen/Documents/ClickMe_Android`)

## Accomplishments

- `SecureTokenStore` gained `lastLoginEmail` / `saveLastLoginEmail(email?)`, implemented in `EncryptedPrefsTokenStore` (encrypted prefs only, committed durably, cached) and `FakeSecureTokenStore`. `clear()` now removes the three token keys instead of wiping the file, so the email survives every sign-out path.
- `UserManager` remembers the trimmed email after a successful login or signup, ignores a blank value, and exposes `rememberedLoginEmail()` and `forgetLastLoginEmail()`.
- `LoginViewModel` pre-fills the remembered email on a fresh Login. An `emailOwned` flag makes saved state, the password-reset `prefill` and anything the user typed outrank it, including when the async read finishes late.
- Ported by hand: `git merge-base --is-ancestor 0c9ecc55 main` still fails, and the branch `feature/remember-login-email` was only read.
- The email is never logged and the password is never stored. No file under `screens/settings/deleteaccount/` changed (plan 08-25).

## Task Commits

Both in the Android repo (`main`, local only, nothing pushed):

1. **Task 1: tracer, store and manager** - `adc3647a` (feat)
2. **Task 2: Login pre-fill** - `e3676ef1` (feat)

**Android SHAs for plan 08-25's todo close:** `adc3647a`, `e3676ef1`.

**Plan metadata:** recorded in the iOS repo by the docs commit that adds this file.

## TDD record (single commit per task, as the plan fixes two commits)

**Task 1 RED** (`:app:testDevDebugUnitTest --tests ...UserManagerTest`, run with the store, fake and manager read accessors in place but no write on login): 75 tests, 3 failed on assertions, `BUILD FAILED`:

```
UserManagerTest > rememberedEmailSurvivesLogoutRejectionAndSuspension FAILED  AssertionError at UserManagerTest.kt:1370
UserManagerTest > signupRemembersEmail FAILED                                 AssertionError at UserManagerTest.kt:1357
UserManagerTest > loginRemembersTrimmedEmailOfTheSuccessfulLogin FAILED       AssertionError at UserManagerTest.kt:1317
```

Semantic assessment: each target test ran and failed on the planned `assertEquals` of the remembered email, not on a compile or fixture fault. The whitespace-only and failed-login rows passed at RED by construction (nothing is written yet) and are guards that must stay green. GREEN: all 75 pass, ktlint clean.

**Task 2 RED** (`...LoginViewModelTest`, tests added, `LoginViewModel` unchanged): 29 tests, 3 failed on assertions, `BUILD FAILED`:

```
LoginViewModelTest > loginAfterServerSideSuspensionPrefillsTheLastEmail FAILED
LoginViewModelTest > loginAfterForcedLogoutPrefillsTheLastEmail FAILED
LoginViewModelTest > loginAfterLogOutPrefillsTheLastEmailWithEmptyPassword FAILED
```

Semantic assessment: each failed on the expected pre-filled email being `""`. The reset, typing, saved-state and empty-first-launch rows pass at RED because they assert the existing behavior that must not regress. GREEN: all pass, ktlint clean.

## Verification

- `UserManagerTest` + ktlint: BUILD SUCCESSFUL, and `UserManager.kt` contains `rememberedLoginEmail`.
- `LoginViewModelTest` + ktlint: BUILD SUCCESSFUL.
- Full run `:app:testDevDebugUnitTest ktlintCheck`: BUILD SUCCESSFUL (`/tmp/08-09-full.log`).
- `git rev-list --count 337f4c0c..HEAD` = 2; changed paths are exactly the seven in `files_modified`; `.idea/` never staged.

## Decisions Made

- Manager accessor is `rememberedLoginEmail()` per the plan, instead of 0c9ecc55's `lastLoginEmail()`. Plan 08-25 uses only the store's `saveLastLoginEmail(null)` and `lastLoginEmail`, so it is unaffected.
- A blank email is ignored in `startSession`, as the plan's behavior bullet and iOS require. The branch stored `email.trim()` even when empty.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 0c9ecc55 would overwrite the remembered email with an empty string**
- **Found during:** Task 1
- **Issue:** The branch hunk calls `tokens.saveLastLoginEmail(email.trim())` unconditionally. A whitespace-only email replaces the previous value with `""`, contradicting the plan's truth ("an empty or whitespace-only value is ignored") and iOS `ignoresWhitespaceOnlyEmail`.
- **Fix:** Only save when the trimmed email is non-empty. Added `whitespaceOnlyEmailIsNotStoredAndKeepsThePreviousOne`.
- **Files modified:** `managers/UserManager.kt`, `managers/UserManagerTest.kt`
- **Verification:** UserManagerTest green
- **Committed in:** `adc3647a`

**2. [Rule 3 - Blocking] Manager accessor renamed to match the plan contract**
- **Found during:** Task 1 verify
- **Issue:** The plan's artifact (`contains: rememberedLoginEmail`), key link and automated grep require `rememberedLoginEmail` in `UserManager.kt`; the branch names it `lastLoginEmail()`, so the verify would fail.
- **Fix:** Named it `rememberedLoginEmail()`; tests use it. Store-level names stay as in the branch.
- **Committed in:** `adc3647a`

**3. [Scope note] `forgetLastLoginEmail()` and its Login test row ported here**
- 0c9ecc55 puts `forgetLastLoginEmail()` in `UserManager.kt` and a row using it in `LoginViewModelTest.kt`, both files in this plan. They are ported (the row is named `loginAfterForgettingTheEmailHasEmptyEmail`). Wiring it to account deletion stays in plan 08-25.

---

**Total deviations:** 3 (1 bug, 1 blocking, 1 scope note)
**Impact on plan:** No scope creep; the first two make behavior match the plan's stated truths.

## Issues Encountered

None. Disk stayed at about 5 GiB free; no build failed for space.

## Known Stubs

None.

## Threat Flags

None. T-08-22 mitigations hold: encrypted prefs only (the new key sits in the same `EncryptedSharedPreferences` file as the tokens), no logging of the email (the only new log line is a fixed string), no password stored. Deletion forgetting the email is plan 08-25.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 08-25 can build on `SecureTokenStore.saveLastLoginEmail(null)` and `FakeSecureTokenStore`; it needs the two SHAs above for the todo close.
- Device check for the encrypted store (D4) belongs to the Android section of `08-REGRESSION-CHECKLIST.md`.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Android commits `adc3647a` and `e3676ef1` are on `main` (verified with `git merge-base --is-ancestor`); the seven changed files exist.
