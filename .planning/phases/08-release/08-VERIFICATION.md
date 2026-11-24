---
phase: 08-release
verified: 2026-11-23T21:30:00Z
status: human_needed
score: 4/5 must-haves verified
covered_files:
  - .github/workflows/build.yml
  - .planning/phases/08-release/08-01-PLAN.md
  - .planning/phases/08-release/08-01-SUMMARY.md
  - .planning/phases/08-release/08-02-PLAN.md
  - .planning/phases/08-release/08-02-SUMMARY.md
  - .planning/phases/08-release/08-03-PLAN.md
  - .planning/phases/08-release/08-03-SUMMARY.md
  - .planning/phases/08-release/08-04-PLAN.md
  - .planning/phases/08-release/08-04-SUMMARY.md
  - .planning/phases/08-release/08-05-PLAN.md
  - .planning/phases/08-release/08-05-SUMMARY.md
  - .planning/phases/08-release/08-06-PLAN.md
  - .planning/phases/08-release/08-06-SUMMARY.md
  - .planning/phases/08-release/08-07-PLAN.md
  - .planning/phases/08-release/08-07-SUMMARY.md
  - .planning/phases/08-release/08-08-PLAN.md
  - .planning/phases/08-release/08-08-SUMMARY.md
  - .planning/phases/08-release/08-09-PLAN.md
  - .planning/phases/08-release/08-09-SUMMARY.md
  - .planning/phases/08-release/08-10-PLAN.md
  - .planning/phases/08-release/08-10-SUMMARY.md
  - .planning/phases/08-release/08-11-PLAN.md
  - .planning/phases/08-release/08-11-SUMMARY.md
  - .planning/phases/08-release/08-12-PLAN.md
  - .planning/phases/08-release/08-12-SUMMARY.md
  - .planning/phases/08-release/08-13-PLAN.md
  - .planning/phases/08-release/08-13-SUMMARY.md
  - .planning/phases/08-release/08-14-PLAN.md
  - .planning/phases/08-release/08-14-SUMMARY.md
  - .planning/phases/08-release/08-15-PLAN.md
  - .planning/phases/08-release/08-15-SUMMARY.md
  - .planning/phases/08-release/08-16-PLAN.md
  - .planning/phases/08-release/08-16-SUMMARY.md
  - .planning/phases/08-release/08-17-PLAN.md
  - .planning/phases/08-release/08-17-SUMMARY.md
  - .planning/phases/08-release/08-18-PLAN.md
  - .planning/phases/08-release/08-18-SUMMARY.md
  - .planning/phases/08-release/08-19-PLAN.md
  - .planning/phases/08-release/08-19-SUMMARY.md
  - .planning/phases/08-release/08-20-PLAN.md
  - .planning/phases/08-release/08-20-SUMMARY.md
  - .planning/phases/08-release/08-21-PLAN.md
  - .planning/phases/08-release/08-21-SUMMARY.md
  - .planning/phases/08-release/08-22-PLAN.md
  - .planning/phases/08-release/08-22-SUMMARY.md
  - .planning/phases/08-release/08-23-PLAN.md
  - .planning/phases/08-release/08-23-SUMMARY.md
  - .planning/phases/08-release/08-24-PLAN.md
  - .planning/phases/08-release/08-24-SUMMARY.md
  - .planning/phases/08-release/08-25-PLAN.md
  - .planning/phases/08-release/08-25-SUMMARY.md
  - .planning/phases/08-release/08-26-PLAN.md
  - .planning/phases/08-release/08-26-SUMMARY.md
  - .planning/phases/08-release/08-27-PLAN.md
  - .planning/phases/08-release/08-27-SUMMARY.md
  - .planning/phases/08-release/08-28-PLAN.md
  - .planning/phases/08-release/08-28-SUMMARY.md
  - .planning/phases/08-release/08-29-PLAN.md
  - .planning/phases/08-release/08-29-SUMMARY.md
  - .planning/phases/08-release/08-30-PLAN.md
  - .planning/phases/08-release/08-30-SUMMARY.md
  - .planning/phases/08-release/08-31-PLAN.md
  - .planning/phases/08-release/08-31-SUMMARY.md
  - ClickMe.xcodeproj/project.pbxproj
  - ExportOptions.plist
  - scripts/release-build-check.sh
covered_digest: "v3:sha256:cd99b878db2dcded878be299f75586ea69dd1d8215593e2b749b3e54f1c5d324"
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "Success criterion 1: one TestFlight regression run of the core paths (book, pay, join, run past the scheduled end, and finish) on a real iPhone"
    reason: "D-33: on build 1.1 (7) R1's end + 10, end + 55 notice, end + 60 auto-end and the Android teardown steps, and the whole of R2 (free in-app voice session), were waived. The paid in-app path (book, pay, hold, accept, join, two-way audio, single capture, call ended by hand at end + 2) passed on device. Stand-in evidence: ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift (pure policy), the Phase 2 device run (call still connected at end + 11), and the overtime moving to 15 minutes in 1.2. The auto-end at end + 60 and the Android call.ended teardown were never observed on a device."
    accepted_by: "user (D-33, verbatim 'Run short ones, waive overtime (Recommended)')"
    accepted_at: "2026-11-23"
re_verification: false
human_verification:
  - test: "Confirm in App Store Connect that version 1.1 (7) is still In Review or Waiting for Review, then, when Apple approves, that it reads Ready for Sale / Released and that App Store users can download 1.1"
    expected: "Status moves Waiting for Review -> In Review -> Ready for Sale, and the 1.1 listing is live. If Apple rejects, the phase goal is not met and a new build or a resubmission is needed."
    why_human: "The App Store half of the goal depends on Apple's review, an external event that has not happened yet. App Store Connect is not reachable from the verifier. The submission itself (2026-11-23 18:41 EST, Waiting for Review) and the TestFlight presence of 1.1 (7) are user-reported only."
  - test: "Optional, reversible (D-33): on a TestFlight or released 1.1 (7), run R1's overtime steps (join a paid or free in-app session, stay past the scheduled end, and wait for end + 55 notice and the end + 60 auto-end, with an Android peer watching for call.ended teardown)"
    expected: "The notice appears at end + 55, the iPhone ends the call at end + 60, and the Android peer tears down on call.ended"
    why_human: "Cannot be checked by grep or a single named test: CallOvertimePolicyTests proves the pure function at each offset, but nothing exercises the timer tick in MeetingCallViewModel through to the real Agora teardown. Waived by the user, so it does not block the phase; it is listed so it is not mistaken for tested."
---

# Phase 8: Release Verification Report

**Phase Goal:** One verified iOS build with every fix reaches TestFlight and the App Store, after all backend changes are live in production
**Verified:** 2026-11-23
**Status:** human_needed
**Re-verification:** No, initial verification

## Verdict

The release work is done and what can be checked from the repository and production is correct. The goal is **partially achieved, and the remainder waits on an external event**:

- **TestFlight: achieved.** Build 1.1 (7) was cut from `1fdcc26`, built by CI from the `release/1.1` push, and the user confirmed it on TestFlight and ran the regression on it.
- **App Store: submitted, not released.** The user reports the submission on 2026-11-23 18:41 EST, status "Waiting for Review". Apple has not approved it. The goal's words "reaches ... the App Store" are not yet true. ROADMAP success criterion 4 and REL-02 ask for "submitted to the App Store", and that part is met.

Nothing in the repository contradicts the SUMMARY and release record claims I checked. No FAILED truth was found, so the status is `human_needed`, not `gaps_found`. Do not read this report as App Store release.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: every phase's fixes verified on a real iPhone, with the D-01 amendment, via one TestFlight regression of the core paths | PASSED (override) | Gating items R1-R11 carry a Result and the sign-off line "Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)" is in `08-RELEASE-RECORD.md` line 201. R3 to R11 PASS. R1 passed in part and is `WAIVED (D-33)` for the overtime steps; R2 is `WAIVED (D-33)` in full. This is an accepted user decision, recorded as an override above. Caveat: ROADMAP.md criterion 1 was amended for D-01 but not for D-33, so the ROADMAP text still says "run past the scheduled end". |
| 2 | SC2: every in-scope inventory item closed, closed as not reproducible, or explicitly deferred with a reason | VERIFIED | `REQUIREMENTS.md`: 105 ticked rows; the only unticked rows are BACK-08 (line 136) and BACK-13 (line 141), each with a written deferral reason (D-07, Phase 5 D-04) and repeated under REL-02. REL-01 and REL-02 are ticked, trace rows read Complete (lines 287-288). 03-VERIFICATION.md and 04-VERIFICATION.md read `status: passed` with 6 and 7 overrides; 03-UAT and 04-UAT read `complete`. ROADMAP lists Phases 1-7 as `[x]`. |
| 3 | SC3: every backend change deployed to production before the iOS build is submitted, and the current Android build still works | VERIFIED | Production `/health` read live now: `{"status":"success","commit":"1d18aac"}`, equal to the frozen SHA. In the backend D12 worktree: `ios-p8-x1` = `412f1aa`, `ios-p8-x2` = `1d18aac`, `412f1aa` is an ancestor of `1d18aac`, local `origin/main` = `1d18aac740dd...`, and the log shows all five X1/X2 commits (`5da3976`, `162f1d7`, `0767cf4`, `412f1aa`, `1d18aac`). X1 was pushed 2026-11-20, X2 2026-11-22, the candidate was cut and submitted 2026-11-23, so ordering holds. Backend `master` merge `e36da57` is local-only, as D-17 requires. Android and build 6 smokes after each deploy are user-reported (08-11, 08-18); the verifier cannot re-run them. |
| 4 | SC4: one iOS build with every fix builds cleanly with no new warnings, is on TestFlight, and is submitted | VERIFIED (repo side); external side user-reported | `git ls-remote origin`: `refs/heads/release/1.1` = `1fdcc26edd75...`, tag `v1.1` peels to `1fdcc26`, GitHub `main` = `1c4401f`. `git diff --name-only 1fdcc26 HEAD` outside `.planning/` is empty, so the built source equals what is on `main`. At `1fdcc26`, `project.pbxproj` has `MARKETING_VERSION = 1.1` and `CURRENT_PROJECT_VERSION = 7` on the app target (bundle id `com.uptrendinvestments.clickmeapp`), the test targets keep `1.0`/`1.2.3`; `Environments.plist` is `Production`; `build.yml` triggers on `release/**` pushes and uploads through `-exportArchive`; `ExportOptions.plist` team id is `V68J585TK5`. The record states unit run 1296 tests / 119 suites passed and `release-build-check.sh` NEW WARNINGS 0 on `1fdcc26`; I did not re-run either (see WR-07 caveat below). The `1fdcc26` tree has the `eyJhbGciOi` string only in two test fixtures. That the CI run uploaded, that TestFlight lists 1.1 (7), and that App Review has it are user-reported; the Actions API and App Store Connect are not reachable here. |
| 5 | Phase goal outcome: the build reaches the App Store | UNCERTAIN (waiting on Apple) | Submitted, status "Waiting for Review" (user-reported 2026-11-23 18:41 EST). The version is set to release automatically on approval with Phased Release off (D-21). Approval and release have not happened, and I cannot observe App Store Connect. Routed to human verification. |

**Score:** 4/5 truths verified (truth 1 counted through the accepted override); 0 present-but-behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ClickMe.xcodeproj/project.pbxproj` | Version 1.1, build 7 on the app target | VERIFIED | Read from `1fdcc26`, lines 445-505. |
| `.github/workflows/build.yml` | TestFlight deploy on `release/**` push, project `ClickMe.xcodeproj`, dry-run switch | VERIFIED | Present at `1fdcc26` with all three. |
| `ExportOptions.plist` | Real team id | VERIFIED | `V68J585TK5`. |
| `scripts/release-build-check.sh` | Clean-checkout Release build and no-new-warnings diff | VERIFIED (exists, substantive) | Baseline `a48c664` against candidate; see WR-07 for its limits. |
| `ClickMe2026/Debug/PreviewSecrets.swift` | Tracked, token-free so a clean checkout compiles | VERIFIED | Reads env or a gitignored local file in DEBUG, `nil` in Release. |
| `08-RELEASE-RECORD.md` | Deploys, regression results, submission, closeout | VERIFIED | Present with all sections; claims I could check against git and `/health` matched. |
| `08-REGRESSION-CHECKLIST.md` | One Result line for each of R1-R11 | VERIFIED | R1-R11 each have a Result; A1-A17 empty and non-gating by design. |
| `ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift` | Overtime policy tests (stand-in evidence under D-33) | VERIFIED (exists) | Pins cutoff, warn window, end + 60, 1-second minimum. Policy is a pure function. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `release/1.1` push | `build.yml` upload | `on.push.branches: release/**` | WIRED | Confirmed in the workflow at `1fdcc26`. |
| `v1.1` tag / `release/1.1` tip / built commit | one SHA | `git ls-remote origin` | WIRED | All `1fdcc26`. |
| Regression sign-off line | App Store submission | pre-submission gate | WIRED | Sign-off line exists before the 23:35Z gate and 23:41Z submission (user-reported time). |
| Production `/health` | frozen SHA `1d18aac` | live curl | WIRED | Equal now. |
| `CallOvertimePolicy.action` | call screen tick | `MeetingCallViewModel.swift:570` | WIRED | The policy is called from the view model; the tick-to-teardown path is not exercised on a device (see override). |

### Data-Flow Trace (Level 4)

Not applicable. Phase 8 changed release configuration and process artifacts. The product fixes it ships were verified in Phases 1-7.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Production backend is the frozen SHA | `curl https://clickme-backend-production.up.railway.app/health` | `commit: 1d18aac` | PASS |
| `release/1.1` and `v1.1` equal the built commit | `git ls-remote origin` | `1fdcc26` for both | PASS |
| No app source changed after the cut | `git diff --name-only 1fdcc26 HEAD` excluding `.planning/` | empty | PASS |
| iOS-line backend commits are ancestors of production | `git merge-base --is-ancestor 412f1aa 1d18aac` in the D12 worktree | true | PASS |
| Full unit run, release warnings check | not re-run by the verifier (about 5 GB builds) | record: 1296 tests passed, 0 new warnings | SKIP (taken from the record; see WR-07) |

### Probe Execution

Step 7c: SKIPPED. No probe files are declared by the phase plans (`scripts/` holds only `release-build-check.sh` and `run-smoke-tests.sh`, neither a `probe-*.sh`).

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| REL-01 | 08-15, 08-19, 08-22, 08-24 | Fixes verified on a real iPhone: device UAT where run, unit tests plus code review plus one TestFlight regression for items never run (D-01); VoiceOver removed (D-02) | SATISFIED, with an accepted deviation | Sign-off line present. Unrun items are listed by number under "Not run on device (D-01)" and VoiceOver steps under "Removed and untested (D-02)", never as passed. R1 overtime and R2 waived by user (D-33), carried as an override. |
| REL-02 | 08-01 to 08-18, 08-20, 08-21, 08-23, 08-24, 08-25 to 08-31 | One new iOS build submitted to TestFlight and the App Store, backend deployed first | SATISFIED for "submitted"; release pending Apple | Backend X1/X2 live before the cut and `/health` equals the freeze SHA now. Build cut and tagged; TestFlight and submission are user-reported. BACK-08 and BACK-13 deferred with reasons (D-07). |

No orphaned requirements: `REQUIREMENTS.md` maps only REL-01 and REL-02 to Phase 8 (trace rows 287-288), and both IDs appear in plan frontmatter (08-15 and 08-24 carry both; 08-19 and 08-22 carry REL-01; the rest carry REL-02).

### Anti-Patterns Found

Scan covered the release-surface files changed in this phase. No `TBD`, `FIXME` or `XXX` debt markers in `build.yml`, `ExportOptions.plist` or `release-build-check.sh` were found to block. The 08-REVIEW.md findings are all `open` in `08-REVIEW-DISPOSITION.md` (1 critical, 7 warnings, 7 info). How they bear on this verdict:

| File | Finding | Severity | Bearing on the phase |
|------|---------|----------|----------------------|
| `scripts/run-smoke-tests.sh:32-38` | CR-01: `xcodebuild ... \| xcbeautify 2>/dev/null \|\| cat` exits 0 when the smoke tests fail. I confirmed the lines are unchanged from `1fdcc26`. | Critical (as reviewed) | Real defect, but a developer script. It is not part of the app binary and was not a Phase 8 acceptance gate (the gates were the unit run, `release-build-check.sh` and the device regression). It cannot have produced a false pass in this phase. Not a blocker. Fix before anyone relies on it. |
| `BookingSummaryViewModel.swift:304-311` | WR-01: on a failed review-context fetch, `forceLoad` sets `hasSubmittedReview = false`, so "Leave a Review" can show on an already-reviewed booking. Confirmed in the code. | Warning | This one is in the shipped binary, so "cannot affect the submitted build" is not exact. Impact is a rare, transient-failure cosmetic offer (the review submit would be refused or repeat). Minor, so D-03 allows deferral, but no written deferral reason is recorded yet. |
| `BookingSummaryView.swift` Message Expert Task | WR-02: unstructured Task can open a chat after the user left. | Warning | In the shipped binary; minor surprise navigation. Same D-03 note. |
| `TopicEditorViewModel.swift:408-413` | WR-03: untouched price reuses stored minor units after a currency change. | Warning | Latent: the picker offers only 2-digit currencies today. |
| `build.yml`, `action.yml` | WR-04 to WR-06: no `permissions:`, mutable action tags, manual dispatch uploads by default, secrets inlined in shell, no cleanup. | Warning | Release pipeline hygiene. The upload for 1.1 (7) already happened by the intended path (tag, branch and built commit match). Matters for 1.2 and for the ITMS-90725 Xcode 27 upgrade. |
| `release-build-check.sh:83-91` | WR-07: the warnings gate compares unique normalized lines without counts, so a second identical warning in a file that already has one is invisible. | Warning | This weakens the evidence for "NEW WARNINGS: 0" in SC4. It does not show that a warning exists; I did not re-run the build. Marked as a caveat, not a gap. |
| IN-01 to IN-07 | Hygiene and test-strength items | Info | No bearing. |

None of the 15 findings contradicts a Phase 8 truth or reaches the major-severity bar in D-03, so none is a BLOCKER. They should be given dispositions (fix, or defer with a reason) before the phase is archived, because the disposition file says "open: 15" and the release record already promises the user decides.

### Human Verification Required

#### 1. App Store review outcome

**Test:** In App Store Connect, confirm 1.1 (7) status over the next review cycle, and after approval confirm it is Ready for Sale and downloadable.
**Expected:** Waiting for Review -> In Review -> Ready for Sale; the live listing is 1.1.
**Why human:** External event not yet happened and a system the verifier cannot reach. Also confirms the user-reported TestFlight and submission facts independently of this report.

#### 2. R1 overtime steps (optional, waived by D-33)

**Test:** On 1.1 (7), run a paid or free in-app session past the scheduled end with an Android peer: end + 55 notice, end + 60 auto-end, Android teardown on `call.ended`.
**Expected:** The notice appears, the iPhone ends the call, the peer hangs up.
**Why human:** Needs a real call and waiting about an hour. Reversible and not gating (user decision).

### Gaps Summary

There are no gaps. Every truth the repository and production can show is verified, and the one deviation from the ROADMAP text (the overtime steps and the free in-app session on device) is a recorded user decision, carried as an override.

Items to record, none blocking:

1. **App Store release has not happened.** The phase can be closed as "submitted", but "reaches the App Store" is only true after Apple approves. If the project treats the phase goal literally, hold the final milestone close until approval, and be ready to reopen the phase if Apple rejects.
2. **ROADMAP.md criterion 1 does not mention D-33.** It still says the regression covered "run past the scheduled end". Add the D-33 amendment next to the D-01 one so the contract matches what was done.
3. **ROADMAP.md line 41 shows Phase 8 as `[ ]`.** That is correct until the orchestrator closes the phase.
4. **The review's claim that nothing it found "affects what shipped" is too broad.** CR-01 and WR-04 to WR-07 are tooling, but WR-01, WR-02 and WR-03 are in the shipped app code. All three are low-impact or latent, and fit the 1.2 triage. They need a disposition.
5. **What's New says calls "keep going for up to an hour past the end".** The code does this (`CallOvertimePolicy.cutoff` = 60 minutes, called from `MeetingCallViewModel.swift:570`), and the user approved the text, but the auto-end was never observed on a device and moves to 15 minutes in 1.2.

---

_Verified: 2026-11-23_
_Verifier: Claude (gsd-verifier)_
