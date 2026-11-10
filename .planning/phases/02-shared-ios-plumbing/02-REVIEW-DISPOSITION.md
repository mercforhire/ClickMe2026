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
    disposition: fixed
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
    disposition: fixed
    title: "`logout()` gives no feedback for up to 3 s while the user is still signed in"
  - id: IN-03
    severity: info
    disposition: open
    title: "Currency symbol is \"US$\" on the price label and \"$\" in the hint, on the same screen (outside phase plans: e43ef50/73e729e)"
open: 4
total: 7
recorded: 2026-11-10T17:57:39.457Z
---

# Phase 02: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | da16ef4 — both client fallbacks now `?? .unknown`; `ClientBookingStatusFallbackTests` green (verified 2026-11-10, 02-VERIFICATION.md) |
| WR-02 | warning | fixed | 1824a11 — user logout now runs DELETE, then Firebase deleteToken, then clears the session (Android order, user decision 2026-11-10), so Login cannot appear while the cleanup runs; isLoggingOut resets in clearLocalSession; PushTokenCleanup runs every deleteToken on one serialized lane and retryIfPending awaits it before the isPending check; PushTokenCleanupTests rows signOutOrder, aHungDeleteTokenStillFinishesLogoutWithinTheCap, aCompletedLogoutLeavesNothingForTheNextSignInToWaitOn, retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken, retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished, aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout, userAndInvoluntaryDeleteTokensNeverOverlap green (quick 261110-mmr, 2026-11-10) |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | fixed | 1824a11 — the Profile Log Out row (client and expert, ClientProfileHomeListItem isBusy) and the delete-account farewell's Back to Login button show a spinner and are disabled while UserManager.isLoggingOut holds, which now covers the whole wait (DELETE then deleteToken, up to about 6 s); device check in UAT item 14 (e) (quick 261110-mmr, 2026-11-10) |
| IN-03 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
