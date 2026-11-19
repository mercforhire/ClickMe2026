---
phase: "08"
slug: "release"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-19"
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (iOS `ClickMe2026Tests/`), jest (backend `tests/`), JUnit + ktlint (Android) |
| **Config file** | `ClickMe2026/AllTests.xctestplan`; backend `jest.config.js`; Android Gradle |
| **Quick run command** | iOS: `xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite>`; backend: `npm test -- --silent <test files>`; Android: `./gradlew :app:testDevDebugUnitTest --tests '<FQCN>' ktlintCheck` |
| **Full suite command** | iOS: the same command without `-only-testing`; backend: `npm test -- --silent` (only the 6 `redis.test.js` tests may fail); Android: `./gradlew :app:testDevDebugUnitTest ktlintCheck` |
| **Estimated runtime** | ~600 seconds (full iOS run); ~120 s backend; ~300 s Android |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the repo the task touched, naming the suite.
- **After every plan wave:**
  - Backend waves: the full backend suite at the baseline of 6 known failures.
  - iOS waves: the full iOS unit run, a Debug build and the warnings grep.
  - Android waves: the full Android unit run plus ktlint.
- **Before `/gsd-verify-work`:** all of the following must hold:
  - The full iOS run is green.
  - The clean-checkout Release build is green, with an empty new-warnings diff against `a48c664`.
  - The backend suite is at its baseline.
  - `/health` reports the last pushed SHA.
  - The regression checklist is signed off.
- **Max feedback latency:** 600 seconds

---

## Per-Task Verification Map

Task IDs are filled in by the planner. Requirement-level map from RESEARCH.md § Validation Architecture:

| Requirement / item | Behavior | Test Type | Automated Command | File Exists | Status |
|--------------------|----------|-----------|-------------------|-------------|--------|
| REL-02 / G-03-1-ITEM1C | Reschedule decline pushes the proposer with `sub_category: 'reschedules'` (D-31); request decline unchanged | backend unit | `npm test -- --silent tests/events.test.js tests/clientBooking.test.js tests/expertBooking.test.js` | ✅ (rows to add) | ⬜ pending |
| REL-02 / G-03-1-ITEM1B backend | `reason_text` / `reason_by` in the chat event (cherry-picked `94d659b`) | backend unit | same | ✅ | ⬜ pending |
| REL-02 / G-03-1-ITEM1B iOS | The mapper reads `reason_text ?? decline_reason_text`, labels by `reason_by` and ignores a blank reason | iOS unit | `-only-testing:ClickMe2026Tests/ChatItemMapperTests` | ✅ (rows to add) | ⬜ pending |
| REL-02 / G-03-1-ITEM1B Android | `toThreadItem` carries the reason fields | Android unit | `--tests '*ChatMessageMappingTest'` | ✅ (rows to add) | ⬜ pending |
| REL-02 / D-23 | Delete Account saved-cards note: exact string, plus the test carve-out | iOS unit | `-only-testing:ClickMe2026Tests/AccountDeletionCopyTests` | ✅ (rewrite) | ⬜ pending |
| REL-02 / D-24 | `US$` / `CA$` everywhere on iOS | iOS unit | `-only-testing:ClickMe2026Tests/MoneyTests` (+ `MoneyCallSiteTests`, `ClientProfileBookingCardTests`, `ClientProfileHistoryEarningsTests`, `TopicsSetupTopicCardLabelTests`, `TopicCurrencyTests`) | ✅ (pins change) | ⬜ pending |
| REL-02 / D-32 | Android symbol override | Android unit | `--tests '*MoneyTest'` | ✅ (6 rows change) | ⬜ pending |
| REL-02 / D-29 | A transient pre-PI error leaves the row unstamped; post-PI errors are unchanged; the start−6h deadline is honored | backend unit | `npm test -- --silent tests/cron/longLeadChargeSweep.test.js` | ✅ (rows to add) | ⬜ pending |
| REL-02 / D-17 | The D-12 and CR-02 describe blocks pass on merged `master` | backend | full suite | ✅ | ⬜ pending |
| REL-02 / D-19, D-25 | A clean checkout builds in Release with no new warnings | build | clean-checkout build + warnings diff script | ❌ W0 | ⬜ pending |
| REL-02 / D-18 | The app target is 1.1 / 7 | shell grep | `grep -c 'MARKETING_VERSION = 1.1;' ClickMe.xcodeproj/project.pbxproj` and `grep -c 'CURRENT_PROJECT_VERSION = 7;' ...` | n/a | ⬜ pending |
| REL-01 | Regression run: book, pay, join, past the end, finish, plus the D-06, D-27 and D-28 checks | manual device | checklist artifact signed off by the user | ❌ W0 | ⬜ pending |
| REL-01 | Closeouts are consistent | doc check | grep the REQUIREMENTS and ROADMAP rows; check the `03-VERIFICATION` and `04-VERIFICATION` status | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Fix `FavoritesViewModel.swift:282` (`_ = list.remove(...)`) so the warnings diff is empty.
- [ ] Make a clean checkout compile with a tracked, token-free `PreviewSecrets`. Fix `XCODE_PROJECT` in `build.yml` and `teamID` in `ExportOptions.plist`.
- [ ] `scripts/release-build-check.sh`: a clean-checkout Release build plus a normalized warnings diff against `a48c664`.
- [ ] `08-REGRESSION-CHECKLIST.md`.
- [ ] `08-RELEASE-RECORD.md`.
- [ ] New test rows: `ChatItemMapperTests`, the backend events and sweep rows, `ChatMessageMappingTest`, and the Money and AccountDeletionCopy rewrites.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Core-path regression with real money on TestFlight build 1.1 (7) against production | REL-01 | Real device, real Stripe charge, Android peer | `08-REGRESSION-CHECKLIST.md` S1–S3 |
| BACK-06 / BACK-07 / BACK-19 hold release | REL-01, D-06, D-27 | Real Stripe state | Regression side checks; verify in the Stripe Dashboard |
| Backend deploy smoke on build 6 + Android | REL-02, D-13 | Live clients | Log in, open bookings, open chat, plus one changed path |
| App Store submission and the What's New text | REL-01, D-22 | App Store Connect | User approves the text and submits |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
