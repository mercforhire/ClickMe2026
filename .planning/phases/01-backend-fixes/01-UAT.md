---
status: testing
phase: 01-backend-fixes
source: [01-VERIFICATION.md]
started: 2026-11-09T00:00:00Z
updated: 2026-11-09T00:00:00Z
---

## Current Test

number: 1
name: Real-Stripe checklists 01-17 (BACK-06, BACK-07) and 01-19 (BACK-19), at the latest during Phase 4 payment UAT
expected: |
  See behavior_unverified_items in 01-VERIFICATION.md. Money behavior on live Stripe was skipped by user decision, and BACK-06, BACK-07 and BACK-19 stay Pending in REQUIREMENTS.md until then.
awaiting: user response

## Tests

### 1. Real-Stripe checklists 01-17 (BACK-06, BACK-07) and 01-19 (BACK-19), at the latest during Phase 4 payment UAT
expected: See behavior_unverified_items in 01-VERIFICATION.md. Money behavior on live Stripe was skipped by user decision, and BACK-06, BACK-07 and BACK-19 stay Pending in REQUIREMENTS.md until then.
result: [pending]

### 2. Optional no-money check of the BACK-19 contract change on App Store build 6 and on current Android: cancel a free or no-payment booking and open Payments history
expected: Cancel completes with no error; a ledger row with refunded_amount 0 renders as it does today.
result: [pending]

### 3. BACK-15 confirm replay and BACK-12 late-cancel guard on a device, after a forced confirm timeout
expected: A retried confirm lands on the pending booking; a cancel after end returns SESSION_ALREADY_ENDED with the server message shown.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
