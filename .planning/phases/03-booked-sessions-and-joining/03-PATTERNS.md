# Phase 3: Booked Sessions and Joining - Pattern Map

**Mapped:** 2026-11-10
**Files analyzed:** 33 (14 new, 19 modified)
**Analogs found:** 31 / 33

All paths are relative to `/Users/LeonChen/Documents/ClickMe2026/ClickMe2026/` unless stated. Folder names contain spaces; quote them. All analogs are git-tracked source. Line numbers were read on 2026-11-10 and will shift as plans edit the files.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift` (new) | service/view-model helper | request-response | `BookingSummaryViewModel.swift` L237-335 (source to extract) | exact |
| shared reschedule card subview (new, same folder `Subviews/`) | component | request-response | `BookingSummaryView.swift` `rescheduleCard` L~330-380 | exact |
| `Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift` (mod) | view model | CRUD | itself | exact |
| `Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift` (mod) | view | request-response | itself | exact |
| `.../Booking Summary/Subviews/BookingSummaryExpertCard.swift` (mod, ID line) | component | transform | `UpcomingBookingStatusRow.swift` L34-36 | role-match |
| decline note card (new, `Subviews/`) | component | transform | `Subviews/BookingSummaryExpertCard.swift` (glass card + `BookingSummarySectionHeader`) | role-match |
| `Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift` (mod) | view model | CRUD | itself + `BookingSummaryViewModel.forceLoad` | exact |
| `.../Upcoming Booking Details/UpcomingBookingView.swift` (mod) | view | request-response | itself | exact |
| `.../Upcoming Booking Details/Subviews/UpcomingBookingStatusRow.swift` (mod) | component | transform | itself | exact |
| `.../Upcoming Booking Details/Subviews/UpcomingBookingJoinCard.swift` (mod, Open in provider) | component | event-driven | itself (`inAppJoinButton`) | exact |
| `.../Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift` (mod, hide Cancel) | component | transform | itself | exact |
| `Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift` (mod) | view model | request-response | itself | exact |
| `.../Cancellation/Subviews/CancellationBookingSummary.swift` (mod) | component | transform | itself L64-90 | exact |
| `.../Cancellation/Subviews/CancellationCommentField.swift` (mod, 450 cap + counter) | component | event-driven | itself | exact |
| `Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift` (mod) | view model | request-response | itself | exact |
| `Views/Screens/Client Mode/My Bookings/MyBookingsView.swift` (mod) | view | request-response | itself | exact |
| Past empty state (new, `My Bookings/Subviews/`) | component | transform | `My Bookings/Subviews/UpcomingEmptyState.swift` | exact |
| `Views/Screens/Client Mode/Home/HomeClientView.swift` (mod) | shell | event-driven | itself | exact |
| `Views/Screens/Expert Mode/Home/HomeExpertView.swift` (mod) | shell | event-driven | itself | exact |
| `Views/Extensions/HomeNavigationPath.swift` (mod, new `HomeRoute` cases) | route | event-driven | itself | exact |
| `Managers/ToastCenter.swift` (new) | provider/manager | pub-sub | `Managers/UserManager.swift` (`@MainActor @Observable`, `static let shared`) | role-match |
| `Views/Components/Toast/ToastHost.swift` (new) | component (ViewModifier) | event-driven | `CallOverlayHost` in `Views/Screens/Call/Calling/CallOverlayHost.swift`; chip look from `SkypeLinkActions.swift` L36 | role-match |
| `Utils/CancelRefundPreview.swift` (new) | utility | transform | `Utils/JoinWindow.swift` (pure enum, injected `now`) | role-match |
| `Utils/CancelReasonComposer.swift` (new) | utility | transform | `Utils/JoinWindow.swift`; code in RESEARCH "Cancel reason composer" | role-match |
| `Utils/CancelToastMessage.swift`, `BookingStatusPill.swift`, `DeclineNote.swift`, `BookingShortID.swift` (new) | utility | transform | `Utils/JoinWindow.swift`, `Utils/Money.swift` | role-match |
| `Network/ClickMeAPI+Booking.swift` (mod, `cancelClientBooking` typed decode) | service | request-response | itself L220-226 and `declineClientReschedule` L205-218 | exact |
| `Network/ClickMeAPI+Availability.swift` (mod, `excludeBookingId`) | service | request-response | itself `getExpertAvailability` | exact |
| `Model/Responses/ClientBookingDetail.swift` (mod, decline fields, `paymentActionRequired`) | model | transform | itself | exact |
| `Model/Responses/CancelBookingData.swift` (new) | model | transform | `Model/Responses/PaymentIntentResponse.swift`, `SuccessDataResponse` | role-match |
| `Views/Screens/Call/Calling/MeetingCallView.swift` + `MeetingCallViewModel.swift` (mod, status text) | view / view model | event-driven | itself | exact |
| `.../Call/Calling/Subviews/SkypeSessionHero.swift` (mod, timer) | component | event-driven | `Subviews/MeetingCallInfo.swift` (timer block) | exact |
| `Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift` (mod, Join) | view | event-driven | `Expert Mode/Expert Dashboard/ExpertDashboardView.swift` L485-515 | exact |
| `Views/Screens/Expert Mode/Cancellation/Subviews/ExpertCancellationClientBox.swift`, `ExpertCancellationView.swift`, `ExpertCancellationViewModel.swift` (mod) | component / view | transform | themselves | exact |
| `Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift` + `ExpertDashboardView.swift` (mod, `onReschedule`) | view | event-driven | `handleCardTap` L~318 in `UpcomingBookingsView.swift` | exact |
| `ClickMe2026Tests/**` new suites | test | request-response / transform | `Booking/ClientBookingStatusFallbackTests.swift`, `Utils/JoinWindowTests.swift` | exact |
| `ClickMe_Android/.../clientmode/bookingsummary/subviews/BookingSummaryCard.kt` (mod) | component (Android) | transform | itself, L113-145 | exact |

## Pattern Assignments

### `RescheduleResponder.swift` (new, extract from `BookingSummaryViewModel`)

**Analog:** `Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift` L237-335.

Move these members into the responder: `isSubmittingReschedule`, `rescheduleError` (L70-71), `requiresAcceptRescheduleDisclosure`, `acceptRescheduleChargesSoon`, `acceptReschedule()`, `declineReschedule(reason:)`, private `errorCode(for:)`, and `acceptRescheduleDialogMessage` (private computed on `BookingSummaryView` L85-96). Replace `forceLoad(bookingId:)` calls with an injected `refetch: () async -> Void` closure.

**Disclosure inputs** (L237-253):
```swift
var requiresAcceptRescheduleDisclosure: Bool {
    guard let expiresAt = authorizationExpiresAt, let proposal = reschedule else { return false }
    return proposal.proposedEnd > expiresAt
}
var acceptRescheduleChargesSoon: Bool {
    guard let proposal = reschedule else { return false }
    return proposal.proposedStart.timeIntervalSinceNow < 48 * 3600
}
```

**Accept with PAYMENT_METHOD_REQUIRED recovery** (L264-308): guard on `isSubmittingReschedule`, `defer` reset, first `acceptClientReschedule(id:)`, branch on `Self.errorCode(for: error) == .paymentMethodRequired` (never message text), then `api.getPaymentMethods().data.paymentMethods`, pick `isDefault` or first, retry with `stripePaymentMethodId:`. Second `.paymentMethodRequired` is terminal.

**Error-code extraction** (L310-316):
```swift
private static func errorCode(for error: Error) -> ErrorCode? {
    guard case let NetworkError.httpError(_, data) = error,
          let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
    else { return nil }
    return response.code
}
```

**Decline** (L318-332): trim the reason, send `nil` when empty; extend with UTF-16 cap at 500 (see `CancelReasonComposer.prefixUTF16`).

**Copy edits owned by the responder** (UI-SPEC): "Settings > Payment" becomes "Profile > Payment" at L291 and L303; add a `.rescheduleOutsideAuthWindow` branch on accept. `ErrorCode` currently lacks `SESSION_ALREADY_ENDED`; unknown codes decode to nil and show `userMessage`, which is wanted.

**Host-view wiring** (copy to both screens, `BookingSummaryView.swift` L100-150): `.confirmationDialog("Accept the proposed reschedule?")`, `.alert("Decline reschedule")` with `TextField("Optional reason", ...)`, `.alert("Couldn't update booking", ...)` bound through `Binding(get:set:)` to `rescheduleError`. Change button titles per UI-SPEC (`Accept New Time`/`Keep Current Time`, `Decline New Time`, dismiss `Back to Booking`).

---

### `UpcomingBookingViewModel.swift` (mod: BOOK-06, 09, 13, CALL-03, CALL-08)

**Analog:** itself (228 lines) plus `BookingSummaryViewModel.apply(detail:)` L215-227 for fields to store.

**Fields to add** (pattern from L18-37): `startTime`, `endTime`, `expertId`, raw `statusRaw: String`, `canJoin: Bool?`, `reschedule`, `authorizationExpiresAt`, `paymentActionRequired`. Set them in `init` (L56-72), `previewSeed` (L88-118, previews compile in Release, no `#if DEBUG`) and `apply(_:)` (L151-168).

**Existing ID formatting is inlined twice** (L58 and L152): `"#" + bookingId.uuidString.prefix(8).uppercased()`. Replace both with `BookingShortID`.

**Status decode to keep** (L166-167): `bookingStatus = BookingStatus(rawValue: data.status) ?? .unknown`. Also keep `data.status` raw for the pill humanizer.

**Silent refresh (Pitfall 1).** `forceLoad` at L130-141 sets `state = .loading` first, which tears down the loaded screen. Add a `refresh()` that reuses the `ReloadGeneration` token pattern but only touches `state` on failure when nothing is loaded:
```swift
private func forceLoad() async {
    let token = reloads.begin()
    state = .loading                       // refresh() must skip this line once .loaded
    do {
        let response = try await api.getClientBookingDetail(id: bookingId)
        guard reloads.isCurrent(token) else { return }
        apply(response.data); state = .loaded
    } catch {
        guard reloads.isCurrent(token) else { return }
        state = .failed(Self.message(for: error))
    }
}
```
Route the `booking.update` subscription (L76-80) and post-accept/decline through `refresh()`.

---

### `UpcomingBookingView.swift` and join/secondary subviews (mod)

**Analog:** itself.

**Callbacks with defaults** (L14-47): keep `onJoinCall`, `onReschedule`, `onCancel` as override seams, but make Join self-contained in the view (call `CallCenter.shared.startCall` when no override), because `HomeClientView.swift` L302, `HomeExpertView.swift` L246 and `ClientTransactionsView` construct it with `{}` defaults (Pitfall 2).

**Where the response card goes** (`loadedContent` L84-): insert directly after `UpcomingBookingStatusRow(...)` (L88) and before `UpcomingBookingExpertCard`. Pass the real status into the row.

**60 s join gate** (copy from `Expert Mode/Expert Dashboard/ExpertDashboardView.swift` L485-512):
```swift
if JoinWindow.showsJoinButton(status: session.status.code) {
    TimelineView(.periodic(from: .now, by: 60)) { context in
        let inWindow = JoinWindow.isOpen(status: ..., start: ..., end: ..., now: context.date, serverCanJoin: session.actions.canJoin)
        Button {
            CallCenter.shared.startCall(bookingId: ..., peerId: ..., peerName: ..., peerImageURL: ...,
                topic: ..., scheduledStart: ..., scheduledEnd: ..., meetingType: ..., isRejoin: status == .completed)
        } label: { ... }
```
Hint text for disabled: `Available closer to the session start` (existing 02-14 accessibility hint; find with `grep -rn "Available closer" ClickMe2026`).

**Join button look** (`Subviews/UpcomingBookingJoinCard.swift` L36-56, `inAppJoinButton`): 52 pt, `UpcomingBookingBrand.brandGreen` fill with glow shadow, `PressScaleButtonStyle()`. The new `Open in {provider}` button copies this but with a 16 pt radius and `.callout` semibold (UI-SPEC). The `skypeZoom` case (L24-27) currently shows `linkRow` only; add the button above `linkRow` inside the same `VStack`. Copy button (L90-103) needs `.accessibilityLabel`.

**Provider label:** `ExternalMeetingProvider.detect(from:)`, `.displayName`, `.iconSystemName` in `Views/Screens/Call/Calling/ExternalMeetingProvider.swift`. `.unknown` returns `"Meeting"`, so build the label as `provider == .unknown ? "Open Meeting" : "Open in \(displayName)"`.

**Status row** (`Subviews/UpcomingBookingStatusRow.swift` L11-41): hard-coded `Text("Confirmed")` and `brandGreen` at L19-23. Change the init to take a `BookingStatusPill` (text + tone) and keep the capsule, 8 pt dot and padding.

**Hide Cancel** (`Subviews/UpcomingBookingSecondaryActions.swift`, 62 lines): add `showsCancel: Bool` fed from a pure `canShowCancel(status:end:now:)` evaluated inside a 60 s `TimelineView`; when hidden, Reschedule fills the row.

---

### `ClientCancellationViewModel.swift`, `CancellationBookingSummary.swift`, comment field (mod: BOOK-07, 08, 12)

**Analog:** itself.

**Preview that must be replaced** (VM L108-135): `refundAmount(from:)` returns the full list price for `held`/`captured`. Replace `CancellationBooking.refundAmount: String?` with refund facts (`topic`, `paymentStatus`, `authorizationExpiresAt`, `start`) and compute the case via `CancelRefundPreview`. Update `map`, `placeholderBooking` (~L180), `sampleBooking` and `#Preview`s in the same task (Pitfall 12).

**Dropped comment bug** (VM L141-162): `cancelClientBooking(id:reason: selectedReason)` ignores `comment`; the doc comment even says so. Send `CancelReasonComposer.reason(label: selectedReason, comment: comment)`.

**Confirm flow to extend** (L141-162):
```swift
cancelError = nil
withAnimation { isConfirming = true }
defer { isConfirming = false }
do { _ = try await api.cancelClientBooking(id: bookingId, reason: selectedReason) }
catch { cancelError = error.userMessage; return }
onConfirm(selectedReason, comment)
```
Before the request, recompute the case at `Date()`; if it differs from the displayed case (C to D), set a published `previewChangedNotice` and return without submitting. After success read `response.data.refundAmount` / `.currency` and call `ToastCenter.shared.show(CancelToastMessage...)` before `onConfirm`.

**Summary money row to replace** (`CancellationBookingSummary.swift` L80-92): a `creditcard` `HStack` with `Text(refundAmount)` in `brandGreen` plus `" will be refunded according to our policy."`. Per UI-SPEC the amount is `onSurface` semibold, never green. Case D uses an amber block (orange 10% fill / 45% stroke / 16 pt radius).

---

### `ClickMeAPI+Booking.swift`, `ClickMeAPI+Availability.swift`, models (mod / new)

**Cancel typed decode** (analog `ClickMeAPI+Booking.swift` L220-226; return-type pattern from `getExpertBookingDetails` which returns `SuccessDataResponse<...>`):
```swift
func cancelClientBooking(id: UUID, reason: String) async throws -> SuccessDataResponse<CancelBookingData> {
    try await service.httpRequest(url: url(.cancelClientBooking, id: id), method: .post, parameters: ["reason": reason])
}
```
`CancelBookingData: Decodable { let refundAmount: Double; let currency: String }`. The service uses `.convertFromSnakeCase`, so no `CodingKeys`. `refund_amount` is major units: use `Money.format(major:currency:)` (returns optional).

**Availability** (analog `ClickMeAPI+Availability.swift` L30-36): currently `parameters: ["month": month]`. Add `excludeBookingId: UUID? = nil` and put `"exclude_booking_id"` in the dictionary only when non-nil. `RescheduleViewModel.fetchAvailability` (L216-222) passes `bookingId`; `MakeABooking` callers stay default.

**Reschedule copy edits** (`RescheduleViewModel.swift` L348, L384, L386): replace "Settings > Payment" with "Profile > Payment" and L384 with the UI-SPEC `RESCHEDULE_OUTSIDE_AUTH_WINDOW` line.

---

### `MyBookingsView.swift` (mod: BOOK-11, 12, 16, CALL-03)

**Analog:** itself.

**Destinations** (L100-160). Keep Booking and the reschedule return currently call `popToRoot()` (L146-154; `popToRoot` at L182 is `navPath.reset()`). Change `onKeepBooking` and `onRescheduled` to a one-level pop (`navPath.removeLast()`), keep `popToRoot()` only for `onConfirmCancellation`. Pass `onJoinCall` into `UpcomingBookingView` (L108-112) using the `startCall` block already at L340-351:
```swift
CallCenter.shared.startCall(
    bookingId: booking.id, peerId: booking.expertId, peerName: booking.expertName,
    peerImageURL: booking.imageURL, topic: booking.topic,
    scheduledStart: booking.startTime, scheduledEnd: booking.endTime,
    meetingType: booking.meetingType, isRejoin: booking.status == .completed)
```
**Past empty state** (L284-): `if viewModel.selectedTab == 0 && viewModel.upcomingBookings.isEmpty { UpcomingEmptyState(...) }`. Add a `selectedTab == 1 && pastBookings.isEmpty` branch inside `loadedContent` only, so loading and error states are untouched. New `PastEmptyState` copies `UpcomingEmptyState.swift` L8-35 (illustration `GlowingCalendarIllustration(glowPulse:)`, `VStack(spacing: 28)`, `MyBookingsBrand.*`), with `.title2` semibold / `.callout` regular and no button.

---

### `HomeClientView.swift`, `HomeExpertView.swift`, `HomeNavigationPath.swift` (mod)

**Analog:** itself.

**Route registration** (`HomeClientView.swift` L223-233, 287-): `homeStack(_ nav:, path:, root:)` receives `nav` but `homeRouteDestination(route)` does not. Change to `homeRouteDestination(route, nav:)` in both shells. New client action routes (`cancelBooking(bookingId:)`, `rescheduleBooking(bookingId:)`, `writeReview(bookingId:)`) go in `HomeNavigationPath.swift` beside `upcomingBooking` (L90) and are `EmptyView()` in the expert shell, as expert-only cases already are in the client shell:
```swift
case .expertBookingSummary:
    // Expert-only destination. Not reachable from the client shell,
    // but the case must be exhaustive.
    EmptyView()
```
**Wrong-tab pop bug** (`HomeExpertView.swift` L251-254): `.expertReschedule` uses `bookingsPath.pop()` regardless of origin tab; use the `nav` passed in.

**Toast host:** add `.modifier(ToastHost())` next to `.modifier(CallOverlayHost {...})` at `HomeClientView.swift` L104.

---

### `ExpertBookingSummaryView.swift` (mod: CALL-10)

**Analog:** `Expert Mode/Expert Dashboard/ExpertDashboardView.swift` L485-515 (exact Join gating plus `startCall` for an `ExpertBookingDetail`-shaped payload), and the existing `messageClientButton` at `ExpertBookingSummaryView.swift` ~L663-690.

Insert Join directly above `messageClientButton` (render site ~L190). Use `detail.actions.canJoin`, `detail.client.id`, `detail.client.name ?? "Client"`, `detail.client.avatarUrl ?? ""`, `detail.session.startTime/endTime/meetingType`. Visibility rule is a pure function (Pitfall 3): `confirmed | in_progress | pending_reschedule` or `JoinWindow.isOpen`; never use `showsJoinButton` alone. When Join is rendered, `Message Client` (L675) switches to the outlined style (`Brand.primary` stroke 1.5 pt at 50%, accent label, 50 pt) to keep one accent fill. Attach the `Couldn't join call` alert here too (pattern at `MyBookingsView.swift` L234-241, bound to `callCenter.joinError`).

---

### Expert cancel copy (mod: EXP-11)

**Analog:** `Expert Mode/Cancellation/Subviews/ExpertCancellationClientBox.swift` L90-100 builds `Text("A ") + Text(refundType) + Text(" will be processed ... according to our policy.")`. Remove `refundType: String` here, in `ExpertCancellationView.swift` (L61, 72, 93, 154, 208) and `ExpertCancellationViewModel.swift` (L20, 49, 60). Replace with an `ExpertCancelRefundLine` value (free / hold / full refund / unformattable). Keep `creditcard` icon HStack structure; use `lock.fill` for the hold line; amount semibold `onSurface`, not `brandGreen`. Input data: `session.consultationFee` (major) via `Money.format(major:currency:)` and `authorizationExpiresAt`.

---

### Expert reschedule wiring (mod: EXP-13)

**Analog:** `Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift` L118-130 (`onReschedule: ... = { _ in }`), `handleCardTap` (~L318-322):
```swift
guard let homeNavigationPath else { return }
homeNavigationPath.push(HomeRoute.expertBookingSummary(bookingId: session.bookingId))
```
Add `handleReschedule(for:)` pushing `HomeRoute.expertReschedule(bookingId: session.bookingId)` the same way and pass it where `onReschedule: viewModel.onReschedule` is used (L243). Mirror the Dashboard embed. `ExpertBookingSummaryView.swift` L197-204 already pushes this route.

---

### Skype/Zoom screen (mod: CALL-06, 07)

**Analog:** `Call/Calling/MeetingCallView.swift` L105-116 passes the full timer set to the in-app layout:
```swift
timerString: viewModel.timerString,
statusLabel: viewModel.callStatus.label,
remainingLabel: viewModel.remainingLabel,
isNearOrPastEnd: viewModel.isInFinalStretch || viewModel.isPastScheduledEnd
```
Reuse the same VM properties (`MeetingCallViewModel.swift` L317, 340, 347, 354, 373). Extend `SkypeSessionHero` (L8-48: `peerName`, `peerAvatarURL`, `topic`, `scheduledRangeLabel`) with `timerString`, `remainingLabel`, `isNearOrPastEnd`, and render the timer as `MeetingCallInfo` does (`Subviews/MeetingCallInfo.swift`; read it for the exact `.title2` monospaced + orange chip code). Replace `skypeStatusText` (L238-246) with the UI-SPEC strings, and move it to the VM so it can be unit tested:
```swift
return "Meeting in progress. Scheduled to finish at \(endLabel). Tap End Session when you're done."
return "Meeting in progress. Tap End Session when you're done."
```

---

### `ToastCenter.swift` and `ToastHost.swift` (new)

**Analog (manager):** `Managers/UserManager.swift` (`@MainActor @Observable final class`, `static let shared`). **Analog (chip look):** `Call/Calling/Subviews/SkypeLinkActions.swift` L19-45 (private "Link copied" chip: capsule, `surfaceContainerHigh`, `primary` 60% stroke). **Analog (overlay host):** `Call/Calling/CallOverlayHost.swift`. Behavior (4 s cancellable `Task`, replace-restarts, tap to dismiss, VoiceOver announcement, Reduce Motion fade only) is in RESEARCH Pattern 4 and UI-SPEC section 10. Success paths call `show` before the pop.

---

### Pure helpers under `Utils/` (new)

**Analog:** `Utils/JoinWindow.swift` L1-83 (caseless `enum`, static functions, `now:` injected, doc comments with `- Parameters:`) and `Utils/Money.swift`. Use `Money.format(minorUnits:currency:)` for `topic.price.amount`, `Money.format(major:currency:) -> String?` for cancel `refund_amount` and expert `consultationFee`. Code for `CancelRefundPreview.refundCase` and `CancelReasonComposer` is in RESEARCH (Pattern 3, Code Examples); copy it, the strict `> 24 * 3600` boundary mirrors `refund.js`.

---

### Tests (new)

**Analog:** `ClickMe2026Tests/Booking/ClientBookingStatusFallbackTests.swift` (VM-level with `MockURLProtocol`, detail JSON builder at L28-55; make it a shared `Support/ClientBookingFixtures.swift`) and `ClickMe2026Tests/Utils/JoinWindowTests.swift` (pure helper suite, `@MainActor @Suite("...")`, Swift Testing `#expect`). Suites touching `MockURLProtocol` are `.serialized` and run one suite per `xcodebuild` call. Bring a uniquely named body-reading helper (not `httpBodyOrStreamData`, which is private in `LoginTests.swift`).

---

### Android `BookingSummaryCard.kt` (BOOK-20, separate commit in `../ClickMe_Android`)

**File:** `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/bookingsummary/subviews/BookingSummaryCard.kt`. The topic/date/price `Column` (L113-145) ends with the price `Row`. Add the ID `Text` after that `Row`:
```kotlin
Text(
    text = stringResource(R.string.upcoming_booking_id, shortBookingId(details.bookingId)),
    style = MaterialTheme.typography.bodySmall,
    color = MaterialTheme.extras.onSurfaceMuted,
)
```
`shortBookingId` is in `upcomingbooking/UpcomingBookingUiState.kt:22`; `upcoming_booking_id` is `ID: %1$s` in `res/values/strings_upcoming_booking.xml:6`. Confirm `details.bookingId` exists in `BookingSummaryUiState.kt` and extend `BookingSummaryScreenTest`. (The snippet is illustrative; verify signatures when editing.)

## Shared Patterns

### Errors
**Source:** `Network/Error+UserMessage.swift`; `Model/Enums/ErrorCode.swift`.
Catch, assign `error.userMessage` to a `@Published` string, show an alert. Branch on `ErrorCode` via `NetworkError.httpError` plus `StandardErrorResponse` (see `errorCode(for:)` above). No `try?` on writes, no message matching, no private `errorMessage(for:)`.

### Stale-response protection
**Source:** `Utils/ReloadGeneration.swift`, used at `UpcomingBookingViewModel.swift` L130-141 and `BookingSummaryViewModel.swift` L180-210. `let token = reloads.begin()` then `guard reloads.isCurrent(token) else { return }` after every `await`.

### Join gating
**Source:** `Utils/JoinWindow.swift` L54-82 plus a 60 s `TimelineView` (`ExpertDashboardView.swift` L485-512). Pass `context.date`; never read `Date()` in a body.

### Money and status
`Money.format(...)` for all amounts; `BookingStatus(rawValue:) ?? .unknown` for statuses.

### Navigation
Per-tab `HomeNavigationPath` (`push/pop/reset`); read via `@Environment(\.homeNavigationPath)`; register every `HomeRoute` once through `homeStack` (CR-01).

### View model conventions
`@MainActor ObservableObject`, `@Published apiError`/`cancelError`, runtime init plus preview-seed init, previews compile in Release. Buttons use `PressScaleButtonStyle()`. Per-screen brand enums (`UpcomingBookingBrand`, `CancellationBrand`, ...) stay as they are; new files use `Brand.*`.

### Headers and MARKs
Every Swift file starts with the Xcode header (`//  Name.swift / ClickMe2026 / Created by ... / Copyright © 2026 Uptrend Investments Inc. All rights reserved.`) and uses `// MARK: -` dividers. New files under `ClickMe2026/` and `ClickMe2026Tests/` auto-register (file-system-synchronized groups); no pbxproj edit.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `Managers/ToastCenter.swift` / `Views/Components/Toast/ToastHost.swift` | manager / modifier | pub-sub | No shared toast exists; only the private "Link copied" chip. Use the manager and chip analogs above plus RESEARCH Pattern 4 |
| `Utils/CancelReasonComposer.swift` UTF-16 capping | utility | transform | No existing UTF-16-safe cap; use the RESEARCH code (mirrors Android `CancellationReason.kt` L22-44) |

## Cautions for the Planner

- Plans touching `UpcomingBookingView`/`UpcomingBookingViewModel` and `MyBookingsView` must be serialized (many requirements converge there).
- `ErrorCode` has no `SESSION_ALREADY_ENDED`; do not add string matching, the server message already reads well.
- `MockURLProtocol` suites need `.serialized` and one suite per `xcodebuild` call; exclude `LoginTests.swift`, `AuthSmokeTests.swift`, `SignupSmokeTests.swift` (command in RESEARCH Validation Architecture).
- RESEARCH Open Questions 1 (Cancel for `in_progress`) and 4 (comment visible to expert) need user input; implement `canShowCancel` as one pure function so the answer is a one-line change.

## Metadata

**Analog search scope:** `ClickMe2026/Views/Screens/{Client Mode,Expert Mode,Call}`, `Views/Extensions`, `Utils`, `Managers`, `Network`, `ClickMe2026Tests`, plus `ClickMe_Android/.../clientmode/bookingsummary`.
**Files scanned:** about 45 read in full or in part.
**Pattern extraction date:** 2026-11-10
