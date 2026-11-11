---
phase: 03-booked-sessions-and-joining
plan: 03
subsystem: calls
tags: [swiftui, skype-zoom, meeting-call, copy, timer, overtime-banner]
status: complete

requires:
  - phase: 02-calls
    provides: "end + 55 overtime warning and end + 60 cutoff (CallOvertimePolicy, isOvertimeWarning)"
provides:
  - "MeetingCallViewModel.skypeStatusText (no auto-end promise, tested)"
  - "MeetingCallViewModel.endingBannerText (one banner string source for both layouts, tested)"
  - "Session timer and 'M:SS left' chip on the Skype/Zoom hero"
  - "End + 55 'This call will end in 5 minutes' notice on the Skype/Zoom layout"
affects: [03-UAT, android-parity]

actuals:
  tokens: 2263
  tasks: 3
  commits: 3
plan_head_before: 8f2a7da306e60f16b7322abe9466ba1b9a1907ab
plan_head_after: fd71b2543020e5cd8caf5e7eee767b3a982a7bb2

tech-stack:
  added: []
  patterns:
    - "Call-screen copy lives in MeetingCallViewModel so it can be unit tested; the view only renders it"

key-files:
  created:
    - ClickMe2026Tests/Calls/SkypeStatusTextTests.swift
  modified:
    - ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift
    - ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift
    - ClickMe2026/Views/Screens/Call/Calling/Subviews/SkypeSessionHero.swift

key-decisions:
  - "D-09: the Skype/Zoom status line never says or implies the meeting ends by itself; it tells the user to tap End Session"
  - "D-15: the Skype/Zoom layout reuses the voice layout's endingSoonBanner, gated on isOvertimeWarning only (supersedes UI-SPEC K2); the ending-soon and scheduled-time-complete states stay voice-only"

requirements-completed: [CALL-06, CALL-07]
---

# Phase 3 Plan 03: Skype/Zoom session copy, timer and end + 55 notice Summary

**The Skype/Zoom session screen now tells users to end the session themselves, shows the same timer as the in-app voice layout, and shows the amber "This call will end in 5 minutes" notice at end + 55, all from `MeetingCallViewModel`.**

## Accomplishments

- **CALL-06 (D-09):** `skypeStatusText` returns the three agreed strings ("Open the meeting link to start the session." / "Meeting in progress. Scheduled to finish at {end}. Tap End Session when you're done." / "Meeting in progress. Tap End Session when you're done."). The old copy that said the meeting "will end automatically" is gone from the view and the `scheduledEndLabel` doc. The text wraps (`fixedSize(horizontal: false, vertical: true)`).
- **CALL-07 (D-08):** `SkypeSessionHero` takes `timerString`, `remainingLabel` and `isNearOrPastEnd` and renders the timer exactly as `MeetingCallInfo` does (monospaced title2, amber near and after the end, plus the amber "M:SS left" capsule). `skypeCallContent` passes the same view model expressions the voice layout uses. A "Near the end" preview was added.
- **D-15:** `endingBannerText` holds the three banner strings, moved verbatim from the view, in the same precedence. `endingSoonBanner` reads it, the view's private `bannerText` is removed, and `skypeCallContent` shows the banner while `isOvertimeWarning` is true. The voice layout is unchanged. No timing change: `isOvertimeWarning` was already driven on the Skype branch by the per-second timer, and the end + 60 cutoff and `/end` reporting are untouched.

## Task Commits

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: Skype/Zoom status no longer promises an automatic end (CALL-06) | 55e6af8 |
| 2 | Skype/Zoom hero shows the session timer (CALL-07) | a10f291 |
| 3 | Skype/Zoom layout shows the end + 55 notice (D-15) | fd71b25 |

## Verification

- `SkypeStatusTextTests`: 7 tests in 1 suite passed (4 status-line tests, 3 banner tests).
- `CallOvertimePolicyTests` regression: 9 tests passed.
- Debug build for iPhone 17 simulator: BUILD SUCCEEDED. Warning comparison against the pre-edit baseline (0 warnings in the three touched app files) printed nothing, so no new warnings.
- Plan grep checks (auto-end copy removed, VM text read by the view, shared timer values passed, banner on the Skype layout, `bannerText` removed) all pass.

## Deviations from Plan

None. The plan was executed as written. One mechanical note: the first attempt to delete the view's private `bannerText` did not match because Task 1 had already changed the text after it; it was removed on the second attempt with the correct context.

## Deferred device checks (Phase 3 UAT)

Tracer device check deferred under the user's standing approval of 2026-11-10 ("approved, and defer all tracer device checks to UAT"). The Task 1 automated verification passed before expansion.

## Pending device checks

1. **CALL-06:** on a Skype/Zoom session, after tapping Open, the status reads "Meeting in progress. Scheduled to finish at {end}. Tap End Session when you're done."
2. **CALL-07:** open a Skype/Zoom session early; the hero reads "Starts in M:SS", counts up after the start, and turns amber with an "M:SS left" chip in the last 5 minutes.
3. **D-15:** keep a Skype/Zoom session open until 55 minutes after its scheduled end (or rejoin a completed one inside its reconnect tier just before then); the amber "This call will end in 5 minutes" notice appears at the top of the Skype screen, and the session ends at end + 60. The in-app voice banners read as before.
4. **L2:** at the largest accessibility Dynamic Type size, the Skype status line and timer block wrap and stay readable.

## Android follow-up (not built)

- Check Android's Skype/Zoom status copy for the same auto-end promise.
- Android's Skype/Zoom layout should show the same end + 55 notice.

## Requirements

CALL-06 and CALL-07 are fully delivered by this plan; no other Phase 3 plan lists them as requirements, so both are marked complete.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or trust-boundary changes. T-03-06 mitigated as planned (status line tells the user to tap End Session, timer turns amber, end + 55 notice shown, `/end` and the end + 60 cutoff unchanged).

## Self-Check: PASSED

- FOUND: ClickMe2026Tests/Calls/SkypeStatusTextTests.swift
- FOUND commits: 55e6af8, a10f291, fd71b25
