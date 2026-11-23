# Phase 03 — UI Review (re-audit)

**Audited:** 2026-11-22 (re-audit of the 2026-11-11 review against current code)
**Baseline:** 03-UI-SPEC.md (approved, force-approved 2026-11-10)
**Screenshots:** not captured (native SwiftUI app, no web dev server; code-only audit of source and #Preview blocks, no build or simulator run)
**Interaction captures:** off (workflow.ui_interaction_capture is false). All interaction findings are code-derived.

**Changed since the 2026-11-11 review:** `ToastHost.swift` (unchanged in Phase 03 scope, still the same geometry), `HomeClientView.swift` / `HomeExpertView.swift` (ToastHost wiring and route stubs), `BookingSummaryView.swift` and `BookingSummaryViewModel.swift` (ID line and Leave a Review gate now via `BookingShortID`, commit 9e95cf3 area, 2026-11-16), `UpcomingBookingView.swift` (Cancel and Reschedule now gated by `UpcomingActionPolicy` in a 60 s timeline, D-13), `ExpertBookingSummaryView.swift` (Calendar and ID work from 2026-11-16/17), and the client Session Summary Message Expert change (quick-261122-r2o, commit a603a2a, which is not a Phase 03 surface and was not re-scored).

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract strings present (Accept New Time, Decline New Time, No past bookings yet, DECLINE NOTE, Review Cancellation, Back to Booking, Open in provider). Expert Booking Summary reschedule buttons still read "Accept" / "Decline", not the contract labels (verify whether they are the same card). |
| 2. Visuals | 3/4 | Focal points match the contract (Join or Open in provider as accent, amber case D block, Past empty state). Toast chip is a 20 pt rounded rectangle, not the capsule the spec asks for; Skype timer and remaining chip still have no accessibility value. |
| 3. Color | 3/4 | Accent kept off money and warnings. Decline New Time still uses raw `Color.red` (not `Brand.destructive`) on the response card and the expert summary. Hardcoded avatar fallback literal remains in `CancellationBookingSummary.swift`. |
| 4. Typography | 2/4 | Declared set is 12/15/16/22 and Regular/Semibold. `.caption2` (11 pt) still used in `RescheduleResponseCard.swift` (lines 104, 119, 181), `ExpertBookingSummaryView.swift` (583, 645, 702) and on Upcoming prep notes and topic card. `.medium` weight still used in `SkypeSessionHero.swift:44`, `MeetingCallView.swift:170` and `UpcomingBookingStatusRow.swift:49`. |
| 5. Spacing | 3/4 | New blocks sit on the 4/8/16/24 grid and the Join card is 52 pt with a 16 pt radius as specified. Response-card buttons still use a 10 pt radius (off the 12/16 rule) and the expert reschedule Decline and Accept buttons are `frame(height: 42)` (ExpertBookingSummaryView.swift:663, 688), below the 44 pt minimum the spec declares. |
| 6. Experience Design | 3/4 | State coverage strong: 60 s TimelineViews on Join, Open, Cancel and Reschedule visibility, in-flight disable, case C to D re-check at confirm, toast survives pops, Keep Booking one-level pop. Toast still hardcodes a 49 pt tab bar offset and ignores the keyboard; Skype layout still has no overtime banner (K2). |

**Overall: 17/24** (unchanged from 2026-11-11; no pillar moved up, and two prior deviations remain open)

---

## Prior Findings: Status

| # | Prior finding (2026-11-11) | Status | Evidence |
|---|---------------------------|--------|----------|
| 1 | Typography: `.caption2` and `.medium` outside declared set | Still open | RescheduleResponseCard.swift:104,119,181; ExpertBookingSummaryView.swift:583,645,702; SkypeSessionHero.swift:44; MeetingCallView.swift:170 |
| 2 | Toast placement hardcoded (tabBarHeight 49), not keyboard-aware, shape is rounded rect not capsule | Still open | ToastHost.swift: `private let tabBarHeight: CGFloat = 49`, `RoundedRectangle(cornerRadius: 20)`, no safeAreaInset, no keyboard handling |
| 3 | Response-card buttons 10 pt radius, Decline uses `Color.red` | Still open | RescheduleResponseCard.swift:138-147, 166-168 |
| 3b | Expert reschedule buttons 42 pt | Still open | ExpertBookingSummaryView.swift:663, 688 (the 44 pt values at 343 and 368 are a different pair of buttons) |
| 4 | Skype timer and remaining chip lack accessibility label or updatesFrequently | Still open | No accessibilityLabel or updatesFrequently in SkypeSessionHero.swift or MeetingCallView.swift |
| 5 | Toast chip tappable with no accessible dismiss action | Still open | ToastHost.swift uses `.onTapGesture` and `.accessibilityAddTraits(.isStaticText)` only; no `.accessibilityAction` |
| 6 | Skype focal point: `Open in {provider}` button, verify on device | Still open (not verified in code) | Skype screen renders existing SkypeLinkActions; no `Open in` on MeetingCallView |
| 7 | Skype layout has no overtime banner (K2) | Still open (known, accepted by contract) | Unchanged |
| - | Open in {provider} button on Upcoming details (CALL-08) | Resolved | UpcomingBookingJoinCard.swift:88-100: `Text(provider.openButtonTitle)`, 52 pt, 16 pt radius, opacity 0.55 when disabled |
| - | Cancel hidden after end (BOOK-13) | Resolved, extended | UpcomingBookingView.swift:268-280 uses `UpcomingActionPolicy.canShowCancel` in a 60 s TimelineView; Reschedule is now gated the same way |
| - | Cancel confirm comment counter `{n}/450` | Resolved | CancellationCommentField.swift:58 `"\(comment.utf16.count)/\(CancelReasonComposer.commentLimit)"` (confirm the limit constant is 450) |
| - | Booking Summary ID line, Leave a Review gate, DECLINE NOTE card | Resolved | BookingSummaryViewModel.swift:57 `showsLeaveReview`, :138 `BookingShortID.label`; BookingSummaryDeclineNoteCard.swift:25 |
| - | Past empty state copy and no button | Resolved | PastEmptyState.swift:28-42 (title2 Semibold, callout body, 40 pt padding) |
| - | Expert Join Session 52 pt, 12 pt radius, Message Client outlined while Join shown | Resolved | ExpertBookingSummaryView.swift:299, 778-834 |
| - | Client cancel case D warning block, preview-changed notice | Resolved | CancellationBookingSummary.swift:129-147; ClientCancellationView.swift:216-218 |
| - | Toast mounted on client and expert shells | Resolved | HomeClientView.swift:126, HomeExpertView.swift:99 |

---

## Top 3 Priority Fixes

1. **Expert reschedule decision buttons are below the 44 pt minimum and carry unverified labels** — A dual-role user answering a client's reschedule proposal from the expert summary gets 42 pt targets, and the spec says no control stays under 44 pt. Users can mis-tap Decline. Fix: in `ExpertBookingSummaryView.swift` change `frame(height: 42)` at lines 663 and 688 to `minHeight: 44`; confirm whether the labels "Accept" and "Decline" (lines 659, 683) should be "Accept New Time" and "Decline New Time" per the copy contract, and align them.

2. **Toast position and shape are guesses** — `ToastHost.swift` pins the toast with a fixed 49 pt tab-bar offset and a 20 pt rounded rectangle, and it does not respond to the keyboard. On any screen where the tab bar is hidden, or with the keyboard up, the toast can sit in the wrong place or cover a control. Fix: replace the fixed padding with `.safeAreaInset(edge: .bottom)` and use `Capsule()` for single-line messages (keep the rounded rectangle for wrapped text). Add `.accessibilityAction(.default) { center.dismiss() }` so VoiceOver users can dismiss it.

3. **Type and color drift on the response card and Skype hero** — `.caption2` (11 pt) and `.medium` weight sit outside the declared 4-size, 2-weight set, and Decline New Time uses `Color.red.opacity(...)` where the contract names `Brand.destructive`. The response-card buttons also keep a 10 pt radius. Fix: move FROM/TO and note labels to `.brand(.caption, weight: .semibold)`; move the Skype status line and range to `.brand(.caption, weight: .regular)`; replace the `Color.red` tints with `Brand.destructive`; set the button radius to 12 in `RescheduleResponseCard.swift`.

---

## Further Items (lower priority)

4. Skype timer (`SkypeSessionHero.swift:48`) and the remaining chip (`:54`) have no accessibility label. Add `.accessibilityLabel` such as "Starts in 4 minutes" and `.updatesFrequently` on the timer.
5. Skype focal point: confirm on device that an accent `Open in {provider}` affordance is shown on the Skype/Zoom session screen, or record the deviation in the contract.
6. K2: the Skype layout still has no overtime banner. Revisit only if the user asks.
7. Hardcoded `Color(red: 0.12, green: 0.18, blue: 0.14)` avatar fallback in `CancellationBookingSummary.swift` (legacy cancel palette; leave unless the cancel palette is unified).
8. Device-only backstops (L2, L3, D2 to D4) remain unverified here and belong to the UAT checklist (03-DEVICE-UAT-CHECKLIST.md).

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

Matches the contract:
- `RescheduleResponseCard.swift`: "Expert requested a new time", "You proposed a new time", "Expert's message", "Accept New Time", "Decline New Time", "Awaiting expert's response".
- `PastEmptyState.swift`: "No past bookings yet" and "Completed, cancelled and missed sessions will show up here."
- `BookingSummaryDeclineNoteCard.swift:25`: "DECLINE NOTE".
- `ClientCancellationView.swift:91`: "Review Cancellation"; `BookingSummaryView.swift:130` and `UpcomingBookingView.swift:129`: "Back to Booking".
- `ExternalMeetingProvider.swift`: "Open Meeting" fallback for unrecognized hosts, with the provider title otherwise.

Gaps:
- `ExpertBookingSummaryView.swift:659, 683`: the reschedule action buttons read "Decline" and "Accept". This is not the response card contract label. Verify whether this is the expert entry point of the shared card; if so, the copy must match.

### Pillar 2: Visuals (3/4)

- Focal points follow the contract (see the Focal Points table). The Join card is 52 pt, accent at full opacity when enabled and 55% with no glow when closed.
- Accessibility is good on the response card (proposed time in button labels, container and header trait) and on the copy button.
- Toast chip: 20 pt rounded rectangle, not a capsule (Fix 2).
- Skype hero: no accessibility grouping on the timer or chip (item 4).

### Pillar 3: Color (3/4)

- Accent stays on join buttons, Accept New Time, the toast stroke and the outlined Message Client. Money lines are neutral. Orange is used only for warnings.
- Deviation: `Color.red.opacity(0.95/0.10/0.45)` on Decline New Time in `RescheduleResponseCard.swift:138-147` and `ExpertBookingSummaryView.swift:366-373, 661-672`. The contract names `Brand.destructive`.
- Deviation: hardcoded avatar fallback literal in `CancellationBookingSummary.swift`.

### Pillar 4: Typography (2/4)

Declared set: 12/15/16/22 pt and Regular/Semibold.

Observed outside it, on Phase 03 surfaces (current grep counts 17 `caption2` or `medium` hits across the Booking Summary, Upcoming, Cancellation, My Bookings and Calling folders):
- `.caption2` Semibold: FROM/TO labels and note labels in `RescheduleResponseCard.swift:104, 119, 181`; time and note blocks in `ExpertBookingSummaryView.swift:583, 645, 702`; `UpcomingBookingPrepNotesCard.swift:24`; `UpcomingBookingTopicCard.swift:20` (the last two are pre-existing and out of contract for Phase 03 only if untouched).
- `.medium` weight: `SkypeSessionHero.swift:44`, `MeetingCallView.swift:170`, `UpcomingBookingStatusRow.swift:49`, `UpcomingBookingDateTimeRow.swift:31`. This is a third weight.
- Skype timer is `.system(.title2, design: .monospaced)` as declared (D-08); it is correct.

### Pillar 5: Spacing (3/4)

- On grid: decline note card (16 padding, 8 gap), warning block (16 padding, 16 radius, 10 icon gap), Past empty state (40 side padding, 28 section spacing), toast (16/8 padding, 24 side margin), Open in provider button (52 pt, 16 pt radius).
- Deviation: response-card buttons 10 pt radius (`RescheduleResponseCard.swift:143, 168`), off the 12/16 rule for new controls.
- Deviation: expert reschedule buttons `frame(height: 42)` at `ExpertBookingSummaryView.swift:663, 688`, below the 44 pt minimum.
- Response card buttons are `minHeight: 44` (lines 141, 166), which meets the exception.

### Pillar 6: Experience Design (3/4)

Covered well:
- Loading: Accept and Decline disable with an in-button `ProgressView` while in flight.
- Time-dependence: `TimelineView(.periodic(from: .now, by: 60))` on Join, Open, Cancel and Reschedule visibility (`UpcomingBookingView.swift:238, 260, 272`), the cancel preview and expert Join.
- Cancel: case C to D change at confirm blocks submit and shows the preview-changed notice (`ClientCancellationView.swift:216`).
- Toasts: `ToastCenter` is a shared singleton hosted at the client and expert shells, posts a VoiceOver announcement, replaces the current toast, and uses a 4 s timer keyed by id.
- Errors: alerts with "Review Cancellation" and "Back to Booking" dismiss buttons (cancel role, no retry).

Gaps:
- Toast is not keyboard-aware and hardcodes the tab-bar height (Fix 2). No `reduceMotion` branch; the spec accepts fade-only, so this is acceptable.
- Skype timer and chip are not accessible values (item 4).
- Skype layout has no overtime banner (K2, known).
- The `ExpertBookingSummaryView` Decline and Accept controls sit at 42 pt on a critical decision (Fix 1).
- Device-only backstops remain unverified here.

---

## Registry Safety

Not applicable: no `components.json`, no third-party registries.

---

## Files Audited

- /Users/LeonChen/Documents/ClickMe2026/.planning/phases/03-booked-sessions-and-joining/03-UI-SPEC.md (lines 1-502 read; the probe table after line 502 was not re-read)
- /Users/LeonChen/Documents/ClickMe2026/.planning/phases/03-booked-sessions-and-joining/03-UI-REVIEW.md (prior review, 2026-11-11)
- ClickMe2026/Managers/ToastCenter.swift
- ClickMe2026/Views/Components/Toast/ToastHost.swift
- ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift (grep)
- ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift (grep and partial)
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingJoinCard.swift
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingStatusRow.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingTopicCard.swift and UpcomingBookingPrepNotesCard.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/RescheduleResponseCard.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryDeclineNoteCard.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationBookingSummary.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationCommentField.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/PastEmptyState.swift
- ClickMe2026/Views/Screens/Call/Calling/Subviews/SkypeSessionHero.swift
- ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift (grep)
- ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift (grep)
- ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift (grep and partial)
