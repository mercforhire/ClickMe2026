# Phase 02 — UI Review

**Audited:** 2026-11-10
**Baseline:** `02-UI-SPEC.md` (approved 2026-11-09). Known spec drift (BOOK-14 all-days picker, CALL-02/D-12 disabled Join) is graded against the superseding SUMMARY contracts (02-07, 02-08, 02-14, 02-15), not against the old spec rows. See "Spec Drift" below.
**Screenshots:** not captured (native iOS app, no dev server; code-only audit)
**Interaction captures:** off (`workflow.ui_interaction_capture` is false)

**Scope and limits**
- Code-only audit. Nothing in this report is a device pass. Device checks for CALL-01, CALL-02, BOOK-10, BOOK-14, BOOK-18, PUSH-01/02/03/04, CHAT-09 and EXP-14 history are PENDING in `02-DEVICE-UAT-CHECKLIST.md`.
- Paths below are relative to the iOS repo root `/Users/LeonChen/Documents/ClickMe2026`.
- Diff range `fb94bb2^..HEAD` includes two commits outside the Phase 02 plans (`73e729e`, `e43ef50`, topic currency work). Findings on those are marked out of scope and are excluded from the score only where noted.
- Read in full: all 15 `02-NN-SUMMARY.md`, `02-UI-SPEC.md`, `02-CONTEXT.md`. The 15 `02-NN-PLAN.md` files were not opened line by line; SUMMARY truths were used as plan intent.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract strings match verbatim; a disabled Join gives sighted users no visible reason (W-1) |
| 2. Visuals | 3/4 | Focal-point rules hold; the Join label colour differs across the four Join surfaces (W-2) |
| 3. Color | 3/4 | Accent reserved correctly; Explore Join label hardcodes `.black`, not `Brand.onPrimary` (W-3) |
| 4. Typography | 3/4 | New text stays on 12/15/16/20 pt and Regular/Semibold; undocumented Medium, Bold and a 34 pt title remain (W-4) |
| 5. Spacing | 3/4 | Phase 02 spacing sits on the grid; an off-grid 6 pt stack came in with out-of-phase commit `73e729e` (W-5) |
| 6. Experience Design | 3/4 | Skeleton, retry, empty, Ended and dash-fallback states present; a disabled Join is unexplained (W-1); two status tables decide one Join rule (W-6) |

**Overall: 18/24**

**Blockers: none.** Warnings: 6 (W-1 to W-6). No pillar scored 1. If the out-of-phase `73e729e` item (W-5) is excluded from scoring, Spacing becomes 4 and the overall becomes 19/24.

---

## Top 3 Priority Fixes

1. **Disabled Join gives no visible reason (W-1)** — a dimmed "Join Call" / "Join Session" sits on screen for hours with no text, and the only explanation is a VoiceOver hint. Fix: add a visible caption line "Available closer to the session start" under the disabled button on all four surfaces, or record a product decision to keep the parity behaviour silent. Files: `ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift:112-115`, `ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/UpcomingBookingCard.swift:219-222`, `ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift:527-530`, `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift:65-68`.

2. **Two status tables decide one Join rule (W-6)** — strip membership admits `pending_reschedule` (`ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardViewModel.swift:373-378`, `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:160-166`), while the shared gate excludes it (`ClickMe2026/Utils/JoinWindow.swift:37`). A change to one table will silently desynchronise strip membership from the Join gate. Fix: derive strip membership from `JoinWindow` (one status set), and add a test that every status a strip admits is covered by `showsJoinButton` and `isOpen`.

3. **Join label colour is hardcoded and differs by surface (W-2, W-3)** — the Explore label uses `.black` (`ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift:100`); My Bookings uses `MyBookingsBrand.onPrimary` (`ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/UpcomingBookingCard.swift:206`); the expert list uses `Brand.onPrimary` (`ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift:52`). UI-SPEC line 128 names `Brand.onPrimary` (#00391d) as the text colour on accent. Fix: use `Brand.onPrimary` on all four Join labels and confirm contrast on device.

---

## Spec Drift (UI-SPEC needs revision)

Each row below is out of date against `02-UI-SPEC.md`. Each is graded here against the governing contract. None is counted as a defect.

| # | UI-SPEC line(s) | What the spec says | What is implemented | Governing SUMMARY | Grade vs new contract |
|---|-----------------|--------------------|---------------------|-------------------|-----------------------|
| 1 | 191 (W1-9), 192 (W1-10) | Paid days past now + 6 d render blank and untappable; slot chips past the limit are removed | All days visible and tappable; slots past the limit dimmed and untappable, never removed; free-to-paid switch still clears a far slot | 02-07 and 02-08 (user parity decision 2026-11-10; commits `1ddd0d0`, `9f85dc2`) | Pass. `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift:97-98, 125`; `MakeABookingTimeSlotsCard.swift:139-172` |
| 2 | 221 (My Bookings, window closed; not-joinable) | JOIN CALL hidden, button removed | Dimmed, disabled JOIN CALL; awaiting-approval card keeps its banner | 02-14 (`a620b92`) | Pass. `UpcomingBookingCard.swift:197-222` |
| 3 | 222 (Explore strip, not-joinable) | Not rendered | Rendered dimmed and disabled for `pending_reschedule` (strip member) | 02-14 (`ddc0163`) | Pass. `ExploreTodaysSessionsSection.swift:88, 105, 112-115` |
| 4 | 223 (expert Upcoming list, closed and not-joinable) | Hidden | Dimmed, disabled Join Session; NOW badge still hides when the window is closed | 02-14 (`a620b92`) | Pass. `UpcomingBookingsSessionCard.swift:46-68, 142-152` |
| 5 | 224 (expert dashboard strip, not-joinable) | Not rendered | Rendered dimmed and disabled for `pending_reschedule` | 02-14 (`1ab3f1f`) | Pass. `ExpertDashboardView.swift:486-530`; membership at `ExpertDashboardViewModel.swift:373-378` |
| 6 | 228 (intentional change: Join disappears for `pending_reschedule`) | Join disappears on the strips | Join present, disabled | 02-14 | Pass against new contract |
| 7 | 257 (Client Profile history shows a dash until EXP-14) | `—` on every row | Real net earnings `CA$x.xx` for `pending_approval`, `confirmed`, `pending_reschedule`, `in_progress`, `completed`; dash for others | 02-15 (`63b743d`, user decision at tracer gate) | Pass. `ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift` (`earningsStatuses`); `ClientProfileBookingCard.swift:24-27, 46` |
| 8 | 263-264 (section 4 picker table: blank or hidden days; slots removed) | Blank or hidden days; far slots removed | Visible days; slots dimmed; fixed paid note under the slots title | 02-07 rework, 02-08 | Pass. `MakeABookingTimeSlotsCard.swift:29-34`; `RescheduleTimeSlotsCard.swift:37-43`; `RescheduleView.swift:173-174` |
| 9 | 269 (blank days deliberately differ from dimmed days) | Distinction between blank and dimmed | Superseded: no blank days exist | 02-08 | Pass |
| 10 | 277-281 (empty states: whole-month-blank caption under the grid) | Caption from `longLeadMessage` / `rescheduleTooFarAheadMessage` under the calendar | No blank month is possible. Fixed note under the slots title. Caption constants remain for submit errors only | 02-08 | Pass against new contract. Copy rows at lines 161 and 163 are not shown as captions |
| 11 | 283-287 (accessibility 1: blank cells `accessibilityHidden`) | Blank cells hidden from VoiceOver | Moot: no blank cells. Item 2 (chevron labels) is still in force and implemented | 02-08 | Pass. `MakeABookingCalendarCard.swift:41, 59`; `RescheduleCalendarCard.swift:45, 61` |
| 12 | 292-294 (plan ownership: Make a Booking month caption gap) | Gap with no owning plan | Closed by the 02-08 rework; no follow-up plan needed | 02-08 | Pass |
| 13 | 337 (My Bookings focal point: the button is hidden when closed) | Closed card has no accent focal point | Button is present, dimmed; focal point yields to the session time | 02-14 | Pass |
| 14 | 355 (UI Considerations S2: "Hidden or not rendered") | Hidden | Rendered and disabled | 02-14 | Pass |
| 15 | 161, 163 (copy: month-blank captions) | Captions for blank months | Replaced by notes: "Paid sessions can be booked up to 6 days ahead." (`MakeABookingTimeSlotsCard.swift:30`) and "Paid sessions can be rescheduled up to 6 days ahead." (`RescheduleTimeSlotsCard.swift:38`) | 02-08 (Android verbatim, user decision) | Pass against new contract; the new strings are not yet in the copy table |
| 16 | 364 (E1), 365 (A1) | Blank-month and blank-cell coverage | Superseded by rows 9-12 | 02-08 | Pass |

**Spec gaps (not user drift; the spec should document these, or the code should change):**
- Medium weight on reschedule chips (`RescheduleTimeSlotsCard.swift:77`) and on the call caption (`ClickMe2026/Views/Screens/Call/Calling/Subviews/MeetingCallInfo.swift:45`). Bold on the Client Profile amount (`ClientProfileBookingCard.swift:47`, pre-existing). Neither is in the UI-SPEC inherited-exception lists (lines 110-114).
- 34 pt bold call-timer title (`MeetingCallInfo.swift:30`). Pre-existing; UI-SPEC line 102 says hero sizes of 34 pt and above are not used on Phase 02 surfaces, and the call screen is a listed Phase 02 surface (line 340).
- Orange "Current" chip (`RescheduleTimeSlotsCard.swift:87, 124`) is not in the warning exception list (lines 122, 130).
- Join label text colour `.black` (`ExploreTodaysSessionsSection.swift:100`) against the token at line 128.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Verified against contract (pass):**
- Join labels: `Join Call` (`ExploreTodaysSessionsSection.swift:97`), `JOIN CALL` with `phone.fill` (`UpcomingBookingCard.swift:202`), `Join Session` (`UpcomingBookingsSessionCard.swift:50`, `ExpertDashboardView.swift:511`). Matches UI-SPEC lines 153-155.
- Call banner strings in `ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift:224-231`: "This call will end in 5 minutes", "Scheduled time complete — you can wrap up when ready.", "Session ending soon — please start wrapping up." Match UI-SPEC lines 156-158.
- Ended label: `MeetingCallView.swift:30` (`Call Ended`). Matches line 159.
- Empty states: `MakeABookingTimeSlotsCard.swift:63` ("No available slots on this day."); `RescheduleTimeSlotsCard.swift:46` ("No available slots for the selected day.").
- Error copy: `ClickMe2026/Utils/BookingErrorMapper.swift:23, 26-27, 43, 45, 64-67` matches UI-SPEC lines 166-170. Long-lead and reschedule-too-far codes branch on `ErrorCode`, not on message text.
- Accessibility labels "Previous month" / "Next month" on both calendars (UI-SPEC C1): `MakeABookingCalendarCard.swift:41, 59`; `RescheduleCalendarCard.swift:45, 61`.

**Findings:**
- **W-1 (WARNING).** A disabled Join has no visible text. The only explanation is `.accessibilityHint("Available closer to the session start")` at `ExploreTodaysSessionsSection.swift:115`, `UpcomingBookingCard.swift:222`, `ExpertDashboardView.swift:530`, `UpcomingBookingsSessionCard.swift:68`. Sighted users get no reason. The contract does not require visible text (02-14 copies Android's state description), so this is a gap against the parity standard. It needs a product decision.

### Pillar 2: Visuals (3/4)

**Verified (pass):**
- Focal points match UI-SPEC lines 335-339: the accent fill appears only when the window is open (`UpcomingBookingCard.swift:211`, `ExploreTodaysSessionsSection.swift:105`, `ExpertDashboardView.swift:519`, `UpcomingBookingsSessionCard.swift:57`). Closed state is 55% opacity with no glow.
- The two calendar selection treatments stay distinct: filled circle (`MakeABookingCalendarCard.swift:107-111`) vs 1.6 pt ring (`RescheduleCalendarCard.swift:100-105`), as UI-SPEC lines 268-269 require.
- Overtime banner: amber, `.fixedSize(vertical:)` so it wraps (`MeetingCallView.swift:211`), outer padding 24 horizontal and 12 top (`MeetingCallView.swift:87-88`), as UI-SPEC line 213.
- Days past the paid limit stay visible and tappable (`MakeABookingCalendarCard.swift:97-98`). Their slots dim (`MakeABookingTimeSlotsCard.swift:141, 150`).

**Findings:**
- **W-2 (WARNING).** The Join label colour differs across the four Join surfaces: `.black` (`ExploreTodaysSessionsSection.swift:100`), `MyBookingsBrand.onPrimary` (`UpcomingBookingCard.swift:206`), `Brand.onPrimary` (`UpcomingBookingsSessionCard.swift:52`, `ExpertDashboardView.swift:445`). The same control reads differently depending on the screen.

### Pillar 3: Color (3/4)

**Verified (pass):**
- Accent reserved to the list at UI-SPEC lines 133-139 (Join fills, selected day and slot, Today numeral, chevrons).
- Money labels never take the accent: `ClientProfileBookingCard.swift:48` uses `ClientProfileBrand.onSurface`; expert earnings use `Brand` text tokens (`RequestDecisionEarningsSection.swift:166`).
- Amber warning colour uses `Color.orange` as the spec allows (UI-SPEC lines 122, 130): `MeetingCallView.swift:207, 218-220`; `MeetingCallInfo.swift:51, 57-63`.

**Findings:**
- **W-3 (WARNING).** `ExploreTodaysSessionsSection.swift:100` hardcodes `.black` for the Join label. It is not a `Brand` token, and UI-SPEC line 128 names `Brand.onPrimary` (#00391d). The same file also uses `.black` on the "Today" pill at line 57, which predates this phase.
- Spec gap: reschedule "Current" chips use `.orange` (`RescheduleTimeSlotsCard.swift:87, 124`), which the UI-SPEC warning exception does not list (see Spec Drift).

### Pillar 4: Typography (3/4)

**Verified (pass):** new Phase 02 text uses only the declared scale and weights:
- Paid notes: `.caption` Regular (`MakeABookingTimeSlotsCard.swift:31`; `RescheduleTimeSlotsCard.swift:39`).
- Banner: `.caption` Semibold (`MeetingCallView.swift:209`).
- Join labels: Bold, which is inherited (UI-SPEC line 112).
- Dynamic Type: banner text uses `fixedSize` (`MeetingCallView.swift:211`), as UI-SPEC line 116 requires.

**Findings:**
- **W-4 (WARNING).** Undocumented weights and sizes remain on Phase 02 surfaces:
  - Medium on reschedule chips (`RescheduleTimeSlotsCard.swift:77`), a pre-existing choice.
  - Medium on the call caption (`MeetingCallInfo.swift:45`).
  - Bold on the Client Profile amount (`ClientProfileBookingCard.swift:47`). This was inherited from the base (`git show fb94bb2^` line 34), but the text is now real money (02-15), so Semibold would match the contract.
  - 34 pt bold call-timer title (`MeetingCallInfo.swift:30`), inherited.
  - None of these is a new addition. The UI-SPEC inherited-exception list (lines 110-114) does not cover them.

### Pillar 5: Spacing (3/4)

**Verified (pass):** Phase 02 layout values sit on the target grid or on the declared exceptions:
- Card padding 16 (`MakeABookingTimeSlotsCard.swift:38`); chip padding 16 horizontal and 10 vertical (`:153-154`, the 10 is an inherited exception).
- Calendar grid spacing 4 (`MakeABookingCalendarCard.swift:83`); month-nav padding 8 and 14/12 (`:61-63`, the 14 is inherited).
- Banner outer padding 24 and 12 (`MeetingCallView.swift:87-88`).
- Join button height 50 pt, as declared at UI-SPEC line 95.

**Findings:**
- **W-5 (WARNING, out of phase; excluded from the score if the orchestrator wants Phase 02-only scoring).** Off-grid `VStack(spacing: 6)` at `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift:100, 429, 455, 519`. These lines came in with `73e729e` (topic currency, EXP-17 iOS half), which is not a Phase 02 plan. UI-SPEC line 95 says new layout code adds no new off-grid value. The phase diff range includes this change, so it is noted here.

### Pillar 6: Experience Design (3/4)

**Verified (pass):**
- Make a Booking availability: skeleton (`MakeABookingTimeSlotsCard.swift:50-51, 107-118`), error with Retry (`:120-135`), empty copy (`:62-66`), loaded state.
- Reschedule empty copy (`RescheduleTimeSlotsCard.swift:45-49`).
- Call end states: banner priority and the Ended label (`MeetingCallView.swift:30, 224-232`).
- Unknown money renders a dash: `ClickMe2026/Utils/Money.swift:123-133` returns nil for non-finite values; `ClientProfileBookingCard.swift:24-27` falls back to `—`.
- Summary badge hidden for `rescheduled` and `unknown`: `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift:350-360`; the badge renders only `if let status` (`BookingSummaryExpertCard.swift:83`).
- Disabled controls cannot be tapped: `.disabled(!inWindow)` on all four Join buttons (`ExploreTodaysSessionsSection.swift:112`, `UpcomingBookingCard.swift:219`, `ExpertDashboardView.swift:527`, `UpcomingBookingsSessionCard.swift:65`). The server remains the final authority on `POST /join`.
- Long-lead refusal makes no request (02-07, `MakeABookingViewModel`).

**Findings:**
- **W-1 (WARNING, see Pillar 1).** Disabled Join is unexplained for sighted users.
- **W-6 (WARNING).** Two status tables for one rule. Strip membership admits `pending_reschedule` at `ExpertDashboardViewModel.swift:375` and `ExploreClientViewModel.swift:161-162`, while `JoinWindow.joinableStatuses` excludes it (`JoinWindow.swift:37`). The strip card renders a dimmed Join for the whole day. The two tables will drift silently if one changes.
- Known limitation K1 (push-opened booking detail actions inert until Phase 3, UI-SPEC line 367) is documented and was not scored.
- Device-only, not verified here: Join dimming over elapsed time (CALL-02), blank-cell and tap behaviour (BOOK-14), CHAT-09 suppression, PUSH-01 routing, PUSH-04 logout. All are PENDING in the checklist.

---

## Registry Safety

Not applicable. `components.json` is absent (UI-SPEC line 24) and no third-party registry is listed.

---

## Files Audited

- `ClickMe2026/Utils/JoinWindow.swift`
- `ClickMe2026/Utils/Money.swift`
- `ClickMe2026/Utils/BookingErrorMapper.swift`
- `ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift`
- `ClickMe2026/Views/Screens/Call/Calling/Subviews/MeetingCallInfo.swift`
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/UpcomingBookingCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift`
- `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleTimeSlotsCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardViewModel.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionEarningsSection.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Client Profile/Subviews/ClientProfileBookingCard.swift`
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift` (out of phase)
- `ClickMe2026/Localizable.xcstrings` (note strings verified present)
- `.planning/phases/02-shared-ios-plumbing/02-UI-SPEC.md`, `02-CONTEXT.md`, `02-01` to `02-15` SUMMARY files
