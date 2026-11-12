---
phase: 04-booking-payment-and-discovery
plan: 01
subsystem: payments
tags: [stripe, webhook, payment-method-detached, cron, long-lead-charge-sweep, backend, D-12, T-01-32, deploy, live-stripe]

requires:
  - phase: 01-backend-fixes
    provides: "BACK-07 evictClonesForPlatformPaymentMethod (connected_pm_clones eviction), the T-24h longLeadChargeSweep, the stripe_events claim and drain"
provides:
  - "payment_method.detached on the platform webhook evicts the removed card's connected-account clones (idempotent, retried on error)"
  - "longLeadChargeSweep.chargeOne checks the platform card before any off-session charge: detached, missing or foreign card takes the existing immediate-cancel path; a transient Stripe error never cancels"
  - "D-12 live in production as the only commit added to main (backend ae3ec1a), platform endpoint reported subscribed to payment_method.detached"
affects: [04-14, Phase 8 release, backend master merge]

# Actuals (#2632). Same scale as the plan estimate: chars/4 over the realized backend diff (27005 chars / 4).
actuals:
  tokens: 6750
  tasks: 3
  commits: 1   # MEASURED in the backend repo: git rev-list --count 32fa6ec..ae3ec1a = 1 (the D-12 commit). No iOS-repo production commits; the iOS repo gets only docs commits.

# Backend repo SHAs (this plan's production commit lives in the backend repo, not the iOS repo)
plan_head_before: 32fa6ecd97a47409c5e7bf4f730b803f7b2fd7e5   # backend origin/main and production before the push (ios-p4-d12-rollback)
plan_head_after: ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d    # backend origin/main and production after the push

tech-stack:
  added: []
  patterns:
    - "Single-commit backend change built in its own worktree on origin/main, pushed alone by explicit refspec behind a re-checking gate, with a recorded rollback branch"
    - "Platform-card check before an off-session charge: only resource_missing, a null customer or a foreign customer cancels; every other retrieve error is re-thrown and leaves the booking scheduled"

key-files:
  created:
    - .planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md
    - .planning/phases/04-booking-payment-and-discovery/04-USER-SETUP.md
  modified:
    - "(backend) src/controllers/webhooks.controller.js"
    - "(backend) src/services/connectedPaymentMethodClone.js"
    - "(backend) src/cron/longLeadChargeSweep.js"
    - "(backend) tests/webhooks.test.js"
    - "(backend) tests/cron/longLeadChargeSweep.test.js"
    - "(backend) docs/ios/STRIPE-INTEGRATION.md"
    - .planning/todos/completed/2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md

key-decisions:
  - "Route (b) chosen by the user before any push: ship the D-12 commit alone now. Backend master was never pushed and carries unreviewed Phase 31 work."
  - "D-12 was built on 32fa6ec (the real origin/main and production base at execution time), not the af47201 the plan names; the base moved before execution."
  - "The webhook logs an evicted count only, never a pm_ id; the sweep logs the booking id only."
  - "A transient retrieve error leaves the row stamped and scheduled (existing catch); only scaRecoveryWindowSweep's 6 h window can cancel it later, and no charge happens."
  - "Android (Stripe SDK 23.24.0) and iOS build 6 (SDK 26.2.0) set no PaymentSheet removal option and both use the SDK default (RESEARCH A5). The server fix covers both; no Android change."

patterns-established:
  - "Backend change for the iOS project: one commit on a branch cut from origin/main, never from master, gated before the user's push"

requirements-completed: [D-12]
# D-12 is a folded todo with no REQUIREMENTS.md ID. BACK-06, BACK-07, BACK-15 and BACK-19 stay Pending until the D-11 session (plan 04-14) passes; none is listed here.
requirements-pending: [BACK-06, BACK-07, BACK-15, BACK-19]

coverage:
  - id: D1
    description: "A verified platform payment_method.detached event for a pm_ id evicts that card's connected-account clones, stamps the event processed (also with zero clones), returns 500 and leaves it unprocessed on an eviction error, and ignores a non-pm_ id, a missing object or a connected-account event"
    verification:
      - kind: unit
        ref: "tests/webhooks.test.js#payment_method.detached (ios-p4 D-12)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The T-24h sweep retrieves the platform card before any clone or PaymentIntent; a detached, missing or foreign card takes cancelAndRelease with no charge; a transient Stripe error (network, rate limit, API error) does not cancel; an attached card charges as before"
    verification:
      - kind: unit
        ref: "tests/cron/longLeadChargeSweep.test.js#platform card check (ios-p4 D-12)"
        status: pass
      - kind: integration
        ref: "REDIS_URL=redis://localhost:6379 npm test (full backend suite, D-12 worktree): 153 suites, 3804 tests passed"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-12 is live in production as the only commit past the rollback base, touching exactly the six D-12 files, and the platform endpoint delivers payment_method.detached"
    verification:
      - kind: other
        ref: "git rev-list --count ios-p4-d12-rollback..origin/main = 1; git diff --name-only ios-p4-d12-rollback origin/main = the six files; curl /health = ae3ec1a"
        status: pass
    human_judgment: true
    rationale: "The Stripe Dashboard event subscription is the user's report and cannot be verified from this repo; delivery on live Stripe is proven only in the D-11 device session (plan 04-14)."
  - id: D4
    description: "A card removed inside the PaymentSheet cannot be charged: clone rows gone after the webhook, and the sweep refuses it"
    verification: []
    human_judgment: true
    rationale: "Needs live Stripe and a real saved card; every automated proof here is on mocked Stripe. Runs in the D-11 device session (plan 04-14)."

duration: "about 1 day wall clock (tasks 1 and 2 by the agent, task 3 waited on the user's deploy); agent work not separately timed"
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 01: D-12 PaymentSheet Card Removal (Backend) Summary

**A payment_method.detached webhook now evicts a removed card's connected-account clones, and the T-24h charge sweep refuses a platform card that is detached, missing or foreign, with D-12 live in production as a single backend commit (ae3ec1a) on top of 32fa6ec.**

## Performance

- **Duration:** about 1 day wall clock, mostly waiting for the user's deploy; agent work was not timed separately
- **Completed:** 2026-11-12
- **Tasks:** 3 (Task 1 tracer, Task 2 sweep guard and commit, Task 3 human-action deploy checkpoint)
- **Files modified:** 6 backend files (327 insertions, 7 deletions) plus planning artifacts in this repo

## Accomplishments

- `payment_method.detached` is handled in `dispatchPlatformEvent` (`webhooks.controller.js`): a `pm_` id calls `evictClonesForPlatformPaymentMethod` and is stamped processed (also when zero clones exist); a non-`pm_` id, a missing object or a top-level `event.account` is stamped ignored with no eviction call; any eviction error returns 500 `WEBHOOK_PROCESSING_FAILED` so Stripe and the drain cron retry.
- `longLeadChargeSweep.chargeOne` retrieves the platform card before `getOrCreateConnectedCustomer`. Only `resource_missing`, a null `customer`, or a `customer` that differs from the client's platform customer cancels (`cancelAndRelease(booking, null)`, no PaymentIntent). Any other retrieve error is re-thrown, so a transient failure never cancels a booking.
- The `connectedPaymentMethodClone.js` header now names two eviction callers (DELETE /me/payment-methods/:id and the webhook); `docs/ios/STRIPE-INTEGRATION.md` has a "Card removed inside PaymentSheet" note. No route, response field, error code or push changed, so App Store build 6 and the current Android build are unaffected.
- Deployed by the user on route (b): backend `ae3ec1a` is origin/main and production (`/health` = `{"status":"success","commit":"ae3ec1a"}`); the user reported the live-mode platform endpoint subscribed to `payment_method.detached`.

## Task Commits

1. **Task 1: Tracer, payment_method.detached evicts the removed card's clones** - no separate commit, by plan: left uncommitted in the D-12 worktree and folded into the single D-12 commit
2. **Task 2: The T-24h sweep refuses to charge a card the client removed** - `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d` (fix, backend repo, branch `ios-p4-d12`, worktree `/Users/LeonChen/Documents/ClickMe2026 Backend D12`): all six files in one commit, subject `fix(ios-p4): handle card removal inside PaymentSheet (D-12)`
3. **Task 3: User picks the route, ships only D-12, subscribes the endpoint** - no code commit; the user pushed `ae3ec1a` to main and subscribed the Dashboard event

**Plan metadata:** the iOS-repo docs commit that carries this SUMMARY, the todos, 04-USER-SETUP.md, STATE.md and ROADMAP.md.

## Files Created/Modified

Backend (commit `ae3ec1a`):
- `src/controllers/webhooks.controller.js` - `case 'payment_method.detached'` in `dispatchPlatformEvent`, import, JSDoc and header entry
- `src/services/connectedPaymentMethodClone.js` - header and JSDoc comment only (two eviction callers); no logic change
- `src/cron/longLeadChargeSweep.js` - platform-card check before the charge, `retrievePaymentMethod` import, header bullet
- `tests/webhooks.test.js` - `describe('payment_method.detached (ios-p4 D-12)')`
- `tests/cron/longLeadChargeSweep.test.js` - `describe('platform card check (ios-p4 D-12)')`, `retrievePaymentMethod` mock with a default attached-card resolution
- `docs/ios/STRIPE-INTEGRATION.md` - "Card removed inside PaymentSheet" contract note

iOS repo:
- `.planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md` - backend master must MERGE origin/main (never rebase or force-push)
- `.planning/phases/04-booking-payment-and-discovery/04-USER-SETUP.md` - the Stripe Dashboard step, recorded complete
- `.planning/todos/completed/2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md` - moved from pending, Resolution added

## Decisions Made

- **Deploy route:** the user chose (b), ship the D-12 commit alone now, before anything was pushed. The user's reply: "b: deployed ae3ec1a, subscribed".
- **Deploy SHA found as:** the tip of `ios-p4-d12` (`git rev-parse ios-p4-d12`), equal to the SHA Task 2 recorded; the push was the user's one-line gated command with an explicit refspec as a fast-forward of main. Claude pushed nothing and changed nothing in Stripe.
- **Rollback base:** `32fa6ecd97a47409c5e7bf4f730b803f7b2fd7e5`, local branch `ios-p4-d12-rollback`. Rollback is Railway's redeploy of the previous deployment, or a revert of the D-12 commit through the same gated route. Never force-push main.
- **Android and build 6 removal setting:** Android (Stripe SDK 23.24.0) and iOS build 6 (SDK 26.2.0) set no PaymentSheet removal option; both use the SDK default (RESEARCH A5, assumed removal allowed). The server fix covers both; no Android code change.
- **Eviction safety:** eviction is safe from the webhook because a detached platform card can never be re-cloned (Stripe documents detachment as permanent).
- **Known behavior after the change:** a transient retrieve error leaves the row stamped and scheduled; only `scaRecoveryWindowSweep`'s 6 h window can cancel it, and no charge happens.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Backend base moved before execution**
- **Found during:** Task 1 (worktree creation)
- **Issue:** `origin/main` and production were `32fa6ec`, not the `af47201` the plan names. The plan's line references, the "76 baseline" and the "38 commits" were stale. The real baseline for the three D-12 suites was 70 passed; master was 5 commits ahead of `origin/main` at the checkpoint (31-11 docs, and 31-12: a guarded one-way `20261113000100_drop_legacy_ledger.sql` migration plus test and script cleanup).
- **Fix:** built D-12 on `32fa6ec` in the worktree as the plan's own method prescribes; recorded the real numbers here. No plan task changed.
- **Files modified:** none beyond the plan's six
- **Verification:** `merge-base --is-ancestor origin/main HEAD` held at commit time; the shipped range is exactly one commit past `32fa6ec`.
- **Committed in:** `ae3ec1a`

**2. [Rule 1 - Bug] Per-row isolation sweep test needed the new mock**
- **Found during:** Task 2
- **Issue:** after the sweep started calling `retrievePaymentMethod`, the existing per-row isolation test ran out of mocked resolutions for its second row.
- **Fix:** added two `mockResolvedValueOnce` lines to that test's setup. No assertion in any existing test changed.
- **Files modified:** `tests/cron/longLeadChargeSweep.test.js`
- **Verification:** the sweep suite passes with every pre-existing assertion intact.
- **Committed in:** `ae3ec1a`

**3. [Plan wording] Header sentence reworded**
- **Found during:** Task 1
- **Issue:** the old header sentence forbade the webhook caller.
- **Fix:** reworded the forbidding sentence to "Keep it out of every booking and sweep path"; the plan's acceptance grep for the old phrase (`NEVER call it from a booking`, expect 0) holds.
- **Committed in:** `ae3ec1a`

**4. [Rule 2 - Missing critical coverage] Four extra test rows**
- **Found during:** Tasks 1 and 2
- **Issue:** edges the plan's truths name but its row list does not: a webhook event with a missing object, one with a non-string id, a Stripe rate-limit transient error on the sweep, and a profile-read error combined with a detached card.
- **Fix:** added one row for each. With the plan's 11 rows, the three suites went from 70 to 85 passed (+15).
- **Verification:** the guard was disabled temporarily; exactly the four cancel rows failed, and the file was restored byte-identical.
- **Committed in:** `ae3ec1a`

---

**Total deviations:** 4 (1 Rule 3 blocking, 1 Rule 1 test setup, 1 wording, 1 Rule 2 coverage)
**Impact on plan:** none changed behavior; the base correction means the plan's line numbers and counts should be read as stale, and the numbers in this SUMMARY are the measured ones.

## Verification

- Three D-12 suites in the D-12 worktree: 85 passed (baseline 70).
- Full backend suite (`REDIS_URL=redis://localhost:6379 npm test`, D-12 worktree): 153 suites, 3804 tests passed. `npm run check-docs`: OK (126 endpoints).
- Pre-push gate (pre-checkpoint): exactly one commit past origin/main, the D-12 commit, and exactly its six files.
- Post-deploy checks, re-run by Claude on 2026-11-12 after the continuation:
  - `git rev-parse origin/main` equals `git rev-parse ios-p4-d12`, both `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d`: PASS.
  - `git rev-list --count ios-p4-d12-rollback..origin/main` = 1: PASS.
  - `git diff --name-only ios-p4-d12-rollback origin/main` lists exactly `docs/ios/STRIPE-INTEGRATION.md`, `src/controllers/webhooks.controller.js`, `src/cron/longLeadChargeSweep.js`, `src/services/connectedPaymentMethodClone.js`, `tests/cron/longLeadChargeSweep.test.js`, `tests/webhooks.test.js`: PASS. (Compared by eye against the plan's list; the scripted `diff <(...)` form was refused by this shell, bash 3.2.)
  - Production `/health` = `{"status":"success","commit":"ae3ec1a"}`, matching `git rev-parse --short=7 ios-p4-d12`: PASS.
  - The merge todo exists, names `ios-p4-d12` and contains `merge-base --is-ancestor`: PASS.
- Master untouched: `ae3ec1a` is not an ancestor of master (checked); no `ios-p4` subject on master (count 0). Master has since moved to `d4b897f` ("docs(31): complete phase 31 legacy teardown, transition to phase 32"), 11 commits past the merge base `32fa6ec`; that was another session's work.

## Issues Encountered

- The Stripe Dashboard subscription is the user's report only. It could not be independently verified from this repo; the live proof is the D-11 session.
- The sweep guard protects off-session charges even if the event never arrives, so a missing subscription is not a charge risk.

## Known Stubs

None.

## Threat Flags

None. The change adds no new endpoint, auth path or schema; the new webhook case sits behind the existing HMAC verification.

## User Setup Required

External service configuration was required and is recorded as complete. See [04-USER-SETUP.md](./04-USER-SETUP.md): add `payment_method.detached` to the live-mode platform webhook endpoint (not the Connect endpoint). Done by the user on 2026-11-12.

## Next Phase Readiness

- Plan 04-14 (D-11 real-money device session) is unblocked on the backend side. It must include the live proof: remove a card in the sheet, show the webhook delivery (200) and the clone rows gone, and show the removed card cannot be charged.
- **BACK-06, BACK-07, BACK-15 and BACK-19 stay Pending** until the D-11 session (plan 04-14) passes. This plan lists none of them in `requirements-completed`.
- Open follow-up: backend master must merge origin/main before its next deploy; see `.planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md`. Before the D-11 session and the Phase 8 release, `git merge-base --is-ancestor <D-12 sha> <the /health sha>` must hold.
- Later cleanup, not done here: the worktree `/Users/LeonChen/Documents/ClickMe2026 Backend D12` and the branches `ios-p4-d12` and `ios-p4-d12-rollback` stay until Phase 4 verification.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*

## Self-Check: PASSED

- FOUND: `.planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md`
- FOUND: `.planning/phases/04-booking-payment-and-discovery/04-USER-SETUP.md`
- FOUND: `.planning/todos/completed/2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md` (and absent from pending)
- FOUND: backend commit `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d` is an ancestor of backend origin/main
