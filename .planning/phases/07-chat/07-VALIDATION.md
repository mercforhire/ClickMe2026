---
phase: "07"
slug: "chat"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| CHAT-01 | Reducer: append, ack keeps the bubble id, fail, retry, remove, `mergePage` by serverId then clientMsgId, Read never regresses, order | unit (pure) | `ChatThreadReducerTests` | ❌ W0 | ⬜ pending |
| CHAT-01 | Send: pending first; URLError/5xx → Failed; retry reuses the same `client_msg_id`; ack in place; 4xx → removed, text restored, alert | unit (stubbed, serialized) | `ChattingViewModelSendTests` | ❌ W0 | ⬜ pending |
| CHAT-01 | A reload keeps pending and failed bubbles | unit (stubbed) | `ChattingViewModelSendTests` | ❌ W0 | ⬜ pending |
| CHAT-01 / D-04 | Cap of 10,000 UTF-16 units, emoji never split, counter shown from 9,000 | unit (pure) | `ChatComposerRulesTests` | ❌ W0 | ⬜ pending |
| CHAT-02 | Report `reason == rawValue` for all six cases; details capped at 1,000 UTF-16 units and trimmed; 429 mapping | unit (stubbed, serialized) | `ReportChatViewModelTests` | ❌ W0 | ⬜ pending |
| CHAT-03 | `ChatBlockState` matrix, transitions, NOT_BLOCKER, legacy, scan miss, blocked beats unavailable | unit (pure) | `ChatBlockStateTests` | ❌ W0 | ⬜ pending |
| CHAT-03 | `ChatThreadItem` decodes with `blocked_by_me` missing → false | unit | `ChatThreadItemDecodingTests` | ❌ W0 | ⬜ pending |
| CHAT-03 | THREAD_BLOCKED / RECIPIENT_UNAVAILABLE on send → banner, bubble removed, rescan | unit (stubbed) | `ChattingViewModelSendTests` | ❌ W0 | ⬜ pending |
| CHAT-04 | Profile block: initiate, then actions block, in order and once; 404 → unavailable copy; repeat taps ignored | unit (stubbed, serialized) | `ProfileBlockActionTests` | ❌ W0 | ⬜ pending |
| CHAT-04 | Block copy makes no profile or booking claim | grep gate | `! grep -rniE "see your profile\|book appointments" ClickMe2026/Views/Screens/Chat "ClickMe2026/Views/Screens/Client Mode/Expert Profile"` | n/a | ⬜ pending |
| CHAT-05 | `peerUserId` is set on open before any message; admin rows never set it | unit (stubbed) | `ChattingViewModelOpenTests` | ❌ W0 | ⬜ pending |
| CHAT-06 | `loadEarlier` overlapping page 1 adds only new rows | unit | `ChatThreadReducerTests`, `ChattingViewModelOpenTests` | ❌ W0 | ⬜ pending |
| CHAT-07 | Badge `99+`, VoiceOver label, hidden at 0; open → 0; peer message → +1 and moves to top; open thread or own message → no +1 | unit | `ChatUnreadRulesTests`, `ChatConversationsUnreadTests` | ❌ W0 | ⬜ pending |
| D-16 | Read ids emitted once per page, held until the socket connects | unit | `ChattingViewModelReadEmitTests` | ❌ W0 | ⬜ pending |
| D-18 | Booking-row route: expert shell → `.expertBookingSummary`; client shell keeps its routes | unit (pure) | `ChatBookingRowRouteTests` | ❌ W0 | ⬜ pending |
| CHAT-08 | "Read" label updates live between two devices | manual | Device UAT row C6 | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ClickMe2026Tests/Chat/` folder with the suites above (no chat tests exist today)
- [ ] `ChattingViewModel` test seams: identity injection (`myUserId`, `myName`), an injectable read-emit closure, and `internal` incoming-event handlers
- [ ] `ChatConversationsViewModel` seams: `internal` incoming-message and open-thread entry points
- [ ] `ChatFixtures` helper for `GET /chats` and `GET /chats/:id/messages` JSON
- [ ] Framework install: none needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "Read" label updates live while a chat is open | CHAT-08 | Needs realtime between two accounts on two devices | Device UAT C6: A sends, B opens the thread, and A sees "Read" with no reload |
| Pending → Failed → Retry on a real dead network | CHAT-01 | Real network conditions | Device UAT C1: turn on airplane mode, send, wait for Failed, reconnect, then Retry |
| Block banner on both sides; only the blocker sees Unblock | CHAT-03 | Two accounts | Device UAT: A blocks B, then check both devices |
| Unread badge appears and clears live | CHAT-07 | Realtime | Device UAT: B sends while A is on the Chats list |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 240s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
