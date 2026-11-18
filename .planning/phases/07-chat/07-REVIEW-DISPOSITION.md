---
phase: 07
review: 07-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "A stale `GET /chats` scan can undo a block or unblock that finished while it was running"
  - id: WR-02
    severity: warning
    disposition: open
    title: "`recipientUnavailable` is never cleared, so the composer stays disabled until the screen is rebuilt"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Socket.IO client logging is on in all builds and logs message traffic"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Chats list reloads can overwrite local unread changes and double-fetch during the first load"
  - id: IN-01
    severity: info
    disposition: open
    title: "`sendFailure` treats every 4xx as a permanent refusal, including 401, 408 and 429"
  - id: IN-02
    severity: info
    disposition: open
    title: "`.timestamp` rows would be moved to the end by `ChatThreadReducer.order`"
  - id: IN-03
    severity: info
    disposition: open
    title: "`Int(d)` in `extractInt` can trap on an out-of-range double"
  - id: IN-04
    severity: info
    disposition: open
    title: "Empty accessibility label on non-pending bubble containers"
  - id: IN-05
    severity: info
    disposition: open
    title: "Test timing helpers hide failures and one negative check is a fixed sleep"
open: 9
total: 9
recorded: 2026-11-18T15:46:53.447Z
---

# Phase 07: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | 07-REVIEW.md |
| WR-02 | warning | open | 07-REVIEW.md |
| WR-03 | warning | open | 07-REVIEW.md |
| WR-04 | warning | open | 07-REVIEW.md |
| IN-01 | info | open | 07-REVIEW.md |
| IN-02 | info | open | 07-REVIEW.md |
| IN-03 | info | open | 07-REVIEW.md |
| IN-04 | info | open | 07-REVIEW.md |
| IN-05 | info | open | 07-REVIEW.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved.
