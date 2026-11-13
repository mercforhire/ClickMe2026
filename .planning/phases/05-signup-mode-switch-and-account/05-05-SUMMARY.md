---
phase: 05-signup-mode-switch-and-account
plan: 05
subsystem: settings
tags: [swiftui, notifications, feedback, support-contact, auto-save, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: no code dependency (wave 1)
provides:
  - NotificationSettingsViewModel snapshot dedupe (lastAppliedSnapshot) and an injectable autoSaveDebounce
  - FeedbackViewModel.minimumDetailsLength and meetsMinimumLength(_:) (trimmed UTF-16 count, 10 minimum)
  - SupportContact (nonisolated enum) holding the one support address and mailto URL
  - NotificationSettingsAutoSaveTests (4), FeedbackValidationTests (8 test runs incl. 5 arguments), SupportContactTests (3)
affects: [05-13 (verifier closes SET-02, ticks nothing), 05-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 5300
  tasks: 3
  commits: 3
plan_head_before: a19c02de5bc934dd891691112093eeea7d08c6c6
plan_head_after: f41420e60497cebf867a5b8eaecee12a80178490

tech-stack:
  added: []
  patterns:
    - "View model records the server-known state as a snapshot string; the view's change observer becomes a no-op when the toggles equal it"
    - "One nonisolated constants enum for a value both a MainActor view and a nonisolated notice type need"

key-files:
  created:
    - ClickMe2026/Utils/SupportContact.swift
    - ClickMe2026Tests/Settings/NotificationSettingsAutoSaveTests.swift
    - ClickMe2026Tests/Settings/FeedbackValidationTests.swift
    - ClickMe2026Tests/Utils/SupportContactTests.swift
  modified:
    - ClickMe2026/Views/Screens/Settings/Notifications/NotificationSettingsViewModel.swift
    - ClickMe2026/Views/Screens/Settings/Feedback/FeedbackViewModel.swift
    - ClickMe2026/Views/Screens/Settings/Feedback/Subviews/FeedbackDetailsField.swift
    - ClickMe2026/Views/Screens/Settings/Help/HelpView.swift
    - ClickMe2026/Utils/SuspensionNotice.swift

key-decisions:
  - "Feedback length is the trimmed text's UTF-16 count: the server's JavaScript string length and Android's String.length, so five emoji pass and four do not"
  - "scheduleAutoSave() cancels the pending save first, then returns when the toggles equal lastAppliedSnapshot; this also drops a flip-and-flip-back"
  - "SupportContact is nonisolated because SuspensionNotice is nonisolated and default actor isolation is MainActor"

requirements-completed: [SET-04, SET-05, SET-02]

coverage:
  - id: D1
    description: "Opening Notification preferences sends no PATCH, even when the server has a row turned off; a reload sends none either"
    requirement: "SET-04"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/NotificationSettingsAutoSaveTests.swift#loadSendsNothing, reloadSendsNothing"
        status: pass
    human_judgment: false
  - id: D2
    description: "One toggle flip sends exactly one PATCH after the debounce; an unchanged re-schedule sends no second; flip-and-flip-back sends none"
    requirement: "SET-04"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/NotificationSettingsAutoSaveTests.swift#oneFlipSendsOnePatch, flipAndFlipBackSendsNothing"
        status: pass
    human_judgment: false
  - id: D3
    description: "Feedback under 10 trimmed UTF-16 units sends no request, keeps the typed text and shows 'Please enter at least 10 characters.'; 10 sends once; the error clears only when long enough"
    requirement: "SET-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Settings/FeedbackValidationTests.swift#tooShortSendsNothing, tenCharactersSendsOnce, paddedTenCharactersSendsOnce, fourEmojiRefused, fiveEmojiAccepted, errorClearsOnlyWhenLongEnough, ruleBoundary, successClearsForm"
        status: pass
    human_judgment: false
  - id: D4
    description: "One support address constant shared by Help and the suspension notice; no other Swift file in ClickMe2026 spells it"
    requirement: "SET-02"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/SupportContactTests.swift#addressIsPinned, mailtoURLIsPinned, suspensionNoticeUsesIt"
        status: pass
      - kind: command
        ref: "grep -rln 'clickmeapp@uptrendinvestments.net' ClickMe2026 --include=*.swift prints only ClickMe2026/Utils/SupportContact.swift"
        status: pass
    human_judgment: false
  - id: D5
    description: "Help > Email Us opens the default mail app addressed to the support inbox on a real iPhone"
    requirement: "SET-02"
    human_judgment: true
    rationale: "Handing a mailto URL to the system mail client is not asserted by a unit test; belongs on the device UAT checklist (05-DEVICE-UAT-CHECKLIST.md, not yet written at this point in the phase)"

duration: 20 min
completed: 2026-11-13
status: complete
---

# Phase 05 Plan 05: Notification auto-save, feedback minimum, one support address Summary

**Opening Notification preferences no longer PATCHes (snapshot dedupe), Feedback refuses under 10 UTF-16 characters like the server does, and Help and the suspension notice share one `SupportContact` address.**

## Accomplishments

- **SET-04 (tracer, Task 1).** Applying the loaded preference rows changed `sections`, which tripped the view's `.onChange(of: autoSaveSnapshot)` and PATCHed whenever the server had a row off. `NotificationSettingsViewModel` now keeps `lastAppliedSnapshot`, set in `init`, at the end of `apply(preferences:)` and after a successful save (to the snapshot taken when that save started). `scheduleAutoSave()` cancels the pending task, then returns when the toggles equal it. The debounce is an init parameter (`autoSaveDebounce: UInt64 = 800_000_000`) so tests use 20 ms.
- **SET-05 (Task 2).** `FeedbackViewModel.meetsMinimumLength(_:)` trims whitespace and newlines and compares `utf16.count` with `minimumDetailsLength` (10). `submit()` shows the inline error and sends nothing below it, leaving `details` as typed; `detailsDidChange()` clears the error only once the text is long enough. The error line reads "Please enter at least 10 characters." The cleared-form-and-thanks behavior after a successful send is unchanged (P16.5 D-06), covered by `successClearsForm`.
- **SET-02 (Task 3).** `nonisolated enum SupportContact` holds `email` and `mailtoURL`. `HelpView.openSupportEmail()` builds from `SupportContact.mailtoURL`; `SuspensionNotice.message` interpolates `SupportContact.email` and is byte-for-byte unchanged. `SupportContactTests` pins both values.

## Task Commits

1. **Task 1 (tracer): opening notification preferences saves nothing** - `e44ef67` (fix)
2. **Task 2: feedback needs at least 10 characters** - `9190bbd` (fix)
3. **Task 3: one support address** - `f41420e` (refactor)

Metadata commit (SUMMARY, STATE, ROADMAP, REQUIREMENTS) follows this file.

## TDD notes

The plan prescribes one commit per task, so RED and GREEN share a commit.

- Task 1: RED was run and checked. With the debounce injectable but no snapshot guard, all four tests failed on the planned assertions (PATCH counts of 1, 2, 1, 1 against expected 0, 1, 0, 0). The tracer gate (re-run of `<verify>`, end-to-end) then passed before expansion: `Tracer verified end-to-end - expanding`.
- Task 2: tests and implementation were written together; no separate RED run was made. `ruleBoundary` references the new `meetsMinimumLength` API, so against the old code it fails to compile, which is the only RED observed. Treat the Task 2 RED evidence as weak.
- Task 3: tests and implementation together, no separate RED run (`SupportContact` did not exist, so the suite could not compile without it).

## Verification

| Check | Result |
|-------|--------|
| `NotificationSettingsAutoSaveTests` | 4 tests passed (`/tmp/05-05-t1.log`) |
| `FeedbackValidationTests` | 8 tests passed (`/tmp/05-05-t2.log`) |
| `SupportContactTests` | 3 tests passed (`/tmp/05-05-t3.log`) |
| Regression `SuspensionNoticeTests` (unchanged) | 4 tests passed (`/tmp/05-05-reg.log`) |
| Task 1 grep gate (`lastAppliedSnapshot` count 5, baseline 0; debounce init parameter present) | pass |
| Task 2 grep gate (`minimumDetailsLength`, new copy present, old copy absent; `utf16.count` count 1, baseline 0) | pass |
| Task 3 grep gate (address only in `SupportContact.swift`, Help uses `SupportContact.`, no `support@clickme`) | pass |
| Build gate, warnings in the six app files vs `/tmp/05-05-warn-before.txt` | BUILD SUCCEEDED; baseline 0 warnings, after 0 warnings (files touched before both builds so they recompiled) |

Not run: `LoginTests`, `AuthSmokeTests`, `SignupSmokeTests` (excluded by the plan's own command; they hit the network). The device check for SET-02 (Help > Email Us opens the mail app addressed to the support inbox) is not done here; `05-DEVICE-UAT-CHECKLIST.md` does not exist yet at this point in the phase.

## Deviations from Plan

None - plan executed exactly as written.

Small additions inside the plan's intent: the feedback suite also covers the padded-10 case, newline padding and `successClearsForm`.

## Issues Encountered

- `ClickMe2026/Localizable.xcstrings` carried pre-existing uncommitted edits before this run and is not staged by this plan. It still holds an entry for the old copy "Please describe your experience before submitting." (line ~1552) and has no entry for "Please enter at least 10 characters."; the string catalog is left for whoever owns those edits, since the literal in `FeedbackDetailsField` renders correctly in English either way.
- A first draft of the notification test built the GET body inside the `@Sendable` closure and failed Swift 6 isolation checks (`defaultSections` is MainActor); the body is now built outside the closure.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or schema. T-05-09 (preferences written without a user change) is mitigated by the snapshot guard with a test that seeds a server row off; T-05-11 (support mail to a wrong address) is mitigated by the single constant with an exact-value test and a grep gate; T-05-10 stays accepted (server `min(10)` remains authoritative).

## Next Phase Readiness

Plan 05-13 ticks nothing for SET-02; the verifier closes it. Add the SET-02 device check (Help > Email Us opens the default mail app addressed to `SupportContact.email`) to `05-DEVICE-UAT-CHECKLIST.md` when that file is created.

## Self-Check: PASSED

- Created files exist: `SupportContact.swift`, `NotificationSettingsAutoSaveTests.swift`, `FeedbackValidationTests.swift`, `SupportContactTests.swift`.
- Commits `e44ef67`, `9190bbd`, `f41420e` are ancestors of HEAD; measured count `a19c02d..HEAD` is 3.
- No unintended deletions in any task commit.
