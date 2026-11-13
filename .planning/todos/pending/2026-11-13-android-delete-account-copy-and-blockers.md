---
created: 2026-11-13T00:00:00.000Z
title: Android Delete Account copy and 409 blocker alert (port iOS Phase 5, D-11)
area: account
severity: high
files:
  - ClickMe_Android/app/src/main/res/values/strings_delete_account.xml
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/DeleteAccountViewModel.kt
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/deleteaccount/subviews/DeleteAccountComponents.kt
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/model/enums/ErrorCode.kt
  - ClickMe2026/Utils/AccountDeletionCopy.swift
  - ClickMe2026/Utils/AccountDeletionBlocker.swift
---

## Problem

Android's `delete_account_body` (`strings_delete_account.xml`) makes the same false claim iOS removed in Phase 5 (plan 05-15, SET-06): "Deleting your account is permanent and cannot be undone. All your data, including bookings, profile information, and payment details, will be permanently removed." The backend does not do that. `accountCascade.purgeAndLockAccount` keeps bookings (anonymized), keeps messages and reviews, and keeps payment records, and it does not detach saved cards.

Android also has no blocker handling for the self-delete 409s. Read 2026-11-13 (nothing run on an Android device):

- `ErrorCode.kt` already declares `ClientHasUpcomingBookings("CLIENT_HAS_UPCOMING_BOOKINGS")`, `ExpertHasUpcomingBookings` and `SessionInProgress`, so the codes decode.
- `DeleteAccountViewModel.onFailure` treats every 409 the same way: a dialog showing the server message (`e.status == HTTP_CONFLICT`), or the generic text. It never branches on the three codes, shows no "View My Bookings" button, and says nothing about switching modes for a dual-role user. So `CLIENT_HAS_UPCOMING_BOOKINGS` is mapped only to the server message, not to the iOS behavior below.
- The `ClickMeApi.requestAccountDeletion` doc comment mentions only `EXPERT_HAS_UPCOMING_BOOKINGS`.

## What to do

Android is a port of iOS, and iOS is the source of truth for behavior. Copy these strings word for word from `ClickMe2026/Utils/AccountDeletionCopy.swift` (final, plan 05-15) and `ClickMe2026/Utils/AccountDeletionBlocker.swift` (final, plan 05-08). If either Swift file changes, change this todo and Android together.

### Delete Account header (replace `delete_account_body`)

Shown on the confirmation step. The feedback (reason and password) step shows the headline and the permanence line only. Remove the paragraph that claims everything is removed.

| Element | Text |
|---------|------|
| Permanence line (both steps) | `Deleting your account is permanent and can't be undone.` |
| Upfront line (confirmation step only) | `Before you delete, cancel or finish any upcoming sessions. Requests you've sent that haven't been answered yet are cancelled for you, and any hold on your card is released.` |
| Group 1 title | `Deleted` |
| Group 1 body | `Your name, photo, bio and location, your devices, your notifications and preferences, and your uploaded profile photos.` |
| Group 2 title | `Kept without your personal details` |
| Group 2 body | `Your past bookings stay on record, shown as from "Deleted user". Your private notes on them are erased.` |
| Group 3 title | `Kept` |
| Group 3 body | `Messages and reviews you've written stay visible to the other person, shown as from "Deleted user". Payment records are kept.` |

Rules iOS tests enforce: none of the strings may contain `removed`, `saved card` or `payment details`; together they must contain `visible to the other person`, `Deleted user` and `upcoming`. No saved-card claim either way (see `2026-11-13-decide-saved-cards-on-account-deletion.md`). The `Before you go...` title and the Pause Account card are removed on iOS (SET-03); check Android has no equivalent.

### Blocker alert for the three 409 codes

Shown when `POST /user/account/delete-request` or `DELETE /user/account` returns 409. Branch on the error code, never on the server message. The text is client-owned and names no booking, person or amount. The user stays on the reason and password step, and a retry runs both calls again (a new single-use token).

Title: `You can't delete your account yet`

| Code | Active mode | Message | Bookings button |
|------|-------------|---------|-----------------|
| `EXPERT_HAS_UPCOMING_BOOKINGS` | Expert | `You have upcoming bookings as an expert. Cancel or finish them, then try again.` | `View My Bookings` |
| `EXPERT_HAS_UPCOMING_BOOKINGS` | Client | `You have upcoming bookings as an expert. Switch to Expert mode to cancel or finish them, then try again.` | none |
| `CLIENT_HAS_UPCOMING_BOOKINGS` | Client | `You have upcoming sessions booked. Cancel them, then try again.` | `View My Bookings` |
| `CLIENT_HAS_UPCOMING_BOOKINGS` | Expert | `You have upcoming sessions booked as a client. Switch to Client mode to cancel them, then try again.` | none |
| `SESSION_IN_PROGRESS` | either | `A session is in progress or starts within 15 minutes. Wait until it ends, then try again.` | `View My Bookings` |

- Buttons: `View My Bookings` (default, only when the table says so) and a dismiss button. iOS uses the system `OK`; Android's existing dialog uses `Got it` (`delete_account_got_it`), which can stay.
- Mode rule for the bookings action: the button shows only when the blocker's side matches the active mode (expert blocker in Expert mode, client blocker in Client mode, `SESSION_IN_PROGRESS` in either). It opens the Bookings tab of the active mode with the Profile stack reset to its root.
- An unknown 409 code keeps the existing behavior: the generic failure dialog with the server message.
- `CLIENT_HAS_UPCOMING_BOOKINGS` mapping: Android already decodes it. Add the `ClientHasUpcomingBookings` branch beside the two existing ones. A 409 on the client side blocks confirmed and pending_reschedule sessions; `pending_approval` requests do not block (they are cancelled for the user, which is what the upfront line says).

Verify on an Android device with a throwaway account. Delete Account is irreversible against the production backend.
