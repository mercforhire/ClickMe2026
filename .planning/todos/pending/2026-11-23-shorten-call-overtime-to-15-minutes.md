---
created: 2026-11-23T22:45:00.000Z
title: Shorten call overtime to 15 minutes (iOS and Android, 1.2)
area: calls
severity: minor
files:
  - ClickMe2026/Utils/CallOvertimePolicy.swift:34
  - ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift:382
  - ClickMe2026/Views/Screens/Call/Calling/MeetingCallView.swift:207
  - ClickMe_Android app/src/main/java/com/uptrendinvestments/clickmeapp/managers/CallTimer.kt:12 (OVERTIME_CUTOFF_SECONDS = 3600L)
  - ClickMe_Android app/src/test/java/com/uptrendinvestments/clickmeapp/managers/CallTimerTest.kt:91
  - ../ClickMe2026 Backend/docs/ios/CALL-END-SEMANTICS.md
---

## Problem

User decision 2026-11-23, during the 08-22 R1 run on build 1.1 (7): one hour of overtime after a session's scheduled end is too much. Change it to 15 minutes. Timing (user choice): **next release, 1.2**. 1.1 (7) ships as tested with the 60-minute cutoff (CALL-01), and R1 is still run to end + 60 on build 7.

Today `CallOvertimePolicy.cutoff = 60 * 60` and `warningLead = 5 * 60`: notice "This call will end in 5 minutes" at end + 55, auto-end at end + 60. Android mirrors it with `OVERTIME_CUTOFF_SECONDS = 3600`.

## Solution

Not built. Set the cutoff to 15 minutes, which with the 5-minute lead gives the notice at end + 10 and the auto-end at end + 15, on iOS and Android together.

- **Update the doc comment.** `CallOvertimePolicy.swift` says "The cutoff must stay at 60 minutes" because the server accepts `/end` `completed` until end + 70 and the Agora token expires at end + 70. 15 minutes is inside both, so lowering it is safe. Raising it never was.
- **Check against backend Sweep B.** Sweep B completes and captures the booking at end + 15 (`call.controller.js:270`). Make sure ending the call at end + 15 doesn't race the sweep: `/end` on a booking that's already completed is accepted until end + 70, per CALL-END-SEMANTICS.md.
- **Backend doc.** CALL-END-SEMANTICS.md might need a wording change. No backend code change is expected.
- **Tests.** Update iOS `CallOvertimePolicy` and the boundary tests, and Android `CallTimerTest` (3600 becomes 900; keep the "not the old 5-minute value" test).
- **Copy.** Check for copy that names one hour: overtime notices, FAQ and policy text.
- **Device check.** Confirm the notice at end + 10 and the auto-end at end + 15.
