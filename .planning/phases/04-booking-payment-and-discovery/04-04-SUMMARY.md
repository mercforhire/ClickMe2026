---
phase: 04-booking-payment-and-discovery
plan: 04
subsystem: ui
tags: [swiftui, availability, date-formatting, locale, reload-generation, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "ReloadGeneration stale-response token"
provides:
  - "Month-race guard on Make a Booking availability loads (BOOK-02)"
  - "DateUtil.shortTime, zoneName and normalizedZoneName (device 12/24-hour style, readable zone name)"
  - "Slot chips, Reschedule picker, Today's Sessions and Request Sent times that follow the device 12/24-hour setting"
  - "Device-zone name label on the slots card and on Today's Sessions"
affects: [04-08, 04-13]

actuals:
  tokens: 7100
  tasks: 3
  commits: 3
plan_head_before: c987e233a58b97e45ad846c0fcdfd949a94dbed1
plan_head_after: 88f77ab1ad07767baf9271c94f05664b7db94ec8

tech-stack:
  added: []
  patterns:
    - "Formatter cache key includes the locale's resolved hour pattern so a 12/24-hour toggle builds a new formatter"
    - "Static formatting seams take explicit timeZone and locale defaults so tests pin both"

key-files:
  created:
    - ClickMe2026Tests/Booking/MakeABookingAvailabilityTests.swift
    - ClickMe2026Tests/Utils/SlotTimeFormatTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Utils/DateUtil.swift
    - ClickMe2026/Model/UIModels/BookingTimeSlot.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift

key-decisions:
  - "A cancelled load that is still the newest leaves availabilityState at .loading (skeleton) rather than .failed; the next appear or month change reloads it"
  - "The Today's Sessions zone label sits at the section title (one label per section), as the slots card has one at its header"
  - "The date part of the Request Sent strings stays a fixed English pattern, moved into the DateUtil.Format catalog (shortMonthDay, shortMonthDayYear)"

patterns-established:
  - "DateUtil.shortTime(_:timeZone:locale:) is the one place a time of day is formatted for display in the booking flow"

requirements-completed: [BOOK-02, BOOK-03, BOOK-04]

coverage:
  - id: A1
    description: "A month change never shows the previous month's availability; an older load landing last writes nothing; cancellation is not a failure; a current 500 still shows the server message"
    requirement: BOOK-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/MakeABookingAvailabilityTests.swift (5 tests)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift (regression)"
        status: pass
    human_judgment: false
  - id: A2
    description: "Short time follows 12/24-hour locale styles with exact scalars; zone name is readable and nil-safe; slot, Today's Sessions and Request Sent strings use the shared helper"
    requirement: BOOK-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/SlotTimeFormatTests.swift (10 tests)"
        status: pass
    human_judgment: false
  - id: A3
    description: "Live 12/24-hour toggle, zone label wrapping at the largest Dynamic Type, failed-month and empty-day copy after the change (UAT T1-T4, D-18)"
    requirement: BOOK-03
    verification:
      - kind: other
        ref: "grep gates: DateUtil.zoneName() in the slots card and Today's Sessions; Text(tz) x0; fixed 12-hour pattern x0 in BookingTimeSlot, Explore and Request Sent"
        status: pass
    human_judgment: true
    rationale: "A runtime settings toggle, Dynamic Type wrapping and the on-screen zone wording need a real iPhone (UAT T1-T4, D-18); logged in WINDOWS.md as an unrun-verify entry"

duration: 8min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 04: Month-Race Guard, Device Time Style and Zone Names Summary

**Make a Booking availability loads are token-guarded per month, and slot chips, the Reschedule picker, Today's Sessions and Request Sent now follow the device 12/24-hour setting through `DateUtil.shortTime`, with the device zone named in words on the slots card and Today's Sessions.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-11-12T04:47:42Z
- **Completed:** 2026-11-12T04:55Z
- **Tasks:** 3
- **Files modified:** 9 (2 created, 7 modified)

## Accomplishments

- `loadAvailability(for:)` takes a `ReloadGeneration` token first, re-checks it after each of its three awaits, and also requires the loaded month to still be the displayed month before writing `availabilityByDate`, `expertTimezone` and `.loaded`. Month navigation cancels the stored task. URLError.cancelled and CancellationError never produce `.failed` (BOOK-02).
- `DateUtil.shortTime` caches a short-style formatter under zone, locale and the locale's hour pattern, so toggling 24-Hour Time builds a fresh formatter. `zoneName` returns the generic localized name (for example "Eastern Time") and `normalizedZoneName` drops nil, empty and whitespace names (BOOK-03, BOOK-04).
- The slots card header shows the device zone name instead of the expert's IANA id and wraps rather than truncating; Today's Sessions shows the same label beside its title (K2, D-18).
- `BookingTimeSlot.displayLabel`, `ExploreClientViewModel.timeRangeString` and both Request Sent strings use the shared helper; no call site builds its own time formatter any more (K3).

## Task Commits

1. **Task 1: Tracer, a month change never shows the previous month's availability** - `685fd77` (fix)
2. **Task 2: Slot chips follow 12/24-hour; zone label in words** - `0bba6ad` (fix)
3. **Task 3: Today's Sessions and Request Sent follow 12/24-hour; Today's Sessions names the zone** - `88f77ab` (fix)

**Plan metadata:** committed with this summary (docs).

## Files Created/Modified

- `MakeABookingViewModel.swift` - `availabilityGate`, `availabilityTask`, token checks, `isCancellation`
- `MakeABookingAvailabilityTests.swift` - month race, older-load-lands-last, other-month, cancelled and 500 cases
- `DateUtil.swift` - `shortTime`, `zoneName`, `normalizedZoneName`, `Format.shortMonthDay`, `Format.shortMonthDayYear`
- `BookingTimeSlot.swift` - `displayLabel` is the shared short time
- `MakeABookingTimeSlotsCard.swift` - device-zone label replaces the IANA label
- `ExploreClientViewModel.swift` - `timeRangeString(from:to:timeZone:locale:)` is internal and uses the helper
- `ExploreTodaysSessionsSection.swift` - title row with the device-zone label
- `BookingRequestSentViewModel.swift` - `whenLabel` and `dateTimeString` are internal static and use the helper
- `SlotTimeFormatTests.swift` - 10 tests, explicit locales, U+202F compared as a scalar

## Decisions Made

- Followed the plan. A cancelled load that is still current leaves `.loading` (the skeleton row), which the card already renders for `.idle` and `.loading`; the next appear or month change reloads it.
- `expertTimezone` stays decoded and published on the view model but is no longer shown (K2). Its doc comment still says "Rendered under the calendar"; that wording is stale and I left it because the plan lists no edit to that comment (a one-line follow-up).

## Deviations from Plan

None - plan executed exactly as written.

### Tracer gate handled without a mid-flight stop

The tracer's `<verify>` carries only `<automated>` checks, so under `human_verify_mode: end-of-phase` there is no checkpoint. I re-ran the tracer verify (MakeABookingAvailabilityTests, BookingErrorCopyParityTests and the grep gates, all passing), logged the tracer as verified end-to-end and continued to Task 2.

## Issues Encountered

None. The warning baseline for the seven app files was empty, and the post-change build and test builds showed no warnings in them.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths or schema changes. T-04-12 (stale month response) is mitigated by the token and month check, with the server still rejecting an unavailable slot with SLOT_UNAVAILABLE. T-04-13 (zone label mismatch) is mitigated: both labels come from `DateUtil.zoneName()`, the zone `DateFormatter` formats in; the IANA id and expert zone are never shown.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Android follow-up

None logged for BOOK-02 to BOOK-04 (not in CONTEXT's Android list).

## Next Phase Readiness

- Device checks (UAT BOOK-03, BOOK-04, D-18, T1-T4) are pending for the end-of-phase session and recorded as an `unrun-verify` entry in `.planning/WINDOWS.md`.
- Plans 04-08 and 04-13 also edit `MakeABookingViewModel.swift`; this plan touched only the availability section and the month navigation methods.

## Self-Check: PASSED

- Created files exist: MakeABookingAvailabilityTests.swift, SlotTimeFormatTests.swift.
- Commits `685fd77`, `0bba6ad`, `88f77ab` are on `main`; `git rev-list --count c987e23..HEAD` was 3 at the last task commit.
- Acceptance criteria re-run: `availabilityGate = ReloadGeneration()` x1, `availabilityGate.isCurrent` x4, `availabilityTask?.cancel()` x2, `static func shortTime` x1, `static func zoneName` x1, `202F` x2, `case shortMonthDay ` x1, `DateUtil.zoneName()` in Today's Sessions x1, `Text(session.timeRange)` x1, `Text(tz)` x0, `h:mm a` x0 in the three changed app files.
- Plan verification: MakeABookingAvailabilityTests (5), BookingErrorCopyParityTests and SlotTimeFormatTests (10) pass with non-zero counts; build succeeded with no new warnings in the seven app files.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
