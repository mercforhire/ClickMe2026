---
phase: 06-expert-mode
plan: 03
subsystem: ui
tags: [swift, swiftui, availability, time-picker, draft-copy, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "06-02 topics fixes (different folder, untouched here)"
provides:
  - "AvailabilitySlotRules: pickerRows(isStart:draftStart:draftEnd:storedValue:) and addHours(after:)"
  - "TimeRangePickerSheet edits a draft copy; only Done commits through AvailabilitySettingsViewModel.commitEditedSlot(_:)"
  - "minutesToAMPM wraps at 24 so 1440 reads 12:00 AM"
  - "Add hours dimmed and VoiceOver-hinted when no room is left; slot-delete label Delete time range"
  - "Three nav-bar pins on AvailabilitySettingsView; folded dark-pin todo closed"
affects: [06-10 device UAT checklist (Availability Cancel, Add hours, 09:15 and 24:00 slots, D2 Save legibility)]

actuals:
  tokens: 3900
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Sheet edits a @State draft copy of the value and hands it back only on Done; Cancel, swipe-down and tap-outside write nothing"
    - "Stored value passed to the row builder as it was when the sheet opened, so an off-grid or 24:00 time stays a selectable row"

key-files:
  created:
    - ClickMe2026/Utils/AvailabilitySlotRules.swift
    - ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Availability/Subviews/TimeRangePickerSheet.swift
    - ClickMe2026/Views/Screens/Expert Mode/Availability/Subviews/AvailabilityDayRow.swift
    - .planning/todos/completed/2026-11-14-availability-settings-toolbar-dark-pin.md

key-decisions:
  - "Add hours is disabled when the new slot's start (latest end + 30) would be 23:00 or later, per user decision U3 (2026-11-16); its end clamps to 23:30"
  - "The slot-delete accessibility label is a rename (Delete time slot to Delete time range), not an addition (06-RESEARCH Open Question 4)"
  - "Sheet content is keyed by the edited slot's id so reopening on another slot builds a fresh draft"

patterns-established:
  - "AvailabilitySlotRules is the one place that decides which times a picker list offers and what Add hours appends"

requirements-completed: []
# EXP-05, EXP-06, EXP-07 left pending: requirements.ready-ids reports them blocked by plan 06-10.

coverage:
  - id: D1
    description: "Done writes the draft to the slot keeping its id; Cancel and an out-of-range commit leave the schedule unchanged"
    requirement: EXP-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#commitWritesDraft"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#dismissLeavesSlot"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#commitOutOfRangeIsNoOp"
        status: pass
    human_judgment: false
  - id: D2
    description: "Picker rows: a stored off-grid or 24:00 time is a sorted, de-duplicated row; 24:00 is never offered as new; forbidden stored values are dropped; 24:00 reads 12:00 AM"
    requirement: EXP-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#offGridStartIsInserted"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#storedMidnightEndIsKept"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#midnightNotOfferedNew"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#amPmLabels"
        status: pass
    human_judgment: false
  - id: D3
    description: "addHours returns 9-5 on an empty day, clamps the end to 23:30, and returns nil when the new start would be 23:00 or later"
    requirement: EXP-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#addHoursAfterTenPM"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#addHoursNoRoom"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift#addHoursNeverPastLastGridTime"
        status: pass
    human_judgment: false
  - id: D4
    description: "Cancel on the sheet, the dimmed Add hours control with its VoiceOver hint, a stored 09:15 and 24:00 opening selected, and Save readable in Light with Reduce Transparency and Liquid Glass Tinted"
    requirement: EXP-05
    verification: []
    human_judgment: true
    rationale: "Sheet gestures, VoiceOver hint and iOS 26 glass rendering need a real iPhone (device checks written by plan 06-10, D2)"

plan_head_before: 339f8fa903d628b9d17e521cdc0856a2701d2099
plan_head_after: 887b6004b1480d54b8dc2136e3a05d3e60632c0e

duration: 20min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 03: Availability Cancel, Add hours and 24:00 fixes Summary

**The Availability time-range sheet now edits a draft copy that only Done commits, shows a stored 09:15 or 24:00 as a selected row without rewriting it, Add hours clamps at 23:30 and dims when no room is left, 24:00 reads 12:00 AM, and the screen pins its nav bar dark so Save stays legible on iOS 26.**

## Performance

- **Duration:** about 20 min
- **Completed:** 2026-11-16
- **Tasks:** 2
- **Files modified:** 7 (2 created, 5 modified, including the todo rename)

## Accomplishments
- `AvailabilitySlotRules` (plain enum): `pickerRows` builds the 30-minute grid to 23:30 filtered by the other draft value and adds the slot's value as it was when the sheet opened, sorted and de-duplicated; `addHours(after:)` returns the slot Add hours appends or nil.
- `TimeRangePickerSheet` takes a slot value, holds `@State draft`, and calls `onDone(draft)` only from Done. The settings view routes Done to `commitEditedSlot` and Cancel to `dismissTimePicker`, and keys the sheet by the slot id. Row look, 44 pt rows, 180 pt height and the two-shot `scrollTo` are unchanged.
- `minutesToAMPM` computes the hour as `(minutes / 60) % 24`; `minutesToString` still gives `24:00` for the day row.
- Add hours: the old inline arithmetic that could produce a 24:00 end is gone; the button is disabled at 0.45 opacity with the hint "There is no room left in this day for another time range." when the rule returns nil. The slot-delete label reads `Delete time range`.
- `AvailabilitySettingsView` pins `toolbarBackground(Brand.surface)`, `toolbarBackground(.visible)` and `toolbarColorScheme(.dark)` on the nav bar; the folded todo is moved to `completed/` with a Resolution.
- `AvailabilitySlotRulesTests`: 17 tests, all pass.

## Task Commits

1. **Task 1: Tracer, the time-range sheet edits a draft, opens on the stored time, and only Done writes it** - `af3ffe8` (fix)
2. **Task 2: Add hours never makes an end the picker can't show, and Save stays legible on iOS 26** - `887b600` (fix)

## Verification

- `xcodebuild test -only-testing:ClickMe2026Tests/AvailabilitySlotRulesTests` on iPhone 17: 17 tests in 1 suite passed (after Task 1: 11 tests).
- Debug build succeeded after each task; warning baseline for the five Availability Swift files was 0 and stayed 0.
- All grep change gates in both tasks passed (no slot binding in the sheet, draft state present, three pins on non-comment lines, no `24 * 60` in the day row, new label and hint present, todo moved).

## Deviations from Plan

None - plan executed exactly as written. The plan's `tdd="true"` tasks were committed as one commit per task, as the plan's commit rules specify (no separate RED commit). The `type: execute` plan has no TDD gate sequence.

## Issues Encountered

- The first Task 2 `git add` listed the pending todo path that `git mv` had already removed, so it failed before committing; it was rerun without that path. Nothing was committed in between.

## Known Stubs

None.

## Threat Flags

None. T-06-05 is mitigated: the draft is committed only by Done, stored values are inserted as rows and never snapped, `addHours` clamps at 23:30, and `parseHHMM` / `formatHHMM` are untouched.

## Device Checks Pending (plan 06-10)

Cancel leaves original times; Add hours at 22:00 adds 22:30-23:30 and is dimmed at 22:30; a stored 09:15 and a 24:00 end open selected and save unchanged; D2: Save readable in Light with Reduce Transparency on and with Liquid Glass Tinted.

## Next Phase Readiness

Ready for 06-04. EXP-05, EXP-06 and EXP-07 stay pending in REQUIREMENTS.md until plan 06-10.

## Self-Check: PASSED

- Created files exist: `ClickMe2026/Utils/AvailabilitySlotRules.swift`, `ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift`.
- Commits `af3ffe8` and `887b600` are on HEAD.
- Acceptance criteria for both tasks re-run and passing.
