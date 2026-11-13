---
phase: 04
review: 04-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Overlapping `/client/home` fetches race, and the last response to land wins regardless of filter"
  - id: WR-02
    severity: warning
    disposition: open
    title: "A cancelled category-change fetch restores `.loaded` with the previous filter's experts"
  - id: WR-03
    severity: warning
    disposition: open
    title: "The \"while `.loading`, the fetch that set it is in flight\" invariant does not hold, so a cancelled fetch can settle sections a different fetch owns"
  - id: IN-01
    severity: info
    disposition: open
    title: "A failed refresh still wipes loaded content, which is inconsistent with the stated \"keep what's on screen\" intent"
  - id: IN-02
    severity: info
    disposition: open
    title: "Triplicated per-section state code, with lines past the advisory 120 columns"
  - id: IN-03
    severity: info
    disposition: open
    title: "`MockURLProtocol` is only partly made thread-safe"
  - id: IN-04
    severity: info
    disposition: open
    title: "Held-response tests block the shared URL protocol thread and depend on wall-clock polling"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "RESOLVED (iOS, plans 04-15)"
  - id: CR-02
    severity: critical
    disposition: fixed
    title: "RESOLVED for the platform-card check (backend `28da165`); the broader promise is still open as WR-06"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Returning to Make a Booking re-runs `onAppear` and silently clears the chosen slot"
  - id: WR-05
    severity: warning
    disposition: open
    title: "Favorites list races and stale state"
  - id: WR-06
    severity: warning
    disposition: deferred
    title: "A transient error AFTER the stamp still ends in a wrongful cancellation about 6 h later (open, tracked as T-04-45) (new)"
  - id: WR-07
    severity: warning
    disposition: deferred
    title: "The pre-stamp retry has no deadline, so a persistent error can leave a delivered session uncharged (accepted by the user, recorded for visibility) (new)"
  - id: IN-05
    severity: info
    disposition: open
    title: "The paid-flow alert binding ignores dismissal"
  - id: IN-06
    severity: info
    disposition: open
    title: "D-12 backend operational notes"
  - id: IN-07
    severity: info
    disposition: open
    title: "The snapshot reads `meetingType` and `clientNotes` after the network calls, and `paidAttempt` is writable from anywhere (new)"
  - id: IN-08
    severity: info
    disposition: open
    title: "A slot kept across a reload can be selected while the refreshed calendar shows it unavailable (new)"
  - id: IN-09
    severity: info
    disposition: open
    title: "Wall-clock timing in the confirm-race tests can flake under load (new)"
open: 14
total: 18
recorded: 2026-11-13T04:39:32.935Z
---

# Phase 04: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| CR-01 | critical | fixed | plan 04-15 (6184f6c, 50f55de, 2baa72d) (not in the current review) |
| CR-02 | critical | fixed | plan 04-16 (backend 28da165, deployed) (not in the current review) |
| WR-04 | warning | open | - (not in the current review) |
| WR-05 | warning | open | - (not in the current review) |
| WR-06 | warning | deferred | todo 2026-11-12-long-lead-sweep-transient-errors-after-stamp; T-04-45 (not in the current review) |
| WR-07 | warning | deferred | user-accepted limit (a)/(b), 04-16 checkpoint 2026-11-12; T-04-44 (not in the current review) |
| IN-05 | info | open | - (not in the current review) |
| IN-06 | info | open | - (not in the current review) |
| IN-07 | info | open | - (not in the current review) |
| IN-08 | info | open | - (not in the current review) |
| IN-09 | info | open | - (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
