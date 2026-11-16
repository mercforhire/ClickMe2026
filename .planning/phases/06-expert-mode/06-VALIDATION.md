---
phase: "6"
slug: "expert-mode"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-16"
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `06-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests`; `MockURLProtocol` for HTTP. Android: unit tests under `app/src/test` (Gradle) |
| **Config file** | `ClickMe2026/AllTests.xctestplan` — no Wave 0 framework install |
| **Quick run command** | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| **Full suite command (phase gate, plan 06-10)** | Same with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests` (smoke suites hit production — never run), with `MakeABookingAvailabilityTests.swift` added to `EXCLUDED_SOURCE_FILE_NAMES` (known flake, see below) |
| **Known-flaky record run** | Quick run of `MakeABookingAvailabilityTests` alone, one rerun on failure; outcome recorded in the device checklist and in todo `2026-11-13-flaky-make-a-booking-availability-test.md`; not part of the phase verdict while no Phase 6 commit touches Make a Booking |
| **Build gate** | `xcodebuild build ...` → `BUILD SUCCEEDED` and no new warnings in touched files (before/after `comm -13`, as in Phase 5) |
| **Estimated runtime** | ~2–4 min per single-suite run (simulator boot dominates); ~6–12 min per task verify (two or three xcodebuild invocations, including the build gate); ~4–8 min for the full suite; Android Gradle test + ktlint ~2–5 min warm |

A run counts only with a non-zero test count. `MockURLProtocol` suites use `.serialized`. In per-task quick runs each stubbed suite runs in its own `xcodebuild` invocation (02-07 decision); the phase gate runs every suite in one invocation, as 05-13 did (803 tests in 82 suites), so each new stubbed suite must also pass alongside the others. The iOS plans run one at a time (waves 1 to 9), so per-task runs never share the simulator or tree with another plan; only the Android plan 06-09 runs beside 06-01.

---

## Sampling Rate

- **After every task commit:** the one suite for the touched helper (quick run)
- **After every plan wave:** suites touched in the wave + build gate + regressions `TopicCurrencyTests`, `HomeNavigationPathTests`, `HomeShellExitTests`, `PushRoutePlannerTests`, `ClientProfileHistoryEarningsTests`, `ExpertRescheduleWindowTests`
- **Before `/gsd-verify-work`:** Full suite (phase gate) must be green, grep gates pass, known-flaky outcome recorded
- **Max feedback latency:** ~4 minutes per suite run; ~12 minutes per task verify

---

## Per-Task Verification Map

Requirement-level map (task IDs are bound by the plans' `<verify>` blocks):

| Requirement | Behavior | Test Type | Automated Command / Suite | File Exists | Status |
|-------------|----------|-----------|---------------------------|-------------|--------|
| EXP-02 | Decimal price parse (`12.50`→1250, `12,50`, `.5`, 3 decimals invalid, 20 digits no crash, zero-decimal currency) | unit | `TopicPriceRulesTests` | ❌ W0 | ⬜ pending |
| EXP-03 / EXP-17 iOS | Currency kept on edit; paid locked; default from limits else CAD | unit | `TopicCurrencyTests` (extend) | ✅ | ⬜ pending |
| EXP-04 | PATCH sends `icon_slug: null` / `description: null` when cleared, omits unchanged keys | unit + unit (stubbed, `.serialized`) | `ExpertTopicRequestBodyTests`, `TopicsSetupMutationTests` (PATCH rows) | ❌ W0 | ⬜ pending |
| EXP-01 | No DELETE before confirm; exactly one after | unit (stubbed, `.serialized`) | `TopicsSetupMutationTests` (delete rows) | ❌ W0 | ⬜ pending |
| EXP-08 | Stale 409 comment removed | grep | `! grep -rn "Returns 409 if the topic has active" ClickMe2026` | n/a | ⬜ pending |
| EXP-05 | Cancel reverts draft; commit writes | unit | `AvailabilitySlotRulesTests` | ❌ W0 | ⬜ pending |
| EXP-06 | `addHours` never yields an unpickable end | unit | `AvailabilitySlotRulesTests` | ❌ W0 | ⬜ pending |
| EXP-07 | Off-grid 09:15 row present and selected | unit | `AvailabilitySlotRulesTests` | ❌ W0 | ⬜ pending |
| EXP-09 / D-12 / U1 | Accept → confirmation; 409 `ALREADY_PROCESSED` pops; 1000-unit cap | unit (stubbed, `.serialized`) | `RequestDecisionAcceptTests` | ❌ W0 | ⬜ pending |
| EXP-10 | Calendar title `ClickMe · <topic> with <client>` + fallbacks | unit | `ExpertBookingConfirmationContentTests` | ❌ W0 | ⬜ pending |
| Back to Home | Resets source tab, shows `.dashboard` | unit | `HomeShellExitTests` (extend) | ✅ | ⬜ pending |
| EXP-12 | No whole-card opacity on expired | grep + device D1 | `! grep -n "opacity(request.isExpired" ".../IncomingRequestCard.swift"` | n/a | ⬜ pending |
| EXP-14 | Earnings in booking currency stay green | unit | `ClientProfileHistoryEarningsTests`, `ClientProfileBookingCardTests` | ✅ | ⬜ pending |
| EXP-15 | No fake `isOnline` in hub VM | grep | `! grep -n "isOnline" ".../ExpertProfileHomeViewModel.swift"` | n/a | ⬜ pending |
| EXP-16 | 5000 cap, whitespace-only saves empty (other text sent as typed), dirty tracking, discard prompt | unit (stubbed, `.serialized`) | `ExpertBookingNoteViewModelTests` | ❌ W0 | ⬜ pending |
| EXP-18 | `ID: #` + first 8 upper-cased | unit | `BookingShortIDTests` (extend) | ✅ | ⬜ pending |
| Android EXP-17 | Picker from `allowed_currencies`; lock; body currency; segmented row, caption and notice | Android unit + Robolectric | `./gradlew :app:testDevDebugUnitTest --tests '<FQCN>' ktlintCheck` for `TopicEditorViewModelTest`, `TopicEditorSubviewsTest`, `TopicEditorScreenTest` (plan 06-09) | extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New suites under `ClickMe2026Tests/`: `TopicPriceRulesTests`, `ExpertTopicRequestBodyTests`, `TopicsSetupMutationTests`, `AvailabilitySlotRulesTests`, `RequestDecisionAcceptTests`, `ExpertBookingConfirmationContentTests`, `ExpertBookingNoteViewModelTests` (no pbxproj edit — synchronized folder)
- [ ] Test seams: `TopicsSetupViewModel` `topicPendingDelete` / `requestDelete(_:)` / `cancelDelete()` / `confirmDelete(_:)`; request body recorded via `MockURLProtocol.recordedRequests`
- [ ] `06-DEVICE-UAT-CHECKLIST.md` (written by the last plan, Phase 4/5 format)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Expired request card readability | EXP-12 | Visual contrast; LIKELY item needs device confirmation | Device check D1 in `06-DEVICE-UAT-CHECKLIST.md` |
| Booking Note swipe blocked / Back discard prompt | EXP-16 | Gesture behaviour cannot be unit tested | Device check D4: the swipe never pops (always locked, D-19 amendment 2026-11-16); Back prompts when dirty and pops when clean |
| Accept → Confirmed → Back lands on refreshed Incoming Requests | EXP-09 | Navigation stack behaviour | Device check per UI-SPEC D-list |
| Calendar event created via system editor | EXP-10 | EventKit UI | Device check |
| Android currency picker | EXP-17 | Cross-platform visual | Android device/emulator check |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency within the stated budget (~4 min per suite run, ~12 min per task verify)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
