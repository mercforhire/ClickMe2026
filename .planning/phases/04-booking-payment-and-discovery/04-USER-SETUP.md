# Phase 4: User Setup Required

**Generated:** 2026-11-12
**Phase:** 04-booking-payment-and-discovery
**Status:** Complete (reported by the user on 2026-11-12; the Dashboard state is not independently verifiable from this repo)

Claude automated everything possible; the items below need human access to the Stripe Dashboard. Source: plan 04-01 `user_setup` (D-12).

## Environment Variables

None. The repo has no code-side webhook event list, and no new environment variable was added.

## Dashboard Configuration

### Stripe (live mode)

- [x] **Add `payment_method.detached` to the platform webhook endpoint's events**
  - Location: Stripe Dashboard (live mode) -> Developers -> Webhooks -> the platform endpoint that targets `/webhooks/stripe` -> Update details -> Select events
  - Set to: `payment_method.detached` listed in the endpoint's events
  - Notes: the platform endpoint only. Do NOT add it to the Connect endpoint `/webhooks/stripe-connect`. The event must be subscribed after the backend deploy so the old code never stamps one of these events as ignored.
  - Done: 2026-11-12, by the user, after deploying backend `ae3ec1a`. The user's reply: "b: deployed ae3ec1a, subscribed".

## Verification

Backend deploy (checked by Claude on 2026-11-12):

```bash
curl -s https://clickme-backend-production.up.railway.app/health
```

Expected and observed: `{"status":"success","commit":"ae3ec1a"}`.

Event delivery on live Stripe is NOT yet proven. The live proof runs in the D-11 device session (plan 04-14): remove a saved card inside the PaymentSheet, then confirm the webhook was delivered (Stripe Dashboard -> Developers -> Webhooks -> the platform endpoint -> recent deliveries, `payment_method.detached` with a 200) and that the card's `connected_pm_clones` rows are gone.

The T-24h sweep guard does not depend on this subscription: it checks the platform card itself before any off-session charge, so a missing subscription cannot cause a charge on a removed card.

---

**Once all items complete:** status is "Complete" (done 2026-11-12).
