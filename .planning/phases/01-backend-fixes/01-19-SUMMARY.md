---
phase: 01-backend-fixes
plan: 19
subsystem: payments
tags: [deploy-handoff, wave-3b, smoke-checklist, stripe, expert-cancel, refund, BACK-19, D-17]

requires:
  - phase: 01-backend-fixes/01-17
    provides: "wave 3a live; production and origin/main at d356fdc, real-card smoke not run by user decision"
  - phase: 01-backend-fixes/01-18
    provides: "BACK-19 commits ccd586e and 3899d63 on backend master"
provides:
  - "Wave-3b push bundle and expert-cancel smoke checklist (below), full gate green at 3899d63"
  - "Refund retry analysis and options for the user's decision before the push"
affects: [01-20 onward (later deploy waves start only after 3b is handled), Phase 3 EXP-11 and BOOK-08 copy, Phase 4 payment UAT]

actuals:
  tokens: 6218
  tasks: 1
  # Measured at partial-SUMMARY write, before this file's own commit. Final count is set at resume.
  commits: 0

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-19-SUMMARY.md"
  modified:
    - ".planning/phases/01-backend-fixes/deferred-items.md"
    - ".planning/STATE.md"
    - ".planning/WINDOWS.md"

key-decisions:
  - "The checklist drops the plan's 'cancel inside 24 hours': the void branch has no time check, so a close start proves nothing extra and shortens the margin before a charge"
  - "The void is proven from the PaymentIntent state and refund_failed, not the app, because expert cancel returns 200 even when the Stripe call failed"
  - "Correction to 01-18: PATCH /expert/bookings/:id/status does not accept cancelled. The Zod schema allows only missed and completed, so that item is closed in deferred-items.md"
  - "Correction to the D-17 premise: capture happens only from completed, in_progress or client-no-show missed, none of which an expert can cancel, and the T-24h sweep only authorizes. So a normal expert cancel was already a full release, and the refund branch is rarely reached"

requirements-completed: []
requirements-pending-checkpoint: [BACK-19]

coverage:
  - id: D1
    description: "Full backend gate green at 3899d63; the push range is exactly the two plan 01-18 commits; production and target SHAs recorded"
    requirement: BACK-19
    verification:
      - kind: other
        ref: "npm test -- --testPathIgnorePatterns=tests/services/redis.test.js; check-openapi-coverage; check-doc-coverage; git log origin/main..master; git ls-remote origin main; GET /health"
        status: pass
    human_judgment: false
  - id: D2
    description: "On production, an expert cancel of an authorized paid booking releases the client's full hold: the PaymentIntent is canceled and refund_failed is not true"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "Every test mocks Stripe, and only the user can push and hold the card. Pending Task 2."
  - id: D3
    description: "A captured booking is refunded in full by an expert cancel, on real Stripe"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "NOT covered by this smoke. No safe route to a captured, still cancellable booking exists on live data. Only mocked tests cover it (D-13 deviation, Open Q7)."

plan_head_before: fa3f552fb7b7dadb7bfc640ae0cb0695af328575
# plan_head_after and the final commits count: set when the plan completes after the checkpoint resumes.
# plan_head_before is an iOS repo SHA. This plan makes no backend commits; backend master stays at 3899d63.

status: in-progress
---

# Phase 1 Plan 19: Wave 3b close-out Summary (PARTIAL, awaiting Task 2)

**Wave 3b (BACK-19: an expert cancel fully refunds a captured booking) is gate-green at `3899d63` and packaged for your push. It has no migration. One decision is yours before the push. The smoke proves the hold release only, not the refund.**

Status: Task 1 done. Task 2 (`checkpoint:human-action`, `gate="blocking"`) is waiting on you. Claude pushed and deployed nothing (D-11), and no backend code changed in this plan. No requirement is marked complete.

## Read this before pushing

### 1. DECISION NEEDED: failed refunds are not retried as refunds

**Confirmed by reading the code. Nothing here was run on real Stripe.**

1. If `createRefund` throws, the catch block sets only `refund_failed: true` (`expertBooking.controller.js:1245`, `clientBooking.controller.js:949`). `refund_amount_minor_units` stays NULL.
2. The API still returns 200 with the full `refund_amount`, because the value is set before `createRefund` runs.
3. `refundReconciliation.js` reads NULL as a failed void and calls `cancelPI`. On a captured PaymentIntent that should fail on every 30-minute sweep, so the flag never clears. The client gets no money unless someone refunds by hand.

**Handlers affected:**

| Handler | Affected? | Note |
|---------|-----------|------|
| `POST /expert/bookings/:id/cancel` | Yes | Any failed refund |
| `POST /client/bookings/:id/cancel` | Yes | Only when more than 24 hours out; within 24 hours it owes 0 and makes no refund call |
| `accountCascade`, `expirePastSessions` | No | They save the intended amount, so the sweep does retry a refund |

**BACK-19 widens this less than the 01-18 note and the D-17 context say.** Capture runs only through `captureIfEligible`, and only for `completed`, `in_progress` or a client no-show `missed` (`completionCapture.js`). An expert can cancel only `pending_approval`, `confirmed` or `pending_reschedule`. The T-24h long-lead sweep only authorizes (`requires_capture`), so D-17's "charged at T-24h" case takes the void branch today, as it did before this wave. A normal expert cancel was already a full release.

From reading the code, a booking can be captured and still cancellable in only three ways:

- Rows from before capture moved to session completion.
- A capture made outside this code, such as in the Dashboard, which the webhook records.
- A narrow case: `authExpirySweep` captures an `in_progress` or `completed` row, which is then rescheduled before its end time.

**Two read-only queries size this (Supabase SQL editor). They need no hold:**

```sql
-- QA: bookings that would reach the refund branch if an expert cancelled now
select id, status, payment_status, captured_at, start_time, amount_paid_minor_units, currency
from bookings
where status in ('pending_approval','confirmed','pending_reschedule')
  and payment_intent_id is not null
  and (payment_status in ('captured','partially_refunded','processing') or captured_at is not null);

-- QB: rows the sweep is retrying right now
select id, status, payment_status, refund_amount_minor_units, amount_paid_minor_units, updated_at
from bookings
where refund_failed = true
order by updated_at desc;
```

- An empty QA is strong evidence that the exposure is small. It is not proof, because an old row's `payment_status` can be stale.
- A QB row with `status = cancelled`, `payment_status = captured` and a NULL amount is a client who may be owed money today, whatever you decide about this wave. Tell Claude.

**Options:**

| Option | What happens | Cost |
|--------|--------------|------|
| **A. Push now, fix next (my recommendation if QA and QB are empty)** | Wave 3b ships. The fix becomes its own small plan and deploy, before Phase 4 payment UAT | Until then a failed refund needs a manual refund, and the API overstates it |
| B. Fix first | The fix joins this push | Client cancel and the sweep join the wave, so it is no longer expert-cancel only (D-10). The gate and this bundle must be redone |
| C. Accept it | No fix. Check QB periodically and refund by hand | A client can wait on a manual step while the API said refunded |

Why A: from the code, this wave does not make a normal booking worse, and the hole already exists for client cancels today.

**What a correct fix looks like (not implemented):**

- **Handlers:** in both catch blocks, save the intended amount when the refund branch was reached. This is not enough alone. If `retrievePI` failed on an uncaptured booking, that row needs a void. A Stripe outage makes `retrievePI` and `createRefund` fail together, so the handler cannot tell which case it is in.
- **Sweep:** read the PaymentIntent first. Uncaptured: void it, reset the amount and move `payment_status` to `canceled`. Succeeded: refund the saved amount. Canceled: clear the flag. A NULL row that is already captured stays flagged for manual handling, because no `cancelled_by` column exists and the owed amount cannot be re-derived for a client cancel.
- **Display:** `derivePaymentStatus` and `clientTransactions` read an amount above 0 as refunded, so they must also check `refund_failed`. The `missed` path already has this flaw today.
- **Response:** return `refund_amount: 0` when the refund failed. Both clients show this value.
- **Size:** about the size of 01-18: two controllers, one cron, two read paths and tests, with no migration and no new field. It would again be proven only against mocks.

**If you ever refund a stuck row by hand, refund the full amount.** From the code: the `charge.refunded` webhook then writes the refunded amount, and the sweep calls `createRefund` with it. After a full refund Stripe should reject that, leaving a stuck flag and log noise. After a partial refund the sweep could refund the same amount again.

### 2. Correction: `PATCH /expert/bookings/:id/status` does not accept `cancelled`

The 01-18 note, `deferred-items.md` and the dispatch all said an expert could mark a past session cancelled with no money moving. **That is wrong, so there is no D-17 product question on this route.**

- `statusSchema` allows only `missed` and `completed`, with a comment explaining why (CR-06). I ran it: `cancelled` fails, `missed` and `completed` pass. The route applies it through `validate`, which returns 422. I did not call the route with `cancelled` itself.
- The handler's docblock and `openapi/clickme-api.yaml` still say `cancelled` is allowed. That is doc drift, now logged.
- A smaller real point: `missed` on an already captured past session also moves no money. Neither client calls this route (iOS `main` has an unused API method, and Android HEAD `2d04c4ce` has none). Logged as low priority.

### 3. An edge case changed by 01-18

If `retrievePI` fails on a non-pending booking within 24 hours, the handler now attempts a refund where it made no Stripe call before. If that PaymentIntent is only authorized, Stripe is expected to reject it, `refund_failed` is set and the sweep voids the hold. No test covers the full sequence on real Stripe. A code comment in `expirePastSessions.js` records a live probe of that same rejection, but I did not repeat it.

Two side effects of that path:

- The API returns the full `refund_amount` although the outcome is a void.
- The sweep does not move `payment_status`, so the row keeps `requires_capture` with a canceled PaymentIntent. It is not captured, because `cancelled` is not a capture candidate.

**New finding, client cancel only and not part of this wave:** the same `retrievePI` failure within 24 hours gives a refund of 0, no Stripe call and no flag. The hold stays on the card with nothing retrying it, until the authorization lapses. Logged in `deferred-items.md`.

### 4. This smoke does not prove the refund

The captured-refund branch has **never run on real Stripe**, and the smoke cannot reach it safely on live data. It exercises the void path only. `git diff d356fdc 3899d63` also shows the void branch was **not changed** by this wave, so a pass is evidence that the deploy did not break it. It says nothing about the code BACK-19 changed. The only real test of that code would be the local Stripe test-mode run you dropped (Open Q7).

### 5. Wave 3a is live and unverified

- Its real-card smoke was not run, by your decision, so BACK-06 and BACK-07 stay Pending. This smoke does not cover them.
- Whether a paid booking was made during wave 3a is unknown.
- **Rollback:** after this push, `ddfe5bf` is no longer a clean way back. `d356fdc` is the target for this wave, and it contains the unverified card code.

### 6. Still open from wave 2

- The `pending_approval` hold after `end_time` stays until `expireBookings` voids it, up to about 12 hours after the request. You have not confirmed this explicitly.
- The confirm orphaned hold: when the confirm insert fails with no replay, the authorized PaymentIntent is not voided. This needs your decision before Phase 4 payment UAT. It also applies to step 1 below, see S1.

## Task 1: Gate and push bundle (done)

### Full gate (run on master at 3899d63)

| Check | Result |
|-------|--------|
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | `Test Suites: 128 passed, 128 total`; `Tests: 2968 passed, 2968 total` |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

- `tests/services/redis.test.js` did not run (needs REDIS_URL).
- No file failed in this run, so no isolated rerun was needed. Earlier runs had parallel flakiness whose cause is not established, and one clean run does not rule it out.
- `git status --porcelain -- src tests openapi docs supabase scripts` prints one line: `?? scripts/uat-seed-profile.js`, the same pre-existing untracked file. It is not part of the push. No tracked file in the repo is modified.

### Push bundle

- Production SHA now (`GET /health`): `d356fdc` (`{"status":"success","commit":"d356fdc"}`). `git ls-remote origin main` also shows `d356fdc`, after a fetch, so no other session has moved it.
- Target SHA (`git rev-parse --short=7 master`): `3899d63`
- `git status -sb`: `## master...origin/main [ahead 2]`. `master..origin/main` is 0, so the push is a fast-forward.
- Diff against origin/main: 5 files, 226 insertions, 58 deletions. **The only runtime file is `src/controllers/expertBooking.controller.js`.**
- **No migration or dependency change:** `git diff --name-status origin/main master -- supabase package.json package-lock.json railway.json` prints nothing.
- **Going back is code-only:** the previous state is `d356fdc`.
- Push command (you only): `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`

| Commit | Plan | Subject |
|--------|------|---------|
| ccd586e | 01-18 | fix(ios-p1/BACK-19): expert-initiated cancel always refunds the client in full (D-17) |
| 3899d63 | 01-18 | docs(ios-p1/BACK-19): document the expert-cancel full refund policy |

## Task 2: Checkpoint (PENDING, user action)

**A. Decide note 1**, then push: `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`, and wait for Railway to report the deploy healthy. There is no migration to apply first.

**B. Smoke.** Production runs live Stripe with a real card you own.

### What to run

| Level | Steps | Holds | What it proves |
|-------|-------|-------|----------------|
| **Minimum** | 1 to 4 on one build | 1 | **The void path works on production. Step 3 matters most.** |
| Full D-12 | 1 to 4 on build 6, then again on Android, plus 5 | 2 | Also both expert apps and both client displays. From code read on iOS `main` and Android HEAD `2d04c4ce`, not the shipped binaries, both call the same `POST /expert/bookings/:id/cancel`, so a second run adds client checks, not server proof |
| No money | Step 5 only, and have the expert cancel the free booking | 0 | The deployed handler runs and sends the push. **Proves nothing about Stripe.** BACK-19 would stay Pending |

Steps 1 to 4 are the checks that matter. Step 5 cannot be affected by this wave's code, because the only runtime change is the expert cancel handler.

### Rules for paid booking P

- Cheapest paid topic, starting **2 to 5 days from now**. A slot more than 6 days out is refused.
- **Neither side joins a call on it. Do not reschedule it.** Cancel it in the same sitting.
- Run one build at a time, so there is only ever one hold.
- In the Stripe Dashboard, **only look. Do not click Capture or Refund.**

Why, from the code:

- A connected call moves P to `in_progress`, which cannot be cancelled, and it is captured at end+15.
- If only the expert joins and the session ends, that is a client no-show, also captured.
- A reschedule can void the hold and convert the booking to a charge at T-24h.

If you forget P: an accepted booking nobody joined is voided after its end. That comes from the sweep code and is covered by mocked tests only.

**Cost:** one real hold per run for the topic's full price, released on cancel. Your bank may show a pending line for some days after the void; the Stripe state is the reliable answer.

### Read-only query (Supabase SQL editor)

**Q1:**
```sql
select id, status, payment_status, refund_failed, refund_amount_minor_units, payment_intent_id, stripe_account_id
from bookings
where client_id = (select id from auth.users where email = '<client email>')
order by created_at desc limit 1;
```

### Steps

1. **Book P as the client** and pay with your card. Complete 3DS if asked. Q1 shows `pending_approval` and `requires_capture`. If the app shows an error, see S1.
2. **Accept P as the expert.** Q1 shows `confirmed`, still `requires_capture`. Accepting does not capture. If it shows `captured`, see S2.
3. **Cancel P as the expert, then prove the hold is gone. All of these must hold, because the app reports success even when the Stripe call failed:**
   - Q1: `status` is `cancelled`, `payment_status` is `canceled`, `refund_failed` is not true.
   - Stripe Dashboard, Connected accounts, the account `stripe_account_id` from Q1, Payments: the PaymentIntent `payment_intent_id` from Q1 shows canceled, with nothing captured or refunded.
   - If not, see S3.
4. **As the client:** P shows as cancelled, and the cancellation push arrived. A missing push is worth reporting but does not affect the money.
5. **Base checks, separate free booking only:** sign in, make a free booking, join a call on it from both sides, chat both ways. Never use P for this.

### Stop conditions

- **S1, step 1 shows an error after you paid.** There may be no booking, and a hold may be left behind (note 6). Look on the expert's connected account for an uncaptured payment and tell Claude. The app cannot release it, because no booking links to it. It stays until the authorization lapses, or until you cancel that payment yourself in the Dashboard.
- **S2, before cancelling, P shows `captured` or `in_progress`, or its end time passes.** **Do not cancel, and tell Claude at once.** Cancelling a captured P would be the first real refund, and `in_progress` cannot be cancelled and is captured at end+15.
- **S3, cancel succeeded but `refund_failed` is true, or the PaymentIntent is still uncaptured.** The hold is not released. The sweep retries every 30 minutes, so wait for one sweep and check again.
  - Trust the Dashboard over `payment_status`. A void done by the sweep leaves `requires_capture` in the row.
  - If it is still uncaptured, you can cancel that payment yourself in the Dashboard, and tell Claude. The flag may then stay stuck, because the sweep's void of an already canceled payment should fail. That is log noise, not money.
- **S4, the expert cancel returns an error, or P stays active.** Try once more. If it still fails, stop and tell Claude with the message and the time. The hold remains. Wave 3b may need to go back to `d356fdc`.
- **S5, the Dashboard shows the payment as succeeded or refunded at any point.** Stop and tell Claude. That means a real charge, which this smoke must never cause.

### What this smoke cannot show

| Check | Can it? | Note |
|-------|---------|------|
| Full release of an authorized hold | Yes | The only money check here |
| A real refund of a captured booking | **No** | Notes 1 and 4. Mocked tests only |
| A failed refund being retried | **No** | Note 1. Neither client can force it |
| The `retrievePI` failure edge | **No** | Note 3. Neither client can force it |

### Required end state

- Every P from this smoke is `cancelled`, and its PaymentIntent is canceled on Stripe.
- This shows no P from this smoke:
  ```sql
  select id, status, payment_status, refund_failed, payment_intent_id from bookings
  where client_id = (select id from auth.users where email = '<client email>')
    and (payment_status = 'requires_capture' or refund_failed = true);
  ```
  It covers the whole account, so a row may be an older booking. Tell Claude either way.
- No charge from this smoke on your card. A pending line that later drops off is fine.
- Saved cards are untouched by this smoke. Cancel the free booking if you do not want it.

**After you reply, Claude runs (read-only):** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" rev-list --count origin/main..master` must print 0, and `curl -fsS https://clickme-backend-production.up.railway.app/health` must contain `"commit":"3899d63"`. Claude then records your results here.

**Resume signal:** reply "wave 3b deployed" with your choice on note 1, then any step that failed (or "all passed"), which level you ran, and whether the end state holds.

## Deviations from Plan

- **Gate command:** ran with `--testPathIgnorePatterns=tests/services/redis.test.js` instead of `REDIS_URL=redis://localhost:6379 npm test` (no local Redis; the dispatch named this as the gate), so `redis.test.js` did not run. Recorded in `.planning/WINDOWS.md`.
- **`status --porcelain` not literally empty:** the pre-existing untracked `scripts/uat-seed-profile.js`, left untouched.
- **[Rule 2 - Missing critical] Checklist tightened from the plan's text.** Read together, the plan's steps could charge the card, leave a hold, or pass when the Stripe call failed. Changes:
  - Plan step 1 says "join a call" and step 2 books a paid session, with nothing keeping them apart. Base checks now use a separate free booking, with no join on P from either side (`CANCELLABLE_STATUSES`, `expirePastSessions.js`, `completionCapture.js`).
  - Plan step 3 says "inside 24 hours if you can". Removed, with P now 2 to 5 days out and no reschedule. The void branch has no time check, so a close start tests nothing extra and shortens the margin before end+15.
  - Plan step 4 checks the Dashboard only. Added Q1 with `refund_failed`, because expert cancel returns 200 when the Stripe call fails, and a warning not to click Capture or Refund.
  - Added a check at step 2 that accepting did not capture, the stop conditions, the cost, the end state and the table of what the smoke cannot show.
  - Added three levels so the minimum is clear, because the last smoke was skipped. The plan and D-12 ask for both builds; the full level still does. **The base checks are marked as lower value, which is a judgment call of mine against D-12.**
- **[Rule 1 - Correction to the record] The PATCH item from 01-18 was wrong.** `deferred-items.md` entry closed and the STATE.md blocker text corrected. No code changed.
- **[Rule 3 - Out of scope, logged] New deferred items:** the client-cancel hold left with no flag (note 3), the PATCH doc drift and the `missed` point (note 2). Added to `deferred-items.md`.
- **The dispatch's premise that BACK-19 widens the path significantly was checked and narrowed.** See note 1. It rests on reading the code; QA is the check against live data.
- **`01-USER-SETUP.md` not generated** even though the plan has `user_setup`. The push and the Dashboard check are fully written in Task 2 above, as in 01-17.
- **Commits on `main`:** `git.base-branch --is-protected main` returns `true`, but `branching_strategy` is `none`, the dispatch named this branch, and plans 01-01 to 01-18 ran the same way. Only planning docs were committed.

## Threat Coverage

T-01-39 (wave-3b deploy): the isolated push range and green gate are done. The post-deploy `/health` check and the live expert-cancel smoke are Task 2. The smoke covers a full release only, so for a captured booking this threat stays mitigated by mocked tests alone. No new security surface: this plan changes no code.

## Next Phase Readiness

Blocked on Task 2 and on your choice in note 1. BACK-19 stays Pending until the push and the smoke results are recorded here. BACK-06 and BACK-07 stay Pending.

## Self-Check: PASSED (record checks only; Task 2 not run)

- This SUMMARY contains `BACK-19` and lists every commit in `origin/main..master` with its plan id, the production SHA and the target SHA.
- `git log origin/main..master` holds exactly `ccd586e` and `3899d63`, both from plan 01-18.
- `git rev-list --count master..origin/main` = 0, and `git ls-remote origin main` = `d356fdc`; nothing pushed by Claude.
- No backend file changed in this plan: `git status --porcelain` in the backend shows no tracked change.
- The columns in Q1, QA and QB match the code that reads and writes them.
- Task 2 is not done, so `status: in-progress`, `requirements-completed: []`, and no requirement is marked complete.
