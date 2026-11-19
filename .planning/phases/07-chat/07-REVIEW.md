---
phase: 07-chat
reviewed: 2026-11-18T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - ClickMe2026/Model/UIModels/ChatDisplayModels.swift
  - ClickMe2026/Utils/ChatItemMapper.swift
  - ClickMe2026/Utils/ChatThreadReducer.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift
  - ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift
  - ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift
  - ClickMe2026Tests/Chat/ChatItemMapperTests.swift
  - ClickMe2026Tests/Chat/ChatThreadReducerTests.swift
  - ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift
  - ClickMe2026Tests/Support/RequestGate.swift
  - ClickMe2026Tests/Support/WaitUntil.swift
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-11-18
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

This is an incremental re-review after the second batch of fix commits (f914364, 04962f2, e42d16f, cb412f2, 9c024fd, 500c9a1, 3ac5cfe, aea7ecb). I read the full diff `fca37d4..HEAD` of the listed files, read `ChatConversationsViewModel.swift` in full, and read the new test support files and the changed test suites. I also checked `ChatSendCoordinator.perform` (the only caller of `sendFailure(for:)`) and the current state of the IN-06 locations.

**Fix verification**
- **WR-05 (late `GET /chats` replaces preview, time label, order; `markOpened` lost for an unlisted row): fixed.** `fetchChats()` now overlays unread count, last message and time label, and moves touched rows to the top, newest first. `markOpened` records before its `guard`. I traced the `defer` ordering: `applyLocalChanges` runs inside the `return` expression, before the `defer` clears the records. The clear happens only when `reloadsInFlight` reaches 0, so overlapping reloads keep the records. One new gap, WR-07: a message without text content.
- **WR-06 (unknown thread's first message dropped during a load): fixed.** `needsReloadAfterLoad` is set only in `.loading`. In `forceLoad`, the assignment `chats = ...` and `loadState = .loaded` are one synchronous main-actor step, so no message can slip between the response and the flag check. A failure clears the flag. A follow-up `silentReload()` runs with `loadState == .loaded`, so a message that arrives during the follow-up goes through the normal `.loaded` branch. Remaining nit: IN-08.
- **IN-01 (4xx treated as a permanent refusal): fixed.** 408 and 429 now return `.keepAsFailed`. `ChatSendCoordinator.perform` is the only caller, and it maps the result as before. The Retry path reuses the same `clientMsgId`, so it is idempotent. See IN-09 for the Android divergence.
- **IN-02 (`.timestamp` ordering trap): fixed** as a comment-only change. No behaviour change.
- **IN-03 (`Int(d)` trap): fixed.** `Int(exactly:)` returns nil for NaN, infinity, fractional and out-of-range doubles. The new `ChatItemMapperTests` cover each case and also assert that the row still maps.
- **IN-04 (empty accessibility label): fixed.** `accessibilityLabel(_:isEnabled:)` with `isEnabled: isPending` leaves the label alone for a sent bubble. It needs the VoiceOver check on a device that the fix report already lists.
- **IN-05 (silent `waitUntil`, fixed sleeps): fixed.** The shared `waitUntil` records an `Issue` at the call site on timeout. The two fixed-sleep negative checks are now asserted through the request count after an awaited `load()`. The private `waitUntil` in `PushTokenCleanupTests` (line 410) is a member and shadows the global one, so it is unaffected.
- **IN-07 (two different `Gate` helpers): fixed.** One `RequestGate` disarms in `open()`. A leftover semaphore count when `open()` runs before the handler reaches `waitIfArmed()` is harmless, because each test creates its own gate and the local change was already made before `open()`.

No security issues, crashes or data-loss bugs found. The status stays `issues_found` because of WR-07 and the open info items.

## Warnings

### WR-07: A live message without text content makes the late-reload overlay replace the server's newer preview with the stale local one (regression from the WR-05 fix)

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:215-222, 258`
**Issue:** `handleMessageNew` builds the row with `lastMessage: event.content ?? existing.lastMessage`. When `event.content` is nil (for example a non-text message or an event), `updated.lastMessage` is just the old preview. `noteLocalActivity(updated)` then records that old preview as `LocalRowChange.lastMessage`. `applyLocalChanges` prefers `change.lastMessage` over the row from the server, so a reload that predates or follows that message and carries the correct, newer preview from the server has it overwritten by the stale text. Before WR-05 only the unread count was overlaid, so the server's preview won. The row shows the wrong preview until the next reload.
**Fix:** Record the preview only when the event carried one.
```swift
private func noteLocalActivity(_ row: ChatPreview, hasContent: Bool) {
    guard reloadsInFlight > 0 else { return }
    if hasContent {
        changesDuringReload[row.threadId, default: LocalRowChange()].lastMessage = row.lastMessage
    }
    changesDuringReload[row.threadId, default: LocalRowChange()].timeLabel = row.timeLabel
    movedToTopDuringReload.removeAll { $0 == row.threadId }
    movedToTopDuringReload.insert(row.threadId, at: 0)
    noteLocalUnread(row.unreadCount, threadId: row.threadId)
}
// call site: noteLocalActivity(updated, hasContent: event.content != nil)
```
Add a test: during a held reload, deliver an event with `content: nil` and assert that the server's `lastMessage` is kept.

## Info

### IN-06: The "unavailable" banner does not tell the user that pull-to-refresh retries

**File:** `ClickMe2026/Utils/ChatBlockState.swift:126`, `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift:173-180`
**Issue:** WR-02 made pull-to-refresh clear `recipientUnavailable`, but the banner copy is still "This user is unavailable." with no hint. The recovery path exists but a user cannot find it. The fix report deliberately left the copy as a UX decision. The same applies to Android, which ports `BlockState.kt`. I re-checked both locations: the string is unchanged at line 126 and `reload()` still clears the flag. Still open, deliberately skipped.
**Fix:** Get a copy decision, for example "This user is unavailable. Pull down to try again." Alternatively, clear the flag in `viewDidAppear` after a delay or on socket reconnect.

### IN-08: The WR-06 follow-up fetch swallows its own failure

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:148-150, 163-166`
**Issue:** The follow-up goes through `silentReload()`, which uses `try?`. If that request fails, the list stays at the first response and the new conversation does not appear. Nothing records that it is still missing, and `needsReloadAfterLoad` was already cleared. The failure is invisible until the next reload (pop-back or pull-to-refresh), which is acceptable for a silent refresh, but it is the same window the fix set out to close.
**Fix:** Optional. Set `needsReloadAfterLoad = true` again when the follow-up fails and retry once on the next `viewDidAppear`/`load()`, or accept the gap and note it in the doc comment on `needsReloadAfterLoad`.

### IN-09: iOS and Android now differ on 408 and 429 for a failed chat send

**File:** `ClickMe2026/Utils/ChatThreadReducer.swift:43-60`
**Issue:** iOS keeps the bubble as Failed for 408 and 429. Android's `ChatThreadViewModel.kt` (`SERVER_ERROR_FROM = 500`) removes the bubble and restores the text. The project rule is that iOS is the source of truth and Android mirrors it. The fix report notes the divergence but no Android change is recorded. This is a cross-repo item, so I did not verify it in the Android repo.
**Fix:** Port the 408/429 rule to `ChatThreadViewModel.kt` in the Android repo in its own commit, or record that the divergence is accepted.

### IN-10: Recorded row changes are not scoped to the reloads that started before them

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:171-183`
**Issue:** `changesDuringReload` is one dictionary that lives until `reloadsInFlight` reaches 0. If reload A is in flight when a local change is recorded and reload B then starts, B's response is also overlaid with that change, although B's request was sent after the change and may carry a newer server value (for example a higher unread count after more peer messages reached the server while the socket was down). The local value wins until the last reload ends. The effect is bounded, because the records are cleared when the last reload ends and the next reload takes the server's value. It only shows with overlapping reloads and a socket gap.
**Fix:** Optional. Give each `fetchChats()` call a sequence number, store the sequence with each record, and apply only the records made after that request started and before its response, which is the shape of the `Session.revision` guard in `ChattingViewModel`.

---

_Reviewed: 2026-11-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
