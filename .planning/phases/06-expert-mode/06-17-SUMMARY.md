---
phase: 06-expert-mode
plan: 17
subsystem: api
tags: [backend, topics, currency, gap-closure, decision]

requires:
  - phase: 06-expert-mode
    provides: "06-11 iOS normalization of a blank or malformed stored topic currency (closes G-06-1-currency on iOS)"
provides:
  - "User decision on the optional backend null currency: skip (2026-11-17)"
  - "Backend follow-up todo recording the value change and the client tolerance gate to rerun first"
affects: [backend topics serializer, phase 8 release pass]

actuals:
  tokens: 2500
  tasks: 3
  commits: 1
plan_head_before: 88853a64d485455cb9e4a66c6571a0da8bb33d59
plan_head_after: b5d381a04c466371505f216ea03cde6f727290e8

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/todos/pending/2026-11-16-backend-null-topic-currency.md
  modified: []

key-decisions:
  - "06-17: user chose skip (2026-11-17) for the optional backend null topic currency; no backend command, worktree or branch; the iOS fix in 06-11 closes G-06-1-currency either way"

requirements-completed: [EXP-17]

coverage:
  - id: D1
    description: "User decision on the optional backend hardening for G-06-1-currency recorded (skip), with no backend change"
    requirement: EXP-17
    verification:
      - kind: other
        ref: "Task 2 skip check: /tmp/06-17-decision.txt is skip, no 'ClickMe2026 Backend P6' path, no branch ios-p6-topic-currency-null"
        status: pass
    human_judgment: false
  - id: D2
    description: "Backend follow-up todo names the change as a value change and the client tolerance gate to rerun if revived"
    requirement: EXP-17
    verification:
      - kind: other
        ref: "Task 3 grep check on .planning/todos/pending/2026-11-16-backend-null-topic-currency.md"
        status: pass
    human_judgment: false

duration: 3 min
completed: 2026-11-17
status: complete
---

# Phase 6 Plan 17: Optional backend null topic currency Summary

**The user skipped the optional backend change that would send price.currency null instead of "" for a topic stored with no currency; the backend is untouched and a follow-up todo records the value change and the client tolerance gate to rerun if it is revived.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-11-17T05:43:00Z
- **Completed:** 2026-11-17T05:46:00Z
- **Tasks:** 3 (Task 1 decision answered by the user, Task 2 skip path, Task 3 todo)
- **Files modified:** 1 (one new todo in this repo)

## Accomplishments

- Task 1 (checkpoint:decision, gate blocking-human): the user answered `skip` on 2026-11-17 via the orchestrator. `skip` was written to `/tmp/06-17-decision.txt`.
- Task 2 on the skip path: no backend command, no client tolerance gate run, no worktree, no branch. Verified: `/tmp/06-17-decision.txt` is `skip`, `/Users/LeonChen/Documents/ClickMe2026 Backend P6` does not exist, branch `ios-p6-topic-currency-null` does not exist in the backend repo. Skipped by user decision.
- Task 3: backend todo created. It states the contract mismatch (`serializeTopic` sends `""`, OpenAPI and the public endpoints say a code or null), that the change is a value change and not additive, that safety for App Store build 6 (`a48c664`) and Android rests on the client tolerance gate, the exact change if revived, and the two undecided related questions (production backfill of NULL rows, requiring a currency on a free create).

Backend scope origin: this plan exists because of the UAT gap G-06-1-currency (`06-UAT.md` `## Gaps`, its "Optional backend hardening" item) and the orchestrator's note, not `06-CONTEXT.md`, whose scope line puts any backend change out of Phase 6. It was the one user-decided exception, and the user declined it.

## Task Commits

1. **Task 1: Decide whether to build the backend null currency now** - no commit (decision `skip`, recorded in `/tmp/06-17-decision.txt` and here)
2. **Task 2: Build path (not taken)** - no commit (skipped by user decision; no backend change)
3. **Task 3: Record the backend follow-up** - `b5d381a` (docs)

**Plan metadata:** committed after this file (docs: complete plan)

## Files Created/Modified

- `.planning/todos/pending/2026-11-16-backend-null-topic-currency.md` - backend follow-up for the blank topic currency, with the skip decision and the revive steps

## Decisions Made

- The user chose skip. The iOS normalization (06-11) and Android's existing guard cover every existing row and any future blank, so no user sees a difference. The wire keeps sending `""` against the OpenAPI contract until revived.

## Deviations from Plan

None - plan executed exactly as written (skip branch).

## Issues Encountered

None. The iOS and Android client tolerance gate was not run, because the plan runs it only on build-branch.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 18 plans of Phase 6 now have a SUMMARY. Remaining before Phase 6 can close: the device re-check R1 to R8 results in `06-DEVICE-UAT-CHECKLIST.md`, then `/gsd-verify-work 06`.
- No backend deploy is pending from this plan.

## Self-Check: PASSED

- `.planning/todos/pending/2026-11-16-backend-null-topic-currency.md` exists; commit `b5d381a` is on `main` and lists only that file.
- Task 2 skip check and Task 3 check both passed (no P6 worktree, no branch, todo sections and required terms present, `docs(06-17)` commit).

---
*Phase: 06-expert-mode*
*Completed: 2026-11-17*
