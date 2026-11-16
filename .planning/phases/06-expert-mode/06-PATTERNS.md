# Phase 6: Expert Mode - Pattern Map

**Mapped:** 2026-11-16
**Files analyzed:** 36 (new and modified, iOS plus Android)
**Analogs found:** 34 / 36 (the two Android currency-picker files have only a partial analog)

All paths below were checked with `git ls-files` (iOS and Android repos) and are tracked. iOS paths are relative to `/Users/LeonChen/Documents/ClickMe2026/ClickMe2026/` unless they start with `ClickMe2026Tests/`. Android paths are relative to `/Users/LeonChen/Documents/ClickMe_Android/`. `Views/Screens/Expert Mode/` is abbreviated `EM/`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `Utils/TopicPriceRules.swift` (new) | utility (pure) | transform | `Utils/UTF16Prefix.swift`, `Utils/Money.swift` | role-match |
| `Utils/AvailabilitySlotRules.swift` (new) | utility (pure) | transform | `Utils/UTF16Prefix.swift`, `Utils/HomeShellExit.swift` | role-match |
| `Utils/BookingNoteRules.swift` (new, or on the VM) | utility (pure) | transform | `Utils/CancelReasonComposer.swift` | exact |
| `Utils/ExpertBookingConfirmationContent.swift` (new) | utility (pure) | transform | `Utils/BookingShortID.swift` | role-match |
| `EM/Topics/Topic Editor/TopicEditorViewModel.swift` | view model | request-response | itself (`resolveInitialCurrency`, `isCurrencyLocked`) | exact |
| `EM/Topics/Topic Editor/TopicEditorView.swift` (L105 keyboard) | view | request-response | itself (`currencyPicker`, L419-450) | exact |
| `Model/Requests/ExpertTopicRequest.swift` | model | request-response | itself; no tri-state analog | partial |
| `EM/Topics/Subviews/TopicsSetupTopicCard.swift`, `Topics/TopicsSetupView.swift`, `TopicsSetupViewModel.swift` | view and VM | CRUD (delete) | `EM/Profile/ExpertProfileHomeScreen.swift` L77-92 (alert) | exact |
| `Network/ClickMeAPI+ExpertProfile.swift` (comment only L66-67) | service | CRUD | itself | exact |
| `EM/Availability/AvailabilitySettingsView.swift` (pins, `minutesToAMPM`) | view | request-response | `Views/Screens/Settings/Delete account/DeleteAccountView.swift` L71 | exact |
| `EM/Availability/Subviews/AvailabilityDayRow.swift` | view | event-driven | itself L105-121 | exact |
| `EM/Availability/Subviews/TimeRangePickerSheet.swift` | view | request-response | itself; draft-copy pattern in RESEARCH Pattern 4 | partial |
| `EM/Request decision/RequestDecisionView.swift`, `RequestDecisionViewModel.swift` | view and VM | request-response | itself (`confirmAccept` L178-200) | exact |
| `EM/Request decision/Subviews/RequestDecisionAcceptSheet.swift` | view | request-response | `Utils/CancelReasonComposer.swift` (cap) | role-match |
| `EM/Confirmed/BookingConfirmedView.swift` (+ `Subviews/`) | view | request-response | itself (preview-only today) | exact |
| `EM/Confirmed/Subviews/CalendarEventEditorSheet.swift` | view (UIKit wrapper) | event-driven | itself L44-60 | exact |
| `Views/Screens/Expert Mode/HomeExpertView.swift` (env action) | shell | event-driven | `Utils/HomeShellExit.swift` and the client shell | role-match |
| `EM/Incoming Requests/Subviews/IncomingRequestCard.swift` | view | transform | itself | exact |
| `EM/Profile/ExpertProfileHomeViewModel.swift`, `ExpertProfileHomeScreen.swift` | VM and view | request-response | itself | exact |
| `Views/Screens/Client Mode/Profile/Subviews/ClientProfileHomeUserCard.swift` | view | request-response | itself | exact |
| `EM/Booking Note/ExpertBookingNoteViewModel.swift`, `ExpertBookingNoteView.swift` | VM and view | CRUD | `Views/Screens/Signup Flow/Overview/SignupOverviewView.swift` L145-160 (back and gesture lock) | role-match |
| `EM/Booking Summary/ExpertBookingSummaryView.swift` | view | request-response | `Utils/BookingShortID.swift` and the client summary card | exact |
| `ClickMe2026Tests/Utils/*Tests.swift` (new, 8 suites) | test | unit | `ClickMe2026Tests/Utils/BookingShortIDTests.swift`, `Utils/HomeShellExitTests.swift` | exact |
| `ClickMe2026Tests/.../RequestDecisionAcceptTests`, `TopicsSetupDeleteConfirmTests`, `ExpertBookingNoteViewModelTests` (new) | test | request-response (stubbed) | `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift` | exact |
| `ClickMe2026Tests/Model/TopicCurrencyTests.swift` (extend) | test | unit | itself | exact |
| Android `.../topics/editor/subviews/TopicCurrencyPicker.kt` (new) | component | event-driven | `.../subviews/TopicPriceField.kt` (no SegmentedButton exists in the app) | partial |
| Android `TopicEditorViewModel.kt`, `TopicEditorUiState.kt`, `TopicEditorScreen.kt` | VM, state, screen | request-response | themselves | exact |
| Android `model/responses/MeData.kt` | model | request-response | itself (`PricingLimits`) | exact |
| Android `res/values/strings_expert_topics.xml` | config | n/a | itself | exact |
| Android tests (`TopicEditorViewModelTest.kt`, `TopicEditorSubviewsTest.kt`, `TopicPriceTest.kt`) | test | unit | themselves | exact |
| `06-DEVICE-UAT-CHECKLIST.md` (new) | doc | n/a | earlier phase UAT files under `.planning/phases/` | role-match |

## Pattern Assignments

### New pure helpers (`TopicPriceRules`, `AvailabilitySlotRules`, `BookingNoteRules`, `ExpertBookingConfirmationContent`)

**Analog:** `Utils/UTF16Prefix.swift` (nonisolated caseless enum, `///` doc with `- Parameters:`).

```swift
nonisolated enum UTF16Prefix {
    /// The longest whole-character prefix of `text` whose UTF-16 length is at most `limit`.
    /// - Parameters:
    ///   - text: The string to cap. Returned unchanged when it already fits.
    ///   - limit: Maximum length in UTF-16 code units.
    static func prefix(_ text: String, limit: Int) -> String {
        guard text.utf16.count > limit else { return text }
        ...
```

Copy: Xcode header block, `nonisolated enum`, `static` members only, doc comments that cite the decision id. For `TopicPriceRules` use `Money.fractionDigits(for:)` (`Utils/Money.swift`); the digit-split parser is in RESEARCH Pattern 1 (copy that code, it mirrors Android `TopicPrice.kt`). For `BookingNoteRules` copy the shape of `Utils/CancelReasonComposer.swift` (it wraps `UTF16Prefix.prefix(text, limit: commentLimit)` at L30 and L41) and call `UTF16Prefix.prefix(_, limit: 5000)` and, for the accept sheet message, `limit: 1000`.

Short-ID helper to reuse, not recreate (`Utils/BookingShortID.swift`):

```swift
static func label(_ id: UUID) -> String { "ID: " + short(id) }
```

---

### `Model/Requests/ExpertTopicRequest.swift` (model, EXP-04)

**Analog:** itself, L36-54. Current shape (synthesized `Encodable`, so `nil` drops the key):

```swift
struct UpdateExpertTopicRequest: Encodable {
    struct HourlyRate: Encodable { let amount: Int; let currency: String }
    let title: String?
    let description: String?
    let durationMins: Int?
    let hourlyRate: HourlyRate?
    let isFree: Bool?
    let iconSlug: String?
    let expertiseTagIds: [String]?
}
```

No in-repo tri-state encoder exists (`grep encodeNil` finds none), so use RESEARCH Pattern 2 (`NullableField<Value>` with `.omit/.set/.null` plus a hand-written `encode(to:)` using `encodeNil`). `NetworkService` applies `.convertToSnakeCase` to a custom `encode(to:)` too, so keep Swift camelCase `CodingKeys` raw strings. Test against `JSONEncoder` with `keyEncodingStrategy = .convertToSnakeCase`.

---

### `EM/Topics/Topic Editor/TopicEditorViewModel.swift` and `TopicEditorView.swift` (EXP-02, 03, 17 iOS)

**Analog:** themselves; the currency picker and lock already ship (commit `73e729e`). Preserve this block (`TopicEditorView.swift` L419-450):

```swift
Picker("Currency", selection: $viewModel.currency) {
    ForEach(viewModel.pickableCurrencies, id: \.self) { code in Text(code).tag(code) }
}
.pickerStyle(.segmented)
.disabled(viewModel.isCurrencyLocked)
```

Change only: `validate()` and `isRateBelowMinimum` (parse via `TopicPriceRules.parseMinor`, never `Int(...) * 100`), and the keyboard at about L105 to `.decimalPad` when `Money.fractionDigits(for: currency) > 0`. Keep the `trimmedRate == seededRate` branch first so an untouched save sends the stored minor amount (02-06 D-19). Do not add `onChange(of: currency)` that rewrites the text.

---

### `EM/Topics/Subviews/TopicsSetupTopicCard.swift` + `TopicsSetupView.swift` (EXP-01 delete confirm)

**Analog:** `EM/Profile/ExpertProfileHomeScreen.swift` L77-92 (centred `.alert`, with the reason written in the comment):

```swift
.alert(
    "Log out of ClickMe?",
    isPresented: $showLogoutConfirmation
) {
    Button("Log Out", role: .destructive) {
        guard CallCenter.shared.attempt("log out") else { return }
        viewModel.logOut()
    }
    Button("Cancel", role: .cancel) {}
}
```

Adapt to `.alert("Delete this topic?", isPresented: <binding on topicPendingDelete != nil>, presenting: topicPendingDelete) { topic in Button("Delete", role: .destructive) { ... deleteTopic } ; Button("Cancel", role: .cancel) {} } message: { Text("\u{201C}\(topic.title)\u{201D} will be removed and clients won't be able to book it.") }`. The card Menu item only sets `topicPendingDelete`; no request is sent before `Delete`. Failures keep using the existing parent alert on `TopicsSetupView`.

---

### `EM/Availability/AvailabilitySettingsView.swift` (nav-bar pins, `minutesToAMPM`)

**Analog:** `Views/Screens/Settings/Delete account/DeleteAccountView.swift` L71 and siblings (`ModeSwitchView.swift` L92, `FeedbackView.swift` L40). Add the three sibling modifiers on the screen body:

```swift
.toolbarBackground(Brand.surface, for: .navigationBar)
.toolbarBackground(.visible, for: .navigationBar)
.toolbarColorScheme(.dark, for: .navigationBar)
```

Same three pins go on `BookingConfirmedView`. Fix `minutesToAMPM` (L35-41) with `let h = (minutes / 60) % 24` so 1440 reads `12:00 AM`.

### `EM/Availability/Subviews/AvailabilityDayRow.swift` (Add hours, EXP-06)

**Analog:** itself L105-121 (current code to replace with `AvailabilitySlotRules.addHours`):

```swift
if let maxEnd = day.slots.map(\.end).max() {
    let newStart = min(maxEnd + 30, 23 * 60)
    let newEnd = min(newStart + 60, 24 * 60)
    day.slots.append(AvailabilityTimeSlot(start: newStart, end: newEnd))
} else {
    day.slots.append(AvailabilityTimeSlot(start: 9 * 60, end: 17 * 60))
}
```

Keep the `withAnimation(.easeInOut(duration: 0.2))` wrapper and the "anchor to latest end across all slots" comment. Add `.disabled(...)` plus `.opacity(0.45)` and an accessibility hint when `addHours` returns nil.

### `EM/Availability/Subviews/TimeRangePickerSheet.swift` (EXP-05, 07)

**Analog:** itself. Today it takes `@Binding var slot: AvailabilityTimeSlot` and `times = stride(from: 0, through: 24 * 60 - step, by: step)`; Cancel and Done both only call closures. Change to a value plus a commit closure (RESEARCH Pattern 4). Keep the existing parameter list for colours (`brandGreen`, `bg`, `onSurface`, `onSurfaceVar`, `onPrimary`) and the Done/Cancel capsule layout (50 pt). Update the two previews that pass `$slot` (RESEARCH Pitfall 12).

---

### `EM/Request decision/RequestDecisionViewModel.swift` (EXP-09, 12; U1)

**Analog:** itself. Current accept path (L178-200) to restructure:

```swift
func confirmAccept(message: String) async {
    guard let requestId else { return }
    guard !isSubmitting else { return }
    submitError = nil
    isSubmitting = true
    defer { isSubmitting = false }
    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
        _ = try await api.acceptBookingRequest(id: requestId, message: trimmed.isEmpty ? nil : trimmed)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { showAcceptSheet = false }
        withAnimation(.easeInOut(duration: 0.25).delay(0.15)) { isAccepted = true }
    } catch {
        submitError = error.userMessage
    }
}
```

Replace the `isAccepted` frame with a `confirmation` value set in the same transaction as the sheet close. Keep the `isSubmitting` double-tap guard. Replace `submitError: String?` with a failure value carrying `popsOnDismiss`, using `BookingErrorMapper.code(for:)` (`Utils/BookingErrorMapper.swift` L31-37):

```swift
static func code(for error: Error) -> ErrorCode? {
    guard case let NetworkError.httpError(_, data) = error,
          let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
    else { return nil }
    return response.code
}
```

Branch on `== .alreadyProcessed` (the case exists in `Model/Enums/ErrorCode.swift`); never match message text. Do not copy the existing `formatDate/formatTime` that build new formatters; use `DateUtil`.

### `EM/Confirmed/Subviews/CalendarEventEditorSheet.swift` (EXP-10)

**Analog:** itself L44-60. Replace only the content (title, notes, location):

```swift
event.title = "ClickMe · \(booking.expertName)"
event.startDate = calendarPayload.startDate
event.endDate = calendarPayload.endDate
event.notes = booking.meetingNote
if !booking.isVirtual { event.location = booking.meetingNote }
event.addAlarm(EKAlarm(relativeOffset: -15 * 60))
```

Title and notes come from `ExpertBookingConfirmationContent` (pure, testable without EventKit). Drop the location branch. Keep the alarm and the `Coordinator` dismiss handling.

### Back to Home / tab exit (EXP-09)

**Analog:** `Utils/HomeShellExit.swift` (generic over `HomeShellTab`; `HomeExpertTab` already conforms). Use `HomeShellExit.plan(.backToHome, selectedTab:)`. Test by extending `ClickMe2026Tests/Utils/HomeShellExitTests.swift`, which uses `@Test(arguments: HomeClientTab.allCases)`; add the same shape over the expert tab enum. Note RESEARCH Pitfall 5: do not use `HomeNavigationPath.replace(with:)` for Confirmed; host Confirmed inside `RequestDecisionView`.

---

### `EM/Booking Note/ExpertBookingNoteViewModel.swift` + `ExpertBookingNoteView.swift` (EXP-16)

**Analog (VM):** itself. Keep `load()` shape (404 means empty note) and `hasChanges`. Change `save()` to send the normalized text and set both `noteText` and `lastPersisted` to what was sent (RESEARCH Pitfall 7). Current line to fix:

```swift
let response = try await api.createBookingNote(id: bookingId, note: noteText)
lastPersisted = response.data.note ?? noteText
```

**Analog (view back button and gesture lock):** `Views/Screens/Signup Flow/Overview/SignupOverviewView.swift` L145-160 and `Client Mode/Request Sent/BookingRequestSentView.swift` L58-61:

```swift
.navigationBarBackButtonHidden(true)
.background(BookingRequestSentPopGestureLock())
```

Here the lock is unconditional, which is the spec's fallback (Plan B). For Plan A wrap it as `.background { if viewModel.hasChanges { BookingRequestSentPopGestureLock() } }`. The prompt uses `.alert` (same reasoning as the Log Out alert above). Cap in the `TextEditor` binding `set` via `UTF16Prefix.prefix`, as `Utils/CancelReasonComposer.swift` does for the 450-character comment.

### `EM/Request decision/Subviews/RequestDecisionAcceptSheet.swift` (U1 cap and counter)

**Analog:** `Utils/CancelReasonComposer.swift` for the UTF-16 cap, and `RescheduleResponder.swift` L166 (`UTF16Prefix.prefix(trimmed, limit: Self.declineReasonLimit)`). Cap in the binding, counter from 800.

### `EM/Booking Summary/ExpertBookingSummaryView.swift` (EXP-18)

Add `Text(BookingShortID.label(bookingId))` as the last child of the client header `VStack` (`.caption`, `Brand.onSurfaceVariant`, `.textSelection(.enabled)`). Spacing 5 changes to 4. The client summary card's matching line is the visual reference.

### Hub dot (EXP-15) and expired card (EXP-12)

No analog needed: edits in place (`ExpertProfileHomeViewModel.isOnline` removed; `ExpertProfileHomeScreen.swift` reads at about L196 and L297; add `showsOnlineDot: Bool = true` on `ClientProfileHomeUserCard`; `IncomingRequestCard.swift` removes the whole-card `.opacity(0.55)`).

---

### Android EXP-17 (`/Users/LeonChen/Documents/ClickMe_Android`)

**Analog:** `app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/topics/editor/subviews/TopicPriceField.kt` for file layout, test tag constants, KDoc style, and `Column` + `labelMedium` label + `Spacer(Modifier.height(Spacing.sm))`:

```kotlin
const val TOPIC_PRICE_TAG = "topic_editor_price"
...
Text(
    text = stringResource(R.string.topic_editor_price_label),
    style = MaterialTheme.typography.labelMedium,
    color = MaterialTheme.colorScheme.onSurfaceVariant,
)
Spacer(Modifier.height(Spacing.sm))
```

No `SegmentedButton` exists anywhere in `app/src` (grep empty), so `SingleChoiceSegmentedButtonRow` is new Material 3 usage; follow the plain M3 API, with a `testTag` per segment and `enabled` passed through.

**ViewModel analog:** `TopicEditorViewModel.kt`. `onMeChanged` (about L144-163) resets currency on create and keeps it on edit; it must stop overwriting a user-picked currency:

```kotlin
val currency =
    if (isEdit) s.currency else TopicPrice.resolveCurrency(null, defaultCurrencyOf(me))
```

Add `fun onCurrencyChange(code: String)` next to `onPriceChange` (L214-220), which re-reads `floorNow(currency)` and keeps `priceText` (D-03; `filterInput` re-run is a no-op for CAD and USD). Add `allowedCurrencies` and `isCurrencyLocked` to `TopicEditorUiState.kt` (it already has `currency` and `floorMinor`). Wire the picker into `TopicEditorScreen.kt` just above the `TopicPriceField(` call at about L329 (`decimalKeyboard = TopicPrice.fractionDigits(currency) > 0`).

**Model analog:** `model/responses/MeData.kt` `PricingLimits` (about L28-31) uses `@Json(name = "min_session_amount") val minSessionAmount: MinSessionAmount`. Add `@Json(name = "allowed_currencies") val allowedCurrencies: List<String>? = null` (nullable, additive).

**Strings:** `app/src/main/res/values/strings_expert_topics.xml` L58-61 (`topic_editor_price_*`); add `Currency` label, lock caption and USD notice with the exact strings from 06-UI-SPEC.

**Android tests:** `TopicEditorSubviewsTest.kt` (Robolectric + `createComposeRule`, `onNodeWithTag`, `assertIsNotEnabled`) for the picker; `TopicEditorViewModelTest.kt` and `TopicPriceTest.kt` for the VM and rules.

---

### Test patterns (iOS)

**Pure helper suites:** `ClickMe2026Tests/Utils/BookingShortIDTests.swift`:

```swift
import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Booking short ID")
struct BookingShortIDTests {
    @Test("short is '#' plus the first 8 characters of the id, upper-cased")
    func shortForm() { #expect(BookingShortID.short(id) == "#7F3C9A2B") }
}
```

Header comment states the requirement id. Use `arguments:` parameterised tests as in `HomeShellExitTests.swift`.

**Stubbed HTTP suites (`RequestDecisionAcceptTests`, `TopicsSetupDeleteConfirmTests`, `ExpertBookingNoteViewModelTests`):** `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift`:

```swift
@Suite("Client cancellation view model", .serialized)
@MainActor
struct ...
    nonisolated private static func isCancel(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/cancel") == true
    }
    private func makeAPI(...) -> ClickMeAPI {
        APITestFactory.make { request in
            if Self.isCancel(request) { return Fixtures.response(for: request, status: cancelStatus, body: cancelBody) }
            return Fixtures.response(for: request, body: detail)
        }
    }
```

Count requests with `MockURLProtocol.recordedRequests.filter(...)` (for "zero DELETEs before confirm"). Always `.serialized` for any `MockURLProtocol` suite. Support files: `ClickMe2026Tests/Support/APITestFactory.swift`, `MockURLProtocol.swift`, `URLRequest+Body.swift` (read the PATCH body for the `null` assertions), `ClientBookingFixtures.swift`.

**Singleton-state suites:** `ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift` (`.serialized`, `init()` resets state, `defer` cleanup). Not needed for the pure helpers; only copy if a test touches `UserManager.shared`. `ClickMe2026Tests/Signup/SelectionOrderTests.swift` is a reference for small pure-value suites (not read in detail here).

**Extend:** `ClickMe2026Tests/Model/TopicCurrencyTests.swift` (uses `TopicEditorViewModel.resolveInitialCurrency(topic:defaultCurrency:)` and `isCurrencyLocked(topic:)`), `HomeShellExitTests.swift`, `ClientProfileHistoryEarningsTests.swift` (must stay green for EXP-14).

## Shared Patterns

### Server error code branching
**Source:** `Utils/BookingErrorMapper.swift` L31-37; `Network/Error+UserMessage.swift`
**Apply to:** `RequestDecisionViewModel` (accept and decline 409), topic save (`TOPIC_CURRENCY_LOCKED`, `PRICE_BELOW_MINIMUM`), delete.
Branch on `BookingErrorMapper.code(for: error)`, display `error.userMessage`. Never write a private `errorMessage(for:)`.

### Centred alert for confirmations launched from a Menu or custom control
**Source:** `EM/Profile/ExpertProfileHomeScreen.swift` L77-92
**Apply to:** delete topic, discard note changes, 409 and submit-failure alerts.

### Dark nav-bar pins
**Source:** `Views/Screens/Settings/Delete account/DeleteAccountView.swift` L71 (with `.toolbarBackground` pair beside it)
**Apply to:** `AvailabilitySettingsView`, `BookingConfirmedView`. Verify, do not duplicate, on Topic Editor, Booking Note, Request Decision.

### UTF-16 caps
**Source:** `Utils/UTF16Prefix.swift`, used at `Utils/CancelReasonComposer.swift` L30, L41
**Apply to:** accept message (1000), booking note (5000).

### Money
**Source:** `Utils/Money.swift` (`fractionDigits(for:)`, `format(minorUnits:currency:)`, `format(major:currency:)`)
**Apply to:** `TopicPriceRules`, minimum-price hint and below-floor message, Client Profile (verify only).

### Dates
**Source:** `Utils/DateUtil.swift` (`string(from:format:)`, `shortTime(_:)`)
**Apply to:** Confirmed body sentence and card. No new `DateFormatter`.

### Header and style
Every new Swift file starts with the Xcode header block (see any file above), 4-space indent, `// MARK: -` sections, `///` docs, `@MainActor ObservableObject` view models with `@Published` state.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Tri-state `NullableField` encoder in `ExpertTopicRequest.swift` | model | request-response | No custom `encode(to:)` with `encodeNil` exists in `Model/Requests/`; use RESEARCH Pattern 2 |
| Android `SingleChoiceSegmentedButtonRow` picker | component | event-driven | No `SegmentedButton` anywhere in `app/src`; use the Material 3 API with `TopicPriceField.kt` as the structural analog |
| Conditional pop-gesture lock added after appear | view | event-driven | Only unconditional uses exist (`BookingRequestSentView`, `SignupOverviewView`); behaviour of a late-added lock is unproven (RESEARCH Pitfall 6, device check D4) |

## Metadata

**Analog search scope:** `ClickMe2026/Utils`, `ClickMe2026/Views/Screens/Expert Mode`, `Settings`, `Signup Flow`, `Client Mode/Request Sent`, `ClickMe2026/Model/Requests`, `ClickMe2026Tests/{Auth,Booking,Model,Signup,Support,Utils}`, Android `screens/expertmode/topics/editor` and its tests.
**Files scanned:** about 45
**Pattern extraction date:** 2026-11-16
**Caveats:** `SelectionOrderTests.swift` and the client Booking Summary card were identified by path but not read; `HomeExpertView.swift` path was not re-verified (RESEARCH names it as the only plan-D shell edit). Line numbers for the Topic Editor and Incoming Request card come from RESEARCH and the CONTEXT, not re-read.
