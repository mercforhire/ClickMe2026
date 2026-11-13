---
status: diagnosed
phase: 04-booking-payment-and-discovery
source: [04-VERIFICATION.md]
started: 2026-11-12T19:43:46Z
updated: 2026-11-13T03:49:54.193Z
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
note: "Seen working on device 2026-11-12: precondition query returned true; initial Explore load shows a free no-currency topic labelled Free and a Chinese-script title rendered correctly; airplane mode shows 'The Internet connection appears to be offline.' with Retry per section and no stale Featured Topics. Failing part: pull to refresh on Explore loads nothing (also blocks 'a pull to refresh after airplane mode loads normally')."


### 4. UAT item 2, EXPL-03: free featured topic card reads "Free"; paid card shows CA$12.50 style price
expected: Free card reads Free; paid card shows cents
result: pass

### 5. Remaining UAT items 3 to 22 of 04-DEVICE-UAT-CHECKLIST.md (BOOK-01, BOOK-19, BOOK-04, EXPL-02, EXPL-05, EXPL-06, K1/K3/K4/K5)
expected: Per the checklist's Expected lines
result: skipped
reason: "User stopped the session on 2026-11-12 before items 3 to 22 ran (no device results recorded for them; resume with /gsd-verify-work 04)"

## Summary

total: 5
passed: 2
issues: 1
pending: 0
skipped: 1
blocked: 1

## Gaps

- gap_id: G-04-3
  truth: "Explore loads every time, including on pull to refresh and on a refresh after airplane mode is turned off"
  status: failed
  reason: "User reported: IOS, Pull to refresh on the exports screen is currently broken. Nothing will load."
  severity: blocker
  test: 3
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

## Deferred Follow-Ups

- test: 1
  idea: "defer (D-11 step g: run the 01-17 and 01-19 real-Stripe checklists; BACK-06, BACK-07, BACK-19 stay Pending)"
  deferred_at: 2026-11-12
