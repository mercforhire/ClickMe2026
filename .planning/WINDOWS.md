---
schema_version: 1
open_count: 37
waived_count: 0
fixed_count: 7
total_count: 44
last_updated: 2026-11-18T15:34:23.215Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | deviation | tests/services/redis.test.js |  | 01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-08T17:25:53.004Z | 2026-11-09T03:13:09.560Z |
| 2 | 01 | deviation | tests/services/redis.test.js |  | 01-15 wave-2 gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T00:17:57.404Z | 2026-11-09T03:13:09.645Z |
| 3 | 01 | deviation | src/services/connectedPaymentMethodClone.js |  | 01-16 D-13 local Stripe test-mode run dropped by user decision (Open Q7); Stripe behavior verified with mocks only until the 01-17 real-card smoke | open |  | 2026-11-09T00:28:14.347Z |  |
| 4 | 01 | deviation | tests/services/redis.test.js |  | 01-17 wave-3a gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T00:34:49.908Z | 2026-11-09T03:13:09.727Z |
| 5 | 01 | unrun-verify | .planning/phases/01-backend-fixes/01-17-SUMMARY.md |  | 01-17 wave-3a real-card smoke not run (user skip 2026-11-08): BACK-06/BACK-07 stay Pending; real clone detach never run against real Stripe; run the 01-17 checklist, at the latest during Phase 4 payment UAT | open |  | 2026-11-09T01:00:39.518Z |  |
| 6 | 01 | deviation | .planning/phases/01-backend-fixes/01-18-SUMMARY.md |  | 01-18 BACK-19 D-13 deviation: verified with mocked Stripe only; the captured refund branch has never run against real Stripe and cannot be reached safely on live data | open |  | 2026-11-09T01:06:43.406Z |  |
| 7 | 01 | unrun-verify | tests/services/redis.test.js |  | 01-18 wave-3b gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T01:06:43.491Z | 2026-11-09T03:13:09.809Z |
| 8 | 01 | fixme | src/controllers/expertBooking.controller.js |  | 01-18 BACK-19: a failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI instead of a refund and the client is not refunded. User chose option A (2026-11-08): the fix needs its own plan and deploy before Phase 4 payment UAT, and that plan still needs creating; see deferred-items.md | fixed |  | 2026-11-09T01:06:43.585Z | 2026-11-09T05:33:41.054Z |
| 9 | 01 | deviation | tests/services/redis.test.js |  | 01-19 wave-3b gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T01:16:27.446Z | 2026-11-09T03:13:09.890Z |
| 10 | 01 | fixme | src/controllers/clientBooking.controller.js |  | 01-19: client cancel within 24h with a retrievePI failure leaves the hold with no flag and no retry until the authorization lapses; see deferred-items.md | fixed |  | 2026-11-09T01:16:27.542Z | 2026-11-09T05:33:41.136Z |
| 11 | 01 | unrun-verify | .planning/phases/01-backend-fixes/01-19-SUMMARY.md |  | 01-19 wave-3b production smoke not run (user skip 2026-11-08): BACK-19 stays Pending; expert-cancel hold release not confirmed on production; run the 01-19 checklist, at the latest during Phase 4 payment UAT | open |  | 2026-11-09T02:16:24.413Z |  |
| 12 | 01 | unmet-truth | .planning/phases/01-backend-fixes/01-23-SUMMARY.md |  | 01-23 wave 3c dropped by user decision (2026-11-08): BACK-08 and BACK-13 not delivered; silent client-to-expert promotion and the tax-ID prompt remain in production; code parked on local backend branch wave-3c; needs a new decision | open |  | 2026-11-09T03:13:09.977Z |  |
| 13 | 02 | unrun-verify | .planning/phases/02-shared-ios-plumbing/02-05-SUMMARY.md |  | 02-05 BOOK-10 device check not run (user approve and defer 2026-11-09): CAD topic 12.50 shows CA$12.50 and 12.00 shows CA$12.00 on Make a Booking, Explore, Expert Profile, Payment History; add to 02-12 device UAT checklist — Carried into 02-DEVICE-UAT-CHECKLIST.md item 6 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T04:09:27.895Z |  |
| 14 | 02 | deviation | ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift |  | 02-08: user-directed Android parity for the paid 6-day cap (days visible, slots dimmed, fixed note) supersedes the 02-07/02-08 blank-day rule; 02-UI-SPEC section 4 and W1-9/W1-10 need revising — Carried into 02-DEVICE-UAT-CHECKLIST.md item 7 (and the 'UI-SPEC needs revision' preamble note) by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T04:38:43.121Z |  |
| 15 | 02 | unrun-verify | ClickMe2026/Managers/PushRouter.swift |  | 02-10 PUSH-01 device check deferred (user, at the Task 1 tracer gate): backgrounded client-mode app, expert accepts a pending request, tap the booking-confirmed push; expected Bookings tab opens that booking with no warning page and Back returns to My Bookings. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 10 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T05:04:00.631Z |  |
| 16 | 02 | unrun-verify | .planning/phases/02-shared-ios-plumbing/02-06-SUMMARY.md |  | 02-06 BOOK-10 expert device check not run (user approve and defer 2026-11-10): as an expert, Dashboard This Week earnings and available payout, Payouts available and pending balances and earnings rows, Topics tab cards, an incoming request earnings, the request-decision breakdown lines and Upcoming Bookings card earnings all show CA$x.xx (never CA$12, $12 or CAD 12); open a topic priced 12.50 (set from Android): field shows 12.50, change only the title and save, card still CA$12.50; a legacy USD topic on the CAD account saved with only the title changed still shows $ not CA$; add to 02-12 device UAT checklist — Carried into 02-DEVICE-UAT-CHECKLIST.md item 6 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T05:52:16.162Z |  |
| 17 | 02 | unrun-verify | ClickMe2026/Managers/PushForegroundPolicy.swift |  | 02-11 CHAT-09 device check deferred (user approve and defer, at the Task 1 tracer gate): device 1 (account B) has the chat with A open and A sends a message; expected no banner, no sound, the message appears in the thread, nothing added to Notification Center. Control: from the conversations list a second message from A shows the banner and plays the sound. Edge cases: with chat A open switch to the Bookings tab and have A send, the banner must appear (assumption A3, onDisappear on tab switch); open chat B from a push or profile on top of chat A, go back to A, then A sends: no banner (stacked chats); a non-chat push (booking) while any chat is open still shows the banner. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 15 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T06:17:02.937Z |  |
| 18 | 02 | unrun-verify | .planning/phases/02-shared-ios-plumbing/02-13-SUMMARY.md |  | 02-13 BOOK-18 client device check deferred (user approve and defer, at the Task 1 tracer gate): (1) with Upcoming Booking details open on the client, pull to refresh at the same moment the expert proposes a reschedule from another device; expected the screen ends on the rescheduled state and no spinner is left running. (2) with My Bookings open on the client, have the expert cancel or reschedule from the other device while you pull to refresh; expected the row ends in its new state and the list is not left on a spinner. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 9 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T06:32:57.972Z |  |
| 19 | 02 | unrun-verify | .planning/phases/02-shared-ios-plumbing/02-14-SUMMARY.md |  | 02-14 CALL-02 device check DEFERRED (behavior changed after the Task 1 tracer gate: Join is now shown disabled, not hidden, for non-joinable bookings, as Android does): (1) expert Dashboard strip: Join Session turns enabled on its own within about a minute of start - 60 min, with no refresh; (2) expert Dashboard strip: a pending_reschedule card shows Join visible but dimmed and disabled, and VoiceOver reads it as dimmed; (3) client Explore today strip: the same two checks for Join Call; (4) client My Bookings and expert Upcoming list: a pending_reschedule card shows Join disabled (changed by fix(02-04) a620b92). Supersedes the 02-04 deferred wording 'no Join on pending_reschedule'. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 3 and 4 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T16:49:52.107Z |  |
| 20 | 02 | unrun-verify | .planning/phases/02-shared-ios-plumbing/02-15-SUMMARY.md |  | 02-15 BOOK-10 / EXP-14 device check DEFERRED (approve and defer at the tracer gate; behavior then changed to Android parity): as an expert, open a client's profile from a booking. Confirmed, completed or other gated rows (pending_approval, pending_reschedule, in_progress) show the net earnings as CA$x.xx. Cancelled and other non-gated rows show —. No row shows $0 or CA$0.00 unless the net really is zero. The layout is unchanged. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 6 by 02-12 (2026-11-10); stays open until run on device | open |  | 2026-11-10T17:16:48.018Z |  |
| 21 | 02 | unrun-verify | ClickMe2026/Managers/PushTokenCleanup.swift |  | 02-12 PUSH-04 device check DEFERRED (user approve and defer at the Task 1 tracer gate, 2026-11-10): sign in as A, log out from Profile, from another device send A a chat message; expected nothing arrives on the logged-out device. Plus the Task 2 paths: airplane-mode logout then relaunch and sign in as B (B gets B's pushes, A's do not arrive; residual window before the retry accepted under D-17/D-18) and an involuntary logout if a safe production trigger exists. Carried into 02-DEVICE-UAT-CHECKLIST.md item 14 | open |  | 2026-11-10T17:42:26.359Z |  |
| 22 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift |  | PAY-01 device check (close sheet with saved card preselected places no hold; Link off) not run; belongs to the D-11 session in plan 04-14 | open |  | 2026-11-12T04:40:17.963Z |  |
| 23 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentPopGestureLock.swift |  | 04-03 device check (UAT D2, BOOK-01/BOOK-19): no Back on Request Sent, edge and iOS 26 content swipe do not pop from each source tab (Explore, Search, Profile>Favorites, chat View Profile), exits reset the source tab; swipe-back still works on other screens afterwards | open |  | 2026-11-12T04:46:26.094Z |  |
| 24 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift |  | 04-03 device check (UAT L1, E1, BOOK-05): slow network shows 'Loading booking…' with both exits pinned; airplane-mode error state shows Retry and both exits | open |  | 2026-11-12T04:46:26.205Z |  |
| 25 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift |  | 04-04 device check (UAT BOOK-03, BOOK-04, D-18, T1-T4): with 24-Hour Time on, slot chips, Today's Sessions, Reschedule picker and Request Sent show 14:00-style times; slots card and Today's Sessions title say the zone in words (never America/Toronto); toggle 24-Hour Time off while app is open and return: 2:00 PM style; fast month taps always match the shown month; empty day and failed month keep their copy | open |  | 2026-11-12T04:55:04.962Z |  |
| 26 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift |  | 04-05 device check (UAT EXPL-01, L3, EXPL-05): airplane mode on, open a profile: 'Couldn't load profile' with Retry and no heart or menu; network back on, Retry shows a spinner then the profile; a deleted or suspended expert shows 'This profile isn't available' with only Back (pops one level); heart matches is_favorite for a favorited expert; no /client/favorites call on open | open |  | 2026-11-12T05:03:15.847Z |  |
| 27 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift |  | 04-06 device check (UAT EXPL-05, D-07, D-09): with more than 20 favorites, scroll to the end: a spinner appears, then the rest load with no repeats and nothing shows at the end; airplane mode before the next page: footer 'Couldn't load more favorites' with Retry, earlier rows stay, Retry after network back appends the page; pull to refresh restarts at page 1; unfavorite a row then scroll to the end: list returns to the first 20 and no favorite is skipped; Pro Tip (shown with no favorites) says 'heart' | open |  | 2026-11-12T05:11:40.658Z |  |
| 28 | 04 | unrun-verify | ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift |  | D-13 / UI-SPEC D4: suspension alert on a real cold launch (suspended account lands on Login, alert shows once, Close Alert clears the flag); device check in the Phase 8 release pass | open |  | 2026-11-12T05:16:40.722Z |  |
| 29 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift |  | PAY-02 / D-03 / D-11 (UAT L2, E2): airplane mode during Confirming, wait for the We couldn't confirm your booking alert, restore the network, tap Try again: Request Sent opens for that same booking, My Bookings shows one booking and Stripe shows one hold; also once let a retry succeed on its own; 409 PAYMENT_IN_PROGRESS (D-17) cannot be forced on a device, proven by unit tests only; device check in the 04-14 session | open |  | 2026-11-12T05:30:54.623Z |  |
| 30 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift |  | PAY-03 / UI-SPEC D3 (D-11 session): a new paid booking's Request Sent shows 'A hold is placed on your card' with the session time in step 2; a free booking shows no payment card. Variants B and C (older long-lead and charged rows) are unit-tested and previewed only | open |  | 2026-11-12T05:36:51.007Z |  |
| 31 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift |  | 04-10 device check (UAT EXPL-05, D-08, N2): empty Favorites -> Explore Experts opens Explore, Profile back at root; View My History opens Bookings on Past, Profile back at root | open |  | 2026-11-12T05:43:19.260Z |  |
| 32 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift |  | 04-11 device check (UAT EXPL-06, D-07): expert with more than 20 reviews scrolls through every review with the spinner footer; airplane mode on a later page shows Couldn't load more reviews with a 44 pt Retry; pull-to-refresh keeps the rows when offline | open |  | 2026-11-12T05:50:56.788Z |  |
| 33 | 04 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift |  | 04-11 device check (UAT EXPL-04, L5, LT1): search an expert with a 60 character tag and a non-Latin tag; every pill shows its whole text and wraps inside the pill at the largest Dynamic Type size; Favorites chips and expert topic setup chips look as before | open |  | 2026-11-12T05:50:56.918Z |  |
| 34 | 04 | unrun-verify | .planning/phases/04-booking-payment-and-discovery/04-13-PLAN.md |  | 04-13 PAY-02 D-04/D-15 device check (UAT E5, 04-14 D-11 session): after the confirm-unknown alert tap Not now then Book Now on the same slot and land on Request Sent for the existing booking; a slot someone else holds still shows the plain slot-taken alert; SwiftUI alert layout (Check My Bookings, Close Alert) unseen on device | open |  | 2026-11-12T06:01:27.372Z |  |
| 35 | 04 | unrun-verify | .planning/phases/04-booking-payment-and-discovery/04-12-PLAN.md |  | 04-12 EXPL-02 and EXPL-05 device check not run (user chose fix-now 2026-11-12, device check deferred to the 04-14 UAT list): chat View Profile for an expert with no reviews shows no Expertise header, no empty Recent Reviews card, no blank gap and 'No reviews yet' in the hero (compare before on the App Store build); one review shows '(1 review)'; a profile opened from Favorites shows a filled heart from the first frame while one opened from Search starts empty | open |  | 2026-11-12T15:02:14.464Z |  |
| 36 | 06 | unrun-verify | ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift |  | 06-07 device checks D4, OV2, LT1, EM2 (swipe never pops, Back prompts when dirty, counter above keyboard, 5,000 cap on paste, TextEditor shows the cut text) not run; belongs in 06-DEVICE-UAT-CHECKLIST.md | open |  | 2026-11-16T18:36:00.126Z |  |
| 37 | 07 | unrun-verify | ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift |  | 07-02 Task 1 human-check deferred to end-of-phase UAT: C1 second half and C8 on two iPhones (tap-to-retry delivers once, long-press Delete, VoiceOver actions) | open |  | 2026-11-18T05:27:16.006Z |  |
| 38 | 07 | unrun-verify | ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift |  | 07-02 Task 2 human-check deferred to end-of-phase UAT: C2 and counter part of C8 (paste over 10,000, counter, VoiceOver announcement once) | open |  | 2026-11-18T05:27:16.103Z |  |
| 39 | 07 | unrun-verify | ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift |  | 07-03 Task 2 device check C6 (open-clears, two accounts, cold-launch push open, Load earlier twice) deferred to end-of-phase UAT | open |  | 2026-11-18T05:42:11.755Z |  |
| 40 | 07 | unrun-verify | ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift |  | 07-04 Task 3 device checks C4, C5, C9 (banner) and C8 (banner): two accounts, block/unblock, B sends while blocked, largest text size and VoiceOver; deferred to end-of-phase UAT | open |  | 2026-11-18T06:03:49.550Z |  |
| 41 | 7 | unrun-verify | ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatView.swift |  | 07-05 Task 2 human-check deferred to end-of-phase UAT: Block & Report card rows, reason picker order, 1000/1000 counter and a live report on two accounts (device checks C3, C4 card part, report part) | open |  | 2026-11-18T06:19:17.017Z |  |
| 42 | 7 | unrun-verify | ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift |  | 07-06 Task 2 human-check deferred to end-of-phase UAT: profile Block alert, Blocking scrim with VoiceOver, You blocked {name} toast placement and a live block on two accounts (device checks C3 profile part, C7) | open |  | 2026-11-18T06:34:16.857Z |  |
| 43 | 7 | unrun-verify | ClickMe2026/Views/Screens/Chat/Conversations/Subviews/ChatConversationRow.swift |  | 07-07 Task 2 human-check deferred to end-of-phase UAT: unread pill 1, 4, 99+, bold brighter preview, name bold in both states (A9), clears on open by row, push and profile, no Chats tab badge, VoiceOver one element with unread clause (device checks C6 badge part, C8 row) | open |  | 2026-11-18T06:46:05.128Z |  |
| 44 | 7 | unrun-verify | ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift |  | 07-09 Task 2 device check deferred to end-of-phase UAT: as the test expert on a real iPhone (build at or after 491b600), tapping a chat booking row opens the expert Booking Summary with no load error, for active and finished bookings; as the test client the same row still opens the client's booking screens (device check C10 after-step, item 14) | open |  | 2026-11-18T15:34:23.215Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-08T17:25:53.004Z",
    "resolved_at": "2026-11-09T03:13:09.560Z",
    "milestone": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-15 wave-2 gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T00:17:57.404Z",
    "resolved_at": "2026-11-09T03:13:09.645Z",
    "milestone": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "01",
    "file": "src/services/connectedPaymentMethodClone.js",
    "line": null,
    "description": "01-16 D-13 local Stripe test-mode run dropped by user decision (Open Q7); Stripe behavior verified with mocks only until the 01-17 real-card smoke",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T00:28:14.347Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-17 wave-3a gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T00:34:49.908Z",
    "resolved_at": "2026-11-09T03:13:09.727Z",
    "milestone": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-17-SUMMARY.md",
    "line": null,
    "description": "01-17 wave-3a real-card smoke not run (user skip 2026-11-08): BACK-06/BACK-07 stay Pending; real clone detach never run against real Stripe; run the 01-17 checklist, at the latest during Phase 4 payment UAT",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T01:00:39.518Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-18-SUMMARY.md",
    "line": null,
    "description": "01-18 BACK-19 D-13 deviation: verified with mocked Stripe only; the captured refund branch has never run against real Stripe and cannot be reached safely on live data",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.406Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-18 wave-3b gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.491Z",
    "resolved_at": "2026-11-09T03:13:09.809Z",
    "milestone": null
  },
  {
    "id": 8,
    "kind": "fixme",
    "phase": "01",
    "file": "src/controllers/expertBooking.controller.js",
    "line": null,
    "description": "01-18 BACK-19: a failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI instead of a refund and the client is not refunded. User chose option A (2026-11-08): the fix needs its own plan and deploy before Phase 4 payment UAT, and that plan still needs creating; see deferred-items.md",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.585Z",
    "resolved_at": "2026-11-09T05:33:41.054Z",
    "milestone": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-19 wave-3b gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:16:27.446Z",
    "resolved_at": "2026-11-09T03:13:09.890Z",
    "milestone": null
  },
  {
    "id": 10,
    "kind": "fixme",
    "phase": "01",
    "file": "src/controllers/clientBooking.controller.js",
    "line": null,
    "description": "01-19: client cancel within 24h with a retrievePI failure leaves the hold with no flag and no retry until the authorization lapses; see deferred-items.md",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:16:27.542Z",
    "resolved_at": "2026-11-09T05:33:41.136Z",
    "milestone": null
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-19-SUMMARY.md",
    "line": null,
    "description": "01-19 wave-3b production smoke not run (user skip 2026-11-08): BACK-19 stays Pending; expert-cancel hold release not confirmed on production; run the 01-19 checklist, at the latest during Phase 4 payment UAT",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T02:16:24.413Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 12,
    "kind": "unmet-truth",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-23-SUMMARY.md",
    "line": null,
    "description": "01-23 wave 3c dropped by user decision (2026-11-08): BACK-08 and BACK-13 not delivered; silent client-to-expert promotion and the tax-ID prompt remain in production; code parked on local backend branch wave-3c; needs a new decision",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T03:13:09.977Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 13,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-shared-ios-plumbing/02-05-SUMMARY.md",
    "line": null,
    "description": "02-05 BOOK-10 device check not run (user approve and defer 2026-11-09): CAD topic 12.50 shows CA$12.50 and 12.00 shows CA$12.00 on Make a Booking, Explore, Expert Profile, Payment History; add to 02-12 device UAT checklist — Carried into 02-DEVICE-UAT-CHECKLIST.md item 6 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T04:09:27.895Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "02",
    "file": "ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift",
    "line": null,
    "description": "02-08: user-directed Android parity for the paid 6-day cap (days visible, slots dimmed, fixed note) supersedes the 02-07/02-08 blank-day rule; 02-UI-SPEC section 4 and W1-9/W1-10 need revising — Carried into 02-DEVICE-UAT-CHECKLIST.md item 7 (and the 'UI-SPEC needs revision' preamble note) by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T04:38:43.121Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 15,
    "kind": "unrun-verify",
    "phase": "02",
    "file": "ClickMe2026/Managers/PushRouter.swift",
    "line": null,
    "description": "02-10 PUSH-01 device check deferred (user, at the Task 1 tracer gate): backgrounded client-mode app, expert accepts a pending request, tap the booking-confirmed push; expected Bookings tab opens that booking with no warning page and Back returns to My Bookings. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 10 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T05:04:00.631Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 16,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-shared-ios-plumbing/02-06-SUMMARY.md",
    "line": null,
    "description": "02-06 BOOK-10 expert device check not run (user approve and defer 2026-11-10): as an expert, Dashboard This Week earnings and available payout, Payouts available and pending balances and earnings rows, Topics tab cards, an incoming request earnings, the request-decision breakdown lines and Upcoming Bookings card earnings all show CA$x.xx (never CA$12, $12 or CAD 12); open a topic priced 12.50 (set from Android): field shows 12.50, change only the title and save, card still CA$12.50; a legacy USD topic on the CAD account saved with only the title changed still shows $ not CA$; add to 02-12 device UAT checklist — Carried into 02-DEVICE-UAT-CHECKLIST.md item 6 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T05:52:16.162Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 17,
    "kind": "unrun-verify",
    "phase": "02",
    "file": "ClickMe2026/Managers/PushForegroundPolicy.swift",
    "line": null,
    "description": "02-11 CHAT-09 device check deferred (user approve and defer, at the Task 1 tracer gate): device 1 (account B) has the chat with A open and A sends a message; expected no banner, no sound, the message appears in the thread, nothing added to Notification Center. Control: from the conversations list a second message from A shows the banner and plays the sound. Edge cases: with chat A open switch to the Bookings tab and have A send, the banner must appear (assumption A3, onDisappear on tab switch); open chat B from a push or profile on top of chat A, go back to A, then A sends: no banner (stacked chats); a non-chat push (booking) while any chat is open still shows the banner. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 15 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T06:17:02.937Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 18,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-shared-ios-plumbing/02-13-SUMMARY.md",
    "line": null,
    "description": "02-13 BOOK-18 client device check deferred (user approve and defer, at the Task 1 tracer gate): (1) with Upcoming Booking details open on the client, pull to refresh at the same moment the expert proposes a reschedule from another device; expected the screen ends on the rescheduled state and no spinner is left running. (2) with My Bookings open on the client, have the expert cancel or reschedule from the other device while you pull to refresh; expected the row ends in its new state and the list is not left on a spinner. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 9 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T06:32:57.972Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 19,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-shared-ios-plumbing/02-14-SUMMARY.md",
    "line": null,
    "description": "02-14 CALL-02 device check DEFERRED (behavior changed after the Task 1 tracer gate: Join is now shown disabled, not hidden, for non-joinable bookings, as Android does): (1) expert Dashboard strip: Join Session turns enabled on its own within about a minute of start - 60 min, with no refresh; (2) expert Dashboard strip: a pending_reschedule card shows Join visible but dimmed and disabled, and VoiceOver reads it as dimmed; (3) client Explore today strip: the same two checks for Join Call; (4) client My Bookings and expert Upcoming list: a pending_reschedule card shows Join disabled (changed by fix(02-04) a620b92). Supersedes the 02-04 deferred wording 'no Join on pending_reschedule'. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 3 and 4 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T16:49:52.107Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 20,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-shared-ios-plumbing/02-15-SUMMARY.md",
    "line": null,
    "description": "02-15 BOOK-10 / EXP-14 device check DEFERRED (approve and defer at the tracer gate; behavior then changed to Android parity): as an expert, open a client's profile from a booking. Confirmed, completed or other gated rows (pending_approval, pending_reschedule, in_progress) show the net earnings as CA$x.xx. Cancelled and other non-gated rows show —. No row shows $0 or CA$0.00 unless the net really is zero. The layout is unchanged. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md — Carried into 02-DEVICE-UAT-CHECKLIST.md item 6 by 02-12 (2026-11-10); stays open until run on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T17:16:48.018Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 21,
    "kind": "unrun-verify",
    "phase": "02",
    "file": "ClickMe2026/Managers/PushTokenCleanup.swift",
    "line": null,
    "description": "02-12 PUSH-04 device check DEFERRED (user approve and defer at the Task 1 tracer gate, 2026-11-10): sign in as A, log out from Profile, from another device send A a chat message; expected nothing arrives on the logged-out device. Plus the Task 2 paths: airplane-mode logout then relaunch and sign in as B (B gets B's pushes, A's do not arrive; residual window before the retry accepted under D-17/D-18) and an involuntary logout if a safe production trigger exists. Carried into 02-DEVICE-UAT-CHECKLIST.md item 14",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T17:42:26.359Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 22,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift",
    "line": null,
    "description": "PAY-01 device check (close sheet with saved card preselected places no hold; Link off) not run; belongs to the D-11 session in plan 04-14",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T04:40:17.963Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 23,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentPopGestureLock.swift",
    "line": null,
    "description": "04-03 device check (UAT D2, BOOK-01/BOOK-19): no Back on Request Sent, edge and iOS 26 content swipe do not pop from each source tab (Explore, Search, Profile>Favorites, chat View Profile), exits reset the source tab; swipe-back still works on other screens afterwards",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T04:46:26.094Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 24,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift",
    "line": null,
    "description": "04-03 device check (UAT L1, E1, BOOK-05): slow network shows 'Loading booking…' with both exits pinned; airplane-mode error state shows Retry and both exits",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T04:46:26.205Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 25,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift",
    "line": null,
    "description": "04-04 device check (UAT BOOK-03, BOOK-04, D-18, T1-T4): with 24-Hour Time on, slot chips, Today's Sessions, Reschedule picker and Request Sent show 14:00-style times; slots card and Today's Sessions title say the zone in words (never America/Toronto); toggle 24-Hour Time off while app is open and return: 2:00 PM style; fast month taps always match the shown month; empty day and failed month keep their copy",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T04:55:04.962Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 26,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift",
    "line": null,
    "description": "04-05 device check (UAT EXPL-01, L3, EXPL-05): airplane mode on, open a profile: 'Couldn't load profile' with Retry and no heart or menu; network back on, Retry shows a spinner then the profile; a deleted or suspended expert shows 'This profile isn't available' with only Back (pops one level); heart matches is_favorite for a favorited expert; no /client/favorites call on open",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:03:15.847Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 27,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift",
    "line": null,
    "description": "04-06 device check (UAT EXPL-05, D-07, D-09): with more than 20 favorites, scroll to the end: a spinner appears, then the rest load with no repeats and nothing shows at the end; airplane mode before the next page: footer 'Couldn't load more favorites' with Retry, earlier rows stay, Retry after network back appends the page; pull to refresh restarts at page 1; unfavorite a row then scroll to the end: list returns to the first 20 and no favorite is skipped; Pro Tip (shown with no favorites) says 'heart'",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:11:40.658Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 28,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift",
    "line": null,
    "description": "D-13 / UI-SPEC D4: suspension alert on a real cold launch (suspended account lands on Login, alert shows once, Close Alert clears the flag); device check in the Phase 8 release pass",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:16:40.722Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 29,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift",
    "line": null,
    "description": "PAY-02 / D-03 / D-11 (UAT L2, E2): airplane mode during Confirming, wait for the We couldn't confirm your booking alert, restore the network, tap Try again: Request Sent opens for that same booking, My Bookings shows one booking and Stripe shows one hold; also once let a retry succeed on its own; 409 PAYMENT_IN_PROGRESS (D-17) cannot be forced on a device, proven by unit tests only; device check in the 04-14 session",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:30:54.623Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 30,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift",
    "line": null,
    "description": "PAY-03 / UI-SPEC D3 (D-11 session): a new paid booking's Request Sent shows 'A hold is placed on your card' with the session time in step 2; a free booking shows no payment card. Variants B and C (older long-lead and charged rows) are unit-tested and previewed only",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:36:51.007Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 31,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Profile/ClientProfileHomeScreen.swift",
    "line": null,
    "description": "04-10 device check (UAT EXPL-05, D-08, N2): empty Favorites -> Explore Experts opens Explore, Profile back at root; View My History opens Bookings on Past, Profile back at root",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:43:19.260Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 32,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift",
    "line": null,
    "description": "04-11 device check (UAT EXPL-06, D-07): expert with more than 20 reviews scrolls through every review with the spinner footer; airplane mode on a later page shows Couldn't load more reviews with a 44 pt Retry; pull-to-refresh keeps the rows when offline",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:50:56.788Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 33,
    "kind": "unrun-verify",
    "phase": "04",
    "file": "ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift",
    "line": null,
    "description": "04-11 device check (UAT EXPL-04, L5, LT1): search an expert with a 60 character tag and a non-Latin tag; every pill shows its whole text and wraps inside the pill at the largest Dynamic Type size; Favorites chips and expert topic setup chips look as before",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T05:50:56.918Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 34,
    "kind": "unrun-verify",
    "phase": "04",
    "file": ".planning/phases/04-booking-payment-and-discovery/04-13-PLAN.md",
    "line": null,
    "description": "04-13 PAY-02 D-04/D-15 device check (UAT E5, 04-14 D-11 session): after the confirm-unknown alert tap Not now then Book Now on the same slot and land on Request Sent for the existing booking; a slot someone else holds still shows the plain slot-taken alert; SwiftUI alert layout (Check My Bookings, Close Alert) unseen on device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T06:01:27.372Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 35,
    "kind": "unrun-verify",
    "phase": "04",
    "file": ".planning/phases/04-booking-payment-and-discovery/04-12-PLAN.md",
    "line": null,
    "description": "04-12 EXPL-02 and EXPL-05 device check not run (user chose fix-now 2026-11-12, device check deferred to the 04-14 UAT list): chat View Profile for an expert with no reviews shows no Expertise header, no empty Recent Reviews card, no blank gap and 'No reviews yet' in the hero (compare before on the App Store build); one review shows '(1 review)'; a profile opened from Favorites shows a filled heart from the first frame while one opened from Search starts empty",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-12T15:02:14.464Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 36,
    "kind": "unrun-verify",
    "phase": "06",
    "file": "ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift",
    "line": null,
    "description": "06-07 device checks D4, OV2, LT1, EM2 (swipe never pops, Back prompts when dirty, counter above keyboard, 5,000 cap on paste, TextEditor shows the cut text) not run; belongs in 06-DEVICE-UAT-CHECKLIST.md",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-16T18:36:00.126Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 37,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift",
    "line": null,
    "description": "07-02 Task 1 human-check deferred to end-of-phase UAT: C1 second half and C8 on two iPhones (tap-to-retry delivers once, long-press Delete, VoiceOver actions)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T05:27:16.006Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 38,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift",
    "line": null,
    "description": "07-02 Task 2 human-check deferred to end-of-phase UAT: C2 and counter part of C8 (paste over 10,000, counter, VoiceOver announcement once)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T05:27:16.103Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 39,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift",
    "line": null,
    "description": "07-03 Task 2 device check C6 (open-clears, two accounts, cold-launch push open, Load earlier twice) deferred to end-of-phase UAT",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T05:42:11.755Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 40,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift",
    "line": null,
    "description": "07-04 Task 3 device checks C4, C5, C9 (banner) and C8 (banner): two accounts, block/unblock, B sends while blocked, largest text size and VoiceOver; deferred to end-of-phase UAT",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T06:03:49.550Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 41,
    "kind": "unrun-verify",
    "phase": "7",
    "file": "ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatView.swift",
    "line": null,
    "description": "07-05 Task 2 human-check deferred to end-of-phase UAT: Block & Report card rows, reason picker order, 1000/1000 counter and a live report on two accounts (device checks C3, C4 card part, report part)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T06:19:17.017Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 42,
    "kind": "unrun-verify",
    "phase": "7",
    "file": "ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift",
    "line": null,
    "description": "07-06 Task 2 human-check deferred to end-of-phase UAT: profile Block alert, Blocking scrim with VoiceOver, You blocked {name} toast placement and a live block on two accounts (device checks C3 profile part, C7)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T06:34:16.857Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 43,
    "kind": "unrun-verify",
    "phase": "7",
    "file": "ClickMe2026/Views/Screens/Chat/Conversations/Subviews/ChatConversationRow.swift",
    "line": null,
    "description": "07-07 Task 2 human-check deferred to end-of-phase UAT: unread pill 1, 4, 99+, bold brighter preview, name bold in both states (A9), clears on open by row, push and profile, no Chats tab badge, VoiceOver one element with unread clause (device checks C6 badge part, C8 row)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T06:46:05.128Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 44,
    "kind": "unrun-verify",
    "phase": "7",
    "file": "ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift",
    "line": null,
    "description": "07-09 Task 2 device check deferred to end-of-phase UAT: as the test expert on a real iPhone (build at or after 491b600), tapping a chat booking row opens the expert Booking Summary with no load error, for active and finished bookings; as the test client the same row still opens the client's booking screens (device check C10 after-step, item 14)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-18T15:34:23.215Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
