---
created: 2026-11-15T06:30:00.000Z
title: "Android: clearing the expert meeting link is never sent (port the CR-01 iOS rule)"
area: general
severity: medium
files:
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsViewModel.kt
  - ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/expertmode/settings/ExpertProfileSettingsRepository.kt
---

## Problem

`onMeetingUrlChange` (L326-336) keeps the saved link in the saver snapshot whenever the trimmed text is empty or fails `isAllowedMeetingUrl`. Its doc (L321-325) says this is so the field "can neither wipe the link nor store a `javascript:` URL".

The save path sends only when L508 holds: `shouldSend && link.isNotBlank() && isAllowedMeetingUrl(link)`. Both of the last two conditions block a blank link:

- `link.isNotBlank()` drops a blank link.
- `isAllowedMeetingUrl(link)` rejects "" as well (`components/web/ExternalLinkLauncher.kt` L36-45 returns false when there is no colon).

So even a blank link that reached the snapshot would not be sent. `shouldSend` (L507) only compares the link with `savedMeetingUrl` and `rejectedMeetingUrl`.

`restoredOver` (L287-290) applies the same blank-keeps-the-server-link rule to text restored after a process recreation.

So a cleared link is never sent, and reopening shows the old one.

Evidence is a code read on 2026-11-15; nothing was verified on an Android device.

## Reload (checked, no Android change needed)

iOS also fixed a reload that kept a cleared link on screen (a server nil kept the field's old text). Android's load does not have that bug. `seed()` (L216-257) reads the link with `professional?.meetingUrl.orEmpty().trim()` (L220), so a server nil becomes "" for `savedMeetingUrl` (L241) and for the field (L244), unless text typed before a process recreation is restored. The screen loads on open and on Retry (`load()` L200-211, `retryLoad()` L214) and has no pull to refresh. Checked by reading the code on 2026-11-15.

## What iOS now does (iOS is the source of truth)

- When the server holds a link and the trimmed field is empty, iOS sends `PATCH /expert/profile` with `professional_details.meeting_url: ""`.
- An expert with no link never sends the key.
- A non-empty link is sent trimmed.
- A request never carries an empty `professional_details`.
- After a load, the field and its baseline are the server's link, with a nil read as "".
- The backend accepts "" and stores NULL (BACK-04, backend `df7fb18`; production `/health` reported `28da165`, which contains it, on 2026-11-15).

## What to do

- Let a blank field clear a saved link: in `onMeetingUrlChange` and `restoredOver`, let blank text enter the snapshot as "", and at L508 send "" when the link is blank and `savedMeetingUrl` is not. Keep `isAllowedMeetingUrl` (the `javascript:` guard) for non-blank text only.
- Make sure `updateMeetingUrl("")` sends "" rather than dropping it.
- Check on a device.
- No backend change is needed.

## Resolution

Done by plan 08-06, in the Android repo on `main` (local only, not pushed): `ad190070` "fix(ios-p8): clearing the expert meeting link sends meeting_url "" (iOS CR-01 parity)".

- A blank field over a saved link, typed or restored after process recreation, enters the saver snapshot as "" and `PATCH /expert/profile` sends `professional_details.meeting_url: ""`. An expert with no saved link never sends the key. A non-blank link is sent trimmed and still has to pass `isAllowedMeetingUrl`, so the `javascript:` guard is intact; only "" bypasses it (the backend stores NULL, BACK-04).
- `ExpertProfileSettingsRepository.updateMeetingUrl("")` needed no code change: Moshi writes "" as `""`, and the request always carries a non-null `MeetingUrlBody`. Its doc now says so.
- Tests in `ExpertProfileSettingsViewModelTest`: clear sends "", whitespace-only clears, no saved link sends nothing, trimmed send, `javascript:` after a clear is not sent, blank restored text is a clear, invalid restored text keeps the server link. Two older rows that asserted the bug (`invalidOrBlankLinkNotSent`, `blankMeetingLinkNeverSent`) were rewritten.

Device check: 08-REGRESSION-CHECKLIST.md Android section. Nothing here was run on an Android device.
