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
