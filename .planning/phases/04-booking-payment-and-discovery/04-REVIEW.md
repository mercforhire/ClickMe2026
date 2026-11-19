---
phase: 04-booking-payment-and-discovery
reviewed: 2026-11-19T00:00:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift
  - ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift
  - ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift
  - ClickMe2026Tests/Network/Discovery/ExploreFetchOrderingTests.swift
  - ClickMe2026Tests/Network/Discovery/FavoritesRemovalRaceTests.swift
  - ClickMe2026Tests/Support/HeldURLProtocol.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift
  - ClickMe2026/Utils/ConfirmOutcome.swift
  - ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift
  - ClickMe2026Tests/Support/MockURLProtocol.swift
findings:
  critical: 0
  warning: 3
  info: 13
  total: 16
status: issues_found
---

# Phase 04: Code Review Report (incremental re-review after fix commits f3bdb3f to f07660a)

**Reviewed:** 2026-11-19
**Depth:** standard
**Files Reviewed:** 21 (the 13 files in the delta, plus 8 files where carried-forward Info items live or that were read to trace a fix)
**Status:** issues_found (0 critical, 3 warnings, 13 info)

## Summary

This pass re-reviews `git diff 25ec5a6..HEAD` (six fix commits: CR-03, WR-08, WR-09, WR-10, WR-11, WR-12) and re-checks every open Info finding (IN-10 to IN-21) against the current source. New ids start at CR-04, WR-13 and IN-22. No id is reused.

**Verdict on the six fixes.** All six are correct for the cases they target. There is no new blocker.

- **CR-03 (fixed, still needs the device check).** I traced it end to end.
  - `completePaidBooking` keeps `confirmPaymentMethodId` only for `PAYMENT_REQUIRES_ACTION` (`MakeABookingViewModel.swift:650-652`). Every other server code still clears it.
  - `handlePaidFlowError` clears it through `resetPaidFlow()` on the no-detail path (`:711-712`), so a 402 without a `client_secret` cannot leave a card behind.
  - `retryConfirmAfterSCA()` resends the stored platform `pm_`. With no stored card it cancels and sends nothing.
  - The sheet no longer reads the SDK's PaymentIntent (`MakeABookingStripePaymentSheet.swift:206, 214-216`).
  - Backend: `docs/ios/STRIPE-INTEGRATION.md` §2.4 says to retry "with the same `booking_attempt_id` and the same `pm_`". `booking.controller.js:903` looks the id up on the platform account. On the retry the PI is `requires_capture`, so the handler takes the skip-confirm branch (`:931-933`) and inserts the booking. Android resends `pendingPaymentMethodId`. Retained state is cleared on success (`:638`), on cancel (`cancelSCA` → `resetPaidFlow`) and on every other code.
  - I found no path that leaves a stale card. Residual risk: a real 3DS card has not been run, and nothing in the app cancels a hold left by an earlier build or by a cancelled challenge.
- **WR-08 (fixed).** The generation token is applied at the three right places (response, catch, before Today's Sessions). The `restorable` mapping stops a dropped fetch from stranding a section on `.loading`. Residual: the `stateAfterCancelledFetch` doc comment and its `.loading` case are now stale (see IN-10).
- **WR-09 (fixed).** A failed re-load over `.loaded` keeps the profile, and a 404 still wins. I found no hole. A `.failed` first load still reaches `.failed`, so Retry remains.
- **WR-10 (fixed, with consequences).** `onAppear` no longer clears the slot or rotates the attempt id. The interaction with IN-17 is benign and in fact narrows IN-17. The same change removed the only automatic availability refresh, which exposes a gap that already existed (WR-14).
- **WR-11 (mostly fixed).** The removal filter is correct. The serial comparison `finishedAt >= serial` filters a request that started before the DELETE ended and spares one that started after. The rollback insert is clamped and de-duplicated in `PagedList.insert`. The revalidation hook has a timing hole (WR-13).
- **WR-12 (fixed).** `startChat()` surfaces the failure and skips cancellation. The "Couldn't start chat" key is not in `Localizable.xcstrings`, but every entry there is an empty or comment-only stub with source language `en`, so the literal renders. That is not a defect.

**New warnings.** WR-13: the Favorites revalidation hook can fire after the list has already reloaded, so the stale-list bug survives in a narrow window. WR-14: after `SLOT_UNAVAILABLE` the calendar is never reloaded, so the same taken slot stays tappable (Android reloads). WR-15: `HeldURLProtocol` keeps process-wide state that two separate suites reset.

### Carry-forward table (IN-10 to IN-21)

| Id | Status | Note |
|----|--------|------|
| IN-10 | Still present, body updated | Line numbers moved. WR-08 made the `.loading` case of `stateAfterCancelledFetch` dead and its doc comment more wrong. |
| IN-11 | Still present | `ExploreClientViewModel.swift:144-151` |
| IN-12 | Still present | `ExpertProfileViewModel.swift:303, 328`. WR-12's `startChat` uses `userMessage`, so one view model now uses both. |
| IN-13 | Still present | `MakeABookingViewModel.swift:721-726, 817` |
| IN-14 | Still present | `PaymentLifecycleCard.swift:173-175` |
| IN-15 | Still present | `MakeABookingViewModel.swift:336-338` and the three others. |
| IN-16 | Still present | `MakeABookingViewModel.swift:477-494, 541-584` |
| IN-17 | Still present, body updated | WR-10 narrowed its reachable paths. It becomes live again once WR-14 is fixed. |
| IN-18 | Still present | `MakeABookingViewModel.swift:853-857` |
| IN-19 | Still present | `ExpertProfileViewModel.swift` (the WR-09 edit did not touch it) |
| IN-20 | Still present | `MockURLProtocol.swift` is not in the delta. |
| IN-21 | Still present, body updated | `HeldURLProtocol` fixed the parked-thread pattern for the two new suites only. `ClientHomeFeedTests` still uses `serveHeld`. |

None was dropped. New: IN-22.

## Warnings

### WR-13: The Favorites revalidation flag can be set after the list has already reloaded, so the stale list returns in a narrow window

*New. Residual of WR-11.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift:205-209`, `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift:70-76`, `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift:93-107`

**Issue:** The heart button runs `await viewModel.toggleFavorite()` and only then `onFavorite()`, which sets `needsRevalidation`. The `Task` is not tied to the screen. A user who taps the heart and immediately taps Back (the PUT/DELETE takes a few hundred milliseconds on a mobile connection) pops the profile first. `FavoritesView`'s `.task { load() }` re-runs, sees the flag still false, and returns without a request. The toggle then finishes and sets the flag, but nothing runs `load()` again until the next appearance. The row for the expert just unfavorited stays in the list, which is the original WR-11 symptom.

A second route to the same result: `refresh()` clears the flag on any successful response (`:197`), including a pull-to-refresh that started before the toggle. The flag is set mid-flight and then wiped by the older response.

**Fix:** Make the list view model act when it is told, rather than wait for the next `.task`. It is owned by the view's `@StateObject`, so it is still alive while the profile is pushed or has just been popped.
```swift
// FavoritesViewModel
func noteProfileFavoriteChanged() {
    needsRevalidation = true
    Task { await refresh(quietly: true) }   // runs now; refresh() ignores a call while one is in flight
}
```
If `isRefreshing` is already true, record the request and re-run once the current refresh ends, so an older response cannot clear the flag. Add a test that calls `noteProfileFavoriteChanged()` while a refresh is held and releases the old response after it.

### WR-14: After `SLOT_UNAVAILABLE` the calendar is not reloaded, so the same taken slot stays tappable (Android reloads)

*New. WR-10 removed the only other automatic refresh.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:513-517` (free path), `:740-755` (paid path); Android `BookingErrors.kt:16, 35-39` and `MakeABookingViewModel.kt:599, 750`

**Issue:** Both `SLOT_UNAVAILABLE` branches set `selectedTimeSlot = nil` and show the error, and nothing refreshes `availabilityByDate`. The chip for the taken slot is still drawn as available. The user taps it again, gets the same error, and loops. Only a month change or leaving and re-entering the screen repairs it. Android documents this as D-09 / D-14: "drop the selected slot and reload availability". The iOS code carries the Android comment about dropping the slot but not the reload.

Before WR-10, returning from Payment Methods reloaded the calendar, which hid the gap in one common route. `loadAvailabilityIfNeeded` now skips a `.loaded` calendar, so a calendar left open for minutes is never refreshed. This is the consequence the fix report accepted. It was acceptable only if the slot-taken path refreshes, and it does not.

**Fix:** Reload after the clear, in both branches. In `handlePaidFlowError`, after `resetPaidFlow()` in the `.slotUnavailable` case, and in `performFreeBooking`'s catch:
```swift
availabilityTask?.cancel()
availabilityTask = Task { await loadAvailability(for: displayedMonth) }
```
Because `loadAvailability` no longer clears the slot, also reconcile after the load (see IN-17), so a held slot is not left selected. Add a test: 409 `SLOT_UNAVAILABLE`, then expect one more `/availability` request and `selectedTimeSlot == nil`.

### WR-15: `HeldURLProtocol` keeps process-wide state that two separate suites reset, and a cancelled held request stays queued

*New. Test reliability.*

**File:** `ClickMe2026Tests/Support/HeldURLProtocol.swift:21-23, 33-39, 52-70, 85`; users `ExploreFetchOrderingTests.swift:60`, `FavoritesRemovalRaceTests.swift:70`

**Issue:**
- `held`, `shouldHold` and `otherwise` are static. `configure` resets all three. `ExploreFetchOrderingTests` and `FavoritesRemovalRaceTests` are different top-level suites. `.serialized` orders tests inside one suite only, and Swift Testing runs different suites in parallel. Both suites wait with `await Task.sleep` polling, which is where the main actor interleaves. A `configure` from one suite then wipes the held requests and hold rule of the other, and `heldCount == n` waits time out. I could not make it fail here, so this is a structural hazard, not an observed flake. The existing `MockURLProtocol` suites have the same shape, which is probably why it has not shown.
- `stopLoading()` is empty. A request cancelled while held stays in `held`, so `heldCount` over-counts and `release(where:)` can pick the dead entry (the oldest match) instead of a live one. `finish` then calls the client after `stopLoading`.
- `release` calls `matches` while holding the lock. A matcher that reads `heldCount` would deadlock on the non-recursive `NSLock`. No current matcher does.

**Fix:** Put both suites under one parent so they cannot overlap, or give each `configure` call its own instance and session instead of statics.
```swift
@Suite("Held-response tests", .serialized)
struct HeldResponseTests {
    @Suite struct ExploreOrdering { ... }
    @Suite struct FavoritesRemovalRace { ... }
}
```
and
```swift
override func stopLoading() {
    Self.lock.withLock { Self.held.removeAll { $0 === self } }
}
```
Run `matches` outside the lock on a snapshot of `held`.

## Info

### IN-10: Explore's cancelled-fetch settle logic documents an invariant it does not hold, and is unreachable today

*Old WR-02, WR-03 and IN-02 (plan 04-17 review). Body updated after WR-08.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:96-156, 343-364`

**Issue:** `stateAfterCancelledFetch` restores a section from its pre-fetch state when a fetch ends in `URLError.cancelled` or `CancellationError`. Three problems:
- On the category-change path (`replacingLoadedContent: true`) the arrays still hold the previous filter's experts, so `before == .loaded` restores `.loaded` with the wrong filter's content and no Retry.
- The doc comment (`:352-353`) says "while a section is `.loading`, the fetch that set it is still in flight". WR-08 made this wrong in a new way: a superseded fetch is dropped by the generation guard and never settles anything, so a `.loading` section may belong to a fetch that has already returned. The `restorable` helper (`:102`) now maps `.loading` to `.idle` before capture, so the `case .loading: return .loading` arm of `stateAfterCancelledFetch` (`:361-362`) can no longer be reached.
- The six assign-if-changed blocks (`:110-115` and `:138-143`) repeat one pattern, and lines 138 to 142 run past 120 columns.

Nothing in `NetworkService` cancels a request, so no production path reaches the cancel branch. The logic is correct only because it is not exercised.

**Fix:** The generation token now answers the ownership question. Either delete the cancel branch and treat a cancelled fetch as the generic failure (it keeps a Retry), or keep it, delete the unreachable `.loading` arm and correct the invariant comment. If it stays, replace the six blocks with one helper that takes a key path, and pass `replacingLoadedContent` into the settle step so the category-change case settles to `.failed(interruptedLoadMessage)`.

### IN-11: A failed pull-to-refresh wipes the Explore content that was on screen

*Old IN-01 (plan 04-17 review).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:144-151`

**Issue:** A cancelled refresh keeps loaded sections, but a real failure during a refresh over loaded content, such as pulling to refresh while offline, sets all three sections to `.failed` and empties `featuredTopics`. The user loses categories and experts they were already looking at and has only a Retry card. WR-09 fixed the same class of problem on the profile screen, so Explore is now the odd one out.

**Fix:** When the fetch was a refresh (`!replacingLoadedContent`) and the section was `.loaded` before it, keep the content and report the error another way (a toast, using the shared `ToastCenter`). Keep the current behaviour for a first load and for a category change.

### IN-12: Two view models still carry a private copy of `Error.userMessage`

*Old IN-01 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift:303, 328`, `.../Request Sent/BookingRequestSentViewModel.swift:115, 166`

**Issue:** The project convention says never to write a private `message(for:)` helper and to use `Error.userMessage`. Both files re-implement it. They also differ from `userMessage`: the copy decodes with a plain `JSONDecoder` and falls back to `localizedDescription`, so a decoding or transport failure can show a raw system string in the favorite alert and on the Request Sent error card. `ExpertProfileViewModel` now uses both: `startChat()` (WR-12) and the details load use `userMessage`, while `toggleFavorite` still uses the private helper, so one screen words the same failure two ways.

**Fix:** Replace both call sites with `error.userMessage` and delete the helpers.

### IN-13: `PI_CURRENCY_MISMATCH` on confirm falls through to the default branch and keeps the stale attempt id

*Old IN-02 (e6c7488), narrowed.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:721-726, 817`, `ClickMe2026/Utils/ConfirmOutcome.swift:32-50`

**Issue:** `ErrorCode.piCurrencyMismatch` says "discard the intent and restart", like `INTENT_EXPIRED`. The server returns it as a 409 when the topic's currency changed after the PaymentIntent was created (`booking.controller.js:865-871`). `handlePaidFlowError` has no case for it, so the default branch resets the flow but keeps `bookingAttemptId`. The next Book Now sends the same idempotency key (`booking:{attempt}:create_pi:{account}`). Because the currency differs from the original request, Stripe answers with an idempotency conflict, which the app maps to `BOOKING_ATTEMPT_CONFLICT`. The user needs two failed attempts to recover.

**Fix:** Add `.piCurrencyMismatch` to the `.intentExpired, .piContextMismatch, .piAmountMismatch` case. Add it to `ConfirmOutcome.explicitlyMappedCodes` so the "explicitly mapped" list stays true to the switch. Same cleanup: `handlePaidFlowError` takes `topic` and discards it with `_ = topic; _ = slot` (line 817). Drop the unused parameter.

### IN-14: Dead branch in `PaymentLifecycleCard.titleColor`

*Old IN-03 (e6c7488).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift:173-175`

**Issue:** Both arms of the ternary return `Brand.onSurface`, so `index <= currentStepIndex` has no effect. The doc comment says later steps render muted.

**Fix:** Return `Brand.onSurface` directly, or restore the intended muted colour for steps after the current one.

### IN-15: A cancelled first load shows as a failure in four view models

*Old IN-04 (e6c7488), cancellation half.*

**File:** `MakeABookingViewModel.swift:336-338` (topics), `FavoritesViewModel.swift:126-128`, `ExpertReviewsViewModel.swift:123-125`, `BookingRequestSentViewModel.swift:114-116`

**Issue:** `loadAvailability` and `ExpertProfileViewModel` skip cancellation. These four loaders map any thrown error, including the `URLError.cancelled` caused by a view's `.task` being cancelled when the user leaves or switches tab, to `.failed(error.userMessage)`. The state recovers when the screen appears again and `.task` re-runs, but the failure card can flash, and on Request Sent it can show "Couldn't load your booking" over a booking that was just made. WR-10 makes the Make a Booking case a little more visible: `loadTopics` runs on every reappear, and a topics load cancelled by a push leaves `.failed` behind.

**Fix:** Add `guard !(error is CancellationError || (error as? URLError)?.code == .cancelled) else { state = <previous>; return }` to each catch. A shared `Error.isCancellation` helper would remove the copies of the check now spread across `ExploreClientViewModel`, `MakeABookingViewModel`, `ExpertProfileViewModel` and `FavoritesViewModel.refresh`.

### IN-16: The paid attempt's snapshot reads the form after two awaits, and its lock starts one turn late

*Old IN-07 (e6c7488).*

**File:** `MakeABookingViewModel.swift:477-494, 541-584, 229`

**Issue:**
- `book()` captures `topic` and `slot` as values but reads `meetingType` and `clientNotes` in `beginPaidBooking` (`:564-565`), after `createPaymentIntent` and `createPaymentMethodSetupIntent`. Today that is safe only because `paidStep = .creatingIntent` turns on the form lock, and that assignment runs inside the `Task`, not in `book()`.
- `book()` returns before `isSubmitting` is true (`isBooking` and `paidStep` are set inside the spawned `Task`). A second tap that is delivered before the `Task` body runs passes the `guard !isSubmitting` check. In practice the main actor usually runs the `Task` first, so this is a narrow window rather than a likely bug.
- `paidAttempt` is an unrestricted `var`. The doc comment promises "as they were when Book Now created the PaymentIntent", which the code does not enforce.

**Fix:** Read `meetingType` and the trimmed notes in `book()` and pass them to `beginPaidBooking` with `topic` and `slot`. Set `paidStep = .creatingIntent` (or `isBooking = true`) synchronously in `book()` before starting the `Task`. Make `paidAttempt` `private(set)` and give tests an `installPaidAttemptForTesting` method.

### IN-17: A slot kept across a reload can stay selected while the refreshed calendar shows it unavailable

*Old IN-08 (e6c7488). Body updated after WR-10.*

**File:** `MakeABookingViewModel.swift:306-309, 360-404`; `MakeABookingTimeSlotsCard.swift:141-145`

**Issue:** `loadAvailability` no longer clears `selectedTimeSlot` (WR-10), and nothing reconciles the slot with the new `availabilityByDate`. After a load the slot can be absent or `isAvailable == false` (a `held` slot, or one another client took) while `selectedTimeSlot` keeps its old copy. The summary still shows it and `canBook` stays true, while the chip is drawn unselected and disabled (the chip compares the whole `BookingTimeSlot`, so the stale copy no longer equals the refreshed one). `book()` rechecks only `isBookableStart`. The server and the ledger decide the result, so the outcome is a confusing round trip, not a wrong charge.

Effect of WR-10 on this finding: it narrowed it. `onAppear` now loads only from `.idle`, `.failed` or an interrupted `.loading`, states in which the slot is normally nil. A month change still clears the slot. The in-flight-attempt route (a reload while a paid attempt holds the slot) is blocked, because `onAppear` skips a `.loaded` calendar and the form is disabled while submitting. So the case is close to unreachable today. It becomes live again as soon as WR-14 adds a reload after `SLOT_UNAVAILABLE` or anything else reloads a loaded calendar, so the two should be fixed together.

**Fix:** After a successful load, if the selected slot is no longer present as available in `availabilityByDate` and no attempt is in flight, clear it (keep `isSubmitting` as the guard, since a paid attempt reads `paidAttempt`, not the selection). Alternatively, have `canBook` require `isSelectableSlot(selectedTimeSlot)`.

### IN-18: The calendar adds a stray filler row for months that end exactly on a Saturday

*New (earlier pass).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:853-857`

**Issue:** `trailing = (7 - total % 7) % 7` is 0 when the grid is already full. The loop `for i in 1 ... max(1, trailing)` then still appends one filler cell labelled "1". That cell starts a new row in the 7-column `LazyVGrid`, so months such as February 2026 and October 2026 show an extra row with a single greyed "1". `MakeABookingCalendarCellTests.fillersAreDatelessCells` describes this as "the extra trailing cell", so the tests treat it as intended. The `max(1, ...)` appears to be a guard against the invalid range `1...0`, not a design choice.

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

*New (earlier pass).*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift:103-135, 279-307`

**Issue:** `loadProfileDetails` skips the server's `is_favorite` only while `isFavoriteInFlight` is true. If the user taps the heart while the details request is still in flight, and the PUT or DELETE finishes before the details response arrives, the details value (read by the server before the toggle) then overwrites the heart with the old state. The server is now favorited and the heart shows empty. A second tap reconciles it, so the damage is a wrong icon, not lost data. The reappear re-load (WR-09 keeps it on screen when it fails, but a success still applies the server value) widens the window slightly.

**Fix:** Keep a `favoriteTouchedDuringLoad` flag. Set it in `toggleFavorite` and clear it when `loadProfileDetails` begins. Skip the server's value when it is set.

### IN-20: `MockURLProtocol` is only partly thread-safe

*Old IN-03 (plan 04-17 review).*

**File:** `ClickMe2026Tests/Support/MockURLProtocol.swift:17, 23-30, 52`

**Issue:** The request log is locked, but `handler` is a bare `nonisolated(unsafe) static var`. It is written on the main actor (`serve`, `reset`, and tests that assign it directly) and read on the URL loading thread. The `recordedRequests` setter makes a read-modify-write such as `recordedRequests.append(x)` non-atomic, which the doc comment denies. `stopLoading()` is empty, so a cancelled request still runs its handler to completion. `HeldURLProtocol` has the same empty `stopLoading` (WR-15).

**Fix:** Guard `handler` with the same lock. Take a snapshot under the lock in `startLoading` and call the snapshot outside the lock. Remove the `recordedRequests` setter and leave `reset()` as the only way to clear the log.

### IN-21: Async tests depend on a semaphore parked on the URL thread and on wall-clock polling

*Old IN-04 (plan 04-17 review) and old IN-09 (e6c7488). Body updated after `HeldURLProtocol`.*

**File:** `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift:107-129, 354, 384, 414, 441-458, 524-538`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift:1044-1054`

**Issue:**
- `HeldURLProtocol` removes the parked-thread pattern for the two new suites (`ExploreFetchOrderingTests`, `FavoritesRemovalRaceTests`). `ClientHomeFeedTests` still uses `serveHeld`, which parks the shared URL-protocol thread in `gate.wait(timeout: 10)`. If a test fails before its `defer { gate.signal() }` runs, any other `MockURLProtocol` request in the process stalls for up to 10 s. Two copies of the protocol now exist for the same job.
- The poll loops with 3 s to 5 s ceilings (20 ms steps in `ClientHomeFeedTests` and `PaidFlowTests`, 10 ms in the new suites) can flake on a loaded CI machine. The new suites add more of them (`waitUntil` in both new files, `settleAvailability` at `PaidFlowTests.swift:839`).
- `startSlowConfirm` relies on a real 500 ms retry delay (`:1046`), and a stall longer than that between the first request and the `#require` makes the retry fire first and fail without a product bug.
- `cancelledFirstLoadShowsFailure` ends with a weak `!contains("cancel")` check that the exact `genericError` equality above it already covers.
- `refreshKeepsLoadedSectionsVisible` does not assert that a refresh over loaded content publishes nothing, which its code comment claims.

**Fix:** Move the `serveHeld` tests onto `HeldURLProtocol` and delete the semaphore helper. Give `ConfirmRetryPolicy` a gate seam in place of a real delay for the confirm-race tests. Drop the redundant assertion, and count `objectWillChange` events in the refresh test.

### IN-22: The Message button has no in-flight guard, so a double tap opens the chat twice

*New.*

**File:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift:446-458`, `ExpertProfileViewModel.swift:312-323`

**Issue:** `handleMessage` starts a new `Task` per tap and `startChat()` has no in-flight flag. Two taps before the first response run two `POST /chats/initiate` calls (idempotent on the server) and call `openChatThread` twice, which can push the thread onto the navigation stack twice. On a slow connection the button also gives no sign that anything is happening, which is the same "nothing visible" complaint WR-12 set out to fix. The second tap also clears `messageError` while the first is still running. This predates WR-12 (the old code had the same shape), but WR-12 rewrote the handler without adding a guard.

**Fix:** Add `@Published private(set) var isStartingChat = false` to the view model. Return nil from `startChat()` when it is already true, and disable the Message button while it is set.

---

_Reviewed: 2026-11-19_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
