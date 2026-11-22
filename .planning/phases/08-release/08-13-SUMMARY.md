---
phase: 08-release
plan: "13"
subsystem: account-deletion-copy
tags: [ios, swiftui, copy, privacy, account-deletion]
status: complete

requires:
  - phase: 08
    provides: "08-10 US$ money plan (wave 4 dependency)"
provides:
  - "AccountDeletionCopy.savedCardsNote shown on the Delete Account confirmation step only"
  - "Android todo carries the final saved-cards line word for word for plan 08-17"
  - "D-23 todo closed with the user's answer recorded"
affects: [ios-release, android-port-08-17]

actuals:
  tokens: 4000
  tasks: 3
  commits: 2

plan_head_before: d5331b9dbb1613b17c52f285d8c630578e56ba01
plan_head_after: ae00a43efd73366cef48e934e89eda76aa32bbcd
commits: 2

tech-stack:
  added: []
  patterns:
    - "Deletion copy stays a nonisolated enum of static strings; every string is pinned by an exact-string test and scanned by noFalseClaims"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/AccountDeletionCopy.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountWarningHeader.swift
    - ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift
    - .planning/todos/pending/2026-11-13-android-delete-account-copy-and-blockers.md
    - .planning/todos/completed/2026-11-13-decide-saved-cards-on-account-deletion.md

key-decisions:
  - "D-23: disclose, do not detach. Final wording (user chose option-a): \"Cards you added to pay for sessions are not deleted with your account.\""
  - "No noFalseClaims exemption: the approved line contains none of removed, saved card or payment details, so the test is unchanged"

patterns-established: []

requirements-completed: []

coverage:
  - id: D1
    description: "The Delete Account confirmation step renders savedCardsNote after the three groups; the feedback step does not"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift"
        status: pass
    human_judgment: false
  - id: D2
    description: "savedCardsNote equals the Android todo string byte for byte"
    requirement: REL-02
    verification:
      - kind: other
        ref: "shell comparison of the Swift literal and the todo row, MATCH"
        status: pass
    human_judgment: false
---

# Phase 08 Plan 13: Saved-cards disclosure on Delete Account Summary

The Delete Account confirmation step now tells users that cards they added to pay for sessions are not deleted with their account, using the wording the user approved at the Task 2 checkpoint.

## Checkpoint decision (D-23)

- **Question:** final text of the saved-cards line.
- **User answer, verbatim:** "option-a" (2026-11-22).
- **Final wording (kept as implemented in Task 1):** "Cards you added to pay for sessions are not deleted with your account."
- It contains none of `removed`, `saved card` or `payment details`, so `AccountDeletionCopyTests.noFalseClaims` passes unchanged and no exemption was added. No backend or payment change was made.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: confirmation step shows the saved-cards line, pinned by test | e18f70f | AccountDeletionCopy.swift, DeleteAccountWarningHeader.swift, AccountDeletionCopyTests.swift |
| 2 | Approve the wording (checkpoint:decision) | no commit | resolved by the user: option-a |
| 3 | Apply approved wording, hand to Android, close the D-23 todo | ae00a43 | the two todo files |

Task 3 needed no Swift change, since option-a was already the implemented text. The work was the Android handoff row ("Saved-cards line (confirmation step only)"), replacing the "No saved-card claim either way" sentence with the D-23 decision and test rule, and moving the D-23 todo to `completed/` with a `## Resolution` section.

## Verification

- Full iOS unit run (`-only-testing:ClickMe2026Tests`, three smoke/login files excluded as in the plan): `Test run with 1272 tests in 118 suites passed`, `** TEST SUCCEEDED **`. No flake rerun was needed.
- Debug build: `** BUILD SUCCEEDED **`; the only warning is the existing AppIntents metadata notice, none from changed code.
- Free disk before the run: 9 GB (precondition of at least 6 GB met).
- The Swift literal and the Android todo row are identical (shell comparison: MATCH).

## Deviations from Plan

None. The plan executed as written, with the checkpoint resolved to option-a.

## Handoff

- Plan 08-17 ports the line to Android from the todo row. The Android repo was not touched here.
- REL-02 is deliberately not marked complete here; plan 08-24 ticks it.

## Known Stubs

None.

## Threat Flags

None. T-08-27 is mitigated: every false-removal phrase stays forbidden in all strings, and no exemption exists.

## Self-Check: PASSED

- e18f70f and ae00a43 are ancestors of HEAD.
- `.planning/todos/completed/2026-11-13-decide-saved-cards-on-account-deletion.md` exists; `.planning/todos/pending/` no longer holds it.
- The Android todo contains the "Saved-cards line" row.
