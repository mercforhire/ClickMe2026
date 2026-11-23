---
phase: 03-booked-sessions-and-joining
plan: 18
subsystem: ui
tags: [swiftui, booking-summary, price-display, localization, swift-testing]
gap_closure: true
gap_ids: [G-03-1-ITEM14]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: Booking Summary screen, ClientBookingDetail.Topic, Money.format(minorUnits:currency:)
provides:
  - BookingSummaryPrice display enum (free, paid, unknown) with make, text and label
  - Booking Summary price row that always shows once the detail has loaded
  - Four price-row unit tests and a Free Session preview
  - Device check item 27 and two 03-VALIDATION rows
affects: [08-19 Phase 3 verification regeneration, 08-20 release-candidate cut (commits Localizable.xcstrings), 08-24 gap-count gate]

actuals:
  tokens: 2200
  tasks: 2
  commits: 2

plan_head_before: 8eebccfd55f22f82025160c85cbbc941852d80e2
plan_head_after: 5347b0ab32435322ef0191917485648df3fa4cd2
commits: 2

tech-stack:
  added: []
  patterns:
    - "Pure display enum next to the screen (nonisolated enum, Equatable) with a factory from server fields, so label and value are unit-testable"
    - "First String(localized:, comment:) literals in the app, so display strings can be asserted in tests"

key-files:
  created:
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
    - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
    - .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md
    - .planning/phases/03-booked-sessions-and-joining/03-VALIDATION.md

key-decisions:
  - "User decision 2026-11-22 (verbatim choice: \"Session fee\" for free sessions only): a free row reads Session fee · Free; paid and dash rows keep PAID"
  - "Claude's discretion: a paid topic with no amount or currency shows PAID · — (dash), matching Upcoming details and Android PriceDisplay.Unknown, instead of hiding the row"
  - "Claude's discretion: Session fee is shown in sentence case in the PAID caption's font, color and tracking (not uppercased), as on Android"
  - "is_free true wins even when a price is present (Android PriceDisplay.of rule)"

patterns-established:
  - "Price display: BookingSummaryPrice.make(isFree:amount:currency:) is the only place that turns topic price fields into row text"

requirements-completed: [BOOK-20]

coverage:
  - id: D1
    description: "A free session's Booking Summary shows the price row as Session fee · Free (Free in brand green); is_free true wins over a price"
    requirement: BOOK-20
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#freeSessionShowsFree"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#freeFlagWinsOverPrice"
        status: pass
    human_judgment: true
    rationale: "Label, value and brand-green color are asserted for the label and value text only; how the row looks on a real iPhone is device check item 27"
  - id: D2
    description: "A paid session's row is unchanged: PAID with the Money amount, cents kept"
    requirement: BOOK-20
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#paidSessionShowsAmount"
        status: pass
    human_judgment: true
    rationale: "Unchanged look on a real iPhone is checked in device check item 27 step 2"
  - id: D3
    description: "A paid topic with no price reads PAID with a dash; no amount is invented"
    requirement: BOOK-20
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#paidWithoutPriceShowsDash"
        status: pass
    human_judgment: false
  - id: D4
    description: "Free, Session fee and PAID are extracted as localizable strings (BookingSummaryPrice.stringsdata lists all three)"
    verification:
      - kind: other
        ref: "stringsdata extraction check from 03-18-PLAN Task 1 verify (exit 0)"
        status: pass
    human_judgment: true
    rationale: "The keys reach Localizable.xcstrings only on an Xcode IDE build; confirmed in device check item 27"

duration: 5min
completed: 2026-11-22
status: complete
---

# Phase 3 Plan 18: Booking Summary free price row Summary

**Booking Summary now always shows its price row once loaded: a free session reads "Session fee · Free" (Free in brand green), a paid session still reads "PAID · CA$45.50" with cents kept, and a paid topic with no price reads "PAID · —".**

## Performance

- **Duration:** about 5 min
- **Started:** 2026-11-23T04:07:42Z
- **Completed:** 2026-11-23T04:13Z
- **Tasks:** 2
- **Files modified:** 7 (1 created)

## Accomplishments
- Closed G-03-1-ITEM14: the card no longer drops the price row for a free session, matching Android's Booking Summary.
- New `BookingSummaryPrice` enum (`free`, `paid(String)`, `unknown`) with `make(isFree:amount:currency:)`, `text` and `label`; the view model's old private `formatPrice` is gone and `price` is set through the factory.
- Four Swift Testing rows pin both the label and the value for free, free-wins-over-price, paid and missing-price cases. The full unit suite passes (1296 tests in 119 suites) and the build has no new warnings in the four touched files (baseline 0, after 0).
- Device check item 27 and two 03-VALIDATION rows record the on-device check.

## Task Commits

1. **Task 1: Tracer, Session fee · Free price row end to end** - `330afcc` (fix)
2. **Task 2: Device check item 27 and validation rows** - `5347b0a` (docs)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift` - price row display enum, factory, value text and label
- `.../BookingSummaryViewModel.swift` - `pricePaid: String?` replaced by `price: BookingSummaryPrice?`; `apply(detail:)` uses the factory; `formatPrice` removed
- `.../Subviews/BookingSummaryExpertCard.swift` - row renders for every non-nil price; label from `price.label`, value from `price.text`, brand green when free
- `.../BookingSummaryView.swift` - passes `price: viewModel.price`; new "Session Summary — Free Session" preview
- `ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift` - Price row section with four tests
- `03-DEVICE-UAT-CHECKLIST.md`, `03-VALIDATION.md` - item 27 (pending) and validation rows

## Decisions Made
- The Session fee label on free rows is the user's decision of 2026-11-22 (verbatim choice: "Session fee" for free sessions only). PAID stays on paid and dash rows.
- Discretion: a missing price shows PAID · — (two existing conventions agree: Upcoming details and Android). Session fee is shown in sentence case in the PAID caption style.
- `Localizable.xcstrings` was not edited or staged. The Free and Session fee keys arrive on the next Xcode IDE build and are committed by plan 08-20. The build's `BookingSummaryPrice.stringsdata` lists Free, Session fee and PAID.
- `03-UAT.md` was not edited, because verify-work reconciles the gap from this plan's `gap_ids` and SUMMARY.

## Deviations from Plan

None to the code. Two process notes:

- **Tracer gate.** Task 1's `<verify>` carries a `<human-check>` (device item 27), which under `human_verify_mode: end-of-phase` would normally stop for a checkpoint before expansion. That check cannot be run until Task 2 writes item 27 and a device build exists, and Task 2 is documentation only. The automated half of the verify (suite, grep gate, extraction check, build, warning diff) was run end to end and passed, so execution continued and the human check stays pending under item 27 for the end-of-phase harvest.
- Task 2's checklist and validation edits were applied with one scripted exact-string replace (each anchor asserted to occur once) instead of individual Edit calls. The diff is exactly the inserted item 27, the Sign-off line and the two table rows.

**Total deviations:** 0 auto-fixed. **Impact on plan:** none.

## Issues Encountered
None.

## Known Stubs
None. The `.unknown` dash is an intentional display for a paid topic with no price, not a stub.

## Threat Flags
None. T-03-32 is mitigated: Free and Session fee come only from `topic.is_free` true, amounts only from `topic.price` through `Money.format`, and a missing price shows a dash. Pinned by the four new tests.

## User Setup Required
None - no external service configuration required.

## Cross-plan notes
- **08-24 Task 1** counts resolved gaps matching `^G-03-1-ITEM1` and expects 3. Once G-03-1-ITEM14 is reconciled as resolved the count is 4, so 08-24's pattern must match ITEM1, ITEM1B and ITEM1C exactly before 08-24 runs.
- This plan changes iOS code, so it must land before 08-19 (Phase 3 verification regeneration) and 08-20 (release-candidate cut, which also commits the catalog).

## Next Phase Readiness
- Device check item 27 is PENDING in `03-DEVICE-UAT-CHECKLIST.md` and needs a build at or after `330afcc`, built from Xcode (which also adds the two catalog keys).
- No backend or Android change.

## Self-Check: PASSED

- Created file exists: `BookingSummaryPrice.swift` (FOUND).
- Commits `330afcc` and `5347b0a` are ancestors of HEAD (FOUND).
- Task 1 commit lists exactly the five task files; `Localizable.xcstrings` not included.
- Task 1 and Task 2 verify gates, build, warning diff and the full unit suite all passed.

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-22*
