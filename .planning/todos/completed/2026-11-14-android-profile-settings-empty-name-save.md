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

## Resolution

Done by plan 08-06, in the Android repo on `main` (local only, not pushed): `9ce71b80` "fix(ios-p8): never send an empty profile name (iOS G-05-6 parity)" and `337f4c0c` "fix(ios-p8): profile save 422 names the fields to check (iOS G-05-6 parity)".

- `buildProfilePatch` never sends an empty `first_name` or `last_name`; the `basic` group goes out only when a non-empty name changed or the bio changed. Only changed groups are sent, as before.
- Both the client and the expert view model hold a cleared set name (the server keeps its value) and show "Please enter your first name." / "Please enter your last name." under the field. An account whose name is empty on the server shows no message.
- New `ProfileSaveErrorMapper`: a 422 VALIDATION_ERROR reads "Check {fields}, then try again." with the iOS labels and screen order (First Name, Last Name, Bio, Job Title, Company, City, State/Province, Country, Spoken Languages). The raw server text is never shown. A 422 without the `VALIDATION_ERROR` code, and every other failure, keep the previous handling.
- The alert text is built in the mapper rather than in a string resource, because the view models have no `Context` and `FieldError.Res` takes no format arguments. The two name-required messages are string resources.
- Full Android unit run: 5369 tests, 0 failures, ktlint clean.

Device check: 08-REGRESSION-CHECKLIST.md Android section. Nothing here was run on an Android device.
