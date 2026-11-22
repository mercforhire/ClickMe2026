---
phase: 08-release
plan: "10"
subsystem: money-formatting
tags: [ios, swiftui, money, currency, tdd]
status: complete

requires:
  - phase: 08
    provides: "08-03 Android US$/CA$ symbol override (D-24, D-32), Android commit 50626142"
provides:
  - "iOS Money renders USD as US$ (CAD stays CA$) on every surface"
  - "Topics card and topic editor read the symbol from Money; TopicsSetupTopicCard.cardSymbol(for:) removed"
  - "D-24 todo closed"
affects: [ios-release]

actuals:
  tokens: 3000
  tasks: 3
  commits: 3

plan_head_before: 28118e18e16f92b6017149272d45f7168d977767
plan_head_after: 5e7bd610cbaf3d75b0543ac932a8bbf1e8cbeb04
commits: 3

tech-stack:
  added: []
  patterns:
    - "One symbol table (Money.symbols) drives every price label; the editor keeps the bare ISO code for codes outside USD and CAD because Money.prefix appends a no-break space"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/Money.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
    - ClickMe2026Tests/Utils/MoneyTests.swift
    - ClickMe2026Tests/Utils/MoneyCallSiteTests.swift
    - ClickMe2026Tests/Model/TopicCurrencyTests.swift
    - ClickMe2026Tests/Utils/ClientProfileBookingCardTests.swift
    - ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift
    - .planning/todos/completed/2026-11-16-usd-symbol-us-dollar-prefix.md

key-decisions:
  - "D-24: USD is US$ everywhere on iOS, matching docs/ios/USD-TOPIC-PRICING.md section 0 item 5, the server labels and the Android override from 08-03"
  - "TopicEditorViewModel.currencySymbol keeps `default: return currency` (bare ISO code); USD and CAD go through Money.prefix"

patterns-established: []

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Money.format renders 1250 USD as US$12.50, 0 USD as US$0.00, lowercase usd as US$12.50, major 75.5 USD as US$75.50; CAD, EUR, JPY and unknown codes unchanged"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/MoneyTests.swift, MoneyCallSiteTests.swift"
        status: pass
    human_judgment: false
  - id: D2
    description: "Card and editor take their symbol from Money; editor shows US$, CA$ and bare EUR; no cardSymbol reference remains"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#editorSymbolFollowsMoney, ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full iOS unit run passes and the Debug build has no warning naming a touched app file"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "xcodebuild test -only-testing:ClickMe2026Tests: 1272 tests in 118 suites passed; xcodebuild build: BUILD SUCCEEDED"
        status: pass
    human_judgment: false
---

# Phase 8 Plan 10: US$ for USD Summary

**iOS Money now writes USD as `US$` (CAD stays `CA$`), and the Topics card and editor label read that symbol from Money instead of keeping their own copy.**

## Task Commits

1. **Task 1 (tracer): Money table and call-site tests** - `ce7e4cf` (fix): `fix(08-10): USD renders as US$ (D-24)`; Money.swift, MoneyTests.swift, MoneyCallSiteTests.swift
2. **Task 2: Topics card and editor read Money** - `93941bf` (refactor): removes `cardSymbol(for:)`; editor `currencySymbol` returns `Money.prefix` for USD and CAD; adds one editor-symbol test
3. **Task 3: Remaining USD pins, todo closed** - `5e7bd61` (test): two test files plus the todo moved to completed/ with a Resolution

## Changed test rows

MoneyTests.swift (all USD rows; CAD, EUR, JPY and other rows untouched):
- minor table: 1250 and 1200 USD, 0, 1, 5, 99, 100, 123_456_789 USD; -1250 USD (`-US$12.50`); lowercase `usd` 1250
- Int.max and Int.min USD (`US$92233720368547758.07`, `-US$92233720368547758.08`)
- 1_200_000 USD (`US$12000.00`)
- `Money.prefix(for: "USD")` now `US$`
- major table: 75.5, 75.0, 0.125 (`US$0.13`), -0.125 (`-US$0.13`)
- BookingTopic price label: 1250 and 1200 USD

MoneyCallSiteTests.swift: `currencyLabel` 1250 and 12000 USD; `formatEarnings` 75.0 and 75.5; `formatCurrency` 75.5; `formatMinorUnits` 1250.

ClientProfileBookingCardTests.swift: `amountLabel` 75.0 USD (`US$75.00`).
ClientProfileHistoryEarningsTests.swift: `amountLabel` USD 42.50 (`US$42.50`).

Not changed: `TopicsSetupTopicCardLabelTests.swift` (already pinned `US$`, output is the same), `ExpertProfileSectionsTests.swift` (no USD Money pin; the full run passes unchanged). Added in `TopicCurrencyTests.swift`: `editorSymbolFollowsMoney` (USD and CAD equal `Money.prefix`, EUR is the bare `EUR`).

## Verification

- Task 1 run: 26 tests in 2 suites passed. Task 2 run: 45 tests in 2 suites passed.
- Full `-only-testing:ClickMe2026Tests` run: 1272 tests in 118 suites passed, no flake rerun needed.
- Debug build: BUILD SUCCEEDED; the only warning is the AppIntents metadata note, none on Money.swift, TopicsSetupTopicCard.swift or TopicEditorViewModel.swift.
- `git grep cardSymbol` over app and tests is empty.

## Deviations from Plan

None. The plan listed ExpertProfileSectionsTests.swift and TopicsSetupTopicCardLabelTests.swift as possibly changing; neither needed an edit. Commit trailer names Sonnet 5.5, the model that ran, per the session attribution rule.

## Notes

- Amounts, rounding, digits and the (absent) thousands separator are untouched; only the USD table entry changed (prohibition honored).
- Android: symbol override already shipped in 08-03 (`50626142`, D-32); full Android layout parity remains a logged follow-up. No backend change.
- Working tree unrelated changes (.DS_Store files, config.json, Localizable.xcstrings, milestone.lock, state.json) were left unstaged. Localizable.xcstrings was not touched by this plan.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Commits `ce7e4cf`, `93941bf`, `5e7bd61` are ancestors of HEAD; `git rev-list --count 28118e1..HEAD` was 3 before this SUMMARY.
- Todo exists at `.planning/todos/completed/2026-11-16-usd-symbol-us-dollar-prefix.md`; pending copy is gone.
