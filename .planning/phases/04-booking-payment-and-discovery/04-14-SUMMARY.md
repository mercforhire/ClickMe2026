---
phase: 04-booking-payment-and-discovery
plan: 14
subsystem: testing
tags: [device-uat, checklist, stripe, real-money-session, d-11, d-14, android-followups, phase-gate]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "Plans 04-01 to 04-13: D-12 live at backend ae3ec1a, every Phase 4 code change, and the device checks each one deferred to this list"
  - phase: 01-backend-fixes
    provides: "The 01-17 (BACK-06, BACK-07, BACK-15) and 01-19 (BACK-19) real-Stripe checklists the D-11 session runs as written"
provides:
  - "04-DEVICE-UAT-CHECKLIST.md: Setup, notes, 20 numbered items and 2 log-if-seen items, the D-11 real-money session (steps a to h with stop conditions and an end-state table), the D-14 Android check, and a map from each item to the requirement and WINDOWS.md entries it answers"
  - "STATE.md: Phase 4 Android follow-ups (logged, not built) and the D-11 blocker with the D-12 deploy SHA"
  - "Phase gate: ClientHomeFeedTests 18 tests in 1 suite, full unit suite 630 tests in 65 suites, and the app builds, all green"
affects: [gsd-verify-work 04, phase-08-release-pass, android-parity]

# Actuals (#2632). Same scale as the plan estimate: chars/4 over the files actually changed
# (checklist 48802 chars + STATE.md diff 2102 chars; this SUMMARY is not counted).
actuals:
  tokens: 12700
  tasks: 3
  commits: 3   # MEASURED: git rev-list --count 560592f..a9dc1e1 = 3, read from the on-disk ledger. The SUMMARY/metadata commit follows and is not counted here.
plan_head_before: 560592f92fdf8d9efe77ec0b7a342a4d352657fd
plan_head_after: a9dc1e1e81b4f8f14c2063b287a8a51559372a74

tech-stack:
  added: []
  patterns:
    - "Device checklist built from SUMMARY human-check lines; every named item is a Markdown heading so the heading-label checks match keys"
    - "Real-money session ordered so that each hold is cancelled and proved gone from Stripe before the next one is placed"

key-files:
  created:
    - .planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md
  modified:
    - .planning/STATE.md

key-decisions:
  - "No requirement is marked complete: EXPL-03, EXPL-07, BACK-06, BACK-07, BACK-15 and BACK-19 stay unchecked in REQUIREMENTS.md until their device items pass (ROADMAP Phase 4 note)"
  - "The checklist states that a confirm replay (BACK-15, backlog 999.2) cannot be observed: the backend replay path writes no log line and the app cannot tell a replay from a first success, so step c is recorded as proving one booking and one hold for the same booking, and Result asks when airplane mode went on"
  - "The 01-17 and 01-19 checklists run as written on the new iOS build; their rollback SHAs (ddfe5bf, d356fdc) are stale because production moved to ae3ec1a, so a stop condition that says to roll back becomes stop and tell Claude"
  - "The open 01-13 decision (a failed confirm with no replay leaves the authorized PaymentIntent unvoided) is carried into the session as stop condition S-A, checked after every forced failure; cancelling an uncaptured payment is the only Dashboard action allowed besides looking"

requirements-completed: []  # DELIBERATELY EMPTY. The plan's requirements are [EXPL-03, EXPL-07]; both were skipped on purpose and stay Pending (see below).
requirements-pending: [EXPL-03, EXPL-07, BACK-06, BACK-07, BACK-15, BACK-19]

coverage:
  - id: D1
    description: "Phase 4 device UAT checklist: EXPL-03 and EXPL-07 items with the migration precondition, every Phase 4 device item, the D-11 real-money session, the D-14 Android check, the judgment items K1/K3/K4/K5 and the log-if-seen items"
    requirement: "EXPL-03, EXPL-07"
    verification:
      - kind: other
        ref: "heading-label check over 39 required keys (plan Task 2 automated verify) returned pass; D-11 steps a to h present in order as #### headings; step h has the end-state table header"
        status: pass
    human_judgment: true
    rationale: "Whether the checklist is complete and safe to run on live Stripe is a judgment the user makes by reading it; the heading check proves the keys exist, not that the steps are right"
  - id: D2
    description: "EXPL-03 and EXPL-07 regression: ClientHomeFeedTests passes"
    requirement: "EXPL-03, EXPL-07"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift (xcodebuild -only-testing:ClickMe2026Tests/ClientHomeFeedTests): Test run with 18 tests in 1 suite passed"
        status: pass
    human_judgment: true
    rationale: "Both requirements close only on a device check (items 1 and 2); the unit run is the regression, not the acceptance"
  - id: D3
    description: "Phase gate: full unit suite green and the app builds"
    verification:
      - kind: unit
        ref: "xcodebuild test -only-testing:ClickMe2026Tests (AuthSmokeTests and SignupSmokeTests skipped, the three non-compiling files excluded): Test run with 630 tests in 65 suites passed"
        status: pass
      - kind: other
        ref: "xcodebuild build -configuration Debug, iPhone 17: BUILD SUCCEEDED; the only warning is the existing AppIntents metadata notice"
        status: pass
    human_judgment: false
  - id: D4
    description: "STATE.md records the Phase 4 Android follow-ups and the D-11 blocker; REQUIREMENTS.md checkboxes for the six pending requirements are still unchecked"
    verification:
      - kind: other
        ref: "grep of STATE.md for 'Android follow-ups from Phase 4' and 'D-11 real-money session not yet run', and of REQUIREMENTS.md for unchecked EXPL-03, EXPL-07 and BACK-07: pass; BACK-06, BACK-15 and BACK-19 also confirmed unchecked"
        status: pass
    human_judgment: false

duration: 12 min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 14: Phase 4 device UAT checklist and phase gate Summary

**One device checklist (20 items, an 8-step real-money session with stop conditions and an end-state table, an Android push check) closes Phase 4's device work; the full suite (630 tests) and the build are green, and no requirement was marked complete.**

## Performance

- **Duration:** 12 min (the start time is approximate: it was not captured at the first tool call and is taken from the first test log)
- **Started:** 2026-11-12T15:20:00Z (approximate)
- **Completed:** 2026-11-12T15:32:00Z
- **Tasks:** 3
- **Files modified:** 2 (one created, one edited), plus this SUMMARY and the state files in the metadata commit

## Accomplishments

- `ClientHomeFeedTests` passes (18 tests in 1 suite), the EXPL-03 and EXPL-07 regression, and the checklist opens with their two device items. Item 1 carries the migration `20261109000000` precondition, which the user checks; Claude touched nothing in production.
- 20 numbered items plus two log-if-seen items cover every Phase 4 plan's deferred device check, every UI-SPEC backstop (T1 to T4, D1 to D4, L5), the planner assumptions K1, K3, K4 and K5 as `KEEP` or `CHANGE` judgments, the EXPL-02 decision record from 04-12, D-13 as PENDING for the Phase 8 release pass, D-14, OQ7 and D-17.
- The D-11 session runs in the plan's order: a close the card sheet with a saved card, b a completed paid booking (and the clone read before the card is removed), c a forced timeout that a retry survives, d retries exhausted then Try again, e Not now then Book Now again, f card removal in the sheet with the webhook delivery and the clone rows as the proof, g the 01-17 and 01-19 checklists as written, h an end-state table that must show every PaymentIntent released or refunded. The paid booking rule from 01-17 (2 to 5 days out, never joined or rescheduled) is stated up front; each hold is cancelled and proved gone from Stripe before the next is placed.
- Full unit suite: **630 tests in 65 suites passed** (Phase 3's last full run was 434 in 49). Build: BUILD SUCCEEDED.
- STATE.md lists the Android follow-ups from Phase 4 and a blocker for the D-11 session with the D-12 deploy SHA.

## Task Commits

1. **Task 1: Tracer, EXPL-03 and EXPL-07 regression and the opening items** - `be95665` (docs)
2. **Task 2: Every Phase 4 device item and the D-11 real-money session** - `cb7915a` (docs)
3. **Task 3: Phase gate, STATE.md follow-ups and blockers** - `a9dc1e1` (docs)

**Plan metadata:** the `docs(04-14): complete ...` commit that carries this SUMMARY, STATE.md and ROADMAP.md.

The tracer's `<verify>` has only `<automated>` checks and the run was not in auto mode, so under `human_verify_mode: end-of-phase` there was no checkpoint: I re-ran its verify (the test run and the heading and precondition grep both passed) and expanded to Task 2.

## Files Created/Modified

- `.planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md` - the checklist (created)
- `.planning/STATE.md` - Android follow-ups from Phase 4 and the D-11 blocker (modified)

## Requirements: skipped on purpose

The plan lists `requirements: [EXPL-03, EXPL-07]`. Per the ROADMAP Phase 4 note and the plan's output instruction, **I did not mark EXPL-03 or EXPL-07 complete**, and the update-requirements step is skipped for them. The same holds for BACK-06, BACK-07, BACK-15 and BACK-19 (D-11). All six are still unchecked in `REQUIREMENTS.md` (verified). They close when their device items pass, as a `/gsd-verify-work 04` decision.

## Decisions Made

See `key-decisions`. In short: nothing is closed by this plan; the replay (BACK-15) is honestly described as unobservable, with the session recording what can be seen; the stale rollback SHAs in the Phase 1 checklists are called out rather than silently reused; and the open 01-13 orphan-hold decision is a stop condition for the session.

## Deviations from Plan

None in the sense of the deviation rules: no bugs, missing functionality or blockers arose, and no code changed.

Additions beyond the plan's list, all in the checklist and none touching code:
- A closing table mapping each item to the requirement and WINDOWS.md entries it answers. It changes no ledger; `WINDOWS.md` was not modified, which matches the plan's `files_modified`.
- Session stop conditions S-A to S-E and a "keep ids out of the repo" rule (only the last six characters of a `pi_` id, never a `pm_` id), taken from the 01-17 and 01-19 stop conditions and the project's privacy canon.
- A caveat on step c: the replay cannot be told from a first success (the backend source has no log on that path, read-only check), so the item records the observable result and the user's timing.

**Total deviations:** 0 auto-fixed. **Impact on plan:** none.

## Issues Encountered

- The plan start time was not captured at the first tool call, so the Performance block says so and gives an approximate start.
- None otherwise. The three suites that do not compile at HEAD (`LoginTests`, `AuthSmokeTests`, `SignupSmokeTests`) stay excluded on the command line, as in every earlier Phase 4 run; that is the existing STATE.md concern, not new.

## Known Stubs

None. Documentation only; no code was added.

## Threat Flags

None. No endpoint, auth path, file access or schema changed. The plan's own threats are handled in the checklist: T-04-32 (a hold left in place) by the ordered session, the booking rule and the end-state table; T-04-33 (Claude touching production) by running only local tests and builds, and by read-only access to the backend repo (which was not modified: its working tree shows only untracked files that predate this plan); T-04-34 (a requirement closed without a device check) by the unchecked assertions above.

## Authentication Gates

None.

## User Setup Required

None for this plan. To run the checklist the user needs: a real iPhone on a build at or after `c6c3470`, accounts A and B with a paid CAD topic priced with cents, a saved real card, the Stripe Dashboard and the Supabase SQL editor, an Android phone for D-14, and confirmation that migration `20261109000000` is applied (item 1) and that `/health` reports a commit containing `ae3ec1a`.

## Next Phase Readiness

- Phase 4 is code-complete: 14 of 14 plans have a SUMMARY. The next step is `/gsd-verify-work 04`, which walks the user through the checklist.
- **Blocked on the user:** the D-11 real-money session. BACK-06, BACK-07, BACK-15, BACK-19, EXPL-03 and EXPL-07 stay Pending until it and items 1 and 2 pass.
- Still open and not changed here: the 01-13 decision about an unvoided PaymentIntent after a failed confirm (the session has a stop condition for it); backend `master` must merge `origin/main` before its next deploy (todo `2026-11-11-merge-d12-into-backend-master.md`); the Phase 2 and Phase 3 device UAT before Phase 8; the D-14 todo file moves to `completed/` only after the user records the Android result.
- Cross-repo: nothing in the backend or Android repos was changed by this plan; the Android items are logged in STATE.md for a later decision.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*

## Self-Check: PASSED

- FOUND: `.planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md`
- FOUND: commits `be95665`, `cb7915a`, `a9dc1e1` (each an ancestor of HEAD)
- Acceptance criteria re-run: Task 1 heading and migration-precondition check pass; Task 2 heading check over all 39 keys passes (and D1, D2, D4 are also in heading labels), steps a to h are `####` headings in order, step h has the table header, and the BOOK-03 item names both Available Time Slots and Today's Sessions; Task 3 checks pass.
- Plan-level verification: `ClientHomeFeedTests` and the full suite pass, and the build succeeds.
- REQUIREMENTS.md: EXPL-03, EXPL-07, BACK-06, BACK-07, BACK-15 and BACK-19 are unchecked.
