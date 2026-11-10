---
phase: 02-shared-ios-plumbing
plan: 06
subsystem: ui
tags: [swiftui, money, currency, formatting, topic-editor, swift-testing, tdd]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "Plan 02-05 Money formatter (format(minorUnits:currency:), format(major:currency:), fractionDigits(for:))"
provides:
  - "Eight expert money sites format through Money: expert dashboard balances, Payouts balances, incoming-request earnings, upcoming-session net earnings, request-decision breakdown, Topics tab cards, topic editor min-price hint, Payouts earnings rows"
  - "TopicEditorViewModel.editableAmount(minorUnits:currency:) lossless price seed with the topic currency's digit count (D-11)"
  - "TopicEditorViewModel.validate() passes an untouched price through as the stored minor amount and stored currency (D-19)"
  - "MoneyCallSiteTests: 13 rows pinning the unit each expert site passes and the topic-editor round trips"
  - "App-wide gate: zero NumberFormatter currency sites remain in the app target"
affects: [02-12 device UAT checklist, 02-15 expert Client Profile history card, 06 topic editor input (EXP-02, EXP-03, EXP-17), Android Money port]

actuals:
  tokens: 8063
  tasks: 3
  commits: 5
plan_head_before: be798685e0630d2c8c2fc223fbda86aad51462b6
plan_head_after: 91dc466302ce512779ef14603f96d137c9387be4

tech-stack:
  added: []
  patterns:
    - "Fields the server already divided into major units go through Money.format(major:) and keep their own nil guard (dash or hidden); everything else uses the minor entry point"
    - "An editable money field keeps its seed text plus the stored minor amount and stored currency, and the save path passes those through while the trimmed text still equals the seed"
    - "Swift TDD RED commits may carry a compile-only seam (access widening or a stub that mirrors current behavior) so the rows fail on assertions, not as a build failure; the evidence record says so"

key-files:
  created:
    - ClickMe2026Tests/Utils/MoneyCallSiteTests.swift
    - .planning/phases/02-shared-ios-plumbing/02-06-tdd-red-evidence-t2.json
    - .planning/phases/02-shared-ios-plumbing/02-06-tdd-red-evidence-t3.json
  modified:
    - "ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Payouts/PayoutsViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/IncomingRequestsViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionEarningsSection.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Payouts/Subviews/EarningsTransactionRow.swift"

key-decisions:
  - "An untouched topic-editor save sends the topic's stored minor amount and stored currency unchanged (D-19); a typed price is still parsed as whole major units times 100 and saved in defaultCurrency until Phase 6 (EXP-02, EXP-03)"
  - "A whole stored amount seeds as a plain integer (12500 seeds 125, not 125.00) so the Phase 2 whole-number parser still accepts an edit of it; a seed with cents (125.50) is recognized by validate() and passed through"
  - "A topic that carries no currency at all saves untouched in defaultCurrency, which is the currency the backend assumes for it"
  - "BOOK-10 expert device check deferred by the user (approve and defer at the tracer gate); PENDING for plan 02-12"

patterns-established:
  - "Major-unit server fields: Money.format(major:) ?? dash, guard for nil amount or currency untouched"
  - "Lossless editable seed: digits from Money.fractionDigits, no symbol, no grouping, integer arithmetic, total over negatives"

requirements-completed: [BOOK-10]

coverage:
  - id: D1
    description: "Expert dashboard and Payouts balances show full minor digits with fixed symbols (1250 USD is $12.50, 1200 CAD is CA$12.00, 5000 JPY is ¥5000)"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/MoneyCallSiteTests.swift#expert dashboard earnings and payout labels keep their cents; #payouts balances keep their cents and use fixed symbols"
        status: pass
    human_judgment: false
  - id: D2
    description: "Major-unit earnings fields (incoming request, upcoming session net, request-decision breakdown) go through Money.format(major:) so 75.0 USD shows $75.00, never $75 or $0.75; nil keeps the dash and NaN hides the amount"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "MoneyCallSiteTests.swift#incoming request earnings keep their cents and keep the dash for missing values; #upcoming session net earnings use the major entry point and hide a bad value"
        status: pass
      - kind: other
        ref: "grep gate: Money.format(major present in all three files; numberStyle = .currency count 0 in each (baseline 1)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Topic cards, the topic editor min-price hint and Payouts earnings rows go through Money.format(minorUnits:)"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "MoneyCallSiteTests.swift#earnings transaction rows keep their cents and honor zero-decimal currencies"
        status: pass
      - kind: other
        ref: "app-wide gate: grep -rn 'numberStyle = .currency' ClickMe2026 --include=*.swift | wc -l = 0 (baseline at plan start 8, at phase start 13)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Opening an existing topic seeds the price field losslessly (12550 USD seeds 125.50, 12500 seeds 125, 1200 JPY seeds 1200) and saving without touching the price sends the stored minor amount and stored currency (12550 USD stays 12550 USD on a CAD-default account); typed prices still parse as whole numbers in defaultCurrency and decimals are rejected"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "MoneyCallSiteTests.swift#the editable price seed keeps cents and uses the currency's digit count; #an untouched 12550 USD topic saves its stored amount and stored currency; #a whole-dollar hourly rate seeds as a plain integer and saves unchanged; #a topic with only a price falls back to the price amount and currency; #a topic with no stored currency saves untouched in the default currency; #a typed whole number is still parsed and priced in the default currency; #typed decimal input is still rejected until Phase 6; #a new topic seeds an empty price and parses a typed whole number"
        status: pass
      - kind: other
        ref: "grep gates on TopicEditorViewModel.swift: String($0 / 100) 0, Money.fractionDigits 1, seededRateMinor 4, seededRateCurrency 3, Int(trimmedRate) 1"
        status: pass
    human_judgment: false
  - id: D5
    description: "An expert sees the right text on a real iPhone: Dashboard This Week earnings and available payout, Payouts balances and earnings rows, Topics cards, incoming request earnings, request-decision breakdown and Upcoming Bookings earnings all read CA$x.xx; a 12.50 topic opened and saved with only the title changed still shows CA$12.50"
    requirement: BOOK-10
    verification:
      - kind: manual_procedural
        ref: "Device UAT BOOK-10 expert side (DEFERRED, not yet run; WINDOWS.md unrun-verify entry for 02-06)"
        status: unknown
    human_judgment: true
    rationale: "Visual price text on a real device; the user chose 'approve and defer' at the Task 1 tracer gate, so the device check goes to the Phase 2 UAT checklist (plan 02-12)"

duration: ~30min
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 06: Expert money sites and lossless topic price (BOOK-10) Summary

**Every expert-side price and earnings figure now renders through `Money` (full cents, fixed `$`/`CA$` symbols, backend zero-decimal set), the four major-unit fields use the major entry point so `75.0` is `$75.00` and never `$0.75`, and the topic editor seeds a stored price to the cent and sends an untouched price back with its stored amount and currency instead of rewriting `12.50` to `12.00` or re-pricing a USD topic in CAD (D-19).**

## Performance

- **Duration:** about 30 min wall clock (Task 1 in the earlier run, including the tracer-gate pause; Tasks 2 and 3 plus wrap-up in this continuation, started 2026-11-10T05:35Z)
- **Started:** 2026-11-10T05:24Z (warning baseline captured by the Task 1 run)
- **Completed:** 2026-11-10T05:56Z
- **Tasks:** 3 of 3
- **Files modified:** 11 (8 app files, 1 new test file, 2 RED evidence records)

## Accomplishments

- Experts no longer see `US$75`, `JP¥1,200` or `CA$12` from `NumberFormatter`: the dashboard and Payouts balances, Payouts earnings rows, Topics tab cards and the topic editor's min-price hint all go through `Money.format(minorUnits:currency:)`; incoming-request earnings, the Upcoming Bookings card's net earnings and every line of the request-decision breakdown go through `Money.format(major:currency:)` because the server already divided those fields (Pitfall 5). Each site keeps its own nil guard: the dash for a missing amount or currency, hidden on the Upcoming card.
- App-wide gate: `grep -rn 'numberStyle = .currency' ClickMe2026 --include=*.swift` counts 0 lines (13 at phase start, 8 after plan 02-05). No `NumberFormatter` currency formatting is left in the app target.
- Topic editor (D-11 as amended by D-19): `editableAmount(minorUnits:currency:)` seeds the price field with the stored amount and the topic currency's digit count from `Money.fractionDigits` (`12550` USD seeds `"125.50"`, `12500` seeds `"125"`, `1205` CAD seeds `"12.05"`, `1200` JPY seeds `"1200"`). `validate()` compares the trimmed text with the seed; while they match it sends `seededRateMinor` and `seededRateCurrency ?? defaultCurrency`, so an open-and-save of a 12.50 topic writes 12550 (not 12500) and a USD topic on a CAD-default account stays USD. A typed price takes the unchanged branch: whole numbers only, times 100, `defaultCurrency`; `"130.50"` is still rejected.
- Round-trip rows recorded as the plan asked: 12550 USD on a CAD default -> `rate == "125.50"`, `hourlyRateAmount == 12550`, `currency == "USD"`, also with `" 125.50 "`; `"130"` -> 13000 in `vm.defaultCurrency`; `"130.50"` -> nil; 12500 USD -> `"125"` and 12500 USD; price-only 12550 CAD -> 12550 CAD; price-only 12550 with no currency -> 12550 in `vm.defaultCurrency`; new topic -> `""` and `"150"` -> 15000.
- Plan 02-15 converts the last display site, `ClientProfileBookingCard` (expert Client Profile history card).

## Task Commits

1. **Task 1: Tracer, expert dashboard and Payouts balances use Money** - `bb16d32` (fix) [earlier run]
2. **Task 2: Major-unit earnings sites use Money.format(major:)** - RED `182ef12` (test), GREEN `cd2786e` (fix)
3. **Task 3: Topic cards, topic editor (preview, lossless seed, untouched save) and earnings rows; app-wide gate** - RED `92de390` (test), GREEN `91dc466` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

Measured: `git rev-list --count be79868..HEAD` = 5 (plan ledger `.git/gsd-plan-head-before-02-06`).

## TDD Gate Compliance

The plan is `type: execute` with `tdd="true"` on Tasks 2 and 3, so no plan-level TDD gate applies; each task still ran RED then GREEN with classified evidence. GREEN commits use `fix(02-06)` per the orchestrator's instruction for this continuation (a bug-fix project), not the `feat(...)` form in the TDD reference.

- **Task 2 RED** (`182ef12`): `02-06-tdd-red-evidence-t2.json`, `RED_EVIDENCE_OK` (reason `target_test_failed`; 4 tests, 2 pass, 2 fail). Target "incoming request earnings keep their cents and keep the dash for missing values" failed on `"US$75"` and `"US$75.50"` vs `$75.00`/`$75.50`; the Upcoming row failed on `"US$75.50"` and `"NaN"` vs nil. Semantic assessment: both targets executed and failed on the planned assertions; no build, load or fixture failure; the nil-guard rows pass at HEAD by design and are guards. The RED commit widened `IncomingRequestsViewModel.formatEarnings` and `UpcomingBookingsViewModel.formatCurrency` from private to internal static (bodies unchanged) so the rows compile; a Swift test naming a private symbol is a build failure, not a RED.
- **Task 2 GREEN** (`cd2786e`): MoneyCallSiteTests 4 tests passed (`/tmp/02-06-t2.log`).
- **Task 3 RED** (`92de390`): `02-06-tdd-red-evidence-t3.json`, `RED_EVIDENCE_OK` (reason `target_test_failed`; 13 tests, 7 pass, 6 fail). Target "an untouched 12550 USD topic saves its stored amount and stored currency" failed on `rate == "125"`, `hourlyRateAmount == 12500`, `currency == "CAD"` and nil for `" 125.50 "`. The other five failing tests failed on the lossy seed (`"12"` for 1250 USD and 1200 JPY), device-locale text (`"JP¥1,200"`, `"US$12.50"`), the 12500 USD topic re-priced in CAD, and the price-only topics seeding `"125"`. The RED commit carries `editableAmount` as a compile-only stub that mirrors the lossy `/ 100` seed. The first RED run also failed the new-topic row because the fixture had no title and `validate()` rejects an empty title before the price; the fixture was given a title and RED re-run before the record was written (the plan asks for a non-empty title).
- **Task 3 GREEN** (`91dc466`): MoneyCallSiteTests + MoneyTests, 26 tests in 2 suites passed (`/tmp/02-06-t3.log`).

## Files Created/Modified

- `ClickMe2026Tests/Utils/MoneyCallSiteTests.swift` - 13 rows: dashboard and Payouts balances, major-unit sites, earnings rows, `editableAmount` table, seven topic-editor round trips; `ExpertTopicItem` fixtures decoded from snake_case JSON
- `ExpertDashboardViewModel.swift`, `PayoutsViewModel.swift` - `currencyLabel(minorUnits:currency:)` bodies call `Money`; call sites in the views untouched (Task 1)
- `IncomingRequestsViewModel.swift` - `formatEarnings(amountMajor:currency:)` internal static, `Money.format(major:) ?? "—"`, doc no longer promises `$75`
- `UpcomingBookingsViewModel.swift` - `formatCurrency(_:code:)` internal static, `Money.format(major:)`; `formatEarnings` and its fee-source qualifiers unchanged
- `RequestDecisionEarningsSection.swift` - `formatted(_:currencyOverride:)` keeps the nil guard and currency fallback chain, `Money.format(major:) ?? "—"`; doc no longer says whole amounts render without a decimal
- `TopicsSetupTopicCard.swift` - `priceLabel` falls back to `price.label` only without `hourlyRate`, else `Money.format(minorUnits:)`
- `TopicEditorViewModel.swift` - `editableAmount`, `seededRate` / `seededRateMinor` / `seededRateCurrency`, lossless init seed, D-19 branch in `validate()`, `formatMinorUnits` via `Money`; `ValidatedTopic` docs updated; `isRateBelowMinimum`, `minPriceHint`, `defaultCurrency` untouched
- `EarningsTransactionRow.swift` - `formatMinorUnits(_:currency:)` via `Money`
- `02-06-tdd-red-evidence-t2.json`, `02-06-tdd-red-evidence-t3.json` - RED records with classifier verdict and semantic assessment

## Decisions Made

- Untouched save passes the stored amount and stored currency through; a typed price keeps today's whole-number parse in `defaultCurrency` (D-19). This is the one save-path change Phase 2 makes; decimals and a currency choice for typed prices are Phase 6 (EXP-02, EXP-03), and the Topic Editor's currency selection (EXP-17) was not touched.
- A whole stored amount seeds as a plain integer so the Phase 2 parser still accepts an edit of it; only a seed with cents depends on the pass-through.
- A topic with no stored currency takes `defaultCurrency` on an untouched save (nothing stored to keep; it is the currency the backend assumes for such a topic per `MinSessionAmount.defaultCurrency`).
- Stored currency is sent exactly as stored, with no case change.

## Plan vs Android (flagged, not changed)

Android's `TopicEditorViewModel.kt` (its D-10) keeps an existing topic's own currency on **every** save, edited price included (`currency = if (isEdit) s.currency else resolveCurrency(null, default)`), and `TopicPrice.parse`/`filterInput` accept decimal input (its test saves `TopicHourlyRateBody(1250, "USD")` for a USD topic on a CAD account after editing the icon). iOS after this plan matches Android only for the untouched save; an **edited** price on a non-default-currency topic is still saved in `defaultCurrency`, and decimal input is still rejected. The plan and D-19 assign both to Phase 6 (EXP-02, EXP-03, EXP-17), and the orchestrator's instruction for this continuation was not to change the editor's currency selection, so the gap is flagged here rather than closed. Phase 6 should match Android: keep the topic currency for edited prices and parse decimals with the currency's digit count.

Android `util/Money.kt` still differs from D-10 (device-locale symbols, ICU digits); logged in the 02-05 SUMMARY, no Android change in this plan.

## Deviations from Plan

None - plan executed exactly as written. Process notes, not deviations:

- The user chose "approve and defer" at the Task 1 tracer gate, so execution continued before the BOOK-10 expert device check was done (recorded below as PENDING).
- The Task 3 new-topic test fixture initially had no title, so `validate()` returned nil before reaching the price; the fixture was corrected (a title added) and RED re-run before the evidence was recorded. No production code was involved.
- RED commits carry test seams (access widening in Task 2, a compile-only `editableAmount` stub in Task 3) so the rows fail on assertions; the evidence records state this.

## Deferred Device Checks (PENDING, not passed)

These need a real iPhone and have NOT been run. Plan 02-12 builds `02-DEVICE-UAT-CHECKLIST.md` and must pick them up as BOOK-10 expert-side items. Phrased in CAD because the app creates topics in the account default (CAD); a USD topic exists only as legacy data:

1. **Task 1 (tracer check, deferred by user "approve and defer"):** as an expert, the Dashboard's "This Week" earnings and available payout, and the Payouts screen's available and pending balances, all show `CA$x.xx` (never `CA$12`, `$12` or `CAD 12`).
2. **Task 2 sites:** an incoming request worth 75 shows `CA$75.00`; the Upcoming Bookings card's EARNINGS value and every line of the request-decision breakdown (session price, platform fee, net) show two decimals and `CA$`.
3. **Task 3 sites:** the Topics tab cards and the Payouts earnings rows show two decimals and `CA$` (a JPY topic, if any, shows no decimals). Open a topic whose price has cents (for example 12.50 set from Android): the price field shows `12.50`; change only the title and save; the card still shows `CA$12.50`. If the account has a legacy USD topic, save it with only the title changed: the card still shows `$`, not `CA$`.

The unrun check is logged in `.planning/WINDOWS.md` (kind `unrun-verify`, phase 02, file `02-06-SUMMARY.md`).

## Issues Encountered

None. The simulator's region gives `NumberFormatter` the `US$` / `JP¥1,200` forms, which made the RED failures explicit about the device-locale symbol problem. Warning baseline was empty (`/tmp/02-06-warn-before.txt`); after the build the comparison for the eight plan files printed nothing; the only warning line in `/tmp/02-06-build.log` is the toolchain `appintentsmetadataprocessor` note.

Out of scope and left alone: `ExpertBookingSummaryViewModel.feeLabel` (server label, matches D-10), `ClientProfileBookingCard` (plan 02-15), typed-price parsing and currency in the topic editor (Phase 6).

## Known Stubs

None.

## Threat Flags

None - no new network endpoints, auth paths or schema changes. T-02-12 (each site uses the named entry point for its unit; rows pin 75.0 major as `$75.00` and 1250 minor as `$12.50`) and T-02-30 (lossless seed; untouched save returns the stored minor amount and stored currency; rows assert 12550 USD on a CAD default; grep gates that the integer-division seed is gone and the stored currency is carried) are in place.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-15 converts `ClientProfileBookingCard` with `Money.format(minorUnits:)`; after it, BOOK-10 has no declaring plan left open in this phase (REQUIREMENTS.md flips when the shared-ID gate allows).
- Plan 02-12 must include the deferred BOOK-10 client (02-05) and expert (02-06) device checks.
- Phase 6 (EXP-02, EXP-03, EXP-17): keep the topic currency for edited prices and parse decimals, matching Android; `seededRate` / `seededRateMinor` / `seededRateCurrency` and `editableAmount` are the seams to build on.

## Self-Check: PASSED

- FOUND: ClickMe2026Tests/Utils/MoneyCallSiteTests.swift, 02-06-tdd-red-evidence-t2.json, 02-06-tdd-red-evidence-t3.json
- FOUND commits bb16d32, 182ef12, cd2786e, 92de390, 91dc466 (all ancestors of HEAD); measured 5 commits since plan_head_before be79868
- Tests: MoneyCallSiteTests 4 tests passed after Task 2; MoneyCallSiteTests + MoneyTests 26 tests in 2 suites passed after Task 3; BUILD SUCCEEDED; new-warning comparison empty; app-wide `numberStyle = .currency` count 0; `Int(trimmedRate)` count 1

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
