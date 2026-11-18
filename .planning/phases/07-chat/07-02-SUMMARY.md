---
phase: 07-chat
plan: 02
subsystem: chat
tags: [swiftui, swift-testing, retry, client_msg_id, composer-cap, utf16, voiceover, tdd]

# Dependency graph
requires:
  - phase: 07-chat
    provides: "07-01 optimistic send: ChatThreadReducer (retry, remove, findMine), ChatSendCoordinator (isInFlight, send, restoredText), Failed bubble visuals"
provides:
  - "Tap a Failed bubble to resend it with its original client_msg_id; long-press Delete (no confirmation, no request); VoiceOver Retry sending and Delete message actions"
  - "ChatComposerRules: 10,000 UTF-16 cap, 9,000 counter threshold, counter and VoiceOver text, crossedLimit announcement rule"
  - "Composer capped on type, paste and refused-send restore; counter row above the keyboard; the composer no longer locks while sending"
affects: [07-03, 07-04, 07-05, 07-08]

# Actuals (#2632) - chars/4 over the realized diff (git diff 60bbf09..HEAD, 33,192 chars)
actuals:
  tokens: 8298
  tasks: 2
  commits: 4
plan_head_before: 60bbf09bd368da5b952e4f1e23a6249fba368262
plan_head_after: 9bf42384a3f6acc9ec1d8dff8c9b4bd1d653c4bd

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Retry goes view model -> reducer.retry -> coordinator.send with the stored client_msg_id; the view model keeps no in-flight state and asks the coordinator"
    - "Pure composer rules in a nonisolated enum (like UTF16Prefix); the view model funnels every composer write through updateMessageText"
    - "A Failed bubble is one Button group (text bubble plus status line) so tap, context menu and VoiceOver all attach to one element"

key-files:
  created:
    - ClickMe2026/Utils/ChatComposerRules.swift
    - ClickMe2026Tests/Chat/ChatComposerRulesTests.swift
  modified:
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift
    - ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift

key-decisions:
  - "A retry never starts while the bubble's send is in flight (sendCoordinator.isInFlight) and always reuses the stored client_msg_id, so a double tap or a send that did reach the server cannot deliver twice (T-07-05)"
  - "Text a refused send puts back in the composer goes through ChatComposerRules.cap via updateMessageText, so the composer never holds more than 10,000 units (D-03, D-04)"
  - "Counter reserves no space below 9,000 and is hidden from VoiceOver until the cap; the one-time announcement fires on the edit that crosses the limit, not per keystroke"
  - "ChattingMessageBubble is split into textBubble / statusLine / failedGroup so the Failed group can be one Button with a 44 pt hit area while Pending and Sent bubbles stay non-interactive"

patterns-established:
  - "Failed bubbles are memory only (D-02): nothing in this plan writes to disk or UserDefaults"
  - "Every composer length is text.utf16.count, never Character count"

requirements-completed: [CHAT-01]

coverage:
  - id: D1
    description: "Tapping a Failed bubble resends it once with the same client_msg_id; the bubble keeps its id, goes back to Sending and becomes Sent on the ack; a second tap, a Sent bubble or an unknown id sends nothing; with two Failed bubbles only the tapped one is resent"
    requirement: CHAT-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift (retry, double retry, retry on sent/unknown, retryTargetsOnlyTheTappedBubble)"
        status: pass
    human_judgment: true
    rationale: "Delivery exactly once on the other phone and the tap feel need two iPhones; deferred to end-of-phase UAT (see Deferred human verification)"
  - id: D2
    description: "Long-press on a Failed bubble offers one destructive Delete (trash, no confirmation) that removes it locally with no request; pending and sent bubbles have no Delete; Failed bubble is one VoiceOver element with Retry sending and Delete message actions and a 44 pt hit area"
    requirement: CHAT-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift (deleteFailedMessage on .failed and on .sending)"
        status: pass
    human_judgment: true
    rationale: "Long-press menu, VoiceOver rotor actions and hit area are gestures and assistive tech that need hardware; deferred to end-of-phase UAT"
  - id: D3
    description: "The composer is capped at 10,000 UTF-16 units on type, paste and refused-send restore without splitting an emoji; counter {n} / 10,000 from 9,000, red at the cap; one 'Message length limit reached' announcement when the cap is first reached; Send message label"
    requirement: CHAT-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatComposerRulesTests.swift (11 tests: cap, emoji boundary, thresholds, counter text, VoiceOver label, crossedLimit, restoredText, whitespace)"
        status: pass
    human_judgment: true
    rationale: "Paste, keyboard layout and VoiceOver announcements need hardware; deferred to end-of-phase UAT"
  - id: D4
    description: "The dead isSending flag, its field disable, spinner and animation are gone from the view model, input bar and chat view; ChattingViewModel.swift is 550 lines (ceiling 624)"
    requirement: CHAT-01
    verification:
      - kind: other
        ref: "grep gate in 07-02-PLAN Task 2 (isSending count 0, wc -l <= 624) - GREP-GATE-PASS"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 02: Retry, Delete and the 10,000-unit Composer Cap Summary

**Failed chat bubbles retry with their original client_msg_id (one tap, never in flight twice) or delete on long-press, and the composer is capped at the server's 10,000 UTF-16 units with a counter from 9,000.**

## Performance

- **Duration:** about 20 min (first commit 00:11, last 00:27 local, plus the checkpoint pause)
- **Completed:** 2026-11-18
- **Tasks:** 2 (Task 1 tracer, Task 2 auto TDD)
- **Files modified:** 7 (5 app, 2 test), 513 insertions and 84 deletions

## Accomplishments

- **Retry and delete (Task 1, tracer).** `ChattingViewModel.retrySend(clientMsgId:)` returns unless the bubble is `.failed` and not in flight, flips it to Sending through `ChatThreadReducer.retry` and resends the identical text and id through `ChatSendCoordinator`. `deleteFailedMessage(clientMsgId:)` removes a Failed, idle bubble locally with no request. Tests: two POSTs with the same `client_msg_id` and content, one bubble id, ends `.sent`; double retry records one extra POST; retry on a Sent or unknown bubble sends nothing; delete on `.sending` changes nothing; with two Failed bubbles only the tapped id is resent.
- **Failed bubble interactions.** One `Button` group with `.frame(minHeight: 44)`, a destructive trash Delete in the context menu, and one VoiceOver element labelled "{text}. Not sent." with hint "Retries sending" and custom actions "Retry sending" and "Delete message". Pending and Sent bubbles stay non-interactive.
- **Composer cap and counter (Task 2).** `ChatComposerRules` (limit 10,000, counter from 9,000, `cap` through `UTF16Prefix`, `counterText`, `accessibilityCounterLabel`, `crossedLimit`). `updateMessageText(_:)` is the single composer write path: the chat view's capped `Binding` and the refused-send restore both use it. Counter sits inside the bar (rides above the keyboard), `.caption`, `ChattingBrand.onSurfaceVar`, `Brand.error` at the cap, no reserved space below 9,000.
- **Dead sending lock removed.** `isSending`, `.disabled(isSending)`, the spinner branch and the animation are deleted; the composer stays enabled while sends are in flight; the send button is labelled "Send message".

## Task Commits

1. **Task 1: Tracer - retry a Failed bubble with its client_msg_id; long-press Delete**
   - RED `2754819` (test) - failing retry and delete tests, compile seam only
   - GREEN `ac17a38` (feat) - retrySend, deleteFailedMessage, bubble restructure, view wiring
2. **Task 2: Composer cap, counter and removal of the sending lock**
   - RED `b2fa3e7` (test) - ChatComposerRulesTests (11 tests, all failing on assertions) with a stub `ChatComposerRules`
   - GREEN `9bf4238` (feat) - real rules, input bar counter and announcement, capped binding, `updateMessageText`, `isSending` removed

**Plan metadata:** the docs commit following this SUMMARY.

## Files Created/Modified

- `ClickMe2026/Utils/ChatComposerRules.swift` - pure cap, counter and announcement rules (new)
- `ClickMe2026Tests/Chat/ChatComposerRulesTests.swift` - 11 pure tests (new)
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift` - `retrySend`, `deleteFailedMessage`, `updateMessageText`; `isSending` removed; 550 lines
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` - passes `onRetry`/`onDelete`; capped composer `Binding`; no `isSending:` argument
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift` - split into `textBubble` / `statusLine` / `failedGroup`; Button, context menu, VoiceOver actions
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift` - `composerRow` plus counter, announcement, Send message label; spinner and disable removed
- `ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift` - retry and delete rows (19 tests in the suite)

## Decisions Made

See `key-decisions` in the frontmatter. In short: retry is guarded by the coordinator's in-flight check and reuses the stored id (no duplicate delivery); every composer write goes through the cap; the Failed bubble is one accessible Button group.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wrong expected order in `retryTargetsOnlyTheTappedBubble`**
- **Found during:** Task 1 (GREEN)
- **Issue:** The test asserted the two Failed bubbles in send order (a, b), but `ChatThreadReducer` orders server rows first and then unsent local bubbles, so the order is (b, a) after the retry settles.
- **Fix:** Corrected the assertion to (b, a). Reducer behavior was already specified and tested in 07-01; no production change.
- **Files modified:** ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift
- **Committed in:** ac17a38

### Plan-shape deviations (not defects)

**2. Task 2 committed as RED then GREEN instead of one commit.** The plan names one commit for the five Task 2 files; the TDD reference requires a RED test commit before implementation. The same five files were staged across `b2fa3e7` (tests plus a stub `ChatComposerRules` compile seam) and `9bf4238`. No other file was touched.

**3. Task 1 restructured `ChattingMessageBubble`.** Making the failed group one `Button` with a 44 pt hit area required splitting the bubble into `textBubble`, `statusLine` and `failedGroup`. The failed glyph overlay from 07-01 is unchanged in position but now sits outside the tap target (see observation (b) below).

---

**Total deviations:** 1 auto-fixed (Rule 1), 2 plan-shape notes.
**Impact on plan:** None on scope. No architectural change, no new endpoint, no file outside the plan's list.

## Deferred human verification

Per the user's decision ("Defer to UAT", `workflow.human_verify_mode = end-of-phase`), both `<human-check>` items below were NOT run in this plan and are carried to the end-of-phase UAT. Both are also recorded in `.planning/WINDOWS.md` as `unrun-verify`. The unit and build gates for both tasks passed; only hardware evidence is outstanding.

### H1. Task 1: retry, delete and VoiceOver on a Failed bubble (device checks C1 second half and C8)

**Setup:** two accounts on two iPhones, a thread between them; VoiceOver available on the sender.
**Steps:**
1. On the sender, turn airplane mode on and send two messages ("one", "two"). Both bubbles show Failed.
2. Turn the network back on. Tap the "one" bubble.
3. Long-press the "two" bubble and choose Delete.
4. Close the thread and reopen it.
5. Repeat step 1-2 with VoiceOver on, and use the rotor actions on a Failed bubble.

**Expected:**
- The tapped bubble goes to Sending... then Sent; the other phone receives "one" exactly once.
- Delete removes "two" at once with no prompt, and the other phone never receives it.
- After reopening, no Failed bubble remains (memory only, D-02).
- VoiceOver reads "{text}. Not sent.", the hint "Retries sending", and offers the actions "Retry sending" and "Delete message". Pending and Sent bubbles offer no such actions.
- The Failed group is comfortably tappable (at least 44 pt tall).

### H2. Task 2: paste cap, counter and announcement (device check C2 and the counter part of C8)

**Steps:** with the keyboard up, paste text longer than 10,000 characters (include emoji near the cut) into the composer. Turn VoiceOver on and type up to the cap. Tap Send at exactly 10,000.
**Expected:** the text stops at 10,000 units and no emoji is split; the counter shows from 9,000 as `{n} / 10,000` (grouped), turns red at 10,000 and stays above the keyboard; VoiceOver announces "Message length limit reached" once, not per key; the counter is silent to VoiceOver below the cap and reads "{n} of 10,000 characters" at the cap; Send still sends.

### Device-observation items to look at during H1

- **(a) Status animation.** Sending to Failed no longer crossfades the status line, because the Failed bubble is now a different `Button` view than the Sending bubble. Confirm the swap looks acceptable; if not, a follow-up should give both states a shared container with an explicit transition.
- **(b) Failed glyph outside the tap target.** The failed glyph overlay sits 28 pt left of the bubble and outside the `Button`, so tapping the glyph itself does nothing. Confirm that is acceptable or whether the glyph should be inside the hit area.

## Issues Encountered

- `gsd_run` is not defined as a shell function in this runtime; the `gsd-tools.cjs` entry point was invoked with `node` directly for the windows ledger and state updates.
- The RED run for Task 2 prints a very long failure line for the emoji-cap test (the 10,000-character string is in the failure message). Harmless, filtered when reading logs.

## Known Stubs

None. The RED stub of `ChatComposerRules` was replaced in `9bf4238`; no placeholder remains in the plan's files.

## Threat Flags

None. No new endpoint, auth path, file access or schema surface. T-07-04 (oversized message) and T-07-05 (duplicate retry delivery) are mitigated as planned and covered by tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 07-03 onward can rely on `ChatComposerRules` and `updateMessageText` as the only composer write path, and on `retrySend` for Failed bubbles.
- Plan 07-04 adds one more retry guard (retry ignored while a banner replaces the composer); `retrySend`'s guard list has room for it.
- Open: H1 and H2 device checks and observations (a) and (b) are owed to the end-of-phase UAT.

## Self-Check: PASSED

- Files exist: `ChatComposerRules.swift`, `ChatComposerRulesTests.swift` (both FOUND).
- Commits exist and are ancestors of HEAD: `2754819`, `ac17a38`, `b2fa3e7`, `9bf4238`.
- `ChatComposerRulesTests`: 11 tests in 1 suite passed. `ChattingViewModelSendTests`: 19 tests in 1 suite passed.
- Debug build succeeds; the warning diff against the empty baseline is empty (no new warnings in the plan's files).
- Task 2 grep gate passed: `isSending` count 0, view model 550 lines (at most 624), shipped 11 pt field padding and dark nav-bar pin intact.
- `commits: 4` measured from `git rev-list --count 60bbf09..HEAD`.

---
*Phase: 07-chat*
*Completed: 2026-11-18*
