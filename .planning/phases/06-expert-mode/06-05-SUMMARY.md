---
phase: 06-expert-mode
plan: 05
subsystem: ui
tags: [swift, swiftui, booking-request, navigation, swift-testing]

requires:
  - phase: 06-expert-mode
    provides: "06-04 ExpertBookingConfirmationContent.confirmation(...) and BookingConfirmedView(booking:onBackToHome:)"
provides:
  - "RequestDecisionViewModel.confirmation (set only after a 2xx accept), computed isAccepted, SubmitFailure with popsOnDismiss"
  - "Booking Confirmed hosted inside RequestDecisionView, with the nav-bar pins"
  - "Couldn't update request alert for every accept or decline error; 409 ALREADY_PROCESSED pops the screen"
  - "Accept message cap at 1,000 UTF-16 units with a counter from 800"
  - "EnvironmentValues.returnToDashboard and HomeShellExit.Action.backToHomeRoot, installed by HomeExpertView"
affects: [06-10 device UAT checklist (D6, U1, N1, N2, D2 Confirmed half)]

actuals:
  tokens: 4500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Confirmation hosted in the screen that created it (state switch in one transaction) instead of a path replace, so Back reaches the screen beneath"
    - "Alert content as an Identifiable value (SubmitFailure) so the OK action reads the presented failure and cannot lose it on dismissal order"

key-files:
  created:
    - ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift
  modified:
    - ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionViewModel.swift
    - ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionAcceptSheet.swift
    - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
    - ClickMe2026/Utils/HomeShellExit.swift
    - ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift
    - ClickMe2026Tests/Utils/HomeShellExitTests.swift

key-decisions:
  - "Booking Confirmed is hosted inside RequestDecisionView (user sign-off 2026-11-16), superseding 06-UI-SPEC section 3's HomeNavigationPath.replace(with:), which would make Confirmed the only path entry and skip Incoming Requests on Back"
  - "The nav-bar pins go on RequestDecisionView, because 06-UI-SPEC's claim that Request Decision already carries them is false at HEAD (0 pins)"
  - "returnToDashboard is a new environment entry, not the client shell's returnToHome, so client screens hosted in the expert shell do not change behavior"
  - "The 409 pop reads BookingErrorMapper.code(for:) == .alreadyProcessed only; a 409 SLOT_UNAVAILABLE does not pop"

patterns-established:
  - "HomeShellExit.Action.backToHomeRoot: reset the source tab and the home tab, show the home tab (unlike backToHome, the home stack is emptied too)"

requirements-completed: []
# EXP-09 left pending: requirements.ready-ids reports it blocked by plan 06-10.

coverage:
  - id: D1
    description: "A 2xx accept closes the sheet and sets the confirmation (client name and topic from the loaded request); before accept and after a 500 there is none"
    requirement: EXP-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#acceptSuccess"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#serverErrorLeavesUnconfirmed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Two Confirm taps while a request is in flight send exactly one POST /accept"
    requirement: EXP-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#concurrentConfirmSendsOnce"
        status: pass
    human_judgment: false
  - id: D3
    description: "409 ALREADY_PROCESSED on accept or decline sets a failure that pops on OK; any other error, including a 409 with another code, does not pop"
    requirement: EXP-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#acceptAlreadyProcessedPops"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#declineAlreadyProcessedPops"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#otherConflictCodeStays"
        status: pass
    human_judgment: false
  - id: D4
    description: "Accept message capped at 1,000 UTF-16 units on a character boundary; counter threshold at 800"
    requirement: EXP-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#capNeverSplitsACharacter"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift#counterThreshold"
        status: pass
    human_judgment: false
  - id: D5
    description: "Back to Home plan resets the source tab and the Dashboard and shows the Dashboard, for every expert tab"
    requirement: EXP-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/HomeShellExitTests.swift#expertBackToHomeRoot"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real iPhone: Confirmed replaces the decision screen with no Accepted frame, Back shows a refreshed Incoming Requests, Back to Home lands on the Dashboard root from every entry (N1, N2); the 409 alert and pop with two live accounts (D6); the 1,500-character paste and counter colour (U1); Confirmed back chevron in Light with Reduce Transparency and Liquid Glass Tinted (D2)"
    requirement: EXP-09
    verification: []
    human_judgment: true
    rationale: "Tab switching, stack popping, keyboard paste, a real cross-account 409 on production and glass rendering need hardware (device checks written by plan 06-10)"

plan_head_before: 39baa5a2e2e188a1c3a7a402e4c3d42c5ff3eb03
plan_head_after: 378ed961800d15cd8b2a11b8ce07f7d34a5ecb65

duration: 6min
completed: 2026-11-16
status: complete
---

# Phase 6 Plan 05: Accept lands on Booking Confirmed Summary

**Accepting a request now closes the sheet and swaps Request Decision for Booking Confirmed in one transaction (hosted inside the decision view), with a 409 ALREADY_PROCESSED alert that pops to a refreshed list, a 1,000-unit capped accept message with a counter, and a Back to Home that resets to the Dashboard root from any tab.**

## Performance

- **Duration:** about 6 min
- **Completed:** 2026-11-16
- **Tasks:** 3
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments
- `RequestDecisionViewModel` keeps the loaded `BookingRequestDetail` and sets `confirmation` through `ExpertBookingConfirmationContent.confirmation(...)` only after a 2xx accept; `isAccepted` is now `confirmation != nil`, so the footer and sheet guards compile unchanged. `guard !isSubmitting` is kept, so two Confirm taps send one POST.
- `RequestDecisionView` shows `BookingConfirmedView` in place of the decision content, titles the bar `Booking Confirmed`, and carries the three nav-bar pins. No `replace(with:)` is used.
- `SubmitFailure` (`message`, `popsOnDismiss`) replaces the string error. The `Couldn't update request` alert is shared by accept and decline; OK calls `dismiss()` only when the code was `ALREADY_PROCESSED`, read through `BookingErrorMapper.code(for:)`.
- The Accept sheet caps the message through `UTF16Prefix` at 1,000 units as typed and on paste, and shows `{n}/1000` from 800 units (muted, `Brand.error` at 1,000) with a VoiceOver label.
- `HomeShellExit.Action.backToHomeRoot` plus `EnvironmentValues.returnToDashboard`, installed by `HomeExpertView` only.

## Task Commits

1. **Task 1: Tracer, a successful Accept replaces Request Decision with Booking Confirmed** - `358e0d1` (feat)
2. **Task 2: 409 ALREADY_PROCESSED pops to the list, other errors stay, accept message capped at 1,000** - `bffa84a` (feat)
3. **Task 3: Back to Home on Booking Confirmed pops to the Dashboard root from any tab** - `378ed96` (feat)

## Verification
- `RequestDecisionAcceptTests`: "Test run with 11 tests in 1 suite passed" (4 after Task 1, 11 after Task 2).
- `HomeShellExitTests` + `HomeNavigationPathTests` in one run: "Test run with 23 tests in 2 suites passed". The new rows only add lines to `HomeShellExitTests.swift` (24 insertions, 0 deletions).
- Build gate after each task: BUILD SUCCEEDED; the warning baseline for the six app files was empty (`/tmp/06-05-warn-before.txt`) and stayed empty.
- Change gates: no `isAccepted = true`, no `Something went wrong`, no `submitError` in the two decision files, no `replace(with:)` in the view, and no `returnToDashboard` in `HomeClientView`: all pass.
- Tracer gate: the tracer's `<verify>` is automated-only and passed, so execution continued to Task 2 without a checkpoint.
- Backend check: `ALREADY_PROCESSED` (409) is thrown by both accept and decline in `bookingRequests.controller.js` (L314, L405) with message `This booking request has already been processed.`; `ErrorCode.alreadyProcessed` already exists on iOS. No backend change needed.

## Deviations from Plan

None - plan executed exactly as written. Two spec supersessions were planned and are recorded here as the plan required: (1) 06-UI-SPEC section 3's `HomeNavigationPath.replace(with:)` is replaced by in-view hosting (user sign-off 2026-11-16, 06-CONTEXT D-11 amendment); (2) 06-UI-SPEC's "Request Decision already carries the pins" is wrong at HEAD, so the pins were added to `RequestDecisionView`. 06-UI-SPEC.md itself is unedited.

## TDD note

Tasks 1 and 3 put the implementation and its tests in one commit each, and Task 2 likewise, as the plan's single-commit-per-task rules require; there is no separate RED commit. The plan's frontmatter `type` is `execute`, so no TDD Gate Compliance claim is made.

## Known Stubs

None.

## Threat Flags

None. T-06-07 (double accept) is mitigated by the kept `isSubmitting` guard and the 409 pop; T-06-08 by the 1,000-unit cap; T-06-09 by branching on the error code only (the SLOT_UNAVAILABLE row proves status alone does not pop).

## Issues Encountered

One test-compile error on first run: a static property read from a `@Sendable` stub closure needed `nonisolated`. Fixed in the same task before its commit.

## Next Phase Readiness

Ready for 06-06. Device checks D6, U1, N1, N2 and D2 (Confirmed half) are for plan 06-10's checklist. EXP-09 stays Pending in REQUIREMENTS.md (`requirements.ready-ids` reports it blocked by 06-10). One residual: a push-opened decision carries no `isExpired`, so an already-expired request shows Accept and the server answers 409, which the new alert handles (assumption Pitfall 10).

## Self-Check: PASSED

- FOUND: ClickMe2026Tests/ExpertMode/RequestDecisionAcceptTests.swift
- FOUND: 358e0d1, bffa84a, 378ed96 (ancestors of HEAD)
- Acceptance greps: `var isAccepted: Bool` 1, `guard !isSubmitting` 2, `acceptMessageLimit = 1000` 1
