---
phase: 05-signup-mode-switch-and-account
plan: 17
subsystem: ui
tags: [swiftui, dead-code, calls, cleanup]

requires:
  - phase: 05
    provides: plan 05-06 kept the D-12 cancellation policy link; this plan is the D-13 half of SET-07
provides:
  - Views/Screens/Call/Ready/ removed (ReadyToStartCallView, its view model and seven subviews, 729 lines)
affects: [phase 05 verification (SET-07 closes with 05-06 and this plan)]

actuals:
  tokens: 6772
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []
  deleted:
    - ClickMe2026/Views/Screens/Call/Ready/ReadyToStartCallView.swift
    - ClickMe2026/Views/Screens/Call/Ready/ReadyToStartCallViewModel.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallBrand.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallHeadline.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallJoinButton.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallLinkCard.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallMessageButton.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallSkypeIcon.swift
    - ClickMe2026/Views/Screens/Call/Ready/Subviews/ReadyToStartCallSupportRow.swift

key-decisions:
  - "Strings used only by the deleted screen stay in Localizable.xcstrings as stale entries; the catalog is not hand-edited (RESEARCH Pitfall 10)"

requirements-completed: [SET-07]

coverage:
  - id: D1
    description: "ReadyToStartCallView, its view model and seven subviews are deleted; no Swift file in the app, unit or UI test targets names a ReadyToStart type"
    requirement: SET-07
    verification:
      - kind: other
        ref: "test ! -d Call/Ready && test -z \"$(grep -rln ReadyToStart ClickMe2026 ClickMe2026Tests ClickMe2026UITests --include=*.swift)\" && test -d Call/Calling"
        status: pass
    human_judgment: false
  - id: D2
    description: "The app still builds with no new warning in the remaining call code (Views/Screens/Call/ and PreviewNavHarness.swift)"
    verification:
      - kind: other
        ref: "xcodebuild build Debug iPhone 17; comm -13 of before/after warning lists is empty (baseline 0 warnings)"
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-11-13
status: complete
plan_head_before: ff4c8f7168c71d29758a9173334090572976d34e
plan_head_after: df9c92a928395d212539ef5f8c41f642adff87e8
commits: 1
---

# Phase 5 Plan 17: Delete the unreachable ReadyToStartCallView Summary

**The dead Skype meeting-link screen (`ReadyToStartCallView`, its view model and seven subviews) is deleted; the app builds with no new warnings and the shared call code is untouched.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-13T18:11Z
- **Completed:** 2026-11-13T18:17Z
- **Tasks:** 1 (tracer)
- **Files:** 9 deleted (729 lines)

## Accomplishments

- Removed `ClickMe2026/Views/Screens/Call/Ready/` (9 files). Calls run through Agora and `CallCenter`; nothing navigated to this screen.
- Before deleting, confirmed that no Swift file outside the folder names a ReadyToStart type, and that every type declared in the folder (including the private `LiveFetchReadyToStartCallBootstrap`) carries the ReadyToStart prefix, so no helper had to move.
- Left `Views/Screens/Call/Calling/` (`SkypeLinkActions`, `ExternalMeetingProvider`), `api.joinCall(id:)` and `PreviewNavHarness` untouched.
- The app target is a file-system synchronized group, so `project.pbxproj` needed no edit.

## Task Commits

1. **Task 1: Tracer, the dead ReadyToStartCallView is gone and the app still builds** - `df9c92a` (chore)

## Verification

- Grep gate (folder gone, no `ReadyToStart` in any Swift file, `Call/Calling` present): PASS.
- Baseline build before the edit (`/tmp/05-17-build-before.log`): BUILD SUCCEEDED, 0 warnings in `Views/Screens/Call/` and `PreviewNavHarness.swift`.
- Build after the deletion (`/tmp/05-17-build.log`): BUILD SUCCEEDED, `comm -13` of before/after warning lists empty: PASS.
- `git show --stat --format= HEAD`: 9 files changed, 729 deletions, all under `Call/Ready/`.
- Tracer gate: `<verify>` passed end to end, so there was no expansion to hold back (single-task plan).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Notes

- `ClickMe2026/Localizable.xcstrings` already carried uncommitted edits before this run and Xcode rewrote it during both builds; it was not staged or committed.
- The commit went to `main`, the branch the earlier phase 05 plans used in sequential mode; the protected-branch query returned `false` for it.
- Nothing in the backend or Android repos changed. The Android port has its own call screens; no matching Android change is implied by deleting an unreachable iOS screen.

## Next Phase Readiness

Ready for the next phase 05 plan.

## Self-Check: PASSED

- `Call/Ready/` is absent and `Call/Calling/` is present.
- Commit `df9c92a` is an ancestor of HEAD and `git rev-list --count ff4c8f7..HEAD` read 1 before this summary commit.
