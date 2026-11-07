---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
# Technology Stack

**Analysis Date:** 2026-11-07

## Languages

**Primary:**
- Swift 6.0 (`SWIFT_VERSION = 6.0` for the app target in `ClickMe.xcodeproj/project.pbxproj`) - all app code under `ClickMe2026/` (Views, Model, Network, Managers, Realtime, Utils, Theme, Configuration)
- Strict concurrency is enabled: `SWIFT_STRICT_CONCURRENCY = complete` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` in `ClickMe.xcodeproj/project.pbxproj`

**Secondary:**
- Swift 5.0 - UI test target (`ClickMe2026UITests`, `SWIFT_VERSION = 5.0` in `ClickMe.xcodeproj/project.pbxproj`)
- Swift shared constants - `Constants/*.swift` (`Countries.swift`, `Timezones.swift`, `CategoryIconMap.swift`, `WeekdayHeaders.swift`)
- Shell - `scripts/run-smoke-tests.sh`, `ci_scripts/ci_post_clone.sh`, `.github/actions/code-signing-setup/action.yml`
- YAML / plist - `.github/workflows/*.yml`, `ExportOptions.plist`, `ClickMe2026/Environments.plist`, `ClickMe2026/Info.plist`

## Runtime

**Environment:**
- iOS 18.0 minimum deployment target (`IPHONEOS_DEPLOYMENT_TARGET = 18.0`, `ClickMe.xcodeproj/project.pbxproj`)
- Built with Xcode 26 (`XCODE_VERSION: '26'` in `.github/workflows/build.yml` and `.github/workflows/test.yml`)
- Bundle ID: `com.uptrendinvestments.clickmeapp` (app), `com.uptrendinvestments.ClickMe2026.tests` (unit tests), `com.uptrendinvestments.ClickMe2026.uitests` (UI tests)
- Version: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 6` (app target)
- Single Xcode project, no workspace-level Podfile or Gemfile

**Package Manager:**
- Swift Package Manager, resolved through Xcode (no standalone `Package.swift` in this repo)
- Lockfile: present - `ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (version 3 format)
- CocoaPods: not used (commented-out Cocoapods steps remain in `.github/workflows/build.yml` and `.github/workflows/test.yml`)
- Carthage: not used

## Frameworks

**Core:**
- SwiftUI - UI layer for all screens (`ClickMe2026/Views/`, ~450 files)
- UIKit - app delegate, system chrome and navigation/tab bar appearance (`ClickMe2026/ClickMe2026AppDelegate.swift`, `ClickMe2026/Managers/UserManager.swift`)
- Observation / Combine - observable state (`ClickMe2026/Managers/UserManager.swift` imports `Observation`; `ClickMe2026/Managers/CallCenter.swift` imports `Combine`)
- AVFoundation - audio session and media permissions (`ClickMe2026/Managers/AgoraManager.swift`)
- AuthenticationServices - `ASWebAuthenticationSession` for Stripe Connect onboarding (`ClickMe2026/Views/Screens/Expert Mode/Payouts/Subviews/ConnectOnboardingSession.swift`)
- UserNotifications - local/remote notification handling (`ClickMe2026/ClickMe2026AppDelegate.swift`)
- Foundation `URLSession` - all REST calls (`ClickMe2026/Network/NetworkService.swift`, configured with a 120 s request timeout)

**Testing:**
- Swift Testing (`import Testing`, `#expect`, `#require`) - unit and integration tests in `ClickMe2026Tests/` (e.g. `ClickMe2026Tests/Network/Auth/LoginTests.swift`)
- XCTest - UI tests in `ClickMe2026UITests/` (`ClickMe2026UITests/ExampleUITests.swift`, `ClickMe2026UITests/ViewObjects/`, `ClickMe2026UITests/Behaviours/`)
- Test plan: `ClickMe2026/AllTests.xctestplan`
- Mocking: custom `MockURLProtocol` (`ClickMe2026Tests/Support/`) intercepts `URLSession` traffic
- Fixtures: JSON under `ClickMe2026Tests/Fixtures/Auth/`

**Build/Dev:**
- Xcode 26 build system, `xcodebuild` in CI
- SwiftLint - `.swiftlint.yml` (disables `trailing_comma`, `line_length`, `unused_closure_parameter`); run in CI via `cirruslabs/swiftlint-action@v1` in `.github/workflows/test.yml`
- SwiftFormat - `.swiftformat` (4-space indent, `--disable unusedArguments`, `--disable redundantRawValues`)
- EditorConfig - `.editorconfig` (Swift: 4 spaces, LF, max line length 120, trim trailing whitespace)
- GitHub Actions - `.github/workflows/build.yml` (TestFlight deploy on `release/**` push or manual dispatch), `.github/workflows/test.yml` (lint, build-for-testing, test-without-building)
- Dependabot - `.github/dependabot.yml` (weekly updates for `swift` and `github-actions` ecosystems)

## Key Dependencies

All versions below are taken from `ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` and the `XCRemoteSwiftPackageReference` entries in `ClickMe.xcodeproj/project.pbxproj`.

**Critical:**
- `stripe-ios-spm` 26.2.0 (`https://github.com/stripe/stripe-ios-spm`, product `StripePaymentSheet`) - payment sheet, card payments and Stripe Connect onboarding link. Initialized in `ClickMe2026/Configuration/StripeConfiguration.swift`
- `AgoraRtcEngine_iOS` 4.6.2 (`https://github.com/AgoraIO/AgoraRtcEngine_iOS`, product `RtcBasic`; module `AgoraRtcKit`) - in-app voice calls. Wrapped by `ClickMe2026/Managers/AgoraManager.swift`
- `firebase-ios-sdk` 12.17.0 (product `FirebaseAnalytics`, `FirebaseMessaging`; `FirebaseCore` used directly) - push notifications via FCM and analytics. Configured in `ClickMe2026/ClickMe2026AppDelegate.swift`
- `socket.io-client-swift` (branch-tracked, no pinned version in `Package.resolved` beyond revision `42da871d9369f290d6ec4930636c40672143905b`; product `SocketIO`) - real-time socket connection. Wrapped by `ClickMe2026/Realtime/RealtimeService.swift`
- `Valet` 5.1.0 (`https://github.com/Square/Valet`) - Keychain wrapper for the rotating refresh token. Used in `ClickMe2026/Managers/UserManager.swift`
- `Salad` 1.0.0 (`https://github.com/Q42/Salad.git`, product `Salad`) - declared as a package dependency of the app target; no direct usage was located in the Swift sources during this analysis

**Transitive (pulled in by Firebase, Agora and Socket.IO):**
- `Starscream` 4.0.8 - WebSocket transport for `socket.io-client-swift`
- `AgoraInfra_iOS` 1.3.5 - Agora infrastructure dependency
- `app-check` 11.3.1, `GoogleAppMeasurement` 12.17.0, `GoogleDataTransport` 10.1.1, `GoogleUtilities` 8.1.2, `gtm-session-fetcher` 5.3.1, `promises` 2.4.1, `nanopb` 2.30910.1, `leveldb` 1.22.5, `interop-ios-for-google-sdks` 101.0.0, `google-ads-on-device-conversion-ios-sdk` 3.6.1, `grpc-binary` 1.69.1, `abseil-cpp-binary` 1.2024072200.0

**Infrastructure:**
- `URLSession` with `.convertFromSnakeCase` / `.convertToSnakeCase` JSON coding - REST client, see `ClickMe2026/Network/NetworkService.swift`
- Custom date decoding that truncates microsecond timestamps to milliseconds - `ClickMe2026/Network/NetworkService.swift`

## Configuration

**Environment:**
- Runtime environment is selected from `ClickMe2026/Environments.plist` via the `Current` key (currently `Production`). Each environment (`Development`, `Staging`, `Production`) supplies `BaseURL`, `StripePublishableKey` and `AgoraAppId`
- Loaded once at launch by `AppEnvironment.current` in `ClickMe2026/Configuration/AppEnvironment.swift`
- Base URL for all three environments is the same Railway-hosted backend (`https://clickme-backend-production.up.railway.app/api/v1`). Only the Stripe key differs between Development/Staging (test-mode `pk_test_` key) and Production (live-mode `pk_live_` key)
- Stripe key placeholder guard: `StripeConfiguration.configure()` asserts if the key contains `REPLACE_ME`
- Public marketing and policy URL is hard-coded in `AppEnvironment.swift` (`AppLinks.privacyPolicy`)
- Firebase config: `ClickMe2026/GoogleService-Info.plist` (present; contains Firebase project identifiers; not quoted here)
- Entitlements: `ClickMe2026/ClickMe2026.entitlements` sets `aps-environment` to `production` (push notifications)
- Info.plist: custom URL scheme `clickme` (`CFBundleURLTypes`), `ITSAppUsesNonExemptEncryption = false`, background modes `audio` and `remote-notification`
- Privacy manifest: `ClickMe2026/PrivacyInfo.xcprivacy` (no tracking; declares UserDefaults API usage reason `CA92.1` and collected data categories)
- Debug-only preview fixtures: `ClickMe2026/Debug/PreviewSecrets.swift` contains bearer-token placeholders for SwiftUI previews. Contents are intentionally not reproduced in this document
- Smoke-test credentials are injected through environment variables (`CLICKME_TEST_EMAIL`, `CLICKME_TEST_PASSWORD`) by `scripts/run-smoke-tests.sh`. Values are not stored in the repo
- `.env` files: none detected

**Build:**
- `ClickMe.xcodeproj/project.pbxproj` - targets `ClickMe2026`, `ClickMe2026Tests`, `ClickMe2026UITests`
- `ClickMe.xcodeproj/xcshareddata/xcschemes/` - shared schemes
- `ClickMe2026/AllTests.xctestplan` - test plan
- `ExportOptions.plist` - App Store / TestFlight export options
- `.github/actions/code-signing-setup/action.yml` - composite action that installs the signing certificate for CI
- `ClickMe2026/LaunchScreen.storyboard` - launch screen
- `ClickMe2026/Localizable.xcstrings` - String Catalog, source language `en`

## Platform Requirements

**Development:**
- macOS with Xcode 26 and the iOS 18 SDK
- Swift 6 toolchain (strict concurrency)
- Access to the Swift Package Manager dependencies listed above
- An iOS simulator (CI and `scripts/run-smoke-tests.sh` default to `iPhone 17`)
- Optional: `ClickMe_Android` and `ClickMe2026 Backend` sibling repos for cross-project API work (see `CLAUDE.md`)

**Production:**
- Distributed as an iOS app via TestFlight and the App Store, built by `.github/workflows/build.yml` on `macos-26` runners
- Release builds use `CURRENT_PROJECT_VERSION = 6` and `MARKETING_VERSION = 1.0`
- Backend: Railway-hosted Node/Express service (per `CLAUDE.md`, the backend uses Node.js, Express and Supabase; that repo is not analyzed here)

---

*Stack analysis: 2026-11-07*
