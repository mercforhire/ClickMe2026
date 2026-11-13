---
created: 2026-11-13T00:00:00.000Z
title: Android cancellation policy link and corrected policy copy (D-12)
area: bookings
severity: low
files:
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/cancellation/ClientCancellationScreen.kt
  - ClickMe_Android/app/src/main/res/values/strings_cancel_booking.xml
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation Policies/Subviews/HowToInitiateCard.swift
  - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift
---

## Problem

On iOS, `CancellationPoliciesView` existed but nothing linked to it. Phase 5 (plan 05-06, SET-07, D-12) links it from the cancel confirmation and corrects its copy.

Android, read 2026-11-13 (nothing run on an Android device): a grep of `app/src/main` for cancellation-policy screens or links found none. The `screens/clientmode/cancellation/` folder holds the cancel flow only (`ClientCancellationScreen`, `ClientCancellationViewModel`, `RefundPreview` and subviews), and the only policy text is the string `cancel_booking_refund_policy` ("Any refund follows our cancellation policy."), which is not a link. Re-check before building: if Android has a policy screen that the 2026-11-13 grep missed, the todo reduces to a device check that it is reachable from the cancel confirmation and that its copy matches the below.

Android's refund note is also the old claim iOS removed: `cancel_booking_refund_note` reads "Refunds typically appear in your account within 3-5 business days." The backend gives no such promise.

## What to do

1. Add a `Cancellation policy` text link on the cancel confirmation step (the one with the reason selector), between the 24-hour notice and the action buttons, centred, underlined, in the screen's accent colour. It opens the cancellation policy screen; Back returns to the confirmation with the selected reason intact. Android needs the policy screen first if it has none: three cards (Cancellation Deadlines, Refund Eligibility, How to Initiate a Cancellation), content from the iOS `CancellationPoliciesView`.
2. Use the corrected iOS copy:
   - How to Initiate, intro: `To cancel a booking, follow the steps below. You can start a cancellation from the Bookings tab until the session ends.`
   - How to Initiate, steps: `Go to the 'Bookings' section of the app.` / `Find the booking you wish to cancel.` / `Tap 'Cancel'.` / `Follow the on-screen instructions.` (the real button label is `Cancel`, not `Cancel Booking`).
   - Refund footnote, refund cases only: `Your bank decides how long a refund takes to appear.` (no business-days promise). Replace Android's `cancel_booking_refund_note`.
3. The Deadlines and Refund Eligibility cards are unchanged on iOS: a full refund only when the cancellation is strictly more than 24 hours before the start, otherwise none (`refund.js` and the FAQ migration `20261113000200_faq_content_match_terms.sql`). Check Android's wording says the same.
4. Out of scope: expert-cancel refund wording (iOS Phase 6, Q2).
