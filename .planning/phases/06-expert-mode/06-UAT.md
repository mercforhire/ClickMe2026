---
status: testing
phase: 06-expert-mode
source: [06-VERIFICATION.md]
started: 2026-11-16T19:20:00Z
updated: 2026-11-16T19:20:00Z
---

## Current Test

number: 1
name: Run the whole 06-DEVICE-UAT-CHECKLIST.md (35 items) on a real iPhone
expected: |
  Every item PASS, or KEEP/CHANGE for items 34 and 35
awaiting: user response

## Tests

### 1. Run the whole 06-DEVICE-UAT-CHECKLIST.md (35 items) on a real iPhone against build 9e95cf3 or later
expected: Every item PASS, or KEEP/CHANGE for items 34 and 35
result: [pending]

### 2. Accept a request: Booking Confirmed shows, Back reveals a refreshed list, and a request already cancelled on a second device gives the 409 alert and a pop (items 14, 15, 19)
expected: No "Accepted!" frame; the 409 message shows and the screen pops
result: [pending]

### 3. Type or paste past the cap in the accept message (1,000) and the note (5,000), including an emoji across the boundary (items 20, 26, 31)
expected: The editor shows the truncated text, not the extra character (review IN-05)
result: [pending]

### 4. Open an expired request card on App Store build 6, then on the new build (items 21, 22, 35)
expected: Text is readable after the fix; decide whether EXP-12 was a real problem
result: [pending]

### 5. Decision: WR-01 (an expired or settled request opened from a push still shows Accept and Decline)
expected: A recorded disposition in 06-REVIEW-DISPOSITION.md (fix in Phase 6 with an additive backend change to getDetail plus an Android check, defer, or accept)
result: [pending]

### 6. Decision: WR-02 (a legacy free topic with a NULL stored currency opens on an empty currency and gets a 422 on Save) and WR-03 (a pasted "12,000" becomes 12.00)
expected: A recorded disposition for each; WR-03 touches a live price
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
