---
phase: 04-booking-payment-and-discovery
plan: 11
subsystem: ui
tags: [swiftui, reviews, pagination, flow-layout, search, swift-testing]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "PagedList<Item, Key> from plan 04-06 (dedupe by server id, last-3 trigger, has_more stop, stale flag)"
provides:
  - "The full reviews list pages GET /experts/:id/reviews 20 at a time with infinite scroll, a spinner footer, a failed-page footer with Retry, and pull-to-refresh that keeps the rows on failure"
  - "ExpertReview.serverId / pagingKey so one review on two adjacent pages shows once"
  - "Search result tag pills show their full text: at most 3 pills in TopicsSetupFlowLayout(8, 4), no one-line limit, 12 pt continuous rounded rectangle"
  - "TopicsSetupFlowLayout pure static helpers (frames, fittingSize, proposal) and a wrap-inside-the-pill rule for subviews wider than the row"
affects: [04-14, reviews, search, favorites, expert-topic-setup]

actuals:
  tokens: 10500
  tasks: 2
  commits: 2
plan_head_before: a90ef74db954f4e66a467c1ae6240ac910dd1c4a
plan_head_after: de76ca46bb0acc16734d730d59983e06c00f4c94

tech-stack:
  added: []
  patterns:
    - "A second consumer of PagedList: the view model owns the requests and a generation counter, the value type owns the paging rules"
    - "Layout math extracted into pure static helpers so a shared layout's backward compatibility can be unit tested against a copy of the old algorithm"

key-files:
  created:
    - ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift
    - ClickMe2026Tests/Utils/TopicsSetupFlowLayoutTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift
    - ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift
    - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupFlowLayout.swift

key-decisions:
  - "Reviews dedupe on ExpertReview.pagingKey (serverId ?? id); ExpertReview.id is a new UUID per map and could never match across pages"
  - "The header rating and count keep coming from summary on page 1; the pagination envelope has no total (RESEARCH Pitfall 3)"
  - "A failed pull-to-refresh on Reviews raises no alert (public read-only data); the rows stay and the control ends"
  - "TopicsSetupFlowLayout only changes behavior for a subview whose ideal width exceeds the row; every subview that fits is still measured and placed with .unspecified"

patterns-established:
  - "Later-page failures keep rows and surface a footer; only page 1 uses the full-screen error view (same as Favorites)"
  - "Shared layout fixes ship with a test that replays the previous algorithm over fixed inputs"

requirements-completed: [EXPL-06, EXPL-04]

coverage:
  - id: D1
    description: "The full reviews list loads pages of 20, fetches the next page when one of the last 3 rows appears (never while loading), stops on has_more false, and shows a review that arrives on two adjacent pages once, in server order"
    requirement: EXPL-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#25 reviews arrive as 20 then 5: two requests with limit 20, 25 reviews, no third request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#exactly 20 reviews with has_more false makes one request, even after a trigger on the last row"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#a review returned on page 1 and again on page 2 appears once, in its page-1 position"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#reviews keep the server order and appended pages follow page order"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#zero reviews loads an empty list and makes no second request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#the header rating and count come from summary, not from the loaded rows"
        status: pass
    human_judgment: false
  - id: D2
    description: "A failed later page keeps the loaded reviews and offers Retry; a 500 on a later page ends the list; pull-to-refresh replaces the reviews on success and keeps them on failure"
    requirement: EXPL-06
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#a failed page 2 keeps the 20 reviews, shows the page error, and Retry appends the page"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#a 500 on page 2 ends the list: reviews stay, no page error, no further request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#refresh replaces the reviews with a new page 1 when it succeeds"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift#a failed refresh keeps the reviews"
        status: pass
    human_judgment: true
    rationale: "Footer layout, the 44 pt Retry hit area and the pull-to-refresh feel need a real iPhone (UAT EXPL-06, D-07); logged in WINDOWS.md as unrun-verify #32"
  - id: D3
    description: "TopicsSetupFlowLayout places subviews that fit exactly as before (Favorites cards, expert topic setup) and gives a subview wider than the row the row width so it starts its own row"
    requirement: EXPL-04
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicsSetupFlowLayoutTests.swift#subviews that all fit get the same frames and size as the layout had before"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicsSetupFlowLayoutTests.swift#a subview wider than the row is proposed the row width; one that fits is not"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Utils/TopicsSetupFlowLayoutTests.swift#an overflowing pill re-measured at the row width starts its own row"
        status: pass
    human_judgment: false
  - id: D4
    description: "Search result tag pills show their full text: at most 3, in a wrapping layout with 8 and 4 gaps, no ellipsis, on a 12 pt continuous rounded rectangle; no tags renders no row"
    requirement: EXPL-04
    verification:
      - kind: other
        ref: "grep: lineLimit(1) count 0, TopicsSetupFlowLayout(horizontalSpacing: 8, verticalSpacing: 4) count 1, tags.prefix(3) and tags.isEmpty kept, RoundedRectangle(cornerRadius: 12, style: .continuous) count 2"
        status: pass
    human_judgment: true
    rationale: "A long multi-word or non-Latin tag wrapping inside its pill at the largest Dynamic Type size is a visual backstop (UI-SPEC L5); logged in WINDOWS.md as unrun-verify #33, with a 'Long tags' preview added"

duration: 13min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 11: Reviews Paging and Search Tag Pills Summary

**The full reviews list now pages `GET /experts/:id/reviews` 20 at a time on the shared `PagedList` (infinite scroll, footer Retry, refresh that keeps rows on failure), and search tag pills wrap in `TopicsSetupFlowLayout` with their full text, backed by pure layout helpers whose fitting-subview behavior is tested against the old algorithm.**

## Performance

- **Duration:** 13 min (start time estimated; not recorded at launch)
- **Started:** 2026-11-12T05:38:00Z
- **Completed:** 2026-11-12T05:51:00Z
- **Tasks:** 2
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments
- Reviews requested page 1 with the endpoint defaults before this plan, so an expert with more than 20 reviews showed only the first page. `ExpertReviewsViewModel` now holds a `PagedList<ExpertReview, UUID>`, sends `limit=20` explicitly (server default is 10), appends pages as one of the last 3 rows appears, and stops on `has_more` false.
- A later-page failure keeps every loaded review and shows "Couldn't load more reviews" with a 44 pt Retry; a 500 on a later page is read as the end of the list; while a page loads the footer shows a centered accent spinner with 16 pt vertical padding. Page 1 failures still use the existing full-screen error view and its Retry (`reload()`).
- Pull-to-refresh now calls `refresh()`: it restarts at page 1, replaces the reviews only on success, and leaves them untouched on failure.
- The header rating and count still come from `summary`, not from the loaded rows.
- Search pills: the one-line limit is gone, the `HStack(spacing: 6)` is replaced by `TopicsSetupFlowLayout(horizontalSpacing: 8, verticalSpacing: 4)` over the same `prefix(3)`, and the capsule is a 12 pt continuous rounded rectangle with the same fill, stroke and 8 by 4 padding. A "Long tags" preview shows a 60-plus character tag and a Chinese tag.
- `TopicsSetupFlowLayout` gained `proposal(forIdealWidth:maxWidth:)`, `frames(for:maxWidth:horizontalSpacing:verticalSpacing:)` and `fittingSize(of:)`, and both `sizeThatFits` and `placeSubviews` use them. A subview wider than the row is proposed the row width (so its text wraps inside the pill); a subview that fits keeps `.unspecified` for measuring and placing, as before.
- 12 reviews-paging tests and 8 flow-layout tests (10 argument cases against a test-local copy of the previous loops) pass.

## Task Commits

1. **Task 1: Tracer, the full reviews list loads past 20 reviews** - `476c250` (feat)
2. **Task 2: Search tag pills show their full text** - `de76ca4` (fix)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified
- `ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift` - `list`, `pageSize`, `loadNextPageIfNeeded`, `retryNextPage`, `refresh`, generation counter, `serverId` mapping; the private `message(for:)` is replaced by `userMessage`
- `ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift` - `ExpertReview.serverId` / `pagingKey`, `LazyVStack` rows with a row-appear trigger, spinner and error footer, `.refreshable` calls `refresh()`
- `ClickMe2026/Views/Screens/Client Mode/Search/Subviews/SearchExpertCard.swift` - wrapping pills, 12 pt shape, "Long tags" preview
- `ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupFlowLayout.swift` - pure helpers, wrap-inside rule for overflowing subviews, type doc
- `ClickMe2026Tests/Network/Discovery/ExpertReviewsViewModelPagingTests.swift` - stubbed paging, duplicate, order, failure and refresh suite
- `ClickMe2026Tests/Utils/TopicsSetupFlowLayoutTests.swift` - fixed rows, HEAD-comparison rows, overflow rows

## Decisions Made
- Dedupe key is `ExpertReview.pagingKey` (`serverId ?? id`), mirroring `FavoriteExpert.pagingKey` from 04-06.
- A failed refresh on Reviews shows no alert, as the plan's assumptions say; there is no `apiError` on this view model.
- Both `sizeThatFits` and `placeSubviews` call `proposal(forIdealWidth:maxWidth:)` directly instead of sharing one measuring helper, so the plan's check ("called from both") holds and each method reads on its own.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rows in an eager stack would page through the whole list on load**
- **Found during:** Task 1 (ExpertReviewsView)
- **Issue:** The reviews were in a non-lazy `VStack`, so every row's `.onAppear` fires at once and the last-3 trigger would chain page after page until `has_more` was false. Same defect plan 04-06 hit in Favorites.
- **Fix:** The review rows and the footer sit in a `LazyVStack(spacing: 14)` so `.onAppear` means "scrolled into view".
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsView.swift`
- **Verification:** Build clean; the early-row trigger rule is covered by "a review early in the list does not start the next page"; scroll behavior is in the device check.
- **Committed in:** `476c250`

**2. [Rule 2 - Missing critical] Race guards the plan did not name**
- **Found during:** Task 1 (ExpertReviewsViewModel)
- **Issue:** A pull-to-refresh during an in-flight next-page request would append a page from the old offsets onto the new list, and two refreshes could run at once (T-04-27 loop and duplicate-request concern).
- **Fix:** Same pattern as `FavoritesViewModel`: a `generation` counter drops any next-page response that started before a restart, `refresh()` clears the in-flight marker, and an `isRefreshing` flag blocks overlapping restarts.
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift`
- **Verification:** Existing paging and refresh tests pass; the race itself has no dedicated test (timing-dependent with the URLProtocol stub), as with Favorites.
- **Committed in:** `476c250`

**3. [Rule 3 - Blocking] Preview seam initializer touched `list` before `state` was set**
- **Found during:** Task 1 (first test build)
- **Issue:** `Variable 'self.state' used before being initialized`, because `list.replace(...)` ran before `state = .loaded` in the preview init (Favorites avoids this with a default value on `state`).
- **Fix:** Assign `state` first, then install the rows.
- **Files modified:** `ClickMe2026/Views/Screens/Client Mode/Reviews/ExpertReviewsViewModel.swift`
- **Verification:** Tests build and pass.
- **Committed in:** `476c250`

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical, 1 blocking)
**Impact on plan:** All three are needed for the plan's own truths to hold. No file outside the plan's list was touched.

## Issues Encountered
- The first test file for the flow layout aliased `TopicsSetupFlowLayout` as `Layout`, which collides with SwiftUI's `Layout` protocol (`type 'any Layout' has no member 'frames'`); renamed the alias to `Flow`. The fixed argument list also needed `nonisolated` to be read from the `@Test` macro under the project's MainActor default isolation. No change to the production helpers was needed (no `nonisolated` on them).
- `gsd_run` is not on the shell `PATH` for the executor; `/Users/LeonChen/.claude/gsd-core/bin/gsd_run` was called by full path. The commit guard's `git.base-branch` lookup was therefore unavailable and the guard relied on `git.allow_default_branch_commits: true` in `.planning/config.json`, which is set.

## Known Stubs
None.

## Threat Flags
None. No new endpoints, auth paths or schema; the only network call is the existing `GET /experts/:id/reviews`, now with explicit `page` and `limit=20`. T-04-27 is mitigated by the `PagedList` one-at-a-time guard, the `has_more` stop and 500-as-end.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Device checks for EXPL-06 / D-07 and EXPL-04 / L5 are logged as `unrun-verify` #32 and #33 in `.planning/WINDOWS.md` for plan 04-14's UAT checklist. Include a check that Favorites chips and expert topic setup chips look unchanged.
- Android: none logged for EXPL-04 or EXPL-06 (Android already uses a `FlowRow` for these pills).

## Self-Check: PASSED

- Created files present: `ExpertReviewsViewModelPagingTests.swift`, `TopicsSetupFlowLayoutTests.swift`, this SUMMARY.
- Commits `476c250` and `de76ca4` are ancestors of HEAD; `git rev-list --count a90ef74..HEAD` was 2 before this SUMMARY commit.
- Acceptance criteria re-run: `PagedList<ExpertReview, UUID>` count 1, `var serverId: UUID?` count 1, `RoundedRectangle(cornerRadius: 12, style: .continuous)` count 2, `struct TopicsSetupFlowLayoutTests` count 1; all automated checks for both tasks pass.
- Plan verification: `ExpertReviewsViewModelPagingTests` (12 tests) and `TopicsSetupFlowLayoutTests` (8 tests) pass; Debug build succeeds with 0 warnings in the four app files (baseline 0).

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
