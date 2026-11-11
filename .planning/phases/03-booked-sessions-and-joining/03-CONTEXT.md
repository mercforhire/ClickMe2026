# Phase 3: Booked Sessions and Joining - Context

**Gathered:** 2026-11-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Clients and experts can respond to, cancel, reschedule and join their booked sessions from every screen that offers those actions, and those screens show the booking's real status and the refund the backend will actually give. Requirements: BOOK-06, BOOK-07, BOOK-08, BOOK-09, BOOK-11, BOOK-12, BOOK-13, BOOK-16, BOOK-17, BOOK-20, CALL-03, CALL-06, CALL-07, CALL-08, CALL-10, EXP-11, EXP-13.

iOS repo, with one known cross-repo item: BOOK-20 (booking ID on the client Booking Summary) also changes Android (`../ClickMe_Android`), committed there separately. The backend contract this phase needs (BACK-02 decline note, BACK-12 cancel after end rejected, BACK-14 cancel reason stored, BACK-19 expert-cancel full refund) was delivered in Phase 1. If research finds a backend gap, say so and make the change in the backend repo as a separate commit that stays safe for build 6 and current Android.

BOOK-06 (critical) is planned first. Phase 2's UAT is paused (`02-UAT.md`, status partial, tests 6-17 outstanding); that does not block planning here, but the outstanding device checks must be run before the Phase 8 release.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- **Q2 / refunds (Phase 1 D-17, BACK-19):** an expert-initiated cancel always gives the client a full refund or releases the hold. A client-initiated cancel keeps the 24-hour rule. BACK-19 is deployed (`3899d63`) but its production smoke has not been run; the EXP-11 copy below depends on it being true.
- **Join window (Phase 2 D-07, D-12):** every Join/Open button in this phase uses the shared Phase 2 join-window helper ([start − 60, max(end, start + 60)] plus the server reconnect flag) and the server's joinable statuses. `pending_reschedule` shows Join visible but disabled.
- **Money and status (Phase 2 D-09 to D-11, BOOK-18):** all amounts use the shared minor-units formatter (`CA$45.00`); all statuses use the shared decoder with its neutral unknown fallback.
- **Overtime (Phase 2 D-08):** the end + 60 cutoff and the end + 55 notice stay as they are, on both in-app voice and Skype/Zoom.

### Client answers an expert-proposed reschedule (BOOK-06)
- **D-01:** Add a **reschedule response card to the client Upcoming Booking details screen** (`UpcomingBookingView`), shown while the booking is `pending_reschedule` and the expert is the initiator. It shows the proposed new time and Accept / Decline. It reuses the Booking Summary logic (`BookingSummaryViewModel.acceptReschedule` / decline, the "charges soon" accept disclosure and the payment-method-required recovery path) rather than duplicating it; extract a shared helper if needed. Booking Summary keeps its own Accept/Decline. Endpoints: `POST /client/bookings/{id}/accept-reschedule`, `POST /client/bookings/{id}/decline-reschedule`.
- **D-02:** Decline asks for an **optional reason** (≤ 500 characters, the endpoint's limit), as Booking Summary does today. On success the original time is restored.
- **D-03:** After Accept or Decline succeeds, the client **stays on Upcoming Booking details**. The card disappears, the time and the status pill (BOOK-09) update in place, and a short confirmation is shown. Lists stay in step through the Phase 2 `booking.update` handling.

### Client cancel refund preview (BOOK-08)
- **D-04:** The client cancel screen shows the **exact amount plus the reason**, mirroring the backend's `src/utils/refund.js` (`computeRefundAmountMinorUnits`): a captured booking cancelled strictly more than 24 h before start gets a full refund ("Refund: CA$45.00, cancelled more than 24 hours before the start"); at 24 h or less it gets nothing ("Refund: CA$0.00, the session starts within 24 hours"). A held (uncaptured) booking always reads as a release ("The CA$45.00 hold on your card will be released, so you won't be charged"). Free bookings show no money line.
- **D-05:** For a charged booking inside 24 h (refund 0), the review step shows the amount and reason **prominently in a warning style**. No extra confirmation dialog; the existing final confirm button is the gate.
- **D-06:** The preview is **recomputed at the moment the client confirms**, so crossing the 24 h line while the screen is open is reflected. After the cancel, the success message uses the **server's `refund_amount`** from the cancel response, so the client sees what actually happened. (Note: the cancel can return `refund_amount` 0 while a Stripe void/refund is being retried; research should check how to word that case so it doesn't read as "no refund".)

### Expert cancel copy (EXP-11)
- **D-07:** The expert cancel screen **states the client's amount in the same format as D-04**: "The client will get a full refund of CA$45.00", or "The client's CA$45.00 hold will be released" for a held booking. A free booking shows no money line. Applies to the Booking Summary cancel entry and `ExpertCancellationView`. — **Reversibility:** costly — the copy promises live refund behavior (BACK-19); if BACK-19's smoke finds a problem, both this copy and Android's must change.

### Skype/Zoom session screen and opening it (CALL-06, CALL-07, CALL-08)
- **D-08:** The Skype/Zoom session hero shows the **same timer as the in-app voice layout**: reuse `timerString` (elapsed since the scheduled start) and `remainingLabel` from `MeetingCallViewModel`, so both call types look the same and share one code path.
- **D-09:** The "meeting in progress" status copy **no longer promises an automatic end**: "Meeting in progress. Scheduled to finish at {end}. Tap End Session when you're done." The existing amber banners (ending soon, scheduled time complete, end + 55 notice) stay.
- **D-10:** On Upcoming Booking details, a Skype/Zoom booking inside the join window gets an **Open Meeting button** (with the CALL-09 provider label) that goes through `CallCenter.startCall` into the Skype/Zoom session screen, the same path as the My Bookings card, so the timer, End Session and `/end` reporting work. It does not open the URL directly. The existing link text and Copy stay.

### After a client reschedule request (BOOK-16)
- **D-11:** After the client sends a reschedule request, the app **pops exactly one level, back to wherever Reschedule was tapped** (Upcoming Booking details or the My Bookings card), and shows a **"Reschedule request sent" toast** (Android parity). The status there now reads Pending reschedule (BOOK-09).

### Added during plan-phase (user decisions 2026-11-10)
- **D-13:** Client **Cancel is shown only for `confirmed`, `pending_approval` and `pending_reschedule` bookings, and only while `end > now`** (BOOK-13). This matches the server's cancel guard, so an in-progress or terminal booking never shows a Cancel that returns 409. It supersedes the UI-SPEC's end-time-only rule. Put the rule behind one pure function.
- **D-14:** A booking the card was never charged for uses the **"not charged yet" refund copy**: no refund line (BOOK-08). The signal is the backend's derived boolean `payment_action_required` (from `paymentActionFields` in `src/utils/scaRecovery.js`; card authentication pending), plus `payment_status == "none"`. This applies to the client cancel preview and, by the same rule, the expert cancel refund line (EXP-11). **Fail closed on the expert side:** if the expert details payload does not carry `payment_action_required` (backend not yet deployed), the expert sheet makes no client-refund claim at all rather than falling back to the D-07 full-refund line.
- **D-15:** The **end + 55 "This call will end in 5 minutes" notice also shows on the Skype/Zoom session layout** (resolves UI-SPEC K2; restates Phase 2 D-08, which applies the notice to both in-app voice and Skype/Zoom). Skype/Zoom sessions still end at end + 60.

### Todos
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and inventory
- `.planning/ROADMAP.md` § Phase 3 — goal, success criteria, notes (BOOK-06 first)
- `.planning/REQUIREMENTS.md` — BOOK-06 to BOOK-20, CALL-03/06/07/08/10, EXP-11, EXP-13; BACK-02, BACK-12, BACK-14, BACK-19 status
- `.planning/IOS-BUG-INVENTORY.md` — rows B6, B7, B8, B9, B11, B12, B13, B16, B17, C3, C6, C7, C8, C10, E13, E15 (file:line evidence and the suggested fix for each)
- `.planning/PROJECT.md` — constraints (backend compatibility, one release, definition of done)
- `.planning/phases/01-backend-fixes/01-CONTEXT.md` — D-17 (Q2 refund policy)
- `.planning/phases/02-shared-ios-plumbing/02-CONTEXT.md` — D-07, D-08, D-09 to D-12 (join window, overtime, money, status)

### Backend contract (in `../ClickMe2026 Backend`)
- `openapi/clickme-api.yaml` — `/client/bookings/{id}/accept-reschedule`, `/client/bookings/{id}/decline-reschedule` (reason ≤ 500), `/client/bookings/{id}/reschedule`, `/client/bookings/{id}/cancel` (refund_amount semantics, held vs captured), expert cancel
- `src/utils/refund.js` — `computeRefundAmountMinorUnits`, the 24 h binary rule the client preview mirrors (strictly > 24 h → full; ≤ 24 h → 0)
- `src/controllers/clientBooking.controller.js` — client cancel and reschedule behavior
- `src/controllers/expertBooking.controller.js` — expert cancel full refund (D-17)
- `src/controllers/availability.controller.js` — `exclude_booking_id`
- `docs/ios/CALL-END-SEMANTICS.md` — end + 60 / end + 70 call windows

### iOS code touched
- `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/` — response card, status pill, Join / Open Meeting, Cancel visibility
- `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift`, `BookingSummaryView.swift` — existing Accept/Decline logic to reuse; Leave a Review gate; booking ID
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift` — refund preview, comment
- `ClickMe2026/Views/Screens/Client Mode/Reschedule/RescheduleViewModel.swift` — exclude id, copy, return path
- `ClickMe2026/Views/Screens/Client Mode/My Bookings/MyBookingsView.swift` — navigation (Keep Booking, reschedule return, onJoinCall), Past empty state
- `ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift`, `MeetingCallViewModel.swift`, `Subviews/SkypeSessionHero.swift` — timer and status copy
- `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/`, `Expert Mode/Cancellation/`, `Expert Mode/Upcoming Bookings/`, `Expert Mode/Home/HomeExpertView.swift`, `Expert Mode/Expert Dashboard/ExpertDashboardView.swift` — expert Join, cancel copy, reschedule wiring
- `ClickMe2026/Utils/CallOvertimePolicy.swift` — unchanged; referenced for copy

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BookingSummaryViewModel` accept/decline-reschedule, including the "charges soon" disclosure and the payment-method-required recovery (re-propose with the default saved card) — source for the D-01 card.
- `ExpertBookingSummaryView` decline-with-optional-reason prompt — same UI pattern for D-02.
- Phase 2 shared join-window helper, `CallCenter.startCall`, the money formatter and the status decoder.
- `MeetingCallViewModel.timerString` / `remainingLabel` — reused by the Skype hero (D-08).
- `ExpertRescheduleView` — already reachable from `HomeExpertView.swift` (~L215) for EXP-13.

### Established Patterns
- Per-tab `NavigationPath` with typed routes; pop one level instead of `popToRoot()` for D-11 and BOOK-12. Every new route must be registered on its stack (Phase 2 CR-01).
- Errors go through `Error.userMessage`; branch on `ErrorCode`, never on message text.
- View models are `@MainActor ObservableObject` with `@Published apiError`; extract shared logic instead of growing the ~850-line view models.

### Integration Points
- `MyBookingsView.swift` destinations (`.cancelBooking`, `.rescheduleBooking`) and the callers of `UpcomingBookingView` (`MyBookingsView.swift` ~L108, `HomeClientView.swift` ~L253).
- Expert Upcoming card `onReschedule` default `{ _ in }` (`UpcomingBookingsView.swift` ~L117).

</code_context>

<specifics>
## Specific Ideas

- Refund copy examples (client): "Refund: CA$45.00, cancelled more than 24 hours before the start" / "Refund: CA$0.00, the session starts within 24 hours" / "The CA$45.00 hold on your card will be released, so you won't be charged."
- Refund copy examples (expert): "The client will get a full refund of CA$45.00" / "The client's CA$45.00 hold will be released."
- Skype/Zoom status: "Meeting in progress. Scheduled to finish at 3:15 PM. Tap End Session when you're done."
- Reschedule toast: "Reschedule request sent".

</specifics>

<deferred>
## Deferred Ideas

- Android copy check for the expert-cancel full-refund wording (already logged as a Phase 1 D-17 follow-up).

### Reviewed Todos (not folded)
- `2026-11-08-check-the-android-push-prompt-after-a-reinstall.md`: Android push behavior, not booked sessions.
- `2026-11-08-show-the-suspension-message-on-a-cold-launch.md`: auth, fits Phase 5.
- `2026-11-09-handle-paymentsheet-card-removal-on-the-backend.md`: payments backend, fits Phase 4.

</deferred>

---

*Phase: 03-booked-sessions-and-joining*
*Context gathered: 2026-11-10*
