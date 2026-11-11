---
phase: 03-booked-sessions-and-joining
plan: 13
subsystem: ui
tags: [swiftui, observation, reschedule, booking-summary, swift-testing]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: RescheduleResponder, RescheduleResponseCard and ClientBookingFixtures (plan 03-01); ToastCenter posted by the responder (plan 03-06)
provides:
  - Booking Summary answers an expert-proposed time through the shared RescheduleResponder and RescheduleResponseCard, with no accept, decline or PAYMENT_METHOD_REQUIRED code of its own
  - BookingSummaryViewModel.refresh(), a silent refetch used by the responder and by booking.update
  - BookingSummaryViewModelTests, with a reviewContextJSON(hasSubmitted:) helper for plan 03-07
affects: [03-07 Booking Summary review gate and ID line, 03-12 device UAT]

actuals:
  tokens: 3300   # chars/4 over the added lines of the realized diff (13,375 chars)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "A second screen adopts a shared @Observable responder by owning it and injecting its silent refresh as refetch"
    - "Silent refresh writes the detail and the soft review context under one newest-token check and never touches loadState once loaded"

key-files:
  created:
    - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift

key-decisions:
  - "The silent refresh fetches the detail, then the review context, and writes both only if the call is still the newest; a failed detail fetch returns without writing, a failed review context keeps the previous review state"
  - "booking.update calls refresh() and reload() stays for pull-to-refresh and the error state's retry"

patterns-established:
  - "Both client screens that show a proposed time own a RescheduleResponder and render RescheduleResponseCard; the dialog and alerts are bound to responder.accept(), decline(reason:) and apiError"

requirements-completed: [BOOK-06]

coverage:
  - id: D1
    description: "Booking Summary exposes an expert-initiated pending_reschedule proposal and the current start"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#expertProposalIsExposed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Accept sends one POST and Booking Summary shows the confirmed booking in place without leaving .loaded"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#acceptUpdatesInPlace"
        status: pass
    human_judgment: false
  - id: D3
    description: "The accept dialog message is the responder's, including the payment-conversion disclosure"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#dialogMessageIsTheRespondersOwn"
        status: pass
    human_judgment: false
  - id: D4
    description: "A failed detail refetch, or a failed review-context refetch, never blanks Booking Summary; the preview responder sends nothing"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#failedRefreshKeepsContent, failedReviewContextKeepsLoadedAndAppliesDetail, previewResponderSendsNothing"
        status: pass
    human_judgment: false
  - id: D5
    description: "No duplicate accept/decline logic or Settings > Payment text remains on Booking Summary"
    requirement: BOOK-06
    verification:
      - kind: other
        ref: "grep gates: func acceptReschedule 0, Settings > Payment 0 (view model and view), private func rescheduleCard 0, RescheduleResponseCard( 1, Back to Booking 1"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real iPhone, Accept New Time and Decline New Time on Booking Summary read the new labels, behave as on Upcoming details, and the screen updates with no spinner flash"
    requirement: BOOK-06
    verification: []
    human_judgment: true
    rationale: "Visual feel of the in-place update and the dialog presentation need a device; on the Phase 3 UAT checklist (human_verify_mode is end-of-phase)"

duration: 7min
completed: 2026-11-11
plan_head_before: e68604d70a35893f03f1797c0a7a0c8206cdf2ab
plan_head_after: ce0b7f534c6fa2f48fb2a29851e6fd197573fcb2
commits: 2
status: complete
---

# Phase 3 Plan 13: Booking Summary on the shared reschedule responder Summary

**Booking Summary now accepts and declines an expert-proposed time through the same `RescheduleResponder` and `RescheduleResponseCard` as Upcoming Booking details, with the UI-SPEC labels, and refetches silently so neither an accept, a decline nor a `booking.update` ever flips the loaded screen to a spinner.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-11-11T04:50Z
- **Completed:** 2026-11-11T04:57Z
- **Tasks:** 2 of 2
- **Files modified:** 3 (1 created, 2 modified); 296 lines added, 288 removed

## Accomplishments

- `BookingSummaryViewModel` owns `let responder: RescheduleResponder` (runtime and preview inits; the preview one has a nil booking id so it never sends a request). The in-flight flag, the error string, the two disclosure computeds, `acceptReschedule`, `declineReschedule`, the error-code helper and `formatSlot` are deleted. The two "Settings > Payment" strings went with them, so the responder's "Profile > Payment" copy is the only payment-menu wording on the screen.
- `acceptDialogMessage` forwards to `RescheduleResponder.acceptDialogMessage`, so the payment-conversion disclosure and the near-term caveat match Upcoming details word for word.
- `refresh()` is the silent refetch: not loaded runs the full load; loaded fetches the detail then the review context and writes both under one newest-token check, leaving `loadState` alone. The responder's `refetch` and the `booking.update` handler both call it. `reload()` stays for pull-to-refresh and the error retry.
- `BookingSummaryView` renders `RescheduleResponseCard` and binds the dialog ("Accept the proposed reschedule?", Accept New Time / Keep Current Time), the decline alert (Decline New Time / Keep session as-is) and the "Couldn't update booking" alert (Back to Booking) to `viewModel.responder`. The Accept and Decline entry points stay on this screen (D-01). The four private card helpers and the private dialog-message computed are gone.
- Because the responder is the 03-06 one, an accept or decline from Booking Summary posts "Reschedule accepted" / "Reschedule declined" to the client shell's toast with no extra code.
- `BookingSummaryViewModelTests` (6 tests, 1 suite) with the private `reviewContextJSON(hasSubmitted:)` helper that plan 03-07 reuses.

## Task Commits

1. **Task 1: Tracer, Booking Summary's Accept New Time runs through the shared responder and card and updates in place** - `b3dbd2f` (refactor)
2. **Task 2: Realtime and failed refetches never blank Booking Summary** - `ce0b7f5` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift` - responder, `acceptDialogMessage`, silent `refresh()`; old accept/decline code removed
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift` - shared card, responder-bound dialog and alerts
- `ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift` - the suite

## Decisions Made

- The silent refresh writes the detail and the review context only after both fetches and a newest-token check, so a half-applied snapshot never shows.
- A failed review context while loaded keeps the previous `hasSubmittedReview`, `feedbackStars` and `feedbackText`; the full load keeps its existing soft-failure rule (hide the feedback section).

## Deviations from Plan

None - plan executed exactly as written.

Task 2 is marked `tdd="true"`, but its refresh rows passed on first run because `refresh()` was built in Task 1 (the responder's `refetch` needs it). The only Task 2 production change, routing `booking.update` through `refresh()`, has no unit seam (the realtime callback is internal to `RealtimeService`), so it is covered by the grep gate and the device check. Same pattern as plans 03-01 and 02-11.

## Issues Encountered

None. Baseline and final warning sets for `BookingSummaryViewModel.swift` and `BookingSummaryView.swift` were both empty, so there are no new warnings.

## Verification

- `BookingSummaryViewModelTests`: 6 tests in 1 suite passed. Regression: `RescheduleResponderTests` and `UpcomingBookingViewModelTests` pass (32 tests in 2 suites, `/tmp/03-13-reg1.log`).
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded; the warning comparison printed nothing.
- Acceptance greps: `let responder: RescheduleResponder` 1 (baseline 0), `acceptDialogMessage` in the view 1, `func acceptReschedule` 0 (baseline 1), `Settings > Payment` 0 in the view model and the view (baseline 2), `private func rescheduleCard` 0 (baseline 1), `RescheduleResponseCard(` 1, `Back to Booking` 1, `func refresh() async` 1, `self?.refresh()` 2.

## Known Stubs

None.

## Deferred device checks (Phase 3 UAT)

Standing user approval 2026-11-10: tracer device checks are deferred to UAT. On a real iPhone (UI-SPEC section 1, BOOK-06):

1. Open Booking Summary for a booking where the expert has proposed a new time. The card reads "Expert requested a new time" with Accept New Time and Decline New Time.
2. Accept New Time shows "Accept the proposed reschedule?" with Accept New Time / Keep Current Time and, for a payment-conversion case, the same disclosure text as Upcoming details. After confirming, the card disappears and the times change in place with no spinner flash, and "Reschedule accepted" shows above the tab bar (the 03-06 toast reached through this plan).
3. Decline New Time asks for an optional reason (Decline New Time / Keep session as-is); after it succeeds the original time stays and "Reschedule declined" shows.
4. A failed accept or decline shows "Couldn't update booking" dismissed by "Back to Booking".
5. A `booking.update` while the screen is open (for example the expert changes the proposal from a second device) updates the content in place with no spinner.

Plan 03-12's checklist item for BOOK-06 already includes one accept or decline from Booking Summary.

## Requirements

BOOK-06 is declared by plans 03-01, 03-06 and 03-13; this is the last of them, so it is marked complete in REQUIREMENTS.md. Its device checks stay pending in the 03-12 checklist.

## Cross-repo and follow-ups

No backend change and no Android change in this plan. No new Android follow-up.

## Next Phase Readiness

Plan 03-07 can add its review-gate and ID rows to `BookingSummaryViewModelTests` and reuse `reviewContextJSON(hasSubmitted:)`. No blockers.

## Self-Check: PASSED

`BookingSummaryViewModelTests.swift` exists; commits `b3dbd2f` and `ce0b7f5` are ancestors of HEAD.

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
