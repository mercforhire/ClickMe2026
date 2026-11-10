---
phase: 02-shared-ios-plumbing
plan: 05
subsystem: ui
tags: [swiftui, money, currency, formatting, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "Plan 02-03 foundations (BookingSummaryViewModel as left by that plan)"
provides:
  - "Money: the one client-visible price formatter (integer minor path, backend digit set, fixed symbol table)"
  - "Seven client money sites format through Money: Make a Booking topic price, Upcoming Booking details, Booking Summary, Cancel refund preview, Explore featured topics, Expert Profile topic list, Payment History rows"
affects: [02-06 expert money sites, 02-12 device UAT checklist, 02-15 expert Client Profile history card, 03 cancel refund policy (BOOK-08), Android Money port]

actuals:
  tokens: 5682
  tasks: 3
  commits: 3
plan_head_before: 8de798ac2258be1460b6f835bd747cb2e38d98e9
plan_head_after: ddf6c4ab852985009e4e476da85da3df5b24ca68

tech-stack:
  added: []
  patterns:
    - "Display formatters are nonisolated caseless enums with integer arithmetic; the screen keeps its own Free, dash or hidden branch and only the paid branch calls the formatter"
    - "Thousands grouping is a single constant (Money.thousandsSeparator = nil) over a tested helper, so turning it on is a one-line change"

key-files:
  created:
    - ClickMe2026/Utils/Money.swift
    - ClickMe2026Tests/Utils/MoneyTests.swift
  modified:
    - ClickMe2026/Model/UIModels/BookingTopic.swift
    - "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift"
    - "ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift"
    - "ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift"
    - "ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift"
    - "ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift"
    - ClickMe2026/Model/Responses/Children/ClientTransactionItem.swift

key-decisions:
  - "Money shows full minor digits and a fixed symbol per currency (USD $, CAD CA$, AUD A$, EUR, GBP, JPY, INR; any other code, CHF included, shows the ISO code plus a non-breaking space), never the device locale"
  - "Zero-decimal currencies are exactly the backend set JPY, KRW, VND, CLP, ISK, XOF, XAF; every other code has 2 digits"
  - "No thousands separator (Open Question 1): one nil constant, helper tested with and without a separator"

requirements-completed: [BOOK-10]

coverage:
  - id: D1
    description: "Money.format(minorUnits:currency:) and format(major:currency:) give full minor digits, fixed symbols, correct negatives, and no crash at Int.min and Int.max"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/MoneyTests.swift (suite Money, 13 tests, passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "All seven client money sites go through Money; no NumberFormatter currency style or integer / 100 remains in them"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "MoneyTests + ClientHomeFeedTests (31 tests in 2 suites passed, including the Free-label cases)"
        status: pass
      - kind: other
        ref: "grep gate: 0 local formatting lines and 1 Money.format in each of the 6 converted files; BookingTopic has 0 '/ 100'; Money.swift has 0 NumberFormatter or Locale"
        status: pass
      - kind: other
        ref: "xcodebuild build Debug iPhone 17: BUILD SUCCEEDED, new-warning comparison empty"
        status: pass
    human_judgment: false
  - id: D3
    description: "A client sees the right text on a real iPhone: a CAD topic priced 12.50 shows CA$12.50 and a CAD 12.00 topic shows CA$12.00 on Make a Booking, Explore, Expert Profile, Booking details/summary/cancel and Payment History"
    requirement: BOOK-10
    verification:
      - kind: manual_procedural
        ref: "Device UAT BOOK-10 (DEFERRED, not yet run)"
        status: unknown
    human_judgment: true
    rationale: "Visual price text on a real device; user chose 'approve and defer' at the tracer gate, so the device check goes to the Phase 2 UAT checklist (plan 02-12)"

duration: 12min
completed: 2026-11-09
status: complete
---

# Phase 2 Plan 05: Client money formatter (BOOK-10) Summary

**One tested integer-math `Money` formatter (full minor digits, fixed symbols like `CA$`, backend zero-decimal set) now renders every client price: Make a Booking, booking detail, summary, cancel refund preview, Explore, Expert Profile and Payment History.**

## Performance

- **Duration:** about 12 min (Task 1 in the earlier run, Tasks 2 and 3 plus wrap-up in this continuation)
- **Started:** 2026-11-10T03:58Z (baseline capture; approximate, taken from the commit before the plan)
- **Completed:** 2026-11-10T04:10Z
- **Tasks:** 3 of 3
- **Files modified:** 9 (2 created, 7 modified)

## Accomplishments

- Clients no longer see `"USD 12"` for a 1250-cent price (integer `/ 100`) or a price missing `.00` / carrying a device-locale symbol (`US$`, or a bare `$` for CAD). `1250 USD` is `$12.50`, `1200 USD` is `$12.00`, `1250 CAD` is `CA$12.50`, `1200 JPY` is `¥1200`.
- `Money` is `nonisolated`, Foundation-only, and has no `NumberFormatter` or `Locale` (grep gate passes). Negatives put the sign before the symbol, `Int.min` and `Int.max` don't trap, `format(major:currency:)` rounds half away from zero and returns nil for non-finite or out-of-range input.
- Each converted site keeps its own Free, dash, hidden or held/captured branch; only the paid formatting lines changed.

## Task Commits

1. **Task 1: Tracer, shared formatter shown on the Make a Booking topic price** - `6fd2ce4` (fix)
2. **Task 2: Booking detail, summary and cancel screens use Money** - `3fc26e2` (fix)
3. **Task 3: Explore, Expert Profile and Payment History use Money** - `ddf6c4a` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Utils/Money.swift` - `Money.format(minorUnits:currency:)`, `format(major:currency:)`, `fractionDigits(for:)`, `prefix(for:)`, `groupWhole(_:separator:)`, `thousandsSeparator`
- `ClickMe2026Tests/Utils/MoneyTests.swift` - formatter table, boundaries, negatives, zero-decimal and unknown codes, grouping helper, BookingTopic label
- `ClickMe2026/Model/UIModels/BookingTopic.swift` - `priceLabel` paid branch calls Money
- `UpcomingBookingViewModel.swift`, `BookingSummaryViewModel.swift`, `ClientCancellationViewModel.swift` - formatting lines replaced, guards untouched
- `ExploreClientViewModel.swift`, `ExpertProfileViewModel.swift` - formatting replaced, doc examples now `$50.00`
- `ClientTransactionItem.swift` - `format(minorUnits:currency:)` keeps nil as the dash, otherwise Money; doc says digits follow the backend set, not ICU

## Decisions Made

- Fixed symbol table and backend digit set, with the ISO code plus a non-breaking space for anything else (the backend prints `CHF12.50`; iOS prints `CHF 12.50`, which D-10 allows because only USD and CAD must match the backend).
- No thousands grouping now (Open Question 1); the helper exists and is tested so it is a one-line switch later.

## Deviations from Plan

None - plan executed exactly as written. The one process variation was a human decision at the tracer gate: the user chose "approve and defer", so execution continued before the Task 1 device check was done.

No ClientHomeFeedTests expectation changed: its "a paid USD topic shows a formatted price" case only checks that the label contains "50", so `$50.00` passes unedited.

## Deferred Device Checks (PENDING, not passed)

These need a real iPhone and have NOT been run. Plan 02-12 builds `02-DEVICE-UAT-CHECKLIST.md` and must pick them up as BOOK-10 items. The app cannot create USD topics (`TopicEditorViewModel` always uses the backend default currency, CAD), so the wording is CAD:

1. **Make a Booking (Task 1 tracer check, deferred by user "approve and defer"):** a CAD topic priced 12.50 shows `CA$12.50`; a CAD 12.00 topic shows `CA$12.00` (not `CA$12` or `CAD 12`). USD `$12.50` only if a legacy USD topic exists (optional).
2. **Task 3 screens:** Explore featured topics, an expert profile's topic list and Payment History rows show two decimals and `CA$` for a CAD topic.
3. **Task 2 screens:** the booking detail fee, Booking Summary price row and Cancel refund preview (held or captured booking) show full cents and `CA$`.

The unrun check is also logged in `.planning/WINDOWS.md` (kind `unrun-verify`, phase 02).

## Android Follow-up (logged, not built)

Android `util/Money.kt` uses device-locale symbols and ICU digits (for example KWD with 3 digits), which differs from D-10 and from the backend digit set (zero-decimal JPY, KRW, VND, CLP, ISK, XOF, XAF, otherwise 2). It needs the same change as `Money` here: fixed symbol table with `CA$` for CAD, ISO code plus a non-breaking space for other codes, and the backend digit rule. No Android change was made in this plan.

## Issues Encountered

None. Warning baseline was empty (`/tmp/02-05-warn-before.txt`) and the comparison after the build printed nothing, so there are no new warnings in the plan's files.

Out of scope and left alone: the eight expert-side sites that still use `NumberFormatter` with `.currency` (`RequestDecisionEarningsSection`, `IncomingRequestsViewModel`, `UpcomingBookingsViewModel`, `ExpertDashboardViewModel`, `PayoutsViewModel`, `TopicsSetupTopicCard`, `TopicEditorViewModel`, `EarningsTransactionRow`). Plan 02-06 converts the expert sites and plan 02-15 the expert Client Profile history card; `TopicEditorViewModel` input parsing belongs to Phase 6 (EXP-02, EXP-03).

## Known Stubs

None.

## Threat Flags

None - no new network endpoints, auth paths or schema changes. Mitigations T-02-10 (integer-only minor path, tests pin cents, zero-decimal codes and boundaries) and T-02-11 (fixed symbol table, no Locale or NumberFormatter in Money, grep gate) are in place.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-06 can call `Money.format(minorUnits:currency:)` for the expert sites; `format(major:currency:)` is available for fields the server already divided.
- Plan 02-12 must include the deferred BOOK-10 device checks above.
- BOOK-10 is marked complete (client half) on the strength of the unit tests, grep gate and clean build; the device verification remains outstanding and is tracked above.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/Money.swift
- FOUND: ClickMe2026Tests/Utils/MoneyTests.swift
- FOUND commit 6fd2ce4, FOUND commit 3fc26e2, FOUND commit ddf6c4a (all ancestors of HEAD); measured 3 commits since plan_head_before
- Tests: MoneyTests 13 tests passed; MoneyTests + ClientHomeFeedTests 31 tests in 2 suites passed; BUILD SUCCEEDED; new-warning comparison empty

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-09*
