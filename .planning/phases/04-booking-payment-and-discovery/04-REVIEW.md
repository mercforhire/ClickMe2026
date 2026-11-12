---
phase: 04-booking-payment-and-discovery
reviewed: 2026-11-12T00:00:00Z
depth: standard
files_reviewed: 65
files_reviewed_list:
  - ClickMe2026/Managers/UnconfirmedBookingLedger.swift
  - ClickMe2026/Managers/UserManager.swift
  - ClickMe2026/Model/Enums/ErrorCode.swift
  - ClickMe2026/Model/Responses/PublicProfileDetailsData.swift
  - ClickMe2026/Model/UIModels/BookingTimeSlot.swift
  - ClickMe2026/Utils/AutoLoginOutcome.swift
  - ClickMe2026/Utils/ConfirmOutcome.swift
  - ClickMe2026/Utils/ConfirmRetryPolicy.swift
  - ClickMe2026/Utils/DateUtil.swift
  - ClickMe2026/Utils/ExpertProfileSections.swift
  - ClickMe2026/Utils/HomeShellExit.swift
  - ClickMe2026/Utils/PagedList.swift
  - ClickMe2026/Utils/PaymentLifecycleVariant.swift
  - ClickMe2026/Utils/PaymentSheetOutcome.swift
  - ClickMe2026/Utils/SuspensionNotice.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileHero.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileStateView.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesProTipCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentActions.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentPopGestureLock.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift
  - ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupFlowLayout.swift
  - ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift
  - ClickMe2026Tests/Booking/MakeABookingAvailabilityTests.swift
  - ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift
  - ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift
  - ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift
  - ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift
  - ClickMe2026Tests/Utils/AutoLoginOutcomeTests.swift
  - ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift
  - ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift
  - ClickMe2026Tests/Utils/HomeShellExitTests.swift
  - ClickMe2026Tests/Utils/PagedListTests.swift
  - ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift
  - ClickMe2026Tests/Utils/PaymentSheetOutcomeTests.swift
  - ClickMe2026Tests/Utils/SlotTimeFormatTests.swift
  - ClickMe2026Tests/Utils/SuspensionNoticeTests.swift
  - ClickMe2026Tests/Utils/TopicsSetupFlowLayoutTests.swift
  - ClickMe2026Tests/Utils/UnconfirmedBookingLedgerTests.swift
  - "ClickMe2026 Backend D12: src/controllers/webhooks.controller.js"
  - "ClickMe2026 Backend D12: src/services/connectedPaymentMethodClone.js"
  - "ClickMe2026 Backend D12: src/cron/longLeadChargeSweep.js"
  - "ClickMe2026 Backend D12: tests/webhooks.test.js"
  - "ClickMe2026 Backend D12: tests/cron/longLeadChargeSweep.test.js"
  - "ClickMe2026 Backend D12: docs/ios/STRIPE-INTEGRATION.md"
findings:
  critical: 2
  warning: 5
  info: 6
  total: 13
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-11-12
**Depth:** standard
**Files Reviewed:** 65 (59 iOS, 6 backend D-12)
**Status:** issues_found

## Summary

The pure logic units (`ConfirmOutcome`, `ConfirmRetryPolicy`, `PaymentSheetOutcome`, `UnconfirmedBookingLedger`, `PagedList`, `HomeShellExit`, `AutoLoginOutcome`) are sound, and the confirm-retry idempotency design holds when the screen is left alone: the same PaymentIntent, `pm_` and attempt id are replayed, a server-coded answer ends the run, and a 5xx without a mapped code is treated as unknown. The PAY-01 close-equals-cancel rule is correctly encoded. The D-12 backend eviction handler is idempotent and propagates errors for retry.

Two defects need fixing before release. The first is in the iOS payment flow: the retry re-reads mutable UI selections, and nothing locks those selections while a confirm is in progress. The second is in the deployed D-12 sweep change: its "a transient Stripe error never cancels" guarantee does not hold end to end. Most of the remaining findings are race and stale-state issues in discovery view models.

I did not review the Android side. The SCA finding (WR-01) is based on reading the backend `/bookings/confirm` handler. It needs a device check, not just a code read.

## Critical Issues

### CR-01: A confirm retry re-reads the live topic and slot, and the form is not locked while confirming

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:563-596`
**Related:** `MakeABookingViewModel+PaidFlow.swift:58-65`, `MakeABookingViewModel.swift:343-346`, `Subviews/MakeABookingTimeSlotsCard.swift`, `MakeABookingTopicPicker.swift:68`, `MakeABookingCalendarCard.swift:125`

**Issue:** `completePaidBooking` reads `selectedTopic` and `selectedTimeSlot` at call time, not from a snapshot taken when the PaymentIntent was created. The first confirm is consistent because it reads them once. Every user-driven re-run reads them again: Try again goes through `retryConfirm()` to `completePaidBooking`, and `retryConfirmAfterSCA` does the same. Nothing disables the topic picker, calendar or slot chips while `paidStep != .idle`. Only the Book button is disabled (`canBook` and `isSubmitting`). So during `.confirming`, which can last minutes because the URL timeout is 120 s and there are three attempts, and while the "We couldn't confirm" alert is up, the user can:

1. Change the topic or slot. A Try again then sends the original `paymentIntentId` with a different `topicId` and `startTime`. The best case is `PI_CONTEXT_MISMATCH` or `SLOT_UNAVAILABLE`. That path clears the ledger record (`keepsRecord` is false) and resets the flow, even though a hold and booking from the first attempt may exist. The D-04 protection is then lost.
2. Change the month. `loadAvailability` sets `selectedTimeSlot = nil` on its first line (line 346). Try again then hits the `guard let slot` failure and calls `resetPaidFlow()` silently. This drops the PI id and `pm_` id and shows no message, while the hold may exist. The same silent reset happens if the user changes month between `beginPaidBooking` and the sheet completing (`completePaidBooking` guard).

The ledger key is also taken from the new `slot.startTime` on every re-run, so it can record the wrong slot.

The tests in `MakeABookingPaidFlowTests.swift` never change the selection between attempts, so none of this is covered.

**Fix:** Snapshot the attempt when it is created, and lock the inputs while the flow is active.
```swift
// In MakeABookingViewModel
struct PaidAttempt: Equatable {
    let topic: BookingTopic
    let slot: BookingTimeSlot
    let paymentIntentId: String
}
private(set) var paidAttempt: PaidAttempt?   // set in beginPaidBooking on success

func completePaidBooking(paymentMethodId: String) async {
    guard !isConfirmRunning else { return }
    guard let attempt = paidAttempt else { resetPaidFlow(); return }
    // use attempt.topic / attempt.slot / attempt.paymentIntentId everywhere below
}
```
Clear `paidAttempt` in `resetPaidFlow()`. In the view, add `.disabled(viewModel.isSubmitting)` to the topic picker, calendar card and slot chips. In `loadAvailability`, do not clear `selectedTimeSlot` while `paidStep != .idle`. Add a test: set an unknown outcome, change `selectedTimeSlot`, call `retryConfirm()`, and assert the request body still carries the original slot and topic.

---

### CR-02: D-12 sweep, "a transient Stripe error never cancels" is false end to end (deployed in ae3ec1a)

**File:** `ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js:312-338` (new block), against `:266-277` (`stampAttempt` runs first) and `src/cron/scaRecoveryWindowSweep.js:61-84,100-161`

**Issue:** The commit message, the code comment, the test titles and `docs/ios/STRIPE-INTEGRATION.md` all promise that a transient Stripe error during the platform-card check never cancels a booking. The check does not cancel in the same run. But `chargeOne` stamps `off_session_attempted_at` before the new `retrievePaymentMethod` call, and the sweep selects only rows with `off_session_attempted_at IS NULL`. On a transient error the code re-throws, the per-row catch logs it, and the row stays `payment_status='scheduled'` with the stamp set. It is never charged and never retried. `scaRecoveryWindowSweep` then selects it six hours later (`payment_status='scheduled'` and `off_session_attempted_at <= now-6h`). It has no `payment_intent_id`, so it falls through to `cancelOne`, which cancels the booking. The cancel releases the slot and sends a payment-failure notice to both parties.

So a Stripe or network blip during the T-24h run turns into a wrongful cancellation of a paid booking about six hours later. No charge was ever attempted, which is the outcome the change said it prevented. The change adds one more Stripe round trip per booking in front of the existing exposure, and the test `transient ... no cancel, no charge, the row is left scheduled` asserts only the first run and misses the follow-up.

**Fix:** Do the read-only platform-card check before `stampAttempt`, so a transient failure leaves the row unstamped and the next 5-minute sweep retries it:
```js
// chargeOne, before stampAttempt
let platformCardGone = false;
try {
  const card = await retrievePaymentMethod(booking.stripe_payment_method_id);
  platformCardGone = !card || !card.customer ||
    (platformCustomerId !== null && card.customer !== platformCustomerId);
} catch (e) {
  if (e && e.code === 'resource_missing') platformCardGone = true;
  else throw e; // not stamped, retried next run
}
if (platformCardGone) {
  const claimed = await stampAttempt(booking, nowIso);
  if (!claimed) return;
  await cancelAndRelease(booking, null);
  return;
}
// ...then stampAttempt + the existing charge path
```
This needs the `platformCustomerId` profile lookup moved before the stamp too. If you keep the current order instead, on a transient retrieve error reset the stamp with a guarded update (`off_session_attempted_at = null` where `payment_status='scheduled'`). Add a test that simulates two sweep runs after a transient error and asserts that the second run charges. Correct the docs and comments that overstate the guarantee.

## Warnings

### WR-01: SCA retry sends the connected-account clone's `pm_` id, and the original `pm_` is thrown away (needs device verification)

**File:** `Subviews/MakeABookingStripePaymentSheet.swift:213-219`, `MakeABookingViewModel.swift:609-616,792-795`

**Issue:** On `PAYMENT_REQUIRES_ACTION`, the serverCoded arm sets `confirmPaymentMethodId = nil` before `handlePaidFlowError`. After 3DS, `retryConfirmAfterSCA` uses `paymentIntent?.paymentMethodId` from the connected-account PaymentIntent returned by `handleNextAction`. That PI was confirmed with the connected-account clone, so the id is the clone's, not the platform `pm_` the user selected. `/bookings/confirm` (`booking.controller.js` around lines 902-903) calls `retrievePaymentMethod(stripe_payment_method_id)` against the platform account, unguarded. It would fail with `resource_missing` (a 5xx or `INVALID_PAYMENT_METHOD`) rather than recognising the already-authorised PI. If so, the user finishes 3DS and the booking still fails. The first confirm never reaches `requires_capture` for the booking to be created.

**Fix:** Keep the original platform `pm_` through the SCA round trip. Do not nil `confirmPaymentMethodId` when `code == .paymentRequiresAction`, and have `retryConfirmAfterSCA` ignore the SDK-returned id and use `confirmPaymentMethodId`. Confirm on a device with a 3DS-required test card.

### WR-02: A failed re-load replaces an already-loaded expert profile with the full-screen error

**File:** `Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift:108-114`, `ExpertProfileView.swift:301`

**Issue:** `.task { loadProfileDetails() }` re-runs every time the profile screen reappears. That includes coming back from Make a Booking, reviews, or a report sheet. On any thrown error, the catch sets `loadState = .failed(...)`, even when `loadState` was already `.loaded`. On a flaky connection, returning from the booking screen swaps a fully rendered profile for "Couldn't load profile", and the heart and menu are removed. D-10 is meant to stop a seeded profile posing as loaded, not to discard a good one.

**Fix:**
```swift
guard loadGate.isCurrent(token), !Self.isCancellation(error) else { return }
if case .loaded = loadState { return }          // keep the profile already on screen
loadState = Self.isNotFound(error) ? .notFound : .failed(error.userMessage)
```
A 404 on a re-load should still flip to `.notFound`.

### WR-03: Explore loads have no latest-wins gate, so a slow older response can overwrite a newer category filter

**File:** `Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:74-111,233-237`

**Issue:** `applySelectedCategories` fires `Task { await reload() }` for every change, and pull-to-refresh adds more concurrent `load()` calls. Each writes `categories`, `experts`, `featuredTopics`, the three states and `todaysSessions` after its `await` with no generation check. If the user taps category A and then B, and A's response lands last, the expert list shows A's results while the chip highlights B (`syncCategorySelection` runs from the current slugs). This is the same bug class fixed in Make a Booking with `ReloadGeneration` (BOOK-02), left unfixed here.

**Fix:** Reuse `ReloadGeneration`. Take a token at the top of `load()` and `guard gate.isCurrent(token)` after each `await` before writing.

### WR-04: Returning to Make a Booking re-runs `onAppear` and silently clears the chosen slot

**File:** `MakeABookingView.swift:133`, `MakeABookingViewModel.swift:287-292,343-346`

**Issue:** `.task { await viewModel.onAppear() }` restarts whenever the view reappears, for example after the user pushes Payment Methods to add a card and pops back. `loadAvailability` unconditionally sets `selectedTimeSlot = nil` and `availabilityState = .loading`. The user loses the slot they picked and sees the skeleton again. If the task was cancelled mid-flight when the screen was covered, the cancelled load returns without writing (the `isCancellation` guard), leaving `availabilityState == .loading` until the next appear.

**Fix:** Run the initial load once (`guard availabilityState == .idle` or a `hasLoaded` flag). Clear the slot only when the month actually changes (in `goToPreviousMonth`/`goToNextMonth`), not inside `loadAvailability`.

### WR-05: Favorites list races and stale state

**File:** `FavoritesViewModel.swift:140-163,204-233`, `FavoritesView.swift:71,89`

**Issue:**
- An unfavorite removes the row optimistically and then awaits the DELETE. A pull-to-refresh or stale-restart that started earlier and returns later replaces the whole list (`list.replace`) and brings the removed expert back, even though the DELETE then succeeds. The rollback `insert` has the same problem after a replace.
- Unfavoriting from the expert profile (opened from Favorites with `isFavorited: true`) changes the server state, but `.task { load() }` skips re-fetching when `state == .loaded`, and `onFavorite` is the default no-op. The removed expert stays in the list until a manual pull-to-refresh.

**Fix:** Keep a set of ids with an in-flight removal and filter them out of any refresh or page response. For the profile case, use the existing `onFavorite` hook to remove the row, or mark the list stale so the next appear refreshes.

## Info

### IN-01: Private `message(for:)` helpers duplicate `Error.userMessage`

**File:** `ExpertProfileViewModel.swift:299-306`, `BookingRequestSentViewModel.swift:166-173`
**Issue:** Project convention (CLAUDE.md) says never to write a new private `errorMessage(for:)` helper; use `Error.userMessage`. Both re-implement it.
**Fix:** Replace with `error.userMessage` and delete the helpers.

### IN-02: `PI_CURRENCY_MISMATCH` and `PAID_TOPIC_REQUIRES_PAYMENT` fall through to the default branch

**File:** `MakeABookingViewModel.swift:689-694,775-784`
**Issue:** The `ErrorCode` doc says `PI_CURRENCY_MISMATCH` means "discard the intent and restart", like `INTENT_EXPIRED`. The default branch resets the flow but keeps `bookingAttemptId`. The Stripe idempotency key is `booking:{attempt}:create_pi:{account}`, so the next attempt replays the stale intent and can only recover through a second failure (`BOOKING_ATTEMPT_CONFLICT`).
**Fix:** Add `.piCurrencyMismatch` to the `.intentExpired, .piContextMismatch, .piAmountMismatch` case.

### IN-03: Dead branch in `PaymentLifecycleCard.titleColor`

**File:** `Request Sent/Subviews/PaymentLifecycleCard.swift:173-175`
**Issue:** Both ternary arms return `Brand.onSurface`. `index <= currentStepIndex` has no effect.
**Fix:** Return `Brand.onSurface` directly or restore the intended muted colour for future steps.

### IN-04: Cancellation and default handling in `MakeABookingViewModel` loaders

**File:** `MakeABookingViewModel.swift:310-322,875-885`
**Issue:** `loadTopics` maps any thrown error, including a cancelled task, to `.failed(error.userMessage)`, unlike `loadAvailability`, which excludes cancellation. A topic with no `durationMins` is silently given 30 minutes, and that value is then sent as `durationMinutes` to `/bookings/payment-intent`.
**Fix:** Skip the `.failed` assignment on cancellation. Treat a missing duration as non-bookable instead of guessing.

### IN-05: The paid-flow alert binding ignores dismissal

**File:** `MakeABookingView.swift:279-284`
**Issue:** `paidFlowAlertBinding.set` is a no-op by design. SwiftUI sees `isPresented` still `true` after a button tap. "Try again" clears `paidFlowAlert` only inside a later `Task`, which risks a re-presentation flicker. If "Check My Bookings" ever leaves this screen on the stack, the flow stays `.confirming` and the Book button stays disabled until the alert is shown again.
**Fix:** Clear or transition `paidFlowAlert` synchronously in each button action, and bind with the standard setter.

### IN-06: D-12 backend operational notes

**File:** `webhooks.controller.js:386-399`, `docs/ios/STRIPE-INTEGRATION.md`
**Issue:** The eviction only runs if the production Stripe webhook endpoint is subscribed to `payment_method.detached` (a dashboard setting; nothing in the repo shows it). Without it, the sweep's platform-card check is the only protection, which is still sufficient. There is also no notice to the client when a card they removed is attached to a scheduled booking. They find out when it cancels at T-24h. The foreign-card check is skipped when the profile lookup fails (`platformCustomerId === null`). That is acceptable and tested, but note it.
**Fix:** Confirm the endpoint's event list in the Stripe dashboard and record it in the deployment notes. Consider a "your saved card was removed" push for scheduled bookings if product wants earlier warning.

---

_Reviewed: 2026-11-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
