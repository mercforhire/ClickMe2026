---
phase: "01"
slug: "backend-fixes"
status: draft
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-09"
---

# Phase 01 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Basis:** the auditor read the backend code at `master` (`0085662`), whose runtime code is the same as `d86bf97`. It ran no tests and made no production calls. Every cited test mocks Stripe and Supabase, so unless stated otherwise a code read plus a mocked test is the only proof. Nothing here shows behavior on real Stripe.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Client app to REST API | JWT-authenticated requests | Ids, free text, card ids, start times |
| Client app to Stripe directly | PaymentSheet with customer and ephemeral key; the backend never sees removals | Card add and removal |
| Socket client to socket server | Authenticated `message.read` | Thread and message ids |
| Participant to join and end routes | Status and window gate before a token is issued | Agora token, end metadata |
| Any authenticated user to `/expert/*` | Role escalation; first-touch promotion is live | Roles, Connect account creation, tax data |
| Expert or client to cancel routes | User triggers live void or refund | Booking id, reason text |
| Backend to Stripe (platform and connected) | Live money and card calls | Refunds, voids, clones, detach |
| Stripe to webhooks | Events the backend reconciles from | `charge.refunded` and others; no card-detach event |
| Cron to live Stripe | Unattended money movement | Saved amount and flag decide a refund |
| Backend to FCM and APNs | Leaves our infrastructure onto the device | Ids and enums in data; title and body, including chat preview |
| Backend to notifications table and API reads | Shown to the owning user or booking parties | `in_app_meta`, decline note, cancellation reason, refund state |
| Local repo to production | Only the user pushes or runs `db push` | Code, schema |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Tampering | expertProfile.schema.js meeting_url | medium | mitigate | URL validation is kept for every non-empty value (refine with the existing url check, max 500); only null and "" bypass it and both are stored as null | closed |
| T-01-02 | Information disclosure | tests/contract.responseShapes.test.js fixtures | low | accept | Fixtures use synthetic UUIDs and names only; no tokens, keys or real user data are committed | closed |
| T-01-03 | Information disclosure | push.js data map | medium | mitigate | Only enums and ids enter the FCM data map (category, sub_category, target_role from ALLOWED_TARGET_ROLES, event_type, ids); free text goes through in_app_meta, which is written only to the recipient's own notifications row | closed |
| T-01-04 | Elevation of privilege | target_role consumed by clients | low | accept | target_role is a routing hint for which app mode to open; every API call is still authorized server-side by JWT and ownership checks, so a wrong hint cannot grant access | closed |
| T-01-05 | Information disclosure | noShowNotification.js recipient choice | low | mitigate | target_role is computed from the same absentUserId the cron already sends to (T-17-09 privacy rule), so no new recipient is introduced; the test pins both branches | closed |
| T-01-06 | Information disclosure | fetchClientReviewedBookingIds | low | mitigate | The reviews query only receives booking ids already scoped to the caller's expert_id, and returns only a boolean per booking (no rating or text) | closed |
| T-01-07 | Tampering | currency label | low | accept | Symbols come from a static server-side map; no user input reaches the label | closed |
| T-01-08 | Information disclosure | events.js BOOKING_DECLINED push | medium | mitigate | Free text is never put in the FCM data map (only the enum code is); it goes to in_app_meta (the recipient's own notifications row) and the two-party chat event; tests assert absence from data | closed |
| T-01-09 | Information disclosure | clientBooking.getDetail | low | mitigate | The read stays scoped by client_id, and the note is exposed only when status is declined, so stale reschedule notes are not shown | closed |
| T-01-10 | Tampering | decline note rendering | low | accept | Stored and returned as plain text with the existing 1000-character limit; clients render it as text, not markup | closed |
| T-01-11 | Tampering | createRequest | medium | mitigate | Past starts and client-chosen durations are rejected before any hold or insert, so slot keys and end_time always derive from the topic's own length | closed |
| T-01-12 | Denial of service | topic and profile schemas | low | mitigate | zod max on the amount and the arrays turns oversized payloads into 422 before any DB write | closed |
| T-01-13 | Denial of service | /feedback/submit | medium | mitigate | feedbackLimiter: 5 per 15 minutes keyed on req.user.id, mounted before validation, returning 429 TOO_MANY_REQUESTS | closed |
| T-01-14 | Information disclosure | GET /chats empty threads | low | accept | Open Q2 default: the counterpart sees that a thread exists; the query stays participant-scoped with the existing .or() guard, so no non-participant can list it | closed |
| T-01-15 | Spoofing | accept message sender | low | mitigate | sender_id is req.user.id of the authenticated expert whose expert_id scoped the booking read; no client-supplied sender | closed |
| T-01-16 | Elevation of privilege | blocked or moderated recipient bypass | high | mitigate | The accept path re-applies the same is_blocked and getAccountStatus checks chats.send uses before calling postUserMessage; tests cover both skips | closed |
| T-01-17 | Tampering | message content | low | accept | Stored as plain text with the schema's 1000-character cap (chat allows 10000); rendered as text by both clients | closed |
| T-01-18 | Tampering | production schema change | high | mitigate | Additive, idempotent ADD COLUMN IF NOT EXISTS only; the user confirms with `supabase migration list` that it is the only pending migration, applies it, and verifies the column before any dependent code ships | closed (user check) |
| T-01-19 | Repudiation | deploy without verification | medium | mitigate | The push bundle records every commit and SHA; after the push Claude confirms /health reports the expected SHA and records the smoke results | closed |
| T-01-20 | Elevation of privilege | call.controller.js join | high | mitigate | Participant check stays first; then JOINABLE_BOOKING_STATUSES rejects cancelled, declined, expired, missed and pending bookings before any token is minted; then the two-tier window | closed |
| T-01-21 | Spoofing | Agora token lifetime | medium | mitigate | Token expiry is bounded at end+70min (TOKEN_TTL_AFTER_END_SECONDS 4200), shorter than today's end+130min | closed |
| T-01-22 | Tampering | call.controller.js end | low | mitigate | The completed-status acceptance is limited to now ≤ end+70min and writes end metadata only; status and payment are never touched | closed |
| T-01-23 | Tampering (financial) | clientBooking.cancel after end | high | mitigate | SESSION_ALREADY_ENDED guard before the atomic UPDATE and before any Stripe call; test asserts no void or refund | closed |
| T-01-24 | Information disclosure | cancellation_reason | medium | mitigate | Returned only from reads scoped to the booking's client_id (getDetail) or expert_id (getSummary); never added to dispatchBookingEvent, push data or event_data; test asserts absence from the dispatch payload | closed |
| T-01-25 | Tampering | cancel reason content | low | accept | Trimmed, capped at 500 characters, stored and returned as plain text | closed |
| T-01-26 | Information disclosure | confirm replay | high | mitigate | findReplayableBooking returns a row only when isSameUser(row.client_id, req.user.id); foreign bookings keep the generic 409 with no booking_id or detail; test asserts it | closed |
| T-01-27 | Tampering (financial) | confirm replay | high | mitigate | Replay returns before retrievePI, confirmPI, insert, promo consumption and dispatch; the 23P01 replay keeps the winner's slot hold; tests assert none of those run | closed |
| T-01-28 | Information disclosure | payment-intent DUPLICATE_BOOKING detail | medium | mitigate | detail.booking_id is returned only for a booking matched on client_id = req.user.id | closed |
| T-01-29 | Tampering | handleMessageRead / recomputeUnreadFor | high | mitigate | The participant guard runs before any write; the recount only ever writes the caller's own side, chosen by unreadFieldFor from the verified thread row; non-participants and self-threads write nothing; tests cover both | closed |
| T-01-30 | Denial of service | count query per send, read and page-1 open | low | mitigate | One head-only count filtered by thread_id (indexed); failures are caught and never block the request | closed |
| T-01-31 | Repudiation | wave-2 deploy | medium | mitigate | Push bundle lists every commit and SHA; after the push Claude confirms /health reports the expected SHA and records the smoke results | closed |
| T-01-32 | Tampering (financial) | deleted card charged via clone | high | mitigate | Delete evicts and detaches every connected-account clone before detaching the platform card; the 409 block guarantees no active booking (and so no T-24h sweep or reschedule conversion) still references it | closed (accepted risk) |
| T-01-33 | Elevation of privilege | IDOR on pm id | high | mitigate | Existing ownership check (404 not 403, T-18-11) runs before the bookings query and before any eviction; the bookings query is scoped by client_id = req.user.id | closed |
| T-01-34 | Denial of service | Stripe failure during eviction | low | accept | Fail closed: the error propagates and the card stays saved, so the user can retry; no partial platform detach | closed |
| T-01-35 | Repudiation | silent default change | low | mitigate | Default promotion touches only the Stripe customer's invoice_settings, is logged on failure, and tests assert no booking is updated | closed |
| T-01-36 | Tampering (financial) | wave-3a deploy | high | mitigate | Isolated push range (card fixes only), green gate, post-deploy /health SHA check, and a real-card smoke that confirms block, eviction and detach on live Stripe | closed (accepted risk) |
| T-01-37 | Tampering (financial) | expert cancel refund amount | high | mitigate | The refund equals amount_paid_minor_units (the captured amount, never a client-supplied value), behind the existing expert_id-scoped read and REFUND_AMOUNT_MISSING guard | closed |
| T-01-38 | Tampering (financial) | double refund on concurrent cancels | high | mitigate | The status-guarded atomic UPDATE stays before any Stripe call; a lost race returns 409 ALREADY_CANCELLED with no refund; test covers it | closed |
| T-01-39 | Tampering (financial) | wave-3b deploy | high | mitigate | Isolated push range (BACK-19 only), green gate, /health SHA check, and a live expert-cancel smoke confirming a full release | closed (accepted risk) |
| T-01-40 | Elevation of privilege | silent promotion via any /expert/* call | high | mitigate | Only PATCH /expert/profile/setup mounts provisionExpert, after validation; the gate never writes roles; middleware tests and the flipped route suites pin it here, and plan 01-21's 38-route table pins every mount | closed (accepted risk) |
| T-01-41 | Elevation of privilege | stale-JWT fallback | medium | mitigate | The fallback only adds expert when profiles.roles (written by the server's own provisioning) already says expert; roles are never read from the request body | open — below high threshold (non-blocking) |
| T-01-42 | Denial of service | extra profiles read per non-expert /expert/* request | low | accept | One primary-key read; only for tokens without the expert role; real experts keep the zero-cost fast path | closed |
| T-01-43 | Information disclosure | client-only reads of /expert/* | low | accept | Read controllers stay scoped to req.user.id, so a client-only account sees only its own empty data (identical to an un-onboarded expert today) | closed |
| T-01-44 | Elevation of privilege | wave-3c deploy | high | mitigate | Isolated push range, green gate including the 38-route classification test and the Connect seam tests, /health SHA check, and a two-client smoke confirming no promotion on reads, no Connect account for a client-only account and a working stale-token path | closed (accepted risk) |
| T-01-45 | Information disclosure | account B and smoke queries | low | mitigate | Only read-only SELECTs on roles, setup flags and payout account ids; the checklist identifies account B by email or name only, never credentials | closed |
| T-01-46 | Information disclosure | chat, review, payment-action and reminder target_role | low | accept | The value is the recipient's own side of their own thread or booking and goes only to that recipient's devices; every call keeps its existing recipient, so no new recipient is introduced | closed |
| T-01-47 | Information disclosure | account-level push payload | low | mitigate | Only the enum target_role is added; the deletion token and password never enter push data or meta_data (T-16-12), and a test asserts the deletion push data still holds only event_type | closed |
| T-01-48 | Elevation of privilege | Connect account creation (postOnboard) | high | mitigate | Refused at the gate (403) and again inside postOnboard before any payout_accounts access or Stripe call when req.user.roles lacks expert; tests assert createConnectAccount is never called for a client-only caller | closed (accepted risk) |
| T-01-49 | Tampering | tax profile read and write by a client-only account | medium | mitigate | POST /expert/tax-profile is refused at the gate, so no TIN from a non-expert is ever encrypted or stored; GET /expert/tax-profile mounts expertWriteGate (option-a, decision record 01-21-D1), so a client-only account is never served the TIN form; expertTaxProfile.test.js pins both 403s and the unchanged expert paths | open — below high threshold (non-blocking) |
| T-01-50 | Information disclosure | contract docs and route headers | low | accept | The documents describe error codes and route behavior only; no secrets, tokens or user data, and the code changes in this plan are comment-only (diff check in Task 2) | closed |
| T-01-51 | Tampering (financial) | double refund across sweep retries, parallel sweeps, or a lost handler response | high | mitigate | The refund is the saved amount minus Charge.amount_refunded, read right before the call, with the key reconcile-refund-{pi}-{amount}; tests cover the interrupted run, parallel runs and a partial refund. Real Stripe stays unproven (backstop truth) | closed |
| T-01-52 | Tampering (financial) | sweep voids or refunds in the wrong state | high | mitigate | The PaymentIntent status decides the action, not the row; a captured PaymentIntent is never voided, an uncaptured one never refunded, and a client sole no-show hold is left for Sweep C | closed |
| T-01-53 | Tampering (financial) | guessed amount on a captured row with a NULL amount | high | mitigate | No money call and an OPS log line; a client cancel inside 24 hours is owed 0, so amount_paid_minor_units must not be assumed | closed |
| T-01-54 | Repudiation | detail shows refunded while the refund failed | medium | mitigate | derivePaymentStatus checks refund_failed; the getDetail select is asserted so a mock cannot hide a missing column | closed |
| T-01-55 | Information disclosure | Stripe ids in cron logs | low | mitigate | New log lines carry only the booking id and status (T-12-13) | open — below high threshold (non-blocking) |
| T-01-56 | Tampering (financial) | intended amount saved by client cancel | high | mitigate | The saved amount comes from computeRefundAmountMinorUnits on the client-scoped row at cancel time, never the request, and never exceeds it on retry | closed |
| T-01-57 | Tampering (financial) | hold left in place after a retrievePI failure | medium | mitigate | The handler flags the row with amount 0, and the sweep voids it if uncaptured or clears the flag if captured; the test covers the handler, plan 01-24 covers the sweep | closed |
| T-01-58 | Repudiation | API or ledger overstating a refund | medium | mitigate | refund_amount is 0 after a failure and refunded_amount is 0 while flagged; the select is asserted so a mock cannot hide a missing column | closed |
| T-01-59 | Tampering (financial) | money-wave deploy | high | mitigate | Isolated push range, exact runtime file list, no migration, green gate and a /health SHA check; only the user pushes | closed |
| T-01-60 | Tampering (financial) | first sweep on rows flagged before the deploy | high | mitigate | The user runs the read-only query before pushing, and Claude reviews any row against the first-sweep table first | closed (user confirmation) |
| T-01-61 | Denial of service | parked branch shipping by accident and breaking client-only accounts on build 6 | high | mitigate | Subject, ancestor and symbol checks on the push range before the handoff | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Open Threats

| ID | Severity | What is missing | What closes it |
|----|----------|-----------------|----------------|
| T-01-55 | low | `refundReconciliation.js:253` logs `rowErr.message`, which can carry Stripe text; the header claim at `:55` is false and untested (B19-WR-03) | Log only booking id and status on that path |
| T-01-41 | medium | Moot in production: the DB role fallback exists only on `wave-3c` | Revisit with `wave-3c` |
| T-01-49 | medium | Live: `src/routes/expertTaxProfile.js:31,34` promote, then serve POST and GET. The read gate is only on `wave-3c` | Deploy `wave-3c` after SIGN-06 |

---

## Evidence for High-Severity Closed Threats

Paths are relative to the backend repo. Lower-severity threats were checked in the same audit.

| ID | Evidence |
|----|----------|
| T-01-16 | `bookingRequests.controller.js:241,244-245` matches `chats.controller.js:385,394-395`; `tests/bookingRequests.test.js:937,946` |
| T-01-20 | `call.controller.js:88-91,94-97,102-109`, sole token mint `:148`; `tests/call.test.js:468,503` |
| T-01-23 | `clientBooking.controller.js:836-838` runs before the UPDATE and Stripe; `tests/clientBooking.test.js:1838-1840`; passed on a device on a free booking (`01-UAT.md` Test 3) |
| T-01-26 | `booking.controller.js:229-241`; `tests/booking.test.js:2176` |
| T-01-27 | Replays at `booking.controller.js:749,818` run before the payment work; `tests/booking.test.js:2197,2238,2261`. Device check deferred |
| T-01-29 | `services/socket.js:237-244`; `services/unreadCounts.js:34-40,74-81`; `tests/socket.messageRead.test.js:95` |
| T-01-33 | `paymentMethods.controller.js:273-275` runs before the bookings query and clone work; `tests/paymentMethods.test.js:453,474,593` |
| T-01-37 | `expertBooking.controller.js:1128-1133,1226-1231,1236`; `tests/expertBooking.test.js:1832`. Never run on real Stripe |
| T-01-38 | `expertBooking.controller.js:1146-1162` runs before Stripe; `tests/expertBooking.test.js:1919,2118` |
| T-01-51 | `cron/refundReconciliation.js:147-165`; `services/stripe.js:383`; `tests/refundReconciliation.test.js:402,626,648`. Real Stripe unproven |
| T-01-52 | `refundReconciliation.js:98,100-121`; `tests/refundReconciliation.test.js:501,533` |
| T-01-53 | `refundReconciliation.js:133-139`; `tests/refundReconciliation.test.js:487` |
| T-01-56 | `clientBooking.controller.js:816-821,945-946,978`; `tests/clientBooking.test.js:1709,1738` |
| T-01-59 | Push range `215adcb..d86bf97` is 5 commits, 4 `src` files, no migration or dependency change; gate and `/health` from `01-26-SUMMARY.md` |
| T-01-18 | Additive migration `20261107000000_bookings_cancellation_reason.sql`; the user ran `supabase migration list` on 2026-11-09: 111 local, 111 remote, 0 mismatches, latest `20261109000000` |
| T-01-60 | First-sweep table matches `refundReconciliation.js`. The user confirmed on 2026-11-09 that the flagged-row query, which returned no rows, ran before the push |
| T-01-61 | `wave-3c` is not an ancestor of `master` or `origin/main`, and no parked symbols are in `src` or `openapi` |

**Residuals on closed threats:**
- WR-02 on T-01-23: the guard also blocks cancelling a past-end `pending_approval`, so a hold stays until `expires_at`, with no charge.
- B19-WR-01 on T-01-57: a flagged row with a null `stripe_account_id` throws on every sweep. The number of such rows is unknown.
- B19-WR-02 on T-01-56 and T-01-57: the flag write result is unchecked, so a Stripe failure plus a DB failure leaves nothing to retry.

**Recorded items with no threat ID, not blockers and not tracked as threats:** hotfix `215adcb`, WR-03 (a failed client cancel reported as "already cancelled"), the confirm orphaned hold, the `accountCascade` hold gap, and refunds that fail later at the bank.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-01 | T-01-02 | Accepted at plan time; rationale in `01-01-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-02 | T-01-04 | Accepted at plan time; rationale in `01-02-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-03 | T-01-46 | Accepted at plan time; rationale in `01-03-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-04 | T-01-07 | Accepted at plan time; rationale in `01-05-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-05 | T-01-10 | Accepted at plan time; rationale in `01-06-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-06 | T-01-14 | Accepted at plan time; rationale in `01-08-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-07 | T-01-17 | Accepted at plan time; rationale in `01-09-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-08 | T-01-25 | Accepted at plan time; rationale in `01-12-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-09 | T-01-34 | Accepted at plan time; rationale in `01-16-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-10 | T-01-42 | Accepted at plan time; rationale in `01-20-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-11 | T-01-43 | Accepted at plan time; rationale in `01-20-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-12 | T-01-50 | Accepted at plan time; rationale in `01-22-PLAN.md`. Confirmed by the 2026-11-09 audit | Plan | 2026-11-09 |
| AR-01-13 | T-01-32 | Card removal inside Stripe's PaymentSheet skips the BACK-07 checks, so a connected-account clone can survive and a reschedule-converted booking could charge it. Narrow route, read from code and not run. Accepted until the tracked backend fix ships, which must happen before the iOS release | Leon chen | 2026-11-09 |
| AR-01-14 | T-01-36 | Wave 3a real-card smoke not run. Accepted until Phase 4 payment UAT (backlog 999.1) | Leon chen | 2026-11-09 |
| AR-01-15 | T-01-39 | Wave 3b live expert-cancel smoke not run. Accepted until Phase 4 payment UAT (backlog 999.1). The smoke proves the void path only; the captured refund stays proven by mocks alone | Leon chen | 2026-11-09 |
| AR-01-16 | T-01-40 | Wave 3c dropped to protect App Store build 6, so first-touch promotion via any /expert/* call stays in production. Revisit when SIGN-06 lets wave-3c deploy | Leon chen | 2026-11-09 |
| AR-01-17 | T-01-44 | The wave 3c deploy never happened, so this deploy threat has nothing to act on. Closes with T-01-40 and T-01-48 | Leon chen | 2026-11-09 |
| AR-01-18 | T-01-48 | Wave 3c dropped, so a client can create a Stripe Connect account with no role check. Revisit when SIGN-06 lets wave-3c deploy | Leon chen | 2026-11-09 |

*Accepted risks do not resurface in future audit runs, so the expiry conditions above are tracked in `ROADMAP.md` backlog 999.1 and 999.2, SIGN-06 in Phase 5, and `.planning/todos/pending/2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md`.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-09 | 61 | 57 | 4 (1 blocking) | gsd-security-auditor, with user decisions recorded the same day |

## Security Audit 2026-11-09

| Metric | Count |
|---|---|
| Threats found | 61 |
| Closed | 58 |
| Open | 3 |
