---
phase: 05-signup-mode-switch-and-account
plan: 04
subsystem: signup
tags: [swiftui, signup, publish, profile-photo, province, country-code, location-formatter, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: no code dependency (wave 1)
provides:
  - SignupAccumulator.missingForPublish ([ChecklistItemKind], checklist order, never .verifyEmail) and isReadyToPublish == missingForPublish.isEmpty, photo required
  - Publish shows "Finish these first: Add profile picture." and sends no request when something is missing
  - Province/State optional in readiness, the Personal details row and the publish body; country_code normalized on publish
  - SignupBasicInfoViewModel province-clear rule (empty string only when a province that existed at open was emptied) and "Province/State (optional)" placeholder
  - LocationFormatter.format(city:province:country:), used by the signup review and ClientProfilePersonalInfo
  - SignupAccumulatorTests (12), SignupBasicInfoProvinceTests (4), LocationFormatterTests (6 test functions, 12 cases with arguments)
affects: [05-11 (SIGN-02 edits SignupAccumulator.swift next), 05-09 (settings half of D-07), 05-DEVICE-UAT-CHECKLIST]

actuals:
  tokens: 4700
  tasks: 3
  commits: 3
plan_head_before: 581de0a2740bebd928ea4d1b7ee70b4445e3e99d
plan_head_after: 0a24d98e09d4d8adf757f418f53df4f1ffce7600

tech-stack:
  added: []
  patterns:
    - "Pure caseless-enum formatter in Utils/ that every screen shares, instead of per-screen private helpers"
    - "Accumulator exposes a typed list of what is missing; the review view model maps it to the Overview checklist titles"

key-files:
  created:
    - ClickMe2026/Utils/LocationFormatter.swift
    - ClickMe2026Tests/Signup/SignupAccumulatorTests.swift
    - ClickMe2026Tests/Signup/SignupBasicInfoProvinceTests.swift
    - ClickMe2026Tests/Utils/LocationFormatterTests.swift
  modified:
    - ClickMe2026/Views/Screens/Signup Flow/SignupAccumulator.swift
    - ClickMe2026/Views/Screens/Signup Flow/Signup Review/SignupReviewViewModel.swift
    - ClickMe2026/Views/Screens/Signup Flow/Basic Info/SignupBasicInfoViewModel.swift
    - ClickMe2026/Views/Screens/Signup Flow/Basic Info/SignupBasicInfoView.swift
    - ClickMe2026/Views/Screens/Expert Mode/Client Profile/Subviews/ClientProfilePersonalInfo.swift

key-decisions:
  - "Photo is a client-side pre-check only: the server 422 stays the enforcer, iOS just avoids a doomed request"
  - "Basic Info completeness (hasBasicInfo) trims first name and city and requires Countries.normalize(countryCode) != nil, so a whitespace-only city or an unknown country now reads incomplete"
  - "A cleared province is sent as province_state \"\" only if the accumulator held a province when the screen opened (provinceAtOpen); a never-set empty field sends no key"
  - "An unknown country code in LocationFormatter is shown as given rather than hidden"

requirements-completed: [SIGN-01, SIGN-04]

coverage:
  - id: D1
    description: "Publish is not offered as ready without a profile photo; Publish names the missing step and sends no request"
    requirement: "SIGN-01"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SignupAccumulatorTests.swift#noPhotoIsNotReady, photoMakesItReady, emptyPhotoUrlIsMissing, unverifiedEmailIsNotMissing, missingItemsAreInChecklistOrder, publishWithoutPhotoSendsNothing"
        status: pass
    human_judgment: false
  - id: D2
    description: "The publish body carries the normalized alpha-3 country code; an unrecognised or empty code makes the profile not ready and lists basic info"
    requirement: "SIGN-04"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SignupAccumulatorTests.swift#countryCodeIsNormalized, badCountryCodeIsNotReady, publishBodyOnTheWire"
        status: pass
    human_judgment: false
  - id: D3
    description: "Province is optional in readiness, the checklist row and the publish body (no key when empty, trimmed when set)"
    requirement: "D-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SignupAccumulatorTests.swift#emptyProvinceIsReady, blankCityIsMissing, provinceInPublishBody, publishBodyOnTheWire"
        status: pass
    human_judgment: false
  - id: D4
    description: "Basic Info clears a province only when one existed at open; otherwise an empty field sends no key"
    requirement: "D-07"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Signup/SignupBasicInfoProvinceTests.swift#clearedProvinceSendsEmptyString, untouchedEmptyProvinceSendsNothing, whitespaceProvinceIsEmpty, typedProvinceIsSent"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every location label is City, Province, Country with absent parts dropped and no stray comma"
    requirement: "D-06"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/LocationFormatterTests.swift#absentProvince, withProvince, trimsAndNormalizesCountry, unknownCountryShownAsGiven, missingCity, nothingIsNil"
        status: pass
    human_judgment: false
  - id: D6
    description: "The 'Province/State (optional)' placeholder and the on-screen Publish message read correctly on a device"
    requirement: "SIGN-01"
    human_judgment: true
    rationale: "Layout and wording on a real screen are not asserted by a unit test; belongs on the device UAT checklist"

duration: 13 min
completed: 2026-11-13
status: complete
---

# Phase 05 Plan 04: Signup publish rules, optional province, one location formatter Summary

**Publish now follows the server's rules: a photo is required (and named when missing), the country goes out as a normalized alpha-3 code, the province is optional and clearable, and every location label comes from one `LocationFormatter`.**

## Accomplishments

- **SIGN-01 (tracer, Task 1).** `SignupAccumulator.missingForPublish` lists the blocking checklist steps in order (`.basicInfo`, `.timezone`, `.profilePicture`, `.expertise`) and never `.verifyEmail`, matching Android `SignupDraft.missingForPublish`. `isReadyToPublish` is exactly `missingForPublish.isEmpty`. `SignupReviewViewModel.publish()` shows "Finish these first: Add profile picture." using the Overview checklist titles and sends nothing. Before the change the RED run showed the doomed PATCH actually going out.
- **SIGN-04 and D-05 (Task 2).** A private `hasBasicInfo` (trimmed first name and city, `Countries.normalize(countryCode) != nil`, languages) drives both `checklist.basicInfo` and the `.basicInfo` entry. The publish body sends `Countries.normalize(countryCode)` (`"ca "` becomes `"CAN"`) and omits `province_state` when empty.
- **D-07 signup half (Task 2).** `SignupBasicInfoViewModel` captures `provinceAtOpen`; `save()` sends the trimmed province, or `""` only when it was emptied after opening with a value, otherwise no key. Placeholder is now "Province/State (optional)".
- **D-06 (Task 3).** `LocationFormatter.format(city:province:country:)` trims, drops empty or whitespace-only parts, names a known country (alpha-2 normalized first), shows an unknown one as given, and returns nil when nothing is left. The private `formatLocation` is deleted.

## Location sites

Re-ran `grep -rn 'stateProvince\|provinceState\|state_province' ClickMe2026 --include=*.swift` plus a search for other location rendering (`.city`, `Countries.find`, `mappin`, `locationLabel`). Display sites:

| Site | Uses now |
|------|----------|
| Signup review card (`SignupReviewViewModel.profile`) | `LocationFormatter.format` |
| Expert-side client profile "Location" row (`ClientProfilePersonalInfo.locationLabel`, fed by `ClientProfileView`) | `LocationFormatter.format` |

Not display sites, left alone: `ClientProfileSettingsViewModel` and `ExpertProfileSettingsViewModel` (edit forms; they read and send `stateProvince`, covered by plan 05-09), `ProfileCountryField` (a country picker row, not a location label), `ExpertTaxProfileView` (a tax address form), and the response and request models. This agrees with RESEARCH R7: no expert-card or public expert-profile location rendering exists in iOS. No extra site was found, so none was switched.

## Task Commits

1. **Task 1 (tracer): photo required to publish** - `db670e3` (fix)
2. **Task 2: province optional and clearable, country normalized** - `7a5fe53` (fix)
3. **Task 3: one location formatter** - `0a24d98` (fix)

Metadata commit (SUMMARY, STATE, ROADMAP, REQUIREMENTS) follows this file.

## TDD notes

The plan is `type: execute` with `tdd="true"` tasks and prescribes one `fix(05-04)` commit per task, so RED and GREEN share a commit per task rather than the `test`/`feat` split. RED was still run and checked for each task before implementing:

- Task 1: an empty `missingForPublish` stub (a missing symbol would be a build failure, not RED). 7 issues on the planned assertions, including `recordedRequests` non-empty (the doomed PATCH being sent).
- Task 2: unchanged production code. 21 issues across the two suites, all planned assertions.
- Task 3: a nil-returning formatter stub. 9 issues on the planned assertions.

## Verification

| Check | Result |
|-------|--------|
| `SignupAccumulatorTests` | 12 tests passed |
| `SignupBasicInfoProvinceTests` | 4 tests passed |
| `LocationFormatterTests` | passed (log `/tmp/05-04-t3.log`) |
| Regression: `SelectionOrderTests`, `SignupProfilePhotoSaveTests` | 14 tests passed |
| Task 1 / 2 / 3 grep gates and acceptance criteria | all pass (`Finish these first` count 2, baseline 0) |
| Build gate, warnings in the six app files vs baseline | BUILD SUCCEEDED; baseline 0 warnings, after 0 warnings |

Not run: `LoginTests`, `AuthSmokeTests`, `SignupSmokeTests` (excluded by the plan's own command; they hit the network).

## Deviations from Plan

None - plan executed exactly as written.

Small additions inside the plan's intent, not deviations: extra test rows beyond the listed behavior (blank city, whitespace province, empty photo URL, checklist order, and a wire-level publish body test that asserts `country_code` and the absence of `province_state` on the actual request).

## Issues Encountered

- `ClickMe2026/Localizable.xcstrings` carried pre-existing uncommitted edits before this run. This plan did not stage it. The new "Province/State (optional)" and "Finish these first: ..." strings are plain literals; whether Xcode later extracts them into the catalog is untouched here.

## Known Stubs

None. (The two temporary RED stubs were replaced before each commit.)

## Threat Flags

None. No new endpoint, auth path or schema; T-05-08 (malformed country code) is mitigated by `Countries.normalize` on publish, and T-05-07 stays accepted (the server 422 is the enforcer).

## Next Phase Readiness

Plan 05-11 (SIGN-02) edits `SignupAccumulator.swift` next and can build on `missingForPublish` and `hasBasicInfo`. Plan 05-09 owns the settings half of D-07. Device check for the placeholder text and the Publish message belongs on the UAT checklist.

## Self-Check: PASSED

- Created files exist: `LocationFormatter.swift`, `SignupAccumulatorTests.swift`, `SignupBasicInfoProvinceTests.swift`, `LocationFormatterTests.swift`.
- Commits `db670e3`, `7a5fe53`, `0a24d98` are ancestors of HEAD; measured count `581de0a..HEAD` is 3.
- No unintended deletions in any task commit.
