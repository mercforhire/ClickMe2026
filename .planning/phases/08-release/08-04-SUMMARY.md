---
phase: 08-release
plan: "04"
subsystem: ci-release
tags: [ci, github-actions, signing, testflight, d-25, d-26, rel-02]

requires:
  - phase: 08
    provides: "Plan 08-01: PreviewSecrets compiles in Release without a token"
provides:
  - "build.yml builds ClickMe.xcodeproj with team V68J585TK5, keeps the build number, and has a dry_run dispatch input"
  - "A green GitHub dry run (archive, signing, export) on main at 4bd63e7"
  - "release_path: ci for plan 08-20"
affects: [08-20]

actuals:
  tasks: 3
  commits: 4

commits: 4

tech-stack:
  added: []
  patterns: ["Archive signs with automatic Development signing; export re-signs manually with a named App Store profile"]

key-files:
  created: []
  modified:
    - .github/workflows/build.yml
    - .github/workflows/test.yml
    - .github/actions/code-signing-setup/action.yml
    - scripts/run-smoke-tests.sh
    - ExportOptions.plist
    - ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

key-decisions:
  - "release_path ci: the user reported the main dry run green (answer verbatim: \"success\", 2026-11-22)"
  - "Export signs manually with the App Store profile \"ClickMe AppStore CI\" (secret BUILD_PROVISION_PROFILE_BASE64), chosen over an Admin API key (user choice: \"A\"), because the App Manager key cannot use cloud-managed distribution signing"
  - "BUILD_CERTIFICATE_BASE64 holds both the Development (feiyang chen, H9PYU6VR7L) and Distribution (Uptrend Investments inc., expires 2027-11-22) identities: the archive signs with Development, the export with Distribution"

requirements-completed: []

duration: user wait
completed: 2026-11-22
---

# Phase 08 Plan 04: CI dry run and release path Summary

**The GitHub "Deploy to TestFlight" workflow now archives, signs and exports ClickMe 1.0 on a dry run with nothing uploaded, so 1.1 (7) can ship from a release/1.1 push.**

release_path: ci

## Commits (iOS, main)

| Hash | Subject |
|------|---------|
| abc4585 | ci(08-04): build ClickMe.xcodeproj with the real team, keep the build number, add a dry-run switch (D-25) |
| 00032ae | ci(08-04): drop SPM cache restore-keys so a stale checkout cannot be reused (D-25) |
| eeb6c9e | fix(08-04): repin AgoraRtcEngine_iOS 4.6.2 to the re-tagged commit (D-25) |
| 4bd63e7 | ci(08-04): export with a manual App Store profile instead of cloud signing (D-25) |

## Task 3: Dry-run rounds (fix-and-retry until green)

1. **Secrets missing:** the user added all repository secrets, with a new Team API key (App Manager).
2. **Install Swift packages:** stale SPM cache and the re-tagged Agora 4.6.2 revision. Fixed in `00032ae` and `eeb6c9e`.
3. **API key decode:** wrong `.p8` encoded. The user generated and encoded a new key.
4. **Archive build:** `No signing certificate "iOS Development" found`. The user re-exported the `.p12` with both the Development and Distribution certificates. No repo change.
5. **Export:** `Cloud signing permission error` and `No profiles for 'com.uptrendinvestments.clickmeapp' were found`. Fixed in `4bd63e7`: `ExportOptions.plist` uses manual signing (`Apple Distribution`, profile `ClickMe AppStore CI`, method `app-store-connect`), and the signing action installs the profile into both the Xcode 16+ `UserData` folder and `MobileDevice`.
6. **Green:** the user reported `success`.

## Push and scans (D-25, D-26)

- `4bd63e7` was pushed as a fast-forward to `main` together with `f796f1d` and `f9d8fbd` (no --force).
- The history scan for JWT-shaped strings, `sk_live_`, `sk_test_`, `whsec_` and private key blocks over `f796f1d~1..4bd63e7` came back empty. The working-tree `git grep -l eyJhbGciOi` outside `.planning` lists only `ClickMe2026Tests/Fixtures/Auth/login_success.json` and `ClickMe2026Tests/Network/Auth/LoginTests.swift`.

## Deviations from Plan

- **Scan after the push:** the D-25 scans ran right after the `4bd63e7` push instead of before it. Both came back clean.
- **Extra files:** `.github/actions/code-signing-setup/action.yml` and `Package.resolved` changed, though the plan didn't list them. They were needed to get past the package and export failures.

## Issues Encountered

- The archive step's `-allowProvisioningUpdates` made the API key create a "Created via API" Development certificate (expires 2027-11-22). Its private key was lost with the runner. Each run may add another, and Apple caps a team's Development certificates. The user can revoke these. Before plan 08-20, check whether the archive can sign without creating certificates, for example with manual Development signing or without `-allowProvisioningUpdates`.
- The App Store profile `ClickMe AppStore CI` is tied to the Distribution certificate that expires 2027-11-22. Renew both together.
