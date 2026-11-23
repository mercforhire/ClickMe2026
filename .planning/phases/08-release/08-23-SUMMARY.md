---
phase: 08-release
plan: "23"
subsystem: release
tags: [release, app-store, whats-new, rel-02, d-20, d-21, d-22]
status: complete

requires:
  - phase: 08
    provides: "08-22 regression sign-off on TestFlight 1.1 (7) with the backend frozen at 1d18aac, and the ticked BACK-06/07/19 and Phase 4 rows that the What's New source gate reads"
provides:
  - "## Submission in 08-RELEASE-RECORD.md: pre-submission gate result, the approved What's New text, one Release note sources line per bullet, the App Review notes plan, the App Store Connect steps, and the submission time and status"
  - "1.1 (7) submitted for App Review on 2026-11-23 18:41 EST, status Waiting for Review (the submission evidence 08-24 needs to tick REL-02)"
affects: [08-24]

actuals:
  tokens: 3700
  tasks: 3
  commits: 2

plan_head_before: 31e9fa39da21973e67626ca933117c3fd2e8b16c
plan_head_after: faf7643ab585aef7c1c3cba3232321cb36a88dd4
commits: 2

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - ".planning/phases/08-release/08-23-SUMMARY.md"
  modified:
    - ".planning/phases/08-release/08-RELEASE-RECORD.md"

key-decisions:
  - "D-22: the user approved the What's New text (15 bullets, 2259 characters) and the App Review notes unedited on 2026-11-23, verbatim \"approve\""
  - "1.1 (7) submitted for App Review 2026-11-23 18:41 EST (23:41Z), status Waiting for Review; the 1.0 review notes are reused without the stale Stripe test-card instruction"

requirements-completed: []

duration: about 15 min (Task 1; Tasks 2 and 3 were the user's approval and App Store Connect submission)
completed: 2026-11-23
---

# Phase 8 Plan 23: App Store Submission of 1.1 (7) Summary

**The gate passed: the regression was signed off, production was still on the frozen `1d18aac`, and the privacy and encryption settings were unchanged. Claude drafted the What's New text, and every one of its 15 bullets cites closed or shipped work. The user approved the text unedited and submitted 1.1 (7) for App Review on 2026-11-23 at 18:41 EST, and its status is Waiting for Review.**

## Performance

- **Duration:** about 15 min for Task 1. Task 2 was the user's approval and Task 3 was the user's submission, both on 2026-11-23.
- **Completed:** 2026-11-23
- **Tasks:** 3 of 3 (Task 1 here; Task 2 decision and Task 3 human action by the user)
- **Files modified:** 1 (plus this summary)

## Pre-submission gate (Task 1, 2026-11-23T23:35Z): PASS

- The release record has the line "Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)".
- Production /health reported commit `1d18aac`, equal to the frozen SHA `1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594`.
- `ios-p8-x1` (`412f1aa`) and `ios-p8-x2` (`1d18aac`) are ancestors of production. This was read in the backend D12 worktree with `rev-parse` and `merge-base` only.
- `ClickMe2026/PrivacyInfo.xcprivacy` is unchanged between `a48c664` and `v1.1` (`1fdcc26`), and `ITSAppUsesNonExemptEncryption` is `false`. `Info.plist` is also unchanged over that range.

## Accomplishments

- **What's New:** 15 bullets in plain user language, 2259 characters as pasted, with no requirement, decision or internal ids. It promises nothing deferred: not BACK-08, not BACK-13, and not the 1.2 todos for 15-minute overtime or the Stripe payout guide. The overtime bullet ("up to an hour past the end") describes what the 1.1 code does (CALL-01). It does not mention the end + 55 notice that D-33 left unproven on a device.
- **Release note sources:** each bullet has one line naming its closed source. Together they cite 36 requirement ids, all ticked `- [x]`. They also cite the shipped fixes G-03-1-ITEM1, G-03-1-ITEM1B, D-23, D-24 and D-31, each recorded in an 08 SUMMARY.
- **App Review notes:** the 1.0 notes are reused and the stale Stripe test-card instruction is dropped, because the app takes live payments. `APP_STORE_REVIEW_CHECKLIST.md` section 3 still lists the test card and is not reused. The App Store Connect steps are recorded.
- **Approval (Task 2, D-22):** the user replied "approve" (verbatim) on 2026-11-23, with no edits.
- **Submission (Task 3, D-20, D-21):** the user replied "submitted 2026-11-23 18:41, status Waiting for Reviw" (verbatim). This is recorded as 2026-11-23 18:41 EST (23:41Z), status Waiting for Review; "Reviw" is the user's typo.

## Task Commits

1. **Task 1: gate, What's New draft, sources, review-notes plan:** `8a7e060` (docs)
2. **Task 2: approval:** recorded in the release record and committed with Task 3. The plan names no commit for Task 2.
3. **Task 3: submission record (includes the Task 2 approval line):** `faf7643` (docs)

## Verification

The checks ran from scratchpad scripts with the same logic as the plan's one-liners, because of Bash 3.2. They ran after Task 1, again after the approval line, and again after the submission record.

- Check 1 (gate): exit 0.
- Check 2 (What's New length and ids): exit 0, 2260 characters in the section.
- Check 3 (sources): exit 0. There are 15 source lines for 15 bullets, 36 requirement ids all ticked, and the cited fixes (D-23, D-24, D-31, G-03-1-ITEM1, G-03-1-ITEM1B) are in the shipped set and named in 08 SUMMARYs.
- Task 3 record: `## Submission` has the submission time and "Waiting for Review", and the sign-off line is still present. This also meets 08-24 Task 1's precondition.

## Deviations from Plan

**1. [Transparency] Dropped "read state" from the plan's list of suggested bullet topics**
- **Found during:** Task 1, source cross-check
- **Issue:** CHAT-08, the live Read label, was closed as not reproducible and no fix was made, so 1.1 does not change the read state.
- **Fix:** the messages bullet covers sending, failed, retry and unread counts only (CHAT-01, CHAT-07, BACK-18). The record notes the omission.

**2. Split the general "clearer screens" topic into specific bullets**
- Each bullet (booking, payment, profiles and Explore, signup, notifications, Delete Account, experts) has its own closed sources rather than one broad claim.

**3. Release setting not confirmed separately**
- The user's reply reported only the time and status. The record states the plan's steps (automatic release, no phased release, no external TestFlight group) and notes that the reply did not confirm them separately.

## Known Stubs

None.

## Issues Encountered

None.

## For plan 08-24

- 08-24 can run now. Its Task 1 precondition is the "Regression signed off" line and a submission time under `## Submission`, and both are present. Nothing in the plan waits for App Review approval or the release.
- REL-01 and REL-02 are still unticked, for 08-24 to tick. REL-02's evidence is this submission (2026-11-23 18:41 EST, Waiting for Review).
- 08-24 Task 3's last check compares `git ls-remote origin refs/heads/main` with local `main`. Local `main` is 19 commits ahead of `origin/main` (local tracking ref, not fetched) and nothing has been pushed, so that check needs a push approved by the user (D-26 history scans first).
- If App Review rejects the build, the D-21 one-release rule means a new build number and a new regression ruling. That is outside this plan.

## User Setup Required

None.

## Self-Check: PASSED

- FOUND: .planning/phases/08-release/08-RELEASE-RECORD.md (`## Submission` with the gate, `### What's New`, `### Release note sources`, `### App Review notes`, steps, submission time and status)
- FOUND: .planning/phases/08-release/08-23-SUMMARY.md
- FOUND commits: 8a7e060, faf7643 (ancestors of HEAD)
- REL-01 and REL-02 unticked; no push; no backend or Android change; no production SQL.
