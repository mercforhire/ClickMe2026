---
phase: 08-release
plan: "22"
subsystem: release
tags: [release, regression, testflight, rel-01, d-04, d-06, d-09, d-27, d-28, d-33]
status: complete

requires:
  - phase: 08
    provides: "08-18 backend frozen at 1d18aac; 08-19 zero code findings in Phases 3 and 4; 08-20 candidate 1fdcc26 = tag v1.1, TestFlight 1.1 (7)"
provides:
  - "## Regression results in 08-RELEASE-RECORD.md (R1-R11 in checklist order, then A1-A17), build 1.1 (7), and the sign-off line"
  - "BACK-06, BACK-07, BACK-19 and the 17 Phase 4 rows ticked in REQUIREMENTS.md with their trace rows Complete, so 08-23's What's New source gate reads real ticks"
  - "D-33 recorded (08-CONTEXT.md, release record) and the 08-22 Task 3 gate amended to accept WAIVED (D-33) for R1 and R2 only"
affects: [08-23, 08-24]

actuals:
  tokens: 6100
  tasks: 3
  commits: 3

plan_head_before: 98d9d87949621aafeb617cf409fcfa06a9120cbb
plan_head_after: 3259a6cadf4559222b5d54e37d2fc66a0434ec92
commits: 3

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - ".planning/phases/08-release/08-22-SUMMARY.md"
  modified:
    - ".planning/phases/08-release/08-CONTEXT.md"
    - ".planning/phases/08-release/08-REGRESSION-CHECKLIST.md"
    - ".planning/phases/08-release/08-RELEASE-RECORD.md"
    - ".planning/phases/08-release/08-22-PLAN.md"
    - ".planning/REQUIREMENTS.md"

key-decisions:
  - "D-33 (user, 2026-11-23, verbatim \"Run short ones, waive overtime (Recommended)\"): for build 1.1 (7), R1's overtime steps and R2 are waived on CallOvertimePolicyTests, code review, the Phase 2 device run (end + 11) and R1's paid-path PASS; R3's short run is accepted the same way"
  - "Regression on TestFlight 1.1 (7) signed off 2026-11-23: R3-R11 PASS, R1 and R2 WAIVED (D-33); BACK-06/07/19 and the 17 Phase 4 rows closed, none deferred, no D-03 blocker"

requirements-completed: [BACK-06, BACK-07, BACK-19, BOOK-01, BOOK-02, BOOK-03, BOOK-04, BOOK-05, BOOK-19, PAY-01, PAY-02, PAY-03, PAY-04, EXPL-01, EXPL-02, EXPL-03, EXPL-04, EXPL-05, EXPL-06, EXPL-07]

duration: about 30 min (Task 3; the user ran Task 2 on 2026-11-23)
completed: 2026-11-23
---

# Phase 8 Plan 22: TestFlight Regression on 1.1 (7) Summary

**The user ran the regression on TestFlight 1.1 (7) against the frozen backend `1d18aac`. R3 to R11 passed. R1's overtime steps and all of R2 were waived under the new decision D-33. Plan 08-22 recorded the results and the sign-off line, and closed BACK-06, BACK-07, BACK-19 and all 17 Phase 4 rows on their evidence.**

## Performance

- **Duration:** about 30 min for Task 3 (the regression itself was the user's run on 2026-11-23)
- **Completed:** 2026-11-23
- **Tasks:** 3 of 3 (Task 1 pre-flight and Task 2 device run by the orchestrator and the user; Task 3 here)
- **Files modified:** 5

## Pre-flight (Task 1, run by the orchestrator on 2026-11-23)

- Frozen SHA: `Backend frozen at 1d18aac (1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594)`. /health reported `1d18aac` at the pre-flight and again just before Task 3.
- Candidate SHA: tag `v1.1` peels to `1fdcc26`, which is in the release record's `## Build`. Every gating Result line was empty on the first run.

## Regression (Task 2, the user, 2026-11-23)

- The user installed TestFlight build 1.1 (7) and reported no other build number.
- The orchestrator wrote each R1 to R11 Result line from the user's chat replies, in commits `e67896e`, `2b3381d`, `c548612`, `0f8e1e2`, `8e2beb8`, `5ac3805` and `98d9d87`. This plan did not change the substance of any of those lines.
- PASS: R3 (short run), R4, R5, R6 (pi ...VoLGAu Canceled), R7, R8 (iOS), R9, R10, R11 (S1 pi ...QJ0AJ8, one Succeeded capture of CA$5.00, nothing else held or charged).
- R1 was SKIPPED in part. The paid in-app path passed and the user ended the call at end + 2, so end + 10, the end + 55 notice, the end + 60 auto-end and the Android teardown at the auto-end were not run. R2 was SKIPPED. Under D-33 both lines now start with `WAIVED (D-33)`, with the rest of each line kept word for word.

## Accomplishments

- D-33 was added to the decisions in 08-CONTEXT.md, and a D-33 line was added to the release record under `## Closed on non-device evidence`.
- `## Regression results` now lists R1 to R11, then A1 to A17, with each Result copied word for word from the checklist. It also gives the build (1.1 (7)), the frozen backend and the sign-off line `Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)`.
- Requirement closures (REQUIREMENTS.md, with trace rows set to Complete):
  - **BACK-06**: closed on R4 PASS.
  - **BACK-07**: closed on R5 PASS. Q2 returned the clone before the card was removed, and the count was 0 afterwards.
  - **BACK-19**: closed on R6 PASS (hold release on a device) plus the mocked captured-refund tests (D-27).
  - **BOOK-01 [major]**: truths 3 and 4. The swipe lock (04-UAT test 6) is device-only and replaced by D-01.
  - **BOOK-02**: truth 7, MakeABookingAvailabilityTests.
  - **BOOK-03** and **BOOK-04**: truth 8, SlotTimeFormatTests. BOOK-04's 12/24-hour toggle is replaced by D-01.
  - **BOOK-05** and **PAY-03**: truth 5, PaymentLifecycleVariantTests.
  - **BOOK-19**: truth 6, HomeShellExitTests.
  - **PAY-01 [major]**: truth 1, plus 04-UAT test 1 pass (D-11 step a).
  - **PAY-02 [major]**: truths 2 and 19, MakeABookingPaidFlowTests, plus 04-UAT test 1 pass (D-11 step d). No R item is cited, because R1 recorded no confirm timeout (D-08). The note ends with the required clause that the 3DS retry was covered by unit tests only, naming both MakeABookingPaidFlowTests tests.
  - **PAY-04**: truth 18.
  - **EXPL-01 [major]**: truth 9. Its WR-02 caveat was superseded by WR-09, fixed in aed0c22.
  - **EXPL-02**: truth 10, ExpertProfileSectionsTests.
  - **EXPL-03**: truth 11, ClientHomeFeedTests, plus 04-UAT test 4 pass.
  - **EXPL-04**: truth 12, TopicsSetupFlowLayoutTests.
  - **EXPL-05 [major]**: truths 13 and 14, FavoritesViewModelPagingTests. Its WR-05 caveat was superseded by WR-11, fixed in 753da57.
  - **EXPL-06**: truth 15, ExpertReviewsViewModelPagingTests.
  - **EXPL-07 [major]**: truths 16, 20 and 21, ClientHomeFeedTests, plus 04-UAT test 5 pass (the G-04-3 re-test, which resolves test 3's issue).
  - No Phase 4 row was deferred and there is no `## Release blockers (D-03)`. Every row's 08-19 classification has no code finding, and no 04-UAT test for any of them is an unresolved issue.
- REL-01 and REL-02 are not ticked. Only 08-24 may tick them.

## Task Commits

1. **D-33 and the Task 3 gate amendment**: `e29300e` (docs)
2. **Check 1 false positive fix**: `089d373` (fix)
3. **Task 3: regression record and requirement closures**: `3259a6c` (docs)

The Task 2 Result lines were committed earlier by the orchestrator (`e67896e` .. `98d9d87`).

## Plan amendments (2026-11-23, D-33)

- **08-22-PLAN.md**:
  - An `<amendment>` element was added to Task 3.
  - The must_haves truth on sign-off, Task 3's action, the first acceptance criterion and `<done>` now accept `WAIVED (D-33)` for R1 and R2 only.
  - Check 1 tags each Result line with its item, and allows `^R[12] Result: *WAIVED \(D-33\)` both as a valid status and as passing.
  - Check 2 does not count R1 or R2 as bad when the line starts with `WAIVED (D-33)`.
  - Check 3 is unchanged, because it reads only the sign-off line, which still contains "gating items R1-R11 PASS".
  - Negative tests on scratch copies: `WAIVED (D-33)` on R3 fails checks 1 and 2, and a leading `SKIPPED` on R1 fails both.
- **08-23-PLAN.md**: not changed. Its only regression check is `grep -q '^Regression signed off'`, which the new line meets.
- **08-24-PLAN.md**: not changed. Task 1 reads only the R4, R5 and R6 Results (all PASS) and Task 2 does not read Result lines, so neither rejects `WAIVED (D-33)`.

## Verification (Task 3 automated checks, run from scripts in the scratchpad with identical logic)

- Check 1 (record integrity): exit 0. The first run failed on a false positive (see Deviations). It passed after the fix.
- Check 2 (release gate): exit 0.
- Check 3 (requirement closure): exit 0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Check 1's `pm_` pattern matched the table name `connected_pm_clones`**
- **Found during:** Task 3, first run of check 1
- **Issue:** `pm_[A-Za-z0-9]{6,}` matched `connected_pm_clones` in the checklist's own Q2 query and in R5 step 7. Those lines have been in the checklist since it was written, so check 1 could never pass whatever the results were.
- **Fix:** the pattern is now `(^|[^A-Za-z0-9_])pm_[A-Za-z0-9]{6,}`. A test with a made-up id confirmed it still rejects a `pm_` id shape at the start of a line, after a space and inside backticks. The user's SQL was not changed.
- **Files modified:** .planning/phases/08-release/08-22-PLAN.md
- **Commit:** `089d373`

**2. Plan amendment by user decision (D-33)**, as directed: described above under Plan amendments.

## For plan 08-24 (rulings and records needed)

- **Android CA$ bug (R8):** on the Android dev build the CAD price has no `CA$` prefix (Android `Money.pinnedSymbol` path, todo `2026-11-23-android-cad-price-missing-ca-prefix`). iOS passed R8 and Android Delete Account passed. The fault is not in the iOS build, so it does not gate the iOS submission, but 08-24 still needs to record a ruling on it.
- **U4 flash decision (R10):** KEEP (user, 2026-11-23).
- **R10 slow-network pass:** SKIPPED (not run), recorded inside R10's PASS line.
- **R1's Android teardown observation (D-28):** Android hung up when the call was ended by hand. The teardown at the end + 60 auto-end was not observed and is waived under D-33.
- **New 1.2 todos:** `2026-11-23-shorten-call-overtime-to-15-minutes` (iOS and Android, behind D-33) and `2026-11-23-add-an-in-app-guide-before-expert-stripe-payout-setup` (user choice "In-app, next release").
- **Phase 3 WR-01 PAID-label acceptance:** 08-19 left this for 08-24, and it is still open.

## Issues Encountered

None beyond the check 1 false positive.

## User Setup Required

None.

## Next Phase Readiness

- 08-23 can start: the release record has the sign-off line and no `## D-09 routing` or `## Release blockers (D-03)`. BACK-06, BACK-07, BACK-19 and the Phase 4 rows are ticked for its What's New source gate.
- No backend or Android repo change was made, nothing was pushed, and no production SQL was run.

## Self-Check: PASSED

- FOUND: .planning/phases/08-release/08-22-SUMMARY.md, 08-RELEASE-RECORD.md (`## Regression results` and the sign-off line), 08-CONTEXT.md (D-33), REQUIREMENTS.md (20 rows ticked, 20 trace rows Complete)
- FOUND commits: e29300e, 089d373, 3259a6c (ancestors of HEAD)
- REL-01 and REL-02 still unticked. No `pm_` id, full `pi_` id, client secret or card number in the checklist, the record, REQUIREMENTS.md or this summary.
