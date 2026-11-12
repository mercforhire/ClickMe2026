---
phase: 04-booking-payment-and-discovery
plan: 09
subsystem: payments
tags: [swiftui, booking, payment-copy, swift-testing, fail-closed]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "04-03 Request Sent exits and 04-04 DateUtil.shortTime times on the same view model and view"
provides:
  - "PaymentLifecycleVariant: pure chooser (liveHold, chargeScheduled, alreadyCharged) over booking status, payment_status and authorization_expires_at, with per-variant copy and icons"
  - "PaymentLifecycleCard.variant (init default .liveHold, so PaymentInfoSheet is unchanged)"
  - "BookingRequestSentViewModel.paymentVariant, chosen in apply(_:) from the loaded booking"
affects: [04-14]

actuals:
  tokens: 5600
  tasks: 2
  commits: 2
plan_head_before: 507346b0975331ce13e3443ef505a7d2d36b9d33
plan_head_after: 819d8582b53915d35035303264f60cbe02008512

tech-stack:
  added: []
  patterns:
    - "A nonisolated pure chooser compares raw server strings (not the MainActor-isolated BookingStatus) and returns nil to hide a UI element when the data cannot support it (fail closed)"

key-files:
  created:
    - ClickMe2026/Utils/PaymentLifecycleVariant.swift
    - ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift

key-decisions:
  - "held with a live authorization_expires_at is the live hold; held without one hides the card, because the backend derives held from booking status alone and the payload cannot tell a hold from a charge"
  - "none is a scheduled charge only on pending_approval, pending_reschedule or confirmed; any other status (cancelled, declined, expired, missed, completed, in_progress, unknown, missing) hides the card"
  - "captured, and only captured, reads as already charged; refunded, empty and unknown payment values hide the card"
  - "The status pill is unchanged (K1); the card still shows no amount"

requirements-completed: [PAY-03]

coverage:
  - id: D1
    description: "PaymentLifecycleVariant.choose returns the live hold, scheduled charge or already-charged variant per the backend payment state, and nil for free, held without an expiry, none on a non-pending/confirmed booking, refunded and unknown values"
    requirement: PAY-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift#PaymentLifecycleVariantTests"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each variant's four strings and icons equal the UI-SPEC table"
    requirement: PAY-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift#liveHoldCopy, chargeScheduledCopy, alreadyChargedCopy"
        status: pass
    human_judgment: false
  - id: D3
    description: "BookingRequestSentViewModel loads paymentVariant from a stubbed booking detail (live hold, scheduled, cancelled-none, held-no-expiry, captured, free, refunded)"
    requirement: PAY-03
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift#BookingRequestSentVariantTests"
        status: pass
    human_judgment: false
  - id: D4
    description: "UI-SPEC D3: variant A appears on Request Sent for a real paid booking with a live hold, and a free booking shows no payment card (D-11 device session)"
    requirement: PAY-03
    verification: []
    human_judgment: true
    rationale: "Needs a real paid booking with a live Stripe hold on a device; deferred to the 04-14 D-11 session and logged in WINDOWS.md as unrun-verify"

duration: 12min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 09: Request Sent payment card Summary

**A tested pure chooser makes Request Sent's "What happens next" card say hold, scheduled charge or already charged from the loaded booking, and hide itself whenever the payment data cannot support any of those**

## Performance

- **Duration:** 12 min
- **Tasks:** 2
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- `PaymentLifecycleVariant.choose(isFree:bookingStatus:paymentStatus:authorizationExpiresAt:)` is a `nonisolated` pure function. Live hold needs `held` plus a non-nil expiry (the `CancelRefundPreview` rule). Scheduled charge needs `none` on a pending_approval, pending_reschedule or confirmed booking. Already charged is `captured` only. Everything else returns nil.
- `PaymentLifecycleCard` takes a `variant` (default `.liveHold`) and draws steps 1 and 3 from it; step 2 and the pre-payment `PaymentInfoSheet` use are unchanged. Two new previews cover B and C.
- `BookingRequestSentViewModel.apply(_:)` publishes `paymentVariant`; the view renders the card only when it is non-nil, replacing the old `!isFree` test.
- 12 chooser tests and 7 view-model tests pass. Build succeeds with no warnings in the four app files (baseline was zero).

## Task Commits

1. **Task 1: Tracer, Request Sent's payment card matches the booking** - `bd011cf` (fix)
2. **Task 2: View model picks the variant from the loaded booking (stubbed detail)** - `819d858` (test)

Task 2 is test-only: Task 1 already wired `apply(_:)`, so the new suite passed on its first run.

## Files Created/Modified

- `ClickMe2026/Utils/PaymentLifecycleVariant.swift` - chooser, status set, per-variant copy and icons
- `ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift` - `PaymentLifecycleVariantTests` and `BookingRequestSentVariantTests`
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift` - variant input, two previews
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift` - `paymentVariant`, `previewSeed` parameter
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift` - renders from `paymentVariant`

## Decisions Made

See key-decisions. Mutually consistent with the plan's checker-review corrections: a held booking is never described as charged, and a booking that will not be charged is never told a charge is scheduled.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or schema; the chooser only reads fields already decoded from `GET /client/bookings/:id` (T-04-25 mitigated by the chooser and both test suites).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Device check (UI-SPEC D3, D-11 session) is logged in `.planning/WINDOWS.md` for 04-14. Variants B and C are reachable only for older long-lead rows or a booking converted to the T-24h charge, so they are covered by unit tests and previews only.
- Android: not on CONTEXT's Android list; none logged.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/PaymentLifecycleVariant.swift
- FOUND: ClickMe2026Tests/Utils/PaymentLifecycleVariantTests.swift
- FOUND commits: bd011cf, 819d858
- Acceptance criteria and both tasks' automated checks re-run and passing; plan-level verification (both suites non-zero, no new warnings) passing
