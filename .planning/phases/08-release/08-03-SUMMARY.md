---
phase: 08-release
plan: "03"
subsystem: android-parity
tags: [android, kotlin, compose, chat, money, parity, tdd]

requires:
  - phase: 08
    provides: "08-02 backend marker event_data.reschedule_decline; backend 94d659b reason_text / reason_by in chat event_data"
provides:
  - "Android chat system-event rows show who gave which reason (cancel, decline, reschedule proposal), with the same captions as iOS plan 08-07"
  - "Android reschedule-decline rows read 'Reschedule Declined' and are non-terminal"
  - "Android Money renders USD as US$ and CAD as CA$ in every locale (symbol override only)"
affects: [08-07, 08-08, 08-21, android-release]

actuals:
  tokens: 8766
  tasks: 2
  commits: 2

plan_head_before: 27e024bf507e29f6cc10ceefd0790e4fdc39be47
plan_head_after: 50626142e5e57f50aea0108bd7895588404a5cf0
commits: 2

tech-stack:
  added: []
  patterns:
    - "Reason caption composed once in ChatMessageMapping.toThreadItem from event_data; the row only renders plain strings"
    - "Currency symbol pinned by copying the locale formatter's DecimalFormatSymbols and setting currencySymbol, leaving placement and grouping to the locale"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatMessageMapping.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ThreadItem.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/subviews/SystemEventRow.kt"
    - "../ClickMe_Android/app/src/main/res/values/strings_chat_thread.xml"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/util/Money.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/testing/ChatFixtures.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ChatMessageMappingTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/util/MoneyTest.kt"

key-decisions:
  - "Caption wording lives in ChatMessageMapping.kt as plain English strings (not string resources), because the plan's behavior rows assert the mapped ThreadItem.reasonCaption text and the mapper has no Context; the only new string resource is the 'Reschedule Declined' title"
  - "decline_reason_text is a fallback only for a request decline (no reschedule_decline marker): that column is shared with reschedule declines on the backend, so a marked decline reads reason_text alone, matching the iOS 08-07 rule"
  - "The reschedule_decline marker is honored only on a BOOKING_DECLINED row and only as a literal boolean true, like the backend"
  - "A blank reason_text falls through to decline_reason_text (request declines) instead of ending the caption"
  - "Commit trailer is 'Co-Authored-By: Claude Sonnet 5.5', the model that actually ran, not the 'Opus 5.5' string in the plan and dispatch note"

patterns-established:
  - "ThreadItem.SystemEvent.isTerminal and ThreadItem.SystemEvent.titleRes() are the per-event reads; SystemEventKind.isTerminal / titleRes() stay the per-kind defaults"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Android chat row shows the cancel, decline or reschedule-proposal reason with who gave it ('Reason from the client: ...', 'Reason: ...', 'Note from the expert: ...'), trimmed, blank shows nothing, a row with none of the keys maps as before"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../screens/chat/chatting/ChatMessageMappingTest.kt#cancelReasonFromTheClientIsTrimmedAndLabelled, cancelReasonFromTheExpertIsLabelledAsTheExpert, cancelReasonWithoutReasonByUsesThePlainLabel, unknownReasonByUsesThePlainLabelNeverTheRawValue, rescheduleProposalNoteIsLabelledByWhoSentIt, blankReasonShowsNoCaption, eventWithNoReasonKeysMapsAsBefore"
        status: pass
    human_judgment: false
  - id: D2
    description: "A request decline reads reason_text ?? decline_reason_text as the expert's reason, adds the iOS DeclineNote label for a known decline_reason_code, and shows nothing (never the raw code) for an unknown one"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ChatMessageMappingTest#requestDeclineFallsBackToDeclineReasonTextAsTheExpert, requestDeclinePrefersReasonTextOverDeclineReasonText, declineCodeLabelsMatchTheIosTable, unknownDeclineCodeShowsNothingAndNeverTheRawCode"
        status: pass
    human_judgment: false
  - id: D3
    description: "reschedule_decline true makes a BOOKING_DECLINED row read 'Reschedule Declined' and not count as terminal; without the marker it stays 'Booking Declined' and terminal"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ChatMessageMappingTest#rescheduleDeclineReadsRescheduleDeclinedAndIsNotTerminal, rescheduleDeclineWithoutReasonByUsesThePlainLabel, declineWithoutTheMarkerStaysABookingDeclinedAndTerminal"
        status: pass
    human_judgment: false
  - id: D4
    description: "Reason text never reaches ThreadItem.SystemEvent.toString"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "ChatMessageMappingTest#reasonTextNeverReachesToString"
        status: pass
    human_judgment: false
  - id: D5
    description: "Money renders USD as US$ and CAD as CA$ in every locale, placement and grouping unchanged (Locale.US 123456789012 USD -> US$1,234,567,890.12; Locale.CANADA 5000 CAD -> CA$50.00)"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../util/MoneyTest.kt (17 tests: six Locale.US USD rows now US$, cad_inCanadianLocale_stillShowsCadMarker, usd_inCanadianLocale_showsUsMarker)"
        status: pass
      - kind: other
        ref: "./gradlew :app:testDevDebugUnitTest ktlintCheck (full run): BUILD SUCCESSFUL, 5343 tests"
        status: pass
    human_judgment: false
  - id: D6
    description: "On an Android device the reason lines wrap fully under the row title and read well next to the title and subtitle; US$ and CA$ look right on real screens"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Compose rendering of the new lines (spacing, wrapping, contrast) is not asserted by any unit test; D-31 puts it in the cross-platform regression run, which needs the deployed backend (08-08)."

duration: 25min
completed: 2026-11-19
status: complete
---

# Phase 08 Plan 03: Android chat reasons and US$/CA$ parity Summary

**Android chat rows now show the cancel, decline and reschedule reason with who gave it (and read "Reschedule Declined", non-terminal, for a reschedule decline), and Android Money shows US$ and CA$ in every locale by overriding only the currency symbol; two local commits in ClickMe_Android, nothing pushed.**

## Performance

- **Duration:** about 25 min by the system clock (start approximated from the first Android edit; no start timestamp was recorded)
- **Started:** 2026-11-20T03:58:00Z (approximate)
- **Completed:** 2026-11-20T04:24:00Z
- **Tasks:** 2 (Task 1 tracer, Task 2 auto/tdd)
- **Files modified:** 17 in the Android repo (6 in the chat commit incl. tests and one string resource, 11 in the money commit incl. 9 existing tests); this iOS repo gets only planning files

## Accomplishments

- `ChatMessageMapping.toThreadItem` reads `reason_text`, `reason_by`, `decline_reason_text`, `decline_reason_code` and `reschedule_decline` once and fills three new `ThreadItem.SystemEvent` fields (`reasonCaption`, `reasonCodeLabel`, `isRescheduleDecline`). Captions match iOS plan 08-07: `Reason from the client|expert: <text>` or `Reason: <text>` for cancelled and declined rows, `Note from the client|expert: <text>` or `Note: <text>` for a reschedule proposal. The role comes from `reason_by`, never from the text; a request decline with no `reason_by` is labelled as the expert's.
- The decline-code label table is copied from iOS `DeclineNote.reasonLine(for:)` (UNAVAILABLE, OUTSIDE_EXPERTISE/OUT_OF_SCOPE, SCHEDULE_CONFLICT/CONFLICT, PRICING, OTHER); an unknown code gives no line and the raw code is never shown.
- `SystemEventRow` renders the code label then the caption as plain `Text` (no `AnnotatedString`, no links) in the row's muted style, wrapping fully. A reschedule decline uses the new `chat_event_reschedule_declined` title through `ThreadItem.SystemEvent.titleRes()`, and `onOpenBooking` now receives `event.isTerminal`, which is false for that row, so the card still opens the live booking.
- `Money.format` copies the locale formatter's `DecimalFormatSymbols`, sets `currencySymbol` to `US$` (USD) or `CA$` (CAD) and assigns it back; placement, grouping and fraction digits are untouched. `Locale.CANADA` CAD used to read `$50.00` and now reads `CA$50.00`.
- Reason text is kept out of `SystemEvent.toString` (T-08-08); `toString` gains only `isRescheduleDecline`.

## RED / GREEN evidence (TDD)

- **RED (Task 1):** with the new `ThreadItem` fields scaffolded inert (null / false defaults) and the fixture parameters added so the test class compiles, `ChatMessageMappingTest` ran 26 tests and 11 failed, all on the planned assertions (`ChatMessageMappingTest.kt` lines 101 to 181); the 15 other rows passed by design (the 11 existing tests plus four regression rows: no-key, blank, unmarked decline, `toString`). Not a build or fixture failure.
- **GREEN (Task 1):** same class, 26 passed; `ktlintCheck` clean after one line-length fix in a test.
- **RED (Task 2):** `MoneyTest` ran 17 tests, 7 failed on the planned assertions (the six tests holding the edited `Locale.US` USD rows, and `cad_inCanadianLocale_stillShowsCadMarker`); `usd_inCanadianLocale_showsUsMarker` already passed because `en_CA` renders USD as `US$` natively.
- **GREEN (Task 2):** `MoneyTest` 17 passed; full unit run `:app:testDevDebugUnitTest ktlintCheck` BUILD SUCCESSFUL, 5343 tests, 0 failed.
- RED evidence was read from the Gradle console and JUnit XML directly; `gsd_run check tdd-red-evidence` was not run, since `workflow.tdd_mode` is not enabled for this project.

## Task Commits

Both in `/Users/LeonChen/Documents/ClickMe_Android`, branch `main`, not pushed:

1. **Task 1 (tracer): chat reasons** - `8aaee356` (feat): `feat(ios-p8): show booking action reasons in chat (G-03-1-ITEM1B)`; six files
2. **Task 2: US$ and CA$** - `50626142` (fix): `fix(ios-p8): show US$ and CA$ regardless of locale (D-24, D-32)`; eleven files

Tracer gate: `human_verify_mode` is `end-of-phase` and the tracer's `<verify>` is automated-only, so the verify was re-run end to end (it passed again inside the full suite) and expansion continued, no checkpoint.

**Plan metadata:** committed in the iOS repo after this file (docs: complete plan).

## Files Created/Modified

All under `/Users/LeonChen/Documents/ClickMe_Android/app/src/`:

- `main/java/.../screens/chat/chatting/ChatMessageMapping.kt` - reads the reason keys, composes caption and code label, sets the marker
- `main/java/.../screens/chat/chatting/ThreadItem.kt` - `SystemEvent` gains `reasonCaption`, `reasonCodeLabel`, `isRescheduleDecline` and a computed `isTerminal`; `toString` excludes the text
- `main/java/.../screens/chat/chatting/subviews/SystemEventRow.kt` - `SystemEvent.titleRes()`, `ReasonLine`, terminal flag from the event
- `main/res/values/strings_chat_thread.xml` - `chat_event_reschedule_declined`
- `main/java/.../util/Money.kt` - `pinnedSymbol` and the `DecimalFormatSymbols` override
- `test/java/.../testing/ChatFixtures.kt` - `chatEvent(...)` gains `reasonText`, `reasonBy`, `declineReasonText`, `declineReasonCode`, `rescheduleDecline`
- `test/java/.../screens/chat/chatting/ChatMessageMappingTest.kt` - 15 new rows
- `test/java/.../util/MoneyTest.kt` - six USD rows to `US$`, two `Locale.CANADA` rows
- Nine other unit tests updated to expect `US$` (listed under Deviations)

## Decisions Made

See `key-decisions` above. Follow-up logged, not built (D-32): full iOS layout parity for money (prefix-only symbol, no thousands grouping) on Android. Android still follows the device locale for placement, so `de_DE` shows `1.234,56 US$`, not `US$1,234.56`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Nine other Android unit tests pinned a bare `$` for USD output of `Money`**
- **Found during:** Task 2, the second automated check (full unit run)
- **Issue:** The plan's `fails_when` anticipated this ("another test pinned a bare $ for USD"). After the symbol change the full run had 16 failures in 10 classes, all of the form expected `$75.00` but was `US$75.00`; no logic differed.
- **Fix:** Changed only the expectations that compare against `Money` output (and one `Money.format` assertion plus a comment in `EarningsUnitsRegressionTest`); fixture strings handed to composables as already-formatted text were left alone because they still pass and test other things. One further failure, `transactionsAreMinorUnits`, surfaced on the second full run and was fixed the same way.
- **Files modified:** `components/PriceTextTest.kt`, `screens/expertmode/bookingsummary/ExpertBookingSummaryScreenTest.kt` and `...ViewModelTest.kt`, `screens/expertmode/cancellation/ExpertCancellationScreenTest.kt`, `screens/expertmode/incomingrequests/IncomingRequestsLogicTest.kt` and `...ScreenTest.kt`, `screens/expertmode/payouts/EarningsUnitsRegressionTest.kt`, `screens/expertmode/requestdecision/RequestEarningsSectionTest.kt`, `screens/expertmode/upcomingbookings/ExpertBookingsScreenTest.kt`
- **Verification:** full `:app:testDevDebugUnitTest ktlintCheck` BUILD SUCCESSFUL, 5343 tests
- **Committed in:** `50626142` (Task 2 commit). The plan says the commit stages "the two paths by name"; it stages eleven, because the full run could not be green otherwise and the plan requires it green.

**2. [Rule 3 - Blocking] A string resource file joined the Task 1 commit**
- **Found during:** Task 1
- **Issue:** The plan's action allows "add a string resource if titles are resources"; they are, so `strings_chat_thread.xml` is a sixth file where the acceptance criterion says "exactly the five files".
- **Fix:** Added `chat_event_reschedule_declined` ("Reschedule Declined") to `strings_chat_thread.xml` and staged it by name.
- **Committed in:** `8aaee356`

**3. [Plan-structure choice] TDD RED/GREEN done without separate test/feat commits**
- **Issue:** The dispatch asked for RED, GREEN, REFACTOR; the plan's truths and acceptance criteria require exactly two commits in the Android repo, one per change.
- **Fix:** RED was run for real before each implementation and recorded above, but each task is one commit (tests plus implementation), as the plan specifies. No REFACTOR commit was needed.

**4. [Attribution] Commit trailer names Sonnet 5.5**
- The plan and the dispatch note ask for `Co-Authored-By: Claude Opus 5.5`; the session's attribution rule and the model that actually wrote the commits is Sonnet 5.5, so that is what the two commits carry. Rewording is possible before any push if the Opus string is wanted.

---

**Total deviations:** 4 (2 Rule 3 blocking fixes, 1 structural choice, 1 attribution)
**Impact on plan:** No scope creep. The extra test edits are a direct consequence of D-24 and were anticipated by the plan; the chat and money behavior is exactly as specified.

## Issues Encountered

- `ktlintCheck` rejected one over-long test line in `ChatMessageMappingTest.kt` (line 171, 121 columns); shortened the test text, no behavior change.
- A first `git add` in a compound command was refused by the shell (bash 3.2); re-run as plain separate commands. No state was changed by the refused call.

## Known Stubs

None. No placeholder, empty-default or TODO values were introduced; the new `ThreadItem.SystemEvent` fields default to null / false only as "no reason", which is the real value for events without the keys.

## Threat Flags

None. The new surface (another user's free text in a chat row) is the plan's own T-08-07 / T-08-08 and is mitigated: plain `Text`, role label from `reason_by`, text excluded from `toString`, nothing logged. No dependency added (T-08-SC).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Android now matches the iOS source of truth for chat reasons and money symbols; iOS plan 08-07 builds the iOS half with the same captions and marker rule.
- Not pushed and not merged by design: the Android release is outside this phase. The Android repo has pre-existing unrelated `.idea` changes that were never staged.
- Device check of the new Android rows (D6 above) belongs to the regression run once the backend is deployed (08-08).

## Self-Check: PASSED

- Commit `8aaee356` and `50626142` are on `main` in ClickMe_Android; `git rev-list --count 27e024bf..HEAD` is 2.
- All eight key-files exist on disk and `git status --short` in the Android repo lists only the three pre-existing `.idea` modifications (plus untracked planning scratch that was never touched).
- `ChatMessageMappingTest`, `MoneyTest` and the full `:app:testDevDebugUnitTest ktlintCheck` run are green.

---
*Phase: 08-release*
*Completed: 2026-11-19*
