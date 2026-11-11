---
phase: 03-booked-sessions-and-joining
plan: 07
subsystem: ui
tags: [swiftui, booking-summary, review-gate, booking-id, decline-note, swift-testing]

requires:
  - phase: 03-booked-sessions-and-joining
    provides: "03-01 ClientBookingFixtures with extraFields; 03-13 BookingSummaryViewModel.refresh() and reviewContextJSON test helper; 03-14 BookingShortID"
provides:
  - Leave a Review on Booking Summary only for a completed booking with no review (BookingSummaryViewModel.showsLeaveReview)
  - The short booking ID line ("ID: #A1B2C3D4") as the last line of the Booking Summary topic section, selectable
  - DeclineNote and BookingSummaryDeclineNoteCard, the expert's decline reason and note on a declined booking
  - ClientBookingDetail.declineReasonCode and .declineReasonText
affects: [03-12 device UAT checklist (BOOK-17 and the decline note item), 03-15 Android ID line parity]

actuals:
  tokens: 4700   # chars/4 over the added lines of the realized diff (18,902 chars, app and test Swift only)
  tasks: 2
  commits: 2
plan_head_before: 2fafe6e05d9ca68adcd6e5b809a84dc3a2003d5e
plan_head_after: f6450457eee825511ddd98855ff9e5b31ddb2a07
commits: 2

tech-stack:
  added: []
  patterns:
    - "A server enum this build may not know is decoded as a raw String? and mapped in one pure helper that returns nil for anything unlisted, so the raw value is never shown"
    - "Expert-authored free text goes to Text(verbatim:) as a String value with fixedSize(horizontal: false, vertical: true), so it is neither parsed as Markdown nor truncated"

key-files:
  created:
    - ClickMe2026/Utils/DeclineNote.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryDeclineNoteCard.swift
    - ClickMe2026Tests/Utils/DeclineNoteTests.swift
  modified:
    - ClickMe2026/Model/Responses/ClientBookingDetail.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
    - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift
    - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift

key-decisions:
  - "showsLeaveReview is status == .completed && !hasSubmittedReview; status is nil until the detail loads, so nothing shows while the status is unknown"
  - "DeclineNote.make checks the raw status itself (only 'declined'), so a stray code or text on another status is never shown, even though the backend already nulls them"
  - "Code matching is exact: 'pricing' or 'PRICING ' map to no reason line"
  - "mapStatus and the Cancelled badge for a declined booking are untouched (UI-SPEC K1 dismissed by the user)"

patterns-established:
  - "Booking ID on every iOS screen goes through BookingShortID.label/short; no inline prefix(8) copy remains"

requirements-completed: [BOOK-20]

coverage:
  - id: D1
    description: "Leave a Review is offered only for a completed booking with no submitted review; cancelled, declined, missed and expired never offer it; it is hidden before the detail loads"
    requirement: BOOK-17
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#completedWithoutReviewOffersReview, completedWithReviewHidesReview, sessionThatDidNotHappenHidesReview, reviewHiddenBeforeLoad"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Booking Summary ID label is the shared BookingShortID format"
    requirement: BOOK-20
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#bookingIDLabelUsesSharedFormat"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/BookingShortIDTests.swift (3 tests, rerun)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every decline code maps to its UI-SPEC reason line; an unknown or null code shows no line and never the raw code; the card hides without a reason line or note, and for any status other than declined"
    requirement: BACK-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/DeclineNoteTests.swift#reasonLines, unknownCode, codeMatchIsExact, nothingToShow, unknownCodeBlankText, notDeclined, codeOnly, textOnly"
        status: pass
    human_judgment: false
  - id: D4
    description: "A 1000-character note is kept whole, markup stays literal, and the detail decodes the decline fields when present, null, unknown and absent"
    requirement: BACK-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/DeclineNoteTests.swift#longTextIsNotTruncated, markupIsLiteral, decodesPresent, decodesUnknownCode, decodesNull, decodesAbsent"
        status: pass
    human_judgment: false
  - id: D5
    description: "The view model exposes the decline note for a declined detail, none for a declined detail without fields or a cancelled detail, and keeps the Cancelled badge"
    requirement: BACK-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift#declinedDetailExposesNote, declinedWithoutNoteShowsNothing, cancelledShowsNoDeclineNote"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real iPhone: the ID line is selectable and matches Upcoming details, Leave a Review is absent on cancelled and missed sessions, and the DECLINE NOTE card wraps a long note in full without accent or amber"
    requirement: BOOK-17
    verification: []
    human_judgment: true
    rationale: "Text selection, layout and wrapping of a 1000-character note need a device; deferred to Phase 3 UAT by the user's standing approval of 2026-11-10"

duration: 7min
completed: 2026-11-11
status: complete
---

# Phase 3 Plan 07: Booking Summary review gate, booking ID and decline note Summary

**Booking Summary now offers Leave a Review only after a completed session, shows the booking ID in the shared `ID: #A1B2C3D4` format through `BookingShortID`, and shows a DECLINE NOTE card with the expert's mapped reason line and full plain-text note on a declined booking.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-11-11T05:15Z; **Completed:** about 2026-11-11T05:22Z
- **Tasks:** 2 of 2 (Task 1 tracer, Task 2 TDD)
- **Files:** 8 (3 created, 5 modified); 442 lines added, 2 removed

## Accomplishments

- `BookingSummaryViewModel.showsLeaveReview` is `status == .completed && !hasSubmittedReview`, and the view's leave-review button uses it as its only condition. A cancelled, declined, missed or expired booking never invites a review the server would refuse (BOOK-17). The feedback card for a submitted review is unchanged.
- `bookingIDLabel` is `BookingShortID.label(bookingId)` in the runtime init (preview default `ID: #A1B2C3D4`) and renders as the last line of the expert card's topic section after the price row: caption regular, `onSurfaceVariant`, 4 pt top padding, text selection on (BOOK-20). No inline copy of the ID rule was added.
- `ClientBookingDetail` decodes `decline_reason_code` and `decline_reason_text` as raw `String?`, so a code this build does not know never breaks decoding.
- `DeclineNote.make(status:code:text:)` returns a note only for status `declined` with a reason line or non-blank text. `reasonLine(for:)` holds the UI-SPEC mapping (UNAVAILABLE; OUTSIDE_EXPERTISE and OUT_OF_SCOPE; SCHEDULE_CONFLICT and CONFLICT; PRICING; OTHER) and returns nil for anything else.
- `BookingSummaryDeclineNoteCard` (header `DECLINE NOTE` with `text.bubble`, reason line semibold `onSurface`, note regular `onSurfaceVariant`, 8 pt spacing, 16 pt padding, `BookingSummaryGlassCardBackground`) is rendered between the expert card and My Note. The note is passed to `Text(verbatim:)` with `fixedSize(horizontal: false, vertical: true)`, so it neither parses Markdown nor truncates. Two previews added.
- Leave a Review and the decline note sit inside `loadedContent`, so neither shows while the detail loads (UI-SPEC S9).

## Task Commits

1. **Task 1: Tracer, Booking Summary shows the booking ID; review only for completed** - `95a10ff` (feat)
2. **Task 2: A declined booking shows the expert's decline note** - `f645045` (feat)

**Plan metadata:** the docs commit that follows this file.

## Decisions Made

- The reason-line mapping matches codes exactly (no trimming or case folding): the server sends fixed upper-case enum values, and anything else is treated as unknown rather than guessed.
- `DeclineNote` re-checks the status instead of trusting the backend's null-when-not-declined rule, so a future backend regression can never show a reschedule-decline note as a booking decline note.
- The Cancelled badge for a declined booking is kept as is (K1 dismissed).

## Deviations from Plan

### Auto-fixed Issues

None.

### Small additions

**1. [Scope note] Three view-model rows for the decline note in `BookingSummaryViewModelTests`**
- **Found during:** Task 2
- **Issue:** The plan's Task 2 file list has no test that `apply(detail:)` actually feeds `DeclineNote.make`; `DeclineNoteTests` covers the helper and the decode only.
- **Fix:** Added `declinedDetailExposesNote`, `declinedWithoutNoteShowsNothing` and `cancelledShowsNoDeclineNote` to the existing suite (a Task 1 file), and included that file in the Task 2 commit, so the commit has seven files instead of the planned six.
- **Commit:** `f645045`

**Total deviations:** 0 auto-fixed, 1 small test addition. **Impact:** test-only; no change to shipped behavior or scope.

## Issues Encountered

None. Task 2's tests were written before the implementation (compile-red) and the helper, fields, card and wiring followed in the same commit, since the plan specifies one commit for the task. Task 1's rows passed on first run because the production change is a one-line gate plus a label.

## Tracer gate

The tracer's `<verify>` carries automated checks and a device `<human-check>`. Under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT"), the device check is deferred and Task 2 proceeded. The automated verify (11 tests in `BookingSummaryViewModelTests`, `BookingShortIDTests` 3 tests, the three grep gates) passed on the committed tree before Task 2 began.

## Verification

- Task 1: `BookingSummaryViewModelTests` 11 tests in 1 suite passed (`/tmp/03-07-t1.log`); `BookingShortIDTests` 3 tests passed (`/tmp/03-07-t1b.log`). Greps: `if !viewModel.hasSubmittedReview` 0 (baseline 1), `showsLeaveReview` in the view 1 or more (baseline 0), `textSelection` in the expert card 1 or more (baseline 0), `BookingShortID.label` in the view model 1, `bookingIDLabel` in the view model 3.
- Task 2: `DeclineNoteTests` plus `BookingSummaryViewModelTests` 29 tests in 2 suites passed (`/tmp/03-07-t2.log`, copied to `/tmp/03-07-t2b.log`). Greps: `BookingSummaryDeclineNoteCard(` in the view 1, `let declineReasonCode: String?` 1, `struct DeclineNote` 1, `DECLINE NOTE` 1, `DeclineNote.make` in the view model 1.
- BUILD: `xcodebuild build` (Debug, iPhone 17) succeeded (`/tmp/03-07-build.log`). The warning baseline for the six touched app files was empty before and after, so the comparison prints nothing.

## Known Stubs

None. The preview init's `ID: #A1B2C3D4` is a display fixture for `#Preview`, as the plan specifies.

## Threat Flags

None. T-03-13 (decline note rendered with Markdown or links) is mitigated: the note is a `String` passed to `Text(verbatim:)`, wraps, is never interpolated into a literal, and the raw code is never displayed; `markupIsLiteral` pins the literal rendering. T-03-14 (selectable short ID) is accepted as planned. No new network, auth or file surface.

## Requirement status

- **BOOK-20** is complete: Android (03-15) and Upcoming details (03-14) were done, and this plan delivers the iOS Booking Summary half. Marked complete in REQUIREMENTS.md.
- **BOOK-17** is also declared by plan 03-12 (Leave a Review wiring on a push-opened summary and the device checklist), which has not finished. Its code half is delivered here, and the requirement is left open for 03-12.
- BACK-02 is not in this plan's `requirements`; its iOS half is delivered here and the requirement's status stays with its owning plan.

## Deferred device checks (Phase 3 UAT)

On a real iPhone, under the user's standing approval of 2026-11-10:

- **BOOK-17, BOOK-20:** open a completed past session without a review (Leave a Review shows; the ID line shows and can be selected), then a cancelled and a missed one (no Leave a Review). Compare the ID with Upcoming details for the same booking.
- **BACK-02 iOS:** have the expert decline a request with a reason and a long note (up to 1000 characters); on the client's Booking Summary the DECLINE NOTE card sits between the expert card and My Note, shows the reason line and the full note wrapped, uses neither accent nor amber, and the badge still reads Cancelled.

## Pending device checks

- Same items as above, listed here as the plan's output spec requires.

## Cross-repo and follow-ups

No backend change (the decline fields were already live) and no Android change in this plan. The Android ID line is 03-15 (done). Android decline-note display remains the existing Phase 1 follow-up in STATE.md under "Android follow-ups", not built here.

## Next Phase Readiness

Plan 03-12 can add the BOOK-17 and decline-note device items to the UAT checklist and close BOOK-17. No blockers.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/DeclineNote.swift, ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryDeclineNoteCard.swift, ClickMe2026Tests/Utils/DeclineNoteTests.swift
- FOUND: commits `95a10ff` and `f645045` are ancestors of HEAD; `git rev-list --count 2fafe6e..HEAD` = 2

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
