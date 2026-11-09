---
status: partial
phase: 01-backend-fixes
source: [01-VERIFICATION.md]
started: 2026-11-09T00:00:00Z
updated: 2026-11-09T06:37:00.010Z
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

### 3. BACK-15 confirm replay and BACK-12 late-cancel guard on a device, after a forced confirm timeout
expected: A retried confirm lands on the pending booking; a cancel after end returns SESSION_ALREADY_ENDED with the server message shown.
result: [pending]
notes: "Paused 2026-11-09. Part A attempt not valid: the free 1:00-1:30 am booking was declined on the expert side, which BACK-12 does not guard. Rerun with a new free booking left unanswered, then tap Cancel as the client after its end time. Recommended on resume: split into 3a (Part A) and 3b (Part B, deferred to Phase 4 payment UAT), and correct 3b's expected result, because per the iOS code a second tap gets 409 DUPLICATE_BOOKING from payment-intent and shows 'A booking for this session already exists.' rather than landing on the booking."

## Summary

total: 3
passed: 1
issues: 0
pending: 1
skipped: 1
blocked: 0

## Gaps

## Deferred Follow-Ups

- test: 1
  idea: "defer"
  note: "Run real-Stripe checklists 01-17 and 01-19 during Phase 4 payment UAT; the 01-19 checklist does not prove the failed-refund retry"
  deferred_at: 2026-11-09
