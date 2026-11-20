---
phase: 08-release
plan: "12"
subsystem: android-parity
tags: [android, kotlin, compose, cancellation-policy, availability, parity, tdd]

requires:
  - phase: 08
    provides: "iOS CancellationPoliciesView and the corrected cancel-confirmation copy (Phase 5 05-06, SET-07); iOS AvailabilitySlotRules.addHours (Phase 6 06-03); the Android parity todos from Phases 5 and 6"
provides:
  - "Android Cancellation Policy screen (CancellationPolicyScreen, CancellationPolicyKey) with the three iOS cards, reachable from a 'Cancellation policy' link on the cancel confirmation step"
  - "Android refund footnote 'Your bank decides how long a refund takes to appear.' replaces the business-days promise in the client cancel flow"
  - "Android AvailabilityScheduleLogic.canAddHours(slots); addHours never starts a slot before the latest existing end; the day card's Add hours button is disabled and dimmed when there is no room"
  - "A 'Phase 8 answers' section in the Phase 5 parity, Phase 6 parity and push-prompt todos (16 parity rows answered from the Android source)"
affects: [08-15, 08-24, 08-26, android-release, 08-REGRESSION-CHECKLIST]

actuals:
  tokens: 7000
  tasks: 3
  commits: 2

plan_head_before: e3676ef18426dddd14830f982301dd4a1215abc3
plan_head_after: 384142ee77c68c11cdfaea88f1f8edadd8250548
commits: 2

tech-stack:
  added: []
  patterns:
    - "Nav3 leaf route as a data object key (CancellationPolicyKey) registered in the client shell with BottomBar.hidden(); the pushing screen's entry-scoped ViewModel keeps its state while the leaf is open"
    - "Pure schedule-rule predicate (canAddHours) read by both the logic and the card, so the on-screen disabled state and the no-op cannot disagree"

key-files:
  created:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/cancellation/CancellationPolicyScreen.kt"
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/cancellation/ClientCancellationScreen.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/cancellation/subviews/CancellationConfirmStep.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/home/HomeClientScreen.kt"
    - "../ClickMe_Android/app/src/main/res/values/strings_cancel_booking.xml"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/clientmode/cancellation/ClientCancellationScreenTest.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/AvailabilityScheduleLogic.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/subviews/AvailabilityDayCard.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/AvailabilityScheduleLogicTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/AvailabilityScreenTest.kt"
    - ".planning/todos/completed/2026-11-13-android-cancellation-policy-link.md"
    - ".planning/todos/pending/2026-11-16-android-phase-6-parity-follow-ups.md"
    - ".planning/todos/pending/2026-11-13-android-phase-5-parity-check.md"
    - ".planning/todos/pending/2026-11-08-check-the-android-push-prompt-after-a-reinstall.md"

key-decisions:
  - "The policy link opens CancellationPolicyKey through a new onOpenPolicy callback threaded ClientCancellationScreen -> ClientCancellationContent -> CancellationConfirmStep, wired in HomeClientScreen's cancel slot, so ClientBookingManagementEntries.kt (outside this plan's files) is untouched"
  - "CancellationPolicyKey lives in CancellationPolicyScreen.kt, keeping the plan's file list tight (the repo's other keys have their own file)"
  - "The disabled Add hours button is also dimmed to 0.45 alpha, as iOS does; there is no VoiceOver-style hint string (a disabled Material button is announced as disabled)"
  - "The expert cancel refund note (3-5 business days) is left as is: iOS ExpertCancellationMainCard says the same and the todo marks expert-cancel wording out of scope (iOS Phase 6 Q2)"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "The cancel confirmation step shows a 'Cancellation policy' link that opens a three-card Cancellation Policy screen with the iOS copy; the old business-days refund note is gone and the corrected footnote shows for refund cases only"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../clientmode/cancellation/ClientCancellationScreenTest.kt#confirmStepShowsThePolicyLinkAndOpensIt, policyScreenShowsTheThreeCardsWithTheIosCopy, fullRefundShowsAmountAndNote, noRefundNoteIsShownOutsideRefundCases"
        status: pass
    human_judgment: false
  - id: D2
    description: "Back from the policy screen returns to the cancel confirmation with the reason kept"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Rests on the entry-scoped ViewModel (rememberViewModelStoreNavEntryDecorator) and the Nav3 stack; no test drives the real nav host from the link through Back. Device check in the Android section of 08-REGRESSION-CHECKLIST.md."
  - id: D3
    description: "The Cancellation Policy screen looks right (three cards, readable on the dark theme)"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Layout and visual match to the iOS cards are not asserted by a test; Android styling is a Material approximation of the iOS gradient borders."
  - id: D4
    description: "Add hours never builds a slot that starts before the latest existing end; canAddHours is false from a latest end of 22:30; addHours is then a no-op; the end clamps to 23:30; the day card button is disabled"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../expertmode/availability/AvailabilityScheduleLogicTest.kt#addHours_latestEnd2200_addsHalfPastTenToHalfPastEleven, addHours_latestEnd2230_hasNoRoomAndLeavesTheDayUnchanged, addHours_offGridLatestEnd2215_clampsTheEndTo2330, addHours_latestEndLaterThanTheLastSlotIsUsed, addHours_midnightEndHasNoRoom, addHours_emptyDayCanAdd"
        status: pass
      - kind: unit
        ref: "app/src/test/.../expertmode/availability/AvailabilityScreenTest.kt#addHoursIsDisabledWhenTheLatestEndLeavesNoRoom, addHoursCallsAction"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every Phase 6 item and Phase 5 parity row has exactly one recorded answer; the Phase 5 and Phase 6 todos stay pending for 08-26"
    requirement: REL-02
    verification:
      - kind: other
        ref: "awk over '## Phase 8 answers' in both todos: 16 lines, each matches/aligned/differs/device check needed"
        status: pass
    human_judgment: true
    rationale: "The answers come from reading the Android source, not from a device; each differs row needs the user's port, defer or accept decision (plan 08-26)."

duration: ~40min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 12: Android cancellation policy link, Add hours end of day and parity answers Summary

**Android now links the cancel confirmation to a three-card Cancellation Policy screen with the iOS copy and a bank-timing footnote instead of the business-days promise, Add hours stops (disabled and dimmed) once the day has no room, and all 16 open parity questions have a recorded answer for the user's decision in 08-26.**

## Performance

- **Duration:** about 40 min (start time was not captured when the run began)
- **Completed:** 2026-11-20
- **Tasks:** 3
- **Files modified:** 10 Android files (1 created) and 4 todo files
- **Android commits:** 2 (base `e3676ef1`, head `384142ee`); iOS repo: 1 todo commit plus this plan's close-out commit

## Accomplishments

- Cancel confirmation step: a centred, underlined `Cancellation policy` link in the primary colour, between the summary card and the Keep Booking and Confirm Cancellation buttons. It pushes `CancellationPolicyKey` (bottom bar hidden). Back pops to the confirmation, whose entry-scoped ViewModel still holds step, reason and comment through `SavedStateHandle`.
- `CancellationPolicyScreen`: three cards titled **Cancellation Deadlines**, **Refund Eligibility** and **How to Initiate a Cancellation**, which match iOS `CancellationPoliciesView` (`CancellationDeadlinesCard`, `RefundEligibilityCard`, `HowToInitiateCard`). The text is copied word for word, including the corrected intro and the four steps ending `Tap 'Cancel'.` and the refund text "a full refund ... more than 24 hours before the start", "No refund ... within 24 hours of the start". That equals `refund.js`; no refund timing is promised (threat T-08-26).
- `cancel_booking_refund_note` is now `Your bank decides how long a refund takes to appear.`, shown only for the full-refund case. A test asserts that no "business days" text is on the screen. The tracer gate greps pass.
- Add hours: `canAddHours(slots)` (true for no slots, else latest end + 30 min must be before 23:00), `addHours` returns the day unchanged without room, the start is latest end + 30 min with no clamp back to 23:00 (that clamp was the overlap), and the end clamps to 23:30. The day card reads `AvailabilityScheduleLogic.canAddHours(day.slots)` for the button's `enabled` flag, and dims it to 0.45 alpha as iOS does.
- Parity answers: Phase 6 items 1-4 and the 12 Phase 5 rows each have one line under `## Phase 8 answers`; the push-prompt todo has its finding and device step. The policy-link todo moved to `completed/` with a `## Resolution`.
- Full Android unit suite: 5394 tests, 0 failures, 0 skipped; `ktlintCheck` clean.

## Task Commits

Android repo (`/Users/LeonChen/Documents/ClickMe_Android`, branch `main`, local only, nothing pushed):

1. **Task 1 (tracer): policy link, policy screen, corrected copy** - `2ffb5d23` (feat)
2. **Task 2 (tdd): Add hours end of day** - `384142ee` (fix); the plan fixes one commit for this task, so RED and GREEN are one commit and the RED output is recorded below

iOS repo (`/Users/LeonChen/Documents/ClickMe2026`, branch `main`):

3. **Task 3: parity answers and the policy-link todo close** - `2127908` (docs)

**Plan metadata:** the close-out commit that adds this SUMMARY, STATE.md and ROADMAP.md (docs: complete plan).

## Tracer gate

Task 1 ran as the tracer. `<verify>` was run end to end before Task 2 started: `testDevDebugUnitTest --tests '...clientmode.cancellation.*' ktlintCheck` was BUILD SUCCESSFUL (ClientCancellationScreenTest 36 tests, 0 failures), the hyphenated `3-5 business days` grep found nothing in `res/values/`, and the new footnote string is present. The first run failed ktlint on the new test (chained calls on one line); fixed and re-run before the commit.

The three card titles quoted from the Android screen: "Cancellation Deadlines", "Refund Eligibility", "How to Initiate a Cancellation". They are the same three titles as the iOS cards.

## TDD record for Task 2 (RED output)

Plan-level `type` is `execute`, so the `check tdd-red-evidence` classifier and a separate `test(...)` commit were not required; the plan fixes a single commit. RED was run for real with a stub `canAddHours` that returned `true` so the new tests compiled and failed on their assertions (a missing symbol would be a build failure, not RED):

- Command: `./gradlew :app:testDevDebugUnitTest --tests '...AvailabilityScheduleLogicTest' --tests '...AvailabilityScreenTest'`
- Result: `62 tests completed, 4 failed`
  - `AvailabilityScheduleLogicTest > addHours_latestEnd2230_hasNoRoomAndLeavesTheDayUnchanged` (AssertionError, `assertFalse(canAddHours(...))`)
  - `AvailabilityScheduleLogicTest > addHours_latestEndLaterThanTheLastSlotIsUsed` (AssertionError)
  - `AvailabilityScheduleLogicTest > addHours_midnightEndHasNoRoom` (AssertionError)
  - `AvailabilityScreenTest > addHoursIsDisabledWhenTheLatestEndLeavesNoRoom` (AssertionError: "Failed to assert the following: (is not enabled)")
- Semantic assessment: each failure is on the planned assertion for the intended reason (no room not detected, button always enabled). The cases that already behaved correctly (latest end 22:00, off-grid 22:15, empty day) passed in RED, as expected.
- GREEN: same command, 62 tests, 0 failures, plus `ktlintCheck`. One ktlint line-length fix was needed on the way.

## Parity answers

Each answer is read from the Android source. Nothing was run on an Android device, and nothing is marked verified on a device. The full text is in the three todos.

**matches (9):** Phase 6 item 3 (409 `ALREADY_PROCESSED`); Phase 5 tag and language tap order, crop on upload, country normalized on publish, province optional and clearable, "City, Country" label, notification preferences save on open, one support address.

**aligned (1):** Phase 6 item 1, Add hours end of day (`384142ee`).

**differs (6), for plan 08-26 to put to the user:**

1. Phase 6 item 2, off-grid stored time: a stored 09:15 or 24:00 opens selected on Android too, but the row leaves the list once another row is tapped; iOS keeps it for the life of the sheet.
2. Phase 6 item 4, client hub online dot: Android's client Profile hub has no dot; iOS keeps its green dot (decision U2).
3. Photo required to publish: Android disables Publish and shows "Still needed: profile picture."; iOS refuses on tap with "Finish these first: Add profile picture."
4. Feedback minimum: Android's message is "Please describe your experience in at least 10 characters."; iOS's is "Please enter at least 10 characters."
5. Settings language save: Android's Done with nothing selected sends an empty list and the server deletes every language; iOS keeps the old list and shows "Keep at least one language." This one is the most consequential (data loss), so 08-26 should weigh it first.
6. Resume keeps the verified email: Android overwrites the local flag with each status read, so a stale "not verified" could untick Verify email; iOS never downgrades a local success.

**device check needed (2), for plan 08-15's Android section:**

- Phase 5 expert-mode gate and Not now: with an unfinished expert account tap an expert-targeted push and see the notifications list, not the hub; tap a push for the other mode during a call and see it wait for the call to end with no mode switch; relaunch and foreground a client-only account and see it stay client-only.
- Push prompt after a reinstall: code finding is that the iOS gap does not exist (`allowBackup=false` and the backup rules exclude all domains, so a reinstall wipes both the session and the "asked" flag, and the next login asks again). Device step: Android 13+, sign in, deny the prompt, uninstall, reinstall, sign in, see the prompt again; also note that a user who is signed in and was never asked gets no prompt on a plain relaunch because a session restore never prompts. Plan 08-24 closes that todo.

Other device checks for the Android section of `08-REGRESSION-CHECKLIST.md` (plan 08-15): Cancel Booking, Continue, tap `Cancellation policy`, check the three cards, Back, and confirm the reason is still selected; an expert with a Monday slot ending 22:30 sees Add hours dimmed and disabled, and one ending 22:00 can add 22:30-23:30.

The Phase 5 and Phase 6 todos stay in `pending/`; nothing was logged away or closed.

## Files Created/Modified

See the frontmatter `key-files`. In short: the new `CancellationPolicyScreen.kt`; the link, callback and route wiring in `ClientCancellationScreen.kt`, `CancellationConfirmStep.kt` and `HomeClientScreen.kt`; copy in `strings_cancel_booking.xml`; the Add hours rule in `AvailabilityScheduleLogic.kt` and the card in `AvailabilityDayCard.kt`; tests for both; and the four todo files.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The link had to be added in `CancellationConfirmStep.kt`, which the plan's file list omits**
- **Found during:** Task 1
- **Issue:** The confirmation step is the composable in `screens/clientmode/cancellation/subviews/CancellationConfirmStep.kt`; `ClientCancellationScreen.kt` only hosts it, so the link could not be placed from the listed files.
- **Fix:** Added `onOpenPolicy` and the `PolicyLink` composable there, and threaded the callback through `ClientCancellationScreen`/`ClientCancellationContent`. The Task 1 commit therefore has six paths (the plan's five plus this subview).
- **Files modified:** `.../cancellation/subviews/CancellationConfirmStep.kt`
- **Committed in:** `2ffb5d23`

**2. [Rule 1 - Bug] An existing test asserted the overlap bug**
- **Found during:** Task 2
- **Issue:** `addHours_clampsNearMidnight` expected a 23:00-23:30 slot to be appended after a latest end of 22:30 or later, which is the overlap the plan removes.
- **Fix:** Replaced it with the new rows (no room, off-grid 22:15, latest end from an earlier slot, midnight end, empty day).
- **Files modified:** `AvailabilityScheduleLogicTest.kt`
- **Committed in:** `384142ee`

**3. [Rule 2 - Missing critical] Disabled Add hours also needed to look disabled**
- **Found during:** Task 2
- **Issue:** The button's icon and label colours were fixed to primary, so a disabled button looked identical to an enabled one and the expert would not see why a tap does nothing.
- **Fix:** Dim the icon and label to 0.45 alpha when `canAddHours` is false, matching iOS.
- **Files modified:** `AvailabilityDayCard.kt`
- **Committed in:** `384142ee`

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 bug, 1 missing critical)
**Impact on plan:** All three were necessary to deliver what the plan asks. No scope creep.

## Issues Encountered

- **A business-days promise remains in the expert cancel flow.** `strings_expert_cancel.xml` (`expert_cancel_refund_note`) still says "Refunds typically appear in the client's account within 3-5 business days." Task 1's `fails_when` reads "the business-days promise still appears in any values resource", but its grep gate looks for `3-5 business days` with an ASCII hyphen (the real strings use an en dash) and the todo's item 4 puts expert-cancel wording out of scope (iOS Phase 6 Q2). iOS `ExpertCancellationMainCard.swift` line 38 says the same words today, so Android matches iOS. Changing it needs a decision made for both platforms (it is also a refund claim, threat T-08-26); it is raised here for the user rather than changed.
- Two ktlint failures on new test and card code (chained calls on one line; a line over 120 characters) were fixed before the commits.
- Disk stayed at about 5.4 GiB free throughout; no build failed for space and nothing was deleted.
- The Android checkout's pre-existing `.idea/*` changes and untracked `.planning` files were never staged.

## Known Stubs

None. No placeholder text, empty data or unwired components were introduced.

## Threat Flags

None. No new endpoint, auth path, file access or schema surface. T-08-26 (refund copy) is mitigated: the policy text is the iOS text, it matches `refund.js`, and the business-days promise is removed from the client flow and gated by a test.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 08-15 can pick up the Android device checks listed above; plan 08-24 closes the push-prompt todo; plan 08-26 must ask the user about the six `differs` rows and the two device-check rows before the Phase 5 and Phase 6 todos close.
- Nothing is blocked. The Android commits are local on `main` and not pushed.

## Self-Check: PASSED

- Files exist: `CancellationPolicyScreen.kt` (Android), this SUMMARY, the completed policy-link todo; the pending policy-link todo is gone.
- Commits are on their branches: Android `2ffb5d23` and `384142ee` (ancestors of Android HEAD), iOS `2127908`.
- Task verifies re-run: tracer gate (BUILD SUCCESSFUL, no hyphenated business-days string, new footnote present), Task 2 gates (clamp gone, card reads `canAddHours(day.slots)`, `assertIsNotEnabled` row present, BUILD SUCCESSFUL), Task 3 gates (todo moved, answers section present, 16 well-formed answer lines, Phase 5 and 6 todos not in `completed/`), full suite 5394 tests 0 failures and `ktlintCheck` clean.

---
*Phase: 08-release*
*Completed: 2026-11-20*
