---
phase: 02
review: 02-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Client screens coerce an unknown booking status to `.confirmed`, so BOOK-18 is only half-applied"
  - id: WR-02
    severity: warning
    disposition: open
    title: "`isLoggingOut` stays true after the login screen is up, so a fast re-login can silently skip push registration"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Typed topic price is always multiplied by 100, ignoring the currency's digits, and can overflow (outside phase plans: e43ef50/73e729e)"
  - id: WR-04
    severity: warning
    disposition: open
    title: "`PI_CURRENCY_MISMATCH` is declared but not handled in the paid-booking error path (outside phase plans: e43ef50/73e729e)"
  - id: IN-01
    severity: info
    disposition: open
    title: "Dead production helper and stale \"hide\" wording after the dim-not-hide decision"
  - id: IN-02
    severity: info
    disposition: open
    title: "`logout()` gives no feedback for up to 3 s while the user is still signed in"
  - id: IN-03
    severity: info
    disposition: open
    title: "Currency symbol is \"US$\" on the price label and \"$\" in the hint, on the same screen (outside phase plans: e43ef50/73e729e)"
open: 6
total: 7
recorded: 2026-11-10T17:57:39.457Z
---

# Phase 02: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | da16ef4 — both client fallbacks now `?? .unknown`; `ClientBookingStatusFallbackTests` green (verified 2026-11-10, 02-VERIFICATION.md) |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
