---
phase: 06
review: 06-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Topic editor seeds the price text with a different currency than the one it selects"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Calendar sheet content is built from the same optional that drives `isPresented`, and the pattern is copy-pasted"
  - id: IN-01
    severity: info
    disposition: open
    title: "Production code left unused after the delegation refactor"
  - id: IN-02
    severity: info
    disposition: open
    title: "Duplicated `trimmed` helper and a circular dependency between the two content enums"
  - id: IN-03
    severity: info
    disposition: open
    title: "Stale plan reference in a doc comment"
  - id: IN-04
    severity: info
    disposition: open
    title: "Redundant status gate in two views"
  - id: IN-05
    severity: info
    disposition: open
    title: "Summary view modifier layout and comment"
  - id: IN-06
    severity: info
    disposition: open
    title: "Card currency symbol differs from the editor's for codes other than USD and CAD"
  - id: IN-07
    severity: info
    disposition: open
    title: "New tests depend on shared global state"
open: 9
total: 9
recorded: 2026-11-17T05:51:07.607Z
---

# Phase 06: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-07 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
