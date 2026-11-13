---
phase: "05"
slug: "signup-mode-switch-and-account"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-13"
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests` |
| **Config file** | `ClickMe2026/AllTests.xctestplan` |
| **Quick run command** | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| **Full suite command** | same, with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests -collect-test-diagnostics never` (smoke suites hit production; never run) |
| **Build gate** | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` → `BUILD SUCCEEDED`, no new warnings in touched files |
| **Estimated runtime** | ~180 seconds per single-suite run |

A run counts only with a non-zero test count. `MockURLProtocol` suites are `.serialized`. One suite per `xcodebuild`; rerun once on a simulator-busy error.

---

## Sampling Rate

- **After every task commit:** Run the quick run command for the suite of the touched helper
- **After every plan wave:** Run every suite touched in the wave + build gate + Phase 2–4 regressions in this area (`PushRoutePlannerTests`, `AutoLoginOutcomeTests`, `SuspensionNoticeTests`, `HomeShellExitTests`, `HomeNavigationPathTests`, `ClientCancellationViewModelTests`, `CancelRefundPreviewTests`, `UpcomingActionPolicyTests`)
- **Before `/gsd-verify-work`:** Full suite must be green, grep gates pass
- **Max feedback latency:** 180 seconds

---

## Requirement → Test Map

| Req ID | Behavior | Test Type | Suite / Command | File Exists |
|--------|----------|-----------|-----------------|-------------|
| SIGN-01 | Not ready without avatar; ready with; `missingForPublish` lists photo | unit | `SignupAccumulatorTests` | ❌ W0 |
| SIGN-02 | Status `verified:true` seeds `emailVerified`; failure leaves it; never downgrades | unit (stubbed) | `SignupEmailVerifiedSeedTests` | ❌ W0 |
| SIGN-03 | Language and tag picker output and publish payload keep tap order | unit | `SelectionOrderTests` | ❌ W0 |
| SIGN-04 | `"ca "` → `CAN` in publish body; unknown code = not ready | unit | `SignupAccumulatorTests` | ❌ W0 |
| SIGN-05 | Crop size and centre pixel for zoom 0/0.5/1; rotated source; max side; no EXIF GPS | unit | `ProfilePhotoCropperTests` | ❌ W0 |
| SIGN-06 | Gate truth table (incomplete → hub, failed → enter, complete → enter, call active → blocked for user and push, deferred, role guard); deferral store set/clear/logout | unit | `ExpertModeGateTests`, `SetupDeferralStoreTests` | ❌ W0 |
| SIGN-06 | No `setMode(` outside `UserManager.swift` | grep gate | `! grep -rn 'setMode(' ClickMe2026 \| grep -v Managers/UserManager.swift` | n/a |
| SIGN-06 | Single-call invariant: `requestModeSwitch` call guard ahead of every write; push `.blockedByCall` case keeps the tap and the shells replay it on call end; foreground re-check holds the hub during a call | region grep gates | 05-07 Task 1, 05-10 Task 1, 05-12 Task 1 | n/a |
| D-05/06/07 | Province optional; `LocationFormatter` cases; `""` sent on clear | unit | `SignupAccumulatorTests`, `LocationFormatterTests`, `ProfileLanguagesSaveTests` | ❌ W0 |
| SET-01 | Client and expert bodies carry `languages.language_ids` + `custom_languages`; omitted when unchanged; customs preserved | unit (stubbed) | `ProfileLanguagesSaveTests` | ❌ W0 |
| SET-02 | Help support address equals `clickmeapp@uptrendinvestments.net` (shared constant) | unit + grep | `SupportContactTests`; `! grep -rn 'support@clickme' ClickMe2026` | ❌ W0 |
| SET-03 | No Pause Account code or copy | grep gate | `! grep -rniE 'PauseCard\|onPauseAccount\|Pause Account' ClickMe2026` | n/a |
| SET-04 | Load → 0 PATCH; toggle → exactly 1 | unit (stubbed) | `NotificationSettingsAutoSaveTests` | ❌ W0 |
| SET-05 | 0, 9, whitespace-padded 9 chars → no request; 10 → request | unit (stubbed) | `FeedbackValidationTests` | ❌ W0 |
| SET-06 | `ErrorCode` decodes `CLIENT_HAS_UPCOMING_BOOKINGS`; blocker mapping; copy has no false claims; 409 shows message | unit | `AccountDeletionBlockerTests`, `DeleteAccountViewModelTests` | ❌ W0 |
| SET-07 | Policy view linked from `ClientCancellationView`; `ReadyToStart*` gone | grep + build | `grep -c 'CancellationPoliciesView()' …/ClientCancellationView.swift` ≥ 1; `grep -rn ReadyToStart ClickMe2026 ClickMe2026Tests` = 0 | n/a |
| T8 | remember/trim/prefill/explicit wins/deletion forgets/failed deletion keeps | unit (stubbed, `.serialized`) | `RememberedLoginEmailTests` | ported from `b0629d9` |

*Per-task rows are filled from PLAN.md `<automated>` blocks during execution / `/gsd-validate-phase`.*

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New test suites listed above under `ClickMe2026Tests/` (synchronized groups; no pbxproj edit)
- [ ] Seams: injectable debounce (`NotificationSettingsViewModel`, both profile VMs), `api:` on `ClientProfileSettingsViewModel.previewSeed`, a hook to run `performAutoSave` in tests, `userManager:` param on `DeleteAccountViewModel`
- [ ] `05-DEVICE-UAT-CHECKLIST.md`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gate over a real mode switch, Not now, deferral across relaunch/foreground, hub chrome | SIGN-06 | SwiftUI route handoff and scenePhase | Device checklist |
| Crop result on a real photo | SIGN-05 | Real camera-roll orientation/EXIF | Device checklist |
| Mail opens to support address | SET-02 | Mail app / `mailto:` | Device checklist |
| Delete copy readable; 409 → My Bookings | SET-06 | Visual copy review, tab routing | Device checklist |
| Cancellation policy link opens from cancel confirmation | SET-07 | Navigation on `NavigationPath` stack | Device checklist |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
