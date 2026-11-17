---
status: diagnosed
phase: 06-expert-mode
source: [06-VERIFICATION.md]
started: 2026-11-16T19:20:00Z
updated: 2026-11-17T02:52:41.637Z
---

## Current Test

[testing complete]

## Tests

### 1. Run the whole 06-DEVICE-UAT-CHECKLIST.md (35 items) on a real iPhone against build 9e95cf3 or later
expected: Every item PASS, or KEEP/CHANGE for items 34 and 35
result: issue
reported: "Item 1: The price on this screen should have two digits after the decimal (Topics tab cards show CA$50 / US$5). Item 4: Some topics have a third currency which is invisible. This could be a bug on the backend. Item 8: By default, all the free topics open with an unknown currency, which causes a problem at save. Item 17: Add this \"Add to Calendar\" button on the booking summary screen for both client and expert, so this screen can be reached repeatedly."
severity: blocker
checklist: 29 PASS, 1 FAIL (item 4), 3 SKIPPED (12 no such slot; 13 and 16 iOS 26 glass checks, no reason given), KEEP on 34 and 35. Item 1 PASS with a cosmetic card-format issue; item 17 PASS with a change request. Per-item results are in 06-DEVICE-UAT-CHECKLIST.md.

### 2. Accept a request: Booking Confirmed shows, Back reveals a refreshed list, and a request already cancelled on a second device gives the 409 alert and a pop (items 14, 15, 19)
expected: No "Accepted!" frame; the 409 message shows and the screen pops
result: pass

### 3. Type or paste past the cap in the accept message (1,000) and the note (5,000), including an emoji across the boundary (items 20, 26, 31)
expected: The editor shows the truncated text, not the extra character (review IN-05)
result: pass

### 4. Open an expired request card on App Store build 6, then on the new build (items 21, 22, 35)
expected: Text is readable after the fix; decide whether EXP-12 was a real problem
result: pass

### 5. Decision: WR-01 (an expired or settled request opened from a push still shows Accept and Decline)
expected: A recorded disposition in 06-REVIEW-DISPOSITION.md (fix in Phase 6 with an additive backend change to getDetail plus an Android check, defer, or accept)
result: pass
disposition: accepted (recorded in 06-REVIEW-DISPOSITION.md)

### 6. Decision: WR-02 (a legacy free topic with a NULL stored currency opens on an empty currency and gets a 422 on Save) and WR-03 (a pasted "12,000" becomes 12.00)
expected: A recorded disposition for each; WR-03 touches a live price
result: pass
note: WR-02 is a fix in Phase 6, settled by device evidence (checklist items 4 and 8: every free topic is affected; gap G-06-1-currency). WR-03 is accepted ("The price is not likely to reach 1,000, so accept, or we can set a reasonable maximal price."); the maximum-price idea is a deferred follow-up below.

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-06-1-currency
  truth: "A free topic opens on CAD or USD in the editor and saves without error (checklist items 4, 8; review WR-02)"
  status: failed
  reason: "User reported: Some topics have a third currency which is invisible. This could be a bug on the backend. / By default, all the free topics open with an unknown currency, which causes a problem at save."
  severity: blocker
  test: 1
  root_cause: "iOS regression from commit 73e729e: TopicEditorViewModel seeds currency with `hourlyRate?.currency ?? price.currency ?? default`; `??` does not skip \"\", and the backend serializes a NULL price_currency as \"\" (expertTopics.controller.js:95). So free topics with NULL currency (created by API scripts/seeds, never backfilled because PATCH never writes currency while a topic stays free) open on \"\", pickableCurrencies adds it as a blank third segment, and every save sends hourly_rate.currency \"\" -> 422. App Store build 6 unaffected; Android already ignores blank codes (917ab205)."
  artifacts:
    - path: "ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift"
      issue: "resolveInitialCurrency, isCurrencyLocked, the price seed and pickableCurrencies accept \"\" as a currency (lines ~104-107, 165-175, 207-210)"
    - path: "ClickMe2026Tests/Model/TopicCurrencyTests.swift"
      issue: "No fixture for the real wire shape currency \"\" on a free topic; fixtures still carry an hourly_rate key the server no longer sends"
    - path: "ClickMe2026 Backend/src/controllers/expertTopics.controller.js"
      issue: "Line 95 serializes NULL price_currency as \"\" instead of null (optional, additive hardening)"
  missing:
    - "One iOS helper normalizing a stored currency to a trimmed 3-letter uppercased code or nil (mirror Android validCode/cleanCode), used in resolveInitialCurrency, isCurrencyLocked and the price seed"
    - "TopicCurrencyTests rows for a free topic with currency \"\" and whitespace, using the real response shape (no hourly_rate, amount 0)"
    - "Optional backend hardening: serialize null instead of \"\" and update OpenAPI to string|null (safe for build 6 and Android, both treat currency as optional); a NULL->CAD backfill of live rows is a separate user decision, not part of this fix"
  debug_session: ".planning/debug/free-topic-blank-currency.md"

- gap_id: G-06-1-card-cents
  truth: "Topic cards on the Topics tab show the price with two decimal places (e.g. CA$50.00 / session) (checklist item 1)"
  status: failed
  reason: "User reported: The price on this screen should have two digits after the decimal."
  severity: cosmetic
  test: 1
  root_cause: "TopicsSetupTopicCard.priceLabel formats through Money only when topic.hourlyRate is present; the server stopped sending hourly_rate (50abd85), so the card always falls back to the server price.label, which backend formatPrice.js:37-38 deliberately trims (120.00 -> '120'). Found by the currency debug session and confirmed by the orchestrator."
  artifacts:
    - path: "ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift"
      issue: "priceLabel (line ~23-25) uses Money only when hourlyRate is non-nil, otherwise price.label"
    - path: "ClickMe2026 Backend/src/utils/formatPrice.js"
      issue: "Trims trailing zeros by design; shared with build 6 and Android, so not the place to change"
  missing:
    - "Build the card text on iOS from price.amount + price.currency via Money.format (keep Free for free topics and the per-session suffix), falling back to price.label only when amount/currency are unusable"
    - "Unit test for the card label: CAD 5000 -> CA$50.00, USD 500 -> the Money USD symbol + 5.00, free -> Free"
    - "Check the Android topic card for the same label fallback and mirror if needed"
  debug_session: ".planning/debug/free-topic-blank-currency.md"

- gap_id: G-06-1-summary-calendar
  truth: "Booking Summary has an Add to Calendar button for both client and expert, so the event can be added any time, not only from Booking Confirmed (checklist item 17; Android mirror needed)"
  status: failed
  reason: "User reported: Add this \"Add to Calendar\" button on the booking summary screen for both client and expert, so this screen can be reached repeatedly."
  severity: minor
  test: 1
  root_cause: "Phase 6 scoped Add to Calendar to the expert Booking Confirmed screen only, and CalendarEventEditorSheet takes a BookingConfirmation that only RequestDecisionViewModel.confirmAccept builds, so no other screen can present it. The client has no Add to Calendar anywhere. Android has the same shape (calendarEventSpec tied to the Confirmed nav key). No backend change needed. Note: the client 'Booking Summary' (BookingSummaryView) only opens for finished bookings; the client screen for a future session is UpcomingBookingView, which is the client target."
  artifacts:
    - path: "ClickMe2026/Views/Screens/Expert Mode/Confirmed/Subviews/CalendarEventEditorSheet.swift"
      issue: "Input coupled to BookingConfirmation"
    - path: "ClickMe2026/Model/BookingCalendarPayload.swift"
      issue: "Holds start/end only; natural home for title/notes"
    - path: "ClickMe2026/Utils/ExpertBookingConfirmationContent.swift"
      issue: "calendarTitle/calendarNotes are expert-worded (client-name fallback only)"
    - path: "ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift"
      issue: "No Add to Calendar button"
    - path: "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift"
      issue: "No Add to Calendar button (client target)"
    - path: "ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/confirmed/CalendarIntent.kt"
      issue: "calendarEventSpec tied to the Confirmed nav key"
  missing:
    - "iOS: decouple the sheet to a plain event value (title, notes, start, end), make title/notes builders side-agnostic so the expert summary title matches Booking Confirmed exactly; client title 'ClickMe · {topic} with {expert name}' (fallbacks Session/Expert), notes = meeting type + client's own message"
    - "iOS: status-gated button on ExpertBookingSummaryView and UpcomingBookingView: show for confirmed, pending_reschedule, in_progress while the session has not ended (same set as Join, same minute-tick time gate as client Cancel); hide otherwise"
    - "iOS unit tests for the client title, fallbacks and the status gate"
    - "Android: generalize calendarEventSpec to plain values, reuse the intent/launch helpers and double-tap guard on ExpertBookingSummaryScreen and UpcomingBookingScreen, add the client title string and Expert fallback (one commit in ClickMe_Android)"
  debug_session: ".planning/debug/booking-summary-add-to-calendar.md"

## Deferred Follow-Ups

- test: 6
  idea: "Set a reasonable maximum topic price (iOS, Android and backend validation), which would also bound the WR-03 grouped-paste misread"
  deferred_at: 2026-11-16
