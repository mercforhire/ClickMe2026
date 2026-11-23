---
phase: quick-261122-tcf
plan: 01
subsystem: client-booking, expert-chat
tags: [swiftui, reschedule, chat, review-follow-up]
requires: []
provides:
  - "Reschedule decline applies the server's restored status (T-03-23)"
  - "ChatStarter single-flight chat start with error alert for the three expert Message buttons (WR-10)"
affects:
  - ClickMe2026/Views/Screens/Client Mode
  - ClickMe2026/Views/Screens/Expert Mode
key-files:
  created:
    - ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift
    - ClickMe2026/Views/Screens/Chat/ChatStarter.swift
    - ClickMe2026Tests/Chat/ChatStarterTests.swift
  modified:
    - ClickMe2026/Network/ClickMeAPI+Booking.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift
    - ClickMe2026Tests/Support/ClientBookingFixtures.swift
    - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
    - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
    - .planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md
    - .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md
decisions:
  - "Expert reschedule buttons keep the labels Decline and Accept; only the height changed to a 44 pt minimum"
  - "RescheduleResponseData keeps only status (no booking_id) so a malformed id can never fail the decode"
metrics:
  tasks: 3
  tests_added: "RescheduleResponder +3 rows (36 total), Upcoming +3 rows net (29), BookingSummary +2 (24), ChatStarter 6 new"
actuals:
  tokens: 60000
  tasks: 3
  commits: 3
plan_head_before: 311f9a45d6dfa05acf68f1315c064d3222085011
plan_head_after: 0f98b25e857939434f5f173afade6c5a382375b7
commits: 3
status: complete
---

# Phase quick-261122-tcf Plan 01: Phase 3 review follow-ups Summary

Declining an expert's reschedule now shows the status the server restored, and the three expert Message buttons report failures and send one request per tap burst.

## Commits (iOS repo, all local, nothing pushed)

| Task | Commit | Message |
|------|--------|---------|
| 1 | 208ee4f | fix(quick-261122-tcf): use the server's restored status after a reschedule decline (T-03-23) (9 files) |
| 2 | cec4477 | fix(quick-261122-tcf): expert Message buttons show errors and ignore a second tap; 44 pt reschedule buttons (WR-10) (5 files) |
| 3 | 0f98b25 | docs(quick-261122-tcf): mark IN-02 and WR-10 fixed; add device checks 25-26 (2 files) |

No Android commit. No backend commit.

## What changed

- **T-03-23.** `declineClientReschedule` now returns `RescheduleDeclineResponse`, which decodes `data.status` best-effort (missing, null, non-object, non-string or blank all give `restoredStatus == nil`). `RescheduleResponder.Resolution.declined(restoredStatus:)` carries it. Upcoming details sets `bookingStatus`/`statusRaw` from it (unknown string becomes `.unknown`, raw kept) and resets `canJoin`; with no status it leaves status and `canJoin` alone. Booking Summary applies it through `mapStatus`. In both, the card clears, the toast shows, the refetch runs and `apiError` stays nil. Accept paths unchanged.
- **WR-10.** New `ChatStarter` (`@MainActor @Observable`) ports `BookingSummaryViewModel.startChat()`: single flight, 404 or NOT_FOUND gives `ExpertProfileBlockViewModel.unavailableMessage`, other failures give `Error.userMessage`, cancellation is silent. The expert Booking Summary, Upcoming Bookings list and Request Decision use it with a "Couldn't start chat" alert. Message Client shows a spinner and is disabled while running. No new strings.
- **44 pt.** Expert reschedule Decline and Accept use `.frame(maxWidth: .infinity, minHeight: 44)`. Labels stay "Decline" and "Accept": the UI-SPEC "Accept New Time / Decline New Time" copy is for the client response card, Android labels this pair "Accept", and renaming would add catalog strings while `Localizable.xcstrings` has unrelated uncommitted changes.

## Verification

- Task 1 run (`/tmp/261122-tcf-t1.log`): 89 tests in 3 suites passed (RescheduleResponderTests 36 `@Test`, UpcomingBookingViewModelTests 29, BookingSummaryViewModelTests 24).
- Task 2 run (`/tmp/261122-tcf-t2.log`): ChatStarterTests, 6 tests in 1 suite passed.
- Full unit run (`/tmp/261122-tcf-full.log`, LoginTests, AuthSmokeTests and SignupSmokeTests excluded): 1292 tests in 119 suites passed, TEST SUCCEEDED.
- Debug simulator build (`/tmp/261122-tcf-build.log`) after touching all nine source files: BUILD SUCCEEDED. No warning in any touched file. The only `warning:` line in the build log is the pre-existing "Metadata extraction skipped. No AppIntents.framework dependency found."
- Commit shape: two `fix(quick-261122-tcf)` commits with 14 files in total, one docs commit with 2 files. No `.planning/config.json`, `Localizable.xcstrings`, `state.json`, `milestone.lock`, `.DS_Store`, STATE.md, ROADMAP.md or Phase 08 file was staged. Those unrelated files are still dirty and unstaged.

## Android parity (re-verified at execution, no change)

Android HEAD e311a74c, `app/src` clean (`git status --short -- app/src` empty). All planning-time greps passed:
- Expert Message controls call `chatEntry.open(ChatPeer(...))` in `ExpertBookingSummaryScreen.kt`, `ExpertBookingsScreen.kt` and `RequestDecisionScreen.kt`. `ChatLauncher.kt` has the `AlreadyOpening` single-flight and maps `status == STATUS_NOT_FOUND` to the unavailable copy.
- Client decline: `RescheduleResponse.kt` routes `DeclineOutcome.Declined -> succeed(RescheduleNotice.Declined)` and `succeed` calls `reload()`. Neither `clientmode/upcomingbooking/UpcomingBookingViewModel.kt` nor `clientmode/bookingsummary/BookingSummaryViewModel.kt` writes a confirmed status.

Android needs no change and the Android repo got no commit.

## Backend

No change needed. The decline 200 already returns `data.status` (`clientBooking.controller.js` `declineReschedule`, `openapi/clickme-api.yaml`). The backend freeze and the live App Store build are unaffected.

## Deviations from Plan

**1. [Process] Task 1 and Task 2 TDD order.** The new tests and the implementation were written in the same pass, and the RED state was not run separately before implementing. Tests were run after implementation and pass. The changes are covered by the behaviors listed in the plan (including the null, non-string and blank status rows).

Otherwise the plan was executed as written.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust-boundary surface beyond the plan's threat model.

## Open items

- `03-SECURITY.md` still marks T-03-23 as open until the next `/gsd-secure-phase 3` re-audit.
- Device checklist items 25 (T-03-23) and 26 (WR-10 and the 44 pt buttons) in `03-DEVICE-UAT-CHECKLIST.md` await a run on a real iPhone.

## Self-Check: PASSED

- FOUND: ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift
- FOUND: ClickMe2026/Views/Screens/Chat/ChatStarter.swift
- FOUND: ClickMe2026Tests/Chat/ChatStarterTests.swift
- FOUND commits: 208ee4f, cec4477, 0f98b25 (all ancestors of HEAD)
