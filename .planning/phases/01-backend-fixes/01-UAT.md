---
status: complete
phase: 01-backend-fixes
source: [01-VERIFICATION.md]
started: 2026-11-09T00:00:00Z
updated: 2026-11-09T07:39:55.103Z
---

## Current Test

[testing complete]

## Tests

### 1. Real-Stripe checklists 01-17 (BACK-06, BACK-07) and 01-19 (BACK-19), at the latest during Phase 4 payment UAT
expected: See behavior_unverified_items in 01-VERIFICATION.md. Money behavior on live Stripe was skipped by user decision, and BACK-06, BACK-07 and BACK-19 stay Pending in REQUIREMENTS.md until then.
result: skipped
reason: "Deferred follow-up: defer"

### 2. Optional no-money check of the BACK-19 contract change on App Store build 6 and on current Android: cancel a free or no-payment booking and open Payments history
expected: Cancel completes with no error; a ledger row with refunded_amount 0 renders as it does today.
result: pass

### 3. BACK-12 late-cancel guard on a device
expected: A client cancel after the session's end returns SESSION_ALREADY_ENDED with the server message shown, and the booking is not cancelled.
result: pass
notes: "Split from the original Test 3 on 2026-11-09. Second attempt: free 2:00-2:30 am booking left unanswered, client tapped Cancel at 2:31. The app showed 'Couldn't cancel booking. This session has already ended, so it can't be cancelled.' (user screenshot). First attempt was not valid: that booking was declined on the expert side, which BACK-12 does not guard."

### 4. BACK-15 confirm replay on a device, after a forced confirm timeout
expected: After a lost confirm response, a retry leaves exactly one booking and one hold for that slot. On iOS a second tap calls payment-intent, gets 409 DUPLICATE_BOOKING and shows 'A booking for this session already exists.' Corrected on 2026-11-09 from 'a retried confirm lands on the pending booking', which is not what the iOS code does per a code read. A normal retry tap does not reach the confirm replay code.
result: skipped
reason: "Deferred follow-up: defer"

## Summary

total: 4
passed: 2
issues: 0
pending: 0
skipped: 2
blocked: 0

## Gaps

## Deferred Follow-Ups

- test: 1
  idea: "defer"
  note: "Run real-Stripe checklists 01-17 and 01-19 during Phase 4 payment UAT; the 01-19 checklist does not prove the failed-refund retry"
  deferred_at: 2026-11-09
- test: 4
  idea: "defer"
  note: "Run BACK-15 with a real hold during Phase 4 payment UAT. A normal retry tap only proves one booking and one hold, not the confirm replay code; on iOS only the retry after 3D Secure calls confirm again"
  deferred_at: 2026-11-09
