---
phase: 07
review: 07-REVIEW.md
titles: json
findings:
  - id: WR-07
    severity: warning
    disposition: fixed
    title: "A live message without text content makes the late-reload overlay replace the server's newer preview with the stale local one (regression from the WR-05 fix)"
  - id: IN-06
    severity: info
    disposition: skipped
    title: "The \"unavailable\" banner does not tell the user that pull-to-refresh retries"
  - id: IN-08
    severity: info
    disposition: open
    title: "The WR-06 follow-up fetch swallows its own failure"
  - id: IN-09
    severity: info
    disposition: open
    title: "iOS and Android now differ on 408 and 429 for a failed chat send"
  - id: IN-10
    severity: info
    disposition: open
    title: "Recorded row changes are not scoped to the reloads that started before them"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "A late `GET /chats` still replaces the live row's preview, time and order, and a `markOpened` on a row that is not listed yet is lost (incomplete fix of WR-04, part 1)"
  - id: WR-06
    severity: warning
    disposition: fixed
    title: "A new conversation's first message is dropped if it arrives while a load is in flight (regression from the WR-04 part 2 fix)"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "`sendFailure` treats every 4xx as a permanent refusal, including 401, 408 and 429"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "`.timestamp` rows would be moved to the end by `ChatThreadReducer.order`"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "`Int(d)` in `extractInt` can trap on an out-of-range double"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "Empty accessibility label on non-pending bubble containers"
  - id: IN-05
    severity: info
    disposition: fixed
    title: "Test timing helpers hide failures and one negative check is a fixed sleep"
  - id: IN-07
    severity: info
    disposition: fixed
    title: "Two copies of the test `Gate` helper that behave differently"
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
open: 3
total: 17
recorded: 2026-11-19T04:07:11.806Z
---

# Phase 07: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-07 | warning | fixed | 07-REVIEW-FIX.md |
| IN-06 | info | skipped | 07-REVIEW-FIX.md |
| IN-08 | info | open | - |
| IN-09 | info | open | - |
| IN-10 | info | open | - |
| WR-05 | warning | fixed | 07-REVIEW-FIX.md (not in the current review) |
| WR-06 | warning | fixed | 07-REVIEW-FIX.md (not in the current review) |
| IN-01 | info | fixed | 07-REVIEW-FIX.md (not in the current review) |
| IN-02 | info | fixed | 07-REVIEW-FIX.md (not in the current review) |
| IN-03 | info | fixed | 07-REVIEW-FIX.md (not in the current review) |
| IN-04 | info | fixed | 07-REVIEW-FIX.md (not in the current review) |
| IN-05 | info | fixed | 07-REVIEW-FIX.md (not in the current review) |
| IN-07 | info | fixed | 07-REVIEW-FIX.md (not in the current review) |
| WR-01 | warning | fixed | 07-REVIEW-FIX.md (not in the current review) |
| WR-02 | warning | fixed | 07-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 07-REVIEW-FIX.md (not in the current review) |
| WR-04 | warning | fixed | 07-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
