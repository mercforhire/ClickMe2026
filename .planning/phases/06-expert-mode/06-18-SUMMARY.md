---
phase: 06-expert-mode
plan: 18
subsystem: expert-mode-booking-summary
tags: [swiftui, eventkit, calendar, gap-closure, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "BookingCalendarPayload and CalendarEventEditorSheet(event:onDismiss:) (plan 06-13, EXP-10, D-13)"
provides:
  - "BookingCalendarEventContent: title, notes, expertEvent, clientEvent, offeredStatuses, isOffered, fallbacks"
  - "Booking Confirmed and the expert Booking Summary build the calendar event through one builder"
  - "ExpertBookingSummaryViewModel.calendarEvent and showsAddToCalendar(at:)"
  - "A status-gated Add to Calendar button on the expert Booking Summary with its own sheet presenter"
affects: [06-14, 06-16]

actuals:
  tokens: 5000
  tasks: 2
  commits: 2
plan_head_before: 673ca87886374a39ec043bc27bb0e9a31f85c64a
plan_head_after: 83181abf2bcd8327253e1bf12b3a669fd09ac92f

tech-stack:
  added: []
  patterns:
    - "One side-agnostic builder (title, notes) with expert and client wrappers; one offer rule shared by every Add to Calendar surface"
    - "A second sheet gets its own presenter on the content router, leaving the body chain's cancellation sheet untouched"

key-files:
  created:
    - ClickMe2026/Utils/BookingCalendarEventContent.swift
    - ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift
  modified:
    - ClickMe2026/Utils/ExpertBookingConfirmationContent.swift
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift

key-decisions:
  - "The calendar sheet is presented from the content router inside the body's ZStack, not from the body modifier chain, so it never shares a presenter with the cancellation sheet; ExpertBookingSummaryView.swift only gained lines (0 removed lines against base 673ca87)"
  - "The offer rule is BookingCalendarEventContent.isOffered: confirmed, pending_reschedule or in_progress with the end strictly after now, re-evaluated by a 60 s timeline; plan 06-14 reuses it and clientEvent on the client Upcoming Booking screen"

requirements-completed: [EXP-10]

coverage:
  - id: D1
    description: "The expert Booking Summary event equals the Booking Confirmed event for the same booking (title, notes, start, end)"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift#the expert event equals the Booking Confirmed event for the same inputs"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift#the summary view model builds the Booking Confirmed event and gates it on status and end"
        status: pass
    human_judgment: false
  - id: D2
    description: "Add to Calendar is offered only for confirmed, pending_reschedule and in_progress bookings before the scheduled end"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift#offered for the three booked statuses while the end is after now"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift#never offered for any other status, even before the end"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift#not offered at or after the end, or when the end is unknown"
        status: pass
    human_judgment: false
  - id: D3
    description: "The shared builder carries the client wording (Session and Expert fallbacks) for plan 06-14"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift#the client event reads the expert's name, with Expert and Session fallbacks"
        status: pass
    human_judgment: false
  - id: D4
    description: "On a real iPhone the summary offers Add to Calendar, the New Event sheet matches Booking Confirmed, and the Confirm Cancellation sheet still opens and closes with Keep Booking before and after it"
    verification: []
    human_judgment: true
    rationale: "EventKit's system sheet, sheet presentation order and the real booking list need a device; checklist re-check R4 written by plan 06-16"

duration: 9min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 18: Add to Calendar on the expert Booking Summary Summary

**A shared `BookingCalendarEventContent` builder and offer rule now feed both Booking Confirmed and a status-gated Add to Calendar button on the expert Booking Summary, with the calendar sheet on its own presenter beside the unchanged Cancel sheet.**

## Performance

- **Duration:** about 9 min
- **Tasks:** 2
- **Files:** 2 created, 3 modified

## Accomplishments
- `BookingCalendarEventContent` builds the title (`ClickMe · {topic} with {name}`, U+00B7), the notes (meeting type, then the trimmed message on a new line when not blank), `expertEvent` and `clientEvent`, and holds `offeredStatuses` and `isOffered(status:end:now:)`.
- `ExpertBookingConfirmationContent` delegates its fallbacks, `calendarTitle`, `calendarNotes` and the confirmation's `calendarPayload` to the shared builder; its signatures are unchanged and `ExpertBookingConfirmationContentTests` and `RequestDecisionAcceptTests` pass untouched.
- `ExpertBookingSummaryViewModel.calendarEvent` and `showsAddToCalendar(at:)` read the loaded detail through the shared builder and rule.
- `ExpertBookingSummaryView` shows Add to Calendar (icon `calendar.badge.plus`, existing `Add to Calendar` key) directly after the Join and Message section, on a 60 s `TimelineView`. The tap captures the event in `pendingCalendarEvent`, which presents `CalendarEventEditorSheet(event:onDismiss:)`.
- The calendar `.sheet` sits on the line right after the bare `content` line in the body's ZStack, a different view from the body chain that presents the cancellation sheet. The summary view only gained lines.
- `BookingCalendarEventContentTests` (22 tests across the new suite and `ExpertBookingConfirmationContentTests`): Booking Confirmed parity, the summary view model, wording, and the status and time tables.

## Task Commits

1. **Task 1: Tracer, the expert Booking Summary offers Add to Calendar beside an unchanged Cancel sheet** - `2e74ebd` (feat)
2. **Task 2: The shared builder carries the client wording** - `83181ab` (feat)

**Plan metadata:** the docs commit that carries this file. Plan base (`/tmp/06-18-base.txt`): `673ca87886374a39ec043bc27bb0e9a31f85c64a`.

## Where the calendar sheet is attached

`ExpertBookingSummaryView.body`: inside `ZStack { Brand.surface...; content .sheet(isPresented: Binding(get/set on pendingCalendarEvent)) { CalendarEventEditorSheet(event:) ... } }`. The cancellation sheet stays on the body modifier chain after `.task`, byte-identical.

## Decisions Made
- A `Binding` over `pendingCalendarEvent != nil` drives the sheet because `BookingCalendarPayload` is not `Identifiable`; its setter clears the event on interactive dismissal, and the editor's `onDismiss` clears it after the system sheet closes.
- Tracer gate: the task's `<verify>` carries a device human-check, deferred to checklist re-check R4 (plan 06-16) under `human_verify_mode: end-of-phase`; the automated verify was re-run end to end after the commit's code was final and passed, so expansion was not blocked.

## Deviations from Plan

None - plan executed exactly as written.

(One test-file compile error during Task 2, main-actor-isolated static arrays used as `@Test(arguments:)`, was fixed in the same task by marking them `nonisolated`; it never reached a commit.)

## Issues Encountered

None. HEAD is on `main` with `git.allow_default_branch_commits` true. `ClickMe2026/Localizable.xcstrings`, `.planning/config.json`, `.planning/state.json`, `.planning/milestone.lock` and the `.DS_Store` files were already modified or untracked and were never staged.

## Verification

- Task 1: `BookingCalendarEventContentTests`, `ExpertBookingConfirmationContentTests` and `RequestDecisionAcceptTests`: 27 tests in 3 suites passed. Task 2: 22 tests in 2 suites passed.
- Debug build succeeded after each task; the warning baseline for the four app files was empty before and after (`comm -13` empty).
- All grep gates passed, including: no removed line in `ExpertBookingSummaryView.swift` since the base, no added line naming the cancellation sheet's Bool, exactly one `.sheet(` directly after the bare `content` line, and exactly one `.sheet(isPresented: $showCancellationSheet)`.
- Only the named suites were run, as the plan specifies; the UI tests and the three excluded network suites were not run.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. T-06-20 (accepted) and T-06-29 (mitigated: the offer rule rows, the separate presenter, and the no-removed-lines check) hold as planned; no new endpoint, auth path or schema change.

## Next Phase Readiness
- Plan 06-14 can call `BookingCalendarEventContent.clientEvent(...)` and `isOffered(...)` on the client Upcoming Booking screen.
- Device re-check R4 (both sheets, past booking shows no button) is owned by plan 06-16. A `pending_reschedule` booking offers the button with its current time; an event added before a reschedule is accepted keeps the old time (no EventKit sync).

## Self-Check: PASSED

- All five files exist; commits `2e74ebd` and `83181ab` are ancestors of HEAD (2 commits measured since `673ca87`).

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
