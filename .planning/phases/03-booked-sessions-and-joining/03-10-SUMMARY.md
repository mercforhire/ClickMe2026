---
phase: 03-booked-sessions-and-joining
plan: 10
subsystem: ui
tags: [swiftui, cancellation, toast, refund, swift-testing, utf16]

requires:
  - phase: 03-booked-sessions-and-joining (plan 03-01)
    provides: UTF16Prefix, ClientBookingFixtures, URLRequest.bodyDataForTest()/jsonBodyForTest()
  - phase: 03-booked-sessions-and-joining (plan 03-02)
    provides: CancelRefundPreview.Case, CancellationBooking.refundCase, the confirm-time recheck in ClientCancellationViewModel
  - phase: 03-booked-sessions-and-joining (plan 03-06)
    provides: ToastCenter (show(_:systemImage:), injectable displayDuration) hosted by the client shell
provides:
  - CancelBookingData and a typed cancelClientBooking returning SuccessDataResponse<CancelBookingData>
  - CancelToastMessage, the post-cancel toast copy chosen from the server refund_amount and the confirmed case
  - CancelReasonComposer, "label: comment" capped by UTF-16 length at character boundaries
  - 450-unit comment cap and n/450 counter on the cancel comment field
affects: [Phase 3 UAT checklist (03-12)]

actuals:
  tokens: 4300   # chars/4 over the added lines of the realized diff (17,375 chars)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Money wording chosen from the server's answer plus the case the client confirmed under; a server 0 is never read as no refund on its own"
    - "Producer posts to the shell-owned ToastCenter after the 2xx and before onConfirm pops"

key-files:
  created:
    - ClickMe2026/Model/Responses/CancelBookingData.swift
    - ClickMe2026/Utils/CancelToastMessage.swift
    - ClickMe2026/Utils/CancelReasonComposer.swift
    - ClickMe2026Tests/Utils/CancelToastMessageTests.swift
    - ClickMe2026Tests/Utils/CancelReasonComposerTests.swift
  modified:
    - ClickMe2026/Network/ClickMeAPI+Booking.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationCommentField.swift
    - ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift

key-decisions:
  - "The toast uses the booking's refundCase as last shown after the 03-02 recompute; an unloaded case falls back to the amount-unknown wording (plain 'Booking cancelled.')"
  - "The counter counts UTF-16 units as Android does, so an emoji can advance it by two; it has a spoken accessibility label ('n of 450 characters')"
  - "ClientCancellationViewModel takes toasts: ToastCenter = .shared on the runtime init; the preview init posts nothing"

patterns-established:
  - "Pure copy helper with a caseless nonisolated enum and exhaustive Swift Testing rows, same style as CancelRefundPreview"

requirements-completed: [BOOK-07, BOOK-08]

coverage:
  - id: D1
    description: "Post-cancel toast follows the server refund_amount: above 0 names the amount; 0 reads by confirmed case (free and unknown plain, hold being released, refund being processed, within 24 hours no refund applies, never charged); an unformattable amount falls back to plain"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelToastMessageTests.swift (refundAboveZero, zeroFreeAndUnknown, zeroLiveHold, zeroChargedRefundable, zeroChargedNotRefundable, zeroNotCharged, noRefundWordingIsExclusive, unformattableAmount)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A 200 with refund_amount 45 posts the refund toast and confirms once; a zero refund uses the confirmed case; a 409 shows the error, posts no toast and does not confirm"
    requirement: BOOK-08
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift (successPostsRefundToast, zeroRefundUsesConfirmedCase, failurePostsNoToast)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reason composition: label alone for a blank comment, 'label: comment' with the comment trimmed, comment capped at 450 units, longest reason 472, whole reason capped at 500, emoji never split"
    requirement: BOOK-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/CancelReasonComposerTests.swift (blankCommentSendsLabel, commentIsTrimmedAndJoined, capsAscii, capsEmojiWithoutSplitting, shortCommentUnchanged, longestReasonIs472, composedReasonCapped, composedReasonCapKeepsEmojiWhole)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The recorded cancel POST body carries reason 'Change of plans: running late', and the label alone for a blank comment"
    requirement: BOOK-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift (reasonBodyCarriesComment, reasonBodyLabelOnly)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Comment field cap and counter wiring, stale 'comment dropped' doc removed, cancelClientBooking no longer drops the response"
    requirement: BOOK-07
    verification:
      - kind: other
        ref: "grep checks: commentLimit in CancellationCommentField (1+), CancelReasonComposer.reason in the view model (1+), 'Comment is intentionally dropped' (0), SuccessMessageResponse cancel signature (0), SuccessDataResponse<CancelBookingData> (1)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Toast placement and wording across the pop on a real iPhone; counter stops at 450 with emoji; expert Booking Summary shows 'label: comment'; counter layout at the largest Dynamic Type size"
    requirement: BOOK-07
    verification: []
    human_judgment: true
    rationale: "SwiftUI placement, the real refund in the Payments list and what the expert sees need a device and two accounts; user deferred tracer device checks to Phase 3 UAT"

duration: 7min
completed: 2026-11-11
plan_head_before: 7569fa9b3188679862f07cb97fc9746e1d6f0d50
plan_head_after: a49b1fe282650d5fe6913898be0fe3f1eaa087e4
commits: 2
status: complete
---

# Phase 3 Plan 10: Cancel toast from the server's refund and the cancellation comment Summary

**After a client cancel the toast now says what the server did with the money (from `data.refund_amount` and the case confirmed under, never "no refund" for a bare 0), and the cancellation comment is sent as "label: comment", capped at 450 and 500 UTF-16 units without splitting a character.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-11-11T05:31Z, **Completed:** 2026-11-11T05:38Z
- **Tasks:** 2 of 2
- **Files modified:** 9 (5 created, 4 modified), 408 insertions and 10 deletions

## Accomplishments

- `cancelClientBooking(id:reason:)` returns `SuccessDataResponse<CancelBookingData>`; `refund_amount` is in major units and goes through `Money.format(major:currency:)`.
- `CancelToastMessage.text(serverRefundMajor:currency:confirmedCase:)` implements the UI-SPEC table. Only the charged-inside-24-hours case reads "No refund applies because the session was within 24 hours."; a test asserts no other case can produce that sentence.
- `ClientCancellationViewModel` posts the toast to the injected `ToastCenter` after the 2xx and before `onConfirm` pops. A failed cancel sets `cancelError`, posts nothing and does not confirm. The preview path posts nothing.
- `CancelReasonComposer` composes `"label: comment"` (comment trimmed, label alone when blank) and caps the reason at 500; the comment field caps input at 450 on a character boundary and shows a trailing `{n}/450` counter. The longest reason is 472 units.
- The stale "Comment is intentionally dropped" doc is replaced by the real behavior.

## Task Commits

1. **Task 1: Tracer, after a cancel the toast says what the server actually did with the money** - `8648644` (feat)
2. **Task 2: The cancellation comment is sent as "label: comment", capped safely** - `a49b1fe` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Model/Responses/CancelBookingData.swift` - typed cancel response (`refundAmount`, `currency`)
- `ClickMe2026/Network/ClickMeAPI+Booking.swift` - typed return and a doc on the 0 semantics
- `ClickMe2026/Utils/CancelToastMessage.swift` - post-cancel copy
- `ClickMe2026/Utils/CancelReasonComposer.swift` - reason composition and caps
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift` - injected `toasts`, composed reason, toast before pop
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationCommentField.swift` - 450 cap and counter
- `ClickMe2026Tests/Utils/CancelToastMessageTests.swift`, `ClickMe2026Tests/Utils/CancelReasonComposerTests.swift` - new suites (8 tests each)
- `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift` - five new rows (three toast, two body); suite is now 9 tests

## Decisions Made

- The toast reads the case the client last saw (`booking.refundCase`); when it is nil the wording is the plain "Booking cancelled." (amount-unknown fallback).
- The counter counts UTF-16 units to match the server and Android, with a spoken label so VoiceOver does not read "slash".
- Counter styling follows the plan: caption, regular weight, `CancellationBrand.onSurfaceVar`, trailing under the editor.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Warning baseline for the six app files was empty before and after, so there are no new warnings.

## Verification

- Tests: `CancelToastMessageTests` 8, `CancelReasonComposerTests` 8, `ClientCancellationViewModelTests` 9 (includes the 03-02 rows), `CancelRefundPreviewTests` 15 (regression). All pass.
- BUILD: `xcodebuild build` (Debug, iPhone 17) printed `BUILD SUCCEEDED`; the warning comparison printed nothing.
- Acceptance greps: `struct CancelBookingData` 1, `SuccessDataResponse<CancelBookingData>` 1, `You weren't charged.` 1, `enum CancelReasonComposer` 1.
- Tracer gate: the tracer's automated verify passed end to end and the device check was deferred under the standing approval of 2026-11-10; expansion (Task 2) went ahead.

## Known Stubs

None.

## Deferred device checks (Phase 3 UAT)

On a real iPhone, for the 03-12 checklist (the user deferred all tracer device checks to UAT):

1. **BOOK-08 / D-06:** cancel a held booking (toast "The {amount} hold on your card is being released."), a captured or T-24h-charged booking more than 24 hours out ("{amount} will be refunded to your card."), and one inside 24 hours ("No refund applies because the session was within 24 hours."). Compare each with the refund shown in the Payments list. The toast must survive the pop to My Bookings and sit above the tab bar.
2. **BOOK-07:** cancel with a comment containing emoji; the counter stops at 450 without cutting an emoji; the expert's Booking Summary for that booking shows "label: comment".
3. Counter and comment field at the largest accessibility Dynamic Type size.

Comment-visibility note for the user (threat T-03-19, accepted): the comment is stored (BACK-14) and shown to the expert on `GET /expert/bookings/{id}/summary`. The field label "Additional Comments (Optional)" is locked by the UI-SPEC and was not changed, so a client is not told the expert can read it. Flag this on the UAT item.

## Requirements

BOOK-07 is listed only by this plan in the phase (03-12 lists BOOK-12, BOOK-16 and BOOK-17), and it is fully delivered in code, so it is marked complete in REQUIREMENTS.md; the device check stays on the UAT list. BOOK-08 was already marked complete by 03-02 (the preview half) and is left checked; this plan finishes its confirmation half.

## Threat Flags

None. No new endpoint or trust boundary; the comment now reaches an existing endpoint field (T-03-18 mitigated by the caps, T-03-19 accepted and documented above).

## Cross-repo and follow-ups

No backend change. Android already sends "label: comment" with the same 450-unit cap, so there is no Android follow-up from this plan.

## Next Phase Readiness

Ready for the remaining Phase 3 plans. No blockers.

## Self-Check: PASSED

- FOUND: ClickMe2026/Model/Responses/CancelBookingData.swift
- FOUND: ClickMe2026/Utils/CancelToastMessage.swift
- FOUND: ClickMe2026/Utils/CancelReasonComposer.swift
- FOUND: ClickMe2026Tests/Utils/CancelToastMessageTests.swift
- FOUND: ClickMe2026Tests/Utils/CancelReasonComposerTests.swift
- FOUND: commit 8648644
- FOUND: commit a49b1fe

---
*Phase: 03-booked-sessions-and-joining*
*Completed: 2026-11-11*
