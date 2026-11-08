---
phase: 01-backend-fixes
plan: 10
subsystem: database
tags: [supabase, migration, deploy-handoff, wave-1, smoke-checklist]

requires:
  - phase: 01-backend-fixes/01-09
    provides: "last wave-1 code plan (BACK-01 accept message); wave 1 = plans 01-01 to 01-09"
provides:
  - "Migration 20261107000000_bookings_cancellation_reason.sql (nullable TEXT bookings.cancellation_reason), committed, NOT applied"
  - "Wave-1 push bundle and smoke checklist (below), full gate green"
  - "Android follow-ups from Phase 1 logged in STATE.md Pending Todos"
affects: [01-11, 01-12 (writes cancellation_reason; needs the column live first)]

actuals:
  tokens: 6000
  tasks: 2
  commits: 2

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/supabase/migrations/20261107000000_bookings_cancellation_reason.sql"
  modified:
    - ".planning/STATE.md"

key-decisions:
  - "BACK-14 column ships a full wave before the code that writes it (Open Q8 default); the migration is additive and harmless to today's code"
  - "Dependent-object audit: no views over bookings, no RETURNS SETOF bookings or %ROWTYPE; functions that read bookings name their columns"

requirements-completed: []
requirements-pending-checkpoint: [BACK-14, BACK-01, BACK-02, BACK-03, BACK-04, BACK-05, BACK-10, BACK-11, BACK-16, BACK-17]

plan_head_before: 1562fe4d2b02f44c16e89f384bed96c44e04dbb3
# plan_head_after and final commits count: set when the plan completes after the checkpoint resumes.
# commits counts the iOS repo only (STATE log + this partial SUMMARY). The backend commit is a92acba.

status: in-progress
---

# Phase 1 Plan 10: Wave 1 close-out Summary (PARTIAL, awaiting Task 3)

**BACK-14 `bookings.cancellation_reason` migration authored and committed (not applied); wave 1 is gate-green and packaged for the user to apply, push and smoke-test.**

Status: Tasks 1 and 2 done. Task 3 (`checkpoint:human-action`, `gate="blocking"`) is waiting on the user. Nothing was pushed, deployed or applied by Claude (D-11).

## Task 1: BACK-14 migration (done)

- File: `/Users/LeonChen/Documents/ClickMe2026 Backend/supabase/migrations/20261107000000_bookings_cancellation_reason.sql`
- Backend commit `a92acba` `feat(ios-p1/BACK-14): add bookings.cancellation_reason column (migration only)`, exactly this file.
- Body: `ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT NULL;` plus a `COMMENT ON COLUMN`. Nothing else.
- Checks: `grep -c "ADD COLUMN IF NOT EXISTS cancellation_reason"` prints 1; destructive-statement grep (outside comments) prints 0; the file sorts last in `supabase/migrations`.
- `git diff --stat origin/main..master -- supabase` shows this is the only migration in the push, so it is the only migration this push can make pending (the user still confirms with `supabase migration list`, since remote state cannot be read without touching production).

## Task 2: Gate, push bundle, Android follow-up log (done)

Android follow-ups from Phase 1 are logged in `.planning/STATE.md` (iOS commit `dff4eab` `docs(01): log Android follow-ups from Phase 1`, only STATE.md): BACK-02, BACK-18, D-17/BACK-19, BACK-07, BACK-13, BACK-12.

### Full gate (all run on master at a92acba)

| Check | Result |
|-------|--------|
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | `Test Suites: 126 passed, 126 total`; `Tests: 2790 passed, 2790 total` |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

- `tests/services/redis.test.js` was excluded (needs REDIS_URL; known environmental failure), so the plan's literal `REDIS_URL=... npm test` command was not used. No flaky file appeared in this run.
- `git status --porcelain -- src tests openapi docs supabase scripts` prints one line: `?? scripts/uat-seed-profile.js`. That is a pre-existing untracked file (mtime Oct 17), not part of any plan and not part of the push. The plan's "prints nothing" expectation is therefore not literally met; no tracked file is modified.

### Push bundle

- Production SHA now (`GET /health`): `2ec82af` (read 2026-11-08, `{"status":"success","commit":"2ec82af"}`)
- Target SHA (`git rev-parse --short=7 master`): `a92acba`
- `git status -sb`: `## master...origin/main [ahead 21]`; 21 commits listed below (20 code commits for plans 01-01 to 01-09, plus 1 for this plan). Diff against origin/main: 52 files changed, 2960 insertions(+), 201 deletions(-). All subjects carry an `ios-p1/` scope and map to a plan.
- Push command (user only): `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main` (`push.default` is unset, so name the refspec)

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

### Handoff notes for the user

- 01-07: the 50-item language/tag cap (Open Q9) was never checked against production data. Spot-check one well-populated expert profile (smoke step 12). `PATCH /user/profile` language arrays remain uncapped (out of scope).
- 01-08: the feedback limiter is in-memory, correct only while `railway.json` `numReplicas` is 1.
- 01-09: socket delivery, push and Chats display of the accept message are not device-verified yet (smoke step 8).
- 01-05: the CHF label renders `CHF12.50 / session` (no space), from the symbol table.
- The parallel jest suite has intermittent random-file flakiness (present at baseline 2ec82af too); a file that passes alone is the known flake.

## Task 3: Checkpoint (PENDING, user action)

Order matters: A (migration) before B (push), because the wave-2 code in plan 01-12 reads and writes the column, and an unknown column would 500 the cancel money path.

**A. Apply the migration first**
1. `cd "/Users/LeonChen/Documents/ClickMe2026 Backend" && supabase migration list` (read-only). The only migration that is local but not remote must be `20261107000000_bookings_cancellation_reason.sql`. If anything else is pending, stop and tell Claude.
2. `supabase db push`
3. In the Supabase SQL editor: `select column_name, data_type, is_nullable from information_schema.columns where table_schema = 'public' and table_name = 'bookings' and column_name = 'cancellation_reason';` Expect exactly one row: `cancellation_reason, text, YES`.

**B. Push wave 1:** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`, then wait for Railway to report the deploy healthy.

**C. Smoke checklist, on BOTH App Store build 6 (iPhone) and the current Android build (D-12).** Production runs live Stripe; the paid step places a real hold on a real card you own.
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

**Resume signal:** reply "wave 1 deployed" with the column-check row and any checklist step that failed (or "all passed").

**After resume Claude will check (read-only):** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" rev-list --count origin/main..master` prints 0, and `/health` contains `"commit":"a92acba"`; then record the column-check result and smoke results here, set `status: complete`, fill `plan_head_after` and `commits`, and advance STATE/ROADMAP/requirements.

## Deviations from Plan

- Gate ran with `--testPathIgnorePatterns=tests/services/redis.test.js` instead of `REDIS_URL=redis://localhost:6379 npm test` (no local Redis; the orchestrator named this as the gate). Other results match the plan's expectations.
- `git status --porcelain -- ... scripts` showed the pre-existing untracked `scripts/uat-seed-profile.js` (see above); left untouched.
- Planning commits in the iOS repo were made on `main` (branching_strategy `none`, the same as plans 01-01 to 01-09 and as the dispatch instructed), which the executor's protected-branch assertion would otherwise flag; no code was committed there.

## Self-Check (partial)

- FOUND: backend commit a92acba (migration) and the migration file
- FOUND: iOS commit dff4eab (STATE.md follow-up log)
- Not yet checked: Task 3 results
