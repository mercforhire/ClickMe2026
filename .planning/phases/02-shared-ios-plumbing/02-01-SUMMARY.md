---
phase: 02-shared-ios-plumbing
plan: 01
subsystem: calls
tags: [swift, swiftui, agora, call-overtime, swift-testing]

requires:
  - phase: 01
    provides: none (independent call-screen fix)
provides:
  - CallOvertimePolicy, a pure and unit-tested rule for the overtime cutoff (end + 60), the warning (end + 55) and the POST /end duration
  - Call screen that no longer cuts a live call off at end + 5 minutes
  - "This call will end in 5 minutes" notice on the existing banner
  - POST /end that sends at least 1 second for a joined leg and no request for a never-joined leg
affects: [phase-02-device-uat, android-call-ended-follow-up]

plan_head_before: fb94bb2d0803531047fd134b61ca0ef250a04c9f
plan_head_after: 1a2148ae487e819892de3f017e0b06126df536d2

actuals:
  tokens: 3300
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Time rules live in a nonisolated pure enum that never reads the clock; callers pass now"
    - "Best-effort writes use do/catch with a DEBUG-only log line, not try?"

key-files:
  created:
    - ClickMe2026/Utils/CallOvertimePolicy.swift
    - ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift
  modified:
    - ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift
    - ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift

key-decisions:
  - "Cutoff stays at 3600 s: the server accepts /end until end + 70 and the Agora token lives until end + 70, so end + 60 is the safe ceiling"
  - "A never-joined leg sends no POST /end rather than inventing a duration; this matches Android and today's effective behavior (the server 422 was swallowed by try?)"
  - "A failed POST /end shows the user nothing and the teardown and dismiss still run; it is logged in DEBUG only with the booking id and userMessage"

patterns-established:
  - "CallOvertimePolicy: pure, nonisolated, boundary-tested policy type used by the view model's 1 s timer"

requirements-completed: [CALL-01, CALL-04]

coverage:
  - id: D1
    description: "A running call is not ended locally before scheduled end + 60 minutes; at end + 60 it ends through CallCenter.endCall"
    requirement: CALL-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift#constants, beforeWarning, cutoffReached, nilEndIsNone"
        status: pass
    human_judgment: true
    rationale: "The cutoff boundaries are unit tested, but the fix has not run on a device. The user's iPhone was still on a pre-fix build when it disconnected at about end + 5 minutes. The end + 10 and full end + 60 run is Phase 2 device checklist item 1."
  - id: D2
    description: "The banner shows 'This call will end in 5 minutes' from end + 55 minutes"
    requirement: CALL-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift#warningWindow"
        status: pass
    human_judgment: true
    rationale: "The warn window is tested; the banner copy, placement and animation are visual and need a device look."
  - id: D3
    description: "POST /end sends at least 1 second for a joined leg and nothing for a never-joined leg; a failed /end is caught and logged in DEBUG only"
    requirement: CALL-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift#neverJoinedIsNil, shortLegIsClampedToOne, negativeLegIsClampedToOne, longLegTruncates"
        status: pass
    human_judgment: true
    rationale: "The duration rule is unit tested. Whether the /end request reaches the server and the peer's call.ended fires is an end-to-end behavior no unit test asserts (see the Android follow-up)."

duration: "2h (spans the tracer gate pause)"
completed: 2026-11-09
status: complete
---

# Phase 2 Plan 01: Call overtime cutoff and /end duration Summary

**CallOvertimePolicy restores the 60-minute overtime cutoff in place of the 5-minute testing constant, adds an end + 55 notice, and makes POST /end send at least 1 second via do/catch instead of try?**

## Performance

- **Duration:** about 2 h wall clock, mostly the pause at the tracer gate
- **Started:** 2026-11-09 (Task 1 commit 17:43 -0500)
- **Completed:** 2026-11-10T00:38:19Z (Task 2 commit 19:38 -0500)
- **Tasks:** 2 of 2
- **Files modified:** 4 (2 created, 2 modified), plus 76 net-new lines in the Task 2 commit

## Accomplishments

- The 5-minute testing cutoff that ended every call at scheduled end + 5 minutes is gone. A call now runs to end + 60 and then ends through `CallCenter.endCall`, the same path as a hang-up.
- At end + 55 the existing amber banner reads "This call will end in 5 minutes". No new styling.
- `POST /bookings/:id/end` never sends a 0-second leg (the server rejects it with a 422). A leg that never joined sends no request.
- The `/end` call no longer swallows errors with `try?`; it is caught, logged in DEBUG only, and the teardown and dismiss still run.
- 9 Swift Testing tests pin the constants and every boundary one second either side.

## Task Commits

1. **Task 1: Tracer, a running call reaches end + 60 and ends through the normal end path** - `be00d74` (fix)
2. **Task 2: End + 55 notice and the /end duration clamp** - `1a2148a` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Utils/CallOvertimePolicy.swift` - nonisolated enum: `cutoff`, `warningLead`, `Action`, `action(scheduledEnd:now:)`, `endDuration(joinStart:now:)`
- `ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift` - `applyOvertimePolicy(now:)` on the 1 s tick, `isOvertimeWarning`, do/catch around `/end`
- `ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift` - banner text and animation for the warning state
- `ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift` - boundary and duration tests

## Decisions Made

- Cutoff held at 3600 s with a comment explaining the end + 70 server and Agora-token ceiling, so nobody raises it.
- Never-joined leg sends no `/end`; matches Android.
- No backend or Android change.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0.

Test counts: Task 1 run and Task 2 run both used `-only-testing:ClickMe2026Tests/CallOvertimePolicyTests` with the plan's `EXCLUDED_SOURCE_FILE_NAMES`. The Task 2 run reported "Test run with 9 tests in 1 suite passed" (log `/tmp/02-01-t2.log`). The Task 1 run passed with the five Task 1 test functions (log `/tmp/02-01-t1.log`). Build: `BUILD SUCCEEDED`. Warning comparison against the pre-change baseline printed nothing, so there are no new warnings in the three touched Swift files.

Acceptance greps at HEAD: `TEMP` count 0 (baseline 2), `enforceMaxOvertimeCutoff` 0 (baseline 2), `max(0, duration)` 0 (baseline 1), `try? await api.endCall` 0 (baseline 1), `CallOvertimePolicy.endDuration` 1, `isOvertimeWarning` in the view 2.

## Issues Encountered

**Device check is deferred and the fix is not yet device-verified.** The user approved the Task 1 tracer gate with "approve and defer"; the on-device check moves to the Phase 2 device UAT checklist (item 1).

Device evidence the user supplied: on a real iPhone with an Android peer, a 30-minute session (7:00 to 7:30 pm) disconnected on the iPhone at about 7:35 pm. That matches the OLD 5-minute testing cutoff, so the iPhone was running a build from before `be00d74`. Re-test on a build from `be00d74` or later: the call should still be connected at end + 10, show the notice at end + 55, and end by itself at end + 60.

## Follow-ups (not done here)

- **Android peer stayed connected after the iPhone auto-ended.** Per the backend `docs/SOCKET-CONTRACT.md` (`call.ended`), `/end` emits `call.ended` to both participants and the peer should tear down. Either the iOS `POST /end` failed silently (the old code used `try?`; Task 2 now logs failures in DEBUG, so a debug build will show it) or the Android app does not handle `call.ended` on that path. Check this during the Phase 2 device UAT with a debug iOS build. No Android or backend repo was changed.
- The Skype/Zoom variant has no Agora session and its 1 s timer pauses while the app is in the background, so the cutoff there applies when the app returns. Accepted in the plan.
- The warning banner is shown only in the in-app voice layout (`agoraCallContent`), as before; the Skype layout has no banner.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or trust-boundary changes. T-02-01, T-02-02 and T-02-29 are mitigated as planned.

## Next Phase Readiness

- Ready for the remaining Phase 2 plans.
- CALL-01 is not closed until the end + 10 and end + 60 device runs pass (Phase 2 device checklist item 1).

## Self-Check: PASSED

- Files exist: `CallOvertimePolicy.swift`, `CallOvertimePolicyTests.swift`, `MeetingCallViewModel.swift`, `MeetingCallView.swift`.
- Commits `be00d74` and `1a2148a` are ancestors of HEAD; `git rev-list --count fb94bb2..HEAD` was 2 before this docs commit.
- Acceptance greps and the plan-level build and warning comparison re-run after the final edit: all pass.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-09*
