---
phase: 06-expert-mode
plan: 14
subsystem: client-upcoming-booking
tags: [swiftui, eventkit, calendar, gap-closure, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "BookingCalendarPayload and CalendarEventEditorSheet(event:onDismiss:) (plan 06-13)"
  - phase: 06-expert-mode
    provides: "BookingCalendarEventContent.clientEvent, offeredStatuses and isOffered (plan 06-18)"
provides:
  - "UpcomingBookingViewModel.calendarEvent and showsAddToCalendar(at:)"
  - "UpcomingBookingAddToCalendarButton subview in the Reschedule glass style"
  - "A status-gated Add to Calendar button and the EventKit New Event sheet on the client Upcoming Booking screen"
affects: [06-16]

actuals:
  tokens: 4000
  tasks: 2
  commits: 2
plan_head_before: ece8d8dd34625c7715dfbfa729bd216a3f94e50e
plan_head_after: 7d7bc117b44e45abf63f11bf9ed6fca7017df26d

tech-stack:
  added: []
  patterns:
    - "Client and expert Add to Calendar surfaces share one builder and one offer rule; each screen only adds its own view-model wrapper and a 60 s timeline"

key-files:
  created:
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingAddToCalendarButton.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift

key-decisions:
  - "The client calendar sheet is attached to UpcomingBookingView.body right after .task, because that screen had no sheet; the client Session Summary folder gained no calendar code"
  - "The notes carry the meeting type and the client's own note only; no join link, booking id or location is added (T-06-22 accepted)"

requirements-completed: [EXP-10]

coverage:
  - id: D1
    description: "A client on a confirmed future booking sees Add to Calendar on Upcoming Booking, and the event is titled ClickMe · {topic} with {expert name} with the booking's start and end and the meeting type as notes"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#a confirmed future booking offers Add to Calendar with the expert's name in the title"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#a blank expert name reads Expert and the client's own note follows the meeting type"
        status: pass
    human_judgment: false
  - id: D2
    description: "The button shows only for confirmed, pending_reschedule and in_progress bookings before the end; never before load, for pending_approval, terminal or unknown statuses, or at and after the end"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#no calendar button for a pending request, a finished booking or an unknown status, even before the end"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#the button goes at the scheduled end"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#before any load there is no calendar event and no button"
        status: pass
    human_judgment: false
  - id: D3
    description: "On a real iPhone the test client's Upcoming Booking for a confirmed future session offers Add to Calendar with the expert's name in the title; a pending request and the Session Summary show no button"
    verification: []
    human_judgment: true
    rationale: "EventKit's system sheet and real bookings need a device; checklist re-check R5 written by plan 06-16"

duration: 8min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 14: Add to Calendar on the client Upcoming Booking Summary

**The client Upcoming Booking screen now shows a status-gated Add to Calendar button, built on plan 06-18's shared `BookingCalendarEventContent` and plan 06-13's EventKit sheet, so a client can put a booked session on their calendar until it ends.**

## Performance

- **Duration:** about 8 min
- **Tasks:** 2
- **Files:** 1 created, 3 modified

## Accomplishments
- `UpcomingBookingViewModel.calendarEvent` builds `BookingCalendarEventContent.clientEvent` from the loaded topic, expert name, start, end, meeting type and the client's own note, and is `nil` until both times are known. `showsAddToCalendar(at:)` applies `BookingCalendarEventContent.isOffered` to the booking status and end.
- `UpcomingBookingAddToCalendarButton` is a full-width button in the Reschedule glass style (`calendar.badge.plus`, the existing `Add to Calendar` key) with a `#Preview`.
- `UpcomingBookingView` renders the button below the preparation note and above Reschedule/Cancel, only for the three booked statuses, on a 60 s `TimelineView` so it goes when the session ends. The tap captures the event in `pendingCalendarEvent`, which presents `CalendarEventEditorSheet(event:onDismiss:)` through a sheet on `body`.
- `UpcomingBookingViewModelTests` grew from 19 to 26 tests: the confirmed-future event, the pre-load state, a hidden-status table (including an unrecognized `on_hold` decoded as `.unknown`), the offered booked statuses, the end boundary, Skype/Zoom notes, and the Expert fallback with the client's note. `loadedModel` now takes a meeting type.
- The client Session Summary (`Client Mode/Booking Summary`) is untouched and has no calendar code.

## Task Commits

1. **Task 1: Tracer, Upcoming Booking offers Add to Calendar and opens the New Event sheet titled with the expert** - `2a6c578` (feat)
2. **Task 2: Upcoming Booking hides Add to Calendar where an event would be wrong, and the notes carry the client's message** - `7d7bc11` (test)

**Plan metadata:** the docs commit that carries this file. Plan base: `ece8d8dd34625c7715dfbfa729bd216a3f94e50e`.

## Decisions Made
- A `Binding` over `pendingCalendarEvent != nil` drives the sheet because `BookingCalendarPayload` is not `Identifiable`; its setter and the editor's `onDismiss` both clear the event.
- Tracer gate: the task's `<verify>` carries no blocking-human gate and `human_verify_mode` is `end-of-phase`; the automated verify (tests, grep gates, build and warning comparison) was run end to end on the final code and passed, so expansion was not blocked. The device check is deferred to checklist re-check R5 (plan 06-16).
- A `pending_reschedule` booking offers the button with its current time; an event added before the reschedule resolves keeps that time (EventKit has no sync).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. HEAD is on `main` with `git.allow_default_branch_commits` true. `ClickMe2026/Localizable.xcstrings`, `.planning/config.json`, `.planning/state.json`, `.planning/milestone.lock` and the `.DS_Store` files were already modified or untracked and were never staged.

## Verification

- Task 1: `UpcomingBookingViewModelTests` and `BookingCalendarEventContentTests`: 30 tests in 2 suites passed. Task 2: `UpcomingBookingViewModelTests`: 26 tests in 1 suite passed.
- Debug build succeeded before and after Task 1; the warning baseline for the three Upcoming Booking files was empty before and after (`comm -13` empty).
- All Task 1 and Task 2 grep gates passed, including 0 `CalendarEventEditorSheet` references in the client Booking Summary folder and Reschedule/Cancel still rendering.
- Only the named suites were run, as the plan specifies; the UI tests and the three excluded network suites were not run. No test or build failed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. T-06-22 (accepted) and T-06-23 (mitigated by the shared offer rule and the status and time rows) hold as planned; no new endpoint, auth path or schema change.

## Next Phase Readiness
- Device re-check R5 (confirmed booking offers the button with the expert's name, a pending request and a past booking's Session Summary show none) is owned by plan 06-16. Android is plan 06-15 (done); no backend change.
- Remaining in phase 06: 06-16, 06-17.

## Self-Check: PASSED

- All four files exist; commits `2a6c578` and `7d7bc11` are ancestors of HEAD (2 commits measured since `ece8d8d`).

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
