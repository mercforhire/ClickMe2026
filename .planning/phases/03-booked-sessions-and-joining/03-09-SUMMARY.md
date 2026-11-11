---
phase: 03-booked-sessions-and-joining
plan: 09
subsystem: ui
tags: [swiftui, join-window, callcenter, skype-zoom, cancel-policy, swift-testing]
status: complete

requires:
  - phase: 02-client-bookings
    provides: JoinWindow (isOpen, showsJoinButton), ExternalMeetingProvider.detect, CallCenter.startCall
  - phase: 03-booked-sessions-and-joining
    provides: "03-01 UpcomingBookingViewModel silent refresh and ClientBookingFixtures; 03-14 status pill and BookingShortID; 03-03 Skype/Zoom session screen"
provides:
  - Upcoming Booking details starts the call itself through CallCenter.startCall for every entry point (no caller wiring)
  - JOIN CALL and Open in {provider} gated by JoinWindow.isOpen with can_join, re-evaluated every 60 s
  - ExternalMeetingProvider.openButtonTitle and an Open in {provider} button on Skype/Zoom bookings that goes through the call path
  - UpcomingActionPolicy.canShowCancel, the one Cancel visibility rule (D-13)
affects: [03-12 cancel and reschedule wiring on push- and Payments-opened details, 03-DEVICE-UAT-CHECKLIST, android-parity]

actuals:
  tokens: 4870   # chars/4 over the added Swift lines of the realized diff (19,483 chars)
  tasks: 3
  commits: 3
plan_head_before: 763cd8e7d8a30ffd314fc70e9a9da37c50ec4919
plan_head_after: be60f6fbf812e0f8cb493cd47386dd3ef9ec4fef

tech-stack:
  added: []
  patterns:
    - "Time-dependent display gates are pure functions of an injected now, driven by a 60 s TimelineView, so tests use a fixed clock"
    - "A screen that must work from every caller owns its default action; the callback becomes an optional override"

key-files:
  created:
    - ClickMe2026/Utils/UpcomingActionPolicy.swift
    - ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingJoinCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift
    - ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
    - ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift

key-decisions:
  - "onJoinCall on UpcomingBookingView is optional and nil means the screen starts the call itself; none of the four callers passes it, so JOIN CALL works from My Bookings, push taps, chat rows, Explore and Payments"
  - "The Skype/Zoom Open button runs the same action as JOIN CALL (CallCenter.startCall), so the session screen tracks time and /end is reported; the card contains no URL opener"
  - "Cancel visibility is statuses {confirmed, pending_approval, pending_reschedule} AND end > now, mirroring the backend cancellableStatuses and BACK-12 (D-13 supersedes the UI-SPEC end-time-only rule)"
  - "previewSeed now defaults startTime to one hour out (was nil) so preview canvases show an open join window; the Reschedule proposed preview still passes its own start"

requirements-completed: [CALL-03, CALL-08, BOOK-13]

coverage:
  - id: D1
    description: "JOIN CALL on Upcoming details is enabled exactly when JoinWindow.isOpen says so (confirmed inside 60 min, closed 2 h out, pending_reschedule shown but disabled, completed reconnect tier needs can_join, pending_approval shows the banner)"
    requirement: CALL-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#joinInputsAreDecoded, confirmedInsideWindow, confirmedBeforeWindow, pendingRescheduleIsDisabled, completedReconnectTier, pendingApprovalHidesJoinCard, joinClosedBeforeLoad"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tapping JOIN CALL starts the call through CallCenter.startCall from every entry point, and a failed join shows the Couldn't join call alert"
    requirement: CALL-03
    verification:
      - kind: other
        ref: "grep gates: no inert onJoinCall default remains; CallCenter.shared.startCall used in the view model"
        status: pass
    human_judgment: true
    rationale: "startCall reaches CallCenter.shared and Agora, so it is not called in unit tests; the join, the alert and the entry points need a device (UAT item CALL-03)"
  - id: D3
    description: "Open button label names the provider, reads Open Meeting for an unrecognized or lookalike host, nil or empty link"
    requirement: CALL-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift#openTitleNamesProvider, openTitleForUnknownHost, openTitleForMissingLink"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Skype/Zoom card never opens the expert URL directly and the Copy button is announced"
    requirement: CALL-08
    verification:
      - kind: other
        ref: "grep gate: UIApplication.shared.open count 0 in UpcomingBookingJoinCard.swift; Copy meeting link label present"
        status: pass
    human_judgment: false
  - id: D5
    description: "Open in {provider} lands on the Skype/Zoom session screen with the timer, the link opens from there and End Session reports /end; Open in Microsoft Teams fits one line on the smallest iPhone"
    requirement: CALL-08
    verification: []
    human_judgment: true
    rationale: "Navigation into the session screen, the external app launch and button text fit need a device (UI-SPEC D3, L3)"
  - id: D6
    description: "Cancel shows only for confirmed, pending_approval and pending_reschedule while end is in the future; hidden at end == now and later, for in_progress, completed and every terminal or unknown status, and when end is unknown"
    requirement: BOOK-13
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift#showsWhileEndIsAhead, hidesAtAndAfterEnd, hidesForOtherStatuses, hidesWithoutEnd, listsAreExhaustive"
        status: pass
    human_judgment: false
  - id: D7
    description: "Reschedule fills the row when Cancel is hidden, and the row re-evaluates every 60 s on a real iPhone"
    requirement: BOOK-13
    verification: []
    human_judgment: true
    rationale: "Layout and the live minute tick need a device (UAT item BOOK-13)"

duration: 25min
completed: 2026-11-11
---

# Phase 3 Plan 09: JOIN CALL, Open in {provider} and Cancel visibility on Upcoming details Summary

**Upcoming Booking details now starts the call itself through `CallCenter.startCall` inside the shared join window (dimmed and disabled with a hint outside it), gives Skype/Zoom bookings an "Open in {provider}" button through the same call path, and hides Cancel once the server would refuse it.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-11
- **Tasks:** 3 of 3 (Task 1 tracer, Tasks 2 and 3 TDD)
- **Files:** 9 (2 created, 7 modified), 457 insertions and 60 deletions in the plan range

## Accomplishments

- **CALL-03:** `UpcomingBookingViewModel` decodes `endTime`, `expertId` and `can_join`, exposes `showsJoinCard`, `joinWindowOpen(at:)` (forwards to `JoinWindow.isOpen`) and `startCall()` (forwards to `CallCenter.shared.startCall`, `isRejoin` for a completed booking). `UpcomingBookingView`'s `onJoinCall` is now an optional override; nil, which every caller uses, starts the call from the screen. The join card sits in a 60 s `TimelineView`, dims to 55% with no glow, is disabled and carries the hint "Available closer to the session start" while the window is closed, and `pending_reschedule` shows it disabled. `pending_approval` keeps the "Waiting for expert to accept" banner. The screen also presents the "Couldn't join call" and microphone-denied alerts copied from My Bookings.
- **CALL-08:** `ExternalMeetingProvider.openButtonTitle` returns "Open in Skype", "Open in Zoom", "Open in Google Meet", "Open in Microsoft Teams" and "Open Meeting" for an unrecognized host (never "Open in Meeting"). The Skype/Zoom card shows a 52 pt, 16 pt-radius accent button with the provider icon above the Meeting Link row, one line scaling to 0.8, with the same enabled/dimmed treatment as JOIN CALL. It runs `onJoinCall`, so it enters the Skype/Zoom session screen from 03-03 and `/join` and `/end` are reported. The Copy button reads "Copy meeting link" or "Link copied". Two previews added (Teams link; Zoom with the window closed).
- **BOOK-13:** `UpcomingActionPolicy.canShowCancel(status:end:now:)` allows `confirmed`, `pending_approval` and `pending_reschedule` while `end > now`, matching the backend `cancellableStatuses` and the BACK-12 409. `UpcomingBookingSecondaryActions(showsCancel:)` hides Cancel and lets Reschedule fill the row, inside a 60 s `TimelineView`. Labels "Cancel" and "Reschedule" are unchanged.

## Task Commits

1. **Task 1: Tracer, JOIN CALL on Upcoming details starts the call inside the join window** - `10ce408` (feat)
2. **Task 2: A Skype/Zoom booking gets Open in {provider} through the call path** - `2b8394d` (feat)
3. **Task 3: Cancel hides once the server would refuse it** - `be60f6f` (fix)

**Plan metadata:** the docs commit that follows this file.

## Decisions Made

- `onJoinCall` stays as an optional override seam rather than being removed, so a caller that wants custom behavior can still pass one.
- `previewSeed` defaults `startTime` to one hour from now so the canvas shows an enabled Join; before this it was nil, which would now read as a closed window.
- The tests for Task 2 and 3 were written first and failed to compile (RED) before the implementation; the plan specifies one commit per task, so each commit holds tests and implementation together.

## Deviations from Plan

None - plan executed exactly as written. The plan listed the join-card previews as "update its previews"; the card had none, so two were added in Task 2 (the Teams preview the plan asks for, plus a closed-window Zoom preview).

## Issues Encountered

None. The first rewrite of `UpcomingBookingSecondaryActions` left mismatched braces, caught before any build and fixed by rewriting the file cleanly.

## Tracer gate

Task 1's `<verify>` carries automated checks and a device `<human-check>`. Under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT") the device check is deferred and Tasks 2 and 3 proceeded. The automated verify (16 view-model tests, three grep gates, `ClientBookingStatusFallbackTests` regression) passed on the committed tree first.

## Verification

- `UpcomingBookingViewModelTests`: 16 tests in 1 suite passed (`/tmp/03-09-t1.log`). `ClientBookingStatusFallbackTests`: 5 tests passed (`/tmp/03-09-reg.log`).
- `ExternalMeetingProviderTests`: 8 test functions in 1 suite passed (`/tmp/03-09-t2.log`); the compile-red run is `/tmp/03-09-t2-red.log`.
- `UpcomingActionPolicyTests`: 5 tests in 1 suite passed (`/tmp/03-09-t3.log`). `JoinWindowTests`: 13 tests passed (`/tmp/03-09-jw.log`).
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded (`/tmp/03-09-build.log`). Warning baseline for the five existing touched files was empty before; the comparison with the six touched files after prints nothing, so no new warnings.
- Acceptance greps: `func startCall()` 1, `TimelineView` in the view 2 (was 0), `isJoinEnabled` in the card 5 (was 0), inert `onJoinCall` default 0 (was 2), `JoinWindow.isOpen` in the view model 1, `CallCenter.shared.startCall` 1, `var openButtonTitle: String` 1, `Open Meeting` 4, `UIApplication.shared.open` in the card 0, `UpcomingActionPolicy.canShowCancel` in the view 1, `showsCancel` in the actions row 2, `enum UpcomingActionPolicy` 1.
- Tests for `startCall()` itself were not written, as the plan directs, because it reaches `CallCenter.shared`.

## Known Stubs

None.

## Threat Flags

None. T-03-16 mitigated: `openButtonTitle` sits on the exact-host `detect(from:)` (lookalike hosts tested to read "Open Meeting"), the button goes through `CallCenter.startCall`, and the card contains no URL opener (gate count 0). T-03-17 mitigated: `joinWindowOpen(at:)` forwards to the edge-tested `JoinWindow.isOpen` with `can_join`, with view-model rows for the reconnect tier and a 60 s tick. No new network, auth or file surface.

## Requirement status

CALL-03, CALL-08 and BOOK-13 are declared only by this plan (03-12 lists BOOK-12, BOOK-16, BOOK-17), and all three are delivered in code, so they are marked complete in REQUIREMENTS.md with the device checks pending below. Cancel and Reschedule on push-opened or Payments-opened details are wired by 03-12; this plan only changes when Cancel is visible.

## Deferred device checks (Phase 3 UAT)

Tracer `<human-check>` for CALL-03, deferred under the standing approval; see item 1.

## Pending device checks

1. **CALL-03:** open an in-app booking's Upcoming details from My Bookings and from a push tap inside the window; JOIN CALL starts the call. Also try from a chat row, the Explore today strip and the Payments list. An hour and a half early the button is dimmed and VoiceOver reads the hint; on a pending reschedule it is visible and disabled. A failed join (for example while already on another call) shows the "Couldn't join call" alert.
2. **CALL-08 (UI-SPEC D3, L3):** on a Skype/Zoom booking inside the window, Open in {provider} opens the Skype/Zoom session screen with the timer running; Open there launches the meeting app; End Session completes the booking. "Open in Microsoft Teams" fits on one line on the smallest supported iPhone, scaling down only if it would truncate.
3. **BOOK-13:** open a booking whose session has ended (from the Payments list) and one in progress; neither shows Cancel and Reschedule fills the row. A confirmed future booking shows both. Leave a booking open across its end time and confirm Cancel disappears within a minute.
4. **Join-failure alert note (assumption in the plan):** the alert is attached on this screen as well as at the My Bookings root. When Upcoming details is pushed from My Bookings both are in the hierarchy; confirm a failed join shows one "Couldn't join call" alert, not two.
5. **Two-tap Skype/Zoom note (D-10, RESEARCH Open Question 6):** opening a Skype/Zoom session takes two taps, Open in {provider} here and then Open on the session screen. Confirm that reads acceptably.

## Cross-repo and follow-ups

No backend change in this plan.

Android follow-up (logged, not built): Android's Upcoming details Cancel rule should match D-13: show Cancel only for confirmed, pending_approval and pending_reschedule bookings while the end time is in the future.

## Next Phase Readiness

03-12 can wire Cancel and Reschedule on push- and Payments-opened details; the visibility rule is already in place. No blockers.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/UpcomingActionPolicy.swift, ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift
- FOUND commits `10ce408`, `2b8394d`, `be60f6f` are ancestors of HEAD; `git rev-list --count 763cd8e..HEAD` = 3

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
