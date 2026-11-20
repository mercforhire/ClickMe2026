---
phase: 08-release
plan: "26"
subsystem: android-parity
tags: [android, parity, todos, user-decision, gap-closure, planning-only]

requires:
  - phase: 08
    provides: "Plan 08-12: the `## Phase 8 answers` sections in the Phase 5 and Phase 6 parity todos (16 lines: 6 differs and 1 device-check row; STATE.md's 08-12 decision says 2 device rows, the todo files hold 1)"
provides:
  - "`## Phase 8 decisions` in both parity todos: 7 decision lines, one per differs or device-check row (6 port requests, 1 closed with its device step in the regression checklist Android section)"
  - "Both todos stay in .planning/todos/pending/ because P1-P6 are requested Android ports that have not landed"
  - "`## Port requested (gap closure)` below, the input for /gsd-plan-phase 08 --gaps"
affects: [08-24, android-release, 08-REGRESSION-CHECKLIST]

actuals:
  tokens: 1500
  tasks: 3
  commits: 2

# commits is measured: git rev-list --count 6805adf..HEAD before this SUMMARY commit.
# Planning documents only; the plan's two task commits are in the iOS repo.
commits: 2
plan_head_before: 6805adfb0c7f058652a48e6b7373b31e22a817e4
plan_head_after: affed363853d911bdcf11dbbc8015f6aa33c7836

tech-stack:
  added: []
  patterns:
    - "A parity difference is closed only by the user's own reply, written one line per row with the date; a requested port keeps its todo in pending/ until the gap plan that lands it rewrites the line to `ported (<Android SHA>)`"

key-files:
  created:
    - ".planning/phases/08-release/08-26-SUMMARY.md"
  modified:
    - ".planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md"
    - ".planning/todos/pending/2026-11-13-android-phase-5-parity-check.md"

key-decisions:
  - "P1-P6 are port requests (user, 2026-11-20), read from the message 'Since the iOS store review has still not been completed, let's continue to do the Android fixes.'"
  - "P7 (Expert-mode gate and Not now, device check needed) is closed now, by the user's own answer of 2026-11-20 to a separate question; its device step runs in the Android section of 08-REGRESSION-CHECKLIST.md and a difference found there becomes a new todo"
  - "No row was deferred or accepted as intended, so no deferred-differences todo exists"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Every differs and device-check row from plan 08-12 has exactly one dated decision line from the user in its todo (7 of 7)"
    requirement: REL-02
    verification:
      - kind: other
        ref: "the plan's Task 3 verify command: t=7 d=7 a=7, both todos in exactly one folder, pending ones carry an open decision"
        status: pass
    human_judgment: false
  - id: D2
    description: "The requested Android ports P1-P6 are written out with their evidence so /gsd-plan-phase 08 --gaps can plan them"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Whether the evidence below is complete enough to plan from is judged by the gap planner; no test can assert it"

# Metrics
duration: 2 sessions (Task 1 and the partial Task 2 in the first, the P7 reply and close-out in this one)
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 26: Android parity decisions Summary

**Seven remaining Android parity rows decided by the user: six requested as Android ports (one of them a data-loss bug in Settings language save), one closed with its device step in the regression checklist; both parity todos stay pending until the ports land.**

## Performance

- **Duration:** two sessions, no code built or run (planning documents only)
- **Started:** 2026-11-20 (first session)
- **Completed:** 2026-11-20T05:37Z
- **Tasks:** 3
- **Files modified:** 2 todos in the iOS repo, plus this SUMMARY

## Decision list (Task 1)

Numbered in file order, Phase 6 todo first. P5 is the highest priority because it loses data.

| # | Todo | Row | What Android does, per plan 08-12 |
|---|------|-----|-----------------------------------|
| P1 | Phase 6 follow-ups | item 2 Off-grid stored time | differs: a stored 09:15 or 24:00 opens as a selected row, as on iOS, but once the expert taps another row that off-grid or 24:00 row leaves the list on Android (`AvailabilityScheduleLogic.startOptions/endOptions` keep only the current draft value), while iOS keeps it as a row for as long as the sheet is open |
| P2 | Phase 6 follow-ups | item 4 Client hub online dot | differs: the Android client Profile hub shows no online dot on the avatar, while the iOS client hub keeps its green dot (user decision U2, 2026-11-16) |
| P3 | Phase 5 parity check | Photo required to publish | differs: Android disables Publish and shows "Still needed: profile picture."; iOS leaves the button usable and refuses with "Finish these first: Add profile picture." |
| P4 | Phase 5 parity check | Feedback minimum | differs: same rule as iOS, different message: "Please describe your experience in at least 10 characters." vs "Please enter at least 10 characters." |
| P5 | Phase 5 parity check | Settings language save | differs: Done with nothing selected sends an empty list and the server deletes every language; iOS keeps the previous list and shows "Keep at least one language." |
| P6 | Phase 5 parity check | Resume keeps the verified email | differs: `SignupSetupRepository.mergeStatus` overwrites the local flag from `GET /auth/email/status`, so a stale "not verified" answer could untick Verify email; iOS never downgrades a local success |
| P7 | Phase 5 parity check | Expert-mode gate and Not now | device check needed: unfinished expert account, expert-targeted push opens the notifications list not the hub; push for the other mode during a call waits until it ends with no mode switch; a client-only account stays client-only after relaunch and foreground |

The 9 other answered rows (Phase 6 items 1 and 3, and 7 Phase 5 rows) matched or were aligned by plan 08-12 and needed no decision.

## Decisions (Task 2, user replies)

| # | Decision | Source |
|---|----------|--------|
| P1-P6 | port requested | the user's message of 2026-11-20 about continuing the Android fixes while the iOS store review is still open (recorded in commit `d20f1dd`) |
| P7 | closed, device step in the regression checklist Android section | the user's own answer of 2026-11-20 to "should its todo close now or stay open until the device check": close |

## Port requested (gap closure)

Run `/gsd-plan-phase 08 --gaps` to plan these. Plan 08-24 will not close Phase 8 while any of them has not landed, because plan 08-24's folded-todo gate treats a parity todo with an unlanded port as having no outcome. iOS is the source of truth; the iOS plan that defines each behavior is in brackets. Android paths are under `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/`. The gap plan that lands a port rewrites its decision line to `ported (<Android SHA>)` and closes the todo once every line in it is ported.

1. **P5 - Settings language save (iOS 05-09, SET-01, UI-SPEC A9). DATA LOSS, highest priority.**
   - Difference: Done with no language selected sends an empty `language_ids`; the backend accepts it and deletes every language row. iOS never applies or sends a zero-language Done: it keeps the previous list and shows "Keep at least one language."
   - Android files: `screens/clientmode/profile/` `ClientProfileSettingsViewModel.applyLanguages` and `screens/expertmode/` `ExpertProfileSettingsViewModel.applyLanguages` (no zero-language guard in either).

2. **P6 - Resume keeps the verified email (iOS 05-11, SIGN-02).**
   - Difference: the setup hub re-reads `GET /auth/email/status` on every appearance (`SignupOverviewViewModel.onShown`), but `SignupSetupRepository.mergeStatus` overwrites the local flag, so a stale "not verified" answer can untick Verify email. iOS treats the endpoint as the only seed and never downgrades a local success.
   - Android files: `SignupSetupRepository.mergeStatus`, `SignupOverviewViewModel.onShown`.

3. **P3 - Photo required to publish (iOS 05-04, SIGN-01).**
   - Difference: Android disables Publish and shows "Still needed: profile picture."; iOS keeps the button usable and refuses with "Finish these first: Add profile picture." with no request sent.
   - Android files: `SignupDraft.missingForPublish`, `SignupReviewScreen` (under `screens/signup`).

4. **P4 - Feedback minimum (iOS 05-05, SET-05).**
   - Difference: message text only. Android "Please describe your experience in at least 10 characters." vs iOS "Please enter at least 10 characters."
   - Android file: `res/values/strings_feedback.xml` line 20.

5. **P1 - Off-grid stored time (iOS 06-03, D-08).**
   - Difference: iOS keeps a stored off-grid time (for example 09:15) or a stored 24:00 end as a row while the time-range sheet is open, even after the expert taps another row. Android keeps only the current draft value, so the stored row disappears once another row is tapped.
   - Android files: `screens/expertmode/availability/AvailabilityScheduleLogic.kt` (`startOptions`, `endOptions`), `screens/expertmode/availability/subviews/TimeRangePickerSheet.kt`.

6. **P2 - Client hub online dot (iOS 06-06, U2).**
   - Difference: iOS keeps the green online dot on the client Profile hub avatar (user decision 2026-11-16); the Android client hub shows none and nothing in `screens/clientmode/profile` reads online or presence.
   - Android files: `screens/clientmode/profile/ClientProfileHomeScreen.kt`, `ClientProfileHomeViewModel.kt`, `subviews/ProfileHubComponents.kt`.

## Task Commits

1. **Task 1: Tracer, decision list P1..P7** - no commit (read-only; `/tmp/08-26-answers.txt` held 16 lines and `/tmp/08-26-decisions.txt` held 7, re-verified before resuming)
2. **Task 2: Decide each remaining difference** - checkpoint answered by the user; P1-P6 recorded in `d20f1dd`, P7 in `affed36`
3. **Task 3: Record the decisions** - `d20f1dd` and `affed36` (both `docs`, the todo files only)

**Plan metadata:** the commit that adds this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `.planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md` - `## Phase 8 decisions`: P1 and P2 port requested
- `.planning/todos/pending/2026-11-13-android-phase-5-parity-check.md` - `## Phase 8 decisions`: P3-P6 port requested, P7 closed with its device step in the regression checklist Android section
- `.planning/phases/08-release/08-26-SUMMARY.md` - this file

## Decisions Made

See key-decisions. Both todos stay in pending/ and no `.planning/todos/pending/2026-11-19-android-deferred-parity-differences.md` was created, because nothing was deferred.

## Deviations from Plan

None - plan executed exactly as written. Two points of record, neither a deviation:

- The plan's Task 2 expects one reply of the form "P1 port, ...". The user answered P1-P6 with a single message about continuing the Android fixes and P7 with a separate reply; each is written as the user gave it, and nothing was inferred beyond reading that message as a port request for each `differs` row.
- Task 3's verify passed on the final state: 7 decision lines against 7 differs and device-check rows, both todos in exactly one folder, each pending todo carrying an open decision.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Gap closure needed before Phase 8 closes:** run `/gsd-plan-phase 08 --gaps` for P1-P6 above. Plan 08-24 stops on the two parity todos while those lines read `port requested`.
- **P7 device step:** `.planning/phases/08-release/08-REGRESSION-CHECKLIST.md` did not exist when this plan ran (plan 08-15 creates it). Its Android section must include the three Expert-mode gate and Not now steps (expert-targeted push for an unfinished expert account, a push for the other mode during a call, a client-only account relaunched and foregrounded), because the user closed the row on that basis.
- No Android code was changed, nothing was pushed, and no device result is recorded by this plan.

## Self-Check: PASSED

- Commits `d20f1dd` and `affed36` are on `main` (checked with `git merge-base --is-ancestor`).
- Both parity todos exist in `.planning/todos/pending/` and not in `completed/`, each with a `## Phase 8 decisions` section.
- Task 3 verify command: `t=7 d=7 a=7`, exit 0.
- `.planning/todos/pending/2026-11-19-android-deferred-parity-differences.md` does not exist, as required when nothing is deferred.

---
*Phase: 08-release*
*Completed: 2026-11-20*
