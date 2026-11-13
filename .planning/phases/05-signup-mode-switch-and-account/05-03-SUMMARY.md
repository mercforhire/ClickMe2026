---
phase: 05-signup-mode-switch-and-account
plan: 03
subsystem: signup
tags: [swiftui, signup, profile-photo, uikit, image-crop, swift-testing]

requires:
  - phase: 05-signup-mode-switch-and-account
    provides: plan 05-02 (no code dependency; same phase, wave 1)
provides:
  - ProfilePhotoCropper.squareCrop(_:zoom:maxSide:), a pure renderer of the centred square the preview circle shows
  - SignupProfilePhotoViewModel keeps the picked UIImage (pickedImage), exposes canZoom and usePickedImage(_:), and crops in save()
  - ProfilePhotoCropperTests (10 tests) and SignupProfilePhotoSaveTests (4 tests)
affects: [05-DEVICE-UAT-CHECKLIST SIGN-05 device row]

actuals:
  tokens: 5000
  tasks: 2
  commits: 2
plan_head_before: ecc10d15bff3a5ed54002eccf454a5968b0c4865
plan_head_after: 7f6659a79856135e01184d104ff004a0bbbd906e

tech-stack:
  added: []
  patterns:
    - "Pure enum renderer in Utils/ (UIGraphicsImageRenderer at scale 1) with the view model holding the source UIImage rather than pre-encoded bytes"

key-files:
  created:
    - ClickMe2026/Utils/ProfilePhotoCropper.swift
    - ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift
    - ClickMe2026Tests/Signup/SignupProfilePhotoSaveTests.swift
  modified:
    - ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoViewModel.swift
    - ClickMe2026/Views/Screens/Signup Flow/Profile Photo/SignupProfilePhotoView.swift

key-decisions:
  - "Crop rectangle is built from integers (side rounded, origin floored) instead of CGRect.integral, so it is always square and repeated crops of an odd-sized image give the same size"
  - "Zoom stays display-only for a downloaded avatar: canZoom is false without a newly picked photo, the slider is disabled, and Save keeps its no-op success"
  - "Re-rendering through UIGraphicsImageRenderer is the metadata drop (T-05-05); the GPS test asserts the input really carries GPS first"

requirements-completed: [SIGN-05]

coverage:
  - id: D1
    description: "Save uploads the centred square at side min(w, h) / (1 + zoom), capped at 1024 px, zoom clamped to 0...1"
    requirement: "SIGN-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift#landscapeZeroZoom, landscapeFullZoom, squareAdjacency, largePhotoIsCapped, zoomIsClamped, zoomedOutputShowsTheCentre"
        status: pass
    human_judgment: false
  - id: D2
    description: "A photo with an EXIF orientation is cropped on its upright pixels"
    requirement: "SIGN-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift#orientationIsApplied"
        status: pass
    human_judgment: false
  - id: D3
    description: "The original photo's GPS metadata is not in the uploaded avatar"
    requirement: "SIGN-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift#gpsMetadataIsDropped"
        status: pass
    human_judgment: false
  - id: D4
    description: "An image with no pixels uploads nothing and shows an error; a hydrated avatar uploads nothing and cannot be zoomed; a picked photo uploads once and sets the avatar URL"
    requirement: "SIGN-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift#emptyImageIsNil; ClickMe2026Tests/Signup/SignupProfilePhotoSaveTests.swift#saveUploadsOnce, emptyImageUploadsNothing, hydratedAvatarUploadsNothing, pickingEnablesZoom"
        status: pass
    human_judgment: false
  - id: D5
    description: "Repeated crops of an odd-sized image at the same zoom give the same output size"
    requirement: "SIGN-05"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift#oddSizeIsDeterministic"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real iPhone, a zoomed camera-roll photo uploads looking the same as the preview circle"
    requirement: "SIGN-05"
    verification: []
    human_judgment: true
    rationale: "Visual framing match between the SwiftUI preview and the uploaded avatar; checked on the device UAT checklist (05-DEVICE-UAT-CHECKLIST.md)"

duration: 12min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 03: Profile Photo Crop Summary

**Signup profile photo Save now uploads the centred square the preview circle shows (side min(w, h) / (1 + zoom), upright, at most 1024 px, JPEG 0.85, no source metadata) instead of the whole original.**

## Performance

- **Duration:** about 12 min
- **Completed:** 2026-11-13T17:46:00Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments

- `ProfilePhotoCropper` (new, `Utils/`) bakes the orientation into a scale-1 render, clamps zoom to 0...1, crops the centred integer square, scales it down to at most 1024 px and encodes JPEG at 0.85. It returns `nil` for an image with no pixels. The `///` doc ties the math to `ProfileAvatarRing`.
- `SignupProfilePhotoViewModel` holds the picked `UIImage` (`pickedImage`) in place of the old pre-encoded JPEG bytes. `loadSelectedPhoto()` now only decodes and calls `usePickedImage(_:)`. `save()` crops at the current `zoomScale`; no picked photo keeps the old no-op success, and a failed crop sets `saveError` ("Couldn't prepare this photo. Please choose another one.") with no request.
- `SignupProfilePhotoView` enables the zoom slider from `canZoom`, so a downloaded avatar is display-only.
- `ProfilePhotoCropperTests` (10 tests) and `SignupProfilePhotoSaveTests` (4 tests, serialized) cover size, clamping, centre content, orientation, GPS removal (with a non-vacuous input check), empty input, odd-size determinism, one upload on Save, and the hydrated-avatar no-op.

## Task Commits

1. **Task 1 (tracer): The uploaded photo is the square the preview shows** - `e8fe382` (fix)
2. **Task 2: Orientation, metadata, empty images and the hydrated avatar** - `7f6659a` (test)

## Verification

- Task 1: `ProfilePhotoCropperTests` 6 tests passed; `squareCrop(` appears in the view model, `pendingJpegData` 0 (baseline 4), `enum ProfilePhotoCropper` 1, `func usePickedImage` 1 (baseline 0).
- Tracer gate: end-of-phase mode, automated-only `<verify>`; passed on the committed tree, so expansion continued.
- Task 2: `ProfilePhotoCropperTests` 10 tests passed, `SignupProfilePhotoSaveTests` 4 tests passed; `isEnabled: viewModel.canZoom` 1 (baseline 0); `kCGImagePropertyGPSDictionary` 3 in the cropper tests.
- Build gate: `BUILD SUCCEEDED`, run twice, the second after touching the three app files so they recompiled. Warnings in `SignupProfilePhotoViewModel.swift`, `SignupProfilePhotoView.swift` and `ProfilePhotoCropper.swift`: 0 before, 0 after (`comm -13` empty).
- Device check still open: portrait camera-roll photo, zoom most of the way, Save, then compare the expert profile or Overview avatar with the preview circle (05-DEVICE-UAT-CHECKLIST.md).

## Deviations from Plan

None - plan executed exactly as written.

Notes: the plan names `.integral` for the crop rectangle. I built the rectangle from an integer side (rounded) and a floored origin instead, because `.integral` can return a non-square rectangle for odd sizes and the plan's own determinism truth needs a square, stable size. The plan prescribes one commit per task, so there is no separate RED commit; the test file for Task 1 was written alongside the cropper and passed on the first run, and Task 2's first run failed only on a Swift 6 isolation error in the test fixture (`uploadedUrl` made `nonisolated`). `gsd_run` was sourced from the job's `gsd.sh`.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. T-05-05 (EXIF GPS in the uploaded avatar) is mitigated and tested; T-05-06 (very large image) is mitigated by the 1024 px cap and JPEG 0.85.

## Working tree note

The working tree carried uncommitted edits before this run (`.DS_Store`, `.planning/config.json`, `ClickMe2026/Localizable.xcstrings`, untracked `.planning/state.json`, `.planning/milestone.lock`, `.DS_Store` files). This plan did not edit `Localizable.xcstrings` and did not stage any of those files. The Xcode project uses synchronized groups, so the new files needed no `project.pbxproj` change.

## Next Phase Readiness

Ready for 05-04. The SIGN-05 device row is still to be run on a real iPhone as part of the phase UAT.

## Self-Check: PASSED

- FOUND: `ClickMe2026/Utils/ProfilePhotoCropper.swift`, `ClickMe2026Tests/Utils/ProfilePhotoCropperTests.swift`, `ClickMe2026Tests/Signup/SignupProfilePhotoSaveTests.swift`
- FOUND: `e8fe382`, `7f6659a` (both ancestors of HEAD)
- `check evaluation-scope --plan 05-03 --commits-only` returns both commits.
