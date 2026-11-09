---
phase: 01-backend-fixes
plan: 15
subsystem: api
tags: [deploy-handoff, wave-2, smoke-checklist, join-window, cancel-guard, confirm-replay, unread-counts]

requires:
  - phase: 01-backend-fixes/01-10
    provides: "bookings.cancellation_reason live in production; wave 1 live at a92acba"
  - phase: 01-backend-fixes/01-14
    provides: "last wave-2 code plan (BACK-18); wave 2 = plans 01-11 to 01-14"
provides:
  - "Wave 2 live in production: pushed at 7fdc7c4 (full gate green); origin/main and production /health are now at ddfe5bf, one test-only commit later"
  - "Wave-2 smoke checklist reported all passed by the user, with no per-step notes and no 'not offered by the client' notes"
affects: [01-16 (deploy wave 3 starts only after wave 2 is verified)]

actuals:
  tokens: 5113
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-15-SUMMARY.md"
  modified:
    - ".planning/STATE.md"
    - ".planning/ROADMAP.md"
    - ".planning/REQUIREMENTS.md"
    - ".planning/WINDOWS.md"

key-decisions:
  - "Smoke checklist assigns each step to a specific booking, because a paid booking whose call connected, or whose end time has passed, can no longer be released by a client cancel and is captured at end+15"
  - "Android unread step adds a force-quit, because the Android badge is max(server, session-local) and would otherwise pass without the server count"
  - "Wave 2 deployed: production moved from a92acba to 7fdc7c4, then to ddfe5bf (test-only commit outside this plan); smoke checklist user-reported all passed, with no per-step notes"

requirements-completed: [BACK-09, BACK-12, BACK-14, BACK-15, BACK-18]

coverage:
  - id: D1
    description: "Wave 2 passed the full backend gate at 7fdc7c4 and was packaged with every commit mapped to plans 01-11 to 01-14"
    verification:
      - kind: unit
        ref: "npm test with tests/services/redis.test.js excluded (2932 passed), check-openapi-coverage and check-doc-coverage (128 endpoints) at 7fdc7c4, before the push"
        status: pass
    human_judgment: false
  - id: D2
    description: "Wave 2 is deployed: origin/main equals local master and production /health reports the master SHA"
    verification:
      - kind: other
        ref: "git rev-list --count origin/main..master = 0, master..origin/main = 0; git ls-remote origin main = ddfe5bf; GET /health = {\"status\":\"success\",\"commit\":\"ddfe5bf\"}; re-run 2026-11-09T00:17Z. All 10 wave-2 commits are ancestors of origin/main"
        status: pass
    human_judgment: false
  - id: D3
    description: "The wave-2 smoke checklist passes on App Store build 6 and the current Android build"
    verification:
      - kind: manual_procedural
        ref: "User-reported \"wave 2 deployed\", then \"all passed\" when asked for the smoke result, with no per-step notes"
        status: pass
    human_judgment: true
    rationale: "Device behavior across real client and expert accounts is only observable by the user. The report is one overall result that does not separate the two clients, so individual steps cannot be audited from this file."
  - id: D4
    description: "BACK-15 confirm replay behaves correctly on the deployed code"
    requirement: BACK-15
    verification:
      - kind: unit
        ref: "tests/booking.test.js#BACK-15 ownership-checked replay, in the 7fdc7c4 gate run"
        status: pass
    human_judgment: true
    rationale: "The wave-2 checklist has no step that drives a confirm retry against production, and the tests mock Stripe and Supabase. Deployed replay behavior has not been directly observed."

# plan_head_before / plan_head_after are the iOS repo (planning docs) and pair with commits: 1,
# measured with git rev-list at SUMMARY write, so the close-out commits that follow are not counted.
# This plan makes no backend commits. ddfe5bf is on backend master and production but is not from this plan.
plan_head_before: d4c9db80faf76b8c4cc5960aee69235f30760e2b
plan_head_after: 3d6c5c6848b90872a0a37dc316d002d0a828c923

duration: ~6h 20m wall clock (almost all of it waiting on the user's push and smoke test)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 15: Wave 2 close-out Summary

**Deploy wave 2 (BACK-09 join gate, BACK-12 cancel guard, BACK-14 reason storage, BACK-15 confirm replay, BACK-18 unread counts) moved production from `a92acba` to `7fdc7c4`, with the user reporting the smoke checklist all passed. Production now reports `ddfe5bf`, one later test-only commit with the same runtime code.**

## Performance

- **Duration:** ~6h 20m wall clock, from 2026-11-08T18:00Z to 2026-11-09T00:20Z, almost all of it the Task 2 wait on the user
- **Tasks:** 2 of 2 (Task 1 by Claude, Task 2 by the user)
- **Files modified:** 5, all planning docs (this SUMMARY, `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `WINDOWS.md`). No backend files.

## Accomplishments

- The full gate was green at `7fdc7c4`, and the bundle listed 10 commits, all from plans 01-11 to 01-14.
- The user pushed wave 2 with no migration needed.
- The user reported the smoke checklist all passed.

## Task Commits

1. **Task 1: Wave-2 pre-push gate and push bundle** - `3d6c5c6` (docs, iOS repo)
2. **Task 2: User pushes wave 2 and runs the smoke checklist** - user action, no Claude commit

## Task 2: Results

### Smoke result: what the user reported

The user replied "wave 2 deployed", then, when asked for the smoke result, "all passed".

- There is no per-step detail.
- There were no "not offered by the client" notes.
- The reply does not say which client exercised which step, including steps 3 and 5, so this file does not say either.
- The paid booking P being cancelled (step 8) rests only on "all passed". Claude did not check Stripe or Supabase.

### Deploy verification (read-only, re-run 2026-11-09T00:17Z)

| Check | Result |
|-------|--------|
| `git rev-list --count origin/main..master` | `0` |
| `git rev-list --count master..origin/main` | `0` |
| `git rev-parse --short=7 master` | `ddfe5bf` |
| `git ls-remote origin refs/heads/main` | `ddfe5bf338b12f9af1518ed1c09606269678a1b5` |
| `GET /health` | `200 {"status":"success","commit":"ddfe5bf"}` |
| All 10 wave-2 commits are ancestors of `origin/main` | Yes |

The plan's check, that `/health` reports the short SHA of master, passes.

### Production is at ddfe5bf, not 7fdc7c4

The dispatch for this continuation recorded both master and `/health` at `7fdc7c4`. Both were at `ddfe5bf` when re-checked, so the Task 2 text's literal `"commit":"7fdc7c4"` no longer matches.

| Time (local, 2026-11-08) | `origin/main` tracking ref (backend reflog, "update by push") |
|-------------------------|---------------------------------------------------------------|
| 12:13:40 | `a92acba` (wave 1) |
| 13:20:58 | `7fdc7c4` (wave 2, exactly the 10-commit bundle) |
| 14:11:22 | `ddfe5bf` |

- `ddfe5bf` is `fix(tests): use one clock read in clientBooking date fixtures`, committed at 14:05:15. It changes only `tests/clientBooking.test.js`, so the code under `src` is the same as `7fdc7c4`.
- It is not part of the wave-2 bundle or of this plan, and no planning file mentions it. This executor did not make or push it. Who pushed it is not established here.
- Which of the two SHAs the smoke test ran against is not known. Either way the runtime code is the same.
- The full gate ran at `7fdc7c4`, not at `ddfe5bf`. `tests/clientBooking.test.js` was re-run on its own at `ddfe5bf`: 141 passed.

### Open decisions (flagged to the user, not answered)

1. **`pending_approval` hold after `end_time` (handoff note 1).** Accepted in effect by pushing, but the user did not explicitly confirm it. It stays open.
2. **Confirm orphaned hold (handoff note 2).** A decision is needed before Phase 4 payment UAT.

## Task 1: Gate and push bundle (done)

### Precondition

`bookings.cancellation_reason` is recorded as live in `01-10-SUMMARY.md` (user-run column check: `cancellation_reason | text | YES`). Claude did not re-read the production database.

### Full gate (all run on master at 7fdc7c4)

| Check | Result |
|-------|--------|
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | `Test Suites: 128 passed, 128 total`; `Tests: 2932 passed, 2932 total` |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

- `tests/services/redis.test.js` did not run (needs REDIS_URL, so the plan's literal `REDIS_URL=... npm test` command was not used). Logged in `.planning/WINDOWS.md` as entry 2, as 01-10 did with entry 1.
- No flaky file appeared in this run, so no isolated rerun was needed.
- `git status --porcelain -- src tests openapi docs supabase scripts` prints one line: `?? scripts/uat-seed-profile.js`. It is the same pre-existing untracked file noted in 01-10, not part of the push. No tracked file is modified.

### Push bundle

- Production SHA before the push (`GET /health`): `a92acba` (read 2026-11-08, `{"status":"success","commit":"a92acba"}`)
- Target SHA (`git rev-parse --short=7 master`): `7fdc7c4`
- `git status -sb`: `## master...origin/main [ahead 10]`. `master..origin/main` is 0, so the push is a fast-forward.
- 10 commits, all with an `ios-p1/` scope for BACK-09, 12, 14, 15 or 18, and all mapped to plans 01-11 to 01-14. Nothing else is in the range.
- Diff against origin/main: 23 files changed, 2702 insertions(+), 327 deletions(-), all under `src`, `tests`, `openapi` and `docs`.
- **No migration:** `git diff --name-status origin/main master -- supabase` prints nothing. The columns the new code uses already exist in committed migrations: `cancellation_reason` (`20261107000000`, applied in 01-10) and `unread_count_client` / `unread_count_expert` (`20260609000000_create_chats.sql`). No package or `railway.json` change.
- Push command (user only): `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`

| Commit | Plan | Subject |
|--------|------|---------|
| 0ed81f5 | 01-11 | fix(ios-p1/BACK-09): two-tier join window and booking status check (D-03/D-04) |
| 8cad41f | 01-11 | fix(ios-p1/BACK-09): align can_join flags with the join gate (D-06) |
| 15d405c | 01-11 | fix(ios-p1/BACK-09): accept overtime call end after auto-completion; document join rules (D-05) |
| deda040 | 01-12 | fix(ios-p1/BACK-14): store and return the cancellation reason |
| 87d3c62 | 01-12 | fix(ios-p1/BACK-12): reject client cancel after the session end; document cancellation_reason |
| 7aa4297 | 01-13 | fix(ios-p1/BACK-15): replay confirm for the caller's own booking instead of DUPLICATE_BOOKING/SLOT_UNAVAILABLE |
| b982e0b | 01-13 | fix(ios-p1/BACK-15): payment-intent reports the caller's own booking; validate duration; document replay |
| 949b2b7 | 01-14 | fix(ios-p1/BACK-18): recount the recipient's unread messages on send (D-16) |
| fbf8ce7 | 01-14 | fix(ios-p1/BACK-18): reset the reader's unread count on message.read; make the handler testable |
| 7fdc7c4 | 01-14 | fix(ios-p1/BACK-18): recount on thread open; document maintained unread counts |

### Handoff notes: written before the push, still in force

1. **Pending request holds after the end time (01-12).** A client can no longer cancel a `pending_approval` booking after `end_time`. The hold stays until `expireBookings` voids it, up to about 12 hours after the request. Nothing is captured. The expert side of the time guard has no dedicated test.
2. **Confirm can leave a hold behind (01-13, `deferred-items.md`).** When the confirm insert fails with no replay, confirm does not void the authorized PaymentIntent. Whether a webhook or sweep clears it is unchecked. This predates the phase and needs a decision before Phase 4 payment UAT. Separately, confirm Step 1 ignores a read error on its idempotency select.
3. **Android unread badge can stick (01-14).** The count covers the whole thread, but Android emits `message.read` only for loaded messages. A thread with unread messages older than the loaded page keeps a non-zero badge after opening. Existing threads keep their stored value until their first send, read or page-1 open. Step 7 covers this.
4. **Join window and call end (01-11).**
   - Production kept the old `[start-120, end+120]` window until this push.
   - `scripts/uat-demo-shoot-check.js` still mirrors the old window after it.
   - `/end` overwrites `end_reason` `auto_completed` with `completed` for overtime hang-ups.
   - `POST /end` has no limit for `dropped` and `manual_exit` (predates this phase).
5. **What the tests do not prove.** The full suite has pre-existing parallel flakiness. Failures seen, in files whose isolated rerun then passed: connectWebhooks, adminPayouts, clientBooking, expertBooking, connect, webhooks, call (401), expertTopics (15 failures, 404). The root cause is not established. Tests mock Stripe and Supabase, so the real `cancellation_reason` write and the replay on deployed code are proven only by the smoke test.
   - **Correction at close-out:** the checklist below has no step that drives a confirm retry. "All passed" therefore does not show BACK-15 replay working in production. Its evidence is the mocked tests in the gate (coverage D4).
6. **Real money in the checklist.** Client cancel now refuses a booking past its end time (new), and it already refused `in_progress`. Either way the hold is captured at end+15. See "Keep the bookings separate" below.

### The checklist the user was given

**A. Push wave 2:** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`, then wait for Railway to report the deploy healthy. There is no migration to apply first.

**B. Smoke checklist, on BOTH App Store build 6 and the current Android build (D-12).** Production runs live Stripe; the paid step places a real hold on a card you own.

**Keep the bookings separate.** A connected call moves a booking to `in_progress`, and a client cannot cancel that status. A client also cannot cancel once `end_time` has passed. In both cases a paid booking is captured at end+15, which is a real charge.

| Booking | Type | Use it for | Rule |
|---------|------|-----------|------|
| P | Paid | Step 1 (book and pay), step 8 (cancel) | Never join a call on it. Cancel it before its end time. |
| F1 | Free, accepted, short | Steps 1 to 4 (calls) | |
| F2 | Free, accepted, short, not overlapping F1 | Step 5 | No call on it. |

1. Base checks: sign in; make free bookings F1 and F2; make paid booking P and pay; join an in-app call on F1 from both sides; chat both ways.
2. Join window (BACK-09): tap Join on a confirmed free booking about 30 minutes before start on Android: the call connects. If either app offers Join more than 60 minutes early, the server now answers "This session opens for joining 60 minutes before it starts."
3. Rejoin (BACK-09, D-03): during F1, leave the call after the scheduled end and rejoin within 60 minutes from whichever app still offers Join; it connects. If neither app offers Join after the end, note "not offered by the client" (the server rule is covered by tests; iOS gets this in Phase 2).
4. Hang-up after auto-complete (D-05): if a call runs past end+15, hanging up shows no error.
5. Late cancel (BACK-12): on build 6, open F2 after its end time and within 15 minutes of it, and tap Cancel: the app shows "This session has already ended, so it can't be cancelled." Nothing is refunded (F2 is free). After end+15 the cron moves the booking and you get a different error. If build 6 does not offer Cancel, note "not offered by the client".
6. Cancel reason (BACK-14): cancel a booking from a screen that accepts a comment (Android, if it sends one). P in step 8 can double as this. In the Supabase SQL editor (read-only): `select status, cancellation_reason from bookings where id = '<booking id>';` shows the comment.
7. Unread badge (BACK-18), on Android, in a short thread:
   - Receive a message while outside that chat: the conversation row shows an unread badge.
   - Force-quit and reopen the app before opening the chat: the badge is still there. Android shows the larger of the server count and a count kept in memory, so only this part proves the server count.
   - Open the chat and go back: the badge is cleared.
   - A long thread with unread messages older than the loaded page may keep a badge after opening. That is handoff note 3, not a failure, but please report it if you see it.
   - On build 6, chat behaves as before. It decodes the count but does not display it.
8. Cancel P before its end time to release the hold. If it ever shows `in_progress`, or the end time has passed, the cancel is refused and the card is charged at end+15. Tell Claude if that happens.

## Requirements Status

- **Complete in REQUIREMENTS.md:** BACK-09, BACK-12, BACK-14, BACK-15, BACK-18. `requirements.ready-ids` returned all five as ready and none blocked, because every plan declaring them (01-10 to 01-15) now has a SUMMARY.
- **BACK-15 caveat:** complete under the gate, but deployed behavior rests on mocked tests (coverage D4).

## Deviations from Plan

- **Production SHA differs from the planned target.** `/health` reports `ddfe5bf`, not `7fdc7c4`. See "Production is at ddfe5bf, not 7fdc7c4". The plan's check against master's short SHA passes, and no code changed in this plan.
- **Gate command:** ran with `--testPathIgnorePatterns=tests/services/redis.test.js` instead of `REDIS_URL=redis://localhost:6379 npm test` (no local Redis; the dispatch named this as the gate), so `redis.test.js` did not run.
- **`status --porcelain` not literally empty:** the pre-existing untracked `scripts/uat-seed-profile.js`, left untouched.
- **[Rule 2 - Missing critical] Checklist tightened from the plan's text.** The plan's step 1 did not say which booking to join on, and its step 8 cancels "the paid booking from step 1". Read together, a paid booking with a connected call cannot be cancelled, and the card is charged at end+15. From `clientBooking.controller.js` `cancellableStatuses`, `call.controller.js` confirm-connection and `expirePastSessions.js` Sweep C. Added the booking table, narrowed step 5 to a free booking with no call, and added the warning to step 8.
- **Checklist addition for step 7.** Added the force-quit, because `displayUnread` in Android's `ConversationsUiState.kt` returns `maxOf(server, local)`, so the plan's step could pass with the server count still at 0.
- **New-config scan not completed.** A grep of the diff for new environment variables was blocked by the secret-read guard, and was not reworded to get around it. Evidence that no new config is needed is indirect: no package or config file changed, and the 01-11 to 01-14 SUMMARYs list no user setup (01-13 says so explicitly about environment variables).
- **Commits on `main`:** `git.base-branch --is-protected main` returns `true`, but `branching_strategy` is `none`, the dispatch named this branch, and plans 01-01 to 01-14 ran the same way. Only planning docs were committed.
- **`01-USER-SETUP.md` not generated** even though the plan has `user_setup`. The push was the only step and the user has done it, so a file with status "Incomplete" would be wrong.

**Total deviations:** 8, none needing a code fix. **Impact on plan:** `redis.test.js` is the one check that did not run before the push.

## Issues Encountered

None beyond the SHA difference above. The checkpoint resumed as designed.

## User Setup Required

None remaining. The push and smoke test were done by the user in Task 2.

## Next Phase Readiness

Ready for plan 01-16 (deploy wave 3). Two decisions remain open: the `pending_approval` hold after `end_time`, and the confirm orphaned hold, which needs an answer before Phase 4 payment UAT.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*

## Self-Check: PASSED

- FOUND: this SUMMARY contains "wave 2" and lists every commit in the pushed bundle with its plan id, the production SHA and the target SHA.
- FOUND: iOS commit `3d6c5c6`, an ancestor of HEAD. `git rev-list --count d4c9db8..3d6c5c6` = 1, matching `commits: 1`.
- FOUND: all 10 backend wave-2 commits are ancestors of `origin/main`.
- `origin/main..master` = 0 and `master..origin/main` = 0; `/health` reports master's short SHA, `ddfe5bf`.
- FOUND: `.planning/WINDOWS.md` entry 2 records this plan's gate exclusion.
- Nothing was pushed or deployed by this executor.
