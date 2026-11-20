---
phase: 08-release
plan: "01"
subsystem: build-release
tags: [xcodebuild, release-build, previews, secrets, warnings-gate, swift6]

requires:
  - phase: 07
    provides: shipped build 6 baseline commit a48c664 and the Phase 7 code the candidate carries
provides:
  - A tracked, token-free ClickMe2026/Debug/PreviewSecrets.swift, so a clean checkout compiles in Release
  - scripts/release-build-check.sh, the reproducible clean-checkout Release build plus normalized warnings diff against a48c664
  - The Favorites withAnimation warning fixed, so the candidate has no warning that build 6 lacks
  - Project guidance (CLAUDE.md and its codebase sources) describing the tracked-file rule
affects: [08-04, 08-20, 08-24, release-candidate-build, ci-build-workflow]

actuals:
  tokens: 3900
  tasks: 3
  commits: 3

plan_head_before: e19f80213029b3628b00f9c96e3490908c4a647d
plan_head_after: c968c7b7a7c96db8870dbcc09ae60d6c3dcee0cf
commits: 3

tech-stack:
  added: []
  patterns:
    - "Tracked, token-free preview secrets: DEBUG reads env vars then a gitignored repo-root JSON; Release compiles no read and returns nil"
    - "Warnings gate: git-archive both refs, identical Release command, normalize, comm -13"

key-files:
  created:
    - scripts/release-build-check.sh
    - ClickMe2026/Debug/PreviewSecrets.swift (now tracked; it existed only as an ignored local file before)
  modified:
    - .gitignore
    - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift
    - .claude/CLAUDE.md
    - .planning/codebase/CONVENTIONS.md
    - .planning/codebase/ARCHITECTURE.md
    - .planning/codebase/STACK.md

key-decisions:
  - "PreviewSecrets.local.json lives at the repo root, outside the synchronized ClickMe2026/ group, so it is never bundled in the IPA (mode 600, gitignored, never committed)"
  - "release-build-check.sh copies the candidate's committed PreviewSecrets.swift into the a48c664 tree, because build 6 predates the tracked file and could not compile on a clean checkout"

patterns-established:
  - "Never write a token into a tracked file; JWT-shaped git grep and git log -G scans must stay empty before any push"
  - "Run one xcodebuild at a time (disk is tight: about 5 GB per Release build, about 7 GB free)"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "A clean checkout (git archive HEAD, no untracked files) builds the ClickMe2026 scheme in Release for generic/platform=iOS with CODE_SIGNING_ALLOWED=NO"
    requirement: REL-02
    verification:
      - kind: other
        ref: "Task 1 second automated check: git archive HEAD, xcodebuild Release generic/platform=iOS; BUILD SUCCEEDED, 0 'cannot find PreviewSecrets' errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "PreviewSecrets.swift is tracked, token-free, with env-var then local-JSON lookup in DEBUG and nil in Release; no JWT-shaped string in tracked ClickMe2026/ files or in origin/main..HEAD history"
    requirement: REL-02
    verification:
      - kind: other
        ref: "Task 1 first automated check (git ls-files, check-ignore, git grep, git log -G): STATIC_GATES_PASS"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release build has no new warnings compared with shipped build 6 (a48c664), and scripts/release-build-check.sh reproduces the measurement"
    requirement: REL-02
    verification:
      - kind: other
        ref: "bash scripts/release-build-check.sh: BASELINE 4, CANDIDATE 4, NEW 0, RELEASE CHECK PASSED"
        status: pass
    human_judgment: false
  - id: D4
    description: "CLAUDE.md and the codebase docs it is generated from say PreviewSecrets.swift is tracked and token-free, with tokens in the gitignored PreviewSecrets.local.json or environment variables"
    requirement: REL-02
    verification:
      - kind: other
        ref: "Task 3 automated grep check: DOCS_CHECK_PASS"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-11-19
status: complete
---

# Phase 08 Plan 01: Release build path Summary

**A clean checkout now compiles in Release because PreviewSecrets.swift is tracked and token-free (tokens moved to a gitignored local JSON), the one new Favorites warning is fixed, and `scripts/release-build-check.sh` proves "no new warnings vs build 6" in one command (4 / 4 / 0).**

## Performance

- **Duration:** 12 min (three Release builds dominate)
- **Started:** 2026-11-20T03:53:00Z (approximate; taken from the plan ledger timestamp)
- **Completed:** 2026-11-20T04:07:00Z
- **Tasks:** 3
- **Files modified:** 8 (one of them, PreviewSecrets.swift, newly tracked)

## Accomplishments

- A fresh `git archive HEAD` builds the `ClickMe2026` scheme in Release for `generic/platform=iOS` with `CODE_SIGNING_ALLOWED=NO`. Before this plan the same build failed with `cannot find 'PreviewSecrets' in scope` in 37 files.
- The two real preview tokens moved out of the tree into `PreviewSecrets.local.json` (repo root, mode 600, gitignored, untracked) without ever being printed. The tracked Swift file reads `CLICKME_PREVIEW_CLIENT_TOKEN` / `CLICKME_PREVIEW_EXPERT_TOKEN` first, then that file, in DEBUG only; Release returns `nil` and compiles no read.
- The JWT scans are empty: `git grep` for a JWT prefix under `ClickMe2026/` prints nothing, and `git log -G ... origin/main..HEAD` prints nothing, so a later push publishes no token.
- `FavoritesViewModel.removeFavorite` now writes `_ = list.remove(key: expert.pagingKey)`, which removes the only warning the candidate had beyond build 6.
- `scripts/release-build-check.sh` builds the baseline (`a48c664`) and the candidate (default `HEAD`) from git archives with the identical Release command, normalizes the warning lines, and exits 0 only when both build and `comm -13` shows nothing new. Plan 08-20 reruns it on the release candidate.
- CLAUDE.md and its three codebase source docs no longer say the Swift file is ignored; they describe the tracked, token-free file and the local token file.

## Release check output (Task 2 verify)

```
BASELINE WARNINGS: 4
CANDIDATE WARNINGS: 4
NEW WARNINGS: 0
RELEASE CHECK PASSED
```

This matches the research expectation of 4, 4, 0.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer - tracked, token-free PreviewSecrets** - `5583dfa` (chore): `.gitignore`, `ClickMe2026/Debug/PreviewSecrets.swift`
2. **Task 2: Favorites warning fix and release-build-check.sh** - `285ea11` (chore): `FavoritesViewModel.swift`, `scripts/release-build-check.sh`
3. **Task 3: Guidance says PreviewSecrets.swift is tracked and token-free** - `c968c7b` (docs): `.claude/CLAUDE.md`, `CONVENTIONS.md`, `ARCHITECTURE.md`, `STACK.md`

**Plan metadata:** committed separately after this file (docs: complete plan).

The tracer gate ran as the tracer's own automated verify (static gates plus the clean-checkout Release build, both green) before Task 2 and Task 3 started: "Tracer verified end-to-end, expanding".

## Files Created/Modified

- `ClickMe2026/Debug/PreviewSecrets.swift` - tracked, token-free `enum PreviewSecrets` with `clientBearerToken` and `expertBearerToken` (both `String?`); private DEBUG-only helpers `token(env:key:)` and `clean(_:)`
- `.gitignore` - ignores `PreviewSecrets.local.json` instead of the Swift file
- `PreviewSecrets.local.json` (local only, never committed) - the real preview tokens, mode 600
- `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift` - discards the unused `withAnimation` result
- `scripts/release-build-check.sh` - clean-checkout Release build and warnings diff (env vars `CANDIDATE`, `BASELINE`, `PROJECT`, `SCHEME`, `WORK`)
- `.claude/CLAUDE.md`, `.planning/codebase/CONVENTIONS.md`, `ARCHITECTURE.md`, `STACK.md` - tracked-file rule, one line per spot

## Decisions Made

- The repo-root JSON location (not inside `ClickMe2026/`) keeps it out of the file-system-synchronized app group, so it is never bundled.
- The baseline tree gets the candidate's committed PreviewSecrets.swift because build 6 predates it; the file is token-free and Release reads `nil`, so it cannot change the baseline's warning set.

## Deviations from Plan

None - plan executed exactly as written.

Two small implementation choices inside the plan's freedom, not deviations from its contract: the Swift file computes each value in a `static let` closure that calls the private `token(env:key:)` helper (so each is computed once), and `norm` in the script first strips the `$WORK/base|cand/` prefix before the research `sed`, so a warning with no `ClickMe2026` path segment still compares equal across the two trees.

**Total deviations:** 0.

## Issues Encountered

None. The disk precondition held (7 GB free, at least 6 needed) and no Gradle build was running. Scratch DerivedData and `$WORK` were deleted after each run.

## Known Stubs

None.

## User Setup Required

None required. To get live-fetch previews back on this Mac, `PreviewSecrets.local.json` already exists at the repo root with the current tokens. On another machine, set `CLICKME_PREVIEW_CLIENT_TOKEN` and `CLICKME_PREVIEW_EXPERT_TOKEN` or create that file with keys `clientBearerToken` and `expertBearerToken`.

## Next Phase Readiness

- Plan 08-20 can rerun `bash scripts/release-build-check.sh` on the release candidate (set `CANDIDATE` to the ref).
- Remaining Pitfall 1 items belong to other plans: `XCODE_PROJECT` in `build.yml`, `ExportOptions.plist` `teamID`, and the build-number question. Not touched here.
- The D-25 push gates (JWT scans) are clean as of `c968c7b`.

## Self-Check: PASSED

- FOUND: ClickMe2026/Debug/PreviewSecrets.swift (tracked), scripts/release-build-check.sh (mode 755, tracked), PreviewSecrets.local.json (untracked, ignored, mode 600)
- FOUND commits: 5583dfa, 285ea11, c968c7b (all ancestors of HEAD; `git rev-list --count e19f802..HEAD` = 3)
- Task 1 static gates, clean-checkout Release build, Task 2 release check (4 / 4 / 0) and Task 3 docs check all pass

---
*Phase: 08-release*
*Completed: 2026-11-19*
