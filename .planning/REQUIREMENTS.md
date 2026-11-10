# Requirements: ClickMe iOS — Android-Parity Bug Fixes

**Defined:** 2026-11-07
**Core Value:** Live iOS users can book, pay for, join and finish a session without the app cutting them off, charging them wrongly, or silently dropping their actions.

Each requirement cites its inventory ID in brackets. Evidence (file:line), sources and fix notes are in `.planning/IOS-BUG-INVENTORY.md`. Severity: **[crit]**, **[major]**, or minor (unmarked). LIKELY items need a device check first and may be closed as "not reproducible".

**Definition of Done (every requirement):** unit test where the logic is testable · clean `xcodebuild` with no new warnings · device check on a real iPhone via the phase UAT checklist · backend tests for any backend change · backend changes stay compatible with the current Android build.

## v1 Requirements

### Calls

- [x] **CALL-01** [C1] **[crit]**: A call keeps running until 60 minutes after its scheduled end, not 5 minutes (revert the TEMP `overtimeCutoffSeconds`)
- [x] **CALL-02** [C2] **[major]**: User can join a session from 60 minutes before start until its scheduled end, including the second half of sessions longer than an hour
- [ ] **CALL-03** [C3] **[major]**: Tapping Join on the client Upcoming Booking details screen starts the call
- [x] **CALL-04** [C4]: Ending a call with a 0-second leg is accepted by the server (send at least 1 second)
- [x] **CALL-05** [C5] (likely): The call screen reaches the Ended state when the Agora connection fails or is aborted
- [ ] **CALL-06** [C6]: Skype/Zoom status copy no longer promises the meeting ends automatically at the scheduled time
- [ ] **CALL-07** [C7]: The Skype/Zoom session screen shows the elapsed or remaining time
- [ ] **CALL-08** [C8] **[major]**: User can open a Skype/Zoom meeting from the Upcoming Booking details screen
- [x] **CALL-09** [C9]: Skype/Zoom detection matches the real host domain only, so a lookalike URL is not treated as a trusted provider
- [ ] **CALL-10** [C10] **[major]**: Expert can join a session from the expert Booking Summary, within the same join window as CALL-02

### Client Bookings

- [ ] **BOOK-01** [B1] **[major]**: After a booking request is sent, the user cannot go Back to the form and submit it again
- [ ] **BOOK-02** [B2]: Changing month in the booking calendar never shows the previous month's availability
- [ ] **BOOK-03** [B3]: The slots card shows a readable time-zone name, not a raw IANA id
- [ ] **BOOK-04** [B4]: Slot and Today's Sessions times follow the device's locale (12/24-hour)
- [ ] **BOOK-05** [B5]: The Request Sent screen's loading copy reads "Loading booking…"
- [ ] **BOOK-06** [B6] **[crit]**: Client can accept or decline an expert-proposed reschedule from the upcoming-booking flow
- [ ] **BOOK-07** [B7]: The client's cancellation comment is sent with the cancel request (depends on BACK-14 to be stored)
- [ ] **BOOK-08** [B8] **[major]**: The client cancel screen previews the refund the backend will actually give (24-hour rule; a held booking shows as a release) — policy per decision Q2
- [ ] **BOOK-09** [B9]: The Upcoming Booking status pill shows the booking's real status
- [x] **BOOK-10** [B10] **[major]**: Every money amount is shown with correct decimals for its currency (no dropped cents), using one shared formatter
- [ ] **BOOK-11** [B11]: The Past tab shows an empty state when there are no past bookings
- [ ] **BOOK-12** [B12]: Keep Booking returns to the previous screen, not the My Bookings root
- [ ] **BOOK-13** [B13]: Cancel is hidden on a booking whose session has already ended
- [x] **BOOK-14** [B14] **[major]**: Paid booking and reschedule pickers allow slots at most 6 days ahead, and the long-lead error codes show a clear error instead of an invalid confirm
- [ ] **BOOK-15** [B15] **[major]**: Tapping a `booking/payment_actions` push opens that booking (Q3 settled 2026-11-09 as route only, Phase 2 D-01: no recovery flow is built; an unanswered booking is cancelled by scaRecoveryWindowSweep)
- [ ] **BOOK-16** [B16]: The reschedule picker excludes the booking being moved, returns to where the user started with a confirmation, and its copy is correct for held bookings
- [ ] **BOOK-17** [B17]: Leave a Review appears on the Booking Summary only for completed sessions
- [x] **BOOK-18** [B18] **[major]**: A realtime `booking.update` with status `rescheduled` (or any unknown status) is decoded and applied, not dropped
- [ ] **BOOK-19** [B19]: A booking started from Favorites or Search doesn't leave Request Sent stuck on that tab's stack

### Payments

- [ ] **PAY-01** [P1] **[major]**: Closing the payment sheet without tapping pay never places a hold — behavior per decision Q4
- [ ] **PAY-02** [P2] **[major]**: A confirm that times out and is retried sends the user to their pending booking, not "slot taken"
- [ ] **PAY-03** [P3]: The payment lifecycle card describes what actually happened (hold vs charge), including older long-lead bookings
- [ ] **PAY-04** [P5]: The stale `TODO(backend): stripe_account` comments are removed
- [x] **PAY-05** [P6]: Paid and free booking paths show the same slot-taken and meeting-link error copy

### Explore, Profile, Favorites, Reviews

- [ ] **EXPL-01** [X1] **[major]**: An unavailable (404) expert profile shows "This profile isn't available", and network errors show a retry
- [ ] **EXPL-02** [X2] (likely): Empty Expertise, Topics and Reviews sections are hidden, and zero reviews renders cleanly
- [ ] **EXPL-03** [X3]: Featured topic cards show "Free" for free topics
- [ ] **EXPL-04** [X4]: Search result tag pills show their full text
- [ ] **EXPL-05** [X5] **[major]**: Favorites shows all favorites (paged), its empty-state buttons work, its copy is correct, and favorite state comes from the profile's `is_favorite`
- [ ] **EXPL-06** [X6]: The full reviews list loads more than 20 reviews (paging)
- [ ] **EXPL-07** **[major]**: Explore loads when the home feed has a free topic with no currency or one bad featured topic. The free topic shows "Free", a bad topic is dropped alone, a failed load shows readable text, and no stale Featured Topics sit beside section errors

### Signup and Mode Switch

- [ ] **SIGN-01** [S1] **[major]**: Expert cannot publish the profile without a photo
- [ ] **SIGN-02** [S3] **[major]**: Resuming signup keeps the already-verified email state
- [ ] **SIGN-03** [S4]: Expertise tags (and languages) are saved in the order the user tapped them, so the first pick is primary
- [ ] **SIGN-04** [S5]: The country code is normalized on publish
- [ ] **SIGN-05** [S6]: The uploaded photo matches the zoom/crop the user set
- [ ] **SIGN-06** [S7] **[major]**: Switching to Expert mode with incomplete setup opens the setup hub (per decision Q5; pairs with BACK-13)

### Expert Mode

- [ ] **EXP-01** [E1]: Deleting a topic asks for confirmation
- [ ] **EXP-02** [E2] **[major]**: Expert can enter a topic price with decimals (e.g. 12.50) in the topic's currency
- [ ] **EXP-03** [E3] **[major]**: Editing a topic keeps the topic's own currency
- [ ] **EXP-04** [E4]: Expert can clear a topic's icon or description
- [ ] **EXP-05** [E5]: Cancelling the availability time-range picker reverts the change
- [ ] **EXP-06** [E6]: Availability never produces an end time the picker can't show (24:00 displays correctly or is capped)
- [ ] **EXP-07** [E7]: An off-grid stored time (e.g. 09:15) still shows as selected in the picker
- [ ] **EXP-08** [E8]: The stale 409 comment on topic delete is corrected
- [ ] **EXP-09** [E11]: Accepting a request shows the booking-confirmed screen
- [ ] **EXP-10** [E12]: The calendar event created from a confirmed booking is titled with the client's name
- [ ] **EXP-11** [E13] **[major]**: The expert cancel screen states the client's refund correctly — policy per decision Q2
- [ ] **EXP-12** [E14] (likely): Expired request cards stay readable (no 55% dim on text)
- [ ] **EXP-13** [E15] **[major]**: Reschedule on an expert Upcoming card opens the expert reschedule flow
- [ ] **EXP-14** [E16]: The expert-side Client Profile shows real earnings in the booking currency
  - Note (2026-11-10): the Client Profile *history* rows were delivered early in plan 02-15 (Android parity, user decision at the tracer gate): `earnings_breakdown.net_amount` in the breakdown currency, gated to pending_approval / confirmed / pending_reschedule / in_progress / completed, dash otherwise. Device check pending in 02-12. Phase 6 planning should cover any remaining Client Profile earnings surface (for example the relationship summary) rather than redo the history rows.
- [ ] **EXP-15** [E17]: The expert hub online dot reflects real presence, or is removed
- [ ] **EXP-16** [E18]: The private booking note is capped at 5000 characters with a counter, trims whitespace, and asks before discarding edits
- [ ] **EXP-17** [new, user request 2026-11-09]: When creating a topic, the expert can choose its currency from CAD or USD (default CAD), on both iOS and Android; the minimum-price hint and validation follow the chosen currency, and editing keeps the topic's currency. Backend already accepts `hourly_rate.currency` (seeded `currencies` table, per-currency floors in `src/utils/pricing.js`), so no backend change is expected

### Chat

- [ ] **CHAT-01** [H1]: A sent message appears immediately as pending, shows a failed state on error, and can be retried
- [ ] **CHAT-02** [H2]: Chat reports send the report-reason enum values, not display labels
- [ ] **CHAT-03** [H3] **[major]**: A blocked thread hides the composer and shows who blocked it; Unblock appears only to the blocker
- [ ] **CHAT-04** [H4] **[major]**: Blocking from a profile uses a confirm dialog, and the block copy describes what blocking actually does
- [ ] **CHAT-05** [H5]: Typing indicators and View Profile work as soon as a chat opens
- [ ] **CHAT-06** [H6]: Loading earlier messages never duplicates messages
- [ ] **CHAT-07** [H7] **[major]**: Conversation rows show an unread badge (backend increments on send and resets on read; iOS shows the badge)
- [ ] **CHAT-08** [H8] (likely, re-test first per Q8): The "Read" label updates live while the chat is open
- [x] **CHAT-09** [H9]: No foreground push banner appears for the chat currently on screen

### Push

- [x] **PUSH-01** [N1] **[major]**: Tapping any push type opens the right screen, and unknown types open the notifications list (backend `category` for iOS or a wider iOS parser, per decision Q6)
- [x] **PUSH-02** [N2] **[major]**: A push tap switches to the right mode (client/expert) before routing
- [x] **PUSH-03** [N3]: A booking-request push opens that request, not the list
- [ ] **PUSH-04** [N4] **[major]**: After logout, the device stops receiving the old account's pushes (the token is unregistered before auth is cleared)

### Settings, Profile, Account

- [ ] **SET-01** [T1] **[major]**: Language edits on the client (and expert) profile save to the server
- [ ] **SET-02** [T2] **[major]**: Help → Email Us opens a mail to `clickmeapp@uptrendinvestments.net`
- [ ] **SET-03** [T3]: The non-functional Pause Account card is removed from Delete Account
- [ ] **SET-04** [T4]: Opening Notification preferences doesn't send a save before the user changes anything
- [ ] **SET-05** [T5]: Feedback requires at least 10 characters before it can be sent
- [ ] **SET-06** [T6] **[major]**: The Delete Account copy accurately describes what is deleted and what is kept or anonymized
- [ ] **SET-07** [T7]: `CancellationPoliciesView` and `ReadyToStartCallView` are deleted or wired in, per decision Q7

### Backend (in `../ClickMe2026 Backend`, compatible with current Android)

- [x] **BACK-01** [K1]: The accept `message` is delivered to the client (or the iOS field is removed)
- [x] **BACK-02** [K2] **[major]**: The decline note is returned on the client booking detail and notification, and shown in iOS
- [x] **BACK-03** [K3]: Expert booking detail and lists expose whether the client left a review (`has_review`)
- [x] **BACK-04** [K4]: An expert can clear `meeting_url` (null or "")
- [x] **BACK-05** [K5]: `potential_earnings` and `consultation_fee.label` use the booking currency's digits and symbol
- [ ] **BACK-06** [K6]: A lone saved card is made the default *(Pending on purpose: deployed at d356fdc, but the real-card smoke was not run by user decision on 2026-11-08. Do not close until the 01-17 checklist has been run.)*
- [ ] **BACK-07** [K7] **[major]**: A deleted card can no longer be charged through its connected-account clone *(Pending on purpose: deployed at d356fdc, but the real-card smoke was not run by user decision on 2026-11-08. Do not close until the 01-17 checklist has been run.)*
- [ ] **BACK-08** [K8]: A client account is never shown the Stripe tax-ID prompt *(Pending, not delivered: wave 3c dropped by user decision 2026-11-08. Code parked on backend branch `wave-3c`. Needs a new decision.)*
- [x] **BACK-09** [K9]: The join window matches the client rule in CALL-02, and `/bookings/:id/join` checks booking status
- [x] **BACK-10** [K10]: `POST /bookings/request` validates `duration_minutes` and rejects a past `scheduled_start`
- [x] **BACK-11** [K11]: `price_amount` and the tag-replace list have upper bounds
- [x] **BACK-12** [K12]: Client cancel is rejected after the session's end time
- [ ] **BACK-13** [K13] **[major]**: A client is promoted to expert only by an explicit setup call, not any `/expert/*` call *(Pending, not delivered: wave 3c dropped by user decision 2026-11-08. Code parked on backend branch `wave-3c`. Needs a new decision.)*
- [x] **BACK-14** [K14]: The cancel `reason` is stored
- [ ] **BACK-15** [K15]: A confirm retry with the same `booking_attempt_id` replays the original result *(Pending on purpose: deployed and verified with mocked tests; the device retry check with a real hold was deferred to Phase 4 payment UAT, backlog 999.2)*
- [x] **BACK-16** [K16]: `GET /chats` shows empty threads, and `/feedback/submit` is rate-limited (the notification mark-read sub-item was dropped by D-15: NOTIF-07 time-based expiry deliberately has no read state)
- [x] **BACK-17** [N1 backend half]: Push payloads carry the routing fields iOS needs (if decision Q6 picks the backend route)
- [x] **BACK-18** [H7 backend half] **[major]**: Unread counts increment on send and reset on `message.read`
- [ ] **BACK-19** [Q2, D-17] **[major]**: An expert-initiated cancel always gives the client a full refund or releases the hold; a client-initiated cancel keeps the 24-hour rule *(Pending on purpose: deployed at 3899d63, but the production smoke was not run by user decision on 2026-11-08. Do not close until the 01-19 checklist has been run.)*

### Release

- [ ] **REL-01**: Every phase's fixes pass a device UAT checklist on a real iPhone
- [ ] **REL-02**: One new iOS build with all fixes is submitted to TestFlight and the App Store, with backend changes deployed first *(Note 2026-11-08: BACK-08 and BACK-13 are not deployed, because wave 3c was dropped by user decision. Scope unchanged. They need a new decision before release: ship them, or defer them with a reason.)*

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
| S2 optional province, S8 password digit, T8 remember-login-email | By-design differences; move in only if decisions Q1/Q5 say so |
| Hotfix build before the final release | User decision 2026-11-07: one release at the end |

## Traceability

Which phases cover which requirements. Filled in during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CALL-01 | Phase 2 | Complete |
| CALL-02 | Phase 2 | Complete |
| CALL-03 | Phase 3 | Pending |
| CALL-04 | Phase 2 | Complete |
| CALL-05 | Phase 2 | Complete |
| CALL-06 | Phase 3 | Pending |
| CALL-07 | Phase 3 | Pending |
| CALL-08 | Phase 3 | Pending |
| CALL-09 | Phase 2 | Complete |
| CALL-10 | Phase 3 | Pending |
| BOOK-01 | Phase 4 | Pending |
| BOOK-02 | Phase 4 | Pending |
| BOOK-03 | Phase 4 | Pending |
| BOOK-04 | Phase 4 | Pending |
| BOOK-05 | Phase 4 | Pending |
| BOOK-06 | Phase 3 | Pending |
| BOOK-07 | Phase 3 | Pending |
| BOOK-08 | Phase 3 | Pending |
| BOOK-09 | Phase 3 | Pending |
| BOOK-10 | Phase 2 | Complete |
| BOOK-11 | Phase 3 | Pending |
| BOOK-12 | Phase 3 | Pending |
| BOOK-13 | Phase 3 | Pending |
| BOOK-14 | Phase 2 | Complete |
| BOOK-15 | Phase 2 | Pending |
| BOOK-16 | Phase 3 | Pending |
| BOOK-17 | Phase 3 | Pending |
| BOOK-18 | Phase 2 | Complete |
| BOOK-19 | Phase 4 | Pending |
| PAY-01 | Phase 4 | Pending |
| PAY-02 | Phase 4 | Pending |
| PAY-03 | Phase 4 | Pending |
| PAY-04 | Phase 4 | Pending |
| PAY-05 | Phase 2 | Complete |
| EXPL-01 | Phase 4 | Pending |
| EXPL-02 | Phase 4 | Pending |
| EXPL-03 | Phase 4 | Pending |
| EXPL-04 | Phase 4 | Pending |
| EXPL-05 | Phase 4 | Pending |
| EXPL-06 | Phase 4 | Pending |
| EXPL-07 | Phase 4 | Pending |
| SIGN-01 | Phase 5 | Pending |
| SIGN-02 | Phase 5 | Pending |
| SIGN-03 | Phase 5 | Pending |
| SIGN-04 | Phase 5 | Pending |
| SIGN-05 | Phase 5 | Pending |
| SIGN-06 | Phase 5 | Pending |
| EXP-01 | Phase 6 | Pending |
| EXP-02 | Phase 6 | Pending |
| EXP-03 | Phase 6 | Pending |
| EXP-04 | Phase 6 | Pending |
| EXP-05 | Phase 6 | Pending |
| EXP-06 | Phase 6 | Pending |
| EXP-07 | Phase 6 | Pending |
| EXP-08 | Phase 6 | Pending |
| EXP-09 | Phase 6 | Pending |
| EXP-10 | Phase 6 | Pending |
| EXP-11 | Phase 3 | Pending |
| EXP-12 | Phase 6 | Pending |
| EXP-13 | Phase 3 | Pending |
| EXP-14 | Phase 6 | Pending |
| EXP-15 | Phase 6 | Pending |
| EXP-16 | Phase 6 | Pending |
| EXP-17 | Phase 6 | Pending |
| CHAT-01 | Phase 7 | Pending |
| CHAT-02 | Phase 7 | Pending |
| CHAT-03 | Phase 7 | Pending |
| CHAT-04 | Phase 7 | Pending |
| CHAT-05 | Phase 7 | Pending |
| CHAT-06 | Phase 7 | Pending |
| CHAT-07 | Phase 7 | Pending |
| CHAT-08 | Phase 7 | Pending |
| CHAT-09 | Phase 2 | Complete |
| PUSH-01 | Phase 2 | Complete |
| PUSH-02 | Phase 2 | Complete |
| PUSH-03 | Phase 2 | Complete |
| PUSH-04 | Phase 2 | Pending |
| SET-01 | Phase 5 | Pending |
| SET-02 | Phase 5 | Pending |
| SET-03 | Phase 5 | Pending |
| SET-04 | Phase 5 | Pending |
| SET-05 | Phase 5 | Pending |
| SET-06 | Phase 5 | Pending |
| SET-07 | Phase 5 | Pending |
| BACK-01 | Phase 1 | Complete |
| BACK-02 | Phase 1 | Complete |
| BACK-03 | Phase 1 | Complete |
| BACK-04 | Phase 1 | Complete |
| BACK-05 | Phase 1 | Complete |
| BACK-06 | Phase 1 | Pending |
| BACK-07 | Phase 1 | Pending |
| BACK-08 | Phase 1 | Pending |
| BACK-09 | Phase 1 | Complete |
| BACK-10 | Phase 1 | Complete |
| BACK-11 | Phase 1 | Complete |
| BACK-12 | Phase 1 | Complete |
| BACK-13 | Phase 1 | Pending |
| BACK-14 | Phase 1 | Complete |
| BACK-15 | Phase 1 | Pending |
| BACK-16 | Phase 1 | Complete |
| BACK-17 | Phase 1 | Complete |
| BACK-18 | Phase 1 | Complete |
| BACK-19 | Phase 1 | Pending |
| REL-01 | Phase 8 | Pending |
| REL-02 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 105 total
- Mapped to phases: 105
- Unmapped: 0 ✓

---
*Requirements defined: 2026-11-07*
*Last updated: 2026-11-09 — added EXPL-07 (Explore home feed decode, quick 261109-323); stays Pending until a device check*
