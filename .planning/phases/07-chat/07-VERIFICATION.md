---
phase: 07-chat
verified: 2026-11-19T04:10:00Z
status: passed
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
  - ClickMe2026/Model/UIModels/ChatDisplayModels.swift
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
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingEmptyState.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsView.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/Subviews/ChatConversationRow.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatView.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatDescriptionField.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatReasonField.swift
  - ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatReportCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileBlockViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift
covered_digest: "v3:sha256:554efd9bfd63908b0841aa344ed64d74bb402be9ffd8ace906e9189a013cba7d"
behavior_unverified: 0
overrides_applied: 0
coincidental_reliance_items: []
deferred_follow_ups:
  - item: "VoiceOver pass: checklist item 12, the VoiceOver parts of items 3 and 4, and the IN-04 check that a delivered bubble is not read as pending"
    tracked_in: "ROADMAP backlog Phase 999.5"
    decided_by: "user, 2026-11-19 (UAT skipped at the user's request)"
  - item: "WR-02 device step (pull-to-refresh re-enables the composer for an unavailable recipient): no unavailable test account existed"
    tracked_in: "covered by unit tests (ChatBlockStateTests, ChattingViewModelOpenTests); no backlog entry"
---

# Phase 7: Chat Verification Report

**Phase Goal:** Chat is reliable and clear: messages appear immediately and can be retried, block state is obvious to both sides, and unread and read state is visible
**Verified:** 2026-11-19T04:10:00Z
**Status:** passed
**Re-verification:** Yes. This replaces the earlier `human_needed` report, which predates both rounds of code-review fixes (82050a4..aea7ecb) and the device UAT. Every truth was re-checked against the current code, not the previous report.

## Goal Achievement

All five ROADMAP success criteria hold in the current code. I re-read the changed files, re-ran the Phase 7 suites myself, and checked the review fixes against the source. The earlier report's open items are now closed or recorded:

- The 18 device checks have been run (`07-UAT.md` complete, 6/6 pass; every `Result:` line in the checklist is filled except item 12).
- The review warnings WR-01 to WR-06 are fixed in code (verified below).
- One review warning, WR-07, is still open. I judged it non-blocking (see Anti-Patterns).

Two things were never exercised on a device: the VoiceOver pass and the WR-02 recovery step. I did not count either as a blocker or as a pending human item. Reasons are in "Deferred, not gating" below. The user made both decisions and can reverse them.

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A sent message appears at once as pending, shows a failed state on error, and can be retried; loading earlier never duplicates; typing and View Profile work as soon as a chat opens | VERIFIED | `ChattingViewModel.sendMessage` appends via `ChatThreadReducer.appendLocal` (`:371`) before handing the POST to `startSend` (`:375`, `:380`). `retrySend(clientMsgId:)` (`:435`) reuses the stored id. `ChatThreadReducer.sendFailure` keeps the bubble as Failed for everything except a permanent 4xx, and since IN-01 also for 408 and 429 (`:43-62`). `loadEarlier` and `forceLoad` both go through `ChatThreadReducer.mergePage` (`:204`, `:273`). `peerUserId` is set from the thread lookup on open. Device: checklist items 1 and 2 PASS on a fresh build (500c9a1), including Retry delivering once and Delete needing no prompt. Unit: `ChattingViewModelSendTests`, `ChatThreadReducerTests`, `ChattingViewModelOpenTests` pass in my run. |
| 2 | A blocked thread hides the composer and says who blocked it; only the blocker sees Unblock; profile Block uses a confirm dialog whose copy matches reality | VERIFIED | `ChattingBlockedBanner` replaces the input bar and shows Unblock only for the blocker (`ChatBlockState.blockedByMe`; a legacy block with `blockedByMe` missing reads as blocked by the peer). `ExpertProfileView` raises a centred alert "Block {name}?" with "They won't be able to message you." and sends nothing until Block is tapped (`ExpertProfileBlockViewModel`). WR-01 is fixed: `refreshThreadInfo` captures `blockSession.revision` and drops the scan result if it changed (`ChattingViewModel.swift:321-325`; the revision bumps on every block, unblock and refusal in `ChatBlockState.Session`). WR-02 is fixed: `reload()` calls `blockSession.clearRecipientUnavailable()` (`:176`). Device: checklist items 3 to 9 PASS with two accounts. Unit: `ChatBlockStateTests`, `ProfileBlockActionTests`, `ReportChatViewModelTests` pass. |
| 3 | Conversation rows show an unread badge that clears once the thread is read | VERIFIED | `ChatConversationRow` renders the pill from `ChatUnreadRules.badgeLabel` (hidden at 0, `99+` above 99). `ChatConversationsViewModel.handleMessageNew` adds 1 only for a peer message on a thread that is not visible; `markOpened` zeroes the row locally. WR-04, WR-05 and WR-06 are fixed: `fetchChats` overlays local unread count, preview, time and ordering over a late reload, and a first message from an unknown thread during a load triggers one follow-up fetch (`needsReloadAfterLoad`, `:134-150`). The backend recount for send and read is Phase 1 work (BACK-18), unchanged here. Device: checklist items 10 and 11 PASS with two accounts, and UAT test 6 (the post-fix steps 1 to 3) PASS. Unit: `ChatConversationsUnreadTests`, `ChatUnreadRulesTests`, `ChattingViewModelReadEmitTests` pass. |
| 4 | Reports from chat reach the backend as report-reason enum values | VERIFIED | `ReportChatViewModel.submitReport` takes `selected.rawValue` from `UserReportReason` (`:151`) and passes it to `chatAction(action: "report", reason:details:)`. Details are trimmed and capped. `ReportChatViewModelTests` pass in my run. |
| 5 | The "Read" label updates live while a chat is open, or CHAT-08 is closed as not reproducible after the device re-test | VERIFIED (closed as not reproducible; regression row passed) | `07-CONTEXT` D-17 records the device re-test after Phase 1 (Q8). I extracted `handleMessageRead` at the phase base `16fe88e` and at HEAD: both are 13 lines and `diff` reports them identical. `REQUIREMENTS.md` carries the closure note. The two-device regression row on the final build (checklist item 11) is PASS. |

**Score:** 5/5 roadmap truths verified (0 present, behavior-unverified)

Plan-level truths from the nine `must_haves` blocks were spot-checked against code and not only against SUMMARY text. The send, retry, merge and ack rules in `ChatThreadReducer`, the composer cap in `ChatComposerRules`, the shell-aware booking-row route in `ChatBookingRowRoute` (D-18), and the connection-held read receipts in `ChattingViewModel.emitPendingReads` all exist, are substantive and are called from the view models. Prohibitions: no `TBD`, `FIXME` or `XXX` in any covered file; no `try?` on a chat write (the five remaining are two profile reads, two `Task.sleep` debounces and a view-side sleep, all pre-existing or read-only); Failed bubbles live only in `items`.

### Review-fix verification (code, not narration)

| Finding | Claimed | What I found |
|---------|---------|--------------|
| WR-01 stale scan overwrites block state | fixed | `Session.revision` exists (`ChatBlockState.swift:170`, bumped at `:200, :216, :230, :240`); `refreshThreadInfo` compares it before applying (`ChattingViewModel.swift:321-325`) |
| WR-02 `recipientUnavailable` never cleared | fixed | `clearRecipientUnavailable()` (`ChatBlockState.swift:209`), called from `reload()` (`ChattingViewModel.swift:176`) |
| WR-03 socket logging in Release | fixed | `RealtimeService.swift:92-101`: `socketLogging` is true only under `#if DEBUG` |
| WR-04 / WR-05 reload overwrites local unread, preview, order | fixed | `changesDuringReload`, `movedToTopDuringReload`, `applyLocalChanges` in `ChatConversationsViewModel` (`:171-200`); `markOpened` records before its `guard` |
| WR-06 first message of an unknown thread dropped during a load | fixed | `needsReloadAfterLoad` set only while `.loading`, consumed in `forceLoad` |
| IN-01, IN-03, IN-04, IN-05, IN-07 | fixed | 408/429 kept as Failed (`ChatThreadReducer.swift:62`); the rest are in `07-REVIEW-FIX.md` and are exercised by `ChatItemMapperTests` and the shared test helpers |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Utils/ChatThreadReducer.swift` | Pure thread rules | VERIFIED | 286 lines; used by `ChattingViewModel` (append, ack, fail, retry, remove, mergePage, onIncoming) |
| `Views/.../ChatSendCoordinator.swift` | In-flight send ownership | VERIFIED | Called from `startSend`; the only caller of `sendFailure` |
| `Utils/ChatItemMapper.swift` | Row mapping out of the VM | VERIFIED | Used by `mapToChatItem` |
| `Utils/ChatComposerRules.swift` | Cap and counter | VERIFIED | Used by `updateMessageText` |
| `Utils/ChatThreadLookup.swift` | Bounded `GET /chats` scan | VERIFIED | Used by the thread VM and Report & Block |
| `Utils/ChatBlockState.swift` | Block matrix and Session | VERIFIED | Used by the thread VM, `ReportChatViewModel` and the banner |
| `ChattingBlockedBanner.swift` | Banner replacing composer | VERIFIED | Rendered when `composerMode != .normal` |
| `ExpertProfileBlockViewModel.swift` | Confirm then initiate and block | VERIFIED | Wired in the `ExpertProfileView` alert |
| `Utils/ChatUnreadRules.swift` | Pill and label rules | VERIFIED | Used by the row and the list VM |
| `Utils/ChatBookingRowRoute.swift` | Shell-aware route | VERIFIED | Wired in `ChattingView` |
| `RealtimeService.isConnected` / `onConnect` | Connection-held read receipts | VERIFIED | Used by `attachRealtime` and `emitPendingReads` |
| 13 test files in `ClickMe2026Tests/Chat/` | Behavioral coverage | VERIFIED | 10 of them run in my invocation; all 13 run in the full-suite log |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `sendMessage` | `ChatSendCoordinator.send` then POST with `clientMsgId` | `startSend` | WIRED | Same id on bubble and request |
| Outcome | `ChatThreadReducer.ack/fail/remove` | `applySendOutcome` | WIRED | |
| `forceLoad` / `loadEarlier` | `mergePage` | direct | WIRED | |
| Open and `viewDidAppear` | `ChatThreadLookup.find` | `refreshThreadInfo` | WIRED | Revision-guarded after WR-01 |
| Send refusal 403 | banner | `blockSession.applySendRefusal` | WIRED | |
| Block & Report outcome | thread | `onBlockStateChange` | WIRED | |
| `ChatPresence.visibleThreadId` | list `markOpened` / `silentReload` | `.onChange` | WIRED | |
| Socket `message.new` | list row | `handleMessageNew` | WIRED | |
| `submitReport` | `chatAction(... reason: rawValue)` | direct | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `ChatConversationRow` pill | `chat.unreadCount` | `GET /chats` `unread_count` plus local +1 and zero, overlaid across reloads | Yes | FLOWING |
| `ChattingBlockedBanner` | `composerMode` | `GET /chats` `is_blocked` and `blocked_by_me`, send refusal, Block & Report hand-back | Yes | FLOWING |
| Message bubbles | `items` | `GET /chats/:id/messages` merged with local sends and socket events | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Ten chat suites | `xcodebuild test -scheme ClickMe2026 -only-testing:` on ChatConversationsUnread, ChatThreadReducer, ChatBlockState, ChattingViewModelOpen/Send/ReadEmit, ReportChatViewModel, ProfileBlockAction, ChatItemMapper, ChatUnreadRules (iPhone 17 simulator) | `Test run with 169 tests in 10 suites passed`, `** TEST SUCCEEDED **` | PASS |
| Full unit suite at the last code commit | Read `/tmp/07-validate-full.log` (not re-run by me) | `Test run with 1192 tests in 109 suites passed`, `** TEST SUCCEEDED **`. `git diff aea7ecb HEAD -- ClickMe2026 ClickMe2026Tests` is empty, so the log covers the current code. | PASS (log read) |
| `handleMessageRead` unchanged since phase base | extract at `16fe88e` vs HEAD, `diff` | identical | PASS |
| Working tree only has unrelated edits | `git status --short` | `.DS_Store` files, `.planning/config.json`, `Localizable.xcstrings`, `milestone.lock`, `state.json`; no covered source file modified | PASS |

The regression gate for earlier phases is the 1192-test full-suite run above. I did not re-run it myself; I read its log and confirmed no code changed after it.

### Probe Execution

Step 7c: SKIPPED. The phase declares no probe scripts.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CHAT-01 | 07-01, 07-02 | Pending, failed, retry | SATISFIED | Truth 1; device items 1 and 2 PASS |
| CHAT-02 | 07-05 | Report sends enum values | SATISFIED | Truth 4 |
| CHAT-03 | 07-04, 07-05, 07-06 | Blocked-thread banner; Unblock only for the blocker | SATISFIED | Truth 2; device items 6 and 7 PASS |
| CHAT-04 | 07-05, 07-06 | Profile Block confirm dialog; truthful copy | SATISFIED | Truth 2; device item 8 PASS |
| CHAT-05 | 07-03 | Typing and View Profile on open | SATISFIED | `ChatThreadLookup` and `ChattingViewModelOpenTests` |
| CHAT-06 | 07-03 | No duplicates on Load earlier | SATISFIED | `mergePage` in `loadEarlier` and its tests |
| CHAT-07 | 07-03, 07-07 | Unread badge | SATISFIED | Truth 3; device items 10 and 11 and UAT test 6 PASS |
| CHAT-08 | 07-01, 07-03 (guard only) | Live Read label | SATISFIED (closed as not reproducible) | Truth 5; regression row PASS |

All eight IDs appear in the plan frontmatter and in `REQUIREMENTS.md`. There are no orphaned requirements: CHAT-09 maps to Phase 2 and is already ticked. Bookkeeping for the orchestrator: `REQUIREMENTS.md` still shows the CHAT-01 to CHAT-08 checkboxes open and the traceability rows as Pending. I did not edit them, as instructed.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ChatConversationsViewModel.swift` | 215-222, 258 | WR-07 (open): `noteLocalActivity` records `existing.lastMessage` as the overlay preview when a `message.new` carries `content: nil`, so a late reload's newer server preview can be replaced by the stale one | Warning, not a blocker | Wrong preview text on one row until the next reload. See reasoning below. |
| `ChatConversationsViewModel.swift` | 148-166 | IN-08 (open): the WR-06 follow-up uses `silentReload`, whose `try?` hides a failure | Info | New row can stay missing until the next reload |
| `ChatThreadReducer.swift` | 43-62 | IN-09 (open): iOS keeps 408/429 as Failed; Android removes the bubble and restores the text | Info, cross-repo | Platform divergence only. Android work would be its own commit in the Android repo; I did not check that repo. |
| `ChatConversationsViewModel.swift` | 171-183 | IN-10 (open): recorded row changes are not scoped to the reload that was in flight when they happened | Info | Only with overlapping reloads and a socket gap; bounded, cleared when the last reload ends |
| `ChatBlockState.swift` | 126 | IN-06 (skipped on purpose): banner copy does not say that pull-to-refresh retries | Info | Needs a copy decision |
| `ExpertProfileView.swift` | 454 | `TODO` comment, pre-existing | Info | Not a debt marker; no `TBD`, `FIXME` or `XXX` in any covered file |

**Why WR-07 does not block the goal.** I confirmed the defect in the code. But the backend contract for `message.new` (`docs/SOCKET-CONTRACT.md`, `content: "string, 1..10000 chars"` for text) means `content` is nil only for a non-text message type. The wrong value is one row's preview text, and it needs a late reload racing a content-less event. The unread count, the row order and the message itself are unaffected, and the next reload corrects the preview. It does not touch any of the five success criteria. I recommend a fix before the Phase 8 build, since the reviewer's fix is small (record the preview only when `event.content != nil`, plus one test), but I would not hold the phase for it. IN-08 to IN-10 are optional hardening or cross-repo notes. `07-REVIEW-DISPOSITION.md` still lists WR-07, IN-08, IN-09 and IN-10 as `open`; they need a fix, defer or skip decision from the orchestrator.

### Deferred, not gating

These two were not exercised on a device. I judge neither a phase-goal blocker and I list them so the decision is visible.

1. **VoiceOver pass** (checklist item 12, the VoiceOver parts of items 3 and 4, the IN-04 check). The user skipped these on purpose and `ROADMAP.md` tracks them as backlog Phase 999.5. None of the eight CHAT requirements or five success criteria is about accessibility output; the accessibility labels and custom actions exist in code (`ChattingMessageBubble`, with the IN-04 label now applied only while a bubble is pending). The UI review (`07-UI-REVIEW.md`, 18/24, no blockers) is consistent with that. Strictly, VoiceOver output on the Failed bubble, the cap counter and the pending label is still unobserved. If you want those confirmed before release, run backlog 999.5 before the Phase 8 build.
2. **WR-02 device step** (an unavailable recipient re-enabled by pull-to-refresh). No unavailable test account existed. The code path is verified above and the unit tests pass; the device step stays unrun.

### Human Verification Required

None. Everything that was a human item in the previous report has a recorded result in `07-UAT.md` and `07-DEVICE-UAT-CHECKLIST.md`, apart from the two deferred items above.

### Gaps Summary

There are no gaps. Every ROADMAP criterion and every plan must-have I checked is present, substantive, wired and backed by passing tests, and the device checks the previous report listed as outstanding have been run and passed. The audits agree: `07-VALIDATION.md` is nyquist-compliant, `07-SECURITY.md` has 0 open threats, and `07-UI-REVIEW.md` has no blockers. Open items that do not block the goal: WR-07 (fix recommended before Phase 8), IN-08, IN-09 and IN-10, the skipped IN-06, and the two deferred device checks above.

---

_Verified: 2026-11-19T04:10:00Z_
_Verifier: Claude (gsd-verifier)_
