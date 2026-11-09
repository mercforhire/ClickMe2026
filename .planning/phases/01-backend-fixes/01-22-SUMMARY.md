---
phase: 01-backend-fixes
plan: 22
subsystem: api
tags: [openapi, docs, expert-gate, wave-3c, BACK-13, BACK-08]

requires:
  - phase: 01-backend-fixes
    provides: "01-20's expert gate and 01-21's final 17 / 20 / 1 route classification, including option-a for GET /expert/tax-profile"
provides:
  - "EXPERT_SETUP_REQUIRED in the OpenAPI ErrorCode enum and components.responses.ExpertSetupRequired, referenced from all 20 refused operations"
  - "docs/ios/EXPERT-SETUP-GATE.md: the gate contract for iOS SIGN-06 and the Android follow-up, including the BACK-08 outcome"
  - "No file under src/routes or src/middleware describes convert-on-demand as current behavior"
affects: [01-23 (wave 3c handoff, setup-promotion decision), Phase 5 SIGN-06, Android EXPERT_SETUP_REQUIRED follow-up]

# Measured in the BACKEND repo, where all code commits live:
# git -C "<backend>" rev-list --count e1eb483..8407402 = 3. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (38976 bytes). The iOS repo holds planning docs only.
actuals:
  tokens: 9744
  tasks: 2
  commits: 3
plan_head_before: e1eb4837fb9f3887b31cac0cfcbc8475939bbef0
plan_head_after: 8407402839945b1f30171687cc91d2c110db0847

tech-stack:
  added: []
  patterns:
    - "An operation with a second 403 keeps the shared $ref and overrides its description (OpenAPI 3.1 Reference Object), so the shared response stays single"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/EXPERT-SETUP-GATE.md"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/expert.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/expertTopics.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/bookingRequests.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/expertBooking.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/availability.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/analytics.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/routes/expertClients.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/middleware/ensureExpert.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/middleware/rejectSelfBooking.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/ios/EXPERT-EARNINGS-TRANSACTIONS.md"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/UAT-ACCOUNTS.md"

key-decisions:
  - "01-22 BACK-13: the two expert reschedule responses keep the shared 403 $ref and override its description, because their controllers also return 403 FORBIDDEN when the expert proposed the reschedule"
  - "01-22 BACK-13: the 403 entries on 15 pass-through reads were removed and the FORBIDDEN case on GET /expert/clients/{id} was dropped, because the gate never refuses those reads; ACCOUNT_SUSPENDED stays covered by the API-level note"

patterns-established: []

# BACK-08 and BACK-13 are also declared by 01-23, so they stay Pending until it has a SUMMARY.
requirements-completed: [BACK-13, BACK-08]

coverage:
  - id: D1
    description: "The OpenAPI contract has EXPERT_SETUP_REQUIRED, one shared 403 response, and a reference to it from all 20 refused operations"
    requirement: BACK-13
    verification:
      - kind: other
        ref: "npm run check-openapi-coverage (OK: all 128 endpoints); grep -c ExpertSetupRequired = 21; js-yaml parse lists the $ref on each of the 20 operations"
        status: pass
    human_judgment: false
  - id: D2
    description: "No comment under src/routes or src/middleware describes convert-on-demand, and the route changes are comment-only"
    requirement: BACK-13
    verification:
      - kind: other
        ref: "case-insensitive grep for convert-on-demand finds nothing in src/routes and src/middleware; comment-only diff check prints nothing; REDIS_URL=redis://localhost:6379 npm test (130 suites, 3099 tests, final run)"
        status: pass
    human_judgment: false
  - id: D3
    description: "docs/ios/EXPERT-SETUP-GATE.md is accurate and usable for iOS SIGN-06 and the Android follow-up, including what build 6 and Android do on the new 403"
    requirement: BACK-08
    verification: []
    human_judgment: true
    rationale: "Written from the code and checked against it, but its statements about shipped clients come from reading client code. No shipped client has run against this gate; the wave 3c smoke in plan 01-23 covers that."

duration: 8 min
completed: 2026-11-09
status: complete
---

# Phase 1 Plan 22: BACK-13 and BACK-08 Contract Docs Summary

**The OpenAPI contract now has `EXPERT_SETUP_REQUIRED` on all 20 refused operations, `docs/ios/EXPERT-SETUP-GATE.md` gives both clients the gate rules and the BACK-08 outcome, and no route or middleware comment still describes convert-on-demand. Committed locally; not deployed.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-11-09T02:34:51Z
- **Completed:** 2026-11-09T02:42:07Z
- **Tasks:** 2 of 2
- **Files modified:** 13 (all in the backend repo)

## Accomplishments

- OpenAPI has the new enum value, `components.responses.ExpertSetupRequired`, and a reference from the 19 writes and `GET /expert/tax-profile`. The setup, profile, Connect onboarding and tax-profile operations state their rule, and an API-level note sums up the gate.
- `docs/ios/EXPERT-SETUP-GATE.md` covers the rule, the 38-route table, the setup route, stale tokens, what each read returns, client guidance, build 6 and Android behavior, BACK-08 with option-a, and D-09.
- The spec says plainly that `{}` is a valid setup body and promotes, and that `{ "setup_completed": true }` on an incomplete record promotes and then returns 422. Behavior is unchanged; tightening it is a user decision at 01-23.
- The seven remaining route headers now describe the BACK-13 gate, in comments only.

## Task Commits

All in `/Users/LeonChen/Documents/ClickMe2026 Backend`, branch `master`, not pushed:

1. **Task 1: OpenAPI error enum, shared 403 response, and the expert-gate client spec** - `730a1f0` (docs)
2. **Task 2: Route-header comment sweep for the remaining seven route files** - `3f076e9` (docs)
3. **Orchestrator's small additions, separate because the plan fixes each task commit's file list** - `8407402` (docs)

## Verification

| Check | Result |
|-------|--------|
| `REDIS_URL=redis://localhost:6379 npm test`, run 1, with Task 2's comment edits uncommitted | **130 suites: 1 failed. 3099 tests: 40 failed** (see below) |
| Same, run 2, same code | 130 suites, 3099 tests, all passed |
| Same, run 3, at `8407402`, the final commit | 130 suites, 3099 tests, all passed |
| `check-openapi-coverage` and `check-doc-coverage` | `OK: all 128 endpoints` on both |
| `grep -c ExpertSetupRequired openapi/clickme-api.yaml` | 21 (one definition, 20 references; baseline 0) |
| `grep -c EXPERT_SETUP_REQUIRED openapi/clickme-api.yaml` | 7 (baseline 0) |
| Parsed spec | All 20 refused operations carry the `$ref`; 16 of the 17 reads have no 403, and `GET /expert/clients/{id}` keeps `NO_RELATIONSHIP` |
| Convert-on-demand sweep, case-sensitive per the plan and case-insensitive | No matches in `src/routes` or `src/middleware` |
| Task 2 comment-only diff check, run right after its commit | Prints nothing |
| Backend `git status -sb` | `master...origin/main [ahead 8]`; nothing pushed, nothing deployed |

**Run 1 failures.** All 40 were in `tests/clientBooking.test.js`, which is not on the known-flake list. Alone it passed 143 of 143, and runs 2 and 3 passed in full. The only uncommitted changes in run 1 were comments, so this plan did not cause it. Root cause not established; it is logged in `deferred-items.md`. The failing groups:

- `POST /api/v1/client/bookings/:id/cancel (BOOK-13)`, 7 tests: `BACK-14 cancel reason` (2), `BACK-12 cancel after the session end` (4), `D-17 regression` (1)
- `Reschedule accept/decline + enrichment (quick 260804-0sb) — client`, 18 tests: accept-reschedule, decline-reschedule, overwrite race, list and detail enrichment, the edge #3 cancel, and the propose-time notification
- `Phase 27.1 — accept-reschedule payment conversion`, 10 tests
- `261028-uph — RESCHEDULE_TOO_FAR_AHEAD + scheduled charge_due_at (client)`, 5 tests

This checks documents against the code and the test suite against mocks. No client has read these documents yet, and no client has run against the gate.

## Files Created/Modified

- `openapi/clickme-api.yaml` - enum value, shared response, 20 references, operation notes, stale 403s removed
- `docs/ios/EXPERT-SETUP-GATE.md` - the new client spec
- `src/routes/expert.js`, `expertTopics.js`, `bookingRequests.js`, `expertBooking.js`, `availability.js`, `analytics.js`, `expertClients.js` - header comments only
- `src/middleware/ensureExpert.js`, `src/middleware/rejectSelfBooking.js` - header comments only
- `docs/ios/EXPERT-EARNINGS-TRANSACTIONS.md`, `docs/UAT-ACCOUNTS.md` - corrected first-touch wording

## Decisions Made

- `POST /expert/bookings/:id/accept-reschedule` and `/decline-reschedule` keep the shared `$ref` and override its description, because a 403 key holds only one response and those controllers also return `403 FORBIDDEN` when the expert proposed the reschedule.
- In `analytics.js`, "analytics are expert-private" became "scoped to the caller's own id", because a client-only account can now read these routes and gets its own empty data.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed 403 entries the gate can no longer return from pass-through reads**
- **Found during:** Task 1
- **Issue:** 15 reads documented a 403 for a caller who is not an expert, and `GET /expert/clients/{id}` listed `FORBIDDEN` beside `NO_RELATIONSHIP`. The gate never refuses these reads, so the contract would have contradicted itself.
- **Fix:** removed those entries and the `FORBIDDEN` example. `ACCOUNT_SUSPENDED` is still covered by the API-level note, which says any authenticated endpoint may return it.
- **Files modified:** `openapi/clickme-api.yaml`
- **Verification:** parsed the spec and listed each read's responses
- **Committed in:** `730a1f0`

**2. [Rule 1 - Bug] `rejectSelfBooking.js` still described convert-on-demand**
- **Found during:** Task 2
- **Issue:** the plan's grep is case-sensitive, so "Convert-on-demand" at line 7 passes it while still breaking the plan's truth that no file under `src/middleware` describes this. The file is not in the plan's list.
- **Fix:** reworded the comment
- **Files modified:** `src/middleware/rejectSelfBooking.js`
- **Verification:** case-insensitive grep finds nothing
- **Committed in:** `8407402`

**3. [Orchestrator small additions] One-line corrections outside the plan's files**
- **Found during:** after Task 2
- **Fix:** `ensureExpert.js` header names the one read on the write gate. `EXPERT-EARNINGS-TRANSACTIONS.md` line 22 and `UAT-ACCOUNTS.md` state the BACK-13 behavior. The UAT scripts are unchanged and logged in `deferred-items.md`, with which ones would now fail.
- **Files modified:** `src/middleware/ensureExpert.js`, `docs/ios/EXPERT-EARNINGS-TRANSACTIONS.md`, `docs/UAT-ACCOUNTS.md`
- **Verification:** the final full-suite run; the source changes are comments
- **Committed in:** `8407402`

---

**Total deviations:** 3 (2 Rule 1 documentation fixes, 1 set of orchestrator-requested corrections).
**Impact on plan:** Documents and comments only; no behavior changed. The plan's two task commits kept their exact file lists, which is why there is a third commit.

## Issues Encountered

None blocking. Logged in `deferred-items.md`:

- **`clientBooking.test.js` flake:** new this plan, cause not established.
- **UAT scripts:** `scripts/uat-convert-expert.js` would fail after wave 3c deploys. `scripts/uat-topic-tags.js` and `scripts/uat-topic-owned-tags.js` should pass with their default accounts if those hold the expert role, which was not checked. `scripts/uat-seed-notifications.js` would not fail.
- **Stale comments:** `src/routes/index.js` and `analytics.controller.js` name a `roleCheck('expert')` that no expert route mounts.

## User Setup Required

None. No migration or environment variable is needed.

## Next Phase Readiness

- Ready for 01-23, the wave 3c handoff. The user has one open decision there: whether `{}` and an incomplete publish should keep promoting on the setup route.
- Before that smoke, `scripts/uat-convert-expert.js` should not be used to judge the gate, since it asserts the old behavior.
- Production stays at 3899d63. Wave 3c is now eight local commits: `2b5f9ea`, `f14f9d0`, `bdc580f`, `de662e9`, `e1eb483`, `730a1f0`, `3f076e9`, `8407402`. Nothing was pushed or deployed.

## Self-Check: PASSED

- `docs/ios/EXPERT-SETUP-GATE.md` and all 12 modified files exist in the backend repo.
- `730a1f0`, `3f076e9` and `8407402` are ancestors of backend HEAD.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-09*
