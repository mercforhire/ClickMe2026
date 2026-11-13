---
phase: 05-signup-mode-switch-and-account
plan: 13
subsystem: planning
tags: [device-uat, android-followups, requirements, roadmap, back-13, swift-testing]
status: complete

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: all sixteen code-plan SUMMARYs (05-01 to 05-12 and 05-14 to 05-17) and the approved 05-UI-SPEC
provides:
  - 05-DEVICE-UAT-CHECKLIST.md, 47 device items with Result lines, automated evidence and five KEEP or CHANGE decisions
  - Four Android follow-up todos (delete copy and blockers, remember-login-email, cancellation policy link, Phase 5 parity check)
  - Saved-card decision todo and the flaky MakeABookingAvailabilityTests todo
  - BACK-13 deferral (D-04) recorded in REQUIREMENTS.md and the ROADMAP Phase 5 entry
affects: [/gsd-verify-work 05, Phase 8 release, Android port]

requirements-completed: [SIGN-06, SET-06, SET-07, D-04, D-11, D-12, D-16]

actuals:
  tokens: 16600
  tasks: 3
  commits: 3
plan_head_before: 1f37f5cb8c8448718a30598809d1a219f9d191d3
plan_head_after: 4a070cae93348a995959e683b97a876a399a8538

tech-stack:
  added: []
  patterns:
    - "Todo strings are copied from the Swift constants and checked verbatim by a script (15 of 15 matched), not retyped"

key-files:
  created:
    - .planning/phases/05-signup-mode-switch-and-account/05-DEVICE-UAT-CHECKLIST.md
    - .planning/todos/pending/2026-11-13-android-delete-account-copy-and-blockers.md
    - .planning/todos/pending/2026-11-13-android-remember-login-email.md
    - .planning/todos/pending/2026-11-13-android-cancellation-policy-link.md
    - .planning/todos/pending/2026-11-13-android-phase-5-parity-check.md
    - .planning/todos/pending/2026-11-13-decide-saved-cards-on-account-deletion.md
    - .planning/todos/pending/2026-11-13-flaky-make-a-booking-availability-test.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "This plan ticks no requirement checkbox: SIGN-06, SET-02, SET-06 and SET-07 stay Pending in REQUIREMENTS.md until /gsd-verify-work 05 reads the device results, although requirements.ready-ids reported SIGN-06, SET-06 and SET-07 as ready"
  - "BACK-13 is recorded as deferred past this release (D-04) with the ensureExpert reason under REL-02; BACK-08 keeps its 'needs a new decision' wording"

coverage:
  - id: D1
    description: "The whole phase passes together: full ClickMe2026Tests suite (smoke suites skipped), Debug build, and every phase grep gate on commit 359c721"
    requirement: "SIGN-06"
    verification:
      - kind: command
        ref: "xcodebuild test -only-testing:ClickMe2026Tests (log /tmp/05-13-full.log): Test run with 803 tests in 82 suites passed"
        status: pass
      - kind: command
        ref: "xcodebuild build Debug iPhone 17 (log /tmp/05-13-build.log): BUILD SUCCEEDED, no compiler warning"
        status: pass
      - kind: command
        ref: "/tmp/05-13-gate.sh: no setMode( outside UserManager.swift, no pause references, no ReadyToStart, no LanguageEditorSheet, one support-address file"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every open Phase 5 device check is on one checklist, one item per behavior, with Result lines, and the Phase 2 to 4 partial UATs are named as due before Phase 8"
    requirement: "SIGN-06"
    verification:
      - kind: command
        ref: "/tmp/05-13-gate.sh: 48 'Result:' lines (47 items), '## Automated evidence' present, 20 lines mention SIGN-06"
        status: pass
    human_judgment: true
    rationale: "Whether each behavior actually works on a real iPhone is the user's to run; the checklist only records what to check"
  - id: D3
    description: "D-11, D-12 and D-16 follow-ups hold the final strings and facts: AccountDeletionCopy and AccountDeletionBlocker strings verbatim, CLIENT_HAS_UPCOMING_BOOKINGS mapping, Android branch 0c9ecc55, the policy-link finding"
    requirement: "SET-06"
    verification:
      - kind: command
        ref: "python3 -I /tmp/05-13-verbatim.py: 15 strings checked, 0 missing; /tmp/05-13-gate2.sh: files, key strings, 5 of 5 frontmatter keys per todo, Android status and HEAD unchanged"
        status: pass
    human_judgment: false
  - id: D4
    description: "REQUIREMENTS.md and the ROADMAP Phase 5 entry record BACK-13 as deferred (D-04) with the REL-02 reason, and S2 and T8 as moved into Phase 5"
    requirement: "D-04"
    verification:
      - kind: command
        ref: "/tmp/05-13-gate3.sh: BACK-13 line cites D-04, REL-02 line cites ensureExpert, D-14 recorded, 0 'needs a decision' in the Phase 5 entry, 2 BACK-13 lines point to REL-02; ROADMAP hunks at lines 297 and 344 only"
        status: pass
    human_judgment: false

duration: 17 min
completed: 2026-11-13
---

# Phase 5 Plan 13: Device UAT checklist, follow-up todos and the BACK-13 deferral Summary

**Phase 5 is proved green as a whole (803 tests in 82 suites, clean Debug build, all grep gates), the user has one 47-item device checklist, the Android port has the exact Delete Account strings, and BACK-13's deferral and its REL-02 reason are written down.**

## Performance

- **Duration:** about 17 min (the full suite and the build dominate)
- **Completed:** 2026-11-13T22:52Z
- **Tasks:** 3 (one tracer, two auto)
- **Files:** 10 (7 created, 3 modified)

## Accomplishments

- **Task 1 (tracer).** The full suite ran on commit `359c721`, the last Phase 5 commit that touched app code: `Test run with 803 tests in 82 suites passed`, `TEST SUCCEEDED`, no failure. The Debug build succeeded with no compiler warning (the one `warning:` line is the build system's AppIntents metadata notice). All phase grep gates pass. `05-DEVICE-UAT-CHECKLIST.md` has 47 items, 48 `Result:` lines, an Automated evidence section, and one section each for setup, notes and the summary.
- **Checklist coverage.** The gate (items 1 to 17: hub on incomplete setup, finished and airplane-mode entry, hub chrome on every entry, Not now, deferral across relaunch, asking again, sign-out, Publish, call block on four screens, dimmed cards, push during a call, expert push for an unfinished expert, the foreground re-check and its A6 fallback, client-only account never promoted, no hub over a call), signup (items 18 to 24: photo required, crop on a real photo, tap order, country and optional province, province clear, location label, verified email on resume), settings (items 25 to 33: client and expert language saves, Add languages, the zero-language rule, notification preferences, feedback, Help mail, remembered email and its deletion), account (items 34 to 40, 47: copy on both steps at the largest Dynamic Type, saved-card silence, blocker alert from both shells, dual-role wrong mode, throwaway delete, in-call and session-in-progress) and SET-07 (items 41 to 44: policy link from both cancel entry points with the A5 fallback, corrected copy, link hit area).
- **Decisions put to the user** (KEEP or CHANGE): A9 (settings never saves an empty language list although the backend allows it, item 28, as the orchestrator asked), U3 saved cards (item 36), U2 policy link hit area (item 44), U4 Verify email flash (item 45), A1 Not now style (item 46).
- **Task 2.** Four Android todos and the saved-card todo, plus STATE.md "Android follow-ups from Phase 5" and two captured-todo lines. The delete-copy todo carries every `AccountDeletionCopy` and `AccountDeletionBlocker` string, verified verbatim by script (15 of 15). Android was read only: its status and HEAD are identical before and after.
- **Task 3.** BACK-13's note cites D-04 and says it stays parked on `wave-3c`; REL-02 records the `ensureExpert` reason; the Out of Scope row records S2 (D-05 to D-07) and T8 (D-14) as moved in; the footer is dated. ROADMAP Phase 5 changed on exactly two lines (297 and 344). No checkbox or Traceability status changed.

## Task Commits

1. **Task 1 (tracer): the phase passes together; device checklist written** - `a45d1e3` (docs)
2. **Task 2: Android and saved-card follow-ups logged** - `2b3c073` (docs)
3. **Task 3: BACK-13 deferral, S2 and T8 scope moves** - `4a070ca` (docs)

## Android findings (read-only, 2026-11-13)

- `strings_delete_account.xml` `delete_account_body` still says "All your data, including bookings, profile information, and payment details, will be permanently removed."
- `ErrorCode.kt` already declares `ClientHasUpcomingBookings`, but `DeleteAccountViewModel.onFailure` shows the server message for any 409: no per-code mapping, no bookings button, no mode-aware message.
- No cancellation-policy screen or link under `app/src/main`; the only policy text is the string `cancel_booking_refund_policy`. Android's `cancel_booking_refund_note` still promises "3-5 business days", the claim iOS removed.
- Branch `feature/remember-login-email` holds `0c9ecc55` ("feat(login): pre-fill the last email after sign-out", 2026-11-05) and is not merged.

## Deviations from Plan

### Orchestrator additions

**1. [Addition] Flaky Make a Booking test todo**
- **Source:** orchestrator note 1 (observed during this run).
- **What:** `2026-11-13-flaky-make-a-booking-availability-test.md`, in the existing todo format: `MakeABookingAvailabilityTests` "An older load that lands last writes nothing" (`MakeABookingAvailabilityTests.swift:154`, expected `Zone/2`, got `Zone/1`) failed in 1 of 3 isolated runs and once in a full-suite run during Phase 5, and passed in this plan's full-suite run. Phase 5 did not touch Make a Booking (last edit in Phase 4, plan 04-15). The todo gives a hypothesis (which unstructured `Task` reaches the stub first is unordered), labeled as unconfirmed.
- **Commit:** `2b3c073` (committed with the Task 2 files and listed in STATE.md captured todos).

**2. [Addition] UI-SPEC assumption A9 on the checklist**
- **Source:** orchestrator note 2. Item 28 asks the user to confirm that settings never saves an empty language list.

### Plan reading

**3. [Decision] Requirement boxes not ticked although `requirements.ready-ids` reports them ready**
- **Found during:** the update_requirements step. All sixteen code-plan SUMMARYs now exist, so SIGN-06, SET-06 and SET-07 come back as ready.
- **Decision:** none were marked complete. This plan's must-have truth says it ticks no requirement checkbox and that `/gsd-verify-work 05` decides whether a SIGN or SET item counts as closed before its device check. SIGN-06, SET-02, SET-06 and SET-07 therefore stay Pending in REQUIREMENTS.md (SIGN-01 to SIGN-05, SET-01 and SET-03 to SET-05 were ticked by their own plans). This answers orchestrator note 3: the reconciliation is that nothing is left half-ticked for a reason other than the open device checks.

**Total deviations:** 2 additions, 1 decision. **Impact:** none on scope; no code changed.

## Issues Encountered

- A first draft of two shell checks used a heredoc inside `$(...)`-style one-liners that the shell refused; they were rewritten as script files (`/tmp/05-13-gate.sh`, `-gate2.sh`, `-gate3.sh`). No effect on results.
- The flaky test passed in this run, so the suite count is a clean 803 of 803. It is logged, not fixed (outside this plan's scope).

## Known Stubs

None. No code was written in this plan.

## Threat Flags

None. The checklist and todos contain only UI strings, error codes, file paths and role names. No token, password, card number or real email is recorded (T-05-28 mitigated); no package was installed (T-05-SC).

## Next Phase Readiness

- Phase 5 plan work is done. Next: run the device checklist (`05-DEVICE-UAT-CHECKLIST.md`) on a real iPhone, then `/gsd-verify-work 05`, which decides what ticks in REQUIREMENTS.md. The Phase 2, 3 and 4 partial UATs must also run before Phase 8.
- Open for the user: the Android todos (nothing was committed in the Android repo), the saved-card decision, and the A9, U2, U3, U4 and A1 calls on the checklist.
- Working tree note: `.DS_Store`, `.planning/config.json`, `ClickMe2026/Localizable.xcstrings` and the untracked `.planning/state.json`, `.planning/milestone.lock` and `.DS_Store` files carried uncommitted changes before this run and were not staged. Xcode rewrote `Localizable.xcstrings` during the build; it was left as found. A device build from this working tree includes those uncommitted catalog edits.

## Self-Check: PASSED

- FOUND: the checklist, the five todos named by the plan and the flaky todo, `05-13-SUMMARY.md`.
- FOUND commits `a45d1e3`, `2b3c073`, `4a070ca` (ancestors of HEAD); measured `1f37f5c..HEAD` count is 3.
- Task acceptance criteria re-run: Task 1 (`## Automated evidence` 1, `SIGN-06` 20 lines, three automated checks pass), Task 2 (all files and strings present, Android status and HEAD unchanged), Task 3 (`git show --stat` lists only REQUIREMENTS.md and ROADMAP.md, ROADMAP hunks inside the Phase 5 entry, automated check passes).
