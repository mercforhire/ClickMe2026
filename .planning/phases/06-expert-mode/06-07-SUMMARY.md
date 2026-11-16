---
phase: 06-expert-mode
plan: 07
subsystem: ui
tags: [swiftui, booking-note, utf16, discard-prompt, pop-gesture-lock]

requires:
  - phase: 06-expert-mode
    provides: plan 06-06 (expert hub), tree baseline for the warning compare
provides:
  - "Expert private note hard-capped at 5,000 UTF-16 units with a counter from 4,500"
  - "Whitespace-only note saves as empty; other text sent as typed; persisted value is exactly what was sent"
  - "Custom Back with Discard changes? prompt, and an always-on swipe-back lock on the Booking Note screen"
affects: [06-10 device UAT checklist, EXP-16 verification]

actuals:
  tokens: 6500
  tasks: 2
  commits: 2
plan_head_before: d4c5e3e5b2c7898e8fa6389ad6f604703679f0da
plan_head_after: eb14c73007bdc0b114940125e27d6f02cba1b4ca

tech-stack:
  added: []
  patterns:
    - "Capped TextEditor binding: set closure routes through a view-model updateNote using UTF16Prefix"
    - "Unconditional BookingRequestSentPopGestureLock plus hidden system back and a custom 44 pt Back button"

key-files:
  created:
    - ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift

key-decisions:
  - "Swipe-back lock is attached unconditionally (D-19 amendment, user decision 2026-11-16), superseding UI-SPEC section 7's lock-only-while-dirty design; 06-UI-SPEC.md not edited"
  - "save() sets lastPersisted to the normalized text that was sent, and rewrites noteText only if it still equals the text captured at save start, so text typed during the request is kept and still counts as changed"
  - "needsDiscardPrompt = hasChanges || isSaving, so Back during a save in flight still asks"

requirements-completed: []  # EXP-16 left pending: requirements.ready-ids reports it blocked by plan 06-10

coverage:
  - id: D1
    description: "Note capped at 5,000 UTF-16 units on type and paste without splitting an emoji"
    requirement: EXP-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift#longPasteIsCapped, emojiIsNotSplit"
        status: pass
    human_judgment: false
  - id: D2
    description: "Counter {n} / 5,000 from 4,500, locale grouped, error colour at the limit, VoiceOver label"
    requirement: EXP-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift#counterThreshold, counterText"
        status: pass
    human_judgment: true
    rationale: "Colour, placement above the keyboard and the VoiceOver reading need a device check (LT1, OV2)"
  - id: D3
    description: "Whitespace-only note posts \"\" and the field then shows empty; other text sent as typed"
    requirement: EXP-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift#whitespaceOnlySavesEmpty, normalization, failedSaveKeepsText, successfulSaveClearsChanges"
        status: pass
    human_judgment: false
  - id: D4
    description: "Back asks Discard changes? when unsaved, pops at once when clean; swipe-back never pops the screen"
    requirement: EXP-16
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift#editPromptsAndRevertClears, savingCountsAsChanged, savedNoteDoesNotPrompt, loadedNoteDoesNotPrompt"
        status: pass
    human_judgment: true
    rationale: "Interactive pop gesture and the alert presentation cannot be unit-tested; device check D4"

duration: 15min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 07: Expert Booking Note Summary

**Expert private booking note capped at 5,000 UTF-16 units through UTF16Prefix with a 4,500 counter, whitespace-only saves as empty, and a Discard changes? Back prompt with swipe-back always locked.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-11-16
- **Tasks:** 2
- **Files modified:** 3 (1 created)

## Accomplishments
- `ExpertBookingNoteViewModel` gained `noteLimit`, `counterFrom`, `updateNote(_:)`, `noteLength`, `showsCounter`, `counterText(length:locale:)`, `normalizedForSave(_:)` and `needsDiscardPrompt`; `save()` posts the normalized text and persists exactly what was sent.
- `ExpertBookingNoteView` binds the editor through `updateNote`, shows the trailing caption counter from 4,500 (error colour at 5,000, VoiceOver "{n} of 5,000 characters"), hides the system back for a 44 by 44 pt `chevron.left` Back button, shows the Discard changes? alert (Keep editing / Discard), and attaches `BookingRequestSentPopGestureLock` unconditionally.
- New stubbed `ExpertBookingNoteViewModelTests` suite, 13 tests, all passing (`.serialized`, own handler per test through `APITestFactory.make`).
- No logging of the note text in the note files (grep gate 0), the three nav-bar pins and the `frame(minHeight: 260)` editor card are unchanged.

## Task Commits

1. **Task 1: Tracer, cap, counter, whitespace-only saves empty** - `9c72c8e` (feat)
2. **Task 2: Discard changes? prompt, custom Back, always-on swipe lock** - `eb14c73` (feat)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Files Created/Modified
- `ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift` - cap, counter, normalization, dirty-state rules
- `ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift` - capped binding, counter, custom Back, discard alert, pop lock
- `ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift` - 13 stubbed tests

## Decisions Made
See key-decisions. The swipe lock supersedes UI-SPEC section 7's design by user decision 2026-11-16, so nothing about the swipe is left to the device check beyond confirming it is blocked.

## Deviations from Plan

None - plan executed exactly as written.

TDD note: Task 1 is a single tracer commit per the plan. The tests were written before the implementation, but the RED run was not separately executed: every behavior row names a symbol that did not exist, so the only possible RED was a compile failure (INVALID_RED by `build_failure`), which would not have been valid evidence. GREEN was confirmed by the suite passing (9 tests after Task 1, 13 after Task 2).

## Issues Encountered
None. Warning baseline for the two app files was 0 before and 0 after each task.

## Known Stubs
None.

## Threat Flags
None. The note text goes only to the existing note POST; no new endpoints or logging.

## Open Device Checks (WINDOWS.md entry added, kind unrun-verify)
- D4, OV2, LT1, EM2 on a real iPhone (06-DEVICE-UAT-CHECKLIST.md, owned by plan 06-10). One point to watch: when a paste or keystroke is cut at 5,000 and the stored text does not change, confirm the TextEditor shows the cut text and not the extra characters. If it shows extra text, that is a bug in this plan to fix before the release.

## Requirements
EXP-16 left pending in REQUIREMENTS.md: `requirements.ready-ids` reports it blocked by plan 06-10 (shared ID, sibling has no SUMMARY yet).

## Next Phase Readiness
Ready for 06-08.

## Self-Check: PASSED
- Created file `ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift` exists; commits `9c72c8e` and `eb14c73` are on `main`.
- Suite: Test run with 13 tests in 1 suite passed. Build: BUILD SUCCEEDED, no new warnings in the two app files.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
