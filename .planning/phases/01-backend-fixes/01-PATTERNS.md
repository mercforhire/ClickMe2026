# Phase 1: Backend Fixes - Pattern Map

**Mapped:** 2026-11-07
**Files analyzed:** 22 (new or modified, backend repo)
**Analogs found:** 22 / 22 (one new-file analog is partial)

**All paths are relative to the backend repo root `/Users/LeonChen/Documents/ClickMe2026 Backend`** (local branch `master`, tracks `origin/main`; Node 22, Express 5, zod, Jest + supertest, mock-based). No iOS code changes in this phase. Every analog below was checked as git-tracked (`git ls-files`) in the backend repo.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `supabase/migrations/2026110xxxxxxx_bookings_cancellation_reason.sql` (new, BACK-14) | migration | batch (DDL) | `supabase/migrations/20261017000100_chats_blocked_by.sql` | exact |
| `src/services/push.js` (BACK-17) | service | event-driven (FCM fan-out) | itself, L255-290 (Phase 13 D-04 branch) | exact (in place) |
| `tests/push.test.js` (invert iOS tests) | test | event-driven | itself, L730-800 `android channel and data (Phase 13 D-04)` | exact (in place) |
| `src/middleware/rateLimiter.js` (+`feedbackLimiter`, BACK-16b) | middleware | request-response | `withdrawLimiter` in same file, L164-178 | exact |
| `src/routes/feedback.js` | route | request-response | itself, L26 | exact (in place) |
| `tests/feedback.test.js` (429 on 6th) | test | request-response | itself, header L1-47 | exact |
| `src/services/agora.js` (BACK-09 `evaluateJoinWindow`) | utility | transform | itself, L51-56, L107-112 | exact (in place) |
| `src/controllers/call.controller.js` (`join`) | controller | request-response | itself, L50-90 | exact (in place) |
| `tests/call.test.js` (replace 120/120 mirror) | test | request-response | itself, L1-60 | exact |
| `src/middleware/ensureExpert.js` (split gates, BACK-13) | middleware | request-response | itself, L1-118 | exact (refactor) |
| `src/routes/*.js` mounting `ensureExpert` (expert, onboarding, expertTopics, bookingRequests, expertBooking, availability, earnings, payouts, connect, expertTaxProfile, analytics, expertClients) | route | request-response | `src/routes/feedback.js` header style for route docs | partial |
| `tests/middleware/ensureExpert.test.js` (rewrite) | test | request-response | itself, L1-60 | exact |
| `tests/expertRoutesGate.test.js` (new, table-driven) | test | request-response | `tests/call.test.js` supertest + authenticate mock | role-match |
| `src/controllers/paymentMethods.controller.js` (BACK-06/07) | controller | CRUD + Stripe | itself, `deletePaymentMethod` L186-241 | exact (in place) |
| `src/services/stripe.js` (`detachPaymentMethod(pmId, stripeAccountId?)`) | service | request-response | existing `detachPaymentMethod` | exact (in place) |
| `tests/paymentMethods.test.js` | test | request-response, mocked Stripe | itself, L28 `jest.mock('../src/services/stripe', ...)`, L283 DELETE block | exact |
| `src/controllers/chats.controller.js` (`send` unread, list empty threads) | controller | CRUD | itself, L425-490 | exact (in place) |
| `src/services/socket.js` (`message.read` handler, exported) | service | event-driven | itself, L283-320 | exact (in place) |
| `tests/socket.messageRead.test.js` (new) | test | event-driven | `tests/call.test.js` supertest-free mock pattern (supabase chain mock L21-36) | partial |
| `src/controllers/expertBooking.controller.js` (BACK-19, BACK-03, BACK-05) | controller | CRUD + Stripe | itself (`cancel`, captured branch) | exact (in place) |
| `src/controllers/clientBooking.controller.js` (BACK-12, 14, 02) | controller | CRUD | itself (`cancel` L801+) | exact (in place) |
| `src/controllers/bookingRequests.controller.js` (BACK-01, 05) | controller | CRUD + event | `src/controllers/chats.controller.js` `send` (shared helper source) | role-match |
| `src/services/chatMessages.js` (new, BACK-01/18 shared) | service | CRUD + event-driven | `chats.controller.js` `send` L425-490 | role-match |
| `src/utils/currency.js` (new, BACK-05) | utility | transform | `minorUnitDigitsFor` in `src/utils/earnings.js` (ZERO_DECIMAL set ~L25) | role-match |
| `src/controllers/booking.controller.js` (BACK-10, 15) | controller | request-response | itself (`createRequest` L1458+, `confirm` L630-700) | exact (in place) |
| `src/schemas/expertProfile.schema.js`, `expertTopics.schema.js`, `onboarding.schema.js` (BACK-04/11) | schema | validation | `src/schemas/booking.schema.js` (L63-74 strict, L119 cancelSchema) | role-match |
| `openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md`, `docs/ios/*.md` | config/docs | contract | `ErrorCode` enum at `openapi/clickme-api.yaml:11721+` | exact |

Note on the requested "409 on card delete" analog: D-10 / Open Question 3 leave open whether deleting a card in use is blocked with 409 (RESEARCH recommends hard-decline in the T-24h sweep instead). If the planner chooses blocking, the analog is in the 409 section of Shared Patterns below.

## Pattern Assignments

### `supabase/migrations/2026110xxxxxxx_bookings_cancellation_reason.sql` (migration, DDL)

**Analog:** `supabase/migrations/20261017000100_chats_blocked_by.sql` (latest tracked migrations are `20261017000200_profiles_drop_phone.sql`; pick a timestamp after it).

**Header + idempotent column pattern** (lines 1-4, 24-29):
```sql
-- 20261017000100_chats_blocked_by.sql
-- Quick 261017-htx: record WHO blocked a chat thread ...
--   blocked_by  UUID NULL  -> FK profiles(id) ON DELETE SET NULL (the first blocker)
-- Replay-safe: every statement is idempotent. Never edit this file once applied; add a new one.

ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS blocked_by UUID NULL REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMPTZ NULL;
```
Apply to BACK-14: `ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT NULL;` Keep the long header style (dependent-object audit: grep migrations for views/RPCs that `select *` from bookings; note RLS and that writes go via service role). Do NOT reuse `cancel_reason` (in-memory enum copied into push data). Handoff must say "user runs `supabase db push` BEFORE pushing code" (RESEARCH Pitfall 2).

---

### `src/services/push.js` (service, event-driven) - BACK-17

**Analog:** itself, L253-290. Remove the `isAndroid` gate for data fields only.

**Current shape to change** (lines 267-275):
```javascript
const isAndroid = platform === 'android';
await messaging.send({
  token,
  notification: { title, body },
  data: isAndroid
    ? { ...safeData, category: String(category || ''), sub_category: String(sub_category || '') }
    : safeData,
  apns: { payload: { aps: { sound: 'default' } } },
  android: isAndroid ? { priority: 'high', notification: { channelId: channelIdFor(category), visibility: 'private' } } : { priority: 'high' },
});
```
Target: `data: { ...safeData, category: String(category || ''), sub_category: String(sub_category || ''), ...(target_role ? { target_role: String(target_role) } : {}) }` for every token; keep `android` block Android-only. `safeData` coercion (L254-258, WR-05) already guarantees string values; `target_role` must be a string too. Add `target_role` to the `sendPushToUser(userId, { ..., target_role })` destructure and default to `'expert'` when `is_expert_only`. Callers per RESEARCH change map: `services/events.js` (booking events), `chats.controller.js:483`, `reviews.controller.js:101`, `account.controller.js:253,469` (omit), `webhooks.controller.js:230`, `connectWebhooks.controller.js:156,219,958`, `cron/reminderNotification.js:88,98`, `cron/noShowNotification.js:95`, `cron/reviewNudgeNotification.js:107`, `cron/longLeadChargeSweep.js:364`.

**Test pattern to invert** (`tests/push.test.js` L737-771, 788-800): `scriptTokens(rows)` queues the pref read then the `device_tokens` read; `IOS_MESSAGE` literal currently has no category. Change `IOS_MESSAGE.data` to include `category: 'booking', sub_category: 'confirmations'`, keep `toEqual` deep-equality, and add a platform-less token case plus a `target_role` case:
```javascript
function scriptTokens(rows) {
  supabaseAdmin.from.mockImplementationOnce(() => ({
    select: jest.fn().mockReturnThis(), eq: jest.fn().mockReturnThis(),
    maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
  }));
  const select = jest.fn().mockReturnThis();
  supabaseAdmin.from.mockImplementationOnce(() => ({
    select, eq: jest.fn().mockResolvedValue({ data: rows, error: null }),
  }));
  admin._mockSend.mockResolvedValue({ messageId: 'msg_ok' });
  return select;
}
...
expect(admin._mockSend.mock.calls[0][0]).toEqual(IOS_MESSAGE);
```

---

### `src/middleware/rateLimiter.js` + `src/routes/feedback.js` (middleware/route, request-response) - BACK-16b

**Analog:** `withdrawLimiter` (rateLimiter.js L164-178), exports line L271.

**Per-user limiter pattern** (copy verbatim, change limit/message):
```javascript
const withdrawLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,                    // v8: 'limit' replaces deprecated 'max'
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  keyGenerator: (req) => (req.user && req.user.id) ? req.user.id : req.ip,
  validate: { keyGeneratorIpFallback: false },
  handler: (req, res) => {
    return res.status(429).json({
      status: 'error',
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many withdrawal attempts. Please try again in 15 minutes.',
    });
  },
});
```
Add `feedbackLimiter` and append it to the `module.exports = { forgotLimiter, ..., reportLimiter }` list (L271).

**Route wiring** (`src/routes/feedback.js` L26): place the limiter before `validate`:
```javascript
router.post('/feedback/submit', validate(submitFeedbackSchema), submitFeedback);
// -> router.post('/feedback/submit', feedbackLimiter, validate(submitFeedbackSchema), submitFeedback);
```
(`authenticate` is global in `routes/index.js`, so `req.user` is set.)

**Test** (`tests/feedback.test.js`): mocks `authenticate` with a fixed user (L16-19) and `supabaseAdmin` chain (L21-45); loop 5 valid POSTs then assert the 6th returns 429 with `body.code === 'TOO_MANY_REQUESTS'`. Note `beforeEach(() => jest.clearAllMocks())` does not reset the in-memory limiter store; use `jest.isolateModules` or a distinct user id per test.

---

### `src/services/agora.js` + `src/controllers/call.controller.js` (BACK-09)

**Analog:** itself.

**Constants to change** (agora.js L51-56):
```javascript
const JOIN_LEAD_MS  = 120 * 60 * 1000; // -> 60
const JOIN_GRACE_MS = 120 * 60 * 1000; // -> 60 (reconnect horizon)
const TOKEN_TTL_AFTER_END_SECONDS = JOIN_GRACE_MS / 1000 + 600; // end+70 min covers reconnect
```
Replace `isWithinSessionWindow(startTime, endTime)` (L107-112, exported at L125) with `evaluateJoinWindow({ start, end, now, alreadyJoined })` per RESEARCH "Two-tier join gate" code example; keep `isWithinSessionWindow` exported only if other callers exist (grep first).

**Controller seam** (call.controller.js L57, L70-73): extend the select with `client_joined_at, expert_joined_at`, pick the caller's column, add status check before the window check. Error convention:
```javascript
.select('id, client_id, expert_id, meeting_type, meeting_url, start_time, end_time, status')
...
if (!isWithinSessionWindow(booking.start_time, booking.end_time)) {
  throw new AppError(403, 'SESSION_NOT_ACTIVE', 'Session join window is not active.');
}
```
Reuse `403 SESSION_NOT_ACTIVE` with a distinct message for non-joinable status (RESEARCH A3; both clients already map it). Keep the booking.id lowercase rule (G-11-6) and the first-join-wins stamp (L77-88, `.is(joinedAtCol, null)`) unchanged. Header comments cite decision ids (`T-04-28`, `CALL-02`); add `D-03/D-04`.

**Test** (`tests/call.test.js`): header lines 1-11 describe the old [-120,+120] window and L134-135 mirror it; update both. Mock pattern (L14-36): `authenticate` returns `roles: ['client']`; supabase `makeChain()` with `single`/`maybeSingle`/`update`; `agora-token`, `socket`, `events` mocked.

---

### `src/middleware/ensureExpert.js` (middleware, request-response) - BACK-13

**Analog:** itself. Split into `provisionExpert(req)` (current steps a-d), `expertWriteGate`, `expertReadGate`; export all three, keep default export name stable if tests import it.

**Provision core to preserve** (L72-118): steps (a) `expert_profiles` upsert `{ onConflict: 'id', ignoreDuplicates: true }`, (b) `supabaseAdmin.auth.admin.updateUserById(userId, { app_metadata: { roles: ['client','expert'], role: 'expert' } })`, (c) `profiles.update({ roles, role }).eq('id', userId)`, (d) in-memory `req.user.roles.push('expert')`. Errors go through `next(err)`, never 403. Fast path stays first:
```javascript
if (req.user && Array.isArray(req.user.roles) && req.user.roles.includes('expert')) {
  return next();
}
if (!req.user || !req.user.id) { return next(); }
```
Only `PATCH /expert/profile/setup` (onboarding.js) mounts `provisionExpert`. Write gate: when JWT lacks `expert`, read `profiles.roles` (stale-JWT case, Pitfall 1), augment `req.user.roles`, else `next(new AppError(403, 'EXPERT_SETUP_REQUIRED', 'Finish expert setup to use this feature.'))`. Read gate: same DB check but always `next()`. Use the route classification table in 01-RESEARCH.md (BACK-13 section); regenerate with `grep -rn "ensureExpert," src/routes`.

**Test pattern** (`tests/middleware/ensureExpert.test.js` L16-60): module-level mutable results named `mock*` for Jest hoisting; `supabaseAdmin.from` returns `{ upsert, update }`; add `select/eq/maybeSingle` for the new `profiles.roles` read; hand-rolled `makeRes()` capturing `statusCode`/`body`; fake `req/next` (no supertest).

---

### `src/controllers/paymentMethods.controller.js` + `src/services/stripe.js` (BACK-06/07)

**Analog:** `deletePaymentMethod` (L186-241).

**Ownership + detach pattern** (L197-232, to extend):
```javascript
if (!profile || !profile.stripe_customer_id) {
  throw new AppError(404, 'NOT_FOUND', 'Payment method not found.');   // T-18-11, 404 not 403
}
...
await detachPaymentMethod(pmId);
const customer = await retrieveCustomer(callerCustomerId);
const defaultPmId = customer.invoice_settings && customer.invoice_settings.default_payment_method;
if (pmId === defaultPmId) {
  await clearDefaultPaymentMethod(callerCustomerId);
}
```
BACK-07: before the detach, query `connected_pm_clones` where `platform_payment_method_id = pmId`, call `detachPaymentMethod(cloneId, stripeAccountId)` per row (tolerate Stripe `resource_missing`), then delete rows. This reverses the "append-only / never-evict" header in `src/services/connectedPaymentMethodClone.js`; document why in that header. BACK-06: add `ensureLoneCardDefault(customerId, pmList, defaultPmId)` and call from list and from delete when exactly one card remains; update the PM-01/PM-03 header comments (L24-27: "GET never writes", "Unconditional detach (no 409)").

**Test pattern** (`tests/paymentMethods.test.js`): `jest.mock('../src/services/stripe', ...)` at L28 with per-function mocks; helpers at L82-89 queue `profiles.single` results (`mockProfileSingle.mockResolvedValueOnce({ data: { stripe_customer_id }, error: null })`); DELETE block at L283. Use realistic Stripe shapes (RESEARCH Pitfall 5).

---

### `src/controllers/chats.controller.js` + `src/services/socket.js` (BACK-18, BACK-16a)

**Analog:** `chats.controller.js` `send` L425-450 (unread seam) and `socket.js` `message.read` L283-320.

**Unread seam** (chats.controller.js L425-451): `unreadField` is already computed and the increment is commented out inside the best-effort try:
```javascript
const unreadField = thread.client_id === userId ? 'unread_count_expert' : 'unread_count_client';
try {
  await supabaseAdmin.from('chats').update({ last_msg_at: ..., last_msg_text: preview,
    last_msg_sender_id: userId, updated_at: now }).eq('id', chatId);
  // ... Deferred to a future patch ...
  // void unreadField; // unread increment deferred
} catch (_) { /* non-fatal */ }
```
Recommended (RESEARCH A2): recompute `unread_count_<recipient>` = count of messages with `sender_id != recipient` and `status != 'read'` (system messages have NULL sender and are not counted), written in the same update. Extract this "post a user message" logic into `src/services/chatMessages.js` so BACK-01 (accept message) reuses it.

**Socket read handler** (socket.js L283-320): participant guard via `.or(\`client_id.eq.${userId},expert_id.eq.${userId}\`)`, `messages.update({ status: 'read' }).in('id', message_ids).neq('sender_id', userId)`, then notify partner with `_io.to(partnerId).emit('message.read', { thread_id, message_ids, read_by: userId })`. After the status update, recompute and write the READER's counter. Extract the handler into an exported function (e.g. `handleMessageRead(socket, io, userId, data)`) for testing (Wave 0). Update `docs/SOCKET-CONTRACT.md` section 6.

---

### `src/controllers/expertBooking.controller.js` (BACK-19, BACK-03, BACK-05)

**Analog:** itself. Edit the captured branch of `cancel` (comment `// succeeded (captured) → refund per D-04 binary policy`):
`refundAmountMinorUnits = computeRefundAmountMinorUnits(booking);` -> `booking.amount_paid_minor_units`. Keep the atomic status-guarded UPDATE (T-04-20) and `paymentStateMachine.transition(... 'captured' -> 'refunded')`. Tests (`tests/expertBooking.test.js`) must drive `retrievePI -> status: 'succeeded'` within 24 h and assert full-amount `createRefund`, plus `requires_capture` -> void (RESEARCH F2). BACK-03 `has_review`: one batched `reviews` query `.in('booking_id', ids).eq('reviewer_role','client')` per page in `getFeed`/`getDetails`/`getSummary`. BACK-05 label at L138: use shared `minorUnitDigitsFor` plus a symbol map; do not add a fourth local copy.

---

### `src/controllers/clientBooking.controller.js` (BACK-12, 14, 02)

**Analog:** itself, `cancel` L801+.
```javascript
// select at L806 lacks end_time; cancellable set at L818:
const cancellableStatuses = ['confirmed', 'pending_approval', 'pending_reschedule'];
```
Add `end_time` to select; `if (now >= end_time) throw new AppError(409, 'SESSION_ALREADY_ENDED', '<readable message>')` before the atomic UPDATE; write `cancellation_reason: req.validatedBody.reason ?? null` in that UPDATE (only after the migration is applied). `cancelSchema` (`booking.schema.js` L119-120) already allows `reason: z.string().max(500).optional()`. BACK-02: in `getDetail` add `decline_reason_code/text` only when `status === 'declined'` (shared column with reschedule decline, Pitfall 4).

---

### `src/controllers/bookingRequests.controller.js` (BACK-01, BACK-05)

**Analog:** `chats.controller.js` `send` (above) for message posting. In `accept` (~L216-285), after the status UPDATE and CONFIRMED dispatch, best-effort (never fail the accept): resolve thread (export `ensureThread` from `events.js` or reuse `findThreadForPair` in `services/threads.js`), skip if blocked, insert a `text` message with a generated `client_msg_id` (nullable column, unique per `(thread_id, sender_id, client_msg_id)`), bump `last_msg_*`, emit `message.new`, send chat push. Wrap in try/catch following the `// non-fatal` style at chats.controller.js L447-449.

---

### `src/controllers/booking.controller.js` (BACK-10, 15)

**Analog:** itself. BACK-10 seam: `const topicDuration = duration_minutes || topic.duration_mins || 30;` (L1507) and `requestSchema` (L87-95). Reject past `scheduled_start` and duration mismatch with 422 and a hand-written top-level `message` (not raw Zod text; `RAW_ZOD_MESSAGE` filter in `utils/errors.js`). BACK-15 seams: `confirm` Step 1 (L630-639, currently `409 DUPLICATE_BOOKING`), Step 3 (L697-701), 23505/23P01 handler (L934-951), `createPaymentIntent` Step 3 (L387-390). Replay must verify `booking.client_id === req.user.id` before returning the original 201 body (`booking_id`, `status`, `message`, `estimated_confirmation_time`); `confirmSchema` has no `booking_attempt_id` (F4).

---

### Schemas (BACK-04/11): `expertProfile.schema.js:43,53-58`, `expertTopics.schema.js:77`, `onboarding.schema.js:43-44`

**Analog:** `src/schemas/booking.schema.js` (`.strict()` zod objects, L63-74; `cancelSchema` L119-120). Edits: `meeting_url: z.string().url().max(500).optional()` -> accept `null`/`""` and normalize `""` to `null` in `expert.controller.js:158-159`; `amount: z.number().int().nonnegative()` -> add `.max(2147483647)` (or business cap); `z.array(z.string())` -> `.max(50)` (confirm production max first, A4). Write field messages by hand (quick-261103-nnw top-level message rule). Tests: `tests/schemas/expertProfile.schema.test.js`, `tests/expertTopics.test.js`, `tests/onboarding.test.js`.

---

### `openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md`

Add `EXPERT_SETUP_REQUIRED` and `SESSION_ALREADY_ENDED` to the closed `ErrorCode` enum (`openapi/clickme-api.yaml:11721+`). Document `has_review`, decline note, `target_role`, `cancellation_reason`. No new routes, so `scripts/check-openapi-coverage.js` and `scripts/check-doc-coverage.js` (128 endpoints) must stay green; run `npm run check-openapi-coverage && npm run check-doc-coverage`.

## Shared Patterns

### Authenticate mock with roles (all supertest suites)
**Source:** `tests/call.test.js` L14-17
**Apply to:** every new/edited controller test
```javascript
jest.mock('../src/middleware/authenticate', () => (req, res, next) => {
  req.user = { id: 'test-user-uuid', email: 'user@example.com', roles: ['client'] };
  return next();
});
```
Variants: `tests/feedback.test.js` L16-19 uses `role: 'client'` (no `roles` array). For BACK-13 table-driven tests use a mutable `mockRoles` variable (name must start with `mock`) so each case can flip `['client']` vs `['client','expert']`. RESEARCH Wave 0 proposes a shared helper because each suite re-declares this mock.

### Supabase chain mock
**Source:** `tests/call.test.js` L21-36 and `tests/feedback.test.js` L21-45
**Apply to:** all tests; note RESEARCH Pitfall 5: `mockReturnValueOnce` chains are order-dependent, so adding a query shifts existing chains.
```javascript
jest.mock('../src/services/supabase', () => {
  const makeChain = () => ({
    select: jest.fn().mockReturnThis(), eq: jest.fn().mockReturnThis(),
    single: jest.fn(), maybeSingle: jest.fn(), update: jest.fn().mockReturnThis(),
    then: (resolve) => resolve({ data: null, error: null }),
  });
  return { supabase: { from: jest.fn(() => makeChain()) }, supabaseAdmin: { from: jest.fn(() => makeChain()) } };
});
```
Also mock `../src/services/socket` (`getIo`) and `../src/services/events` (`dispatchBookingEvent`) where the controller imports them (call.test.js L50-63), otherwise `getIo()` is uninitialized in Jest.

### Errors: AppError / dbError, 409 with a standard code
**Source:** `src/controllers/account.controller.js` L85-106 (409 precedent), `src/utils/errors.js`
**Apply to:** every new 4xx (join status, `EXPERT_SETUP_REQUIRED`, `SESSION_ALREADY_ENDED`, optional card-in-use block)
```javascript
if (upErr) return upErr; // surface DB error — do NOT treat as "no bookings"
if (upcoming && upcoming.length > 0) {
  return new AppError(
    409,
    'EXPERT_HAS_UPCOMING_BOOKINGS',
    'You have upcoming bookings. Please complete or cancel them before deleting your account.'
  );
}
```
Pattern: query upcoming rows with `.in('status', ['confirmed','pending_approval','pending_reschedule','in_progress']).gt('start_time', now).limit(1)`, DB error first, then 409 with a user-readable message. If the planner blocks card deletion while an upcoming booking uses the card (Open Question 3), copy this query shape against `bookings.payment_method_id` (verify the column name in `booking.controller.js` before use; not read in this pass). New codes decode leniently on iOS and Android (RESEARCH Pitfall 6), so the `message` must be user-readable.

### Best-effort side effects
**Source:** `src/controllers/chats.controller.js` L430-451, L453-470
**Apply to:** BACK-01 accept message, BACK-18 unread update, any push/emit
```javascript
try { ...update... } catch (_) { /* non-fatal */ }
try { const io = getIo(); io.to(recipientId).emit('message.new', {...}); }
catch (err) { console.error('[chats.send] emit failed (non-fatal, D-06):', err.message); }
```

### Atomic money transition
**Source:** `expertBooking.controller.js` / `clientBooking.controller.js` `cancel` (status-guarded UPDATE, T-04-20) plus `paymentStateMachine.transition`
**Apply to:** BACK-19, BACK-12, BACK-14. Keep the guarded UPDATE; add new columns to the same UPDATE, never a second write.

### Header decision-id comments
**Source:** `src/middleware/ensureExpert.js` L1-60, `src/controllers/paymentMethods.controller.js` L1-32
**Apply to:** every touched controller/middleware: cite this phase's ids (D-03, D-07, D-17, BACK-xx) and update stale lines (e.g. PM-01 "no lazy create", `ensureExpert` "REPLACES roleCheck").

### FCM string-only data
**Source:** `src/services/push.js` L254-258 (WR-05)
**Apply to:** BACK-17 `target_role`, any new push data key: coerce through `safeData`, never pass free text (decline/cancel/accept notes) into `data`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `tests/socket.messageRead.test.js` | test | event-driven | No socket handler test exists; `message.read` is an inline closure in `socket.js`. Extract the handler to an exported function first (Wave 0), then unit test with mocked `supabaseAdmin` and a fake `_io.to().emit()`. |
| `tests/contract.responseShapes.test.js` | test | request-response | No contract-shape suite exists. Use the supertest + authenticate-mock pattern above and assert `Object.keys(res.body.data)` sets for GET /client/bookings/:id, GET /chats, POST /bookings/confirm 201, POST /bookings/:id/join 200, GET /expert/profile. |
| `src/utils/currency.js` symbol map | utility | transform | `minorUnitDigitsFor` exists in `utils/earnings.js`, but no symbol map in code; seeded symbols live in `supabase/migrations/20260603050000_seed_currencies.sql` (e.g. `CA$`). Open Question 4 decides `CA$` vs `$`. |

## Metadata

**Analog search scope:** backend `src/{services,middleware,controllers,routes,schemas}`, `tests/`, `tests/middleware/`, `supabase/migrations/`
**Files read for excerpts:** 01-CONTEXT.md, 01-RESEARCH.md, `push.js` (L225-300), `rateLimiter.js` (L161-271), `feedback.js`, `socket.js` (L275-325), `agora.js` (L40-125), `call.controller.js` (L45-110), `ensureExpert.js`, `chats.controller.js` (L425-490), `paymentMethods.controller.js` (L1-60, L173-262), `account.controller.js` (L85-110), `20261017000100_chats_blocked_by.sql`, `tests/call.test.js`, `tests/feedback.test.js`, `tests/push.test.js` (L730-800), `tests/middleware/ensureExpert.test.js`
**Not re-read (taken from RESEARCH.md line refs, planner should re-open before editing):** `booking.controller.js`, `clientBooking.controller.js`, `expertBooking.controller.js`, `bookingRequests.controller.js`, schemas, `connectedPaymentMethodClone.js`, `events.js`
**Pattern extraction date:** 2026-11-07
