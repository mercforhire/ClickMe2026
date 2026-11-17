# Phase 7: Chat - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-17
**Phase:** 07-chat
**Areas discussed:** Send failure & retry, Block copy & profile block, Unread badge clearing, CHAT-08 'Read' re-test

---

## Todo cross-reference

| Option | Description | Selected |
|--------|-------------|----------|
| Fold it in | Confirm on a device, then send expert-mode chat booking rows to ExpertBookingSummaryView (Android parity) | ✓ |
| Leave it deferred | Keep it as a separate todo | |

**User's choice:** Fold in `2026-11-16-expert-chat-row-opens-client-booking-screen.md`.

---

## Send failure & retry

| Question | Options | Selected |
|----------|---------|----------|
| Failed send bubble | Copy Android D-01 / Retry only, no Delete / Auto-retry once, then fail | Copy Android D-01 |
| Failed messages persist? | No, in memory only / Keep for the app session | No, in memory only |
| 403 THREAD_BLOCKED / RECIPIENT_UNAVAILABLE | Copy Android D-03 / Failed bubble + alert | Copy Android D-03 |
| Composer character cap | Yes, match Android (10,000 + counter) / No cap, map the 422 | Yes, match Android |

---

## Block copy & profile block

| Question | Options | Selected |
|----------|---------|----------|
| Copy vs enforcement | Fix the copy / Enforce on the backend | Fix the copy |
| Profile block flow | Copy Android D-05 / Dialog, then open the thread | Copy Android D-05 |
| Blocked thread composer | §5 matrix wording with Unblock on the banner / Banner only, Unblock in menu | §5 matrix wording |
| Legacy blocks | Follow CHAT-UNBLOCK §7 / Keep a legacy Unblock | Follow the doc |

---

## Unread badge clearing

| Question | Options | Selected |
|----------|---------|----------|
| Clear on open | Zero locally on open / Wait for the server | Zero locally on open |
| message.new on a thread that isn't open | Increment locally / Keep the server value | Increment locally |
| Badge style | Count pill, 99+ cap / Dot only / You decide | Count pill, 99+ cap |
| Chats tab badge | No / Yes, total count | No |
| Unread beyond page 1 | Mark as pages load / Backend mark-all-read / Accept as-is | Mark as pages load |

**Notes:** The page-1 issue came up because `message.read` (socket.js) marks only the listed message ids, and opening a thread marks nothing as read (backend 01-14).

---

## CHAT-08 'Read' re-test

| Question | Options | Selected |
|----------|---------|----------|
| Re-tested since Phase 1? | Not yet: first plan gate / Not yet: test before planning / Yes, still fails / Yes, works now | Yes, it works now |
| If it fails, start where? | Backend first / iOS first | Backend first |

**Notes:** CHAT-08 closed as not reproducible. Q8 is settled.

---

## Claude's Discretion

- Visuals of the pending, failed and banner states and the counter
- The form of the profile-block success confirmation
- When the counter appears

## Deferred Ideas

- Enforce block on the backend (profile and bookings)
- Backend mark-all-read for threads with more than 30 unread
- Chats tab total unread badge
- Offline send queue
