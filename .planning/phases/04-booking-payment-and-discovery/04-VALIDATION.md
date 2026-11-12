---
phase: "04"
slug: "booking-payment-and-discovery"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `04-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests`; backend Jest |
| **Config file** | `ClickMe2026/AllTests.xctestplan` (language en, region GB). Backend: `../ClickMe2026 Backend` jest config |
| **Quick run command** | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| **Full suite command** | Same, with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests -collect-test-diagnostics never` (the smoke suites hit production and must never run) |
| **Backend command** | `REDIS_URL=redis://localhost:6379 npm test -- tests/webhooks.test.js tests/services/connectedPaymentMethodClone.test.js tests/cron/longLeadChargeSweep.test.js` from `../ClickMe2026 Backend` (baseline: 3 suites, 76 tests) |
| **Build gate** | `xcodebuild build … -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` → `BUILD SUCCEEDED`, no new warnings in touched files |
| **Estimated runtime** | ~180 seconds per single-suite run (mostly simulator boot) |

A run counts only if it reports a non-zero test count. `MockURLProtocol` suites are `.serialized`; run one suite per `xcodebuild`. If concurrent runs hit a simulator-busy error, rerun once.

---

## Sampling Rate

- **After every task commit:** the single suite for the touched helper (quick run command)
- **After every plan wave:** every suite touched in the wave, plus the build gate; the backend command for D-12
- **Before `/gsd-verify-work`:** full suite green, including the Phase 2/3 regressions (`JoinWindowTests`, `MoneyTests`, `ClientBookingStatusFallbackTests`, `ReloadGenerationTests`, `BookingErrorMapperTests`, `HomeNavigationPathTests`, `ClientHomeFeedTests`); backend suites green; then the device checklist
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

Task IDs are filled in by the planner; the requirement-to-suite mapping is fixed here.

| Requirement | Behavior | Test Type | Automated Command (`-only-testing:ClickMe2026Tests/…`) | File Exists | Status |
|-------------|----------|-----------|----------------------------------------------------------|-------------|--------|
| PAY-01 | Closing the sheet never proceeds, even with a saved card | unit | `PaymentSheetOutcomeTests` | ❌ W0 | ⬜ pending |
| PAY-02 / D-17 | Transport failure = unknown; 409 PAYMENT_IN_PROGRESS = unknown (D-17); other coded 402/409/422 = server-coded; `ConfirmRetryPolicy` bounded retries | unit | `ConfirmOutcomeTests` (classifier and retry-policy rows; plus `BookingErrorMapperTests` regression) | ❌ W0 | ⬜ pending |
| PAY-02 / D-17 | Unknown (including PAYMENT_IN_PROGRESS) keeps PI/pm/attempt id, retries ≤2, replay lands on Request Sent, Try again reuses the PI | unit (stubbed) | `MakeABookingPaidFlowTests` | ❌ W0 | ⬜ pending |
| PAY-02 / D-04 / D-15 / D-17 | Ledger-backed "maybe" alert; DUPLICATE_BOOKING smart route; record kept on SLOT_UNAVAILABLE and PAYMENT_IN_PROGRESS (`keepsRecord(afterServerCode:)`) | unit | `MakeABookingPaidFlowTests`, `UnconfirmedBookingLedgerTests` | ❌ W0 | ⬜ pending |
| PAY-03 | Lifecycle card variant chooser (free / held+expiry / none / captured; held without expiry hidden, never "charged"), fail closed | unit | `PaymentLifecycleVariantTests`, `BookingRequestSentVariantTests` | ❌ W0 | ⬜ pending |
| PAY-04 | No stale `TODO(backend)` / "Backend hasn't shipped" comments | grep gate | see RESEARCH § Validation Architecture | n/a | ⬜ pending |
| BOOK-01 / BOOK-19 | Shell exit plan per action × source tab; Past segment | unit | `HomeShellExitTests` (+ `HomeNavigationPathTests`) | ❌ W0 | ⬜ pending |
| BOOK-02 | Stale month response never overwrites the newer month | unit | `MakeABookingAvailabilityTests` (+ `ReloadGenerationTests`) | ❌ W0 | ⬜ pending |
| BOOK-03 / BOOK-04 / D-18 | Zone name (slots card and Today's Sessions); 12/24-hour short time; shared helper | unit + grep gate | `SlotTimeFormatTests`; `ExploreTodaysSessionsSection.swift` calls `DateUtil.zoneName()` | ❌ W0 | ⬜ pending |
| BOOK-05 | "Loading booking…" copy | grep gate | `BookingRequestSentView.swift` contains `Loading booking…` | n/a | ⬜ pending |
| EXPL-01 / EXPL-05 | 404 → not-found; transport → retry; `is_favorite` drives the heart | unit (stubbed) | `ExpertProfileViewModelTests` | ❌ W0 | ⬜ pending |
| EXPL-02 | Empty sections hidden | unit | `ExpertProfileSectionsTests` | ❌ W0 | ⬜ pending |
| EXPL-03 / EXPL-07 | Free label, failed-load text | unit (existing) | `ClientHomeFeedTests` | ✅ | ⬜ pending |
| EXPL-04 | Pills not truncated; shared flow layout places fitting subviews as before, wraps overflowing ones | grep gate + unit | `SearchExpertCard.swift` has no `lineLimit(1)`; `TopicsSetupFlowLayoutTests` | ❌ W0 | ⬜ pending |
| EXPL-05 / EXPL-06 | Shared paging: append, dedupe, stop on `has_more` | unit | `PagedListTests` | ❌ W0 | ⬜ pending |
| EXPL-05 | Favorites paging, refresh, later-page error | unit (stubbed) | `FavoritesViewModelPagingTests` | ❌ W0 | ⬜ pending |
| EXPL-06 | Reviews paging beyond 20 | unit (stubbed) | `ExpertReviewsViewModelPagingTests` | ❌ W0 | ⬜ pending |
| D-13 | Suspended cold launch → Login with message | unit | `AutoLoginOutcomeTests`, `SuspensionNoticeTests` | ❌ W0 | ⬜ pending |
| D-12 | `payment_method.detached` evicts clones; sweep refuses a detached card | backend jest | backend command | extend existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Pure types and suites: `PaymentSheetOutcome`, `ConfirmOutcome`, `ConfirmRetryPolicy`, `ErrorCode.paymentInProgress`, `PagedList`, `HomeShellExit`, `PaymentLifecycleVariant`, `AutoLoginOutcome`, `UnconfirmedBookingLedger`, `DateUtil` short-time / zone-name helpers, `TopicsSetupFlowLayout` math helpers
- [ ] New suites listed in the map above
- [ ] Paging and 404 fixtures under `ClickMe2026Tests/Fixtures/` (or inline JSON, as `ClientHomeFeedTests` does)
- [ ] Test seams: `ExpertReview.serverId`, `ExpertProfileView.init(isFavorited:)`
- [ ] No framework install needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Closing the sheet places no hold | PAY-01 | Live Stripe | D-11 session: close with a saved card preselected; no `requires_capture` PI in the Dashboard |
| Forced timeout then retry lands on Request Sent | PAY-02 | Live network + BACK-15 replay | D-11 session: airplane mode during "Confirming…", then restore |
| Card removed in the sheet can't be charged | D-12 | Live Stripe webhook | D-11 session, after the D-12 deploy |
| Deferred real-Stripe checklists 01-17, 01-19 | BACK-06/07/15/19 | Live Stripe | D-11 session; release or refund every hold before ending |
| Variant A card on a live hold | PAY-03 | Live hold | D-11 session |
| Back hidden; edge swipe doesn't pop from each source tab | BOOK-01 | Gesture | Device |
| 12/24-hour toggle while running | BOOK-04 | System setting | Device |
| Zone name in words on the slots card and Today's Sessions | BOOK-03 / D-18 | Device locale and zone | Device |
| Empty profile sections on a real profile | EXPL-02 | LIKELY item | Device, before the fix |
| Free label; topic load failure | EXPL-03 / EXPL-07 | Built in quick 261109-323 | Device |
| Android push prompt after reinstall | D-14 | Check only | Android device |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
