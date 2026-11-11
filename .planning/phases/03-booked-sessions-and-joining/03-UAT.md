---
status: testing
phase: 03-booked-sessions-and-joining
source: [03-VERIFICATION.md]
started: 2026-11-11T06:30:00Z
updated: 2026-11-11T06:30:00Z
---

## Current Test

number: 1
name: Run the 24 device checks in 03-DEVICE-UAT-CHECKLIST.md on a real iPhone
expected: |
  Every item records PASS. In particular:
  - JOIN CALL starts the call from My Bookings, a push, a chat row, the Explore strip and Payments.
  - The amber end + 55 notice shows on the Skype/Zoom layout.
  - The expert cancel sheet shows the right line for a live hold, a captured booking, a free booking and a converted long-lead booking.
awaiting: user response

## Tests

### 1. Run the 24 device checks in 03-DEVICE-UAT-CHECKLIST.md on a real iPhone
expected: Every item records PASS. JOIN CALL works from every entry. The end + 55 notice shows on the Skype/Zoom layout. The expert cancel sheet line is right for a live hold, a captured booking, a free booking and a converted long-lead booking.
result: [pending]

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
result: [pending]

### 3. Decide whether to fix code-review findings WR-01 and WR-02 before the Phase 8 release
- WR-01: after an accept or decline, if the refresh fails, the response card stays on screen.
- WR-02: the cancel toast says a refund is coming when the server refunded 0.

expected: Each one has a fix or a skip recorded in 03-REVIEW-DISPOSITION.md.
result: [pending]

### 4. Android BOOK-20: run BookingSummaryScreenTest, then decide when to push commit 0f2e8cd
expected: bookingIdShowsInTheShortFormat and fullUuidBookingIdMatchesIos pass, and the commit is pushed with the Android release.
result: [pending]

### 5. Run the carried-over prerequisites: Phase 2 UAT tests 6-17 and the BACK-19 production smoke
expected: Both run before Phase 8. Until the BACK-19 smoke runs, the EXP-11 expert refund-or-release copy is verified in code only.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
