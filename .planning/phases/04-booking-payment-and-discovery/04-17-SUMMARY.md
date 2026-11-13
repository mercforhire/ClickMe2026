---
phase: 04-booking-payment-and-discovery
plan: 17
subsystem: ui
tags: [swiftui, explore, pull-to-refresh, cancellation, swift-testing, urlprotocol]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "EXPL-07 Explore load tolerance (plan 04-04) and G-04-3 diagnosis (04-UAT.md)"
provides:
  - "Explore fetch shielded from caller cancellation: load() awaits an unstructured Task running fetchHome(replacingLoadedContent:)"
  - "Loaded Explore sections stay on screen during a refresh, Retry or reappear load"
  - "stateAfterCancelledFetch(current:before:) and interruptedLoadMessage: a cancelled fetch never strands a skeleton"
  - "Nine G-04-3 Swift Testing rows and a held-response test seam (serveHeld, homeRequestCount, homeRequestArrived)"
  - "MockURLProtocol.recordedRequests behind one NSLock"
  - "Device checklist item 1 step 4 (G-04-3 re-test)"
affects: [04-verify-work, EXPL-07 device check, other .refreshable screens]

actuals:
  tokens: 5500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Unstructured Task awaited via .value to shield a fetch from SwiftUI refresh-task cancellation"
    - "Settle a cancelled fetch from a captured prior state, never to idle"
    - "Held-response MockURLProtocol handler (DispatchSemaphore) plus polled request arrival"

key-files:
  created: []
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift
    - ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift
    - ClickMe2026Tests/Support/MockURLProtocol.swift
    - .planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md

key-decisions:
  - "The shield lives in the view model's load(), not the view's .refreshable closure, so every caller (.refreshable, .task, both Retry buttons) is covered and it is unit-testable"
  - "A first load that is cancelled settles as NetworkError's fixed sentence with Retry, not idle, so no skeleton is ever stranded and no new copy is added"
  - "Category change keeps its skeletons via fetchHome(replacingLoadedContent: true)"
  - "MockURLProtocol.recordedRequests locked (option a): computed property over a private requestLog under NSLock; no other test file changed"

patterns-established:
  - "Cancellation is never a section state: restore what the section showed before the fetch"

requirements-completed: [EXPL-07]

coverage:
  - id: D1
    description: "A pull to refresh on Explore finishes its load even when the calling task is cancelled mid-request, from a loaded screen and from a failed one"
    requirement: EXPL-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a refresh whose calling task is cancelled still loads the new feed (G-04-3)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a refresh after a failure whose calling task is cancelled still loads every section (G-04-3)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Loaded sections stay on screen during a refresh; a category change still shows skeletons"
    requirement: EXPL-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#loaded sections stay on screen while a refresh is in flight (G-04-3)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a category change still shows skeletons while the filtered feed loads (G-04-3)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A cancelled fetch settles each section from its prior state and never leaves idle; no raw 'cancelled' text"
    requirement: EXPL-07
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a cancelled reload over loaded data keeps every section loaded (G-04-3)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a cancelled reload after a failure keeps the failure and its Retry (G-04-3)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a cancelled first load shows the generic failure, not a skeleton (G-04-3)"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift#a cancelled fetch settles each section from the state before it (G-04-3)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Pull to refresh on a real iPhone: ten pulls end loaded, airplane mode shows the offline sentence with Retry, and the pull after it loads (UAT test 3 re-test)"
    requirement: EXPL-07
    verification: []
    human_judgment: true
    rationale: "The diagnosis is from code, not a debugger. Only a real device confirms the refresh no longer ends on skeletons (checklist item 1 step 4, /gsd-verify-work 04)."

duration: 16min
completed: 2026-11-13
status: complete
plan_head_before: fdfe2c9785a320b862f2c8ed038d86266f3058bf
plan_head_after: a06dd8996e970d7324dc79ec07adb38e16d41048
---

# Phase 4 Plan 17: Explore pull-to-refresh fix (G-04-3) Summary

**Explore's fetch now runs in an unstructured Task that `load()` awaits, loaded sections stay on screen during a refresh, and a cancelled fetch restores each section's prior state instead of stranding a skeleton.**

## Performance

- **Duration:** ~16 min (start time not recorded at launch; estimated from the previous plan's STATE timestamp)
- **Completed:** 2026-11-13T04:31Z
- **Tasks:** 3
- **Files modified:** 5 (plus this SUMMARY and planning state)

## Accomplishments

- G-04-3 is fixed in code. The mechanism reproduced in unit tests: cancelling the calling task mid-request moved every section to `.idle` (a skeleton with nothing loading). `load()` now awaits `Task { fetchHome(...) }.value`, so SwiftUI cancelling `.refreshable` or `.task` never reaches URLSession.
- Sections that are `.loaded` publish no state change at the start of a refresh, so the ScrollView owning `.refreshable` keeps its content. Idle and failed sections still show skeletons while loading.
- `stateAfterCancelledFetch(current:before:)` settles a cancelled fetch: loaded stays loaded, a failure keeps its Retry, a first load shows `interruptedLoadMessage` (NetworkError's fixed sentence, no new copy), a section another fetch settled is left alone.
- EXPL-07 failure branch is byte-for-byte unchanged (`featuredTopics = []`, three `.failed(msg)`); all 18 pre-existing rows pass with no assertion changed.
- Device checklist item 1 gets step 4, an Expected bullet and the closes-table note.

## Baseline and RED evidence

- **Baseline at a347ede-equivalent files (before any edit, /tmp/04-17-before.log):** `Test run with 18 tests in 1 suite passed`; 0 `warning:` lines naming ExploreClientViewModel.swift, ExploreClientView.swift or ClientHomeFeedTests.swift.
- **RED run 1 (/tmp/04-17-red1.log, 22 tests, 13 issues):** (a), (a2), (b) failed; (c) passed.
  - (a): `Expectation failed: (viewModel.categoriesState → .idle) == .loaded` (also experts and featured idle, and `(viewModel.featuredTopics.map(\.title) → ["First"]) == ["Second"]`).
  - (a2): `Expectation failed: (viewModel.categoriesState → .idle) == .loaded`, `(viewModel.featuredTopics.map(\.title) → []) == ["Back"]`, `(viewModel.categories.count → 0) == 1`, `(viewModel.experts.count → 0) == 1`.
  - (b): `Expectation failed: (viewModel.categoriesState → .loading) == .loaded` (same for experts and featured topics).
  - (c): `✔ Test "a category change still shows skeletons while the filtered feed loads (G-04-3)" passed`.
- **RED run 2 after Task 1 (/tmp/04-17-red2.log, 26 tests, 6 issues):** (e) and (g) failed; (d) and (f) passed.
  - (e): `Expectation failed: (viewModel.categoriesState → .idle) == (failed → .failed("Something went wrong. Please try again."))` (same for experts and featured).
  - (g): the same three expectations, `.idle` instead of the generic failure.
  - Row (h) was added with the fix, because it calls the new function.
- Neither failing state was committed.

## recordedRequests lock (checker option a)

`MockURLProtocol.recordedRequests` is now a static computed property (getter and setter under one `NSLock`) over a private `nonisolated(unsafe)` backing array `requestLog`. `reset()` clears it under the lock and `startLoading()` appends under the lock in one `withLock` call. No other test file changed to keep compiling (the 11 readers and the one `= []` assignment compile unchanged).

## Accepted cases, in user-visible terms

A filter fetch cancelled by the system shows the previous experts with the new chip highlighted until the next load. When two loads overlap, the one that finishes last decides what Explore shows, even if it started first.

## Test counts

- ClientHomeFeedTests after Task 1: 22 tests in 1 suite passed (18 + 4).
- After Task 2: 27 tests in 1 suite passed (18 + 9).
- Full unit target (/tmp/04-17-full.log): `Test run with 650 tests in 65 suites passed` (04-15 ended at 641 in 65 suites; +9 new).

## Task Commits

1. **Task 1: tracer, refresh survives caller cancellation, loaded sections stay visible, recordedRequests lock** - `1e9ddde` (fix)
2. **Task 2: cancelled fetch restores prior state** - `cc50bb9` (fix)
3. **Task 3: device checklist step 4** - `a06dd89` (docs)

**Plan metadata:** the `docs(04-17)` commit that adds this SUMMARY.

## Build result

`xcodebuild build` (Debug, iPhone 17) after touching the three Swift files: BUILD SUCCEEDED, log mentions ExploreClientViewModel.swift (3 times), 0 warnings naming ExploreClientViewModel.swift or ExploreClientView.swift. The full-suite log mentions ClientHomeFeedTests.swift (3 times) with 0 warnings naming it, MockURLProtocol.swift or any Explore file.

## Files Created/Modified

- `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift` - `load()` shield, `fetchHome(replacingLoadedContent:)`, `stateAfterCancelledFetch`, `interruptedLoadMessage`, category path keeps skeletons
- `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift` - one comment at `.refreshable`, no code change
- `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift` - Refresh (G-04-3) section, three helpers, nine rows
- `ClickMe2026Tests/Support/MockURLProtocol.swift` - locked `recordedRequests` (test support only)
- `.planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md` - item 1 step 4, Expected bullet, closes-table row

## Decisions Made

- Shield in `load()` rather than the view: covers `.refreshable`, `.task` and both Retry buttons and is unit-testable.
- First-load cancellation shows the generic failure with Retry rather than idle, to avoid a stranded skeleton and retry loops.
- Category change keeps skeletons because the loaded experts no longer match the chip.

## Deviations from Plan

None - plan executed exactly as written. The one deferral that the plan itself allowed: the `PLAN_START_TIME` was not recorded at launch, so duration is an estimate.

## Issues Encountered

None. `ClickMe2026/Localizable.xcstrings` and other unrelated working-tree changes were left unstaged throughout.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or schema; the `/client/home` request is unchanged.

## Status of G-04-3 and EXPL-07

G-04-3 is fixed in code, with the device re-test pending (UAT test 3, checklist item 1 step 4, `/gsd-verify-work 04`). It is not closed. The diagnosis came from code and was reproduced by unit tests, not confirmed under a debugger. EXPL-07 stays Pending in REQUIREMENTS.md until checklist item 1 passes on a device.

## Out-of-scope findings for a later todo

- **17 other `.refreshable` screens** (ExpertProfileSettings, IncomingRequests, UpcomingBookings, Payouts, ExpertDashboard, ExpertTaxProfile, Transactions, TopicsSetup, Chatting, AvailabilitySettings, ClientProfile, ChatConversations, ReadyToStartCall, NotificationsList, ClientTransactions, SearchExpert, MyBookings) flip their load state to `.loading` on reload and do not handle a cancelled refresh. That is the same shape as Explore's root cause. On those screens a cancelled refresh more likely ends in a failed state that shows the system's "cancelled" text than in a stranded skeleton (not checked on a device). Favorites (`FavoritesViewModel.refresh()`) and ExpertReviews (`ExpertReviewsViewModel.refresh()`) already keep their rows visible, so they are the pattern to copy. A shared fix belongs in its own todo or phase.
- **Completion-order race:** two overlapping Explore fetches still write in completion order, so the last to finish wins. MyBookings and UpcomingBookings guard against this with `ReloadGeneration`; Explore never has. `.task` loads now finish after the screen disappears (one read-only GET into the `@StateObject`, accepted as T-04-52).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for the device re-test of UAT test 3. No backend or Android change is needed.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-13*

## Self-Check: PASSED

- Files modified exist on disk: the four Swift files and the checklist (verified by the plan's structural greps).
- Commits `1e9ddde`, `cc50bb9`, `a06dd89` are ancestors of HEAD.
