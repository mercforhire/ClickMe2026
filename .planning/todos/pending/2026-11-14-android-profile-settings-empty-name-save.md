---
created: 2026-11-15T05:05:56.000Z
title: "Android: Profile Settings saves on an account with an empty name (port the G-05-6 iOS rules)"
area: general
severity: medium
files:
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ProfileSnapshot.kt
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings/clientprofilesettings/ClientProfileSettingsViewModel.kt
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsViewModel.kt
---

## Problem

Android's `buildProfilePatch` (`ProfileSnapshot.kt`) sends a changed basic group whole, so an edit to First Name or Bio on an account with an empty last name carries `last_name ""` and gets a 422 from the backend's `min(1)` rule. On a 422 Android shows the raw server text under the fields (`onSaveFailed`, `fieldForServerName` in the client view model; `onSaveFailed` in the expert one).

Evidence is a code read on 2026-11-14 in the debug session `.planning/debug/profile-settings-save-fails-incomplete-profile.md`. Nothing was verified on an Android device.

## What iOS now does (iOS is the source of truth)

- Only changed groups are sent.
- An empty name key is never sent.
- A cleared set name is held and shows "Please enter your first name." / "Please enter your last name." under the field.
- A 422 VALIDATION_ERROR alert reads "Check {fields}, then try again." with the label table and screen order from `ProfileSaveErrorMapper` (example: "Check First Name and Last Name, then try again."). The labels are First Name, Last Name, Bio, Job Title, Company, City, State/Province, Country, Spoken Languages.
- The raw server text is never shown.

## What to do

Port these rules to both Android settings screens, then check them on a device. No backend change is needed. The related backend decision (accepting an empty last name) is in `2026-11-14-backend-profile-name-validation.md`.
