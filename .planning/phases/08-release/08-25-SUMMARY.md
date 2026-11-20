---
phase: 08-release
plan: "25"
subsystem: android-parity
tags: [android, kotlin, account-deletion, remember-email, parity, tdd, privacy]

requires:
  - phase: 08
    provides: "Plan 08-09: SecureTokenStore.lastLoginEmail / saveLastLoginEmail(email: String?) and FakeSecureTokenStore on Android main (adc3647a, e3676ef1)"
  - phase: 08
    provides: "Plan 08-12: keeps the Android lane sequential in ../ClickMe_Android"
provides:
  - "Android DeleteAccountRepository forgets the remembered login email after a successful deletion, durably and before deleteAccount returns, in a NonCancellable context on the IO dispatcher"
  - "A failed deletion (409 or network error) keeps the remembered email; tests assert both"
  - "Todo 2026-11-13-android-remember-login-email.md closed with a Resolution naming adc3647a, e3676ef1 and 2d75fb97"
affects: [08-17, android-release, 08-REGRESSION-CHECKLIST]

actuals:
  tokens: 2300
  tasks: 2
  commits: 1

# commits is measured in the Android repo, where this plan's code commit lives:
# git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count 384142ee..HEAD
commits: 1
plan_head_before: 384142ee77c68c11cdfaea88f1f8edadd8250548
plan_head_after: 2d75fb974d394df2222c0f1d22dba04ab1acc557

tech-stack:
  added: []
  patterns:
    - "A privacy side effect that must survive scope cancellation runs in withContext(NonCancellable + io) after the API call returns, so it never runs on failure and never gets skipped on success"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountRepository.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountViewModelTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountScreenTest.kt"
    - ".planning/todos/completed/2026-11-13-android-remember-login-email.md (moved from pending/)"

key-decisions:
  - "Added a third test row beyond 0c9ecc55's two: a network failure (IOException) during deleteAccount also keeps the email, because the plan's behavior bullet names both the 409 and the network error."

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "A successful account deletion forgets the remembered login email before deleteAccount returns, so the Login shown after the Farewell starts empty"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/settings/deleteaccount/DeleteAccountViewModelTest.kt#successfulDeletionForgetsTheRememberedLoginEmail"
        status: pass
    human_judgment: false
  - id: D2
    description: "A failed deletion (409 blocker or network error) keeps the remembered email"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/settings/deleteaccount/DeleteAccountViewModelTest.kt#failedDeletionKeepsTheRememberedLoginEmail, networkFailureDuringDeletionKeepsTheRememberedLoginEmail"
        status: pass
    human_judgment: false
  - id: D3
    description: "The remembered email is really gone from the Keystore-backed encrypted prefs after deleting a throwaway account on a device"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "EncryptedPrefsTokenStore cannot run under Robolectric/JVM, so the unit tests use FakeSecureTokenStore. The real store is covered by the Android section of 08-REGRESSION-CHECKLIST.md on a device, using a throwaway account (a real account must never be deleted for testing)."

duration: 5min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 25: Android account deletion forgets the remembered email Summary

**Android account deletion now clears the remembered login email in a NonCancellable context before returning, finishing the hand port of 0c9ecc55 (with 08-09) and matching iOS 1.1; a failed deletion keeps it.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-20T05:02:00Z
- **Completed:** 2026-11-20T05:07:00Z
- **Tasks:** 2
- **Files modified:** 4 (3 in `/Users/LeonChen/Documents/ClickMe_Android`, 1 todo moved in the iOS repo)

## Accomplishments

- `DeleteAccountRepository` takes `tokens: SecureTokenStore` and `@IoDispatcher io: CoroutineDispatcher`. After `api.deleteAccount` succeeds it runs `withContext(NonCancellable + io) { tokens.saveLastLoginEmail(null) }`, so a cancelled scope cannot skip it. A thrown API error exits before that line, so the email stays.
- `DeleteAccountViewModelTest` seeds the fake store with an email and gained three rows: success forgets it, a 409 keeps it, a network failure keeps it. `DeleteAccountScreenTest` builds the repository with `FakeSecureTokenStore()` and the test dispatcher.
- The folded todo is closed in `.planning/todos/completed/` with a `## Resolution` naming `adc3647a`, `e3676ef1` (08-09) and `2d75fb97` (this plan), and the device check in the Android section of `08-REGRESSION-CHECKLIST.md`.
- Ported by hand: `git merge-base --is-ancestor 0c9ecc55 main` still fails, and `feature/remember-login-email` was only read with `git show`.
- The email is never logged. No dependency added.

## Task Commits

1. **Task 1: tracer, deletion forgets the remembered email** - Android `2d75fb97` (feat), exactly the three deleteaccount paths
2. **Task 2: full Android run, close the todo** - iOS `fd80363` (docs), the todo move only

**Android SHAs for the todo:** `adc3647a`, `e3676ef1`, `2d75fb97`. Nothing was pushed in either repo.

**Plan metadata:** recorded in the iOS repo by the docs commit that adds this file.

## TDD record (single code commit, as the plan fixes one Android commit)

**RED** (`:app:testDevDebugUnitTest --tests ...DeleteAccountViewModelTest`, constructor params and tests in place, no forget call yet): 21 tests, 1 failed, `BUILD FAILED`:

```
DeleteAccountViewModelTest > successfulDeletionForgetsTheRememberedLoginEmail FAILED
    java.lang.AssertionError at DeleteAccountViewModelTest.kt:388
```

Semantic assessment: it failed on the planned `assertNull(tokens.lastLoginEmail)` (the seeded email was still there), not on a compile or fixture fault. The two keep-the-email rows passed at RED by construction (nothing is cleared yet); they are guards that must stay green.

**GREEN:** the `deleteaccount.*` tests plus ktlint pass, BUILD SUCCESSFUL.

## Verification

- Task 1 automated verify: `deleteaccount.*` tests + `ktlintCheck` BUILD SUCCESSFUL, and `DeleteAccountRepository.kt` contains `saveLastLoginEmail(null)` (`/tmp/08-25-t1.log`).
- Full run `:app:testDevDebugUnitTest ktlintCheck`: BUILD SUCCESSFUL, 5397 tests, 0 failures, 0 skipped (`/tmp/08-25-full.log`).
- `git show --stat 2d75fb97` lists exactly the three deleteaccount paths; `git rev-list --count 384142ee..HEAD` = 1; `.idea/` never staged.
- Task 2 automated verify: todo present in `completed/`, absent from `pending/`, `## Resolution` present.

## Decisions Made

- A third test row (network failure keeps the email) was added beyond the two in 0c9ecc55, because the plan's truth names both the 409 and the network error.

## Deviations from Plan

None - plan executed exactly as written.

The todo commit was first made without the Resolution text (the rename was staged before the text was appended). It was amended before anything else used it; the final commit `fd80363` holds the rename and the Resolution. Local and unpushed, so no history was affected.

## Issues Encountered

None. Disk stayed at about 5.2 GiB free; no build failed for space.

## Known Stubs

None.

## Threat Flags

None. T-08-54 is mitigated: the clear runs in a NonCancellable context after a successful delete, a test asserts the fake store is empty afterwards, and the email is never logged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Android remember-login-email is complete across 08-09 and 08-25. Plan 08-17 edits the same two deleteaccount test files and can build on `2d75fb97`.
- Device check for the real encrypted store (D3) belongs to the Android section of `08-REGRESSION-CHECKLIST.md`; use a throwaway account for the deletion step.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Android commit `2d75fb97` is on `main` (`git merge-base --is-ancestor`); the three changed files exist.
- iOS commit `fd80363` holds the todo move; `.planning/todos/completed/2026-11-13-android-remember-login-email.md` exists and the pending copy does not.
