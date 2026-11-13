---
phase: 05-signup-mode-switch-and-account
plan: 06
subsystem: ui
tags: [swiftui, navigation, cancellation, copy, refund-policy]

requires:
  - phase: 02
    provides: tab-owned navigation stacks that own the client cancel flow (D-04)
provides:
  - "Cancellation policy" link on the client cancel confirmation step that opens CancellationPoliciesView
  - How to Initiate card copy matching the real Cancel button and the cancel-until-session-end rule
  - Refund footnote with no fixed-days promise, matching the backend FAQ
affects: [05-17 (D-13 half of SET-07), 06 (expert-cancel refund wording, untouched here)]

actuals:
  tokens: 300
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "navigationDestination(isPresented:) on the cancel flow's outer ZStack pushes onto whichever tab stack shows it"

key-files:
  created: []
  modified:
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation Policies/Subviews/HowToInitiateCard.swift
    - ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift

key-decisions:
  - "Link placed between the 24-hour notice and the action buttons as a plain underlined green text button (Claude's discretion, D-12)"
  - "Deadlines and Refund Eligibility cards left unchanged: re-read refund.js and the FAQ migration, both still match"
  - "Expert-cancel refund wording not touched (Phase 6)"

requirements-completed: [SET-07]

coverage:
  - id: D1
    description: "Cancel confirmation shows a 'Cancellation policy' link that pushes CancellationPoliciesView; Back returns to the confirmation"
    requirement: SET-07
    verification:
      - kind: other
        ref: "grep -E 'navigationDestination\\(isPresented: \\$showPolicy\\)' ClientCancellationView.swift; xcodebuild build succeeded"
        status: pass
    human_judgment: true
    rationale: "Push-from-inside-a-destination behavior on a NavigationPath stack (RESEARCH A5) can only be confirmed on a device from both the Bookings tab and a Home-route cancel"
  - id: D2
    description: "How to Initiate card says Tap 'Cancel' and that cancellation can start until the session ends"
    requirement: SET-07
    verification:
      - kind: other
        ref: "grep gates on HowToInitiateCard.swift (no 'Cancel Booking', no 'before the session starts', has 'until the session ends', has \"Tap 'Cancel'.\")"
        status: pass
    human_judgment: false
  - id: D3
    description: "Refund footnote reads 'Your bank decides how long a refund takes to appear.' with no business-days claim"
    requirement: SET-07
    verification:
      - kind: other
        ref: "grep gates on CancellationConfirmCard.swift (no 'business days', has the new sentence)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No new compiler warnings in the three edited files"
    verification:
      - kind: other
        ref: "xcodebuild build Debug iPhone 17, comm -13 of before/after warning lists is empty (baseline 0 warnings)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-11-13
status: complete
plan_head_before: 14d08921000c64ea3bf4551efaeb4f0137800e4c
plan_head_after: c489e9a3d07843cb818e761e198c3e98dd7bdc30
commits: 1
---

# Phase 05 Plan 06: Cancellation policy link and policy copy fixes Summary

**The client cancel confirmation now links to the (previously unreachable) CancellationPoliciesView through a pushed navigation destination, and the policy and refund copy was corrected to match the Cancel button, the cancel-until-session-end rule and the backend FAQ.**

## Performance

- **Duration:** about 8 min (two xcodebuild runs dominate)
- **Completed:** 2026-11-13T18:15Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- `ClientCancellationView` gained `@State private var showPolicy` and a centred, underlined "Cancellation policy" text button between the 24-hour notice and the action buttons. `.navigationDestination(isPresented: $showPolicy) { CancellationPoliciesView() }` is on the outer `ZStack` (not in a lazy stack) so it pushes onto whichever tab stack shows the cancel flow.
- `HowToInitiateCard`: step 3 is now "Tap 'Cancel'." and the intro says a cancellation can start from the Bookings tab until the session ends, matching `UpcomingActionPolicy.canShowCancel` (end > now).
- `CancellationConfirmCard`: the refund footnote no longer promises 3-5 business days; it reads "Your bank decides how long a refund takes to appear." under the same `showsRefundFootnote` condition.
- Re-read `refund.js` (full refund only when strictly more than 24 hours before start, otherwise 0) and the FAQ migration `20261113000200_faq_content_match_terms.sql`: both match the unchanged Deadlines and Refund Eligibility cards, so those were not edited.

## Task Commits

1. **Task 1: Tracer, "Cancellation policy" opens the corrected policy from the cancel confirmation** - `c489e9a` (feat)

**Plan metadata:** committed separately (docs: complete plan)

## Files Created/Modified
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/ClientCancellationView.swift` - policy link and navigation destination
- `ClickMe2026/Views/Screens/Client Mode/Cancellation Policies/Subviews/HowToInitiateCard.swift` - step 3 label and intro sentence
- `ClickMe2026/Views/Screens/Client Mode/Cancellation/Subviews/CancellationConfirmCard.swift` - refund footnote

`ClickMe2026/Localizable.xcstrings` also carried pre-existing uncommitted edits and Xcode rewrote it during the builds; it was never staged.

## Decisions Made
- Link style and placement as in the plan (small underlined brand-green text button, centred, above the action buttons).
- No new tests: the change is a navigation link and three strings with no testable logic; verification is the grep and build gates plus the device check.

## Deviations from Plan

### Plan defect (not a code deviation)

**1. [Gate defect] BRE grep for `navigationDestination(isPresented: $showPolicy)` cannot match on macOS**
- **Found during:** Task 1 verification
- **Issue:** The plan's first `<automated>` command uses `grep -c 'navigationDestination(isPresented: $showPolicy)'` (basic regex). On macOS BSD grep the mid-pattern `$` behaves as an anchor, so the count is 0 even though the code is present at `ClientCancellationView.swift:80`.
- **Fix:** No code change. Confirmed with `grep -nF` (match at line 80) and with the ERE form used in the plan's own `key_links` (`navigationDestination\(isPresented: \$showPolicy\)`, count 1). All six other grep checks and the build/warning gate pass as written.
- **Files modified:** none
- **Committed in:** n/a

---

**Total deviations:** 0 code deviations, 1 plan gate defect (fixed-string grep substituted)
**Impact on plan:** None on the shipped code.

## Issues Encountered
None beyond the grep gate defect above.

## Pending device check (SET-07)

On a real iPhone as a client with a confirmed booking: open Cancel from the Bookings tab, continue to the confirmation, tap "Cancellation policy"; the policy should open and Back should return to the confirmation with the same reason. Repeat from a booking opened on the Explore (Home-route) tab. If the push does not work from inside a destination (RESEARCH A5), the fallback is a sheet with its own `NavigationStack` and a Done button, logged as a follow-up fix. The `05-DEVICE-UAT-CHECKLIST.md` file does not exist yet in the phase directory, so this check is recorded here for that checklist.

## Known Stubs

None.

## Threat Flags

None. T-05-12 (policy copy promising refunds or timing the backend does not give) is mitigated: the fixed-days claim is removed and the remaining copy was re-checked against `refund.js` and the FAQ migration.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 05-17 owns the other half of SET-07 (deleting `ReadyToStartCallView`), so SET-07 is not fully complete until that plan finishes.
- Expert-cancel refund wording remains for Phase 6.

---
*Phase: 05-signup-mode-switch-and-account*
*Completed: 2026-11-13*

## Self-Check: PASSED

- Modified files exist; commit `c489e9a` is an ancestor of HEAD; `git show --stat` lists exactly the three task files.
- Acceptance criteria: `grep -c "Tap 'Cancel'."` = 1; build gate passes with an empty warning diff.
