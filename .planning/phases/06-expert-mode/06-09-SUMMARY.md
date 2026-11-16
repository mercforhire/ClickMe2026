---
phase: 06-expert-mode
plan: 09
subsystem: android-topic-editor
tags: [android, jetpack-compose, material3, currency, exp-17, usd-topic-pricing]

requires:
  - phase: 06-expert-mode
    provides: "iOS EXP-17 reference (73e729e, pinned by 06-01): currency picker, lock caption, USD notice copy"
provides:
  - "Android topic editor CAD | USD currency picker on new and free topics, locked on paid topics, with the iOS copy"
  - "PricingLimits.allowedCurrencies (allowed_currencies, nullable) on the Android /me model"
affects: [06-10, android-parity, uat]

requirements-completed: [EXP-17]

actuals:
  tokens: 28000
  tasks: 2
  commits: 1
plan_head_before: 0f2e8cd76541473a6d64f3d6ddef49034b87e5d3
plan_head_after: da498620

tech-stack:
  added: []
  patterns:
    - "Picked state mirrored to SavedStateHandle (KEY_CURRENCY) and re-validated against /me on every refresh"
    - "Material 3 SingleChoiceSegmentedButtonRow from the existing Compose Material 3 dependency (first use in the app)"

key-files:
  created:
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/subviews/TopicCurrencyPicker.kt
  modified:
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/model/responses/MeData.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorUiState.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorViewModel.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorScreen.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/res/values/strings_expert_topics.xml
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorViewModelTest.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/subviews/TopicEditorSubviewsTest.kt

key-decisions:
  - "Lock rule mirrors iOS isCurrencyLocked(topic:): an edit whose seed is paid and carries a valid stored currency is locked; free or legacy topics are not"
  - "allowedCurrencies in the UI state always includes the current currency (as iOS does), so a paid USD topic on a CAD-default account still shows a disabled picker on USD"
  - "onMeChanged keeps a picked currency (KEY_CURRENCY present and still allowed); an edit with no pick keeps the currency it opened with, as before"
  - "TopicPrice.kt left unchanged: floors, parsing and boundary rules are reused as is"

patterns-established:
  - "Currency pick survives /me refresh, rotation and process death because resolveCurrency re-reads KEY_CURRENCY and validates it against the latest allowed list"

duration: 40min
completed: 2026-11-16
status: complete

coverage:
  - id: D1
    description: "A new Android topic can pick CAD or USD from pricing_limits.allowed_currencies; picking USD saves hourly_rate.currency USD with the amount unchanged"
    requirement: EXP-17
    verification:
      - kind: unit
        ref: "TopicEditorViewModelTest#pickingUsdOnANewTopicReachesTheCreateRequest"
        status: pass
    human_judgment: false
  - id: D2
    description: "A paid topic's currency is locked on edit (onCurrencyChange ignored, save sends the stored currency); a free topic can switch"
    requirement: EXP-17
    verification:
      - kind: unit
        ref: "TopicEditorViewModelTest#aPaidEditIsLockedAndSendsItsStoredCurrency, #aFreeEditCanSwitchCurrency"
        status: pass
    human_judgment: false
  - id: D3
    description: "Switching currency keeps the typed price text, re-reads the floor, and the below-floor error follows the currency at the boundary"
    requirement: EXP-17
    verification:
      - kind: unit
        ref: "TopicEditorViewModelTest#switchingCurrencyKeepsTheTypedTextAndReReadsTheFloor, #theBelowFloorErrorFollowsTheChosenCurrencyAtTheBoundary"
        status: pass
    human_judgment: false
  - id: D4
    description: "A picked currency survives a /me refresh and a rebuild from the same SavedStateHandle; codes outside the allowed list are ignored; a /me without allowed_currencies decodes and hides the picker"
    requirement: EXP-17
    verification:
      - kind: unit
        ref: "TopicEditorViewModelTest#aMeRefreshKeepsAPickedCurrencyOnANewTopic, #aPickedCurrencySurvivesRebuildingFromTheSameSavedState, #aCurrencyOutsideTheAllowedListIsIgnored, #aMeWithoutAllowedCurrenciesOffersOnlyTheDefaultAndStillDecodes"
        status: pass
    human_judgment: false
  - id: D5
    description: "TopicCurrencyPicker renders CAD | USD segments, disables them with the exact lock caption, shows the exact USD notice only while USD is selected, and renders nothing for a single currency"
    requirement: EXP-17
    verification:
      - kind: automated_ui
        ref: "TopicEditorSubviewsTest#currency_* (5 Robolectric rows)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Material 3 segmented rendering and the live save on a real Android device or emulator against production"
    requirement: EXP-17
    verification: []
    human_judgment: true
    rationale: "Visual rendering of the segmented row and a live save need a running Android app; recorded as the plan's backstop device check"
---

# Phase 6 Plan 09: Android CAD and USD Topic Currency Picker Summary

**Android topic editor gains a Material 3 CAD | USD segmented picker fed by `pricing_limits.allowed_currencies`: free choice on new and free topics, locked on paid topics, with the exact iOS lock caption and USD conversion-fee notice, delivered as one Android commit.**

## Performance

- **Duration:** about 40 min
- **Started:** 2026-11-16T17:15Z (approx)
- **Completed:** 2026-11-16T17:58Z
- **Tasks:** 2 (tracer + picker)
- **Files modified:** 8 (7 modified, 1 created), all in `/Users/LeonChen/Documents/ClickMe_Android`

## Accomplishments

- `PricingLimits.allowedCurrencies` added as a nullable, defaulted field, so older `/me` payloads still decode (T-06-15).
- `TopicEditorViewModel.onCurrencyChange` with the paid-edit lock, allowed-list validation, `KEY_CURRENCY` saved state, and a `/me` refresh that no longer overwrites a picked currency (T-06-14).
- `TopicCurrencyPicker` (Material 3 `SingleChoiceSegmentedButtonRow`) placed above the price field, with three new strings copied character for character from iOS / `USD-TOPIC-PRICING.md` section 4.
- 9 new view-model tests and 5 new Robolectric rows; `TopicEditorViewModelTest` 49/49, `TopicEditorSubviewsTest` 30/30, `TopicEditorScreenTest` 22/22 pass, `ktlintCheck` clean.

## Task Commits

The plan requires one squashed EXP-17 commit in the Android repo (user decision 2026-11-16), so Task 1 (tracer) was left uncommitted and committed together with Task 2.

1. **Task 1: Tracer, state and view-model path** and **Task 2: segmented picker, caption, notice** - `da498620` (feat), in `ClickMe_Android`
   - Android base commit (recorded in `/tmp/06-09-base.txt`): `0f2e8cd76541473a6d64f3d6ddef49034b87e5d3`
   - `git rev-list --count 0f2e8cd7..HEAD` = 1; `git show --stat HEAD` lists exactly the eight plan files; no `.idea` or `.planning` file committed.

**Plan metadata:** the iOS repo holds only this SUMMARY for plan 06-09 (STATE.md and ROADMAP.md are updated by the orchestrator).

## Tracer gate

Task 1's `<verify>` (view-model, price and key tests plus `ktlintCheck`) passed end-to-end with no `<human-check>`, so under `end-of-phase` mode the tracer was verified and expansion continued (`Tracer verified end-to-end - expanding`).

## TDD note

Both tasks are `tdd="true"` inside a plan of `type: execute`, and the plan's commit rule forbids intermediate commits (one squashed commit). Tests and implementation were therefore written in one pass and verified green together; no separate RED commit exists and no `gsd_run check tdd-red-evidence` record was produced. This follows the plan's explicit commit rule rather than the per-feature RED/GREEN commit pattern.

## Decisions Made

See `key-decisions` above. One behavior worth recording: the USD notice lives inside the picker composable (as the plan specifies), so it shows only when the picker shows (two or more pickable currencies). iOS renders its notice below the price field independent of the picker. The difference only matters for a USD-default account on a server that omits `allowed_currencies`, which the live backend does not do.

## Deviations from Plan

None - plan executed exactly as written. Two small in-scope details worth noting:

- `ktlint` flagged the indentation of the `meWith` test builder after its signature grew parameters; re-indented (same file, same commit).
- `onMeChanged` on an edit keeps the currency it opened with unless a currency was picked, which preserves the prior edit behavior the plan asked to leave unchanged.

**Total deviations:** 0 auto-fixed. **Impact on plan:** none.

## Issues Encountered

None. A bash 3.2 compound-command refusal required running the Task 1 gate greps as separate commands; results were identical to the plan's gates (4 modified files, nothing staged, HEAD at the recorded base before Task 2).

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or schema; `allowed_currencies` is an additive read of an existing `/me` field (T-06-14 and T-06-15 mitigated as planned).

## User Setup Required

None - no external service configuration required.

## Outstanding human check (backstop)

Android device or emulator check against production with a test expert account: create a topic, pick USD, type 12.50, switch to CAD and back; edit a paid USD topic; edit a free topic. Expected: row above the price field under "Currency"; USD shows the conversion-fee notice and the helper minimum in US dollars; 12.50 survives every switch; the paid USD topic shows the row disabled on USD with the lock caption; the free topic can switch. Fold into the Phase 6 UAT checklist (plan 06-10).

## Next Phase Readiness

- EXP-17 Android half is done and committed; the iOS half is plan 06-01.
- Android follow-ups logged by the plan (Add hours near end of day, off-grid row display, client hub dot) are for plan 06-10 to write to a todo; not built here.

## Self-Check: PASSED

- Created file exists: `TopicCurrencyPicker.kt` FOUND.
- Commit `da498620` is an ancestor of Android `HEAD` (it is `HEAD`); exactly one commit since base `0f2e8cd7`.
- `git status --short -- app` in Android is empty; `.idea` entries are the same pre-existing changes.
- No iOS app or test file edited or staged by this plan.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
