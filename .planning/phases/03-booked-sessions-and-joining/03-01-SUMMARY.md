---
phase: 03-booked-sessions-and-joining
plan: 01
subsystem: ui
tags: [swiftui, observation, reschedule, stripe-payment-method-recovery, swift-testing]

requires:
  - phase: 02-client-bookings
    provides: ClientBookingDetail decoding of reschedule and authorization_expires_at; BookingErrorMapper; Upcoming Booking details screen
provides:
  - RescheduleResponder, the one accept/decline/payment-method-recovery path for a client answering an expert-proposed time
  - RescheduleResponseCard, the one shared response card (expert proposed / client proposed variants)
  - Upcoming Booking details answers the proposal in place, with a silent refresh
  - UTF16Prefix, grapheme-safe truncation matching the server's zod max()
  - ClientBookingFixtures and URLRequest.bodyDataForTest() shared test support
affects: [03-06 reschedule toast, 03-13 Booking Summary move onto responder and card, 03-14 status pill]

actuals:
  tokens: 13300   # chars/4 over the added lines of the realized diff (53,338 chars)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "@MainActor @Observable helper owned by an ObservableObject view model; the owner injects a refetch closure"
    - "Silent refresh that never flips state to .loading (token-guarded, failure while loaded keeps content)"
    - "Branch on ErrorCode via BookingErrorMapper.code(for:), never on message text"

key-files:
  created:
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/RescheduleResponseCard.swift
    - ClickMe2026/Utils/UTF16Prefix.swift
    - ClickMe2026Tests/Support/ClientBookingFixtures.swift
    - ClickMe2026Tests/Support/URLRequest+Body.swift
    - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
    - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift

key-decisions:
  - "RescheduleResponder is @MainActor @Observable, not ObservableObject, so views read responder.isSubmitting without objectWillChange forwarding"
  - "Decline reason is capped on submit (500 UTF-16 units, character boundary), not per keystroke, because an alert TextField cannot host a counter"
  - "Booking Summary keeps its own accept/decline copy for one wave; plan 03-13 deletes it and moves onto the responder and card"

patterns-established:
  - "Shared money-affecting action lives once in a responder; screens supply refetch"
  - "Phase 3 view-model suites build their GET payloads through ClientBookingFixtures.detailJSON with extraFields for plan-specific keys"

requirements-completed: [BOOK-06]

coverage:
  - id: D1
    description: "Upcoming Booking details shows the reschedule response card for an expert-proposed pending_reschedule booking and none for a confirmed one"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#expertProposalIsExposed, confirmedHasNoProposal, clientProposalIsExposed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Accept sends one POST and the screen updates in place without leaving .loaded"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift#acceptUpdatesInPlace, failedRefreshKeepsContent"
        status: pass
    human_judgment: false
  - id: D3
    description: "PAYMENT_METHOD_REQUIRED recovery, auth-window copy, unmapped-code passthrough and concurrent-tap guard"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleResponderTests.swift (acceptSuccess, retriesWithDefaultCard, emptyVault, vaultReadFails, secondPaymentMethodRequiredIsTerminal, outsideAuthWindow, outsideAuthWindowOnRetry, unmappedCodeShowsServerMessage, concurrentAcceptSendsOnce)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Decline reason trimmed, omitted when blank, capped at 500 UTF-16 units without splitting a character"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleResponderTests.swift (blankReasonOmitted, reasonTrimmed, longReasonCapped, emojiReasonCappedWithoutSplitting, prefixKeepsSurrogatePairsWhole)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Accept confirmation dialog text: short text, hold-release disclosure past the authorization window, near-term caveat under 48 hours"
    requirement: BOOK-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/RescheduleResponderTests.swift (dialogShortText, dialogNoExpiry, dialogDisclosure, dialogNearTermCaveat)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Card layout, 44 pt buttons, Dynamic Type at the largest accessibility size, and the no-spinner-flash feel on a real iPhone"
    requirement: BOOK-06
    verification: []
    human_judgment: true
    rationale: "Visual layout, Dynamic Type clipping and animation feel need a device; listed in the Phase 3 UAT checklist (human_verify_mode is end-of-phase)"

duration: 15min  # Task 2 and close-out in this continuation run; Task 1 ran in the earlier executor session
completed: 2026-11-10
plan_head_before: 596c75fd901b9fd2aab0e7aa62bf6ac34d63f570
plan_head_after: 31fd502100fb414db3a236b6b529e8e74e0017dd
commits: 2
status: complete
---

# Phase 3 Plan 1: Client answers an expert reschedule Summary

**A client can accept or decline an expert-proposed time from Upcoming Booking details through one shared `RescheduleResponder` and `RescheduleResponseCard`, staying on the screen while it refreshes silently; the decline reason is capped at 500 UTF-16 units and the PAYMENT_METHOD_REQUIRED recovery matrix is under test.**

## Performance

- **Duration:** about 15 min for this continuation run (Task 2 and close-out); Task 1 was done by the previous executor session
- **Completed:** 2026-11-10
- **Tasks:** 2 of 2
- **Files modified:** 9 (7 created, 2 modified), 1,327 insertions in the plan range

## Accomplishments

- `RescheduleResponder` holds the accept/decline logic lifted from `BookingSummaryViewModel`: an `isSubmitting` guard that stops a second tap sending a second request, the saved-card retry on `PAYMENT_METHOD_REQUIRED` (default card, else first), the exact UI-SPEC copy for an empty vault, a failed vault read, an unusable card and `RESCHEDULE_OUTSIDE_AUTH_WINDOW`, and the pure dialog-message helpers (`requiresDisclosure`, `chargesSoon`, `acceptDialogMessage`).
- `RescheduleResponseCard` renders the expert-proposed variant (FROM/TO, optional plain-text note, 44 pt Accept New Time / Decline New Time with an in-button spinner) and the client-proposed variant ("You proposed a new time" with the awaiting pill and no buttons).
- `UpcomingBookingViewModel` gained `reschedule`, `authorizationExpiresAt`, `startTime`, `responder`, `pendingProposal`, `acceptDialogMessage`, a token-guarded silent `refresh()` and `appeared()`. The view renders the card under the status row and wires the confirmation dialog, decline alert and "Couldn't update booking" alert.
- `UTF16Prefix.prefix(_:limit:)` truncates on a character boundary by UTF-16 length, so emoji can no longer push a decline reason over the server's `z.string().max(500)` after the user confirmed.
- 23 responder tests plus the Upcoming view-model suite pass; the shared `ClientBookingFixtures` and `bodyDataForTest()` are in place for later Phase 3 suites.

## Task Commits

1. **Task 1: Tracer, client accepts the expert's proposed time on Upcoming Booking details** - `46b46a0` (feat)
2. **Task 2: 500-unit decline cap; responder recovery matrix tested** - `31fd502` (feat)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift` - shared accept/decline/recovery, error copy, dialog-message helpers, `declineReasonLimit`
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/RescheduleResponseCard.swift` - shared response card, `slotLabel(_:)`, previews
- `ClickMe2026/Utils/UTF16Prefix.swift` - grapheme-safe UTF-16 cap
- `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift` - proposal state, responder, silent refresh
- `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift` - card, dialogs, `appeared()` task
- `ClickMe2026Tests/Support/ClientBookingFixtures.swift` - shared `GET /client/bookings/:id` JSON builder
- `ClickMe2026Tests/Support/URLRequest+Body.swift` - shared request-body reader for tests
- `ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift`, `ClickMe2026Tests/Booking/RescheduleResponderTests.swift` - the two suites

## Decisions Made

- `RescheduleResponder` is `@MainActor @Observable` so two `ObservableObject` owners can share it and views track `isSubmitting` without forwarding `objectWillChange`.
- The decline cap applies on submit, not per keystroke, because an alert `TextField` cannot host a counter.
- Booking Summary is left untouched; its duplicate accept/decline code lives for one wave until plan 03-13.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `RescheduleProposal.previewSample(initiatedBy:note:)` in RescheduleResponseCard.swift**
- **Found during:** Task 1
- **Issue:** The two `#Preview` blocks the plan requires, and the Upcoming "Reschedule proposed" preview, need a `RescheduleProposal` value, and the type only has a memberwise init with required `createdAt` and `proposedTimezone`.
- **Fix:** A small preview-sample helper beside the card so the previews stay short.
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/RescheduleResponseCard.swift`
- **Committed in:** `46b46a0`

**2. [Rule 3 - Blocking] Marked the test-side static helpers `nonisolated` and added `jsonBodyForTest()`**
- **Found during:** Task 2
- **Issue:** The `MockURLProtocol` handler is `@Sendable`, so it cannot call statics isolated to the `@MainActor` suite under Swift 6 strict concurrency; and each body assertion needed a decoded dictionary.
- **Fix:** `nonisolated` on the suite's static request-matching helpers and fixture bodies; a small `jsonBodyForTest()` beside `bodyDataForTest()`.
- **Files modified:** `ClickMe2026Tests/Booking/RescheduleResponderTests.swift`, `ClickMe2026Tests/Support/URLRequest+Body.swift`
- **Committed in:** `31fd502`

---

**Total deviations:** 2 auto-fixed (2 Rule 3)
**Impact on plan:** Both are test or preview scaffolding; no change to shipped behavior or scope.

## Issues Encountered

None. The 500-unit cap and its tests were written together rather than as a separate red commit, since the plan specifies one commit for Task 2.

## Verification

- `RescheduleResponderTests`: 23 tests in 1 suite passed. `UpcomingBookingViewModelTests` and `ClientBookingStatusFallbackTests` (Phase 2 BOOK-18 regression) pass.
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded. The warning comparison for `RescheduleResponder.swift`, `RescheduleResponseCard.swift`, `UTF16Prefix.swift`, `UpcomingBookingViewModel.swift` and `UpcomingBookingView.swift` is empty before and after (no new warnings).
- Acceptance greps: `declineReasonLimit` appears 3 times, `UTF16Prefix.prefix` is used in the responder, `func bodyDataForTest` appears once.

## Known Stubs

None.

## Pending device checks

For the Phase 3 UAT checklist (BOOK-06), on a real iPhone:

1. With the expert proposing a new time from a second device, open the booking from My Bookings, tap the card, Accept New Time, confirm. The card disappears, the date and time change in place, and the screen stays on Upcoming Booking details with no spinner flash.
2. Decline New Time with a long reason containing emoji succeeds and the original time stays.
3. At the largest accessibility Dynamic Type size, the card, its 44 pt buttons and a long expert note stay unclipped.

## Cross-repo and follow-ups

No backend change and no Android change in this plan. Android keeps the label `Accept` (logged copy difference, UI-SPEC). Plan 03-13 moves Booking Summary onto `RescheduleResponder` and `RescheduleResponseCard` and deletes its duplicate; the toast is plan 03-06 and the real status pill is plan 03-14.

## Next Phase Readiness

Plans 03-06 and 03-13 can build on the responder, card and fixtures. No blockers.

## Self-Check: PASSED

All seven created files exist; commits `46b46a0` and `31fd502` are ancestors of HEAD.

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-10*
