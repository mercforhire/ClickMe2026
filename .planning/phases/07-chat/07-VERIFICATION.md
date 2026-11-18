---
phase: 07-chat
verified: 2026-11-18T17:00:00Z
status: human_needed
score: 5/5 must-haves verified
covered_files:
  - .planning/phases/07-chat/07-01-PLAN.md
  - .planning/phases/07-chat/07-01-SUMMARY.md
  - .planning/phases/07-chat/07-02-PLAN.md
  - .planning/phases/07-chat/07-02-SUMMARY.md
  - .planning/phases/07-chat/07-03-PLAN.md
  - .planning/phases/07-chat/07-03-SUMMARY.md
  - .planning/phases/07-chat/07-04-PLAN.md
  - .planning/phases/07-chat/07-04-SUMMARY.md
  - .planning/phases/07-chat/07-05-PLAN.md
  - .planning/phases/07-chat/07-05-SUMMARY.md
  - .planning/phases/07-chat/07-06-PLAN.md
  - .planning/phases/07-chat/07-06-SUMMARY.md
  - .planning/phases/07-chat/07-07-PLAN.md
  - .planning/phases/07-chat/07-07-SUMMARY.md
  - .planning/phases/07-chat/07-08-PLAN.md
  - .planning/phases/07-chat/07-08-SUMMARY.md
  - .planning/phases/07-chat/07-09-PLAN.md
  - .planning/phases/07-chat/07-09-SUMMARY.md
  - ClickMe2026/Managers/ChatPresence.swift
  - ClickMe2026/Model/Responses/Children/ChatThreadItem.swift
  - ClickMe2026/Realtime/RealtimeService.swift
  - ClickMe2026/Utils/ChatBlockState.swift
  - ClickMe2026/Utils/ChatBookingRowRoute.swift
  - ClickMe2026/Utils/ChatComposerRules.swift
  - ClickMe2026/Utils/ChatItemMapper.swift
  - ClickMe2026/Utils/ChatThreadLookup.swift
  - ClickMe2026/Utils/ChatThreadReducer.swift
  - ClickMe2026/Utils/ChatUnreadRules.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChatSendCoordinator.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/Subviews/ChatConversationRow.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileBlockViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift
covered_digest: "v3:sha256:4fffda7f6f38589ba72ac0d459d012d599eba62d8c7de04e8a4ef980bf95c30d"
behavior_unverified: 0
overrides_applied: 0
coincidental_reliance_items: []
human_verification:
  - test: "Item 1 and 2 (07-DEVICE-UAT-CHECKLIST.md): on a real iPhone, send with the network on, then with airplane mode on; turn the network back on, tap the Failed bubble, long-press another and choose Delete; close and reopen the thread."
    expected: "First bubble shows Sending then the time, no second bubble. Offline bubble stays as Failed with the glyph and 'Not sent. Tap to retry', no alert, keyboard stays up. Retry delivers exactly once to the second phone. Delete removes the bubble with no prompt and the second phone never gets it. No Failed bubble survives a reopen."
    why_human: "Real network loss, keyboard focus and exactly-once delivery to a second device cannot be seen from stubbed URLProtocol tests."
  - test: "Items 3 to 9 (checklist): composer counter and cap on a real keyboard; blocked banner on both sides with two accounts; Block & Report card states; profile Block confirm alert, scrim and toast over the tab bar; foreground and push entry routes."
    expected: "Counter rides above the keyboard and VoiceOver reads 'n of 10,000 characters' at the cap. The blocker sees Unblock in banner, menu and card; the blocked side sees 'You can't reply to this conversation' with no Unblock anywhere. Profile Block asks first, shows 'They won't be able to message you.', then a toast that is not hidden by the tab bar."
    why_human: "Two-account block state, keyboard layout, toast placement and VoiceOver output need hardware (UI-SPEC C2 to C5, C7, C8; backstops D2, D4, D5, OV2)."
  - test: "Items 10 and 11 (checklist), CHAT-07 and CHAT-08: with two accounts, send to an account whose thread is closed, then open it. Also keep a chat open on both phones and send from one."
    expected: "The unread pill appears live with the right count (99+ above 99), clears when the thread is opened by any route, and the sender's bubble flips to 'Read' live while both chats are open."
    why_human: "End-to-end socket delivery and the backend recount cannot be exercised without two live sessions. CHAT-08 was closed as not reproducible on a device on 2026-11-17, and plan 07-03 later changed when the receiving side emits message.read, so the regression row in item 11 should be run on the final build."
  - test: "Items 12 to 14 (checklist): VoiceOver pass over the failed bubble, banner and unread row; largest Dynamic Type; expert taps a chat booking row (App Store build 6 before, current build after)."
    expected: "Retry sending and Delete message actions are offered on a Failed bubble; text wraps without truncation and the banner stacks at accessibility sizes; the expert booking row opens the expert Booking Summary with no load error."
    why_human: "Accessibility output, Dynamic Type layout and the D-18 route on a real expert account are device-only."
  - test: "Items 15 to 18 (checklist): the three KEEP or CHANGE judgements (120 s Sending on a dead network, a count reappearing after a very quick pop, toast height) and the filled-state sweep."
    expected: "A KEEP or CHANGE answer for each, and the sweep shows no visual regressions."
    why_human: "Design judgement by the product owner."
---

# Phase 7: Chat Verification Report

**Phase Goal:** Chat is reliable and clear: messages appear immediately and can be retried, block state is obvious to both sides, and unread and read state is visible
**Verified:** 2026-11-18T17:00:00Z
**Status:** human_needed
**Re-verification:** No, initial verification

## Goal Achievement

All five ROADMAP success criteria hold in the code, and a fresh test run of the Phase 7 suites passes. I found no failed truth, missing artifact or unwired link. Status is `human_needed` rather than `passed` because the device checks the user deferred to end-of-phase UAT are all still unrun (all 18 `Result:` lines in `07-DEVICE-UAT-CHECKLIST.md` are blank), and four open review warnings are untriaged. I ranked none of the warnings as a blocker.

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A sent message appears at once as pending, shows a failed state on error, and can be retried; loading earlier never duplicates; typing and View Profile work as soon as a chat opens | VERIFIED | `ChattingViewModel.sendMessage()` appends via `ChatThreadReducer.appendLocal` before any suspension, then `startSend` hands the POST to `ChatSendCoordinator` (`ChattingViewModel.swift:338-376`). `applySendOutcome` acks in place, marks Failed on URLError/5xx, and on a 4xx removes the bubble and restores the text. `retrySend` reuses the stored `client_msg_id` and is gated on `!isInFlight` (`:427-435`). `ChattingMessageBubble` renders Sending, Failed and the tap and long-press Delete. `loadEarlier` and `forceLoad` both merge through `ChatThreadReducer.mergePage` (`:201`, `:270`), which matches by server id, then client_msg_id. `ChatThreadLookup.find` sets `peerUserId` from `partner.id` on open (`:313-322`). Covered by `ChatThreadReducerTests`, `ChattingViewModelSendTests`, `ChattingViewModelOpenTests`; all pass in my run. |
| 2 | A blocked thread hides the composer and says who blocked it; only the blocker sees Unblock; profile Block uses a confirm dialog whose copy matches reality | VERIFIED | `ChattingView.composerSlot` swaps `ChattingInputBar` for `ChattingBlockedBanner` when `composerMode != .normal`. The banner shows the Unblock button only for `.blockedByMe` (`ChattingBlockedBanner.swift:66`). `ChatBlockState.showsUnblock = isBlocked && blockedByMe`, and `ChatThreadItem.blockedByMe` decodes missing or null as false (D-08), so a legacy block reads as blocked by the peer. The menu, banner and card all key off the same state (`menuEntry`, `ReportChatBlockCard.shouldShowButton`). `ExpertProfileView` shows an alert "Block {name}?" with "They won't be able to message you.", and nothing is sent until Block is tapped (`ExpertProfileBlockViewModel.block` runs initiate then block, once). The card copy says blocking only stops new messages in this conversation. Covered by `ChatBlockStateTests`, `ChatThreadItemDecodingTests`, `ProfileBlockActionTests`, `ReportChatViewModelTests`. Caveats: WR-01 and WR-02 below. |
| 3 | Conversation rows show an unread badge that clears once the thread is read | VERIFIED (iOS side and backend recount) | `ChatConversationRow` renders a capsule from `ChatUnreadRules.badgeLabel` (hidden at 0, `99+` above 99) with a bold preview. `ChatConversationsViewModel.handleMessageNew` adds 1 for a peer message on a closed thread, and `markOpened` zeroes a row when `ChatPresence.visibleThreadId` changes. `ChattingViewModel.emitPendingReads` emits `message.read` for loaded unread peer ids only, on every page, held until the socket connects. The backend recomputes `unread_count_*` on send and on message.read (`src/services/unreadCounts.js`, BACK-18) and `GET /chats` returns the caller-side count and lists empty threads. Covered by `ChatConversationsUnreadTests`, `ChatUnreadRulesTests`, `ChattingViewModelReadEmitTests`. Live two-account behavior is in the human list. |
| 4 | Reports from chat reach the backend as report-reason enum values | VERIFIED | `ReportChatViewModel.submitReport` sends `selected.rawValue` through `chatAction(action: "report", reason:details:)`. The six `UserReportReason` raw values match the backend `moderation.schema.js` list. Details are capped at 1,000 UTF-16 units and trimmed. `ReportChatViewModelTests` passes. |
| 5 | The "Read" label updates live while a chat is open, or CHAT-08 is closed as not reproducible after the device re-test | VERIFIED (closed as not reproducible) | `07-CONTEXT` D-17 records the user's device re-test after Phase 1 shipped (Q8). I diffed `handleMessageRead` against the phase base `16fe88e` and the 13-line extract is identical. The `REQUIREMENTS.md` CHAT-08 line records the closure and names the two Phase 7 changes next to that path. The checkbox is intentionally still unchecked; the orchestrator left it for `/gsd-verify-work 07`. A regression row for the two-device Read label is in checklist item 11. |

**Score:** 5/5 roadmap truths verified (0 present, behavior-unverified)

Plan-level truths from all nine `must_haves` blocks were also spot-checked against code, not only SUMMARY text:
- Send, retry and merge rules: `ChatThreadReducer` read in full, including `ack` (collapses into a reload-added row and never regresses Read), `order` (stable sort, local rows last), and `sendFailure` (4xx refused, everything else kept as failed).
- Composer cap: `ChatComposerRules` counts UTF-16 units, with the counter from 9,000.
- D-18 route: `ChatBookingRowRoute.route` is wired in `ChattingView.openBookingDetail` through `hostsClientBookingFlows`.
- Size ceiling: `ChattingViewModel.swift` is 624 lines, equal to the base.
- Prohibitions: no `print`, `NSLog` or `os_log` in the chat surfaces; no `try?` on any chat write (only the three pre-existing read-side uses); no `UserDefaults`, `FileManager` or Valet in the send path. Failed bubbles live only in `items`. Unblock is gated by `blockedByMe` in every surface.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Utils/ChatThreadReducer.swift` | Pure thread rules | VERIFIED | 268 lines, wired from the view model (`appendLocal`, `ack`, `fail`, `retry`, `remove`, `mergePage`, `onIncoming`, `unreadPeerIds`) |
| `Views/.../ChatSendCoordinator.swift` | In-flight send ownership | VERIFIED | One task per `client_msg_id`; `send` is a no-op for an id already in flight |
| `Utils/ChatItemMapper.swift` | Row mapping moved out of the VM | VERIFIED | Used by `ChattingViewModel.mapToChatItem` |
| `Utils/ChatComposerRules.swift` | Cap and counter | VERIFIED | Used by `updateMessageText` |
| `Utils/ChatThreadLookup.swift` | Bounded `GET /chats` scan | VERIFIED | Limit 100, up to 3 pages; used by the thread view model and Report & Block |
| `Utils/ChatBlockState.swift` | Block matrix and Session | VERIFIED | Used by the thread view model, `ReportChatViewModel` and the banner |
| `ChattingBlockedBanner.swift` | Banner replacing the composer | VERIFIED | Rendered by `ChattingView.composerSlot` |
| `ExpertProfileBlockViewModel.swift` | Initiate then block | VERIFIED | Wired in `ExpertProfileView` alert |
| `Utils/ChatUnreadRules.swift` | Pill and label rules | VERIFIED | Used by the row and the list view model |
| `Utils/ChatBookingRowRoute.swift` | Shell-aware route | VERIFIED | Wired in `ChattingView` |
| `RealtimeService.isConnected`, `onConnect` | Connection-held read receipts | VERIFIED | Used by `attachRealtime` and `emitPendingReads` |
| 12 test files under `ClickMe2026Tests/Chat/` | Behavioral coverage | VERIFIED | All run in my invocation |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `sendMessage` | `ChatSendCoordinator.send` then `sendChatMessage` with `clientMsgId` | `startSend` | WIRED | Same id stored on the bubble and sent in the POST |
| Outcome | `ChatThreadReducer.ack/fail/remove` | `applySendOutcome` | WIRED | Bubble id preserved through ack |
| `forceLoad` / `loadEarlier` | `mergePage` | direct | WIRED | No `insert(contentsOf` remains |
| `forceLoad` / `viewDidAppear` | `ChatThreadLookup.find` | `refreshThreadInfo` | WIRED | Sets `peerUserId` and block flags |
| Send refusal 403 | banner | `blockSession.applySendRefusal` then rescan | WIRED | |
| Block & Report outcome | thread | `onBlockStateChange` to `adoptBlockState` | WIRED | `ChattingView.navigationDestination` |
| `ChatPresence.visibleThreadId` | list `markOpened` / `silentReload` | `.onChange` | WIRED | `ChatPresence` is `@Observable` |
| Socket `message.new` | list `+1` | `handleMessageNew` with guards | WIRED | |
| `ReportChatViewModel.submitReport` | `chatAction(... reason: rawValue)` | direct | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `ChatConversationRow` pill | `chat.unreadCount` | `GET /chats` `unread_count` (backend recount) plus local +1 and zero | Yes | FLOWING |
| `ChattingBlockedBanner` | `composerMode` | `GET /chats` `is_blocked` and `blocked_by_me`, send refusal, Block & Report hand-back | Yes | FLOWING |
| Message bubbles | `items` | `GET /chats/:id/messages` merged with local sends and socket events | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 7 suites plus `PushForegroundPolicyTests` | `xcodebuild test ... -only-testing` on 13 suites, simulator iPhone 17 | `Test run with 181 tests in 13 suites passed`, `** TEST SUCCEEDED **` | PASS |
| `handleMessageRead` unchanged since phase base | extract at `16fe88e` vs HEAD, `diff` | identical | PASS |
| View model size ceiling | `wc -l ChattingViewModel.swift` | 624 (base 624) | PASS |
| App and test code unchanged since the last code commit | `git diff 491b600 HEAD -- ClickMe2026 ClickMe2026Tests` | empty | PASS |

I did not run the full 1172-test suite. I relied on the 07-09 report for it, because the code is byte-identical to that commit, and ran only the Phase 7 suites.

### Probe Execution

Step 7c: SKIPPED. The phase declares no probe scripts.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CHAT-01 | 07-01, 07-02 | Pending, failed, retry | SATISFIED | Truth 1; device items 1 and 2 pending |
| CHAT-02 | 07-05 | Report sends enum values | SATISFIED | Truth 4 |
| CHAT-03 | 07-04, 07-05, 07-06 | Blocked thread banner; Unblock to blocker only | SATISFIED | Truth 2; device items 6 and 7 pending |
| CHAT-04 | 07-05, 07-06 | Profile Block confirm dialog; truthful copy | SATISFIED | Truth 2; device item 8 pending |
| CHAT-05 | 07-03 | Typing and View Profile on open | SATISFIED | `ChatThreadLookup` plus `ChattingViewModelOpenTests` |
| CHAT-06 | 07-03 | No duplicates on Load earlier | SATISFIED | `mergePage` in `loadEarlier` plus tests |
| CHAT-07 | 07-03, 07-07 | Unread badge | SATISFIED | Truth 3; device items 10 and 11 pending |
| CHAT-08 | 07-01, 07-03 (guard only) | Live Read label | SATISFIED (closed as not reproducible) | Truth 5; the box in `REQUIREMENTS.md` is still unticked |

All eight IDs appear in plan frontmatter and in `REQUIREMENTS.md`. No orphaned requirements: CHAT-09 maps to Phase 2 and is already ticked. The `REQUIREMENTS.md` traceability table still shows CHAT-01 to CHAT-08 as Pending; that is a bookkeeping update for the orchestrator after sign-off.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ChattingViewModel.swift` / `ChatBlockState.swift` | 313-322 / 172 | A stale `GET /chats` scan can overwrite a block or unblock that finished while it was running; `sessionBlockedByMe` is not reset by a scan that reports a peer block (review WR-01, confirmed in code) | Warning | Banner or composer can briefly show the wrong state until the next scan. Needs an unblock tap during an in-flight scan, so the window is narrow. |
| `ChatBlockState.swift` | 159, 186 | `recipientUnavailable` is never cleared (WR-02, confirmed) | Warning | After a RECIPIENT_UNAVAILABLE refusal the composer stays replaced until the thread is reopened. |
| `RealtimeService.swift` | 93 | `.log(true)` is on in Release (WR-03; the line is pre-existing, not in the Phase 7 diff) | Warning | Socket traffic, including message text, reaches the device log. Outside the CHAT requirements but against the project's logging rule. |
| `ChatConversationsViewModel.swift` | 114-124, 148-173 | `silentReload` can restore a server count over a local `markOpened`, and early `message.new` events trigger duplicate loads (WR-04) | Warning | Pill can reappear briefly for the thread on screen. |
| `ExpertProfileView.swift` | 454 | `TODO` comment | Info | Pre-existing (blame 2026-07-29), not a debt marker (`TBD/FIXME/XXX`). No debt markers in Phase 7 files. |

`07-REVIEW-DISPOSITION.md` shows all nine findings (4 warnings, 5 info) as `open`. None blocks a must-have truth. They need a triage decision (fix, defer or skip) before Phase 8 release.

### Human Verification Required

#### 1. Retry, failed bubble and Delete on a real network failure (CHAT-01, items 1 and 2)

**Test:** Send with the network on, then in airplane mode; restore the network, tap the Failed bubble, long-press another and choose Delete; reopen the thread.
**Expected:** Sending then time; Failed bubble with no alert and the keyboard still up; Retry delivers exactly once to phone 2; Delete needs no prompt; no Failed bubble after reopening.
**Why human:** Real connectivity loss and exactly-once delivery to a second device.

#### 2. Block state on both sides (CHAT-03, CHAT-04, items 3 to 9)

**Test:** Two accounts: block from the thread card and from the expert profile, then view the thread on both sides, the menu and the card; check the counter and cap on a real keyboard.
**Expected:** Only the blocker sees Unblock anywhere; the blocked side reads "You can't reply to this conversation"; profile Block asks first and the toast clears the tab bar; the counter rides above the keyboard.
**Why human:** Needs two real accounts, a keyboard, a toast over the tab bar and VoiceOver.

#### 3. Live unread pill and Read label (CHAT-07, CHAT-08, items 10 and 11)

**Test:** Send to a closed thread, open it from several routes, then chat with both phones open.
**Expected:** Pill appears and clears live with the right count; the sender sees "Read" live.
**Why human:** Socket delivery plus backend recount across two sessions. Plan 07-03 changed when read receipts are emitted after the CHAT-08 device re-test, so the regression row should be run on the final build.

#### 4. Accessibility, Dynamic Type and expert booking row (items 12 to 14)

**Test:** VoiceOver and largest text sizes over the new states; an expert taps a chat booking row.
**Expected:** Custom actions Retry sending and Delete message; no truncation, banner stacks; expert Booking Summary opens with no load error.
**Why human:** Device-only.

#### 5. Product judgements (items 15 to 18)

**Test:** KEEP or CHANGE on the 120 s Sending case, the quick-pop count, the toast height; then the filled-state sweep.
**Expected:** A recorded answer for each.
**Why human:** Design judgement.

### Gaps Summary

There are no gaps. Every ROADMAP criterion and every plan must-have I checked is present, substantive, wired and backed by a passing test. Three things keep this from `passed`:

1. The 18 device checks are unrun. They were deferred by design (`human_verify_mode = end-of-phase`), and they cover things the simulator cannot show: a real dead network, two-account block and unread flows, VoiceOver and Dynamic Type.
2. WR-01 and WR-02 are real stale-state defects in the block flow, confirmed against the code. They are edge cases and not goal failures, but they weaken "block state is obvious" under a race or a reinstated recipient, so I recommend fixing them before the Phase 8 build.
3. The `REQUIREMENTS.md` checkboxes and traceability rows for CHAT-01 to CHAT-08 are still open. They should be updated after the UAT results are recorded.

---

_Verified: 2026-11-18T17:00:00Z_
_Verifier: Claude (gsd-verifier)_
