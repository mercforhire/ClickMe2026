---
phase: 06-expert-mode
verified: 2026-11-16T19:10:00Z
status: human_needed
score: 14/15 must-haves verified
covered_files:
  - ".planning/phases/06-expert-mode/06-01-PLAN.md"
  - ".planning/phases/06-expert-mode/06-01-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-02-PLAN.md"
  - ".planning/phases/06-expert-mode/06-02-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-03-PLAN.md"
  - ".planning/phases/06-expert-mode/06-03-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-04-PLAN.md"
  - ".planning/phases/06-expert-mode/06-04-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-05-PLAN.md"
  - ".planning/phases/06-expert-mode/06-05-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-06-PLAN.md"
  - ".planning/phases/06-expert-mode/06-06-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-07-PLAN.md"
  - ".planning/phases/06-expert-mode/06-07-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-08-PLAN.md"
  - ".planning/phases/06-expert-mode/06-08-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-09-PLAN.md"
  - ".planning/phases/06-expert-mode/06-09-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-10-PLAN.md"
  - ".planning/phases/06-expert-mode/06-10-SUMMARY.md"
  - "ClickMe2026/Model/Requests/ExpertTopicRequest.swift"
  - "ClickMe2026/Network/ClickMeAPI+ExpertProfile.swift"
  - "ClickMe2026/Utils/AvailabilitySlotRules.swift"
  - "ClickMe2026/Utils/ExpertBookingConfirmationContent.swift"
  - "ClickMe2026/Utils/HomeShellExit.swift"
  - "ClickMe2026/Utils/TopicPriceRules.swift"
  - "ClickMe2026/Views/Extensions/HomeNavigationPath.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Availability/Subviews/AvailabilityDayRow.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Availability/Subviews/TimeRangePickerSheet.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/BookingConfirmedCard.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/BookingConfirmedHeadline.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestAvatar.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Request decision/Subviews/RequestDecisionAcceptSheet.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/TopicsSetupViewModel.swift"
covered_digest: "v3:sha256:d73d0b0a0938c8359c2e0127088ab9b1aea8893d6a23ce8d2988665d93a6ed33"
behavior_unverified: 1
overrides_applied: 0
behavior_unverified_items:
  - truth: "The private booking note asks before discarding unsaved edits, and a swipe can never discard them (EXP-16)"
    test: "On the Booking Note screen, type text, tap Back (expect Discard changes?), then try a left-edge swipe with and without edits, then leave the screen and confirm swipe-back works on the next screen"
    expected: "Back with edits asks; Back with no edits pops at once; the edge swipe never pops this screen; the previous screen's swipe-back is restored after leaving"
    why_human: "needsDiscardPrompt is unit-tested, but the alert, the UIKit pop-gesture disable and its restore on viewWillDisappear are gesture state that no test exercises (checklist items 28, 29)"
human_verification:
  - test: "Run the whole 06-DEVICE-UAT-CHECKLIST.md (35 items) on a real iPhone against build 9e95cf3 or later; every Result: line is blank today"
    expected: "Every item PASS, or KEEP/CHANGE for items 34 and 35"
    why_human: "Definition of done requires a device check via the UAT checklist. Swipe-back, keyboard, EventKit, Dynamic Type, glass, push and the cross-device 409 need hardware (items 1-35)"
  - test: "Accept a request, then confirm Booking Confirmed shows, Back reveals a refreshed list, and a second device that already cancelled the request produces the 409 alert and a pop (items 14, 15, 19)"
    expected: "No Accepted frame; the 409 message shows and the screen pops"
    why_human: "The VM decisions are unit-tested; the view swap and the alert-dismiss pop are SwiftUI behavior"
  - test: "Type or paste past the cap in the accept message (1,000) and the note (5,000), including an emoji across the boundary (items 20, 26, 31)"
    expected: "The editor shows the truncated text, not the extra character (review IN-05: the capped Binding may not re-render on an equal write)"
    why_human: "Review IN-05 is unconfirmed and depends on the SwiftUI release"
  - test: "Open the expired request card on App Store build 6, then on the new build (items 21, 22, 35)"
    expected: "Text is readable after the fix; decide whether EXP-12 was a real problem"
    why_human: "EXP-12 is a LIKELY item, and readability is a visual judgment"
  - test: "Decision: WR-01 (push-opened expired or settled request still shows Accept and Decline). Fix in Phase 6, defer to a follow-up, or accept"
    expected: "A recorded disposition in 06-REVIEW-DISPOSITION.md"
    why_human: "A fix needs an additive backend change (status and expires_at on getDetail) plus an Android check, so it is a cross-repo scope decision"
  - test: "Decision: WR-02 (a legacy free topic with a NULL stored currency opens on an empty currency and 422s on Save) and WR-03 (a pasted 12,000 becomes 12.00)"
    expected: "A recorded disposition for each; WR-03 touches a live price"
    why_human: "Both are small, but the project's priority is that payments are never wrong, so the maintainer should choose fix-now or accept"
---

# Phase 6: Expert Mode Verification Report

**Phase Goal:** Experts can price, describe and schedule their topics correctly and handle requests, bookings, clients and notes without wrong amounts or dead ends
**Verified:** 2026-11-16T19:10:00Z
**Status:** human_needed
**Re-verification:** No, initial verification

## Goal Achievement

The code delivers the phase goal. No truth failed, no artifact is a stub, and no debt markers were found. I did not rely on SUMMARY.md. I read each source file, ran the nine grep gates myself, and ran 10 Phase 6 test suites in one targeted `xcodebuild` (111 tests in 10 suites passed, `** TEST SUCCEEDED **`).

The phase cannot be called `passed`. The definition of done requires a device check on a real iPhone, and all 35 checklist results are blank. One truth (the note's discard prompt and swipe lock) depends on UIKit gesture behavior that no test covers. The code review also raised four warnings that bear on the phrase "without wrong amounts or dead ends", and they need a maintainer decision.

### Observable Truths

Roadmap success criteria 1 to 5 are split into per-requirement truths. No PLAN truth narrowed a roadmap criterion.

| #  | Truth | Status | Evidence |
| -- | ----- | ------ | -------- |
| 1  | EXP-02: a topic price accepts decimals (`12.50`, `12,50`, `.5`) in the topic's currency and saves exact minor units | VERIFIED | `TopicPriceRules.swift` is integer-only. `parseMinor` folds digits one at a time, rejects 3 fraction digits, and caps at 7 integer digits so it cannot trap. `TopicEditorView.swift:106` routes input through `updateRate`, and the keyboard is `.decimalPad` when the currency has fraction digits. An untouched save sends the stored amount (`validate()`, D-19). `TopicPriceRulesTests` passed. See WR-03 for a paste edge. |
| 2  | EXP-03 and EXP-17: editing keeps the topic's own currency, and a new topic can pick CAD or USD on iOS and Android | VERIFIED | iOS `resolveInitialCurrency` and `isCurrencyLocked` seed from the stored currency, never the account default. The picker is a segmented control, disabled on a paid topic. `currency` is sent on every save. Backend `ALLOWED_TOPIC_CURRENCIES = ['CAD','USD']` and `/me` publishes `allowed_currencies`. Android commit `da498620` exists with `TopicCurrencyPicker.kt`, view-model changes and tests. `TopicCurrencyTests` passed. Edge cases: WR-02 (iOS) and a latent WR-04 (Android). |
| 3  | EXP-04: the icon and description can be cleared | VERIFIED | `NullableField.patch` sends JSON `null` for a cleared stored value, `omit` for unchanged. The backend schema has `.nullable().optional()` for both fields (`expertTopics.schema.js:130,134,151,155`). `ExpertTopicRequestBodyTests` passed. |
| 4  | EXP-01 and EXP-08: deleting a topic asks first, and the stale 409 comment is corrected | VERIFIED | The only call to `requestDelete` is the card menu (`TopicsSetupTopicCard.swift:47`). `deleteTopic` is reached only from `confirmDelete`, after the `Delete this topic?` alert. The "Returns 409" comment is gone (grep gate 0), and the backend `softDeleteTopic` has no conflict path. `TopicsSetupMutationTests` passed. |
| 5  | EXP-05: Cancel on the time-range picker reverts the change | VERIFIED | `TimeRangePickerSheet` edits a `@State draft`. Only Done calls `onDone`, which reaches `commitEditedSlot`. Cancel, swipe-down and tap-outside call `dismissTimePicker`, which writes nothing. `AvailabilitySlotRulesTests` passed. Device item 10. |
| 6  | EXP-06: availability never produces an end time the picker can't show | VERIFIED | `AvailabilitySlotRules.addHours` clamps the end to 23:30 and returns nil when the new start would be 23:00 or later. `AvailabilityDayRow` uses it, including for a stored 24:00 end. Picker rows never offer 24:00 as a new choice. |
| 7  | EXP-07: an off-grid stored time such as 09:15 shows as selected | VERIFIED | `pickerRows` merges `storedValue` (the value from when the sheet opened) into the list when it passes the draft test, sorted and de-duplicated. Tests passed. |
| 8  | EXP-09: accepting a request shows the booking-confirmed screen | VERIFIED | `confirmAccept` sets `confirmation` and closes the sheet in one transaction. `RequestDecisionView` swaps its content for `BookingConfirmedView` when `confirmation` is set. A 409 `ALREADY_PROCESSED` sets `popsOnDismiss` from the error code only. The double-tap guard is tested. `RequestDecisionAcceptTests` passed. See WR-01 for the push-entry gap. |
| 9  | EXP-10: the calendar event is titled with the client's name | VERIFIED | `calendarTitle` is `ClickMe · {topic} with {client}`, with `Session` and `Client` fallbacks. `CalendarEventEditorSheet.swift:46` uses `booking.calendarTitle`. No `expertName` remains in the Confirmed folder (grep gate 0). `ExpertBookingConfirmationContentTests` passed. |
| 10 | EXP-12: expired request cards stay readable | VERIFIED (code) | The whole-card `opacity(request.isExpired ...)` is gone (gate 0). Expiry is shown by a badge, a border at 0.35 and a darker fill. Only the avatar keeps a 0.55 dim, and that is not text. EXP-12 is a LIKELY item; the device before and after is checklist items 21, 22 and 35. |
| 11 | EXP-14: Client Profile shows real earnings in the booking currency | VERIFIED | `mapBooking` uses `earnings_breakdown.net_amount` with the breakdown's own currency, gated by status, through `Money.format`. A missing amount or currency shows a dash, never a made-up `$0`. `ClientProfileHistoryEarningsTests` passed, including a mixed CAD and USD case. This surface came from Phase 2 plan 02-15. 06-08 added no app code. I found no other money surface on the screen. |
| 12 | EXP-15: the hub online dot reflects real presence, or is removed | VERIFIED | `isOnline` is deleted from `ExpertProfileHomeViewModel` (gate 0). The expert hub card and the self-preview pass `isOnline: false`. The client hub is untouched. |
| 13 | EXP-16 (cap, counter, whitespace): the note is capped at 5000 with a counter, whitespace-only saves as empty, other text is sent as typed | VERIFIED | `updateNote` cuts at 5000 UTF-16 units, matching the server's `z.string().max(5000)`. The counter shows from 4500 and turns red at 5000. `normalizedForSave` sends `""` for whitespace-only text, and the backend accepts `""`. Other text is sent untrimmed. `ExpertBookingNoteViewModelTests` passed. |
| 14 | EXP-16 (discard): leaving with unsaved edits asks first | PRESENT_BEHAVIOR_UNVERIFIED | The Back button, the `Discard changes?` alert, the always-on `BookingRequestSentPopGestureLock` and its restore on `viewWillDisappear` are all present and wired. `needsDiscardPrompt` has unit tests, but nothing exercises the alert or the gesture lock and restore. Routed to human verification (items 28, 29). |
| 15 | EXP-18: the expert Booking Summary shows the booking ID | VERIFIED | `bookingIdLabel` is `BookingShortID.label(bookingId)`, rendered in the header (`ExpertBookingSummaryView.swift:378`). Android `expertShortBookingId` (drop hyphens, first 8, upper-case) gives the same string as iOS `prefix(8)` for a canonical UUID. `BookingShortIDTests` passed. |

**Score:** 14/15 truths verified (1 present, behavior-unverified)

### Deferred Items

None. Phase 7 (Chat) and Phase 8 (Release) do not cover any of the findings below.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `Utils/TopicPriceRules.swift` | Integer-only filter, parse and floor check | VERIFIED | Substantive and wired (`TopicEditorViewModel.updateRate`, `validate`, `isRateBelowMinimum`) |
| `Model/Requests/ExpertTopicRequest.swift` | Three-state `NullableField` PATCH | VERIFIED | Used by `TopicsSetupViewModel.saveTopic` |
| `Utils/AvailabilitySlotRules.swift` | Picker rows and Add hours rule | VERIFIED | Used by `TimeRangePickerSheet` and `AvailabilityDayRow` |
| `Utils/ExpertBookingConfirmationContent.swift` | Confirmed content and calendar title | VERIFIED | Called from `confirmAccept` |
| `Booking Note/ExpertBookingNoteViewModel.swift` and View | Cap, counter, normalize, discard prompt | VERIFIED | Wired; see truth 14 for the UIKit part |
| `Booking Summary/ExpertBookingSummaryViewModel.swift` | `bookingIdLabel` | VERIFIED | Rendered in the view |
| Android `TopicCurrencyPicker.kt` and related files (`da498620`) | CAD and USD picker | VERIFIED | Present, with 8 files changed and tests. I did not re-run the Gradle tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `TopicEditorView` price field | `TopicPriceRules.filterInput` | `viewModel.updateRate` | WIRED | Line 106 |
| `TopicEditorViewModel.validate` | `TopicPriceRules.parseMinor` and `isBelowFloor` | direct call | WIRED | Live hint and Save share one parse |
| `TopicsSetupTopicCard` Delete menu | `deleteMyTopic` | `requestDelete`, alert, `confirmDelete`, `deleteTopic` | WIRED | No path bypasses the alert |
| `AvailabilitySettingsView` sheet | `commitEditedSlot` (Done) and `dismissTimePicker` (Cancel) | closures | WIRED | Lines 79-80 |
| `RequestDecisionAcceptSheet` | `confirmAccept` then `confirmation` then `BookingConfirmedView` | closure and state | WIRED | |
| `BookingConfirmedView` | `CalendarEventEditorSheet` | `calendarTitle` and `calendarNotes` | WIRED | |
| Expert hub card | `ClientProfileHomeUserCard` | `isOnline: false` | WIRED | |
| `ExpertBookingNoteView` Back | discard alert | `needsDiscardPrompt` | WIRED | Runtime behavior unverified (truth 14) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Topic card price | `topic.price.label` | `GET /expert/topics` (`serializeTopic`) | Yes | FLOWING |
| Client Profile history amount | `earnings_breakdown.net_amount` and `currency` | bookings feed | Yes, status-gated | FLOWING |
| Booking Confirmed card | `detail.client.name`, `topic`, times | `GET /expert/booking-requests/:id` | Yes | FLOWING |
| Booking Summary ID | route `bookingId` | navigation value | Yes | FLOWING |
| Decision screen expiry | `isExpired` | list row only | No on the push route | HOLLOW for push entry (WR-01) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Phase 6 suites pass | `xcodebuild test ... -only-testing:` 10 suites (TopicPriceRules, AvailabilitySlotRules, ExpertTopicRequestBody, TopicCurrency, ExpertBookingNoteViewModel, ExpertBookingConfirmationContent, RequestDecisionAccept, TopicsSetupMutation, ClientProfileHistoryEarnings, BookingShortID) | 111 tests in 10 suites passed, `TEST SUCCEEDED` | PASS |
| Grep gates (`rateMajor`, stale 409 comment, `slot: $viewModel.schedule`, `replace(with:)` in `RequestDecisionView`, `opacity(request.isExpired`, `isOnline` in the profile VM) | grep | all 0 | PASS |
| Full-suite claim (952 tests, 93 suites) | not re-run | Not independently reproduced; the targeted run above covers every Phase 6 suite | SKIP |
| Android Gradle tests (49, 30 and 22) | not re-run | Not independently reproduced; the commit and files exist | SKIP |

### Probe Execution

SKIPPED. Phase 6 declares no probe scripts.

### Requirements Coverage

All 16 IDs in the phase's requirements list appear in at least one PLAN's `requirements:` field. `REQUIREMENTS.md` has them all mapped to Phase 6 as Pending, and no Phase 6 ID is orphaned. EXP-11 and EXP-13 are mapped to Phase 3 and are out of scope here.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| EXP-01 | 06-02 | Delete asks for confirmation | SATISFIED | Truth 4 |
| EXP-02 | 06-01 | Decimal topic price | SATISFIED (WR-03 edge) | Truth 1 |
| EXP-03 | 06-01 | Editing keeps the topic's currency | SATISFIED (WR-02 edge) | Truth 2 |
| EXP-04 | 06-02 | Clear icon or description | SATISFIED | Truth 3 |
| EXP-05 | 06-03 | Picker Cancel reverts | SATISFIED | Truth 5 |
| EXP-06 | 06-03 | No end time the picker can't show | SATISFIED | Truth 6 |
| EXP-07 | 06-03 | Off-grid stored time selected | SATISFIED | Truth 7 |
| EXP-08 | 06-02 | Stale 409 comment corrected | SATISFIED | Truth 4 |
| EXP-09 | 06-04, 06-05 | Accept shows Booking Confirmed | SATISFIED (WR-01 edge) | Truth 8 |
| EXP-10 | 06-04 | Calendar event titled with the client | SATISFIED | Truth 9 |
| EXP-12 | 06-06 | Expired cards readable | SATISFIED (device pending, LIKELY) | Truth 10 |
| EXP-14 | 06-08 | Client Profile earnings in booking currency | SATISFIED | Truth 11 |
| EXP-15 | 06-06 | Hub dot real or removed | SATISFIED | Truth 12 |
| EXP-16 | 06-07 | Note cap, counter, whitespace, discard | NEEDS HUMAN | Truths 13 and 14 |
| EXP-17 | 06-01, 06-09 | CAD or USD on create, iOS and Android | SATISFIED (WR-04 latent) | Truth 2 |
| EXP-18 | 06-08 | Expert Booking Summary ID | SATISFIED | Truth 15 |

I did not tick the `REQUIREMENTS.md` boxes. That is left to the orchestrator after the device pass.

### Anti-Patterns Found

No `TBD`, `FIXME` or `XXX` in any of the 32 Swift files changed since `59da049`, and no `TODO`, `HACK` or `PLACEHOLDER` either.

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `Request decision/Subviews/RequestDecisionActionFooter.swift` | 60 | Dead `Accepted!` copy, unreachable after the Confirmed swap | Info | Remove so it can't come back (UI review) |
| `Profile/ExpertProfileHomeScreen.swift` | 299 | Misindented `isOnline: false,` (IN-04) | Info | Formatting only |
| `AvailabilitySettingsView.swift`, `BookingConfirmedCard.swift`, `IncomingRequestAvatar.swift` | various | Hardcoded RGB values bypass `Brand` | Info | UI review pillar 3, no behavior impact |
| `RequestDecisionViewModel.swift` | 263-271 | New `DateFormatter` instances where `CLAUDE.md` says use `DateUtil` (IN-03) | Info | Style |

### Review Findings Weighed Against the Goal

The goal is "without wrong amounts or dead ends". I re-checked each warning in the code. None is a BLOCKER, because none of them breaks a roadmap success criterion as written. WR-01 and WR-03 get the most weight because each touches the goal's own wording.

| ID | Re-checked? | Verdict | Reasoning |
| -- | ----------- | ------- | --------- |
| WR-01 | Yes. `HomeExpertView.swift:337` builds `RequestDecisionView(requestId:)` with the default `isExpired: false`. `BookingRequestDetail` has no status or expiry field. | WARNING, decision needed | A push-opened expired or settled request shows Accept and Decline. The server is the guard: accept and decline compare-and-set on `status` and answer 409 `ALREADY_PROCESSED`, which the new D-12 path turns into a message and a pop. So there is no wrong charge and no stuck screen, only a wasted tap on the most common way to reach a request. The behavior predates Phase 6, and EXP-12 only asks that cards stay readable. The reviewer's caveat is worth a human look: backend `accept` checks `status` but not `expires_at`, so a request past its expiry and not yet swept can still be accepted. A real fix needs an additive backend change plus an Android check. |
| WR-02 | Yes. The backend returns `(price_currency \|\| '').toUpperCase()`, so a NULL stored currency arrives as `""`. `resolveInitialCurrency` keeps `""`. The code is identical to the pre-phase code at `59da049`. | WARNING | It is not a hard dead end. A free topic's currency is unlocked, so the expert can pick CAD or USD from the segmented control. But the picker shows an empty third segment, and a title-only edit sends `currency: ""` and gets a 422 on a topic the expert did not change. iOS always sends a currency on create, so this only affects topics created some other way. Production data was not checked. |
| WR-03 | Yes. `filterInput("12,000", "CAD")` returns `"12,00"`, which parses to 1200. | WARNING, decision needed | A pasted grouped number silently turns into a different price. The plan specified "a 3rd fraction digit is dropped" (Truth 2 edge text), and Android has the same rule, so the code matches its plan. A decimal-pad keyboard makes a typed grouped value unlikely, and the field does display `12,00` after the paste. But this is the one path in the phase where an expert could save a wrong paid amount without an error. Because the project puts payments first, I recommend a maintainer decision. |
| WR-04 | Yes. `TopicCurrencyPicker.kt:46` returns early below two currencies, and the USD notice is inside it. | WARNING, latent | The backend always publishes `['CAD','USD']` (`ALLOWED_TOPIC_CURRENCIES`), so no account can have a single-currency list today. It only matters if the allowlist ever shrinks. |

### Human Verification Required

#### 1. The 35-item device UAT checklist

**Test:** Run `.planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md` on a real iPhone (iOS 26 for the glass items) against a build at or after `9e95cf3`. Use test accounts, free topics only for accept and decline, and airplane mode for forced failures.
**Expected:** Every `Result:` line filled in. Today 33 are blank and 2 hold unfilled KEEP or CHANGE prompts.
**Why human:** The definition of done requires it. Hardware is needed for swipe-back, keyboard, EventKit, Dynamic Type, Liquid Glass, and the two-device 409.

#### 2. Note discard prompt and swipe lock (PRESENT_BEHAVIOR_UNVERIFIED)

**Test:** On the Booking Note screen, type, tap Back, try an edge swipe with and without edits, then leave and check swipe-back on the next screen.
**Expected:** Back with edits asks `Discard changes?`; with none it pops; the swipe never pops this screen; the gesture is restored afterwards.
**Why human:** The alert and the UIKit gesture state have no test (items 28, 29).

#### 3. Capped TextEditor display (review IN-05)

**Test:** Paste past 1,000 in the accept message and past 5,000 in the note, including an emoji on the boundary (items 20, 26, 31).
**Expected:** The editor shows the truncated text.
**Why human:** The capped Binding may not re-render on an equal write, and that varies by SwiftUI release.

#### 4. Expired card readability (EXP-12, LIKELY)

**Test:** Compare an expired card on App Store build 6 and on the new build (items 21, 22, 35).
**Expected:** The text reads clearly after the fix.
**Why human:** A visual judgment.

#### 5. Maintainer decisions on WR-01, WR-02 and WR-03

**Test:** Record fixed, accepted or deferred for each in `06-REVIEW-DISPOSITION.md`, which still lists all nine findings as `open`.
**Expected:** A disposition per finding. WR-01 needs a backend change and an Android check if fixed.
**Why human:** Scope and cross-repo risk. Fixing WR-03 before release avoids a possible wrong live price.

### Gaps Summary

There are no gaps that block the phase goal. The 15 truths hold in code, the targeted suites pass, and every requirement ID is covered. What stops a `passed` status is verification that code reading cannot supply: the 35-item device checklist (all results blank), one gesture-dependent truth, and three review warnings that need a disposition. If the maintainer decides WR-03 or WR-01 must be fixed, those would become `gaps_found` items for `/gsd-plan-phase --gaps`.

---

_Verified: 2026-11-16T19:10:00Z_
_Verifier: Claude (gsd-verifier)_
