---
phase: 08-release
plan: "24"
subsystem: release-docs
tags: [closeout, requirements, verification, overrides, d-01, d-02, d-05, d-33, todos, rel-01, rel-02]
status: complete

requires:
  - phase: 08
    provides: "08-22 regression sign-off and the BACK-06/07/19 and 17 Phase 4 ticks; 08-23 App Store submission of 1.1 (7); 08-19 human-item classification (zero code findings); 08-21 backend merge e36da57; 08-26/08-31 Android ports"
provides:
  - "REL-01 and REL-02 ticked with evidence; trace rows Complete"
  - "03-VERIFICATION.md and 04-VERIFICATION.md status passed with ## Overrides (Phase 8 D-01, D-02) (6 and 7 lines); 03-UAT and 04-UAT complete; ROADMAP Phases 3 and 4 Complete 2026-11-23"
  - "08-RELEASE-RECORD.md ## Closeout: every Phase 8 tick with evidence, the user's closeout rulings verbatim, what stays open, release references, ### Folded todos (14 lines)"
  - "Two new 1.2 todos: PAID label on cancelled/declined/expired rows, triage of the Phase 2 and 5 review findings"
affects: [phase-8-verification, 1.2]

actuals:
  tokens: 7440
  tasks: 3
  commits: 5

commits: 5
plan_head_before: 37f334631c0a6777d6f5484df7618e069e0e58a2
plan_head_after: b06e6418503920146ed272b7625f5061a6302f4b

tech-stack:
  added: []
  patterns:
    - "A user ruling is recorded verbatim with its date; an override line that rests on a product decision says so and never claims the regression covered it"

key-files:
  created:
    - ".planning/todos/pending/2026-11-23-paid-label-on-cancelled-declined-expired-rows.md"
    - ".planning/todos/pending/2026-11-23-triage-phase-2-and-5-review-findings-for-1-2.md"
    - ".planning/phases/08-release/08-24-SUMMARY.md"
  modified:
    - ".planning/REQUIREMENTS.md"
    - ".planning/ROADMAP.md"
    - ".planning/STATE.md"
    - ".planning/phases/08-release/08-RELEASE-RECORD.md"
    - ".planning/phases/08-release/08-24-PLAN.md"
    - ".planning/phases/03-booked-sessions-and-joining/03-UAT.md"
    - ".planning/phases/03-booked-sessions-and-joining/03-VERIFICATION.md"
    - ".planning/phases/04-booking-payment-and-discovery/04-UAT.md"
    - ".planning/phases/04-booking-payment-and-discovery/04-VERIFICATION.md"

key-decisions:
  - "Phase 3 WR-01 PAID label: user ruling 2026-11-23 \"Change it in 1.2 (Recommended)\"; accepted for 1.1 (7), change tracked in todo 2026-11-23-paid-label-on-cancelled-declined-expired-rows"
  - "Phase 2 and Phase 5 open review findings (15): user ruling 2026-11-23 \"Defer all to 1.2 (Recommended)\"; one triage todo"
  - "R8 Android CA$ fault does not gate the iOS submission; open Android follow-up (user: \"Yes, record that\")"
  - "Overrides that close on later device evidence (04 G-04-3, 03 item 27) say so instead of the D-01 not-run wording"

requirements-completed: [REL-01, REL-02]

duration: about 60 min, including the wait for the user's rulings
completed: 2026-11-23
---

# Phase 8 Plan 24: Release closeout Summary

**REL-01 and REL-02 ticked on the signed-off 1.1 (7) regression and the App Store submission, Phases 3 and 4 closed under the D-01 amendment with one override line per human item, and every folded todo given an outcome. The release record's Closeout holds the user's rulings word for word.**

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: REL-01/REL-02 ticks, Phase 3 gaps, release record Closeout | `24489b6` | REQUIREMENTS.md, 03-UAT.md, 08-RELEASE-RECORD.md |
| 2 | D-01 overrides; Phases 3 and 4 leave human_needed | `fda4d40` (Phase 4), `808e6f1` (Phase 3, after the WR-01 ruling) | 04-VERIFICATION.md, 04-UAT.md, 03-VERIFICATION.md, 03-UAT.md, ROADMAP.md |
| 3 | Folded todo outcomes; pre-push gate; push | `8948add` | 08-RELEASE-RECORD.md |
| fix | Task 1 check counts only the three ITEM1 gaps | `b06e641` | 08-24-PLAN.md |

`commits: 5` is `git rev-list --count 37f3346..b06e641`, measured before this SUMMARY's own commit. `808e6f1` also holds the closeout rulings, the two new todos and their STATE.md bullets.

## What was done

- **Requirements.** REL-01 (as amended by D-01) is ticked on the sign-off line "Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)". REL-02 is ticked on the submission of 1.1 (7) on 2026-11-23 at 18:41 EST (Waiting for Review), with backend X1 and X2 live before the cut. Both trace rows read Complete. BACK-06, BACK-07 and BACK-19 (ticked by 08-22) were re-checked against R4, R5 and R6 PASS and left alone. BACK-08 and BACK-13 stay unticked (D-07).
- **Phase 3 gaps.** ITEM1, ITEM1B and ITEM1C were already `resolved`. Their `resolved_by` now names 08-02 and 08-08 (ITEM1, ITEM1C) and 08-02, 08-07 and 08-03 (ITEM1B), and each one carries the R7 device confirmation.
- **Phase 4.** 04-VERIFICATION has 7 override lines and `overrides_applied: 7`, with status `passed`:
  - WR-01 3DS/SCA: "not run on device; covered by unit tests only (user decision 2026-11-19), MakeABookingPaidFlowTests".
  - The item 3 VoiceOver bullet: removed, untested on device (D-02).
  - G-04-3 closes on its 2026-11-13 device pass.
  - 04-UAT is `complete` with the test 2 note, and ROADMAP shows Phase 4 Complete 2026-11-23.
- **Phase 3.** This half waited for the user's WR-01 ruling. 03-VERIFICATION has 6 override lines and `overrides_applied: 6`, with status `passed`:
  - The WR-01 PAID-label line cites the ruling and its todo, not the regression.
  - Item 27 closes on its 2026-11-23 device pass.
  - Truth B4 was reworded so that the functional pass reads before the D-02 note.
  - 03-UAT is `complete`, and ROADMAP shows Phase 3 Complete 2026-11-23.
- **Closeout** (08-RELEASE-RECORD.md) contains:
  - every Phase 8 tick with its evidence: BACK-06, 07, 19, BACK-15, the 17 Phase 4 rows, REL-01 and REL-02
  - "None" for D-03 Phase 4 deferrals
  - the rulings: D-33; R8 as Android-only (user: "Yes, record that"); U4 KEEP; WR-01 ("Change it in 1.2 (Recommended)"); the 15 Phase 2 and 5 review findings, each "deferred to 1.2: not release-blocking, build 7 frozen (user decision 2026-11-23)" ("Defer all to 1.2 (Recommended)")
  - what stays open, including the four 1.2 todos and the Xcode 27 / iOS 27 SDK note (ITMS-90725 on the build 7 upload)
  - release references: tag `v1.1`, backend merge `e36da57`, production `1d18aac`
  - `### Folded todos`
- **Folded todos.** There are 14 lines: 13 are completed and 1 is pending. The Android push-prompt todo stays pending as "device check not run in Phase 8", because A11's Result is empty. Every 08-26 port request (P1 to P6) is on ClickMe_Android `main`; this was checked read-only.

## Verification

All three plan checks were extracted from `08-24-PLAN.md` and run on HEAD `b06e641`, with their `/tmp` files moved to the session scratchpad:

- Task 1: exit 0, after the plan fix below.
- Task 2: exit 0. The 03 and 04 override line counts equal `overrides_applied` (6 and 7).
- Task 3, first check (pre-push gate): exit 0.
  - All 14 todos have an outcome.
  - No JWT-shaped string in `origin/main..HEAD`.
  - Outside `.planning`, the working-tree list is exactly the two fake-JWT fixtures.
  - No tracked `.planning` file holds a JWT-shaped string.
- Task 3, second check (GitHub `main` equals local `main`): runs after the approved push, which follows this SUMMARY's commit, so it is reported to the orchestrator and not recorded here.

## Deviations from Plan

**1. [Rule 1 - Bug] Task 1's gap count could never pass.** The awk check matched every gap_id starting with `G-03-1-ITEM1`, which also catches `G-03-1-ITEM14` (added later by 03-18), so it counted 4 against `-eq 3`. The orchestrator approved a minimal amendment, done the way 08-22 did it: the regex is now `/^G-03-1-ITEM1[BC]?$/`, and an `<amendment>` note sits in Task 1. Commit `b06e641`.

**2. [Accuracy] Two override lines record device evidence instead of "not run on device".** G-04-3 (04-UAT test 5 passed on 2026-11-13) and Phase 3 item 27 (passed on 2026-11-23) were both run on a device after their verifier reports were written. The plan's D-01 wording would have been false for them.

**3. [Process] Task 2 landed in two commits.** Phase 4 was committed first. Phase 3 waited for the user's WR-01 ruling, because the instructions forbade recording it as "covered by regression".

**4. [Check wording] Two lines that tripped the VoiceOver check were reworded.** The plan's `voiceover.*(pass|passed)` check is case-insensitive. One of my 04 intro sentences matched it, and so did the verifier's truth B4 row in 03-VERIFICATION. Both were reworded with no change in meaning, and neither line records a VoiceOver step as passed.

**5. [Scope] The push-prompt todo file was left unchanged.** It stays in pending/ with its reason recorded in the Closeout, so re-running this plan changes nothing.

## Known Stubs

None. Every change is a planning document.

## Threat Flags

None. T-08-52 is mitigated: every tick cites its R result or submission, the overrides cover only device-only items with no code finding, and VoiceOver is never recorded as passed. T-08-53 is mitigated: the pre-push gate ran on the final HEAD before the push, and the push is a single fast-forward with no tags and no release branch.

## Self-Check: PASSED

- FOUND: both new todo files, 08-24-SUMMARY.md, `## Closeout` and `### Folded todos` in 08-RELEASE-RECORD.md, and both Overrides sections.
- FOUND: `24489b6`, `fda4d40`, `8948add`, `808e6f1` and `b06e641` are ancestors of HEAD.
- Never staged: `.DS_Store` files, `.planning/config.json`, `.planning/milestone.lock` and `.planning/state.json`.
