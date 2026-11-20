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

## Phase 8 answers

Finding from the Android source (plan 08-12; nothing was run on a device): the iOS gap does not exist here. `allowBackup` is false and `backup_rules.xml` and `data_extraction_rules.xml` exclude every domain, so a reinstall wipes both the session (EncryptedSharedPreferences) and the "asked" flag (DataStore, `PushPreferences.notificationPromptAsked`). The user is signed out after a reinstall, logs in, `UserManager.sessionStarts` rises, the flag is false, and `PushPermissionGate` asks again (`PushPermissionRequester` shows the system prompt on the landing route). A cold-start session restore never prompts (`PushPermissionGate` states this), so a user who is already signed in and was never asked is not asked until their next login; that is the one remaining difference from iOS's ask on every signed-in launch.

- Push prompt after a reinstall: device check needed: on Android 13 or newer, sign in and deny the prompt, uninstall, reinstall, sign in again, and see the system notification prompt appear once more; also note that an already signed-in user who was never asked gets no prompt on a plain relaunch (for the 08-REGRESSION-CHECKLIST.md Android section, plan 08-24 closes this todo)
