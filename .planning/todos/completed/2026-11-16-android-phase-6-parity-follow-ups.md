---
created: 2026-11-16T00:00:00.000Z
title: "Android: Phase 6 parity follow-ups (Add hours end of day, off-grid rows, 409, client hub dot)"
area: android
severity: low
files:
  - ../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/AvailabilityScheduleLogic.kt
  - ../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/availability/subviews/TimeRangePickerSheet.kt
  - ../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/requestdecision/RequestDecisionViewModel.kt
  - ../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/profile/subviews/ProfileHubComponents.kt
---

## Problem

Phase 6 changed four iOS behaviors that Android may not match. The evidence below is a read of the Android source on 2026-11-16 (06-UI-SPEC "Android follow-ups"). Nothing was run on an Android device.

1. **Add hours near the end of the day (iOS D-07, plan 06-03).** `AvailabilityScheduleLogic.addHours` builds the new slot with `start = minOf(maxEnd + ADD_HOURS_GAP, LATEST_START)`. When the latest end is at or after 22:30 the start is clamped back to `LATEST_START`, so the new slot can start before the latest existing end and overlap it. iOS now disables Add hours when the new slot's start (latest end + 30 min) would be 23:00 or later, and clamps the end to 23:30.
2. **Off-grid stored time (iOS D-08, plan 06-03).** iOS inserts a stored time that is not on the 30-minute grid (for example 09:15) into the time-range lists as a normal selected row, and shows a stored 24:00 end as `12:00 AM`. Android's `TimeRangePickerSheet` was written to round-trip 1440 losslessly; it is not known whether an off-grid time such as 09:15 shows as selected in its picker.
3. **409 `ALREADY_PROCESSED` on accept or decline (iOS D-12, plan 06-05).** iOS shows `Couldn't update request` with the server message and `OK` pops to a refreshed Incoming Requests. Android's `RequestDecisionViewModel` maps `ALREADY_PROCESSED` (its comment cites 11-CONTEXT D-07). Parity has not been verified against the iOS behavior.
4. **Client hub online dot (iOS U2, plan 06-06).** iOS removed the hard-coded online dot from the expert hub and kept it on the client hub (user decision 2026-11-16). A grep of `screens/clientmode/profile` (`ClientProfileHomeScreen.kt`, `ClientProfileHomeViewModel.kt`, `subviews/ProfileHubComponents.kt`) for online, dot and presence found no match, so the Android client hub may not show a dot at all. Not confirmed on a device.

## What to do

For each item, compare with the iOS behavior shipped in plans 06-03 (items 1 and 2), 06-05 (item 3) and 06-06 (item 4), then either align Android or record the accepted difference in the Android repo:

- Item 1: decide whether Android should disable Add hours near the end of the day as iOS does, or accept that it can add an overlapping slot (the overlap banner would then show).
- Item 2: on a device, open a slot stored at 09:15 (set it through the API) and one ending 24:00; confirm both open selected.
- Item 3: accept a free-topic test request that the client has cancelled; confirm the message is the server's and that OK lands on a refreshed list.
- Item 4: open the client Profile hub on an Android device and note whether an avatar dot shows; if it shows a hard-coded one, decide whether to remove it.

No iOS change is implied. Not built in Phase 6.

## Phase 8 answers

Read from the Android source by plan 08-12 (nothing was run on an Android device). The todo stays pending: plan 08-26 asks the user to port, defer or accept each `differs` row before it closes.

- item 1 Add hours end of day: aligned (384142ee)
- item 2 Off-grid stored time: differs: a stored 09:15 or 24:00 opens as a selected row, as on iOS, but once the expert taps another row that off-grid or 24:00 row leaves the list on Android (AvailabilityScheduleLogic.startOptions/endOptions keep only the current draft value), while iOS keeps it as a row for as long as the sheet is open
- item 3 409 ALREADY_PROCESSED on accept or decline: matches (RequestDecisionViewModel.onDecisionFailed and dismissDialog, RequestDecisionErrors.toRequestDecisionFailure: "Couldn't update request" with the server message, OK pops and posts an Incoming Requests reload)
- item 4 Client hub online dot: differs: the Android client Profile hub shows no online dot on the avatar (nothing in screens/clientmode/profile reads online or presence), while the iOS client hub keeps its green dot (user decision U2, 2026-11-16)

## Phase 8 decisions

Recorded by plan 08-26 from the user's message of 2026-11-20: "Since the iOS store review has still not been completed, let's continue to do the Android fixes." That message is read as a port request for each `differs` row. Port work is planned separately (`/gsd-plan-phase 08 --gaps`); the gap plan that lands a port rewrites its line to `ported (<Android SHA>)`.

- item 2 Off-grid stored time: ported (96933b85, da7002ce)
- item 4 Client hub online dot: ported (fa9057ad)

## Resolution

Closed by plan 08-31 on 2026-11-20. Every requested port landed on ClickMe_Android `main` as local commits (not pushed), and each decision line above now reads `ported` with its SHAs. The device checks are in the Android section of 08-REGRESSION-CHECKLIST.md, taken from items (P1) to (P6) consolidated in 08-31-SUMMARY.md.
