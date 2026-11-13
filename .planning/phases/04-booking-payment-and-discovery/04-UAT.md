---
status: partial
phase: 04-booking-payment-and-discovery
source: [04-VERIFICATION.md]
started: 2026-11-12T19:43:46Z
updated: 2026-11-13T04:52:16.248Z
---

## Current Test

[testing complete]

## Tests

### 1. D-11 real-money session: close the card sheet with a saved card preselected, forced confirm timeout then Try again (with the form-lock taps), SCA/3DS path, remove a card inside the sheet, T-24h sweep
expected: No requires_capture PaymentIntent after closing the sheet; a timed-out confirm lands on the one booking with one hold; 3DS completes into a booking (see WR-01); a removed card is refused at T-24h (production now runs 28da165); payment_method.detached delivered with 200
result: pass
note: "Run 2026-11-12. Steps a, b, d, f and h PASS (sheet close places no hold; paid booking with hold card; timed-out confirm + Try again landed on one booking, one hold; in-sheet card removal delivered payment_method.detached 200 and removed the clone; every hold released, none charged). Step c and step e SKIPPED by user (airplane-mode tests); CR-01 form-lock taps not run. Step g (01-17/01-19) DEFERRED by user, so BACK-06, BACK-07 and BACK-19 stay Pending. No 3DS challenge appeared (WR-01 is test 2). The T-24h refusal of a removed card was not exercised live, by design (04-01 unit tests plus the live detach). Detail in 04-DEVICE-UAT-CHECKLIST.md D-11 a to h."

### 2. WR-01: complete a 3DS challenge on a saved card that requires SCA, then confirm a booking exists
expected: After 3DS the booking is created, with no authorized PaymentIntent stranded without a booking
result: blocked
blocked_by: third-party
reason: "blocked (no saved card triggers a 3DS challenge on live Stripe; none appeared in D-11 step b)"

### 3. UAT item 1, EXPL-07: Explore loads with a free no-currency topic, one bad topic, a failed load
expected: Explore loads every time; a bad featured topic is dropped alone; airplane-mode failure shows a readable sentence and no stale Featured Topics (precondition: migration 20261109000000_home_feed_null_hourly_rate.sql applied in production)
result: issue
reported: "IOS, Pull to refresh on the exports screen is currently broken. Nothing will load."
severity: blocker
note: "Seen working on device 2026-11-12: precondition query returned true; initial Explore load shows a free no-currency topic labelled Free and a Chinese-script title rendered correctly; airplane mode shows 'The Internet connection appears to be offline.' with Retry per section and no stale Featured Topics. Failing part: pull to refresh on Explore loads nothing (also blocks 'a pull to refresh after airplane mode loads normally'). Fix: plan 04-17 (gap G-04-3, resolved); device re-test is test 5."

### 4. UAT item 2, EXPL-03: free featured topic card reads "Free"; paid card shows CA$12.50 style price
expected: Free card reads Free; paid card shows cents
result: pass

### 5. G-04-3 re-test (checklist item 1 step 4): Explore pull to refresh after plan 04-17
expected: On a build that includes 04-17: (a) on a loaded Explore, pull to refresh ten times in a row, letting each finish; (b) airplane mode on, pull to refresh; (c) airplane mode off, pull to refresh. Expected: on each of the ten pulls Trending Categories, Featured Experts and Featured Topics stay on screen while the spinner runs and are replaced in place when it ends. The airplane-mode pull shows the readable offline sentence with Retry in each section and no Featured Topics. The pull after airplane mode is off loads every section. A skeleton that stays after the spinner is gone is a FAIL.
result: pass
note: "2026-11-13: a) pass b) pass c) pass"

### 6. Checklist item 3, BOOK-01 / BOOK-19 / D2: Request Sent has no Back and no swipe, and both exits reset the source tab
expected: Make one free booking (B's free topic) from each of Explore, Search, Profile > Favorite Experts, Bookings (Book Again) and Chats > View Profile. On each Request Sent the title stays "Booking Request", there is no Back button, and neither the edge swipe nor (iOS 26) a content swipe pops it. Back to Home (on two) shows Explore; View My Bookings (on three) shows Bookings; going back to the source tab shows its root, never the Make a Booking form or Request Sent. Swipe-back still works on other screens. Cancel the free bookings afterwards.
result: skipped
reason: "Deferred follow-up: defer"

### 7. Checklist item 4, BOOK-05 / L1 / E1: "Loading booking…" and the Request Sent load error keep both exits
expected: With Network Link Conditioner on a very slow profile, make a free booking. While loading, Request Sent shows the spinner and "Loading booking…" (not "Sending your booking…") with View My Bookings and Back to Home pinned at the bottom. Switch to 100% Loss before it finishes: "Couldn't load your booking" with Retry and the same two exits pinned. Network back, Retry: the screen loads and the entry animation runs only after the copy has loaded. (SKIPPED with a reason if the error state can't be landed.)
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 8. Checklist item 5, BOOK-02 / T2 / T3: month changes never show another month's slots; failed and empty states keep their copy
expected: On Make a Booking for B's topic, tap next/previous month quickly several times: while a month loads the slots card shows its skeleton row, never the previous month's slots, and after the burst the slots match the month shown. A day or month with no slots shows the existing empty copy. With airplane mode on, a month change shows the existing failure copy; with it off, the next month change reloads.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 9. Checklist item 6, BOOK-03 / D-18: the device time zone is named in words on the slots card and on Today's Sessions
expected: The label beside Available Time Slots (Make a Booking) and beside Today's Sessions (Explore, needs a booking today) both show the device zone's localized name, e.g. "Eastern Time", and match each other; never a raw id like America/Toronto and never the expert's zone (also with an expert in another zone, or after changing the phone's zone and relaunching). At the largest Dynamic Type the labels may wrap but are never cut off with an ellipsis. Note if a zone change shows only after relaunch (not a failure). Put Date & Time back on Set Automatically afterwards.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 10. Checklist item 7, BOOK-04 / T1 / T4: slot times follow the 12/24-hour setting, live, and many slots stay readable
expected: With 24-Hour Time on: slot chips, Today's Sessions range, the Reschedule picker (free booking, leave without sending) and Request Sent all show "14:00" style. With the app backgrounded, turn 24-Hour Time off and return without relaunching: all four show "2:00 PM" style on the next render (needing a relaunch is a FAIL). On a day with many slots, with 24-hour on and at the largest Dynamic Type, chips size to their text, wrap into the grid and never clip "12:30 PM".
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 11. Checklist item 8, PAY-03 / D3: the "hold is placed" card shows on a paid Request Sent and is absent on a free one
expected: Paid half already seen in D-11 step b on 2026-11-12 (variant A: What happens next / A hold is placed on your card / Your session runs on … / Your card is charged after the session, no amount). Remaining check: make a free booking and confirm Request Sent shows no payment card at all.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 12. Checklist item 9, EXPL-01 / L3 / E3: expert profile load errors: network failure retries, a missing expert says so
expected: Airplane mode on, open an expert profile not opened yet: "Couldn't load profile", the error message, an accent Retry, and no heart or overflow menu in the toolbar. Network off airplane mode, tap Retry: the capsule becomes a small spinner in place, the state view stays up, then the profile shows (a failed retry brings the state view back). A favorited expert's profile shows a filled heart. Optional (only if you have one): a deleted/suspended expert shows "This profile isn't available" with a single Back, no Retry, no heart or menu.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 13. Checklist item 10, EXPL-02: empty Expertise, Topics and Reviews sections are hidden; the hero reads "No reviews yet"
expected: Chat with an expert who has no reviews > View Profile: no Expertise header, no empty Topics card, no empty Recent Reviews card and no blank gap; About and the stats bar unchanged; the hero reads "No reviews yet" with no star and no 0.0. One review: "{rating} (1 review)". Two or more: "{rating} ({n} reviews)", one decimal. At the largest Dynamic Type the hero rating row and shortened scroll read correctly. (A chat-opened profile showing no Expertise at all is expected.)
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 14. Checklist item 11, EXPL-04 / LT1: search tag pills show their whole text
expected: Give an expert a topic with a 60-character tag and a non-Latin tag, then search for them: every pill shows its full text with no ellipsis, at most three pills show, a pill that doesn't fit moves to the next line, and a pill wider than the row wraps inside the pill (12 pt rounded shape), at normal size and at the largest Dynamic Type. Favorites chips and the expert topic-setup chips look as they did before.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 15. Checklist item 12, EXPL-05 / D-07 / D-08 / D-09: Favorites paging, refresh, empty buttons, Pro Tip and the heart
expected: (Paging needs more than 20 favorites, otherwise note SKIPPED for that part.) Scrolling to the end shows a centered spinner then the rest, no repeats, nothing at the end; an offline next page shows "Couldn't load more favorites" with a 44 pt Retry, rows stay, Retry appends. Pull to refresh restarts at page 1; after an unfavorite no favorite is skipped. Empty state: Pro Tip reads "Tap the heart icon on any expert's profile to add them to this list instantly."; Explore Experts opens Explore and View My History opens Bookings on Past, both leaving Profile at its root. A profile opened from Favorites has a filled heart from the first frame; the same expert from Search starts empty and fills on load.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 16. Checklist item 13, EXPL-06: the full reviews list pages past 20
expected: For an expert with more than 20 reviews (otherwise SKIPPED with why): every review is reachable, spinner footer while loading, no repeats, nothing at the end. An offline later page shows "Couldn't load more reviews" with a 44 pt Retry; rows stay; Retry appends. A pull to refresh while offline keeps the rows and shows no alert. An expert with no reviews still shows "No reviews yet".
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 17. Checklist item 14, D-13 / D4: a suspended account lands on Login with the suspension alert on a cold launch
expected: (Planned for the Phase 8 release pass; needs a suspended account.) Relaunch on a suspended session: the splash goes straight to Login with no home flash, and the alert "Your account has been suspended" / "You can't use ClickMe with this account right now. If you think this is a mistake, contact clickmeapp@uptrendinvestments.net." shows once with Close Alert; a later fresh sign-in doesn't show it again.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 18. Checklist item 15, L5: every new state view, status line, footer, alert and wrapped pill reads correctly at the largest Dynamic Type
expected: At the maximum Larger Accessibility Size, check: the Confirming your booking… line and the "We couldn't confirm your booking" / "Couldn't book" alerts; Request Sent loading, error and loaded states with the pinned exits; the "Couldn't load profile" and "This profile isn't available" views and the hero rating row; the Favorites and Reviews paging footers and the Pro Tip; the wrapped search pills and both zone labels. Every block wraps, nothing is cut off or overlaps, 44/48 pt controls keep their height, nothing needs horizontal scrolling.
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 19. Checklist item 16, K1 (judgment): Request Sent's status pill always reads "Awaiting Approval"
expected: Judge whether a pill that always reads Awaiting Approval on Request Sent is acceptable (a replayed confirm could, in theory, return a booking whose status already moved). Reply KEEP or CHANGE (what).
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 20. Checklist item 17, K3 (judgment): Request Sent uses the same short time style as the slot chips
expected: With 24-Hour Time on, compare the chip on Make a Booking with both times on Request Sent (details card "Oct 24, 2023 | 14:00 - 15:00" and payment-card step 2 "Oct 24 · 14:00"). Judge whether the confirmation reads consistently with the chip. Reply KEEP or CHANGE (what).
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 21. Checklist item 18, K4 (judgment): the slot is cleared after "You may already have this booking"
expected: After the "Couldn't book" / "You may already have this booking. Check My Bookings." alert and Close Alert, the slot selection is cleared and the rest of the form stays intact. It cannot be forced; if never seen, reply SKIPPED (not seen) or give the design judgment. Reply KEEP or CHANGE (what).
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 22. Checklist item 19, K5 (judgment): the seeded profile can flash before a "profile isn't available" screen
expected: With Network Link Conditioner on a slow profile, open a profile from Favorites or a chat: the seeded profile shows with no spinner, then the details load replaces it. Judge whether that flash is confusing enough to want a full-screen spinner instead. Reply KEEP or CHANGE (what).
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 23. Checklist item 20, D-14: Android push prompt after a reinstall (Android device)
expected: On the Android phone, sign in to the current Android build, reinstall the app while signed in, note whether you're still signed in, and note whether the system push prompt appears. Record either outcome. If the prompt does not appear while signed in with notifications off, that's a new Android todo (not a Phase 4 defect).
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 24. Checklist item 21, OQ7 (log if seen): favorites staleness after unfavoriting on a profile
expected: Not expected to be tested. If seen: open a profile from Favorites, unfavorite it with the heart, go Back, and note whether the row is still in the list (a known out-of-scope behavior that becomes a todo).
result: skipped
reason: "Deferred follow-up: defer further device tests"

### 25. Checklist item 22, D-17 (log if seen): "payment still processing" on confirm
expected: Not expected to be tested (a 409 PAYMENT_IN_PROGRESS can't be forced). If seen: the Confirming your booking… line stays up, then Request Sent or the confirm-unknown alert with Try again; never server error copy and never a second hold.
result: skipped
reason: "Deferred follow-up: defer further device tests"

## Summary

total: 25
passed: 3
issues: 1
pending: 0
skipped: 20
blocked: 1

## Gaps

- gap_id: G-04-3
  truth: "Explore loads every time, including on pull to refresh and on a refresh after airplane mode is turned off"
  status: resolved
  reason: "User reported: IOS, Pull to refresh on the exports screen is currently broken. Nothing will load."
  severity: blocker
  test: 3
  screen_confirmed: "Explore (user confirmed 2026-11-12; 'exports' in the verbatim report is a typo for Explore)"
  root_cause: "ExploreClientViewModel.load() sets all three section states to .loading at the start of a pull to refresh, which swaps the loaded sections for skeletons inside the ScrollView that owns .refreshable. SwiftUI cancels the refreshable task when that view re-renders mid-refresh, so getClientHome throws URLError.cancelled. The cancellation branch (ExploreClientViewModel.swift:96-99) reverts every .loading section to .idle and starts no new load; .idle renders the same skeleton as .loading, so Explore is stuck on skeletons with nothing in flight. Diagnosed from code (inline, 2026-11-12); not yet reproduced under a debugger."
  artifacts:
    - path: "ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift"
      issue: ".refreshable { await viewModel.reload() } runs the load in the refresh task, which SwiftUI cancels when the ScrollView content re-renders (lines 140-142)"
    - path: "ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift"
      issue: "load() flips loaded sections to .loading on every reload (75-77); the cancellation branch strands sections at .idle with no reload (96-99)"
  missing:
    - "Run the pull-to-refresh load so it survives the view update (e.g. await an unstructured Task's value from .refreshable, or keep loaded sections visible during a refresh instead of flipping them to .loading)"
    - "A cancelled load must never leave a section at .idle/skeleton with no load in flight: restore the prior state (loaded content or the failed message) or retry"
    - "Unit tests: a reload over loaded data keeps the content when cancelled; a reload after a failure that is cancelled does not strand the skeleton; a successful reload after failure loads normally"
  debug_session: ""
  resolved_by: "04-17-PLAN.md"
  resolved_at: "2026-11-12"

## Deferred Follow-Ups

- test: 1
  idea: "defer (D-11 step g: run the 01-17 and 01-19 real-Stripe checklists; BACK-06, BACK-07, BACK-19 stay Pending)"
  deferred_at: 2026-11-12
- test: 6
  idea: "defer (checklist item 3, BOOK-01 / BOOK-19 / D2: Request Sent no Back/no swipe, exits reset the source tab)"
  deferred_at: 2026-11-13
- test: 7
  idea: "defer further device tests (Checklist item 4, BOOK-05 / L1 / E1)"
  deferred_at: 2026-11-13
- test: 8
  idea: "defer further device tests (Checklist item 5, BOOK-02 / T2 / T3)"
  deferred_at: 2026-11-13
- test: 9
  idea: "defer further device tests (Checklist item 6, BOOK-03 / D-18)"
  deferred_at: 2026-11-13
- test: 10
  idea: "defer further device tests (Checklist item 7, BOOK-04 / T1 / T4)"
  deferred_at: 2026-11-13
- test: 11
  idea: "defer further device tests (Checklist item 8, PAY-03 / D3)"
  deferred_at: 2026-11-13
- test: 12
  idea: "defer further device tests (Checklist item 9, EXPL-01 / L3 / E3)"
  deferred_at: 2026-11-13
- test: 13
  idea: "defer further device tests (Checklist item 10, EXPL-02)"
  deferred_at: 2026-11-13
- test: 14
  idea: "defer further device tests (Checklist item 11, EXPL-04 / LT1)"
  deferred_at: 2026-11-13
- test: 15
  idea: "defer further device tests (Checklist item 12, EXPL-05 / D-07 / D-08 / D-09)"
  deferred_at: 2026-11-13
- test: 16
  idea: "defer further device tests (Checklist item 13, EXPL-06)"
  deferred_at: 2026-11-13
- test: 17
  idea: "defer further device tests (Checklist item 14, D-13 / D4)"
  deferred_at: 2026-11-13
- test: 18
  idea: "defer further device tests (Checklist item 15, L5)"
  deferred_at: 2026-11-13
- test: 19
  idea: "defer further device tests (Checklist item 16, K1 (judgment))"
  deferred_at: 2026-11-13
- test: 20
  idea: "defer further device tests (Checklist item 17, K3 (judgment))"
  deferred_at: 2026-11-13
- test: 21
  idea: "defer further device tests (Checklist item 18, K4 (judgment))"
  deferred_at: 2026-11-13
- test: 22
  idea: "defer further device tests (Checklist item 19, K5 (judgment))"
  deferred_at: 2026-11-13
- test: 23
  idea: "defer further device tests (Checklist item 20, D-14)"
  deferred_at: 2026-11-13
- test: 24
  idea: "defer further device tests (Checklist item 21, OQ7 (log if seen))"
  deferred_at: 2026-11-13
- test: 25
  idea: "defer further device tests (Checklist item 22, D-17 (log if seen))"
  deferred_at: 2026-11-13
