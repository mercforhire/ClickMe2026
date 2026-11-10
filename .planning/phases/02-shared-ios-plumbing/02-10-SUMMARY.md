---
phase: 02-shared-ios-plumbing
plan: 10
subsystem: push-routing
tags: [push, apns, fcm, route_category, target_role, mode-switch, swift-testing, tdd]

requires:
  - phase: 02-shared-ios-plumbing
    provides: plan 02-09's shared PushDestination table, homeStack registration and replace(with:) in both shells
provides:
  - Non-failable PushEvent.init(userInfo:) reading route_category, route_sub_category, target_role and UUID ids, with Android's full event_type fallback table and the booking_id-only booking fallback
  - PendingPush, PushPlan, PushAccountSource (.live) and PushRoutePlanner (plan, canUseExpertMode, needsRoles)
  - PushRouter.pending queue, handleTap(_:isSignedIn:) and planPending(currentMode:account:)
  - consumePendingPush in both shells, re-triggered when roles load and when the app becomes active
  - PushEventTests (16) and PushRoutePlannerTests (14)
affects: [02-11 foreground presentation options, 02-12 logout clears the queue and the device UAT checklist, phase 3 booking actions on push-opened screens]

actuals:
  tokens: 12792
  tasks: 2
  commits: 5
plan_head_before: 1af56bc0de3a39701107de25d2128404d2a76422
plan_head_after: deaa405fe4e9a02ec2be5c1b7a0c3f1b49fb8888

tech-stack:
  added: []
  patterns:
    - "Push parse order: route_category, then uppercased event_type through the Android table, then booking_id alone means booking; anything else is nil and opens the notifications list"
    - "A tapped push is a PendingPush (destination plus target role) queued on PushRouter; the shell for the current mode asks planPending what to do, switches mode or opens the destination, and clears it"
    - "PushAccountSource is the injected seam for roles and expert setup; tests pass fakes, production passes .live"
    - "Swift RED commits carry compile-only stubs of new types so the suite builds and fails on its assertions (a build failure is not a RED)"

key-files:
  created:
    - ClickMe2026Tests/Push/PushEventTests.swift
    - ClickMe2026Tests/Push/PushRoutePlannerTests.swift
    - .planning/phases/02-shared-ios-plumbing/02-10-tdd-red-evidence.json
    - .planning/phases/02-shared-ios-plumbing/02-10-tdd-red-evidence-fallback.json
  modified:
    - ClickMe2026/Model/Push/PushEvent.swift
    - ClickMe2026/ClickMe2026AppDelegate.swift
    - ClickMe2026/Managers/PushRouter.swift
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026/Views/Screens/Notification/NotificationsListView.swift

key-decisions:
  - "02-10: a push with no route_category and no known event_type but a valid booking_id routes as a booking push (user decision at the Task 1 gate, Android parity with PushEvent.kt RESEARCH F-1); the plan's truth that sent this case to the notifications list is superseded"
  - "02-10: D-03 is applied only to the client-to-expert switch; a session already in expert mode keeps routing expert-targeted pushes without reading roles"
  - "02-10: an expert-targeted tap in client mode is never decided from a nil me; planPending reloads me once and otherwise leaves the tap queued for the next trigger (new tap, roles loading, app active, shell appearing)"
  - "02-10: the PUSH-01 device check was deferred by the user at the tracer gate and is PENDING for 02-12"

patterns-established:
  - "Shell push hooks: onChange(pushRouter.pending), onAppear, onChange(userManager.me?.roles) and onChange(scenePhase) == .active all call the same consumePendingPush; running a plan twice is harmless"
  - "A mode switch made for a push does not clear the queue; the shell that mounts for the new mode consumes it"

requirements-completed: [PUSH-01, PUSH-02, PUSH-03, BOOK-15]

coverage:
  - id: D1
    description: "Push taps are parsed from route_category and route_sub_category; the Android-only category key is never read; route_category wins over event_type; a nested data dictionary wins over root keys"
    requirement: PUSH-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushEventTests.swift (16 tests, 1 suite; /tmp/02-10-t2.log)"
        status: pass
      - kind: other
        ref: "grep -c 'data[\"category\"]' PushEvent.swift = 0; grep -c route_category >= 1; grep -c 'init?(userInfo' = 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "When route_category is empty, event_type falls back through Android's full table; a booking_id-only payload is a booking push; an empty or unknown payload with no booking_id opens the notifications list"
    requirement: PUSH-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushEventTests.swift#every event_type in the fallback table maps as Android does (19 cases)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushEventTests.swift#a payload with only a booking_id is a booking push, as on Android"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#a tap with no route_category and no known event_type opens the notifications list"
        status: pass
    human_judgment: false
  - id: D3
    description: "A real booking-confirmed push tapped in client mode opens that booking on the Bookings tab with no warning page, and Back returns to My Bookings (PUSH-01 device check)"
    requirement: PUSH-01
    verification: []
    human_judgment: true
    rationale: "Device check deferred by the user at the Task 1 tracer gate; PENDING for 02-12 and the 02-DEVICE-UAT-CHECKLIST.md. Not run, not passed."
  - id: D4
    description: "A push whose target_role differs from the current mode switches mode silently and opens the destination in the other shell; an absent target_role keeps the current mode; an account without the expert role or a completed expert setup is never switched into expert mode and opens the notifications list"
    requirement: PUSH-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#plan keeps or switches the mode from the target role (8 cases)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#expert mode needs the expert role and a completed setup"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#a client-only account is decided from its known roles without a reload"
        status: pass
    human_judgment: true
    rationale: "The planner is unit-tested; the shell swap (ClickMe2026App mirroring currentMode onto the route) and the on-screen result need the PUSH-02 device checks in the Task 2 human-check (warm and cold, both directions, client-only account)"
  - id: D5
    description: "A booking-request push in client mode on a set-up expert account switches to expert mode and opens that request; a payment_actions push opens that booking"
    requirement: PUSH-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#a booking-request tap for the expert role queues that request with the expert target"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#an expert tap with unknown roles is planned once the reload brings them"
        status: pass
    human_judgment: true
    rationale: "Queue and plan are unit-tested; RequestDecisionView opening from the push after the mode switch is a device check (PUSH-03 in the Task 2 human-check)"
  - id: D6
    description: "A payment_actions push with a client target queues the booking detail with the client role (route only, D-01)"
    requirement: BOOK-15
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#a payment_actions tap for the client role queues that booking with the client target (BOOK-15)"
        status: pass
    human_judgment: false
  - id: D7
    description: "A tap while no account is signed in is dropped; the later of two taps is the one routed; a tap held for unknown roles reloads me once and stays queued, and a tap replaced while loading is not planned"
    requirement: PUSH-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#a tap while no account is signed in is dropped"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#the later of two taps is the one queued"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#an expert tap with unknown roles reloads them once and stays queued when they stay unknown"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Push/PushRoutePlannerTests.swift#an expert account with no loaded setup fetches the expert profile once; a failed fetch counts as cannot"
        status: pass
    human_judgment: false
  - id: D8
    description: "A tap that launches the app is held until the shell for its mode appears, then routed once; a second tap arriving during a mode switch ends on the second tap's destination"
    requirement: PUSH-02
    verification: []
    human_judgment: true
    rationale: "Cold-launch ordering and the in-flight switch are runtime behaviors of the shells; covered by the Task 2 human-check items (4) and (6) and marked backstop in the plan"

duration: ~15 min this session (Task 1 and its tracer gate in the prior session)
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 10: Push taps route on route_category and switch mode from target_role Summary

**Push taps parse `route_category` with Android's `event_type` and `booking_id` fallbacks, and a `PendingPush` queue plus a pure `PushRoutePlanner` switch the app into the push's `target_role` mode (never into an un-set-up expert mode) before the shell opens the destination, surviving cold launch and the shell swap.**

## Performance

- **Duration:** about 15 min in this continuation (deviation plus Task 2); Task 1 and its device gate ran in the prior session
- **Completed:** 2026-11-10
- **Tasks:** 2 planned, plus 1 user-directed deviation
- **Files modified:** 10 (6 app files, 2 new test files, 2 RED evidence records)

## Accomplishments

- `PushEvent.init(userInfo:)` is non-failable. It reads `route_category` / `route_sub_category` (trimmed, lowercased, empty is nil), falls back through the uppercased `event_type` with Android's full 19-row table (D-16), then treats a payload with only a valid `booking_id` as a `booking` push (Android parity), and reads `target_role` as `.client` / `.expert` only. The Android-only `category` key is never read (D-05). `raw` is gone.
- `PushRouter.pending: PendingPush?` replaces the destination-only property. `handleTap(_:isSignedIn:)` drops taps with no stored session (T-02-20) and queues the newest tap from the shared 02-09 table, falling back to `.notificationsList`.
- `PushRoutePlanner` is pure: `plan` applies D-02 and D-03 (client to expert only when `canUseExpertMode`; a session already in expert mode is never forced out), `canUseExpertMode` needs the expert role and `setup_completed == true`, `needsRoles` is true only for an expert-targeted tap in client mode.
- `planPending(currentMode:account:)` reloads `me` once when roles are unknown and otherwise leaves the tap queued (T-02-28), fetches the expert profile once when it is missing (a failed fetch counts as cannot, A8), and returns nil when a newer tap replaced the queued one while loading.
- Both shells call one `consumePendingPush()` from `onChange(pushRouter.pending)`, `onAppear`, `onChange(userManager.me?.roles)` and `onChange(scenePhase)` when `.active`. A mode switch leaves the tap queued for the other shell; otherwise the destination opens and the queue clears. Notifications-list rows queue a `PendingPush` with no target role.
- 41 tests in 3 suites pass (`PushEventTests` 16, `PushRoutePlannerTests` 14, `PushDestinationTableTests` 11). No test reaches the network: `PushAccountSource` is faked.

## Task Commits

1. **Task 1: Tracer, a real push tap opens its screen again (route_category parse)** - `90a2dba` (fix) — prior session
2. **Deviation: booking_id-only fallback (Android parity)** - `36b99a8` (test, RED) then `13ca3d2` (fix, GREEN)
3. **Task 2: target_role switches mode before routing; queued tap survives cold launch and the shell swap** - `25988c8` (test, RED) then `deaa405` (fix, GREEN)

**Plan metadata:** committed separately (docs: complete plan).

## TDD evidence

- Deviation RED: `02-10-tdd-red-evidence-fallback.json`, `RED_EVIDENCE_OK` (16 tests, 14 pass, 2 fail; the two fallback rows fail on `event.category == "booking"` with nil). GREEN: 27 tests in 2 suites pass (PushEventTests plus PushDestinationTableTests).
- Task 2 RED: `02-10-tdd-red-evidence.json`, `RED_EVIDENCE_OK` (14 tests, 2 pass, 12 fail; target "an expert tap with unknown roles is planned once the reload brings them"). The RED commit carries the new types as compile-only stubs with default-returning bodies, because a Swift test naming undeclared types is a build failure, not a RED. The two trivially-passing rows (nothing queued; signed-out tap dropped) are guards and still pass after GREEN. GREEN: 41 tests in 3 suites pass.
- Commit types follow the user's instruction for this continuation (`test(02-10)` then `fix(02-10)`), not the `feat(...)` GREEN form in the TDD reference; the plan is `type: execute` with `tdd="true"` on Task 2, so no plan-level TDD gate applies.

## Tracer outcome (Task 1)

The Task 1 tracer gate was answered by the user with "approve and defer, add the Android fallback". The PUSH-01 device check was **not run** and is **PENDING** (see below). Execution continued per that approval.

## Files Created/Modified

- `ClickMe2026/Model/Push/PushEvent.swift` - non-failable parse, route keys, event_type table, booking_id fallback, target_role
- `ClickMe2026/ClickMe2026AppDelegate.swift` - builds the event without optional binding; DEBUG line prints category, sub-category and target_role only (Task 1)
- `ClickMe2026/Managers/PushRouter.swift` - `PendingPush`, `PushPlan`, `PushAccountSource`, `PushRoutePlanner`, `pending`, `handleTap(_:isSignedIn:)`, `planPending`
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` - `consumePendingPush`, four triggers, `scenePhase`
- `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift` - same
- `ClickMe2026/Views/Screens/Notification/NotificationsListView.swift` - row tap queues a `PendingPush`
- `ClickMe2026Tests/Push/PushEventTests.swift` - parse matrix including the booking_id fallback rows
- `ClickMe2026Tests/Push/PushRoutePlannerTests.swift` - plan, canUseExpertMode, needsRoles, planPending with a fake account, handleTap queue

## Decisions Made

- The booking_id-only fallback is in (user decision, Android parity). Android's `PushEvent.kt` keeps `sub_category` as-is in that branch; iOS keeps `route_sub_category` the same way, so the table's `booking/<anything else>` row opens the booking detail.
- D-03 applies only to the client-to-expert switch (plan assumption confirmed in code and tests).
- `PushAccountSource.live` is a computed static property rather than a stored `static var`, because a stored mutable global of a non-Sendable struct does not compile under strict concurrency. Same seam, same name.
- The expert-profile fetch happens only inside the `needsRoles` branch; a tap that does not switch into expert mode never reads or loads expert setup.

## Deviations from Plan

### User-directed

**1. [User decision - Android parity] booking_id-only payloads route as booking pushes**
- **Found during:** Task 1 tracer gate (user reply "approve and defer, add the Android fallback")
- **Issue:** The plan's truth "an empty or whitespace route_category with no known event_type ... opens the notifications list" sent the cron reminder, no-show and nudge pushes (which carry only `booking_id`) to the notifications list, while Android (`PushEvent.kt` L80-83, RESEARCH F-1) opens the booking.
- **Fix:** After the `event_type` table, a valid `booking_id` makes the category `booking` with `route_sub_category` as the sub-category. No `booking_id`, or a malformed one, still gives nil. The `unknownEventType` test row that pinned the old behavior now has no `booking_id`; three new rows cover the fallback and its guard.
- **Files modified:** `ClickMe2026/Model/Push/PushEvent.swift`, `ClickMe2026Tests/Push/PushEventTests.swift`
- **Verification:** RED `36b99a8` (RED_EVIDENCE_OK), GREEN `13ca3d2`, 27 tests pass
- **Plan conflict flagged:** this overrides plan truth 4 and the `fails_when` wording of PUSH-01 as written; the phase user preference (match Android when iOS differs) applies.

### Auto-fixed

**2. [Rule 3 - Blocking] Parameterized test rows could not read `@MainActor` fixtures**
- **Found during:** Task 2 RED
- **Issue:** `@Test(arguments:)` evaluates its argument list outside the suite's `@MainActor` isolation, so rows referencing the suite's static fixtures failed to compile ("expression is 'async' but is not marked with 'await'").
- **Fix:** The three shared fixtures (`a`, `d`, `expertRequest`) are `nonisolated static let`; all are Sendable values.
- **Files modified:** `ClickMe2026Tests/Push/PushRoutePlannerTests.swift`
- **Committed in:** `25988c8`

---

**Total deviations:** 1 user-directed (Android parity), 1 auto-fixed (Rule 3, test compile)
**Impact on plan:** The fallback widens PUSH-01 routing to match Android; everything else executed as written.

## Issues Encountered

- The swift-testing console emits some result lines with leading zero-width spaces (U+200B), which made a glyph-anchored grep drop three lines and the classifier report "Incomplete swift-testing report". Stripping U+200B before extracting the report fixed it; both RED records were classified on complete reports.

## Pending device checks (UAT) — PENDING, not passed

Deferred by the user at the Task 1 tracer gate; to be picked up by 02-12 for `02-DEVICE-UAT-CHECKLIST.md`. Recorded in `.planning/WINDOWS.md` as an unrun verify.

- **PUSH-01 (Task 1 human-check, DEFERRED):** client in client mode with the app backgrounded; the expert accepts a pending request; tap the booking-confirmed push. Expected: the Bookings tab opens on that booking, with no SwiftUI warning page, and Back returns to My Bookings.
- **PUSH-02, PUSH-03, BOOK-15 (Task 2 human-check, warm and cold):** (1) client mode on a set-up expert account, tap a booking-request push: switches to expert mode and opens that request. (2) expert mode, tap a client-targeted booking-confirmed push: switches to client mode and opens the booking. (3) client-only account, expert-targeted push: stays in client mode, opens the notifications list. (4) force-quit, tap a push: launches in the right mode, opens the screen once. (5) payment_actions push opens that booking. (6) roles unknown at cold launch (airplane mode, last mode client, set-up expert account): client home opens with no notifications list; after airplane mode is turned off and Control Center closes, the app switches to expert mode and opens the request. Action buttons on push-opened screens may be inert until Phase 3.
- **Android parity check (new):** a cron reminder, no-show or nudge push (booking_id only) opens that booking on both platforms.

## Known Stubs

None.

## Threat Flags

None new. T-02-18 (untrusted payload) is covered by the parse tests; T-02-19 (switch into expert mode) by `canUseExpertMode` and the D-03 rows; T-02-20 (signed-out tap) by `handleTap(isSignedIn: false)`; T-02-28 (decision from unknown roles) by the planPending hold rows. Plan 02-12 still has to clear `pending` on logout.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 02-11 can change the `willPresent` options; `handleForegroundArrival` is unchanged.
- 02-12 must clear `PushRouter.shared.pending` on logout and put the PUSH-01 and Task 2 device checks in the UAT checklist.
- Android needs no change: it already routes on `category`, reads `target_role`, and has the booking_id fallback this plan copied.
- No backend or API change.

## Self-Check: PASSED

- Created files exist: `ClickMe2026Tests/Push/PushEventTests.swift`, `ClickMe2026Tests/Push/PushRoutePlannerTests.swift`, both RED evidence JSON files.
- Commits `90a2dba`, `36b99a8`, `13ca3d2`, `25988c8`, `deaa405` are ancestors of HEAD; `git rev-list --count 1af56bc..HEAD` = 5 (measured from the plan ledger).
- Plan verification: `xcodebuild build` succeeded (`/tmp/02-10-build.log`); warning comparison for the six app files against the 0-line baseline printed nothing; the only build warning is the `appintentsmetadataprocessor` toolchain line. No new DEBUG line prints a token, a bearer or the full userInfo.
- Acceptance: PushEventTests and PushRoutePlannerTests pass every row (41 tests, 3 suites, `/tmp/02-10-t2.log`); `init?(userInfo` count 0; `struct PendingPush` count 1; `pendingDestination` references 0; both shells call `planPending` with their own mode and re-trigger on `userManager.me?.roles` and `scenePhase`; `func needsRoles` and `struct PushAccountSource` present.

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
