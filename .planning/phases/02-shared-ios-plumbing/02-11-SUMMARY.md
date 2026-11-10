---
phase: 02-shared-ios-plumbing
plan: 11
subsystem: push-presentation
tags: [push, foreground, willPresent, UNNotificationPresentationOptions, chat, presence, swift-testing, tdd]

requires:
  - phase: 02-shared-ios-plumbing
    provides: plan 02-10's non-failable PushEvent(userInfo:) with category and threadId, and PushRouter.handleForegroundArrival
provides:
  - PushForegroundPolicy.options(for:visibleChatThreadId:), a pure decision that returns no presentation options only for a message push whose thread_id equals the chat on screen, and the full set otherwise
  - ChatPresence.shared with visibleThreadId, chatAppeared(threadId:) and chatDisappeared(threadId:), the latter clearing only its own thread
  - ChatView reports itself in onAppear and onDisappear when its view model has a thread id
  - willPresent completes with the policy's options after the unconditional handleForegroundArrival tick
  - PushForegroundPolicyTests (12 rows, serialized) covering the policy matrix and the stacked-chat presence rule
affects: [02-12 logout and the device UAT checklist (CHAT-09 pending), phase 7 chat screens that open a thread from a new surface]

actuals:
  tokens: 3470
  tasks: 2
  commits: 2
plan_head_before: 2478c3fc699d3a69851d6f22cf922ab5b30cd274
plan_head_after: a9e554c743fa65db9a09ddf09449b48873fc5a51

tech-stack:
  added: []
  patterns:
    - "Foreground push presentation is a pure function of the parsed event and the visible chat thread; willPresent reads ChatPresence on the main actor and calls the completion handler from the same Task"
    - "Screen presence holders are plain main-actor classes, not @Observable, when nothing renders from them"
    - "A disappearing screen clears a shared presence marker only when the marker is its own id, so stacked pushes and stale onDisappear calls never unmark the screen still showing"

key-files:
  created:
    - ClickMe2026/Managers/PushForegroundPolicy.swift
    - ClickMe2026/Managers/ChatPresence.swift
    - ClickMe2026Tests/Push/PushForegroundPolicyTests.swift
  modified:
    - ClickMe2026/ClickMe2026AppDelegate.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift

key-decisions:
  - "02-11: a foreground push presents nothing only when route_category is message (or the event_type fallback resolves to it), thread_id is present and equals ChatPresence.visibleThreadId; every other push, including a booking push carrying the same thread_id, keeps banner, list, sound and badge"
  - "02-11: ChatPresence.chatDisappeared clears only its own thread, matching Android ChatSessionState.onThreadHidden; the Task 2 presence rows passed on their first run because Task 1 built the rule, so Task 2 is a test-only commit with no GREEN step"
  - "02-11: the CHAT-09 device check was deferred by the user at the Task 1 tracer gate (approve and defer) and is PENDING for 02-12; the tab-switch case (assumption A3) is unverified"

patterns-established:
  - "Suites that drive a shared main-actor singleton are marked .serialized and each row returns the singleton to its empty state through the production API"

requirements-completed: [CHAT-09]

coverage:
  - id: D1
    description: "A message push for the thread on screen presents no options; a message push for another thread, with no chat open, or with no thread_id, and a non-chat push with a matching thread_id, all present the full set; the event_type fallback path is treated as a message push"
    requirement: CHAT-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushForegroundPolicyTests.swift (7 policy rows; /tmp/02-11-t2-red.log, 28 tests in 2 suites passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "ChatPresence keeps the top chat marked when a chat underneath it disappears, clears when the top chat disappears, ignores a disappear for a chat not on screen and a disappear with nothing open, and the policy follows the top thread"
    requirement: CHAT-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushForegroundPolicyTests.swift (5 presence rows under MARK Presence; same run)"
        status: pass
    human_judgment: false
  - id: D3
    description: "willPresent bumps the notifications tick for every foreground push and then completes with the policy's options; ChatView reports its thread in onAppear and onDisappear"
    requirement: CHAT-09
    verification:
      - kind: other
        ref: "grep -c '[.banner, .list, .sound, .badge]' ClickMe2026AppDelegate.swift = 0; grep PushForegroundPolicy.options ClickMe2026AppDelegate.swift present; grep -c ChatPresence.shared ChattingView.swift = 2; xcodebuild build BUILD SUCCEEDED (/tmp/02-11-build.log)"
        status: pass
    human_judgment: false
  - id: D4
    description: "On a device, a message for the chat already open shows no banner, no sound and no Notification Center entry while the message appears in the thread; a message to the same chat from the conversations list shows the banner; with the chat open but the Bookings tab selected, the banner appears (assumption A3)"
    requirement: CHAT-09
    verification: []
    human_judgment: true
    rationale: "Device check deferred by the user at the Task 1 tracer gate (approve and defer). NOT RUN, NOT PASSED. Recorded in .planning/WINDOWS.md as an unrun verify for 02-12 and 02-DEVICE-UAT-CHECKLIST.md."

duration: ~5 min this continuation (Task 1 and its tracer gate in the prior session)
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 11: No foreground banner for the chat already on screen Summary

**`willPresent` now completes with `PushForegroundPolicy.options`, which returns no presentation options only for a `message` push whose `thread_id` equals the chat `ChatView` has marked in `ChatPresence`; every other push keeps banner, list, sound and badge, and the stacked-chat rule (a disappearing chat clears only its own thread) is pinned by serialized tests.**

## Performance

- **Duration:** about 5 min in this continuation (verify Task 1, Task 2, build, close-out); Task 1 and its tracer gate ran in the prior session
- **Started:** 2026-11-10T06:13:58Z (this continuation)
- **Completed:** 2026-11-10T06:18Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments

- `PushForegroundPolicy` (enum, `import UserNotifications`) exposes `fullOptions = [.banner, .list, .sound, .badge]` and `options(for:visibleChatThreadId:)`. Suppression needs all three: `event.category == "message"`, a non-nil `event.threadId`, and equality with the visible thread. A `message` push with no `thread_id` and a `booking` push carrying a matching `thread_id` both present in full. A chat push that reaches `message` through 02-10's `event_type` fallback is suppressed like a `route_category` one.
- `ChatPresence` (`@MainActor final class`, `static let shared`) holds `private(set) var visibleThreadId: UUID?`. `chatAppeared` sets it; `chatDisappeared` clears it only when it equals the given id. It is not `@Observable` because nothing renders from it.
- `ChatView` calls `chatAppeared` in `.onAppear` and `chatDisappeared` in `.onDisappear`, each only when `viewModel.threadId` is non-nil, so a preview seed never marks a thread.
- `willPresent` keeps `PushRouter.shared.handleForegroundArrival(event)` unconditional inside the main-actor `Task`, then calls the completion handler with the policy result read from `ChatPresence.shared.visibleThreadId`. The fixed `[.banner, .list, .sound, .badge]` literal is gone from the delegate.
- `PushForegroundPolicyTests` is `@MainActor @Suite("Push foreground policy", .serialized)` with 7 policy rows and 5 presence rows. 28 tests in 2 suites pass with `PushEventTests` in the same run.

## Task Commits

1. **Task 1: Tracer, a message for the open chat arrives with no banner (CHAT-09)** - `fae23f3` (fix) — prior session
2. **Task 2: Presence edge cases (second chat on top, no thread id)** - `a9e554c` (test)

**Plan metadata:** committed separately (docs: complete plan).

Measured from the plan ledger: `git rev-list --count 2478c3f..a9e554c` = 2.

## TDD evidence (Task 2, `tdd="true"`)

- The five presence rows were written first and run with the plan's Task 2 command (`/tmp/02-11-t2-red.log`). They passed on the first run: 28 tests in 2 suites, no failures.
- Investigation per the TDD reference ("test doesn't fail in RED phase: feature may already exist"): `ChatPresence.chatDisappeared` as committed in Task 1 (`fae23f3`) already clears only when `visibleThreadId == threadId`, and its `///` doc already describes the stacked-chat rule. The plan anticipated this ("if a row fails, fix `ChatPresence`"), so there was no RED and no GREEN implementation step; Task 2 is the plan's single `test(02-11)` commit. No RED evidence record was produced because no failing run existed to classify. The plan is `type: execute`, so no plan-level TDD gate applies.
- `ChatPresence.swift` is unchanged by Task 2 (the plan's "short `///` note on the stacked-chat rule" was already present from Task 1), so the Task 2 commit carries one file instead of the two the plan listed.

## Tracer outcome (Task 1)

The Task 1 tracer gate was answered by the user with "approve and defer". The CHAT-09 device check was **not run** and is **PENDING** (see below). Execution continued per that approval; no further tracer gate was raised in this continuation.

## Files Created/Modified

- `ClickMe2026/Managers/PushForegroundPolicy.swift` - pure presentation decision, `fullOptions`, `options(for:visibleChatThreadId:)`
- `ClickMe2026/Managers/ChatPresence.swift` - main-actor holder of the visible chat thread with the clears-only-its-own-thread rule
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` - `.onAppear` / `.onDisappear` report the thread id when present
- `ClickMe2026/ClickMe2026AppDelegate.swift` - `willPresent` completes with the policy result after the unconditional tick; method doc updated
- `ClickMe2026Tests/Push/PushForegroundPolicyTests.swift` - policy matrix and stacked-chat presence rows, `.serialized`

## Decisions Made

- Suppression is an exact `thread_id` match on a `message` push only (CHAT-09 discretion note). A non-chat push is never suppressed, even with a matching `thread_id`, so booking pushes about the person you are chatting with still notify.
- `ChatPresence` is a plain main-actor class rather than `@Observable`: it is read once per push, nothing observes it.
- The suite is `.serialized` and each presence row ends with the `chatDisappeared` calls that return `ChatPresence.shared` to nil, so rows cannot leak state into each other or into other suites.

## Android parity

- iOS `ChatPresence` matches Android `ChatSessionState` (`onThreadShown` / `onThreadHidden`): `ChatSessionStateTest.openThreadShownAndHidden` pins that hiding "t2" while "T1" is open keeps "T1" and hiding "t1" clears it, the same rule the iOS presence rows pin. No plan-vs-Android conflict found.
- Android also resets `openThreadId` in `clearSessionData()` on logout. iOS relies on `ChatView.onDisappear` firing when the chat hierarchy is torn down at logout. 02-12 (logout clears push state) may want to clear `ChatPresence.shared` explicitly for parity; flagged, not built here.
- Android thread ids are compared case-insensitively as strings; iOS compares `UUID` values, which is the same comparison for valid ids.

## Deviations from Plan

None - plan executed exactly as written. The only variances are documentary: Task 2 produced no RED because Task 1 already implemented the stacked-chat rule (anticipated by the plan's "if a row fails" wording), and the Task 2 commit touches one file because `ChatPresence.swift` needed no change.

## Issues Encountered

None.

## Pending device checks (UAT) — PENDING, not passed

Deferred by the user at the Task 1 tracer gate ("approve and defer"); to be picked up by 02-12 for `02-DEVICE-UAT-CHECKLIST.md`. Recorded in `.planning/WINDOWS.md` as an unrun verify.

- **CHAT-09 (Task 1 human-check, DEFERRED):** device 1 (account B) has the chat with account A open; A sends a message. Expected: no banner and no sound on device 1; the message appears in the thread; nothing is added to Notification Center.
- **Control:** from the conversations list (chat closed), a second message from A shows the banner and plays the sound.
- **Tab switch (Task 2 human-check, assumption A3):** with chat A open, switch to the Bookings tab and have A send: the banner appears. If it does not, `ChatView.onDisappear` does not fire on tab change and the shells must clear `ChatPresence` on tab selection (follow-up).
- **Stacked chats (Task 2 edge case):** open chat B on top of chat A (from a push or a profile), go back to A, then A sends: no banner. While B is on top, a message from A shows the banner and a message from B does not.
- **Non-chat push while a chat is open:** a booking push (for example a request accepted) while any chat is open still shows the banner and sound.
- **No thread id:** not device-testable (preview seeds only); covered by the `noThreadIdPresents` row.

## Known Stubs

None.

## Threat Flags

None new. T-02-22 (suppressing a banner for a chat not on screen) is covered by the exact-match policy rows and the presence rows; the tab-switch case remains a device check as the threat register states.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 02-12 must put the CHAT-09 device checks above into the UAT checklist and may clear `ChatPresence.shared` on logout (Android parity, see above).
- Phase 7 chat work that opens a thread from a new surface gets suppression for free as long as it goes through `ChatView` with a non-nil `threadId`.
- Android needs no change; it already tracks `openThreadId` in `ChatSessionState.kt`.
- No backend or API change.

## Self-Check: PASSED

- Created files exist: `ClickMe2026/Managers/PushForegroundPolicy.swift`, `ClickMe2026/Managers/ChatPresence.swift`, `ClickMe2026Tests/Push/PushForegroundPolicyTests.swift`.
- Commits `fae23f3` and `a9e554c` are ancestors of HEAD; `git rev-list --count 2478c3f..HEAD` = 2 (measured from the plan ledger).
- Plan verification: `xcodebuild build` succeeded (`/tmp/02-11-build.log`); the warning comparison for the plan's five files against the 0-line baseline `/tmp/02-11-warn-before.txt` printed nothing; the only warning line in the log is the `appintentsmetadataprocessor` toolchain message.
- Acceptance: PushForegroundPolicyTests passes every row including the stacked-chat rows (28 tests, 2 suites, `/tmp/02-11-t2-red.log`); `ChatPresence.shared` count in ChattingView.swift = 2; fixed-options literal count in ClickMe2026AppDelegate.swift = 0 and `PushForegroundPolicy.options` present; `.serialized` present on the suite.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
