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

To be filled by plan 08-22, copied from the Result line of each item R1 to R11 in `08-REGRESSION-CHECKLIST.md`. An empty Result means the item was not run.

## Submission

To be filled by plan 08-23.
