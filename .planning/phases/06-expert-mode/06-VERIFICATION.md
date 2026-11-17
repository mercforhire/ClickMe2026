---
phase: 06-expert-mode
verified: 2026-11-17T17:00:00Z
status: passed
score: 19/19 must-haves verified
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
  - ".planning/phases/06-expert-mode/06-11-PLAN.md"
  - ".planning/phases/06-expert-mode/06-11-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-12-PLAN.md"
  - ".planning/phases/06-expert-mode/06-12-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-13-PLAN.md"
  - ".planning/phases/06-expert-mode/06-13-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-14-PLAN.md"
  - ".planning/phases/06-expert-mode/06-14-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-15-PLAN.md"
  - ".planning/phases/06-expert-mode/06-15-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-16-PLAN.md"
  - ".planning/phases/06-expert-mode/06-16-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-17-PLAN.md"
  - ".planning/phases/06-expert-mode/06-17-SUMMARY.md"
  - ".planning/phases/06-expert-mode/06-18-PLAN.md"
  - ".planning/phases/06-expert-mode/06-18-SUMMARY.md"
  - "ClickMe2026/Model/BookingCalendarPayload.swift"
  - "ClickMe2026/Model/Responses/Children/ExpertTopicItem.swift"
  - "ClickMe2026/Utils/BookingCalendarEventContent.swift"
  - "ClickMe2026/Utils/ExpertBookingConfirmationContent.swift"
  - "ClickMe2026/Utils/TopicPriceRules.swift"
  - "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingAddToCalendarButton.swift"
  - "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift"
  - "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift"
  - "ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift"
covered_digest: "v3:sha256:a4fdeae2360bf3cad87ceaae593a48988e1c98b77258742e9dcfa972ae1de2b7"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 18/19
  gaps_closed:
    - "Truth 18 (sheet coexistence on the expert Booking Summary): was PRESENT_BEHAVIOR_UNVERIFIED; device re-check R4 passed on 2026-11-17, no blank flash seen"
    - "Review WR-01 (editor price seed vs selected currency): fixed in code by quick task 261117-1le (a87e963); the coincidental-reliance note on truth 16 is resolved"
    - "Human items 1 (R1 to R8) and 3 (review dispositions): all recorded as passed in 06-UAT.md"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "IN-08: other TopicEditorViewModel tests still rely on the shared UserManager having no /me"
    category: other
    reason: "Test-isolation hygiene from the 2026-11-17 re-review (06-REVIEW.md); no user impact, the full suite passes. Ledger disposition is open"
    evidence_status: "none provided"
---

# Phase 6: Expert Mode Verification Report

**Phase Goal:** Experts can price, describe and schedule their topics correctly and handle requests, bookings, clients and notes without wrong amounts or dead ends
**Verified:** 2026-11-17T17:00:00Z
**Status:** passed
**Re-verification:** Yes. The previous report went stale because quick task 261117-1le changed two covered files (`TopicEditorViewModel.swift`, `BookingCalendarEventContent.swift`). The report and the covered-input fingerprint are regenerated.

## Goal Achievement

I read the quick-task diff myself (`git diff e90c617 HEAD -- ClickMe2026`). It touches exactly two app files, and the claims about it hold:

- `BookingCalendarEventContent.swift` changed one doc comment (IN-03). No behavior change.
- `TopicEditorViewModel.swift`: `init` now resolves the currency once through `resolveInitialCurrency(topic:defaultCurrency: newTopicDefaultCurrency(in: me))`. The price seed (`editableAmount(minorUnits:currency:)`) and `self.currency` both use that one `resolvedCurrency` (lines 223-253). The old seed took the raw account default while `currency` took the resolved default, and that mismatch was WR-01. A `meProvider` seam (defaults to a live read of `userManager.me`) now feeds `defaultCurrency`, `allowedCurrencies`, the floor check in `validate()`, `isBelowFloor` and `minPriceHint`. A grep of the file finds no `userManager.me` read outside that default closure.

Test evidence I ran myself:

- `xcodebuild test` on iPhone 17, with `-only-testing` for `TopicCurrencyTests`, `TopicsSetupTopicCardLabelTests`, `TopicsSetupMutationTests`, `BookingCalendarEventContentTests` and `TopicPriceRulesTests`: **73 tests in 5 suites passed, TEST SUCCEEDED**. This includes the new WR-01 regression rows (`TopicCurrencyTests.swift:294`).
- The orchestrator's full-suite log (`06-regression-full.log`, 11:04 today) reads `✔ Test run with 997 tests in 95 suites passed` and `** TEST SUCCEEDED **`, with zero `✘` lines. The working tree has no app or test change since that run beyond the already-dirty `Localizable.xcstrings`, which predates this phase.

### Observable Truths

Roadmap success criteria 1 to 5 are split per requirement (truths 1 to 15), plus four gap-closure truths (16 to 19).

| #  | Truth | Status | Evidence |
| -- | ----- | ------ | -------- |
| 1  | EXP-02: a topic price takes decimals in the topic's currency and saves exact minor units | VERIFIED | `TopicPriceRules` integer parse; `TopicPriceRulesTests` pass in my run. Device item 1 PASS (2026-11-16). WR-03 (grouped paste) was accepted by the user |
| 2  | EXP-03 and EXP-17: editing keeps the topic's currency; CAD or USD can be picked on iOS and Android | VERIFIED | `resolveInitialCurrency`, `isCurrencyLocked`, segmented picker; Android `da498620` and `TopicCurrencyPicker.kt`. Device items 2 to 7, 32 PASS |
| 3  | EXP-04: icon and description can be cleared | VERIFIED | Three-state `NullableField`. Device item 8 PASS on a paid topic; the free-topic case is R3, PASS (2026-11-17) |
| 4  | EXP-01 and EXP-08: delete asks first; stale 409 comment gone | VERIFIED | `TopicsSetupMutationTests` pass in my run. Delete only reaches `deleteTopic` through the alert |
| 5  | EXP-05: Cancel on the time-range picker reverts | VERIFIED | Draft state in `TimeRangePickerSheet`. Device item 10 PASS. Glass readability item 13 deferred with a reason (see Deferred Items) |
| 6  | EXP-06: no end time the picker can't show | VERIFIED | `AvailabilitySlotRules.addHours` caps at 23:30; `AvailabilitySlotRulesTests` pass in the orchestrator's full run |
| 7  | EXP-07: an off-grid stored time shows as selected | VERIFIED | `pickerRows` merges the stored value; unit tests pass. Device item 12 had no such slot; the user accepted the unit tests as the evidence on 2026-11-17 (06-UAT test 9) |
| 8  | EXP-09: Accept shows the booking-confirmed screen | VERIFIED | `RequestDecisionAcceptTests` pass in the full run. Device items 14, 15, 19 PASS. Glass chevron item 16 deferred with a reason |
| 9  | EXP-10: the calendar event is titled with the client's name | VERIFIED | `BookingCalendarEventContent.title` (`ClickMe · {topic} with {client}`); `BookingCalendarEventContentTests` pass in my run. Device item 17 PASS, R6 PASS |
| 10 | EXP-12: expired request cards stay readable | VERIFIED | Whole-card dim removed; only the avatar keeps its opacity. Device items 21, 22 PASS; item 35 KEEP |
| 11 | EXP-14: Client Profile earnings in the booking currency | VERIFIED | `ClientProfileHistoryEarningsTests` pass in the full run. Device item 24 PASS |
| 12 | EXP-15: hub online dot real or removed | VERIFIED | `isOnline` removed from the profile view model. Device item 23 PASS; item 34 KEEP |
| 13 | EXP-16: note cap, counter, whitespace-only saves empty | VERIFIED | `ExpertBookingNoteViewModelTests` pass in the full run. Device items 26, 27, 30, 31 PASS |
| 14 | EXP-16: leaving with unsaved edits asks first; swipe can't discard | VERIFIED | Device items 28, 29 PASS (behavioral evidence no test can give) |
| 15 | EXP-18: expert Booking Summary shows the booking ID | VERIFIED | `BookingShortIDTests` pass in the full run. Device item 25 PASS |
| 16 | G-06-1-currency (EXP-03, EXP-17): a free topic whose stored currency arrives as `""` opens on the default currency, shows no blank third segment, and saves with a 3-letter currency | VERIFIED | `TopicPriceRules.validCurrencyCode` feeds `ExpertTopicItem.storedCurrency`, which `resolveInitialCurrency`, `isCurrencyLocked` and `pickableCurrencies` read. After WR-01, the price seed and the selected currency use one resolved value (`TopicEditorViewModel.swift:231-253`), so the earlier undeclared-precondition note no longer applies. `TopicCurrencyTests` (blank-code fixture and the new seed-matches-currency rows) and `TopicsSetupMutationTests` pass in my run. Device R2 and R3 PASS (2026-11-17) |
| 17 | G-06-1-card-cents (EXP-02): a paid topic card reads the price with the currency's full minor digits and ` / session`; a free topic reads `Free` | VERIFIED | `TopicsSetupTopicCard.priceLabel(for:defaultCurrency:)` goes through `Money.format`; `TopicsSetupTopicCardLabelTests` pass in my run, including the `""` and `null` currency wire shapes. Device R1 PASS (2026-11-17) |
| 18 | G-06-1-summary-calendar (iOS, EXP-10): the expert Booking Summary and the client Upcoming Booking offer Add to Calendar for confirmed, pending_reschedule and in_progress bookings until the end, with the same event as Booking Confirmed; the expert summary's calendar and cancellation sheets work independently | VERIFIED | One builder and one offer rule feed three screens; `BookingCalendarEventContentTests` pass in my run. The sheet-coexistence invariant has no unit test, and R4 supplies the behavioral evidence: PASS on a real iPhone on 2026-11-17, with the explicit watch for a blank flash on dismissal and none reported (06-UAT test 4, WR-02 deferral reason). R5, R6, R8 PASS |
| 19 | G-06-1-summary-calendar (Android): Booking Summary and Upcoming Booking show Add to Calendar with the same gate and event | VERIFIED | Commit `69c4e159` exists in ClickMe_Android (confirmed in its log). Device R7 PASS (2026-11-17) on an Android build at or after that commit. The Gradle unit tests were not re-run by this verification |

**Score:** 19/19 truths verified, 0 present-but-behavior-unverified.

### Deferred Items

Not scheduled in a later phase. Each was recorded by the user with a reason in `06-UAT.md` (test 9, `## Deferred Follow-Ups`) on 2026-11-17, so none leaves the phase unaccounted for.

| # | Item | Disposition | Reason recorded |
|---|------|-------------|-----------------|
| 1 | Device item 12 (09:15 and 24:00 slot edges, EXP-07) | Accepted on unit tests | `AvailabilitySlotRulesTests` accepted as the EXP-07 evidence |
| 2 | Device items 13 and 16 (two iOS 26 Liquid Glass readability checks) | Deferred | To be run on iOS 26 before Phase 8; recorded as unchecked, not as passed |
| 3 | A maximum topic price (bounds the accepted WR-03 paste) | Deferred | Follow-up in `06-UAT.md` |
| 4 | Review findings WR-02, IN-01, IN-02, IN-04, IN-05, IN-06 | Deferred | Reasons in `06-REVIEW-DISPOSITION.md`. WR-02 specifically: no blank flash was seen on device in R4 |

### Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | IN-08: other `TopicEditorViewModel` tests still rely on the shared `UserManager` having no `/me` | other | Test hygiene, no user impact, ledger disposition `open`; the full suite passes |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `Utils/TopicPriceRules.swift` `validCurrencyCode` | One stored-currency normalizer | VERIFIED | Used by `ExpertTopicItem`, the editor and the card |
| `Model/Responses/Children/ExpertTopicItem.swift` `storedCurrency` | Topic's own valid code | VERIFIED | Read by the editor |
| `Topic Editor/TopicEditorViewModel.swift` | Currency resolved once; `meProvider` seam | VERIFIED | Read in full; the `init` and every `/me` read checked |
| `Topics/Subviews/TopicsSetupTopicCard.swift` | `priceLabel(for:defaultCurrency:)` | VERIFIED | Wired through `newTopicDefaultCurrency` |
| `Utils/BookingCalendarEventContent.swift` | Shared builder and offer rule | VERIFIED | Used by 3 screens; doc comment fix only |
| `Model/BookingCalendarPayload.swift` | Plain event value | VERIFIED | Used by the sheet and 3 screens |
| `Confirmed/Subviews/CalendarEventEditorSheet.swift` | Sheet on the plain value | VERIFIED | Unchanged since the prior report |
| Expert Booking Summary view and view model | Gated button and sheet | VERIFIED | R4 PASS on device |
| Client Upcoming Booking view, view model, button | Client button | VERIFIED | R5, R8 PASS on device |
| Android `CalendarIntent.kt`, two screens, 3 test files | Android mirror | VERIFIED | Commit `69c4e159` present; R7 PASS |
| `06-DEVICE-UAT-CHECKLIST.md` | Every result filled | VERIFIED | Items 1 to 35 and R1 to R8 each carry a PASS, SKIPPED or KEEP line with a date; the skipped items 12, 13 and 16 carry "Deferred follow-up" reasons |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Editor `init` | `resolveInitialCurrency` and `newTopicDefaultCurrency` | one `resolvedCurrency` for seed and `currency` | WIRED | `TopicEditorViewModel.swift:231-253` |
| Editor `validate()` | `meProvider` then PATCH `hourlyRate.currency` | `currentMe`, `TopicsSetupViewModel.saveTopic` | WIRED | Floor check reads `currentMe` |
| `ExpertTopicItem.storedCurrency` | `TopicPriceRules.validCurrencyCode` | hourly rate code, then price code | WIRED | |
| `TopicsSetupTopicCard.priceLabel` | `Money.format`, `resolveInitialCurrency` | static helper | WIRED | Card and editor use the same two functions |
| Expert summary and client Upcoming buttons | `calendarEvent` then `CalendarEventEditorSheet(event:)` | `pendingCalendarEvent` | WIRED | |
| Summary and Upcoming view models | `BookingCalendarEventContent.isOffered` | `showsAddToCalendar(at:)` | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Topic card price | `hourlyRate?.amount ?? price.amount`, resolved currency | `GET /expert/topics` | Yes | FLOWING |
| Editor currency and price seed | `storedCurrency`, `me.pricingLimits` via `meProvider` | topic payload and `/me` | Yes | FLOWING |
| Expert summary event | client name, topic, schedule, note | booking detail | Yes | FLOWING |
| Client Upcoming event | topic, expert name, times, note | booking detail | Yes | FLOWING |
| Decision screen expiry on push entry | `isExpired` | list row only | No | HOLLOW (earlier WR-01 of the first review, accepted by the user; unchanged) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Currency, card label, mutation, calendar content and price-rule suites | `xcodebuild test -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:` TopicCurrencyTests, TopicsSetupTopicCardLabelTests, TopicsSetupMutationTests, BookingCalendarEventContentTests, TopicPriceRulesTests | 73 tests in 5 suites passed, `TEST SUCCEEDED` | PASS |
| Full unit suite | Orchestrator log `06-regression-full.log`: `✔ Test run with 997 tests in 95 suites passed`, `** TEST SUCCEEDED **`, 0 `✘` lines (I read the log, I did not re-run the full suite) | 997 passed | PASS |
| No stray `userManager.me` read in the editor view model | `grep -n "userManager\." TopicEditorViewModel.swift` | Only the default closure and `expertProfile` reads | PASS |
| Android Gradle tests | not re-run | Commit read; device R7 PASS | SKIP |

### Probe Execution

SKIPPED. Phase 6 declares no probe scripts.

### Requirements Coverage

All 16 IDs in the phase requirement list appear in at least one PLAN `requirements:` field (06-10 lists all 16). `REQUIREMENTS.md` maps all 16 to Phase 6 and none is orphaned. EXP-11 and EXP-13 belong to Phase 3.

`REQUIREMENTS.md` still shows 12 of the 16 as `[ ]` / `Pending` (EXP-01, 04, 05, 06, 07, 08, 09, 12, 14, 15, 16, 18). This verification did not change the file. The orchestrator should tick them now that the phase is `passed`.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| EXP-01 | 06-02, 06-10 | Delete asks first | SATISFIED | Truth 4 |
| EXP-02 | 06-01, 06-12, 06-16 | Decimal price; cards show cents | SATISFIED | Truths 1, 17; R1 PASS |
| EXP-03 | 06-01, 06-11 | Editing keeps the currency | SATISFIED | Truths 2, 16; R2 PASS |
| EXP-04 | 06-02 | Clear icon or description | SATISFIED | Truth 3; R3 PASS |
| EXP-05 | 06-03 | Picker Cancel reverts | SATISFIED | Truth 5; glass check deferred |
| EXP-06 | 06-03 | No unshowable end time | SATISFIED | Truth 6 |
| EXP-07 | 06-03 | Off-grid time selected | SATISFIED | Truth 7; unit tests accepted by the user |
| EXP-08 | 06-02 | Stale comment fixed | SATISFIED | Truth 4 |
| EXP-09 | 06-04, 06-05 | Accept shows Confirmed | SATISFIED | Truth 8 |
| EXP-10 | 06-04, 06-13, 06-14, 06-15, 06-16, 06-18 | Calendar event titled with the client; Add to Calendar on summary screens | SATISFIED | Truths 9, 18, 19; R4 to R8 PASS |
| EXP-12 | 06-06 | Expired cards readable | SATISFIED | Truth 10 |
| EXP-14 | 06-08 | Earnings in booking currency | SATISFIED | Truth 11 |
| EXP-15 | 06-06 | Hub dot real or removed | SATISFIED | Truth 12 |
| EXP-16 | 06-07 | Note cap, whitespace, discard | SATISFIED | Truths 13, 14 |
| EXP-17 | 06-01, 06-09, 06-11, 06-16, 06-17 | CAD or USD on create | SATISFIED | Truths 2, 16; backend hardening skipped by the user (todo recorded) |
| EXP-18 | 06-08 | Expert Booking Summary ID | SATISFIED | Truth 15 |

### Anti-Patterns Found

No `TBD`, `FIXME` or `XXX` in the two files changed since the last report.

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `Request decision/RequestDecisionViewModel.swift` | 254 | `TODO:` on the View Profile action | Info | Pre-existing, not a Phase 6 stub |
| `ExpertBookingSummaryView.swift`, `UpcomingBookingView.swift` | 74-93 | `.sheet(isPresented:)` with an `if let` on the same optional (WR-02) | Warning | Deferred; no flash seen on device in R4 |
| `ExpertBookingConfirmationContent.swift` | 25-45 | Unused wrappers after the delegation refactor (IN-01) | Info | Dead code, deferred |
| Others | | IN-02, IN-04 to IN-06, IN-08 | Info | Maintainability; deferred, or open for IN-08 |

### Human Verification Required

None outstanding. The earlier items resolved as follows:

1. R1 to R8 on a real iPhone and an Android device: all PASS on 2026-11-17 (06-UAT tests 1 to 8; checklist R1 to R8 Result lines filled).
2. Items 12, 13, 16: recorded as skipped with "Deferred follow-up" reasons by the user (06-UAT test 9). Item 12 is accepted on unit tests. Items 13 and 16 stay unchecked until before Phase 8.
3. Review dispositions: recorded in `06-REVIEW-DISPOSITION.md` (3 fixed, 6 deferred with reasons, 1 new info finding open as an advisory). 06-UAT test 10 PASS.
4. Android Gradle tests: not independently reproduced here. Device check R7 passed on the commit, and the Android suite is not a Phase 6 must-have, so this is a note, not a hold.

06-SECURITY.md reports `threats_open: 0`.

### Gaps Summary

No gaps. All 19 truths hold in code. Behavioral evidence exists for the one truth that tests cannot reach (the two sheets on the expert Booking Summary, R4 on device). All 16 requirement IDs are covered and none is orphaned. The two glass checks (items 13 and 16) are not run on hardware. They are recorded as deferred by the user with a reason and a deadline (before Phase 8), and neither is a success criterion that blocks the goal. They are listed under Deferred Items so they are not lost.

---

_Verified: 2026-11-17T17:00:00Z_
_Verifier: Claude (gsd-verifier)_
