---
phase: 03-booked-sessions-and-joining
plan: 16
subsystem: ui
tags: [swiftui, reschedule, booking, observation, swift-testing, gap-closure]
gap_closure: true
gap_ids: [G-03-3-WR01]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: RescheduleResponder shared by Upcoming details and Booking Summary (03-06, 03-13)
provides:
  - RescheduleResponder.onResolved hook, called after every 2xx accept or decline and before refetch
  - Upcoming details and Booking Summary clear the reschedule proposal locally on onResolved
  - Call-order rows and failed-refetch rows on both screens
  - WR-01 recorded as fixed in the review ledger
affects: [03-UAT item 1 (BOOK-06) device check, phase 03 verification, Android RescheduleResponseController]

actuals:
  tokens: 5000
  tasks: 2
  commits: 2
plan_head_before: 657356960eba56e55e657e559b5b1eda66c429fa
plan_head_after: c8a4504ea462c60d54cfc55283421acb864e9b52

tech-stack:
  added: []
  patterns:
    - "Synchronous owner hook (onResolved) ahead of an async refetch, so a local clear cannot interleave with the refetch's ReloadGeneration.begin()"

key-files:
  created:
    - .planning/phases/03-booked-sessions-and-joining/03-16-SUMMARY.md
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
    - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
    - .planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md
    - .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md

key-decisions:
  - "onResolved is synchronous ((@MainActor () -> Void)?), so nothing can interleave between the clear and the refetch"
  - "Only the proposal is cleared locally; status, times and the pill keep their last value until the next successful fetch (D-03 existing rule)"

requirements-completed: [BOOK-06]

coverage:
  - id: D1
    description: "RescheduleResponder calls onResolved after every 2xx accept (first try and saved-card retry) and decline, before refetch, and never after a failure"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleResponderTests.swift#acceptResolvesBeforeRefetch, retryAcceptResolvesOnce, declineResolvesBeforeRefetch, failedAcceptDoesNotResolve, unrecoveredPaymentMethodDoesNotResolve, failedDeclineDoesNotResolve"
        status: pass
    human_judgment: false
  - id: D2
    description: "Upcoming details drops the Accept/Decline card after a 2xx accept or decline even when the follow-up detail GET returns 500"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#acceptWithFailedRefetchClearsProposal, declineWithFailedRefetchClearsProposal"
        status: pass
    human_judgment: false
  - id: D3
    description: "Booking Summary drops the Accept/Decline card the same way"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#acceptWithFailedRefetchClearsCard, declineWithFailedRefetchClearsCard"
        status: pass
    human_judgment: false
  - id: D4
    description: "Normal-path behavior on a phone: card goes with the toast and times update in place"
    requirement: BOOK-06
    verification: []
    human_judgment: true
    rationale: "Phase 3 UAT item 1 device check is still pending; a phone cannot fail only the follow-up request on demand, so the failed-refetch edge rests on the unit rows"

duration: 7min
completed: 2026-11-11
status: complete
---

# Phase 3 Plan 16: Reschedule card cleared on a 2xx even when the refetch fails Summary

**`RescheduleResponder.onResolved` clears the proposal on both client screens as soon as the server accepts or declines, so a failed follow-up GET can no longer leave an Accept card that sends a second money-affecting POST (WR-01, gap G-03-3-WR01).**

## Performance

- **Duration:** 7 min (2026-11-11T20:36:49Z to 2026-11-11T20:43:42Z)
- **Tasks:** 2 of 2
- **Files modified:** 8 (3 app, 3 test, 2 planning docs)

## Accomplishments

- `RescheduleResponder` gained `onResolved`, called after the toast and before `await refetch?()` on the first-try accept, the saved-card retry accept and the decline. Every failure path is unchanged and never calls it.
- `UpcomingBookingViewModel` and `BookingSummaryViewModel` set `reschedule = nil` from `onResolved` in the runtime init. The preview init on Booking Summary is untouched (its responder has no booking id). `refresh()`, `pendingProposal` and `apply` are unchanged, so a successful refetch still writes the server's state, including any proposal it still returns.
- Tests: six call-order rows in `RescheduleResponderTests`, two failed-refetch rows each in `UpcomingBookingViewModelTests` and `BookingSummaryViewModelTests`. Each failed-refetch row asserts one POST, two detail GETs, proposal nil, state `.loaded`, `apiError` nil.
- `03-REVIEW-DISPOSITION.md`: WR-01 fixed by 03-16, open count 12 to 11. `03-DEVICE-UAT-CHECKLIST.md` item 1 gained the WR-01 note (Status and Result untouched).

## Task Commits

1. **Task 1 (tracer): responder hook and Upcoming details** - `788be8c`
2. **Task 2: Booking Summary and ledger** - `c8a4504`

## Verification

- `RescheduleResponderTests` 33 tests passed, `UpcomingBookingViewModelTests` 18 passed, `BookingSummaryViewModelTests` 16 passed.
- Tracer gate (auto mode): the Task 1 `<verify>` suites and grep gate were run after the commit's changes and passed, so expansion proceeded.
- Full unit suite: 438 tests in 48 suites passed (the plan expected more than 434).
- Build: `BUILD SUCCEEDED`. Warning baseline for the three app files was 0 before and the `comm` comparison printed nothing after, so no new warnings.
- Both task grep gates exit 0.

## Deviations from Plan

None - plan executed exactly as written. The `acceptance_criteria` for the `git show` check on the Task 2 commit hold: the ledger diff touches only the WR-01 entry, the WR-01 row and the `open:` count.

## Known Stubs

None.

## Threat Flags

None. T-03-28 is mitigated by the new rows; T-03-29 accepted as planned.

## Pending device check

Phase 3 UAT item 1 (BOOK-06) stays pending: accept and decline on Upcoming details and on Booking Summary on a real iPhone. On the normal path the card goes when the toast shows and the times update in place. The failed-refetch edge cannot be forced on a phone and rests on the unit rows.

## Android follow-up (logged, not built)

Android's `RescheduleResponseController` has the same WR-01 behavior. `RescheduleResponseController.succeed()` (ClickMe_Android `screens/clientmode/mybookings/RescheduleResponse.kt`) awaits the quiet reload, then sets the notice. A failed quiet reload (`UpcomingBookingViewModel.startLoad(quiet = true)`) keeps the old `Loaded` details, so the card and proposal stay and become tappable again when `submitting` resets. Android follow-up (logged, not built): after a 2xx accept or decline, clear the proposal from the loaded state whether or not the quiet reload succeeds. No backend change.

## Self-Check: PASSED

- All eight modified files exist; commits `788be8c` and `c8a4504` are ancestors of HEAD.
- `git rev-list --count 657356960eba..HEAD` is 2 before this SUMMARY commit, matching `commits: 2`.
