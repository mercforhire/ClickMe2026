---
phase: 05-signup-mode-switch-and-account
plan: 22
subsystem: account-settings
tags: [swiftui, safe-area-inset, delete-account, dynamic-type, set-06, lt1]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-15 Delete Account confirmation step and plan 05-21 CR-01 checklist section
provides:
  - "Delete Account confirmation step: the pinned Delete Account and Cancel bar is a bottom safe-area inset of the ScrollView, so the last disclosure line scrolls clear of it at any text size (SET-06, UI-SPEC LT1)"
  - "SET-06 legibility device re-test block under checklist item 34"
affects: [verify-work-05]

plan_head_before: 4697ee859d9c7cfa4fb61b868777d8ec2c7b07d6
plan_head_after: 5c9cc95b45175b7a2cb7aed98caa02945454c58f

actuals:
  tokens: 1100
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "A pinned bottom bar over a ScrollView is a safeAreaInset(edge: .bottom, spacing: 0), never an overlay under a fixed spacer"

key-files:
  created: []
  modified:
    - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift
    - .planning/phases/05-signup-mode-switch-and-account/05-DEVICE-UAT-CHECKLIST.md

key-decisions:
  - "UI-SPEC LT1's mechanism changed from the bottom spacer to the bottom safe-area inset; LT1's outcome (last line clear of the buttons) is unchanged and 05-UI-SPEC.md was not edited"
  - "The confirmation content gets .padding(.bottom, 24), the same breathing room feedbackView uses, in place of the 80 pt spacer"

requirements-completed: [SET-06]

coverage:
  - id: D1
    description: "The confirmation step's Delete Account and Cancel bar is a bottom safe-area inset of the ScrollView; the 80 pt spacer and the bottom-aligned ZStack overlay are gone; the call guard, advance action, dismiss action and warning header are unchanged; the feedback step is byte-identical"
    requirement: SET-06
    verification:
      - kind: other
        ref: "bash /tmp/05-22-t1-gate.sh (region source gate: inset 1, spacer 0, overlay ZStack 0, guards 1 each)"
        status: pass
      - kind: other
        ref: "xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug (BUILD SUCCEEDED, zero warnings naming DeleteAccountView.swift, baseline also zero)"
        status: pass
    human_judgment: false
  - id: D2
    description: "On a small iPhone at the default and the largest text size, scrolled to the bottom of the confirmation step, the last line of the Kept group reads in full above the buttons (UI-SPEC LT1, UAT test 2, VERIFICATION truth 12)"
    requirement: SET-06
    verification: []
    human_judgment: true
    rationale: "Scroll geometry at accessibility text sizes on a real iPhone cannot be asserted by a unit test; checklist item 34 block 'Re-test for SET-06 legibility (plan 05-22)' is the backstop"
  - id: D3
    description: "UI-SPEC OV1: when the three groups are taller than the screen the confirmation step scrolls and every group wraps with nothing truncated"
    requirement: SET-06
    verification: []
    human_judgment: true
    rationale: "Same device re-test; layout wrapping is visual"

duration: 4min
completed: 2026-11-15
status: complete
---

# Phase 5 Plan 22: Delete Account Disclosure Clears the Pinned Buttons Summary

**The Delete Account confirmation step's pinned Delete Account and Cancel bar is now a bottom safe-area inset of its ScrollView, so the last "Kept" line scrolls clear of the roughly 163 pt bar instead of hiding behind it under a fixed 80 pt spacer.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-11-15T06:29:28Z
- **Completed:** 2026-11-15T06:33Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- `confirmationView` is a `ScrollView` holding `DeleteAccountWarningHeader()` with `.padding(.bottom, 24)`, and `DeleteAccountBottomButtons` moved unchanged into `.safeAreaInset(edge: .bottom, spacing: 0)`. The fixed `Spacer().frame(height: 80)`, the bottom-aligned `ZStack` and the VStack wrapper are removed.
- The call guard (`CallCenter.shared.attempt("delete your account")`), `viewModel.advanceToFeedback()`, `secondaryAction: { dismiss() }` and the `isDeleting` spinner path are unchanged. `feedbackView` text is identical between the parent and the task commit (md5 of the awk-extracted block matches).
- Checklist item 34 has the "Re-test for SET-06 legibility (plan 05-22)" block (build at or after `01e55f4`, throwaway account, smallest iPhone, default and largest text size). Items 34, 35 and 47 keep their headings, no item 48 exists, and 05-21's CR-01 section is intact.
- LT1 mechanism note: UI-SPEC row LT1 named the bottom spacer as its mechanism; LT1's mechanism is now the bottom safe-area inset instead of the bottom spacer, with the outcome (last line clear of the buttons) unchanged. 05-UI-SPEC.md, 05-VERIFICATION.md and 05-UAT.md were not edited.

## Task Commits

1. **Task 1: Tracer, bottom safe-area inset on the confirmation step** - `01e55f4` (fix)
2. **Task 2: SET-06 legibility device re-test in checklist item 34** - `5c9cc95` (docs)

**Plan metadata:** the final docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift` - `confirmationView` rearranged around the inset (+11 / -12 lines)
- `.planning/phases/05-signup-mode-switch-and-account/05-DEVICE-UAT-CHECKLIST.md` - SET-06 legibility re-test block (+28 lines)

## Verification Results
- Tracer gate: the source gate passed (`/tmp/05-22-t1-gate.sh`); the build gate passed: `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` gave BUILD SUCCEEDED (`/tmp/05-22-build.log`), and `comm -13` of the before and after warning lists for `DeleteAccountView.swift` is empty (both lists have 0 lines).
- Checklist gate (`/tmp/05-22-t2-gate.sh`) passed.
- Related unit tests: `xcodebuild test ... -only-testing:ClickMe2026Tests/DeleteAccountViewModelTests` gave TEST SUCCEEDED, 8 tests in 1 suite passed (`/tmp/05-22-test.log`). No unit test covers the view's layout; the device re-test is the backstop.
- Post-commit deletion check: no deleted files in either commit.
- `git status --short` for 05-UI-SPEC.md prints nothing.

## Decisions Made
- LT1's mechanism changed from the bottom spacer to the bottom safe-area inset (per 05-UI-REVIEW.md Top fix 2); the outcome is unchanged and 05-UI-SPEC.md was not edited, as the plan directs.
- `.padding(.bottom, 24)` replaces the 80 pt spacer, matching `feedbackView`'s spacing.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The tracer's `<human-check>` (LT1 on a real iPhone) is not an executor gate under the default `end-of-phase` mode with an automated `<verify>`; it is carried by the checklist block and `/gsd-verify-work 05`.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. T-05-41 is mitigated as planned: the inset makes the scroll view's bottom inset include the bar's height, the call guard and advance action are unchanged, and checklist item 34 carries the default and largest text size re-test.

## Next Phase Readiness
- This was the last plan in Phase 5. SET-06 legibility (UAT test 2, VERIFICATION truth 12) closes when the device re-test under item 34 passes on a build at or after `01e55f4`.

## Self-Check: PASSED

`DeleteAccountView.swift` and `05-DEVICE-UAT-CHECKLIST.md` exist; commits `01e55f4` and `5c9cc95` are ancestors of HEAD.

---
*Phase: 05-signup-mode-switch-and-account*
*Completed: 2026-11-15*
