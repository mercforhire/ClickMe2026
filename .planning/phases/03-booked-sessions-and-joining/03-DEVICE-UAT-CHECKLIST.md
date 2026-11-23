# Phase 3 Device UAT Checklist

Every device check Phase 3 (booked sessions and joining) deferred, in one list. Built by plan 03-12 from the "Deferred device checks" and "Pending device checks" sections of every 03-*-SUMMARY.md, the UI-SPEC backstops (L2, L3, D2, D3, D4, K2), the VALIDATION.md "Manual-Only Verifications" table and the RESEARCH assumptions log. Where a SUMMARY recorded a deviation or a superseded wording, the SUMMARY's wording is used and the item says so. All code is merged and unit-tested; nothing on this list has been seen on a device yet.

## Setup

- **Device:** a real iPhone (iOS 18+), not the simulator. Push, calls and the Skype/Zoom handoff need APNs/FCM, Agora and the meeting app.
- **Build:** a build at or after plan 03-12's commits (`8115d3b` or later on `main`). Plan 03-12 is the last Phase 3 plan.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`). Real holds and charges exist: items that cancel or reschedule a paid booking touch a real hold or refund. Run them with a small CAD topic.
- **Accounts:** account **A** (client) and account **B** (a set-up expert). B needs a **paid CAD topic priced with cents** (for example 12.50), an **in-app voice topic**, and a **Skype/Zoom topic with a meeting link**. B also uses client mode for the expert-shell item.
- **Second device:** another phone (Android is fine) signed in as the other party, to propose reschedules, decline requests, trigger pushes and join calls. The Android peer for item 14 (BOOK-20 Android) must be a debug or release build at or after the 03-15 commit.
- **Backend deploy state (plan 03-05):** **deployed.** Backend commit `65bb2ed` has been live in production since 2026-11-10 (`/health` reports `65bb2ed`). `GET /expert/bookings/:id/details` returns `payment_action_required`, `payment_action_deadline` and `payment_not_charged`. If a build or a backend rollback ever lacks those keys, the expert cancel sheet fails closed (D-14): it shows **no client-money line on any booking**, so item 16 would read as "no money line anywhere" instead of its normal cases.
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date.

## Notes before you start

- **Phase 2's UAT is still outstanding.** `02-UAT.md` tests 6-17 have not been run and must run before Phase 8. Phase 2's checklist (`02-DEVICE-UAT-CHECKLIST.md`) said push-opened screens might have inert Join, Cancel, Reschedule and Leave Review buttons until Phase 3. They are wired now: items 6, 8, 9 and 11 cover them.
- **BACK-19's production smoke has not been run** (Phase 1 plan 01-19, skipped by user decision 2026-11-08). The EXP-11 expert copy promises BACK-19's behavior (an expert cancel always fully refunds or releases the client), so it is **code-verified only**. Reversibility is costly (D-07): if the smoke finds a problem, the iOS copy and Android's change together. Note the smoke result next to item 16.
- **K2 is resolved by D-15.** UI-SPEC K2 (the Skype/Zoom layout has no overtime banner) is closed: the end + 55 "This call will end in 5 minutes" notice now shows on the Skype/Zoom layout. Item 17 checks it.
- **Phase 2's BOOK-14 item changes.** The Phase 2 BOOK-14 item expects the expert reschedule picker unchanged. Plan 03-04 now caps it at 6 days for paid bookings (Phase 2 D-13). Run that Phase 2 item against the capped behavior; item 18 below is the check for the cap.
- **Two taps to open a Skype/Zoom meeting (D-10).** From Upcoming details, "Open in {provider}" opens the session screen, then "Open" there launches the meeting app. Judge on device whether two taps reads acceptably (RESEARCH Open Question 6).
- **The join-failure alert may present from the root screen (RESEARCH A1).** The "Couldn't join call" alert is attached on Upcoming details and at the My Bookings root. Confirm one alert shows, not two or none.
- **The cancellation comment is shown to the expert and the field label does not say so (RESEARCH Open Question 4, assumption A5, threat T-03-19 accepted).** The label "Additional Comments (Optional)" is locked by the UI-SPEC. Judge whether a client should be told.
- **A confirmed cancel from a push-opened screen returns two levels (03-12 assumption).** A cancel confirmed on a screen opened from a push tap, a chat row, the Explore today strip or the Payments list returns to whatever opened the cancelled booking's details. A cancel started from My Bookings still returns to the My Bookings list root.
- **Android keeps "Accept" and "New time proposed".** The Android copy differs from iOS's "Accept New Time" and "Expert requested a new time"; logged copy difference, not a failure.
- **No pending todo was folded into this phase (D-12).** All three matched on keywords only.
- **Items marked *optional* are covered by unit tests** and may be skipped.

---

## Items

### 1. BOOK-06 — accept and decline a proposed reschedule (03-01, 03-06, 03-13)

**Status:** PENDING (tracer device checks deferred under the standing approval of 2026-11-10).

Steps:
1. As B on the second device, propose a new time for a confirmed booking with A. As A, open the booking from **My Bookings** (Upcoming details). Tap Accept New Time, then confirm.
2. Repeat from a **push tap** ("new time proposed") so the same Upcoming details opens from the notification.
3. Propose again and tap **Decline New Time** with a long reason that contains emoji. Confirm.
4. **Payment-conversion disclosure case:** use a paid booking whose hold is at least 2 days old and have B propose a start about 5 days out, so the new end falls after the hold's 6-day window. Open the confirmation dialog. (Reuse this booking for item 16.)
5. **Booking Summary:** with a proposal pending, open the booking's Booking Summary and accept or decline once from there (the responder moved onto Booking Summary in plan 03-13). A `booking.update` while the screen is open (B changes the proposal from the second device) should update the content in place.
6. A failed accept (B cancels the booking first) shows the alert.

Expected:
- The card reads "Expert requested a new time" with Accept New Time and Decline New Time (44 pt buttons).
- Accept shows "Accept the proposed reschedule?" with Accept New Time / Keep Current Time. After confirming, the card disappears, the date and time change **in place with no spinner flash**, the screen stays on Upcoming details, and the toast **"Reschedule accepted"** shows.
- Decline asks for an optional reason (Decline New Time / Keep session as-is). Afterward the original time stays and the toast **"Reschedule declined"** shows. The emoji reason succeeds.
- The payment-conversion case shows the disclosure text in the dialog, the same on Upcoming details and Booking Summary.
- Booking Summary accept or decline shows the **same "Reschedule accepted" / "Reschedule declined" toast** (the 03-06 toast reached through the 03-13 responder move).
- A failed accept or decline shows "Couldn't update booking", dismissed by "Back to Booking", and no toast.
- **WR-01 (03-16):** the card is cleared as soon as the server accepts or declines, before the refetch, so it also disappears when that refetch fails; the date, time and status pill then update on the next successful fetch. A phone cannot fail only the follow-up request on demand, so this edge is proven by unit tests (`RescheduleResponderTests`, `UpcomingBookingViewModelTests`, `BookingSummaryViewModelTests`) and has no device step. The Expected lines above are unchanged on the normal path.

Result: FAIL (2026-11-19, backend) — the push A receives when B proposes a new time says "booking has been rescheduled"; it should read as a reschedule request. Source: backend `src/services/events.js` `BOOKING_RESCHEDULED` push (title "Booking Rescheduled", body "A booking has been rescheduled."). Gap G-03-1-ITEM1 in 03-UAT.md.
FAIL (2026-11-19, step 3) — the decline with an emoji reason goes through, but B never sees the reason: no screen shows it and it is not added to the chat. Backend stores it in `decline_reason_text` but only exposes that column for `declined` bookings, and the reschedule-decline event carries no reason. Gap G-03-1-ITEM1B in 03-UAT.md.
Rest of item 1 PASS (2026-11-19): accept, decline toast, payment-conversion disclosure, Booking Summary parity and in-place update, failed-accept alert.

### 2. BOOK-07 — cancellation comment is sent with the reason (03-10)

**Status:** PENDING.

Steps:
1. As A, cancel a booking and type a comment with emoji in "Additional Comments (Optional)". Keep typing past the limit.
2. As B, open that booking's Booking Summary.
3. Open the cancel screen at the largest accessibility Dynamic Type size (counter and field).

Expected:
- The counter stops at 450 characters without cutting an emoji in half.
- B's Booking Summary shows the cancellation as "label: comment".
- The counter and field wrap without clipping at the largest size.
- **Comment-visibility note (threat T-03-19, accepted, RESEARCH A5):** the comment is stored (BACK-14) and shown to the expert on `GET /expert/bookings/{id}/summary`. The field label is locked and does not tell the client. Record your judgment in Result.

Result: PASS (2026-11-19). No comment on the label-visibility judgment; label kept as locked.

### 3. BOOK-08 — cancel preview and post-cancel toast match the server refund (03-02, 03-10)

**Status:** PENDING. Touches real holds and refunds.

Steps and expected (compare each confirm-step line and each toast with the refund shown in the Payments list):
1. **Live hold, cancelled:** lock icon and "The {amount} hold on your card will be released, so you won't be charged." No refund footnote. After confirming, toast "The {amount} hold on your card is being released."
2. **Charged booking more than 24 h out** (captured, or held and past the T-24h charge): "Refund: {amount}, cancelled more than 24 hours before the start" plus the "Refunds typically appear..." footnote. Toast "{amount} will be refunded to your card."
3. **Charged booking inside 24 h:** the amber block "Refund: {zero}" with "the session starts within 24 hours", no footnote. Toast "No refund applies because the session was within 24 hours."
4. **Never charged** (payment status none, or a failed T-24h charge awaiting card authentication; skip if none can be found): "You haven't been charged for this session, so nothing will be charged."
5. The amount is semibold in the primary text colour, never green.
6. *Optional:* keep the confirm step open across the 24 h line on a charged booking. The line turns into the amber block, the first Confirm Cancellation tap shows "The session now starts within 24 hours, so your refund has changed..." and submits nothing; the second tap cancels.
7. A failed cancel shows "Couldn't cancel booking" with the server's message and "Review Cancellation"; the confirm step stays.
8. Cross the 24 h line with two bookings and compare toast and refund (VALIDATION manual item).
9. The toast survives the pop to My Bookings and sits above the tab bar.
10. **WR-02 (03-17):** if a cancel the confirm step showed as refundable ('Refund: {amount}, cancelled more than 24 hours before the start') ends with the toast 'Booking cancelled. Any refund due will follow our cancellation policy.', the server returned refund_amount 0: the phone clock was behind the server's at the 24 h line, a refund is being retried, or the booking was already cancelled. That toast is expected for those cases and names no amount. Record which case it was and compare with the Payments list. The edge is proven by unit tests (`CancelToastMessageTests`, `ClientCancellationViewModelTests`). Do not change the phone clock to force it, because on a real captured booking that forfeits the refund.

Result: PASS (2026-11-19).

### 4. BOOK-09 — Upcoming details status pill shows the real status (03-14)

**Status:** PENDING.

Steps:
1. Open Upcoming details for a pending-approval booking, a confirmed booking and a pending-reschedule booking.
2. From the Payments list, open a booking that was cancelled.
3. Turn VoiceOver on and focus the pill and ID row. Repeat at the largest accessibility Dynamic Type size.

Expected:
- Each pill reads its real status, not a fixed "Confirmed".
- The pill and ID row read as **one VoiceOver element** and stay readable at the largest size (UI-SPEC L2).

Result: SKIPPED (2026-11-19) — "Skip item 4 due to voiceover. Not testing voiceover." Whole item skipped, including the non-VoiceOver status-pill and Dynamic Type checks.

### 5. BOOK-11 — Past tab empty state (03-11)

**Status:** PENDING.

Steps: sign in as an account with no past bookings and open My Bookings, Past tab. Then force a failed load (airplane mode, pull the list).

Expected:
- Illustration, "No past bookings yet", body text, no button.
- A failed load shows "Couldn't load bookings", never the empty state.
- The empty state is not scrollable, so there is no pull-to-refresh on it; the same holds for the existing Upcoming empty state. Judge whether that is acceptable.

Result: PASS (2026-11-19). No pull-to-refresh on the empty state accepted.

### 6. BOOK-12 — Keep Booking returns one level (03-11, 03-12)

**Status:** PENDING.

Steps:
1. From **My Bookings**, open an upcoming booking, tap Cancel, then Keep Booking.
2. Tap a booking **push** to open Upcoming details, tap Cancel, then Keep Booking.
3. Repeat once from a **chat system-event row**, from the **Explore today strip**, and from **Profile > Payment history** (a future booking). On the Payments path the details screen now sits on the Profile tab's path.
4. Confirm a cancel from a push-opened screen.

Expected:
- Keep Booking goes back **one level** to Upcoming details in every case (BOOK-12).
- A confirmed cancel from My Bookings lands on the My Bookings list. A confirmed cancel from a push-opened, chat-opened, Explore-opened or Payments-opened screen **pops two levels, past the cancelled booking** to the screen that opened it, with the post-cancel toast (03-12 assumption).

Result: PASS (2026-11-19).

### 7. BOOK-13 — Cancel and Reschedule visibility by status and time (03-09)

**Status:** PENDING.

Steps: open a booking whose session has ended (from the Payments list) and one in progress. Open a confirmed future booking. Leave a booking open across its end time.

Expected:
- Ended and in-progress bookings show **neither Cancel nor** a stale Reschedule; Reschedule fills the row when it is the only action.
- A confirmed future booking shows both.
- Cancel disappears within a minute of the end time without leaving the screen.
- Pending-approval and pending-reschedule bookings still show Cancel before their end (D-13).

Result: PASS (2026-11-22).

### 8. BOOK-16 — reschedule returns one level with a toast (03-11, 03-12)

**Status:** PENDING.

Steps:
1. From Upcoming details in **My Bookings**, and from a My Bookings card, reschedule a booking to a new time.
2. From a **push tap**, a **chat system-event row** and **Payments**, open Upcoming details and reschedule from there.
3. With a held paid booking, pick a time the backend cannot convert. With no saved card, try a reschedule that needs one.
4. Set the largest accessibility Dynamic Type size and trigger the error alert.

Expected:
- The app returns to the screen where Reschedule was tapped (not the My Bookings root), **"Reschedule request sent"** shows above the tab bar, and the status pill there reads Pending reschedule after the refetch.
- The booking's own current time is not greyed in the picker.
- The unconvertible time shows the RESCHEDULE_OUTSIDE_AUTH_WINDOW copy, wrapping cleanly; with no saved card the alert says "Profile > Payment".

Result: PASS (2026-11-22).

### 9. BOOK-17 — Leave a Review on completed sessions only (03-07, 03-12)

**Status:** PENDING.

Steps:
1. Open a completed past session without a review from **My Bookings**: Leave a Review shows and opens the form.
2. Tap a **review-nudge push** for a completed session: Leave a Review shows and opens the form on that tab.
3. Open the same booking from a **chat system-event row** and tap Leave a Review.
4. Open a cancelled booking and a missed one: no Leave a Review.
5. Submit a review, then reopen the summary.

Expected:
- Leave a Review opens the review form from every entry above, for completed sessions only (BOOK-17).
- No Leave a Review on cancelled, missed or already-reviewed sessions.
- Book Again, Message and Private Note on a **push-opened** Booking Summary stay inert; they are out of scope (RESEARCH Open Question 2) and not a failure.

Result: PASS (2026-11-22).

### 10. BOOK-20 (iOS) — booking ID line (03-07)

**Status:** PENDING.

Steps: open Booking Summary for a past session. Long-press the ID. Open Upcoming details for the same booking and compare.

Expected: the line "ID: #A1B2C3D4" (first 8 characters, upper-cased) is the last line of the topic section, can be selected and copied, and **matches** the ID on Upcoming details for the same booking.

Result: PASS (2026-11-22). The Upcoming details ID is not copyable on a long-press; the user confirmed it does not need to be.

### 11. CALL-03 — JOIN CALL works on every Upcoming details entry (03-09)

**Status:** PENDING.

Steps:
1. Open an in-app booking's Upcoming details from My Bookings and from a **push tap** inside the join window; tap JOIN CALL.
2. Repeat from a **chat row**, the **Explore today strip** and the **Payments list**.
3. An hour and a half before the start, check the button (and with VoiceOver, the hint).
4. Open a booking in `pending_reschedule`.
5. Trigger a failed join (for example while already on another call).

Expected:
- JOIN CALL starts the call from every entry.
- Early: the button is dimmed and VoiceOver reads the hint. On a pending reschedule it is visible and disabled.
- A failed join shows **one** "Couldn't join call" alert (RESEARCH A1: the alert is attached on this screen and at the My Bookings root; when pushed from My Bookings both are in the hierarchy, so confirm it is not shown twice or missed).

Result: PASS (2026-11-22). Free in-app voice booking; VoiceOver hint not checked (user does not test VoiceOver).

### 12. CALL-06 — Skype/Zoom status line promises no automatic end (03-03)

**Status:** PENDING.

Steps: on a Skype/Zoom session, tap Open on the session screen and return to the app.

Expected: the status reads "Meeting in progress. Scheduled to finish at {end}. Tap End Session when you're done."

Result: SKIPPED (2026-11-22) — "no skype/zoom app" on the test iPhone.

### 13. CALL-07 — Skype/Zoom session timer matches the in-app layout (03-03)

**Status:** PENDING.

Steps: open a Skype/Zoom session early, then keep it open through the start and into the last 5 minutes.

Expected: the hero reads "Starts in M:SS", counts up after the start, and turns amber with an "M:SS left" chip in the last 5 minutes.

Result: PASS (2026-11-22).

### 14. BOOK-20 (Android) — booking ID line on Android (03-15)

**Status:** PENDING. Android device.

Steps: on an Android device, open a client Booking Summary and compare with iOS for the same booking.

Expected: "ID: #…" appears under the price and **matches** the ID iOS shows for the same booking (item 10).

Result: PASS (2026-11-22). The ID matches iOS. Found while comparing: on a free session, iOS Booking Summary has no price row, while Android shows "Free". The user wants iOS to show "Free"; logged as gap G-03-1-ITEM14 in 03-UAT.md.

### 15. CALL-08 / D3 — Open in {provider} reaches the Skype screen; End Session completes the booking (03-09)

**Status:** PENDING. UI-SPEC backstop D3 (needs a Skype/Zoom booking on a real iPhone).

Steps:
1. On a Skype/Zoom booking inside the join window, tap Open in {provider} on Upcoming details.
2. Confirm the session screen's timer runs, tap Open there, then End Session.

Expected:
- Open in {provider} opens the Skype/Zoom session screen with the **timer running**; Open there launches the meeting app; End Session completes the booking and `/end` is reported.
- **Two-tap note (D-10, RESEARCH Open Question 6):** it takes two taps. Record whether that reads acceptably.

Result: PASS (2026-11-22). The Open-in-meeting-app tap was not run (no Skype/Zoom app); the two taps were accepted.

### 16. EXP-11 — expert cancel sheet states the client's money outcome (03-08, backend 03-05)

**Status:** PENDING. **Backend deploy state: deployed** (`65bb2ed`, 2026-11-10), so the cases below apply. **BACK-19's production smoke has not been run**: this copy is code-verified only (D-07 costly).

Steps: as B, open Cancel (the Booking Summary cancel sheet and any other path into `ExpertCancellationView`) on:
1. A **live-hold** booking.
2. A **captured** booking.
3. A **free** booking.
4. A booking **converted to long-lead by an accepted reschedule** (reuse the item 1 payment-conversion booking: a paid booking whose hold is at least 2 days old, moved to a start about 5 days out so its end falls after the hold's 6-day window, then opened from the expert account).
5. If one can be found, a booking whose T-24h charge is **waiting on card authentication** (D-14).
6. A legacy booking with a captured PaymentIntent but a null `payment_status`, if one exists.

Expected:
- Live hold: "The client's CA$... hold will be released." with a lock icon and **no footnote**.
- Captured: "The client will get a full refund of CA$..." plus the 3-5 business days footnote.
- Free: no money line, no footnote.
- Converted to long-lead (D-16): **no client-money line and no footnote.**
- Waiting on card authentication (D-14): no money line.
- Legacy null `payment_status` with a captured PaymentIntent: reads `payment_not_charged: true` on the backend and loses its line (a missing line, never a wrong claim); acceptable.
- **Fail-closed state (D-14):** before the 03-05 deploy, or against a backend lacking the keys, no booking would show a money line. Not expected now that `65bb2ed` is live; record only if you see it.
- Note the BACK-19 smoke result here once it is run.

Result: PASS (2026-11-22). BACK-19 production smoke: still unrun (copy remains code-verified for the backend side).

### 17. D-15 / K2 — end + 55 notice on the Skype/Zoom layout (03-03)

**Status:** PENDING. Needs a session held to 55 minutes past its end. Resolves UI-SPEC K2.

Steps: keep a Skype/Zoom session open until 55 minutes after its scheduled end, or rejoin a completed one inside its reconnect tier just before then. Also check an in-app voice session.

Expected:
- The amber **"This call will end in 5 minutes"** notice appears at the top of the Skype screen, and the session ends at end + 60.
- The in-app voice banners read as before.

Result: SKIPPED (2026-11-22). The user skipped it; it needs a session held open 55 minutes past its end.

### 18. EXP-13 — expert reschedule wiring and 6-day paid cap (03-04)

**Status:** PENDING. Supersedes the Phase 2 BOOK-14 item's "picker unchanged" expectation.

Steps:
1. As B, from the **Bookings tab** and from **Dashboard > calendar**, tap Reschedule on a card, pick a time and submit.
2. Open Reschedule on a **paid (CAD)** booking, then on a **free** booking.

Expected:
- The form closes back to the list **on the same tab** on both tabs.
- Paid: every day is visible, the note **"Paid sessions can be rescheduled up to 6 days ahead."** shows under Time Slots, and chips after now + 6 days are dimmed and untappable.
- Free: no note and no dimming from the cap.

Result: PASS (2026-11-22).

### 19. CALL-10 / D4 — expert Join Session from Booking Summary across two accounts (03-04)

**Status:** PENDING. UI-SPEC backstop D4 (two accounts and a device).

Steps:
1. As B, open Booking Summary for a booking inside the join window; A joins from the client side.
2. Open one outside the window and one in `pending_reschedule`.
3. Trigger a refused join.

Expected:
- Join Session is the accent button above an outlined Message Client; tapping it connects both parties.
- Outside the window it is dimmed; on a pending reschedule it is visible and disabled.
- A refused join shows "Couldn't join call" **once** (the Bookings and Dashboard roots host an alert on the same `joinError`; SwiftUI presents one).

Result: PASS (2026-11-22).

### 20. BACK-02 (iOS) — decline note on the client's Booking Summary (03-07)

**Status:** PENDING.

Steps: as B, decline a request with a reason and a long note (up to 1000 characters). As A, open the declined booking's Booking Summary.

Expected: the DECLINE NOTE card sits between the expert card and My Note, shows the reason line and the full note wrapped, uses neither the accent nor amber, and the badge still reads **Cancelled**.

Result: PASS (2026-11-22).

### 21. D2 — toast placement, dismissal and VoiceOver (03-06)

**Status:** PENDING. UI-SPEC backstop D2.

Steps: accept a proposed time on Upcoming details (with and without the keyboard up), then cancel a booking. Repeat with VoiceOver and with Reduce Motion on.

Expected:
- The toast appears about 24 pt above the tab bar for about 4 seconds, a tap dismisses it early, and it **does not cover** the Accept New Time / Decline New Time buttons or the keyboard.
- VoiceOver reads it.
- A multi-line message wraps cleanly; with Reduce Motion it only fades.

Result: PASS (2026-11-22). VoiceOver part not run (user does not test VoiceOver).

### 22. L2 — Dynamic Type at the largest accessibility size (03-01, 03-02, 03-03, 03-06, 03-11)

**Status:** PENDING. UI-SPEC backstop L2.

Steps: set the largest accessibility size and open each new block: the reschedule response card (with a long expert note) and its 44 pt buttons, the amber warning block and money line on the cancel confirm step, a multi-line toast, the Skype status line and timer block, and the Past empty state body.

Expected: every block wraps, nothing is clipped, no fixed height, and the 44 pt buttons keep that minimum.

Result: PASS (2026-11-22).

### 23. L3 — "Open in Microsoft Teams" on the smallest iPhone (03-09)

**Status:** PENDING. UI-SPEC backstop L3. Use the smallest supported iPhone.

Steps: open a Teams or Google Meet booking's Upcoming details inside the window.

Expected: "Open in Microsoft Teams" (and "Open in Google Meet") stays on **one line**, scaling down only if it would otherwise truncate.

Result: SKIPPED (2026-11-22). The user skipped it (needs the smallest iPhone and a Teams or Google Meet booking).

### 24. Expert shell chat-row item — no client actions, no blank screen (03-12)

**Status:** PENDING. Added in the 03-12 checker revision.

Steps:
1. In **expert mode**, open a chat with a client and tap the system-event row of an **upcoming** booking.
2. Tap the system-event row of a **completed** booking.
3. Tap Back each time.

Expected:
- The client Upcoming details shows **no Cancel and no Reschedule**; the client Booking Summary shows **no Leave a Review**; **no tap opens a blank screen** (the expert shell stubs the three new routes and sets `hostsClientBookingFlows` to false).
- Join (03-09) is unchanged.
- For a booking the user is the **expert** on, the client screen may show its load error ("Couldn't load booking"), because the client endpoint returns 404 for a booking the user did not book as a client. This is pre-existing and outside Phase 3: note it in Result without failing the item.
- A dual-role user's own client booking opened this way loads, and still shows no client actions in the expert shell.

Result: PASS (2026-11-22).

### 25. T-03-23 — declining a reschedule shows the booking's restored status (quick 261122-tcf)

**Status:** PENDING. Added by quick task 261122-tcf.

Steps:
1. On a booking that is **Pending approval**, user B proposes a new time from the second device, and user A taps **Decline New Time** on Upcoming details. If neither app lets B propose a new time on a pending request, use a **completed** session whose original end time has not passed.
2. Repeat on a **Confirmed** booking.

Expected:
- Step 1: the "Reschedule declined" toast, the proposal card gone, and the status pill showing that booking's earlier status (Pending approval, or Completed), **never Confirmed**. Join follows that status.
- Step 2: the pill reads Confirmed.
- If step 1's booking cannot be set up, record SKIPPED (why) for that step only.

Result: PASS (2026-11-22).

### 26. WR-10 — expert Message errors and second taps; 44 pt reschedule buttons (quick 261122-tcf)

**Status:** PENDING. Added by quick task 261122-tcf.

Steps:
1. As user B on the expert Booking Summary, double-tap **Message Client**.
2. In airplane mode, tap **Message Client**.
3. Repeat steps 1 and 2 from a Bookings-tab Upcoming row's Message and from a pending request's Request Decision Message.
4. On a booking where A proposed a new time, open the expert Booking Summary.

Expected:
- Step 1: one chat opens, one Back returns, and a spinner shows with the button disabled while the request runs.
- Step 2: a "Couldn't start chat" alert with a readable message, and OK dismisses it.
- Step 3: the same single open and the same alert (no spinner on these two).
- Step 4: Decline and Accept are at least 44 pt tall and easy to hit, and the labels are unchanged.

Result: PASS (2026-11-22).

### 27. G-03-1-ITEM14 — Booking Summary price row reads Session fee · Free for a free session (03-18)

**Status:** PENDING. Added by plan 03-18. Needs a build at or after the 03-18 commit, built and run from Xcode.

Steps:
1. As user A, open My Bookings, then Past, then a **free** session, to open its Booking Summary.
2. Open the Booking Summary of a past **paid** CAD session priced with cents (for example 12.50).
3. Optional: open the same free session on Android and compare.

Expected:
- Step 1: the topic section shows the row Session fee · Free, above the ID line: the label Session fee in the small grey caption, and the value Free in green. Before 03-18 this row was missing.
- Step 2: the row reads PAID · {amount} (for example PAID · CA$12.50) exactly as before: same PAID label, same color, cents kept. It does not read Session fee.
- Step 3: Android shows the same row for the same booking: Session fee with the value Free.
- After the Xcode build, ClickMe2026/Localizable.xcstrings has Free and Session fee entries (Xcode adds them on an IDE build). Leave the file unstaged: plan 08-20 commits the catalog.
- A paid topic with no price from the server, which reads PAID · —, cannot be set up on a device and is covered by BookingSummaryViewModelTests.

Result:

---

## Sign-off

- [ ] All items above have a Result. (items 1-26 on 2026-11-22; item 27 added by 03-18, pending)
- [x] Item 16 notes the BACK-19 smoke result (still unrun).
- [ ] Phase 2 `02-UAT.md` tests 6-17 run before Phase 8.
- [ ] Failures logged as gaps for a `/gsd-plan-phase 3 --gaps` pass.
