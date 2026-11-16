---
phase: 06-expert-mode
plan: 10
subsystem: testing
tags: [uat, device-checklist, phase-gate, validation, todos]

requires:
  - phase: 06-expert-mode
    provides: "plans 06-01 to 06-09 (all Phase 6 code and the Android EXP-17 commit)"
provides:
  - "Phase gate proof: 952 tests in 93 suites passed in one xcodebuild run, Debug build succeeded, every phase grep gate passed"
  - "06-DEVICE-UAT-CHECKLIST.md: Setup, Notes, Automated evidence and 35 device and assumption items"
  - "Two follow-up todos (Android parity, USD symbol) linked from STATE.md"
  - "06-VALIDATION.md automated sign-off (status stays draft)"
affects: [/gsd-verify-work 06, /gsd-validate-phase 06, Phase 8 pre-release pass]

actuals:
  tokens: 11900
  tasks: 2
  commits: 2  # MEASURED: git rev-list --count ${PLAN_HEAD_BEFORE}..HEAD at SUMMARY write; the docs(06-10) completion commit follows this file

tech-stack:
  added: []
  patterns:
    - "STATE.md staged from a HEAD copy through git update-index --cacheinfo so tool-owned edits never enter a plan's commit"

key-files:
  created:
    - .planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md
    - .planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md
    - .planning/todos/pending/2026-11-16-usd-symbol-us-dollar-prefix.md
  modified:
    - .planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md
    - .planning/phases/06-expert-mode/06-VALIDATION.md
    - .planning/STATE.md

key-decisions:
  - "The known-flaky MakeABookingAvailabilityTests failed once at line 154 and passed on the rerun; recorded in the checklist and its todo, not part of the verdict (no Phase 6 commit touches Make a Booking)"
  - "No requirement checkbox in REQUIREMENTS.md was ticked: the plan's truth (and the checklist's note) leaves that to /gsd-verify-work 06, so the dispatch instruction to mark them was not applied"

requirements-completed: [EXP-01, EXP-02, EXP-03, EXP-04, EXP-05, EXP-06, EXP-07, EXP-08, EXP-09, EXP-10, EXP-12, EXP-14, EXP-15, EXP-16, EXP-17, EXP-18]

plan_head_before: eb7049628608b49e64c3f540b677b4fb3e4479fc
plan_head_after: 6c55b75ab059f8d54edf847f82db6d918827c06e

coverage:
  - id: D1
    description: "The whole phase passes together: full unit suite in one invocation (smoke suites and the known flake skipped), Debug build, and the nine grep gates"
    requirement: EXP-09
    verification:
      - kind: other
        ref: "xcodebuild test (phase gate): Test run with 952 tests in 93 suites passed, TEST SUCCEEDED (/tmp/06-10-full.log)"
        status: pass
      - kind: other
        ref: "xcodebuild build Debug: BUILD SUCCEEDED, no new warnings (/tmp/06-10-build.log)"
        status: pass
      - kind: other
        ref: "grep gates: rateMajor 0, 409 claim 0, slot binding 0, expertName in Confirmed 0, replace(with:) 0, opacity(request.isExpired 0, isOnline 0, nav-bar pins 1 and 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Device UAT checklist with 35 items (every UI-SPEC D1 to D6, LT3, OV2, E7, PO1 check, every plan human-check, the 06-07 TextEditor truncation note, the Android picker and two KEEP or CHANGE assumptions)"
    verification: []
    human_judgment: true
    rationale: "The checklist is the hand-off to a human on a real iPhone; its Results are filled in by the user and read by /gsd-verify-work 06"
  - id: D3
    description: "Follow-ups logged as todos: Android parity (Add hours, off-grid rows, 409, client hub dot) and the USD symbol question (Open Question 3)"
    verification:
      - kind: other
        ref: "file checks: AvailabilityScheduleLogic and US$ present; both linked from STATE.md"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 10: Phase 6 Gate, Device UAT Checklist and Follow-ups Summary

**Phase 6 is proven green together (952 tests in 93 suites, Debug build clean, all nine grep gates), and the user now has one 35-item device checklist, two follow-up todos and a signed-off validation file; no app code changed.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-11-16T18:40Z
- **Completed:** 2026-11-16T18:48Z
- **Tasks:** 2
- **Files modified:** 6 (3 created, 3 modified, plus the flaky-test todo)

## Accomplishments
- Phase gate on HEAD `eb70496` (last Phase 6 app commit `9e95cf3`): `Test run with 952 tests in 93 suites passed after 8.277 seconds`, `** TEST SUCCEEDED **`, in one xcodebuild invocation with every Phase 6 `.serialized` MockURLProtocol suite alongside the others. Smoke suites and `MakeABookingAvailabilityTests` were skipped; the latter ran alone afterward.
- Debug build succeeded; the only warning line is the build system's own AppIntents metadata note. All nine grep gates passed (the six change gates at 0, the path-replace guard at 0, the two nav-bar pins at 1 each).
- `06-DEVICE-UAT-CHECKLIST.md`: Setup (build at or after `9e95cf3`, production at backend `28da165`, accounts by role), Notes, Automated evidence, and 35 items: topic editor (1 to 9), availability (10 to 13), accept and Booking Confirmed (14 to 20), expert surfaces (21 to 25), the private note (26 to 31), the Android picker (32), populated states PO1 (33) and two KEEP or CHANGE assumptions (34, 35). Item 31 carries 06-07's note that a truncated keystroke or paste must leave the TextEditor showing the truncated text (WINDOWS #36). The two settled decisions (D-11 and D-19 amendments) are named in Notes and only their behavior is checked (items 14, 15, 29).
- `2026-11-16-android-phase-6-parity-follow-ups.md` (four items, Android source read) and `2026-11-16-usd-symbol-us-dollar-prefix.md` (Open Question 3); STATE.md captured-todo list drops the folded dark-pin todo and links the two new ones. The STATE.md hunk of the docs commit is exactly those three bullets.
- `06-VALIDATION.md`: `nyquist_compliant: true`, `wave_0_complete: true`, 9 boxes ticked, every map row green (EXP-12 reads `green (grep); device D1 pending`), Approval names gate commit `9e95cf3`; `status: draft` kept.

## Task Commits

1. **Task 1: Tracer, the whole phase passes together, evidence opens the checklist** - `2346936` (docs)
2. **Task 2: Device items, follow-up todos, STATE.md todo list, 06-VALIDATION.md sign-off** - `6c55b75` (docs)

**Plan metadata:** the docs(06-10) completion commit that follows this file.

## Files Created/Modified
- `.planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md` - the Phase 6 device checklist
- `.planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md` - Android follow-ups
- `.planning/todos/pending/2026-11-16-usd-symbol-us-dollar-prefix.md` - USD `$` versus `US$` decision
- `.planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md` - one dated line appended
- `.planning/phases/06-expert-mode/06-VALIDATION.md` - automated sign-off
- `.planning/STATE.md` - captured-todo list only (in the task commit)

## Decisions Made
- Known flake recorded, not gated: run 1 of `MakeABookingAvailabilityTests` failed at `MakeABookingAvailabilityTests.swift:154` (`Zone/1` against `Zone/2`, exactly the todo's failure), run 2 passed. No Phase 6 commit touches the Make a Booking folder or its test (0 commits in `fe3372c..HEAD`).
- Checklist expectations: item 3 says a USD topic card reads `$20.00` (the shipped `Money` table), citing the USD-symbol todo, so the `US$` editor label versus `$` card is not scored as a failure.
- Item 6 expects `CA$12.50` under a French (Canada) locale because `Money` uses a fixed symbol table, not the device locale.

## Deviations from Plan

**1. [Instruction conflict] Requirement checkboxes not ticked**
- **Found during:** SUMMARY and state updates
- **Issue:** the dispatch said to mark the phase's EXP requirements complete if `requirements.ready-ids` reports them ready. The plan's must-have truth, the checklist's Notes and the Phase 5 precedent (05-13) say this plan ticks no requirement checkbox: whether a device item re-opens a requirement is for `/gsd-verify-work 06`, and every EXP item still has an unrun device check.
- **Fix:** followed the plan's truth; REQUIREMENTS.md is untouched. `ready-ids` output is reported in the return notes. The orchestrator can mark them after verification if it wants.
- **Files modified:** none

**Total deviations:** 1 (instruction conflict resolved toward the plan's stricter rule). **Impact on plan:** none on deliverables.

## Issues Encountered
- The known-flaky run failed once as expected and passed on the rerun (see Decisions).
- Xcode rewrote `ClickMe2026/Localizable.xcstrings` during the build, as before; it was never staged.

## Known Stubs
None. No app code changed.

## Threat Flags
None. T-06-16: the checklist refers to accounts by role and holds no token, password, card number or email (checked by grep).

## User Setup Required
None - no external service configuration required. The user runs `06-DEVICE-UAT-CHECKLIST.md` on a real iPhone, with an Android device for items 25 and 32 and App Store build 6 for item 21.

## Next Phase Readiness
- Phase 6 is ready for `/gsd-verify-work 06` (reads the checklist Results) and `/gsd-validate-phase 06` (sets `status: validated`).
- Open and carried: WINDOWS #36 (06-07 device checks) is now item 26 to 31 of the checklist and stays open until run; the Phase 2 to 5 device checklists still run before Phase 8.

## Self-Check: PASSED
- FOUND: 06-DEVICE-UAT-CHECKLIST.md (35 items, 35 Result lines), both new todo files, 06-VALIDATION.md sign-off.
- FOUND commits: 2346936, 6c55b75 (ancestors of HEAD); the task-2 commit lists exactly the five planned files; its STATE.md diff is the three todo bullets only; the working STATE.md has no todo-list difference from HEAD.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
