---
phase: 07-chat
reviewed: 2026-11-18T00:00:00Z
depth: standard
files_reviewed: 42
files_reviewed_list:
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
  - ClickMe2026Tests/Chat/ChatBlockStateTests.swift
  - ClickMe2026Tests/Chat/ChatBookingRowRouteTests.swift
  - ClickMe2026Tests/Chat/ChatComposerRulesTests.swift
  - ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift
  - ClickMe2026Tests/Chat/ChatThreadItemDecodingTests.swift
  - ClickMe2026Tests/Chat/ChatThreadReducerTests.swift
  - ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift
  - ClickMe2026Tests/Chat/ChattingViewModelReadEmitTests.swift
  - ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift
  - ClickMe2026Tests/Chat/ChatUnreadRulesTests.swift
  - ClickMe2026Tests/Chat/ProfileBlockActionTests.swift
  - ClickMe2026Tests/Chat/ReportChatViewModelTests.swift
  - ClickMe2026Tests/Support/ChatFixtures.swift
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-11-18
**Depth:** standard
**Files Reviewed:** 42
**Status:** issues_found

## Summary

I read all 29 source files and skimmed the 13 test files for reliability problems. The send pipeline holds up: the reducer, coordinator, view model and views agree on the send flow.

- The optimistic-bubble lifecycle is consistent. A bubble keeps its `id` across ack, fail and retry, and reload merges match by `client_msg_id`, so a reload can't duplicate or drop a bubble.
- Retry reuses the `client_msg_id`. This is safe: the backend returns 201 with the existing row on a duplicate (`chatMessages.js`, D-12).
- The composer cap counts UTF-16 units, which is the unit the backend's zod `max(10000)` uses.
- The 4xx and 5xx split in `sendFailure` matches the backend's `THREAD_BLOCKED` and `RECIPIENT_UNAVAILABLE` 403s.
- `ChatSendCoordinator` is safe under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Its `inFlight` dictionary is only touched on the main actor, so there is no data race.
- I found no security vulnerabilities and no crash or data-loss bugs.

The four warnings are stale-state races that leave the UI wrong until the next refresh, plus one pre-existing logging setting that the chat feature makes more sensitive. The info items are latent traps and test-quality notes.

## Warnings

### WR-01: A stale `GET /chats` scan can undo a block or unblock that finished while it was running

**File:** `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift:313-322` (with `ClickMe2026/Utils/ChatBlockState.swift:172-174`)
**Issue:** `refreshThreadInfo()` awaits up to three sequential `GET /chats` pages, then calls `blockSession.applyScan(found:)`. Nothing checks whether the block state changed during that time. Several things can start a scan: `forceLoad`, `viewDidAppear`, and the send-refusal path (`applySendOutcome`, line 408). The user can tap the banner's Unblock, or return from Report & Block with a new state adopted through `adoptBlockState`, while a scan is in flight. The server sees the unblock after the scan read the thread, so the scan response is stale. When it arrives it overwrites `block` with `isBlocked: true`, and the composer reverts to the banner although the server has unblocked. The same applies in the other direction after a block. `ReportChatViewModel` guards against exactly this with `stateRevision` (lines 65-67 and 113). The thread view model has the same exposure and no guard.

The scan can also leave `sessionBlockedByMe` stale. `applyScan` copies the found flags into `block`, but `sessionBlockedByMe` stays true after a scan reports that the peer blocked. A later scan that doesn't list the thread then reads as blocked by me.

**Fix:** Add a revision counter to `ChatBlockState.Session` and bump it in every mutator except `applyScan`. `refreshThreadInfo` captures it before the await and drops the result if it changed. Also make `applyScan(found:)` set `sessionBlockedByMe = found.isBlocked && found.blockedByMe` when `found` is non-nil.
```swift
// ChatBlockState.Session
private(set) var revision = 0
// bump `revision &+= 1` in adopt, applyUnblockSucceeded, applyUnblockFailure, applySendRefusal

// ChattingViewModel.refreshThreadInfo
let revision = blockSession.revision
let thread = try await ChatThreadLookup.find(threadId: threadId, api: api)
guard revision == blockSession.revision else { return }
```

### WR-02: `recipientUnavailable` is never cleared, so the composer stays disabled until the screen is rebuilt

**File:** `ClickMe2026/Utils/ChatBlockState.swift:159, 186`
**Issue:** `applySendRefusal(.recipientUnavailable)` sets `recipientUnavailable = true`. Nothing resets it: not `applyScan`, not `adopt`, not `applyUnblockSucceeded`. `GET /chats` does not expose the peer's account status, so a rescan can't clear it either. If the recipient is suspended and then reinstated, or the 403 came from a transient moderation state, the user can't send in this open chat. The "unavailable" banner stays, and its text says nothing about retrying. The flag only resets when `ChattingViewModel` is recreated, which happens when the user leaves and re-enters the thread. The doc comment says "for this session", but nothing tells the user the way out.

**Fix:** Clear the flag in `viewDidAppear`/`reload()` (the pull-to-refresh path) so a fresh visit or refresh retries. The server's fail-open check means one extra refused send is cheap. For example, add `mutating func clearUnavailable()` to `Session` and call it from `ChattingViewModel.reload()`.

### WR-03: Socket.IO client logging is on in all builds and logs message traffic

**File:** `ClickMe2026/Realtime/RealtimeService.swift:93` (`.log(true)`)
**Issue:** This line is not in the phase diff, but the file is in scope. `SocketManager` is created with `.log(true)` unconditionally. socket.io-client-swift then writes engine and event traffic to the console in Release as well as Debug builds. That includes the decoded `message.new` and `message.read` payloads, so chat content and user ids reach the unified log. The project convention is "no logging of user content" and "wrap debug-only logging in `#if DEBUG`". This phase adds more traffic through the socket: read receipts, reconnect handling and the `onConnect` hook. It also adds more places where the log would leak. The same connect call sends the JWT as the handshake payload (line 113).

**Fix:**
```swift
#if DEBUG
let logging = true
#else
let logging = false
#endif
// config: [.log(logging), ...]
```

### WR-04: Chats list reloads can overwrite local unread changes and double-fetch during the first load

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:114-124, 148-173`
**Issue:** Two related races in the list view model:
1. `silentReload()` assigns `chats = response…map(mapThread)` when the response arrives. The view triggers it when a chat closes (`ChatConversationsView.swift:75`). If the user opens another thread during the request, `markOpened(threadId:)` zeroes that row. The late response then restores the server's count. The server may not have processed the `message.read` emits yet. The pill for the thread on screen reappears until the next reload. The same applies to `handleMessageNew` updates made while a reload is in flight.
2. `handleMessageNew` subscribes at `init`, so it runs while `chats` is still empty. Every live message in that window takes the "unknown thread" branch and calls `silentReload()`. That falls through to `forceLoad()` because `loadState` is not `.loaded`. The result is duplicate `GET /chats` calls that each set `loadState = .loading`, so the spinner can flash again after the first load finishes. In the `.failed` state, any incoming message also silently re-triggers a full load.

**Fix:** For (1), apply a reload result by merging: keep the local `unreadCount` for rows whose thread is currently visible (`visibleThreadId()`), or track a revision counter bumped by `markOpened` and `handleMessageNew` and drop or merge a result that predates it. For (2), only take the "unknown thread" reload path when `loadState == .loaded`, and otherwise ignore the event, because the pending load will include it.

## Info

### IN-01: `sendFailure` treats every 4xx as a permanent refusal, including 401, 408 and 429

**File:** `ClickMe2026/Utils/ChatThreadReducer.swift:44-49`
**Issue:** The rule mirrors Android (`SERVER_ERROR_FROM = 500`), and `ChatSendCoordinator` removes the bubble and restores the text on any 4xx. For 429 and 408 that is a reasonable result. The bubble is gone and the text is back in the composer, so the user can resend, but the failure looks like a refusal. A 401 that survives the refresh interceptor logs the user out and also shows a "Couldn't send message" alert. Behaviour is acceptable, but the doc comment ("the server refused the message") overstates it.
**Fix:** Optionally map 408 and 429 to `.keepAsFailed` so the Retry affordance is available, and say in the comment which codes are treated as a refusal.

### IN-02: `.timestamp` rows would be moved to the end by `ChatThreadReducer.order`

**File:** `ClickMe2026/Utils/ChatThreadReducer.swift:181-198`, `ClickMe2026/Model/UIModels/ChatDisplayModels.swift:35-40`
**Issue:** `order` sorts rows that have a server id, then appends everything without one in current order. `.timestamp` separators have no `serverId`, so any `.timestamp` row that enters `items` is put after the server rows. Today only the preview `sampleConversation` contains them, and `mergePage` isn't used for previews, so there is no live bug. It is a trap if day separators are ever added to `items`. The `.timestamp` id (`"ts_\(label)"`) also collides when two separators share a label.
**Fix:** Add a note to the `order` doc comment, or compute separators at render time rather than storing them in `items`.

### IN-03: `Int(d)` in `extractInt` can trap on an out-of-range double

**File:** `ClickMe2026/Utils/ChatItemMapper.swift:160`
**Issue:** `case .double(let d): return Int(d)` crashes at runtime if the server sends a double outside the `Int` range, for example `1e30` in `duration_mins`. The value comes from the backend's `event_data`, so the risk is low, but a crash while mapping a thread page would block the whole chat from opening.
**Fix:** `return Int(exactly: d)`.

### IN-04: Empty accessibility label on non-pending bubble containers

**File:** `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift:69-70`
**Issue:** `.accessibilityLabel(isPending ? "\(message.body). Sending." : "")` applies an empty label to the `.contain` container for every sent bubble. Children are still read, but an explicit empty label on a container is an odd VoiceOver signal. It's cleaner to attach the label only to the pending case.
**Fix:** Branch the modifier with `@ViewBuilder` or `if`, or use `.accessibilityLabel(isPending ? Text(...) : nil)` where available.

### IN-05: Test timing helpers hide failures and one negative check is a fixed sleep

**File:** `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift:88-92`, `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift:146-150, 289-292`
**Issue:** `waitUntil` loops without reporting a timeout. A timeout falls through to whatever the next `#expect` checks. That is fine for positive checks, but the failure message then points at the wrong assertion. `viewDidAppearScansOnlyOnceLoaded` asserts "no request was made" after a fixed 50 ms sleep, which would also pass if the scan were merely late. The suites rely on the test plan's `parallelizable: false` because `MockURLProtocol.handler` is global static state. `.serialized` alone does not prevent cross-suite interference if someone enables parallel execution.
**Fix:** Have `waitUntil` record an `Issue` on timeout. For the negative check, drive the scan through the awaited `Task` or an injected seam. Add a comment on the suites noting the dependency on the non-parallel test plan.

---

_Reviewed: 2026-11-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
