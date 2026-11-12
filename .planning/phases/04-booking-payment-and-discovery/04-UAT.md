---
status: testing
phase: 04-booking-payment-and-discovery
source: [04-VERIFICATION.md]
started: 2026-11-12T19:43:46Z
updated: 2026-11-12T19:43:46Z
---

## Current Test

number: 1
name: D-11 real-money session (04-DEVICE-UAT-CHECKLIST.md)
expected: |
  No requires_capture PaymentIntent after closing the sheet; a timed-out confirm lands on the one booking with one hold; 3DS completes into a booking (see WR-01); a removed card is refused at T-24h (production now runs 28da165); payment_method.detached delivered with 200
awaiting: user response

## Tests

### 1. D-11 real-money session: close the card sheet with a saved card preselected, forced confirm timeout then Try again (with the form-lock taps), SCA/3DS path, remove a card inside the sheet, T-24h sweep
expected: No requires_capture PaymentIntent after closing the sheet; a timed-out confirm lands on the one booking with one hold; 3DS completes into a booking (see WR-01); a removed card is refused at T-24h (production now runs 28da165); payment_method.detached delivered with 200
result: [pending]

### 2. WR-01: complete a 3DS challenge on a saved card that requires SCA, then confirm a booking exists
expected: After 3DS the booking is created, with no authorized PaymentIntent stranded without a booking
result: [pending]

### 3. UAT item 1, EXPL-07: Explore loads with a free no-currency topic, one bad topic, a failed load
expected: Explore loads every time; a bad featured topic is dropped alone; airplane-mode failure shows a readable sentence and no stale Featured Topics (precondition: migration 20261109000000_home_feed_null_hourly_rate.sql applied in production)
result: [pending]

### 4. UAT item 2, EXPL-03: free featured topic card reads "Free"; paid card shows CA$12.50 style price
expected: Free card reads Free; paid card shows cents
result: [pending]

### 5. Remaining UAT items 3 to 22 of 04-DEVICE-UAT-CHECKLIST.md (BOOK-01, BOOK-19, BOOK-04, EXPL-02, EXPL-05, EXPL-06, K1/K3/K4/K5)
expected: Per the checklist's Expected lines
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
