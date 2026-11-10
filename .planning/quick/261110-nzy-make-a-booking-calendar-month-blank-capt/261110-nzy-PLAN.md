---
phase: quick-261110-nzy
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift
  - ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift
  - .planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md
  - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md
autonomous: true
requirements:
  - QUICK-261110-nzy
  - BOOK-14

estimate:
  tokens: 26000
  raw_tokens: 26000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "With VoiceOver on, swiping through the Make a Booking calendar never lands on the dimmed previous-month or next-month numbers that pad the grid. Every day of the displayed month is still its own focusable element (02-UI-SPEC A1, matching the Reschedule calendar's Color.clear cells and Android's empty Box)"
    - "Past days of the displayed month stay focusable and read as dimmed. Days past the paid 6-day limit stay visible, tappable and announced, so the cap never blanks or hides an in-month day (user decision 2026-11-10, Android parity, 02-08 deviation 1)"
    - "The month chevrons on both client calendars read 'Previous month' and 'Next month' (02-UI-SPEC C1). They shipped in 1ddd0d0 and 9f85dc2 and this plan leaves them unchanged"
    - "Neither calendar grid gets a month-level caption. E1's trigger, a displayed month where every day is blank, cannot occur since the 2026-11-10 parity decision. 02-08 added none to Reschedule and Android has none. The resolution is written into 02-UI-SPEC section 4"
    - "Filler cells stay untappable: hiding them from VoiceOver changes only the accessibility tree, not the disabled state or the guarded tap action"
    - "No new user-facing string: Localizable.xcstrings is unchanged"
    - "Debug build succeeds with no warning in MakeABookingCalendarCard.swift or MakeABookingViewModel.swift, and the MakeABookingCalendarCellTests suite passes (at least 3 tests)"
  artifacts:
    - path: "ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift"
      provides: "CalendarDay.isFiller: true only for the grid-padding cells generateDays(for:) emits with no date"
      contains: "var isFiller: Bool"
    - path: "ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift"
      provides: "Filler cells removed from the accessibility tree; chevron labels kept"
      contains: ".accessibilityHidden(item.isFiller)"
    - path: "ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift"
      provides: "Rows pinning which cells are fillers, that every in-month day stays announced, and that days past the paid limit are never fillers"
      contains: "@Suite(\"MakeABooking calendar cells\")"
    - path: ".planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md"
      provides: "E1/A1/C1 resolution for both calendars in section 4, with pointers from the copy row, the checker rows and approval FLAG 1"
      contains: "261110-nzy"
    - path: ".planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md"
      provides: "VoiceOver expectations added to item 7 (BOOK-14) for the Phase 02 device UAT"
      contains: "261110-nzy"
  key_links:
    - from: "MakeABookingCalendarCard.calendarCell(item:)"
      to: "MakeABookingViewModel.CalendarDay.isFiller"
      via: "the cell Button is hidden from VoiceOver exactly when the day has no date; .disabled and the tap guard are unchanged"
      pattern: "accessibilityHidden\\(item\\.isFiller\\)"
    - from: "ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift"
      to: "MakeABookingViewModel.generateDays(for:)"
      via: "rows read the real grid the card renders, through the preview-seam initializer (no API)"
      pattern: "generateDays\\(for:"
---

<objective>
Close the Make a Booking half of the 02-UI-SPEC deltas E1, A1 and C1 (section 4 "Plan ownership", Copywriting Contract rows for the Make a Booking calendar caption and the month chevrons, UI Considerations E1/A1/C1, approval FLAG 1). Do this against the live tree, mirroring what 02-08 did for the Reschedule calendar so both client calendars behave the same.

Purpose: the spec marks these deltas as an open gap with no owning plan, and that gap has to be closed before the Phase 02 device UAT. A VoiceOver user should hear only this month's days, never the filler numbers from the next or previous month.

Output: one accessibility change in `MakeABookingCalendarCard.swift`, backed by a testable `CalendarDay.isFiller` flag and a new test suite. The plan also records the resolution in 02-UI-SPEC and adds a VoiceOver step to the device checklist.

## What the live tree shows (planning-time observation at HEAD b4fdbde, 2026-11-10)

The UI-SPEC text for these rows was written on 2026-11-09, before the 02-08 rework (`1ddd0d0`, `9f85dc2`). The code has moved on since, so each delta is planned from the code as it is now.

- **C1 (month-arrow labels): already shipped.** `MakeABookingCalendarCard.swift` has `.accessibilityLabel("Previous month")` at L41 and `.accessibilityLabel("Next month")` at L59, added in `1ddd0d0` (02-08-SUMMARY, auto-fix 2). `RescheduleCalendarCard.swift` has the same labels at L45 and L61. Both strings are already in `Localizable.xcstrings`. Nothing to build here, only a regression gate.
- **E1 (month-blank caption): not built, recorded as superseded.** The 2026-11-10 user decision, made at the 02-08 tracer gate and recorded in STATE.md and 02-08-SUMMARY deviation 1, is that days past the paid 6-day limit are never hidden or blanked. Their slots dim, and the slots card shows the fixed note "Paid sessions can be booked up to 6 days ahead." for a paid topic. Since then no day cell on either client calendar is ever blank, so the trigger "every day of the displayed month is blank" cannot occur. 02-08 called the caption moot and added none to Reschedule. Android's `MakeABookingCalendarCard.kt` has no month-level caption. The user also considered and dropped an extra on-selection warning in favor of exact Android parity. Two other things argue against adding the caption. On a month that is entirely past the limit, it would repeat the fixed note in near-identical words (`BookingErrorMapper.longLeadMessage`). It would also make the two calendars differ, which this task forbids. **This follows the user's locked decision (the UI-SPEC row, written earlier, said otherwise).** If the user does want a caption whenever the displayed month is entirely past the limit, that is a new behavior for both calendars and Android, and belongs in a separate quick task.
- **A1 (blank cells hidden from VoiceOver): re-targeted to the cells that are actually non-days.** `generateDays(for:)` (MakeABookingViewModel L694-725) pads the grid with `CalendarDay(label: "<n>", date: nil, isCurrentMonth: false)`. The card draws each one as a disabled `Button` showing the adjacent month's day number at 35% opacity (card L100-125). VoiceOver focuses these cells and reads, for example, "29, dimmed, button" while the user browses November. That is the "empty disabled button" A1 forbids. Reschedule draws its padding as `Color.clear` (RescheduleCalendarCard L84), which VoiceOver skips. Android draws an empty `Box` with no semantics (MakeABookingCalendarCard.kt L133-146), which TalkBack skips. Hiding the filler cells makes both iOS calendars and Android match. In-month days, including past days and days past the paid limit, stay focusable, as on Reschedule (dimmed, disabled `Button`) and Android (`selectable(enabled = false)` with a content description).

## Cross-repo

- **Android (`../ClickMe_Android`): no matching change needed.** Its filler cells are an empty `Box`, its chevrons have `make_a_booking_previous_month` / `make_a_booking_next_month` content descriptions, and it has no month-level caption. iOS is catching up to Android here. Do not edit the Android repo.
- **Backend:** none. No API, contract or schema change.

## Source coverage audit

| Source | ID | Item | Plan / task | Status |
|--------|----|------|-------------|--------|
| GOAL | quick | Close the Make a Booking E1/A1/C1 gap, both calendars behaving the same | 01 / T1, T2 | COVERED |
| CONTEXT | 2026-11-10 parity decision (02-08 deviation 1) | Days past the cap never hidden or blanked; Android parity | 01 / T1 (test row 3), T2 | COVERED |
| SPEC | 02-UI-SPEC C1 | Chevron labels `Previous month` / `Next month` | already in code (1ddd0d0); T1 regression gate; T2 records it | COVERED |
| SPEC | 02-UI-SPEC A1 | Non-day cells hidden from VoiceOver, still untappable | 01 / T1 | COVERED |
| SPEC | 02-UI-SPEC E1 / Copywriting row (calendar caption) | Month-blank caption with the long-lead copy | 01 / T2 records it as superseded; T1 negative gate keeps the card caption-free | RESOLVED: superseded by the locked 2026-11-10 user decision (trigger unreachable, not on Android, not on Reschedule) |
| REQ | BOOK-14 | Paid picker cap (complete); this plan touches only its picker's accessibility contract | 01 / T1 | COVERED (no behavior change to the cap) |
| TASK | strings | New strings go through the String Catalog | none added (accessibilityHidden carries no text) | COVERED |
| TASK | Android note | State whether ../ClickMe_Android needs a change | this objective, "Cross-repo" | COVERED |

## Observed, out of scope (do not fix here)

`generateDays(for:)` appends one trailing filler cell even when the last week is already full (`for i in 1 ... max(1, trailing)`). A month whose last day is a Saturday, such as February 2026 or October 2026, therefore gets an extra row holding a lone dimmed "1". This is visual and pre-existing (calendar grid geometry is out of contract in 02-UI-SPEC). After this plan VoiceOver skips that cell too. Report it in the SUMMARY as a candidate follow-up and do not change it.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@.claude/CLAUDE.md
@.planning/phases/02-shared-ios-plumbing/02-08-SUMMARY.md
@.planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md
@ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift
@ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift

<interfaces>
From `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` (the module default isolation is MainActor, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so the nested struct is main-actor isolated and test suites must be `@MainActor`):
- `let calendar = Calendar.current` (L199)
- `var latestBookableStart: Date?` (L366): non-nil exactly when the selected topic is paid
- `struct CalendarDay { let label: String; let date: Date?; let isCurrentMonth: Bool }` (L688-692)
- `func generateDays(for month: Date) -> [CalendarDay]` (L694-725): leading and trailing filler cells have `date: nil, isCurrentMonth: false`; in-month cells have a date and `isCurrentMonth: true`
- Preview-seam init (L224): `init(expertId: UUID = UUID(), expertName:, expertTitle:, expertImageURL:, topics: [BookingTopic], availabilityByDate: = [:], expertTimezone: = nil, paymentMethodsAvailability: = .available, api: ClickMeAPI = .shared)`; it sets `selectedTopic = topics.first`

From `ClickMe2026/Utils/PaidBookingWindow.swift`: `nonisolated enum PaidBookingWindow` with `static func isDayBeyond(_ day: Date, latestStart: Date?, calendar: Calendar) -> Bool`.

From `ClickMe2026Tests/Utils/PaidBookingWindowTests.swift` L77-98: `BookingTopic(id:title:durationMinutes:description:priceAmount:currency:isFree:)` and the `makeViewModel(selecting:)` pattern (preview seam, no API, no MockURLProtocol).
</interfaces>
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Hide the Make a Booking filler cells from VoiceOver, end to end (A1)</name>
  <files>ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift, ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift, ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift</files>
  <read_first>
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift (whole file, 127 lines)
    - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift L360-382 and L678-725 only (do not read the whole 842-line file)
    - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift L78-120 (the counterpart: Color.clear padding, dimmed disabled day Buttons)
    - ClickMe2026Tests/Utils/PaidBookingWindowTests.swift L1-110 (topic fixtures, preview-seam view model, suite style)
  </read_first>
  <action>
This is the single path through every layer this plan touches: view model flag, then view modifier, then tests, then the build.

1. View model (`MakeABookingViewModel.swift`). Inside the nested `CalendarDay` struct, add a computed `var isFiller: Bool` that returns true exactly when `date` is nil. Give it a `///` doc comment saying why: it marks a cell that only pads the grid with a day number from the previous or next month. Such a cell is never tappable, and the calendar card hides it from VoiceOver (02-UI-SPEC A1), like the Reschedule calendar's empty cells and Android's empty `Box`. Do not change `generateDays(for:)`. Its trailing `max(1, trailing)` cell is a pre-existing visual quirk outside this task (see the objective). Do not add anything else to this 842-line file.

2. Calendar card (`MakeABookingCalendarCard.swift`). In `calendarCell(item:)`, add `.accessibilityHidden(item.isFiller)` after the existing `.disabled(...)` modifier. Keep `.disabled(...)`, the guarded tap closure (`if let d = item.date, isCurrentMonth, !isPast`) and all visuals exactly as they are. Filler cells still render their dimmed adjacent-month numbers, because grid geometry and styling are out of contract per 02-UI-SPEC "Out of contract: pre-existing layout". Past in-month days and days past the paid 6-day limit must stay focusable. That follows the user's 2026-11-10 Android-parity decision that no day is ever hidden or blanked, and it matches Reschedule, where non-bookable days are dimmed disabled Buttons that VoiceOver still reads. Leave both chevron buttons and their `Previous month` / `Next month` labels untouched (C1 already shipped in 1ddd0d0). Do not add any caption, footer or extra `Text` under the grid. E1 is resolved as superseded by that same user decision: its trigger can no longer occur, Android has no such caption, and 02-08 added none to Reschedule. Do not edit `RescheduleCalendarCard.swift` or `RescheduleView.swift`, which already behave the way this task makes Make a Booking behave.

3. Tests: create `ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift`. Start it with the standard Xcode header block, then `import Foundation`, `import Testing` and `@testable import ClickMe2026`. Declare `@MainActor @Suite("MakeABooking calendar cells") struct MakeABookingCalendarCellTests`. Build the view model through the preview-seam initializer with a free topic first and a paid topic second, copying the `BookingTopic` fixtures and the `makeViewModel(selecting:)` pattern from `PaidBookingWindowTests.ViewModelRows`. The suite never reaches the API, so do not use `APITestFactory` or `MockURLProtocol` (the STATE.md 02-07 rule on suites that never call the API). Build every month date with the view model's own `calendar`, so the rows hold in any device time zone. Use `@Test("...")` display names. Write these rows:
   - "filler cells are exactly the cells with no date": for 2026-11, 2026-02 and 2026-10, every cell has `isFiller == (date == nil)`, every filler has `isCurrentMonth == false`, and every non-filler has `isCurrentMonth == true`. February and October 2026 end on a Saturday and so carry the extra trailing cell, which must count as a filler.
   - "every day of the displayed month stays announced": for the same three months, the non-filler cells' dates are, in order, day 1 through the month's day count (from `calendar.range(of: .day, in: .month, for:)`).
   - "days past the paid limit are never fillers": select the paid topic and `#require` that `latestBookableStart` is non-nil. Generate the month two months after `Date()`. `#expect` that every in-month day satisfies `PaidBookingWindow.isDayBeyond(_:latestStart:calendar:)`, which proves the row really covers past-limit days. Then `#expect` that none of those days is a filler and that the count of non-fillers equals that month's day count.
   Do not assert the total grid length, because that would pin the trailing-cell quirk.

4. Build and test with the commands in `<verify>`, which reuse the simulator destination that worked in quick 261110-mmr. If that simulator id is not available, swap only the destination to `-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'` and record the swap in the SUMMARY. Xcode may rewrite `ClickMe2026/Localizable.xcstrings` during the build. This task adds no user-facing text, so if `git diff --quiet -- ClickMe2026/Localizable.xcstrings` reports a change, restore the file with `git checkout -- ClickMe2026/Localizable.xcstrings` and note it in the SUMMARY.

5. Commit the three Swift files only, as `fix(quick-261110-nzy): hide Make a Booking filler cells from VoiceOver (02-UI-SPEC A1)`.
  </action>
  <verify>
    <automated>xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'id=E8F9FD72-750B-4888-8F47-91AE12B58F65' -only-testing:ClickMe2026Tests/MakeABookingCalendarCellTests 2>&1 | tee /tmp/261110-nzy-t1.log | tail -30 && grep -Eq 'Test run with ([3-9]|[1-9][0-9]) tests? in [0-9]+ suites? passed' /tmp/261110-nzy-t1.log && test "$(grep 'MakeABookingCalendarCellTests\.swift' /tmp/261110-nzy-t1.log | grep -c 'warning:')" -eq 0</automated>
    <automated>xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'id=E8F9FD72-750B-4888-8F47-91AE12B58F65' 2>&1 | tee /tmp/261110-nzy-build.log | tail -5 && grep -q 'BUILD SUCCEEDED' /tmp/261110-nzy-build.log && test "$(grep -E 'MakeABookingCalendarCard\.swift|MakeABookingViewModel\.swift' /tmp/261110-nzy-build.log | grep -c 'warning:')" -eq 0</automated>
    <automated>test "$(grep -v '^[[:space:]]*//' 'ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift' | grep -c 'accessibilityHidden(item.isFiller)')" -eq 1 && test "$(grep -v '^[[:space:]]*//' 'ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift' | grep -c 'var isFiller: Bool')" -eq 1</automated>
    <automated>test "$(grep -c 'accessibilityLabel("Previous month")' 'ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift')" -eq 1 && test "$(grep -c 'accessibilityLabel("Next month")' 'ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift')" -eq 1 && test "$(grep -v '^[[:space:]]*//' 'ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift' | grep -c 'BookingErrorMapper')" -eq 0 && git diff --quiet HEAD -- 'ClickMe2026/Views/Screens/Client Mode/Reschedule' ClickMe2026/Localizable.xcstrings</automated>
    <human-check>VoiceOver on a simulator or device is checked at the Phase 02 device UAT. Task 2 adds the steps to 02-DEVICE-UAT-CHECKLIST.md item 7, so nothing blocks here.</human-check>
  </verify>
  <acceptance_criteria>
    - Deliverable gates, each 0 at HEAD b4fdbde (baselines measured at planning time): `accessibilityHidden(item.isFiller)` appears exactly once in non-comment lines of the card, and `var isFiller: Bool` exactly once in non-comment lines of the view model.
    - Regression guards, which already pass at HEAD and must keep passing: the card has exactly one `accessibilityLabel("Previous month")` and one `accessibilityLabel("Next month")` (baseline 1 each). The card's non-comment lines reference the error-copy mapper 0 times (baseline 0), so no month caption crept in. Nothing under `ClickMe2026/Views/Screens/Client Mode/Reschedule` changed, and `Localizable.xcstrings` has no diff.
    - `MakeABookingCalendarCellTests` reports at least 3 passing tests, with no warning in the new test file.
    - Debug `BUILD SUCCEEDED`, with 0 `warning:` lines for `MakeABookingCalendarCard.swift` and `MakeABookingViewModel.swift`. The baseline is 0: the last full build, in quick 261110-mmr, reported only the `describe` warning in `UserManager.swift`.
  </acceptance_criteria>
  <done>Filler cells in the Make a Booking grid are hidden from VoiceOver and still untappable. Every in-month day, including past days and days past the paid limit, is still a focusable element. Both chevron labels are unchanged and no caption was added. The new suite passes, the build is clean for the touched files, and the three Swift files are committed.</done>
</task>

<task type="auto">
  <name>Task 2: Record the E1/A1/C1 resolution in 02-UI-SPEC and add the VoiceOver step to the device checklist</name>
  <files>.planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md, .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md</files>
  <read_first>
    - .planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md L160-168, L276-299, L362-370 and L418-428 only
    - .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md L111-126 (item 7, BOOK-14)
  </read_first>
  <action>
Use scoped `Edit` calls only; never rewrite either file with `Write`. These are annotations that record outcomes. Do not change the spec's approval status, any Dimension verdict, or any row this plan does not own. Do not edit any executed phase PLAN.md.

02-UI-SPEC.md:
1. Section 4 "Plan ownership" table. Replace the owner cell of the Reschedule row, which still says 02-08 is not yet executed, with this text: 02-08 (executed); chevron labels shipped in 9f85dc2; the month-blank caption and blank-cell hiding are moot because no day cell is ever blank or hidden (user decision 2026-11-10, Android parity, 02-08-SUMMARY deviation 1); its padding cells are Color.clear, which VoiceOver skips. Replace the owner cell of the Make a Booking row, which still reports the gap as unowned, with this text: quick 261110-nzy (2026-11-10); chevron labels already shipped in 1ddd0d0; padding cells (adjacent-month numbers) hidden from VoiceOver; month-blank caption not built, moot for the same reason as Reschedule.
2. Directly under that table, add a short paragraph headed `**Resolution (quick 261110-nzy, 2026-11-10).**` that says five things. First, since the user's parity decision, days past the paid limit stay visible and tappable on both client calendars and only their slots dim. Second, the "Whole displayed month is blank" row of the empty-states table above can therefore no longer occur, so neither calendar shows a month-level caption: Android shows none, and the slots card's fixed paid note already explains a paid month. Third, accessibility item 1 now applies to the grid-padding cells, the only non-day cells, which are hidden from VoiceOver on both calendars. Fourth, item 2, the chevron labels, is shipped on both. Fifth, W1-9, W1-10 and the section 4 limit table stay superseded as recorded in device checklist item 7, and their full rewrite stays with the pending 02-UI-SPEC revision noted in STATE.md.
3. Copywriting Contract. In the row for the Make a Booking calendar card caption (paid topic, every day of the displayed month blank), replace its bold "not yet in code" note with: **Not built: superseded by the 2026-11-10 parity decision (no day is ever blank); see section 4 resolution, quick 261110-nzy**. In the row for the month-chevron accessibility labels, append: Shipped on both calendars (1ddd0d0, 9f85dc2); quick 261110-nzy.
4. Checker rows E1, A1 and C1. Append `Resolved by quick 261110-nzy (see section 4 resolution).` to the end of each row's last cell.
5. Approval FLAG 1, the Dimension 2 flag about the Make a Booking half of E1, A1 and C1. Append: Resolved by quick 261110-nzy (2026-11-10).

02-DEVICE-UAT-CHECKLIST.md item 7 (BOOK-14). Insert a block immediately before that item's `Result:` line, headed `Expected, VoiceOver (02-UI-SPEC A1, C1; quick 261110-nzy):`. It has four bullets:
- With VoiceOver on, swiping through the Make a Booking grid reads only the displayed month's days; the dimmed previous-month and next-month numbers are skipped.
- Past days read as dimmed, and days past the paid limit read normally.
- The chevrons read "Previous month" and "Next month".
- The client Reschedule calendar behaves the same.

Leave the item's Status line, Steps and `Result:` untouched.

Commit both files as `docs(quick-261110-nzy): record the E1/A1/C1 resolution in 02-UI-SPEC and the device checklist`.
  </action>
  <verify>
    <automated>test "$(grep -c '261110-nzy' .planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md)" -ge 6 && test "$(grep -c '261110-nzy' .planning/phases/02-shared-ios-plumbing/02-DEVICE-UAT-CHECKLIST.md)" -ge 1 && test "$(grep -c '^\*\*Approval:\*\* approved 2026-11-10' .planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md)" -eq 1 && PHASE_STATUS="$(git status --porcelain -- .planning/phases)" && test "$(printf '%s\n' "$PHASE_STATUS" | grep -c -- '-PLAN\.md')" -eq 0</automated>
  </verify>
  <acceptance_criteria>
    - `261110-nzy` appears at least 6 times in 02-UI-SPEC.md (baseline 0: Make a Booking owner cell, resolution heading, caption copy row, chevron copy row, E1, A1, C1 and FLAG 1, which is 8 when complete) and at least once in 02-DEVICE-UAT-CHECKLIST.md (baseline 0).
    - Regression guard (baseline 1): the approval line `**Approval:** approved 2026-11-10` is still present exactly once.
    - No PLAN.md file under `.planning/phases` is modified.
  </acceptance_criteria>
  <done>02-UI-SPEC no longer reports the Make a Booking half of E1/A1/C1 as unowned. Both calendars' rows record what shipped and why E1 was not built. Device checklist item 7 tells the tester what VoiceOver should and should not read. Both docs are committed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | UI-only change on an existing screen: no network call, no new input, no stored data. The paid 6-day cap (client refusal plus server 422) is untouched |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-quick-261110-nzy-01 | Tampering | MakeABookingCalendarCard.calendarCell(item:) | low | mitigate | Hiding a cell from VoiceOver removes it only from the accessibility tree. `.disabled(...)` and the guarded tap closure stay, so a filler cell can never set `selectedDate` (code review of the diff; Task 1 keeps both modifiers) |
| T-quick-261110-nzy-02 | Denial of service | VoiceOver booking path on Make a Booking | low | mitigate | `isFiller` is `date == nil` only. Test rows pin that every in-month day, and every day past the paid limit, is never a filler, so no bookable day can disappear from VoiceOver |
| T-quick-261110-nzy-03 | Elevation of privilege | paid 6-day cap (T-02-15) | low | accept | No change to `isSelectableSlot(_:)`, `book()`'s local refusal or the server's 422 backstop. The calendar change is presentation-only |
| T-quick-261110-nzy-SC | Tampering | npm/pip/cargo installs | low | accept | No packages are installed or upgraded in this plan |
</threat_model>

<verification>
- Task 1 and Task 2 `<automated>` commands all exit 0.
- Optional full regression, run only if time allows, using the 261110-mmr command (`xcodebuild test ... -only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/SignupSmokeTests -skip-testing:ClickMe2026Tests/AuthSmokeTests`): expect at least 247 tests passed (the 261110-mmr baseline of 244 plus this plan's 3).
- `git log --oneline -2` shows the `fix(quick-261110-nzy)` and `docs(quick-261110-nzy)` commits. `git show --stat` of each touches only that task's files.
- No file in `../ClickMe_Android` or `../ClickMe2026 Backend` changed.
</verification>

<success_criteria>
- A VoiceOver user on Make a Booking hears only the displayed month's days and the labeled chevrons, the same as on client Reschedule and on Android.
- No calendar day is hidden or blanked by the paid cap, and no month caption is added, per the user's 2026-11-10 parity decision.
- Clean Debug build for the touched files, a new test suite with at least 3 passing rows, and no new string.
- 02-UI-SPEC and the device checklist record the resolution, so the Phase 02 UAT and UI review no longer flag the gap.
- The SUMMARY states that no Android change is needed, records E1 as superseded with the override path (a separate quick task covering both calendars and Android), and lists the trailing-cell quirk as a candidate follow-up.
</success_criteria>

<output>
Create `.planning/quick/261110-nzy-make-a-booking-calendar-month-blank-capt/261110-nzy-SUMMARY.md` when done
</output>
