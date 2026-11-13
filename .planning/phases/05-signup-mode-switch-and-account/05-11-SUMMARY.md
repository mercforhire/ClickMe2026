---
phase: 05-signup-mode-switch-and-account
plan: 11
subsystem: signup
tags: [swiftui, signup, email-verification, swift-testing, resume]
status: complete

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: "05-04 SignupAccumulator with emailVerified flag and checklist mirror"
provides:
  - "SignupAccumulator.refreshEmailVerified(using:) seeding the flag from GET /auth/email/status"
  - "Setup hub re-seeds the Verify email row on every appearance"
  - "Fresh signup starts emailVerified from the signup response's email_verified"
affects: [05-16 Not now on SignupOverviewView, 05-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 1950
  tasks: 2
  commits: 2

commits: 2
plan_head_before: 1d22a30a2f739d555b1096c20194543f4dcd1205
plan_head_after: 967c9b97a9d6efcfb51c6ce16a49bdef105c5dbf

tech-stack:
  added: []
  patterns:
    - "Best-effort server read with try?: failure means unknown, keep the current value"
    - "Never-downgrade seed rule for a client-held flag"

key-files:
  created:
    - ClickMe2026Tests/Signup/SignupEmailVerifiedSeedTests.swift
  modified:
    - ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift
    - ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewViewModel.swift
    - ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift
    - ClickMe2026/Views/Screens/Signup Flow/Initial/SignupInitialViewModel.swift

key-decisions:
  - "GET /auth/email/status is the only source for the hub seed; GET /expert/profile has no email_verified field"
  - "Status read uses try? (best-effort): a failure or verified:false leaves the flag unchanged"
  - "A local true is never downgraded and short-circuits before any request"

patterns-established:
  - "Hub .task re-seeds server-derived checklist state on each appearance, covering launch resume, login resume, the gate's hub and the return from Verify email"

requirements-completed: [SIGN-02]

coverage:
  - id: D1
    description: "A resumed signup shows a verified email as verified: the hub seeds emailVerified from GET /auth/email/status"
    requirement: SIGN-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SignupEmailVerifiedSeedTests.swift (4 tests: seed true, verified false, status 500, local true never downgraded)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A fresh signup starts emailVerified from the signup response and never turns a true into false"
    requirement: SIGN-02
    verification:
      - kind: other
        ref: "grep response.emailVerified in SignupInitialViewModel.swift plus clean xcodebuild with no new warnings"
        status: pass
    human_judgment: true
    rationale: "attemptContinue calls the shared UserManager's real API, so it has no unit test; the never-downgrade rule it relies on is covered by SignupEmailVerifiedSeedTests. Device check: verify the email, force-quit mid-setup, relaunch, the Verify email row is still ticked."

duration: 10 min
completed: 2026-11-13
---

# Phase 5 Plan 11: Resume keeps a verified email verified Summary

**The expert signup hub now seeds the Verify email row from `GET /auth/email/status` on every appearance, and a fresh signup starts from the signup response's `email_verified`, so a user who already verified is never asked to again.**

## Performance

- **Duration:** about 10 min
- **Tasks:** 2 of 2
- **Files:** 5 (1 created, 4 modified)

## Accomplishments

- `SignupAccumulator.refreshEmailVerified(using:)`: returns at once when the flag is already true (no request, no downgrade); otherwise a best-effort `try?` read of `checkEmailVerified()` that sets the flag only on `verified == true`. `checkEmailVerified()` previously had no callers.
- `SignupOverviewViewModel.refreshEmailVerified()` and a `.task` on `SignupOverviewView`, so every appearance of the hub (launch `.signupSetup` resume, login resume, the hub the gate opens from Mode Switch, and the return from Verify email) re-seeds the flag.
- `SignupInitialViewModel.attemptContinue()` keeps the signup response and sets `accumulator.emailVerified = (current) || response.emailVerified`.
- `SignupEmailVerifiedSeedTests` (4 tests): verified true seeds the flag and checklist with one GET; verified false stays false; HTTP 500 stays false; local true makes no request and stays true.

## Task Commits

1. **Task 1 (tracer): hub shows a verified email as verified after a resume** - `c8d4946` (fix)
2. **Task 2: fresh signup starts from the server's email_verified** - `967c9b9` (fix)

## TDD notes

Task 1 carries `tdd="true"` inside a plan of `type: execute` with a single-commit contract, so RED/GREEN were run locally and committed once, as the plan specifies, rather than as separate `test(...)`/`feat(...)` commits.

- RED: with a no-op stub `refreshEmailVerified`, the target suite ran and failed on the planned assertions (`emailVerified` false after a verified answer, `statusRequestCount` 0 versus 1 in three tests); the never-downgrade test passed by design. Log `/tmp/05-11-red.log`. This is a real assertion failure, not a build error.
- GREEN: the 4 tests pass (`/tmp/05-11-t1.log`, "Test run with 4 tests in 1 suite passed").

## Verification

- `SignupEmailVerifiedSeedTests`: 4 tests, 1 suite, passed.
- Regression `SignupAccumulatorTests`: 12 tests, 1 suite, passed (`/tmp/05-11-reg.log`).
- Build: `BUILD SUCCEEDED`; warnings in the four app files before: 0, after: 0 (`comm -13` empty).
- Grep gates: `checkEmailVerified()` is called in `SignupAccumulator.swift`; `refreshEmailVerified` appears in `SignupOverviewView.swift` and `response.emailVerified` in `SignupInitialViewModel.swift`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Hub progress bar follows the seeded row**
- **Found during:** Task 1
- **Issue:** `animatedProgress` is set once in `.onAppear`. When the seed ticks Verify email a moment later, the checklist row updates but the progress bar would stay at the pre-seed value.
- **Fix:** The `.task` compares `viewModel.progress` before and after the refresh and animates `animatedProgress` to the new value only when it changed, so the existing 0.8 s appear animation is untouched when nothing changes.
- **Files modified:** `ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift`
- **Commit:** c8d4946

**Total deviations:** 1 auto-fixed (1 missing functionality). **Impact:** none on scope; two lines in a file the plan already edits.

UI-SPEC: no copy, casing or spacing in this plan's scope was refined; none of the strings or layout touched.

## Issues Encountered

None. `05-DEVICE-UAT-CHECKLIST.md` does not exist yet in the phase directory, so the SIGN-02 device check could not be appended there; it is recorded below for whoever builds that checklist.

## Device check (backstop, not run by the executor)

On a real iPhone: start an expert signup, verify the email, force-quit before publishing, relaunch. The hub opens with Verify email ticked.

## Known Stubs

None.

## Threat Flags

None. The only new request is the existing authenticated `GET /auth/email/status`; the flag is display-only (T-05-25 accepted).

## Notes

- `ClickMe2026/Localizable.xcstrings` and `.planning/config.json` carried pre-existing uncommitted edits; this plan did not touch or stage them.
- No backend change: the endpoint already exists and its `{ data: { verified } }` shape was confirmed in `auth.controller.js`.

## Next

Ready for 05-12 (and 05-16, which adds Not now to `SignupOverviewView` on top of this `.task`).

## Self-Check: PASSED

- FOUND: `ClickMe2026Tests/Signup/SignupEmailVerifiedSeedTests.swift`
- FOUND commits `c8d4946`, `967c9b9` (ancestors of HEAD)
