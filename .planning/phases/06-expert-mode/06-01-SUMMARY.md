---
phase: 06-expert-mode
plan: 01
subsystem: ui
tags: [swift, swiftui, money, topic-editor, decimal-parsing, swift-testing]

requires:
  - phase: 02-money-and-booking-flow
    provides: "Money.fractionDigits / Money.format, editableAmount seed, D-19 untouched-save rule"
provides:
  - "TopicPriceRules: pure filterInput, parseMinor and isBelowFloor keyed on Money.fractionDigits"
  - "Topic editor price field accepts cents (12.50 / 12,50) and saves the exact minor amount in the topic's own currency"
  - "One decimal parse for the live minimum hint and Save"
  - "Tests pinning currency switching, comma decimals, untouched seeds and the 20-digit paste"
affects: [06-10 device UAT checklist (D3, LT3), 06-09 Android topic price parity]

actuals:
  tokens: 6100
  tasks: 2
  commits: 3  # measured base..HEAD; 2 are this plan's, 1 is c283a6e (docs 06-09, the parallel Android plan) landing in the same window

tech-stack:
  added: []
  patterns:
    - "Money-affecting text parsed by integer arithmetic over ASCII digits, never Double / Decimal(string:) / Int*100"
    - "Input filtering through a custom Binding set closure into a view-model method; no onChange observer on the currency"

key-files:
  created:
    - ClickMe2026/Utils/TopicPriceRules.swift
    - ClickMe2026Tests/Utils/TopicPriceRulesTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift
    - ClickMe2026Tests/Utils/MoneyCallSiteTests.swift
    - ClickMe2026Tests/Model/TopicCurrencyTests.swift

key-decisions:
  - "Comma is read as a decimal point (Android parity); the filter keeps whichever single separator the keyboard typed"
  - "Integer digits capped at 7 so minor units stay far inside the server INTEGER max; a longer paste is truncated by the filter and rejected by the parser, never trapping"
  - "No observer on currency: switching currency never rewrites the price text (D-03), the floor hint and Save re-read the new currency's floor"

patterns-established:
  - "TopicPriceRules (nonisolated enum) is the single source for price text rules; the hint and Save call the same functions"

requirements-completed: [EXP-02, EXP-03, EXP-17]

coverage:
  - id: D1
    description: "A typed 12.50 or 12,50 saves as 1250 minor units in the topic's own currency; 130.50 on a USD topic saves 13050 USD"
    requirement: EXP-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicPriceRulesTests.swift#parsesValidPrices"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/MoneyCallSiteTests.swift#typedDecimalSavesTheCents"
        status: pass
    human_judgment: false
  - id: D2
    description: "Input filter keeps at most 7 integer digits and the currency's fraction digits; parser rejects 3 decimals and a 20-digit paste without trapping"
    requirement: EXP-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicPriceRulesTests.swift#filtersTypedInput"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicPriceRulesTests.swift#longPasteDoesNotTrap"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#longPasteInEditor"
        status: pass
    human_judgment: false
  - id: D3
    description: "The live minimum hint and Save share one floor rule: 4.99 against a CA$5.00 floor is flagged, 5 and 5.00 pass, blank and 0 are free"
    requirement: EXP-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicPriceRulesTests.swift#liveFloorCheck"
        status: pass
    human_judgment: false
  - id: D4
    description: "Switching currency keeps the typed text; untouched seeds (1250 and 1200) and the paid-topic currency lock behave as shipped in 73e729e"
    requirement: EXP-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#currencySwitchKeepsTypedText"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#untouchedSeedsRoundTrip"
        status: pass
    human_judgment: false
  - id: D5
    description: "The price keyboard shows the decimal key for CAD and USD, and typing 12,50 under Region Canada (French) works; lock caption, USD notice and hint wrap at the largest Dynamic Type size"
    requirement: EXP-17
    verification: []
    human_judgment: true
    rationale: "Keyboard layout, locale separator and Dynamic Type wrapping need a real iPhone (device checks D3 and LT3, written by plan 06-10)"

plan_head_before: 0c53474d6ba837cf77efcad700489fdb3726272a
plan_head_after: f82d0f4

duration: 7min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 01: Decimal topic prices in the topic's own currency Summary

**TopicPriceRules (integer-only filter, parser and floor check keyed on Money.fractionDigits) so an expert can type 12.50 or 12,50 and Save sends exactly 1250 in the topic's currency, with the live minimum hint on the same parse.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-16T17:52:18Z
- **Completed:** 2026-11-16T17:58:30Z
- **Tasks:** 2
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments
- New `TopicPriceRules` helper: `filterInput` (digits, one separator, 7 integer digits, currency fraction digits), `parseMinor` (loop-built integer arithmetic, nil on anything unrepresentable, cannot trap), `isBelowFloor` (minor and typed-text overloads).
- `TopicEditorViewModel.validate()` and `isRateBelowMinimum` both go through the shared parser and floor rule; the old `Int(...) * 100` parse (the WR-03 crash path) is gone. The untouched-save branch (D-19) is unchanged.
- `TopicEditorView` price field uses a filtered binding (`updateRate(_:)`) and `.decimalPad` while the currency has fraction digits, `.numberPad` for zero-decimal currencies. The currency picker, lock caption, USD notice and hint layout are untouched.
- The Phase 2 test that asserted decimals are rejected is replaced by `typedDecimalSavesTheCents`; new `TopicPriceRulesTests` suite and a `TopicCurrencyTests` section pin currency switching, comma decimals, untouched seeds and the long paste. EXP-03 and the iOS half of EXP-17 (shipped in 73e729e) are preserved and covered by the existing rows plus the new ones.

## Task Commits

1. **Task 1: Tracer, typed 12.50 saves as 1250 in the topic's own currency** - `2406dc1` (feat)
2. **Task 2: Live minimum hint uses the same parse; currency switch keeps the typed number** - `f82d0f4` (feat)

**Plan metadata:** committed with this SUMMARY (docs).

_Note: the plan prescribes one commit per task, so the TDD red/green steps were not split into separate `test(...)` commits._

## Files Created/Modified
- `ClickMe2026/Utils/TopicPriceRules.swift` - pure filter, parser and floor check
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift` - `updateRate(_:)`, validate and live hint on the shared rules, doc comments updated
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift` - filtered price binding and decimal keyboard
- `ClickMe2026Tests/Utils/TopicPriceRulesTests.swift` - parser, filter and floor tables
- `ClickMe2026Tests/Utils/MoneyCallSiteTests.swift` - decimal-rejected row replaced
- `ClickMe2026Tests/Model/TopicCurrencyTests.swift` - decimal and currency-switch rows

## Decisions Made
- Comma reads as a decimal point, keeping whichever single separator the keyboard typed (Android parity).
- Currency switching never touches the price text; no `onChange` observer was added (D-03, Pitfall 3).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `isRateBelowMinimum` migrated in Task 1 instead of Task 2**
- **Found during:** Task 1
- **Issue:** Task 1's grep gate requires zero `rateMajor` / `Int(trimmed` lines in the view model, but the plan left `isRateBelowMinimum` (which held both) for Task 2.
- **Fix:** Moved `isRateBelowMinimum` onto `TopicPriceRules.parseMinor` in Task 1 (inline), then onto `isBelowFloor(rateText:...)` in Task 2 as planned. The `isBelowFloor` helper and its tests were added in Task 2 only.
- **Files modified:** TopicEditorViewModel.swift
- **Verification:** both tasks' gates pass
- **Committed in:** 2406dc1, f82d0f4

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Ordering only; end state is exactly as planned.

## Issues Encountered
- Commit count: `git rev-list --count` over the plan window is 3, not 2, because plan 06-09's `c283a6e` (docs, Android plan) landed between this plan's two commits. Only `2406dc1` and `f82d0f4` belong to this plan.
- The test host has no `/me`, so the floor interplay with `validate()` is covered through `TopicPriceRules.isBelowFloor` rather than a view-model row.

## Verification Results
- `TopicPriceRulesTests`, `MoneyCallSiteTests`, `TopicCurrencyTests`: 42 tests in 3 suites passed (Task 1 run: 20 tests in 2 suites).
- Build: BUILD SUCCEEDED; warning baseline for the three app files was empty and stays empty (0 new warnings).
- Change-gate greps and acceptance criteria all pass; no Double/Float/Decimal in non-comment lines of the helper.

## Known Stubs
None.

## Threat Flags
None. Mitigations T-06-01 (7-digit cap, no-trap parser, 20-digit rows) and T-06-02 (one exact parser, D-19 untouched path, currency lock kept) are implemented.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Device checks D3 (decimal key, 12,50 under Region Canada French) and LT3 (Dynamic Type) remain for the 06-10 UAT checklist.
- Ready for 06-02.

## Self-Check: PASSED
- FOUND: ClickMe2026/Utils/TopicPriceRules.swift, ClickMe2026Tests/Utils/TopicPriceRulesTests.swift
- FOUND commits: 2406dc1, f82d0f4

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
