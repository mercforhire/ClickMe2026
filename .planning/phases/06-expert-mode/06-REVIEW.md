---
phase: 06-expert-mode
reviewed: 2026-11-16T00:00:00Z
depth: standard
files_reviewed: 50
files_reviewed_list:
  - ClickMe2026/Model/Requests/ExpertTopicRequest.swift
  - ClickMe2026/Network/ClickMeAPI+ExpertProfile.swift
  - ClickMe2026/Utils/AvailabilitySlotRules.swift
  - ClickMe2026/Utils/ExpertBookingConfirmationContent.swift
  - ClickMe2026/Utils/HomeShellExit.swift
  - ClickMe2026/Utils/TopicPriceRules.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
  - ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Availability/Subviews/AvailabilityDayRow.swift
  - ClickMe2026/Views/Screens/Expert Mode/Availability/Subviews/TimeRangePickerSheet.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/BookingConfirmedCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/BookingConfirmedHeadline.swift
  - ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift
  - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestAvatar.swift
  - ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift
  - ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionAcceptSheet.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupViewModel.swift
  - ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift
  - ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift
  - ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
  - ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift
  - ClickMe2026Tests/Model/TopicCurrencyTests.swift
  - ClickMe2026Tests/Utils/AvailabilitySlotRulesTests.swift
  - ClickMe2026Tests/Utils/BookingShortIDTests.swift
  - ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift
  - ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift
  - ClickMe2026Tests/Utils/HomeShellExitTests.swift
  - ClickMe2026Tests/Utils/MoneyCallSiteTests.swift
  - ClickMe2026Tests/Utils/TopicPriceRulesTests.swift
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/model/responses/MeData.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/subviews/TopicCurrencyPicker.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorScreen.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorUiState.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorViewModel.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/res/values/strings_expert_topics.xml
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/subviews/TopicEditorSubviewsTest.kt
  - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorViewModelTest.kt
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-11-16
**Depth:** standard
**Files Reviewed:** 50
**Status:** issues_found

## Summary

Reviewed the Phase 6 iOS diff (`59da049..HEAD`) and the Android commit `da498620` (currency picker), reading each changed source file in full and cross-checking the API-facing pieces against the backend (`bookingRequests.controller.js`, `expertTopics.controller.js`, `note.controller.js`, `expertTopics.schema.js`).

The core money-path logic is sound. `TopicPriceRules` is integer-only and cannot trap. The PATCH `NullableField` encoding is correct. `ExpertBookingNoteViewModel`'s UTF-16 cap matches the server `max(5000)`. The accept flow's double-tap guard, the `ALREADY_PROCESSED` pop decided by `ErrorCode` rather than message text, and the delete-confirmation alert all behave as specified. I found no security issues, no data-loss paths and nothing that blocks the release.

There are four warnings. The most important one is the one the UI audit raised: the push route for Request Decision cannot know a request is expired. It is confirmed and classified WARNING (WR-01). The others are an empty-currency edge on legacy free topics (WR-02), a silent decimal/thousands mis-parse on paste (WR-03), and an iOS/Android parity gap in the USD notice (WR-04).

## Warnings

### WR-01: Expired or already-settled request opened from a push still shows Accept and Decline

**File:** `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift:338`, `ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionViewModel.swift:76-88,151`, `ClickMe2026/Model/Responses/BookingRequestDetail.swift:16-49`

**Verification of the UI-audit finding:** Confirmed. There are three entry points to `RequestDecisionView(requestId:)`:
- `IncomingRequestsView.swift:72` forwards `isExpired`, taken from the list row (`status == "expired" || expiresAt <= now`).
- `LiveFetchRequestDecisionBootstrap` (`RequestDecisionView.swift:414`) computes it from the list row.
- The push route, `HomeExpertView.swift:338` (`case let .requestDecision(requestId)`), calls `RequestDecisionView(requestId: requestId)` and so takes the default `isExpired: false`.

`forceLoad` never corrects this afterwards. `BookingRequestDetail` has no status or expiry field, and the backend `getDetail` selects `status` but does not return it or `expires_at` (`bookingRequests.controller.js:158-215`). So for a push-opened request that has expired, or was already accepted or declined on another device, the screen renders the client message, the earnings section and the Accept/Decline footer. The expired banner never shows.

**Classification: WARNING, not BLOCKER.** The server guards the mutation. Accept and decline use a compare-and-set on `status='pending_approval'` and answer 409 `ALREADY_PROCESSED` (`bookingRequests.controller.js:300-314,401-405`). The new D-12 path then shows the server message and pops. So no wrong charge or double-accept results. The cost is a misleading screen and a wasted tap on the most common way an expert reaches a request, which is the push notification.

There is a backend caveat. `accept` does not check `expires_at`. It only checks `status`. A request past `expires_at` but not yet swept by `expireBookings` (runs every 5 minutes) can still be accepted server-side. The client cannot compensate for that, and a client-side expiry check would reduce but not close the window.

**Fix:** Make the detail response self-describing, additively so the Android build is unaffected. In the backend `getDetail`, return `status` and `expires_at`. Then in iOS:

```swift
// BookingRequestDetail
let status: String?
let expiresAt: Date?

// RequestDecisionViewModel.forceLoad, before mapping
let serverExpired = detail.status == "expired"
    || (detail.expiresAt.map { $0 <= Date() } ?? false)
let settled = detail.status.map { $0 != "pending_approval" && $0 != "expired" } ?? false
isExpired = isExpired || serverExpired || settled   // or add a separate `isSettled` banner
request = Self.map(detail: detail, isExpired: isExpired)
```

If the backend change is deferred, at least pass a push-time `isExpired` where the push payload carries one. This needs a matching Android check, since Android uses the same contract.

### WR-02: Legacy free topic with no stored currency opens with an empty-string currency and cannot be saved

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift:165-175,207-221` (new coverage in `ClickMe2026Tests/Model/TopicCurrencyTests.swift`)

**Issue:** The backend serializes a null `price_currency` as `''` (`expertTopics.controller.js:95`: `(topic.price_currency || '').toUpperCase()`). The controller comments confirm free topics can have `price_currency NULL`. `ExpertTopicItem.Price.currency` decodes that as `""`, not `nil`. `resolveInitialCurrency` does `(stored ?? defaultCurrency)`, so `""` is kept and the editor starts with `currency == ""`:
- `pickableCurrencies` adds `""` as a third segment with an empty label, and it is the selected one.
- `validate()` returns `currency: ""`, and `saveTopic` sends `hourly_rate.currency: ""`.
- The backend rejects it. The PATCH schema validates the currency against an allowlist (`isAllowedTopicCurrency`), so the expert sees a 422 on a topic they have not changed.

Android handles this: `TopicPrice.resolveCurrency` and `cleanCode` treat anything that is not a 3-letter code as absent. The `TopicCurrencyTests` fixtures only cover `"CAD"` and `"USD"`, so the gap is not pinned.

**Fix:** Normalize blank and invalid stored currencies to `nil` in both the seed and the lock rule:

```swift
private static func storedCurrency(of topic: ExpertTopicItem?) -> String? {
    let raw = topic?.hourlyRate?.currency ?? topic?.price.currency
    let trimmed = raw?.trimmingCharacters(in: .whitespaces)
    guard let trimmed, trimmed.count == 3 else { return nil }
    return trimmed.uppercased()
}
// use it in resolveInitialCurrency, isCurrencyLocked and the init's storedCurrency
```

Add a `TopicCurrencyTests` row for `"currency": ""` on a free topic.

### WR-03: A pasted grouped price ("12,000") is silently read as 12.00

**File:** `ClickMe2026/Utils/TopicPriceRules.swift:57-78,92-111` (pinned by `ClickMe2026Tests/Utils/TopicPriceRulesTests.swift`, "12,50" row)

**Issue:** The field treats both `.` and `,` as the decimal separator, since the keyboard decides which one is typed. A paste of `12,000` or `1,000.50` is filtered: the first separator wins and fraction digits past the currency's count are dropped. `12,000` becomes `12,00`, which parses to 1200 minor units. The expert asked for 12,000 and gets 12.00. This is a paid price in a live-payment app. The `isBelowFloor` check only helps when the result lands under the floor, and `12,00` (12.00) clears a 5.00 floor with no warning. The field does show `12,00`, but nothing says that digits were dropped.

Android's `TopicPrice.filterInput` is the stated source of this behavior, so the same defect exists there.

**Fix:** Do not silently truncate a fraction that is longer than the currency allows. Treat it as invalid so `parseMinor` returns `nil` and Save shows the validation message:

```swift
// filterInput: keep the extra fraction digit(s) instead of dropping them,
// so parseMinor rejects "12,000" ("12.000" has 3 fraction digits, USD allows 2).
```

Or, if typing-time capping is wanted, drop only on a typed (single-character) change and reject on a multi-character paste. Fix the same way on Android.

### WR-04: Android hides the USD conversion-fee notice when only one currency is pickable; iOS shows it

**File:** `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/subviews/TopicCurrencyPicker.kt:46` (iOS reference: `TopicEditorView.swift:118`)

**Issue:** `TopicCurrencyPicker` starts with `if (currencies.size < 2) return`, and the USD notice is rendered inside it. On iOS the notice is a separate block under the price field, shown whenever `currency == "USD"` (`showsUSDFXNotice`). So an Android expert whose only allowed or stored currency is USD never sees the Stripe conversion-fee warning. That happens when `allowed_currencies == ["USD"]`, or when `pickableCurrencies` collapses to one entry. This is the money-disclosure copy the contract says to show "only while USD is selected", and it is meant to be shown regardless of picker visibility. The Android test `TopicEditorSubviewsTest` covers the two-currency case only.

**Fix:** Render the notice outside the picker's early return, driven by `state.showsUsdNotice`:

```kotlin
if (state.showsCurrencyPicker) { TopicCurrencyPicker(...) }
if (state.showsUsdNotice) { UsdNotice() }   // or hoist into its own composable under PriceSection
```

Add a Compose test for a single `["USD"]` allowed list.

## Info

### IN-01: Android new-topic default can fall outside the allowed list; iOS picks the first allowed one

**File:** `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/TopicEditorViewModel.kt:107-130` (iOS: `TopicEditorViewModel.swift:214-217`)

**Issue:** iOS seeds a new topic with the account default only when it is in `allowed_currencies`, otherwise the first allowed one. Android's `resolveCurrency` returns the account default unconditionally, and `allowedOf` then appends it to the list. If the backend ever returns a default that is not in `allowed_currencies`, Android would offer and send a currency the server rejects.

**Fix:** In `resolveCurrency`, for a non-edit topic with no pick, use `stored.takeIf { it in listed } ?: listed.first()`, matching iOS `newTopicDefault`.

### IN-02: Back to Home from Booking Confirmed is a silent no-op outside the expert shell

**File:** `ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift:152`

**Issue:** `onBackToHome: { returnToDashboard?() }` does nothing when the environment value is `nil`. That is by design for previews. But `confirmAccept` has already succeeded at that point, so a tap that does nothing on the primary button leaves only the system back control. Both runtime entry points sit inside `HomeExpertView`, so this is latent today.

**Fix:** Fall back to `dismiss()` when `returnToDashboard` is `nil`.

### IN-03: Stale planning reference and duplicated duration math

**File:** `ClickMe2026/Utils/ExpertBookingConfirmationContent.swift:82,66-69`; `RequestDecisionViewModel.swift:291-294`

**Issue:** The doc comment says "Plan 06-05 calls this on accept success", a planning reference that will rot. `durationText` (`"\(minutes) min"`) duplicates `RequestDecisionViewModel.formatDuration` (`"\(minutes)m"`), which has the same `Int(end - start)/60` truncation. `RequestDecisionViewModel.formatDate` and `formatTime` also create new `DateFormatter`s, which `CLAUDE.md` says to avoid in favor of `DateUtil`. The same screen's Confirmed state already uses `DateUtil`.

**Fix:** Drop the plan reference. Have `formatDuration` call a shared helper, and move `formatDate` and `formatTime` to `DateUtil`.

### IN-04: Misindented argument in `ExpertProfileHomeScreen`

**File:** `ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift:299`

**Issue:** `isOnline: false,` is at the wrong indent level after the comment was inserted. It will trip SwiftFormat and reads as if it belongs to a different call.

**Fix:** Indent it to match the surrounding arguments.

### IN-05: Capped `TextEditor` bindings should be checked on a device

**File:** `ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionAcceptSheet.swift:70-73`, `ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift:143-146`

**Issue:** Both editors cap the text inside a custom `Binding` setter. When the text is already at the cap and the user types one more character, the setter writes back a value equal to the stored one. For the accept sheet the storage is `@State`, which does not re-render on an equal write, so the editor may show the extra character until the next change. The view model tests cover `cappedAcceptMessage` and `updateNote`, but not what the editor displays. This is not confirmed. SwiftUI's behavior here has varied between releases.

**Fix:** Add the "type past the cap" case (including pasting an emoji across the boundary) to the Phase 6 device UAT checklist. If it reproduces, cap in `.onChange(of:)` instead of the setter.

---

_Reviewed: 2026-11-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
