---
phase: 06-expert-mode
plan: 11
subsystem: expert-mode-topics
tags: [swiftui, topic-editor, currency, gap-closure, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: TopicPriceRules (06-01), Topic Editor currency seed and paid-topic lock (Phase 34 D-18, D-04)
provides:
  - "TopicPriceRules.validCurrencyCode(_:), the one stored-currency normalizer"
  - "ExpertTopicItem.storedCurrency, the topic's own valid code (hourly rate first, then price)"
  - "Topic Editor seed, lock rule and picker on the normalized code"
affects: [06-12, 06-16]

actuals:
  tokens: 9000
  tasks: 2
  commits: 2
plan_head_before: 299627abf56efe5bb668d62133895711ea9e5fda
plan_head_after: 20d6d8aaca7c0b5f4f6998fcfc1b979a7859219b

tech-stack:
  added: []
  patterns:
    - "One normalizer decides what a stored server currency is; callers never read raw currency strings"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/TopicPriceRules.swift
    - ClickMe2026/Model/Responses/Children/ExpertTopicItem.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
    - ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
    - ClickMe2026Tests/Utils/TopicPriceRulesTests.swift
    - ClickMe2026Tests/Model/TopicCurrencyTests.swift

key-decisions:
  - "A stored currency is valid only when trimmed it is exactly 3 ASCII letters (checked on unicode scalars); it is uppercased, else it reads as none (Android TopicPrice.validCode parity)"
  - "resolveInitialCurrency order is stored code, then the default when valid, then CAD"
  - "pickableCurrencies still appends a real off-list stored code (for example EUR) but never a blank or malformed one"

requirements-completed: [EXP-03, EXP-17]

coverage:
  - id: D1
    description: "A free topic stored with no currency (price.currency \"\") opens on the default currency, unlocked, with no blank picker segment"
    requirement: EXP-17
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#a free topic stored with a blank currency opens on the default, unlocked, with a clean picker"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#a whitespace-only stored currency reads the same as a blank one"
        status: pass
    human_judgment: false
  - id: D2
    description: "Saving that free topic sends hourly_rate.currency as a 3-letter code with is_free true, so the PATCH is not rejected with 422"
    requirement: EXP-17
    verification:
      - kind: integration
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#G-06-1-currency: a free topic stored with no currency opens on the default and saves a 3-letter code"
        status: pass
    human_judgment: false
  - id: D3
    description: "One normalizer (validCurrencyCode) handles blank, padded, malformed and non-ASCII codes"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicPriceRulesTests.swift#a stored currency code is trimmed, three ASCII letters, uppercased, else none"
        status: pass
    human_judgment: false
  - id: D4
    description: "A paid topic with a real stored code stays locked on it; a paid topic with a blank code is unlocked on the default; EXP-03 unchanged"
    requirement: EXP-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#a paid topic in the real wire shape with a real code stays locked on it"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/TopicCurrencyTests.swift#a paid topic with a blank stored code is unlocked on the default and keeps its amount"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real iPhone, a free topic that showed the blank segment opens on CAD | USD with CAD selected and saves"
    verification: []
    human_judgment: true
    rationale: "Device behavior against the live backend; covered by checklist re-check R2 and R3 written by plan 06-16"

duration: 20min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 11: Blank stored topic currency Summary

**One normalizer (`TopicPriceRules.validCurrencyCode`) makes a blank, padded or malformed stored topic currency read as none, so a free topic the server stores with `price.currency: ""` opens on the default currency and saves with a real 3-letter code instead of a 422.**

## Performance

- **Duration:** about 20 min
- **Completed:** 2026-11-17T05:12Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- `TopicPriceRules.validCurrencyCode(_:)`: trim, exactly 3 ASCII letters (unicode-scalar check, so non-ASCII letters are rejected), uppercase, else nil.
- `ExpertTopicItem.storedCurrency`: the hourly-rate code first, then the price code, both normalized.
- `TopicEditorViewModel`: `resolveInitialCurrency`, `isCurrencyLocked`, the price seed and `pickableCurrencies` all read the normalized code; no direct hourly-rate currency read remains. A blank code never appends an invisible third picker segment, and Save always sends a 3-letter currency.
- End-to-end test: the real wire free topic decodes, opens on `defaultCurrency`, and its PATCH carries a 3-letter `hourly_rate.currency` with `is_free` true.
- Table and wire-shape tests for blank, whitespace, padded, malformed and non-ASCII codes; real codes keep today's lock and seed behavior.

## Task Commits

1. **Task 1: Tracer, a free topic stored with no currency opens on the default and its Save sends a real code** - `ae87065` (fix)
2. **Task 2: Blank, padded and malformed stored codes read as none in every editor rule** - `20d6d8a` (test)

**Plan metadata:** the docs commit that carries this file.

## Files Created/Modified
- `ClickMe2026/Utils/TopicPriceRules.swift` - `validCurrencyCode(_:)`
- `ClickMe2026/Model/Responses/Children/ExpertTopicItem.swift` - `storedCurrency` extension
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift` - seed, lock and picker on the normalized code
- `ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift` - end-to-end PATCH row (8 tests)
- `ClickMe2026Tests/Utils/TopicPriceRulesTests.swift` - `validCurrencyCode` table
- `ClickMe2026Tests/Model/TopicCurrencyTests.swift` - blank-currency rows and six wire-shape fixtures (27 tests)

## Decisions Made
- Resolution order is stored code, then the default when valid, then CAD (Android `resolveCurrency` parity).
- `pickableCurrencies` keeps appending a real off-list code (for example a legacy EUR paid topic) so its selection still renders.
- The backend `""` to `null` hardening stays in plan 06-17; this fix does not depend on it and covers rows that already exist.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The git HEAD was on `main`; `git.allow_default_branch_commits` is `true` in `.planning/config.json`, so the commit guard was satisfied by config (the query verb `git.base-branch` was unavailable in this environment).

## Verification

- Task 1 run (`TopicsSetupMutationTests`, `TopicCurrencyTests`): 27 tests in 2 suites passed.
- Task 2 run (`TopicPriceRulesTests`, `TopicCurrencyTests`, `MoneyCallSiteTests`): 52 tests in 3 suites passed.
- Debug build succeeded after each task. Warning baseline for the three app files was empty before and after (no new warnings).
- Grep gates passed (no direct hourly-rate currency read in the editor, `.storedCurrency` read 3 or more times, mutation suite 8 tests, currency suite 27 tests).
- No other test suite was run. The UI tests and the three excluded network suites were not run, as the plan specifies.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. T-06-17 and T-06-18 are mitigated: only a trimmed 3-ASCII-letter code can reach the editor's selection, lock or save, and the end-to-end row pins a 3-letter currency on the PATCH.

## Next Phase Readiness
- Plan 06-12 can read `ExpertTopicItem.storedCurrency` for the topic card.
- Device re-check (checklist R2 and R3) is owned by plan 06-16.
- No backend change was made or needed in this plan.

## Self-Check: PASSED

- Files: all six modified files present in the commits (`git show --stat` for `ae87065`: 4 files, `20d6d8a`: 2 files).
- Commits `ae87065` and `20d6d8a` are ancestors of HEAD.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
