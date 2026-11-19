---
phase: 04-booking-payment-and-discovery
fixed_at: 2026-11-19T16:44:24Z
review_path: .planning/phases/04-booking-payment-and-discovery/04-REVIEW.md
iteration: 1
findings_in_scope: 16
fixed: 16
skipped: 0
status: all_fixed
---

# Phase 04: Code Review Fix Report

**Fixed at:** 2026-11-19T16:44:24Z
**Source review:** .planning/phases/04-booking-payment-and-discovery/04-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 16 (WR-13, WR-14, WR-15, IN-10 to IN-22)
- Fixed: 16
- Skipped: 0

Two findings are fixed only in part, and the part left out is named under them: IN-10 (the category-change restore) and IN-21 (the remaining poll loops). Every finding's cited code was read in the current source before it was changed. All 16 were real. Three descriptions were slightly off, and the notes under IN-12, IN-15 and IN-20 say how.

All work is on `main` in `/Users/LeonChen/Documents/ClickMe2026`, one commit per finding (WR-14 and IN-17 share one, as the review recommends). There was no worktree. Only the files each fix touched were staged. `.DS_Store`, `.planning/config.json`, `.planning/state.json` and `ClickMe2026/Localizable.xcstrings` were left alone. No backend or Android file was edited.

## Fixed Issues

### WR-13: The Favorites revalidation flag can be set after the list has already reloaded, so the stale list returns in a narrow window

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift`, `ClickMe2026Tests/Network/Discovery/FavoritesRemovalRaceTests.swift`
**Commit:** 151d8ab
**Status:** fixed: requires human verification (race and state)
**Applied fix:** `noteProfileFavoriteChanged()` now starts a quiet refresh at once and returns the `Task` (`@discardableResult`, so the view's `onFavorite` closure is unchanged). A `revalidationEpoch` counter is bumped on each heart change. A page-1 response clears `needsRevalidation` only when the epoch has not moved since its request started, so an older pull-to-refresh cannot wipe the flag. `refresh()` is now a loop: if the epoch moved while it ran, it asks again, quietly, and a failure or cancellation does not loop. `forceLoad()` uses the same epoch rule. A failed quiet revalidation still leaves the flag set, so the next `load()` retries.
**Tests:** Three existing revalidation tests were rewritten, because the trigger moved from `load()` to the note. Two new tests cover the finding: a toggle that finishes after the list's `.task` already ran still revalidates, and a refresh started before the change cannot clear the flag. Both fail on the old behaviour (checked by removing the immediate refresh and by removing the re-run guard).
**Android:** Not inspected. If Android's favorites list has the same flag-on-next-appearance shape, it needs the same change.

### WR-14: After `SLOT_UNAVAILABLE` the calendar is not reloaded, so the same taken slot stays tappable (Android reloads)

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`, `ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift`
**Commit:** 68f9b82 (shared with IN-17)
**Status:** fixed: requires human verification (state)
**Applied fix:** Both `SLOT_UNAVAILABLE` branches (the free path's catch, and `handlePaidFlowError`, which serves the payment-intent and confirm phases) call `reloadAvailabilityAfterSlotTaken()`. It cancels the previous load and reloads the displayed month. `loadAvailability(for:keepVisible:)` is the iOS form of Android's `loadAvailability(keepVisible = true)`: the calendar stays on screen instead of dropping to the skeleton. Only `SLOT_UNAVAILABLE` reloads; a test confirms `INTENT_EXPIRED` does not. I read Android's `clearSlotAndReload` (`MakeABookingViewModel.kt:599, 750`, `PaidFlowError.kt`) before writing this. The reload runs in an unstructured `Task`, so `finishAvailabilityLoad()` was added as a test seam, and the existing slot-taken tests await it so no request outlives a test.
**Tests:** Free path, payment-intent and confirm each get one new test. They check that the center month and both neighbours are requested, the state is `.loaded`, and `.loading` is never published. These fail without the reload (checked).

### WR-15: `HeldURLProtocol` keeps process-wide state that two separate suites reset, and a cancelled held request stays queued

**Files modified:** `ClickMe2026Tests/Support/HeldURLProtocol.swift`, `ClickMe2026Tests/Network/Discovery/ExploreFetchOrderingTests.swift`, `ClickMe2026Tests/Network/Discovery/FavoritesRemovalRaceTests.swift`
**Files created:** `ClickMe2026Tests/Support/HeldURLProtocolTests.swift`
**Commit:** 6378953
**Applied fix:** A parent `@Suite("Held-response tests", .serialized) struct HeldResponseTests {}` is declared in `HeldURLProtocol.swift`, and every suite that uses the protocol is an `extension HeldResponseTests { @Suite ... }` member. The log confirms the Explore suite finishes before the Favorites suite starts. `stopLoading()` now removes the request from `held`. `release(where:)` runs the matcher on a snapshot outside the lock, then removes the chosen entry under the lock if it is still there. Two tests on the helper itself: a cancelled held request leaves the queue (fails without the `stopLoading` change, checked), and a matcher that reads `heldCount` does not deadlock.
**Note for later suites:** any new suite that uses `HeldURLProtocol` must be nested in `HeldResponseTests`. The IN-19, IN-21 and IN-22 suites below are.

### IN-10: Explore's cancelled-fetch settle logic documents an invariant it does not hold, and is unreachable today

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`, `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift`
**Commit:** 29e36e0
**Status:** fixed in part (cleanup only, no behaviour change, as instructed)
**Applied fix:** The `restorable` helper is gone and `stateAfterCancelledFetch` treats a `.loading` "before" like `.idle`, which is what `restorable` did, so behaviour is identical. The doc comment is rewritten around the generation guard. The six assign-if-changed blocks (two over 120 columns) became one `set(_:to:)` helper that keeps the publish-nothing-when-unchanged rule. The one test that pinned the old `.loading` arm now expects the failure with Retry.
**Not done, on purpose:** the first bullet of the finding (a cancelled fetch on the category-change path restores the old filter's content as `.loaded`). Nothing in `NetworkService` cancels a request, so no production path reaches it, and passing `replacingLoadedContent` into the settle step would change behaviour. It can be added later if a cancel source appears.

### IN-11: A failed pull-to-refresh wipes the Explore content that was on screen

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`, `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift`
**Commit:** d43ef08
**Status:** fixed: requires human verification (state)
**Applied fix:** `ExploreClientViewModel` takes `toasts: ToastCenter = .shared`. When a fetch fails over a section that was `.loaded` and the fetch was a refresh (`!replacingLoadedContent`), that section keeps its content and state, `featuredTopics` is not cleared, and the error is shown through `ToastCenter` (text is `error.userMessage`, with an SF Symbol). A first load, a Retry and a category change behave as before. The old test `failedReloadClearsFeaturedTopics` pinned the wiping behaviour and was replaced by three tests: the refresh keeps content and raises the toast (fails on the old code, checked), a failed first load shows failures with no toast, and a failed category change still replaces content.
**Android:** Not inspected. Check whether Android's Explore wipes its content on a failed refresh.

### IN-12: Two view models still carry a private copy of `Error.userMessage`

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift`, `ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift`
**Files created:** `ClickMe2026Tests/Booking/BookingRequestSentViewModelTests.swift`
**Commit:** 82e1fb9
**Applied fix:** Both call sites use `error.userMessage` and both private helpers are deleted. One correction to the finding: the copies were not different from `userMessage`. They decode with a plain `JSONDecoder` and fall back to `LocalizedError` then `localizedDescription`, which is exactly what `userMessage` does. So this is a pure de-duplication with no behaviour change, and it still removes the "one screen, two helpers" shape. Two tests pin the Request Sent failure text (server message, and generic text for an unreadable body), which had no tests.

### IN-13: `PI_CURRENCY_MISMATCH` on confirm falls through to the default branch and keeps the stale attempt id

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026/Utils/ConfirmOutcome.swift`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`, `ClickMe2026Tests/Utils/ConfirmOutcomeTests.swift`
**Commit:** 76c4fec
**Status:** fixed: needs device verification (payment)
**Backend check before deciding:** `booking.controller.js:865-871` returns 409 `PI_CURRENCY_MISMATCH` before any booking insert, so nothing is written. `docs/ios/STRIPE-INTEGRATION.md` (section 6 table, line 422), `docs/ios/USD-TOPIC-PRICING.md` (section 7) and `openapi/clickme-api.yaml` (the 409 description) all say "discard the PaymentIntent and restart from `POST /bookings/payment-intent`". `booking.controller.js:588-592` shows why the old attempt id is a trap: the idempotency key is `booking:{attempt}:create_pi:{account}`, and a changed currency on the same key becomes `BOOKING_ATTEMPT_CONFLICT`. The finding's reading was right.
**Applied fix:** `.piCurrencyMismatch` joins `.intentExpired, .piContextMismatch, .piAmountMismatch`: new attempt id, flow reset, server text shown, ledger record cleared (it is not a code that keeps one). `ConfirmOutcome.explicitlyMappedCodes` gains it, so a 5xx carrying it stays server-coded. The unused `topic` parameter of `handlePaidFlowError` is dropped (`slot` is used, so it stays). A parametrised test covers all four codes; the `PI_CURRENCY_MISMATCH` case fails without the fix (checked).
**Why the device flag:** this changes what a paid user sees after a topic-currency change, on real holds. The unit test cannot show that the next Book Now creates a clean PaymentIntent against the live backend. Suggested UAT: change a topic's currency after a PaymentIntent exists, then confirm, then tap Book Now again.
**Android follow-up:** Android has no `PI_CURRENCY_MISMATCH` handling at all (no match in `ClickMe_Android`), so it takes the default path. It needs the same case as `IntentExpired` in `PaidFlowError.kt`.

### IN-14: Dead branch in `PaymentLifecycleCard.titleColor`

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift`
**Commit:** d517bbc
**Applied fix:** `titleColor(index:)` is deleted and the title uses `Brand.onSurface` directly, with a one-line comment. The rendered colour is unchanged. I did not restore a muted colour for later steps, because the icon badge and connector already carry the progress and the finding offered both options.

### IN-15: A cancelled first load shows as a failure in four view models

**Files modified:** `ClickMe2026/Network/Error+UserMessage.swift`, `ClickMe2026/Model/UIModels/LoadState.swift`, `MakeABookingViewModel.swift`, `FavoritesViewModel.swift`, `ExpertReviewsViewModel.swift`, `BookingRequestSentViewModel.swift`, `ExploreClientViewModel.swift`, `ExpertProfileViewModel.swift` (the last two for the shared helper only)
**Files created:** `ClickMe2026Tests/Utils/LoadCancellationTests.swift`
**Commit:** 3f877d4
**Status:** fixed: requires human verification (state)
**Applied fix:** `Error.isCancellation` is the one shared check, and the copies in Explore, Make a Booking, Expert Profile and `FavoritesViewModel.refresh` now use it. `LoadState.afterCancelledLoad(previous:)` returns a section that is still `.loading` to what it showed before: `.idle` for a first load, the earlier failure for a retry. The four loaders capture `previous` before setting `.loading` and use it on a cancel. `.idle` and `.loading` render the same in all four views, and the screen's `.task` loads again on reappear. Tests cover the helper and each of the four loaders (first load, retry, and for topics a real failure still shows). With the cancel branch removed, every loader test fails (checked).
**Correction:** the finding says `BookingRequestSentViewModel` used `userMessage` in that catch. It used its private `message(for:)` until IN-12, which came first.

### IN-16: The paid attempt's snapshot reads the form after two awaits, and its lock starts one turn late

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`
**Commit:** 2d34dff
**Status:** fixed: requires human verification (race)
**Applied fix:** `book()` reads `meetingType` and the trimmed notes once and sets the lock synchronously (`isBooking = true` for a free topic, `paidStep = .creatingIntent` for a paid one) before it starts the `Task`. `performFreeBooking` and `beginPaidBooking` take the values as arguments and no longer set the lock themselves. `paidAttempt` is `private(set)`, with `installPaidAttemptForTesting(_:)` for the one test helper that wrote it. Three new tests: a second `book()` before the first task runs sends one PaymentIntent request (paid) and one booking request (free), and an edit made right after `book()` does not reach the attempt. All three fail without the change (checked).
**Android:** not inspected.

### IN-17: A slot kept across a reload can stay selected while the refreshed calendar shows it unavailable

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026Tests/Booking/MakeABookingAvailabilityTests.swift`
**Commit:** 68f9b82 (shared with WR-14)
**Status:** fixed: requires human verification (state)
**Applied fix:** After a successful load, `reconcileSelectedSlot()` drops the selected slot if the refreshed calendar lacks it or shows it unavailable, and replaces it with the refreshed copy if it is still offered (the chip compares the whole slot). It does nothing while `isSubmitting`, so a paid attempt keeps its slot (CR-01), and it does not run after a failed load. Five tests: still offered stays and keeps the attempt id, held drops, absent drops, a failed reload keeps, and an attempt in flight keeps. The two drop tests fail without the call (checked).

### IN-18: The calendar adds a stray filler row for months that end exactly on a Saturday

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026Tests/Booking/MakeABookingCalendarCellTests.swift`
**Commit:** a7deee0
**Applied fix:** Trailing fillers are added only when `trailing > 0`. The test comment that called the extra cell intended is corrected, and a new test checks `days.count % 7 == 0` and the row count for Feb, Oct, Nov and May 2026 (4, 5, 5 and 6 rows). It fails on the old code (checked). Android's `BookingCalendar.kt` already pads to whole weeks, so Android needs no change.

### IN-19: A late details response can flip the heart back after the user has toggled it

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift`
**Files created:** `ClickMe2026Tests/Network/Discovery/ExpertProfileHeartRaceTests.swift`
**Commit:** 7f6622f
**Status:** fixed: requires human verification (race)
**Applied fix:** `favoriteTouchedDuringLoad` is set in `toggleFavorite()` and cleared when `loadProfileDetails()` begins, except when a toggle is still running at that moment (its effect is not in what the server reads for the new load). The server's `is_favorite` is skipped while the flag is set. Four tests on `HeldURLProtocol`: a finished toggle survives a late details response, a toggle running when the details start survives, a load that starts after the toggle applies the server value, and a load with no toggle applies it. The first two fail on the old code (checked).

### IN-20: `MockURLProtocol` is only partly thread-safe

**Files modified:** `ClickMe2026Tests/Support/MockURLProtocol.swift`, `ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift`, `ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift`
**Commit:** 8336bba
**Applied fix:** `handler` is a computed property over storage behind the same lock as the request log. `startLoading` takes a snapshot of the handler under the lock and calls it outside. `recordedRequests` is read-only. `reset()` clears both. Three tests used `recordedRequests = []` to stop counting their setup requests while keeping the handler, so they call a new atomic `clearRecordedRequests()` instead. That is a small departure from "reset() is the only way to clear", because `reset()` would remove the handler those tests need.
**Not changed, with the reason:** `stopLoading()` stays empty. The finding says a cancelled request still runs its handler to completion, but the handler runs synchronously inside `startLoading`, so there is no window in which a request is waiting to be cancelled. I did not add a test for the lock itself, because a test that calls `reset()` would race the other suites that share the global handler.
**Verification:** the 46 suites that use `MockURLProtocol` ran together (588 tests) and passed.

### IN-21: Async tests depend on a semaphore parked on the URL thread and on wall-clock polling

**Files modified:** `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`, `ClickMe2026/Utils/ConfirmRetryPolicy.swift`
**Commit:** f4b089b
**Status:** fixed in part (smallest safe change, as allowed)
**Applied fix:**
- The four tests that used `serveHeld` (refresh survives caller cancellation, the same after a failure, loaded sections stay visible, category change shows skeletons) moved to a suite nested under `HeldResponseTests`, on `HeldURLProtocol`. `serveHeld`, `homeRequestCount` and `homeRequestArrived` are deleted, so the parked-thread semaphore is gone.
- `ConfirmRetryPolicy` has a `wait: (Duration) async -> Void` property. It defaults to `Task.sleep`, so production behaviour is the same. The two confirm-race tests wait on a gate they open instead of a real 500 ms retry delay, and the first-failure wait uses `waitUntil`.
- The redundant `!contains("cancel")` assertion is dropped.
- The refresh test now counts `objectWillChange` events and expects none while a refresh over loaded content is in flight. It fails if the `set(_:to:)` guard is removed (checked), which is what its comment claimed.
**Not done:** the remaining 20 ms poll loops with 3 s to 5 s ceilings in `PaidFlowTests` and the older suites (`bookAndWaitForOutcome`, `settleAvailability`, the book-then-poll loops). The tests I added or rewrote use `waitUntil`, which fails at the call site on a timeout. Replacing every loop is a wider rewrite than this finding needs.

### IN-22: The Message button has no in-flight guard, so a double tap opens the chat twice

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift`, `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift`, `ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileActionButtons.swift`, `ClickMe2026Tests/Network/Discovery/ExpertProfileHeartRaceTests.swift`
**Commit:** a74892c
**Status:** fixed: requires human verification (race, and a visual change)
**Applied fix:** `@Published private(set) var isStartingChat`. `startChat()` returns nil without a request while it is set, and clears it with a `defer` on success, failure and cancellation. `ExpertProfileActionButtons` takes `isMessageBusy`: the Message button is disabled and shows a `ProgressView` in place of its icon. Three tests: a second call during the request makes no request and returns nil, the flag clears after a failure, and a second tap does not clear an error shown meanwhile. The first fails on the old code (checked).

## Skipped Issues

None.

## Verification

All of this ran in the main checkout, not a worktree, because the instruction was to commit directly on `main`. Nothing reached the real network. Every request in the tests went through `MockURLProtocol` or `HeldURLProtocol`.

**Build** (`xcodebuild -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' clean build`, after the last commit): `** BUILD SUCCEEDED **` with exactly the 7 known warnings and nothing else besides the AppIntents metadata notice:
- `UserManager.swift:958` (`describe`)
- `NetworkService.swift:168` (await without async)
- `FavoritesViewModel.swift:282` (`withAnimation` unused result, the `guard let expertId` branch of `removeFavorite`)
- `MakeABookingStripePaymentSheet.swift:202` (deprecated `handleNextAction`)
- `ProfileAvatarSection.swift:64`, `:66`, `:69`

No new warnings, in the app or the test target.

**Tests** (after the last commit): `xcodebuild ... test` with 93 explicit `-only-testing:ClickMe2026Tests/<Suite>` arguments: all Booking, Payment, Discovery, Confirm and Ledger suites, every suite that uses `MockURLProtocol`, every suite I added or touched, and the `HeldResponseTests` parent with its nested suites. Result: `Test run with 1077 tests in 101 suites passed`, `** TEST SUCCEEDED **`. Earlier per-commit runs of the touched suites also passed.

**New suites:** `HeldResponseTests` (parent, in `HeldURLProtocol.swift`), `HeldURLProtocolTests`, `ExpertProfileHeartRaceTests` (heart suite plus the `ExpertProfileMessageTests` suite for IN-22, both in `ExpertProfileHeartRaceTests.swift`), `ExploreHeldRefreshTests` (in `ClientHomeFeedTests.swift`), `BookingRequestSentViewModelTests`, `LoadCancellationTests`.

**Tests shown to fail on the old behaviour:** I reverted the relevant production lines one fix at a time, ran the new tests, saw them fail, and restored the file. Done for WR-13 (two mutations), WR-14, WR-15, IN-11, IN-13, IN-15, IN-16, IN-17, IN-18, IN-19, IN-21 (the publish count) and IN-22. Not done for IN-10, IN-12, IN-14 and IN-20, which are behaviour-preserving, so no test is expected to fail. The restores are confirmed by `git status`: every commit contains only the intended change.

**Not run:**
- The full `ClickMe2026Tests` target, `AuthSmokeTests` and `SignupSmokeTests` (they hit production), and the UI tests.
- Any device or simulator run of the app screens. The visual changes (Message spinner, Explore refresh toast, calendar rows, slot reload after a taken slot) are not looked at on a screen.
- One thing that stays unverified: the race fixes pass on the simulator test runner, but real timing on a device (WR-13, IN-16, IN-19, IN-22) is a human check.

## New user-visible strings

None. The Explore refresh toast reuses `Error.userMessage` (the server message, or the app's generic "Something went wrong. Please try again."). The Message button spinner has no text. No change was made to `Localizable.xcstrings`.

## Cross-repo follow-ups

Nothing in the backend needed changing; nothing was edited there or in Android.

**Android should mirror:**
- IN-13: add `PI_CURRENCY_MISMATCH` to the "PaymentIntent unusable" group (new attempt id, reset). It has no handling today.
- Check, not yet inspected: IN-11 (does a failed Explore refresh wipe content), IN-15 (cancelled load shown as failure), IN-19 (a late details response flipping the heart), IN-22 (double tap on Message), WR-13 (favorites list refresh after a heart change on the profile), IN-16 (double tap on Book Now).

**Android already matches, no change:** WR-14 (`clearSlotAndReload`), IN-17 (reconcile of a restored or held slot), IN-18 (calendar pads to whole weeks).

## Suggested device checks (UAT)

- Payment: IN-13 above. Also repeat the existing 3DS check from CR-03, since `book()` and the paid flow were touched (IN-16).
- Book a slot another client took, for both a free and a paid topic: the error shows, the slot is cleared, and the calendar redraws without the chip (WR-14, IN-17).
- Tap Book Now twice quickly on a paid and a free topic: one request, one booking (IN-16).
- Open a month that ends on a Saturday (October 2026) and check the calendar has no extra row (IN-18).
- Favorites: open a profile from the list, tap the heart, go back at once; the row follows the heart (WR-13).
- Explore: turn on airplane mode and pull to refresh; content stays and a toast shows (IN-11).
- Profile: tap Message twice quickly on a slow connection; one thread opens, the button shows a spinner (IN-22).

---

_Fixed: 2026-11-19T16:44:24Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
