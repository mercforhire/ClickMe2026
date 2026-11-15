---
phase: 05-signup-mode-switch-and-account
plan: 21
subsystem: expert-settings
tags: [swiftui, expert-profile, meeting-link, patch-expert-profile, swift-testing, back-04, cr-01]

requires:
  - phase: 01-backend
    provides: BACK-04 (backend df7fb18) accepts "" or null for professional_details.meeting_url and stores NULL
provides:
  - "Clearing a set expert meeting link sends meeting_url \"\" (CR-01), via the static meetingLinkBody(current:baseline:)"
  - "After a load or pull to refresh the link field and its baseline are the server's link, nil read as \"\" (CR-01 reload half), via the static loadedMeetingLink(from:current:)"
  - "CR-01 device re-test section after item 47, Android parity todo, before-release BACK-04 re-check in STATE.md"
affects: [05-22, verify-work-05, android-parity]

plan_head_before: c19913dd0b82d9365a852463634039fe07ccdb53
plan_head_after: 95337e8ea9e38c3ac702cac58d1bebb888681467

actuals:
  tokens: 6300
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Rules with a view-model dependency on UserManager.shared are extracted to statics with explicit inputs so tests use literals"

key-files:
  created:
    - ClickMe2026Tests/Settings/ExpertMeetingLinkBodyTests.swift
    - ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift
    - .planning/todos/pending/2026-11-15-android-expert-settings-clear-meeting-link.md
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift
    - ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift
    - .planning/phases/05-signup-mode-switch-and-account/05-DEVICE-UAT-CHECKLIST.md
    - .planning/STATE.md

key-decisions:
  - "An expert whose server link is empty never sends the key; a set link that is cleared sends meeting_url \"\" (BACK-04)"
  - "A held expert profile is the server's word on reload: a nil link becomes an empty field and baseline; only with no profile held does the field keep its text"
  - "init and performAutoSave() left byte-identical to HEAD (verified by md5 of their awk-extracted text across c19913d..HEAD)"

patterns-established:
  - "Tracer and pure rows call static rules with literal baselines, so no row depends on the shared manager's held profile in the test host"

requirements-completed: [SET-01]

coverage:
  - id: D1
    description: "Clearing a meeting link the server holds sends PATCH /expert/profile with exactly {\"professional_details\":{\"meeting_url\":\"\"}}; an expert with no link sends nothing; no body is an empty professional_details"
    requirement: SET-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift#CR-01: clearing a set meeting link sends an empty meeting_url"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ExpertMeetingLinkBodyTests.swift (8 rows)"
        status: pass
    human_judgment: false
  - id: D2
    description: "After a load or pull to refresh the meeting-link field equals the server's link (nil as empty) and its baseline matches, so no save is queued"
    requirement: SET-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift (5 rows)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Device behavior: clear a link and reopen, type it back, no-link City edit, pull to refresh after a clear on a second device"
    requirement: SET-01
    verification: []
    human_judgment: true
    rationale: "Real PATCH against production and a second-device refresh cannot be asserted by unit tests; the CR-01 checklist section is the backstop"

duration: 13min
completed: 2026-11-15
status: complete
---

# Phase 5 Plan 21: CR-01 Meeting-Link Clear and Reload Summary

**Clearing the Skype / Zoom link on Expert Settings now sends `meeting_url: ""` (BACK-04) instead of an empty `professional_details`, and a reload takes the server's link with nil read as "", each rule a static with literal-input tests.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-11-15T06:14:29Z
- **Completed:** 2026-11-15T06:28Z
- **Tasks:** 3
- **Files modified:** 7 (4 modified, 3 created)

## Accomplishments
- `ExpertProfileSettingsViewModel.meetingLinkBody(current:baseline:)` returns nil when the trimmed link equals the baseline, otherwise a body carrying the trimmed link ("" for a cleared link). `makeExpertProfileUpdateBody()` delegates to it. The stale comment claiming the server rejects an empty link is gone; the doc cites BACK-04, `expertProfile.schema.js` and `expert.controller.js`.
- `ExpertProfileSettingsViewModel.loadedMeetingLink(from:current:)` makes `forceLoad()` show the server's link after a load or pull to refresh (nil becomes ""), with `baselineMeetingUrl = trimmedMeetingUrl` on the very next line so no save is queued. With no profile held the field keeps its text.
- One tracer row sends the clear body through `api.updateExpertProfile` and checks the wire bytes; two pure suites (8 body rows, 5 reload rows) use literal inputs and never build the view model or touch `UserManager.shared`.
- Production check (read-only): `GET /health` returned `28da165` at 2026-11-15T06:14:31Z and again at 06:27:49Z; `git merge-base --is-ancestor df7fb18 28da165` exits 0, so BACK-04 is live.
- CR-01 device re-test section after item 47 (item 22 and the 47 numbered items untouched), an Android parity todo, and STATE.md link plus before-release BACK-04 re-check.

## Task Commits

1. **Task 1: Tracer, clearing a set meeting link sends meeting_url ""**
   - `59b10b8` refactor: extract `meetingLinkBody(current:baseline:)`, no behavior change (26 tests in 2 suites passed)
   - `697e58c` test: RED tracer row plus the `/expert/profile` branch in `makeAPI`
   - `d13a976` fix: send the trimmed link, "" when cleared; delete the stale comment; cite BACK-04
2. **Task 2: Reload takes the server's link, pure rows**
   - `9ce9273` test: extract `loadedMeetingLink(from:current:)` with today's rule, plus the RED reload suite
   - `3d43983` fix: nil link reads as "", no held profile keeps the field
   - `baad5a0` test: `ExpertMeetingLinkBodyTests`
3. **Task 3: BACK-04 check, checklist section, Android todo, STATE.md** - `95337e8` (docs)

**Plan metadata:** the final docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified
- `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift` - the two static rules, the one-line delegation and the `forceLoad()` change
- `ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift` - tracer row and the `PATCH /expert/profile` mock answer
- `ClickMe2026Tests/Settings/ExpertMeetingLinkBodyTests.swift` - 8 pure body rows (new)
- `ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift` - 5 pure reload rows (new)
- `.planning/phases/05-signup-mode-switch-and-account/05-DEVICE-UAT-CHECKLIST.md` - `## Re-test for CR-01 (plan 05-21)` after item 47
- `.planning/todos/pending/2026-11-15-android-expert-settings-clear-meeting-link.md` - Android follow-up (new)
- `.planning/STATE.md` - todo link and before-release BACK-04 re-check

## TDD Evidence
- **RED, Task 1** (`/tmp/05-21-t1-red.log`): `✘ Test "CR-01: clearing a set meeting link sends an empty meeting_url"` failed on its three `meeting_url` expectations (`meetingUrl → nil`, `details.keys → []`, `meeting_url → nil`); every other row passed (27 tests, 3 issues). Semantic assessment: the target executed and failed on the planned assertion for the planned reason (nil key, empty object), not on compilation. The `check tdd-red-evidence` classifier was not run: this plan is `type: execute`, not `type: tdd`.
- **RED, Task 2** (`/tmp/05-21-t2-red.log`): exactly the two rows that read a server nil failed ("a reload where the server holds no link empties the field" and "after a reload the baseline is the server link and no save is queued"); the other three passed. Run failed on behavior.
- **GREEN:** tracer in `/tmp/05-21-t1.log` (27 tests, 2 suites passed); reload suite in `/tmp/05-21-t2-green.log` (5 tests passed).
- The body suite has no RED run of its own, as planned; Task 1's RED is its evidence.

## Verification Results
- Four-suite run (`ExpertMeetingLinkReloadTests`, `ExpertMeetingLinkBodyTests`, `ProfileSettingsSaveTests`, `ProfileLanguagesSaveTests`): 40 tests in 4 suites passed (`/tmp/05-21-t2.log`).
- Source gates (`/tmp/05-21-t1-gate.sh`, `/tmp/05-21-t2-gate.sh`, `/tmp/05-21-t3-gate.sh`): all pass.
- Build gate: `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` after touching the view model: BUILD SUCCEEDED, zero warnings naming `ExpertProfileSettingsViewModel.swift` (baseline also zero).
- Full unit suite (`-only-testing:ClickMe2026Tests`, smoke suites excluded): 866 tests in 87 suites passed on the first run, so the flaky-row rerun did not trigger (`/tmp/05-21-full.log`).
- `performAutoSave()` and `init` identical between `c19913d` and `HEAD` (md5 of the awk-extracted text matches for both).
- No file in `../ClickMe2026 Backend` or `../ClickMe_Android` was written by this plan; their pre-existing working-tree changes are not mine.

## Decisions Made
- A clear sends `""` rather than `null`: both pass the BACK-04 refine and the controller stores `meeting_url || null`; `""` matches the existing `String?` model and the tracer's literal wire body.
- Task 2's extraction and RED suite share one commit (`9ce9273`) because the plan allows separate commits but the extraction is a no-op that the RED suite compiles against.

## Deviations from Plan

None - plan executed exactly as written. (The pre-execution `STATE.md` diff, which the orchestrator wrote, rode into the Task 3 commit because STATE.md is one of that task's files.)

## Issues Encountered
- The shell refused the first long compound command (bash 3.2); the checks were split into simple commands and saved scripts under `/tmp`, as the plan allows.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The change adds no new endpoint or trust boundary; T-05-38, T-05-39, T-05-40 and T-05-42 are mitigated as planned (wire-bytes tracer row, BACK-04 check with before-release re-check, GET-only probe, reload rule with rows and re-test step 4).

## Next Phase Readiness
- CR-01 is closed in code. SET-01 stays reopened until the device re-test (this plan's checklist section and item 22) passes.
- Plan 05-22 may follow; it waits on this plan because both edit the device checklist (its guard looks for the literal `Re-test for CR-01 (plan 05-21)`).
- Before the release build: re-check read-only that production `/health` still reports a commit containing `df7fb18`.

## Self-Check: PASSED

All created files exist; commits `59b10b8`, `697e58c`, `d13a976`, `9ce9273`, `3d43983`, `baad5a0`, `95337e8` are ancestors of HEAD.

---
*Phase: 05-signup-mode-switch-and-account*
*Completed: 2026-11-15*
