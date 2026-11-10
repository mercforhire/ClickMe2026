---
phase: 02-shared-ios-plumbing
plan: 13
subsystem: bookings
tags: [swift, swiftui, realtime, booking-update, reload-generation, race]

requires:
  - phase: 02-03
    provides: ReloadGeneration (begin() / isCurrent(_:)) and the newest-refetch pattern on the expert Upcoming Bookings list
  - phase: 02-05
    provides: the price formatting in UpcomingBookingViewModel and BookingSummaryViewModel that this plan leaves alone
provides:
  - Newest-refetch gate on UpcomingBookingViewModel.forceLoad() (client Upcoming Booking details)
  - Newest-refetch gate on BookingSummaryViewModel.forceLoad(bookingId:) (client Booking Summary)
  - Newest-refetch gate on MyBookingsViewModel.forceLoad() and silentReload() (client My Bookings), with silentReload() running a forced load while one is in flight so the spinner is always settled by the newest call
affects: [02-12-device-uat, phase-02-verification, android-parity]

plan_head_before: 5b0f15a0900a554a4b48979e9963902ab713c41e
plan_head_after: ff4f3992404c6828ddbf606feaadb7704cf3cfbc

actuals:
  tokens: 2000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Overlapping refetches on a client booking screen: take a ReloadGeneration token before the first await, guard reloads.isCurrent(token) after every await and in the catch, return without writing when superseded"
    - "A silent (background) reload that finds a forced load in flight runs a forced load itself, so the newest call owns the load state"

key-files:
  created: []
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift

key-decisions:
  - "02-13: the three client booking screens use the 02-03 ReloadGeneration counter (newest started wins, superseded fetch writes nothing, no task cancellation); Android reaches the same latest-wins outcome by cancelling the previous job, so no Android change is needed"
  - "02-13: MyBookingsViewModel.silentReload() runs forceLoad() while state is .loading, so a booking.update during a pull-to-refresh supersedes that load instead of racing it, and the newest call always settles the spinner"
  - "02-13: BOOK-18 client device check deferred by the user at the Task 1 tracer gate (approve and defer), PENDING for 02-12 (WINDOWS #18)"

patterns-established:
  - "Per-fetch-path token: forceLoad and silentReload each take their own token; a superseded call returns at the first failed isCurrent check"

requirements-completed: [BOOK-18]

coverage:
  - id: D1
    description: "Overlapping refetches on client Upcoming Booking details and Booking Summary leave the screen on the newest response, and the newest refetch settles the load state (no stranded spinner)"
    requirement: BOOK-18
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ReloadGenerationTests.swift#freshTokenIsCurrent, secondBeginSupersedesFirst, checkOrderDoesNotMatter, newerFetchResumedFirst, olderFetchResumedFirst (xcodebuild test, iPhone 17, /tmp/02-13-t1.log and /tmp/02-13-t2.log)"
        status: pass
      - kind: other
        ref: "grep gate: ReloadGeneration() present and isCurrent( count >= 2 in UpcomingBookingViewModel.swift (2) and BookingSummaryViewModel.swift (5)"
        status: pass
    human_judgment: true
    rationale: "The token rules and both completion orders are unit tested against a test-local screen. The wiring into the two view models (real network, pull-to-refresh at the moment the expert proposes a reschedule from another device, no stuck spinner) is a two-device check, deferred by the user; WINDOWS #18, pending for 02-12."
  - id: D2
    description: "Overlapping refetches on client My Bookings end on the newest response with the load state settled; a booking.update during a forced load supersedes it rather than racing it"
    requirement: BOOK-18
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ReloadGenerationTests.swift (same five tests; /tmp/02-13-t2.log: Test run with 14 tests in 2 suites passed)"
        status: pass
      - kind: other
        ref: "grep gate: ReloadGeneration() present and isCurrent( count 3 in MyBookingsViewModel.swift"
        status: pass
    human_judgment: true
    rationale: "Device step: with My Bookings open, the expert cancels or reschedules from the other device while the client pulls to refresh; the row ends in its new state and the list is not left on a spinner. Deferred by the user; WINDOWS #18, pending for 02-12."
  - id: D3
    description: "Every booking.update still triggers a refetch on the three screens whatever its status: subscriber closures, load() and reload() are unchanged and none reads event.status"
    requirement: BOOK-18
    verification:
      - kind: other
        ref: "no-regression guard: grep -c 'event\\.status' is 0 in all three view models; git diff 5b0f15a..ff4f399 touches only the reloads property, forceLoad, silentReload and their doc comments"
        status: pass
    human_judgment: false
  - id: D4
    description: "Clean build with no new warnings in the three plan files"
    requirement: BOOK-18
    verification:
      - kind: other
        ref: "xcodebuild build (Debug, iPhone 17) BUILD SUCCEEDED, /tmp/02-13-build.log; comm -13 /tmp/02-13-warn-before.txt /tmp/02-13-warn-after.txt prints nothing"
        status: pass
    human_judgment: false

duration: "~4 min (continuation; Task 1 in prior session)"
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 13: Newest refetch on the client booking screens Summary

**The three client booking screens (Upcoming Booking details, Booking Summary, My Bookings) now gate every fetch path with the 02-03 ReloadGeneration token, so an older `booking.update` or pull-to-refresh response that lands last can no longer overwrite a newer one or leave a spinner running**

## Performance

- **Duration:** ~4 min for this continuation (Task 2, verification, SUMMARY). Task 1 was done by the previous executor, which stopped at the tracer human-verify gate; the user answered "approve and defer".
- **Started:** 2026-11-10T06:28:59Z (continuation; Task 1 committed 2026-11-10T06:24:10Z)
- **Completed:** 2026-11-10T06:32:59Z
- **Tasks:** 2
- **Files modified:** 3 (57 insertions, 0 deletions)

## Accomplishments

- `UpcomingBookingViewModel.forceLoad()` takes a token before `state = .loading`, and applies the detail and `.loaded` (or `.failed` in the catch) only while the token is current. A superseded call returns without writing anything.
- `BookingSummaryViewModel.forceLoad(bookingId:)` takes the token first and checks it after the detail fetch (success and catch), after the review-context fetch (success and catch) and before the final `.loaded`; a superseded call returns at the first failed check.
- `MyBookingsViewModel.forceLoad()` and `silentReload()` each take a token before their first `await` and assign the two lists (and, for the forced load, the load state) only while the token is current. `silentReload()` runs `forceLoad()` instead when `state` is `.loading`, so a `booking.update` that arrives during a pull-to-refresh supersedes that load and the newest call settles the spinner. Otherwise it keeps its silent failure (best-effort read).
- The subscriber closures, `load()` and `reload()` are unchanged in all three files, and none reads `event.status`, so every `booking.update` still triggers a refetch whatever its status.

## Fetch paths gated by ReloadGeneration

| View model | Fetch path | Token taken | `isCurrent` checks |
|------------|-----------|-------------|--------------------|
| `UpcomingBookingViewModel` (client Upcoming Booking details) | `forceLoad()` (behind `load()`, `reload()`, pull-to-refresh and the `booking.update` subscriber) | before `state = .loading` | after the detail await; in the catch |
| `BookingSummaryViewModel` (client Booking Summary) | `forceLoad(bookingId:)` (behind `load()`, `reload()` and the `booking.update` subscriber) | before `loadState = .loading` | after the detail await (success and catch); after the review-context await (success and catch); before the final `.loaded` |
| `MyBookingsViewModel` (client My Bookings) | `forceLoad()` (behind `load()` when not yet loaded, `reload()` and pull-to-refresh) | before `state = .loading` | after the two list awaits; in the catch |
| `MyBookingsViewModel` | `silentReload()` (behind `load()` when already loaded and the `booking.update` subscriber) | after the `.loading` fallback check, before the first await | after the two list awaits (the catch stays silent) |

Together with plan 02-03 (expert `UpcomingBookingsViewModel`), all four `booking.update` subscribers in the app now refetch through a gated path.

## Task Commits

1. **Task 1: Tracer, overlapping refetches on Upcoming Booking details and Booking Summary keep the newest response** - `76533ee` (fix) — previous executor
2. **Task 2: My Bookings keeps the newest refetch and never strands its spinner** - `ff4f399` (fix)

**Plan metadata:** committed separately (docs: complete plan)

## Files Created/Modified

- `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift` - `private var reloads = ReloadGeneration()`; token and two guards in `forceLoad()`; doc comment
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift` - `reloads` property; token and five guards in `forceLoad(bookingId:)`; doc comment
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift` - `reloads` property; token and guards in `forceLoad()` and `silentReload()`; `silentReload()` falls back to `forceLoad()` while loading; both doc comments rewritten (the old "can't race the initial forceLoad" wording is gone)

## Decisions Made

- Same mechanism as plan 02-03: a generation counter, not task cancellation. A superseded fetch finishes its network call and writes nothing, so a genuine failure of the newest fetch still shows `.failed` and a superseded one never touches the load state.
- `silentReload()` defers to `forceLoad()` while a forced load is in flight. The alternative (skip the silent reload) would drop the `booking.update` that arrived during the pull-to-refresh; the alternative of running it silently alongside would let whichever finished last win the lists while the forced load alone settled the spinner.
- No new test file (per the plan's assumption): the gate is unit tested in `ReloadGenerationTests`, the view models fetch through `ClickMeAPI.shared` with no fake seam, and the wiring is covered by grep gates plus the device step.

## Android parity

Android reaches latest-wins on these screens by cancelling the previous coroutine job when a new refetch starts; iOS uses the `ReloadGeneration` counter and lets the superseded call finish and write nothing. The user-visible outcome is the same (the screen ends on the newest response and the load state is settled by it), so **no Android change is needed**. No plan-vs-Android conflict: the plan's behavior matches Android's; only the mechanism differs, and that choice was made in plan 02-03 for the whole app.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The warning baseline for the three files (`/tmp/02-13-warn-before.txt`) was empty before the work and is empty after. The build log's only warning line is the unrelated `appintentsmetadataprocessor` note (same as plan 02-03).
- The tracer gate after Task 1 was answered "approve and defer": the device check was not run (recorded below and in WINDOWS #18).

## Verification

- Task 2 tests: `xcodebuild test` for `ReloadGenerationTests` and `BookingStatusDecodingTests` on iPhone 17: `Test run with 14 tests in 2 suites passed`, `** TEST SUCCEEDED **` (`/tmp/02-13-t2.log`). Task 1's run (`/tmp/02-13-t1.log`) also ended `** TEST SUCCEEDED **`.
- Grep gates: `ReloadGeneration()` present in all three files; `isCurrent(` counts: UpcomingBookingViewModel 2, BookingSummaryViewModel 5, MyBookingsViewModel 3 (baseline 0 each).
- No-regression guard: `event.status` count is 0 in all three view models.
- BUILD: `xcodebuild build` (Debug, iPhone 17) `** BUILD SUCCEEDED **` (`/tmp/02-13-build.log`); `comm -13` against the empty baseline prints nothing.
- Commits in the plan range measured from the ledger: `git rev-list --count 5b0f15a..HEAD` = 2.

## Device checks: PENDING (not run)

**BOOK-18 client device check — PENDING, deferred by the user ("approve and defer") at the Task 1 tracer gate. Not passed. Recorded as WINDOWS #18 (unrun-verify) for 02-12 to collect into `02-DEVICE-UAT-CHECKLIST.md`.**

1. With Upcoming Booking details open on the client, pull to refresh at the same moment the expert proposes a reschedule from another device. Expected: the screen ends on the rescheduled state, and no spinner is left running.
2. With My Bookings open on the client, have the expert cancel or reschedule from the other device while you pull to refresh. Expected: the row ends in its new state and the list is not left on a spinner.

## Known Stubs

None.

## Threat Flags

None. T-02-32 is mitigated as planned (every fetch path on the three screens takes a token before its first await and writes only while current). No new network, auth or file surface; T-02-SC-13 holds (no packages installed).

## User Setup Required

None - no external service configuration required.

## Cross-repo notes

No backend change and no API change. No Android change (see Android parity above).

## Next Phase Readiness

- All four `booking.update` subscribers (plan 02-03 and this plan) now refetch through a `ReloadGeneration` gate; BOOK-18's code work is complete, pending the device checks in 02-12.
- Phase 2 device UAT (02-12) must include WINDOWS #18 (this plan) alongside #13, #15, #16 and #17.

## Self-Check: PASSED

- FOUND: ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
- FOUND: ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
- FOUND: ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsViewModel.swift
- FOUND commit: 76533ee (ancestor of HEAD)
- FOUND commit: ff4f399 (HEAD)
- commits: 2 measured from ledger 5b0f15a..ff4f399

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*
