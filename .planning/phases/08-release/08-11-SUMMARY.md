---
phase: 08-release
plan: "11"
subsystem: backend-deploy
tags: [smoke, production, deploy-x1, rel-02, d-13]

requires:
  - phase: 08
    provides: "Plan 08-08: deploy X1 live at 412f1aa, rollback branch at 28da165"
provides:
  - "User-reported live smoke of deploy X1 on App Store build 1.0 (6) and the current Android build: all six lines pass"
affects: [08-14, 08-16, 08-18]

actuals:
  tasks: 2
  commits: 0

commits: 0

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "No rollback: every smoke line passed, so production stays on 412f1aa"

requirements-completed: []

duration: user wait
completed: 2026-11-22
---

# Phase 08 Plan 11: Deploy X1 live smoke Summary

**Deploy X1 (412f1aa) is confirmed safe for App Store build 6 and the current Android build: the user reported the whole smoke as passing, and production stays on X1.**

## Task 1: Probe

- First run 2026-11-20T17:31:20Z, re-run 2026-11-21T06:01:47Z before the smoke.
- `/health` = `412f1aa`. GitHub backend `main` = `ios-p8-x1` = `412f1aa649f5aa72fb853e40e87ab5e0998eb926`.
- `ios-p8-x1-rollback` = `28da165ebe66a973008560f689c469389279c25f`.

## Task 2: Live smoke (user-reported)

The user's reply, verbatim: `pass`. It was given as one answer for the whole checklist, with no notes on individual lines. It is recorded as PASS for each line:

| # | Smoke line | Result |
|---|------------|--------|
| 1 | Both apps: log in, My Bookings, open a chat | PASS |
| 2 | Client proposes, expert declines: "Reschedule Requested" to the expert, "Reschedule Declined" to the client only; the tap opens the booking on Android, and build 6 does not crash | PASS |
| 3 | Expert proposes, client declines: "Reschedule Declined" to the expert only | PASS |
| 4 | Chat event rows on build 6 and Android show as before, no crash | PASS |
| 5 | Android empty first name with an empty last name: an error, no crash | PASS |
| 6 | Expert Topics tab on both apps shows every topic, including free ones | PASS |

The build under test is App Store build 1.0 (6), which the App Store approved (user report, 2026-11-21).

## Deviations from Plan

- Task 1 (a read-only probe) was run by the orchestrator inline, not by an executor.

## Next

- Plan 08-14 (D-29 long-lead retry), then deploy X2 in 08-16.
