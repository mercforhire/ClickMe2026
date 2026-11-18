---
phase: 07
review: 07-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "A stale `GET /chats` scan can undo a block or unblock that finished while it was running"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "`recipientUnavailable` is never cleared, so the composer stays disabled until the screen is rebuilt"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Socket.IO client logging is on in all builds and logs message traffic"
  - id: WR-04
    severity: warning
    disposition: fixed
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
open: 5
total: 9
recorded: 2026-11-18T16:03:41.148Z
---

# Phase 07: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 07-REVIEW-FIX.md |
| WR-02 | warning | fixed | 07-REVIEW-FIX.md |
| WR-03 | warning | fixed | 07-REVIEW-FIX.md |
| WR-04 | warning | fixed | 07-REVIEW-FIX.md |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
