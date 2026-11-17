---
status: complete
phase: 06-expert-mode
source: [06-VERIFICATION.md]
started: 2026-11-17T00:00:00Z
updated: 2026-11-17T16:00:24.622Z
---

Re-verification after gap closure (plans 06-11 to 06-18). The previous UAT session
(status: diagnosed, gaps G-06-1-currency, G-06-1-card-cents, G-06-1-summary-calendar) is
in git history at commit 4baacec. Its gaps are closed in code; these tests confirm them on
hardware. Full steps for R1 to R8 are in 06-DEVICE-UAT-CHECKLIST.md, section
"Gap closure re-check".

## Current Test

[testing complete]

## Tests

### 1. R1. Topics tab cards show the cents (G-06-1-card-cents, 06-12)
expected: Paid cards read CA$50.00 / session, CA$5.00 / session, CA$12.50 / session, US$5.00 / session; free topics read Free
result: pass

### 2. R2. A free topic opens on CAD | USD and saves (G-06-1-currency, 06-11)
expected: A free topic stored with no currency opens with CAD selected (no blank third segment) and saves without error
result: pass

### 3. R3. Clearing the icon and description on a free topic sticks (G-06-1-currency, 06-11)
expected: After saving with the icon and description cleared, reopening the topic shows them still cleared
result: pass

### 4. R4. Expert Booking Summary has Add to Calendar; its Cancel sheet still works (G-06-1-summary-calendar, 06-18)
expected: A confirmed future booking offers Add to Calendar and the New Event sheet opens with the booking details; the Confirm Cancellation sheet opens before and after it and Keep Booking dismisses it (stop at Keep Booking, do not cancel). Watch for a blank flash as the calendar sheet closes (review WR-02)
result: pass

### 5. R5. Client Upcoming Booking has Add to Calendar (G-06-1-summary-calendar, 06-14)
expected: A confirmed booking offers Add to Calendar with the expert's name in the title; a pending request and the Session Summary show no button
result: pass

### 6. R6. Booking Confirmed still adds the same event (regression, 06-13, 06-18)
expected: Add to Calendar on Booking Confirmed creates the same event as before the change (title, notes, time, 15-minute alert)
result: pass

### 7. R7. Android: Booking Summary and Upcoming Booking (G-06-1-summary-calendar, 06-15)
expected: On an Android build at or after 69c4e159, both screens offer Add to Calendar and open the calendar app with the event
result: pass

### 8. R8. Optional: the button goes when the session ends (06-18, 06-14)
expected: After the session's end time, Add to Calendar is no longer shown on either screen
result: pass

### 9. Items 12, 13 and 16 skipped on 2026-11-16
expected: Either run them (09:15 and 24:00 slot edges; two iOS 26 glass checks) or accept AvailabilitySlotRulesTests as the EXP-07 evidence and record the glass checks as unchecked
result: skipped
reason: "Deferred follow-up: accept AvailabilitySlotRulesTests as the EXP-07 evidence for item 12; record glass checks 13 and 16 as unchecked and run them on iOS 26 before Phase 8 (user decision 2026-11-17)"

### 10. Open code-review findings (06-REVIEW-DISPOSITION.md)
expected: A recorded disposition (fix, accept or defer) for each of the 9 open findings, at least WR-01 (editor price seed vs selected currency) and WR-02 (calendar sheet built from the isPresented optional)
result: pass
note: "User: pass, fix WR-01, IN-03, IN-07; defer the rest. Recorded in 06-REVIEW-DISPOSITION.md (3 open to fix, 6 deferred)."

## Summary

total: 10
passed: 9
issues: 0
pending: 0
skipped: 1
blocked: 0

## Gaps

## Deferred Follow-Ups

- test: 9
  idea: "Run the two iOS 26 Liquid Glass readability checks (checklist items 13 and 16: Availability Save, and the Booking Confirmed back chevron and title, with Reduce Transparency and Liquid Glass Tinted) before Phase 8. Item 12 (09:15 and 24:00 slot edges) is accepted on AvailabilitySlotRulesTests."
  deferred_at: 2026-11-17
