---
phase: "1"
slug: "backend-fixes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-07"
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> All code and tests for this phase live in the backend repo: `/Users/LeonChen/Documents/ClickMe2026 Backend`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30.4.2 + supertest 7.2.2 (mock-based: `supabaseAdmin`, Stripe, Redis and events are `jest.mock`ed; no real DB) |
| **Config file** | `jest.config.js` (`setupFiles: tests/setup.env.js`, `testMatch: **/tests/**/*.test.js`) |
| **Quick run command** | `cd "/Users/LeonChen/Documents/ClickMe2026 Backend" && npm test -- tests/<file>.test.js` |
| **Full suite command** | `cd "/Users/LeonChen/Documents/ClickMe2026 Backend" && npm test && npm run check-openapi-coverage && npm run check-doc-coverage` |
| **Estimated runtime** | ~11 seconds (full suite); 1–3 s per targeted file |

Baseline: 124/125 suites, 2664 tests pass. `tests/services/redis.test.js` fails only when `REDIS_URL` is unset (local `redis-server` is available).

---

## Sampling Rate

- **After every task commit:** Run the targeted test file(s) for that task
- **After every plan wave:** Run the full suite command (with `REDIS_URL` set) plus both coverage scripts
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

Filled in by the planner and executor as task IDs are assigned. Requirement → test mapping from RESEARCH.md:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | BACK-09 | — | Join rejected outside window / wrong status | unit + supertest | `npm test -- tests/call.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-12 | — | Client cancel after `end_time` rejected | supertest | `npm test -- tests/clientBooking.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-14 | — | N/A | supertest | `npm test -- tests/clientBooking.test.js tests/expertBooking.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-19 | — | Captured PI refunded in full on expert cancel | supertest + mocked stripe | `npm test -- tests/expertBooking.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-10/15 | — | Past start / bad duration 422; foreign replay still 409 | supertest | `npm test -- tests/booking.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-01/02 | — | Decline note only visible to booking's client | supertest | `npm test -- tests/bookingRequests.test.js tests/clientBooking.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-03/05 | — | N/A | supertest | `npm test -- tests/expertBooking.test.js tests/bookingRequests.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-04/11 | — | Oversized input 4xx, not 500 | supertest + schema | `npm test -- tests/expertProfile.test.js tests/expertTopics.test.js tests/onboarding.test.js tests/schemas/expertProfile.schema.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-06/07 | — | Deleted card cannot be charged via clone | supertest + mocked stripe | `npm test -- tests/paymentMethods.test.js tests/services/connectedPaymentMethodClone.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-13/08 | — | Client-only write to /expert/* → 403; no silent promotion | unit + supertest | `npm test -- tests/middleware/ensureExpert.test.js tests/expertRoutesGate.test.js` | ❌ W0 (gate test) | ⬜ pending |
| TBD | TBD | TBD | BACK-16 | — | 6th feedback in window → 429 | supertest | `npm test -- tests/chats.test.js tests/feedback.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-17 | — | N/A | unit | `npm test -- tests/push.test.js` | ✅ | ⬜ pending |
| TBD | TBD | TBD | BACK-18 | — | Reader can only reset own unread count | unit | `npm test -- tests/socket.messageRead.test.js` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | All | — | Existing response key sets unchanged (additive only) | contract | `npm test -- tests/contract.responseShapes.test.js` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/contract.responseShapes.test.js` — locks current key sets (D-12)
- [ ] `tests/socket.messageRead.test.js` + exported handler in `src/services/socket.js` — BACK-18
- [ ] `tests/expertRoutesGate.test.js` — table-driven over the `/expert/*` classification — BACK-13
- [ ] Shared supertest helper for an authenticated app with configurable `roles`
- Framework install: none needed (Jest already present)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Build 6 + Android still sign in, book, pay, join, chat | All | Live clients against deployed backend | After each deploy: sign in, free booking, paid booking, pay, join call, chat on both clients |
| Build 6 push tap navigation with `category` | BACK-17 | Real APNs delivery | Tap a confirmed/declined push on build 6, confirm it opens the booking |
| Rejoin call at end+30 | BACK-09 | Real Agora session | Join, leave, rejoin within reconnect window |
| Card add/delete + expert cancel with real test card | BACK-06/07/19 | Stripe test-mode end-to-end | Add/delete card, expert-cancel a captured booking, check Stripe dashboard |
| Client-only account opens expert home | BACK-13 | Client UX path | Sign in as client-only, open expert home, confirm no promotion and no crash |
| `cancellation_reason` migration applied before code deploy | BACK-14 | Production DB ops | `supabase db push`, verify column exists, then deploy |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
