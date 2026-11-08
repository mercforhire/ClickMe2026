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

Filled in by the planner (2026-11-07); the executor updates Status. Requirement → test mapping from RESEARCH.md.

Commands below are shortened; run each as `npm --prefix "/Users/LeonChen/Documents/ClickMe2026 Backend" test -- <files>`. Plans run sequentially (wave = plan number) because every plan commits to the one shared backend checkout and nearly all touch openapi/clickme-api.yaml.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01-01 | 1 | BACK-04 | T-01-01 | Non-empty meeting_url still URL-validated | supertest + schema (tracer) | `tests/expertProfile.test.js tests/schemas/expertProfile.schema.test.js` | ✅ | ⬜ pending |
| 01-01-T2 | 01-01 | 1 | All (D-12) | T-01-02 | Existing response key sets unchanged (additive only) | contract | `tests/contract.responseShapes.test.js tests/booking.test.js` | ❌ W0 (created here) | ⬜ pending |
| 01-01-T3 | 01-01 | 1 | BACK-16, BACK-19 (docs) | — | N/A | grep (iOS repo) | `grep -c "BACK-19" .planning/REQUIREMENTS.md .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 01-02-T1 | 01-02 | 2 | BACK-17 | T-01-03 | Free text never in FCM data; in_app_meta row-only | unit | `tests/push.test.js` | ✅ | ⬜ pending |
| 01-02-T2 | 01-02 | 2 | BACK-17 | T-01-04 | N/A | unit | `tests/events.test.js tests/push.test.js` | ✅ | ⬜ pending |
| 01-03-T1..T2 | 01-03 | 3 | BACK-17 | T-01-46 | No new push recipient introduced | unit | `tests/chats.test.js tests/reviews.test.js tests/webhooks.test.js tests/reminderNotification.test.js` | ✅ | ⬜ pending |
| 01-04-T1..T2 | 01-04 | 4 | BACK-17 | T-01-05, T-01-47 | Account pushes add only the enum role; no token or password in push data | unit | `tests/noShowNotification.test.js tests/reviewNudgeNotification.test.js tests/cron/longLeadChargeSweep.test.js tests/account.test.js tests/userPassword.test.js` | ✅ | ⬜ pending |
| 01-05-T1 | 01-05 | 5 | BACK-03 | T-01-06 | has_review only for the expert's own bookings | supertest | `tests/expertBooking.test.js tests/contract.responseShapes.test.js` | ✅ | ⬜ pending |
| 01-05-T2..T3 | 01-05 | 5 | BACK-05 | T-01-07 | N/A | unit + supertest | `tests/utils/pricing.test.js tests/expertBooking.test.js tests/bookingRequests.test.js` | ✅ | ⬜ pending |
| 01-06-T1..T2 | 01-06 | 6 | BACK-02 | T-01-08, T-01-09 | Decline note only on declined bookings; never in FCM data | supertest + unit | `tests/clientBooking.test.js tests/events.test.js tests/bookingRequests.test.js` | ✅ | ⬜ pending |
| 01-07-T1 | 01-07 | 7 | BACK-10 | T-01-11 | Rejected request holds nothing | supertest | `tests/booking.test.js` | ✅ | ⬜ pending |
| 01-07-T2..T3 | 01-07 | 7 | BACK-11 | T-01-12 | Oversized input 422, not 500 | supertest + schema | `tests/expertTopics.test.js tests/onboarding.test.js tests/schemas/expertProfile.schema.test.js` | ✅ | ⬜ pending |
| 01-08-T1..T2 | 01-08 | 8 | BACK-16 | T-01-13, T-01-14 | 6th feedback in window → 429 | supertest | `tests/chats.test.js tests/feedback.test.js` | ✅ | ⬜ pending |
| 01-09-T1..T2 | 01-09 | 9 | BACK-01 | T-01-15, T-01-16 | Blocked/moderated recipient skipped | unit + supertest | `tests/services/chatMessages.test.js tests/chats.test.js tests/bookingRequests.test.js` | ❌ W0 (chatMessages test created here) | ⬜ pending |
| 01-10-T1..T3 | 01-10 | 10 | BACK-14 (migration) + wave-1 deploy | T-01-18, T-01-19 | Column applied before dependent code | grep + full gate + manual | full gate; column check in checkpoint | ✅ | ⬜ pending |
| 01-11-T1..T3 | 01-11 | 11 | BACK-09 | T-01-20, T-01-21, T-01-22 | Join rejected outside window / wrong status | unit + supertest | `tests/call.test.js tests/clientBooking.test.js tests/expertBooking.test.js tests/expirePastSessions.test.js` | ✅ | ⬜ pending |
| 01-12-T1 | 01-12 | 12 | BACK-14 | T-01-24 | Reason only to the two parties; never in push data | supertest | `tests/clientBooking.test.js tests/expertBooking.test.js` | ✅ | ⬜ pending |
| 01-12-T2 | 01-12 | 12 | BACK-12 | T-01-23 | Client cancel after end_time rejected, no Stripe call | supertest | `tests/clientBooking.test.js` | ✅ | ⬜ pending |
| 01-13-T1..T2 | 01-13 | 13 | BACK-15 | T-01-26, T-01-27, T-01-28 | Replay only for the owner; no second booking or charge | supertest | `tests/booking.test.js tests/services/stripePaymentsContract.test.js` | ✅ | ⬜ pending |
| 01-14-T1..T3 | 01-14 | 14 | BACK-18 | T-01-29, T-01-30 | Reader can only reset own unread count | unit + supertest | `tests/services/unreadCounts.test.js tests/services/chatMessages.test.js tests/socket.messageRead.test.js tests/chats.test.js` | ❌ W0 (socket and unread tests created here) | ⬜ pending |
| 01-15-T1..T2 | 01-15 | 15 | wave-2 deploy | T-01-31 | N/A | full gate + manual | full gate | ✅ | ⬜ pending |
| 01-16-T1..T2 | 01-16 | 16 | BACK-06, BACK-07 | T-01-32, T-01-33, T-01-35 | Deleted card cannot be charged via clone; in-use card 409; money-path edges pinned by tests | supertest + mocked stripe | `tests/stripe.paymentMethods.test.js tests/services/connectedPaymentMethodClone.test.js tests/paymentMethods.test.js` | ✅ | ⬜ pending |
| 01-17-T1..T2 | 01-17 | 17 | wave-3a deploy | T-01-36 | N/A | full gate + manual (real card) | full gate | ✅ | ⬜ pending |
| 01-18-T1..T2 | 01-18 | 18 | BACK-19 | T-01-37, T-01-38 | Captured PI refunded in full on expert cancel; no double refund | supertest + mocked stripe | `tests/expertBooking.test.js tests/clientBooking.test.js tests/refund.test.js` | ✅ | ⬜ pending |
| 01-19-T1..T2 | 01-19 | 19 | wave-3b deploy | T-01-39 | N/A | full gate + manual (real card) | full gate | ✅ | ⬜ pending |
| 01-20-T1..T3 | 01-20 | 20 | BACK-13 | T-01-40, T-01-41 | Client-only write to /expert/* → 403; no silent promotion; stale JWT allowed | unit + supertest | `tests/middleware/ensureExpert.test.js tests/onboarding.test.js tests/expertProfile.test.js tests/earnings.test.js tests/earnings.transactions.test.js tests/payouts.test.js tests/connect.test.js` | ✅ | ⬜ pending |
| 01-21-T1 | 01-21 | 21 | BACK-08, BACK-13 | T-01-48 | No Connect account for a non-expert; 38-route classification pinned | unit + supertest | `tests/expertRoutesGate.test.js tests/connect.test.js` | ❌ W0 (gate test created here) | ⬜ pending |
| 01-21-T2 | 01-21 | 21 | BACK-08 | — | N/A (user decision on GET /expert/tax-profile, D-08) | checkpoint:decision (blocking-human) | n/a | — | ⬜ pending |
| 01-21-T3 | 01-21 | 21 | BACK-08 | T-01-49 | No TIN stored for a non-expert; GET per the user's option | supertest | `tests/expertTaxProfile.test.js tests/expertRoutesGate.test.js` | ✅ | ⬜ pending |
| 01-22-T1..T2 | 01-22 | 22 | BACK-13, BACK-08 (contract docs) | T-01-50 | N/A | coverage scripts + grep + full gate | full gate; convert-on-demand sweep | ✅ | ⬜ pending |
| 01-23-T1..T2 | 01-23 | 23 | wave-3c deploy + BACK-08 seam smoke | T-01-44, T-01-45 | N/A | full gate + manual | full gate | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/contract.responseShapes.test.js` — locks current key sets (D-12) — plan 01-01 Task 2
- [ ] `tests/socket.messageRead.test.js` + exported handler in `src/services/socket.js` — BACK-18 — plan 01-14 Task 2
- [ ] `tests/expertRoutesGate.test.js` — table-driven over the `/expert/*` classification — BACK-13/BACK-08 — plan 01-21 Task 1
- [ ] Shared supertest helper for an authenticated app with configurable `roles` — `tests/support/authMock.js`, plan 01-01 Task 2
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
| Client-only account reaches no tax-ID prompt | BACK-08 | Real Stripe Connect page and shipped client screens | Plan 01-23 steps B7-B8: Payouts set-up refused with no Stripe page and no payout_accounts row; Tax & Payout Info per the plan 01-21 option; Android cannot reach the expert shell without setup |
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
