---
phase: 04
review: 04-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "A confirm retry re-reads the live topic and slot, and the form is not locked while confirming"
  - id: CR-02
    severity: critical
    disposition: open
    title: "D-12 sweep, \"a transient Stripe error never cancels\" is false end to end (deployed in ae3ec1a)"
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
open: 13
total: 13
recorded: 2026-11-12T15:39:31.870Z
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
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved.
