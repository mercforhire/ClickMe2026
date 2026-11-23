# Phase 8 Release Record

What shipped, what ran on a device, and what did not. This record is written before the release build exists, so nothing is decided at the device. Sections marked "filled by" are completed by the named plan. Nothing in this file records an item as tested that was not tested: an item that was not run is listed as not run (D-01), or as removed and untested (D-02).

## Build

| Field | Value |
|-------|-------|
| Version and build | 1.1 (7): `MARKETING_VERSION = 1.1`, `CURRENT_PROJECT_VERSION = 7` for the app target (D-18). App Store build 6 (1.0) is the shipped baseline. |
| Release path | `ci` (plan 08-04, user-reported green dry run of the "Deploy to TestFlight" workflow on `main` at `4bd63e7`, 2026-11-22). A pushed `release/1.1` branch builds, signs and uploads to TestFlight (D-19, D-25). |
| Environment | `Environments.plist` stays on `Production` (P9, by design). |
| Candidate SHA | `1fdcc26` (`1fdcc26edd754d5f156bb8369c41fb2e5f0281f5`), `chore(release): 1.1 (7)`, on top of `73b9800` `chore(08-20): refresh the string catalog`. Annotated tag `v1.1` (tag object `e5a92134f134e68799a94a54c3efd52ff1e4d738`, "ClickMe iOS 1.1 (7)") peels to `1fdcc26`; `release/1.1` tip on GitHub is `1fdcc26`; `main` on GitHub was `1fdcc26` at the cut (fast-forward from `4bd63e7`). Built commit, tag and branch tip are the same SHA (`git ls-remote origin`, 2026-11-23). Cut after the backend freeze: /health was `1d18aac`, equal to the frozen SHA. User go (plan 08-20 Task 2, 2026-11-23, verbatim): "go". |
| Candidate checks | Full unit run on `1fdcc26`: "Test run with 1296 tests in 119 suites passed" (first run, no flake rerun). `scripts/release-build-check.sh` on `1fdcc26`: RELEASE CHECK PASSED, NEW WARNINGS: 0. D-25/D-26 history scans over `origin/main..HEAD` (61 commits, re-run immediately before the first push): no JWT-shaped string and no secret key; the working-tree `eyJhbGciOi` list outside `.planning` is exactly the two fake-JWT fixtures. |
| TestFlight build number | 1.1 (7), uploaded by the "Deploy to TestFlight" workflow (`.github/workflows/build.yml`) triggered by the `release/1.1` push (2026-11-23, shortly before 14:35Z). Run ID not read at the cut: `gh` is not installed on this machine and the repo's Actions API is private. Runs: https://github.com/mercforhire/ClickMe2026/actions/workflows/build.yml?query=branch%3Arelease%2F1.1 . 08-22 starts after TestFlight shows 1.1 (7). |
| Testers | internal TestFlight testers only (D-20) |
| Regression checklist | `08-REGRESSION-CHECKLIST.md`, items R1 to R11 |

## Backend deploys

Production is an iOS-only line cherry-picked onto `origin/main` and pushed as fast-forwards (D-10). Each deploy had a gate, the user's approval of that one deploy (D-14) and a rollback branch recorded before the push (D-16). Rollback is a Railway redeploy of the rollback SHA, never a force-push.

| Wave | Commits | Pushed SHA | /health before | /health after | Rollback branch (SHA) | Smoke result |
|------|---------|------------|----------------|---------------|-----------------------|--------------|
| X1 | `5da3976` chat reasons in the chat event; `162f1d7` reschedule declines notify the proposer; `0767cf4` hand-written messages for empty profile names; `412f1aa` null, not an empty string, for a topic with no currency | `412f1aa649f5aa72fb853e40e87ab5e0998eb926` (pushed 2026-11-20T17:29:02Z) | `28da165` | `412f1aa` (live 2026-11-20T17:30:24Z) | `ios-p8-x1-rollback` (`28da165ebe66a973008560f689c469389279c25f`) | Plan 08-11, user-reported: log in, My Bookings, chat, reschedule proposal and decline, chat event rows, empty first name, expert Topics tab: all six lines PASS on App Store build 6 and the current Android build; no rollback |
| X2 | `1d18aac` retry transient T-24h errors before the PaymentIntent, up to 6 h before the session (D-29) | `1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594` (pushed 2026-11-22T22:22:09Z, from `08-16-SUMMARY.md`) | `412f1aa` | `1d18aac` (live 2026-11-22T22:23:02Z) | `ios-p8-x2-rollback` (`412f1aa649f5aa72fb853e40e87ab5e0998eb926`) | Plan 08-18, user-reported 2026-11-22 ("x2 check pass"): step 1 app smoke PASS on App Store build 6 and the current Android build; step 2 sweep log PASS (no errors); step 3 stuck-rows query not run (optional; the 08-16 value was 0). No rollback. See the note below the table. |
| Freeze | `1d18aac` (X2 is the last backend commit of this release) | `1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594` | `1d18aac` | `1d18aac` (/health re-read 2026-11-23T00:30Z, equal to the frozen SHA) | `ios-p8-x2-rollback` (`412f1aa649f5aa72fb853e40e87ab5e0998eb926`) | Frozen after the X2 smoke passed |

Backend frozen at 1d18aac (1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594) on 2026-11-22; no backend push until the regression is signed off, except a D-09 fix (D-12).

Found during the X2 smoke, not an X2 failure: the client Session Summary "Message Expert" button does nothing. It is a pre-existing iOS-only bug, present in App Store build 6 since before this release, not caused by deploy X2, and needs no backend change. It is being fixed as quick task 261122-r2o in the 1.1 (7) build, so it is not a reason to break the freeze.

Backend `master` is not deployed by this phase (D-10). It takes the D-12 merge in plan 08-21 (D-17).

## Warnings

Measured by `scripts/release-build-check.sh` (plan 08-01): a clean-checkout Release build of build 6's commit `a48c664` against the candidate, with the identical command, comparing normalized warning lines.

| | Count |
|-|-------|
| Baseline (build 6, `a48c664`) | 4 |
| Candidate at plan 08-01 | 4 |
| New warnings | 0 |
| Candidate at release (final diff) | `1fdcc26` (plan 08-20, 2026-11-23): BASELINE WARNINGS: 4, CANDIDATE WARNINGS: 4, NEW WARNINGS: 0, RELEASE CHECK PASSED |

## Not run on device (D-01)

These items were not run on a device before submission. Their evidence is the unit tests plus the TestFlight regression run of the core paths (D-01, user-approved amendment 2026-11-19). This can be reversed: any of them can still be run later. One line each, by number.

### Phase 3 device checklist, items 7 to 24

- Phase 3 checklist item 7 (BOOK-13, Cancel and Reschedule visibility by status and time): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 8 (BOOK-16, reschedule returns one level with a toast): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 9 (BOOK-17, Leave a Review on completed sessions only): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 10 (BOOK-20 iOS, booking ID line): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 11 (CALL-03, functional steps only: JOIN CALL from every Upcoming details entry, the early and pending-reschedule button states, and the failed-join alert): not run on device; covered by unit tests plus regression (VoiceOver step excluded, see D-02)
- Phase 3 checklist item 12 (CALL-06, Skype/Zoom status line promises no automatic end): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 13 (CALL-07, Skype/Zoom session timer matches the in-app layout): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 14 (BOOK-20 Android, booking ID line on Android): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 15 (CALL-08 / D3, Open in {provider} reaches the Skype screen and End Session completes the booking): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 16 (EXP-11, expert cancel sheet states the client's money outcome): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 17 (D-15 / K2, end + 55 notice on the Skype/Zoom layout): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 18 (EXP-13, expert reschedule wiring and the 6-day paid cap): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 19 (CALL-10 / D4, expert Join Session from Booking Summary across two accounts): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 20 (BACK-02 iOS, decline note on the client's Booking Summary): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 21 (D2, functional steps only: toast placement about 24 pt above the tab bar, dismissal by tap and after about 4 seconds, wrapping, not covering the buttons or the keyboard, and the Reduce Motion fade): not run on device; covered by unit tests plus regression (VoiceOver step excluded, see D-02)
- Phase 3 checklist item 22 (L2, Dynamic Type at the largest accessibility size; large text is not part of the D-02 drop): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 23 (L3, "Open in Microsoft Teams" on the smallest iPhone): not run on device; covered by unit tests plus regression
- Phase 3 checklist item 24 (expert shell chat-row item, no client actions and no blank screen): not run on device; covered by unit tests plus regression

### Phase 4 UAT, 20 skipped tests (04-UAT.md tests 6 to 25)

- Phase 4 UAT test 6 (checklist item 3, BOOK-01 / BOOK-19 / D2, Request Sent has no Back and no swipe, and both exits reset the source tab): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 7 (checklist item 4, BOOK-05 / L1 / E1, "Loading booking…" and the Request Sent load error keep both exits): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 8 (checklist item 5, BOOK-02 / T2 / T3, month changes never show another month's slots): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 9 (checklist item 6, BOOK-03 / D-18, the device time zone is named in words): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 10 (checklist item 7, BOOK-04 / T1 / T4, slot times follow the 12/24-hour setting): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 11 (checklist item 8, PAY-03 / D3, the hold card shows on a paid Request Sent and is absent on a free one): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 12 (checklist item 9, EXPL-01 / L3 / E3, expert profile load errors): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 13 (checklist item 10, EXPL-02, empty Expertise, Topics and Reviews sections are hidden): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 14 (checklist item 11, EXPL-04 / LT1, search tag pills show their whole text): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 15 (checklist item 12, EXPL-05 / D-07 / D-08 / D-09, Favorites paging, refresh, empty buttons, Pro Tip and the heart): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 16 (checklist item 13, EXPL-06, the full reviews list pages past 20): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 17 (checklist item 14, D-13 / D4, a suspended account lands on Login with the suspension alert on a cold launch): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 18 (checklist item 15, L5, new state views read correctly at the largest Dynamic Type): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 19 (checklist item 16, K1 judgment, Request Sent's status pill always reads Awaiting Approval): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 20 (checklist item 17, K3 judgment, Request Sent uses the same short time style as the slot chips): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 21 (checklist item 18, K4 judgment, the slot is cleared after "You may already have this booking"): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 22 (checklist item 19, K5 judgment, the seeded profile can flash before a "profile isn't available" screen): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 23 (checklist item 20, D-14, Android push prompt after a reinstall; also item A11 in the regression checklist's Android section, which does not gate the submission): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 24 (checklist item 21, OQ7, log if seen: favorites staleness after unfavoriting on a profile): not run on device; covered by unit tests plus regression
- Phase 4 UAT test 25 (checklist item 22, D-17, log if seen: "payment still processing" on confirm): not run on device; covered by unit tests plus regression

### Phase 4 UAT test 2, covered by unit tests only (user decision 2026-11-19)

- Phase 4 UAT test 2 (WR-01, 3DS/SCA challenge on a saved card that requires SCA): not run on device; covered by unit tests only. Reason: no live-mode card reliably triggers SCA, and no step in 08-REGRESSION-CHECKLIST.md adds a real-money SCA charge (user decision 2026-11-19). Tests: MakeABookingPaidFlowTests (ClickMe2026Tests/Booking/MakeABookingPaidFlowTests.swift) "The 3DS retry sends the topic and slot the payment was made for" and "A 3DS retry with no card left ends the attempt and sends no second confirm" (the CR-03 resend of the platform card, iOS f3bdb3f), and "Every way out of a paid attempt unlocks the form" (closing the 3DS sheet unlocks the form).

## Removed and untested (D-02)

The accessibility steps below were dropped from the device checklists at the user's request (D-02). Each is removed and untested on device. None of them is a result of any kind.

- Phase 3 item 4: BOOK-09 status pill and ID row read as one VoiceOver element: removed, untested on device. The whole item was skipped on 2026-11-19, so its non-VoiceOver steps (the real status shown on the pill, the largest-size look) were not run on device either. Phase 3 item 4 is outside the D-01 list above, so plan 08-19 and plan 08-24 must classify those non-VoiceOver steps.
- Phase 3 item 11: JOIN CALL hint read by VoiceOver: removed, untested on device
- Phase 3 item 21: toast read by VoiceOver: removed, untested on device
- UI-SPEC L2 backstops: the VoiceOver readings (Phase 3 item 4's one-element read): removed, untested on device. The largest-size Dynamic Type parts are not part of this drop and stay under D-01 (Phase 3 item 22, Phase 4 UAT test 18).
- Phase 4 checklist item 3: the optional VoiceOver bullet (no Back control, the two exits read as normal buttons): removed, untested on device
- Phase 7 checklist item 12: VoiceOver on the failed bubble, the counter, the banner, the profile Block overlay and a Chats row with an unread count: removed, untested on device (ROADMAP backlog 999.5)
- Phase 7 checklist item 3: VoiceOver reading of the counter at the cap: removed, untested on device (backlog 999.5)
- Phase 7 checklist item 4: VoiceOver repeat of the profile Block with a second test client: removed, untested on device (backlog 999.5)
- Phase 7 checklist item 8: the VoiceOver clause that the banner title is announced once: removed, untested on device. The UAT file names only items 3, 4 and 12 as skipped, so this one is listed to be safe.
- Phase 7 IN-04 check that a delivered bubble is not read as pending: removed, untested on device (backlog 999.5)
- Phase 6 items 11 and 20: the VoiceOver sentences in their expected text (no room left in a day, the character counter): removed, untested on device. Their Results were recorded on 2026-11-16 with no note on whether those sentences were run, so they are recorded here as untested.

## Closed on non-device evidence

- **BACK-15** (D-08): closed on its mock and unit-test evidence. A phone cannot force a same-`booking_attempt_id` retry, so no device check can prove the confirm replay. PAY-02's iOS handling is covered by the regression run only if a timeout happens to occur (R1 records what the app did if one does).
- **BACK-19, captured-refund branch** (D-27): the held-booking release is checked on a real PaymentIntent in the regression run (R6). The captured-refund branch is not exercised on a device, because a device cannot force a captured refund. It stays covered by the mocked captured-refund tests. BACK-19 closes on the hold-release evidence plus those mocked tests.
- **R1 overtime steps and R2** (D-33, user decision 2026-11-23, verbatim: "Run short ones, waive overtime (Recommended)"): on build 1.1 (7), R1's end + 10, end + 55 notice, end + 60 auto-end and the Android teardown at the auto-end, and the whole of R2 (free in-app voice session), are waived, not run on device. Evidence in their place: `ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift` plus code review, the Phase 2 device run (`02-UAT.md`: call still connected at end + 11), R1's PASS of the paid in-app path, and the overtime moving to 15 minutes in 1.2 (todo `2026-11-23-shorten-call-overtime-to-15-minutes`). R3's short run, without the end + 55 banner, is accepted under the same decision.

## Deferred with reason

### Requirements

- **BACK-08** (D-07): deferred past this release, like BACK-13. Its gate returns 403 on `GET /expert/tax-profile` for client-only accounts, and it ships with BACK-13 once App Store build 6 and the current Android build no longer rely on implicit promotion. The code stays parked on backend branch `wave-3c`.
- **BACK-13** (D-07, Phase 5 D-04): deferred past this release. App Store build 6 and the current Android build rely on `ensureExpert`'s implicit client-to-expert promotion, so the explicit-promotion change would leave those clients unable to become experts. The iOS Expert-mode gate (SIGN-06) fixes the user-facing bug. The code stays parked on `wave-3c`.

### Open review infos

The disposition files list these as `open`. They are info findings, which D-03 allows to be deferred with a written reason.

| Finding | Reason it is deferred |
|---------|-----------------------|
| Phase 3 IN-01 `bannerFinalStretch` test cannot distinguish the branch | Test strength only. The banner code is correct and the Phase 3 behavior is covered by other rows. No user impact. |
| Phase 3 IN-02 `HomeNavigationPathTests` do not cover the route wiring behind `pop(2)` | Test coverage gap. Every current caller pushes a `HomeRoute`, where `pop(2)` is correct. Not reachable today. |
| Phase 3 IN-03 duplicate error-message helper | Maintainability only. The helper gives the same message as `Error.userMessage`. No user impact. |
| Phase 3 IN-04 Booking Summary shows the response card without a status check | Not reachable today: the backend returns the reschedule block only for `pending_reschedule`. Becomes a risk only if the payload changes. |
| Phase 3 IN-05 `startCall()` returns silently when join inputs are missing | Not reachable today: the join window already requires start and end, and the expert id is set in the same step. Core flow is covered by R1 to R3. |
| Phase 3 IN-06 `.chargedNotRefundable` at server 0 still says "No refund applies" | Edge case only: a phone clock running ahead near the 24-hour edge. The server amount is what the user is charged or refunded. Wording only, no money effect. |
| Phase 6 IN-08 other `TopicEditorViewModel` tests rely on the shared `UserManager` | Test isolation only. The tests pass today and have no user impact. |

`G-03-1-ITEM1` (the proposal push wording) shipped in backend deploy X1 (`162f1d7`), so it is not deferred.

### Other open review findings, not named in the plan

The disposition files for Phase 2 and Phase 5 also hold findings marked `open` with no reason recorded. They are listed so they are not lost. No reason is invented here: the user decides in plan 08-24 whether each is fixed, deferred with a reason, or accepted.

- Phase 2: WR-03 (typed topic price always multiplied by 100), WR-04 (`PI_CURRENCY_MISMATCH` not handled in the paid-booking error path), IN-01 (dead helper and stale wording), IN-03 (currency symbol in the price label and the hint)
- Phase 5: WR-01, WR-02, WR-03, IN-01, IN-02, IN-03, PRIOR-WR-03, PRIOR-WR-04, PRIOR-WR-05, PRIOR-WR-06, PRIOR-IN-04

## Backlog dispositions

- **999.1** (Phase 01 deferred UAT, test 1: the real-Stripe checklists 01-17 and 01-19): folded into the regression run (R4, R5, R6) per D-06 and D-27. The failed-refund retry and the captured refund are not exercised on a device (D-27).
- **999.2** (Phase 01 deferred UAT, test 4: BACK-15 with a real hold): closed by D-08. A phone cannot force a same-`booking_attempt_id` retry; BACK-15 closes on its mock and unit-test evidence.
- **999.3** (Phase 06 deferred UAT, test 6: a reasonable maximum topic price): stays in the backlog. It is a new limit across iOS, Android and the backend, outside this release.
- **999.4** (Phase 06 deferred UAT, test 9: the two iOS 26 Liquid Glass readability checks): folded into the regression run per D-28 (R9).
- **999.5** (Phase 07 deferred UAT, test 4: the VoiceOver check): removed per D-02. It is listed above under "Removed and untested (D-02)".

## Regression results

Copied by plan 08-22 Task 3 from the one `Result:` line of each item in `08-REGRESSION-CHECKLIST.md`, word for word, in checklist order (R1 to R11, then the Android section). The Result lines were written by the orchestrator from the user's chat replies during the run (commits `e67896e` to `98d9d87`); the leading `WAIVED (D-33)` token on R1 and R2 was added on 2026-11-23 under D-33 with the rest of each line unchanged. An empty Result means the item was not run.

- **TestFlight build installed:** 1.1 (7), from internal testing (the user reported no other build number).
- **Backend during the run:** frozen at `1d18aac`; the 08-22 pre-flight read /health = `1d18aac` and tag `v1.1` = `1fdcc26` (2026-11-23). No backend push during the run.
- **Run date:** 2026-11-23, iPhone client A against Android expert B (R9 with roles swapped).

### Gating items (R1 to R11)

- **R1** (S1: paid in-app voice session, book, pay, join, run past the end, finish (D-04, D-08, D-28, PAY-02, CALL-01)): WAIVED (D-33); SKIPPED in part (2026-11-23): booking, pay (no confirm alert), hold, accept, JOIN CALL, two-way audio and the single capture PASS (pi ...QJ0AJ8 Succeeded CA$5.00 = topic price, no refund, no second payment; Q1 completed/captured after the end + 15 sweep; Past shows completed); end + 10, end + 55 notice, end + 60 auto-end and the auto-end Android teardown NOT RUN: user ended the call at end + 2 (Android hung up when the call was ended by hand). Topic price had no cents (CA$5.00). Open for the 08-24 ruling: rerun on build 7 or accept CallOvertimePolicy unit tests (cutoff moves to 15 min in 1.2 by user decision 2026-11-23)
- **R2** (S2: free in-app voice session, book, join, run past the end, finish (D-04, CALL-01)): WAIVED (D-33); SKIPPED (2026-11-23): user chose to skip R2 ("skip"); the free in-app voice path and the end + 55 / end + 60 overtime were not run on build 7. Open for the 08-24 ruling together with R1's overtime steps
- **R3** (S3: one Skype/Zoom session on a free topic, book, join, run past the end, finish (D-04, CALL-06, CALL-07, CALL-08)): PASS (2026-11-23), short run by user decision (run the short items, waive overtime): free Skype/Zoom booking, accept, provider label, Open in {provider} opens the meeting link, elapsed/remaining time, no auto-end promise, End Session closes the screen and Join is gone; end + 55 banner not waited for (waived with the overtime steps). Earlier the same day: SKIPPED ("skip"), then run; end + 55 banner waived (D-33)
- **R4** (BACK-06: one saved card becomes the default (D-06, BACK-06)): PASS (2026-11-23)
- **R5** (BACK-07: a removed card's clone is detached and cannot be charged (D-06, BACK-07)): PASS (2026-11-23); Q2 returned the S1 clone row before removal, card removed, clone gone from the connected customer, count 0 afterwards; no hold or charge
- **R6** (BACK-19 hold release: B cancels a held booking and the PaymentIntent is released (D-06, D-27, BACK-19, BACK-07)): PASS (2026-11-23); pi ...VoLGAu Canceled on the connected account, nothing captured or refunded; in-use card removal blocked; cancel push arrived; captured-refund branch not exercised (D-27)
- **R7** (Chat reasons, the reschedule-request push and the reschedule-decline push (D-31, G-03-1-ITEM1, G-03-1-ITEM1B, G-03-1-ITEM1C)): PASS (2026-11-23), steps 1-7 as reported by the user ("pass"); covers the blocked Phase 3 item 1 re-test (G-03-1-ITEM1, 1B, 1C) and Message Expert (quick 261122-r2o); Android half on the dev build
- **R8** (US$ and CA$ prices, and the saved-cards line on Delete Account (D-24, D-23)): PASS on iOS (2026-11-23): US$ and CA$ prices, Delete Account cards line; Android dev build FAIL on step 2: the same page shows US$ but the CAD price has no CA$ prefix (Android Money.pinnedSymbol path, todo 2026-11-23-android-cad-price-missing-ca-prefix); Android Delete Account (step 4) PASS. The Android fault is not in the iOS build; 08-24 to confirm it does not gate the iOS submission
- **R9** (Liquid Glass readability on iOS 26: Availability Save and the Booking Confirmed chevron and title (D-28, EXP-05, EXP-09)): PASS (2026-11-23) on iOS 26: Availability Save and back chevron, Booking Confirmed chevron and title readable with Reduce Transparency on and with Liquid Glass Tinted. Earlier the same day: SKIPPED ("R9 skipped"), then run
- **R10** (Resuming signup keeps the verified email ticked, and the flash on resume (D-28, SIGN-02, U4)): PASS (2026-11-23); Verify email ticked and counted in the ring after force-quit and relaunch; slow-network pass SKIPPED (not run); U4 flash decision: KEEP
- **R11** (End state: every hold released, one capture, nothing else charged (D-11, D-06, D-27)): PASS (2026-11-23); requires_capture count 0; refund_failed/requires_capture query returned no rows; Stripe: R6 ...VoLGAu Canceled, S1 ...QJ0AJ8 one Succeeded capture CA$5.00, nothing else; no other card charge; side bookings cancelled

### Android local-build checks (not gating the iOS submission)

- **A1**: Result empty: not run in this regression (does not gate the iOS submission)
- **A2**: Result empty: not run in this regression (does not gate the iOS submission)
- **A3**: Result empty: not run in this regression (does not gate the iOS submission)
- **A4**: Result empty: not run in this regression (does not gate the iOS submission)
- **A5**: Result empty: not run in this regression (does not gate the iOS submission)
- **A6**: Result empty: not run in this regression (does not gate the iOS submission)
- **A7**: Result empty: not run in this regression (does not gate the iOS submission)
- **A8**: Result empty: not run in this regression (does not gate the iOS submission)
- **A9**: Result empty: not run in this regression (does not gate the iOS submission)
- **A10**: Result empty: not run in this regression (does not gate the iOS submission)
- **A11**: Result empty: not run in this regression (does not gate the iOS submission)
- **A12**: Result empty: not run in this regression (does not gate the iOS submission)
- **A13**: Result empty: not run in this regression (does not gate the iOS submission)
- **A14**: Result empty: not run in this regression (does not gate the iOS submission)
- **A15**: Result empty: not run in this regression (does not gate the iOS submission)
- **A16**: Result empty: not run in this regression (does not gate the iOS submission)
- **A17**: Result empty: not run in this regression (does not gate the iOS submission)

The Android fault seen in R8 step 2 (CAD price without the `CA$` prefix on the Android dev build) is recorded in R8's Result and as todo `2026-11-23-android-cad-price-missing-ca-prefix`; plan 08-24 rules on whether it gates the iOS submission. R10's U4 flash decision is KEEP.

Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)

## Submission

**Status:** Submitted for App Review, Waiting for Review.

- **Submitted:** 2026-11-23 18:41 EST (2026-11-23T23:41Z), version 1.1 with build 1.1 (7), by the user in App Store Connect (plan 08-23 Task 3, D-20, D-21). User report, verbatim: "submitted 2026-11-23 18:41, status Waiting for Reviw" ("Reviw" is the user's typo; the App Store Connect status is "Waiting for Review").
- **App Store Connect status at submission:** Waiting for Review.
- **Release setting:** the plan's steps were "Automatically release this version" with Phased Release off (D-21) and no external TestFlight group or Beta App Review (D-20). The user's report covers the submission time and status only.
- **Approval (Task 2, D-22):** the user approved the What's New text and the review notes unedited on 2026-11-23, verbatim: "approve". The approved text is the text under `### What's New` as drafted in `8a7e060`.
- **Gate:** passed at 2026-11-23T23:35Z, before the submission (below).

**Pre-submission gate** (plan 08-23 Task 1, 2026-11-23T23:35Z): PASS.

- Regression sign-off line present: "Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)".
- Production /health commit = `1d18aac`, equal to the frozen SHA (`1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594`); no backend change since the regression (D-12).
- iOS-line branch tips are ancestors of production: `ios-p8-x1` (`412f1aa`) and `ios-p8-x2` (`1d18aac`), read in the backend D12 worktree.
- `ClickMe2026/PrivacyInfo.xcprivacy` is unchanged between `a48c664` (build 6) and `v1.1` (`1fdcc26`), and `ITSAppUsesNonExemptEncryption` is `false`, so the App Privacy answers and export compliance stay as for 1.0.

### What's New

This update makes booking, paying for and joining a session smoother and more reliable. Here's what's new:

- Calls no longer cut off at the scheduled end time. If you're still talking, your call keeps going for up to an hour past the end.
- Join your session from your booking details, whether it's an in-app call or a Skype or Zoom meeting, any time from an hour before it starts until it's due to end. Experts can join from the booking summary too.
- Skype and Zoom sessions now show how long you've been talking and how much time is left.
- When your expert suggests a new time, you can accept or decline it right from your booking. You'll also get a clear notification when a new time is suggested, or when the time you suggested is declined.
- Before you cancel, you'll see the refund you'll actually get. If your expert cancels, you always get a full refund, or the hold on your card is released.
- Prices now show cents and a clear CA$ or US$ sign, so you always know what you'll pay.
- Messages show while they're sending, tell you if one didn't go through, and let you try again. Your chats list shows how many messages you haven't read.
- When a booking is cancelled, declined or moved to a new time, the reason the other person gave now appears in your chat.
- Booking is clearer: the calendar only shows times for the month you're viewing, times follow your phone's 12- or 24-hour setting with a readable time zone, and a request can't be sent twice by accident.
- Your booking now says whether your card was held or charged, and closing the payment screen without paying never places a hold.
- Expert profiles and Explore load more reliably, free topics are labelled Free, and Favorites and reviews now show the full list.
- Signing up is smoother: a verified email stays verified when you come back to finish, and your profile photo is saved just as you cropped it.
- Tapping a notification now opens the right screen, and after you log out you stop getting that account's notifications.
- Delete Account explains clearly what is deleted and what is kept, including that saved cards are not removed.
- For experts: set topic prices with cents in CAD or USD, reschedule from your upcoming bookings, and see the client's refund before you cancel.

### Release note sources

- Calls no longer cut off: CALL-01
- Join your session from your booking details: CALL-02, CALL-03, CALL-08, CALL-10
- Skype and Zoom sessions now show: CALL-07
- When your expert suggests a new time: BOOK-06, G-03-1-ITEM1, D-31
- Before you cancel: BOOK-08, BACK-19
- Prices now show cents: BOOK-10, D-24
- Messages show while they're sending: CHAT-01, CHAT-07, BACK-18
- When a booking is cancelled, declined or moved: G-03-1-ITEM1B, BOOK-07, BACK-14
- Booking is clearer: BOOK-01, BOOK-02, BOOK-03, BOOK-04
- Your booking now says whether your card was held: PAY-01, PAY-03
- Expert profiles and Explore load more reliably: EXPL-01, EXPL-03, EXPL-05, EXPL-06, EXPL-07
- Signing up is smoother: SIGN-02, SIGN-05
- Tapping a notification now opens the right screen: PUSH-01, PUSH-02, PUSH-04
- Delete Account explains clearly: SET-06, D-23
- For experts: EXP-02, EXP-17, EXP-13, EXP-11

These lines stay in this record and are not pasted into App Store Connect. Every requirement cited is ticked `- [x]` in REQUIREMENTS.md; G-03-1-ITEM1 (reschedule-request push wording, backend X1 `162f1d7`), G-03-1-ITEM1B (reasons in chat, backend `94d659b` plus iOS 08-07) and D-23, D-24, D-31 are shipped fixes recorded in the 08 SUMMARYs. No bullet rests on BACK-08, BACK-13, an open requirement, or the 1.2 todos (15-minute overtime, Stripe payout guide). The read-state label is not claimed: CHAT-08 closed as not reproducible with no fix made.

### App Review notes

Plan: reuse the App Review Information that passed for 1.0 in App Store Connect (App Store Connect carries it into the new version), with one change.

- Keep: contact name, phone and email; Sign-in required = Yes; the client and expert demo accounts; what ClickMe is (a marketplace for live sessions with human experts); why there is no In-App Purchase (real-world services, Guideline 3.1.5(a)); where account deletion is (Settings, Delete Account).
- Remove: any Stripe test-card instruction (for example `4242 4242 4242 4242`). The app runs live Stripe, so a test card is declined and any real card is charged. `APP_STORE_REVIEW_CHECKLIST.md` section 3 still lists the test card (last updated 2026-10-17); it is stale and is not reused.
- Check before submitting (checklist section 3): both demo accounts still sign in from a fresh install, and they still show seeded bookings and chat threads.
- No attachment.

### App Store Connect steps (Task 3, after approval)

1. App Store Connect, ClickMe, + Version, 1.1.
2. Build: select 1.1 (7), the internally tested build.
3. What's New in This Version: paste the approved text under `### What's New` only, not the Release note sources.
4. App Review Information: reuse the 1.0 notes, remove any Stripe test-card instruction, confirm the demo accounts.
5. App Privacy and export compliance: unchanged from 1.0 (no new data collected; `ITSAppUsesNonExemptEncryption = false`).
6. Version Release: "Automatically release this version"; Phased Release off (D-21).
7. Add for Review, then Submit. Do not add an external TestFlight group or use Beta App Review (D-20).
8. Report the submission time and the status App Store Connect shows (for example "Waiting for Review").

## Closeout

Written by plan 08-24 on 2026-11-23, after the submission. Every tick below names the evidence it rests on. Nothing here records a not-run or removed item as passed.

### Requirement ticks in Phase 8

- **BACK-06** (lone saved card becomes the default): ticked by plan 08-22 on R4 PASS (2026-11-23) (D-06).
- **BACK-07** (a deleted card's connected-account clone can no longer be charged): ticked by plan 08-22 on R5 PASS (2026-11-23); the in-use removal block was checked inside R6 (D-06).
- **BACK-19** (expert cancel always refunds in full or releases the hold): ticked by plan 08-22 on R6 PASS (2026-11-23, hold released on a real PaymentIntent `...VoLGAu`); the captured-refund branch closes on the mocked captured-refund tests, not on a device (D-27).
- **BACK-15** (same `booking_attempt_id` replays the original result): ticked by plan 08-15 on mock and unit-test evidence (D-08); a phone cannot force the retry.
- **The 17 Phase 4 rows**, ticked by plan 08-22 under D-01 on their 04-VERIFICATION.md evidence plus the signed-off regression, each with a dated "Closed in Phase 8 under D-01, 2026-11-23" note in REQUIREMENTS.md and "08-19-SUMMARY: no code finding":
  - BOOK-01 (truths 3 and 4, swipe lock not run on device), BOOK-02 (MakeABookingAvailabilityTests), BOOK-03 and BOOK-04 (SlotTimeFormatTests), BOOK-05 (PaymentLifecycleVariantTests), BOOK-19 (HomeShellExitTests)
  - PAY-01 (04-UAT test 1 pass, D-11 step a, 2026-11-12), PAY-02 (MakeABookingPaidFlowTests; 04-UAT test 1 pass, D-11 step d; the 3DS retry, 04-UAT test 2, on unit tests only by user decision 2026-11-19), PAY-03 (PaymentLifecycleVariantTests), PAY-04 (grep for `TODO(backend)` returns 0)
  - EXPL-01 (404 mapping, WR-09 fix `aed0c22`), EXPL-02 (ExpertProfileSectionsTests), EXPL-03 (04-UAT test 4 pass, 2026-11-12), EXPL-04 (TopicsSetupFlowLayoutTests), EXPL-05 (FavoritesViewModelPagingTests, WR-11 fix `753da57`), EXPL-06 (ExpertReviewsViewModelPagingTests), EXPL-07 (ClientHomeFeedTests; 04-UAT test 5 pass, the G-04-3 pull-to-refresh re-test on device, 2026-11-13)
- **REL-01** (as amended by D-01): ticked by plan 08-24 on the regression sign-off line above ("Regression signed off 2026-11-23; gating items R1-R11 PASS (R1 overtime steps and R2 waived, D-33)").
- **REL-02**: ticked by plan 08-24 on the submission above (1.1 (7), submitted 2026-11-23 18:41 EST, Waiting for Review), with backend X1 and X2 live before the cut and production frozen at `1d18aac`.

### Phase 4 rows deferred under D-03

None. All 17 Phase 4 rows were ticked by plan 08-22; no row was deferred, so no D-03 reason is needed.

### Rulings recorded at closeout

- **R1 overtime steps and R2** (D-33, user, 2026-11-23): waived for 1.1 (7), not run on device. Evidence in their place: `ClickMe2026Tests/Utils/CallOvertimePolicyTests.swift`, R1's PASS of the paid in-app path and the Phase 2 device run. The overtime moves to 15 minutes in 1.2 (todo `2026-11-23-shorten-call-overtime-to-15-minutes`). This answers the "open for the 08-24 ruling" note in the R1 and R2 Result lines.
- **R8 Android CA$ fault**: Android-only (the Android `Money.pinnedSymbol` path on the dev build); iOS showed US$ and CA$ correctly and the fault is not in the iOS build, so it does not gate the iOS submission. It stays open as an Android follow-up, todo `2026-11-23-android-cad-price-missing-ca-prefix`.
- **R10 U4 flash on resume**: user decision KEEP (2026-11-23). R10's slow-network pass was skipped and is not run; it is not recorded as passed.

### Still open, and why

- **BACK-08 and BACK-13**: deferred past this release (D-07, Phase 5 D-04); reasons under "Deferred with reason" above. Code parked on backend branch `wave-3c`.
- **Open review infos** (Phase 3 IN-01 to IN-06, Phase 6 IN-08): deferred with the reasons in the table above (D-03 allows it for info findings).
- **Other open review findings for Phases 2 and 5** (listed above with no reason): still open. No reason is invented here; each needs the user's decision (fix, defer with a reason, or accept).
- **Phase 3 WR-01** (03-REVIEW.md: the Booking Summary PAID label on cancelled, declined or expired paid sessions): the user decided on 2026-11-22 that paid rows keep PAID; the review raised the never-charged statuses after that decision. Still open for the user's ruling (accept as is, or change in 1.2); it is not recorded as covered by the regression.
- **Android local-build section (A1 to A17)**: not run in this regression and does not gate the iOS submission. The Android release is not part of this phase.
- **Backlog 999.3** (a maximum topic price): stays in the backlog (see Backlog dispositions).
- **1.2 todos**: `2026-11-23-shorten-call-overtime-to-15-minutes` and `2026-11-23-add-an-in-app-guide-before-expert-stripe-payout-setup`.
- **Follow-up note, toolchain**: App Store Connect returned an ITMS-90725 warning on the build 7 upload. Builds uploaded from April 2027 must use Xcode 27 and the iOS 27 SDK, so the release workflow (`XCODE_VERSION: '26'`, `macos-26` runners) needs the upgrade before then. Recorded here as a note, not a todo.
- **App Review**: Waiting for Review at the time of writing; the version is set to release automatically on approval with Phased Release off (D-21).

### Release references

- **Tag** `v1.1` (annotated, tag object `e5a92134f134e68799a94a54c3efd52ff1e4d738`, "ClickMe iOS 1.1 (7)") peels to `1fdcc26edd754d5f156bb8369c41fb2e5f0281f5`, the built commit and the `release/1.1` tip (plan 08-20).
- **Backend merge commit** `e36da572b8f2559da5ef05c16942864cf4eb4dab` (plan 08-21, D-17): backend `master` takes `origin/main` at `1d18aac` with D-12, CR-02 and D-29; `master` is not pushed and not deployed.
- **Production backend**: frozen at `1d18aac` (`1d18aac740dd49c7e5b8b0ed2d59563c0d9a5594`), the X2 SHA; rollback branch `ios-p8-x2-rollback`.

### Folded todos

The 14 todo files folded into Phase 8 (08-CONTEXT.md, Folded Todos), one line each. A `completed` todo is in `.planning/todos/completed/` with a `## Resolution`; a `pending` one is still in `.planning/todos/pending/` with the reason. Every Android port the user requested in 08-26 (P1 to P6) has landed on ClickMe_Android `main` (08-31), so no parity todo is open on an unlanded port.

- 2026-11-11-merge-d12-into-backend-master: completed (08-21, backend `master` took `origin/main` at `1d18aac` by merge commit `e36da57`; not pushed, not deployed)
- 2026-11-12-long-lead-sweep-transient-errors-after-stamp: completed (08-14, D-29 retry of transient errors up to 6 h before the session, backend `1d18aac`, deployed in X2 by 08-16)
- 2026-11-16-backend-null-topic-currency: completed (08-05, null instead of an empty string for a topic with no currency, backend `412f1aa`, deployed in X1 by 08-08)
- 2026-11-14-backend-profile-name-validation: completed (08-05, D-30 hand-written messages for empty profile names, backend `0767cf4`, deployed in X1; the empty-last-name decisions stay product questions)
- 2026-11-13-decide-saved-cards-on-account-deletion: completed (08-13, D-23 disclose it on Delete Account: "Cards you added to pay for sessions are not deleted with your account.")
- 2026-11-16-usd-symbol-us-dollar-prefix: completed (08-10, D-24 USD renders as US$ and CAD as CA$ on iOS; the Android symbol override is 08-03)
- 2026-11-16-android-phase-6-parity-follow-ups: completed (08-31, P1 off-grid stored time and P2 client hub online dot ported on ClickMe_Android `main`; device checks A12 and A13 not run)
- 2026-11-13-android-phase-5-parity-check: completed (08-31, P3 to P6 ported on ClickMe_Android `main`, P7 closed by the user on 2026-11-20; device checks A10 and A14 to A17 not run)
- 2026-11-13-android-cancellation-policy-link: completed (08-12, cancellation policy screen and link, Android `2ffb5d23`)
- 2026-11-13-android-delete-account-copy-and-blockers: completed (08-17, truthful Delete Account copy and the 409 blocker alert, Android `2a65e7c7` and `e311a74c`)
- 2026-11-13-android-remember-login-email: completed (08-09, remembered login email ported by hand, Android `adc3647a` and `e3676ef1`)
- 2026-11-14-android-profile-settings-empty-name-save: completed (08-06, never send an empty profile name and name the fields on a 422, Android `9ce71b80` and `337f4c0c`)
- 2026-11-15-android-expert-settings-clear-meeting-link: completed (08-06, clearing the meeting link sends `meeting_url: ""`, Android `ad190070`)
- 2026-11-08-check-the-android-push-prompt-after-a-reinstall: pending - device check not run in Phase 8 (A11's Result is empty; the 08-12 source reading found no reinstall gap, which is not a device result)
