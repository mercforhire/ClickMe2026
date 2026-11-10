---
phase: 02-shared-ios-plumbing
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 89
files_reviewed_list:
  - ClickMe.xcodeproj/xcshareddata/xcschemes/ClickMe2026.xcscheme
  - ClickMe2026/AllTests.xctestplan
  - ClickMe2026/ClickMe2026AppDelegate.swift
  - ClickMe2026/Localizable.xcstrings
  - ClickMe2026/Managers/AgoraManager.swift
  - ClickMe2026/Managers/ChatPresence.swift
  - ClickMe2026/Managers/PushForegroundPolicy.swift
  - ClickMe2026/Managers/PushRouter.swift
  - ClickMe2026/Managers/PushTokenCleanup.swift
  - ClickMe2026/Managers/UserManager.swift
  - ClickMe2026/Model/Enums/BookingStatus.swift
  - ClickMe2026/Model/Enums/ErrorCode.swift
  - ClickMe2026/Model/Push/PushEvent.swift
  - ClickMe2026/Model/Responses/Children/ClientTransactionItem.swift
  - ClickMe2026/Model/Responses/Children/ExpertBookingItem.swift
  - ClickMe2026/Model/Responses/ClientBookingDetail.swift
  - ClickMe2026/Model/Responses/MeData.swift
  - ClickMe2026/Model/UIModels/BookingTopic.swift
  - ClickMe2026/Model/UIModels/UpcomingBooking.swift
  - ClickMe2026/Utils/BookingErrorMapper.swift
  - ClickMe2026/Utils/CallOvertimePolicy.swift
  - ClickMe2026/Utils/JoinWindow.swift
  - ClickMe2026/Utils/Money.swift
  - ClickMe2026/Utils/PaidBookingWindow.swift
  - ClickMe2026/Utils/ReloadGeneration.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
  - ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift
  - ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift
  - ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift
  - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift
  - ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/UpcomingBookingCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleView.swift
  - ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleTimeSlotsCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Client Profile/Subviews/ClientProfileBookingCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/IncomingRequestsViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Payouts/PayoutsViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Payouts/Subviews/EarningsTransactionRow.swift
  - ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionEarningsSection.swift
  - ClickMe2026/Views/Screens/Expert Mode/Reschedule/ExpertRescheduleViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift
  - ClickMe2026/Views/Screens/Notification/NotificationsListView.swift
  - ClickMe2026/Views/Screens/Notification/NotificationsListViewModel.swift
  - ClickMe2026Tests/Booking/BookingErrorCopyParityTests.swift
  - ClickMe2026Tests/Booking/RescheduleWindowTests.swift
  - ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift
  - ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift
  - ClickMe2026Tests/Fixtures/Auth/login_success.json
  - ClickMe2026Tests/Integration/AuthSmokeTests.swift
  - ClickMe2026Tests/Integration/SignupSmokeTests.swift
  - ClickMe2026Tests/Model/BookingStatusDecodingTests.swift
  - ClickMe2026Tests/Model/TopicCurrencyTests.swift
  - ClickMe2026Tests/Network/Auth/LoginTests.swift
  - ClickMe2026Tests/Push/PushDestinationTableTests.swift
  - ClickMe2026Tests/Push/PushEventTests.swift
  - ClickMe2026Tests/Push/PushForegroundPolicyTests.swift
  - ClickMe2026Tests/Push/PushRoutePlannerTests.swift
  - ClickMe2026Tests/Push/PushTokenCleanupTests.swift
  - ClickMe2026Tests/Utils/BookingErrorMapperTests.swift
  - ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift
  - ClickMe2026Tests/Utils/ClientProfileBookingCardTests.swift
  - ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift
  - ClickMe2026Tests/Utils/JoinWindowTests.swift
  - ClickMe2026Tests/Utils/MoneyCallSiteTests.swift
  - ClickMe2026Tests/Utils/MoneyTests.swift
  - ClickMe2026Tests/Utils/PaidBookingWindowTests.swift
  - ClickMe2026Tests/Utils/ReloadGenerationTests.swift
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 89
**Status:** issues_found

## Summary

Reviewed the changed hunks (`git diff 8a2cc2c..HEAD`) of the phase, with surrounding code and the backend contract (`src/services/agora.js`, `src/schemas/call.schema.js`, `docs/ios/USD-TOPIC-PRICING.md`) read for cross-checks.

The core plumbing holds up. I traced these paths and found them correct:

- `JoinWindow` matches the backend's `evaluateJoinWindow` and the joinable-status set.
- `CallOvertimePolicy` boundaries, and the `/end` minimum duration of 1.
- The Agora `.failed` to `.disconnected` mapping and its single `/end` with `.dropped`.
- `PushEvent` parsing and the `PushRoutePlanner` mode-switch logic. The overlapping `consumePendingPush` Tasks are safe because the MainActor serializes them and `planPending` re-checks `pending == queued` after each await.
- `HomeRoute` is registered exactly once per tab through `homeStack`, so the CR-01 failure cannot recur on these stacks.
- `ReloadGeneration` use on all four client/expert booking view models.
- `Money` integer math and its digit tables.
- `PushTokenCleanup` ordering and its bounded race.
- The BOOK-14 dim-not-hide behavior, per user decision 1.

No Critical issues. Four Warnings and three Info items remain, mostly gaps at the edges of the new shared helpers:

- WR-01: client screens still coerce unknown booking statuses to `.confirmed`.
- WR-02: the new `isLoggingOut` guard can drop the next login's push registration.
- WR-03: the topic editor's typed-price parse is wrong for zero-decimal currencies and can trap on overflow.
- WR-04: `PI_CURRENCY_MISMATCH` is not handled in the paid flow.

**Note on commits e43ef50 and 73e729e (outside phase plans).** These two commits (topic currency picker, EXP-17 iOS half, backend phase 34 D-18) came from a separate session and are not covered by any Phase 2 plan. They touch `ErrorCode.swift`, `MeData.swift`, `TopicEditorView.swift`, `TopicEditorViewModel.swift`, `TopicCurrencyTests.swift` and `MoneyCallSiteTests.swift`. They were reviewed with the phase. Findings that come from them are labeled "(outside phase plans: e43ef50/73e729e)" in the body (WR-03, WR-04, IN-03). The backend contract strings (FX notice, lock caption) match `docs/ios/USD-TOPIC-PRICING.md` verbatim.

## Warnings

### WR-01: Client screens coerce an unknown booking status to `.confirmed`, so BOOK-18 is only half-applied

**File:** `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift:190`, `ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift:214`
**Issue:** The phase added `BookingStatus.rescheduled` and `.unknown` so an unrecognized status never reads as something it is not. Context says "the screen shows a neutral label until the refetch finishes". The typed decoders (`RealtimeBookingUpdateEvent`, `ExpertBookingItem`) now do this. The client detail and list payloads still carry `status` as a raw `String` (`ClientBookingDetail.status`, `ClientBookingItem.status`). Both view models map it with `BookingStatus(rawValue: ...) ?? .confirmed`:
- `UpcomingBookingViewModel.apply`: `bookingStatus = BookingStatus(rawValue: data.status) ?? .confirmed`
- `MyBookingsViewModel.mapUpcoming`: `let status = BookingStatus(rawValue: item.status) ?? .confirmed`

A status string this build does not know therefore renders as a confirmed booking. The card shows an enabled Join inside the window, plus the confirmed-state actions. This is the opposite of the neutral fallback. `JoinWindow` correctly refuses `.unknown`, but this fallback bypasses it. The server still has the final say on `/join`, so this is not a charge risk, but the user gets actions the booking does not allow.
**Fix:** Use the new fallback case instead of `.confirmed`:
```swift
bookingStatus = BookingStatus(rawValue: data.status) ?? .unknown
// MyBookingsViewModel.mapUpcoming
let status = BookingStatus(rawValue: item.status) ?? .unknown
```
Make sure the detail view and the card render a neutral label for `.unknown`. Alternatively decode `status` as `BookingStatus` on `ClientBookingDetail` and `ClientBookingItem`, which also makes `.rescheduled` reachable.

### WR-02: `isLoggingOut` stays true after the login screen is up, so a fast re-login can silently skip push registration

**File:** `ClickMe2026/Managers/UserManager.swift:341-357` (flag lifetime), `:661` and `:740` (guards), `:206` and `:236` (login/signup callers)
**Issue:** `logout()` sets `isLoggingOut = true` and clears it only after `signOut` finishes, which includes the final `deleteToken` step (up to 3 s). `clearLocalSession()` runs before that step, so the shell routes to Login while the flag is still set. `registerPushToken` and `fetchAndUploadFCMToken` both return early while it is set. `apply(loginData:)` and `apply(signupData:)` call `fetchAndUploadFCMToken()` exactly once. A user who signs back in inside that window (account switch on a shared device, which is the PUSH-04 scenario) gets the registration skipped. The `MessagingDelegate` token callback after `deleteToken` is skipped the same way if it lands before the flag clears. Nothing retries until the next foreground activation (`refreshPushTokenBinding`), so the new account can receive no pushes for the rest of that session.

A related overlap: `login()` awaits `retryPushCleanupIfNeeded()`. The marker is set before `clearSession` and removed only after `deleteToken` succeeds, so the retry starts a second `deleteToken` while the first is still running. Two concurrent `deleteToken` calls can both invalidate the token the new session is about to register.
**Fix:** Make the guard apply only to the account that is leaving, not to the next login. For example, clear `isLoggingOut` as soon as `clearLocalSession()` has run (in the `clearSession` closure), since the leaving account has no bearer after that point. Or have `apply(loginData:)` and `apply(signupData:)` re-trigger registration after the flag clears. Have `retryPushCleanupIfNeeded` await the in-flight cleanup instead of starting a parallel `deleteToken`.

### WR-03: Typed topic price is always multiplied by 100, ignoring the currency's digits, and can overflow (outside phase plans: e43ef50/73e729e)

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift:385` (the `rateMinor = rateMajor * 100` line in `validate()`)
**Issue:** Two defects in the typed-price branch.
1. The phase changed the editor so a topic keeps its own currency, and `currency` can now be any stored code. For an existing paid topic in a zero-decimal currency (JPY, KRW, VND and so on) the field is seeded through `Money.fractionDigits`, so `¥1200` shows as `"1200"`. A retyped price then goes through `rateMinor = rateMajor * 100`, so typing `1500` sends `150000` JPY minor units, which is a 100x price. The seed and the parser disagree about what the field's unit is. Before the currency change this was unreachable, because the currency was always the account default (CAD).
2. `Int(trimmedRate)` followed by `* 100` traps with an arithmetic overflow for a long digit string. The field uses `.numberPad`, so a 17-digit entry crashes the app. The multiplication used to sit in the same place, but it is now in a path the phase edited.

Reachability of (1) depends on legacy topics in non-CAD/USD currencies existing. The backend's `allowed_currencies` is `["CAD","USD"]`, but the editor passes any stored currency through to the save.
**Fix:**
```swift
let digits = Money.fractionDigits(for: currency)
let (scaled, overflow) = rateMajor.multipliedReportingOverflow(by: Int(pow(10.0, Double(digits))))
guard !overflow else { /* show the "valid values" error */ return nil }
rateMinor = scaled
```
Do the same for `isRateBelowMinimum`, which also hard-codes `* 100`. Alternatively reject typed edits when `currency` is outside `allowedCurrencies`, until Phase 6 (EXP-02) lands decimal input.

### WR-04: `PI_CURRENCY_MISMATCH` is declared but not handled in the paid-booking error path (outside phase plans: e43ef50/73e729e)

**File:** `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift:581-640` (`handlePaidFlowError`), `ClickMe2026/Model/Enums/ErrorCode.swift` (`piCurrencyMismatch`)
**Issue:** Commit 73e729e adds `ErrorCode.piCurrencyMismatch` and documents it: "the intent is stale. Discard it and restart from `POST /bookings/payment-intent`". The paid flow never branches on it. It falls into `default:`, which shows the server message plus a "Payment reference" line (the user is told a payment reference exists for a booking that failed) and does not call `newBookingAttempt()`. The retry then reuses the same `booking_attempt_id`. The backend builds the PaymentIntent idempotency key from that id (`booking.controller.js:543`), so the retry either replays the stale intent or hits the Stripe idempotency conflict (`BOOKING_ATTEMPT_CONFLICT`, line 588) before it recovers. The user sees two failures where the contract wants a clean restart.
**Fix:** Handle it with the other stale-intent codes:
```swift
case .intentExpired, .piContextMismatch, .piAmountMismatch, .piCurrencyMismatch:
    newBookingAttempt()
    bookingError = message
    resetPaidFlow()
```

## Info

### IN-01: Dead production helper and stale "hide" wording after the dim-not-hide decision

**File:** `ClickMe2026/Utils/PaidBookingWindow.swift:19-21, 33-41`
**Issue:** `PaidBookingWindow.isDayBeyond` has no production caller. The only references are in `PaidBookingWindowTests.swift`. User decision 1 keeps the days visible and dims the slots, so the helper that exists to "hide the whole day" is dead code that tests keep alive. The type doc ("The picker uses this to hide what the server would refuse") and the `BookingErrorMapper` doc still describe hiding.
**Fix:** Delete `isDayBeyond` and its test rows, or note that it is unused. Reword the doc comments to say "dim".

### IN-02: `logout()` gives no feedback for up to 3 s while the user is still signed in

**File:** `ClickMe2026/Managers/UserManager.swift:340-358`
**Issue:** Per D-06 the unregister call is awaited before the session is cleared. On a slow or offline network the Log out tap does nothing visible for up to 3 s. The app stays fully signed in, the socket stays connected, and a second tap is silently ignored by the `isLoggingOut` guard. Functionally correct and accepted by design, but the user cannot tell the tap registered.
**Fix:** Expose `isLoggingOut` (already `private(set)`) to the profile screens and disable the button or show a spinner while it is true.

### IN-03: Currency symbol is "US$" on the price label and "$" in the hint, on the same screen (outside phase plans: e43ef50/73e729e)

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift:107-113` (`currencySymbol`) versus `Money.swift:34-42`
**Issue:** `currencySymbol` returns `US$` for USD, so the label reads "Price per Session (US$)". The minimum hint and message go through `Money`, where USD is `$` (D-10), so the same screen says "min $5.00". Two spellings of one currency on one form.
**Fix:** Derive the label symbol from `Money.prefix(for: currency)`, or add `US$` to `Money`'s table only if product wants that everywhere. The CLAUDE.md rule is one shared formatter.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
