---
phase: 06-expert-mode
reviewed: 2026-11-17T12:00:00Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - ClickMe2026/Model/BookingCalendarPayload.swift
  - ClickMe2026/Model/Responses/Children/ExpertTopicItem.swift
  - ClickMe2026/Utils/BookingCalendarEventContent.swift
  - ClickMe2026/Utils/ExpertBookingConfirmationContent.swift
  - ClickMe2026/Utils/TopicPriceRules.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingAddToCalendarButton.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
  - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
  - ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
  - ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift
  - ClickMe2026Tests/Model/TopicCurrencyTests.swift
  - ClickMe2026Tests/Utils/BookingCalendarEventContentTests.swift
  - ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift
  - ClickMe2026Tests/Utils/TopicPriceRulesTests.swift
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/CalendarIntent.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/BookingConfirmedScreen.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/bookingsummary/ExpertBookingSummaryScreen.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/upcomingbooking/UpcomingBookingScreen.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/res/values/strings_upcoming_booking.xml
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/CalendarIntentTest.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/bookingsummary/ExpertBookingSummaryScreenTest.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/clientmode/upcomingbooking/UpcomingBookingScreenTest.kt
findings:
  critical: 0
  warning: 2
  info: 7
  total: 9
status: issues_found
---

# Phase 06: Code Review Report (gap-closure plans 06-11..06-18)

**Reviewed:** 2026-11-17T12:00:00Z
**Depth:** standard
**Files Reviewed:** 29 (21 iOS, 8 Android)
**Status:** issues_found

This report supersedes the earlier phase-06 review (preserved in git history at `e7f9cd5`) for the gap-closure scope only: the iOS changes since `e7f9cd5f` and the Android commit `69c4e159`.

## Summary

The change set does three things: (1) it adds Add to Calendar to the expert Booking Summary and the client Upcoming Booking screens through a shared `BookingCalendarEventContent` builder and a `BookingCalendarPayload`-based `CalendarEventEditorSheet`; (2) it treats a blank or malformed stored topic currency as "no currency" through `TopicPriceRules.validCurrencyCode` and `ExpertTopicItem.storedCurrency`; (3) it makes the topic card show cents. Android gets the matching calendar change.

I found no correctness blockers, security issues or data-loss risks. I checked these areas in detail:

- **Offer rule parity.** iOS `offeredStatuses` (`confirmed`, `pendingReschedule`, `inProgress`) matches Android `JOINABLE_BOOKING_STATUSES`. Both use a strict `end > now` and both reject unknown statuses.
- **Title and notes parity.** Both trim topic and name, use the same fallbacks (`Session`, `Client`, `Expert`), and add the message on a new line only when it is not blank.
- **Currency parsing.** `validCurrencyCode` is total, ASCII-only, and rejects the blank code that would cause a 422.
- **Card formatting.** `priceLabel` slices off the `Money` prefix by its own length, which is correct for `$`, `CA$` and `CODE\u{00A0}`.
- **Android launcher.** `rememberCalendarInsertLauncher` keeps the double-tap guard and clears it on resume. The intent carries user text only as extras, never in a URI.

The findings below are an internal inconsistency in the topic editor seed, a presentation pattern that is copied twice and can misbehave on dismissal, and several maintainability items (dead production code after the delegation refactor, duplicated helpers, test coupling to global state).

## Warnings

### WR-01: Topic editor seeds the price text with a different currency than the one it selects

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift:229-240`
**Issue:** For a topic with no valid stored currency, `seedCurrency` is `storedCurrency ?? accountDefault`. That uses the raw, unvalidated, not-necessarily-allowed account default (`accountDefaultCurrency`). `self.currency` is resolved separately through `resolveInitialCurrency(topic:defaultCurrency: newTopicDefaultCurrency(...))`. That path picks the first allowed currency when the account default is not pickable, validates the code, and falls back to `CAD`.

The two can differ. Example: account default `JPY` (zero-decimal) while `allowed_currencies` is `["CAD","USD"]`. `editableAmount` then formats the stored minor amount with 0 digits, so 5000 shows as `5000`, while the editor's `currency` is `CAD` and `parseMinor` and `filterInput` use 2 digits. The seed text and the selected currency disagree by a factor of 100. The untouched-save shortcut hides this on save. If the user edits the text, or the card and editor are compared, the amounts diverge.

The new `TopicsSetupTopicCard` comment says "card and editor agree". They do agree on the symbol and digits for the card, but the editor's seed path was left on the old rule. `TopicsSetupMutationTests` asserts `editor.currency == editor.defaultCurrency`, which only holds while the account default is allowed. The new `newTopicDefaultCurrency` helper is the correct single source, but `defaultCurrency` (the property, documented as the new-topic seed) still returns the raw account default. Server allowlist is currently CAD and USD, both 2 digits, so this is latent today.
**Fix:** Resolve the currency once and use it for both the seed and `currency`:
```swift
let resolvedCurrency = Self.resolveInitialCurrency(
    topic: topic,
    defaultCurrency: Self.newTopicDefaultCurrency(in: userManager.me)
)
let seed = minorAmount.map { Self.editableAmount(minorUnits: $0, currency: resolvedCurrency) } ?? ""
...
self.currency = resolvedCurrency
```
Then make the `defaultCurrency` property return `Self.newTopicDefaultCurrency(in: userManager.me)` so the property, the test assertion and the init agree.

### WR-02: Calendar sheet content is built from the same optional that drives `isPresented`, and the pattern is copy-pasted

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift:85-95` and `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift:74-87`
**Issue:** Both screens present the editor with `.sheet(isPresented: Binding(get: { pendingCalendarEvent != nil }, set: ...))` and an `if let event = pendingCalendarEvent` in the content closure. When the sheet is dismissed (swipe-down, or `onDismiss` setting `pendingCalendarEvent = nil`), the optional becomes nil before the dismissal animation finishes, so the content closure can re-evaluate to an empty view while the sheet is still on screen. This is a known SwiftUI flash. `.sheet(item:)` keeps the item for the whole presentation and removes the hand-made Binding. I could not run the UI to confirm the flash on iOS 18, so treat the visual effect as likely rather than proven. The same ten lines also exist in two files, so a fix has to be made twice.
**Fix:** Make the payload `Identifiable` (a stored `let id = UUID()` set at construction, excluded from `Equatable` if the tests compare payloads, or wrap it in a small `Identifiable` struct) and present with `.sheet(item: $pendingCalendarEvent) { event in CalendarEventEditorSheet(event: event) { pendingCalendarEvent = nil }.ignoresSafeArea() }`. Better, extract one `View` extension, for example `calendarEventSheet(item:)`, and use it in both screens.

## Info

### IN-01: Production code left unused after the delegation refactor

**File:** `ClickMe2026/Utils/ExpertBookingConfirmationContent.swift:25-45` and `ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift:30-33`
**Issue:** `confirmation(...)` now builds its event through `BookingCalendarEventContent.expertEvent`, so `ExpertBookingConfirmationContent.calendarTitle(topic:clientName:)`, `calendarNotes(meetingType:clientMessage:)`, and the `BookingConfirmation.calendarTitle` and `calendarNotes` computed properties have no production caller. Only tests use them. The aliases `clientFallback` and `topicFallback` are still used inside `confirmation`, but they only forward to `BookingCalendarEventContent`.
**Fix:** Delete the wrappers and the computed properties, and point the existing tests at `BookingCalendarEventContent.title` and `.notes` (which `BookingCalendarEventContentTests` already covers). If they are kept for the older tests, say so in the doc comment.

### IN-02: Duplicated `trimmed` helper and a circular dependency between the two content enums

**File:** `ClickMe2026/Utils/BookingCalendarEventContent.swift:123-128`, `ClickMe2026/Utils/ExpertBookingConfirmationContent.swift:116-121`, and `BookingCalendarEventContent.swift:44`
**Issue:** The private `trimmed(_:)` is byte-identical in both enums. `BookingCalendarEventContent.notes` calls `ExpertBookingConfirmationContent.meetingTypeLabel`, while `ExpertBookingConfirmationContent` calls back into `BookingCalendarEventContent` for title, notes and event. The new shared builder therefore depends on the screen-specific one it was meant to serve.
**Fix:** Move `meetingTypeLabel` (and `meetingTypeIcon`) into `BookingCalendarEventContent` or a tiny `MeetingTypeDisplay` helper, and share one `trimmed` (an internal `String?` extension).

### IN-03: Stale plan reference in a doc comment

**File:** `ClickMe2026/Utils/BookingCalendarEventContent.swift:77-78`
**Issue:** "Plan 06-14 calls it from the client Upcoming Booking screen" is already true and will go stale as plans are archived. The project convention is to explain the why, not restate plan numbers.
**Fix:** Say "Used by the client Upcoming Booking screen" or drop the sentence.

### IN-04: Redundant status gate in two views

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift:259` and `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift:315`
**Issue:** Each view wraps the `TimelineView` in `BookingCalendarEventContent.offeredStatuses.contains(...)`, and the view model's `showsAddToCalendar(at:)` then applies the same status rule again through `isOffered`. There are two copies of the rule on the screen path, so a future change to the offered set has to be made in the view as well as the model. The outer check only avoids creating a timer for hidden statuses.
**Fix:** Keep the status check in the view model only and always render the `TimelineView`, or expose one `var offersCalendarTimeline: Bool` on the view model and use it in both views.

### IN-05: Summary view modifier layout and comment

**File:** `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift:72-86`
**Issue:** `.sheet` is chained under `content` at the same indentation as `content`, and a line comment inside the `ZStack` explains the presenter choice. This reads as if `.sheet` belongs to the `ZStack`. SwiftFormat would indent it, and a later reader may move it.
**Fix:** Indent the modifier one level under `content`, and move the "why" comment above `pendingCalendarEvent`'s declaration. Folds into WR-02 if the shared modifier is extracted.

### IN-06: Card currency symbol differs from the editor's for codes other than USD and CAD

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift:26-28` and `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift:116-122`
**Issue:** `TopicsSetupTopicCard.cardSymbol` returns `US$` for USD, otherwise `Money.prefix`. The editor's `currencySymbol` returns `US$`, `CA$`, otherwise the bare ISO code. For any other code they differ (the card shows `€` for EUR, the editor shows `EUR`). The server allowlist is CAD and USD only, and the card comment already tracks the open USD-symbol todo, so there is no user impact today. There are now two places to update when that todo lands.
**Fix:** Have the editor's `currencySymbol` call `TopicsSetupTopicCard.cardSymbol(for:)` (or move the function to `Money`) so one rule drives both.

### IN-07: New tests depend on shared global state

**File:** `ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift:72-85` and `ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift` (new `blankCurrencyFreeTopicSavesARealCurrency`)
**Issue:** `cardAndEditorAgreeOnBlankCurrency` reads `UserManager.shared.me` and hard-codes `editor.currency == "CAD"`. The mutation test asserts `editor.currency == editor.defaultCurrency`, which also depends on `me`. Both pass only while `me` is nil (as in the test host) or has a CAD default. A suite that populates the shared `UserManager` would break them depending on run order. This is the same coupling WR-01 describes in production code. `TopicCurrencyTests` already notes "The test host has no /me" as an assumption.
**Fix:** Build the editor with an injected `UserManager` (the init already takes `userManager:`) or pass `me: nil` into `newTopicDefaultCurrency`, so the assertions do not read the singleton.

---

## Android (commit 69c4e159)

No findings. The parity checks passed:

- `isCalendarEventOffered` uses `JOINABLE_BOOKING_STATUSES` (`confirmed`, `in_progress`, `pending_reschedule`) and `now.isBefore(end)`, matching iOS `isOffered`.
- `calendarEventSpec` trims the message and omits it when blank, matching iOS `notes`.
- Titles and fallbacks resolve in composition (not in the click lambda) and match iOS, including the `Expert` and `Session` fallbacks.
- The shared launcher handles `ActivityNotFoundException` by re-enabling the button before the callback.
- Tests cover the offered set, the unknown-status case and the end boundary.

One non-blocking difference, already documented in the code: Android cannot set a 15-minute reminder through `ACTION_INSERT`, while the iOS sheet adds one.

---

_Reviewed: 2026-11-17T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
