---
phase: 04-booking-payment-and-discovery
reviewed: 2026-11-12T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
  - ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift
  - "ClickMe2026 Backend D12: src/cron/longLeadChargeSweep.js"
  - "ClickMe2026 Backend D12: tests/cron/longLeadChargeSweep.test.js"
findings:
  critical: 0
  warning: 7
  info: 9
  total: 16
status: issues_found
---

# Phase 4: Code Review Report (incremental re-review after gap plans 04-15 and 04-16)

**Reviewed:** 2026-11-12
**Depth:** standard
**Files Reviewed:** 7 (5 iOS, 2 backend). The prior full-phase pass covered 65 files (59 iOS, 6 backend D-12); this pass re-reviews only the files the gap plans touched.
**Diff ranges:** iOS `f5610ff..HEAD` (commits `6184f6c`, `50f55de`, `2baa72d`); backend `ae3ec1a..28da165` (branch `ios-p4-d12`).
**Status:** issues_found (0 critical, 7 warnings, 9 info)

## Summary

Both prior blockers are resolved in code. CR-01 (a confirm retry re-reading live form state) is fixed by a `PaidAttempt` snapshot that every confirm, the ledger key and the error handling now read, plus a view-level lock on the input cards. CR-02 (a transient card-check error stamping the row and being cancelled six hours later) is fixed for the card check by moving the read-only profiles lookup and the platform-card check ahead of `stampAttempt`.

No new blocker was found. The remaining risk is what the fixes deliberately left open:

- The "a transient Stripe error never cancels" guarantee still does not hold after the stamp (WR-06). This is tracked in an iOS-repo todo and the code comments say so, but the exposure is real.
- The pre-stamp retry has no deadline (WR-07). The user accepted this before the push, but it can end with a delivered session that is never charged.
- The existing 3DS-retry test now encodes the behaviour suspected in WR-01.
- The form lock widens the impact of IN-05.

Carried-forward findings keep their original IDs. WR-01, WR-04 and IN-05 sit on code this diff touched, so they are re-assessed below. The remaining carried items are reproduced verbatim from the prior pass, and their line numbers refer to that pass.

## Resolution of prior Critical issues

### CR-01: RESOLVED (iOS, plans 04-15)

**Evidence in the code:**
- `MakeABookingViewModel+PaidAttempt.swift:23-29` defines `PaidAttempt` (topic, slot, PaymentIntent id, meeting type, notes).
- `beginPaidBooking` builds it at `MakeABookingViewModel.swift:541-548`, only after both API calls succeed.
- `completePaidBooking` (`:581-637`) guards only on `paidAttempt` (`:585`). It sends `attempt.paymentIntentId`, `attempt.topic.id`, `attempt.slot.startTime`, `attempt.meetingType` and `attempt.clientNotes`. The ledger `record`, `clear`, the `keepsRecord` check and the `handlePaidFlowError` arguments all use `attempt.slot` (`:596,619,626,629`).
- Try again (`PaidFlow.swift:58-65`) and the 3DS retry (`PaidFlow.swift:99-102`) both go through `completePaidBooking`, so they inherit the snapshot.
- `loadAvailability` no longer clears the slot while `isSubmitting` (`:353-355`). That removes the silent `resetPaidFlow()` that used to drop the PaymentIntent and `pm_` ids, and the `newBookingAttempt()` side effect of the `didSet`.
- `MakeABookingView.swift:65-83` adds `.disabled(viewModel.isSubmitting)` to the topic picker, calendar, slots, meeting type and notes cards.
- `resetPaidFlow()` clears `paidAttempt` (`:645`). A running confirm holds `attempt` as a local, so a reset mid-run cannot change what it sends.
- Tests: `bookCreatesPaidAttempt`, `retryKeepsOriginalSelection`, `scaRetryKeepsOriginalSelection`, `formEditWhileConfirmRunsKeepsRequest`, `ledgerKeysOnPaidAttempt`, `reloadDuringConfirmKeepsSlot`, `idleReloadClearsSlot`, `confirmWithoutAttemptMakesNoRequest`, `everyResetUnlocksTheForm` and `secondConfirmWhileRunningIsRejected` cover the original scenarios. The view-level `.disabled` is not unit-tested; the summary routes it to the D-11 device step.

Residual edges found while verifying are filed as IN-07 and IN-08. Neither reopens CR-01.

### CR-02: RESOLVED for the platform-card check (backend `28da165`); the broader promise is still open as WR-06

**Evidence in the code (`src/cron/longLeadChargeSweep.js`):**
- The profiles select (`:301-305`) and `retrievePaymentMethod` (`:327`) now run before `stampAttempt` (`:342`).
- A profiles read error is re-thrown (`:311`). A non-`resource_missing` retrieve error is re-thrown (`:335`). Both leave `off_session_attempted_at` NULL.
- The candidate query selects `off_session_attempted_at IS NULL` (`:127`), so the next 5-minute run retries the row.
- `scaRecoveryWindowSweep` selects on `off_session_attempted_at <= now - 6h`, which a NULL stamp cannot satisfy, so it never sees the row. This is Postgres NULL semantics. The test models it with `modelWindowSqlFilter` and does not prove it against a database, as the plan summary states.
- The gone-card cancel now runs only after the claim (`:342-350`), so concurrent runs cannot both cancel. The `lost claim` test covers this.
- The null-customer fallback is removed. `platformCard.customer !== platformCustomerId` is now true when the profile has no customer id (`:330`). This matches the ownership rule in `booking.controller.js:1291-1301` (`!stripeCustomerId` is refused at insert).
- Tests: the two-run transient test, the profiles-error table (attached, foreign, detached), the call-order tests and the lost-claim test cover the reorder.

**What CR-02 does not cover:** errors after the stamp. They are filed as WR-06, because the prior CR-02 title ("a transient Stripe error never cancels is false end to end") still describes that path.

## Warnings

### WR-01: SCA retry sends the connected-account clone's `pm_` id, and the original `pm_` is thrown away (needs device verification)

**Status: re-assessed. The code is unchanged and the issue is still open. One new aggravating fact: the test suite now locks the behaviour in.**

**File:** `Subviews/MakeABookingStripePaymentSheet.swift:212-219`, `MakeABookingViewModel.swift:622-629` (the `serverCoded` arm sets `confirmPaymentMethodId = nil`, line 628), `MakeABookingViewModel+PaidFlow.swift:99-102` (`retryConfirmAfterSCA` was moved here unchanged).

**Issue:** On `PAYMENT_REQUIRES_ACTION`, the serverCoded arm sets `confirmPaymentMethodId = nil` before `handlePaidFlowError`. After 3DS, the sheet passes `paymentIntent?.paymentMethodId` from the connected-account PaymentIntent returned by `handleNextAction` to `retryConfirmAfterSCA`. That PI was confirmed with the connected-account clone, so the id is the clone's, not the platform `pm_` the user selected. `/bookings/confirm` (`booking.controller.js` around lines 902-903) calls `retrievePaymentMethod(stripe_payment_method_id)` against the platform account, unguarded. It would fail with `resource_missing` rather than recognising the already-authorised PI, so the user finishes 3DS and the booking still fails.

New in this diff: `scaRetryKeepsOriginalSelection` (`MakeABookingPaidFlowTests.swift:815-842`) asserts `stripe_payment_method_id == "pm_after_sca"`, i.e. it asserts the SDK-supplied id is forwarded. If the fix below is applied, that expectation must change. A reader may take it as evidence that forwarding the SDK id is intended.

**Fix:** Keep the original platform `pm_` through the SCA round trip. Do not nil `confirmPaymentMethodId` when `code == .paymentRequiresAction`, and have `retryConfirmAfterSCA` ignore the SDK-returned id and use `confirmPaymentMethodId`. Update the test to expect the original `pm_test`. Confirm on a device with a 3DS-required test card.

### WR-02: A failed re-load replaces an already-loaded expert profile with the full-screen error

*Carried forward (not re-reviewed).*

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

*Carried forward (not re-reviewed).*

**File:** `Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:74-111,233-237`

**Issue:** `applySelectedCategories` fires `Task { await reload() }` for every change, and pull-to-refresh adds more concurrent `load()` calls. Each writes `categories`, `experts`, `featuredTopics`, the three states and `todaysSessions` after its `await` with no generation check. If the user taps category A and then B, and A's response lands last, the expert list shows A's results while the chip highlights B (`syncCategorySelection` runs from the current slugs). This is the same bug class fixed in Make a Booking with `ReloadGeneration` (BOOK-02), left unfixed here.

**Fix:** Reuse `ReloadGeneration`. Take a token at the top of `load()` and `guard gate.isCurrent(token)` after each `await` before writing.

### WR-04: Returning to Make a Booking re-runs `onAppear` and silently clears the chosen slot

**Status: re-assessed. Partly changed by plan 04-15. Still open for the idle case.**

**File:** `MakeABookingView.swift:143` (the `.task`; it was line 133), `MakeABookingViewModel.swift:294-299,350-355`

**Issue (original):** `.task { await viewModel.onAppear() }` restarts whenever the view reappears, for example after the user pushes Payment Methods to add a card and pops back. `loadAvailability` unconditionally set `selectedTimeSlot = nil` and `availabilityState = .loading`. The user lost the slot they picked and saw the skeleton again. If the task was cancelled mid-flight when the screen was covered, the cancelled load returns without writing (the `isCancellation` guard, `:362`), leaving `availabilityState == .loading` until the next appear.

**What changed:** `loadAvailability` now keeps the slot while `isSubmitting` (`:355`). A reappear during a paid or free booking, for example around the 3DS or PaymentSheet presentation, no longer drops it. That was the part of WR-04 that could hurt a payment.

**What did not change:**
- A reappear while idle, such as returning from Payment Methods, still clears the slot and shows the skeleton.
- The cancelled-load case still leaves `availabilityState == .loading`.
- The guard is evaluated once at the top of the load, so it protects only the slot, not the state flag.

**Fix:** Unchanged from the prior pass. Run the initial load once (`guard availabilityState == .idle` or a `hasLoaded` flag), and clear the slot only when the month actually changes (in `goToPreviousMonth`/`goToNextMonth`), not inside `loadAvailability`. Moving the clear would also make the `isSubmitting` guard unnecessary.

### WR-05: Favorites list races and stale state

*Carried forward (not re-reviewed).*

**File:** `FavoritesViewModel.swift:140-163,204-233`, `FavoritesView.swift:71,89`

**Issue:**
- An unfavorite removes the row optimistically and then awaits the DELETE. A pull-to-refresh or stale-restart that started earlier and returns later replaces the whole list (`list.replace`) and brings the removed expert back, even though the DELETE then succeeds. The rollback `insert` has the same problem after a replace.
- Unfavoriting from the expert profile (opened from Favorites with `isFavorited: true`) changes the server state, but `.task { load() }` skips re-fetching when `state == .loaded`, and `onFavorite` is the default no-op. The removed expert stays in the list until a manual pull-to-refresh.

**Fix:** Keep a set of ids with an in-flight removal and filter them out of any refresh or page response. For the profile case, use the existing `onFavorite` hook to remove the row, or mark the list stale so the next appear refreshes.

### WR-06: A transient error AFTER the stamp still ends in a wrongful cancellation about 6 h later (open, tracked as T-04-45) (new)

**File:** `ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js:342,363-387,441-446`, against `src/cron/scaRecoveryWindowSweep.js` (selects `payment_status='scheduled'` and `off_session_attempted_at <= now-6h`; with no `payment_intent_id` it falls to `cancelOne`)

**Issue:** `stampAttempt` (`:342`) still precedes `getOrCreateConnectedCustomer`, `getOrCreateClonedPaymentMethod`, `recheckStillChargeable` (which throws on a read error), `createManualPI` and `confirmPIOffSession`. Any non-card error from those (network, rate limit, Stripe 5xx, a DB blip) takes the `throw err` at `:446`. The row stays `scheduled`, stamped, with no PaymentIntent. About six hours later the window sweep cancels the booking, releases the slot and notifies both parties, and no charge was ever attempted.

This is the same failure mode as CR-02, just later in the function. It predates D-12. Plan 04-16 left it out of scope on purpose, and the code comment (`:441-445`), the docs bullet and the todo `2026-11-12-long-lead-sweep-transient-errors-after-stamp.md` say so. It is more likely to trigger than the fixed path: it covers four Stripe round trips and a DB read per booking, against one.

The docs change in `STRIPE-INTEGRATION.md` is accurate. However, the `04-VERIFICATION` truth 17 text ("a transient Stripe error never cancels") should stay unscored until this is fixed.

**Fix:** On a non-decline error where no PaymentIntent was created (`!pi`), hand the claim back with a guarded update, then re-throw:
```js
// in the catch, before `throw err`
if (!pi) {
  await supabaseAdmin.from('bookings')
    .update({ off_session_attempted_at: null })
    .eq('id', booking.id)
    .eq('payment_status', 'scheduled')
    .is('payment_intent_id', null);
}
throw err;
```
If `pi` exists, the `createManualPI` idempotency key already makes a re-run safe, so resetting is also safe there. Treat it as a design choice and cover it with a two-run test that includes `scaRecoveryWindowSweep`, like the CR-02 tests. Pair it with WR-07.

### WR-07: The pre-stamp retry has no deadline, so a persistent error can leave a delivered session uncharged (accepted by the user, recorded for visibility) (new)

**File:** `ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js:114-146,301-337`

**Issue:** Because a profiles or card-check error never stamps, the row is retried every 5 minutes with no limit and no alert. The candidate query has no `start_time` bound, and the select does not even read `start_time`. `scaRecoveryWindowSweep` ignores unstamped rows. Joining a call checks booking status only. A non-transient error that is not `resource_missing` therefore leaves the booking confirmed and uncharged. The session can go ahead with no PaymentIntent and no hold, and the expert is unpaid. If nobody joins, `expirePastSessions` marks it missed and cancels the scheduled payment with no charge.

The user accepted these limits before the push (04-16 summary, "Limits ... accepted"). Before this change, such a row was cancelled at 6 h by the window sweep, which is a loss of its own but a bounded one. After it, the failure is silent and unbounded. The only trace is one `console.error('[cron:longLeadChargeSweep] Error processing booking ...')` per run, with no OPS marker.

**Fix:** Select `start_time` and add a deadline. Once `charge_due_at` is older than a fixed bound (for example 5 h, so it ends before the session can start), stamp the row and fall back to the existing 6 h recovery path. Log those rows with an `OPS:` prefix, as `compensateIfCancelled` already does, so the Railway log alert can match them. Add a test for a row that keeps failing past the deadline.

## Info

### IN-01: Private `message(for:)` helpers duplicate `Error.userMessage`

*Carried forward (not re-reviewed).*

**File:** `ExpertProfileViewModel.swift:299-306`, `BookingRequestSentViewModel.swift:166-173`
**Issue:** Project convention (CLAUDE.md) says never to write a new private `errorMessage(for:)` helper; use `Error.userMessage`. Both re-implement it.
**Fix:** Replace with `error.userMessage` and delete the helpers.

### IN-02: `PI_CURRENCY_MISMATCH` and `PAID_TOPIC_REQUIRES_PAYMENT` fall through to the default branch

*Carried forward (not re-reviewed).*

**File:** `MakeABookingViewModel.swift:689-694,775-784`
**Issue:** The `ErrorCode` doc says `PI_CURRENCY_MISMATCH` means "discard the intent and restart", like `INTENT_EXPIRED`. The default branch resets the flow but keeps `bookingAttemptId`. The Stripe idempotency key is `booking:{attempt}:create_pi:{account}`, so the next attempt replays the stale intent and can only recover through a second failure (`BOOKING_ATTEMPT_CONFLICT`).
**Fix:** Add `.piCurrencyMismatch` to the `.intentExpired, .piContextMismatch, .piAmountMismatch` case.

### IN-03: Dead branch in `PaymentLifecycleCard.titleColor`

*Carried forward (not re-reviewed).*

**File:** `Request Sent/Subviews/PaymentLifecycleCard.swift:173-175`
**Issue:** Both ternary arms return `Brand.onSurface`. `index <= currentStepIndex` has no effect.
**Fix:** Return `Brand.onSurface` directly or restore the intended muted colour for future steps.

### IN-04: Cancellation and default handling in `MakeABookingViewModel` loaders

*Carried forward (not re-reviewed).*

**File:** `MakeABookingViewModel.swift:310-322,875-885`
**Issue:** `loadTopics` maps any thrown error, including a cancelled task, to `.failed(error.userMessage)`, unlike `loadAvailability`, which excludes cancellation. A topic with no `durationMins` is silently given 30 minutes, and that value is then sent as `durationMinutes` to `/bookings/payment-intent`.
**Fix:** Skip the `.failed` assignment on cancellation. Treat a missing duration as non-bookable instead of guessing.

### IN-05: The paid-flow alert binding ignores dismissal

**Status: re-assessed. The code is unchanged, but plan 04-15 makes the consequence larger.**

**File:** `MakeABookingView.swift:289-294` (was 279-284), `:188-196`
**Issue (original):** `paidFlowAlertBinding.set` is a no-op by design. SwiftUI sees `isPresented` still `true` after a button tap. "Try again" clears `paidFlowAlert` only inside a later `Task`, which risks a re-presentation flicker. If "Check My Bookings" ever leaves this screen on the stack, the flow stays `.confirming` and the Book button stays disabled until the alert is shown again.

**What changed:** "Check My Bookings" in the `confirmUnknown` alert still does not touch the paid flow (`:191-193`). Since 04-15, the paid flow staying in `.confirming` also locks the topic, calendar, slots, meeting type and notes (`isSubmitting`). If the user returns to this screen without the alert coming back, the whole form is frozen, not only the Book button. The only exits are "Try again" or "Not now", both of which live in the alert.

**Fix:** Unchanged from the prior pass. Clear or transition `paidFlowAlert` synchronously in each button action and bind with the standard setter. Also decide what "Check My Bookings" should do to the flow: either `dismissConfirmAlert()` first (the ledger record survives, so D-04 still protects the client), or keep the alert reachable on return.

### IN-06: D-12 backend operational notes

*Carried forward (not re-reviewed).*

**File:** `webhooks.controller.js:386-399`, `docs/ios/STRIPE-INTEGRATION.md`
**Issue:** The eviction only runs if the production Stripe webhook endpoint is subscribed to `payment_method.detached` (a dashboard setting; nothing in the repo shows it). Without it, the sweep's platform-card check is the only protection, which is still sufficient. There is also no notice to the client when a card they removed is attached to a scheduled booking. They find out when it cancels at T-24h. The foreign-card check is skipped when the profile lookup fails (`platformCustomerId === null`). That is acceptable and tested, but note it.
**Fix:** Confirm the endpoint's event list in the Stripe dashboard and record it in the deployment notes. Consider a "your saved card was removed" push for scheduled bookings if product wants earlier warning.

*Update from this pass: the last sentence of this item no longer holds. After 04-16 a failed profile lookup is re-thrown and retried, and a missing `stripe_customer_id` counts as a mismatch, so the foreign-card check is never skipped.*

### IN-07: The snapshot reads `meetingType` and `clientNotes` after the network calls, and `paidAttempt` is writable from anywhere (new)

**File:** `MakeABookingViewModel.swift:459-474` (`book()` captures `topic` and `slot`), `:541-548` (snapshot built after `await`s), `:166` (`var paidAttempt`)
**Issue:** `book()` captures `topic` and `slot` as values, but `meetingType` and `clientNotes` are read from the live view model after two awaited calls. Today that is safe only because `beginPaidBooking` sets `paidStep = .creatingIntent` first, which turns on the form lock. The lock starts when the `Task` body first runs, not inside `book()`, and nothing in the view model itself stops writes to those fields. The doc comment ("as they were when Book Now created the PaymentIntent") promises more than the code guarantees. Separately, `paidAttempt` is an unrestricted internal `var`, so any code in the module can swap the topic, slot or PI id under a running flow.
**Fix:** Read `meetingType` and the trimmed notes in `book()` and pass them to `beginPaidBooking` with `topic` and `slot`. Set the paid step (or `isBooking`) synchronously in `book()` before starting the `Task`. Make the setter `internal(set)` or route test installation through a small `installPaidAttemptForTesting` method.

### IN-08: A slot kept across a reload can be selected while the refreshed calendar shows it unavailable (new)

**File:** `MakeABookingViewModel.swift:350-355,392-394`; `MakeABookingPaidFlowTests.swift:370-387` (`notNowResetsSilently` asserts the slot is kept)
**Issue:** While a paid attempt is in flight the PaymentIntent holds the slot. A reload during that window returns the slot as `held` or unavailable (`isAvailable = available && !held`, `:892`). The load writes the new `availabilityByDate` but nothing reconciles `selectedTimeSlot`, which keeps its stale `isAvailable == true`. After "Not now" or any reset the slot is still selected, `canBook` only checks non-nil, and `book()` re-checks only `isBookableStart`, not availability. The server and the ledger handle it correctly (`SLOT_UNAVAILABLE` plus a record gives the "may already be booked" alert), so the result is a confusing round trip, not a wrong charge.
**Fix:** After a successful load, if the selected slot is no longer present as available in `availabilityByDate` and no attempt is in flight, clear it. Alternatively re-check `isSelectableSlot` in `canBook`.

### IN-09: Wall-clock timing in the confirm-race tests can flake under load (new)

**File:** `MakeABookingPaidFlowTests.swift:914-924,926-945,947-964`
**Issue:** `startSlowConfirm` relies on a 500 ms retry delay and polls every 20 ms on the main actor. Both tests then `#require(confirmRequests().count == 1)` after the poll. On a loaded CI machine, a stall longer than 500 ms between the first request and the check makes the retry fire first, and `#require` fails without any product bug. The 3 s ceiling on the poll has the same shape.
**Fix:** Make the first confirm await a continuation the test controls (or a `ConfirmRetryPolicy` seam with a gate) instead of a real delay, so the "confirm is running" window is held open deterministically.

---

_Reviewed: 2026-11-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard (incremental re-review; prior full-phase pass: 65 files)_
