---
status: testing
phase: 08-release
source: [08-VERIFICATION.md]
started: 2026-11-24T00:55:53Z
updated: 2026-11-24T00:55:53Z
---

## Current Test

number: 1
name: App Store review outcome and release of 1.1 (7)
expected: |
  App Store Connect status moves Waiting for Review -> In Review -> Ready for Sale (auto-release on), and App Store users can download 1.1. If Apple rejects, the phase goal is not met and a resubmission or new build is needed.
awaiting: user response

## Tests

### 1. App Store review outcome and release of 1.1 (7)
expected: Status moves Waiting for Review -> In Review -> Ready for Sale, and the 1.1 listing is live on the App Store.
result: [pending]

### 2. Optional, reversible (D-33): R1 overtime steps on 1.1 (7)
expected: On an in-app session run past the scheduled end, the notice appears at end + 55, the iPhone ends the call at end + 60, and the Android peer tears down on call.ended. Waived by D-33; does not block the phase.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
