---
phase: 05-signup-mode-switch-and-account
plan: 15
subsystem: settings
tags: [swiftui, delete-account, copy, swift-testing, privacy]
status: complete

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: "05-08 Delete Account blocker alert and 409 handling in DeleteAccountView"
provides:
  - "AccountDeletionCopy: the final D-08/D-10 strings (copied into the Android todo by 05-13)"
  - "DeleteAccountWarningHeader(showsDetails:) with the three Deleted / Kept without your personal details / Kept groups"
  - "Pause Account card, its callback and its title removed from the Delete Account flow"
affects: [05-13, 05-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 2600
  tasks: 2
  commits: 2

commits: 2
plan_head_before: 3b1884549e39f73a6b66b4608ea286c887d1c40e
plan_head_after: ebcfdc6dce5c390ac8db43683283865a1ea1a453

tech-stack:
  added: []
  patterns:
    - "Copy constants in a nonisolated enum (like SuspensionNotice), guarded by a Swift Testing suite that forbids false claims"

key-files:
  created:
    - ClickMe2026/Utils/AccountDeletionCopy.swift
    - ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift
  modified:
    - ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountWarningHeader.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift
  deleted:
    - ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountPauseCard.swift

key-decisions:
  - "The detail groups show on the confirmation step only; the feedback step keeps the headline and the permanence line (showsDetails: false)"
  - "No saved-card claim in the copy (Open Question 1 default); the cascade does not detach cards"
  - "DeleteAccountBrand.pauseIconBg is now unused but left in place: 05-UI-SPEC forbids editing the per-screen brand enums"

patterns-established:
  - "A privacy disclosure is asserted by tests against the backend behavior it describes, not just snapshot-matched"

requirements-completed: [SET-03, SET-06]

coverage:
  - id: D1
    description: "Delete Account shows one permanence line, the upcoming-sessions line and three groups matching accountCascade.purgeAndLockAccount, with no removal, saved-card or payment-details claim"
    requirement: SET-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift (5 tests: exact strings, forbidden words, visible to the other person, Deleted user, upcoming)"
        status: pass
      - kind: command
        ref: "grep gate: header has no 'All your data', uses AccountDeletionCopy. at least 4 times and showsDetails at least 2 times"
        status: pass
    human_judgment: false
  - id: D2
    description: "The pause card, its callback and its title text are gone from every Swift source; the step order and both CallCenter delete guards are unchanged"
    requirement: SET-03
    verification:
      - kind: command
        ref: "grep gate: no PauseCard|onPauseAccount|Pause Account|Before you go in ClickMe2026; file deleted; showsDetails: false present; attempt(\"delete your account\") count at least 2"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Settings/DeleteAccountViewModelTests.swift (8 tests, regression)"
        status: pass
    human_judgment: false
  - id: D3
    description: "SET-06 device check: the copy reads well at the 16 pt spacing and wraps at the largest Dynamic Type on both steps of a real iPhone, with no Pause card"
    requirement: SET-06
    verification: []
    human_judgment: true
    rationale: "Layout, wrapping and readability need a real device; listed in 05-DEVICE-UAT-CHECKLIST.md (UI-SPEC LT1 and OV1 backstops)"
---

# Phase 5 Plan 15: Delete Account copy and Pause card removal Summary

**Delete Account now says what is deleted, what is kept without personal details and what is kept (checked against `purgeAndLockAccount`), with no saved-card claim, and the Pause Account card that had no backend route is gone.**

## Performance

- **Duration:** about 12 min
- **Completed:** 2026-11-13
- **Tasks:** 2
- **Files:** 5 (2 created, 2 modified, 1 deleted)

## Accomplishments

- `AccountDeletionCopy` holds the eight locked strings (permanence, upcoming-sessions line and the three title/body groups). Its doc comment maps each group to the cascade steps and notes that 05-13 copies the strings word for word into the Android todo.
- `DeleteAccountWarningHeader` replaces the false "All your data ... payment details ... permanently removed" paragraph. It shows the permanence line always, and the upcoming-sessions line plus the three groups when `showsDetails` is true.
- `DeleteAccountView`: the confirmation step shows the header and the spacer only; the feedback step uses `showsDetails: false`, so the long copy is read once, before the user commits. The pause callback, init parameter, assignment, title and card are removed, and `DeleteAccountPauseCard.swift` is deleted.
- `AccountDeletionCopyTests` (5 tests) forbid `removed`, `saved card` and `payment details`, and require `visible to the other person`, `Deleted user` and `upcoming`.

## Task Commits

1. **Task 1: Tracer, accurate Delete Account copy** - `1e35048` (fix)
2. **Task 2: Remove the Pause Account card** - `ebcfdc6` (fix)

## Verification Results

- `AccountDeletionCopyTests`: 5 tests in 1 suite passed (`/tmp/05-15-t1.log`). RED was a compile failure (the type did not exist yet); the plan's single Task 1 commit holds test and implementation together, so no separate RED commit exists.
- `DeleteAccountViewModelTests` (05-08 regression): 8 tests in 1 suite passed (`/tmp/05-15-reg.log`).
- Build: `BUILD SUCCEEDED`; warnings in the three app files: 0 before, 0 after, so none new.
- Grep gates: all pass. The pause-reference count went from 10 matching lines at HEAD to 0, and `attempt("delete your account")` stays at 2.
- Backend re-check (read-only, before locking the copy): `purgeAndLockAccount` still tombstones the profile to "Deleted user" (F1), erases the private booking notes (F3, F4), deletes devices, notifications and preferences (F6 to F8) and reaps avatar files (step I), with no DML on reviews, messages, reports or payment tables. `cancelActiveBookingsForUser` cancels `pending_approval` bookings and voids the authorization. `accountCascade.js` last changed in `44d5b56` (not newer than the plan's reading). No string needed adjusting.

## Deviations from Plan

### Auto-fixed Issues

**1. [UI-SPEC refinement] Header stack spacing 16 instead of 12**
- **Found during:** Task 1
- **Issue:** The plan says only "spaced like the existing header" (12 pt); 05-UI-SPEC, approved after planning, contracts 16 pt (md) for the stack and 4 pt between a group title and its body.
- **Fix:** `VStack(alignment: .leading, spacing: 16)` in the header, groups as `VStack(spacing: 4)`. The UI-SPEC wins per the dispatch notes.
- **Files modified:** `DeleteAccountWarningHeader.swift`
- **Commit:** `1e35048`

**2. [Addition] Two `#Preview` blocks on the header**
- **Found during:** Task 1
- **Issue:** The header had no preview, and UI-SPEC LT1 asks for a held-out preview or device check of the groups at large Dynamic Type.
- **Fix:** Added "Details" and "Short" previews (no new warnings).
- **Files modified:** `DeleteAccountWarningHeader.swift`
- **Commit:** `1e35048`

**Total deviations:** 2 (one UI-SPEC refinement, one small addition). **Impact:** none on scope or behavior.

## Issues Encountered

None.

## Known Stubs

None.

## Notes

- `ClickMe2026/Localizable.xcstrings` carries pre-existing uncommitted edits from before this run. This plan did not stage or commit it.
- `DeleteAccountBrand.pauseIconBg` is now unused. It is left in place because 05-UI-SPEC forbids changing the per-screen brand enums.
- Cross-repo: no backend change was made. The Android `delete_account_body` has the same wrong claim; plan 05-13 owns copying these strings into the Android todo (D-11).

## Next Phase Readiness

Ready for the remaining wave-3 plans. A device pass of Delete Account on both steps (on a throwaway account, never a live one) is listed for `05-DEVICE-UAT-CHECKLIST.md`.

## Self-Check: PASSED

- FOUND: `ClickMe2026/Utils/AccountDeletionCopy.swift`
- FOUND: `ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift`
- MISSING (intended): `DeleteAccountPauseCard.swift` (deleted in `ebcfdc6`)
- FOUND commits: `1e35048`, `ebcfdc6`
