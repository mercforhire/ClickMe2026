---
phase: 08-release
plan: "20"
subsystem: release
tags: [release, version-bump, testflight, ci, d-18, d-19, d-25, d-26, rel-02]
status: complete

requires:
  - phase: 08
    provides: "08-01 scripts/release-build-check.sh; 08-04 release_path: ci; 08-18 backend frozen at 1d18aac; 08-19 zero code findings"
provides:
  - "Release candidate 1.1 (7) at 1fdcc26: tag v1.1 (annotated) and release/1.1 on GitHub, both at 1fdcc26"
  - "The release/1.1 push that starts the Deploy to TestFlight run (build.yml) for build 7"
  - "## Build and ## Warnings of 08-RELEASE-RECORD.md filled"
affects: [08-22, 08-24]

actuals:
  tokens: 7100
  tasks: 3
  commits: 3

plan_head_before: 0bbecb6310d70b9cc5eac3d53e30b750a5e37411
plan_head_after: dc7bf95ecca3a90e7e7b872170290af8d750bbef
commits: 3

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - ".planning/phases/08-release/08-20-SUMMARY.md"
  modified:
    - "ClickMe.xcodeproj/project.pbxproj"
    - "ClickMe2026/Localizable.xcstrings"
    - ".planning/phases/08-release/08-RELEASE-RECORD.md"

key-decisions:
  - "Release candidate 1.1 (7) is 1fdcc26; tag v1.1, release/1.1 and the checked commit are the same SHA (user go 2026-11-23, verbatim: \"go\")"

requirements-completed: []

duration: about 75 min
completed: 2026-11-23
---

# Phase 08 Plan 20: Release candidate 1.1 (7) Summary

1.1 (7) was cut from `1fdcc26`, after the backend freeze. That commit passed the full unit run (1296 tests in 119 suites) and the clean-checkout Release check (NEW WARNINGS: 0). Tag `v1.1` and `release/1.1` point at it on GitHub, and the branch push starts the "Deploy to TestFlight" run for build 7.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: version 1.1 (7) committed and the candidate passes every local release gate | `73b9800` (catalog), `1fdcc26` (version, candidate) | `ClickMe2026/Localizable.xcstrings`, `ClickMe.xcodeproj/project.pbxproj` |
| 2 | Go / no-go (checkpoint:decision) | none | - |
| 3 | Push the candidate (ci path) and record the build | `dc7bf95` | `.planning/phases/08-release/08-RELEASE-RECORD.md` |

`commits: 3` is `git rev-list --count 0bbecb6..dc7bf95`. The SUMMARY and state commit follows.

## Task 1: the candidate

- **String catalog (`73b9800`):** Xcode-extracted keys only. 62 were added, including "Free" and "Session fee" from 03-18 and the 261122-r2o alert strings. 31 were removed because they no longer appear as localizable literals in the source. 0 changed.
  - en is the only language, so no translated string was removed.
  - The one removed entry with an en unit ("Your meeting with %@ on %@, at %@ has been successfully booked.") was Xcode's auto-generated positional form with state "new". It went because 77204c6 moved that sentence from a SwiftUI literal to a plain String.
  - The Debug build did not change the catalog again.
- **Version (`1fdcc26`):** only the four app-target lines changed. The app target resolves to MARKETING_VERSION 1.1 and CURRENT_PROJECT_VERSION 7 in Debug and Release (bundle id `com.uptrendinvestments.clickmeapp`). The test target stays at CURRENT_PROJECT_VERSION 1.2.3.
- **Unit run on `1fdcc26`:** `✔ Test run with 1296 tests in 119 suites passed after 9.337 seconds.` It passed first time, and the known MakeABookingAvailabilityTests flake did not occur.
- **Release check on `1fdcc26`:** BASELINE WARNINGS: 4, CANDIDATE WARNINGS: 4, NEW WARNINGS: 0, RELEASE CHECK PASSED.
- **Environments.plist:** Current is Production. The clean-tree check (with `.DS_Store` excluded) is empty.
- **D-25/D-26 history gate:** I ran it over `origin/main..HEAD` (61 commits) after Task 1, and again immediately before the first push.
  - Neither run found a JWT-shaped string or a secret key.
  - The working-tree `eyJhbGciOi` list outside `.planning` is exactly the two fake-JWT fixtures.
  - No tracked `.planning` file holds a JWT.

## Task 2: go / no-go

The user's answer, relayed by the orchestrator on 2026-11-23, verbatim: **"go"**.

## Task 3: the cut (ci path)

These are in push order. None of the pushes used force.

1. Annotated tag `v1.1` ("ClickMe iOS 1.1 (7)", tag object `e5a92134f134e68799a94a54c3efd52ff1e4d738`) was created at `1fdcc26`.
2. `main` was pushed as a fast-forward, `4bd63e7..1fdcc26`.
3. Tag `v1.1` was pushed.
4. `1fdcc26:refs/heads/release/1.1` was pushed as a new branch, after checking that it did not exist.
5. The release record commit `dc7bf95` was pushed on `main` as a fast-forward, `1fdcc26..dc7bf95`.

`git ls-remote origin` after the cut:

```
dc7bf95ecca3a90e7e7b872170290af8d750bbef	refs/heads/main
1fdcc26edd754d5f156bb8369c41fb2e5f0281f5	refs/heads/release/1.1
e5a92134f134e68799a94a54c3efd52ff1e4d738	refs/tags/v1.1
1fdcc26edd754d5f156bb8369c41fb2e5f0281f5	refs/tags/v1.1^{}
```

The candidate, the `v1.1` tag and the `release/1.1` tip are the same SHA, `1fdcc26`. The Task 3 automated verify passed.

**CI run:** the `release/1.1` push triggers the "Deploy to TestFlight" workflow (`.github/workflows/build.yml`, `push: branches 'release/**'`). This machine could not read the run's ID or status: `gh` is not installed, and the repo is private, so the public Actions API returns 404. Watch it at https://github.com/mercforhire/ClickMe2026/actions/workflows/build.yml?query=branch%3Arelease%2F1.1 . **08-22 starts after TestFlight shows 1.1 (7).**

## Deviations from Plan

- **Logs:** they went to the session scratchpad instead of `/tmp/08-20-*`, with the same checks. The first verify block runs from a script because this machine's bash 3.2 refused the one-line form.
- **CI run ID:** not recorded. `gh` is missing and the API is private (see above). The record holds the workflow filter URL instead.

## Next

- Watch the "Deploy to TestFlight" run. When TestFlight shows 1.1 (7), start 08-22 (the regression run, R1 to R11).
- REL-01 and REL-02 stay open. Only 08-24 marks them complete.

## Self-Check: PASSED

- FOUND: `ClickMe.xcodeproj/project.pbxproj` (MARKETING_VERSION = 1.1;), `.planning/phases/08-release/08-RELEASE-RECORD.md` (contains `1fdcc26`)
- FOUND commits: `73b9800`, `1fdcc26`, `dc7bf95` (ancestors of HEAD)
- FOUND on GitHub: `refs/tags/v1.1^{}` = `refs/heads/release/1.1` = `1fdcc26`
