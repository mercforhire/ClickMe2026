# Phase 3: Booked Sessions and Joining - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-10
**Phase:** 03-booked-sessions-and-joining
**Areas discussed:** Reschedule answer (BOOK-06), Client cancel preview (BOOK-08) and expert cancel copy (EXP-11), Skype/Zoom screen (CALL-06/07/08), After a reschedule (BOOK-16)

Carried forward without asking: Q2 refund policy (Phase 1 D-17), join window (Phase 2 D-07/D-12), money and status (Phase 2 D-09 to D-11), overtime (Phase 2 D-08).

---

## Reschedule answer (BOOK-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Card on Upcoming details | Response card with Accept/Decline on Upcoming Booking details, reusing Booking Summary logic | ✓ |
| Route to Booking Summary | "Tap to review" opens Booking Summary, which already has Accept/Decline | |
| Both | Card on Upcoming details, and "Tap to review" lands there | |

**Decline reason:** Optional reason (≤500) ✓ / No reason / Required reason
**After success:** Stay, update in place ✓ / Pop back to My Bookings / You decide

---

## Client cancel preview (BOOK-08) and expert cancel copy (EXP-11)

| Option | Description | Selected |
|--------|-------------|----------|
| Exact amount + reason | Computed amount with the 24 h reason; held booking reads as a release | ✓ |
| Policy in words only | Rule text, no amount | |
| Amount only | Number with no explanation | |

**Inside 24 h warning:** Clear warning in the flow ✓ / Extra confirm dialog / Same as any cancel
**Boundary and server mismatch:** Recompute at confirm, then trust the server's refund_amount ✓ / Preview only
**Expert copy:** State the client's amount ✓ / Keep generic "full refund"

---

## Skype/Zoom screen (CALL-06, CALL-07, CALL-08)

| Option | Description | Selected |
|--------|-------------|----------|
| Same as in-app voice | Reuse timerString and remainingLabel | ✓ |
| Remaining only | Countdown, then "Scheduled time complete" | |
| Elapsed only | Count up from scheduled start | |

**Status copy:** Scheduled end + End Session ✓ / Also mention the cutoff / You decide
**Open on Upcoming details:** Open the meeting screen via CallCenter.startCall ✓ / Open the link directly

---

## After a reschedule (BOOK-16)

| Option | Description | Selected |
|--------|-------------|----------|
| Back to origin + toast | Pop one level and show "Reschedule request sent" (Android parity) | ✓ |
| Back to origin, no toast | Pop one level; status pill is the confirmation | |
| Confirmation screen | Dedicated "Request sent" screen | |

---

## Todos

The user first selected "None" plus two todos; on clarification chose **Fold none**.

## Claude's Discretion

BOOK-07, BOOK-09, BOOK-11, BOOK-12, BOOK-13, BOOK-16 remainder (exclude_booking_id, stale payment path, held-booking advice), BOOK-17, BOOK-20, CALL-03, CALL-10, EXP-13, decline note display: follow the inventory fix and Android.

## Deferred Ideas

- Android copy check for the expert-cancel full-refund wording (Phase 1 D-17 follow-up).
