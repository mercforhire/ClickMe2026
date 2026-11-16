---
phase: 06-expert-mode
plan: 06
subsystem: ui
tags: [swiftui, expert-mode, incoming-requests, profile-hub, contrast, presence]

requires:
  - phase: 06-expert-mode
    provides: "06-05 Accept to Booking Confirmed flow (serialized wave order)"
provides:
  - "Expert hub with no online dot and no presence state in its view model"
  - "Expired request card with full-contrast text, darker fill, faint border, dimmed avatar photo and EXPIRED pill"
affects: [06-07, 06-08, 06-10, device-uat-D1]

actuals:
  tokens: 1500
  tasks: 2
  commits: 2
plan_head_before: a4bb3be295fa0f026c5766fcb7e04cb2e90f6934
plan_head_after: 098c4563b056fb775903a64c3212d14082484b35

tech-stack:
  added: []
  patterns:
    - "Expired state marked by fill, border and badge, never by whole-card opacity"
    - "Shared client card reused with isOnline: false rather than forking it (U2)"

key-files:
  created: []
  modified:
    - "ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift"
    - "ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestAvatar.swift"

key-decisions:
  - "Expert hub passes isOnline: false to the unchanged shared ClientProfileHomeUserCard, so the client hub cannot change (U2)"
  - "Expert's own public-profile preview also gets isOnline: false (Open Question 5); listed for the user to judge in the device checklist"
  - "Border opacity lives in a private borderOpacity property so the card's grep gate for the removed whole-card opacity stays meaningful"

patterns-established:
  - "Dim imagery only (avatar photo), keep text at full contrast, on expired cards"

requirements-completed: [EXP-15, EXP-12]

coverage:
  - id: D1
    description: "Expert hub user card and own public-profile preview show no online dot; hub view model holds no presence state"
    requirement: EXP-15
    verification:
      - kind: other
        ref: "grep gate: no isOnline in ExpertProfileHomeViewModel.swift, no viewModel.isOnline in the screen, two isOnline: false call sites, client hub files unchanged"
        status: pass
      - kind: other
        ref: "xcodebuild build iPhone 17 Debug: BUILD SUCCEEDED, no new warnings"
        status: pass
    human_judgment: true
    rationale: "Rendering of the dot (and the client hub still showing it) can only be judged on a real device; device check D1"
  - id: D2
    description: "Expired request card keeps name, topic, Earnings, amount and date at full contrast; fill, border, avatar photo and EXPIRED pill carry the expired state"
    requirement: EXP-12
    verification:
      - kind: other
        ref: "grep gate: no whole-card opacity, surfaceContainerLowest, overlayWhite10, 0.35, Capsule(), avatar isExpired, amber line and PressScaleButtonStyle kept"
        status: pass
      - kind: other
        ref: "xcodebuild build iPhone 17 Debug: BUILD SUCCEEDED, no new warnings"
        status: pass
    human_judgment: true
    rationale: "Contrast and rendering can only be judged on screen; no snapshot tests in this project; device check D1 before (build 6) and after"

duration: 2min
completed: 2026-11-16
status: complete
---

# Phase 06 Plan 06: Expert hub presence dot and expired request card Summary

**Removed the hard-coded always-online dot from the expert hub, and rebuilt the expired incoming-request card so only its fill, border, avatar photo and EXPIRED pill change while every text stays at full contrast.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-11-16T18:28:27Z
- **Completed:** 2026-11-16T18:30:31Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- EXP-15 (D-10): `ExpertProfileHomeViewModel` no longer has `isOnline` (property, init assignment, `previewSeed` parameter). The hub user card and the expert's own public-profile preview are built with `isOnline: false`. The client hub files are untouched.
- EXP-12 (D-17): the whole-card 0.55 opacity is gone. Expired cards use `Brand.surfaceContainerLowest`, the iris border at 0.35, the avatar photo at 0.55 (image only, ring unchanged) and an EXPIRED capsule pill (`Brand.overlayWhite10`, `Brand.onSurfaceVariant`, `.subheadline` Bold, tracking 1.2, padding 12 by 4). Open cards render as before and expired cards stay tappable.

## Task Commits

1. **Task 1: Tracer, the expert hub shows no online dot** - `d7c86c2` (fix)
2. **Task 2: Expired request cards keep their text at full contrast** - `098c456` (fix)

**Plan metadata:** committed separately as `docs(06-06)` (SUMMARY, STATE, ROADMAP).

## Files Created/Modified
- `ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift` - presence property and preview parameter removed
- `ClickMe2026/Views/Screens/Expert Mode/Profile/ExpertProfileHomeScreen.swift` - user card and self-preview pass `isOnline: false` with a D-10 comment
- `ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift` - expired fill, border opacity, EXPIRED pill; whole-card opacity removed
- `ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestAvatar.swift` - photo dims on expiry only

## Decisions Made
- Expert hub reuses the unchanged shared card with `isOnline: false` (smallest route within UI-SPEC latitude; keeps U2).
- The border opacity is a private `borderOpacity` computed property instead of an inline `.opacity(request.isExpired ...)`, so the plan's grep gate for the removed whole-card modifier stays unambiguous.

## Deviations from Plan

None - plan executed exactly as written.

The tracer's `<verify>` carries only automated gates and `HUMAN_VERIFY_MODE` is the default, so the tracer was re-verified end to end (grep gate and build, no new warnings) and expansion continued without a checkpoint.

**Total deviations:** 0
**Impact on plan:** none.

## Issues Encountered
- First Task 2 grep gate failed because an inline `.opacity(request.isExpired ? 0.35 : 1)` on the border matched the whole-card-opacity pattern. Moved the value into `borderOpacity`; gate and build then passed (one fix attempt).

## Verification
- Warning baseline for the four files before edits: 0 warnings; after Task 1 and after Task 2: no new warnings.
- `xcodebuild build` (iPhone 17, Debug): BUILD SUCCEEDED after each task.
- No unit tests were added or run: colour and opacity are not observable in this project (no snapshot tests); the plan names grep and build gates with device check D1 as the backstop.

## Known Stubs
None.

## Threat Flags
None. Presentation-only change; T-06-10 mitigated (no presence state in the hub view model, grep-verified).

## Device Check Pending (backstop)
- D1 (06-DEVICE-UAT-CHECKLIST.md): on App Store build 6 (before) confirm the expired card text is hard to read; on the new build confirm name, topic, Earnings, amount and date read at full contrast, EXPIRED sits in a pill, the card still opens the read-only decision screen, the expert hub avatar has no dot, the expert's own public-profile preview has no dot, and the client hub still shows its dot. If the before-check finds the text readable, closing EXP-12 as not reproducible is the verifier's call.

## Requirements
EXP-15 and EXP-12 are declared complete in this plan's frontmatter, but `requirements.ready-ids` reports both blocked by plan 06-10 (a sibling plan that also declares them has no SUMMARY yet), so REQUIREMENTS.md was left unchanged for them.

## Next Phase Readiness
Ready for 06-07. No blockers.

## Self-Check: PASSED
- All four modified files exist and contain the planned changes.
- Commits `d7c86c2` and `098c456` are on `main` (`git rev-list --count` from the plan base: 2).
- Task 1 and Task 2 acceptance criteria re-run: pass.

---
*Phase: 06-expert-mode*
*Completed: 2026-11-16*
