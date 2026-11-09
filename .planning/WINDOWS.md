---
schema_version: 1
open_count: 8
waived_count: 0
fixed_count: 0
total_count: 8
last_updated: 2026-11-09T01:06:43.585Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | deviation | tests/services/redis.test.js |  | 01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis) | open |  | 2026-11-08T17:25:53.004Z |  |
| 2 | 01 | deviation | tests/services/redis.test.js |  | 01-15 wave-2 gate excluded tests/services/redis.test.js (no local Redis) | open |  | 2026-11-09T00:17:57.404Z |  |
| 3 | 01 | deviation | src/services/connectedPaymentMethodClone.js |  | 01-16 D-13 local Stripe test-mode run dropped by user decision (Open Q7); Stripe behavior verified with mocks only until the 01-17 real-card smoke | open |  | 2026-11-09T00:28:14.347Z |  |
| 4 | 01 | deviation | tests/services/redis.test.js |  | 01-17 wave-3a gate excluded tests/services/redis.test.js (no local Redis) | open |  | 2026-11-09T00:34:49.908Z |  |
| 5 | 01 | unrun-verify | .planning/phases/01-backend-fixes/01-17-SUMMARY.md |  | 01-17 wave-3a real-card smoke not run (user skip 2026-11-08): BACK-06/BACK-07 stay Pending; real clone detach never run against real Stripe; run the 01-17 checklist, at the latest during Phase 4 payment UAT | open |  | 2026-11-09T01:00:39.518Z |  |
| 6 | 01 | deviation | .planning/phases/01-backend-fixes/01-18-SUMMARY.md |  | 01-18 BACK-19 D-13 deviation: verified with mocked Stripe only; the captured refund branch has never run against real Stripe and cannot be reached safely on live data | open |  | 2026-11-09T01:06:43.406Z |  |
| 7 | 01 | unrun-verify | tests/services/redis.test.js |  | 01-18 wave-3b gate excluded tests/services/redis.test.js (no local Redis) | open |  | 2026-11-09T01:06:43.491Z |  |
| 8 | 01 | fixme | src/controllers/expertBooking.controller.js |  | 01-18 BACK-19: a failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI instead of a refund and the client is not refunded; see deferred-items.md | open |  | 2026-11-09T01:06:43.585Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-08T17:25:53.004Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "01",
    "file": "tests/services/redis.test.js",
    "line": null,
    "description": "01-15 wave-2 gate excluded tests/services/redis.test.js (no local Redis)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T00:17:57.404Z",
    "resolved_at": null,
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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T00:34:49.908Z",
    "resolved_at": null,
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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.491Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 8,
    "kind": "fixme",
    "phase": "01",
    "file": "src/controllers/expertBooking.controller.js",
    "line": null,
    "description": "01-18 BACK-19: a failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI instead of a refund and the client is not refunded; see deferred-items.md",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-11-09T01:06:43.585Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
