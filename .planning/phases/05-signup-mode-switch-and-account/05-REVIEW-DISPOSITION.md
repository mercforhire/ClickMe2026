---
phase: 05
review: 05-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "Clearing the meeting link is never sent, yet the screen shows \"saved\""
  - id: WR-01
    severity: warning
    disposition: open
    title: "`ProfileSaveErrorMapper` hides the useful message for expert-only 422 fields, and drops unmapped fields when any mapped one is present"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Overlapping auto-saves are not serialised"
  - id: IN-01
    severity: info
    disposition: open
    title: "Inconsistent whitespace trimming"
  - id: IN-02
    severity: info
    disposition: open
    title: "The new inline error text has no accessibility treatment"
  - id: IN-03
    severity: info
    disposition: open
    title: "Test and code hygiene"
  - id: WR-03
    severity: warning
    disposition: open
    title: "A push-initiated Expert switch clears the user's \"Not now\" deferral"
  - id: WR-04
    severity: warning
    disposition: open
    title: "A wrong password on `delete-request` triggers a token refresh and a second request"
  - id: WR-05
    severity: warning
    disposition: open
    title: "`loadExistingAvatarIfNeeded` can overwrite a photo the user picked while it downloads"
  - id: WR-06
    severity: warning
    disposition: open
    title: "Flipping a notification toggle back during an in-flight save cancels it and skips the resave"
  - id: IN-04
    severity: info
    disposition: open
    title: "`RememberedLoginEmailTests` mutates the real Keychain through the singleton"
open: 11
total: 11
recorded: 2026-11-15T05:11:10.439Z
---

# Phase 05: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | - |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| WR-03 | warning | open | - (not in the current review) |
| WR-04 | warning | open | - (not in the current review) |
| WR-05 | warning | open | - (not in the current review) |
| WR-06 | warning | open | - (not in the current review) |
| IN-04 | info | open | - (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
