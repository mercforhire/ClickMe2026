---
phase: 05
review: 05-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Clearing the meeting link is never sent, yet the screen shows \"saved\""
  - id: WR-01
    severity: warning
    disposition: open
    title: "Reload overwrites the field and baseline from a possibly stale cached profile"
  - id: WR-02
    severity: warning
    disposition: open
    title: "A 422 on the meeting link still shows the generic message (carried forward, prior WR-01)"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Overlapping auto-saves are not serialised (carried forward, prior WR-02)"
  - id: IN-01
    severity: info
    disposition: open
    title: "`meetingLinkBody` trims the baseline redundantly"
  - id: IN-02
    severity: info
    disposition: open
    title: "The `forceLoad` wiring is untested"
  - id: IN-03
    severity: info
    disposition: open
    title: "Leftover dead section and unchanged prior Info items (prior IN-01, IN-02, IN-03)"
  - id: PRIOR-WR-03
    severity: warning
    disposition: open
    title: "A push-initiated Expert switch clears the user's \"Not now\" deferral"
  - id: PRIOR-WR-04
    severity: warning
    disposition: open
    title: "A wrong password on `delete-request` triggers a token refresh and a second request"
  - id: PRIOR-WR-05
    severity: warning
    disposition: open
    title: "`loadExistingAvatarIfNeeded` can overwrite a photo the user picked while it downloads"
  - id: PRIOR-WR-06
    severity: warning
    disposition: open
    title: "Flipping a notification toggle back during an in-flight save cancels it and skips the resave"
  - id: PRIOR-IN-04
    severity: info
    disposition: open
    title: "`RememberedLoginEmailTests` mutates the real Keychain through the singleton"
open: 11
total: 12
recorded: 2026-11-15T00:00:00Z
---

# Phase 05: Code Review Disposition

`05-REVIEW.md` is now the incremental review of plans 05-21 and 05-22, run against `5cee2da`.
The earlier full-phase review (commit `5cee2da`) had findings in files the incremental review
did not cover. They are kept below with a `PRIOR-` prefix so none drops out of view. Their full
text is at `git show 5cee2da:.planning/phases/05-signup-mode-switch-and-account/05-REVIEW.md`.

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 05-21 (`d13a976`, `3d43983`); confirmed by the incremental review |
| WR-01 | warning | open | incremental review (new) |
| WR-02 | warning | open | incremental review (prior WR-01) |
| WR-03 | warning | open | incremental review (prior WR-02) |
| IN-01 | info | open | incremental review (new) |
| IN-02 | info | open | incremental review (new) |
| IN-03 | info | open | incremental review (prior IN-01..IN-03) |
| PRIOR-WR-03 | warning | open | review `5cee2da` |
| PRIOR-WR-04 | warning | open | review `5cee2da` |
| PRIOR-WR-05 | warning | open | review `5cee2da` |
| PRIOR-WR-06 | warning | open | review `5cee2da` |
| PRIOR-IN-04 | info | open | review `5cee2da` |
