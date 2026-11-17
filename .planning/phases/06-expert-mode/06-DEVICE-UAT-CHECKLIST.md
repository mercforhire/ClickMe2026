# Phase 6 Device UAT Checklist

Every device check Phase 6 (Expert Mode) left open, in one list, plus the planner and UI-SPEC assumptions you are asked to judge. Built by plan 06-10 from every `06-0[1-9]-SUMMARY.md`, the `<human-check>` blocks in plans 06-01 to 06-09, the "UI Considerations" (D1 to D6 and the backstops LT3, OV2, E7 and PO1) and "Device-only checks" tables in `06-UI-SPEC.md`, and the "Manual-Only Verifications" table in `06-VALIDATION.md`. All code is merged and unit-tested; nothing on this list has been seen on a device yet. Where a SUMMARY recorded a deviation or a superseded wording, the SUMMARY's wording is used and the item says so (for example Booking Confirmed is hosted inside the decision screen, and the Booking Note swipe-back is always locked). Claude runs only local tests and builds: every step on a device or against production is yours.

## Setup

- **Device:** a real iPhone on iOS 18 or later, not the simulator. Swipe-back, the keyboard, EventKit, Dynamic Type and push need hardware. The glass checks (items 13 and 16) need iOS 26.
- **Build:** a build at or after `9e95cf3` (plan 06-08), the last Phase 6 commit that touched app code (`git log -1 --format=%h -- ClickMe2026`). Every later Phase 6 commit is tests or docs. The working tree also carries uncommitted edits to `ClickMe2026/Localizable.xcstrings` that Phase 6 did not make (Xcode rewrites it on every build); for a build that is exactly Phase 6, check out `9e95cf3` (or the current HEAD) in a clean copy.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`). Phase 6 made no backend change. Re-check read-only before you start that `/health` reports a commit containing `28da165` (it reported exactly `28da165` on 2026-11-16 when this list was written; `28da165` is also the head of the backend `origin/main`).
- **Accounts (yours):**
  - a **test expert** with a free topic and a paid USD topic (the paid CAD topic of item 1 is created during the run), at least one pending request for a free topic and one expired request;
  - a **test client** who can send a request to that expert for the free topic;
  - a client with **one CAD and one USD session** with that expert (and one cancelled session if you have it);
  - a **second device or account** to cancel a request while the expert has it open (item 19);
  - an **Android device or emulator** for the Android check (item 32) and for the booking ID comparison (item 25);
  - **App Store build 6** on a device for the "before" check of the expired card (item 21).
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. Items that ask for a decision take `KEEP` or `CHANGE (what)`. Do not write a token, a password, a card number or a real email address anywhere in this file; refer to an account by its role ("the test expert").

## Notes before you start

- **The Phase 2 to 5 UATs are still partial.** `02-DEVICE-UAT-CHECKLIST.md`, `03-DEVICE-UAT-CHECKLIST.md`, `04-DEVICE-UAT-CHECKLIST.md` and `05-DEVICE-UAT-CHECKLIST.md` must run before Phase 8. Phase 6 touched screens they cover (the shared shell exit used by Back to Home, the expert Booking Summary and Client Profile), so run them on the same build.
- **Nothing in this plan, and nothing you write in this file, ticks a box in `REQUIREMENTS.md`.** EXP-01 to EXP-10, EXP-12 and EXP-14 to EXP-18 stay as they are there until `/gsd-verify-work 06` reads the Results. Whether a failed item re-opens a requirement is that command's decision.
- **Every environment is production with live Stripe keys.** Accepting and declining a request changes a real booking and a real card hold, so accept and decline only requests for a **free** topic made by a test client. Creating, editing and deleting a topic needs no money, but it changes the expert's real topic list: use a spare test topic for Delete.
- **Use airplane mode for every forced failure.** It fails in milliseconds; a black-holed network can take minutes (120 s request timeout).
- **Settled by you on 2026-11-16, not asked again** (recorded in `06-CONTEXT.md` and resolved in `06-RESEARCH.md` Open Questions):
  - Open Question 1, the D-11 amendment: Booking Confirmed is hosted inside Request Decision, not pushed by a path replace. Items 14 and 15 check the behavior only.
  - Open Question 2, the D-19 amendment: swiping back on the Booking Note screen is always locked. Item 29 checks the behavior only.
- **Assumptions for you to judge** (items 34 and 35, each `KEEP` or `CHANGE (what)`): the expert's own public-profile preview with no dot (Open Question 5), and EXP-12 as a LIKELY item whose before-state you confirm on build 6 (items 21 and 22).
- **Follow-ups logged, not built:** the Android parity checks (Add hours at the end of the day, off-grid rows, 409, client hub dot) are in `.planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md`; whether USD reads `$` or `US$` is in `.planning/todos/pending/2026-11-16-usd-symbol-us-dollar-prefix.md` (a USD topic card reading `$20.00` while the editor label reads `US$` is that known question, not a failure). A flaky Make a Booking test is `2026-11-13-flaky-make-a-booking-availability-test.md`.

## Automated evidence

Run by plan 06-10 on 2026-11-16 at HEAD `eb70496` (the last Phase 6 app commit is `9e95cf3`; every later Phase 6 commit is tests or docs), simulator `iPhone 17`, Debug:

- **Phase gate suite (the full unit suite in one xcodebuild invocation, smoke suites and the known flake skipped):** `✔ Test run with 952 tests in 93 suites passed after 8.277 seconds.` and `** TEST SUCCEEDED **` (log `/tmp/06-10-full.log`). Skipped: `AuthSmokeTests` and `SignupSmokeTests` hit production and were not run; `MakeABookingAvailabilityTests` is the known flaky suite (todo `2026-11-13-flaky-make-a-booking-availability-test.md`) and was run separately below. This run includes every Phase 6 stubbed `.serialized` suite (`TopicsSetupMutationTests`, `RequestDecisionAcceptTests`, `ExpertBookingNoteViewModelTests`) alongside the others.
- **Known-flaky record run (`MakeABookingAvailabilityTests` alone, not part of the verdict):** run 1 failed: `✘ Test run with 5 tests in 1 suite failed after 0.704 seconds with 1 issue.` at `MakeABookingAvailabilityTests.swift:154` (`olderLoadLandingLastWritesNothing`, `Zone/1` against `Zone/2`, the failure the todo describes). Run 2 passed: `✔ Test run with 5 tests in 1 suite passed after 0.707 seconds.` No Phase 6 commit touches the Make a Booking folder or its test file (0 commits in `fe3372c..HEAD`). Logs `/tmp/06-10-flaky-1.log` and `/tmp/06-10-flaky-2.log`; the outcome is appended to the todo.
- **Debug build:** `** BUILD SUCCEEDED **`; the only `warning:` line in the log is the build system's own "Metadata extraction skipped. No AppIntents.framework dependency found." (log `/tmp/06-10-build.log`).
- **Grep gates (all PASS):**
  - no `rateMajor` in `TopicEditorViewModel.swift` outside comments: 0 matches;
  - no `Returns 409 if the topic has active` in `ClickMe2026`: 0 matches;
  - no `slot: $viewModel.schedule` in `AvailabilitySettingsView.swift`: 0 matches;
  - no `expertName` in the `Expert Mode/Confirmed` folder outside comments: 0 matches;
  - no `replace(with:)` in `RequestDecisionView.swift`: 0 matches;
  - no `opacity(request.isExpired` in `IncomingRequestCard.swift`: 0 matches;
  - no `isOnline` in `ExpertProfileHomeViewModel.swift`: 0 matches;
  - the `toolbarColorScheme(.dark, for: .navigationBar)` pin appears once in `AvailabilitySettingsView.swift` and once in `RequestDecisionView.swift`.
- **Android (plan 06-09):** one commit, `da498620` in `ClickMe_Android`; `TopicEditorViewModelTest` 49/49, `TopicEditorSubviewsTest` 30/30 and `TopicEditorScreenTest` 22/22 passed with `ktlintCheck` clean (Gradle, from the 06-09 SUMMARY; not re-run here).
- **What the automation does not cover:** every item below.

---

## Items

### 1. EXP-02 — a decimal price types and saves as cents on a new CAD topic (06-01)

**Status:** PENDING (UI-SPEC D3, PO1).

Steps: as the test expert, Topics > add a topic, leave the currency on CAD, type `12.50` in the price field, Save. Reopen the topic.

Expected:
- The price keyboard shows a decimal key (`.decimalPad`).
- The topic card reads `CA$12.50`; reopening shows `12.50` in the field.
- With the field blank or `0` the hint reads `Leave blank or enter 0 for a free session — otherwise min CA$5.00.`; typing `4.99` turns it red, and Save shows `A paid session must be at least CA$5.00.`

Result: PASS (2026-11-16): the edit topic screen shows the price correctly. Separate observation, logged as its own cosmetic issue: the Topics tab cards show whole amounts with no cents ("CA$50 / session", "CA$5 / session", "US$5 / session"), and the user wants two decimal places (e.g. "CA$50.00 / session"). The USD card also reads "US$5", not the "$" item 3 expected.

### 2. EXP-03 — Save with nothing changed keeps the price and the currency (06-01)

**Status:** PENDING.

Steps: open the `CA$12.50` topic from item 1, change nothing, Save, reopen. Then open a topic stored at a whole amount (for example `CA$120.00`) and do the same.

Expected: both cards read exactly as before (`CA$12.50`, `CA$120.00`) and the currency is unchanged. No price changes by a cent.

Result: PASS (2026-11-16)

### 3. EXP-17 — a paid USD topic has its currency locked, with the caption (06-01)

**Status:** PENDING.

Steps: create a topic, pick USD, type `20`, Save. Reopen it from the Topics tab.

Expected:
- The picker is shown but disabled, on `USD`, with the caption `A paid topic's currency can't be changed. Create a new topic to charge in a different currency.` under it.
- Save without changing anything keeps the price at 20 USD. The label reads `Price per Session (US$)`. The topic card reads `$20.00` (the shipped `Money` table shows `$` for USD; the `US$` question is logged in `2026-11-16-usd-symbol-us-dollar-prefix.md`, so `$20.00` on the card is not a failure).

Result: PASS (2026-11-16)

### 4. EXP-17 — a free topic can switch currency, and USD shows the conversion-fee notice (06-01)

**Status:** PENDING.

Steps: edit a free topic (price blank or `0`). Tap `USD`, then `CAD`.

Expected: the picker is enabled. While USD is selected the notice reads `Clients will pay in US dollars. If your payout bank account is in Canadian dollars, Stripe converts each payment and keeps a currency conversion fee of about 2%. You may be able to avoid this by adding a USD bank account in your Stripe Express dashboard.` and it disappears on CAD.

Result: FAIL (2026-11-16): some topics show a third, invisible (blank) currency segment in the picker. The user suspects the backend. This reproduces review finding WR-02: the backend serializes a NULL `price_currency` as `''` (`expertTopics.controller.js:95`), and iOS keeps `""` as a pickable, selected currency, so Save sends `currency: ""` and gets a 422. Android already treats a non-3-letter code as absent. Severity: major. Update (item 8): the user reports that by default **every** free topic opens on the unknown currency, and Save fails. Free topics cannot be edited on this build.

### 5. EXP-03 — switching currency keeps the typed number and updates the hint (06-01)

**Status:** PENDING.

Steps: on a new topic type `12.50`, then switch CAD to USD to CAD. Type `4.99`, then switch currency again.

Expected: the field keeps `12.50` through every switch (no conversion, no reformat). The label symbol (`CA$` or `US$`) and the minimum hint update on each switch; `4.99` shows the hint in red against the 5.00 floor of either currency.

Result: PASS (2026-11-16)

### 6. EXP-02 — a comma decimal saves as cents under a comma locale (06-01, D3)

**Status:** PENDING (UI-SPEC D3).

Steps: Settings > General > Language & Region > Region: Canada, with the iPhone language set to French (Canada). Open the app, add a topic, type `12,50`, Save, reopen. Set Region and language back afterwards.

Expected: the keyboard has a decimal key, `12,50` is accepted, the topic saves as 12.50 CAD and the card reads `CA$12.50` (the app formats money through its own fixed table, not the device locale), never `CA$1,250` or `CA$12`.

Result: PASS (2026-11-16)

### 7. EXP-02 — the lock caption, USD notice and hint wrap at the largest text size (06-01, LT3)

**Status:** PENDING (UI-SPEC LT3, backstop).

Steps: Settings > Accessibility > Display & Text Size > Larger Text > Larger Accessibility Sizes on, slider at the maximum. Open a paid topic (lock caption) and a free topic with USD selected (notice and hint).

Expected: every line of the caption, notice and hint is fully visible, wrapped over several lines, with nothing cut off or overlapping the price field. Put the text size back afterwards.

Result: PASS (2026-11-16)

### 8. EXP-04 — clearing the icon and description sticks after Save and reopen (06-02)

**Status:** PENDING.

Steps: edit a topic that has an icon and a description. Tap the selected icon chip to clear it, delete all the description text, Save, reopen the topic. Then edit it again, change only the title, Save, reopen.

Expected: after the first Save the icon and description stay cleared (no icon selected, empty description). The second Save, which changes the title only, does not bring them back and does not clear anything else.

Result: PASS (2026-11-16), on a paid topic. Free topics cannot be saved on this build (see item 4).

### 9. EXP-01 — Delete asks first, in a centred alert (06-02)

**Status:** PENDING.

Steps: on a spare test topic, tap the card's menu, then Delete, then Cancel. Tap Delete again, then Delete in the alert.

Expected:
- The alert is centred on the screen (not a sheet from the bottom, not anchored to the menu). Title `Delete this topic?`; message `“{topic title}” will be removed and clients won't be able to book it.` with curly quotes around the title.
- Cancel keeps the card and nothing is sent.
- Delete removes the card, with no toast. With airplane mode on, Delete leaves the card and shows the existing error alert with a message.

Result: PASS (2026-11-16)

### 10. EXP-05 — Cancel on the time-range sheet leaves the original times (06-03)

**Status:** PENDING.

Steps: as the test expert, Availability, tap a slot's time button, pick different start and end times, then tap Cancel. Repeat with a swipe down on the sheet and with a tap outside it. Then pick new times and tap Done.

Expected: Cancel, swipe-down and tap-outside leave the row showing the original times and the screen does not show unsaved changes. Done writes the new times to the row.

Result: PASS (2026-11-16)

### 11. EXP-06 — Add hours on a day ending at 22:00 and at 22:30 (06-03)

**Status:** PENDING.

Steps: set a day's only slot to end at `22:00`, tap Add hours. Then on a day whose latest end is `22:30` look at Add hours and tap it.

Expected: at 22:00 Add hours adds a slot `22:30 - 23:30`. At 22:30 the control is dimmed and tapping does nothing; with VoiceOver on it reads `There is no room left in this day for another time range.` On an empty enabled day it still adds `09:00 - 17:00`. The slot-delete icon is announced as `Delete time range`.

Result: PASS (2026-11-16)

### 12. EXP-07 — a stored 09:15 and a stored 24:00 open selected and save unchanged (06-03)

**Status:** PENDING.

Steps: this needs slots the app cannot create: set one slot to start at `09:15` and another to end at `24:00` from Android or through the API (note that as `SKIPPED (no such slot)` if you cannot). On iOS open each in the time-range sheet, change nothing, tap Done, then Save the schedule.

Expected: the sheet opens with `9:15 AM` selected in the start list and `12:00 AM` selected in the end list (24:00 reads `12:00 AM`); no other row changes; after Done and Save the day row still reads `09:15` and `24:00`. `12:00 AM` is not offered as a new End choice on a normal slot.

Result: SKIPPED (no such slot) (2026-11-16)

### 13. EXP-05 — Availability Save is readable with Reduce Transparency and Liquid Glass Tinted (06-03, D2)

**Status:** PENDING (UI-SPEC D2; iOS 26 needed).

Steps: on an iOS 26 iPhone, Light appearance. Settings > Accessibility > Display & Text Size > Reduce Transparency on, open Availability. Then Reduce Transparency off and Settings > Display & Brightness > Liquid Glass > Tinted, open Availability.

Expected: the `Save` label in the navigation bar and the back chevron are readable in both settings (not white on white). Put the settings back afterwards.

Result: SKIPPED (2026-11-16, no reason given)

### 14. EXP-09 — Accept lands on Booking Confirmed with no Accepted frame, and Back shows the refreshed list (06-05, N1)

**Status:** PENDING (UI-SPEC N1). Use a free-topic test request: Accept and Decline here change a real booking.

Steps: as the test expert, Incoming Requests, open a pending request for a free topic, Accept, Confirm. Then tap Back.

Expected: the sheet closes and `Booking Confirmed` replaces the decision screen straight away, with no `Accepted!` frame and no toast; the title reads `Booking Confirmed`, the headline `Booking Confirmed!` and the body `Your meeting with {client name} on {date}, at {time} has been successfully booked.` The card shows the client's name, the topic, the client's photo (or the person placeholder), `{date}, {time} ({n} min)` and the meeting type. Back (the chevron or Back from the nav bar) lands on Incoming Requests without the accepted request, and its pending count is right. The old decision screen is not reachable. Per the 06-05 SUMMARY, Confirmed is hosted inside the decision screen (D-11 amendment); you are checking the behavior only.

Result: PASS (2026-11-16)

### 15. EXP-09 — Back to Home lands on the Dashboard root from a Dashboard push and from another tab (06-05, N2)

**Status:** PENDING (UI-SPEC N2).

Steps: accept another free-topic test request and tap `Back to Home` instead of Back, from each entry: (a) opened from Incoming Requests; (b) opened from a booking push notification (it opens on the Dashboard stack); (c) opened from another tab if any route opens it there (for example a chat or Bookings entry; `SKIPPED (no such route)` if none does).

Expected: in every case the Dashboard tab is selected and shown at its root (no screens above it) and its pending-request count has dropped.

Result: PASS (2026-11-16)

### 16. EXP-09 — the Confirmed back chevron and title are readable on iOS 26 (06-05, D2)

**Status:** PENDING (UI-SPEC D2; iOS 26 needed).

Steps: on a Booking Confirmed screen, look at the navigation bar with Reduce Transparency on (Light appearance), then with Liquid Glass Tinted.

Expected: the back chevron and the `Booking Confirmed` title are readable in both settings. Put the settings back afterwards.

Result: SKIPPED (2026-11-16, no reason given)

### 17. EXP-10 — Add to Calendar opens the system editor pre-filled with the client and topic (06-04, 06-05, D5)

**Status:** PENDING (UI-SPEC D5, calendar half).

Steps: on Booking Confirmed (item 14), tap `Add to Calendar` and allow calendar access if asked. Look at the New Event sheet; do not necessarily save it (cancel it, or save and delete the event afterwards).

Expected: the title reads `ClickMe · {topic} with {client name}` (a middle dot with a space each side); the start and end match the booking; there is one alert 15 minutes before; the notes hold the meeting type (`In-App Voice` or `Skype/Zoom`) and, on a new line, the client's message when the client wrote one; there is no location.

Result: PASS (2026-11-16). CHANGE REQUEST (2026-11-16): the user wants the "Add to Calendar" button on the Booking Summary screen too, for both client and expert, because Booking Confirmed is shown only once and Booking Summary can be reached repeatedly. Android must mirror it.

### 18. EXP-10 — Add to Calendar with calendar access denied (06-04, E7)

**Status:** PENDING (UI-SPEC E7, backstop).

Steps: Settings > Privacy & Security > Calendars: turn ClickMe off (or choose no access), then tap `Add to Calendar` on Booking Confirmed again. Turn access back on afterwards.

Expected: the system editor shows its own message about access; the app shows no copy of its own and adds nothing to the calendar.

Result: PASS (2026-11-16)

### 19. EXP-09 — a 409 ALREADY_PROCESSED shows the server message and pops to a refreshed list (06-05, D6)

**Status:** PENDING (UI-SPEC D6). Needs two accounts on production: a test client and the test expert, free topic only.

Steps: the client sends a booking request for the expert's free topic. The expert opens that request's decision screen and leaves it open. The client (second device or account) cancels the request. The expert then taps Accept, then Confirm.

Expected: an alert titled `Couldn't update request` with the server message (today `This booking request has already been processed.`) and `OK`. OK pops to Incoming Requests, refreshed, without that request. No Booking Confirmed screen appears. Repeat with Decline instead of Accept if you want: same alert, same pop.

Result: PASS (2026-11-16)

### 20. EXP-09 — the Accept message stops at 1,000 characters, with a counter (06-05, U1)

**Status:** PENDING (UI-SPEC U1).

Steps: on a pending free-topic request, tap Accept and paste about 1,500 characters into the message field (paste a text with an emoji near the 1,000th character if you can). Type more.

Expected: the text stops at 1,000 UTF-16 units and never splits an emoji. A `{n}/1000` counter appears from 800 characters, muted, and turns red at `1000/1000`; VoiceOver reads `{n} of 1,000 characters`. `Confirm` still works at the cap.

Result: PASS (2026-11-16)

### 21. EXP-12 — BEFORE: the expired request card on App Store build 6 (06-06, D1)

**Status:** PENDING (UI-SPEC D1, LIKELY item: do this first).

Steps: on a device with App Store build 6 installed, as an expert with an expired incoming request, open Incoming Requests and look at the expired card.

Expected (the bug to confirm): the card's topic and `Earnings` text are hard to read (the whole card is faded). Record whether it is. If build 6 reads fine, say so in Result: the verifier may then close EXP-12 as not reproducible (see item 35).

Result: PASS (2026-11-16): the bug is confirmed on build 6. The expired card is hard to read.

### 22. EXP-12 — AFTER: the expired card keeps its text at full contrast (06-06, D1)

**Status:** PENDING (UI-SPEC D1).

Steps: the same account and request on the new build.

Expected: name, topic, `Earnings`, the amount and the date read at full contrast; the card has a darker fill and a fainter border; the photo is dimmed; `EXPIRED` sits in a pill. Tapping the card still opens the read-only decision screen. An open (not expired) card looks as it did.

Result: PASS (2026-11-16)

### 23. EXP-15 — the expert hub has no online dot, and the client hub keeps its dot (06-06, U2)

**Status:** PENDING (UI-SPEC U2).

Steps: Expert mode > Profile hub: look at the avatar card at the top, and open the expert's own public-profile preview from the hub. Then switch to Client mode and open its Profile hub.

Expected: the expert hub avatar and the self-preview show no dot, no ring and no replacement text. The client hub avatar shows its online dot exactly as before.

Result: PASS (2026-11-16)

### 24. EXP-14 — Client Profile shows each session in its own currency (06-08, D5)

**Status:** PENDING (UI-SPEC D5, Client Profile half).

Steps: as the test expert, open the Client Profile of a test client who has one CAD and one USD session with you, plus a cancelled session if you have one.

Expected: each history row shows its own currency (`CA$…` for the CAD session, `$…` for the USD session), never a converted or summed figure; the cancelled row shows `—`. There is no earnings total anywhere on the screen.

Result: PASS (2026-11-16)

### 25. EXP-18 — the expert Booking Summary shows the booking ID and it matches Android (06-08)

**Status:** PENDING.

Steps: as the test expert, open any booking's Booking Summary. Note the line under `View Profile`. Open the same booking in the Android app (Android expert Booking Summary).

Expected: the last line of the client header reads `ID: #A1B2C3D4` (the first 8 characters of the booking id, upper-case, selectable by long-press); it appears at once, before the details load; the Android summary shows the same 8 characters for that booking.

Result: PASS (2026-11-16)

### 26. EXP-16 — a 6,000-character paste stops at 5,000 with a red counter (06-07, LT1)

**Status:** PENDING (UI-SPEC LT1).

Steps: as the test expert, open a past session's My Note and paste about 6,000 characters, ending with an emoji if you can.

Expected: the text stops at 5,000 and no emoji is split; the counter reads `5,000 / 5,000` in the error colour; Save still works. Counters from 4,500 show `{n} / 5,000` muted, with the number grouped for the device locale.

Result: PASS (2026-11-16)

### 27. EXP-16 — a whitespace-only note saves as empty (06-07, EM2)

**Status:** PENDING (UI-SPEC EM2).

Steps: in My Note, select all text and replace it with spaces and a blank line only, Save, then leave and reopen the note.

Expected: Save works; the field then shows empty with the placeholder; reopening shows an empty note. A note with real text is saved exactly as typed, including leading and trailing spaces.

Result: PASS (2026-11-16)

### 28. EXP-16 — Back asks `Discard changes?` when there are edits, and pops at once when there are none (06-07, D4)

**Status:** PENDING (UI-SPEC D4).

Steps: (a) open My Note, change nothing, tap the Back button. (b) Open it again, type a few characters, tap Back; tap `Keep editing`; tap Back again and tap `Discard`. (c) Type, tap Save, wait for the checkmark, tap Back.

Expected: (a) the screen pops at once, no prompt. (b) a centred alert `Discard changes?` / `Your changes to this note won't be saved.` with `Keep editing` (stays) and `Discard` (leaves, the edits are lost). (c) no prompt after a successful save. Back also asks while a save is still in flight.

Result: PASS (2026-11-16)

### 29. EXP-16 — a left-edge swipe never pops the note screen, with or without edits (06-07, D4)

**Status:** PENDING (UI-SPEC D4; settled by the D-19 amendment, 2026-11-16).

Steps: on My Note with no edits, swipe from the left edge of the screen. Then type something and swipe from the left edge again. Then tap Back.

Expected: the swipe never pops the screen, with or without edits. Back with no edits pops at once, and Back with edits asks the prompt. A swipe that pops the screen is a failure of plan 06-07, not a choice to make here.

Result: PASS (2026-11-16)

### 30. EXP-16 — the counter stays above the keyboard near the cap (06-07, OV2, LT1)

**Status:** PENDING (UI-SPEC OV2, backstop).

Steps: in My Note with a note near 4,600 characters, tap in the editor so the keyboard is up, and type at the end of the text.

Expected: the counter `{n} / 5,000` stays visible above the keyboard (not hidden behind it) and updates as you type; the keyboard can be dismissed with the toolbar button.

Result: PASS (2026-11-16)

### 31. EXP-16 — the editor shows the cut text when a keystroke or paste is truncated and the stored text does not change (06-07, WINDOWS #36)

**Status:** PENDING. This is the check plan 06-07 logged as unrun in `.planning/WINDOWS.md` (#36).

Steps: in My Note, type or paste until the text is exactly 5,000 characters, then (a) type one more character and (b) paste a short extra text, both while at the cap. Also paste a 6,000-character text onto an empty note (the stored text goes from empty to 5,000, so it changes: compare).

Expected: when the keystroke or paste is cut at 5,000 and the stored text does not change, the TextEditor shows the truncated text (the extra characters do not appear on screen and the cursor stays where it was). If the editor shows the extra characters while the counter reads `5,000 / 5,000`, that is a bug in plan 06-07 to fix before the release: record `FAIL (editor shows N extra characters)`.

Result: PASS (2026-11-16)

### 32. EXP-17 — the Android topic editor has the CAD | USD picker (06-09, Android)

**Status:** PENDING (Android device or emulator, production backend, test expert). The Android change is commit `da498620` in `ClickMe_Android`.

Steps: in the Android app create a topic, pick USD, type `12.50`, switch to CAD and back. Edit a paid USD topic. Edit a free topic.

Expected: a `CAD | USD` row sits above the price field under `Currency`; picking USD shows the conversion-fee notice (the same text as item 4) and the helper minimum in US dollars; `12.50` survives every switch; the paid USD topic shows the row disabled on USD with the lock caption (the same text as item 3); the free topic can switch.

Result: PASS (2026-11-16)

### 33. PO1 — every Phase 6 change in its normal filled state (all plans)

**Status:** PENDING (UI-SPEC PO1, backstop).

Steps: with real, filled data (not the empty or error states), look at each of these once and judge the layout: a topic card with a decimal price (`CA$12.50`); an Availability day with an inserted 09:15 row and a slot ending 22:30 after Add hours; a Booking Confirmed card with a long client name and topic; the expert Booking Summary header with the new ID line; the Client Profile history with CAD and USD rows; a My Note with about 4,800 characters.

Expected: nothing is cut off, overlaps another element or looks out of place; spacing around the new ID line and the counter is even. Add anything odd to Result.

Result: PASS (2026-11-16)

### 34. Assumption — the expert's own public-profile preview shows no online dot (06-06, Open Question 5)

**Status:** PENDING. **Decision wanted:** `KEEP` or `CHANGE (what)`.

Context: the expert hub avatar has no dot (item 23). The expert's own public-profile preview, opened from the hub, was also given no dot, because the expert has no presence signal of their own. A client viewing that expert sees a dot on the real profile.

Steps: open the self-preview from the Expert Profile hub and compare with how a client sees you (second device).

Expected: judge whether a preview with no dot is what you want.

Result: KEEP (2026-11-16)

### 35. Assumption — EXP-12 is only LIKELY: is the expired card a real problem on build 6? (06-06)

**Status:** PENDING. **Decision wanted:** `KEEP` (the fix stays and EXP-12 closes on item 22) or `CHANGE (what)`.

Context: EXP-12 was a LIKELY item from the Android port work: it was never confirmed that the expired card's text is hard to read. Item 21 records what build 6 shows. If build 6 reads fine, the verifier may close EXP-12 as not reproducible; the redesigned card (item 22) is then still shipped and harmless.

Steps: use the results of items 21 and 22.

Expected: say whether the before-state was a real readability problem and whether the after-state is acceptable.

Result: KEEP (2026-11-16): the before-state on build 6 was a real readability problem (item 21), and the after-state is acceptable (item 22). EXP-12 closes on item 22.

---

## Gap closure re-check (plans 06-11 to 06-15 and 06-18)

UAT Test 1 of this checklist found three gaps: `G-06-1-currency` (item 4 and item 8: a free topic opened on a blank currency segment and Save failed), `G-06-1-card-cents` (item 1: the Topics tab cards dropped the cents) and `G-06-1-summary-calendar` (item 17: Add to Calendar was wanted on the Booking Summary screens too, with Android mirroring it). Plans 06-11 to 06-15 and 06-18 fixed them in code, and these items re-check items 1, 4, 8 and 17 on the fixed build, plus the regressions the fixes could cause. Record each Result as `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, with the date. The 35 Results above stay as recorded; nothing here edits them, and nothing here ticks a box in `REQUIREMENTS.md` (`/gsd-verify-work 06` reads the new Results).

### Automated evidence (gap closure)

Run by plan 06-16 on 2026-11-17 at HEAD `1724c93`, simulator `iPhone 17`, Debug. The final gap-closure app commit (`git log -1 --format=%h -- ClickMe2026`) is `2a6c578` (plan 06-14); every later Phase 6 commit is tests or docs:

- **Phase gate suite (the full unit suite in one xcodebuild invocation, smoke suites and the known flake skipped):** `✔ Test run with 994 tests in 95 suites passed after 8.588 seconds.` and `** TEST SUCCEEDED **` (log `/tmp/06-16-full.log`). That is 42 more tests than the 952 of plan 06-10, so no suite was dropped. Skipped: `AuthSmokeTests` and `SignupSmokeTests` hit production and were not run; `MakeABookingAvailabilityTests` is the known flaky suite (todo `2026-11-13-flaky-make-a-booking-availability-test.md`) and was run separately below.
- **Known-flaky record run (`MakeABookingAvailabilityTests` alone, not part of the verdict):** run 1 passed: `✔ Test run with 5 tests in 1 suite passed after 0.727 seconds.` Run 2 was not needed (log `/tmp/06-16-flaky-1.log`). No Phase 6 commit touches the Make a Booking folder or its test file; the outcome is appended to the todo.
- **Debug build:** `** BUILD SUCCEEDED **`; the only `warning:` line in the log is the build system's own `Metadata extraction skipped. No AppIntents.framework dependency found.` (log `/tmp/06-16-build.log`).
- **Grep gates, the nine 06-10 phase gates (all PASS):**
  - no `rateMajor` in `TopicEditorViewModel.swift` outside comments: 0 matches;
  - no `Returns 409 if the topic has active` in `ClickMe2026`: 0 matches;
  - no `slot: $viewModel.schedule` in `AvailabilitySettingsView.swift`: 0 matches;
  - no `expertName` in the `Expert Mode/Confirmed` folder outside comments: 0 matches;
  - no `replace(with:)` in `RequestDecisionView.swift`: 0 matches;
  - no `opacity(request.isExpired` in `IncomingRequestCard.swift`: 0 matches;
  - no `isOnline` in `ExpertProfileHomeViewModel.swift`: 0 matches;
  - the `toolbarColorScheme(.dark, for: .navigationBar)` pin appears at least once in `AvailabilitySettingsView.swift` and at least once in `RequestDecisionView.swift`.
- **Grep gates, one per gap (all PASS):**
  - `G-06-1-currency`: no `hourlyRate?.currency` read in `TopicEditorViewModel.swift` outside comments (0 matches), and `func validCurrencyCode` exists in `TopicPriceRules.swift`;
  - `G-06-1-card-cents`: `static func priceLabel(for` exists in `TopicsSetupTopicCard.swift`, and the old `guard let rate = topic.hourlyRate` is gone from it (0 matches);
  - `G-06-1-summary-calendar`: `CalendarEventEditorSheet.swift` no longer has `let booking:` (0 matches); the expert Booking Summary and the client Upcoming Booking both present `CalendarEventEditorSheet(event:`; the expert Booking Summary still has exactly one `.sheet(isPresented: $showCancellationSheet)` and two or more `.sheet(` lines in all; the client Session Summary folder has no `CalendarEventEditorSheet` (0 files); and `fun isCalendarEventOffered` exists in the Android `CalendarIntent.kt`.
- **Android (plan 06-15):** one commit, `69c4e159` in `ClickMe_Android` (base `da4986206f01875dc718dd313cb6642b7bae1f48`, eight files). Its Gradle result, from the 06-15 SUMMARY and not re-run here: `./gradlew :app:testDevDebugUnitTest` on `CalendarIntentTest`, `BookingConfirmedScreenTest`, `ExpertBookingSummaryScreenTest` and `UpcomingBookingScreenTest` plus `ktlintCheck` was `BUILD SUCCESSFUL`, 0 failures, 0 skipped.
- **Android topic card (plan 06-12, read-only check, no Android edit):** the Android Topics card builds its price through `TopicPrice.resolveCurrency` and `PriceDisplay`/`Money.format` (two fraction digits) and never reads the server's `price.label`, so it already shows the cents and needed no mirror. Its USD symbol follows the device region (recorded in the USD-symbol todo).
- **Backend:** the gap closure deployed nothing. Plan 06-17 decides the optional backend hardening and deploys nothing, so production still sends `price.currency: ""` for a free topic stored with no currency, which is exactly the case R2 and R3 exercise.
- **What the automation does not cover:** every item below.

### Re-check items

**Setup for R1 to R8.**

- **iPhone:** a real iPhone on a build at or after `2a6c578`, the final gap-closure app commit (plan 06-14). The working tree still carries the uncommitted `ClickMe2026/Localizable.xcstrings` edits that Phase 6 did not make, as noted in Setup above.
- **Android (R7 only):** a device or emulator on a build at or after `69c4e159`, the plan 06-15 commit in `ClickMe_Android`.
- **Backend:** production. The gap closure changed and deployed nothing on the backend (plan 06-17 decides the optional backend hardening and deploys nothing), so a free topic stored with no currency still arrives with a blank currency. That is the case R2 and R3 test, so do not skip them because the backend "looks fine".
- **Test expert:** the free topics that showed the blank currency segment in item 4; paid CAD topics at 50, 5 and 12.50; a paid USD topic at 5; a confirmed future booking whose Booking Summary shows Cancel; a past booking; and, if available, a pending reschedule.
- **Test client:** a confirmed future booking, a pending request and a past booking.
- **Live Stripe:** accept only requests for a free topic, and never confirm a cancellation (R4 stops at `Keep Booking`).

### R1. Re-check item 1 — G-06-1-card-cents: Topics tab cards show the cents (06-12)

**Status:** PENDING.

Steps: as the test expert, open Topics and read each card. Open a paid CAD topic and a paid USD topic and compare the editor's price field and price label with the card.

Expected:
- The cards read `CA$50.00 / session`, `CA$5.00 / session`, `CA$12.50 / session`, `US$5.00 / session` and `Free`.
- Opening a topic still shows `50` and `12.50` in the editor's price field.
- The editor's price label shows the same symbol as that topic's card. A paid topic with no stored currency, if the account has one, reads in the editor's default with the cents (`CA$` in production) on both the card and the editor, never a trimmed `$125 / session`.

Note: USD keeps the `US$` the card showed before, so a USD card reads `US$5.00 / session` while other `Money` surfaces (for example the Client Profile history rows) read `$5.00`. That difference is expected until the open USD-symbol todo (`2026-11-16-usd-symbol-us-dollar-prefix.md`) is decided, and is not a fail.

Result:

### R2. Re-check item 4 — G-06-1-currency: a free topic opens on CAD | USD and saves (06-11)

**Status:** PENDING.

Steps: as the test expert, edit each free topic that showed the blank currency segment. Tap `USD`, then `CAD`, then Save. Reopen the topic.

Expected:
- The picker has exactly two segments, `CAD` and `USD`, with `CAD` selected and no blank segment.
- The USD notice from item 4 shows while USD is selected and not on CAD.
- Save succeeds, with no `Topics can be priced in CAD or USD only.` message.
- Reopening shows `CAD` selected again. That is expected, because the server keeps no currency on a free topic.

Result:

### R3. Re-check item 8 — G-06-1-currency: clearing the icon and description on a free topic sticks (06-11)

**Status:** PENDING.

Steps: item 8's steps, on a free topic. Edit the topic, tap the selected icon chip to clear it, delete all the description text, Save, reopen. Then edit again, change only the title, Save, reopen.

Expected: as item 8. After the first Save the icon and description stay cleared. The second Save, which changes the title only, does not bring them back and does not clear anything else. Save works on a free topic (it failed on the earlier build, item 4).

Result:

### R4. Re-check item 17 — G-06-1-summary-calendar: the expert Booking Summary has Add to Calendar, and its Cancel sheet still works (06-18)

**Status:** PENDING.

Steps: as the test expert, open Bookings and the Booking Summary of a confirmed future booking that shows Cancel.
1. Tap Cancel and look at the `Confirm Cancellation` sheet. Tap `Keep Booking`. Never confirm the cancellation: it cancels a live booking and its payment.
2. Tap `Add to Calendar` and inspect the New Event sheet. Cancel it.
3. Tap Cancel again, then `Keep Booking` again.
4. Leave the summary, open the same summary again and repeat `Add to Calendar`.
5. Open a past booking's summary.
6. If available, open a pending reschedule's summary.

Expected:
- The `Confirm Cancellation` sheet opens as before and `Keep Booking` returns to the summary, both before and after the New Event sheet. The New Event sheet opens right after the cancellation sheet has closed.
- The `Add to Calendar` button sits below Message Client.
- The sheet title is `ClickMe · {topic} with {client name}`; start and end match the booking; there is one alert 15 minutes before; the notes hold the meeting type and the client's message; there is no location. This is exactly the Booking Confirmed event of item 17.
- It works on every visit.
- The past booking shows no button.
- A pending reschedule shows the button with the current time. An event added then keeps that time if the new time is accepted later (the app cannot update a calendar event).

Result:

### R5. Re-check item 17 — G-06-1-summary-calendar: the client Upcoming Booking has Add to Calendar (06-14)

**Status:** PENDING.

Steps: as the test client, open My Bookings, then Upcoming, then the confirmed future booking. Tap `Add to Calendar`, inspect the New Event sheet, cancel it. Then open the pending request. Then open a past booking (Session Summary).

Expected:
- The title reads `ClickMe · {topic} with {expert name}`; start and end are the booking's times; there is one alert 15 minutes before; the notes hold the meeting type and the client's own note; there is no location.
- The pending request shows no `Add to Calendar` button.
- The Session Summary of a past booking shows no `Add to Calendar` button.

Result:

### R6. Regression — G-06-1-summary-calendar: Booking Confirmed still adds the same event (06-13, 06-18)

**Status:** PENDING.

Steps: as the test expert, accept a free-topic request (item 14) and tap `Add to Calendar` on Booking Confirmed.

Expected: exactly the event of item 17: title `ClickMe · {topic} with {client name}`, the booking's start and end, one 15-minute alert, the meeting type and the client's message in the notes, no location.

Result:

### R7. Android — G-06-1-summary-calendar: Booking Summary and Upcoming Booking on Android (06-15)

**Status:** PENDING.

Steps: on the Android build named in the setup, run the 06-15 human check: the expert Booking Summary of a confirmed future booking, the client Upcoming Booking of a confirmed future booking, a past booking, a pending request, and Booking Confirmed.

Expected: the same titles and offer rule as R4 to R6 (`ClickMe · {topic} with {client name}` for the expert, `ClickMe · {topic} with {expert name}` for the client, no button on a past booking or a pending request, Booking Confirmed unchanged). Tapping `Add to Calendar` opens the device's calendar app pre-filled with that event.

Result:

### R8. Optional — G-06-1-summary-calendar: the button goes when the session ends (06-18, 06-14)

**Status:** PENDING (optional).

Steps: keep an expert Booking Summary or a client Upcoming Booking open across a session's scheduled end, with no refresh.

Expected: the `Add to Calendar` button disappears within about a minute of the scheduled end, without a refresh.

Result:
