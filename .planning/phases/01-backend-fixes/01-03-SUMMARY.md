---
phase: 01-backend-fixes
plan: 03
subsystem: api
tags: [push, fcm, notifications, jest, chats, reviews, webhooks, cron]

requires:
  - phase: 01-backend-fixes/01-02
    provides: "src/utils/pushTargetRole.js (targetRoleFor) and the target_role contract in sendPushToUser"
provides:
  - "New-message push carries target_role = the recipient's side of the thread"
  - "Review-received push carries target_role 'expert'"
  - "Refund-issued push from the Stripe webhook reconciler carries target_role 'client'"
  - "Session reminder pushes carry 'client' to booking.client_id and 'expert' to booking.expert_id"
affects: [01-04 (remaining senders: no-show, review nudge, long-lead charge, account pushes), 01-10 (wave-1 smoke checklist), iOS Phase 2 PUSH-01/PUSH-02]

actuals:
  tokens: 4200
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Senders import targetRoleFor from ../utils/pushTargetRole, never from ../services/push, so factory mocks of push in their suites cannot hide it"
    - "mock-prefixed mutable auth user id in a hoisted jest.mock factory to let one test act as the other thread participant"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/chats.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/reviews.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/webhooks.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/cron/reminderNotification.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/chats.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/reviews.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/webhooks.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/reminderNotification.test.js"

key-decisions:
  - "Chat uses targetRoleFor(thread, recipientId) on the chats row already loaded for the ownership check; no extra query"
  - "Review push uses the literal 'expert' because the push only fires when reviewer_role is 'client'"
  - "Webhook push uses targetRoleFor(booking, booking.client_id); the booking select has only client_id, which still resolves to 'client' because targetRoleFor falls through to the client check when expert_id is absent"

requirements-completed: [BACK-17]

coverage:
  - id: D1
    description: "A new-message push carries the recipient's role: 'expert' for a client-sent message, 'client' for an expert-sent message"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/chats.test.js#send: offline recipient (target_role expert); send: expert-sent message -> push to the client carries target_role client"
        status: pass
    human_judgment: false
  - id: D2
    description: "A review-received push carries target_role 'expert'"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/reviews.test.js#client submitReview -> sendPushToUser called on reviewee (expert) with category review (NOTIF-13)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The refund-issued push from the webhook reconciler carries target_role 'client'"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/webhooks.test.js#reconcileChargeRefunded - sendPushToUser refund emitter (NOTIF-10)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Reminder pushes carry 'client' to the client and 'expert' to the expert"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/reminderNotification.test.js#REM-03: calls sendPushToUser for both client_id and expert_id"
        status: pass
    human_judgment: false

# plan_head_before is the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: 4f075c0f26c3d87747cfa319f6b3af4fc7c422aa
backend_head_before: b7c5c9926f97dd4b3dd105b03c421ff11fbe21e2
backend_head_after: 979af3cac9f3e6e8a3ed19bcc5b957338a4e7438
commits: 2

duration: ~2 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 03: BACK-17 target_role on chat, review, refund-webhook and reminder pushes Summary

**Chat, review, refund-webhook and both reminder push senders now pass the recipient's own `target_role`, so build 6 and iOS Phase 2 know which mode to open for these taps.**

## Performance

- **Duration:** ~2 min wall clock (2026-11-08T05:28:34Z to 05:30:06Z)
- **Tasks:** 2 of 2
- **Files:** 8 backend files modified (4 source, 4 test), 70 insertions, 1 deletion

## Accomplishments

Call sites wired here, with the source of each role:

| Call site | Recipient | Role source |
|-----------|-----------|-------------|
| `src/controllers/chats.controller.js` send (new message) | the other thread participant | `targetRoleFor(thread, recipientId)` ('expert' when recipient is `thread.expert_id`, else 'client') |
| `src/controllers/reviews.controller.js` submitReview | `reviewee_id` (the expert) | literal `'expert'`; the push only fires for `reviewer_role === 'client'` |
| `src/controllers/webhooks.controller.js` reconcileChargeRefunded | `booking.client_id` | `targetRoleFor(booking, booking.client_id)` resolves to 'client' |
| `src/cron/reminderNotification.js` client reminder | `booking.client_id` | `targetRoleFor(booking, booking.client_id)` -> 'client' |
| `src/cron/reminderNotification.js` expert reminder | `booking.expert_id` | `targetRoleFor(booking, booking.expert_id)` -> 'expert' |

Together with plan 01-02 (events.js) and the `is_expert_only` default for Connect webhooks, the remaining unwired senders are those in plan 01-04.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `db63196` | fix(ios-p1/BACK-17): target_role on chat and review pushes |
| backend (master) | `979af3c` | fix(ios-p1/BACK-17): target_role on payment-action and reminder pushes |

Backend `git status -sb` shows `master...origin/main [ahead 6]` (2 from 01-01, 2 from 01-02, 2 from this plan). Nothing was pushed or deployed (D-11).

## Verification

- TDD: assertions were written first and confirmed red (3 failures in chats/reviews, 2 in webhooks/reminders) before the source change.
- Targeted: `tests/chats.test.js tests/reviews.test.js` 73/73; `tests/webhooks.test.js tests/reminderNotification.test.js` 44/44.
- Full gate as specified (`REDIS_URL=redis://localhost:6379 npm test`): 126/126 suites, 2713 tests, 0 failed. `check-openapi-coverage` and `check-doc-coverage` both print `OK: all 128 endpoints`.
- Without REDIS_URL (`--testPathIgnorePatterns=tests/services/redis.test.js`): 125/125 suites, 2707 tests on the final run. One earlier run of this configuration showed 1 failed test in `tests/account.test.js` (suite load under parallel run); the same file passed 3/3 when re-run alone (39/39 each) and the full suite passed on the next run. No file in this plan touches account code, so it is recorded as an intermittent flake, not a regression.
- Each commit lists exactly its four planned files; the post-commit deletion check found none.

## Deviations from Plan

### Auto-fixed Issues

None.

### Interpretation notes

**1. The "payment-action-required" push in webhooks.controller.js is the refund-issued push**
- The plan and must_haves call the push at `webhooks.controller.js:230` "payment-action-required". The code there is the `REFUND_ISSUED` push in `reconcileChargeRefunded` (category `booking`, sub_category `refunds`), sent to `booking.client_id`. It is the only `sendPushToUser` call in that file. The role ('client') is the same either way, so the wiring and the truth ("carries target_role 'client'") hold. Plan 01-04 and `docs/ios/PUSH-ROUTING.md` should refer to it as the refund push.

**2. chats.test.js auth mock made switchable**
- The suite's `authenticate` mock hard-coded the client user, so an expert-sent message could not be tested. It now reads a `mock`-prefixed `mockAuthUserId` (default null falls back to the client), and the new expert-sent test sets it and resets it in a `finally`. No other test is affected.

**Total deviations:** 0 auto-fixed, 2 interpretation notes. **Impact:** none on scope or behavior.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-46 accepted as planned: each call keeps its existing recipient and the value is that recipient's own side of their own thread or booking. T-01-SC: no packages installed or upgraded.

## Notes for later plans

- Plan 01-04 still has to wire no-show, review nudge, long-lead charge and the two account-level pushes; until then those send the routing keys but no role.
- `docs/ios/PUSH-ROUTING.md` (plan 01-02) lists these senders in its table; the webhook row should read as the refund push.

## Next

Ready for plan 01-04.

## Self-Check: PASSED

- FOUND commits in backend history: `db63196`, `979af3c`
- FOUND `target_role` in all four source files (chats, reviews, webhooks, reminderNotification)
