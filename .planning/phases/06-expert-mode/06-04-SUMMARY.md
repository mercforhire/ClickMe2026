---
phase: 06-expert-mode
plan: 04
subsystem: ui
tags: [swift, swiftui, eventkit, calendar, booking-confirmed, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "06-03 Availability fixes (different folder, untouched here)"
provides:
  - "ExpertBookingConfirmationContent: calendarTitle, calendarNotes, meetingTypeLabel/Icon, durationText, bodySentence, confirmation(...)"
  - "BookingConfirmation reshaped to client-side content; BookingConfirmedView.init(booking:onBackToHome:)"
  - "CalendarEventEditorSheet(booking:onDismiss:) with internal makeEvent(booking:in:)"
affects: [06-05 hosts BookingConfirmedView after Accept and calls ExpertBookingConfirmationContent.confirmation, 06-10 device UAT checklist (D5 calendar half, E7)]

actuals:
  tokens: 3700
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Pure plain-enum content builder in Utils/ feeds a display model; views render its strings verbatim"
    - "EKEvent built by an internal static function so a unit test can assert its fields without calendar permission"

key-files:
  created:
    - ClickMe2026/Utils/ExpertBookingConfirmationContent.swift
    - ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/BookingConfirmedHeadline.swift
    - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/BookingConfirmedCard.swift
    - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift

key-decisions:
  - "BookingCalendarPayload now lives inside BookingConfirmation (calendarPayload), so the view and sheet take one value; its separate sample and init parameter are removed"
  - "A nil client image URL becomes an empty string in the display model; URL(string: \"\") is nil, so AsyncImage shows the unchanged person placeholder"
  - "The Face-to-Face preview was replaced by a Long names preview (LT2); expert sessions are always In-App Voice or Skype/Zoom"

patterns-established:
  - "ExpertBookingConfirmationContent is the single place that decides the calendar title, notes and Confirmed copy"

requirements-completed: []
# EXP-10 and EXP-09 left pending: requirements.ready-ids reports both blocked by plan 06-10.

coverage:
  - id: D1
    description: "Calendar title is exactly ClickMe · {topic} with {client name} (U+00B7), trimmed, with Session and Client fallbacks, emoji and long topics unchanged"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#titleExact"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#titleFallbacks"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#titleKeepsInput"
        status: pass
    human_judgment: false
  - id: D2
    description: "Notes are the meeting type plus a new line and the trimmed client message only when not blank; the EKEvent has the booking's window, no location and one 15-minute alert"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#notesWithMessage"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#event"
        status: pass
    human_judgment: false
  - id: D3
    description: "Confirmed body sentence, date and time through DateUtil, duration and meeting-type row come from client content"
    requirement: EXP-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#body"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#confirmationFields"
        status: pass
    human_judgment: false
  - id: D4
    description: "Add to Calendar opens the system editor pre-filled as above on a real iPhone; with calendar access denied the system editor shows its own message and the app adds none; long names wrap on the card"
    requirement: EXP-10
    verification: []
    human_judgment: true
    rationale: "EKEventEditViewController and the calendar permission UI run out of process (device checks D5 calendar half and E7, written by plan 06-10)"

plan_head_before: 8b8386d3f6f2adb49005ca5d7b954935f9129190
plan_head_after: 35ffff40cdfd39e0dc9b2c94ddb3355cf3f09f7a

duration: 25min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 04: Booking Confirmed and calendar event for the expert Summary

**The orphaned Booking Confirmed screen now shows the client side of an accepted request, and Add to Calendar builds `ClickMe · {topic} with {client name}` with the meeting type and client message as notes, no location and the 15-minute alert, through a pure `ExpertBookingConfirmationContent` builder that plan 06-05 calls on accept.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-16
- **Tasks:** 2
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments
- `ExpertBookingConfirmationContent` (plain enum): title with the `\u{00B7}` middle dot, notes rule, `Client` and `Session` fallbacks, meeting-type label and icon, `{n} min` duration, the body sentence, and `confirmation(...)` which formats date with `DateUtil.string(... .shortMonthDayYear)` and time with `DateUtil.shortTime`.
- `BookingConfirmation` now holds `clientName`, `clientImageURL`, `topic`, `date`, `time`, `duration`, `meetingTypeLabel`, `meetingTypeIcon`, `calendarTitle`, `calendarNotes` and `calendarPayload`; the expert-side fields are gone. The entry animation, layout, fonts and colours are unchanged.
- Headline body uses `bodySentence` with `fixedSize(horizontal: false, vertical: true)`; the card shows client name, topic, client photo (person placeholder when missing), `{date}, {time} ({n} min)` and the meeting row; name and topic wrap without a line limit.
- `CalendarEventEditorSheet.makeEvent(booking:in:)` is internal and sets only title, start, end, notes and the 15-minute alarm; the location assignment is removed.
- `ExpertBookingConfirmationContentTests`: 12 tests, all pass, including an `EKEvent` check that runs in the test host.

## Task Commits

1. **Task 1: Tracer, Booking Confirmed and its calendar event show the client** - `77204c6` (fix)
2. **Task 2: Tests pin the exact title, notes, fallbacks, body sentence and event fields** - `35ffff4` (test)

## Verification
- Task 1 grep gate: no `expertName` or `meetingNote` left outside comments in the Confirmed folder, no `event.location`, the `EKAlarm(relativeOffset: -15 * 60)` kept, middle-dot escape and `confirmation(` present, no `DateFormatter()` in the builder: pass.
- Build gate before and after: BUILD SUCCEEDED; the warning baseline for the five app files was empty and stayed empty.
- `xcodebuild test -only-testing:ClickMe2026Tests/ExpertBookingConfirmationContentTests`: "Test run with 12 tests in 1 suite passed". EventKit logged `defaultTimedAlarmOffset ... Access denied` noise in the simulator; no assertion depends on it.
- Tracer gate: the tracer's `<verify>` is automated-only and passed at Task 1, so execution continued to Task 2 without a checkpoint.

## Deviations from Plan

None - plan executed exactly as written.

## TDD note

Task 2 carries `tdd="true"`, but the plan puts the implementation in Task 1 (the tracer, whose five files must change together to compile), so there was no separate RED commit: the suite was written against the existing builder and passed on its first run. The plan's structure, not an executor choice, set this order; no TDD Gate Compliance claim is made for this plan (its frontmatter `type` is `execute`).

## Known Stubs

None. `BookingConfirmation.sample` and the `Long names` preview are canned preview data, used only by the default init and the canvas; plan 06-05 supplies real values.

## Threat Flags

None. The client's message reaches only the notes of the system calendar editor on the expert's own device (T-06-06, accepted); nothing is sent, logged or stored by the app.

## Issues Encountered

None.

## Next Phase Readiness

Ready for 06-05: call `ExpertBookingConfirmationContent.confirmation(clientName:clientImageURL:topic:start:end:meetingType:clientMessage:)` with the accepted `BookingRequestDetail` values and host `BookingConfirmedView(booking:onBackToHome:)`. `BookingCalendarPayload`'s doc comment still describes it as separate from `BookingConfirmation`; it is outside this plan's file list and can be tidied later. Device checks D5 (calendar half) and E7 remain for plan 06-10's checklist.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ExpertBookingConfirmationContent.swift
- FOUND: ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift
- FOUND: 77204c6, 35ffff4 (ancestors of HEAD)
- Acceptance greps: `Booking Confirmed!` 1, `runEntryAnimation` 1, `Session with Client` in tests >= 1
