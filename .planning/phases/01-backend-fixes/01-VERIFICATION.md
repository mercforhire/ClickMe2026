---
phase: 01-backend-fixes
verified: 2026-11-09T03:45:00Z
status: gaps_found
score: 13/19 must-haves verified
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
covered_digest: "v3:sha256:5ec457da5f5626c7a7199bf7665893856704ae634fd9d948d7f8c21870834ef9"
behavior_unverified: 3
overrides_applied: 0
gaps:
  - truth: "BACK-08: A client account is never shown the Stripe tax-ID prompt (ROADMAP success criterion 2)"
    status: failed
    reason: "Not delivered. Wave 3c was dropped by user decision on 2026-11-08 and never pushed. Production (master 3899d63 = origin/main, /health reports 3899d63) has no expertWriteGate, no non-expert refusal in postOnboard, and no EXPERT_SETUP_REQUIRED code in src or openapi. Plans 01-21 and 01-22 are marked complete, but their code exists only on local branch wave-3c."
    artifacts:
      - path: "src/routes/index.js"
        issue: "GET /expert/tax-profile still mounts ensureExpert on master, so a client-only account is promoted and can open the tax form"
      - path: "src/controllers/connect.controller.js"
        issue: "postOnboard has no check that req.user.roles contains expert (that check exists only on wave-3c)"
    missing:
      - "A new user decision: ship wave-3c in some form that keeps build 6 client-only accounts able to become experts, or defer BACK-08 with a reason (REL-02 already says this must be decided before release)"
  - truth: "BACK-13: A client becomes an expert only through an explicit setup call, not any /expert/* call (ROADMAP success criterion 3)"
    status: failed
    reason: "Not delivered, same decision as BACK-08. On master, src/middleware/ensureExpert.js still upserts expert_profiles and writes app_metadata roles [client, expert] and profiles.roles on the first /expert/* call (lines 80-98). grep of tests/ for BACK-13 returns 0 files on master."
    artifacts:
      - path: "src/middleware/ensureExpert.js"
        issue: "First-touch promotion still active for every /expert/* route"
    missing:
      - "A new user decision on BACK-13 (revive wave-3c, redesign, or defer). Phase 5 SIGN-06 pairs with it and needs the same re-decision"
deferred: []
behavior_unverified_items:
  - truth: "BACK-06: A lone saved card is made the default"
    test: "On a real test account, add one card through PaymentSheet and call GET /me/payment-methods; then add a second card, delete one, and read the list again (01-17 checklist)"
    expected: "The lone card has is_default true after the first read and after the delete; two cards leave the choice to the user"
    why_human: "Deployed at d356fdc and covered by mocked-Stripe tests only. The real-card smoke was skipped by user decision on 2026-11-08, so promoteLoneCard has never run against real Stripe"
  - truth: "BACK-07: A deleted card can no longer be charged through its connected-account clone"
    test: "Run the 01-17 checklist: read the clone id from connected_pm_clones, delete the card, then confirm the clone is detached on the expert's connected account and the row is gone"
    expected: "The clone is detached in Stripe and its cache row removed; a card tied to an active booking returns 409 PAYMENT_METHOD_IN_USE"
    why_human: "The CLONE_ALREADY_GONE_CODES values come from in-repo code and are not confirmed against Stripe (the source says so). The real clone detach has never run. Windows ledger #3 and #5 stay open"
  - truth: "BACK-19: An expert-initiated cancel always refunds the client in full or releases the hold"
    test: "Run the 01-19 checklist on production with a low-value or no-money booking: expert cancels a held booking, and a captured one"
    expected: "A held booking is voided and a captured one is fully refunded, whatever the time to start"
    why_human: "Deployed at 3899d63, mocked Stripe only. The captured-refund branch cannot be reached safely on live data. Windows ledger #6 and #11 stay open. The failure path is also not retried as a refund (see warnings)"
human_verification:
  - test: "CR-01 / BACK-17: on App Store build 6 in client mode, tap a Booking Confirmed push, then a session push, then a review-nudge push"
    expected: "Each opens the booking (or at least lands somewhere sensible). If it shows a blank or warning page, build 6 users are affected right now"
    why_human: "BACK-17 puts category on iOS pushes, so build 6 now routes taps to HomeClientView.handlePushDestination, which pushes HomeRoute.upcomingBooking onto bookingsPath. The client Bookings stack registers only BookingRoute (MyBookingsView.swift:102); HomeRoute destinations are registered on Explore, Chats and Profile only (HomeClientView.swift:191,218,228). iOS app code at HEAD equals build 6 (git diff a48c664..HEAD for ClickMe2026/ is empty). This conflicts with the user-reported wave-1 smoke step 6 pass. I read the code and did not run a device, so I do not resolve it either way"
  - test: "Decide the fix if CR-01 reproduces: restore the old behavior for non-Android tokens by sending route_category / route_sub_category to iOS, and give Phase 2 PUSH-01 those keys"
    expected: "Build 6 keeps its pre-BACK-17 tap behavior; Phase 2 reads the new keys"
    why_human: "It changes D-01, so it is a user decision. The backend change can reach live users before the end-of-project iOS release; an iOS fix cannot"
  - test: "Run the real-Stripe checklists 01-17 (BACK-06, BACK-07) and 01-19 (BACK-19), at the latest during Phase 4 payment UAT"
    expected: "See behavior_unverified_items"
    why_human: "Skipped by user decision; money behavior on live Stripe"
  - test: "BACK-15 confirm replay and BACK-12 late-cancel guard on a device, after a forced confirm timeout"
    expected: "A retried confirm lands on the pending booking; a cancel after end returns SESSION_ALREADY_ENDED with the server message shown"
    why_human: "Waves 1 and 2 smoke is the user's 'all passed' with no per-step notes, and BACK-15 replay has no smoke step at all. Unit tests with mocks pass, so this is a confidence gap and not a failure"
---

# Phase 1: Backend Fixes Verification Report

**Phase Goal:** The production backend validates, stores and returns everything the iOS fixes depend on, and every change stays safe for the current Android build
**Verified:** 2026-11-09T03:45:00Z
**Status:** gaps_found
**Re-verification:** No, initial verification

## Verification basis

- Backend repo `/Users/LeonChen/Documents/ClickMe2026 Backend`, branch `master` at `3899d63`. `git rev-parse` gives the same SHA for HEAD, master and origin/main. Read-only git only.
- `GET https://clickme-backend-production.up.railway.app/health` returned `{"status":"success","commit":"3899d63"}` with HTTP 200, so production runs this code.
- `REDIS_URL=redis://localhost:6379 npm test` ran once at `3899d63`: 129 of 129 suites and 2974 of 2974 tests passed. The suite has known parallel flakes; none appeared in this run.
- Plans 01-20 to 01-23 (BACK-13, BACK-08) were dropped by user decision on 2026-11-08. Their code is on local branch `wave-3c` (8 commits ahead of master). I did not verify them against that branch as if they had shipped.
- Nothing was run on a device or against real Stripe or Supabase. Every money statement below rests on code and mocks.

## Goal Achievement

### Observable Truths (one per phase requirement)

| # | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 1 | BACK-01 accept message reaches the client | VERIFIED | `bookingRequests.controller.js` `postAcceptMessage` posts through `postUserMessage` with `client_msg_id` `booking-accept:<id>`, after block and moderation checks, non-fatal. `acceptSchema` allows `message` (max 1000). Tests present |
| 2 | BACK-02 decline note on client detail and notification | VERIFIED | `clientBooking.controller.js` getDetail returns `decline_reason_code/text` only when status is `declined`. `events.js` puts the text in `in_app_meta` and chat `event_data`, only the code in the FCM map. Fields in openapi |
| 3 | BACK-03 `has_review` on expert detail and lists | VERIFIED | `fetchClientReviewedBookingIds` (reviewer_role `client`, one read per page) feeds feed, details and summary |
| 4 | BACK-04 expert can clear `meeting_url` | VERIFIED | Schema accepts `null` and `""`; controller stores `meeting_url \|\| null`. Non-empty values still need a valid URL |
| 5 | BACK-05 currency digits and symbol | VERIFIED | `potential_earnings` divides by `10^minorUnitDigitsFor(currency)`; fee label uses `currencySymbolFor(currency)` with the booking's digits |
| 6 | BACK-06 lone card becomes default | PRESENT_BEHAVIOR_UNVERIFIED | `promoteLoneCard` on GET (one card, no default) and after delete. Mocked Stripe only; real-card smoke skipped by user |
| 7 | BACK-07 deleted card not chargeable via clone | PRESENT_BEHAVIOR_UNVERIFIED | 409 `PAYMENT_METHOD_IN_USE` check, `evictClonesForPlatformPaymentMethod` before the platform detach. Mocked Stripe only. See WR-01: removal inside PaymentSheet bypasses this path |
| 8 | BACK-08 client never shown tax-ID prompt | FAILED | Not delivered by user decision (wave 3c dropped). Not in master |
| 9 | BACK-09 join window and status check | VERIFIED | `evaluateJoinWindow`: first join in [start-60, max(end, start+60)], reconnect to end+60 per party; `/join` rejects statuses outside confirmed, in_progress, completed with 403 `SESSION_NOT_ACTIVE`; `can_join` flags use the same function. `call.test.js` present. Window narrowed from the old plus or minus 120 min, so build 6 and Android joins that were allowed at start-120 or end+120 are now refused. See WR-06 |
| 10 | BACK-10 request validation | VERIFIED | `createRequest` rejects start at or before now and a duration different from the topic's with 422 `VALIDATION_ERROR` before any Redis hold. Both clients send `topic.durationMins` (iOS `MakeABookingViewModel.swift:389,431`; Android `MakeABookingViewModel.kt:403,435`) |
| 11 | BACK-11 upper bounds | VERIFIED | `price_amount` max 2147483647; languages and expertise_tags max 50 on both profile and onboarding schemas. IN-02: the price cap is above Stripe's limit |
| 12 | BACK-12 client cancel after end rejected | VERIFIED | `clientBooking.cancel` throws 409 `SESSION_ALREADY_ENDED` at or after `end_time`, after the status guard. WR-02 below |
| 13 | BACK-13 explicit setup call only | FAILED | Not delivered by user decision. `ensureExpert.js` on master still promotes on first `/expert/*` call |
| 14 | BACK-14 cancel reason stored | VERIFIED | Migration `20261107000000_bookings_cancellation_reason.sql` (applied before wave 2 per 01-10); both cancel handlers write `cancellation_reason`; returned on client detail (cancelled only) and expert summary; never in push or chat data |
| 15 | BACK-15 confirm retry replay | VERIFIED (mocks only) | `findReplayableBooking` is ownership-checked and active-status only; replays 201 at the idempotency check, the conflict check, and the 23505 and 23P01 insert errors. `booking.test.js` describes each path. No smoke step exists |
| 16 | BACK-16 empty threads and feedback limit | VERIFIED | `GET /chats` drops the not-null filter and orders `last_msg_at desc nullsFirst:false`, `created_at desc`. `feedbackLimiter` (5 per 15 min per user, in-memory, valid while one replica) mounted before `validate`. Notification mark-read dropped by D-15 |
| 17 | BACK-17 push routing fields | UNCERTAIN | Payload side verified: `category`, `sub_category` and `target_role` go to every token, `target_role` allow-listed, `in_app_meta` never reaches FCM. The "safe for build 6" clause is open: CR-01, see Human Verification |
| 18 | BACK-18 unread counts | VERIFIED | `recomputeUnreadFor` runs on send (recipient), `handleMessageRead` (reader) and page 1 of messages. `GET /chats` reads the maintained counter. WR-04: counts can stay above zero for history nobody acks |
| 19 | BACK-19 expert cancel full refund | PRESENT_BEHAVIOR_UNVERIFIED | Captured PI refunds `amount_paid_minor_units` in full at any time and moves `captured` to `refunded`; authorized PI is voided; client cancel still uses `computeRefundAmountMinorUnits`. Mocked Stripe only; production smoke skipped by user |

**Score:** 13/19 truths verified (3 present, behavior-unverified; 1 uncertain; 2 failed)

### ROADMAP success criteria

| SC | Result | Why |
|----|--------|-----|
| 1 Booking requests, cancels, confirms and joins validated and recorded | VERIFIED | Rows 9, 10, 12, 14, 15 |
| 2 Saved cards safe on live Stripe; no tax-ID prompt; expert cancel refunds in full | FAILED | Tax-ID clause (BACK-08) not delivered; BACK-06, 07 and 19 unproven on real Stripe |
| 3 Booking and expert data complete; client becomes expert only via setup | FAILED | Everything but the explicit-setup clause (BACK-13) is verified |
| 4 Chat and push data correct | VERIFIED | Rows 16, 17 (payload), 18 |
| 5 Backend tests for every change; Android and build 6 still work | UNCERTAIN | Tests exist for every delivered requirement and pass. "Still work" rests on a user-reported smoke with no notes for waves 1 and 2, no smoke for 3a and 3b, and an open CR-01 |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/migrations/20261107000000_bookings_cancellation_reason.sql` | BACK-14 column | VERIFIED | Additive `ADD COLUMN IF NOT EXISTS` |
| `src/services/chatMessages.js` | single chat message path | VERIFIED | Used by `chats.send` and the accept message |
| `src/services/unreadCounts.js` | unread recompute | VERIFIED | Wired in chatMessages, socket, chats.controller |
| `src/utils/pushTargetRole.js` | target_role helpers | VERIFIED | Wired in push.js and every sender |
| `src/services/connectedPaymentMethodClone.js` `evict...` | BACK-07 eviction | VERIFIED (code) | Called only from `deletePaymentMethod` |
| `src/middleware/rateLimiter.js` `feedbackLimiter` | BACK-16 limit | VERIFIED | Mounted on `/feedback/submit` |
| `openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md`, `docs/ios/PUSH-ROUTING.md` | contract docs | VERIFIED | `SESSION_ALREADY_ENDED`, `PAYMENT_METHOD_IN_USE`, `has_review`, `cancellation_reason`, `decline_reason_text`, `target_role` are present. `EXPERT_SETUP_REQUIRED` is absent, matching production |
| `provisionExpert` / `expertWriteGate` (BACK-13, BACK-08) | explicit promotion and gate | MISSING on master | On `wave-3c` only |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `call.controller.join` | `agora.evaluateJoinWindow` + `JOINABLE_BOOKING_STATUSES` | per-party joined_at | WIRED |
| `clientBooking` / `expertBooking` `can_join` | same `evaluateJoinWindow` | joined_at selected for the flag only | WIRED |
| `bookingRequests.accept` | `postUserMessage` | `postAcceptMessage` | WIRED |
| every `sendPushToUser` caller | `targetRoleFor` / `targetRoleForAccount` | explicit `target_role` | WIRED (see WR-05) |
| `chats.send` and `message.read` | `recomputeUnreadFor` | send, handler, page 1 | WIRED |
| `deletePaymentMethod` | `evictClonesForPlatformPaymentMethod` | before platform detach | WIRED |
| `PATCH /expert/profile/setup` | `provisionExpert` | validate then promote | NOT PRESENT on master |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Production runs the verified commit | `GET /health` | commit 3899d63 | PASS |
| Backend suite | `REDIS_URL=redis://localhost:6379 npm test` | 129/129 suites, 2974/2974 tests | PASS |
| BACK-13 absent in production code | `grep -rn "provisionExpert\|expertWriteGate\|EXPERT_SETUP_REQUIRED" src` on master | no matches | CONFIRMS GAP |

### Probe Execution

No probes declared by the phase. Step 7c: SKIPPED.

### Requirements Coverage

Every ID from the phase and the PLAN frontmatter is accounted for in REQUIREMENTS.md. No orphans: the traceability table maps exactly BACK-01 to BACK-19 to Phase 1, and the plans claim all of them (BACK-13 and BACK-08 through 01-20 to 01-23).

| Requirement | Source plans | REQUIREMENTS.md | Verified status |
|-------------|--------------|-----------------|-----------------|
| BACK-01 | 01-09, 01-10 | Complete | SATISFIED |
| BACK-02 | 01-06, 01-10 | Complete | SATISFIED |
| BACK-03 | 01-05, 01-10 | Complete | SATISFIED |
| BACK-04 | 01-01, 01-10 | Complete | SATISFIED |
| BACK-05 | 01-05, 01-10 | Complete | SATISFIED |
| BACK-06 | 01-16, 01-17 | Pending | UNPROVEN (mocks only). Pending is correct |
| BACK-07 | 01-16, 01-17 | Pending | UNPROVEN (mocks only). Pending is correct |
| BACK-08 | 01-21, 01-22, 01-23 | Pending | BLOCKED, not delivered. Pending is correct |
| BACK-09 | 01-11, 01-15 | Complete | SATISFIED |
| BACK-10 | 01-07, 01-10 | Complete | SATISFIED |
| BACK-11 | 01-07, 01-10 | Complete | SATISFIED |
| BACK-12 | 01-12, 01-15 | Complete | SATISFIED |
| BACK-13 | 01-20 to 01-23 | Pending | BLOCKED, not delivered. Pending is correct |
| BACK-14 | 01-10, 01-12, 01-15 | Complete | SATISFIED |
| BACK-15 | 01-13, 01-15 | Complete | SATISFIED (mocks; no smoke) |
| BACK-16 | 01-08, 01-10 | Complete | SATISFIED |
| BACK-17 | 01-02 to 01-04, 01-10 | Complete | Payload SATISFIED; build-6 safety OPEN (CR-01). "Complete" is stronger than the evidence until the device check is done |
| BACK-18 | 01-14, 01-15 | Complete | SATISFIED (WR-04 caveat) |
| BACK-19 | 01-18, 01-19 | Pending | UNPROVEN (mocks only). Pending is correct |

REQUIREMENTS.md statuses match what I found, except that BACK-17 should be read as conditional on CR-01.

### Safety for App Store build 6 and Android

Contract changes were checked against both clients by the code review (iOS at the build 6 commit `a48c664`, Android at `2d04c4ce`; I did not check Android against a shipped artifact). I confirmed these myself:

- Both clients send `topic.durationMins` as `duration_minutes`, so the new 422 does not fire for them.
- New error codes decode to nil on iOS and the server message is shown.
- `PushEvent.swift` reads `category` first and falls back to `event_type` only for message and request events. Before BACK-17 iOS tokens got no `category`, so those pushes parsed to nil. They now route. That is the one behavior change for build 6 (CR-01).
- BACK-09 narrows the join window. iOS and Android local rules are within it for the first join (iOS allows start-60 to start+60 at minimum), but WR-06 shows a gap after the Sweep A "missed" path.

I found no break in sign-in, booking, paying, or chat decoding. I could not rule out CR-01 without a device.

### Anti-Patterns Found

None blocking. `git diff 2ec82af..3899d63 -- src` adds no `TBD`, `FIXME`, `XXX`, `TODO` or `HACK` lines. Known debts live in `deferred-items.md` and the Windows ledger (7 open, which will block `/gsd-ship` while `windows_enforce` is on).

Warnings carried from `01-REVIEW.md` that I re-read in code and consider real:

| Item | Severity | Impact |
|------|----------|--------|
| WR-01 card removal inside PaymentSheet skips BACK-07 | Warning | BACK-07's guarantee has a hole; a converted T-24h booking could charge a cached clone of a card the client removed |
| WR-02 BACK-12 blocks release of an unanswered `pending_approval` hold after end | Warning | Hold stays up to about 12 h; no charge. Accepted in effect by pushing wave 2, not confirmed by the user |
| Refund retry (deferred-items, ledger #8) | Warning | A failed expert-cancel refund is not retried as a refund, so BACK-19's "always refunds in full" does not hold on the failure path until a fix plan ships. Recorded user decision (option A), no plan exists yet |
| WR-03 failed client cancel can report "already cancelled" | Warning | Predates the phase |
| WR-04 unread counts stuck above zero | Warning | No visible effect on build 6; Android shows `max(server, local)` |
| WR-05 `target_role` unreliable for account and chat pushes | Warning | No shipped client reads it; fix before Phase 2 PUSH-02 |
| WR-06 first-join window past end vs Sweep A missed | Warning | Edge case: late joiner gets 403 "marked as missed" |
| WR-07 card delete can still error after the card is gone | Warning | iOS rolls the row back; retry returns 404 |

### Human Verification Required

1. **CR-01, BACK-17 on build 6.** On build 6 in client mode, tap Booking Confirmed, session and review-nudge pushes. Expected: each opens the booking. Why human: see the frontmatter. This is the only open item that can affect live App Store users today. If it fails, the only fix before the end-of-project release is a backend change (user decision on D-01).
2. **Real-Stripe checklists** 01-17 and 01-19, at the latest during Phase 4 payment UAT.
3. **BACK-15 replay and BACK-12 guard** on a device, since waves 1 and 2 smoke has no per-step notes and replay has no step.

### Gaps Summary

The backend is live at `3899d63` and 13 of 19 requirements are verified in code, with tests passing (2974 of 2974). Two requirements, BACK-08 and BACK-13, are not delivered, so success criteria 2 and 3 fail on their last clause. The user dropped wave 3c on purpose because the gate would leave build 6 client-only accounts unable to become experts, so this is a known decision and not a hidden regression. It is still a gap against this phase's goal text, and no later phase delivers it (Phase 5 SIGN-06 is the iOS half only). It needs a new decision before REL-02.

**This looks intentional.** If the user wants the phase to close with these two deferred, the override entries would be:

```yaml
overrides:
  - must_have: "BACK-08: A client account is never shown the Stripe tax-ID prompt"
    reason: "Wave 3c dropped to protect App Store build 6; code parked on backend branch wave-3c"
    accepted_by: "{name}"
    accepted_at: "{ISO timestamp}"
  - must_have: "BACK-13: A client becomes an expert only through an explicit setup call"
    reason: "Wave 3c dropped to protect App Store build 6; code parked on backend branch wave-3c"
    accepted_by: "{name}"
    accepted_at: "{ISO timestamp}"
```

I did not add these. An override needs the user's own acceptance, and the drop decision is recorded in STATE.md but not as an override of these truths. Even with the overrides, the phase would be `human_needed` because of CR-01 and the three behavior-unverified money items.

---

_Verified: 2026-11-09T03:45:00Z_
_Verifier: Claude (gsd-verifier)_
