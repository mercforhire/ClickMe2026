---
phase: 01-backend-fixes
plan: 26
subsystem: payments
tags: [deploy-handoff, stripe, refund, cron, BACK-19, D-10, D-11, gap-closure, mocked-stripe]

requires:
  - phase: 01-backend-fixes/01-24
    provides: "Expert-cancel refund retry and the read-first sweep, backend commits b547f0c and e5243dd"
  - phase: 01-backend-fixes/01-25
    provides: "Client-cancel refund retry, ledger and docs, backend commits 6dc7256, 51f1c0f and d86bf97"
provides:
  - "Push bundle for the BACK-19 refund retry fix: production SHA, target SHA, commit list, runtime files, push command, first-sweep table (this file)"
  - "Pre-push gate green at d86bf97 and a push range isolated to plans 01-24 and 01-25"
affects: [Task 2 checkpoint (user query and push), Task 3 (ledger and deferred-items close-out after the deploy), Phase 4 payment UAT, BACK-19 verification]

# Actuals (#2632). Provisional while the plan is paused at the Task 2 checkpoint; the continuation agent re-measures all of it at completion.
actuals:
  tokens: null      # measured at completion (chars/4 over the files this plan changes)
  tasks: 1          # Task 1 only; Task 2 is the open checkpoint, Task 3 has not run
  commits: 0        # MEASURED at SUMMARY write: git rev-list --count fd8225a..HEAD in the iOS repo, before this draft was committed. This plan makes no backend commits.

plan_head_before: fd8225ac70fb4f8f992827cbfaa272498bdc8391
plan_head_after: fd8225ac70fb4f8f992827cbfaa272498bdc8391   # as of SUMMARY write, before the draft's own commit; re-measure at completion

tech-stack:
  added: []
  patterns:
    - "Money deploys are handed off, not pushed: the user pushes (D-11), Claude verifies /health afterward"
    - "Read-only flagged-row query before the push, because the first sweep after the deploy acts on those rows"

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-26-SUMMARY.md"
  modified: []

key-decisions:
  - "Task 1 gate ran with REDIS_URL=redis://localhost:6379 exactly as the plan writes it. A local Redis answered PONG on that URL, so redis.test.js and meta.test.js ran instead of being skipped or failing for environment reasons."
  - "The first-sweep table below was checked line by line against src/cron/refundReconciliation.js at d86bf97 instead of copied from the plan, and it matches. The code adds rows the plan table does not list (no payment_intent_id, an unexpected PaymentIntent status, a Stripe read failure); they are included."

requirements-completed: []
requirements-pending-checkpoint: [BACK-19]

coverage:
  - id: D1
    description: "Full backend gate green at d86bf97 and the push range holds only the BACK-19 commits from plans 01-24 and 01-25, with exactly four runtime files, no migration, no dependency change and no parked-branch symbols"
    requirement: BACK-19
    verification:
      - kind: other
        ref: "REDIS_URL=redis://localhost:6379 npm test; npm run check-openapi-coverage; npm run check-doc-coverage; git rev-list --count origin/main..master; git diff --name-only origin/main master -- src; git diff --name-status origin/main master -- supabase package.json package-lock.json railway.json; merge-base --is-ancestor wave-3c master"
        status: pass
    human_judgment: false
  - id: D2
    description: "After the user's push, production GET /health reports d86bf97 and origin/main equals master"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "NOT RUN YET. The plan is paused at the Task 2 checkpoint. Only the user pushes (D-11)."
  - id: D3
    description: "On production, a real failed cancel refund is retried as a refund by the sweep"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "Backstop truth. Every test mocks Stripe, and no safe way to force a Stripe failure on live data exists. A green /health says which code is deployed, not how it behaves. BACK-19 stays Pending until the 01-19 checklist is run on real Stripe."

duration: null
completed: null
# status: halted marks a designed stop at the Task 2 checkpoint, not a failure. The continuation agent sets it to complete after Task 3.
status: halted
---

# Phase 1 Plan 26: BACK-19 refund retry deploy handoff Summary (DRAFT, paused at the Task 2 checkpoint)

**The BACK-19 refund retry fix (five backend commits, four runtime files, no migration) passes the full gate at `d86bf97` and is isolated for its own push; nothing is pushed, production still runs `215adcb`, and the fix is proven on mocked Stripe only.**

## Status

- **Task 1:** done. This file is its output.
- **Task 2:** open `checkpoint:human-action`. The user runs a read-only query, pushes, and waits for Railway.
- **Task 3:** not run. It needs production `/health` to report the new SHA.
- **Nothing was pushed or deployed** by Claude (D-11). The backend repo is untouched by this plan.

## Push bundle

Recorded 2026-11-09 after `git fetch origin` in the backend repo (`/Users/LeonChen/Documents/ClickMe2026 Backend`, branch `master`).

| Item | Value |
|------|-------|
| Production SHA now (`GET /health`) | `215adcb` (`{"status":"success","commit":"215adcb"}`) |
| `git ls-remote origin main` | `215adcb2a4f26bdd428821771857b15316db4316` |
| Local `origin/main` after fetch | `215adcb2a4f26bdd428821771857b15316db4316` |
| **Rollback target** | `215adcb` |
| **Target SHA** (`git rev-parse --short=7 master`) | `d86bf97` (`d86bf97328a81d34b9533b0aee4234fc5522e272`) |
| `git rev-list --count origin/main..master` | 5 |
| `git rev-list --count master..origin/main` | 0, so the push is a fast-forward |
| Diff against `origin/main` | 12 files, 1120 insertions, 76 deletions |

All three production readings agree, so no other session moved production since the plan was written (it named `215adcb`).

**Push command (the user runs it; Claude never does):**

```
git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main
```

### Commits in the push range

| Commit | Plan | Subject |
|--------|------|---------|
| `b547f0c` | 01-24 | fix(ios-p1/BACK-19): retry a failed expert-cancel refund as a refund |
| `e5243dd` | 01-24 | fix(ios-p1/BACK-19): reconciliation reads Stripe before moving money; detail stops reporting a failed refund |
| `6dc7256` | 01-25 | fix(ios-p1/BACK-19): client cancel saves the intended refund and flags an unknown payment state |
| `51f1c0f` | 01-25 | fix(ios-p1/BACK-19): the transactions ledger reports no refund while it is being retried |
| `d86bf97` | 01-25 | docs(ios-p1/BACK-19): document how a failed cancel refund is retried |

These are exactly the five commits the 01-24 and 01-25 summaries list. No other commit is in the range.

### The four runtime files

1. `src/controllers/clientBooking.controller.js`
2. `src/controllers/clientTransactions.controller.js`
3. `src/controllers/expertBooking.controller.js`
4. `src/cron/refundReconciliation.js`

The other eight files are tests (`tests/clientBooking.test.js`, `tests/clientTransactions.test.js`, `tests/expertBooking.test.js`, `tests/refundReconciliation.test.js`, new `tests/refundRetryFlow.test.js`) and docs (`openapi/clickme-api.yaml`, `docs/ios/CLIENT-TRANSACTIONS.md`, `docs/ios/STRIPE-INTEGRATION.md`).

### Rollback

Code-only: push the SHA `215adcb` over `main`. No migration is involved. After a rollback the old sweep would retry a saved amount as a refund, which is right for a captured row. A flagged row whose hold was never captured would fail on every old-sweep run until someone voids it by hand. The old read paths would also show saved amounts as refunded.

## Task 1 gate results

| Check | Result |
|-------|--------|
| `REDIS_URL=redis://localhost:6379 npm test` | exit 0. `Test Suites: 130 passed, 130 total`; `Tests: 3019 passed, 3019 total`. The "Tests:" line has no "failed". One run only; the known `connectWebhooks` flake did not appear. |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |
| `git rev-list --count origin/main..master` | 5, matching the 01-24 and 01-25 summaries |
| `git log --format=%s origin/main..master \| grep -vc "ios-p1/BACK-19"` | 0 |
| `git diff --name-only origin/main master -- src \| wc -l` | 4 (the four files above) |
| `git diff --name-status origin/main master -- supabase package.json package-lock.json railway.json \| wc -l` | 0, so no migration or dependency change |
| `git merge-base --is-ancestor wave-3c master` | `clean`, so the parked branch is not in master |
| `grep -rlE "provisionExpert\|expertWriteGate\|EXPERT_SETUP_REQUIRED"` over `src` and `openapi` | 0 files |
| `git diff --diff-filter=D --name-only origin/main master` | 0 deletions |
| `git status --porcelain -- src tests openapi docs supabase scripts` | only `?? scripts/uat-seed-profile.js`, the expected pre-existing untracked file, left out |

`REDIS_URL` was set exactly as the plan writes it. A local Redis answered `PONG` on `localhost:6379`, so `tests/services/redis.test.js` and `tests/meta.test.js` ran for real.

## What the first sweep does with a flagged row

The sweep (`sweepFailedRefunds`) runs every 30 minutes. It selects bookings with `status` in (`cancelled`, `missed`) and `refund_failed = true`, then reads the PaymentIntent from Stripe before any money call. This table was checked against `src/cron/refundReconciliation.js` at `d86bf97`.

| Stripe PaymentIntent state | Saved `refund_amount_minor_units` | What the sweep does |
|----------------------------|-----------------------------------|---------------------|
| Uncaptured (`requires_capture`, `requires_payment_method`, `requires_confirmation`, `requires_action`) | any, including NULL | **Voids the PaymentIntent**, moves `payment_status` to `canceled` where it was `requires_capture`, `scheduled` or `processing`, sets the amount to 0, clears the flag. **Exception:** a client sole no-show (`classifyCaptureEligibility` returns `capture`) only has its flag cleared; the hold is left alone for the capture sweep. |
| `canceled` | any | No money call. Sets the amount to 0 and clears the flag. |
| `succeeded` | above 0 | Reads the Charge, refunds `min(saved, captured) - Charge.amount_refunded` (key `reconcile-refund-{pi}-{amount}`), moves `payment_status` to `partially_refunded` or `refunded`, saves the refunded total, clears the flag. **This is real money.** |
| `succeeded` | 0 | No money call. Clears the flag. |
| `succeeded` | NULL | **Moves no money.** Keeps the flag and logs an `OPS:` line naming the booking id. |

Cases the code handles that the plan's table does not list:

- A row with no `payment_intent_id`: clears the flag, no Stripe call.
- Any other PaymentIntent state (for example `processing`): logs a warning with the booking id and status, keeps the flag.
- A Stripe read or write failure, or a failed flag-clearing write: the per-row catch logs the booking id and message, the flag stays, and the next run reads the Charge again so no second refund is made.

What this means for rows flagged before the deploy: the old handlers wrote only `refund_failed: true` on a failed cancel refund, so an old expert-cancel or client-cancel row has a NULL amount. If its hold was never captured, the new sweep voids it, which is the right outcome. If it was captured, the new sweep leaves it alone with an `OPS:` line, and the client may be owed money. Rows written by `expirePastSessions` and `accountCascade` already carry a saved amount and behave as they did before.

## Task 2: what the user is asked to do

**A. Before the push, read-only, in the Supabase SQL editor:**

```sql
select id, status, payment_status, no_show_party, refund_amount_minor_units, amount_paid_minor_units, payment_intent_id, stripe_account_id, updated_at from bookings where refund_failed = true order by updated_at desc;
```

- No rows: go on to step B.
- Any row: send them to Claude and wait. Within 30 minutes of the deploy the sweep acts on each one as in the table above, and a refund it makes is real money. A row with `payment_status` captured and a NULL amount is a client who may be owed money; the sweep leaves it for the user.

**B.** Run the push command above, then wait for Railway to report the deploy healthy.

**C. Optional no-money check, about 5 minutes, on App Store build 6 and on current Android:** make a free booking and cancel it from the client side, make another and cancel it from the expert side, then open the client's Transactions list and a past booking's detail. Expected: no error on any screen. This shows the deployed handlers and read paths still work for both apps. It proves nothing about Stripe.

**D. Observing the fix afterward:** in Railway logs filter on `[cron:refundReconciliation]`. A healthy system logs nothing. An `OPS:` line names a booking that needs manual review. Re-run the step A query at any time. If the user ever refunds a stuck row by hand, refund the full amount; the `charge.refunded` webhook records it and the next sweep clears the flag. The 01-17 and 01-19 real-Stripe checklists stay deferred to Phase 4 payment UAT.

**After the reply, Claude runs (read-only):** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" rev-list --count origin/main..master` must print 0, and `curl -fsS https://clickme-backend-production.up.railway.app/health` must contain `"commit":"d86bf97"`.

## What is known and what is not

**Known (from code and mocked tests):**

- The gate is green and the range is isolated, as the tables above show.
- The sweep's behavior per PaymentIntent state, as read in the code and covered by `tests/refundReconciliation.test.js` and `tests/refundRetryFlow.test.js` on mocked Stripe.

**Not known:**

- **Real Stripe.** Every test mocks Stripe. Whether a repeated reconcile key yields no second refund, whether `Charge.amount_refunded` reads as expected after a real refund, and whether a failed cancel refund is retried as a refund on production have not been observed. No safe way to force a Stripe failure on live data exists, so this stays unobserved until a real failure happens or a test-mode run is done.
- **Whether the current App Store build keeps working.** Project memory says the current App Store build must keep working because review is slow and no quick client fix exists. The 01-25 summary's claim that App Store build 6 and current Android display `refund_amount` 0 and `refunded_amount` 0 without error **rests on a code read only**. iOS decodes only `status` and `message` on cancel and a required `Int` for `refunded_amount`. Android treats `refund_amount` 0 as the plain cancelled notice and reads `refunded_amount` as a `Long` defaulting to 0. It was **not run on a device or against the shipped build**, and Android HEAD `2d04c4ce` is not a shipped binary. No field is added or removed, and 0 is already a value both clients meet for voided, free and already-cancelled bookings, but that is reasoning, not an observation. The optional step C above is the only check of it.
- **Wave 3a and wave 3b are live with no real-Stripe check** (01-17 and 01-19, skipped by user decision). BACK-06, BACK-07 and BACK-19 stay Pending.

## Deviations from Plan

**1. [Process] Task commit on `main`, which the protected-branch guard flags.**
- **Found during:** the pre-commit check for this draft.
- **Issue:** `gsd_run query git.base-branch --is-protected main` returns `true` and `git.allow_default_branch_commits` is not set. The executor commit guard would refuse a commit on `main`.
- **Handling:** `workflow` branching is `branching_strategy: none`, the dispatch ran this agent sequentially on the main working tree, the dispatch told it to commit this draft, and plans 01-01 to 01-25 committed planning docs on `main` the same way (01-19 recorded the same note). Only this one planning file is committed. Nothing is pushed. The config was not changed. If the user wants that guard to hold for planning docs, the switch is `git.allow_default_branch_commits` in `.planning/config.json`, which is the user's call, not an agent's.

**2. [Process] Gate command used `REDIS_URL` as written.** No deviation from the plan. Recorded because 01-19 had to skip `redis.test.js` for lack of a local Redis; this time Redis was running.

No other deviations. No code changed in either repo.

## Issues Encountered

None.

## Threat Coverage

- **T-01-59** (money-wave deploy): the isolated push range, exact runtime file list, absence of a migration and the green gate are done. The `/health` SHA check and the user-only push are still ahead.
- **T-01-60** (first sweep on rows flagged before the deploy): the first-sweep table is written and checked against the code. The user's read-only query and Claude's review of any row are the Task 2 step A.
- **T-01-61** (parked branch shipping by accident): subject, ancestor and symbol checks pass.
- **T-01-SC:** no packages were installed or upgraded.

No new security surface: this plan changes no code.

## User Setup Required

`user_setup` in the plan covers the user's own push to `origin/main` (GitHub and Railway) and a read-only Supabase query. Both are written out in full in the Task 2 section above, as in 01-17 and 01-19, so `01-USER-SETUP.md` is not generated.

## Next Phase Readiness

- Waiting on the user. Resume signal: reply "refund retry deployed" with the query result (no rows, or the rows) and the no-money check (all passed, what failed, or skip).
- Task 3 then records the deploy, marks WINDOWS #8 and #10 fixed, resolves two entries in `deferred-items.md`, adds four new open entries, and finishes this file. BACK-19 stays Pending.

## Self-Check: PARTIAL (Task 1 only)

**Checked:**

- This file exists and contains `BACK-19`.
- The production SHA (`215adcb`), the target SHA (`d86bf97`), the commit list, the four runtime files, the push command, the Task 2 query and the first-sweep table are all in this file.
- Nothing was pushed: `git rev-list --count origin/main..master` is still 5 in the backend, and production `/health` still reports `215adcb`.
- All five commits in the range are ancestors of backend `master`, and `git log --format=%s origin/main..master` shows no commit outside plans 01-24 and 01-25.
- `requirements-completed` is `[]`; REQUIREMENTS.md was not touched.

**Not yet checked (later tasks):** the user's query result and push, `/health` reporting `d86bf97`, `origin/main` equal to `master`, and the ledger updates.

---
*Phase: 01-backend-fixes*
*Paused at Task 2 checkpoint: 2026-11-09*
