---
phase: "02"
slug: "shared-ios-plumbing"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-11-09"
validated: "2026-11-10"
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`), target `ClickMe2026Tests` |
| **Config file** | `ClickMe2026/AllTests.xctestplan` |
| **Quick run command** | `xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'id=E8F9FD72-750B-4888-8F47-91AE12B58F65' -only-testing:ClickMe2026Tests/<Suite> -skip-testing:ClickMe2026Tests/SignupSmokeTests -skip-testing:ClickMe2026Tests/AuthSmokeTests` |
| **Full suite command** | same command with `-only-testing:ClickMe2026Tests` (the two smoke suites hit the live production backend and must never run; the target runs serially) |
| **Build gate** | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`, with no new warnings in touched files |
| **Estimated runtime** | ~180 seconds per targeted run (simulator boot + build); suites themselves run in milliseconds |

A run counts only if the output reports a non-zero test count (`Test run with [1-9]`).

---

## Sampling Rate

- **After every task commit:** Run the quick command for that task's suite
- **After every plan wave:** Run the full suite command plus the build gate
- **Before `/gsd-verify-work`:** Full suite must be green, no new warnings, device UAT done
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

Audited 2026-11-10 against a full-target run: 233 tests in 27 suites green before the audit; 238 tests in 28 suites after it (236 pass, 2 fail, both the WR-01 gap tests below).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01 T1, T2 | 02-01 | 1 | CALL-01 | — | N/A | unit | `-only-testing:ClickMe2026Tests/CallOvertimePolicyTests` | ✅ `Utils/CallOvertimePolicyTests.swift` | ✅ green |
| 02-01 T2 | 02-01 | 1 | CALL-04 | — | N/A | unit | `-only-testing:ClickMe2026Tests/CallOvertimePolicyTests` | ✅ `Utils/CallOvertimePolicyTests.swift` | ✅ green |
| 02-02 T1 | 02-02 | 2 | CALL-05 | — | N/A | unit | `-only-testing:ClickMe2026Tests/AgoraConnectionMappingTests` | ✅ `Calls/AgoraConnectionMappingTests.swift` | ✅ green |
| 02-04 T1, T2 | 02-04 | 2 | CALL-02 | T-02-09 | Join gated by server state (lists) | unit | `-only-testing:ClickMe2026Tests/JoinWindowTests` | ✅ `Utils/JoinWindowTests.swift` | ✅ green |
| 02-14 T1, T2 | 02-14 | 3 | CALL-02 | T-02-31 | Join gated by server state (strips); client detail decodes can_join | unit + grep gate | `-only-testing:ClickMe2026Tests/JoinWindowTests` | ✅ `Utils/JoinWindowTests.swift` | ✅ green |
| 02-02 T2 | 02-02 | 2 | CALL-09 | — | Lookalike hosts are not trusted providers | unit | `-only-testing:ClickMe2026Tests/ExternalMeetingProviderTests` | ✅ `Calls/ExternalMeetingProviderTests.swift` | ✅ green |
| 02-05 T1-T3 | 02-05 | 2 | BOOK-10 | T-02-10, T-02-11 | N/A | unit | `-only-testing:ClickMe2026Tests/MoneyTests` | ✅ `Utils/MoneyTests.swift` | ✅ green |
| 02-06 T1, T2 | 02-06 | 3 | BOOK-10 | T-02-12 | Each expert site uses the entry point for its unit | unit | `-only-testing:ClickMe2026Tests/MoneyCallSiteTests` | ✅ `Utils/MoneyCallSiteTests.swift` | ✅ green |
| 02-06 T3 | 02-06 | 3 | BOOK-10 | T-02-30 | An unedited topic save keeps its stored price amount and currency (D-19) | unit + grep gate | `-only-testing:ClickMe2026Tests/MoneyCallSiteTests` | ✅ `Utils/MoneyCallSiteTests.swift` | ✅ green |
| 02-15 T1 | 02-15 | 3 | BOOK-10 | T-02-33 | Real Client Profile net earnings; unknown earnings show "—" (user decision) | unit + grep gate | `-only-testing:ClickMe2026Tests/ClientProfileBookingCardTests` | ✅ `Utils/ClientProfileBookingCardTests.swift` | ✅ green |
| 02-03 T1, T2 | 02-03 | 1 | BOOK-18 | T-02-06, T-02-07 | Unknown statuses decode instead of dropping the event (typed decoders) | unit | `-only-testing:ClickMe2026Tests/BookingStatusDecodingTests` | ✅ `Model/BookingStatusDecodingTests.swift` | ✅ green |
| 02-03 T2 | 02-03 | 1 | BOOK-18 | T-02-27 | Only the newest overlapping refetch writes the expert Upcoming list | unit + grep gate | `-only-testing:ClickMe2026Tests/ReloadGenerationTests` | ✅ `Utils/ReloadGenerationTests.swift` | ✅ green |
| 02-13 T1, T2 | 02-13 | 3 | BOOK-18 | T-02-32 | Only the newest overlapping refetch writes the client detail, summary and My Bookings screens | grep gate + unit (helper) | `-only-testing:ClickMe2026Tests/ReloadGenerationTests` | ✅ `Utils/ReloadGenerationTests.swift` | ✅ green |
| audit gap (WR-01) | 02-03 / 02-13 | — | BOOK-18 | T-02-06 | An unknown status on the client detail and My Bookings screens reads as `.unknown`, never `.confirmed` | unit (VM + stubbed API) | `-only-testing:ClickMe2026Tests/ClientBookingStatusFallbackTests` | ✅ `Booking/ClientBookingStatusFallbackTests.swift` (added by audit) | ❌ red: 3 control tests pass, 2 unknown-status tests fail on the real defect (escalated) |
| 02-07 T1, T3 | 02-07 | 1 | BOOK-14 | — | 6-day paid cap shows days and dims slots (user decision) | unit | `-only-testing:ClickMe2026Tests/PaidBookingWindowTests` + `BookingErrorMapperTests` | ✅ `Utils/PaidBookingWindowTests.swift`, `Utils/BookingErrorMapperTests.swift` | ✅ green |
| 02-08 T1, T2 | 02-08 | 2 | BOOK-14 | — | Reschedule picker honours the 6-day paid cap; shared error copy | unit | `-only-testing:ClickMe2026Tests/RescheduleWindowTests` | ✅ `Booking/RescheduleWindowTests.swift` | ✅ green |
| 02-07 T2 | 02-07 | 1 | PAY-05 | — | N/A | unit | `-only-testing:ClickMe2026Tests/BookingErrorMapperTests` + `BookingErrorCopyParityTests` | ✅ `Utils/BookingErrorMapperTests.swift`, `Booking/BookingErrorCopyParityTests.swift` | ✅ green |
| 02-09 T1-T3, 02-10 T1 | 02-09, 02-10 | 1, 2 | PUSH-01 | — | Unknown push types fall back safely; booking_id-only fallback (user decision) | unit | `-only-testing:ClickMe2026Tests/PushEventTests` + `PushDestinationTableTests` + `PushRoutePlannerTests` | ✅ `Push/` | ✅ green |
| 02-10 T2 | 02-10 | 2 | PUSH-02 | — | Expert mode only when the account can be expert | unit | `-only-testing:ClickMe2026Tests/PushRoutePlannerTests` | ✅ `Push/PushRoutePlannerTests.swift` | ✅ green |
| 02-09 T3, 02-10 T2 | 02-09, 02-10 | 1, 2 | PUSH-03 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PushRoutePlannerTests` + `PushDestinationTableTests` | ✅ `Push/` | ✅ green |
| 02-09 T3, 02-10, 02-12 | 02-09, 02-10, 02-12 | 1-3 | BOOK-15 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PushDestinationTableTests` + `PushRoutePlannerTests` | ✅ `Push/` | ✅ green |
| 02-12 T1, T2 | 02-12 | 3 | PUSH-04 | — | Old account's pushes stop after logout | unit (fakes) | `-only-testing:ClickMe2026Tests/PushTokenCleanupTests` | ✅ `Push/PushTokenCleanupTests.swift` | ✅ green |
| 02-11 T1, T2 | 02-11 | 3 | CHAT-09 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PushForegroundPolicyTests` | ✅ `Push/PushForegroundPolicyTests.swift` | ✅ green |
| 02-12 T3 | 02-12 | 3 | (checklist) | — | N/A | manual | `02-DEVICE-UAT-CHECKLIST.md` | ✅ | manual-only |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Test files for every suite above under `ClickMe2026Tests/{Utils,Calls,Model,Push,Booking}/`
- [x] A fake-injectable `PushTokenCleanup` and a pure `PushRoutePlanner` exist before their tests
- [x] Broken-test exclusion decided: smoke suites are skipped with `-skip-testing` (`SignupSmokeTests`, `AuthSmokeTests`); `LoginTests` runs green
- [x] Phase 2 UAT checklist file for the device checks below (`02-DEVICE-UAT-CHECKLIST.md`)

---

## Manual-Only Verifications

All device-only checks are collected in `02-DEVICE-UAT-CHECKLIST.md` and are classified manual-only, not automation gaps.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Call past end+55 shows the notice and ends at end+60 | CALL-01 | Needs a live Agora call on a device | Book a short session, stay in the call past its end, watch for the notice at +55 and the end at +60 |
| Call screen reaches Ended on Agora failure | CALL-05 | `.failed` arrives only after a long reconnect timeout; delegate wiring | Unit mapping test plus a normal-call regression check |
| Booking push opens the screen, no warning page, client and expert mode, warm and cold | PUSH-01/02/03, BOOK-15 | SwiftUI navigation registration is not unit-testable | Send each push type from the backend to a device in each mode and launch state |
| After logout the old account's pushes do not arrive | PUSH-04 | Needs real APNs/FCM delivery | Log out, trigger a push to the old account, confirm nothing arrives |
| No banner for the chat already on screen | CHAT-09 | Foreground notification presentation | Open a chat, send a message from the other side, confirm no banner |
| Join button at the window edges | CALL-02 | Live booking timing | Check Join at start−60, during the session, and after end on a long session, on the lists and on the Explore and dashboard strips |
| Neutral label for an unknown status on the client detail and My Bookings card (after the WR-01 fix) | BOOK-18 | Rendering; the mapping itself is now unit-tested | Covered by `ClientBookingStatusFallbackTests` once WR-01 is fixed; visually confirm on device |
| Money on screen; topic reopen-and-save; Client Profile history | BOOK-10 | Rendering, and a real topic PATCH against production data | Check cents and CA$ on each money screen; open a topic priced with cents, change only the title, save, confirm the price and its currency are unchanged; confirm Client Profile history rows show "—" |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter. Blocked: BOOK-18 has a red test (`ClientBookingStatusFallbackTests`) exposing review WR-01. `UpcomingBookingViewModel.swift:190` and `MyBookingsViewModel.swift:214` fall back to `.confirmed` instead of `.unknown`. Escalated to the developer; app code was not changed by this audit.

**Approval:** partial (22/23 requirement rows green; BOOK-18 client-screen fallback escalated)

### Escalated

| Requirement | Test | Failing assertion | Defect |
|-------------|------|-------------------|--------|
| BOOK-18 | `ClientBookingStatusFallbackTests` "a detail with an unrecognised status maps to .unknown, not .confirmed" | `ClientBookingStatusFallbackTests.swift:159`: `(vm.bookingStatus → .confirmed) == .unknown` | WR-01, `UpcomingBookingViewModel.swift:190` |
| BOOK-18 | `ClientBookingStatusFallbackTests` "an upcoming row with an unrecognised status maps to .unknown, not .confirmed" | `ClientBookingStatusFallbackTests.swift:177`: `(vm.upcomingBookings.map(\.status) → [.confirmed]) == [.unknown]` | WR-01, `MyBookingsViewModel.swift:214` |

## Validation Audit 2026-11-10

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 |
