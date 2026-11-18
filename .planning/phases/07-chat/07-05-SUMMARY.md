---
phase: 07-chat
plan: 05
subsystem: chat
tags: [swiftui, swift-testing, chat, block, unblock, report, moderation-enum, utf16, tdd]

# Dependency graph
requires:
  - phase: 07-chat
    provides: "07-03 ChatThreadLookup; 07-04 ChatBlockState, ChattingViewModel.adoptBlockState(_:)"
provides:
  - "Block & Report card follows the CHAT-UNBLOCK section 5 matrix: Unblock only for the blocker, truthful block copy, no button after NOT_BLOCKER"
  - "Block, unblock and NOT_BLOCKER outcomes reach the thread (onBlockStateChange -> adoptBlockState) with no reload"
  - "Chat reports send UserReportReason raw values; details capped at 1,000 UTF-16 units with an always-visible counter"
  - "ReportChatViewModelTests: 19 stubbed tests"
affects: [07-06, 07-08]

# Actuals (#2632) - chars/4 over the realized diff (git diff 422041b..HEAD, ClickMe2026 and ClickMe2026Tests, 45,422 chars)
actuals:
  tokens: 11356
  tasks: 2
  commits: 4
plan_head_before: 422041b8360cd8eb3ccb8e8df088b934b489bd7d
plan_head_after: ae8c67114e324f5e5405bfd726b61f391f0e1be4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Screen view model holds one ChatBlockState and reports every change through a callback closure; the presenting thread adopts it"
    - "stateRevision counter lets a late GET /chats lookup be ignored when a block or unblock finished while it ran"
    - "Text caps use a didSet on the published property with UTF16Prefix, so existing $viewModel bindings are capped with no new binding"

key-files:
  created:
    - ClickMe2026Tests/Chat/ReportChatViewModelTests.swift
  modified:
    - "ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatViewModel.swift"
    - "ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatView.swift"
    - "ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift"
    - "ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatReasonField.swift"
    - "ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatReportCard.swift"
    - "ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatDescriptionField.swift"
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift

key-decisions:
  - "No unblock latch: after NOT_BLOCKER the state is blocked-by-peer, which already hides the button (matches 07-04)"
  - "A lookup result is dropped when a block or unblock applied while it ran (stateRevision), so a stale GET /chats cannot undo the user's action"
  - "ReportChatViewModel is the only place with the new logic; ChattingViewModel.swift stays at 624 lines (only ChattingView.swift was touched on the thread side)"

patterns-established:
  - "Alert title is a published property (apiErrorTitle) set with the message, one title per action"
  - "Details counter counts utf16 units, the server's zod unit, not Characters"

requirements-completed: [CHAT-02, CHAT-03, CHAT-04]

coverage:
  - id: D1
    description: "Block 200 gives blocked by me and tells the thread once; unblock 200 gives not blocked; unblock 403 NOT_BLOCKER gives blocked by the peer with its own title and message; 500 and transport errors keep the state and show the right copy; a repeat Block tap sends one request"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ReportChatViewModelTests.swift (blockSucceeds, blockServerError, blockTransportFailure, blockIgnoresARepeatTap, unblockSucceeds, unblockNotBlocker, unblockServerError)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The block lookup uses ChatThreadLookup (limit 100); a legacy block reads as blocked by the peer; an unlisted thread or a failed lookup leaves the state alone and tells nobody"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ReportChatViewModelTests.swift (loadBlockStateListed, loadBlockStateNotListed, loadBlockStateFails)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Block card copy for the three rows and the confirm dialog message describe only stopping new messages in this conversation (D-05); no profile or booking claim remains in the Chat folder"
    requirement: CHAT-04
    verification:
      - kind: other
        ref: "Task 1 grep gate (GREP_OK): exact copy present, profile and appointment claims 0, old headline 0"
        status: pass
    human_judgment: true
    rationale: "Card layout, wording in context and the Unblock accent style need eyes on a device; deferred to end-of-phase UAT (device checks C3, C4 card part)"
  - id: D4
    description: "Chat reports send the UserReportReason raw value for all six cases with action report; nothing is preselected; no reason shows the reason error and sends nothing"
    requirement: CHAT-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ReportChatViewModelTests.swift (reportSendsRawValue, pickerListsTheEnum, reportWithoutReason)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Report details stop at 1,000 UTF-16 units on typing and paste without splitting an emoji, are trimmed on submit, and are omitted when blank; the counter shows n/1000"
    requirement: CHAT-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ReportChatViewModelTests.swift (detailsAreCapped, capKeepsEmojiWhole, blankDetailsAreOmitted, detailsAreTrimmed)"
        status: pass
    human_judgment: true
    rationale: "The counter's look and a real 1,000-character paste into the TextEditor need a device; deferred to end-of-phase UAT"
  - id: D6
    description: "A failed report (429 TOO_MANY_REQUESTS or transport) shows Couldn't send report with the server message or the not-sent connection copy, is posted once and never retried"
    requirement: CHAT-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ReportChatViewModelTests.swift (reportRateLimited, reportTransportFailure)"
        status: pass
    human_judgment: false
  - id: D7
    description: "No new warnings in the plan's files against an empty baseline; ChattingViewModel.swift still 624 lines"
    requirement: CHAT-03
    verification:
      - kind: other
        ref: "build/warning diff (WARN_OK, /tmp/07-05-warn-t1.txt and warn-t2.txt vs /tmp/07-05-warn-before.txt); wc -l"
        status: pass
    human_judgment: false

# Metrics
duration: 14min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 05: Block & Report Blocker Matrix, Enum Reasons and Capped Details Summary

**The Block & Report screen now shows Unblock only to the person who blocked, describes blocking as stopping new messages in this chat only, hands every block, unblock and NOT_BLOCKER outcome back to the thread, and sends chat reports with the moderation enum and details capped at 1,000 UTF-16 units.**

## Performance

- **Duration:** about 14 min (start time approximate; the plan start time was not recorded)
- **Completed:** 2026-11-18T06:20Z
- **Tasks:** 2 (Task 1 tracer, Task 2 auto TDD)
- **Files modified:** 8 (1 new, 7 changed), 4 task commits

## Accomplishments

- **Blocker matrix (Task 1, tracer).** `ReportChatBlockCard` takes a `ChatBlockState` and the peer name and renders the three section 5 rows: Block User with the red button, "You blocked this conversation" with an Unblock User button in the accent (`brandGreen`) style, and "You can't reply to this conversation" with no button for the other side, a legacy block and the state after NOT_BLOCKER. The unblock latch is gone.
- **Truthful copy (CHAT-04, D-05).** The not-blocked body is exactly "Blocking stops both of you from sending new messages in this conversation. You can still see earlier messages. They won't be notified." and the confirm dialog says "They won't be able to message you. They won't be notified." No profile or appointment claim remains in the Chat folder.
- **Thread hand-back (UI N1).** `ReportChatViewModel` holds a `ChatBlockState`, applies the section 6 transitions and calls `onBlockStateChange`; `ChattingView` seeds the screen from `blockState` and passes `adoptBlockState`. Lookup now uses `ChatThreadLookup` (limit 100, 3 pages) instead of one 50-thread page. Alert titles are per action: Couldn't block user, Couldn't unblock user, Couldn't send report.
- **Enum reasons and capped details (Task 2).** The picker lists the six `UserReportReason` labels in enum order with nothing preselected (A13, confirmed 2026-11-17) and posts the `rawValue`. Details are capped by a `didSet` using `UTF16Prefix` (emoji-safe), shown with an always-visible `n/1000` counter, trimmed on submit and omitted when blank. A 429 or transport failure is shown once and never retried.

## Task Commits

1. **Task 1: Tracer - blocker matrix, truthful copy, thread hand-back**
   - RED `a77240f` (test) - 10 rows, 7 failing on state, title, copy and limit-100 assertions
   - GREEN `dedc034` (feat) - view model, card, view and thread wiring
2. **Task 2: Chat reports send the moderation enum; details capped at 1,000**
   - RED `68e8658` (test) - 8 rows, all failing on the planned assertions
   - GREEN `ae8c671` (feat) - enum picker, cap, counter, error copy

**Plan metadata:** the docs commit following this SUMMARY.

## TDD evidence

- **Tracer gate:** `HUMAN_VERIFY_MODE` is `end-of-phase` and Task 1's `<verify>` is automated-only, so tests, grep gate and build/warning gate were re-run after GREEN and passed. Tracer verified end-to-end, then expanded.
- **RED, Task 1** (`/tmp/07-05-red.log`, `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`): `blockState` stayed not blocked after block 200 and unblock 200, NOT_BLOCKER kept blocked-by-me with the server text, `apiErrorTitle` stayed "Couldn't block user", the lookup sent `limit=50`. The 500-on-block, repeat-tap, not-listed and failed-lookup rows passed as regression guards. Semantic assessment: the target ran and failed on the planned assertions; no compile or fixture fault.
- **RED, Task 2** (`/tmp/07-05-red2.log`, `RED_EVIDENCE_OK`, target "a 429 shows its title..."): no POST was made for any of the six reasons, the 1,200-character description stayed 1,200 units, blank details were not omitted, the report error title and not-sent copy were missing. Semantic assessment: the target ran and failed on the planned assertions.
- **GREEN:** `ReportChatViewModelTests` 19 tests passed; regression run of `ChatBlockStateTests`, `ChattingViewModelOpenTests`, `ChattingViewModelSendTests` and the new suite: 95 tests in 4 suites passed. Debug build succeeded with no warnings in the plan's files (baseline empty).
- No REFACTOR commit was needed.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatViewModel.swift` - `blockState`, `onBlockStateChange`, `apiErrorTitle`, `actionTask`/`awaitPendingAction()`, `ChatThreadLookup` lookup, enum reasons, capped details
- `ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatView.swift` - `onBlockStateChange` init parameter, new dialog message, per-action alert title
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift` - section 5 card
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatReasonField.swift`, `ReportChatReportCard.swift`, `ReportChatDescriptionField.swift` - enum picker types, counter
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` - seed and `adoptBlockState` wiring
- `ClickMe2026Tests/Chat/ReportChatViewModelTests.swift` - new suite (19 tests)

## Decisions Made

- No unblock latch, as in 07-04: `blockedByMe == false` after NOT_BLOCKER already hides the button.
- `stateRevision` (not in the plan) drops a lookup that finished after a block or unblock applied, so a stale `GET /chats` cannot revert the user's action.
- `ExpertProfileView`, the other caller of `ReportChatView`, needed no change: the new init parameter has a default and the card derives from the same initial flags.

## Deviations from Plan

### Auto-fixed Issues

**1. [Process] RED and GREEN split into separate commits per task**
- The plan lists one `feat` commit per task; the TDD rules require a RED test commit first, so each task has a `test(07-05)` and a `feat(07-05)` commit, as in plans 07-01 to 07-04. Small compile seams (`blockState`, `apiErrorTitle`, `onBlockStateChange`, `awaitPendingAction`, `selectReason(UserReportReason)` stub, `maxDetailsLength`) landed in the RED commits so the tests compile and fail on assertions.

**2. [Process] Picker row moved to the Task 2 GREEN commit**
- **Found during:** Task 2 RED
- **Issue:** `pickerListsTheEnum` reads `viewModel.reasons.map(\.displayLabel)`, which cannot compile until `reasons` becomes `[UserReportReason]`; it made the RED run a build failure (INVALID_RED).
- **Fix:** The row was added in the GREEN commit with the type change; the other seven Task 2 rows carry the RED evidence.
- **Committed in:** `ae8c671`

**3. [Process] Parameterized six-reason test written as one looping test**
- The checker counts each argument case as a test but sees one result line, rejecting the RED record as an incomplete swift-testing report. `reportSendsRawValue` loops over `UserReportReason.allCases` with a fresh view model and API each time; coverage is the same.

**4. [Rule 1 - Bug] Stale lookup could undo a block (added `stateRevision`)**
- **Found during:** Task 1 (GREEN)
- **Issue:** `loadBlockState()` runs on appear; if it returned after a block or unblock had applied, it would overwrite the new state with the older scan.
- **Fix:** A revision counter bumped on every applied state; a lookup that started before the bump is ignored.
- **Files modified:** `ReportChatViewModel.swift`
- **Committed in:** `dedc034`

---

**Total deviations:** 1 auto-fixed (Rule 1), 3 process notes
**Impact on plan:** No change to behaviour or to the names later plans use.

## Issues Encountered

- A first GREEN test run failed to compile because the `awaitPendingAction()` seam was dropped when the block section was replaced; it was re-added.
- `ClickMe2026/Localizable.xcstrings` and `.planning/config.json` have pre-existing uncommitted changes and were left unstaged. New copy is literals in code, like the surrounding chat screens.

## Deferred human verification

Per the user's decision (`workflow.human_verify_mode = end-of-phase`), the Task 2 `<human-check>` was NOT run and is carried to the end-of-phase UAT. It is logged in `.planning/WINDOWS.md` as an `unrun-verify` entry. Unit and build gates passed; only hardware evidence is outstanding.

### H1. Task 2: Block & Report screen on device (device checks C3, C4 card part, report part)

**Setup:** two test accounts (A and B) on iPhones against the production backend, with a thread between them.
**Steps:**
1. A opens Block & Report on an unblocked thread.
2. A taps Block User and confirms; A returns to the thread.
3. A opens Block & Report again; then B opens Block & Report on the same blocked thread.
4. A taps Unblock User.
5. On either account open the reason picker, then paste more than 1,000 characters into Description, then submit a report on a test account.

**Expected:**
- Step 1: the card reads "Block User", the body is "Blocking stops both of you from sending new messages in this conversation. You can still see earlier messages. They won't be notified." with a red Block User button; the confirm dialog says "They won't be able to message you. They won't be notified."
- Step 2: the thread shows the blocked banner at once, without a reload.
- Step 3: A sees "You blocked this conversation", "Unblocking lets you and {name} send messages in this conversation again." and an Unblock User button in the green style; B sees "You can't reply to this conversation", the can't-lift body and no button.
- Step 4: the card returns to Block User and the thread shows the composer on return.
- Step 5: the picker lists Harassment or abuse, Spam, Inappropriate content, Scam or fraud, Impersonation, Something else, in that order, nothing preselected; Description stops at 1,000 with the counter at 1000/1000; the report submits and shows the submitted state.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. `ChatThreadItem.blockedByMe` is still `Bool?`; `ChatBlockState.ScannedBlock(thread:)` holds its only fallback until plan 07-06 Task 3.

## Threat Flags

None. T-07-10 (reason pollution) is mitigated by the enum-only picker and `rawValue` (tested for all six cases), T-07-11 by the UTF-16 cap, T-07-12 accepted (one POST on 429), T-07-13 by adding no logging.

## Next Phase Readiness

Ready for 07-06 (Task 3 makes `blockedByMe` non-optional; this plan reads it only through `ScannedBlock(thread:)`). The Block & Report screen and the thread now share one state value, so the 07-08 gate can grep the Chat folder for the removed copy and logging calls.

---
*Phase: 07-chat*
*Completed: 2026-11-18*

## Self-Check: PASSED

- Created files exist: `ClickMe2026Tests/Chat/ReportChatViewModelTests.swift`.
- Commits exist on HEAD: `a77240f`, `dedc034`, `68e8658`, `ae8c671`.
- RED and GREEN gate commits are present for each task, in order.
