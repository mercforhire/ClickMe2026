# Phase 4: Booking, Payment and Discovery - Research

**Researched:** 2026-11-11
**Domain:** SwiftUI client booking and payment flow (Stripe PaymentSheet FlowController, idempotent confirm replay), discovery screens (profile, favorites, reviews, search), one backend money-path fix (Stripe webhook plus off-session charge guard)
**Confidence:** HIGH for iOS and backend code facts (all read this session); MEDIUM for SwiftUI swipe-back and live 12/24-hour behavior (needs a device); LOW only where tagged `[ASSUMED]`

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward (not re-asked)**
- **Money (Phase 2 D-09 to D-11):** every amount on these screens (Request Sent payment card, featured topic prices, "Free") uses the shared minor-units formatter (`CA$45.00`).
- **Tab-owned stacks (Phase 2 D-04):** a destination opens on the stack of the tab that owns it, and Back returns to that tab's root. Navigation decisions below follow this.
- **Booking window (Phase 2 D-13, BOOK-14):** paid pickers keep the 6-day cap and the shared long-lead error mapper.
- **Toasts (Phase 3):** `ToastCenter` / `ToastHost` exist in both shells (WR-05). Use them only where a decision below asks for a toast.

**Q4 / PAY-01: closing the card sheet**
- **D-01: Q4 is settled as cancel (Android parity).** When the client closes the FlowController card sheet (swipe down or X), the booking is cancelled even if a saved card is preselected: there is no confirm and no hold. Only tapping the sheet's Continue/confirm proceeds. Use the `presentPaymentOptions` variant with a `didCancel` flag. It exists in the shipped stripe-ios 26.2.0 (CHANGELOG, PR #5202; `PaymentSheetFlowController+AsyncPublicAPIs.swift`). Do not rely on `paymentOption != nil`. Today's check is at `MakeABookingStripePaymentSheet.swift:101-106`. — **Reversibility:** reversible
- **D-02:** After a cancel, the reset is **silent**: no toast and no alert. The client stays on the booking form with the topic and slot still selected, and Book Now is enabled again. This is consistent with today's silent reset after a 3DS cancel (P4, by design).

**PAY-02: confirm timeout and retry**
- **D-03:** When `POST /bookings/confirm` fails with a **transport timeout or lost connection**, the hold may already exist. The app does not call `resetPaidFlow()` and keeps the payment intent id, the `pm_…` and the `booking_attempt_id`. It stays on "Confirming…" and **automatically retries the same confirm** (same PI, same card) a small bounded number of times (1–2). A replayed 201 (BACK-15 replays by an ownership-checked lookup on `payment_intent_id` for active bookings) lands on **Request Sent for that booking**, exactly like a first-time success. If the retries still fail, show "We couldn't confirm your booking" with a **Try again** button that reuses the same PI. Server-coded errors (402, 409, 422 and so on) keep today's `handlePaidFlowError` mapping, and only transport failures take this path.
- **D-04:** If a later attempt in this app session hits `SLOT_UNAVAILABLE` after a confirm for the **same expert and slot** timed out or was abandoned, the error reads **"You may already have this booking. Check My Bookings."** with a button that opens My Bookings. That attempt could be a new attempt after leaving the form, or after the retries ran out. Every other `SLOT_UNAVAILABLE` keeps today's copy and slot reset. The planner decides whether "this device" survives an app relaunch; a session-only record is acceptable.

**BOOK-01 / BOOK-19: Request Sent navigation**
- **D-05:** Request Sent **hides Back and disables the interactive swipe-back**. Its only exits are "View My Bookings" and "Back to Home", so the booking form can no longer be reached or resubmitted. Keep the current push from `MakeABookingView` (`navigationDestination(item: $viewModel.completedBookingId)`). No stack surgery.
- **D-06:** Both exits **reset the source tab's stack**: whichever tab started the flow (Explore, Search, or Profile via Favorites). Today `HomeClientView.swift:87-94` resets only explore (and bookings). "Back to Home" resets the source tab and switches to **Explore**. "View My Bookings" resets the source tab and Bookings, then switches to **Bookings**. No tab is ever left holding the booking flow.

**EXPL-05 / EXPL-06: Favorites and reviews paging**
- **D-07:** Favorites uses **infinite scroll**: pages of 20 via `page`/`limit` (`ClickMeAPI+Favorites.swift`; the server clamps `limit` to 1–100), fetching the next page near the bottom and stopping at the server's total. Pull-to-refresh restarts at page 1. The full Reviews list (EXPL-06, `ExpertReviewsViewModel.swift:102`) uses the **same paging pattern**.
- **D-08:** The empty-state buttons (`FavoritesEmptyState.swift`, wired from `FavoritesView.swift:117`) work. **"Explore Experts"** resets the Profile stack and switches to Explore. **"View My History"** resets the Profile stack and opens the Bookings tab on its **past/completed list**.
- **D-09:** The Pro Tip copy (`FavoritesProTipCard.swift:31`) says **"heart"**, not "star". The profile's favorite control is `heart` / `heart.fill` (`ExpertProfileView.swift:239`). A profile's favorite state comes from the profile response's `is_favorite` (`publicProfile.controller.js:289-299`), not a scan of the favorites list.

**EXPL-01: unavailable profiles**
- **D-10:** A **404** expert profile shows **"This profile isn't available"** with a **Back** button only. There is no retry, because a 404 won't change. A favorited expert is **not** removed automatically and no Remove button is offered: the entry stays in Favorites until the server stops returning it. A **network/transport error** gets a separate "Couldn't load profile" state with **Retry**. This replaces the `try?` at `ExpertProfileViewModel.swift:68-69`. The migration `20261016000100_discovery_hide_moderated_users.sql` appears to make `list_favorite_experts` hide moderated experts already. Research must confirm this. If so, a 404 from Favorites mostly means a deleted account or a race.

**Real-hold device testing**
- **D-11:** Phase 4 runs **one combined real-money device session** on the user's own client and expert accounts. It covers PAY-01 (closing the sheet places no hold), PAY-02 (forced timeout then retry lands on Request Sent, which also exercises the BACK-15 confirm replay for backlog 999.2), the folded card-removal fix (D-12), and the deferred Phase 1 real-Stripe checklists **01-17** (BACK-06, BACK-07, BACK-15) and **01-19** (BACK-19). That closes backlog items 999.1 and 999.2. **Every hold placed is released or refunded before the session ends.** BACK-06, 07, 15 and 19 move to Complete only when this session passes. Note from 999.1: the 01-19 checklist does not prove the failed-refund retry.

**Folded todos**
- **D-12:** This gets its **own backend plan and deploy**. Handle `payment_method.detached`, evict the clones (`connectedPaymentMethodClone.js`), and check the platform card before off-session charges. It needs backend tests, and the deploy must be safe for build 6 and current Android (check Android's SDK default for sheet removal). It is deployed **before** the D-11 device session, which then removes a card in the sheet and confirms it can't be charged. — **Reversibility:** costly — this is a production webhook and charge-path change on live Stripe, and undoing it needs a redeploy while real holds may be in flight.
- **D-13:** **Fix it from the code, without a device repro first.** On a cold launch, a suspension routes to Login (not home) and shows the suspension message from `wasSuspended`. Add a unit test. The device check happens in the release pass. Record whether Android needs a matching change.
- **D-14:** **Check only.** Reinstall the Android app while signed in and record whether the push prompt appears (`PushPermissionRequester.kt`). If there's a gap, file a new todo for the fix. No code change in this phase.

### Claude's Discretion
- How the PAY-02 transport-failure path is detected (`URLError` codes versus `NetworkError`), and the exact retry count (1–2) and spacing.
- Whether the D-04 "abandoned confirm" record survives a relaunch.
- BOOK-02 (cancel the previous month's availability task and check the month before assigning), BOOK-03 (`TimeZone.localizedName`), BOOK-04 (`timeStyle = .short`), BOOK-05 ("Loading booking…"), EXPL-04 (full tag pill text, as on Android) and PAY-04 (delete the stale `TODO(backend): stripe_account` comments) follow the inventory's suggested fixes. They were not discussed.
- PAY-03 lifecycle card copy: describe hold versus charge correctly from the booking's payment state, including older long-lead rows (inventory P3). This was not discussed, so use the existing Phase 3 refund and hold wording style.

### Deferred Ideas (OUT OF SCOPE)
- Any Android fix that comes out of the D-14 push-prompt check becomes a new todo, not Phase 4 work.
- Android parity follow-ups for D-01, D-03/D-04, D-05/D-06, D-07/D-08, D-10 and D-13 go in the Android repo and are tracked separately.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BOOK-01 | After a request is sent, the user cannot go Back and submit it again | `navigationBarBackButtonHidden` plus a UIKit fallback that disables both pop recognizers (Pattern 4); pinned exits in every Request Sent state |
| BOOK-02 | Changing month never shows the previous month's availability | `ReloadGeneration` token plus stored `Task` and cancellation handling (Pattern 6); `ReloadGeneration` already exists in `Utils/` |
| BOOK-03 | Readable time-zone name, not a raw IANA id | `TimeZone.current.localizedName(for: .generic, locale:)`, verified output `Eastern Time` (Pattern 7) |
| BOOK-04 | Slot and Today's Sessions times follow the device 12/24-hour setting | DateFormatter `timeStyle = .short`; `BookingTimeSlot.displayLabel` is shared with the Reschedule picker; tests need explicit locales (Pitfall 9) |
| BOOK-05 | Request Sent loading copy reads "Loading booking…" | One string at `BookingRequestSentView.swift` `loadingContent` |
| BOOK-19 | A booking from Favorites/Search doesn't leave Request Sent on that tab | Pure `HomeShellExit` planner keyed on the selected tab (Pattern 5) |
| PAY-01 | Closing the payment sheet never places a hold | Callback overload `presentPaymentOptions(from:completion: ((Bool) -> Void)?)` in `PaymentSheetFlowController.swift:486-490` (Pattern 1) |
| PAY-02 | A timed-out confirm that is retried reaches the pending booking, not "slot taken" | Outcome-unknown classifier, kept PI/pm/attempt id, bounded auto-retry, plus DUPLICATE_BOOKING routing (Pattern 2, Open Question 1) |
| PAY-03 | Payment lifecycle card describes hold vs charge | Pure variant chooser over `paymentStatus` and `authorizationExpiresAt` (Pattern 8) |
| PAY-04 | Stale `TODO(backend): stripe_account` comments removed | Three stale comments located (Pitfall 12); `detail.stripe_account` is shipped by the backend |
| EXPL-01 | 404 profile shows "This profile isn't available"; network errors offer retry | Details endpoint returns `404 NOT_FOUND` for missing/suspended/deleted experts (Pattern 9) |
| EXPL-02 | Empty Expertise/Topics/Reviews hidden | Code read confirms empty headers render today; details response has no profile-level tags (Open Question 5) |
| EXPL-03 | Featured topic cards show "Free" | Built in quick 261109-323 (`formatPrice`); device check only |
| EXPL-04 | Search tag pills show full text | Drop `lineLimit(1)`, use `TopicsSetupFlowLayout` (already in repo) |
| EXPL-05 | Favorites shows all favorites (paged), buttons work, copy right, `is_favorite` | Shared `PagedList`, shell actions, details `is_favorite` (Patterns 5, 9, 10) |
| EXPL-06 | Full reviews list loads beyond 20 | Same `PagedList`; server pagination has `has_more`, no total (Pitfall 3) |
| EXPL-07 | Explore loads with a free no-currency topic | Built in quick 261109-323; device check only; backend migration is on `origin/main` |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Extracted from `/Users/LeonChen/Documents/ClickMe2026/CLAUDE.md` and `.claude/CLAUDE.md`. Treat as locked.

- **Stack:** SwiftUI, Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`), iOS 18+, Xcode 26. No rewrites.
- **Cross-repo:** The backend owns the API contract (`openapi/clickme-api.yaml`, `docs/ios/`). Backend fixes are one commit per repo per change; never assume the other repo has it. Backend changes must be additive or safe for the current Android build and for **App Store build 6** (memory `protect-live-ios-release`).
- **Android:** iOS is the source of truth for behavior; every behavior change here is a likely Android follow-up and must be logged, not assumed done.
- **Errors:** Convert errors with `Error.userMessage`; never write a new private `errorMessage(for:)`. Branch on `ErrorCode`, never on message text. `try?` only for best-effort reads, never for writes or user-visible requests (the `try?` at `ExpertProfileViewModel.swift:68-69` is the thing EXPL-01 removes).
- **Logging:** Do not log tokens, passwords, client secrets or full payloads. Wrap debug logging in `#if DEBUG`.
- **Dates:** Date formatting is centralized in `DateUtil`; do not create new `DateFormatter` instances at call sites.
- **Structure:** View models are long (`MakeABookingViewModel` is 848 lines). Put new logic in helpers or sibling types. Screen-prefixed subviews. `@MainActor` view models; `@Published var apiError` for new view models; new shared managers use `@Observable`.
- **Style:** 4-space indent, `// MARK: -` sections, `Id` (not `ID`) in names, Xcode header block on every file, `///` doc comments that explain why. SwiftLint runs in CI only (not installed locally).
- **Tests:** Swift Testing (`@Suite`, `@Test`, `#expect`) with `MockURLProtocol`; `@testable import ClickMe2026`.
- **Definition of done:** unit tests where testable, clean `xcodebuild` with no new warnings, device check on a real iPhone via UAT checklist, backend tests for backend changes.
- **Production data:** every environment is the live backend with live Stripe keys. Payment and refund changes need care.
- **Release:** one iOS build at the end; no hotfix build.
- **GSD:** all file changes go through a GSD workflow.

## Summary

Phase 4 is mostly view-model and shell work in the iOS repo, plus one backend money-path plan (D-12). All 17 requirements and 14 decisions are implementable with the libraries already in the project: no new package is needed. The riskiest pieces are PAY-01/PAY-02 (live Stripe holds) and D-12 (live webhook and charge path); everything else is local logic that can be unit tested with the existing `MockURLProtocol` harness.

Reading the code and the backend turned up **eight facts that refine or contradict the CONTEXT and UI-SPEC wording**. The planner must absorb them:

1. **The `didCancel` overload is not in the Async file.** It is the callback overload `presentPaymentOptions(from:completion: ((_ didCancel: Bool) -> Void)?)` at `PaymentSheetFlowController.swift:486-490`. The async variant in `PaymentSheetFlowController+AsyncPublicAPIs.swift:91` has no flag. Use the callback form, which is what `MakeABookingStripePaymentSheet.swift:101` already calls.
2. **On production today, "retry after a timed-out confirm" does not return `SLOT_UNAVAILABLE`.** Since BACK-15, `POST /bookings/payment-intent` returns `409 DUPLICATE_BOOKING` with `detail.booking_id` for the caller's own identical active booking, and the backend doc says "route the user to that booking instead of the slot picker". `SLOT_UNAVAILABLE` now means someone else's booking or a different topic. D-04 as written (SLOT_UNAVAILABLE) is a backstop; the path that actually fires is DUPLICATE_BOOKING. See Open Question 1; this needs user confirmation because it extends D-03/D-04.
3. **The pagination envelope has no total.** `buildPagination` returns `current_page`, `total_pages`, `has_more` only. UI-SPEC wording about "the server's total" and "lowering the known total" cannot be implemented; stop on `has_more` (`PaginationMeta.hasMoreOrDerived`).
4. **`FavoriteExpert.id` and `ExpertReview.id` are a fresh `UUID()` on every construction.** Dedupe by `FavoriteExpert.expertId` and by the server review id (`ReviewItem.id`, which `ExpertReview` does not carry today and must gain).
5. **`UserManager` has a private init**, so `tryAutoLogin` cannot be unit tested directly. D-13 needs a small pure decision function that can be tested (Pattern 11).
6. **The app test plan runs in region GB** (`AllTests.xctestplan`), and `en_US` short time contains U+202F (narrow no-break space) before AM/PM. Time-format tests must pass explicit locales and compare with the exact scalar.
7. **`MyBookingsViewModel` is created inside `MyBookingsView`'s default argument**, so the shell cannot reach its `selectedTab`. D-08's "open Past" needs the shell to own the view model.
8. **Backend deploy range:** local `master` is 5 docs-only commits ahead of `origin/main`; `git diff origin/main..master -- src supabase` is empty. Deploying D-12 means pushing `master` to `origin/main`; the push range must contain only the D-12 commits (the Phase 1 wave pattern, D-10).

**Primary recommendation:** Build four small pure, unit-tested helpers first (outcome classifier, `PagedList`, `HomeShellExit`/`PaymentLifecycleVariant`, time and zone formatting plus `AutoLoginOutcome`), then wire the screens to them. Ship D-12 as its own backend plan and deploy, and keep every iOS payment change behind the idempotent same-PI retry contract (never create a second PaymentIntent for an attempt whose outcome is unknown).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Card sheet cancel vs continue (PAY-01) | Browser/Client (iOS, Stripe SDK) | API/Backend (confirm only on Continue) | Only the client knows whether the sheet was dismissed; no hold exists until `POST /bookings/confirm` |
| Confirm retry / replay (PAY-02) | Browser/Client (retry, kept ids) | API/Backend (idempotent replay by `payment_intent_id`) | Server guarantees one booking per PI; client must reuse the same PI/pm/attempt id |
| Duplicate-booking detection | API/Backend (`findOwnActiveBooking`) | Client (routing) | Backend decides identity; client only navigates |
| Request Sent one-way navigation (BOOK-01/19) | Client (shell, `NavigationStack`) | — | Pure navigation state |
| Payment card copy (PAY-03) | Client (pure chooser) | API/Backend (supplies `payment_status`, `authorization_expires_at`) | Backend already collapses raw state; client picks copy |
| Month availability races (BOOK-02) | Client | API/Backend (month endpoint) | Stale-response ordering is a client concern |
| Time and zone formatting (BOOK-03/04) | Client (Foundation) | — | Device locale and zone |
| Profile 404 vs network (EXPL-01), `is_favorite` | API/Backend (404 `NOT_FOUND`, `is_favorite`) | Client (state machine) | Backend owns existence and favorite flag |
| Favorites/reviews paging (EXPL-05/06) | Client (infinite scroll, dedupe) | API/Backend (`page`/`limit`, `has_more`) | Server paging; client accumulation |
| Card removal safety (D-12) | API/Backend (webhook, sweep guard) | Database (`connected_pm_clones`) | Stripe sheet removal bypasses the app; only the server can enforce |
| Suspension on cold launch (D-13) | Client (splash, login) | API/Backend (403 `ACCOUNT_SUSPENDED`) | Routing and alert are client; flag already set by the network trap |

## Standard Stack

No new packages. Everything below is already in the project.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| stripe-ios-spm (`StripePaymentSheet`) | 26.2.0 | FlowController card sheet | Pinned in `Package.resolved` (revision `7583122c3065d0582c3674abfec8b40a0b5a679c`); `didCancel` overload present [VERIFIED: DerivedData checkout `git describe` = 26.2.0] |
| SwiftUI / Foundation | iOS 18 SDK, Xcode 26.5 | UI, `URLSession`, `TimeZone`, `DateFormatter` | Project stack |
| Swift Testing | Xcode 26.5 | Unit tests | Existing convention (`@Suite`, `@Test`) |
| `MockURLProtocol` + `APITestFactory` | in repo | Stub HTTP, record requests | `ClickMe2026Tests/Support/` [VERIFIED: read this session] |
| Backend: Express, Jest, `stripe` Node SDK 22.2.0 | `package.json` | Webhook and sweep fix | Existing; `"stripe": "22.2.0"` [VERIFIED: package.json:48] |

### Supporting (existing in-repo helpers to reuse)
| Helper | Path | Use |
|--------|------|-----|
| `ReloadGeneration` | `ClickMe2026/Utils/ReloadGeneration.swift` | BOOK-02 stale-response guard |
| `ClientTransactionsViewModel.loadNextPageIfNeeded` | `Views/Screens/Client Mode/Payments/ClientTransactionsViewModel.swift:120` | The established paging pattern (last-3-rows trigger, `isLoadingMore`, `pageError`, 500-on-page>1 = end) |
| `BookingErrorMapper.code(for:)` / `.message(for:fallback:)` | `Utils/BookingErrorMapper.swift` | ErrorCode branching |
| `CancelRefundPreview` hold predicate | `Utils/CancelRefundPreview.swift:114` | Same `held` plus `authorizationExpiresAt != nil` live-hold rule PAY-03 needs |
| `TopicsSetupFlowLayout(horizontalSpacing:verticalSpacing:)` | `Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupFlowLayout.swift` | EXPL-04 wrapping pills (already used by `FavoriteExpertCard.swift:79`) |
| `PressScaleButtonStyle`, `Money.format(minorUnits:currency:)`, `ToastCenter` | existing | Buttons, money, (no toast needed) |
| `HomeNavigationPath` (`reset()`, `replace(with:)`, `pop(_:)`) | `Views/Extensions/HomeNavigationPath.swift` | Tab-owned stacks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Callback `presentPaymentOptions(... didCancel)` | Async `presentPaymentOptions` | Async version has no cancel flag (Stripe source), so it cannot distinguish close from Continue |
| Hand-written paging in each VM | One `PagedList` value type | Two lists (favorites, reviews) plus Phase 3 transactions share the same rules; a pure type is unit-testable without a view model |
| Moving `tryAutoLogin` behind a protocol | Pure `AutoLoginOutcome` function | `UserManager` is a `private init` singleton; a pure function is the cheapest testable seam |

**Installation:** none. **Version verification:** `Package.resolved` lists `stripe-ios-spm` 26.2.0; the checked-out SDK reports `26.2.0` [VERIFIED: `git describe --tags` in the DerivedData checkout]. No `npm view`/`pip` check applies because no package is added.

## Package Legitimacy Audit

Phase 4 installs no external package on either side (iOS SPM unchanged; backend `package.json` unchanged). Audit not applicable.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | n/a | No packages added |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                           Tab shell (HomeClientView)
   Explore / Search / Bookings / Chats / Profile  (one NavigationStack + HomeNavigationPath each)
        │  push ExpertProfileView ──► MakeABooking ──► BookingRequestSentView (back hidden)
        │                                   │                     │
        │                          PAID FLOW (MakeABookingViewModel)       exits ──► HomeShellExit.plan(action, selectedTab)
        │   POST /bookings/payment-intent ─► 409 DUPLICATE_BOOKING + detail.booking_id ──► route to that booking
        │            │ 200 (PI + SetupIntent)                                             (reset source tab, select tab)
        │            ▼
        │   FlowController sheet ── didCancel == true ──► silent reset (no confirm, no hold)
        │            │ didCancel == false (Continue)
        │            ▼  confirm(from:) → pm_…
        │   POST /bookings/confirm (same PI, same pm, same booking_attempt_id)
        │       ├─ 201 ───────────────────────────────────────► completedBookingId ► Request Sent
        │       ├─ server-coded 4xx/402/409/422 ─► handlePaidFlowError (today's mapping)
        │       └─ outcome unknown (URLError / undecodable / 5xx) ─► keep ids, auto-retry ≤2, then alert
        │              └─ replay: same PI ─► backend findReplayableBooking ─► 201 same booking_id
        ▼
   Discovery: ExpertProfileViewModel ── GET /experts/:id/details ── 404 NOT_FOUND ─► notFound state
                                                       └ other error ─► failed state (Retry)
              FavoritesViewModel / ExpertReviewsViewModel ── PagedList(page, limit 20, has_more) ── GET …?page=&limit=
   Backend (separate repo, D-12):
     Stripe sheet "remove card" ─► Stripe detaches platform pm ─► event payment_method.detached
        ─► POST /webhooks/stripe ─► dispatchPlatformEvent ─► evictClonesForPlatformPaymentMethod(pm.id)
     longLeadChargeSweep.chargeOne ─► (new) platform card still attached? ─ no ─► existing hard-decline path (cancelAndRelease)
```

### Recommended Project Structure
```
ClickMe2026/
├── Utils/
│   ├── PagedList.swift                    # pure: append(dedupe by key), hasMore, nextPage, reset (EXPL-05/06)
│   ├── ConfirmOutcome.swift               # pure classifier: outcomeUnknown vs serverCoded (PAY-02)
│   ├── HomeShellExit.swift                # pure planner: which paths to reset, which tab to show (D-06/D-08)
│   ├── PaymentLifecycleVariant.swift      # pure chooser A/B/C/none (PAY-03)
│   ├── AutoLoginOutcome.swift             # pure: after a refresh failure, login vs dashboard (D-13)
│   └── DateUtil.swift                     # + shortTime(...) and zoneName(...) (BOOK-03/04); no call-site DateFormatter
├── Managers/
│   └── UnconfirmedBookingLedger.swift     # session-only record of unknown/abandoned confirms (D-04); @MainActor
├── Views/Screens/Client Mode/
│   ├── Make a Booking/…                   # edits: MakeABookingViewModel(+Paid flow extension file), StripePaymentSheet, TimeSlotsCard
│   ├── Request Sent/…                     # edits + BookingRequestSentActions spacing param; PaymentLifecycleCard variants
│   ├── Expert Profile/…                   # ExpertProfileStateView (new, screen-prefixed), VM load states
│   ├── Favorites/…, Reviews/…, Search/…   # paging footers, tag pills
│   └── Home/HomeClientView.swift          # shell actions use HomeShellExit
ClickMe2026Tests/{Booking,Utils,Network/Discovery}/   # new suites listed in Validation Architecture
../ClickMe2026 Backend/ (own plan): src/controllers/webhooks.controller.js, src/services/connectedPaymentMethodClone.js, src/cron/longLeadChargeSweep.js + tests
```
New files auto-register via the project's synchronized groups (Phase 3 validation note).

### Pattern 1: Close vs Continue on the card sheet (PAY-01, D-01, D-02)
**What:** Use the callback overload that reports `didCancel`. On `true`, reset silently. On `false`, still guard `paymentOption != nil`, then confirm.
**Source (verbatim):** `PaymentSheetFlowController.swift:486-490` [VERIFIED]:
```swift
/// - Parameter completion: Called after the sheet is dismissed. The didCancel parameter is "true" if the user canceled the sheet (e.g. by tapping the close button or tapping outside the sheet), and "false" if they tapped the primary ("Continue") button.
public func presentPaymentOptions(
    from presentingViewController: UIViewController,
    completion: ((_ didCancel: Bool) -> Void)? = nil
) {
```
Dismissal paths: `flowControllerViewControllerShouldClose(... didCancel:)` at `PaymentSheetFlowController.swift:1022-1031` passes `didCancel` through; `LoadingViewControllerDelegate.shouldDismiss` passes `true` (line 1008). `CHANGELOG.md:379` (24.21.0, PR #5202) documents the API [VERIFIED].
**Example (replaces `MakeABookingStripePaymentSheet.swift:101-108`):**
```swift
flowController.presentPaymentOptions(from: presenter) { didCancel in
    // Closing the sheet (swipe down or X) is a cancel even with a saved card
    // preselected (D-01). Only Continue (didCancel == false) proceeds.
    guard !didCancel, flowController.paymentOption != nil else {
        viewModel.cancelPaidBooking()
        return
    }
    Task { await confirmViaFlow(flowController: flowController, presenter: presenter) }
}
```
A closure with an explicit `didCancel in` parameter selects the `Bool` overload; the zero-parameter closure currently in the file selects the old one. Extract the decision to a one-line pure function (`PaymentSheetOutcome.proceed(didCancel:hasOption:)`) so the rule is unit tested; the SDK call itself is device-only.

### Pattern 2: Outcome-unknown confirm, kept ids, bounded auto-retry (PAY-02, D-03)
**What:** Classify a confirm failure as *outcome unknown* (transport or ambiguous) or *server-coded*. Unknown keeps `paymentIntentId`, the `pm_…` and `bookingAttemptId`, stays in `.confirming`, retries up to 2 times, then raises the "We couldn't confirm your booking" alert. Retrying is always safe: the PI authorizes once, and a repeat confirm for an existing active booking replays `201` [VERIFIED: `docs/ios/STRIPE-INTEGRATION.md:128,190`].
**Classifier (mirror of Android `PaidFlowError.kt`, which treats `Network`, `Decoding`, and unmapped `status >= 500` on confirm as unknown) [VERIFIED: read this session]:**
```swift
// Proposed names. Rule: any URLError, an undecodable 2xx, or an unmapped 5xx on confirm.
enum ConfirmOutcome: Equatable {
    case outcomeUnknown
    case serverCoded
    static func classify(_ error: Error) -> ConfirmOutcome {
        if error is URLError || error is CancellationError { return .outcomeUnknown }
        if let net = error as? NetworkError {
            switch net {
            case .invalidResponse, .decodingFailed: return .outcomeUnknown   // 2xx whose body we could not read
            case let .httpError(status, _):
                if status >= 500, BookingErrorMapper.code(for: error) != .directChargeDisabled { return .outcomeUnknown }
                return .serverCoded
            default: return .serverCoded
            }
        }
        return .serverCoded
    }
}
```
`NetworkService` does not wrap transport errors: `sendRaw` lets `session.data(for:)` throw a raw `URLError` (`NetworkService.swift:208`), and `Error+UserMessage` falls through to `localizedDescription` for them [VERIFIED]. False positives are cheap (an idempotent replay); false negatives lose money visibility.
**Retry shape:** keep the pm in a private property set when `completePaidBooking(paymentMethodId:)` starts; `Try again` calls a `retryConfirm()` that reuses it. Spacing 2 s then 4 s (UI-SPEC minimum is 2 s). Inject the delay (`retryDelays: [Duration]`, `.zero` in tests). On success, `completedBookingId = response.data.bookingId` and `resetPaidFlow()` exactly as today. Post `AccessibilityNotification.Announcement("Confirming your booking…")` when the status line first appears (UI-SPEC section 2).
**Where it plugs in:** the `.confirm` phase of `handlePaidFlowError` (`MakeABookingViewModel.swift:560`) splits before `default:` at line 649; `retryConfirmAfterSCA` (line 666) also calls `completePaidBooking`, so SCA retries inherit the behavior.

### Pattern 3: DUPLICATE_BOOKING at payment-intent routes to the booking (PAY-02, Open Question 1)
**Backend contract (verbatim quotes):**
- `booking.controller.js:492` [VERIFIED]: `throw new AppError(409, 'DUPLICATE_BOOKING', 'You already have a booking for this time.', {` followed by `booking_id: ownBooking.id,`.
- `docs/ios/STRIPE-INTEGRATION.md:89` [VERIFIED]: "`detail.booking_id` holds the booking's id, so route the user to that booking instead of the slot picker. A conflict with anyone else's booking, or with the caller's own booking for a different topic, stays `409 SLOT_UNAVAILABLE` with no id."
- `STRIPE-INTEGRATION.md:408`: "`SLOT_UNAVAILABLE` ... means someone else's booking or a different topic of yours."
- iOS today: `ErrorCode.swift:49` `case duplicateBooking = "DUPLICATE_BOOKING"`; `BookingErrorMapper` maps it to "A booking for this session already exists." and `handlePaidFlowError` resets the flow. `errorDetail(for:)` (`MakeABookingViewModel.swift:836`) already parses `detail` from raw JSON.
**Recommendation:** in the `.createIntent` phase, on `.duplicateBooking` with a parseable `detail["booking_id"]` UUID, set `completedBookingId` to it (Request Sent) instead of showing an error. Keep D-04's SLOT_UNAVAILABLE variant as the stated backstop. Both ride the same `UnconfirmedBookingLedger` record. Needs user confirmation (Open Question 1).

### Pattern 4: One-way Request Sent (BOOK-01, D-05)
Apply `.navigationBarBackButtonHidden(true)` to `BookingRequestSentView`. Per Apple Developer Forums, hiding the back button on a standard push also disables the left-edge swipe [CITED: developer.apple.com/forums/thread/818848]; the `.zoom` transition is a documented exception, and the app uses no zoom transition. iOS 26 adds a second recognizer, `interactiveContentPopGestureRecognizer`, and the accepted answer disables both [CITED: developer.apple.com/forums/thread/791605]. Because UI-SPEC D2 mandates a device check, ship a small `UIViewControllerRepresentable` fallback (`PopGestureLock`) that finds the nearest `UINavigationController` and sets `isEnabled = false` on `interactivePopGestureRecognizer` and, under `if #available(iOS 26, *)`, `interactiveContentPopGestureRecognizer`, restoring on disappear. Land the plain modifier first; add the fallback only if the device check shows a swipe still pops, and keep the restore-on-disappear so other tabs are unaffected.
**Exits in every state:** `BookingRequestSentActions` gains a `spacing` parameter (default 14) so the pinned loading/error placements can use 16 (UI-SPEC); pass `opacity: 1, yOffset: 0` there (no entry animation). Loading copy: `Loading booking…` (replaces `Sending your booking…`).

### Pattern 5: Source-tab exits as a pure planner (BOOK-19, D-06, D-08)
`HomeClientView.swift:90-98` today:
```swift
.environment(\.showMyBookings, HomeShellAction {
    explorePath.reset()
    bookingsPath.reset()
    selectedTab = .bookings
})
.environment(\.returnToHome, HomeShellAction {
    explorePath.reset()
    selectedTab = .explore
})
```
Defect: a flow started on Search or Profile leaves `searchPath` / `profilePath` holding Request Sent. The source tab is `selectedTab` at call time (the exit buttons exist only on the visible tab). Extract the decision so it is testable (closures inside `body` are not):
```swift
// Proposed. HomeClientTab already exists in HomeClientView.
struct HomeShellExit: Equatable {
    var resetTabs: Set<HomeClientTab>
    var showTab: HomeClientTab
    var bookingsSegment: BookingsSegment?   // .past for "View My History"
    enum Action { case backToHome, viewMyBookings, checkMyBookings, exploreExperts, viewMyHistory }
    static func plan(_ action: Action, selectedTab: HomeClientTab) -> HomeShellExit { … }
}
```
Rules from UI-SPEC section 4: `backToHome` resets `{selected}` and shows `.explore`; `viewMyBookings`/`checkMyBookings` reset `{selected, .bookings}` and show `.bookings`; `exploreExperts` resets `{.profile}` and shows `.explore` (does not reset explore); `viewMyHistory` resets `{.profile, .bookings}`, shows `.bookings`, segment `.past`. When selected is already in the set, reset once. Add one new env action for the history case beside `showMyBookings`/`returnToHome` (`HomeNavigationPath.swift:195-211`).
**Past segment:** `MyBookingsViewModel.selectedTab` is a `@Published var selectedTab: Int` (`MyBookingsViewModel.swift:17`) created inside `MyBookingsView.init(viewModel: = MyBookingsViewModel())`. The shell must own it (`@StateObject private var myBookingsViewModel`) and pass it into `MyBookingsView(viewModel:)`, then set `selectedTab = 1` for the history case. Android did this with a singleton `BookingsLaunchRequest` consumed on read [VERIFIED: read this session]; a shell-owned view model avoids a new singleton.
**Favorites wiring:** `ClientProfileHomeScreen.swift` builds `FavoritesView()` with default no-op closures (that is the dead-button bug). Pass `onExplore`/`onViewHistory` that call the new env actions.

### Pattern 6: Month change race (BOOK-02)
`goToPreviousMonth()`/`goToNextMonth()` fire `Task { await loadAvailability(for: displayedMonth) }` (`MakeABookingViewModel.swift:340-348`) and `loadAvailability` makes three sequential requests with no cancellation or month check. Reuse `ReloadGeneration` (verified file, `Utils/ReloadGeneration.swift`):
- Add `private var availabilityGate = ReloadGeneration()` and `private var availabilityTask: Task<Void, Never>?`.
- `loadAvailability` takes `let token = availabilityGate.begin()` before the first `await`, and re-checks `availabilityGate.isCurrent(token)` after each await and before writing `availabilityByDate`, `expertTimezone`, `availabilityState`.
- Month navigation cancels the previous task, then starts the new one. A cancelled request surfaces as `URLError.cancelled`/`CancellationError`; do **not** map it to `.failed` (same rule as `ExploreClientViewModel.isCancellation`, `ExploreClientViewModel.swift:287`).
- The Retry button (`MakeABookingTimeSlotsCard.swift` `errorRow`) calls `loadAvailability` directly; route it through the same gate.
- The loaded merge also needs the displayed month check (`Calendar` month compare) because neighbor months are fetched best-effort.

### Pattern 7: Zone label and time format (BOOK-03, BOOK-04)
Verified on this machine (macOS 26, Foundation), `en_US` / `America/Toronto`:
```
TimeZone.localizedName(for: .generic, locale: en_US)  -> "Eastern Time"
DateFormatter(timeStyle .short, dateStyle .none) en_US -> "3:00 AM"  scalars: 33 3a 30 30 202f 41 4d   (U+202F before AM)
                                                en_GB  -> "03:00"
                                                fr_CA  -> "03:00"
Date.FormatStyle(date: .omitted, time: .shortened) en_GB -> "3:00"   (differs from DateFormatter)
```
Decisions: (1) Use `DateFormatter` with `timeStyle = .short`, `dateStyle = .none` per UI-SPEC; do **not** mix in `Date.FormatStyle` (leading-zero difference). (2) Implement inside `DateUtil` (CLAUDE.md: no call-site formatters) as `shortTime(_:timeZone:locale:)` taking `locale` with default `.autoupdatingCurrent`, so tests pass an explicit locale. (3) Do not cache by `locale.identifier` with `Locale.current`: a 12/24-hour toggle does not change the identifier, so a cached formatter could stay stale. Either key the cache so the formatter holds `Locale.autoupdatingCurrent`, or build per call (the current `BookingTimeSlot.displayLabel` already builds a formatter per call). Live-toggle behavior is `[ASSUMED]` and is device check T1. (4) `BookingTimeSlot.displayLabel` is also used by `RescheduleTimeSlotsCard.swift:74` and `MakeABookingView.swift:215`, so the change flows to the client Reschedule picker and the booking summary line; that is desirable but must be listed in the plan. (5) Zone label: `TimeZone.current.localizedName(for: .generic, locale: .current)`; omit the label when `nil`; remove the `Text(tz)` over `viewModel.expertTimezone` (`MakeABookingTimeSlotsCard.swift:19-23`). Today's Sessions: replace `timeRangeString` (`ExploreClientViewModel.swift:179-184`) with the same helper. K3 (Request Sent `h:mm a`, `BookingRequestSentViewModel.swift:129,143`) is a planner/user choice; recommend applying the same helper so a 24-hour user sees consistent times.

### Pattern 8: Payment lifecycle variants (PAY-03)
Backend facts [VERIFIED: `clientBooking.controller.js:40-100`, `reschedule.js:273-280`]: `derivePaymentStatus` returns `none` when there is no `payment_intent_id` (long-lead or free) or when `payment_status` is `canceled`/`auth_expired`/`failed`; `held` for `pending_approval|pending_reschedule|confirmed|in_progress`; `captured` for `completed`. `authorizationExpiresAt` is non-null only for a live authorization. iOS fields: `ClientBookingDetail.swift:45` `let paymentStatus: String`, `:72` `let authorizationExpiresAt: Date?`. Build a pure chooser from `isFree`, `paymentStatus`, `authorizationExpiresAt` (the same live-hold rule as `CancelRefundPreview.swift:114`): free -> none; `held` + expiry -> A; `none` -> B; `captured` or `held` without expiry -> C; anything else -> fail closed (card hidden). `PaymentLifecycleCard` keeps its `.upcoming` mode for `PaymentInfoSheet`; add a variant input without changing that call site. `BookingRequestSentViewModel.apply` must also store `paymentStatus` and `authorizationExpiresAt`. Caveat: variant B is reachable for a `declined`/`cancelled` row that replays after the expert acted (both read `none`); treat it as covered by K1.

### Pattern 9: Expert profile states and `is_favorite` (EXPL-01, EXPL-02, D-09, D-10)
Backend [VERIFIED]: `publicProfile.controller.js:56-73` returns `404 NOT_FOUND` ("Expert not found") for a missing, non-expert, non-`active` or `deleted_at` expert; `getExpertDetails` (line ~289) returns `is_favorite` at the top level of `data`, false on any lookup error; `data` also carries `topics_of_discussion[].expertise_tags` per topic but **no profile-level expertise tags**.
iOS changes: add `isFavorite: Bool?` to `PublicProfileDetailsData` (`PublicProfileDetailsData.swift`, currently has `profile`, `topicsOfDiscussion`, `recentReviews`, `isBookable`); introduce `ProfileLoadState` (`loading`, `loaded`, `notFound`, `failed(String)`) decided only by the details call; branch with `BookingErrorMapper.code(for:) == .notFound` or the HTTP status 404, never on message text; keep the 3-review preview call `try?` (best-effort, silent); delete the `getClientFavorites(page: 1, limit: 100)` scan (`ExpertProfileViewModel.swift:70-76`). A missing `is_favorite` reads `false`. Seeding the heart as filled when opened from Favorites requires a `isFavorited:` parameter on the convenience `ExpertProfileView.init(expert:...)` (the view model init already has it; `FavoritesView.swift:67` and the other call sites do not pass it).

### Pattern 10: Shared `PagedList` for favorites and reviews (EXPL-05, EXPL-06, D-07)
Server contract [VERIFIED: `pagination.js:45-53`]: the envelope is `{ current_page, total_pages, has_more }`; there is no `total_count`. iOS `PaginationMeta` (`PaginationMeta.swift:16-27`):
```swift
struct PaginationMeta: Decodable {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int?
    let hasMore: Bool?
    var hasMoreOrDerived: Bool { hasMore ?? (currentPage < totalPages) }
}
```
`totalCount` is `nil` for both endpoints. Build `PagedList<Item, Key: Hashable>`: `items`, `nextPage` (starts 1), `hasMore`, `isLoadingMore`, `pageError`; `mutating func applyFirstPage(_:hasMore:)`, `appendPage(_:hasMore:)` (skip keys already present), `remove(key:)`, `reset()`. The view model trigger copies `ClientTransactionsViewModel.loadNextPageIfNeeded` (last 3 rows, never while loading, 500 on a page greater than 1 means end of list). Keys: `FavoriteExpert.expertId` (the `id` is a new UUID each time) and a new `serverId` on `ExpertReview` taken from `ReviewItem.id`. Reviews default page size on the server is 10 (`parsePage(req.query, 10)`) but iOS passes `limit` explicitly, so send `limit: 20`. Favorites list calls `getClientFavorites(page:limit:)`; reviews call `getExpertReviews(id:page:limit:)` (`ClickMeAPI+Reviews.swift:32`). Pull-to-refresh restarts at page 1 and replaces the list only on success.

### Pattern 11: Suspension on cold launch (D-13)
Actual path [VERIFIED: read `NetworkService.send` lines 154-170, `UserManager.tryAutoLogin` lines 267-306]: `refreshMe()` gets 403 `ACCOUNT_SUSPENDED`; `send` awaits `suspensionHandler` (sets `wasSuspended = true`, `forceLogout()`) **before** rethrowing; `tryAutoLogin`'s catch sees `isAuthRejection == false` (it explicitly excludes `ACCOUNT_SUSPENDED`), falls into the "transient" branch, `hasStoredToken` is now false, and the function returns `true`. `SplashViewModel.start()` then sees `succeeded == true` and `me == nil` and routes `.dashboard(currentMode)`: a home shell with no session. Nothing reads `wasSuspended` (grep: only `UserManager.swift`).
Fix: extract `AutoLoginOutcome.resolve(storedToken:refreshError:wasSuspended:)` (pure) used by `tryAutoLogin`; a suspension returns "login". `LoginView` reads `UserManager.shared.wasSuspended` on appear, shows the alert (copy in UI-SPEC), then calls `clearSuspensionFlag()`. The same alert also fixes the mid-session case where `ClickMe2026App`'s `onChange(isLoggedIn)` routes to `.login`. Test the pure function and the alert-consumption helper; the singleton's `private init` (`UserManager.swift:120`) blocks testing the method itself.

### Pattern 12: Backend D-12 (own plan, own deploy)
Facts [VERIFIED: read this session]:
- `dispatchPlatformEvent` handles four event types (`payment_intent.succeeded`, `charge.refunded`, `application_fee.created`, `application_fee.refunded`); anything else returns `false` and is stamped terminal (`webhooks.controller.js:513-540`). A reconciler error leaves the `stripe_events` row unprocessed for the drain cron, which gives retry for free.
- `evictClonesForPlatformPaymentMethod(platformPmId)` selects rows by platform pm, detaches each clone (tolerating `resource_missing` and `payment_method_unexpected_state`), then deletes the cache row, row by row (`connectedPaymentMethodClone.js`). Its header says "NEVER call it from a booking, sweep or webhook path". The reason given (safe only when the platform card is detached and cannot be re-cloned) **holds in the webhook path**, because `payment_method.detached` fires after the platform pm is detached and Stripe documents detachment as permanent: "once detached, a PaymentMethod can no longer be used for payments or re-attached to a Customer" [CITED: docs.stripe.com/api/payment_methods/detach]. The header comment must be updated in the same commit.
- The event exists: "`payment_method.detached` ... Occurs whenever a payment method is detached from a customer." [CITED: docs.stripe.com/api/events/types].
- Charge path: `longLeadChargeSweep.chargeOne` resolves `platformCustomerId`, then calls `getOrCreateClonedPaymentMethod(booking.stripe_payment_method_id, ...)` (line ~309) which returns a cached clone with no platform-card check. Other callers: `booking.controller.js:958,1317,1557` and `paymentStateMachine.js:405`.
- Guard design: before the off-session charge, `retrievePaymentMethod(booking.stripe_payment_method_id)` (`stripe.js:1052`) and require `pm.customer === platformCustomerId`; otherwise take the existing hard-decline path (`cancelAndRelease`), as `01-REVIEW.md` WR-01 prescribes. A transient Stripe/retrieve error must **not** cancel (re-throw, the 6 h SCA window is the safety net, same rule as the sweep's existing comment).
- Tests: `tests/webhooks.test.js`, `tests/services/connectedPaymentMethodClone.test.js`, `tests/cron/longLeadChargeSweep.test.js`: baseline run 3 suites, 76 tests passed [VERIFIED: ran `REDIS_URL=redis://localhost:6379 npm test -- ...` this session].
- Ops step: the platform webhook endpoint in the Stripe Dashboard must be subscribed to `payment_method.detached` (the repo has no code-side event list; Phase 28 chose endpoints by live probe). This is a `checkpoint:human-action`, not code. `[ASSUMED]` that it is not subscribed today.
- Deploy: push `master` to `origin/main`; require `git log origin/main..master` to contain only D-12 commits (today it holds 5 docs commits; either push them with the deploy or exclude, per the Phase 1 D-10 isolated-range rule). Record `/health` SHA before and after (01-17 precedent).
- Compatibility: server-only; no response shape changes, so build 6 and current Android are unaffected. The only behavior change is that a booking whose card was removed in the sheet is cancelled at T-24h instead of charged. Android's PaymentSheet config does not set a removal option (`ClickMePaymentSheetStyle.kt` read in full), so Android uses the SDK default `[ASSUMED]`; iOS 26.2.0 default is removal allowed (`allowsRemovalOfLastSavedPaymentMethod = true`, SPI-only to change).

### Anti-Patterns to Avoid
- **Regenerating `bookingAttemptId` on an outcome-unknown confirm.** It creates a second PaymentIntent and a second hold. Keep the id until the user leaves the failure (UI-SPEC section 2).
- **Calling `resetPaidFlow()` in the transport-failure branch.** It nils `paymentIntentId`, so the retry would have nothing to replay.
- **Inferring cancel from `paymentOption != nil`.** A preselected saved card makes it non-nil after a close (the bug).
- **Branching on message text** for 404 or duplicate; use `ErrorCode`/status.
- **Treating a 500 on page > 1 as an error banner** (the transactions list already treats it as end of list).
- **Adding a toast.** No Phase 4 decision asks for one (UI-SPEC).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stale async response guard | New counter logic | `ReloadGeneration` | Already tested (`ReloadGenerationTests`) |
| Infinite-scroll trigger and 500-as-end rule | Third copy of the paging code | Copy `ClientTransactionsViewModel.loadNextPageIfNeeded` semantics into `PagedList` | Documented PostgREST out-of-range footgun |
| Wrapping chips | Custom `HStack` math | `TopicsSetupFlowLayout` | Already used by `FavoriteExpertCard` |
| Money text | `/100` or `String(format:)` | `Money.format(minorUnits:currency:)` | Phase 2 D-09 |
| Time format strings | `dateFormat = "h:mm a"` | `DateUtil.shortTime` with `timeStyle = .short` | Fixed formats ignore locale and the 24-hour setting |
| Zone names | Parsing IANA ids | `TimeZone.localizedName(for: .generic, locale:)` | Handles DST naming |
| Idempotency | Client-generated booking dedupe | Backend BACK-15 replay plus `booking_attempt_id` | Server already guarantees one booking per PI |
| Clone eviction | New delete logic | `evictClonesForPlatformPaymentMethod` | Existing, row-by-row, retry-safe |
| Webhook verification and durability | New route | Existing `handleStripeWebhook` + `stripe_events` | HMAC check and PK de-dup already there |
| Confirming the 3-button alert | Custom overlay | SwiftUI `.alert` with a model enum | Three actions render natively |

**Key insight:** every hard part of this phase (idempotency, paging footgun, stale guards, wrapping layout, eviction) already has a tested in-repo primitive. The phase is wiring plus four pure helpers.

## Runtime State Inventory

Not a rename/refactor/migration phase: omitted by instruction. One data note for D-12: `connected_pm_clones` rows for cards removed in the sheet before the fix deploys stay behind. Decide whether the backend plan also ships a one-off reconcile (list platform customer pms, evict clones whose platform pm is gone) or accepts that only future removals are handled; at minimum the sweep guard covers old rows because it checks the platform card, not the cache.

## Common Pitfalls

### Pitfall 1: Auto-retry that outlives the screen
**What goes wrong:** The user taps Back during "Confirming…"; the retry loop keeps running on the view model, a replayed `201` sets `completedBookingId` with no view to push, and the booking exists unseen.
**Why:** `MakeABooking` still allows Back during a confirm; the `Task` retains the view model.
**How to avoid:** Record the attempt in `UnconfirmedBookingLedger` (session-only, keyed `expertId` + `topicId` + slot start, outside the view model) when a confirm starts, and clear it on a definitive result. A later `DUPLICATE_BOOKING`/`SLOT_UNAVAILABLE` for that key shows the "Check My Bookings" variant.
**Warning signs:** a booking in My Bookings the user never saw confirmed.

### Pitfall 2: 120-second timeouts make the retry loop long
**What goes wrong:** `NetworkService` uses `timeoutIntervalForRequest = 120`. Three attempts against a black-holed network can spin for about 6 minutes.
**How to avoid:** Accept per UI-SPEC ("The 120 s request timeout is not changed") but device-test with airplane mode, which fails in milliseconds with `.notConnectedToInternet`/`.networkConnectionLost`, not with a 120 s wait. Put the worst case in the plan as a known limit.

### Pitfall 3: Planning against a total that does not exist
**What goes wrong:** UI-SPEC says "stop at the server's total" and "lower the known total by one". The favorites and reviews responses have only `has_more`.
**How to avoid:** Stop on `hasMoreOrDerived`. For reviews the header total is `summary.totalReviews`, not pagination.

### Pitfall 4: Offset paging skips an item after an unfavorite
**What goes wrong:** The user removes a favorite already on screen, then the next page request (`page=2`, offset 20) skips the item that shifted up on the server.
**How to avoid:** After a successful DELETE while `hasMore`, either re-request the last loaded page and merge with dedupe, or flag the list stale and reload from page 1 on the next paging trigger. Dedupe by `expertId` hides duplicates, not skips. (Android avoided paging by using `limit=100`, `FavoritesViewModel.kt` D-12.)

### Pitfall 5: `FavoriteExpert.id` and `ExpertReview.id` change on every map
**What goes wrong:** Dedupe by `id` never matches, and a pull-to-refresh re-keys every row (flicker, lost scroll position).
**How to avoid:** Key `PagedList` by `expertId`/server review id. Add `serverId: UUID` to `ExpertReview`; keep `id = UUID()` only for previews or make it derive from `serverId`.

### Pitfall 6: Sheet dismissal and Link
**What goes wrong:** Android found (BUG-07) that Stripe Link left at default can dismiss the sheet with no callback (stuck spinner) or drop the chosen card, and fixed it with Link `.never`. The iOS config leaves Link at `.automatic` (`LinkConfiguration.display` default), and the SDK calls `presentPaymentOptionsCompletionWithResult?(false)` after the Link flow (`PaymentSheetFlowController.swift:631`). It was not seen on iOS and is not in the iOS inventory.
**How to avoid:** Not in scope unless the user wants it; Open Question 3. If the device session shows a stuck spinner or a card that vanishes, set `config.link.display = .never` in `MakeABookingStripePaymentSheet.presentSheet`.

### Pitfall 7: Hiding Back does not guarantee no swipe
**What goes wrong:** On iOS 26 the second recognizer (`interactiveContentPopGestureRecognizer`) may still pop.
**How to avoid:** Pattern 4 fallback, decided by the D2 device check from each source tab.

### Pitfall 8: Pinned exits on loading/error must not run the entry animation
`BookingRequestSentActions` takes `opacity` and `yOffset` for the staggered entry; passing the view model's initial `0` / `16` on the pinned placements would make the only exits invisible. Pass `1` / `0`.

### Pitfall 9: Time-format tests and the test plan locale
**What goes wrong:** `AllTests.xctestplan` sets language `en`, region `GB`, so `Locale.current` in unit tests is en_GB (24-hour). `en_US` output contains U+202F, so `"2:00 PM"` typed with a normal space never matches.
**How to avoid:** Always pass `Locale(identifier:)` explicitly; compare against `"2:00\u{202F}PM"` or normalize NNBSP.

### Pitfall 10: `Date.FormatStyle` is not a drop-in for `DateFormatter.timeStyle`
en_GB gives `3:00` vs `03:00`. Pick `DateFormatter` (UI-SPEC) everywhere in Phase 4.

### Pitfall 11: Executing `book()` twice from alert buttons
**What goes wrong:** `Try again` and the original Book Now button could both start a confirm. `isSubmitting` is `isBooking || paidStep != .idle`; keep `paidStep == .confirming` while the alert is up so Book Now stays disabled, and guard `retryConfirm()` on a stored pm and `paidStep == .confirming`.

### Pitfall 12: Stale comments to delete (PAY-04)
Three places, not one: `MakeABookingViewModel.swift:178-180` (`TODO(backend): the stripeAccount needed to complete 3DS ... Wire the full retry once that ships.`), the `SCAChallenge.stripeAccount` doc ("Nil until backend adds it to `detail.stripe_account`"), and `MakeABookingStripePaymentSheet.swift:174-178` ("Backend hasn't shipped detail.stripe_account yet"). The backend ships it: `classifyConfirmedPI` doc, `booking.controller.js` ("`stripe_account` is a deliberate, scope-limited WR-02 exception: iOS needs the connected account id"). Comment-only; the `guard let stripeAccount` fail-closed code stays. `grep -c "TODO(backend)"` should drop from 1 to 0.

### Pitfall 13: Profile flashes before a 404
The seeded profile shows while `loading` (UI-SPEC K5, accepted). Do not add a spinner screen unless the device check says it confuses.

### Pitfall 14: `PAYMENT_IN_PROGRESS` is not in `ErrorCode`
`classifyConfirmedPI` can return `409 PAYMENT_IN_PROGRESS`; iOS has no case, so it falls to `default:`, shows the server message with the payment reference and resets the PI. Retrying the same PI would be safe. Out of scope; note for the plan reviewer only.

## Code Examples

### Pending-alert model for the three Make a Booking alerts
```swift
// Proposed. Keeps `bookingError: String?` for existing sheet-modifier writes.
enum PaidFlowAlert: Identifiable, Equatable {
    case confirmUnknown(paymentReference: String?)   // "We couldn't confirm your booking"
    case mayAlreadyBeBooked                          // "You may already have this booking. Check My Bookings."
    var id: String { switch self { case .confirmUnknown: "unknown"; case .mayAlreadyBeBooked: "maybe" } }
}
// View: .alert(title, isPresented:, presenting:) with buttons
//   confirmUnknown: Button("Try again"), Button("Check My Bookings"), Button("Not now", role: .cancel)
//   mayAlreadyBeBooked: Button("Check My Bookings"), Button("Close Alert", role: .cancel)
```
Copy is exact in UI-SPEC "Make a Booking: payment sheet and confirm". The payment reference line reuses the existing `"\(message)\n\nPayment reference: \(intentId)"` convention (`MakeABookingViewModel.swift:653`).

### Test seam for the paid flow
`MakeABookingViewModel.paymentIntentId`, `selectedTopic`, `selectedTimeSlot` are settable `@Published` (preview init at lines 224-247 installs topics and a default selection); `bookingAttemptId` is `private(set)` and readable. A test sets those, stubs `/bookings/confirm` with `APITestFactory.make { request in ... throw URLError(.timedOut) }`, calls `completePaidBooking(paymentMethodId:)`, and asserts `paymentIntentId` is still set, `recordedRequests` shows 3 POSTs, and `completedBookingId` is set on a later `201`.
```swift
// MockURLProtocol.handler may throw to simulate a transport failure (MockURLProtocol.swift: "or throw to simulate a transport-layer error").
let api = APITestFactory.make { request in
    if MockURLProtocol.recordedRequests.count < 3 { throw URLError(.networkConnectionLost) }
    return (okResponse(request), confirmJSON)
}
```
(`recordedRequests` is appended before the handler runs, so a handler can branch on the count, per Phase 3 note.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Infer cancel from `paymentOption != nil` | `presentPaymentOptions` completion `didCancel` | stripe-ios 24.21.0 (PR #5202) | Required for PAY-01 |
| Retry after timeout shows "slot taken" | `201` replay on confirm; `409 DUPLICATE_BOOKING` + `detail.booking_id` on payment-intent | BACK-15 (Phase 1, deployed) | PAY-02 can land on the booking |
| Single pop gesture | Edge `interactivePopGestureRecognizer` plus iOS 26 content-area recognizer | iOS 26 | Disable both if needed (Pattern 4) |
| Fixed `h:mm a` | `timeStyle = .short` | n/a | Follows locale and 24-hour setting |

**Deprecated/outdated:** `LONG_LEAD_REQUIRES_SAVED_CARD` is kept server-side only for old clients; paid starts past 6 days return `LONG_LEAD_NOT_AVAILABLE` (already handled, Phase 2).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A Railway or proxy 502/504 on confirm can occur after the hold exists (Android treats unmapped 5xx as unknown) | Pattern 2 | If never occurs, the 5xx arm is merely harmless extra retries |
| A2 | `navigationBarBackButtonHidden(true)` alone disables edge swipe on iOS 18 and 26 for a standard push | Pattern 4 | Swipe still pops; mitigated by the fallback and device check D2 |
| A3 | An uncached `DateFormatter` or one holding `Locale.autoupdatingCurrent` reflects a live 12/24-hour toggle | Pattern 7 | Times stay stale until relaunch; device check T1 |
| A4 | The Stripe sheet's "remove card" triggers `payment_method.detached` on the platform account, and the platform webhook endpoint is not yet subscribed to it | Pattern 12 | Handler never fires; the real-card step (D-11) must confirm; the sweep guard is the independent safety net |
| A5 | Android's PaymentSheet SDK default allows card removal (config sets no removal option) | Pattern 12 | If Android disables removal, the exposure is iOS-only, which does not change the fix |
| A6 | Stripe Link left on `.automatic` can mis-fire the iOS FlowController completion | Pitfall 6 | Only matters if Link is enabled on the live account; not seen on iOS |
| A7 | `GET /experts/:id/reviews` past the last page may 500 (PostgREST out-of-range) as the transactions endpoint does | Pattern 10 | Mitigated by gating on `has_more`, and by treating 500 on page > 1 as end |
| A8 | Backend migration `20261109000000_home_feed_null_hourly_rate.sql` is applied on production Supabase (it is on `origin/main`; application is unknown) | EXPL-07 | Build 6 still fails to decode a free no-currency topic; new iOS decodes either way |
| A9 | Expert profile opened from chat (`.peerProfile`) always has empty Expertise tags because the details endpoint returns tags per topic only | Open Question 5 | Expertise section never shows on that entry; correct per EXPL-02, but a product gap |

## Open Questions

1. **Should `409 DUPLICATE_BOOKING` + `detail.booking_id` at payment-intent open Request Sent for that booking?**
   - Known: production returns it for the caller's own identical active booking (`STRIPE-INTEGRATION.md:89,420`); D-04 only names `SLOT_UNAVAILABLE`, which the backend doc says now means someone else's booking or a different topic.
   - Unclear: whether the user wants navigation (matches roadmap success criterion 1) or only the "Check My Bookings" alert, and whether a booking made hours ago should open "Request Sent" (its pill reads "Awaiting Approval", UI-SPEC K1).
   - Recommendation: route to Request Sent when the ledger shows an unknown or abandoned confirm for that key, otherwise show the D-04 alert variant with the Check My Bookings button; implement D-04 exactly as written either way. Confirm with the user before planning.
2. **UI-SPEC planner assumptions K1, K3, K4, K5** remain explicit assumptions: leave the "Awaiting Approval" pill (K1); apply the short time style to Request Sent too (K3, recommended); clear the slot after the D-04 alert (K4); accept the seeded-profile flash (K5).
3. **Stripe Link on iOS (Android BUG-07).** Not in any requirement. Add `config.link.display = .never` in the same edit as PAY-01 only if the user approves; otherwise device-watch.
4. **Offset shift after unfavorite (Pitfall 4).** Pick re-request-last-page or reload-on-next-trigger; recommend reload-on-next-trigger (simplest, no skipped rows).
5. **Expertise for chat-opened profiles.** Details has no profile-level tags. Hiding the empty section satisfies EXPL-02; deriving tags from the union of `topics_of_discussion[].expertise_tags` would show something, but is new behavior. Recommend: hide only, log as a follow-up.
6. **Stripe Dashboard event subscription** for `payment_method.detached` on the platform endpoint: ops checkpoint inside the D-12 plan. Who has Dashboard access and who runs `stripe trigger payment_method.detached`?
7. **Favorites staleness.** `FavoritesViewModel.load()` skips when already `.loaded`, so unfavoriting from a profile and going Back leaves the row. Android refreshes on return. Not in scope; log if the device check hits it.
8. **EXPL-07 backend migration status (A8).** Confirm before the device check if a build-6 comparison is wanted.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | all iOS tasks | yes | 26.5 (17F42) | — |
| iOS Simulator "iPhone 17" | unit tests (Phase 3 command style) | yes | 3 devices share the name (`OS=latest` resolves) | iPhone 17 Pro |
| Node / npm | backend tests | yes | node v26.8.1, npm 11.19.0 | — |
| Backend `node_modules` | backend tests | yes | baseline 3 suites / 76 tests passed | `npm ci` |
| Redis (`REDIS_URL=redis://localhost:6379`) | backend jest | yes | `PONG` | — |
| Stripe CLI | `stripe trigger payment_method.detached` (D-12 verification) | yes | `/opt/homebrew/bin/stripe` | Dashboard "send test webhook" |
| SwiftLint | lint | no | CI only (`cirruslabs/swiftlint-action`) | rely on CI |
| Real iPhone, the user's live Stripe cards, client and expert accounts | D-11, D1-D4 device checks | not probed | — | none: human-only |
| Android device (reinstall check D-14) | D-14 | not probed | — | none: human-only |

**Missing dependencies with no fallback:** real device and live accounts (human steps, by design).
**Missing dependencies with fallback:** SwiftLint (CI).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests`; backend Jest |
| Config file | `ClickMe2026/AllTests.xctestplan` (language en, region GB); new files auto-register through synchronized groups |
| Quick run command | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| Full suite command | same with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests -collect-test-diagnostics never` (smoke suites hit production and must never run). Phase 3 last run: 434 tests in 49 suites |
| Backend command | `REDIS_URL=redis://localhost:6379 npm test -- tests/webhooks.test.js tests/services/connectedPaymentMethodClone.test.js tests/cron/longLeadChargeSweep.test.js` from `../ClickMe2026 Backend` (baseline: 3 suites, 76 tests passed) |
| Build gate | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` with no new warnings in touched files |

A run counts only if it reports a non-zero test count. Suites using `MockURLProtocol` are `.serialized` and run one suite per `xcodebuild`. Concurrent `xcodebuild` runs in one wave may hit a simulator-busy error; rerun once.

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command (`-only-testing:ClickMe2026Tests/…`) | File Exists? |
|--------|----------|-----------|----------------------------------------------------------|-------------|
| PAY-01 | `proceed(didCancel:hasOption:)` is false when closed even with a saved card | unit | `PaymentSheetOutcomeTests` | Wave 0 |
| PAY-01 | Real close places no hold | device | D-11 session | manual |
| PAY-02 | Classifier: any `URLError`, undecodable 2xx, unmapped 5xx = unknown; 402/409/422 coded = serverCoded | unit | `ConfirmOutcomeTests` | Wave 0 |
| PAY-02 | Unknown failure keeps PI/pm/attempt id, retries ≤2 with injected zero delay, replayed 201 sets `completedBookingId`, exhausted raises alert, Try again reuses same PI (recorded request bodies carry the same `payment_intent_id`) | unit (stubbed API) | `MakeABookingPaidFlowTests` | Wave 0 |
| PAY-02 / D-04 | Ledger: SLOT_UNAVAILABLE after unknown outcome for same key = "maybe" alert and slot cleared; other = old copy; DUPLICATE_BOOKING with `booking_id` routes | unit | `MakeABookingPaidFlowTests`, `UnconfirmedBookingLedgerTests` | Wave 0 |
| PAY-02 | Forced timeout then retry lands on Request Sent (BACK-15 replay, backlog 999.2) | device | D-11 session | manual |
| PAY-03 | Variant chooser: free none; held+expiry A; none B; captured or held-without-expiry C; unknown fail closed | unit | `PaymentLifecycleVariantTests` | Wave 0 |
| PAY-03 | Variant A on a live hold | device | D3 | manual |
| PAY-04 | No stale comments | grep gate | `test "$(grep -rc 'TODO(backend)' ClickMe2026/Views/Screens/Client\ Mode/Make\ a\ Booking \| awk -F: '{s+=$2} END{print s}')" -eq 0` and `grep -c "Backend hasn't shipped" …StripePaymentSheet.swift` = 0 | n/a |
| BOOK-01/19 | `HomeShellExit.plan` for every action x selected tab (Explore, Search, Bookings, Chats, Profile); reset-once; Past segment for history | unit | `HomeShellExitTests` (regression: `HomeNavigationPathTests`) | Wave 0 |
| BOOK-01 | Edge swipe does not pop from each source tab; Back hidden | device | D2 | manual |
| BOOK-02 | Slow older month response lands after newer: screen shows newer; cancel is not `.failed`; month check before write | unit | `MakeABookingAvailabilityTests` (regression: `ReloadGenerationTests`) | Wave 0 |
| BOOK-03 | Zone label `Eastern Time` for America/Toronto en_US; nil omits | unit | `SlotTimeFormatTests` | Wave 0 |
| BOOK-04 | en_US `2:00\u{202F}PM`, en_GB `14:00`; Today's Sessions range joined by ` - `; reschedule chips share the helper | unit | `SlotTimeFormatTests` | Wave 0 |
| BOOK-04 | Toggle 12/24-hour while running | device | T1 | manual |
| BOOK-05 | `Loading booking…` | grep gate | `grep -c 'Loading booking…' "ClickMe2026/Views/Screens/Client Mode/Request Sent/BookingRequestSentView.swift"` = 1 and `Sending your booking` = 0 | n/a |
| EXPL-01 | 404 `NOT_FOUND` -> `.notFound`; `URLError` -> `.failed`; Retry succeeds | unit (stubbed API) | `ExpertProfileViewModelTests` | Wave 0 |
| EXPL-02 | Section visibility predicate (tags, topics, reviews empty = hidden); hero zero and one review strings | unit | `ExpertProfileSectionsTests` | Wave 0 |
| EXPL-02 | Confirm empty headers on a device first (LIKELY item) | device | D-list | manual |
| EXPL-03 / EXPL-07 | Free label, bad topic dropped alone, failed-load text | unit (existing) + device | `ClientHomeFeedTests` (18 tests) | yes |
| EXPL-04 | Pills not truncated | grep gate + preview | `grep -c 'lineLimit(1)' …SearchExpertCard.swift` = 0 and `grep -c TopicsSetupFlowLayout` >= 1 | n/a |
| EXPL-05 | `is_favorite` drives the heart; no `/client/favorites` request from the profile (`recordedRequests`) | unit | `ExpertProfileViewModelTests` | Wave 0 |
| EXPL-05/06 | `PagedList`: first page, append, dedupe by key, stops on `has_more` false, reset, remove | unit | `PagedListTests` | Wave 0 |
| EXPL-05 | Favorites VM paging, pull-to-refresh, later-page failure keeps rows and sets `pageError`, 500 on page>1 = end | unit (stubbed API) | `FavoritesViewModelPagingTests` | Wave 0 |
| EXPL-06 | Reviews VM paging beyond 20 | unit (stubbed API) | `ExpertReviewsViewModelPagingTests` | Wave 0 |
| EXPL-05 | Pro Tip says heart; buttons work | grep gate + device | `grep -c 'heart icon' …FavoritesProTipCard.swift` = 1 | n/a |
| D-13 | Suspended cold launch resolves to login; alert consumed once | unit | `AutoLoginOutcomeTests`, `SuspensionNoticeTests` | Wave 0 |
| D-12 | `payment_method.detached` evicts clones for `data.object.id`; no-op when none; Stripe error leaves row unprocessed; sweep cancels when platform card detached; transient retrieve error does not cancel | backend jest | webhooks, clone service, longLeadChargeSweep suites | extend existing files |

### Sampling Rate
- **Per task commit:** the single suite for the touched helper (about 180 s including simulator boot; suites run in milliseconds).
- **Per wave merge:** each suite touched in the wave (one `xcodebuild` per suite) plus the build gate; backend command for D-12.
- **Phase gate:** full suite green (Phase 2/3 regressions: `JoinWindowTests`, `MoneyTests`, `ClientBookingStatusFallbackTests`, `ReloadGenerationTests`, `BookingErrorMapperTests`, `HomeNavigationPathTests`, `ClientHomeFeedTests`), no new warnings, backend suites green, then the device checklist.

### Wave 0 Gaps
- [ ] New pure types and their suites: `PaymentSheetOutcome`, `ConfirmOutcome`, `PagedList`, `HomeShellExit`, `PaymentLifecycleVariant`, `AutoLoginOutcome`, `UnconfirmedBookingLedger`, `DateUtil.shortTime`/`zoneName`
- [ ] Suites listed above (all new): `PaymentSheetOutcomeTests`, `ConfirmOutcomeTests`, `MakeABookingPaidFlowTests`, `UnconfirmedBookingLedgerTests`, `PaymentLifecycleVariantTests`, `HomeShellExitTests`, `MakeABookingAvailabilityTests`, `SlotTimeFormatTests`, `ExpertProfileViewModelTests`, `ExpertProfileSectionsTests`, `PagedListTests`, `FavoritesViewModelPagingTests`, `ExpertReviewsViewModelPagingTests`, `AutoLoginOutcomeTests`, `SuspensionNoticeTests`
- [ ] Fixtures for the paging and 404 bodies under `ClickMe2026Tests/Fixtures/` (or inline JSON as `ClientHomeFeedTests` does)
- [ ] `ExpertReview.serverId` and `ExpertProfileView.init(isFavorited:)` seams (needed before tests)
- [ ] No framework install needed

### Real-money device session (D-11) checklist skeleton
Order: D-12 deploy and `/health` SHA first; then PAY-01 (close with saved card preselected, verify no `requires_capture` PI in the Stripe Dashboard); complete a paid booking (variant A, Back hidden, swipe from each source tab); forced confirm timeout (airplane mode during "Confirming…", restore) lands on the same booking (999.2); retries-exhausted then Try again yields one booking and one hold; remove a card in the sheet and prove it cannot be charged (D-12); then 01-17 steps 1-9 (BACK-06/07/15) and 01-19 (BACK-19). Release or refund every hold before ending. Booking must start 2 to 5 days out and not be joined or rescheduled (01-17 key decision).

## Security Domain

`security_enforcement` is enabled (absent = enabled); ASVS level 1, block on high.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes (D-13 only) | Existing token clear on 403 `ACCOUNT_SUSPENDED`; no new auth surface |
| V3 Session Management | yes (D-13) | `forceLogout` already clears Keychain and socket; routing must not show a home shell without a session |
| V4 Access Control | yes | Backend replay and `detail.booking_id` are scoped to the caller (`client_id`); client only navigates, and `GET /client/bookings/:id` re-checks ownership |
| V5 Input Validation | yes | Webhook: `constructEvent` HMAC; new handler must read only `event.data.object.id` and ignore non-`pm_` ids; client: parse `detail.booking_id` as `UUID` |
| V6 Cryptography | no | None added; never hand-roll |
| V7 Error Handling and Logging | yes | Never log PaymentIntent client secrets, ephemeral keys or `pm_` ids in release; `Payment reference` shows only the `pi_` id (support convention) |
| V8 Data Protection | yes | No PAN handled; the PaymentSheet owns card entry |

### Known Threat Patterns for this stack
| Pattern | STRIDE category | Standard Mitigation |
|---------|-----------------|---------------------|
| Double charge or second hold from a retry | Tampering (financial) | Same PI, same `booking_attempt_id`, backend replay; never mint a new attempt on outcome-unknown |
| Card removed in the sheet then charged off-session (T-01-32) | Tampering (financial) | `payment_method.detached` eviction plus platform-card check before `confirmPIOffSession` |
| Forged webhook | Spoofing | Existing `constructEvent` signature and 300 s tolerance; new case adds no unauthenticated path |
| Webhook replay | Repudiation | `stripe_events` PK insert; handler must be idempotent (eviction of zero rows is a no-op) |
| IDOR via `detail.booking_id` | Information disclosure | Value is only ever the caller's own booking (T-01-28) |
| Account stays usable after suspension | Elevation of privilege | Route to Login on suspension; token already cleared |
| Sensitive data in logs | Information disclosure | `#if DEBUG`; no secrets in alerts |

## Sources

### Primary (HIGH confidence)
- iOS source read this session: `MakeABookingStripePaymentSheet.swift`, `MakeABookingViewModel.swift`, `MakeABookingView.swift`, `MakeABookingTimeSlotsCard.swift`, `BookingTimeSlot.swift`, `BookingRequestSent*`, `PaymentLifecycleCard.swift`, `HomeClientView.swift`, `HomeNavigationPath.swift`, `MyBookingsView.swift`, `Favorites*`, `ExpertProfile*`, `ExpertReviews*`, `SearchExpertCard.swift`, `ExploreClientViewModel.swift`, `NetworkService.swift`, `UserManager.swift`, `SplashViewModel.swift`, `ClickMe2026App.swift`, `ErrorCode.swift`, `PaginationMeta.swift`, `ClientBookingDetail.swift`, `ReloadGeneration.swift`, `ClientTransactionsViewModel.swift`, `AllTests.xctestplan`, test support files
- stripe-ios 26.2.0 checkout (DerivedData): `PaymentSheetFlowController.swift:465-520,995-1031`, `PaymentSheetFlowController+AsyncPublicAPIs.swift:70-125`, `CHANGELOG.md:379`, `PaymentSheetConfiguration.swift` (removal and Link config)
- Backend source: `booking.controller.js` (replay, payment-intent, confirm), `publicProfile.controller.js`, `favorites.controller.js`, `reviews.controller.js`, `utils/pagination.js`, `clientBooking.controller.js`, `utils/reschedule.js`, `webhooks.controller.js`, `connectedPaymentMethodClone.js`, `longLeadChargeSweep.js`, `paymentMethods.controller.js`, `services/redis.js`, `docs/ios/STRIPE-INTEGRATION.md` (lines 89, 128, 190, 192, 408, 419-420), migration `20261016000100` (line 601-602 `moderation_status = 'active'` and `deleted_at IS NULL`; D-10 confirmed)
- Android source: `PaidFlowError.kt`, `FavoritesViewModel.kt`, `StackOrigin.kt`, `BookingsLaunchRequest`, `ClickMePaymentSheetStyle.kt`
- Planning: 04-CONTEXT, 04-UI-SPEC, REQUIREMENTS, 01-13-SUMMARY, 01-17-SUMMARY, 01-REVIEW (WR-01), 01-SECURITY (T-01-32), 03-VALIDATION
- Ran this session: Swift script for time/zone formats; backend jest baseline (76 tests passed)

### Secondary (MEDIUM confidence)
- docs.stripe.com/api/payment_methods/detach (detachment permanent); docs.stripe.com/api/events/types (`payment_method.detached`)
- Apple Developer Forums 818848 (hidden back button disables edge swipe on standard push), 791605 (iOS 26 two recognizers)

### Tertiary (LOW confidence)
- Web search on cached `DateFormatter` and 12/24-hour live changes: no authoritative source found (A3)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new packages; versions read from `Package.resolved` and the checkout
- Architecture: HIGH for iOS and backend code paths (read and cross-checked); MEDIUM for swipe-back and live 12/24 behavior (device checks D2, T1)
- Pitfalls: HIGH - each one traced to a file and line, or run on this machine

**Research date:** 2026-11-11
**Valid until:** 2026-12-11 (stable code; re-check `origin/main..master` and the Stripe SDK pin before planning if either moves)
