# Phase 1: Backend Fixes - Research

**Researched:** 2026-11-07
**Domain:** Live production Node/Express/Supabase/Stripe API (repo `../ClickMe2026 Backend`), shared by Android and App Store iOS build 6
**Confidence:** MEDIUM-HIGH (all file claims read this session; design choices for BACK-07/08/15/18 marked ASSUMED where they rest on judgment, not on a verified fact)

> All code lives in the backend repo `/Users/LeonChen/Documents/ClickMe2026 Backend` (local branch `master`, tracks `origin/main`). Planning artifacts live in this iOS repo. No external web research was needed: every question was answerable from the two codebases. No new packages are required, so the research-plan / package-legitimacy seams were not run.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Q6 is settled as **backend route**. BACK-17 stays in scope: send `category` and `sub_category` in the FCM `data` map for iOS tokens too, not only Android (`src/services/push.js` ~L270-274, Phase 13 D-04 Android-only branch). All senders, including the reminder, no-show, review-nudge and long-lead crons, already pass category/sub_category to `sendPushToUser`, so this is mainly removing the platform check for the data fields. The Android-only `android.notification.channelId` and visibility block stays Android-only. Build 6 parses only `event_type`, so the extra keys are ignored there (safe). Phase 2's PUSH-01 routes on `category`/`sub_category`, with nil or unknown falling back to the notifications list.
- **D-02:** BACK-17 also adds a per-recipient **`target_role`** field (`client` | `expert`) to the push data for both platforms, so iOS PUSH-02 can switch mode before routing. Compute it per recipient (e.g. recipient === booking.expert_id → `expert`). Android ignores it until it is used. Every `sendPushToUser` call site must supply or derive it. Record it in the OpenAPI/push docs.
- **D-03:** `/bookings/:id/join` uses a **two-tier gate**, applied separately to each party: First join (that party's `client_joined_at` / `expert_joined_at` is NULL): the CALL-02 rule, now ∈ [start − 60 min, max(end, start + 60 min)]. Reconnect (that party's joined_at is already set): allowed until end + 60 min, matching CALL-01 overtime. This replaces the current [start − 120, end + 120] in `isWithinSessionWindow` (`src/services/agora.js`). Make sure the Agora token TTL still covers the end+60 reconnect horizon.
- **D-04:** `/join` adds a status check. Allowed: `confirmed`, `in_progress`, `completed`, the same set as `JOINABLE_STATUSES` in `clientBooking.controller.js`. `completed` stays allowed so a reconnect still works after the end+15 cron completes the booking. All other statuses are rejected with a clear error code (planner picks 403 vs 409 and the code name, and documents it).
- **D-05:** **Leave the end+15 completion/capture cron as is** (`src/cron/expirePastSessions.js`, `AUTO_COMPLETE_GRACE_MS`). The price is fixed, so capturing at end+15 is correct. Optional and low-risk: `/end` can update `actual_duration_secs` when an overtime call ends after the cron ran. No change to the capture or payout path.
- **D-06:** Display helpers (`canJoinWindow` in clientBooking, `canJoin` in expertBooking, currently 5-min-before) should match the CALL-02 rule, so the `can_join`-style flags the server returns agree with the gate. The planner checks how build 6 and Android use these flags before changing them.
- **D-07:** Only **`PATCH /expert/profile/setup`** promotes a client to expert (keeps the current `ensureExpert` provisioning: `expert_profiles` upsert, `app_metadata` roles, `profiles.roles`, in-memory grant). No new endpoint, because build 6 and current Android already call setup during onboarding. Reversibility: costly.
- **D-08:** For a client-only account, every other `/expert/*` route: **GET/read routes** return an empty or "not set up" response (e.g. a profile with `setup_completed: false`, empty lists, zero earnings) **without promoting**, so build 6's expert home (reachable from `ModeSwitchView` for any role) shows an empty state instead of errors. **Write routes** return **403 `EXPERT_SETUP_REQUIRED`** (new error code, added to the OpenAPI error enum). The planner lists every route mounted with `ensureExpert` and classifies each one. Check what build 6 and Android call before setup completes.
- **D-09:** **No data migration.** Accounts already promoted by accident are left alone. iOS SIGN-06 (Phase 5) sends incomplete-setup experts to the setup hub. There is still no downgrade path (T-19-01 stays deferred).
- **D-10:** Deploy in **risk-grouped waves**, and check each wave before the next: (1) Additive data and validation: BACK-17 push fields + `target_role`, BACK-03 `has_review`, BACK-02 decline note, BACK-05 currency digits/symbol, BACK-04 clearable `meeting_url`, BACK-10 request validation, BACK-11 bounds, BACK-14 reason storage, BACK-16 (empty threads, feedback rate limit), BACK-01 accept message to chat. (2) Behavior changes: BACK-09 join gate, BACK-12 cancel time guard, BACK-15 idempotent confirm replay, BACK-18 unread counts. (3) High-risk, each deployed separately: Stripe card fixes (BACK-06, BACK-07, BACK-08), the Q2 expert-cancel full refund (D-17), and BACK-13 promotion. The planner may adjust wave membership, but must keep money paths and BACK-13 isolated.
- **D-11:** **The user pushes to `origin/main`** (production deploy) themselves. Claude commits locally in the backend repo (local `master` tracks `origin/main`) and never pushes. Each wave ends at a handoff: "wave N ready to push".
- **D-12:** Verify each wave with: the backend test suite passing (`tests/`), contract tests that lock the existing response shapes build 6 and Android rely on (additive fields only), and a **manual smoke checklist** after each deploy, on both build 6 and current Android: sign in, book (free and paid), pay, join a call, chat. The planner writes the checklist per wave.
- **D-13:** Stripe changes (BACK-06/07/08 and D-17) are verified with **unit tests using a mocked Stripe**, plus a **local backend run with Stripe test-mode keys**, before the wave is pushed: card delete evicting `connected_pm_clones`, lone-card default promotion, the tax-ID prompt, and the expert-cancel refund.
- **D-14:** **BACK-01:** when an expert accepts with an optional `message`, post it as a normal chat message from the expert in the client–expert chat thread, creating the thread if needed, so it shows in Chats and sends the usual chat push and socket event. No new client UI. The iOS accept-message field stays.
- **D-15:** **BACK-16:** keep NOTIF-07 (time-based notification expiry, `is_read` removed on purpose). **Drop the "notifications can be marked read" sub-item**, recording NOTIF-07 as the reason. BACK-16 now covers only: `GET /chats` lists empty threads, and `/feedback/submit` is rate-limited. Update REQUIREMENTS.md and the ROADMAP success criterion 4 to match.
- **D-16:** BACK-18 as in the inventory: increment the recipient's unread count on send (`chats.controller.js` ~L446-451, currently commented out) and reset it on `message.read` (`services/socket.js` ~L303-308).
- **D-17:** **Q2 is settled now: an expert-initiated cancel always gives the client a full refund**, or releases the hold, whenever it happens. Client-initiated cancel keeps the 24 h rule. This is backend work in the wave-3 money group (D-10). Add this to REQUIREMENTS.md (new backend item, e.g. BACK-19) and the Phase 1 roadmap. Reversibility: costly.

### Claude's Discretion
- Exact error code names and HTTP statuses for the rejected join status (D-04), BACK-10 validation, the BACK-12 cancel guard and BACK-11 bounds, following existing `AppError` conventions and field-validation `message`s (quick-261103-nnw).
- How BACK-15 stores and replays the confirm result (attempt-keyed lookup of an existing booking vs a stored response).
- How BACK-05 maps currency to digits and symbol (reuse an existing currency util if one exists).
- How "empty" responses look per GET route for non-experts (D-08), as long as build 6 decodes them.

### Deferred Ideas (OUT OF SCOPE)
- Demoting accounts promoted by accident, or any expert→client downgrade (T-19-01): not done (D-09).
- Notification read state (`read_at` + mark-read endpoint): rejected for now in favor of NOTIF-07 (D-15).
- Deferring the end+15 cron while an overtime call is still running: rejected (D-05).
- Android copy update for the expert-cancel full refund (D-17): a follow-up in `ClickMe_Android`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BACK-01 | Accept `message` delivered to client as a chat message (D-14) | `bookingRequests.controller.js` `accept` ignores `message` today; reuse send-path logic via a shared helper (see BACK-01 row) |
| BACK-02 | Decline note returned on client booking detail and notification | `decline_reason_code/text` already stored; expose in `clientBooking.getDetail` only when `status==='declined'` |
| BACK-03 | `has_review` on expert booking detail and lists | batch lookup on `reviews (booking_id, reviewer_role='client')` |
| BACK-04 | Expert can clear `meeting_url` | `expertProfile.schema.js:43` rejects null and "" |
| BACK-05 | `potential_earnings` and `consultation_fee.label` use currency digits/symbol | `bookingRequests.controller.js:195`, `expertBooking.controller.js:138` |
| BACK-06 | Lone saved card becomes default | `paymentMethods.controller.js` list/delete; no webhook needed |
| BACK-07 | Deleted card cannot be charged via connected clone | `connected_pm_clones` eviction + connected-account detach; T-24h sweep and `convertToLongLead` are the exposure |
| BACK-08 | Client never shown tax-ID prompt | root cause UNCONFIRMED; most likely covered by BACK-13 gate (see row) |
| BACK-09 | Join window + status check | `agora.js` + `call.controller.js` two-tier gate (D-03/D-04) |
| BACK-10 | `/bookings/request` validates duration, rejects past start | `booking.controller.js` `createRequest`, `requestSchema` |
| BACK-11 | Bounds on `price_amount` and tag lists | `expertTopics.schema.js:77`, `onboarding.schema.js:43-44`, `expertProfile.schema.js:53-58` |
| BACK-12 | Client cancel rejected after session end | `clientBooking.controller.js` `cancel` (fetch lacks `end_time`) |
| BACK-13 | Promotion only via explicit setup call (D-07..D-09) | `ensureExpert.js` split into read/write gates; stale-JWT trap (see Pitfall 1) |
| BACK-14 | Cancel `reason` stored | needs a NEW nullable column (migration) |
| BACK-15 | Confirm retry replays original result | `booking.controller.js` `confirm` / `createPaymentIntent` own-booking handling |
| BACK-16 | `GET /chats` lists empty threads; `/feedback/submit` rate limited (mark-read dropped by D-15) | `chats.controller.js:175`; per-user limiter pattern exists |
| BACK-17 | Push `category`/`sub_category` for iOS + `target_role` | `push.js:268-274`; CONTEXT D-01 premise about build 6 is partly wrong (see Findings) |
| BACK-18 | Unread count increments on send, resets on `message.read` | no atomic increment primitive exists; see BACK-18 row |
| BACK-19 (new, D-17) | Expert cancel always full refund/release | `expertBooking.controller.js` `cancel`; practical scope narrower than CONTEXT assumes (see Findings) |
</phase_requirements>

## Summary

The backend is a mock-tested Jest/supertest suite (2664 tests pass today; one pre-existing suite, `tests/services/redis.test.js`, fails only because `REDIS_URL` is unset). Every change in this phase is a localized edit to an existing controller, schema, middleware or service. No new routes are needed (a new route would trip `scripts/check-doc-coverage.js` and `scripts/check-openapi-coverage.js`, both currently green at 128 endpoints). Two changes need a Supabase migration that the user must apply with `supabase db push` before the code deploys: BACK-14 (new `bookings.cancellation_reason` column) and, only if chosen, an atomic unread-increment RPC for BACK-18.

Three findings change how the CONTEXT decisions should be executed. (1) D-01's premise is wrong: build 6's `PushEvent` reads `category` first and `PushRouter` already maps every category, so once the backend sends `category` to iOS tokens, build 6 taps that did nothing today will start navigating (and a tap on an expert-side push while in client mode can land on a client booking-detail 404 until Phase 2 ships `target_role` handling). (2) BACK-13 has a stale-JWT trap: roles are read only from the JWT, and a freshly promoted account keeps a client-only token for up to 7 days, so the new gate must consult `profiles.roles` for client-only tokens or every post-setup expert call would 403. (3) D-17's concrete scenario (charged long-lead booking refunds 0) cannot occur on the current payment model: PaymentIntents are created `capture_method: 'manual'` and are voided (full release) on cancel unless already `succeeded`. The refund-0 branch is only reachable for PIs already captured. The D-17 change is still correct and small, but its tests must target the `succeeded` branch.

**Primary recommendation:** Execute in the D-10 waves, but add a Wave 0 (shared test helpers, extracted testable handlers, contract-shape tests) and make the BACK-14 migration an explicit "user applies migration first" handoff step at the start of the wave that contains it.

## Findings That Contradict or Refine CONTEXT

| # | CONTEXT statement | What the code says | Impact on plan |
|---|-------------------|--------------------|----------------|
| F1 | D-01: "Build 6 parses only `event_type`, so the extra keys are ignored (safe)" | `PushEvent.init` reads `data["category"]` first and only falls back to `event_type` [VERIFIED: ClickMe2026/Model/Push/PushEvent.swift:61-65: `if let cat = data["category"] as? String, !cat.isEmpty {`]. `PushRouter.destination(for:)` maps `booking/*`, `session/*`, `message`, `review`, `payout`, `account` [VERIFIED: ClickMe2026/Managers/PushRouter.swift:117-165] | The change is not ignorable on build 6. Previously dead pushes (confirmed, declined, cancelled, reminders, no-show, nudge, payment_actions) start navigating on build 6 the moment wave 1 deploys. This is mostly beneficial, but an expert-side push tapped while in client mode opens `bookingDetail` in the client shell (likely 404 for a booking the user owns as expert). Add to the wave-1 smoke checklist and get user acknowledgement (Open Question 1). |
| F2 | D-17: "an expert cancelling a charged long-lead booking within 24 h currently refunds 0" | `createManualPI` sets `capture_method: 'manual'` [VERIFIED: src/services/stripe.js:~172 `capture_method: 'manual',`]; the T-24h sweep authorizes only (`// status after success: 'requires_capture'`); both cancel handlers void when the live PI is `requires_capture` and only call `computeRefundAmountMinorUnits` when the PI is `succeeded` (captured) [VERIFIED: src/controllers/expertBooking.controller.js `cancel`, the `else` branch under `// succeeded (captured) → refund per D-04 binary policy`]. Capture happens at end+15 (Sweep C) | The 24 h refund-0 branch only fires for already-captured PIs (legacy accept-time captures, edge cases). D-17 still stands as a user decision and is a one-line behavior change in that branch, but the planner must write the test against `retrievePI → status 'succeeded'`, and BOOK-08/EXP-11 copy in later phases should be told that for normal bookings cancel is already a full release. |
| F3 | D-08: "the planner lists every route mounted with `ensureExpert`" (list in CONTEXT omits some) | Routes also mounted: `expertBooking.js` (11), `availability.js` (2), `analytics.js` (3). `clientTransactions.js` only mentions it in a comment. `payouts.js` withdraw is a retired 410 route with no gate | Use the full classification table under BACK-13. |
| F4 | BACK-15 "confirm retry with the same `booking_attempt_id`" | `confirmSchema` has NO `booking_attempt_id` (strict) [VERIFIED: src/schemas/booking.schema.js:63-74]. `booking_attempt_id` exists only on `paymentIntentSchema`. `confirm` already answers a retry that finds the PI's booking with `409 DUPLICATE_BOOKING` [VERIFIED: booking.controller.js:637]. The own-booking `SLOT_UNAVAILABLE` comes from (a) `createPaymentIntent` Step 3 `isSlotConflicted` (booking.controller.js:~387-389) when the client restarts at the intent step, and (b) the in-flight race in `confirm` Step 3 / exclusion-constraint handler (L700, L948) | Replay must be keyed on existing columns (client_id, expert_id, topic_id, start_time, payment_intent_id), not on a column that does not exist. |
| F5 | D-16: "reset it on message.read" | `docs/SOCKET-CONTRACT.md` §6 tells clients unread is not maintained; Android takes `maxOf(server, local)` [VERIFIED: ConversationsUiState.kt `fun displayUnread(server: Int, local: Int): Int = maxOf(server, local)`] | Once the server count is live, a server count that is never reset would pin Android's badge above its local count. The reset path must be reliable (recompute, and consider also resetting on `GET /chats/:id/messages`). SOCKET-CONTRACT §6 must be rewritten. |
| F6 | BACK-08 "client never shown tax-ID prompt" | The only tax-ID flow in the backend is the expert CRA tax profile (`/expert/tax-profile`, `tin_on_file`); there is no `tax_id_collection` anywhere in `src`. The Android bug log says only "Stripe tax ID (TIN) prompt seen on client account B... A Connect status was not read" [VERIFIED: ClickMe_Android/.planning/phases/16-cross-platform-qa/16-BUG-LOG.md:45] | Root cause not proven by this research pass. Best hypothesis: the client account was silently promoted by `ensureExpert` (BACK-13) and then surfaced expert-only onboarding. **Superseded 2026-11-07 (planning revision):** the "BACK-08 seam trace" below locates every tax-ID surface in code, so BACK-08 is fixed at those seams (plan 01-21) and no longer depends on this hypothesis; the account B check stays only as background for BUG-03. |

### BACK-08 seam trace (added in the 2026-11-07 planning revision)

Read this revision, in all three repos. A tax-ID prompt can reach a user in exactly three ways:

| # | Surface | Where it is shown | Backend seam | Evidence |
|---|---------|-------------------|--------------|----------|
| 1 | In-app "Tax & Payout Info" form with a TIN field ("Required by Stripe to process your payouts", Android `strings_tax_profile.xml:6`; "TIN (SIN / BN)", line 20) | iOS: unconditional row in the expert Profile tab [VERIFIED: ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift:120-122]; Android: expert shell only [VERIFIED: HomeExpertScreen.kt:316, SettingsEntries.kt:79 inside `expertSettingsEntries`] | `GET /expert/tax-profile` loads it (`tin_on_file:false` → empty form); `POST /expert/tax-profile` saves it | iOS view renders the form only on a successful load and an error view otherwise [VERIFIED: ExpertTaxProfileView.swift:66-73]; Android likewise [VERIFIED: ExpertTaxProfileScreen.kt:189-200] |
| 2 | Stripe-hosted Express onboarding (asks for the SIN) | Opened from expert Payouts | `POST /expert/connect/onboard`, the only code that creates a Connect account [VERIFIED: src/controllers/connect.controller.js:66 `createConnectAccount({ email, country: 'CA' })`; `grep accounts.create src` finds only stripe.js:590] | Android calls it only from `ExpertFinancialRepository.kt` |
| 3 | Stripe's own follow-up requests for an existing Connect account, and the `KYC_ACTION_REQUIRED` push | Email/Stripe UI; push to `payout_accounts.expert_id` | Needs a `payout_accounts` row, which only surface 2 creates [VERIFIED: connectWebhooks.controller.js:146-166] | — |

Nothing else collects a tax ID: there is no `tax_id_collection`, customer `tax_id` or PaymentSheet billing-detail collection in the backend (`grep -rn "tax_id\|automatic_tax\|tax_id_collection" src` finds only the expert tax profile) or in either client's payment code. Neither client loads `GET /expert/tax-profile` on its own: on iOS only `ExpertTaxProfileViewModel` calls it, on Android only `TaxProfileRepository.load`.

Reachability for a client-only account once the BACK-13 gate ships:
- **Android:** the mode switch goes to the setup hub when setup is incomplete, and "Not now" returns to client home [VERIFIED: AppViewModel.kt:223]. So surfaces 1 and 2 cannot be reached until the setup call promotes the account. Closed.
- **Surfaces 2 and 3, any client:** `POST /expert/connect/onboard` is a write and gets 403 at the gate. Plan 01-21 also refuses non-experts inside `postOnboard`. Closed.
- **Build 6 iOS, surface 1:** `ModeSwitchView` opens the expert home for any role (inventory S7), and the row is unconditional, so `GET /expert/tax-profile` is reachable. With D-08's read rule it returns 200 and the empty form renders; saving is refused. This is the one remaining surface. Closing it from the backend needs that GET to return 403, which is an exception to D-08, so plan 01-21 Task 2 asks the user.

Conclusion: silent promotion by `ensureExpert` is the only way a client account can reach surfaces 1-3. That makes A7's mechanism a fact about the code. Whether account B took that path is still a production question, but BACK-08's fix does not depend on the answer.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Join-window and status gate (BACK-09) | API / Backend (`call.controller.js`, `services/agora.js`) | Client (button visibility, Phase 2/3) | Server is authoritative; clients only mirror via `can_join` hints |
| Expert promotion + `/expert/*` gating (BACK-13) | API / Backend (`middleware/ensureExpert.js`, per-route wiring) | Client (SIGN-06 gate, Phase 5) | Authorization must be server-side |
| Booking validation, cancel guard, reason storage, idempotent confirm (BACK-10/12/14/15) | API / Backend + Database (new column) | — | Business rules and persistence |
| Saved-card default / clone eviction (BACK-06/07) | API / Backend + Stripe | Database (`connected_pm_clones`) | Money state lives in Stripe and the clone cache |
| Unread counters (BACK-18) | API / Backend + Database (`chats.unread_count_*`) | Socket.io (`message.read`) | Denormalized counters written by REST send and socket read |
| Push routing fields (BACK-17) | API / Backend (`services/push.js`) | Client routers (Phase 2) | Payload shape is the contract |
| Empty-state shapes for non-experts (D-08) | API / Backend | Client | Existing controllers already tolerate missing rows |

## Standard Stack

No new libraries. Everything below is already installed and used [VERIFIED: package.json].

### Core
| Library | Version | Purpose | Use in this phase |
|---------|---------|---------|-------------------|
| express | 5.2.1 | HTTP; async errors propagate natively | all controllers, middleware |
| zod | ^4.4.3 | request validation via `middleware/validate` | BACK-04/10/11 schema edits; field-validation `message` convention (quick-261103-nnw) |
| stripe | 22.2.0 | payments | BACK-06/07/19 wrappers in `src/services/stripe.js` |
| luxon | ^3.7.2 | time math | BACK-09/10/12 windows |
| express-rate-limit | ^8.5.2 | limiters (in-memory, single replica) | BACK-16 `/feedback/submit` per-user limiter, copy `withdrawLimiter` / `interactionLimiter` keyGenerator pattern in `src/middleware/rateLimiter.js` |
| jest / supertest | 30.4.2 / 7.2.2 | tests | all validation |
| socket.io | 4.8.3 | realtime | BACK-18 reset, BACK-01 emit |
| firebase-admin | 13.10.0 | push | BACK-17 |

**Installation:** none. **Version verification:** versions read from `package.json` this session; no registry lookup needed because nothing is added.

## Package Legitimacy Audit

No external packages are installed or upgraded in this phase. Audit not applicable.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 iOS build 6 / Android ──HTTPS──► Express app (src/app.js)
        │                             │  authenticate (JWT roles from app_metadata ONLY)
        │                             ▼
        │            ┌── /expert/* ── expertGate(read|write) ──► controllers (BACK-13)
        │            │      reads: pass-through, no provisioning
        │            │      writes: DB role check ─► 403 EXPERT_SETUP_REQUIRED
        │            │      PATCH /expert/profile/setup ─► promote (a..d) ─► setupProfile
        │            ├── /bookings/request ─► createRequest (BACK-10 validate) ─► Redis hold ─► bookings insert
        │            ├── /bookings/payment-intent ─► createPaymentIntent ─► Stripe PI (manual capture)
        │            ├── /bookings/confirm ─► confirm (BACK-15 replay) ─► bookings insert (+ dispatchBookingEvent)
        │            ├── /bookings/:id/join ─► call.join (BACK-09 gate) ─► Agora token
        │            ├── /client/bookings/:id/cancel ─► cancel (BACK-12 guard, BACK-14 reason) ─► void/refund
        │            ├── /expert/bookings/:id/cancel ─► cancel (BACK-19 full refund)
        │            ├── /expert/booking-requests/:id/accept|decline ─► (BACK-01 chat msg, BACK-02 note)
        │            ├── /me/payment-methods ─► list/delete (BACK-06 default, BACK-07 evict)
        │            ├── /chats, /chats/:id/send ─► (BACK-16 list, BACK-18 unread)
        │            └── /feedback/submit ─► feedbackLimiter (BACK-16)
        │
 Socket.io ── message.read ─► socket.js handler ─► messages.status + chats.unread_count_* reset (BACK-18)
        ▲
 dispatchBookingEvent ─► ensureThread ─► system message ─► booking.update emit ─► sendPushToUser (BACK-17 category/target_role)
 crons (reminder, noShow, reviewNudge, longLeadChargeSweep) ─► sendPushToUser
 Sweep B/C (expirePastSessions) completes at end+15 and captures (UNCHANGED, D-05)
```

### Recommended file touch map
```
src/middleware/ensureExpert.js     # split: provisionExpert() + expertReadGate + expertWriteGate (BACK-13)
src/services/agora.js              # join window constants + evaluateJoinWindow (BACK-09)
src/services/push.js               # category/sub_category/target_role for all platforms (BACK-17)
src/services/chatMessages.js (new) # shared "post a user message" used by chats.send and accept (BACK-01/18)
src/utils/currency.js (new, small) # symbol map beside minorUnitDigitsFor in utils/earnings.js (BACK-05)
src/services/stripe.js             # detachPaymentMethod(pmId, stripeAccountId?) (BACK-07)
supabase/migrations/2026110xxxxxxx_bookings_cancellation_reason.sql (new, BACK-14)
openapi/clickme-api.yaml, docs/SOCKET-CONTRACT.md, docs/ios/*.md  # every contract change
tests/...                          # see Validation Architecture
```

### Pattern: per-requirement change map (the planning core)

Legend: **Android/b6** = effect on current Android and live build 6. **$** = touches money. **Mig** = needs DB migration.

| Req | Exact seams | Change | Android/b6 | $ | Mig |
|-----|-------------|--------|-----------|---|-----|
| **BACK-17** | `src/services/push.js:268-274` (`const isAndroid = platform === 'android'`; data spread `{ ...safeData, category: ..., sub_category: ... }`). Call sites (about 24): `services/events.js` (booking_request, CONFIRMED, DECLINED, CANCELLED x2 recipients, COMPLETED x2, EXPIRED, RESCHEDULED), `controllers/chats.controller.js:483`, `reviews.controller.js:101`, `account.controller.js:253,469`, `webhooks.controller.js:230`, `connectWebhooks.controller.js:156,219,958`, `cron/reminderNotification.js:88,98`, `cron/noShowNotification.js:95`, `cron/reviewNudgeNotification.js:107`, `cron/longLeadChargeSweep.js:364` | Always add `category`, `sub_category` (and `target_role` when known) to `safeData` for every token including legacy rows with no `platform`. Keep `android.notification.channelId`/`visibility` Android-only. Add optional `target_role` param to `sendPushToUser`; derive default `'expert'` when `is_expert_only` is true; each booking/chat/review/cron site passes it explicitly (recipient === booking.expert_id → expert, chat recipient === thread.expert_id, review reviewee by reviewer_role). Account-level pushes (password, deletion) omit the key (iOS must keep current mode). Value must be a string (WR-05). | See F1. Android ignores `target_role`; it already reads `category`/`sub_category`. | no | no |
| **BACK-03** | `expertBooking.controller.js` `getFeed` (select at ~L205-212), `getDetails` (L294+), `getSummary` (L378+) | Batch `reviews` query: `.in('booking_id', ids).eq('reviewer_role','client')` once per page; add `has_review: boolean` to each item and the detail/summary. Reviews table has `UNIQUE (booking_id, reviewer_role)` [VERIFIED: supabase/migrations/20260610000000_create_reviews.sql `CONSTRAINT reviews_booking_reviewer_unique UNIQUE (booking_id, reviewer_role)`]. | Additive key | no | no |
| **BACK-02** | `clientBooking.controller.js` `getDetail` (select at L1003-1010, return at L1038+); `bookingRequests.controller.js` `decline` (L296-380) dispatches with the booking row that lacks the reason; `events.js` BOOKING_DECLINED push and `injectEventMessage` | Add `decline_reason_code`, `decline_reason_text` to the select and response **only when `status === 'declined'`**: `expertBooking.declineReschedule` writes the same `decline_reason_text` column (`updatePayload.decline_reason_text = reason;` at L1007) while the booking returns to `confirmed`, so an unconditional return would show a stale reschedule-decline note on a live booking. Pass reason through `dispatchBookingEvent` so it reaches the push `data` (also stored in `notifications.meta_data`) and the system message `event_data`. | Additive keys | no | no |
| **BACK-05** | `expertBooking.controller.js:138` `` label: `$${major.toFixed(digits)} / session` ``; `bookingRequests.controller.js:195-196` `potential_earnings: data.amount_paid_minor_units != null ? data.amount_paid_minor_units / 100` and the list-row computation at ~L102 | Divide by `10 ** minorUnitDigitsFor(currency)` (shared in `utils/earnings.js`, ZERO_DECIMAL set at L25) and take the symbol from a small map/`currencies` table. Seeded symbols include `('CAD', 'CA$', ...)` [VERIFIED: supabase/migrations/20260603050000_seed_currencies.sql:35]. | CAD data has 2 digits so numbers are unchanged. The label would change `$12.50` to `CA$12.50` if the table symbol is used (Open Question 4). | no | no |
| **BACK-04** | `src/schemas/expertProfile.schema.js:43` `meeting_url: z.string().url().max(500).optional(),`; `expert.controller.js:158-159` | Accept `null` and `""` (`.nullable()` plus `z.literal('')`), normalize `""` to `null` before the upsert. Relaxing validation only. | Additive | no | no |
| **BACK-10** | `booking.controller.js` `createRequest` (L1458+): `const topicDuration = duration_minutes \|\| topic.duration_mins \|\| 30;` (L1507); `requestSchema` (L87-95) | Reject `scheduled_start <= now` (422 with a hand-written message so it surfaces as the top-level `message`). Reject `duration_minutes !== topic.duration_mins` (both clients send the topic's duration: iOS `MakeABookingViewModel.swift:389,431`, Android `MakeABookingViewModel.kt:403,435`). `createPaymentIntent` has the same `duration_minutes \|\|` trust (L364) while `confirm` uses the topic duration (L687); apply the same equality check there to avoid slot-key drift (hardening, payment path). | Both clients already send topic duration, so no valid request is newly rejected | no (free path; PI path is hardening) | no |
| **BACK-11** | `expertTopics.schema.js:77` `amount:   z.number().int().nonnegative(),` (no max); `onboarding.schema.js:43-44` `languages`/`expertise_tags` `z.array(z.string())` uncapped; `expertProfile.schema.js:53-58` `languages`, `expertise_tags` uncapped | `amount` max 2147483647 (Postgres INTEGER) or a business cap; array `.max(N)`. No client-side tag cap was found in iOS or Android, so N must not reject any legitimate payload: pick a generous bound (suggest 50) and check production max (Open Question 9). | Rejects only absurd payloads | no | no |
| **BACK-12** | `clientBooking.controller.js:801-` `cancel`: fetch select (L806) lacks `end_time`; `const cancellableStatuses = ['confirmed', 'pending_approval', 'pending_reschedule'];` (L818) | Add `end_time` to the select; if `now >= end_time` throw 409 with a new code (suggest `SESSION_ALREADY_ENDED`, unknown codes decode leniently on both clients, see Pitfall 6) before the atomic UPDATE. Applies regardless of status. Expert cancel unchanged. | iOS Phase 3 hides the button (BOOK-13); Android never sends | guards refunds | no |
| **BACK-14** | `booking.schema.js:119-120` `cancelSchema = z.object({ reason: z.string().max(500).optional(),`; both `cancel` handlers update only `status`/`updated_at` | New nullable column `bookings.cancellation_reason TEXT`; write `req.validatedBody.reason ?? null` in the same atomic UPDATE for client and expert cancel. The name matches the placeholder in `expertBooking.getSummary` (`responseData.cancellation_reason = null; // populated by cancel endpoint`). **Do NOT reuse `cancel_reason`**: it is an in-memory enum (`'payment_failed'`) that `events.js` copies into push `data` and chat `event_data`. Never put free text into that path. Return it only to the booking's own parties. | Additive column | no | **yes** |
| **BACK-15** | `booking.controller.js` `confirm` Step 1 (L630-639), Step 3 (L697-701), 23505/23P01 handler (L934-951); `createPaymentIntent` Step 3 (L387-390) | Add one helper `findOwnBookingForRetry({clientId, expertId, topicId, startIso, paymentIntentId?})`. In `confirm`: when an existing booking for this `payment_intent_id` belongs to `clientId`, replay the original `201` body instead of `409 DUPLICATE_BOOKING` (same keys: `booking_id`, `status`, `message`, `estimated_confirmation_time`); use the same replay in the 23505 handler and when the Step 3 conflict is the caller's own identical booking. In `createPaymentIntent`: if the conflicting row is the caller's own active booking for the same expert/topic/start, return a distinct, mappable `409 DUPLICATE_BOOKING` carrying `booking_id` in `detail` rather than `SLOT_UNAVAILABLE`. Foreign bookings keep `SLOT_UNAVAILABLE`. Ownership check is mandatory (V4). | Replay returns a success where old clients mapped 409; DUPLICATE_BOOKING and SLOT_UNAVAILABLE are already mapped by iOS (`MakeABookingViewModel.swift` cases) | creates no charge; sits on the PI confirm path | no |
| **BACK-16a** | `chats.controller.js:175` `.not('last_msg_at', 'is', null)` with `.order('last_msg_at', { ascending: false })` | Drop the filter. Postgres sorts NULLs FIRST on DESC, so order by `last_msg_at` desc with `nullsFirst: false` then `created_at` desc; select already includes `created_at`. Response already maps `last_message: ... \|\| null`, `last_msg_at: ... \|\| null`. Threads are created by `POST /chats/initiate` with no message, so the OTHER party will also see an empty row (Open Question 2). | iOS `ChatThreadItem.lastMsgAt: Date?`, Android `lastMsgAt: Instant? = null` and sorts nulls last: both tolerate | no | no |
| **BACK-16b** | `src/routes/feedback.js` `router.post('/feedback/submit', validate(submitFeedbackSchema), submitFeedback);` | Add a per-user `feedbackLimiter` in `rateLimiter.js` (copy `withdrawLimiter`: `keyGenerator: (req) => (req.user && req.user.id) ? req.user.id : req.ip`, `validate: { keyGeneratorIpFallback: false }`, 429 `TOO_MANY_REQUESTS`). Suggest 5 per 15 min. Place before `validate`. In-memory store is correct only because `railway.json` pins `numReplicas: 1`. | clients already map 429 / `TOO_MANY_REQUESTS` | no | no |
| **BACK-18** | `chats.controller.js` `send` (~L437-451: the commented-out `// void unreadField; // unread increment deferred`, `unreadField` already computed); `services/socket.js` `socket.on('message.read', ...)` (~L284-318) | **Recommended (no migration):** after the message insert, set `unread_count_<recipient>` = count of messages in the thread where `sender_id != recipient` and `status != 'read'` (recompute, self-healing, no read-modify-write race on an integer). On `message.read`, after the status update, recompute the READER's counter the same way (becomes 0 when all read). Alternative needing a migration: an atomic `increment_unread` RPC. Count only user messages (system `event` messages have `sender_id` NULL and are not counted). Extract the socket handler into an exported function so it is testable (no socket test exists today). | Android: `maxOf(server, local)`, see F5. iOS ignores the field today | no | no (recompute) |
| **BACK-01** | `bookingRequests.controller.js` `accept` (~L216-285): body `message` is validated by `acceptSchema` (`message: z.string().max(1000).optional()`) then never read; the alias route `/expert/bookings/:id/accept` uses the same handler | After the status UPDATE and the CONFIRMED dispatch, best-effort (never fail the accept): find/create the thread, skip if blocked or recipient unavailable, insert a `text` message from the expert (generate a `client_msg_id`), bump `chats.last_msg_*`, emit `message.new`, send the chat push, bump unread. Reuse the extracted send logic (`services/chatMessages.js`) so BACK-18 applies to it automatically. Chat `content` max is 10000 [VERIFIED: src/schemas/chat.schema.js:38], so 1000 fits. `ensureThread` is private to `events.js` (not exported) while `findThreadForPair` is exported from `services/threads.js`: export `ensureThread` or reuse the pair lookup plus upsert. | Additive message; Android shows it as a normal chat message | no | no |
| **BACK-09** | `services/agora.js:51-56` constants; `call.controller.js` `join` (select at L57 lacks `client_joined_at, expert_joined_at`; gate at L70) | `evaluateJoinWindow({start, end, now, alreadyJoined})`: first join allowed in `[start-60m, max(end, start+60m)]`; reconnect (that party's joined_at set) until `end+60m`. Status check against `['confirmed','in_progress','completed']` before the window check. Set `JOIN_GRACE_MS` to 60 min: `TOKEN_TTL_AFTER_END_SECONDS = JOIN_GRACE_MS / 1000 + 600` then yields end+70 min, which covers the reconnect horizon. Stamp logic (first-join-wins) unchanged. Reuse `403 SESSION_NOT_ACTIVE` for the non-joinable status with a distinct message: both clients already map it (iOS `ErrorCode.swift:53`, Android `ErrorCode.kt:43`), so no new code is needed. Update `can_join` helpers (`clientBooking.canJoinWindow` L123, `expertBooking.canJoin` L158) to `[start-60m, max(end, start+60m)]`; iOS ignores the server flag (UpcomingBookingsView.swift:56 comment), Android decodes `can_join` but never reads it in `app/src/main`. | Tighter than today's 120/120 window; both clients enforce their own window | no | no |
| **BACK-06** | `paymentMethods.controller.js` `listPaymentMethods` (computes `defaultPmId`), `deletePaymentMethod` (clears default when the deleted card was default) | Helper `ensureLoneCardDefault(customerId, pmList, defaultPmId)`: if no default and exactly one card, call `setDefaultPaymentMethod` (and report `is_default: true` in the response); call it from list (the first read after PaymentSheet adds a card) and after a delete leaves one card. No `payment_method.attached` webhook (needs Stripe dashboard event config that tests cannot cover). Default is display-only: charging uses an explicit `pm_` id (`grep default_payment_method src` shows no booking use). Note PM-01's "GET never writes" contract text must be updated. | Additive | no (default flag only) | no |
| **BACK-07** | `services/connectedPaymentMethodClone.js` (file header: "treated as append-only / never-evict (Pitfall 3): this file MUST NOT add a DELETE/UPDATE path against that table"); `deletePaymentMethod` detaches only the platform PM; consumers: `longLeadChargeSweep.chargeOne` (cache HIT then `confirmPIOffSession`), `paymentStateMachine.convertToLongLead`, `confirmLongLead` | On delete: look up all `connected_pm_clones` rows for `platform_payment_method_id = pmId`, detach each clone from the connected Customer (`paymentMethods.detach(cloneId, {stripeAccount})`, new optional 2nd param on `stripe.detachPaymentMethod`), then delete the rows. This deliberately reverses the never-evict rule for a card that can never be re-cloned (platform PM is detached); document why. Then decide what the T-24h sweep does when the clone is gone: today a non-`StripeCardError` rethrows and the booking waits for the 6 h `scaRecoveryWindowSweep` (Open Question 3). Must run before/with the Stripe detach and tolerate Stripe `resource_missing`. Table allowlist: service-role only (RLS on, no policies). | no client change | **YES** | no |
| **BACK-08** | see F6 and the BACK-08 seam trace; `expertTaxProfile.js` GET/POST and `connect.js` onboard, all behind `ensureExpert` | Fixed at the traced seams (plan 01-21, revision 2026-11-07): the BACK-13 gate refuses `POST /expert/connect/onboard` and `POST /expert/tax-profile` for client-only accounts; `postOnboard` also refuses non-experts itself, so no Connect account is ever created for one; `GET /expert/tax-profile` follows the user's decision at plan 01-21 Task 2 (403, or D-08's empty response with a recorded build 6 residual). Regression tests: client-only `GET /expert/tax-profile`, `GET /expert/connect/status` and `POST /expert/connect/onboard` change no roles and create no `expert_profiles` or `payout_accounts` rows. The read-only check of the Android test account is background for BUG-03 only. | ships with BACK-13 in wave 3c | no | no |
| **BACK-13** | `src/middleware/ensureExpert.js` (fast path on `req.user.roles.includes('expert')`, then provision a-d); see classification below | Split into `provisionExpert(req)` (current a-d), `expertWriteGate`, `expertReadGate`. **Setup route**: `provisionExpert` then controller (only place that promotes). **Reads**: if JWT has `expert`, next; else if `profiles.roles` contains `expert` (stale JWT), augment `req.user.roles` and next; else pass through without provisioning (controllers already use `maybeSingle()`/empty defaults). **Writes**: same DB check, else `403 EXPERT_SETUP_REQUIRED`. Add the code to the OpenAPI `ErrorCode` enum (closed list at `openapi/clickme-api.yaml:11721+`). | See Pitfall 1 and the Android finding below | gates Connect/payout routes | no |
| **BACK-19 (D-17)** | `expertBooking.controller.js` `cancel`, captured branch: `refundAmountMinorUnits = computeRefundAmountMinorUnits(booking);` | Replace with `booking.amount_paid_minor_units` (full). The uncaptured/void branch is already a full release; the refund call already passes `refund_application_fee: true` (`stripe.js createRefund`). Keep the atomic status UPDATE and `paymentStateMachine.transition(... 'captured' → 'refunded')`. Client cancel keeps `computeRefundAmountMinorUnits`. | Android copy follow-up logged | **YES** | no |

#### BACK-13 route classification (generated by reading every `ensureExpert` mount)

| File | READ (non-promoting pass-through) | WRITE (403 `EXPERT_SETUP_REQUIRED`) | Promoter |
|------|-----------------------------------|-------------------------------------|----------|
| `onboarding.js` | | | `PATCH /expert/profile/setup` |
| `expert.js` | `GET /expert/profile` (returns `setup_completed:false`; already safe: `const expert = (profile && profile.expert_profiles) \|\| {};`) | `PATCH /expert/profile`, `POST /expert/profile/avatar` | |
| `expertTopics.js` | `GET /expert/topics`, `GET /expert/topics/:id` | `POST`, `PATCH /:id`, `DELETE /:id` | |
| `bookingRequests.js` | `GET /expert/booking-requests`, `GET /:id` | `POST /:id/accept`, `POST /:id/decline` | |
| `expertBooking.js` | `GET /expert/bookings`, `/:id/details`, `/:id/summary` | `PUT /:id/takeaways`, `PATCH /:id/status`, `PATCH /:id/reschedule`, `POST /:id/cancel`, `POST /:id/accept`, `POST /:id/decline`, `POST /:id/accept-reschedule`, `POST /:id/decline-reschedule` | |
| `availability.js` | `GET /expert/availability` (empty schedule when no row) | `PUT /expert/availability` | |
| `earnings.js` | `GET /expert/earnings/weekly`, `/transactions` | | |
| `payouts.js` | `GET /expert/payouts/summary` (returns `400 NO_PAYOUT_METHOD`, identical to an un-onboarded expert) | (withdraw is a retired 410, no gate) | |
| `connect.js` | `GET /expert/connect/status` (returns `404 NOT_FOUND`, identical to an un-onboarded expert) | `POST /expert/connect/onboard`, `POST /expert/connect/refresh-link` | |
| `expertTaxProfile.js` | `GET /expert/tax-profile` (`tin_on_file:false`) | `POST /expert/tax-profile` | |
| `analytics.js` | `GET summary`, `trends`, `popular-topics` (RPCs keyed by expert id) | | |
| `expertClients.js` | `GET /expert/clients/:id` | | |

About 18 reads and 19 writes plus the setup route. Regenerate with `grep -rn "ensureExpert," src/routes` before planning.

**What shipped clients call before setup completes (verified):** both clients upload the avatar through the client route `/user/profile/avatar` (iOS `APIRequestURLs.swift:218`), and call only `GET /expert/profile` and `PATCH /expert/profile/setup` during signup/resume (iOS `SignupBasicInfoViewModel`, `SignupTimezoneViewModel`, `SignupReviewViewModel`, `SignupTagsViewModel`; Android `SignupSetupRepository.kt:169,283,364`). Android's mode switch deliberately uses `GET /expert/profile` as the promotion trigger: "The GET goes through the backend's `ensureExpert` and permanently converts a client-only account to expert. D-23 accepts this as the 'become an expert' path" [VERIFIED: UserManager.kt requestModeSwitch doc]. After the change that GET returns `setup_completed:false` without promoting, Android and iOS both route to the setup hub, and the setup PATCH promotes. So BACK-13 is compatible, provided the post-setup stale-JWT case works (Pitfall 1). Account signup with `role: 'expert'` already creates `['client','expert']` (`auth.controller.js:562`), so direct expert signups take the fast path.

### Anti-Patterns to Avoid
- **Editing applied migrations.** Repo rule (migration headers): add a new versioned file; the user runs `supabase db push`.
- **Writing a new column from code before the migration is applied.** supabase-js errors on an unknown column, which would 500 the cancel (money) path. The wave handoff must say "apply migration first".
- **Putting user free text into `cancel_reason` / push `data`** (leaks to the other party's lock-screen payload and chat event data).
- **Adding a route** without updating `EXPECTED_ROUTE_COUNT` in both coverage scripts, the OpenAPI paths and `.planning/clickme-api-reference.md`.
- **Using `||` on numeric/zero values** in money helpers (`utils/earnings.js` WR-01 discipline).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Request validation | manual `if` checks | zod schema + `middleware/validate` (top-level `message` rule from quick-261103-nnw) | consistent 422 shape; messages must be hand-written, not raw Zod defaults (`RAW_ZOD_MESSAGE` filter in `utils/errors.js`) |
| Rate limiting | custom counters | `express-rate-limit` per-user keyGenerator pattern in `rateLimiter.js` | already battle-tested here |
| Money digits | new `/100` math | `minorUnitDigitsFor` in `utils/earnings.js` | single shared copy (three local duplicates still exist in clientBooking/booking/coupons: do not add a fourth) |
| payment_status writes | direct UPDATE | `paymentStateMachine.transition` | guarded transitions, audit log |
| Atomic money transitions | read-then-write | UPDATE with status guard (T-04-20 pattern) | keep for D-17 |
| Thread lookup | new query | `findThreadForPair` / `classifyPairRoles` in `services/threads.js` | handles either column direction |
| Errors | ad-hoc `res.status().json` | `AppError` / `dbError` from `utils/errors.js` | handler formats `status/code/message`; `detail` is surfaced |
| Idempotency for Stripe calls | ad-hoc retries | Stripe idempotency keys already used (`booking:{attempt}:create_pi:{acct}`) | double-charge protection |

**Key insight:** every fix here has an existing sibling pattern in the repo; copying that pattern (and its header-comment decision IDs) is faster and safer than introducing new mechanisms in a live money system.

## Runtime State Inventory (BACK-13 is a behavior migration)

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `profiles.roles`/`role`, `expert_profiles` rows created by past accidental promotions | None (D-09). New code must not create rows on reads. |
| Live service config | Supabase Auth `app_metadata.roles` on promoted users | None; setup route keeps writing it. |
| OS-registered state | None: verified, no scheduler/launchd involvement | None |
| Secrets/env vars | None changed | None |
| Build artifacts | None | None |
| Cached tokens | Existing JWTs carry the roles at issue time (7 day lifetime comment in `authenticate.js`) | Gate must consult `profiles.roles` for client-only tokens (Pitfall 1). |

## Common Pitfalls

### Pitfall 1: Stale JWT after promotion makes the new gate 403 real experts
**What goes wrong:** `authenticate.js` takes roles only from the token (`const appMeta = payload.app_metadata ?? {};`). After `PATCH /expert/profile/setup` promotes a user, the token the app is holding still says `['client']` until it is refreshed or re-issued. Today every `/expert/*` call re-runs the idempotent provisioning, so it works; with a pure "JWT must contain expert" write gate, the next `PATCH /expert/profile` or topic create returns 403.
**How to avoid:** for client-only tokens, read `profiles.roles` (one indexed read) before deciding, and augment `req.user.roles` in memory. Test: token roles `['client']` + DB roles `['client','expert']` → write allowed.
**Warning signs:** 403 `EXPERT_SETUP_REQUIRED` right after a successful setup on a device that has not re-logged in.

### Pitfall 2: Write-before-migration on the cancel path
**What goes wrong:** deploying code that sets `cancellation_reason` before `supabase db push` makes every cancel update error, after Redis hold release ordering and before the Stripe void. **How to avoid:** the plan puts "user applies migration" as an explicit gate task before the code commit is handed off; keep the column write in the same UPDATE only after that gate. Consider a feature check (select the column in a pre-flight smoke script). **Warning signs:** 500 `INTERNAL_ERROR` on cancel, `column "cancellation_reason" does not exist` in Railway logs.

### Pitfall 3: Never-evict invariant vs BACK-07
The clone cache exists because re-cloning a used unattached PM fails (Pitfall 3 in the file header). Eviction is only safe because the source platform PM is being detached too. Do not evict on any other trigger, and do not call eviction from the booking hot path.

### Pitfall 4: `decline_reason_text` is shared with reschedule decline
See BACK-02: only expose when `status === 'declined'`.

### Pitfall 5: Jest mocks are sequential chains
Most suites mock `supabaseAdmin.from()` with `mockReturnValueOnce` chains in call order (`clientBooking.test.js` header comments; `paymentMethods.test.js` warns "thin mocks hide drift"). Adding a query (e.g. `end_time`, a `reviews` batch read, a `profiles.roles` read) shifts the order and breaks unrelated tests. Budget time to update existing chains, and use realistic Stripe shapes (data arrays, `invoice_settings.default_payment_method`).

### Pitfall 6: New error codes
Both clients decode unknown codes leniently: iOS "decode unknown values to `nil` (lenient)" [VERIFIED: ErrorCode.swift:15-18 doc], Android "an unknown wire value maps to null via [fromWire]" [VERIFIED: ErrorCode.kt:3-8 doc]. So `EXPERT_SETUP_REQUIRED` and `SESSION_ALREADY_ENDED` show the server `message` instead of a mapped state. Put a user-readable `message` on each. Add both to the OpenAPI enum.

### Pitfall 7: First-join extension vs no-show logic
Allowing a first join up to `start+60` on short sessions stamps `client_joined_at/expert_joined_at` later than before. `cron/noShowNotification.js` reads those stamps; verify it does not treat a late first join as a no-show that was already pushed (read the cron before finalizing the gate), and note a `completed` booking can still receive a first join until `max(end,start+60)`.

### Pitfall 8: `ensureThread` side effect and empty threads
`POST /chats/initiate` creates a thread with no messages; after BACK-16a the counterpart sees it. Also `injectEventMessage` already bumps `last_msg_at` for booking events (quick 261018-f3m), so booking threads were already listed; only manually initiated empty threads change.

### Pitfall 9: Local "Stripe test-mode run" needs a non-production database
`.env.example` shows the app needs `SUPABASE_*` and `REDIS_URL` alongside `STRIPE_SECRET_KEY`. Test-mode Stripe keys with production Supabase would write test data into production tables. Confirm a separate Supabase project exists before D-13's local run (`docs/DEPLOY-RAILWAY.md` §3 describes provisioning one). I did not read `.env` (protected).

## Code Examples

### Two-tier join gate (BACK-09), shape only
```js
// Source: derived from src/services/agora.js (constants L51-56) and CONTEXT D-03/D-04
const JOIN_LEAD_MS  = 60 * 60 * 1000;   // CALL-02
const JOIN_GRACE_MS = 60 * 60 * 1000;   // CALL-01 overtime horizon; TTL = GRACE/1000 + 600
const JOINABLE_STATUSES = ['confirmed', 'in_progress', 'completed'];

function evaluateJoinWindow({ start, end, now = Date.now(), alreadyJoined }) {
  const s = new Date(start).getTime();
  const e = new Date(end).getTime();
  const earliest = s - JOIN_LEAD_MS;
  const latest = alreadyJoined ? e + JOIN_GRACE_MS : Math.max(e, s + 60 * 60 * 1000);
  return now >= earliest && now <= latest;
}
// controller: select 'client_joined_at, expert_joined_at'; pick the caller's column;
// check JOINABLE_STATUSES first (403 SESSION_NOT_ACTIVE, distinct message), then the window.
```

### Per-user limiter (BACK-16b)
```js
// Source: pattern at src/middleware/rateLimiter.js (withdrawLimiter)
const feedbackLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 5,
  standardHeaders: 'draft-7', legacyHeaders: false,
  keyGenerator: (req) => (req.user && req.user.id) ? req.user.id : req.ip,
  validate: { keyGeneratorIpFallback: false },
  handler: (req, res) => res.status(429).json({
    status: 'error', code: 'TOO_MANY_REQUESTS',
    message: 'Too many feedback submissions. Please try again later.',
  }),
});
```

### Read/write gate skeleton (BACK-13)
```js
// Source: derived from src/middleware/ensureExpert.js; DB role read covers stale JWTs
async function resolveIsExpert(req) {
  if (req.user?.roles?.includes('expert')) return true;
  if (!req.user?.id) return null;                      // authenticate already 401s; never 403 here
  const { data } = await supabaseAdmin.from('profiles').select('roles').eq('id', req.user.id).maybeSingle();
  if (data?.roles?.includes('expert')) { req.user.roles = [...req.user.roles, 'expert']; return true; }
  return false;
}
// write gate: false -> next(new AppError(403, 'EXPERT_SETUP_REQUIRED', 'Finish expert setup to use this feature.'))
// read gate: always next(); never provision.
```

## Deploy Waves (planner may adjust; D-10 constraints preserved)

| Wave | Contents | Migration / ops step first | Handoff |
|------|----------|----------------------------|---------|
| 0 (no deploy) | shared test helpers, extract `message.read` handler, contract-shape tests for current responses | none | local commit |
| 1 additive | BACK-17 (+F1 acknowledgement), 03, 02, 05, 04, 10, 11, 16a, 16b, 01, **14** | user runs `supabase db push` for `bookings.cancellation_reason` BEFORE pushing code (or split BACK-14 into its own mini-wave) | "wave 1 ready to push" |
| 2 behavior | BACK-09, 12, 15, 18 | none (BACK-18 recompute) | "wave 2 ready to push" |
| 3a money | BACK-06, then BACK-07, BACK-19 each separate | local Stripe test-mode run (needs non-prod Supabase) | one push per item |
| 3b | BACK-13 (+BACK-08 regression tests) | none | last, isolated |

Docs updated with each change: `openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md` (§6 "unread_count is not maintained" must be rewritten in wave 2; `message.read` semantics), `docs/ios/*` where relevant. In the iOS repo: update REQUIREMENTS.md (add BACK-19, drop mark-read from BACK-16) and the ROADMAP success criterion 4 (D-15/D-17).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node | tests/dev | yes | v26.8.1 locally (`.nvmrc` pins 22, `engines >=22`) | `nvm use 22` if a toolchain quirk appears; full suite passed on v26 |
| npm/jest | tests | yes | jest 30.4.2 | none |
| Redis (`redis-server`, `redis-cli`) | `tests/services/redis.test.js`, local run | yes (`/opt/homebrew/bin`) | not probed | start locally and set `REDIS_URL=redis://localhost:6379` to make the one failing suite pass |
| Supabase CLI | applying BACK-14 migration (user) | yes (`~/.nvm/.../bin/supabase`) | not probed | dashboard SQL editor |
| Stripe CLI | local test-mode checks | yes (`/opt/homebrew/bin/stripe`) | not probed | dashboard |
| Non-production Supabase project | D-13 local run | UNKNOWN | — | Open Question 7; without it, rely on mocked-Stripe unit tests only |
| Docker, psql | — | no | — | not needed |

**Missing with no fallback:** none for coding. A non-prod Supabase for the D-13 local run is unconfirmed.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30.4.2 + supertest 7.2.2 (mock-based: `supabaseAdmin`, Stripe, Redis, events are `jest.mock`ed; no real DB) |
| Config file | `jest.config.js` (`setupFiles: tests/setup.env.js` placeholders, `testMatch: **/tests/**/*.test.js`) |
| Quick run command | `cd "/Users/LeonChen/Documents/ClickMe2026 Backend" && npm test -- tests/<file>.test.js` |
| Full suite command | `npm test` (about 11 s). Baseline today: 124/125 suites, 2664 pass; only `tests/services/redis.test.js` fails (needs `REDIS_URL`) |
| Contract gates | `npm run check-openapi-coverage` and `npm run check-doc-coverage` (both OK, 128 endpoints) |

### Phase Requirements → Test Map
| Req | Behavior | Test type | Automated command | File exists? |
|-----|----------|-----------|-------------------|-------------|
| BACK-09 | first/reconnect windows, status gate, TTL | unit + supertest | `npm test -- tests/call.test.js` (replace local 120/120 mirror at L134-135) | exists, edit |
| BACK-12 | cancel after `end_time` rejected; before end ok | supertest | `npm test -- tests/clientBooking.test.js` | exists, edit |
| BACK-14 | reason written in UPDATE (client + expert) | supertest | `npm test -- tests/clientBooking.test.js tests/expertBooking.test.js` | exists, edit |
| BACK-19 | expert cancel, PI `succeeded` within 24 h → full refund; `requires_capture` → void | supertest + mocked stripe | `npm test -- tests/expertBooking.test.js` | exists, edit |
| BACK-10/15 | past start 422, duration mismatch 422; confirm replay 201 for same client, 409/`SLOT_UNAVAILABLE` for foreign | supertest | `npm test -- tests/booking.test.js` | exists, edit |
| BACK-01/02 | accept message creates chat message + emit + push; decline note on client detail only when `declined` | supertest | `npm test -- tests/bookingRequests.test.js tests/clientBooking.test.js` | exists, edit |
| BACK-03/05 | `has_review` in feed/detail/summary; currency digits/symbol | supertest | `npm test -- tests/expertBooking.test.js tests/bookingRequests.test.js` | exists, edit |
| BACK-04/11 | `meeting_url` null/"" accepted; bounds 422 | supertest + schema | `npm test -- tests/expertProfile.test.js tests/expertTopics.test.js tests/onboarding.test.js tests/schemas/expertProfile.schema.test.js` | exists, edit |
| BACK-06/07 | lone default; delete evicts clones + detaches on connected acct; tolerant of `resource_missing` | supertest + mocked stripe | `npm test -- tests/paymentMethods.test.js tests/services/connectedPaymentMethodClone.test.js` | exists, edit |
| BACK-13/08 | classification table: client-only read 200 w/o promotion, write 403; stale-JWT allowed; setup promotes; route-level sweep | unit + supertest | `npm test -- tests/middleware/ensureExpert.test.js` + one new table-driven `tests/expertRoutesGate.test.js` | middleware test exists (rewrite); new file Wave 0 |
| BACK-16a/b | empty thread listed and ordered last; 6th feedback in window → 429 | supertest | `npm test -- tests/chats.test.js tests/feedback.test.js` | exists, edit |
| BACK-17 | iOS, Android and platform-less tokens all carry category/sub_category/target_role; Android channel stays Android-only; every call site passes target_role | unit | `npm test -- tests/push.test.js` (invert the Phase 13 D-04 iOS tests at ~L732-900) + cron/event tests | exists, edit |
| BACK-18 | send recompute for recipient; `message.read` recompute for reader; system messages not counted | unit | new `tests/socket.messageRead.test.js` | **Wave 0 gap** (no socket test exists; extract handler) |
| All | existing response key sets unchanged (additive only) | contract | new `tests/contract.responseShapes.test.js` asserting key sets of GET /client/bookings/:id, GET /chats, POST /bookings/confirm 201, POST /bookings/:id/join 200, GET /expert/profile | **Wave 0 gap** |

### Sampling Rate
- **Per task commit:** the targeted test file(s) above, about 1-3 s each.
- **Per wave merge:** `npm test` plus both coverage scripts.
- **Phase gate:** full suite green (with `REDIS_URL` set so the redis suite also passes) and coverage scripts OK before each "ready to push" handoff.
- **After each deploy (user):** manual smoke on build 6 and Android: sign in, free booking, paid booking, pay, join call, chat; plus wave-specific rows (wave 1: tap a confirmed/declined push on build 6 and confirm it opens the booking; wave 2: rejoin a call at end+30; wave 3: add/delete a card, expert-cancel with real test card, client-only account opens expert home).

### Wave 0 Gaps
- [ ] `tests/contract.responseShapes.test.js`: locks current key sets (D-12)
- [ ] `tests/socket.messageRead.test.js` + exported handler in `src/services/socket.js`
- [ ] `tests/expertRoutesGate.test.js`: table-driven over the classification table
- [ ] shared supertest helper for authenticated app with configurable `roles` (each suite currently re-declares the `authenticate` mock)
- [ ] none needed for framework install (Jest already present)

## Security Domain

`security_enforcement` is enabled (`config.json`: `security_enforcement: true`, ASVS level 1, block on high).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no change | existing JWKS verification |
| V3 Session Management | partial | stale-JWT role handling (Pitfall 1); roles never from body |
| V4 Access Control | **yes** | BACK-13 server-side gate; BACK-15 replay must verify `client_id === req.user.id`; BACK-09 participant + status checks; BACK-07 IDOR on PM ownership (existing 404-not-403 stays) |
| V5 Input Validation | **yes** | zod `.strict()` schemas; bounds (BACK-11); past-date and duration checks (BACK-10) |
| V6 Cryptography | no | none added (TIN encryption untouched) |
| V8 Data Protection | yes | free-text decline/cancel/accept text must not enter FCM `data` beyond what is needed, never logged |
| V11 Business Logic | **yes** | idempotent replay, cancel-after-end guard, atomic status-guarded money transitions |
| V13 API | yes | per-user rate limit on feedback; closed error-code enum documented |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Privilege escalation by touching any `/expert/*` route | Elevation | explicit promotion route only (BACK-13) |
| Replay returning another user's booking | Information disclosure | ownership check before replay (BACK-15) |
| Charging a removed card via cached clone | Tampering / financial | evict + detach (BACK-07) |
| Free text injected into chat via accept message | Tampering | stored and rendered as plain text; same `content` limits as normal sends |
| Feedback spam | DoS | per-user limiter (BACK-16b) |
| Late refund after session end | Financial | cancel-after-end guard (BACK-12) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | BACK-15 is best implemented as ownership-checked replay keyed on (client, expert, topic, start, PI) with no new column | change map | If production data has duplicate-looking own bookings, replay could pick the wrong row; planner should scope to active statuses |
| A2 | BACK-18 recompute (no RPC) is race-safe enough | change map | Two simultaneous sends could briefly undercount until the next recompute; acceptable for a UX badge |
| A3 | Reusing `403 SESSION_NOT_ACTIVE` for a non-joinable status produces acceptable UI on both clients | BACK-09 | Clients may show "session not started" copy for a cancelled booking; check message text |
| A4 | Tag/language array cap of 50 rejects no legitimate payload | BACK-11 | Valid experts with more tags hit 422; verify production maximum first |
| A5 | RESOLVED, not an assumption: `client_msg_id   TEXT,` is nullable [VERIFIED: supabase/migrations/20260609010000_create_messages.sql:42] and dedup is `CONSTRAINT messages_dedup_unique UNIQUE (thread_id, sender_id, client_msg_id)` (L46), so a server-generated UUID string is safe for the accept message | BACK-01 | none |
| A6 | Moshi/Codable on both clients ignore unknown JSON keys, so additive fields are safe | all additive rows | A strict decoder on an older build would fail on new keys; Android `ResponseDecodingTest.kt` exists and iOS uses `Decodable` structs (default ignores extras) |
| A7 | RESOLVED (2026-11-07 revision), no longer an assumption: the BACK-08 seam trace shows silent promotion by `ensureExpert` is the only code path from a client account to any tax-ID surface; plan 01-21 fixes those seams directly | BACK-08 | none for the fix; whether account B took that path is recorded as BUG-03 background in plan 01-23 |
| A8 | A non-production Supabase project is available for the D-13 local run | Pitfall 9 | Local Stripe run would hit production data |
| A9 | T-24h sweep, after eviction, leaves the booking `scheduled` until the 6 h SCA sweep cancels it | BACK-07 | Different cancel timing than product intends (Open Question 3) |

## Open Questions (RESOLVED)

All nine are closed. Q1, Q3, Q4 and Q7 were decided by the user during plan-phase on 2026-11-07. The user left Q2, Q6, Q8 and Q9 to this research's recommendation, which the named plans adopt. Q5 is closed by the BACK-08 seam trace.

1. **Does the user accept build 6 behavior change F1?** RESOLVED (user decision 2026-11-07): accepted. category, sub_category and target_role ship on iOS payloads in deploy wave 1. Plan 01-02 records it, and the wave-1 smoke in plan 01-10 taps a confirmed and a declined push on build 6.
2. **Empty threads from `POST /chats/initiate` become visible to the other party.** RESOLVED (recommendation adopted): ship as BACK-16 requires; both participants see the empty thread; no visibility column or migration. Recorded in plan 01-08 (assumption and threat T-01-14).
3. **BACK-07 policy for a deleted card that a booking still depends on.** RESOLVED (user decision 2026-11-07): block the delete with `409 PAYMENT_METHOD_IN_USE` while any booking in pending_approval, confirmed, pending_reschedule or in_progress references the card. Otherwise evict and detach the clones, then the platform card. Implemented in plan 01-16; the edges are pinned by tests.
4. **Currency label.** RESOLVED (user decision 2026-11-07): use the currency-table symbol, `CA$12.50 / session`. Implemented in plan 01-05.
5. **BACK-08 root cause.** RESOLVED (2026-11-07 revision): the BACK-08 seam trace above locates every tax-ID surface, and plan 01-21 closes them at the seams (gate plus a `postOnboard` refusal, and the tax-profile GET per the user's Task 2 decision). BACK-08 no longer depends on A7. The read-only check of Android test account B moves to plan 01-23 as background for BUG-03 and does not decide BACK-08.
6. **Unread reset on thread open.** RESOLVED (recommendation adopted): also recompute the caller's counter on `GET /chats/:id/messages` page 1. This is a recount, not a forced zero. Implemented in plan 01-14 Task 3.
7. **Non-prod Supabase for the local Stripe run.** RESOLVED (user decision 2026-11-07): none exists. Stripe changes are verified with mocked-Stripe unit tests plus a post-deploy production smoke on a card the user owns; no local live-Stripe run. The D-13 deviation is recorded in plans 01-16, 01-17, 01-18 and 01-19.
8. **Migration timing for BACK-14.** RESOLVED (recommendation adopted: apply first). The migration is authored in plan 01-10, and the user applies and verifies it (`supabase db push`) at that plan's checkpoint, before the wave-1 push. The code that writes the column ships a wave later, in plan 01-12, so the column is live a full wave before anything uses it.
9. **Tag/language caps and the `price_amount` maximum.** RESOLVED (recommendation adopted): `languages` and `expertise_tags` capped at 50 each, and `amount` capped at 2147483647 (Postgres INTEGER max), each with a hand-written 422 message. Implemented in plan 01-07; A4 stays a monitored assumption.

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Capture at accept | Authorize at booking, capture at end+15 (Sweep C) | Cancel of an unfinished booking is a void; refund logic only matters for captured PIs (F2) |
| Convert-on-demand for any `/expert/*` call | Explicit setup promotion (this phase) | removes silent role escalation |

## Sources

### Primary (HIGH confidence): read this session
- Backend: `src/middleware/ensureExpert.js`, `authenticate.js`; `src/services/agora.js`, `push.js`, `events.js`, `socket.js` (message.read), `connectedPaymentMethodClone.js`, `stripe.js` (createManualPI, createRefund, PM helpers); controllers `call`, `booking`, `clientBooking`, `expertBooking`, `bookingRequests`, `chats`, `paymentMethods`, `expert`, `onboarding`, `connect`, `payouts`, `earnings`, `availability`, `expertTaxProfile`; schemas `booking`, `call`, `chat`, `expertProfile`, `expertTopics`, `onboarding`; `src/middleware/rateLimiter.js`; `src/cron/longLeadChargeSweep.js`; routes for every `ensureExpert` mount; migrations (`create_reviews`, `seed_currencies`, `connected_pm_clones`, `create_chats`, `normalize_currency_to_cad`); `openapi/clickme-api.yaml` (ErrorCode enum), `docs/SOCKET-CONTRACT.md` §6, `docs/DEPLOY-RAILWAY.md`; `jest.config.js`, `tests/setup.env.js`, test headers; `package.json`, `railway.json`, `.env.example` (names only). Baseline `npm test`, `npm run check-openapi-coverage`, `npm run check-doc-coverage`.
- iOS: `Model/Push/PushEvent.swift`, `Managers/PushRouter.swift`, `ClickMe2026AppDelegate.swift` (tap handling), `Splash/SplashViewModel.swift`, `LoginView.swift`, `UserManager.swift`, `ErrorCode.swift`, `StandardErrorResponse.swift`, `ExpertProfileData.swift`.
- Android: `UserManager.kt` (mode switch), `SignupSetupRepository.kt`, `ConversationsUiState.kt`, `ChatPayloads.kt`, `ErrorCode.kt`, `16-BUG-LOG.md` (BUG-03/17/27).

### Secondary / Tertiary
- None. No web sources used; Stripe API behavior claims (detach on connected account via `stripeAccount` option, empty-string default clear) are taken from existing in-repo code and comments, not re-verified against Stripe docs this session. The planner should confirm `paymentMethods.detach(id, {}, {stripeAccount})` behavior during the local test-mode run.

## Project Constraints (from CLAUDE.md)

- Backend owns the API contract: read `openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md`, `docs/ios/`, `src/routes|controllers|schemas` before changing a call; one commit per repo per change; say explicitly when another repo needs a matching change; never assume the other repo already has it.
- iOS is the source of truth for behavior; Android is a port. Backend changes must be additive or safe for current Android and live build 6 (Google Play ~2026-12-13).
- Constraints: Swift 6/iOS 18 apply to later phases only; this phase has no iOS code changes.
- Definition of done: backend tests for every backend change; a clean build; device UAT via checklist; payment/refund changes need extra care (real holds).
- GSD workflow enforcement: file-changing work goes through a GSD command (both repos' CLAUDE.md).
- Backend stack conventions: Express 5, zod, Jest/supertest; header comments record decision IDs (cite this phase's D-ids); `AppError`/`dbError`; field-validation top-level `message`.
- The user pushes to production; Claude commits locally in the backend repo and never pushes (D-11).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new, versions read from `package.json`
- Architecture / change map: HIGH for seams (all read this session), MEDIUM for BACK-07/15/18 design (judgment, flagged ASSUMED)
- Pitfalls: HIGH for 1, 2, 4, 5, 6 (read from code); MEDIUM for 7 (cron not fully read), 9 (env unknown)

**Research date:** 2026-11-07
**Valid until:** 2026-11-21 (fast-moving: backend `origin/main` HEAD was `2ec82af` when researched; re-check `git log` before planning if anyone pushes)
