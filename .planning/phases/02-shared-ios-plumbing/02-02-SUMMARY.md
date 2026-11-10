---
phase: 02-shared-ios-plumbing
plan: 02
subsystem: calls
tags: [swift, swiftui, agora, meeting-links, swift-testing]

requires:
  - phase: 02-shared-ios-plumbing
    provides: plan 02-01 call-screen overtime policy (same view model)
provides:
  - AgoraLinkState and ConnectionState.localState(for:), a pure and unit-tested mapping from Agora connection states to the local call state
  - rtcEngine(_:connectionChangedTo:reason:) delegate handler; a terminal Agora failure now ends the call through the normal end path with end_reason dropped
  - ExternalMeetingProvider host matching by equality or dotted suffix, with no raw-string fallback
affects: [phase-02-device-uat, android-parity]

plan_head_before: d611fabadb4164f55dfcf7a95c5e9689d6b2faea
plan_head_after: 3ec67f60118a5079343845085145e6c6eb6e0c69

actuals:
  tokens: 3700
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Agora SDK enums are mirrored by an app-side Int enum so the unit-test target (which links no SPM products) can test the mapping"
    - "Host trust is equality or '.' + domain after lowercasing and dropping one trailing dot; never substring"

key-files:
  created:
    - ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift
    - ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift
  modified:
    - ClickMe2026/Managers/AgoraManager.swift
    - ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift
    - ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift

key-decisions:
  - "Only Agora's failed state ends the call. Disconnected maps to no change because it is the initial state and the state after leaveChannel; mapping it would report a user's own hang-up as dropped"
  - "A failed connection ends with EndReason.dropped through the normal end path (CallCenter.endCall then handleEndCall), so the booking stays live server-side and the peer gets the usual call.ended"
  - "The dead didOfflineOfUid local-user branch is removed; the SDK reports remote users only there"
  - "A link with no host (bare 'zoom.us/j/1') is unknown rather than guessed, so the UI shows the generic Open Meeting copy"

patterns-established:
  - "AgoraLinkState / ConnectionState.localState(for:): pure mapping tested without the SDK"
  - "ExternalMeetingProvider.host(_:isOrEndsWith:): private static host matcher"

requirements-completed: [CALL-05, CALL-09]

coverage:
  - id: D1
    description: "When Agora reports the local connection failed, the call screen reaches Ended and the normal end path runs, sending end_reason dropped for a leg that joined"
    requirement: CALL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift#failedDisconnects, connectedIsReady, otherStatesAreNoChange, rawValues, unknownRawValue"
        status: pass
      - kind: device
        ref: "UAT CALL-05 / D-14: normal call -> Active -> hang up -> Ended"
        status: pass
    human_judgment: false
    rationale: "The mapping is unit tested and the normal-call regression passed on a real iPhone. The failed branch itself fires only about 20 minutes into failed reconnects, so it was not reproduced on device (accepted in the plan, no airplane-mode repro)."
  - id: D2
    description: "Agora's disconnected state (initial and after leaveChannel) does not end the call, so a user's own hang-up is never reported as dropped"
    requirement: CALL-05
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift#otherStatesAreNoChange"
        status: pass
      - kind: device
        ref: "UAT CALL-05 / D-14: hang-up reaches Ended as before"
        status: pass
    human_judgment: false
    rationale: "Mapping pinned by test; the hang-up path was exercised on device."
  - id: D3
    description: "A failed-connection event that arrives while a hang-up is in progress, or arrives twice, produces exactly one POST /end"
    requirement: CALL-05
    verification:
      - kind: backstop
        ref: "MeetingCallViewModel.endAfterConnectionFailure guard (!isEndingCall, callStatus != .ended)"
        status: pass
    human_judgment: true
    rationale: "Declared as a backstop in the plan: the guard exists in code but no automated test drives a duplicate failed event through the view model. Not reproducible on device without a 20-minute failed reconnect."
  - id: D4
    description: "ExternalMeetingProvider labels a link Skype, Zoom, Google Meet or Teams only when the host equals the provider domain or ends with a dot plus that domain; evilzoom.us, zoom.us.evil.com and notskype.com are unknown"
    requirement: CALL-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift#realHosts, lookalikeHosts"
        status: pass
    human_judgment: false
    rationale: "Eight lookalike hosts and ten real-host cases are in the argument tables."
  - id: D5
    description: "A URL with no host is unknown, and the native schemes skype, zoommtg, zoomus and msteams still map to their provider"
    requirement: CALL-09
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift#missingHost, nilURL, nativeSchemes"
        status: pass
    human_judgment: false
    rationale: "Pure function over URL; fully covered by the argument tables."
  - id: D6
    description: "The remote-user offline callback only ever changes the remote party's state"
    requirement: CALL-05
    verification:
      - kind: other
        ref: "grep -c 'uid == 0' AgoraManager.swift prints 0 (baseline 1)"
        status: pass
    human_judgment: false
    rationale: "Structural: the local branch no longer exists, so the callback cannot touch the local state."

duration: "about 1h including the tracer gate pause"
completed: 2026-11-09
status: complete
---

# Phase 2 Plan 02: Agora connection failure and meeting-link host trust Summary

**A terminal Agora connection failure now ends the call through the normal end path with end_reason dropped, and Skype/Zoom/Meet/Teams labels are given only to links whose host is the provider's real domain.**

## Performance

- **Duration:** about 1 h wall clock, spanning the pause at the Task 1 tracer gate
- **Completed:** 2026-11-09 (Task 2 commit 22:38 -0500)
- **Tasks:** 2 of 2
- **Files modified:** 5 (2 created, 3 modified); 229 insertions and 23 deletions

## Accomplishments

- CALL-05: the old local-drop branch watched `didOfflineOfUid` for `uid == 0`, which the SDK never reports (remote users only), so a failed call sat on a live screen. The new `connectionChangedTo` delegate maps only Agora's `failed` to the local disconnected state, and the view model runs `CallCenter.endCall()` with `pendingEndReason = .dropped`.
- A user's own hang-up is unaffected: Agora's `disconnected` state (initial, and after `leaveChannel`) maps to no change, so the reason stays completed or manual_exit.
- CALL-09: `host.contains("zoom.us")` and the raw-string fallback are gone. A host must equal the provider domain or end with `.` plus it (lowercased, one trailing dot ignored). `evilzoom.us`, `zoom.us.evil.com`, `zoom.us@evil.com` and `notskype.com` now get the generic "Open Meeting" copy.

## Task Commits

1. **Task 1: Tracer, an Agora connection failure ends the call through the normal end path (CALL-05)** - `2cf8029` (fix)
2. **Task 2 RED: failing host-matching tests (CALL-09)** - `023579e` (test)
3. **Task 2 GREEN: match meeting providers on the real host only (CALL-09)** - `3ec67f6` (fix)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `ClickMe2026/Managers/AgoraManager.swift` - `AgoraLinkState`, `ConnectionState.localState(for:)`, `connectionChangedTo` delegate, local branch removed from `didOfflineOfUid`
- `ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift` - `pendingEndReason`, `endAfterConnectionFailure()`, `handleEndCall` end-reason selection
- `ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift` - `host(_:isOrEndsWith:)`, raw-string fallback deleted, doc rewritten
- `ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift` - 5 mapping tests, no AgoraRtcKit import
- `ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift` - host matching tables

## TDD Gate Compliance (Task 2)

- **RED (`023579e`):** the test file was run against the unchanged implementation (`/tmp/02-02-red.log`, exit 65). The target tests failed on their planned assertions: "lookalike hosts are not trusted" failed for all 8 cases (for example `evilzoom.us` returned `.zoom`, `notskype.com` returned `.skype`, `zoom.us@evil.com` returned `.zoom`) and "a URL with no host is unknown" returned `.zoom`. The positive tests (real hosts, native schemes, nil) already passed, as expected for behavior the old code had. Run summary: 5 tests in 1 suite, 9 issues.
- **Semantic assessment:** the target executed, compiled, and failed on the intended assertion for the intended reason (substring and raw-string trust); no setup, import or fixture fault.
- **Machine check not run:** `gsd_run check tdd-red-evidence` has adapters for `swift test` console output, and the evidence here is `xcodebuild test` output, so no classifier verdict was obtained. The assessment above is manual and is not a `RED_EVIDENCE_OK`.
- **GREEN (`3ec67f6`):** the same tests pass. No REFACTOR commit. The GREEN commit type is `fix`, as the plan specified, not `feat`.

## Verification Results

- Tests: Task 1 run, "Test run with 5 tests in 1 suite passed" (`/tmp/02-02-t1.log`). Final combined run of `ExternalMeetingProviderTests`, `AgoraConnectionMappingTests` and `CallOvertimePolicyTests`: "Test run with 19 tests in 3 suites passed", `TEST SUCCEEDED` (`/tmp/02-02-t2.log`). Plan 02-01's `CallOvertimePolicyTests` (9 tests) still pass.
- Build: `BUILD SUCCEEDED` (`/tmp/02-02-build.log`).
- Warnings: the baseline for the three touched files was empty (`/tmp/02-02-warn-before.txt`, 0 lines) and the after file is empty too, so the comparison prints nothing: no new warnings.
- Acceptance greps at HEAD: `uid == 0` 0 (baseline 1), `connectionChangedTo` 3 (baseline 0), `pendingEndReason` 4 (baseline 0), `host.contains|raw.contains` 0 (baseline 9 lines), `hasSuffix` 2 (baseline 0), `import AgoraRtcKit` in the test file 0.
- Device (D-14, CALL-05): one normal in-app voice call, both sides Active, hang-up reaches Ended and dismisses as before. **Passed on device** (user approved the tracer gate with this result); it is not deferred.

## Decisions Made

See `key-decisions` above. Android needs no change: `managers/AgoraEventMapping.kt` already maps `CONNECTION_STATE_FAILED` to a local failure and `ExternalMeetingProvider.kt` uses an `isOnDomain` check. No backend change.

## Deviations from Plan

None - plan executed exactly as written. One note on mechanics: the host helper is called as `Self.host(...)` because the local `host` constant in `detect(from:)` would otherwise shadow the helper.

**Total deviations:** 0.

## Issues Encountered

None blocking. The failed-connection branch itself (about 20 minutes of failed reconnects) was not reproduced on device, as the plan accepted; D3 (duplicate failed event produces one `/end`) rests on the `isEndingCall` / `callStatus == .ended` guard and is a declared backstop with no automated test.

## Known Stubs

None.

## Threat Flags

None. T-02-03 (spoofed provider label), T-02-04 (call stuck on a dead channel) and T-02-05 (hang-up misreported as dropped) are mitigated as planned.

## Self-Check: PASSED

- FOUND: ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift
- FOUND: ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift
- FOUND commits: 2cf8029, 023579e, 3ec67f6 (all ancestors of HEAD)
