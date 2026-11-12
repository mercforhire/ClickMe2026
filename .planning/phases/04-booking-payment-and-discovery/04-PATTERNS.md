# Phase 4: Booking, Payment and Discovery - Pattern Map

**Mapped:** 2026-11-11
**Files analyzed:** 40 (15 new iOS helpers/suites groups, ~20 modified iOS, 6 backend)
**Analogs found:** 38 / 40 (all analog paths verified git-tracked; no mirror paths)

## File Classification

### New iOS files

| New File | Role | Data Flow | Closest Analog | Match |
|----------|------|-----------|----------------|-------|
| `ClickMe2026/Utils/ConfirmOutcome.swift` | utility (pure classifier) | transform | `ClickMe2026/Utils/PaidBookingWindow.swift` (pure enum) + `Utils/BookingErrorMapper.swift` | role-match |
| `ClickMe2026/Utils/PaymentSheetOutcome.swift` | utility (pure) | transform | `Utils/PaidBookingWindow.swift` | exact |
| `ClickMe2026/Utils/PagedList.swift` | utility (value type) | CRUD/paging | paging state in `Views/Screens/Client Mode/Payments/ClientTransactionsViewModel.swift` | role-match |
| `ClickMe2026/Utils/HomeShellExit.swift` | utility (pure planner) | transform | `Utils/PaidBookingWindow.swift`; types from `Home/Subviews/HomeClientTab.swift` | role-match |
| `ClickMe2026/Utils/PaymentLifecycleVariant.swift` | utility (pure chooser) | transform | `Utils/CancelRefundPreview.swift` (`refundCase`, lines 90-127) | exact |
| `ClickMe2026/Utils/AutoLoginOutcome.swift` | utility (pure) | transform | `Utils/PaidBookingWindow.swift` | role-match |
| `ClickMe2026/Managers/UnconfirmedBookingLedger.swift` | manager (session store) | event-driven | `Utils/ReloadGeneration.swift` (small value store); `@MainActor` rule from `UserManager` | partial |
| `ClickMe2026/Utils/DateUtil.swift` (add `shortTime`, `zoneName`) | utility | transform | same file's cached `formatter(...)` | exact |
| `ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileStateView.swift` | component | request-response | `Request Sent` error view / Favorites error view (read the file before writing) | role-match |
| Tests: `PaymentSheetOutcomeTests`, `ConfirmOutcomeTests`, `PaymentLifecycleVariantTests`, `HomeShellExitTests`, `PagedListTests`, `AutoLoginOutcomeTests`, `SuspensionNoticeTests`, `UnconfirmedBookingLedgerTests`, `SlotTimeFormatTests`, `ExpertProfileSectionsTests` | test (pure) | transform | `ClickMe2026Tests/Utils/PaidBookingWindowTests.swift` | exact |
| Tests: `MakeABookingPaidFlowTests`, `MakeABookingAvailabilityTests`, `ExpertProfileViewModelTests`, `FavoritesViewModelPagingTests`, `ExpertReviewsViewModelPagingTests` | test (VM + stubbed API) | request-response | `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift`; stale-guard: `Tests/Utils/ReloadGenerationTests.swift` | exact |

### Modified iOS files

| File | Role | Data Flow | Analog / Pattern Source | Match |
|------|------|-----------|-------------------------|-------|
| `Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift` | view helper | event-driven | itself, lines 92-110 | exact |
| `Make a Booking/MakeABookingViewModel.swift` (PAY-02, D-04/D-15, BOOK-02, PAY-04) | view model | request-response | itself (`handlePaidFlowError`, `errorDetail`) | exact |
| `Client Mode/Home/HomeClientView.swift`, `Views/Extensions/HomeNavigationPath.swift` | shell/config | event-driven | itself (`HomeShellAction`, `@Entry`) | exact |
| `Favorites/FavoritesViewModel.swift`, `Reviews/ExpertReviewsViewModel.swift` | view model | CRUD/paging | `ClientTransactionsViewModel.loadNextPageIfNeeded` | exact |
| `Expert Profile/ExpertProfileViewModel.swift` | view model | request-response | itself; `LoadState` | role-match |
| `Managers/UserManager.swift`, `Login/LoginView.swift`, `Splash/SplashViewModel.swift` | manager/view | request-response | `UserManager.tryAutoLogin` (lines 267-330) | exact |
| `Model/UIModels/BookingTimeSlot.swift`, `ExploreClientViewModel.swift`, `MakeABookingTimeSlotsCard.swift` | model/VM | transform | `DateUtil` | exact |
| `Request Sent/*`, `PaymentLifecycleCard.swift`, `FavoritesProTipCard.swift`, `FavoritesEmptyState.swift`, `SearchExpertCard.swift` | view | request-response | themselves; `TopicsSetupFlowLayout` used by `FavoriteExpertCard.swift:79` | exact |

### Backend files (`/Users/LeonChen/Documents/ClickMe2026 Backend`)

| File | Role | Data Flow | Analog | Match |
|------|------|-----------|--------|-------|
| `src/controllers/webhooks.controller.js` (add `payment_method.detached` case) | controller | event-driven | `dispatchPlatformEvent` switch, lines ~513-540 | exact |
| `src/services/connectedPaymentMethodClone.js` (header comment + reuse evict) | service | CRUD | itself, lines 122-159 | exact |
| `src/cron/longLeadChargeSweep.js` (platform-card guard in `chargeOne`) | cron/service | batch | itself, lines ~290-345 | exact |
| `tests/webhooks.test.js` | test | event-driven | `describe('POST /webhooks/stripe — unknown event type + reconciler failure')` (line 294) | exact |
| `tests/services/connectedPaymentMethodClone.test.js` | test | CRUD | `describe('evictClonesForPlatformPaymentMethod (BACK-07)')` (line 233) | exact |
| `tests/cron/longLeadChargeSweep.test.js` | test | batch | hard decline test (~line 190) | exact |

---

## Pattern Assignments

### Conventions for every new Swift file
Xcode header block (`//  File.swift` / `//  ClickMe2026` / copyright), `// MARK: -` sections, `Id` spelling, `///` docs explaining why. New `Utils/` helpers are `nonisolated enum`/`struct`. New files auto-register (synchronized groups).

### Pure helpers: `PaymentSheetOutcome`, `ConfirmOutcome`, `HomeShellExit`, `PaymentLifecycleVariant`, `AutoLoginOutcome`

**Analog:** `ClickMe2026/Utils/PaidBookingWindow.swift` (lines 1-55), for the shape.

```swift
import Foundation

/// How far ahead a paid session can start (BOOK-14).
/// ... (doc explains WHY and the server contract)
/// The helper never reads the clock. Callers pass `now` ...
nonisolated enum PaidBookingWindow {
    static let maxLead: TimeInterval = 6 * 24 * 3600
    static func latestStart(isPaid: Bool, now: Date) -> Date? { isPaid ? now.addingTimeInterval(maxLead) : nil }
    static func allows(_ start: Date, latestStart: Date?) -> Bool {
        guard let latestStart else { return true }
        return start <= latestStart
    }
}
```
Rules: `nonisolated`, no clock or singletons read inside, all inputs as parameters, mirror the server/Android rule in the doc comment.

**`PaymentLifecycleVariant` analog (exact):** `Utils/CancelRefundPreview.swift:99-127`. Copy the case-enum plus pure chooser and the live-hold predicate, then add variants A/B/C/none:
```swift
if facts.isFree { return .free }
if facts.paymentActionRequired || facts.paymentStatus == "none" { return .notChargedYet }
...
let isLiveHold = facts.paymentStatus == "held" && facts.authorizationExpiresAt != nil
let isCharged = facts.paymentStatus == "captured" || facts.paymentStatus == "held"
guard isCharged else { return .amountUnknown }   // fail closed -> PAY-03 "Unknown" hides the card
```
Copy lives in a separate `static func text(for:)` switch (lines 131-147).

**`ConfirmOutcome`:** use the research Pattern 2 classifier. Error shapes: `NetworkError.httpError(statusCode:data:)`, `.invalidResponse`, `.decodingFailed`; raw `URLError` escapes `NetworkService.sendRaw`. `BookingErrorMapper.code(for:)` already extracts `ErrorCode` from a thrown error. Branch on codes, never message text.

**`HomeShellExit`:** types `HomeClientTab` (`Home/Subviews/HomeClientTab.swift:13`, `explore, search, bookings, chats, profile`). Pure `plan(_ action:, selectedTab:)` returning `resetTabs: Set<HomeClientTab>`, `showTab`, optional Past segment. Rules in 04-UI-SPEC section 4.

**`AutoLoginOutcome`:** extract the decision currently inline in `UserManager.tryAutoLogin` (lines 267-306, `isAuthRejection` at 316-330). `UserManager` has a `private init`, so the singleton cannot be unit tested. Inputs: `hasStoredToken`, refresh error, `wasSuspended`. A suspension returns "login".

### `MakeABookingStripePaymentSheet.swift` (PAY-01, D-01, D-16)

**Current code to replace** (lines 71-110):
```swift
var config = PaymentSheet.Configuration()
config.merchantDisplayName = "ClickMe"
config.allowsDelayedPaymentMethods = false
...
case .success(let flowController):
    flowController.presentPaymentOptions(from: presenter) {
        guard flowController.paymentOption != nil else {
            viewModel.cancelPaidBooking()
            return
        }
        Task { await confirmViaFlow(flowController: flowController, presenter: presenter) }
    }
```
**Change:** use the `completion: ((_ didCancel: Bool) -> Void)?` overload (`PaymentSheetFlowController.swift:486-490`, stripe-ios 26.2.0, not the async one), guard through `PaymentSheetOutcome.proceed(didCancel:hasOption:)`, and add `config.link.display = .never` after line 73 (D-16). Keep the silent `cancelPaidBooking()` (D-02).

**PAY-04 comments:** delete the stale text at lines 174-178 ("Backend hasn't shipped detail.stripe_account yet"). Keep the `guard let stripeAccount` fail-closed code.

### `MakeABookingViewModel.swift` (PAY-02, D-03, D-04, D-15, BOOK-02, PAY-04)

**Analog:** itself, `handlePaidFlowError` (lines ~560-660).
```swift
private enum PaidPhase { case createIntent, confirm }
private func handlePaidFlowError(_ error: Error, phase: PaidPhase, topic: BookingTopic, slot: BookingTimeSlot) {
    let code = BookingErrorMapper.code(for: error)
    let message = error.userMessage
    switch code {
    case .slotUnavailable:
        selectedTimeSlot = nil
        newBookingAttempt()
        bookingError = BookingErrorMapper.message(for: code, fallback: message)
        resetPaidFlow()
    case .duplicateBooking:
        bookingError = BookingErrorMapper.message(for: code, fallback: message)
        resetPaidFlow()
    default:
        if phase == .confirm, let intentId = paymentIntentId {
            bookingError = "\(message)\n\nPayment reference: \(intentId)"
        } else { bookingError = message }
        resetPaidFlow()
    }
}
```
**Changes:**
- Before `switch code`, when `phase == .confirm` and `ConfirmOutcome.classify(error) == .outcomeUnknown`, do not call `resetPaidFlow()`. Keep `paymentIntentId`, the `pm_`, and `bookingAttemptId`. Auto-retry 1-2 times with an injected `retryDelays` (`.zero` in tests). On exhaustion raise the `PaidFlowAlert` (research "Code Examples").
- `.slotUnavailable`: if `UnconfirmedBookingLedger` has the key, use the "You may already have this booking" variant (D-04). Keep `selectedTimeSlot = nil` (K4).
- `.duplicateBooking` in `.createIntent` with a parseable `detail["booking_id"]` UUID: if the ledger has the key, set `completedBookingId` (D-15 smart route). Otherwise show the D-04 alert. Parse with the existing helper:
```swift
private static func errorDetail(for error: Error) -> [String: Any]? {
    guard case let NetworkError.httpError(_, data) = error,
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return root["detail"] as? [String: Any]
}
```
- `retryConfirmAfterSCA` (line ~666) also calls `completePaidBooking`, so SCA retries inherit the behavior.
- BOOK-02: `ReloadGeneration` pattern (below). Delete the stale `TODO(backend)` at lines 178-180 (and the `SCAChallenge.stripeAccount` doc).
- File is ~848 lines. Put new logic in a sibling file (`MakeABookingViewModel+PaidFlow.swift`) or the helpers above, per CLAUDE.md. Note `bookingAttemptId` is `private(set)`.

### BOOK-02: month-change race

**Analog:** `ClickMe2026/Utils/ReloadGeneration.swift`
```swift
nonisolated struct ReloadGeneration {
    private(set) var current = 0
    mutating func begin() -> Int { current += 1; return current }
    func isCurrent(_ token: Int) -> Bool { token == current }
}
```
Use `let token = availabilityGate.begin()` before the first `await` in `loadAvailability`, then re-check `isCurrent(token)` after each await and before every write. Treat `URLError.cancelled`/`CancellationError` as not-failed (same as `ExploreClientViewModel.isCancellation`, line ~287).
**Test analog:** `ClickMe2026Tests/Utils/ReloadGenerationTests.swift` (a `FakeScreen` with continuations; a `waitUntil` helper yields until N fetches are suspended).

### Paging: `PagedList`, `FavoritesViewModel`, `ExpertReviewsViewModel` (D-07)

**Analog:** `Views/Screens/Client Mode/Payments/ClientTransactionsViewModel.swift:95-151`. Copy the trigger and the 500-as-end rule:
```swift
func loadNextPageIfNeeded(currentItem: ClientTransactionItem) async {
    guard !isLoadingMore, hasMore, case .loaded = loadState else { return }
    guard let index = items.firstIndex(of: currentItem), index >= items.count - 3 else { return }
    isLoadingMore = true
    pageError = nil
    defer { isLoadingMore = false }
    let requestedPage = currentPage + 1
    do {
        let response = try await api.getClientTransactions(page: requestedPage, limit: limit)
        items.append(contentsOf: response.data.transactions)
        currentPage = requestedPage
        hasMore = response.data.pagination.hasMoreOrDerived
    } catch {
        if requestedPage > 1, case let NetworkError.httpError(status, _) = error, status == 500 {
            hasMore = false
            return
        }
        pageError = error.userMessage
    }
}
```
**Differences to apply:**
- The envelope has no total, only `has_more` (`PaginationMeta.hasMoreOrDerived`). Do not implement "stop at total".
- Dedupe by `FavoriteExpert.expertId` and a new `ExpertReview.serverId` (from `ReviewItem.id`). Today `id = UUID()` on every map.
- Current first-page loads are `api.getClientFavorites()` (`FavoritesViewModel.swift:~67`) and `api.getExpertReviews(id: expertId)` (`ExpertReviewsViewModel.swift:~102`). Pass `page:`/`limit: 20`.
- Unfavorite: reload on the next paging trigger (Pitfall 4).
- Keep the existing `load()`/`reload()`/`forceLoad()` split and the optimistic remove with rollback (`FavoritesViewModel.swift:~84-110`).

### `ExpertProfileViewModel.swift` (EXPL-01, EXPL-05, D-09, D-10)

**Replace** lines 62-90 (`try? await api.getExpertDetails`, `try? ... getClientFavorites(page: 1, limit: 100)`):
```swift
let details = try? await api.getExpertDetails(id: expertId)
let reviews = try? await api.getExpertReviews(id: expertId, page: 1, limit: 3)
let favorites = try? await api.getClientFavorites(page: 1, limit: 100)
```
Make details a `do/catch` that sets `ProfileLoadState` (`loading/loaded/notFound/failed(String)`), branching on status 404 or `BookingErrorMapper.code(for:) == .notFound`. Keep reviews `try?` (best-effort). Delete the favorites scan; read `is_favorite` from `PublicProfileDetailsData` (new optional field). Existing init already takes `isFavorited:` and `api:` (lines 36-45), which is the injection seam for tests.
**Test analog:** `ClientHomeFeedTests.swift` (the `makeAPI(serving:)`, `response(for:status:body:)` and `@Suite(..., .serialized) @MainActor struct` pattern).

### Shell actions (`HomeClientView.swift:87-98`, `HomeNavigationPath.swift:185-211`)

**Current:**
```swift
.environment(\.showMyBookings, HomeShellAction {
    explorePath.reset()
    bookingsPath.reset()
    selectedTab = .bookings
})
.environment(\.returnToHome, HomeShellAction {
    explorePath.reset()
    selectedTab = .explore
})
```
**Pattern for the new history action:**
```swift
struct HomeShellAction { let action: () -> Void; func callAsFunction() { action() } }
extension EnvironmentValues {
    @Entry var showMyBookings: HomeShellAction? = nil
    @Entry var returnToHome: HomeShellAction? = nil
}
```
Add `@Entry var showMyHistory: HomeShellAction? = nil` with a doc comment. Closures in `body` are untestable, so each closure applies a `HomeShellExit.plan(...)` result. Per-tab paths: `explorePath`, `searchPath`, `bookingsPath`, `profilePath` (`HomeNavigationPath.reset()`). The shell must own `MyBookingsViewModel` (`@StateObject`) so it can set `selectedTab = 1` (Past). Today it is created in `MyBookingsView`'s default argument. Pass `onExplore`/`onViewHistory` from `ClientProfileHomeScreen.swift:~207` to `FavoritesView`.
**Regression test:** `ClickMe2026Tests/Utils/HomeNavigationPathTests.swift`.

### Time formatting (BOOK-03/04): `DateUtil`, `BookingTimeSlot`, `ExploreClientViewModel`

**Analog:** `Utils/DateUtil.swift` formatter cache, lines 79-96:
```swift
private static let cacheLock = NSLock()
nonisolated(unsafe) private static var cache: [String: DateFormatter] = [:]
private static func formatter(format: Format, timeZone: TimeZone, locale: Locale) -> DateFormatter {
    let key = "\(format.rawValue)|\(timeZone.identifier)|\(locale.identifier)"
    cacheLock.lock(); defer { cacheLock.unlock() }
    ...
}
```
Add `shortTime(_:timeZone:locale:)` (`timeStyle = .short`, `dateStyle = .none`) as a new method. Do not reuse the format-string cache key (the identifier is unchanged by the 12/24-hour toggle; build per call or hold `Locale.autoupdatingCurrent`). Add `zoneName(...)` using `TimeZone.localizedName(for: .generic, locale:)`, which returns nil to omit the label.
**Call sites to replace:** `BookingTimeSlot.displayLabel` (`en_US_POSIX`, `"h:mm a"`, built per call, also used by `RescheduleTimeSlotsCard.swift:74` and `MakeABookingView.swift:215`), `ExploreClientViewModel.timeRangeString` (lines ~179-184), `Text(tz)` in `MakeABookingTimeSlotsCard.swift:19-23`.
**Tests:** pass explicit locales. The test plan runs region GB, and en_US output has U+202F before AM/PM (`"2:00\u{202F}PM"`).

### Suspension on cold launch (D-13)

**Analog:** `Managers/UserManager.swift`: `wasSuspended` (line 34), suspension handler (157-170), `clearSuspensionFlag()` (177), `tryAutoLogin` (267-306).
```swift
do { try await refreshMe() } catch {
    if Self.isAuthRejection(error) { forceLogout(); return false }
    // Transient ...
}
if hasStoredToken { requestPushPermissionIfNeeded(); fetchAndUploadFCMToken() }
return true
```
`isAuthRejection` excludes `ACCOUNT_SUSPENDED` (lines 316-330), which falls into the transient branch and returns `true`. Route the decision through `AutoLoginOutcome`, have `SplashViewModel`/`LoginView` read `wasSuspended`, show the alert once, then call `clearSuspensionFlag()`. Nothing reads `wasSuspended` today.

### Unit tests: pure helpers

**Analog:** `ClickMe2026Tests/Utils/PaidBookingWindowTests.swift`
```swift
import Foundation
import Testing
@testable import ClickMe2026

@Suite("PaidBookingWindow")
struct PaidBookingWindowTests {
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)   // fixed clock
    @Test("a paid topic ends at exactly now + 6 days, inclusive")
    func paidEdge() { ... #expect(...) }
}
```
Header comment names the requirement ID and the rule. Use `Locale`/`Calendar` passed in.

### Unit tests: VM + stubbed network (`MakeABookingPaidFlowTests`, paging, profile)

**Analog:** `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift` + `Support/APITestFactory.swift`
```swift
@MainActor
private func makeAPI(serving body: Data) -> ClickMeAPI {
    APITestFactory.make { request in
        if request.url?.path.hasSuffix("/client/home") == true { return HomeFeedFixture.response(for: request, body: body) }
        return HomeFeedFixture.response(for: request, status: 404, body: Data(#"{"status":"error","message":"nope"}"#.utf8))
    }
}
@Suite("...", .serialized) @MainActor struct ClientHomeFeedTests { ... }
```
- Throw `URLError(.networkConnectionLost)` from the handler to simulate transport failure. `MockURLProtocol.recordedRequests` is appended before the handler runs, so a handler can branch on the count.
- Swap handlers between calls with `MockURLProtocol.handler = ...`.
- Suites touching `MockURLProtocol` are `.serialized`; run one suite per `xcodebuild`.

### Backend: `payment_method.detached` (D-12)

**Webhook analog:** `src/controllers/webhooks.controller.js` `dispatchPlatformEvent` (~lines 513-540):
```js
async function dispatchPlatformEvent(event) {
  const eventObject = event.data ? event.data.object : null;
  switch (event.type) {
    case 'charge.refunded':
      await reconcileChargeRefunded(eventObject);
      return true;
    case 'application_fee.created':
      return _throwIfUnresolved(await reconcileApplicationFeeCreated(eventObject, event.id));
    default:
      return false;   // caller stamps terminal "ignored" (D-05)
  }
}
```
Add `case 'payment_method.detached':` that calls `evictClonesForPlatformPaymentMethod(eventObject.id)` and returns `true`. Read only `eventObject.id`, and ignore ids that do not start with `pm_`. A thrown error leaves the `stripe_events` row unprocessed for the drain cron. Evicting zero rows is a no-op, so it is idempotent. Import it as `paymentMethods.controller.js:58` does:
`const { evictClonesForPlatformPaymentMethod } = require('../services/connectedPaymentMethodClone');`

**Service (`connectedPaymentMethodClone.js`):** reuse `evictClonesForPlatformPaymentMethod` (lines 122-159) unchanged: select rows by `platform_payment_method_id`, detach each clone tolerating `CLONE_ALREADY_GONE_CODES`, delete row by id. Update the header comment at lines 17-22, which currently says "NEVER call it from a booking, sweep or webhook path". It must now allow the `payment_method.detached` webhook, since the platform card is already detached and cannot be re-cloned.

**Sweep guard (`longLeadChargeSweep.js` ~lines 290-345):** insert before `getOrCreateClonedPaymentMethod(...)` (line ~309), using `retrievePaymentMethod` (`src/services/stripe.js:1052`) and `platformCustomerId`:
```js
const clonedPmId = await getOrCreateClonedPaymentMethod(
  booking.stripe_payment_method_id, booking.stripe_account_id, connectedCustomerId, platformCustomerId
);
```
and the existing hard-decline path in the `catch` (`StripeCardError` leads to `cancelAndRelease(booking, pi && pi.id)`). Platform card detached (`pm.customer !== platformCustomerId`) must take the hard-decline path. A transient retrieve error must re-throw (the "other error" branch, ~line 383: "never a wrongful immediate cancel on transient infra noise").

**Test analogs:**
- `tests/webhooks.test.js:294-335` (post a JSON payload, sign it with `makeSignature`, assert 200 and `stripeEvents.markProcessed`/`markIgnored`; a reconciler throw gives 500 `WEBHOOK_PROCESSING_FAILED` and no stamp). `dispatchPlatformEvent` is also directly callable (lines 337-347). The current unknown-event test uses `invoice.paid`.
- `tests/services/connectedPaymentMethodClone.test.js:233-271` (`makeRowsChain`/`makeDeleteChain`, `_fromQueue`, `_mockPM.detach`, `it.each(['resource_missing','payment_method_unexpected_state'])`).
- `tests/cron/longLeadChargeSweep.test.js`: the stripe module mock (lines 59-63) lists only `createManualPI`, `confirmPIOffSession`, `cancelPI`. Add `retrievePaymentMethod: jest.fn()` and set a default resolved value in `beforeEach` (line ~110) so the existing tests keep passing. Chain queue order in the success test: `[selectChain, stampChain, profileChain, makeRecheckChain(), finalChain]`. The decline test builds `Object.assign(new Error(...), { type: 'StripeCardError', code: 'card_declined' })`.
- Command: `REDIS_URL=redis://localhost:6379 npm test -- tests/webhooks.test.js tests/services/connectedPaymentMethodClone.test.js tests/cron/longLeadChargeSweep.test.js` (baseline 76 passing).

---

## Shared Patterns

### Error handling (all iOS VMs)
**Source:** `ClickMe2026/Network/Error+UserMessage.swift`, `Utils/BookingErrorMapper.swift`
Use `error.userMessage`; branch on `ErrorCode` via `BookingErrorMapper.code(for:)`, never on message text. Do not add a private `errorMessage(for:)` (existing `FavoritesViewModel`/`ExpertReviewsViewModel` have a private `message(for:)`; do not copy it into new code). No `try?` on writes or user-visible loads.

### Paid-flow state safety
**Source:** `MakeABookingViewModel` (`resetPaidFlow`, `newBookingAttempt`). Never regenerate `bookingAttemptId` or call `resetPaidFlow()` on an outcome-unknown confirm. Alert buttons must not double-submit (`isSubmitting = isBooking || paidStep != .idle`).

### Stale-response guard
**Source:** `Utils/ReloadGeneration.swift` (BOOK-02, plus any profile retry).

### Money
**Source:** `Utils/Money.swift` `Money.format(minorUnits:currency:)`. Never `/100`.

### Logging
`#if DEBUG` only; never log client secrets, ephemeral keys, `pm_` ids or full payloads. Show only the `pi_` reference to the user.

### Dates
Through `DateUtil`; no new `DateFormatter` at call sites.

### Cross-repo
Backend D-12 is its own plan, its own commit and deploy in `../ClickMe2026 Backend`, before the D-11 device session. Log Android follow-ups (PAY-01, D-03/D-04, D-05/D-06, D-07/D-08, D-10, D-13) without assuming they exist.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `PopGestureLock` (`UIViewControllerRepresentable`, only if device check D2 fails) | util | event-driven | No UIKit pop-gesture wrapper in the repo; use research Pattern 4 |
| `UnconfirmedBookingLedger` | manager | event-driven | No session-only keyed record store exists. Use `@MainActor`, `static let shared`, plain dictionary. `UserManager` shows the singleton style, but use `@Observable` only if views read it |
| `ExpertProfileStateView` | component | request-response | Not-found/failed layout is new; copy layout idiom from the existing Favorites/Reviews/Request Sent error views (not read in this pass), tokens per UI-SPEC |
| `PaidFlowAlert` presentation (three-button `.alert` with an enum) | view | event-driven | No existing multi-button model alert; use research "Code Examples" |

## Metadata

**Analog search scope:** `ClickMe2026/Utils`, `Managers`, `Views/Screens/Client Mode/{Make a Booking,Payments,Favorites,Reviews,Expert Profile,Home}`, `Views/Extensions`, `ClickMe2026Tests/{Utils,Network/Discovery,Support}`, backend `src/{controllers,services,cron}` and `tests/`
**Tracked-source check:** 8 spot-checked iOS analog paths confirmed via `git ls-files`. Backend files confirmed tracked. No gitignored mirror paths used.
**Pattern extraction date:** 2026-11-11
