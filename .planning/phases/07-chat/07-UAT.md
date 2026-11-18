---
status: testing
phase: 07-chat
source: [07-VERIFICATION.md]
started: 2026-11-18T17:30:00Z
updated: 2026-11-18T17:30:00Z
---

## Current Test

number: 1
name: Send, offline Failed bubble, retry and delete (checklist items 1-2)
expected: |
  First bubble shows Sending then the time, no second bubble. Offline bubble stays as Failed with the glyph and 'Not sent. Tap to retry', no alert, keyboard stays up. Retry delivers exactly once to the second phone. Delete removes the bubble with no prompt and the second phone never gets it. No Failed bubble survives a reopen.
awaiting: user response

## Tests

Full step-by-step instructions for each item are in `07-DEVICE-UAT-CHECKLIST.md`.

### 1. Send, offline Failed bubble, retry and delete (checklist items 1-2)
expected: First bubble shows Sending then the time, no second bubble. Offline bubble stays as Failed with the glyph and 'Not sent. Tap to retry', no alert, keyboard stays up. Retry delivers exactly once to the second phone. Delete removes the bubble with no prompt and the second phone never gets it. No Failed bubble survives a reopen.
result: [pending]

### 2. Composer cap, block banner on both sides, Block & Report card, profile Block, entry routes (checklist items 3-9)
expected: Counter rides above the keyboard and VoiceOver reads 'n of 10,000 characters' at the cap. The blocker sees Unblock in banner, menu and card; the blocked side sees 'You can't reply to this conversation' with no Unblock anywhere. Profile Block asks first, shows 'They won't be able to message you.', then a toast that is not hidden by the tab bar.
result: [pending]

### 3. Unread pill and live Read receipts with two accounts (checklist items 10-11, CHAT-07, CHAT-08)
expected: The unread pill appears live with the right count (99+ above 99), clears when the thread is opened by any route, and the sender's bubble flips to 'Read' live while both chats are open. Run the CHAT-08 regression row on the final build.
result: [pending]

### 4. VoiceOver, largest Dynamic Type, expert booking row (checklist items 12-14, D-18)
expected: Retry sending and Delete message actions are offered on a Failed bubble; text wraps without truncation and the banner stacks at accessibility sizes; the expert booking row opens the expert Booking Summary with no load error.
result: [pending]

### 5. KEEP or CHANGE judgements and filled-state sweep (checklist items 15-18)
expected: A KEEP or CHANGE answer for each of the three judgements (120 s Sending on a dead network, a count reappearing after a very quick pop, toast height), and the sweep shows no visual regressions.
result: [pending]

### 6. Chats list and bubble behavior after the code-review fixes (WR-02, WR-05, WR-06, IN-04)
expected: With phone A on the Chats list, a message from phone B in an existing thread moves that row to the top with the new preview, time and unread pill, and a pull-to-refresh right after does not put back the old preview or order. A first message from an account phone A has never chatted with shows up as a new row, even if it arrives while phone A is pulling to refresh. Opening a thread clears its pill and it does not come back after the list reloads. With VoiceOver on, a delivered bubble is not read as pending or sending. If a recipient shows the unavailable state, pulling to refresh in that chat re-enables the composer once they can receive messages again.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
