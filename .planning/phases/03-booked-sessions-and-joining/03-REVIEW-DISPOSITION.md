---
phase: 03
review: 03-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "After a successful accept, a failed refetch leaves the Accept/Decline card on screen"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Post-cancel toast can promise a refund the server did not issue"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Refund and hold lines show the list price, not the amount paid"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Reschedule is offered on every booking status; only Cancel was gated"
  - id: WR-05
    severity: warning
    disposition: open
    title: "Reschedule accept/decline succeeds silently in the expert shell"
  - id: WR-06
    severity: warning
    disposition: open
    title: "`ToastCenterTests` use real sleeps with thin margins"
  - id: WR-07
    severity: warning
    disposition: open
    title: "`submitRefusesFarSlot` would call the live backend if its guard regressed"
  - id: WR-08
    severity: warning
    disposition: open
    title: "After a successful accept or decline with a failed refetch, the screen still shows the old time and a \"Pending reschedule\" status, and nothing retries"
  - id: WR-09
    severity: warning
    disposition: open
    title: "Post-cancel toast reads the refund case after the await, so the 60 s tick can change the case the user confirmed under"
  - id: IN-01
    severity: info
    disposition: open
    title: "`bannerFinalStretch` test cannot distinguish the final-stretch branch"
  - id: IN-02
    severity: info
    disposition: open
    title: "`HomeNavigationPathTests` do not cover the route wiring that makes `pop(2)` correct"
  - id: IN-03
    severity: info
    disposition: open
    title: "Duplicate error-message helper"
  - id: IN-04
    severity: info
    disposition: open
    title: "Booking Summary shows the response card without a status check"
  - id: IN-05
    severity: info
    disposition: open
    title: "`startCall()` returns silently when join inputs are missing"
  - id: IN-06
    severity: info
    disposition: open
    title: "`.chargedNotRefundable` at server 0 still states \"No refund applies\", the same ambiguity WR-02 removed for the refundable case"
open: 13
total: 15
recorded: 2026-11-11T20:55:36.547Z
---

# Phase 03: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 03-16 (gap G-03-3-WR01) |
| WR-02 | warning | fixed | 03-17 (gap G-03-3-WR02) |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| WR-06 | warning | open | - |
| WR-07 | warning | open | - |
| WR-08 | warning | open | - |
| WR-09 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
