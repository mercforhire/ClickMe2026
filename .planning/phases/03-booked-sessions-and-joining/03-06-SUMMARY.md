---
phase: 03-booked-sessions-and-joining
plan: 06
subsystem: ui
tags: [swiftui, observation, toast, accessibility, reschedule, swift-testing]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: RescheduleResponder (plan 03-01), the one accept/decline path for an expert-proposed time
provides:
  - ToastCenter, the one shared transient confirmation (one at a time, 4 s timer, VoiceOver announcement, injectable duration)
  - ToastHost, the ViewModifier that renders ToastCenter.current above the tab bar
  - Client shell hosts the toast; RescheduleResponder confirms "Reschedule accepted" / "Reschedule declined" after a 2xx
affects: [03-10 cancel toasts, 03-11 reschedule-request toast, 03-13 Booking Summary move onto responder, 03-12 device UAT]

actuals:
  tokens: 2700   # chars/4 over the added lines of the realized diff (10,923 chars)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Shell-owned @MainActor @Observable manager with static shared and an injectable instance for tests"
    - "Timer task that clears state only if the toast id is still the one it was started for"
    - "Producers post a confirmation only after the 2xx, before the owner's refetch"

key-files:
  created:
    - ClickMe2026/Managers/ToastCenter.swift
    - ClickMe2026/Views/Components/Toast/ToastHost.swift
    - ClickMe2026Tests/Utils/ToastCenterTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
    - ClickMe2026Tests/Booking/RescheduleResponderTests.swift

key-decisions:
  - "ToastCenter takes displayDuration through init (default 4 s) so tests use 300 ms or 60 s instances and never touch the shell's shared one"
  - "RescheduleResponder takes toasts: ToastCenter = .shared by injection; the toast is posted before refetch so the confirmation survives the screen update"
  - "The chip is a continuous RoundedRectangle (radius 20) rather than a Capsule, so a wrapped money message keeps the same radius family without a second shape"

patterns-established:
  - "Later producers (plans 03-10, 03-11) call ToastCenter.shared.show(_:systemImage:) after a 2xx and before they pop"

requirements-completed: [BOOK-06]

coverage:
  - id: D1
    description: "A successful accept posts 'Reschedule accepted' to the injected ToastCenter before the refetch runs"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleResponderTests.swift#acceptPostsToast"
        status: pass
    human_judgment: false
  - id: D2
    description: "A successful decline posts 'Reschedule declined'; a failed accept or decline (409) leaves no toast"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleResponderTests.swift#declinePostsToast, failedAcceptShowsNoToast, failedDeclineShowsNoToast"
        status: pass
    human_judgment: false
  - id: D3
    description: "One toast at a time: a new message replaces the current one and restarts the timer; dismiss clears immediately"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ToastCenterTests.swift#showReplaces, replacementRestartsTimer, dismissClears, showAfterDismiss"
        status: pass
    human_judgment: false
  - id: D4
    description: "The client shell hosts the toast and the expert shell does not"
    requirement: BOOK-06
    verification:
      - kind: other
        ref: "grep 'ToastHost()' HomeClientView.swift >= 1; grep 'ToastHost' HomeExpertView.swift == 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Placement 24 pt above the tab bar, never over the card buttons or keyboard, VoiceOver speaks it, wraps cleanly at the largest Dynamic Type size, fades only"
    requirement: BOOK-06
    verification: []
    human_judgment: true
    rationale: "SwiftUI placement, keyboard avoidance, VoiceOver output and Dynamic Type wrapping are not asserted by unit tests (UI-SPEC D2, L2); on the Phase 3 UAT checklist"

duration: 25min
completed: 2026-11-11
plan_head_before: d8a8be5008ad4f45c4afe446c8df6e1831a5a2fe
plan_head_after: 5dd55ed52c5bdcce6d7edcb0a7fa2182434fa7ae
commits: 2
status: complete
---

# Phase 3 Plan 6: Shared client toast for reschedule confirmations Summary

**A shell-owned `ToastCenter` and `ToastHost` show "Reschedule accepted" or "Reschedule declined" above the client tab bar after a 2xx response, one toast at a time with a restartable 4-second timer, tap-to-dismiss and a VoiceOver announcement.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-11 (UTC)
- **Tasks:** 2 of 2
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `ToastCenter` (`@MainActor @Observable`, `static let shared`) holds `current: Toast?`. `show` replaces the toast, cancels the old timer, starts a new one that clears `current` only if it still holds the same toast id, and posts an `AccessibilityNotification.Announcement`. `dismiss` clears at once.
- `ToastHost` overlays the chip bottom-anchored: `surfaceContainerHigh` fill, `primary` at 60% stroke, `.subheadline` semibold text, 16/8 pt padding, 24 pt side margins, 24 pt plus 49 pt tab bar from the bottom. The 0.25 s ease-in-out opacity fade is the only motion, so Reduce Motion needs no extra branch. A tap dismisses. No Brand token was added.
- `HomeClientView` applies `.modifier(ToastHost())` right after `CallOverlayHost`; `HomeExpertView` has none.
- `RescheduleResponder` takes `toasts: ToastCenter = .shared` and posts after a 2xx accept (both the first attempt and the saved-card retry) and a 2xx decline, before `refetch`. Failure paths never toast (T-03-11).
- Tests: 4 `ToastCenterTests` rows (replace, timer restart with a 300 ms duration, dismiss, show after dismiss) and 4 new responder rows. The responder suite is at 27 tests, all passing.

## Task Commits

1. **Task 1: Tracer, accepting a proposed time shows "Reschedule accepted" above the tab bar** - `24033b5` (feat)
2. **Task 2: One toast at a time; a declined reschedule confirms; failures never toast** - `5dd55ed` (feat)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Managers/ToastCenter.swift` - the shared toast state and timer
- `ClickMe2026/Views/Components/Toast/ToastHost.swift` - the chip and overlay, with a preview
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` - hosts the toast
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift` - injected `toasts`, posts on 2xx accept and decline
- `ClickMe2026Tests/Utils/ToastCenterTests.swift` - timing and replacement rows
- `ClickMe2026Tests/Booking/RescheduleResponderTests.swift` - accept/decline toast rows and the two failure rows

## Decisions Made

- `displayDuration` is an init parameter, so tests never wait 4 seconds and never share the shell's instance.
- The toast is posted before `refetch`, as the plan specifies, so the message exists before the screen updates.
- Rounded rectangle at radius 20 instead of `Capsule`, so a wrapped multi-line message keeps the same corner radius.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Baseline and final warning sets for the four touched app files were both empty, so there are no new warnings.

## Verification

- `RescheduleResponderTests`: 24 tests passed after Task 1, 27 after Task 2. `ToastCenterTests`: 4 passed.
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded; the warning comparison printed nothing.
- Acceptance greps: `final class ToastCenter` 1, `AccessibilityNotification.Announcement` 1, `struct ToastHost: ViewModifier` 1, `struct ToastCenterTests` 1, `ToastHost()` in `HomeClientView` 1, `ToastHost` in `HomeExpertView` 0, `Reschedule accepted` and `Reschedule declined` each 1 in the responder.

## Known Stubs

None.

## Deferred device checks (Phase 3 UAT)

Standing user approval 2026-11-10: tracer device checks are deferred to UAT. On a real iPhone (UI-SPEC D2, L2):

1. Accept a proposed time on Upcoming details: "Reschedule accepted" appears about 24 pt above the tab bar for about 4 seconds, a tap dismisses it early, VoiceOver reads it, and it does not cover the Accept New Time / Decline New Time buttons or the keyboard.
2. Decline a proposed time: "Reschedule declined" shows.
3. A failed accept (for example on a booking the expert has just cancelled) shows the "Couldn't update booking" alert and no toast.
4. A multi-line message wraps cleanly at the largest accessibility Dynamic Type size, and with Reduce Motion on it only fades.
5. Booking Summary accept and decline get the same toast only after plan 03-13 moves it onto the responder; check that step in the 03-12 UAT.

## Requirements

BOOK-06 is also listed by plans 03-08, 03-12 and 03-13 in this phase, and plan 03-13 (Booking Summary onto the responder) has no summary yet. REQUIREMENTS.md was not touched by this plan; BOOK-06 stays as it is until 03-13 finishes.

## Cross-repo and follow-ups

No backend change. No Android follow-up from this plan (Android already shows toasts). Plans 03-10 and 03-11 post their cancel and reschedule-request messages to `ToastCenter.shared`.

## Next Phase Readiness

`ToastCenter.show(_:systemImage:)` is ready for plans 03-10 and 03-11. No blockers.

## Self-Check: PASSED

`ToastCenter.swift`, `ToastHost.swift` and `ToastCenterTests.swift` exist; commits `24033b5` and `5dd55ed` are ancestors of HEAD.

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
