---
phase: "07"
slug: "chat"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-17"
---

# Phase 07 — Validation Strategy

> The validation contract for this phase: how each task's work gets tested while it runs.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests`; `MockURLProtocol` for HTTP |
| **Config file** | `ClickMe2026/AllTests.xctestplan` (file-system-synchronized test group, so new files under `ClickMe2026Tests/` need no project edit) |
| **Quick run command** | `cd /Users/LeonChen/Documents/ClickMe2026 && set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| **Full suite command** | Same, with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests` and `MakeABookingAvailabilityTests.swift` added to `EXCLUDED_SOURCE_FILE_NAMES` (a known flaky suite). Never run the smoke suites, because they hit production |
| **Build gate** | `xcodebuild build ... -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` must print `BUILD SUCCEEDED` and add no new warnings in touched files (compare before and after with `comm -13`) |
| **Estimated runtime** | About 2–4 min per single-suite run; 4–8 min for the full suite |

Rules:
- A run counts only if its test count is above zero.
- `MockURLProtocol` suites are `.serialized`.
- A task runs one suite per `xcodebuild` call.
- Suites that never call the API must not use `APITestFactory`.

---

## Sampling Rate

- **After every task commit:** Run the quick command for the one suite covering the type you touched
- **After every plan wave:** Run the suites the wave touched, the build gate, and the regression suites `PushForegroundPolicyTests`, `HomeNavigationPathTests`, `ToastCenterTests` and `ExpertBookingNoteViewModelTests`
- **Before `/gsd-verify-work`:** The full suite is green, the grep gates pass, and device UAT C1–C10 have been run
- **Max feedback latency:** ~240 seconds

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Suite / Command | File Exists | Status |
|--------|----------|-----------|-----------------|-------------|--------|
| CHAT-01 | Reducer: append, ack keeps the bubble id, fail, retry, remove, `mergePage` by serverId then clientMsgId, Read never regresses, order | unit (pure) | `ChatThreadReducerTests` | ✅ exists | ✅ green |
| CHAT-01 | Send: pending first; URLError/5xx → Failed; retry reuses the same `client_msg_id`; ack in place; 4xx → removed, text restored, alert | unit (stubbed, serialized) | `ChattingViewModelSendTests` | ✅ exists | ✅ green |
| CHAT-01 | A reload keeps pending and failed bubbles | unit (stubbed) | `ChattingViewModelSendTests` | ✅ exists | ✅ green |
| CHAT-01 / D-04 | Cap of 10,000 UTF-16 units, emoji never split, counter shown from 9,000 | unit (pure) | `ChatComposerRulesTests` | ✅ exists | ✅ green |
| CHAT-02 | Report `reason == rawValue` for all six cases; details capped at 1,000 UTF-16 units and trimmed; 429 mapping | unit (stubbed, serialized) | `ReportChatViewModelTests` | ✅ exists | ✅ green |
| CHAT-03 | `ChatBlockState` matrix, transitions, NOT_BLOCKER, legacy, scan miss, blocked beats unavailable | unit (pure) | `ChatBlockStateTests` | ✅ exists | ✅ green |
| CHAT-03 | `ChatThreadItem` decodes with `blocked_by_me` missing → false | unit | `ChatThreadItemDecodingTests` | ✅ exists | ✅ green |
| CHAT-03 | THREAD_BLOCKED / RECIPIENT_UNAVAILABLE on send → banner, bubble removed, rescan | unit (stubbed) | `ChattingViewModelSendTests` | ✅ exists | ✅ green |
| CHAT-04 | Profile block: initiate, then actions block, in order and once; 404 → unavailable copy; repeat taps ignored | unit (stubbed, serialized) | `ProfileBlockActionTests` | ✅ exists | ✅ green |
| CHAT-04 | Block copy makes no profile or booking claim | grep gate | `! grep -rniE "see your profile\|book appointments" ClickMe2026/Views/Screens/Chat "ClickMe2026/Views/Screens/Client Mode/Expert Profile"` | n/a | ✅ green |
| CHAT-05 | `peerUserId` is set on open before any message; admin rows never set it | unit (stubbed) | `ChattingViewModelOpenTests` | ✅ exists | ✅ green |
| CHAT-06 | `loadEarlier` overlapping page 1 adds only new rows | unit | `ChatThreadReducerTests`, `ChattingViewModelOpenTests` | ✅ exists | ✅ green |
| CHAT-07 | Badge `99+`, VoiceOver label, hidden at 0; open → 0; peer message → +1 and moves to top; open thread or own message → no +1 | unit | `ChatUnreadRulesTests`, `ChatConversationsUnreadTests` | ✅ exists | ✅ green |
| D-16 | Read ids emitted once per page, held until the socket connects | unit | `ChattingViewModelReadEmitTests` | ✅ exists | ✅ green |
| D-18 | Booking-row route: expert shell → `.expertBookingSummary`; client shell keeps its routes | unit (pure) | `ChatBookingRowRouteTests` (plan 07-09, runs after the 07-08 gate) | ✅ exists | ✅ green |
| CHAT-01 | Retry reuses the same `client_msg_id` once per bubble; delete a failed bubble locally; counter and cap rules | unit (stubbed, serialized) | `ChattingViewModelSendTests`, `ChatComposerRulesTests` | ✅ exists | ✅ green |
| CHAT-03 | Thread open scan, unblock outcomes (success, NOT_BLOCKER, server and transport error, repeat tap), self-thread | unit (stubbed, serialized) | `ChattingViewModelOpenTests` | ✅ exists | ✅ green |
| CHAT-03 / CHAT-04 | Report & Block screen: block, unblock, NOT_BLOCKER and stale-lookup outcomes handed back to the thread | unit (stubbed, serialized) | `ReportChatViewModelTests` | ✅ exists | ✅ green |
| CHAT-01 to CHAT-07 | Phase gate: the full unit suite, one invocation, 1168 tests in 107 suites; Debug build; Phase 7 grep gates; `ChattingViewModel.swift` at 624 lines | full suite + build + grep | Plan 07-08 Task 1 (`/tmp/07-08-full.log`, `/tmp/07-08-build.log`) | ✅ exists | ✅ green |
| CHAT-03 / WR-01 | A late `GET /chats` scan is dropped after the block state changed (revision counter on `ChatBlockState.Session`); a listed thread resets `sessionBlockedByMe` | unit (pure + stubbed, serialized) | `ChatBlockStateTests`, `ChattingViewModelOpenTests` | ✅ exists | ✅ green |
| CHAT-03 / WR-02 | Pull-to-refresh clears `recipientUnavailable` | unit (pure + stubbed) | `ChatBlockStateTests`, `ChattingViewModelSendTests` | ✅ exists | ✅ green |
| WR-03 | Socket.IO client logging is on in DEBUG builds only | grep gate | `grep -n -A4 "#if DEBUG" ClickMe2026/Realtime/RealtimeService.swift` shows `socketLogging = true` / `#else` / `false`, and `.log(socketLogging)` is the only `.log(` call | n/a | ✅ green |
| CHAT-07 / WR-04, WR-05 | Local unread count, last message, time label and top position win over a late `GET /chats`; `markOpened` during the first load is kept | unit (stubbed, serialized, `RequestGate`) | `ChatConversationsUnreadTests` | ✅ exists | ✅ green |
| CHAT-07 / WR-06 | An unknown thread's message during a load triggers exactly one follow-up fetch (first load and pull-to-refresh); none on a plain load; flag dropped on failure | unit (stubbed, serialized, `RequestGate`) | `ChatConversationsUnreadTests` | ✅ exists | ✅ green |
| CHAT-01 / IN-01 | 408 and 429 keep the bubble as Failed; 409 and 428 stay refusals; 404 → `.refused(.notFound)` | unit (pure) | `ChatThreadReducerTests` | ✅ exists | ✅ green |
| IN-03 | `extractInt` reads whole doubles and returns nil for fractional, NaN, infinite and out-of-range values without trapping | unit (pure) | `ChatItemMapperTests` | ✅ exists | ✅ green |
| CHAT-01 to CHAT-07 | Post-review regression gate: the full unit suite, one invocation, 1192 tests in 109 suites, `** TEST SUCCEEDED **`, at HEAD `024899e` (last app commit `aea7ecb`) | full suite | `/tmp/07-validate-full.log` (2026-11-18 re-audit) | ✅ exists | ✅ green |
| CHAT-08 | "Read" label updates live between two devices | manual | Device UAT row C6 (checklist item 11) | n/a | ✅ green (UAT 2026-11-19) |
| IN-04 | A delivered bubble is not read by VoiceOver as pending (label attached only while pending) | manual | VoiceOver pass, backlog 999.5 | n/a | ⬜ pending (deferred) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `ClickMe2026Tests/Chat/` folder with the suites above (no chat tests exist today)
- [x] `ChattingViewModel` test seams: identity injection (`myUserId`, `myName`), an injectable read-emit closure, and `internal` incoming-event handlers
- [x] `ChatConversationsViewModel` seams: `internal` incoming-message and open-thread entry points
- [x] `ChatFixtures` helper for `GET /chats` and `GET /chats/:id/messages` JSON
- [x] Framework install: none needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "Read" label updates live while a chat is open | CHAT-08 | Needs realtime between two accounts on two devices | Device UAT C6: A sends, B opens the thread, and A sees "Read" with no reload |
| Pending → Failed → Retry on a real dead network | CHAT-01 | Real network conditions | Device UAT C1: turn on airplane mode, send, wait for Failed, reconnect, then Retry |
| Block banner on both sides; only the blocker sees Unblock | CHAT-03 | Two accounts | Device UAT: A blocks B, then check both devices |
| Unread badge appears and clears live | CHAT-07 | Realtime | Device UAT: B sends while A is on the Chats list |
| Live row kept over a refresh; new thread's first message during a refresh; pill stays cleared (WR-05, WR-06) | CHAT-07 | Real socket plus a reload in flight | Device UAT test 6, steps 1-3: passed 2026-11-19 |
| Unavailable recipient re-enabled by pull-to-refresh (WR-02) | CHAT-03 | Needs an unavailable test account | Device UAT test 6, step 4: not run (no such account); unit tests cover it |
| VoiceOver: failed bubble actions, counter at the cap, banners, profile Block overlay, unread row, and IN-04 (a delivered bubble is not read as pending) | CHAT-01, CHAT-03, CHAT-04, CHAT-07 | Needs VoiceOver on a device | Checklist item 12 plus the VoiceOver parts of items 3, 4 and test 6: deferred to backlog 999.5 |

Device UAT result (07-UAT.md, 2026-11-19): 6 passed, 0 issues. Only the VoiceOver checks (backlog 999.5) and the WR-02 device step are still open.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-11-18 by plan 07-08 on the green phase gate: full suite 1168 tests in 107 suites passed at HEAD `003aff8` (last Phase 7 app commit `7452bc0`), evidence committed in `8fdc9fd`. `status` stays `draft` and the Manual-Only rows stay pending for `/gsd-verify-work 07`; the D-18 row is closed by plan 07-09.

**Re-audit 2026-11-18 (after the code-review fixes `82050a4..aea7ecb`):** every fix that can be unit tested has tests in the suites listed above (WR-01, WR-02, WR-04, WR-05, WR-06, IN-01, IN-03; IN-05 and IN-07 are test-support changes, and IN-02 only changes comments). WR-03 is checked by a grep gate. IN-04 is a SwiftUI modifier and needs the VoiceOver check deferred to backlog 999.5. The full unit suite passed: 1192 tests in 109 suites at HEAD `024899e`. No new Nyquist gaps were found, so no tests were generated.

## Validation Audit 2026-11-18

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

## Validation Audit 2026-11-19

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
