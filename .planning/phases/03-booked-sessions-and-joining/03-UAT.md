---
status: partial
phase: 03-booked-sessions-and-joining
source: [03-VERIFICATION.md]
started: 2026-11-11T06:30:00Z
updated: 2026-11-11T20:02:04.579Z
---

## Current Test

[testing complete]

## Tests

### 1. Run the 24 device checks in 03-DEVICE-UAT-CHECKLIST.md on a real iPhone
expected: Every item records PASS. JOIN CALL works from every entry. The end + 55 notice shows on the Skype/Zoom layout. The expert cancel sheet line is right for a live hold, a captured booking, a free booking and a converted long-lead booking.
result: blocked
blocked_by: physical-device
reason: "Defer the iPhone test. Move on to test 3."

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
result: blocked
blocked_by: physical-device
reason: "Passed over by 'Move on to test 3.' All 11 backstops are device-only checks (same deferral as test 1)."

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
reason: "defer" (02-UAT.md is partial with tests 7-17 pending and test 6 skipped; BACK-19 smoke from 01-19 still unrun)

## Summary

total: 5
passed: 1
issues: 1
pending: 0
skipped: 0
blocked: 3

## Gaps

- gap_id: G-03-3-WR01
  truth: "After a successful reschedule accept or decline, the Accept/Decline card disappears even if the follow-up booking refetch fails"
  status: failed
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
  status: failed
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
