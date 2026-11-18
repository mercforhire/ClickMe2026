# Phase 7 Device UAT Checklist

Every device check Phase 7 (Chat) left open, in one list, plus the planner and UI-SPEC assumptions you are asked to judge. Built by plan 07-08 from every `07-0[1-7]-SUMMARY.md`, the `<human-check>` blocks in plans 07-01 to 07-07, the "Device-only checks" and "UI Considerations" tables in `07-UI-SPEC.md`, and the "Manual-Only Verifications" table in `07-VALIDATION.md`. All code is merged and unit-tested; nothing on this list has been seen on a device yet. Claude runs only local tests and builds: every step on a device or against production is yours.

## Setup

- **Devices:** two real iPhones on iOS 18 or later, not the simulator. Airplane mode, the keyboard, VoiceOver, Dynamic Type, push and live sockets need hardware. In this list **Phone 1** is signed in as the test client and **Phone 2** as the test expert unless an item says otherwise.
- **Build:** a build at or after `491b600`, the last Phase 7 app commit (plan 07-09, D-18, the expert booking-row route; `git log -1 --format=%h -- ClickMe2026`). Item 14's "before" step uses App Store build 6 instead, and its "after" step needs a build at or after `491b600`. The working tree also carries uncommitted edits to `ClickMe2026/Localizable.xcstrings` that Phase 7 did not make (Xcode rewrites it on every build); for a build that is exactly Phase 7, build from a clean checkout of the commit.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`). Phase 7 made no backend change. Before you start, check read-only that `/health` answers and note the commit it reports; nothing else needs to be called by hand.
- **Accounts (yours, named by role only):**
  - a **test client** (Phone 1) and a **test expert** (Phone 2) with a thread between them that has more than 60 messages (for Load earlier) and at least one booking system row in it (item 14 needs an expert-side thread with a booking row);
  - a **second test client** to repeat the profile Block and the VoiceOver passes on a fresh pair, so a thread the first pair already blocked does not hide a bug;
  - push notifications enabled on Phone 1 (item 9);
  - **App Store build 6** on a device, signed in as the test expert, for the "before" step of item 14.
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. The three judgement items (15 to 17) take `KEEP` or `CHANGE (what)`. Do not write a token, a password, a card number or a real email address anywhere in this file; refer to an account by its role.

## Notes before you start

- **Block, Unblock and Report change real production accounts.** Use the test accounts only. Report the test accounts, never a real person. Unblock every thread you blocked when you finish.
- **Use airplane mode for every forced failure.** It fails in milliseconds; a black-holed network can take up to 120 s (the request timeout), which is what judgement item 15 asks about.
- **The Phase 2 to 6 device checklists are still partial.** `02-DEVICE-UAT-CHECKLIST.md` to `06-DEVICE-UAT-CHECKLIST.md` must run before Phase 8. Phase 7 touched screens they cover (the shared thread, Expert Profile and Chats list), so run them on the same build.
- **Nothing in this plan, and nothing you write in this file, ticks a box in `REQUIREMENTS.md`.** CHAT-01 to CHAT-08 stay as they are there until `/gsd-verify-work 07` reads the Results. Whether a failed item re-opens a requirement is that command's decision.
- **No backend or Android change was made in Phase 7** (07-RESEARCH "Android parity"). A failure that looks like a server problem (item 11 in particular) is reported, not fixed from this list.
- **Settled by you on 2026-11-17, not asked again:** UI-SPEC A9 (the conversation name stays bold when read; item 10 checks the behavior only) and UI-SPEC A13 (the six report reasons in enum order; item 6 has a plain verification row).
- **Backstop coverage (UI-SPEC "UI Considerations").** Each backstop is carried by these items: PO1 by item 18 (a sweep of every delta in its filled state, after items 1 to 17); D1 by items 1 and 2; D2 by items 4, 6 and 7; D3 by items 10 and 11; D4 by item 5; D5 by item 12; LT3 by item 13; OV2 by items 3 and 8.
- **07-VALIDATION Manual-Only rows** are carried by: "Read label live" (CHAT-08) by item 11; "Pending, Failed, Retry on a real dead network" (CHAT-01) by items 1 and 2; "Block banner on both sides, only the blocker sees Unblock" (CHAT-03) by items 6 and 7; "Unread badge appears and clears live" (CHAT-07) by item 10.

## Automated evidence

Run by plan 07-08 on 2026-11-18 and re-run in full by plan 07-09 on 2026-11-18 at HEAD `491b600`, the last Phase 7 app commit (07-09 added `ChatBookingRowRoute` and its call site after the 07-08 run; every Phase 7 commit after it is docs), simulator `iPhone 17`, Debug. The figures below are the 07-09 re-run at `491b600`; the 07-08 run at `003aff8` gave 1168 tests in 107 suites and the same pass results:

- **Phase gate suite (the full unit suite in one xcodebuild invocation, smoke suites and the known flake skipped):** `✔ Test run with 1172 tests in 108 suites passed after 9.916 seconds.` and `** TEST SUCCEEDED **` (log `/tmp/07-08-full.log`, rewritten by the re-run). Skipped: `AuthSmokeTests` and `SignupSmokeTests` hit production and were not run; `MakeABookingAvailabilityTests` is the known flaky suite (todo `2026-11-13-flaky-make-a-booking-availability-test.md`) and was run separately below. `LoginTests` is compiled and run in this invocation (it passes; the old STATE.md concern that it does not compile was fixed by `be79868`). This run includes every Phase 7 stubbed `.serialized` suite alongside the others.
- **Known-flaky record run (`MakeABookingAvailabilityTests` alone, not part of the verdict):** in the 07-09 re-run, run 1 failed with 1 issue (`✘ Test run with 5 tests in 1 suite failed after 0.776 seconds with 1 issue.`, the known flake) and run 2 passed (`✔ Test run with 5 tests in 1 suite passed after 0.743 seconds.`); in the 07-08 run, run 1 passed. No Phase 7 commit touches the Make a Booking folder or its test file (0 commits in `16fe88e..HEAD`). Logs `/tmp/07-08-flaky-1.log` and `/tmp/07-08-flaky-2.log`; the outcome is appended to the todo.
- **Debug build:** `** BUILD SUCCEEDED **`; the only `warning:` line in the log is the build system's own "Metadata extraction skipped. No AppIntents.framework dependency found." (log `/tmp/07-08-build.log`).
- **Grep gates (all PASS; comment lines filtered out of every whole-tree count):**
  - no block copy claiming profile or booking hiding (`your profile`, `appointment`) in the Chat screens, `ExpertProfileView.swift` or `ExpertProfileBlockViewModel.swift`: 0 matches (3 at the base);
  - no `unblockDenied` latch in `ClickMe2026`: 0 code lines (7 at the base);
  - no `ReportThreadIdentifier` sheet identifier in `ClickMe2026`: 0 code lines (3 at the base);
  - no `print(`, `NSLog`, `os_log` or `Logger(` in the Chat screens, `ChatThreadReducer`, `ChatItemMapper`, `ChatBlockState`, `ChatThreadLookup`, `ChatComposerRules`, `ChatUnreadRules` or `ExpertProfileBlockViewModel`: 0 matches;
  - no `try? await` on `sendChatMessage`, `chatAction` or `initiateChat` in those Phase 7 surfaces plus `ExpertProfileView.swift`: 0 matches (the 5 whole-tree hits outside Phase 7 are out of scope and unchanged);
  - no `items.insert(contentsOf` in `ChattingViewModel.swift` outside comments: 0 (1 at the base);
  - no `Spam or scam` in the Chat screens: 0 (1 at the base);
  - no `UserDefaults`, `FileManager` or `Valet` in `ChattingViewModel.swift`, `ChatSendCoordinator.swift` or `ChatThreadReducer.swift`: 0;
  - no `message.contains`, `message.hasPrefix` or `localizedCaseInsensitiveContains` in `ChattingViewModel.swift`, `ReportChatViewModel.swift` or `ExpertProfileBlockViewModel.swift`: 0;
  - no `.badge(` in `ClickMe2026` outside comments: 0 (D-15);
  - the `toolbarColorScheme(.dark, for: .navigationBar)` pin appears once in `ChattingView.swift` and once in `ReportChatView.swift`.
- **D-17 Read-handler guard:** `ChattingViewModel.handleMessageRead(_:)` is byte-identical to the phase base `16fe88e` (13-line extract compared with `cmp`, PASS), re-checked at `491b600`. No Phase 7 plan edited the sender-side Read handler.
- **View-model size ceiling:** `ChattingViewModel.swift` is 624 lines, at the ceiling of 624 (its length at the phase base `16fe88e`). Where the new logic went: `ChatSendCoordinator.swift` 123 lines, `ChatItemMapper.swift` 182 lines, `ChatBlockState.swift` 224 lines.
- **Backend and Android:** Phase 7 made no backend change and no Android change (07-RESEARCH "Android parity").
- **What the automation does not cover:** every item below.

---

## Items

### 1. C1 (first half), D1 — a message goes Sending, then the time; a dead network gives a Failed bubble (07-01)

**Requirement:** CHAT-01. **Plan:** 07-01. **Status:** PENDING (UI-SPEC C1, D1).

Steps: on Phone 1 (test client) open the thread with the test expert. With the network on, send a message. Then turn airplane mode on and send a second message.

Expected:
- The first bubble appears at once showing `Sending…` where the time goes, then switches to the time with no flash, jump or second bubble.
- The second bubble stays where it was appended with a red exclamation glyph before it, a dimmed green fill with readable text, a thin red border, and the status line `Not sent. Tap to retry` in place of the time. No alert appears.
- The keyboard stays up and the field stays usable and focused throughout, before and after the failure.

Also look at (07-02 device observations, answer in the Result line): (a) the Sending to Failed change no longer cross-fades the status line, because the Failed bubble is a different view; is that acceptable? (b) tapping the red glyph itself does nothing (it sits outside the tap target); is that acceptable?

Result:

### 2. C1 (second half), D1 — Retry delivers exactly once; Delete needs no prompt; failed bubbles do not survive a reopen (07-02)

**Requirement:** CHAT-01. **Plan:** 07-02. **Status:** PENDING (UI-SPEC C1, D1).

Steps: continue from item 1 with airplane mode still on and send a second failed message, so there are two Failed bubbles ("one" and "two"). Turn the network on. Tap the "one" bubble. Long-press the "two" bubble and choose `Delete`. Close the thread and reopen it.

Expected:
- The tapped bubble goes to `Sending…`, then to the time; Phone 2 shows "one" exactly once (no duplicate).
- `Delete` removes "two" at once with no prompt, and Phone 2 never receives it.
- After reopening, no Failed bubble remains (they live in memory only).
- The Failed bubble group is comfortably tappable.
- Judge the wait too: while the network was dead, how long did a send stay on `Sending…` before it turned Failed? Record your answer in judgement item 15.

Result:

### 3. C2, OV2 (counter) — the composer stops at 10,000, the counter shows from 9,000 (07-02)

**Requirement:** CHAT-01. **Plan:** 07-02. **Status:** PENDING (UI-SPEC C2, OV2).

Steps: with the keyboard up on Phone 1, paste text longer than 10,000 characters into the composer, with an emoji close to the cut. Delete down to about 8,990 characters and type up to 9,000, then up to 10,000. Tap Send at exactly 10,000.

Expected:
- The text stops at 10,000 units and no emoji is split in half.
- The counter shows from 9,000 as `{n} / 10,000` with grouped digits, turns red at 10,000, and stays above the keyboard (it rides up with the bar, it is not hidden by it).
- Send still works at exactly 10,000.
- With VoiceOver on, typing up to the cap announces `Message length limit reached` once, not on every key; below the cap the counter is silent, at the cap it reads `{n} of 10,000 characters`.

Result:

### 4. C3 (profile part) — Block from the Expert Profile asks first, blocks without leaving the profile (07-06)

**Requirement:** CHAT-04, CHAT-03. **Plan:** 07-06. **Status:** PENDING (UI-SPEC C3, D2).

Steps: on Phone 1 (test client) open the test expert's profile, tap the `⋯` menu, tap `Block {name}`. Tap `Cancel` once. Repeat and tap `Block`. Then open the thread on Phone 2 (test expert). Repeat the whole item with the second test client and VoiceOver on.

Expected:
- The alert reads `Block {name}?` with `They won't be able to message you.`, buttons `Block` (red) and `Cancel`. `Cancel` sends nothing.
- `Block` shows a dim scrim with a spinner over the profile (VoiceOver says `Blocking`), then the toast `You blocked {name}`; you stay on the profile and no chat opens.
- On Phone 2 the thread shows `You can't reply to this conversation`, there is no Unblock anywhere, and the menu entries are `View Profile` and `Report` only.
- If the block fails (try airplane mode once), the alert `Couldn't block user` shows and no toast appears.

Result:

### 5. C7, D4, A12 — the profile toast is not hidden behind the tab bar or the home indicator (07-06)

**Requirement:** CHAT-04. **Plan:** 07-06. **Status:** PENDING (UI-SPEC C7, D4, A12).

Steps: during item 4, when `You blocked {name}` appears, look at where it sits on screen. Do it once on a profile reached from the Search or Explore tab, where the tab bar is visible.

Expected: the toast is fully visible above the tab bar and the home indicator, wrapped and readable. UI-SPEC A12 accepts that the toast may float slightly higher than needed if the profile hides the tab bar; whether that looks acceptable is judgement item 17.

Result:

### 6. C3 and C4 (card part), D2, A13 — the Block & Report screen on each side, and the report (07-05)

**Requirement:** CHAT-02, CHAT-03, CHAT-04. **Plan:** 07-05. **Status:** PENDING (UI-SPEC C3, C4, D2, A13).

Steps: Phone 1 (test client) opens the thread menu, `Block or Report`, on an unblocked thread. Tap `Block User` and confirm; come back to the thread. Open `Block & Report` again on Phone 1, then open it on Phone 2 on the same blocked thread. On Phone 1 tap `Unblock User`. On either phone open the reason picker, paste more than 1,000 characters into Description, and submit a report on a test account.

Expected:
- Unblocked: the card reads `Block User`, body `Blocking stops both of you from sending new messages in this conversation. You can still see earlier messages. They won't be notified.`, with a red `Block User` button. The confirm dialog says `They won't be able to message you. They won't be notified.` No text anywhere claims a profile or an appointment is hidden.
- After the block the thread shows the blocked banner at once, with no reload.
- Blocked, Phone 1 (the blocker): `You blocked this conversation`, body `Unblocking lets you and {name} send messages in this conversation again.`, and an `Unblock User` button in the green style.
- Blocked, Phone 2: `You can't reply to this conversation`, body `You can still see earlier messages, but neither of you can send new ones. Only the person who blocked this conversation can lift it.`, and no button.
- After `Unblock User` the card returns to `Block User` and the thread shows the composer on return.
- **UI-SPEC A13 verification row:** the reason picker lists, in this order, `Harassment or abuse`, `Spam`, `Inappropriate content`, `Scam or fraud`, `Impersonation`, `Something else`, with nothing preselected. You confirmed this list on 2026-11-17 (07-CONTEXT D-09 note), so this is a plain check with no KEEP or CHANGE question.
- Description stops at 1,000 characters with the counter at `1000/1000`; the report submits and shows the submitted state. A failed submit (try airplane mode) shows `Couldn't send report`.

Result:

### 7. C4 (banner), D2 — the blocker sees Unblock on the thread banner, the blocked side never does (07-04)

**Requirement:** CHAT-03. **Plan:** 07-04. **Status:** PENDING (UI-SPEC C4, D2).

Steps: Phone 1 (test client) blocks the test expert from the thread menu's `Block or Report` and comes back to the thread. Check both phones' threads and menus. On Phone 1 tap `Unblock` on the banner. Block again for item 8.

Expected:
- Phone 1: banner `You blocked this conversation` with an `Unblock` capsule; the menu reads `View Profile`, `Unblock or Report`.
- Phone 2: banner `You can't reply to this conversation`, no Unblock anywhere, menu `View Profile`, `Report`. Earlier messages stay readable and scrollable on both phones.
- Tapping `Unblock` shows a spinner labelled `Unblocking`, then brings back an empty, unfocused composer with a short fade. Both phones can send again.
- A thread blocked before this build existed (a legacy block with no recorded blocker, if you have one) shows "can't reply" with no Unblock on either phone.

Result:

### 8. C5, OV2 — a send refused because the thread was blocked while it was open (07-04)

**Requirement:** CHAT-03. **Plan:** 07-04. **Status:** PENDING (UI-SPEC C5, OV2).

Steps: with Phone 2 (test expert) on the thread, composer showing and keyboard up, have Phone 1 block the thread. On Phone 2 type a message and send.

Expected: the message bubble disappears, the text returns to the composer, the banner `You can't reply to this conversation` replaces the composer, the keyboard hides, no alert appears, and with VoiceOver on the banner title is announced once. Unblock again when done.

Result:

### 9. C6 (open-clears part), CHAT-05, CHAT-06 — push open, Load earlier, a brand-new thread (07-03)

**Requirement:** CHAT-05, CHAT-06, CHAT-07. **Plan:** 07-03. **Status:** PENDING (UI-SPEC C6).

Steps: force-quit the app on Phone 1. On Phone 2 send 3 messages. Tap the push notification on Phone 1 (cold launch) to open the thread, then go back to Chats and pull to refresh. Open the long thread (more than 60 messages), scroll to the top and tap `Load earlier` twice. Optional: open a brand-new thread from a profile `Message` button and open the menu before anyone writes.

Expected:
- After the push open and the list reload, the thread's row shows no unread count; on Phone 2 the 3 messages show `· Read`.
- `Load earlier` never shows a message twice, and older messages appear above the newer ones.
- On the brand-new thread `View Profile` is enabled right away and Phone 2 sees Phone 1 typing as soon as Phone 1 types.

Result:

### 10. C6 (pill part), D3, A9 — the unread pill counts, caps and clears live (07-07)

**Requirement:** CHAT-07. **Plan:** 07-07. **Status:** PENDING (UI-SPEC C6, D3, A9).

Steps: Phone 1 stays on the Chats list. Phone 2 sends one message, then three more, then 100 or more (a script run on a test account is fine; do not paste its credentials into this file). On Phone 1 open the thread from the row, then go back. With the thread open, Phone 2 sends again; go back. Open another thread of Phone 2 from a push and from the profile `Message` button.

Expected:
- The pill reads `1`, then `4`, then `99+`, with a bold, brighter preview. The row moves to the top on a new message.
- The name is bold both before and after the thread is read (UI-SPEC A9, confirmed by you on 2026-11-17).
- Opening the thread clears the pill at once and it stays clear after going back; a message arriving while that thread is open never shows a count; a push-opened or profile-opened thread also clears its row.
- There is no badge on the Chats tab icon and no `Blocked` label on any row.
- Your own messages never add to a count.

Result:

### 11. C6 (CHAT-08 regression), D3 — the sender sees `· Read` live (D-17)

**Requirement:** CHAT-08. **Plan:** 07-01, 07-03 (no CHAT-08 fix was made; this is the regression row). **Status:** PENDING (UI-SPEC C6, D3).

Steps: with both phones on the same thread, Phone 1 sends a message and Phone 2 has the thread open and visible. Watch Phone 1 without reloading. Then close the thread on Phone 2, have Phone 1 send, and open the thread on Phone 2.

Expected: Phone 1 sees `· Read` appear on the message live, with no reload or reopen, in both cases (immediately if Phone 2 is looking, as soon as Phone 2 opens it otherwise). An own bubble that already shows `Read` does not revert after a reload.

If this fails: start with the backend `message.read` delivery, not the iOS handler. Check room membership (is Phone 1 in the thread's socket room), the emit target (does the server send `message.read` to the sender), and the thread id and message ids in the event. The sender-side handler (`ChattingViewModel.handleMessageRead`) is byte-identical to the phase base, so a failure here is a regression of the shipped behavior or a backend problem, not a Phase 7 edit to that handler.

Result:

### 12. C8, D5 — VoiceOver on the failed bubble, the counter, the banner and a row with an unread count (07-02, 07-04, 07-06, 07-07)

**Requirement:** CHAT-01, CHAT-03, CHAT-04, CHAT-07. **Plan:** 07-02, 07-04, 07-06, 07-07. **Status:** PENDING (UI-SPEC C8, D5).

Steps: turn VoiceOver on and walk each surface: a Failed bubble (item 2 setup), the counter at the cap (item 3), the blocked banner on both phones (items 7 and 8), the profile Block overlay (item 4), and a Chats row with an unread count (item 10).

Expected:
- Failed bubble: reads `{text}. Not sent.`, the hint `Retries sending`, and offers the actions `Retry sending` and `Delete message` (so Delete does not depend on the long-press). A Pending or Sent bubble offers neither. The red glyph is not read separately.
- Counter: silent below the cap; `{n} of 10,000 characters` at the cap; one announcement `Message length limit reached`.
- Banner: the title is read as static text; `Unblock` is a button with the hint `You and {name} can message each other again`; `Unblocking` while busy; after a rejected send the banner title is announced once.
- Profile overlay: `Blocking`, with the screen behind it hidden from VoiceOver until the request ends; the toast is announced once, not twice.
- Chats row: one element reading `{name}. {n} unread messages. {preview}. {time}` (`1 unread message` for one, `More than 99 unread messages` above 99, `Online.` appended when online).

Result:

### 13. C9, LT3 — largest Dynamic Type: the banner stacks, nothing truncates (07-04)

**Requirement:** CHAT-03, CHAT-01, CHAT-07. **Plan:** 07-04 (and 07-01, 07-05, 07-07 for the failed line, card and pill). **Status:** PENDING (UI-SPEC C9, LT3).

Steps: Settings > Accessibility > Display & Text Size > Larger Text, set the largest accessibility size. Look at the blocked banner on Phone 1 (the blocker), a Failed bubble, the Block & Report card in each state, and a Chats row with an unread count (also with a long contact name). Set the size back afterwards.

Expected:
- The `Unblock` capsule moves under the banner title, left-aligned, and stays 44 pt tall.
- The status line `Not sent. Tap to retry` wraps without truncation.
- The block card body wraps without truncation.
- The unread pill grows with the text and never truncates; the preview line truncates instead.

Result:

### 14. C10, D-18 — the expert opens a chat booking row (07-09)

**Requirement:** none of CHAT-01 to CHAT-08 (the folded D-18 todo). **Plan:** 07-09 decides the route; this item records both outcomes. **Status:** PENDING (UI-SPEC C10, N3).

Before step (App Store build 6, signed in as the test expert): open a chat that has a booking row and tap the row. A load error is the expected old behaviour; note what you see.

After step (only if plan 07-09 changed the route; install a build at or after its app commit): repeat the tap as the test expert. Expected: it opens the expert booking summary with no load error. As the test client, the same row still opens the client's own booking screens as before.

07-09 outcome: reproduced. On 2026-11-18 the user ran the "before" step on App Store build 6 as the test expert (chat booking row) and reported "reproduced" at the plan's decision checkpoint: the row opened the wrong screen or failed to load. Plan 07-09 then changed the route in commit `491b600`: in the expert shell a booking row opens the expert Booking Summary for active and finished bookings alike; the client shell is unchanged. The "after" step (a build at or after `491b600`, as the test expert, then as the test client) has not been run on a device yet.

Result:

### 15. Judgement — Open Question 3: how long a send may stay on `Sending…` on a dead network (07-RESEARCH)

**Requirement:** CHAT-01. **Plan:** 07-01. **Status:** PENDING.

Context: the request timeout is 120 s, so on a network that drops packets without refusing them a send can stay `Sending…` for up to two minutes before it turns Failed. Airplane mode fails in milliseconds and will not show this; if you can, try a weak or throttled network once (Network Link Conditioner, 100% loss). Phase 7 keeps 120 s (a shorter timeout adds a duplicate-delivery risk that only the `client_msg_id` dedupe covers).

Answer: `KEEP` or `CHANGE (what)`. A `CHANGE` answer becomes a follow-up todo, not a Phase 7 change.

Result:

### 16. Judgement — research A4: a count may reappear briefly after a very quick pop (07-07)

**Requirement:** CHAT-07. **Plan:** 07-07. **Status:** PENDING.

Context: opening a thread zeroes its row, and the next quiet `GET /chats` reload corrects drift. If you leave a thread within about a second, the old count may show again until that reload. No second delayed reload was built.

Steps: open a thread that has an unread pill from item 10 and go back within a second. Watch the row.

Answer: `KEEP` or `CHANGE (what)`.

Result:

### 17. Judgement — UI-SPEC A12: toast height on the profile (07-06)

**Requirement:** CHAT-04. **Plan:** 07-06. **Status:** PENDING.

Context: `ToastHost` is built for a screen with the tab bar visible and adds 49 pt. If the Expert Profile hides the tab bar, the toast floats about 49 pt higher than needed. This is accepted in the spec; you judge how it looks (see item 5).

Answer: `KEEP` or `CHANGE (what)`.

Result:

### 18. PO1 — every delta in its normal filled state (backstop sweep)

**Requirement:** CHAT-01 to CHAT-07. **Plan:** 07-01 to 07-07. **Status:** PENDING (UI-SPEC PO1).

Steps: after items 1 to 17, take one last look, on Phone 1 and Phone 2, at each of these in a normal filled state: a Pending and a Failed bubble, the counter near the cap, both banners (blocker and blocked side), the three Block & Report card states, the profile confirm alert and toast, and a Chats row with a pill.

Expected: each looks like the UI-SPEC describes (accent only on the Unblock capsule and the pill, red only on the failed state, the counter at the cap and destructive actions), nothing overlaps or clips at the default text size, and the dark appearance and nav bars match the rest of the app. Unblock every thread you blocked.

Result:
