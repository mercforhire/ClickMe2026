---
phase: 01-backend-fixes
plan: 09
subsystem: api
tags: [chat, booking, accept, socket, push, refactor, jest, openapi]

requires:
  - phase: 01-backend-fixes/01-03
    provides: "chat push carries target_role via targetRoleFor (kept when extracting the send path)"
  - phase: 01-backend-fixes/01-08
    provides: "GET /chats lists empty threads, so a thread created by accept shows in Chats"
provides:
  - "src/services/chatMessages.js postUserMessage: the one path for posting a user chat message (insert with dedup, chats denormalization, message.new emit, chat push)"
  - "ensureThread exported from src/services/events.js"
  - "Booking accept delivers the optional message as a chat message from the expert, with socket event and push"
  - "OpenAPI documents the optional accept body on both accept operations"
affects: [01-14 (BACK-18 unread recount goes inside postUserMessage), 01-10 (wave-1 smoke checklist), iOS accept-message field]

actuals:
  tokens: 14000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Shared service owns the message side effects; callers own authorization (send rejects, accept skips)"
    - "Deterministic client_msg_id (booking-accept:<booking id>) reuses the messages unique constraint for idempotency"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/chatMessages.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/services/chatMessages.test.js"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/chats.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/events.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/bookingRequests.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/bookingRequests.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "postUserMessage does no ownership, block or moderation checks; chats.send keeps its rejecting checks and accept re-applies is_blocked and getAccountStatus as silent skips (T-01-16)"
  - "Existing log prefixes ([chats.send] ...) were kept inside the extracted function so log filters do not change"
  - "A moderation lookup error in accept fails open, mirroring chats.send"

requirements-completed: [BACK-01]

coverage:
  - id: D1
    description: "Accept with a non-blank message posts it, trimmed, as a text chat message from the expert after the BOOKING_CONFIRMED dispatch, using client_msg_id booking-accept:<booking id>; both accept URLs"
    requirement: BACK-01
    verification:
      - kind: unit
        ref: "tests/bookingRequests.test.js#accept message (BACK-01): posts the trimmed message once...; also posts through the /expert/bookings/:id/accept alias"
        status: pass
    human_judgment: false
  - id: D2
    description: "No, empty or whitespace-only message posts nothing and still returns 200; a 1000 code-unit message with emoji is passed verbatim"
    requirement: BACK-01
    verification:
      - kind: unit
        ref: "tests/bookingRequests.test.js#accept message (BACK-01): posts nothing and returns 200 for ...; passes a 1000 code-unit message with emoji through verbatim"
        status: pass
    human_judgment: false
  - id: D3
    description: "Blocked thread, suspended or terminated client, null thread (self-pair) and unreadable chats row skip the post; a failing post never changes the 200 response body"
    requirement: BACK-01
    verification:
      - kind: unit
        ref: "tests/bookingRequests.test.js#accept message (BACK-01): skips ... blocked; skips ... suspended/terminated; returns 200 with an unchanged body when posting rejects; ensureThread null"
        status: pass
    human_judgment: false
  - id: D4
    description: "postUserMessage inserts, updates the chats row, emits message.new and pushes once; dedups on 23505 with no side effects; side-effect failures never throw; non-23505 insert error throws; recipient follows the sender"
    requirement: BACK-01
    verification:
      - kind: unit
        ref: "tests/services/chatMessages.test.js (5 cases)"
        status: pass
    human_judgment: false
  - id: D5
    description: "POST /chats/:id/send behaves exactly as before the extraction"
    requirement: BACK-01
    verification:
      - kind: unit
        ref: "tests/chats.test.js (unchanged, passes)"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real device the client sees the expert's accept note in Chats with a push and live update"
    requirement: BACK-01
    verification: []
    human_judgment: true
    rationale: "Socket delivery, APNs push and Chats rendering across a real expert/client pair are only observable on devices against a deployed backend; covered by the wave-1 smoke checklist (plan 01-10)."

# plan_head_before is the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: fdd9bec89f815f8ac33df81c93866289d955c8d9
backend_head_before: 9fe6178149e81230c4daa9aa03e5b7ba9e8ec91a
backend_head_after: a1492798c17f8eaf85679f05a00d255c3cb5838f
commits: 2

duration: ~25 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 09: BACK-01 accept message delivered as a chat message Summary

**When an expert accepts a booking with a note, the backend now posts that note as a normal chat message from the expert in the client-expert thread (thread created if needed, socket event and push included), through a new `postUserMessage` service shared with `POST /chats/:id/send`.**

## Performance

- **Duration:** ~25 min wall clock
- **Tasks:** 2 of 2
- **Files:** 7 backend files (2 created, 5 modified)

## Accomplishments

- **Task 1, extraction (behavior-preserving).** The insert with 23505 dedup, the best-effort chats denormalization, the best-effort `message.new` emit and the best-effort chat push (with `target_role` from 01-03) moved verbatim from `chats.send` into `postUserMessage({ thread, senderId, type, content, clientMsgId })`. `chats.send` keeps the participant guard, `THREAD_BLOCKED` and `RECIPIENT_UNAVAILABLE`, then delegates and returns the same 201 body. The unread comment block was left in the service for plan 01-14 to replace. `ensureThread` is now exported from `events.js`. The now-unused `getIo`, `sendPushToUser` and `targetRoleFor` imports were dropped from the controller.
- **Task 2, accept wiring.** After the `BOOKING_CONFIRMED` dispatch, `accept` reads `message` from the validated body; if its trim is non-empty it runs a best-effort `postAcceptMessage`: `ensureThread` (null/self-pair skips), read the chats row (missing or `is_blocked` skips), `getAccountStatus(client)` (existing non-active account skips, lookup error fails open), then `postUserMessage` with `client_msg_id` `booking-accept:<booking id>`. Any throw is logged ("accept message post failed (non-fatal, BACK-01)") and the 200 body is unchanged.
- **OpenAPI.** Both accept operations (`acceptExpertBookingRequest`, `acceptExpertBooking`) now document the optional `message` request body (maxLength 1000, delivered as a chat message, not stored on the booking, skipped for blocked threads).

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `95d9450` | refactor(ios-p1/BACK-01): extract postUserMessage from chats.send |
| backend (master) | `a149279` | fix(ios-p1/BACK-01): deliver the accept message to the client as a chat message (D-14) |

Backend `git status -sb` shows `master...origin/main [ahead 20]`. Nothing was pushed or deployed (D-11). No `git add -A`; each commit lists exactly its planned files, and the post-commit deletion check found none.

## Verification

- Task 1: `tests/services/chatMessages.test.js tests/chats.test.js tests/events.test.js` 134/134. `tests/chats.test.js` is untouched (`git diff HEAD~2 --stat` empty). `ensureThread` appears in `module.exports` (baseline: absent).
- Task 2: `tests/bookingRequests.test.js tests/expertBooking.test.js` 195/195 (77 in bookingRequests, 13 of them new for BACK-01, counting the `it.each` expansions). `grep -c "booking-accept:"` in the controller is 1 (baseline 0).
- Full gate (`--testPathIgnorePatterns=tests/services/redis.test.js`): 126/126 suites, 2790/2790 tests, 0 failed. `check-openapi-coverage` and `check-doc-coverage` both print `OK: all 128 endpoints`. No flaky failure occurred on the final run.

## Deviations from Plan

None - plan executed exactly as written.

### Interpretation notes

- In `tests/bookingRequests.test.js` the events mock gained `ensureThread` and two new module mocks were added (`chatMessages`, and `moderation` with `requireActual` spread so other exports stay intact). The pre-existing accept test that already sends a message keeps passing because the default `ensureThread` mock resolves to undefined and the post is skipped.
- The existing `tests/expertBooking.test.js` mocks `events` without `ensureThread`; an accept with a message there would throw a TypeError inside the non-fatal block and be logged, not fail. It passes unchanged.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. Mitigations T-01-15 (sender is the authenticated expert, no client-supplied sender) and T-01-16 (blocked thread and non-active client skipped, both covered by tests) are implemented.

## Next Phase Readiness

Ready for plan 01-10. Plan 01-14 (BACK-18) can add the unread recount inside `postUserMessage`, and the accept message will count as unread with no further change. The backend change is not deployed; the user pushes and deploys wave 1 (D-10, D-11).

## Self-Check: PASSED

- FOUND: src/services/chatMessages.js, tests/services/chatMessages.test.js (backend)
- FOUND commits 95d9450 and a149279 on backend master (`git merge-base --is-ancestor` true for both)
- All acceptance criteria re-run and passing; plan-level verification (full gate, chats tests unchanged, nothing pushed) passing
