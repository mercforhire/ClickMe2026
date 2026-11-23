---
phase: 03-booked-sessions-and-joining
reviewed: 2026-11-22T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryExpertCard.swift
  - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 03: Code Review Report (incremental, gap-closure 03-18)

**Reviewed:** 2026-11-22
**Depth:** standard
**Files Reviewed:** 5

This report replaces the previous full-phase report. That report remains in git history at `b026274`.

## Summary

The scope is the diff since `b026274`. The main change is gap-closure plan 03-18 (G-03-1-ITEM14): the new `BookingSummaryPrice` enum, and the view model, card, view preview and tests wired to it. The diff in these files also includes the decline-status change that came from other quick tasks: `applyResolution` now switches on `Resolution.declined(restoredStatus:)`, and the decline tests cover it. I reviewed that part too, along with the supporting `RescheduleDeclineResponse`.

The 03-18 logic is correct:
- `make(isFree:amount:currency:)` lets `is_free == true` win, and returns `.unknown` when either the amount or the currency is missing.
- Paid amounts go through `Money.format(minorUnits:)`, so cents are kept.
- The view model leaves `price` nil until the first load, and `apply(detail:)` always sets it.
- Test fixtures default to `isFree: true`, and the four price tests exercise the real fixture and API path.

The decline path is also sound. `mapStatus` returns nil for non-terminal statuses, so a restored `confirmed` status leaves the badge nil. A missing `data` leaves the status untouched. The decode of `RescheduleDeclineResponse` is tolerant. This matches the sibling `UpcomingBookingViewModel.applyResolution`.

No security, concurrency or crash defects were found. The findings below are one correctness and wording concern and three minor items.

## Warnings

### WR-01: "PAID" label is shown for bookings that were never charged, and the new `.unknown` case widens it

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift:55-62` (rendered at `Subviews/BookingSummaryExpertCard.swift:116-128`)
**Issue:**
- `label` returns "PAID" for every non-free row, regardless of the booking's outcome or `payment_status`.
- Booking Summary also shows cancelled, declined, missed and expired bookings (`mapStatus` maps all of them to badges). For those, a paid topic's hold is usually released and never captured.
- The pre-change code already printed "PAID · $45.00" there. The new `.unknown` case adds "PAID · —" for any paid topic whose detail lacks a price, on any status, including those never-charged ones.
- The 03-18 plan fixes this wording as a user decision ("paid rows keep PAID · {amount}"), so I am not claiming the plan is wrong.
- The risk is still real for a screen showing money: the row states a payment happened when it may not have. This is one of the project's "charging them wrongly" concerns.
- The detail already carries `payment_status`, as the fixtures show, but the view model never passes it to the price row.

**Fix:** Raise this with the product owner and Android before the release build. If the wording should follow the outcome, thread the payment outcome into `make` and label by it, for example:
```swift
static func make(isFree: Bool, amount: Int?, currency: String?, captured: Bool) -> BookingSummaryPrice
// label: .paid where captured -> "PAID"; otherwise a neutral "Price" (or "Session fee")
```
If the wording stays, record in the UAT notes that "PAID" on cancelled, declined or expired sessions is accepted behavior.

## Info

### IN-01: New localizable strings are not yet in the String Catalog

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift:41,57`
**Issue:**
- `"Free"` and `"Session fee"` appear in neither the committed `Localizable.xcstrings` nor the working-tree copy.
- The working-tree copy has about 290 lines of unrelated uncommitted churn. The plan intentionally leaves catalog sync to Xcode.
- The English source language falls back to the key, so nothing breaks at runtime. The catalog still needs a commit once Xcode extracts the keys (and the comments), before the release build.

**Fix:** Run an IDE build, then commit the catalog change in its own commit. Confirm that `Free` and `Session fee` are present with their comments.

### IN-02: Em-dash value has no accessibility text

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryPrice.swift:44-45`, `Subviews/BookingSummaryExpertCard.swift:122`
**Issue:**
- The `.unknown` value is a bare "\u{2014}", which VoiceOver reads as "em dash" or skips.
- The comment says the dash "is not translated", but the spoken form is not covered.

**Fix:** Add `.accessibilityLabel("Price unavailable")` (localized) to the value `Text` when `price == .unknown`. Alternatively, combine the label and value into one element with `.accessibilityElement(children: .combine)` and give it that text.

### IN-03: Price tests compare against English literals and rely on fixture defaults

**File:** `ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift:~435-490`
**Issue:**
- The tests assert `"Free"`, `"Session fee"` and `"PAID"` literally. The paid-amount test already uses `Money.format` for the value. Once translations are added, these literal asserts would fail on a non-English test locale.
- `freeSessionShowsFree` depends on the `ClientBookingFixtures.detailJSON` default `isFree: true`, so it passes by omission. A future change to that default would silently change what the test covers.

**Fix:** Pass `isFree: true` explicitly in `freeSessionShowsFree`. Optionally compare against `String(localized: "Free")` and `String(localized: "Session fee")`, or force the test locale.

---

_Reviewed: 2026-11-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
