---
phase: 07-chat
fixed_at: 2026-11-18T00:00:00Z
review_path: .planning/phases/07-chat/07-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-11-18
**Source review:** .planning/phases/07-chat/07-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (WR-01 to WR-04; IN-* left alone as instructed)
- Fixed: 4
- Skipped: 0

All four findings are fixed on `main` as four atomic commits, one per finding, after a fast-forward from the isolated review-fix worktree. No fix needed a backend change.

## Fixed Issues

### WR-01: A stale `GET /chats` scan can undo a block or unblock that finished while it was running

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Utils/ChatBlockState.swift`, `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift`, `ClickMe2026Tests/Chat/ChatBlockStateTests.swift`, `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift`
**Commit:** 82050a4
**Applied fix:**
- `ChatBlockState.Session` has a new `revision` counter. It moves on `adopt`, `applyUnblockSucceeded`, a `NOT_BLOCKER` `applyUnblockFailure` and a handled `applySendRefusal`. It does not move on a scan or on an unhandled refusal.
- `refreshThreadInfo()` captures `revision` before the `GET /chats` scan and drops the block flags when it changed. `peerUserId` is still taken from a listed thread, because the partner id cannot go stale.
- `Session.applyScan(found:)` now sets `sessionBlockedByMe = found.isBlocked && found.blockedByMe` when the thread is listed, so a peer block seen by a scan is not later read as mine on a scan miss.
- Tests: three `Session` tests (revision moves, revision ignores scans, `sessionBlockedByMe` resets), and one view-model test that holds a scan in flight, adopts a block, releases the scan and checks the block survives.
- One deviation from the suggested fix: a failed unblock only bumps the revision when it changes state (`NOT_BLOCKER`). Other failures change nothing, so there is nothing for a scan to undo.

### WR-02: `recipientUnavailable` is never cleared, so the composer stays disabled until the screen is rebuilt

**Status:** fixed: requires human verification (state handling)
**Files modified:** `ClickMe2026/Utils/ChatBlockState.swift`, `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift`, `ClickMe2026Tests/Chat/ChatBlockStateTests.swift`, `ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift`
**Commit:** 505068c
**Applied fix:** Added `Session.clearRecipientUnavailable()`. `ChattingViewModel.reload()` (the pull-to-refresh path in `ChattingView`) calls it first. A person who is still unavailable is refused again by the server on the next send. A block still wins over the cleared flag. Tests cover both the `Session` method and the view-model reload path.
**Not done:** The review also offered `viewDidAppear` as a place to clear the flag. I used `reload()` only, because `viewDidAppear` also fires when returning from the profile or Report & Block, where silently dropping the banner would be surprising. The banner text still gives no hint that a pull-to-refresh retries. That is a copy and UX decision, so I left it.

### WR-03: Socket.IO client logging is on in all builds and logs message traffic

**Files modified:** `ClickMe2026/Realtime/RealtimeService.swift`
**Commit:** d9dc9b6
**Applied fix:** `.log(true)` is now `.log(socketLogging)`, where `socketLogging` is `true` under `#if DEBUG` and `false` otherwise. No unit test was added, because the setting lives inside the socket manager construction and has no observable seam. The Debug build compiled the `DEBUG` branch. I did not build Release.

### WR-04: Chats list reloads can overwrite local unread changes and double-fetch during the first load

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift`, `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`
**Commit:** 9f5f35e
**Applied fix:**
- (1) Overwrite race: `forceLoad` and `silentReload` now go through one `fetchChats()` helper. It counts reloads in flight. `markOpened` and `handleMessageNew` record the local unread count while a reload is in flight, and `fetchChats()` applies those counts over the server's for the same rows. The records are cleared when the last reload ends, so the next reload takes the server's count again. This is the "merge" option from the review; only the unread count is kept, not the whole local row.
- (2) Double fetch: `handleMessageNew` for an unknown thread now returns early unless `loadState == .loaded`, because the pending first load already returns that message. This also stops an incoming message from silently re-triggering a load in the `.failed` state.
- Tests: a late reload after `markOpened`, a late reload after a live peer message, overrides ending with the reload, and an unknown-thread event before the first load starting no request.

## Skipped Issues

None.

## Verification

**Where it ran:** an isolated git worktree at `.claude/worktrees/rf-07-1` (branch `gsd-reviewfix/07-1`), not the main checkout. The gitignored `ClickMe2026/Debug/PreviewSecrets.swift` was copied in so the app target compiled. The worktree commits were fast-forwarded onto `main`, then the worktree, temp branch and recovery sentinel were removed. The numbers below come from the worktree's tree, which is identical in the touched files to `main` at commit 9f5f35e. The worktree is gone, so they are not reproducible from it. I did not re-run them in the main checkout, which also holds the unrelated uncommitted changes.

- **Build:** `xcodebuild -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' build -quiet` after the WR-03 change succeeded, with no errors. I saw no warnings in the touched files in the build or test logs. This is a search of the logs for those files, not a diff against a baseline warning count.
- **Tests:** after the last fix I ran `ChatBlockStateTests`, `ChattingViewModelOpenTests`, `ChattingViewModelSendTests`, `ChatConversationsUnreadTests`, `ChattingViewModelReadEmitTests` and `ChatThreadReducerTests`. 124 tests in 6 suites passed. I did not run the full suite, the other Chat suites (such as `ChatUnreadRulesTests` and `ReportChatViewModelTests`), or any UI tests.
- **Test caveat:** the new in-flight tests hold a stubbed response with a semaphore (5 second cap) so they can change state while a request runs. They pass reliably here, but they depend on `MockURLProtocol` running its handler off the main actor.

## Left for the orchestrator and the developer

- The unrelated working-tree changes (`.DS_Store` files, `.planning/config.json`, `ClickMe2026/Localizable.xcstrings`, `.planning/milestone.lock`, `.planning/state.json`) were not staged or committed.
- `07-REVIEW-FIX.md` is not committed; the orchestrator handles that.
- Android: the review notes `BlockState.kt` was the source of the block-state port. WR-01 and WR-02 likely apply to the Android port too, and no change was made there.

---

_Fixed: 2026-11-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
