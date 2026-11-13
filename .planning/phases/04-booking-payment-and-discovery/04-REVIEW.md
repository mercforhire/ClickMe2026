---
phase: 04-booking-payment-and-discovery
reviewed: 2026-11-12T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift
  - ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift
  - ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift
  - ClickMe2026Tests/Support/MockURLProtocol.swift
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 04: Code Review Report (incremental, plan 04-17 / G-04-3)

**Reviewed:** 2026-11-12
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Scope is the diff `e6c7488..HEAD` for the Explore pull-to-refresh fix, read against the full files.

The core change is sound. `load()` awaits `Task { await self.fetchHome(...) }.value`. The inner `Task` inherits `@MainActor` isolation but not the caller's cancellation, so cancelling `.refreshable` or `.task` no longer reaches `URLSession`. Loaded sections stay `.loaded` during a refresh, so the spinner no longer collapses the layout. The new tests discriminate: remove the shield and the "Second" and "Back" assertions fail. `MockURLProtocol.recordedRequests` is now lock-guarded.

No blockers. The remaining issues are:
- **Overlapping fetches are unguarded.** The shield removed the only mechanism that implicitly bounded them.
- **The cancellation settle logic breaks its own documented invariant.** On the category-change path it can restore the wrong content.
- **The mock and tests have minor reliability gaps.**

## Warnings

### WR-01: Overlapping `/client/home` fetches race, and the last response to land wins regardless of filter

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:81-117, 264-270`
**Issue:** Every `load()` or `reload()` call now runs to completion in an uncancellable task. Nothing coalesces or orders them. Before this change a new refresh, a `.task` re-fire or a disappear cancelled the stale request. Now each call becomes an independent fetch that writes `categories`, `experts` and `featuredTopics` on completion.

Concrete bad interleaving:
1. The user pulls to refresh with no filter. Sections stay `.loaded`, so the UI looks idle.
2. The user taps a category chip. `applySelectedCategories` sets `selectedCategorySlugs = ["technology"]` and starts a filtered fetch.
3. The filtered response arrives first and sets `.loaded`. The slower unfiltered refresh then lands and overwrites `experts` and `categories` with unfiltered data.
4. `syncCategorySelection()` still highlights the chip, so the screen shows a filter that is not applied.

The same applies to chip A followed quickly by chip B. That ordering hazard existed before, because `applySelectedCategories` was already an uncancelled `Task`. The refresh path is now exposed too, since it used to be cancelled out from under the user. Rapid tab switching also re-fires `.task { load() }`, stacking fetches, and each one also awaits `loadTodaysSessions()`.

**Fix:** Track the in-flight work and discard stale results.
```swift
private var fetchGeneration = 0
private var inFlight: Task<Void, Never>?

func load() async {
    if let inFlight { await inFlight.value; return }       // coalesce same-filter loads
    let task = Task { await self.fetchHome(replacingLoadedContent: false) }
    inFlight = task
    await task.value
    inFlight = nil                                          // only if still this task
}

// in fetchHome: capture `fetchGeneration += 1; let gen = fetchGeneration` at the start,
// and apply the response (and the cancel settle) only if `gen == fetchGeneration`.
// applySelectedCategories bumps the generation so older fetches become no-ops.
```

### WR-02: A cancelled category-change fetch restores `.loaded` with the previous filter's experts

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:264-270, 340-350`
**Issue:** The category-change path calls `fetchHome(replacingLoadedContent: true)`. It deliberately shows skeletons because the loaded experts no longer match the filter. `stateAfterCancelledFetch` ignores that distinction. For `before == .loaded` it returns `.loaded`, relying on "the content arrays were never cleared". On this path the arrays do hold the old filter's data. If `URLError.cancelled` ever hits the filtered request, the screen settles on `.loaded` with unfiltered experts, `selectedCategorySlugs` and the chip highlight set to the new filter, and no Retry. That is the silent wrong-data state the `replacingLoadedContent: true` flag exists to avoid. No test covers it. The new tests only cancel `reload()`.

**Fix:** Pass the flag into the settle step. When `replacingLoadedContent` is true, settle to `.failed(interruptedLoadMessage)`, which gives a Retry. Alternatively, revert `selectedCategorySlugs` to the previous set and restore `.loaded`. Add a test with `applySelectedCategories` and a `URLError(.cancelled)` handler.

### WR-03: The "while `.loading`, the fetch that set it is in flight" invariant does not hold, so a cancelled fetch can settle sections a different fetch owns

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:91-105, 124-130, 329-350`
**Issue:** `stateAfterCancelledFetch` only checks `current == .loading`, not who set it. Two cases break the documented invariant:
- **Refresh over loaded, then category change.** Fetch A (a refresh over `.loaded`) never sets `.loading`, so its `before` is `.loaded`. Fetch B (a category change) then sets `.loading`. If A is cancelled, `current == .loading` and `before == .loaded`, so A restores `.loaded` and drops B's skeletons while B is still in flight. The old-filter content becomes visible until B lands.
- **First load, then re-fire.** Fetch 1 (a first load, `before = .idle`) is in flight. Fetch 2 (a `.task` re-fire, `before = .loading`) starts. If fetch 1 is cancelled, it settles to `.failed(interrupted)` and shows a Retry card while fetch 2 is still loading. Fetch 2 then overwrites it, so the user sees a flicker.

Both are transient or rare, since only `URLError.cancelled` reaches this branch now. But the doc comment and the tests assert something the code does not guarantee.

**Fix:** Resolved by the generation token in WR-01. Only the fetch that owns the latest generation settles state. Otherwise correct the invariant comment and add a test for the overlap cases.

## Info

### IN-01: A failed refresh still wipes loaded content, which is inconsistent with the stated "keep what's on screen" intent

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:131-138`
**Issue:** A cancelled refresh now keeps loaded sections. A real failure during pull-to-refresh, such as offline, still sets all three sections to `.failed` and clears `featuredTopics`. The user loses content that was on screen. This is pre-existing, but it sits next to new code that now treats loaded content as worth preserving.
**Fix:** If `before == .loaded` and the fetch was not a filter change, keep the content and surface the error some other way (a toast). Otherwise record this as intentional.

### IN-02: Triplicated per-section state code, with lines past the advisory 120 columns

**File:** `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift:93-105, 125-130`
**Issue:** The same assign-if-changed pattern is written out six times, once per section for begin and once for settle. Lines 125 and 129 run past 120 columns.
**Fix:** Add a small helper, for example `private func update(_ keyPath: ReferenceWritableKeyPath<ExploreClientViewModel, LoadState>, _ new: LoadState)`. Then loop over the three key paths with `zip(before, ...)`.

### IN-03: `MockURLProtocol` is only partly made thread-safe

**File:** `ClickMe2026Tests/Support/MockURLProtocol.swift:17, 30-33, 41`
**Issue:** The request log is locked, but `handler` is still a bare `nonisolated(unsafe) static var`. It is written on the main actor (`serve`, `serveHeld`, `reset`) and read on the URL loading thread. `recordedRequests` also keeps a setter, so a read-modify-write such as `recordedRequests.append(x)` is not atomic despite the doc comment.
**Fix:** Guard `handler` with the same lock. Take a snapshot under the lock in `startLoading`, and invoke the snapshot outside the lock. Drop the `recordedRequests` setter and keep `reset()` as the only way to clear the log.

### IN-04: Held-response tests block the shared URL protocol thread and depend on wall-clock polling

**File:** `ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift:104-129, 343-470`
**Issue:**
- `serveHeld` parks the URLProtocol thread in `gate.wait(timeout: 10)`. CFNetwork runs custom protocols on a shared thread, so any other mocked request in the process stalls for up to 10 s if a test fails before its `defer { gate.signal() }` runs. That signal is queued correctly here, but the coupling is fragile.
- Polling with 20 ms sleeps and 5 s ceilings (`homeRequestArrived` and the category-change loop) can flake on loaded CI.
- `cancelledFirstLoadShowsFailure` asserts only that the message lacks "cancel". It is a weak check next to the exact `genericError` equality already asserted above it.
- `refreshKeepsLoadedSectionsVisible` does not assert the code comment's claim that a refresh over loaded content publishes nothing. An `objectWillChange` counter would cover it.

**Fix:** Prefer an `AsyncStream` or continuation-based hold in the mock (complete the request later via `client?.urlProtocol(...)`) over a semaphore. Drop the redundant weak assertion. Add tests for overlapping fetches (WR-01) and for a cancelled category change (WR-02).

---

_Reviewed: 2026-11-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
