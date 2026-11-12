---
phase: 04-booking-payment-and-discovery
plan: 12
subsystem: ui
tags: [swiftui, expert-profile, favorites, swift-testing]

requires:
  - phase: 04-booking-payment-and-discovery
    provides: "04-05 ExpertProfileViewModel with isFavorited seed and loadState; 04-06 FavoritesView navigation destination"
provides:
  - "ExpertProfileView.init(expert:isFavorited:...) seed parameter; Favorites passes true (D-09)"
  - "ExpertProfileSections: pure visibility rules for Expertise, Topics and Reviews, and the hero rating row copy"
  - "Empty profile sections and their padding are not drawn; zero reviews reads 'No reviews yet'; one review reads '(1 review)'"
affects: [04-14]

actuals:
  tokens: 2500
  tasks: 3
  commits: 2
plan_head_before: 38af22a17da10c69d5347ec09d16ba2137222362
plan_head_after: c6c3470

tech-stack:
  added: []
  patterns:
    - "Presentation rules as a caseless enum of pure functions returning a small Equatable value (Rating), shared by the view and the tests"

key-files:
  created:
    - ClickMe2026/Utils/ExpertProfileSections.swift
    - ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift
    - ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileHero.swift
    - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift

key-decisions:
  - "Task 2 (EXPL-02 confirm): the user chose fix-now on 2026-11-12. The fix went in from the code evidence and the before/after device check moves to the 04-14 UAT list"
  - "Open Question 5 adopted: a chat-opened profile has no profile-level tags, so its Expertise section is hidden, not derived"
  - "D-09: only FavoritesView seeds the heart as filled; every other entry keeps the false default and the server's is_favorite replaces the seed"
  - "The hero keeps the existing %.1f rating format; only the zero and one review copy changed"

patterns-established:
  - "Section guards wrap a section together with its own padding so a hidden section leaves no gap"

requirements-completed: [EXPL-02, EXPL-05]

coverage:
  - id: D1
    description: "A profile opened from Favorites seeds a filled heart; other entries seed it empty"
    requirement: EXPL-05
    verification:
      - kind: other
        ref: "grep isFavorited: true in FavoritesView.swift; grep 'isFavorited: Bool = false' in ExpertProfileView.swift; xcodebuild build"
        status: pass
    human_judgment: true
    rationale: "First-frame heart state is visual; only a device shows the absence of a flicker"
  - id: D2
    description: "Empty Expertise, Topics and Reviews sections are not drawn, with their padding"
    requirement: EXPL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift (expertiseVisibility, topicsVisibility, reviewsVisibility)"
        status: pass
    human_judgment: true
    rationale: "The unit tests prove the rule; the absence of a bare header or blank gap in the laid-out profile needs a device check (04-14 UAT, EXPL-02)"
  - id: D3
    description: "Hero rating row: 'No reviews yet' with no star for zero reviews, '(1 review)' for one, '(n reviews)' for more, placeholders until the summary loads"
    requirement: EXPL-02
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift (ratingBeforeSummaryLoads, ratingZeroReviews, ratingOneReview, ratingManyReviews)"
        status: pass
    human_judgment: false

duration: ~35 min of active work (excludes the wait at the Task 2 decision)
completed: 2026-11-12
status: complete
---

# Phase 4 Plan 12: Expert Profile Empty Sections and Favorites Heart Summary

**Empty Expertise, Topics and Reviews sections are no longer drawn, a zero-review expert reads "No reviews yet" instead of "0.0 (0 reviews)", and a profile opened from Favorites starts with a filled heart.**

## Performance

- **Duration:** ~35 min active (the first session began 2026-11-12T00:52Z; the clock includes the wait for the Task 2 decision)
- **Tasks:** 3 (Task 2 was a decision, no commit)
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- The heart on a profile opened from Favorites is filled from the first frame (D-09, EXPL-05). Explore, Search, the chat peer profile and the expert's own profile keep the empty seed.
- `ExpertProfileSections` holds the EXPL-02 rules as pure functions: `showsExpertise`, `showsTopics`, `showsReviews` and `rating(summaryLoaded:rating:reviewCount:)`. Seven tests pin them.
- `ExpertProfileView` wraps each of the three sections together with its own padding in a guard, so a hidden section leaves no bare header and no blank gap. The About card, stats bar and the self-view rules (heart, menu and booking buttons hidden) are untouched.
- `ExpertProfileHero.ratingRow` draws from the rule: no star and no value for zero reviews, "(1 review)" for one, the existing one-decimal value otherwise, and em-dash placeholders until the summary loads.

## Task Commits

1. **Task 1: Tracer, Favorites seeds a filled heart** - `2eb6a35` (fix)
2. **Task 2: EXPL-02 decision** - no commit. The user answered **fix-now**.
3. **Task 3: Hide empty profile sections; zero and one review copy** - `c6c3470` (fix)

**Plan metadata:** the docs commit that carries this file (docs: complete plan).

Commits are measured by subject (`(04-12)`), not by range: plan 04-13 committed between 2eb6a35 and c6c3470, so `plan_head_before..HEAD` would count its commits too.

## Task 2 Decision Record

- **Question:** confirm EXPL-02 on a device first, or fix from the code evidence.
- **Answer:** `fix-now` (genuine user reply, 2026-11-12).
- **Evidence used:** the three section views draw their headers for empty input; a chat-opened profile is seeded with `expertiseTags: []` and the details response has no profile-level tags (RESEARCH Open Question 5, A9).
- **Consequence:** Task 3 ran. EXPL-02 is not closed as not-reproducible, and no device or build was used for confirmation. The before/after device check is in the 04-14 UAT list (see below).

## TDD

- **RED:** the seven tests were written against a deliberately wrong stub (every section visible, "N reviews" label). Run `/tmp/04-12-t3-red.log`: 7 of 7 tests compiled and failed on their planned assertions (`Test run with 7 tests in 1 suite failed`). Semantic assessment: each failure was the target test's own `#expect` on the planned behavior, for example `showsExpertise([]) → true` against `false` and `"(1 reviews)"` against `"(1 review)"`. No build, load or zero-test fault.
- **GREEN:** the rules were implemented and the suite passed (`Test run with 7 tests in 1 suite passed`).
- **REFACTOR:** none.
- **Commit shape:** RED and GREEN are in one commit, `c6c3470`, because the plan asks for one commit with these four files (the plan is `type: execute`, not `type: tdd`). The RED evidence is the run log above, not a separate `test(04-12)` commit.

## Files Created/Modified

- `ClickMe2026/Utils/ExpertProfileSections.swift` - visibility and hero rating rules
- `ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift` - seven rows: three visibility, four rating
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift` - heart seed parameter on the convenience init; three section guards
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/Subviews/ExpertProfileHero.swift` - rating row built from the rule
- `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesView.swift` - passes `isFavorited: true`

## Decisions Made

See `key-decisions`. No new architecture; one pure-function enum and view guards.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The behavior row "4.25 shows 4.3" is wrong for `%.1f`**
- **Found during:** Task 3 GREEN run
- **Issue:** `String(format: "%.1f", 4.25)` gives "4.2". 4.25 is an exact binary tie and printf rounds it half to even. The plan's row assumed "4.3" while also saying to keep the existing one-decimal format.
- **Fix:** kept the existing `%.1f` format (changing the rounding would change what users see for every expert) and moved the test input to 4.26, which gives "4.3" without depending on tie rounding.
- **Files modified:** ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift
- **Verification:** suite passes, 7 of 7
- **Committed in:** c6c3470

---

**Total deviations:** 1 auto-fixed (1 bug in the plan's expected value)
**Impact on plan:** None on behavior. Android was not checked for how it rounds a tie; if Android rounds half up, an expert rated exactly x.x5 could differ by 0.1 between platforms. Not logged as a follow-up because the app only ever shows server averages.

## Issues Encountered

None. The warning baseline for the touched files was empty and the final build has no new warnings (`comm` against `/tmp/04-12-warn-before.txt` printed nothing).

## Device Check for the 04-14 UAT List

Recorded in `.planning/WINDOWS.md` as an open `unrun-verify` entry. For the 04-14 checklist (EXPL-02 and EXPL-05 items):

1. **Before (App Store build):** open View Profile from a chat with an expert who has no reviews and note whether a bare "Expertise" or "Recent Reviews" header or an empty card shows, and whether the hero reads "0.0 (0 reviews)".
2. **After (a current debug build):** the same expert shows no Expertise header, no empty Recent Reviews card, no blank gap, and the hero reads "No reviews yet" with no star.
3. An expert with one review shows "(1 review)". An expert with two or more shows "(n reviews)".
4. Open a profile from Favorites: the heart is filled from the first frame. Open the same expert from Search: the heart starts empty, then fills when the profile loads.
5. Largest Dynamic Type (L5): the hero rating row and the shortened scroll still lay out cleanly.

## Follow-ups (logged, not built)

- Derive a chat-opened profile's Expertise from the union of `topics_of_discussion[].expertise_tags` (RESEARCH Open Question 5).

## Known Stubs

None.

## Threat Flags

None. Presentation only; no new request, endpoint or data. T-04-28 is mitigated as planned: the seed is used only from Favorites and the 04-05 details load replaces it with `is_favorite`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 04-14, which needs the device check above and the Task 2 decision record in its UAT checklist.

---
*Phase: 04-booking-payment-and-discovery*
*Completed: 2026-11-12*

## Self-Check: PASSED

- FOUND: ClickMe2026/Utils/ExpertProfileSections.swift
- FOUND: ClickMe2026Tests/Utils/ExpertProfileSectionsTests.swift
- FOUND commits: 2eb6a35, c6c3470 (both ancestors of HEAD)
