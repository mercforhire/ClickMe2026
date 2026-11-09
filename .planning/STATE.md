---
gsd_state_version: "1.0"
current_phase: 01
current_phase_name: Backend Fixes
status: executing
stopped_at: "01-23 Task 2 checkpoint: wave 3c ready to push, awaiting user decision on setup promotion, push and smoke"
last_updated: "2026-11-09T02:55:16.038Z"
last_activity: 2026-11-08
last_activity_desc: Phase 01 execution started
state_head: 958ab2ebccc449ad1a59f2b456375ccd6ef8034e
progress:
  total_phases: 8
  completed_phases: 0
  total_plans: 23
  completed_plans: 23
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-11-07)

**Core value:** Live iOS users can book, pay for, join and finish a session without the app cutting them off, charging them wrongly, or silently dropping their actions.
**Current focus:** Phase 01 — Backend Fixes

## Current Position

Phase: 01 (Backend Fixes) — EXECUTING
Plan: 23 of 23
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
| Phase 01 P11 | 7 min | 3 tasks | 10 files |
| Phase 01 P12 | 4 min | 2 tasks | 6 files |
| Phase 01 P13 | 7 min | 2 tasks | 4 files |
| Phase 01 P14 | 5 min | 3 tasks | 10 files |
| Phase 01 P15 | ~6h 20m wall clock (user wait) | 2 tasks | 5 files |
| Phase 01 P16 | 6 min | 2 tasks | 8 files |
| Phase 01 P17 | ~30 min wall clock (user wait) | 1 of 2 (Task 2 deployed, smoke not run) tasks | 1 files |
| Phase 01 P18 | 5 min | 2 tasks | 5 files |
| Phase 01 P19 | ~1h 10m wall clock (user wait) | 1 of 2 (Task 2 deployed, smoke not run) tasks | 1 files |
| Phase 01 P20 | 6 min | 3 tasks | 9 files |
| Phase 01 P21 | 5 min | 2 tasks | 8 files |
| Phase 01 P22 | 8 min | 2 tasks | 13 files |

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
- [Phase 01]: 01-11 BACK-09: /join refusals reuse 403 SESSION_NOT_ACTIVE with status-specific messages because both shipped clients decode the code and show the server message
- [Phase 01]: 01-11 BACK-09: can_join reads the caller's own joined_at through evaluateJoinWindow, the same function as the gate; the column is selected for the flag only and never returned
- [Phase 01]: 01-11 BACK-09: an overtime /end after the cron changes end_reason from auto_completed to completed; nothing in src reads end_reason, so counting cron closures from it would be unreliable
- [Phase 01]: 01-12 BACK-12: client cancel at or after end_time returns 409 SESSION_ALREADY_ENDED, after the status guard and for every cancellable status; a pending_approval hold past end_time now stays until expireBookings voids it at expires_at (up to about 12h after the request)
- [Phase 01]: 01-12 BACK-14: the trimmed cancel reason is written to cancellation_reason in the atomic cancel UPDATE and returned only by GET /client/bookings/:id (cancelled only) and GET /expert/bookings/:id/summary; never in dispatch, push or chat event_data
- [Phase 01]: 01-13 BACK-15: confirm retries replay 201 through an ownership-checked lookup on payment_intent_id, with no new column or stored response; only pending_approval, confirmed, pending_reschedule and in_progress replay, with the booking's current status; a foreign or finished booking keeps the generic 409 with no booking id
- [Phase 01]: 01-13 BACK-15: on the 23P01 path the replay lookup runs before the slot keys are released; a lookup error returns 500 and leaves the keys to their 900s TTL because they may be the winner's
- [Phase 01]: 01-13 BACK-15: payment-intent returns 409 DUPLICATE_BOOKING with detail.booking_id only for the caller's own active booking with the same expert, topic and start; a different topic stays SLOT_UNAVAILABLE; a duration_minutes that differs from the topic's duration_mins returns 422 before any hold or Stripe call
- [Phase 01]: 01-14 BACK-18: unread_count is recomputed from messages.status on send (recipient), message.read (reader) and GET /chats/:id/messages page 1 (caller), with no increment RPC and no migration; simultaneous sends can undercount by one until the next event
- [Phase 01]: 01-14 BACK-18: opening a thread recomputes the caller's counter and marks nothing read (Open Q6 default); partner messages a client never emits message.read for stay in the count, including older pages; Phase 7 CHAT-07/08 may revisit
- [Phase 01]: 01-14 BACK-18: countUnreadFor throws when a query returns no count, so a missing count is never written to the counter as 0
- [Phase 01]: 01-15: wave 2 deployed, production moved from a92acba to 7fdc7c4, then to ddfe5bf (test-only commit outside the plan, same runtime code); smoke checklist user-reported all passed, with no per-step notes
- [Phase 01]: 01-15: smoke checklist assigns each step to a specific booking, because a paid booking whose call connected, or whose end time has passed, can no longer be released by a client cancel and is captured at end+15
- [Phase 01]: 01-15: Android unread smoke step adds a force-quit, because the Android badge is max(server, session-local) and would otherwise pass without the server count
- [Phase 01]: 01-16 BACK-07: DELETE returns 409 PAYMENT_METHOD_IN_USE for a card referenced by the caller's booking in pending_approval, confirmed, pending_reschedule or in_progress, with no time filter; otherwise clones are evicted through evictClonesForPlatformPaymentMethod before the platform detach
- [Phase 01]: 01-16 BACK-07: only resource_missing and payment_method_unexpected_state count as a clone already gone; any other Stripe error returns 502 and keeps the card, so an unreachable connected account could make a card undeletable (logged in deferred-items.md)
- [Phase 01]: 01-16 BACK-06: a lone card with no default is promoted on GET and after a delete; failures to list or promote after the detach do not fail the DELETE, because the card is already gone and a retry would 404
- [Phase 01]: 01-16: D-13 local Stripe test-mode run dropped by user decision (Open Q7); Stripe behavior is proven only against mocks until the 01-17 real-card smoke
- [Phase 01]: 01-17: wave 3a deployed by the user, production moved from ddfe5bf to d356fdc; the real-card smoke was NOT RUN by user decision (2026-11-08), so BACK-06 and BACK-07 stay Pending and the real clone detach has never run against real Stripe
- [Phase 01]: 01-17: the smoke checklist reads the clone id from connected_pm_clones before the card is removed, because eviction deletes the only record of it and a count of 0 afterwards proves nothing if no clone existed
- [Phase 01]: 01-17: the checklist's paid booking starts 2 to 5 days out and is never joined or rescheduled, because a connected call or client no-show is captured at end+15 and a reschedule can convert it to a T-24h charge
- [Phase 01]: 01-17: the checklist proves a hold released from the PaymentIntent state, not the app, because client cancel returns 200 even when the Stripe void failed (it sets refund_failed)
- [Phase 01]: 01-18 BACK-19: POST /expert/bookings/:id/cancel refunds amount_paid_minor_units in full on a captured PaymentIntent at any time and moves captured to refunded; a zero amount still makes no Stripe call; client cancel keeps the 24-hour rule; committed locally at 3899d63, not deployed, mocked Stripe only
- [Phase 01]: 01-18 BACK-19: a retrievePI failure on a non-pending booking still falls back to the captured branch, so that case now attempts a full refund at any time; a rejected refund flags refund_failed and the sweep's cancelPI then applies to an uncaptured hold
- [Phase 01]: 01-19: wave 3b deployed by the user, production moved from d356fdc to 3899d63; the production smoke was NOT RUN by user decision (2026-11-08), so BACK-19 stays Pending. Wave 3a and wave 3b are both live with no real-Stripe check; d356fdc is the rollback target for this wave and contains unverified card code
- [Phase 01]: 01-19: user chose option A on the refund retry (2026-11-08): push now, fix next. Failed refunds are not retried as refunds until a separate plan and deploy, before Phase 4 payment UAT; that plan still needs creating
- [Phase 01]: 01-19: read-only queries QA and QB were user-run and reported empty after the push; their order relative to the push is not known. An empty QA is strong evidence, not proof, since an old row's payment_status can be stale
- [Phase 01]: 01-20 BACK-13: the default export of ensureExpert is the method-aware gate (GET/HEAD/OPTIONS read gate, other methods write gate), so every mount changes with no wiring change; only PATCH /expert/profile/setup is rewired, to validate then provisionExpert. Committed locally at bdc580f, not deployed, mocks only
- [Phase 01]: 01-20 BACK-13: a token without expert costs one primary-key read of profiles.roles; a failed read is a safe 500 through dbError, never a 403; provisionExpert error paths are unchanged
- [Phase 01]: 01-20 BACK-13: a schema-valid setup PATCH promotes even when it is {} or when the controller then returns 422 for an incomplete publish; matches the plan, logged in deferred-items.md as a possible user decision before 01-23
- [Phase 01]: 01-21-D1 BACK-08: GET /expert/tax-profile refuses a client-only account with 403 EXPERT_SETUP_REQUIRED by mounting expertWriteGate; option-a, user decision of 2026-11-07, a D-08 amendment for this one route; final classification 17 reads, 20 refused, 1 setup. Committed locally at e1eb483, not deployed, mocks only
- [Phase 01]: 01-21 BACK-08: postOnboard refuses a caller whose req.user.roles lacks expert (missing and empty included) before any payout_accounts or Stripe call; getConnectStatus and postRefreshLink need no such check because only postOnboard creates a payout_accounts row
- [Phase 01]: 01-22 BACK-13: the two expert reschedule responses keep the shared 403 $ref and override its description, because their controllers also return 403 FORBIDDEN when the expert proposed the reschedule
- [Phase 01]: 01-22 BACK-13: the 403 entries on 15 pass-through reads were removed and FORBIDDEN was dropped from GET /expert/clients/{id}, because the gate never refuses those reads; ACCOUNT_SUSPENDED stays covered by the API-level note

### Pending Todos

Android follow-ups from Phase 1 (logged, not built):

- Decline note display on Android booking detail (BACK-02)
- Switch `displayUnread` to the server count once BACK-18 is live (BACK-18)
- Expert-cancel copy promises a full refund (D-17/BACK-19)
- Map PAYMENT_METHOD_IN_USE on card delete (BACK-07)
- Map EXPERT_SETUP_REQUIRED and route to the setup hub (BACK-13)
- Map SESSION_ALREADY_ENDED on client cancel (BACK-12)
- Route payment-intent 409 DUPLICATE_BOOKING to detail.booking_id (BACK-15)

### Blockers/Concerns

- [Phase 1]: Q6 must be settled before BACK-17 is planned. It decides whether PUSH-01 (Phase 2) uses a backend `category` or a wider iOS parser.
- [Phase 1]: BACK-09 (tighter `/join` window plus a status check) can conflict with CALL-01 overtime to end+60, because the cron completes bookings at end+15. Settle the rejoin rule in discuss.
- [Phase 1]: The backend is live production and also serves App Store build 6, so every change must be safe for build 6 and current Android. BACK-13 (expert promotion) carries the most risk.
- [Phase 3]: If Q2 changes the backend refund policy, that is backend work outside Phase 1. It can be pulled forward into Phase 1's discuss step.
- [Phase 4]: Every environment points at the production backend and live Stripe, so payment UAT places real holds.
- [Phase 7]: CHAT-08 needs a device re-test before planning (Q8).
- [Phase 4]: Open decision from 01-13: when the confirm insert fails with no replay, confirm does not void the authorized PaymentIntent, and whether a webhook or sweep clears it is unchecked. Needs a user decision before Phase 4 payment UAT.
- [Phase 1]: Open decision from 01-12: a pending_approval hold past end_time stays until expireBookings voids it (up to about 12h after the request). Accepted in effect by pushing wave 2, not explicitly confirmed by the user.
- [Phase 1]: BACK-06/BACK-07 real-card smoke not run (user skip 2026-11-08); run the 01-17 checklist before those requirements close, at the latest during Phase 4 payment UAT.
- [Phase 1]: Refund retry fix (user chose option A, 2026-11-08): failed refunds are not retried as refunds; needs its own plan and deploy before Phase 4 payment UAT. No phase or plan for it exists yet; one still needs creating. A failed cancel refund leaves refund_amount_minor_units NULL, so refundReconciliation retries cancelPI, not a refund, and the client is not refunded without manual action. Applies to expert and client cancels; from the 01-19 code read, BACK-19 widens it only slightly because capture happens after a booking stops being cancellable. Analysis and the shape of the fix are in 01-19-SUMMARY.md. (Correction: PATCH /expert/bookings/:id/status rejects cancelled, so that item is closed.)
- [Phase 1]: BACK-19 production smoke not run (user skip 2026-11-08); run the 01-19 checklist before it closes, at the latest during Phase 4 payment UAT.
- Wave 3c (BACK-13, BACK-08) is packaged at 8407402 and not pushed. User decides setup-route promotion option A, B or C, then pushes and runs the 01-23 smoke

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| *(none)* | | | | |

## Session Continuity

Last session: 2026-11-09T02:55:15.876Z
Stopped at: 01-23 Task 2 checkpoint: wave 3c ready to push, awaiting user decision on setup promotion, push and smoke
Resume file: .planning/phases/01-backend-fixes/01-23-SUMMARY.md
