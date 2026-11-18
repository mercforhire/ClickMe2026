---
created: 2026-11-13T00:00:00.000Z
title: Flaky test: MakeABookingAvailabilityTests "An older load that lands last writes nothing"
area: testing
severity: low
files:
  - ClickMe2026Tests/Booking/MakeABookingAvailabilityTests.swift
  - ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift
---

## Problem

`MakeABookingAvailabilityTests` > `olderLoadLandingLastWritesNothing` ("An older load that lands last writes nothing") is intermittent. The failing assertion is `#expect(viewModel.expertTimezone == "Zone/2")` at `MakeABookingAvailabilityTests.swift:154`: it got `"Zone/1"`.

Seen during Phase 5 (2026-11-13): it failed in 1 of 3 isolated runs and once in a full-suite run. It passed in the plan 05-13 full-suite run (803 tests in 82 suites passed). Phase 5 did not touch Make a Booking (no Phase 5 commit edits `MakeABookingViewModel.swift` or this test file), so this is not a Phase 5 regression. Phase 4 owns the area (BOOK-02, T2 and T3).

Seen in Phase 6 plan 06-10 (2026-11-16): run 1 failed at MakeABookingAvailabilityTests.swift:154, run 2 passed; Phase 6 did not touch Make a Booking.

Seen in Phase 6 plan 06-16 (2026-11-17): run 1 passed; the gap closure did not touch Make a Booking.

Seen in Phase 7 plan 07-08 (2026-11-18): run 1 passed (5 tests in 1 suite), no rerun needed, log `/tmp/07-08-flaky-1.log`; Phase 7 did not touch Make a Booking (0 commits in `16fe88e..HEAD`).

Seen in Phase 7 plan 07-09 (2026-11-18, the final-tree gate re-run at `491b600`): run 1 failed with 1 issue (5 tests in 1 suite), run 2 passed; Phase 7 did not touch Make a Booking (0 commits in `16fe88e..HEAD`).

## What to look at

The test starts two loads for the same month with two unstructured `Task`s (`older`, `newer`) and makes the first request the stub sees slow (`Thread.sleep(0.3)` when `counter.next() == 1`), tagging each response with its request number. It assumes the first request to reach the stub belongs to the older load and the second to the newer one. Nothing guarantees which `Task` reaches the stub first, so on a run where the newer load's request is number 1, the slow one is the newer load and `"Zone/1"` wins, which is what the failure shows. This is an unconfirmed hypothesis from reading the test, not a diagnosis; confirm by running the test in a loop and logging which load issues request 1.

Possible fixes (pick one when someone has time):

- Make the ordering deterministic: start the older load, wait until the stub has seen its request (a continuation or an async stream the stub signals), then start the newer one.
- Tag each response by the load that issued it rather than by arrival order.
- Run the test in a loop (for example `-test-iterations 50`) before and after to prove the flake is gone.

No product bug is implied: `loadAvailability` is meant to drop a stale response, and the other tests in the suite cover the rest of that rule.
