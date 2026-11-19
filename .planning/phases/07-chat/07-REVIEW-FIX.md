---
phase: 07-chat
fixed_at: 2026-11-18T00:00:00Z
review_path: .planning/phases/07-chat/07-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-11-18
**Source review:** .planning/phases/07-chat/07-REVIEW.md
**Iteration:** 1

**Earlier passes:** two earlier passes of this command wrote reports that this file replaces. The first fixed WR-01 to WR-04 of the first review (commits 82050a4, 505068c, d9dc9b6, 9f5f35e). The second covered the re-review's WR-05, WR-06 and IN-01 to IN-07 (fix commits f914364, 04962f2, e42d16f, cb412f2, 9c024fd, 500c9a1, 3ac5cfe, aea7ecb; IN-06 was skipped as a copy decision). That second report is committed in git history as d46dbe3, with a title correction in 51c5040. This report covers the latest re-review: WR-07.

**Summary:**
- Findings in scope: 1 (WR-07)
- Fixed: 1
- Skipped: 0

Out of scope for `fix_scope: critical_warning` (Info findings, not attempted and not skipped): IN-06, IN-08, IN-09, IN-10. They stay open in 07-REVIEW.md.

The fix is committed directly on `main` in this checkout. No worktree or temporary branch was used (per the orchestrator), so none is left behind. No backend change was needed and no backend file was touched.

## Fixed Issues

### WR-07: A live message without text content makes the late-reload overlay replace the server's newer preview with the stale local one (regression from the WR-05 fix)

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift`, `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`, `ClickMe2026Tests/Support/ChatFixtures.swift`
**Commit:** ccf5304
**Cited lines checked first:** the cited lines still matched the review (`noteLocalActivity` at 215-222, `lastMessage: event.content ?? existing.lastMessage` at 258), so the review's suggestion applied as written.
**Applied fix:** `noteLocalActivity(_:hasContent:)` records `LocalRowChange.lastMessage` only when `hasContent` is true. `handleMessageNew` passes `event.content != nil`. The time label, top position and unread count are still recorded for a text-less message, so the row still moves to the top and counts as unread, but a newer preview from the server is no longer overwritten by the old local text. The doc comment on `noteLocalActivity` says why.
**Tests added:** `lateReloadKeepsServerPreviewForTextlessEvent` in `ChatConversationsUnreadTests`. The first load lists B with no preview. The server body is then swapped to a page where B has `last_message: "newer on the server"`, and the reload is held on the gate. An event with `content: nil` arrives for B, then the gate opens. The test asserts that B is first, that its `lastMessage` is the server's, that its time label is set and that its unread count is 3 (server 2 plus the live message). To write it, the `event` helper now takes `content: String?` (default unchanged: "hello"), and `ChatFixtures.thread` got an optional `lastMessage` parameter (default nil, so existing callers are unchanged).
**Failed on the old code first:** I ran `ChatConversationsUnreadTests` with only the test and fixture changes in place. It ran 21 tests, 20 passed, and the new test failed with `Expectation failed: (viewModel.chats.first?.lastMessage → "") == "newer on the server"`. That is the stale-preview override the review describes. After the fix it passes.

## Verification

All commands ran in the main checkout (`/Users/LeonChen/Documents/ClickMe2026`, branch `main`), not in a worktree, so the results can be reproduced from this tree. Simulator: iPhone 17.

- **Build:** `xcodebuild -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' build` gave BUILD SUCCEEDED. The only warning is the usual `appintentsmetadataprocessor ... Metadata extraction skipped. No AppIntents.framework dependency found.` notice. No new warnings.
- **Old-code check:** `test -only-testing:ClickMe2026Tests/ChatConversationsUnreadTests` before the fix: 21 tests, 1 failed (the new test), `** TEST FAILED **`.
- **Chat unit tests after the fix:** `xcodebuild ... test` with `-only-testing` for all 13 Chat suites (ChatBlockStateTests, ChatBookingRowRouteTests, ChatComposerRulesTests, ChatConversationsUnreadTests, ChatItemMapperTests, ChatThreadItemDecodingTests, ChatThreadReducerTests, ChattingViewModelOpenTests, ChattingViewModelReadEmitTests, ChattingViewModelSendTests, ChatUnreadRulesTests, ProfileBlockActionTests, ReportChatViewModelTests): `Test run with 190 tests in 13 suites passed`, `** TEST SUCCEEDED **`. That is the 189 tests of the earlier pass plus the new one.
- **Not run:** the full unit target, the UI tests, and any on-device check. The overlay logic is tested with a held request, not with a real socket and network, so WR-05 to WR-07 should be checked on a device in the phase UAT (for example a non-text message arriving while the list reloads).

## Working tree

Only the three files listed above were staged and committed. `ClickMe2026/Localizable.xcstrings`, `.planning/config.json`, `.planning/state.json` and the `.DS_Store` files were already modified or untracked and were left alone. This report is not committed (the orchestrator does that).

---

_Fixed: 2026-11-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
