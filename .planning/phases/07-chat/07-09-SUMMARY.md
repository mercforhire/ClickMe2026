---
phase: 07-chat
plan: 09
subsystem: chat
tags: [swiftui, navigation, booking, expert-shell, d-18, tdd]

requires:
  - phase: 07-chat
    provides: "07-08 phase gate, device UAT checklist (item 14 / C10) and the chat system-event rows (BookingEvent.bookingId / isTerminal)"
provides:
  - "ChatBookingRowRoute.route(isTerminal:bookingId:hostsClientBookingFlows:), a pure shell-aware destination for a tapped chat booking row"
  - "Expert shell chat booking rows open ExpertBookingSummaryView for active and finished bookings (D-18); client shell unchanged"
  - "D-18 todo closed with a Resolution; dual-role follow-up todo; C10 outcome recorded"
affects: [phase-07 device UAT, phase-07 verification, dual-role booking routing]

actuals:
  tokens: 2500
  tasks: 3
  commits: 3
  plan_head_before: 4d1c17d66f6f1459ba1d020d8cae422a4b692e9b
  plan_head_after: 472cb2a95b966419cbf43d835a141ecba240e8e8

tech-stack:
  added: []
  patterns:
    - "Pure routing helper chosen by an environment flag (hostsClientBookingFlows) instead of branching inside the view"

key-files:
  created:
    - ClickMe2026/Utils/ChatBookingRowRoute.swift
    - ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift
    - .planning/todos/pending/2026-11-17-chat-booking-row-dual-role-route.md
  modified:
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
    - .planning/phases/07-chat/07-DEVICE-UAT-CHECKLIST.md
    - .planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md
    - .planning/WINDOWS.md

key-decisions:
  - "D-18 decision checkpoint answered 'reproduced' by the user after a device check on App Store build 6 as the test expert, so the route was changed"
  - "The shell, not the viewer's role on the booking, decides the destination; dual-role users are logged as a pending todo with the event_data expert_id idea, not built (07-RESEARCH Open Question 2)"

patterns-established:
  - "RED stub that keeps the old behaviour compiles and fails on the assertion, so RED evidence is a real assertion failure, not a build error"

requirements-completed: [D-18]

coverage:
  - id: D1
    description: "Expert shell: a tapped chat booking row opens the expert Booking Summary for active and finished bookings"
    requirement: "D-18"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift#expert shell, finished booking opens the expert summary"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift#expert shell, active booking opens the expert summary"
        status: pass
    human_judgment: true
    rationale: "The unit test proves the route choice, not that the screen loads on a device against production. Device check C10 after-step (item 14) is deferred to the end-of-phase UAT."
  - id: D2
    description: "Client shell keeps bookingSummary for finished bookings and upcomingBooking for active ones"
    requirement: "D-18"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift#client shell, finished booking keeps the client summary"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift#client shell, active booking keeps the upcoming booking screen"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-18 outcome recorded in C10, todo closed with a Resolution, dual-role follow-up todo created"
    requirement: "D-18"
    verification:
      - kind: other
        ref: "Task 3 automated check (file moves, Resolution, expert_id, C10 outcome line)"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 09: Expert chat booking rows open the expert Booking Summary Summary

**A pure `ChatBookingRowRoute` helper sends a tapped chat booking row to `ExpertBookingSummaryView` in the expert shell (active or finished) and keeps the client screens in the client shell, wired into `ChattingView` and covered by a four-row test.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-11-18T15:19:00Z (approximate)
- **Completed:** 2026-11-18T15:35:00Z
- **Tasks:** 3 (1 decision checkpoint answered before dispatch, 1 TDD tracer, 1 docs)
- **Files modified:** 9 (2 app, 1 test, 1 checklist, 2 todos, 1 new todo, WINDOWS.md, flaky todo)

## Accomplishments

- D-18 is applied on the "reproduced" branch: in the expert shell (`hostsClientBookingFlows` false) a booking row in a chat now pushes `HomeRoute.expertBookingSummary`, which loads from the expert endpoint, instead of the client screens that call `GET /client/bookings/:id` (behind `roleCheck('client')`). Matches Android `ExpertBookingSummaryKey`.
- The choice is one pure function with a four-case unit test; `ChattingView.openBookingDetail(for:)` now has a single push and its doc comment, which sat on `openPeerProfile`, is back on the right function.
- Final-tree phase gate re-run after the app change: full suite 1172 tests in 108 suites passed (1168 plus the 4 new), build clean, every Phase 7 grep gate, the 624-line ceiling and the D-17 `handleMessageRead` byte-identical guard all pass. The checklist's Automated evidence section now names `491b600`.

## Task Commits

1. **Task 1: D-18 decision checkpoint** - no commit. Answered "reproduced" by the user before dispatch (device check on App Store build 6, expert account).
2. **Task 2: Tracer (TDD)**
   - RED: `f8bfa3e` (test) - four-row test plus a compile-only stub that keeps the old client routes
   - GREEN: `491b600` (fix) - helper implemented, `ChattingView` wired
3. **Task 3: Record outcome, close todo, dual-role follow-up** - `472cb2a` (docs)

**Plan metadata:** the docs commit that follows this SUMMARY (SUMMARY, STATE, ROADMAP, WINDOWS ledger, flaky-test todo note).

## TDD

- **RED:** `ChatBookingRowRouteTests` against a stub returning the pre-D-18 client routes. Result: 4 tests, 2 failed (the two expert-shell rows, on `route == .expertBookingSummary(...)`, got `.bookingSummary` / `.upcomingBooking`), 2 passed (client shell). `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`, format `swift-testing`). Semantic assessment: the target executed and failed on the planned assertion; no build, load or fixture fault.
- **GREEN:** `ChatBookingRowRoute.route` returns the expert summary when `hostsClientBookingFlows` is false, otherwise the client summary for terminal events and the upcoming screen for active ones. 4 of 4 pass.
- **REFACTOR:** none needed.

## Files Created/Modified

- `ClickMe2026/Utils/ChatBookingRowRoute.swift` - shell-aware destination for a chat booking row (cites D-18, the backend role check, Android, and the dual-role limit)
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` - reads `hostsClientBookingFlows`, one push through the helper
- `ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift` - pure four-case route table
- `.planning/phases/07-chat/07-DEVICE-UAT-CHECKLIST.md` - C10 outcome, Build line and Automated evidence updated to `491b600`
- `.planning/todos/completed/2026-11-16-expert-chat-row-opens-client-booking-screen.md` - moved from `pending/` with a Resolution
- `.planning/todos/pending/2026-11-17-chat-booking-row-dual-role-route.md` - new, the dual-role limit and the `event_data.expert_id` idea
- `.planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md` - one line: failed on run 1, passed on run 2 in the final-tree gate
- `.planning/WINDOWS.md` - ledger entry for the deferred device check

## Decisions Made

- The user answered "reproduced" at the D-18 checkpoint, so the code change went ahead. This is recorded in C10 and the todo Resolution.
- Dual-role users keep the shell rule for this phase (07-RESEARCH Open Question 2); the per-viewer idea is a pending todo, not built.

## Deviations from Plan

### Auto-fixed Issues

**1. [Process - TDD split] Task 2 landed as two commits, not one**
- **Found during:** Task 2
- **Issue:** the plan's commit step says "commit only the three files" in one `fix(07-09)` commit, but the execution context requires a RED test commit before the implementation, and a RED that is a build error is INVALID_RED.
- **Fix:** RED commit `f8bfa3e` = test file + compile-only stub of the helper (2 files); GREEN commit `491b600` = helper + `ChattingView` (2 files). Together they are exactly the three planned files; GREEN uses the plan's `fix(07-09)` message.
- **Verification:** `git show --stat` on both; no unplanned files; no deletions.

---

**Total deviations:** 1 (process, no scope change)
**Impact on plan:** None on behaviour or file set.

## Issues Encountered

- `MakeABookingAvailabilityTests` (known flake, todo `2026-11-13-flaky-make-a-booking-availability-test.md`) failed on run 1 of the final-tree gate and passed on run 2, as the 07-08 command allows. No Phase 7 commit touches Make a Booking. Noted in the todo and the checklist.

## Deferred human verification

Deferred to the end-of-phase UAT per `workflow.human_verify_mode = end-of-phase`; logged in `.planning/WINDOWS.md` (kind `unrun-verify`, phase 7) and carried by checklist item 14 (C10, UI N3).

Steps (needs a real iPhone on a build at or after `491b600`, and the test expert and test client accounts with a thread that has a booking row):

1. As the test expert, open a chat that has a booking row. Tap an active booking row (request, confirmed or rescheduled). Expected: the expert Booking Summary opens and loads, with no load error.
2. As the test expert, tap a finished booking row (declined, cancelled, completed or expired). Expected: the expert Booking Summary opens and loads, with no load error.
3. As the test client, tap the same rows. Expected: an active booking opens the client's upcoming-booking screen and a finished one opens the client's booking summary, as before.
4. Record `PASS`, `FAIL (what happened)` or `SKIPPED (why)` in the `Result:` line of item 14. The 07-09 outcome line is already filled (reproduced, `491b600`).

## Known Stubs

None. (The RED-phase stub was replaced in `491b600`.)

## Threat Flags

None. No new endpoint or trust boundary; T-07-20 is mitigated as planned: the expert shell reads through the expert endpoint, and both endpoints stay role- and participant-scoped server-side.

## Android follow-up

None needed for D-18: Android already routes expert-mode chat rows to `ExpertBookingSummaryKey`. The dual-role todo notes that Android would need the same per-viewer rule if it is ever built.

## Next Phase Readiness

- All nine Phase 7 plans have a SUMMARY after this one. Phase 7 is ready for `/gsd-verify-work 07` once the user runs the device checklist (`07-DEVICE-UAT-CHECKLIST.md`, items 1 to 18 including C10 item 14).
- The pre-existing uncommitted `Localizable.xcstrings`, `.planning/config.json` and `.DS_Store` edits were not staged.

## Self-Check: PASSED

- Created files exist: `ClickMe2026/Utils/ChatBookingRowRoute.swift`, `ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift`, `.planning/todos/pending/2026-11-17-chat-booking-row-dual-role-route.md`, `.planning/todos/completed/2026-11-16-expert-chat-row-opens-client-booking-screen.md` (FOUND).
- Commits `f8bfa3e`, `491b600`, `472cb2a` are ancestors of HEAD (FOUND).
- Acceptance: Task 2 four automated checks PASS, Task 3 automated check PASS, 07-08 Task 1 `<automated>` commands all exit 0 at `491b600`.

---
*Phase: 07-chat*
*Completed: 2026-11-18*
