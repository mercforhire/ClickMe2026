---
phase: 06-expert-mode
plan: 12
subsystem: expert-mode-topics
tags: [swiftui, topics-tab, money, currency, gap-closure, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "ExpertTopicItem.storedCurrency and TopicEditorViewModel.resolveInitialCurrency (plan 06-11)"
  - phase: 02-client-booking
    provides: "Money.format and Money.prefix (BOOK-10)"
provides:
  - "TopicsSetupTopicCard.priceLabel(for:defaultCurrency:), the card's price text to the cent"
  - "TopicsSetupTopicCard.cardSymbol(for:) (US$ for USD, the Money prefix otherwise)"
  - "TopicEditorViewModel.newTopicDefaultCurrency(in:), shared by the editor and the card"
affects: [06-16]

actuals:
  tokens: 5500
  tasks: 2
  commits: 3
plan_head_before: aabeb9dee2505ac952e8671a8d0af466fcc45ef4
plan_head_after: 9f3aa2b05cbcdf51cbcc0eb95d37d43aac9fec66

tech-stack:
  added: []
  patterns:
    - "The card never re-implements currency rules: it calls the editor's resolveInitialCurrency with the editor's newTopicDefaultCurrency, so card and editor cannot disagree"

key-files:
  created:
    - ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
    - .planning/todos/pending/2026-11-16-usd-symbol-us-dollar-prefix.md

key-decisions:
  - "USD keeps the US$ symbol on the card (what the server label showed, and what the editor shows); only the cents are added. How USD renders app-wide stays the open todo"
  - "A paid topic with no valid stored currency is priced in the editor's default, never the trimmed server label; the label is used only when the amount is missing or negative"
  - "The editor's inline new-topic default moved into a static (no behavior change) so the card reads the same rule"

requirements-completed: [EXP-02]

coverage:
  - id: D1
    description: "A paid topic card reads the price to the cent with the per-session suffix (CA$50.00 / session, CA$12.50 / session, US$5.00 / session); a free topic reads Free"
    requirement: EXP-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift#a paid CAD topic reads CA$50.00 / session"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift#a paid USD topic keeps the US$ symbol and adds the cents"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift#a free topic reads Free"
        status: pass
    human_judgment: false
  - id: D2
    description: "A paid topic with a blank or null currency reads in the same currency on its card as in its editor"
    requirement: EXP-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift#card and editor agree on a paid topic that carries no currency"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift#a paid topic with a null currency decodes and is formatted in the editor's default"
        status: pass
    human_judgment: false
  - id: D3
    description: "Missing or negative amounts keep the server label; the editor's behavior is unchanged by the moved default"
    requirement: EXP-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift#a negative amount keeps the server label"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift"
        status: pass
    human_judgment: false
  - id: D4
    description: "On a real iPhone the Topics tab cards read CA$50.00 / session, CA$12.50 / session, US$5.00 / session and Free, with each editor's price label showing the same symbol as its card"
    verification: []
    human_judgment: true
    rationale: "Device rendering against the live backend; covered by checklist re-check R1 written by plan 06-16"

duration: 6min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 12: Topic card price to the cent Summary

**The Topics tab card now formats each topic's stored minor amount through `Money` in the currency its editor opens it in, so `CA$50 / session` reads `CA$50.00 / session`, USD keeps its `US$` symbol, free topics read `Free`, and the server label is used only when no usable amount exists.**

## Performance

- **Duration:** about 6 min
- **Started:** 2026-11-17T05:18Z
- **Completed:** 2026-11-17T05:23Z
- **Tasks:** 2
- **Files modified:** 4 (one created)

## Accomplishments
- `TopicsSetupTopicCard.priceLabel(for:defaultCurrency:)`: free reads `Free`; otherwise the amount (hourly rate first, then `price.amount`) is formatted with `Money` digits, the card symbol and ` / session`. The currency comes from `TopicEditorViewModel.resolveInitialCurrency`, so the card re-implements no stored-code, validation or default rule.
- `cardSymbol(for:)` keeps `US$` for USD and takes the `Money` prefix otherwise (`CA$` for CAD). Tied to the open USD-symbol todo.
- `TopicEditorViewModel.newTopicDefaultCurrency(in:)`: the editor's inline new-topic default moved into a static that `init` now calls (no behavior change; `TopicCurrencyTests` and `TopicsSetupMutationTests` still pass).
- `TopicsSetupTopicCardLabelTests`: 14 rows in the real wire shape (CAD, USD, free, blank and null currency, lowercase code, hourly rate, missing and negative amounts, and a card-editor agreement row).
- USD-symbol todo now names the card, the `US$12.50 / session` card bullet and the Android locale fact.

## Task Commits

1. **Task 1: Tracer, the Topics tab card reads CA$50.00 / session** - `8929f34` (fix)
2. **Task 2: fallbacks and tolerance rows** - `983c1bc` (test)
3. **Task 2: USD-symbol todo covers the card** - `9f3aa2b` (docs)

**Plan metadata:** the docs commit that carries this file.

## Files Created/Modified
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift` - `priceLabel(for:defaultCurrency:)`, `cardSymbol(for:)`, `perSessionSuffix`
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift` - `newTopicDefaultCurrency(in:)`
- `ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift` - card label table
- `.planning/todos/pending/2026-11-16-usd-symbol-us-dollar-prefix.md` - names the card

## Decisions Made
- USD keeps `US$` on the card; no symbol changes without the USD decision.
- A blank or null currency on a paid topic is priced in the editor's default (CAD in production and the test host).

## Deviations from Plan

None - plan executed exactly as written.

## Android read-only check

Android HEAD `69c4e159` (the plan recorded `da498620` when it was written). `TopicCard.kt` builds the price with `TopicPrice.resolveCurrency(item.storedCurrency, null)` and `PriceDisplay.of(...)`; `PriceDisplay.kt` formats through `Money.format`, and `Money.kt` sets `minimumFractionDigits = digits`. The Android card never reads `price.label`, so it already shows two decimals and needs no mirror. Its symbol comes from `NumberFormat.getCurrencyInstance(locale)`, so Android's USD symbol follows the device region (recorded in the USD todo). No Android edit or commit; the Android topics and util folders are clean.

## Issues Encountered

None. `git.allow_default_branch_commits` is `true`, and HEAD is on `main`.

## Verification

- Task 1 run (`TopicsSetupTopicCardLabelTests`, `TopicCurrencyTests`, `TopicsSetupMutationTests`): 39 tests in 3 suites passed.
- Task 2 run (`TopicsSetupTopicCardLabelTests`, `TopicCurrencyTests`): 41 tests in 2 suites passed.
- Debug build succeeded; the warning baseline for the card and editor files was empty before and after.
- All grep gates of both tasks passed. Only these suites were run; the UI tests and the three excluded network suites were not run, as the plan specifies.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. T-06-19 is mitigated as planned: integer-minor-unit formatting through `Money`, a fixed symbol rule, and the editor's resolved currency.

## Next Phase Readiness
- Device re-check (checklist R1) is owned by plan 06-16.
- Android needs no change. The USD symbol decision remains open in the todo.

## Self-Check: PASSED

- Created and modified files exist; commits `8929f34`, `983c1bc`, `9f3aa2b` are ancestors of HEAD (3 commits measured since `aabeb9d`).

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
