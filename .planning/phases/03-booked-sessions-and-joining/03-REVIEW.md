---
phase: 03-booked-sessions-and-joining
reviewed: 2026-11-11T00:00:00Z
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
findings:
  critical: 0
  warning: 7
  info: 5
  total: 12
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-11-11
**Depth:** standard
**Files Reviewed:** 77
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

## Warnings

### WR-01: After a successful accept, a failed refetch leaves the Accept/Decline card on screen

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

---

_Reviewed: 2026-11-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
