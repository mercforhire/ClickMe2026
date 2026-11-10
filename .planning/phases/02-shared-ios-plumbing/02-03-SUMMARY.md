---
phase: 02-shared-ios-plumbing
plan: 03
subsystem: bookings
tags: [swift, swiftui, realtime, booking-status, swift-testing]

requires:
  - phase: 01
    provides: none (independent iOS plumbing fix)
provides:
  - BookingStatus.rescheduled and BookingStatus.unknown with a decode that never fails on a string
  - Every exhaustive BookingStatus switch decides both new cases explicitly, with no default branch
  - ReloadGeneration, a token so only the newest overlapping refetch writes a screen
  - Expert Upcoming Bookings list that keeps the newest of overlapping refetches and always settles its load state
affects: [02-04-join-helper, 02-13-client-refetch-gating, phase-02-device-uat, android-status-parity]

plan_head_before: 6d110c608441ed74728bd69a9ad7641bfa04b65f
plan_head_after: c87cfeab1f24388d046aef964bb6807f475bbafd

actuals:
  tokens: 5700
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Server-mirrored enums decode tolerantly: init(from:) reads a String and falls back to .unknown, as ErrorCode already does"
    - "Overlapping refetches: take a ReloadGeneration token before the first await, write data and load state only while isCurrent(token)"

key-files:
  created:
    - ClickMe2026/Utils/ReloadGeneration.swift
    - ClickMe2026Tests/Model/BookingStatusDecodingTests.swift
    - ClickMe2026Tests/Utils/ReloadGenerationTests.swift
  modified:
    - ClickMe2026/Model/Enums/BookingStatus.swift
    - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift

key-decisions:
  - "rescheduled and unknown are never strip members and never joinable on Explore or the expert dashboard; whether Join is offered is the plan 02-04 join helper's call (D-12)"
  - "Expert Upcoming Bookings lists an unknown or rescheduled booking under Upcoming until its session ends, then under Past as missed, rather than hiding it"
  - "No neutral status label is added: no subscriber reads event.status, so a pill keeps the previous status until the refetch lands and then shows the server's state"
  - "Generation counter, not task cancellation: a superseded fetch finishes its network call and writes nothing"
  - "The token is taken by the caller (forceLoad, silentReload) and passed to runFetch(token:), so forceLoad can tell a superseded fetch (writes no load state) from a genuine failure or cancellation of the newest fetch (still shows .failed, as before)"

patterns-established:
  - "ReloadGeneration: nonisolated value type owned as an @ObservationIgnored property of the view model"

requirements-completed: [BOOK-18]

coverage:
  - id: D1
    description: "A realtime booking.update with status rescheduled decodes as .rescheduled, any unrecognised status decodes as .unknown, the nine existing statuses are unchanged, and EndCallData and BookingStatusMeta no longer fail on an unknown status"
    requirement: BOOK-18
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Model/BookingStatusDecodingTests.swift#realtimeRescheduled, realtimeUnknown, knownRawValues, decodeIsStable, endCallDataUnknown, metaUnknown, metaRescheduled"
        status: pass
    human_judgment: true
    rationale: "Decoding is unit tested, but the screen refreshing without a pull-to-refresh when the other party proposes a reschedule is a two-device behavior (Phase 2 device checklist, BOOK-18 item 1)."
  - id: D2
    description: "Every exhaustive switch on BookingStatus names .rescheduled and .unknown explicitly, with no default branch"
    requirement: BOOK-18
    verification:
      - kind: other
        ref: "xcodebuild test (Debug, iPhone 17): compiles with all five switches exhaustive and no new warnings in the touched files"
        status: pass
    human_judgment: false
  - id: D3
    description: "Overlapping refetches on the expert Upcoming Bookings list leave it on the newest response, whatever order the responses land in, and the load state is always settled by the newest fetch"
    requirement: BOOK-18
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ReloadGenerationTests.swift#freshTokenIsCurrent, secondBeginSupersedesFirst, checkOrderDoesNotMatter, newerFetchResumedFirst, olderFetchResumedFirst"
        status: pass
    human_judgment: true
    rationale: "The token and both completion orders are unit tested against a test-local screen. The wiring into UpcomingBookingsViewModel (real network, pull-to-refresh during a socket refetch, no stuck spinner) is a device check (Phase 2 device checklist, BOOK-18 item 2)."

duration: "about 70 min wall clock, including the pause on the protected-branch commit guard"
completed: 2026-11-09
status: complete
---

# Phase 2 Plan 03: Booking status decode and newest-refetch gating Summary

**BookingStatus now decodes `rescheduled` and any unknown string instead of dropping the whole `booking.update`, and a ReloadGeneration token keeps the expert Upcoming Bookings list on the newest of overlapping refetches**

## Performance

- **Duration:** about 70 min wall clock (Task 1 work was finished by an earlier executor that could not commit; this run committed it, then did Task 2)
- **Started:** 2026-11-09T19:39 -0500 (HEAD 6d110c6)
- **Completed:** 2026-11-10T01:50Z
- **Tasks:** 2
- **Files modified:** 9 (3 created, 6 modified)

## Accomplishments

- `RealtimeService` decodes each socket event with `try?` and returns on failure, so one unknown status used to drop the whole event and leave the open screen stale. `BookingStatus.init(from:)` now reads a `String` and falls back to `.unknown`; `rescheduled` (a socket-only value per the backend socket contract) is its own case. A missing or non-string status still throws.
- The same tolerant decode covers the REST shapes that carry a status (`EndCallData`, `BookingStatusMeta`, and through the same enum `ConfirmConnectionData`, `BookingRequestData`, `ConfirmBookingData`), so a status this build does not know no longer fails a list or detail response.
- `ReloadGeneration` (`begin()` / `isCurrent(_:)`) gates the expert Upcoming Bookings list. A `booking.update` during a load, or a pull-to-refresh during a socket refetch, can no longer let an older response overwrite a newer one.
- `silentReload()` during a forced load now runs a forced load, so the booking.update supersedes that load instead of being skipped.

## Switch sites decided (Task 1)

| Switch | `.rescheduled` / `.unknown` |
|--------|-----------------------------|
| `ExploreClientViewModel.isJoinable` | `false` (not strip members) |
| `ExpertDashboardViewModel.isJoinable` | `false` (not strip members) |
| `BookingSummaryViewModel.mapStatus` | `nil` (badge hidden rather than wrong) |
| `UpcomingBookingsViewModel.isUpcoming` | `true` (row visible under Upcoming; the guard above the switch already drops an ended session; Join stays closed via the 02-04 join helper) |
| `UpcomingBookingsViewModel.mapPastIfApplicable` | joins the non-terminal branch (past as missed once the session has ended, otherwise nil) |
| `ClientProfileViewModel.mapStatus` | `.upcoming`, with the other non-terminal cases |

`MyBookingsViewModel` and `PayoutsViewModel` already had default branches and were left alone. The compiler listed no other exhaustive switch.

## Fetch paths gated by ReloadGeneration

- `UpcomingBookingsViewModel` (expert Upcoming Bookings): `forceLoad()` (behind `load()`, `reload()` and pull-to-refresh), `silentReload()` (behind the booking.update subscriber and `.onAppear`) and `runFetch(token:)`.
- Plan 02-13 applies the helper to `UpcomingBookingViewModel`, `BookingSummaryViewModel` and `MyBookingsViewModel`.

## Task Commits

1. **Task 1: Tracer, rescheduled and unknown statuses reach the open screen** - `7dd8415` (fix)
2. **Task 2: Overlapping refetches on the expert Upcoming Bookings list keep the newest response** - `c87cfea` (fix)

**Plan metadata:** committed separately (docs: complete plan)

## Files Created/Modified

- `ClickMe2026/Model/Enums/BookingStatus.swift` - `rescheduled`, `unknown`, tolerant `init(from:)`
- `ClickMe2026/Utils/ReloadGeneration.swift` - generation token, `nonisolated struct`
- `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift` - new cases in two switches; token gating on `forceLoad`, `silentReload`, `runFetch(token:)`
- The other five view models above - one case list each
- `ClickMe2026Tests/Model/BookingStatusDecodingTests.swift` - 9 decode tests (realtime and REST shapes)
- `ClickMe2026Tests/Utils/ReloadGenerationTests.swift` - 5 tests including both completion orders

## Decisions Made

See `key-decisions` above. In short: both new statuses are non-joinable and non-strip members, the list keeps an unknown booking visible rather than hiding it, no neutral label, and a generation counter rather than task cancellation.

## Deviations from Plan

None - plan executed exactly as written.

One implementation detail differs from the plan's wording, not its outcome: the plan says `runFetch()` takes the token. Here `forceLoad()` and `silentReload()` call `reloads.begin()` before their first `await` and pass the token to `runFetch(token:)`. `forceLoad` needs the token itself to decide, in its catch, whether it was superseded (write nothing) or is the newest fetch failing or being cancelled (show `.failed`, as before). Taking the token inside `runFetch` would leave a genuine cancellation of the newest fetch stuck on `.loading`.

## Issues Encountered

- The earlier executor finished Task 1 but the protected-branch commit guard refused `main`. The user then chose "allow-main" and the orchestrator set `git.allow_default_branch_commits: true`. The diff was reviewed against Task 1 and committed unchanged.
- Warning baseline for the touched files was empty before the work and is empty after (only the unrelated `appintentsmetadataprocessor` notes appear in the log).

## Verification

- `xcodebuild test` for `ReloadGenerationTests` and `BookingStatusDecodingTests` on iPhone 17: 14 tests in 2 suites passed, `** TEST SUCCEEDED **`.
- Gate on `UpcomingBookingsViewModel.swift`: `ReloadGeneration()` present, 3 `isCurrent(` checks.
- No-regression guard: none of the four booking.update subscribers reads `event.status`.
- Tracer re-verified end to end at the final state (same test run).
- Device checks (not run, pending in the Phase 2 UAT checklist): (1) with Upcoming Booking details open on the client, have the expert propose a reschedule from another device and see the client screen update without a pull-to-refresh; (2) with the expert Upcoming Bookings tab open, have the client cancel or reschedule from another device while pulling to refresh, and see the row end in its new state with no stuck spinner.

## Known Stubs

None.

## Threat Flags

None. T-02-06, T-02-07 and T-02-27 are mitigated as planned; no new network, auth or file surface was added.

## User Setup Required

None - no external service configuration required.

## Cross-repo notes

No backend change and no API change. Android keeps unknown statuses as raw strings and drops or neutralizes them (`BookingStatusDisplay.kt`), so no Android change is needed for this plan.

## Next Phase Readiness

- `ReloadGeneration` is ready for plan 02-13, which gates the client detail, summary and My Bookings refetches.
- The plan 02-04 join helper decides Join for `.rescheduled` and `.unknown`; this plan left both closed everywhere a strip or list decides it.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ReloadGeneration.swift
- FOUND: ClickMe2026Tests/Model/BookingStatusDecodingTests.swift
- FOUND: ClickMe2026Tests/Utils/ReloadGenerationTests.swift
- FOUND commit: 7dd8415
- FOUND commit: c87cfea

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-09*
