---
phase: 02-shared-ios-plumbing
plan: 15
subsystem: ui
tags: [swiftui, money, currency, formatting, client-profile, earnings, android-parity, swift-testing, tdd]

requires:
  - phase: 02-shared-ios-plumbing
    provides: "Plan 02-05 Money formatter (format(major:currency:) with fixed symbols and the backend digit set); plan 02-03 ClientProfileViewModel.mapBooking"
provides:
  - "ClientBookingHistory carries amountMajor: Double? and currency: String? in place of the integer amount"
  - "ClientProfileBookingCard.amountLabel(amountMajor:currency:) formats through Money.format(major:currency:) and shows a dash for an unknown, missing or non-finite amount"
  - "ClientProfileViewModel.mapBooking maps earnings_breakdown.net_amount and its currency into the history row, gated by ClientProfileViewModel.earningsStatuses (pending_approval, confirmed, pending_reschedule, in_progress, completed), as Android ClientHistory.AMOUNT_STATUSES does"
  - "ClientProfileBookingCardTests (5 label rows) and ClientProfileHistoryEarningsTests (7 rows: mapping, status gate both ways, nil net, missing breakdown, wire field decode)"
  - "App-wide gate: zero hard-coded currency-symbol interpolations remain in the app target"
affects: [02-12 device UAT checklist, 06 EXP-14 remaining Client Profile earnings surfaces, Android ClientHistory comments]

actuals:
  tokens: 3740
  tasks: 2
  commits: 4
plan_head_before: db6a0ca0702ff6fbe36046ff55176521478fc54b
plan_head_after: 63b743d24c10aea324be90b2e01756b9cd3a2401

tech-stack:
  added: []
  patterns:
    - "A display row that shows a server-side major-unit amount carries amountMajor plus currency, and its label is one static function over Money.format(major:) with a dash fallback"
    - "An earnings surface gates by status, not by data presence: the feed sends a breakdown on every row, so the status set is what keeps unearned money off the screen (mirrors Android)"
    - "Swift TDD RED commits may carry a compile-only seam (dropping private on the function under test) so the rows fail on assertions, not as a build failure; the evidence record says so"

key-files:
  created:
    - ClickMe2026Tests/Utils/ClientProfileBookingCardTests.swift
    - ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift
    - .planning/phases/02-shared-ios-plumbing/02-15-tdd-red-evidence-t1.json
    - .planning/phases/02-shared-ios-plumbing/02-15-tdd-red-evidence-t2.json
  modified:
    - "ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileView.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Client Profile/Subviews/ClientProfileBookingCard.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift"

key-decisions:
  - "The Client Profile history row shows the expert's net earnings now, matching Android, instead of a dash until Phase 6 (user decision at the tracer gate: approve and defer, match Android now); EXP-14 stays open for any other Client Profile earnings surface"
  - "The earnings status gate is Android's set verbatim (pending_approval, confirmed, pending_reschedule, in_progress, completed); rescheduled and unknown codes show a dash, as Android's else branch does"
  - "The amount formats through Money.format(major:currency:) with the fixed symbol table, not the device locale as Android does; the 02-05 decision stands and CA$75.00 is the iOS rendering"
  - "The BOOK-10 / EXP-14 device check is deferred by the user; it is PENDING for plan 02-12 with the Android-parity wording recorded in WINDOWS.md"

patterns-established:
  - "History row money: amountMajor + currency on the display model, Money.format(major:) ?? dash in one static label function"
  - "Status-gated earnings: a Set<BookingStatus> on the view model decides whether the breakdown is read at all"

requirements-completed: [BOOK-10]

coverage:
  - id: D1
    description: "The Client Profile history card formats its amount through Money.format(major:currency:): 75.0 USD is $75.00, 120.5 CAD is CA$120.50, 1200 JPY is ¥1200; nil amount, nil currency or a non-finite amount shows a dash"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ClientProfileBookingCardTests.swift#Client profile booking card amount (5 rows)"
        status: pass
      - kind: other
        ref: "grep gate: 0 lines matching the dollar-sign interpolation in ClickMe2026/**/*.swift; 0 'amount: 0' in ClientProfileViewModel.swift; 1 or more Money.format(major in ClientProfileBookingCard.swift"
        status: pass
    human_judgment: false
  - id: D2
    description: "mapBooking maps earnings_breakdown.net_amount and its currency into the row for pending_approval, confirmed, pending_reschedule, in_progress and completed; cancelled, declined, missed, expired, rescheduled, unknown, a nil net amount or a missing breakdown give nil/nil (dash)"
    requirement: BOOK-10
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift#Client profile history earnings mapping (7 rows, 18 cases)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Device check: as an expert, open a client's profile from a booking; gated rows show the net earnings as CA$x.xx, non-gated rows show a dash, no row shows $0 or CA$0.00 unless the net really is zero, layout unchanged"
    requirement: BOOK-10
    verification: []
    human_judgment: true
    rationale: "Deferred by the user at the tracer gate; needs a real expert account with bookings and a visual check of the row layout. Recorded as PENDING for 02-12 in WINDOWS.md (unrun-verify)."

duration: 23 min
completed: 2026-11-10
status: complete
---

# Phase 2 Plan 15: Client Profile History Amounts Summary

**The expert Client Profile history card now shows each booking's real net earnings through the shared `Money` formatter (`CA$75.00`), gated by status exactly as Android does, with a dash for anything it does not know, replacing the hard-coded `"$0"` on every row.**

## Performance

- **Duration:** 23 min (16:54:24Z to 17:17:33Z; includes the tracer gate round-trip)
- **Started:** 2026-11-10T16:54:24Z
- **Completed:** 2026-11-10T17:17:33Z
- **Tasks:** 2 (Task 1 as planned; Task 2 user-directed at the tracer gate)
- **Files modified:** 7 (3 app, 2 test, 2 evidence records)

## Accomplishments

- `ClientBookingHistory` carries `amountMajor: Double?` and `currency: String?`; the integer `amount` and the only `"$\(amount)"` interpolation in the app target are gone.
- `ClientProfileBookingCard.amountLabel(amountMajor:currency:)` is the one label path: `Money.format(major:currency:) ?? "—"`, dash for nil amount, nil currency or NaN.
- `ClientProfileViewModel.mapBooking` maps `earnings_breakdown.net_amount` (major units) and the breakdown's `currency` into the row for the five Android-gated statuses; every other status, a nil net or a missing breakdown yields nil/nil. The stale "doesn't expose an amount" comment and the EXP-14 deferral comment are both gone.
- Two Swift Testing suites (12 tests, 25 cases including parameterized rows) pin the label, the mapping, the status gate in both directions and the wire field decode.
- Full Debug build succeeds; the warning comparison for this plan's files prints nothing (baseline and after are both empty). Full unit target: 217 tests in 25 suites pass (live smoke suites skipped).

## Task Commits

TDD cycles, one RED and one GREEN each:

1. **Task 1 RED: pin the Client Profile history amount label** - `f2d4610` (test)
2. **Task 1 GREEN: amounts go through the shared formatter** - `293bf58` (fix)
3. **Task 2 RED: pin the net-earnings mapping and status gate** - `953119f` (test)
4. **Task 2 GREEN: history shows real net earnings, as Android does** - `63b743d` (fix)

**Plan metadata:** docs commit follows this SUMMARY.

## TDD Gate Compliance

| Cycle | RED commit | RED evidence | GREEN commit |
|-------|-----------|--------------|--------------|
| Task 1 | `f2d4610` `test(02-15)` | `02-15-tdd-red-evidence-t1.json`, `RED_EVIDENCE_OK` (5 tests, 5 fail; the stub returned `$75`, `$121`, `$1200`, `$0`) | `293bf58` `fix(02-15)` |
| Task 2 | `953119f` `test(02-15)` | `02-15-tdd-red-evidence-t2.json`, `RED_EVIDENCE_OK` (7 tests, 2 fail on the planned assertions, 5 pass as guards) | `63b743d` `fix(02-15)` |

Both RED commits carry a compile-only seam, recorded in their evidence `note`: Task 1 a stub `amountLabel` mirroring the HEAD label, Task 2 the `private` modifier dropped from `mapBooking` with its body untouched. The GREEN commits use the `fix(…)` type because this plan is `type: execute` with `tdd="true"` tasks, matching 02-06. The Task 2 semantic assessment notes the five passing guard rows (dash for gated-out statuses, nil net, missing breakdown; wire decode) pin behavior the GREEN change had to keep; the target row and the shown-statuses row failed on their planned assertions. No REFACTOR commit was needed.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileView.swift` - `ClientBookingHistory.amountMajor` / `.currency` with unit docs.
- `ClickMe2026/Views/Screens/Expert Mode/Client Profile/Subviews/ClientProfileBookingCard.swift` - `amountLabel(amountMajor:currency:)`; the amount `Text` reads it.
- `ClickMe2026/Views/Screens/Expert Mode/Client Profile/ClientProfileViewModel.swift` - `earningsStatuses`, net-earnings mapping in `mapBooking`, CAD preview rows (75.0, 120.5, nil).
- `ClickMe2026Tests/Utils/ClientProfileBookingCardTests.swift` - 5 label rows.
- `ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift` - 7 mapping rows over a `GET /expert/bookings` fixture shaped like `buildSessionMoney`.
- `.planning/phases/02-shared-ios-plumbing/02-15-tdd-red-evidence-t1.json`, `-t2.json` - RED records.

## Android Parity

The user directed the parity change at the tracer gate ("approve and defer, match Android now"). Read-only references: `ClickMe_Android/.../screens/expertmode/clientprofile/ClientHistory.kt` (`AMOUNT_STATUSES`, `ClientHistoryRow.amountText`) and `ExpertDisplay.kt` (`ExpertBookingItem.netEarningsText` -> `Money.formatMajor(net, currency, locale)`).

| Aspect | Android | iOS (this plan) |
|--------|---------|-----------------|
| Source | `session.earningsBreakdown.netAmount` | `session.earningsBreakdown?.netAmount` (same wire field, already decoded by `EarningsBreakdown`) |
| Currency | `breakdown.currency ?: consultationFee.currency` | `breakdown.currency` (non-optional on iOS; the backend always sends it, so no fallback is needed) |
| Status gate | `pending_approval, confirmed, pending_reschedule, in_progress, completed`; else no amount | `ClientProfileViewModel.earningsStatuses`, the same five; `rescheduled` and `unknown` fall outside, as Android's `else` does |
| Nil net / missing breakdown | null (no amount) | nil/nil, card shows `—` |
| Gross as fallback | never | never |
| Formatting | `Money.formatMajor` with the device locale (locale symbols) | `Money.format(major:currency:)`, fixed symbol table, not the device locale. Deliberate: the 02-05 decision stands, so iOS shows `CA$75.00` where Android may show `$75.00` on a Canadian device |

Backend unit check (orchestrator request, confirmed again here): `buildSessionMoney` in `ClickMe2026 Backend/src/controllers/expertBooking.controller.js` L134-155 divides `amount_paid_minor_units` by `10^digits` before sending `consultation_fee.amount`, and `buildEarningsBreakdown` carries `net_amount` in the same major units with an always-present `currency`. Field names `earnings_breakdown.net_amount` and `earnings_breakdown.currency` match `EarningsBreakdown.swift` through `convertFromSnakeCase`; no model change was needed and no explicit `CodingKeys` were added.

Android follow-up (log only, not built here): the Android card has no hard-coded symbol. Its comments in `ClientHistory.kt` L50-51 and `subviews/ClientProfileBookingHistory.kt` L61 say "iOS always shows a stub $0", which this plan makes stale; a comment-only update when Android is next touched. Android's `consultationFee.currency` fallback has no iOS counterpart because `EarningsBreakdown.currency` is non-optional.

## Decisions Made

- Show real net earnings now rather than a dash until Phase 6 (user decision at the tracer gate). This overrides the plan's "Do not map any real amount (EXP-14)" line and the "nil until EXP-14" key link; both were plan constraints the user lifted, not implementation choices.
- Gate by status with Android's exact set, kept as a `Set<BookingStatus>` on the view model so the test rows read it the same way the mapping does.
- Keep the fixed-symbol formatter over device-locale symbols; cross-platform the amount is the same number in the same currency, only the symbol spelling differs, and 02-05 already settled that for iOS.
- Keep the fixture-based decode row as a guard that pins the wire field names, even though it passes at RED; its purpose is to break if the backend contract or the iOS model drifts.

## Deviations from Plan

### User-directed scope change

**1. [User decision at the tracer gate] Map real net earnings with Android's status gate**
- **Found during:** Task 1 tracer gate (checkpoint:human-verify). User response: "approve and defer, match Android now".
- **Issue:** The plan left the history rows at `—` until EXP-14 in Phase 6 ("Do not map any real amount"). The Android port already shows net earnings on this screen, so iOS and Android would have diverged on a live surface.
- **Fix:** Task 2, RED then GREEN: `mapBooking` reads `earnings_breakdown.net_amount` and `currency` for `earningsStatuses`, nil/nil otherwise; the EXP-14 deferral comment is removed. Plan gates that assumed the nil/nil mapping: the key link `via: "nil until EXP-14 maps earnings_breakdown.net_amount and its currency"` no longer describes the code (its grep pattern `amountMajor:` still matches); the Task 1 `<human-check>` wording ("each History row shows —") is superseded by the WINDOWS.md entry wording. No automated gate pinned nil/nil, so none was adjusted.
- **Files modified:** ClientProfileViewModel.swift, ClientProfileHistoryEarningsTests.swift (new), 02-15-tdd-red-evidence-t2.json (new)
- **Verification:** `ClientProfileHistoryEarningsTests` 7 rows pass; full Debug build; no new warnings; 217-test unit target passes.
- **Committed in:** `953119f` (RED), `63b743d` (GREEN)

### Auto-fixed Issues

None.

---

**Total deviations:** 1 user-directed scope change (0 auto-fixed)
**Impact on plan:** Delivers the history half of EXP-14 early. EXP-14 is NOT marked complete; it stays a Phase 6 requirement for any other Client Profile earnings surface. A one-line note was added under the EXP-14 bullet in REQUIREMENTS.md so Phase 6 planning does not redo the rows.

## Issues Encountered

- Task 1 and Task 2 each needed a compile-only RED seam (Swift cannot reference a missing or private symbol without a build failure, which the classifier rejects as `build_failure`). Recorded in both evidence records; the GREEN commits carry the behavior.
- The `02-12-PLAN.md` device checklist (checklist item 6, L216) still describes the Client Profile rows as "— instead of $0 (intentional until EXP-14 in Phase 6)". Not edited here (another plan's artifact); the WINDOWS.md unrun-verify entry for 02-15 carries the replacement wording and names 02-12 as the pending owner. The 02-12 executor should use that wording.

## Deferred Device Check

**PENDING (user: approve and defer).** Recorded in `.planning/WINDOWS.md` as `unrun-verify`, phase 02, owner 02-12 / `02-DEVICE-UAT-CHECKLIST.md`:

> As an expert, open a client's profile from a booking. Confirmed, completed or other gated rows (pending_approval, pending_reschedule, in_progress) show the net earnings as `CA$x.xx`. Cancelled and other non-gated rows show `—`. No row shows `$0` or `CA$0.00` unless the net really is zero. The layout is unchanged.

## Known Stubs

None. Preview rows in `sampleBookingHistory` carry CAD amounts and one nil row on purpose so both card states render in the canvas; live rows are mapped from the feed.

## Threat Flags

None. T-02-33 (repudiation on the earnings label) is mitigated as planned: the label goes through `Money` with an explicit unit and currency, unknown values show a dash, and the status gate keeps unearned money off the screen. No new network, auth, file or schema surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BOOK-10 is complete for Phase 2: every money display site goes through `Money`; the app-wide symbol-interpolation gate is at 0. 02-15 was the last plan declaring BOOK-10, so it releases now.
- Phase 2 remaining: 02-12 (device checklist and PUSH-04). Its BOOK-10 checklist wording for the Client Profile should follow the WINDOWS.md entry, not the plan's L216 text.
- Phase 6 EXP-14: the history rows are done; scope the remaining Client Profile earnings surfaces (relationship summary, totals) rather than the rows.
- Android follow-up: comment-only update in `ClientHistory.kt` and `ClientProfileBookingHistory.kt` ("iOS shows a stub $0" is no longer true).

---
*Phase: 02-shared-ios-plumbing*
*Completed: 2026-11-10*

## Self-Check: PASSED

- 7 key files present on disk
- 4 task commits (f2d4610, 293bf58, 953119f, 63b743d) are ancestors of HEAD
- commits: 4 measured from ledger db6a0ca..63b743d
