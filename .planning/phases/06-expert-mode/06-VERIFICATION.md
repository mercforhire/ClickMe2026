---
phase: 06-expert-mode
verified: 2026-11-17T13:30:00Z
status: human_needed
score: 18/19 must-haves verified
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
covered_digest: "v3:sha256:a0b2c3f61ceeb45adb97b41d1e94d30b46f5f82f17b2dd504967a27b7d0f5e8f"
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 14/15
  gaps_closed:
    - "G-06-1-currency: a free topic opens on CAD or USD in the editor and saves without error (code and unit-test level; device re-check R2, R3 pending)"
    - "G-06-1-card-cents: Topics tab cards show the price with two decimals (code and unit-test level; device re-check R1 pending)"
    - "G-06-1-summary-calendar: Add to Calendar on the expert Booking Summary, the client Upcoming Booking, and Android (code and unit-test level; device re-checks R4 to R8 pending)"
    - "Earlier WR-02 (blank stored currency) is now fixed in code, not accepted"
  gaps_remaining: []
  regressions: []
behavior_unverified_items:
  - truth: "The calendar sheet and the cancellation sheet on the expert Booking Summary each present and dismiss independently, and the New Event sheet opens right after the cancellation sheet closes (G-06-1-summary-calendar, plan 06-18)"
    test: "Re-check R4 on a real iPhone: open a confirmed future booking, open and close Confirm Cancellation with Keep Booking, add to calendar, then open Cancel again. Stop at Keep Booking, never confirm a cancellation on a live booking"
    expected: "Both sheets open and close every time, in either order, and the New Event sheet does not flash empty on swipe-down"
    why_human: "The two sheets sit on different presenters by design, but sheet presentation order and the dismissal animation are SwiftUI runtime behavior. No test exercises them. Review WR-02 flags a likely empty-content flash on dismissal that was not run"
coincidental_reliance_items:
  - truth: "A topic card and its editor show a paid topic that has no valid stored currency in the same currency (G-06-1-card-cents, G-06-1-currency)"
    reason: undeclared-precondition
    harden: "The editor seeds its price text from the raw account default (TopicEditorViewModel.swift:229-233) while its currency and the card use newTopicDefaultCurrency. They agree only because the backend default is always CAD and CAD is always allowed (backend pricing.js:61, 296). Resolve the currency once and use it for both the seed and currency (review WR-01)"
human_verification:
  - test: "Run the Gap closure re-check items R1 to R8 in 06-DEVICE-UAT-CHECKLIST.md on a real iPhone (build at or after 2a6c578) and an Android device (build at or after 69c4e159); every Result: line is blank today"
    expected: "R1: cards read CA$50.00 / session, CA$5.00 / session, CA$12.50 / session, US$5.00 / session and Free. R2 and R3: a free topic opens on CAD | USD with CAD selected, saves, and a cleared icon and description stick. R4: the expert Booking Summary of a confirmed future booking offers Add to Calendar and the Confirm Cancellation sheet still works. R5: the client Upcoming Booking offers it with the expert's name. R6: Booking Confirmed still adds the same event. R7: Android shows it on both screens. R8: the button goes when the session ends"
    why_human: "Definition of done needs a device check. These are the user-reported failures (checklist items 1, 4, 8, 17) and the fixes are tested only as logic. EventKit sheet, glass and Android intents need hardware"
  - test: "Checklist items 12, 13 and 16 were SKIPPED on 2026-11-16 (no 09:15 or 24:00 slot; two iOS 26 glass checks, no reason given)"
    expected: "Either run them or accept the unit tests (AvailabilitySlotRulesTests) as enough for EXP-07, and accept the glass checks as unchecked"
    why_human: "Device-only; EXP-05 readability under Reduce Transparency and the Confirmed chevron contrast on iOS 26 were never seen on hardware"
  - test: "Decide the open code-review findings in 06-REVIEW-DISPOSITION.md (all 9 are open): WR-01 seed currency vs selected currency, and WR-02 sheet(isPresented:) with an optional"
    expected: "A recorded disposition per finding. WR-01 is latent while the backend default is CAD. WR-02 is a likely dismissal flash that R4 will show"
    why_human: "Scope decision for the maintainer. Neither blocks the phase goal as written"
  - test: "Android Gradle tests for commit 69c4e159 were not re-run by this verification"
    expected: "Run the Android unit tests for CalendarIntentTest, ExpertBookingSummaryScreenTest and UpcomingBookingScreenTest before release"
    why_human: "The commit and wiring exist and were read, but the Android suite was not independently reproduced"
---

# Phase 6: Expert Mode Verification Report

**Phase Goal:** Experts can price, describe and schedule their topics correctly and handle requests, bookings, clients and notes without wrong amounts or dead ends
**Verified:** 2026-11-17T13:30:00Z
**Status:** human_needed
**Re-verification:** Yes, after gap-closure plans 06-11 to 06-18 (UAT 06 gaps G-06-1-currency, G-06-1-card-cents, G-06-1-summary-calendar)

## Goal Achievement

The code delivers the goal and all three UAT gaps are closed in code. I did not rely on SUMMARY.md. I read each gap-closure source file, confirmed no app or test file changed since the 994-test full-suite run (`git diff e90c617 HEAD -- ClickMe2026 ClickMe2026Tests` is empty), and ran 13 Phase 6 suites in two targeted `xcodebuild` invocations myself: 81 tests in 6 suites and 91 tests in 7 suites, both `TEST SUCCEEDED`.

The status is `human_needed`, not `passed`. The gap fixes are tested only as logic. The three failures the user hit on a phone (items 1, 4/8, 17) are re-checked by R1 to R8, and all eight Result lines are blank. Device-only items are reported as not done.

### Observable Truths

Roadmap success criteria 1 to 5 are split per requirement (truths 1 to 15, unchanged from the earlier report), plus four gap-closure truths (16 to 19).

| #  | Truth | Status | Evidence |
| -- | ----- | ------ | -------- |
| 1  | EXP-02: a topic price takes decimals in the topic's currency and saves exact minor units | VERIFIED | `TopicPriceRules` integer parse; `TopicPriceRulesTests` pass in this run. Device item 1 PASS on 2026-11-16. WR-03 (grouped paste) was accepted by the user |
| 2  | EXP-03 and EXP-17: editing keeps the topic's currency; CAD or USD can be picked on iOS and Android | VERIFIED | `resolveInitialCurrency` and `isCurrencyLocked` read `storedCurrency`; the segmented picker. Android `da498620` and `TopicCurrencyPicker.kt` exist. Device items 2 to 7, 32 PASS. The free-topic blank-currency hole that broke this on device is truth 16 |
| 3  | EXP-04: icon and description can be cleared | VERIFIED | Three-state `NullableField` (`ExpertTopicRequestBodyTests` pass in this run). Device item 8 PASS on a paid topic only; the free-topic case was blocked by the currency bug and is now R3 |
| 4  | EXP-01 and EXP-08: delete asks first; stale 409 comment gone | VERIFIED | Grep gate `Returns 409` = 0. Delete only reaches `deleteTopic` through the alert. `TopicsSetupMutationTests` pass |
| 5  | EXP-05: Cancel on the time-range picker reverts | VERIFIED | Draft state in `TimeRangePickerSheet`. Device item 10 PASS. The glass readability item 13 was SKIPPED |
| 6  | EXP-06: no end time the picker can't show | VERIFIED | `AvailabilitySlotRules.addHours` caps at 23:30; tests pass in this run |
| 7  | EXP-07: an off-grid stored time shows as selected | VERIFIED | `pickerRows` merges the stored value; tests pass. Device item 12 SKIPPED (no such slot), so logic-only evidence |
| 8  | EXP-09: Accept shows the booking-confirmed screen | VERIFIED | `RequestDecisionAcceptTests` pass in this run. Device items 14, 15, 19 PASS. Item 16 (glass chevron) SKIPPED |
| 9  | EXP-10: the calendar event is titled with the client's name | VERIFIED | Title is built by `BookingCalendarEventContent.title` (`ClickMe · {topic} with {client}`); Booking Confirmed goes through `expertEvent`. `ExpertBookingConfirmationContentTests` and `BookingCalendarEventContentTests` pass. Device item 17 PASS |
| 10 | EXP-12: expired request cards stay readable | VERIFIED | Whole-card dim removed; only the avatar keeps `.opacity(0.55)` (`IncomingRequestAvatar.swift:51`, not text). Device items 21, 22 PASS; item 35 KEEP: build 6 was a real problem |
| 11 | EXP-14: Client Profile earnings in the booking currency | VERIFIED | `ClientProfileHistoryEarningsTests` pass in this run. Device item 24 PASS |
| 12 | EXP-15: hub online dot real or removed | VERIFIED | `isOnline` gone from `ExpertProfileHomeViewModel` (grep 0). Device item 23 PASS |
| 13 | EXP-16: note cap, counter, whitespace-only saves empty | VERIFIED | `ExpertBookingNoteViewModelTests` pass in this run. Device items 26, 27, 30, 31 PASS |
| 14 | EXP-16: leaving with unsaved edits asks first; swipe can't discard | VERIFIED | Previously PRESENT_BEHAVIOR_UNVERIFIED. Device items 28 and 29 PASS on 2026-11-16 supply the behavioral evidence that no test could |
| 15 | EXP-18: expert Booking Summary shows the booking ID | VERIFIED | `BookingShortIDTests` pass in this run. Device item 25 PASS |
| 16 | G-06-1-currency (EXP-03, EXP-17): a free topic whose stored currency arrives as `""` opens on the default currency, shows no blank third segment, and saves with a 3-letter currency | VERIFIED (coincidental-reliance) | `TopicPriceRules.validCurrencyCode` (trim, exactly 3 ASCII letters, uppercase, else nil, `TopicPriceRules.swift:135`) feeds `ExpertTopicItem.storedCurrency`, which `resolveInitialCurrency`, `isCurrencyLocked` and `pickableCurrencies` all read. Grep gate: no `hourlyRate?.currency` read left in the editor folder (0). The PATCH sends `hourlyRate: .init(amount:, currency: currency)` (`TopicsSetupViewModel.swift:161,175`). `TopicCurrencyTests` (blank-code fixture at line 377) and `TopicsSetupMutationTests` pass. The paid-topic lock still holds on a real code. Backend untouched by design (06-17 skipped). Reliance note: see `coincidental_reliance_items`. Device R2 and R3 pending |
| 17 | G-06-1-card-cents (EXP-02): a paid topic card reads the price with the currency's full minor digits and ` / session`; a free topic reads `Free` | VERIFIED | `TopicsSetupTopicCard.priceLabel(for:defaultCurrency:)` formats `amount` through `Money.format` in the editor's resolved currency, keeps `US$` for USD, falls back to the server label only when no usable amount exists. `TopicsSetupTopicCardLabelTests` pass, including `"currency":""` and `"currency":null` wire-shape rows. Device R1 pending |
| 18 | G-06-1-summary-calendar (iOS, EXP-10): the expert Booking Summary and the client Upcoming Booking offer Add to Calendar for confirmed, pending_reschedule and in_progress bookings until the end, with the same event as Booking Confirmed, and the expert summary's calendar and cancellation sheets work independently | PRESENT_BEHAVIOR_UNVERIFIED | One builder (`BookingCalendarEventContent`) and one rule (`isOffered`) feed Booking Confirmed, `ExpertBookingSummaryViewModel.calendarEvent` and `UpcomingBookingViewModel.calendarEvent`. `CalendarEventEditorSheet` now takes a plain `BookingCalendarPayload`. Both views gate through a 60 s `TimelineView`. The client Session Summary (finished bookings) has no calendar sheet, as the diagnosis required. `BookingCalendarEventContentTests` and `UpcomingBookingViewModelTests` pass. Device R4 to R6, R8 pending |
| 19 | G-06-1-summary-calendar (Android): Booking Summary and Upcoming Booking show Add to Calendar with the same gate and event | VERIFIED (code only) | Commit `69c4e159` in ClickMe_Android. `isCalendarEventOffered`, `calendarEventSpec` (plain values) and `rememberCalendarInsertLauncher` exist in `CalendarIntent.kt` and are called from `ExpertBookingSummaryScreen.kt:440`, `UpcomingBookingScreen.kt:474` and Booking Confirmed. Gradle tests not re-run here. Device R7 pending |

**Truth 18:** the builder, offer rule, event content and wiring are verified by tests and code reading. The sheet-coexistence invariant on the expert Booking Summary (calendar and cancellation sheets on separate presenters) has no test, so the truth is present and wired but behavior-unverified. It is not counted in the score and is carried in `behavior_unverified_items` and Human Verification item 1 (R4).

**Score:** 18/19 truths verified (1 present, behavior-unverified, the sheet coexistence)

### Deferred Items

None. A maximum topic price (bounds the accepted WR-03 paste) is a recorded follow-up in `06-UAT.md` `## Deferred Follow-Ups`, not scheduled in a later phase.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `Utils/TopicPriceRules.swift` `validCurrencyCode` | One stored-currency normalizer | VERIFIED | Substantive, used by `ExpertTopicItem`, the editor and the card |
| `Model/Responses/Children/ExpertTopicItem.swift` `storedCurrency` | Topic's own valid code | VERIFIED | Read in 4 places in the editor |
| `Topic Editor/TopicEditorViewModel.swift` | Normalized seed, lock, picker | VERIFIED | WR-01 (seed text uses the raw default) is latent |
| `Topics/Subviews/TopicsSetupTopicCard.swift` | `priceLabel(for:defaultCurrency:)`, `cardSymbol(for:)` | VERIFIED | Wired through `newTopicDefaultCurrency` |
| `Utils/BookingCalendarEventContent.swift` | Shared builder and offer rule | VERIFIED | Used by 3 screens |
| `Model/BookingCalendarPayload.swift` | Plain event value | VERIFIED | Used by the sheet and 3 screens |
| `Confirmed/Subviews/CalendarEventEditorSheet.swift` | Sheet on the plain value | VERIFIED | `makeEvent` adds the 15-minute alert |
| `Booking Summary/ExpertBookingSummaryView.swift` and ViewModel | Gated button and sheet | VERIFIED | Cancellation sheet unchanged, calendar sheet on a separate presenter |
| `Upcoming Booking Details/…ViewModel`, `View`, `UpcomingBookingAddToCalendarButton.swift` | Client button | VERIFIED | Present and wired |
| Android `CalendarIntent.kt`, two screens, strings, 3 test files | Android mirror | VERIFIED (code only) | One commit, `69c4e159` |
| `06-DEVICE-UAT-CHECKLIST.md` R1 to R8 | Re-check items | VERIFIED (present) | 8 items, all Result blank |
| `.planning/todos/pending/2026-11-16-backend-null-topic-currency.md` | 06-17 outcome | VERIFIED | Records the user's `skip`; no backend change |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `ExpertTopicItem.storedCurrency` | `TopicPriceRules.validCurrencyCode` | hourly rate code then price code | WIRED | `ExpertTopicItem.swift:53-54` |
| Editor init, `isCurrencyLocked`, `pickableCurrencies` | `storedCurrency` / `validCurrencyCode` | direct | WIRED | lines 109, 173, 181, 230 |
| Editor `validate().currency` | PATCH `hourlyRate.currency` | `TopicsSetupViewModel.saveTopic` | WIRED | lines 161, 175 |
| `TopicsSetupTopicCard.priceLabel` | `Money.format` and `resolveInitialCurrency` | static helper | WIRED | card and editor use the same two functions |
| Expert summary button | `calendarEvent` then `CalendarEventEditorSheet(event:)` | `pendingCalendarEvent` | WIRED | `ExpertBookingSummaryView.swift:316-322, 74-84` |
| Client Upcoming button | same | same | WIRED | `UpcomingBookingView.swift:259-266, 85-93` |
| Summary and Upcoming view models | `BookingCalendarEventContent.isOffered` | `showsAddToCalendar(at:)` | WIRED | |
| `ExpertBookingConfirmationContent.confirmation` | `expertEvent` | `calendarPayload` | WIRED | line 102 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Topic card price | `hourlyRate?.amount ?? price.amount`, resolved currency | `GET /expert/topics` | Yes | FLOWING |
| Editor currency and price seed | `storedCurrency`, `me.pricingLimits` | topic payload and `/me` | Yes | FLOWING |
| Expert summary event | `detail.client.name`, topic, schedule, `preparationNotes.text` | `GET` booking detail | Yes | FLOWING |
| Client Upcoming event | `topic`, `expertName`, `startTime`, `endTime`, `preparationNote` | booking detail | Yes | FLOWING |
| Decision screen expiry on push entry | `isExpired` | list row only | No | HOLLOW (earlier WR-01, accepted by the user in 06-REVIEW-DISPOSITION) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Gap suites pass | `xcodebuild test … -only-testing:` TopicCurrencyTests, TopicsSetupTopicCardLabelTests, BookingCalendarEventContentTests, TopicsSetupMutationTests, TopicPriceRulesTests, RequestDecisionAcceptTests | 81 tests in 6 suites passed, `TEST SUCCEEDED` | PASS |
| Earlier suites not regressed | same, AvailabilitySlotRulesTests, ExpertBookingNoteViewModelTests, ExpertBookingConfirmationContentTests, ClientProfileHistoryEarningsTests, BookingShortIDTests, UpcomingBookingViewModelTests, ExpertTopicRequestBodyTests | 91 tests in 7 suites passed, `TEST SUCCEEDED` | PASS |
| No code change since the full-suite run | `git diff --stat e90c617 HEAD -- ClickMe2026 ClickMe2026Tests` | empty | PASS |
| Full suite (994 tests in 95 suites, 06-16) | not re-run | Claim stands on the empty diff above plus my 172 targeted tests | SKIP |
| Phase grep gates | `rateMajor` 0, `Returns 409` 0, `slot: $viewModel.schedule` 0, `replace(with:` in `RequestDecisionView` 0, `isOnline` in profile VM 0, `hourlyRate?.currency` in editor 0, `opacity(request.isExpired` 1 (avatar only, not text) | as listed | PASS |
| Android Gradle tests | not re-run | Commit and wiring read, suite not reproduced | SKIP |

### Probe Execution

SKIPPED. Phase 6 declares no probe scripts.

### Requirements Coverage

All 16 IDs from the phase requirement list appear in at least one PLAN `requirements:` field (06-10 lists all 16). `REQUIREMENTS.md` maps all 16 to Phase 6 and none is orphaned. EXP-11 and EXP-13 belong to Phase 3. The `REQUIREMENTS.md` boxes were not ticked by this verification (EXP-02, 03, 10, 17 are ticked there already; the other 12 are still `[ ]`). That is left to the orchestrator after the device pass.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| EXP-01 | 06-02, 06-10 | Delete asks first | SATISFIED | Truth 4 |
| EXP-02 | 06-01, 06-12, 06-16 | Decimal price; cards show cents | SATISFIED (device R1 pending) | Truths 1, 17 |
| EXP-03 | 06-01, 06-11 | Editing keeps the currency | SATISFIED (device R2 pending) | Truths 2, 16 |
| EXP-04 | 06-02 | Clear icon or description | SATISFIED (free-topic case R3 pending) | Truth 3 |
| EXP-05 | 06-03 | Picker Cancel reverts | SATISFIED | Truth 5 |
| EXP-06 | 06-03 | No unshowable end time | SATISFIED | Truth 6 |
| EXP-07 | 06-03 | Off-grid time selected | SATISFIED (logic only; device item 12 skipped) | Truth 7 |
| EXP-08 | 06-02 | Stale comment fixed | SATISFIED | Truth 4 |
| EXP-09 | 06-04, 06-05 | Accept shows Confirmed | SATISFIED | Truth 8 |
| EXP-10 | 06-04, 06-13, 06-14, 06-15, 06-18 | Calendar event titled with the client; Add to Calendar on summary screens | SATISFIED (device R4 to R8 pending) | Truths 9, 18, 19 |
| EXP-12 | 06-06 | Expired cards readable | SATISFIED | Truth 10 |
| EXP-14 | 06-08 | Earnings in booking currency | SATISFIED | Truth 11 |
| EXP-15 | 06-06 | Hub dot real or removed | SATISFIED | Truth 12 |
| EXP-16 | 06-07 | Note cap, whitespace, discard | SATISFIED | Truths 13, 14 |
| EXP-17 | 06-01, 06-09, 06-11, 06-17 | CAD or USD on create | SATISFIED (device R2 pending; backend hardening skipped by user) | Truths 2, 16 |
| EXP-18 | 06-08 | Expert Booking Summary ID | SATISFIED | Truth 15 |

### Anti-Patterns Found

No `TBD`, `FIXME` or `XXX` in any of the 53 Swift files changed since `59da049`.

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `Request decision/RequestDecisionViewModel.swift` | 254 | `TODO:` on the View Profile action | Info | Pre-existing, not a Phase 6 stub |
| `Topic Editor/TopicEditorViewModel.swift` | 229-233 | Price seed uses the raw account default, while `currency` and the card use the resolved default (review WR-01) | Warning | Latent: backend default is always CAD and CAD is always allowed. Disposition open |
| `ExpertBookingSummaryView.swift`, `UpcomingBookingView.swift` | 74-84, 85-93 | `.sheet(isPresented:)` with an `if let` on the same optional (review WR-02) | Warning | Likely empty flash on dismissal; R4 will show it. Disposition open |
| `ExpertBookingConfirmationContent.swift` | 25-45 | Unused wrappers after the delegation refactor (IN-01) | Info | Dead code |
| Others | | IN-02 to IN-07 | Info | Maintainability; all open |

### Human Verification Required

#### 1. Gap closure re-check R1 to R8

**Test:** Run `.planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md` section "Gap closure re-check" on an iPhone build at or after `2a6c578` and an Android build at or after `69c4e159`. R4 must stop at Keep Booking.
**Expected:** Every Result filled, PASS. R1 cards read `CA$50.00 / session` and so on. R2 and R3 a free topic opens on CAD | USD with CAD selected, saves, and a cleared icon and description stick. R4 to R6 and R8 the iOS calendar behavior. R7 Android.
**Why human:** The user reported these failures on a device. The fixes pass as logic tests; the EventKit sheet, the two-sheet presentation and the Android intent need hardware. All eight Result lines are blank.

#### 2. Items skipped on 2026-11-16

**Test:** Checklist items 12 (a 09:15 or 24:00 slot), 13 (Availability Save under Reduce Transparency and Liquid Glass Tinted) and 16 (Confirmed chevron on iOS 26).
**Expected:** PASS, or an explicit decision to accept the unit tests for EXP-07 and leave the two glass checks unseen.
**Why human:** Visual and device state.

#### 3. Review findings WR-01 and WR-02 (and the seven info items)

**Test:** Record fixed, accepted or deferred for each in `06-REVIEW-DISPOSITION.md`; all 9 are `open`.
**Expected:** A disposition each. WR-02 will be visible in R4. WR-01 is a latent price-seed mismatch if the allowed list ever drops CAD.
**Why human:** A scope call. Under the project's rule that payments come first, WR-01 is worth fixing while this code is fresh, but it does not break a success criterion today.

#### 4. Android unit tests

**Test:** Run the Android tests for commit `69c4e159` (CalendarIntentTest, ExpertBookingSummaryScreenTest, UpcomingBookingScreenTest).
**Expected:** Pass.
**Why human:** Not reproduced by this verification.

### Gaps Summary

No gaps block the goal. All 19 truths hold in code, the three UAT gaps are closed at the logic level, and every one of the 16 requirement IDs is covered. The phase stays at `human_needed` because the three defects the user hit on a phone are re-checked only by R1 to R8, which are empty, and because one presentation behavior (two sheets on the expert Booking Summary) has no test. The user's `skip` on the optional backend change (06-17) is recorded in a todo; production still sends `price.currency: ""` for NULL-currency free topics, and the iOS fix handles that shape, so R2 and R3 exercise the real wire format. One advisory note: the card and the editor agree on a no-currency paid topic only because the backend default is fixed at CAD (see `coincidental_reliance_items`).

---

_Verified: 2026-11-17T13:30:00Z_
_Verifier: Claude (gsd-verifier)_
