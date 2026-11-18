---
phase: 07-chat
plan: 03
subsystem: chat
tags: [swiftui, swift-testing, socket-io, read-receipts, pagination, thread-lookup, tdd]

# Dependency graph
requires:
  - phase: 07-chat
    provides: "07-01 ChatThreadReducer (mergePage, unreadPeerIds), ChatSendCoordinator, ChatFixtures; 07-02 retry/delete and the composer cap"
provides:
  - "ChatThreadLookup.find: one GET /chats scan (limit 100, up to 3 pages) for a thread, reused by plans 07-04 and 07-05"
  - "Chat opens knowing the other person: peerUserId from partner.id on every entry route, message rule kept as fallback"
  - "loadEarlier merges through ChatThreadReducer.mergePage: no duplicate rows, older rows above newer in server-time order"
  - "message.read for the unread peer ids of every page loaded and each live peer message, held until the socket is connected"
  - "RealtimeService.isConnected and onConnect(_:)"
affects: [07-04, 07-05, 07-08]

# Actuals (#2632) - chars/4 over the realized diff (git diff cab53a1..HEAD excluding .planning, 38,729 chars)
actuals:
  tokens: 9682
  tasks: 2
  commits: 4
plan_head_before: cab53a19275edb82a6ed9981bf7e41f4a0edbc9b
plan_head_after: f4f7fbdfc796525be66f71c3c763666c79f1dfb6

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Best-effort thread scan: try? read in the view model, no loading UI, silent on failure, the older rule stands as fallback"
    - "Emits that the socket library drops while disconnected are recorded as sent only when connected, and replayed from an onConnect subscription"
    - "Test seams on the runtime init (isRealtimeConnected, emitMessageRead) instead of a protocol, with defaults that read the live RealtimeService"

key-files:
  created:
    - ClickMe2026/Utils/ChatThreadLookup.swift
    - ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift
    - ClickMe2026Tests/Chat/ChattingViewModelReadEmitTests.swift
  modified:
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
    - ClickMe2026/Realtime/RealtimeService.swift
    - ClickMe2026Tests/Support/ChatFixtures.swift

key-decisions:
  - "The scan result replaces a message-derived peer id (partner.id is authoritative); a failed or empty scan leaves the message rule in place"
  - "refreshThreadInfo runs after loadState = .loaded so messages render first; a failed page-1 fetch returns before the scan"
  - "message.read ids are recorded as emitted only when RealtimeService.isConnected, and held ids go out from realtimeDidConnect (07-RESEARCH Open Question 1, same as Android)"
  - "handleMessageNew now emits through emitPendingReads, so a live message also flushes any ids still held; one path for page loads and live messages"

patterns-established:
  - "ChattingViewModel.swift stays wiring over ChatThreadLookup and ChatThreadReducer: 596 lines against the 624 ceiling"
  - "ChatFixtures.thread / threadsPage build GET /chats rows; blocked_by_me is omitted when nil to test a missing key"

requirements-completed: [CHAT-05, CHAT-06, CHAT-07]

coverage:
  - id: D1
    description: "Opening a thread scans GET /chats (limit 100, up to 3 pages) and sets peerUserId from partner.id, including for a thread with no messages; View Profile and typing have a recipient before any peer message"
    requirement: CHAT-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift (lookup paging x5, emptyThreadGetsPeerFromScan, scanReplacesMessageDerivedPeer)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A failed or unlisted scan leaves the thread loaded, shows no error and keeps the first-non-me-sender peer id; viewDidAppear rescans only after the thread loaded"
    requirement: CHAT-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift (failedScanFallsBackToTheMessageRule, unlistedThreadFallsBackToTheMessageRule, viewDidAppearScansOnlyOnceLoaded)"
        status: pass
    human_judgment: false
  - id: D3
    description: "loadEarlier merges through the reducer: repeated rows add nothing, new older rows land above newer ones in time order, an empty page ends paging"
    requirement: CHAT-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift (olderPageMergesWithoutDuplicates, repeatedOlderPageAddsNothing, emptyOlderPageEndsPaging)"
        status: pass
    human_judgment: true
    rationale: "Scroll position and the visual feel of paging back in a long real thread need a device; deferred to end-of-phase UAT"
  - id: D4
    description: "message.read goes out once per page for unread peer ids only (never mine, already Read or already sent), is held while the socket is disconnected and sent on connect, and live peer messages emit their own id"
    requirement: CHAT-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelReadEmitTests.swift (8 tests: pageOne, olderPage, repeatedPage, held-until-connected, reconnect, live peer, own/foreign, repeated live)"
        status: pass
    human_judgment: true
    rationale: "The unread badge reaching 0 after a cold-launch push open, and Read ticks on the sender's phone, need two accounts on two iPhones; deferred to end-of-phase UAT (device check C6)"
  - id: D5
    description: "ChattingViewModel.swift is 596 lines (ceiling 624); no new warnings in the plan's files; the old all-items emit helper and the unfiltered prepend are gone"
    requirement: CHAT-06
    verification:
      - kind: other
        ref: "grep gate in 07-03-PLAN Task 2 (GREP_GATE_PASS) and warning diff against the empty baseline (WARN_GATE_PASS)"
        status: pass
    human_judgment: false

# Metrics
duration: 13min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 03: Thread Lookup, Duplicate-free Paging and Held Read Receipts Summary

**Opening any chat scans GET /chats once to learn the other person's id, loadEarlier merges pages through the reducer so nothing shows twice, and message.read goes out for every loaded page, held until the socket is connected.**

## Performance

- **Duration:** about 13 min
- **Started:** 2026-11-18T05:29:08Z
- **Completed:** 2026-11-18T05:42Z
- **Tasks:** 2 (Task 1 tracer, Task 2 auto TDD)
- **Files modified:** 7 (3 app, 1 new app, 2 new test suites, 1 test support), 757 insertions and 25 deletions

## Accomplishments

- **Thread lookup (Task 1, tracer).** `ChatThreadLookup.find(threadId:api:maxPages:)` reads `GET /chats` at the backend maximum of 100 per page, for at most 3 pages, and stops on a page with no threads, a response with no `pagination`, or the last page. `ChattingViewModel.refreshThreadInfo()` sets `peerUserId` from `partner.id` after the messages render, with `try?` and no published state, so a failed scan changes nothing on screen. It runs at the end of `forceLoad()` (so pull-to-refresh rescans) and from `viewDidAppear()` once the thread is `.loaded` (returning from Report & Block or a profile). The first-sender rule `hydratePeerUserIdIfNeeded` stays as the fallback and a scan result replaces it.
- **Duplicate-free paging (Task 2).** `loadEarlier()` now calls `ChatThreadReducer.mergePage`, so a row whose server id is already shown is reconciled, not added, and older rows are ordered above newer ones by server time. The page cursor, `hasMoreEarlier`, the peer-id fallback and the silent catch are unchanged.
- **Read receipts per page, held until connected (Task 2).** `emitPendingReads()` emits `ChatThreadReducer.unreadPeerIds(items, alreadyEmitted:)` only while `isRealtimeConnected()` is true and records the ids then. It runs after the page-1 merge, after each older-page merge and for each live peer `message.new`. `RealtimeService` gains `isConnected` and `onConnect(_:)` (the previously empty `.connect` handler now calls the subscribers), and `attachRealtime()` subscribes `realtimeDidConnect()` so ids loaded while connecting go out on connect and on every reconnect. The old `emitReadForVisiblePeerMessages` helper is deleted.
- **Size rule.** `ChattingViewModel.swift` is 596 lines (550 before, ceiling 624).

## Task Commits

1. **Task 1: Tracer - opening any chat looks the thread up and knows the other person at once**
   - RED `dc3ecdb` (test) - 10 tests, 8 failing on the planned assertions; `ChatThreadLookup` and the view-model methods were compile stubs
   - GREEN `03e1d3c` (feat) - lookup paging, `refreshThreadInfo`, `viewDidAppear`, view `.onAppear` call
2. **Task 2: Older pages never duplicate messages, and read receipts go out for every page, held until the socket connects**
   - RED `71d588e` (test) - 8 read-receipt tests and 3 `loadEarlier` tests, 9 failing on assertions; init seams, `RealtimeService.isConnected` and a `realtimeDidConnect` stub as compile seams
   - GREEN `f4f7fbd` (feat) - merge in `loadEarlier`, `emitPendingReads`, `realtimeDidConnect`, `onConnect`

**Plan metadata:** the docs commit following this SUMMARY.

## TDD evidence

- **RED, Task 1** (`/tmp/07-03-red.log`): failures on `found?.partner.id → nil`, `requests.count → 0`, `peerUserId → nil` and one wrong peer id (the first non-me sender where the scan's partner was expected). The two fallback tests passed at RED because the shipped message rule already satisfies them; they are regression guards, not the target. Semantic assessment: the failures are on the planned assertions, not on compile or fixture faults.
- **RED, Task 2** (`/tmp/07-03-red2.log`): `socket.emits.count → 0` for every receipt test and a duplicated `serverId` list for the two merge tests. Passing at RED, as guards: "own or foreign live message emits nothing" (nothing emitted at all) and "empty older page" (nothing to add). Semantic assessment: valid RED.
- **GREEN:** `ChattingViewModelOpenTests` 13 passed, `ChattingViewModelReadEmitTests` 8 passed, regression `PushForegroundPolicyTests` 12 passed, and `ChattingViewModelSendTests` plus `ChatThreadReducerTests` 40 passed.
- No REFACTOR commit was needed.

## Files Created/Modified

- `ClickMe2026/Utils/ChatThreadLookup.swift` - bounded `GET /chats` scan for one thread (new)
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift` - `refreshThreadInfo`, `viewDidAppear`, `emitPendingReads`, `realtimeDidConnect`, `emittedReadIds`, init seams, `loadEarlier` through `mergePage`
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` - `.onAppear` calls `viewDidAppear()`
- `ClickMe2026/Realtime/RealtimeService.swift` - `isConnected`, `connectHandlers`, `onConnect(_:)`, connect handler fans out
- `ClickMe2026Tests/Support/ChatFixtures.swift` - `thread(...)`, `threadsPage(...)`
- `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift` - lookup, peer seed and `loadEarlier` merge tests (new)
- `ClickMe2026Tests/Chat/ChattingViewModelReadEmitTests.swift` - per-page, deduplicated, connection-held receipts (new)

## Decisions Made

See `key-decisions` in the frontmatter. In short: the scan's `partner.id` wins over the message guess; receipts are recorded only when actually emittable and replayed on connect; one emit path serves page loads and live messages.

## Deviations from Plan

### Plan-shape notes (not defects)

**1. Both tasks committed as RED then GREEN.** The plan names one commit per task; the TDD reference requires a RED test commit first. The same files were staged across the two commits, plus no other file. The RED commits carry compile stubs (`ChatThreadLookup` returning nil, empty `refreshThreadInfo`/`viewDidAppear`/`realtimeDidConnect`, the init seams and `RealtimeService.isConnected`) so the tests build and fail on assertions.

**2. `threadsPage` has one extra defaulted parameter, `includePagination`.** The plan's signature has `page` and `totalPages`; the "pagination absent" behavior row needs a response with no `pagination` key, which the plan's signature cannot produce. Existing call shapes are unaffected.

**3. `loadEarlier` row "empty page" lives in the Open suite with the other two merge rows;** the emit half of the "new unread older row" behavior lives in the ReadEmit suite. Together they cover every `<behavior>` row.

---

**Total deviations:** 0 auto-fixed, 3 plan-shape notes.
**Impact on plan:** None on scope. No file outside the plan's list was touched, no endpoint or contract changed.

## Deferred human verification

Per the user's decision (`workflow.human_verify_mode = end-of-phase`), the Task 2 `<human-check>` was NOT run and is carried to the end-of-phase UAT. It is recorded in `.planning/WINDOWS.md` as `unrun-verify`. Unit and build gates passed; only hardware evidence is outstanding.

### H1. Task 2: open-clears, cold-launch push open and Load earlier (device check C6, open-clears part)

**Setup:** two accounts (A and B) on two iPhones, a thread between them with enough history for several pages (more than 60 messages); push notifications enabled on A.
**Steps:**
1. Force-quit A's app. On B, send 3 messages to A.
2. Tap the push notification on A (cold launch) to open the thread.
3. Go back to Chats and pull to refresh.
4. Open the long thread, scroll to the top and tap Load earlier twice (or scroll to trigger paging).
5. Optional: open a brand-new thread from a profile Message button and open the menu before anyone writes.
**Expected:**
- After the push open and the list reload, the thread's row shows no unread count.
- On B's phone, the 3 messages show Read.
- Load earlier never shows a message twice, and older messages appear above the newer ones.
- On the brand-new thread, View Profile in the menu is enabled and B sees A typing as soon as A types.

## Issues Encountered

- A test run that included the third suite exceeded the foreground time limit and moved to the background; it completed with exit 0.
- The `sed` rewrite of a test helper to `nonisolated` and a Python patch of the view model were reported by the editor as "changed on disk"; both were my own edits.

## Known Stubs

None. Every compile stub added at RED was replaced at GREEN; no placeholder text, empty data flow or TODO remains in the plan's files.

## Accepted gaps (from the plan)

- A thread with more than 30 unread messages where the user never loads older pages keeps a non-zero server count, and the badge returns after the next GET /chats (D-16).
- For an account with more than 300 threads, a thread older than all of them (including a brand-new empty thread, which the backend sorts last) gets no peer seed from the scan and falls back to the message rule until the first peer message.

## Threat Flags

None. No new endpoint, auth path or file access. T-07-06 is mitigated as planned: receipts list only loaded peer rows (`unreadPeerIds`), never a whole-thread mark, and the tests assert own, Read and already-sent ids are excluded. T-07-07 is accepted: only the matching row of the caller's own list is used and nothing is stored or logged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 07-04 can extend `refreshThreadInfo()` with the block state (`isBlocked`, `blockedByMe`) from the same `ChatThreadLookup.find` result; a nil result must not be read as "not blocked".
- Plan 07-05 can reuse `ChatThreadLookup`.
- Open: device check H1 above, plus H1/H2 and observations (a) and (b) from 07-02, are owed to the end-of-phase UAT.

## Self-Check: PASSED

- Files exist: `ChatThreadLookup.swift`, `ChattingViewModelOpenTests.swift`, `ChattingViewModelReadEmitTests.swift` (all FOUND).
- Commits exist and are ancestors of HEAD: `dc3ecdb`, `03e1d3c`, `71d588e`, `f4f7fbd`.
- Task 1 and Task 2 grep gates passed; `ChattingViewModel.swift` is 596 lines (at most 624), `items.insert(contentsOf` and `emitReadForVisiblePeerMessages` count 0.
- Debug build succeeds; the warning diff against the empty baseline is empty (no new warnings in the plan's files).
- `commits: 4` measured from `git rev-list --count cab53a1..HEAD`.

---
*Phase: 07-chat*
*Completed: 2026-11-18*
