---
phase: 02-shared-ios-plumbing
plan: 14
subsystem: ui
tags: [swiftui, bookings, join-window, timelineview, swift-testing, accessibility, android-parity]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "JoinWindow rule and the two list surfaces from plan 02-04; BookingStatus decoding from plan 02-03"
provides:
  - "Expert dashboard strip and client Explore today strip on JoinWindow, re-evaluated every 60 s inside a TimelineView"
  - "Join is shown disabled, not hidden, for non-joinable bookings on all four Join surfaces (strips and 02-04 lists), as Android does; the joining rule is unchanged"
  - "JoinWindow.showsJoinButton(status:) as the one shown-versus-enabled predicate, tested"
  - "ClientBookingDetail.canJoin (optional can_join) for Phase 3 CALL-03"
  - "No join-window copy of the symmetric-hour rule left in the app target (only the two 'starting now' pill helpers keep that arithmetic, by design)"
affects: [02-12 device UAT checklist, 02-UI-SPEC section 2, 03 client detail and expert summary join (CALL-03, CALL-08, CALL-10), Android JoinWindow port]

actuals:
  tokens: 6400
  tasks: 2
  commits: 7
plan_head_before: 87af01f1190330a0f4d070b6b29baa2590a13b3d
plan_head_after: ddc0163b837a4ca594f52c77b4b6288941f30d88

tech-stack:
  added: []
  patterns:
    - "Shown versus enabled: JoinWindow.showsJoinButton decides whether a Join button is rendered; JoinWindow.isOpen decides whether it is enabled. Disabled Join is 55% accent, no glow, .disabled(true), plus an accessibility hint with Android's explore_join_call_state wording"
    - "Every Join surface re-reads the rule inside TimelineView(.periodic(from: .now, by: 60))"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/JoinWindow.swift
    - "ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift"
    - ClickMe2026/Model/Responses/Children/ExpertBookingItem.swift
    - "ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift"
    - ClickMe2026/Model/Responses/ClientBookingDetail.swift
    - ClickMe2026Tests/Utils/JoinWindowTests.swift
    - "ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/UpcomingBookingCard.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift"

key-decisions:
  - "02-14: Join is shown DISABLED, not hidden, for non-joinable bookings (pending_reschedule included) on the expert dashboard strip, the client Explore strip, the client My Bookings card and the expert Upcoming list, matching Android on each screen (user decision 2026-11-10 at the Task 1 tracer gate). This supersedes the presentation half of D-12 and the 'Hidden' / 'Not rendered' cells of 02-UI-SPEC section 2; the joining RULE is unchanged (JoinWindow.isOpen still excludes pending_reschedule and honours the server can_join)"
  - "02-14: JoinWindow.showsJoinButton(status:) is the one shown-versus-enabled predicate: every status but pending_approval renders Join; the awaiting-approval client card keeps its banner in place of the button, as Android's My Bookings card does"
  - "02-14: disabled Join buttons rely on .disabled() for the VoiceOver 'dimmed' announcement and add Android's explore_join_call_state wording ('Available closer to the session start') as an accessibility hint on all four surfaces"
  - "02-14: CALL-02 device check DEFERRED by the user because the behavior changed after the checkpoint; PENDING for 02-12 (WINDOWS #19)"

patterns-established:
  - "Swift TDD RED for a new symbol: declare it with the body the code implements today so the test compiles and fails on its assertion (a build failure is INVALID_RED); classify with the gsd tdd-red-evidence check after stripping only the U+200B terminal prefixes swift-testing puts on parameterised result lines"

requirements-completed: [CALL-02]

coverage:
  - id: D1
    description: "Join is rendered for every status but pending_approval and enabled only by JoinWindow.isOpen; a pending_reschedule booking shows Join disabled, not hidden"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/JoinWindowTests.swift#Join is rendered for every status but pending_approval; #A pending_reschedule booking shows Join disabled, not hidden (RED b285b8b failed 8 issues, GREEN 1ab3f1f; /tmp/02-14-t2.log 205 tests in 23 suites passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Expert dashboard strip uses JoinWindow with the server can_join and re-evaluates every minute; a pending_reschedule card shows Join dimmed and disabled"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "JoinWindowTests (rule and presentation); grep gates: JoinWindow.isOpen 1, TimelineView 2, showsJoinButton 1, delta <= 3600 0 in ExpertDashboardView.swift; BUILD SUCCEEDED, no new warnings"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT CALL-02 expert dashboard strip (DEFERRED, not run; WINDOWS #19)"
        status: unknown
    human_judgment: true
    rationale: "Live time-driven enablement and the disabled visual on a real iPhone; the user deferred the device check because the behavior changed after the tracer gate"
  - id: D3
    description: "Client Explore today strip re-reads JoinWindow every minute and shows Join disabled, not hidden, for a pending_reschedule booking"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "JoinWindowTests; grep gates: TimelineView 2, showsJoinButton 1 in ExploreTodaysSessionsSection.swift; BUILD SUCCEEDED"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT CALL-02 client Explore strip (DEFERRED, not run; WINDOWS #19)"
        status: unknown
    human_judgment: true
    rationale: "Live enablement without leaving the screen needs eyes on a device"
  - id: D4
    description: "Client My Bookings card and expert Upcoming list show Join disabled instead of hidden for non-joinable bookings or a closed window (Android parity on the 02-04 lists)"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "JoinWindowTests (showsJoinButton rows); BUILD SUCCEEDED, no new warnings in UpcomingBookingCard.swift or UpcomingBookingsSessionCard.swift"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT CALL-02 lists: pending_reschedule shows Join disabled (DEFERRED; WINDOWS #19)"
        status: unknown
    human_judgment: true
    rationale: "Visual dimmed state and VoiceOver announcement on a device"
  - id: D5
    description: "ClientBookingDetail decodes with can_join true, can_join false, and without the key (nil)"
    requirement: CALL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/JoinWindowTests.swift#ClientBookingDetail can_join (3 rows, passed)"
        status: pass
    human_judgment: false
  - id: D6
    description: "No join-window copy of the symmetric-hour rule remains in the app target"
    requirement: CALL-02
    verification:
      - kind: other
        ref: "grep -rn 'delta <= 3600' ClickMe2026 --include=*.swift minus the two pill helpers = 0 (total 2 lines, both isStartingNow)"
        status: pass
    human_judgment: false

duration: ~50 min (continuation; Task 1 in the prior session)
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 14: Shared join window on the strips, Join shown disabled not hidden Summary

**The expert dashboard strip and the client Explore today strip now sit on `JoinWindow` inside a 60 s `TimelineView`, and on every Join surface a non-joinable booking (pending_reschedule included) shows Join dimmed and disabled instead of no button, as Android does; `ClientBookingDetail.canJoin` decodes `can_join` for Phase 3.**

## Performance

- **Duration:** about 50 min for this continuation (Task 1 landed in the prior session at `13ccd3d`, 2026-11-10T06:39Z)
- **Started:** 2026-11-10T16:00Z (continuation)
- **Completed:** 2026-11-10T16:55Z
- **Tasks:** 2 of 2, plus the user-directed presentation change
- **Files modified:** 8 (the plan's 5 plus `JoinWindow.swift`, `UpcomingBookingCard.swift`, `UpcomingBookingsSessionCard.swift`)

## Accomplishments

- **Strips on the shared rule, live.** `ExpertDashboardView` lost its last copy of the symmetric plus-or-minus 3600 s rule and reads `JoinWindow.isOpen` with `actions.canJoin` for the reconnect tier (Task 1, `13ccd3d`). `ExploreTodaysSessionsSection` re-reads `session.isWithinJoinWindow` every minute, so Join Call enables at start minus 60 min without leaving the screen (Task 2, `ddc0163`). App-wide, `delta <= 3600` survives only in the two "starting now" pill helpers, by design.
- **Join shown disabled, not hidden (user decision 2026-11-10).** Android was read first (read-only): `TodaysSessionsSection.kt`, `ExploreTodaysSessionsSection.kt`, `UpcomingBookingCard.kt` and `ExpertUpcomingCard.kt` all render the shared `JoinCallButton(enabled = isWithinJoinWindow(...))` unconditionally; only the My Bookings `pending_approval` card shows a banner instead. Disabled on Android is the Material disabled state plus a `stateDescription` of `explore_join_call_state` ("Available closer to the session start"). iOS now matches on each screen: the dashboard strip (`1ab3f1f`), the Explore strip (`ddc0163`), and the 02-04 lists, My Bookings `JOIN CALL` and expert `Join Session` (`a620b92`). Android hides on none of the four, so nothing stays hidden.
- **One shown-versus-enabled predicate.** `JoinWindow.showsJoinButton(status:)` returns true for every status but `pendingApproval`; `JoinWindow.isOpen` keeps deciding enabled. Pinned by 4 new test functions (13 rows). The disabled state is the existing 55% accent, no glow, `.disabled(true)`; VoiceOver announces it as dimmed, and an `accessibilityHint` carries Android's wording.
- **`ClientBookingDetail.canJoin`** added as `Bool?` with the BACK-09 doc; decodes with `true`, `false` and absent (3 rows).
- **Stale docs fixed:** `ExpertBookingItem.Actions.canJoin` (Task 1), the Explore `isStartingNow` doc that claimed the `JoinWindow` rule.

## Task Commits

1. **Task 1: Tracer, expert dashboard strip uses JoinWindow with the server reconnect flag** - `13ccd3d` (fix; prior session)
2. **RED: pin Join shown-versus-enabled** - `b285b8b` (test)
3. **GREEN plus (a): expert dashboard strip shows Join disabled instead of hidden** - `1ab3f1f` (fix(02-14))
4. **(c): 02-04 lists show Join disabled instead of hidden, as Android does** - `a620b92` (fix(02-04))
5. **Task 2: live Explore join strip and client can_join** - `ddc0163` (fix(02-14))

**Plan metadata:** the docs commit that follows this file.

**Measured `commits: 7`** from the ledger base `87af01f` to `ddc0163`. Two of the seven are outside this plan and landed between the two sessions: `e43ef50` and `73e729e` (topics currency work). The plan's own commits are the five above.

## Files Created/Modified

- `ClickMe2026/Utils/JoinWindow.swift` - `showsJoinButton(status:)`, the shown-versus-enabled predicate (rule functions unchanged)
- `ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift` - Join Session on `JoinWindow.isOpen` with `actions.canJoin`, 60 s `TimelineView`, rendered for every card, dimmed and disabled when closed; symmetric-hour helper deleted
- `ClickMe2026/Model/Responses/Children/ExpertBookingItem.swift` - `canJoin` doc rewritten to BACK-09 (Task 1)
- `ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift` - Join Call in a 60 s `TimelineView`, rendered for every card, dimmed and disabled when closed; `isStartingNow` doc corrected, arithmetic untouched
- `ClickMe2026/Model/Responses/ClientBookingDetail.swift` - `let canJoin: Bool?`
- `ClickMe2026Tests/Utils/JoinWindowTests.swift` - presentation rows; new suite `ClientBookingDetail can_join`
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/Subviews/UpcomingBookingCard.swift` - `joinCallButton(enabled:)` always rendered outside the pending-approval banner case, dimmed and disabled when closed
- `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/Subviews/UpcomingBookingsSessionCard.swift` - Join Session always rendered, dimmed and disabled when closed; NOW badge still hides when closed

## Decisions Made

- **Supersedes D-12 (presentation half) and 02-UI-SPEC section 2.** D-12 in `02-CONTEXT.md` (line 38) says "Join disappears for those bookings on the Explore and expert dashboard strips"; `02-UI-SPEC.md` section 2 says "Not rendered" for both strips and "Hidden" for the two lists in the "Window closed" and "Not-joinable status" columns (lines 221 to 224), repeats it at line 228 ("Join disappears for pending_reschedule bookings"), in the focal-point table at lines 337 to 339, and in UI Considerations row S2 (line 355, "Hidden or not rendered on every Join surface"). All of those now read: **rendered, dimmed (55% accent, no glow) and disabled, VoiceOver "dimmed"**, on all four surfaces; only the awaiting-approval My Bookings card keeps its banner in place of the button. The rule half of D-12 (pending_reschedule is not joinable) and D-07 (server `can_join` for the reconnect tier) are unchanged. `02-UI-SPEC.md` itself was not edited in this plan; it needs this revision before the Phase 02 UAT, as 02-08 already required for its section 4.
- The plan's Task 1 acceptance criterion `grep -c "JoinWindow.isJoinableStatus"` in `ExpertDashboardView.swift` (want 1 or more) now reads 0, and the Explore key-link pattern `JoinWindow\.isJoinableStatus` is not present: both were the hide gate the user replaced. `JoinWindow.showsJoinButton` is at 1 in each file instead. User-directed, recorded here rather than as a deviation.
- `showsJoinButton` is also applied on the two strips and the expert list where `pending_approval` never appears (the strip view-models and the expert Upcoming bucket exclude it), so it is a no-op there today; it keeps the render rule in one place and matches Android's reachable behavior on every surface.

## TDD Notes

- **RED (`b285b8b`):** the tests name `JoinWindow.showsJoinButton`, so the symbol had to exist for the test target to compile (a build failure is INVALID_RED per `tdd.md`). It was declared with the body the views implemented at the time, `isJoinableStatus(status)`, the D-12 hide. Run: 13 tests in 1 suite, 2 failed with 8 issues, all on `showsJoinButton` (`/tmp/02-14-t2-red.log`). `gsd-tools check tdd-red-evidence` first returned `INVALID_RED (invalid_record: Incomplete swift-testing report)` on the raw xcodebuild log because the five parameterised result lines carry a U+200B prefix; with only those zero-width spaces stripped (no report content changed) it returned `RED_EVIDENCE_OK / target_test_failed` (13 tests, 11 pass, 2 fail, target matched). Semantic assessment: the target failed on the planned assertion for the intended reason; the 18 pre-existing rows passed; no compile, fixture or load failure.
- **GREEN (`1ab3f1f`):** `status != .pendingApproval`; JoinWindow suite passed inside the full run (205 tests in 23 suites passed, `/tmp/02-14-t2.log`).
- **No RED exists for `ClientBookingDetail.canJoin`:** in Swift the declaration is the whole feature, and a decode test cannot compile without it. The three decode rows were added with the property in `ddc0163` and passed on their first run (as 02-11 recorded for its Task 2).
- No REFACTOR commit; nothing to clean up.

## Deviations from Plan

**1. [User decision at the tracer gate] Join shown disabled instead of hidden**
- **Found during:** the Task 1 tracer human-verify gate; the user chose "disable like Android"
- **Issue:** D-12 and the plan hid Join for non-joinable bookings on the strips; Android disables on every Join surface
- **Fix:** `JoinWindow.showsJoinButton`, both strips, and the two 02-04 lists render Join and disable it; rule unchanged
- **Files modified:** `JoinWindow.swift`, `ExpertDashboardView.swift`, `ExploreTodaysSessionsSection.swift`, `UpcomingBookingCard.swift`, `UpcomingBookingsSessionCard.swift`, `JoinWindowTests.swift`
- **Verification:** JoinWindowTests presentation rows; BUILD SUCCEEDED; no new warnings
- **Committed in:** `b285b8b`, `1ab3f1f`, `a620b92`, `ddc0163`

**2. [Scope, user-directed] 02-04 list files edited in this plan**
- `UpcomingBookingCard.swift` and `UpcomingBookingsSessionCard.swift` are 02-04 files not in this plan's `files_modified`; the user asked for the same presentation on the lists with a `fix(02-04)` commit (`a620b92`). Their warning baseline was captured at HEAD before the edits (`/tmp/02-14-warn-before-v2.txt`, empty), and the after-build comparison printed nothing for them.

---

**Total deviations:** 2, both user-directed at the checkpoint. **Impact:** presentation only; the CALL-02 joining rule and the server authorization are untouched.

## Deferred Device Checks (PENDING, not passed)

The user deferred the Task 1 tracer device check because the behavior changed after the checkpoint. Recorded in `.planning/WINDOWS.md` as unrun-verify **#19** for plan 02-12 / `02-DEVICE-UAT-CHECKLIST.md`:

1. **Expert Dashboard strip:** Join Session turns enabled on its own within about a minute of start minus 60 min, with no refresh.
2. **Expert Dashboard strip:** a `pending_reschedule` card shows Join visible but dimmed and disabled; VoiceOver reads it as dimmed.
3. **Client Explore today strip:** the same two checks for Join Call.
4. **My Bookings and expert Upcoming list:** a `pending_reschedule` card shows Join disabled (changed by `a620b92`).

The 02-04 deferred checks' wording "no Join on a `pending_reschedule` booking" (02-04-SUMMARY items 1 and 3, and the UI-SPEC "intentional change" line) is **superseded**: the expected result is now a visible, disabled Join.

## Android Follow-up (logged, not built; restated from 02-04)

Android's `managers/JoinWindow.kt` still treats `pending_reschedule` as joinable (`JOINABLE_BOOKING_STATUSES` plus a `completed`-until-end branch) and deliberately ignores the server `can_join` flag. That is the rule-side follow-up already logged in 02-04 and it still stands: remove `pending_reschedule` from the joinable statuses, and use `can_join` for the reconnect tier to end plus 60. Android's presentation (Join rendered and disabled) is what iOS now matches, so no Android presentation change is needed. No Android file was modified in this plan.

## Issues Encountered

- Warning baseline: the plan's `/tmp/02-14-warn-before.txt` (four files, from the prior session) was empty; the re-baseline at HEAD for all eight touched files (`/tmp/02-14-warn-before-v2.txt`) was also empty. After the final build (`/tmp/02-14-build.log`, BUILD SUCCEEDED), `comm -13` against both printed nothing. The build's single warning is in an unrelated file. The test build reported 0 warnings in `JoinWindowTests.swift`.
- Verification ran the whole unit-test target (with the three non-compiling or live-production test files excluded as the dispatch requires) rather than only the plan's two suites: 205 tests in 23 suites passed.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths or schema changes; the strip and list buttons remain display gates behind the server's `POST /join` check (T-02-31 mitigated: both strips call the plan 02-04 helper, the dashboard passes `actions.canJoin`, each re-reads every minute, and the app-wide gate shows no symmetric-hour copy).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-12 must carry WINDOWS #19 (this plan's four device checks) and revise the 02-04 wording; 02-UI-SPEC section 2 needs the "disabled, not hidden" revision before the Phase 02 UAT.
- Phase 3 can read `ClientBookingDetail.canJoin` on Upcoming Booking details (CALL-03) and reuse `JoinWindow.showsJoinButton` / `isOpen` on the detail and expert summary screens (CALL-08, CALL-10).
- CALL-02 stays marked complete on the strength of the unit tests and clean build; its device verification is outstanding and tracked above.

## Self-Check: PASSED

- FOUND: all eight modified files on disk
- FOUND commits 13ccd3d, b285b8b, 1ab3f1f, a620b92, ddc0163 (ancestors of HEAD)
- Tests: 205 tests in 23 suites passed; BUILD SUCCEEDED; new-warning comparison empty; app-wide `delta <= 3600` outside the pill helpers: 0

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
