---
phase: 06-expert-mode
plan: 16
subsystem: expert-mode-gap-closure-gate
tags: [uat, device-checklist, gap-closure, xcodebuild, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "Gap-closure code plans 06-11 (blank currency), 06-12 (card cents), 06-13 (plain calendar event), 06-18 (expert summary calendar), 06-14 (client Upcoming Booking calendar), 06-15 (Android calendar)"
provides:
  - "Automated evidence that the whole gap-closure iOS tree passes together (994 tests, Debug build, grep gates)"
  - "06-DEVICE-UAT-CHECKLIST.md section 'Gap closure re-check' with items R1 to R8 for the device re-check"
affects: [06-17, verify-work]

actuals:
  tokens: 3100
  tasks: 2
  commits: 2
plan_head_before: 1724c93c05808ec09c12f57e2b9a50f43ed871be
plan_head_after: d134a49a43d7edc4858e6070bfb00fc7c429ba6e

tech-stack:
  added: []
  patterns:
    - "Gate plan: one full-suite run, one known-flaky record run and one build with grep gates, quoted into the checklist before the device items"

key-files:
  created: []
  modified:
    - .planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md
    - .planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md

key-decisions:
  - "Appended the re-check section after item 35 as additions only (0 removed lines against 4baacec), so the user's 35 recorded Results are untouched"
  - "The Setup for R1 to R8 is a short bullet list rather than one paragraph, so the iPhone SHA, Android SHA and the backend-unchanged fact are each easy to find"

requirements-completed: [EXP-02, EXP-03, EXP-10, EXP-17]

coverage:
  - id: D1
    description: "The full iOS unit suite passes in one xcodebuild invocation on the final gap-closure tree with more tests than the 952 of plan 06-10"
    requirement: EXP-17
    verification:
      - kind: command
        ref: "xcodebuild test (full suite): Test run with 994 tests in 95 suites passed; TEST SUCCEEDED (/tmp/06-16-full.log)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Debug build succeeds with no new warnings; the nine 06-10 grep gates and the per-gap gates pass"
    requirement: EXP-10
    verification:
      - kind: command
        ref: "xcodebuild build: BUILD SUCCEEDED, only the AppIntents metadata warning (/tmp/06-16-build.log); 9 phase gates + 11 gap gates PASS"
        status: pass
    human_judgment: false
  - id: D3
    description: "The user has a device re-check list (R1 to R8) for checklist items 1, 4, 8 and 17, including the expert Cancel sheet beside the new calendar sheet"
    requirement: EXP-02
    verification:
      - kind: command
        ref: "Task 2 automated check: 8 R items, 43 Result lines, 0 removed lines against 4baacec, gap ids and copy present, no token-looking string"
        status: pass
    human_judgment: true
    rationale: "R1 to R8 are device checks against production; their Results are filled by the user and read by /gsd-verify-work 06"

duration: 15min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 16: Gap closure gate and device re-check list Summary

**The whole Phase 6 gap-closure tree passes together (994 unit tests, clean Debug build, every grep gate), and `06-DEVICE-UAT-CHECKLIST.md` now carries the evidence and eight device re-check items (R1 to R8) for checklist items 1, 4, 8 and 17.**

## Performance

- **Duration:** about 15 min (most of it the full suite, the flaky run and the build)
- **Completed:** 2026-11-17T05:45Z
- **Tasks:** 2
- **Files modified:** 2 (no app, test, Android or backend file)

## Accomplishments
- Full unit suite in one invocation: `Test run with 994 tests in 95 suites passed after 8.588 seconds.` and `** TEST SUCCEEDED **`, 42 more tests than the 952 of plan 06-10. Skipped as in 06-10: `AuthSmokeTests`, `SignupSmokeTests` (production) and `MakeABookingAvailabilityTests` (known flaky).
- Known-flaky `MakeABookingAvailabilityTests` alone: run 1 passed (5 tests in 1 suite); no second run was needed. Outcome appended to the flaky-test todo.
- Debug build: `BUILD SUCCEEDED`; the only `warning:` line is the build system's "Metadata extraction skipped. No AppIntents.framework dependency found."
- Grep gates: the nine 06-10 phase gates and the per-gap gates (no direct hourly-rate currency read, `priceLabel(for` on the card, sheet takes a plain event, both summary screens present `CalendarEventEditorSheet(event:`, exactly one cancellation sheet and two sheets on the expert summary, none in the client Session Summary, Android `isCalendarEventOffered`) all pass.
- Checklist: a `## Gap closure re-check (plans 06-11 to 06-15 and 06-18)` section with an intro, `### Automated evidence (gap closure)`, a setup list (iPhone build at or after `2a6c578`, Android at or after `69c4e159`, backend unchanged so production still sends `price.currency: ""`), and R1 to R8. R4 re-checks the `Confirm Cancellation` sheet with `Keep Booking` before and after the New Event sheet.

## Task Commits

1. **Task 1: Tracer, the gap-closure tree passes together and the evidence opens the re-check section** - `e90c617` (docs)
2. **Task 2: The device re-check items for checklist items 1, 4, 8 and 17** - `d134a49` (docs)

**Plan metadata:** the docs commits that carry this file and the state update. Plan base: `1724c93c05808ec09c12f57e2b9a50f43ed871be`.

## Files Created/Modified
- `.planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md` - re-check section appended after item 35 (additions only)
- `.planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md` - one dated line

## Decisions Made
- Tracer gate: the task is a documentation tracer whose `<verify>` is fully automated; the three automated checks passed end to end before the second task was written, so nothing blocked expansion.
- No Android or backend work here. The Android commit and its Gradle result are quoted from the 06-15 SUMMARY and were not re-run.

## Deviations from Plan

None - plan executed exactly as written. No SUMMARY recorded a deviation in copy or placement, so the items use the plan's wording (the one note carried over is 06-15's: the Android client button sits directly after the notes card; a placement preference from the device check is a one-line move).

## Issues Encountered

None. All three automated blocks passed on the first run. HEAD was on `main` with `git.allow_default_branch_commits` true. The pre-existing uncommitted files (`ClickMe2026/Localizable.xcstrings`, `.planning/config.json`, `.planning/state.json`, `.planning/milestone.lock`, the `.DS_Store` files) were never staged.

## Verification

- Task 1: full suite (994 tests passed), flaky record run (passed), grep gates and build (`BUILD SUCCEEDED`); checklist diff against `4baacec` shows 0 removed lines.
- Task 2: 8 `### R<n>.` items, 43 `Result:` lines (35 + 8), 35 original items, gap ids and copy present, no bearer or JWT-looking string.
- Not run: the UI tests, the smoke suites and every device or Android check (R1 to R8 are the user's).

## User Setup Required

Device re-check by the user: R1 to R8 in `06-DEVICE-UAT-CHECKLIST.md`, on an iPhone build at or after `2a6c578` and an Android build at or after `69c4e159`. R4 must stop at `Keep Booking` (never confirm a cancellation on a live booking).

## Known Stubs

None.

## Threat Flags

None. T-06-26 mitigated: accounts are named by role, the Task 2 check found no token-looking string, and the quoted log lines carry test names and results only.

## Next Phase Readiness
- Remaining in phase 06: 06-17 (optional backend hardening decision; deploys nothing).
- `/gsd-verify-work 06` reads the R1 to R8 Results once the user fills them.

## Self-Check: PASSED

- Both modified files exist; commits `e90c617` and `d134a49` are ancestors of HEAD (2 commits measured since `1724c93`).
- Checklist re-check section and `### Re-check items` heading present.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
