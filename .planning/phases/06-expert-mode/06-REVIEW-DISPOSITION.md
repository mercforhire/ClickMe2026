---
phase: 06
review: 06-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: accepted
    note: "Accepted by the user in UAT 2026-11-16. The server's 409 ALREADY_PROCESSED guard (device-checked in checklist item 19) prevents any wrong charge; the misleading Accept/Decline screen on a push-opened expired or settled request stays as is."
    title: "Expired or already-settled request opened from a push still shows Accept and Decline"
  - id: WR-02
    severity: warning
    disposition: open
    note: "To fix in Phase 6: confirmed on device in UAT 2026-11-16 (every free topic opens on a blank currency and fails to save). Gap G-06-1-currency in 06-UAT.md."
    title: "Legacy free topic with no stored currency opens with an empty-string currency and cannot be saved"
  - id: WR-03
    severity: warning
    disposition: accepted
    note: "Accepted by the user in UAT 2026-11-16: a price of 1,000 or more is unlikely. A reasonable maximum price (none exists today in the iOS rules or the backend) is logged as a deferred follow-up in 06-UAT.md."
    title: "A pasted grouped price (\"12,000\") is silently read as 12.00"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Android hides the USD conversion-fee notice when only one currency is pickable; iOS shows it"
  - id: IN-01
    severity: info
    disposition: open
    title: "Android new-topic default can fall outside the allowed list; iOS picks the first allowed one"
  - id: IN-02
    severity: info
    disposition: open
    title: "Back to Home from Booking Confirmed is a silent no-op outside the expert shell"
  - id: IN-03
    severity: info
    disposition: open
    title: "Stale planning reference and duplicated duration math"
  - id: IN-04
    severity: info
    disposition: open
    title: "Misindented argument in `ExpertProfileHomeScreen`"
  - id: IN-05
    severity: info
    disposition: open
    title: "Capped `TextEditor` bindings should be checked on a device"
---

# Phase 06 — Code Review Disposition

Ledger of what happened to each finding in `06-REVIEW.md`. Every finding defaults to `open`; update a row's `disposition` (`fixed`, `accepted`, `deferred`, `wont-fix`) when it is triaged.

Counts: 0 critical, 4 warning, 5 info (9 total).
