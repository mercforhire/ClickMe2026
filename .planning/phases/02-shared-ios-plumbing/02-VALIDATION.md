---
phase: "02"
slug: "shared-ios-plumbing"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-09"
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`), target `ClickMe2026Tests` |
| **Config file** | `ClickMe2026/AllTests.xctestplan` |
| **Quick run command** | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite>` |
| **Full suite command** | same command without `-only-testing` |
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

Task IDs are filled in by the planner; the requirement → suite mapping is fixed here.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | CALL-01 | — | N/A | unit | `-only-testing:ClickMe2026Tests/CallOvertimePolicyTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CALL-04 | — | N/A | unit | `-only-testing:ClickMe2026Tests/CallOvertimePolicyTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CALL-05 | — | N/A | unit | `-only-testing:ClickMe2026Tests/AgoraConnectionMappingTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CALL-02 | — | Join gated by server state | unit | `-only-testing:ClickMe2026Tests/JoinWindowTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CALL-09 | — | Lookalike hosts are not trusted providers | unit | `-only-testing:ClickMe2026Tests/ExternalMeetingProviderTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BOOK-10 | — | N/A | unit | `-only-testing:ClickMe2026Tests/MoneyTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BOOK-18 | — | N/A | unit | `-only-testing:ClickMe2026Tests/BookingStatusDecodingTests` | ❌ W0 | ⬜ pending |
| 02-03 T2, T3 | 02-03 | 1 | BOOK-18 | T-02-27 | Only the newest overlapping refetch writes the screen | unit | `-only-testing:ClickMe2026Tests/ReloadGenerationTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BOOK-14 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PaidBookingWindowTests` + `BookingErrorMapperTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PAY-05 | — | N/A | unit | `-only-testing:ClickMe2026Tests/BookingErrorMapperTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PUSH-01 | — | Unknown push types fall back safely | unit | `-only-testing:ClickMe2026Tests/PushEventTests` + `PushRoutePlannerTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PUSH-02 | — | Expert mode only when the account can be expert | unit | `-only-testing:ClickMe2026Tests/PushRoutePlannerTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PUSH-03 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PushRoutePlannerTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BOOK-15 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PushRoutePlannerTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PUSH-04 | — | Old account's pushes stop after logout | unit (fakes) | `-only-testing:ClickMe2026Tests/PushTokenCleanupTests` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CHAT-09 | — | N/A | unit | `-only-testing:ClickMe2026Tests/PushForegroundPolicyTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test files for every suite above under `ClickMe2026Tests/{Utils,Calls,Model,Push}/` (none exist yet)
- [ ] A fake-injectable `PushTokenCleanup` and a pure `PushRoutePlanner` exist before their tests
- [ ] Broken-test exclusion decided (keep `EXCLUDED_SOURCE_FILE_NAMES` or fix `LoginTests` / `AuthSmokeTests`)
- [ ] Phase 2 UAT checklist file for the device checks below

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Call past end+55 shows the notice and ends at end+60 | CALL-01 | Needs a live Agora call on a device | Book a short session, stay in the call past its end, watch for the notice at +55 and the end at +60 |
| Call screen reaches Ended on Agora failure | CALL-05 | `.failed` arrives only after a long reconnect timeout; delegate wiring | Unit mapping test plus a normal-call regression check |
| Booking push opens the screen, no warning page, client and expert mode, warm and cold | PUSH-01/02/03, BOOK-15 | SwiftUI navigation registration is not unit-testable | Send each push type from the backend to a device in each mode and launch state |
| After logout the old account's pushes do not arrive | PUSH-04 | Needs real APNs/FCM delivery | Log out, trigger a push to the old account, confirm nothing arrives |
| No banner for the chat already on screen | CHAT-09 | Foreground notification presentation | Open a chat, send a message from the other side, confirm no banner |
| Join button at the window edges | CALL-02 | Live booking timing | Check Join at start−60, during the session, and after end on a long session |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
