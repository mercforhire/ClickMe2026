---
phase: 01-backend-fixes
reviewed: 2026-11-09T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - src/controllers/clientBooking.controller.js
  - src/controllers/clientTransactions.controller.js
  - src/controllers/expertBooking.controller.js
  - src/cron/refundReconciliation.js
  - tests/refundRetryFlow.test.js
  - tests/refundReconciliation.test.js
  - tests/expertBooking.test.js
  - tests/clientBooking.test.js
  - tests/clientTransactions.test.js
  - openapi/clickme-api.yaml
  - docs/ios/STRIPE-INTEGRATION.md
  - docs/ios/CLIENT-TRANSACTIONS.md
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 01: Code Review Report (BACK-19, backend range 215adcb..d86bf97)

**Reviewed:** 2026-11-09
**Depth:** standard, with cross-file tracing of the rows the two cancel handlers write and the sweep and read paths later read
**Files Reviewed:** 12 (backend repo `/Users/LeonChen/Documents/ClickMe2026 Backend`)
**Status:** issues_found

## Summary

The change set holds up on the money-critical questions. I traced these paths and found no defect:

- Sweep order: the sweep reads the PaymentIntent before it moves money.
- Double refund: it refunds `min(saved - Charge.amount_refunded, captured - amount_refunded)`. That stays safe with two replicas, a handler `createRefund` with no key that timed out but succeeded, and the cascade and Sweep A keys.
- Amount field: the saved amount is an intent, and the void, refund and clear actions all match the PI state.
- Payment state: every `payment_status` transition the sweep requests is legal in `paymentStateMachine.TRANSITIONS`, and a stale-row 409 is caught as non-fatal.
- Reads: `derivePaymentStatus` has exactly one caller (`getDetail`), and that select now includes `refund_failed`. `refund_amount_minor_units` has no other reader. The webhook `.is.null/.lt` guard cannot corrupt the saved intent. The sweep's final `refund_amount_minor_units` write comes from Stripe.
- Client contract: the cancel response keeps its shape. The iOS cancel screen ignores the cancel response amount.
- Tests: all 368 tests in the five test files pass.

No Critical findings. There are 3 Warnings and 5 Info items. The recorded open items (cascade hold unflagged when retrievePI fails, bank-failed refund, replayed saved error, no push on `reconcileDirectChargeRefunded`) were not re-reported.

## Warnings

### B19-WR-01: A flagged row with no `stripe_account_id` can never clear, and the new "PI state unknown" flag creates such rows

**File:** `src/cron/refundReconciliation.js:98` (sweep), `src/controllers/clientBooking.controller.js:915,963-967` (writer), `src/services/stripe.js:189-193` (`retrievePI` guard)

**Issue:** The old sweep cleared an `intended === 0` row with no Stripe call. The new sweep calls `retrievePI(...)` first for every flagged row. `retrievePI` throws `MISSING_STRIPE_ACCOUNT` before any SDK call when `stripe_account_id` is null. The comment at `clientBooking.controller.js:902` says such pre-Phase-25 rows exist.

The new `else if (piReadFailed) throw` in the client `cancel` handler also flags a row that used to be left clean.

Failure scenario:
- Row: `status=confirmed`, `payment_intent_id=pi_x`, `stripe_account_id=NULL`, start in 2 hours.
- Client cancels. `retrievePI` throws `MISSING_STRIPE_ACCOUNT`, so `piReadFailed=true` and the guess is `succeeded`.
- `computeRefundAmountMinorUnits` returns 0, then the new branch throws.
- The catch writes `{refund_failed: true, refund_amount_minor_units: 0}`. Before this change that cancel wrote no flag.
- Every 30-minute sweep calls `retrievePI` with a null account and throws. The flag never clears.
- If an operator later refunds that charge by hand and the `charge.refunded` webhook records the amount, the row still reads `refund_failed=true`. `derivePaymentStatus` and `GET /client/transactions` then hide the refund that did land, indefinitely.

**Fix:** In `reconcileBooking`, handle the missing account before the Stripe read.
```js
if (!booking.stripe_account_id) {
  if (booking.refund_amount_minor_units === 0) { await clearFlag(booking.id, {}); return; }
  console.error('[cron:refundReconciliation] OPS: flagged booking has no stripe_account_id, manual review needed for booking', booking.id);
  return;
}
```
In the client handler, skip the new throw when the read failed with `MISSING_STRIPE_ACCOUNT` (`err.code === 'MISSING_STRIPE_ACCOUNT'`), because no sweep can ever read that PI either. Add a test for both halves.

### B19-WR-02: The write that creates the retry record never checks its result, in either cancel handler

**File:** `src/controllers/clientBooking.controller.js:980-983`, `src/controllers/expertBooking.controller.js:1257-1260`

**Issue:** `await supabaseAdmin.from('bookings').update(flagUpdate).eq('id', bookingId);` discards the `{ error }` that supabase-js returns instead of throwing. The sweep's `clearFlag` does check it. This update is now the only durable record that the client is owed a refund or void, and this change made it carry the intended amount.

Failure scenario:
- An expert cancels a captured booking and Stripe rejects `createRefund`.
- The flag update then fails (a Supabase 5xx or a timeout).
- The handler logs only the Stripe error and returns 200 with `refund_amount: 0`.
- The booking is `cancelled`, the client stays charged, and nothing is flagged, so the sweep never sees it.

The new tests cannot catch this. Every flag-chain mock resolves `{ error: null }`.

**Fix:** Check the result and log a loud, greppable line that names the booking id. Consider retrying once.
```js
const { error: flagErr } = await supabaseAdmin.from('bookings').update(flagUpdate).eq('id', bookingId);
if (flagErr) {
  console.error('[expertBooking.cancel] OPS: could not flag refund_failed, client may be owed money for booking', bookingId, ':', flagErr.message);
}
```
Add a test where the flag chain resolves `{ error: { message: 'boom' } }`. It should assert the OPS line, and that the response is still 200.

### B19-WR-03: The new "log lines carry the booking id and status only" claim is false, and the sweep's own catch logs Stripe messages

**File:** `src/cron/refundReconciliation.js:55` (claim), `:248-254` (per-row catch)

**Issue:** The header says log lines never carry a PaymentIntent, Charge or account id. The catch logs `rowErr.message` verbatim. This change adds `retrievePI`, `retrieveCharge`, `cancelPI` and `createRefund` to the per-row path. Stripe error text routinely embeds the id, for example `No such payment_intent: 'pi_...'` or `Charge ch_... has already been refunded.`

The repo treats this as a threat (T-12-13, T-28-03), and the new tests assert `not.toContain(PI)` only for the transition-error line. The two handlers also log `stripeErr.message` and have the same exposure.

**Fix:** Log a classified, redacted form in the sweep: `rowErr.code || rowErr.type || 'error'` and `rowErr.statusCode`, without the message. Or run the message through a small scrub (`/\b(pi|ch|acct|re)_[A-Za-z0-9]+/g` replaced with `[id]`). Add a sweep test where `retrievePI` rejects with a message containing the PI id and assert the logged text does not. If the redaction is not wanted, correct the header instead of leaving a claim the code breaks.

## Info

### IN-01: A flag that can never resolve is retried and logged every 30 minutes with no age limit or escalation

**File:** `src/cron/refundReconciliation.js:123,131-139,189-191` (and B19-WR-01)

**Issue:** These states keep the flag set and re-read Stripe on every run:
- PI `processing` or another unexpected status.
- A succeeded PI whose saved amount is NULL. This is the OPS line.
- A succeeded PI with no Charge.
- A missing account.

Each run makes 1 to 2 Stripe reads and writes an error line per stuck row, forever. A real alert gets buried.

The NULL and `succeeded` dead end also covers an expert cancel whose void failed because the PI was captured in the meantime. The requirement says an expert cancel always refunds in full, and that case never auto-resolves. The cause is that the row has no "cancelled by" column to tell it from a client cancel.

**Fix:** Include the row's `updated_at` in the OPS line. Log at most once per N hours per booking, or add a counter or age cut-off that raises a single louder alert. Consider recording who cancelled so the NULL and `succeeded` case can refund an expert cancel in full.

### IN-02: Docs describe only the common flagged state

**File:** `docs/ios/CLIENT-TRANSACTIONS.md:150`, `openapi/clickme-api.yaml:5932,14584-14588`, both cancel handlers' response `message`

**Issue:**
- CLIENT-TRANSACTIONS says a flagged row reads `captured` with `0` and "nothing has come back yet." Two other states exist:
  - A handler `createRefund` that timed out after Stripe accepted it, followed by the `charge.refunded` webhook. That gives `payment_status=refunded` with `refunded_amount=0` for up to 30 minutes, because the ledger hides the amount while the flag is set.
  - A failed void. That gives `requires_capture` (or `scheduled`) with `0`.
- The OpenAPI booking-detail `payment_status` still says "none = free booking or no charge applied". A cancelled booking that was charged, with a failed refund pending, returns `none`. The raw `payment_status` is already selected. This matches the existing cancelled-within-24h behaviour, which also returns `none`, and the code comment calls it deliberate. It still contradicts the ledger's `captured` for the same booking.
- The 200 body keeps the message "Refund processed if applicable." when the response carries a failed refund and `refund_amount: 0`. The tests assert it unchanged, presumably to keep client parity.

**Fix:** Add the extra states to the CLIENT-TRANSACTIONS note. Amend the `none` description to say it includes a cancelled booking whose refund is still being retried. Optionally return `captured` from `derivePaymentStatus` when `refund_failed === true` and the raw status is `captured`.

### IN-03: The end-to-end flow test hides the state it should prove

**File:** `tests/refundRetryFlow.test.js:36-43` (state machine mock), `:150-165` (fixture)

**Issue:**
- `paymentStateMachine` is mocked wholesale, so the sweep's `payment_status` moves are never applied to `row`. Flow B's row is `payment_status: 'captured'` while the PI is `requires_capture`, which cannot occur in production and never exercises `moveToCanceled`.
- Only the expert route is run end to end. The new client-cancel saved-amount-0 path is covered by unit tests on each half only.
- No test covers the sweep's own `select` column list. The detail and transactions tests assert the select string "because a mocked read hides a missing column", but the sweep tests inject rows directly. Dropping `no_show_party` or `payment_status` from the sweep select would pass every test.

**Fix:** Use the real `paymentStateMachine` over the fake row in this file (or have the mock update `row.payment_status`). Add a client-route flow with `retrievePI` rejecting at 2 hours out, then the sweep. Assert `selectChain.select.mock.calls[0][0]` contains `no_show_party` and `payment_status`.

### IN-04: The reconciliation test header is stale and the sweep selects unused columns

**File:** `tests/refundReconciliation.test.js:3-18`, `src/cron/refundReconciliation.js:233`

**Issue:** The header still says "RED scaffolds: all tests in this file MUST FAIL until Wave 2 implements", and it says the sweep queries `status='cancelled'` only. The sweep selects `amount_paid_minor_units` and `currency`, but `reconcileBooking` and `reconcileCaptured` use neither (the "never assume `amount_paid_minor_units`" rule is the reason). The old tests also never cover a `clearFlag` result with `error` set, so the throw at `clearFlag` is untested.

**Fix:** Rewrite the header, drop the two unused columns, and add a test where the update chain resolves `{ error: { message } }` and the next run still works.

### IN-05: The uncaptured-state list now exists in four places

**File:** `src/cron/refundReconciliation.js:72`, `src/services/accountCascade.js:43`, `src/controllers/clientBooking.controller.js:919`, `src/controllers/expertBooking.controller.js:1206`

**Issue:** The list of PaymentIntent statuses meaning "void, not refund" is duplicated three times as a constant and inline in the two controllers. A future status change must be made in all four, or void-versus-refund will differ between the handler and the sweep.

**Fix:** Export one `UNCAPTURED_PI_STATES` constant from `src/utils` or `services/stripe.js` and use it in all four places.

---

_Reviewed: 2026-11-09_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
