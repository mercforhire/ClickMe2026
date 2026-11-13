---
phase: 05-signup-mode-switch-and-account
plan: 08
subsystem: ui
tags: [swiftui, delete-account, error-code, alert, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-01 DeleteAccountViewModel userManager init and success tail
provides:
  - ErrorCode.clientHasUpcomingBookings (CLIENT_HAS_UPCOMING_BOOKINGS)
  - AccountDeletionBlocker (expertUpcoming, clientUpcoming, sessionInProgress; init?(code:), title, bookingsActionLabel, offersBookingsAction(in:), message(in:))
  - DeleteAccountViewModel.blocker with 409 handling on delete-request and DELETE
  - Blocker alert on DeleteAccountView with the View My Bookings action
  - AccountDeletionBlockerTests (14 tests) and DeleteAccountViewModelTests (8 tests)
affects: [05-13 Android todo (copy table), 05-14 expert shell showMyBookings, 05-15 Delete Account copy and pause card removal]

actuals:
  tokens: 5600
  tasks: 2
  commits: 2
plan_head_before: c97e9f9935e974e169152f941b9457a26cb0ed06
plan_head_after: 9ab79d28039c3fa129c5fe1d91ae89f604c5db06

tech-stack:
  added: []
  patterns:
    - "Pure mapper enum (AccountDeletionBlocker) from ErrorCode to iOS-owned copy and an action rule keyed on the active AppMode; the view model only maps, the view only renders"
    - "409 branches on ErrorCode via BookingErrorMapper.code(for:), with the server message as the fallback only for an unknown code"

key-files:
  created:
    - ClickMe2026/Utils/AccountDeletionBlocker.swift
    - ClickMe2026Tests/Utils/AccountDeletionBlockerTests.swift
    - ClickMe2026Tests/Settings/DeleteAccountViewModelTests.swift
  modified:
    - ClickMe2026/Model/Enums/ErrorCode.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift

key-decisions:
  - "The bookings button label is Title Case, View My Bookings (UI-SPEC CP1/A7 supersedes the plan's sentence case); it is the single constant AccountDeletionBlocker.bookingsActionLabel"
  - "A 409 with a known blocker code sets blocker and leaves deletionError nil; an unknown or missing code leaves blocker nil and shows the server message (or the handler's fallback) in the existing Couldn't delete account alert"
  - "The 409 never changes step, so the user stays on the feedback step and the next confirmDeletion() resets blocker and POSTs delete-request again for a fresh token (T-05-18 unchanged)"
  - "The blocker alert reads UserManager.shared.currentMode at render time, so the mode rule follows the active mode (Open Question 2 default)"

requirements-completed: [SET-06]

coverage:
  - id: D1
    description: "The three self-delete 409 codes map to the iOS-owned blocker, branched on ErrorCode, with the mode rule for the bookings action and the mode-switch copy"
    requirement: "SET-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AccountDeletionBlockerTests.swift (14 tests: code mapping, offersBookingsAction per mode, copy per mode)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CLIENT_HAS_UPCOMING_BOOKINGS decodes to ErrorCode.clientHasUpcomingBookings"
    requirement: "SET-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/AccountDeletionBlockerTests.swift#decodesClientCode"
        status: pass
    human_judgment: false
  - id: D3
    description: "A 409 on delete-request or DELETE shows the blocker and stays on feedback; an unknown 409 code shows the server message; a retry calls delete-request again for a fresh token"
    requirement: "SET-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/DeleteAccountViewModelTests.swift#requestStep409Client, requestStep409Session, requestStep409UnknownCode, deleteStep409Expert, deleteStep409UnknownCode, retryAfterDelete409"
        status: pass
    human_judgment: false
  - id: D4
    description: "The blocker alert renders with View My Bookings opening My Bookings from the client shell, and the wrong-mode case shows the switch-mode message with no bookings button"
    requirement: "SET-06"
    verification: []
    human_judgment: true
    rationale: "Alert presentation and the shell navigation reset (HomeShellExit) are visual and device behavior; the plan lists it as a device check in 05-DEVICE-UAT-CHECKLIST.md"

duration: 15min
completed: 2026-11-13
status: complete
---

# Phase 05 Plan 08: Self-delete 409 blocker alert Summary

**A self-delete refused with EXPERT_HAS_UPCOMING_BOOKINGS, CLIENT_HAS_UPCOMING_BOOKINGS or SESSION_IN_PROGRESS now shows an iOS-owned "You can't delete your account yet" alert, with View My Bookings when the blocker's side matches the active mode and a switch-mode message when it does not.**

## Performance

- **Duration:** about 15 min
- **Completed:** 2026-11-13
- **Tasks:** 2
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `ErrorCode` decodes `CLIENT_HAS_UPCOMING_BOOKINGS`; previously iOS dropped it to nil and showed the generic alert.
- `AccountDeletionBlocker` owns the code mapping, the title, the button label, the mode rule and the five message strings. The view model and view contain no copy of their own.
- `DeleteAccountViewModel` handles 409 on both `delete-request` and `DELETE /user/account`, leaves the step on `.feedback`, and the old private message helper is gone in favor of `Error.userMessage`.
- `DeleteAccountView` has a second alert bound to `viewModel.blocker`. `View My Bookings` calls `showMyBookings` only when the rule allows it and the shell provides the action (client shell now; expert shell after plan 05-14).
- Every 409 path is covered by tests, including the retry asking for a fresh token.

## Task Commits

1. **Task 1: Tracer, a blocked deletion explains why and offers My Bookings** - `342940a` (fix)
2. **Task 2: The 409 paths are tested on both steps, and a retry asks for a fresh token** - `9ab79d2` (test)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified

- `ClickMe2026/Model/Enums/ErrorCode.swift` - new `clientHasUpcomingBookings` case
- `ClickMe2026/Utils/AccountDeletionBlocker.swift` - mapper, copy and mode rule
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift` - `blocker`, 409 cases, `userMessage`
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift` - `showMyBookings` environment value and the blocker alert
- `ClickMe2026Tests/Utils/AccountDeletionBlockerTests.swift` - mapping, mode rule, copy, decode
- `ClickMe2026Tests/Settings/DeleteAccountViewModelTests.swift` - 409 on both steps, unknown code, retry

## Decisions Made

See key-decisions. The blocker texts are the exact strings in the plan and the UI-SPEC copy table; plan 05-13 copies them into the Android todo (D-11).

## Deviations from Plan

### Spec refinements

**1. [UI-SPEC CP1 / A7] Bookings button label is Title Case**
- **Found during:** Task 1
- **Issue:** The plan says `View my bookings`; the approved UI-SPEC (CP1, A7) supersedes it with `View My Bookings`, matching the shipped Request Sent button.
- **Fix:** `AccountDeletionBlocker.bookingsActionLabel = "View My Bookings"`, asserted in `AccountDeletionBlockerTests.fixedStrings`. The plan's other strings are unchanged.
- **Files modified:** `AccountDeletionBlocker.swift`, `AccountDeletionBlockerTests.swift`
- **Committed in:** `342940a`

### Auto-fixed Issues

**2. [Rule 3 - Blocking] Test helpers needed `nonisolated`**
- **Found during:** Task 2
- **Issue:** The suite is `@MainActor`, so its static response helpers were main-actor isolated and could not be called from `APITestFactory.make`'s `@Sendable` responder (Swift 6 compile error).
- **Fix:** Marked the two pure helpers `nonisolated`.
- **Files modified:** `ClickMe2026Tests/Settings/DeleteAccountViewModelTests.swift`
- **Verification:** suite passes, 8 tests
- **Committed in:** `9ab79d2` (before the commit, so the committed file is the working one)

---

**Total deviations:** 2 (1 spec refinement, 1 Rule 3)
**Impact on plan:** No scope change.

## Verification Results

- `AccountDeletionBlockerTests`: 14 tests passed (`/tmp/05-08-t1.log`).
- `DeleteAccountViewModelTests`: 8 tests passed (`/tmp/05-08-t2.log`).
- `RememberedLoginEmailTests` (plan 05-01, same view model): 8 tests passed (`/tmp/05-08-reg.log`).
- Build gate: BUILD SUCCEEDED; warnings in the four app files: baseline 0, after 0 (`/tmp/05-08-warn-before.txt`, `/tmp/05-08-warn-after.txt`).
- Grep gate: new code present, 2 `AccountDeletionBlocker(code:` sites, no `Self.message(for:`, `showMyBookings` referenced in the view.
- TDD: the RED step for Task 1 was the test file written before any production symbol existed (the types and enum case were absent, so the target could not compile); a separate RED build run was not executed to save a 3 minute build. GREEN passed on the first run after implementation.
- `ClickMe2026/Localizable.xcstrings` carried pre-existing uncommitted edits before this run; this plan did not edit or stage it. The new alert strings are plain `Text`/`Button` literals and were not added to the catalog.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Device check (backstop)

On a real iPhone, as listed for 05-DEVICE-UAT-CHECKLIST.md: as a client with a confirmed upcoming session, Delete Account fails with the blocker alert and View My Bookings opens My Bookings; as a dual-role user in Client mode with only an expert-side booking, the alert says to switch to Expert mode and shows no bookings button. The expert shell button is checked in plan 05-14.

## Next Phase Readiness

Ready for plan 05-14 (installs `showMyBookings` on the expert shell, which makes the button appear in Expert mode) and 05-15 (Delete Account copy and pause card removal, built on top of this view model and view).

## Self-Check: PASSED

- Created files exist: `AccountDeletionBlocker.swift`, `AccountDeletionBlockerTests.swift`, `DeleteAccountViewModelTests.swift`.
- Commits `342940a` and `9ab79d2` are ancestors of HEAD; measured commit count 2.

---
*Phase: 05-signup-mode-switch-and-account*
*Completed: 2026-11-13*
