---
phase: 08-release
plan: "02"
subsystem: backend-push
tags: [push, events, reschedule, fcm, openapi, jest, cherry-pick]

requires:
  - phase: 03
    provides: G-03-1-ITEM1, ITEM1B and ITEM1C gaps found in 03-UAT.md
provides:
  - Backend branch ios-p8-x1 in the D12 worktree, two local commits ahead of origin/main (28da165), nothing pushed
  - A reschedule decline push that goes to the party who proposed the time, with sub_category 'reschedules' and title 'Reschedule Declined'
  - event_data.reschedule_decline (boolean) on the chat event of a reschedule decline
  - A proposal push that reads as a request ('Reschedule Requested'), not a done deal
affects: [08-08, 08-21, android-chat-reasons, release-candidate-backend]

actuals:
  tokens: 5143
  tasks: 3
  commits: 2

plan_head_before: 28da165ebe66a973008560f689c469389279c25f
plan_head_after: 162f1d7c8f7f16044c7044ecdd30fd604e767b06
commits: 2

tech-stack:
  added: []
  patterns:
    - "Dispatch marker plus server-chosen recipient: the controller passes notify_user_id (from the booking row) and reschedule_decline: true; events.js branches on a literal true"
    - "Additive wire change only: one new event_data key, push data keys unchanged"

key-files:
  created: []
  modified:
    - "../ClickMe2026 Backend D12/src/services/events.js"
    - "../ClickMe2026 Backend D12/src/controllers/clientBooking.controller.js"
    - "../ClickMe2026 Backend D12/src/controllers/expertBooking.controller.js"
    - "../ClickMe2026 Backend D12/tests/events.test.js"
    - "../ClickMe2026 Backend D12/tests/clientBooking.test.js"
    - "../ClickMe2026 Backend D12/tests/expertBooking.test.js"
    - "../ClickMe2026 Backend D12/openapi/clickme-api.yaml"
    - "../ClickMe2026 Backend D12/docs/ios/PUSH-ROUTING.md"

key-decisions:
  - "94d659b applied cleanly with cherry-pick -x, so the D-11 hand rebuild was not needed; 94d659b stays on backend master untouched for the 08-21 merge, and 22b8967 (docs) was not cherry-picked"
  - "reschedule_decline is honored only as a literal boolean true, and only on BOOKING_DECLINED chat events; the route schema is strict, so request input can never set the recipient or the marker"
  - "The proposal wording change (ITEM1) was applied during Task 1 instead of Task 2, because it lives in the same events.js file and Task 1's verify runs the whole events suite; its RED row was observed first"

patterns-established:
  - "A decline marked reschedule_decline with no notify_user_id warns and sends no push, rather than guessing a recipient"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "A client declining the expert's proposed time sends the push to the expert (booking.expert_id) with target_role expert, sub_category 'reschedules', title 'Reschedule Declined'; the client gets no push"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#client declines the expert proposal: the expert (proposer) gets one push, the client gets none"
        status: pass
      - kind: unit
        ref: "tests/clientBooking.test.js#decline-reschedule: the dispatch targets the proposer (expert_id) and is marked as a reschedule decline"
        status: pass
    human_judgment: false
  - id: D2
    description: "An expert declining the client's proposed time sends the push to the client with target_role client, sub_category 'reschedules', title 'Reschedule Declined'; the expert gets no push"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#expert declines the client proposal: the client (proposer) gets one push, the expert gets none"
        status: pass
      - kind: unit
        ref: "tests/expertBooking.test.js#decline-reschedule: the dispatch targets the proposer (client_id) and is marked as a reschedule decline"
        status: pass
    human_judgment: false
  - id: D3
    description: "No reason text in push data or in_app_meta for a reschedule decline (BACK-02); push data deep-equals { booking_id, event_type }; the chat event carries reschedule_decline true plus reason_text and reason_by"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#push data is exactly { booking_id, event_type }; no reason text and no in_app_meta anywhere (BACK-02)"
        status: pass
      - kind: unit
        ref: "tests/events.test.js#chat event carries reschedule_decline true plus reason_text and reason_by"
        status: pass
    human_judgment: false
  - id: D4
    description: "A request decline is unchanged (client, 'Booking Declined', 'declines', decline_reason_code in data, no reschedule_decline key); a marked decline without notify_user_id warns and sends no push"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#a request decline never carries the reschedule_decline key and keeps its wording and recipient"
        status: pass
      - kind: unit
        ref: "tests/events.test.js#reschedule_decline without notify_user_id: warns and sends no push"
        status: pass
    human_judgment: false
  - id: D5
    description: "The BOOKING_RESCHEDULED proposal push reads 'Reschedule Requested' / 'A new time has been proposed for a booking. Open it to respond.' with recipient and data unchanged"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#reads as a request to respond, not as a done deal; recipient and data are unchanged"
        status: pass
    human_judgment: false
  - id: D6
    description: "Full backend suite at the redis baseline, doc gates green, branch exactly two commits ahead of origin/main, no migration, nothing pushed"
    requirement: REL-02
    verification:
      - kind: other
        ref: "npm test (full): Tests 6 failed, 3850 passed; the only FAIL suite is tests/services/redis.test.js"
        status: pass
      - kind: other
        ref: "npm run check-docs and npm run check-openapi-coverage: both OK, 126 endpoints"
        status: pass
      - kind: other
        ref: "Task 3 second automated check: rev-list count 2, clean tree, 0 migration files changed, ls-remote origin main = 28da165"
        status: pass
    human_judgment: false
  - id: D7
    description: "On a device, a reschedule decline push opens the booking detail for the proposer (iOS PushRouter sends booking/reschedules to bookingDetail), and the proposal push wording reads correctly"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "The route is decided on the device from route_sub_category; D-31 says the regression run checks it. It needs the deployed backend (plan 08-08) and a real push, so no automated test in this plan covers it."

duration: 4min
completed: 2026-11-19
status: complete
---

# Phase 08 Plan 02: Reschedule decline and proposal push fixes Summary

**Reschedule declines now push the person who proposed the time (not the decliner) with sub_category 'reschedules' and an event_data.reschedule_decline marker, the proposal push says 'Reschedule Requested', and the chat-reasons commit 94d659b rides along on backend branch ios-p8-x1, two local commits on origin/main, nothing pushed.**

## Performance

- **Duration:** about 4 min by the system clock (start approximated from the cherry-pick commit time)
- **Started:** 2026-11-20T04:07:00Z (approximate)
- **Completed:** 2026-11-20T04:11:00Z
- **Tasks:** 3 (Task 1 tracer, Task 2 auto/tdd, Task 3 auto)
- **Files modified:** 8 backend files, in the D12 worktree (a separate git repo); this iOS repo gets only planning files

## Accomplishments

- `94d659b` (chat reasons) cherry-picked onto `ios-p8-x1` from `origin/main` (28da165) with `-x`. It applied cleanly, so the D-11 fallback rebuild was not used. `22b8967` was not cherry-picked. `94d659b` is still on backend master.
- A client declining the expert's proposal now pushes `booking.expert_id` (target_role `expert`); an expert declining the client's proposal pushes `booking.client_id` (target_role `client`). Both use `sub_category: 'reschedules'`, title `Reschedule Declined`, body `Your proposed new time was declined. The original time stands.`, the same booking deep link the request-decline push sends, and push data of exactly `{ booking_id, event_type }`. The decliner gets nothing.
- The chat event of a reschedule decline carries `event_data.reschedule_decline: true` (the only new wire key), even with no reason text. A request decline never carries it. A marked decline with no `notify_user_id` logs `[events] reschedule BOOKING_DECLINED: no notify_user_id; skipping push` and sends no push.
- The proposal push (`BOOKING_RESCHEDULED`) reads `Reschedule Requested` / `A new time has been proposed for a booking. Open it to respond.`; recipient, category and data are unchanged.
- OpenAPI documents `reschedule_decline` next to `reason_text` / `reason_by`; `docs/ios/PUSH-ROUTING.md` splits the BOOKING_DECLINED row into request decline and reschedule decline and gains a "Reschedule pushes" section.

## RED / GREEN evidence (Tasks 1 and 2)

- **RED (Task 1):** against the cherry-picked code, `tests/events.test.js` and `tests/clientBooking.test.js` ran 262 tests, 7 failed, all on the planned assertions: the push went to `a0000000-...0001` (the client) instead of `e0000000-...0003` (the expert); the chat event had no `reschedule_decline`; a marked decline with no `notify_user_id` still sent a push; the proposal title was `Booking Rescheduled`; the client dispatch had `notify_user_id` undefined. The regression rows (request decline unchanged, no reason text in push data, literal-true only, deep link) passed on the old code by design.
- **GREEN (Task 1):** same two suites, 262 passed, 0 failed.
- **RED (Task 2):** `tests/expertBooking.test.js`, 2 failed of 162 (`payload.notify_user_id` undefined where the client id was expected).
- **GREEN (Task 2):** `events`, `expertBooking` and `clientBooking`, 424 passed.
- **Full suite:** 153 suites, 3856 tests: 3850 passed, 6 failed, all six in `tests/services/redis.test.js` (no Redis server). Baseline after the cherry-pick was 3837 passed / 6 failed; the 13 extra passes are this plan's new rows (10 events, 1 client, 2 expert).

## Task Commits

All in `/Users/LeonChen/Documents/ClickMe2026 Backend D12`, branch `ios-p8-x1`:

1. **Task 1 (tracer): cherry-pick of the chat reasons** - `5da3976` (feat, `cherry picked from commit 94d659b`)
2. **Tasks 1 to 3 change commit (single commit by plan design)** - `162f1d7` (fix): `fix(ios-p8): reschedule declines notify the proposer and say so (G-03-1-ITEM1C, ITEM1)`; exactly the eight files listed above

**Plan metadata:** committed in the iOS repo after this file (docs: complete plan).

## Files Created/Modified

- `src/services/events.js` - reschedule-decline branch in `dispatchPushForEvent`, marker in `injectEventMessage`, proposal wording
- `src/controllers/clientBooking.controller.js`, `src/controllers/expertBooking.controller.js` - `declineReschedule` passes `notify_user_id` (the proposer) and `reschedule_decline: true`
- `tests/events.test.js`, `tests/clientBooking.test.js`, `tests/expertBooking.test.js` - the new rows
- `openapi/clickme-api.yaml`, `docs/ios/PUSH-ROUTING.md` - the contract

## Decisions Made

- The D-11 fallback was not needed: the cherry-pick applied with no conflict.
- `reschedule_decline` counts only as a literal boolean `true`, and the chat-event marker is added only for `BOOKING_DECLINED`. The decline route schema is strict (`additionalProperties: false`), so a client cannot send its own recipient or marker (T-08-04); a test with extra body keys returned 422 and was dropped because its unconsumed mocks leaked into later suites.
- The `EVENT_PREVIEW_TEXT` chat-list preview and chat row titles were left alone, as the plan allows.

## Deviations from Plan

### Auto-fixed Issues

None under Rules 1 to 3. Three process deviations to record:

**1. [Process] RED was observed but not committed separately**
- **Found during:** Tasks 1 and 2 (TDD)
- **Issue:** The orchestrator prompt asked for a failing-test commit first, but the plan's own acceptance criteria and verify require the branch to be exactly two commits ahead of `origin/main` (the cherry-pick plus one change commit), and Task 1 says "do not commit this task's edits yet".
- **Fix:** Followed the plan. Tests were written first and run RED (evidence above), then GREEN, then committed together in `162f1d7`. `tdd_mode` is not enabled in `.planning/config.json`, and the plan's frontmatter type is `execute`, so no TDD gate applies.
- **Impact:** No separate `test(08-02)` commit exists in git history. The RED runs are recorded only in this file.

**2. [Process] Proposal wording applied in Task 1, not Task 2**
- **Issue:** Task 1's verify runs all of `tests/events.test.js`, which already held the proposal-wording row (it went RED first).
- **Fix:** Changed the title and body in `events.js` during Task 1. Task 2 then only had the expert controller to change.

**3. [Process] Co-Authored-By trailer names Claude Sonnet 5.5, not Opus 5.5**
- **Issue:** The plan text says `Claude Opus 5.5`; the session's attribution instruction names `Claude Sonnet 5.5`, the model that actually did the work.
- **Fix:** Used the session's line on `162f1d7`. The cherry-picked `5da3976` keeps the original trailer of `94d659b`.

---

**Total deviations:** 0 auto-fixed, 3 process notes
**Impact on plan:** None on behavior or scope; all acceptance criteria and both automated checks pass.

## Issues Encountered

- A first draft of one client test sent extra body keys to prove the recipient cannot come from input. The strict route schema answered 422, the test's queued `mockReturnValueOnce` chains were never consumed, and 17 unrelated Phase 27.1 and 261028-uph rows then failed with 500. Removing that test restored the suite; the pollution was mine, not pre-existing.
- This shell is bash 3.2, so the plan's compound `<automated>` one-liners were run as separate simple commands with the same checks and results.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. The recipient is read from the booking row server-side (T-08-04), no reason text reaches push data or in_app_meta (T-08-05), the wire change is one additive event_data key and there is no migration (T-08-06).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Branch `ios-p8-x1` (D12 worktree) holds `5da3976` and `162f1d7`, local only. Plan 08-08 owns the deploy and needs a per-deploy user approval (D-14). Production `/health` is still 28da165 and `origin/main` was not touched.
- Backend master still holds `94d659b`; plan 08-21 merges `origin/main` into master, and this branch's reschedule-decline commit will need to reach master by that merge or a cherry-pick.
- Android follow-up (not built here): render `reason_text` / `reason_by` and the `reschedule_decline` marker in `ChatMessageMapping.kt`, and route a `reschedules` push to the booking. The iOS chat client does not yet read `reschedule_decline`; no iOS change was in scope.
- Device check (D-31, coverage item D7): after the deploy, decline a reschedule on a real iPhone and confirm the proposer's push opens the booking detail.

## Self-Check: PASSED

- Commits exist on the branch: `5da3976`, `162f1d7` (`git rev-list --count origin/main..ios-p8-x1` = 2).
- `origin/main` on the remote is still `28da165`; no migration file changed; the D12 worktree is clean.

---
*Phase: 08-release*
*Completed: 2026-11-19*
