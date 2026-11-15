---
phase: 05-signup-mode-switch-and-account
reviewed: 2026-11-15T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountView.swift
  - ClickMe2026Tests/Settings/ExpertMeetingLinkBodyTests.swift
  - ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift
  - ClickMe2026Tests/Settings/ProfileSettingsSaveTests.swift
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 5: Code Review Report (incremental: plans 05-21, 05-22)

**Reviewed:** 2026-11-15
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Scope was the diff from `5cee2da` to HEAD for the five listed files.

**CR-01 from the prior review is resolved.** I checked the backend contract directly. `src/schemas/expertProfile.schema.js:48-53` accepts `""` and `null` for `professional_details.meeting_url`, and `src/controllers/expert.controller.js:158-160` stores `meeting_url || null`. `meetingLinkBody(current:baseline:)` now sends `meeting_url: ""` when a set link is cleared. Every non-nil body carries the key, so `{"professional_details":{}}` can no longer be produced. Whitespace-only input trims to `""` and is treated as unchanged against an empty baseline. `UpdateExpertProfileRequest` is a plain `Encodable` with optionals, so `""` is encoded and `nil` is omitted, and the encode test confirms this with `.convertToSnakeCase`. The pure-function extraction keeps the tests free of `UserManager.shared`.

The 05-22 change is correct. `safeAreaInset(edge: .bottom, spacing: 0)` on the `ScrollView` makes the scroll content stop above the bar, and the removed `Spacer().frame(height: 80)` was the fixed value that the bar could outgrow. The unused `ZStack` and `VStack` wrappers are gone. I found no defects in `DeleteAccountView`.

The remaining concerns are in the reload half of CR-01. `loadedMeetingLink` treats a cached expert profile as the server's word, and that assumption does not always hold. Three prior findings are also still open, because their files were not touched by 05-21 or 05-22.

## Warnings

### WR-01: Reload overwrites the field and baseline from a possibly stale cached profile

**File:** `ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift:242-245, 261-264`
**Issue:** The doc comment on `loadedMeetingLink` says a held profile "is the server's word, because `refreshExpertProfile()` replaces it". That is only true when the refresh succeeds. `forceLoad` calls it with `try?`, and a failure leaves `userManager.expertProfile` at its previous value. The post-save refresh in `performAutoSave` (line 402) is also `try?`.

Failure scenario:
1. The user changes the link from A to B.
2. `PATCH /expert/profile` succeeds, so the server holds B.
3. The follow-up `refreshExpertProfile()` fails on a flaky connection, so the cache still holds A.
4. The user pulls to refresh and that refresh also fails.
5. `loadedMeetingLink` returns A, so the field shows A.
6. `baselineMeetingUrl` is set to A, so `scheduleAutoSave` sees no change and never corrects it.

The screen then shows a link the server no longer holds. The new nil to `""` mapping widens this. A cached nil from before the save now blanks a field that holds a freshly saved link.

A second path: a user with an edit still inside the 1.2 s debounce who pulls to refresh gets the field overwritten. `performAutoSave` then builds a nil body, and the edit is dropped without any message. Before 05-21 this happened only when the server value was non-nil. Now it also happens when the server value is nil.

**Fix:** Take the held profile only when this load's refresh actually succeeded.
```swift
let refreshed: Bool
do { try await userManager.refreshExpertProfile(); refreshed = true } catch { refreshed = false }
if refreshed {
    expertiseEntries = userManager.expertProfile?.expertiseTags ?? expertiseEntries
    meetingUrl = Self.loadedMeetingLink(from: userManager.expertProfile?.professionalDetails, current: meetingUrl)
    baselineMeetingUrl = trimmedMeetingUrl
}
```
Keep the existing behavior, which is silent and leaves the field and baseline untouched, when the refresh fails. Also skip the overwrite while `autoSaveTask` is pending or `isAutoSaving` is true. Add a row for the refresh-failed case. Update the doc comment so it no longer claims the held profile is always the server's word.

### WR-02: A 422 on the meeting link still shows the generic message (carried forward, prior WR-01)

**File:** `ClickMe2026/Utils/ProfileSaveErrorMapper.swift:22-32` (unchanged since the prior review)
**Issue:** The label table has no entry for `professional_details.meeting_url`. The backend refine now reports "Meeting link must be a valid URL." on that path, so a link typed without a scheme (for example `zoom.us/j/1`) gets the generic "Please check the information you entered" alert. The field is never named. The debounced save also runs after 1.2 s of typing pause, so an intermediate value can trigger this alert. 05-21 made this more visible because the clear path now depends on the same endpoint. Still open.
**Fix:** Add `("professional_details.meeting_url", "Skype / Zoom Meeting Link")` to `labelTable`, in screen order, and add a mapper test.

### WR-03: Overlapping auto-saves are not serialised (carried forward, prior WR-02)

**File:** `ExpertProfileSettingsViewModel.swift:380-408` and `ClientProfileSettingsViewModel.swift` (unchanged)
**Issue:** There is no guard against `performAutoSave` re-entering while a request is in flight. The `isAutoSaving` spinner is cleared by whichever save finishes first. 05-21 does not change this. It matters slightly more for the meeting link, because an A to "" clear followed by an immediate retype of A can race two PATCHes, and `baselineMeetingUrl` ends up as the last response to arrive, not the last edit. Still open.
**Fix:** Return early from `performAutoSave` when `isAutoSaving` is true and re-run `scheduleAutoSave()` after the in-flight save completes.

## Info

### IN-01: `meetingLinkBody` trims the baseline redundantly

**File:** `ExpertProfileSettingsViewModel.swift:365`
**Issue:** `baselineMeetingUrl` is only ever assigned trimmed values (init, `forceLoad`, `performAutoSave`), so trimming it again is harmless but hides the contract. The tests pass untrimmed baselines in some rows. Either keep the trim as a defensive measure or document that `baseline` must already be trimmed.

### IN-02: The `forceLoad` wiring is untested

**File:** `ClickMe2026Tests/Settings/ExpertMeetingLinkReloadTests.swift`
**Issue:** The rows cover the pure `loadedMeetingLink` and the body rule. They do not cover the call site in `forceLoad` (lines 242-245), which is where WR-01 lives. The new tests cannot catch a regression in how `forceLoad` uses the result, or the refresh-failed case. This is the same seam gap as prior IN-03. Inject a refresher closure into the view model so `forceLoad` and `performAutoSave` become testable.

### IN-03: Leftover dead section and unchanged prior Info items

**File:** `ExpertProfileSettingsViewModel.swift:435-436`; `ClickMe2026/Utils/ProfileSettingsSnapshot.swift:52-59`; `ProfileLabeledField.swift`
**Issue:** These items from the prior review are still open, because their files were not touched.
- The empty trailing `// MARK: - Error mapping` section is still there.
- The snapshot trims `.whitespaces` while the meeting link trims `.whitespacesAndNewlines`, so a name that is only a newline is treated as non-empty.
- The field error text still has no accessibility association.

---

_Reviewed: 2026-11-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
