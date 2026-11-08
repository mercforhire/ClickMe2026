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
