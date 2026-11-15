---
status: complete
phase: 05-signup-mode-switch-and-account
source: [05-VERIFICATION.md]
started: 2026-11-13T23:40:00Z
updated: 2026-11-15T19:56:01.903Z
---

## Current Test

[testing complete]

## Tests

### 1. SIGN-06 end to end on a device (05-DEVICE-UAT-CHECKLIST.md items 1 to 17)
expected: The setup hub opens for an unfinished expert and a finished expert enters Expert. Airplane mode fails open, including right after Publish. No mode switch happens during a call. A push for the other mode waits until the call ends. The foreground re-check opens the hub.
result: issue
reported: "1. Upon logging in to the unfinished setup account, the top-left button test is hard to see. The contrast is wrong."
severity: cosmetic
note: Checklist item 1 / item 5 (hub after a login). Screenshot shows the hub opened at 80% with Add profile picture unticked, `Not now` at top left and no back chevron; the `Not now` label is pale grey-green text on a light grey glass capsule, so it barely reads. Checklist items 1 and 2 otherwise PASS, item 3 PASS, item 4 steps 1-2 PASS, item 4 step 3 PASS (unfinished expert published, then offline Mode Switch entered Expert home; dashboard showed the expected offline "Couldn't load dashboard" + Retry state). The unfinished account is now published; items 5-10, 14, 15, 17 need it reset or the second unfinished account. Items 5, 6, 7, 8, 9, 15 PASS (2026-11-14; item 15 confirms RESEARCH A6, App-level scenePhase re-check fires). Item 14 PASS (backend agent sent an expert-targeted push to the unfinished account; tapping it opened the notifications list, not the hub). Item 17 SKIPPED (optional per checklist; needs a booked live call on the unfinished account; items 11 and 13 cover in-call behavior). Item 10 PASS. Item 16 steps 1-3 PASS (client-only account A not promoted by launch, offline launch or foreground); step 4 (explicit Expert tap on throwaway) RECORDED: the setup hub opened; app stays in Client mode until setup is published (user observation). Server-side promotion (roles/expert_profiles row) not yet confirmed by a backend read. Item 11 PASS (all four Mode Switch entries blocked during a call). Item 13 PASS (expert-targeted push tapped during a call deferred until call end, then switched and opened once). Item 12 SKIPPED (optional per checklist; Network Link Conditioner not set up). Test 1 closed: all 17 items run or skipped; only issue is G-05-1.

### 2. SET-06 legibility: Settings > Delete Account on a small iPhone and at the largest Dynamic Type size, scrolled to the bottom of the confirmation step
expected: All three groups, including the last "Kept" group (messages, reviews, payment records), can be read in full and are not covered by the pinned Delete and Cancel buttons. If the "Kept" group is hidden, record it as a gap; the fix is a bottom `safeAreaInset` (05-UI-REVIEW.md).
result: pass
note: Skipped on first run ("skip", no reason given). The same check was re-run as test 8 on the plan 05-22 build and passed on 2026-11-15; this result rests on that run.

### 3. SET-02: Help > Email Us on a device with Mail set up
expected: The default mail app opens addressed to clickmeapp@uptrendinvestments.net.
result: pass

### 4. SIGN-05: pick a camera-roll photo, zoom in on the slider, Save, then view the public avatar
expected: The uploaded avatar looks like the preview circle.
result: pass

### 5. SET-07: from both the Bookings tab and a Home-route cancel, tap "Cancellation policy" on the cancel confirmation, then Back
expected: The policy opens, and Back returns to the confirmation with its state intact.
result: pass

### 6. Remaining items in 05-DEVICE-UAT-CHECKLIST.md (SIGN-02 quit and relaunch, SET-01 reopen after a language edit, SET-06 409 blocker alerts, T8 pre-filled email, KEEP or CHANGE on assumptions A9, U2, U3, U4 and A1)
expected: Each item matches its Expected block in the checklist.
result: issue
reported: "22 fail Because the profile has not been completed yet, all saving actions fail on the screen."
severity: blocker
note: Checklist item 22 (D-07 clear province in profile settings). Screenshot - client Profile Settings for a fresh, unfinished expert signup (First/Last Name, City, Country, languages empty; State/Province "Ontario"). Any save shows the alert "Couldn't save changes / Please check the information you entered and try again." with no field named. Province clearing could not be tested.
progress: Items 18, 20, 21 PASS (2026-11-14). Item 22 ISSUE (G-05-6) on an incomplete profile; item 22 PASS when retested on a complete profile (province clear persists). Items 23, 25, 26 PASS. Item 28 A9 decision: KEEP (settings never saves an empty language list). Item 27 (optional) not reported. Items 29, 30, 32, 34 (copy; Dynamic Type part was test 2, skipped), 35 PASS. Item 36 U3 decision: KEEP (no saved-card claim this release). Items 37, 38, 39, 43 PASS. Item 44 U2 decision: KEEP (text-height tap target). Item 46 A1 decision: KEEP (quiet secondary style; G-05-1 fixes only legibility). Items 40, 33, 47 PASS (throwaway deleted; Login email cleared). Item 27 (optional) not run. Test 6 closed: only issue is G-05-6. Items 24, 45 SKIPPED (no reason given; would need another unpublished expert signup; U4 decision left open). Remaining: 22, 23, 25-30, 32-40, 43, 44, 46, 47 (27, 29, 47 optional; 28, 36, 44, 46 are KEEP/CHANGE decisions).

### 7. G-05-1 re-test: the setup hub's `Not now` is legible (checklist item 46, re-test block; plan 05-18)
expected: On an iPhone on iOS 26 (build at or after 0d44688), open the setup hub for an unfinished expert in Light + Reduce Transparency, then Liquid Glass Tinted, then Dark. In every case `Not now` is pale text on a dark capsule (never light grey), reads clearly, sits top left at body size, is not accent green, has no back chevron. Tapping it lands on client home.
result: pass

### 8. SET-06 legibility re-test: Delete Account confirmation clears the pinned buttons (checklist item 34, re-test block; plan 05-22; replaces skipped test 2)
expected: On the smallest iPhone available (build at or after 01e55f4), Settings > Account > Delete Account with a throwaway account, at default and at the largest Dynamic Type size, scrolled to the bottom: the last line of the `Kept` group is fully visible above the red `Delete Account` and `Cancel` buttons, and no group is cut off. Cancel closes the screen; Delete Account opens the feedback step. Nothing is deleted.
result: pass

### 9. G-05-6 re-test: Profile Settings saves on an empty-name profile (checklist item 22, re-test block; plans 05-19, 05-20)
expected: On a build at or after a0310ca, with an empty-name account: clearing State/Province, editing Bio and changing languages in client Profile Settings each save with no "Couldn't save changes" alert and persist after reopening. On an expert with an empty Last Name, City and Skype / Zoom link edits save and persist. Clearing a set First Name shows "Please enter your first name." in red under the field with no alert, City still saves, and reopening shows the old first name. A9 unchanged (empty language Done shows "Keep at least one language.").
result: pass

### 10. CR-01 re-test: a cleared Skype / Zoom link stays cleared, and a reload shows the server's link (checklist section after item 47; plan 05-21)
expected: On a build at or after baad5a0 (production /health on a commit containing df7fb18): clearing the link saves with no alert and stays empty after reopening; typing a link back persists; on an expert with no link a City-only edit saves with no alert. With a second device: after the link is cleared there, pull to refresh here empties the field with no checkmark, and a later City edit keeps the link empty. Without a second device, steps 4 and 5 are SKIPPED (no second device).
result: pass

## Summary

total: 10
passed: 8
issues: 2
pending: 0
skipped: 0
blocked: 0

## Deferred Follow-Ups

<!-- Device checklist items (05-DEVICE-UAT-CHECKLIST.md) deferred by the user on 2026-11-15 -->
- test: checklist-12
  idea: "Mode Switch cards dimmed during a slow lookup (needs Network Link Conditioner; optional, unit-tested)"
  deferred_at: 2026-11-15
- test: checklist-17
  idea: "Foreground re-check never opens the hub over a live call (needs a booked live call on an unfinished expert; optional)"
  deferred_at: 2026-11-15
- test: checklist-24
  idea: "Resuming signup keeps the verified email ticked (needs another unpublished expert signup)"
  deferred_at: 2026-11-15
- test: checklist-27
  idea: "Profile with no languages shows Add languages and chips wrap (optional, unit-tested)"
  deferred_at: 2026-11-15
- test: checklist-45
  idea: "U4 Verify email flash on resume: decision KEEP for now; observe on a device with a fresh unpublished signup"
  deferred_at: 2026-11-15

## Gaps

- gap_id: G-05-1
  truth: "The setup hub's `Not now` button at the top left is clearly legible (UI-SPEC A1: quiet secondary style, but visible and tappable)"
  status: resolved
  resolved_by: 05-18-PLAN.md
  resolved_at: 2026-11-15
  reason: "User reported: 1. Upon logging in to the unfinished setup account, the top-left button test is hard to see. The contrast is wrong."
  severity: cosmetic
  test: 1
  root_cause: "OverviewNotNowChrome (SignupOverviewView.swift:143-162, plan 05-16) puts `Not now` in a .topBarLeading ToolbarItem with fixed Brand.onSurfaceVariant (#bacbbc) text but never pins the navigation bar's color scheme, unlike every sibling signup screen (e.g. SignupReviewView.swift:100-102) and the Settings screens. The app has no app-wide dark scheme (no UIUserInterfaceStyle, no root .preferredColorScheme), and the AppDelegate's opaque #131313 bar appearance paints only the background. On a device in Light appearance with opaque glass (Reduce Transparency; likely iOS 26.1 Liquid Glass 'Tinted'), the iOS 26 toolbar capsule resolves to #f2f2f2, giving 1.52:1 contrast. Default clear glass samples the dark content (9.25:1), which hid it in development. Simulator repro on iOS 26.5 SDK; tester's device appearance settings not confirmed."
  artifacts:
    - path: "ClickMe2026/Views/Screens/Signup Flow/Overview/SignupOverviewView.swift"
      issue: "OverviewNotNowChrome toolbar lacks .toolbarColorScheme(.dark) / .toolbarBackground pins; fixed light text relies on a dark capsule"
    - path: "ClickMe2026/Theme/Brand.swift"
      issue: "onSurfaceVariant #bacbbc is correct for the kept quiet style (A1 KEEP) but only legible on dark"
    - path: "ClickMe2026/ClickMe2026AppDelegate.swift"
      issue: "Global nav bar appearance pins background, not trait/color scheme (context, no change required)"
    - path: "ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift"
      issue: "Same latent pattern: Brand.primary Save button in an unpinned toolbar (lines 61-65, 244-266) — out of gap scope, note for planner"
  missing:
    - "Add the sibling-screen bar pins in OverviewNotNowChrome: .toolbarBackground(Brand.surface, for: .navigationBar), .toolbarBackground(.visible, for: .navigationBar), .toolbarColorScheme(.dark, for: .navigationBar)"
    - "Keep Brand.onSurfaceVariant and body font (A1 KEEP: quiet style unchanged)"
    - "Device re-check on an iPhone in Light appearance with Reduce Transparency or Liquid Glass Tinted"
  debug_session: ".planning/debug/not-now-button-low-contrast.md"

- gap_id: G-05-6
  truth: "Profile settings saves an edit (including clearing State/Province) and it persists after reopening, with no error, even when the profile is not yet complete"
  status: resolved
  resolved_by: 05-20-PLAN.md
  resolved_at: 2026-11-15
  reason: "User reported: 22 fail Because the profile has not been completed yet, all saving actions fail on the screen."
  severity: blocker
  test: 6
  root_cause: "Two conditions together. (1) iOS: makeProfileUpdateBody in ClientProfileSettingsViewModel.swift:308-331 (and ExpertProfileSettingsViewModel.swift:314-337) sends one whole-form PATCH on every edit and always includes basic.first_name and basic.last_name, so empty names go out as \"\" even for a province-only edit. (2) Backend: src/schemas/userProfile.schema.js has first_name/last_name z.string().min(1) (contradicting openapi/clickme-api.yaml, which has no minLength, and signup, which stores '' at auth.controller.js:604-605), so validation returns 422 VALIDATION_ERROR with errors[] on basic.first_name/basic.last_name and the generic summary message 'Please check the information you entered and try again.' (src/utils/errors.js:5). iOS Error.userMessage (Error+UserMessage.swift:22-30) shows only the top-level message and ignores errors[], so no field is named. Wider impact: no iOS signup step writes last_name (SetupExpertProfileRequest has no lastName), so every iOS-created account keeps last_name '' and any Profile Settings save fails until the user types a last name. Not a Phase 5 regression (since baseline df8d99e, present in App Store build 6). Reproduced locally against the backend's real validate middleware; production origin/main 28da165 matches."
  artifacts:
    - path: "ClickMe2026/Views/Screens/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift"
      issue: "Whole-form body (308-331) always sends empty first/last name; catch (~350) shows only userMessage"
    - path: "ClickMe2026/Views/Screens/Expert Mode/Settings/ExpertProfileSettingsViewModel.swift"
      issue: "Same whole-form body (314-337); meeting_url already uses the omit-empty fix (345-351) but names do not"
    - path: "ClickMe2026/Network/Error+UserMessage.swift"
      issue: "Ignores errors[] field list in 422 VALIDATION_ERROR, so the alert names no field"
    - path: "ClickMe2026/Model/Requests/SetupExpertProfileRequest.swift"
      issue: "No lastName, so iOS signups leave last_name '' (context)"
    - path: "ClickMe2026 Backend/src/schemas/userProfile.schema.js"
      issue: "min(1) on first_name/last_name with no custom message; out of sync with OpenAPI and signup default (optional additive backend change)"
  missing:
    - "iOS: send only changed groups (Android parity), and omit first_name/last_name when empty and unchanged from load"
    - "iOS: if the user clears a previously set name, show a local required-field error instead of sending"
    - "iOS: surface 422 errors[] field names (e.g. FieldValidationErrorResponse) instead of only the generic summary"
    - "Apply to both client and expert profile settings view models"
    - "Unit test: hydrate an empty-name profile, edit province/bio, mock returns 422 for empty names; assert the request omits empty names and the save succeeds"
    - "Optional backend (additive, Android-safe): custom min(1) messages; product decision on accepting '' for last_name; Android follow-up todo if backend changes"
  debug_session: ".planning/debug/profile-settings-save-fails-incomplete-profile.md"
