---
phase: 04-booking-payment-and-discovery
verified: 2026-11-13T05:30:00Z
status: human_needed
score: 17/21 must-haves verified
covered_files: [".planning/phases/04-booking-payment-and-discovery/04-01-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-01-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-02-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-02-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-03-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-03-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-04-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-04-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-05-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-05-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-06-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-06-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-07-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-07-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-08-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-08-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-09-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-09-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-10-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-10-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-11-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-11-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-12-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-12-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-13-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-13-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-14-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-14-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-15-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-15-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-16-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-16-SUMMARY.md",".planning/phases/04-booking-payment-and-discovery/04-17-PLAN.md",".planning/phases/04-booking-payment-and-discovery/04-17-SUMMARY.md","ClickMe2026/Managers/UnconfirmedBookingLedger.swift","ClickMe2026/Utils/ConfirmOutcome.swift","ClickMe2026/Utils/ConfirmRetryPolicy.swift","ClickMe2026/Utils/DateUtil.swift","ClickMe2026/Utils/ExpertProfileSections.swift","ClickMe2026/Utils/HomeShellExit.swift","ClickMe2026/Utils/PagedList.swift","ClickMe2026/Utils/PaymentLifecycleVariant.swift","ClickMe2026/Utils/PaymentSheetOutcome.swift","ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift","ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift","ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift","ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift","ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift","ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift","ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift","ClickMe2026Tests/Support/MockURLProtocol.swift"]
covered_digest: "v3:sha256:50f67fd693fd2770baa2b48b83f13823031821190e15dc4f4efaa63f26b97d06"
behavior_unverified: 2
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 15/19
  gaps_closed:
    - "G-04-3 (UAT test 3, blocker): Explore pull to refresh left skeletons. Fixed in code by plan 04-17 (iOS 1e9ddde, cc50bb9, a06dd89); device re-test still pending, so it is closed in code and not on hardware"
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
  - finding: "04-REVIEW WR-01 / WR-03 (Explore): fetches are unshielded against each other. A pull to refresh started before a category-chip tap, and landing after the filtered response, overwrites experts and categories with the unfiltered feed while the chip stays highlighted. A cancelled fetch can also settle sections that a different, still-running fetch owns (transient flicker). Neither leaves a section on a skeleton with nothing loading"
    category: other
    reason: "Predates plan 04-17 for the chip-versus-chip case (applySelectedCategories was already an uncancelled Task); 04-17 makes the refresh path exposed too, because a refresh is no longer cancelled out from under the user. The plan recorded it as out of scope (T-04-52, accepted). I traced every overlap interleaving of fetchHome and stateAfterCancelledFetch and found none that ends with a section at .loading or .idle and no fetch left to settle it, so the G-04-3 truth holds. Fix idea in 04-REVIEW.md: a generation token (the MyBookings ReloadGeneration pattern)"
    evidence_status: "code trace by me plus the 04-REVIEW.md reproduction; no test and no device observation. 04-REVIEW-DISPOSITION.md: open, not triaged"
  - finding: "04-REVIEW WR-02 (Explore): a category-change fetch cancelled by the URL loading system settles to .loaded with the previous filter's experts, the new chip highlighted, and no Retry"
    category: other
    reason: "Reachable only through a system-level URLError.cancelled, because nothing in the app cancels the unstructured filter Task (the plan accepts this in its assumptions, 'Category change keeps its skeletons'). No test covers it. Wrong data without an error is the kind of state EXPL-07 exists to avoid, so I flag it for a follow-up even though it is rare"
    evidence_status: "code read (ExploreClientViewModel.swift:340-350 returns .loaded for before == .loaded, and applySelectedCategories passes replacingLoadedContent: true without telling the settle step); not reproduced"
behavior_unverified_items:
  - truth: "Request Sent cannot be swiped back (interactivePopGestureRecognizer and iOS 26 interactiveContentPopGestureRecognizer disabled while visible, restored when leaving)"
    test: "On a device, make a free booking, then try the left-edge swipe and an in-content swipe on Request Sent; tap either exit and check the destination tab's swipe-back works again"
    expected: "No swipe pops Request Sent; after leaving, swipe-back works on every other screen"
    why_human: "BookingRequestSentPopGestureLock sets and restores UIKit recognizer state; no test exercises the set and restore, and presence checks cannot see whether the gesture is actually blocked or whether a leaked disabled state breaks swipe-back elsewhere (checklist item 3). Not run: the 2026-11-12 device session stopped before items 3 to 22"
  - truth: "The booking form (topic picker, calendar day cells and month arrows, time slots, meeting type, notes) is locked from Book Now until the paid flow completes or resets"
    test: "On a device in airplane mode, start a paid booking, and while 'Confirming your booking...' shows tap another slot, the topic row, another day and the next-month arrow; then Try again (D-11 step d)"
    expected: "None of the taps changes the form; after Try again, Request Sent shows the slot first chosen, with one booking and one hold"
    why_human: "Five .disabled(viewModel.isSubmitting) modifiers are present in MakeABookingView.swift:71-83, but no test asserts a SwiftUI view is disabled. The data-level protection (the PaidAttempt snapshot) is unit-tested; this lock is defense in depth. The 2026-11-12 D-11 session recorded 'CR-01 form-lock taps not run' (04-UAT.md test 1)"
human_verification:
  - test: "G-04-3 / EXPL-07 device re-test (04-DEVICE-UAT-CHECKLIST.md item 1 step 4; 04-UAT.md test 3): on a loaded Explore pull to refresh ten times, letting each finish; airplane mode on and pull to refresh; airplane mode off and pull to refresh again"
    expected: "On each pull, Trending Categories, Featured Experts and Featured Topics stay on screen while the spinner runs and are replaced in place when it ends; the airplane-mode pull shows the readable offline sentence with Retry in each section and no Featured Topics; the pull after airplane mode is off loads every section; a skeleton that outlives the spinner is a FAIL"
    why_human: "Plan 04-17's own truth is tagged verification: backstop. The cause was diagnosed from code and reproduced only in unit tests, never under a debugger or on hardware, and the unit tests drive the view model with a hand-made task cancel, not SwiftUI's. Only a device shows whether SwiftUI's real cancellation behaves as modelled. REQUIREMENTS.md keeps EXPL-07 Pending until this passes, per the plan"
  - test: "WR-01 (open in 04-REVIEW-DISPOSITION.md): complete a 3DS challenge on a saved card that requires SCA, then confirm a booking exists"
    expected: "After 3DS the booking is created. Code evidence suggests retryConfirmAfterSCA sends the connected-account clone's pm_ id while booking.controller.js:903 retrieves it on the platform account, which would fail and strand an authorized PaymentIntent with no booking"
    why_human: "Blocked in 04-UAT.md test 2: no saved card triggered a 3DS challenge on live Stripe. If it fails it is a gap against 'without unintended holds'. The existing 3DS-retry test encodes the suspected behavior, so a green suite is not evidence"
  - test: "D-11 steps still not run (04-UAT.md test 1): step c and step e (airplane-mode steps), the CR-01 form-lock taps, and step g (01-17 and 01-19 real-Stripe checklists, which keeps BACK-06, BACK-07 and BACK-19 Pending)"
    expected: "Per the checklist's Expected lines for D-11 c, e and g"
    why_human: "Real holds on live Stripe and airplane-mode behavior need a device. Steps a, b, d, f and h passed on 2026-11-12 (sheet close places no hold; timed-out confirm plus Try again landed on one booking and one hold; payment_method.detached delivered with 200), which is real evidence for PAY-01 and PAY-02 but not the whole session"
  - test: "Remaining UAT items for BOOK-01, BOOK-19, BOOK-04, EXPL-02, EXPL-05, EXPL-06, K1/K3/K4/K5 (items 3 to 22 of 04-DEVICE-UAT-CHECKLIST.md)"
    expected: "Per the checklist's Expected lines"
    why_human: "Gestures, 12/24-hour setting, layout and paging against real data need hardware. The user stopped the session before item 3 (04-UAT.md test 5, skipped); resume with /gsd-verify-work 04"
---

# Phase 4: Booking, Payment and Discovery Verification Report

**Phase Goal:** Clients can find an expert, book and pay without double submissions, unintended holds, misleading errors or missing profile data
**Verified:** 2026-11-13
**Status:** human_needed
**Re-verification:** Yes, after gap-closure plan 04-17 (G-04-3). The prior report (human_needed, 15/19) is replaced by this one.

## Goal Achievement

The device session on 2026-11-12 found one real defect, G-04-3: pull to refresh on Explore ended on skeletons. Plan 04-17 changed `ExploreClientViewModel`, and I checked the change in the code and by running its test suite. The mechanism of the fix is sound and the tests discriminate. What I cannot do from here is show it works on a phone, and the plan itself marks the device re-test as the only proof of the whole behavior. So G-04-3 moves from FAILED to "fixed in code, device re-test pending", and EXPL-07 stays UNCERTAIN. No gap remains open in the code I can inspect, no earlier truth regressed, and the status is `human_needed` and not `passed`.

### What changed since the last verification

| Item | Before | Now | Evidence I checked myself |
|------|--------|-----|---------------------------|
| G-04-3 (new truth 20) | FAILED on device (UAT test 3) | VERIFIED at the view-model level | `load()` is one statement: `await Task { await self.fetchHome(replacingLoadedContent: false) }.value` (`ExploreClientViewModel.swift:82`). The inner Task inherits MainActor isolation but not its caller's cancellation, so cancelling the `.refreshable` task cannot reach `URLSession`. A `.loaded` section is not re-assigned at fetch start (`begin(_:)`, lines 97-105), so a refresh over loaded content publishes no state change. The cancel branch (lines 124-130) never assigns `.idle`; it settles each section through `stateAfterCancelledFetch(current:before:)` (lines 340-350). I ran `ClientHomeFeedTests` alone: `Test run with 27 tests in 1 suite passed`, 27 `Test ... passed` lines, 0 warnings naming the Explore files, the test file or `MockURLProtocol` |
| EXPL-03 (truth 11) | UNCERTAIN | VERIFIED | Device UAT recorded PASS on 2026-11-12: a free featured card reads Free, a paid card reads CA$120.00 (`04-UAT.md` test 4, checklist item 2). This is the user's report, not something I observed |
| PAY-01 / PAY-02 (truths 1, 2) | VERIFIED in code | VERIFIED in code, partly proven live | D-11 steps a, b, d, f, h passed on 2026-11-12 (`04-UAT.md` test 1): closing the sheet placed no hold; a timed-out confirm plus Try again landed on one booking and one hold. User's report. Steps c, e, g and the form-lock taps were not run |
| All other truths (1-10, 12-15, 17-19) | VERIFIED / PRESENT_BEHAVIOR_UNVERIFIED | unchanged | `git diff --stat fbb4afd HEAD` over `ClickMe2026` and `ClickMe2026Tests` touches only the Explore files, `ClientHomeFeedTests`, `MockURLProtocol`, and four files of other phases (`CancellationDeadlinesCard`, `RefundEligibilityCard`, `HelpView`, `HelpViewModel`, from commits 510e7cb and cae4090). None of the other Phase 4 covered files changed |

### G-04-3 against the three code-review warnings

The review (`04-REVIEW.md`, disposition: all open) raised three warnings on the 04-17 files. I weighed each against the G-04-3 truth ("Explore loads every time, including on pull to refresh and on a refresh after airplane mode is turned off") and EXPL-07.

1. **WR-03 (the invariant "while `.loading`, the fetch that set it is in flight" is not strictly true).** Correct as a statement about ownership: a cancelled fetch can settle a section that a different fetch is still loading. I traced every overlap I could construct (first load plus a `.task` re-fire; refresh over loaded plus a chip change; cancels in either order). In each, the section ends `.loaded`, `.failed` (with Retry), or `.loading` with at least one fetch still in flight that settles it, because success and failure write all three sections unconditionally and the fetch that first set `.loading` leaves it only by settling it. No path strands a skeleton. The cost is a transient flicker (a Retry card that an in-flight fetch then overwrites). So the G-04-3 claim holds; the doc comment is stronger than the code and should be corrected or the generation token added.
2. **WR-01 (overlapping fetches, last writer wins).** Real, and a user-visible wrong-data case: refresh in flight, tap a chip, the filtered response lands first, then the older unfiltered refresh overwrites it while the chip stays highlighted. It predates 04-17 for chip-versus-chip, and the plan accepted it as T-04-52 and recorded it as out of scope. It does not make a refresh fail to load, so it does not falsify the G-04-3 truth. It does mean EXPL-07's "Explore shows the right content" can be wrong in a narrow timing window. Advisory.
3. **WR-02 (a system-cancelled category-change fetch restores `.loaded` with the previous filter's experts).** Only reachable through a URL-loading-system cancel, since nothing in the app cancels that Task. No test covers it. Advisory, rare, but it is silent wrong data with no Retry, so I would fix it in the same follow-up as WR-01.

I do not treat these as blockers: none stops a pull to refresh from ending with content, and none contradicts a written must-have. They are recorded in the `advisory` list so they reach the developer, and `04-REVIEW-DISPOSITION.md` still lists them open.

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PAY-01 / SC1: closing the card sheet without tapping Continue never places a hold | VERIFIED | `MakeABookingStripePaymentSheet.swift:107-111` uses `presentPaymentOptions(from:completion:)` with `PaymentSheetOutcome.proceeds(didCancel:hasPaymentOption:)`; a close never reaches `completePaidBooking`. Live: D-11 step a PASS on 2026-11-12 (user report) |
| 2 | PAY-02 / SC1: a confirm that times out and is retried lands on the pending booking, not "slot taken", also when the client touches the form | VERIFIED | `PaidAttempt` snapshot in `MakeABookingViewModel+PaidAttempt.swift`; `completePaidBooking` reads only `attempt.*`; 38 paid-flow tests passed in the prior verification and `MakeABookingPaidFlowTests.swift` is unchanged since. Live: D-11 step d PASS (user report). The 3DS retry still sends the clone `pm_` id, which is WR-01, a separate human item |
| 3 | BOOK-01 / SC2: Request Sent has no Back button and both exits are reachable in loading, error and loaded states | VERIFIED | `BookingRequestSentView.swift` `.navigationBarBackButtonHidden(true)`; file unchanged since the last verification |
| 4 | BOOK-01 / SC2: swipe-back is locked while Request Sent is visible and restored on leaving | PRESENT_BEHAVIOR_UNVERIFIED | `BookingRequestSentPopGestureLock.swift` sets both recognizers; no test exercises set and restore. Checklist item 3 not run |
| 5 | BOOK-05 + PAY-03 / SC2: loading copy "Loading booking…"; payment card describes hold vs scheduled charge vs already charged | VERIFIED | `PaymentLifecycleVariant.swift` wired in `BookingRequestSentViewModel`; unchanged; `PaymentLifecycleVariantTests` in the orchestrator's 667-test run |
| 6 | BOOK-19 / SC2: a booking started from Favorites/Search/another tab does not leave Request Sent on that tab's stack | VERIFIED | `HomeShellExit.swift` present, `HomeClientView` wiring unchanged; `HomeShellExitTests` |
| 7 | BOOK-02 / SC3: changing month never shows the previous month's availability | VERIFIED | `loadAvailability` `ReloadGeneration` token unchanged; `MakeABookingAvailabilityTests` |
| 8 | BOOK-03 + BOOK-04 / SC3: readable zone name and device 12/24-hour setting | VERIFIED | `DateUtil.shortTime` / `DateUtil.zoneName()` unchanged; `SlotTimeFormatTests`. Device 12/24 toggle check pending |
| 9 | EXPL-01 / SC4: a 404 profile shows "This profile isn't available"; network errors offer retry | VERIFIED | `ExpertProfileViewModel` 404 mapping unchanged. Caveat WR-02 (profile reload error) below |
| 10 | EXPL-02 / SC4: empty Expertise, Topics and Reviews sections are hidden; zero reviews renders cleanly | VERIFIED | `ExpertProfileSections.swift` used by `ExpertProfileView`; `ExpertProfileSectionsTests`. No device confirmation |
| 11 | EXPL-03 / SC4: free featured topics show "Free" | VERIFIED | `ExploreClientViewModel.formatPrice` returns "Free" for `isFree == true` (line 317); `ClientHomeFeedTests` price rows; device PASS recorded 2026-11-12 (`04-UAT.md` test 4). REQUIREMENTS.md still reads Pending for EXPL-03 and is now stale |
| 12 | EXPL-04 / SC4: Search tag pills show their full text | VERIFIED | `SearchExpertCard.tagsRow` flow layout; `TopicsSetupFlowLayoutTests` |
| 13 | EXPL-05 / SC5: Favorites shows every favorite (paged), empty-state buttons work, copy is correct | VERIFIED | `FavoritesViewModel` on `PagedList`; paging tests. Caveat WR-05 below |
| 14 | EXPL-05 / SC5: profile favorite state comes from `is_favorite` | VERIFIED | Unchanged |
| 15 | EXPL-06 / SC5: the full reviews list loads beyond 20 reviews | VERIFIED | `ExpertReviewsViewModel` on `PagedList`; paging tests |
| 16 | EXPL-07: Explore loads with a free no-currency topic or one bad topic; no stale Featured Topics beside section errors | UNCERTAIN | Code: `LossyFeaturedTopic` + `compactMap` unchanged; the failure branch is byte-for-byte as before (`featuredTopics = []` then three `.failed(msg)`, lines 131-138), all 18 pre-existing `ClientHomeFeedTests` rows pass. Device 2026-11-12: initial load with a free no-currency topic and a Chinese-script title passed, and the airplane-mode load showed the readable sentence with Retry and no stale topics. The same checklist item failed on pull to refresh (G-04-3), so the requirement as a whole is not device-proven until the re-test passes. Pending by design |
| 17 | D-12 (04-01): a removed card is refused at T-24h, and a transient error while checking the platform card never cancels the booking | VERIFIED (scoped; post-stamp limit accepted) | Unchanged since the last verification: backend `28da165`, 50 cron tests passed on my earlier run. See "Truth 17" below |
| 18 | PAY-04: stale `TODO(backend): stripe_account` comments removed | VERIFIED | `grep -rn "TODO(backend)" ClickMe2026` returns 0 (unchanged) |
| 19 | CR-01 (04-15): the booking form is locked while a paid booking is in flight | PRESENT_BEHAVIOR_UNVERIFIED | `.disabled(viewModel.isSubmitting)` on five cards (`MakeABookingView.swift:71-83`); no test asserts the view is disabled; form-lock taps not run in D-11 |
| 20 | G-04-3 (04-17): a pull to refresh, section Retry or reappear load on Explore runs to the end even when the calling task is cancelled; loaded sections stay on screen during it; a cancelled fetch never leaves a section at idle; a category change still shows skeletons | VERIFIED (view-model level, 27 tests) | Code read plus my own run of `ClientHomeFeedTests`. The rows that carry the claim: "a refresh whose calling task is cancelled still loads the new feed", "a refresh after a failure whose calling task is cancelled still loads every section", "loaded sections stay on screen while a refresh is in flight", "a cancelled reload over loaded data keeps every section loaded", "a cancelled reload after a failure keeps the failure and its Retry", "a cancelled first load shows the generic failure, not a skeleton", "a cancelled fetch settles each section from the state before it", "a category change still shows skeletons while the filtered feed loads". Test (a) cancels the caller after the request arrives and releases a held response, then expects `.loaded` and the new title. Per the 04-17-SUMMARY, rows (a), (a2), (b) failed before the fix and (e), (g) failed before Task 2; I did not re-run the RED states. Wiring: `.refreshable` (`ExploreClientView.swift:142`), both Retry buttons (`:302`) and `.task` (`:147`) all call `reload()` or `load()`, which share the shield; `applySelectedCategories` calls `fetchHome(replacingLoadedContent: true)` (line 269). The cancel in the tests is `Task.cancel()`, not SwiftUI's own, which is why truth 21 exists |
| 21 | G-04-3 (04-17), device: ten pulls end loaded, the airplane-mode pull shows the offline sentence with Retry and no Featured Topics, and the pull after it loads | UNCERTAIN | The plan tags this `verification: backstop`; presence plus wiring plus unit tests never qualify (Step 5b of the process). The diagnosis is from code, not a debugger. Awaiting the device re-test. Not run |

**Score:** 17/21 truths verified (2 present, behavior-unverified: truths 4 and 19; 2 uncertain, awaiting device: truths 16 and 21; 0 failed)

### Truth 17: gap or accepted limit

Unchanged from the prior report. **Accepted limit, not a gap.** Plan 04-01's written prohibition is scoped to errors "while checking the platform card". That now holds end to end in `longLeadChargeSweep.js` `chargeOne`: the profiles select and `retrievePaymentMethod` both rethrow on a non-`resource_missing` error before the first `stampAttempt` (line 68), so an unstamped row is retried on the next 5-minute run and `scaRecoveryWindowSweep` never sees it. A transient error after the stamp still ends in a cancel at about 6 h (advisory WR-06, T-04-45), accepted by the user before the push. A persistent check error with no deadline (advisory WR-07, T-04-44) is also accepted. I did not re-run the backend suites this round; no backend file changed since.

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ExploreClientViewModel.swift` | `fetchHome(replacingLoadedContent:)`, shielded `load()`, `stateAfterCancelledFetch`, `interruptedLoadMessage` | VERIFIED | Substantive (358 lines, all four present); wired (`load()` line 82, cancel branch lines 125-129, category path line 269) |
| `ExploreClientView.swift` | one G-04-3 comment at `.refreshable`, no code change | VERIFIED | Comment at lines 140-141 above `.refreshable` |
| `ClientHomeFeedTests.swift` | G-04-3 section with `serveHeld`, `homeRequestCount`, `homeRequestArrived` and nine rows | VERIFIED | 27 tests (18 plus 9), all passed on my run |
| `MockURLProtocol.swift` | `recordedRequests` behind one lock | VERIFIED | `requestLock` (`NSLock`), private `requestLog`, `withLock` on read, write, reset and append; no stored `recordedRequests`. Review IN-03 notes `handler` is still unguarded (info) |
| `04-DEVICE-UAT-CHECKLIST.md` | item 1 step 4, Expected bullet, closes-table row | VERIFIED | Three "plan 04-17" references at lines 48, 51 and 601; Status line still PENDING, Result line still the FAIL, as the plan required |
| Prior Phase 4 artifacts (`MakeABookingViewModel+PaidAttempt.swift`, `+PaidFlow.swift`, `PaymentSheetOutcome.swift`, `ConfirmOutcome.swift`, `ConfirmRetryPolicy.swift`, `UnconfirmedBookingLedger.swift`, `PaymentLifecycleVariant.swift`, `HomeShellExit.swift`, `PagedList.swift`, `ExpertProfileSections.swift`, backend `longLeadChargeSweep.js`) | regression check | VERIFIED | Unchanged since the prior report (`git diff fbb4afd HEAD`) |
| Backend `master` | contains D-12 and CR-02 | NOT PRESENT (by design) | Pending todo `2026-11-11-merge-d12-into-backend-master.md`. `28da165` is on `ios-p4-d12` / `origin/main` |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.refreshable` and both section Retry buttons | `reload()` -> `load()` -> unstructured Task | `.value` | WIRED | `ExploreClientView.swift:142, 302`; `ExploreClientViewModel.swift:82, 233-235` |
| `fetchHome` cancel branch | `stateAfterCancelledFetch(current:before:)` | one call per section | WIRED | Lines 125, 127, 129; no `.idle` assignment in `fetchHome` |
| `applySelectedCategories` | `fetchHome(replacingLoadedContent: true)` | unstructured Task | WIRED | Line 269 |
| `.task { load() }` on Explore | same shielded fetch | | WIRED | `ExploreClientView.swift:147` |
| `beginPaidBooking` -> `completePaidBooking` -> `confirmBooking` / ledger | `paidAttempt` | snapshot | WIRED | Unchanged |
| `chargeOne` | `scaRecoveryWindowSweep` | stamp placed after the read-only checks | WIRED | Unchanged |
| `MakeABookingView` | `BookingRequestSentView` | `navigationDestination(item: completedBookingId)` | WIRED | Unchanged |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Explore Categories / Experts / Featured Topics | `categories`, `experts`, `featuredTopics` | `api.getClientHome(categorySlugs:)` -> `/client/home`, mapped in `fetchHome` | Yes | FLOWING |
| Explore Today's Sessions | `todaysSessions` | `api.getClientBookings(type: .upcoming)` | Yes | FLOWING |
| `completePaidBooking` request body | topic, slot, meeting type, notes, PI id | `paidAttempt` | Yes | FLOWING |
| `PaymentLifecycleCard`, heart, Favorites, Reviews | per prior report | | Yes | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| G-04-3 and EXPL-07 view-model behavior | `xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 ... -only-testing:ClickMe2026Tests/ClientHomeFeedTests` (iPhone 17, run alone) | "Test run with 27 tests in 1 suite passed after 0.356 seconds"; 0 `warning:` lines naming `ExploreClientViewModel.swift`, `ClientHomeFeedTests.swift` or `MockURLProtocol.swift` | PASS |
| Full iOS unit target | not re-run by me; the orchestrator reports `xcodebuild test -only-testing:ClickMe2026Tests` = 667 tests in 68 suites passed on 2026-11-12, and a post-merge BUILD SUCCEEDED | n/a | SKIPPED, taken from the orchestrator |
| Smoke suites that hit production (`AuthSmokeTests`, `SignupSmokeTests`) | not run, per instruction | n/a | SKIPPED |
| Backend suites | not re-run; no backend change since the last verification | n/a | SKIPPED |

## Probe Execution

Step 7c: SKIPPED. No plan declares a probe script, and `scripts/*/tests/probe-*.sh` is not used by this phase.

## Requirements Coverage

All 17 phase requirement IDs (BOOK-01..05, BOOK-19, PAY-01..04, EXPL-01..07) appear in plan frontmatter and in REQUIREMENTS.md. No orphans. Plan 04-17 declares `requirements: [EXPL-07]`. D-12 and D-13 are decision IDs, not REQUIREMENTS.md rows.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOOK-01 | 04-03 | No Back after request sent | SATISFIED (swipe lock behavior-unverified) | truths 3, 4 |
| BOOK-02 | 04-04 | Month change race | SATISFIED | truth 7 |
| BOOK-03 | 04-04 | Readable zone name | SATISFIED | truth 8 |
| BOOK-04 | 04-04 | 12/24-hour | SATISFIED (device toggle pending) | truth 8 |
| BOOK-05 | 04-03 | "Loading booking…" | SATISFIED | truth 5 |
| BOOK-19 | 04-03, 04-10 | Source-tab exits | SATISFIED | truth 6 |
| PAY-01 | 04-02 | Close sheet, no hold | SATISFIED (live step a PASS) | truth 1 |
| PAY-02 | 04-08, 04-13, 04-15 | Timeout retry lands on booking | SATISFIED in code and unit tests; live step d PASS; form lock and 3DS retry (WR-01) not run | truths 2, 19 |
| PAY-03 | 04-09 | Hold vs charge card | SATISFIED | truth 5 |
| PAY-04 | 04-02, 04-08 | Stale TODO comments removed | SATISFIED | truth 18 |
| EXPL-01 | 04-05 | 404 and retry | SATISFIED | truth 9 |
| EXPL-02 | 04-12 | Empty sections hidden | SATISFIED in code; device pending | truth 10 |
| EXPL-03 | 04-14 | "Free" label | SATISFIED (device PASS 2026-11-12) | truth 11 |
| EXPL-04 | 04-11 | Full-text tag pills | SATISFIED | truth 12 |
| EXPL-05 | 04-05, 04-06, 04-10, 04-12 | Favorites paged, buttons, copy, `is_favorite` | SATISFIED | truths 13, 14 |
| EXPL-06 | 04-11 | Reviews paging | SATISFIED | truth 15 |
| EXPL-07 | 04-14, 04-17 | Explore home-feed resilience | NEEDS HUMAN (Pending by design; G-04-3 fixed in code, device re-test pending) | truths 16, 20, 21 |

REQUIREMENTS.md still shows `[ ]` and "Gaps Found" for 15 of the 17 IDs (EXPL-03 and EXPL-07 read Pending). That table reflects the first report and is stale for the orchestrator to update. On the evidence above, BOOK-01..05, BOOK-19, PAY-03, PAY-04, EXPL-01, EXPL-02, EXPL-04, EXPL-05 and EXPL-06 can move off "Gaps Found". EXPL-03 has a device PASS and could be ticked. PAY-01 and PAY-02 should stay short of final until the rest of the D-11 session and WR-01 pass. EXPL-07 must stay Pending. I did not edit REQUIREMENTS.md.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| Debt markers (TBD/FIXME/XXX/TODO) in the Explore view model, `MockURLProtocol.swift`, `ClientHomeFeedTests.swift`, and the earlier `Make a Booking/`, `Utils/` files | n/a | none found | none | n/a |
| `ExploreClientViewModel.swift` | 81-117, 264-270 | no ordering or latest-wins gate between concurrent fetches (04-REVIEW WR-01) | Warning (advisory, open) | wrong data for a narrow timing window; see advisory list |
| `ExploreClientViewModel.swift` | 329-350 | a system-cancelled filter fetch restores the previous filter's experts as `.loaded` (04-REVIEW WR-02) | Warning (advisory, open) | rare; silent wrong data |
| `ExploreClientViewModel.swift` | 338-339 | the doc comment's invariant ("while `.loading`, the fetch that set it is in flight") is stronger than the code (04-REVIEW WR-03) | Warning (advisory, open) | transient flicker only; comment is misleading |
| `ExploreClientViewModel.swift` | 131-138 | a failed refresh over loaded data still wipes the content (04-REVIEW IN-01) | Info | pre-existing; the plan keeps the EXPL-07 failure path on purpose |
| `MockURLProtocol.swift` / `ClientHomeFeedTests.swift` | 17, 30-33; 104-129, 343-470 | `handler` unguarded; held-response tests park the URL protocol thread and use wall-clock polling (04-REVIEW IN-03, IN-04) | Info | test reliability; I saw no flake in my one run |
| Backend `longLeadChargeSweep.js` | 167-172, 127 | WR-06 and WR-07 | Warning (accepted) | user-accepted limits; T-04-45, T-04-44 |
| `ExpertProfileViewModel.swift` | 108-114 | any reload error replaces a loaded profile with the full-screen error (WR-02 of the earlier review) | Warning (open) | |
| `FavoritesViewModel.swift` | 140-163, 204-233 | refresh can resurrect a row being unfavorited (WR-05 of the earlier review) | Warning (open) | |
| `04-DEVICE-UAT-CHECKLIST.md` | 10, 20 | still names `ae3ec1a` as production and `32fa6ec` as the rollback base; production is now `28da165`, rollback base `ae3ec1a` | Warning | The D-11 session already ran. Before any further live step (c, e, g), correct these: rolling back to `32fa6ec` would remove D-12 and CR-02 |

`04-REVIEW-DISPOSITION.md` records CR-01 and CR-02 as fixed, WR-06 and WR-07 as deferred, and the rest, including the three Explore warnings, as open and not triaged.

## Human Verification Required

See the `human_verification` and `behavior_unverified_items` frontmatter. In short:

1. **G-04-3 / EXPL-07 pull-to-refresh re-test (checklist item 1 step 4).** The one item that decides whether the blocker is closed. It needs a build containing 1e9ddde and cc50bb9. If a skeleton outlives the spinner, G-04-3 is not fixed and phase 4 reopens for it.
2. **WR-01, the 3DS retry `pm_` id.** Blocked on a card that triggers 3DS.
3. **D-11 steps c, e, g and the form-lock taps**, which the user skipped or deferred on 2026-11-12.
4. **Checklist items 3 to 22**, never run.
5. Two behavior-unverified truths (4 and 19), both inside the lists above.

## Gaps Summary

No gaps. G-04-3, the only gap from the device session, is fixed in the code I read and in the 27 tests I ran, and I found no regression in the other 19 truths. It is not closed on hardware, so it is not counted as closed. The three open review warnings are real but none stops Explore from loading, and they are recorded as advisory with a suggested follow-up (a generation token for Explore fetches, plus telling the cancel settle step about `replacingLoadedContent`). Nothing in later milestone phases (5 to 8) covers any of this, so nothing was deferred.

What keeps this from `passed`: the project's definition of done requires a device check on a real iPhone, and the G-04-3 re-test, WR-01 and most of the checklist have not run.

---

_Verified: 2026-11-13_
_Verifier: Claude (gsd-verifier)_
