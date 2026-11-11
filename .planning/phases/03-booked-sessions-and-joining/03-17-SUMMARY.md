---
phase: 03-booked-sessions-and-joining
plan: 17
subsystem: ui
tags: [swiftui, cancellation, refund, toast, swift-testing, gap-closure]
gap_closure: true
gap_ids: [G-03-3-WR02]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: CancelToastMessage and ClientCancellationViewModel post-cancel toast (03-10)
provides:
  - Neutral zero-refund toast under the charged-refundable case, with no amount and no timing
  - Rows for the all-cases "no amount at zero" rule and the idempotent already-cancelled 200
  - 03-UI-SPEC toast table row C at 0 aligned with the code
  - WR-02 recorded as fixed in the review ledger
affects: [03-UAT item 3 (BOOK-08) device check, phase 03 verification]

actuals:
  tokens: 4000
  tasks: 2
  commits: 2
plan_head_before: 85133bd4d9625f7449149340ccb695fb3b95bd32
plan_head_after: 0b4c338434e6dface40aab1bd80eb630478ccd73

tech-stack:
  added: []
  patterns:
    - "Money statements in a post-action toast follow the server amount; a server 0 under a case chosen by the phone clock is worded neutrally"

key-files:
  created:
    - .planning/phases/03-booked-sessions-and-joining/03-17-SUMMARY.md
  modified:
    - ClickMe2026/Utils/CancelToastMessage.swift
    - ClickMe2026Tests/Utils/CancelToastMessageTests.swift
    - ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift
    - .planning/phases/03-booked-sessions-and-joining/03-UI-SPEC.md
    - .planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md
    - .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md

key-decisions:
  - "Every server refund_amount of 0 under .chargedRefundable reads 'Booking cancelled. Any refund due will follow our cancellation policy.' because the success body cannot distinguish clock skew, a retried refund (BACK-19) and the already-cancelled 200, and CLAUDE.md forbids branching on message"
  - "ClientCancellationViewModel.swift intentionally unchanged: the wording lives in CancelToastMessage and the view-model rows drive the real call site"

requirements-completed: [BOOK-08]

coverage:
  - id: D1
    description: "A server refund_amount 0 under .chargedRefundable shows the neutral policy line, naming no amount and no timing (no digits, no 'within', 'days', 'business')"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelToastMessageTests.swift#zeroChargedRefundable"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift#zeroRefundUsesConfirmedCase"
        status: pass
    human_judgment: false
  - id: D2
    description: "The idempotent already-cancelled 200 shows the same neutral line, posts it once and calls onConfirm once"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift#alreadyCancelledShowsNeutralLine"
        status: pass
    human_judgment: false
  - id: D3
    description: "A refund amount is named only above 0, and every other server-0 row is unchanged"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelToastMessageTests.swift#zeroNeverNamesARefundAmount, refundAboveZero, noRefundWordingIsExclusive, zeroLiveHold, zeroChargedNotRefundable, zeroNotCharged"
        status: pass
    human_judgment: false
  - id: D4
    description: "Normal-path toasts on a phone against real holds and refunds"
    requirement: BOOK-08
    verification: []
    human_judgment: true
    rationale: "Phase 3 UAT item 3 device check is still pending; the server-0 edge cannot be forced on a real captured booking without forfeiting the refund, so it rests on the unit rows"

duration: 8min
completed: 2026-11-11
status: complete
---

# Phase 3 Plan 17: Neutral post-cancel toast on a server refund of 0 Summary

**A cancel the server answers with `refund_amount` 0 on a booking the client confirmed as refundable now says "Any refund due will follow our cancellation policy." instead of naming the full amount as a refund in progress (WR-02, gap G-03-3-WR02).**

## Performance

- **Duration:** about 8 min
- **Tasks:** 2 of 2
- **Files modified:** 6 (1 app, 2 test, 3 planning docs)

## Accomplishments

- `CancelToastMessage` zero-refund `.chargedRefundable` arm no longer binds or names the amount. The above-0 branch and every other arm are unchanged. The type doc comment records why (phone clock vs server clock, retried refund, already-cancelled 200).
- `CancelToastMessageTests`: `zeroChargedRefundable` now pins the neutral line and asserts no "CA$", "processed" or "No refund". Per the plan-checker advisory it also asserts no digits and no "within", "days" or "business", so the BOOK-08 "no refund timing" rule is pinned. New `zeroNeverNamesARefundAmount` loops all six cases at 0.
- `ClientCancellationViewModelTests`: `zeroRefundUsesConfirmedCase` expects the neutral line; new `alreadyCancelledShowsNeutralLine` uses the exact backend body ("Booking is already cancelled.", refund_amount 0, CAD) and checks the toast, `cancelError == nil` and one `onConfirm`.
- `03-UI-SPEC.md` row `0 | C` carries the neutral line, with a sentence under the table explaining the rule.
- `03-REVIEW-DISPOSITION.md`: WR-02 fixed by 03-17, open count 11 to 10. `03-DEVICE-UAT-CHECKLIST.md` item 3 gained step 10 (Status and Result untouched).

## Task Commits

1. **Task 1 (tracer): neutral toast, tests, UI-SPEC** - `4cc7767`
2. **Task 2: ledger and checklist** - `0b4c338`

## Verification

- Tracer gate (auto mode): `CancelToastMessageTests` (9 tests) and `ClientCancellationViewModelTests` (10 tests) passed, and the grep gate exited 0, before the Task 2 expansion.
- Task 2 grep gate exits 0.
- Full unit suite: 440 tests in 48 suites passed (438 after 03-16, plus the two new rows).
- Build: `BUILD SUCCEEDED`. Warning baseline for `CancelToastMessage.swift` was 0 before and the `comm` comparison printed nothing after, so no new warnings.
- `git show --stat` for the Task 1 commit lists no change to `ClientCancellationViewModel.swift`, as intended.

## Deviations from Plan

None - plan executed exactly as written. The optional plan-checker advisory (no digits and no timing words in the neutral text) was added as extra assertions inside `zeroChargedRefundable`; this adds no new test function.

## Known Stubs

None.

## Threat Flags

None. T-03-30 is mitigated by the new rows; T-03-31 and T-03-SC-17 accepted as planned.

## Pending device check

Phase 3 UAT item 3 (BOOK-08) stays pending on a real iPhone. The normal-path toasts are unchanged. The neutral line appears only when the server returns 0 for a booking the confirm step showed as refundable. Do not change the phone clock to force it, because that forfeits the refund on a real captured booking.

## Cross-repo

No backend change and no Android change: Android already says plain "Booking cancelled" unless the server reports a refund above 0. `03-UAT.md` was not edited (the orchestrator or verify-work reconciles gaps).

## Self-Check: PASSED

- All six modified files exist; commits `4cc7767` and `0b4c338` are ancestors of HEAD.
- `git rev-list --count 85133bd4d962..HEAD` is 2 before this SUMMARY commit, matching `commits: 2`.
