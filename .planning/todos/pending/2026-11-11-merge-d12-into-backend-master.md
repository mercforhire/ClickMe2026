---
created: 2026-11-12T00:00:00.000Z
title: Merge D-12 (origin/main) into backend master before its next deploy
area: payments
severity: high
files:
  - ClickMe2026 Backend/src/controllers/webhooks.controller.js
  - ClickMe2026 Backend/src/services/connectedPaymentMethodClone.js
  - ClickMe2026 Backend/src/cron/longLeadChargeSweep.js
  - ClickMe2026 Backend/tests/webhooks.test.js
  - ClickMe2026 Backend/tests/cron/longLeadChargeSweep.test.js
  - ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md
---

## Problem

D-12 (plan 04-01) is live in production, but it is not on backend `master`. It was built on `ios-p4-d12` from `origin/main` in its own worktree and pushed alone as a fast-forward of `main`: commit `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d`, subject `fix(ios-p4): handle card removal inside PaymentSheet (D-12)`. Production `/health` reports `ae3ec1a`. The rollback base is `32fa6ecd97a47409c5e7bf4f730b803f7b2fd7e5` (local branch `ios-p4-d12-rollback`).

If `master` is deployed without D-12, T-01-32 reopens: a card removed inside Stripe's PaymentSheet would again leave its connected-account clones behind and `longLeadChargeSweep` would again charge the cached clone with no platform-card check, with real money.

Git refuses a non-fast-forward push of `master` onto `origin/main`, which is the safety net. Do not "fix" that with a force-push.

Facts at the time of writing (2026-11-12):

- `master` and `origin/main` share the merge base `32fa6ec`. At the plan 04-01 checkpoint `master` was 5 commits ahead of it (31-11 docs, and 31-12: a guarded one-way `20261113000100_drop_legacy_ledger.sql` migration plus test and script cleanup). At the 2026-11-12 re-check `master` is 11 commits ahead, tip `d4b897f` ("docs(31): complete phase 31 legacy teardown, transition to phase 32"). D-12 is not an ancestor of `master` (checked).
- 31-05 (`3149a6b`) rewrote `dispatchPlatformEvent` and `tests/webhooks.test.js` on `master` so the platform dispatcher keeps only the `application_fee.*` cases. D-12 adds `case 'payment_method.detached'` to the same function and the same test file, so conflicts are expected in `src/controllers/webhooks.controller.js` and `tests/webhooks.test.js`.
- Baseline test counts on D-12's base: the three D-12 suites (`tests/webhooks.test.js`, `tests/services/connectedPaymentMethodClone.test.js`, `tests/cron/longLeadChargeSweep.test.js`) were 70 passed before the change and 85 after (+15 rows). Full backend suite on the D-12 branch: 153 suites, 3804 tests passed.

## Solution

This needs a change in the backend repo, which the iOS plan did not make. In `/Users/LeonChen/Documents/ClickMe2026 Backend`, on whichever session owns `master`:

1. `git fetch origin`, then MERGE `origin/main` into `master` (`git merge origin/main`). Never rebase `master` and never force-push either branch.
2. Resolve the conflicts so that `master` keeps both its 31-05 dispatcher (the `application_fee.*` cases) and D-12's `case 'payment_method.detached'` that calls `evictClonesForPlatformPaymentMethod(eventObject.id)`, plus the platform-card check in `longLeadChargeSweep.chargeOne` (`retrievePaymentMethod(booking.stripe_payment_method_id)`).
3. Both `describe('payment_method.detached (ios-p4 D-12)')` in `tests/webhooks.test.js` and `describe('platform card check (ios-p4 D-12)')` in `tests/cron/longLeadChargeSweep.test.js` must exist and pass on the merged `master`, and the full backend suite must pass, before any deploy of `master`.
4. Before the D-11 real-money session (plan 04-14) and before the Phase 8 release, confirm that production still contains D-12:
   `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" merge-base --is-ancestor ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d <the 40-character SHA that /health reports, expanded with git rev-parse>`
   must exit 0. Production `/health` returns a 7-character SHA, so expand it first with `git rev-parse <7-char sha>`.
5. The same ancestry check is the gate on any future `master` push: if D-12 is not an ancestor of the commit being pushed, do not push.

The worktree `/Users/LeonChen/Documents/ClickMe2026 Backend D12` and the branches `ios-p4-d12` and `ios-p4-d12-rollback` stay until Phase 4 verification; removing them (`git worktree remove`, `git branch -d`) is later cleanup.
