---
created: 2026-11-23T23:59:30.000Z
title: Triage the open Phase 2 and Phase 5 code-review findings for 1.2
area: general
severity: minor
files:
  - .planning/phases/02-shared-ios-plumbing/02-REVIEW.md
  - .planning/phases/02-shared-ios-plumbing/02-REVIEW-DISPOSITION.md
  - .planning/phases/05-signup-mode-switch-and-account/05-REVIEW.md
  - .planning/phases/05-signup-mode-switch-and-account/05-REVIEW-DISPOSITION.md
---

## Problem

The review disposition files for Phases 2 and 5 still list 15 findings as `open` with no reason. On 2026-11-23 (plan 08-24) the user chose, verbatim: "Defer all to 1.2 (Recommended)". Each one is recorded in `08-RELEASE-RECORD.md` ## Closeout as "deferred to 1.2: not release-blocking, build 7 frozen (user decision 2026-11-23)".

Phase 2 (`02-REVIEW.md`):

- WR-03: Typed topic price is always multiplied by 100, ignoring the currency's digits, and can overflow. `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift`
- WR-04: `PI_CURRENCY_MISMATCH` is declared but not handled in the paid-booking error path. `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, `ClickMe2026/Model/Enums/ErrorCode.swift`
- IN-01: Dead production helper and stale "hide" wording after the dim-not-hide decision. `ClickMe2026/Utils/PaidBookingWindow.swift`
- IN-03: Currency symbol is "US$" on the price label and "$" in the hint, on the same screen. `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift`, `Money.swift`

Phase 5 (`05-REVIEW.md`; the PRIOR-* items come from the earlier review at `23da555`, carried as prior findings since review `5cee2da`):

- WR-01: Reload overwrites the field and baseline from a possibly stale cached profile. `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift`
- WR-02: A 422 on the meeting link still shows the generic message. `ClickMe2026/Utils/ProfileSaveErrorMapper.swift`
- WR-03: Overlapping auto-saves are not serialised. `ExpertProfileSettingsViewModel.swift`, `ClientProfileSettingsViewModel.swift`
- IN-01: `meetingLinkBody` trims the baseline redundantly. `ExpertProfileSettingsViewModel.swift`
- IN-02: The `forceLoad` wiring is untested. `ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift`
- IN-03: Leftover dead section and unchanged prior Info items. `ExpertProfileSettingsViewModel.swift`, `ClickMe2026/Utils/ProfileSettingsSnapshot.swift`, `ProfileLabeledField.swift`
- PRIOR-WR-03: A push-initiated Expert switch clears the user's "Not now" deferral. `ClickMe2026/Managers/UserManager.swift`
- PRIOR-WR-04: A wrong password on `delete-request` triggers a token refresh and a second request. `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift`, `NetworkService.swift`
- PRIOR-WR-05: `loadExistingAvatarIfNeeded` can overwrite a photo the user picked while it downloads. `ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoViewModel.swift`
- PRIOR-WR-06: Flipping a notification toggle back during an in-flight save cancels it and skips the resave. `ClickMe2026/Views/Screens/Settings/Notifications/NotificationSettingsViewModel.swift`
- PRIOR-IN-04: `RememberedLoginEmailTests` mutates the real Keychain through the singleton. `ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift`

## Solution

At the start of 1.2, re-read each finding against current `main`. Later work may already have fixed some of them, for example Phase 2 WR-03 and IN-03, which sit near the Phase 6 EXP-02 decimal pricing and the 08-10 US$ change. Then record a disposition for each in its `*-REVIEW-DISPOSITION.md`: fixed (with the commit), deferred with a reason, or accepted. Fix any warning that still reproduces, with a unit test where the logic is testable. Check Android parity for behavior changes.
