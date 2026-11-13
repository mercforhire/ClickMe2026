---
phase: 05-signup-mode-switch-and-account
plan: 02
subsystem: signup
tags: [swiftui, signup, expertise-tags, languages, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-01 (no code dependency; same phase, wave 1)
provides:
  - SignupTagsViewModel.selectionOrder, so selectedTags, the accumulator and the PATCH expertise_tags array follow tap order (first tap = primary)
  - LanguageSelectionViewModel.selectionOrder, so onDone returns languages in tap order
  - SelectionOrderTests suite (10 tests) covering both pickers and both request bodies
affects: [05-09 SET-01 reuses LanguageSelectionView in both profile settings screens, 05-04 same Basic Info save body]

actuals:
  tokens: 3980
  tasks: 2
  commits: 2
plan_head_before: f30a12323c05c6ad8e2f335e478d0a922b9f9818
plan_head_after: eba5f0f76630aabe1fcdf9303af9176edd923b22

tech-stack:
  added: []
  patterns:
    - "Ordered id array beside the membership Set; output resolves ids through the catalog, falling back to the init seed so nothing drops before the catalog loads"

key-files:
  created:
    - ClickMe2026Tests/Signup/SelectionOrderTests.swift
  modified:
    - ClickMe2026/Views/Screens/Signup Flow/Setup Tags/SignupTagsViewModel.swift
    - ClickMe2026/Views/Screens/Signup Flow/Basic Info/Language Selection/LanguageSelectionViewModel.swift
    - ClickMe2026/Views/Screens/Signup Flow/Basic Info/Language Selection/LanguageSelectionView.swift

key-decisions:
  - "selectedIds (tags) and selected (languages) became private(set) so the Set and the ordered array can only change together; no external writer existed"
  - "Seed items are kept in a private dictionary (seedTagsById, seedLanguagesById) and used when the catalog has no entry for an id (RESEARCH Pitfall 6)"
  - "SignupAccumulator.hydrate still re-sorts non-primary tags alphabetically on resume, unchanged per RESEARCH Pattern 6"

requirements-completed: [SIGN-03]

coverage:
  - id: D1
    description: "Expertise tags are listed, accumulated and saved in tap order; deselect then reselect appends; removeTag keeps the rest in order"
    requirement: "SIGN-03"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SelectionOrderTests.swift#tagsFollowTapOrder, deselectThenReselectAppends, removeTagKeepsOrder, saveSendsTapOrder"
        status: pass
    human_judgment: false
  - id: D2
    description: "A seeded tag selection keeps its order and shows before the catalog loads and after it loads alphabetically"
    requirement: "SIGN-03"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SelectionOrderTests.swift#seedKeepsOrderWithoutCatalog, seedOrderSurvivesCatalog"
        status: pass
    human_judgment: false
  - id: D3
    description: "LanguageSelectionView returns languages in tap order and the Basic Info save sends the languages array in that order"
    requirement: "SIGN-03"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SelectionOrderTests.swift#languageSeedKeepsOrderWithoutCatalog, languageSeedOrderSurvivesCatalog, languageToggleFollowsTapOrder, basicInfoSaveSendsLanguageOrder"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Selected Tags strip and language rows show the tapped order on a real device"
    requirement: "SIGN-03"
    verification: []
    human_judgment: true
    rationale: "The unit tests assert view model output; the visual strip order is checked on the device UAT checklist"

duration: 8min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 02: Selection Order Summary

**Signup tag and language pickers keep the order the user tapped, so the first expertise tag tapped is the primary tag the server stores and languages are saved in the order picked.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-11-13T17:38:00Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `SignupTagsViewModel` adds `@Published private(set) var selectionOrder: [UUID]` and a private `seedTagsById`. `toggleTag` and `removeTag` update the Set and the order together. `selectedTags` resolves `selectionOrder` through the catalog, falling back to the seed, so `syncToAccumulator()` and `save()` (both unchanged) now send tap order. `previewSeed` sets the order too.
- `LanguageSelectionViewModel` gets the same shape (`selectionOrder`, `seedLanguagesById`); `orderedSelection` is tap-ordered and independent of the catalog. The `onDone` doc in `LanguageSelectionView` now says tap order. No layout change.
- `SelectionOrderTests` (`@MainActor`, serialized, 10 tests) covers tap order, deselect then reselect, `removeTag`, seed order with and without a loaded catalog, the PATCH `expertise_tags` array, language toggling, and the Basic Info `languages` array.

## Task Commits

1. **Task 1 (tracer): The first tag tapped is the first tag saved** - `6f800f5` (fix)
2. **Task 2: Languages come back from the picker in tap order** - `eba5f0f` (fix)

## Verification

- RED confirmed before each implementation: Task 1 run showed 4 of 6 tests failing on genuine order assertions; Task 2 run showed the language order tests failing (the Basic Info save test passed already, since `setLanguages` stored the list as given; it stays as a guard).
- `SelectionOrderTests`: 6 tests passed after Task 1, 10 tests in 1 suite passed after Task 2.
- Acceptance: `selectionOrder` appears 8 times in `SignupTagsViewModel.swift` and 6 times in `LanguageSelectionViewModel.swift`; `seedTagsById` 3 times; the old `allTags.filter { selectedIds.contains` and `allLanguages.filter { selected.contains` both 0 (baselines 1 and 1).
- Build gate: `BUILD SUCCEEDED`. Warnings in the three app files: 0 before, 0 after (`comm -13` empty).
- Tracer gate: `human_verify_mode` end-of-phase, auto mode off, automated-only `<verify>`; passed on the committed tree, so expansion continued.

## Deviations from Plan

None - plan executed exactly as written.

Notes: the plan prescribes one `fix` commit per task, so there is no separate `test(...)` RED commit; RED was run and observed before each implementation. `gsd_run` was not defined in the shell, so `gsd-tools.cjs` was called through `node` directly.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. T-05-04 (client-chosen order decides primary tag) is accepted per the plan; the server still validates tag ids.

## Working tree note

The working tree carried uncommitted edits before this run (`.DS_Store`, `.planning/config.json`, `ClickMe2026/Localizable.xcstrings`, untracked `.planning/state.json`, `.planning/milestone.lock`, `.DS_Store` files). This plan did not edit `Localizable.xcstrings` and did not stage any of those files.

## Next Phase Readiness

Ready for 05-03. Plan 05-09 can reuse `LanguageSelectionView` and rely on `onDone` returning tap order. Plan 05-04 changes province handling in the same Basic Info save body; the tests here assert only the `languages` key.

## Self-Check: PASSED

- FOUND: `ClickMe2026Tests/Signup/SelectionOrderTests.swift`, `SignupTagsViewModel.swift`, `LanguageSelectionViewModel.swift`, `LanguageSelectionView.swift`
- FOUND: `6f800f5`, `eba5f0f` (both ancestors of HEAD)
- `check evaluation-scope --plan 05-02 --commits-only` returns both commits.
