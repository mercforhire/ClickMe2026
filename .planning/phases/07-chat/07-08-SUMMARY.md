---
phase: 07-chat
plan: 08
subsystem: testing
tags: [phase-gate, device-uat, validation, chat, swift-testing, xcodebuild]

requires:
  - phase: 07-chat
    provides: "Plans 07-01 to 07-07 (optimistic send, retry and cap, thread lookup, blocked banner, report and block, profile block, unread pill)"
provides:
  - "Phase 7 gate evidence: full unit suite 1168 tests in 107 suites green, Debug build green, all grep gates, 624-line view-model ceiling and the D-17 Read-handler guard"
  - "07-DEVICE-UAT-CHECKLIST.md: 18 numbered items covering UI-SPEC C1 to C10, every deferred human-check, the backstops and the Manual-Only rows"
  - "CHAT-08 closure note in REQUIREMENTS.md (closed as not reproducible, no fix made, box left unticked)"
  - "07-VALIDATION.md signed off (nyquist_compliant and wave_0_complete true, status stays draft)"
affects: [07-09, verify-work 07, phase-08]

actuals:
  tokens: 9000
  tasks: 2
  commits: 2

plan_head_before: 003aff86aac61895231d1929a355118170a3e3fc
plan_head_after: 6774e7f8e2f67d855a1d2628adb883b094a70a6b

tech-stack:
  added: []
  patterns:
    - "Phase close-out plan: gate evidence first (tracer), then the device checklist, then requirement note and validation sign-off"

key-files:
  created:
    - .planning/phases/07-chat/07-DEVICE-UAT-CHECKLIST.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/phases/07-chat/07-VALIDATION.md
    - .planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md

key-decisions:
  - "Recorded CHAT-08 as closed as not reproducible only because the D-17 guard passed: handleMessageRead is byte-identical to the phase base 16fe88e (13-line extract)"
  - "Approval in 07-VALIDATION names the gate run HEAD 003aff8 and the evidence commit 8fdc9fd; the D-18 row stays pending because plan 07-09 owns it"
  - "Did not run requirements mark-complete: the plan forbids ticking any requirement box; /gsd-verify-work 07 decides after the device Results"

patterns-established:
  - "Checklist item per UI-SPEC device check, merging each plan's human-check into the matching C item and citing the plan"

requirements-completed: [CHAT-01, CHAT-02, CHAT-03, CHAT-04, CHAT-05, CHAT-06, CHAT-07, CHAT-08]

coverage:
  - id: D1
    description: "The whole phase passes together: full unit suite (LoginTests included; smoke suites and the known-flaky suite excluded), Debug build succeeds"
    requirement: "CHAT-01"
    verification:
      - kind: integration
        ref: "xcodebuild test -only-testing:ClickMe2026Tests (log /tmp/07-08-full.log): Test run with 1168 tests in 107 suites passed, ** TEST SUCCEEDED **"
        status: pass
      - kind: other
        ref: "xcodebuild build Debug (log /tmp/07-08-build.log): ** BUILD SUCCEEDED **, only the AppIntents metadata warning"
        status: pass
    human_judgment: false
  - id: D2
    description: "Phase grep gates, the 624-line ChattingViewModel ceiling and the D-17 Read-handler guard hold on the final tree"
    requirement: "CHAT-08"
    verification:
      - kind: other
        ref: "plan 07-08 Task 1 grep block (14 checks PASS) and cmp of handleMessageRead against 16fe88e"
        status: pass
    human_judgment: false
  - id: D3
    description: "Known-flaky MakeABookingAvailabilityTests recorded separately: run 1 passed, no Phase 7 commit touches Make a Booking"
    verification:
      - kind: unit
        ref: "/tmp/07-08-flaky-1.log: Test run with 5 tests in 1 suite passed"
        status: pass
    human_judgment: false
  - id: D4
    description: "Device UAT checklist with 18 items (C1 to C10, backstops, A13 row, three KEEP or CHANGE judgements) and the 07-09 outcome line"
    verification:
      - kind: other
        ref: "plan 07-08 Task 2 automated check (item count, Result lines, CHAT-01 to CHAT-08, C1 to C10, no secret patterns)"
        status: pass
    human_judgment: true
    rationale: "The checklist is only useful once the user runs it on two iPhones; its completeness against the UI-SPEC and plan human-checks is judged at /gsd-verify-work 07"
  - id: D5
    description: "CHAT-08 closure note in REQUIREMENTS.md and 07-VALIDATION sign-off"
    requirement: "CHAT-08"
    verification:
      - kind: other
        ref: "git diff 16fe88e -- .planning/REQUIREMENTS.md changes only the CHAT-08 line, box unticked; 07-VALIDATION has nyquist_compliant: true and wave_0_complete: true with status: draft"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 08: Phase gate, device UAT checklist and validation sign-off Summary

**Phase 7 proven together (1168 tests in 107 suites green, Debug build green, grep gates and the 624-line view-model ceiling held, Read handler untouched), with an 18-item two-iPhone UAT checklist, CHAT-08 recorded as closed-as-not-reproducible, and the validation strategy signed off**

## Performance

- **Duration:** 10 min
- **Started:** 2026-11-18T06:44:00Z
- **Completed:** 2026-11-18T06:54:00Z
- **Tasks:** 2
- **Files modified:** 4 (one created)

## Accomplishments

- Ran the whole gate on the final Phase 7 code commit (`7452bc0`, HEAD `003aff8`): `Test run with 1168 tests in 107 suites passed after 8.784 seconds.`, `** TEST SUCCEEDED **`; LoginTests compiled and ran. The known-flaky suite passed on run 1 (5 tests), so no rerun was needed.
- Debug build `** BUILD SUCCEEDED **` with only the build system's own AppIntents metadata warning.
- All 14 grep checks passed (block copy claims, unblock latch, sheet identifier, logging, `try?` on chat writes, unfiltered prepend, old report labels, persistence APIs, error-message matching, `.badge`, both nav-bar pins, the coordinator and mapper files, the size ceiling). `ChattingViewModel.swift` is exactly 624 lines, with the new logic in `ChatSendCoordinator` (123), `ChatItemMapper` (182) and `ChatBlockState` (224).
- D-17 guard passed: `handleMessageRead` is byte-identical to `16fe88e`, so the REQUIREMENTS.md note truthfully says no CHAT-08 fix was made.
- Wrote `07-DEVICE-UAT-CHECKLIST.md`: Setup, Notes, Automated evidence and 18 items (C1 to C10, the per-plan human-checks merged by item, a CHAT-08 regression row inside C6 with the backend-first triage note, a plain A13 verification row, three KEEP or CHANGE judgements for Open Question 3, research A4 and UI-SPEC A12, and a PO1 sweep). Item 14 (C10) has the before step on App Store build 6, the conditional after step and a `07-09 outcome:` line for plan 07-09.
- Appended the CHAT-08 closure note to REQUIREMENTS.md (box unticked, one line changed), and signed off `07-VALIDATION.md`.

## Task Commits

1. **Task 1: Tracer, gate evidence and checklist skeleton** - `8fdc9fd` (docs)
2. **Task 2: Device items, CHAT-08 note, validation sign-off** - `6774e7f` (docs)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified

- `.planning/phases/07-chat/07-DEVICE-UAT-CHECKLIST.md` - the device UAT checklist and automated evidence (new)
- `.planning/REQUIREMENTS.md` - CHAT-08 closure note, box left unticked
- `.planning/phases/07-chat/07-VALIDATION.md` - sign-off, rows green, added rows for suites beyond the draft map
- `.planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md` - one dated line for this run

## Decisions Made

- The CHAT-08 note was written only after the D-17 guard passed.
- 07-VALIDATION Approval names the gate run (`003aff8`, last app commit `7452bc0`) and the evidence commit (`8fdc9fd`); the D-18 row (`ChatBookingRowRouteTests`) stays pending because plan 07-09 owns it.
- `requirements.mark-complete` was not run: this plan explicitly ticks no requirement box, and `/gsd-verify-work 07` decides after the device Results.

## Deviations from Plan

None - plan executed exactly as written. One small fix inside Task 2: my first edit of the VALIDATION frontmatter also flipped the word in a comment line; it was restored before the commit, so the committed diff changes only the intended lines.

## Issues Encountered

None. Every gate passed on the first run. No app or test code was changed.

## Deferred human verification

This plan adds no new device-only `<human-check>` of its own: its deliverable is the checklist that carries all of them. Every deferred check from plans 07-01 to 07-07 (already logged in `.planning/WINDOWS.md` as `unrun-verify`) is now an item in `07-DEVICE-UAT-CHECKLIST.md` with steps, expected result and a `Result:` line, so nothing further was logged. Run it on two iPhones, then `/gsd-verify-work 07`.

## Known Stubs

None. No code was written in this plan.

## Threat Flags

None. Docs only; the checklist's secret-pattern gate (T-07-19) returned 0 matches and accounts are named by role.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 07-09 (D-18, expert chat booking row) is next; it fills `07-09 outcome:` in checklist item 14 and closes the `ChatBookingRowRouteTests` row in `07-VALIDATION.md`.
- Before Phase 8 and the release: the user runs the checklist (and the Phase 2 to 6 partial checklists), then `/gsd-verify-work 07` reads the Results and decides the CHAT-01 to CHAT-08 boxes.

## Self-Check: PASSED

- Files exist: `07-DEVICE-UAT-CHECKLIST.md`, `07-VALIDATION.md`, `REQUIREMENTS.md`, the flaky todo (all FOUND).
- Commits `8fdc9fd` and `6774e7f` are ancestors of HEAD.
- Task 1 and Task 2 acceptance criteria re-run: automated Task 2 check PASS; `git diff 16fe88e -- .planning/REQUIREMENTS.md` shows only the CHAT-08 line; `grep -c 'status: draft'` on VALIDATION prints 1; the flaky todo gained one dated line naming `/tmp/07-08-flaky-1.log`.

---
*Phase: 07-chat*
*Completed: 2026-11-18*
