---
phase: 06-expert-mode
plan: 13
subsystem: expert-mode-booking-confirmed
tags: [swiftui, eventkit, calendar, refactor, gap-closure, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "BookingConfirmation, CalendarEventEditorSheet and ExpertBookingConfirmationContent (plan 06-04, EXP-10, D-13)"
provides:
  - "BookingCalendarPayload(title:notes:startDate:endDate:), an Equatable plain event value"
  - "CalendarEventEditorSheet(event:onDismiss:) and static makeEvent(_:in:), no dependency on the Booking Confirmed display model"
affects: [06-18, 06-14, 06-16]

actuals:
  tokens: 4000
  tasks: 1
  commits: 1
plan_head_before: 0009220c6361422cff9b9298b373cbb256e8a7cc
plan_head_after: 9e69910

tech-stack:
  added: []
  patterns:
    - "The EventKit sheet takes a plain event value; each screen builds its own payload through a content builder"

key-files:
  created: []
  modified:
    - ClickMe2026/Model/BookingCalendarPayload.swift
    - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift
    - ClickMe2026/Utils/ExpertBookingConfirmationContent.swift
    - ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift
    - ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift

key-decisions:
  - "BookingConfirmation keeps calendarTitle and calendarNotes as computed properties over calendarPayload, so existing readers and tests compile unchanged"
  - "The sheet stays in Expert Mode/Confirmed/Subviews (no file move); the name and signature plan 06-18 builds on are CalendarEventEditorSheet(event:onDismiss:) and makeEvent(_:in:)"

requirements-completed: [EXP-10]

coverage:
  - id: D1
    description: "Booking Confirmed adds exactly the same calendar event as before (title ClickMe, U+00B7, topic, with, client; start and end; notes; no location; one -900 s alarm), now through a plain event value"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#event carries the built title, notes and window, no location, one 15-minute alert"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift#the plain event value carries the built title, notes and window"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests"
        status: pass
    human_judgment: false
  - id: D2
    description: "Any screen can present the EventKit sheet from a plain event value"
    requirement: EXP-10
    verification:
      - kind: command
        ref: "grep gates: sheet stores event: BookingCalendarPayload, no BookingConfirmation dependency, no labelled makeEvent(booking:) left"
        status: pass
    human_judgment: false
  - id: D3
    description: "On a real iPhone Booking Confirmed still adds exactly the item 17 event after a free-topic accept"
    verification: []
    human_judgment: true
    rationale: "EventKit's system sheet needs a device; covered by checklist re-check R6 written by plan 06-16"

duration: 12min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 13: Calendar sheet takes a plain event value Summary

**`CalendarEventEditorSheet` now takes a plain `BookingCalendarPayload` (title, notes, start, end) instead of the Booking Confirmed display model, so any screen can present it, while Booking Confirmed still adds the identical event.**

## Performance

- **Duration:** about 12 min
- **Tasks:** 1
- **Files modified:** 5 (none created)

## Accomplishments
- `BookingCalendarPayload` is `Equatable` and carries `title`, `notes`, `startDate`, `endDate`.
- `CalendarEventEditorSheet(event:onDismiss:)` and `makeEvent(_:in:)` build the `EKEvent` from the payload alone (plus the -15 minute alarm; no location). The doc comment no longer names the Confirmed model.
- `ExpertBookingConfirmationContent.confirmation(...)` builds the payload with the same title and notes builders as before; public signatures unchanged.
- `BookingConfirmation.calendarTitle` and `calendarNotes` are now computed from the payload; `BookingConfirmedView` passes `booking.calendarPayload` to the sheet.
- Tests: the `event()` row moved to the new `makeEvent`, and a new `payloadCarriesTitleAndNotes` row pins the payload value and the computed properties (13 rows in the suite).

## Task Commits

1. **Task 1: Tracer, Booking Confirmed adds the identical event through a plain event value** - `9e69910` (refactor)

**Plan metadata:** the docs commit that carries this file.

## Files Created/Modified
- `ClickMe2026/Model/BookingCalendarPayload.swift` - title, notes, start, end; Equatable
- `ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift` - `event:` input, `makeEvent(_:in:)`
- `ClickMe2026/Utils/ExpertBookingConfirmationContent.swift` - builds the four-field payload
- `ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift` - computed title and notes; sheet gets the payload
- `ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift` - `event()` on the new builder, `payloadCarriesTitleAndNotes`

## Decisions Made
- Names for plan 06-18 are exactly as the plan stated: no rename was needed.
- Tracer gate: the task's `<verify>` is automated plus a device human-check deferred to checklist R6 (HUMAN_VERIFY_MODE end-of-phase), so the automated verify was re-run end to end and passed; expansion was not blocked.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. HEAD is on `main`, as for the earlier gap plans (`git.allow_default_branch_commits` is `true`, per the 06-12 SUMMARY). `ClickMe2026/Localizable.xcstrings` was already modified before this plan and was not staged.

## Verification

- `ExpertBookingConfirmationContentTests` and `RequestDecisionAcceptTests`: 24 tests in 2 suites passed.
- Debug build succeeded; the warning baseline for the four app files was empty before and after.
- All grep gates passed (sheet takes the payload, no `let booking:` or `makeEvent(booking:` left, Confirmed view passes its payload, no `expertName` in the Confirmed folder, at least 13 `@Test` rows).
- No Booking Summary file and no `BookingCalendarEventContent.swift` was touched (plan 06-18). Only the two named suites were run; the UI tests and the three excluded network suites were not run, as the plan specifies.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. T-06-21 is mitigated as planned: the sheet sets only the payload's plain strings on the `EKEvent` title and notes, never a URL or location, and the two event rows pin the exact output.

## Next Phase Readiness
- Plan 06-18 can build the shared builder and the Booking Summary button on `BookingCalendarPayload` and `CalendarEventEditorSheet(event:onDismiss:)`.
- Device re-check R6 is owned by plan 06-16.

## Self-Check: PASSED

- All five modified files exist; commit `9e69910` is an ancestor of HEAD (1 commit measured since `0009220`).

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
