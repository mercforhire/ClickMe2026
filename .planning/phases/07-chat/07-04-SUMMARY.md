---
phase: 07-chat
plan: 04
subsystem: chat
tags: [swiftui, swift-testing, chat, block, unblock, banner, accessibility, tdd]

# Dependency graph
requires:
  - phase: 07-chat
    provides: "07-01 ChatSendCoordinator and ChatFixtures; 07-03 ChatThreadLookup and refreshThreadInfo"
provides:
  - "ChatBlockState: pure port of Android BlockState (scan, transitions, menu entry, banner copy, error copy) and the per-thread Session value the view model holds"
  - "A blocked thread replaces the composer and typing strip with a banner saying who blocked; only the recorded blocker gets an Unblock capsule"
  - "A send refused 403 THREAD_BLOCKED or RECIPIENT_UNAVAILABLE returns its text, shows the banner, rescans, hides the keyboard and announces once, with no alert"
  - "Unblock from the banner (NOT_BLOCKER handled); state-aware thread menu; adoptBlockState(_:) for plan 07-05"
affects: [07-05, 07-06, 07-08]

# Actuals (#2632) - chars/4 over the realized diff (git diff a38fa2f..HEAD, ClickMe2026 and ClickMe2026Tests, 55,870 chars)
actuals:
  tokens: 13968
  tasks: 3
  commits: 6
plan_head_before: a38fa2fab873e1693de812b4e8564d9f6627af2e
plan_head_after: 8c159f69f100c08f5ae24fc48f852406e88e24e6

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Block bookkeeping lives in a pure nested value (ChatBlockState.Session) the view model stores once; the view model only calls it, which keeps ChattingViewModel.swift at its 624-line ceiling"
    - "Scan do/catch tells a scan that answered 'not listed' (state kept, or blocked by me after a session block) from a scan that failed (nothing changes)"
    - "View model exposes derived read-only values (composerMode, refusedBannerToken, isUnblocking) computed from the one published Session"

key-files:
  created:
    - ClickMe2026/Utils/ChatBlockState.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift
    - ClickMe2026Tests/Chat/ChatBlockStateTests.swift
  modified:
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingEmptyState.swift
    - ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift
    - ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift

key-decisions:
  - "No unblock latch (deliberate divergence from Android): after NOT_BLOCKER blockedByMe is false, which already hides Unblock"
  - "refusedBannerToken and isUnblocking are computed from ChatBlockState.Session (refusalCount, isUnblocking, beginUnblock) instead of stored @Published fields, so the view model stays at 624 lines"
  - "The refusal announcement token is bumped inside applySendRefusal, before the rescan, as the plan orders it; the announced title is the mode right after the refusal"
  - "A legacy self-thread (peer id equals my id) shows no block or report entry, because the server answers CANNOT_REPORT_SELF"

patterns-established:
  - "ChattingBlockedBanner takes mode, peerName, isUnblocking and onUnblock; copy and symbols come from ChatBlockState, so the view holds no strings of its own for the state machine"
  - "Optional onSendMessage on ChattingEmptyState: nil hides the capsule behind a banner"

requirements-completed: [CHAT-03]

coverage:
  - id: D1
    description: "Open-time scan drives the composer slot: blocked by me, blocked by the peer, legacy block with no blocked_by_me key reads as by the peer, unblocked and unlisted keep the normal composer, a failed scan changes nothing and shows no error, a later scan miss never clears a block by me"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift (scanBlockedByMe, scanBlockedByPeer, scanLegacyBlockWithMissingKey, scanNotBlocked, scanMissKeepsNormal, failedScanKeepsNormal, laterScanMissKeepsBlockedByMe)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A send refused THREAD_BLOCKED or RECIPIENT_UNAVAILABLE removes the bubble, returns the text, switches to the banner, rescans GET /chats and shows no alert; blocked wins over unavailable; Failed-bubble retry is ignored behind a banner; a 422 keeps the alert"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelSendTests.swift (threadBlockedSwitchesToTheBanner, recipientUnavailableSwitchesToTheBanner, blockedWinsOverUnavailable, retryIsIgnoredBehindTheBanner, validationRefusalKeepsTheNormalComposer)"
        status: pass
    human_judgment: true
    rationale: "Keyboard hiding and the single VoiceOver announcement need a device; deferred to end-of-phase UAT"
  - id: D3
    description: "Unblock from the banner posts chat_action unblock once, 200 restores the composer, NOT_BLOCKER moves to can't-reply with its own copy, 500 and transport errors keep the banner with the right copy; only the blocker is offered Unblock (T-07-08)"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift (unblockSucceeds, unblockNotBlocker, unblockServerError, unblockTransportFailure, unblockIgnoresARepeatTap) and ClickMe2026Tests/Chat/ChatBlockStateTests.swift (menu, showsUnblock, session unblock rows)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Pure block state ported from Android BlockStateTest without the latch, plus banner copy, error copy and Session transitions; adoptBlockState survives a scan miss; a scan whose partner is me marks a self-thread"
    requirement: CHAT-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatBlockStateTests.swift (26 tests); ChattingViewModelOpenTests adoptedBlockSurvivesAScanMiss, selfThreadFromScan"
        status: pass
    human_judgment: false
  - id: D5
    description: "Banner and menu presentation: banner replaces composer with a 0.2 s fade, at least 56 pt with a hairline, Unblock capsule 44 pt moving under the title at large text sizes (ViewThatFits), Unblocking spinner, state-aware menu, empty-state button hidden behind a banner"
    requirement: CHAT-03
    verification: []
    human_judgment: true
    rationale: "Layout at the largest Dynamic Type size, the fade, VoiceOver labels and the two-account flow need hardware; deferred to end-of-phase UAT (device checks C4, C5, C8, C9)"
  - id: D6
    description: "ChattingViewModel.swift is 624 lines (ceiling 624); no new warnings in the plan's files"
    requirement: CHAT-03
    verification:
      - kind: other
        ref: "wc -l gate in Task 3 verify (GREP_OK) and warning diff against the empty baseline (WARN_OK, /tmp/07-04-warn-t3.txt)"
        status: pass
    human_judgment: false

# Metrics
duration: 22min
completed: 2026-11-18
status: complete
---

# Phase 7 Plan 04: Blocked-thread Banner, Send Refusals and Blocker-only Unblock Summary

**A blocked conversation now replaces the composer with a banner that says who blocked it, a send refused as blocked or unavailable keeps its text and switches to that banner with no alert, and only the recorded blocker is ever offered Unblock, from the banner or the thread menu.**

## Performance

- **Duration:** about 22 min
- **Started:** 2026-11-18T05:44:11Z
- **Completed:** 2026-11-18T06:06Z
- **Tasks:** 3 (Task 1 tracer, Tasks 2 and 3 auto TDD)
- **Files modified:** 8 (3 new, 5 changed), 6 task commits

## Accomplishments

- **ChatBlockState (Task 1, tracer).** A pure port of Android `BlockState.kt` with no unblock latch: `ScannedBlock` (a missing `blocked_by_me` reads false), `ComposerMode`, `MenuEntry`, `applyScan(found:sessionBlockedByMe:)`, the four transitions, `showsUnblock`, `menuEntry`, `composerMode(block:recipientUnavailable:)` (blocked beats unavailable), the banner titles and symbols, and the error copy. The nested `Session` is the one value the view model stores.
- **Open-time block state.** `refreshThreadInfo()` now uses `do`/`catch`: a listed thread sets the peer id and applies its flags, an unlisted one keeps the state (or becomes blocked by me after a session block), a failed scan changes nothing. `ChattingBlockedBanner` takes the composer's slot (typing strip included) with a 0.2 s fade, and composer focus drops when it arrives.
- **Send refusals (Task 2).** `.refused` still removes the bubble and restores the text, then asks `blockSession.applySendRefusal(code)`: for `THREAD_BLOCKED` or `RECIPIENT_UNAVAILABLE` there is no alert, the banner shows and `GET /chats` is rescanned inside the outcome handler (so `awaitInFlightSends()` covers it). The view hides the keyboard and posts one VoiceOver announcement with the banner title. `retrySend` is ignored unless the composer is normal.
- **Unblock and menu (Task 3).** `unblockFromBanner()` posts `unblock` once per tap sequence; 200 restores an empty composer, `NOT_BLOCKER` becomes "You can't reply to this conversation" with its own alert copy, other errors keep the banner and show `userMessage` or the connection fallback. The menu is View Profile, then Block or Report, Unblock or Report, or Report by state, and none of the three on a self-thread. `adoptBlockState(_:)` is ready for plan 07-05. The empty state hides Send a message behind a banner.
- **Size rule.** `ChattingViewModel.swift` is exactly 624 lines (596 before this plan).

## Task Commits

1. **Task 1: Tracer - a blocked thread shows the banner in place of the composer, read from the open-time scan**
   - RED `6a59e41` (test) - 7 new rows, 4 failing on the planned `composerMode` assertions; `ChatBlockState` (whole, pure) and the view model's `blockSession`/`composerMode` were the compile seams
   - GREEN `a10d812` (feat) - scan applied in `refreshThreadInfo`, `ChattingBlockedBanner`, composer slot
2. **Task 2: A send refused as blocked or unavailable switches to the banner and gives the text back**
   - RED `749ab01` (test) - 5 send rows (4 failing) plus the 26-test `ChatBlockStateTests`, which passed at RED because the pure type already existed
   - GREEN `6d83928` (feat) - refusal branch, retry guard, announcement
3. **Task 3: Only the blocker can unblock, from the banner or the menu; the menu matches the state**
   - RED `f4f2b8e` (test) - 7 rows, 12 assertion failures; `unblockFromBanner`, `adoptBlockState`, `isSelfThread` and two published fields were empty stubs
   - GREEN `8c159f6` (feat) - unblock flow, banner capsule, menu, alert, optional empty-state action

**Plan metadata:** the docs commit following this SUMMARY.

## TDD evidence

- **Tracer gate:** `HUMAN_VERIFY_MODE` is `end-of-phase` and Task 1's `<verify>` is automated-only, so its tests, grep gate and build/warning gate were re-run after GREEN and passed. Tracer verified end-to-end, then expanded.
- **RED, Task 1** (`/tmp/07-04-red.log`, `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`): `composerMode → .normal` against `.blockedByMe`, `.blockedByPeer` (twice) and the later-scan row. Not-blocked, unlisted and 500 rows passed as regression guards. Semantic assessment: the target test ran and failed on the planned assertion; no compile or fixture fault.
- **RED, Task 2** (`/tmp/07-04-red2.log`, `RED_EVIDENCE_OK`): `sendError → "Gone"` against nil, `composerMode → .normal` against `.unavailable` and `.blockedByPeer`, no rescan recorded, and an extra POST on retry behind the banner. The 422 row passed as a guard.
- **RED, Task 3** (`/tmp/07-04-red3.log`): zero actions POSTs, `unblockError → nil`, `composerMode → .blockedByMe` against `.normal` or `.blockedByPeer`, `isSelfThread → false`. Semantic assessment: assertion failures on the stubbed behaviours.
- **GREEN:** `ChattingViewModelOpenTests` 27, `ChattingViewModelSendTests` 23, `ChatBlockStateTests` 26 passed; regression `ChattingViewModelReadEmitTests` 8 and `ChatThreadReducerTests` 21 passed. Debug build succeeded with no warnings in the plan's files against an empty baseline.
- No REFACTOR commit was needed.

## Files Created/Modified

- `ClickMe2026/Utils/ChatBlockState.swift` - the pure block state and Session
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift` - banner with the Unblock capsule and four previews
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift` - block section, scan, refusal branch, retry guard, unblock, hand-back, `isSelfThread`
- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` - composer slot, state-aware menu, unblock alert, announcement, focus drop
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingEmptyState.swift` - optional `onSendMessage`
- `ClickMe2026Tests/Chat/ChatBlockStateTests.swift` - new pure suite
- `ClickMe2026Tests/Chat/ChattingViewModelOpenTests.swift`, `ChattingViewModelSendTests.swift` - scan, refusal, unblock, hand-back and self-thread rows

## Decisions Made

- No unblock latch: `blockedByMe == false` after `NOT_BLOCKER` already hides Unblock (07-PATTERNS).
- The announcement token and the unblock-in-flight flag are derived from the Session so the view model keeps its size; the view reads the same names as the plan.
- Self-threads show no block or report entry because the server answers `CANNOT_REPORT_SELF`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] View model over the 624-line ceiling after Task 3**
- **Found during:** Task 3 (GREEN)
- **Issue:** The plan's `@Published private(set) var refusedBannerToken`, `isUnblocking`, and its `defer` guard put `ChattingViewModel.swift` at 627 lines.
- **Fix:** Moved the in-flight flag and the refusal count into `ChatBlockState.Session` (`isUnblocking`, `beginUnblock()`, `refusalCount`), exposed them as computed `isUnblocking` and `refusedBannerToken` on the view model, and removed an empty `// MARK: - Error mapping` section and a doubled blank line. No doc comment was deleted.
- **Files modified:** `ClickMe2026/Utils/ChatBlockState.swift` (a sixth file in the Task 3 commit), `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift`
- **Verification:** `wc -l` is 624; all three suites pass; `ChatBlockStateTests` still passes unchanged.
- **Committed in:** `8c159f6`

**2. [Process] RED and GREEN split into separate commits per task**
- The plan lists one `feat` commit per task, but the TDD execution rules require a RED test commit first. Each task therefore has a `test(07-04)` commit and a `feat(07-04)` commit, as in plans 07-01 to 07-03. `ChatBlockState.swift` (new, pure) landed in the Task 1 RED commit as a compile seam, not in the GREEN commit.

---

**Total deviations:** 1 auto-fixed (Rule 3), 1 process note
**Impact on plan:** No change to behaviour or to the names later plans use; `ChatBlockState` is the sixth file in the Task 3 commit.

## Issues Encountered

- A first test run failed to compile because `#expect` cannot call a `mutating` method on a `var` Session; the calls were moved out of the expectation.
- `ClickMe2026/Localizable.xcstrings` has pre-existing uncommitted changes and was left unstaged. The new user-facing strings (`Unblock`, `Unblocking`, `Couldn't unblock user`, `Report`, `Unblock or Report`, the banner titles) are literals in code, the same as the surrounding chat screens, and no catalog entries were added.

## Deferred human verification

Per the user's decision (`workflow.human_verify_mode = end-of-phase`), the Task 3 `<human-check>` was NOT run and is carried to the end-of-phase UAT. It is recorded in `.planning/WINDOWS.md` as entry 40 (`unrun-verify`). Unit and build gates passed; only hardware evidence is outstanding.

### H1. Task 3: banner, unblock and refusal on two iPhones (device checks C4, C5, C9 banner and C8 banner)

**Setup:** two accounts (A and B) on two iPhones against the production backend, with a thread between them.
**Steps:**
1. A opens the thread, opens the menu and chooses Block or Report, then blocks B from that screen and comes back.
2. Check both phones' threads and menus.
3. A taps Unblock on the banner.
4. A blocks B again. B, with the thread open and the keyboard up, types a message and sends.
5. Repeat steps 1 to 4 with the largest accessibility text size and then with VoiceOver on.

**Expected:**
- A sees "You blocked this conversation" with an Unblock capsule; the menu reads View Profile, Unblock or Report.
- B sees "You can't reply to this conversation" with no Unblock anywhere; the menu reads View Profile, Report.
- A's Unblock shows a spinner labelled Unblocking, then brings back an empty, unfocused composer with a short fade.
- B's send disappears, the text returns to the composer, the banner appears, the keyboard hides and VoiceOver announces the banner title once, with no alert.
- At the largest text size the Unblock capsule moves under the title and stays 44 pt tall.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The `ReportChatView` closures in `ChattingView` still ignore the Block & Report outcome; plan 07-05 wires `adoptBlockState(_:)` there (named in this plan, not a stub in this plan's goal).

## Threat Flags

None. T-07-08 is mitigated: Unblock is shown only when `ChatBlockState.showsUnblock` is true and `NOT_BLOCKER` moves the thread to blocked-by-peer (`ChatBlockStateTests`, `ChattingViewModelOpenTests`).

## Next Phase Readiness

Ready for 07-05: `adoptBlockState(_:)`, `isSelfThread`, `blockState` and `ChatBlockState.actionErrorMessage` are in place for the Block & Report screen to use. `ChatThreadItem.blockedByMe` is still `Bool?`; `ScannedBlock(thread:)` holds the only fallback, ready for plan 07-06 Task 3. The view model has no spare lines under its ceiling, so further thread-level logic should go into `ChatBlockState.Session` or a sibling type.

---
*Phase: 07-chat*
*Completed: 2026-11-18*

## Self-Check: PASSED

- Created files exist: `ChatBlockState.swift`, `ChattingBlockedBanner.swift`, `ChatBlockStateTests.swift`.
- Commits exist on HEAD: `6a59e41`, `a10d812`, `749ab01`, `6d83928`, `f4f2b8e`, `8c159f6`.
- RED and GREEN gate commits are present for each task, in order.
