# Roadmap: ClickMe iOS — Android-Parity Bug Fixes

## Overview

This project fixes every confirmed and likely iOS bug that the Android port found, plus the backend issues behind them, and ships one new iOS build at the end. The work runs in horizontal layers, as the user chose. Backend fixes come first, in the separate backend repo and compatible with the current Android build. Next comes the shared iOS plumbing that many screens depend on: call timing and join windows, one money formatter, booking-status decoding, error-code mapping and the push pipeline. The critical 5-minute call cutoff (CALL-01) is the first item in that layer. Then come the screen-level fixes, grouped by area. Booked sessions and joining go first, because that group holds the critical reschedule response (BOOK-06) and the most majors. The project ends with a single release.

## Rules for Every Phase

**Definition of done:** unit tests where the logic is testable, a clean `xcodebuild` with no new warnings, a device check on a real iPhone using the phase UAT checklist, and backend tests for any backend change.

**Cross-repo:** backend changes are made and committed in `../ClickMe2026 Backend`, one commit per repo per change. Check the backend contract (`openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md`, `src/routes`, `src/schemas`) before changing `Network/` or `Model/`. Never assume another repo already has a change. Android follow-ups are logged instead of built.

**Open product decisions:** each one is settled in the discuss step of the phase it affects:

| Decision | Affects | Settled in |
|----------|---------|------------|
| Q1 Merge remember-login-email? | T8 (out of scope unless moved in) | Phase 5 |
| Q2 Expert cancel: full refund or the 24 h rule? | BOOK-08, EXP-11 | Phase 1 (D-17) |
| Q3 Long-lead SCA recovery, or route the push only? | BOOK-15 | Phase 2 (settled 2026-11-09: route only, D-01) |
| Q4 Dismissed payment sheet with a preselected card: cancel or confirm? | PAY-01 | Phase 4 |
| Q5 Optional province, and a gated Expert-mode switch? | SIGN-06 (S2 out of scope unless moved in) | Phase 5 |
| Q6 Fix dead pushes with a backend `category` or a wider iOS parser? | BACK-17, PUSH-01 | Phase 1 |
| Q7 Delete or wire in the dead screens? | SET-07 | Phase 5 |
| Q8 Re-test the "Read" label on a device | CHAT-08 | Phase 7 (re-test before planning) |

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Backend Fixes** - Production backend validates, stores and returns what the iOS fixes need, without breaking current Android (completed 2026-11-09)
- [ ] **Phase 2: Shared iOS Plumbing** - Call timing, join window, money formatting, status decoding, error codes and push routing are correct in one place
- [ ] **Phase 3: Booked Sessions and Joining** - Clients and experts can respond to, cancel, reschedule and join booked sessions from every screen that offers it
- [ ] **Phase 4: Booking, Payment and Discovery** - Clients can find an expert, book and pay without resubmits, unintended holds or misleading errors
- [ ] **Phase 5: Signup, Mode Switch and Account** - Signup, becoming an expert and account settings save correctly and tell the truth
- [ ] **Phase 6: Expert Mode** - Experts can price, schedule and run their bookings without wrong amounts or dead ends
- [ ] **Phase 7: Chat** - Messages, block state, unread and read state behave reliably and clearly
- [ ] **Phase 8: Release** - One verified iOS build ships to TestFlight and the App Store after the backend is live

## Phase Details

### Phase 1: Backend Fixes

**Goal**: The production backend validates, stores and returns everything the iOS fixes depend on, and every change stays safe for the current Android build
**Depends on**: Nothing (first phase)
**Requirements**: BACK-01, BACK-02, BACK-03, BACK-04, BACK-05, BACK-06, BACK-07, BACK-08, BACK-09, BACK-10, BACK-11, BACK-12, BACK-13, BACK-14, BACK-15, BACK-16, BACK-17, BACK-18, BACK-19
**Success Criteria** (what must be TRUE):
  1. Booking requests, cancels, confirms and joins are validated and recorded. A past `scheduled_start` or an invalid `duration_minutes` is rejected, and so is a client cancel after the session's end. The cancel `reason` is saved on the booking. A confirm retry with the same `booking_attempt_id` returns the original result instead of SLOT_UNAVAILABLE. `/bookings/:id/join` enforces the agreed join window and checks booking status.
  2. Saved cards behave safely on live Stripe. A lone saved card becomes the default, a deleted card can no longer be charged through its connected-account clone, and a client account is never shown the tax-ID prompt. An expert-initiated cancel always refunds the client in full or releases the hold (BACK-19, D-17).
  3. Booking and expert data is complete and correct: the client receives the decline note and the accept message (or the accept field is dropped by decision); expert booking detail and lists include `has_review`; `potential_earnings` and `consultation_fee.label` use the booking currency's digits and symbol; an expert can clear `meeting_url`; oversized `price_amount` and tag lists get a 4xx instead of a 500; and a client becomes an expert only through an explicit setup call.
  4. Chat and push data is correct: sending a message increments the recipient's unread count and `message.read` resets it, `GET /chats` lists empty threads, and `/feedback/submit` is rate-limited. Push payloads carry `category`, `sub_category` and a per-recipient `target_role` for iOS and Android alike (Q6 settled as the backend route, D-01/D-02).
  5. Every change has backend tests. The current Android build and the live iOS build 6 can still sign in, book, pay, join and chat against the updated backend.

**Plans**: 26/26 plans complete (sequential; deploy waves 1, 2, 3a, 3b, 3c each end with a user push checkpoint; 01-24 to 01-26 close the BACK-19 refund retry gap with their own push checkpoint)

Plans:
**Wave 1**
- [x] 01-01-PLAN.md — Tracer BACK-04 (clear meeting_url), D-12 response-shape lock, requirements/roadmap sync for D-15/D-17

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 01-02-PLAN.md — BACK-17 push routing fields for every platform plus target_role and in_app_meta (push.js, events.js, pushTargetRole helpers)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 01-03-PLAN.md — BACK-17 target_role on chat, review, payment-action and reminder pushes

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 01-04-PLAN.md — BACK-17 target_role on no-show, review-nudge, long-lead and account-level pushes (D-02 at every call site)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 01-05-PLAN.md — BACK-03 has_review; BACK-05 currency symbol and digits

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 01-06-PLAN.md — BACK-02 decline note on client detail, in-app notification and chat event

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 01-07-PLAN.md — BACK-10 free-request validation; BACK-11 price and list bounds

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 01-08-PLAN.md — BACK-16 empty threads listed; feedback rate limit

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 01-09-PLAN.md — BACK-01 accept message posted as a chat message (shared postUserMessage)

**Wave 10** *(blocked on Wave 9 completion)*
- [x] 01-10-PLAN.md — Deploy wave 1 handoff; BACK-14 migration applied first (checkpoint)

**Wave 11** *(blocked on Wave 10 completion)*
- [x] 01-11-PLAN.md — BACK-09 two-tier join gate, status check, can_join, overtime /end

**Wave 12** *(blocked on Wave 11 completion)*
- [x] 01-12-PLAN.md — BACK-14 cancel reason stored; BACK-12 client cancel after end rejected

**Wave 13** *(blocked on Wave 12 completion)*
- [x] 01-13-PLAN.md — BACK-15 ownership-checked confirm replay; payment-intent own-booking 409

**Wave 14** *(blocked on Wave 13 completion)*
- [x] 01-14-PLAN.md — BACK-18 unread counts recomputed on send, read and thread open

**Wave 15** *(blocked on Wave 14 completion)*
- [x] 01-15-PLAN.md — Deploy wave 2 handoff (checkpoint)

**Wave 16** *(blocked on Wave 15 completion)*
- [x] 01-16-PLAN.md — BACK-06 lone-card default; BACK-07 in-use 409 and clone eviction

**Wave 17** *(blocked on Wave 16 completion)*
- [x] 01-17-PLAN.md — Deploy wave 3a handoff, saved-card smoke (checkpoint) — deployed; smoke NOT RUN by user decision, BACK-06 and BACK-07 stay Pending

**Wave 18** *(blocked on Wave 17 completion)*
- [x] 01-18-PLAN.md — BACK-19 (D-17) expert cancel always refunds in full

**Wave 19** *(blocked on Wave 18 completion)*
- [x] 01-19-PLAN.md — Deploy wave 3b handoff, expert-cancel smoke (checkpoint) — deployed; smoke NOT RUN by user decision, BACK-19 stays Pending

**Wave 20** *(blocked on Wave 19 completion)*
- [x] 01-20-PLAN.md — BACK-13 promotion only via setup; read/write expert gate; legacy convert-on-demand tests flipped — NOT deployed; code parked on backend branch `wave-3c`, wave 3c dropped by user decision 2026-11-08

**Wave 21** *(blocked on Wave 20 completion)*
- [x] 01-21-PLAN.md — BACK-08 at its traced seams (no Connect account for non-experts; tax-profile GET per user decision); 38-route classification lock — NOT deployed; code parked on backend branch `wave-3c`, wave 3c dropped by user decision 2026-11-08

**Wave 22** *(blocked on Wave 21 completion)*
- [x] 01-22-PLAN.md — BACK-13/BACK-08 contract docs (EXPERT_SETUP_REQUIRED, EXPERT-SETUP-GATE.md) and route-header sweep — NOT on backend `master`; parked on branch `wave-3c`, wave 3c dropped by user decision 2026-11-08

**Wave 23** *(blocked on Wave 22 completion)*
- [x] 01-23-PLAN.md — Deploy wave 3c handoff, BACK-13 and BACK-08 seam smoke, account B background check (checkpoint) — NOT deployed; wave 3c dropped by user decision. No smoke run; BACK-08 and BACK-13 stay Pending

**Wave 24** *(blocked on Wave 23 completion)*
- [x] 01-24-PLAN.md — BACK-19 gap: a failed expert-cancel refund is retried as a refund; the sweep reads Stripe before moving money; booking detail stops reporting a failed refund

**Wave 25** *(blocked on Wave 24 completion)*
- [x] 01-25-PLAN.md — BACK-19 gap: the same fix for client cancels, including the hold left unflagged when retrievePI fails within 24 hours; transactions ledger; contract docs

**Wave 26** *(blocked on Wave 25 completion)*
- [x] 01-26-PLAN.md — Deploy the refund retry fix: pre-push gate, flagged-row query, user push, /health check (checkpoint). BACK-19 stays Pending until the 01-19 checklist has been run

**Cross-cutting constraints:**
- After the user's push, production GET /health reports the short SHA of local master

**Notes**:
- All work happens in the separate backend repo (`../ClickMe2026 Backend`) and is committed there. Update `openapi/clickme-api.yaml` and `docs/SOCKET-CONTRACT.md` with every contract change.
- Every change must be additive or otherwise safe for the current Android build (Google Play launch ~2026-12-13). This backend is the live production one, so a deployed change also reaches App Store build 6 right away; check each change against build 6 too. Deploy timing is settled in this phase's discuss step. REL-02 requires every backend change to be live before the iOS build is submitted. **Note (2026-11-08):** that is not true today, because BACK-08 and BACK-13 are not live (wave 3c dropped by user decision). See the Phase 8 note. Standing constraint from the user: backend changes must not break the live App Store iOS build; app review is slow.
- Q6 is settled in this phase's discuss step. **BACK-17 is conditional on Q6.** If Q6 picks the iOS-parser route, BACK-17 is closed as not needed and PUSH-01 (Phase 2) widens the iOS parser instead. The reminder, no-show and nudge crons send no `event_type`, so the iOS-only route can only send those pushes to the notifications list.
- Conflict between BACK-09 and CALL-01: calls are allowed to run until end+60, but `cron/expirePastSessions.js` completes bookings at end+15. A `/join` window that closes at the end, plus a status check, could block a rejoin during overtime. Settle the server rule here.
- BACK-13 must not break signup or the mode switch on current Android or on build 6. The "explicit setup call" has to be one those builds already make. Otherwise, hold the change until the iOS gate (SIGN-06) ships. **Applied 2026-11-08:** the wave 3c gate would leave client-only accounts on build 6 with no way to become experts, so the user dropped the wave, which follows this rule. BACK-13 and BACK-08 are not delivered, so the BACK-13 clause of success criterion 3 and the tax-ID clause of success criterion 2 are unmet. They need a new decision.
- BACK-07 and BACK-15 touch real holds and charges, so test them with care.
- iOS pairs: BACK-02 → Phase 3 (decline note display), BACK-14 → BOOK-07, BACK-15 → PAY-02, BACK-12 → BOOK-13, BACK-09 → CALL-02, BACK-13 → SIGN-06, BACK-18 → CHAT-07, BACK-17 → PUSH-01. Android display follow-ups, such as the decline note and the unread badge, are logged, not built.

### Phase 2: Shared iOS Plumbing

**Goal**: The app-wide rules that many screens rely on are correct in one shared place: call lifetime and join window, money formatting, booking-status decoding, booking error codes and push routing
**Depends on**: Phase 1
**Requirements**: CALL-01, CALL-02, CALL-04, CALL-05, CALL-09, BOOK-10, BOOK-14, BOOK-15, BOOK-18, PAY-05, PUSH-01, PUSH-02, PUSH-03, PUSH-04, CHAT-09
**Success Criteria** (what must be TRUE):
  1. A call keeps running until 60 minutes after its scheduled end, not 5. The server accepts the end of a call with a 0-second leg. The call screen reaches Ended when the Agora connection fails or is aborted.
  2. Join is available from 60 minutes before start until the scheduled end, or until 60 minutes after start if that is later, so the second half of a long session can be joined. A lookalike Skype/Zoom URL is not treated as a trusted provider.
  3. Every money amount in the app goes through one shared formatter and shows correct decimals for its currency ($12.50, not $12). A realtime `booking.update` with `rescheduled` or any unknown status updates the open screen instead of being dropped.
  4. Paid booking and reschedule pickers offer no slot more than 6 days ahead. The long-lead error codes show a clear error instead of an invalid confirm. Paid and free booking paths show the same slot-taken and meeting-link copy.
  5. Tapping any push switches to the right mode and opens the right screen: a booking-request push opens that request, `booking/payment_actions` opens that booking, and unknown types open the notifications list. No banner appears for the chat already on screen, and after logout the device stops receiving the old account's pushes.

**Plans**: 15/15 plans executed in 3 waves (iOS only, no backend change)

Plans:
**Wave 1**
- [x] 02-01-PLAN.md — CALL-01 first: 60-minute overtime cutoff, end + 55 notice, 1-second minimum on /end (CALL-04)
- [x] 02-03-PLAN.md — BOOK-18 tolerant booking status (rescheduled and unknown), every exhaustive switch decided, newest-refetch helper on the expert Upcoming list
- [x] 02-07-PLAN.md — BOOK-14 and PAY-05 on Make a Booking: shared error mapper, long-lead fall-through removed, 6-day paid picker cap
- [x] 02-09-PLAN.md — CR-01 and D-04: HomeRoute registered on every tab, tab-owned destinations, one push destination table (PUSH-01, PUSH-03, BOOK-15)

**Wave 2** *(each plan waits for the wave 1 plan it names)*
- [x] 02-02-PLAN.md — CALL-05 Agora failure reaches Ended; CALL-09 exact host matching (after 02-01)
- [x] 02-04-PLAN.md — CALL-02 one join window with the server reconnect flag, live Join on the client and expert lists, D-12 (after 02-03)
- [x] 02-05-PLAN.md — BOOK-10 shared Money formatter and the client money sites (after 02-03)
- [x] 02-08-PLAN.md — BOOK-14 client reschedule cap and shared copy on both reschedule screens (after 02-07)
- [x] 02-10-PLAN.md — PUSH-01/02/03, BOOK-15: route_category parse, target_role mode switch, cold-launch queue (after 02-09)

**Wave 3**
- [x] 02-06-PLAN.md — BOOK-10 expert money sites, lossless topic-editor price seed, app-wide formatter gate (after 02-04, 02-05)
- [x] 02-11-PLAN.md — CHAT-09 no banner for the chat on screen (after 02-10)
- [x] 02-12-PLAN.md — PUSH-04 logout push cleanup; Phase 2 device checklist; Q3 recorded as route only (after 02-10)
- [x] 02-13-PLAN.md — BOOK-18 newest refetch on the client detail, summary and My Bookings screens (after 02-03, 02-05)
- [x] 02-14-PLAN.md — CALL-02 Explore and expert dashboard strips on the shared join window; client detail can_join (after 02-04)
- [x] 02-15-PLAN.md — BOOK-10 Client Profile history card through the shared formatter (after 02-03, 02-05)

**Notes**:
- Plan CALL-01 first. It is critical and was confirmed on a production iPhone.
- The PUSH-01 approach follows Q6, which is settled in Phase 1. Q3 (BOOK-15: route only, or also build long-lead SCA recovery) is settled in this phase's discuss step. Settled as route only (D-01).
- CALL-05 is a LIKELY item. Confirm it on a device first; it may close as not reproducible.
- BOOK-10 replaces the per-screen `/100` math on client and expert screens (the inventory lists nine call sites). Later phases use the shared formatter.
- Unit-testable: overtime cutoff, join window, money formatter, status decoding with an unknown fallback, provider host matching, error-code mapping, push parsing and routing.

### Phase 3: Booked Sessions and Joining

**Goal**: Clients and experts can respond to, cancel, reschedule and join their booked sessions from every screen that offers those actions, with accurate status and refund information
**Depends on**: Phase 2 (and Phase 1 for BACK-02, BACK-12, BACK-14)
**Requirements**: BOOK-06, BOOK-07, BOOK-08, BOOK-09, BOOK-11, BOOK-12, BOOK-13, BOOK-16, BOOK-17, BOOK-20, CALL-03, CALL-06, CALL-07, CALL-08, CALL-10, EXP-11, EXP-13
**Success Criteria** (what must be TRUE):
  1. A client can accept or decline an expert-proposed reschedule from the upcoming-booking flow.
  2. Join works on every booking screen that offers it. Tapping Join on the client Upcoming Booking details screen starts the call, and the expert can join from Booking Summary within the same window. Both can open a Skype/Zoom meeting. The meeting screen shows elapsed or remaining time and no longer promises an automatic end.
  3. Cancel screens on both sides state the refund the backend will actually give: the 24-hour rule applies, a held booking shows as a release, and the policy follows Q2. The client's cancellation comment is sent and stored. Cancel is hidden once a session has ended.
  4. Reschedule works from both sides. Reschedule on an expert Upcoming card opens the expert reschedule flow. The client picker excludes the booking being moved, returns to where the user started with a confirmation, and shows correct copy for held bookings.
  5. Booking screens show the real state: the status pill shows the booking's real status, a declined booking shows the expert's decline note (the iOS half of BACK-02), the Past tab has an empty state, Keep Booking returns one screen back, and Leave a Review appears only for completed sessions.

**Plans**: 17/17 plans executed in 4 waves; 2 gap-closure plans (03-16, 03-17) added 2026-11-11 from 03-UAT test 3 (iOS, one additive backend commit for D-14 and D-16 with a deploy decision, one Android commit for BOOK-20). Revised 2026-11-10 after the plan check: 03-13, 03-14 and 03-15 were split out of 03-01, 03-06 and 03-07 so no plan touches more than 10 files.

Plans:
**Wave 1**
- [x] 03-01-PLAN.md — BOOK-06 first: client accepts/declines an expert reschedule on Upcoming details; shared RescheduleResponder and card; 500-unit decline cap
- [x] 03-02-PLAN.md — BOOK-08 cancel refund preview mirroring refund.js (D-04, D-05, D-06 recompute, D-14)
- [x] 03-03-PLAN.md — CALL-06/07 Skype/Zoom screen: timer from the voice layout, no auto-end promise, end + 55 notice (D-08, D-09, D-15)
- [x] 03-04-PLAN.md — CALL-10 expert Join on Booking Summary; EXP-13 expert card Reschedule on its own tab, expert picker 6-day paid cap (Phase 2 D-13)
- [x] 03-05-PLAN.md — Backend: payment_action_required (D-14) and payment_not_charged (D-16) on expert booking details, one commit, with a deploy decision checkpoint
- [x] 03-15-PLAN.md — BOOK-20 Android: booking ID on the Android client Booking Summary (separate Android commit)

**Wave 2** *(each plan waits for the wave 1 plans it names)*
- [x] 03-06-PLAN.md — Shared client toast; reschedule accept/decline confirmations (D-03) (after 03-01)
- [x] 03-08-PLAN.md — EXP-11 expert cancel states the client's refund or released hold, with no money line for a never-charged booking and failing closed without the backend keys (D-07, D-14, D-16) (after 03-04, 03-05)
- [x] 03-13-PLAN.md — BOOK-06 Booking Summary on the shared responder and card, silent refresh (D-01, D-03) (after 03-01)
- [x] 03-14-PLAN.md — BOOK-09 real status pill from the shared decoder; BookingShortID on Upcoming details (after 03-01)

**Wave 3**
- [x] 03-07-PLAN.md — Booking Summary: BOOK-17 review gate, BOOK-20 booking ID (iOS), decline note (after 03-01, 03-02, 03-13, 03-14)
- [x] 03-09-PLAN.md — CALL-03 Join, CALL-08 Open in {provider}, BOOK-13 Cancel visibility on Upcoming details (D-10, D-13) (after 03-01, 03-14)
- [x] 03-10-PLAN.md — BOOK-07 cancel comment sent; post-cancel toast from the server's refund_amount (D-06) (after 03-01, 03-02, 03-06)
- [x] 03-11-PLAN.md — BOOK-16 reschedule picker and one-level return with toast (D-11); BOOK-12 Keep Booking; BOOK-11 Past empty state (after 03-01, 03-06, 03-13)

**Wave 4**
- [x] 03-12-PLAN.md — Push-opened Cancel/Reschedule/Keep Booking/Leave a Review routes; Phase 3 device UAT checklist (after all)

**Gap closure** *(03-UAT test 3: code-review findings WR-01 and WR-02, user decision "fix both"; iOS only)*
- [x] 03-16-PLAN.md — WR-01: a successful accept or decline clears the reschedule response card before the refetch, on Upcoming details and Booking Summary (BOOK-06, D-03; gap G-03-3-WR01)
- [x] 03-17-PLAN.md — WR-02: a server refund_amount of 0 on a booking confirmed as refundable gets a neutral post-cancel toast with no amount or timing (BOOK-08, D-06; gap G-03-3-WR02) (after 03-16: shared review ledger and device checklist)

**UI hint**: yes
**Notes**:
- Plan BOOK-06 first. It is critical and was rated so by the user.
- Q2 (BOOK-08, EXP-11) is settled in this phase's discuss step. If Q2 changes the expert-cancel refund policy instead of only fixing the copy, the backend change is made in the backend repo during this phase, with backend tests and Android compatibility. To keep it in the backend layer, settle Q2 early, in Phase 1's discuss step.
- This phase uses the Phase 2 join window (CALL-03, CALL-08, CALL-10), money formatter and status decoding. BOOK-07 only has an effect once BACK-14 stores the reason.

### Phase 4: Booking, Payment and Discovery

**Goal**: Clients can find an expert, book and pay without double submissions, unintended holds, misleading errors or missing profile data
**Depends on**: Phase 2 (and Phase 1 for BACK-06, BACK-07, BACK-10, BACK-15)
**Requirements**: BOOK-01, BOOK-02, BOOK-03, BOOK-04, BOOK-05, BOOK-19, PAY-01, PAY-02, PAY-03, PAY-04, EXPL-01, EXPL-02, EXPL-03, EXPL-04, EXPL-05, EXPL-06, EXPL-07
**Success Criteria** (what must be TRUE):
  1. Closing the payment sheet without tapping pay never places a hold (behavior per Q4). A confirm that times out and is retried takes the user to their pending booking instead of showing "slot taken".
  2. After a request is sent, the user cannot go Back and submit it again. Request Sent reads "Loading booking…", and its payment card describes what actually happened (hold vs charge, including older long-lead bookings). A booking started from Favorites or Search doesn't leave Request Sent stuck on that tab.
  3. Changing month never shows the previous month's availability. Slot and Today's Sessions times show a readable time-zone name and follow the device's 12/24-hour setting.
  4. An unavailable (404) expert profile shows "This profile isn't available", and network errors offer a retry. Empty Expertise, Topics and Reviews sections are hidden. Free featured topics show "Free". Search tag pills show their full text.
  5. Favorites shows every favorite (paged), with working empty-state buttons and correct copy. A profile's favorite state matches its `is_favorite`. The full reviews list loads beyond 20 reviews.

**Plans**: 14/14 plans executed in 4 waves (iOS, plus one backend plan for D-12 with a user deploy checkpoint; 04-12 has a user decision checkpoint for the LIKELY item EXPL-02)

Plans:
**Wave 1**
- [x] 04-01-PLAN.md — D-12 backend: payment_method.detached evicts clones; T-24h sweep refuses a removed card; user deploys and subscribes the endpoint (checkpoint)
- [x] 04-02-PLAN.md — PAY-01 closing the card sheet cancels (didCancel, D-01, D-02); Link off (D-16); PAY-04 sheet comment
- [x] 04-03-PLAN.md — BOOK-01, BOOK-05, BOOK-19: Request Sent one-way (Back hidden, swipe locked, exits in every state) and source-tab exits (D-05, D-06)
- [x] 04-04-PLAN.md — BOOK-02 month race; BOOK-03 zone name on slots and Today's Sessions (D-18); BOOK-04 12/24-hour on slots, Today's Sessions and Request Sent (K3)
- [x] 04-05-PLAN.md — EXPL-01 not-available and load-failed profile states (D-10); heart from is_favorite (EXPL-05, D-09)
- [x] 04-06-PLAN.md — EXPL-05 Favorites paging on the shared PagedList, footer retry, refresh, heart Pro Tip (D-07, D-09)
- [x] 04-07-PLAN.md — D-13 suspension on cold launch routes to Login with the notice

**Wave 2** *(each plan waits for the wave 1 plans it names)*
- [x] 04-08-PLAN.md — PAY-02 confirm timeout keeps the payment, retries, lands on Request Sent; confirm-unknown alert (D-03); 409 PAYMENT_IN_PROGRESS as outcome unknown (D-17); PAY-04 view-model comments (after 04-04)
- [x] 04-09-PLAN.md — PAY-03 payment card variants from the booking's payment state; a held booking is never called charged (after 04-03, 04-04)
- [x] 04-10-PLAN.md — EXPL-05 Favorites empty-state buttons: Explore Experts, View My History on Past (D-08) (after 04-03)
- [x] 04-11-PLAN.md — EXPL-06 reviews paging; EXPL-04 full-text search pills (after 04-06)
- [x] 04-12-PLAN.md — Heart seed from Favorites (D-09); EXPL-02 empty sections and zero/one review copy after the device-confirm decision (after 04-05, 04-06)

**Wave 3**
- [x] 04-13-PLAN.md — PAY-02 D-04 "You may already have this booking" and D-15 DUPLICATE_BOOKING route via the session ledger (after 04-08)

**Wave 4**
- [x] 04-14-PLAN.md — EXPL-03 and EXPL-07 regression; Phase 4 device UAT checklist with the D-11 real-money session (01-17, 01-19, backlog 999.1 and 999.2) and the D-14 Android check; full suite (after all)

**UI hint**: yes
**Notes**:
- Q4 (PAY-01) is settled in this phase's discuss step.
- PAY-01 and PAY-02 involve real holds. Every environment points at the production backend with live Stripe keys, so plan device tests to place and release real holds on your own accounts.
- PAY-02 builds on BACK-15's idempotent replay.
- EXPL-02 is a LIKELY item. Confirm it on a device first.
- EXPL-07 and the EXPL-03 "Free" label were built in quick 261109-323. Phase 4 only needs to device-check them, and both stay unchecked until it does.
- PAY-04 is a comment-only change, verified in code review.

### Phase 5: Signup, Mode Switch and Account

**Goal**: Users can finish signup, enter Expert mode only with a complete setup, and edit or close their account with saves that stick and copy that tells the truth
**Depends on**: Phase 2 (and Phase 1 for BACK-13) — needs a decision: BACK-13 is not delivered (wave 3c dropped 2026-11-08)
**Requirements**: SIGN-01, SIGN-02, SIGN-03, SIGN-04, SIGN-05, SIGN-06, SET-01, SET-02, SET-03, SET-04, SET-05, SET-06, SET-07
**Success Criteria** (what must be TRUE):
  1. An expert cannot publish without a photo, and the uploaded photo matches the crop they set. Expertise tags and languages are saved in tap order, so the first pick is primary. The country code is normalized on publish.
  2. Resuming signup keeps an already-verified email verified. Switching to Expert mode with incomplete setup opens the setup hub (per Q5).
  3. Language edits on the client and expert profiles save to the server. Opening Notification preferences sends no save until the user changes something.
  4. Help → Email Us opens a mail to `clickmeapp@uptrendinvestments.net`. Feedback cannot be sent with fewer than 10 characters. Delete Account has no Pause Account card and accurately says what is deleted and what is kept or anonymized.
  5. `CancellationPoliciesView` and `ReadyToStartCallView` are either reachable in the app or removed from the codebase (per Q7).

**Plans**: TBD
**UI hint**: yes
**Notes**:
- These decisions are settled in this phase's discuss step:
  - Q5: the SIGN-06 gate, and whether S2's optional province moves in.
  - Q7: SET-07.
  - Q1: remember-login-email (T8), which stays out of scope unless Q1 moves it in.
- SIGN-06 pairs with BACK-13 (Phase 1). **Needs a decision:** BACK-13 is not delivered (wave 3c dropped by user decision 2026-11-08; code parked on backend branch `wave-3c`), so this pairing has to be decided again. This note does not change this phase's plans or scope.
- The SET-06 copy must match what `services/accountCascade.js` keeps or anonymizes. Log the matching Android copy change as a follow-up.
- SET-01: check the expert profile settings view model for the same missing languages save.

### Phase 6: Expert Mode

**Goal**: Experts can price, describe and schedule their topics correctly and handle requests, bookings, clients and notes without wrong amounts or dead ends
**Depends on**: Phase 2 (and Phase 1 for BACK-01, BACK-05, BACK-11)
**Requirements**: EXP-01, EXP-02, EXP-03, EXP-04, EXP-05, EXP-06, EXP-07, EXP-08, EXP-09, EXP-10, EXP-12, EXP-14, EXP-15, EXP-16, EXP-17, EXP-18
**Success Criteria** (what must be TRUE):
  1. An expert can enter a topic price with decimals (e.g. 12.50) in the topic's own currency, and editing a topic keeps that currency. When creating a topic, the expert can choose CAD or USD on both iOS and Android (EXP-17). The icon and description can be cleared. Deleting a topic asks for confirmation first.
  2. In availability, Cancel on the time-range picker reverts the change. No end time is produced that the picker can't show. An off-grid stored time such as 09:15 shows as selected.
  3. Accepting a request shows the booking-confirmed screen, and the calendar event created from it is titled with the client's name.
  4. Expired request cards stay readable. The expert-side Client Profile shows real earnings in the booking currency. The hub online dot reflects real presence, or is removed.
  5. The private booking note is capped at 5000 characters with a counter, trims whitespace, and asks before discarding unsaved edits.

**Plans**: TBD
**UI hint**: yes
**Notes**:
- EXP-02 and EXP-14 use the Phase 2 money formatter. EXP-03 matters for money too, because sending the wrong currency changes what clients pay.
- If Phase 1 dropped the accept message (BACK-01), remove the iOS accept-message field here.
- EXP-12 is a LIKELY item. Confirm it on a device first.
- EXP-08 is a comment-only change, verified in code review.

### Phase 7: Chat

**Goal**: Chat is reliable and clear: messages appear immediately and can be retried, block state is obvious to both sides, and unread and read state is visible
**Depends on**: Phase 2 (and Phase 1 for BACK-16, BACK-18)
**Requirements**: CHAT-01, CHAT-02, CHAT-03, CHAT-04, CHAT-05, CHAT-06, CHAT-07, CHAT-08
**Success Criteria** (what must be TRUE):
  1. A sent message appears immediately as pending, shows a failed state on error, and can be retried. Loading earlier messages never duplicates any. Typing indicators and View Profile work as soon as a chat opens.
  2. A blocked thread hides the composer and says who blocked it, and only the blocker sees Unblock. Blocking from a profile uses a confirm dialog whose copy matches what blocking actually does.
  3. Conversation rows show an unread badge that clears once the thread is read.
  4. Reports from chat reach the backend as report-reason enum values, the same as profile reports.
  5. The "Read" label updates live while a chat is open, or CHAT-08 is closed as not reproducible after the device re-test.

**Plans**: TBD
**UI hint**: yes
**Notes**:
- Q8: re-test CHAT-08 on a device before planning this phase. If it still fails, the plan traces `message.read` delivery on the backend.
- CHAT-07 needs BACK-18. CHAT-09 (foreground banner) is done in Phase 2.
- Realtime checks need two devices or accounts.

### Phase 8: Release

**Goal**: One verified iOS build with every fix reaches TestFlight and the App Store, after all backend changes are live in production
**Depends on**: Phases 1, 2, 3, 4, 5, 6 and 7
**Requirements**: REL-01, REL-02
**Success Criteria** (what must be TRUE):
  1. Every phase's UAT checklist (Phases 1–7) has passed on a real iPhone. The release candidate passes a regression run of the core paths: book, pay, join, run past the scheduled end, and finish.
  2. Every in-scope inventory item is closed, closed as not reproducible (LIKELY items), or explicitly deferred with a reason.
  3. Every backend change is deployed to production before the iOS build is submitted, and the current Android build still works against it.
  4. One new iOS build containing every fix builds cleanly with no new warnings, is on TestFlight, and is submitted to the App Store.

**Plans**: TBD
**Notes**:
- No hotfix build comes before this one (user decision 2026-11-07).
- `Environments.plist` stays on Production for the release build (P9, by design).
- **Note (2026-11-08):** the goal, success criterion 3 and REL-02 assume every backend change is live. BACK-08 and BACK-13 are not, because wave 3c was dropped by user decision (code parked on backend branch `wave-3c`). Scope is unchanged. Before release they need a new decision: ship them, or defer them with a reason under success criterion 2.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Backend Fixes | 26/26 | Complete    | 2026-11-09 |
| 2. Shared iOS Plumbing | 15/15 | In Progress | - |
| 3. Booked Sessions and Joining | 17/17 | In Progress | - |
| 4. Booking, Payment and Discovery | 14/14 | In Progress | - |
| 5. Signup, Mode Switch and Account | 0/TBD | Not started | - |
| 6. Expert Mode | 0/TBD | Not started | - |
| 7. Chat | 0/TBD | Not started | - |
| 8. Release | 0/TBD | Not started | - |

---
*Roadmap created: 2026-11-07*

## Backlog

### Phase 999.1: Follow-up — Phase 01 deferred UAT follow-up: Test 1 (BACKLOG)

**Goal:** Resolve the UAT checkpoint deferred during Phase 01 verification
**Source phase:** 01
**Deferred at:** 2026-11-09 during /gsd-verify-work 01 session completion
**Follow-ups:**
- [ ] Test 1: defer (Run real-Stripe checklists 01-17 and 01-19 during Phase 4 payment UAT; the 01-19 checklist does not prove the failed-refund retry) (deferred 2026-11-09)

### Phase 999.2: Follow-up — Phase 01 deferred UAT follow-up: Test 4 (BACKLOG)

**Goal:** Resolve the UAT checkpoint deferred during Phase 01 verification
**Source phase:** 01
**Deferred at:** 2026-11-09 during /gsd-verify-work 01 session completion
**Follow-ups:**
- [ ] Test 4: defer (Run BACK-15 with a real hold during Phase 4 payment UAT. A normal retry tap only proves one booking and one hold, not the confirm replay code; on iOS only the retry after 3D Secure calls confirm again) (deferred 2026-11-09)
