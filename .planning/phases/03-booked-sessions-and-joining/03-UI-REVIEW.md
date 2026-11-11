# Phase 03 — UI Review

**Audited:** 2026-11-11
**Baseline:** 03-UI-SPEC.md (approved, force-approved 2026-11-10)
**Screenshots:** not captured (native SwiftUI app, no web dev server; static audit of source and #Preview blocks, no build or simulator run)
**Interaction captures:** off (workflow.ui_interaction_capture is false). All interaction findings are code-derived.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract strings match (Accept New Time, Decline New Time, Past empty state, DECLINE NOTE, Review Cancellation); Skype status copy and Skype-screen open affordance not verified against contract |
| 2. Visuals | 3/4 | Clear focal points and good a11y labels/hints; toast placement is a hardcoded guess and the toast shape deviates from the spec |
| 3. Color | 3/4 | Accent kept off money and warnings; Decline New Time uses raw `Color.red` instead of `Brand.destructive` |
| 4. Typography | 2/4 | Declared set of 4 sizes / 2 weights is broken: `.caption2` (11 pt) and `.medium` weight are in use on Phase 03 surfaces |
| 5. Spacing | 3/4 | New blocks sit on the 4/8/16/24 grid; response-card buttons use a 10 pt radius (off the 12/16 rule) and expert reschedule buttons are 42 pt |
| 6. Experience Design | 3/4 | State coverage is strong (60 s timelines, in-flight disable, 2-tap refund change, toast survives pops); toast is not keyboard-aware and Reduce Motion / tab-bar-less screens are unaddressed |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Typography set exceeds the contract** — The spec locks 4 sizes (12/15/16/22) and 2 weights, but `RescheduleResponseCard.swift` (`timeBlock` and `noteBlock` labels) and the matching expert-side time block in `ExpertBookingSummaryView.swift:600-610` use `.caption2` (11 pt). `SkypeSessionHero` (scheduled range) and the Skype status line in `MeetingCallView.swift` use `weight: .medium`. Small labels get harder to read and the type scale drifts. Fix: move the FROM/TO/Expert's message labels to `.caption` Semibold, and the Skype status line and range to `.caption` Regular or `.subheadline` Regular.
2. **Toast placement is hardcoded and not keyboard-aware** — `ToastHost.swift` adds a fixed `tabBarHeight = 49` on top of 24 pt, so on any screen where the tab bar is hidden (pushed cancel or reschedule flows) the toast floats about 73 pt above the bottom. It also ignores the keyboard, which the spec says it must never cover. The shape is a 20 pt rounded rectangle, not the capsule the spec asks for. Fix: anchor with `.safeAreaInset(edge: .bottom)` so it follows the real tab bar and keyboard insets, and use `Capsule()` for single-line messages.
3. **Response-card and expert-summary buttons are off the geometry contract** — The Accept New Time and Decline New Time buttons in `RescheduleResponseCard.swift` use a 10 pt corner radius (spec: 12 or 16 for new controls), and Decline uses `Color.red.opacity(...)` rather than `Brand.destructive`. The expert reschedule action buttons in `ExpertBookingSummaryView.swift:619,644` are still 42 pt tall, below the 44 pt minimum the spec says no control may stay under. Fix: set radius 12, swap in `Brand.destructive`, and raise the expert buttons to `minHeight: 44`.

Further items (lower priority):

4. Skype timer (`Text(timerString)` in `SkypeSessionHero`) and the remaining-time chip carry no accessibility label or `updatesFrequently` trait, so VoiceOver reads raw `M:SS`. Add labels such as "Starts in 4 minutes".
5. `ToastHost` chip has `.accessibilityAddTraits(.isStaticText)` but is tappable via `onTapGesture` with no accessible dismiss action. Add `.accessibilityAction(.default) { center.dismiss() }`.
6. Open question for the Skype layout: the contract's focal point is an accent `Open in {provider}` button, but the screen renders the existing `SkypeLinkActions`. Verify on device that the provider-named affordance (or an equivalent) is present. Not confirmed from the files read.
7. K2 stays open: the Skype layout still has no overtime banner (unchanged from the contract).

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

Matches the contract:
- `RescheduleResponseCard.swift`: "Expert requested a new time", "You proposed a new time", "Expert's message", "Accept New Time", "Decline New Time", "Awaiting expert's response".
- `PastEmptyState.swift`: "No past bookings yet" and "Completed, cancelled and missed sessions will show up here." with no button, as specified.
- `BookingSummaryDeclineNoteCard.swift`: header "DECLINE NOTE".
- `ClientCancellationView.swift:85`: dismiss button "Review Cancellation". Line 210: the changed-refund notice matches the contract verbatim.
- `UpcomingBookingJoinCard.swift`: "JOIN CALL", "Meeting Link", "Not available yet", "Copy meeting link" / "Link copied" labels, and the hint "Available closer to the session start".

Gaps:
- The "Open in {provider}" label comes from `ExternalMeetingProvider.openButtonTitle`. I did not check the unrecognized-host fallback ("Open Meeting") in that file.
- The response-card time block labels are written as "From"/"To" and uppercased in code. This is correct per the spec.
- No generic "Submit"/"OK" labels were found in the Phase 03 files read.

### Pillar 2: Visuals (3/4)

- Focal points follow the contract. The Join card is a 52 pt accent button, dimmed to 55% with the glow removed when closed. The warning block in cancel case D is the amber focal point. `Message Client` drops to outlined while `Join Session` is shown (`ExpertBookingSummaryView.swift:734-757`).
- Accessibility is thorough: response-card buttons carry the proposed time in their labels, the card is an `accessibilityElement(.contain)` container with a header trait, the warning block reads as one sentence, and the icon-only copy button is labelled.
- `ToastHost.swift`: the chip is a `RoundedRectangle(cornerRadius: 20)`, not a capsule. The placement is a guess at the tab bar height (see Fix 2).
- `SkypeSessionHero` has no accessibility grouping. The timer and chip are not exposed as meaningful values.
- Each screen keeps its own brand alias enum, as the contract requires.

### Pillar 3: Color (3/4)

- The accent is reserved for join buttons, the Accept New Time button, the toast stroke, and the outlined Message Client. The refund amount uses `onSurface` semibold, not accent (`CancellationBookingSummary.emphasizedText`). The decline note is neutral.
- Orange is used only for warnings (case D block, preview-changed notice, response card, remaining chip, near-end timer), as inherited.
- Deviation: `Color.red.opacity(0.95/0.10/0.45)` is used for Decline New Time in `RescheduleResponseCard.swift` and the expert summary. The contract names `Brand.destructive`.
- Deviation: `Color(red: 0.12, green: 0.18, blue: 0.14)` is a hardcoded avatar fallback in `CancellationBookingSummary.swift`. The legacy cancel palette is allowed by the contract, but this literal is not tokenised.

### Pillar 4: Typography (2/4)

Declared set: 12/15/16/22 pt and Regular/Semibold.

Observed outside it, on Phase 03 surfaces:
- `.caption2` (11 pt) Semibold: FROM/TO labels and note labels in `RescheduleResponseCard.swift`; time block in `ExpertBookingSummaryView.swift:600-610`.
- `.medium` weight: `SkypeSessionHero` scheduled range, and the Skype status line in `MeetingCallView.swift`. This is a third weight.
- `.bold` on `JOIN CALL`, cancel buttons, and the 34 pt names are pre-existing and declared out of contract.
- `Font.system(.caption, design: .monospaced)` in the link row is pre-existing.

The Skype timer correctly uses `.title2` monospaced. New multi-line copy uses `fixedSize(horizontal: false, vertical: true)` consistently.

### Pillar 5: Spacing (3/4)

- On grid: decline note card (16 padding, 8 gap), warning block (16 padding, 16 radius, 10 icon gap), Past empty state (40 side padding, 28 section spacing), toast (16/8 padding, 24 side margin).
- The response card keeps its inherited 14 pt padding, radius and gap, which the contract declares out of contract.
- Deviation: response-card buttons have a 10 pt radius, off the 12/16 rule for new controls.
- Deviation: expert reschedule buttons are `frame(height: 42)`, below the 44 pt minimum. These are on the expert surface and may be untouched legacy code, but the contract says no control is kept under 44 pt.
- Join buttons are 52 pt with 16 pt (Open in provider) and 12 pt (expert) radii as specified. The in-app `JOIN CALL` keeps 14 pt as declared.

### Pillar 6: Experience Design (3/4)

Covered well:
- Loading: Accept/Decline disable with an in-button `ProgressView` while in flight. Confirm Cancellation is disabled while confirming.
- Time-dependence: `TimelineView(.periodic(from: .now, by: 60))` on Join, Open Meeting, Cancel visibility (`UpcomingBookingView.swift:224,246`), the cancel preview (`ClientCancellationView.swift:193`), and expert Join (`ExpertBookingSummaryView.swift:260`).
- Cancel: the refund-case change at confirm blocks submit and shows the notice (`previewChangedNotice`).
- Toasts: `ToastCenter` is a shared singleton hosted at the client shell (`HomeClientView.swift:115`) so messages survive pops. It posts a VoiceOver announcement, replaces the current toast, and uses a 4 s timer keyed by id.
- Errors: alerts with "Review Cancellation" and "Back to Booking" dismiss buttons.
- Past empty state is gated by load result per the contract.

Gaps:
- Toast is not keyboard-aware and assumes a tab bar (Fix 2). There is no `reduceMotion` branch; the spec accepts fade-only, and the code is fade-only, so this is acceptable.
- Skype timer and chip are not accessible values (item 4).
- Skype layout has no overtime banner (K2, known).
- Device-only backstops (L2, L3, D2 to D4) remain unverified here and belong to the UAT checklist.

---

## Registry Safety

Not applicable: no `components.json`, no third-party registries.

---

## Files Audited

- /Users/LeonChen/Documents/ClickMe2026/.planning/phases/03-booked-sessions-and-joining/03-UI-SPEC.md
- ClickMe2026/Managers/ToastCenter.swift
- ClickMe2026/Views/Components/Toast/ToastHost.swift
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingJoinCard.swift
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/RescheduleResponseCard.swift
- ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryDeclineNoteCard.swift
- ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationBookingSummary.swift
- ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationCommentField.swift (grep)
- ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/PastEmptyState.swift
- ClickMe2026/Views/Screens/Call/Calling/Subviews/SkypeSessionHero.swift
- ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift
- ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift (grep and partial)
- ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift (grep)
