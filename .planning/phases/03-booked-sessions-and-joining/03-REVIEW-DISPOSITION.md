---
phase: 03
review: 03-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "\"PAID\" label is shown for bookings that were never charged, and the new `.unknown` case widens it"
  - id: IN-01
    severity: info
    disposition: open
    title: "New localizable strings are not yet in the String Catalog"
  - id: IN-02
    severity: info
    disposition: open
    title: "Em-dash value has no accessibility text"
  - id: IN-03
    severity: info
    disposition: open
    title: "Price tests compare against English literals and rely on fixture defaults"
  - id: WR-10
    severity: warning
    disposition: fixed
    title: "Message Client on the expert Booking Summary fails silently and can push the chat twice"
  - id: WR-11
    severity: warning
    disposition: open
    title: "`tickDuringRequestKeepsConfirmedCase` waits on a yield count, not on time, and blocks a thread on a semaphore"
  - id: IN-04
    severity: info
    disposition: open
    title: "The reschedule response card is not gated on booking status (carried forward, now on two screens)"
  - id: IN-05
    severity: info
    disposition: open
    title: "`startCall()` returns silently when join inputs are missing (carried forward)"
  - id: IN-06
    severity: info
    disposition: open
    title: "`.chargedNotRefundable` at server 0 still says \"No refund applies\" (carried forward)"
  - id: IN-07
    severity: info
    disposition: open
    title: "The confirm step shows a refund case that is only as fresh as the load, until the first 60 s tick"
  - id: IN-08
    severity: info
    disposition: open
    title: "`rescheduleListsAreExhaustive` claims exhaustiveness it does not check"
  - id: IN-09
    severity: info
    disposition: open
    title: "`rescheduleTimesRow` builds two throwaway `RescheduleProposal` values just to format a date"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Post-cancel toast can promise a refund the server did not issue"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Refund and hold lines show the list price, not the amount paid"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "Reschedule is offered on every booking status; only Cancel was gated"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "Reschedule accept/decline succeeds silently in the expert shell"
  - id: WR-06
    severity: warning
    disposition: fixed
    title: "`ToastCenterTests` use real sleeps with thin margins"
  - id: WR-07
    severity: warning
    disposition: fixed
    title: "`submitRefusesFarSlot` would call the live backend if its guard regressed"
  - id: WR-08
    severity: warning
    disposition: fixed
    title: "After a successful accept or decline with a failed refetch, the screen still shows the old time and a \"Pending reschedule\" status, and nothing retries"
  - id: WR-09
    severity: warning
    disposition: fixed
    title: "Post-cancel toast reads the refund case after the await, so the 60 s tick can change the case the user confirmed under"
open: 11
total: 20
recorded: 2026-11-23T04:47:22.173Z
---

# Phase 03: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| WR-10 | warning | fixed | quick 261122-tcf (ChatStarter on the three expert Message buttons) (not in the current review) |
| WR-11 | warning | open | - (not in the current review) |
| IN-04 | info | open | - (not in the current review) |
| IN-05 | info | open | - (not in the current review) |
| IN-06 | info | open | - (not in the current review) |
| IN-07 | info | open | - (not in the current review) |
| IN-08 | info | open | - (not in the current review) |
| IN-09 | info | open | - (not in the current review) |
| WR-02 | warning | fixed | 03-17 (gap G-03-3-WR02) (not in the current review) |
| WR-03 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |
| WR-04 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |
| WR-05 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |
| WR-06 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |
| WR-07 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |
| WR-08 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |
| WR-09 | warning | fixed | 03-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
