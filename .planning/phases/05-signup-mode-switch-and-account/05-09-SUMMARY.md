---
phase: 05-signup-mode-switch-and-account
plan: 09
subsystem: ui
tags: [swiftui, profile-settings, languages, auto-save, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-02 LanguageSelectionViewModel tap-ordered orderedSelection that keeps initial items before the catalog loads
provides:
  - ClientProfileSettingsViewModel.languageItems, customLanguages, computed languages, hydrate(from:), applyLanguageSelection(_:), makeProfileUpdateBody(), internal performAutoSave(), init(..., autoSaveDebounce:)
  - ExpertProfileSettingsViewModel.languageItems, customLanguages, computed languages, hydrate(from:), applyLanguageSelection(_:), makeProfileUpdateBody(), init(languageItems:)
  - Both profile settings screens open the catalog-backed LanguageSelectionView; LanguageEditorSheet deleted
  - ProfileLanguageField empty prompt "Add languages" and wrapping chips
  - ProfileLanguagesSaveTests (15 tests)
affects: [05-13 device UAT checklist (SET-01 check), Android language-save follow-up]

actuals:
  tokens: 11000
  tasks: 2
  commits: 2
plan_head_before: 0b6b50403f3dc1976a06a1f4b1cff6ab3463db96
plan_head_after: 3a9c5fac2f35b7889e17983ed7a436d7a17c218f

tech-stack:
  added: []
  patterns:
    - "Languages are held as [LanguageItem] (catalog ids) plus [String] customs; the PATCH languages group is built only when the picked ids differ from the persisted ids, and always carries the customs"
    - "Auto-save records the snapshot read before the request, so an edit made in flight is not marked saved"

key-files:
  created:
    - ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift
  modified:
    - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift
    - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsView.swift
    - ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/ProfileLanguageField.swift
    - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsView.swift
  deleted:
    - ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/LanguageEditorSheet.swift

key-decisions:
  - "Both settings screens use LanguageSelectionView (catalog-backed, searchable); the hard-coded 12-label sheet is deleted (Open Question 6 default)"
  - "Custom (id-less) languages are always sent with language_ids, so the full-replace PATCH never deletes them; the picker cannot add or remove them (T-05-20)"
  - "A Done that would leave zero languages (no ids and no customs) is never applied or sent: the previous list stays and autoSaveError becomes Keep at least one language.; a profile that already has none is a silent no-op (UI-SPEC EM4, A9)"
  - "State/Province clear needed no wire change: the body already sends the trimmed string, so an emptied field is the empty string and never null (D-07 settings half), now regression-tested on both screens"

requirements-completed: [SET-01]

coverage:
  - id: D1
    description: "A client language edit sends languages.language_ids in picked order and languages.custom_languages, and the saved checkmark follows a successful PATCH"
    requirement: "SET-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift#clientLanguageEditSendsIdsAndCustoms"
        status: pass
    human_judgment: false
  - id: D2
    description: "The expert screen sends the same languages group through the same PATCH"
    requirement: "SET-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift#expertLanguageEditSendsIdsAndCustoms"
        status: pass
    human_judgment: false
  - id: D3
    description: "A text-only edit never sends the languages group; customs always travel with ids"
    requirement: "SET-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift#clientTextEditOmitsLanguages, expertTextEditOmitsLanguages, clientCustomOnlyIsNotZero"
        status: pass
    human_judgment: false
  - id: D4
    description: "After a successful save an unchanged re-schedule sends no second PATCH, and two edits inside one debounce window send one PATCH with the final selection"
    requirement: "SET-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift#clientSavedLanguagesAreIdempotent, clientTwoEditsOnePatch"
        status: pass
    human_judgment: false
  - id: D5
    description: "Clearing State/Province sends an empty string, never null, on both screens"
    requirement: "SET-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift#clientClearedStateSendsEmptyString, expertClearedStateSendsEmptyString"
        status: pass
    human_judgment: false
  - id: D6
    description: "Zero-language Done sends nothing, keeps the previous list and shows Keep at least one language.; an already-empty profile is silent (UI-SPEC EM4)"
    requirement: "SET-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift#clientZeroDoneKeepsPreviousList, clientZeroDoneOnEmptyProfileIsSilent, expertZeroDoneKeepsPreviousList, expertZeroDoneOnEmptyProfileIsSilent"
        status: pass
    human_judgment: false
  - id: D7
    description: "On a real iPhone, changed languages on the client and expert profile are shown from the server after leaving and reopening; the Add languages prompt, the alert text and the chip wrapping look right"
    requirement: "SET-01"
    verification: []
    human_judgment: true
    rationale: "Sheet presentation, the saved checkmark, a fresh server read and chip wrapping are device behavior; listed in 05-DEVICE-UAT-CHECKLIST.md (plan 05-13)"

duration: 35min
completed: 2026-11-13
status: complete
---

# Phase 05 Plan 09: Profile language save Summary

**Language edits on the client and expert profile settings now reach PATCH /user/profile as catalog ids in picked order plus the existing custom languages, through the catalog-backed picker, with a guard that never saves an empty language list.**

## Performance
- **Duration:** about 35 min
- **Tasks:** 2 of 2
- **Files:** 5 modified, 1 created, 1 deleted

## Accomplishments
- Task 1 (tracer): the client view model holds `languageItems` and `customLanguages`; `makeProfileUpdateBody()` adds `languages` only when the picked ids differ from `persistedLanguageIds`, always with the customs. The checkmark now follows a PATCH that really carried the change.
- Task 2: the expert view model got the same shape; both screens open `LanguageSelectionView(initialSelection:onDone:)`; `LanguageEditorSheet.swift` and its preview are gone.
- `ProfileLanguagesSaveTests`: 15 tests across both screens (ids and customs, text-only edit, province clear, idempotency, debounce coalescing, zero-language guard). SelectionOrderTests (plan 05-02) still passes (10 tests).
- Build is clean: `BUILD SUCCEEDED`, 0 warnings in the four plan files (baseline also 0).

## Task Commits
1. **Task 1: client language edits are saved** - `b956838`
2. **Task 2: expert language edits saved, old sheet removed** - `3a9c5fa`

## Deviations from Plan

### Auto-fixed / Added Issues

**1. [Rule 2 - Missing critical functionality] Zero-language guard in both view models (UI-SPEC EM4, A9)**
- **Found during:** Task 1 (instruction from the UI-SPEC, approved after the plan was written)
- **Issue:** The backend accepts an empty language list and deletes every row, so a Done with nothing selected would wipe the user's languages.
- **Fix:** `applyLanguageSelection(_:)` on both view models: with no ids and no customs it sends nothing and keeps the previous list, setting `autoSaveError` to `Keep at least one language.` (existing `Couldn't save changes` alert); a profile that already has none is a silent no-op. `makeProfileUpdateBody()` also never builds a languages group that would leave zero. The views call `applyLanguageSelection` from the picker's `onDone` instead of assigning `languageItems` directly.
- **Files modified:** both view models and both views; 8 extra tests
- **Commits:** `b956838`, `3a9c5fa`

**2. [Rule 2 - Missing critical functionality] `Add languages` prompt and wrapping chips in `ProfileLanguageField`**
- **Found during:** Task 1
- **Issue:** The file is not in the plan's `files_modified`, but UI-SPEC requires the `Add languages` row for a profile with zero languages, and the catalog picker allows far more languages than the old 12-label sheet, so the single-line `HStack` of chips would overflow.
- **Fix:** Empty state text in `ProfileSettingsBrand.onSurfaceVar` (`.subheadline`, Regular); chips use the existing `ProfileFlowLayout` and an offset-keyed `ForEach` (a custom label equal to a catalog label cannot collide).
- **Files modified:** `ProfileLanguageField.swift`
- **Commit:** `b956838`

**3. [Rule 1 - Bug] Auto-save recorded the post-request snapshot**
- **Found during:** Task 1
- **Issue:** `performAutoSave()` set `lastAppliedSnapshot = currentSnapshot()` after the request, so an edit made while the request was in flight would be marked as saved.
- **Fix:** The snapshot and the sent language ids are read before the request and those values are recorded on success (expert already did this for the snapshot).
- **Commit:** `b956838`

**Total deviations:** 3 (2 Rule 2, 1 Rule 1). **Impact:** all additive and inside the files this plan owns, except `ProfileLanguageField.swift`.

## Issues Encountered
- The TDD RED run was not captured as a separate failing run: tests and implementation were written in one pass and first run together (green), then extended. Each behavior has a test that would fail without the corresponding code path, but no RED log exists.
- `ClickMe2026/Localizable.xcstrings` already carried uncommitted edits before this run and was not staged. The new `Add languages` string is not in the catalog; it falls back to the source text.

## Known Stubs
None.

## Threat Flags
None. The PATCH surface is unchanged; T-05-20 (custom languages deleted by a full replace) is mitigated and tested.

## Next Phase Readiness
Plan 05-13 should list the SET-01 device check: change languages on the client and the expert profile, leave and reopen, confirm the new languages and any custom language; deselect every language and tap Done (expect the `Couldn't save changes` / `Keep at least one language.` alert). Android likely has the same language-save gap and the same zero-language risk; no Android change was made.

## Self-Check: PASSED
- Files: `ProfileLanguagesSaveTests.swift` found; `LanguageEditorSheet.swift` absent; no Swift reference to it remains.
- Commits `b956838` and `3a9c5fa` are ancestors of HEAD; `git rev-list --count` from `plan_head_before` is 2.
- `ProfileLanguagesSaveTests`: 15 tests in 1 suite passed; `SelectionOrderTests`: 10 passed; Debug build succeeded with no new warnings.
