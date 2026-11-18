---
phase: 07-chat
fixed_at: 2026-11-18T00:00:00Z
review_path: .planning/phases/07-chat/07-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 8
skipped: 1
status: partial
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-11-18
**Source review:** .planning/phases/07-chat/07-REVIEW.md
**Iteration:** 1

**Earlier pass:** an earlier pass of this command fixed WR-01 to WR-04 of the first review (commits 82050a4, 505068c, d9dc9b6, 9f5f35e) and wrote a report that this file replaces. This report covers the re-review's findings: WR-05, WR-06 and IN-01 to IN-07.

**Summary:**
- Findings in scope: 9 (WR-05, WR-06, IN-01 to IN-07)
- Fixed: 8
- Skipped: 1 (IN-06)

All fixes are committed directly on `main` in this checkout, one commit per finding. No worktree or temporary branch was used, so none is left behind. No fix needed a backend change, and no backend file was touched.

## Fixed Issues

### WR-05: A late `GET /chats` still replaces the live row's preview, time and order, and a `markOpened` on a row that is not listed yet is lost (incomplete fix of WR-04, part 1)

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift`, `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`
**Commit:** f914364
**Applied fix:** `unreadSetDuringReload` became `changesDuringReload`, a per-thread record of unread count, last message and time label, plus `movedToTopDuringReload` (newest first). `fetchChats()` applies them over the server rows through `applyLocalChanges(to:)`, and moves the touched rows to the top. Only the three fields a live message changes are overlaid, so the server's name, avatar and online state still win. `markOpened` now records the open before its `guard`, so an open during the first load (row not listed yet) is kept. All of it is cleared when the last in-flight reload ends.
**Tests added:** late reload keeps the live preview, time label and top position; two live messages keep the newest on top; `markOpened` during the first load keeps the row at 0. I ran these three against the old code and all three failed.

### WR-06: A new conversation's first message is dropped if it arrives while a load is in flight (regression from the WR-04 part 2 fix)

**Status:** fixed: requires human verification (race/state logic)
**Files modified:** `ClickMe2026/Views/Screens/Chat/Conversations/ChatConversationsViewModel.swift`, `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`
**Commit:** 04962f2
**Applied fix:** `needsReloadAfterLoad` is set when an unknown thread's message arrives while `loadState == .loading` (first load or pull-to-refresh). `forceLoad()` runs one `silentReload()` after a successful load and clears the flag on failure. This differs from the review's suggestion in one way: the flag is set only while `.loading`, not for `.idle` or `.failed`, because the next `load()` fetches the message anyway and a flag set while idle would cause a needless extra request later.
**Tests added:** follow-up fetch after the first load; follow-up fetch after a pull-to-refresh; no follow-up on a plain load; the flag is dropped when the load fails. The gate helper in the unread suite now snapshots the response body before it waits, as a real server would, so a body swapped mid-request reaches only the follow-up fetch.

### IN-01: `sendFailure` treats every 4xx as a permanent refusal, including 401, 408 and 429

**Status:** fixed
**Files modified:** `ClickMe2026/Utils/ChatThreadReducer.swift`, `ClickMe2026Tests/Chat/ChatThreadReducerTests.swift`
**Commit:** e42d16f
**Applied fix:** 408 and 429 now return `.keepAsFailed`, so the Retry affordance stays. The send is idempotent on `client_msg_id`, so retry is safe. Backend contract checked first: `POST /chats/{id}/send` in `openapi/clickme-api.yaml` and `src/controllers/chats.controller.js` document and emit only 401, 403, 404 and 422, and `src/routes/chats.js` has no rate limiter on the route. So 408 and 429 can only come from infrastructure, and no backend change is needed. 401 stays a refusal, because by then the refresh interceptor has failed and session handling logs the user out. The doc comments on `SendFailure.refused` and `sendFailure(for:)` now list the real refusal codes and say that iOS differs from Android's "everything below 500" rule here.
**Cross-repo note:** Android (`ChatThreadViewModel.kt`, `SERVER_ERROR_FROM = 500`) still treats 408 and 429 as a refusal. This is a small, safe divergence. Say so if parity matters and Android should follow.
**Tests added:** 408 and 429 keep the bubble; 409 and 428 stay refusals; a 404 maps to `.refused(.notFound)`.

### IN-02: `.timestamp` rows would be moved to the end by `ChatThreadReducer.order`

**Status:** fixed (comment only)
**Files modified:** `ClickMe2026/Utils/ChatThreadReducer.swift`, `ClickMe2026/Model/UIModels/ChatDisplayModels.swift`
**Commit:** cb412f2
**Applied fix:** Added a note to the `order` doc comment and to `ChatItem.timestamp`: separators have no server id and sort after the server rows, so live separators belong at render time. The colliding `ts_<label>` id is mentioned too. No behavior change.

### IN-03: `Int(d)` in `extractInt` can trap on an out-of-range double

**Status:** fixed
**Files modified:** `ClickMe2026/Utils/ChatItemMapper.swift`, `ClickMe2026Tests/Chat/ChatItemMapperTests.swift` (new)
**Commit:** 9c024fd
**Applied fix:** `Int(exactly: d)`. A fractional, NaN, infinite or out-of-range double now reads as nil, and the row still maps. A new test file covers whole numbers and the four bad doubles. It is a new file because no mapper test file existed.

### IN-04: Empty accessibility label on non-pending bubble containers

**Status:** fixed
**Files modified:** `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift`
**Commit:** 500c9a1
**Applied fix:** `.accessibilityLabel(Text(verbatim: ...), isEnabled: isPending)`. The label is applied only while the bubble is pending, and the view identity does not change when the send is acknowledged. `Text(verbatim:)` keeps the string out of the localization catalog, as before. There is no unit test for this, because it is a SwiftUI modifier. It needs a VoiceOver check on a device.

### IN-05: Test timing helpers hide failures and one negative check is a fixed sleep

**Status:** fixed
**Files modified:** `ClickMe2026Tests/Support/WaitUntil.swift` (new), `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`, `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift`
**Commit:** aea7ecb
**Applied fix:** One shared `waitUntil(_:timeout:sourceLocation:_:)` records an `Issue` at the call site when it times out. Call sites got a short description. The two fixed 50 ms negative checks (`viewDidAppearScansOnlyOnceLoaded` and the unknown-thread-before-first-load test) no longer sleep. They call the action, then `await load()`, then assert that the request count is exactly one. A stray scan or reload would run while `load()` awaits its request and add a second request. Both suites carry a doc comment that they rely on the non-parallel test plan.

### IN-07: Two copies of the test `Gate` helper that behave differently

**Status:** fixed
**Files modified:** `ClickMe2026Tests/Support/RequestGate.swift` (new), `ClickMe2026Tests/Chat/ChatConversationsUnreadTests.swift`, `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift`
**Commit:** 3ac5cfe
**Applied fix:** One `RequestGate` whose `open()` disarms the gate and releases the waiting request. Both suites use it and the private copies are gone.

## Skipped Issues

### IN-06: The "unavailable" banner does not tell the user that pull-to-refresh retries

**File:** `ClickMe2026/Utils/ChatBlockState.swift:126`, `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift:173-180`
**Reason:** skipped: needs a product copy decision, not a code change. The review itself says "Get a copy decision". The string `This user is unavailable.` is specified word for word in the phase plan (07-04-PLAN.md), asserted in `ChatBlockStateTests`, equal to the server's message, and mirrored in Android's `chat_banner_unavailable`. The string is a plain Swift literal and is not in `Localizable.xcstrings`, so the catalog would not have been touched, and that was not the reason for skipping. Suggested copy from the review: "This user is unavailable. Pull down to try again." If approved, change it in `ChatBlockState.bannerTitle(for:)`, update the one assertion in `ChatBlockStateTests`, and change the Android string in the same step.
**Original issue:** WR-02 made pull-to-refresh clear `recipientUnavailable`, but the banner copy gives no hint that this recovery path exists.

## Verification

All commands ran in the main checkout (`/Users/LeonChen/Documents/ClickMe2026`, branch `main`), not in a worktree, so the results can be reproduced from this tree. Simulator: iPhone 17.

- **Build:** `xcodebuild -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' build` gave BUILD SUCCEEDED, with no warnings beyond the usual "Metadata extraction skipped. No AppIntents.framework dependency" notice. The commit-by-commit builds and test runs also compiled with no new warnings in the changed files.
- **Chat unit tests:** all 13 suites in `ClickMe2026Tests/Chat/` plus the `ProfileBlockActionTests` and `ReportChatViewModelTests` suites ran together: 189 tests in 13 suites, all passed. The suites were ChatBlockStateTests, ChatComposerRulesTests, ChatBookingRowRouteTests, ChatConversationsUnreadTests (20 tests), ChatItemMapperTests (new, 2 tests), ChatThreadItemDecodingTests, ChatThreadReducerTests, ChattingViewModelReadEmitTests, ChatUnreadRulesTests, ChattingViewModelSendTests, ReportChatViewModelTests, ChattingViewModelOpenTests and ProfileBlockActionTests.
- **Not run:** the full unit target, the UI tests, and any on-device check. IN-04 (VoiceOver) and the race fixes WR-05 and WR-06 (tested with a held request, not with a real socket and network) should be checked on a device in the phase UAT.

## Working tree

Only the files listed above were staged. `ClickMe2026/Localizable.xcstrings`, `.planning/config.json`, `.planning/milestone.lock`, `.planning/state.json` and the `.DS_Store` files were already modified or untracked and were left alone. `git worktree list` shows only the main checkout, and no `gsd-reviewfix/*` branch exists.

---

_Fixed: 2026-11-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
