# Phase 4: Booking, Payment and Discovery - Context

**Gathered:** 2026-11-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Clients can find an expert, book and pay without double submissions, unintended holds, misleading errors or missing profile data. Requirements: BOOK-01, BOOK-02, BOOK-03, BOOK-04, BOOK-05, BOOK-19, PAY-01, PAY-02, PAY-03, PAY-04, EXPL-01, EXPL-02, EXPL-03, EXPL-04, EXPL-05, EXPL-06, EXPL-07.

This phase is mostly in the iOS repo. It also has three folded todos (see Folded Todos). One of them is **backend money code**, committed in `../ClickMe2026 Backend` as its own plan and deploy. It must stay safe for build 6 and current Android. A second is an **Android device check only** (no iOS code). Android mirrors iOS behavior (root `CLAUDE.md`), so record each behavior change here (PAY-01, PAY-02, BOOK-01/19, EXPL-05, EXPL-01) as a likely Android follow-up, and say so explicitly. Do not assume Android already has it.

Every environment points at the **production backend with live Stripe keys**. PAY-01, PAY-02 and the folded card-removal fix place and release real holds.

Status notes that don't block planning: Phase 2 UAT is partial (11 tests pending) and Phase 3 UAT is partial (3 device-blocked, plus the 03-REVIEW-FIX WR-03..09 device checks). Both must be run before the Phase 8 release. EXPL-07 and the EXPL-03 "Free" label were already built in quick 261109-323 and only need the device check here. PAY-04 is comment-only and is verified in code review. EXPL-02 is a LIKELY item, so confirm it on a device before fixing it.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- **Money (Phase 2 D-09 to D-11):** every amount on these screens (Request Sent payment card, featured topic prices, "Free") uses the shared minor-units formatter (`CA$45.00`).
- **Tab-owned stacks (Phase 2 D-04):** a destination opens on the stack of the tab that owns it, and Back returns to that tab's root. Navigation decisions below follow this.
- **Booking window (Phase 2 D-13, BOOK-14):** paid pickers keep the 6-day cap and the shared long-lead error mapper.
- **Toasts (Phase 3):** `ToastCenter` / `ToastHost` exist in both shells (WR-05). Use them only where a decision below asks for a toast.

### Q4 / PAY-01: closing the card sheet
- **D-01: Q4 is settled as cancel (Android parity).** When the client closes the FlowController card sheet (swipe down or X), the booking is cancelled even if a saved card is preselected: there is no confirm and no hold. Only tapping the sheet's Continue/confirm proceeds. Use the `presentPaymentOptions` variant with a `didCancel` flag. It exists in the shipped stripe-ios 26.2.0 (CHANGELOG, PR #5202; `PaymentSheetFlowController+AsyncPublicAPIs.swift`). Do not rely on `paymentOption != nil`. Today's check is at `MakeABookingStripePaymentSheet.swift:101-106`. — **Reversibility:** reversible
- **D-16 (decided 2026-11-11, after research):** In the same edit as PAY-01, turn Stripe Link off in the iOS payment sheet configuration (`config.link.display = .never`), matching Android's BUG-07 fix. — **Reversibility:** reversible
- **D-02:** After a cancel, the reset is **silent**: no toast and no alert. The client stays on the booking form with the topic and slot still selected, and Book Now is enabled again. This is consistent with today's silent reset after a 3DS cancel (P4, by design).

### PAY-02: confirm timeout and retry
- **D-03:** When `POST /bookings/confirm` fails with a **transport timeout or lost connection**, the hold may already exist. The app does not call `resetPaidFlow()` and keeps the payment intent id, the `pm_…` and the `booking_attempt_id`. It stays on "Confirming…" and **automatically retries the same confirm** (same PI, same card) a small bounded number of times (1–2). A replayed 201 (BACK-15 replays by an ownership-checked lookup on `payment_intent_id` for active bookings) lands on **Request Sent for that booking**, exactly like a first-time success. If the retries still fail, show "We couldn't confirm your booking" with a **Try again** button that reuses the same PI. Server-coded errors (402, 409, 422 and so on) keep today's `handlePaidFlowError` mapping, and only transport failures take this path.
- **D-04:** If a later attempt in this app session hits `SLOT_UNAVAILABLE` after a confirm for the **same expert and slot** timed out or was abandoned, the error reads **"You may already have this booking. Check My Bookings."** with a button that opens My Bookings. That attempt could be a new attempt after leaving the form, or after the retries ran out. Every other `SLOT_UNAVAILABLE` keeps today's copy and slot reset. The planner decides whether "this device" survives an app relaunch; a session-only record is acceptable.
- **D-17 (decided 2026-11-11, plan check):** `409 PAYMENT_IN_PROGRESS` from `POST /bookings/confirm` (the backend's concurrent-confirm response, `booking.controller.js` ~L630/L1441) is treated as **outcome unknown**, an amendment to D-03 for this one code only. The app keeps the same PI, `pm_…` and `booking_attempt_id`, retries within the same bounded D-03 limit, and **never clears the D-04 record** on this code. — **Reversibility:** reversible
- **D-15 (decided 2026-11-11, after research):** Production returns **`409 DUPLICATE_BOOKING` with `detail.booking_id`** at `/bookings/payment-intent` when the caller already has the same active booking (`STRIPE-INTEGRATION.md:89,408,420`). **Smart route:** if the app's own record shows an unknown or abandoned confirm for that expert and slot (the D-04 record), open **Request Sent for `detail.booking_id`**. Otherwise show the D-04 alert ("You may already have this booking. Check My Bookings.", with a button that opens My Bookings). D-04 is still built as written for `SLOT_UNAVAILABLE`, as a backstop. — **Reversibility:** reversible

### BOOK-01 / BOOK-19: Request Sent navigation
- **D-05:** Request Sent **hides Back and disables the interactive swipe-back**. Its only exits are "View My Bookings" and "Back to Home", so the booking form can no longer be reached or resubmitted. Keep the current push from `MakeABookingView` (`navigationDestination(item: $viewModel.completedBookingId)`). No stack surgery.
- **D-06:** Both exits **reset the source tab's stack**: whichever tab started the flow (Explore, Search, or Profile via Favorites). Today `HomeClientView.swift:87-94` resets only explore (and bookings). "Back to Home" resets the source tab and switches to **Explore**. "View My Bookings" resets the source tab and Bookings, then switches to **Bookings**. No tab is ever left holding the booking flow.

### EXPL-05 / EXPL-06: Favorites and reviews paging
- **D-07:** Favorites uses **infinite scroll**: pages of 20 via `page`/`limit` (`ClickMeAPI+Favorites.swift`; the server clamps `limit` to 1–100), fetching the next page near the bottom and stopping at the server's total. Pull-to-refresh restarts at page 1. The full Reviews list (EXPL-06, `ExpertReviewsViewModel.swift:102`) uses the **same paging pattern**.
- **D-08:** The empty-state buttons (`FavoritesEmptyState.swift`, wired from `FavoritesView.swift:117`) work. **"Explore Experts"** resets the Profile stack and switches to Explore. **"View My History"** resets the Profile stack and opens the Bookings tab on its **past/completed list**.
- **D-09:** The Pro Tip copy (`FavoritesProTipCard.swift:31`) says **"heart"**, not "star". The profile's favorite control is `heart` / `heart.fill` (`ExpertProfileView.swift:239`). A profile's favorite state comes from the profile response's `is_favorite` (`publicProfile.controller.js:289-299`), not a scan of the favorites list.

### EXPL-01: unavailable profiles
- **D-10:** A **404** expert profile shows **"This profile isn't available"** with a **Back** button only. There is no retry, because a 404 won't change. A favorited expert is **not** removed automatically and no Remove button is offered: the entry stays in Favorites until the server stops returning it. A **network/transport error** gets a separate "Couldn't load profile" state with **Retry**. This replaces the `try?` at `ExpertProfileViewModel.swift:68-69`. The migration `20261016000100_discovery_hide_moderated_users.sql` appears to make `list_favorite_experts` hide moderated experts already. Research must confirm this. If so, a 404 from Favorites mostly means a deleted account or a race.

### Real-hold device testing
- **D-11:** Phase 4 runs **one combined real-money device session** on the user's own client and expert accounts. It covers PAY-01 (closing the sheet places no hold), PAY-02 (forced timeout then retry lands on Request Sent, which also exercises the BACK-15 confirm replay for backlog 999.2), the folded card-removal fix (D-12), and the deferred Phase 1 real-Stripe checklists **01-17** (BACK-06, BACK-07, BACK-15) and **01-19** (BACK-19). That closes backlog items 999.1 and 999.2. **Every hold placed is released or refunded before the session ends.** BACK-06, 07, 15 and 19 move to Complete only when this session passes. Note from 999.1: the 01-19 checklist does not prove the failed-refund retry.

### Claude's Discretion
- How the PAY-02 transport-failure path is detected (`URLError` codes versus `NetworkError`), and the exact retry count (1–2) and spacing.
- Whether the D-04 "abandoned confirm" record survives a relaunch.
- BOOK-02 (cancel the previous month's availability task and check the month before assigning), BOOK-03 (`TimeZone.localizedName`), BOOK-04 (`timeStyle = .short`), BOOK-05 ("Loading booking…"), EXPL-04 (full tag pill text, as on Android) and PAY-04 (delete the stale `TODO(backend): stripe_account` comments) follow the inventory's suggested fixes. They were not discussed.
- **D-18 (decided 2026-11-11, plan check; locked, not discretion):** ROADMAP SC3 is honored as written. **Today's Sessions** on Explore also shows the device's readable time-zone name, using the same helper as the slots card (BOOK-03). It is not only the 12/24-hour fix (BOOK-04). — **Reversibility:** reversible
- PAY-03 lifecycle card copy: describe hold versus charge correctly from the booking's payment state, including older long-lead rows (inventory P3). This was not discussed, so use the existing Phase 3 refund and hold wording style.

### Folded Todos
- **Handle PaymentSheet card removal on the backend** (`.planning/todos/pending/2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md`). T-01-32 is an accepted risk that must be fixed before the iOS release. Removing a card inside Stripe's PaymentSheet bypasses BACK-07, there is no `payment_method.detached` handler, and `longLeadChargeSweep.js:309,332` charges the cached connected-account clone unchecked.
  - **D-12:** This gets its **own backend plan and deploy**. Handle `payment_method.detached`, evict the clones (`connectedPaymentMethodClone.js`), and check the platform card before off-session charges. It needs backend tests, and the deploy must be safe for build 6 and current Android (check Android's SDK default for sheet removal). It is deployed **before** the D-11 device session, which then removes a card in the sheet and confirms it can't be charged. — **Reversibility:** costly — this is a production webhook and charge-path change on live Stripe, and undoing it needs a redeploy while real holds may be in flight.
- **Show the suspension message on a cold launch** (`.planning/todos/pending/2026-11-08-show-the-suspension-message-on-a-cold-launch.md`). `tryAutoLogin` returns `true` after a 403 `ACCOUNT_SUSPENDED`, and nothing reads `UserManager.wasSuspended` (`UserManager.swift:34`).
  - **D-13:** **Fix it from the code, without a device repro first.** On a cold launch, a suspension routes to Login (not home) and shows the suspension message from `wasSuspended`. Add a unit test. The device check happens in the release pass. Record whether Android needs a matching change.
- **Check the Android push prompt after a reinstall** (`.planning/todos/pending/2026-11-08-check-the-android-push-prompt-after-a-reinstall.md`).
  - **D-14:** **Check only.** Reinstall the Android app while signed in and record whether the push prompt appears (`PushPermissionRequester.kt`). If there's a gap, file a new todo for the fix. No code change in this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and inventory
- `.planning/ROADMAP.md` § Phase 4: goal, success criteria, notes (Q4, real holds, EXPL-02 likely, EXPL-07/EXPL-03 device-check only, PAY-04 comment-only)
- `.planning/REQUIREMENTS.md`: BOOK-01..05, BOOK-19, PAY-01..04, EXPL-01..07, and BACK-06/07/15/19 (pending real-card checks)
- `.planning/IOS-BUG-INVENTORY.md` § Client bookings (B1–B5, B19), § Payments (P1–P5), § Explore, expert profile, favorites, search (X1–X6), § Decisions for the user (Q4): file and line pointers and suggested fixes

### Payments contract
- `../ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md`: client Stripe flow and error codes
- `../ClickMe2026 Backend/openapi/clickme-api.yaml`: `/bookings/confirm`, `/client/favorites`, public profile, reviews
- `.planning/phases/01-backend-fixes/01-13-SUMMARY.md`: BACK-15 replay semantics (replay keyed on `payment_intent_id`; only active statuses replay)
- `.planning/phases/01-backend-fixes/01-17-PLAN.md`, `01-17-SUMMARY.md`: real-card checklist (BACK-06, 07, 15)
- `.planning/phases/01-backend-fixes/01-19-PLAN.md`, `01-19-SUMMARY.md`: BACK-19 smoke checklist
- `.planning/ROADMAP.md` § Backlog 999.1, 999.2: the deferred real-Stripe checks this phase closes
- `.planning/todos/pending/2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md`; `../ClickMe2026 Backend/src/controllers/webhooks.controller.js`, `src/services/connectedPaymentMethodClone.js`, `src/cron/longLeadChargeSweep.js`; `.planning/phases/01-backend-fixes/01-REVIEW.md` (WR-01), `01-SECURITY.md` (T-01-32)

### Stripe SDK
- stripe-ios 26.2.0 `PaymentSheetFlowController+AsyncPublicAPIs.swift` and CHANGELOG (PR #5202): `presentPaymentOptions` with `didCancel` (in DerivedData `SourcePackages/checkouts/stripe-ios-spm`)

### Discovery backend
- `../ClickMe2026 Backend/supabase/migrations/20261016000100_discovery_hide_moderated_users.sql`: `list_favorite_experts` moderation filtering (confirm)
- `../ClickMe2026 Backend/src/controllers/favorites.controller.js`, `publicProfile.controller.js` (404 at :73, `is_favorite` at :289-299)

### Prior phase decisions
- `.planning/phases/02-shared-ios-plumbing/02-CONTEXT.md`: D-04 tab-owned stacks, D-09..D-11 money formatter, D-13 6-day cap
- `.planning/phases/03-booked-sessions-and-joining/03-CONTEXT.md`: refund and hold wording, toasts

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MakeABookingViewModel.handlePaidFlowError` / `resetPaidFlow` / `newBookingAttempt`: the PAY-02 change splits transport failures out of the `default:` branch so that they keep the PI.
- `BookingErrorMapper`: per-`ErrorCode` copy. D-04 adds the My Bookings variant for `.slotUnavailable`.
- `HomeShellAction` env actions `showMyBookings` / `returnToHome` and the per-tab `HomeNavigationPath` (`explorePath`, `bookingsPath`, `searchPath`, `profilePath`): D-06 extends these to reset the source tab.
- `ToastCenter` / `ToastHost`: available, but no Phase 4 decision needs a new toast.
- The shared money formatter (Phase 2) for Request Sent and featured topics.

### Established Patterns
- `@MainActor ObservableObject` view models with `@Published apiError`; errors via `Error.userMessage`; branch on `ErrorCode`, never on message text.
- `LoadState` per section: EXPL-01 needs distinct not-found and network-error states.
- Swift Testing with `MockURLProtocol` for the paging, retry and 404 logic.

### Integration Points
- `MakeABookingStripePaymentSheet.swift:92-110`: FlowController create/present (D-01).
- `MakeABookingView.swift:128-133` → `BookingRequestSentView`: hide Back and disable swipe (D-05).
- `HomeClientView.swift:87-94`: shell actions (D-06).
- `FavoritesViewModel.swift:67`, `ClickMeAPI+Favorites.swift:19`, `FavoritesView.swift:117`, `ClientProfileHomeScreen.swift:207`: paging and empty state (D-07, D-08).
- `ExpertProfileViewModel.swift:68-75`: 404, network and `is_favorite` (D-09, D-10).
- `ExpertReviewsViewModel.swift:102`: reviews paging (D-07).
- `UserManager.swift:34` (`wasSuspended`, `tryAutoLogin`) and `SplashView` / `ClickMe2026App` routing (D-13).

</code_context>

<specifics>
## Specific Ideas

- Copy: "This profile isn't available"; "Couldn't load profile" plus Retry; "We couldn't confirm your booking" plus Try again; "You may already have this booking. Check My Bookings."; "Loading booking…"; the Pro Tip says "Tap the heart icon…".
- The PAY-02 forced-timeout device step doubles as the BACK-15 replay proof that backlog 999.2 asks for. A normal retry tap does not exercise replay, but a same-PI confirm retry does.

</specifics>

<deferred>
## Deferred Ideas

- Any Android fix that comes out of the D-14 push-prompt check becomes a new todo, not Phase 4 work.
- Android parity follow-ups for D-01, D-03/D-04, D-05/D-06, D-07/D-08, D-10 and D-13 go in the Android repo and are tracked separately.

</deferred>

---

*Phase: 04-booking-payment-and-discovery*
*Context gathered: 2026-11-11*
