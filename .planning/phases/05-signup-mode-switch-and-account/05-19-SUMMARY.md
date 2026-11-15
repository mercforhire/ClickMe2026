---
phase: 05-signup-mode-switch-and-account
plan: 19
subsystem: settings
tags: [swiftui, profile-settings, patch-user-profile, swift-testing, gap-closure, G-05-6]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: "05-09 language saves (A9 guard, D-07 province rule) on both settings view models"
provides:
  - "ProfileSettingsSnapshot: trimmed form snapshot with patch(from:), merging(_:) and the required-name errors, shared by both settings view models"
  - "Client and expert Profile Settings saves that send only changed groups and never an empty first or last name"
  - "Expert PATCH /expert/profile sent only when the trimmed meeting link changed"
  - "firstNameError / lastNameError on both view models (shown under the field by plan 05-20)"
affects: [05-20, SET-01 re-test (checklist item 22)]

actuals:
  tokens: 13570
  tasks: 2
  commits: 4

plan_head_before: a5a0cfb09afbc166848b2f70d31fe0830e85de3a
plan_head_after: 047347753d398786d3e234bcb9d94a604f46e14b

tech-stack:
  added: []
  patterns:
    - "Baseline snapshot + patch(from:) + merging(_:): a save sends the diff against what the server holds, and the baseline takes only the keys that were sent"
    - "Lock-guarded PATCH body recorder in a MockURLProtocol handler that mimics a backend validation rule"

key-files:
  created:
    - ClickMe2026/Utils/ProfileSettingsSnapshot.swift
    - ClickMe2026Tests/Utils/ProfileSettingsSnapshotTests.swift
    - ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift
  modified:
    - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift
    - ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift

key-decisions:
  - "An empty name is never sent, on both screens; a set name the user clears is held (server keeps it) and flagged via firstNameError / lastNameError. iOS goes one step beyond Android's buildProfilePatch, which still sends an empty last_name inside a changed basic group"
  - "A country key the body cannot carry (empty or unknown) never counts as a change, so it cannot trigger a save by itself"
  - "Expert screen keeps one baselineMeetingUrl apart from the snapshot, so a link-only edit sends only PATCH /expert/profile and a profile-only edit sends only PATCH /user/profile"
  - "TDD split follows the dispatch (separate RED commit before each GREEN commit) rather than the plan's one-commit-per-task wording"

patterns-established:
  - "Settings auto-save: build the optional body first, return when nil (no request, no checkmark), merge the sent body into the baseline on success"

requirements-completed: [SET-01]

coverage:
  - id: D1
    description: "On an empty-name client profile a State/Province edit sends one PATCH carrying only the location group and saves with no alert, against a mock of the backend's min(1) name 422"
    requirement: SET-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift#G-05-6: on an empty-name profile, a province edit saves"
        status: pass
    human_judgment: false
  - id: D2
    description: "Empty names are never sent; only changed groups go out; a cleared set name is held and flagged; the baseline takes exactly the sent keys; A9 and D-07 unchanged"
    requirement: SET-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ProfileSettingsSnapshotTests.swift (25 rows)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift (all existing rows)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Expert screen sends PATCH /user/profile only when a group changed and PATCH /expert/profile only when the trimmed link changed; refreshExpertProfile() still runs after a successful save"
    requirement: SET-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift (expert rows: body builders and api.updateUserProfile)"
        status: pass
    human_judgment: true
    rationale: "The private expert performAutoSave and its refreshExpertProfile() call cannot be driven in a unit test (they reach UserManager.shared's real API); the sequencing is covered by a source grep gate and needs the device re-test in checklist item 22"
  - id: D4
    description: "SET-01 counts as closed again only after plan 05-20 and the G-05-6 device re-test in checklist item 22"
    requirement: SET-01
    verification: []
    human_judgment: true
    rationale: "Device behavior on a real empty-name account; 05-20 adds the visible error"

duration: 10min
completed: 2026-11-14
status: complete
---

# Phase 5 Plan 19: Profile Settings Changed-Group Saves Summary

**Both Profile Settings screens now send only the groups that changed and never an empty first or last name, via a shared ProfileSettingsSnapshot (patch/merge), so a State/Province edit on an empty-name profile saves instead of hitting the backend's min(1) 422 (G-05-6).**

## Performance

- **Duration:** 10 min
- **Started:** 2026-11-14T23:49:00-05:00 (approx.)
- **Completed:** 2026-11-14T23:59:00-05:00
- **Tasks:** 2 (tracer + auto, both TDD)
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `ProfileSettingsSnapshot` (`patch(from:)`, `merging(_:)`, `firstNameError(from:)` / `lastNameError(from:)`) with 25 pure rows covering group selection, name handling, country normalization, languages (A9), province (D-07), merge idempotency.
- Client view model moved onto the snapshot: optional `makeProfileUpdateBody()`, no request or checkmark when nothing can be sent, baseline merge on success.
- Expert view model moved onto the same rules, plus `makeExpertProfileUpdateBody()` gated on a meeting-link baseline; `refreshExpertProfile()` still runs after any successful save.
- Save-path tests against a mock that returns the production 422 body whenever a name key is the empty string, so a regression fails the way it fails on a device.

## Task Commits

1. **Task 1: Tracer, province edit on an empty-name client profile saves**
   - RED `e6c6e3d` (test) - snapshot rows and client save rows; target files did not compile (missing `ProfileSettingsSnapshot`, `firstNameError`, `lastNameError`)
   - GREEN `c2b9e77` (fix) - snapshot type and client view model
2. **Task 2: Expert settings saves the same way, link only when changed**
   - RED `be83875` (test) - expert rows; did not compile (missing `makeExpertProfileUpdateBody`, `firstNameError`, `lastNameError`)
   - GREEN `0473477` (fix) - expert view model and the `ProfileLanguagesSaveTests` call-site adaptation

**Plan metadata:** the docs commit that carries this file.

## TDD Gate Compliance

RED before GREEN for both tasks (`test(05-19)` precedes the matching `fix(05-19)`). RED evidence is a compile failure on the missing symbols, which the plan accepts as RED ("A compile failure on the missing type counts as RED"). It was not run through `check tdd-red-evidence`, which classifies a build failure as INVALID_RED; this plan is `type: execute`, not `type: tdd`, and `tdd_mode` gating does not apply. Semantic assessment: the named target tests could not run because the types they exercise did not exist; after GREEN all 50 tests in the 3 suites ran and passed. GREEN commits use `fix(...)` as the plan specifies, so a `feat(05-19)` grep finds none. No REFACTOR commit.

## Files Created/Modified

- `ClickMe2026/Utils/ProfileSettingsSnapshot.swift` - trimmed snapshot, changed-groups patch, merge, required-name copy
- `ClickMe2026Tests/Utils/ProfileSettingsSnapshotTests.swift` - pure rules (25 rows)
- `ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift` - client and expert save rows against the min(1)/422 mock with a lock-guarded body recorder
- `ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift` - baseline snapshot, optional body, merge on success, name errors
- `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift` - same, plus the gated meeting-link body
- `ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift` - expert call sites adapted to the optional body (`try #require(...)` / `?.languages`); no assertion removed

## Verification

- 3 suites, 50 tests pass in one run (`ProfileSettingsSnapshotTests`, `ProfileSettingsSaveTests`, `ProfileLanguagesSaveTests`); logs `/tmp/05-19-t1.log`, `/tmp/05-19-t2.log`, RED logs `/tmp/05-19-t1-red.log`, `/tmp/05-19-t2-red.log`.
- Build: `BUILD SUCCEEDED`. Warning baseline for `ClientProfileSettingsViewModel.swift`, `ExpertProfileSettingsViewModel.swift` and `ProfileSettingsSnapshot.swift` was empty before and after (`comm -13` empty).
- Grep gates for both tasks pass (no whole-form basic group from the raw first name; `patch(from: baseline)`, `baseline.merging(`, gated link body, name-error properties, A9 copy all present).
- iOS repo got four task commits (RED and GREEN per task) plus this SUMMARY. No backend or Android change; no unrelated working-tree file staged.

## Decisions Made

See `key-decisions` above. The held-name behavior is deliberate: the user's cleared first or last name is never sent as `""`, other groups still save, and the name error stays until a value is typed.

## Deviations from Plan

### Process deviation (dispatch instruction over plan wording)

**1. [Dispatch override] Separate RED commit per task**
- **Found during:** Task 1 and Task 2 commits
- **Issue:** The plan lists one commit per task containing tests and implementation, and acceptance criteria say each task commit lists exactly the task's files. The dispatch required a separate failing-test commit before implementation.
- **Fix:** Four commits instead of two. Task 1 RED lists the 2 test files, GREEN lists the 2 production files (4 files across the pair). Task 2 RED lists `ProfileSettingsSaveTests.swift`, GREEN lists the expert view model and `ProfileLanguagesSaveTests.swift` (3 files across the pair). `git diff` of `ProfileLanguagesSaveTests.swift` changes call syntax only.
- **Committed in:** `e6c6e3d`, `c2b9e77`, `be83875`, `0473477`

No Rule 1-4 auto-fixes were needed.

**Total deviations:** 1 process deviation, 0 auto-fixed. **Impact on plan:** none on behavior or file set; the history is finer-grained than planned.

## Issues Encountered

- The first Task 1 test run reported exit 1 only because a trailing diagnostic `grep` for errors matched nothing; the xcodebuild run itself was `TEST SUCCEEDED`. No code issue.
- Clearing the expert meeting link (trimmed link becomes empty against a non-empty baseline) still sends `PATCH /expert/profile` with `professional_details` and no `meeting_url` key, a server-side no-op that matches the old empty-link-to-omitted-key behavior. The server cannot clear a link through this path; unchanged from before.

## Known Stubs

None.

## Threat Flags

None. No new endpoints or trust boundaries; T-05-34 and T-05-35 mitigated as planned (changed groups go out whole, baseline takes only sent keys, A9 languages rule moved into `patch(from:)` unchanged, every `ProfileLanguagesSaveTests` row passes).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05-20 can read `firstNameError` / `lastNameError` on both view models and change the catch block to name the 422 fields.
- SET-01 stays reopened until 05-20 and the G-05-6 device re-test (checklist item 22) pass; the reopen note is already in ROADMAP.md.

## Self-Check: PASSED

- All 6 files found on disk.
- Commits `e6c6e3d`, `c2b9e77`, `be83875`, `0473477` are ancestors of HEAD.
- `git rev-list --count a5a0cfb..HEAD` was 4 at write time.

---
*Phase: 05-signup-mode-switch-and-account*
*Completed: 2026-11-14*
