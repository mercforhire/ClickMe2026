---
phase: quick-261110-nzy
plan: 01
subsystem: make-a-booking-calendar
tags: [accessibility, voiceover, swiftui, booking]
requires: [02-08]
provides: [CalendarDay.isFiller, Make a Booking filler cells hidden from VoiceOver]
affects: [02-UI-SPEC, 02-DEVICE-UAT-CHECKLIST]
tech-stack:
  added: []
  patterns: [accessibilityHidden on non-day grid cells]
key-files:
  created:
    - ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift
    - .planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md
    - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md
decisions:
  - "E1 (month-blank caption) not built: superseded by the 2026-11-10 parity decision; no day is ever blank, Android and Reschedule have no caption"
  - "C1 (chevron labels) already shipped in 1ddd0d0; only guarded as a regression"
metrics:
  tasks: 2
  completed: 2026-11-10
status: complete
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
plan_head_before: 68352078b14035b06aed28e6d1a4a812d77a1ec4
plan_head_after: 88c6a23a8ebeae95913e2386e33799c080d228f2
---

# Phase quick-261110-nzy Plan 01: Make a Booking calendar VoiceOver gap Summary

Make a Booking's grid-padding cells (dimmed previous/next-month numbers) are now hidden from VoiceOver through a testable `CalendarDay.isFiller` flag, so both client calendars and Android behave the same.

## Commits

- 4036dff: fix(quick-261110-nzy): hide Make a Booking filler cells from VoiceOver (02-UI-SPEC A1) (view model flag, card modifier, 3-row test suite)
- 88c6a23: docs(quick-261110-nzy): record the E1/A1/C1 resolution in 02-UI-SPEC and the device checklist

## Results

- `MakeABookingCalendarCellTests`: 3 tests passed, 0 warnings in the new file.
- Debug build: BUILD SUCCEEDED; 0 warnings for `MakeABookingCalendarCard.swift` and `MakeABookingViewModel.swift` (only the AppIntents metadata notice).
- Optional full regression (`-only-testing:ClickMe2026Tests`, skipping SignupSmokeTests and AuthSmokeTests): 247 tests in 29 suites passed (244 baseline plus 3).
- Simulator destination `id=E8F9FD72-750B-4888-8F47-91AE12B58F65` worked; no swap needed.
- `Localizable.xcstrings` and the Reschedule folder: no diff.
- Tracer gate: `<verify>` re-run end to end after the commit-ready state; passed, expanded to Task 2.

## Decisions

- **C1 (chevron labels):** already in code since 1ddd0d0 (`Previous month` / `Next month`). Unchanged; grep gates keep them.
- **E1 (month-blank caption): not built, superseded.** The 2026-11-10 user decision means days past the paid limit are never hidden or blanked, so "whole displayed month blank" cannot occur. Android has no such caption and 02-08 added none to Reschedule. If a caption for a month entirely past the limit is wanted, it is a new behavior for both iOS calendars and Android and belongs in a separate quick task.
- **A1:** re-targeted to the real non-day cells (grid padding). In-month days, past days and days past the paid limit remain focusable. `.disabled(...)` and the guarded tap closure are unchanged, so filler cells remain untappable.

## Cross-repo

No Android change needed (empty `Box` filler cells, chevron descriptions, no caption already). No backend change. Neither repo was touched.

## Deviations from Plan

None to the code. Procedural note: the 02-UI-SPEC and checklist annotations were applied with a single exact-match, assert-unique string replacement script rather than individual `Edit` calls; the result is the same scoped edits (16 insertions, 8 deletions), approval line still present once, no PLAN.md touched.

## Candidate follow-up (out of scope, not changed)

`generateDays(for:)` appends one trailing filler cell even when the last week is already full (`max(1, trailing)`), so a month ending on Saturday (February 2026, October 2026) gets an extra row with a lone dimmed "1". Visual and pre-existing; after this plan VoiceOver skips it. The new tests deliberately do not pin total grid length.

## Known Stubs

None.

## Threat Flags

None. Presentation-only change; the paid 6-day cap, `isSelectableSlot`, `book()` refusal and server 422 are untouched.

## Self-Check: PASSED

- FOUND: ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift
- FOUND commits 4036dff and 88c6a23 on main
