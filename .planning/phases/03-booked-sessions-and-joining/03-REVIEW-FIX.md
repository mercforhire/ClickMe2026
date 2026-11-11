---
phase: 03-booked-sessions-and-joining
fixed_at: 2026-11-11T21:40:00Z
review_path: .planning/phases/03-booked-sessions-and-joining/03-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 7
skipped: 0
already_fixed: 2
status: all_fixed
---

# Phase 3: Code Review Fix Report

**Fixed at:** 2026-11-11
**Source review:** .planning/phases/03-booked-sessions-and-joining/03-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (WR-01 to WR-09; no Critical findings; Info excluded by `fix_scope: critical_warning`)
- Fixed in this run: 7 (WR-03 to WR-09), one commit each
- Already fixed before this run: 2 (WR-01, WR-02), confirmed against current source, no new commit
- Skipped: 0

Two fixes are flagged "requires human verification" (WR-03 and WR-08, see below). One follow-up needs a backend change that was not made (WR-03).

## Already Fixed (verified, no new commit)

### WR-01: After a successful accept, a failed refetch leaves the Accept/Decline card on screen

**Source:** gap-closure plan 03-16.
**Verified in source:** `RescheduleResponder` calls `onResolved` after the success toast and before `refetch` on all three 2xx paths (first accept, saved-card retry accept, decline), and never from a `catch`. Both owners clear `reschedule` in it. The responder, Upcoming and Booking Summary tests covering this pass in the full run below.
**Note:** WR-08 extends this fix, see below.

### WR-02: Post-cancel toast can promise a refund the server did not issue

**Source:** gap-closure plan 03-17.
**Verified in source:** `CancelToastMessage.text` returns the neutral "Any refund due will follow our cancellation policy." for `.chargedRefundable` at a server amount of 0, and names an amount only in the `serverRefundMajor > 0` branch. `CancelToastMessageTests` and `ClientCancellationViewModelTests` cover it and pass.

## Fixed Issues

### WR-03: Refund and hold lines show the list price, not the amount paid

**Files modified:** `ClickMe2026/Utils/CancelRefundPreview.swift`, `ClickMe2026/Utils/CancelToastMessage.swift`, `ClickMe2026/Utils/ExpertCancelRefundLine.swift`, `ClickMe2026Tests/Utils/CancelRefundPreviewTests.swift`, `ClickMe2026Tests/Utils/CancelToastMessageTests.swift`, `ClickMe2026Tests/Utils/ExpertCancelRefundLineTests.swift`
**Commit:** f649900
**Status:** fixed: requires human verification (interim wording fix, not the full fix)
**Applied fix:** The backend refunds `amount_paid_minor_units`, but neither the client booking-detail payload nor the expert detail exposes it (checked `openapi/clickme-api.yaml` and the booking controllers). So the "amount paid" fix the reviewer preferred needs a backend change, which was not made. The reviewer's interim option was applied: the lines now say "up to" the list price.
- Client confirm: "Refund: up to CA$45.00, cancelled more than 24 hours before the start" and "Up to CA$45.00 held on your card will be released, so you won't be charged."
- Post-cancel toast, live-hold case: "Up to CA$45.00 held on your card is being released."
- Expert sheet: "The client will get a full refund of up to CA$45.00" and "The client's hold of up to CA$45.00 will be released."
- The `CA$0.00` within-24-hours line is unchanged (zero is exact). Doc comments on the three helpers record why. Test expectations updated.

**Follow-up (backend, not done here):** expose the amount paid on `GET /client/bookings/:id` and the expert booking detail, then replace the "up to" wording with the real figure. This is additive and safe for the Android build.

### WR-04: Reschedule is offered on every booking status; only Cancel was gated

**Files modified:** `ClickMe2026/Utils/UpcomingActionPolicy.swift`, `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingView.swift`, `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift`, `ClickMe2026Tests/Utils/UpcomingActionPolicyTests.swift`
**Commit:** 5564958
**Applied fix:** Added `UpcomingActionPolicy.canShowReschedule(status:end:now:)` mirroring `canReschedule` in the backend `reschedule.js`: `confirmed`, `pending_approval` and `pending_reschedule` always; `completed` and `in_progress` only while the scheduled end is ahead; everything else (cancelled, declined, missed, expired, rescheduled, unknown) never. `UpcomingBookingSecondaryActions` takes `showsReschedule`, and the whole row is hidden when neither button applies. New test rows cover each status group, the end-time edge, a nil end, and exhaustiveness against the Cancel lists.

### WR-05: Reschedule accept/decline succeeds silently in the expert shell

**Files modified:** `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift`, `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift`, `ClickMe2026/Managers/ToastCenter.swift`, `ClickMe2026/Views/Components/Toast/ToastHost.swift`
**Commit:** c59d7fe
**Applied fix:** Took the reviewer's first option: `ToastHost` is now applied on the expert shell as well, so a dual-role user answering a client reschedule from a chat row sees "Reschedule accepted/declined", and the message no longer lingers into client mode. Comments that said "client mode only" were updated. The `hostsClientBookingFlows` gating of the other client-only actions is unchanged.

### WR-06: `ToastCenterTests` use real sleeps with thin margins

**Files modified:** `ClickMe2026/Managers/ToastCenter.swift`, `ClickMe2026Tests/Utils/ToastCenterTests.swift`
**Commit:** 1b165f8
**Applied fix:** `ToastCenter.init` gained an injectable `sleep` closure (default `Task.sleep`, so production behaviour is unchanged). The tests now drive the dismiss timer through a manually released `ManualSleeper` (cancellation-aware), so the "replacement restarts the timer" and "show after dismiss" rows no longer depend on wall-clock margins. Other `ToastCenter(displayDuration:)` call sites are untouched.

### WR-07: `submitRefusesFarSlot` would call the live backend if its guard regressed

**Files modified:** `ClickMe2026Tests/Booking/ExpertRescheduleWindowTests.swift`
**Commit:** 0e83b92
**Applied fix:** The test now injects `APITestFactory.make { ... }` through the `api:` parameter. The stub counts requests (small lock-based `RequestCounter`, so it does not depend on the shared `MockURLProtocol.recordedRequests`) and throws a transport error. The test asserts `requests.count == 0` as well as the mapped error copy. The file header was updated to say that one row now uses a stub.

### WR-08: After a successful accept or decline with a failed refetch, the screen still shows the old time and a "Pending reschedule" status

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift`, `ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift`, `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift`, `ClickMe2026Tests/Booking/RescheduleResponderTests.swift`, `ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift`, `ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift`
**Commit:** 80f30d0
**Status:** fixed: requires human verification (state logic)
**Applied fix:** `onResolved` now receives a `RescheduleResponder.Resolution` (`.accepted` / `.declined`). Each owner updates itself locally before the refetch:
- Upcoming details, accepted: start, end, date and time range take the proposal's values; status becomes `confirmed`; `canJoin` clears; the proposal clears.
- Upcoming details, declined: status becomes `confirmed`, proposal clears, time unchanged.
- Booking Summary, accepted: `dateTime` and `currentStartTime` take the proposal's values; proposal clears. Declined: proposal clears.

Each owner's refetch now retries once after `refetchRetryDelay` (default 2 s, shortened in tests) when the first detail GET fails; `refresh()` is split into a private `refreshOnce()` that reports whether the GET failed. New and updated tests: both failed-refetch rows now expect two failed GETs after the load, assert the new time and status, and a new test shows the retry's answer (`pending_approval`) replacing the local guess.

**Why it needs a human look:** for a decline, the backend restores `reschedule_prev_status`, which the client payload does not carry. `confirmed` is assumed until the refetch or retry corrects it. If the previous status was `pending_approval` and both fetches fail, the screen shows Confirmed until the next socket event or reopen. The device checklist should include a decline on a booking that was pending approval, offline after the POST.

### WR-09: Post-cancel toast reads the refund case after the await

**Files modified:** `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationViewModel.swift`, `ClickMe2026Tests/Booking/ClientCancellationViewModelTests.swift`
**Commit:** 0a2f636
**Applied fix:** `confirmCancellation` captures `confirmedCase` before any await and passes it to `CancelToastMessage.text`. `recomputeRefundCase()` returns early while `isConfirming`, so the 60 s tick cannot flip the case during the request. New test holds the cancel response with a semaphore, moves the clock across the 24-hour line, ticks, releases the response, and asserts the toast is still the neutral line from the confirmed case.

## Skipped Issues

None.

## Verification

All builds and tests ran in the **isolated worktree** (`.claude/worktrees/rf-03-fixer1`, branch `gsd-reviewfix/03-fixer1`) before it was fast-forwarded into `main`; they were not re-run in the main checkout afterwards. The worktree was given a copy of the git-ignored `ClickMe2026/Debug/PreviewSecrets.swift` so it could compile, and used a throwaway DerivedData directory (removed). The sources in the main checkout are identical to what was built (the fast-forward merged the same commits).

- Per-fix Tier 2: `swiftc -parse` on each edited file, all clean.
- `xcodebuild build-for-testing -project ClickMe.xcodeproj -scheme ClickMe2026 -destination 'platform=iOS Simulator,name=iPhone 17'`: **TEST BUILD SUCCEEDED**. The first attempt failed on one error in the new WR-09 test (a main-actor static read inside a `@Sendable` closure); it was fixed and folded into the WR-09 commit. No new warnings: the warnings in the log are all in files this run did not touch (`UserManager.swift:618`, `NetworkService.swift:168`, `MakeABookingStripePaymentSheet.swift:197`, `ProfileAvatarSection.swift`).
- `xcodebuild test-without-building` on the ten affected suites (ToastCenter, UpcomingActionPolicy, ExpertRescheduleWindow, ClientCancellationViewModel, UpcomingBookingViewModel, BookingSummaryViewModel, RescheduleResponder, CancelRefundPreview, CancelToastMessage, ExpertCancelRefundLine): 134 tests in 10 suites passed.
- `-only-testing:ClickMe2026Tests` (whole unit target): 463 tests in 51 suites passed.
- Not run: UI tests, and any on-device check. The UI behaviour changes (Reschedule hidden on terminal statuses, toast host in the expert shell, "up to" copy, WR-08 in-place state) still need the device UAT.

## Not changed

- No backend or Android repo was edited. Android mirrors iOS behaviour per the root CLAUDE.md, so WR-04 (Reschedule gate), WR-08 (local state after accept/decline) and WR-09 (toast case capture) likely need matching Android changes, and the WR-03 wording should be matched there once decided.
- Info findings IN-01 to IN-06 are out of scope for `critical_warning` and remain open in `03-REVIEW-DISPOSITION.md`. The dispositions for WR-03 to WR-09 still read `open` there; the orchestrator should update them.

---

_Fixed: 2026-11-11_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
