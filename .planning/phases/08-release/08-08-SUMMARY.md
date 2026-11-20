---
phase: 08-release
plan: "08"
subsystem: backend-deploy
tags: [deploy, production, railway, backend, rel-02]

requires:
  - phase: 08
    provides: "Plans 08-02 and 08-05: the ios-p8-x1 commits (chat reasons, reschedule-decline recipient and wording, name messages, null topic currency)"
provides:
  - "Production backend main at 412f1aa (deploy wave X1), live per /health"
  - "Local backend branch ios-p8-x1-rollback at 28da165ebe66a973008560f689c469389279c25f (D-16 rollback point)"
affects: [08-11, 08-14, 08-16, 08-18]

actuals:
  tasks: 3
  commits: 0

# No repo file changes; the only code-side action is the backend push of an existing branch.
commits: 0

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "D-14: user approved this deploy only (answer verbatim: \"1. approve\", 2026-11-20)"
  - "Task 3 was run by the orchestrator, not the executor: the executor declined to push on an approval relayed by agent message, and the approval had been given directly to the orchestrator by the user"

requirements-completed: []

duration: ~1h (including user wait)
completed: 2026-11-20
---

# Phase 08 Plan 08: Deploy wave X1 Summary

**Production backend moved from 28da165 to 412f1aa (ios-p8-x1) as one approved fast-forward, live on /health at 2026-11-20T17:30:24Z, with a rollback branch at 28da165.**

## Task 1: Tracer (gates without pushing)

- H (/health before): `28da165`, equal to backend `origin/main`.
- Rollback branch: `ios-p8-x1-rollback` at `28da165ebe66a973008560f689c469389279c25f`.
- Ancestry: origin/main is an ancestor of ios-p8-x1 (fast-forward); D-12 `ae3ec1a` and CR-02 `28da165` are ancestors; master's `d33c222` is NOT an ancestor.
- No file under `supabase/migrations` changed (D-15). Worktree clean.
- Dry-run push: `28da165..412f1aa  412f1aa649f5aa72fb853e40e87ab5e0998eb926 -> main` (fast-forward).
- Edges: neither fired (4 commits to deploy; /health was not already 412f1aa).
- The chained `<automated>` verify was refused by the sandbox as one command; every gate in it was run as a separate command and passed.

### Full suite (D-13)

- Run 1: `Tests: 9 failed, 3855 passed, 3864 total`. FAIL: `tests/services/redis.test.js` (6, allowed; no Redis server) and `tests/chats.test.js` (3: an expert-sent message push got 401 instead of 201; `actions: block` and `actions: report` got 500 instead of 200).
- `tests/chats.test.js` alone: 66/66 passed.
- Run 2: `Tests: 6 failed, 3858 passed, 3864 total`. Only FAIL: `tests/services/redis.test.js` (allowed).
- The chats.test.js failures are treated as a flake under full-suite parallel load; the cause was not found. Logs: `$CLAUDE_JOB_DIR/tmp/08-08-full.log`, `08-08-chats.log`, `08-08-full2.log` (job-scoped, not durable).

### Commits deployed (`git log origin/main..ios-p8-x1`)

```
412f1aa fix(ios-p8): send null, not "", for a topic stored with no currency (G-06-1-currency)
0767cf4 fix(ios-p8): hand-written messages for empty profile names (D-30)
162f1d7 fix(ios-p8): reschedule declines notify the proposer and say so (G-03-1-ITEM1C, ITEM1)
5da3976 feat(quick-261119-miw): carry booking action reasons and notes into the chat event
```

Diff stat: 13 files changed, 830 insertions(+), 25 deletions(-). Files: `docs/ios/PUSH-ROUTING.md`, `docs/ios/USD-TOPIC-PRICING.md`, `openapi/clickme-api.yaml`, `src/controllers/clientBooking.controller.js`, `src/controllers/expertBooking.controller.js`, `src/controllers/expertTopics.controller.js`, `src/schemas/userProfile.schema.js`, `src/services/events.js`, and tests (`clientBooking`, `events`, `expertBooking`, `expertTopics`, `userProfile`).

## Task 2: Approval (D-14)

- User answer, verbatim: `1. approve`, on 2026-11-20 (before 17:29Z). Covers this deploy only.

## Task 3: Push and confirm

- Recheck just before the push: /health `28da165`, origin/main `28da165`, ios-p8-x1 `412f1aa649f5aa72fb853e40e87ab5e0998eb926`, tree clean, fast-forward OK.
- Push at 2026-11-20T17:29:02Z: `git push origin 412f1aa649f5aa72fb853e40e87ab5e0998eb926:refs/heads/main` → `28da165..412f1aa` (no --force).
- /health after: `{"status":"success","commit":"412f1aa"}`, live at 2026-11-20T17:30:24Z (8th poll, ~80 s).
- GitHub `main` = `412f1aa649f5aa72fb853e40e87ab5e0998eb926`. Verify passed.
- Rollback: redeploy `28da165ebe66a973008560f689c469389279c25f` (branch `ios-p8-x1-rollback`) in Railway (D-16). Claude does not roll back.

## Deviations from Plan

- Task 3 was run inline by the orchestrator instead of the executor (see key-decisions). Same commands and gates as the plan.
- The verify ran as split commands instead of one chained command (sandbox limit); same gates.

## Issues Encountered

- A flaky `tests/chats.test.js` run (3 failures, then a clean rerun). Not investigated further; worth a backend todo if it recurs.

## Next

- Plan 08-11: live smoke of deploy X1 on build 6 and Android.
