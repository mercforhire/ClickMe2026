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
  - "Wave-2 push bundle and smoke checklist (below), full gate green at 7fdc7c4"
affects: [01-16 (deploy wave 3 starts only after wave 2 is verified)]

actuals:
  tokens: 3433
  tasks: 1
  commits: 1

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-15-SUMMARY.md"
  modified:
    - ".planning/STATE.md"

key-decisions:
  - "Smoke checklist assigns each step to a specific booking, because a paid booking whose call connected, or whose end time has passed, can no longer be released by a client cancel and is captured at end+15"
  - "Android unread step adds a force-quit, because the Android badge is max(server, session-local) and would otherwise pass without the server count"

requirements-completed: []
requirements-pending-checkpoint: [BACK-09, BACK-12, BACK-14, BACK-15, BACK-18]

plan_head_before: d4c9db80faf76b8c4cc5960aee69235f30760e2b
# plan_head_after and the final commits count: set when the plan completes after the checkpoint resumes.
# commits counts the iOS repo only (this partial SUMMARY). This plan makes no backend commits; backend master stays at 7fdc7c4.

status: in-progress
---

# Phase 1 Plan 15: Wave 2 close-out Summary (PARTIAL, awaiting Task 2)

**Wave 2 (BACK-09 join gate, BACK-12 cancel guard, BACK-14 reason storage, BACK-15 confirm replay, BACK-18 unread counts) is gate-green at `7fdc7c4` and packaged for the user to push and smoke-test. It has no migration.**

Status: Task 1 done. Task 2 (`checkpoint:human-action`, `gate="blocking"`) is waiting on the user. Nothing was pushed or deployed by Claude (D-11). No requirement is marked complete.

## Task 1: Gate and push bundle (done)

### Precondition

`bookings.cancellation_reason` is recorded as live in `01-10-SUMMARY.md` (user-run column check: `cancellation_reason | text | YES`). Claude did not re-read the production database.

### Full gate (all run on master at 7fdc7c4)

| Check | Result |
|-------|--------|
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | `Test Suites: 128 passed, 128 total`; `Tests: 2932 passed, 2932 total` |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

- `tests/services/redis.test.js` did not run (needs REDIS_URL, so the plan's literal `REDIS_URL=... npm test` command was not used).
- No flaky file appeared in this run, so no isolated rerun was needed.
- `git status --porcelain -- src tests openapi docs supabase scripts` prints one line: `?? scripts/uat-seed-profile.js`. It is the same pre-existing untracked file noted in 01-10, not part of the push. No tracked file is modified.

### Push bundle

- Production SHA now (`GET /health`): `a92acba` (read 2026-11-08, `{"status":"success","commit":"a92acba"}`)
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

### Handoff notes: read before pushing

1. **Pending request holds after the end time (01-12).** A client can no longer cancel a `pending_approval` booking after `end_time`. The hold stays until `expireBookings` voids it, up to about 12 hours after the request. Nothing is captured. The expert side of the time guard has no dedicated test.
2. **Confirm can leave a hold behind (01-13, `deferred-items.md`).** When the confirm insert fails with no replay, confirm does not void the authorized PaymentIntent. Whether a webhook or sweep clears it is unchecked. This predates the phase and needs a decision before Phase 4 payment UAT. Separately, confirm Step 1 ignores a read error on its idempotency select.
3. **Android unread badge can stick (01-14).** The count covers the whole thread, but Android emits `message.read` only for loaded messages. A thread with unread messages older than the loaded page keeps a non-zero badge after opening. Existing threads keep their stored value until their first send, read or page-1 open. Step 7 covers this.
4. **Join window and call end (01-11).**
   - Production keeps the old `[start-120, end+120]` window until this push.
   - `scripts/uat-demo-shoot-check.js` still mirrors the old window after it.
   - `/end` overwrites `end_reason` `auto_completed` with `completed` for overtime hang-ups.
   - `POST /end` has no limit for `dropped` and `manual_exit` (predates this phase).
5. **What the tests do not prove.** The full suite has pre-existing parallel flakiness. Failures seen, in files whose isolated rerun then passed: connectWebhooks, adminPayouts, clientBooking, expertBooking, connect, webhooks, call (401), expertTopics (15 failures, 404). The root cause is not established. Tests mock Stripe and Supabase, so the real `cancellation_reason` write and the replay on deployed code are proven only by the smoke test.
6. **Real money in the checklist.** Client cancel now refuses a booking past its end time (new), and it already refused `in_progress`. Either way the hold is captured at end+15. See "Keep the bookings separate" below.

## Task 2: Checkpoint (PENDING, user action)

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

**After you reply, Claude runs (read-only):** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" rev-list --count origin/main..master` must print 0, and `curl -fsS https://clickme-backend-production.up.railway.app/health` must contain `"commit":"7fdc7c4"`. Claude then records your results here.

**Resume signal:** reply "wave 2 deployed" with any checklist step that failed (or "all passed"), plus any "not offered by the client" notes.

## Deviations from Plan

- **Gate command:** ran with `--testPathIgnorePatterns=tests/services/redis.test.js` instead of `REDIS_URL=redis://localhost:6379 npm test` (no local Redis; the dispatch named this as the gate), so `redis.test.js` did not run.
- **`status --porcelain` not literally empty:** the pre-existing untracked `scripts/uat-seed-profile.js`, left untouched.
- **[Rule 2 - Missing critical] Checklist tightened from the plan's text.** The plan's step 1 did not say which booking to join on, and its step 8 cancels "the paid booking from step 1". Read together, a paid booking with a connected call cannot be cancelled, and the card is charged at end+15. From `clientBooking.controller.js` `cancellableStatuses`, `call.controller.js` confirm-connection and `expirePastSessions.js` Sweep C. Added the booking table, narrowed step 5 to a free booking with no call, and added the warning to step 8.
- **Checklist addition for step 7.** Added the force-quit, because `displayUnread` in Android's `ConversationsUiState.kt` returns `maxOf(server, local)`, so the plan's step could pass with the server count still at 0.
- **New-config scan not completed.** A grep of the diff for new environment variables was blocked by the secret-read guard, and was not reworded to get around it. Evidence that no new config is needed is indirect: no package or config file changed, and the 01-11 to 01-14 SUMMARYs list no user setup (01-13 says so explicitly about environment variables).
- **Commits on `main`:** `git.base-branch --is-protected main` returns `true`, but `branching_strategy` is `none`, the dispatch named this branch, and plans 01-01 to 01-14 ran the same way. Only planning docs were committed.
- **`01-USER-SETUP.md` not generated** even though the plan has `user_setup`. The push is the only step and it is fully written in Task 2 above.

## Next Phase Readiness

Blocked on Task 2. Deploy wave 3 must not start until wave 2 is pushed, `/health` reports `7fdc7c4`, and the smoke results are recorded here.

## Self-Check: PASSED

- FOUND: this SUMMARY contains "wave 2" and lists every commit in `origin/main..master` with its plan id, the production SHA and the target SHA.
- `git log origin/main..master` holds exactly the 10 listed commits, all from plans 01-11 to 01-14.
- `git rev-list --count master..origin/main` = 0; nothing pushed by Claude (`origin/main` still `a92acba`).
- The checklist's quoted server messages match `call.controller.js` and `clientBooking.controller.js`.
- Task 2 is not done, so `status: in-progress`, `requirements-completed: []`, and no requirement is marked complete.
