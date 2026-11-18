---
phase: 07-chat
reviewed: 2026-11-18T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - ClickMe2026/Realtime/RealtimeService.swift
  - ClickMe2026/Utils/ChatBlockState.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift
  - ClickMe2026/Utils/ChatThreadReducer.swift
  - ClickMe2026/Model/UIModels/ChatDisplayModels.swift
  - ClickMe2026/Utils/ChatItemMapper.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift
  - ClickMe2026Tests/Chat/ChatBlockStateTests.swift
  - ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift
  - ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift
  - ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift
findings:
  critical: 0
  warning: 2
  info: 7
  total: 9
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-11-18
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

This is an incremental re-review after fix commits 82050a4, 505068c, d9dc9b6 and 9f5f35e (WR-01 to WR-04 of the first review). I read the four changed source files in full and the diff of the four changed test files. I also re-opened every location cited by IN-01 to IN-05.

**Fix verification**
- **WR-01 (stale scan undoes a block change): fixed.** `Session.revision` moves on `adopt`, `applyUnblockSucceeded`, a `NOT_BLOCKER` unblock failure and a handled send refusal. `refreshThreadInfo` captures it before the await and drops the flags if it moved. I traced the ordering: a refusal bumps the revision first and then starts its own rescan, so that rescan captures the new value and is not dropped. `applyScan(found:)` now also resets `sessionBlockedByMe`. Nothing regressed.
- **WR-02 (`recipientUnavailable` never cleared): fixed.** `reload()` is only called from pull-to-refresh and the error retry in `ChattingView`. A block still wins over the cleared flag. The banner text still gives no hint that refreshing helps (see IN-06).
- **WR-03 (Socket.IO logging in all builds): fixed.** `.log` is now `false` outside `#if DEBUG`. No other `print`, `NSLog` or logger call exists in the file.
- **WR-04 (list reload races): partly fixed.** The unread count now survives a late reload, but two gaps remain, WR-05 and WR-06 below.

No security issues, crashes or data-loss bugs found. The new in-flight tests are sound. `MockURLProtocol` records a request before it calls the handler, so `waitUntil { chatsGets().count >= 2 }` returns only once the request is held at the gate.

## Warnings

### WR-05: A late `GET /chats` still replaces the live row's preview, time and order, and a `markOpened` on a row that is not listed yet is lost (incomplete fix of WR-04, part 1)

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:149-163, 182-220`
**Issue:** `fetchChats()` re-applies only `unreadCount` over the server snapshot. `handleMessageNew` changes four other things on the row: `lastMessage`, `timeLabel`, the row position (moved to index 0) and `unreadCount`.

1. If a live message arrives while a reload is in flight, the response that predates it restores the old preview, the old time label and the old order. The unread pill then shows the new count (for example 3) beside the old message text. The review of WR-04 named "the same applies to `handleMessageNew` updates made while a reload is in flight", and the fix covers only the pill. The row stays wrong until the next reload.
2. `markOpened` returns at `guard let idx` before it reaches `noteLocalUnread`. While the first load is running, `chats` is empty and the thread is not listed yet. If the user opens that thread then (for example from a push tap on cold start), nothing is recorded, and the first load puts the server's unread pill back on the thread that is on screen.

**Fix:** Record the local change for the whole row, and record `markOpened` even when the row is absent.
```swift
private var localRowsDuringReload: [UUID: ChatPreview] = [:]   // set by handleMessageNew
private var openedDuringReload: Set<UUID> = []                  // set by markOpened, row listed or not

// fetchChats: after mapping
for index in rows.indices {
    let id = rows[index].threadId
    if let local = localRowsDuringReload[id] { rows[index] = local }
    else if openedDuringReload.contains(id) { rows[index].unreadCount = 0 }
}
// order: put rows in localRowsDuringReload first, newest event first
```
`markOpened` should call `openedDuringReload.insert(threadId)` before its `guard`, but only while `reloadsInFlight > 0`. Clear both collections together with the existing counter. Add a test for each of the two cases above.

### WR-06: A new conversation's first message is dropped if it arrives while a load is in flight (regression from the WR-04 part 2 fix)

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:189`
**Issue:** The new `guard case .loaded = loadState else { return }` assumes that a pending load "already returns the message". That is true only if the server read its list after the message was stored. The socket event can arrive while the HTTP response is still travelling, and that response may carry a snapshot taken before the message. In that case the event is ignored and the response does not list the thread, so the new conversation does not appear until some later reload. The window is the request latency, which is longest on a cold start.

The same guard also covers a pull-to-refresh. `reload()` sets `loadState = .loading` while `chats` is already filled, so every unknown-thread event during a refresh is dropped. Before the fix this case called `silentReload()` and then `forceLoad()`, which at least refetched.

**Fix:** Remember the event and refetch once the in-flight load ends, instead of dropping it.
```swift
private var needsReloadAfterLoad = false

// handleMessageNew, unknown-thread branch
guard case .loaded = loadState else { needsReloadAfterLoad = true; return }

// end of forceLoad(), after loadState = .loaded
if needsReloadAfterLoad { needsReloadAfterLoad = false; await silentReload() }
```
This keeps the fix's goal, which is no duplicate request during the load. It makes one follow-up request only when an unknown thread was seen in that window. Reset the flag when the load fails.

## Info

### IN-01: `sendFailure` treats every 4xx as a permanent refusal, including 401, 408 and 429

**File:** `ClickMe2026/Utils/ChatThreadReducer.swift:44-49`
**Issue:** The rule mirrors Android (`SERVER_ERROR_FROM = 500`), and `ChatSendCoordinator` removes the bubble and restores the text on any 4xx. For 429 and 408 that is a reasonable result. The bubble is gone and the text is back in the composer, so the user can resend, but the failure looks like a refusal. A 401 that survives the refresh interceptor logs the user out and also shows a "Couldn't send message" alert. Behaviour is acceptable, but the doc comment ("the server refused the message") overstates it.
**Fix:** Optionally map 408 and 429 to `.keepAsFailed` so the Retry affordance is available, and say in the comment which codes are treated as a refusal.

### IN-02: `.timestamp` rows would be moved to the end by `ChatThreadReducer.order`

**File:** `ClickMe2026/Utils/ChatThreadReducer.swift:181-197`, `ClickMe2026/Model/UIModels/ChatDisplayModels.swift:35-40`
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

**File:** `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift:120-124`, `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift:146-150, 289-292`
**Issue:** `waitUntil` loops without reporting a timeout. A timeout falls through to whatever the next `#expect` checks. That is fine for positive checks, but the failure message then points at the wrong assertion. `viewDidAppearScansOnlyOnceLoaded` asserts "no request was made" after a fixed 50 ms sleep, which would also pass if the scan were merely late. The suites rely on the test plan's `parallelizable: false` because `MockURLProtocol.handler` is global static state. `.serialized` alone does not prevent cross-suite interference if someone enables parallel execution. The new in-flight tests also use `waitUntil` to reach the gate, and a timeout there would release a request that was never held (the same silent fall-through).
**Fix:** Have `waitUntil` record an `Issue` on timeout. For the negative check, drive the scan through the awaited `Task` or an injected seam. Add a comment on the suites noting the dependency on the non-parallel test plan. Note that `ChatConversationsUnreadTests.swift:313` (the new `unknownThreadBeforeFirstLoadIsIgnored` test) adds another fixed 50 ms negative check of the same kind.

### IN-06: The "unavailable" banner does not tell the user that pull-to-refresh retries

**File:** `ClickMe2026/Utils/ChatBlockState.swift:126`, `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift:173-180`
**Issue:** WR-02 made pull-to-refresh clear `recipientUnavailable`, but the banner copy is still "This user is unavailable." with no hint. The recovery path exists but a user cannot find it. The fix report deliberately left the copy as a UX decision. The same applies to Android, which ports `BlockState.kt`.
**Fix:** Get a copy decision, for example "This user is unavailable. Pull down to try again." Alternatively, clear the flag in `viewDidAppear` after a delay or on socket reconnect.

### IN-07: Two copies of the test `Gate` helper that behave differently

**File:** `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift:44-62`, `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift:558-570`
**Issue:** The two `Gate` classes are near duplicates. The one in `ChatConversationsUnreadTests` disarms itself in `open()`. The one in `ChattingViewModelOpenTests` never does, so every later request that goes through the same handler waits for the full 5-second timeout. The test passes now only because `ChatThreadLookup.find` finds the thread on page 1 and makes one request. A fixture with `pagination.totalPages > 1` would make that test slow or flaky without a clear cause.
**Fix:** Move one `Gate` that disarms in `open()` into `ClickMe2026Tests/Support/` and use it in both suites.

---

_Reviewed: 2026-11-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
