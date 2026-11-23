# Requirements: ClickMe iOS — Android-Parity Bug Fixes

**Defined:** 2026-11-07
**Core Value:** Live iOS users can book, pay for, join and finish a session without the app cutting them off, charging them wrongly, or silently dropping their actions.

Each requirement cites its inventory ID in brackets. Evidence (file:line), sources and fix notes are in `.planning/IOS-BUG-INVENTORY.md`. Severity: **[crit]**, **[major]**, or minor (unmarked). LIKELY items need a device check first and may be closed as "not reproducible".

**Definition of Done (every requirement):** unit test where the logic is testable · clean `xcodebuild` with no new warnings · device check on a real iPhone via the phase UAT checklist · backend tests for any backend change · backend changes stay compatible with the current Android build.

## v1 Requirements

### Calls

- [x] **CALL-01** [C1] **[crit]**: A call keeps running until 60 minutes after its scheduled end, not 5 minutes (revert the TEMP `overtimeCutoffSeconds`)
- [x] **CALL-02** [C2] **[major]**: User can join a session from 60 minutes before start until its scheduled end, including the second half of sessions longer than an hour
- [x] **CALL-03** [C3] **[major]**: Tapping Join on the client Upcoming Booking details screen starts the call
- [x] **CALL-04** [C4]: Ending a call with a 0-second leg is accepted by the server (send at least 1 second)
- [x] **CALL-05** [C5] (likely): The call screen reaches the Ended state when the Agora connection fails or is aborted
- [x] **CALL-06** [C6]: Skype/Zoom status copy no longer promises the meeting ends automatically at the scheduled time
- [x] **CALL-07** [C7]: The Skype/Zoom session screen shows the elapsed or remaining time
- [x] **CALL-08** [C8] **[major]**: User can open a Skype/Zoom meeting from the Upcoming Booking details screen
- [x] **CALL-09** [C9]: Skype/Zoom detection matches the real host domain only, so a lookalike URL is not treated as a trusted provider
- [x] **CALL-10** [C10] **[major]**: Expert can join a session from the expert Booking Summary, within the same join window as CALL-02

### Client Bookings

- [x] **BOOK-01** [B1] **[major]**: After a booking request is sent, the user cannot go Back to the form and submit it again *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truths 3 and 4 (code read: BookingRequestSentView hides Back, BookingRequestSentPopGestureLock; the table cites no test suite); swipe-lock device check (04-UAT test 6) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **BOOK-02** [B2]: Changing month in the booking calendar never shows the previous month's availability *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 7 (MakeABookingAvailabilityTests); month-change device check (04-UAT test 8) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **BOOK-03** [B3]: The slots card shows a readable time-zone name, not a raw IANA id *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 8 (SlotTimeFormatTests); zone-name device check (04-UAT test 9) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **BOOK-04** [B4]: Slot and Today's Sessions times follow the device's locale (12/24-hour) *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 8 (SlotTimeFormatTests); 12/24-hour device toggle (04-UAT test 10) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **BOOK-05** [B5]: The Request Sent screen's loading copy reads "Loading booking…" *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 5 (PaymentLifecycleVariantTests); loading and error device check (04-UAT test 7) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **BOOK-06** [B6] **[crit]**: Client can accept or decline an expert-proposed reschedule from the upcoming-booking flow
- [x] **BOOK-07** [B7]: The client's cancellation comment is sent with the cancel request (depends on BACK-14 to be stored)
- [x] **BOOK-08** [B8] **[major]**: The client cancel screen previews the refund the backend will actually give (24-hour rule; a held booking shows as a release) — policy per decision Q2
- [x] **BOOK-09** [B9]: The Upcoming Booking status pill shows the booking's real status
- [x] **BOOK-10** [B10] **[major]**: Every money amount is shown with correct decimals for its currency (no dropped cents), using one shared formatter
- [x] **BOOK-11** [B11]: The Past tab shows an empty state when there are no past bookings
- [x] **BOOK-12** [B12]: Keep Booking returns to the previous screen, not the My Bookings root
- [x] **BOOK-13** [B13]: Cancel is hidden on a booking whose session has already ended
- [x] **BOOK-14** [B14] **[major]**: Paid booking and reschedule pickers allow slots at most 6 days ahead, and the long-lead error codes show a clear error instead of an invalid confirm
- [x] **BOOK-15** [B15] **[major]**: Tapping a `booking/payment_actions` push opens that booking (Q3 settled 2026-11-09 as route only, Phase 2 D-01: no recovery flow is built; an unanswered booking is cancelled by scaRecoveryWindowSweep)
- [x] **BOOK-16** [B16]: The reschedule picker excludes the booking being moved, returns to where the user started with a confirmation, and its copy is correct for held bookings
- [x] **BOOK-17** [B17]: Leave a Review appears on the Booking Summary only for completed sessions
- [x] **BOOK-18** [B18] **[major]**: A realtime `booking.update` with status `rescheduled` (or any unknown status) is decoded and applied, not dropped
- [x] **BOOK-19** [B19]: A booking started from Favorites or Search doesn't leave Request Sent stuck on that tab's stack *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 6 (HomeShellExitTests); source-tab exit device check (04-UAT test 6) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **BOOK-20** [new, user request 2026-11-10]: The client Booking Summary screen shows the booking ID, on both iOS and Android, in the same short-ID format as Upcoming Booking details (`ID: …`). Android has no ID on this screen today either, so both apps change

### Payments

- [x] **PAY-01** [P1] **[major]**: Closing the payment sheet without tapping pay never places a hold — behavior per decision Q4 *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 1 (code read: MakeABookingStripePaymentSheet, PaymentSheetOutcome; the table cites no test suite); 04-UAT test 1 pass (D-11 step a, sheet close places no hold, 2026-11-12); 08-19-SUMMARY: no code finding)*
- [x] **PAY-02** [P2] **[major]**: A confirm that times out and is retried sends the user to their pending booking, not "slot taken" *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED in code and unit tests, truths 2 and 19 (MakeABookingPaidFlowTests); 04-UAT test 1 pass (D-11 step d, timed-out confirm plus Try again landed on one booking and one hold, 2026-11-12); form-lock taps (truth 19) not run on device; covered by unit tests plus regression (D-01); R1 recorded no confirm timeout, so no regression item is cited (D-08); 08-19-SUMMARY: no code finding; 3DS retry (04-UAT test 2) not run on device; covered by unit tests only (user decision 2026-11-19): MakeABookingPaidFlowTests, The 3DS retry sends the topic and slot the payment was made for; A 3DS retry with no card left ends the attempt and sends no second confirm)*
- [x] **PAY-03** [P3]: The payment lifecycle card describes what actually happened (hold vs charge), including older long-lead bookings *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 5 (PaymentLifecycleVariantTests); hold-card device check (04-UAT test 11) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **PAY-04** [P5]: The stale `TODO(backend): stripe_account` comments are removed *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 18 (grep for TODO(backend) returns 0; the table cites no test suite); 08-19-SUMMARY: no code finding)*
- [x] **PAY-05** [P6]: Paid and free booking paths show the same slot-taken and meeting-link error copy

### Explore, Profile, Favorites, Reviews

- [x] **EXPL-01** [X1] **[major]**: An unavailable (404) expert profile shows "This profile isn't available", and network errors show a retry *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 9 (code read: ExpertProfileViewModel 404 mapping; the table cites no test suite; its WR-02 caveat is superseded by WR-09, fixed in aed0c22, 04-REVIEW-DISPOSITION.md); load-error device check (04-UAT test 12) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **EXPL-02** [X2] (likely): Empty Expertise, Topics and Reviews sections are hidden, and zero reviews renders cleanly *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED in code, truth 10 (ExpertProfileSectionsTests); empty-sections device check (04-UAT test 13) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **EXPL-03** [X3]: Featured topic cards show "Free" for free topics *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 11 (ClientHomeFeedTests price rows); 04-UAT test 4 pass (2026-11-12); 08-19-SUMMARY: no code finding)*
- [x] **EXPL-04** [X4]: Search result tag pills show their full text *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 12 (TopicsSetupFlowLayoutTests); tag-pill device check (04-UAT test 14) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **EXPL-05** [X5] **[major]**: Favorites shows all favorites (paged), its empty-state buttons work, its copy is correct, and favorite state comes from the profile's `is_favorite` *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truths 13 and 14 (the paging tests: FavoritesViewModelPagingTests; its WR-05 caveat is superseded by WR-11, fixed in 753da57, 04-REVIEW-DISPOSITION.md); Favorites device check (04-UAT test 15) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **EXPL-06** [X6]: The full reviews list loads more than 20 reviews (paging) *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md SATISFIED, truth 15 (the paging tests: ExpertReviewsViewModelPagingTests); reviews-paging device check (04-UAT test 16) not run on device; covered by unit tests plus regression (D-01); 08-19-SUMMARY: no code finding)*
- [x] **EXPL-07** **[major]**: Explore loads when the home feed has a free topic with no currency or one bad featured topic. The free topic shows "Free", a bad topic is dropped alone, a failed load shows readable text, and no stale Featured Topics sit beside section errors *(Closed in Phase 8 under D-01, 2026-11-23: 04-VERIFICATION.md NEEDS HUMAN only for the device re-test, truths 16, 20 and 21 (ClientHomeFeedTests); 04-UAT test 5 pass (G-04-3 pull-to-refresh re-test, 2026-11-13), which resolves test 3's issue (gap G-04-3 resolved by 04-17); 08-19-SUMMARY: no code finding)*

### Signup and Mode Switch

- [x] **SIGN-01** [S1] **[major]**: Expert cannot publish the profile without a photo
- [x] **SIGN-02** [S3] **[major]**: Resuming signup keeps the already-verified email state
- [x] **SIGN-03** [S4]: Expertise tags (and languages) are saved in the order the user tapped them, so the first pick is primary
- [x] **SIGN-04** [S5]: The country code is normalized on publish
- [x] **SIGN-05** [S6]: The uploaded photo matches the zoom/crop the user set
- [x] **SIGN-06** [S7] **[major]**: Switching to Expert mode with incomplete setup opens the setup hub (per decision Q5; pairs with BACK-13)

### Expert Mode

- [x] **EXP-01** [E1]: Deleting a topic asks for confirmation
- [x] **EXP-02** [E2] **[major]**: Expert can enter a topic price with decimals (e.g. 12.50) in the topic's currency
- [x] **EXP-03** [E3] **[major]**: Editing a topic keeps the topic's own currency
- [x] **EXP-04** [E4]: Expert can clear a topic's icon or description
- [x] **EXP-05** [E5]: Cancelling the availability time-range picker reverts the change
- [x] **EXP-06** [E6]: Availability never produces an end time the picker can't show (24:00 displays correctly or is capped)
- [x] **EXP-07** [E7]: An off-grid stored time (e.g. 09:15) still shows as selected in the picker
- [x] **EXP-08** [E8]: The stale 409 comment on topic delete is corrected
- [x] **EXP-09** [E11]: Accepting a request shows the booking-confirmed screen
- [x] **EXP-10** [E12]: The calendar event created from a confirmed booking is titled with the client's name
- [x] **EXP-11** [E13] **[major]**: The expert cancel screen states the client's refund correctly — policy per decision Q2
- [x] **EXP-12** [E14] (likely): Expired request cards stay readable (no 55% dim on text)
- [x] **EXP-13** [E15] **[major]**: Reschedule on an expert Upcoming card opens the expert reschedule flow
- [x] **EXP-14** [E16]: The expert-side Client Profile shows real earnings in the booking currency
  - Note (2026-11-10): the Client Profile *history* rows were delivered early in plan 02-15 (Android parity, user decision at the tracer gate): `earnings_breakdown.net_amount` in the breakdown currency, gated to pending_approval / confirmed / pending_reschedule / in_progress / completed, dash otherwise. Device check pending in 02-12. Phase 6 planning should cover any remaining Client Profile earnings surface (for example the relationship summary) rather than redo the history rows.
- [x] **EXP-15** [E17]: The expert hub online dot reflects real presence, or is removed
- [x] **EXP-16** [E18]: The private booking note is capped at 5000 characters with a counter, saves whitespace-only text as empty (other text is sent as typed), and asks before discarding unsaved edits
  - Note (2026-11-16): reworded from "trims whitespace" by user decision during Phase 6 planning, to match 06-CONTEXT D-19 (Android 16.4 D-01 to D-04). The behaviour planned in 06-07 is unchanged.
- [x] **EXP-17** [new, user request 2026-11-09]: When creating a topic, the expert can choose its currency from CAD or USD (default CAD), on both iOS and Android; the minimum-price hint and validation follow the chosen currency, and editing keeps the topic's currency. Backend already accepts `hourly_rate.currency` (seeded `currencies` table, per-currency floors in `src/utils/pricing.js`), so no backend change is expected
- [x] **EXP-18** [new, user request 2026-11-10]: The expert Booking Summary screen shows the booking ID, on both iOS and Android. Android already shows `ID: #…` (`expert_summary_id`, `ExpertSummaryCard.kt`); iOS adds it in the same format, and Android is checked to match the client screen's short-ID rule (BOOK-20)

### Chat

- [x] **CHAT-01** [H1]: A sent message appears immediately as pending, shows a failed state on error, and can be retried
- [x] **CHAT-02** [H2]: Chat reports send the report-reason enum values, not display labels
- [x] **CHAT-03** [H3] **[major]**: A blocked thread hides the composer and shows who blocked it; Unblock appears only to the blocker
- [x] **CHAT-04** [H4] **[major]**: Blocking from a profile uses a confirm dialog, and the block copy describes what blocking actually does
- [x] **CHAT-05** [H5]: Typing indicators and View Profile work as soon as a chat opens
- [x] **CHAT-06** [H6]: Loading earlier messages never duplicates messages
- [x] **CHAT-07** [H7] **[major]**: Conversation rows show an unread badge (backend increments on send and resets on read; iOS shows the badge)
- [x] **CHAT-08** [H8] (likely, re-test first per Q8): The "Read" label updates live while the chat is open *(Closed as not reproducible 2026-11-17: the user's device re-test after Phase 1 shipped showed the live Read label working (Q8, 07-CONTEXT D-17). No CHAT-08 fix was made: the sender-side Read handler (ChattingViewModel.handleMessageRead) is byte-identical to the phase base. Two Phase 7 changes sit next to that path: plan 07-01 keeps an own Read bubble from reverting on reload, and plan 07-03 changes when the receiving side emits message.read (D-16, for CHAT-07). Regression row in item C6 of 07-DEVICE-UAT-CHECKLIST.md. The box is left for /gsd-verify-work 07.)*
- [x] **CHAT-09** [H9]: No foreground push banner appears for the chat currently on screen

### Push

- [x] **PUSH-01** [N1] **[major]**: Tapping any push type opens the right screen, and unknown types open the notifications list (backend `category` for iOS or a wider iOS parser, per decision Q6)
- [x] **PUSH-02** [N2] **[major]**: A push tap switches to the right mode (client/expert) before routing
- [x] **PUSH-03** [N3]: A booking-request push opens that request, not the list
- [x] **PUSH-04** [N4] **[major]**: After logout, the device stops receiving the old account's pushes (the token is unregistered before auth is cleared)

### Settings, Profile, Account

- [x] **SET-01** [T1] **[major]**: Language edits on the client (and expert) profile save to the server
- [x] **SET-02** [T2] **[major]**: Help → Email Us opens a mail to `clickmeapp@uptrendinvestments.net`
- [x] **SET-03** [T3]: The non-functional Pause Account card is removed from Delete Account
- [x] **SET-04** [T4]: Opening Notification preferences doesn't send a save before the user changes anything
- [x] **SET-05** [T5]: Feedback requires at least 10 characters before it can be sent
- [x] **SET-06** [T6] **[major]**: The Delete Account copy accurately describes what is deleted and what is kept or anonymized
- [x] **SET-07** [T7]: `CancellationPoliciesView` and `ReadyToStartCallView` are deleted or wired in, per decision Q7

### Backend (in `../ClickMe2026 Backend`, compatible with current Android)

- [x] **BACK-01** [K1]: The accept `message` is delivered to the client (or the iOS field is removed)
- [x] **BACK-02** [K2] **[major]**: The decline note is returned on the client booking detail and notification, and shown in iOS
- [x] **BACK-03** [K3]: Expert booking detail and lists expose whether the client left a review (`has_review`)
- [x] **BACK-04** [K4]: An expert can clear `meeting_url` (null or "")
- [x] **BACK-05** [K5]: `potential_earnings` and `consultation_fee.label` use the booking currency's digits and symbol
- [x] **BACK-06** [K6]: A lone saved card is made the default *(Closed by the Phase 8 regression (08-REGRESSION-CHECKLIST.md R4, 2026-11-23))*
- [x] **BACK-07** [K7] **[major]**: A deleted card can no longer be charged through its connected-account clone *(Closed by the Phase 8 regression (08-REGRESSION-CHECKLIST.md R5, 2026-11-23))*
- [ ] **BACK-08** [K8]: A client account is never shown the Stripe tax-ID prompt *(Pending, not delivered: wave 3c dropped by user decision 2026-11-08. Code parked on backend branch `wave-3c`. BACK-08 is deferred past this release (D-07): its gate returns 403 on `GET /expert/tax-profile` for client-only accounts, and it ships with BACK-13 once build 6 and the current Android build no longer rely on implicit promotion; the reason is recorded under REL-02. Checkbox stays unticked.)*
- [x] **BACK-09** [K9]: The join window matches the client rule in CALL-02, and `/bookings/:id/join` checks booking status
- [x] **BACK-10** [K10]: `POST /bookings/request` validates `duration_minutes` and rejects a past `scheduled_start`
- [x] **BACK-11** [K11]: `price_amount` and the tag-replace list have upper bounds
- [x] **BACK-12** [K12]: Client cancel is rejected after the session's end time
- [ ] **BACK-13** [K13] **[major]**: A client is promoted to expert only by an explicit setup call, not any `/expert/*` call *(Deferred past this release by Phase 5 decision D-04, 2026-11-13; wave 3c was dropped by user decision 2026-11-08. The iOS Expert-mode gate (SIGN-06, plans 05-07, 05-10, 05-12 and 05-16) fixes the user-facing bug. The code stays parked on backend branch `wave-3c`. It can ship once App Store build 6 and the current Android build no longer rely on implicit promotion; the reason is recorded under REL-02. Checkbox stays unticked.)*
- [x] **BACK-14** [K14]: The cancel `reason` is stored
- [x] **BACK-15** [K15]: A confirm retry with the same `booking_attempt_id` replays the original result *(Closed on mock and unit-test evidence (Phase 8 D-08): a phone cannot force a same booking_attempt_id retry)*
- [x] **BACK-16** [K16]: `GET /chats` shows empty threads, and `/feedback/submit` is rate-limited (the notification mark-read sub-item was dropped by D-15: NOTIF-07 time-based expiry deliberately has no read state)
- [x] **BACK-17** [N1 backend half]: Push payloads carry the routing fields iOS needs (if decision Q6 picks the backend route)
- [x] **BACK-18** [H7 backend half] **[major]**: Unread counts increment on send and reset on `message.read`
- [x] **BACK-19** [Q2, D-17] **[major]**: An expert-initiated cancel always gives the client a full refund or releases the hold; a client-initiated cancel keeps the 24-hour rule *(Closed by the Phase 8 regression (08-REGRESSION-CHECKLIST.md R6, 2026-11-23); hold release on a device; captured refund on mocked tests, D-27)*

### Release

- [x] **REL-01**: Every phase's fixes are verified on a real iPhone: device UAT checklists where they were run, and for the items never run on a device (Phase 3 checklist items 7-24, Phase 4's skipped UAT tests) unit tests and code review plus one TestFlight regression run of the core paths (D-01, user-approved amendment 2026-11-19); VoiceOver steps are removed and untested (D-02) *(Closed in Phase 8 plan 08-24, 2026-11-23, as amended by D-01: the one TestFlight regression run on 1.1 (7) was signed off 2026-11-23, "Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)" (08-REGRESSION-CHECKLIST.md, 08-RELEASE-RECORD.md ## Regression results). R1's end + 10, end + 55, end + 60 steps and the whole of R2 were waived by the user (D-33, 2026-11-23) and rest on CallOvertimePolicyTests; the items never run on a device are listed in 08-RELEASE-RECORD.md ## Not run on device (D-01) and the VoiceOver steps under ## Removed and untested (D-02), never as passed)*
- [x] **REL-02**: One new iOS build with all fixes is submitted to TestFlight and the App Store, with backend changes deployed first *(Note 2026-11-08: BACK-08 and BACK-13 are not deployed, because wave 3c was dropped by user decision. Scope unchanged. Update 2026-11-13: BACK-13 is deferred past this release (Phase 5 decision D-04). Reason: App Store build 6 and the current Android build rely on `ensureExpert`'s implicit client-to-expert promotion, so the explicit-promotion change would leave those clients unable to become experts. BACK-08 still needs a new decision before release: ship it, or defer it with a reason. Update (Phase 8): BACK-08 is deferred past this release (D-07). Reason: its gate returns 403 on `GET /expert/tax-profile` for client-only accounts, and it ships with BACK-13 once build 6 and the current Android build no longer rely on implicit promotion. The code stays parked on backend branch `wave-3c`.)* *(Closed in Phase 8 plan 08-24, 2026-11-23: build 1.1 (7) from `1fdcc26` (tag `v1.1`) went to internal TestFlight through the "Deploy to TestFlight" workflow (08-20) and was submitted for App Review on 2026-11-23 18:41 EST, status Waiting for Review (08-23, 08-RELEASE-RECORD.md ## Submission). Backend deploys X1 (`412f1aa`, 2026-11-20) and X2 (`1d18aac`, 2026-11-22) were live before the cut, and production /health read `1d18aac` at the pre-submission gate. BACK-08 and BACK-13 stay deferred (D-07).)*

## v2 Requirements

Deferred. Tracked but not in the current roadmap.

- **PORT-01** [D1]: Private note on Upcoming Booking Details (product request, both apps)
- **PORT-02** [D2]: Booking ID on Payment History and expert list rows
- **PORT-03** [D3]: Android's loading standard (skeletons, inline error + Retry, refresh-failed snackbar)
- **PORT-04** [D4]: Optimistic favorite heart with rollback and confirm-before-remove
- **PORT-05** [D8]: My Bookings paging beyond 20 per bucket (both apps)
- **PORT-06** [P4]: Toast when 3DS is cancelled

## Out of Scope

| Feature | Reason |
|---------|--------|
| Android code changes | Separate project; backend changes stay compatible and Android follow-ups are logged instead |
| D5, D6, D7, D9 Android deviations | Overlap other fixes (B19) or are intentional product choices already settled |
| P7, E9, E10, T9 | Already fixed |
| P8, P9 | By design (debug-only token; production environment is intended for release) |
| S2 optional province, S8 password digit, T8 remember-login-email | By-design differences; move in only if decisions Q1/Q5 say so. Moved in by Phase 5: S2 (D-05 to D-07) and T8 (D-14). S8 stays out by design |
| Hotfix build before the final release | User decision 2026-11-07: one release at the end |

## Traceability

Which phases cover which requirements. Filled in during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CALL-01 | Phase 2 | Complete |
| CALL-02 | Phase 2 | Complete |
| CALL-03 | Phase 3 | Complete |
| CALL-04 | Phase 2 | Complete |
| CALL-05 | Phase 2 | Complete |
| CALL-06 | Phase 3 | Complete |
| CALL-07 | Phase 3 | Complete |
| CALL-08 | Phase 3 | Complete |
| CALL-09 | Phase 2 | Complete |
| CALL-10 | Phase 3 | Complete |
| BOOK-01 | Phase 4 | Complete |
| BOOK-02 | Phase 4 | Complete |
| BOOK-03 | Phase 4 | Complete |
| BOOK-04 | Phase 4 | Complete |
| BOOK-05 | Phase 4 | Complete |
| BOOK-06 | Phase 3 | Complete |
| BOOK-07 | Phase 3 | Complete |
| BOOK-08 | Phase 3 | Complete |
| BOOK-09 | Phase 3 | Complete |
| BOOK-10 | Phase 2 | Complete |
| BOOK-11 | Phase 3 | Complete |
| BOOK-12 | Phase 3 | Complete |
| BOOK-13 | Phase 3 | Complete |
| BOOK-14 | Phase 2 | Complete |
| BOOK-15 | Phase 2 | Complete |
| BOOK-16 | Phase 3 | Complete |
| BOOK-17 | Phase 3 | Complete |
| BOOK-18 | Phase 2 | Complete |
| BOOK-19 | Phase 4 | Complete |
| BOOK-20 | Phase 3 | Complete |
| PAY-01 | Phase 4 | Complete |
| PAY-02 | Phase 4 | Complete |
| PAY-03 | Phase 4 | Complete |
| PAY-04 | Phase 4 | Complete |
| PAY-05 | Phase 2 | Complete |
| EXPL-01 | Phase 4 | Complete |
| EXPL-02 | Phase 4 | Complete |
| EXPL-03 | Phase 4 | Complete |
| EXPL-04 | Phase 4 | Complete |
| EXPL-05 | Phase 4 | Complete |
| EXPL-06 | Phase 4 | Complete |
| EXPL-07 | Phase 4 | Complete |
| SIGN-01 | Phase 5 | Complete |
| SIGN-02 | Phase 5 | Complete |
| SIGN-03 | Phase 5 | Complete |
| SIGN-04 | Phase 5 | Complete |
| SIGN-05 | Phase 5 | Complete |
| SIGN-06 | Phase 5 | Complete |
| EXP-01 | Phase 6 | Complete |
| EXP-02 | Phase 6 | Complete |
| EXP-03 | Phase 6 | Complete |
| EXP-04 | Phase 6 | Complete |
| EXP-05 | Phase 6 | Complete |
| EXP-06 | Phase 6 | Complete |
| EXP-07 | Phase 6 | Complete |
| EXP-08 | Phase 6 | Complete |
| EXP-09 | Phase 6 | Complete |
| EXP-10 | Phase 6 | Complete |
| EXP-11 | Phase 3 | Complete |
| EXP-12 | Phase 6 | Complete |
| EXP-13 | Phase 3 | Complete |
| EXP-14 | Phase 6 | Complete |
| EXP-15 | Phase 6 | Complete |
| EXP-16 | Phase 6 | Complete |
| EXP-17 | Phase 6 | Complete |
| EXP-18 | Phase 6 | Complete |
| CHAT-01 | Phase 7 | Complete |
| CHAT-02 | Phase 7 | Complete |
| CHAT-03 | Phase 7 | Complete |
| CHAT-04 | Phase 7 | Complete |
| CHAT-05 | Phase 7 | Complete |
| CHAT-06 | Phase 7 | Complete |
| CHAT-07 | Phase 7 | Complete |
| CHAT-08 | Phase 7 | Complete |
| CHAT-09 | Phase 2 | Complete |
| PUSH-01 | Phase 2 | Complete |
| PUSH-02 | Phase 2 | Complete |
| PUSH-03 | Phase 2 | Complete |
| PUSH-04 | Phase 2 | Complete |
| SET-01 | Phase 5 | Complete |
| SET-02 | Phase 5 | Complete |
| SET-03 | Phase 5 | Complete |
| SET-04 | Phase 5 | Complete |
| SET-05 | Phase 5 | Complete |
| SET-06 | Phase 5 | Complete |
| SET-07 | Phase 5 | Complete |
| BACK-01 | Phase 1 | Complete |
| BACK-02 | Phase 1 | Complete |
| BACK-03 | Phase 1 | Complete |
| BACK-04 | Phase 1 | Complete |
| BACK-05 | Phase 1 | Complete |
| BACK-06 | Phase 1 | Complete |
| BACK-07 | Phase 1 | Complete |
| BACK-08 | Phase 1 | Pending |
| BACK-09 | Phase 1 | Complete |
| BACK-10 | Phase 1 | Complete |
| BACK-11 | Phase 1 | Complete |
| BACK-12 | Phase 1 | Complete |
| BACK-13 | Phase 1 | Pending |
| BACK-14 | Phase 1 | Complete |
| BACK-15 | Phase 1 | Complete |
| BACK-16 | Phase 1 | Complete |
| BACK-17 | Phase 1 | Complete |
| BACK-18 | Phase 1 | Complete |
| BACK-19 | Phase 1 | Complete |
| REL-01 | Phase 8 | Complete |
| REL-02 | Phase 8 | Complete |

**Coverage:**
- v1 requirements: 107 total
- Mapped to phases: 107
- Unmapped: 0 ✓

---
*Requirements defined: 2026-11-07*
*Last updated: 2026-11-23 — Phase 8 plan 08-24: REL-01 closed on the signed-off regression (D-01, D-33) and REL-02 on the 1.1 (7) submission (Waiting for Review); BACK-08 and BACK-13 stay deferred (D-07). Previous: 2026-11-23 — Phase 8 plan 08-22: BACK-06, BACK-07 and BACK-19 closed on the signed-off 1.1 (7) regression (R4, R5, R6; D-06, D-27); the 17 Phase 4 rows closed under D-01 on their 04-VERIFICATION.md evidence (PAY-02's 3DS retry on unit tests only, user decision 2026-11-19); R1 overtime and R2 waived (D-33). Previous: 2026-11-22 — Phase 8 plan 08-15: REL-01 amended (D-01, user-approved 2026-11-19; VoiceOver removed per D-02); BACK-08 deferral reason recorded (D-07); BACK-15 closed on mock and unit-test evidence (D-08); BACK-19, BACK-06 and BACK-07 closing conditions set to the Phase 8 regression evidence (D-27, D-06). Previous: 2026-11-16 — Phase 6 planning: EXP-16 reworded to match 06-CONTEXT D-19 (user decision). Previous: 2026-11-13 — Phase 5: BACK-13 deferred past this release (D-04, reason under REL-02); S2 and T8 moved in (D-05 to D-07, D-14)*
