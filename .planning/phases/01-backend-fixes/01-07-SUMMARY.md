---
phase: 01-backend-fixes
plan: 07
subsystem: api
tags: [zod, express, jest, openapi, validation, booking]

requires:
  - phase: 01-backend-fixes
    provides: "01-01 shared test helpers and D-12 response-shape lock (contract suite still passes)"
provides:
  - "POST /bookings/request rejects a past or current scheduled_start and a duration_minutes that differs from the topic's duration_mins (422 VALIDATION_ERROR) before any Redis hold or insert (BACK-10)"
  - "hourly_rate.amount on topic create and patch is capped at 2147483647 with 'Price is too large.' instead of a Postgres INTEGER overflow 500 (BACK-11)"
  - "languages and expertise_tags are capped at 50 on PATCH /expert/profile and PATCH /expert/profile/setup, [] still clears, order preserved (BACK-11)"
affects: [01-10 wave-1 smoke checklist, 01-13 paid createPaymentIntent duration check]

tech-stack:
  added: []
  patterns:
    - "Hand-written ValidationError messages (not raw zod defaults) so they become the top-level message"
    - "Date-only fake clock (freezeClock) in jest so supertest timers stay real"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/booking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/booking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/schemas/expertTopics.schema.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertTopics.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/schemas/onboarding.schema.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/schemas/expertProfile.schema.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/onboarding.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/schemas/expertProfile.schema.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "Past-start check is at-or-before now (<=), so the exact current instant is rejected"
  - "topicDuration now prefers topic.duration_mins over the request value; the request only sizes a legacy topic with null duration_mins"
  - "Price bound is the INTEGER column limit (2147483647), not a business cap"
  - "Only the four arrays named in the plan are capped; PATCH /user/profile language arrays are untouched"

requirements-completed: [BACK-10, BACK-11]

coverage:
  - id: D1
    description: "Free booking requests with a start at or before now are rejected with 422 'Choose a session time in the future.' on scheduled_start, holding nothing and inserting nothing"
    requirement: BACK-10
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-10: scheduled_start and duration_minutes validation"
        status: pass
    human_judgment: false
  - id: D2
    description: "A duration_minutes that differs from the topic's duration_mins is rejected with 422 \"Session length must match the topic's length.\" before any hold; null-duration legacy topics and valid requests still reach 201"
    requirement: BACK-10
    verification:
      - kind: integration
        ref: "tests/booking.test.js#BACK-10: scheduled_start and duration_minutes validation"
        status: pass
    human_judgment: false
  - id: D3
    description: "Topic price amount 2147483647 accepted and 2147483648 rejected with 422 'Price is too large.' on both create and patch, no DB call"
    requirement: BACK-11
    verification:
      - kind: integration
        ref: "tests/expertTopics.test.js#hourly_rate.amount upper bound (BACK-11)"
        status: pass
    human_judgment: false
  - id: D4
    description: "50 languages / 50 expertise tags accepted, 51 rejected with hand-written messages, [] accepted, order and duplicates preserved, on onboarding and expert profile schemas and the setup route"
    requirement: BACK-11
    verification:
      - kind: unit
        ref: "tests/schemas/expertProfile.schema.test.js#expertProfilePatchSchema — list caps (BACK-11)"
        status: pass
      - kind: integration
        ref: "tests/onboarding.test.js#PATCH /api/v1/expert/profile/setup — list caps (BACK-11)"
        status: pass
    human_judgment: false
  - id: D5
    description: "No real expert profile in production already needs more than 50 tags or languages"
    requirement: BACK-11
    verification: []
    human_judgment: true
    rationale: "Open Q9 assumption; no production query was run. Plan 01-10 asks the user to spot-check one well-populated expert profile."

actuals:
  tokens: 7200
  tasks: 3
  commits: 3

plan_head_before: c994619af02da0bf11ef17edd4698aeb6434828b
plan_head_after: c994619af02da0bf11ef17edd4698aeb6434828b
backend_head_before: 0b92cf1
backend_head_after: c80981d725c38b00aa5455048c0c509f300ff98d

duration: not captured (start time was not recorded)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 07: BACK-10 and BACK-11 wave-1 validation Summary

**Free booking requests now reject a past start and a duration that does not match the topic (before any Redis hold), and oversized topic prices and 51+ item language or tag lists get a readable 422 instead of a 500.**

## Accomplishments

- **BACK-10:** `createRequest` throws `ValidationError(..., 'VALIDATION_ERROR', 422)` for `scheduled_start <= now` and for `duration_minutes !== topic.duration_mins` (when the topic has a numeric length). Both run after the is_free check and before the meeting-link lookup, the Redis hold and the insert. Slot keys and `end_time` now derive from the topic's own length.
- **BACK-11 price:** `hourlyRateSchema.amount` gets `.max(2147483647, 'Price is too large.')`, shared by create and patch.
- **BACK-11 lists:** `.max(50)` with hand-written messages on `languages` and `expertise_tags` in `onboarding.schema.js` and `expertProfile.schema.js`. `[]` still clears; the bound does not reorder or de-duplicate.
- **OpenAPI:** both 422 conditions documented on POST /bookings/request (with examples), `maximum: 2147483647` on both topic operations, `maxItems: 50` on the four arrays (count 4). `check-openapi-coverage` and `check-doc-coverage` print `OK: all 128 endpoints`.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `5b4ad5a` | fix(ios-p1/BACK-10): reject past or mismatched-duration free booking requests |
| backend (master) | `7c1e4f6` | fix(ios-p1/BACK-11): bound topic price amount |
| backend (master) | `c80981d` | fix(ios-p1/BACK-11): cap language and expertise tag lists at 50 |

Backend `git status -sb` shows `master...origin/main [ahead 16]` (13 before this plan plus these 3). Nothing was pushed or deployed. The `plan_head_before/after` fields are the iOS repo HEAD before the docs commit; the docs commit that adds this file follows it.

## Verification

- Task 1: `tests/booking.test.js` 130/130. Task 2: `tests/expertTopics.test.js` 97/97. Task 3: `tests/onboarding.test.js`, `tests/schemas/expertProfile.schema.test.js`, `tests/expertProfile.test.js` 47/47.
- Full gate (`npm test -- --testPathIgnorePatterns=tests/services/redis.test.js`): 125/125 suites, 2767/2767 tests, 0 failed. Exit 0. The D-12 contract suite is included and passes.
- RED evidence: with each source change temporarily reverted to HEAD, the new tests failed (3 of the BACK-10 cases, 3 of the BACK-11 price cases, 5 of the list-cap cases) and passed again once restored. The reverted state was never staged.
- Acceptance criteria re-run: `grep -c "Choose a session time in the future."` on the controller is 1 (baseline 0); `grep -c 2147483647` on expertTopics.schema.js is 1 (baseline 0); `grep -c "maxItems: 50"` on the OpenAPI file is 4 (baseline 0); each commit lists exactly its planned files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing /bookings/request tests used a now-past fixture date**
- **Found during:** Task 1
- **Issue:** The existing tests post `scheduled_start: '2024-10-24T10:30:00Z'`, which the new check correctly rejects as past, so they would fail.
- **Fix:** Added a `freezeClock()` helper in `tests/booking.test.js` that fakes only `Date` (every timer stays real so supertest is unaffected) at 2024-10-23T12:00Z, plus a global `afterEach(useRealTimers)`. Applied to the BOOK-09/10 and meeting_url-copy describes and to the two ONB-03 createRequest tests that reach the check. No fixture date was edited and no assertion was loosened.
- **Files modified:** tests/booking.test.js
- **Commit:** 5b4ad5a

**2. [Interpretation] topicDuration precedence changed**
- The plan says to compute it as `topic.duration_mins` when set, else `duration_minutes`, else 30. Implemented exactly that; the old order was request first. With the equality check this is behavior-neutral for valid requests and only differs for legacy topics with null length (unchanged: request value used).

**Total deviations:** 1 auto-fixed (Rule 3), 1 interpretation note. **Impact:** none on scope; the fake clock is test-only.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-11 mitigated: a past start or client-chosen duration is rejected before any hold or insert. T-01-12 mitigated: oversized amount and arrays now 422 before any DB write. T-01-SC: no packages installed or upgraded.

## Notes for later plans

- Plan 01-10 (wave-1 smoke): the 50-item cap rests on the unverified Open Q9 assumption. Ask the user to spot-check one well-populated expert profile and to confirm a free booking from both build 6 and Android still returns 201 (both send the topic's duration).
- Plan 01-13 owns the same duration check on the paid `createPaymentIntent` path; this plan deliberately did not touch it.
- `PATCH /user/profile` language arrays (`userProfile.schema.js`) are not capped; they were outside this plan's file list and do not feed an INTEGER column.
- Pre-existing untracked files in the backend repo were left untouched.

## Next

Ready for plan 01-08.

## Self-Check: PASSED

- FOUND backend commits `5b4ad5a`, `7c1e4f6`, `c80981d` (ancestors of backend HEAD `c80981d`)
- FOUND all nine modified backend files with the expected changes; acceptance greps re-run and pass
