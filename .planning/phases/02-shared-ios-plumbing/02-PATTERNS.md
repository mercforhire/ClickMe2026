# Phase 2: Shared iOS Plumbing - Pattern Map

**Mapped:** 2026-11-09
**Files analyzed:** 36 (14 new source, 6 new test suites grouped as 11 test files, 11 modified source groups counted individually below)
**Analogs found:** 33 / 36 (all analog paths verified git-tracked)

Paths are relative to `/Users/LeonChen/Documents/ClickMe2026/`. Source under `ClickMe2026/`, tests under `ClickMe2026Tests/`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Utils/CallOvertimePolicy.swift` (new) | utility | transform | `Utils/Utils.swift` (namespace enum) + `MeetingCallViewModel.enforceMaxOvertimeCutoff` (logic source) | role-match |
| `Utils/JoinWindow.swift` (new) | utility | transform | `Model/UIModels/UpcomingBooking.swift:62-67` (logic being replaced) | exact (logic) |
| `Utils/Money.swift` (new) | utility | transform | `Views/.../Explore/ExploreClientViewModel.swift:~270-285` `formatPrice` (logic being replaced) | exact (logic) |
| `Utils/PaidBookingWindow.swift` (new) | utility | transform | `Utils/Utils.swift` | role-match |
| `Utils/BookingErrorMapper.swift` (new) | utility | transform | `MakeABookingViewModel.handlePaidFlowError` (~L596-640) + `Network/Error+UserMessage.swift` | exact (copy source) |
| `Managers/PushRoutePlanner.swift` (new) | utility | request-response | `Managers/PushRouter.swift` `destination(for:)` | exact |
| `Managers/PushForegroundPolicy.swift` (new) | utility | event-driven | `ClickMe2026AppDelegate.swift` `willPresent` (L147-159) | role-match |
| `Managers/PushTokenCleanup.swift` (new) | service | event-driven | `Managers/UserManager.swift` `unregisterPushTokenIfAny` (~L652) | role-match |
| `Managers/PushRouter.swift` (mod) | provider | event-driven | itself | exact |
| `Model/Push/PushEvent.swift` (mod) | model | transform | itself | exact |
| `Model/Enums/BookingStatus.swift` (mod) | model | transform | itself (+ `ErrorCode.swift` for tolerant decode) | exact |
| `Model/Enums/ErrorCode.swift` (mod) | model | transform | itself | exact |
| `Views/Screens/Call/Calling/ExternalMeetingProvider.swift` (mod) | utility | transform | itself | exact |
| `Views/Screens/Call/Calling/MeetingCallViewModel.swift` (mod, L532, L692) | view-model | event-driven | itself | exact |
| `Managers/AgoraManager.swift` (mod, ~L276) | service | event-driven | its own `didJoinedOfUid` / `didOfflineOfUid` delegates | exact |
| `Managers/UserManager.swift` (mod, `logout()`) | manager | request-response | itself | exact |
| `ClickMe2026AppDelegate.swift` (mod) | controller | event-driven | itself | exact |
| `Views/Extensions/HomeNavigationPath.swift` (mod, add `replace(with:)`, `HomeRoute.requestDecision`) | utility | event-driven | itself | exact |
| `Views/Screens/Client Mode/Home/HomeClientView.swift` (mod) | component (shell) | event-driven | its `chatsTab` / `profileTab` (register HomeRoute) | exact |
| `Views/Screens/Expert Mode/Home/HomeExpertView.swift` (mod) | component (shell) | event-driven | `HomeClientView.swift` | exact |
| `MakeABookingViewModel.swift` (mod), `RescheduleViewModel` (mod) | view-model | request-response | itself | exact |
| Money call sites (15 files, see RESEARCH Pattern 4 table) | view-model | transform | `ExploreClientViewModel.formatPrice` | exact |
| Join-window call sites (`UpcomingBookingsView`, `ExpertDashboardView`, `ExploreClientViewModel`, `ExpertDashboardViewModel`) | view/view-model | transform | `UpcomingBooking.isWithinJoinWindow` | exact |
| `MeetingCallView.swift` (mod, banner at end+55) | component | event-driven | its `bannerText` (~L221) | exact |
| Tests: `Utils/{Money,JoinWindow,CallOvertimePolicy,PaidBookingWindow,BookingErrorMapper}Tests.swift`, `Calls/*`, `Model/BookingStatusDecodingTests.swift`, `Push/*` (all new) | test | transform | `Network/Discovery/ClientHomeFeedTests.swift` | role-match |

## Pattern Assignments

### Shared header and isolation (every new Swift file)

Every new source file starts with the Xcode header (copy `Model/Push/PushEvent.swift:1-6`):
```swift
//
//  PushEvent.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
```
The app target defaults to `MainActor`, so every pure helper must be declared `nonisolated enum` / `nonisolated struct` (RESEARCH Pitfall 1). `Utils/Utils.swift:11` shows the namespace-enum shape (`enum Utils { static func ... }`) but it is main-actor by default; do NOT copy it without `nonisolated`.

---

### `Utils/Money.swift` (utility, transform)

**Analog (logic to replace):** `Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift` `formatPrice` (~L270-285)
```swift
private static func formatPrice(
    _ rate: ClientHomeData.FeaturedTopic.HourlyRate?,
    isFree: Bool?
) -> String {
    if isFree == true { return "Free" }
    guard let amount = rate?.amount, let currency = rate?.currency else { return "—" }
    let amountMajor = Double(amount) / 100.0
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.maximumFractionDigits = amountMajor.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
    ...
}
```
Keep the "Free" and "—" branches at the call site; replace only the body from `let amountMajor` down with `Money.format(minorUnits: amount, currency: currency)`. Use the `Money` enum from RESEARCH Pattern 4 verbatim (integer math, backend zero-decimal set, fixed symbol table, no `NumberFormatter`, no locale). Two entry points: `format(minorUnits:currency:)` and `format(major:currency:)`; each of the 15 call sites must pick the right one per the unit column in RESEARCH Pattern 4.

---

### `Utils/JoinWindow.swift` (utility, transform)

**Analog (logic to replace):** `Model/UIModels/UpcomingBooking.swift:62-67`
```swift
var isWithinJoinWindow: Bool {
    if status == .pendingApproval { return false }
    if status == .completed { return endTime > Date() }
    let delta = startTime.timeIntervalSinceNow
    return delta <= 3600 && delta >= -3600
}
```
Replace body with `JoinWindow.isOpen(status:start:end:now:serverCanJoin:)` (RESEARCH Pattern 2). Pass `Date()` in from the caller; the helper never reads the clock. Same replacement at `UpcomingBookingsView.swift:64-67` and `ExpertDashboardView.swift:531-534`. Client list passes `serverCanJoin: nil`; expert list/detail pass `ExpertBookingItem.Actions.canJoin`; add additive `let canJoin: Bool?` to `ClientBookingDetail`. Statuses follow the server: `confirmed`, `inProgress`, `completed` (D-12).

---

### `Utils/CallOvertimePolicy.swift` (utility, transform) and `MeetingCallViewModel.swift` edits

**Analog:** `Views/Screens/Call/Calling/MeetingCallViewModel.swift`, `enforceMaxOvertimeCutoff` (~L527-537) and `/end` (~L689-696)
```swift
private func enforceMaxOvertimeCutoff() {
    guard let scheduledEnd else { return }
    guard callStatus != .ended, !isEndingCall else { return }
    let overtimeCutoffSeconds: TimeInterval = 5 * 60 // TEMP: was 3600
    let cutoff = scheduledEnd.addingTimeInterval(overtimeCutoffSeconds)
    guard Date() >= cutoff else { return }
    CallCenter.shared.endCall()
}
```
```swift
let duration = self.joinStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
_ = try? await self.api.endCall(
    id: bookingId,
    actualDuration: max(0, duration),
    endReason: endReason
)
```
Change: delete the TEMP constant; `switch CallOvertimePolicy.action(scheduledEnd:now: Date())` -> `.end` calls `CallCenter.shared.endCall()`, `.warn` sets a published `isOvertimeWarning = true`; `/end` uses `CallOvertimePolicy.endDuration(joinStart:now:)` (`max(1, ...)`). Keep the `isEndingCall` / `.ended` guards (fire-exactly-once). The `try?` on `/end` already exists; leave as is (best-effort). Plan CALL-01 first and alone.

---

### `Managers/AgoraManager.swift` (service, event-driven) — CALL-05

**Analog:** same file, delegate callbacks L270-290 (use the exact nonisolated + `Task { @MainActor [weak self] in }` shape)
```swift
nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    Task { @MainActor [weak self] in
        self?.remoteConnectionState = .ready
    }
}
```
Add `nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason)` in the same style. Put the state mapping in a pure `nonisolated` function (only `.failed` -> `.disconnected`, `.connected` -> `.ready`) so `AgoraConnectionMappingTests` can call it without the SDK. Remove/neutralise the dead `if uid == 0` branch in `didOfflineOfUid`.

---

### `Views/Screens/Call/Calling/ExternalMeetingProvider.swift` (utility, transform) — CALL-09

**Analog:** itself, `detect(from:)` L25-53. Keep the scheme `switch` (L32-37). Replace L40-44 `host.contains(...)` with `host == domain || host.hasSuffix("." + domain)` (strip one trailing "." and lowercase first) and delete L46-50 (raw-string fallback) entirely. See RESEARCH Pattern 3.

---

### `Model/Enums/BookingStatus.swift` (model, transform) — BOOK-18

**Analog:** itself (L14-24: `enum BookingStatus: String, Decodable`, column-aligned raw values). Add `case rescheduled` and `case unknown` plus the tolerant `init(from:)` from RESEARCH Pattern 5. Keep the column alignment style (`case pendingApproval    = "pending_approval"`). Do not add `default:` to exhaustive switches the compiler flags (Pitfall 6).

---

### `Model/Enums/ErrorCode.swift` (model, transform)

**Analog:** itself, L112-120 (comment-then-case style).
```swift
case longLeadRequiresSavedCard = "LONG_LEAD_REQUIRES_SAVED_CARD"
case commissionNotConfigured   = "COMMISSION_NOT_CONFIGURED"  // 500 — server config issue
```
Add `longLeadNotAvailable = "LONG_LEAD_NOT_AVAILABLE"` and `rescheduleTooFarAhead = "RESCHEDULE_TOO_FAR_AHEAD"` adjacent, with a one-line contract comment. Update the stale comment above `longLeadRequiresSavedCard` (it tells callers to fall through to a no-PI confirm, which the backend retired).

---

### `Utils/BookingErrorMapper.swift` (utility, transform) — PAY-05, BOOK-14

**Analog (copy the copy):** `MakeABookingViewModel.swift` ~L596-632
```swift
case .slotUnavailable:
    selectedTimeSlot = nil
    newBookingAttempt()
    bookingError = "That time slot was just taken. Please pick another."
    resetPaidFlow()
case .meetingLinkUnavailable:
    bookingError = "The expert hasn't set up their Skype/Zoom link yet. Please choose in-app voice instead."
case .directChargeDisabled:
    bookingError = "Payments are temporarily unavailable. Please try again in a few minutes."
case .paymentFailed:
    bookingError = "Your card was declined. Please try another card."
```
The mapper is only the pure `ErrorCode -> String` table (`message(for code: ErrorCode?, fallback: String) -> String`); the state side effects (`selectedTimeSlot = nil`, `newBookingAttempt()`, `resetPaidFlow()`) stay in the view model. Fallback comes from `Error.userMessage` (`Network/Error+UserMessage.swift`), never a new `errorMessage(for:)`. Call from both the paid handler and the free path (`MakeABookingViewModel.swift:~396`, `bookingError = Self.message(for: error)`) and from `RescheduleViewModel.rescheduleErrorMessage`.

**Fall-through to delete:** `MakeABookingViewModel.swift:452-462`: the `if Self.errorCode(for: error) == .longLeadRequiresSavedCard { await performLongLeadBooking(...); return }` block and the `performLongLeadBooking` method itself.

---

### `Utils/PaidBookingWindow.swift` (utility, transform) — BOOK-14

No code analog (pure arithmetic); use RESEARCH Pattern 6 snippet. Wire into `MakeABookingViewModel.slotsForSelectedDate` / `isPastDate`, `MakeABookingCalendarCard.swift:~94`, `MakeABookingTimeSlotsCard.swift:~132`, and `RescheduleViewModel.slotsForSelectedDate` / `hasSlots(on:)`. Compute `Date()` at each evaluation (Pitfall 9). Hide, not disable.

---

### `Model/Push/PushEvent.swift` (model, transform) — PUSH-01..03

**Analog:** itself. Current shape to change:
```swift
init?(userInfo: [AnyHashable: Any]) {
    let data: [String: Any] = {
        if let nested = userInfo["data"] as? [String: Any] { return nested }
        var flattened: [String: Any] = [:]
        for (key, value) in userInfo {
            if let key = key as? String { flattened[key] = value }
        }
        return flattened
    }()
    ...
    if let cat = data["category"] as? String, !cat.isEmpty { ... }
    else if let eventType = data["event_type"] as? String { switch eventType.uppercased() { ... default: return nil } }
    else { return nil }
    ...
    self.bookingId = (data["booking_id"] as? String).flatMap { UUID(uuidString: $0) }
```
Keep: the `data` flattening block and the `UUID(uuidString:)` id parsing (L86-89). Change: make the init non-failable; read `route_category` / `route_sub_category` (never `category`); trim and lowercase; empty category -> `event_type` fallback (`NEW_MESSAGE` etc.), else category empty (planner sends to notifications list); add `targetRole` accepting only `client` / `expert`. The test `categoryKeyIsIgnored` in RESEARCH expects `e.category == nil`, so make `category` `String?` (or empty-string) consistently and update every reader (`PushRouter.destination(for:)` switch, AppDelegate debug print).

---

### `Managers/PushRoutePlanner.swift` (utility, request-response) and `Managers/PushRouter.swift` (mod)

**Analog:** `Managers/PushRouter.swift` `destination(for:)` L117-163 (switch on `event.category`, `guard let id ... else { return nil }`, `.bookingDetail`/`.leaveReview` etc.). Planner calls `PushRouter.destination(for:)` then applies the D-02/D-03 mode logic (RESEARCH Pattern 7). Make `destination(for:)` `nonisolated static` so the pure planner and tests can call it (the class is `@MainActor`).

Edits to the table:
- `booking/requests`: `.incomingRequest(bookingId:)` when `bookingId` present, else `.incomingRequests` (L124-126).
- `booking/payment_actions` falls into the existing generic `booking/*` -> `.bookingDetail` (L127-128); add only a test row (D-01).
- Split terminal sub-categories (`declines`, `cancellations`, `expirations`, `refunds`) to the summary route.

State shape change (L68): replace
```swift
@Published var pendingDestination: PushDestination?
```
with `@Published var pending: PendingPush?` (`destination`, `mode`; both `Equatable`). `handleTap` (L82-90) becomes: build plan via `PushRoutePlanner.plan(...)`, set `pending`. Keep `handleForegroundArrival` (L96-98) unchanged. `NotificationsListView.swift:~158` and `NotificationsListViewModel.destination(for:)` set the old property directly; update them in lockstep (mode `nil`).

---

### `Managers/PushForegroundPolicy.swift` (utility, event-driven) — CHAT-09

**Analog:** `ClickMe2026AppDelegate.swift` `willPresent` L147-159
```swift
let userInfo = notification.request.content.userInfo
if let event = PushEvent(userInfo: userInfo) {
    Task { @MainActor in
        PushRouter.shared.handleForegroundArrival(event)
    }
}
completionHandler([.banner, .list, .sound, .badge])
```
Keep the `handleForegroundArrival` tick unconditional; replace only the completion options with `PushForegroundPolicy.options(for: event, visibleChatThreadId:)`. Since the event is now non-failable, drop the `if let`. `ChatPresence.visibleThreadId` is set from `ChatView`'s `.onAppear` / `.onDisappear`.

**didReceive** (L170-195): remove the `else` "parse FAILED" branch (init no longer fails); keep `completionHandler()` called last; keep logging inside `#if DEBUG`; do NOT copy the full-`userInfo` dump (project rule), and remove the debug print that reads `event.category` non-optionally.

---

### Shell files: `HomeClientView.swift`, `HomeExpertView.swift`, `HomeNavigationPath.swift` (D-04, CR-01)

**Analog:** `HomeClientView.swift` `chatsTab` / `profileTab` (L205-232) already register `HomeRoute`:
```swift
private var chatsTab: some View {
    NavigationStack(path: $chatsPath.path) {
        ChatConversationsView()
            .navigationDestination(for: HomeRoute.self) { route in
                homeRouteDestination(route)
            }
    }
    .environment(\.homeNavigationPath, chatsPath)
}
```
`searchTab` (L198-203) and `bookingsTab` (L205-210) do not register it; that is CR-01. Introduce one helper per shell (`homeStack(path:root:)`) wrapping `NavigationStack(path:)` + a single `.navigationDestination(for: HomeRoute.self)` + `.environment(\.homeNavigationPath, path)`, and use it for every tab. `HomeExpertView` Topics tab (:164) is the same gap.

Push handler to change (`HomeClientView.swift` L132-171, mirror in `HomeExpertView.swift` ~L81-132): current shape `.onChange(of: pushRouter.pendingDestination)` + `.onAppear` -> `handlePushDestination`, with per-case `selectedTab = ...; xPath.push(...)` and `pushRouter.pendingDestination = nil` at the end. Changes:
1. Observe `pending`. If `pending.mode` differs from this shell's mode: `userManager.setMode(...)` and return WITHOUT clearing.
2. Otherwise set `selectedTab` for every case (the `.notificationsList`, `.incomingRequests`, `.payouts`, `.kycOnboarding` cases currently push onto `explorePath` with no tab selection), call `path.replace(with: route)`, then clear `pending`.
3. Add `HomeRoute.requestDecision(requestId:)` and handle it in the exhaustive `homeRouteDestination` switches (expert: `RequestDecisionView(requestId:)`; client: `EmptyView()`).

`HomeNavigationPath.swift` (same pattern as existing `push`/`pop`/`reset`, L26-43): add
```swift
func replace<V: Hashable>(with value: V) { path = NavigationPath([value]) }
```
Fallback if A1 fails on device: `reset()` then `push` on the next run-loop turn. Also fix the stale doc comment (L10-15) that says tabs share one stack.

---

### `Managers/UserManager.swift` + `Managers/PushTokenCleanup.swift` (PUSH-04)

**Analog:** `UserManager.logout()` L297-318 and `unregisterPushTokenIfAny()` ~L652
```swift
func logout() {
    Task { [weak self] in await self?.unregisterPushTokenIfAny() }   // runs after the bearer is nil
    authUser = nil
    ...
    api.bearerToken = nil
    persist(token: nil)
    clearRefreshCredentials()
    RealtimeService.shared.disconnect()
    ...
}

private func unregisterPushTokenIfAny() async {
    guard hasStoredToken else { return }     // always false by the time this runs
    let deviceId = Self.deviceIdentifier()
    _ = try? await api.unregisterDeviceToken(deviceId: deviceId)
    UserDefaults.standard.removeObject(forKey: pushDeviceTokenKey)
}
```
Change: capture deviceId and bearer first, set `isLoggingOut`, await the DELETE raced against a 3 s timeout, always `Messaging.messaging().deleteToken`, then run the existing clearing block unchanged. Involuntary paths (`handleAccountSuspended`, auth-rejection) skip the DELETE and stay synchronous. Marker `pendingPushCleanup` lives in `UserDefaults` (same style as `pushDeviceTokenKey`, `onboardingShownKey`). Put the sequence in `PushTokenCleanup` with injected closures (`unregister`, `deleteToken`, `clearSession`) so the order is testable. API call: `Network/ClickMeAPI+Notifications.swift:28` `unregisterDeviceToken(deviceId:)`. Also clear `PushRouter.shared.pending` in the clearing block. Callers to update: the two profile VMs' `logOut()`, delete-account "Back to Login", `AccountSecurityView.onBackToLogin`.

---

### Test files (new, under `ClickMe2026Tests/{Utils,Calls,Model,Push}/`)

**Analog:** `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift`

Header/imports (L1-17):
```swift
import Foundation
import Testing
@testable import ClickMe2026
```
Fixtures are a `private enum` with `nonisolated static` builders (L21-68). Suite shape (L~100):
```swift
@Suite("ClickMeAPI+Discovery · client home feed", .serialized)
@MainActor
struct ClientHomeFeedTests {
    @Test("decodes hourly_rate {amount:0,currency:null}")
    func decodesZeroAmountNullCurrency() async throws {
        let api = makeAPI(serving: ...)
        let topic = try #require(response.data.featuredTopics?.first)
        #expect(topic.hourlyRate?.amount == 0)
    }
}
```
Rules for the new suites:
- Pure helper suites (`MoneyTests`, `JoinWindowTests`, `CallOvertimePolicyTests`, `PaidBookingWindowTests`, `BookingErrorMapperTests`, `ExternalMeetingProviderTests`, `AgoraConnectionMappingTests`, `PushRoutePlannerTests`, `PushForegroundPolicyTests`): `@Suite` + `@Test(arguments:)` tables, no network, no `.serialized` needed; use `@MainActor struct` only if they touch main-actor types.
- Decoding suite (`BookingStatusDecodingTests`): mirror `RealtimeService.decoder` config (`.convertFromSnakeCase`, `.iso8601`), per RESEARCH "Code Examples".
- `PushTokenCleanupTests`: fakes through injected closures; no `MockURLProtocol` needed. If an API-level test is wanted, use `APITestFactory.make { request in ... }` and `MockURLProtocol.handler` as in `ClientHomeFeedTests` L81-97 (call `MockURLProtocol.reset()` between tests).
- `.serialized` is required for any suite that sets the shared `MockURLProtocol.handler`.
- Run command with the broken-test exclusion is in RESEARCH "Validation Architecture".

## Shared Patterns

### Error handling and copy
**Source:** `Network/Error+UserMessage.swift`; `Model/Enums/ErrorCode.swift`
**Apply to:** `BookingErrorMapper`, `MakeABookingViewModel`, `RescheduleViewModel`, expert reschedule path
Branch on `ErrorCode`, never on `message`; fall back to `error.userMessage`; no new private `errorMessage(for:)`. Catch blocks set `@Published var apiError` / `bookingError`.

### Pure helpers under strict concurrency
**Source:** RESEARCH Pitfall 1 (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
**Apply to:** all new `Utils/` and planner/policy types: `nonisolated enum`, no `Date()`/`Locale.current` inside, `now` passed in.

### Main-actor delegate hop
**Source:** `Managers/AgoraManager.swift:270-290`
**Apply to:** the new Agora `connectionChangedTo` delegate: `nonisolated func` + `Task { @MainActor [weak self] in ... }`.

### Logging
**Source:** project CLAUDE.md, `ClickMe2026AppDelegate.swift`
**Apply to:** push, logout, call code: `#if DEBUG` only, `push:` prefix, no tokens or full payloads.

### Registration of navigation destinations
**Source:** `HomeClientView.swift` `chatsTab`/`profileTab`
**Apply to:** all ten tab stacks (client 5, expert 5) through one helper per shell.

### Section markers and docs
`// MARK: -` dividers, `///` docs that state the why (server contract, race); file header block on every file.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `Utils/PaidBookingWindow.swift` | utility | transform | No existing date-cap helper; use RESEARCH Pattern 6 (mirror of Android `BookingSlots.kt` in `../ClickMe_Android`) |
| `Managers/PushTokenCleanup.swift` | service | event-driven | No existing injected-closure sequencing type; base on `unregisterPushTokenIfAny` plus Android `FcmPushTokenRegistrar.kt` |
| `ChatPresence` visible-thread tracker | store | event-driven | No existing presence tracker; small `@MainActor` holder set from `ChatView` `.onAppear`/`.onDisappear` |

## Metadata

**Analog search scope:** `ClickMe2026/{Utils,Managers,Model,Network,Views/Extensions,Views/Screens/{Call,Client Mode,Expert Mode}}`, `ClickMe2026Tests/`
**Files scanned:** ~25 read (targeted ranges), plus directory and grep listings
**Tracked-source check:** `PushRouter.swift`, `Utils.swift`, `MockURLProtocol.swift`, and the `ClickMe2026Tests` tree confirmed via `git ls-files`; no capability-mirror paths are named.
**Pattern extraction date:** 2026-11-09
**Caveat:** line numbers for files not re-read this pass (`ExploreClientViewModel`, `MakeABookingViewModel` ~L396, `HomeExpertView`, `NotificationsListView`) come from RESEARCH.md and CONTEXT.md; planner/executor should re-confirm with a targeted Read before editing.
