# Phase 1 Deferred Items

Out-of-scope discoveries logged during execution. Nothing here was changed.

## Deferred Items

- `scripts/uat-demo-shoot-check.js` still mirrors the old join window
  status: open
  **Found in:** plan 01-11 (BACK-09), backend `scripts/uat-demo-shoot-check.js` lines 34-35 and 45.
  **What:** its `inJoinWindow` helper uses 120 min lead and grace and names the removed `isWithinSessionWindow` in a comment. After wave 2 deploys, the demo-shoot check can report a booking as joinable when `/join` refuses it. `tests/uatDemoShootCheck.test.js` pins the helper, so a fix has to update that test too.
  **Why deferred:** a UAT script outside this plan's files, with no effect on production behavior.

- `POST /bookings/:id/end` has no status or time limit for `dropped` and `manual_exit`
  status: open
  **Found in:** plan 01-11 (BACK-09), backend `src/controllers/call.controller.js` `end`.
  **What:** only `end_reason: "completed"` is guarded. A participant can send `dropped` or `manual_exit` on any booking at any time, including a long-finished or cancelled one, and overwrite `actual_duration_secs` and `end_reason`. Nothing in `src` reads those two columns for money, so the effect is limited to reported metadata.
  **Why deferred:** behavior that predates this plan. D-05 only asked to accept the overtime `completed` end.

- `confirm` leaves the card authorization in place when the insert loses a slot to another client
  status: open
  **Found in:** plan 01-13 (BACK-15), backend `src/controllers/booking.controller.js` `confirm`, 23P01 and other insert-error branches.
  **What:** by the insert the PaymentIntent is already `requires_capture`. When the insert fails and there is no replay (a different client won the slot, or any other DB error), the handler releases the slot keys and returns an error, but `cancelPI` is not imported in this file and nothing voids the PI, so no booking row exists to link it to. The hold appears to stay on the card until Stripe's authorization expires. This plan did not check whether any webhook or sweep handles such a PI.
  **Why deferred:** behavior that predates this plan. A void on this path is a money change and belongs in a planned, separately deployed item.

- `confirm` Step 1 ignores a read error on its idempotency select
  status: open
  **Found in:** plan 01-13 (BACK-15), backend `src/controllers/booking.controller.js` `confirm` Step 1.
  **What:** the select destructures only `data`, so a read error looks like "no booking" and the request goes on to the payment work. The unique constraint still blocks a second row, and that insert error now replays for the owner, so no double booking results. The new `findReplayableBooking` read does throw on error.
  **Why deferred:** behavior that predates this plan, and the plan said to keep the existing select.

- A saved card can become undeletable if one of its connected accounts is unreachable
  status: open
  **Found in:** plan 01-16 (BACK-07), backend `src/services/connectedPaymentMethodClone.js` `evictClonesForPlatformPaymentMethod`.
  **What:** only `resource_missing` and `payment_method_unexpected_state` count as "already gone". Any other Stripe error returns 502 and keeps the card, as the plan decided. If an expert's connected account is closed or the platform loses access to it, a client with a clone there may be unable to delete that card. Which error Stripe returns in that case was not established.
  **Why deferred:** the plan fixes this behavior on purpose. Widening the tolerated list is a money-path decision for the user, ideally informed by the 01-17 smoke.

- In-use check and clone eviction on card delete are not atomic
  status: open
  **Found in:** plan 01-16 (BACK-07), backend `src/controllers/paymentMethods.controller.js` `deletePaymentMethod`.
  **What:** a long-lead confirm for the same card that lands after the bookings check can create a booking, or a clone row after the eviction, with no lock to stop it. A cached clone could then be charged by the T-24h sweep after the client removed the card. It needs one client to book and delete the same card at the same moment.
  **Why deferred:** closing it needs a lock or a re-check across the delete and confirm paths, which goes beyond this plan.

- A partly failed card delete can spoil the saved card for one expert
  status: open
  **Found in:** plan 01-17 review of BACK-07, backend `src/services/connectedPaymentMethodClone.js` `evictClonesForPlatformPaymentMethod` and `src/services/stripe.js` `clonePaymentMethodToConnectedAccount`.
  **What:** eviction detaches a clone and deletes its row one account at a time. If a later step fails (a 502 on another account's clone, or the platform detach), the card stays saved with that clone gone. The clone call uses the fixed idempotency key `clone-{pm}-on-{acct}`, so a later booking with that card and expert may get the old, detached clone back from Stripe within the key's retention window, and the attach would then fail before any hold. Removing and re-adding the card gives a new pm id and avoids it. Inferred from the code, not tested against Stripe.
  **Why deferred:** no money moves and the failure needs a prior partial delete. Changing the key or the eviction order is a money-path change for a planned item.

- A failed cancel refund is never retried as a refund
  status: open
  **Found in:** plan 01-18 (BACK-19), backend `src/controllers/expertBooking.controller.js` `cancel` and `src/controllers/clientBooking.controller.js` `cancel`, catch blocks; `src/cron/refundReconciliation.js`.
  **What:** when `createRefund` throws, both handlers set `refund_failed: true` but leave `refund_amount_minor_units` NULL. The sweep reads NULL as a failed void and calls `cancelPI`, not `createRefund`. On a captured PaymentIntent that call should fail on every 30-minute sweep (not run against real Stripe), so the flag never clears and the client is not refunded unless someone does it by hand. The code comment saying the cron retries is wrong for this branch. The same failed call also returns `refund_amount` as the full amount, because the value is set before `createRefund` runs. From the 01-19 code read, BACK-19 widens this path only slightly, because capture happens after a booking stops being cancellable.
  **Why deferred:** the plan says to leave the CR-06 error handling untouched, and the behavior predates it. The obvious fix, writing the amount in the catch, is not safe alone: when `retrievePI` fails on an uncaptured booking the handler assumes `succeeded`, and that row needs the void retry.
  **Decision (user, 2026-11-08, option A):** push now, fix next. Wave 3b shipped without this fix. It needs its own plan and deploy before Phase 4 payment UAT. No phase or plan for it exists yet; one still needs creating. The shape of the fix is in `01-19-SUMMARY.md` note 1.

- `PATCH /expert/bookings/:id/status` with `cancelled` moves no money
  status: resolved
  **Found in:** plan 01-18 (BACK-19), backend `src/controllers/expertBooking.controller.js` `patchStatus`.
  **What:** the item said an expert can mark a past session `cancelled` with no money moving. That was wrong.
  **Resolution (plan 01-19):** `statusSchema` in `src/schemas/booking.schema.js` allows only `missed` and `completed` (CR-06), and the route applies it through `validate`, which returns 422. Confirmed by parsing the schema; the route was not called with `cancelled`. The handler alone looked reachable. No code changed.

- PATCH status docs still list `cancelled`, and `missed` after capture moves no money
  status: open
  **Found in:** plan 01-19 review of the item above, backend `openapi/clickme-api.yaml` (`/expert/bookings/{id}/status`) and the `patchStatus` docblock.
  **What:** both say `cancelled` is accepted, but the schema rejects it. Separately, `missed` on an already captured past session makes no refund, and the handler has no check on the current status. Neither client calls this route (iOS `main` has an unused API method; Android HEAD `2d04c4ce` has none).
  **Why deferred:** a doc fix in the backend repo, plus a low-priority product question. No current client reaches it.

- Client cancel can leave a hold with no flag when `retrievePI` fails within 24 hours
  status: open
  **Found in:** plan 01-19 review, backend `src/controllers/clientBooking.controller.js` `cancel`.
  **What:** a `retrievePI` failure on a non-pending booking falls back to `succeeded`. `computeRefundAmountMinorUnits` then returns 0 within 24 hours, so no Stripe call is made and `refund_failed` is not set. `cancelScheduledPayment` leaves a PaymentIntent the caller already knew about, and the capture sweeps skip `cancelled` rows. The hold stays on the card with nothing retrying it, until the authorization lapses. No charge results. Read from the code, not run on real Stripe.
  **Why deferred:** behavior that predates this project and is outside wave 3b. It belongs with the failed-refund fix above, because the same PaymentIntent read in the handler and sweep would address it.

- Comments still describe the old expert refund rule
  status: open
  **Found in:** plan 01-18 (BACK-19), backend `src/utils/refund.js` header (lists expert cancel as an importer), `src/services/stripe.js` `createRefund` docblock (says callers use the D-04 policy), `tests/refund.test.js` header.
  **What:** comments only; no behavior is affected.
  **Why deferred:** these files are outside the plan, which says `refund.js` is unchanged.

- A schema-valid setup PATCH that the controller then refuses still promotes
  status: open
  **Found in:** plan 01-20 (BACK-13), backend `src/routes/onboarding.js` and `src/controllers/onboarding.controller.js` `setupProfile`.
  **What:** every field in `onboardingSchema` is optional, so `{}` is a valid body and promotes a client-only account. `{ "setup_completed": true }` on an incomplete record also promotes, because the controller's 422 with `missing_fields` runs after `provisionExpert`; that 422 keeps the other fields it already saved, by design (quick-260715-vta). Only a schema failure promotes nothing.
  **Why deferred:** this matches the plan's wording (validate, then provision) and D-07 names the route, not a required field. A stricter rule would change the setup contract both shipped clients use, so it is a user decision. No promotion is possible from any other route.
  **Update (plan 01-22):** the behavior is unchanged and now stated in `docs/ios/EXPERT-SETUP-GATE.md` section 3 and on the OpenAPI setup operation. Whether to tighten it is a user decision at 01-23.

- Live UAT scripts and docs still assume a first `/expert/*` call converts the account
  status: open
  **Found in:** plan 01-20 (BACK-13), backend `scripts/uat-convert-expert.js`, `scripts/uat-topic-tags.js`, `scripts/uat-topic-owned-tags.js`, `scripts/uat-seed-notifications.js`, `docs/UAT-ACCOUNTS.md`, `docs/ios/EXPERT-EARNINGS-TRANSACTIONS.md` line 22.
  **What:** after wave 3c deploys, a client-only account is not converted by these paths, so a script that relies on it fails or reports the wrong result, and the transactions doc states the old behavior to client developers. Plan 01-22 sweeps `src/routes` and `src/middleware` and does not list these files.
  **Why deferred:** outside this plan's files, with no effect on production behavior. The doc line should be fixed alongside 01-22's contract docs.
  **Update (plan 01-22):** both docs are corrected in backend commit `8407402`, so only the scripts remain, and their behavior was not changed. Read from the code; none were run, because they call production. After wave 3c deploys:
  - `scripts/uat-convert-expert.js` **would fail.** It exists to prove first-touch conversion, and it hard-checks that `POST /expert/connect/onboard` is never a 403. It needs a rewrite or retirement.
  - `scripts/uat-topic-tags.js` and `scripts/uat-topic-owned-tags.js` should still pass with their defaults, `uat.expert@clickme.test` and `seed-expert-001@clickme.test`, as long as those accounts hold the expert role (not checked against production). Their comments saying any account works are now wrong: a client-only override account gets 403 on `POST /expert/topics`.
  - `scripts/uat-seed-notifications.js` **would not fail.** It makes no `/expert/*` call, and only its comment explaining `--as` mentions conversion.

- `src/services/stripeEvents.js` cites an old line number in `ensureExpert.js`
  status: open
  **Found in:** plan 01-20 (BACK-13), backend `src/services/stripeEvents.js` line 44.
  **What:** the comment points at `src/middleware/ensureExpert.js:82` for the upsert precedent, and that line moved when the file was rewritten. The upsert is now in `provisionExpert`. Comment only.
  **Why deferred:** outside this plan's files.

- One `expertBooking.test.js` flake has a likely cause: two separate `Date.now()` calls
  status: open
  **Found in:** plan 01-21 full-suite run, backend `tests/expertBooking.test.js` lines 273-274 (the same pair is at 693-694 and 1070-1071), failing assertion at line 2333.
  **What:** `futureStart` and `futureEnd` each call `Date.now()`. If the millisecond ticks between the two calls, `durationMs` is 60 minutes plus 1 ms, and `Math.ceil((durationMins + 30) / 30)` gives 4 while the window still has 3 keys. That is exactly the failure seen ("Expected: 4, Received: 3") in `slot_keys (quick 260804-qo6): sets NEW keys in the guarded UPDATE and releases OLD holds (array form)`, and it fits a failure that shows up under load. Read from the code; not reproduced by forcing the tick. It does not explain the `connectWebhooks.test.js` failures in the same run, whose first failure was a 5 s timeout.
  **Why deferred:** test infrastructure outside this plan's files, and no production behavior is involved. Likely fix: derive `futureEnd` from one captured timestamp.

- `ensureExpert.js` header does not mention the one read that uses the write gate
  status: resolved
  **Found in:** plan 01-21 (BACK-08), backend `src/middleware/ensureExpert.js`.
  **What:** the header says client-only reads pass through and `expertGate`'s comment says the method selects the gate. Both are true of the default export, but `GET /expert/tax-profile` now mounts `expertWriteGate` explicitly. The route file and table test record the exception.
  **Resolution (plan 01-22):** the header's `expertWriteGate` entry now names that read, in backend commit `8407402`.

- `clientBooking.test.js` failed 40 tests in one full-suite run and passed alone
  status: open
  **Found in:** plan 01-22 full-suite run, backend `tests/clientBooking.test.js`.
  **What:** the first of three full runs in this plan failed 40 of 3099 tests, all in this file (for example `BACK-14 cancel reason › applies the 500 character limit after trimming`, "Expected: 200, Received: 401", under a mocked `authenticate` that never returns 401). The same code passed 143 of 143 alone, and the next two full runs passed 3099 of 3099. Root cause not established. The failures look like one test's queued `mockReturnValueOnce` values leaking into the next, but that was not shown. The only uncommitted changes in that run were comments, so this plan did not cause it. This file was not on the known-flake list before.
  **Why deferred:** test infrastructure outside this plan's files, and no production behavior is involved.

- Comments still name a `roleCheck('expert')` that no expert route mounts
  status: open
  **Found in:** plan 01-22 (BACK-13) comment sweep, backend `src/routes/index.js` lines 81, 131, 139, 148, 153 and `src/controllers/analytics.controller.js` line 18.
  **What:** they say expert routes self-gate with `roleCheck('expert')`. Those routes use the BACK-13 expert gate, and `roleCheck` is mounted only with `'client'` on the booking routes. Comments only. They do not describe convert-on-demand, so the sweep does not cover them.
  **Why deferred:** outside this plan's files, and more than a one-line correction.
