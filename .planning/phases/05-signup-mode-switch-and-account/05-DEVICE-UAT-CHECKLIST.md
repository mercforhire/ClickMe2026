# Phase 5 Device UAT Checklist

Every device check Phase 5 (signup, mode switch and account) left open, in one list, plus the planner and UI-SPEC assumptions you are asked to confirm. Built by plan 05-13 from every `05-*-SUMMARY.md`, the `<human-check>` blocks and `verification: backstop` truths in the plans, the "Device-only checks" and "UI Considerations" tables in `05-UI-SPEC.md`, and the "Manual-Only Verifications" table in `05-VALIDATION.md`. All code is merged and unit-tested; nothing on this list has been seen on a device yet. Where a SUMMARY recorded a deviation or a superseded wording, the SUMMARY's wording is used and the item says so (for example the bookings button reads `View My Bookings`, Title Case, not the plan's `View my bookings`). Claude runs only local tests and builds: every step on a device or against production is yours.

## Setup

- **Device:** a real iPhone on iOS 18 or later, not the simulator. Swipe-back, `scenePhase`, the mail app, push, calls and Dynamic Type need hardware.
- **Build:** a build at or after `359c721` (plan 05-12), the last Phase 5 commit that touched app code. Every later Phase 5 commit is docs only. The working tree also carries uncommitted edits to `ClickMe2026/Localizable.xcstrings` that Phase 5 did not make; for a build that is exactly Phase 5, check out `359c721` (or the current HEAD) in a clean copy.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`). Phase 5 made no backend change, so there is no deploy state to check. Every environment in `Environments.plist` points at production, so everything below acts on real accounts.
- **Accounts (yours):**
  - an **expert with unfinished setup** (`setup_completed` false);
  - a **finished expert**;
  - a **client-only account** (never been an expert);
  - a **dual-role account** with an upcoming confirmed booking on each side (one as client, one as expert);
  - a **client with a confirmed upcoming session**;
  - a **throwaway account** for Delete Account and for the explicit client-to-expert promotion. Delete Account is irreversible against production, and picking Expert on a client-only account may promote it through the server's `ensureExpert` (D-04, accepted as consent). Never use a live account for either.
- **Second device:** another phone (Android is fine) to turn a notification preference off, to place a booking, and to send the push for the other-mode item.
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. Items that ask for a decision take `KEEP` or `CHANGE (what)`. Do not write a token, a password, a card number or a real email address anywhere in this file; refer to an account by its role ("the throwaway account").

## Notes before you start

- **The Phase 2, 3 and 4 UATs are still partial** (Phase 4: 20 device items deferred on 2026-11-13). `02-DEVICE-UAT-CHECKLIST.md`, `03-DEVICE-UAT-CHECKLIST.md` and `04-DEVICE-UAT-CHECKLIST.md` must run before Phase 8. Phase 5 touched screens they cover (cancel confirmation, Request Sent exits through the shared shell exit, the setup hub and the Mode Switch screens), so run them on the same build.
- **Nothing in this plan, and nothing you write in this file, ticks a box in `REQUIREMENTS.md`.** SIGN-06, SET-02, SET-06 and SET-07 are still Pending there. `REQUIREMENTS.md` already shows SIGN-01 to SIGN-05, SET-01, SET-03, SET-04 and SET-05 as Complete (their plans ticked them when they finished, with unit evidence) while their device items below are open. Whether a failed item re-opens one of them is a `/gsd-verify-work 05` decision after the Results are filled in.
- **Two RESEARCH assumptions have a fallback if the device disagrees.** A5: the `Cancellation policy` link pushes `CancellationPoliciesView` from inside a `NavigationPath` destination (items 41 and 42); if it does not push, the fallback is a sheet with its own `NavigationStack` and a `Done` button, logged as a follow-up fix. A6: the foreground re-check is driven by `scenePhase` at App level (`ClickMe2026App`); if it never fires (item 15), the follow-up moves the call into the `scenePhase` handlers of `HomeClientView` and `HomeExpertView`.
- **Use airplane mode for every forced failure.** It fails in milliseconds; a black-holed network can take minutes (120 s request timeout).
- **Items marked *optional* are covered by unit tests** and may be skipped. Items that need data you do not have are `SKIPPED (why)`, not a pass.
- **Planner and UI-SPEC assumptions for you to judge.** Items 28, 36, 44, 45 and 46 each name an assumption (A9, U3, U2, U4 and A1 in `05-UI-SPEC.md`) and ask for `KEEP` or `CHANGE (what)`. A9 (settings never saves an empty language list, though the backend allows it) is the one that changes behavior for users.
- **Other follow-ups are logged elsewhere.** Android ports and the saved-card decision are in `.planning/todos/pending/` (`2026-11-13-android-*.md` and `2026-11-13-decide-saved-cards-on-account-deletion.md`). A flaky Make a Booking test seen during this phase is `2026-11-13-flaky-make-a-booking-availability-test.md`.

## Automated evidence

Run by plan 05-13 on the phase's final code commit `359c721`, simulator `iPhone 17`, Debug:

- **Full suite (smoke suites skipped):** `✔ Test run with 803 tests in 82 suites passed after 8.699 seconds.` and `** TEST SUCCEEDED **` (log `/tmp/05-13-full.log`). `AuthSmokeTests` and `SignupSmokeTests` hit production and were not run.
- **Debug build:** `** BUILD SUCCEEDED **`; the only `warning:` line in the log is the build system's own "Metadata extraction skipped. No AppIntents.framework dependency found." (log `/tmp/05-13-build.log`).
- **Grep gates:**
  - no `setMode(` outside `ClickMe2026/Managers/UserManager.swift`: 0 matches (PASS);
  - no `PauseCard`, `onPauseAccount` or `Pause Account` in `ClickMe2026`: 0 matches (PASS);
  - no `ReadyToStart` in `ClickMe2026`, `ClickMe2026Tests` or `ClickMe2026UITests`: 0 files (PASS);
  - no `LanguageEditorSheet`: 0 matches (PASS);
  - the support address is spelled in exactly one file, `ClickMe2026/Utils/SupportContact.swift`, and `support@clickme` appears nowhere (PASS);
  - `ClientCancellationView.swift` references `CancellationPoliciesView()` once (PASS).
- **What the automation does not cover:** every item below.

---

## Items

### 1. SIGN-06 — an unfinished expert picking Expert from Mode Switch opens the setup hub (05-07, 05-16)

**Status:** PENDING. SIGN-06 stays Pending in `REQUIREMENTS.md` until items 1 to 17 pass.

Steps: as the expert with unfinished setup, in Client mode: Profile > Mode Switch > Expert.

Expected:
- The setup hub opens (the checklist and progress ring), with no alert and no toast.
- The app stays in Client mode underneath (it never stores Expert and bounces).
- The hub shows a `Not now` button at the top left and **no back chevron**.

Result:

### 2. SIGN-06 — the hub stays open; the app never jumps back to a home route (05-07)

**Status:** PENDING.

Steps: from item 1, stay on the hub for about 30 seconds. Open a checklist step (for example Personal details), go back to the hub, and switch to another app and back once.

Expected: the hub stays on screen the whole time. The app never snaps back to client home or Expert home while the hub is open.

Result:

### 3. SIGN-06 — a finished expert enters Expert home (05-07)

**Status:** PENDING.

Steps: as the finished expert, in Client mode: Profile > Mode Switch > Expert.

Expected: Expert home opens (Dashboard). The hub does not appear.

Result:

### 4. SIGN-06 / D-02 — a failed setup lookup fails open: airplane mode enters Expert, also right after Publish (05-07)

**Status:** PENDING.

Steps:
1. As the finished expert, turn airplane mode on, then Profile > Mode Switch > Expert.
2. Turn airplane mode off. Switch back to Client mode.
3. As the unfinished expert, finish setup with Publish (online), land on client home, then immediately turn airplane mode on and pick Expert again, in the same session.

Expected: in both cases Expert home opens with no error and no hub. A cached "setup incomplete" profile never sends a user to the hub; only a successful answer of "incomplete" does.

Result:

### 5. SIGN-06 / D-01 — the hub chrome on every entry: no back chevron, swipe-back blocked, checklist steps still go back (05-16)

**Status:** PENDING (UI-SPEC D1).

Steps: open the hub by each route and try the edge swipe from the left on the hub itself each time:
1. Mode Switch > Expert (item 1).
2. Launch the app with the unfinished expert signed in and Expert mode stored (the `.signupSetup` resume).
3. Sign out, sign in as the unfinished expert (the hub after a login).
4. A fresh expert signup that has not yet published (the hub after signup).
5. On the hub, open a checklist step, then swipe back from that step.

Expected: on every entry the hub has `Not now` and no back chevron, and the edge swipe does nothing. Swipe-back from a checklist step pushed on top returns to the hub (swipe-back is restored for that step). Other screens in the app still swipe back.

Result:

### 6. SIGN-06 — Not now lands on client home on a fresh Explore tab (05-16)

**Status:** PENDING (UI-SPEC D1).

Steps: on the hub from item 1, tap `Not now`.

Expected: client home opens on a fresh Explore tab, in Client mode. No confirmation and no toast. The `Not now` text is the quiet secondary grey-green style, not the bright accent.

Result:

### 7. SIGN-06 / D-01 — the deferral survives a relaunch (05-10, 05-16)

**Status:** PENDING.

Steps: after item 6, force-quit the app and relaunch it. Then background it and reopen it a few times.

Expected: client home, no hub, after the relaunch and after each foreground return.

Result:

### 8. SIGN-06 / D-01 — asking for Expert again clears the deferral and reopens the hub (05-10, 05-16)

**Status:** PENDING.

Steps: with the deferral set (item 7), Profile > Mode Switch > Expert. The hub opens. Without tapping `Not now` or Publish, force-quit and relaunch.

Expected: the hub opens again on the Mode Switch tap, and after the relaunch the hub opens at launch (the deferral was cleared by asking again, and setup is still unfinished).

Result:

### 9. SIGN-06 / D-01 — signing out clears the deferral (05-10, 05-16)

**Status:** PENDING.

Steps: tap `Not now` on the hub (deferral set). Sign out (Profile > Log Out), then sign in with the same account.

Expected: the hub opens after the login. The deferral did not carry across the sign-out.

Result:

### 10. SIGN-06 — Publish from the hub lands on client home, and Expert then works (05-16)

**Status:** PENDING.

Steps: as the unfinished expert, finish the checklist from the hub and tap Publish. Then Profile > Mode Switch > Expert.

Expected: Publish lands on client home (the existing landing), and Mode Switch > Expert now enters Expert home with no hub.

Result:

### 11. SIGN-06 — Mode Switch is blocked during a call on all four screens (05-07, 05-10)

**Status:** PENDING (single-call invariant).

Steps: with a call active (use the second device to book and join a short session), open Mode Switch from each of the four places and pick the other mode:
1. Client shell: the `Mode Switch` route inside the shell.
2. Expert shell: the `Mode Switch` route inside the shell.
3. The client Profile hub (Profile > Mode Switch).
4. The expert Profile hub (Profile > Mode Switch).

Expected: each shows the alert `End the call to switch modes.` and changes nothing: same mode, the call screen unchanged. The two shell routes had no guard before Phase 5, so check them closely. After the call ends, the switch works.

Result:

### 12. SIGN-06 / D-03 — Mode Switch cards are dimmed while a slow lookup runs (05-10, UI-SPEC L1)

**Status:** PENDING. *Optional* if you cannot slow the network.

Steps: Settings > Developer > Network Link Conditioner (a very slow profile), then Profile > Mode Switch > Expert as the unfinished expert. Watch the two cards and try tapping again.

Expected: the two cards are dimmed and disabled (no spinner, no toast, no new text) until the lookup answers, and a second tap cannot start a second switch.

Result:

### 13. SIGN-06 / D-03 — a push for the other mode tapped during a call waits until the call ends (05-10)

**Status:** PENDING.

Steps: on the dual-role account in Client mode, start a call. From the second device, trigger a push meant for the Expert side (for example an expert booking request). Tap the push banner while the call is on screen. Then end the call.

Expected: while the call is active the mode and the call screen are unchanged and no alert appears (a push is not a user tap, so there is no "End the call" message). Once the call ends, the app switches mode and opens the push's destination exactly once.

Result:

### 14. SIGN-06 / D-01 — an expert-targeted push for an unfinished expert opens the notifications list, not the hub (05-10)

**Status:** PENDING.

Steps: as the unfinished expert in Client mode, tap a push that targets the Expert side.

Expected: the notifications list opens. The setup hub is never opened by a push.

Result:

### 15. SIGN-06 / D-02 — the foreground re-check opens the hub after an offline launch (05-12, RESEARCH A6)

**Status:** PENDING (UI-SPEC D4). Part of the A6 check.

Steps:
1. As the unfinished expert, force-quit the app, turn airplane mode on and launch it. Home opens.
2. Turn airplane mode off, background the app, and reopen it.

Expected: home opens first, then after the reopen the setup hub opens. If it never does, A6 is wrong (App-level `scenePhase` does not report `.active`) and the fix is to move the call into the two shells' `scenePhase` handlers; write that in Result.

Result:

### 16. SIGN-06 / D-04 — a client-only account is never promoted by a launch or a foreground (05-10, 05-12)

**Status:** PENDING. Use the client-only account. Do not tap Expert on Mode Switch during this item.

Steps: sign in as the client-only account in Client mode, relaunch, then run the item 15 airplane-mode sequence (launch offline, network on, background, reopen).

Expected: nothing happens. No hub, no Expert mode, no offer of Expert. Neither launch nor foreground makes an `/expert/*` call for this account (check with your backend logs or by confirming the account still has no expert profile afterward). The explicit Expert tap on Mode Switch is the only thing that may promote it (D-04); try that last, on the throwaway account only, and write what you saw.

Result:

### 17. SIGN-06 — the foreground re-check never opens the hub over a live call (05-12)

**Status:** PENDING. *Optional* if item 11 already needed a call.

Steps: repeat the item 15 setup so a re-check is pending (offline launch as the unfinished expert, then network on), start a call, background the app during the call and reopen it.

Expected: the hub does not open while the call is active. It opens on a later foreground after the call ends.

Result:

### 18. SIGN-01 — publish needs a photo and names the missing step (05-04)

**Status:** PENDING.

Steps: as an expert in signup with everything done except the profile photo, go to Review and tap Publish.

Expected: the alert `Couldn't publish profile` with the message `Finish these first: Add profile picture.` and an `OK` button. No request is sent (the profile stays unpublished). With the photo added, Publish succeeds.

Result:

### 19. SIGN-05 — the uploaded photo matches the preview circle (05-03)

**Status:** PENDING (UI-SPEC D2). Needs a real camera-roll photo.

Steps: in signup Profile Photo, pick a **portrait** camera-roll photo, drag the zoom slider most of the way, Save. Then open the Overview or the expert profile and compare the avatar to the preview circle you saved. Repeat with a landscape photo. Also reopen the Profile Photo step on a profile that already has a downloaded avatar and look at the zoom slider.

Expected: the avatar is framed the same as the preview circle (centred, same zoom, upright, not the whole original). For the downloaded avatar the zoom slider is disabled and Save succeeds without uploading.

Result:

### 20. SIGN-03 — tags and languages keep the order tapped (05-02)

**Status:** PENDING.

Steps: in signup, tap three expertise tags in a deliberate non-alphabetical order (note the first), then three languages in a deliberate order. Look at the Selected Tags strip and the language rows, finish setup, and reopen the profile.

Expected: the Selected Tags strip and the language rows show your tapped order. The first tag tapped is the primary tag on the saved profile. Deselecting then reselecting one puts it last.

Result:

### 21. SIGN-04 / D-05 — country is normalized and the province is optional on publish (05-04)

**Status:** PENDING.

Steps: in signup Basic Info, leave **Province/State (optional)** empty, choose a country and a city, finish setup and Publish.

Expected: the placeholder reads `Province/State (optional)`, Basic Info completes with no province, and Publish succeeds. The country shows by name on the profile. (The `"ca "` to `CAN` normalization is unit-tested; you cannot type a malformed code from the picker.)

Result:

### 22. D-07 — a province can be cleared in settings and stays cleared (05-04, 05-09)

**Status:** PENDING.

Steps: on a profile that has a province, open Profile > profile settings (client, then expert), empty the State/Province field, wait for the saved checkmark, leave, and reopen the screen from the server.

Expected: the field is still empty after reopening. No error. (The wire rule, `""` and never `null`, is unit-tested on both screens.)

Result:

**Re-test for G-05-6 (plans 05-19, 05-20)**

**Status:** PENDING.

Why: the UAT found every Profile Settings save failing with "Please check the information you entered and try again.", because the screen sent empty first and last names, which the server rejects. The new build sends only the changed groups and never an empty name. A name the user clears is held back and flagged under its field.

Needs: a build at or after `a0310ca` (plan 05-20, Task 2). An account with an empty first and last name (the unfinished expert, or a fresh throwaway signup that has never typed a name in Profile Settings). An expert whose Last Name is empty (any expert created on iOS who never typed one). An account with a first name set.

Steps:

1. On the empty-name account, open client Profile Settings, clear State/Province (set one first if it is empty), wait for the checkmark, leave, and reopen.
2. Edit Bio, wait for the checkmark, and reopen.
3. Change the spoken languages and save.
4. On the expert with an empty Last Name, open Expert Settings, edit City and the Skype / Zoom link, wait for the checkmark, and reopen.
5. On the account with a first name, clear First Name, then edit City while it is empty, wait for the checkmark, leave, and reopen. Then type the name back.

Expected:

- Steps 1 to 4 show no "Couldn't save changes" alert, and each edit is still there after reopening.
- In step 5, "Please enter your first name." shows in red under First Name with no alert, and City saves. After reopening, First Name shows the old name and City the new value. Typing the name back removes the error.
- A9 is unchanged: Done in the language picker with nothing selected still shows "Keep at least one language."

Result:

### 23. D-06 — locations read "City, Country" or "City, Province, Country" with no stray comma (05-04)

**Status:** PENDING.

Steps: as an expert, open a client's profile from a booking or a chat where that client has a province, and one where they have none (a profile saved with no province, or the province cleared in item 22).

Expected: the Location row reads `{City}, {Province}, {Country name}` with a province and `{City}, {Country name}` without one: no stray comma, no blank.

Result:

### 24. SIGN-02 — resuming signup keeps the verified email ticked (05-11)

**Status:** PENDING.

Steps: start an expert signup, verify the email, force-quit before publishing, relaunch.

Expected: the hub opens with Verify email ticked, and the progress ring includes it. (A brief moment of Verify email unticked before the status read returns is the accepted U4 flash, judged in item 45.)

Result:

### 25. SET-01 — client profile language edits save and come back from the server, including a custom language (05-09)

**Status:** PENDING.

Steps: as a client, Profile > profile settings > Spoken Languages. Change the selection (add one, remove one), including a language that is not in the catalog if the screen lets you type one. Wait for the saved checkmark, leave, reopen the screen.

Expected: the new languages and their order are shown from the server, and any custom language is still there (the picker cannot delete customs). The picker is the searchable `LanguageSelectionView`, not the old 12-label sheet.

Result:

### 26. SET-01 — expert profile language edits save the same way (05-09)

**Status:** PENDING.

Steps: repeat item 25 on the Expert profile settings screen.

Expected: same result as item 25. A text-only edit (change the bio, not the languages) leaves the languages untouched.

Result:

### 27. SET-01 / EM4 — a profile with no languages shows "Add languages" and the chips wrap (05-09)

**Status:** PENDING. *Optional* if you have no account with zero languages.

Steps: open settings on a profile that has zero languages (or look at the preview if you have none). Also pick many languages and watch the row.

Expected: with none, the row shows `Add languages` in muted text under `Spoken Languages`. With many, the chips wrap onto more lines instead of running off screen. Done with zero selected on a profile that already had none does nothing (no alert).

Result:

### 28. SET-01 / A9 — a Done with nothing selected keeps the previous languages (05-09; UI-SPEC A9, EM4) — YOUR DECISION

**Status:** PENDING. **Product assumption A9 for you to confirm.** The backend accepts an empty language list and deletes every language row (`userProfile.schema.js:59-61` has no minimum), so Phase 5 made this an iOS rule: settings never saves an empty list. Signup already requires at least one language.

Steps: on a profile that has languages, open Spoken Languages, deselect every language and tap Done.

Expected: the alert `Couldn't save changes` with the message `Keep at least one language.` and an `OK` button; the previous languages are still shown; no request is sent (confirm by reopening the screen). Then decide whether you want a user to be able to clear all languages.

Result: (KEEP = never save an empty list, or CHANGE = allow it)

### 29. SET-04 — opening Notification preferences saves nothing (05-05)

**Status:** PENDING. *Optional* (4 unit tests cover it); the on-device check is the visible half.

Steps: from the second device (or Android), turn one preference off on the account. On the iPhone open Profile > Notifications, wait about 3 seconds, and leave. Reopen it.

Expected: the preference you turned off is still off, and no saved indicator or error appears on open. Flipping one toggle shows the saved indicator once.

Result:

### 30. SET-05 — Feedback needs 10 characters (05-05)

**Status:** PENDING.

Steps: Settings > Feedback. Type 9 characters and submit. Then type text padded with spaces so the trimmed text is 9 characters and submit. Then type 10 characters and submit.

Expected: under 10 (after trimming) shows the red inline message `Please enter at least 10 characters.` in small regular-weight text, keeps your text and sends nothing. The message clears only once the text is long enough. 10 characters send, and the form clears with the thanks (unchanged behavior).

Result:

### 31. SET-02 — Help > Email Us opens Mail addressed to the support inbox (05-05)

**Status:** PENDING (UI-SPEC D3). SET-02 stays Pending until this item passes.

Steps: Profile > Help > Email Us.

Expected: the default mail app opens with a new message addressed to `clickmeapp@uptrendinvestments.net`. Close it without sending. If you have no mail account set up, write `SKIPPED (why)`.

Result:

### 32. T8 / D-14 — Login pre-fills the last email after each sign-out path, password empty (05-01)

**Status:** PENDING (UI-SPEC D6). The unit suite cannot sign out the shared manager.

Steps: sign in with an account, then Profile > Log Out. Look at the Login screen. Edit the pre-filled email (change one character, then clear it) to confirm it is editable. Force-quit and relaunch from the Login screen and look again. If you can, repeat after a forced logout (a suspended account, or a session you revoke from another device).

Expected: the email field opens with the last signed-in email and the password field is empty, after the sign-out and after a relaunch. The field is editable. The suspension alert (if you saw one) is unchanged, just over a pre-filled email. A very long email scrolls in the field.

Result:

### 33. T8 / D-14 — the remembered email is forgotten after a successful account deletion (05-01)

**Status:** PENDING. **Throwaway account only.** Combine with item 40.

Steps: sign in as the throwaway account, delete it through Delete Account (item 40), then look at the Login screen.

Expected: the email field is empty. A deletion that fails (for example a wrong password, or a 409 blocker) keeps the email.

Result:

### 34. SET-06 / SET-03 — Delete Account, confirmation step: permanence line, upfront line, three groups, no Pause card (05-15)

**Status:** PENDING. Open the screen with a throwaway account; do not delete anything yet.

Steps: Settings > Account > Delete Account. Read the first step. Then increase Dynamic Type to the largest accessibility size (Settings > Accessibility > Display & Text Size > Larger Text) and scroll the whole step.

Expected:
- The headline `Are you sure you want to delete your account?`, then `Deleting your account is permanent and can't be undone.`, then `Before you delete, cancel or finish any upcoming sessions. Requests you've sent that haven't been answered yet are cancelled for you, and any hold on your card is released.`
- Three groups, bold title over body: `Deleted`, `Kept without your personal details`, `Kept`, with the bodies exactly as in `AccountDeletionCopy.swift`.
- There is **no** `Before you go...` title and **no** Pause Account card.
- The copy is readable, with even spacing (about 16 pt between blocks), and at the largest size every group wraps with nothing truncated, the screen scrolls, and the last line stays clear of the bottom buttons.

Result:

### 35. SET-06 — Delete Account, feedback step: headline and permanence line only (05-15)

**Status:** PENDING.

Steps: from item 34 tap Delete Account to reach the reason and password step.

Expected: only the headline and `Deleting your account is permanent and can't be undone.` sit above the reason form (the long copy was read once, on the first step). The step order is unchanged: confirmation, reason and password, farewell.

Result:

### 36. SET-06 / U3 — saved cards: the copy makes no claim either way (05-15; UI-SPEC U3, A6) — YOUR DECISION

**Status:** PENDING. **Planner assumption U3 for you to confirm.** Deleting an account does not detach saved cards (the backend never calls `detachPaymentMethod` from the delete cascade), and the Delete Account copy deliberately says nothing about cards.

Steps: read the Delete Account copy once more (item 34). Decide whether it should say, for example, `Saved cards are not removed by deleting your account.`, or whether the backend should detach cards. The decision todo is `.planning/todos/pending/2026-11-13-decide-saved-cards-on-account-deletion.md`.

Expected: nothing on screen changes in this phase. You record whether the silence is acceptable.

Result: (KEEP = no card claim for this release, or CHANGE (what))

### 37. SET-06 — a client with a confirmed upcoming session gets the blocker alert, and View My Bookings opens My Bookings (05-08)

**Status:** PENDING. Use the client with a confirmed upcoming session. The server refuses the delete, so the account is not deleted; still, only use an account you could afford to lose if the refusal did not happen.

Steps: Delete Account > Delete Account, enter the reason and password, confirm. When the alert appears, read it, then tap `View My Bookings`. Go back to Delete Account and try the same confirm once more, without cancelling anything.

Expected: the alert titled `You can't delete your account yet` with `You have upcoming sessions booked. Cancel them, then try again.` and two buttons, `View My Bookings` and `OK`. You stay on the reason step. `View My Bookings` opens the Bookings tab (the Profile stack is back at its root when you return to it). A second attempt asks the server again and shows the same alert; it does not hang on a spent token.

Result:

### 38. SET-06 — the blocker alert from the Expert shell: View My Bookings opens the expert Bookings tab (05-14)

**Status:** PENDING. Use an expert in Expert mode with an upcoming booking.

Steps: Profile > Delete Account, confirm with the password, read the alert, tap `View My Bookings`.

Expected: `You have upcoming bookings as an expert. Cancel or finish them, then try again.` with `View My Bookings` and `OK`. The button opens the expert Bookings tab and the Profile tab is back at its root when reopened. As a client, `View My Bookings` on Request Sent still opens My Bookings (unchanged).

Result:

### 39. SET-06 — a dual-role user in the wrong mode sees the switch-mode message and no bookings button (05-08)

**Status:** PENDING. Use the dual-role account with an upcoming booking on each side.

Steps: in Client mode, start Delete Account and confirm. Switch to Expert mode and repeat. Which blocker the server reports first depends on its check order; the rule below holds either way.

Expected: when the blocker is on the other mode's side, the message names the mode to switch to (`You have upcoming bookings as an expert. Switch to Expert mode to cancel or finish them, then try again.` or `You have upcoming sessions booked as a client. Switch to Client mode to cancel them, then try again.`) and there is **no** `View My Bookings` button, only `OK`. When the blocker is on the active mode's side, the button shows (items 37 and 38).

Result:

### 40. SET-06 — deleting a throwaway account completes the flow (05-01, 05-15)

**Status:** PENDING. **Throwaway account with no upcoming bookings only. Irreversible.** Run item 33 right after.

Steps: Delete Account > Delete Account, choose a reason, enter the password, confirm.

Expected: the farewell screen appears, then Login. The earlier steps behave as in items 34 and 35, and the `Delete Account` button is the only red control.

Result:

### 41. SET-07 — the Cancellation policy link from the Bookings-tab cancel flow (05-06, RESEARCH A5)

**Status:** PENDING (UI-SPEC D5). SET-07 stays Pending until items 41 and 42 pass.

Steps: as a client with a confirmed booking, Bookings tab > the booking > Cancel, choose a reason, continue to the confirmation, tap `Cancellation policy`. Then go back.

Expected: the link (underlined, green, centred between the 24-hour notice and the buttons) opens the Cancellation Policies screen (three cards). Back returns to the confirmation with the same reason still selected. If the link does nothing or the screen does not push, A5 is wrong; the fallback is a sheet, and you write that in Result.

Result:

### 42. SET-07 — the Cancellation policy link from a Home-route cancel (05-06, RESEARCH A5)

**Status:** PENDING (UI-SPEC D5, N3).

Steps: open a booking from the Explore tab's upcoming card (the Home-route cancel), start Cancel, continue to the confirmation, tap `Cancellation policy`, then go back.

Expected: the same as item 41, pushed onto the Explore stack, with the reason kept.

Result:

### 43. SET-07 — the corrected policy copy and the refund footnote (05-06)

**Status:** PENDING.

Steps: on the Cancellation Policies screen read How to Initiate a Cancellation. On the cancel confirmation of a booking that would be refunded (more than 24 hours before the start), read the footnote; on one inside 24 hours, check there is none.

Expected: the intro reads `To cancel a booking, follow the steps below. You can start a cancellation from the Bookings tab until the session ends.` Step 3 reads `Tap 'Cancel'.` The refund footnote appears only when a refund applies and reads `Your bank decides how long a refund takes to appear.` with no business-days promise.

Result:

### 44. SET-07 / U2 — the policy link's tap target (UI-SPEC U2) — YOUR DECISION

**Status:** PENDING. **Planner assumption U2 for you to confirm.** The link has a text-height tap area only (no 44 pt minimum).

Steps: tap the `Cancellation policy` link about ten times with a normal thumb on the confirmation screen.

Expected: it opens reliably. Note any mis-tap.

Result: (KEEP = leave as shipped, or CHANGE (what), for example a 44 pt hit area)

### 45. SIGN-02 / U4 — the Verify email flash on resume (UI-SPEC U4) — YOUR DECISION

**Status:** PENDING. **Planner assumption U4 for you to confirm.** The hub may show Verify email unticked for a moment before the status read returns; no spinner.

Steps: do item 24 again, this time watching the checklist as the hub appears, on a normal and on a slow network.

Expected: at most a brief flash of Verify email unticked, then ticked, with the progress ring updating to match.

Result: (KEEP = accept the flash, or CHANGE (what))

### 46. SIGN-06 / A1 — the Not now button style (UI-SPEC A1) — YOUR DECISION

**Status:** PENDING. **Assumption A1 for you to confirm.** `Not now` is a quiet leading toolbar button in secondary text colour at body size, not the accent, so it does not compete with the Continue and Publish capsule (Android also shows `Not now`, D-27).

Steps: look at the hub with a few steps done.

Expected: the checklist and progress ring are the focal point; `Not now` is visible and tappable (system toolbar button, 44 pt target) without competing with Continue.

Result: (KEEP, or CHANGE (what))

**Re-test for G-05-1 (plan 05-18)**

**Status:** PENDING.

Why: the UAT found `Not now` illegible (pale text on a light grey capsule). The fix pins the hub's nav bar dark, like every sibling signup screen. A1's quiet style is kept.

Needs: an iPhone on iOS 26 with a build at or after `0d44688` (plan 05-18, Task 1), and a way to reach the hub (an expert with unfinished setup, or a fresh signup on a throwaway account, which lands on the hub).

Steps:

1. Settings > Display & Brightness > Light.
2. Settings > Accessibility > Display & Text Size > Reduce Transparency on.
3. Open the hub and read `Not now`.
4. Turn Reduce Transparency off, set Settings > Display & Brightness > Liquid Glass to Tinted (iOS 26.1 or later; if your iOS has no such setting, write that down), and read it again.
5. Read it once more in Dark appearance.
6. Tap `Not now`.
7. Restore your settings.

Expected: in every combination `Not now` is pale text on a dark capsule (never a light grey capsule) and reads clearly. It sits at the top left at body size, is not accent green, and has no back chevron beside it. Tapping it lands on client home.

Result:

### 47. SET-06 — Delete during a call, and the session-in-progress blocker (05-08) *optional*

**Status:** PENDING. *Optional*; both paths are unit-tested.

Steps: with a call active, open Delete Account and tap Delete Account on each step. Separately, with a confirmed session that is live or starts within 15 minutes, attempt a delete.

Expected: during a call, the alert `End the call to delete your account.` on both steps (existing behavior, unchanged by Phase 5). With a session in progress or about to start, the blocker alert reads `A session is in progress or starts within 15 minutes. Wait until it ends, then try again.` with `View My Bookings` in either mode (`SKIPPED (why)` if you have no session starting soon).

Result:

---

## Summary

Fill in after the run: items passed, failed and skipped; the SIGN, SET and T8 requirements you consider closed; the decisions made on items 28, 36, 44, 45 and 46. Then run `/gsd-verify-work 05`, which decides what ticks in `REQUIREMENTS.md`.
