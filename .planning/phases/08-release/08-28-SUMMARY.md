---
phase: 08-release
plan: "28"
subsystem: android-parity
tags: [android, kotlin, signup, email-verification, parity, tdd]

requires:
  - phase: 08
    provides: "Plan 08-26: the user's Android parity port requests; P6 (resume keeps the verified email)"
  - phase: 05
    provides: "iOS 05-11 (SIGN-02): SignupAccumulator.refreshEmailVerified seeds the flag from GET /auth/email/status and never downgrades a local true"
provides:
  - "Android setup hub keeps Verify email ticked on every reappearance after a local verify, even when GET /auth/email/status answers verified false"
  - "An already-verified draft makes no status request on reappearance (SignupSetupRepository.refreshEmailStatus returns early)"
  - "A hydrate (launch, pull-to-refresh, re-hydrate after a failure) still reads the status endpoint and still reports Loaded, but merges it with emailVerified || status.verified: the server can tick the row, never untick it"
affects: [08-29, 08-30, 08-31, 08-15, android-release]

actuals:
  tokens: 2000
  tasks: 2
  commits: 2

# commits is measured in the Android repo, where this plan's code commits live:
# git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count b1e37ca2..HEAD
commits: 2
plan_head_before: b1e37ca2c017212f60c1ee840f9e110c48ab52a3
plan_head_after: 5a044d0ab5cf50b73194b75ae5aab0f5db2f769c

tech-stack:
  added: []
  patterns:
    - "A server flag that only seeds display state is merged with OR (local || server), and a flag that is already true skips the request, so a stale answer can never undo a local success"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/signup/SignupSetupRepository.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/signup/SignupSetupRepositoryTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/signup/overview/SignupOverviewViewModelTest.kt"

key-decisions:
  - "The fix lives in the repository, not in SignupOverviewViewModel: onShown and refresh already call refreshEmailStatus and hydrate, so one early return and one OR in the private status merge cover every hub path"
  - "runHydrate keeps its concurrent status call and its ok rule, so the hub's Loaded and Failed states are unchanged; only what the merge does with the answer changed"
  - "seedFromSignup is untouched: it runs once on a fresh draft right after account creation, so it cannot downgrade a local success"

patterns-established:
  - "Never-downgrade seed: refreshEmailStatus returns before the API call when the flag is already true, and mergeStatus ORs the server answer into the local flag"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Returning to the Android setup hub after a successful Verify email keeps the row ticked and makes no status request, even if the server would answer verified false"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/signup/overview/SignupOverviewViewModelTest.kt#onShownAfterALocalVerifyKeepsVerifyEmailTickedAndSkipsTheStatusCall"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/SignupSetupRepositoryTest.kt#refreshEmailStatusAfterALocalVerifyMakesNoRequest"
        status: pass
    human_judgment: false
  - id: D2
    description: "An unverified draft still becomes verified on a verified true answer and stays unverified on false, on reappearance and on hydrate"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/signup/SignupSetupRepositoryTest.kt#refreshEmailStatusUnverifiedAnswerLeavesTheFlagFalse"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/SignupSetupRepositoryTest.kt#refreshEmailStatusUpdatesTheVerifiedFlag"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/SignupSetupRepositoryTest.kt#hydrateTicksAnUnverifiedEmailWhenTheServerSaysVerified"
        status: pass
    human_judgment: false
  - id: D3
    description: "A hydrate (repository and pull-to-refresh) after a local verify still reads the status endpoint, still reports Loaded, and keeps the email verified"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/signup/SignupSetupRepositoryTest.kt#hydrateAfterALocalVerifyKeepsTheEmailVerified"
        status: pass
      - kind: unit
        ref: "app/src/test/.../screens/signup/overview/SignupOverviewViewModelTest.kt#pullToRefreshAfterALocalVerifyKeepsVerifyEmailTicked"
        status: pass
    human_judgment: false
  - id: D4
    description: "On a real Android device, a fresh expert signup keeps Verify email ticked across hub reappearance, pull to refresh, other steps, force-quit and relaunch mid-setup"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "The real status endpoint, process death and relaunch are not exercised by repository and view model tests; the (P6) device check below covers them"

duration: 14min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 28: Android Verified-Email Resume (P6) Summary

**Android setup hub no longer unticks a verified email (iOS 05-11 parity): refreshEmailStatus skips the request when the draft is already verified, and the status merge is `emailVerified || status.verified`, so no reappearance, pull-to-refresh, launch or re-hydrate can downgrade a local success.**

## Performance

- **Duration:** about 14 min (start time not captured at launch; estimated from the first command to this write)
- **Completed:** 2026-11-20T06:30Z
- **Tasks:** 2 (reappearance tracer, hydrate path plus full run)
- **Files modified:** 3 (all in the Android repo; no iOS code, no backend change)

## Accomplishments

- Closed port request P6: before this plan Android re-read `GET /auth/email/status` on every hub appearance and copied the answer straight over the local flag, so a stale `verified: false` could untick Verify email right after the user verified it.
- `SignupSetupRepository.refreshEmailStatus` now returns before the API call when `_draft.value.emailVerified` is true (iOS `refreshEmailVerified`: "a flag that is already true is never downgraded and costs no request"); an unverified draft still calls, and still becomes verified only on a true answer.
- The private `mergeStatus` is now `copy(emailVerified = emailVerified || status.verified)`, which covers launch, pull-to-refresh and re-hydrate-after-failure. `runHydrate` still makes its concurrent status call and keeps its `ok = profile != null && status != null` rule, so Loaded and Failed behave as before.
- Six new unit rows; the full Android unit suite passes (5409 tests, 0 failures, 0 skipped, up from 5403) with ktlint.

## Task Commits

All commits are local on Android `main`; nothing was pushed (Android `origin/main` is still `27e024bf`).

1. **Task 1: Tracer, the hub reappears after a local verify and keeps Verify email ticked, with no status request** - `1b536ef2` (fix; three paths)
2. **Task 2: A hydrate never downgrades a verified email; full Android run** - `5a044d0a` (fix; the same three paths)

`git -C /Users/LeonChen/Documents/ClickMe_Android log --oneline b1e37ca2..HEAD` shows exactly these two commits (08-27's last commit is `b1e37ca2`). `.idea/*` and the untracked `.planning/` files were never staged.

**Plan metadata:** the iOS repo docs commit that holds this SUMMARY (docs: complete plan).

## TDD evidence (RED)

RED was run first for each task and is recorded here, not committed separately (the plan calls for one commit per task). Both RED runs compiled and failed on assertions, not on compilation or setup. The repo's classifier (`gsd_run check tdd-red-evidence`) has no adapter for Gradle's console output, so the semantic assessment below is the evidence.

**Task 1 (reappearance), 55 tests, 2 failed:**

```
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest \
  --tests '...screens.signup.SignupSetupRepositoryTest' --tests '...screens.signup.overview.SignupOverviewViewModelTest'
SignupSetupRepositoryTest > refreshEmailStatusAfterALocalVerifyMakesNoRequest FAILED                             (java.lang.AssertionError)
SignupOverviewViewModelTest > onShownAfterALocalVerifyKeepsVerifyEmailTickedAndSkipsTheStatusCall FAILED         (java.lang.AssertionError)
55 tests completed, 2 failed
```

Semantic assessment: both failing tests are the planned targets, failing on the planned assertion (the verified flag was downgraded to false by the stale answer, because the call was made and its answer copied over the local flag). The third row, `refreshEmailStatusUnverifiedAnswerLeavesTheFlagFalse`, passed at RED because today's code already did that; it pins behavior that must not regress.

**Task 2 (hydrate), 58 tests, 2 failed:**

```
SignupSetupRepositoryTest > hydrateAfterALocalVerifyKeepsTheEmailVerified FAILED                    (java.lang.AssertionError)
SignupOverviewViewModelTest > pullToRefreshAfterALocalVerifyKeepsVerifyEmailTicked FAILED           (java.lang.AssertionError)
58 tests completed, 2 failed
```

Semantic assessment: the two "after a local verify" rows failed on their assertions because the status merge still overwrote the local flag, as the plan predicted. `hydrateTicksAnUnverifiedEmailWhenTheServerSaysVerified` passed at RED (the overwrite also ticks an unverified draft) and pins the other half of the rule.

GREEN: Task 1 the two filtered classes plus `ktlintCheck`, BUILD SUCCESSFUL; Task 2 one full `:app:testDevDebugUnitTest ktlintCheck`, BUILD SUCCESSFUL (5409 tests, 0 failures, 0 skipped).

## Files Created/Modified

- `SignupSetupRepository.kt` - early return in `refreshEmailStatus` when already verified (KDoc updated to the iOS rule); `mergeStatus` ORs the server flag into the local one (KDoc cites iOS 05-11)
- `SignupSetupRepositoryTest.kt` - four new rows: `refreshEmailStatusAfterALocalVerifyMakesNoRequest`, `refreshEmailStatusUnverifiedAnswerLeavesTheFlagFalse`, `hydrateAfterALocalVerifyKeepsTheEmailVerified`, `hydrateTicksAnUnverifiedEmailWhenTheServerSaysVerified`
- `SignupOverviewViewModelTest.kt` - two new rows: `onShownAfterALocalVerifyKeepsVerifyEmailTickedAndSkipsTheStatusCall`, `pullToRefreshAfterALocalVerifyKeepsVerifyEmailTicked`; one new import

## Decisions Made

- The fix is in the repository the hub already calls, so `SignupOverviewViewModel.kt` is unchanged.
- `hydrate` keeps reading the status endpoint because its Loaded/Failed result depends on both calls; only the merge changed (as the plan's assumptions state).
- `reset()` on logout still clears the draft, so a new account starts unverified (threat T-08-58, accepted: display state only, the server enforces verification itself).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- One Bash call (the plan's single-line verify with `&&` chains, `tee` and `$(...)`) was refused by the harness's old bash before it ran; the full run was re-issued as separate simpler commands with the same Gradle invocation and the same checks (BUILD SUCCESSFUL in `/tmp/08-28-full.log`, `emailVerified || status.verified` present once, `copy(emailVerified = status.verified)` absent, the hydrate test present, `origin/main` still `27e024bf`). The test count came from the Gradle XML results (5409 tests, 0 skipped, 0 failures).
- Disk free was 6.3 GiB at the start and 7.1 GiB after the full run; no cleanup was needed and nothing was deleted.

## Device checks for 08-15 (Android section)

**(P6) Verified email survives resume on Android.** Run on a dedicated test account with a fresh unpublished expert signup, on an Android dev build from `ClickMe_Android` `main` (at or after `5a044d0a`).

1. Sign up as a new expert, open Verify email from the setup hub and verify the code. Expect the Verify email row ticked on the hub.
2. Pull to refresh on the hub. Expect Verify email stays ticked.
3. Open and leave two other steps (for example Personal details and Timezone). Expect Verify email stays ticked each time the hub reappears.
4. Force-quit the app, relaunch and log in mid-setup. Expect the hub loads with Verify email still ticked.
5. Failure handling: if the row ever unticks after a successful verify, record which step preceded it (reappearance, pull to refresh, other step, or relaunch).

## Known Stubs

None. No placeholder values or unwired data in the changed files.

## Threat Flags

None. No new endpoint, auth path or trust-boundary file access; T-08-58 (a local verified flag kept over a server false) is accepted as planned: display state only, cleared on logout.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-29 to 08-31 chain after this plan on Android `main` at `5a044d0a`; the Android lane stays sequential.
- 08-31 consolidates this section's (P6) item into its own `## Device checks for 08-15 (Android section)` for 08-15's checklist.
- Nothing is pushed in either repo; Android `origin/main` is `27e024bf`.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Android commits `1b536ef2` and `5a044d0a` are on `main` (`git merge-base --is-ancestor`); every changed Android file exists.
- `git log --oneline b1e37ca2..HEAD` lists exactly two commits; `git show --stat` of each lists exactly the three planned paths (no `.idea/`).
- `emailVerified || status.verified` appears once in `SignupSetupRepository.kt`; the old overwriting merge is gone; all six new test names exist.
- Android `origin/main` is still `27e024bf`; no iOS app code or backend file was changed.
