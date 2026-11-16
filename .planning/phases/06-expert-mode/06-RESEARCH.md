# Phase 6: Expert Mode - Research

**Researched:** 2026-11-16
**Domain:** SwiftUI bug-fix phase on the live ClickMe iOS app (expert topics, availability, request accept flow, private note), plus the Android half of EXP-17 (Kotlin/Compose). No backend change.
**Confidence:** HIGH (every finding below was read in this session from the code at iOS HEAD `feb4be5`, the backend repo and the Android repo; the SwiftUI-behaviour claims that rest on community sources are flagged MEDIUM)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** New topics choose their currency with a **segmented control (CAD | USD)** on the topic editor, next to the price field. Android gets a matching Material SegmentedButton (EXP-17 is "both iOS and Android"). Supersedes Android 10-CONTEXT D-10's "no currency picker". Reversibility: costly.
- **D-02:** On edit, a **paid topic's currency is read-only** and shows a short note ("A paid topic's currency can't be changed."). A **free topic shows the picker**. Mirrors the backend rule in `expertTopics.controller.js` (`TOPIC_CURRENCY_LOCKED`). A 422 `TOPIC_CURRENCY_LOCKED` still maps to the server message.
- **D-03:** Switching currency after typing a price **keeps the typed number** (12.50 stays 12.50) and revalidates against the new currency's floor. No conversion. The minimum-price hint updates.
- **D-04:** A new topic defaults to `pricing_limits.min_session_amount.default_currency` from `/me`, else **CAD**.
- **D-05:** The price field accepts decimals using the currency's fraction digits (`Money` already knows the digits). Replaces 02-06's "whole units until Phase 6". An untouched save still sends the stored minor amount and currency (02-06 D-19).
- **D-06:** **Keep the 23:30 cap** on end times. No 24:00 row.
- **D-07:** "Add hours" that would push an end past 23:30 **clamps the end to 23:30**. If the start is already 23:00 or later, the button is disabled.
- **D-08:** A stored time off the 30-minute grid (e.g. 09:15) or an already-stored 24:00 end is **inserted into the picker as a selected row** with its exact value (24:00 labelled "12:00 AM"). No snapping.
- **D-09:** Cancel on the time-range picker reverts: edit a copy and commit on Done.
- **D-10:** **Remove the dot** from the expert hub (`ExpertProfileHomeViewModel.isOnline` and its view). Matches Android.
- **D-11:** **Copy Android 11-CONTEXT D-04/D-05.** On a successful accept, the accept sheet closes and `BookingConfirmedView` **replaces** Request Decision on the stack. Back returns to a refreshed Incoming Requests, never a stale decision screen. "Back to Home" pops to the Dashboard (switching tabs if the flow began elsewhere), refreshed so the pending count drops.
- **D-12:** **409 `ALREADY_PROCESSED`** on accept (or decline): an alert shows the server message; OK pops to a refreshed Incoming Requests. Other errors show the server message and stay on the screen.
- **D-13:** The calendar event title is **exactly `"ClickMe · {topic} with {client name}"`**. Start and end from the booking; description carries the meeting type plus the client's message if present.
- **D-14:** EXP-01: delete asks "Delete this topic?" (Delete / Cancel) before `DELETE /expert/topics/:id`.
- **D-15:** EXP-04: PATCH encodes an explicit `null` for a cleared icon or description.
- **D-16:** EXP-08: comment-only fix on `deleteMyTopic` (soft delete, 404 only), verified in code review.
- **D-17:** EXP-12: expired request cards keep text at full contrast. Dim only the background or badge. LIKELY item: confirm on a device first.
- **D-18:** EXP-14: Client Profile history row already shows real net earnings (02-15). This phase covers any remaining Client Profile earnings surface, formatted through `Money` in the booking currency.
- **D-19:** EXP-16: hard 5000-character cap with a counter. A whitespace-only note is sent as `""`. Leaving with unsaved changes asks "Discard changes?" (Keep editing / Discard). Save disabled when nothing changed.
- **D-20:** EXP-18: the expert Booking Summary shows `ID: #A1B2C3D4` through `BookingShortID`; check Android uses the same short-ID rule.

### Claude's Discretion
- Exact placement and styling of the segmented control and the read-only currency note, within the existing topic editor layout and `Brand` tokens.
- The exact wording of the D-07 disabled state (if any hint is shown).
- How the inserted off-grid row is ordered in the picker list (in time order is expected).

### Deferred Ideas (OUT OF SCOPE)
- More topic currencies than CAD and USD.
- A midnight (24:00) end time. Revisit only if a backend test proves slot generation handles hour 24.
- Reviewed todos not folded: Android cancellation policy link, Android Delete Account copy, Android Phase 5 parity check, Android remember-login-email, Android Profile Settings empty name, Android clear meeting link (Android-side ports); backend PATCH /user/profile name validation; flaky `MakeABookingAvailabilityTests`; Android push prompt after reinstall, long-lead sweep transient errors, saved cards on account deletion, merge D-12 into backend master.

### Folded Todo (in scope)
- "Availability settings: pin the nav bar dark so the Save button stays legible" (`.planning/todos/pending/2026-11-14-availability-settings-toolbar-dark-pin.md`): add the three 05-18 pins to `AvailabilitySettingsView`.

### UI-SPEC user decisions made 2026-11-16 (06-UI-SPEC.md, treat as locked)
- U1: Accept sheet message gets a hard 1,000 UTF-16-unit cap and a `{n}/1000` counter from 800.
- U2: Client hub keeps its online dot; the expert hub loses it.
- U3: `Add hours` disabled when the new slot's start would be 23:00 or later (latest end at or after 22:30).
- U4: Availability touch-target sizes unchanged; slot-delete icon gets an accessibility label.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXP-01 | Deleting a topic asks for confirmation | Menu item at `TopicsSetupTopicCard.swift:46-48` calls `deleteTopic` directly; add `topicPendingDelete` state + `.alert` on `TopicsSetupView` (Plan group B) |
| EXP-02 | Decimal topic price in the topic's currency | Both `validate()` and `isRateBelowMinimum` use `Int(...)` and `rateMajor * 100` (traps on a long entry); replace with a pure digit-split parser keyed on `Money.fractionDigits` (Plan group A) |
| EXP-03 | Editing a topic keeps the topic's own currency | Already shipped by `73e729e`; preserve and pin with tests (Plan group A) |
| EXP-04 | Clear a topic's icon or description | `UpdateExpertTopicRequest` synthesized `Encodable` drops `nil`; needs a custom `encode(to:)` with `encodeNil` (Plan group B) |
| EXP-05 | Cancel on time-range picker reverts | Sheet binds `$viewModel.schedule[di].slots[si]` directly; switch to draft copy committed on Done (Plan group C) |
| EXP-06 | No end time the picker can't show | `minutesToAMPM(1440)` returns `12:00 PM`; Add hours produces a 24:00 end; clamp to 23:30 and disable near end of day (Plan group C) |
| EXP-07 | Off-grid stored time shows as selected | Picker rows are the fixed 30-min grid; insert the stored value as a row (Plan group C) |
| EXP-08 | Stale 409 comment corrected | Two doc comments, comment-only (Plan group B) |
| EXP-09 | Accept shows booking-confirmed screen | `BookingConfirmedView` is orphaned (preview-only); host it inside `RequestDecisionView` (Plan group D) |
| EXP-10 | Calendar event titled with client's name | `CalendarEventEditorSheet.swift` builds the title from `booking.expertName`; rebuild content from the request (Plan group D) |
| EXP-12 | Expired request cards stay readable | `IncomingRequestCard` applies `.opacity(0.55)` to the whole card (Plan group E; device-confirm first) |
| EXP-14 | Client Profile shows real earnings in booking currency | Already delivered by 02-15 for the only earnings surface; verify-only plus device check D5 (Plan group I) |
| EXP-15 | Hub online dot removed | `isOnline` is hard-coded `true`; remove, and also stop feeding it into `PublicExpertProfile(isOnline:)` (Plan group F) |
| EXP-16 | Private note capped, counter, trim, discard prompt | `ExpertBookingNoteViewModel` has no cap, no counter, no discard guard (Plan group G) |
| EXP-17 | Choose CAD or USD on create, iOS and Android | iOS half already shipped (`73e729e`); Android half is genuinely new (Plan group J, separate repo) |
| EXP-18 | Expert Booking Summary shows booking ID, iOS and Android | iOS adds the line; Android already shows it and uses the same first-8 rule (verify-only) (Plan group H) |
</phase_requirements>

## Summary

This is a bug-fix phase, so the research question is "what is the true state of the code and what mechanism is safe", not "which library". No new packages, no new backend work. The single most important correction to `06-CONTEXT.md`: **the iOS half of the currency picker (D-01 to D-04, EXP-03, EXP-17 iOS) is already in the code** (`73e729e`, on `main`, verified: `TopicEditorViewModel.swift:76-118`, `TopicEditorView.swift:98`, `:419-450`). iOS still has the decimal-price bug (EXP-02) in **two** places (`validate()` and the live `isRateBelowMinimum`), and the multiplication `rateMajor * 100` can trap, so the decimal rewrite is a safety fix as well as a feature.

Production backend is healthy for everything this phase needs. `GET https://clickme-backend-production.up.railway.app/health` returned `{"status":"success","commit":"28da165"}` this session, and `28da165` contains the amended paid-topic currency lock, optional PATCH currency, `ALREADY_PROCESSED` 409s and the `acceptSchema` 1000 cap (verified with `git show 28da165:...`). Phase 1's BACK-01 was delivered (accept message becomes a chat message, 01-CONTEXT D-14: "The iOS accept-message field stays"), so the accept-message field stays. BACK-05 and BACK-11 are also complete.

Two places where the UI-SPEC's *mechanism* is wrong or fragile and the planner must override while keeping the observable behaviour (see Open Questions 1 and 2): (1) `HomeNavigationPath.replace(with:)` makes the value the **only** entry on the tab's stack, so using it for "Confirmed replaces Request Decision, Back returns to Incoming Requests" would drop Incoming Requests; and Incoming Requests pushes the decision screen with `navigationDestination(item:)`, which is not in the `NavigationPath` at all. Host the Confirmed screen **inside** `RequestDecisionView` instead. (2) `navigationBarBackButtonHidden(true)` generally kills the swipe-back gesture in SwiftUI, so the Booking Note "swipe works when clean" promise probably cannot be met without UIKit work; plan for the spec's own fallback.

**Primary recommendation:** Ship the phase as ten small plans (groups A to J below), each a pure, unit-testable helper plus a thin view change, with the Confirmed screen hosted inside `RequestDecisionView`, a digit-split decimal parser (never `Int(text) * 100`, `Double` or `Decimal(string:)`), and the Android EXP-17 picker as its own plan in the Android repo.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Price parse, filter, floor check | Client (pure helper) | API (authoritative `PRICE_BELOW_MINIMUM`) | Local check is UX only; server floor wins |
| Paid-topic currency lock | API (`TOPIC_CURRENCY_LOCKED`) | Client (disable picker) | Server is authoritative, client prevents the 422 |
| Clear icon/description | Client request encoding | API (nullable fields) | Wire shape bug is client-side |
| Availability draft/cap/off-grid | Client | API (accepts `HH:mm`, 15-min aligned) | Pure view-model rules |
| Accept/decline outcome, 409 | API | Client (alert + navigation) | Branch on `ErrorCode`, never on text |
| Booking Confirmed content, calendar title | Client | Platform (`EKEventEditViewController`) | System editor owns permission UI |
| Note cap/trim/discard | Client | API (`max(5000)`, `""` allowed) | Server counts UTF-16 units |
| Hub online dot | Client (remove) | -- | No real presence source on this screen |
| Client Profile earnings | API (`earnings_breakdown`) | Client (`Money.format`) | Already implemented |
| Booking ID line | Client | -- | Derived from the route's own `bookingId` |

## Standard Stack

No new dependencies. Everything is first-party SwiftUI/EventKitUI and in-repo helpers.

### Core (in-repo, reuse; do not re-create)
| Library / Helper | Version / Path | Purpose | Why Standard |
|------------------|----------------|---------|--------------|
| `Money` | `ClickMe2026/Utils/Money.swift` | `fractionDigits(for:)`, `format(minorUnits:currency:)`, `format(major:currency:)` | Phase 2 BOOK-10 single formatter; zero-decimal set mirrors the backend [VERIFIED: Money.swift:34, :57-59] |
| `UTF16Prefix` | `Utils/UTF16Prefix.swift` | Grapheme-safe cap in UTF-16 units | Server zod `.max()` counts UTF-16 units [VERIFIED: UTF16Prefix.swift doc comment] |
| `BookingShortID` | `Utils/BookingShortID.swift` | `label(_:)` = `"ID: #A1B2C3D4"` | BOOK-20 rule [VERIFIED: BookingShortID.swift] |
| `DateUtil` | `Utils/DateUtil.swift` | `string(from:format: .shortMonthDayYear)` (`MMM d, yyyy`), `shortTime(_:)` (device 12/24 h) | Project forbids new `DateFormatter`s [VERIFIED: DateUtil.swift:46-47, :99] |
| `BookingErrorMapper.code(for:)` | `Utils/BookingErrorMapper.swift:31-37` | Extract `ErrorCode?` from a thrown `NetworkError.httpError` | Existing, tested; use for `ALREADY_PROCESSED` [VERIFIED] |
| `Error.userMessage` | `Network/Error+UserMessage.swift` | Server message for any error | Project rule: no private `errorMessage(for:)` |
| `HomeShellExit` + `HomeShellAction` | `Utils/HomeShellExit.swift`, `Views/Extensions/HomeNavigationPath.swift` | Back to Home plan; `HomeExpertTab` already conforms to `HomeShellTab` | Phase 4 pattern, has tests [VERIFIED: HomeShellExit.swift tail] |
| `BookingRequestSentPopGestureLock` | `Client Mode/Request Sent/Subviews/` | Disables both pop recognizers in `viewDidAppear` | See Pitfall 6 before reusing |
| Swift Testing + `MockURLProtocol` | `ClickMe2026Tests/` | Unit tests | Project standard |

### Supporting
| Item | Purpose | When to Use |
|------|---------|-------------|
| `EKEventEditViewController` (EventKitUI) | Calendar event sheet, already wrapped by `CalendarEventEditorSheet` | Keep; only change the content builder |
| `NetworkService` JSON encoder | `keyEncodingStrategy = .convertToSnakeCase` [VERIFIED: NetworkService.swift:97-98] | Applies to a custom `encode(to:)` too, so `iconSlug` becomes `icon_slug` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| In-view Confirmed hosting | `HomeNavigationPath.replace(with:)` (UI-SPEC wording) | `replace(with:)` wipes the whole tab stack; see Open Question 1 |
| Digit-split decimal parser | `Decimal(string:)` | `Decimal(string:)` is lenient about trailing junk [ASSUMED]; digit split is exact and total |

**Installation:** none. **Version verification / Package Legitimacy:** this phase installs no external packages, so the legitimacy gate has nothing to check.

## Package Legitimacy Audit

No external packages are installed by this phase (iOS: none; Android: none, the picker uses Material 3 already in the app).

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | -- | -- | -- | -- | -- | -- |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
EXPERT TOPICS (Topics tab / Dashboard "editTopics")
 TopicsSetupTopicCard Menu --Delete--> topicPendingDelete --alert Delete--> DELETE /expert/topics/:id (soft delete, 404 only)
 TopicEditorView
   price text --TopicPriceRules.filter--> text --parse--> minor units --floor(Money/limits)--> validate()
   currency picker (locked if paid at open) -----------------------------^
   validate() -> ValidatedTopic -> TopicsSetupViewModel.saveTopic
        PATCH body: UpdateExpertTopicRequest (icon/description = set | explicit null) -> /expert/topics/:id
        server: 422 TOPIC_CURRENCY_LOCKED / PRICE_BELOW_MINIMUM -> editor alert (server message)

AVAILABILITY (Dashboard "availability")
 AvailabilityDayRow --Add hours--> AvailabilitySlotRules.addHours(existing) -> new slot | nil(disabled)
 slot tap -> sheet(draft copy of slot) --rows from TimeRangeRows(draft, original)--> Done: commit draft | Cancel/swipe: discard
 Save -> PUT /expert/availability (HH:mm; 24:00 round-trips unchanged)

REQUEST FLOW
 Dashboard banner -> IncomingRequestsView --navigationDestination(item:)--> RequestDecisionView
 Push tap -------------------------------> HomeRoute.requestDecision ------> RequestDecisionView
   Accept sheet (message capped at 1000 UTF-16 units) --POST accept-->
        2xx : confirmation = BookingConfirmation(from loaded request); sheet closes; view body shows BookingConfirmedView
                Add to Calendar -> EKEventEditViewController (title "ClickMe · {topic} with {client}")
                Back (system) -> previous screen; Incoming Requests silentReload on appear
                Back to Home -> HomeShellExit.plan(.backToHome, selectedTab) -> reset source tab, select Dashboard
        409 ALREADY_PROCESSED : alert(server message) -> OK -> dismiss() to Incoming Requests (reloads on appear)
        other : alert(server message), stay

NOTE (Booking Summary / Past sessions) -> ExpertBookingNoteView
   text --UTF16Prefix 5000--> noteText ; whitespace-only -> "" on save ; hasChanges -> custom Back -> "Discard changes?" alert
```

### Recommended Project Structure (additions only)
```
ClickMe2026/
├── Utils/
│   ├── TopicPriceRules.swift          # pure: filterInput, parseMinor, isBelowFloor (nonisolated enum, like Money)
│   ├── AvailabilitySlotRules.swift    # pure: addHours, pickerRows(start/end), 24:00 label
│   ├── BookingNoteRules.swift         # pure: cap, normalizedForSave, needsDiscardPrompt (or on the VM)
│   └── ExpertBookingConfirmationContent.swift  # pure: title, notes, body sentence, fallbacks
├── Model/Requests/ExpertTopicRequest.swift     # custom encode(to:) with a three-state field
└── Views/Screens/Expert Mode/ ...              # existing folders; no new folder needed
ClickMe2026Tests/Utils/  # TopicPriceRulesTests, AvailabilitySlotRulesTests, ExpertTopicRequestBodyTests,
                         # RequestDecisionAcceptTests, ExpertBookingNoteViewModelTests, ExpertBookingConfirmationContentTests,
                         # TopicsSetupDeleteConfirmTests, ExpertBookingSummaryIDTests
```
The test and app targets are `PBXFileSystemSynchronizedRootGroup`s, so new files need no `project.pbxproj` edit [VERIFIED: project.pbxproj `path = ClickMe2026;` / `path = ClickMe2026Tests;` under PBXFileSystemSynchronizedRootGroup].

### Pattern 1: Pure digit-split decimal parser (EXP-02)
**What:** Filter as typed, then parse the filtered string by splitting on the one separator and combining integer arithmetic. Never `Double`, never `Int(text) * 100`, never `Decimal(string:)`.
**When:** `validate()`, `isRateBelowMinimum`, and the field's `onChange`/binding filter.
```swift
// Source: mirrors Android TopicPrice.kt (filterInput/parse) which already ships and is tested.
nonisolated enum TopicPriceRules {
    static let maxIntegerDigits = 7   // keeps minor units far inside the server INTEGER max 2147483647

    static func filterInput(_ raw: String, currency: String) -> String {
        let digits = Money.fractionDigits(for: currency)
        var out = ""; var whole = 0; var frac = 0; var sep = false
        for ch in raw {
            if ("0"..."9").contains(ch), ch.isASCII {
                if !sep { if whole < maxIntegerDigits { out.append(ch); whole += 1 } }
                else if frac < digits { out.append(ch); frac += 1 }
            } else if (ch == "." || ch == ","), !sep {
                if digits == 0 { return out }
                out.append(ch); sep = true
            }
        }
        return out
    }

    /// nil = invalid; 0 = free (blank or zero). Total: cannot trap.
    static func parseMinor(_ text: String, currency: String) -> Int? {
        let t = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if t.isEmpty { return 0 }
        let parts = t.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let digits = Money.fractionDigits(for: currency)
        guard parts.count <= 2, parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }) else { return nil }
        let wholeStr = String(parts[0]), fracStr = parts.count == 2 ? String(parts[1]) : ""
        guard wholeStr.count <= maxIntegerDigits, fracStr.count <= digits,
              !(wholeStr.isEmpty && fracStr.isEmpty) else { return nil }
        let w = Int(wholeStr) ?? 0
        let f = Int(fracStr.padding(toLength: digits, withPad: "0", startingAt: 0)) ?? 0
        var scale = 1; for _ in 0..<digits { scale *= 10 }
        return w * scale + f   // <= 9_999_999 * 100 + 99, no overflow
    }
}
```
The live hint and `validate()` must call the **same** function (UI-SPEC: "`isRateBelowMinimum` and `minPriceHint` use the same decimal parse as Save").

### Pattern 2: Three-state encodable field for explicit `null` (EXP-04)
**What:** Swift's synthesized `Encodable` uses `encodeIfPresent`, so a `nil` optional drops the key and the server leaves the old icon/description. Write `encode(to:)` by hand.
```swift
// Source: Swift Encodable semantics; wire contract expertTopics.schema.js:130,134,151,155 (nullable)
enum NullableField<Value: Encodable>: Encodable {
    case omit, set(Value), null
}
struct UpdateExpertTopicRequest: Encodable {
    // ... existing fields ...
    var description: NullableField<String> = .omit
    var iconSlug: NullableField<String> = .omit
    private enum CodingKeys: String, CodingKey { case title, description, durationMins, hourlyRate, isFree, iconSlug, expertiseTagIds }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(title, forKey: .title)
        switch description { case .omit: break; case .set(let v): try c.encode(v, forKey: .description); case .null: try c.encodeNil(forKey: .description) }
        // same for iconSlug; the rest use encodeIfPresent
    }
}
```
Recommendation: the editor owns the whole form, so `saveTopic` on an **edit** sends `.set(text)` or `.null` for both fields every time (no `omit`); keep `.omit` for create-shaped callers and for the test that proves the key is absent when unchanged. Creates keep omitting empty fields (backend create schema also accepts null, but nothing needs it).

### Pattern 3: Confirmed screen hosted inside Request Decision (EXP-09)
**What:** `RequestDecisionViewModel` gains `@Published var confirmation: BookingConfirmation?` (and keeps the raw `sessionStart`, `sessionEnd`, `meetingType` it currently throws away in `map`). On accept success, close the sheet and set `confirmation` in one `withAnimation`. `RequestDecisionView.body` shows `BookingConfirmedView` when `confirmation != nil`, otherwise `content`. The system Back chevron then pops to whatever sat under the decision screen (Incoming Requests, or the Dashboard root for a push-opened decision), which reloads on appear. See Open Question 1 for why not `replace(with:)`.

### Pattern 4: Draft copy for the time-range sheet (EXP-05)
```swift
// TimeRangePickerSheet takes a value and a commit closure, not a Binding
struct TimeRangePickerSheet: View {
    let original: AvailabilityTimeSlot
    @State private var draft: AvailabilityTimeSlot
    let onDone: (AvailabilityTimeSlot) -> Void
    let onCancel: () -> Void
    init(slot: AvailabilityTimeSlot, ..., onDone: ..., onCancel: ...) { original = slot; _draft = State(initialValue: slot); ... }
}
// AvailabilitySettingsView: guard di/si are in range, then
// onDone: { viewModel.schedule[di].slots[si] = $0; viewModel.dismissTimePicker() }
```
Cancel, swipe-down and tap-outside all discard because only Done writes. The two previews in the file that pass `$slot` need updating.

### Anti-Patterns to Avoid
- **`Int(text) * 100` or `Double` for money:** the current code traps (see Pitfall 1).
- **Branching on error message text:** use `BookingErrorMapper.code(for:) == .alreadyProcessed`.
- **A new `DateFormatter`:** use `DateUtil`. (`RequestDecisionViewModel.formatDate/formatTime` already create formatters; do not copy that.)
- **`.confirmationDialog` anchored to a `Menu` item:** UI-SPEC A7 chooses `.alert`; follow it.
- **Hand-editing `Localizable.xcstrings`:** it is already modified in the working tree (uncommitted, unrelated). Stage only intended string changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency digits and money text | A new symbol or digit table | `Money.fractionDigits`, `Money.format(minorUnits:)` | Mirrors backend zero-decimal set; one source |
| Capping pasted text | `String.prefix(5000)` | `UTF16Prefix.prefix(_:limit:)` | `prefix` counts characters, server counts UTF-16 units; emoji would still 422 |
| Calendar editing UI | A custom date/permission UI | `EKEventEditViewController` (already wrapped) | System owns access prompt and denied state |
| Short booking ID | `.prefix(8)` inline | `BookingShortID.label(_:)` | Single rule shared with the client screen |
| Server error code | Decode message text | `BookingErrorMapper.code(for:)` | Existing, tested |
| Time formatting | `DateFormatter` per call | `DateUtil.shortTime`, `DateUtil.string(from:format:)` | Cached; follows 12/24 h |
| Tab exit | Ad hoc `selectedTab = .dashboard` + path resets | `HomeShellExit.plan(.backToHome, selectedTab:)` + a new env action in `HomeExpertView` | Same planner the client shell uses; tested in `HomeShellExitTests` |

**Key insight:** every defect here is a missing seam, not missing capability. Extract the rule into a pure `nonisolated` helper, test it, then wire a thin view change.

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted. (One adjacent fact: the stored availability times that may already be off-grid or `24:00` live on the production server; D-08 exists so an untouched save round-trips them. The backend regex accepts `24:00` [VERIFIED: availability.schema.js:15-18 `/^\d{2}:\d{2}$/`].)

## Common Pitfalls

### Pitfall 1: `rateMajor * 100` traps while typing, not only on Save
**What goes wrong:** `Int("99999999999999999")` parses (17 digits), then `rateMajor * 100` overflows and crashes the app.
**Why it happens:** two sites do it. Quoted: `TopicEditorViewModel.swift:379-385` `} else if let parsed = Int(trimmedRate), parsed >= 0 {` ... `rateMinor = rateMajor * 100`, and `:431-432` `guard !trimmed.isEmpty, let rateMajor = Int(trimmed), rateMajor > 0 else { return false }` / `return rateMajor * 100 < limit.minMinorUnits(for: currency)`. The second one runs on **every keystroke** through the view's `viewModel.isRateBelowMinimum` read [VERIFIED: TopicEditorView.swift:110].
**How to avoid:** 7-integer-digit filter plus the digit-split parser; both sites call `TopicPriceRules.parseMinor`. Add a test that feeds 20 digits and expects no crash.
**Warning signs:** a test that only covers `validate()`.

### Pitfall 2: The untouched-save rule must survive the rewrite
`validate()` compares `trimmedRate == seededRate` and then sends `seededRateMinor` (D-19). Keep that branch first. The seed (`editableAmount`) gives `"12.50"` for 1250 and `"12"` for 1200 [VERIFIED: TopicEditorViewModel.swift:456-471]; both must still parse to the same minor value with the new parser (add a round-trip test).

### Pitfall 3: Changing currency must not re-seed or reformat the text
D-03 says keep the typed text exactly. The text is filtered against the **current** currency's digits only when the user types. If a currency with fewer digits is selected later the text is not re-filtered (CAD and USD are both 2, so this is theoretical). Do not add an `onChange(of: currency)` that rewrites `rate`.

### Pitfall 4: `.decimalPad` hides the dismiss key; the dismiss toolbar already exists
`.numberPad`/`.decimalPad` have no Return key. The editor already attaches `.keyboardDismissToolbar()` [VERIFIED: TopicEditorView.swift:176]. Change only `keyboard: .numberPad` at `:105` to `.decimalPad` when `Money.fractionDigits(for: currency) > 0`. On a comma-locale device the decimal key types `,`; the filter must accept both (D3 device check).

### Pitfall 5: `HomeNavigationPath.replace(with:)` is not "replace the top"
Quoted: `HomeNavigationPath.swift:67-69` `func replace<V: Hashable>(with value: V) {` / `path = NavigationPath([value])`. It leaves exactly one entry. Using it after Accept would make Back go to the tab root and drop Incoming Requests. Also `IncomingRequestsView.swift:71-73` pushes with `.navigationDestination(item: $pushedRequest)`, an item destination the `NavigationPath` does not model, so no path operation can remove it. Host Confirmed in-view (Pattern 3).

### Pitfall 6: Swipe-back and a hidden Back button (Booking Note)
`navigationBarBackButtonHidden(true)` tends to disable the interactive pop gesture in SwiftUI [CITED: https://dev.to/akash_kottil/how-to-keep-the-swipe-back-gesture-working-with-custom-navigation-buttons-in-swiftui-4dhj and Apple Developer Forums thread 745986; community sources, MEDIUM], and iOS 18/26 add a second content-area recognizer. `BookingRequestSentPopGestureLock` only acts in `viewDidAppear` and restores in `viewWillDisappear` [VERIFIED: BookingRequestSentPopGestureLock.swift]; whether a `LockController` inserted later (when `hasChanges` flips true) receives `viewDidAppear` is unproven here [ASSUMED]. Plan A: hidden back + custom 44 pt button + conditional lock (UI-SPEC). Plan B (spec's own fallback): attach the lock unconditionally. Either way the unsaved-changes prompt is guaranteed on the visible Back button; swipe behaviour is the device check D4. Decide Plan B up front if the executor cannot show D4 on a device.

### Pitfall 7: Note save with whitespace-only text can leave the field dirty
Quoted: `ExpertBookingNoteViewModel.swift` `lastPersisted = response.data.note ?? noteText`. If the user typed `"   "`, you send `""`, and the server answers `""`/`null`, `lastPersisted` can become `"   "` (the typed text) and `hasChanges` flips true forever, or the field keeps showing spaces. Set both `noteText` and `lastPersisted` to the **sent** (normalized) text on success. The server stores what it receives [VERIFIED: note.controller.js postNote updates `expert_private_note: note`; `noteSchema` `note: z.string().max(5000)` at booking.schema.js:153-155 allows `""`].

### Pitfall 8: Cap on paste through a `TextEditor` binding
Apply the cap in the binding's `set` (or a VM method), not in a `didSet` that fights the editor cursor. Test the VM method with a 6,000-character string and with an emoji straddling the 5,000th unit.

### Pitfall 9: Accept sheet message vs trimming
`confirmAccept` trims then sends (`RequestDecisionViewModel.swift`), so a capped 1,000-unit message stays valid; the counter and cap live in `RequestDecisionAcceptSheet` (`message` is local `@State`). Cap in the `TextEditor` binding the same way as the note.

### Pitfall 10: Two entry paths to Request Decision, one `isExpired` quirk
Push taps use `HomeRoute.requestDecision(requestId:)`, which carries no `isExpired` (`HomeExpertView.swift:332` `RequestDecisionView(requestId: requestId)`), so a push for an already-expired request shows Accept/Decline; the server answers 409 `ALREADY_PROCESSED` (or similar). The new 409 alert (D-12) covers it. Do not widen the route in this phase.

### Pitfall 11: Shared `ClientProfileHomeUserCard` and the second `isOnline` read
`ExpertProfileHomeScreen.swift` reads `viewModel.isOnline` twice: the user card (`:196`) **and** `PublicExpertProfile(... isOnline: viewModel.isOnline ...)` for the expert's own profile preview (`:297`), which `ExpertProfileHero.swift:78` renders as a dot. Removing the VM property must also pass `isOnline: false` at `:297` (no fake presence anywhere on the expert side). The client hub passes its own `isOnline` to the same card and must look identical (add `showsOnlineDot: Bool = true`).

### Pitfall 12: Stale fixtures in previews and tests
`TimeRangePickerSheetPreview` (`AvailabilitySettingsView.swift:286-308`) and the `BookingConfirmedView` previews use the old initializers. Update them in the same plan or the app target stops compiling.

## Code Examples

### 409 handling that branches on the code
```swift
// Source: BookingErrorMapper.swift:31-37 (existing), ErrorCode.swift:52
//   case alreadyProcessed        = "ALREADY_PROCESSED"
struct SubmitFailure: Identifiable { let id = UUID(); let message: String; let popsOnDismiss: Bool }

} catch {
    let already = BookingErrorMapper.code(for: error) == .alreadyProcessed
    submitFailure = SubmitFailure(message: error.userMessage, popsOnDismiss: already)
}
// View: .alert("Couldn't update request", isPresented: ..., presenting: viewModel.submitFailure) { f in
//     Button("OK", role: .cancel) { if f.popsOnDismiss { dismiss() } }
// } message: { Text($0.message) }
```
Backend message today: `throw new AppError(409, 'ALREADY_PROCESSED', 'This booking request has already been processed.');` [VERIFIED: bookingRequests.controller.js:314 and :405, accept and decline].

### Calendar content as a pure value (testable without EventKit)
```swift
// Source: 06-UI-SPEC copy table; Android strings_booking_confirmed.xml booking_confirmed_calendar_title = "ClickMe · %1$s with %2$s"
struct ExpertBookingConfirmationContent {
    static func calendarTitle(topic: String?, clientName: String?) -> String {
        "ClickMe · \(blankToNil(topic) ?? "Session") with \(blankToNil(clientName) ?? "Client")"
    }
    static func calendarNotes(meetingTypeLabel: String, clientMessage: String?) -> String {
        let m = clientMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return m.isEmpty ? meetingTypeLabel : meetingTypeLabel + "\n" + m
    }
}
```
Today's code: `CalendarEventEditorSheet.swift` `event.title = "ClickMe · \(booking.expertName)"` and `event.notes = booking.meetingNote`, with `event.location` set for non-virtual (expert sessions are always virtual: drop location) [VERIFIED].

### Add hours, clamp and disable (EXP-06, D-07)
```swift
// Source: AvailabilityDayRow.swift add-hours closure today:
//   let newStart = min(maxEnd + 30, 23 * 60)
//   let newEnd = min(newStart + 60, 24 * 60)
nonisolated enum AvailabilitySlotRules {
    static let lastEnd = 23 * 60 + 30
    static func addHours(after maxEnd: Int?) -> (start: Int, end: Int)? {
        guard let maxEnd else { return (9 * 60, 17 * 60) }            // empty enabled day
        let start = maxEnd + 30
        guard start < 23 * 60 else { return nil }                      // disabled at 23:00 or later
        return (start, min(start + 60, lastEnd))
    }
    static func ampmLabel(_ m: Int) -> String { minutesToAMPM(m % (24 * 60)) } // 1440 -> "12:00 AM"
}
```
`minutesToAMPM(1440)` is `12:00 PM` today because `h = 24` gives period `PM` [VERIFIED: AvailabilitySettingsView.swift:35-41]; fix inside `minutesToAMPM` itself (`let h = (minutes / 60) % 24`) so the one function is right everywhere.

### Picker rows with an inserted value
```swift
// rows for the START list: grid times < draft.end, plus original.start if it is off-grid and < draft.end
// rows for the END list:   grid times > draft.start up to 23:30, plus original.end if off-grid or 1440 and > draft.start
static func rows(isStart: Bool, draft: AvailabilityTimeSlot, original: AvailabilityTimeSlot) -> [Int] {
    let grid = stride(from: 0, through: 23 * 60 + 30, by: 30).map { $0 }
    let valid: (Int) -> Bool = { isStart ? $0 < draft.end : $0 > draft.start }
    let extra = (isStart ? original.start : original.end)
    return Set(grid.filter(valid) + (valid(extra) ? [extra] : [])).sorted()
}
```
Filtering the inserted value by the same validity rule keeps the invariant that a list never offers an ordering the other list forbids. Existing `times` = `stride(from: 0, through: 24 * 60 - step, by: step)` [VERIFIED: TimeRangePickerSheet.swift].

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Int(text) * 100` price | Digit-split parse with `Money.fractionDigits` | this phase | Removes the trap and supports cents |
| Sheet binds to stored slot | Draft copy committed on Done | this phase | Cancel really cancels |
| Orphaned `BookingConfirmedView` | Hosted in the decision screen | this phase | Accept ends on a confirmation |
| Android: read-only ISO badge | Android: CAD/USD segmented picker | this phase (Android repo) | Matches iOS and `docs/ios/USD-TOPIC-PRICING.md` |

**Deprecated/outdated in 06-CONTEXT.md:** its line numbers for the topic editor pre-date `73e729e`; trust the live code. Its D-01 to D-04 are already implemented on iOS.

## Plan Decomposition Recommendation

Groups below are file-disjoint except where noted, so they can be ordered freely. One `xcodebuild` per suite; the simulator is shared, so do not run two builds at once.

| Group | Requirements | Files touched | Tests (Wave 0) |
|-------|--------------|---------------|----------------|
| A Topic price + currency pins | EXP-02, EXP-03, EXP-17 iOS | `TopicEditorViewModel.swift`, `TopicEditorView.swift:105`, new `Utils/TopicPriceRules.swift` | `TopicPriceRulesTests`; extend `TopicCurrencyTests` (switch keeps text; untouched save) |
| B Topics list | EXP-01, EXP-04, EXP-08 | `TopicsSetupTopicCard.swift`, `TopicsSetupView.swift`, `TopicsSetupViewModel.swift`, `ExpertTopicRequest.swift`, `ClickMeAPI+ExpertProfile.swift:66-67` comment | `ExpertTopicRequestBodyTests`, `TopicsSetupDeleteConfirmTests` |
| C Availability | EXP-05/06/07 + folded todo | `AvailabilitySettingsView.swift`, `AvailabilityDayRow.swift`, `TimeRangePickerSheet.swift` | `AvailabilitySlotRulesTests` |
| D Accept to Confirmed | EXP-09, EXP-10 (+ U1 cap, 409) | `RequestDecisionView.swift`, `RequestDecisionViewModel.swift`, `RequestDecisionAcceptSheet.swift`, `BookingConfirmedView.swift` + subviews, `CalendarEventEditorSheet.swift`, `HomeExpertView.swift` (env action), `HomeNavigationPath.swift` doc comment | `RequestDecisionAcceptTests`, `ExpertBookingConfirmationContentTests`; extend `HomeShellExitTests` for the expert tab |
| E Expired card | EXP-12 | `IncomingRequestCard.swift`, `IncomingRequestAvatar.swift` | none (visual); grep gate + device D1 |
| F Hub dot | EXP-15 | `ExpertProfileHomeViewModel.swift`, `ExpertProfileHomeScreen.swift`, `ClientProfileHomeUserCard.swift` | grep gate |
| G Booking note | EXP-16 | `ExpertBookingNoteViewModel.swift`, `ExpertBookingNoteView.swift` | `ExpertBookingNoteViewModelTests` |
| H Summary ID | EXP-18 iOS | `ExpertBookingSummaryView.swift` (and VM `bookingIDLabel` if following the client pattern) | `ExpertBookingSummaryIDTests` or extend `BookingShortIDTests` |
| I Client Profile | EXP-14 | none expected | existing `ClientProfileHistoryEarningsTests` stays green; device D5 |
| J Android | EXP-17, EXP-18 verify | `../ClickMe_Android` `MeData.kt`, `TopicEditorViewModel.kt`, `TopicEditorUiState.kt`, `TopicEditorScreen.kt`, new picker subview, `strings_expert_topics.xml`, tests | Android unit tests (below) |
| K UAT checklist | all | `06-DEVICE-UAT-CHECKLIST.md` | Device list from UI-SPEC "Device-only checks" |

Shared-file notes: B and A both touch topic files but different ones (`saveTopic` signature in `TopicsSetupViewModel` is the only crossover: the `description`/`iconSlug` parameters become the three-state values; do B after A or hand B the integration). D is the only plan that edits `HomeExpertView.swift`. Pre-existing uncommitted `ClickMe2026/Localizable.xcstrings` changes must not be swept into any task commit.

### Android half (group J), concrete touch points
- `app/src/main/java/com/uptrendinvestments/clickmeapp/model/responses/MeData.kt`: `PricingLimits` has only `minSessionAmount`; add `@Json(name = "allowed_currencies") val allowedCurrencies: List<String>? = null` (additive, nullable so older servers still decode) [VERIFIED: MeData.kt:28-31 `data class PricingLimits(` / `@Json(name = "min_session_amount") val minSessionAmount: MinSessionAmount,`; grep for `allowedCurrencies` across Android found nothing].
- `TopicEditorUiState` has `currency` and `floorMinor` but no allowed list or lock flag; add both. `TopicEditorViewModel.save()` already sends `TopicHourlyRateBody(TopicPrice.wireAmount(minor, floor), currency)` for create and edit, so the wire side needs no change once `currency` can be changed [VERIFIED: TopicEditorViewModel.kt:326-330].
- The `/me` refresh handler keeps `s.currency` when `isEdit` and resets it for create (`TopicEditorViewModel.kt:146-153`); it must stop resetting a currency the expert has picked on a new topic.
- Add a `SingleChoiceSegmentedButtonRow` subview above `TopicPriceField`, the lock caption, and the USD notice, with the exact strings from `docs/ios/USD-TOPIC-PRICING.md` §4. Android floors and hint already follow `s.currency`.
- Android EXP-18: verified, no change. `expertShortBookingId(id) = id.replace("-", "").take(8).uppercase()` and the string `expert_summary_id = "ID: #%1$s"` [VERIFIED: ExpertBookingSummaryUiState.kt:112, strings_expert_booking_summary.xml:7]. For a canonical UUID the first 8 hex characters are identical to iOS `uuidString.prefix(8)`.
- Android calendar title already `ClickMe · %1$s with %2$s` [VERIFIED: strings_booking_confirmed.xml:7].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode + xcodebuild | all iOS plans | yes | Xcode 26.5 (17F42) | -- |
| iOS Simulator `iPhone 17` | test commands | yes (two devices share the name `iPhone 17`; the prior-phase command `name=iPhone 17,OS=latest` has worked) | -- | pass a device UUID if xcodebuild reports ambiguity |
| Production backend `/health` | UAT; accept 409; topic lock | yes | commit `28da165` | -- |
| Real iPhone | device checks D1 to D6 | user-owned, not probed | -- | checks stay `human_needed`, as in earlier phases |
| Gradle wrapper + JDK + Android SDK | group J | `gradlew` present, JDK 18 on PATH, `~/Library/Android/sdk` present; a build was not run [ASSUMED to work] | -- | defer Android build to the Android plan's own gate |
| Backend repo / jest | none (no backend change) | not needed | -- | -- |

**Missing dependencies with no fallback:** none. **Live-data warning:** every environment is production with live Stripe keys; device checks that accept or decline use test accounts and a free topic.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests`; `MockURLProtocol` for HTTP; Android: JUnit/Robolectric-style unit tests under `app/src/test` |
| Config file | `ClickMe2026/AllTests.xctestplan`; no Wave 0 framework install |
| Quick run command | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| Full suite command | same with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests -collect-test-diagnostics never` (smoke suites hit production; never run) |
| Build gate | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` then `BUILD SUCCEEDED` and no new warnings in touched files (before/after `comm -13`, as plan 05-18 does) |

Pattern proven by `.planning/phases/05-signup-mode-switch-and-account/05-18-PLAN.md` and 05-RESEARCH. A run counts only with a non-zero test count; `MockURLProtocol` suites use `.serialized`; one suite per `xcodebuild`.

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command (`-only-testing:ClickMe2026Tests/...`) | File Exists? |
|--------|----------|-----------|----------------------------------------------------------|-------------|
| EXP-02 | `12.50`->1250, `12,50`->1250, `12.5`->1250, `.5`->50, blank/`0`->0 free, 3 decimals invalid, 8 integer digits filtered, 20 digits no crash, zero-decimal drops separator, untouched seed round-trips, live floor flag matches Save | unit | `TopicPriceRulesTests` | no, Wave 0 |
| EXP-03 / EXP-17 iOS | Currency switch keeps text; paid topic locked; free topic unlocked; default from limits else CAD; typed price keeps stored currency | unit | `TopicCurrencyTests` (extend) | yes |
| EXP-04 | PATCH JSON has `"icon_slug":null` and `"description":null` when cleared; key absent for `.omit`; `hourly_rate`/`is_free` unchanged | unit (encode with `.convertToSnakeCase`) | `ExpertTopicRequestBodyTests` | no, Wave 0 |
| EXP-01 | 0 DELETE requests before confirm; exactly 1 after; cancel clears pending | unit (stubbed) | `TopicsSetupDeleteConfirmTests` | no, Wave 0 |
| EXP-08 | Comment-only | code review + grep: `! grep -rn "Returns 409 if the topic has active" ClickMe2026` | n/a | n/a |
| EXP-05 | Draft edits do not touch stored slot; commit writes; cancel leaves | unit on the pure draft/commit helper | `AvailabilitySlotRulesTests` | no, Wave 0 |
| EXP-06 | `addHours`: maxEnd 22:00 -> 22:30-23:30; 22:30 -> nil; 23:30 -> nil; 24:00 -> nil; 22:15 -> 22:45-23:30; empty -> 9:00-17:00; `minutesToAMPM(1440)=="12:00 AM"` and 0 == "12:00 AM", 720 == "12:00 PM" | unit | `AvailabilitySlotRulesTests` | no, Wave 0 |
| EXP-07 | Rows for 09:15 start include 555 sorted and selected; 1440 end row present; inserted row dropped when invalid against the other draft value | unit | `AvailabilitySlotRulesTests` | no, Wave 0 |
| EXP-09 | Accept 2xx sets `confirmation` and closes sheet; no `isAccepted` frame; double tap one POST | unit (stubbed, `.serialized`) | `RequestDecisionAcceptTests` | no, Wave 0 |
| D-12 | 409 `ALREADY_PROCESSED` on accept and decline -> failure with `popsOnDismiss` true and server message; 500 -> false, stays | unit (stubbed) | `RequestDecisionAcceptTests` | no, Wave 0 |
| EXP-10 | Title `ClickMe · Career coaching with Jane D.`; fallbacks `Session` / `Client`; notes = type only, or type + newline + message; no location | unit | `ExpertBookingConfirmationContentTests` | no, Wave 0 |
| U1 | Accept message cut at 1,000 UTF-16 units on a boundary; counter threshold 800 | unit | `RequestDecisionAcceptTests` | no, Wave 0 |
| Back to Home | Plan resets source tab, shows `.dashboard` | unit | `HomeShellExitTests` (extend with `HomeExpertTab`) | yes |
| EXP-12 | No whole-card opacity on expired | grep gate: `! grep -n "opacity(request.isExpired" "ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift"`; device D1 | grep + device | n/a |
| EXP-14 | Existing mapping stays green | unit | `ClientProfileHistoryEarningsTests`, `ClientProfileBookingCardTests` | yes |
| EXP-15 | No `isOnline` in `ExpertProfileHomeViewModel`; client card unchanged | grep gate: `! grep -n "isOnline" "ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift"` | grep | n/a |
| EXP-16 | 6,000 chars -> 5,000; emoji at the boundary not split; whitespace-only saves `""` and leaves `hasChanges` false; edit then revert to persisted -> no prompt; save error keeps text and `hasChanges`; save in flight counts as changed | unit (stubbed) | `ExpertBookingNoteViewModelTests` | no, Wave 0 |
| EXP-18 | `bookingIDLabel` is `ID: #` + first 8 chars upper-cased | unit | `BookingShortIDTests` (extend) | yes |
| Nav-bar pins | The three pins on Availability and Confirmed | grep gate: `grep -c "toolbarColorScheme(.dark" <file>` >= 1 | grep | n/a |
| Device | D1 to D6 from UI-SPEC | manual UAT | `06-DEVICE-UAT-CHECKLIST.md` | Wave 0 |
| Android EXP-17 | Picker lists `allowed_currencies`; default from limits else CAD; paid edit disabled; free edit enabled; switching keeps text and re-reads floor; USD notice only on USD; request body carries picked currency | Android unit | `./gradlew testDebugUnitTest --tests '*TopicEditorViewModelTest' --tests '*TopicEditorScreenTest'` | extend existing |

### Sampling Rate
- **Per task commit:** the one suite for the touched helper (quick run).
- **Per wave merge:** suites touched in the wave plus build gate plus regressions: `TopicCurrencyTests`, `HomeNavigationPathTests`, `HomeShellExitTests`, `PushRoutePlannerTests`, `ClientProfileHistoryEarningsTests`, `ExpertRescheduleWindowTests`.
- **Phase gate:** full suite green, grep gates, then `/gsd-verify-work` and the device checklist.

### Wave 0 Gaps
- [ ] New suites listed above (all under `ClickMe2026Tests/`; no pbxproj edit).
- [ ] Seams: `TopicsSetupViewModel` needs an `api:` already present (`init(api:userManager:)`), plus `topicPendingDelete`/`confirmDelete()`; `RequestDecisionViewModel(requestId:isExpired:api:)` already injectable; `ExpertBookingNoteViewModel(bookingId:api:)` already injectable; `TopicsSetupViewModel.saveTopic` needs a way to record the body (assert via `MockURLProtocol.recordedRequests`).
- [ ] `06-DEVICE-UAT-CHECKLIST.md` (written by the last plan, Phase 4/5 format).

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block on high).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no auth change) | -- |
| V3 Session Management | no | -- |
| V4 Access Control | no new surface; note and topic endpoints are server-scoped to the owner (uniform 404) [VERIFIED: note.controller.js postNote scoping] | server |
| V5 Input Validation | yes | client caps (price 7 integer digits, note 5000 and accept message 1000 UTF-16 units) as UX; server zod is authoritative (`max(2147483647)` price, `max(5000)` note, `max(1000)` accept) |
| V6 Cryptography | no | -- |
| V8 Data Protection | yes (light) | No new logging; the private note must never be logged. Do not copy the existing `print("push: TAP received ...")` diagnostics |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Integer overflow / crash on a hostile or fat-fingered price | Denial of service (client crash) | Filter to 7 integer digits; digit-split parse that cannot overflow (Pitfall 1) |
| Charging in the wrong currency | Tampering (money) | Always send the topic's own currency; locked picker for paid; server `TOPIC_CURRENCY_LOCKED` backstop |
| Double accept / replay | Tampering | `isSubmitting` guard (shipped); server 409 `ALREADY_PROCESSED` handled |
| Oversized free text | Tampering / DoS | UTF-16 cap before send; server rejects with 422 otherwise |
| Calendar event leaks client message | Information disclosure | Notes only include the client's own message on the expert's own device; user reviews the system editor before saving |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `navigationBarBackButtonHidden(true)` disables swipe-back in SwiftUI on the current OS (community sources only) | Pitfall 6 | The Booking Note swipe design could be simpler than planned, or the fallback unneeded; device check D4 settles it |
| A2 | A `LockController` inserted after the view appeared still gets `viewDidAppear` | Pitfall 6 | Conditional lock does nothing; use the unconditional fallback. Moot since 2026-11-16: the lock is attached unconditionally (Open Question 2, D-19 amendment) |
| A3 | `Decimal(string:)` accepts a numeric prefix and ignores trailing junk | Standard Stack, Pattern 1 | None for the recommendation (digit-split avoids it) |
| A4 | Android Gradle build works in this environment | Environment Availability | Android plan may need environment fixes first |
| A5 | `.alert` is right over `.confirmationDialog` when a `Menu` item is the trigger (UI-SPEC A7: iPad popover anchoring) | Anti-Patterns | Cosmetic only |
| A6 | A push-opened decision for an already-expired request shows Accept and the server returns the 409/`ALREADY_PROCESSED` path | Pitfall 10 | Different error code would show the generic alert instead of popping; still safe |
| A7 | PATCH from the editor may always send explicit `.set`/`.null` for icon and description (full-form semantics) instead of diffing against the original | Pattern 2 | None functionally; UI-SPEC prefers omit-when-unchanged, which needs the original values threaded through |

## Open Questions (RESOLVED)

All five questions are resolved (planning, 2026-11-16). Each item names the resolving plan.

1. **UI-SPEC says "the replace uses the existing `HomeNavigationPath.replace(with:)`". Should the planner override it?**
   - What we know: `replace(with:)` leaves one entry (HomeNavigationPath.swift:67-69). Incoming Requests opens the decision screen with `.navigationDestination(item: $pushedRequest)` (IncomingRequestsView.swift:71-73), outside the path. Push taps open it as `HomeRoute.requestDecision` through the path.
   - What's unclear: whether the user cares about the mechanism or only the behaviour (D-11 states behaviour: Back returns to a refreshed Incoming Requests).
   - Recommendation: host `BookingConfirmedView` inside `RequestDecisionView` (Pattern 3). It satisfies D-11 and works for both entry paths with no path surgery. Tell the plan-checker the UI-SPEC mechanism was deliberately superseded; update the UI-SPEC sentence in the plan's notes.
   - **RESOLVED: 06-05** — `BookingConfirmedView` is hosted inside `RequestDecisionView`. The user signed off on this before execution (2026-11-16), recorded as the D-11 amendment in 06-CONTEXT.md; the behaviour D-11 locks is unchanged. Not re-asked at the device check.

2. **Booking Note swipe-back.**
   - What we know: UI-SPEC section 7 wants swipe to work when clean and be locked when dirty; hiding the back button probably disables the gesture entirely.
   - Recommendation: build custom Back + discard alert first (guaranteed), attach the lock unconditionally if D4 shows the conditional lock fails. Decide at the device check, do not block the plan.
   - **RESOLVED: 06-07** — user decision 2026-11-16, recorded as the D-19 amendment in 06-CONTEXT.md: the pop gesture is always disabled (`BookingRequestSentPopGestureLock` attached unconditionally), and the custom Back with the "Discard changes?" alert when dirty is the only exit. Nothing is deferred to the device check; D4 verifies the swipe is blocked and Back prompts when dirty and pops when clean.

3. **USD symbol.** `docs/ios/USD-TOPIC-PRICING.md` §0 item 5 says USD renders as `US$`, but the shipped `Money` table uses `$` for USD (Phase 2 D-10) and the topic card therefore shows `$12.50` while the editor label says `US$`. Out of this phase; do not "fix" it in a Phase 6 plan. Raise it for Phase 8 or a follow-up.
   - **RESOLVED: 06-10** — out of Phase 6. 06-10 writes the todo `2026-11-16-usd-symbol-us-dollar-prefix.md` asking for a `$` versus `US$` decision before Phase 8; 06-01 leaves `Money` and the editor label unchanged.

4. **U4 accessibility label.** UI-SPEC says the slot-delete button "gains the accessibility label `Delete time range`", but the code already has `.accessibilityLabel("Delete time slot")` (`AvailabilityDayRow.swift`, delete button). It is a rename, not an addition. Recommendation: rename to the spec string; harmless.
   - **RESOLVED: 06-03** — the shipped label is renamed to `Delete time range` (UI U4); touch targets unchanged.

5. **Expert hub public-profile preview.** Confirm `isOnline: false` (Pitfall 11) is what the user wants for the expert's own profile preview; the alternative is to keep the hero dot. D-10 says remove the online dot on the hub; the preview feeding `true` is the same fake presence.
   - **RESOLVED: 06-06** — the self-preview is built with `isOnline: false`, so no fake presence shows anywhere on the expert side (D-10). 06-10's device checklist lists it as a KEEP or CHANGE item so the user can still judge it on hardware.

## Sources

### Primary (HIGH confidence, read this session)
- iOS repo at `feb4be5`: `TopicEditorViewModel.swift`, `TopicEditorView.swift`, `TopicsSetupViewModel.swift`, `TopicsSetupView.swift`, `TopicsSetupTopicCard.swift`, `ExpertTopicRequest.swift`, `Money.swift`, `UTF16Prefix.swift`, `BookingShortID.swift`, `DateUtil.swift`, `AvailabilitySettingsView.swift`, `AvailabilitySettingsViewModel.swift`, `AvailabilityDayRow.swift`, `TimeRangePickerSheet.swift`, `RequestDecisionView.swift`, `RequestDecisionViewModel.swift`, `RequestDecisionAcceptSheet.swift`, `RequestDecisionActionFooter.swift`, `BookingConfirmedView.swift`, `BookingConfirmedViewModel.swift`, `BookingConfirmedHeadline.swift`, `BookingConfirmedCard.swift`, `CalendarEventEditorSheet.swift`, `BookingCalendarPayload.swift`, `IncomingRequestsView.swift`, `IncomingRequestCard.swift`, `IncomingRequestAvatar.swift`, `ExpertDashboardView.swift`, `HomeExpertView.swift`, `HomeNavigationPath.swift`, `HomeShellExit.swift`, `BookingRequestSentPopGestureLock.swift`, `ClientProfileViewModel.swift`, `ClientProfileBookingCard.swift`, `ExpertProfileHomeViewModel.swift`, `ExpertProfileHomeScreen.swift`, `ClientProfileHomeUserCard.swift`, `ExpertBookingNoteViewModel.swift`, `ExpertBookingNoteView.swift`, `ExpertBookingSummaryView.swift`, `ErrorCode.swift`, `BookingErrorMapper.swift`, `NetworkService.swift`, `ClickMeAPI+Booking.swift`
- Backend repo (`master` HEAD `35bc749`; production `28da165`): `src/schemas/expertTopics.schema.js`, `src/controllers/expertTopics.controller.js` (patchTopic, softDeleteTopic), `src/schemas/booking.schema.js` (acceptSchema L189-191, noteSchema L153-155), `src/schemas/availability.schema.js`, `src/controllers/availability.controller.js` (validateDaySlots), `src/controllers/bookingRequests.controller.js` (L314, L405), `src/controllers/note.controller.js`, `openapi/clickme-api.yaml` (409 ALREADY_PROCESSED), `docs/ios/USD-TOPIC-PRICING.md` §0 to §4
- Live check: `curl https://clickme-backend-production.up.railway.app/health` -> `{"status":"success","commit":"28da165"}`; `git merge-base --is-ancestor 989a50d 28da165` true
- Android repo: `TopicPrice.kt`, `TopicPriceField.kt`, `TopicEditorUiState.kt`, `TopicEditorViewModel.kt`, `MeData.kt`, `ExpertBookingSummaryUiState.kt`, `strings_expert_booking_summary.xml`, `strings_booking_confirmed.xml`; `11-CONTEXT.md` D-04 to D-07
- Planning: `06-CONTEXT.md`, `06-UI-SPEC.md`, `REQUIREMENTS.md`, `ROADMAP.md` Phase 6, `STATE.md`, `01-CONTEXT.md` D-14, `01-09-SUMMARY.md`, `05-RESEARCH.md` (validation pattern), `05-18-PLAN.md`
- Contrast arithmetic re-computed with the WCAG formula this session: dimmed `onSurfaceVariant` text about 4.0:1 (UI-SPEC says 3.91), dimmed `onSurface` about 5.0:1 (UI-SPEC 4.85); full-opacity text on `#0e0e0e` is 11.36:1 (`onSurfaceVariant`) and 14.98:1 (`onSurface`) (the UI-SPEC lists the two labels in the other order). Conclusion unchanged: below 4.5:1 for the secondary text, so EXP-12 stays LIKELY pending the device check.

### Secondary (MEDIUM confidence)
- [dev.to: keeping swipe-back with custom navigation buttons in SwiftUI](https://dev.to/akash_kottil/how-to-keep-the-swipe-back-gesture-working-with-custom-navigation-buttons-in-swiftui-4dhj), [Apple Developer Forums 745986](https://developer.apple.com/forums/thread/745986), [Apple Developer Forums 818848](https://developer.apple.com/forums/thread/818848): hidden back button disables swipe-back; iOS 18+/26 use a second recognizer

### Tertiary (LOW confidence)
- None beyond the Assumptions Log.

## Project Constraints (from CLAUDE.md)

- **Cross-repo:** backend owns the API contract; read `openapi/clickme-api.yaml` and `docs/ios/` before touching `Network/` or `Model/` (done above). Android is a port of iOS; EXP-17 and EXP-18 need Android commits, **one commit per repo**. No backend change is expected; if one appears, say so and commit in the backend repo.
- **Do not assume another repo already has a change.** The Android half of EXP-17 is not done (no `allowed_currencies` model on Android).
- **Backend deploys must not break the live App Store build** (memory); this phase has none.
- **Stack:** SwiftUI, Swift 6 strict concurrency, iOS 18+, Xcode 26; no rewrites. View models are `@MainActor`; pure helpers use `nonisolated enum` like `Money`.
- **Conventions:** `Id` not `ID`; `apiError` for new view-model errors; `Error.userMessage` only (no private `errorMessage(for:)`); branch on `ErrorCode`, never on message text; no `try?` on writes; no `print` of tokens/payloads, new debug logging under `#if DEBUG`; `// MARK: -` sections; `///` doc comments; Xcode header on every Swift file; 4-space indent; `DateUtil` not new `DateFormatter`s; screen-prefixed names for new subviews; new screens end in `View`; do not widen large view models (extract helpers).
- **Definition of done:** unit tests where logic is testable, clean `xcodebuild` with no new warnings, device check via a UAT checklist, backend tests for backend changes (none here).
- **GSD workflow:** edits go through a GSD command; `commit_docs` is true.
- **Preview code** must compile in Release (no `#if DEBUG` around `#Preview` bodies).
- **No toast** is posted by any Phase 6 action (UI-SPEC). No new Brand token, no new shared component.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new; every helper opened and read.
- Architecture: HIGH for the code facts; MEDIUM for the SwiftUI swipe-back behaviour (community sources) and the unproven lock-after-appear.
- Pitfalls: HIGH; the traps and the `replace(with:)` behaviour are quoted from source.

**Research date:** 2026-11-16
**Valid until:** 2026-12-16 (stable code; re-check `/health` before UAT because the backend can move)
