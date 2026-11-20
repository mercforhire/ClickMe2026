---
phase: 08-release
plan: "30"
subsystem: android-parity
tags: [android, kotlin, availability, time-range-picker, parity, tdd]

requires:
  - phase: 08
    provides: "Plan 08-26: the user's Android parity port request P1 (a stored off-grid or 24:00 time stays a picker row)"
  - phase: 06
    provides: "iOS 06-03 (EXP-07, D-08): AvailabilitySlotRules.pickerRows and the sheet's storedValue wiring"
provides:
  - "Android AvailabilityScheduleLogic.pickerRows(isStart, draftStart, draftEnd, storedValue), the port of iOS AvailabilitySlotRules.pickerRows, replacing startOptions and endOptions"
  - "TimeRangePickerContent takes storedStart and storedEnd; TimeRangePickerSheet passes the slot as it opened (initial.start, initial.end) while the draft stays in rememberSaveable"
  - "A stored 09:15 start or 24:00 end stays a row for as long as the sheet is open, even after another row is tapped, and can be tapped again"
  - "A 24:00 end now leaves 23:30 as a Start row, as on iOS (one shared grid 00:00 to 23:30 for both lists)"
affects: [08-15, 08-31, android-release]

actuals:
  tokens: 3540
  tasks: 2
  commits: 2

# commits is measured in the Android repo, where this plan's code commits live:
# git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count 68509208..HEAD
commits: 2
plan_head_before: 68509208a1c49e1bd208ce360389e204933ee2d8
plan_head_after: da7002ce5e9ad4327950642cc292d7c69c2bbf83

tech-stack:
  added: []
  patterns:
    - "A picker's selectable rows are a pure function of the draft plus the value the sheet opened with, so an off-grid or 24:00 stored time never leaves the list while the sheet is open"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/AvailabilityScheduleLogic.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/subviews/TimeRangePickerSheet.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/AvailabilityScheduleLogicTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/subviews/TimeRangePickerSheetTest.kt"

key-decisions:
  - "One grid 0 through LATEST_END (23:30) feeds both lists, as iOS lastGridTime does; LATEST_START stays because canAddHours still uses it"
  - "The draft value is no longer injected into the rows (iOS does not): the draft is always a grid row or the stored value, since every draft comes from a tap or from the opening value"
  - "Wire format untouched: 1440 still round-trips losslessly; only the displayed rows changed"

patterns-established:
  - "Port a pure iOS rule helper by name and signature (pickerRows) and mirror its Swift Testing table row for row in the Kotlin logic test"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "A stored off-grid start (09:15) and a stored 24:00 end stay rows after another row is tapped, and can be tapped again"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../availability/subviews/TimeRangePickerSheetTest.kt#storedOffGridStartStaysARowAfterAnotherStartIsTapped"
        status: pass
      - kind: unit
        ref: "app/src/test/.../availability/subviews/TimeRangePickerSheetTest.kt#storedMidnightEndStaysARowAfterAnotherEndIsTapped"
        status: pass
      - kind: unit
        ref: "app/src/test/.../availability/AvailabilityScheduleLogicTest.kt#pickerRows_storedOffGridStartSurvivesAnotherDraftStart"
        status: pass
      - kind: unit
        ref: "app/src/test/.../availability/AvailabilityScheduleLogicTest.kt#pickerRows_storedMidnightEndSurvivesAnotherDraftEnd"
        status: pass
    human_judgment: false
  - id: D2
    description: "Android's rows equal iOS pickerRows for every input: the six iOS table rows, including 23:30 as a Start with a 24:00 end, a forbidden stored value dropped, no duplicate, and 24:00 never a new End choice"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../availability/AvailabilityScheduleLogicTest.kt#pickerRows_aMidnightEndLeavesHalfPastElevenAsAStart"
        status: pass
      - kind: unit
        ref: "app/src/test/.../availability/AvailabilityScheduleLogicTest.kt#pickerRows_storedValueTheOtherDraftValueForbidsIsDropped"
        status: pass
      - kind: unit
        ref: "app/src/test/.../availability/AvailabilityScheduleLogicTest.kt#pickerRows_storedGridValueIsNotDuplicated"
        status: pass
      - kind: unit
        ref: "app/src/test/.../availability/AvailabilityScheduleLogicTest.kt#pickerRows_midnightIsNeverANewEndChoice"
        status: pass
    human_judgment: false
  - id: D3
    description: "On a real Android device the sheet shows and keeps the stored 9:15 AM and 12:00 AM rows as on iOS, and Cancel leaves the slot unchanged"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Robolectric rows prove the row logic and the tap behavior; only a device run against the real backend with a slot written by another client proves the stored values reach the sheet and that Cancel changes nothing; the (P1) device check below covers it"

duration: 5min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 30: Android Stored Off-Grid Time Stays a Picker Row (P1) Summary

**Android's Select Time Range sheet now keeps a stored off-grid start (09:15) or stored 24:00 end as a tappable row for as long as the sheet is open, using a port of iOS `AvailabilitySlotRules.pickerRows` with the slot's opening values as `storedValue`; a 24:00 end also leaves 23:30 as a Start row, as on iOS (iOS 06-03 D-08 parity).**

## Performance

- **Duration:** about 5 min (start recorded from the first command, 2026-11-20T06:33Z)
- **Completed:** 2026-11-20T06:38Z
- **Tasks:** 2 (stored-row tracer through the sheet, full iOS row table plus full run)
- **Files modified:** 4 (all in the Android repo; no iOS code, no backend change)

## Accomplishments

- Closed port request P1. Before this plan the Android rows added only the current draft value to the grid, so once the expert tapped another row a stored 09:15 start or 24:00 end vanished from the list and could not be chosen again. `pickerRows(isStart, draftStart, draftEnd, storedValue)` replaces `startOptions` and `endOptions`; `TimeRangePickerSheet` passes `storedStart = initial.start` and `storedEnd = initial.end` (the slot as the sheet opened) into `TimeRangePickerContent`, while the draft stays in `rememberSaveable`.
- Android's rows now equal iOS `pickerRows` for every input: one 30-minute grid from 00:00 to 23:30 for both lists, kept when before the draft end (Start) or after the draft start (End), plus the stored value only when it passes the same test, distinct and ascending. 24:00 is a row only when it is the stored end. The one visible change beyond the stored row is 23:30 in the Start list when the end is 24:00.
- The wire format and the 1440 round trip are untouched (T-08-60 accepted as planned: only the slot's own opening value is added, and only when it passes the row test).
- Full Android unit suite plus ktlint green: 400 test classes, 5420 tests, 0 failures, 0 skipped (up from 5413; +2 logic and +2 sheet rows in Task 1, +3 logic rows in Task 2).

## Task Commits

All commits are local on Android `main`; nothing was pushed (Android `origin/main` is still `27e024bf`).

1. **Task 1: Tracer, a stored 09:15 start and 24:00 end stay rows after the expert taps another row** - `96933b85` (fix; the four planned paths)
2. **Task 2: Picker rows equal iOS pickerRows for every input, including 23:30 with a 24:00 end** - `da7002ce` (fix; two paths)

`git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count 68509208..HEAD` prints 2 (08-29's last commit is `68509208`). `.idea/*` and the untracked `.planning/` files were never staged.

**Plan metadata:** the iOS repo docs commit that holds this SUMMARY (docs: complete plan).

## TDD evidence (RED)

RED was run first for both tasks and is recorded here, not committed separately (the plan calls for one commit per task). Both RED runs compiled and failed on the planned assertions, not on compilation, setup or discovery. The repo's classifier (`gsd_run check tdd-red-evidence`) has no adapter for Gradle's console output, so the semantic assessment below is the evidence.

**Task 1 (stored rows survive a tap), 53 tests, 4 failed.** For RED, `pickerRows` was first given the old behavior (grid plus the current draft value, `storedValue` ignored), the six old rows were renamed onto it, and the four new rows were added.

```
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest \
  --tests 'com.uptrendinvestments.clickmeapp.screens.expertmode.availability.AvailabilityScheduleLogicTest' \
  --tests 'com.uptrendinvestments.clickmeapp.screens.expertmode.availability.subviews.TimeRangePickerSheetTest'
AvailabilityScheduleLogicTest > pickerRows_storedOffGridStartSurvivesAnotherDraftStart FAILED    AssertionError at AvailabilityScheduleLogicTest.kt:362
AvailabilityScheduleLogicTest > pickerRows_storedMidnightEndSurvivesAnotherDraftEnd FAILED       AssertionError at AvailabilityScheduleLogicTest.kt:370
TimeRangePickerSheetTest > storedOffGridStartStaysARowAfterAnotherStartIsTapped FAILED           AssertionError at TimeRangePickerSheetTest.kt:67
TimeRangePickerSheetTest > storedMidnightEndStaysARowAfterAnotherEndIsTapped FAILED              AssertionError at TimeRangePickerSheetTest.kt:73
53 tests completed, 4 failed
```

Semantic assessment: the four targets executed and failed on the planned behavior. The logic rows failed because the stored 555 (or 1440) was not among the rows once the draft moved. The sheet rows failed at `scrollStartTo` / `scrollEndTo` (lines 67 and 73), the scroll to the stored row's tag, because that row no longer exists in the list after the other row is tapped, which is exactly the user-visible bug. The other 49 tests, including the six renamed old rows, passed, so nothing failed for an unrelated reason.

**Task 2 (iOS row table, 23:30 start with a 24:00 end), 46 logic tests, 1 failed:**

```
./gradlew ... :app:testDevDebugUnitTest --tests '...availability.AvailabilityScheduleLogicTest'
AvailabilityScheduleLogicTest > pickerRows_aMidnightEndLeavesHalfPastElevenAsAStart FAILED   AssertionError at AvailabilityScheduleLogicTest.kt:333
46 tests completed, 1 failed
```

Semantic assessment: the target ran and failed on its first assertion, `pickerRows(true, 1380, 1440, 1380)` returned the grid to 23:00 instead of to 23:30 (the 23:30 Start row is missing with a 24:00 end). The other three new rows (`pickerRows_storedValueTheOtherDraftValueForbidsIsDropped`, `pickerRows_storedGridValueIsNotDuplicated`, `pickerRows_midnightIsNeverANewEndChoice`) passed at RED because Task 1's GREEN already established that behavior; they are added as the remaining rows of the iOS table, not as new behavior, and are recorded as such rather than claimed as failing.

## Verification

- Task 1 verify (filtered logic and sheet classes plus ktlint, then the greps): BUILD SUCCESSFUL, `fun pickerRows(` present, `storedStart = initial.start` and `storedEnd = initial.end` present, no `startOptions` or `endOptions` anywhere under `app/src/main` or `app/src/test`, `storedOffGridStartStaysARowAfterAnotherStartIsTapped` present. A first ktlint run failed on one over-long call chain in the new sheet test ("Expected newline before '.'"); it was split across lines and the run repeated green (not a deviation, an in-task fix before the commit).
- Task 2 verify (full `:app:testDevDebugUnitTest ktlintCheck`): BUILD SUCCESSFUL in 1m 24s; 400 classes, 5420 tests, 0 failures, 0 errors, 0 skipped. The three named iOS-table rows are present in `AvailabilityScheduleLogicTest.kt`, and Android `origin/main` is still `27e024bf`.
- The plan's single long-line verify commands were refused by the tool shell (nested command substitution), so the Gradle runs and each grep or `git rev-parse` check were run as equivalent separate commands, as the run instructions allow.
- Tracer gate: Task 1's verify was green on the exact tree that was committed, so the tracer was treated as verified end to end before expansion.

## Files Created/Modified

- `AvailabilityScheduleLogic.kt` - `startOptions` and `endOptions` replaced by `pickerRows`, one 00:00 to 23:30 grid for both lists with the stored-value rule and KDoc ported from iOS
- `TimeRangePickerSheet.kt` - `TimeRangePickerContent` gains `storedStart` and `storedEnd`; the sheet passes `initial.start` and `initial.end`; both columns call `pickerRows`; the preview passes stored values
- `AvailabilityScheduleLogicTest.kt` - the six old rows renamed onto `pickerRows` (`pickerRows_*`), two P1 rows from Task 1 and the three remaining iOS table rows from Task 2 added; the old 23:00 Start-cap row became the iOS 23:30 row
- `TimeRangePickerSheetTest.kt` - two existing call sites pass stored values, a stateful 09:15 to 24:00 harness and two stored-row rows added

## Decisions Made

See `key-decisions` above. In short: one shared grid to 23:30 as iOS; no draft-value injection (iOS has none); `LATEST_START` kept for `canAddHours`; wire format and 1440 round trip unchanged.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0
**Impact on plan:** none.

## Issues Encountered

- The tool shell refused the plan's one-line verify chains and one of my own compound check commands (nested command substitution); each was re-run as separate equivalent commands.
- Disk stayed between 6.8 and 7.0 GiB free through all Gradle runs; nothing was deleted.

## Known Stubs

None.

## Threat Flags

None. T-08-60 is accepted as planned (only the slot's own opening value is added, and only when it passes the same start-before-end or end-after-start test as every grid row; the overlap banner still reports overlaps). T-08-63 is mitigated by the device item below (dedicated test account, availability noted first and restored afterwards, the 09:15 to 24:00 slot set by the user, never by Claude).

## Device checks for 08-15 (Android section)

Use an Android dev build from `ClickMe_Android` `main` (local commits `96933b85`, `da7002ce`). Claude does not run this: it writes availability to the live production backend.

1. **(P1)** Sign in as a dedicated test expert account (never a real expert's account). Before starting, note that account's current weekly availability. The user sets that account's Monday slot to 09:15 to 24:00 through the API (Claude never writes production data). Open the slot: 9:15 AM and 12:00 AM are selected. Tap 10:00 AM: the 9:15 AM row is still listed. Tap 11:30 PM as the end: the 12:00 AM row is still listed. Cancel leaves the slot unchanged. Afterwards restore the noted availability on that account and confirm the Availability screen shows it again.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Android lane is ready for 08-31. The (P1) device item above goes into plan 08-15's Android section.
- Nothing pushed: Android `origin/main` is still `27e024bf`, with this plan's two commits (and the earlier 08-2x commits) local on `main`.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Modified files exist: the two main-source and two test files checked, all FOUND.
- Commits are ancestors of HEAD: `96933b85`, `da7002ce`, both FOUND; `rev-list --count 68509208..HEAD` is 2.
- Nothing staged beyond the planned paths; `.idea/*` still modified and unstaged; `show --stat` of each commit lists exactly its planned paths.
