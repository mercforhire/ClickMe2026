---
status: complete
phase: 06-expert-mode
source: [06-VERIFICATION.md]
started: 2026-11-16T19:20:00Z
updated: 2026-11-17T02:52:41.637Z
---

## Current Test

[testing complete]

## Tests

### 1. Run the whole 06-DEVICE-UAT-CHECKLIST.md (35 items) on a real iPhone against build 9e95cf3 or later
expected: Every item PASS, or KEEP/CHANGE for items 34 and 35
result: issue
reported: "Item 1: The price on this screen should have two digits after the decimal (Topics tab cards show CA$50 / US$5). Item 4: Some topics have a third currency which is invisible. This could be a bug on the backend. Item 8: By default, all the free topics open with an unknown currency, which causes a problem at save. Item 17: Add this \"Add to Calendar\" button on the booking summary screen for both client and expert, so this screen can be reached repeatedly."
severity: blocker
checklist: 29 PASS, 1 FAIL (item 4), 3 SKIPPED (12 no such slot; 13 and 16 iOS 26 glass checks, no reason given), KEEP on 34 and 35. Item 1 PASS with a cosmetic card-format issue; item 17 PASS with a change request. Per-item results are in 06-DEVICE-UAT-CHECKLIST.md.

### 2. Accept a request: Booking Confirmed shows, Back reveals a refreshed list, and a request already cancelled on a second device gives the 409 alert and a pop (items 14, 15, 19)
expected: No "Accepted!" frame; the 409 message shows and the screen pops
result: pass

### 3. Type or paste past the cap in the accept message (1,000) and the note (5,000), including an emoji across the boundary (items 20, 26, 31)
expected: The editor shows the truncated text, not the extra character (review IN-05)
result: pass

### 4. Open an expired request card on App Store build 6, then on the new build (items 21, 22, 35)
expected: Text is readable after the fix; decide whether EXP-12 was a real problem
result: pass

### 5. Decision: WR-01 (an expired or settled request opened from a push still shows Accept and Decline)
expected: A recorded disposition in 06-REVIEW-DISPOSITION.md (fix in Phase 6 with an additive backend change to getDetail plus an Android check, defer, or accept)
result: pass
disposition: accepted (recorded in 06-REVIEW-DISPOSITION.md)

### 6. Decision: WR-02 (a legacy free topic with a NULL stored currency opens on an empty currency and gets a 422 on Save) and WR-03 (a pasted "12,000" becomes 12.00)
expected: A recorded disposition for each; WR-03 touches a live price
result: pass
note: WR-02 is a fix in Phase 6, settled by device evidence (checklist items 4 and 8: every free topic is affected; gap G-06-1-currency). WR-03 is accepted ("The price is not likely to reach 1,000, so accept, or we can set a reasonable maximal price."); the maximum-price idea is a deferred follow-up below.

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-06-1-currency
  truth: "A free topic opens on CAD or USD in the editor and saves without error (checklist items 4, 8; review WR-02)"
  status: failed
  reason: "User reported: Some topics have a third currency which is invisible. This could be a bug on the backend. / By default, all the free topics open with an unknown currency, which causes a problem at save."
  severity: blocker
  test: 1
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis

- gap_id: G-06-1-card-cents
  truth: "Topic cards on the Topics tab show the price with two decimal places (e.g. CA$50.00 / session) (checklist item 1)"
  status: failed
  reason: "User reported: The price on this screen should have two digits after the decimal."
  severity: cosmetic
  test: 1
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis

- gap_id: G-06-1-summary-calendar
  truth: "Booking Summary has an Add to Calendar button for both client and expert, so the event can be added any time, not only from Booking Confirmed (checklist item 17; Android mirror needed)"
  status: failed
  reason: "User reported: Add this \"Add to Calendar\" button on the booking summary screen for both client and expert, so this screen can be reached repeatedly."
  severity: minor
  test: 1
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis

## Deferred Follow-Ups

- test: 6
  idea: "Set a reasonable maximum topic price (iOS, Android and backend validation), which would also bound the WR-03 grouped-paste misread"
  deferred_at: 2026-11-16
