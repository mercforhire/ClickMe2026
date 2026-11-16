---
phase: 06-expert-mode
plan: 02
subsystem: ui
tags: [swift, swiftui, topics, patch-null, delete-confirmation, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "06-01 topic editor price parsing (same Topics folder, untouched here)"
provides:
  - "NullableField<Value> (omit / set / null) with patch(old:new:)"
  - "UpdateExpertTopicRequest.encode(to:) that sends icon_slug and description as JSON null when cleared"
  - "Topic edit save that diffs icon and description against the stored topic"
  - "Delete this topic? centred alert; DELETE only from its destructive button"
  - "Delete doc comments that describe the real soft delete with no conflict response"
affects: [06-10 device UAT checklist (topic delete and clear-icon checks), 06-09 Android parity]

actuals:
  tokens: 4900
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Three-state PATCH field (omit / set / null) so a cleared value reaches the server as an explicit null"
    - "Destructive action from a Menu item goes through view-model pending state and a centred .alert, with the topic passed to the confirm action explicitly"

key-files:
  created:
    - ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift
    - ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
  modified:
    - ClickMe2026/Model/Requests/ExpertTopicRequest.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
    - ClickMe2026/Network/ClickMeAPI+ExpertProfile.swift

key-decisions:
  - "PATCH diffs against editingTopic and omits unchanged icon and description (UI-SPEC section 1); research assumption A7 (always send set-or-null) not adopted"
  - "A stored empty string counts as no value in the diff, so an empty stored description never produces a null"
  - "Delete confirmation uses .alert on loadedContent, not .confirmationDialog (a Menu trigger would anchor a dialog as an iPad popover), and not on the outer ZStack that already holds the error alert"

patterns-established:
  - "NullableField.patch(old:new:) is the one place that decides omit / set / null for a cleared PATCH field"

requirements-completed: [EXP-01, EXP-04, EXP-08]

coverage:
  - id: D1
    description: "Clearing a topic's icon and description sends icon_slug and description as JSON null on PATCH; the updated topic replaces the list entry"
    requirement: EXP-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#clearedFieldsSendNull"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift#nullEncodesAsNSNull"
        status: pass
    human_judgment: false
  - id: D2
    description: "A save that leaves the stored icon and description alone sends neither key; nothing-to-nothing never sends null; other keys encode as before"
    requirement: EXP-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#unchangedFieldsSendNoKeys"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift#nothingToNothingIsOmitted"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift#otherKeysUnchanged"
        status: pass
    human_judgment: false
  - id: D3
    description: "Tapping Delete or Cancel sends no DELETE; confirming sends one and removes the topic only after a 2xx; a 404 keeps the card and sets the server message; a repeat 404 leaves the list alone"
    requirement: EXP-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#requestDeleteSendsNothing"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#cancelDeleteSendsNothing"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#confirmDeleteRemovesAfterSuccess"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#failedDeleteKeepsTheTopic"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift#secondDeleteLeavesTheListAlone"
        status: pass
    human_judgment: false
  - id: D4
    description: "The delete comments describe a soft delete with a 404 and no conflict response (comment-only)"
    requirement: EXP-08
    verification:
      - kind: command
        ref: "grep gate: no 'Returns 409 if the topic has active' or 'Server returns 409' left in ClickMe2026"
        status: pass
    human_judgment: false
  - id: D5
    description: "The alert is centred on a device when opened from the card menu, reads the exact copy with curly quotes, and shows no toast; a cleared icon and description stay cleared after reopening against the live server"
    requirement: EXP-01
    verification: []
    human_judgment: true
    rationale: "Alert presentation from a Menu and the live server round trip need a real iPhone (device check written by plan 06-10)"

plan_head_before: d5cbb345fc66f6a00acddef57c9f89c25f69b83c
plan_head_after: e042550

duration: 10min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 02: Clear topic icon/description and confirm topic delete Summary

**A three-state NullableField so a cleared topic icon or description goes to PATCH /expert/topics/:id as an explicit JSON null (unchanged ones are omitted), plus a centred "Delete this topic?" alert so Delete never fires from one tap, and delete comments that describe the real soft delete.**

## Performance

- **Duration:** about 10 min
- **Completed:** 2026-11-16
- **Tasks:** 2
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- `NullableField<Value>` (`omit`, `set`, `null`) with `patch(old:new:)`, and a hand-written `UpdateExpertTopicRequest.encode(to:)` that uses `encodeNil` for `.null`. `CreateExpertTopicRequest` is untouched.
- The edit save compares icon and description with the stored topic (empty stored value counts as none): unchanged omits the key, cleared sends null, changed sends the string. The `saveTopic` signature is unchanged, so the editor closure compiles as before.
- The card's Delete now calls `requestDelete`; the `Delete this topic?` alert (message with curly-quoted title) confirms with the presenting topic. Cancel and tapping Delete send nothing; removal happens only after a 2xx; a failure shows the existing error alert and keeps the card.
- Two doc comments (`deleteMyTopic`, `deleteTopic`) no longer promise a 409.
- Tests: `ExpertTopicRequestBodyTests` (10 rows, pure) and `TopicsSetupMutationTests` (7 rows, stubbed, `.serialized`).

## Task Commits

1. **Task 1: Tracer, clearing a topic's icon and description sends explicit nulls on PATCH** - `6560a2d` (fix)
2. **Task 2: Delete asks first, and the delete comments match the soft-delete contract** - `e042550` (fix)

**Plan metadata:** committed with this SUMMARY (docs).

_TDD note: the plan prescribes one commit per task, so there are no separate `test(...)` commits. RED was still observed for Task 1 before any implementation: the two stubbed PATCH rows (`clearedFieldsSendNull`, `unchangedFieldsSendNoKeys`) ran against the unchanged code and failed on the planned assertions (`icon_slug` and `description` absent where NSNull was expected; present where absent was expected). Task 2's rows call new view-model methods, so their RED would only be a compile failure (INVALID_RED); they were written with the implementation._

## Files Created/Modified
- `ClickMe2026/Model/Requests/ExpertTopicRequest.swift` - `NullableField`, `UpdateExpertTopicRequest` with `CodingKeys` and `encode(to:)`
- `ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupViewModel.swift` - PATCH diff, `topicPendingDelete`, `requestDelete`, `cancelDelete`, `confirmDelete`, corrected comment
- `ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupView.swift` - `Delete this topic?` alert on `loadedContent`
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift` - Delete item routes to `requestDelete`
- `ClickMe2026/Network/ClickMeAPI+ExpertProfile.swift` - comment-only change (verified in the diff: 2 comment lines replaced by 3)
- `ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift`, `ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift` - new suites

## Decisions Made
See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Accuracy] Delete comments say 404 for a missing or other expert's topic, not "already-deleted"**
- **Found during:** Task 2 (read_first of `softDeleteTopic`)
- **Issue:** The plan text says an already-deleted topic returns 404. The backend (`src/controllers/expertTopics.controller.js`, identical at production `28da165`) updates `is_active=false` with `.eq('id')` and `.eq('expert_id')` only, so a repeat DELETE of an archived topic that still exists answers 200 `Topic archived`; a 404 comes only for a missing id or another expert's topic.
- **Fix:** The two comments state the verified contract: soft delete, 404 for a topic that does not exist or is not the caller's, no conflict response. The "repeat delete" test row still stubs a 404 because that is what the client must handle for any failure (the row proves the list is left alone); it does not assert the server's behavior.
- **Files modified:** `ClickMeAPI+ExpertProfile.swift`, `TopicsSetupViewModel.swift`
- **Commit:** `e042550`

**2. [Rule 3 - Blocking] Test fixtures made `nonisolated`**
- **Found during:** Task 1 RED run
- **Issue:** Swift 6 rejected main-actor static helpers and a default argument read inside the `@Sendable` MockURLProtocol handler.
- **Fix:** Marked the fixture statics `nonisolated`.
- **Commit:** `6560a2d`

---

**Total deviations:** 2 auto-fixed (1 accuracy, 1 blocking)
**Impact on plan:** None on behavior. Comment wording follows the real server code.

## Issues Encountered
- None blocking. `ClickMe2026/Localizable.xcstrings` is rewritten by Xcode on every build (the new alert strings included); it was not staged, per the dispatch rules, and still carries the pre-existing uncommitted change.

## Verification Results
- `ExpertTopicRequestBodyTests`: 10 tests in 1 suite passed. `TopicsSetupMutationTests`: 7 tests in 1 suite passed (separate xcodebuild runs).
- Build: BUILD SUCCEEDED; warning baseline for the five app files was empty and stays empty (0 new warnings).
- Change-gate greps all pass (stale 409 comments gone, card routes to `requestDelete`, alert title and `confirmDelete(topic)` present, `topicPendingDelete` present, 404 named in the API comment); "won't be able to book it" count 1 (baseline 0).
- `CreateExpertTopicRequest` is unchanged in the Task 1 diff.
- Not run: the new suites together with the other stubbed suites in one invocation (the phase gate, plan 06-10, does that). Device check for the alert and the live clear-icon round trip is left to 06-10.

## Known Stubs
None.

## Threat Flags
None. T-06-03 (null only for a cleared stored value; omit and set rows prove it) and T-06-04 (DELETE only from the confirmation alert; 0-DELETE rows for request and cancel; removal after 2xx) are implemented. The backend was read-only.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Device UAT items for 06-10: Delete then Cancel, Delete then Delete (centred alert, curly-quoted title, no toast), and clear icon and description then reopen.
- Ready for 06-03.

## Self-Check: PASSED
- FOUND: ClickMe2026Tests/Model/ExpertTopicRequestBodyTests.swift, ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
- FOUND commits: 6560a2d, e042550

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
