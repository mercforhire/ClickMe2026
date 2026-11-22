---
created: 2026-11-13T00:00:00.000Z
title: Decide what to do about saved cards when an account is deleted (RESEARCH Open Question 1)
area: account
severity: medium
files:
  - ClickMe2026 Backend/src/services/accountCascade.js
  - ClickMe2026 Backend/src/controllers/paymentMethods.controller.js
  - ClickMe2026/Utils/AccountDeletionCopy.swift
  - .planning/phases/05-signup-mode-switch-and-account/05-RESEARCH.md
---

## Problem

Deleting an account does not detach the user's saved cards. In the backend, `detachPaymentMethod` is only reached from `paymentMethods.controller.js` (the user removing a card in the app). `accountCascade.purgeAndLockAccount` never calls it, so a deleted user's saved cards stay attached to their Stripe customer.

Phase 5 (plan 05-15, SET-06) rewrote the Delete Account copy so it no longer claims payment details are removed, and it makes no claim about saved cards either way (`AccountDeletionCopy` has no card line; its tests forbid `saved card` and `payment details`). That keeps the copy true, but it leaves the question open, and it is a privacy decision, not a code fix.

No code change was made. This is a product and privacy decision for the user.

## What to do

Decide one of:

1. **Disclose it.** Add a fourth line to the Delete Account copy on iOS and Android, for example `Saved cards are not removed by deleting your account.` (UI-SPEC row U3 suggests this wording). iOS-only change plus the Android copy port; no backend change.
2. **Detach on delete.** Add a backend step to `accountCascade.purgeAndLockAccount` that detaches the user's saved payment methods. Constraints: the change must be additive and safe for the live App Store build 6 and the current Android build; payment changes need care because the backend is production with live Stripe holds and charges. Check first that no booking that still needs the card (an authorized hold, a long-lead booking the sweep will charge) loses it, which is why the cascade cancels unanswered requests and voids their holds before the purge. A backend change is committed in the backend repo, with backend tests, separately from any iOS change.
3. **Leave it** and record why (for example, the cards are only usable by the deleted customer and Stripe retains them for dispute handling).

Whichever is chosen, update `AccountDeletionCopy` and the Android port together (the Android todo `2026-11-13-android-delete-account-copy-and-blockers.md` carries the current strings).

## Resolution

Resolved 2026-11-22 in phase 08 plan 08-13 (D-23): option 1, disclose it (checkpoint choice `option-a`).

User answer, verbatim: "option-a" (2026-11-22). Final wording, unchanged from the proposed default: "Cards you added to pay for sessions are not deleted with your account."

- iOS: `AccountDeletionCopy.savedCardsNote`, rendered on the Delete Account confirmation step after the three groups (not on the feedback step). Commit e18f70f (`feat(08-13)`), pinned by `AccountDeletionCopyTests`. The text contains none of `removed`, `saved card` or `payment details`, so `noFalseClaims` passes unchanged and needed no exemption.
- No backend or payment change. Detaching on delete (option 2) was not chosen.
- Android: the "Saved-cards line (confirmation step only)" row in `2026-11-13-android-delete-account-copy-and-blockers.md` carries the string word for word. The port happens in plan 08-17.
