---
phase: 06-expert-mode
plan: 15
subsystem: expert-mode-android-parity
tags: [android, compose, calendar, gap-closure, robolectric]

requires:
  - phase: 06-expert-mode
    provides: Android Booking Confirmed Add to Calendar (06-09), iOS summary calendar plans 06-14 and 06-18 (rules and copy)
provides:
  - "Android calendarEventSpec on plain values, isCalendarEventOffered, rememberCalendarInsertLauncher"
  - "Add to Calendar on the Android expert Booking Summary and client Upcoming Booking"
affects: [06-16]

actuals:
  tokens: 7600
  tasks: 2
  commits: 1
plan_head_before: da4986206f01875dc718dd313cb6642b7bae1f48
plan_head_after: 69c4e159ba62240af7e791b5a0a2558f01f95416

tech-stack:
  added: []
  patterns:
    - "One shared Compose launcher owns the double-tap guard and the no-handler fallback for every Add to Calendar button"

key-files:
  created: []
  modified:
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/CalendarIntent.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/BookingConfirmedScreen.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/bookingsummary/ExpertBookingSummaryScreen.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/upcomingbooking/UpcomingBookingScreen.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/main/res/values/strings_upcoming_booking.xml
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/CalendarIntentTest.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/bookingsummary/ExpertBookingSummaryScreenTest.kt
    - /Users/LeonChen/Documents/ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/clientmode/upcomingbooking/UpcomingBookingScreenTest.kt

key-decisions:
  - "The expert summary reuses the Booking Confirmed strings so both expert events are identical; the client gets upcoming_booking_calendar_title and an Expert fallback"
  - "The client button sits directly after the notes card and before Message Expert, per the plan wording; the expert button sits after Message Client"
  - "Android join clock ticks every 30 s (iOS 60 s); both hide the button within a minute of the end, accepted"

requirements-completed: [EXP-10]

coverage:
  - id: D1
    description: "isCalendarEventOffered: true for confirmed, in_progress, pending_reschedule before the end; false for every other status and at or after the end"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "app/src/test/.../expertmode/confirmed/CalendarIntentTest.kt#offeredForBookedStatusesBeforeTheEnd, notOfferedForOtherStatuses, notOfferedAtOrAfterTheEnd"
        status: pass
    human_judgment: false
  - id: D2
    description: "calendarEventSpec on plain values keeps the title, times and description rule (meeting type, then trimmed message when not blank); intent shape and no-handler rows unchanged"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "app/src/test/.../expertmode/confirmed/CalendarIntentTest.kt#specCarriesTitleTimesAndDescription, blankMessageIsOmitted, intentHasActionDataAndExtrasOnly, noHandlerCallsCallbackWithoutCrashing"
        status: pass
    human_judgment: false
  - id: D3
    description: "Expert Booking Summary shows Add to Calendar for a confirmed future booking, not for completed or ended ones"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "app/src/test/.../bookingsummary/ExpertBookingSummaryScreenTest.kt#addToCalendarShowsForBookedSessionNotYetEnded, addToCalendarIsHiddenForACompletedBooking, addToCalendarIsHiddenOnceTheSessionHasEnded"
        status: pass
    human_judgment: false
  - id: D4
    description: "Client Upcoming Booking shows Add to Calendar for a confirmed future booking, not for pending_approval or ended ones"
    requirement: EXP-10
    verification:
      - kind: unit
        ref: "app/src/test/.../upcomingbooking/UpcomingBookingScreenTest.kt#addToCalendarShowsForABookedSessionNotYetEnded, addToCalendarIsHiddenForAPendingRequest, addToCalendarIsHiddenOnceTheSessionHasEnded"
        status: pass
    human_judgment: false
  - id: D5
    description: "Booking Confirmed behaves as before on the shared launcher"
    verification:
      - kind: unit
        ref: "app/src/test/.../expertmode/confirmed/BookingConfirmedScreenTest.kt (existing rows)"
        status: pass
    human_judgment: false
  - id: D6
    description: "On an Android device or emulator the calendar app opens pre-filled from both screens and a past or pending booking shows no button"
    verification: []
    human_judgment: true
    rationale: "The calendar app hand-off needs a running Android app; covered by checklist re-check R7 written by plan 06-16"

duration: 25min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 15: Android Add to Calendar on summary screens Summary

**Android's expert Booking Summary and client Upcoming Booking now offer Add to Calendar for booked, not-yet-ended sessions through a plain-values `calendarEventSpec`, an `isCalendarEventOffered` rule and one shared `rememberCalendarInsertLauncher`, mirroring iOS plans 06-14 and 06-18, delivered as one Android commit.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-17
- **Tasks:** 2
- **Files modified:** 8 (all in ClickMe_Android; none in this repo besides this SUMMARY)

## Accomplishments
- `calendarEventSpec(title, beginMillis, endMillis, meetingTypeLabel, message)` replaces the Booking Confirmed nav-key builder; the description rule is unchanged.
- `isCalendarEventOffered(statusCode, end, now)`: `JOINABLE_BOOKING_STATUSES` and `now` strictly before `end` (iOS `BookingCalendarEventContent.isOffered` parity).
- `rememberCalendarInsertLauncher(onNoHandler)` owns the launching flag, resets it in `LifecycleResumeEffect` and on no handler; Booking Confirmed dropped its own copy of that logic.
- Expert Booking Summary: full-width outlined button after Message Client, event `ClickMe · {topic} with {client}` identical to Booking Confirmed.
- Client Upcoming Booking: button after the notes card, event `ClickMe · {topic} with {expert}` (fallbacks `Session` and `Expert`), two new strings.
- Tests: spec rows moved to the new builder, an offer-rule table, and three visibility rows on each screen.

## Task Commits

Both tasks land as one commit in `/Users/LeonChen/Documents/ClickMe_Android` (plan requirement; Task 1 left its five files uncommitted for Task 2):

1. **Task 1 (tracer) and Task 2** - `69c4e159` (feat) on Android base `da4986206f01875dc718dd313cb6642b7bae1f48`

No iOS app, test, or backend change. The iOS repo gets only this SUMMARY.

## Decisions Made
- Placement on the client screen follows the plan text (directly after the notes card, before Message Expert). The interfaces note says "below the notes"; if the device check prefers it below Message Expert it is a one-line move.
- `OutlinedButton` reuses `CancelMinHeight` and `CancelIconSize` already in each screen, so the button matches the Cancel button height.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The first `ExpertBookingSummaryContent` test helper gained a `joinNow` parameter (default unchanged) to cover the ended-session row.

## Verification
- `./gradlew :app:testDevDebugUnitTest` on `CalendarIntentTest`, `BookingConfirmedScreenTest`, `ExpertBookingSummaryScreenTest`, `UpcomingBookingScreenTest` plus `ktlintCheck`: BUILD SUCCESSFUL, 0 failures, 0 skipped (Task 1 run 1m 5s, Task 2 run 45s).
- Task 1 and Task 2 grep gates passed; exactly one Android commit since the recorded base with eight files; nothing under `app/` left uncommitted; no `.idea` or `.planning` file in the commit.
- Not run: xcodebuild (plan forbids it), Android device or emulator check (R7, plan 06-16).

## Next Phase Readiness
Ready for 06-16 (checklist re-check R7 covers the Android device check). No blockers.

## Known Stubs

None.

## Threat Flags

None. The intent builder is unchanged (T-06-24); the shared launcher keeps the double-tap guard on all three screens (T-06-25).

## Self-Check: PASSED
- Android commit `69c4e159` is on `main` in ClickMe_Android and is one commit past the recorded base.
- All eight Android files exist and are in that commit.
