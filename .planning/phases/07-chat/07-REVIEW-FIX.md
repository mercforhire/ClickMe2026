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

**Earlier passes:** three earlier passes of this command wrote reports that this file replaces. The first fixed WR-01 to WR-04 of the first review (commits 82050a4, 505068c, d9dc9b6, 9f5f35e). The second covered the re-review's WR-05, WR-06 and IN-01 to IN-07 (fix commits f914364, 04962f2, e42d16f, cb412f2, 9c024fd, 500c9a1, 3ac5cfe, aea7ecb; IN-06 was skipped as a copy decision). That second report is committed in git history as d46dbe3, with a title correction in 51c5040. The third fixed WR-07 (commit ccf5304; its report is committed as 988f0b4). This report covers the four Info findings that remained open after that pass: IN-06, IN-08, IN-09 and IN-10 (`fix_scope: all`).

**Summary:**
- Findings in scope: 4 (IN-06, IN-08, IN-09, IN-10; no Critical or Warning findings were open)
- Fixed: 4 (IN-06, IN-08, IN-09, IN-10)
- Skipped: 0 (IN-06 was skipped in this pass for a copy decision, then fixed in a follow-up once the user approved the copy)

Commits were made directly on `main` in each checkout. No worktree or temporary branch was used (per the orchestrator), so none is left behind. No backend file was touched. Two commits are in the Android repo (IN-09 and IN-06), local only, not pushed.

## Fixed Issues

### IN-08: The WR-06 follow-up fetch swallows its own failure

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift`, `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`
**Commit:** 761c1bd (iOS repo)
**Cited lines checked first:** the review cited lines 148-150 and 163-166. The `try?` in `silentReload()` and the early `needsReloadAfterLoad = false` were both still there as described.
**Applied fix:** `silentReload()` no longer uses `try?`. It reads and clears `needsReloadAfterLoad` before it fetches, and if that fetch fails while a follow-up was owed, it sets the flag again. `load()` used to return at once when the list was loaded. It now also calls `silentReload()` when the flag is set, so the next `.task { load() }` retries. `forceLoad()` clears the flag when it starts (its own fetch begins after the message that set the flag) and no longer clears it before the follow-up. A retry that fails again leaves the flag set and waits for the next call, so there is no loop inside one call. The doc comment on `needsReloadAfterLoad` describes the rule.
**Tests added (3, in `ChatConversationsUnreadTests`):**
- `failedFollowUpIsRetriedByNextLoad`: the follow-up gets a 500, the list stays at the first response, the next `load()` lists the new thread, and a further `load()` sends no request.
- `failedRetryDoesNotLoop`: the follow-up and the first retry both fail, and each `load()` then makes exactly one request.
- `refreshCoversFailedFollowUp`: a pull-to-refresh after a failed follow-up fetches once, and the next `load()` adds no request.
**Failed on the old code first:** with the view model reverted and the new tests in place, `ChatConversationsUnreadTests` ran 24 tests and the first two new tests failed (expected 3 GET /chats, got 2, and the new thread was missing). The third passes on both versions, because the old code never retried at all. It guards against an extra fetch.

### IN-09: iOS and Android now differ on 408 and 429 for a failed chat send

**Status:** fixed (Android repo)
**Files modified:** `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatThreadViewModel.kt`, `/Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatThreadViewModelSendTest.kt`
**Commit:** d78f80f8 (Android repo, branch `main`, local only, not pushed): `fix(chat): keep a send that fails with 408 or 429 as a Failed bubble (iOS parity)`
**Cited lines checked first:** `ChatThreadViewModel.kt:240` still read `e.status < SERVER_ERROR_FROM` (500, line 601), as the review said.
**Applied fix:** the check is now `isRefusal(e.status)`, a private companion function that mirrors iOS `ChatThreadReducer.sendFailure(for:)`: a refusal is an HTTP status in 400..499 that is not 408 or 429. Those two, 5xx, transport errors and unreadable responses keep the bubble as Failed with Retry. `SERVER_ERROR_FROM` had no other use and was replaced. One side effect of mirroring iOS exactly: an `ApiException.Http` with a status below 400 (not expected from this API) now keeps the bubble as Failed, where Android used to treat it as a refusal.
**Test added:** `timeoutAndRateLimitKeepTheFailedBubble` in `ChatThreadViewModelSendTest` (408 and 429 each leave one Failed bubble, keep the text on it, leave the composer empty and show no send error). The existing refusal tests (403 THREAD_BLOCKED, 403 RECIPIENT_UNAVAILABLE, 422, 404) are unchanged and still pass.
**Failed on the old code first:** with `ChatThreadViewModel.kt` reverted, `ChatThreadViewModelSendTest` ran 30 tests and `timeoutAndRateLimitKeepTheFailedBubble` failed.
**Staging:** only the two files above were staged. The `.idea/*` and `.planning/*` changes that were already in that repo were left alone.

### IN-10: Recorded row changes are not scoped to the reloads that started before them

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift`, `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`
**Commit:** b1bb1af (iOS repo)
**Cited lines checked first:** the dictionary `changesDuringReload` and `movedToTopDuringReload` were still unscoped, as at the cited lines 171-183.
**Applied fix:** `fetchChats()` takes a number from `fetchCounter` when it starts. `changesDuringReload` is now an ordered list of `LocalRowChange` records. Each carries its thread id and the newest fetch number at the moment it was made, in place of the per-thread dictionary and the separate moved-to-top list. A response applies only the records stamped at or after its own number, with the latest value winning for each field of a row. The moved-to-top order is derived from the same list, newest first. The list is still cleared when `reloadsInFlight` reaches 0. With a single reload the result is the same as before, so the existing WR-04, WR-05 and WR-07 tests pass unchanged.
**Tests added (3, in `ChatConversationsUnreadTests`):**
- `changeBeforeSecondReloadDoesNotReachIt`: markOpened while reload A is out, then reload B starts and the server now says 5. A's answer shows 0, B's shows 5.
- `eachReloadTakesItsOwnChanges`: a markOpened before B started and a live message after it. A's answer takes both, B's takes only the live message.
- `changesEndWithTheLastOverlappingReload`: a change made while two reloads were out is gone once both ended, so the next reload takes the server's count.
The tests read the two answers through a `$chats` recorder, because the second answer arrives right after the first and a test cannot stop between them. The first version of the tests asserted between the answers and was flaky, so I changed it. The mock URL protocol runs one request at a time, so reload B's request waits behind A's held one. B has still started as far as the view model's bookkeeping goes, because the fetch number is taken before the request is sent. A short wait (`letReloadStart`) lets B's task reach that point.
**Failed on the old code first:** with the view model reverted, 27 tests ran and the first two new tests failed (`threadB` count was 0, expected 5). The third passes on both versions and guards the clearing rule.
**Trade-off to confirm on a device:** a reload that starts after `markOpened` no longer gets the local 0, so if the server has not yet processed the read when that request is answered, the pill can reappear on a row for a thread that is open. This is what the review asked for (the server value is the newer one), it only happens with a socket gap, and the next reload corrects it.

### IN-06: The "unavailable" banner does not tell the user that pull-to-refresh retries

**Status:** fixed (follow-up after the user approved the copy on 2026-11-18)
**Files modified:** `ClickMe2026/Utils/ChatBlockState.swift`, `ClickMe2026Tests/Chat/ChatBlockStateTests.swift` (iOS); `app/src/main/res/values/strings_chat_thread.xml`, `app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatThreadViewModel.kt`, `app/src/test/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatThreadScreenTest.kt`, `app/src/test/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatThreadViewModelSendTest.kt` (Android)
**Commit:** fa3bfb5 (iOS repo); 27e024bf (Android repo, branch `main`, local only, not pushed)
**Applied fix:** `ChatBlockState.bannerTitle(for: .unavailable)` now returns "This user is unavailable. Pull down to try again." Only the chat composer banner changed. The other "This user is unavailable." strings (the expert profile block error, the chat entry dialog and the report error) are not the banner and were left as they were. On Android, `chat_banner_unavailable` got the same copy. Android's pull to refresh never cleared `recipientUnavailable` (iOS gained that in WR-02), so the new copy would have promised a recovery Android did not have. The `LoadMode.Pull` branch of `startLoad` now clears the flag when the pull starts, as iOS `ChattingViewModel.reload()` does.
**Tests:** the iOS `ChatBlockStateTests.bannerCopy` assertion was updated, and all 30 tests in that suite pass. On Android, the `ChatThreadScreenTest.bannerForUnavailableRecipient` assertion was updated and `pullToRefreshLiftsTheUnavailableBanner` was added to `ChatThreadViewModelSendTest`. `./gradlew :app:testDevDebugUnitTest --tests '*ChatThread*' --offline` ran 141 tests with no failures.

## Verification

**Where it ran:** all iOS commands ran in the main checkout (`/Users/LeonChen/Documents/ClickMe2026`, branch `main`), not in a worktree, so the results can be reproduced from this tree. Simulator: iPhone 17. The Android Gradle run was in `/Users/LeonChen/Documents/ClickMe_Android`.

- **iOS build:** `xcodebuild -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' build` gave `BUILD SUCCEEDED`. The only warning is the usual `appintentsmetadataprocessor ... Metadata extraction skipped. No AppIntents.framework dependency found.` No new warnings. The `test` runs (which also compile the changed files) showed no other warnings.
- **iOS Chat unit tests:** `xcodebuild ... test` with `-only-testing` for all 13 Chat suites (ChatBlockStateTests, ChatBookingRowRouteTests, ChatComposerRulesTests, ChatConversationsUnreadTests, ChatItemMapperTests, ChatThreadItemDecodingTests, ChatThreadReducerTests, ChattingViewModelOpenTests, ChattingViewModelReadEmitTests, ChattingViewModelSendTests, ChatUnreadRulesTests, ProfileBlockActionTests, ReportChatViewModelTests) on the final code: `Test run with 196 tests in 13 suites passed`, `** TEST SUCCEEDED **`. That is the 190 tests of the previous pass plus 6 new ones (3 for IN-08 and 3 for IN-10). I ran this command three times in a row to check the new timing-sensitive tests, and all three runs passed. (An earlier run, before the recorder change, failed 2 tests by a race in the tests themselves. That is why the tests were changed.)
- **Android:** `./gradlew :app:testDebugUnitTest --tests '*ChatThread*'` does not work in that repo: the task name is ambiguous because of product flavors (`testDevDebugUnitTest` and `testProdDebugUnitTest`). I ran `./gradlew :app:testDevDebugUnitTest --tests '*ChatThread*' --offline` instead. It gave `BUILD SUCCESSFUL`: ChatThreadViewModelSendTest 30 tests, ChatThreadViewModelTest 31, ChatThreadViewModelRealtimeTest 22, ChatThreadScreenTest 52, NavigatorOpenChatThreadTest 5, with 0 failures and 0 errors in each. The `prod` flavor was not run.
- **Not run:** the full iOS unit target, the iOS UI tests, the full Android test suite, and any on-device check. IN-08 and IN-10 are tested with held requests, not a real socket and network, so they belong in the phase UAT together with WR-05 to WR-07 (for example a new conversation arriving while the list loads on a flaky connection, then opening a thread while a reload is out). IN-09 changes what a user sees on a 408 or 429 on Android only.

## Working tree

iOS: only the two Swift files per fix were staged and committed (761c1bd, b1bb1af). `.DS_Store` files, `.planning/config.json`, `.planning/state.json` and `ClickMe2026/Localizable.xcstrings` were already modified or untracked and were left alone. This report is not committed (the orchestrator does that). Android: only the two files for d78f80f8 were staged; the repo's other dirty files were left alone and nothing was pushed.

**Cross-repo note:** the Android change in d78f80f8 is a separate commit in a separate repo and has not been pushed or built into a release.

---

_Fixed: 2026-11-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
