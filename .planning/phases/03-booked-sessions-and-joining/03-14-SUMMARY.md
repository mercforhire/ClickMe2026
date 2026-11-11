---
phase: 03-booked-sessions-and-joining
plan: 14
subsystem: ui
tags: [swiftui, booking-status, status-pill, booking-id, swift-testing]

requires:
  - phase: 02-client-bookings
    provides: BookingStatus decoder with the .unknown fallback (BOOK-18)
  - phase: 03-booked-sessions-and-joining
    provides: "03-01 UpcomingBookingViewModel silent refresh(), ClientBookingFixtures, UpcomingBookingViewModelTests"
provides:
  - BookingStatusPill, the exhaustive BookingStatus case to pill text and tone mapping
  - Upcoming Booking details pill that shows the booking's real status instead of a hard-coded "Confirmed"
  - BookingShortID, the one short booking ID formatter (iOS half of the BOOK-20 format; Android is 03-15)
affects: [03-07 Booking Summary ID line reuses BookingShortID, 03-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 3400   # chars/4 over the added lines of the realized diff (13,512 chars, app and test Swift only)
  tasks: 2
  commits: 2
plan_head_before: 8d5503046d84ec092f82f6bf2c5d4bd491aaf201
plan_head_after: 1891c5f6de260cf710d84499cbae8e4cbb4a3fd3

tech-stack:
  added: []
  patterns:
    - "Display mapping over a decoded enum is one exhaustive switch with no default, so a new case fails to compile until its UI is decided"
    - "The raw server string is kept only to humanize the decoder's .unknown fallback, never to decide a known case"

key-files:
  created:
    - ClickMe2026/Utils/BookingStatusPill.swift
    - ClickMe2026/Utils/BookingShortID.swift
    - ClickMe2026Tests/Utils/BookingStatusPillTests.swift
    - ClickMe2026Tests/Utils/BookingShortIDTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingStatusRow.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift

key-decisions:
  - "The pill is decided by the decoded BookingStatus case; statusRaw is read only when the case is .unknown, which is always neutral"
  - "An empty or blank raw status on .unknown reads 'Unknown' (the UI-SPEC has no row for it; planner choice kept)"
  - "Test suites for these main-actor-default value types are marked @MainActor, matching JoinWindowTests, instead of making the helpers nonisolated"

patterns-established:
  - "Tests for a status mapping carry an exhaustive switch (no default) as the expected table, so adding a BookingStatus case breaks the test target build too"

requirements-completed: [BOOK-09]

coverage:
  - id: D1
    description: "Every BookingStatus case maps to its UI-SPEC pill text and tone; a known case ignores the raw string"
    requirement: BOOK-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingStatusPillTests.swift#knownCases, knownCaseIgnoresRaw"
        status: pass
    human_judgment: false
  - id: D2
    description: "An unknown status is humanized, neutral, and never reads Confirmed or accent; empty reads Unknown"
    requirement: BOOK-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingStatusPillTests.swift#unknownIsHumanized, unknownEmptyRaw, unknownNeverConfirmed"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#unknownStatusPill"
        status: pass
    human_judgment: false
  - id: D3
    description: "The view model's pill follows a loaded detail, keeps its value across a failed silent refresh, then follows the server"
    requirement: BOOK-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#pendingReschedulePill, pillKeepsValueUntilRefetchLands"
        status: pass
    human_judgment: false
  - id: D4
    description: "BookingShortID gives '#7F3C9A2B' for the shared fixture UUID in upper and lower case, and Upcoming details uses it at both sites"
    requirement: BOOK-20
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingShortIDTests.swift (shortForm, labelForm, lowerCaseInput)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#bookingIDLabelUsesSharedFormat"
        status: pass
    human_judgment: false
  - id: D5
    description: "Pill colors, the pill and ID row combining into one VoiceOver element, and readability at the largest accessibility Dynamic Type size on a real iPhone"
    requirement: BOOK-09
    verification: []
    human_judgment: true
    rationale: "Visual tone, VoiceOver reading and Dynamic Type clipping need a device; deferred to Phase 3 UAT by the user's standing approval of 2026-11-10"

duration: 15min
completed: 2026-11-11
status: complete
---

# Phase 3 Plan 14: Upcoming details status pill and shared booking ID Summary

**The Upcoming Booking details pill now shows the booking's real status (Confirmed, In progress, Completed, Pending approval, Pending reschedule, Cancelled, Missed, Rescheduled, or a humanized unknown) through one exhaustive `BookingStatus` switch, and the ID goes through a single `BookingShortID` formatter that matches Android.**

## Performance

- **Duration:** about 15 min
- **Started:** about 2026-11-11T04:50Z; **Completed:** 2026-11-11T05:05Z
- **Tasks:** 2 of 2 (Task 1 tracer, Task 2 TDD)
- **Files:** 8 (4 created, 4 modified)

## Accomplishments

- `BookingStatusPill.make(status:rawStatus:)` is one `switch` over every `BookingStatus` case with no `default`. Confirmed, In progress and Completed are accent; Pending approval and Pending reschedule are amber; declined reads Cancelled and expired reads Missed (the `PastBookingStatus` wording), plus Rescheduled, all neutral. Only `.unknown` reads the raw string, humanized; an empty string reads "Unknown". No raw-string status table exists outside comments.
- `UpcomingBookingStatusRow` takes `pill:` and `bookingID:`, colors the dot, its glow, the text and the capsule fill and stroke by tone, keeps shape, dot size and padding, and combines into one VoiceOver element.
- `UpcomingBookingViewModel` keeps `statusRaw` (set in `apply(_:)` and the preview seed) and exposes `statusPill`. Because `refresh()` is the silent refetch from 03-01, the pill keeps its previous value until the server answer lands (D-03). Failed refresh keeps it too.
- `BookingShortID.short/label/length` replaces both inlined `prefix(8).uppercased()` expressions. The test fixture `7F3C9A2B-1D4E-4C8A-9B0F-123456789ABC` is the one Android 03-15 pins, so both platforms assert `#7F3C9A2B`.
- A "Pending reschedule pill" preview was added to `UpcomingBookingView`.

## Task Commits

1. **Task 1: Tracer, Upcoming details pill shows the real status from the shared decoder** - `97c6ba0` (fix)
2. **Task 2: One short booking ID formatter; Upcoming details uses it** - `1891c5f` (refactor)

**Plan metadata:** the docs commit that follows this file.

## Decisions Made

- Known cases ignore `rawStatus` entirely, so a raw `"garbage"` with `.confirmed` still reads Confirmed; an unknown status can never reach the accent tone.
- Test suites are `@MainActor` (as `JoinWindowTests` is) because the app target defaults to main-actor isolation, which made `BookingStatusPill` and its `Equatable` conformance main-actor isolated.
- `BookingStatusPillTests` uses an exhaustive no-default `switch` as its expected table rather than a hand-listed rows array, so adding a `BookingStatus` case breaks the test build as well as the app build.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Marked `BookingStatusPillTests` and `BookingShortIDTests` `@MainActor`**
- **Found during:** Task 1
- **Issue:** The first test build failed under Swift 6: `BookingStatusPill.make`, its `Equatable` conformance and its properties are main-actor isolated by the target's default isolation, so a nonisolated test suite could not call them.
- **Fix:** `@MainActor` on the suites, the same convention `JoinWindowTests` uses.
- **Files modified:** `ClickMe2026Tests/Utils/BookingStatusPillTests.swift` (and written that way in `BookingShortIDTests.swift`)
- **Commit:** `97c6ba0`, `1891c5f`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Test scaffolding only; no change to shipped behavior or scope.

## Issues Encountered

None. Task 2's tests were written before `BookingShortID` existed (compile-red) and the implementation followed in the same commit, since the plan specifies one commit for the task.

## Tracer gate

The tracer's `<verify>` carries automated checks and a device `<human-check>`. Under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT"), the device check is deferred and Task 2 proceeded. The automated verify (pill tests, view-model tests, the three grep gates) passed on the committed tree before Task 2 began.

## Verification

- `BookingStatusPillTests`: 5 tests in 1 suite passed (`/tmp/03-14-t1.log`).
- `UpcomingBookingViewModelTests`: 9 tests in 1 suite passed (`/tmp/03-14-t2b.log`); `ClientBookingStatusFallbackTests` (BOOK-18 regression): 5 tests passed (`/tmp/03-14-reg1.log`).
- `BookingShortIDTests`: 3 tests in 1 suite passed (`/tmp/03-14-t2.log`).
- Grep gates: no `Text("Confirmed")` left in the status row; `statusPill` used in the view; helper switches on `.pendingReschedule`; zero raw-string status literals in the helper outside comments; `statusRaw` appears 6 times in the view model; `prefix(8).uppercased()` is gone and `BookingShortID.short` is used twice.
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded. The warning baseline for the five touched app files was empty before and after, so the comparison prints nothing.

## Known Stubs

None. The preview seed's "#CM-98231" label default is a display fixture and was left as the plan says.

## Threat Flags

None. T-03-23 (a pending, cancelled or unknown booking shown as Confirmed) is mitigated: exhaustive switch, `.unknown` always neutral, a test over every case, and a gate against a raw-string table. No new network, auth or file surface.

## Requirement status

BOOK-09 is declared only by this plan and is delivered in code; marked complete in REQUIREMENTS.md, with the device check pending below. BOOK-20 is also declared by 03-07 (iOS Booking Summary), and its Android half is 03-15 (done). This plan delivers the shared iOS formatter and the Upcoming screen only, so BOOK-20 is left open for 03-07.

## Deferred device checks (Phase 3 UAT)

- **BOOK-09 (tracer `<human-check>`):** on a real iPhone, open Upcoming details for a pending-approval, a confirmed and a pending-reschedule booking, and one from the Payments list that was cancelled; each pill reads its real status. Also confirm the pill and ID row read as one VoiceOver element and stay readable at the largest accessibility Dynamic Type size (UI-SPEC L2).

## Pending device checks

- Same item as above (BOOK-09), listed here as the plan's output spec requires.

## Cross-repo and follow-ups

No backend change. No Android change in this plan (the Android ID line is 03-15, already done). The Android details pill says "New time proposed" for pending_reschedule while iOS keeps D-11's "Pending reschedule"; this is a logged copy difference, not an Android follow-up. Plan 03-07 should call `BookingShortID.short`/`label` for the Booking Summary ID line.

## Next Phase Readiness

`BookingShortID` is ready for 03-07. No blockers.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/BookingStatusPill.swift, ClickMe2026/Utils/BookingShortID.swift, ClickMe2026Tests/Utils/BookingStatusPillTests.swift, ClickMe2026Tests/Utils/BookingShortIDTests.swift
- FOUND: commits `97c6ba0` and `1891c5f` are ancestors of HEAD; `git rev-list --count 8d55030..HEAD` = 2

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
