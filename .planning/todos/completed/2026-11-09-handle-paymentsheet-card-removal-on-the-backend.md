---
created: 2026-11-09T08:05:00.000Z
title: Handle PaymentSheet card removal on the backend
area: payments
files:
  - ClickMe2026 Backend/src/controllers/webhooks.controller.js
  - ClickMe2026 Backend/src/services/connectedPaymentMethodClone.js
  - ClickMe2026 Backend/src/cron/longLeadChargeSweep.js
---

## Problem

T-01-32 (accepted risk, must be fixed before the iOS release). Removing a card inside Stripe's PaymentSheet goes straight to Stripe, so the backend's BACK-07 checks never run. There is no `payment_method.detached` handler, so the connected-account clone is left behind, and `longLeadChargeSweep.js:309,332` charges the cached clone unchecked. The route needs a booking converted by reschedule. Read from code and not run. Android's SDK default for sheet removal was not checked. See WR-01 in `01-REVIEW.md` and `01-SECURITY.md`.

## Solution

Handle `payment_method.detached`, evict the clones, and check the platform card before off-session charges. A backend fix also protects build 6. This is money code, so give it its own plan and deploy, and check it against build 6 and current Android before any push.

## Resolution

Done in plan 04-01 (D-12), backend commit `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d` on `origin/main`, deployed by the user on 2026-11-12 (production `/health` = `ae3ec1a`); the user reported the platform endpoint subscribed to `payment_method.detached`. The webhook evicts the removed card's clones, and `longLeadChargeSweep.chargeOne` checks the platform card before any off-session charge. Proof is mocked Stripe only: the live proof (remove a card in the sheet, show the clone rows gone and that it cannot be charged) runs in the D-11 device session, plan 04-14. Backend `master` does not yet contain D-12; see `.planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md`.
