---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 0
total_count: 1
last_updated: 2026-11-08T17:25:53.004Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | deviation | tests/services/redis.test.js |  | 01-10 wave-1 gate excluded tests/services/redis.test.js (no local Redis) | open |  | 2026-11-08T17:25:53.004Z |  |

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
  }
]
````
