---
phase: 08-release
plan: "21"
subsystem: release
tags: [backend, merge, d-17, master, no-deploy]
status: complete

requires:
  - phase: 08
    provides: "08-18 backend frozen at 1d18aac (origin/main, ios-p8-x2)"
provides:
  - "Backend master carries D-12, CR-02, D-29 and every Phase 8 iOS-line commit via merge commit e36da572b8f2559da5ef05c16942864cf4eb4dab"
  - "Todo 2026-11-11-merge-d12-into-backend-master closed with a Resolution"
affects: [08-22, 08-23]

actuals:
  tokens: 1000
  tasks: 2
  commits: 1

plan_head_before: 34d41bb87f0866c66566192d6fc6ffa97aa4a573
plan_head_after: 83a327824e1c30a0f945a8ab8d5c7a77ad5d332b
commits: 1

key-files:
  created: []
  modified:
    - ".planning/todos/completed/2026-11-11-merge-d12-into-backend-master.md"

key-decisions:
  - "Hand-resolve the six conflict hunks by keeping origin/main's additions (user decision 2026-11-22: 'resolve', 'resolve now')"
  - "master stays local: not pushed, not deployed; supabase db push only from master after this merge"

requirements-completed: []
---

# Phase 08 Plan 21: Merge origin/main into backend master Summary

Backend `master` now contains `origin/main` (1d18aac) by a no-ff merge commit with six hand-resolved hunks; the D-12, CR-02 and D-29 describes and the full suite (153 suites, 3852 tests) pass on it, and nothing was pushed or deployed.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: merge origin/main into master, describes pass | backend `e36da57` (merge) | six hand-resolved files, see below |
| 2 | Full suite, ancestry gates, close todo, push proof | iOS `83a3278` | completed todo |

The `commits:` count above is the iOS repo only (the todo commit; the SUMMARY and state commits follow it). The backend repo has one commit for this plan, the merge `e36da57`.

## Task 1: the plan's "clean merge" premise was wrong

The first run stopped at the Task 1 gate. Before the merge: `git rev-list --left-right --count origin/main...master` gave `7 17` (master 17 ahead, origin/main 7 ahead), merge base `32fa6ec`, `git diff --name-only master...origin/main -- .planning` empty. `git merge-tree --write-tree --name-only master origin/main` exited 1 with six conflicted files, one hunk each. The plan's research (merge-tree exit 0) predates the origin/main commits 162f1d7 (G-03-1-ITEM1C), 0767cf4 (D-30) and 412f1aa (G-06-1-currency). master's 94d659b and origin/main's 5da3976 are the same patch, but origin/main added lines next to it, so git saw two inserts at one spot.

The user authorized a hand resolution (verbatim, 2026-11-22: "resolve", then "resolve now"). In every hunk master's side of the conflict was empty (checked by script before removing markers), so the resolution keeps origin/main's added lines and the shared lines, and drops nothing master alone had:

1. `openapi/clickme-api.yaml`: kept origin/main's `reschedule_decline` boolean property (G-03-1-ITEM1C, D-31) on the event_data schema. The file is byte-identical to origin/main; parses with js-yaml.
2. `src/controllers/clientBooking.controller.js`: kept `notify_user_id: booking.expert_id` and `reschedule_decline: true` in the `declineReschedule` dispatch, ahead of the shared `reason_text` / `reason_by` lines.
3. `src/controllers/expertBooking.controller.js`: same, with `notify_user_id: booking.client_id`.
4. `tests/clientBooking.test.js`: kept the new "dispatch targets the proposer (expert_id)" test before the shared reason tests.
5. `tests/events.test.js`: kept the whole new describe "reschedule decline reaches the proposer (G-03-1-ITEM1C, D-31)" (132 lines) before the shared quick 261119-miw describe.
6. `tests/expertBooking.test.js`: kept the two new "targets the proposer (client_id)" tests before the shared reason tests.

Check after resolving: `git diff --check` clean, no conflict markers under openapi/src/tests, `node --check` on both controllers. Resolved files differ from master only by additions. The merge commit was amended once, before anything else referenced it, to add the attribution trailer (`7b88b6e` became `e36da57`).

The D-12 and CR-02 files (`webhooks.controller.js`, `longLeadChargeSweep.js`, their tests, `connectedPaymentMethodClone.js`) merged cleanly, with no hand edit.

## Task 2: verification on merged master

Local Redis was running, so `REDIS_URL=redis://localhost:6379` was set; redis.test.js therefore passed (no FAILs at all).

| Check | Result |
|-------|--------|
| `payment_method.detached (ios-p4 D-12)` | 6 passed |
| `platform card check (ios-p4 D-12)` | 11 passed |
| `transient platform-card error is retried on the next run (ios-p4 CR-02)` | 4 passed |
| `transient error before the PaymentIntent is retried (ios-p8 D-29)` | 17 passed |
| Combined `-t "ios-p4 D-12\|ios-p4 CR-02\|ios-p8 D-29"` on the two files | 38 passed, 0 failed |
| Full suite | 153 suites passed, 3852 tests passed, 0 failed |
| `check-openapi-coverage`, `check-docs` | OK (126 endpoints) |
| Lint | the backend has no lint script |
| Ancestors of master | `ae3ec1a`, `28da165`, `ios-p8-x1`, `ios-p8-x2`, `1d18aac`: all yes |

Push proof: `git ls-remote origin refs/heads/main` = `1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594`; `git ls-remote origin refs/heads/master` = `95b5d709dc5538bc1b1367bacc56179bb0e6cd9b` (unchanged, 95b5d70). No push, rebase, force or `supabase db push` was run. The user's own uncommitted/untracked backend `.planning` files were not staged or touched (`git status` still shows only ` M .planning/STATE.md` among tracked files).

Standing rule (also in the todo's Resolution): any future deploy of master needs D-12 and CR-02 as ancestors, a green suite, and no force-push or rebase; `supabase db push` runs only from master after this merge.

## Deviations from Plan

**1. [Rule 3 - Blocking issue] The plan's premise of a clean merge was false.** Found during Task 1. Six hunks conflicted; resolved by hand under the user's explicit decision (above). Per the instruction, the PLAN text ("no conflicts expected", "research ran it: exit 0", the todo Resolution wording "clean merge-tree") was not rewritten; this note is the correction. Commit: backend `e36da57`.

**2. [Environment] The plan's verify command pipes to `/tmp` and passes `-t` through npm.** Ran with logs in the scratchpad, and re-ran each describe separately by exact name to confirm each exists and passes.

## Known Stubs

None.

## Threat Flags

None. No new endpoints or trust boundaries; the merge only joins existing history.

## Self-Check: PASSED

- Merge `e36da57` is HEAD of backend master and has parents 22b8967 and 1d18aac.
- iOS commit `83a3278` exists; the completed todo exists and the pending one is gone.
