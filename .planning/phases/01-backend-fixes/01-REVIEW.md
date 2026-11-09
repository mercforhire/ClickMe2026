---
phase: 01-backend-fixes
reviewed: 2026-11-09T03:31:10Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - src/controllers/account.controller.js
  - src/controllers/booking.controller.js
  - src/controllers/bookingRequests.controller.js
  - src/controllers/call.controller.js
  - src/controllers/chats.controller.js
  - src/controllers/clientBooking.controller.js
  - src/controllers/expert.controller.js
  - src/controllers/expertBooking.controller.js
  - src/controllers/paymentMethods.controller.js
  - src/controllers/reviews.controller.js
  - src/controllers/webhooks.controller.js
  - src/cron/longLeadChargeSweep.js
  - src/cron/noShowNotification.js
  - src/cron/reminderNotification.js
  - src/cron/reviewNudgeNotification.js
  - src/middleware/rateLimiter.js
  - src/routes/feedback.js
  - src/schemas/booking.schema.js
  - src/schemas/expertProfile.schema.js
  - src/schemas/expertTopics.schema.js
  - src/schemas/onboarding.schema.js
  - src/services/agora.js
  - src/services/chatMessages.js
  - src/services/connectedPaymentMethodClone.js
  - src/services/events.js
  - src/services/push.js
  - src/services/socket.js
  - src/services/stripe.js
  - src/services/unreadCounts.js
  - src/utils/bookingStatusSets.js
  - src/utils/pricing.js
  - src/utils/pushTargetRole.js
findings:
  critical: 1
  warning: 7
  info: 3
  total: 11
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-11-09T03:31:10Z
**Depth:** standard
**Files Reviewed:** 32 (backend repo, `2ec82af..3899d63`; paths below are relative to that repo unless marked iOS or Android)
**Status:** issues_found

## Summary

**Can this break the live clients?** One finding can, on iOS. BACK-17 sends `category` to iOS tokens, and build 6 reads `category` first. Taps on booking, session and review-nudge pushes now navigate. In client mode, the code sends those taps to a route the Bookings tab has no destination for (CR-01). The wave-1 smoke was reported as passing, so this needs a two-minute device check before anyone acts on it. I found nothing that breaks decoding, sign-in, booking, paying or joining on either client.

**Money paths.** I found no wrong amount and no double charge in the diff. BACK-07's guarantee has a gap: both apps let a client remove a card inside Stripe's sheet, which skips the new checks (WR-01). BACK-12 can leave a hold on a card that the client can no longer cancel (WR-02). The refund retry bug in `deferred-items.md` is no worse than recorded. A `retrievePI` failure on an uncaptured expert-cancel booking heals through the void retry, and only the overstated `refund_amount` remains, which is already logged.

**What this evidence is.** This is a code read only. Nothing was run on a device or against Stripe. iOS app code at `HEAD` is identical to the build 6 commit `a48c664` (`git diff` is empty for `ClickMe2026/`). Android was read at `2d04c4ce`; I did not check that against the shipped artifact.

### Contract changes checked against both clients, no break found

| Change | iOS build 6 | Android |
|--------|-------------|---------|
| New error codes (`SESSION_ALREADY_ENDED`, `PAYMENT_METHOD_IN_USE`) | Unknown code decodes to `nil`, server message shown (`StandardErrorResponse.swift`) | `ErrorCode.fromWire` returns null for unknown codes; I read the card-remove error path, not the cancel path |
| `DUPLICATE_BOOKING` from `/bookings/payment-intent` | Handled, keeps the slot; a new slot gets a new attempt id | Handled (`PaidFlowError.kt:127`) |
| Empty threads in `GET /chats` | `lastMessage`, `lastMsgAt` optional | Both nullable |
| `client_msg_id` of `booking-accept:{id}` | `String?` | `String?` |
| `duration_minutes` must equal the topic's | Sends `topic.durationMins`; `?? 30` applies only when the server sends null, which skips the check | Same |
| `notifications.meta_data` additions | `JSONValue?` | `Map<String, Any?>?` |
| `can_join` now true from T-60 | Decoded, not used for the button (local rule of start ±60 min) | Decoded, no use in main sources |
| `category` on iOS push data | **Changes behavior: CR-01** | Already routed on it |

## Narrative Findings (AI reviewer)

No structural findings or external reviewer evidence were provided, so everything below comes from direct review. Findings that predate this commit range are marked.

## Critical Issues

### CR-01: Client-mode taps on booking pushes go to a route the Bookings tab cannot show on build 6

**Update 2026-11-08: reproduced and fixed.** The user reproduced this on App Store build 6: a client-mode tap on a booking push landed on SwiftUI's yellow warning page in the Bookings tab. Backend commit `215adcb`, pushed by the user, sends `route_category` and `route_sub_category` to iOS and legacy tokens instead of `category` and `sub_category`. `/health` reports `215adcb`. User-run device results after the deploy: a new booking push on build 6 in client mode opens the app on the client home page with no warning; a chat push opens the chat screen; an Android booking push opens the right screen. Expert-mode taps on build 6 no longer navigate either. This replaces D-01's "same keys on every platform" while build 6 is in use.

**File:** `src/services/push.js:322-327`; iOS `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift:140-142,155-159,205-210`; iOS `ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsView.swift:102`

**Issue:** BACK-17 adds `category` and `sub_category` for iOS tokens. Build 6's `PushEvent` reads `category` first (`PushEvent.swift:61-65`), so pushes that used to parse to `nil`, and did nothing on tap, now reach `PushRouter`. This much was known and accepted (RESEARCH F1), but on the belief that these taps open the booking: `docs/ios/PUSH-ROUTING.md` says so, and smoke step 6 expects "each opens that booking".

The code does not do that in client mode:

- `handlePushDestination` runs `bookingsPath.push(HomeRoute.upcomingBooking(...))`, or `HomeRoute.bookingSummary(...)` for `.leaveReview`.
- The client `bookingsTab` stack contains only `MyBookingsView`, which registers `navigationDestination(for: BookingRoute.self)`. `BookingRoute` is a private enum in that file.
- `navigationDestination(for: HomeRoute.self)` exists in only three places in the client shell: Explore, Chats and Profile (`HomeClientView.swift:191,218,228`). None is inside the Bookings stack. The expert shell does register it on its Bookings stack (`HomeExpertView.swift:157`), so this is client-mode only.

**Failure scenario:** A client on build 6 taps "Booking Confirmed". The app switches to the Bookings tab and appends a `HomeRoute` value that stack cannot resolve. SwiftUI then shows a blank or warning page instead of the booking, and I expect the user can back out. I inferred the exact rendering and did not run it. This affects every `booking/*` push except `requests`, plus `session/*` and `review/nudge`, including `PAYMENT_ACTION_REQUIRED`, where the client has to act.

**Conflicting evidence:** the user reported the 14-step wave-1 smoke as "all passed" with no per-step notes (`01-10-SUMMARY.md`), and step 6 should have exposed this. Either step 6 was not exercised this way, or SwiftUI resolves the route in a way I cannot see from the code.

**Fix:** First, on build 6 in client mode, tap a Booking Confirmed push.

- **If it opens the booking:** close this finding and record how it resolved.
- **If it does not:** the iOS fix (add `.navigationDestination(for: HomeRoute.self)` to `bookingsTab`) cannot reach build 6 until the end-of-project release. The only fix for live users is on the backend: restore the old behavior for non-Android tokens and give Phase 2 its own key names.

```js
// push.js: build 6 falls back to event_type, as it did before BACK-17
data: {
  ...safeData,
  ...(isAndroid
    ? { category: String(category || ''), sub_category: String(sub_category || '') }
    : { route_category: String(category || ''), route_sub_category: String(sub_category || '') }),
  ...(resolvedRole ? { target_role: resolvedRole } : {}),
},
```

This changes the contract in D-01, so it needs a user decision. PUSH-01 would then read `route_category`. Either way, correct the "Build 6 behavior" section of `docs/ios/PUSH-ROUTING.md`.

## Warnings

### WR-01: Removing a card inside Stripe's sheet skips the BACK-07 in-use check and clone eviction

**File:** `src/controllers/paymentMethods.controller.js:278-297`; `src/services/connectedPaymentMethodClone.js:82`; iOS `.../Payment Methods/Subviews/PaymentMethodsSetupSheet.swift:52-55`; iOS `.../Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift:79-82`; Android `stripe/ClickMePaymentSheetStyle.kt:32`

**Issue:** The new checks run only on `DELETE /me/payment-methods/:id`. Both apps also give PaymentSheet the customer and an ephemeral key. Removal in the sheet is on by default in the iOS SDK in use (`allowsRemovalOfLastSavedPaymentMethod = true`), and it goes straight to Stripe. `src` has no `payment_method.detached` handler, so the backend never hears about it. `getOrCreateClonedPaymentMethod` returns a cached clone without checking the platform card.

**Failure scenario:** A booking was rescheduled past 6 days, so it was converted to a T-24h charge. The client removes that card in the sheet's edit mode. No 409 fires and no clone is evicted. At T-24h, `longLeadChargeSweep` charges the cached clone of a card the client removed. This is threat T-01-32, which the controller header lists as mitigated. Separately, clones of every card removed this way stay attached on expert accounts. Whether Android's SDK defaults the same way, and how the removal control appears on each app, was not run.

**Fix:** Handle `payment_method.detached` on the platform webhook and evict clones there. Before an off-session charge, confirm the platform card still has a customer, and if not, take the existing payment-failure path. Update the T-01-32 note to name this path.

### WR-02: BACK-12 stops a client releasing a hold on an unanswered request after its end time

**File:** `src/controllers/clientBooking.controller.js:821-825`

**Issue:** The guard applies to `pending_approval`, and its comment says the `expirePastSessions` cron settles past-end bookings. That cron does not select `pending_approval` (`SWEEP_STATUSES`, `expirePastSessions.js:73`), and Sweep C does not capture it. Only `expireBookings` handles it, at `expires_at`, which is creation plus 12 hours whatever the session time (`booking.controller.js:1000,1030`).

**Failure scenario:** A client books at 18:00 for 18:30-19:00 and the expert never answers. At 19:05, cancel returns 409 `SESSION_ALREADY_ENDED`. The hold stays until 06:00 the next day, and the card cannot be deleted either (409 `PAYMENT_METHOD_IN_USE`). Before this change the client could cancel and void. No charge results.

**Fix:** Exempt that status, and correct the comment:

```js
if (booking.status !== 'pending_approval' && Date.now() >= new Date(booking.end_time).getTime()) {
```

### WR-03: A failed client cancel can report "already cancelled", and the client may then be charged (predates this range)

**File:** `src/controllers/clientBooking.controller.js:842-856`

**Issue:** `updateErr || !updated` returns 200 "Booking is already cancelled." for any failed update, including a database error, and for a row that moved to a non-cancelled status after the read.

**Failure scenario:** A transient database error, or the expert's `confirm-connection` moving the row to `in_progress` between the read and the update. The client sees success with `refund_amount: 0`, but the booking is still live and the hold is intact. If the client then stays away and the expert joined, `expirePastSessions` treats it as a client-only no-show and Sweep C captures the full amount.

**Fix:** Throw `dbError` unless `updateErr.code === 'PGRST116'`. On zero rows, re-read the status: return the idempotent 200 only when it is `cancelled`, otherwise return 409 `INVALID_STATUS`.

### WR-04: Server unread counts can get stuck above zero, and Android displays them

**File:** `src/services/unreadCounts.js:53-58`; `src/services/socket.js:247-252`; Android `screens/chat/conversations/ConversationsUiState.kt:76-84`; iOS `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift:184,230-248`

**Issue:** The count covers every peer message in the thread that is not `read`, including all history from before BACK-18. Messages become `read` only when a client acks their ids. iOS acks only the first page, on load and on live arrival; `loadEarlier` sends no ack. Android acks what it has loaded, so older pages are acked only if the user scrolls up to them. Opening a thread recounts but marks nothing read.

**Failure scenario:** 45 messages arrive while a user is away. Opening the thread acks the newest 30 on iOS, and the server count stays at 15 for good on build 6. On Android, `displayUnread` shows `max(server, local)`, so the badge stays until the user scrolls through the history. Build 6 has no visible impact, because `ChatConversationRow` has no unread UI, but any future iOS badge inherits the backlog. Since the first recount runs on the next send or open, long-lived threads can show counts from messages acked by no one.

**Fix:** In `handleMessageRead`, also mark peer messages older than the newest acked id as read. Run a one-time backfill of historic rows in the same change, and tell Android the count is now real.

### WR-05: `target_role` is unreliable for account and chat pushes, because nearly every account holds the expert role

**File:** `src/utils/pushTargetRole.js:48-50`; `src/services/chatMessages.js:146`; `src/services/threads.js:103-110`

**Issue:** Both apps sign up with the expert role (`deferred-items.md`, BACK-08 entry), so `targetRoleForAccount` returns `expert` for almost everyone. RESEARCH's BACK-17 row said account pushes should omit the key so iOS keeps its current mode; the plan changed that. For chat, `classifyPairRoles` falls back to caller = `client_id` when both accounts hold the expert role, so `targetRoleFor(thread, recipient)` reflects who started the thread, not who is acting as the expert.

**Failure scenario:** No shipped client reads this today. Once PUSH-02 switches mode before routing, a client-only user who taps "Password changed" lands in Expert mode. A chat tap can also flip mode for no reason.

**Fix:** Before Phase 2, omit `target_role` on account pushes and chat pushes. A missing value already means "stay in the current mode" in `PUSH-ROUTING.md`. Update that doc's rules.

### WR-06: The first-join window past end time cannot be used when nobody has joined

**File:** `src/services/agora.js:131-133`; `src/cron/expirePastSessions.js:124`; `src/controllers/call.controller.js:94`

**Issue:** D-03 opens first join until `max(end, start + 60)`. Sweep A selects `confirmed` rows with `end_time < now`, with no grace, and D-04 rejects `missed`.

**Failure scenario:** A 30-minute session where nobody has connected. At most 5 minutes after the end, Sweep A marks it `missed` and voids or refunds. A client arriving at start+40 on a list loaded before the sweep still sees Join on build 6 (iOS `Model/UIModels/UpcomingBooking.swift:62-66` allows start+60), and gets 403 "This session was marked as missed." The server's rule and message disagree with the documented window, though blocking the join is the right result once the money has moved.

**Fix:** Pick one and record it. Either document that the extended window applies only when the booking is `in_progress` or `completed`, and align CALL-02 on iOS with that; or delay Sweep A's missed path to `max(end, start + 60)`, which is a money-timing change that needs its own plan.

### WR-07: A card delete can still return an error after the card is gone

**File:** `src/controllers/paymentMethods.controller.js:307,328`

**Issue:** The BACK-06 comment says a failure after the detach must not fail the request, because a retry would 404 and clients would put the removed card back. The list and promote steps follow that, but `retrieveCustomer` and `clearDefaultPaymentMethod` still throw.

**Failure scenario:** Stripe fails on `retrieveCustomer` just after a successful detach. iOS rolls the row back (`PaymentMethodsViewModel.swift:156-158`), and the retry returns 404 for a card that no longer exists.

**Fix:** Wrap both calls in the same non-fatal try/catch as the list step, and log them. `GET` already repairs a lone card's default on its next read.

## Info

### IN-01: The reconnect window depends on a stamp whose failure goes unnoticed

**File:** `src/controllers/call.controller.js:115-119`

**Issue:** supabase-js returns errors rather than throwing them, so this `try/catch` never sees a failed stamp. A party whose stamp failed is treated as a first-joiner and loses the end+60 reconnect.

**Fix:** Destructure `error` and log it.

### IN-02: The price cap is above what Stripe can charge

**File:** `src/schemas/expertTopics.schema.js:80`

**Issue:** The new limit matches the Postgres column, as its comment says. Stripe's documented limit is 8 digits (99,999,999 minor units for most currencies, not tested here), so a price between the two limits saves and then fails on every booking attempt.

**Fix:** Decide whether to add a lower cap, with per-currency care.

### IN-03: The expert cancel docblock describes a limit the code does not have

**File:** `src/controllers/expertBooking.controller.js:1112`

**Issue:** It says "at any time before the session", but expert cancel has no time guard. A `confirmed` booking can be cancelled in the gap between its end and the next Sweep A run, which voids a hold on a session that may have happened. Only the expert loses out.

**Fix:** Correct the comment, or add a guard matching BACK-12.

---

_Reviewed: 2026-11-09T03:31:10Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
