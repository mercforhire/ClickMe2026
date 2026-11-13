---
phase: 05
review: 05-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "`resolvePostAuthLanding` writes state after the session may have ended"
  - id: WR-02
    severity: warning
    disposition: open
    title: "`refreshExpertProfile` repopulates `expertProfile` after logout"
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
  - id: IN-01
    severity: info
    disposition: open
    title: "The checklist and the publish gate disagree on an empty `avatarUrl`"
  - id: IN-02
    severity: info
    disposition: open
    title: "Tapping the already-active Expert mode triggers a lookup and can open the setup hub"
  - id: IN-03
    severity: info
    disposition: open
    title: "`DeleteAccountView` reads `UserManager.shared` directly instead of the view model's injected manager"
  - id: IN-04
    severity: info
    disposition: open
    title: "`RememberedLoginEmailTests` mutates the real Keychain through the singleton"
open: 10
total: 10
recorded: 2026-11-13T22:59:14.045Z
---

# Phase 05: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| WR-06 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
