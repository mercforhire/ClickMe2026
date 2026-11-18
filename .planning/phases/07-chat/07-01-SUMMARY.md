---
phase: 07-chat
plan: 01
subsystem: chat
tags: [swiftui, swift-testing, optimistic-send, thread-reducer, client_msg_id, tdd]

# Dependency graph
requires:
  - phase: 07-chat
    provides: "07-CONTEXT decisions D-01, D-02, D-03 (first half), D-17 and the 07-UI-SPEC failed-bubble contract"
provides:
  - "Optimistic chat send: pending bubble at once, ack updates the same bubble, Failed bubble on network/5xx, refused text returned to the composer"
  - "ChatThreadReducer: pure thread rules ported from Android ThreadReducer.kt (appendLocal, ack, fail, retry, remove, findMine, mergePage, onIncoming, unreadPeerIds, order, sendFailure)"
  - "ChatSendCoordinator: sibling type owning sends in flight keyed by client_msg_id"
  - "ChatItemMapper: server-row mapping moved out of ChattingViewModel, now carrying client_msg_id and event server id and time"
  - "ChatFixtures test support for later Phase 7 plans"
affects: [07-02, 07-03, 07-04, 07-05, 07-08]

# Actuals (#2632) - chars/4 over the realized diff
actuals:
  tokens: 20523
  tasks: 3
  commits: 4
plan_head_before: f7ff0b1b6244b946f33930cd487de307385fe87c
plan_head_after: afd3c31c59f73db25d27ad624a185bcaacf52b5c

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure reducer over [ChatItem]; a message is mutated by taking it out of .message and writing it back at the same index so ChatMessage.id never changes"
    - "Send bookkeeping in a sibling coordinator (one Task per client_msg_id) so the view model holds no in-flight state"
    - "Server rows ordered by (server time, original index); local unsent rows follow in their order"

key-files:
  created:
    - ClickMe2026/Utils/ChatThreadReducer.swift
    - ClickMe2026/Utils/ChatItemMapper.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/ChatSendCoordinator.swift
    - ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift
    - ClickMe2026Tests/Chat/ChatThreadReducerTests.swift
    - ClickMe2026Tests/Support/ChatFixtures.swift
  modified:
    - ClickMe2026/Model/UIModels/ChatDisplayModels.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift

key-decisions:
  - "HTTP 4xx is a refusal (bubble removed, text restored, alert); everything else, including 5xx, URLError, decode and invalid-response failures, keeps the bubble as Failed with no alert"
  - "Failed glyph is an overlay offset 28 pt left of the bubble rather than an HStack sibling, so the 260 pt frame sees the same content as in the Sending state and the text never re-wraps when a send fails"
  - "ChattingViewModel ends the plan at 516 lines, well under the 624-line ceiling, because the mapping section moved to ChatItemMapper"

patterns-established:
  - "Reducer owns every list merge: forceLoad uses mergePage, handleMessageNew uses onIncoming; no path assigns a server page wholesale"
  - "handleMessageRead stays byte-identical to the phase base 16fe88e (D-17); guard re-checked at the end of this plan"

requirements-completed: [CHAT-01]

coverage:
  - id: D1
    description: "Tapping Send appends an own bubble in Sending state before the POST completes, clears the composer, bumps scrollToBottomToken; the 201 ack updates the same bubble (same id, server id, time, sent)"
    requirement: CHAT-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift#send appends a pending bubble at once, then the ack updates that same bubble"
        status: pass
    human_judgment: false
  - id: D2
    description: "A 5xx or transport failure keeps the bubble in place as Failed with no alert; a 4xx removes it, restores the text ahead of the draft and shows the server message"
    requirement: CHAT-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift#a 500 keeps the bubble in place as failed, with no alert"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift#a 422 removes the bubble, restores the text and shows the server's reason"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift#a refused send puts its text ahead of what was typed since, on its own line"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reload, load and live events merge through the reducer: pending and failed bubbles survive, nothing is shown twice, an own Read row never reverts"
    requirement: CHAT-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatThreadReducerTests.swift (21 cases)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift#a reload without a failed bubble keeps it, after the server rows"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift#a live message for another thread, from me, or already shown adds no row"
        status: pass
    human_judgment: false
  - id: D4
    description: "Pending and Failed bubble visuals: Sending... in place of the time, 40% fill, error border, destructive glyph, Not sent. Tap to retry; no layout jump or text re-wrap"
    requirement: CHAT-01
    verification: []
    human_judgment: true
    rationale: "Visual rendering, animation and contrast on a real iPhone (device check C1, first half); no snapshot or UI test asserts it"
  - id: D5
    description: "Send bookkeeping lives in ChatSendCoordinator and the mapping in ChatItemMapper; ChattingViewModel is at or under 624 lines; handleMessageRead is byte-identical to the phase base"
    requirement: CHAT-01
    verification:
      - kind: other
        ref: "Task 3 verify: wc -l ChattingViewModel.swift = 516 (<= 624); cmp of handleMessageRead extract against 16fe88e"
        status: pass
    human_judgment: false

# Metrics
duration: 18min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 01: Optimistic chat send and the thread reducer Summary

**Optimistic chat send with a Sending/Failed bubble that keeps its identity through ack and reload, backed by an Android-ported ChatThreadReducer, a ChatSendCoordinator for sends in flight, and a ChatItemMapper lifted out of the view model**

## Performance

- **Duration:** 18 min
- **Started:** 2026-11-18T04:48:07Z
- **Completed:** 2026-11-18T05:07:05Z (before the docs commit)
- **Tasks:** 3 (plus a RED test commit for Task 1)
- **Files modified:** 9 (6 created, 3 modified)

## Accomplishments

- Tapping Send now appends an own bubble in the Sending state at once, clears the composer and scrolls, before `POST /chats/:id/send` answers. The composer is never disabled and shows no spinner; nothing sets the old `isSending` flag any more.
- The 201 ack updates that same bubble in place (same `ChatMessage.id`, server id, server time, `.sent`). A network error, 5xx, decode failure or invalid response leaves the bubble where it was, Failed, with no alert. Any other 4xx removes the bubble, puts the text back ahead of anything typed since, and shows the shipped alert (D-03 first half; THREAD_BLOCKED and RECIPIENT_UNAVAILABLE take this path until plan 07-04).
- `ChatThreadReducer` ports Android `ThreadReducer.kt` (no `markRead`, per D-17). `forceLoad()` now merges the page instead of replacing the list, and `handleMessageNew` goes through `onIncoming`, so a reload can no longer delete a pending or failed bubble and a live event can no longer duplicate a row. Booking-event rows now carry their server id and created time, so an overlapping page cannot duplicate them.
- `ChatSendCoordinator` owns every send in flight (one `Task` per `client_msg_id`; a duplicate id makes no request) and `ChatItemMapper` owns the server-row mapping, so `ChattingViewModel.swift` went from 624 to 516 lines.
- 34 new tests pass: 21 reducer cases (Android port plus iOS-only rows) and 13 stubbed view-model cases.

## Task Commits

1. **Task 1: Tracer, optimistic send** - RED `0aaef6e` (test), GREEN `6b48181` (feat)
2. **Task 2: Sending/Failed bubble and ChatItemMapper** - `f4cb380` (feat)
3. **Task 3: Full reducer port, merge on reload and live events** - `afd3c31` (feat)

**Plan metadata:** recorded in the docs commit that follows this file.

## TDD Gate Compliance

- **RED** (`0aaef6e`): the nine send tests plus compile seams only (model fields, a no-op `ChatSendCoordinator`, view model identity parameters and `awaitInFlightSends`); `sendMessage()` still waited for the ack. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`, 9 tests, 3 pass, 6 fail). Target test: "send appends a pending bubble at once, then the ack updates that same bubble". Semantic assessment: the target ran and failed on the planned assertions (`sendState` was `.sent` not `.sending`, `clientMsgId` nil, `serverId` already set because the bubble was only appended after the ack), not on a build, fixture or discovery fault.
- **GREEN** (`6b48181`): reducer subset, coordinator and view model wiring; all 9 tests pass.
- **REFACTOR:** none needed.
- Task 3 (marked `tdd="true"`) did not get a separate failing-test commit: its reducer functions were written before its tests, so there is no RED commit for it. As a substitute I ran a mutation check: reverting `forceLoad()` to the old wholesale assignment made the reload tests fail (Pitfall 1 shape), and restoring it made them pass again (restored file compared byte for byte).

## Files Created/Modified

- `ClickMe2026/Model/UIModels/ChatDisplayModels.swift` - `ChatSendState`; assignable `id`, `clientMsgId`, `sendState`, `var timestamp` on `ChatMessage`; `BookingEvent` assignable `id`, `serverId`, `createdAt`; `ChatItem.serverId` and `orderDate`
- `ClickMe2026/Utils/ChatThreadReducer.swift` - pure list rules and send-failure classification
- `ClickMe2026/Views/Screens/Chat/Chatting/ChatSendCoordinator.swift` - sends in flight, the POST, outcome classification, `restoredText`
- `ClickMe2026/Utils/ChatItemMapper.swift` - mapping moved from the view model, plus `client_msg_id` and event id and time
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift` - optimistic `sendMessage`, `startSend`, `applySendOutcome`, `awaitInFlightSends`, merge on reload, reducer-backed `handleMessageNew` (now internal); mapping section removed
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift` - Sending and Failed rendering and the pending VoiceOver label
- `ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift`, `ClickMe2026Tests/Chat/ChatThreadReducerTests.swift`, `ClickMe2026Tests/Support/ChatFixtures.swift` - new suites and fixtures

## Decisions Made

- 4xx is a refusal and everything else stays Failed, mirroring Android's `SERVER_ERROR_FROM = 500` split, as the plan specified. This also treats 408 and 429 as refusals; no decision asks otherwise.
- The failed glyph is laid out as an overlay (see deviation 1).
- Ack tests give the two sends distinct server times. Two acks with an identical server time that arrive in reverse order leave the rows in ack order (the stable sort keeps the order they had when sorted); real server timestamps differ, so this only shows with synthetic equal times.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Failed glyph laid out as an overlay, not an HStack sibling**
- **Found during:** Task 2 (bubble)
- **Issue:** The plan wraps the glyph and the text bubble in an `HStack`. The bubble carries `.frame(maxWidth: 260, alignment:)`, which fills up to 260 pt when space allows, so an HStack sibling would sit away from short bubbles, and the 28 pt it adds inside the width budget would make long text wrap differently in Failed than in Sending.
- **Fix:** `.overlay(alignment: .leading)` on the bubble with `.offset(x: -28)` (20 pt glyph plus 8 pt gap), before the frame. Visual result matches UI-SPEC section 1 (20 pt, 8 pt before the bubble, centred on the bubble only); the sender label and status line are untouched.
- **Files modified:** `ChattingMessageBubble.swift`
- **Verification:** build passes and all Task 2 grep gates pass; not seen on a device (human check C1 below).
- **Committed in:** `f4cb380`

**2. [Rule 1 - Bug] Test fixture used identical ack times for two sends**
- **Found during:** Task 2 (rerun of the Task 1 suite)
- **Issue:** The "two sends" test acked both messages with the same server time; when the acks landed in reverse order the rows ended as `["b", "a"]`. Test artifact, not a reducer bug.
- **Fix:** The ack responder adds one second for text "b", so server times follow send order. Ran the suite three times in a row, all green.
- **Files modified:** `ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift` (committed with Task 3, which owns that file)
- **Committed in:** `afd3c31`

### Process deviations (not code)

- **RED commit scope:** the plan describes one `feat` commit per task. To get a valid RED (the tests must compile before they can fail on an assertion), the RED commit `0aaef6e` carries the model fields, a no-op coordinator and the view model seam alongside the test file. The Task 1 GREEN commit `6b48181` therefore lists three files (reducer, coordinator, view model), and the two other Task 1 files were already in the RED commit. All five Task 1 files are covered across the two commits.
- **Task 3 TDD order:** see TDD Gate Compliance.

---

**Total deviations:** 2 auto-fixed (2 Rule 1) plus 2 process notes
**Impact on plan:** No scope creep. Deviation 1 is a layout mechanism change for the stated UI-SPEC result; it needs the device check.

## Issues Encountered

- `ClickMe2026/Localizable.xcstrings` was already modified in the working tree before this plan and was not staged. The new literals `Sending…` and `Not sent. Tap to retry` are not in the string catalog; they render from the source text (English). Add them when the catalog is next committed.
- `ChattingViewModel.isSending` stays as a dead published property, as planned; plan 07-02 Task 2 deletes it with the spinner and the `ChattingInputBar` parameter.
- The tracer gate: mode `end-of-phase` and an automated-only `<verify>` for Task 1, so no checkpoint was raised. The three Task 1 checks were green on the tree that was committed. Tracer verified end-to-end, expanding.

## Verification Results

- `ChattingViewModelSendTests` 13 tests passed; `ChatThreadReducerTests` 21 tests passed.
- Build succeeded; warning set for the plan's files is empty, equal to the baseline (0 warnings before, 0 after); no new warnings in the new test files.
- Grep gates: no logging call, persistence API or `try?` on the send path; no `sendChatMessage` call or in-flight dictionary in the view model; no `!isSending` guard.
- D-17 guard: the `handleMessageRead` extract (13 lines) is byte-identical to the phase base `16fe88e`.
- Size rule: `ChattingViewModel.swift` is 516 lines (ceiling 624).
- Not run: the device check C1 (first half) and the Android and backend sides (none needed; no backend or Android change in this plan).

## Known Stubs

None. The unused `isSending` property is scheduled for deletion in plan 07-02 and renders nothing.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 07-02: `startSend` is the retry entry point, `ChatThreadReducer.retry` exists, `ChatSendCoordinator.restoredText` is ready for the composer cap, and `ChatFixtures` is in place.
- Human check still open: device check C1 (first half): send with the network on, then in airplane mode; confirm Sending... then the time with no jump, and a dimmed, readable, bordered bubble with the red glyph and `Not sent. Tap to retry`, no alert, keyboard stays up.

## Self-Check: PASSED

All seven created files exist on disk and the four commits (`0aaef6e`, `6b48181`, `f4cb380`, `afd3c31`) are ancestors of HEAD.

---
*Phase: 07-chat*
*Completed: 2026-11-18*
