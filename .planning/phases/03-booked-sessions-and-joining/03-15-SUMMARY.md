---
phase: 03-booked-sessions-and-joining
plan: 15
subsystem: ui
tags: [android, jetpack-compose, booking-summary, booking-id, ios-parity]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: "Plan 03-07 iOS Booking Summary ID line and the BOOK-20 format (UI-SPEC D1); Android shortBookingId already existed"
provides:
  - "Android client Booking Summary card shows 'ID: #XXXXXXXX' as the last line of the topic/date/price column"
  - "Two Android screen-test rows pinning the short and full-UUID forms"
affects: [03-UAT, android-parity]

actuals:
  tokens: 600
  tasks: 1
  commits: 1
plan_head_before: 886d6fdfc81efa351215796f97885b1ca58ee497
plan_head_after: 0f2e8cd76541473a6d64f3d6ddef49034b87e5d3

tech-stack:
  added: []
  patterns:
    - "Reuse the existing upcoming_booking_id string and shortBookingId rule so the ID reads the same on every Android screen"

key-files:
  created: []
  modified:
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/bookingsummary/subviews/BookingSummaryCard.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/clientmode/bookingsummary/BookingSummaryScreenTest.kt

key-decisions:
  - "No new string resource: reused R.string.upcoming_booking_id and shortBookingId, so Android Summary, Upcoming details and Payments cannot drift apart"
  - "Added a bookingId parameter (default 'b1') to the test helper details() rather than a second helper"

requirements-completed: [BOOK-20]

coverage:
  - id: D1
    description: "Android client Booking Summary shows the booking ID as 'ID: #B1' for bookingId 'b1' (last line of the topic/date/price column)"
    requirement: "BOOK-20"
    verification:
      - kind: unit
        ref: "BookingSummaryScreenTest#bookingIdShowsInTheShortFormat"
        status: pass
    human_judgment: false
  - id: D2
    description: "A full-UUID booking id renders 'ID: #7F3C9A2B' on Android, the same short ID iOS BookingShortIDTests pins"
    requirement: "BOOK-20"
    verification:
      - kind: unit
        ref: "BookingSummaryScreenTest#fullUuidBookingIdMatchesIos"
        status: pass
    human_judgment: false
  - id: D3
    description: "The ID line sits under the price on a real Android device and matches iOS for the same booking"
    requirement: "BOOK-20"
    verification: []
    human_judgment: true
    rationale: "Layout position and visual match with iOS need a device; deferred to Phase 3 UAT by the user's standing approval of 2026-11-10"

duration: 6min
completed: 2026-11-10
status: complete
---

# Phase 3 Plan 15: Android Booking Summary ID Line Summary

**Android client Booking Summary now shows the short booking ID ("ID: #7F3C9A2B") under the price, reusing the existing `upcoming_booking_id` string and `shortBookingId` rule so it matches the iOS Booking Summary from plan 03-07.**

## Performance

- **Duration:** about 6 min
- **Completed:** 2026-11-10 (finished 2026-11-11T04:31Z UTC)
- **Tasks:** 1 (tracer)
- **Files modified:** 2, both in the Android repo

## Accomplishments

- `BookingSummaryCard` renders a `Text` after the price `Row`: `stringResource(R.string.upcoming_booking_id, shortBookingId(details.bookingId))`, `bodySmall`, `extras.onSurfaceMuted`. No new string resource.
- `BookingSummaryScreenTest` gained `bookingIdShowsInTheShortFormat` ("ID: #B1") and `fullUuidBookingIdMatchesIos` ("ID: #7F3C9A2B" for `7f3c9a2b-1d4e-4c8a-9b0f-123456789abc`), written first and run red (both failed, the other 32 tests passed), then green after the card change.
- Gradle verify passed: `BookingSummaryScreenTest` and `UpcomingBookingViewModelTest` unit tests plus `ktlintCheck`, BUILD SUCCESSFUL.

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| Android (`ClickMe_Android`) | `0f2e8cd76541473a6d64f3d6ddef49034b87e5d3` | feat(booking-summary): show the booking ID like Upcoming details (iOS BOOK-20 parity) |

The commit lists exactly the two files above (+23/-3). The Android repo's unrelated dirty files (`.idea/*`, `.planning/*`) were not staged; `git status --short` is identical before and after. The iOS repo has no source change from this plan. `commits: 1` is the Android-repo count measured from `plan_head_before` to `plan_head_after` in that repo; the iOS repo gets only the docs commit for this SUMMARY.

## Task Commits

1. **Task 1: Tracer, Android Booking Summary booking ID line** - `0f2e8cd` in ClickMe_Android (feat)

## Deviations from Plan

None - plan executed exactly as written.

## Tracer gate

The tracer's `<verify>` carries an automated Gradle check and a device `<human-check>`. Under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT"), the device check is deferred and execution continued. The automated verify was re-run end to end after the commit (commit file list, `upcoming_booking_id` present in the card, commit subject contains BOOK-20) and passed. There were no expansion tasks (the plan has one task).

## Deferred device checks (Phase 3 UAT)

- **BOOK-20 Android:** on a real Android device, open a client Booking Summary and confirm "ID: #…" appears under the price, and that it matches the ID iOS shows for the same booking.

## Pending device checks

- Same item as above (BOOK-20 Android), listed here as the plan's output spec requires.

## Requirement status

BOOK-20 is declared by plans 03-07, 03-14 and 03-15. This plan delivers the Android half only, so BOOK-20 is not marked complete in REQUIREMENTS.md here; it stays open for 03-07 and 03-14 (the shared-ID gate lets the last declaring plan flip it).

## Known Stubs

None.

## Threat Flags

None. The short ID already appears on Android Upcoming details and Payments and grants no access (the server checks ownership). T-03-24 mitigation held: two named files staged, commit file list verified.

## Issues Encountered

None. The first attempt at a compound shell check was rejected by the harness (bash 3.2); it was re-run as simpler commands with the same results.

## Self-Check: PASSED

- FOUND: BookingSummaryCard.kt (contains `upcoming_booking_id`, count 1)
- FOUND: BookingSummaryScreenTest.kt (`bookingIdShowsInTheShortFormat` count 1)
- FOUND: commit 0f2e8cd in ClickMe_Android, two files only
- Android `.idea` / `.planning` status unchanged
