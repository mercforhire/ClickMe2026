---
created: 2026-11-12T19:00:00.000Z
title: Long-lead T-24h sweep: transient errors after the stamp still cancel at 6 h
area: payments
severity: medium
files:
  - ClickMe2026 Backend/src/cron/longLeadChargeSweep.js
  - ClickMe2026 Backend/src/cron/scaRecoveryWindowSweep.js
---

## Problem

`longLeadChargeSweep.chargeOne` stamps `off_session_attempted_at` (stampAttempt) before it writes anything to Stripe. After the stamp, these calls can throw a transient error: the connected-customer lookup (`getOrCreateConnectedCustomer`), the clone lookup (`getOrCreateClonedPaymentMethod`), the pre-charge recheck read (`recheckStillChargeable`), `createManualPI`, and a non-card error from `confirmPIOffSession`. Any of them is re-thrown to the per-row catch, so the row is left `payment_status = 'scheduled'`, stamped, with no PaymentIntent. `longLeadChargeSweep` never selects it again (its candidate query needs a NULL stamp), and `scaRecoveryWindowSweep` selects it once the stamp is 6 h old. With no `payment_intent_id` that sweep goes straight to the `scheduled -> canceled` transition and `cancelBookingForPaymentFailure`: the booking is cancelled, the slot is released and both parties are notified, though no charge was ever attempted.

This predates ios-p4 D-12 (Phase 26, backend D-08). Plan 04-16 (CR-02) fixed only the card-check part: the profiles read and the platform-card check now run before the stamp, so a transient error there is retried on the next 5-minute run. 04-VERIFICATION truth 17 ("a removed card is refused at T-24h and a transient Stripe error never cancels") is therefore only partly closed: true for errors at the profiles read and the platform-card check, still false for errors after the stamp.

Related limit accepted at the CR-02 deploy (T-04-44): a profiles read error or a platform-card check error that persists is retried every 5 minutes with no deadline. If it lasts past the session start, nothing cancels the booking (the 6 h window needs a stamp), joining checks only the booking status, so the session can go ahead with no PaymentIntent and no hold, and once the call connects the long-lead sweep stops selecting it. The session is then delivered and never charged, and the expert is not paid for it. Any bound on that belongs to the same later decision.

Users who already hit this: a booking in this state before the CR-02 deploy is not rescued by it. The read-only query for them is `select id, status, charge_due_at, off_session_attempted_at from bookings where payment_status = 'scheduled' and off_session_attempted_at is not null and payment_intent_id is null;`.

## Why it was not fixed in CR-02

- A stamp reset after a Stripe write can replay `createManualPI` under the same idempotency key (`booking:{id}:t24h_charge:{account}`) and then confirm a PaymentIntent that may already be authorized, stranding a hold with no record of it.
- An unbounded retry would let a session start uncharged.
- Backend D-08 chose one fixed 6 h window over retry escalation, so changing it needs a bounded design and a user decision.

## Solution

TBD, needs a change in the backend repo (separate commit there) and a user decision first. Options:

1. A bounded retry only for errors before `createManualPI`: a guarded stamp reset while no PaymentIntent exists (`payment_intent_id IS NULL`), plus a deadline before the session start so a session can never begin uncharged because of retries.
2. Reconcile a lost confirm by retrieving the PaymentIntent (by the idempotency key or booking metadata) before deciding to cancel, so an authorized hold is never stranded and a missing one is retried.
3. Decide whether a persistent card-check or profiles read error needs the same deadline (see the accepted limit above).
