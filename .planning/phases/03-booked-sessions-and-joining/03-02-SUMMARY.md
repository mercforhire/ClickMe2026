---
phase: 03-booked-sessions-and-joining
plan: 02
subsystem: ui
tags: [swiftui, refund-preview, cancellation, swift-testing, timelineview]

requires:
  - phase: 01-backend-and-contract-fixes
    provides: Q2 / D-17 client-cancel 24-hour rule in src/utils/refund.js; paymentActionFields in src/utils/scaRecovery.js
  - phase: 03-booked-sessions-and-joining (plan 03-01)
    provides: ClientBookingFixtures shared GET /client/bookings/:id JSON builder
provides:
  - CancelRefundPreview, the pure refund-preview rule (cases A-F) and copy, mirroring refund.js
  - ClientBookingDetail.paymentActionRequired (optional, D-14)
  - Client cancel confirm step that shows the refund, release or no-charge line the backend will apply
  - 60 s re-check and recompute-at-tap that blocks a changed refund once (D-06)
affects: [03-10 post-cancel toast from the server's refund_amount, Phase 3 UAT checklist]

actuals:
  tokens: 7900   # chars/4 over the added lines of the realized diff (31,730 chars)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Pure rule helper with injected now (same style as JoinWindow); the view model owns the clock closure"
    - "TimelineView(.periodic) tick calling a view-model recompute, so a time-dependent line follows the clock"

key-files:
  created:
    - ClickMe2026/Utils/CancelRefundPreview.swift
    - ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift
    - ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift
  modified:
    - ClickMe2026/Model/Responses/ClientBookingDetail.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationBookingSummary.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift

key-decisions:
  - "The preview uses the list price topic.price.amount, not the amount paid (U2 dismissed); the post-cancel toast in 03-10 uses the server's refund_amount"
  - "A held booking with no authorization_expires_at is treated as charged and follows the strict 24-hour rule; payment_action_required or payment_status none reads as not charged"
  - "A case change at the confirm tap stores the new case, shows the notice and sends nothing; the next tap submits"
  - "Any payment_status other than none, held or captured (for example refunded) falls to the policy sentence rather than inventing a case"

patterns-established:
  - "Refund wording lives once in CancelRefundPreview; views never build money sentences"

requirements-completed: [BOOK-08]

coverage:
  - id: D1
    description: "Money line per case: free shows none, live hold reads as a release, charged more than 24 h out shows the refund, charged within 24 h shows the zero refund, uncharged reads as not charged, missing price reads as the policy sentence"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift (free, liveHold, liveHoldInsideWindow, chargedRefundable, heldWithoutExpiryIsCharged, notChargedWhenNone, notChargedWhenActionRequired, amountUnknown, unexpectedStatus)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exactly 24 hours out is not refundable and 24 hours plus one second is; zero-decimal currency formats the zero through Money"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift (chargedRefundable, exactBoundaryNotRefundable, zeroDecimalCurrency)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The preview never promises a refund the backend will not give: no amount inside 24 hours for a charge, no refund or charge wording for a hold or an uncharged booking"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift#neverPromisesWhatTheBackendWillNotGive"
        status: pass
    human_judgment: false
  - id: D4
    description: "A case that changed since it was shown blocks the first confirm tap with no request; the second tap sends exactly one cancel and clears the notice; an unchanged case and a free booking submit on the first tap"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift (changedCaseBlocksOnce, unchangedCaseSubmitsImmediately, freeBookingSubmits)"
        status: pass
    human_judgment: false
  - id: D5
    description: "SESSION_ALREADY_ENDED shows the server's own message, does not confirm, and leaves the client on the confirm step"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift#sessionAlreadyEnded"
        status: pass
    human_judgment: false
  - id: D6
    description: "ClientBookingDetail decodes payment_action_required when present and as nil when absent"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift#decodesPaymentActionRequired"
        status: pass
    human_judgment: false
  - id: D7
    description: "Refund footnote shows only for the charged-refundable case; the 60 s tick, the changed-refund notice and the 'Review Cancellation' alert button are wired"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift#footnote (rule); grep checks for TimelineView, showsRefundFootnote, Review Cancellation, and the notice text in the cancellation views"
        status: pass
    human_judgment: false
  - id: D8
    description: "Amber warning block, lock/credit-card icons, semibold amount in onSurface (never accent green), wrapping at the largest accessibility Dynamic Type size, and the 60 s tick on a real iPhone"
    requirement: BOOK-08
    verification: []
    human_judgment: true
    rationale: "Visual layout, colour and Dynamic Type wrapping need a device; the user deferred all tracer device checks to Phase 3 UAT"

duration: 25min  # Task 2 and close-out in this continuation run; Task 1 ran in the earlier executor session
completed: 2026-11-10
plan_head_before: d1c837eaa24bb551e6f2c93c383f2a0216b82c72
plan_head_after: 8c24f8604a03cbbbccbee3b186f4c14841dc1478
commits: 2
status: complete
---

# Phase 3 Plan 2: Client cancel previews the refund the backend gives Summary

**The client cancel confirm step now states the refund the backend will actually apply (release for a live hold, full refund more than 24 hours out, an amber zero-refund block inside 24 hours, "not charged" for an uncharged booking), re-checks it every minute, and blocks a tap once when the case changed since it was shown.**

## Performance

- **Duration:** about 25 min for this continuation run (Task 2 and close-out); Task 1 was done by the previous executor session
- **Completed:** 2026-11-10
- **Tasks:** 2 of 2
- **Files modified:** 8 (3 created, 5 modified), 737 insertions and 43 deletions in the plan range (before this Task 2 commit's share of tests)

## Accomplishments

- `CancelRefundPreview` mirrors `src/utils/refund.js` (strict `>` 24 hours) and `paymentActionFields`: cases free, live hold, charged refundable, charged not refundable, not charged yet, amount unknown. It owns the exact UI-SPEC sentences, the emphasised amount substring, the icon names and the footnote rule.
- `ClientBookingDetail.paymentActionRequired` is optional, so older payloads still decode.
- The confirm step renders the case through `CancellationBookingSummary` (neutral line, or the amber block with a single accessibility label for the within-24-hours zero refund) and the footnote only for the charged-refundable case.
- `ClientCancellationViewModel` carries an injected clock, `recomputeRefundCase()` on load and every 60 s via `TimelineView`, and `previewChangedNotice`. `confirmCancellation` recomputes first; a changed case is stored, the notice shows, nothing is sent, and the next tap submits. `isConfirming` still disables the button, so a second tap cannot double submit.
- The cancel error alert now dismisses with "Review Cancellation" and keeps the client on the confirm step; `SESSION_ALREADY_ENDED` shows the server's message.
- 19 tests in 2 suites pass (15 `CancelRefundPreviewTests`, 4 `ClientCancellationViewModelTests`).

## Task Commits

1. **Task 1: Tracer, the confirm step shows the refund the backend will actually give** - `b55dc5b` (feat)
2. **Task 2: The preview re-checks every minute and at confirm; a changed refund blocks the submit once** - `8c24f86` (feat)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Utils/CancelRefundPreview.swift` - pure rule, copy, emphasis, icons, footnote predicate
- `ClickMe2026/Model/Responses/ClientBookingDetail.swift` - `paymentActionRequired: Bool?`
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift` - `CancellationBooking.refundFacts` / `refundCase`, 60 s `TimelineView`, changed-refund notice, "Review Cancellation"
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift` - injected clock, `recomputeRefundCase()`, `previewChangedNotice`, recompute at confirm; list-price refund helper removed
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationBookingSummary.swift` - money line and amber block replace the old policy-refund row
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift` - footnote conditional
- `ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift`, `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift` - the two suites

## Decisions Made

- The preview shows the list price, not the amount paid (U2 dismissed); the server's `refund_amount` is worded in the post-cancel toast by plan 03-10.
- A `held` booking without `authorization_expires_at` is treated as charged (RESEARCH Pitfall 4); the one backend exception, a failed off-session charge awaiting card authentication, arrives as `payment_action_required` and reads as not charged.
- The changed-case block applies in the preview-seed path too (before the `bookingId` guard), so previews and tests exercise the same rule.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking, minor] ClientCancellationViewModelTests builds its detail through the shared `ClientBookingFixtures`**
- **Found during:** Task 2
- **Issue:** The plan said to copy a private detail JSON builder because the shared fixtures might not exist yet. Plan 03-01 had already created `ClientBookingFixtures`, so a private copy would be a duplicate.
- **Fix:** The suite uses `ClientBookingFixtures.detailJSON` (paid CAD 4500 topic, `payment_status` and start passed in), `response(for:)` and `errorBody(code:message:)`.
- **Files modified:** `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift`
- **Committed in:** `8c24f86`

---

**Total deviations:** 1 auto-fixed (Rule 3, test scaffolding only)
**Impact on plan:** None on shipped behavior or scope.

## Issues Encountered

None. The first plan-level test run exited non-zero only because a trailing `grep error:` found nothing; the xcodebuild result was `TEST SUCCEEDED`.

## Verification

- Tests: `ClientCancellationViewModelTests` and `CancelRefundPreviewTests`, 19 tests in 2 suites passed.
- BUILD: `xcodebuild build` (Debug, iPhone 17) printed `BUILD SUCCEEDED`. The warning comparison against `/tmp/03-02-warn-before.txt` for the six app files printed nothing (no new warnings).
- Acceptance checks: `Review Cancellation` appears once and `TimelineView` in the cancellation view; `showsRefundFootnote` appears once in `CancellationConfirmCard`; `previewChangedNotice` appears 4 times in the view model; "so your refund has changed" appears once in the view.

## Known Stubs

None.

## Pending device checks

Deferred device checks (Phase 3 UAT), BOOK-08, on a real iPhone. The user deferred all tracer device checks to UAT.

Task 1 (confirm-step copy):
1. Cancel a booking with a live hold: lock icon and "The {amount} hold on your card will be released, so you won't be charged." No refund footnote.
2. Cancel a charged booking (captured, or held and past the T-24h charge) more than 24 hours out: "Refund: {amount}, cancelled more than 24 hours before the start" and the "Refunds typically appear..." footnote.
3. Cancel a charged booking within 24 hours: the amber block "Refund: {zero}" with "the session starts within 24 hours", no footnote.
4. Cancel a booking that was never charged (payment_status none, or a failed charge awaiting card authentication): "You haven't been charged for this session, so nothing will be charged."
5. The amount is semibold in the primary text colour, never green.

Task 2 (re-check):
6. Optional timing case: keep the confirm step open across the 24-hour line on a charged booking. The line turns into the amber block, the first Confirm Cancellation tap shows "The session now starts within 24 hours, so your refund has changed..." and submits nothing, the second tap cancels.
7. A failed cancel shows "Couldn't cancel booking" with the server's message and "Review Cancellation", leaving the confirm step on screen.
8. At the largest accessibility Dynamic Type size, the amber block and the money line wrap without clipping.

## Threat Flags

None. No new endpoint, auth path or schema; the app only previews, the server still computes and moves the money (T-03-04 and T-03-05 mitigated as planned).

## Cross-repo and follow-ups

No backend change. Android is not affected by this plan; the iOS case E copy is iOS-only (UI-SPEC discretion). Plan 03-10 words the post-cancel toast from the server's `refund_amount` and handles the comment.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/CancelRefundPreview.swift
- FOUND: ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift
- FOUND: ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift
- FOUND: commit b55dc5b
- FOUND: commit 8c24f86
