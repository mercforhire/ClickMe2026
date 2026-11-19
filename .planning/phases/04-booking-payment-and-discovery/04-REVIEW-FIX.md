---
phase: 04-booking-payment-and-discovery
fixed_at: 2026-11-19T01:10:00Z
review_path: .planning/phases/04-booking-payment-and-discovery/04-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 04: Code Review Fix Report

**Fixed at:** 2026-11-19
**Source review:** .planning/phases/04-booking-payment-and-discovery/04-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-03, WR-08, WR-09, WR-10, WR-11, WR-12)
- Fixed: 6
- Skipped: 0
- Out of scope (Info, not attempted): IN-10 to IN-21

All six cited locations were checked against the source at HEAD `e8b1b5c` before editing. Every finding was real. No backend change was needed and no Android file was touched. Work was done directly on `main`, with no worktree and no recovery sentinel. Only the files each fix needed were staged. The dirty files `.DS_Store`, `.planning/config.json`, `.planning/state.json` and `ClickMe2026/Localizable.xcstrings` were left alone.

## Fixed Issues

### CR-03: The 3DS retry sends the connected-account clone's `pm_` id, so a card that needs 3DS ends with a hold and no booking (needs device verification, touches payment state)

**Status:** fixed: requires human verification (device, 3DS test card)
**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift`, `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`
**Commit:** f3bdb3f
**Applied fix:**
- `completePaidBooking` no longer clears `confirmPaymentMethodId` on `PAYMENT_REQUIRES_ACTION`. Every other server code still clears it.
- `retryConfirmAfterSCA()` now takes no argument and resends the stored platform `pm_`. With no stored card it calls `cancelSCA` with the "couldn't be resolved" message and sends nothing.
- The sheet's `.succeeded` branch no longer reads `paymentIntent?.paymentMethodId`, which is the connected-account clone's id.
- This matches the backend contract: `docs/ios/STRIPE-INTEGRATION.md` §2.4 and `openapi/clickme-api.yaml` both say to retry "with the same `booking_attempt_id` and the same `pm_`". `booking.controller.js:903` looks the id up on the platform account. It also matches Android, which resends `pendingPaymentMethodId` (`MakeABookingViewModel.kt:545, 658`).
- `scaRetryKeepsOriginalSelection` asserted `"pm_after_sca"`. It now asserts the original `pm_test`, asserts the retry's id equals the first request's id, and checks that the card survives the 402.
- Added `scaRetryWithoutCardCancels`.
- **Confirmed failing on the old behaviour:** with the nil-ing restored, `scaRetryKeepsOriginalSelection` failed on three expectations (the card was nil, only 1 confirm request, no booking id). It passes with the fix.
- **Not verified:** a real 3DS card. Run a saved 3DS-required test card (for example 4000 0025 0000 3155) end to end. Confirm the second `/bookings/confirm` returns 201, and that Stripe shows one PaymentIntent in `requires_capture` linked to one booking. Also check what happens to a hold left by a build that still has the bug. Nothing in the app cancels it.

### WR-08: Overlapping `/client/home` fetches race, and the last response to land wins regardless of the filter

**Status:** fixed: requires human verification (race or state)
**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`, `ClickMe2026Tests/Network/Discovery/ExploreFetchOrderingTests.swift` (new)
**Commit:** 23c4d3a (the test file was later moved onto the shared `HeldURLProtocol` in 753da57)
**Applied fix:**
- Added `fetchGeneration`. Each `fetchHome` takes the next value. It drops its response, its failure and its Today's Sessions call when it is no longer the newest.
- One addition beyond the review: a fetch captures a section left `.loading` by an older fetch as `.idle`. A dropped older fetch never settles that section, so a cancelled newest fetch must not hand it back to one. Without this the section could stay on a skeleton with nothing loading.
- Tests hold two `/client/home` responses and release them in both orders, plus a refresh over a pending filter. The two ordering tests **fail on the old code** (2 experts shown under the filter, and the unfiltered response flipped the sections to `.loaded`). The third test is a regression guard and passes on both.
- Device check: tap a category chip while the Explore tab is still loading, and while a pull-to-refresh is running.

### WR-09: A failed re-load replaces an already-loaded expert profile with the full-screen error

**Status:** fixed
**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift`, `ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift`
**Commit:** aed0c22
**Applied fix:**
- When `loadState` is already `.loaded`, a failed re-load that is not a 404 now returns without changing it. A 404 still goes to `.notFound`. A failed first load still goes to `.failed`, so Retry remains.
- Tests: a 500 and an offline error keep `.loaded`, a 404 flips to `.notFound`, and a repeated failure after a failed first load stays `.failed`. The 500 and offline tests **fail on the old code**.

### WR-10: Returning to Make a Booking re-runs the load and silently clears the chosen slot (needs device verification)

**Status:** fixed: requires human verification (state, device)
**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift`
**Commit:** f6adf4a
**Applied fix:**
- `onAppear` calls `loadAvailabilityIfNeeded()`. A calendar that is already `.loaded` is left alone. An idle, failed or interrupted (`.loading` with nothing running) calendar still loads.
- `loadAvailability` no longer clears `selectedTimeSlot`. `goToPreviousMonth` and `goToNextMonth` clear it through `clearSelectedSlotForMonthChange()`. That keeps the `!isSubmitting` guard (CR-01), so a paid attempt in flight keeps its slot.
- The review said `idleReloadClearsSlot` would need to change. It is replaced by `idleReloadKeepsSlot`, `reappearKeepsSlot`, `reappearRetriesFailedCalendar`, `monthChangeClearsSlot` (both directions) and `monthChangeKeepsSlotDuringAttempt`.
- **Confirmed failing on the old code:** `idleReloadKeepsSlot`, `reappearKeepsSlot` (slot nil, attempt id rotated, 3 extra availability requests) and both `monthChangeClearsSlot` cases. `monthChangeKeepsSlotDuringAttempt` is a regression guard.
- Device check: the Add a Payment Method round trip, and a push to Payment Methods and back with a slot selected.
- Known consequence, as the review accepted: a reappear no longer refreshes a calendar that is already loaded, so slots taken meanwhile show only on the next month change or failed load. The server and the ledger still catch a taken slot at book time.

### WR-11: Favorites list goes stale after an unfavorite from the profile, and a refresh can undo an optimistic remove

**Status:** fixed: requires human verification (race or state)
**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift`, `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift`, `ClickMe2026Tests/Network/Discovery/FavoritesRemovalRaceTests.swift` (new), `ClickMe2026Tests/Support/HeldURLProtocol.swift` (new), `ClickMe2026Tests/Network/Discovery/ExploreFetchOrderingTests.swift`
**Commit:** 753da57
**Applied fix:**
- **Stale list.** The profile pushed from Favorites now passes `onFavorite`, which calls `noteProfileFavoriteChanged()`. When the list's `.task` runs again on pop, `load()` on a loaded list does a quiet `refresh(quietly: true)` only if that flag is set. The rows stay on screen and a failure raises no alert. The flag stays set after a failure, so the next `load()` retries. I used a flag instead of an unconditional refresh on every appear, because an unconditional refresh collapses a scrolled list back to page 1 on every return from a profile.
- **Race.** Instead of only the `pendingRemovals` set the review suggested, I added a per-request serial. A set alone covers only responses that land while the DELETE runs. A response requested before the DELETE ended can land after it and still carry the row. The view model now filters an expert from a list response if the DELETE is running, or if the DELETE finished after that request started. A request started after the DELETE ended is not filtered, so a re-favorited expert comes back. The rollback after a failed DELETE is unchanged.
- Added `HeldURLProtocol`, a shared test `URLProtocol` that parks requests without blocking the URL thread, which `MockURLProtocol` cannot do for two concurrent requests. `ExploreFetchOrderingTests` moved onto it.
- **Confirmed failing on the old code:** with the view model and view reverted, three race tests failed and the revalidation tests failed too (no revalidation existed). The revalidation tests call the new API, so they cannot compile against the old view model. I stubbed the call out to run them against old code.
- Device check: unfavorite from a profile opened from Favorites and pop back. The row should leave without a spinner or alert. Also unfavorite a row and pull to refresh at the same moment.

### WR-12: The Message button drops a failed chat start with no feedback

**Status:** fixed
**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift`, `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift`, `ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift`
**Commit:** f07660a
**Applied fix:**
- Added `@Published var messageError: String?` and `startChat() async -> UUID?`. It calls `initiateChat` through the injected `api` (it was `ClickMeAPI.shared`), sets `messageError` from `Error.userMessage`, and returns nil without a message for a cancelled task.
- `handleMessage` keeps its guards, awaits `startChat()` and opens the thread only on success. A second alert, "Couldn't start chat", sits beside the favorites alert.
- Tests cover success, a 500 with the server message, offline, cancellation, clearing an earlier error, and a profile with no id (no request). The original behaviour was an empty `catch`, so there is nothing to run against the old code. The tests call the new method.
- **Localization:** the alert title is a string-literal key, the same style as "Couldn't update favorites", which is in `Localizable.xcstrings`. I did not edit the catalog. "Couldn't start chat" is not in it yet, and Xcode did not add it during these builds. It needs adding (and translating, if the catalog carries other languages) when the catalog is next updated.

## Out of Scope

Not attempted, by the orchestrator's instruction (Info findings, `fix_scope` is `critical_warning`). They are not skipped:

- IN-10: Explore's cancelled-fetch settle logic documents an invariant it does not hold, and is unreachable today
- IN-11: A failed pull-to-refresh wipes the Explore content that was on screen
- IN-12: Two view models still carry a private copy of `Error.userMessage`
- IN-13: `PI_CURRENCY_MISMATCH` on confirm falls through to the default branch and keeps the stale attempt id
- IN-14: Dead branch in `PaymentLifecycleCard.titleColor`
- IN-15: A cancelled first load shows as a failure in four view models
- IN-16: The paid attempt's snapshot reads the form after two awaits, and its lock starts one turn late
- IN-17: A slot kept across a reload can stay selected while the refreshed calendar shows it unavailable
- IN-18: The calendar adds a stray filler row for months that end exactly on a Saturday
- IN-19: A late details response can flip the heart back after the user has toggled it
- IN-20: `MockURLProtocol` is only partly thread-safe
- IN-21: Async tests depend on a semaphore parked on the URL thread and on wall-clock polling

WR-08 touches the code IN-10 describes. Its generation token removes the ownership question, as IN-10 anticipated, but the cancel branch and the repeated assign-if-changed blocks were not cleaned up. WR-10 changes the area IN-17 describes: the slot is no longer cleared on a reload, so the stale-selection case can now happen after a reload that returns a held slot. IN-17 should be reviewed with that in mind.

## Cross-repo follow-ups (Android, not changed here)

iOS is the source of truth. Check these in `../ClickMe_Android`:

- **CR-03:** Android already resends `pendingPaymentMethodId`, so nothing to port. Worth a glance that its challenge `Completed` path never takes the id from the SDK's PaymentIntent.
- **WR-10:** Android's `onAppear`-equivalent and month navigation should be checked for the same clearing. Mirror iOS: load availability once, and clear the slot on a month change only.
- **WR-11:** Check Android's Favorites screen for the same stale list after a profile unfavorite, and for a refresh that undoes an optimistic remove.
- **WR-12:** Check that Android's Message button reports a failed chat start.
- **WR-08, WR-09:** Check Android Explore for overlapping home fetches, and the profile for a failed re-load replacing a loaded profile.

## Verification

All commands ran on the main checkout (`/Users/LeonChen/Documents/ClickMe2026`), not in a worktree, so the numbers can be reproduced from this tree. Destination: `platform=iOS Simulator,name=iPhone 17`. Everything used `MockURLProtocol` or `HeldURLProtocol`. No real network request was made and no Stripe call was possible.

- **Build:** `xcodebuild -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' clean build` returned BUILD SUCCEEDED. It printed 7 warnings (UserManager.swift:958, NetworkService.swift:168, ProfileAvatarSection.swift three times, FavoritesViewModel.swift:249 `withAnimation` result unused, MakeABookingStripePaymentSheet.swift:202 deprecated `handleNextAction`). None is on a line these fixes added. FavoritesViewModel.swift:249 and the deprecated call are in code that already existed (the same `withAnimation` call is at line 208 in `HEAD~7`). I did not build a baseline to compare warning counts, so "no new warnings" rests on that reading of the log.
- **Tests:** one run with `-only-testing` over 37 named suites (the runner reported 40 suites): the Booking and Discovery suites, the payment, booking and Make a Booking utility suites, and every suite added or touched here. The result was 449 tests in 40 suites passed, TEST SUCCEEDED. The run covered `MakeABookingPaidFlowTests`, `MakeABookingAvailabilityTests`, `MakeABookingCalendarCellTests`, `ExpertProfileViewModelTests`, `ClientHomeFeedTests`, `ExploreFetchOrderingTests`, `FavoritesViewModelPagingTests`, `FavoritesRemovalRaceTests`, `ExpertReviewsViewModelPagingTests`, `ConfirmOutcomeTests`, `PaymentSheetOutcomeTests`, `PaymentLifecycleVariantTests`, `UnconfirmedBookingLedgerTests`, `PagedListTests`, `HomeNavigationPathTests`, `ProfileBlockActionTests` and the rest of the Booking directory.
- **Old-code checks:** run per finding as described above, by temporarily restoring the old source with the new tests in place, then restoring the fix.
- **Not run:**
  - The full `ClickMe2026Tests` target, because it holds `AuthSmokeTests` and `SignupSmokeTests`, which are meant to hit the real backend.
  - Auth, Calls, Chat (except `ProfileBlockActionTests`), ExpertMode, Push, Settings and Signup suites.
  - UI tests.
  - Any device check. The device checks named under CR-03, WR-08, WR-10 and WR-11 are all still open.
- **Flakiness found and fixed in my own tests:** `monthChangeClearsSlot` first leaked an unstructured availability load into the next test's mock handler, which broke `scaRetryKeepsOriginalSelection` when run with the Availability suite. The tests now wait for the load to finish. Three consecutive runs of the three Make a Booking suites passed afterwards.

---

_Fixed: 2026-11-19_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
