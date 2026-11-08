# Phase 1: Backend Fixes - Context

**Gathered:** 2026-11-07
**Status:** Ready for planning

<domain>
## Phase Boundary

The production backend (`../ClickMe2026 Backend`, Node/Express/Supabase, Railway) validates, stores and returns everything the iOS fixes depend on: BACK-01 to BACK-18, plus the Q2 expert-cancel refund change pulled forward from Phase 3 (D-17). Every change is additive or otherwise safe for current Android (Google Play ~2026-12-13) and for the live App Store iOS build 6, because the backend is shared and live. All work is committed in the backend repo. `openapi/clickme-api.yaml` and `docs/SOCKET-CONTRACT.md` are updated with every contract change. No iOS code changes in this phase.

</domain>

<decisions>
## Implementation Decisions

### Push routing (Q6 → BACK-17)
- **D-01:** Q6 is settled as **backend route**. BACK-17 stays in scope: send `category` and `sub_category` in the FCM `data` map for iOS tokens too, not only Android (`src/services/push.js` ~L270-274, Phase 13 D-04 Android-only branch). All senders, including the reminder, no-show, review-nudge and long-lead crons, already pass category/sub_category to `sendPushToUser`, so this is mainly removing the platform check for the data fields. The Android-only `android.notification.channelId` and visibility block stays Android-only. Build 6 parses only `event_type`, so the extra keys are ignored there (safe). Phase 2's PUSH-01 routes on `category`/`sub_category`, with nil or unknown falling back to the notifications list.
- **D-02:** BACK-17 also adds a per-recipient **`target_role`** field (`client` | `expert`) to the push data for both platforms, so iOS PUSH-02 can switch mode before routing. Compute it per recipient (e.g. recipient === booking.expert_id → `expert`). Android ignores it until it is used. Every `sendPushToUser` call site must supply or derive it. Record it in the OpenAPI/push docs.

### Join window and rejoin (BACK-09)
- **D-03:** `/bookings/:id/join` uses a **two-tier gate**, applied separately to each party:
  - First join (that party's `client_joined_at` / `expert_joined_at` is NULL): the CALL-02 rule, now ∈ [start − 60 min, max(end, start + 60 min)].
  - Reconnect (that party's joined_at is already set): allowed until end + 60 min, matching CALL-01 overtime.
  - This replaces the current [start − 120, end + 120] in `isWithinSessionWindow` (`src/services/agora.js`). Make sure the Agora token TTL still covers the end+60 reconnect horizon.
- **D-04:** `/join` adds a status check. Allowed: `confirmed`, `in_progress`, `completed`, the same set as `JOINABLE_STATUSES` in `clientBooking.controller.js`. `completed` stays allowed so a reconnect still works after the end+15 cron completes the booking. All other statuses are rejected with a clear error code (planner picks 403 vs 409 and the code name, and documents it).
- **D-05:** **Leave the end+15 completion/capture cron as is** (`src/cron/expirePastSessions.js`, `AUTO_COMPLETE_GRACE_MS`). The price is fixed, so capturing at end+15 is correct. Optional and low-risk: `/end` can update `actual_duration_secs` when an overtime call ends after the cron ran. No change to the capture or payout path.
- **D-06:** Display helpers (`canJoinWindow` in clientBooking, `canJoin` in expertBooking, currently 5-min-before) should match the CALL-02 rule, so the `can_join`-style flags the server returns agree with the gate. The planner checks how build 6 and Android use these flags before changing them.

### Expert promotion (BACK-13)
- **D-07:** Only **`PATCH /expert/profile/setup`** promotes a client to expert (keeps the current `ensureExpert` provisioning: `expert_profiles` upsert, `app_metadata` roles, `profiles.roles`, in-memory grant). No new endpoint, because build 6 and current Android already call setup during onboarding. — **Reversibility:** costly — every `/expert/*` route's middleware changes, and both shipped clients depend on the new contract
- **D-08:** For a client-only account, every other `/expert/*` route:
  - **GET/read routes** return an empty or "not set up" response (e.g. a profile with `setup_completed: false`, empty lists, zero earnings) **without promoting**, so build 6's expert home (reachable from `ModeSwitchView` for any role) shows an empty state instead of errors.
  - **Write routes** return **403 `EXPERT_SETUP_REQUIRED`** (new error code, added to the OpenAPI error enum).
  - The planner lists every route mounted with `ensureExpert` (expert.js, onboarding.js, expertTopics.js, bookingRequests.js, expertClients.js, payouts.js, connect.js, earnings.js, clientTransactions.js, expertTaxProfile, …) and classifies each one. Check what build 6 and Android call before setup completes (e.g. Connect onboarding and availability during setup may need to stay allowed, or be called only after setup).
- **D-09:** **No data migration.** Accounts already promoted by accident (expert role, setup not completed, no topics) are left alone. iOS SIGN-06 (Phase 5) sends incomplete-setup experts to the setup hub. There is still no downgrade path (T-19-01 stays deferred).

### Deploy and rollout
- **D-10:** Deploy in **risk-grouped waves**, and check each wave before the next:
  1. **Additive data and validation:** BACK-17 push fields + `target_role`, BACK-03 `has_review`, BACK-02 decline note, BACK-05 currency digits/symbol, BACK-04 clearable `meeting_url`, BACK-10 request validation, BACK-11 bounds, BACK-14 reason storage, BACK-16 (empty threads, feedback rate limit), BACK-01 accept message to chat.
  2. **Behavior changes:** BACK-09 join gate, BACK-12 cancel time guard, BACK-15 idempotent confirm replay, BACK-18 unread counts.
  3. **High-risk, each deployed separately:** Stripe card fixes (BACK-06, BACK-07, BACK-08), the Q2 expert-cancel full refund (D-17), and BACK-13 promotion.
  - The planner may adjust wave membership, but must keep money paths and BACK-13 isolated.
- **D-11:** **The user pushes to `origin/main`** (production deploy) themselves. Claude commits locally in the backend repo (local `master` tracks `origin/main`) and never pushes. Each wave ends at a handoff: "wave N ready to push".
- **D-12:** Verify each wave with: the backend test suite passing (`tests/`), contract tests that lock the existing response shapes build 6 and Android rely on (additive fields only), and a **manual smoke checklist** after each deploy, on both build 6 and current Android: sign in, book (free and paid), pay, join a call, chat. The planner writes the checklist per wave.
- **D-13:** Stripe changes (BACK-06/07/08 and D-17) are verified with **unit tests using a mocked Stripe**, plus a **local backend run with Stripe test-mode keys**, before the wave is pushed: card delete evicting `connected_pm_clones`, lone-card default promotion, the tax-ID prompt, and the expert-cancel refund.

### Second-round items
- **D-14:** **BACK-01:** when an expert accepts with an optional `message`, post it as a normal chat message from the expert in the client–expert chat thread, creating the thread if needed, so it shows in Chats and sends the usual chat push and socket event. No new client UI. The iOS accept-message field stays (Phase 6 does not remove it).
- **D-15:** **BACK-16:** keep NOTIF-07 (time-based notification expiry, `is_read` removed on purpose). **Drop the "notifications can be marked read" sub-item**, recording NOTIF-07 as the reason. BACK-16 now covers only: `GET /chats` lists empty threads, and `/feedback/submit` is rate-limited. Update REQUIREMENTS.md and the ROADMAP success criterion 4 to match.
- **D-16:** BACK-18 as in the inventory: increment the recipient's unread count on send (`chats.controller.js` ~L446-451, currently commented out) and reset it on `message.read` (`services/socket.js` ~L303-308).
- **D-17:** **Q2 is settled now: an expert-initiated cancel always gives the client a full refund**, or releases the hold, whenever it happens. Today expert cancel uses the binary 24 h rule (`expertBooking.controller.js` ~L1063-1140, `utils/refund.js`), so an expert cancelling a charged long-lead booking within 24 h currently refunds 0. Client-initiated cancel keeps the 24 h rule. This is backend work in the wave-3 money group (D-10). Phase 3's EXP-11 copy then keeps promising a full refund, and BOOK-08 (client cancel preview) still follows the 24 h rule. A matching Android copy check is logged as a follow-up. Add this to REQUIREMENTS.md (new backend item, e.g. BACK-19) and the Phase 1 roadmap. — **Reversibility:** costly — it changes live refund behavior on real charges, and copy on both clients depends on it

### Claude's Discretion
- Exact error code names and HTTP statuses for the rejected join status (D-04), BACK-10 validation, the BACK-12 cancel guard and BACK-11 bounds, following existing `AppError` conventions and field-validation `message`s (quick-261103-nnw).
- How BACK-15 stores and replays the confirm result (attempt-keyed lookup of an existing booking vs a stored response).
- How BACK-05 maps currency to digits and symbol (reuse an existing currency util if one exists).
- How "empty" responses look per GET route for non-experts (D-08), as long as build 6 decodes them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and inventory
- `.planning/ROADMAP.md` (Phase 1 section): goal, success criteria, notes
- `.planning/REQUIREMENTS.md` (Backend section, BACK-01 to BACK-18; also CALL-01, CALL-02, PUSH-01, PUSH-02, SIGN-06, BOOK-08, EXP-11 for the matching iOS behavior)
- `.planning/IOS-BUG-INVENTORY.md`: rows K1 to K16, N1, H7, B7, B13, P2, S7, E13 (source evidence with file:line pointers)
- `.planning/PROJECT.md`: constraints (Android/build-6 compatibility, production data, cross-repo commits)

### Backend contract (in `../ClickMe2026 Backend`)
- `openapi/clickme-api.yaml`: REST contract; update with every change
- `docs/SOCKET-CONTRACT.md`: socket events (`message.new`, `message.read`, unread counts)
- `docs/ios/`: per-feature client specs

### Backend code touched by the decisions
- `src/services/push.js`: iOS/Android data branch (D-01, D-02), in-app notifications row write
- `src/cron/reminderNotification.js`, `src/cron/noShowNotification.js`, `src/cron/reviewNudgeNotification.js`, `src/cron/longLeadChargeSweep.js`: push senders and their category/sub_category
- `src/controllers/call.controller.js`: `/join`, `/end`, joined_at stamping (D-03 to D-05)
- `src/services/agora.js`: `isWithinSessionWindow`, JOIN_LEAD/JOIN_GRACE, token TTL (D-03)
- `src/cron/expirePastSessions.js`: end+15 completion and capture (D-05, unchanged)
- `src/controllers/clientBooking.controller.js`: `JOINABLE_STATUSES`, `canJoinWindow`, client cancel (BACK-12, BACK-14)
- `src/controllers/expertBooking.controller.js`: `canJoin`, expert cancel and refund (D-06, D-17)
- `src/utils/refund.js`: `computeRefundAmountMinorUnits` (D-17)
- `src/middleware/ensureExpert.js` and every route that mounts it (`src/routes/expert.js`, `onboarding.js`, `expertTopics.js`, `bookingRequests.js`, `expertClients.js`, `payouts.js`, `connect.js`, `earnings.js`, `clientTransactions.js`, expertTaxProfile route via `index.js`) (D-07, D-08)
- `src/controllers/notificationPrefs.controller.js`: NOTIF-07 rationale (D-15)
- `src/controllers/chats.controller.js`, `src/services/socket.js`: unread counts (D-16), accept message into chat (D-14)
- `railway.json`: deploy config (single replica, `/health` check)

### iOS consumers (read-only in this phase, for compatibility checks)
- `ClickMe2026/Model/Push/PushEvent.swift`, `ClickMe2026/ClickMe2026AppDelegate.swift`: build 6 push parsing
- `ClickMe2026/Views/Screens/Splash/SplashViewModel.swift`, `ClickMe2026/Network/APIRequestURLs.swift`: build 6 expert-route usage

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sendPushToUser(userId, { title, body, data, category, sub_category, is_expert_only })`: one push choke point. The D-01 and D-02 changes go here and at its call sites.
- `ensureExpert` provisioning steps (a) to (d): move them into the setup route only (D-07). The fast path for real experts stays unchanged.
- `JOINABLE_STATUSES` (clientBooking): reuse for the `/join` status check (D-04).
- `computeRefundAmountMinorUnits` (`utils/refund.js`): keep for client cancel; expert cancel bypasses it for a full refund (D-17).
- `AppError` + `dbError` (`src/utils/errors.js`) and the field-validation top-level `message` (quick-261103-nnw) for every new 4xx.
- `tests/`: existing Jest-style backend suite, to extend per change.

### Established Patterns
- Header comments in controllers and middleware record decision IDs (CALL-0x, D-xx, T-xx). Keep that style and cite this phase's D-ids.
- Atomic UPDATE with a status guard for money transitions (T-04-20). Keep it in the D-17 change.
- Booking ids are canonicalized to lowercase `booking.id` (G-11-6). Keep this for any new join/rejoin logic.
- The FCM data map must hold only string values (WR-05), so `target_role` must be a string.

### Integration Points
- Push data → iOS `PushEvent` (Phase 2, PUSH-01/02) and Android's existing category router.
- `/join` → iOS CALL-02/CALL-01 and the Android join button. Error codes have to be ones both clients can map.
- `/expert/*` empty responses → build 6 `ModeSwitchView` → expert home; iOS SIGN-06 (Phase 5).
- Expert cancel refund → Phase 3 EXP-11 copy, plus an Android copy follow-up.

</code_context>

<specifics>
## Specific Ideas

- Build 6 currently promotes any client who just opens Expert mode, because the expert home calls `GET /expert/profile`. D-08's non-promoting reads are what keep build 6 usable after the fix.
- The long-lead booking is charged at T-24h, so an expert cancel within 24 h refunds 0 today. This is the concrete case D-17 fixes.
- Waves end with a "ready to push" handoff to the user. Claude never pushes to the production remote.

</specifics>

<deferred>
## Deferred Ideas

- Demoting accounts promoted by accident, or any expert→client downgrade (T-19-01): not done (D-09).
- Notification read state (`read_at` + mark-read endpoint): rejected for now in favor of NOTIF-07 (D-15).
- Deferring the end+15 cron while an overtime call is still running: rejected (D-05); revisit only if duration or earnings reporting needs it.
- Android copy update for the expert-cancel full refund (D-17): a follow-up in `ClickMe_Android`.

</deferred>

---

*Phase: 01-backend-fixes*
*Context gathered: 2026-11-07*
