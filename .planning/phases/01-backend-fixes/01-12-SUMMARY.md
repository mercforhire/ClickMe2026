---
phase: 01-backend-fixes
plan: 12
subsystem: api
tags: [cancel, cancellation_reason, zod, express, jest, openapi, wave-2]

requires:
  - phase: 01-backend-fixes
    provides: "01-10 applied bookings.cancellation_reason to production; 01-11 is the prior wave 2 plan on master"
provides:
  - "POST /client/bookings/:id/cancel and POST /expert/bookings/:id/cancel store the trimmed reason in cancellation_reason, in the atomic cancel UPDATE"
  - "GET /expert/bookings/:id/summary returns the stored reason for cancelled bookings"
  - "GET /client/bookings/:id always has cancellation_reason, non-null only for cancelled bookings"
  - "Client cancel at or after end_time returns 409 SESSION_ALREADY_ENDED with no side effects"
affects: [01-15 (wave 2 gate and push), Phase 3 BOOK-07 and BOOK-13, Android cancel error mapping]

# Measured in the BACKEND repo, where both code commits live:
# git -C "<backend>" rev-list --count 15d405c..87d3c62 = 2. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (29447 bytes). The iOS repo holds planning
# docs only and had no commits at SUMMARY write (iOS HEAD 8f20a04).
actuals:
  tokens: 7362
  tasks: 2
  commits: 2
plan_head_before: 15d405c1a2181b6d976611ec60333f30aa18e9ce
plan_head_after: 87d3c622f4552f1eb4f1f1bb284d8f8702c82250

tech-stack:
  added: []
  patterns:
    - "Tests assert the select column list directly, because mocks return fixture fields whether or not the query selected them"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/schemas/booking.schema.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/clientBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expertBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/clientBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "BACK-12 uses 409 SESSION_ALREADY_ENDED, runs after the status guard and applies to every cancellable status, so pending_approval and pending_reschedule are refused after end_time too"
  - "BACK-14 keeps the free-text reason out of the dispatch payload, the response and the cancel_reason enum; only the client detail and expert summary reads return it"

patterns-established: []

requirements-completed: [BACK-14, BACK-12]

coverage:
  - id: D1
    description: "A cancel reason is trimmed and stored in the atomic cancel UPDATE for both parties; a missing or blank reason stores NULL"
    requirement: BACK-14
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#BACK-14 cancel reason"
        status: pass
      - kind: integration
        ref: "tests/expertBooking.test.js#POST /api/v1/expert/bookings/:id/cancel (EBOOK-08) BACK-14 cancel reason"
        status: pass
    human_judgment: false
  - id: D2
    description: "The expert summary and client detail return the stored reason, and the client detail returns null for any status but cancelled"
    requirement: BACK-14
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#BACK-14 cancellation reason (cancelled bookings only)"
        status: pass
      - kind: integration
        ref: "tests/expertBooking.test.js#GET /api/v1/expert/bookings/:id/summary (EBOOK-04) BACK-14 cancellation_reason"
        status: pass
    human_judgment: false
  - id: D3
    description: "The reason never reaches the BOOKING_CANCELLED dispatch payload, which is the source of push data and chat event_data"
    requirement: BACK-14
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#keeps the reason out of the BOOKING_CANCELLED dispatch and the response"
        status: pass
      - kind: integration
        ref: "tests/expertBooking.test.js#keeps the reason out of the BOOKING_CANCELLED dispatch and the response"
        status: pass
    human_judgment: false
  - id: D4
    description: "A client cancel at or after end_time returns 409 SESSION_ALREADY_ENDED with no UPDATE, Stripe, Redis, payment state or dispatch call; one minute before end proceeds; a completed booking still gets INVALID_STATUS"
    requirement: BACK-12
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#BACK-12 cancel after the session end"
        status: pass
    human_judgment: false
  - id: D5
    description: "Expert cancel has no time guard"
    requirement: BACK-12
    verification:
      - kind: other
        ref: "grep -c SESSION_ALREADY_ENDED src/controllers/expertBooking.controller.js prints 0"
        status: pass
    human_judgment: false
  - id: D6
    description: "The OpenAPI contract has the new code, the 409 response, the reason request body and the cancellation_reason field"
    requirement: BACK-12
    verification:
      - kind: other
        ref: "grep -c SESSION_ALREADY_ENDED openapi/clickme-api.yaml prints 4; npm run check-openapi-coverage reports 128 of 128; the YAML parsed with the new enum entry, both request bodies and the detail field present"
        status: pass
    human_judgment: false
  - id: D7
    description: "Real cancels on the deployed backend store the reason and show it to the other party"
    verification: []
    human_judgment: true
    rationale: "Tests mock Supabase, so the real write to the production column is only proven after the wave 2 push. Not deployed here (D-11)."

duration: 4 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 12: Cancel Reason Storage and Cancel-After-End Guard Summary

**Cancel reasons are saved with the booking and returned only to its client and expert, and a client cancel at or after the session's end now gets 409 SESSION_ALREADY_ENDED with no refund, void or slot release.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-11-08T17:37:38Z
- **Completed:** 2026-11-08T17:41:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- `cancelSchema` trims the reason, applies the 500-character limit after trimming and treats a blank reason as absent.
- Client and expert cancel both write `cancellation_reason` in the same atomic UPDATE that sets `status: 'cancelled'`.
- The expert summary returns the stored reason in place of the null placeholder. The client detail always has the key, and it is non-null only for cancelled bookings.
- A client cancel at or after `end_time` is refused before any write, Stripe call, Redis release, payment state change or dispatch.
- The OpenAPI file documents the new code, the 409 response, the `reason` body on both cancel operations and the new field. The body was not documented on either operation before.

## Task Commits

Both commits are in the backend repo, on local `master`, unpushed:

1. **Task 1: BACK-14 store and return the cancel reason** - `deda040` (fix)
2. **Task 2: BACK-12 reject client cancel after the session has ended, and document both changes** - `87d3c62` (fix)

## Verification

| Check | Result |
|-------|--------|
| Task 1 verify: `clientBooking`, `expertBooking`, `contract.responseShapes` | 3 suites, 277 tests, all passed |
| Task 2 verify: `clientBooking` | 1 suite, 141 tests, all passed |
| Full gate, excluding `tests/services/redis.test.js` | 126 suites, 2868 tests, all passed, exit 0. No parallel flakes in this run. |
| `grep -c "populated by cancel endpoint"` on the expert controller | 0 (baseline 1) |
| `grep -c "SESSION_ALREADY_ENDED"` on `openapi/clickme-api.yaml` | 4 (needs at least 2, baseline 0) |
| `npm run check-openapi-coverage`, `npm run check-docs` | 128 of 128 endpoints on both |
| Backend `git status -sb` | `master...origin/main [ahead 5]`, nothing pushed |

**RED before GREEN:** the new tests were run against the unchanged code first. BACK-14 had 17 failures and BACK-12 had 5, on the planned assertions (for example `Expected: 409, Received: 200`). The tests that passed at RED assert absences or behavior that already held. One BACK-14 RED failure, "applies the 500 character limit after trimming", also left unused mock chains that leaked into the next test. That cleared at GREEN.

## Files Created/Modified

All paths are in `/Users/LeonChen/Documents/ClickMe2026 Backend/`:

- `src/schemas/booking.schema.js` - `cancelSchema` trim, limit and blank handling
- `src/controllers/clientBooking.controller.js` - reason write, detail field, `end_time` select and time guard
- `src/controllers/expertBooking.controller.js` - reason write and summary field
- `tests/clientBooking.test.js` - BACK-14 and BACK-12 cases
- `tests/expertBooking.test.js` - BACK-14 cases
- `openapi/clickme-api.yaml` - contract updates

## Decisions Made

- The time guard applies to all three cancellable statuses, as RESEARCH specifies ("Applies regardless of status"). See the first item under Issues Encountered for what that means for `pending_approval`.
- The plan's commit instructions (one `fix(ios-p1/...)` commit per task with a fixed file list) take precedence over the `test` then `feat` split in `tdd.md`, so RED was run but not committed separately. This plan is `type: execute`, so the plan-level TDD gate does not apply.

## Deviations from Plan

None - plan executed exactly as written. Tests went beyond the listed behavior cases: the two other cancellable statuses, the 500-character limit after trimming, the lost atomic race, and direct select-list assertions.

## Issues Encountered

- **A `pending_approval` hold can outlast the session, and the client can no longer release it.** A request expires 12 hours after it is created (`booking.controller.js`), so a request made shortly before its slot can pass `end_time` while still pending. Before this change the client could cancel to void the hold right away. Now they get `SESSION_ALREADY_ENDED`, and the hold stays until `expireBookings` voids it at `expires_at`, up to about 12 hours after the request. No money is lost and the card is never captured: `completionCapture` defers on this status. This follows the plan, so it was not changed, but it is a tradeoff to review before the wave 2 push.
- **Late cancels of confirmed bookings now depend on the cron.** `expirePastSessions` Sweep A moves past-end `confirmed` and `pending_reschedule` rows to `missed`, with its own refund rules, so these rows are still settled, with no client action.
- **The expert time-guard truth has no dedicated test.** The plan limits Task 2's commit to three files, and none is the expert test file. It is proven by the expert controller having no guard code (grep count 0).
- **Commits on default branches.** Backend commits are on `master` as D-11 and the dispatch direct. iOS planning commits are on `main`, where `git.base-branch --is-protected` returns `true` and the executor's Step 0 assertion would halt. `branching_strategy` is `none`, the dispatch names this branch, and `execute-phase/steps/protected-branch.md` continues on the current branch for that strategy, as in plans 01-01 to 01-11. HEAD had not drifted and config was not changed.

## Requirements Status

`requirements.ready-ids` reports BACK-14 and BACK-12 as blocked, because a sibling plan in this phase also declares them and has no SUMMARY yet. They are not marked complete in `REQUIREMENTS.md` by this plan, and the last declaring plan will mark them.

## User Setup Required

None. The column was already applied to production at the 01-10 checkpoint.

## Next Phase Readiness

- Wave 2 commits on `master`, ready for the wave 2 gate: `0ed81f5`, `8cad41f`, `15d405c` (01-11), `deda040`, `87d3c62` (01-12). Production is still at `a92acba`.
- Client follow-ups: Phase 3 BOOK-07 and BOOK-13 can rely on `cancellation_reason` and `SESSION_ALREADY_ENDED`. The Android mapping of `SESSION_ALREADY_ENDED` is already logged in STATE.md. iOS `StandardErrorResponse` decodes an unknown code to nil and keeps the message, so build 6 shows the server text.

## Self-Check: PASSED

All six modified files exist. `deda040` and `87d3c62` are ancestors of backend HEAD.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*
