---
phase: 04-booking-payment-and-discovery
verified: 2026-11-12T21:30:00Z
status: human_needed
score: 15/19 must-haves verified
covered_files: [".planning/phases/04-booking-payment-and-discovery/04-01-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-01-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-02-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-02-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-03-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-03-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-04-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-04-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-05-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-05-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-06-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-06-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-07-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-07-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-08-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-08-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-09-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-09-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-10-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-10-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-11-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-11-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-12-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-12-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-13-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-13-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-14-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-14-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-15-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-15-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-16-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-16-SUMMARY.md","ClickMe2026/Managers/UnconfirmedBookingLedger.swift","ClickMe2026/Utils/ConfirmOutcome.swift","ClickMe2026/Utils/ConfirmRetryPolicy.swift","ClickMe2026/Utils/DateUtil.swift","ClickMe2026/Utils/ExpertProfileSections.swift","ClickMe2026/Utils/HomeShellExit.swift","ClickMe2026/Utils/PagedList.swift","ClickMe2026/Utils/PaymentLifecycleVariant.swift","ClickMe2026/Utils/PaymentSheetOutcome.swift","ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift","ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift","ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift","ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift"]
covered_digest: "v3:sha256:9a36549421f5940a47a6cd6f34a20b3ac5f641dbfd8658c51a67406501786e4d"
behavior_unverified: 2
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 13/18
  gaps_closed:
    - "PAY-02 / CR-01: a retried confirm re-reads the live topic and slot (closed by plan 04-15, iOS 6184f6c, 50f55de, 2baa72d)"
    - "D-12 / CR-02: a transient Stripe error at the platform-card check turns into a cancel about 6 h later (closed by plan 04-16, backend 28da165, scoped to the profiles read and the platform-card check)"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
advisory:
  - finding: "WR-06: a transient error AFTER the stamp in longLeadChargeSweep.chargeOne (connected customer, clone, pre-charge recheck, createManualPI, non-card confirm error) still ends in scaRecoveryWindowSweep cancelling the booking about 6 h later, with no charge attempted"
    category: other
    reason: "Predates D-12 and is outside plan 04-01's own prohibition (scoped to errors 'while checking the platform card'). Accepted by the user before the 04-16 push ('Q-CR02 0 rows, limits accepted', limit c). Tracked in .planning/todos/pending/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md (T-04-45). Needs a bounded-retry design and a user decision in the backend repo"
    evidence_status: "code read in the D12 worktree (longLeadChargeSweep.js lines 167-172 comment and rethrow) and todo text; no production observation"
  - finding: "WR-07: a profiles-read or platform-card-check error that persists is retried every 5 minutes with no deadline; past session start the session can go ahead with no PaymentIntent and be delivered uncharged"
    category: other
    reason: "Accepted by the user before the push (limits a and b), recorded as T-04-44. The alternative is the cancel that D-12 forbids"
    evidence_status: "code read (candidate query has no start-time bound, longLeadChargeSweep.js:127); consequence chain taken from the 04-16-SUMMARY re-check, not re-derived end to end"
behavior_unverified_items:
  - truth: "Request Sent cannot be swiped back (interactivePopGestureRecognizer and iOS 26 interactiveContentPopGestureRecognizer disabled while visible, restored when leaving)"
    test: "On a device, make a free booking, then try the left-edge swipe and an in-content swipe on Request Sent; tap either exit and check the destination tab's swipe-back works again"
    expected: "No swipe pops Request Sent; after leaving, swipe-back works on every other screen"
    why_human: "BookingRequestSentPopGestureLock sets and restores UIKit recognizer state; no test exercises the set and restore, and presence checks cannot see whether the gesture is actually blocked or whether a leaked disabled state breaks swipe-back elsewhere (UAT item 3)"
  - truth: "The booking form (topic picker, calendar day cells and month arrows, time slots, meeting type, notes) is locked from Book Now until the paid flow completes or resets"
    test: "On a device in airplane mode, start a paid booking, and while 'Confirming your booking...' shows tap another slot, the topic row, another day and the next-month arrow; then Try again (D-11 step d)"
    expected: "None of the taps changes the form; after Try again, Request Sent shows the slot first chosen, with one booking and one hold"
    why_human: "Five .disabled(viewModel.isSubmitting) modifiers are present in MakeABookingView.swift:71-83, but no test asserts a SwiftUI view is disabled. The data-level protection (the PaidAttempt snapshot) is unit-tested, so this lock is defense in depth and screen consistency; plan 04-15 itself marks it a device-only check (UI-SPEC D1, backstop)"
human_verification:
  - test: "D-11 real-money session (04-DEVICE-UAT-CHECKLIST.md): close the card sheet with a saved card preselected, forced confirm timeout then Try again (with the form-lock taps), SCA/3DS path, remove a card inside the sheet, T-24h sweep"
    expected: "No requires_capture PaymentIntent after closing the sheet; a timed-out confirm lands on the one booking with one hold; 3DS completes into a booking (see WR-01); a removed card is refused at T-24h (production now runs 28da165); payment_method.detached delivered with 200"
    why_human: "Real holds on live Stripe; PAY-01 real-hold proof, BACK-06/07/15/19, 01-17, 01-19 and the unreported Stripe Dashboard subscription (user-reported, not verified) can only be proved on a device and in the Dashboard. The project definition of done requires it"
  - test: "WR-01 (open in 04-REVIEW-DISPOSITION.md): complete a 3DS challenge on a saved card that requires SCA, then confirm a booking exists"
    expected: "After 3DS the booking is created. Code evidence suggests retryConfirmAfterSCA sends the connected-account clone's pm_ id while booking.controller.js:903 retrieves it on the platform account, which would fail and strand an authorized PaymentIntent with no booking"
    why_human: "Cannot be proven or refuted without a card that triggers 3DS on live Stripe; if it fails it is a gap against 'without unintended holds'. The existing 3DS-retry test encodes the suspected behavior, so a green suite is not evidence"
  - test: "UAT item 1, EXPL-07: Explore loads with a free no-currency topic, one bad topic, a failed load"
    expected: "Explore loads every time; a bad featured topic is dropped alone; airplane-mode failure shows a readable sentence and no stale Featured Topics. Precondition: migration 20261109000000_home_feed_null_hourly_rate.sql applied in production (unknown)"
    why_human: "Depends on live production data and an unconfirmed migration; REQUIREMENTS.md leaves EXPL-07 Pending until this passes"
  - test: "UAT item 2, EXPL-03: free featured topic card reads 'Free'; paid card shows CA$12.50 style price"
    expected: "Free card reads Free; paid card shows cents"
    why_human: "Code present (ExploreClientViewModel.swift:284) but REQUIREMENTS.md leaves EXPL-03 Pending until a device check; needs production data with a free topic"
  - test: "Remaining UAT items for BOOK-01, BOOK-19, BOOK-04, EXPL-02, EXPL-05, EXPL-06, K1/K3/K4/K5 (items 3 to 22 of 04-DEVICE-UAT-CHECKLIST.md)"
    expected: "Per the checklist's Expected lines"
    why_human: "Gestures, 12/24-hour setting, layout and paging against real data need hardware; nothing has been run on a device yet"
---

# Phase 4: Booking, Payment and Discovery Verification Report

**Phase Goal:** Clients can find an expert, book and pay without double submissions, unintended holds, misleading errors or missing profile data
**Verified:** 2026-11-12
**Status:** human_needed
**Re-verification:** Yes, after gap closure (plans 04-15 and 04-16). The prior report (status `gaps_found`, 13/18) is replaced by this one.

## Goal Achievement

Both gaps from the prior report are closed in the code I read and tested, and no regression turned up in the 13 truths that passed before. The one thing the prior report scored FAILED (partial) that is not fully closed, the "never cancels on a transient error" half of D-12, is a documented, user-accepted limit outside the plan's own prohibition, so it is advisory and not a gap. What stands between this phase and "done" is hardware and live Stripe: nothing has run on a device, WR-01 (3DS) is unproven, and EXPL-03 and EXPL-07 are Pending by design. That is why the status is `human_needed` and not `passed`.

### What changed since the first verification

| Item | Before | Now | Evidence I checked myself |
|------|--------|-----|---------------------------|
| CR-01 / PAY-02 (truth 2) | FAILED (partial) | VERIFIED | `MakeABookingViewModel+PaidAttempt.swift` declares `PaidAttempt` (topic, slot, paymentIntentId, meetingType, clientNotes). `beginPaidBooking` builds it from the parameters `book()` captured (`MakeABookingViewModel.swift:542`). `completePaidBooking` guards only on `paidAttempt` (`:585`) and every request field and ledger call reads `attempt.*`. The function body contains no `selectedTopic` or `selectedTimeSlot` (awk over the function: 0 matches). `loadAvailability` clears the slot only when `!isSubmitting` (`:355`). Re-ran the suites: 38 paid-flow tests passed, 5 availability tests passed |
| CR-02 / D-12 (truth 17) | FAILED (partial) | VERIFIED, scoped, with accepted limit | Backend `28da165` on `ios-p4-d12` (HEAD of the worktree, clean tree). In `chargeOne` the order is: no-card branch, profiles select (error logged and rethrown), `retrievePaymentMethod`, one `stampAttempt`, then cancel or charge. Re-ran the cron suites: 2 suites, 50 tests passed |

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PAY-01 / SC1: closing the card sheet without tapping Continue never places a hold | VERIFIED | `MakeABookingStripePaymentSheet.swift:107-111` uses `presentPaymentOptions(from:completion:)` with `PaymentSheetOutcome.proceeds(didCancel:hasPaymentOption:)`; a close never reaches `completePaidBooking`. `PaymentSheetOutcome.swift` present. Real-hold proof is the D-11 session, pending |
| 2 | PAY-02 / SC1: a confirm that times out and is retried lands on the pending booking, not "slot taken", also when the client touches the form | VERIFIED | See the table above. Regression rows exist and passed in the 38-test run: `bookCreatesPaidAttempt`, `retryKeepsOriginalSelection`, `scaRetryKeepsOriginalSelection`, `reloadDuringConfirmKeepsSlot`, `idleReloadClearsSlot`, `ledgerKeysOnPaidAttempt`, `confirmWithoutAttemptMakesNoRequest`, `everyResetUnlocksTheForm`, `formEditWhileConfirmRunsKeepsRequest`, `secondConfirmWhileRunningIsRejected`. This is the exact regression the first report asked for (unknown outcome, selection changed, `retryConfirm()`, original slot and topic in the body). The 3DS retry still sends the clone `pm_` id, which is WR-01, a separate human item |
| 3 | BOOK-01 / SC2: Request Sent has no Back button and both exits are reachable in loading, error and loaded states | VERIFIED | `BookingRequestSentView.swift:58` `.navigationBarBackButtonHidden(true)`; actions pinned in all three states (unchanged since first verification) |
| 4 | BOOK-01 / SC2: swipe-back is locked while Request Sent is visible and restored on leaving | PRESENT_BEHAVIOR_UNVERIFIED | `BookingRequestSentPopGestureLock.swift` sets both recognizers including `interactiveContentPopGestureRecognizer` (lines 51-52); no test exercises set and restore. UAT item 3 |
| 5 | BOOK-05 + PAY-03 / SC2: loading copy "Loading booking…"; payment card describes hold vs scheduled charge vs already charged | VERIFIED | `PaymentLifecycleVariant.swift` present and wired in `BookingRequestSentViewModel`; unchanged since first verification, covered by `PaymentLifecycleVariantTests` in the 641-test run |
| 6 | BOOK-19 / SC2: a booking started from Favorites/Search/another tab does not leave Request Sent on that tab's stack | VERIFIED | `HomeShellExit.swift` present; `HomeClientView` `applyExit` wiring unchanged; `HomeShellExitTests` in the run |
| 7 | BOOK-02 / SC3: changing month never shows the previous month's availability | VERIFIED | `loadAvailability` still takes a `ReloadGeneration` token and checks after every await. `MakeABookingAvailabilityTests` passed on its own (5 tests). The 04-15 change to the slot clear did not touch this logic |
| 8 | BOOK-03 + BOOK-04 / SC3: readable zone name and device 12/24-hour setting | VERIFIED | `DateUtil.shortTime` and `DateUtil.zoneName()` unchanged; `SlotTimeFormatTests`. Device 12/24 toggle check pending |
| 9 | EXPL-01 / SC4: a 404 profile shows "This profile isn't available"; network errors offer retry | VERIFIED | `ExpertProfileViewModel` 404 mapping unchanged. Caveat WR-02 below |
| 10 | EXPL-02 / SC4: empty Expertise, Topics and Reviews sections are hidden; zero reviews renders cleanly | VERIFIED | `ExpertProfileSections.swift` present and used by `ExpertProfileView`; `ExpertProfileSectionsTests`. No device confirmation of the original bug (UAT item 10) |
| 11 | EXPL-03 / SC4: free featured topics show "Free" | UNCERTAIN | Code present (`ExploreClientViewModel.swift:284`); Pending by design until a device check |
| 12 | EXPL-04 / SC4: Search tag pills show their full text | VERIFIED | `SearchExpertCard.tagsRow` flow layout; `TopicsSetupFlowLayoutTests` |
| 13 | EXPL-05 / SC5: Favorites shows every favorite (paged), empty-state buttons work, copy is correct | VERIFIED | `FavoritesViewModel` on `PagedList`; `PagedList.swift` present; paging tests in the run. Caveat WR-05 below |
| 14 | EXPL-05 / SC5: profile favorite state comes from `is_favorite` | VERIFIED | Unchanged since first verification |
| 15 | EXPL-06 / SC5: the full reviews list loads beyond 20 reviews | VERIFIED | `ExpertReviewsViewModel` on `PagedList`; `ExpertReviewsViewModelPagingTests` |
| 16 | EXPL-07: Explore loads with a free no-currency topic or one bad topic; no stale Featured Topics beside section errors | UNCERTAIN | `LossyFeaturedTopic` + `compactMap` present; Pending by design; production migration state unknown (UAT item 1) |
| 17 | D-12 (04-01): a removed card is refused at T-24h, and a transient error while checking the platform card never cancels the booking | VERIFIED (scoped; post-stamp limit accepted, see below) | Eviction handler, detached/missing/foreign check, and now the reorder are in `28da165`. Details in the CR-02 section |
| 18 | PAY-04: stale `TODO(backend): stripe_account` comments removed | VERIFIED | `grep -rn "TODO(backend)" ClickMe2026` returns 0 |
| 19 | CR-01 (04-15): the booking form is locked while a paid booking is in flight, so the screen shows the form being confirmed | PRESENT_BEHAVIOR_UNVERIFIED | `.disabled(viewModel.isSubmitting)` on the topic picker, calendar, time slots, meeting type and notes cards (`MakeABookingView.swift:71, 74, 77, 80, 83`). `everyResetUnlocksTheForm` proves `isSubmitting` always returns to false. No test asserts the view is disabled; plan 04-15 lists it as human judgment (D5). Device step d |

**Score:** 15/19 truths verified (2 present, behavior-unverified: truths 4 and 19; 2 uncertain, awaiting device: truths 11 and 16; 0 failed)

### Truth 17 and CR-02: gap or accepted limit

**Verdict: accepted limit, not a gap.** Reasoning:

1. **Scope of the written prohibition.** Plan 04-01's must-have truth reads "a transient error while *retrieving the platform card* ... is re-thrown like any other non-decline error" (`04-01-PLAN.md:37`), and its prohibition reads "MUST NOT cancel a client's booking because of a transient Stripe or network error *while checking the platform card*" (`:77`). Plan 04-16 repeats that scope. My first report's truth 17 was worded more broadly ("a transient Stripe error never cancels"), and the CONTEXT.md line 317 summary is broad too. The enforceable, written prohibition is the card-check one.
2. **That prohibition now holds end to end, and I checked the code rather than the summary.** In `longLeadChargeSweep.js` `chargeOne`, lines 27-38 read the profile and rethrow on error; lines 52-63 call `retrievePaymentMethod`, treat only `resource_missing` as gone, and rethrow anything else; the first `stampAttempt` that can precede a cancel or charge is at line 68, after both reads. The candidate query requires `off_session_attempted_at` to be NULL (`:127`), so an unstamped row is picked up again on the next 5-minute run. `scaRecoveryWindowSweep.js:71-72` selects only rows with `off_session_attempted_at <= cutoff`, so it never sees that row. The CR-02 describe (`longLeadChargeSweep.test.js:622`) runs two sweeps plus the window sweep, and the profiles-error rows (line 767) cover attached, foreign and detached cards. 50 of 50 cron tests pass on my run.
3. **A new weakness the fix closed along the way.** Before, a profiles read error degraded to a null customer id, which skipped the foreign-card comparison. Now a read error is rethrown and a profile with no `stripe_customer_id` counts as a mismatch, the same rule `confirmLongLead` applies at insert. That is stricter than before, not looser.
4. **What is left is a different failure class and was accepted.** A transient error after the stamp (connected customer, clone, pre-charge recheck, `createManualPI`, non-card confirm error) still ends in a cancel at about 6 h. It predates D-12 (backend Phase 26 D-08), and the code comment at `longLeadChargeSweep.js:167-172` says so honestly. Before the push the user was told three limits (a, b, c), and `04-16-SUMMARY.md` lines 105-111 record the reply "Q-CR02 0 rows, limits accepted". Limit (c) is exactly this one, tracked as T-04-45 in `.planning/todos/pending/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md` (I read that todo; it carries the problem, why it was not fixed, and options). The same SUMMARY also read the production-state query `Q-CR02` as 0 rows, so no booking was found already in the bad state (this is the user's report, not something I could check, since I never touch production).
5. **Why not a gap anyway.** A gap would need a must-have that is false. The must-have is true; the leftover concerns a broader sentence that nobody committed to as a deliverable, and the user chose with full information to defer it. Fixing it needs a bounded-retry design in the backend repo and a user decision (a stamp reset after a Stripe write can replay `createManualPI` and strand a hold).

**What I want the reader to keep in mind:** this is a real production exposure, a wrongful cancel for a Stripe or database blip after the stamp, even though it is accepted. It sits in the advisory list as WR-06 so the developer sees it at ship time. A related accepted limit, WR-07, can deliver a session uncharged if a check error persists past the start.

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `MakeABookingViewModel+PaidAttempt.swift` | PaidAttempt snapshot | VERIFIED | Substantive (Equatable struct with five fields), used at `MakeABookingViewModel.swift:166, 542, 585, 645` |
| `MakeABookingViewModel+PaidFlow.swift` | alerts, Try again, 3DS retry, cancel entry points | VERIFIED | `retryConfirm` and `retryConfirmAfterSCA` go through `completePaidBooking` and no longer read live selections (grep: no `selectedTopic`/`selectedTimeSlot` in this file) |
| `MakeABookingViewModel.swift` | does not grow | VERIFIED | 966 lines (gate was at most 974) |
| `MakeABookingView.swift` | five locked cards | VERIFIED | 5 `.disabled(viewModel.isSubmitting)` |
| `Utils/PaymentSheetOutcome.swift`, `ConfirmOutcome.swift`, `ConfirmRetryPolicy.swift`, `Managers/UnconfirmedBookingLedger.swift`, `PaymentLifecycleVariant.swift`, `HomeShellExit.swift`, `PagedList.swift`, `ExpertProfileSections.swift` | prior artifacts | VERIFIED | All present and non-empty (regression check) |
| Backend `src/cron/longLeadChargeSweep.js`, `tests/cron/longLeadChargeSweep.test.js`, `docs/ios/STRIPE-INTEGRATION.md` | CR-02 | VERIFIED | `28da165` is one commit, exactly these three files, on top of `ae3ec1a`; worktree clean |
| Backend `master` | contains D-12 and CR-02 | NOT PRESENT (by design) | Pending todo `2026-11-11-merge-d12-into-backend-master.md`. The deployed code is on `origin/main`/`ios-p4-d12`; `master` must take both commits before it deploys |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `beginPaidBooking` | `paidAttempt` | `PaidAttempt(topic:slot:...)` built from `book()` parameters | WIRED | `MakeABookingViewModel.swift:542` |
| `completePaidBooking` | `confirmBooking` request | `attempt.paymentIntentId/topic.id/slot.startTime/meetingType/clientNotes` | WIRED | Region has 0 reads of the live selection |
| `completePaidBooking` | `UnconfirmedBookingLedger` | `attempt.slot.startTime` for record and both clears | WIRED | |
| `MakeABookingView` | `isSubmitting` | `.disabled` on five cards | WIRED | Lines 71-83 |
| `loadAvailability` | `paidAttempt` safety | slot cleared only when idle | WIRED | `:355` |
| `chargeOne` | `scaRecoveryWindowSweep` | stamp placed after the read-only checks | WIRED (the prior HARMFUL link is fixed) | profiles select, retrieve, then `stampAttempt` at line 68 |
| Stripe sheet completion | `cancelPaidBooking()` | `PaymentSheetOutcome.proceeds` | WIRED | |
| `MakeABookingView` | `BookingRequestSentView` | `navigationDestination(item: completedBookingId)` | WIRED | Unchanged |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `completePaidBooking` request body | topic, slot, meeting type, notes, PI id | `paidAttempt`, set from the Book Now parameters and the `/bookings/payment-intent` response | Yes (not a live-form read) | FLOWING |
| `PaymentLifecycleCard` | `paymentVariant` | `GET /client/bookings/:id` | Yes | FLOWING |
| `ExpertProfileView` heart | `isFavorited` | `getExpertDetails().isFavorite` | Yes | FLOWING |
| `FavoritesView` / `ExpertReviewsView` | `list.items` | paged API calls | Yes | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| CR-01 paid attempt snapshot, retry, ledger, lock reset | `xcodebuild test -only-testing:ClickMe2026Tests/MakeABookingPaidFlowTests` (iPhone 17 Pro) | "Test run with 38 tests in 1 suite passed" | PASS |
| BOOK-02 month race still holds after the slot-clear change | `-only-testing:ClickMe2026Tests/MakeABookingAvailabilityTests`, run alone | "Test run with 5 tests in 1 suite passed" | PASS |
| CR-02 two-run sweep, profiles-error rows, window sweep | `npx jest tests/cron/longLeadChargeSweep.test.js tests/cron/scaRecoveryWindowSweep.test.js` in the D12 worktree | 2 suites, 50 tests passed | PASS |
| Full iOS suite | not re-run; orchestrator reports 641 tests in 65 suites passed after 04-15, no app or test change since `2baa72d` (confirmed: `git diff 2baa72d HEAD` for `ClickMe2026` and `ClickMe2026Tests` is empty), build on HEAD succeeded with the 1 pre-existing Stripe deprecation warning | n/a | SKIPPED, taken from the orchestrator |
| Full backend suite | not re-run; 04-16-SUMMARY reports 153 suites, 3809 tests | n/a | SKIPPED, taken from the summary |

One note on method: my first attempt ran the paid-flow and availability suites in a single `xcodebuild` invocation and one availability test failed (`An older load that lands last writes nothing`, `expertTimezone` "Zone/1" vs "Zone/2"). Both suites use `MockURLProtocol`, whose static state is shared, and the project already says such suites must run in separate invocations (STATE 02-07, restated in 04-15-PLAN). Run separately, each passes. I treat that as test isolation, not a regression, but it is a standing hazard: someone running these two suites together will see a false red.

## Probe Execution

Step 7c: SKIPPED. No probe scripts are declared by any plan, and `scripts/*/tests/probe-*.sh` is not used by this phase.

## Requirements Coverage

All 17 phase requirement IDs (BOOK-01..05, BOOK-19, PAY-01..04, EXPL-01..07) appear in plan frontmatter and in REQUIREMENTS.md. No orphans. D-12 and D-13 are decision IDs, not REQUIREMENTS.md rows.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOOK-01 | 04-03 | No Back after request sent | SATISFIED (swipe lock behavior-unverified) | truths 3, 4 |
| BOOK-02 | 04-04 | Month change race | SATISFIED | truth 7 |
| BOOK-03 | 04-04 | Readable zone name | SATISFIED | truth 8 |
| BOOK-04 | 04-04 | 12/24-hour | SATISFIED (device toggle pending) | truth 8 |
| BOOK-05 | 04-03 | "Loading booking…" | SATISFIED | truth 5 |
| BOOK-19 | 04-03, 04-10 | Source-tab exits | SATISFIED | truth 6 |
| PAY-01 | 04-02 | Close sheet, no hold | SATISFIED in code; real-hold proof pending (D-11) | truth 1 |
| PAY-02 | 04-08, 04-13, 04-15 | Timeout retry lands on booking | SATISFIED in code and unit tests (CR-01 closed); form lock and real timeout need the D-11 session | truths 2, 19 |
| PAY-03 | 04-09 | Hold vs charge card | SATISFIED | truth 5 |
| PAY-04 | 04-02, 04-08 | Stale TODO comments removed | SATISFIED | truth 18 |
| EXPL-01 | 04-05 | 404 and retry | SATISFIED | truth 9 |
| EXPL-02 | 04-12 | Empty sections hidden | SATISFIED in code; device pending | truth 10 |
| EXPL-03 | 04-14 | "Free" label | NEEDS HUMAN (Pending by design) | truth 11 |
| EXPL-04 | 04-11 | Full-text tag pills | SATISFIED | truth 12 |
| EXPL-05 | 04-05, 04-06, 04-10, 04-12 | Favorites paged, buttons, copy, `is_favorite` | SATISFIED | truths 13, 14 |
| EXPL-06 | 04-11 | Reviews paging | SATISFIED | truth 15 |
| EXPL-07 | 04-14 | Explore home-feed resilience | NEEDS HUMAN (Pending by design) | truth 16 |

REQUIREMENTS.md currently shows `[ ]` checkboxes and traceability "Gaps Found" for 15 of the 17 IDs (EXPL-03 and EXPL-07 read Pending). That table reflects the first report and is now stale for the orchestrator to update. On the code evidence the 15 can move off "Gaps Found". PAY-01 and PAY-02 should stay short of final until the D-11 session passes, per the project's definition of done. I did not edit REQUIREMENTS.md.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| Debt markers (TBD/FIXME/XXX/TODO) in the phase's Swift files | n/a | none found in `Make a Booking/`, `Utils/`, `UnconfirmedBookingLedger.swift` | none | n/a |
| Backend `longLeadChargeSweep.js` | 167-172 | rethrow after the stamp leaves a stamped, PaymentIntent-less row | Warning (accepted, WR-06) | user-accepted limit; todo T-04-45 |
| Backend `longLeadChargeSweep.js` | 127 | no start-time bound on the retry | Warning (accepted, WR-07) | user-accepted limit; T-04-44 |
| `ExpertProfileViewModel.swift` | 108-114 | any reload error replaces a loaded profile with the full-screen error | Warning (WR-02, open) | |
| `ExploreClientViewModel.swift` | 74-111 | no latest-wins gate on `load()` | Warning (WR-03, open) | |
| `MakeABookingView.swift` / VM | `onAppear` reload | reappear clears the picked slot when idle | Warning (WR-04, open; the payment-hurting half is fixed by the `isSubmitting` guard) | |
| `FavoritesViewModel.swift` | 140-163, 204-233 | refresh can resurrect a row being unfavorited | Warning (WR-05, open) | |
| `04-DEVICE-UAT-CHECKLIST.md` | 10, 20, 25, 335 | still names `ae3ec1a` as production and `32fa6ec` as rollback base; production is now `28da165`, rollback base `ae3ec1a` | Warning | Do not let the device session roll back to `32fa6ec`: that would remove D-12 and CR-02. The ancestor test (`merge-base --is-ancestor ae3ec1a <health sha>`) still passes with `28da165`, but the rollback instructions are stale. Update before the D-11 session |

`04-REVIEW-DISPOSITION.md` records CR-01 and CR-02 as fixed, WR-06 and WR-07 as deferred, and WR-01 to WR-05 as open (not triaged).

## Human Verification Required

See the `human_verification` and `behavior_unverified_items` frontmatter. In short:

1. The D-11 real-money session (04-DEVICE-UAT-CHECKLIST.md): not run. It includes the new form-lock taps and the timeout-then-Try-again path that CR-01 protects.
2. WR-01, the 3DS retry `pm_` id, needs a card that triggers 3DS on live Stripe. If it fails, it is a gap against "without unintended holds" and phase 4 should reopen for it.
3. EXPL-03 and EXPL-07, by design, plus the rest of the 22 UAT items.
4. Two behavior-unverified truths (swipe-back lock, form lock), both in the list above.

Before that session, update the checklist's stale SHAs (see the anti-patterns table). The Stripe Dashboard subscription to `payment_method.detached` remains the user's report only.

## Gaps Summary

No gaps. The two gaps from the first report are closed and I confirmed that in the code and by running the relevant suites, not from the summaries. The remaining exposure, a wrongful cancel for a transient error after the stamp, is a documented limit the user accepted knowingly, outside plan 04-01's written prohibition, and is recorded as advisory WR-06 with a follow-up todo.

What keeps this from `passed`: the project's definition of done requires a device check on a real iPhone and the real-money session, none of which has run, and WR-01 can only be settled there. Nothing in later milestone phases (5 to 8) covers these, so none were deferred.

---

_Verified: 2026-11-12_
_Verifier: Claude (gsd-verifier)_
