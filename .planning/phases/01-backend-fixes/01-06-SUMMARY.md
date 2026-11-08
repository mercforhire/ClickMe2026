---
phase: 01-backend-fixes
plan: 06
subsystem: api
tags: [express, jest, supertest, openapi, push, notifications, bookings, decline]

requires:
  - phase: 01-backend-fixes/01-02
    provides: "sendPushToUser in_app_meta option (notifications.meta_data only, never FCM data) and target_role on BOOKING_DECLINED"
  - phase: 01-backend-fixes/01-01
    provides: "contract.responseShapes.test.js additive-only lock (re-run green)"
provides:
  - "decline_reason_code and decline_reason_text on GET /client/bookings/:id, always present, non-null only when status is declined (BACK-02)"
  - "BOOKING_DECLINED push data carries decline_reason_code (enum) when given; decline_reason_text never enters the FCM data map"
  - "BOOKING_DECLINED notifications.meta_data carries decline_reason_text via in_app_meta"
  - "BOOKING_DECLINED chat system message event_data carries decline_reason_code and decline_reason_text when present"
affects: [iOS Phase 3 (show the decline note), 01-10 (wave-1 smoke checklist), Android decline note port]

actuals:
  tokens: 4443
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Free text reaches the client only through authenticated reads, the recipient's own notifications row and the two-party chat event; the push transport gets enums only"
    - "A column shared by two flows (decline_reason_text for request declines and reschedule declines) is exposed behind a status guard, not by column presence"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/clientBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/clientBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/bookingRequests.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/events.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/events.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/bookingRequests.test.js"

key-decisions:
  - "decline_reason_code is also gated on status declined in getDetail (the plan only named the text), so the two keys always move together"
  - "Empty or non-string code/text are treated as absent in events.js via a small nonEmptyString helper, so a blank value never produces an empty push key or an empty in_app_meta"
  - "Reschedule-decline callers (expertBooking.declineReschedule, clientBooking.declineReschedule) were left untouched: they already dispatch BOOKING_DECLINED with only id, client_id and expert_id, so no note can leak from the stale column"
  - "decline_reason_code is added to the push data map only for BOOKING_DECLINED; other event types ignore the fields even when the booking object carries them (tested)"

requirements-completed: [BACK-02]

coverage:
  - id: D1
    description: "Client booking detail returns the stored decline code and text for a declined booking; null for both on a non-declined booking holding an old reschedule-decline note; null for both on a declined booking with no note; code-only and 1000-character text handled"
    requirement: BACK-02
    verification:
      - kind: integration
        ref: "tests/clientBooking.test.js#BACK-02 decline note (declined bookings only)"
        status: pass
      - kind: integration
        ref: "tests/contract.responseShapes.test.js (additive-only key-set lock, still green)"
        status: pass
    human_judgment: false
  - id: D2
    description: "BOOKING_DECLINED push: code in data, text absent from data and every non-in_app_meta field, text in in_app_meta; no keys at all when neither field is present"
    requirement: BACK-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#dispatchBookingEvent — BOOKING_DECLINED decline note (BACK-02)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Chat system message event_data carries decline_reason_code and decline_reason_text when present, nothing for the reschedule-decline shape and nothing for other event types"
    requirement: BACK-02
    verification:
      - kind: unit
        ref: "tests/events.test.js#dispatchBookingEvent — BOOKING_DECLINED decline note (BACK-02)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The request decline handler passes the stored note (with explicit nulls when absent) to dispatchBookingEvent"
    requirement: BACK-02
    verification:
      - kind: integration
        ref: "tests/bookingRequests.test.js#BACK-02: dispatches BOOKING_DECLINED with the stored reason code and text; ...explicit nulls when no reason is given"
        status: pass
    human_judgment: false
  - id: D5
    description: "OpenAPI documents both nullable fields on ClientBookingDetail with the declined-only rule"
    requirement: BACK-02
    verification:
      - kind: other
        ref: "grep -c decline_reason_text openapi/clickme-api.yaml = 1 (baseline 0); check-openapi-coverage and check-doc-coverage OK (128 endpoints); YAML parses"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real device the decline note appears in the in-app notification and chat card after wave 1 deploys"
    requirement: BACK-02
    verification: []
    human_judgment: true
    rationale: "Rendering the note is iOS Phase 3 work; the backend half is covered by tests, and the device check belongs to the wave-1 smoke checklist (plan 01-10)"

# plan_head_before / plan_head_after are the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: c5583a8bb048cc86efe8448bebd4375e0b8c3db6
backend_head_before: 365e091ca3fbe98073c11dae0eb77e6335ed9579
backend_head_after: 0b92cf1d9f9511a9c1ec587a4d63974512f83e76
commits: 2

duration: ~3 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 06: BACK-02 decline note to the client Summary

**A client can now read why their request was declined: the booking detail returns the expert's code and text for declined bookings only, and the decline notification and chat card carry it, with the free text kept out of the push payload.**

## Performance

- **Duration:** ~3 min wall clock (start 2026-11-08T05:40:59Z)
- **Tasks:** 2 of 2
- **Files:** 7 backend files modified, 264 insertions, 3 deletions

## Accomplishments

- **Client detail (Task 1):** `getDetail` selects `decline_reason_code, decline_reason_text` and returns both keys on every response. They hold the stored values only when `status === 'declined'`, otherwise `null`. A confirmed booking that still holds a reschedule-decline note ("Can't do the new time") returns null, and the test asserts the string does not appear anywhere in the body.
- **OpenAPI (Task 1):** both properties added to `ClientBookingDetail` as nullable, with the declined-only rule and the 1000-character limit in the descriptions.
- **Request decline (Task 2):** `bookingRequests.decline` passes `{ ...booking, decline_reason_code: reason_code ?? null, decline_reason_text: reason_text ?? null }` to `dispatchBookingEvent`, because the fetched row predates the UPDATE.
- **Push and chat (Task 2):** in `events.js` the BOOKING_DECLINED push adds `decline_reason_code` to `data` when it is a non-empty string and passes `in_app_meta: { decline_reason_text }` only when the text is non-empty. `injectEventMessage` appends both keys to `event_data` for BOOKING_DECLINED only (same pattern as `cancel_reason`). The privacy comment required by the plan sits at the push case.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `8d090be` | fix(ios-p1/BACK-02): return the decline note on declined client bookings |
| backend (master) | `0b92cf1` | fix(ios-p1/BACK-02): carry the decline note in the decline notification and chat event |

Backend `git status -sb` shows `master...origin/main [ahead 13]`. Nothing was pushed or deployed (D-11).

## Verification

- TDD: both tasks written red first (6 failing in clientBooking.test.js; 5 failing across events.test.js and bookingRequests.test.js), then green.
- Task 1 gate: `tests/clientBooking.test.js tests/contract.responseShapes.test.js` 2 suites, 122/122 passed.
- Task 2 gate: `tests/events.test.js tests/bookingRequests.test.js tests/push.test.js` 3 suites, 194/194 passed.
- Full gate: `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` 125/125 suites, 2746 tests, 0 failed (baseline from plan 01-02: 2706). `tests/services/redis.test.js` was excluded as the known environmental failure (needs REDIS_URL); it was not run.
- `check-openapi-coverage` and `check-doc-coverage` both print `OK: all 128 endpoints`; the OpenAPI file parses as YAML.
- Acceptance criteria re-run, all pass: three behavior cases in clientBooking.test.js including the confirmed-with-stale-text case; `grep -c decline_reason_text` on the OpenAPI file is 1 (needs at least 1, baseline 0); events.test.js asserts the text is absent from `data` and present in `in_app_meta`; events.test.js asserts the neither-field (reschedule) shape adds no keys; bookingRequests.test.js asserts the dispatched booking carries both fields.
- Reschedule-decline callers confirmed by reading: both still dispatch `{ id, client_id, expert_id }` only.
- The post-commit check for accidental deletions found none for either commit.

## Deviations from Plan

None - plan executed exactly as written.

One small addition inside the plan's intent, recorded under key-decisions: `decline_reason_code` is gated on `declined` in the detail response alongside the text, and `events.js` ignores empty-string values.

**Total deviations:** 0. **Impact:** none.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-08 is mitigated and tested: the free text is asserted absent from the `sendPushToUser` `data` argument and from every field other than `in_app_meta`. T-01-09 is mitigated: the read stays scoped by `client_id` and the note is exposed only for declined bookings. T-01-10 accepted as planned (plain text, existing 1000-character limit). T-01-SC: no packages installed or upgraded.

## Notes for later plans

- **For iOS Phase 3:** read `decline_reason_code` / `decline_reason_text` from `GET /client/bookings/:id` (both always present, nullable). The push data map has `decline_reason_code` only; the text is in the notification row's `meta_data` and in the chat event's `event_data`. Render the text as plain text. The code set is `UNAVAILABLE, OUTSIDE_EXPERTISE, SCHEDULE_CONFLICT, PRICING, OTHER, CONFLICT, OUT_OF_SCOPE`.
- **Android:** the same keys are additive and safe for the current Android build (lenient Moshi decoding, RESEARCH A6). A port to display the note is a separate Android change.
- **Plan 01-10 smoke checklist:** decline a request with a note and confirm the in-app notification row and chat card show it, and that the push banner does not.
- Pre-existing untracked files in the backend repo (`.planning/phases/*`, `assets/`, `scripts/uat-seed-profile.js`) were left untouched.

## Next

Ready for plan 01-07.

## Self-Check: PASSED

- FOUND backend commits: `8d090be`, `0b92cf1` (backend master)
- FOUND modified files in backend: all 7 listed under key-files
