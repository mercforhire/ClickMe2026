---
phase: 04
review: 04-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "RESOLVED (iOS, plans 04-15)"
  - id: CR-02
    severity: critical
    disposition: open
    title: "RESOLVED for the platform-card check (backend `28da165`); the broader promise is still open as WR-06"
  - id: WR-01
    severity: warning
    disposition: open
    title: "SCA retry sends the connected-account clone's `pm_` id, and the original `pm_` is thrown away (needs device verification)"
  - id: WR-02
    severity: warning
    disposition: open
    title: "A failed re-load replaces an already-loaded expert profile with the full-screen error"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Explore loads have no latest-wins gate, so a slow older response can overwrite a newer category filter"
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
    disposition: open
    title: "A transient error AFTER the stamp still ends in a wrongful cancellation about 6 h later (open, tracked as T-04-45) (new)"
  - id: WR-07
    severity: warning
    disposition: open
    title: "The pre-stamp retry has no deadline, so a persistent error can leave a delivered session uncharged (accepted by the user, recorded for visibility) (new)"
  - id: IN-01
    severity: info
    disposition: open
    title: "Private `message(for:)` helpers duplicate `Error.userMessage`"
  - id: IN-02
    severity: info
    disposition: open
    title: "`PI_CURRENCY_MISMATCH` and `PAID_TOPIC_REQUIRES_PAYMENT` fall through to the default branch"
  - id: IN-03
    severity: info
    disposition: open
    title: "Dead branch in `PaymentLifecycleCard.titleColor`"
  - id: IN-04
    severity: info
    disposition: open
    title: "Cancellation and default handling in `MakeABookingViewModel` loaders"
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
open: 18
total: 18
recorded: 2026-11-12T19:37:05.523Z
---

# Phase 04: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | - |
| CR-02 | critical | open | - |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| WR-06 | warning | open | - |
| WR-07 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-07 | info | open | - |
| IN-08 | info | open | - |
| IN-09 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
