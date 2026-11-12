---
phase: 04-booking-payment-and-discovery
plan: 06
subsystem: ui
tags: [swiftui, favorites, pagination, infinite-scroll, pull-to-refresh, swift-testing]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "The heart reads is_favorite (plan 04-05), so the Pro Tip copy now matches the control"
provides:
  - "PagedList<Item, Key>: shared paged-list value type (dedupe by server id, last-3 trigger, has_more stop, stale flag), reused by Reviews in 04-11"
  - "Favorites pages GET /client/favorites in pages of 20 with infinite scroll, pull-to-refresh and a later-page failure footer with Retry"
  - "FavoritesViewModel.loadNextPageIfNeeded(currentItem:), retryNextPage(), refresh(), and reload-on-next-trigger after an unfavorite"
  - "Pro Tip copy names the heart icon"
affects: [04-10, 04-11, 04-12, favorites, reviews]

actuals:
  tokens: 12900
  tasks: 2
  commits: 2
plan_head_before: a0220aadc2b8b046cab1f47423c363ef9a1438cb
plan_head_after: f75a31c1a1fdc074ebe6d3b650a3b0fb5dde9027

tech-stack:
  added: []
  patterns:
    - "Paging state in a value type owned by the view model; the view model only does I/O and calls list mutations"
    - "Generation counter on a view model so a response from before a restart at page 1 is dropped"
    - "Stale flag plus reload-on-next-trigger instead of offset arithmetic after a row leaves a paged list"

key-files:
  created:
    - ClickMe2026/Utils/PagedList.swift
    - ClickMe2026Tests/Utils/PagedListTests.swift
    - ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift
    - ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift
    - ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesProTipCard.swift

key-decisions:
  - "Dedupe by FavoriteExpert.pagingKey (expertId, falling back to id for preview rows); id is regenerated on every map"
  - "UI-SPEC deviation, recorded: the favorites envelope has no total, so 'stop at the server total' and 'lower the known total by one' are has_more plus the stale flag"
  - "An empty page always ends the list even if the server still says has_more, so a misbehaving server cannot make the client loop"
  - "After a failed later page the footer Retry is the only way forward; scrolling back over the last rows does not re-fire the request"
  - "Unfavorite while more pages remain marks the list stale; the next paging trigger restarts at page 1 (RESEARCH Open Question 4)"

patterns-established:
  - "PagedList owns the paging rules; view models own the requests"
  - "Later-page failures keep rows and surface a footer; only page 1 uses the full-screen error view"

requirements-completed: [EXPL-05]

coverage:
  - id: D1
    description: "Favorites loads pages of 20, fetches the next page when one of the last 3 rows appears (never while loading), stops on has_more false, and shows an expert on two adjacent pages once"
    requirement: EXPL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#25 favorites arrive as 20 then 5: two requests with limit 20, 25 rows, no third request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#exactly 20 favorites with has_more false makes one request, even after a trigger on the last row"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#an expert returned on page 1 and again on page 2 appears once"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/PagedListTests.swift#shouldLoadMore is true only for the last 3 indices"
        status: pass
    human_judgment: false
  - id: D2
    description: "A failed later page keeps every row and shows the footer error with Retry; a 500 on a later page ends the list; a failed refresh keeps the rows and raises the existing alert"
    requirement: EXPL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#a failed page 2 keeps the 20 rows, shows the page error, and Retry appends the page"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#a 500 on page 2 ends the list: rows stay, no page error, no further request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#a failed refresh keeps the rows and sets the alert text"
        status: pass
    human_judgment: true
    rationale: "Footer layout, the 44 pt Retry hit area and pull-to-refresh feel need a real iPhone (UAT EXPL-05, D-07); logged in WINDOWS.md as unrun-verify"
  - id: D3
    description: "After a successful unfavorite with more pages remaining, the next paging trigger reloads page 1; a failed unfavorite restores the row at its index; with every page loaded no reload happens"
    requirement: EXPL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#after a successful unfavorite with more pages, the next trigger reloads page 1, not page 2"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#a failed unfavorite puts the row back at its index and does not mark the list stale"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift#an unfavorite with every page loaded needs no reload"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Pro Tip reads 'Tap the heart icon on any expert's profile to add them to this list instantly.'"
    requirement: EXPL-05
    verification:
      - kind: other
        ref: "grep -c 'Tap the heart icon' FavoritesProTipCard.swift returns 1 and grep -c 'star icon' returns 0"
        status: pass
    human_judgment: true
    rationale: "The tip only shows on the empty state, so its on-screen copy needs a device look; logged in WINDOWS.md as unrun-verify"

duration: 7min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 06: Favorites Paging Summary

**Favorites now pages `GET /client/favorites` 20 at a time with infinite scroll, pull-to-refresh, a footer Retry for a failed later page, reload-from-page-1 after an unfavorite, and a Pro Tip that names the heart, all built on one shared `PagedList` type that Reviews will reuse.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-12T05:04:35Z
- **Completed:** 2026-11-12T05:11:26Z
- **Tasks:** 2
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments
- `PagedList<Item, Key>` holds every paging rule (first-occurrence dedupe by server id, last-3 trigger, `has_more` stop, empty page ends the list, remove/insert for optimistic rollback, stale flag) with no network code, covered by 18 pure tests.
- Favorites requests page 1 with `limit=20` and appends further pages as the last 3 rows scroll into view. Before this, only the default first page was ever fetched, so a client with more than 20 favorites could not reach the rest.
- A failed later page keeps every loaded row and shows "Couldn't load more favorites" with a 44 pt Retry; a 500 on a page after the first is read as the end of the list; page 1 failures still use the full-screen error view.
- Pull-to-refresh restarts at page 1 and replaces the rows only on success; a failed refresh keeps the rows and shows the existing "Couldn't update favorites" alert with `Error.userMessage`.
- After an unfavorite while more pages remain, the next paging trigger restarts at page 1, so offset paging never skips the row that moved up. The private `message(for:)` helper is gone in favor of `userMessage`.
- 15 Swift Testing cases in `FavoritesViewModelPagingTests` stub the endpoint and assert the `page` and `limit` query items of every request.

## Task Commits

1. **Task 1: Tracer, Favorites shows every favorite, page by page** - `79da6e0` (feat)
2. **Task 2: Later-page failure footer, pull-to-refresh, unfavorite reload, and the heart Pro Tip** - `f75a31c` (feat)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified
- `ClickMe2026/Utils/PagedList.swift` - shared paged-list value type
- `ClickMe2026Tests/Utils/PagedListTests.swift` - pure paging rules (18 tests)
- `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift` - `list`, `loadNextPageIfNeeded`, `retryNextPage`, `refresh`, stale reload, rollback on `PagedList`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift` - `FavoriteExpert.pagingKey`, wires paging, retry and refresh into the list
- `ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift` - `LazyVStack`, row-appear trigger, spinner and error footers, `.refreshable`
- `ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesProTipCard.swift` - heart copy
- `ClickMe2026Tests/Network/Discovery/FavoritesViewModelPagingTests.swift` - stubbed paging, failure, refresh and unfavorite suite (15 tests)

## Decisions Made
- Dedupe key is `FavoriteExpert.pagingKey` (`expertId ?? id`); `FavoriteExpert.id` is a new UUID on every map and could never match across pages.
- The favorites envelope has no total (RESEARCH Pitfall 3), so UI-SPEC's "stop at the server's total" and "lower the known total by one" are implemented as `has_more` plus the stale flag. Recorded as a UI-SPEC deviation, as the plan asked.
- An empty page forces `hasMore` false whatever the server says, so a server answering `has_more: true` with no rows cannot loop the client (T-04-17).
- Once a later page has failed, scrolling over the last rows does not re-fire the request; the footer Retry is the only way forward. This keeps a flaky connection from hammering the endpoint on every scroll.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rows in an eager VStack would page through the whole list on load**
- **Found during:** Task 1 (FavoritesPopulatedList)
- **Issue:** The existing rows sit in a non-lazy `VStack` inside a `ScrollView`, so every row's `.onAppear` fires immediately. The "last 3 rows" trigger would fire on load and chain page after page until `has_more` was false.
- **Fix:** Changed the rows container to `LazyVStack(spacing: 14)` so `.onAppear` means "scrolled into view".
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Favorites/Subviews/FavoritesPopulatedList.swift`
- **Verification:** Build clean; trigger semantics covered by the "a row early in the list does not start the next page" test; scroll behavior is in the device check.
- **Committed in:** `79da6e0`

**2. [Rule 2 - Missing critical] Race guards the plan did not name**
- **Found during:** Tasks 1 and 2 (FavoritesViewModel)
- **Issue:** A pull-to-refresh (or a stale reload) during an in-flight next-page request would append a page from the old offsets onto the new list, and two refreshes could run at once.
- **Fix:** A `generation` counter drops any next-page response that started before a restart, `refresh()` clears the in-flight marker for the dropped request, and an `isRefreshing` flag blocks overlapping restarts. A cancelled pull gesture (`CancellationError` or `URLError.cancelled`) is not reported as a failed refresh.
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift`
- **Verification:** Existing paging, refresh and unfavorite tests pass; the race itself has no dedicated test (timing-dependent with the URLProtocol stub).
- **Committed in:** `79da6e0`, `f75a31c`

**3. [Rule 3 - Blocking] `removeFavorite(_:)` now returns its Task**
- **Found during:** Task 2 (unfavorite tests)
- **Issue:** The unfavorite round trip ran in an unstructured `Task` the tests could not await, so the "next trigger reloads page 1" row had nothing to wait on.
- **Fix:** `removeFavorite(_:)` is `@discardableResult` and returns the `Task<Void, Never>`; the view ignores it, so the call site is unchanged.
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift`
- **Verification:** `unfavoriteReloadsFromPageOne`, `failedUnfavoriteRollsBack` and `unfavoriteWithEverythingLoaded` await it and pass.
- **Committed in:** `f75a31c`

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical, 1 blocking)
**Impact on plan:** All three are needed for the plan's own truths to hold (no repeated or skipped rows, one request at a time). No scope creep; no file outside the plan's list was touched.

## Issues Encountered
- `#require(list.remove(key:))` does not compile because the macro treats the mutating call as acting on an immutable value; the tests call it first and `#require` the result.
- The Task 1 verify is two separate `xcodebuild test` runs in the plan; they were run as one combined invocation for Task 1 (25 tests passed) and as the plan's exact commands for Task 2.

## Known Stubs
None.

## Threat Flags
None. No new endpoints, auth paths or schema; the only network call is the existing `GET /client/favorites`, now with an explicit `page` and `limit=20`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `PagedList` is ready for the Reviews list in plan 04-11.
- Plans 04-10 (empty-state buttons) and 04-12 (profile heart seed) edit `FavoritesView.swift` after this plan and will find `FavoritesPopulatedList` already taking the paging closures.
- Device check for EXPL-05 / D-07 / D-09 logged as `unrun-verify` #27 in `.planning/WINDOWS.md` for plan 04-14's UAT checklist.
- Android follow-up (logged, not built): Android loads favorites with `limit=100` and no paging; check Favorites paging and the two empty-state buttons there.

## Self-Check: PASSED

- Created files present: `PagedList.swift`, `PagedListTests.swift`, `FavoritesViewModelPagingTests.swift`, this SUMMARY.
- Commits `79da6e0` and `f75a31c` are ancestors of HEAD.
- Acceptance criteria re-run: `struct PagedList` count 1, `var pagingKey: UUID` count 1, `func retryNextPage() async` count 1, `func refresh() async` count 1, all three automated checks per task pass.
- Plan verification: `PagedListTests` and `FavoritesViewModelPagingTests` pass (33 tests, 2 suites); Debug build succeeds with 0 warnings in the five app files (baseline 0).

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
