---
phase: "03"
slug: "booked-sessions-and-joining"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-10"
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests` |
| **Config file** | `ClickMe2026/AllTests.xctestplan` (new files auto-register through synchronized groups) |
| **Quick run command** | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| **Full suite command** | same command with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests -collect-test-diagnostics never` (the two smoke suites hit the live production backend and must never run). Last run 2026-11-22 (re-audit against current `main` at 34d41bb, after phases 04–08 and quick-261122-r2o): 1278 tests in 118 suites, all passed, 0 failures. Previous run 2026-11-11: 434 tests in 49 suites |
| **Backend command** | `npm test -- tests/expertBooking.test.js` (from `../ClickMe2026 Backend`; Supabase and Stripe are mocked, no production calls). Last run 2026-11-22: 162 tests passed |
| **Android command** | `./gradlew :app:testDevDebugUnitTest --tests '*BookingSummaryScreenTest'` (from `../ClickMe_Android`). Last run 2026-11-22: passed |
| **Build gate** | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`, with no new warnings in touched files |
| **Estimated runtime** | ~180 seconds per targeted run (simulator boot + build); suites run in milliseconds |

A run counts only if the output reports a non-zero test count (`Test run with [1-9]`). Suites that touch `MockURLProtocol` are `.serialized` and run one suite per `xcodebuild`.

---

## Sampling Rate

- **After every task commit:** Run the quick command for that task's suite
- **After every plan wave:** Run each suite touched in the wave (one `xcodebuild` per suite) plus the build gate
- **Before `/gsd-verify-work`:** All Phase 3 suites plus the Phase 2 regression suites (`JoinWindowTests`, `MoneyTests`, `ClientBookingStatusFallbackTests`, `ReloadGenerationTests`, `BookingErrorMapperTests`, `ExternalMeetingProviderTests`) green, no new warnings, device UAT checklist run
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

Requirement-to-suite map from `03-RESEARCH.md` § Validation Architecture, updated for the plan revision of 2026-11-10 (plans 03-13, 03-14 and 03-15 split out; D-15 and the expert 6-day cap added). The Plan column names the plan whose tasks create or extend each suite.

| Requirement | Behavior | Test Type | Suite (`-only-testing:ClickMe2026Tests/…`) | Plan | File Exists | Status |
|-------------|----------|-----------|---------------------------------------------|------|-------------|--------|
| BOOK-06 | Accept/decline reschedule, payment-method retry, decline note cap, refetch, double-tap guard | unit (stubbed API) | `RescheduleResponderTests` | 03-01 (toast rows 03-06) | ✅ | ✅ green |
| BOOK-06 | Proposal exposed only when expert-initiated; card gone after refetch | unit | `UpcomingBookingViewModelTests` | 03-01 (also extended by 03-13) | ✅ | ✅ green |
| BOOK-06 | Booking Summary accept through the shared responder; silent refresh keeps content | unit (stubbed API) + grep gate | `BookingSummaryViewModelTests` | 03-13 | ✅ | ✅ green |
| BOOK-07 | Cancel reason composition and 500 UTF-16 cap; request body carries `reason` | unit | `CancelReasonComposerTests`, `ClientCancellationViewModelTests` | 03-10 | ✅ | ✅ green |
| BOOK-08 | Refund preview cases A–F, 24 h boundary, second-tap rule, toast matrix | unit | `CancelRefundPreviewTests`, `CancelToastMessageTests`, `ClientCancellationViewModelTests` | 03-02, 03-10 | ✅ | ✅ green |
| BOOK-09 | Every `BookingStatus` case → pill text/tone from the shared decoder; raw string only for `.unknown`; no raw-string table | unit + grep gate | `BookingStatusPillTests`, `UpcomingBookingViewModelTests` | 03-14 | ✅ | ✅ green |
| BOOK-11 | Past empty state only when loaded and empty | unit | `MyBookingsEmptyStateTests` | 03-11 | ✅ | ✅ green |
| BOOK-12 | Keep Booking pops one level; `pop(_:)` depth | grep gate + unit + device | `UpcomingBookingViewModelTests` and `BookingSummaryViewModelTests` (push-opened, 03-12), `HomeNavigationPathTests` | 03-11, 03-12 | ✅ | ✅ green (logic); wiring is UAT item 6 |
| BOOK-13 | `canShowCancel` boundary at `end == now` | unit | `UpcomingActionPolicyTests` | 03-09 | ✅ | ✅ green |
| BOOK-16 | Availability GET carries `exclude_booking_id`; held copy; return with confirmation | unit + grep gate | `RescheduleAvailabilityTests` | 03-11, 03-12 | ✅ | ✅ green |
| BOOK-17 | Leave a Review only for `.completed` with no review | unit | `BookingSummaryViewModelTests` | 03-07 (created by 03-07; also 03-12) | ✅ | ✅ green |
| BOOK-20 | Short ID formatter; Summary ID label equals Upcoming label | unit | `BookingShortIDTests`, `BookingSummaryViewModelTests` | 03-14, 03-07 | ✅ | ✅ green |
| BOOK-20 (Android) | Android Booking Summary shows "ID: #…" for a short and a full-UUID id | Android unit (Gradle `:app:testDevDebugUnitTest --tests …BookingSummaryScreenTest`) | n/a (Android repo) | 03-15 | ✅ (BookingSummaryScreenTest.kt with the short-ID and full-UUID asserts) | ✅ green |
| BACK-02 (iOS) | Decline note card and reason labels | unit | `DeclineNoteTests` | 03-07 | ✅ | ✅ green |
| CALL-03 / CALL-08 | Upcoming join state per status/time/`canJoin`; provider label | unit | `UpcomingBookingViewModelTests`, `ExternalMeetingProviderTests` | 03-09 | ✅ | ✅ green |
| CALL-06 | Skype status line strings | unit | `SkypeStatusTextTests`, `CallOvertimePolicyTests` | 03-03 | ✅ | ✅ green |
| CALL-06 / D-15 | Shared banner text (end + 55 notice first); Skype layout renders the banner while `isOvertimeWarning` | unit + grep gate + device | `SkypeStatusTextTests`, `CallOvertimePolicyTests` | 03-03 | ✅ | ✅ green (strings and thresholds); banner rendering is UAT item 17 |
| CALL-07 | Hero shows the shared timer source | grep gate + device | n/a | 03-03 | n/a | n/a, UAT item 13 |
| CALL-10 | Expert Join visibility matrix | unit | `ExpertJoinVisibilityTests` | 03-04 | ✅ | ✅ green |
| EXP-11 | Expert refund line cases, including fail closed when `payment_action_required` or `payment_not_charged` is absent, no line when `payment_not_charged` is true (converted long-lead, D-16), the decode states, and no default refund line in any init | unit + grep gate | `ExpertCancelRefundLineTests`, `ExpertDetailPaymentKeysTests` | 03-08 | ✅ | ✅ green |
| EXP-11 / D-14, D-16 (backend) | Expert details return `payment_action_required` / `payment_action_deadline` and `payment_not_charged` (true for a converted long-lead row, free and no-money rows; false for requires_capture and captured rows with a PaymentIntent), no raw payment columns | backend jest | `npm --prefix "../ClickMe2026 Backend" test -- tests/expertBooking.test.js` | 03-05 | ✅ | ✅ green, 65bb2ed |
| EXP-13 | Expert reschedule reachable from Dashboard and Bookings; pop targets originating tab | grep gate + device | n/a | 03-04 | n/a | n/a, UAT item 18 |
| EXP-13 | Expert picker 6-day paid cap through `PaidBookingWindow`: edge, free uncapped, select guard, paid flag | unit | `ExpertRescheduleWindowTests` (regression: `RescheduleWindowTests`, `PaidBookingWindowTests`) | 03-04 | ✅ | ✅ green |
| — | Toast: one at a time, replace restarts timer, dismiss; timer driven by an injected sleeper, not wall clock (WR-06) | unit | `ToastCenterTests` | 03-06, review fix WR-06 | ✅ | ✅ green |
| BOOK-06 / WR-01 | `RescheduleResponder.onResolved` fires after every 2xx accept (first try and saved-card retry) and decline, before refetch, never after a failure; both owners drop the proposal card even when the refetch fails | unit (stubbed API) | `RescheduleResponderTests`, `UpcomingBookingViewModelTests`, `BookingSummaryViewModelTests` | 03-16 | ✅ | ✅ green |
| BOOK-06 / WR-08 | After a 2xx accept/decline with a failed refetch, the screen shows the new time and status, retries the GET once, and the retry's answer replaces the local guess | unit (stubbed API) | `RescheduleResponderTests`, `UpcomingBookingViewModelTests`, `BookingSummaryViewModelTests` | review fix WR-08 | ✅ | ✅ green |
| BOOK-08 / WR-02 | Server `refund_amount` 0 under `.chargedRefundable` shows the neutral policy line (no amount, no timing); already-cancelled 200 idempotent | unit | `CancelToastMessageTests`, `ClientCancellationViewModelTests` | 03-17 | ✅ | ✅ green |
| BOOK-08 / WR-09 | Post-cancel toast uses the refund case captured before the request; the 60 s tick cannot flip it mid-request | unit (held response) | `ClientCancellationViewModelTests` | review fix WR-09 | ✅ | ✅ green |
| BOOK-08 / EXP-11 / WR-03 | Refund and hold lines built from the list price say "up to"; `CA$0.00` within-24 h line unchanged | unit | `CancelRefundPreviewTests`, `CancelToastMessageTests`, `ExpertCancelRefundLineTests` | review fix WR-03 | ✅ | ✅ green |
| BOOK-13 / WR-04 | `canShowReschedule` mirrors backend `canReschedule`: per-status groups, end-time edge, nil end, exhaustive against the Cancel lists | unit | `UpcomingActionPolicyTests` | review fix WR-04 | ✅ | ✅ green |
| EXP-13 / WR-07 | `submitRefusesFarSlot` uses a stubbed API and asserts zero requests | unit (stubbed API) | `ExpertRescheduleWindowTests` | review fix WR-07 | ✅ | ✅ green |
| BOOK-20 / G-03-1-ITEM14 | Booking Summary price row: Session fee · Free for a free session (is_free wins over a price), PAID with the Money amount unchanged for a paid one, PAID with a dash when a paid topic has no price; nil only before the load | unit (stubbed API) | `BookingSummaryViewModelTests` | 03-18 | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `ClickMe2026Tests/Support/ClientBookingFixtures.swift` — shared client detail JSON builder (`reschedule`, `authorization_expires_at`, `can_join`, `decline_reason_*`, `payment_status`) (plan 03-01)
- [x] `ClickMe2026Tests/Support/URLRequest+Body.swift` — request body reader with a non-colliding name (plan 03-01)
- [x] Every suite marked ❌ W0 at planning time, including `BookingSummaryViewModelTests` (03-13), `BookingShortIDTests` (03-14) and `ExpertRescheduleWindowTests` (03-04)
- [x] Phase 3 device UAT checklist (modelled on `02-DEVICE-UAT-CHECKLIST.md`) (plan 03-12; `03-DEVICE-UAT-CHECKLIST.md`, 24 items)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Toast placement above tab bar and keyboard; VoiceOver announcement | BOOK-08 | Layout and accessibility on device | Cancel a booking; check placement with and without keyboard; repeat with VoiceOver |
| Dynamic Type at largest size on new blocks | all UI | Visual | Set largest accessibility size; open each new block |
| Open Meeting → Skype screen timer and `/end` | CALL-06, CALL-07 | External app handoff | Join a Skype/Zoom booking; check timer and end |
| Expert Join across two accounts | CALL-10 | Needs two live accounts | Client and expert join the same booking inside the window |
| BOOK-06 end to end, from My Bookings and from a push tap | BOOK-06 | Needs real push and expert proposal | Expert proposes; client accepts and declines from both entry points |
| Cancel just over and just under 24 h on a captured booking | BOOK-08 | Real payment state | Cancel two bookings either side of 24 h; compare toast with refund |
| End + 55 notice on a Skype/Zoom session | CALL-06 / D-15 | Needs a session held to 55 minutes past its end | Keep a Skype/Zoom session open (or rejoin inside the reconnect tier) until end + 55; the amber notice shows; it ends at end + 60 |
| Expert cancel money line before and after the D-14/D-16 deploy | EXP-11 | Depends on the production backend state | Before the 03-05 deploy: no money line on any booking (fail closed). After: hold, refund and free cases per D-07, and no money line on a booking converted to long-lead by an accepted reschedule (D-16) |
| Expert reschedule picker 6-day cap | EXP-13 | Visual dimming and note | On a paid booking, chips past now + 6 days are dimmed and the note shows; a free booking is uncapped |
| Keep Booking returns one level | BOOK-12 | Navigation wiring on device | `03-DEVICE-UAT-CHECKLIST.md` item 6 |
| Reschedule returns one level with a toast | BOOK-16 | Navigation wiring and toast on device | `03-DEVICE-UAT-CHECKLIST.md` item 8 |
| Past empty state visual | BOOK-11 | Visual | `03-DEVICE-UAT-CHECKLIST.md` item 5 |
| Cancel and Leave a Review on push-opened screens | BOOK-13, BOOK-17 | Needs real push taps | `03-DEVICE-UAT-CHECKLIST.md` items 7, 9 |
| JOIN CALL on every entry | CALL-03 | Needs a live booking from each entry point | `03-DEVICE-UAT-CHECKLIST.md` item 11 |
| Android Booking Summary ID on device | BOOK-20 (Android) | Device check | `03-DEVICE-UAT-CHECKLIST.md` item 14 |
| Booking Summary Session fee · Free price row on device | BOOK-20 | Visual; the Xcode IDE build adds the Free and Session fee keys to the catalog | `03-DEVICE-UAT-CHECKLIST.md` item 27 |
| Teams label on the smallest iPhone | CALL-08 | Layout on small screen | `03-DEVICE-UAT-CHECKLIST.md` item 23 |
| Expert shell chat-row item has no client actions | EXP-13 | Visual and navigation | `03-DEVICE-UAT-CHECKLIST.md` item 24 |
| Reschedule accept/decline toast in the expert shell (WR-05) | BOOK-06 | Toast host wiring in `HomeExpertView` is view-level | Accept or decline a reschedule from the expert shell; the toast shows |
| BACK-19 production smoke not run | EXP-11 | Production backend smoke was not run, so the EXP-11 copy is code-verified only | Run the BACK-19 production smoke after the 03-05 deploy, then re-check the expert cancel money line |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-11-11; re-validated 2026-11-22 against current code (plans 03-16, 03-17 and review fixes WR-03 to WR-09 added to the map; covered files later touched by phases 04, 05, 06 and quick-261122-r2o re-run green)

## Validation Audit 2026-11-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Audit 2026-11-22

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Map rows added | 7 |
| iOS tests run | 1278 |
| iOS suites passed | 118 |
| Backend tests passed | 162 |
