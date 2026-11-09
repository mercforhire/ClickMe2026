---
phase: 01-backend-fixes
verified: 2026-11-09T05:45:22Z
status: human_needed
score: 16/19 must-haves verified (2 by override, not delivered; 3 present, behavior-unverified on real Stripe)
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/phases/01-backend-fixes/01-01-PLAN.md
  - .planning/phases/01-backend-fixes/01-01-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-02-PLAN.md
  - .planning/phases/01-backend-fixes/01-02-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-03-PLAN.md
  - .planning/phases/01-backend-fixes/01-03-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-04-PLAN.md
  - .planning/phases/01-backend-fixes/01-04-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-05-PLAN.md
  - .planning/phases/01-backend-fixes/01-05-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-06-PLAN.md
  - .planning/phases/01-backend-fixes/01-06-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-07-PLAN.md
  - .planning/phases/01-backend-fixes/01-07-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-08-PLAN.md
  - .planning/phases/01-backend-fixes/01-08-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-09-PLAN.md
  - .planning/phases/01-backend-fixes/01-09-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-10-PLAN.md
  - .planning/phases/01-backend-fixes/01-10-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-11-PLAN.md
  - .planning/phases/01-backend-fixes/01-11-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-12-PLAN.md
  - .planning/phases/01-backend-fixes/01-12-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-13-PLAN.md
  - .planning/phases/01-backend-fixes/01-13-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-14-PLAN.md
  - .planning/phases/01-backend-fixes/01-14-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-15-PLAN.md
  - .planning/phases/01-backend-fixes/01-15-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-16-PLAN.md
  - .planning/phases/01-backend-fixes/01-16-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-17-PLAN.md
  - .planning/phases/01-backend-fixes/01-17-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-18-PLAN.md
  - .planning/phases/01-backend-fixes/01-18-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-19-PLAN.md
  - .planning/phases/01-backend-fixes/01-19-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-20-PLAN.md
  - .planning/phases/01-backend-fixes/01-20-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-21-PLAN.md
  - .planning/phases/01-backend-fixes/01-21-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-22-PLAN.md
  - .planning/phases/01-backend-fixes/01-22-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-23-PLAN.md
  - .planning/phases/01-backend-fixes/01-23-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-24-PLAN.md
  - .planning/phases/01-backend-fixes/01-24-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-25-PLAN.md
  - .planning/phases/01-backend-fixes/01-25-SUMMARY.md
  - .planning/phases/01-backend-fixes/01-26-PLAN.md
  - .planning/phases/01-backend-fixes/01-26-SUMMARY.md
covered_digest: "v3:sha256:d26ffdf21d3a0c2053d3e9e7674c80afbe8b290bc3bc886abc61a1a2491df8ab"
behavior_unverified: 3
overrides_applied: 2
overrides:
  - must_have: "BACK-08: A client account is never shown the Stripe tax-ID prompt"
    reason: "Wave 3c dropped by user decision to protect App Store build 6, because it stops client-only accounts from becoming experts there. Not delivered: first-touch promotion and the tax-ID prompt remain in production. Code parked on backend branch wave-3c."
    accepted_by: "Leon chen"
    accepted_at: "2026-11-09T04:14:07Z"
  - must_have: "BACK-13: A client becomes an expert only through an explicit setup call"
    reason: "Wave 3c dropped by user decision to protect App Store build 6, because it stops client-only accounts from becoming experts there. Not delivered: first-touch promotion and the tax-ID prompt remain in production. Code parked on backend branch wave-3c."
    accepted_by: "Leon chen"
    accepted_at: "2026-11-09T04:14:07Z"
re_verification:
  previous_status: gaps_found
  previous_score: 15/19
  gaps_closed:
    - "BACK-19: A failed refund on a cancel is retried as a refund (code delivered at d86bf97, proven on mocked Stripe only)"
    - "BACK-17: build 6 safety question (CR-01) closed by backend 215adcb, which is in production"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
behavior_unverified_items:
  - truth: "BACK-19: A real failed cancel refund is retried as a refund by the sweep, with no second refund"
    test: "Run the 01-19 checklist on real Stripe in test mode (or a low-value live booking): make createRefund fail once on an expert cancel of a captured booking, then let the 30-minute sweep run. Also watch Railway logs for [cron:refundReconciliation] after any real failure"
    expected: "The row ends with refund_failed false and refund_amount_minor_units equal to the amount Stripe shows refunded; the client is refunded once; a repeated reconcile-refund key does not make a second refund; a held booking is voided instead"
    why_human: "Every test mocks Stripe. The Idempotency-Key replay behavior and Charge.amount_refunded semantics are Stripe facts the plan itself marks as backstop. No real failed refund has been observed in production and the user's reply was 'no rows'. The user deferred this to Phase 4 payment UAT"
  - truth: "BACK-06: A lone saved card is made the default"
    test: "01-17 checklist: add one card through PaymentSheet, GET /me/payment-methods, add a second card, delete one, read again"
    expected: "The lone card has is_default true after the first read and after the delete; two cards leave the choice to the user"
    why_human: "Deployed at d356fdc, mocked Stripe only; the real-card smoke was skipped by user decision on 2026-11-08"
  - truth: "BACK-07: A deleted card can no longer be charged through its connected-account clone"
    test: "01-17 checklist: read the clone id from connected_pm_clones, delete the card, confirm the clone is detached on the expert's connected account and the row is gone"
    expected: "Clone detached in Stripe, cache row removed; a card tied to an active booking returns 409 PAYMENT_METHOD_IN_USE"
    why_human: "CLONE_ALREADY_GONE_CODES come from in-repo code, not confirmed against Stripe. The real clone detach has never run"
human_verification:
  - test: "Run the real-Stripe checklists 01-17 (BACK-06, BACK-07) and 01-19 (BACK-19), at the latest during Phase 4 payment UAT"
    expected: "See behavior_unverified_items"
    why_human: "Money behavior on live Stripe; skipped by user decision. BACK-06, BACK-07 and BACK-19 stay Pending in REQUIREMENTS.md until then, which is correct"
  - test: "Optional no-money check of the BACK-19 contract change on App Store build 6 and on current Android: cancel a free or no-payment booking and open Payments history"
    expected: "Cancel completes with no error; a ledger row with refunded_amount 0 renders as it does today"
    why_human: "The user did not report this check (step C of plan 01-26). My code read says both clients cope (see Safety section), but it is a read, not a run on a shipped artifact"
  - test: "BACK-15 confirm replay and BACK-12 late-cancel guard on a device, after a forced confirm timeout"
    expected: "A retried confirm lands on the pending booking; a cancel after end returns SESSION_ALREADY_ENDED with the server message shown"
    why_human: "Waves 1 and 2 smoke was reported 'all passed' with no per-step notes, and replay has no smoke step. Confidence gap, not a failure"
---

# Phase 1: Backend Fixes Verification Report

**Phase Goal:** The production backend validates, stores and returns everything the iOS fixes depend on, and every change stays safe for the current Android build
**Verified:** 2026-11-09T05:45:22Z
**Status:** human_needed
**Re-verification:** Yes, after gap closure (plans 01-24, 01-25, 01-26). Previous status gaps_found, 15/19.

## Verification basis

- Backend repo `/Users/LeonChen/Documents/ClickMe2026 Backend`. `git rev-parse` gives `d86bf97328a81d34b9533b0aee4234fc5522e272` for HEAD, `master` and `origin/main`. `git rev-list --count origin/main..master` is 0. Branch `wave-3c` still exists locally and is not an ancestor of master.
- `GET https://clickme-backend-production.up.railway.app/health` returned `{"status":"success","commit":"d86bf97"}`. Production runs the code I read.
- `REDIS_URL=redis://localhost:6379 npm test`, run once at `d86bf97` with Redis answering PONG: 130 of 130 suites, 3019 of 3019 tests passed (previous run at `3899d63`: 129 suites, 2974 tests).
- `grep -rn "provisionExpert\|expertWriteGate\|EXPERT_SETUP_REQUIRED" src` finds nothing. No wave-3c code is in production.
- `git diff --stat 3899d63..d86bf97 -- src supabase package.json` touches five src files only (the four BACK-19 files plus `push.js` from 215adcb), no migration, no dependency change. `git diff 2ec82af..d86bf97 -- src` adds no TBD, FIXME, XXX, TODO or HACK lines.
- Nothing ran on a device or against real Stripe or Supabase. Every money statement rests on code and mocks.
- The covered-input fingerprint covers planning inputs only. The implementation files live in the backend repo, outside this repo's root, so the fingerprint command cannot cover them. The backend SHA above stands in for them.

## Goal Achievement

### The gap this round re-checked: BACK-19 refund retry

The old defect was: when `createRefund` threw, both cancel handlers set only `refund_failed`, the API reported the full `refund_amount`, and the sweep read the NULL amount as a failed void and retried `cancelPI` on a captured PaymentIntent, so the client was never refunded. I read the code at `d86bf97` against each part of it.

| Plan truth (01-24 / 01-25) | Status | Evidence in code |
|----------------------------|--------|------------------|
| Expert cancel: failed `createRefund` saves `refund_amount_minor_units = amount_paid` with the flag, API returns 200 with `refund_amount` 0 | VERIFIED (mocked) | `expertBooking.controller.js:1183-1185,1232,1250-1262`: `intendedRefundMinorUnits` set after the amount is read, added to `flagUpdate` only when not null, then `refundAmountMinorUnits = 0` |
| Failed void or REFUND_AMOUNT_MISSING writes exactly `{ refund_failed: true }` | VERIFIED (mocked) | `intendedRefundMinorUnits` is set only in the captured branch after the missing-amount throw, so those paths leave it null |
| Sweep reads the PaymentIntent before any money call | VERIFIED | `refundReconciliation.js reconcileBooking`: `retrievePI` is the first Stripe call after the no-PI clear; a throw reaches the per-row catch with the flag left set |
| Succeeded, saved > 0: refund `min(saved - amount_refunded, captured - amount_refunded)` with key `reconcile-refund-{pi}-{toRefund}`, then clear | VERIFIED (mocked) | `reconcileCaptured`; tests for full, already-refunded, partial, partial-capture, expanded charge, no charge, transition rejected |
| Uncaptured: `cancelPI`, never `createRefund`, move to canceled, amount reset to 0, clear | VERIFIED (mocked) | `reconcileBooking` uncaptured branch, `moveToCanceled`, `clearFlag({refund_amount_minor_units: 0})` |
| Canceled PI: no money call, amount 0, flag clears | VERIFIED (mocked) | `reconcileBooking` canceled branch |
| Succeeded with NULL amount: no money call, flag stays, OPS line with booking id | VERIFIED (mocked) | `reconcileCaptured` first guard logs `OPS: captured PaymentIntent with no saved refund amount` |
| `derivePaymentStatus` never returns refunded while `refund_failed` is true | VERIFIED | `clientBooking.controller.js`: `refundLanded = refund_failed !== true && amount > 0`; `getDetail` select now includes `refund_failed`; NULL is treated as not failed |
| Overlap and interruption make no second refund | VERIFIED (mocked) | The amount is derived from `Charge.amount_refunded`, so the second run computes 0. Tests `interrupted after a successful refund` and `two overlapping sweeps` exist |
| Client cancel saves the computed refund with the flag, returns `refund_amount` 0 on failure | VERIFIED (mocked) | `clientBooking.controller.js` catch block, same shape as the expert one; amount is `computeRefundAmountMinorUnits(booking)` |
| Client cancel with `retrievePI` failure inside 24 hours is flagged with amount 0 so the sweep decides from real state | VERIFIED (mocked) | `piReadFailed` guard throws only when the guessed branch owes 0. See B19-WR-01 for a side effect |
| Client cancel inside 24 hours with a working `retrievePI` still makes no Stripe call and sets no flag | VERIFIED | The new throw is gated on `piReadFailed`; `intendedRefundMinorUnits` is set to 0 and no flag results |
| `GET /client/transactions` reports `refunded_amount` 0 while flagged, same keys | VERIFIED | `refund_failed === true ? 0 : (refund_amount_minor_units ?? 0)`; `refund_failed` is selected, never returned |
| Prohibition: never void a client sole no-show hold | VERIFIED | `classifyCaptureEligibility(booking) === 'capture'` clears the flag and returns before `cancelPI`; test `a missed row with no_show_party client is left for Sweep C` exists |
| Prohibition: never refund more than saved minus already refunded | VERIFIED (mocked) | The `Math.min` expression above |
| Prohibition: never refund a captured row with NULL amount | VERIFIED | Same OPS guard |
| Prohibition: no new response field or changed key; `refund_failed` stays server-side | VERIFIED | The diff adds no key to any response |
| Prohibition: no agent push or deploy (D-11) | VERIFIED | The user pushed; `/health`, `origin/main` and `master` agree on `d86bf97` and the range was isolated to the five BACK-19 commits |
| On real Stripe a failed cancel refund is retried, a repeated key makes no second refund, `amount_refunded` reflects prior refunds | PRESENT_BEHAVIOR_UNVERIFIED | Backstop truth in plans 01-24 and 01-26. Mocks cannot show Stripe's behavior. No safe way to force a failure on live data exists. Routes to human verification |

Result: the bug as written is fixed in the code that is deployed. The sweep no longer retries `cancelPI` on a captured PaymentIntent. What is not proven is that Stripe behaves as the mocks assume.

### Observable Truths (one per phase requirement)

| # | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 1 | BACK-01 accept message reaches the client | VERIFIED | Carried forward from the first verification; `src` for the area is unchanged since `3899d63` except the five files listed above, and the full suite is green |
| 2 | BACK-02 decline note on client detail and notification | VERIFIED | Carried forward; `clientBooking.controller.js` changed only in the BACK-19 hunks (diff read in full) |
| 3 | BACK-03 `has_review` | VERIFIED | Carried forward, suite green |
| 4 | BACK-04 expert can clear `meeting_url` | VERIFIED | Carried forward, suite green |
| 5 | BACK-05 currency digits and symbol | VERIFIED | Carried forward, suite green |
| 6 | BACK-06 lone card becomes default | PRESENT_BEHAVIOR_UNVERIFIED | Mocked Stripe only; real-card smoke skipped by user |
| 7 | BACK-07 deleted card not chargeable via clone | PRESENT_BEHAVIOR_UNVERIFIED | Mocked Stripe only; real detach never run. See WR-01 in `01-REVIEW.md` (card removal inside PaymentSheet bypasses this path) |
| 8 | BACK-08 client never shown tax-ID prompt | PASSED (override) | Not delivered; user accepted 2026-11-09. Confirmed absent from master and production |
| 9 | BACK-09 join window and status check | VERIFIED | Carried forward, suite green. WR-06 caveat stands |
| 10 | BACK-10 request validation | VERIFIED | Carried forward, suite green |
| 11 | BACK-11 upper bounds | VERIFIED | Carried forward, suite green |
| 12 | BACK-12 client cancel after end rejected | VERIFIED | Carried forward; the `SESSION_ALREADY_ENDED` guard sits before the BACK-19 hunks and the cancel diff does not touch it |
| 13 | BACK-13 explicit setup call only | PASSED (override) | Not delivered; user accepted 2026-11-09. Phase 5 SIGN-06 still needs a new decision |
| 14 | BACK-14 cancel reason stored | VERIFIED | Carried forward, suite green |
| 15 | BACK-15 confirm retry replay | VERIFIED (mocks only) | Carried forward, suite green; no smoke step exists |
| 16 | BACK-16 empty threads and feedback limit | VERIFIED | Carried forward, suite green |
| 17 | BACK-17 push routing fields | VERIFIED | Payload verified. `push.js:316-324` sends `category`/`sub_category` to Android tokens and `route_category`/`route_sub_category` to iOS and legacy tokens, so build 6 does not receive `category`. That is the pre-phase state for build 6, so no change for shipped builds. The earlier device result (booking push on build 6 lands on client home with no warning) is the user's own report, not something I ran |
| 18 | BACK-18 unread counts | VERIFIED | Carried forward, suite green. WR-04 caveat stands |
| 19 | BACK-19 expert cancel full refund | PRESENT_BEHAVIOR_UNVERIFIED | Code path and failure retry verified above; real Stripe unproven; REQUIREMENTS.md keeps it Pending, which is correct |

**Score:** 16/19 truths verified (2 of them by override, not delivered), 3 present and behavior-unverified (BACK-06, BACK-07, BACK-19).

### ROADMAP success criteria

| SC | Result | Why |
|----|--------|-----|
| 1 Booking requests, cancels, confirms and joins validated and recorded | VERIFIED | Rows 9, 10, 12, 14, 15 |
| 2 Saved cards safe on live Stripe; no tax-ID prompt; expert cancel refunds in full | HUMAN NEEDED | Tax-ID clause covered by the BACK-08 override (not delivered). BACK-06, 07 and 19 are code-complete but unproven on real Stripe |
| 3 Booking and expert data complete; client becomes expert only via setup | VERIFIED with override | Everything but the explicit-setup clause is verified; that clause (BACK-13) is overridden, not delivered |
| 4 Chat and push data correct | VERIFIED | Rows 16, 17, 18 |
| 5 Backend tests for every change; Android and build 6 still work | VERIFIED in code, human confidence gaps | 3019 of 3019 tests pass. "Still work" rests on code reads plus user-reported smoke; see Safety section |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `src/cron/refundReconciliation.js` | read-first sweep | VERIFIED | Contains `retrievePI`, `retrieveCharge`, `reconcileBooking`, `reconcileCaptured`; wired into `startRefundReconciliationJob`, which `app.js` starts |
| `src/controllers/expertBooking.controller.js` | saves intent, reports 0 | VERIFIED | `intendedRefundMinorUnits` present |
| `src/controllers/clientBooking.controller.js` | saves intent, `refund_failed` in read path | VERIFIED | Present, `getDetail` select includes `refund_failed` |
| `src/controllers/clientTransactions.controller.js` | ledger hides unreturned refund | VERIFIED | Present |
| `tests/refundRetryFlow.test.js` | route-to-sweep proof on mocked Stripe | VERIFIED | Flow A and Flow B drive the real route and real sweep. See IN-03 for what it hides |
| Earlier artifacts (migration, `chatMessages`, `unreadCounts`, `pushTargetRole`, `feedbackLimiter`, contract docs) | see first verification | VERIFIED | Unchanged since; suite green |
| `provisionExpert` / `expertWriteGate` (BACK-13, BACK-08) | explicit promotion and gate | MISSING on master (overridden) | On `wave-3c` only |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| expert `cancel` catch block | `sweepFailedRefunds` | `refund_failed` + `refund_amount_minor_units` | WIRED (sweep selects both) |
| client `cancel` catch block | `sweepFailedRefunds` | same | WIRED |
| `refundReconciliation` | `stripe.retrievePI/retrieveCharge/createRefund/cancelPI` | PI status decides action, Charge decides amount | WIRED |
| `getDetail` select | `derivePaymentStatus` | `refund_failed` column | WIRED (single caller) |
| `getClientTransactions` select | `refunded_amount` mapping | `refund_failed` column | WIRED |
| `expirePastSessions` / `accountCascade` flag writers | new sweep | already save amount or NULL | WIRED, behavior preserved |
| earlier links | see first verification | unchanged | WIRED |

### Data-Flow Trace (Level 4)

`refund_failed` and `refund_amount_minor_units` come from the `bookings` table in both writers and both readers; the sweep's final `refund_amount_minor_units` write comes from `Charge.amount_refunded` plus the amount just refunded, not from a literal. No hollow or static source found.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Production runs the verified commit | `GET /health` | commit d86bf97 | PASS |
| Master equals origin/main | `git rev-parse`, `git rev-list --count origin/main..master` | same SHA, 0 | PASS |
| Backend suite | `REDIS_URL=redis://localhost:6379 npm test` | 130/130 suites, 3019/3019 tests | PASS |
| Wave 3c absent | grep for its symbols in `src` | no matches | PASS (confirms the overrides' factual basis) |
| Refund retry behaves on real Stripe | n/a | not run | SKIP, routed to human |

### Probe Execution

No probes declared. Step 7c: SKIPPED.

### Requirements Coverage

All 19 IDs (BACK-01 to BACK-19) appear in the PLAN frontmatter of this phase and in REQUIREMENTS.md. Plans 01-24, 01-25 and 01-26 each claim only BACK-19. No orphans.

| Requirement | Source plans | REQUIREMENTS.md | Verified status |
|-------------|--------------|-----------------|-----------------|
| BACK-01 to BACK-05 | 01-01, 01-05, 01-06, 01-09, 01-10 | unchecked box | SATISFIED in code |
| BACK-06, BACK-07 | 01-16, 01-17 | Pending | UNPROVEN on real Stripe. Pending is correct |
| BACK-08, BACK-13 | 01-20 to 01-23 | Pending | Not delivered, override accepted. Pending is correct |
| BACK-09 to BACK-12, BACK-14 to BACK-16, BACK-18 | various | unchecked box | SATISFIED in code |
| BACK-17 | 01-02 to 01-04, 01-10 | "Gaps Found" | SATISFIED; build 6 safety closed by 215adcb |
| BACK-19 | 01-18, 01-19, 01-24, 01-25, 01-26 | Pending | Code delivered, UNPROVEN on real Stripe. Pending is correct |

Housekeeping: the traceability table in REQUIREMENTS.md still says "Gaps Found" for 12 rows (BACK-01 to 05, 09 to 12, 14 to 18), left from the first verification, and none of the BACK checkboxes is ticked. I did not edit it. The orchestrator should decide whether to update those rows after this report.

### Safety for App Store build 6 and Android (BACK-19 contract change)

The change is behavioral, not structural: no field is added, renamed or removed. Cancel responses can now carry `refund_amount` 0 where they used to carry the full amount after a Stripe failure, and the ledger can carry `refunded_amount` 0 for a flagged row. Both values already occur today (a client cancel inside 24 hours returns 0).

- iOS (`ClickMe2026/` at HEAD equals build 6): the cancel screen builds its refund text from the booking detail, not from the cancel response (`ClientCancellationViewModel.swift:108,117`). `ClientTransactionItem.refundedAmount` is a non-optional `Int`, decodes 0, and `isRefunded` is `refundedAmount > 0`. No decode failure is possible.
- Android (`/Users/LeonChen/Documents/ClickMe_Android`): `CancelBookingData.refundAmount` is `Double = 0.0`, `ClientTransactionsData.refundedAmount` is `Long = 0L`, and unit tests already decode `refund_amount: 0` and `refunded_amount: 0`. The cancel view models show a refund notice only when the amount is above 0.
- Pushes and BACK-17: unchanged by this round except as noted in row 17.

This is a code read of the working trees, not of shipped artifacts. The user did not report the optional no-money check, so it stays a human item with low expected risk.

### Anti-Patterns Found

None blocking. I read both review reports and judged each finding against source.

**`01-REVIEW-BACK-19.md` (range 215adcb..d86bf97), 0 critical, 3 warnings, 5 info.** My assessment:

| Finding | My read of the source | Severity |
|---------|----------------------|----------|
| B19-WR-01 flagged row with no `stripe_account_id` can never clear; the new `piReadFailed` throw creates such rows | Confirmed. `retrievePI` throws `MISSING_STRIPE_ACCOUNT` before any SDK call, the old sweep cleared an amount-0 row with no Stripe call (`git show 215adcb:src/cron/refundReconciliation.js`), the new one reads first. Real, narrow: needs a pre-Phase-25 row with a PaymentIntent and no account. Effect is a stuck flag that hides a later manual refund in detail and ledger | Warning |
| B19-WR-02 the flag write's `{ error }` is never checked in either cancel handler | Confirmed at `expertBooking.controller.js:1257-1260` and the client twin. A failed write would leave a cancelled, charged booking unflagged with a 200 response. This pattern predates the phase, but the write now carries the retry intent | Warning |
| B19-WR-03 header claims logs carry no ids, but the per-row catch logs `rowErr.message`, which Stripe often fills with `pi_`/`ch_` ids | Confirmed as a doc-versus-code mismatch. The two handlers already log `stripeErr.message` the same way | Warning (low) |
| IN-01 stuck flags are retried and logged every 30 minutes forever; an expert cancel whose void failed after the PI was captured elsewhere lands in the NULL plus succeeded OPS dead end | Confirmed. This is a narrow hole in "always refunds in full", handled by manual review | Info, worth tracking |
| IN-02 to IN-05 docs, test fidelity, stale test header, four copies of the uncaptured-state list | Plausible and low impact. IN-03 is accurate: the flow test mocks the state machine, so Flow B's `captured` row with a `requires_capture` PI cannot occur in production | Info |

**`01-REVIEW.md` (earlier range) findings** that I re-read still hold as recorded in the first verification: WR-01 (card removal in PaymentSheet skips BACK-07 checks), WR-02 (BACK-12 blocks release of an unanswered hold after end), WR-03 to WR-07. CR-01 is closed by 215adcb and the user's device results. None changes a verdict here.

No debt markers added in `src` in the phase range.

### Human Verification Required

1. **Real-Stripe checklists 01-17 (BACK-06, BACK-07) and 01-19 (BACK-19)**, at the latest during Phase 4 payment UAT. The user chose that on 2026-11-09. Until then BACK-19 cannot be called proven: all refund tests mock Stripe, and no real failed refund has been seen.
2. **Optional no-money check** of `refund_amount` 0 and `refunded_amount` 0 on App Store build 6 and on Android. Not reported by the user; my code read says safe.
3. **BACK-15 replay and BACK-12 guard** on a device.

### Gaps Summary

No blocking gaps remain. The refund retry bug from the first verification is closed in the deployed code (`d86bf97`): a failed refund now saves the intended amount, the API stops claiming a refund, and the sweep reads Stripe first, then voids, refunds the remainder, or clears the flag. BACK-08 and BACK-13 are carried as accepted overrides and are not delivered. The status is `human_needed` rather than `passed` because BACK-06, BACK-07 and BACK-19 are present and wired but never exercised against real Stripe, and the phase's own plans mark that as a backstop truth that tests cannot establish.

Three review warnings (B19-WR-01 null-account rows, B19-WR-02 unchecked flag write, B19-WR-03 log scrubbing) are real but narrow and none breaks a delivered truth. They are worth a small follow-up plan before Phase 4 payment UAT. They are not gaps against the phase goal.

---

_Verified: 2026-11-09T05:45:22Z_
_Verifier: Claude (gsd-verifier)_
