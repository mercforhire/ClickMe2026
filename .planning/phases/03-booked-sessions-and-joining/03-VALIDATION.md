---
phase: "03"
slug: "booked-sessions-and-joining"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Full suite command** | same command with `-only-testing:ClickMe2026Tests` (the two smoke suites hit the live production backend and must never run) |
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
| BOOK-06 | Accept/decline reschedule, payment-method retry, decline note cap, refetch, double-tap guard | unit (stubbed API) | `RescheduleResponderTests` | 03-01 (toast rows 03-06) | ❌ W0 | ⬜ pending |
| BOOK-06 | Proposal exposed only when expert-initiated; card gone after refetch | unit | `UpcomingBookingViewModelTests` | 03-01 | ❌ W0 | ⬜ pending |
| BOOK-06 | Booking Summary accept through the shared responder; silent refresh keeps content | unit (stubbed API) + grep gate | `BookingSummaryViewModelTests` | 03-13 | ❌ W0 | ⬜ pending |
| BOOK-07 | Cancel reason composition and 500 UTF-16 cap; request body carries `reason` | unit | `CancelReasonComposerTests`, `ClientCancellationViewModelTests` | 03-10 | ❌ W0 | ⬜ pending |
| BOOK-08 | Refund preview cases A–F, 24 h boundary, second-tap rule, toast matrix | unit | `CancelRefundPreviewTests`, `CancelToastMessageTests`, `ClientCancellationViewModelTests` | 03-02, 03-10 | ❌ W0 | ⬜ pending |
| BOOK-09 | Every `BookingStatus` case → pill text/tone from the shared decoder; raw string only for `.unknown`; no raw-string table | unit + grep gate | `BookingStatusPillTests`, `UpcomingBookingViewModelTests` | 03-14 | ❌ W0 | ⬜ pending |
| BOOK-11 | Past empty state only when loaded and empty | unit | `MyBookingsEmptyStateTests` | 03-11 | ❌ W0 | ⬜ pending |
| BOOK-12 | Keep Booking pops one level; `pop(_:)` depth | grep gate + unit + device | `HomeNavigationPathTests` | 03-11, 03-12 | ❌ W0 | ⬜ pending |
| BOOK-13 | `canShowCancel` boundary at `end == now` | unit | `UpcomingActionPolicyTests` | 03-09 | ❌ W0 | ⬜ pending |
| BOOK-16 | Availability GET carries `exclude_booking_id`; held copy; return with confirmation | unit + grep gate | `RescheduleAvailabilityTests` | 03-11 | ❌ W0 | ⬜ pending |
| BOOK-17 | Leave a Review only for `.completed` with no review | unit | `BookingSummaryViewModelTests` | 03-07 | ❌ W0 (created by 03-13) | ⬜ pending |
| BOOK-20 | Short ID formatter; Summary ID label equals Upcoming label | unit | `BookingShortIDTests`, `BookingSummaryViewModelTests` | 03-14, 03-07 | ❌ W0 | ⬜ pending |
| BOOK-20 (Android) | Android Booking Summary shows "ID: #…" for a short and a full-UUID id | Android unit (Gradle `:app:testDevDebugUnitTest --tests …BookingSummaryScreenTest`) | n/a (Android repo) | 03-15 | partial (suite exists) | ⬜ pending |
| BACK-02 (iOS) | Decline note card and reason labels | unit | `DeclineNoteTests` | 03-07 | ❌ W0 | ⬜ pending |
| CALL-03 / CALL-08 | Upcoming join state per status/time/`canJoin`; provider label | unit | `UpcomingBookingViewModelTests`, `ExternalMeetingProviderTests` | 03-09 | partial | ⬜ pending |
| CALL-06 | Skype status line strings | unit | `SkypeStatusTextTests` | 03-03 | ❌ W0 | ⬜ pending |
| CALL-06 / D-15 | Shared banner text (end + 55 notice first); Skype layout renders the banner while `isOvertimeWarning` | unit + grep gate + device | `SkypeStatusTextTests` | 03-03 | ❌ W0 | ⬜ pending |
| CALL-07 | Hero shows the shared timer source | grep gate + device | n/a | 03-03 | n/a | ⬜ pending |
| CALL-10 | Expert Join visibility matrix | unit | `ExpertJoinVisibilityTests` | 03-04 | ❌ W0 | ⬜ pending |
| EXP-11 | Expert refund line cases, including fail closed when `payment_action_required` is absent and the decode states | unit + grep gate | `ExpertCancelRefundLineTests` | 03-08 | ❌ W0 | ⬜ pending |
| EXP-11 / D-14 (backend) | Expert details return `payment_action_required` / `payment_action_deadline`, no raw payment columns | backend jest | `npm --prefix "../ClickMe2026 Backend" test -- tests/expertBooking.test.js` | 03-05 | partial (suite exists) | ⬜ pending |
| EXP-13 | Expert reschedule reachable from Dashboard and Bookings; pop targets originating tab | grep gate + device | n/a | 03-04 | n/a | ⬜ pending |
| EXP-13 | Expert picker 6-day paid cap through `PaidBookingWindow`: edge, free uncapped, select guard, paid flag | unit | `ExpertRescheduleWindowTests` (regression: `RescheduleWindowTests`, `PaidBookingWindowTests`) | 03-04 | ❌ W0 | ⬜ pending |
| — | Toast: one at a time, replace restarts timer, dismiss | unit | `ToastCenterTests` | 03-06 | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ClickMe2026Tests/Support/ClientBookingFixtures.swift` — shared client detail JSON builder (`reschedule`, `authorization_expires_at`, `can_join`, `decline_reason_*`, `payment_status`) (plan 03-01)
- [ ] `ClickMe2026Tests/Support/URLRequest+Body.swift` — request body reader with a non-colliding name (plan 03-01)
- [ ] Every suite marked ❌ W0 above, including `BookingSummaryViewModelTests` (03-13), `BookingShortIDTests` (03-14) and `ExpertRescheduleWindowTests` (03-04)
- [ ] Phase 3 device UAT checklist (modelled on `02-DEVICE-UAT-CHECKLIST.md`) (plan 03-12)

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
| Expert cancel money line before and after the D-14 deploy | EXP-11 | Depends on the production backend state | Before the 03-05 deploy: no money line on any booking (fail closed). After: hold, refund and free cases per D-07 |
| Expert reschedule picker 6-day cap | EXP-13 | Visual dimming and note | On a paid booking, chips past now + 6 days are dimmed and the note shows; a free booking is uncapped |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
