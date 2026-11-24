---
created: 2026-11-23T23:59:00.000Z
title: Booking Summary shows PAID on cancelled, declined or expired paid rows (1.2)
area: booking
severity: minor
files:
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift:56-65
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift:116-128
  - .planning/phases/03-booked-sessions-and-joining/03-REVIEW.md (WR-01)
---

## Problem

The client Booking Summary labels every non-free row `PAID`, whatever happened to the booking. A paid booking that was cancelled, declined or expired, where the client was refunded, had the hold released, or was never charged, still reads `PAID · CA$…`. The `.unknown` case added in 03-18 also shows `PAID` with a dash on never-charged statuses.

Source: Phase 3 code review WR-01 (`03-REVIEW.md`, "PAID" label is shown for bookings that were never charged, and the new `.unknown` case widens it), carried in `03-VERIFICATION.md` as a human item.

The user decided on 2026-11-22 (03-18-PLAN, STATE.md) that paid rows keep PAID. The review raised the never-charged statuses after that decision. On 2026-11-23 (plan 08-24) the user chose, verbatim: "Change it in 1.2 (Recommended)". The label is accepted as is for 1.1 (7), and this todo replaces the 2026-11-22 decision for the cancelled, declined and expired cases only. Paid rows on live or completed bookings keep PAID.

## Solution

1.2, iOS first, then Android parity (one commit per repo):

- On cancelled, declined or expired paid rows, show what happened to the money instead of PAID, for example "Refunded", "Released" (hold released) or "Not charged". Base it on the booking's payment status from the server, not on the device clock. Check the backend booking detail fields first (`openapi/clickme-api.yaml`, `src/controllers/clientBooking.controller.js`), and add a field only if the existing ones can't tell the cases apart (additive, safe for the current Android build).
- Keep `Session fee · Free` for free sessions and `PAID · {amount}` for confirmed, in-progress and completed paid sessions.
- Unit tests in `BookingSummaryViewModelTests` for each status.
- Android: mirror the rule in `BookingSummaryCard.kt` (`PriceText`) with matching strings.
