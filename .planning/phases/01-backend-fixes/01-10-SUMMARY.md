---
phase: 01-backend-fixes
plan: 10
subsystem: database
tags: [supabase, migration, deploy-handoff, wave-1, smoke-checklist]

requires:
  - phase: 01-backend-fixes/01-09
    provides: "last wave-1 code plan (BACK-01 accept message); wave 1 = plans 01-01 to 01-09"
provides:
  - "Migration 20261107000000_bookings_cancellation_reason.sql (nullable TEXT bookings.cancellation_reason), committed and applied to production (user-run; column check row: cancellation_reason | text | YES)"
  - "Wave 1 live in production: origin/main and production /health both at a92acba (was 2ec82af)"
  - "Wave-1 smoke checklist reported all passed by the user on App Store build 6 and the current Android build"
  - "Android follow-ups from Phase 1 logged in STATE.md Pending Todos"
affects: [01-11, 01-12 (writes cancellation_reason; the column is now live), 01-15 (deploy wave 2 handoff)]

actuals:
  tokens: 4567
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Apply an additive migration a full deploy wave before the code that reads or writes it"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/supabase/migrations/20261107000000_bookings_cancellation_reason.sql"
  modified:
    - ".planning/STATE.md"

key-decisions:
  - "BACK-14 column ships a full wave before the code that writes it (Open Q8 default); the migration is additive and harmless to today's code"
  - "Dependent-object audit: no views over bookings, no RETURNS SETOF bookings or %ROWTYPE; functions that read bookings name their columns"

# BACK-14 here covers the storage column only. The code that stores the reason is plan 01-12,
# and 01-15 also declares the ID, so it stays Pending in REQUIREMENTS.md (shared-ID gate, #2388).
requirements-completed: [BACK-14, BACK-01, BACK-02, BACK-03, BACK-04, BACK-05, BACK-10, BACK-11, BACK-16, BACK-17]

coverage:
  - id: D1
    description: "BACK-14 migration authored and committed: adds nullable TEXT bookings.cancellation_reason with ADD COLUMN IF NOT EXISTS, no destructive statements, sorts last in supabase/migrations"
    requirement: BACK-14
    verification:
      - kind: other
        ref: "grep -c 'ADD COLUMN IF NOT EXISTS cancellation_reason' <migration> prints 1; the destructive-statement grep outside comments prints 0; re-run 2026-11-08"
        status: pass
    human_judgment: false
  - id: D2
    description: "bookings.cancellation_reason exists in the production database"
    requirement: BACK-14
    verification:
      - kind: manual_procedural
        ref: "User ran the information_schema column check in the production SQL editor; row returned: cancellation_reason | text | YES"
        status: pass
    human_judgment: true
    rationale: "D-11 keeps Claude out of production, so the row is the user's report and Claude did not read the database itself."
  - id: D3
    description: "Wave 1 is deployed: origin/main equals local master and production /health reports the master SHA"
    verification:
      - kind: other
        ref: "git rev-list --count origin/main..master = 0, master..origin/main = 0; git ls-remote origin main = a92acba; GET /health = {\"status\":\"success\",\"commit\":\"a92acba\"}; re-run 2026-11-08T17:24Z"
        status: pass
      - kind: unit
        ref: "npm test with tests/services/redis.test.js excluded (2790 passed), check-openapi-coverage and check-doc-coverage (128 endpoints) at a92acba, before the push"
        status: pass
    human_judgment: false
  - id: D4
    description: "The 14-step wave-1 smoke checklist passes on App Store build 6 and the current Android build"
    verification:
      - kind: manual_procedural
        ref: "User-reported \"all passed\" for section C of the checkpoint, with no per-step notes"
        status: pass
    human_judgment: true
    rationale: "Device behavior across real client and expert accounts is only observable by the user. The report is one overall result, so individual steps cannot be audited from this file."
  - id: D5
    description: "Android follow-ups from Phase 1 are logged in STATE.md Pending Todos"
    verification:
      - kind: other
        ref: "grep -c 'Android follow-ups from Phase 1' .planning/STATE.md prints 1; commit dff4eab touches only STATE.md"
        status: pass
    human_judgment: false

# plan_head_before / plan_head_after are the iOS repo (planning docs) and pair with commits: 2,
# measured with git rev-list at SUMMARY write, so the close-out commits that follow are not counted.
# Backend commits are tracked separately: one commit in this plan, a92acba.
plan_head_before: 1562fe4d2b02f44c16e89f384bed96c44e04dbb3
plan_head_after: 918efbd9ae3d12551fdbae4c85a05d6aaf522dbe
backend_head_before: a1492798c17f8eaf85679f05a00d255c3cb5838f
backend_head_after: a92acbae5d2b7d96ca51270e11c7c20fe99a080b
commits: 2

duration: ~11h 15m wall clock (almost all of it waiting on the user's deploy and smoke test)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 10: Wave 1 close-out Summary

**`bookings.cancellation_reason` is live in production ahead of the code that writes it, and deploy wave 1 (plans 01-01 to 01-10) moved production from `2ec82af` to `a92acba`, with the user reporting the smoke checklist all passed on build 6 and Android.**

## Performance

- **Duration:** ~11h 15m wall clock, from 2026-11-08T06:09Z to 2026-11-08T17:25Z, almost all of it the Task 3 wait on the user
- **Tasks:** 3 of 3 (Tasks 1 and 2 by Claude, Task 3 by the user)
- **Files modified:** 3 (the migration, `.planning/STATE.md`, this SUMMARY)

## Accomplishments

- BACK-14 storage column added to production, one deploy wave before plan 01-12 reads and writes it.
- All 21 wave-1 backend commits are on `origin/main` and serving production.
- Build 6 and current Android reported working against the new backend (D-12).
- Android follow-ups from Phase 1 logged, not built.

## Task Commits

1. **Task 1: BACK-14 migration** - backend `a92acba` `feat(ios-p1/BACK-14): add bookings.cancellation_reason column (migration only)`
2. **Task 2: Gate, push bundle, Android follow-up log** - iOS `dff4eab` `docs(01): log Android follow-ups from Phase 1`, iOS `918efbd` (partial SUMMARY with the push bundle)
3. **Task 3: Apply, push, smoke** - user action, no commit by Claude

## Task 3 Results

### Reported by the user

- **Column check (production SQL editor):** `cancellation_reason | text | YES`, the expected row.
- **Smoke checklist:** "all passed" (14 steps, section C below, on App Store build 6 and the current Android build). No per-step notes were given, so this is one overall user-reported result with no per-step detail.

The `supabase migration list` output and the order of the migration and the push were not reported. The column being present is what the plan's safety rule depends on.

### Verified read-only by Claude (2026-11-08T17:24Z)

| Check | Result |
|-------|--------|
| `git rev-list --count origin/main..master` | `0` |
| `git rev-list --count master..origin/main` | `0` |
| `git rev-parse --short=7 master` and `origin/main` | both `a92acba` |
| `git ls-remote origin main` | `a92acbae5d2b7d96ca51270e11c7c20fe99a080b` |
| `GET /health` | `{"status":"success","commit":"a92acba"}` |

Production moved from `2ec82af` to `a92acba`.

### Smoke checklist as run (section C)

Run on BOTH App Store build 6 (iPhone) and the current Android build (D-12). Production runs live Stripe; the paid step places a real hold on a real card the user owns.

1. Sign in as a client.
2. Free booking: book a free topic; Request Sent appears.
3. Paid booking: book a paid topic and pay; Request Sent appears.
4. As the expert, accept one request; join the in-app voice call from both sides inside the window.
5. Chat: send a message in each direction; both arrive.
6. (Open Q1) On build 6, as the expert accept one request and decline another. On the client's build 6 phone, tap the "Booking Confirmed" push and the "Booking Declined" push: each opens that booking.
7. On build 6, note what happens if you tap an expert-side push while the app is in client mode (expected to be imperfect until Phase 2; just record it).
8. Accept a request with a message in the accept screen: the message appears in the client's Chats as sent by the expert, with a push (BACK-01).
9. On build 6 expert booking detail, if a fee label is shown it reads "CA$..." (BACK-05).
10. Start a chat from a profile without sending anything: the empty thread appears in both users' chat lists (BACK-16).
11. Submit feedback once from Settings: it succeeds (BACK-16).
12. Open a well-populated expert profile's edit screen and save without changes: it saves (BACK-11 caps not hit).
13. On Android, tap any booking push: it still opens the right screen.
14. Cancel the paid booking from step 3 to release the hold.

## Carry-Forward Notes

- **50-item cap (01-07, Open Q9):** it passed only as a single spot-check of one well-populated profile (step 12), not a check across production data. `PATCH /user/profile` language arrays are uncapped (out of scope).
- **Feedback limiter (01-08):** it is in memory and correct only while `railway.json` `numReplicas` is 1.
- **CHF label (01-05):** CHF renders as `CHF12.50 / session` (no space), from the symbol table.
- **Step 7 (expert-side push tapped in client mode):** expected to be imperfect until Phase 2. The user's report gave no note on what happened, so the actual behavior is unrecorded; Phase 2 should not treat it as characterized.
- **Parallel jest flake:** the suite has intermittent random-file flakiness (present at baseline `2ec82af` too); a file that passes alone is the known flake.

## Task 1: BACK-14 migration

- File: `/Users/LeonChen/Documents/ClickMe2026 Backend/supabase/migrations/20261107000000_bookings_cancellation_reason.sql`
- Body: `ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT NULL;` plus a `COMMENT ON COLUMN`. Nothing else.
- Checks, re-run in this continuation: `grep -c "ADD COLUMN IF NOT EXISTS cancellation_reason"` prints 1; the destructive-statement grep outside comments prints 0; the file sorts last in `supabase/migrations`; `a92acba` contains exactly this one file.

## Task 2: Gate and push bundle

Android follow-ups from Phase 1 are logged in `.planning/STATE.md` (iOS commit `dff4eab`, only STATE.md): BACK-02, BACK-18, D-17/BACK-19, BACK-07, BACK-13, BACK-12.

### Full gate (run on master at a92acba, before the push)

| Check | Result |
|-------|--------|
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | `Test Suites: 126 passed, 126 total`; `Tests: 2790 passed, 2790 total` |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

### Push bundle (as pushed)

- Production SHA before: `2ec82af`. Target and current production SHA: `a92acba`.
- 21 commits (20 code commits for plans 01-01 to 01-09, plus 1 for this plan). Diff against the old `origin/main`: 52 files changed, 2960 insertions(+), 201 deletions(-).

| Commit | Plan | Subject |
|--------|------|---------|
| df7fb18 | 01-01 | fix(ios-p1/BACK-04): allow experts to clear meeting_url (null or "") |
| 017874a | 01-01 | test(ios-p1/wave0): lock build-6/Android response key sets (D-12) |
| a2e55de | 01-02 | fix(ios-p1/BACK-17): send push routing fields to every platform plus target_role (D-01/D-02) |
| b7c5c99 | 01-02 | fix(ios-p1/BACK-17): pass target_role on booking lifecycle pushes |
| db63196 | 01-03 | fix(ios-p1/BACK-17): target_role on chat and review pushes |
| 979af3c | 01-03 | fix(ios-p1/BACK-17): target_role on payment-action and reminder pushes |
| b94fcea | 01-04 | fix(ios-p1/BACK-17): target_role on no-show, review-nudge and long-lead pushes |
| 70c7ed6 | 01-04 | fix(ios-p1/BACK-17): account-level pushes carry the recipient's primary role (D-02) |
| ec02fde | 01-05 | fix(ios-p1/BACK-03): expose has_review on expert booking feed, detail and summary |
| f5bc8b0 | 01-05 | fix(ios-p1/BACK-05): consultation_fee.label uses the booking currency symbol and digits |
| 365e091 | 01-05 | fix(ios-p1/BACK-05): potential_earnings uses currency digits; document has_review and labels |
| 8d090be | 01-06 | fix(ios-p1/BACK-02): return the decline note on declined client bookings |
| 0b92cf1 | 01-06 | fix(ios-p1/BACK-02): carry the decline note in the decline notification and chat event |
| 5b4ad5a | 01-07 | fix(ios-p1/BACK-10): reject past or mismatched-duration free booking requests |
| 7c1e4f6 | 01-07 | fix(ios-p1/BACK-11): bound topic price amount |
| c80981d | 01-07 | fix(ios-p1/BACK-11): cap language and expertise tag lists at 50 |
| 3b9b947 | 01-08 | fix(ios-p1/BACK-16): list empty chat threads after active ones |
| 9fe6178 | 01-08 | fix(ios-p1/BACK-16): rate-limit feedback submissions per user |
| 95d9450 | 01-09 | refactor(ios-p1/BACK-01): extract postUserMessage from chats.send |
| a149279 | 01-09 | fix(ios-p1/BACK-01): deliver the accept message to the client as a chat message (D-14) |
| a92acba | 01-10 | feat(ios-p1/BACK-14): add bookings.cancellation_reason column (migration only) |

## Requirements Status

- **Complete in REQUIREMENTS.md:** BACK-01, BACK-02, BACK-03, BACK-04, BACK-05, BACK-10, BACK-11, BACK-16, BACK-17.
- **Still Pending: BACK-14.** Only the storage column exists. Plan 01-12 writes the reason and 01-15 also declares the ID, and neither has a SUMMARY yet, so the shared-ID gate blocks it.
- **BACK-02 scope:** its text also says "and shown in iOS". The backend half is what shipped. The iOS display is Phase 3 (ROADMAP success criterion 5, "the iOS half of BACK-02") and has no requirement ID of its own.

## Deviations from Plan

- Gate ran with `--testPathIgnorePatterns=tests/services/redis.test.js` instead of `REDIS_URL=redis://localhost:6379 npm test` (no local Redis; the orchestrator named this as the gate), so `tests/services/redis.test.js` did not run. Other results match the plan's expectations.
- `git status --porcelain -- src tests openapi docs supabase scripts` showed the pre-existing untracked `scripts/uat-seed-profile.js` (mtime Oct 17, not part of any plan or the push), so the plan's "prints nothing" expectation was not literally met. No tracked file was modified; the file was left untouched.
- Planning commits in the iOS repo were made on `main`. `git.base-branch --is-protected main` returns `true`, which the executor's Step 0 assertion treats as a halt, but `branching_strategy` is `none`, the dispatch named this branch, and `execute-phase/steps/protected-branch.md` continues on the current branch for that strategy. HEAD had not drifted (plans 01-01 to 01-09 ran the same way), config was not changed, and only docs were committed here.
- `01-USER-SETUP.md` was not generated even though the plan has `user_setup`. The user completed those steps in Task 3, so a file with status "Incomplete" would be wrong.

**Total deviations:** 4, none needing a code fix. **Impact on plan:** `redis.test.js` is the one check that did not run before the push.

## Issues Encountered

None. The checkpoint resumed as designed.

## User Setup Required

None remaining. The Supabase and Railway/GitHub steps were done by the user in Task 3.

## Next Phase Readiness

Ready for plan 01-11. The column prerequisite for plan 01-12 is met. Wave 2 still needs its own gate and user push at plan 01-15.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*

## Self-Check: PASSED

- FOUND: `/Users/LeonChen/Documents/ClickMe2026 Backend/supabase/migrations/20261107000000_bookings_cancellation_reason.sql`
- FOUND: backend commit `a92acba`, an ancestor of `origin/main`
- FOUND: iOS commits `dff4eab` and `918efbd`, ancestors of HEAD
- `git rev-list --count 1562fe4..918efbd` = 2, matching `commits: 2`
- All Task 1 and Task 2 acceptance checks re-run and passing, except the two noted under Deviations
