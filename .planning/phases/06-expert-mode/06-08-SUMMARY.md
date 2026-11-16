---
phase: 06-expert-mode
plan: 08
subsystem: ui
tags: [swiftui, booking-id, earnings, currency, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: plan 06-07 (tree baseline for the warning compare)
  - phase: 02-shared-ios-plumbing
    provides: plan 02-15 Client Profile history earnings mapping (Money.format in booking currency)
provides:
  - "Expert Booking Summary shows ID: #XXXXXXXX as the last line of the client header, via ExpertBookingSummaryViewModel.bookingIdLabel"
  - "Mixed CAD/USD Client Profile history rows pinned by a test (each own currency, dash for cancelled)"
  - "Read-only confirmation that Android expert summary uses the same short-ID rule"
affects: [06-10 device UAT checklist, EXP-14 and EXP-18 verification]

actuals:
  tokens: 2500
  tasks: 2
  commits: 2
plan_head_before: 932d39c92367aac9f35105c96158bf324f10b98c
plan_head_after: e27793d72c82452cd818144776605a1ba9cd138c

tech-stack:
  added: []
  patterns:
    - "One short-ID rule (BookingShortID.label) shared by client and expert Booking Summary, built from the route's own booking id"

key-files:
  created: []
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
    - ClickMe2026Tests/Utils/BookingShortIDTests.swift
    - ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift

key-decisions:
  - "New property named bookingIdLabel (CLAUDE.md Id spelling); older client-side bookingID spellings left untouched as out of scope"
  - "EXP-14 needed no app code: history rows are the only money surface on Client Profile; 02-15 mapping is pinned by a mixed-currency test instead"
  - "No Android change: expertShortBookingId (drop hyphens, first 8, upper-case) equals iOS BookingShortID for canonical UUIDs"

requirements-completed: [EXP-18, EXP-14]

coverage:
  - id: D1
    description: "Expert Booking Summary shows ID: #XXXXXXXX under View Profile, same rule as the client screen"
    requirement: EXP-18
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingShortIDTests.swift#the expert Booking Summary label uses the same rule (EXP-18)"
        status: pass
    human_judgment: true
    rationale: "Layout (caption style, selectable, header spacing) and the cross-device match with Android need a real device (D5)"
  - id: D2
    description: "Android expert summary uses the same short-ID rule (read-only check, no Android edit)"
    requirement: EXP-18
    verification:
      - kind: other
        ref: "grep of ExpertBookingSummaryUiState.kt L112 and strings_expert_booking_summary.xml expert_summary_id; git status clean in Android repo"
        status: pass
    human_judgment: false
  - id: D3
    description: "Client Profile history rows show net earnings in each booking's own currency; cancelled row shows the dash"
    requirement: EXP-14
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift#a client with CAD and USD sessions shows each row in its own currency (EXP-14)"
        status: pass
    human_judgment: true
    rationale: "Real production bookings in two currencies are needed to confirm on device (D5, Client Profile half)"

duration: 3min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 08: Booking ID and Client Profile Currency Summary

**Expert Booking Summary now shows `ID: #A1B2C3D4` under View Profile through the shared BookingShortID rule, and mixed CAD/USD Client Profile earnings are pinned by a test.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-11-16T18:36:56Z
- **Completed:** 2026-11-16T18:39:55Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `ExpertBookingSummaryViewModel.bookingIdLabel` returns `BookingShortID.label(bookingId)`, built from the route's own id so it shows before the detail loads.
- The client header renders it as the last child of the name/View Profile stack (`.caption`, `Brand.onSurfaceVariant`, `.textSelection(.enabled)`), with that stack's spacing moved from 5 to 4.
- Android read-only check passed: `expertShortBookingId` (drop hyphens, first 8, upper-case) and `expert_summary_id` = `ID: #%1$s`; the Android working tree has no changes.
- A mixed-currency test shows `CA$75.00` for a CAD confirmed row, `$42.50` for a USD completed row and the dash for a cancelled USD row. History rows are the only money surface in Client Profile (the other money-looking values are preview fixtures), so no app code changed.

## Task Commits

1. **Task 1: Tracer, expert Booking Summary ID line** - `9e95cf3` (feat)
2. **Task 2: Mixed-currency Client Profile earnings** - `e27793d` (test)

**Plan metadata:** committed after this file (docs: complete plan)

## Files Created/Modified
- `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift` - `bookingIdLabel`
- `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift` - ID line, header spacing 4
- `ClickMe2026Tests/Utils/BookingShortIDTests.swift` - expert label row
- `ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift` - mixed-currency row

## Decisions Made
- Property is `bookingIdLabel` per the CLAUDE.md `Id` spelling; the older `bookingID` names on the client side are left as they are.
- EXP-14 closes on device check D5, not on code: the 02-15 mapping already satisfied it.

## Deviations from Plan

None - plan executed exactly as written. One process note: the Task 1 test was written together with the implementation in a single pass, so there was no separate RED run. The new symbol would have failed at compile time (not a valid RED under the TDD classifier), and the plan asks for one `feat` commit for the task.

## Verification

- `BookingShortIDTests`: 4 tests passed (new row included).
- `ClientProfileHistoryEarningsTests` + `ClientProfileBookingCardTests`: 13 tests in 2 suites passed.
- Build before and after Task 1: BUILD SUCCEEDED, zero warnings in the two Booking Summary files (baseline 0, after 0).
- Structural greps and the Android guard check passed.

## Issues Encountered
None

## Requirements

`requirements.ready-ids` reports EXP-18 and EXP-14 as blocked (sibling plan 06-10 also declares them and has no SUMMARY), so they were left pending in REQUIREMENTS.md as instructed.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Ready for 06-10 (device UAT checklist): add D5 (Client Profile half: one CAD and one USD session, a cancelled row shows the dash; Booking Summary ID matches the same booking on Android).

## Self-Check: PASSED

- Commits `9e95cf3` and `e27793d` are ancestors of HEAD.
- All four modified files exist; no Android paths touched.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
