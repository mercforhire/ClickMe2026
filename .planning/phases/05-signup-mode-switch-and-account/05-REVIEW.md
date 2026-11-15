---
phase: 05-signup-mode-switch-and-account
reviewed: 2026-11-15T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - ClickMe2026/Network/Error+UserMessage.swift
  - ClickMe2026/Utils/ProfileSaveErrorMapper.swift
  - ClickMe2026/Utils/ProfileSettingsSnapshot.swift
  - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsView.swift
  - ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/ProfileLabeledField.swift
  - ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift
  - ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift
  - ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift
  - ClickMe2026Tests/Utils/ProfileSaveErrorMapperTests.swift
  - ClickMe2026Tests/Utils/ProfileSettingsSnapshotTests.swift
findings:
  critical: 1
  warning: 2
  info: 3
  total: 6
status: issues_found
---

# Phase 5: Code Review Report (incremental: plans 05-18, 05-19, 05-20)

**Reviewed:** 2026-11-15
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Scope was the diff from `23da555` to HEAD. The changed-group patch logic (`ProfileSettingsSnapshot.patch` and `merging`) holds up against the backend schema. `PATCH /user/profile` is `.strict()` with `min(1)` on both names, and the iOS body never emits an empty name or unknown keys. The `422` decoding in `validationFieldErrors` matches the backend envelope (`{status, message, errors[{field, message}], code}`) and branches on `ErrorCode`, not message text. The setup hub nav bar pins match the sibling signup screens. I found no problems in `ProfileLabeledField` beyond the accessibility note below.

One real defect in the expert screen: clearing the meeting link is silently lost and then reported as saved. Two robustness gaps are in the error mapping and in overlapping saves.

## Critical Issues

### CR-01: Clearing the meeting link is never sent, yet the screen shows "saved"

**File:** `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift:327-345` (and `performAutoSave` 351-376)
**Issue:** `makeExpertProfileUpdateBody()` turns an emptied link into `meetingUrl: nil`. `nil` is omitted from the JSON, so the request is `{"professional_details":{}}`. The server keeps the old link. `performAutoSave` then records `baselineMeetingUrl = ""`, refreshes the expert profile and shows the checkmark. The user sees "saved", but the link is still set. It reappears on the next `load()`.

The in-code comment says the server 422s on `""`. The backend no longer does. `expertProfile.schema.js` (BACK-04) accepts `""` and `null` explicitly so an expert can clear the link, and the controller stores both as NULL.

Before 05-19 the request was also dropped on clear. But the old code only baselined the whole snapshot. The new code sends a request with an empty `professional_details` object, treats it as a successful change and rebaselines. That makes the lost write permanent for the session, and it is the "silently dropping their actions" failure the project exists to fix.

**Fix:** Send `""` when the baseline held a link and the field is now empty. Verify BACK-04 is deployed to production first, because an older backend would 422 on `""`. If it is not deployed, show the user an explicit "can't clear yet" message instead of a checkmark.
```swift
func makeExpertProfileUpdateBody() -> UpdateExpertProfileRequest? {
    let link = trimmedMeetingUrl
    guard link != baselineMeetingUrl else { return nil }
    // BACK-04: "" clears the link; any other value must be a valid URL.
    return UpdateExpertProfileRequest(
        personalInfo: nil,
        professionalDetails: .init(jobTitle: nil, company: nil, education: nil, meetingUrl: link),
        locationDetails: nil, languages: nil, expertiseTags: nil
    )
}
```
Delete the stale "server 422s on empty" comment. Add a test that clearing a previously set link produces a body with `meeting_url == ""`.

## Warnings

### WR-01: `ProfileSaveErrorMapper` hides the useful message for expert-only 422 fields, and drops unmapped fields when any mapped one is present

**File:** `ClickMe2026/Utils/ProfileSaveErrorMapper.swift:22-44`
**Issue:** The label table only covers `PATCH /user/profile` paths. The expert screen also calls `PATCH /expert/profile`, whose invalid-link 422 has the field `professional_details.meeting_url`. The server's per-field message is "Meeting link must be a valid URL." That path is unmapped, so the mapper falls back to `userMessage`. The backend's top-level `message` on this envelope is the generic "Please check the information you entered and try again." (see `ProfileSaveErrorMapperTests.genericMessage`). The user is never told the meeting link is the problem, which is the exact complaint G-05-6 was meant to remove. Separately, if one 422 lists both a mapped and an unmapped field, only the mapped one is named and the other is dropped.
**Fix:** Add the expert path with the on-screen label to the table, in screen order. For example `("professional_details.meeting_url", "Meeting Link")`; use the label the expert screen shows. Add a mapper test for it. Consider appending a generic suffix, or falling back to the server text, when any field error is unmapped.

### WR-02: Overlapping auto-saves are not serialised

**File:** `ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift:273-336` and `ExpertProfileSettingsViewModel.swift:276-300, 351-376`
**Issue:** `scheduleAutoSave` cancels the pending debounce task, but a `performAutoSave` that is already awaiting the network is not cancelled. The request timeout is 120 s, so on a slow connection a second save can start while the first is in flight. The second `patch(from: baseline)` uses the baseline from before the first finished, so it resends the first save's groups. If the responses arrive out of order, `baseline.merging(body)` leaves the baseline holding the older values until the next edit. The `defer { isAutoSaving = false }` of the first save also clears the spinner while the second is still running. This is mostly pre-existing, but 05-19 made correctness depend on `baseline`, so its staleness now matters more.
**Fix:** Serialise saves. For example, return early from `performAutoSave` when `isAutoSaving` is true and re-run `scheduleAutoSave()` at the end of the in-flight save, or await the previous save task before starting the next.

## Info

### IN-01: Inconsistent whitespace trimming

**File:** `ClickMe2026/Utils/ProfileSettingsSnapshot.swift:52-59` vs `ExpertProfileSettingsViewModel.swift:~392`
**Issue:** The snapshot trims `.whitespaces`, which does not remove newlines. The meeting link trims `.whitespacesAndNewlines`. A pasted name or bio with a trailing newline is sent untrimmed, and one consisting only of a newline is treated as non-empty, so it is sent to the server. A name of only a newline would pass the iOS `isEmpty` guard and 422 on the backend. Use `.whitespacesAndNewlines` for the names at least.

### IN-02: The new inline error text has no accessibility treatment

**File:** `ClickMe2026/Views/Screens/Settings/Client Profile Settings/Subviews/ProfileLabeledField.swift:44-50`
**Issue:** The error text is a separate `Text` under the field. VoiceOver does not tie it to the text field, and the border colour change is the only other cue. Add `.accessibilityHint(error ?? "")` or an `accessibilityElement(children: .combine)` on the field container, so the "Please enter your first name." message is announced with the field.

### IN-03: Test and code hygiene

**Files:** `ExpertProfileSettingsViewModel.swift` (end of file), `ProfileSettingsSaveTests.swift:~205`
**Issue:**
- A trailing empty `// MARK: - Error mapping` section remains at the end of `ExpertProfileSettingsViewModel`. It is now dead, so remove it or move the mapping there.
- The expert tests cannot exercise `performAutoSave`, which is private and calls the shared `UserManager`'s real API. As a result, the expert-side behaviors changed by 05-19 and 05-20 have no automated coverage:
  - the two-call ordering,
  - the partial-failure baseline (profile saved, expert PATCH failed),
  - the mapped 422 text.

  Inject a refresher seam, or make the `userManager` dependency testable, so these paths can be tested. This is also what would have caught CR-01.

---

_Reviewed: 2026-11-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
