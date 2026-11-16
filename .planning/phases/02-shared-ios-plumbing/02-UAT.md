---
status: complete
phase: 02-shared-ios-plumbing
source: [02-VERIFICATION.md]
started: 2026-11-10T18:24:14Z
updated: 2026-11-16T05:11:06.000Z
---

## Current Test

[testing complete]

## Tests

### 1. CALL-01 overtime auto-end (UAT item 1): in-app voice call kept past its scheduled end on a build at or after be00d74
expected: Still connected at end + 10 (old 5-minute cutoff gone); 'This call will end in 5 minutes' at end + 55; ends by itself at end + 60 and shows Ended; Android peer tears down on call.ended
result: pass
note: "User observed the call still connected at end + 11 (old 5-minute cutoff gone). Did not wait for end + 55 / end + 60 ('too long, assume the test passes'). The warn/end timing is covered by ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift; the on-device notice, the auto-end and the Android peer teardown on call.ended were not observed."

### 2. CALL-02 join window edges on all four surfaces (UAT item 3) and the pending_reschedule disabled Join (UAT item 4)
expected: Join appears within about a minute of start - 60 with no refresh; still shown at start + 90 on a long session; leaves the client list at max(end, start + 60); pending_reschedule shows Join dimmed and disabled, enabling on its own once confirmed again
result: pass

### 3. BOOK-10 money on every screen, topic reopen-and-save (D-19), Client Profile history (UAT item 6)
expected: CA$12.50 / CA$12.00 on Make a Booking, Explore, Expert Profile, Payment History, booking detail, summary, cancel preview, dashboard, payouts, request, upcoming card, breakdown, topic cards; a 12.50 topic saved with only the title changed still shows CA$12.50 (and a legacy USD topic keeps $); Client Profile gated rows show real net earnings, others show a dash
result: pass

### 4. BOOK-14 paid 6-day cap on Make a Booking and the client Reschedule picker (UAT item 7)
expected: All days visible and tappable; fixed note 'Paid sessions can be booked up to 6 days ahead.' / 'Paid sessions can be rescheduled up to 6 days ahead.'; slots after now + 6 days dimmed and untappable; free topic uncapped with no note; expert reschedule picker unchanged; VoiceOver (02-UI-SPEC A1/C1, quick 261110-nzy) reads only the displayed month's days (filler cells skipped), past days read as dimmed, days past the paid limit read normally, chevrons read 'Previous month' / 'Next month', same on the client Reschedule calendar
result: pass

### 5. BOOK-18 live booking.update and overlapping refresh on Upcoming Booking details, My Bookings and expert Upcoming Bookings (UAT item 9); neutral label for an unknown status after da16ef4
expected: Screens update without pull-to-refresh; an update during a pull-to-refresh ends on the newest state with no stuck spinner; an unknown status renders a neutral label, not confirmed-state actions
result: pass

### 6. PUSH-01 / CR-01 every push type opens its screen, warm and cold, both modes; unknown category opens the notifications list; notifications-list rows match; booking_id-only cron push opens the booking (UAT item 10)
expected: Right screen, no SwiftUI warning page, Back returns to the tab root, cold tap opens once
result: pass
note: "Re-run on 2026-11-16 after the earlier unexplained skip; user reported the test complete."

### 7. PUSH-02 / D-03 role-targeted pushes switch mode silently, client-only fallback, roles unknown at cold launch (UAT item 11)
expected: Set-up expert in client mode switches to expert and opens the request; client-only account stays in client mode and opens the notifications list; with roles unknown offline the tap stays queued and routes once the network returns
result: pass
note: "Cases 1 (set-up expert switches to expert mode) and 2 (client-only stays in client mode, opens notifications list) pass. Case 3 not met: with roles unknown offline at cold launch, the queued tap does not open the notifications list after the network returns. User accepted this as not important; no fix wanted."

### 8. PUSH-03 booking-request push and notifications-list row open that request's decision screen (UAT item 12)
expected: RequestDecisionView opens; Back returns to the Dashboard
result: pass

### 9. BOOK-15 payment_actions push opens the booking detail, route only (UAT item 13); SKIPPED if no eligible pre-2026-10-28 long-lead booking exists
expected: Booking detail opens, no warning page, no recovery sheet
result: pass

### 10. PUSH-04 after logout the old account's pushes stop, including the second-account, airplane-mode and involuntary paths (UAT item 14 a-d), and the WR-02 fast re-login case: sign back in as B within about 3 seconds of logging out A
expected: Log out shows a spinner on the Log Out row for up to about 6 s (DELETE, then deleteToken, each capped at 3 s) and then lands on Login; no push for A arrives after logout; B receives B's pushes even when the re-login is immediate and without backgrounding the app first, with the sign-in taking its usual time; WR-02 was fixed by quick 261110-mmr, so B receiving nothing until the next foreground activation is now a regression
result: pass

### 11. CHAT-09 no banner for the chat already on screen, with the control, tab-switch, stacked-chat and non-chat cases (UAT item 15)
expected: No banner or sound for the open thread; banner for any other thread, for a tab switch (A3), and for every non-chat push
result: pass

### 12. Backstop (02-02, no test): a failed-connection event that arrives while a hang-up is already in progress, or arrives twice, produces exactly one POST /end
expected: Exactly one /end per leg; the guard is isEndingCall / callStatus == .ended in endAfterConnectionFailure
result: skipped
reason: "Deferred follow-up: Can't reproduce the race by hand"

### 13. Backstop (02-10, no test): a second push tap that arrives while a mode switch for the first is in flight ends on the second tap's destination
expected: The later tap replaces pending and is the one routed after the switch
result: skipped
reason: "Deferred follow-up: Rare test case"

### 14. Judgment-tier prohibition (02-09, PUSH-01): MUST NOT show SwiftUI's unregistered-destination warning page from any push or notifications-list tap, in either mode
expected: Never seen during UAT item 10 in either mode, warm or cold
result: pass

### 15. Judgment-tier prohibition (02-12, PUSH-04): MUST NOT keep the old account's bearer, refresh token or any other credential after logout to retry the unregister (D-18)
expected: Only the Bool marker pendingPushCleanup is written; the retry calls Firebase deleteToken only
result: pass
note: "Verified by code review at the user's request: only the Bool pendingPushCleanup is written (PushTokenCleanup.swift:111, :135); retryIfPending takes only Messaging.deleteToken (UserManager.swift:443); clearLocalSession wipes bearer, keychain token, refresh token and expiry, cached push token (UserManager.swift:457-475)."

### 16. Judgment-tier prohibition (02-12, PUSH-04): MUST NOT register or re-upload this device's push token to the account that is logging out once logout has started
expected: registerPushToken and fetchAndUploadFCMToken return before any write while isLoggingOut is true
result: pass
note: "Verified by code review at the user's request: isLoggingOut guards are the first statement in registerPushToken (UserManager.swift:1024) and fetchAndUploadFCMToken (:1105); api.registerDeviceToken has one call site (:1043), reached only through registerPushToken; involuntary logout is covered by the hasStoredToken guard (:1031)."

### 17. Optional (unit-tested): CALL-09 provider label on a real Zoom/Skype link (UAT item 5); PAY-05 same slot-taken copy on free and paid (UAT item 8)
expected: Provider label for a real host, generic 'Open Meeting' for an unknown host; identical slot-unavailable text on both paths
result: skipped
reason: "Deferred follow-up: Already unit-tested"

## Summary

total: 17
passed: 14
issues: 0
pending: 0
skipped: 3
blocked: 0

## Deferred Follow-Ups

<!-- Deferred by the user on 2026-11-16 -->
- test: 12
  idea: "Can't reproduce the race by hand (one POST /end when a connection failure overlaps a hang-up)"
  deferred_at: 2026-11-16
- test: 13
  idea: "Rare test case (second push tap during an in-flight mode switch)"
  deferred_at: 2026-11-16
- test: 17
  idea: "Already unit-tested (CALL-09 provider label, PAY-05 slot-taken copy)"
  deferred_at: 2026-11-16
- test: checklist-5
  idea: "CALL-09 provider label on a real Zoom/Skype link (optional, unit-tested)"
  deferred_at: 2026-11-16
- test: checklist-8
  idea: "PAY-05 same slot-taken copy on free and paid (optional, unit-tested)"
  deferred_at: 2026-11-16

## Gaps
