---
phase: 08-release
plan: "07"
subsystem: chat
tags: [ios, swiftui, chat, booking-events, reasons, tdd]

requires:
  - phase: 08
    provides: "08-02 backend marker event_data.reschedule_decline; backend 94d659b reason_text / reason_by in chat event_data"
provides:
  - "iOS chat system-event rows show the reason or note given with a cancel, decline or reschedule proposal, labelled by who gave it"
  - "iOS reschedule-decline rows read 'Reschedule Declined' and are non-terminal"
  - "Request-decline rows fall back to decline_reason_text and add the DeclineNote label for a known decline_reason_code"
affects: [08-08, 08-21, ios-release]

actuals:
  tokens: 3200
  tasks: 2
  commits: 2

plan_head_before: c2143caa59bbef5672528f9c69e6940d5522619e
plan_head_after: a153d4cd8fd899682166802fc0c3ed36d10999a4
commits: 2

tech-stack:
  added: []
  patterns:
    - "Reason caption composed once in ChatItemMapper.bookingEvent from event_data; the row only renders plain strings with Text(verbatim:)"
    - "bookingEvent wraps baseBookingEvent: the base builds the display fields, the wrapper adds reason fields after construction"

key-files:
  created: []
  modified:
    - ClickMe2026/Utils/ChatItemMapper.swift
    - ClickMe2026/Model/UIModels/ChatDisplayModels.swift
    - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingSystemEventRow.swift
    - ClickMe2026Tests/Chat/ChatItemMapperTests.swift

key-decisions:
  - "Caption wording matches Android 08-03 exactly: 'Reason from the client|expert: <text>' / 'Reason: <text>' for cancelled and declined, 'Note from the client|expert: <text>' / 'Note: <text>' for a reschedule proposal"
  - "The role comes from reason_by only; an unknown reason_by uses the plain label, never the raw value. A request decline with no reason_by is labelled as the expert's"
  - "reason_text is trimmed; a blank reason_text falls through to decline_reason_text for a request decline only. A marked reschedule decline reads reason_text alone and gets no code label (the decline_reason_* columns are shared with request declines on the backend)"
  - "The marker is honored only on a BOOKING_DECLINED row and only as a literal boolean true"
  - "Captions are English literals in the mapper, not localized keys, like the existing titles; the text is rendered with Text(verbatim:) so it is never read as Markdown, a link or a localized key"

patterns-established:
  - "BookingEvent.reasonCaption / reasonCodeLabel are trailing optional vars so existing memberwise-init call sites (previews, ChatThreadReducerTests) compile unchanged"

requirements-completed: []

coverage:
  - id: D1
    description: "A cancel reason shows in the iOS chat labelled by reason_by (client, expert, unknown -> plain), trimmed; blank shows nothing; an event with none of the new keys maps as before"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Chat/ChatItemMapperTests.swift#cancelReasonIsLabelledByWhoGaveIt, blankReasonShowsNothing, eventWithoutReasonKeysIsUnchanged"
        status: pass
    human_judgment: false
  - id: D2
    description: "A reschedule proposal note reads 'Note from the client|expert: ...' or 'Note: ...'"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ChatItemMapperTests#rescheduleNoteIsLabelled"
        status: pass
    human_judgment: false
  - id: D3
    description: "A request decline uses reason_text ?? decline_reason_text as the expert's reason; a known decline_reason_code adds the DeclineNote label as its own line; an unknown code adds nothing and never the raw code"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ChatItemMapperTests#requestDeclineFallsBackToDeclineReasonText, declineCodeLabel"
        status: pass
    human_judgment: false
  - id: D4
    description: "reschedule_decline true makes a declined row read 'Reschedule Declined' and not terminal; without the marker it stays 'Booking Declined' and terminal"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ChatItemMapperTests#rescheduleDeclineMarker, declineWithoutMarker"
        status: pass
      - kind: other
        ref: "xcodebuild test -only-testing:ClickMe2026Tests: 'Test run with 1271 tests in 118 suites passed'; Debug build BUILD SUCCEEDED, no warning in the three touched app files"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real iPhone the reason lines wrap fully under the row title and read well next to the topic line, and reason text is shown as plain text (no link or Markdown rendering)"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "SwiftUI layout (wrapping, spacing, contrast) and the Text(verbatim:) rendering are not asserted by a unit test; it belongs to the device UAT checklist and the cross-platform regression run once the deployed backend sends the keys (08-08)."

duration: 20min
completed: 2026-11-22
status: complete
---

# Phase 08 Plan 07: iOS chat reasons Summary

**iOS chat rows now show who gave the reason or note for a cancel, decline or reschedule proposal, and a declined reschedule reads "Reschedule Declined" and stays non-terminal, matching Android 08-03.**

## Performance

- **Duration:** about 20 min
- **Tasks:** 2 (tracer, then TDD)
- **Files modified:** 4

## Accomplishments

- `BookingEvent` gained trailing `reasonCaption` and `reasonCodeLabel`; `ChatItemMapper.bookingEvent` reads `reason_text`, `reason_by`, `decline_reason_text`, `decline_reason_code` and `reschedule_decline` once and sets them after the base event is built.
- `ChattingSystemEventRow` renders the code label then the caption under the title and topic with `Text(verbatim:)`, caption style, unlimited wrapping and `fixedSize(horizontal: false, vertical: true)`.
- Reschedule declines get the title "Reschedule Declined" and `isTerminal == false` (the booking stays active, so a tap still routes to the upcoming-booking screen).

## Task Commits

1. **Task 1 (tracer): cancel reason under the chat row** - `4ada6e7` (feat), four files
2. **Task 2 (tdd): notes, request-decline fallback and code label, reschedule-decline marker** - `a153d4c` (feat), two files

TDD: the Task 2 behavior rows were written first and run red (7 expectation failures across the three new request-decline, code-label and marker tests), then the mapper was extended to green. The plan asks for one commit per task, so RED and GREEN are in the single Task 2 commit.

## Deviations from Plan

### Auto-fixed Issues

None needed beyond the plan.

### Notes

- Tracer gate: the Task 1 `<verify>` was re-run end to end (ChatItemMapperTests + ChatThreadReducerTests, 27 tests, passed) before expanding.
- Commits are on `main`; `git.allow_default_branch_commits: true` is set in `.planning/config.json`, so the protected-branch guard is overridden by config, as in the earlier plans of this phase.
- The commit trailer is `Co-Authored-By: Claude Sonnet 5.5`, the model that ran, per the session attribution rule.
- Localizable.xcstrings was not touched by this plan (its working-tree modification is unrelated and was left alone).

## Verification

- Full unit run: `Test run with 1271 tests in 118 suites passed`.
- Debug build: `BUILD SUCCEEDED`; no `warning:` line names ChatItemMapper.swift, ChatDisplayModels.swift, ChattingSystemEventRow.swift or the test file.
- `grep -c 'Reschedule Declined' ClickMe2026/Utils/ChatItemMapper.swift` is 1 (baseline 0).
- Threat mitigations: T-08-17 (Text(verbatim:), role from `reason_by` never the text) and T-08-18 (no print or log of reason text) are in place.

## Cross-repo

No backend or Android change in this plan. The Android half is 08-03 (already committed in ClickMe_Android); the backend keys come from 08-02 and `94d659b`, which must be deployed before the new rows show anything on a real device (event rows without the keys render exactly as before).

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ChatItemMapper.swift, ClickMe2026/Model/UIModels/ChatDisplayModels.swift, ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingSystemEventRow.swift, ClickMe2026Tests/Chat/ChatItemMapperTests.swift
- FOUND commits: 4ada6e7, a153d4c
