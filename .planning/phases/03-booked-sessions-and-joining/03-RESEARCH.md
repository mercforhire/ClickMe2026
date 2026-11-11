# Phase 3: Booked Sessions and Joining - Research

**Researched:** 2026-11-10
**Domain:** SwiftUI bug-fix phase on a live app (booking response, cancel, reschedule, join flows on client and expert screens), plus one Android parity edit (BOOK-20)
**Confidence:** HIGH for code and backend facts (read this session); MEDIUM for on-device SwiftUI behavior (flagged `[ASSUMED]` where unverified)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward (not re-asked)**
- **Q2 / refunds (Phase 1 D-17, BACK-19):** an expert-initiated cancel always gives the client a full refund or releases the hold. A client-initiated cancel keeps the 24-hour rule. BACK-19 is deployed (`3899d63`) but its production smoke has not been run; the EXP-11 copy below depends on it being true.
- **Join window (Phase 2 D-07, D-12):** every Join/Open button in this phase uses the shared Phase 2 join-window helper ([start − 60, max(end, start + 60)] plus the server reconnect flag) and the server's joinable statuses. `pending_reschedule` shows Join visible but disabled.
- **Money and status (Phase 2 D-09 to D-11, BOOK-18):** all amounts use the shared minor-units formatter (`CA$45.00`); all statuses use the shared decoder with its neutral unknown fallback.
- **Overtime (Phase 2 D-08):** the end + 60 cutoff and the end + 55 notice stay as they are, on both in-app voice and Skype/Zoom.

**Client answers an expert-proposed reschedule (BOOK-06)**
- **D-01:** Add a **reschedule response card to the client Upcoming Booking details screen** (`UpcomingBookingView`), shown while the booking is `pending_reschedule` and the expert is the initiator. It shows the proposed new time and Accept / Decline. It reuses the Booking Summary logic (`BookingSummaryViewModel.acceptReschedule` / decline, the "charges soon" accept disclosure and the payment-method-required recovery path) rather than duplicating it; extract a shared helper if needed. Booking Summary keeps its own Accept/Decline. Endpoints: `POST /client/bookings/{id}/accept-reschedule`, `POST /client/bookings/{id}/decline-reschedule`.
- **D-02:** Decline asks for an **optional reason** (≤ 500 characters, the endpoint's limit), as Booking Summary does today. On success the original time is restored.
- **D-03:** After Accept or Decline succeeds, the client **stays on Upcoming Booking details**. The card disappears, the time and the status pill (BOOK-09) update in place, and a short confirmation is shown. Lists stay in step through the Phase 2 `booking.update` handling.

**Client cancel refund preview (BOOK-08)**
- **D-04:** The client cancel screen shows the **exact amount plus the reason**, mirroring the backend's `src/utils/refund.js` (`computeRefundAmountMinorUnits`): a captured booking cancelled strictly more than 24 h before start gets a full refund ("Refund: CA$45.00, cancelled more than 24 hours before the start"); at 24 h or less it gets nothing ("Refund: CA$0.00, the session starts within 24 hours"). A held (uncaptured) booking always reads as a release ("The CA$45.00 hold on your card will be released, so you won't be charged"). Free bookings show no money line.
- **D-05:** For a charged booking inside 24 h (refund 0), the review step shows the amount and reason **prominently in a warning style**. No extra confirmation dialog; the existing final confirm button is the gate.
- **D-06:** The preview is **recomputed at the moment the client confirms**, so crossing the 24 h line while the screen is open is reflected. After the cancel, the success message uses the **server's `refund_amount`** from the cancel response, so the client sees what actually happened. (Note: the cancel can return `refund_amount` 0 while a Stripe void/refund is being retried; research should check how to word that case so it doesn't read as "no refund".)

**Expert cancel copy (EXP-11)**
- **D-07:** The expert cancel screen **states the client's amount in the same format as D-04**: "The client will get a full refund of CA$45.00", or "The client's CA$45.00 hold will be released" for a held booking. A free booking shows no money line. Applies to the Booking Summary cancel entry and `ExpertCancellationView`. — **Reversibility:** costly — the copy promises live refund behavior (BACK-19); if BACK-19's smoke finds a problem, both this copy and Android's must change.

**Skype/Zoom session screen and opening it (CALL-06, CALL-07, CALL-08)**
- **D-08:** The Skype/Zoom session hero shows the **same timer as the in-app voice layout**: reuse `timerString` (elapsed since the scheduled start) and `remainingLabel` from `MeetingCallViewModel`, so both call types look the same and share one code path.
- **D-09:** The "meeting in progress" status copy **no longer promises an automatic end**: "Meeting in progress. Scheduled to finish at {end}. Tap End Session when you're done." The existing amber banners (ending soon, scheduled time complete, end + 55 notice) stay.
- **D-10:** On Upcoming Booking details, a Skype/Zoom booking inside the join window gets an **Open Meeting button** (with the CALL-09 provider label) that goes through `CallCenter.startCall` into the Skype/Zoom session screen, the same path as the My Bookings card, so the timer, End Session and `/end` reporting work. It does not open the URL directly. The existing link text and Copy stay.

**After a client reschedule request (BOOK-16)**
- **D-11:** After the client sends a reschedule request, the app **pops exactly one level, back to wherever Reschedule was tapped** (Upcoming Booking details or the My Bookings card), and shows a **"Reschedule request sent" toast** (Android parity). The status there now reads Pending reschedule (BOOK-09).

**Todos**
- **D-12:** No pending todos are folded into this phase (all three matched on keywords only).

### Claude's Discretion
Follow the inventory fix (`.planning/IOS-BUG-INVENTORY.md`) and Android's choice where it made one:
- **BOOK-07:** send the cancellation comment in `reason` as `"label: comment"`, capped at 500, as Android does (BACK-14 stores it).
- **BOOK-09:** bind the Upcoming Booking status pill to the real decoded status.
- **BOOK-11:** Past tab empty state, matching the Upcoming tab's empty-state style.
- **BOOK-12:** Keep Booking pops one level, not to the My Bookings root.
- **BOOK-13:** hide Cancel once `end < now` (BACK-12 also rejects it server-side).
- **BOOK-16 remainder:** pass `exclude_booking_id` to availability so the booking being moved doesn't block its own slot; replace the stale "Settings > Payment" path with the real menu path; fix the "cancel and book again" advice for a held booking moved inside 24 h so it matches what the backend actually does (research verifies the backend behavior first).
- **BOOK-17:** Leave a Review on Booking Summary only for `.completed`. Review edit/resubmit stays as is (by design).
- **BOOK-20:** show the booking ID on the client Booking Summary in the same short `ID: …` format as Upcoming Booking details, on iOS and on Android (separate Android commit).
- **CALL-03:** wire `onJoinCall` into `UpcomingBookingView` from every caller (`MyBookingsView`, `HomeClientView`).
- **CALL-10:** add Join to the expert Booking Summary, gated by the shared join window, starting the call through `CallCenter.startCall`. Placement follows the screen's existing action style.
- **EXP-13:** pass `onReschedule` on the expert Upcoming card (Home and Dashboard) to `ExpertRescheduleView`. The expert picker's 6-day cap is EXP-13-adjacent Phase 6 work unless research shows it ships with this flow.
- Decline note (BACK-02 iOS half): a declined booking shows the expert's decline note on the client screens that show the decline.

### Deferred Ideas (OUT OF SCOPE)
- Android copy check for the expert-cancel full-refund wording (already logged as a Phase 1 D-17 follow-up).
- Reviewed todos, not folded: `2026-11-08-check-the-android-push-prompt-after-a-reinstall.md` (Android push), `2026-11-08-show-the-suspension-message-on-a-cold-launch.md` (auth, Phase 5), `2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md` (payments backend, Phase 4).

### Approved UI contract (03-UI-SPEC.md, status approved 2026-11-10) — binding on copy, layout and the dismissed limitations
- Copy strings in its Copywriting Contract are exact. K1 (declined shows the `Cancelled` badge), U2 (refund preview uses the list price, not the amount paid) and U3 (expert cannot tell charged from never-charged) are **dismissed by the user**: do not change the badge, do not add `amount_paid_minor_units` or `payment_status` to any API. K2 (no overtime banner on the Skype layout) is **unresolved**, revisit only if the user asks.
- The shipped `Cancel` / `Reschedule` labels on `UpcomingBookingSecondaryActions` are kept; no new color or `Brand` token; no new package; per-screen brand enums are not added, renamed or merged.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BOOK-06 | Client accepts/declines an expert-proposed reschedule from the upcoming flow (critical) | Extract a shared responder from `BookingSummaryViewModel`; Upcoming VM must store `reschedule`, `authorizationExpiresAt`, `startTime`; silent refetch (Pitfall 1); backend endpoints verified (Section "Backend facts") |
| BOOK-07 | Cancellation comment is sent | `cancelClientBooking(id:reason:)` already takes `reason`; compose `"label: comment"` by UTF-16 length (Pitfall 5); backend stores it (BACK-14) |
| BOOK-08 | Cancel screen previews the refund the backend gives | Pure `CancelRefundPreview` mirroring `refund.js`; payment-state facts verified (Pitfall 4); cancel response needs a typed decode |
| BOOK-09 | Upcoming status pill shows real status | `UpcomingBookingStatusRow` hard-codes "Confirmed" today; VM must keep the raw status string |
| BOOK-11 | Past tab empty state | Gate on `selectedTab == 1 && pastBookings.isEmpty` inside `loadedContent` only |
| BOOK-12 | Keep Booking returns one screen | `popToRoot()` is `navPath.reset()`; use `pop()` |
| BOOK-13 | Cancel hidden once session ended | Needs `endTime` in Upcoming VM; 60 s `TimelineView`; server also rejects (BACK-12) |
| BOOK-16 | Reschedule picker details | `getExpertAvailability` has no `exclude_booking_id` param yet; backend supports it; copy fixed in UI-SPEC and verified |
| BOOK-17 | Leave a Review only for completed | `viewModel.status == .completed` already exists on the Summary VM |
| BOOK-20 | Booking ID on client Booking Summary (iOS + Android) | iOS: add label to Summary VM + `BookingSummaryExpertCard`; Android: `BookingSummaryCard.kt` + existing `shortBookingId` |
| CALL-03 | Join on Upcoming details starts the call | VM must hold start/end/expertId/canJoin; `UpcomingBookingView` has 4 callers (see Pitfall 2) |
| CALL-06 | Skype/Zoom status copy has no auto-end promise | `skypeStatusText` is a private computed in `MeetingCallView`; move into the VM for testing |
| CALL-07 | Skype/Zoom screen shows elapsed/remaining time | Timer already starts on the Skype branch; hero needs the three VM values |
| CALL-08 | Open Skype/Zoom meeting from Upcoming details | New button via `CallCenter.startCall`; provider label from `ExternalMeetingProvider` (unknown host must read `Open Meeting`) |
| CALL-10 | Expert Join on Booking Summary | `ExpertBookingDetail.actions.canJoin`; do NOT use `JoinWindow.showsJoinButton` alone (Pitfall 3) |
| EXP-11 | Expert cancel screen states client's refund | Replace `refundType` string with a computed line; backend verified: expert cancel refunds `amount_paid_minor_units` in full |
| EXP-13 | Expert Upcoming card Reschedule opens expert flow | One edit in `UpcomingBookingsView`; fix the wrong-tab pop in `HomeExpertView` (Pitfall 8) |
</phase_requirements>

## Summary

Every backend capability this phase needs is already deployed and read-verified this session: accept/decline reschedule, cancel with `reason` stored (BACK-14), `SESSION_ALREADY_ENDED` (BACK-12), `decline_reason_code/text` on the client detail (BACK-02), `can_join`, `exclude_booking_id` on availability, and the expert full refund (BACK-19 code). **No backend change is needed**, so no backend commit and no Android-compat risk beyond the one BOOK-20 Android edit. The work is iOS wiring plus a handful of pure, testable helpers.

The shared plumbing from Phase 2 exists under its real names: `JoinWindow.isOpen/showsJoinButton`, `Money.format(minorUnits:currency:)` and `Money.format(major:currency:)`, `BookingStatus` (unknown fallback), `ReloadGeneration`. The 03-UI-SPEC is detailed and approved; this research does not re-derive it. The risk is in places the UI-SPEC does not reach: (1) `UpcomingBookingViewModel.forceLoad` flips `state = .loading` on every refetch, which would blank the screen under the new in-place accept/decline flow; (2) `UpcomingBookingView` has four callers and only one passes any callbacks, so Cancel, Reschedule and Join are inert on the push-opened and Payments routes (Phase 2 explicitly deferred this to Phase 3); (3) the shared tab shells pop the wrong tab's path for the expert reschedule route; (4) the cancel comment must be capped by UTF-16 length, not Swift `Character` count, or emoji can push `reason` over the server's 500 limit; (5) `ClientBookingDetail` lacks the decline fields, `cancelClientBooking` discards `refund_amount`, and `getExpertAvailability` lacks `exclude_booking_id`.

**Primary recommendation:** Plan in this order: a no-UI foundation plan (models, pure helpers with tests, `ToastCenter`), then BOOK-06 (shared `RescheduleResponder` + response card + silent refetch + BOOK-09 pill) as the first user-visible plan, then Upcoming Join/Cancel-visibility with `HomeRoute` action routes, then cancel flow, reschedule picker and My Bookings, Booking Summary + Android BOOK-20, Skype screen, expert side, and a Phase 3 device-UAT checklist. Serialize plans that touch `UpcomingBookingView`/`UpcomingBookingViewModel` and `MyBookingsView` (many requirements converge there).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Refund amount actually paid out | API / Backend | — | `cancel` computes via `computeRefundAmountMinorUnits`; iOS only previews and must defer to the response |
| Refund preview copy | iOS View Model (pure helper) | API (data source) | Mirrors the 24 h rule from fields the detail already returns; server wins at confirm |
| Join eligibility (display) | iOS shared helper (`JoinWindow`) | API (`can_join`, `POST /join`) | Display gate only; server enforces |
| Reschedule accept/decline + payment conversion | API / Backend | iOS responder | Server voids/converts the hold; iOS supplies the saved card on `PAYMENT_METHOD_REQUIRED` |
| Cancel after end rejected | API / Backend (409) | iOS hides button | UI hide is cosmetic; BACK-12 is authoritative |
| Decline note text | API (BACK-02) | iOS renders plain text | Server exposes only when `status == declined` |
| Toast / transient confirmation | iOS shell (client only) | — | Must outlive popped screens, so it lives above the stacks |
| Navigation depth after cancel/reschedule | iOS shell per-tab `HomeNavigationPath` | — | One-level `pop()` vs `reset()` |
| Booking ID on Android summary | Android app | — | Separate repo, separate commit |

## Standard Stack

No new packages. Everything is in-repo; Phase 3 adds no dependency (no Package Legitimacy Audit needed).

### Core (existing, by real name)
| Symbol | Where | Purpose | Notes |
|--------|-------|---------|-------|
| `JoinWindow.isOpen(status:start:end:now:serverCanJoin:)`, `JoinWindow.showsJoinButton(status:)` | `ClickMe2026/Utils/JoinWindow.swift:54-82` | The one join-window rule | `showsJoinButton` returns `status != .pendingApproval` (true for cancelled/declined/missed/expired too, see Pitfall 3) |
| `Money.format(minorUnits:currency:) -> String`, `Money.format(major:currency:) -> String?` | `ClickMe2026/Utils/Money.swift` (major entry at :123) | Only way to render money | Cancel response `refund_amount` is **major**; `topic.price.amount` and `UpcomingBooking` prices are **minor** |
| `BookingStatus` (`init(from:)` falls back to `.unknown`) | `ClickMe2026/Model/Enums/BookingStatus.swift:21-41` | Status decoding | `unknown` loses the raw string, so BOOK-09 humanizing needs the raw `String` kept alongside |
| `ReloadGeneration` | `ClickMe2026/Utils/ReloadGeneration.swift` | Newest-refetch-wins | Already in `UpcomingBookingViewModel` and `BookingSummaryViewModel` |
| `CallCenter.shared.startCall(bookingId:peerId:peerName:peerImageURL:topic:scheduledStart:scheduledEnd:meetingType:isRejoin:)` | `ClickMe2026/Managers/CallCenter.swift:118` | Only entry to start a call | `isRejoin: status == .completed` |
| `HomeNavigationPath` (`push/pop/reset/replace(with:)`), `HomeRoute` | `ClickMe2026/Views/Extensions/HomeNavigationPath.swift` | Per-tab navigation | Every `HomeRoute` is registered once per tab via `homeStack` in both shells (CR-01) |
| `BookingErrorMapper`, `Error.userMessage`, `ErrorCode` | `ClickMe2026/Utils/`, `Network/` | Error copy | `SESSION_ALREADY_ENDED` is not in `ErrorCode`; unknown codes decode to nil and the server message is shown, which is the desired behavior |
| `ExternalMeetingProvider` (`detect(from:)`, `displayName`, `iconSystemName`) | `ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift` | Provider label | `displayName` for `.unknown` is `"Meeting"`, so `"Open in \(displayName)"` reads "Open in Meeting" (UI-SPEC wants `Open Meeting`) |
| Swift Testing + `MockURLProtocol` + `APITestFactory.make` | `ClickMe2026Tests/Support/` | VM-level tests against stubbed HTTP | Proven by `ClientBookingStatusFallbackTests` |

### New in-repo units this phase should add (names are recommendations)
| Unit | Kind | Purpose |
|------|------|---------|
| `RescheduleResponder` | `@MainActor ObservableObject` | accept/decline/PM-recovery/disclosure shared by Summary and Upcoming (D-01) |
| `CancelRefundPreview` | pure `enum` | cases A-F from UI-SPEC, 24 h boundary, copy builder |
| `CancelReasonComposer` | pure `enum` | `"label: comment"`, UTF-16 cap 450/500 |
| `CancelToastMessage` | pure `enum` | server `refund_amount` + confirmed case to toast text (D-06 table) |
| `BookingStatusPill` (display model) | pure | raw status to text + tone (UI-SPEC table) |
| `DeclineNote` | pure | code to reason label (UI-SPEC table) |
| `ExpertCancelRefundLine` | pure | free / hold / full refund / unformattable |
| `BookingShortID` | pure | one `#` + 8 uppercase formatter (today inlined twice in `UpcomingBookingViewModel` lines `init` and `apply`) |
| `ToastCenter` + `ToastHost` | `@MainActor @Observable` singleton + `ViewModifier` | the one shared toast (UI-SPEC section 10) |

**Installation:** none. **Version verification:** not applicable (no packages).

## Architecture Patterns

### System Architecture Diagram

```
 booking.update (socket) ──┐
 push tap / chat row ──────┼─> HomeRoute.upcomingBooking(id) ─┐
 Payments list link ───────┤                                   │
 My Bookings card tap ─────┘   BookingRoute.upcoming(booking) ─┤
                                                               v
                                   UpcomingBookingView  <── UpcomingBookingViewModel
                                    │ status pill (raw status)      │ GET /client/bookings/:id
                                    │ reschedule card ──> RescheduleResponder ──> POST accept/decline-reschedule
                                    │                         └─ PAYMENT_METHOD_REQUIRED ─> GET /me/payment-methods ─> retry
                                    │ Join / Open Meeting ──> CallCenter.startCall ──> POST /bookings/:id/join
                                    │ Reschedule ──> RescheduleView ──> PATCH reschedule (+ exclude_booking_id on availability)
                                    │                    └─ success: nav.pop() (one level) + ToastCenter "Reschedule request sent"
                                    └ Cancel (hidden if end < now) ──> ClientCancellationView
                                         step 1 reason + comment (450) ─> step 2 confirm
                                         CancelRefundPreview(case from detail + clock) ── recompute at tap (second tap if C→D)
                                         POST cancel {reason:"label: comment"} ─> {refund_amount (major), currency}
                                         └─ nav.reset() to Bookings root + ToastCenter(CancelToastMessage)
 ToastCenter lives above the stacks (HomeClientView) so it survives the pop.

 Expert: UpcomingBookingsView card ──Reschedule──> HomeRoute.expertReschedule (originating tab's nav)
         ExpertBookingSummaryView ── Join Session ──> CallCenter.startCall (canJoin from details)
                                  └ Cancel sheet ──> ExpertCancelRefundLine(detail) ──> POST /expert/bookings/:id/cancel
```

### Recommended Project Structure (additions only)
```
ClickMe2026/
├── Utils/
│   ├── CancelRefundPreview.swift      # pure, with tests
│   ├── CancelReasonComposer.swift
│   ├── CancelToastMessage.swift
│   ├── BookingStatusPill.swift
│   ├── DeclineNote.swift
│   └── BookingShortID.swift
├── Managers/ToastCenter.swift         # @MainActor @Observable, static let shared
├── Views/Components/Toast/ToastHost.swift
└── Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift  (+ shared card subview)
ClickMe2026Tests/
├── Support/ClientBookingFixtures.swift   # shared detail JSON builder (today private in ClientBookingStatusFallbackTests)
└── Booking/, Utils/, Calls/ ...          # one suite per helper (see Validation Architecture)
```
File-system-synchronized groups mean new files under `ClickMe2026/` and `ClickMe2026Tests/` are picked up with no pbxproj edit [VERIFIED: ClickMe.xcodeproj/project.pbxproj lines 53-77, `PBXFileSystemSynchronizedRootGroup` for `ClickMe2026`, `ClickMe2026Tests`, `ClickMe2026UITests`].

### Pattern 1: Shared reschedule responder (BOOK-06, D-01)
**What:** Move `acceptReschedule`, `declineReschedule`, the PM-recovery fallthrough, `isSubmittingReschedule`, `rescheduleError`, `requiresAcceptRescheduleDisclosure`, `acceptRescheduleChargesSoon` and the dialog-message builder (currently a private computed on `BookingSummaryView`) into one object. Both view models own one and pass a `refetch: () async -> Void` closure. The disclosure inputs are `authorizationExpiresAt`, `reschedule.proposedEnd/proposedStart` and a `now`.
**Why:** `BookingSummaryViewModel` is the source of truth today (`acceptReschedule`, `declineReschedule`, `errorCode(for:)`); duplicating it into `UpcomingBookingViewModel` would fork the money-affecting recovery path. CLAUDE.md says extract rather than grow view models.
**Contract points (verified):** accept sends an empty-object body (`params: [String: Any] = [:]`), and a second call adds `stripe_payment_method_id` only after `.paymentMethodRequired` and a vault read; decline sends `reason` only when non-empty after trimming; backend `rescheduleDeclineSchema` is `z.string().max(500).optional()` and `.strict()` [VERIFIED: ClickMe2026 Backend/src/schemas/booking.schema.js:218-220].
**Copy changes owned by the responder:** the two "Settings > Payment" strings become "Profile > Payment" (UI-SPEC), and `RESCHEDULE_OUTSIDE_AUTH_WINDOW` on accept gets its new line.

### Pattern 2: Pure decision helpers, thin views
Every rule the UI-SPEC defines as a table (refund case, status pill, decline reason, expert refund line, toast text, Join visibility, Cancel visibility) is a pure function with injected `now`. Views only render. This is also what makes the phase testable without a UI test target, since SwiftUI rendering is device-only (UI-SPEC D2-D4).

### Pattern 3: Refund preview from fields the detail already returns
```swift
// Source: derived from backend rules read this session (see Backend facts); copy from 03-UI-SPEC
enum RefundCase { case free, liveHold, chargedRefundable, chargedNotRefundable, notChargedYet, amountUnknown }

static func refundCase(topic: ClientBookingDetail.Topic,
                       paymentStatus: String,
                       authorizationExpiresAt: Date?,
                       start: Date, now: Date) -> RefundCase {
    if topic.isFree { return .free }
    guard topic.price?.amount != nil, topic.price?.currency != nil else { return .amountUnknown }
    switch paymentStatus {
    case "none": return .notChargedYet
    default:     // "held" or "captured"
        if paymentStatus == "held", authorizationExpiresAt != nil { return .liveHold }
        // strictly more than 24 h => full; exactly 24 h or less => 0 (refund.js: `hoursUntilStart > 24`)
        return start.timeIntervalSince(now) > 24 * 3600 ? .chargedRefundable : .chargedNotRefundable
    }
}
```
`refunded` (a cancelled booking) never reaches the cancel screen; treat any other string as `.amountUnknown`-safe default rather than inventing a case.

### Pattern 4: Toast above the stacks (UI-SPEC section 10)
`ToastCenter` is a `@MainActor @Observable final class` with `static let shared` (repo style for shared managers), `show(_ message:, systemImage:)`, a cancellable 4 s `Task` for auto-dismiss (a new message cancels and restarts), tap-to-dismiss, and a VoiceOver announcement via `AccessibilityNotification.Announcement(message).post()` `[ASSUMED: iOS 17+ API; project minimum is iOS 18]`. `ToastHost` is a `ViewModifier` applied once in `HomeClientView` next to `CallOverlayHost`. Success paths call `ToastCenter.shared.show` *before* triggering the pop so the message exists when the destination screen appears.

### Pattern 5: Route per tab, pop the originating path
`homeStack(_ nav:path:root:)` already receives `nav` in both shells but `homeRouteDestination(route)` does not. Change it to `homeRouteDestination(route, nav:)`. This fixes Pitfall 8 and lets new client action routes pop the correct path. Alternative for leaf views: read `@Environment(\.homeNavigationPath)` inside a small wrapper view.

### Anti-Patterns to Avoid
- **Re-implementing the join window** or reading `Date()` inside a view body: pass `context.date` from the 60 s `TimelineView` (pattern already used in `UpcomingBookingCard`, `UpcomingBookingsSessionCard`, `ExpertDashboardView`).
- **Using `Text("…\(serverString)…")` as markdown-bearing** or any HTML/markdown rendering for the decline note: render as plain text (`Text(verbatim:)` or a `String` variable). The backend says "Render as plain text" [CITED: openapi/clickme-api.yaml `decline_reason_text` description].
- **`try?` on writes**, string-matching error messages, a private `errorMessage(for:)`: all banned by CLAUDE.md. Use `Error.userMessage` and `ErrorCode`.
- **`popToRoot()` for Keep Booking / reschedule return** (it is `navPath.reset()`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Join window arithmetic | local `start - 3600` checks | `JoinWindow.isOpen` | Edges are inclusive and unit-tested; reconnect tier needs `serverCanJoin` |
| Money text | `String(format: "%.2f")`, `NumberFormatter` | `Money.format(minorUnits:)` / `format(major:)` | Fixed symbol table (`CA$`), zero-decimal set, integer math |
| Booking ID text | a third copy of `"#" + prefix(8).uppercased()` | one `BookingShortID` used by Upcoming VM and Summary VM | Android and iOS must match (BOOK-20) |
| Newest-fetch-wins | ad hoc `isLoading` flags | `ReloadGeneration` | Out-of-order responses already bit this app |
| Provider label/icon | URL host sniffing in views | `ExternalMeetingProvider.detect` | Lookalike-host hardening already tested |
| Refund amount | a client-side authoritative refund | server `refund_amount` in the cancel response | iOS preview uses list price (U2 dismissed); the response is the truth |
| Error text | switch on message text | `ErrorCode` + `Error.userMessage` | CLAUDE.md |

**Key insight:** every number or rule shown to the user in this phase already exists in the backend or a Phase 2 helper. The bugs are that iOS invents or drops them. Mirror, don't reinvent.

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted.

## Common Pitfalls

### Pitfall 1: Refetch flips the whole Upcoming screen to a spinner
**What goes wrong:** D-03 says the card disappears and the time/pill update in place. `UpcomingBookingViewModel.forceLoad` sets `state = .loading` first, and `content` switches on `state`, so the loaded view is torn down and rebuilt (copy-link `@State`, scroll offset and any in-flight UI reset; the toast and pill "keep previous value" rule (UI-SPEC section 2) is violated). Same for `BookingSummaryViewModel.forceLoad` (`loadState = .loading`).
**Why:** `forceLoad` conflates first load with refresh. Socket-driven `reload()` has the same flicker today.
**How to avoid:** add a silent refresh path (`refresh()` that does not touch `state` unless the first load failed; still uses `ReloadGeneration` tokens and writes only when current). Use it after accept/decline, on `booking.update`, and on `onAppear` after the first load (so returning from Reschedule shows "Pending reschedule" even if the socket event is missed). Note `.task { await viewModel.load() }` returns early when already `.loaded`.
**Warning signs:** a brief spinner after tapping Accept New Time; pill still "Confirmed" after popping back from Reschedule.

### Pitfall 2: Four callers, one passes callbacks; Cancel/Reschedule/Join are inert elsewhere
**What goes wrong:** `UpcomingBookingView(bookingId:)` is constructed with default `{}` callbacks at `HomeClientView.swift:301-302` (push taps, chat rows, Explore today strip), `HomeExpertView.swift:245-246`, and `ClientTransactionsView.swift:70-72` (a `NavigationLink`). Only `MyBookingsView.swift:108-112` passes `onReschedule`/`onCancel`, and nobody passes `onJoinCall`. Likewise `BookingSummaryView(bookingId:)` from `HomeRoute.bookingSummary` has inert `onLeaveReview`, `onBookAgain`, `onOpenPrivateNote`.
**Why it matters:** Phase 2 deferred exactly this to Phase 3 [VERIFIED: 02-VERIFICATION.md "Push-opened booking screens have working Join, Cancel, Reschedule and Leave Review actions" addressed_in "Phase 3"]. A `pending_reschedule` push (the BOOK-06 scenario) lands on the `HomeRoute` path, so BOOK-06 working only from My Bookings would miss the main entry.
**How to avoid:** make Join self-contained in the view model/view (it already has `expert.id`, name, avatar, topic, times, meeting type once loaded) so every caller works with no wiring; keep `onJoinCall` as an override seam. Add client action routes `HomeRoute.cancelBooking(bookingId:)`, `.rescheduleBooking(bookingId:)`, `.writeReview(bookingId:)` registered in `homeRouteDestination` (stub `EmptyView` in the expert shell, as the existing expert-only cases do), and have the views push them via `@Environment(\.homeNavigationPath)` when no callback is injected. Registering them in `homeRouteDestination` registers them once per tab (CR-01). Book Again / Message / Private Note on the push-opened summary are out of the 17 requirements; fold in only if cheap.

### Pitfall 3: `JoinWindow.showsJoinButton` is not a visibility rule for terminal bookings
It returns `status != .pendingApproval` (JoinWindow.swift:54-56), so it is true for cancelled, declined, missed, expired. The client Upcoming screen is reachable for any transaction (Payments list), and the expert summary is reachable for terminal bookings. UI-SPEC section 3 defines expert visibility explicitly: render for `confirmed`, `in_progress`, `pending_reschedule`, or when `JoinWindow.isOpen` is true (completed inside the reconnect window); never for `pending_approval`, `cancelled`, `declined`, `missed`, `expired`. Implement that as one pure function with a test, not an inline condition.

### Pitfall 4: Payment-state signals the refund preview depends on
Verified in `derivePaymentStatus`: no PaymentIntent gives `none`; raw `canceled/auth_expired/failed` gives `none`; `pending_approval`, `pending_reschedule`, `confirmed`, `in_progress` give `held` **even if the money was already captured** (the T-24h charge); only `completed` gives `captured` [VERIFIED: clientBooking.controller.js:79-105]. `authorizationExpiresAt` is non-null only when raw `payment_status == 'requires_capture'` and `authorized_at` exists [VERIFIED: src/utils/reschedule.js:48, 273-280]. So the UI-SPEC rule "held and `authorizationExpiresAt == nil` means already charged" is correct. One uncovered edge: a failed off-session T-24h charge awaiting SCA reads `held` with `authorizationExpiresAt == nil` and `payment_action_required: true` (from `paymentActionFields`, spread into the detail response). It would be classed as "charged" (case C/D) though nothing was charged. Decode `paymentActionRequired: Bool?` and map it to case E. Rare; low cost. `[ASSUMED]` that the user wants this beyond the UI-SPEC (Open Question 3).

### Pitfall 5: Cancel comment length must be UTF-16, not `Character` count
The server schema is `z.string().trim().max(500)` (UTF-16 code units) [VERIFIED: booking.schema.js:119-124]; Android caps in UTF-16 units (`capNotes`) and documents "472" as the maximum [VERIFIED: ClickMe_Android .../cancellation/CancellationReason.kt:22-44]. Swift's `String.count` counts grapheme clusters; 450 family-emoji clusters can exceed 500 UTF-16 units and the cancel would 4xx *after* the user confirmed. Cap with `utf16.count` and truncate at a grapheme boundary (never split a surrogate pair). The same applies to the 500-character decline-reschedule reason (D-02), which the UI-SPEC says "input stops at 500 characters" in an alert text field: enforce on submit (cap) because an alert `TextField` cannot be limited per keystroke easily. Also note the endpoint is `.strict()`: send no extra keys.
Privacy note: the cancel reason is "shown to the other party of the booking, through GET /expert/bookings/{id}/summary" [CITED: openapi/clickme-api.yaml cancelClientBooking]. The existing field label does not say so; flag to the user (Open Question 4), do not change copy unilaterally.

### Pitfall 6: Cancel response drops `refund_amount`
`cancelClientBooking` returns `SuccessMessageResponse` (status, message only). D-06 needs `data.refund_amount` (major units) and `data.currency`. Decode a new `CancelBookingData` via `SuccessDataResponse` (the cancel response always has `data`, including the "already cancelled" idempotent 200 path where `refund_amount` is 0). Pass the value through `Money.format(major:currency:)` (can return nil: then use the no-amount toast variant). The backend returns 0 for a released hold, a within-24h charge, a free booking, and a failed void/refund being retried (flag `refund_failed`, cron retry) [VERIFIED: clientBooking.controller.js cancel catch block "refundAmountMinorUnits = 0"; openapi description]. Therefore the toast table in UI-SPEC (case-aware wording) is required; never print "no refund" for 0 outside case D.

### Pitfall 7: Server status set for Cancel is narrower than the UI hide rule
Client cancel accepts only `confirmed`, `pending_approval`, `pending_reschedule`; `in_progress` and `completed` return 409 `INVALID_STATUS` [VERIFIED: clientBooking.controller.js `cancellableStatuses`]. BOOK-13 and UI-SPEC hide Cancel only when `end < now`, and UI-SPEC states "Cancel is not hidden for any other reason in this phase". So Cancel on an in-progress session before its scheduled end shows the button and fails with the server message. That is within the approved contract, but is a UX gap; see Open Question 1. Implement the hide as a pure `canShowCancel(status:end:now:)` so adding a status condition is a one-line change if the user approves.

### Pitfall 8: Expert reschedule route pops the wrong tab
`HomeExpertView.swift:251-254`: `case let .expertReschedule(bookingId): ExpertRescheduleView(bookingId: bookingId, onRescheduled: { bookingsPath.pop() })`. The route can be pushed from the Dashboard tab (Dashboard "calendar" embeds `UpcomingBookingsView()`, and the Dashboard strip opens `ExpertBookingSummaryView`) so after a successful submit `bookingsPath.pop()` pops the Bookings tab (a silent no-op, or it removes an unrelated screen there) and the user stays on the reschedule form. EXP-13 explicitly wires the Dashboard path, so this must be fixed in the same plan (Pattern 5).

### Pitfall 9: `UpcomingBookingView` needs more loaded data than it stores
`UpcomingBookingViewModel` stores strings only. Needed additions: `startTime`, `endTime`, `expertId`, raw `status` string, `canJoin`, `reschedule`, `authorizationExpiresAt`, `joinLink` (already), `paymentStatus` (already). `previewSeed` and `init` must set the new fields (previews compile in Release; no `#if DEBUG`).

### Pitfall 10: `joinError` alert may not present from a pushed screen
`MyBookingsView` owns the `Couldn't join call` alert on its root `screen`. When Join is tapped on a pushed `UpcomingBookingView` the failure sets `CallCenter.shared.joinError`; whether an alert attached to the covered root presents is `[ASSUMED]` fine but unverified, and the Payments entry has no host at all. Safest: attach the same alert (and `micPermissionDeniedAlert`) to `UpcomingBookingView` and to `ExpertBookingSummaryView`, or move both to `CallOverlayHost` once and delete the per-screen copies. Verify on device (UI-SPEC D3/D4).

### Pitfall 11: Tests define `URLRequest` body helper privately in excluded files
`httpBodyOrStreamData()` is a `private extension` in `LoginTests.swift` and again in `ResetPasswordTests.swift`; the Phase 2 verify command excludes `LoginTests.swift`. A new suite that needs to assert the cancel body (`reason`) or accept body must bring its own helper. Name it differently (for example `bodyDataForTest()`) in `Support/` to avoid an ambiguous-overload with the private ones. `MockURLProtocol.handler` and `recordedRequests` are shared statics, so every suite touching them must be `.serialized` and be run one suite per `xcodebuild` call (the established pattern).

### Pitfall 12: `previewSeed`/memberwise init breakage
`CancellationBooking(expertName:expertTitle:dateString:imageURL:refundAmount:)` is constructed in `ClientCancellationViewModel` (`map`, `placeholderBooking`, `sampleBooking`) and previews. Replacing `refundAmount: String?` with refund facts changes all of them. Update previews in the same task or the build fails.

## Code Examples

### Cancel reason composer (UTF-16 safe)
```swift
// Source: contract from booking.schema.js:119-124 and Android CancellationReason.kt:22-44
enum CancelReasonComposer {
    static let commentLimit = 450      // UTF-16 units; longest label (20) + ": " (2) + 450 = 472
    static let reasonLimit = 500

    static func capComment(_ text: String) -> String { prefixUTF16(text, limit: commentLimit) }

    static func reason(label: String, comment: String) -> String {
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = trimmed.isEmpty ? label : "\(label): \(trimmed)"
        return prefixUTF16(full, limit: reasonLimit)
    }

    private static func prefixUTF16(_ s: String, limit: Int) -> String {
        guard s.utf16.count > limit else { return s }
        var out = ""
        var used = 0
        for ch in s {                        // grapheme boundary: never splits a surrogate pair
            let n = String(ch).utf16.count
            if used + n > limit { break }
            out.append(ch); used += n
        }
        return out
    }
}
```

### Availability request with `exclude_booking_id` (BOOK-16)
```swift
// Source: existing ClickMeAPI+Availability.swift getExpertAvailability(id:month:) + backend availability.controller.js:225
func getExpertAvailability(id: UUID, month: String, excludeBookingId: UUID? = nil)
    async throws -> SuccessDataResponse<ExpertAvailabilityData> {
    var params: [String: Any] = ["month": month]
    if let excludeBookingId { params["exclude_booking_id"] = excludeBookingId.uuidString }  // backend regex is case-insensitive
    return try await service.httpRequest(url: url(.getExpertAvailability, id: id), method: .get, parameters: params)
}
```
`RescheduleViewModel.fetchAvailability` passes `bookingId`; `MakeABooking` callers keep the default `nil`. The backend ignores invalid or non-matching ids silently.

### Cancel response and toast (D-06)
```swift
// Source: openapi cancelClientBooking 200 response (refund_amount major units, currency)
struct CancelBookingData: Decodable { let refundAmount: Double; let currency: String }
// ClickMeAPI: func cancelClientBooking(id: UUID, reason: String) async throws -> SuccessDataResponse<CancelBookingData>
```

### Join gating on Upcoming details
```swift
// Source: pattern in UpcomingBookingCard.swift (60 s TimelineView) + JoinWindow.swift:68-82
TimelineView(.periodic(from: .now, by: 60)) { context in
    let open = JoinWindow.isOpen(status: vm.bookingStatus, start: vm.startTime, end: vm.endTime,
                                 now: context.date, serverCanJoin: vm.canJoin)
    // enabled: open; dimmed 55% + hint "Available closer to the session start" otherwise
}
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Booking Summary only had Accept/Decline | Shared responder + card on both screens | BOOK-06 |
| `refundAmount: "$45.00"` always (full price) | Case-based preview + server amount in the toast | BOOK-08 |
| Hard-coded "Confirmed" pill | Pill from raw server status | BOOK-09 |

Deprecated here: the Booking Summary private `acceptRescheduleDialogMessage` (move into the responder), `ExpertCancellationClientBox.refundType` string parameter (remove per UI-SPEC).

## Backend facts verified this session (no backend change required)

| Fact | Source (read this session) |
|------|----------------------------|
| Refund rule: `if (hoursUntilStart > 24) { return booking.amount_paid_minor_units; }` else `return 0;` | `ClickMe2026 Backend/src/utils/refund.js:36-47` |
| Client cancel statuses: `const cancellableStatuses = ['confirmed', 'pending_approval', 'pending_reschedule'];` | `src/controllers/clientBooking.controller.js` (cancel) |
| After end: `throw new AppError(409, 'SESSION_ALREADY_ENDED', "This session has already ended, so it can't be cancelled.");` | same file, cancel |
| Failed Stripe void/refund: returns 200 with `refund_amount` 0 and sets `refund_failed: true`; cron retries | same file, cancel catch block; openapi `cancelClientBooking` |
| Detail: `decline_reason_code: booking.status === 'declined' ? ... : null`, `decline_reason_text` likewise, `cancellation_reason` only when cancelled, `can_join`, `authorization_expires_at` | `clientBooking.controller.js` getDetail |
| Decline code enum: `[UNAVAILABLE, OUTSIDE_EXPERTISE, SCHEDULE_CONFLICT, PRICING, OTHER, CONFLICT, OUT_OF_SCOPE, null]`; text `maxLength: 1000` | `openapi/clickme-api.yaml` ~14867-14890 |
| `exclude_booking_id` filters the booking out of the month's bookings before slot generation | `src/controllers/availability.controller.js:225-251` |
| Reschedule propose: `canReschedule` allows confirmed/pending_approval/pending_reschedule always, completed/in_progress only before end; paid moves capped at 6 days; `RESCHEDULE_OUTSIDE_AUTH_WINDOW` for no connected account, `DIRECT_CHARGE_ENABLED=false`, or `charge_due_at <= now` | `src/utils/reschedule.js`, `clientBooking.controller.js` reschedule |
| Expert cancel refunds `amount_paid_minor_units` in full at any time (`refundAmountMinorUnits = booking.amount_paid_minor_units;`); statuses via `CANCELLABLE_STATUSES` | `src/controllers/expertBooking.controller.js` (cancel ~1123-1231) |
| Expert details `actions.can_join/can_reschedule/can_cancel/can_message` | `expertBooking.controller.js` getDetails ~399-404 |
| `booking.update` is emitted to both participants' rooms | `docs/SOCKET-CONTRACT.md:119` |

Caveat: BACK-19 is deployed but its production smoke has not been run (REQUIREMENTS.md line 146). EXP-11 copy is code-verified, not production-verified (D-07 reversibility: costly).

## Android (BOOK-20 only)

Android client Booking Summary: `BookingSummaryDetails.bookingId` already exists (`BookingSummaryUiState.kt`), `shortBookingId(id)` is public (`upcomingbooking/UpcomingBookingUiState.kt:22`: `"#" + id.take(SHORT_ID_LENGTH).uppercase(Locale.ROOT)`), and the string `upcoming_booking_id` is `ID: %1$s` (`res/values/strings_upcoming_booking.xml:6`). Add the line after the `PriceText` row in `subviews/BookingSummaryCard.kt` (the topic/date/price `Column`, around lines 117-145), extend `BookingSummaryScreenTest`. One separate commit in `../ClickMe_Android`. UI-SPEC section 2 fixes the placement and style. Run Android unit tests with the project's Gradle wrapper `[ASSUMED: ./gradlew testDebugUnitTest; local JDK is 18.0.1.1, SDK at ~/Library/Android/sdk, not exercised here]`. iOS expert Booking Summary ID (EXP-18) is not in this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.alert` bound to `CallCenter.joinError` on a covered root view presents when a pushed screen triggers a failed join | Pitfall 10 | Silent join failure on Upcoming/Expert Summary; fix is to attach the alert locally |
| A2 | `AccessibilityNotification.Announcement(_:).post()` is available (iOS 17+) and speaks the toast | Pattern 4 | Toast not announced; use `UIAccessibility.post(notification: .announcement, argument:)` instead |
| A3 | Hiding Cancel (and Reschedule) for `in_progress`/`completed`/terminal statuses is wanted although UI-SPEC says Cancel is hidden only for `end < now` | Pitfall 7, Open Q1 | Cancel on an in-progress session shows a server 409 alert |
| A4 | Mapping `payment_action_required` to "not charged yet" copy is wanted | Pitfall 4, Open Q3 | A rare client with a failed T-24h charge reads a wrong refund line |
| A5 | The cancel comment being visible to the expert does not need new field copy | Pitfall 5, Open Q4 | Privacy surprise for clients |
| A6 | Android Gradle can run unit tests with local JDK 18 / SDK | Android | BOOK-20 Android verification falls back to review-only |
| A7 | BACK-19 behaves in production as the code does (expert cancel always full refund/release) | Backend facts, EXP-11 | EXP-11 copy would be wrong on both platforms |

## Open Questions

1. **Cancel/Reschedule on bookings the server will reject (user decision needed)**
   - Known: server accepts client cancel only for `confirmed`, `pending_approval`, `pending_reschedule`; Upcoming details is reachable for any booking via the Payments list (`ClientTransactionsView` link) and shows Cancel/Reschedule regardless of status. UI-SPEC: "Cancel is not hidden for any other reason in this phase."
   - Unclear: whether to also hide Cancel for `in_progress`/`completed`/terminal statuses.
   - Recommendation: implement the contract literally (`end < now`), via a pure `canShowCancel`, and ask the user whether to add the status condition (one-line change, matches the server). The planner should not decide this silently.

2. **Scope of push-opened actions (Pitfall 2)**
   - Known: Phase 2 deferred Join/Cancel/Reschedule/Leave Review on push-opened screens to Phase 3; CONTEXT names only `onJoinCall` wiring.
   - Recommendation: include Join, Cancel, Reschedule (Upcoming) and Leave Review (Summary) on the `HomeRoute` path in this phase (new `HomeRoute` cases, small); leave Book Again/Message/Private Note unless trivial.

3. **SCA-pending charge edge (Pitfall 4)** — decode `payment_action_required` and treat as case E? Recommendation: yes, one extra field and one test.

4. **Cancel comment visibility to the expert (Pitfall 5)** — keep the label as is (UI-SPEC copy locked) or add a hint? Recommendation: leave copy, log it in the Phase 3 UAT notes for the user.

5. **First-tap vs second-tap at the 24 h line (UI-SPEC section 5)** is already decided (second tap). No question; the helper must expose both the displayed case and the recomputed case so the view can compare them.

6. **Skype double-tap UX** — D-10 routes Open Meeting through `startCall`, which opens the Skype screen where the user taps "Open in {provider}" again. This is the locked decision; record in UAT so the user can judge it on device.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | All iOS tasks, tests | yes | Xcode 26.5 (17F42) | — |
| iOS Simulator "iPhone 17" | Test command destination | yes (3 devices with that name) | OS latest | use `id=` of one device if the name is ambiguous |
| Swift Testing | Unit tests | yes (in Xcode 26) | — | — |
| Backend repo + Node | Not needed (no backend change) | node v26.8.1 present | — | — |
| Android SDK / Gradle wrapper | BOOK-20 Android commit | SDK dir and `gradlew` present; JDK 18.0.1.1 | — | review-only if build fails `[ASSUMED]` |
| Real iPhone + two accounts (client, expert) + a Skype/Zoom booking | Device UAT (D2-D4) | not checkable here | — | UAT checklist for the user |
| Production BACK-19 smoke | EXP-11 confidence | not run | — | note in UAT |

**Missing with no fallback:** none for planning. Device checks are the user's (UAT).

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests` |
| Config file | `ClickMe2026/AllTests.xctestplan`; new files auto-register (synchronized groups) |
| Quick run command | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` |
| Full suite command | same, with `-only-testing:ClickMe2026Tests`; never run the two smoke suites (they hit production) |
| Build gate | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` with no new warnings in touched files |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command (`-only-testing:ClickMe2026Tests/…`) | File Exists? |
|--------|----------|-----------|--------------------------------------------------------|--------------|
| BOOK-06 | Accept posts `{}`; on `PAYMENT_METHOD_REQUIRED` reads vault and retries with `stripe_payment_method_id`; empty vault and repeat failure produce the "Profile > Payment" copy; decline trims, nil when blank, caps at 500 UTF-16; disclosure/charges-soon message builder; refetch after success; double-tap guarded | unit (stubbed API) | `RescheduleResponderTests` | ❌ Wave 0 |
| BOOK-06 | Upcoming VM exposes proposal only when expert-initiated; card absent after refetch | unit | `UpcomingBookingViewModelTests` | ❌ Wave 0 |
| BOOK-09 | Status to pill text/tone table incl. unknown and `rescheduled` | unit | `BookingStatusPillTests` | ❌ Wave 0 |
| BOOK-07 | `"label: comment"`, trimmed, label only when blank, cap 450/500 by UTF-16, emoji case | unit | `CancelReasonComposerTests` | ❌ Wave 0 |
| BOOK-07 | Cancel request body contains the composed `reason` | unit (recorded request) | `ClientCancellationViewModelTests` | ❌ Wave 0 |
| BOOK-08 | Cases A-F; exactly 24 h is not refundable; 24 h + 1 s is; zero-decimal currency; paid without price is F | unit | `CancelRefundPreviewTests` | ❌ Wave 0 |
| BOOK-08 | Second-tap rule: case changed at confirm blocks submit once | unit | `ClientCancellationViewModelTests` | ❌ Wave 0 |
| BOOK-08 / D-06 | Toast text matrix: server amount > 0, and 0 under each confirmed case; major-unit formatting; nil format | unit | `CancelToastMessageTests` | ❌ Wave 0 |
| BOOK-12 / BOOK-16 | Keep Booking and reschedule return use one-level pop, not reset | grep gate on `MyBookingsView.swift` + device | `grep -n "popToRoot" "ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsView.swift"` shows only the confirmed-cancel use | n/a |
| BOOK-16 | Availability GET carries `exclude_booking_id=<uuid>`; MakeABooking does not; copy has no "Settings > Payment"; three error strings | unit + grep gate | `RescheduleAvailabilityTests` | ❌ Wave 0 |
| BOOK-11 | Past empty state shown only when loaded and empty | view-model derivation test (small pure predicate) + device | `MyBookingsEmptyStateTests` | ❌ Wave 0 |
| BOOK-13 | `canShowCancel` false at `end < now`, true before; boundary at `end == now` | unit | `UpcomingActionPolicyTests` | ❌ Wave 0 |
| BOOK-17 | Leave a Review visible only for `.completed` and no submitted review | unit | `BookingSummaryViewModelTests` | ❌ Wave 0 |
| BACK-02 (iOS) | Decline note: card only for `declined`; reason labels per code incl. unlisted code shows no reason line; both nil hides | unit | `DeclineNoteTests` | ❌ Wave 0 |
| BOOK-20 | Summary ID label equals Upcoming label for same UUID | unit | `BookingShortIDTests` | ❌ Wave 0 |
| CALL-03 / CALL-08 | Upcoming join info/open state per status/time/`canJoin`; provider label incl. unknown host `Open Meeting` | unit | `UpcomingBookingViewModelTests`, `ExternalMeetingProviderTests` (exists, extend) | partial |
| CALL-10 | Expert Join visibility matrix (all 9 statuses x window) | unit | `ExpertJoinVisibilityTests` | ❌ Wave 0 |
| CALL-06 | Skype status line strings (not opened / end known / end unknown) | unit (move text into VM) | `SkypeStatusTextTests` | ❌ Wave 0 |
| CALL-07 | Hero shows same `timerString`/`remainingLabel` source | grep gate + device | `grep -n "timerString" ".../SkypeSessionHero.swift"` | n/a |
| EXP-11 | Expert refund line: free, live hold, full refund, unformattable | unit | `ExpertCancelRefundLineTests` | ❌ Wave 0 |
| EXP-13 | No `onReschedule: viewModel.onReschedule` default path; Dashboard and Bookings both reach `ExpertRescheduleView`; pop targets originating nav | grep gate + device | `grep -rn "onReschedule: viewModel.onReschedule" ClickMe2026` returns nothing | n/a |
| Toast | One at a time, replace restarts timer, dismiss | unit | `ToastCenterTests` | ❌ Wave 0 |
| Wiring | No caller constructs `UpcomingBookingView` with a dead Join; `Settings > Payment` absent | grep gates | `grep -rn "Settings > Payment" ClickMe2026` returns nothing | n/a |

Device-only (UAT, cannot be unit tested; UI-SPEC L2, L3, D2, D3, D4): toast placement above tab bar and keyboard and VoiceOver announce; Dynamic Type at the largest size on the new blocks; `Open in Microsoft Teams` on the smallest phone; Open Meeting to Skype screen timer and `/end`; expert Join across two accounts; `joinError` alert from a pushed screen; BOOK-06 end to end (expert proposes, client accepts and declines, from both My Bookings and a push tap); cancel at just over and just under 24 h on a captured booking.

### Sampling Rate
- **Per task commit:** the single new/changed suite via the quick command.
- **Per wave merge:** each suite touched in the wave (one `xcodebuild` per suite) plus the build gate.
- **Phase gate:** all Phase 3 suites + Phase 2 regression suites (`JoinWindowTests`, `MoneyTests`, `ClientBookingStatusFallbackTests`, `ReloadGenerationTests`, `BookingErrorMapperTests`, `ExternalMeetingProviderTests`), no new warnings, device UAT checklist run.

### Wave 0 Gaps
- [ ] `ClickMe2026Tests/Support/ClientBookingFixtures.swift` — shared client detail JSON builder with `reschedule`, `authorization_expires_at`, `can_join`, `decline_reason_*`, `payment_status` options (today private in `ClientBookingStatusFallbackTests`)
- [ ] `ClickMe2026Tests/Support/URLRequest+Body.swift` — body reader with a name that does not collide with the private ones (Pitfall 11)
- [ ] All suites in the table marked ❌ Wave 0
- [ ] A Phase 3 device UAT checklist document (model on `02-DEVICE-UAT-CHECKLIST.md`), including the K2 note and the Skype double-tap observation

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block on high).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no (no change) | existing token refresh |
| V3 Session Management | no | — |
| V4 Access Control | yes (display only) | server enforces ownership (404 for not-owned) and status guards; UI hides are cosmetic |
| V5 Input Validation | yes | client caps (450 comment, 500 reason, 500 decline reason by UTF-16) mirror server `cancelSchema`/`rescheduleDeclineSchema`; server is authoritative |
| V6 Cryptography | no | — |
| V7 Error handling / logging | yes | `Error.userMessage`; do not log cancel comments, decline notes or reasons; any new debug print inside `#if DEBUG` |
| V8 Data protection | yes | cancel reason is stored and shown to the other party (Pitfall 5); decline note is expert-authored free text |
| V13 API | yes | typed decode; send no extra keys (`.strict()` schemas) |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale client clock mis-previews the 24 h refund | Spoofing / Tampering of expectation | server computes; toast uses server `refund_amount`; second-tap at confirm |
| Double submit of accept/decline/cancel | Tampering (duplicate money action) | in-flight flags (`isSubmittingReschedule`, `isConfirming`); server atomic status guards and idempotent already-cancelled 200 |
| Server-controlled text rendered with formatting (decline note, expert reschedule note) | Tampering / injection | plain `Text` of a `String` (no markdown/HTML), wrap, no truncation |
| Opening an expert-supplied meeting URL | Spoofing | existing `ExternalMeetingProvider` host hardening for labels; the open itself stays in `MeetingCallViewModel.openExternalLink` (unchanged). `[ASSUMED]` backend validates `meeting_url`; not re-audited here |
| Sensitive text in logs | Information disclosure | no logging of user/server free text |

## Sources

### Primary (HIGH confidence, read this session)
- `.planning/phases/03-booked-sessions-and-joining/03-CONTEXT.md`, `03-UI-SPEC.md`, `.planning/REQUIREMENTS.md`, `STATE.md`, `.planning/IOS-BUG-INVENTORY.md` (rows B6-B17, C3-C10, E13, E15), `02-VERIFICATION.md` (deferrals), Phase 2 summaries (02-14 notes)
- iOS: `Utils/JoinWindow.swift`, `Utils/Money.swift`, `Utils/ReloadGeneration.swift`, `Model/Enums/BookingStatus.swift`, `Model/Responses/ClientBookingDetail.swift`, `ExpertBookingDetail.swift`, `Children/RescheduleProposal.swift`, `Views/Extensions/HomeNavigationPath.swift`, `Views/Screens/Client Mode/{Upcoming Booking Details,Booking Summary,Cancellation,Reschedule,My Bookings,Home}/*`, `Views/Screens/Expert Mode/{Booking Summary,Cancellation,Upcoming Bookings,Home,Expert Dashboard,Reschedule}/*`, `Views/Screens/Call/Calling/*`, `Managers/CallCenter.swift`, `Network/ClickMeAPI+Booking.swift`, `ClickMeAPI+Availability.swift`, `ClickMe2026Tests/Support/*`, `Booking/ClientBookingStatusFallbackTests.swift`, `ClickMe.xcodeproj/project.pbxproj`
- Backend: `src/utils/refund.js`, `src/utils/reschedule.js`, `src/controllers/clientBooking.controller.js` (cancel, getDetail, derivePaymentStatus), `expertBooking.controller.js` (details, cancel), `availability.controller.js`, `src/schemas/booking.schema.js`, `openapi/clickme-api.yaml` (cancelClientBooking, availability, ClientBookingDetail), `docs/SOCKET-CONTRACT.md`
- Android: `screens/clientmode/cancellation/CancellationReason.kt`, `bookingsummary/*`, `upcomingbooking/UpcomingBookingUiState.kt`, `res/values/strings_*.xml`

### Secondary / Tertiary
- None. No web or Context7 lookups were needed; all claims are in-repo. SwiftUI/UIKit API availability statements are `[ASSUMED]` (Assumptions A1, A2).

## Project Constraints (from CLAUDE.md)

- Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`), iOS 18+, Xcode 26; view models/managers `@MainActor`; new shared managers use `@Observable`; match the neighboring view model's observation style.
- Backend is the API contract owner: read the route/schema before changing a call; changes must be additive and safe for the current Android build; one commit per repo per change; say so if another repo needs a change (BOOK-20 needs an Android commit; no backend commit).
- Android mirrors iOS behavior: changes to behavior here usually need an Android counterpart (UI-SPEC already logs the intentional differences: `Accept New Time`, `Pending reschedule`).
- Errors through `Error.userMessage`; branch on `ErrorCode`, never on message text; `@Published var apiError` in new view models; no `try?` for writes; no private `errorMessage(for:)`.
- Endpoint addition pattern: `APIRequestURLs` case, method in `ClickMeAPI+<Feature>.swift`, request/response types under `Model/`. (No new endpoint here; changed signatures only.)
- Swift Testing for unit tests; `@testable import ClickMe2026`; MockURLProtocol for HTTP.
- Dates via `DateUtil`/existing formatters, not new `DateFormatter` instances where a shared one exists (the existing code in the touched VMs creates formatters locally; new code should reuse `DateUtil`).
- Every Swift file starts with the Xcode header block; `// MARK: -` sections; `///` doc comments explain why/contract; `#if DEBUG` for debug logging; `#Preview` bodies not wrapped in `#if DEBUG`.
- Extract new logic into helpers rather than growing ~850-line view models; new folders under `Views/Screens/` keep the spaced naming.
- Definition of done: unit tests where testable, clean `xcodebuild` with no new warnings, device check on a real iPhone via UAT checklist, backend tests only for backend changes (none here).
- GSD workflow: file edits only through a GSD command.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all symbols read from live source; no packages.
- Architecture: HIGH for data flow and backend contract; MEDIUM for on-device SwiftUI behavior (alerts under pushed views, accessibility announcement).
- Pitfalls: HIGH — each traced to a file and line; Pitfalls 1, 2, 8 change plan structure.

**Research date:** 2026-11-10
**Valid until:** 2026-12-10 (stable; invalidated if BACK-19's production smoke finds a problem or the shells are refactored)
