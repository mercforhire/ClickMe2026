---
phase: 01-backend-fixes
plan: 02
subsystem: api
tags: [push, fcm, apns, jest, openapi, notifications]

requires:
  - phase: 01-backend-fixes/01-01
    provides: "contract.responseShapes.test.js (re-run green) and the additive-only rule"
provides:
  - "sendPushToUser sends category and sub_category to every token (ios, android, platform null)"
  - "target_role (client|expert) in the FCM data map and notifications.meta_data"
  - "in_app_meta option: written to notifications.meta_data only, never to FCM data"
  - "src/utils/pushTargetRole.js: targetRoleFor, targetRoleForAccount, ALLOWED_TARGET_ROLES (re-exported by push.js)"
  - "docs/ios/PUSH-ROUTING.md push data contract for iOS Phase 2 PUSH-01/PUSH-02 and Android"
  - "All eight booking-lifecycle sendPushToUser calls in events.js carry the recipient's target_role"
affects: [01-03 (chat, review, webhook, reminder call sites), 01-04 (no-show, nudge, long-lead, account pushes), 01-06 (BACK-02 in_app_meta), 01-10 (wave-1 smoke checklist), iOS Phase 2 PUSH-01/PUSH-02]

actuals:
  tokens: 9128
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Platform-neutral routing contract; platform check demoted to the Android-only presentation block"
    - "Role helpers in a dependency-free util so factory mocks of ../services/push in other suites cannot hide them"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/utils/pushTargetRole.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/PUSH-ROUTING.md"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/push.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/events.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/push.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/events.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "Routing keys promoted to every platform; no iOS-specific variant (assumption_delta_decision: promote)"
  - "A disallowed explicit target_role is dropped (console.warn without user data), not coerced; is_expert_only then still defaults to expert"
  - "Explicit target_role wins over the is_expert_only default"
  - "meta_data merge order is data, then target_role, then in_app_meta, so in_app_meta can add keys but a caller cannot spoof target_role through data alone after resolution is applied"

requirements-completed: [BACK-17]

coverage:
  - id: D1
    description: "iOS, Android and platform-less tokens all receive category and sub_category in the FCM data map; android.notification stays Android-only"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/push.test.js#platform %s: sent data carries category and sub_category (ios, android, null)"
        status: pass
      - kind: unit
        ref: "tests/push.test.js#android channel and data (Phase 13 D-04) (inverted iOS and legacy expectations)"
        status: pass
    human_judgment: false
  - id: D2
    description: "target_role resolution: explicit allow-listed value, is_expert_only default, disallowed value dropped, absent otherwise"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/push.test.js#is_expert_only with no explicit target_role defaults to expert; a disallowed target_role is dropped; no target_role and not expert-only"
        status: pass
    human_judgment: false
  - id: D3
    description: "in_app_meta (free text) reaches notifications.meta_data and never the FCM data map"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/push.test.js#in_app_meta lands in the notifications row and never in the FCM data map"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every booking-lifecycle push in events.js carries the recipient's own role"
    requirement: BACK-17
    verification:
      - kind: unit
        ref: "tests/events.test.js#dispatchBookingEvent — target_role per recipient (BACK-17, D-02)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Push routing contract documented for iOS Phase 2 and Android, and pointed to from OpenAPI"
    requirement: BACK-17
    verification:
      - kind: other
        ref: "grep -c target_role docs/ios/PUSH-ROUTING.md = 12; grep -c PUSH-ROUTING.md openapi/clickme-api.yaml = 2; check-openapi-coverage and check-doc-coverage OK (128 endpoints)"
        status: pass
    human_judgment: true
    rationale: "Doc accuracy against the sender table for plans 01-03/01-04 can only be confirmed once those call sites land; the wave-1 smoke checklist (plan 01-10) covers real-device taps on build 6"

# plan_head_before / plan_head_after are the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: 1a25785af3869571492a53a3a64804e0f7dba5a0
backend_head_before: 017874ab1a4bb9b5f94b1564369f199e34770367
backend_head_after: b7c5c9926f97dd4b3dd105b03c421ff11fbe21e2
commits: 2

duration: ~3 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 02: BACK-17 push routing fields and target_role Summary

**Every push now carries `category`, `sub_category` and a per-recipient `target_role` to iOS, Android and platform-less tokens, with an `in_app_meta` channel that keeps free text out of FCM.**

## Performance

- **Duration:** ~3 min wall clock (start 2026-11-08T05:24:38Z)
- **Tasks:** 2 of 2
- **Files:** 7 backend files changed (2 created, 5 modified), 481 insertions, 21 deletions

## Accomplishments

- **push.js contract (Task 1):** `category` and `sub_category` are built into the FCM data map for every token. `isAndroid` now only gates the `android.notification` block (channelId, `visibility: 'private'`). `target_role` is resolved once per call: explicit value if in `ALLOWED_TARGET_ROLES`, else `expert` for `is_expert_only`, else absent. The notifications insert writes `meta_data` as `data`, then `target_role`, then `in_app_meta`.
- **Helpers:** `src/utils/pushTargetRole.js` exports `targetRoleFor(booking, recipientId)` (case-insensitive via `isSameUser`), `targetRoleForAccount(roles)` and `ALLOWED_TARGET_ROLES`. It requires only `./sameUser`; push.js re-exports all three. Plans 01-03 and 01-04 import from the util.
- **events.js (Task 2):** all eight `sendPushToUser` calls in `dispatchPushForEvent` pass `target_role: targetRoleFor(booking, <recipient>)`: `booking_request` expert; CONFIRMED, DECLINED, EXPIRED client; CANCELLED, COMPLETED, RESCHEDULED the recipient's own role.
- **Docs:** `docs/ios/PUSH-ROUTING.md` (data keys, target_role rules, 19-row sender table, build 6 note, account-level rule, Phase 2 consumer guidance). OpenAPI gets a "Push payload contract" description on `POST /notifications/tokens` and a `target_role` note on the notification `meta_data` description.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `a2e55de` | fix(ios-p1/BACK-17): send push routing fields to every platform plus target_role (D-01/D-02) |
| backend (master) | `b7c5c99` | fix(ios-p1/BACK-17): pass target_role on booking lifecycle pushes |

Backend `git status -sb` shows `master...origin/main [ahead 4]` (2 from plan 01-01, 2 from this plan). Nothing was pushed or deployed (D-11).

## Verification

- TDD: tests written first and confirmed red (19 failing in push.test.js; 12 failing in events.test.js) before the implementation.
- Targeted: `tests/events.test.js tests/push.test.js tests/contract.responseShapes.test.js` 3 suites, 131/131 passed.
- Full gate: `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` 125/125 suites, 2706 tests, 0 failed. `tests/services/redis.test.js` was excluded as the known environmental failure (needs REDIS_URL); it was not run.
- `check-openapi-coverage` and `check-doc-coverage` both print `OK: all 128 endpoints`; the OpenAPI file still parses as YAML.
- Acceptance criteria re-run, all pass: platform loop test (`ios`, `android`, `null`); in_app_meta in the insert and absent from `messaging.send`; the `node -e` util check exits 0; `grep -c target_role` on PUSH-ROUTING.md is 12 (needs 3); `grep -c PUSH-ROUTING.md` on the OpenAPI file is 2 (needs 1, baseline 0); `grep -v "^ *\*" events.js | grep -c "targetRoleFor(booking"` is 8 (needs 8, baseline 0).
- The pre-commit check for accidental deletions found none.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two pre-existing assertions encoded the old payload shape**
- **Found during:** Task 1 (green run) and Task 2
- **Issue:** `tests/push.test.js` "coerces non-string data values" did a `toEqual` on the data map, and `tests/events.test.js` "legacy BOOKING_CANCELLED push is unchanged" did an exact-argument match. Both break by design once the routing keys and `target_role` are always sent.
- **Fix:** The first now expects `category: ''` and `sub_category: ''`; the second now expects `target_role: 'expert'`. Neither assertion was weakened.
- **Files modified:** `tests/push.test.js`, `tests/events.test.js`
- **Commits:** `a2e55de`, `b7c5c99`

**2. [Interpretation] Test layout in push.test.js**
- The plan asks to invert the Phase 13 D-04 expectations and add new cases. The new cases were added inside the existing describe, and the targetRoleFor and targetRoleForAccount unit blocks were placed after it; the last existing test ("review nudge uses sessions") now sits in a small "continued" describe with its own `scriptTokens` helper, because the helper is scoped to its describe. No test was removed.

**Total deviations:** 1 auto-fixed (Rule 1, test expectations), 1 interpretation note. **Impact:** none on scope or behavior.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md` (the file does not exist yet).

## Threat Flags

None. T-01-03 is mitigated and tested: only enums and ids enter the FCM data map (`target_role` passes through `ALLOWED_TARGET_ROLES`), and `in_app_meta` is asserted absent from the sent message (the test also checks the literal value `Busy` does not appear anywhere in the `messaging.send` argument). T-01-04 accepted as planned (routing hint only). T-01-SC: no packages installed or upgraded.

## Notes for later plans

- **Behavior change on deploy:** build 6 reads `data["category"]` first, so iOS taps on confirmed, declined, cancelled, reminder, no-show, nudge and payment-action pushes begin navigating as soon as wave 1 deploys (accepted by the user 2026-11-07). This is also why the plan 01-10 smoke checklist must tap each type on a build 6 device.
- **Not yet wired:** chat (`chats.controller.js`), review, refund webhook, reminders (plan 01-03), and no-show, review nudge, long-lead charge and the two account pushes (plan 01-04) do not pass `target_role` yet. Until then they send the routing keys but no role. Connect webhook pushes already get `expert` from `is_expert_only`.
- Import `targetRoleFor` and `targetRoleForAccount` from `../utils/pushTargetRole`, not from `push.js`, in any sender whose tests mock `../services/push` with a factory.
- `in_app_meta` is ready for BACK-02 in plan 01-06 (decline note).
- Pre-existing untracked files in the backend repo (`.planning/phases/*`, `assets/`, `scripts/uat-seed-profile.js`) were left untouched.

## Next

Ready for plan 01-03.

## Self-Check: PASSED

- FOUND: `src/utils/pushTargetRole.js`, `docs/ios/PUSH-ROUTING.md` (backend)
- FOUND commits in backend history: `a2e55de`, `b7c5c99`
