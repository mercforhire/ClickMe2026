# Phase 8 TestFlight Regression Checklist

The one device run that stands behind the release. It is run on **build 1.1 (7) from internal TestFlight**, against the production backend with live Stripe, with an Android phone as the other party (D-04, D-20). It covers the core paths (book, pay or free, join, run past the scheduled end, finish) for three sessions, the real-money smokes that never ran for BACK-06, BACK-07 and BACK-19 (D-06, D-27), the chat-reason rows and the reschedule-decline push (D-31), and the carried-over device items (D-28). The Phase 3 items 7-24 and Phase 4's 20 skipped UAT tests are not run on a device: they are covered by unit tests plus this run, and they are listed by number in `08-RELEASE-RECORD.md` (D-01).

Claude runs only local tests and builds. Every production step (booking, paying, the Supabase queries, the Stripe Dashboard) is yours. Claude never runs production SQL and never clicks anything in the Dashboard.

Plan 08-22 reads this file when you are done. It needs exactly one `Result:` line per item R1 to R11, and every R item gates the submission. The Android section at the end does not gate the iOS submission.

## Setup

- **iPhone:** a real iPhone on iOS 18 or later, with **TestFlight build 1.1 (7)** installed from the internal testers group only (D-20). Not the simulator, and not the App Store build 6. Check the version and build number in TestFlight before you start. Push notifications must be allowed for the app.
- **Android peer:** an Android phone as the other party. For the sessions S1 to S3 and the money steps it can run the current Android build. For R7 and R8 the Android phone must show the Phase 8 changes (reason rows, `US$` and `CA$`), which exist only in a dev build from `ClickMe_Android` `main` at or after `e311a74c` (the Phase 8 Android commits were local and not on the Play build when this checklist was written). On an older Android build, record the Android half of R7 and R8 as `SKIPPED (Android build predates the Phase 8 commits)`. Do not record it as a failure. The Android section at the end always needs the dev build.
- **Accounts:**
  - **A** is your client account, on the iPhone.
  - **B** is your expert account, on the Android phone. B needs a **paid CAD topic priced with cents** (the cheapest you have, with the shortest duration), a **free topic**, a **USD topic** (never booked, for R8 only), and a **meeting link** in its expert settings (a Zoom or Skype link, for R3).
  - **C** is a **fresh, unpublished expert signup** with an email you can open (for R10). Never publish it.
- **Backend:** the frozen backend SHA is recorded in `08-RELEASE-RECORD.md`, section `## Backend deploys` (filled by plan 08-18). Before you start, `/health` must report that SHA. If it reports another commit, stop and tell Claude: the run would test the wrong backend.
- **Stripe Dashboard and Supabase SQL editor:** open and signed in. The only Dashboard action this checklist allows is looking and, where a step says so, cancelling an **uncaptured** payment. Never click Capture or Refund.
- **Network Link Conditioner (optional):** only R10's slow-network pass uses it. If it is not available, mark that part `SKIPPED (why)` inside the R10 Result line.
- **Recording results:** write one `Result:` line per item: `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, plus the date. An empty Result means the item was not run, never that it passed. Do not write a `pm_` id, a client secret, an ephemeral key or a card number anywhere in this file. For a PaymentIntent write only the last six characters of its `pi_` id. Keep clone ids, `pm_` ids and anything secret in your own notes.

## Rules

- **One hold at a time.** After every paid booking's check, release it (cancel it, or let B cancel it, as the item says) and **prove the hold is gone from Stripe** before the next paid booking. The app reports success even when the void failed. On the Dashboard: Connected accounts, B's account, Payments: the PaymentIntent shows **Canceled**, nothing captured or refunded.
- **S1 is the only booking allowed to capture.** S2 and S3 are on free topics, so they place no hold and no charge.
- **Side bookings** are the bookings made only for a check (R6, R7). Each one starts **2 to 5 days from now** (a paid slot more than 6 days out is refused). They never share a slot with each other or with S1, S2 or S3. A side booking is **never joined**. A paid side booking is **never rescheduled**: a reschedule can void a hold and convert it to a charge. R7 proposes reschedules only on **free-topic** side bookings and always has them declined, so no booking is ever actually rescheduled. A connected call moves a booking to `in_progress`, which a client cannot cancel and which is captured at end + 15 minutes, so never join one.
- **S1, S2 and S3 each start soon.** Pick the first free slot after you are ready, so you are not waiting long to join.
- **Run order.** The items are numbered by topic, not by order. Run them in this order so no step needs something an earlier step removed: R4, R6, R1, R2, R3, R5, R7, R8, R10, R9, R11. R5 comes after S1 because it needs the clone that S1 created, and it removes the card, so nothing paid can follow it. R9 swaps roles, so it goes last before the end-state check.
- **Do not use a second account for a check unless the item says so.** A is always the iPhone client and B is always the Android expert, except in R9.

## Stop conditions

- **S-A, an error after you paid, or an uncaptured payment on B's connected account with no booking.** The backend does not void the PaymentIntent when a confirm fails with no replay, and the app cannot release it. Cancel that payment yourself in the Dashboard, write it in the R11 table as an orphan hold, and tell Claude. Look for orphans after **every** paid booking that showed an error.
- **S-B, any payment other than S1's own capture shows Succeeded, Captured or Refunded.** Stop. Click nothing. Tell Claude at once: that is a real charge this run must never cause.
- **S-C, a side booking shows `in_progress`, or its end time passes.** Stop and tell Claude: the cancel will be refused and a capture may follow at end + 15.
- **S-D, a cancel returned success but the PaymentIntent is still uncaptured.** A sweep retries every 30 minutes. Wait one sweep and look again. If it is still uncaptured, cancel it in the Dashboard and tell Claude. Trust the Dashboard over `payment_status`.
- **S-E, a step fails in a way the 01-17 or 01-19 text covers** (`.planning/phases/01-backend-fixes/01-17-SUMMARY.md` and `01-19-SUMMARY.md`, Task 2 part B). Follow that stop condition, except any instruction to roll back to an old SHA: those SHAs are out of date. Stop and tell Claude for those.

**D-09, what a failure means for the submission.** Any failed real-money check (R1, R4, R5, R6, R11, and any step that placed a hold or a charge) **stops the submission**. Then:
1. If the fault is backend-only, deploy a backend fix (with the user's approval of that deploy) and rerun **only that check**.
2. If the fault is in iOS, a new build is needed and the **full regression is run again**.
3. Write the failure in that item's Result line. Do not edit or delete a failed Result to make the run look clean.

## Queries

Read-only, run in the Supabase SQL editor. Claude does not run them. Replace `<client email>` with A's email.

**Q1, the booking:**
```sql
select id, status, payment_status, stripe_payment_method_id, payment_intent_id, stripe_account_id, refund_failed
from bookings
where client_id = (select id from auth.users where email = '<client email>')
order by created_at desc limit 1;
```

**Q2, the clone** (replace the `pm` id with `stripe_payment_method_id` from Q1). Run it **before** a card is removed and save all three values in your own notes, because removing the card deletes the only record of the clone:
```sql
select clone_payment_method_id, connected_account_id, connected_customer_id
from connected_pm_clones
where platform_payment_method_id = '<pm id from Q1>';
```

## Items

### R1. S1: paid in-app voice session, book, pay, join, run past the end, finish (D-04, D-08, D-28, PAY-02, CALL-01)

**Requirements and decisions:** REL-01, D-04, D-08, D-28. This is the only booking in the run that may capture: a small real CAD charge.

Steps:
1. Precondition: A has exactly one saved card (R4), and R6 is finished with its hold released. As A on the iPhone, open Make a Booking for B's **cheapest paid CAD topic with cents, at its shortest duration**, and pick a slot that **starts soon** (this is the one booking that is joined).
2. Tap **Book Now**, then **Continue** in the card sheet with the saved card. Complete 3-D Secure if asked. Watch **Confirming your booking…** and Request Sent.
3. Run Q1. `status` is `pending_approval` and `payment_status` is `requires_capture`. Write the last six characters of `payment_intent_id` in the R11 table. If a confirm timeout happens to occur (the alert **We couldn't confirm your booking**), do not force it and do not hide it: note what the app did and which button you tapped (D-08, PAY-02), and check that there is still exactly one booking and one hold.
4. On the Android phone as B, **accept** the booking. Run Q1: `confirmed`, still `requires_capture` (accepting does not capture).
5. At the start time, A taps **JOIN CALL** on Upcoming details and B joins from Android. Talk for about 30 seconds each way and confirm you hear each other.
6. **Keep both phones in the call past the scheduled end.** On the iPhone, at **end + 55** the notice appears ("This call will end in 5 minutes"). Note the time it appeared.
7. At **end + 60** the iPhone ends the call by itself and shows **Ended**.
8. **Keep the Android call open and keep watching until end + 65:** does Android tear itself down when the server sends `call.ended` (D-28)? Note yes or no and the time.
9. Finish: the booking moves to completed in My Bookings (Past) on the iPhone, with no call screen left open.
10. Capture can arrive at the finish or up to end + 15 minutes after it. Wait for it, then run Q1 and look at the Dashboard (B's connected account, Payments).

Expected:
- The notice shows at end + 55 and not before. The call is still connected at end + 10, so the old 5-minute cutoff is gone.
- The call ends by itself at end + 60.
- Q1 and the Dashboard show **exactly one** capture for this booking: one PaymentIntent, Succeeded, for the topic price, with no refund and no second payment.
- Nothing else in the run has captured.

Write the Android `call.ended` observation as a note **inside** this item's one Result line, after the status, for example `PASS (2026-11-24); Android tore down at end + 61`. Do not add a second Result line.

Result: SKIPPED in part (2026-11-23): booking, pay (no confirm alert), hold, accept, JOIN CALL, two-way audio and the single capture PASS (pi ...QJ0AJ8 Succeeded CA$5.00 = topic price, no refund, no second payment; Q1 completed/captured after the end + 15 sweep; Past shows completed); end + 10, end + 55 notice, end + 60 auto-end and the auto-end Android teardown NOT RUN: user ended the call at end + 2 (Android hung up when the call was ended by hand). Topic price had no cents (CA$5.00). Open for the 08-24 ruling: rerun on build 7 or accept CallOvertimePolicy unit tests (cutoff moves to 15 min in 1.2 by user decision 2026-11-23)

### R2. S2: free in-app voice session, book, join, run past the end, finish (D-04, CALL-01)

**Requirements and decisions:** REL-01, D-04.

Steps:
1. As A, book B's **free topic** (in-app voice) in a slot that starts soon. There is **no payment step**.
2. Run Q1 for this booking: `payment_intent_id` is empty and there is no PaymentIntent for it.
3. As B on Android, accept the booking.
4. At the start time A taps **JOIN CALL** and B joins. Talk for about 30 seconds.
5. Stay in the call past the scheduled end: the notice at **end + 55** on the iPhone, the automatic end at **end + 60**, then **Ended**.
6. Finish: the booking shows completed in My Bookings (Past).

Expected:
- No payment sheet, no hold and no charge at any point. Q1 shows no PaymentIntent for the booking, and the Dashboard shows no new payment.
- Join, the end + 55 notice and the end + 60 automatic end behave exactly as in R1.

Result: SKIPPED (2026-11-23): user chose to skip R2 ("skip"); the free in-app voice path and the end + 55 / end + 60 overtime were not run on build 7. Open for the 08-24 ruling together with R1's overtime steps

### R3. S3: one Skype/Zoom session on a free topic, book, join, run past the end, finish (D-04, CALL-06, CALL-07, CALL-08)

**Requirements and decisions:** REL-01, D-04. It uses a free topic so that S1 stays the only capture.

Steps, in this order:
1. As A, open Make a Booking for a **free topic** of B, starting soon, and pick **Skype/Zoom** on the meeting-type card. (B's expert settings must already hold a meeting link, see Setup.) There is no payment step.
2. Run Q1 for the booking: there is no PaymentIntent for it.
3. As B on Android, **accept** the booking.
4. At the start time, A opens Upcoming details and taps join. Check the **provider label**, the **Open in {provider}** button (it opens B's meeting link), and the **elapsed or remaining time**.
5. Stay on the session past the scheduled end. At **end + 55** the banner appears on the iPhone. Note the time.
6. Finish: tap **End Session**. The session screen closes and the booking no longer offers Join.

Expected:
- The status line promises no automatic end (nothing ends the session by itself on this layout).
- The `end + 55` banner shows, **Open in {provider}** opens B's meeting link, and **End Session** closes the screen.
- Q1 and the Dashboard show no payment for this booking.

Result: SKIPPED (2026-11-23): user chose to skip R3 ("skip"); the Skype/Zoom layout (provider label, Open in {provider}, no auto-end promise, end + 55 banner, End Session) was not run on build 7. Open for the 08-24 ruling

### R4. BACK-06: one saved card becomes the default (D-06, BACK-06)

**Requirements and decisions:** BACK-06, D-06. Run this first. It follows `01-17-SUMMARY.md` Task 2 part B steps 2 and 9.

Steps:
1. As A in Settings, open Payment Methods and **remove every saved card**. A card used by a live booking cannot be removed: finish or cancel that booking first.
2. Add **exactly one** card. A bank may show its own brief verification line; ClickMe places no hold.
3. Look at the list: the one card is marked as the default.
4. *Step 9 of the 01-17 checklist, needs a second card:* add a second card, make sure the card you will remove is the default, remove it, then leave Payment Methods and reopen it. The remaining card is now the default. If you cannot add two cards (adding the same card twice is unverified), write `step 9 not run` in the Result line. That logic is covered by unit tests only.

Expected:
- A lone card is the default right after it is added.
- After the default card is removed, the remaining card becomes the default.

Result: PASS (2026-11-23)

### R5. BACK-07: a removed card's clone is detached and cannot be charged (D-06, BACK-07)

**Requirements and decisions:** BACK-07, D-06. Run it **after S1**, because it needs the clone that S1's payment created, and it removes the card (01-17 steps 4, 7 and 8). No charge is attempted on a removed card: the detach is the evidence.

Steps:
1. Run Q1 for S1's booking and note `stripe_payment_method_id` (in your own notes only).
2. Run **Q2** with that id and save all three values (`clone_payment_method_id`, `connected_account_id`, `connected_customer_id`) in your own notes **before** removing the card. If Q2 returns no rows, write that in the Result line and tell Claude: the rest of this item then does not test a real clone.
3. Check that no live booking uses the card (R6's hold is released, S1 is completed).
4. As A in Settings, Payment Methods, **remove the card**. It succeeds and leaves the list.
5. Stripe Dashboard, platform account: the removed card shows no customer.
6. Stripe Dashboard, B's connected account: open the saved `connected_customer_id` and check that its payment methods no longer list the clone. If the Dashboard will not open a payment method by id, the customer view is the check.
7. Supabase: `select count(*) from connected_pm_clones where platform_payment_method_id = '<pm id from step 1>';` returns **0**.
8. If `payment_method.detached` deliveries are visible, look in Dashboard, Developers, Webhooks, the live platform endpoint: a `payment_method.detached` delivery with response 200.
9. Add a card back if you want one saved afterwards (a new `pm` id with no clone until its next paid booking).

Expected:
- The removal succeeds, the clone shows detached on the connected account and is not chargeable, and the count is 0.
- No hold and no charge from this item.

Result: PASS (2026-11-23); Q2 returned the S1 clone row before removal, card removed, clone gone from the connected customer, count 0 afterwards; no hold or charge

### R6. BACK-19 hold release: B cancels a held booking and the PaymentIntent is released (D-06, D-27, BACK-19, BACK-07)

**Requirements and decisions:** BACK-19, BACK-07 (in-use block), D-06, D-27. Run it **before** S1. It follows `01-19-SUMMARY.md` Task 2 part B steps 1 to 4. The captured-refund branch is **not exercised** (D-27): a device cannot force a captured refund. That branch rests on the mocked captured-refund tests, and this item records it as not exercised.

Steps:
1. As A, book B's cheapest paid CAD topic as a **side booking** 2 to 5 days out (a slot that is none of S1 to S3), and pay with the saved card. Complete 3-D Secure if asked.
2. Run Q1: `pending_approval` and `requires_capture`. Write the last six characters of `payment_intent_id` in the R11 table.
3. As B on Android, **accept** it. Run Q1: `confirmed`, still `requires_capture`. If it shows captured, that is S-B.
4. *In-use block (01-17 step 5):* as A in Settings, Payment Methods, try to remove the card. The app shows "This card is linked to an upcoming booking. You can remove it once that booking is completed or cancelled." and the card stays. If the removal succeeds, record FAIL for BACK-07 here, and still do step 5.
5. As B on Android, **cancel** the booking (give a reason if the app offers one).
6. Prove the hold is gone, all of these:
   - Q1: `status` is `cancelled`, `payment_status` is `canceled`, `refund_failed` is not true.
   - Dashboard, B's connected account, Payments: the PaymentIntent shows **Canceled**, with nothing captured or refunded.
   - If not, S-D applies.
7. As A on the iPhone: the booking shows as cancelled and the cancellation push arrived. A missing push is worth noting but does not affect the money.

Expected:
- The hold is released by B's cancel: PaymentIntent Canceled, nothing captured, no charge on your card (a bank's pending line that later drops off is fine).
- The captured-refund branch is not exercised (D-27).

Result: PASS (2026-11-23); pi ...VoLGAu Canceled on the connected account, nothing captured or refunded; in-use card removal blocked; cancel push arrived; captured-refund branch not exercised (D-27)

### R7. Chat reasons, the reschedule-request push and the reschedule-decline push (D-31, G-03-1-ITEM1, G-03-1-ITEM1B, G-03-1-ITEM1C)

**Requirements and decisions:** REL-01, D-31, G-03-1-ITEM1, G-03-1-ITEM1B, G-03-1-ITEM1C. This item also stands in for the blocked Phase 3 device item 1 re-test (push wording, decline reason in chat, decline push recipient). Use **free-topic** side bookings only, so there is no money in this item. Each booking starts 2 to 5 days out, on a slot that is none of S1 to S3 and not another side booking's slot.

Side booking SB1 (a free topic of B):
1. As A, book it and, as B on Android, **accept** it.
2. **Reschedule note, A proposes:** as A, propose a new time **with a note**. The chat row on both phones reads the note, labelled `Note from the client: {text}` (or `Note: {text}`). On Android, B gets a push titled **Reschedule Requested** ("A new time has been proposed for a booking. Open it to respond."), not **Booking Rescheduled**.
3. **Reschedule decline, B declines:** as B, decline the proposal **with a reason**. On the iPhone, as the proposer, check that:
   - a push arrives titled **Reschedule Declined**,
   - tapping it opens the **booking detail** in the right mode on the iPhone (client mode for A),
   - the chat row reads **Reschedule Declined** with the reason, labelled `Reason from the expert: {text}`.
4. **Reschedule decline, A declines (the other direction):** as B, propose a new time with a note. On the iPhone, A gets a push titled **Reschedule Requested** ("A new time has been proposed for a booking. Open it to respond."), not **Booking Rescheduled**. Then as A on the iPhone **decline** it with a reason. The chat row reads **Reschedule Declined** with the reason, labelled `Reason from the client: {text}`, and B on Android is the one who gets it.
5. **Cancel reason:** as A, cancel SB1 **with a reason**. The chat row on both phones reads `Reason from the client: {text}` under the cancelled title.

Side booking SB2 (another free topic slot of B):
6. As A, book it. As B, **decline** the request **with a note**. The chat row on both phones reads the expert's note, and a known decline reason adds its label line.
7. **Message Expert from Session Summary (quick 261122-r2o):** as A on the iPhone, open My Bookings, Past, tap SB1 to open its Session Summary and tap **Message Expert**. The Chats tab opens on the conversation with B, showing B's name and avatar, and no alert shows. Go back to the Session Summary and tap Message Expert again: the same conversation opens and the Chats list has no second thread with B.

For every row above, read it on the **iPhone** and on **Android** (see Setup for the Android build). Check that long text wraps fully, shows as plain text (a link or Markdown in the text is not rendered), and reads well under the title.

Expected:
- All four row types show on both phones: cancel, reschedule note, reschedule decline, request decline.
- A reschedule proposal's push reads **Reschedule Requested** on both phones, never **Booking Rescheduled** (G-03-1-ITEM1).
- The reschedule-decline push reaches the proposer, and its tap opens the booking detail.
- A declined reschedule reads **Reschedule Declined**, not **Booking Declined**.
- Message Expert on a cancelled booking's Session Summary opens the chat with that expert.

Result: PASS (2026-11-23), steps 1-7 as reported by the user ("pass"); covers the blocked Phase 3 item 1 re-test (G-03-1-ITEM1, 1B, 1C) and Message Expert (quick 261122-r2o); Android half on the dev build

### R8. US$ and CA$ prices, and the saved-cards line on Delete Account (D-24, D-23)

**Requirements and decisions:** REL-02, D-24, D-23.

Steps:
1. As A on the iPhone, open an expert profile or Explore showing B's **USD topic** and B's **CAD topic**. Read both prices.
2. Repeat on Android (see Setup for the build).
3. As A, go to Settings, **Delete Account**, up to the **first (confirmation) step** only. **Do not continue and do not delete anything.** Read the screen from the top and tap Back.
4. Repeat step 3 on Android with a **throwaway account only**, never a real account (see the Android section).

Expected:
- The USD price starts with `US$` and the CAD price starts with `CA$`, with the same digits as before and no other change to the amount.
- The Delete Account confirmation step shows the line "Cards you added to pay for sessions are not deleted with your account." after the three groups, and says nothing that claims payment details or bookings are removed.

Result: PASS on iOS (2026-11-23): US$ and CA$ prices, Delete Account cards line; Android dev build FAIL on step 2: the same page shows US$ but the CAD price has no CA$ prefix (Android Money.pinnedSymbol path, todo 2026-11-23-android-cad-price-missing-ca-prefix); Android Delete Account (step 4) PASS. The Android fault is not in the iOS build; 08-24 to confirm it does not gate the iOS submission

### R9. Liquid Glass readability on iOS 26: Availability Save and the Booking Confirmed chevron and title (D-28, EXP-05, EXP-09)

**Requirements and decisions:** REL-01, D-28 (Phase 6 items 13 and 16, ROADMAP backlog 999.4). Needs an iPhone on **iOS 26**, Light appearance. If the iPhone is on iOS 18, write `SKIPPED (iPhone is on iOS 18)`. This item swaps roles, so run it late and on free topics only.

Steps:
1. Sign the iPhone in as **expert B** (log A out first, and log A back in afterwards). Put the Android phone on a client account of yours.
2. *Item 13:* Settings, Accessibility, Display & Text Size, **Reduce Transparency on**. Open **Availability**. Then Reduce Transparency off and Settings, Display & Brightness, Liquid Glass, **Tinted**, open Availability again.
3. *Item 16:* from the Android phone as the client, send B a **free** request in a slot 2 to 5 days out that is none of S1 to S3. On the iPhone, **accept** it and reach the **Booking Confirmed** screen. Look at the navigation bar with Reduce Transparency on, then with Liquid Glass Tinted.
4. Cancel that free booking afterwards. Put the display settings back.

Expected:
- In both settings, the `Save` label and the back chevron on Availability are readable (not white on white).
- In both settings, the back chevron and the `Booking Confirmed` title are readable.

Result:

### R10. Resuming signup keeps the verified email ticked, and the flash on resume (D-28, SIGN-02, U4)

**Requirements and decisions:** SIGN-02, D-28 (Phase 5 items 24 and 45). Use account **C**, a fresh unpublished expert signup. Never publish it.

Steps:
1. On the iPhone, start an expert signup as C and **verify the email** (open Verify email from the setup hub and enter the code). The hub shows Verify email ticked.
2. **Force-quit** the app before publishing, then relaunch and log in mid-setup.
3. Watch the setup checklist as the hub appears: is Verify email ticked, and does the progress ring include it?
4. Repeat steps 2 and 3 once more with the Network Link Conditioner on a slow profile, watching the checklist as the hub appears.
5. Write your decision on the flash (U4): `KEEP` (accept it) or `CHANGE (what)`.

Expected:
- The hub opens with Verify email ticked, and the progress ring includes it.
- At most a brief moment of Verify email unticked before the status read returns (the accepted U4 flash), then ticked, with the ring updating to match.

Result: PASS (2026-11-23); Verify email ticked and counted in the ring after force-quit and relaunch; slow-network pass SKIPPED (not run); U4 flash decision: KEEP

### R11. End state: every hold released, one capture, nothing else charged (D-11, D-06, D-27)

**Requirements and decisions:** REL-01, D-06, D-27. The run passes only when **no hold or charge remains except S1's capture**. Do not close it while a row is open.

Fill one row per PaymentIntent placed in the whole run (R1, R6, and any orphan or stray hold). `pi` is the last six characters only. Write the table in your own notes if you prefer, and copy only the last six characters here.

| Item | Booking (short id) | pi (last 6) | How it ended | Stripe state checked | Date |
|------|--------------------|-------------|--------------|----------------------|------|
| R6 | 1ea3dac8 | VoLGAu | released (B cancel) | Canceled, nothing captured or refunded | 2026-11-23 |
| R1 (S1) | c4c574b4 | QJ0AJ8 | captured once, session completed | Succeeded CA$5.00, no refund, only payment | 2026-11-23 |
| Stray or orphan hold | | | | | |

Then run both of these in the Supabase SQL editor. They cover the whole account, so a row may be an older booking; say which in Result:

```sql
select count(*) from bookings
where client_id = (select id from auth.users where email = '<client email>')
  and payment_status = 'requires_capture';
```
```sql
select id, status, payment_status, refund_failed, payment_intent_id from bookings
where client_id = (select id from auth.users where email = '<client email>')
  and (payment_status = 'requires_capture' or refund_failed = true);
```

Also look at every side booking and every free booking from R2, R3, R7 and R9: cancel any that is still upcoming if you do not want it.

Expected:
- The first query returns **0** and the second returns **no rows**.
- Every PaymentIntent in the table is Canceled (released) except S1's, which shows **one** Succeeded capture. None is still `requires_capture`, and none is refunded.
- No charge on your card other than S1's (a bank's pending line that later drops off is fine).
- Saved cards are how you want them.

Result:

## Android local-build checks (not gating the iOS submission)

Run these on the Android phone with a **dev build from `ClickMe_Android` `main` at or after `e311a74c`**. They are checks of the Android ports of the iOS fixes. They do not gate the iOS submission, and a difference found here becomes a new Android todo, not an iOS blocker. Several of them touch the live production backend, so the items that write data name a **dedicated test account**: never use a real expert's or client's account. Delete Account is irreversible, so it is only ever run on a throwaway account.

### A1. Chat reasons rows (08-03, G-03-1-ITEM1B)

Steps: on the Android phone, read the chat rows from R7: cancel, reschedule note, reschedule decline and request decline.

Expected: each row shows the reason or note labelled by who gave it, a declined reschedule reads **Reschedule Declined**, and an event without reason keys reads as before.

Result:

### A2. US$ and CA$ symbols (08-03, D-24, D-32)

Steps: open a USD topic and a CAD topic (an expert profile and a booking), then change the phone's language or region to a Canadian one and look again.

Expected: USD always starts with `US$` and CAD with `CA$`, whatever the locale. Placement and grouping follow the locale. Put the phone's region back afterwards.

Result:

### A3. Clearing the expert meeting link (08-06)

Steps: sign in as an expert **test account** with a saved meeting link. In expert Settings, clear the meeting link field and leave the screen. Reopen it. Type the link back and confirm it persists.

Expected: the cleared link stays empty after reopening, with no error. Typing it back saves it.

Result:

### A4. Empty-name save and the 422 alert (08-06)

Steps: on a **test account** with an empty last name, edit only the Bio in Profile Settings and save. Then clear a set first name and look under the field. If you can force a rejected save (for example a field the server refuses), read the alert.

Expected: a Bio-only edit saves with no error. Clearing a set name shows "Please enter your first name." (or last name) under the field and the old name is kept. A rejected profile save shows "Check {fields}, then try again." and never the server text.

Result:

### A5. Remembered login email (08-09)

Steps: sign in, log out, and look at Login. Then force-quit and reopen.

Expected: the last signed-in email is filled in with an empty password and stays editable. It also survives a rejected session. The saved value is in the device's encrypted storage, so this proves it on the real store.

Result:

### A6. Delete account forgets the remembered email (08-25)

Steps: on a **throwaway account** with nothing upcoming, sign in so its email is remembered, then delete the account. Look at Login after the farewell screen.

Expected: Login starts with an empty email field. Do this only with a throwaway account.

Result:

### A7. Delete Account copy and blocker alert (08-17, D-23)

Steps: on a **throwaway account**, open Delete Account. Read the confirmation step, then continue to the reason and password step. To see a blocker, use a throwaway account with an upcoming booking and try to delete: once as a client with an upcoming session, once as an expert with an upcoming booking, and once with a session starting within 15 minutes. Repeat the first two in the other mode.

Expected:
- The confirmation step shows the permanence line, the upfront line, the three groups and the line "Cards you added to pay for sessions are not deleted with your account." The reason step shows only the headline and the permanence line. No text claims that payment details or bookings are removed.
- A blocked deletion shows "You can't delete your account yet" with the message for that code and mode: `EXPERT_HAS_UPCOMING_BOOKINGS` (expert mode: "You have upcoming bookings as an expert. Cancel or finish them, then try again."; client mode: "...Switch to Expert mode to cancel or finish them, then try again."), `CLIENT_HAS_UPCOMING_BOOKINGS` (client mode: "You have upcoming sessions booked. Cancel them, then try again."; expert mode: "...booked as a client. Switch to Client mode to cancel them, then try again."), `SESSION_IN_PROGRESS` ("A session is in progress or starts within 15 minutes. Wait until it ends, then try again.").
- **View My Bookings** shows only where the table in `.planning/todos/completed/2026-11-13-android-delete-account-copy-and-blockers.md` says so, and opens the Bookings tab of the active mode. The dismiss button reads `Got it`. A retry mints a new token.

Result:

### A8. Cancellation policy link (08-12, SET-07)

Steps: as a client, Cancel Booking, Continue, tap **Cancellation policy**, read the three cards, tap Back, and check the reason you chose.

Expected: the screen shows **Cancellation Deadlines**, **Refund Eligibility** and **How to Initiate a Cancellation**, readable on the dark theme. Back returns to the confirmation step with the reason still selected. The refund note reads "Your bank decides how long a refund takes to appear." and promises no number of business days.

Result:

### A9. Add hours at the end of the day (08-12)

Steps: use a **dedicated test expert account**. Note its current weekly availability first. Make one day's only slot end at 22:00 (through the Availability screen), tap **Add hours**; then make the latest end 22:30 and look at Add hours. Restore the noted availability afterwards.

Expected: with a latest end of 22:00, Add hours adds 22:30 to 23:30. With a latest end of 22:30 the button is dimmed and disabled, and tapping does nothing. After restoring, the Availability screen shows the noted schedule again.

Result:

### A10. Expert-mode gate and Not now (08-26, P7)

Steps, on a **dedicated test account**:
1. With an **unfinished expert account**, tap an expert-targeted push: it opens the notifications list, not the setup hub.
2. During a call, tap a push for the **other mode**: the switch waits until the call ends and there is no mode switch.
3. Relaunch and foreground a **client-only account**: it stays client-only.

Expected: as written in each step. A difference found here becomes a new todo (this row was closed on the basis of this device step).

Result:

### A11. Push prompt after a reinstall (08-12, todo 2026-11-08)

Steps: on Android 13 or later, sign in, **deny** the notification prompt, uninstall the app, reinstall it, and sign in again. Also note that a signed-in user who was never asked gets no prompt on a plain relaunch (a session restore never prompts).

Expected: after the reinstall and sign-in the prompt shows again (the reinstall wipes both the session and the "asked" flag). Record either outcome. A gap becomes a new todo.

Result:

### A12 (P1). Availability picker keeps a stored off-grid or 24:00 time

Sign in as a **dedicated test expert account** (never a real expert's account). Before starting, **note that account's current weekly availability**. The user sets that account's Monday slot to 09:15 to 24:00 through the API (Claude never writes production data). Open the slot: 9:15 AM and 12:00 AM are selected. Tap 10:00 AM: the 9:15 AM row is still listed. Tap 11:30 PM as the end: the 12:00 AM row is still listed. Cancel leaves the slot unchanged. Afterwards **restore the noted availability** on that account and confirm the Availability screen shows it again. (Dev build at or after `da7002ce`.) This item writes availability on the live production backend, which is why it runs on a dedicated test account.

Result:

### A13 (P2). Client Profile hub online dot

Open the client Profile hub: a green dot with a card-coloured ring shows at the bottom-right of the avatar on the user card, and the card still reads "{name}, {email}, Edit profile" to TalkBack with no extra announcement for the dot. Switch to expert mode and open the expert Profile hub: no dot shows on the avatar. Read-only, any test or real account. If TalkBack is not set up, mark only the TalkBack part `SKIPPED (why)` inside the Result line.

Result:

### A14 (P3). Publish refuses a missing photo instead of disabling

Use a **dedicated, unpublished test expert signup** with every step done except the photo (if the refusal failed, the profile would be published on production). On Profile Review the Publish Profile button is usable and no "Still needed" line shows. Tap it: "Couldn't publish profile" with "Finish these first: Add profile picture."; OK stays on Review and nothing is published (the expert is not live, and the setup hub still shows the photo step open).

Result:

### A15 (P4). Feedback minimum message

Help, Feedback: type fewer than 10 characters and send: "Please enter at least 10 characters." shows and the typed text is kept.

Result:

### A16 (P5). Zero-language Done keeps at least one language

Zero-language Done on Android client and expert Profile Settings. Run on a **dedicated test account with a throwaway profile, not a real user**: if the guard failed, these steps would delete that account's languages on the live production backend. Use an Android dev build from `ClickMe_Android` `main` (at or after `b1e37ca2`).
1. Client mode: open Profile Settings, then Spoken Languages. Deselect every language in the sheet (including any custom ones that appear as chips, if the screen offers removal; otherwise a profile with only catalogue languages) and tap Done.
2. Expect: the sheet closes, a dialog titled "Couldn't save changes" shows "Keep at least one language.", and the Spoken Languages list is unchanged. The auto-save status icon shows no failure and no save runs.
3. Dismiss the dialog with "Got it", leave Profile Settings, and reopen it: the languages are still there. Force-quit the app and reopen to confirm the server still returns them.
4. Repeat steps 1 to 3 on expert Profile Settings (switch to expert mode with the same test account).
5. Restore note: no cleanup is needed if the guard works. If the languages were wiped, re-add them in the sheet and record the failure.

Result:

### A17 (P6). Verified email survives resume on Android

Run on a **dedicated test account with a fresh unpublished expert signup**, on an Android dev build from `ClickMe_Android` `main` (at or after `5a044d0a`).
1. Sign up as a new expert, open Verify email from the setup hub and verify the code. Expect the Verify email row ticked on the hub.
2. Pull to refresh on the hub. Expect Verify email stays ticked.
3. Open and leave two other steps (for example Personal details and Timezone). Expect Verify email stays ticked each time the hub reappears.
4. Force-quit the app, relaunch and log in mid-setup. Expect the hub loads with Verify email still ticked.
5. Failure handling: if the row ever unticks after a successful verify, record which step preceded it (reappearance, pull to refresh, other step, or relaunch).

Result:

## Not covered by this run

This run does not cover the items that were removed or covered by other evidence. `08-RELEASE-RECORD.md` lists them:

- `## Not run on device (D-01)`: Phase 3 checklist items 7-24 and Phase 4's skipped UAT tests, covered by unit tests plus this run, and the one Phase 4 test (the 3-D Secure challenge on a saved card that requires SCA) that is covered by unit tests only.
- `## Removed and untested (D-02)`: the accessibility steps that were dropped from the device checklists. They are removed and untested on device, and this checklist has no step for them.
- `## Closed on non-device evidence`: BACK-15 (D-08) and BACK-19's captured-refund branch (D-27).
- `## Deferred with reason`: BACK-08 and BACK-13 (D-07) and the open review findings.
