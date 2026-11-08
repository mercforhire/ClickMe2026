---
phase: 01-backend-fixes
plan: 01
subsystem: api
tags: [zod, express, supertest, jest, openapi, contract-tests]

requires: []
provides:
  - "PATCH /expert/profile accepts professional_details.meeting_url null or '' and stores NULL (BACK-04)"
  - "tests/support/authMock.js: roles-configurable authenticate mock (authenticate, setAuthUser, resetAuthUser)"
  - "tests/contract.responseShapes.test.js: additive-only key-set lock for six endpoints that build 6 and Android decode (D-12)"
  - "iOS REQUIREMENTS.md defines BACK-19; BACK-16 drops notification mark-read (D-15, D-17)"
affects: [01-02 through 01-23 backend plans, all later phase-1 plans that add response fields or need role-switching auth in tests]

actuals:
  tokens: 7083
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Contract baselines as committed sorted literals with expect.arrayContaining (added keys pass, removed keys fail)"
    - "Table-keyed Proxy supabase mock instead of order-dependent mockReturnValueOnce chains"
    - "Hand-written zod refine message instead of z.union so RAW_ZOD_MESSAGE does not drop it from the top-level message"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/support/authMock.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/contract.responseShapes.test.js"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/schemas/expertProfile.schema.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expert.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/schemas/expertProfile.schema.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertProfile.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/booking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"
    - ".planning/REQUIREMENTS.md"
    - ".planning/ROADMAP.md"

key-decisions:
  - "meeting_url is built as z.string().max(500).refine(...).nullable().optional(), not a union, so the 422 keeps a readable top-level message"
  - "Controller stores meeting_url || null, so '' and null both clear the link and existing bookings keep their copied link"
  - "OpenAPI declares both type [string, null] (3.1 idiom) and nullable: true (plan acceptance criterion; the spec already uses nullable: true 7 times)"
  - "Contract suite also locks data/thread-item/agora_config sub-shapes, so it holds 8 BASELINE_ arrays for the 6 endpoints"

requirements-completed: [BACK-04]

coverage:
  - id: D1
    description: "An expert can clear meeting_url with null or '' (stored as NULL); invalid URLs still get 422 VALIDATION_ERROR with 'Meeting link must be a valid URL.'"
    requirement: BACK-04
    verification:
      - kind: unit
        ref: "tests/schemas/expertProfile.schema.test.js#expertProfilePatchSchema — meeting_url clearable (BACK-04)"
        status: pass
      - kind: integration
        ref: "tests/expertProfile.test.js#PATCH /api/v1/expert/profile — meeting_url (04-09)"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-12 mechanical lock on the response key sets of six endpoints plus the POST /bookings/confirm 201 keys"
    verification:
      - kind: integration
        ref: "tests/contract.responseShapes.test.js; tests/booking.test.js#confirms PI and inserts booking row (status=pending_approval)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Shared roles-configurable authenticate mock for later suites"
    verification:
      - kind: unit
        ref: "tests/contract.responseShapes.test.js#tests/support/authMock.js"
        status: pass
    human_judgment: false
  - id: D4
    description: "iOS REQUIREMENTS.md and ROADMAP.md reflect D-15 (no mark-read in BACK-16) and D-17 (BACK-19, Q2 settled in Phase 1, Q6 recorded as backend route)"
    verification:
      - kind: other
        ref: "grep -c BACK-19 .planning/REQUIREMENTS.md .planning/ROADMAP.md; ! grep -q 'can be marked read' ..."
        status: pass
    human_judgment: false

# plan_head_before / plan_head_after are the iOS repo (planning docs). Backend commits are listed below.
plan_head_before: 8039ae0dd000b5794ed9ae10eda9d7336584def0
plan_head_after: a6e93d71411e9c83940eaa075d0e92a0c0c3bb27
backend_head_before: 2ec82af234cf03a1aef9a1b28eb784765217472d
backend_head_after: 017874ab1a4bb9b5f94b1564369f199e34770367
commits: 3

duration: ~12min (approximate; start time was not captured, derived from STATE.md timestamp)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 01: BACK-04 tracer, D-12 contract lock and D-15/D-17 doc sync Summary

**Experts can now clear their Skype/Zoom link (null or "" stored as NULL) through the real Express app, and a new jest suite fails if any key that build 6 or Android decode disappears from six response shapes.**

## Performance

- **Duration:** ~12 min (approximate)
- **Completed:** 2026-11-08
- **Tasks:** 3 of 3
- **Files:** 8 backend, 2 iOS planning

## Accomplishments

- **Tracer (BACK-04):** schema, controller, OpenAPI and supertest all proven in one commit. After the commit the tracer `<verify>` was re-run end to end (28 tests pass, `OK: all 128 endpoints present in spec`) before expanding.
- **Wave 0 (D-12):** `tests/contract.responseShapes.test.js` locks GET /client/bookings/:id, GET /chats (data + thread item), POST /bookings/:id/join (data + agora_config), GET /expert/profile, GET /expert/bookings?type=upcoming and GET /me/payment-methods. `tests/booking.test.js` now asserts `booking_id`, `status`, `message`, `estimated_confirmation_time` on the POST /bookings/confirm 201.
- **authMock:** `tests/support/authMock.js` exports `authenticate`, `setAuthUser`, `resetAuthUser`; usage is documented in its header and exercised in the contract suite.
- **Docs:** BACK-19 added and mapped to Phase 1, BACK-16 no longer includes mark-read, coverage 103/103, ROADMAP criteria 2 and 4 and the Q2 row updated.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `df7fb18` | fix(ios-p1/BACK-04): allow experts to clear meeting_url (null or "") |
| backend (master) | `017874a` | test(ios-p1/wave0): lock build-6/Android response key sets (D-12) |
| iOS (main) | `a6e93d7` | docs(01): sync requirements and roadmap with D-15/D-17 |

Backend `git status -sb` shows `master...origin/main [ahead 2]`. Nothing was pushed or deployed.

## Deliberate-break check (D-12)

In `src/controllers/clientBooking.controller.js` (`getDetail`) the response key `client_notes` was temporarily renamed to `client_notes_RENAMED`. `tests/contract.responseShapes.test.js` then failed (1 failed, 6 passed): the `GET /client/bookings/:id` case reported the received key list without `client_notes` against the `ArrayContaining` baseline. The file was restored with `git checkout -- <file>` and the suite returned to 7/7 passing. The break was never staged or committed.

## Verification

- Targeted: `tests/expertProfile.test.js` + `tests/schemas/expertProfile.schema.test.js` 28/28; `tests/contract.responseShapes.test.js` + `tests/booking.test.js` 131/131 (7 tests in the contract suite).
- Full gate: `REDIS_URL=redis://localhost:6379 npm test` 126/126 suites, 2685 tests, 0 failed (baseline 125/2670). `check-openapi-coverage` and `check-doc-coverage` print `OK: all 128 endpoints`.
- Acceptance criteria re-run: nullable present in OpenAPI at the PATCH request; `grep -c 2ec82af` on the contract file is 2; authMock exports verified with `node -e`; iOS greps for BACK-19 (2 in REQUIREMENTS, 3 in ROADMAP), `103 total`, `BACK-18, BACK-19` and `target_role` pass; `! grep "can be marked read"` passes; each commit lists exactly its planned files.

## Deviations from Plan

### Auto-fixed Issues

None needed for correctness. Minor notes:

**1. [Interpretation] Contract file holds 8 BASELINE_ arrays, not 6**
- **Issue:** The plan says "six BASELINE_ arrays" and also asks for key sets of both `data` and one item for GET /chats, and both `data` and `agora_config` for join.
- **Fix:** One array per locked shape (8 total), all asserted with `expect.arrayContaining`. The six endpoints are all covered. The plan's artifact table already allows names to be adjusted.

**2. [Interpretation] OpenAPI uses both `type: ["string","null"]` and `nullable: true`**
- **Issue:** The spec is OpenAPI 3.1.0, where `nullable` is not a standard keyword, but the plan's acceptance criterion greps for `nullable: true` and the file already uses it 7 times.
- **Fix:** Declared both; coverage scripts pass.

**Baseline provenance:** baselines were captured at backend commit `df7fb18` (2 files differ from 2ec82af: the PATCH-only schema and controller change, which does not touch any locked GET/POST shape). The controllers for all six locked endpoints are byte-identical to 2ec82af, so the recorded baselines equal the 2ec82af key sets.

**Total deviations:** 0 auto-fixed, 2 interpretation notes. **Impact:** none on scope or behavior.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-01 is mitigated: every non-empty meeting_url is still validated as a URL (max 500); only null and "" bypass validation and both are stored as NULL. Whitespace-only input is rejected (tested). T-01-02: fixtures use synthetic UUIDs and names only. T-01-SC: no packages installed or upgraded.

## Notes for later plans

- The unresolved probe assumptions held: whitespace-only is rejected with 422; clearing the link does not touch meeting_url already copied onto bookings; the existing 422 MEETING_LINK_UNAVAILABLE guard handles new skype_zoom bookings after clearing (not changed here).
- Later plans that add response fields must only ADD keys; if a plan must change a baselined key, it needs an explicit decision, not a baseline edit.
- To use the shared mock: `jest.mock('../src/middleware/authenticate', () => require('./support/authMock').authenticate)` then `setAuthUser({...})` per test.
- Pre-existing untracked files in the backend repo (`assets/app-store-screenshots/`, `scripts/uat-seed-profile.js`, `.planning/` files) were left untouched.

## Next

Ready for plan 01-02 (BACK-17 push routing fields).

## Self-Check: PASSED

- FOUND: backend `tests/support/authMock.js`, `tests/contract.responseShapes.test.js`
- FOUND commits: `df7fb18`, `017874a` (backend master), `a6e93d7` (iOS main)
