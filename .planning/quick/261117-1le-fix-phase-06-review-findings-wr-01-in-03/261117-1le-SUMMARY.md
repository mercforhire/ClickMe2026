---
phase: quick-261117-1le
plan: 01
subsystem: expert-mode-topics
tags: [swift, topic-editor, currency, tests, review-fixes]
requires:
  - phase 06 review findings (06-REVIEW.md)
provides:
  - TopicEditorViewModel resolves its currency once for the price seed, `currency` and `defaultCurrency`
  - injectable `/me` seam (`meProvider`) on TopicEditorViewModel
  - MeDataFixtures shared test builder
affects:
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
tech-stack:
  added: []
  patterns:
    - "Optional trailing init closure `meProvider` defaults to a live read of the user manager; tests inject a fixed MeData"
key-files:
  created:
    - ClickMe2026Tests/Support/MeDataFixtures.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
    - ClickMe2026/Utils/BookingCalendarEventContent.swift
    - ClickMe2026Tests/Model/TopicCurrencyTests.swift
    - ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift
    - ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
    - .planning/phases/06-expert-mode/06-REVIEW-DISPOSITION.md
decisions:
  - "Inject /me into the view model through an optional meProvider closure, because UserManager has a private init that rewires the shared API client and realtime socket, so a test cannot build its own instance"
  - "No device UAT item: for CAD and USD, the only codes the live server allows, the old and new seed currency agree, so nothing changes on an iPhone"
status: complete
commits: 5
plan_head_before: 0ee14bf1660908dfda22611f48349ec6d3ef6a2c
plan_head_after: c0cbfff98a5e041ed55a351f9fb881dc33038abf
actuals:
  tokens: 3500
  tasks: 3
  commits: 5
metrics:
  completed: 2026-11-17
---

# Phase quick-261117-1le Plan 01: Fix phase 06 review findings WR-01, IN-03, IN-07 Summary

The topic editor now resolves one currency that drives the price seed text, the selected `currency` and `defaultCurrency`, so a topic can no longer show 12550 while saving in CAD on an account whose default is not allowed. The two tests that read the shared user manager now inject `/me`, and a stale plan number is gone from a doc comment.

## What changed

- **WR-01 (a87e963).** `TopicEditorViewModel.init` computes a local `resolvedCurrency` from `resolveInitialCurrency(topic:defaultCurrency: newTopicDefaultCurrency(in: me))` and uses it for both `editableAmount(minorUnits:currency:)` and `self.currency`. `defaultCurrency` returns `newTopicDefaultCurrency(in: currentMe)`, the same rule the Topics tab card uses. A topic with a stored currency is unchanged (D-18, D-19).
- **Seam and RED tests (4467aa6).** Optional trailing init parameter `meProvider: (@MainActor () -> MeData?)?`. The default reads `userManager.me` live. Every `/me` read in the view model (`defaultCurrency`, `allowedCurrencies`, `validate()`, `isRateBelowMinimum`, `minPriceHint`, init) goes through it. No app-target caller passes it. `MeDataFixtures` (`@MainActor`) builds a decoded `MeData`. Three rows added to `TopicCurrencyTests`.
- **IN-07 (8322e9b).** `cardAndEditorAgreeOnBlankCurrency` loops over no `/me`, a USD default and a JPY default (CAD/USD allowed), each injected, with literal expectations. `blankCurrencyFreeTopicSavesARealCurrency` injects a USD-default account and asserts literal `USD` in the editor, `validate()` and the PATCH body.
- **IN-03 (f6bbbf8).** `clientEvent` doc comment now ends "Used by the client Upcoming Booking screen." with no plan number.
- **Ledger (c0cbfff).** `06-REVIEW-DISPOSITION.md`: WR-01, IN-03, IN-07 fixed with SHAs, `open: 0`, the six deferred rows untouched.

## RED then GREEN (Task 1)

RED run (`/tmp/261117-1le-red.log`), 43 tests in 2 suites, 4 issues:

- Row A, `vm.defaultCurrency → "JPY"` expected `"CAD"`
- Row A, `vm.rate → "12550"` expected `"125.50"`
- Row A, `parseMinor(vm.rate, currency: vm.currency) → 1255000` expected `12550` (the 100x error)
- Row B, `vm.defaultCurrency → "JPY"` expected `"CAD"`
- Row C (stored USD) passed

GREEN run: `Test run with 43 tests in 2 suites passed`.

## Verification

| Gate | Result |
|------|--------|
| build-for-testing, iPhone 17, Debug | `TEST BUILD SUCCEEDED` |
| Warnings in touched or dependent files vs baseline | baseline 0, after 0; `comm -13` diff empty. Whole log: 2 warning lines before and after, both the pre-existing `appintentsmetadataprocessor` "Metadata extraction skipped" message |
| TopicCurrencyTests, MoneyCallSiteTests, TopicsSetupTopicCardLabelTests, TopicsSetupMutationTests, BookingCalendarEventContentTests | `Test run with 74 tests in 5 suites passed` (baseline 71, plus 3 WR-01 rows) |
| Task grep gates | all passed |
| Scope: `git diff --stat 0ee14bf..HEAD -- ClickMe2026 ClickMe2026Tests` | only the six Swift files in `files_modified` |

The `EXCLUDED_SOURCE_FILE_NAMES` flag for `LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift` was kept on every command, as the plan says (those files do not compile at HEAD, a STATE.md concern).

## Deviations from Plan

None. The plan was executed as written.

## Cross-repo

No backend or Android change was made or needed. The server still enforces the currency allowlist and price floor. Android's seed and selection already agree.

## Device UAT

None added. For CAD and USD the old and new seed currency agree, so nothing changes on an iPhone. The fix is proven by unit tests.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files verified to exist: `ClickMe2026Tests/Support/MeDataFixtures.swift`, all modified files. Commits verified in history: 4467aa6, a87e963, 8322e9b, f6bbbf8, c0cbfff.
