---
status: testing
phase: 05-signup-mode-switch-and-account
source: [05-VERIFICATION.md]
started: 2026-11-13T23:40:00Z
updated: 2026-11-13T23:40:00Z
---

## Current Test

number: 1
name: SIGN-06 end to end on a device (05-DEVICE-UAT-CHECKLIST.md items 1 to 17)
expected: |
  The setup hub opens for an unfinished expert and a finished expert enters Expert. Airplane mode fails open, including right after Publish. No mode switch happens during a call. A push for the other mode waits until the call ends. The foreground re-check opens the hub.
awaiting: user response

## Tests

### 1. SIGN-06 end to end on a device (05-DEVICE-UAT-CHECKLIST.md items 1 to 17)
expected: The setup hub opens for an unfinished expert and a finished expert enters Expert. Airplane mode fails open, including right after Publish. No mode switch happens during a call. A push for the other mode waits until the call ends. The foreground re-check opens the hub.
result: [pending]

### 2. SET-06 legibility: Settings > Delete Account on a small iPhone and at the largest Dynamic Type size, scrolled to the bottom of the confirmation step
expected: All three groups, including the last "Kept" group (messages, reviews, payment records), can be read in full and are not covered by the pinned Delete and Cancel buttons. If the "Kept" group is hidden, record it as a gap; the fix is a bottom `safeAreaInset` (05-UI-REVIEW.md).
result: [pending]

### 3. SET-02: Help > Email Us on a device with Mail set up
expected: The default mail app opens addressed to clickmeapp@uptrendinvestments.net.
result: [pending]

### 4. SIGN-05: pick a camera-roll photo, zoom in on the slider, Save, then view the public avatar
expected: The uploaded avatar looks like the preview circle.
result: [pending]

### 5. SET-07: from both the Bookings tab and a Home-route cancel, tap "Cancellation policy" on the cancel confirmation, then Back
expected: The policy opens, and Back returns to the confirmation with its state intact.
result: [pending]

### 6. Remaining items in 05-DEVICE-UAT-CHECKLIST.md (SIGN-02 quit and relaunch, SET-01 reopen after a language edit, SET-06 409 blocker alerts, T8 pre-filled email, KEEP or CHANGE on assumptions A9, U2, U3, U4 and A1)
expected: Each item matches its Expected block in the checklist.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
