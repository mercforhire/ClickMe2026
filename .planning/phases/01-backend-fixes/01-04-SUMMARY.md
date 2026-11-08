---
phase: 01-backend-fixes
plan: 04
subsystem: api
tags: [push, fcm, notifications, jest, cron, account]

requires:
  - phase: 01-backend-fixes/01-02
    provides: "src/utils/pushTargetRole.js (targetRoleFor, targetRoleForAccount) and the target_role contract in sendPushToUser"
  - phase: 01-backend-fixes/01-03
    provides: "chat, review, refund-webhook and reminder senders already carrying target_role"
provides:
  - "No-show push carries the absent party's own role"
  - "Review-nudge and long-lead payment-action pushes carry target_role 'client'"
  - "Password-changed and account-deletion-requested pushes carry the caller's primary role (expert when roles include expert, else client)"
  - "D-02 holds at every sendPushToUser call site in src outside push.js, with no exemption"
affects: [01-10 (wave-1 smoke checklist), iOS Phase 2 PUSH-01/PUSH-02]

actuals:
  tokens: 2760
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Senders import targetRoleFor / targetRoleForAccount from ../utils/pushTargetRole, never from ../services/push (factory mocks of push in their suites would hide them)"
    - "Account-level pushes take the role from the verified JWT (req.user.roles), no database read"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/cron/noShowNotification.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/cron/reviewNudgeNotification.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/cron/longLeadChargeSweep.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/account.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/noShowNotification.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/reviewNudgeNotification.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/cron/longLeadChargeSweep.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/account.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/userPassword.test.js"

key-decisions:
  - "Account pushes use targetRoleForAccount(req.user.roles); a stale JWT can only yield 'client', which is acceptable because the security screen exists in both modes (plan assumption, no DB read added)"
  - "Review-nudge and long-lead selects carry no expert_id; targetRoleFor still resolves 'client' via its client_id fall-through"

requirements-completed: [BACK-17]

coverage:
  - id: D1
    description: "A no-show push carries the absent party's role: 'expert' when the client joined, 'client' when the expert joined"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/noShowNotification.test.js#notifies expert_id when client joined (target_role expert); notifies client_id when expert joined (target_role client)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Review-nudge and long-lead payment-action pushes carry target_role 'client'"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/reviewNudgeNotification.test.js#sends to client_id only; tests/cron/longLeadChargeSweep.test.js#261028-snh SCA push"
        status: pass
    human_judgment: false
  - id: D3
    description: "Password-changed push carries 'expert' for a caller holding the expert role and 'client' otherwise, with no password material in push data"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/userPassword.test.js#7b. password_changed push carries target_role (client-only, expert)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Account-deletion-requested push carries 'expert' / 'client' by caller role, and its data holds only event_type (no deletion token)"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/account.test.js#deletion_requested push carries target_role (client-only caller, expert caller with no blocking bookings)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every sendPushToUser call in src outside push.js passes target_role or is_expert_only: true"
    requirement: BACK-17
    verification:
      - kind: other
        ref: "grep audit of sendPushToUser( in src (table below); full gate 126/126 suites, 2717 tests; check-openapi-coverage and check-doc-coverage OK (128 endpoints)"
        status: pass
    human_judgment: false

# plan_head_before is the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: 87f58ca892d5e95426a61c95f7c825a1e318e4b7
backend_head_before: 979af3cac9f3e6e8a3ed19bcc5b957338a4e7438
backend_head_after: 70c7ed6ee2ffdd12649f43e267ad93f4a6c43391
commits: 2

duration: ~6 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 04: BACK-17 target_role on no-show, nudge, long-lead and account pushes Summary

**The last five push senders now carry `target_role`, so every push the backend sends tells the client app which mode to open, with no exemption from D-02.**

## Performance

- **Duration:** ~6 min wall clock
- **Tasks:** 2 of 2
- **Files:** 9 backend files modified (4 source, 5 test), 83 insertions, 0 deletions

## Accomplishments

- **Task 1 (crons):** `noShowNotification.js` passes `targetRoleFor(booking, absentUserId)`, the same id the cron already sends to, so the role is the absent party's own. `reviewNudgeNotification.js` and `longLeadChargeSweep.js` pass `targetRoleFor(booking, booking.client_id)`. Each is one added argument plus an import.
- **Task 2 (account):** `deleteRequest` and `changePassword` pass `targetRoleForAccount(req.user.roles)`. Titles, bodies, categories, data and the best-effort try/catch are unchanged. Tests run through the real `authenticate` middleware with signed JWTs, so the role really comes from `app_metadata`.
- **Call-site audit:** see the table below.

### Call-site audit: every `sendPushToUser(` in `src` outside `push.js`

| Call site | Recipient | Role source |
|-----------|-----------|-------------|
| `services/events.js` booking_request (260) | expert | `targetRoleFor(booking, expert_id)` |
| `services/events.js` CONFIRMED (272) | client | `targetRoleFor(booking, client_id)` |
| `services/events.js` DECLINED (284) | client | `targetRoleFor(booking, client_id)` |
| `services/events.js` cancelled, notify both (319) | each party | `targetRoleFor(booking, uid)` |
| `services/events.js` EXPIRED (339) | client | `targetRoleFor(booking, client_id)` |
| `services/events.js` COMPLETED client (347) | expert | `targetRoleFor(booking, expert_id)` |
| `services/events.js` COMPLETED/RESCHEDULED (358) | client | `targetRoleFor(booking, client_id)` |
| `services/events.js` legacy CANCELLED (376) | notified party | `targetRoleFor(booking, notifyId)` |
| `controllers/chats.controller.js` send (484) | other participant | `targetRoleFor(thread, recipientId)` |
| `controllers/reviews.controller.js` submitReview (101) | expert | literal `'expert'` |
| `controllers/webhooks.controller.js` refund issued (231) | client | `targetRoleFor(booking, booking.client_id)` |
| `controllers/connectWebhooks.controller.js` KYC action (156) | expert | `is_expert_only: true` (push.js turns it into 'expert') |
| `controllers/connectWebhooks.controller.js` payout paid/failed (219) | expert | `is_expert_only: true` |
| `controllers/connectWebhooks.controller.js` dispute opened (958) | expert | `is_expert_only: true` |
| `controllers/account.controller.js` deleteRequest (254) | caller | `targetRoleForAccount(req.user.roles)` (this plan) |
| `controllers/account.controller.js` changePassword (472) | caller | `targetRoleForAccount(req.user.roles)` (this plan) |
| `cron/noShowNotification.js` (96) | absent party | `targetRoleFor(booking, absentUserId)` (this plan) |
| `cron/reviewNudgeNotification.js` (108) | client | `targetRoleFor(booking, booking.client_id)` (this plan) |
| `cron/longLeadChargeSweep.js` payment action (365) | client | `targetRoleFor(booking, booking.client_id)` (this plan) |
| `cron/reminderNotification.js` client (89) | client | `targetRoleFor(booking, booking.client_id)` |
| `cron/reminderNotification.js` expert (100) | expert | `targetRoleFor(booking, booking.expert_id)` |

No call site lacks a role source. The remaining grep hits in `events.js` lines 236-240 are doc comments, not calls.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `b94fcea` | fix(ios-p1/BACK-17): target_role on no-show, review-nudge and long-lead pushes |
| backend (master) | `70c7ed6` | fix(ios-p1/BACK-17): account-level pushes carry the recipient's primary role (D-02) |

Backend `git status -sb` shows `master...origin/main [ahead 8]` (2 each from plans 01-01 to 01-04). Nothing was pushed or deployed (D-11).

## Verification

- TDD: assertions were written first and confirmed red (4 failures in the three cron suites; 4 failures in account/userPassword) before the source change.
- Targeted: the three cron suites 65/65; `tests/account.test.js tests/userPassword.test.js` 53/53.
- Full gate as specified (`REDIS_URL=redis://localhost:6379 npm test`; Redis was reachable locally): 126/126 suites, 2717 tests, 0 failed. `check-openapi-coverage` prints `OK: all 128 endpoints present in spec`; `check-doc-coverage` prints `OK: all 128 endpoints covered 1:1`.
- `grep -c "targetRoleForAccount(req.user" src/controllers/account.controller.js` is 2 (baseline 0).
- Each commit lists exactly its planned files (6 and 3); the post-commit deletion check found none.

## Deviations from Plan

None - plan executed as written.

The orchestrator's note about plan 01-03 (the push at `webhooks.controller.js:230` being the refund push) needed no change here. The separate payment-action push the plan expects does exist: it is the SCA branch push in `longLeadChargeSweep.js` (`PAYMENT_ACTION_REQUIRED`), wired in Task 1. `docs/ios/PUSH-ROUTING.md` already lists the refund push and the long-lead payment-action push as separate rows (lines 69-70), so no doc edit was needed.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-05 mitigated and tested: the no-show role is computed from the same `absentUserId` the cron already sends to, and both orientations are pinned. T-01-47 mitigated and tested: only the enum `target_role` was added, and the new account tests assert the push `data` is exactly `{ event_type }` (and the password test asserts the new password is absent from the payload). T-01-SC: no packages installed or upgraded.

## Notes for later plans

- After wave-1 deploy, all pushes carry `target_role`. Plan 01-10's smoke checklist should tap one push of each type on a build 6 device, including password-changed and deletion-requested.
- An expert whose JWT predates promotion gets `target_role: 'client'` on account pushes. Accepted per the plan: the security screen exists in both modes.

## Next

BACK-17 is complete (plans 01-02, 01-03, 01-04). Ready for the next plan in phase 01.

## Self-Check: PASSED

- FOUND commits in backend history: `b94fcea`, `70c7ed6`
- FOUND `target_role` in `noShowNotification.js`, `reviewNudgeNotification.js`, `longLeadChargeSweep.js`; `targetRoleForAccount(req.user` x2 in `account.controller.js`
