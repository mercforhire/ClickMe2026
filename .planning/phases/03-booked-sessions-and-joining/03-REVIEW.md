---
phase: 03-booked-sessions-and-joining
reviewed: 2026-11-11T12:00:00Z
depth: standard
files_reviewed: 77
files_reviewed_list:
  - ClickMe2026/Managers/ToastCenter.swift
  - ClickMe2026/Model/Responses/CancelBookingData.swift
  - ClickMe2026/Model/Responses/ClientBookingDetail.swift
  - ClickMe2026/Model/Responses/ExpertBookingDetail.swift
  - ClickMe2026/Network/ClickMeAPI+Availability.swift
  - ClickMe2026/Network/ClickMeAPI+Booking.swift
  - ClickMe2026/Utils/BookingShortID.swift
  - ClickMe2026/Utils/BookingStatusPill.swift
  - ClickMe2026/Utils/CancelReasonComposer.swift
  - ClickMe2026/Utils/CancelRefundPreview.swift
  - ClickMe2026/Utils/CancelToastMessage.swift
  - ClickMe2026/Utils/DeclineNote.swift
  - ClickMe2026/Utils/ExpertCancelRefundLine.swift
  - ClickMe2026/Utils/ExpertJoinVisibility.swift
  - ClickMe2026/Utils/UTF16Prefix.swift
  - ClickMe2026/Utils/UpcomingActionPolicy.swift
  - ClickMe2026/Views/Components/Toast/ToastHost.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
  - ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift
  - ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift
  - ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift
  - ClickMe2026/Views/Screens/Call/Calling/Subviews/SkypeSessionHero.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryDeclineNoteCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/RescheduleResponseCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationBookingSummary.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationCommentField.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsView.swift
  - ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/PastEmptyState.swift
  - ClickMe2026/Views/Screens/Client Mode/Payments/ClientTransactionsView.swift
  - ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleTimeSlotsCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingJoinCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingStatusRow.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Cancellation/ExpertCancellationView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Cancellation/ExpertCancellationViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Cancellation/Subviews/ExpertCancellationClientBox.swift
  - ClickMe2026/Views/Screens/Expert Mode/Cancellation/Subviews/ExpertCancellationMainCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift
  - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
  - ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift
  - ClickMe2026Tests/Booking/ExpertRescheduleWindowTests.swift
  - ClickMe2026Tests/Booking/MyBookingsEmptyStateTests.swift
  - ClickMe2026Tests/Booking/RescheduleAvailabilityTests.swift
  - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
  - ClickMe2026Tests/Booking/RescheduleWindowTests.swift
  - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
  - ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift
  - ClickMe2026Tests/Calls/SkypeStatusTextTests.swift
  - ClickMe2026Tests/Support/ClientBookingFixtures.swift
  - ClickMe2026Tests/Support/URLRequest+Body.swift
  - ClickMe2026Tests/Utils/BookingShortIDTests.swift
  - ClickMe2026Tests/Utils/BookingStatusPillTests.swift
  - ClickMe2026Tests/Utils/CancelReasonComposerTests.swift
  - ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift
  - ClickMe2026Tests/Utils/CancelToastMessageTests.swift
  - ClickMe2026Tests/Utils/DeclineNoteTests.swift
  - ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift
  - ClickMe2026Tests/Utils/ExpertJoinVisibilityTests.swift
  - ClickMe2026Tests/Utils/HomeNavigationPathTests.swift
  - ClickMe2026Tests/Utils/ToastCenterTests.swift
  - ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift
incremental_review:
  diff_base: aac974b62917fc8052e79df6c83873523bc18733
  reviewed_at: 2026-11-11
  scope: gap-closure plans 03-16 (WR-01) and 03-17 (WR-02)
  files:
    - ClickMe2026/Utils/CancelToastMessage.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
    - ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift
    - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
    - ClickMe2026Tests/Utils/CancelToastMessageTests.swift
  resolved_this_pass:
    - WR-01
    - WR-02
  new_this_pass:
    - WR-08
    - WR-09
    - IN-06
findings:
  critical: 0
  warning: 7
  info: 6
  total: 13
  open_ids:
    - WR-03
    - WR-04
    - WR-05
    - WR-06
    - WR-07
    - WR-08
    - WR-09
    - IN-01
    - IN-02
    - IN-03
    - IN-04
    - IN-05
    - IN-06
  resolved_ids:
    - WR-01
    - WR-02
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-11-11 (incremental pass over 03-16 and 03-17; original full review 2026-11-11)
**Depth:** standard
**Files Reviewed:** 77 (full phase) plus 9 re-reviewed incrementally
**Status:** issues_found

## Summary

Reviewed the 54 app files and 23 test files changed since `596c75f`, money-affecting paths first (reschedule accept/decline, client cancel and refund preview, expert cancel refund line, join/call start), then navigation and pop logic, then the rest. Where a client rule claims to mirror the backend, I checked it against `refund.js`, `reschedule.js`, `clientBooking.controller.js`, `expertBooking.controller.js` and `booking.schema.js` in the backend repo.

No blocker was found. The mirrored rules match the backend:
- The strict `> 24h` refund edge.
- The 6-day paid reschedule cap.
- The UTF-16 caps of 500 on the decline reason and cancel reason.
- The cancel-status set and the `SESSION_ALREADY_ENDED` gate.
- The join-window tiers.
- The `payment_not_charged` derivation.

The accept/decline flow is single-flight and only confirms after a 2xx.

The warnings are about places where the UI states something about money or state that it cannot be sure of, an action offered on statuses the server refuses, a silent success path in the expert shell, and two tests that are unreliable. Nothing here changes what the backend charges or refunds.

### Incremental pass: 03-16 (WR-01) and 03-17 (WR-02)

Diffed `aac974b..HEAD` for the nine files and traced both fixes.

- **03-16 / WR-01 is fixed.** `onResolved` is called only on a 2xx path (first accept, saved-card retry accept, decline), never in a `catch`, and runs synchronously before `refetch`. `ReloadGeneration` makes a refresh that was already in flight before the POST lose to the post-accept refetch, because `refetch` calls `begin()` in the same main-actor turn as `onResolved`. So a stale in-flight GET cannot re-add the card. Double-tap is still blocked by `isSubmitting`. The tests (hook order, retry fires once, no hook on 409 / empty vault / vault failure / repeat 422, 500 on refetch clears the card on both screens) are meaningful and isolated: the suites are `.serialized`, the test target is `parallelizable: false`, and `MockURLProtocol` records a request before the handler runs, so the "first detail GET only" counting in `failingRefetchAPI()` is sound. One residual gap is recorded as WR-08: only the card is cleared, not the stale time and status.
- **03-17 / WR-02 is fixed for the case it named.** A server `refund_amount` of 0 under `.chargedRefundable` now returns the neutral line with no amount and no timing, a server amount above 0 still names the amount, and the other cases are unchanged. The neutral wording cannot leak into a case where the server refunded more than 0, because the `> 0` branch returns first. Two adjacent paths that the fix leaves open are recorded as WR-09 and IN-06.

## Warnings

### WR-01: After a successful accept, a failed refetch leaves the Accept/Decline card on screen

**Status:** fixed in 03-16 (verified in this review).
Verification: `RescheduleResponder.swift:99,126,159` call `onResolved?()` after the success toast and before `await refetch?()` on all three success paths. `UpcomingBookingViewModel.swift:126` and `BookingSummaryViewModel.swift:150` set `reschedule = nil`. The card is gated on `reschedule` (Booking Summary) and `pendingProposal` (Upcoming details, which derives from `reschedule`), so it goes even when `refresh()` swallows a failed GET. The hook is not reached from any `catch`. Tests in `RescheduleResponderTests`, `UpcomingBookingViewModelTests` and `BookingSummaryViewModelTests` cover the success and failure paths. See WR-08 for what the fix does not clear.

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift:87-91` (with `UpcomingBookingViewModel.swift:262-275` and `BookingSummaryViewModel.swift:212-225`)
**Issue:** `accept()` posts "Reschedule accepted" and then awaits `refetch`. Both owners implement `refetch` as `refresh()`, which deliberately swallows a failed detail GET and keeps the last known screen. After a flaky-network failure the user sees a green "Reschedule accepted" toast while the card still shows "Accept New Time" and "Decline New Time" for a proposal that no longer exists. Tapping Accept again sends a second money-affecting POST. The server then returns a status error that is shown as "Couldn't update booking". Decline has the same problem. Only a later `booking.update` socket event or a manual reopen clears the card. No test covers success followed by a failed refetch.
**Fix:** After a 2xx, clear the proposal locally without depending on the refetch result, then refetch for fresh times.
```swift
// RescheduleResponder: after a 2xx
toasts.show("Reschedule accepted")
onResolved?()          // owner sets reschedule = nil (UpcomingBookingViewModel / BookingSummaryViewModel)
await refetch?()
```
Add a responder test where the post-accept detail GET returns 500 and assert `pendingProposal == nil`.

### WR-02: Post-cancel toast can promise a refund the server did not issue

**Status:** fixed in 03-17 (verified in this review).
Verification: `CancelToastMessage.swift:51-52` now returns "Booking cancelled. Any refund due will follow our cancellation policy." for `.chargedRefundable` at server 0. The `serverRefundMajor > 0` branch (lines 39-44) returns before the `switch`, so an amount is named only when the server's amount is above 0. The idempotent already-cancelled 200 (also 0) gets the neutral line, covered by `alreadyCancelledShowsNeutralLine`. `CancelToastMessageTests` asserts no amount, no digits and no timing words. Two adjacent paths remain open: see WR-09 and IN-06.

**File:** `ClickMe2026/Utils/CancelToastMessage.swift:44-45`, driven by `ClientCancellationViewModel.swift:136,159,191-195` and `CancelRefundPreview.swift:119`
**Issue:** The refund case is decided with the device clock (`now()`), while the server decides with its own clock (`computeRefundAmountMinorUnits`, strict `> 24h`). If the phone clock runs behind, or the booking crosses the 24h line between the last recompute and the server handling the request, the user confirms under `.chargedRefundable` and the server returns `refund_amount: 0`. `CancelToastMessage` then shows "Your CA$45.00 refund is being processed." No refund is coming. The `0` is ambiguous by design (a refund retry also returns 0), but this branch resolves the ambiguity optimistically. The same applies to the idempotent "already cancelled" 200, which also returns 0. The 24h preview and toast are the headline money statement of this phase.
**Fix:** When the server returns 0 under `.chargedRefundable`, use neutral wording that does not name an amount or promise timing, for example "Booking cancelled. Any refund due will follow our cancellation policy." Keep the amount-specific wording for server amounts above 0. Optionally derive `now` from the response `Date` header instead of the device clock.

### WR-03: Refund and hold lines show the list price, not the amount paid

**File:** `ClickMe2026/Utils/CancelRefundPreview.swift:106-123` and `ClickMe2026/Utils/ExpertCancelRefundLine.swift:52-57`
**Issue:** The client rule uses `topic.price.amount`, and the expert rule uses `session.consultationFee.amount`. The backend refunds `amount_paid_minor_units` (`clientBooking.controller.js:938-945`), which is lower when a promo code was applied. The confirm step then states "Refund: CA$45.00" or "The client will get a full refund of CA$45.00" when the real amount is smaller. The doc comment admits the amount is the list price, but the copy is worded as a firm figure on a real-money action. The post-cancel toast self-corrects, but only after the cancel is irreversible.
**Fix:** Prefer an amount-paid field in the booking detail payload when the backend exposes one (that is a backend change, so flag it to that repo). Until then, do not state a figure for a booking that may have used a promo, or add "up to" to the wording: "Refund: up to CA$45.00".

### WR-04: Reschedule is offered on every booking status; only Cancel was gated

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift:245-256`, `Utils/UpcomingActionPolicy.swift`, `Views/Screens/Client Mode/Payments/ClientTransactionsView.swift:71-74`
**Issue:** This phase routes every Payments row, including completed, cancelled, declined and refunded bookings, to `UpcomingBookingView`. It also hides Cancel on statuses the server refuses. Reschedule stays visible regardless. The backend `canReschedule` accepts only `confirmed`, `pending_approval`, `pending_reschedule`, and (until end) `completed` and `in_progress`. A client who opens a cancelled, declined, missed, expired or unknown-status booking from Payments or a chat row sees a Reschedule button that can only produce a server error. `UpcomingActionPolicyTests` pins the Cancel rule but nothing pins Reschedule.
**Fix:** Add `UpcomingActionPolicy.canShowReschedule(status:end:now:)` mirroring `canReschedule`, pass `showsReschedule` into `UpcomingBookingSecondaryActions`, hide the row when both are false, and add test rows.

### WR-05: Reschedule accept/decline succeeds silently in the expert shell

**File:** `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift:252` (with `RescheduleResponder.swift:89,115,147` and `ToastCenter.swift:15-17`)
**Issue:** The expert shell registers `UpcomingBookingView` for `HomeRoute.upcomingBooking`, so a dual-role user opening a client booking from a chat row gets the full Accept/Decline response card. `ToastHost` is installed only on the client shell, so "Reschedule accepted" and "Reschedule declined" are posted to `ToastCenter.shared` with nothing to show them. The only feedback is the card disappearing. Because the toast lingers for 4 seconds in the shared singleton, it can also surface later if the user switches to client mode.
**Fix:** Install `ToastHost` on `HomeExpertView` too, or have the expert shell suppress the response card via `hostsClientBookingFlows`. The toast comment already says "client mode only", so one of these needs to be decided explicitly.

### WR-06: `ToastCenterTests` use real sleeps with thin margins

**File:** `ClickMe2026Tests/Utils/ToastCenterTests.swift:29-42,55-67`
**Issue:** `replacementRestartsTimer` asserts that B is still present 360 ms after A. B's timer, restarted at 180 ms, expires at 480 ms. That leaves 120 ms of slack, and the later assertion at about 610 ms has about 130 ms. `Task.sleep` only guarantees a minimum, so a loaded CI simulator that overshoots one sleep by over 120 ms fails the first assertion. `showAfterDismiss` has a 100 ms margin. These are timing-based flakes in a suite that gates the release.
**Fix:** Use a much larger `displayDuration` (several seconds) with `dismiss()` for the "still present" assertions, or inject a clock or `sleep` closure into `ToastCenter` so tests advance time deterministically.

### WR-07: `submitRefusesFarSlot` would call the live backend if its guard regressed

**File:** `ClickMe2026Tests/Booking/ExpertRescheduleWindowTests.swift:77-92`
**Issue:** The test builds `ExpertRescheduleViewModel(bookingId: UUID(), isPaidBooking: true)`, which uses `ClickMeAPI.shared` pointed at the Production `Environments.plist` URL. The file header says these rows "must not touch MockURLProtocol". If the local `isBookableStart` guard in `submit` is removed or reordered, the test sends a real unauthenticated PATCH to production, and the assertion fails with a different error string. A guard test should not have a live-network fallback.
**Fix:** Inject a stubbed `ClickMeAPI` via the existing `api:` parameter (`APITestFactory.make { _ in fail }`) and assert `MockURLProtocol.recordedRequests.isEmpty`. That also proves "no request is made", which the current test only implies.

### WR-08: After a successful accept or decline with a failed refetch, the screen still shows the old time and a "Pending reschedule" status, and nothing retries

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift:99-100,126-127,159-160`; `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift:126,264-277`
**Issue:** The 03-16 fix clears only `reschedule`. When `refresh()` then fails, `bookingStatus` stays `.pendingReschedule` and `date`, `timeRange`, `startTime`, `endTime` and `canJoin` stay at the pre-answer values. After a successful accept the user sees the "Reschedule accepted" toast, no card, and the OLD session time under a "Pending reschedule" pill. `joinWindowOpen(at:)` and `UpcomingActionPolicy.canShowCancel` still evaluate the old window, so Join can appear enabled for a window that no longer exists (the server refuses it, but the user was told the booking moved). After a decline the pill is wrong the other way (the booking is no longer pending). `refresh()` is called once; there is no retry, so only a `booking.update` socket event or reopening the screen repairs it. WR-01's double-money-POST risk is closed, but the screen is left in a state the server has already left.
**Fix:** Give `onResolved` the outcome so each owner can update locally, and retry the refetch once.
```swift
enum Resolution { case accepted(RescheduleProposal), declined }
@ObservationIgnored var onResolved: (@MainActor (Resolution) -> Void)?

// UpcomingBookingViewModel
responder.onResolved = { [weak self] resolution in
    guard let self else { return }
    if case .accepted(let proposal) = resolution {
        startTime = proposal.proposedStart; endTime = proposal.proposedEnd
        date = Self.dateString(proposal.proposedStart)
        timeRange = Self.timeRangeString(from: proposal.proposedStart, to: proposal.proposedEnd)
    }
    bookingStatus = .confirmed; statusRaw = BookingStatus.confirmed.rawValue
    canJoin = nil
    reschedule = nil
}
```
At minimum, make the owner's `refetch` retry once after a short delay when the first attempt throws, and add a test where the post-answer GET fails and asserts `bookingStatus != .pendingReschedule`.

### WR-09: Post-cancel toast reads the refund case after the await, so the 60 s tick can change the case the user confirmed under

**File:** `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift:187-195` (with `ClientCancellationView.swift:193-197` and `ClientCancellationViewModel.swift:134-137`)
**Issue:** `confirmCancellation` passes `booking.refundCase ?? .amountUnknown` to `CancelToastMessage.text` after `await api.cancelClientBooking(...)`. The confirm step's `TimelineView` calls `recomputeRefundCase()` every 60 seconds and nothing pauses it while `isConfirming` is true. If a tick lands during the request (and the cancel takes up to the 120 s request timeout on a bad network) and the booking has crossed the 24h line, `booking.refundCase` flips from `.chargedRefundable` to `.chargedNotRefundable`. With a server 0 the toast then says "No refund applies because the session was within 24 hours", which contradicts what the user confirmed and is worse than the neutral line 03-17 added. The doc on `CancelToastMessage.text` says the parameter is "the case the client last saw on the confirm step", and the code does not guarantee that.
**Fix:** Capture the case once, next to the check that compares it, before any await.
```swift
let confirmedCase = booking.refundCase ?? .amountUnknown   // before cancelError = nil / the await
...
toasts.show(CancelToastMessage.text(
    serverRefundMajor: response.data.refundAmount,
    currency: response.data.currency,
    confirmedCase: confirmedCase
))
```
Also make `recomputeRefundCase()` return early while `isConfirming`. Add a test that advances the test clock inside the cancel handler and asserts the toast follows the pre-request case.

## Info

### IN-01: `bannerFinalStretch` test cannot distinguish the final-stretch branch

**File:** `ClickMe2026Tests/Calls/SkypeStatusTextTests.swift:84-92`
**Issue:** `endingBannerText` returns "Session ending soon" for any state that is neither overtime nor past the scheduled end. The test passes whether or not `isInFinalStretch` is true, and it also passes for a call that has not started.
**Fix:** Assert `vm.isInFinalStretch == true` in the test, or drive the text from `isInFinalStretch` and add a not-in-stretch row.

### IN-02: `HomeNavigationPathTests` do not cover the route wiring that makes `pop(2)` correct

**File:** `ClickMe2026Tests/Utils/HomeNavigationPathTests.swift`, `HomeClientView.swift:330-339`
**Issue:** `pop(2)` after a confirmed cancel assumes the details screen is on the path directly beneath the cancel screen. That holds for `HomeRoute` pushes (push tap, chat row, Payments). If a caller ever shows `UpcomingBookingView` through a view-destination `NavigationLink`, `pop(2)` pops the cancel screen only, or one level too many, and the user is left on a cancelled booking's details. The tests only exercise `pop(_:)` arithmetic.
**Fix:** Add a short comment at the `.cancelBooking` case recording the invariant, and cover it with a UAT row for Payments, chat-row and push-tap entry (the device checklist may already include this).

### IN-03: Duplicate error-message helper

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift:362-369`
**Issue:** `message(for:)` re-implements `Error.userMessage`. CLAUDE.md says to use `userMessage` and not write a new private helper. This is old code, but the file was reworked in this phase and it is the only place left doing it.
**Fix:** Replace the call at line 303 with `error.userMessage` and delete `message(for:)`.

### IN-04: Booking Summary shows the response card without a status check

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift:286` and `BookingSummaryView.swift:158-167`
**Issue:** Upcoming details gates the card on `bookingStatus == .pendingReschedule` (`pendingProposal`). Booking Summary shows it whenever `reschedule != nil`. The backend returns the block only for `pending_reschedule` today, so this is not reachable now. A payload change would put money-affecting buttons on a terminal-booking summary.
**Fix:** Gate on the decoded status the same way as `pendingProposal`.

### IN-05: `startCall()` returns silently when join inputs are missing

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift:216-217`
**Issue:** If `expertId`, `startTime` or `endTime` is nil, the Join button does nothing and shows no error. The window gate (`joinWindowOpen`) already requires start and end, and `expertId` is set in the same `apply`, so it is unreachable now. Join is the app's core flow, so a future change to `apply` would produce a dead button with no diagnostics.
**Fix:** Set `CallCenter.shared.joinError` (or assert in debug) in the guard's else branch.

### IN-06: `.chargedNotRefundable` at server 0 still states "No refund applies", the same ambiguity WR-02 removed for the refundable case

**File:** `ClickMe2026/Utils/CancelToastMessage.swift:53-54`
**Issue:** The 03-17 fix made `.chargedRefundable` neutral because the case comes from the phone clock and a server 0 is ambiguous. The mirror case is left firm. If the phone clock runs ahead, a booking just over 24h out is previewed as `.chargedNotRefundable`. The server then refunds, which the `> 0` branch handles correctly, or it returns 0 because the refund failed and is being retried (`refund_failed`). In the second case the toast says "No refund applies because the session was within 24 hours" for a booking the server considered refundable. This needs a clock skew at the edge and a refund failure together, so it is rare.
**Fix:** Either accept it and note it in the `CancelToastMessage` doc comment, or use the neutral line for `.chargedNotRefundable` too when the confirm-time margin to the 24h edge is under a few minutes.

---

_Reviewed: 2026-11-11 (incremental pass appended; original review preserved)_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
