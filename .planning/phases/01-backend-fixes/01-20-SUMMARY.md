---
phase: 01-backend-fixes
plan: 20
subsystem: auth
tags: [expert-gate, roles, middleware, express, jest, wave-3c, BACK-13]

requires:
  - phase: 01-backend-fixes
    provides: "01-19 closed wave 3b; production and master were both at 3899d63 when this plan started"
provides:
  - "A method-aware expert gate: GET/HEAD/OPTIONS pass through without promoting, other methods return 403 EXPERT_SETUP_REQUIRED for a client-only account"
  - "provisionExpert, mounted only on PATCH /expert/profile/setup, after validation"
  - "resolveIsExpert: a stale token whose profiles.roles has expert passes both gates"
  - "Five route suites and the onboarding suite rewritten to the new contract"
affects: [01-21 (38-route table, BACK-08 seams, tax-profile GET), 01-22 (OpenAPI enum, EXPERT-SETUP-GATE.md, remaining route headers), 01-23 (wave 3c handoff), Phase 5 SIGN-06, Android EXPERT_SETUP_REQUIRED follow-up]

# Measured in the BACKEND repo, where all code commits live:
# git -C "<backend>" rev-list --count 3899d63..bdc580f = 3. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (56586 bytes). The iOS repo holds planning docs only.
actuals:
  tokens: 14147
  tasks: 3
  commits: 3
plan_head_before: 3899d63ca77828f1b432b1473ed2913fe037c13b
plan_head_after: bdc580f5bc995b4acb4dcc822dd82245d721b40c

tech-stack:
  added: []
  patterns:
    - "The HTTP method selects the expert gate; a route that needs the stricter gate on a GET mounts expertWriteGate explicitly"
    - "Role changes are written only by provisionExpert; gates may add a role to req.user.roles for one request, never to the database"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/middleware/ensureExpert.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/onboarding.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/middleware/ensureExpert.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/onboarding.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertProfile.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/earnings.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/earnings.transactions.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/payouts.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/connect.test.js"

key-decisions:
  - "01-20 BACK-13: the default export of ensureExpert is the method-aware gate, so every existing mount changes behavior with no wiring change; only the setup route is rewired"
  - "01-20 BACK-13: a failed profiles.roles read goes through dbError, a generic 500 with the real error logged, because errorHandler would otherwise echo the raw Supabase message; provisionExpert's own error paths are unchanged"
  - "01-20 BACK-13: a schema-valid setup PATCH promotes even when it is {} or when the controller then returns 422 for an incomplete publish; matches the plan and logged in deferred-items.md as a possible user decision"

patterns-established:
  - "Each client-only route test scripts the gate's profiles.roles read and asserts no updateUserById, no expert_profiles upsert and no profiles update"

# Corrected at the 01-23 close, 2026-11-08: this listed BACK-13 as a template artifact. Wave 3c was dropped, so nothing here is delivered. See 01-23-SUMMARY.md.
requirements-completed: []

coverage:
  - id: D1
    description: "The expert gate never promotes: client-only reads pass through, client-only writes get 403 EXPERT_SETUP_REQUIRED, JWT experts make no database read, and DB errors are 500s"
    requirement: BACK-13
    verification:
      - kind: unit
        ref: "tests/middleware/ensureExpert.test.js (38 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A stale token whose profiles.roles has expert passes both gates, and req.user.roles includes expert for that request"
    requirement: BACK-13
    verification:
      - kind: unit
        ref: "tests/middleware/ensureExpert.test.js#stale JWT with DB expert"
        status: pass
    human_judgment: false
  - id: D3
    description: "PATCH /expert/profile/setup promotes after validation; a schema-invalid body returns 422 and promotes nothing; a JWT expert skips provisioning"
    requirement: BACK-13
    verification:
      - kind: integration
        ref: "tests/onboarding.test.js#provisionExpert on setup (BACK-13, D-07)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Client-only GET /expert/profile, earnings weekly, earnings transactions and payouts summary reach their controllers without promotion, and POST /expert/connect/onboard returns 403 with no Stripe call"
    requirement: BACK-13
    verification:
      - kind: integration
        ref: "tests/expertProfile.test.js, tests/earnings.test.js, tests/earnings.transactions.test.js, tests/payouts.test.js, tests/connect.test.js (BACK-13 cases)"
        status: pass
      - kind: other
        ref: "REDIS_URL=redis://localhost:6379 npm test (129 suites, 3004 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Build 6 and current Android stay usable against the new gate (expert home empty state, setup hub, 403 message on a write)"
    requirement: BACK-13
    verification: []
    human_judgment: true
    rationale: "Tests use mocks and no shipped client has run against this gate. The wave 3c smoke in plan 01-23 covers it, and nothing is deployed yet."

duration: 6 min
completed: 2026-11-09
one-liner: "BACK-13 expert gate split, parked on unshipped backend branch wave-3c; never deployed, wave dropped by user decision"
status: complete
---

> **Wave 3c dropped (user decision, 2026-11-08).** This plan's backend commits (`2b5f9ea`, `f14f9d0`, `bdc580f`) are on the local, unshipped branch `wave-3c`, not on `master`, and were never deployed. Everything below describes that branch, not production, where any `/expert/*` call still promotes. BACK-13 is not delivered. See `01-23-SUMMARY.md`.

# Phase 1 Plan 20: Expert Gate Split Summary

**`/expert/*` no longer promotes on first touch: client-only reads pass through, client-only writes get 403 `EXPERT_SETUP_REQUIRED`, and only a validated `PATCH /expert/profile/setup` makes a client an expert. Committed locally; not deployed.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-11-09T02:18:11Z
- **Completed:** 2026-11-09T02:24:38Z
- **Tasks:** 3 of 3
- **Files modified:** 9 (all in the backend repo)

## Accomplishments

- `ensureExpert.js` now has `provisionExpert` (today's steps a to d, unchanged), `resolveIsExpert`, `expertReadGate`, `expertWriteGate`, and a method-aware default export. Every existing mount gets the new behavior with no wiring change.
- Tokens without the expert role cost one primary-key read of `profiles.roles`, so a user promoted after their token was issued is not locked out. Tokens with the role still make no database read.
- The setup route now runs validate, then provision, then the controller, so a schema-invalid body returns 422 and promotes nothing.
- The tests that asserted the old promotion now assert the new contract, and the full suite is green.

## Task Commits

All in `/Users/LeonChen/Documents/ClickMe2026 Backend`, branch `master`, not pushed:

1. **Task 1: Split ensureExpert into provisioning, a read gate, a write gate and a method-aware default** - `2b5f9ea` (fix)
2. **Task 2: The setup route promotes, after validation** - `f14f9d0` (fix)
3. **Task 3: Flip the legacy convert-on-demand tests to the new contract** - `bdc580f` (test)

Each task saw its tests fail first, then committed test and code together, because the plan specifies one commit per task with named files. RED results: Task 1, 36 of 38 failed. Task 2, 2 of 16 failed. Task 3, the 5 legacy promotion cases failed against the new gate, plus 3 expertProfile cases that passed once the legacy case was replaced (an unconsumed `single` mock leaked from it).

## Verification

| Check | Result |
|-------|--------|
| `REDIS_URL=redis://localhost:6379 npm test` (plan's gate, after the last commit) | 129 suites, 3004 tests, all passed |
| `npm test -- --testPathIgnorePatterns=tests/services/redis.test.js` (run before the last comment tweak) | 128 suites, 2998 tests, all passed |
| `check-openapi-coverage` and `check-doc-coverage` | `OK: all 128 endpoints` on both |
| Acceptance greps for Tasks 1 to 3 | All pass |
| Backend `git status -sb` | `master...origin/main [ahead 3]`; nothing pushed |

No flaky failures occurred in these runs. This verifies the code against mocks only: no client and no real Supabase has run against the gate.

## Files Created/Modified

- `src/middleware/ensureExpert.js` - the gates and `provisionExpert`
- `src/routes/onboarding.js` - the only promoting route
- `tests/middleware/ensureExpert.test.js` - unit tests for every behavior line
- `tests/onboarding.test.js` - provisioning, 422 and fast-path cases on the setup route
- `tests/expertProfile.test.js`, `tests/earnings.test.js`, `tests/earnings.transactions.test.js`, `tests/payouts.test.js` - client-only reads
- `tests/connect.test.js` - client-only Connect onboarding returns 403

## Decisions Made

- `GET /expert/payouts/summary` for a client-only account returns the existing `400 NO_PAYOUT_METHOD`, not an empty 200. That is the response an un-onboarded expert gets today, which is what the plan asks for. Plan 01-21's table covers how each read responds.
- A stale token that lacks a roles array gets `['client', 'expert']`, the same value as provisioning step (d).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] The roles read throws through `dbError` instead of the raw Supabase error**
- **Found during:** Task 1
- **Issue:** `errorHandler` echoes `err.message` for an error with no status, so a raw Supabase error from the new read would expose schema details in a 500 (CR-03). The plan said only that it throws and reaches `next(err)`.
- **Fix:** `if (error) throw dbError(error);`, the convention at other DB call sites. It still returns a 500, never a 403.
- **Files modified:** `src/middleware/ensureExpert.js`, `tests/middleware/ensureExpert.test.js`
- **Verification:** tests assert `statusCode` 500, `INTERNAL_ERROR`, and that the raw message is absent
- **Committed in:** `2b5f9ea`

---

**Total deviations:** 1 auto-fixed (1 missing critical).
**Impact on plan:** Stays within the planned behavior. No scope change.

**Plan text note:** Task 3's acceptance line says all five files matched "Proves the account was converted" at baseline. Four did; `earnings.transactions.test.js` never had that comment. The grep passes and its promotion case was still rewritten.

## Issues Encountered

None blocking. Three items are logged in `deferred-items.md`:

- A schema-valid setup PATCH that the controller then refuses still promotes. `{}` promotes too, because every schema field is optional. This matches the plan's wording, but it is the one way the "valid PATCH only" rule is looser than it reads, so it may merit a user decision before 01-23.
- `scripts/uat-convert-expert.js`, three other UAT scripts, `docs/UAT-ACCOUNTS.md` and `docs/ios/EXPERT-EARNINGS-TRANSACTIONS.md` line 22 still assume conversion on first touch. Plan 01-22's sweep does not list them.
- `src/services/stripeEvents.js` line 44 cites an old line number in `ensureExpert.js`.

The other seven route headers still say convert-on-demand; plans 01-21 and 01-22 handle those as planned.

## User Setup Required

None. No migration or environment variable is needed. `profiles.roles` already exists and provisioning already writes it, so the gate needs no data change (D-09).

## Next Phase Readiness

- Ready for 01-21. `expertWriteGate` is exported for its explicit `GET /expert/tax-profile` mount; this plan leaves that route on the default gate.
- Wave 3c stays local until plan 01-23's handoff. BACK-06, BACK-07 and BACK-19 are untouched and stay Pending.
- The full suite is green here, and suites that script client-only callers must now include the gate's `profiles.roles` read.

## Self-Check: PASSED

- All 9 modified files exist and are in the three commits.
- `2b5f9ea`, `f14f9d0` and `bdc580f` are ancestors of backend HEAD.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-09*
