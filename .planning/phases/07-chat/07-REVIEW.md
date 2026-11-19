---
phase: 07-chat
reviewed: 2026-11-18T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift
  - ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift
  - ClickMe2026Tests/Support/ChatFixtures.swift
  - ClickMe2026/Utils/ChatBlockState.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
  - ClickMe2026/Utils/ChatThreadReducer.swift
findings:
  critical: 0
  warning: 0
  info: 4
  total: 4
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-11-18
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This is an incremental re-review after fix commit ccf5304 (WR-07). I read `git diff 004f678..HEAD` for the three files, read `ChatConversationsViewModel.swift` in full, and re-checked each carried-forward finding against current source. For IN-06, IN-08, IN-09 and IN-10 that included the files outside the 3-file list. For IN-09 it also included `../ClickMe_Android`, and I read the backend `chatMessages.js` for the message.new payload.

**WR-07: fixed and complete.**
- `noteLocalActivity(_:hasContent:)` records `LocalRowChange.lastMessage` only when the event carried text. `handleMessageNew` is its only caller (line 275) and passes `event.content != nil`.
- The time label, top position and unread count are still recorded for a text-less event. That is right, because those effects are real whether or not the event had text.
- A preview recorded earlier by a text event is not erased by a later text-less one. The text-less one just does not write the key.
- `applyLocalChanges` uses `change.lastMessage ?? row.lastMessage`, so an unrecorded preview falls through to the server's row.
- The new test, `lateReloadKeepsServerPreviewForTextlessEvent`, can tell the fix from the bug on all four assertions. The server preview differs from the local one (nil, shown as ""). The server's `last_msg_at` is null, so a non-empty time label can only come from the local overlay. The server unread count (2) plus the live message gives 3.
- The `ChatFixtures.thread(lastMessage:)` default is nil, which keeps the existing callers' JSON unchanged (`"last_message":null`).
- I found no regression. The first page never writes `lastMessage`, so the test needs the swapped server body, and it has one.
- Practical reach: the backend `message.new` emit (`chatMessages.js`) always sends `content` from a send that was validated at 1..10000 characters, so the text-less path is defensive. The fix is still correct for it.

**Carried forward, still present** (same ids and titles): IN-06, IN-08, IN-09, IN-10. Each was re-checked against the current source.
- IN-06: `ChatBlockState.swift:126` still reads "This user is unavailable." and `ChattingViewModel.reload()` still clears the flag.
- IN-08: `silentReload()` still uses `try?` (line 148), and `needsReloadAfterLoad` is cleared before the follow-up (lines 163-166).
- IN-09: Android `ChatThreadViewModel.kt:240` still removes the bubble for any `e.status < SERVER_ERROR_FROM` (500). It has no 408/429 exception, while iOS `ChatThreadReducer.swift` keeps those two as Failed.
- IN-10: `changesDuringReload` is still one unscoped dictionary (lines 52, 171-183). I added a related case to its text.

**Dropped:** WR-07 (fixed). No new findings, so there is no WR-08 or IN-11.

No security issues, crashes or data-loss bugs found. The status stays `issues_found` only because of the four open info items. The fix report notes that WR-05 to WR-07 are tested with a held request, not a real socket, and wants a device check in the phase UAT.

## Info

### IN-06: The "unavailable" banner does not tell the user that pull-to-refresh retries

**File:** `ClickMe2026/Utils/ChatBlockState.swift:126`, `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift:173-180`
**Issue:** WR-02 made pull-to-refresh clear `recipientUnavailable`, but the banner copy is still "This user is unavailable." with no hint. The recovery path exists but a user cannot find it. This was deliberately left as a UX copy decision. The same applies to Android, which ports `BlockState.kt`. I re-checked both locations: the string is unchanged at line 126 and `reload()` still clears the flag (line 176). Still open, deliberately skipped.
**Fix:** Get a copy decision, for example "This user is unavailable. Pull down to try again." Alternatively, clear the flag in `viewDidAppear` after a delay or on socket reconnect.

### IN-08: The WR-06 follow-up fetch swallows its own failure

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:148-150, 163-166`
**Issue:** The follow-up goes through `silentReload()`, which uses `try?`. If that request fails, the list stays at the first response and the new conversation does not appear. Nothing records that it is still missing, and `needsReloadAfterLoad` was already cleared at line 164. The failure is invisible until the next reload (pop-back or pull-to-refresh). That is acceptable for a silent refresh, but it is the same window the WR-06 fix set out to close. Re-checked against the current source: unchanged.
**Fix:** Optional. Set `needsReloadAfterLoad = true` again when the follow-up fails and retry once on the next `viewDidAppear`/`load()`, or accept the gap and note it in the doc comment on `needsReloadAfterLoad`.

### IN-09: iOS and Android now differ on 408 and 429 for a failed chat send

**File:** `ClickMe2026/Utils/ChatThreadReducer.swift:43-60`
**Issue:** iOS keeps the bubble as Failed for 408 and 429 (`retryableStatusCodes`). I checked the Android repo: `ChatThreadViewModel.kt:240` still runs `if (e is ApiException.Http && e.status < SERVER_ERROR_FROM)` with `SERVER_ERROR_FROM = 500` (line 601). Android therefore still removes the bubble and restores the text for 408 and 429. The project rule is that iOS is the source of truth and Android mirrors it, and no Android change has been made. The two clients disagree on the same server response.
**Fix:** Port the 408/429 rule to `ChatThreadViewModel.kt` in the Android repo in its own commit, or record that the divergence is accepted. The doc comment on `sendFailure(for:)` already states the difference.

### IN-10: Recorded row changes are not scoped to the reloads that started before them

**File:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift:171-183`
**Issue:** `changesDuringReload` is one dictionary that lives until `reloadsInFlight` reaches 0. If reload A is in flight when a local change is recorded and reload B then starts, B's response is also overlaid with that change, although B's request was sent after the change and may carry a newer server value (for example a higher unread count after more peer messages reached the server while the socket was down). The local value wins until the last reload ends. The same shape applies within a single reload. A text event recorded while a response is in flight can overwrite a response that already includes a later message the socket has not delivered yet. WR-07 closed only the text-less variant, because the stale text it recorded had no content behind it. The effect is bounded. The records are cleared when the last reload ends, and a later socket event or reload corrects the row. It only shows with a socket gap.
**Fix:** Optional. Give each `fetchChats()` call a sequence number, store the sequence with each record, and apply only the records made after that request started and before its response, which is the shape of the `Session.revision` guard in `ChattingViewModel`.

---

_Reviewed: 2026-11-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
