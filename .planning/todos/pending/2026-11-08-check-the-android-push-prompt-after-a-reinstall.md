---
created: 2026-11-09T04:46:57.475Z
title: Check the Android push prompt after a reinstall
area: general
severity: minor
files:
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/push/PushPermissionRequester.kt
  - .planning/quick/261108-vrh-prompt-for-push-permission-on-every-sign/261108-vrh-SUMMARY.md:60
---

## Problem

`PushPermissionRequester.kt` prompts once after a login or signup, using a persisted flag. iOS had a gap here that quick task 261108-vrh fixed by asking on every signed-in launch, and Android may have a similar one. It depends on whether Android's session and "already asked" flag survive a reinstall, which has not been checked.

## Solution

TBD. Check first, on a device if needed: reinstall while signed in, then see whether the prompt appears. If the gap is real, fix it in the Android repo (separate commit there).
