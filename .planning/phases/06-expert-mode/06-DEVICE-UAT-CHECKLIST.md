# Phase 6 Device UAT Checklist

Every device check Phase 6 (Expert Mode) left open, in one list, plus the planner and UI-SPEC assumptions you are asked to judge. Built by plan 06-10 from every `06-0[1-9]-SUMMARY.md`, the `<human-check>` blocks in plans 06-01 to 06-09, the "UI Considerations" (D1 to D6 and the backstops LT3, OV2, E7 and PO1) and "Device-only checks" tables in `06-UI-SPEC.md`, and the "Manual-Only Verifications" table in `06-VALIDATION.md`. All code is merged and unit-tested; nothing on this list has been seen on a device yet. Where a SUMMARY recorded a deviation or a superseded wording, the SUMMARY's wording is used and the item says so (for example Booking Confirmed is hosted inside the decision screen, and the Booking Note swipe-back is always locked). Claude runs only local tests and builds: every step on a device or against production is yours.

## Setup

- **Device:** a real iPhone on iOS 18 or later, not the simulator. Swipe-back, the keyboard, EventKit, Dynamic Type and push need hardware. The glass checks (items 13 and 16) need iOS 26.
- **Build:** a build at or after `9e95cf3` (plan 06-08), the last Phase 6 commit that touched app code (`git log -1 --format=%h -- ClickMe2026`). Every later Phase 6 commit is tests or docs. The working tree also carries uncommitted edits to `ClickMe2026/Localizable.xcstrings` that Phase 6 did not make (Xcode rewrites it on every build); for a build that is exactly Phase 6, check out `9e95cf3` (or the current HEAD) in a clean copy.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`). Phase 6 made no backend change. Re-check read-only before you start that `/health` reports a commit containing `28da165` (it reported exactly `28da165` on 2026-11-16 when this list was written; `28da165` is also the head of the backend `origin/main`).
- **Accounts (yours):**
  - a **test expert** with a free topic and a paid USD topic (the paid CAD topic of item 1 is created during the run), at least one pending request for a free topic and one expired request;
  - a **test client** who can send a request to that expert for the free topic;
  - a client with **one CAD and one USD session** with that expert (and one cancelled session if you have it);
  - a **second device or account** to cancel a request while the expert has it open (item 19);
  - an **Android device or emulator** for the Android check (item 32) and for the booking ID comparison (item 25);
  - **App Store build 6** on a device for the "before" check of the expired card (item 21).
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. Items that ask for a decision take `KEEP` or `CHANGE (what)`. Do not write a token, a password, a card number or a real email address anywhere in this file; refer to an account by its role ("the test expert").

## Notes before you start

- **The Phase 2 to 5 UATs are still partial.** `02-DEVICE-UAT-CHECKLIST.md`, `03-DEVICE-UAT-CHECKLIST.md`, `04-DEVICE-UAT-CHECKLIST.md` and `05-DEVICE-UAT-CHECKLIST.md` must run before Phase 8. Phase 6 touched screens they cover (the shared shell exit used by Back to Home, the expert Booking Summary and Client Profile), so run them on the same build.
- **Nothing in this plan, and nothing you write in this file, ticks a box in `REQUIREMENTS.md`.** EXP-01 to EXP-10, EXP-12 and EXP-14 to EXP-18 stay as they are there until `/gsd-verify-work 06` reads the Results. Whether a failed item re-opens a requirement is that command's decision.
- **Every environment is production with live Stripe keys.** Accepting and declining a request changes a real booking and a real card hold, so accept and decline only requests for a **free** topic made by a test client. Creating, editing and deleting a topic needs no money, but it changes the expert's real topic list: use a spare test topic for Delete.
- **Use airplane mode for every forced failure.** It fails in milliseconds; a black-holed network can take minutes (120 s request timeout).
- **Settled by you on 2026-11-16, not asked again** (recorded in `06-CONTEXT.md` and resolved in `06-RESEARCH.md` Open Questions):
  - Open Question 1, the D-11 amendment: Booking Confirmed is hosted inside Request Decision, not pushed by a path replace. Items 14 and 15 check the behavior only.
  - Open Question 2, the D-19 amendment: swiping back on the Booking Note screen is always locked. Item 29 checks the behavior only.
- **Assumptions for you to judge** (items 34 and 35, each `KEEP` or `CHANGE (what)`): the expert's own public-profile preview with no dot (Open Question 5), and EXP-12 as a LIKELY item whose before-state you confirm on build 6 (items 21 and 22).
- **Follow-ups logged, not built:** the Android parity checks (Add hours at the end of the day, off-grid rows, 409, client hub dot) are in `.planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md`; whether USD reads `$` or `US$` is in `.planning/todos/pending/2026-11-16-usd-symbol-us-dollar-prefix.md` (a USD topic card reading `$20.00` while the editor label reads `US$` is that known question, not a failure). A flaky Make a Booking test is `2026-11-13-flaky-make-a-booking-availability-test.md`.

## Automated evidence

Run by plan 06-10 on 2026-11-16 at HEAD `eb70496` (the last Phase 6 app commit is `9e95cf3`; every later Phase 6 commit is tests or docs), simulator `iPhone 17`, Debug:

- **Phase gate suite (the full unit suite in one xcodebuild invocation, smoke suites and the known flake skipped):** `✔ Test run with 952 tests in 93 suites passed after 8.277 seconds.` and `** TEST SUCCEEDED **` (log `/tmp/06-10-full.log`). Skipped: `AuthSmokeTests` and `SignupSmokeTests` hit production and were not run; `MakeABookingAvailabilityTests` is the known flaky suite (todo `2026-11-13-flaky-make-a-booking-availability-test.md`) and was run separately below. This run includes every Phase 6 stubbed `.serialized` suite (`TopicsSetupMutationTests`, `RequestDecisionAcceptTests`, `ExpertBookingNoteViewModelTests`) alongside the others.
- **Known-flaky record run (`MakeABookingAvailabilityTests` alone, not part of the verdict):** run 1 failed: `✘ Test run with 5 tests in 1 suite failed after 0.704 seconds with 1 issue.` at `MakeABookingAvailabilityTests.swift:154` (`olderLoadLandingLastWritesNothing`, `Zone/1` against `Zone/2`, the failure the todo describes). Run 2 passed: `✔ Test run with 5 tests in 1 suite passed after 0.707 seconds.` No Phase 6 commit touches the Make a Booking folder or its test file (0 commits in `fe3372c..HEAD`). Logs `/tmp/06-10-flaky-1.log` and `/tmp/06-10-flaky-2.log`; the outcome is appended to the todo.
- **Debug build:** `** BUILD SUCCEEDED **`; the only `warning:` line in the log is the build system's own "Metadata extraction skipped. No AppIntents.framework dependency found." (log `/tmp/06-10-build.log`).
- **Grep gates (all PASS):**
  - no `rateMajor` in `TopicEditorViewModel.swift` outside comments: 0 matches;
  - no `Returns 409 if the topic has active` in `ClickMe2026`: 0 matches;
  - no `slot: $viewModel.schedule` in `AvailabilitySettingsView.swift`: 0 matches;
  - no `expertName` in the `Expert Mode/Confirmed` folder outside comments: 0 matches;
  - no `replace(with:)` in `RequestDecisionView.swift`: 0 matches;
  - no `opacity(request.isExpired` in `IncomingRequestCard.swift`: 0 matches;
  - no `isOnline` in `ExpertProfileHomeViewModel.swift`: 0 matches;
  - the `toolbarColorScheme(.dark, for: .navigationBar)` pin appears once in `AvailabilitySettingsView.swift` and once in `RequestDecisionView.swift`.
- **Android (plan 06-09):** one commit, `da498620` in `ClickMe_Android`; `TopicEditorViewModelTest` 49/49, `TopicEditorSubviewsTest` 30/30 and `TopicEditorScreenTest` 22/22 passed with `ktlintCheck` clean (Gradle, from the 06-09 SUMMARY; not re-run here).
- **What the automation does not cover:** every item below.

---

## Items
