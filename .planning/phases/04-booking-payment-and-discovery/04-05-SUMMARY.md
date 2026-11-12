---
phase: 04-booking-payment-and-discovery
plan: 05
subsystem: ui
tags: [swiftui, expert-profile, load-state, retry, favorites, swift-testing]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "ReloadGeneration (plan 04-02) and BookingErrorMapper.code(for:)"
provides:
  - "ExpertProfileLoadState (loading, loaded, notFound, failed) driven only by GET /experts/:id/details"
  - "ExpertProfileViewModel.retry() with a double-tap guard and a ReloadGeneration load gate"
  - "ExpertProfileStateView: not-available (Back only) and load-failed (Retry) full-screen states"
  - "PublicProfileDetailsData.isFavorite; the heart reads is_favorite and no longer scans /client/favorites"
affects: [04-06, 04-10, 04-12, expert-profile, favorites]

actuals:
  tokens: 7700
  tasks: 2
  commits: 3
plan_head_before: d3cc96d2f424101faf637e3fe6c61d57fb2499aa
plan_head_after: 076f7c0198edb38d97582192d62c5dbebca53a3d

tech-stack:
  added: []
  patterns:
    - "Load state decided by one call; 404 branches on status or ErrorCode, never message text"
    - "ReloadGeneration token on a view model so only the newest started load writes"

key-files:
  created:
    - ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileStateView.swift
    - ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift
    - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift
    - ClickMe2026/Model/Responses/PublicProfileDetailsData.swift

key-decisions:
  - "A 404 is detected by NetworkError.httpError status 404 or ErrorCode.notFound, so an unreadable 404 body still reads as not available"
  - "The server is_favorite replaces the caller's seed unless a toggle is in flight; a missing key reads false"
  - "The profile ScrollView moved into a profileScroll computed property so the body can switch on loadState"

patterns-established:
  - "Full-screen profile state view replaces the scroll content and the toolbar actions are built only for loading/loaded"

requirements-completed: [EXPL-01, EXPL-05]

coverage:
  - id: D1
    description: "A 404 from the details call shows 'This profile isn't available' with Back only, no Retry and no Remove"
    requirement: EXPL-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#details 404 with NOT_FOUND is notFound and makes no reviews request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#details 404 with an unreadable body is still notFound (status code, not message text)"
        status: pass
    human_judgment: true
    rationale: "State view layout, copy and Back popping one level need a real iPhone (UAT EXPL-01); logged in WINDOWS.md as unrun-verify"
  - id: D2
    description: "Any other details error shows 'Couldn't load profile' with the user message and a working, double-tap-safe Retry"
    requirement: EXPL-01
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#a transport failure is failed with a message"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#retry after a failure with a 200 stub loads the profile"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#retry after a failure that now returns 404 switches to notFound"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#two retries started back to back make one details request"
        status: pass
    human_judgment: true
    rationale: "The spinner replacing the Retry capsule and the removed heart/menu are visual and need a device (UAT L3); logged in WINDOWS.md as unrun-verify"
  - id: D3
    description: "The heart reads is_favorite from the details response; opening a profile makes no /client/favorites request"
    requirement: EXPL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#a full load makes no /client/favorites request"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#is_favorite true replaces a seed of false"
        status: pass
      - kind: unit
        ref: "ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift#a favorite toggle in flight keeps its value when the details land"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 05: Unavailable and Failed Expert Profile States Summary

**The expert profile now decides its load state from `GET /experts/:id/details` alone: a 404 shows "This profile isn't available" with Back only, any other failure shows "Couldn't load profile" with a double-tap-safe Retry, and the heart reads `is_favorite` from the response instead of scanning 100 favorites.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-12T04:56:19Z
- **Completed:** 2026-11-12T05:04:00Z
- **Tasks:** 2
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments
- `ExpertProfileLoadState` (`loading`, `loaded`, `notFound`, `failed(String)`) replaces the swallowed `try?` on the details call, so a deleted or suspended expert, or a network failure, no longer leaves the seeded profile on screen as if it loaded.
- `ExpertProfileStateView` shows the not-available and load-failed layouts per UI-SPEC section 6; the heart and the overflow menu are removed in both, and the system back chevron stays.
- `retry()` ignores taps while one is running; the Retry capsule becomes an accent spinner while it runs. A `ReloadGeneration` token lets only the newest started load write the profile, the heart or the load state.
- `PublicProfileDetailsData.isFavorite` is decoded and the heart is set from it (missing key reads false, an in-flight toggle is never overwritten). The favorites-list request is gone.
- 13 Swift Testing cases in `ExpertProfileViewModelTests` cover 404 by code and by status, transport failure, 500, merge, retry success, retry-to-404, double retry, and the heart rows.

## Task Commits

1. **Task 1: Tracer, a 404 profile says "This profile isn't available"; a network error offers Retry** - `b4e2966` (fix)
2. **Task 2: The heart reads is_favorite from the profile; no favorites-list scan** - `f309b47` (test, RED), `076f7c0` (fix, GREEN)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileViewModel.swift` - load state, `retry()`, `loadGate`, details-only load decision, `is_favorite` heart
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift` - switches on `loadState`, `dismiss` for Back, toolbar items only while loading/loaded; scroll content extracted to `profileScroll`
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileStateView.swift` - new state view with two previews
- `ClickMe2026/Model/Responses/PublicProfileDetailsData.swift` - `isFavorite: Bool?`
- `ClickMe2026Tests/Network/Discovery/ExpertProfileViewModelTests.swift` - new suite

## Decisions Made
- 404 is recognised from `NetworkError.httpError` status 404 or `ErrorCode.notFound` (never message text), so a 404 with an unreadable body is still "not available".
- Cancellation (`CancellationError`, `URLError.cancelled`) from a `.task` that is torn down writes nothing, so leaving the screen never flips it to the failed state.
- The server `is_favorite` replaces the seed except while `isFavoriteInFlight`; the toggle's own response reconciles afterwards.

## Deviations from Plan

### Tracer gate handled without a mid-flight stop

The Task 1 tracer's `<verify>` carries a `<human-check>` (airplane mode and a deleted expert on a real iPhone). Under `human_verify_mode: end-of-phase` I did not stop for a checkpoint: this project's definition of done puts device checks in the end-of-phase UAT session, and plans 04-03 and 04-04 handled theirs the same way. I re-ran the tracer's automated verify (8 tests passing, grep gates passing, then 13 tests after Task 2) before expanding, and logged the device check as an `unrun-verify` entry in `.planning/WINDOWS.md` for UAT. Task 2 does not build on any layout the device check would judge.

### Auto-fixed Issues

None - no Rule 1-3 fixes were needed.

### Task 2 commit split

The plan lists one commit for Task 2; because the task is `tdd="true"` I committed the failing tests first (`f309b47`, four of five new rows failed as expected; the in-flight row passes trivially before the change) and the implementation second (`076f7c0`).

---

**Total deviations:** 0 auto-fixed; 1 process note (tracer device check deferred to UAT), 1 commit split.
**Impact on plan:** None on scope or behavior.

## Issues Encountered
None. Warning baseline for the four app files was 0 before and 0 after; `xcodebuild build` succeeded.

## Known Limitations
- K5 (accepted 2026-11-11): while loading, the seeded profile shows with no spinner, so it can flash briefly before a 404 replaces it.
- A details response that was computed before a heart toggle and lands after that toggle has finished can still set the heart to the older server value. The plan only protects a toggle that is still in flight (T-04-15); the window needs a toggle during a slow details load.
- No unit test drives two overlapping loads, so the `loadGate` out-of-order guard rests on `ReloadGeneration`'s own contract rather than a dedicated row here.
- Android follow-up (logged, not built): verify Android's network-error Retry state on the expert profile (D-10). Android already has the not-available strings.

## User Setup Required
None - no external service configuration required.

## Threat Flags
None - no new network endpoints, auth paths or schema surface beyond reading the existing `is_favorite` field.

## Next Phase Readiness
- Plan 04-12 can edit `ExpertProfileView.swift` in wave 2 (empty-section hiding, Favorites heart seed); the body now switches on `viewModel.loadState` and the scroll content lives in `profileScroll`.
- Pending device check (UAT EXPL-01, L3, EXPL-05) is in `.planning/WINDOWS.md`.

## Self-Check: PASSED

- FOUND: ExpertProfileStateView.swift, ExpertProfileViewModelTests.swift
- FOUND commits: b4e2966, f309b47, 076f7c0

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*
