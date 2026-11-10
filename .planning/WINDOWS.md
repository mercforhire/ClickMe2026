---
schema_version: 1
open_count: 8
waived_count: 0
fixed_count: 7
total_count: 15
last_updated: 2026-11-10T05:04:00.631Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | deviation | tests/services/redis.test.js |  | 01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-08T17:25:53.004Z | 2026-11-09T03:13:09.560Z |
| 2 | 01 | deviation | tests/services/redis.test.js |  | 01-15 wave-2 gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T00:17:57.404Z | 2026-11-09T03:13:09.645Z |
| 3 | 01 | deviation | src/services/connectedPaymentMethodClone.js |  | 01-16 D-13 local Stripe test-mode run dropped by user decision (Open Q7); Stripe behavior verified with mocks only until the 01-17 real-card smoke | open |  | 2026-11-09T00:28:14.347Z |  |
| 4 | 01 | deviation | tests/services/redis.test.js |  | 01-17 wave-3a gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T00:34:49.908Z | 2026-11-09T03:13:09.727Z |
| 5 | 01 | unrun-verify | .planning/phases/01-backend-fixes/01-17-SUMMARY.md |  | 01-17 wave-3a real-card smoke not run (user skip 2026-11-08): BACK-06/BACK-07 stay Pending; real clone detach never run against real Stripe; run the 01-17 checklist, at the latest during Phase 4 payment UAT | open |  | 2026-11-09T01:00:39.518Z |  |
| 6 | 01 | deviation | .planning/phases/01-backend-fixes/01-18-SUMMARY.md |  | 01-18 BACK-19 D-13 deviation: verified with mocked Stripe only; the captured refund branch has never run against real Stripe and cannot be reached safely on live data | open |  | 2026-11-09T01:06:43.406Z |  |
| 7 | 01 | unrun-verify | tests/services/redis.test.js |  | 01-18 wave-3b gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T01:06:43.491Z | 2026-11-09T03:13:09.809Z |
| 8 | 01 | fixme | src/controllers/expertBooking.controller.js |  | 01-18 BACK-19: a failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI instead of a refund and the client is not refunded. User chose option A (2026-11-08): the fix needs its own plan and deploy before Phase 4 payment UAT, and that plan still needs creating; see deferred-items.md | fixed |  | 2026-11-09T01:06:43.585Z | 2026-11-09T05:33:41.054Z |
| 9 | 01 | deviation | tests/services/redis.test.js |  | 01-19 wave-3b gate excluded tests/services/redis.test.js (no local Redis) | fixed |  | 2026-11-09T01:16:27.446Z | 2026-11-09T03:13:09.890Z |
| 10 | 01 | fixme | src/controllers/clientBooking.controller.js |  | 01-19: client cancel within 24h with a retrievePI failure leaves the hold with no flag and no retry until the authorization lapses; see deferred-items.md | fixed |  | 2026-11-09T01:16:27.542Z | 2026-11-09T05:33:41.136Z |
| 11 | 01 | unrun-verify | .planning/phases/01-backend-fixes/01-19-SUMMARY.md |  | 01-19 wave-3b production smoke not run (user skip 2026-11-08): BACK-19 stays Pending; expert-cancel hold release not confirmed on production; run the 01-19 checklist, at the latest during Phase 4 payment UAT | open |  | 2026-11-09T02:16:24.413Z |  |
| 12 | 01 | unmet-truth | .planning/phases/01-backend-fixes/01-23-SUMMARY.md |  | 01-23 wave 3c dropped by user decision (2026-11-08): BACK-08 and BACK-13 not delivered; silent client-to-expert promotion and the tax-ID prompt remain in production; code parked on local backend branch wave-3c; needs a new decision | open |  | 2026-11-09T03:13:09.977Z |  |
| 13 | 02 | unrun-verify | .planning/phases/02-shared-ios-plumbing/02-05-SUMMARY.md |  | 02-05 BOOK-10 device check not run (user approve and defer 2026-11-09): CAD topic 12.50 shows CA$12.50 and 12.00 shows CA$12.00 on Make a Booking, Explore, Expert Profile, Payment History; add to 02-12 device UAT checklist | open |  | 2026-11-10T04:09:27.895Z |  |
| 14 | 02 | deviation | ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift |  | 02-08: user-directed Android parity for the paid 6-day cap (days visible, slots dimmed, fixed note) supersedes the 02-07/02-08 blank-day rule; 02-UI-SPEC section 4 and W1-9/W1-10 need revising | open |  | 2026-11-10T04:38:43.121Z |  |
| 15 | 02 | unrun-verify | ClickMe2026/Managers/PushRouter.swift |  | 02-10 PUSH-01 device check deferred (user, at the Task 1 tracer gate): backgrounded client-mode app, expert accepts a pending request, tap the booking-confirmed push; expected Bookings tab opens that booking with no warning page and Back returns to My Bookings. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md | open |  | 2026-11-10T05:04:00.631Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-08T17:25:53.004Z",
    "resolved_at": "2026-11-09T03:13:09.560Z",
    "milestone": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-15 wave-2 gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T00:17:57.404Z",
    "resolved_at": "2026-11-09T03:13:09.645Z",
    "milestone": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "01",
    "file": "src/services/connectedPaymentMethodClone.js",
    "line": null,
    "description": "01-16 D-13 local Stripe test-mode run dropped by user decision (Open Q7); Stripe behavior verified with mocks only until the 01-17 real-card smoke",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T00:28:14.347Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-17 wave-3a gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T00:34:49.908Z",
    "resolved_at": "2026-11-09T03:13:09.727Z",
    "milestone": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-17-SUMMARY.md",
    "line": null,
    "description": "01-17 wave-3a real-card smoke not run (user skip 2026-11-08): BACK-06/BACK-07 stay Pending; real clone detach never run against real Stripe; run the 01-17 checklist, at the latest during Phase 4 payment UAT",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T01:00:39.518Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-18-SUMMARY.md",
    "line": null,
    "description": "01-18 BACK-19 D-13 deviation: verified with mocked Stripe only; the captured refund branch has never run against real Stripe and cannot be reached safely on live data",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.406Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-18 wave-3b gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.491Z",
    "resolved_at": "2026-11-09T03:13:09.809Z",
    "milestone": null
  },
  {
    "id": 8,
    "kind": "fixme",
    "phase": "01",
    "file": "src/controllers/expertBooking.controller.js",
    "line": null,
    "description": "01-18 BACK-19: a failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI instead of a refund and the client is not refunded. User chose option A (2026-11-08): the fix needs its own plan and deploy before Phase 4 payment UAT, and that plan still needs creating; see deferred-items.md",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.585Z",
    "resolved_at": "2026-11-09T05:33:41.054Z",
    "milestone": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-19 wave-3b gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:16:27.446Z",
    "resolved_at": "2026-11-09T03:13:09.890Z",
    "milestone": null
  },
  {
    "id": 10,
    "kind": "fixme",
    "phase": "01",
    "file": "src/controllers/clientBooking.controller.js",
    "line": null,
    "description": "01-19: client cancel within 24h with a retrievePI failure leaves the hold with no flag and no retry until the authorization lapses; see deferred-items.md",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-11-09T01:16:27.542Z",
    "resolved_at": "2026-11-09T05:33:41.136Z",
    "milestone": null
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-19-SUMMARY.md",
    "line": null,
    "description": "01-19 wave-3b production smoke not run (user skip 2026-11-08): BACK-19 stays Pending; expert-cancel hold release not confirmed on production; run the 01-19 checklist, at the latest during Phase 4 payment UAT",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T02:16:24.413Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 12,
    "kind": "unmet-truth",
    "phase": "01",
    "file": ".planning/phases/01-backend-fixes/01-23-SUMMARY.md",
    "line": null,
    "description": "01-23 wave 3c dropped by user decision (2026-11-08): BACK-08 and BACK-13 not delivered; silent client-to-expert promotion and the tax-ID prompt remain in production; code parked on local backend branch wave-3c; needs a new decision",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T03:13:09.977Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 13,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-shared-ios-plumbing/02-05-SUMMARY.md",
    "line": null,
    "description": "02-05 BOOK-10 device check not run (user approve and defer 2026-11-09): CAD topic 12.50 shows CA$12.50 and 12.00 shows CA$12.00 on Make a Booking, Explore, Expert Profile, Payment History; add to 02-12 device UAT checklist",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T04:09:27.895Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "02",
    "file": "ClickMe2026/Views/Screens/Client Mode/Reschedule/Subviews/RescheduleCalendarCard.swift",
    "line": null,
    "description": "02-08: user-directed Android parity for the paid 6-day cap (days visible, slots dimmed, fixed note) supersedes the 02-07/02-08 blank-day rule; 02-UI-SPEC section 4 and W1-9/W1-10 need revising",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T04:38:43.121Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 15,
    "kind": "unrun-verify",
    "phase": "02",
    "file": "ClickMe2026/Managers/PushRouter.swift",
    "line": null,
    "description": "02-10 PUSH-01 device check deferred (user, at the Task 1 tracer gate): backgrounded client-mode app, expert accepts a pending request, tap the booking-confirmed push; expected Bookings tab opens that booking with no warning page and Back returns to My Bookings. Pending for 02-12 / 02-DEVICE-UAT-CHECKLIST.md",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-10T05:04:00.631Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
