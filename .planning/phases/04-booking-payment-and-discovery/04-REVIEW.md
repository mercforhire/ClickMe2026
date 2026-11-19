---
phase: 04-booking-payment-and-discovery
reviewed: 2026-11-19T00:00:00Z
depth: standard
files_reviewed: 63
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
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesProTipCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
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
  - ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift
  - ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift
  - ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift
  - ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift
  - ClickMe2026Tests/Support/MockURLProtocol.swift
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
findings:
  critical: 1
  warning: 5
  info: 12
  total: 18
status: issues_found
---

# Phase 04: Code Review Report (full re-review, fresh numbering)

**Reviewed:** 2026-11-19
**Depth:** standard
**Files Reviewed:** 63 (all iOS)
**Status:** issues_found (1 critical, 5 warnings, 12 info)

## Summary

This is a full re-review of the 63 Phase 4 iOS files against the current code (HEAD `c86dc57`). It replaces the incremental plan 04-17 review. Finding ids in this report are new and start at CR-03, WR-08 and IN-10. No id in this report was used by an earlier review, so the disposition record cannot collide with an older decision.

Backend facts were checked in `../ClickMe2026 Backend` (`src/controllers/booking.controller.js`, `src/utils/errors.js`, `src/services/stripe.js`) and against the Android port (`PaidFlowStripeHost.kt`, `MakeABookingViewModel.kt`).

**Skipped on purpose:** CR-01 and CR-02 (fixed), WR-06 and WR-07 (deferred backend items the user accepted). Old IN-06 (backend operational notes) is backend-only and is not in this file set, so it was not re-checked.

**The one blocker:** the 3DS retry after `PAYMENT_REQUIRES_ACTION` sends the connected-account clone's `pm_` id. The backend looks it up on the platform account and fails. A card that needs 3DS ends with a held PaymentIntent and no booking (CR-03). This was a warning in the earlier review. It is raised to critical because the backend and Android evidence is now concrete.

### Status of every earlier finding

Format: old id (review) → status → new id.

**Full review at e6c7488**

| Old id | Status | Evidence / new id |
|--------|--------|-------------------|
| WR-01 SCA retry sends the clone's `pm_` id | **Still present** | `MakeABookingViewModel.swift:628` nils `confirmPaymentMethodId`. `MakeABookingStripePaymentSheet.swift:215-219` passes `paymentIntent?.paymentMethodId`. The test at `MakeABookingPaidFlowTests.swift:830-840` still asserts `"pm_after_sca"`. → **CR-03** |
| WR-02 A failed re-load replaces the loaded profile with the full-screen error | **Still present** | `ExpertProfileViewModel.swift:110-113` sets `.failed` with no check of the current state. `ExpertProfileView.swift:313` re-runs the load on every appear. → **WR-09** |
| WR-03 Explore has no latest-wins gate | **Still present** | `ExploreClientViewModel.swift:81-142, 264-270` has no generation token. The 04-17 shield made it slightly worse (see WR-08). → **WR-08** |
| WR-04 Make a Booking `onAppear` clears the chosen slot | **Still present for the idle case** | `MakeABookingViewModel.swift:355` clears the slot whenever `!isSubmitting`. `idleReloadClearsSlot` (`PaidFlowTests.swift:802`) encodes it. The in-flight-attempt half is fixed (the `isSubmitting` guard). → **WR-10** |
| WR-05 Favorites races | **Still present** | `FavoritesViewModel.swift:140-163, 204-234`. `FavoritesView.swift:70-72, 89` has no refresh when the profile pops back. → **WR-11** |
| IN-01 Private `message(for:)` helpers | **Still present** | `ExpertProfileViewModel.swift:299-306`, `BookingRequestSentViewModel.swift:166-173`. → **IN-12** |
| IN-02 `PI_CURRENCY_MISMATCH` and `PAID_TOPIC_REQUIRES_PAYMENT` fall through | **Still present for `PI_CURRENCY_MISMATCH`; no longer applicable for `PAID_TOPIC_REQUIRES_PAYMENT`.** The latter is only returned by `/bookings/request` (`booking.controller.js:1637`), which is the free flow and does not go through `handlePaidFlowError`. | → **IN-13** |
| IN-03 Dead branch in `PaymentLifecycleCard.titleColor` | **Still present** (`PaymentLifecycleCard.swift:173-175`) | → **IN-14** |
| IN-04 Loader cancellation and the 30-minute default | **Cancellation half still present. Default half no longer applicable:** the server falls back to 30 for a null `duration_mins` everywhere (`booking.controller.js:462, 801, 1242, 1675`), so the client's 30 matches. | → **IN-15** |
| IN-05 Paid-flow alert binding ignores dismissal | **No longer applicable in practice.** "Check My Bookings" now runs `HomeShellExit.plan(.viewMyBookings)`, which resets the source tab's stack (`HomeClientView.swift:99-101`). That destroys the view model, so the frozen-form scenario cannot occur. Not carried forward. | none |
| IN-06 D-12 backend notes | Backend only, not in this file set. Not re-checked. | none |
| IN-07 Snapshot reads `meetingType` and `clientNotes` after the network calls | **Still present** (`MakeABookingViewModel.swift:541-548`, `:459-476`) | → **IN-16** |
| IN-08 A kept slot can be selected while the refreshed calendar shows it unavailable | **Still present** (`:350-355, 892`) | → **IN-17** |
| IN-09 Wall-clock timing in the confirm-race tests | **Still present** (`PaidFlowTests.swift:914-945`) | → **IN-21** |

**Incremental review of plan 04-17 (Explore)**

| Old id | Status | New id |
|--------|--------|--------|
| WR-01 Overlapping `/client/home` fetches race | **Still present** | → **WR-08** (merged with the e6c7488 WR-03) |
| WR-02 A cancelled category-change fetch restores `.loaded` with the old filter's experts | **Still present in code, downgraded.** Only `URLError.cancelled` reaches it, and nothing in `NetworkService` cancels a request now. | → **IN-10** |
| WR-03 The "`.loading` means its fetch is in flight" invariant does not hold | **Still present in code, downgraded** for the same reason | → **IN-10** |
| IN-01 A failed refresh wipes loaded content | **Still present** (`ExploreClientViewModel.swift:131-138`) | → **IN-11** |
| IN-02 Triplicated section-state code | **Still present** (`:93-105, 125-130`) | → **IN-10** |
| IN-03 `MockURLProtocol` only partly thread-safe | **Still present** (`MockURLProtocol.swift:17, 25-28`) | → **IN-20** |
| IN-04 Held-response tests block the URL protocol thread | **Still present** (`ClientHomeFeedTests.swift:104-129`) | → **IN-21** |

**New in this pass:** WR-12 (the Message button drops a failure silently), IN-18 (the calendar adds a stray filler row), IN-19 (a late details response can flip the heart back).

## Critical Issues

### CR-03: The 3DS retry sends the connected-account clone's `pm_` id, so a card that needs 3DS ends with a hold and no booking (needs device verification, touches payment state)

*Old WR-01 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:622-629` (line 628), `.../Subviews/MakeABookingStripePaymentSheet.swift:212-219`, `.../MakeABookingViewModel+PaidFlow.swift:99-102`; test `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift:815-842`

**Issue:** `completePaidBooking` handles a `PAYMENT_REQUIRES_ACTION` answer in the `.serverCoded` arm. The arm sets `confirmPaymentMethodId = nil` (line 628) before `handlePaidFlowError`, so the platform `pm_` the user chose is dropped. After 3DS, the sheet reads `paymentIntent?.paymentMethodId` from the connected-account PaymentIntent that `handleNextAction` returns and passes it to `retryConfirmAfterSCA`. That PaymentIntent was confirmed with the clone (`confirmPI(payment_intent_id, clonedPmId, connectAccountId)`, `booking.controller.js:958-962`). The id it returns is the clone's id, not the platform `pm_`.

Server-side consequence, traced:
1. The retry reaches `POST /bookings/confirm`.
2. The handler calls `retrievePaymentMethod(stripe_payment_method_id)` on the platform account (`booking.controller.js:903`). That call is not wrapped in a try/catch.
3. Stripe answers with a `StripeInvalidRequestError` (`resource_missing`).
4. `errorHandler` maps any un-mapped Stripe error to `502 PAYMENT_PROVIDER_ERROR` (`src/utils/errors.js:213-227`).
5. The app has no mapping for that code. `ConfirmOutcome.classify` sees a 5xx with an unmapped code and returns `.outcomeUnknown`.

Concrete failure with a 3DS-required card (for example test card 4000 0025 0000 3155 saved on the account):
1. The user taps Book Now and confirms in the sheet. The server answers 402 `PAYMENT_REQUIRES_ACTION`.
2. The user completes 3DS. The connected-account PaymentIntent is now `requires_capture`, so a real hold exists.
3. The retry fails as above. The app retries two more times (2 s, 4 s). Then it raises "We couldn't confirm your booking. Your request may already have been sent."
4. No booking row exists. The hold stays on the card until Stripe expires it.
5. "Try again" repeats the same failing call, because `confirmPaymentMethodId` was nil'd and `retryConfirm` has nothing to resend.

Android keeps the original id. `MakeABookingViewModel.kt:658-663` re-confirms with `pendingPaymentMethodId`. The `scaRetryKeepsOriginalSelection` test asserts `stripe_payment_method_id == "pm_after_sca"`, which locks the wrong behaviour in. I could not run a 3DS card here, so this needs a device check (see Fix).

**Fix:** Keep the platform `pm_` through the challenge and ignore the SDK's id.
```swift
// MakeABookingViewModel.swift, completePaidBooking, .serverCoded arm
case let .serverCoded(error):
    if !UnconfirmedBookingLedger.keepsRecord(afterServerCode: BookingErrorMapper.code(for: error)) {
        ledger.clear(expertId: expertId, start: attempt.slot.startTime)
    }
    // The 3DS retry needs the card the user chose; every other code ends the attempt.
    if BookingErrorMapper.code(for: error) != .paymentRequiresAction {
        confirmPaymentMethodId = nil
    }
    handlePaidFlowError(error, phase: .confirm, topic: attempt.topic, slot: attempt.slot)

// MakeABookingViewModel+PaidFlow.swift
func retryConfirmAfterSCA() async {
    pendingSCAChallenge = nil
    guard let paymentMethodId = confirmPaymentMethodId else {
        cancelSCA(withMessage: "Payment method couldn't be resolved after verification.")
        return
    }
    await completePaidBooking(paymentMethodId: paymentMethodId)
}

// MakeABookingStripePaymentSheet.swift, runSCA .succeeded
case .succeeded:
    Task { await viewModel.retryConfirmAfterSCA() }
```
`handlePaidFlowError` already calls `resetPaidFlow()` on the no-detail path, which clears the card. Change the test to expect the original `pm_test`.

Device check before shipping: run a saved 3DS-required test card end to end. Confirm that the second `/bookings/confirm` returns 201, and that the Stripe dashboard shows one PaymentIntent in `requires_capture` linked to one booking. Also check what happens to a hold left by a build that still has this bug (nothing in the app cancels it).

## Warnings

### WR-08: Overlapping `/client/home` fetches race, and the last response to land wins regardless of the filter

*Old WR-03 (e6c7488) and WR-01 (plan 04-17 review).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:81-142, 226-230, 264-270`

**Issue:** `load()` runs `fetchHome` in an uncancellable `Task`, and `applySelectedCategories` starts another unstructured `Task`. Nothing orders them. Each fetch reads `selectedCategorySlugs` when it starts and writes `categories`, `experts` and `featuredTopics` when it ends.

Concrete failure that needs no unusual timing:
1. The user returns to the Explore tab. The `.task { load() }` fetch starts with no filter. Sections are already `.loaded`, so the chips stay tappable.
2. Before it lands, the user taps the "Technology" chip. A second fetch starts with `category=technology`. Both sections go to `.loading` (skeletons).
3. The filtered response lands first and the sections show technology experts.
4. The slower, unfiltered response lands second and overwrites `experts` and `categories`.
5. `syncCategorySelection()` re-marks "Technology" as selected, so the chip is highlighted while the list shows every expert. There is no way to tell from the screen that the filter is not applied.

Pull-to-refresh followed by a chip tap produces the same result. Before plan 04-17, a re-fired `.task` or a new refresh cancelled the older request, which bounded this. The shield removed that.

**Fix:** Give each fetch a generation and apply a response only if it is still the newest. Bump the generation in `applySelectedCategories`.
```swift
private var fetchGeneration = 0

private func fetchHome(replacingLoadedContent: Bool) async {
    fetchGeneration += 1
    let generation = fetchGeneration
    // ... begin(...) as today ...
    do {
        let response = try await api.getClientHome(categorySlugs: ...)
        guard generation == fetchGeneration else { return }   // a newer fetch owns the screen
        // ... assign sections ...
    } catch {
        guard generation == fetchGeneration else { return }
        // ... existing cancel / failure handling ...
    }
    guard generation == fetchGeneration else { return }
    await loadTodaysSessions()
}
```
A dropped response must leave section state to the newer fetch, which already set `.loading` or will set `.loaded`. Add a test that holds two responses and releases them out of order (a filtered one first, an unfiltered one second) and asserts that the filtered data stays.

### WR-09: A failed re-load replaces an already-loaded expert profile with the full-screen error

*Old WR-02 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift:108-114`, `ExpertProfileView.swift:313`

**Issue:** `.task { await viewModel.loadProfileDetails() }` runs again every time the profile screen reappears: coming back from Make a Booking, from the reviews list, or from a Report sheet. On any thrown error the catch sets `loadState = .failed(...)`, even when `loadState` is already `.loaded`. `showsProfileActions` turns false, so the heart and the menu disappear too.

Concrete failure: a user opens a profile, taps Book Session, goes through the booking flow on a patchy connection and returns. A single dropped request swaps a fully drawn profile for "Couldn't load profile" and removes Book, Message, the heart and the Report/Block menu. The user must tap Retry. D-10 was meant to stop a seeded profile posing as loaded, not to discard a good one. No test covers a failed second load.

**Fix:**
```swift
guard loadGate.isCurrent(token), !Self.isCancellation(error) else { return }
if case .loaded = loadState, !Self.isNotFound(error) { return }   // keep the profile on screen
loadState = Self.isNotFound(error) ? .notFound : .failed(error.userMessage)
```
A 404 on a re-load should still flip to `.notFound`, because the account is gone. Add a test: load, then fail the second load with a 500, then expect `.loaded`.

### WR-10: Returning to Make a Booking re-runs the load and silently clears the chosen slot (needs device verification)

*Old WR-04 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:294-299, 350-355`, `MakeABookingView.swift:143`; test `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift:802-813`

**Issue:** `.task { await viewModel.onAppear() }` restarts every time the screen reappears. `onAppear` always calls `loadAvailability`, which sets `availabilityState = .loading` and, when `!isSubmitting`, `selectedTimeSlot = nil`. The slot setter also calls `newBookingAttempt()`, so the idempotency seed changes too.

Concrete failure on the "Add a Payment Method" path:
1. A user with no saved card picks a paid topic and a slot. The button reads "Add a Payment Method" and `canBook` is true.
2. They tap it, add a card on the Payment Methods screen and pop back.
3. The slots card flips to a skeleton and the chosen slot is gone. They must pick the slot again.

The same thing happens after any push and pop of this screen. A load cancelled when the screen is covered also returns early (the cancellation guard at line 362) and leaves `availabilityState == .loading` until the next appear. The 04-15 fix protects only an attempt in flight. `idleReloadClearsSlot` documents the idle behaviour as intended, so that test will need to change.

**Fix:** Load once, and clear the slot only when the month changes.
```swift
func onAppear() async {
    async let t: Void = loadTopics()
    async let a: Void = loadAvailabilityIfNeeded()
    async let p: Void = loadPaymentMethods()
    _ = await (t, a, p)
}

private func loadAvailabilityIfNeeded() async {
    if case .loaded = availabilityState { return }       // idle, loading (a cancelled load) and failed still load
    await loadAvailability(for: displayedMonth)
}
// loadAvailability: drop the `if !isSubmitting { selectedTimeSlot = nil }` line.
// goToPreviousMonth / goToNextMonth: set `selectedTimeSlot = nil` there (guarded by !isSubmitting, which the disabled calendar already ensures).
```
Moving the clear also makes the `isSubmitting` guard unnecessary. Device check: the Add a Payment Method round trip, and a push to the Payment Methods screen and back with a slot selected.

### WR-11: Favorites list goes stale after an unfavorite from the profile, and a refresh can undo an optimistic remove

*Old WR-05 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift:71-74, 140-163, 204-234`, `FavoritesView.swift:70-72, 89`

**Issue:** Two separate problems.
- **Stale list (deterministic).** `FavoritesView` pushes `ExpertProfileView(expert:..., isFavorited: true)` with no `onFavorite` hook. The user unfavorites from the profile (the server state changes) and pops back. The `.task { load() }` re-runs, but `load()` returns early when `state == .loaded`. The expert stays in the list until a manual pull-to-refresh. Tapping the row again shows an empty heart, which contradicts the list.
- **Refresh overwrites an optimistic remove.** `removeFavorite` drops the row and then awaits the DELETE. A `refresh()` that started earlier (a pull, or the automatic restart after a previous removal marks the list stale) can land afterwards. `list.replace` then re-installs the removed expert even though the DELETE succeeds. The rollback `insert` after a failed DELETE has the same ordering problem.

**Fix:**
- For the stale list, revalidate on return without a spinner or alert: make the `.task` call `refresh()` when the state is already `.loaded`, or wire `onFavorite` to a view-model method that removes the row. If `refresh()` is reused, give it a quiet mode that does not set `apiError`.
- For the race, keep `private var pendingRemovals: Set<UUID>` in the view model. Insert the id before the DELETE and remove it when the DELETE ends. Filter that set out of every `list.replace` and `list.append` input, so a response that predates the DELETE cannot bring the row back.

### WR-12: The Message button drops a failed chat start with no feedback

*New.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift:437-459` (catch at 451-457)

**Issue:** `handleMessage` calls `initiateChat` inside a `Task` and has an empty `catch` with a TODO. On any failure (offline, 5xx, a blocked or suspended counterpart returning a coded error) the tap does nothing. The user sees no change and no message, and cannot tell whether to retry. The project's stated goal is that users are not left with "silently dropped actions". The profile already has an error-alert path for favorites, but its title is fixed to "Couldn't update favorites", so it cannot be reused as it is.

**Fix:** Add a `@Published var messageError: String?` to `ExpertProfileViewModel`, move the `initiateChat` call into a `startChat()` method that sets it from `error.userMessage` (and skips `CancellationError`), and attach a second alert titled "Couldn't start chat" to the view. Keep `isSameAsCurrentUser` and the `expertId` guards where they are.

## Info

### IN-10: Explore's cancelled-fetch settle logic documents an invariant it does not hold, and is unreachable today

*Old WR-02, WR-03 and IN-02 (plan 04-17 review).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:91-142, 329-350`

**Issue:** `stateAfterCancelledFetch` restores a section from its pre-fetch state when a fetch ends in `URLError.cancelled` or `CancellationError`. Two problems:
- On the category-change path (`replacingLoadedContent: true`) the arrays still hold the previous filter's experts, so `before == .loaded` restores `.loaded` with the wrong filter's content and no Retry.
- The doc comment says "while a section is `.loading`, the fetch that set it is still in flight". That does not hold when a refresh over loaded content (which never sets `.loading`) is followed by a category change.

I downgraded both from warnings. After the 04-17 shield nothing in `NetworkService` cancels a request, so no production path reaches this branch. The logic is correct only because it is never exercised. The six assign-if-changed blocks (lines 93-105 and 125-130) repeat one pattern, and lines 125-129 run past 120 columns.

**Fix:** The WR-08 generation token removes the ownership question. After that, either delete the cancel branch and treat a cancelled fetch as the generic failure (it keeps a Retry), or keep it with the invariant comment corrected. If it stays, replace the six blocks with one helper that takes a key path, and pass `replacingLoadedContent` into the settle step so that the category-change case settles to `.failed(interruptedLoadMessage)`.

### IN-11: A failed pull-to-refresh wipes the Explore content that was on screen

*Old IN-01 (plan 04-17 review).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:131-138`

**Issue:** A cancelled refresh keeps loaded sections (04-17), but a real failure during a refresh over loaded content, such as pulling to refresh while offline, sets all three sections to `.failed` and empties `featuredTopics`. The user loses categories and experts they were already looking at and has only a Retry card. This sits beside new code that treats loaded content as worth keeping, and it is the same class as WR-09.

**Fix:** When the fetch was a refresh (`!replacingLoadedContent`) and the section was `.loaded` before it, keep the content and report the error another way (a toast, using the shared `ToastCenter`). Keep the current behaviour for a first load and for a category change.

### IN-12: Two view models still carry a private copy of `Error.userMessage`

*Old IN-01 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift:299-306`, `.../Request Sent/BookingRequestSentViewModel.swift:166-173`

**Issue:** The project convention says never to write a private `message(for:)` helper and to use `Error.userMessage`. Both files re-implement it. They also differ from `userMessage`: the copy decodes with a plain `JSONDecoder` and falls back to `localizedDescription`, so a decoding or transport failure can show a raw system string in the favorite alert and on the Request Sent error card.

**Fix:** Replace both call sites with `error.userMessage` and delete the helpers.

### IN-13: `PI_CURRENCY_MISMATCH` on confirm falls through to the default branch and keeps the stale attempt id

*Old IN-02 (e6c7488), narrowed.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:697-702`, `ClickMe2026/Utils/ConfirmOutcome.swift:32-50`

**Issue:** `ErrorCode.piCurrencyMismatch` says "discard the intent and restart", like `INTENT_EXPIRED`. The server returns it as a 409 when the topic's currency changed after the PaymentIntent was created (`booking.controller.js:865-871`). `handlePaidFlowError` has no case for it, so the default branch resets the flow but keeps `bookingAttemptId`. The next Book Now sends the same idempotency key (`booking:{attempt}:create_pi:{account}`). Because the currency differs from the original request, Stripe answers with an idempotency conflict, which the app maps to `BOOKING_ATTEMPT_CONFLICT`. The user needs two failed attempts to recover.

**Fix:** Add `.piCurrencyMismatch` to the `.intentExpired, .piContextMismatch, .piAmountMismatch` case. Add it to `ConfirmOutcome.explicitlyMappedCodes` so the "explicitly mapped" list stays true to the switch. Same cleanup: `handlePaidFlowError` takes `topic` and discards it with `_ = topic; _ = slot` (line 793). Drop the unused parameter.

### IN-14: Dead branch in `PaymentLifecycleCard.titleColor`

*Old IN-03 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift:173-175`

**Issue:** Both arms of the ternary return `Brand.onSurface`, so `index <= currentStepIndex` has no effect. The doc comment says later steps render muted.

**Fix:** Return `Brand.onSurface` directly, or restore the intended muted colour for steps after the current one.

### IN-15: A cancelled first load shows as a failure in four view models

*Old IN-04 (e6c7488), cancellation half.*

**File:** `MakeABookingViewModel.swift:326-328` (topics), `FavoritesViewModel.swift:91-93`, `ExpertReviewsViewModel.swift:123-125`, `BookingRequestSentViewModel.swift:114-116`

**Issue:** `loadAvailability` and `ExpertProfileViewModel` skip cancellation. These four loaders map any thrown error, including the `URLError.cancelled` caused by a view's `.task` being cancelled when the user leaves or switches tab, to `.failed(error.userMessage)`. The state recovers when the screen appears again and `.task` re-runs, but the failure card can flash, and on Request Sent it can show "Couldn't load your booking" over a booking that was just made.

**Fix:** Add `guard !(error is CancellationError || (error as? URLError)?.code == .cancelled) else { state = <previous>; return }` to each catch. A shared `Error.isCancellation` helper would remove the five copies of the check now spread across these files.

### IN-16: The paid attempt's snapshot reads the form after two awaits, and its lock starts one turn late

*Old IN-07 (e6c7488).*

**File:** `MakeABookingViewModel.swift:459-476, 523-548, 166`

**Issue:**
- `book()` captures `topic` and `slot` as values but reads `meetingType` and `clientNotes` in `beginPaidBooking`, after `createPaymentIntent` and `createPaymentMethodSetupIntent`. Today that is safe only because `paidStep = .creatingIntent` turns on the form lock, and that assignment runs inside the `Task`, not in `book()`.
- `book()` returns before `isSubmitting` is true (`isBooking` and `paidStep` are set inside the spawned `Task`). A second tap that is delivered before the `Task` body runs passes the `guard !isSubmitting` check. In practice the main actor usually runs the `Task` first, so this is a narrow window rather than a likely bug.
- `paidAttempt` is an unrestricted `var`. The doc comment promises "as they were when Book Now created the PaymentIntent", which the code does not enforce.

**Fix:** Read `meetingType` and the trimmed notes in `book()` and pass them to `beginPaidBooking` with `topic` and `slot`. Set `paidStep = .creatingIntent` (or `isBooking = true`) synchronously in `book()` before starting the `Task`. Make `paidAttempt` `private(set)` and give tests an `installPaidAttemptForTesting` method.

### IN-17: A slot kept across a reload can stay selected while the refreshed calendar shows it unavailable

*Old IN-08 (e6c7488).*

**File:** `MakeABookingViewModel.swift:350-355, 392-394, 892`; `MakeABookingTimeSlotsCard.swift:141-145`

**Issue:** While a paid attempt is in flight, the PaymentIntent holds the slot, so a reload returns it as `held` and `isAvailable == false`. The load writes the new `availabilityByDate` but nothing reconciles `selectedTimeSlot`, which keeps `isAvailable == true`. After "Not now" or any reset the summary still shows the slot and `canBook` stays true, while the chip is drawn unselected and disabled (the chip compares the whole `BookingTimeSlot`, so the stale copy no longer equals the refreshed one). `book()` rechecks only `isBookableStart`. The server and the ledger handle the result, so the outcome is a confusing round trip, not a wrong charge.

**Fix:** After a successful load, if the selected slot is no longer present as available in `availabilityByDate` and no attempt is in flight, clear it. Alternatively, have `canBook` require `isSelectableSlot(selectedTimeSlot)`.

### IN-18: The calendar adds a stray filler row for months that end exactly on a Saturday

*New.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:842-846`

**Issue:** `trailing = (7 - total % 7) % 7` is 0 when the grid is already full. The loop `for i in 1 ... max(1, trailing)` then still appends one filler cell labelled "1". That cell starts a new row in the 7-column `LazyVGrid`, so months such as February 2026 and October 2026 show a sixth or fifth row with a single greyed "1". `MakeABookingCalendarCellTests.fillersAreDatelessCells` describes this as "the extra trailing cell", so the tests treat it as intended. The `max(1, ...)` appears to be a guard against the invalid range `1...0`, not a design choice.

**Fix:**
```swift
if trailing > 0 {
    for i in 1 ... trailing {
        days.append(CalendarDay(label: "\(i)", date: nil, isCurrentMonth: false))
    }
}
```
Update the test comment, and add an assertion that `days.count % 7 == 0`.

### IN-19: A late details response can flip the heart back after the user has toggled it

*New.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift:102-123, 265-295`

**Issue:** `loadProfileDetails` skips the server's `is_favorite` only while `isFavoriteInFlight` is true. If the user taps the heart while the details request is still in flight, and the PUT or DELETE finishes before the details response arrives, the details value (read by the server before the toggle) then overwrites the heart with the old state. The server is now favorited and the heart shows empty. A second tap reconciles it, so the damage is a wrong icon, not lost data.

**Fix:** Keep a `favoriteTouchedDuringLoad` flag. Set it in `toggleFavorite` and clear it when `loadProfileDetails` begins. Skip the server's value when it is set.

### IN-20: `MockURLProtocol` is only partly thread-safe

*Old IN-03 (plan 04-17 review).*

**File:** `ClickMe2026Tests/Support/MockURLProtocol.swift:17, 25-28, 41-46`

**Issue:** The request log is locked, but `handler` is a bare `nonisolated(unsafe) static var`. It is written on the main actor (`serve`, `serveHeld`, `reset`) and read on the URL loading thread. The `recordedRequests` setter makes a read-modify-write such as `recordedRequests.append(x)` non-atomic, which the doc comment denies. `stopLoading()` is empty, so a cancelled request still runs its handler to completion.

**Fix:** Guard `handler` with the same lock. Take a snapshot under the lock in `startLoading` and call the snapshot outside the lock. Remove the `recordedRequests` setter and leave `reset()` as the only way to clear the log.

### IN-21: Async tests depend on a semaphore parked on the URL thread and on wall-clock polling

*Old IN-04 (plan 04-17 review) and old IN-09 (e6c7488).*

**File:** `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift:104-129, 343-470, 523-538`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift:914-945`

**Issue:**
- `serveHeld` parks the shared URL-protocol thread in `gate.wait(timeout: 10)`. If a test fails before its `defer { gate.signal() }` runs, any other mocked request in the process stalls for up to 10 s.
- The 20 ms poll loops with 5 s or 3 s ceilings can flake on a loaded CI machine.
- `startSlowConfirm` relies on a real 500 ms retry delay, and a stall longer than that between the first request and the `#require` makes the retry fire first and fail without a product bug.
- `cancelledFirstLoadShowsFailure` ends with a weak `!contains("cancel")` check that the exact `genericError` equality above it already covers.
- `refreshKeepsLoadedSectionsVisible` does not assert that a refresh over loaded content publishes nothing, which its code comment claims.

**Fix:** Hold a response with a continuation or an `AsyncStream` in the mock instead of a semaphore. Give `ConfirmRetryPolicy` a gate seam in place of a real delay for the confirm-race tests. Drop the redundant assertion, and count `objectWillChange` events in the refresh test. Add tests for overlapping fetches (WR-08) and a failed second profile load (WR-09).

---

_Reviewed: 2026-11-19_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
