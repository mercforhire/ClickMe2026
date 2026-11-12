# Phase 04 — UI Review

**Audited:** 2026-11-12
**Baseline:** `04-UI-SPEC.md` (approved, force-approved 2026-11-11), with `04-CONTEXT.md` decisions D-01 to D-14
**Screenshots:** not captured (native SwiftUI iOS app; no dev server or browser target; static source audit as instructed)
**Interaction captures:** off (`interaction_capture: false`)

**Method:** Static audit of the SwiftUI source against the UI-SPEC copy table, delta contracts, spacing and typography declarations, and color reserved-use list. Copy strings were grepped for exact match. Layout, state and paging logic were read in the files. Tests were not run. Device-only items in the contract (D1 to D4, the real-money session) are not verifiable here and are marked as such.

**Coverage note:** The contract, the code review (`04-REVIEW.md`), and the source were the primary inputs. I extracted key-files from all 16 SUMMARY files, but I did not read each SUMMARY and PLAN in full. Findings that depend on plan intent are stated as code-observed, not plan-verified.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Every new contract string is present and exact; one silent failure path (Expert Profile Message CTA) has no copy at all |
| 2. Visuals | 3/4 | Focal points and state views are built as specified; accent competes with the focal CTA on the Expert Profile hero and the payment card badges |
| 3. Color | 2/4 | Accent is used on at least 8 elements outside the contract's six reserved uses on Phase 04 surfaces; hardcoded literals in changed files |
| 4. Typography | 3/4 | New text uses the declared 12/15/16 pt sizes; the payment card header adds a Bold (700) weight, and state icons on two surfaces use Light |
| 5. Spacing | 3/4 | New values (8, 16, 24, 32, 48) match the tokens; undeclared off-grid values (10, 3, 13, 14) remain in touched files |
| 6. Experience Design | 2/4 | Loading, error, empty and paging states are implemented, but one unresolved 3DS defect may block paid completion, and four race or stale-state defects remain |

**Overall: 16/24**

---

## Top 3 Priority Fixes

1. **3DS retry may send the wrong payment method id, so a paid booking fails after successful verification** (BLOCKER, unverified on device). User impact: the client completes 3D Secure and the booking still fails, with the hold possibly left behind. Fix: keep `confirmPaymentMethodId` through the SCA round trip, do not nil it on `paymentRequiresAction`, and have `retryConfirmAfterSCA` use the platform `pm_` id. Verify on device with a 3DS-required test card before release.

2. **A failed background re-load replaces an already-loaded Expert Profile with "Couldn't load profile"** (WARNING, WR-02). User impact: returning from Make a Booking, Reviews or the report sheet on a flaky connection swaps a full profile for an error and removes the heart and menu. Fix: in `ExpertProfileViewModel.loadProfileDetails()`, return early when `loadState` is already `.loaded` on a non-404 error; keep `.notFound` for a 404.

3. **Returning to Make a Booking silently clears the chosen time slot** (WARNING, WR-04). User impact: after adding a card and popping back, the slot the client picked is gone and the calendar returns to the skeleton. Fix: call `loadAvailability` only once per screen instance, and clear `selectedTimeSlot` only in `goToPreviousMonth` and `goToNextMonth`, not inside `loadAvailability`.

---

## Contract Status Summary

| Contract area | Status | Evidence |
|---------------|--------|----------|
| Status line `Confirming your booking…`, VoiceOver announcement | Implemented | `MakeABookingView.swift` (`confirmingStatusText`, `showsConfirmingLine`, `AccessibilityNotification`) |
| Retries-exhausted alert: title, message, Try again / Check My Bookings / Not now | Implemented | `MakeABookingView.swift` alert block; `MakeABookingViewModel+PaidFlow.swift` `PaidFlowAlert` |
| D-04 alert `You may already have this booking.` with `Check My Bookings` and `Close Alert` | Implemented | `MakeABookingViewModel+PaidFlow.swift`, `MakeABookingView.swift` |
| Form locked while submitting (CR-01 UI lock) | Implemented | `MakeABookingView.swift` `.disabled(viewModel.isSubmitting)` on all five cards |
| Confirm snapshot of topic, slot, PI (CR-01 data) | Implemented | `MakeABookingViewModel+PaidAttempt.swift`; `MakeABookingViewModel.swift` line ~585 reads `attempt` |
| Slot time-zone label (device zone, omitted when no name) | Implemented | `DateUtil.zoneName()`, `MakeABookingTimeSlotsCard.swift` |
| Request Sent: Back hidden, swipe lock, pinned exits in loading and error | Implemented | `BookingRequestSentView.swift`, `BookingRequestSentPopGestureLock.swift`, `BookingRequestSentActions.swift(spacing:)` |
| Payment card three variants, fail-closed chooser | Implemented | `PaymentLifecycleVariant.swift`; copy strings exact |
| Expert Profile `notFound` and `failed` states, heart and menu removed | Implemented | `ExpertProfileStateView.swift`, `ExpertProfileView.swift` (`showsProfileActions`) |
| Hero `No reviews yet` / `(1 review)` | Implemented | `ExpertProfileSections.swift`, `ExpertProfileHero.swift` |
| Empty Expertise, Topics and Reviews sections not rendered | Implemented | `ExpertProfileView.swift` `ExpertProfileSections.show*` |
| Favorites Pro Tip copy, empty buttons wired, paging footer | Implemented | `FavoritesProTipCard.swift`, `FavoritesEmptyState.swift`, `FavoritesPopulatedList.swift` |
| Reviews paging footer and Retry | Implemented | `ExpertReviewsView.swift` `pagingFooter` |
| Search tag pills: no `lineLimit`, flow layout 8/4, cap of 3 | Implemented | `SearchExpertCard.swift` |
| Suspension alert on cold launch with `Close Alert` | Implemented | `LoginView.swift`, `SuspensionNotice.swift` |
| Explore `Today's Sessions` device-zone label and short time range | Implemented | `ExploreTodaysSessionsSection.swift`, `ExploreClientViewModel.timeRangeString` |
| Request Sent `whenLabel` uses 12/24-hour setting (K3, listed unresolved) | Implemented (recommendation applied) | `BookingRequestSentViewModel.whenLabel` uses `DateUtil.shortTime`. The contract still lists K3 as unresolved; update the contract |
| Device-only checks D1 to D4, real-money session | Not verifiable statically | Pending device session |

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

Every new string in the Copywriting Contract matches exactly. I grepped each one. Confirmed: `Confirming your booking…`, `We couldn't confirm your booking`, the retry message with `Payment reference: {pi}`, `Try again`, `Check My Bookings`, `Not now`, `Close Alert`, `You may already have this booking. Check My Bookings.`, `Loading booking…`, `Tap the heart icon on any expert's profile to add them to this list instantly.`, `This profile isn't available`, `This expert may no longer be on ClickMe. Go back and try someone else.`, `Couldn't load profile`, `No reviews yet`, `Couldn't load more favorites`, `Couldn't load more reviews`, `Your account has been suspended`, the suspension body with `clickmeapp@uptrendinvestments.net`, the three payment variant headers and step copy, `Booking Request` navigation title, and `Explore Experts` / `View My History`.

Findings:

- **WARNING: Silent failure on the Message CTA, no user copy.** `ExpertProfileView.swift` around line 465 catches the `initiateChat` error and does nothing. The TODO states the intent to surface it through `apiError`. A tap that fails produces no feedback. Fix: set `viewModel.apiError` (or an alert) with `error.userMessage` in that catch.
- **INFO: Single-word `OK` alerts remain on Favorites and Expert Profile** (`FavoritesView.swift:108`, `ExpertProfileView.swift:296, 322`, `ExploreClientView.swift:165`). These are pre-existing and outside Phase 04's listed deltas. Recorded for completeness; the contract accepted single-word `Retry` and `Back` flags.
- **INFO: Copy drift against Android is logged, not a defect.** `Close Alert` vs `OK` on suspension, and the D-03/D-04 wording, are both acknowledged in the contract's Android follow-ups.

### Pillar 2: Visuals (3/4)

What works:

- The `notFound` and `failed` state view (`ExpertProfileStateView.swift`) follows the contract: icon at title size in Regular weight, heading, message, single 48 pt capsule. Heart and menu are removed from the toolbar for both states.
- The Request Sent loading and error states show the pinned exit capsules. The loaded layout is unchanged.
- The `Confirming your booking…` line is centred 8 pt above the Book button, and it is hidden while an alert is up.

Findings:

- **WARNING: Accent competes with the focal CTA on the loaded Expert Profile.** `ExpertProfileHero.swift` lines ~32, 46, 57, 59, 80, 83 and 102 apply `brandGreen`/`Brand.primary` to the expert title, the avatar glow, the avatar ring, its shadow, the verified badge, and the rating star (`starYellow = Brand.primary`, named yellow but green). The contract's focal-point rule says nothing else on the screen takes the accent at the same weight. The hero is pre-existing, but the screen is a Phase 04 surface. Fix: reserve accent for the Book action and the state capsules, or document the hero as an exception in the contract.
- **WARNING: Payment card step badges use accent** (`PaymentLifecycleCard.swift`, `iconBadge` and `connectorColor` use `Brand.primary`). This is not in the reserved list. It sits on the Request Sent loaded screen beside the `View My Bookings` capsule. The fill is 18% opacity, so the effect is subordinate. Fix: use `Brand.onSurfaceVariant` for step icons, keeping accent for the done checkmark only if the contract is amended.
- **INFO: Dead ternary in `PaymentLifecycleCard.titleColor`** returns `Brand.onSurface` in both arms (code review IN-03). No visual effect today; remove it.

### Pillar 3: Color (2/4)

The contract's accent reserved list has six items on Phase 04 surfaces. Code uses accent outside that list:

- Expert Profile hero: title, avatar glow and ring, verified badge, rating star (`ExpertProfileHero.swift`).
- Request Sent payment card: step badges and connector lines (`PaymentLifecycleCard.swift`).

The "never use accent" list is respected: the zone labels, `No reviews yet`, money amounts and the payment card body text use secondary or primary text colors. The `Confirming your booking…` line uses `onSurfaceVar`. The filled favorite heart stays `.red`. The Pro Tip lightbulb uses accent, which is reserved item 6.

Hardcoded literals in files the contract lists as changed:

- `ExploreTodaysSessionsSection.swift`: `.white` and `.white.opacity(0.65)` for the header, the zone label and session text. The contract's zone-label style is "the section's secondary color". Fix: use `Brand.onSurfaceVariant`.
- `FavoritesEmptyState.swift`: `Color(red: 0.13, green: 0.14, blue: 0.15)` for the `View My History` capsule fill, and `Color.white.opacity(0.12)` for its stroke. Fix: a `FavoritesBrand` alias.
- `FavoritesBrand.swift` defines its own `onSurfaceVar` literal and `bg` pure black. The contract sanctions these per-screen aliases, so no fix is required beyond the note.

Pillar 3 scores 2 because of the reserved-list gaps, not because of the palette itself. A lenient reader could give 3 by treating the hero as pre-existing; the contract's list does not carve it out.

### Pillar 4: Typography (3/4)

Declared scale: 12 pt caption, 15 pt subheadline, 16 pt callout; weights Regular and Semibold. The new and changed text on the state views, footers and status line matches (`caption` 12 Regular, `subheadline` 15 Regular and Semibold, `callout` 16 Semibold).

Findings:

- **WARNING: Bold (700) weight on the payment card header.** `PaymentLifecycleCard.swift` sets `What happens next` to `.subheadline, weight: .bold`. This is a third weight on a changed surface. The contract's out-of-contract list does not cover this header. Fix: `weight: .semibold`.
- **WARNING: Light (300) icons on state views.** `BookingRequestSentView.swift` (error icon, around line 187), `ExpertReviewsView.swift` (empty-state icon, around line 167) and related icons use `.font(.title.weight(.light))`. The contract's state-view icon rule says Regular (400). The `ExpertProfileStateView` icon follows the rule (`.regular`), so the app is internally inconsistent. Fix: `.regular`, or amend the contract to name the Request Sent and Reviews icons as existing.
- **INFO: Text-style count across touched screens is high.** The sweep found nine text styles on the Phase 04 files (`caption2` to `title`). Most are pre-existing and listed in the contract's out-of-contract section. No new point-size text was found. `FavoritesGlowingStar` uses fixed point sizes (90 to 130 pt) for a decorative glyph, which is pre-existing and not text.

### Pillar 5: Spacing (3/4)

Phase 04 tokens are used in the new code: 8 (status line gap), 16 (pinned exit gap and footer padding), 24 (state view padding), 32 (Back capsule padding), 48 (capsule height and bottom padding). The pinned exit placements use the 16 pt spacing parameter, and the loaded layout keeps 14 by default. Both match the contract.

Findings:

- **WARNING: Off-grid values in touched files that the contract does not declare.** The contract's exemption list covers 14, 18 and 22 (pt by 10). It does not cover these:
  - `MakeABookingTimeSlotsCard.swift`: `HStack(spacing: 10)` for chips, and chip `.padding(.vertical, 10)`.
  - `PaymentLifecycleCard.swift`: `VStack(spacing: 3)` for step text, `.padding(.bottom, 14)` on the header, connector `.padding(.leading, 13)`.
  - `FavoritesProTipCard.swift`: `VStack(spacing: 3)` and `.lineSpacing(3)`.
  - `FavoritesEmptyState.swift`: `VStack(spacing: 14)` for the buttons.

  Some of these may be pre-existing, but the contract says every new or changed value is a multiple of 4. Fix: round to 4 or 8 where the file is changed, or add them to the inherited list with the reason.
- **INFO: Reviews and Favorites lists use 14 pt row spacing** (`LazyVStack(spacing: 14)`). Pre-existing and inherited, not Phase 04.
- **INFO: Trailing bottom padding on Expert Profile.** When Reviews is hidden, the preceding card's 28 pt bottom padding remains as the scroll tail. The contract says no blank gap remains. This is a tail margin, not an inter-section gap, so it is recorded only.

### Pillar 6: Experience Design (2/4)

Implemented and verified in code:

- Loading: `Loading booking…` with pinned exits; `Confirming your booking…` with the spinner; Expert Profile seeded profile while loading.
- Error: Request Sent error with Retry and pinned exits; Expert Profile `failed` with an in-place spinner on Retry; paging footer error with Retry; `We couldn't confirm your booking` with three actions.
- Empty: Favorites empty state with both buttons wired (`onExplore`, `onViewHistory` through `HomeShellExit`); Reviews `No reviews yet`; Expert Profile sections hidden; slots `No available slots on this day.`
- Disabled: Book button disabled while submitting; form locked while submitting; month arrows disabled outside the current month.
- Double-submit: `isSubmitting` and `isConfirmRunning` guards; `retryConfirm` is a no-op unless the flow is waiting.
- Paging: 20 per page, trigger window 3, stop on `hasMore == false`, duplicate-key guard in `PagedList`.
- Swipe-back: disabled on Request Sent through the UIKit lock.

Findings:

- **BLOCKER (unverified on device): 3DS retry may send the wrong payment method id.** `MakeABookingStripePaymentSheet.swift`, in the `.succeeded` branch, takes `paymentIntent?.paymentMethodId` from the SDK and passes it to `retryConfirmAfterSCA(paymentMethodId:)`. `MakeABookingViewModel.swift` (`serverCoded` branch, around line 627) sets `confirmPaymentMethodId = nil` before `handlePaidFlowError`, and `.paymentRequiresAction` (around line 672) routes to the SCA sheet. `retryConfirmAfterSCA` ignores the stored id. If the SDK returns the connected-account clone's `pm_` id, the platform-account retrieve in `/bookings/confirm` fails and the user finishes 3DS with no booking. This matches code review WR-01. It needs one device run with a 3DS-required test card before it can be closed. Fix: keep the platform `pm_` through the SCA round trip and use it in `retryConfirmAfterSCA`.
- **WARNING (WR-02): Failed re-load replaces a loaded profile.** `ExpertProfileViewModel.loadProfileDetails()` sets `loadState = .failed(...)` on any non-cancellation error, including when `loadState` is already `.loaded`. `.task { loadProfileDetails() }` reruns on every appearance. Fix: `if case .loaded = loadState, !Self.isNotFound(error) { return }` before assigning.
- **WARNING (WR-04): Slot selection cleared on every appearance.** `MakeABookingViewModel.loadAvailability(for:)` sets `selectedTimeSlot = nil` when `!isSubmitting` (around line 355). `onAppear()` calls it on every appearance, including returning from Payment Methods. The calendar also goes to the skeleton. The contract's delta section 5 says a month change must not show a previous month's slots; it does not require a slot reset on every appearance. Fix: clear only on month change, and load once per instance.
- **WARNING (WR-03): Explore has no latest-wins gate.** `ExploreClientViewModel.applySelectedCategories` (around line 233 to 236) fires a new `reload()` per change. `load()` and `reload()` write `experts`, `featuredTopics` and the states after each `await` with no generation check. A slow earlier response can overwrite the newer category filter while the chip shows the newer selection. The contract's N1 and Z2 rows do not cover this, but the Make a Booking fix (`ReloadGeneration`) set the precedent. Fix: reuse `ReloadGeneration` and check `isCurrent` after each await.
- **WARNING (WR-05): Unfavorite can be undone by an in-flight refresh.** `FavoritesViewModel.removeFavorite` removes the row before the DELETE completes and does not bump `generation`. A `refresh()` started earlier can complete afterwards and replace the list, bringing the removed expert back. Expert Profile opened from Favorites also does not refresh the list after an unfavorite (the `.task` skips when `.loaded`). Fix: track in-flight removal ids and filter them out of refresh and page responses; use the `onFavorite` hook to remove the row.
- **WARNING (IN-05): Paid-flow alert binding ignores dismissal.** `MakeABookingView.paidFlowAlertBinding` has a no-op setter. The `Check My Bookings` action in the confirm alert does not clear `paidFlowAlert`. If the screen stays on the stack (for example when `showMyBookings` is nil in a preview or a future embed), the flow stays `.confirming`, the Book button stays disabled, and the alert can re-present. Fix: clear `paidFlowAlert` synchronously in each button action.
- **WARNING: Silent Message failure** (see Pillar 1).

Registry audit: `components.json` does not exist, and the contract declares no third-party registry. Registry Safety section not applicable.

---

## Cross-Project Note (not scored in this UI audit)

The code review's **CR-02** is a backend defect in the D-12 sweep (`ClickMe2026 Backend D12/src/cron/longLeadChargeSweep.js`). A transient Stripe error at the platform-card check leaves a booking stamped, and the scaRecovery sweep then cancels it about six hours later. It affects paid bookings and notifications. It is not a UI defect, so it is not scored here, but it should be treated as a release blocker. The fix (move the read-only check before the stamp, and add a two-run test) is in the review. I did not verify it.

---

## Reviewer Status Notes

- **Code review CR-01 is addressed in the current tree.** The `PaidAttempt` snapshot exists (`MakeABookingViewModel+PaidAttempt.swift`, read at `MakeABookingViewModel.swift` line ~585), and the form is locked while submitting (`MakeABookingView.swift`, five `.disabled` modifiers). The review's fix list is stale on this point. I did not run the tests that would confirm the snapshot behaviour.
- **Contract K3 is applied in code** (`whenLabel` and the time range both use `DateUtil.shortTime`). The contract still lists K3 as unresolved. Update the contract.
- **Contract K1 is unchanged in code** (the Request Sent pill reads `Awaiting Approval`). Still an open planner assumption.
- **Device checks not performed here:** D1 (sheet close places no hold), D2 (swipe-back from each source tab), D3 (variant A live hold, `Free` price, Explore load), D4 (suspension alert on cold launch), L5 (largest Dynamic Type), T1 (12/24-hour toggle while running), and the real-money session. These are required before the phase is accepted.

---

## Files Audited

Make a Booking:
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidFlow.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel+PaidAttempt.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingBookButton.swift`
- `ClickMe2026/Views/Screens/Client Mode/Make a Booking/Subviews/MakeABookingCalendarCard.swift`

Request Sent:
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentActions.swift`
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/BookingRequestSentPopGestureLock.swift`
- `ClickMe2026/Views/Screens/Client Mode/Request Sent/Subviews/PaymentLifecycleCard.swift`

Expert Profile, Favorites, Reviews, Search, Explore, Login:
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileStateView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileHero.swift`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesEmptyState.swift`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesProTipCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift`
- `ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift`
- `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`
- `ClickMe2026/Views/Screens/Client Mode/Explore/Subviews/ExploreTodaysSessionsSection.swift`
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` (exit wiring)
- `ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift` (suspension alert)

Shared:
- `ClickMe2026/Utils/PaymentLifecycleVariant.swift`
- `ClickMe2026/Utils/DateUtil.swift`
- `ClickMe2026/Utils/SuspensionNotice.swift`
- `ClickMe2026/Utils/ExpertProfileSections.swift`
- `ClickMe2026/Utils/BookingErrorMapper.swift` (copy reference)
- `ClickMe2026/Theme/Brand.swift` (token existence)

Planning artifacts:
- `.planning/phases/04-booking-payment-and-discovery/04-UI-SPEC.md`
- `.planning/phases/04-booking-payment-and-discovery/04-REVIEW.md`
- `.planning/phases/04-booking-payment-and-discovery/04-CONTEXT.md` (decision references only)
- SUMMARY files: key-files extracted; full read not performed

Not run: tests, `xcodebuild`, SwiftLint, device or simulator checks, screenshot capture.
