---
phase: 01-backend-fixes
plan: 26
subsystem: payments
tags: [deploy, stripe, refund, cron, BACK-19, D-10, D-11, gap-closure, mocked-stripe]

requires:
  - phase: 01-backend-fixes/01-24
    provides: "Expert-cancel refund retry and the read-first sweep, backend commits b547f0c and e5243dd"
  - phase: 01-backend-fixes/01-25
    provides: "Client-cancel refund retry, ledger and docs, backend commits 6dc7256, 51f1c0f and d86bf97"
provides:
  - "The BACK-19 refund retry fix live in production at backend d86bf97 (user push, verified by /health, ls-remote and an empty push range)"
  - "Push bundle, flagged-row query result as reported by the user, and first-sweep table"
  - "WINDOWS #8 and #10 fixed; two deferred-items entries resolved (mocked Stripe only); four new open deferred entries"
affects: [Phase 1 verification (BACK-19 gap can be re-verified from code), Phase 4 payment UAT (01-17 and 01-19 checklists), BACK-19 closure]

# Actuals (#2632). Same scale as the plan estimate: chars/4 over the files this plan changed (this file, WINDOWS.md and deferred-items.md added lines).
actuals:
  tokens: 6900
  tasks: 3          # Tasks 1 and 3 by the agent, Task 2 by the user
  commits: 2        # MEASURED: git rev-list --count fd8225a..HEAD in the iOS repo at SUMMARY write (e59c7d4 draft, 7e1bd65 ledger). This plan makes no backend commits.

plan_head_before: fd8225ac70fb4f8f992827cbfaa272498bdc8391
plan_head_after: 7e1bd6555cbd59dd44454ab21201e828db658304   # as of SUMMARY write, before the SUMMARY's own commit

tech-stack:
  added: []
  patterns:
    - "Money deploys are handed off, not pushed: the user pushes (D-11), Claude verifies /health afterward"
    - "Read-only flagged-row query before the push, because the first sweep after the deploy acts on those rows"
    - "A green /health says which code is deployed, not how it behaves; the record says so"

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-26-SUMMARY.md"
  modified:
    - ".planning/WINDOWS.md"
    - ".planning/phases/01-backend-fixes/deferred-items.md"

key-decisions:
  - "Task 1 gate ran with REDIS_URL=redis://localhost:6379 exactly as the plan writes it. A local Redis answered PONG on that URL, so redis.test.js and meta.test.js ran instead of being skipped."
  - "The first-sweep table was checked line by line against src/cron/refundReconciliation.js at d86bf97 instead of copied from the plan, and it matches. The code adds rows the plan table does not list; they are included."
  - "WINDOWS #8 and #10 were marked fixed only after production /health reported d86bf97 and the push range was empty. #3, #5, #6, #11 and #12 stay open: real-Stripe proof is missing and wave 3c stays dropped."
  - "BACK-19 stays Pending and requirements-completed stays empty. The two entries in deferred-items.md are marked resolved with a Resolution line that says the proof is mocked Stripe only."

requirements-completed: []
requirements-pending: [BACK-19]

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
    verification:
      - kind: other
        ref: "curl -fsS https://clickme-backend-production.up.railway.app/health -> {\"status\":\"success\",\"commit\":\"d86bf97\"}; git ls-remote origin main -> d86bf97328a81d34b9533b0aee4234fc5522e272; git rev-list --count origin/main..master -> 0 (re-run by the executor 2026-11-09 after a fetch)"
        status: pass
    human_judgment: false
  - id: D3
    description: "WINDOWS #8 and #10 fixed with open_count 5; deferred-items.md has two resolved entries and four new open entries"
    verification:
      - kind: other
        ref: "grep -c '^open_count: 5' .planning/WINDOWS.md -> 1; grep -c 'accountCascade.cancelActiveBookingsForUser' deferred-items.md -> 2"
        status: pass
    human_judgment: false
  - id: D4
    description: "On production, a real failed cancel refund is retried as a refund by the sweep"
    requirement: BACK-19
    verification: []
    human_judgment: true
    rationale: "Backstop truth. Every test mocks Stripe, and no safe way to force a Stripe failure on live data exists. A green /health says which code is deployed, not how it behaves. BACK-19 stays Pending until the 01-19 checklist is run on real Stripe."
  - id: D5
    description: "App Store build 6 and current Android show refund_amount 0 and refunded_amount 0 without error"
    verification: []
    human_judgment: true
    rationale: "The optional step C no-money check was not reported by the user, so this claim still rests on a code read only."

# Metrics
duration: "about 30 min wall clock (2026-11-09 05:04Z to 05:35Z), mostly the user's wait to push and deploy"
completed: 2026-11-09
status: complete
---

# Phase 1 Plan 26: BACK-19 refund retry deploy Summary

**The BACK-19 refund retry fix (five backend commits, four runtime files, no migration) is live in production at `d86bf97`, confirmed by `/health`, `git ls-remote` and an empty push range; WINDOWS #8 and #10 are fixed, and the fix is proven on mocked Stripe only, so BACK-19 stays Pending.**

## Performance

- **Duration:** about 30 min wall clock, mostly the user's wait to run the query, push and let Railway deploy. Agent work was Task 1 (gate and bundle) and Task 3 (record).
- **Started:** 2026-11-09T05:04Z (approximate; the Task 1 draft was committed at 05:07:51Z)
- **Completed:** 2026-11-09T05:35Z
- **Tasks:** 3 of 3 (Task 2 was done by the user)
- **Files modified:** 3 (this file, `.planning/WINDOWS.md`, `deferred-items.md`). No code changed in either repo.

## Accomplishments

- The pre-push gate was green at `d86bf97` and the push range held only the five BACK-19 commits, so the money deploy was isolated (Task 1).
- The user ran the flagged-row query, pushed and waited for the deploy (Task 2). Production now runs `d86bf97`, up from `215adcb`.
- WINDOWS #8 and #10 are marked fixed, `open_count` is 5 (Task 3).
- `deferred-items.md` closes the two entries this fix addresses, each with a Resolution line that names `d86bf97` and says the proof is mocked Stripe only, and adds four open entries found across plans 01-24 to 01-26.

## Task Commits

All commits are in the iOS repo on `main` (branching_strategy none, as in plans 01-01 to 01-25). Nothing was pushed by the agent in either repo (D-11). This plan makes no backend commits.

1. **Task 1: Pre-push gate and push bundle** - `e59c7d4` (docs; draft of this file with `status: halted`)
2. **Task 2: User checks flagged rows and pushes** - done by the user, no commit
3. **Task 3: Record the deploy and close the ledger items** - `7e1bd65` (docs; `WINDOWS.md` and `deferred-items.md`)

**Plan metadata:** the commit that adds this completed file, then the STATE.md and ROADMAP.md update commit.

## Files Created/Modified

- `.planning/phases/01-backend-fixes/01-26-SUMMARY.md` - this record
- `.planning/WINDOWS.md` - items 8 and 10 set to `fixed` with `gsd-tools windows fixed`, one call per id; `open_count` 7 to 5, `fixed_count` 5 to 7
- `.planning/phases/01-backend-fixes/deferred-items.md` - two entries set to `resolved`, four new `open` entries

## User reply (recorded verbatim)

Task 2 resume reply:

> refund retry deployed, no rows

How each part of the Task 2 instructions is recorded:

| Step | What the user did | Recorded as |
|------|-------------------|-------------|
| A. Flagged-row query | Reported "no rows" | **No rows returned**, as reported by the user. Claude did not see the query output. The reply does not say whether the query ran before the push, so the order is not known. With no flagged rows the first sweep had nothing to act on from before the deploy, if the query ran first. |
| B. Push and deploy | Reported "refund retry deployed" | Confirmed independently, see the deploy checks below. |
| C. Optional no-money check on build 6 and Android | Not mentioned in the reply | **Not reported.** It is not recorded as passed and not recorded as skipped. |
| D. Observing the fix afterward | Nothing to do now | Not applicable. Nobody has looked at the Railway logs for `[cron:refundReconciliation]` as far as this record knows. |

## Deploy checks

Run read-only on 2026-11-09. The orchestrator ran them after the user's reply, and the executor re-ran them after `git fetch origin` in the backend repo (`/Users/LeonChen/Documents/ClickMe2026 Backend`).

| Check | Result |
|-------|--------|
| `git rev-list --count origin/main..master` | `0` (the plan's required value) |
| `git rev-list --count master..origin/main` | `0` |
| `git rev-parse --short=7 master` | `d86bf97` |
| `git rev-parse origin/main` | `d86bf97328a81d34b9533b0aee4234fc5522e272` |
| `git ls-remote origin main` | `d86bf97328a81d34b9533b0aee4234fc5522e272` |
| `curl -fsS https://clickme-backend-production.up.railway.app/health` | `{"status":"success","commit":"d86bf97"}` |

All five readings agree, so `origin/main` equals `master` and production runs the target SHA. The plan's precondition for Task 3 is met. The rollback target stays `215adcb`.

## Push bundle

Recorded 2026-11-09 by Task 1, after `git fetch origin` in the backend repo, before the push.

| Item | Value |
|------|-------|
| Production SHA before the push (`GET /health`) | `215adcb` |
| `git ls-remote origin main` before the push | `215adcb2a4f26bdd428821771857b15316db4316` |
| **Rollback target** | `215adcb` |
| **Target SHA** | `d86bf97` (`d86bf97328a81d34b9533b0aee4234fc5522e272`) |
| `git rev-list --count origin/main..master` before the push | 5 |
| `git rev-list --count master..origin/main` before the push | 0, a fast-forward |
| Diff against `origin/main` before the push | 12 files, 1120 insertions, 76 deletions |

Push command (the user ran it; Claude never does):

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

## Task 3 verify results

| Check | Result |
|-------|--------|
| `grep -c "^open_count: 5" .planning/WINDOWS.md` | `1`. The plan expected 5 and the ledger reports 5, with no other item having changed since the plan was written (baseline 7, minus #8 and #10). |
| `grep -c "accountCascade.cancelActiveBookingsForUser" deferred-items.md` | `2` (the new entry's title and its Found-in line). The plan's check needs a count above 0. |
| WINDOWS status per item | #8 and #10 `fixed`; #3, #5, #6, #11 and #12 `open`; #1, #2, #4, #7 and #9 `fixed` (earlier plans) |
| REQUIREMENTS.md | Not edited. BACK-19 is still Pending. |

## What the first sweep does with a flagged row

The sweep (`sweepFailedRefunds`) runs every 30 minutes. It selects bookings with `status` in (`cancelled`, `missed`) and `refund_failed = true`, then reads the PaymentIntent from Stripe before any money call. Checked against `src/cron/refundReconciliation.js` at `d86bf97`.

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

For rows flagged before the deploy: the old handlers wrote only `refund_failed: true` on a failed cancel refund, so an old expert-cancel or client-cancel row has a NULL amount. If its hold was never captured, the new sweep voids it. If it was captured, the new sweep leaves it alone with an `OPS:` line, and the client may be owed money. The user reported no flagged rows.

## What stays unknown

- **Real Stripe.** Every test mocks Stripe. Whether a repeated reconcile key yields no second refund, whether `Charge.amount_refunded` reads as expected after a real refund, and whether a failed cancel refund is retried as a refund on production have not been observed. No safe way to force a Stripe failure on live data exists, so this stays unobserved until a real failure happens or a test-mode run is done. A green `/health` says which code is deployed, not how it behaves. **BACK-19 stays Pending.**
- **Whether App Store build 6 and current Android keep working with the deployed change.** Step C, the optional no-money check, was **not reported** by the user. The claim in the 01-25 summary that build 6 and current Android display `refund_amount` 0 and `refunded_amount` 0 without error therefore **still rests on a code read only**. iOS decodes only `status` and `message` on cancel and a required `Int` for `refunded_amount`. Android treats `refund_amount` 0 as the plain cancelled notice and reads `refunded_amount` as a `Long` defaulting to 0. Neither was run on a device or against the shipped build, and Android HEAD `2d04c4ce` is not a shipped binary. No field was added or removed, and 0 is a value both clients already meet for voided, free and already-cancelled bookings, but that is reasoning, not an observation.
- **The order of the user's query and push.** The reply gives the query result and the deploy but not their order. "No rows" is the user's report; Claude did not see the output.
- **What the first sweeps did after the deploy.** Nobody has reported the Railway logs for `[cron:refundReconciliation]`. With no flagged rows reported, a healthy system logs nothing, but that was not checked.
- **Wave 3a and wave 3b are live with no real-Stripe check** (01-17 and 01-19, skipped by user decision). BACK-06, BACK-07 and BACK-19 stay Pending. WINDOWS #3, #5, #6 and #11 record this and stay open.

## Decisions Made

- WINDOWS #8 and #10 were closed only after production reported the target SHA and the push range was empty, as the plan requires.
- #3, #5, #6, #11 and #12 stay open because real-Stripe proof is missing and wave 3c stays dropped.
- The two resolved entries in `deferred-items.md` say "mocked Stripe only" in their Resolution lines, so a resolved entry is not read as a verified one.
- `reconcileDirectChargeRefunded` is in `src/controllers/connectWebhooks.controller.js`, not in `stripeEvents.js` as one might guess; the new deferred entry names the file as found.

## Deviations from Plan

**1. [Process] Commits on `main`, which the protected-branch guard flags.**
- **Found during:** the pre-commit checks for Task 1 and again for Task 3.
- **Issue:** `gsd_run query git.base-branch --is-protected main` returns `true` and `git.allow_default_branch_commits` is not set. The executor commit guard would refuse a commit on `main`.
- **Handling:** `branching_strategy` is `none`, the dispatch ran this agent sequentially on the main working tree and told it to commit, and plans 01-01 to 01-25 committed planning docs on `main` the same way. Only this plan's planning files are committed. Nothing is pushed. The config was not changed. If the user wants that guard to hold for planning docs, the switch is `git.allow_default_branch_commits` in `.planning/config.json`, which is the user's call, not an agent's.

**2. [Process] Gate command used `REDIS_URL` as written.** No deviation from the plan. Recorded because 01-19 had to skip `redis.test.js` for lack of a local Redis; this time Redis was running.

**3. [Process] `status: halted` draft became `status: complete` here.** The draft committed in `e59c7d4` was a designed stop at the Task 2 checkpoint. This file replaces it after Task 3.

No other deviations. No code changed in either repo.

## Issues Encountered

None.

## Threat Coverage

- **T-01-59** (money-wave deploy): isolated push range, exact runtime file list, no migration, green gate, the user-only push and the `/health` SHA check are all done.
- **T-01-60** (first sweep on rows flagged before the deploy): the first-sweep table was written and checked against the code. The user reported no flagged rows. The query result is the user's report, and its timing relative to the push is not known.
- **T-01-61** (parked branch shipping by accident): subject, ancestor and symbol checks passed before the handoff.
- **T-01-SC:** no packages were installed or upgraded.

No new security surface: this plan changes no code.

## Known Stubs

None. No code was created or modified.

## User Setup Required

None remaining. The plan's `user_setup` (the user's push to `origin/main` and a read-only Supabase query) was carried out in Task 2 and is written out in the Task 2 section of the plan, so `01-USER-SETUP.md` is not generated.

## Next Phase Readiness

- Plan 26 of 26 in Phase 1 is complete. The refund retry gap in `01-VERIFICATION.md` can be re-verified from code. BACK-19 stays Pending until the 01-19 checklist is run on real Stripe.
- Still open for the user, at the latest during Phase 4 payment UAT: the 01-17 checklist (BACK-06, BACK-07), the 01-19 checklist (BACK-19), and the optional no-money check on build 6 and Android (step C), which nobody has reported.
- Four new open deferred entries need a decision before they are planned: the `accountCascade.cancelActiveBookingsForUser` gap, a refund that fails later at the bank, replayed Stripe errors on the sweep's idempotency key, and the missing push on direct-charge refunds.
- WINDOWS has 5 open items: #3, #5, #6, #11 (real-Stripe proof) and #12 (wave 3c dropped). `/gsd-ship` blocks while `open_count > 0` with `workflow.windows_enforce` on.

## Self-Check: PASSED

- This file exists and contains `BACK-19`.
- `.planning/WINDOWS.md` shows `open_count: 5`; #8 and #10 `fixed`; #6 and #11 `open`.
- `deferred-items.md` has the two entries `status: resolved` with Resolution lines naming `d86bf97`, and the four new `status: open` entries.
- Commits exist: `e59c7d4` and `7e1bd65` are ancestors of iOS `HEAD`.
- Production `/health` reports `d86bf97`; `git rev-list --count origin/main..master` in the backend is `0`.
- `requirements-completed` is `[]`; REQUIREMENTS.md was not touched.
- Nothing was pushed by the agent in either repo. `.DS_Store` files, `.planning/config.json`, `.planning/milestone.lock` and `.planning/state.json` were left out of every commit.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-09*
