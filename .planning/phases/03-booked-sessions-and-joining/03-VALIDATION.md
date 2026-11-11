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

Requirement-to-suite map from `03-RESEARCH.md` § Validation Architecture. Task IDs are filled in from the PLAN files.

| Requirement | Behavior | Test Type | Suite (`-only-testing:ClickMe2026Tests/…`) | File Exists | Status |
|-------------|----------|-----------|---------------------------------------------|-------------|--------|
| BOOK-06 | Accept/decline reschedule, payment-method retry, decline note cap, refetch, double-tap guard | unit (stubbed API) | `RescheduleResponderTests` | ❌ W0 | ⬜ pending |
| BOOK-06 | Proposal exposed only when expert-initiated; card gone after refetch | unit | `UpcomingBookingViewModelTests` | ❌ W0 | ⬜ pending |
| BOOK-07 | Cancel reason composition and 500 UTF-16 cap; request body carries `reason` | unit | `CancelReasonComposerTests`, `ClientCancellationViewModelTests` | ❌ W0 | ⬜ pending |
| BOOK-08 | Refund preview cases A–F, 24 h boundary, second-tap rule, toast matrix | unit | `CancelRefundPreviewTests`, `CancelToastMessageTests`, `ClientCancellationViewModelTests` | ❌ W0 | ⬜ pending |
| BOOK-09 | Status → pill text/tone, including unknown and `rescheduled` | unit | `BookingStatusPillTests` | ❌ W0 | ⬜ pending |
| BOOK-11 | Past empty state only when loaded and empty | unit | `MyBookingsEmptyStateTests` | ❌ W0 | ⬜ pending |
| BOOK-12 | Keep Booking pops one level | grep gate + device | n/a | n/a | ⬜ pending |
| BOOK-13 | `canShowCancel` boundary at `end == now` | unit | `UpcomingActionPolicyTests` | ❌ W0 | ⬜ pending |
| BOOK-16 | Availability GET carries `exclude_booking_id`; held copy; return with confirmation | unit + grep gate | `RescheduleAvailabilityTests` | ❌ W0 | ⬜ pending |
| BOOK-17 | Leave a Review only for `.completed` with no review | unit | `BookingSummaryViewModelTests` | ❌ W0 | ⬜ pending |
| BOOK-20 | Summary ID label equals Upcoming label | unit | `BookingShortIDTests` | ❌ W0 | ⬜ pending |
| BACK-02 (iOS) | Decline note card and reason labels | unit | `DeclineNoteTests` | ❌ W0 | ⬜ pending |
| CALL-03 / CALL-08 | Upcoming join state per status/time/`canJoin`; provider label | unit | `UpcomingBookingViewModelTests`, `ExternalMeetingProviderTests` | partial | ⬜ pending |
| CALL-06 | Skype status line strings | unit | `SkypeStatusTextTests` | ❌ W0 | ⬜ pending |
| CALL-07 | Hero shows the shared timer source | grep gate + device | n/a | n/a | ⬜ pending |
| CALL-10 | Expert Join visibility matrix | unit | `ExpertJoinVisibilityTests` | ❌ W0 | ⬜ pending |
| EXP-11 | Expert refund line cases | unit | `ExpertCancelRefundLineTests` | ❌ W0 | ⬜ pending |
| EXP-13 | Expert reschedule reachable from Dashboard and Bookings; pop targets originating tab | grep gate + device | n/a | n/a | ⬜ pending |
| — | Toast: one at a time, replace restarts timer, dismiss | unit | `ToastCenterTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ClickMe2026Tests/Support/ClientBookingFixtures.swift` — shared client detail JSON builder (`reschedule`, `authorization_expires_at`, `can_join`, `decline_reason_*`, `payment_status`)
- [ ] `ClickMe2026Tests/Support/URLRequest+Body.swift` — request body reader with a non-colliding name
- [ ] Every suite marked ❌ W0 above
- [ ] Phase 3 device UAT checklist (modelled on `02-DEVICE-UAT-CHECKLIST.md`)

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

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
