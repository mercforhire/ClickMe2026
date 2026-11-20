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

## Phase 8 answers

Read from the Android source by plan 08-12 (nothing was run on an Android device). The todo stays pending: plan 08-26 asks the user to port, defer or accept each `differs` row, and to decide each `device check needed` row, before it closes.

- Tag and language tap order: matches (SignupTagsViewModel.selected, SignupBasicInfoViewModel.toggleLanguage, ClientProfileSettingsViewModel.applyLanguages, and SignupSetupRepository.listFieldFor sends tap order, so the first tag is primary)
- Crop on upload: matches (AndroidPhotoProcessor.cropToJpeg draws the chosen square, PhotoMath.outputSide caps it at 1024 px, import applies the EXIF rotation and the JPEG re-encode carries no source metadata; CropMathTest and PhotoCropCircleRegressionTest cover the crop)
- Photo required to publish: differs: Android disables Publish and shows "Still needed: profile picture." when the photo is missing, so no request is sent (SignupDraft.missingForPublish, SignupReviewScreen); iOS leaves the button usable and refuses with "Finish these first: Add profile picture."
- Country normalized on publish: matches (SignupSetupRepository publish sends Countries.normalize, so "ca " becomes "CAN")
- Province optional and clearable: matches (SignupSetupRepository.saveBasicInfo omits a blank province and sends "" for a cleared one; ProfileSnapshot.locationBody always sends the trimmed string, never null; SignupReviewViewModel.reviewLocation skips an empty one)
- City, Country location label: matches (SignupReviewViewModel.reviewLocation drops an empty province, no stray comma, and Countries.displayName returns an unknown code as given)
- Notification preferences save on open: matches (NotificationSettingsViewModel hydrates through AutoSaver.rebase, so opening the screen sends no PATCH)
- Feedback minimum: differs: Android sends nothing under 10 trimmed UTF-16 characters and keeps the text, as iOS, but the message reads "Please describe your experience in at least 10 characters." where iOS reads "Please enter at least 10 characters."
- One support address: matches (AppLinks.SUPPORT_EMAIL is the only address in app/src/main, used by Help and the suspension dialog)
- Settings language save: differs: language_ids and custom_languages go together and only when the selection changed (matches iOS), but Done with nothing selected on Android sends an empty list and the server deletes every language, while iOS keeps the previous list and shows "Keep at least one language." (ClientProfileSettingsViewModel.applyLanguages and ExpertProfileSettingsViewModel.applyLanguages have no guard)
- Resume keeps the verified email: differs: the hub re-reads GET /auth/email/status on every appearance (SignupOverviewViewModel.onShown), but SignupSetupRepository.mergeStatus overwrites the local flag, so a stale "not verified" answer could untick Verify email, while iOS never downgrades a local success
- Expert-mode gate and Not now: device check needed: with an unfinished expert account, tap an expert-targeted push and see the notifications list open instead of the setup hub; tap a push for the other mode during a call and see it wait until the call ends with no mode switch; relaunch and foreground a client-only account and see it stay client-only

## Phase 8 decisions

Recorded by plan 08-26 from the user's message of 2026-11-20: "Since the iOS store review has still not been completed, let's continue to do the Android fixes." That message is read as a port request for each `differs` row. Port work is planned separately (`/gsd-plan-phase 08 --gaps`); the gap plan that lands a port rewrites its line to `ported (<Android SHA>)`.

The `Expert-mode gate and Not now` row (device check needed) was decided separately: the message above does not cover it, so plan 08-26 asked the user, who answered on 2026-11-20 to close it now. Its device step stays in the Android section of 08-REGRESSION-CHECKLIST.md, and a difference found there becomes a new todo.

- Photo required to publish: port requested (user, 2026-11-20)
- Feedback minimum: port requested (user, 2026-11-20)
- Settings language save: port requested (user, 2026-11-20)
- Resume keeps the verified email: port requested (user, 2026-11-20)
- Expert-mode gate and Not now: closed, device step in the regression checklist Android section (user, 2026-11-20)
