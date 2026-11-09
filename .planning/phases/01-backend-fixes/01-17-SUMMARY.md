---
phase: 01-backend-fixes
plan: 17
subsystem: payments
tags: [deploy-handoff, wave-3a, smoke-checklist, stripe, saved-cards, connect, clones, PAYMENT_METHOD_IN_USE]

requires:
  - phase: 01-backend-fixes/01-15
    provides: "wave 2 live; production and origin/main at ddfe5bf"
  - phase: 01-backend-fixes/01-16
    provides: "BACK-06 and BACK-07 commits 0a18772 and d356fdc on backend master"
provides:
  - "Wave-3a push bundle, full gate green at d356fdc"
  - "Wave 3a live in production at d356fdc (the user pushed; /health and git checked by Claude). Real-card smoke not run, by user decision"
  - "The real-card smoke checklist below, still to be run before BACK-06 and BACK-07 close"
affects: [01-18 onward (the user chose to continue without the 3a smoke), Phase 4 payment methods UI and payment UAT (latest point to run the checklist)]

actuals:
  tokens: 6432
  # tasks counts Task 1 only. Task 2 is half done: deployment yes, smoke no.
  tasks: 1
  commits: 1

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-17-SUMMARY.md"
  modified:
    - ".planning/phases/01-backend-fixes/deferred-items.md"
    - ".planning/STATE.md"
    - ".planning/WINDOWS.md"

key-decisions:
  - "The smoke checklist reads the clone id out of connected_pm_clones before the card is removed, because eviction deletes the only record of it and a count of 0 afterwards proves nothing if no clone existed"
  - "The paid booking must start 2 to 5 days out and is never joined by either side or rescheduled, because a connected call or a client no-show is captured at end+15 and a reschedule can convert it to a T-24h charge"
  - "The hold is proven released from the PaymentIntent state, not the app, because client cancel returns 200 even when the Stripe void failed (it sets refund_failed)"
  - "User decision 2026-11-08: skip the wave-3a smoke and continue to the next wave. BACK-06 and BACK-07 stay Pending until the checklist has been run, at the latest during Phase 4 payment UAT"

# status: complete below only means the plan is finished for position purposes. It does not mean the smoke was run.
smoke: not-run-user-decision
requirements-completed: []
requirements-pending-checkpoint: [BACK-06, BACK-07]

coverage:
  - id: D1
    description: "Full backend gate green at d356fdc; the push range is exactly the two plan 01-16 commits; production and target SHAs recorded"
    requirement: BACK-07
    verification:
      - kind: other
        ref: "npm test -- --testPathIgnorePatterns=tests/services/redis.test.js; check-openapi-coverage; check-doc-coverage; git log origin/main..master; git ls-remote origin main; GET /health"
        status: pass
    human_judgment: false
  - id: D2
    description: "On live Stripe with a real card, on build 6 and Android: a card with a real clone is blocked while its booking is active, then removes cleanly with the clone detached and no cache row left, and a lone or remaining card becomes the default"
    requirement: BACK-07
    verification: []
    human_judgment: true
    rationale: "NOT RUN: the user skipped this on 2026-11-08, so no result exists. Every test mocks Stripe and Supabase, and the D-13 local test-mode run was dropped by user decision (Open Q7). This checklist remains the first real check, and only the user holds the card."
  - id: D3
    description: "Deployment only: origin/main and master both at d356fdc, and production /health reports d356fdc. This says nothing about how the deployed code behaves."
    verification:
      - kind: other
        ref: "git rev-list --count origin/main..master; git rev-list --count master..origin/main; git ls-remote origin main; GET /health"
        status: pass
    human_judgment: false

plan_head_before: 6e0d306f891ee3916d0b7982c1866f280556c4aa
plan_head_after: 73628a123bc4e516745d80923af68fb6b7971b49
# commits counts the iOS repo only, measured from plan_head_before to plan_head_after at SUMMARY write. This plan makes no backend commits; backend master stays at d356fdc.

duration: ~30 min wall clock (Task 1 about 6 min, the rest waiting on the user's push)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 17: Wave 3a close-out Summary (smoke not run by user decision)

**Wave 3a (BACK-06 lone-card default, BACK-07 409 `PAYMENT_METHOD_IN_USE` and clone eviction) is live in production at `d356fdc`, pushed by the user. The real-card smoke was not run, by user decision, so BACK-06 and BACK-07 stay Pending.**

## Smoke not run by user decision

- `status: complete` means only that this plan is finished for position purposes, so 01-18 can start. `halted` would block every plan that depends on this one, which is the opposite of what the user asked for.
- **User, verbatim:** "wave 3a deployed", then, when asked for results: "Skip the testing for this wave and continue to the next wave."
- **Task 1:** done.
- **Task 2, deployment:** done by the user. Claude did not push or deploy (D-11).
- **Task 2, smoke:** not run. No per-client results, no answer on the clone, and no end-state confirmation exist. None of steps 1 to 9 has a result on build 6 or Android.
- **BACK-06 and BACK-07:** still Pending. `requirements.ready-ids` reports both as ready, but it only checks whether sibling plans have finished, not whether a skipped check was run, so they were deliberately not marked complete.

### What is still unknown

- **The real clone detach on a connected account is live in production and has never run against real Stripe.** The mocked tests from 01-16 are the only evidence. D-13's local test-mode run was dropped because this smoke was going to replace it, and now neither has happened.
- **Handoff notes 2, 3, 4, 5 and 7 stay open.** Note 6 stays open too, and is tracked in the STATE.md blockers.
- **Holds:** it is unknown whether the user made any paid booking during this wave, so nothing can be said about holds from this wave. That includes whether any exist.
- **Plan must-haves not established:** the app behavior on both clients (blocked removal, removal after cancel), and the detached card and clone with no `connected_pm_clones` row. The plan's success criterion, "verified with a real card on both shipped clients", is not met.
- **Later waves stack on top of this.** `ddfe5bf` is a clean way back only until the next push. After wave 3b, going back to it would also remove BACK-19, so a problem found later needs a forward fix or a targeted revert. A later smoke also could not tell by itself which wave caused a failure, which weakens the D-10 isolation.

### What was checked after the push

Claude re-ran these read-only on 2026-11-08, and they match what the orchestrator reported:

| Check | Result |
|-------|--------|
| `git rev-list --count origin/main..master` | 0 |
| `git rev-list --count master..origin/main` | 0 |
| `master`, `origin/main`, and `git ls-remote origin main` | all `d356fdc` |
| `git log ddfe5bf..origin/main` | exactly `0a18772` and `d356fdc` |
| `GET /health` | 200 `{"status":"success","commit":"d356fdc"}` |

These show which code is deployed. They do not show how it behaves.

## Task 1: Gate and push bundle (done)

### Full gate (all run on master at d356fdc)

| Check | Result |
|-------|--------|
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | `Test Suites: 128 passed, 128 total`; `Tests: 2959 passed, 2959 total` |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

- `tests/services/redis.test.js` did not run (needs REDIS_URL).
- No file failed in this run, so no isolated rerun was needed. Earlier runs had parallel flakiness whose cause is not established, and one clean run does not rule it out.
- `git status --porcelain -- src tests openapi docs supabase scripts` prints one line: `?? scripts/uat-seed-profile.js`, the same pre-existing untracked file noted in 01-10 and 01-15. It is not part of the push. No tracked file is modified.

### Push bundle

This section records the state before the push.

- Production SHA before the push (`GET /health`): `ddfe5bf` (read 2026-11-08, `{"status":"success","commit":"ddfe5bf"}`). `git ls-remote origin main` also shows `ddfe5bf`, so no other session has moved it.
- Target SHA (`git rev-parse --short=7 master`): `d356fdc`
- `git status -sb`: `## master...origin/main [ahead 2]`. `master..origin/main` is 0, so the push is a fast-forward.
- Diff against origin/main: 8 files, 733 insertions, 28 deletions, under `src`, `tests`, `openapi` and `docs`.
- **No migration or dependency change:** `git diff --name-status origin/main master -- supabase package.json package-lock.json railway.json` prints nothing.
- **Going back is code-only:** with no migration, the previous good state is `ddfe5bf`.
- Push command (user only): `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`

| Commit | Plan | Subject |
|--------|------|---------|
| 0a18772 | 01-16 | fix(ios-p1/BACK-07): detach on connected accounts and evict clones of a deleted card |
| d356fdc | 01-16 | fix(ios-p1/BACK-06,BACK-07): block deleting in-use cards, evict clones, default the lone card |

## Handoff notes: written before the push, read before running the checklist

1. **The clone detach has only run against mocks.** The local test-mode run from D-13 was dropped by your decision (Open Q7), so the checklist below is the first real check, whenever it is run. Getting a real clone needs no special setup: on both clients a paid booking goes through `/bookings/confirm` with a card attached to your platform customer, which creates and caches a clone on the expert's connected account (`booking.controller.js` Path 1). The cost is one real authorization hold for that topic's full price, one per client run, released when you cancel. Nothing is captured if you follow the rules in Task 2. The clone stays after the cancel, so removing the card then hits the real detach.
2. **A card could become undeletable.** Any Stripe error other than `resource_missing` or `payment_method_unexpected_state` returns 502 and keeps the card. If an expert's connected account is closed or unreachable, a client with a clone there may not be able to remove that card. Which error Stripe returns in that case is not established, and the smoke cannot force it. Logged in `deferred-items.md`.
3. **Narrow race.** The in-use check and the eviction are not atomic. If the same client confirms a long-lead booking on a card while deleting it, a new clone could survive and the T-24h sweep could later charge it. Paid long-lead creation is already refused (`LONG_LEAD_NOT_AVAILABLE`), so the remaining route I can see is a reschedule conversion. I did not work through that route in full. Logged in `deferred-items.md`.
4. **Path 3 clones are invisible to eviction.** Fresh-card clones from confirm Path 3 are never cached. The comments call them single-use, and that is untested against Stripe. Both current clients collect cards through a setup-mode sheet on the platform customer, so from reading the code their cards take Path 1, not Path 3. The smoke does not exercise Path 3. Older bookings may have used it.
5. **Client display of the result.**
   - Build 6 does not reload after a successful delete, so a newly promoted card shows as default only after you leave Payment Methods and reopen it.
   - The 409 on both clients: read this session, on iOS `main` and Android HEAD `2d04c4ce`, not on the shipped binaries. Both decode the unknown code to null and keep the server message. iOS restores the row and shows it in a "Something went wrong" alert. Android keeps the card and shows it through `toDialogError` in its remove-error dialog. Custom copy is the logged Android follow-up.
6. **Still open from wave 2.**
   - The `pending_approval` hold after `end_time` stays until `expireBookings` voids it, up to about 12h after the request. You accepted this in effect by pushing wave 2, but have not confirmed it explicitly.
   - The confirm orphaned hold: when the confirm insert fails with no replay, the authorized PaymentIntent is not voided. This needs your decision before Phase 4 payment UAT. It also applies to step 3 below, see stop condition S2.
7. **New from this review: a partly failed delete can spoil a card for one expert.** If eviction detaches a clone and removes its row, and then a later step fails (a second account's 502, or the platform detach), the card stays saved with that clone gone. The clone call uses the fixed idempotency key `clone-{pm}-on-{acct}`, so a later booking with the same card and expert may get the old, detached clone back from Stripe within the key's retention window, and the attach would then fail. Booking with that card and expert would then fail before any hold. Removing and re-adding the card avoids it, because the new card has a new id. This is inferred from the code and untested against Stripe. Logged in `deferred-items.md`.

## Task 2: Deployment done, smoke NOT RUN

**A. Push wave 3a: done by the user.** See "What was checked after the push" above.

**B. Smoke checklist: NOT RUN (user decision, 2026-11-08). Kept here to run later, on BOTH App Store build 6 and the current Android build (D-12).** Production runs live Stripe with a real card you own. Before running it, check the SHAs and notes against what has been deployed since: S1's way back to `ddfe5bf` only holds until the next push.

### What this costs

One real authorization hold per client run, for the full price of the topic you book, on the expert's connected account. Use the cheapest paid topic. Run one client at a time, so there is only ever one hold. Cancel voids it and no money moves. Your bank may keep showing a pending line for some days after the void; the Stripe state is the reliable answer. Adding a card places no hold from ClickMe, though a bank can show its own brief verification line.

### Rules for the paid booking

| Booking | Type | Use it for | Rule |
|---------|------|-----------|------|
| F | Free | Step 1 (call and chat) | Any short slot. |
| P | Paid, cheapest topic, one per client | Steps 3 to 6 | Start **2 to 5 days from now**. **Neither side joins a call on it. Do not reschedule it.** Cancel it in the same sitting. The expert does not need to accept it. |

Why these rules, from the code:

- A connected call moves P to `in_progress`, which a client cannot cancel, and the card is captured at end+15.
- If only the expert joins and the session ends, that is a client no-show, which is also captured.
- A reschedule can void the hold and convert the booking to a charge at T-24h.
- A paid slot more than 6 days out is refused, with no hold. If a client offers one, pick a closer slot.

If you forget P: an unaccepted booking is voided at 12h, and an accepted one nobody joined is voided after its end. Those are read from the sweep code and covered by mocked tests only.

### Read-only queries (Supabase SQL editor)

**Q1, the booking:**
```sql
select id, status, payment_status, stripe_payment_method_id, payment_intent_id, stripe_account_id, refund_failed
from bookings
where client_id = (select id from auth.users where email = '<client email>')
order by created_at desc limit 1;
```

**Q2, the clone:**
```sql
select clone_payment_method_id, connected_account_id, connected_customer_id
from connected_pm_clones
where platform_payment_method_id = '<pm id from Q1>';
```

### Steps, for each client (build 6 first, then Android)

1. **Base checks:** sign in, make free booking F, join a call on F from both sides, chat both ways.
2. **Lone card default (BACK-06):** the client account must have no saved card. If it has one, run Q2 on its pm id if you know it, then remove it; if that fails, see S1. Add one card in Settings → Payment Methods: it shows as the default.
3. **Book P** and pay with that card. If asked for 3DS, complete it. Run Q1: `status` is `pending_approval` or `confirmed`, `payment_status` is `requires_capture`. If the app shows an error here, see S2.
4. **Find the real clone:** run Q2 with the pm id from Q1. It must return a row. **Save all three values now**, because the removal deletes the row and this is the only record of the clone id. If it returns no rows, tell Claude; steps 7 and 8 then do not test a real clone.
5. **Blocked while in use (BACK-07):** try to remove the card. The app shows "This card is linked to an upcoming booking. You can remove it once that booking is completed or cancelled." and the card stays. If the removal succeeds, see S3.
6. **Cancel P and prove the hold is gone:** cancel P before its start. The app reports a refund of 0, which is correct because nothing was captured. Then check all of these:
   - Q1: `status` is `cancelled`, `payment_status` is `canceled`, `refund_failed` is not true.
   - Stripe Dashboard, on the expert's connected account (`stripe_account_id` from Q1): the PaymentIntent (`payment_intent_id` from Q1) is canceled.
   - If not, see S4. Do not go on until the hold is gone.
7. **Remove the card:** it succeeds and leaves the list. This is the first real clone detach. If it fails, see S1.
8. **Check the detach (read-only):**
   - Stripe Dashboard, platform account: the removed card (`pm` id) shows no customer.
   - Stripe Dashboard, the connected account from step 4: the clone id shows no customer. I could not confirm the Dashboard opens a payment method by id. If it does not, open the `connected_customer_id` from step 4 and confirm its payment methods no longer list the card.
   - Supabase: `select count(*) from connected_pm_clones where platform_payment_method_id = '<pm id>';` returns 0.
9. **Default after removal (BACK-06), no booking needed:** add two cards. Make sure the one you will remove is the default, remove it, and the remaining card becomes the default.
   - On build 6, leave Payment Methods and reopen it to see this (note 5). Android reloads by itself.
   - This needs a second card. Adding the same card twice is unverified. If you cannot add two, write "step 9 not run": the logic is covered by mocked tests only.

Before starting the other client, remove the remaining card so that client starts at step 2 with no saved card.

### Stop conditions

- **S1, a removal fails with anything other than the step 5 message.** The card stays saved. Try once more, because a retry resumes from the clones that remain. If it still fails, stop, note the message and the time, and tell Claude. This is the note 2 case, and wave 3a may need to go back to `ddfe5bf`.
- **S2, step 3 shows an error after you paid.** There may be no booking, and a hold may be left behind (note 6). Look on the expert's connected account for an uncaptured payment, and tell Claude. The app cannot release it because no booking links to it. It remains on the card until Stripe's authorization lapses, or until you cancel that payment yourself in the Dashboard.
- **S3, step 5 lets you remove the card.** That is a BACK-07 failure. Still cancel P as in step 6: the void uses the PaymentIntent, not the card. Tell Claude.
- **S4, cancel returned success but the hold is not gone** (`refund_failed` true, or the PaymentIntent is still uncaptured). Tell Claude. A cron retries these every 30 minutes, per its migration header. You can also cancel the payment in the Dashboard yourself.
- **S5, P ever shows `in_progress`, or its end time passes.** Tell Claude at once: the cancel will be refused, and a capture may follow at end+15.

### Which steps a build cannot perform

| Check | Build 6 | Android | Note |
|-------|---------|---------|------|
| Steps 1 to 8 | Yes | Yes | Same server paths on both |
| Step 9, seeing the new default | Only after reopening the screen | Yes, reloads | Note 5 |
| Custom copy for the 409 | No | No | Both show the server message |
| An undeletable card (note 2), the race (note 3), Path 3 (note 4), a spoiled clone (note 7) | No | No | Neither client can force these. This smoke does not test them |
| Charging a removed card | No | No | Deliberately not attempted on live Stripe. The detach in step 8 is the evidence |

### Required end state

- Every paid booking from this smoke is `cancelled`, and its PaymentIntent is canceled on Stripe. This returns 0:
  ```sql
  select count(*) from bookings
  where client_id = (select id from auth.users where email = '<client email>')
    and payment_status = 'requires_capture';
  ```
  It covers the whole account, so a non-zero count may be an older booking. Tell Claude either way.
- No charge from this smoke on your card. A pending line that later drops off is fine.
- Saved cards back to how you want them. Removed cards are gone for good. Re-adding one creates a new `pm` id with no clone until its next paid booking. If you had a default before, set it again.
- F needs no cleanup for money. Cancel it if it is still upcoming and you do not want it.

**When the checklist is run:** report any step that failed (or "all passed"), per client, plus "step 9 not run" if it applies, and whether the end state holds. BACK-06 and BACK-07 can close only after that.

## Deviations from Plan

- **Task 2 smoke not run, by user decision.** Quoted at the top of this file. Steps 1 to 9, the clone answer and the end state have no results. This is a user-authorized skip, not a result. It is logged in STATE.md and `.planning/WINDOWS.md`.
- **SUMMARY status:** the template allows only `complete` or `halted`. `complete` is used so 01-18 can start, and the skip is recorded in the title, at the top of the body and in the `smoke` frontmatter field.
- **Gate command:** ran with `--testPathIgnorePatterns=tests/services/redis.test.js` instead of `REDIS_URL=redis://localhost:6379 npm test` (no local Redis; the dispatch named this as the gate), so `redis.test.js` did not run. Recorded in `.planning/WINDOWS.md`.
- **`status --porcelain` not literally empty:** the pre-existing untracked `scripts/uat-seed-profile.js`, left untouched.
- **[Rule 2 - Missing critical] Checklist tightened from the plan's text.** Read together, the plan's steps could charge the card, leave a hold, or pass without testing the clone. Changes:
  - Plan step 1 says "join a call" and step 3 books a paid session, with nothing keeping them apart. Added the separate F and P bookings, with no join from either side. From `clientBooking.controller.js` `cancellableStatuses` and `expirePastSessions.js` Sweep A and C, including the client no-show capture.
  - Plan step 3 gives no date, and step 5 says the hold "is released". Added the 2 to 5 day window, the no-reschedule rule (`paymentStateMachine.convertToLongLead`), and a hold check against the PaymentIntent, because client cancel returns 200 and only sets `refund_failed` if the Stripe void fails.
  - Plan step 7 only counts rows after the removal. A count of 0 passes even if no clone ever existed, and the clone id needed for step 6's Dashboard check is deleted by the removal. Added the Q2 read before removal, and a fallback through the connected customer.
  - Plan step 8 needs a second card and did not say so, or that build 6 needs a reopen. Added both.
  - Added the stop conditions, cost, end state and the table of what a build cannot perform.
- **[Rule 3 - Out of scope, logged] New deferred item:** note 7, the clone idempotency key after a partly failed delete. Added to `deferred-items.md`. No code changed.
- **New-config scan was indirect.** A grep of the diff for environment variables was not run, because that grep was blocked by the secret-read guard in 01-15. Instead I read `paymentMethods.controller.js`, `connectedPaymentMethodClone.js` and the `stripe.js` diff, and found no new configuration. No package or config file changed.
- **Commits on `main`:** `git.base-branch --is-protected main` returns `true`, but `branching_strategy` is `none`, the dispatch named this branch, and plans 01-01 to 01-16 ran the same way. Only planning docs were committed.
- **`01-USER-SETUP.md` not generated** even though the plan has `user_setup`. The push and the Dashboard checks are fully written in Task 2 above.

## Threat Coverage

T-01-36 (wave-3a deploy) is only partly mitigated. The isolated push range, green gate and post-deploy `/health` check are done. The real-card smoke, the part of the mitigation that confirms block, eviction and detach on live Stripe, was not run. This remains open until the checklist is run. No new security surface: this plan changes no code.

## Next Phase Readiness

- 01-18 can start, by user decision: "continue to the next wave."
- Open debt: BACK-06 and BACK-07 stay Pending until the checklist above has been run, at the latest during Phase 4 payment UAT. Logged in STATE.md and `.planning/WINDOWS.md`.
- Phase 1 cannot honestly close those two requirements until then.

## Self-Check: PARTIAL (record checks only, smoke checks NOT RUN)

This covers what could be checked. It does not cover the behavior of the deployed code, which nobody has checked.

**Checked:**

- This file exists and contains `PAYMENT_METHOD_IN_USE`.
- Commit `73628a1` is an ancestor of HEAD, and `git rev-list --count 6e0d306..73628a1` = 1.
- Deployment: origin/main and master both at `d356fdc`, 0 commits apart in either direction, and `/health` reports `d356fdc`.
- `git log ddfe5bf..origin/main` holds exactly `0a18772` and `d356fdc`, both from plan 01-16.
- `requirements-completed` is `[]`, and no requirement was marked complete by this plan.

**Not checked, because the user skipped the smoke:**

- Steps 1 to 9 on build 6 and on Android.
- A real clone detach, the block on removing an in-use card, and the lone or remaining card default, on live Stripe.
- Whether any hold exists from this wave, and the required end state.
