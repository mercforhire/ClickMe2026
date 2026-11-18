---
phase: 07-chat
plan: 06
subsystem: chat
tags: [swiftui, swift-testing, chat, block, expert-profile, toast, codable, tdd]

# Dependency graph
requires:
  - phase: 07-chat
    provides: "07-04 ChatBlockState (connectionFallback, actionErrorMessage, ScannedBlock); 07-05 Block & Report screen reading ScannedBlock(thread:)"
provides:
  - "Expert Profile Block {name} asks first in a centred alert, blocks through initiate then thread action once, stays on the profile and confirms with a toast"
  - "Failure copy by step (404 on initiate reads as This user is unavailable., transport errors as a connection problem) and an accessible in-flight scrim"
  - "ChatThreadItem.blockedByMe is a non-optional Bool that decodes as false when missing or null"
affects: [07-08, 07-09]

# Actuals (#2632) - chars/4 over the realized diff (git diff 0836655..HEAD, ClickMe2026 and ClickMe2026Tests, 29,805 chars)
actuals:
  tokens: 7451
  tasks: 3
  commits: 6
plan_head_before: 0836655b7520a3833f2fbefbb34b2eab4a442f8c
plan_head_after: 67fd0bad944db53497ec46ce3a5cff6bb102fdbc

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Profile-local action view model with an injected ClickMeAPI and ToastCenter, a stored Task and an awaitBlock() test seam"
    - "Error copy chosen per request step; branch on HTTP status and ErrorCode, never on message text"
    - "Decodable default added in an extension so the memberwise initializer stays available"

key-files:
  created:
    - "ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileBlockViewModel.swift"
    - ClickMe2026Tests/Chat/ProfileBlockActionTests.swift
    - ClickMe2026Tests/Chat/ChatThreadItemDecodingTests.swift
  modified:
    - "ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift"
    - ClickMe2026/Model/Responses/Children/ChatThreadItem.swift
    - ClickMe2026/Utils/ChatBlockState.swift

key-decisions:
  - "404 maps to This user is unavailable. only on the initiate step; a 404 on the block step shows the server message (plan assumption kept)"
  - "The view model reuses ChatBlockState.actionErrorMessage for the connection fallback and server message, so Block on the profile and Block in the chat read the same"
  - "ChatThreadItemDecodingTests is @MainActor: the app target's default isolation makes the Decodable conformance main-actor isolated, so a nonisolated suite cannot decode it"

patterns-established:
  - "In-flight scrim: Color.black.opacity(0.4) with a tap-absorbing empty gesture, a large Brand.primary ProgressView, one accessibility element labelled for the action with the modal trait"

requirements-completed: [CHAT-04, CHAT-03]

coverage:
  - id: D1
    description: "Block {name} runs POST /chats/initiate then POST /chats/{id}/actions with action block, once each, in that order, shows the toast You blocked {name} with checkmark.circle.fill, and sets no error"
    requirement: CHAT-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ProfileBlockActionTests.swift#block initiates the thread, then posts action block, once each, and toasts"
        status: pass
    human_judgment: false
  - id: D2
    description: "A failed initiate or block shows an error and no toast; initiate 404 reads This user is unavailable.; transport errors read Check your connection and try again.; a 404 on the block step shows the server message"
    requirement: CHAT-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ProfileBlockActionTests.swift (initiateFails, actionFails, initiateNotFound, initiateTransportError, actionTransportError, actionNotFound)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Repeat block calls send exactly one initiate and one block request; isBlocking is true while the request runs; an empty peer name reads as this user"
    requirement: CHAT-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ProfileBlockActionTests.swift (repeatBlockSendsOnce, isBlockingTracksTheRequest, blankNameFallsBack)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Alert presentation from the menu, the dim scrim with VoiceOver reading Blocking, the toast placement above the tab bar, and a live block on two accounts"
    requirement: CHAT-04
    verification:
      - kind: other
        ref: "Grep gate (GREP_OK) for alert copy, scrim, label, modal trait and disabled menu; build with no new warnings"
        status: pass
    human_judgment: true
    rationale: "Alert from a Menu, toast placement over the tab bar, VoiceOver output and a two-account block need a device; deferred to end-of-phase UAT (device checks C3 profile part, C7)"
  - id: D5
    description: "blocked_by_me decodes as false when the key is missing or null, true and false are kept, every other thread field decodes, and a legacy block reads as blocked by the peer with no Unblock"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatThreadItemDecodingTests.swift (5 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "No new warnings in the plan's files against an empty baseline; the full unit suite still passes (1152 tests in 105 suites)"
    requirement: CHAT-03
    verification:
      - kind: other
        ref: "build/warning diff (WARN_OK, /tmp/07-06-warn-t1.txt, warn-t2.txt, warn-t3.txt vs /tmp/07-06-warn-before.txt); xcodebuild test -only-testing:ClickMe2026Tests"
        status: pass
    human_judgment: false

# Metrics
duration: 13min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 06: Expert Profile Block Confirm, Toast and blocked_by_me Default Summary

**Block {name} on the Expert Profile now asks "Block {name}? They won't be able to message you.", blocks through initiate then the thread action without leaving the profile, confirms with a toast and fails with plain copy; `blocked_by_me` decodes as false when missing so a legacy block never offers Unblock.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-11-18T06:21:11Z
- **Completed:** 2026-11-18T06:34:16Z (before this SUMMARY)
- **Tasks:** 3 (Task 1 tracer, Tasks 2 and 3 auto TDD)
- **Files modified:** 6 (3 new, 3 changed), 6 task commits

## Accomplishments

- **Ask first (T-07-14).** The menu item only sets `showBlockConfirm`; the request starts from the alert's Block button, the one place `blockAction.block(` appears. The `isSameAsCurrentUser` guard is re-checked there (T-07-15). The combined Report & Block sheet, its thread-id state, the old "Couldn't open block flow" alert, `handleOpenBlockFlow()` and the private sheet-identifier struct are gone; `initiateChat` is now called once in the view (Message).
- **One request pair, then a toast.** `ExpertProfileBlockViewModel.block(peerId:peerName:)` returns while `isBlocking`, runs `initiateChat` then `chatAction(action: "block")`, and shows `You blocked {name}` with `checkmark.circle.fill` through the injected `ToastCenter`. No chat is opened (CHAT-04 prohibition).
- **Clear failures (UI E6).** A 404 on initiate (suspended or removed peer) reads `This user is unavailable.`; `URLError` reads `Check your connection and try again.`; anything else shows the server message. A 404 on the block step keeps the server message. Mapping branches on status and `ErrorCode`, never on text.
- **Accessible in-flight scrim (UI L3, C1).** A 40% black scrim absorbs taps with a large `Brand.primary` spinner, one VoiceOver element labelled `Blocking` with the modal trait; the menu is disabled while blocking (T-07-16).
- **blocked_by_me default (D-08, T-07-21).** `ChatThreadItem.blockedByMe` is `Bool`, decoded with `decodeIfPresent(Bool.self, forKey: .blockedByMe) ?? false` in an extension `init(from:)`; `ScannedBlock(thread:)` reads it directly. No coalesced read of the flag remains in the app.

## Task Commits

1. **Task 1: Tracer - Block asks first, blocks through the thread, confirms with a toast**
   - RED `c73c75d` (test) - 5 tests against a compiling no-op view model stub; target failed on the planned assertions
   - GREEN `e0819d2` (feat) - view model, alert, error alert, sheet and old flow removed
2. **Task 2: Clear failures, one request per confirm, accessible scrim**
   - RED `3153e44` (test) - 5 new tests; 404 and two transport rows failed on the planned assertions
   - GREEN `8977779` (feat) - per-step error mapping, scrim, disabled menu
3. **Task 3: blocked_by_me decodes as false when missing**
   - RED `6fc3ed1` (test) - 5 tests; missing-key and null rows failed (`nil` vs `false`)
   - GREEN `67fd0ba` (feat) - non-optional property, `init(from:)`, direct read in `ScannedBlock`

**Plan metadata:** the docs commit following this SUMMARY.

## TDD evidence

- **Tracer gate:** `HUMAN_VERIFY_MODE` is `end-of-phase` and Task 1's `<verify>` is automated-only, so the tests, grep gate and build/warning gate were re-run after GREEN and passed. Tracer verified end-to-end, then expanded.
- **RED, Task 1** (`/tmp/07-06-red.log`, `check tdd-red-evidence` returned `RED_EVIDENCE_OK`, target "block initiates the thread, then posts action block, once each, and toasts"): 0 requests recorded and no toast against a no-op stub. Semantic assessment: the target ran and failed on the planned assertions; the file compiled; no fixture fault. The "failed initiate sends no block request" assertion passed as a regression guard, its error assertion failed.
- **RED, Task 2** (`/tmp/07-06-red2.log`, `RED_EVIDENCE_OK`, target the initiate 404 test): `apiError` was `User not found.` and the raw `NSURLErrorDomain` text for transport errors. Semantic assessment: planned assertions failed. The first attempt did not compile (missing `unavailableMessage`); the constant was added to the RED commit so the evidence is real, not a build failure. The repeat-block test passed already (the Task 1 guard) and stays as a regression guard.
- **RED, Task 3** (`/tmp/07-06-red3.log`, `RED_EVIDENCE_OK`, target the missing-key test): `blockedByMe` was `nil`, expected `false`. Semantic assessment: planned assertion failed. The first attempt did not compile (suite needed `@MainActor`); fixed before the RED commit. The legacy-block row passed already via the old `ScannedBlock` fallback and stays as a guard.
- **GREEN:** `ProfileBlockActionTests` 10 tests, `ChatThreadItemDecodingTests` 5, `ChatBlockStateTests` and `ReportChatViewModelTests` pass; full unit run: 1152 tests in 105 suites passed. Debug build succeeded with no warnings in the plan's files (baseline empty).
- No REFACTOR commit was needed.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileBlockViewModel.swift` - initiate-then-block action, `isBlocking`, `apiError`, toast, per-step error mapping
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift` - confirm alert, `Couldn't block user` alert, scrim overlay, menu disabled while blocking; old sheet, state, handler and identifier removed
- `ClickMe2026Tests/Chat/ProfileBlockActionTests.swift` - 10 stubbed tests
- `ClickMe2026/Model/Responses/Children/ChatThreadItem.swift` - non-optional `blockedByMe`, extension `init(from:)` and `CodingKeys`
- `ClickMe2026/Utils/ChatBlockState.swift` - `ScannedBlock(thread:)` reads the flag directly
- `ClickMe2026Tests/Chat/ChatThreadItemDecodingTests.swift` - 5 pure decoding tests

## Decisions Made

- 404 maps to "This user is unavailable." only on the initiate step, as the plan assumed.
- Error text reuses `ChatBlockState.actionErrorMessage(for:)`, so the profile and the chat show the same connection and server wording. A `NOT_BLOCKER` code cannot arise from `block`, so its special copy is harmless here.
- `ChatThreadItemDecodingTests` is `@MainActor` (still pure: no `APITestFactory`), because the target's default main-actor isolation extends to the `Decodable` conformance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] RED commits carry a stub or constant so the tests compile**
- **Found during:** Tasks 1 and 2
- **Issue:** The plan lists one `feat` commit per task, but `tdd="true"` requires a RED commit with real failing evidence, and the tests reference `ExpertProfileBlockViewModel` (new) and `unavailableMessage` (new). A test file that does not compile is `build_failure`, not RED.
- **Fix:** The Task 1 RED commit adds a no-op `ExpertProfileBlockViewModel` stub with the test file; the Task 2 RED commit adds only the `unavailableMessage` constant. GREEN commits replace the stub with the implementation.
- **Files modified:** `ExpertProfileBlockViewModel.swift`, test files
- **Verification:** `RED_EVIDENCE_OK` on each target test
- **Committed in:** `c73c75d`, `3153e44`

**2. [Rule 3 - Blocking] Decoding suite needed `@MainActor`**
- **Found during:** Task 3 RED
- **Issue:** "main actor-isolated conformance of ChatThreadItem to Decodable cannot be used in nonisolated context".
- **Fix:** Marked the suite `@MainActor`, ids `nonisolated`. Still pure, no `APITestFactory`.
- **Files modified:** `ClickMe2026Tests/Chat/ChatThreadItemDecodingTests.swift`
- **Committed in:** `6fc3ed1`

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking)
**Impact on plan:** Each task has a RED and a GREEN commit instead of one; the test-file commit lists differ from the plan's "exactly three files" wording but together cover the same files. No scope creep.

## Deferred human verification

Device-only `<human-check>` of Task 2, deferred to end-of-phase UAT (`workflow.human_verify_mode = end-of-phase`) and logged in `.planning/WINDOWS.md` (kind `unrun-verify`, phase 7).

- **Steps (device checks C3 profile part and C7, two test accounts):** as the client, open the test expert's profile, tap the overflow menu, then Block {name}. Cancel once, then repeat and tap Block. With VoiceOver on, repeat on a second test account. Then open the thread on the expert's phone.
- **Expected:** Cancel sends nothing. Block shows the dim scrim with a spinner (VoiceOver says "Blocking"), then the toast "You blocked {name}" above the tab bar and home indicator, still on the profile. The expert's thread shows "You can't reply to this conversation" with only Report in the menu.
- **Why human:** alert presentation from a Menu, toast placement, VoiceOver and a live block on two accounts need hardware.

## Issues Encountered

- The first RED runs for Tasks 2 and 3 failed to compile (see deviations); fixed before committing so the RED evidence is on assertions.
- `check tdd-red-evidence` refuses paths outside the project, so the evidence JSON was written to a temporary `.planning/tmp/` and removed before each commit.
- Pre-existing unrelated working-tree changes (`.DS_Store`, `.planning/config.json`, `ClickMe2026/Localizable.xcstrings`, `.planning/state.json`, `.planning/milestone.lock`) were not staged.

## Known Stubs

None. The Task 1 view model stub existed only in the RED commit and was replaced in the GREEN commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 07-07. The profile no longer depends on `ReportChatView`; `ReportChatView` is now used from the chat only.
- Backend unchanged and read-only: `/chats/initiate`, `/chats/{id}/actions` and the `blocked_by_me` list field were checked against `chats.controller.js` and CHAT-UNBLOCK §9. No cross-repo or Android change is made here; Android parity for the profile Block alert is for the phase's Android follow-up.

---
*Phase: 07-chat*
*Completed: 2026-11-18*

## Self-Check: PASSED

- Created files exist: ExpertProfileBlockViewModel.swift, ProfileBlockActionTests.swift, ChatThreadItemDecodingTests.swift.
- Commits `c73c75d`, `e0819d2`, `3153e44`, `8977779`, `6fc3ed1`, `67fd0ba` are ancestors of HEAD.
- Acceptance criteria re-run: all grep gates PASS, tests PASS, warning diff empty.
