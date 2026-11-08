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
