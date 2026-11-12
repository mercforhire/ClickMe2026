---
phase: 04-booking-payment-and-discovery
verified: 2026-11-12T16:30:00Z
status: gaps_found
score: 13/18 must-haves verified
covered_files: [".planning/phases/04-booking-payment-and-discovery/04-01-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-01-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-02-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-02-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-03-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-03-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-04-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-04-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-05-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-05-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-06-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-06-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-07-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-07-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-08-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-08-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-09-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-09-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-10-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-10-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-11-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-11-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-12-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-12-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-13-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-13-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-14-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-14-SUMMARY.md","ClickMe2026/Managers/UnconfirmedBookingLedger.swift","ClickMe2026/Utils/ConfirmOutcome.swift","ClickMe2026/Utils/ConfirmRetryPolicy.swift","ClickMe2026/Utils/DateUtil.swift","ClickMe2026/Utils/ExpertProfileSections.swift","ClickMe2026/Utils/HomeShellExit.swift","ClickMe2026/Utils/PagedList.swift","ClickMe2026/Utils/PaymentLifecycleVariant.swift","ClickMe2026/Utils/PaymentSheetOutcome.swift","ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift","ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift","ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift"]
covered_digest: "v3:sha256:f0c350340155f7fffba7a69ddd9ac93179c1ffdcdab0ce0176d5be99d3e9c543"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "A confirm that times out and is retried takes the user to their pending booking instead of showing 'slot taken' (PAY-02, SC1)"
    status: partial
    reason: "The designed retry path works and is unit-tested. But completePaidBooking re-reads selectedTopic and selectedTimeSlot live on every user-driven re-run (Try again, retryConfirmAfterSCA), and nothing locks the topic picker, calendar, month nav or slot chips while paidStep != .idle (only the Book button is disabled). Confirmed CR-01."
    artifacts:
      - path: "ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift"
        issue: "completePaidBooking (line ~563) reads selectedTopic/selectedTimeSlot at call time instead of a snapshot taken when the PaymentIntent was created. loadAvailability (line ~346) sets selectedTimeSlot = nil unconditionally, so a month change during .confirming makes the next Try again hit the guard and call resetPaidFlow() silently, dropping the PI id and pm_ id while a hold may exist. A changed slot sends the original PI with a different start_time (PI_CONTEXT_MISMATCH or SLOT_UNAVAILABLE); that path clears the ledger or keys it on the new slot, so the D-04 'may already be booked' protection is lost."
      - path: "ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift"
        issue: "Month nav buttons, day cells, MakeABookingTimeSlotsCard chips and MakeABookingTopicPicker have no .disabled(viewModel.isSubmitting)"
      - path: "ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift"
        issue: "No test changes the selection between attempts, so this is uncovered"
    missing:
      - "Snapshot topic, slot and paymentIntentId into a PaidAttempt when the PaymentIntent is created; completePaidBooking and the ledger key use the snapshot"
      - "Disable topic picker, calendar, month nav and slot chips while viewModel.isSubmitting"
      - "Do not clear selectedTimeSlot in loadAvailability while paidStep != .idle (clear it in goToPreviousMonth/goToNextMonth instead)"
      - "Test: set an unknown outcome, change selectedTimeSlot, call retryConfirm(), assert the request body still carries the original slot and topic"
  - truth: "D-12 (plan 04-01): a transient Stripe error while checking the platform card never cancels a client's booking (prohibition, test tier)"
    status: failed
    reason: "Confirmed CR-02 against backend commit ae3ec1a (worktree ClickMe2026 Backend D12). chargeOne stamps off_session_attempted_at (stampAttempt, line ~278) before the new retrievePaymentMethod call (line ~322). On a transient error the code re-throws, the row stays payment_status='scheduled' with the stamp set and no payment_intent_id, and longLeadChargeSweep never selects it again (it filters off_session_attempted_at IS NULL). scaRecoveryWindowSweep selects it once off_session_attempted_at <= now-6h and, with no payment_intent_id, goes straight to the scheduled->canceled transition and cancelBookingForPaymentFailure, which cancels the booking, releases the slot and notifies both parties. So a Stripe or network blip during the T-24h run cancels a booking about 6 hours later with no charge ever attempted. The plan truth text ('stays scheduled for scaRecoveryWindowSweep's window') is satisfied only literally; the prohibition's intent is violated end to end, and the commit message, code comment and docs overstate the guarantee. The exposure for other transient errors in chargeOne predates D-12; D-12 adds one more Stripe round trip in front of it. Already deployed to production."
    artifacts:
      - path: "ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js"
        issue: "stampAttempt runs before the platform-card retrieve; transient error leaves a stamped row that scaRecoveryWindowSweep later cancels"
      - path: "ClickMe2026 Backend D12/tests/cron/longLeadChargeSweep.test.js"
        issue: "The transient-error test asserts only the first run (no cancel, no charge); it does not simulate the follow-up sweeps"
    missing:
      - "Move the read-only platform-card check (and the platformCustomerId profile lookup) before stampAttempt, so a transient failure leaves the row unstamped and the next 5-minute sweep retries it; or reset the stamp with a guarded update on a transient retrieve error"
      - "Test with two sweep runs after a transient error, asserting the second run charges (and scaRecoveryWindowSweep does not cancel)"
      - "Correct the comments and docs/ios/STRIPE-INTEGRATION.md to match the real guarantee; the fix needs a new backend deploy (the user's step, one commit in the backend repo)"
deferred: []
behavior_unverified_items:
  - truth: "Request Sent cannot be swiped back (interactivePopGestureRecognizer and iOS 26 interactiveContentPopGestureRecognizer disabled while visible, restored when leaving)"
    test: "On a device, make a free booking, then try the left-edge swipe and an in-content swipe on Request Sent; tap either exit and check the destination tab's swipe-back works again"
    expected: "No swipe pops Request Sent; after leaving, swipe-back works on every other screen"
    why_human: "BookingRequestSentPopGestureLock sets and restores UIKit recognizer state; no test exercises the set and restore, and presence checks cannot see whether the gesture is actually blocked or whether a leaked disabled state breaks swipe-back elsewhere (UAT item 3)"
human_verification:
  - test: "UAT item 1, EXPL-07: Explore loads with a free no-currency topic, one bad topic, a failed load"
    expected: "Explore loads every time; a bad featured topic is dropped alone; airplane-mode failure shows a readable sentence and no stale Featured Topics. Precondition: migration 20261109000000_home_feed_null_hourly_rate.sql applied in production (unknown)"
    why_human: "Depends on live production data and an unconfirmed migration; REQUIREMENTS.md leaves EXPL-07 Pending until this passes"
  - test: "UAT item 2, EXPL-03: free featured topic card reads 'Free'; paid card shows CA$12.50 style price"
    expected: "Free card reads Free; paid card shows cents"
    why_human: "Code present (ExploreClientViewModel.swift:284) but REQUIREMENTS.md leaves EXPL-03 Pending until a device check; needs production data with a free topic"
  - test: "D-11 real-money session (04-DEVICE-UAT-CHECKLIST.md): close the card sheet with a saved card preselected, forced confirm timeout then Try again, SCA/3DS path, remove a card inside the sheet, T-24h sweep"
    expected: "No requires_capture PaymentIntent after closing the sheet; a timed-out confirm lands on the one booking with one hold; 3DS completes into a booking (see WR-01); a removed card is refused at T-24h; payment_method.detached delivered with 200"
    why_human: "Real holds on live Stripe; BACK-06/07/15/19, 01-17, 01-19 and the unreported Stripe Dashboard subscription (user-reported, not verified) can only be proved on a device and in the Dashboard. The project definition of done requires it"
  - test: "WR-01 (code review, not triaged): complete a 3DS challenge on a saved card that requires SCA, then confirm a booking exists"
    expected: "After 3DS the booking is created. Code evidence suggests retryConfirmAfterSCA sends the connected-account clone's pm_ id (paymentIntent.paymentMethodId from handleNextAction) while booking.controller.js:903 retrieves it on the platform account, which would fail and strand an authorized PaymentIntent with no booking"
    why_human: "Cannot be proven or refuted without a card that triggers 3DS on live Stripe; if it fails it is a gap against 'without unintended holds'"
  - test: "UAT items for BOOK-01, BOOK-19, BOOK-04, EXPL-02, EXPL-05, EXPL-06, K1/K3/K4/K5 (items 3 to 22)"
    expected: "Per the checklist's Expected lines"
    why_human: "Gestures, 12/24-hour setting, layout and paging against real data need hardware; nothing has been run on a device yet"
---

# Phase 4: Booking, Payment and Discovery Verification Report

**Phase Goal:** Clients can find an expert, book and pay without double submissions, unintended holds, misleading errors or missing profile data
**Verified:** 2026-11-12
**Status:** gaps_found
**Re-verification:** No (initial verification)

## Goal Achievement

The 14 plans are all present in the codebase and most of the discovery and booking-UI work is real, wired and unit-tested. Two confirmed defects sit on the core money path (PAY-02 retry and the deployed D-12 sweep), so the "without unintended holds" half of the goal is not yet earned. No device check has run, which the project's definition of done requires.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PAY-01 / SC1: closing the card sheet without tapping Continue never places a hold | VERIFIED | `MakeABookingStripePaymentSheet.swift:105-113` uses the `presentPaymentOptions(from:completion:)` overload and routes through `PaymentSheetOutcome.proceeds(didCancel:hasPaymentOption:)`; a close calls `cancelPaidBooking()` and never `completePaidBooking`. Link is off (`config.link.display = .never`). `PaymentSheetOutcomeTests` ran and passed. Real-hold proof is D-11/D1, pending |
| 2 | PAY-02 / SC1: a confirm that times out and is retried lands on the pending booking, not "slot taken" | FAILED (partial) | Designed path holds: `ConfirmOutcome`/`ConfirmRetryPolicy` replay the same PI, pm_ and attempt id; `MakeABookingPaidFlowTests` ran and passed (49 tests in 3 suites). But CR-01 confirmed: the user-driven re-run re-reads live selections and the form is unlocked, see Gaps |
| 3 | BOOK-01 / SC2: Request Sent has no Back button and both exits are reachable in loading, error and loaded states | VERIFIED | `BookingRequestSentView.swift`: `.navigationBarBackButtonHidden(true)`; `BookingRequestSentActions` pinned in `loadingContent`, `errorContent` and `loadedContent` |
| 4 | BOOK-01 / SC2: the swipe-back gesture is locked while Request Sent is visible and restored on leaving | PRESENT_BEHAVIOR_UNVERIFIED | `BookingRequestSentPopGestureLock` sets/restores both recognizers (incl. iOS 26 content pop); no test exercises it. Routed to UAT item 3 |
| 5 | BOOK-05 + PAY-03 / SC2: loading copy reads "Loading booking…"; payment card describes hold vs scheduled charge vs already charged | VERIFIED | `BookingRequestSentView.swift` `loadingContent`; `PaymentLifecycleVariant.choose` driven by `ClientBookingDetail.status/paymentStatus/authorizationExpiresAt`. Cross-checked against backend `derivePaymentStatus` (`clientBooking.controller.js:75-110`): a long-lead booking has no `payment_intent_id`, gives `none`, and maps to `chargeScheduled`; a held booking never says charged. `PaymentLifecycleVariantTests` in suite |
| 6 | BOOK-19 / SC2: booking started from Favorites/Search/other tab does not leave Request Sent on that tab's stack | VERIFIED | `HomeClientView.swift:96-106,235-243`: `applyExit(HomeShellExit.plan(_, selectedTab:))` resets the source tab's path; `MakeABookingView.swift:142-145` wires both exits; `HomeShellExitTests` in suite |
| 7 | BOOK-02 / SC3: changing month never shows the previous month's availability | VERIFIED | `loadAvailability` takes a `ReloadGeneration` token, checks after every `await`, and writes only if `month` is still `displayedMonth` (`MakeABookingViewModel.swift:343-380`); `MakeABookingAvailabilityTests` |
| 8 | BOOK-03 + BOOK-04 / SC3: slot and Today's Sessions times show a readable zone name and follow the device 12/24-hour setting | VERIFIED | `DateUtil.shortTime` (locale + hour-pattern cache key) used by `BookingTimeSlot.displayLabel`, `ExploreClientViewModel:187`, `BookingRequestSentViewModel:145,161`; `DateUtil.zoneName()` in `MakeABookingTimeSlotsCard:22` and `ExploreTodaysSessionsSection:32`; `SlotTimeFormatTests`. Device 12/24 toggle check pending |
| 9 | EXPL-01 / SC4: a 404 profile shows "This profile isn't available"; network errors offer retry | VERIFIED | `ExpertProfileViewModel.loadProfileDetails` maps 404 (status or `ErrorCode.notFound`) to `.notFound`, other errors to `.failed`; `ExpertProfileStateView.swift:80`; `ExpertProfileView.swift:188-195` shows retry. Caveat WR-02 below |
| 10 | EXPL-02 / SC4: empty Expertise, Topics and Reviews sections are hidden; zero reviews renders cleanly | VERIFIED | `ExpertProfileSections.showsExpertise/showsTopics/showsReviews/rating` used at `ExpertProfileView.swift:365-377`; `ExpertProfileSectionsTests`. Fix shipped on the user's fix-now decision with no device confirmation of the original bug (UAT item 10) |
| 11 | EXPL-03 / SC4: free featured topics show "Free" | UNCERTAIN | Code present (`ExploreClientViewModel.swift:284`); REQUIREMENTS.md keeps it Pending by design until a device check |
| 12 | EXPL-04 / SC4: Search tag pills show their full text | VERIFIED | `SearchExpertCard.tagsRow` uses `TopicsSetupFlowLayout`, `fixedSize(horizontal:false, vertical:true)`, no truncating `lineLimit`; `TopicsSetupFlowLayoutTests` |
| 13 | EXPL-05 / SC5: Favorites shows every favorite (paged), empty-state buttons work, copy is correct | VERIFIED | `FavoritesViewModel` on `PagedList` with `loadNextPageIfNeeded`, footer retry, refresh; `FavoritesEmptyState` buttons wired to `returnToHome` and `showMyHistory` (`ClientProfileHomeScreen.swift:221-222`, `HomeClientView.swift:102-106`); `FavoritesViewModelPagingTests`, `PagedListTests`. Caveat WR-05 below |
| 14 | EXPL-05 / SC5: profile favorite state comes from `is_favorite` | VERIFIED | `ExpertProfileViewModel.swift:~118` sets `isFavorited = details.data.isFavorite ?? false` unless a toggle is in flight; Favorites rows seed the heart (D-09) |
| 15 | EXPL-06 / SC5: the full reviews list loads beyond 20 reviews | VERIFIED | `ExpertReviewsViewModel` pages on `PagedList` (pageSize 20, `has_more`, footer retry); `ExpertReviewsViewModelPagingTests` |
| 16 | EXPL-07: Explore loads with a free no-currency topic or one bad topic; no stale Featured Topics beside section errors | UNCERTAIN | `LossyFeaturedTopic` + `compactMap` in `ClientHomeData.swift:96-97`; Pending by design. The production migration state is unknown (UAT item 1) |
| 17 | D-12 (04-01): a removed card is refused at T-24h and a transient Stripe error never cancels | FAILED (partial) | Eviction handler and the detached/missing/foreign check are present in `ae3ec1a`. The "never cancels" half is false end to end (CR-02), see Gaps |
| 18 | PAY-04: stale `TODO(backend): stripe_account` comments removed | VERIFIED | `grep -rn "TODO(backend)"` over the app returns nothing; the fail-closed guard in `runSCA` remains |

**Score:** 13/18 truths verified (1 present, behavior-unverified; 2 uncertain, awaiting device; 2 failed)

### CR-01 and CR-02 re-assessed against the code

- **CR-01: CONFIRMED.** The in-flight confirm is safe because `completePaidBooking` captures `topic`, `slot` and `intentId` into locals before the retry closure. The defect is the second entry: Try again goes through `retryConfirm()` to `completePaidBooking` and reads the live properties again. I found no `.disabled(isSubmitting)` on the topic picker, calendar, month nav or slot chips (`grep` over `Subviews/`). Trigger window: the confirm can run minutes (120 s timeout, three attempts) with the form interactive and only a status line shown. Practical impact: a mismatched retry is rejected by the server (no wrong hold), but the app can silently drop the PI and pm_ ids, or lose the D-04 "may already be booked" record, for a confirm that actually succeeded. That is the exact scenario PAY-02 exists to protect.
- **CR-02: CONFIRMED.** Traced `longLeadChargeSweep.chargeOne` (stamp, then retrieve, then rethrow) into `scaRecoveryWindowSweep.cancelOne` (no `payment_intent_id`, so skip the PI branch, transition scheduled to canceled, cancel booking). This is a wrongful cancellation, not an unintended hold: no money moves because no charge was attempted. It still violates the plan's own prohibition and is live in production.
- **WR-01: NOT confirmable from code alone.** The evidence in the review is credible: the PI is on the connected account and was confirmed with a cloned PM, so `paymentIntent.paymentMethodId` after `handleNextAction` is plausibly the clone's id, while `/bookings/confirm` retrieves it on the platform account (`booking.controller.js:903`). If true, 3DS completes, the PI sits authorized and no booking is created, which is an unintended hold. Kept as a human item; it should be tested before the release build ships.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Utils/PaymentSheetOutcome.swift` | close-equals-cancel rule | VERIFIED | Substantive, used by the sheet modifier |
| `Utils/ConfirmOutcome.swift`, `ConfirmRetryPolicy.swift` | classify and retry unknown outcomes | VERIFIED | Wired in `completePaidBooking` |
| `Managers/UnconfirmedBookingLedger.swift` | D-04 record | VERIFIED | Wired; session-only, in memory; behaviour affected by CR-01 |
| `MakeABookingViewModel+PaidFlow.swift` | alerts, Try again, Not now | VERIFIED | Wired into `MakeABookingView` |
| `Utils/PaymentLifecycleVariant.swift` | PAY-03 chooser | VERIFIED | Wired in `BookingRequestSentViewModel` |
| `Utils/HomeShellExit.swift` + `HomeClientView.applyExit` | BOOK-19 exits | VERIFIED | Wired through environment actions |
| `Utils/PagedList.swift` | shared paging | VERIFIED | Used by Favorites and Reviews |
| `Utils/ExpertProfileSections.swift`, `ExpertProfileStateView.swift` | EXPL-01/02 | VERIFIED | Wired in `ExpertProfileView` |
| `Backend D12: webhooks.controller.js`, `connectedPaymentMethodClone.js`, `longLeadChargeSweep.js` | D-12 | PARTIAL | Present on `ios-p4-d12` (`ae3ec1a`), deployed; sweep ordering defect (CR-02). Backend `master` does not contain D-12 (pending todo) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Stripe sheet completion | `viewModel.cancelPaidBooking()` | `PaymentSheetOutcome.proceeds` | WIRED | `didCancel` overload used |
| `completePaidBooking` | `/bookings/confirm` retry | `confirmRetryPolicy.run` | WIRED | Same ids replayed; selections not snapshotted (CR-01) |
| `MakeABookingView` | `BookingRequestSentView` | `navigationDestination(item: completedBookingId)` | WIRED | Exits call `showMyBookings` / `returnToHome` |
| `HomeClientView` | tab paths | `applyExit` | WIRED | Resets `resetTabs`, selects `showTab` |
| `FavoritesEmptyState` | shell | `returnToHome` / `showMyHistory` | WIRED | `ClientProfileHomeScreen:221-222` |
| `longLeadChargeSweep` | `scaRecoveryWindowSweep` | stamp + `scheduled` row | HARMFUL | Transient error becomes a cancel after 6 h |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `PaymentLifecycleCard` | `paymentVariant` | `GET /client/bookings/:id` `payment_status`, `status`, `authorization_expires_at` | Yes (backend `derivePaymentStatus`) | FLOWING |
| `ExpertProfileView` heart | `isFavorited` | `getExpertDetails().isFavorite` | Yes | FLOWING |
| `FavoritesView` list | `list.items` | `getClientFavorites(page:limit:)` | Yes | FLOWING |
| `ExpertReviewsView` | `list.items` | `getExpertReviews(id:page:limit:)` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| PAY-01 rule, PAY-02 classification and retry, paid-flow ledger and alerts | `xcodebuild test -only-testing:ClickMe2026Tests/{MakeABookingPaidFlowTests,PaymentSheetOutcomeTests,ConfirmOutcomeTests}` on iPhone 17 Pro simulator, fresh derived data | "Test run with 49 tests in 3 suites passed", TEST SUCCEEDED | PASS |
| Selection changed between confirm attempts keeps original slot | no such test exists | n/a | MISSING (CR-01) |
| Full suite 647 tests / 68 suites | not re-run (orchestrator reports it) | n/a | SKIPPED, taken from the orchestrator |

### Probe Execution

Step 7c: SKIPPED. No probe scripts declared by any plan; `scripts/*/tests/probe-*.sh` not used by this phase.

### Requirements Coverage

All 17 phase requirement IDs appear in plan frontmatter and in REQUIREMENTS.md. No orphans. Plans also cite D-12 and D-13, which are decision IDs, not REQUIREMENTS.md rows.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOOK-01 | 04-03 | No Back after request sent | SATISFIED (swipe lock behavior-unverified) | truths 3, 4 |
| BOOK-02 | 04-04 | Month change race | SATISFIED | truth 7 |
| BOOK-03 | 04-04 | Readable zone name | SATISFIED | truth 8 |
| BOOK-04 | 04-04 | 12/24-hour | SATISFIED (device toggle pending) | truth 8 |
| BOOK-05 | 04-03 | "Loading booking…" | SATISFIED | truth 5 |
| BOOK-19 | 04-03, 04-10 | Source-tab exits | SATISFIED | truth 6 |
| PAY-01 | 04-02 | Close sheet, no hold | SATISFIED in code; real-hold proof pending (D1) | truth 1 |
| PAY-02 | 04-08, 04-13 | Timeout retry lands on booking | BLOCKED (partial) | truth 2, CR-01 |
| PAY-03 | 04-09 | Hold vs charge card | SATISFIED | truth 5 |
| PAY-04 | 04-02, 04-08 | Stale TODO comments removed | SATISFIED | truth 18 |
| EXPL-01 | 04-05 | 404 and retry | SATISFIED | truth 9 |
| EXPL-02 | 04-12 | Empty sections hidden | SATISFIED in code; before/after on device pending | truth 10 |
| EXPL-03 | 04-14 | "Free" label | NEEDS HUMAN (REQUIREMENTS.md: Pending) | truth 11 |
| EXPL-04 | 04-11 | Full-text tag pills | SATISFIED | truth 12 |
| EXPL-05 | 04-05, 04-06, 04-10, 04-12 | Favorites paged, buttons, copy, `is_favorite` | SATISFIED | truths 13, 14 |
| EXPL-06 | 04-11 | Reviews paging | SATISFIED | truth 15 |
| EXPL-07 | 04-14 | Explore home-feed resilience | NEEDS HUMAN (REQUIREMENTS.md: Pending) | truth 16 |

REQUIREMENTS.md marks BOOK-01..05, BOOK-19, PAY-01..04 and EXPL-01/02/04/05/06 `[x] Complete`. After this verification, PAY-02 should not stay Complete until CR-01 is fixed, and PAY-01/PAY-02 are code-complete only until the D-11 session runs.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js` | 278, 322 | stamp-before-read, then rethrow | Blocker | CR-02 |
| `MakeABookingViewModel.swift` | 563-596, 346 | live reads and unconditional slot clear during a confirm | Blocker | CR-01 |
| `ExpertProfileViewModel.swift` | 108-114 | any reload error replaces a loaded profile with the full-screen error | Warning | WR-02 |
| `ExploreClientViewModel.swift` | 74-111 | no latest-wins gate on `load()` | Warning | WR-03 |
| `MakeABookingView.swift` / VM | 133, 287-292 | `onAppear` reload clears the picked slot after returning from Payment Methods | Warning | WR-04 |
| `FavoritesViewModel.swift` | 140-163, 204-233 | refresh can resurrect a row being unfavorited; profile unfavorite leaves a stale row | Warning | WR-05 |
| `MakeABookingViewModel.swift` | 689-694 | `PI_CURRENCY_MISMATCH` falls to default | Info | IN-02 |
| Debt markers (TBD/FIXME/XXX/TODO) | n/a | none found in the phase's Swift files | none | n/a |

04-REVIEW-DISPOSITION.md has all 13 findings still `open` (not triaged).

### Human Verification Required

See the `human_verification` and `behavior_unverified_items` frontmatter. In short: the 22-item `04-DEVICE-UAT-CHECKLIST.md` plus the D-11 real-money session have not been run; EXPL-03 and EXPL-07 depend on it by design; and WR-01 (3DS retry id) needs a card that triggers 3DS on live Stripe. The Stripe Dashboard subscription to `payment_method.detached` is the user's report only (the sweep check does not depend on it).

### Gaps Summary

Two gaps block the goal on the money path, both confirmed against the code and not just the review text:

1. **PAY-02 retry is not safe against form edits (CR-01).** The headline scenario of the phase is a timed-out confirm that is retried. The retry works when the screen is left alone. It can silently drop the payment ids, or lose the "you may already have this booking" record, if the user touches the topic, slot or month while the confirm runs. Fix is small and local to iOS (snapshot, lock the inputs, add one test).
2. **D-12 sweep turns a transient Stripe error into a cancellation six hours later (CR-02).** Already live. It is a backend change in a separate repo, one commit, reorder the check ahead of the stamp. Production-safe to fix (server-only), but it is a deploy.

Not gaps, but the phase cannot be called done until they are handled: WR-01 needs a device 3DS check before the release build; the device UAT has not run (project definition of done); EXPL-03 and EXPL-07 stay Pending; the five review warnings are untriaged. Nothing in the later phases of the milestone (5 to 8) covers these, so none were deferred.

---

_Verified: 2026-11-12_
_Verifier: Claude (gsd-verifier)_
