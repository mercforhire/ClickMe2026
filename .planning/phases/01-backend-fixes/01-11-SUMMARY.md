---
phase: 01-backend-fixes
plan: 11
subsystem: api
tags: [agora, join-window, can_join, express, jest, wave-2]

requires:
  - phase: 01-backend-fixes/01-10
    provides: "wave 1 live in production at a92acba, so wave 2 commits start from a clean origin/main"
provides:
  - "evaluateJoinWindow two-tier gate per party, with JOIN_LEAD_MS, JOIN_GRACE_MS, FIRST_JOIN_MIN_SPAN_MS and TOKEN_TTL_AFTER_END_SECONDS exported from src/services/agora.js"
  - "JOINABLE_BOOKING_STATUSES in src/utils/bookingStatusSets.js, shared by /join and the can_join flags"
  - "POST /bookings/:id/join status check with status-specific 403 SESSION_NOT_ACTIVE messages"
  - "can_join on the client detail and the expert feed and detail agrees with /join, including for a reconnecting party"
  - "POST /bookings/:id/end accepts an overtime end_reason completed on a completed booking until end+70min"
affects: [01-15 (wave 2 gate and push), Phase 2 CALL-01 and CALL-02, Android join button]

# Measured in the BACKEND repo, where all three code commits live:
# git -C "<backend>" rev-list --count a92acba..15d405c = 3. plan_head_before and plan_head_after
# are backend SHAs. The iOS repo holds planning docs only and had no commits at SUMMARY write
# (iOS HEAD 5437612).
actuals:
  tokens: 17997
  tasks: 3
  commits: 3
plan_head_before: a92acbae5d2b7d96ca51270e11c7c20fe99a080b
plan_head_after: 15d405c1a2181b6d976611ec60333f30aa18e9ce

tech-stack:
  added: []
  patterns:
    - "One window function for the gate and the display flags, fed the caller's own joined_at, so a flag cannot disagree with /join"
    - "A column selected for a computed flag only is never added to a response body; the tests assert the key is absent"

key-files:
  created:
    - ".planning/phases/01-backend-fixes/deferred-items.md"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/agora.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/call.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/utils/bookingStatusSets.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/clientBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expertBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/call.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/clientBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/CALL-END-SEMANTICS.md"

key-decisions:
  - "D-04 refusals reuse 403 SESSION_NOT_ACTIVE with a status-specific message, because both shipped clients decode that code and show the server message"
  - "evaluateJoinWindow fails closed on an unparseable time; the gate compares inside the window, so NaN bounds are refused rather than allowed"
  - "An overtime /end after the cron keeps the existing payload, so end_reason changes from auto_completed to completed; nothing in src reads end_reason, and OpenAPI documents it"

patterns-established:
  - "Join rule: evaluateJoinWindow({ start, end, now, alreadyJoined }) is the only place the window is computed"

requirements-completed: [BACK-09]

coverage:
  - id: D1
    description: "Two-tier join window per party: first join in [start-60min, max(end, start+60min)], reconnect until end+60min, both bounds inclusive"
    requirement: BACK-09
    verification:
      - kind: unit
        ref: "tests/call.test.js#evaluateJoinWindow (ios-p1 BACK-09, D-03)"
        status: pass
      - kind: integration
        ref: "tests/call.test.js#POST /api/v1/bookings/:id/join - two-tier window and status check (ios-p1 BACK-09)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A reconnect still works after the end+15 cron completes the booking, and the Agora token expires at end+70min"
    requirement: BACK-09
    verification:
      - kind: integration
        ref: "tests/call.test.js#reconnect after the cron completed the booking: completed, client_joined_at set, E+30 → 200 with a token"
        status: pass
      - kind: integration
        ref: "tests/call.test.js#mints a token that expires at end+70min"
        status: pass
    human_judgment: false
  - id: D3
    description: "/join refuses every non-joinable status with 403 SESSION_NOT_ACTIVE and a status-specific message, before minting a token or stamping joined_at"
    requirement: BACK-09
    verification:
      - kind: integration
        ref: "tests/call.test.js#inside the window → 403 SESSION_NOT_ACTIVE with its own message, no token, no stamp"
        status: pass
    human_judgment: false
  - id: D4
    description: "can_join on the client detail and the expert feed and detail uses the same status set and window as /join, reading only the caller's own joined_at, with no joined_at key in any response"
    requirement: BACK-09
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#can_join flag (display signal, same two-tier rule as the join gate)"
        status: pass
      - kind: integration
        ref: "tests/expertBooking.test.js#can_join flag (display signal, same two-tier rule as the join gate)"
        status: pass
      - kind: other
        ref: "tests/contract.responseShapes.test.js"
        status: pass
    human_judgment: false
  - id: D5
    description: "/end accepts an overtime end_reason completed on a completed booking until end+70min, writing end metadata only; the cron is unchanged"
    requirement: BACK-09
    verification:
      - kind: integration
        ref: "tests/call.test.js#POST /api/v1/bookings/:id/end - overtime end after auto-completion (ios-p1 BACK-09, D-05)"
        status: pass
      - kind: unit
        ref: "tests/expirePastSessions.test.js"
        status: pass
    human_judgment: false
  - id: D6
    description: "Build 6 and current Android keep working against the new join rules on real devices"
    verification: []
    human_judgment: true
    rationale: "Not deployed. The wave 2 smoke checklist runs on both builds at plan 01-15 (D-10, D-12), after the user pushes."

duration: 7 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 11: BACK-09 join gate Summary

**`/join` now applies a per-party two-tier window (first join from an hour before until `max(end, start+60)`, reconnect until `end+60`) and refuses non-joinable bookings with a clear `SESSION_NOT_ACTIVE` message; `can_join` follows the same rule, and `/end` accepts an overtime hang-up after the cron completed the booking.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-08T17:26:55Z
- **Completed:** 2026-11-08T17:33:55Z
- **Tasks:** 3 of 3
- **Files modified:** 10 in the backend repo, plus planning docs here

## Accomplishments

- A party who already joined can reconnect until `end+60`, including after the `end+15` cron marks the booking completed. This is the server half of the critical CALL-01 overtime fix.
- Each party's window is separate: the other party having joined does not open the reconnect horizon.
- Agora tokens now expire at `end+70` instead of `end+130`, and no token is minted for a cancelled, declined, expired, missed or pending booking.
- `can_join` agrees with `/join` for first joins and reconnects. Expert flags also gained the status check they never had.
- `/end` no longer returns 409 for an overtime call that ends after the cron. It writes end metadata only, with no status or payment change. The `end+15` cron is unchanged.
- OpenAPI and `docs/ios/CALL-END-SEMANTICS.md` document all of the above.

## Task Commits

All in the backend repo on local `master`. **Nothing was pushed or deployed (D-11).** `master` is 3 ahead of `origin/main`.

1. **Task 1: Two-tier join gate with status check (D-03, D-04)** - `0ed81f5` `fix(ios-p1/BACK-09): two-tier join window and booking status check (D-03/D-04)`
2. **Task 2: can_join display flags follow the same rule (D-06)** - `8cad41f` `fix(ios-p1/BACK-09): align can_join flags with the join gate (D-06)`
3. **Task 3: /end overtime acceptance and contract docs (D-05)** - `15d405c` `fix(ios-p1/BACK-09): accept overtime call end after auto-completion; document join rules (D-05)`

## Test Results

| Check | Result |
|-------|--------|
| Task 1: `tests/call.test.js tests/contract.responseShapes.test.js` | 2 suites, 82 tests passed |
| Task 2: `tests/clientBooking.test.js tests/expertBooking.test.js tests/contract.responseShapes.test.js` | 3 suites, 256 tests passed |
| Task 3: `tests/call.test.js tests/expirePastSessions.test.js` | 2 suites, 117 tests passed |
| Full gate: `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` | 126 suites, 2840 tests passed, no failures and no flakes in this run |
| `npm run check-openapi-coverage` | OK, all 128 endpoints present |
| `npm run check-doc-coverage` | OK, all 128 endpoints covered |
| `grep -rn "isWithinSessionWindow" src` | no matches |
| `grep -c "120 \* 60 \* 1000" src/services/agora.js` | 0 |
| `grep -c "5 \* 60 \* 1000"` on both booking controllers | 0 and 0 |
| `grep -c "client_joined_at"` client controller, `grep -c "expert_joined_at"` expert controller | 2 and 5 |
| `grep -c "end+60\|end + 60" docs/ios/CALL-END-SEMANTICS.md` | 1 |

`tests/services/redis.test.js` did not run (needs `REDIS_URL`). The full gate ran on the working tree that became `15d405c`.

### TDD evidence

Each task's tests were written and run before its implementation, with the single commit per task the plan specifies, so there are no separate `test(...)` commits. This plan is `type: execute`.

- **Task 1 RED:** 31 of 75 failed. `evaluateJoinWindow is not a function` for the unit cases; the HTTP cases failed on the assertion (for example a cancelled booking expected 403 and got 200).
- **Task 2 RED:** 11 of 249 failed on `can_join` values and select-column assertions. One of those (`pending_reschedule`) was a bad fixture rather than the rule; see Issues Encountered.
- **Task 3 RED:** rerun against the Task 2 controller after the mock fix below: 3 of 7 failed, the three overtime 200 cases. The 409 and `in_progress` cases passed, as expected for unchanged behavior.

## Decisions Made

- **Refusal code (D-04, Claude's discretion):** `403 SESSION_NOT_ACTIVE` with a status-specific message. Both clients already decode the code and show the server message.
- **Fail closed:** an unparseable `start_time` or `end_time` is refused by `evaluateJoinWindow`.
- **`end_reason` after the cron:** the overtime `/end` keeps the existing payload, so `auto_completed` becomes `completed`. Nothing in `src` reads the column. It is documented in OpenAPI. Anyone later using `end_reason` to count cron closures should know this.

## Deviations from Plan

### Beyond the plan's literal list, inside its files

**1. [Rule 1 - Bug] Corrected stale `/end` contract text in OpenAPI**
- **Found during:** Task 3
- **Issue:** The `/end` description said `completed` transitions the booking to completed and triggers the review flow, and `review_seam_triggered` was described as always true. Both have been wrong since quick 260816-1ye.
- **Fix:** Rewrote both to match the code. Same for the docblock on `end` in `call.controller.js` and the "until end_time" comment there.
- **Files modified:** `openapi/clickme-api.yaml`, `src/controllers/call.controller.js`
- **Committed in:** `15d405c`

**2. [Rule 2 - Missing Critical] Documented the expert detail `can_join`**
- **Found during:** Task 3
- **Issue:** The expert detail `can_join` schema had no description, so the plan's "can_join rule" would have covered only two of the three flags.
- **Fix:** Added the same description as the feed.
- **Committed in:** `15d405c`

### Process notes

- **Commits on default branches.** Backend commits are on `master` as D-11 and the dispatch direct. iOS planning commits are on `main`, where `git.base-branch --is-protected` treats the executor's Step 0 assertion as a halt. As in plans 01-01 to 01-10, `branching_strategy` is `none` and the dispatch names this branch. Config was not changed and HEAD had not drifted.
- **`commits:` is measured in the backend repo,** since the iOS repo holds no code for this plan. The frontmatter comment records this.

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical), both documentation. **Impact on plan:** contract docs now match the code. No scope creep in behavior.

## Issues Encountered

- **Test mock leak in Task 3.** My first helper queued chains with `mockReturnValueOnce`. `jest.clearAllMocks` does not drain that queue, so a test that never reached its update left a chain behind and broke later tests in the file. Switched to the `mockImplementation` counter the file's other helpers use. Test-only, fixed before commit.
- **`pending_reschedule` client fixture.** The first version had no `proposed_*` fields and the detail read did not return a body. Added them; the test now asserts 200 and `can_join` false.

## Deferred Items

Logged in `.planning/phases/01-backend-fixes/deferred-items.md`, not changed:

- `scripts/uat-demo-shoot-check.js` still mirrors the old 120-minute window, so it can say a booking is joinable when `/join` refuses it after wave 2 deploys.
- `/end` has no status or time limit for `dropped` and `manual_exit`. This predates the plan and affects reported metadata only.

## Pitfall 7 Check

`src/cron/noShowNotification.js` only selects bookings with `end_time > now`, so a late first join after the scheduled end cannot trigger no-show pushes. Confirmed by reading the cron header and query comment.

## Requirements Status

BACK-09 stays **Pending** in REQUIREMENTS.md. Plan 01-15 also declares it and has no SUMMARY yet, so the shared-ID gate holds it until wave 2 is deployed and smoke-tested.

## User Setup Required

None.

## Next Phase Readiness

Ready for plan 01-12. Wave 2 still needs its gate and user push at plan 01-15. iOS CALL-01 and CALL-02 (Phase 2) can rely on these rules once wave 2 is live; until then production still runs the old `[start-120, end+120]` window.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*

## Self-Check: PASSED

- FOUND: all 10 modified backend files and `deferred-items.md`
- FOUND: backend commits `0ed81f5`, `8cad41f`, `15d405c`, ancestors of `master` and not on `origin/main`
- `git -C "<backend>" rev-list --count a92acba..15d405c` = 3, matching `commits: 3`
- All task acceptance checks re-run and passing (see Test Results)
