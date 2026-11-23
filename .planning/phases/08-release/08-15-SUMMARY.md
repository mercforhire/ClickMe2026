---
phase: 08-release
plan: "15"
subsystem: release-docs
tags: [regression-checklist, release-record, requirements, roadmap, testflight, real-money, d-01, d-02, d-04, d-06, d-27, d-28]

requires:
  - phase: 08
    provides: "08-08 and 08-16 deploy facts (X1 and X2 pushed SHAs and rollback branches), 08-04 release_path ci, 08-01 warning counts"
  - phase: 08
    provides: "08-13 final saved-cards wording, 08-17 Android Delete Account copy and blockers, 08-12/08-25/08-31 Android device-check lists (P1 to P6)"
provides:
  - "08-REGRESSION-CHECKLIST.md: the one TestFlight run on 1.1 (7), items R1 to R11 plus an Android local-build section (A1 to A17, P1 to P6 tagged)"
  - "08-RELEASE-RECORD.md skeleton: Build, Backend deploys (X1 and X2 filled), Warnings, 38 not-run lines, the unit-tests-only line for Phase 4 test 2, removed-and-untested list, non-device closures, deferrals, backlog dispositions"
  - "REQUIREMENTS.md and ROADMAP.md amended for D-01, D-07, D-08 and D-27; BACK-15 ticked and Complete; five backlog dispositions"
affects: [08-18, 08-19, 08-20, 08-22, 08-23, 08-24]

actuals:
  tokens: 15075
  tasks: 3
  commits: 3

commits: 3
plan_head_before: 0c5be7a0aea07d02d0c1f3b5605ab2cdf995edf9
plan_head_after: 00b3724302978931c9b421b6a8bae0a761140f19

tech-stack:
  added: []
  patterns:
    - "Device checklist in the 04 format: one Result line per item, an empty Result means not run, never a pm_ id, client secret or card number, a PaymentIntent by the last six of its pi_ id"

key-files:
  created:
    - ".planning/phases/08-release/08-REGRESSION-CHECKLIST.md"
    - ".planning/phases/08-release/08-RELEASE-RECORD.md"
  modified:
    - ".planning/REQUIREMENTS.md"
    - ".planning/ROADMAP.md"

key-decisions:
  - "R6 (BACK-19 hold release) runs before S1, and R5 (BACK-07 clone detach) runs after S1, because R5 needs the clone S1's payment created and removes the card; the run order is written in the checklist's Rules"
  - "R7 proposes reschedules only on free-topic side bookings and always has them declined, so the rule 'side bookings are never rescheduled' holds: no booking is ever actually rescheduled, and no money is involved"
  - "The in-use block of BACK-07 (01-17 step 5) is checked inside R6 while its hold is live, so no extra hold is needed"
  - "Android half of R7 and R8 needs a dev build at or after e311a74c: the Phase 8 Android commits were local when written; an older Android build records the Android half as SKIPPED, not FAIL"
  - "R9 swaps roles (iPhone signs in as expert B, Android acts as a client on a free request) because the Liquid Glass screens are expert-mode screens"

patterns-established:
  - "Release record lists not-run items by number and never as a result; VoiceOver items live only in the D-02 section"

requirements-completed: []

coverage:
  - id: D1
    description: "A single regression checklist with R1 to R11, each with exactly one Result line, and the Android section with items tagged (P1) to (P6)"
    requirement: REL-01
    verification:
      - kind: other
        ref: "Task 1 automated verify, both blocks, run as separate commands with temp files in the scratchpad: CHECK1_OK, CHECK2_OK; 28 lines start with Result:"
        status: pass
    human_judgment: false
  - id: D2
    description: "Release record has the D-01 list (38 lines), exactly one Phase 4 UAT test 2 line reading 'covered by unit tests only' with both 3DS test titles verified as @Test strings, and the D-02 lines for Phase 3 items 11 and 21"
    requirement: REL-01
    verification:
      - kind: other
        ref: "Task 2 automated verify: counts and greps A_OK to G_OK; count of the plus-regression phrase is exactly 38"
        status: pass
    human_judgment: false
  - id: D3
    description: "REQUIREMENTS.md and ROADMAP.md carry the user-approved amendments; ROADMAP diff touches only criterion 1 and five backlog lines"
    requirement: REL-02
    verification:
      - kind: other
        ref: "Task 3 automated verify VERIFY3_OK; git diff of ROADMAP.md shows 6 insertions and 1 deletion, all in Phase 8 criterion 1 and the 999.1 to 999.5 sections"
        status: pass
    human_judgment: false
  - id: D4
    description: "The checklist is usable on a real device: the step order, the Android build assumption and the R9 role swap work in practice"
    requirement: REL-01
    verification: []
    human_judgment: true
    rationale: "A document cannot prove its own steps are runnable; plan 08-22 is the first real use. The user should read R6, R5 and R9 before the run."

duration: about 40min (start time not captured)
completed: 2026-11-22
status: complete
---

# Phase 8 Plan 15: Regression checklist, release record and the D-01, D-07, D-08, D-27 amendments Summary

**One TestFlight regression checklist (R1 to R11 plus 17 Android checks), a release record that lists 38 not-run items by number, the 3DS/SCA test on its own unit-tests-only line and every removed accessibility step as untested, and the requirement and roadmap text the user approved, all written before the build exists.**

## Performance

- **Duration:** about 40 min (start time was not captured at the beginning of the run)
- **Tasks:** 3 (tracer, then two auto tasks)
- **Files:** 2 created, 2 modified, all under `.planning/`. No source code, no backend, no Android change, nothing pushed.

## Accomplishments

- **Regression checklist** (`08-REGRESSION-CHECKLIST.md`): Setup (build 1.1 (7) internal TestFlight, accounts A, B and C, the frozen backend SHA read from the release record, the recording rule), Rules (one hold at a time, S1 the only capture, side bookings 2 to 5 days out and never joined, a run order), Stop conditions (S-A to S-E adapted from the 04 checklist plus the D-09 routing), Queries (Q1 and Q2 verbatim), and 11 items:
  - R1 S1 paid voice (end + 55 notice, auto-end at end + 60, the Android `call.ended` observation as a note inside R1's one Result line, exactly one capture), R2 S2 free voice, R3 S3 Skype/Zoom on a free topic.
  - R4 BACK-06, R5 BACK-07 (Q2 read before the card is removed, clone shown detached), R6 BACK-19 hold release (D-27: captured-refund branch recorded as not exercised).
  - R7 chat reasons and the reschedule-decline push (D-31), R8 US$ and CA$ plus the saved-cards line, R9 and R10 the D-28 items, R11 the end-state table and queries.
- **Android local-build section** (not gating): A1 to A11 for the Android ports and the "device check needed" steps (chat reasons, US$/CA$, meeting-link clear, empty-name save and 422 alert, remembered email, delete-account email forgotten, delete-account copy and blockers, cancellation policy link, Add hours, Expert-mode gate and Not now, push prompt after reinstall) and A12 to A17 for P1 to P6, copied from 08-31-SUMMARY.md with their `(P1)` to `(P6)` tags and the dedicated-test-account and restore notes (P1 and P5 write to live production).
- **Release record** (`08-RELEASE-RECORD.md`): Build (1.1 (7), `release_path: ci`), Backend deploys (X1 and X2 pushed SHAs, `/health` before and after, rollback branches; smoke for X1 from 08-11, X2 smoke and the freeze left to 08-18), Warnings (baseline 4, candidate 4, new 0), `## Not run on device (D-01)` (Phase 3 items 7 to 24 and Phase 4 tests 6 to 25, 38 lines; items 11 and 21 limited to their functional steps and ending "(VoiceOver step excluded, see D-02)"), one separate line for Phase 4 UAT test 2, `## Removed and untested (D-02)`, non-device closures (BACK-15 D-08, BACK-19 D-27), deferrals (BACK-08, BACK-13, the open review infos with reasons), backlog 999.1 to 999.5, and placeholders for 08-22 and 08-23.
- **Amendments:** REL-01 and ROADMAP Phase 8 criterion 1 reworded with the D-01 amendment (criterion ends "Amended by Phase 8 D-01 (2026-11-19)"); "BACK-08 is deferred past this release (D-07)" with its reason under REL-02 and on the BACK-08 row; BACK-15 ticked with the D-08 reason and its trace row Complete; BACK-19 closes on hold-release evidence plus the mocked captured-refund tests (D-27); BACK-06 and BACK-07 close on the Phase 8 regression evidence (D-06); a "Phase 8 disposition" line under each of 999.1 to 999.5; "Last updated" refreshed.

## Task Commits

1. **Task 1 (tracer): regression checklist** - `a84337c` (docs), one file
2. **Task 2: release record skeleton** - `f108032` (docs), one file
3. **Task 3: REQUIREMENTS.md and ROADMAP.md amendments** - `00b3724` (docs), two files

`git rev-list --count 0c5be7a..HEAD` is 3 before this SUMMARY's own commit. The tracer gate: Task 1's automated verify (both blocks) passed end to end on the committed file before Task 2 started, so the tracer was treated as verified.

## Deviations from Plan

### Auto-fixed Issues

None needed beyond the points below.

### Execution choices to confirm

**1. [Process] Three commits, not one**
- The plan's Task 3 says to commit "the four files" in one commit and its verification says "one commit with the four files". The run instructions say to commit each task atomically, so each task got its own commit with the plan's `docs(08-15)` prefix. The acceptance criterion on the ROADMAP diff still holds: it is in the third commit only and shows only criterion 1 and the five backlog lines.

**2. [Interpretation] "Side bookings are never rescheduled" and R7**
- R7 needs reschedule proposals. The checklist proposes them only on free-topic side bookings and always has them declined (and the cancel at the end), so no booking is ever rescheduled and no hold is touched. A paid side booking is never rescheduled.

**3. [Rule 2 - correctness] Run order and a BACK-07 step added**
- The plan lists R1 to R11 by topic. They cannot be run in that order: R5 removes the card and needs S1's clone, and R4 needs an account with no saved card. The Rules section gives the run order R4, R6, R1, R2, R3, R5, R7, R8, R10, R9, R11. The BACK-07 in-use block (01-17 step 5) is a step inside R6, where a hold is already live.

**4. [Fact] Android build for R7 and R8**
- The plan says the Android peer runs the current Play build. The chat-reason rows and the US$ and CA$ override are in Android commits that were local when this was written, so an older Android build would show nothing new. The Setup section says so and records the Android half as SKIPPED (not FAIL) on an older build. The Android section always needs the dev build.

**5. [Pre-fill] X2 deploy facts**
- The plan leaves X2 and the freeze to 08-18. X2's pushed SHA, `/health` before and after and rollback branch were already in 08-16-SUMMARY.md, so they are filled; its smoke result and the freeze row are left for 08-18.

**6. [Conservative additions to the D-02 list]**
- Beyond the plan's named items, the D-02 section also lists Phase 4 checklist item 3's optional VoiceOver bullet, Phase 7 items 3, 4, 8 and 12 and the IN-04 check, and Phase 6 items 11 and 20. The last two read PASS in their files with no note on whether the VoiceOver sentences were run, so they are recorded as untested rather than assumed passed.

**Total deviations:** 0 rule-based fixes, 6 execution choices above. **Impact:** none on the plan's outputs.

## Issues Encountered

- The plan's Task 1 and Task 2 verify commands write to `/tmp`. They were run as written but with their temporary files in the session scratchpad. All checks passed.
- Early wording slips in the record (the word "pass" after "VoiceOver" on a line) would have tripped the check that no VoiceOver line says pass; three lines were reworded before the commit.
- The Android repo was only read (`git rev-parse`, `git log`). Nothing there was changed.

## Known Stubs

None. The placeholders in the release record ("to be filled by plan 08-18, 08-20, 08-22, 08-23") are by design, each owned by a named later plan.

## Threat Flags

None. T-08-31 to T-08-33 are mitigated as planned: one hold at a time, S1 the only capture, stop conditions and D-09 routing are written before the run, the recording rule forbids `pm_` ids, client secrets and card numbers (a PaymentIntent by its last six characters only), and every not-run or removed item is listed as such, never as passed.

## Things the user should decide or know

1. **Phase 3 item 4** (BOOK-09 status pill) was skipped whole on 2026-11-19 because of VoiceOver. Its non-VoiceOver steps (the real status on the pill, the largest-size look) are not in the D-01 list (items 7 to 24). The release record flags them for plans 08-19 and 08-24 to classify.
2. **Open review findings for Phases 2 and 5** (warnings and infos with no reason recorded) are listed in the release record without invented reasons; plan 08-24 needs your decision on each.
3. **Android dev build.** The regression run needs an Android dev build from `ClickMe_Android` `main` at or after `e311a74c` for the Android half of R7 and R8 and for the whole Android section.
4. **R9 swaps roles** (the iPhone signs in as expert B for the Liquid Glass checks). Read it before the run.
5. **(P2) mentions TalkBack.** It was copied as written from 08-31. The checklist lets you mark the TalkBack part SKIPPED inside the Result line.
6. REL-01 and REL-02 were not marked complete (plan 08-24 ticks them), and no requirement was marked complete here.

## Self-Check: PASSED

- Files exist: `08-REGRESSION-CHECKLIST.md`, `08-RELEASE-RECORD.md`, `08-15-SUMMARY.md`; `REQUIREMENTS.md` and `ROADMAP.md` carry the amendments (verify greps pass).
- Commits `a84337c`, `f108032` and `00b3724` are ancestors of HEAD.
- Nothing pushed; `.DS_Store` files, `.planning/config.json`, `Localizable.xcstrings`, `.planning/milestone.lock` and `.planning/state.json` were never staged.
