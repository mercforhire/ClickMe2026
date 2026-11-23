---
phase: quick-261122-r2o
plan: 01
subsystem: client-booking-summary
tags: [ios, swiftui, chat, booking-summary, bugfix]
requires: []
provides:
  - "Session Summary Message Expert opens the chat with the booking's expert"
affects:
  - "ClickMe2026/Views/Screens/Client Mode/Booking Summary/"
key-files:
  modified:
    - "ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift"
    - "ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift"
    - "ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryActions.swift"
    - "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift"
    - ".planning/phases/08-release/08-REGRESSION-CHECKLIST.md"
decisions:
  - "The screen opens the chat itself through the shell's openChatThread action, so no call site changes and all three entry points work"
status: complete
commits: 2
plan_head_before: 872419911d6fa0737438355ea41323e919771425
plan_head_after: 169a0a4a462d7aabe8aff8b745b9f62508230ccb
actuals:
  tokens: 14000
  tasks: 2
  commits: 2
---

# Phase quick-261122-r2o Plan 01: Session Summary Message Expert Summary

Message Expert on the client Session Summary now calls `POST /chats/initiate` for the booking's expert and opens the returned thread on the shell's Chats tab, with a "Couldn't start chat" alert on failure and a spinner plus disabled button while the request runs.

## What changed

- `BookingSummaryViewModel`: new `startChat() async -> UUID?`, `isStartingChat` and `apiError`. A 404 or `NOT_FOUND` reads `ExpertProfileBlockViewModel.unavailableMessage`, any other failure reads `Error.userMessage`, a cancellation shows nothing, and a second call while one runs returns nil without a second POST. No `try?`.
- `BookingSummaryView`: dead `onMessageExpert` parameter removed from both inits. The view reads `@Environment(\.openChatThread)` itself via `messageExpertTapped()` and hosts the alert. Callers, previews and `#Preview` blocks are unchanged.
- `BookingSummaryActions`: `isMessageBusy` spinner and disabled state.
- Six new tests in `BookingSummaryViewModelTests` (22 total in the suite).
- `08-REGRESSION-CHECKLIST.md` R7: step 7 and one Expected bullet for the device check. Still 28 `Result:` lines, 1 in R7.

## Results

- `/tmp/261122-r2o-t1.log`: `Test run with 22 tests in 1 suite passed`.
- `/tmp/261122-r2o-full.log`: `Test run with 1278 tests in 118 suites passed` (LoginTests, AuthSmokeTests and SignupSmokeTests excluded).
- `/tmp/261122-r2o-build.log`: BUILD SUCCEEDED after touching the three app files, with no warning naming a touched file in any log.
- R7 step 7 is pending the device run (08-21, TestFlight build 1.1 (7)). Not run by Claude.

## Commits

- `a603a2a` fix(quick-261122-r2o): the four code and test files
- `169a0a4` docs(quick-261122-r2o): the checklist only

Nothing pushed. `Localizable.xcstrings`, `.DS_Store` files, `.planning/config.json`, `.planning/milestone.lock` and `.planning/state.json` were left uncommitted.

## Deviations from Plan

**1. [Rule 3 - Blocking] Test helper isolation.** The first test build failed because the new static `threadId` and `initiateSuccess` helpers were main-actor isolated but read from a `@Sendable` mock handler. Marked both `nonisolated`, as the existing `reviewContextJSON` is. Fixed in the same task before the commit.

**2. Flaky unrelated test in the first full run.** The first full run failed one test in an untouched suite (`MakeABookingAvailabilityTests`, "An older load that lands last writes nothing", `Zone/1` vs `Zone/2`). Rerunning that suite alone passed (10 tests), and a second full run passed with 1278 tests. The first failing log is kept at `/tmp/261122-r2o-full-run1.log`. The test looks timing-sensitive under parallel load. Not touched, not part of this plan. Worth a look if it recurs.

**3. Commit trailer.** The Co-Authored-By trailer uses `Claude Sonnet 5.5`, as the current attribution instruction says, instead of the `Claude Opus 5.5` text in the plan.

## Known Stubs

None.

## Threat Flags

None. No new endpoint or trust boundary beyond the planned `POST /chats/initiate` call.

## Self-Check: PASSED

- Commits `a603a2a` and `169a0a4` are on HEAD.
- The four code and test files and the checklist have no uncommitted changes.
