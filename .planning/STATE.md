---
gsd_state_version: "1.0"
current_phase: 01
current_phase_name: Backend Fixes
status: executing
stopped_at: Completed 01-10-PLAN.md
last_updated: "2026-11-08T17:25:52.557Z"
last_activity: 2026-11-08
last_activity_desc: Phase 01 execution started
state_head: 949bb0cffbc8901cd3cf86aea08bc707e1dcc88b
progress:
  total_phases: 8
  completed_phases: 0
  total_plans: 23
  completed_plans: 10
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-11-07)

**Core value:** Live iOS users can book, pay for, join and finish a session without the app cutting them off, charging them wrongly, or silently dropping their actions.
**Current focus:** Phase 01 — Backend Fixes

## Current Position

Phase: 01 (Backend Fixes) — EXECUTING
Plan: 11 of 23
Status: Ready to execute
Last activity: 2026-11-08 — Phase 01 execution started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P01 | 12 min | 3 tasks | 10 files |
| Phase 01 P02 | 3 min | 2 tasks | 7 files |
| Phase 01 P03 | 2 min | 2 tasks | 8 files |
| Phase 01 P04 | 6min | 2 tasks | 9 files |
| Phase 01 P05 | 12 min | 3 tasks | 7 files |
| Phase 01 P06 | 3 min | 2 tasks | 7 files |
| Phase 01 P07 | n/a | 3 tasks | 9 files |
| Phase 01 P08 | 15 min | 2 tasks | 8 files |
| Phase 01 P09 | 25 min | 2 tasks | 7 files |
| Phase 01 P10 | ~11h 15m wall clock (user wait) | 3 tasks | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in the PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: Horizontal layers (user choice): backend, then shared iOS plumbing, then screen fixes, then one release
- [Roadmap]: CALL-01 is planned first in Phase 2 and BOOK-06 first in Phase 3 (the two critical items)
- [Init]: One iOS release at the end, with no hotfix build in between (user, 2026-11-07)
- [Init]: Backend changes stay compatible with the current Android build (launch ~2026-12-13)
- [Init]: Open questions Q1–Q8 are settled in each affected phase's discuss step (Q6 in Phase 1, Q3 in Phase 2, Q2 in Phase 3, Q4 in Phase 4, Q1/Q5/Q7 in Phase 5, Q8 in Phase 7)
- [Phase 01]: [01-01] meeting_url clearable via refine (not union) so 422 keeps a hand-written message; controller stores null for '' and null
- [Phase 01]: [01-01] D-12 contract baselines are committed literals checked with arrayContaining; later plans may only add keys
- [Phase 01]: BACK-17: push routing keys (category, sub_category, target_role) go to every platform; platform check only gates the Android presentation block. Disallowed target_role is dropped; explicit target_role wins over the is_expert_only default; in_app_meta reaches notifications.meta_data only.
- [Phase 01]: 01-03: chat push uses targetRoleFor(thread, recipientId); review push uses literal 'expert'; refund webhook push uses targetRoleFor(booking, booking.client_id) (the plan's 'payment-action-required' push is the refund-issued push)
- [Phase 01]: [01-04] Account pushes take target_role from targetRoleForAccount(req.user.roles); stale JWT yields 'client', acceptable since the security screen exists in both modes
- [Phase 01]: [01-05] A reviews read error fails the expert booking read via dbError instead of reporting has_review false; the reviews read runs after the payout fallback so existing mock order holds
- [Phase 01]: [01-05] Expert fee label uses currencySymbolFor over MIN_PRICE_CURRENCY_SYMBOLS (CA$12.50 / session); no new currency util; CHF symbol has no trailing space (unchanged)
- [Phase 01]: 01-06 BACK-02: decline_reason_code and decline_reason_text are exposed on GET /client/bookings/:id only when status is declined (column is shared with reschedule declines); free text reaches clients via in_app_meta and chat event_data, never the FCM data map
- [Phase 01]: 01-07: BACK-10 rejects start <= now and duration != topic duration_mins in createRequest before any Redis hold; topic length wins over requested length
- [Phase 01]: 01-07: BACK-11 bounds are INTEGER max (2147483647) for topic price and 50 for languages and expertise_tags (Open Q9 assumption, spot-check in 01-10)
- [Phase 01]: 01-08 BACK-16: GET /chats lists empty threads ordered last_msg_at desc nulls last then created_at desc; POST /feedback/submit limited to 5 per 15 min per user via in-memory feedbackLimiter (valid only while numReplicas is 1); hard-mocked rateLimiter modules in connect/payouts tests need each new limiter added
- [Phase 01]: BACK-01: postUserMessage (src/services/chatMessages.js) is the single chat message path; callers own block/moderation checks (send rejects, accept silently skips)
- [Phase 01]: BACK-01: accept message uses client_msg_id booking-accept:<booking id> for idempotency and fails open on a moderation lookup error, like chats.send
- [Phase 01]: 01-10: BACK-14 column bookings.cancellation_reason applied to production a full deploy wave before the code that writes it (Open Q8 default)
- [Phase 01]: 01-10: wave 1 deployed, production moved from 2ec82af to a92acba; smoke checklist user-reported all passed on build 6 and Android, with no per-step notes

### Pending Todos

Android follow-ups from Phase 1 (logged, not built):

- Decline note display on Android booking detail (BACK-02)
- Switch `displayUnread` to the server count once BACK-18 is live (BACK-18)
- Expert-cancel copy promises a full refund (D-17/BACK-19)
- Map PAYMENT_METHOD_IN_USE on card delete (BACK-07)
- Map EXPERT_SETUP_REQUIRED and route to the setup hub (BACK-13)
- Map SESSION_ALREADY_ENDED on client cancel (BACK-12)

### Blockers/Concerns

- [Phase 1]: Q6 must be settled before BACK-17 is planned. It decides whether PUSH-01 (Phase 2) uses a backend `category` or a wider iOS parser.
- [Phase 1]: BACK-09 (tighter `/join` window plus a status check) can conflict with CALL-01 overtime to end+60, because the cron completes bookings at end+15. Settle the rejoin rule in discuss.
- [Phase 1]: The backend is live production and also serves App Store build 6, so every change must be safe for build 6 and current Android. BACK-13 (expert promotion) carries the most risk.
- [Phase 3]: If Q2 changes the backend refund policy, that is backend work outside Phase 1. It can be pulled forward into Phase 1's discuss step.
- [Phase 4]: Every environment points at the production backend and live Stripe, so payment UAT places real holds.
- [Phase 7]: CHAT-08 needs a device re-test before planning (Q8).

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| *(none)* | | | | |

## Session Continuity

Last session: 2026-11-08T17:25:52.531Z
Stopped at: Completed 01-10-PLAN.md
Resume file: None
