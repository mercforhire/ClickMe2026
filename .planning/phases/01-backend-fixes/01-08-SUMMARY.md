---
phase: 01-backend-fixes
plan: 08
subsystem: api
tags: [express, express-rate-limit, supabase, jest, supertest, openapi]

requires:
  - phase: 01-backend-fixes
    provides: "tests/support/authMock.js (setAuthUser/resetAuthUser) and the D-12 contract lock that includes GET /chats items (plan 01-01)"
provides:
  - "GET /chats lists threads with no messages (last_message null, last_msg_at null), ordered last_msg_at desc nulls last, then created_at desc (BACK-16)"
  - "feedbackLimiter: 5 POST /feedback/submit per 15 minutes per user, 429 TOO_MANY_REQUESTS, mounted before validate (BACK-16)"
affects: [01-09 through 01-23, ios chat list (ChatThreadItem.lastMsgAt is already optional), android chat list (null lastMsgAt sorts last)]

actuals:
  tokens: 4400
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "nullsFirst:false on a DESC order() because Postgres sorts NULLs first on DESC"
    - "Per-user limiter copied from withdrawLimiter, mounted before validate so 422s spend budget"
    - "Tests reset limiter state with feedbackLimiter.resetKey(userId) in beforeEach (clearAllMocks does not touch the store)"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/chats.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/chats.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/middleware/rateLimiter.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/feedback.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/feedback.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/connect.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/payouts.test.js"

key-decisions:
  - "Open Q2 default adopted as planned: an empty thread from POST /chats/initiate is visible to both participants; no per-party visibility column"
  - "feedbackLimiter uses the in-memory store; correct only while railway.json numReplicas is 1 (it is 1 today), noted in the limiter comment"
  - "Notification mark-read stays out of BACK-16 (D-15)"

requirements-completed: [BACK-16]

coverage:
  - id: D1
    description: "GET /chats returns a thread with no messages, with last_message and last_msg_at null"
    requirement: BACK-16
    verification:
      - kind: integration
        ref: "tests/chats.test.js#GET /chats: lists empty threads (last_msg_at null) with null last_message and last_msg_at (BACK-16)"
        status: pass
    human_judgment: false
  - id: D2
    description: "GET /chats orders by last_msg_at desc nulls last then created_at desc, and a repeat request returns the same list without writing"
    requirement: BACK-16
    verification:
      - kind: integration
        ref: "tests/chats.test.js#GET /chats: orders by last_msg_at desc nulls last, then created_at desc (BACK-16)"
        status: pass
      - kind: integration
        ref: "tests/chats.test.js#GET /chats: is read-only; a repeat request returns the same list and never writes (BACK-16)"
        status: pass
      - kind: integration
        ref: "tests/contract.responseShapes.test.js (GET /chats key-set lock still passes)"
        status: pass
    human_judgment: false
  - id: D3
    description: "POST /feedback/submit allows 5 per 15 minutes per user, the 6th returns 429 TOO_MANY_REQUESTS with the specified message"
    requirement: BACK-16
    verification:
      - kind: integration
        ref: "tests/feedback.test.js#processes the 1st to 5th submission and returns 429 TOO_MANY_REQUESTS on the 6th"
        status: pass
    human_judgment: false
  - id: D4
    description: "Users have independent feedback budgets, and requests rejected by validation still consume budget"
    requirement: BACK-16
    verification:
      - kind: integration
        ref: "tests/feedback.test.js#gives two different users independent budgets"
        status: pass
      - kind: integration
        ref: "tests/feedback.test.js#counts requests rejected by validation against the budget (limiter runs before validate)"
        status: pass
    human_judgment: false
  - id: D5
    description: "In-memory limiter counters are only correct on a single replica"
    requirement: BACK-16
    verification:
      - kind: other
        ref: "railway.json numReplicas is 1 (checked); no automated guard if it is raised later"
        status: pass
    human_judgment: true
    rationale: "Backstop truth: nothing fails if someone later raises numReplicas; the limiter comment records the dependency."

# plan_head_before / plan_head_after refer to the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: a7ccabc4a4fa606b9f945cea609208bbedf24448
plan_head_after: a7ccabc4a4fa606b9f945cea609208bbedf24448
backend_head_before: c80981d725c38b00aa5455048c0c509f300ff98d
backend_head_after: 9fe6178149e81230c4daa9aa03e5b7ba9e8ec91a
commits: 2

duration: ~15min (approximate, from STATE.md timestamp)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 08: BACK-16 empty chat threads and feedback rate limit Summary

**GET /chats now lists conversations that have no messages yet (null preview and timestamp, sorted below active ones), and POST /feedback/submit allows 5 submissions per 15 minutes per user before returning 429 TOO_MANY_REQUESTS.**

## Performance

- **Duration:** ~15 min (approximate)
- **Completed:** 2026-11-08
- **Tasks:** 2 of 2
- **Files:** 8 backend (6 planned, 2 test mocks added), 0 iOS source

## Accomplishments

- **Empty threads (Task 1):** removed `.not('last_msg_at','is',null)` from the `list` query and ordered with `last_msg_at desc nullsFirst:false`, then `created_at desc`. Without `nullsFirst:false` Postgres would put the empty threads at the top. The response mapping already returned `last_message: null` and `last_msg_at: null`. OpenAPI GET /chats describes the new behavior; the `last_msg_at` schema property was already nullable.
- **Feedback limiter (Task 2):** `feedbackLimiter` in `rateLimiter.js` copies the `withdrawLimiter` shape (15 min, limit 5, draft-7 headers, key `req.user.id`). It is mounted as `router.post('/feedback/submit', feedbackLimiter, validate(...), submitFeedback)`. OpenAPI documents the 429 and notes that validation failures count.
- **TDD:** both tasks went RED first (Task 1: 2 of 3 new cases failed; Task 2: all 7 failed because the limiter did not exist), then GREEN.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `3b9b947` | fix(ios-p1/BACK-16): list empty chat threads after active ones |
| backend (master) | `9fe6178` | fix(ios-p1/BACK-16): rate-limit feedback submissions per user |

Backend `git status -sb` shows `master...origin/main [ahead 18]`. Nothing was pushed or deployed.

## Verification

- Task 1: `tests/chats.test.js` + `tests/contract.responseShapes.test.js` 68/68. `grep -c "nullsFirst: false"` on the controller is 1 (baseline 0).
- Task 2: `tests/feedback.test.js` 7/7. `grep -c "feedbackLimiter, validate"` on the route is 1 (baseline 0).
- Full gate (`npm test -- --testPathIgnorePatterns=tests/services/redis.test.js`): 125/125 suites, 2772 tests, 0 failed. `check-openapi-coverage` and `check-doc-coverage` print `OK: all 128 endpoints`.
- The first full run (before the mock fix below) showed 2 failed suites, both caused by this change, not the known flake.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Two test files mock the whole rateLimiter module without feedbackLimiter**
- **Found during:** Task 2 full gate
- **Issue:** `tests/connect.test.js` and `tests/payouts.test.js` replace `../src/middleware/rateLimiter` with a hand-written list of pass-through limiters. Once `routes/feedback.js` destructures `feedbackLimiter`, it is `undefined` there, Express throws on `router.post`, and both suites fail to load (123/125 suites passed).
- **Fix:** added `feedbackLimiter: (req, res, next) => next()` to both mocks, the same way `reportLimiter` and `setupIntentLimiter` were added earlier.
- **Files modified:** `tests/connect.test.js`, `tests/payouts.test.js` (not in the plan's files_modified; committed with Task 2 in `9fe6178`)
- **Verification:** both suites pass alone (35/35 with feedback), full gate 125/125.

**Total deviations:** 1 auto-fixed (1 blocking). **Impact:** test-only, no behavior change. Later plans that add a limiter to a router file loaded by those suites must extend those mocks the same way.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-13 is mitigated (5 per 15 min per user id, before validation, 429). T-01-14 accepted as planned: the `.or(client_id.eq/expert_id.eq)` participant guard is unchanged, so only participants see an empty thread. T-01-SC: no packages installed or upgraded.

## Notes for later plans

- Clients: iOS `ChatThreadItem.lastMsgAt` is optional and Android sorts a null `lastMsgAt` last, so no client change is required for build 6 or current Android. The iOS chat list UI should be checked in Phase 7 for how a row with a null preview renders (empty-state text).
- The limiter store is per process. If `railway.json` `numReplicas` is ever raised above 1, move `feedbackLimiter` to a Redis store first.
- The 429 body shape (`status`, `code`, `message`) matches the other limiters; iOS should branch on `TOO_MANY_REQUESTS`, not the message.
- Pre-existing untracked files in the backend repo were left untouched.

## Next

Ready for plan 01-09.

## Self-Check: PASSED

- FOUND backend commits `3b9b947`, `9fe6178` (ancestors of backend HEAD)
- FOUND modified files: `src/middleware/rateLimiter.js` exports `feedbackLimiter`; `src/routes/feedback.js` contains `feedbackLimiter, validate`; `src/controllers/chats.controller.js` contains `nullsFirst: false`
