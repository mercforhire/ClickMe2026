# Phase 6: Expert Mode - Context

**Gathered:** 2026-11-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the existing expert-mode screens so experts can price, describe and schedule topics correctly and handle requests, bookings, clients and notes without wrong amounts or dead ends. Requirements: EXP-01 to EXP-10, EXP-12, EXP-14 to EXP-18 (EXP-11 and EXP-13 were delivered in Phase 3).

In scope: topic editor (delete confirm, decimal price, currency choice and keep-on-edit, clearing icon/description, stale 409 comment), availability picker (Cancel revert, end-time cap, off-grid times), accept -> Confirmed flow and its calendar event, expired request card contrast, expert-side Client Profile earnings, the hub online dot, the private booking note, and the expert Booking Summary ID. Plus the folded Availability nav-bar todo.

Not in scope: new expert capabilities, any backend change (none is expected: the backend already accepts `hourly_rate.currency` CAD/USD and locks a paid topic's currency), more currencies than CAD and USD.

EXP-17 and EXP-18 are cross-platform: they need matching Android changes in `../ClickMe_Android` (one commit per repo). Every other item is iOS-only unless noted.

</domain>

<decisions>
## Implementation Decisions

### Topic currency and price (EXP-02, EXP-03, EXP-17)
- **D-01:** New topics choose their currency with a **segmented control (CAD | USD)** on the topic editor, next to the price field. Android gets a matching Material SegmentedButton (EXP-17 is "both iOS and Android"). This supersedes Android 10-CONTEXT D-10's "no currency picker". — **Reversibility:** costly — two platforms ship the same control, and undoing it means changing both UIs and their tests
- **D-02:** On edit, a **paid topic's currency is read-only** and shows a short note ("A paid topic's currency can't be changed."). A **free topic shows the picker**, so it can choose a currency when it becomes paid. This mirrors the backend rule in `expertTopics.controller.js` (`TOPIC_CURRENCY_LOCKED`, Phase 34 D-04 amended 2026-11-10). A 422 `TOPIC_CURRENCY_LOCKED` still maps to the server message if it ever arrives.
- **D-03:** Switching currency after typing a price **keeps the typed number** (12.50 stays 12.50) and revalidates against the new currency's floor. No conversion. The minimum-price hint updates to the new currency.
- **D-04:** A new topic defaults to `pricing_limits.min_session_amount.default_currency` from `/me`, else **CAD** (Android D-10).
- **D-05:** The price field accepts decimals using the currency's fraction digits (Android D-09; `Money` already knows the digits). This replaces 02-06's "typed price parses whole units in defaultCurrency until Phase 6". An untouched save still sends the stored minor amount and currency (02-06 D-19).

### Availability picker (EXP-05, EXP-06, EXP-07)
- **D-06:** **Keep the 23:30 cap** on end times. No 24:00 row. Matches Android and needs no backend change. (The backend's string compare would accept "24:00", but slot generation with hour 24 is unproven on production.)
- **D-07:** "Add hours" that would push an end past 23:30 **clamps the end to 23:30**. If the start is already 23:00 or later, the button is disabled.
- **D-08:** A stored time off the 30-minute grid (the backend allows 15-minute steps, e.g. 09:15) or an already-stored 24:00 end is **inserted into the picker as a selected row** with its exact value (24:00 labelled "12:00 AM"), so nothing changes unless the expert picks a different time. No snapping.
- **D-09:** Cancel on the time-range picker reverts: edit a copy and commit on Done (inventory E5).

### Hub online dot (EXP-15)
- **D-10:** **Remove the dot** from the expert hub (`ExpertProfileHomeViewModel.isOnline` and its view). Matches Android, which never ported it (Android `ExpertProfileHomeViewModel.kt`, D-06).

### Accept -> Confirmed flow (EXP-09, EXP-10)
- **D-11:** **Copy Android 11-CONTEXT D-04/D-05.** On a successful accept, the accept sheet closes and `BookingConfirmedView` **replaces** Request Decision on the stack. Back returns to a refreshed Incoming Requests, never a stale decision screen. "Back to Home" pops to the Dashboard (switching tabs if the flow began elsewhere), refreshed so the pending count drops.
- **D-12:** **409 `ALREADY_PROCESSED`** on accept (or decline): an alert shows the server message; OK pops to a refreshed Incoming Requests (Android D-07). Other errors show the server message and stay on the screen.
- **D-13:** The calendar event title is **exactly Android's string: `"ClickMe · {topic} with {client name}"`**. Start and end come from the booking; the description carries the meeting type ("In-App Voice" or "Skype/Zoom") plus the client's message if present (Android D-06). This fixes the bug where iOS uses the expert's own name.

### Follow Android's existing decisions (not re-discussed)
- **D-14:** EXP-01: delete asks "Delete this topic?" (Delete / Cancel) before `DELETE /expert/topics/:id` (Android 10 D-06).
- **D-15:** EXP-04: PATCH encodes an explicit `null` for a cleared icon or description (`expertTopics.schema.js` marks both nullable; inventory E4).
- **D-16:** EXP-08: comment-only fix on `deleteMyTopic` (soft delete, 404 only), verified in code review.
- **D-17:** EXP-12: expired request cards keep text at full contrast. Dim only the background or badge, not the text (inventory E14, UI-SPEC A5). It is a LIKELY item: confirm on a device first.
- **D-18:** EXP-14: the Client Profile history row already shows real net earnings (02-15). This phase covers any remaining Client Profile earnings surface (totals and summary), formatted through `Money` in the booking currency.
- **D-19:** EXP-16: copy Android 16.4 D-01 to D-04. A hard 5000-character cap with a counter. A whitespace-only note is sent as `""`, which clears it. Leaving with unsaved changes asks "Discard changes?" (Keep editing / Discard). Save is disabled when nothing changed.
- **D-20:** EXP-18: the expert Booking Summary shows `ID: #A1B2C3D4` through `BookingShortID`, the same rule as the client screen (BOOK-20). Android already shows it (`ExpertSummaryCard.kt`, `expert_summary_id`); check that Android uses the same short-ID rule.

### Claude's Discretion
- Exact placement and styling of the segmented control and the read-only currency note, within the existing topic editor layout and `Brand` tokens.
- The exact wording of the D-07 disabled state (if any hint is shown).
- How the inserted off-grid row is ordered in the picker list (in time order is expected).

### Folded Todos
- **"Availability settings: pin the nav bar dark so the Save button stays legible"** (`.planning/todos/pending/2026-11-14-availability-settings-toolbar-dark-pin.md`). The trailing Save on `AvailabilitySettingsView` uses dark-theme colours, and the screen pins no bar colour scheme, so on iOS 26 in Light appearance with Reduce Transparency or Tinted Liquid Glass the capsule likely turns light grey (the latent form of G-05-1). Fix with the 05-18 pins: `toolbarBackground(Brand.surface, for: .navigationBar)`, `toolbarBackground(.visible, for: .navigationBar)`, `toolbarColorScheme(.dark, for: .navigationBar)`. It is the same screen as EXP-05/06/07.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and inventory
- `.planning/REQUIREMENTS.md` — EXP-01 to EXP-18 wording (EXP-17 and EXP-18 include the Android half)
- `.planning/ROADMAP.md` § Phase 6 — goal, success criteria, notes (EXP-12 likely; EXP-08 comment-only)
- `.planning/IOS-BUG-INVENTORY.md` rows E1-E8, E11, E12, E14, E16-E18 — file and line evidence and the suggested fix for each

### Backend contract (read before changing Network/ or Model/)
- `../ClickMe2026 Backend/src/schemas/expertTopics.schema.js` — CAD/USD allowlist, PATCH currency optional, nullable icon/description, duration rules
- `../ClickMe2026 Backend/src/controllers/expertTopics.controller.js` (around L380-440) — `TOPIC_CURRENCY_LOCKED`: a paid topic's currency is fixed; paid -> free is exempt; a free topic may set one
- `../ClickMe2026 Backend/src/utils/pricing.js` — per-currency floors (`assertMeetsMinimumPrice`)
- `../ClickMe2026 Backend/src/schemas/availability.schema.js` and `src/controllers/availability.controller.js` (`validateDaySlots`) — `HH:mm`, 15-minute alignment, end after start
- `../ClickMe2026 Backend/src/schemas/booking.schema.js` (`noteSchema`, about L150) — note max 5000, empty string allowed
- `../ClickMe2026 Backend/openapi/clickme-api.yaml` — accept / decline and `409 ALREADY_PROCESSED`

### Android decisions this phase copies
- `../ClickMe_Android/.planning/phases/10-expert-topics-availability/10-CONTEXT.md` — D-06 delete confirm, D-09 decimals, D-10 currency (amended here by D-01/D-02), D-11 floor, 23:30 cap note
- `../ClickMe_Android/.planning/phases/11-expert-requests-bookings/11-CONTEXT.md` — D-04/D-05 Confirmed flow, D-06 calendar content, D-07 409 handling
- `../ClickMe_Android/.planning/phases/16.4-ios-parity-private-booking-notes-and-expert-side-client-prof/16.4-CONTEXT.md` — D-01 to D-04 note rules
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/` — `TopicEditorViewModel.kt`, `TopicPrice.kt`, `subviews/TopicPriceField.kt` (where the Android EXP-17 picker goes)

### Prior iOS phase decisions
- `.planning/phases/02-shared-ios-plumbing/02-06-SUMMARY.md` — D-19 untouched topic save; typed price whole units until Phase 6
- `.planning/phases/02-shared-ios-plumbing/02-15-SUMMARY.md` — Client Profile history net earnings (EXP-14 remainder)
- `.planning/phases/03-booked-sessions-and-joining/03-CONTEXT.md` — BOOK-20 short ID, expert reschedule cap (EXP-13)
- `.planning/debug/not-now-button-low-contrast.md` and plan 05-18 — the nav-bar pin fix used by the folded todo

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClickMe2026/Utils/Money.swift`: the shared formatter and fraction-digit table (CAD is CA$, zero-decimal set). Use it for price parsing and display (D-05, D-18).
- `ClickMe2026/Utils/BookingShortID.swift`: the BOOK-20 short ID rule for EXP-18 (D-20).
- `ClickMe2026/Utils/UTF16Prefix.swift`: the grapheme-safe text cap used by the 450-character cancel comment. Reuse it for the 5000-character note (D-19).
- `ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift` and `Subviews/CalendarEventEditorSheet.swift`: currently preview-only; wire them in for D-11/D-13.

### Established Patterns
- View models are `@MainActor ObservableObject` with `@Published apiError`; errors go through `Error.userMessage`; branch on `ErrorCode`, never on message strings (add `ALREADY_PROCESSED` / `TOPIC_CURRENCY_LOCKED` cases if missing).
- Destructive actions use a confirmation dialog (Phase 5 pattern).
- Per-tab navigation paths (`HomeNavigationPath`); "Back to Home" must switch to the Dashboard tab and pop to root.
- Nav-bar pins from plan 05-18 for screens with a trailing dark-theme toolbar button.

### Integration Points
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift` (L68-69, L114, L252-271, plus WR-03's `rateMajor * 100` at about L385/L432) and `TopicEditorView.swift` (L100).
- `ClickMe2026/Model/Requests/ExpertTopicRequest.swift` (L42-54): explicit null encoding.
- `ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift`, `Subviews/AvailabilityDayRow.swift`, `TimeRangePickerSheet.swift`.
- `ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift` (L88) and `RequestDecisionActionFooter.swift` (L60).
- `ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift`, `Expert Mode/Profile/ExpertProfileHomeViewModel.swift` (L40, L69), `Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift` and `ExpertBookingNoteView.swift`.

</code_context>

<specifics>
## Specific Ideas

- The calendar title string is fixed: `ClickMe · {topic} with {client name}` (for example "ClickMe · Career coaching with Jane D.").
- The read-only currency note on a paid topic: "A paid topic's currency can't be changed." (match the backend's wording if the planner finds a closer server string).
- Known out-of-phase warning to absorb here: 04-VERIFICATION anti-pattern WR-03, `rateMajor * 100` in `TopicEditorViewModel` ignores `Money.fractionDigits` and can trap on a long entry. D-05 replaces that path.

</specifics>

<deferred>
## Deferred Ideas

- More topic currencies than CAD and USD. A future phase; the backend allowlist would need to grow.
- A midnight (24:00) end time. Revisit only if a backend test proves slot generation handles hour 24.

### Reviewed Todos (not folded)
- Android cancellation policy link (D-12), Android Delete Account copy, Android Phase 5 parity check, Android remember-login-email, Android Profile Settings empty name, Android clear meeting link: Android-side ports, tracked in the Android repo, not iOS Phase 6.
- Backend PATCH /user/profile name validation: backend, not expert mode.
- Flaky `MakeABookingAvailabilityTests`: client booking test, not expert mode.
- Android push prompt after reinstall, long-lead sweep transient errors, saved cards on account deletion, merge D-12 into backend master: other phases or release checks.

</deferred>

---

*Phase: 06-expert-mode*
*Context gathered: 2026-11-16*
