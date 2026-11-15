---
status: complete
phase: 05-signup-mode-switch-and-account
source: [05-VERIFICATION.md]
started: 2026-11-13T23:40:00Z
updated: 2026-11-15T03:49:38.756Z
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
result: skipped
reason: "skip" (no reason given)

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

## Summary

total: 6
passed: 3
issues: 2
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-05-1
  truth: "The setup hub's `Not now` button at the top left is clearly legible (UI-SPEC A1: quiet secondary style, but visible and tappable)"
  status: failed
  reason: "User reported: 1. Upon logging in to the unfinished setup account, the top-left button test is hard to see. The contrast is wrong."
  severity: cosmetic
  test: 1
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis

- gap_id: G-05-6
  truth: "Profile settings saves an edit (including clearing State/Province) and it persists after reopening, with no error, even when the profile is not yet complete"
  status: failed
  reason: "User reported: 22 fail Because the profile has not been completed yet, all saving actions fail on the screen."
  severity: blocker
  test: 6
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis
