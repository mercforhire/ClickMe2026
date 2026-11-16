# Phase 2 Device UAT Checklist

Every device check Phase 2 (shared iOS plumbing) deferred, in one list. Built by plan 02-12 from `.planning/WINDOWS.md` (phase 02 `unrun-verify` entries #13, #15–#20 and deviation #14) and from the "Pending device checks" sections of every 02-*-SUMMARY.md. Where a plan's original wording was later superseded, the latest wording (SUMMARY / WINDOWS.md) is used here and the supersession is noted on the item.

## Setup

- **Device:** a real iPhone (iOS 18+), not the simulator. Push, chat and calls need APNs/FCM and Agora.
- **Build:** a build from this phase — HEAD at or after the 02-12 commits. CALL-01 in particular needs a build from `be00d74` (02-01) or later; the user's earlier device evidence came from a pre-fix build. For item 1's Android-peer follow-up, use a **debug** build so a failed `POST /end` is logged.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`). Payment items touch real holds only where stated; nothing on this list captures a charge.
- **Accounts:** account **A** (client) and account **B** (a set-up expert who also uses client mode). A client-only account **C** for the PUSH-02 fallback case. The expert account should own at least one **CAD topic priced with cents** (for example 12.50, which can be set from Android) and, if available, a **legacy USD topic**.
- **Second device:** another phone (Android is fine) signed in as the other party, to send chat messages, accept or reschedule bookings, and trigger pushes.
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. Items marked *optional* are unit-tested and may be skipped.

## Notes before you start

- **UI-SPEC needs revision (known drift, not fixed here).** `02-UI-SPEC.md` still describes two behaviors that were changed to Android parity during execution: hidden calendar days past the 6-day paid cap (W1-9, W1-10, section 4, the E1/A1 month-blank captions) and a hidden Join on `pending_reschedule` bookings (D-12 rows around lines 221–228, 337–339, S2 at 355). The checklist below is the authority for the expected result: days are **visible with dimmed, untappable slots and a fixed note**, and Join is **visible but disabled**. Revise the spec after this UAT (WINDOWS.md #14).
- **Status of the Join/Dashboard wording.** The 02-04 SUMMARY's "no Join on a `pending_reschedule` booking" is superseded by 02-14 (`a620b92`): Join is shown disabled, not hidden, on the Dashboard strip, the Explore strip, My Bookings and the expert Upcoming list.
- **BOOK-10 wording is CAD.** The app creates topics in the account default currency (CAD), so expected amounts read `CA$12.50` / `CA$12.00`. The plan-stage item "Client Profile history rows show `—` until EXP-14" is superseded by 02-15: gated rows show the real net earnings.
- **EXP-17 (CAD/USD topic currency picker) is not a Phase 2 item.** Its iOS half shipped in `73e729e` / `e43ef50` from another session; the Android half is outstanding, so EXP-17 stays Pending in REQUIREMENTS.md and is not checked here.
- **Push-opened screens may have inert action buttons** (Join, Cancel, Reschedule, Leave Review) until Phase 3 wires them (Open Question 4). For every push item, "pass" means the right screen opens with no SwiftUI warning page and Back returns to the tab root.
- **PUSH-04 residual window is accepted (D-17, D-18).** After a logout with no network, the old account's pushes may still arrive until the next launch or login, whose retry is Firebase `deleteToken` only. That is not a failure. Item 14 says where this applies.

---

## Items

### 1. CALL-01 — in-app call overtime notice and auto-end (02-01)

**Status:** PENDING (user "approve and defer" at the 02-01 tracer gate; the earlier device run was on a pre-fix build).

Steps:
1. Book a short paid or free in-app voice session (for example 15 minutes) between A and B. Both join on the device and the peer.
2. Stay in the call past its scheduled end. Do not hang up.

Expected:
- At end + 10 minutes the call is **still connected** (the old 5-minute test cutoff is gone).
- At end + 55 minutes the notice **"This call will end in 5 minutes"** appears in the in-app voice layout.
- At end + 60 minutes the call **ends by itself** and the screen shows **Ended**.
- Follow-up from 02-01: when the iPhone auto-ends, the **Android peer tears down too** (`call.ended` is emitted to both). If it stays connected, note it; with a debug iOS build a failed `POST /end` prints a `push:`-style DEBUG line in the Xcode console. No Android or backend change was made for this.

Result: PASS, partial (2026-11-10, UAT test 1): call still connected at end + 11, so the old 5-minute cutoff is gone. The end + 55 notice, the end + 60 auto-end and the Android peer teardown were not observed (user did not wait); warn/end timing is covered by `CallOvertimePolicyTests`

### 2. CALL-05 — Agora failure maps to Ended; normal-call regression (02-02, D-14)

**Status:** PASSED on device 2026-11-09 (user approved the 02-02 tracer gate with this result; recorded here, not re-run).

Steps: one normal in-app voice call between A and B; both sides reach Active; either side hangs up.

Expected: the call connects, both sides are Active, the hang-up reaches **Ended** and dismisses as before. (The `.failed` branch itself only fires after about 20 minutes of failed reconnects and is covered by `AgoraConnectionMappingTests`; no airplane-mode repro, per D-14.)

Result: PASS — 2026-11-09, on a real iPhone, normal call connected and both sides could hang up.

### 3. CALL-02 — Join window edges on every surface (02-04, 02-14)

**Status:** PENDING (02-04 deferred; 02-14 deferred as WINDOWS.md #19).

Surfaces: client **My Bookings** list, client **Explore today strip** (`Join Call`), expert **Upcoming** list, expert **Dashboard strip** (`Join Session`), and the Upcoming Booking detail.

Steps and expected:
1. With a confirmed booking about 65 minutes away, keep each surface open. **Join appears on its own within about a minute of start − 60 min, with no pull-to-refresh**, on all four surfaces. On the expert Upcoming list the **NOW** badge also appears without a refresh.
2. On a session longer than an hour, Join is **still shown at start + 90 min**.
3. On the client list, the booking **leaves the joinable list at max(end, start + 60 min)**.
4. During overtime (after end, before end + 60), the expert can **reconnect** when the server still allows it.

Result: PASS (2026-11-10, UAT test 2)

### 4. CALL-02 / D-12 — `pending_reschedule` shows Join visible but disabled (02-04, 02-14)

**Status:** PENDING (WINDOWS.md #19). **Supersedes** the 02-04 wording "no Join on a pending_reschedule booking" and the UI-SPEC D-12 rows; Join is shown disabled, not hidden, as Android does (`a620b92`).

Steps: have the other party propose a reschedule on an upcoming booking so it is `pending_reschedule`, then open each surface.

Expected:
- Expert **Dashboard strip**: the card shows **Join Session visible but dimmed and disabled**; VoiceOver reads it as dimmed.
- Client **Explore today strip**: **Join Call visible but dimmed and disabled**; VoiceOver reads it as dimmed.
- Client **My Bookings** and expert **Upcoming** list: the card shows **Join disabled**.
- Once the reschedule is accepted (booking back to `confirmed`), Join enables on its own within about a minute when inside the window.

Result: PASS (2026-11-10, UAT test 2)

### 5. CALL-09 — external meeting link shows its provider (02-02) — *optional*

**Status:** PENDING, optional (lookalike-host rejection is unit-tested in `ExternalMeetingProviderTests`).

Steps: open a booking whose meeting link is a real Zoom or Skype URL.

Expected: the button shows the provider label (Zoom / Skype). A link on an unknown host shows the generic "Open Meeting" copy.

Result: SKIPPED (2026-11-16, UAT test 17): optional, already unit-tested

### 6. BOOK-10 — money formatting on every screen, topic reopen-and-save, Client Profile history (02-05, 02-06, 02-15)

**Status:** PENDING (WINDOWS.md #13 client side, #16 expert side, #20 Client Profile history). Wording is CAD. A legacy USD topic is optional.

**Client screens (02-05):** with a CAD topic priced 12.50 and one priced 12.00:
1. **Make a Booking** shows `CA$12.50` and `CA$12.00` (never `CA$12`, `$12` or `CAD 12`).
2. **Explore** featured topics, the **Expert Profile** topic list and **Payment History** rows show two decimals and `CA$`.
3. The **Upcoming Booking** detail fee, the **Booking Summary** price row and the **Cancel** refund preview (held or captured booking) show full cents and `CA$`.

**Expert screens (02-06):** as B in expert mode:
4. **Dashboard** "This Week" earnings and available payout, and **Payouts** available and pending balances and earnings rows, show `CA$x.xx`.
5. An **incoming request** worth 75 shows `CA$75.00`; the **Upcoming Bookings** card EARNINGS value and every line of the **request-decision breakdown** (session price, platform fee, net) show two decimals and `CA$`.
6. **Topics** tab cards show two decimals and `CA$` (a JPY topic, if any, shows no decimals).
7. **Reopen-and-save (D-19):** open the topic priced 12.50 — the price field shows `12.50`; change **only the title** and save; the card still shows `CA$12.50`. If a legacy USD topic exists, save it with only the title changed: the card still shows `$`, not `CA$`.

**Client Profile history (02-15, supersedes the plan-stage "—" wording):**
8. As B, open a client's profile from a booking. Rows with status `confirmed`, `completed`, `pending_approval`, `pending_reschedule` or `in_progress` show the **real net earnings as `CA$x.xx`**. `cancelled` and other non-gated rows show **`—`**. No row shows `$0` or `CA$0.00` unless the net really is zero. The layout is unchanged.

Result: PASS (2026-11-10, UAT test 3)

### 7. BOOK-14 — paid 6-day cap: days visible, slots dimmed, fixed note (02-07, 02-08)

**Status:** PENDING (02-08 deferred; WINDOWS.md #14 records the Android-parity supersession). **Supersedes** the 02-07 blank-day rule and UI-SPEC W1-9/W1-10/section 4: days past the cap are **not hidden**.

Steps: as A, on a **paid (CAD)** topic open **Make a Booking**; then, on an existing paid booking, open the client **Reschedule** picker. Repeat Make a Booking on a **free** topic.

Expected, paid (both pickers):
- **All calendar days are visible and tappable**, including the next month.
- A fixed note is shown under the slots title whatever day is selected: **"Paid sessions can be booked up to 6 days ahead."** (Make a Booking) / **"Paid sessions can be rescheduled up to 6 days ahead."** (Reschedule).
- Slot chips starting **after now + 6 days are dimmed and cannot be tapped**; a chip at or before now + 6 days can be tapped and selected.

Expected, free: **no note**, nothing dimmed by the cap, the full month is bookable.

Unchanged: the **expert** reschedule picker (Phase 3, EXP-13).

Expected, VoiceOver (02-UI-SPEC A1, C1; quick 261110-nzy):
- With VoiceOver on, swiping through the Make a Booking grid reads only the displayed month's days; the dimmed previous-month and next-month numbers are skipped.
- Past days read as dimmed, and days past the paid limit read normally.
- The chevrons read "Previous month" and "Next month".
- The client Reschedule calendar behaves the same.

Result: PASS (2026-11-10, UAT test 4), including the VoiceOver checks

### 8. PAY-05 — same slot-taken copy on free and paid bookings (02-07) — *optional*

**Status:** PENDING, optional (both paths go through `BookingErrorMapper`; unit-tested with mocks).

Steps: from the second device book a slot; on the device try to book the same slot, once on a free topic and once on a paid topic.

Expected: both show the **same written slot-unavailable message** (not raw server text), and the selected slot is cleared.

Result: SKIPPED (2026-11-16, UAT test 17): optional, already unit-tested

### 9. BOOK-18 — live booking updates and overlapping refresh (02-03, 02-13)

**Status:** PENDING (02-03 deferred; 02-13 deferred as WINDOWS.md #18).

Client (02-13):
1. With **Upcoming Booking details** open on the client, have the expert propose a reschedule from the other device. The screen **updates without a pull-to-refresh**. Repeat and **pull to refresh at the same moment**: the screen ends on the rescheduled state and **no spinner is left running**.
2. With **My Bookings** open on the client, have the expert cancel or reschedule from the other device **while you pull to refresh**: the row ends in its new state and the list is not left on a spinner.

Expert (02-03):
3. With the expert **Upcoming Bookings** tab open, have the client cancel or reschedule from the other device **while pulling to refresh**: the row ends in its new state with no stuck spinner.

Result: PASS (2026-11-10, UAT test 5), including the neutral label for an unknown status

### 10. PUSH-01 / CR-01 — every push type opens its screen, warm and cold (02-09, 02-10)

**Status:** PENDING (02-10 tracer check deferred as WINDOWS.md #15).

Steps and expected:
1. **Tracer check (02-10):** app backgrounded in client mode as A; the expert accepts A's pending request; tap the **booking-confirmed** push. The **Bookings tab opens on that booking**, no SwiftUI warning page, and Back returns to **My Bookings**.
2. Each push type — confirmation, decline, cancellation, reschedule, reminder, session ended, chat, review, payout, account — in **client** and in **expert** mode, **warm** (backgrounded) and **cold** (force-quit): opens its screen with no warning page; Back goes to the tab root. A cold tap launches in the right mode and opens the screen **once**.
3. A push with an **unknown category** opens the **notifications list**.
4. **Notifications list rows** behave the same as the push (02-09): in expert mode tap a booking notification from the Dashboard bell — it switches to Bookings and shows the booking summary; Back returns to the Upcoming list.
5. **Android parity (02-10):** a cron **reminder, no-show or nudge push that carries only `booking_id`** opens that booking.

Result: PASS (2026-11-15, UAT test 6); no SwiftUI warning page seen from any push or notifications-list tap (UAT test 14)

### 11. PUSH-02 / D-03 — role-targeted pushes switch mode silently, with the client-only fallback (02-10)

**Status:** PENDING (02-10 Task 2 human-check, warm and cold).

Steps and expected:
1. B in **client mode**, tap a **booking-request** push (expert-targeted): the app **switches to expert mode** and opens that request.
2. B in **expert mode**, tap a client-targeted **booking-confirmed** push: the app **switches to client mode** and opens the booking.
3. **Client-only account C**, expert-targeted push: **stays in client mode** and opens the **notifications list**; never forced into expert mode.
4. Force-quit, tap a push: launches in the right mode and opens the screen once.
5. **Roles unknown at cold launch** (02-10 device check 6): airplane mode on, last mode client, set-up expert account B; cold-launch from an expert-targeted push. **Client home opens with no notifications list**; turn airplane mode off and close Control Center — the app **switches to expert mode and opens the request** once the network returns.

Result: PASS (2026-11-15, UAT test 7): mode switch for set-up expert B and client-only C fallback pass. Step 5 (roles unknown at cold launch): the app did not open the notifications list after the network returned, which matches the expected result; whether the request then opened was not confirmed. User accepted it as is, no fix wanted

### 12. PUSH-03 — a booking-request push opens that request (02-09, 02-10)

**Status:** PENDING.

Steps and expected:
1. As B (expert mode), tap a **booking-request** push: that request's **decision screen** opens; Back returns to the Dashboard.
2. From the expert **notifications list**, tap a booking-request row: the same decision screen opens; Back returns to the Dashboard (02-09).

Result: PASS (2026-11-15, UAT test 8)

### 13. BOOK-15 — a `payment_actions` push opens that booking, route only (02-10, D-01)

**Status:** PENDING. Q3 settled 2026-11-09 as **route only** (D-01): no recovery flow is built, iOS never calls `POST /bookings/:id/recover-payment`, and an unanswered booking is cancelled by `scaRecoveryWindowSweep`.

Steps: tap a `booking/payment_actions` (`PAYMENT_ACTION_REQUIRED`) push for one of A's bookings. Only paid long-lead bookings made before 2026-10-28 can produce one; if none exists, record SKIPPED (no eligible booking).

Expected: the **booking detail opens**, no warning page. No recovery sheet or payment prompt is shown.

Result: PASS (2026-11-15, UAT test 9)

### 14. PUSH-04 — after logout the old account's pushes stop (02-12, D-06 as amended by D-17, D-18)

**Status:** PENDING (user "approve and defer" at the 02-12 Task 1 tracer gate, 2026-11-10; Task 2 paths added below); (e) fast re-login added by quick 261110-mmr (WR-02 fix), and step 2 now describes the Android-order wait with the Log Out row's progress state (IN-02).

**(a) User logout (Task 1 tracer check):**
1. Sign in as A on the device. Confirm a push arrives (for example a chat message from B).
2. **Log out from Profile and confirm.** The Log Out row shows a spinner and cannot be tapped again while the cleanup runs (the server DELETE, then Firebase deleteToken, each capped at 3 seconds); the app lands on Login once it has finished, after up to about 6 seconds, usually much less.
3. From the other device, **send A a chat message** (or trigger any push to A).

Expected: **nothing arrives** on the logged-out device — no banner, nothing in Notification Center.

**(b) Second account on the same device:**
4. Sign in as **B** on the same device. Trigger a push to B and a push to A.

Expected: **B receives B's pushes; A's do not arrive.**

**(c) Airplane-mode logout (Task 2, retry path):**
5. Sign in as A. Turn **airplane mode on**. Log out from Profile (it still completes and returns to Login). Force-quit.
6. Turn airplane mode off, **relaunch** (signed-out launch runs the deleteToken-only retry), then **sign in as B**.

Expected: **B receives B's pushes and A's pushes do not arrive.** Accepted residual window (D-17, D-18): between the offline logout and that relaunch/login, a push to A *may* arrive on this device; that is not a failure.

**(d) Involuntary logout (Task 2), only if a safe trigger is available on production:** with the device signed in as A, invalidate A's session from elsewhere (for example a backend-side token revocation on a test account, or a suspension of a test account). On the next authenticated request the app returns to Login **at once**, without waiting on the network; afterwards a push to A does not arrive on this device. If no safe trigger exists, record SKIPPED (no safe production trigger); the ordering is pinned by `PushTokenCleanupTests`.

**(e) Fast re-login (WR-02):**
7. Sign in as A. **Log out from Profile and confirm.** Watch the Log Out row: it shows a spinner and is not tappable while the cleanup runs, for up to about 6 seconds, then the app lands on Login.
8. **As soon as the Login screen appears, sign in as B** (no need to wait; the cleanup has already finished by the time Login is visible).
9. Once Home appears, **trigger a push to B from the other device without backgrounding the app first**, then trigger a push to A.

Expected: **B receives it; the push to A does not arrive.** Sign-in itself takes its usual time.

**Not a failure:** a push to A arriving before the retry after an offline logout (D-17); the app never keeping A's bearer or refresh token for the retry (D-18) — only a Bool marker is saved; the Log Out spinner staying up for as long as about 6 seconds on a slow or offline network (two 3-second caps); and, if Firebase was unreachable for longer than that during the logout, B's pushes starting only after the next token callback or foreground (same class as the D-17 window; record it in Result if seen).

Result: PASS (2026-11-15, UAT test 10), including (a)-(d) and the (e) fast re-login. No-credential retry (D-18) and no token re-upload during logout confirmed by code review (UAT tests 15, 16)

### 15. CHAT-09 — no banner for the chat already on screen (02-11)

**Status:** PENDING (deferred as WINDOWS.md #17).

Steps and expected:
1. **Main:** device 1 (account B) has the chat with A open; A sends a message. **No banner, no sound**; the message appears in the thread; nothing is added to Notification Center.
2. **Control:** from the conversations list (chat closed), a second message from A **shows the banner and plays the sound**.
3. **Tab switch (assumption A3):** with chat A open, switch to the Bookings tab and have A send: **the banner appears**. If it does not, `ChatView.onDisappear` does not fire on tab change and the shells must clear `ChatPresence` on tab selection (follow-up).
4. **Stacked chats:** open chat B on top of chat A (from a push or a profile), go back to A, then A sends: **no banner**. While B is on top, a message from A shows the banner and a message from B does not.
5. **Non-chat push while a chat is open:** a booking push (for example a request accepted) while any chat is open **still shows the banner and sound**.
6. *Not device-testable:* a chat push with no thread id (preview seeds only); covered by the `noThreadIdPresents` unit row.

Result: PASS (2026-11-15, UAT test 11)

---

## Not on the device

Unit-test only, no device step: **CALL-04** (`POST /end` sends at least 1 second for a joined leg and nothing for a never-joined leg; `CallOvertimePolicyTests`).

Decision records referenced above: D-01 (Q3 route only), D-03 (expert-targeted push on a non-expert account), D-12 (joinable statuses follow the server; now shown disabled), D-14 (CALL-05 closes on the mapping test plus one normal-call regression), D-17 (PUSH-04 retry at launch and login only, residual window accepted), D-18 (retry is `deleteToken` only, no retried server DELETE, no kept credential), D-19 (untouched topic save keeps stored amount and currency).

## Sign-off

| Field | Value |
|-------|-------|
| Build (commit / TestFlight build number) | |
| Device and iOS version | |
| Tester | |
| Date | 2026-11-10 to 2026-11-16 |
| Items passed / failed / skipped | 13 / 0 / 2 |
| Follow-ups opened | None. Partial coverage noted on items 1 and 11 |

A Phase 2 item that fails on device goes back to its owning plan's requirement (it stays Pending in REQUIREMENTS.md) and to `.planning/WINDOWS.md` as a new entry; a passing item lets its WINDOWS.md `unrun-verify` entry be marked fixed.
