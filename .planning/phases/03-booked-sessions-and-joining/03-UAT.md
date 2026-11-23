---
status: partial
phase: 03-booked-sessions-and-joining
source: [03-VERIFICATION.md]
started: 2026-11-11T06:30:00Z
updated: 2026-11-23T05:07:53.464Z
---

## Current Test

[testing complete]

## Tests

### 1. Run the 26 device checks in 03-DEVICE-UAT-CHECKLIST.md on a real iPhone
expected: Every item records PASS. JOIN CALL works from every entry. The end + 55 notice shows on the Skype/Zoom layout. The expert cancel sheet line is right for a live hold, a captured booking, a free booking and a converted long-lead booking.
result: issue
reported: "Note a bug for the backend. The notification received on phone A says \"booking has been rescheduled,\" but it should word it as a reschedule request of some sort."
severity: minor
reported_2: "For step, the decline message of the emoji cannot be seen by the other user because the UI does not display the reason for the decline, nor is it added to the chat."
severity_2: major
note: "Device run resumed 2026-11-19 (previously blocked: physical-device). Per-item results are in 03-DEVICE-UAT-CHECKLIST.md. Paused 2026-11-19 by user after item 6: items 1 FAIL (3 backend gaps; rest passed), 2/3/5/6 PASS, 4 SKIPPED (no VoiceOver testing), 7-24 not run. User will not test VoiceOver steps. Resumed 2026-11-22 and finished: items 7-11, 13-16, 18-22 and 24-26 PASS; 12 (no Skype/Zoom app), 17 (55-minute wait) and 23 (no smallest iPhone or Teams/Meet booking) SKIPPED. Every item has a Result. Item 14 found gap G-03-1-ITEM14. 2026-11-23: item 27 (added by 03-18, the G-03-1-ITEM14 fix) PASS on device. 2026-11-23: re-test of item 1's failed parts (ITEM1/1B/1C, fixed in Phase 8) BLOCKED (user: \"blocked\"); still to run on two devices."
reported_3: "log the decline-push bug"
severity_3: major
reported_4: "The iOS session summary screen does not have the price, whereas the Android version says the price or free." Then: "Yes, add \"free\" label to the iOS version."
severity_4: minor

### 2. The 11 UI-SPEC backstop truths
The checks:
- L2 Dynamic Type on the response card, the cancel block, the Skype block and the status pill
- L3 "Open in Microsoft Teams" fits on one line
- D2 toast position and VoiceOver
- D3 the Skype handoff
- D4 expert Join with two accounts
- 03-13 Booking Summary accept/decline parity
- 03-03 end + 55 on a device

expected: Text wraps without clipping at the largest accessibility size. The toast sits 24 pt above the tab bar and VoiceOver speaks it. Both parties connect on a call.
result: skipped
reason: "Run on a device 2026-11-22 through the 03-DEVICE-UAT-CHECKLIST.md items: L2 (22), D2 minus VoiceOver (21), D3 (15), D4 (19) and 03-13 parity (1) PASS. L3 (23) and end + 55 (17) were skipped by the user, and the VoiceOver checks are not tested by user decision."

### 3. Decide whether to fix code-review findings WR-01 and WR-02 before the Phase 8 release
- WR-01: after an accept or decline, if the refresh fails, the response card stays on screen.
- WR-02: the cancel toast says a refund is coming when the server refunded 0.

expected: Each one has a fix or a skip recorded in 03-REVIEW-DISPOSITION.md.
result: issue
reported: "fix both"
severity: major

### 4. Android BOOK-20: run BookingSummaryScreenTest, then decide when to push commit 0f2e8cd
expected: bookingIdShowsInTheShortFormat and fullUuidBookingIdMatchesIos pass, and the commit is pushed with the Android release.
result: pass
note: "Ran 2026-11-11: :app:testProdDebugUnitTest BookingSummaryScreenTest 34/34 pass (both named tests included). 0f2e8cd ships with the Android release (local main is 2108 commits ahead of origin; not pushed in this session)."

### 5. Run the carried-over prerequisites: Phase 2 UAT tests 6-17 and the BACK-19 production smoke
expected: Both run before Phase 8. Until the BACK-19 smoke runs, the EXP-11 expert refund-or-release copy is verified in code only.
result: blocked
blocked_by: prior-phase
reason: "defer" (02-UAT.md is partial with tests 7-17 pending and test 6 skipped; BACK-19 smoke from 01-19 still unrun). Update 2026-11-16: Phase 2 UAT is now complete and Phase 2 is closed; only the BACK-19 production smoke remains (Phase 4 D-11 session).

## Summary

total: 5
passed: 1
issues: 2
pending: 0
skipped: 1
blocked: 1

## Gaps

- gap_id: G-03-1-ITEM1
  truth: "When the expert proposes a new time, the client's push reads as a reschedule request awaiting their response, not as a completed reschedule"
  status: resolved
  resolved_by: 08-02-PLAN.md
  resolved_at: 2026-11-22
  resolution_note: "Cross-phase: fixed by Phase 8 plan 08-02 (backend 162f1d7, proposal push reads Reschedule Requested), deployed to production 2026-11-20 in 08-08 (412f1aa). Recorded by user decision 2026-11-22."
  reason: "User reported: Note a bug for the backend. The notification received on phone A says \"booking has been rescheduled,\" but it should word it as a reschedule request of some sort."
  severity: minor
  test: 1
  repo: backend
  artifacts:
    - path: "../ClickMe2026 Backend/src/services/events.js"
      issue: "BOOKING_RESCHEDULED push uses title 'Booking Rescheduled' / body 'A booking has been rescheduled.' for a proposal (lines 398-405)"
  missing: []
- gap_id: G-03-1-ITEM1B
  truth: "Every reason or note a user gives the other party with a booking action (cancel, reschedule propose/decline, request decline/accept) becomes part of the chat; expert-private notes never do"
  scope_note: "Widened 2026-11-19 by user: 'All the reasons for actions should become part of the chat. Make a backend change for this.' Backend change started 2026-11-19 as a backend quick task (no deploy). iOS + Android chat event rows must then render the new event_data keys."
  backend_progress: "Backend done 2026-11-19, commits 94d659b (code/tests/OpenAPI) + 22b8967 (GSD docs) on backend main, NOT pushed or deployed. Adds optional event_data.reason_text + reason_by ('client'|'expert') to BOOKING_CANCELLED, BOOKING_RESCHEDULED (proposal note) and reschedule BOOKING_DECLINED. Request decline keeps decline_reason_text; accept note already posts as a chat message. Suite 3788 pass / 6 fail (redis.test.js, needs live Redis, pre-existing)."
  client_work_open: "iOS: ChatItemMapper.swift + ChatDisplayModels.swift + chat event row; read reason_text ?? decline_reason_text, label by reason_by. Android: ChatMessageMapping.kt + ChatFixtures.kt."
  noticed_not_fixed:
    - "BOOKING_DECLINED push always goes to client_id (logged as G-03-1-ITEM1C)"
    - "BOOKING_RESCHEDULED event_data has no proposed time"
    - "Reschedule decline with no reason is indistinguishable from a request decline (both BOOKING_DECLINED)"
  status: resolved
  resolved_by: 08-07-PLAN.md
  resolved_at: 2026-11-22
  resolution_note: "Cross-phase: backend 94d659b (08-02, deployed 2026-11-20 in 08-08), iOS chat rows 08-07 (4ada6e7, a153d4c; ships in the Phase 8 build), Android 8aaee356. Recorded by user decision 2026-11-22."
  reason: "User reported: For step, the decline message of the emoji cannot be seen by the other user because the UI does not display the reason for the decline, nor is it added to the chat."
  severity: major
  test: 1
  repo: backend + iOS (+ Android)
  artifacts:
    - path: "../ClickMe2026 Backend/src/controllers/clientBooking.controller.js"
      issue: "reschedule-decline reason saved to decline_reason_text (733-736) but details only expose it for status 'declined' (1123-1125)"
    - path: "../ClickMe2026 Backend/src/services/events.js"
      issue: "reschedule declines pass no reason fields into the chat/push event (191)"
  missing: []

- gap_id: G-03-3-WR01
  truth: "After a successful reschedule accept or decline, the Accept/Decline card disappears even if the follow-up booking refetch fails"
  status: resolved
  resolved_by: 03-16-PLAN.md
  resolved_at: 2026-11-16
  reason: "User reported: fix both (code-review finding WR-01, fix before the Phase 8 release)"
  severity: major
  test: 3
  root_cause: "RescheduleResponder.accept()/decline() rely on refetch() to clear the proposal; both owners implement refetch as refresh(), which swallows a failed detail GET and keeps the stale pendingProposal, so the card stays and a second money-affecting POST is possible"
  artifacts:
    - path: "ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift"
      issue: "card clearing depends on refetch success (lines 87-91, decline path too)"
    - path: "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift"
      issue: "refetch = refresh() swallows failure (262-275)"
    - path: "ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift"
      issue: "refetch = refresh() swallows failure (212-225)"
  missing:
    - "After a 2xx, clear the proposal locally (onResolved callback setting reschedule = nil in both owners) before awaiting refetch"
    - "Responder test: post-accept detail GET returns 500, assert pendingProposal == nil (and the same for decline)"
  debug_session: ".planning/phases/03-booked-sessions-and-joining/03-REVIEW.md#wr-01"
- gap_id: G-03-3-WR02
  truth: "The post-cancel toast never promises a refund amount the server did not issue"
  status: resolved
  resolved_by: 03-17-PLAN.md
  resolved_at: 2026-11-16
  reason: "User reported: fix both (code-review finding WR-02, fix before the Phase 8 release)"
  severity: major
  test: 3
  root_cause: "CancelToastMessage picks the refund wording from the device-clock preview case (.chargedRefundable) and ignores a server refund_amount of 0 (clock skew across the 24h line, refund retry, or idempotent already-cancelled 200), so it shows 'Your CA$X refund is being processed' when no refund is coming"
  artifacts:
    - path: "ClickMe2026/Utils/CancelToastMessage.swift"
      issue: "chargedRefundable branch names an amount even when the server returned 0 (lines 44-45)"
    - path: "ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift"
      issue: "passes the device-clock case into the toast (136, 159, 191-195)"
  missing:
    - "When the server returns refund_amount 0 under .chargedRefundable, show neutral wording with no amount or timing (e.g. 'Booking cancelled. Any refund due will follow our cancellation policy.')"
    - "Keep amount-specific wording only for server amounts above 0"
    - "Unit tests for the 0-under-chargedRefundable case and the already-cancelled 200 case"
  debug_session: ".planning/phases/03-booked-sessions-and-joining/03-REVIEW.md#wr-02"
- gap_id: G-03-1-ITEM1C
  truth: "When a proposed new time is declined, the push goes to the party who proposed it (the non-decliner), never to the person who declined"
  status: resolved
  resolved_by: 08-02-PLAN.md
  resolved_at: 2026-11-22
  resolution_note: "Cross-phase: fixed by Phase 8 plan 08-02 (backend 162f1d7, reschedule declines notify the proposer), deployed to production 2026-11-20 in 08-08. Recorded by user decision 2026-11-22."
  reason: "User reported: log the decline-push bug (found in backend code 2026-11-19 while fixing G-03-1-ITEM1B: a client declining the expert's proposed time gets the 'Booking Declined' push themselves; the expert gets nothing)"
  severity: major
  test: 1
  repo: backend
  artifacts:
    - path: "../ClickMe2026 Backend/src/services/events.js"
      issue: "dispatchPushForEvent case 'BOOKING_DECLINED' always calls sendPushToUser(client_id, ...) with 'Your booking request was declined.'; reschedule declines reuse BOOKING_DECLINED, so the recipient and wording are both wrong for them (BOOKING_RESCHEDULED/BOOKING_CANCELLED already route via notify_user_id)"
  missing: []
- gap_id: G-03-1-ITEM14
  truth: "The client Booking Summary always shows the price row; a free session reads \"Free\" (matching Android) instead of hiding the row"
  status: resolved
  resolved_by: 03-18-PLAN.md
  resolved_at: 2026-11-22
  reason: "User reported: The iOS session summary screen does not have the price, whereas the Android version says the price or free. User decision 2026-11-22: add the \"Free\" label to iOS."
  severity: minor
  test: 1
  repo: iOS
  artifacts:
    - path: "ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift"
      issue: "formatPrice returns nil when topic.isFree (line 379), so pricePaid is nil and the row is hidden"
    - path: "ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift"
      issue: "price row renders only when pricePaid != nil (line 116)"
  root_cause: "BookingSummaryViewModel.formatPrice returns nil for free topics and BookingSummaryExpertCard hides the price row when pricePaid is nil, so free sessions show no price line; Android always shows the row with Free"
  missing:
    - "Show the price row for free sessions with the label Free (match Android PriceText), keeping paid formatting unchanged"
    - "Unit test: a free topic yields the Free display; a paid topic is unchanged"
  android_note: "Android already shows Free (BookingSummaryCard.kt PriceText); no Android change needed"
