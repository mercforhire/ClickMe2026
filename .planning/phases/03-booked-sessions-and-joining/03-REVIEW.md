---
phase: 03-booked-sessions-and-joining
reviewed: 2026-11-22T12:00:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - ClickMe2026/Managers/ToastCenter.swift
  - ClickMe2026/Utils/CancelRefundPreview.swift
  - ClickMe2026/Utils/CancelToastMessage.swift
  - ClickMe2026/Utils/ExpertCancelRefundLine.swift
  - ClickMe2026/Utils/UpcomingActionPolicy.swift
  - ClickMe2026/Views/Components/Toast/ToastHost.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
  - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
  - ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift
  - ClickMe2026Tests/Booking/ExpertRescheduleWindowTests.swift
  - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
  - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
  - ClickMe2026Tests/Utils/BookingShortIDTests.swift
  - ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift
  - ClickMe2026Tests/Utils/CancelToastMessageTests.swift
  - ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift
  - ClickMe2026Tests/Utils/ToastCenterTests.swift
  - ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift
incremental_review:
  diff_base: 3f323e646f61ba84f1275fa8972f0ea9bd024235
  reviewed_at: 2026-11-22
  scope: Phase-03 files changed by the 03-REVIEW-FIX fixes, phases 04/05/06/07/08 and quick task a603a2a
  resolved_since_last_review:
    - WR-01
    - WR-02
    - WR-03
    - WR-04
    - WR-05
    - WR-06
    - WR-07
    - WR-08
    - WR-09
    - IN-02
  new_this_pass:
    - WR-10
    - WR-11
    - IN-07
    - IN-08
    - IN-09
  carried_forward:
    - IN-01
    - IN-03
    - IN-04
    - IN-05
    - IN-06
findings:
  critical: 0
  warning: 2
  info: 8
  total: 10
status: issues_found
---

# Phase 3: Code Review Report (incremental re-review)

**Reviewed:** 2026-11-22
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

This pass re-reviewed the 30 Phase-03 files that the review fixes, later phases (04, 05, 06, 07, 08) and quick task a603a2a changed since `3f323e6`. I read each file in full and used `git diff 3f323e6 HEAD` to find what moved. Anything that mirrors a backend rule was checked against `src/utils/reschedule.js` and `clientBooking.controller.js` in the backend repo.

No blocker was found. The money-affecting paths hold up:
- **Refund and hold wording:** the "up to" wording and the neutral post-cancel line are consistent across `CancelRefundPreview`, `CancelToastMessage` and `ExpertCancelRefundLine`. An amount is named only when the server's `refund_amount` is above 0.
- **Cancel confirmation:** `confirmCancellation` captures `confirmedCase` before the await, and `recomputeRefundCase()` is frozen while `isConfirming`.
- **Reschedule answers:** `RescheduleResponder` calls `onResolved(.accepted/.declined)` only after a 2xx and before `refetch`. Both owners then move to the state the server holds and retry the refetch once.
- **Reschedule gate:** `UpcomingActionPolicy.canShowReschedule` matches `canReschedule` in `reschedule.js`: the same three no-time-gate statuses, the same two time-gated statuses, and `missed` excluded.
- **Cancel gate:** it matches the server's `cancellableStatuses` and the strict `end > now` rule.
- **Accept path:** the backend sets `confirmed` and moves `start_time` on accept, which is what `applyResolution(.accepted)` assumes.
- **Toast host:** it is now on both shells, and the injectable `sleep` in `ToastCenter` leaves the production behaviour unchanged. Cancelling a replaced toast's timer, together with the `current?.id == toast.id` check, is correct.

### Prior findings now resolved
- WR-01, WR-02: fixed (03-16, 03-17), still correct.
- WR-03: interim "up to" wording is in place on all three money lines. The real amount-paid figure still needs a backend field, which is a follow-up (additive and Android-safe), not a defect in this code.
- WR-04: `canShowReschedule` exists, is used, and is tested.
- WR-05: `ToastHost` is applied in `HomeExpertView.swift:99`.
- WR-06: `ToastCenterTests` now drive the timer through a manually released sleeper. The cancellation race in `ManualSleeper` is handled either way, so the rows are deterministic.
- WR-07: `submitRefusesFarSlot` uses a stubbed API and asserts zero requests.
- WR-08: both owners apply the resolution locally and retry once. The residual risk the fixer recorded still stands. A decline restores `reschedule_prev_status`, which the client payload does not carry, so `confirmed` is a guess until a refetch lands. It is bounded and needs the device UAT row for a decline on a `pending_approval` booking.
- WR-09: confirmed case captured before the await. The test is covered by WR-11 below.
- IN-02: resolved. `HomeClientView.swift:394-398` now records the "confirmed cancel pops two" invariant beside the route.

## Warnings

### WR-10: Message Client on the expert Booking Summary fails silently and can push the chat twice

**File:** `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift:847-863`
**Issue:** `handleMessage` calls `ClickMeAPI.shared.initiateChat` through `try?` with no in-flight guard.
- **Failure is invisible.** On a network error, a 404 for a suspended or removed client, or a 5xx, the button does nothing and says nothing. CLAUDE.md says not to use `try?` for requests whose failure the user must see.
- **Repeat taps push the chat twice.** Nothing blocks a second tap while the first request runs, and the request can take up to the 120 s timeout. Each tap that gets an answer calls `openChatThread`, which does `chatsPath.push(HomeRoute.chat(...))`. Two answered taps leave two copies of the same thread on the Chats stack, and the user has to Back out twice.
- **The client side was already fixed.** `BookingSummaryViewModel.startChat()` (quick task a603a2a) and `ExpertProfileViewModel.startChat()` (phase 04, IN-22) add an `isStartingChat` guard and an alert. The expert screen was not brought along.

**Fix:** Give `ExpertBookingSummaryViewModel` the same `startChat()` as `BookingSummaryViewModel` (single-flight flag, `apiError`, 404 mapped to `ExpertProfileBlockViewModel.unavailableMessage`, cancellation ignored). Then drive the button from it.
```swift
private func handleMessage(detail: ExpertBookingDetail) {
    guard let openChatThread else { return }
    let peerName = detail.client.name ?? "Client"
    let peerAvatarURL = detail.client.avatarUrl ?? ""
    Task {
        guard let threadId = await viewModel.startChat() else { return }
        openChatThread(threadId: threadId, peerName: peerName, peerAvatarURL: peerAvatarURL)
    }
}
```
Add a "Couldn't start chat" alert bound to `viewModel.apiError`, show a busy state on the button, and add the same unit tests Booking Summary has (success, 404, second tap sends one POST). `UpcomingBookingsView.swift:361` and `RequestDecisionView.swift:283` have the same shape and are worth the same change in their own phase. Android should be checked for the same gap.

### WR-11: `tickDuringRequestKeepsConfirmedCase` waits on a yield count, not on time, and blocks a thread on a semaphore

**File:** `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift:245-257` (the test added for WR-09)
**Issue:** The test starts `confirmCancellation` in a `Task`, then spins `while cancelPosts().isEmpty, polls < 10_000 { await Task.yield() }` until the stub has recorded the POST. `Task.yield()` returns at once when nothing else is runnable on the main actor, so 10,000 iterations take milliseconds, not a bounded wall-clock wait. The request is issued from another thread through `URLSession` and `MockURLProtocol`. On a loaded CI simulator the loop can exhaust before the request arrives, and `#expect(!Self.cancelPosts().isEmpty)` then fails. This is the same thin-margin timing problem WR-06 was raised for, in the test that guards the headline refund wording. The handler also blocks a URL-loading thread on `DispatchSemaphore.wait(timeout: 10)`.
**Fix:** Use the shared helper that already exists, and release the held response with `RequestGate`, as `BookingSummaryViewModelTests.messageExpertIgnoresSecondTap` does:
```swift
let gate = RequestGate()
// handler: gate.waitIfArmed(); return Fixtures.response(...)
gate.arm()
let confirmTask = Task { await viewModel.confirmCancellation { _, _ in } }
await waitUntil("the cancel POST") { !Self.cancelPosts().isEmpty }
clock.now = ...
viewModel.recomputeRefundCase()
gate.open()
await confirmTask.value
```
`waitUntil` (`Support/WaitUntil.swift`) has a 3 s deadline and a 5 ms sleep between checks.

## Info

### IN-01: `bannerFinalStretch` test cannot distinguish the final-stretch branch (carried forward, unchanged)

**File:** `ClickMe2026Tests/Calls/SkypeStatusTextTests.swift:84-92`
**Issue:** The file is outside this pass's file list, but it is unchanged since the last review, so the finding stands. `endingBannerText` returns "Session ending soon" for any state that is neither overtime nor past the end. The test passes whether or not `isInFinalStretch` is true.
**Fix:** Assert `vm.isInFinalStretch == true` in the test, or add a not-in-stretch row.

### IN-03: Duplicate error-message helper (carried forward)

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift:374,433-440`
**Issue:** `message(for:)` re-implements `Error.userMessage`, which CLAUDE.md says to use instead of a private helper. It is the only caller.
**Fix:** Use `error.userMessage` at line 374 and delete `message(for:)`.

### IN-04: The reschedule response card is not gated on booking status (carried forward, now on two screens)

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift:166-176` (with `BookingSummaryViewModel.swift:323`); `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift:220-222`
**Issue:** Upcoming details shows the card only while `bookingStatus == .pendingReschedule` (`pendingProposal`). Client Booking Summary shows it whenever `reschedule != nil`, and the expert summary shows its Accept/Decline buttons whenever `detail.reschedule != nil` and the client proposed. The backend sends the block only for `pending_reschedule` today, so this is not reachable now. A payload change would put money-affecting buttons on a terminal booking.
**Fix:** Decode the status in `BookingSummaryViewModel` and the expert summary view model, and gate the card on it the same way as `pendingProposal`.

### IN-05: `startCall()` returns silently when join inputs are missing (carried forward)

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift:249`
**Issue:** If `expertId`, `startTime` or `endTime` is nil, Join does nothing and shows nothing. It is unreachable today because `joinWindowOpen` already requires both times and `apply` sets `expertId`. A future change to `apply` would leave a dead button for the app's core flow.
**Fix:** Set `CallCenter.shared.joinError` (or assert in DEBUG) in the guard's else branch.

### IN-06: `.chargedNotRefundable` at server 0 still says "No refund applies" (carried forward)

**File:** `ClickMe2026/Utils/CancelToastMessage.swift:53-54`
**Issue:** The refundable case now uses the neutral line, but the mirror case stays firm. With a phone clock that runs ahead, a booking just over 24 h away is previewed as not refundable. If the server then answers 0 because a refund failed and is being retried, the toast says no refund applies. It needs clock skew at the edge and a refund failure together.
**Fix:** Accept it and note it in the doc comment, or use the neutral line when the confirm-time margin to the 24 h edge is a few minutes or less.

### IN-07: The confirm step shows a refund case that is only as fresh as the load, until the first 60 s tick

**File:** `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift:146-148` and `ClientCancellationView.swift:197-205`
**Issue:** `advanceToConfirmation()` does not recompute the case. `TimelineView.onChange(of: context.date)` fires only on the first tick, 60 s after the confirm step appears. If the user sits on the reason step across the 24 h line (or the case was computed long before), the confirm card first shows the stale "Refund: up to CA$X" line. The safety net works: `confirmCancellation` re-checks, shows the notice and sends nothing. The cost is a misleading line and one wasted tap.
**Fix:** Call `recomputeRefundCase()` in `advanceToConfirmation()` before changing `step`.

### IN-08: `rescheduleListsAreExhaustive` claims exhaustiveness it does not check

**File:** `ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift:94-100` (and `listsAreExhaustive` just below)
**Issue:** The tests compare hand-written arrays with each other. `BookingStatus` is not `CaseIterable`, so adding a case to the enum does not fail either test. A new status silently falls out of both lists, and the policy's safe default hides Cancel and Reschedule with no signal.
**Fix:** Make `BookingStatus` `CaseIterable` and assert `Set(BookingStatus.allCases) == all`. If that is not wanted, rename the tests so they do not claim exhaustiveness.

### IN-09: `rescheduleTimesRow` builds two throwaway `RescheduleProposal` values just to format a date

**File:** `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift:611-640`
**Issue:** Each call fabricates a `RescheduleProposal` with a fake timezone, `.client` initiator and `createdAt`, only to reach `viewModel.formattedProposedSlot`. If that formatter ever reads another field of the proposal, the "From" side silently shows wrong data.
**Fix:** Add a `formattedSlot(_ date: Date)` to the view model and have `formattedProposedSlot` call it. Drop the fake proposals.

---

_Reviewed: 2026-11-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
