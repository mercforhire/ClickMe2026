---
created: 2026-11-13T00:00:00.000Z
title: Android Phase 5 parity check: other behavior changes iOS made
area: general
severity: medium
files:
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/signup
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/settings
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/push
  - .planning/phases/05-signup-mode-switch-and-account/05-UI-SPEC.md
---

## Problem

Android is a port of iOS, and iOS is the source of truth for behavior. Phase 5 changed several iOS behaviors that Android may or may not already match. Nothing here was verified on an Android device and no Android code was read for most rows; each row is a question to answer on a device (or by reading the Android code), not a known bug. The Delete Account copy, the 409 blocker alert, remember-login-email and the cancellation policy link have their own todos (`2026-11-13-android-delete-account-copy-and-blockers.md`, `2026-11-13-android-remember-login-email.md`, `2026-11-13-android-cancellation-policy-link.md`).

## What to do

For each row, check Android against the iOS behavior. If it already matches, record that and stop. If not, port it or log the difference.

| iOS change (plan) | What to check on Android |
|-------------------|--------------------------|
| Tag and language tap order (05-02, SIGN-03) | Expertise tags and languages are shown, accumulated and saved in the order tapped; the first expertise tag tapped is the primary tag the server stores |
| Crop on upload (05-03, SIGN-05) | The uploaded profile photo is the centred square the preview circle shows at the chosen zoom (not the whole original), upright, at most 1024 px, no source metadata (GPS) in the file |
| Photo required to publish (05-04, SIGN-01) | Publishing with no photo is refused on the device, naming the missing step ("Finish these first: Add profile picture."), with no request sent. Android's `SignupDraft.missingForPublish` is the model iOS followed |
| Country normalized on publish (05-04, SIGN-04) | The publish body carries the normalized alpha-3 code ("ca " becomes "CAN") |
| Province optional and clearable (05-04, 05-09; D-05, D-07) | Signup publishes with no province; clearing a province in settings sends an empty string (never null, which the server rejects with 422); every reader treats an empty value as none |
| "City, Country" location label (05-04, D-06) | A profile with no province reads "City, Country" with no stray comma; an unknown country code is shown as given |
| Notification preferences save on open (05-05, SET-04) | Opening Notification preferences sends no request until a toggle changes, even when the server has a row turned off |
| Feedback minimum (05-05, SET-05) | Feedback under 10 trimmed characters sends nothing, keeps the typed text and shows "Please enter at least 10 characters." Count in UTF-16 units (Kotlin `String.length`), as the server counts |
| One support address (05-05, SET-02) | Help > Email Us and the suspension notice both use `clickmeapp@uptrendinvestments.net` from one constant; no other address is spelled in the app |
| Settings language save (05-09, SET-01) | Client and expert profile settings send `language_ids` and `custom_languages` together (a full replace: omitting the customs deletes them); the languages group is sent only when the selection changed. Also the zero-language guard (UI-SPEC A9): the backend accepts an empty list and deletes every row, so Done with nothing selected should keep the previous list and show "Keep at least one language." |
| Resume keeps the verified email (05-11, SIGN-02) | After verifying the email, quitting mid-setup and relaunching, the setup hub shows Verify email ticked (iOS reads `GET /auth/email/status` on every hub appearance and never downgrades a local success) |
| Expert-mode gate and Not now (05-07, 05-10, 05-12, 05-16; SIGN-06, D-17, D-27) | Already on Android (`Not now`, `resolvePostAuthDestination`, `recheckSetupIfPending`). Parity check only: a push for the other mode never opens the hub (an expert-targeted push for an unfinished expert opens the notifications list); no mode switch is applied during a call and a push tapped during a call waits until it ends; a client-only account is never promoted by a launch or a foreground |

Two iOS-only changes need no Android work: `ReadyToStartCallView` was unreachable dead code and was deleted (05-17, D-13), and the iOS Pause Account card (05-15) should be confirmed absent on Android.
