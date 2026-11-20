<!-- GSD:project-start source:PROJECT.md -->

## Project

**ClickMe iOS — Android-Parity Bug Fixes**

A bug-fix project for the live ClickMe iOS app (SwiftUI), a marketplace where clients book paid or free voice and video sessions with experts. While porting the app to Android, the team found that many of its behaviors were wrong in iOS: some were fixed on Android, some avoided, some flagged. This project fixes every confirmed and likely iOS bug from that work, plus the backend issues behind them, and ships one new iOS build at the end.

**Core Value:** Live iOS users can book, pay for, join and finish a session without the app cutting them off, charging them wrongly, or silently dropping their actions. Calls, bookings and payments come first when there's a tradeoff.

### Constraints

- **Tech stack**: SwiftUI, Swift 6 strict concurrency, iOS 18+, Xcode 26 — the existing app, no rewrites
- **Backend compatibility**: Backend changes must be additive or otherwise safe for the current Android build — both clients share the REST contract
- **Cross-repo commits**: Backend fixes are committed in the backend repo, one commit per repo per change; never assume the other repo already has it
- **Release**: One iOS release at the end of the project; no hotfix build in between (user decision 2026-11-07), no fixed date
- **Definition of done**: Unit tests where the logic is testable, a clean `xcodebuild` with no new warnings, a device check on a real iPhone via a UAT checklist, and backend tests for backend changes
- **Production data**: The backend is the live production one; payment and refund changes need care (real holds and charges)

<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->

## Technology Stack

## Languages

- Swift 6.0 (`SWIFT_VERSION = 6.0` for the app target in `ClickMe.xcodeproj/project.pbxproj`) - all app code under `ClickMe2026/` (Views, Model, Network, Managers, Realtime, Utils, Theme, Configuration)
- Strict concurrency is enabled: `SWIFT_STRICT_CONCURRENCY = complete` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` in `ClickMe.xcodeproj/project.pbxproj`
- Swift 5.0 - UI test target (`ClickMe2026UITests`, `SWIFT_VERSION = 5.0` in `ClickMe.xcodeproj/project.pbxproj`)
- Swift shared constants - `Constants/*.swift` (`Countries.swift`, `Timezones.swift`, `CategoryIconMap.swift`, `WeekdayHeaders.swift`)
- Shell - `scripts/run-smoke-tests.sh`, `ci_scripts/ci_post_clone.sh`, `.github/actions/code-signing-setup/action.yml`
- YAML / plist - `.github/workflows/*.yml`, `ExportOptions.plist`, `ClickMe2026/Environments.plist`, `ClickMe2026/Info.plist`

## Runtime

- iOS 18.0 minimum deployment target (`IPHONEOS_DEPLOYMENT_TARGET = 18.0`, `ClickMe.xcodeproj/project.pbxproj`)
- Built with Xcode 26 (`XCODE_VERSION: '26'` in `.github/workflows/build.yml` and `.github/workflows/test.yml`)
- Bundle ID: `com.uptrendinvestments.clickmeapp` (app), `com.uptrendinvestments.ClickMe2026.tests` (unit tests), `com.uptrendinvestments.ClickMe2026.uitests` (UI tests)
- Version: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 6` (app target)
- Single Xcode project, no workspace-level Podfile or Gemfile
- Swift Package Manager, resolved through Xcode (no standalone `Package.swift` in this repo)
- Lockfile: present - `ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (version 3 format)
- CocoaPods: not used (commented-out Cocoapods steps remain in `.github/workflows/build.yml` and `.github/workflows/test.yml`)
- Carthage: not used

## Frameworks

- SwiftUI - UI layer for all screens (`ClickMe2026/Views/`, ~450 files)
- UIKit - app delegate, system chrome and navigation/tab bar appearance (`ClickMe2026/ClickMe2026AppDelegate.swift`, `ClickMe2026/Managers/UserManager.swift`)
- Observation / Combine - observable state (`ClickMe2026/Managers/UserManager.swift` imports `Observation`; `ClickMe2026/Managers/CallCenter.swift` imports `Combine`)
- AVFoundation - audio session and media permissions (`ClickMe2026/Managers/AgoraManager.swift`)
- AuthenticationServices - `ASWebAuthenticationSession` for Stripe Connect onboarding (`ClickMe2026/Views/Screens/Expert Mode/Payouts/Subviews/ConnectOnboardingSession.swift`)
- UserNotifications - local/remote notification handling (`ClickMe2026/ClickMe2026AppDelegate.swift`)
- Foundation `URLSession` - all REST calls (`ClickMe2026/Network/NetworkService.swift`, configured with a 120 s request timeout)
- Swift Testing (`import Testing`, `#expect`, `#require`) - unit and integration tests in `ClickMe2026Tests/` (e.g. `ClickMe2026Tests/Network/Auth/LoginTests.swift`)
- XCTest - UI tests in `ClickMe2026UITests/` (`ClickMe2026UITests/ExampleUITests.swift`, `ClickMe2026UITests/ViewObjects/`, `ClickMe2026UITests/Behaviours/`)
- Test plan: `ClickMe2026/AllTests.xctestplan`
- Mocking: custom `MockURLProtocol` (`ClickMe2026Tests/Support/`) intercepts `URLSession` traffic
- Fixtures: JSON under `ClickMe2026Tests/Fixtures/Auth/`
- Xcode 26 build system, `xcodebuild` in CI
- SwiftLint - `.swiftlint.yml` (disables `trailing_comma`, `line_length`, `unused_closure_parameter`); run in CI via `cirruslabs/swiftlint-action@v1` in `.github/workflows/test.yml`
- SwiftFormat - `.swiftformat` (4-space indent, `--disable unusedArguments`, `--disable redundantRawValues`)
- EditorConfig - `.editorconfig` (Swift: 4 spaces, LF, max line length 120, trim trailing whitespace)
- GitHub Actions - `.github/workflows/build.yml` (TestFlight deploy on `release/**` push or manual dispatch), `.github/workflows/test.yml` (lint, build-for-testing, test-without-building)
- Dependabot - `.github/dependabot.yml` (weekly updates for `swift` and `github-actions` ecosystems)

## Key Dependencies

- `stripe-ios-spm` 26.2.0 (`https://github.com/stripe/stripe-ios-spm`, product `StripePaymentSheet`) - payment sheet, card payments and Stripe Connect onboarding link. Initialized in `ClickMe2026/Configuration/StripeConfiguration.swift`
- `AgoraRtcEngine_iOS` 4.6.2 (`https://github.com/AgoraIO/AgoraRtcEngine_iOS`, product `RtcBasic`; module `AgoraRtcKit`) - in-app voice calls. Wrapped by `ClickMe2026/Managers/AgoraManager.swift`
- `firebase-ios-sdk` 12.17.0 (product `FirebaseAnalytics`, `FirebaseMessaging`; `FirebaseCore` used directly) - push notifications via FCM and analytics. Configured in `ClickMe2026/ClickMe2026AppDelegate.swift`
- `socket.io-client-swift` (branch-tracked, no pinned version in `Package.resolved` beyond revision `42da871d9369f290d6ec4930636c40672143905b`; product `SocketIO`) - real-time socket connection. Wrapped by `ClickMe2026/Realtime/RealtimeService.swift`
- `Valet` 5.1.0 (`https://github.com/Square/Valet`) - Keychain wrapper for the rotating refresh token. Used in `ClickMe2026/Managers/UserManager.swift`
- `Salad` 1.0.0 (`https://github.com/Q42/Salad.git`, product `Salad`) - declared as a package dependency of the app target; no direct usage was located in the Swift sources during this analysis
- `Starscream` 4.0.8 - WebSocket transport for `socket.io-client-swift`
- `AgoraInfra_iOS` 1.3.5 - Agora infrastructure dependency
- `app-check` 11.3.1, `GoogleAppMeasurement` 12.17.0, `GoogleDataTransport` 10.1.1, `GoogleUtilities` 8.1.2, `gtm-session-fetcher` 5.3.1, `promises` 2.4.1, `nanopb` 2.30910.1, `leveldb` 1.22.5, `interop-ios-for-google-sdks` 101.0.0, `google-ads-on-device-conversion-ios-sdk` 3.6.1, `grpc-binary` 1.69.1, `abseil-cpp-binary` 1.2024072200.0
- `URLSession` with `.convertFromSnakeCase` / `.convertToSnakeCase` JSON coding - REST client, see `ClickMe2026/Network/NetworkService.swift`
- Custom date decoding that truncates microsecond timestamps to milliseconds - `ClickMe2026/Network/NetworkService.swift`

## Configuration

- Runtime environment is selected from `ClickMe2026/Environments.plist` via the `Current` key (currently `Production`). Each environment (`Development`, `Staging`, `Production`) supplies `BaseURL`, `StripePublishableKey` and `AgoraAppId`
- Loaded once at launch by `AppEnvironment.current` in `ClickMe2026/Configuration/AppEnvironment.swift`
- Base URL for all three environments is the same Railway-hosted backend (`https://clickme-backend-production.up.railway.app/api/v1`). Only the Stripe key differs between Development/Staging (test-mode `pk_test_` key) and Production (live-mode `pk_live_` key)
- Stripe key placeholder guard: `StripeConfiguration.configure()` asserts if the key contains `REPLACE_ME`
- Public marketing and policy URL is hard-coded in `AppEnvironment.swift` (`AppLinks.privacyPolicy`)
- Firebase config: `ClickMe2026/GoogleService-Info.plist` (present; contains Firebase project identifiers; not quoted here)
- Entitlements: `ClickMe2026/ClickMe2026.entitlements` sets `aps-environment` to `production` (push notifications)
- Info.plist: custom URL scheme `clickme` (`CFBundleURLTypes`), `ITSAppUsesNonExemptEncryption = false`, background modes `audio` and `remote-notification`
- Privacy manifest: `ClickMe2026/PrivacyInfo.xcprivacy` (no tracking; declares UserDefaults API usage reason `CA92.1` and collected data categories)
- Debug-only preview fixtures: `ClickMe2026/Debug/PreviewSecrets.swift` (tracked, token-free) supplies the SwiftUI preview bearer tokens from environment variables or the gitignored repo-root `PreviewSecrets.local.json`; token values are never reproduced in this document
- Smoke-test credentials are injected through environment variables (`CLICKME_TEST_EMAIL`, `CLICKME_TEST_PASSWORD`) by `scripts/run-smoke-tests.sh`. Values are not stored in the repo
- `.env` files: none detected
- `ClickMe.xcodeproj/project.pbxproj` - targets `ClickMe2026`, `ClickMe2026Tests`, `ClickMe2026UITests`
- `ClickMe.xcodeproj/xcshareddata/xcschemes/` - shared schemes
- `ClickMe2026/AllTests.xctestplan` - test plan
- `ExportOptions.plist` - App Store / TestFlight export options
- `.github/actions/code-signing-setup/action.yml` - composite action that installs the signing certificate for CI
- `ClickMe2026/LaunchScreen.storyboard` - launch screen
- `ClickMe2026/Localizable.xcstrings` - String Catalog, source language `en`

## Platform Requirements

- macOS with Xcode 26 and the iOS 18 SDK
- Swift 6 toolchain (strict concurrency)
- Access to the Swift Package Manager dependencies listed above
- An iOS simulator (CI and `scripts/run-smoke-tests.sh` default to `iPhone 17`)
- Optional: `ClickMe_Android` and `ClickMe2026 Backend` sibling repos for cross-project API work (see `CLAUDE.md`)
- Distributed as an iOS app via TestFlight and the App Store, built by `.github/workflows/build.yml` on `macos-26` runners
- Release builds use `CURRENT_PROJECT_VERSION = 6` and `MARKETING_VERSION = 1.0`
- Backend: Railway-hosted Node/Express service (per `CLAUDE.md`, the backend uses Node.js, Express and Supabase; that repo is not analyzed here)

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

## Naming Patterns

- One primary type per file, named after the type: `ClickMe2026/Network/NetworkService.swift` holds `NetworkService`; `ClickMe2026/Theme/Brand.swift` holds `enum Brand`.
- Screen folders hold a view, its view model, and a `Subviews/` folder for child views. Example: `ClickMe2026/Views/Screens/Client Mode/Make a Booking/` contains `MakeABookingView.swift`, `MakeABookingViewModel.swift`, and `Subviews/`.
- View model files end in `ViewModel.swift` (for example `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift`). Screen views end in `View.swift`. Some older or secondary screens use other suffixes, such as `ExpertProfileHomeScreen.swift` in `ClickMe2026/Views/Screens/Expert Mode/Profile/`.
- Network extensions are named `ClickMeAPI+<Feature>.swift`, for example `ClickMe2026/Network/ClickMeAPI+Booking.swift`.
- Request and response models live in `ClickMe2026/Model/Requests/` and `ClickMe2026/Model/Responses/`. Response types end in `Data` or `Response`, for example `LoginData.swift`, `PaymentIntentResponse.swift`, `SuccessDataResponse.swift`.
- Enums that mirror server values are in `ClickMe2026/Model/Enums/` (for example `BookingStatus.swift`, `ErrorCode.swift`, `UserRole.swift`).
- Folder names with spaces are used for screens (`Client Mode/`, `Login Flow/`, `Request decision/`). New folders under `Views/Screens/` should follow that existing pattern, because the directory names are shown to Xcode groups.
- `UpperCamelCase` for all types, including enums, structs, protocols, and classes.
- Feature-scoped types are prefixed with the screen name. Subviews of `MakeABookingView` are named `MakeABookingExpertCard`, `MakeABookingTopicPicker`, `MakeABookingCalendarCard`, and `MakeABookingBrand`. Keep that prefix for any new subview.
- Namespaces are caseless `enum`s with `static` members: `enum Brand` (`ClickMe2026/Theme/Brand.swift`), `enum Utils` (`ClickMe2026/Utils/Utils.swift`), `enum APIRequestURLs`.
- View structs do not always carry the `View` suffix. `struct MakeABooking: View` is declared in `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift`, while other screens use `...View`. Prefer the `...View` suffix for new screens.
- `lowerCamelCase` verb-first names: `initiateBooking(expertId:topicId:)`, `createPaymentIntent(...)`, `newBookingAttempt()` in `ClickMe2026/Network/ClickMeAPI+Booking.swift` and `MakeABookingViewModel.swift`.
- Network endpoint methods mirror the endpoint's purpose, not the HTTP verb. Use `login`, `signup`, `initiateBooking`, not `postLogin`.
- Argument labels are full words and use `id` suffixes: `expertId: UUID`, `bookingAttemptId: UUID`.
- `lowerCamelCase`. Identifiers are spelled `Id` (not `ID`) in names: `expertId`, `topicId`, `threadId`, `bookingId`. Keep this spelling for consistency with existing call sites.
- Published view state uses `@Published var` inside `ObservableObject` view models, and `private(set) var` inside observable managers (see `ClickMe2026/Managers/UserManager.swift`).
- Error text is exposed as `@Published var apiError: String?` in view models (used across most `*ViewModel.swift` files). `var errorMessage: String?` also appears in a few files. Prefer `apiError` for new view models.
- Swift cases are `lowerCamelCase`. Server raw values are `snake_case` or `SCREAMING_SNAKE_CASE`, declared explicitly:
- Error codes from the server are modeled as `enum ErrorCode: String, Decodable` in `ClickMe2026/Model/Enums/ErrorCode.swift`, with `SCREAMING_SNAKE_CASE` raw values.
- Static constants use `static let` on a namespace type, such as `Brand.primary` and `APITestFactory.baseURL`.
- Brand colors and tokens are declared `nonisolated static let` so they can be read from any actor context (`ClickMe2026/Theme/Brand.swift`).

## Code Style

- Indentation: 4 spaces, LF line endings, final newline, trailing whitespace trimmed. Defined in `/Users/LeonChen/Documents/ClickMe2026/.editorconfig`.
- `max_line_length = 120` is set in `.editorconfig`. The line-length lint rule is disabled, so the limit is advisory. Long argument lists are broken one argument per line, with the closing parenthesis on its own line (see `ClickMe2026/Network/ClickMeAPI+Booking.swift`).
- Multi-line boolean or closure conditions put the opening brace on its own line when the condition spans lines:
- Single-line `guard let ... else { ... }` and `else`-on-same-line style is used for simple cases.
- Column alignment is used for enum raw values and short declarations, for example `case pendingApproval    = "pending_approval"`.
- SwiftFormat config at `/Users/LeonChen/Documents/ClickMe2026/.swiftformat`: `--indent 4`, `--disable unusedArguments`, `--disable redundantRawValues`. The `redundantRawValues` rule is disabled so explicit raw values stay in enums such as `BookingStatus`.
- No `swiftformat` run is wired into CI. Format manually to match surrounding code.
- SwiftLint, configured in `/Users/LeonChen/Documents/ClickMe2026/.swiftlint.yml`. Disabled rules: `trailing_comma`, `line_length`, `unused_closure_parameter`.
- SwiftLint runs in CI as the first step of `.github/workflows/test.yml` through `cirruslabs/swiftlint-action@v1`. Lint failures block PRs to `main`.

## Import Organization

- Not used. Swift modules are referenced by name. There are no path aliases or Swift package aliases in the project.

## Error Handling

- Transport and HTTP failures are thrown as `NetworkError` (`ClickMe2026/Network/NetworkService.swift`): `invalidURL`, `invalidResponse`, `httpError(statusCode:data:)`, `decodingFailed(Error)`, `encodingFailed(Error)`, `invalidDate`.
- A non-2xx response throws `.httpError` with the raw body. Callers decode the body as `StandardErrorResponse` or `FieldValidationErrorResponse` (`ClickMe2026/Model/Responses/`).
- Endpoint methods are `async throws` and return a typed `SuccessDataResponse<T>` or a plain payload type. They do not swallow errors.
- A 401 on an authenticated request triggers the refresh interceptor (`authTokenRefresher`) once, then retries. A `403 ACCOUNT_SUSPENDED` triggers `suspensionHandler` and still rethrows.
- Convert any `Error` to a display string with the `Error.userMessage` extension in `ClickMe2026/Network/Error+UserMessage.swift`. It prefers the server `message` from `StandardErrorResponse`, then `LocalizedError.errorDescription`, then `localizedDescription`.
- Do not write a new private `errorMessage(for:)` helper in a view model. Use `userMessage`.
- Async work is wrapped in `do { try await ... } catch { ... }`. The catch sets a `@Published` error string (`apiError`) that the view renders. Catch blocks are common (about 150 in the app target). Use them in any new network call.
- `try?` is used for best-effort reads where failure is acceptable (for example, optional decoding). Do not use `try?` for writes or for requests whose failure must be shown to the user.
- `try!` and `fatalError` do not appear in app code. `fatalError` is used only in test support (`ClickMe2026Tests/Support/Bundle+Fixtures.swift`).
- Force casts (`as!`) are not used in app code.
- Use `guard` for early exit on missing state rather than nested `if let`.
- Branch on `ErrorCode` values (`ClickMe2026/Model/Enums/ErrorCode.swift`) when the UI needs different behavior per error, for example `BOOKING_ATTEMPT_CONFLICT`. Do not string-match on `message`.

## Logging

- Request and response logging is gated behind `#if DEBUG` in `ClickMe2026/Network/NetworkService.swift` (`logRequest`, `logResponse`). The `Authorization` header is redacted to `Bearer …` before printing.
- Push notification diagnostics use a `push:` prefix so they can be filtered in the Xcode console: `print("push: APNs registration FAILED = ...")` in `ClickMe2026/ClickMe2026AppDelegate.swift` and `ClickMe2026/Managers/UserManager.swift`.
- Do not log tokens, passwords, or full user payloads. The existing `print("push: TAP received. Full userInfo:")` in `ClickMe2026AppDelegate.swift` is development-only diagnostics; do not copy it into other flows.
- Wrap new debug-only logging in `#if DEBUG ... #endif`.

## Comments

- Explain the why, the server contract, or a non-obvious race or retry rule. Examples: the attempt-id explanation in `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, and the 422 and 409 behavior documented on `createPaymentIntent` in `ClickMe2026/Network/ClickMeAPI+Booking.swift`.
- Reference the backend doc when the behavior is part of the API contract, for example `docs/ios/USER-REPORTING.md` §4 (cited in `NetworkService.swift`). See the root `CLAUDE.md` for the cross-repo contract locations.
- Do not restate what the code does.
- `// MARK: - Section name` is the standard section divider. It is used about 1,370 times in the app target. Common sections: `// MARK: - Body`, `// MARK: Inits`, `// MARK: Loaded content`, `// MARK: Selections`, `// MARK: - POST /auth/signup`.
- Every Swift file starts with the Xcode header block:
- Use `///` doc comments on types and on public or internal methods. Use `- Parameter name:` for non-obvious parameters (see `ClickMe2026Tests/Support/APITestFactory.swift`).
- Put `- Parameters:` text in the doc comment instead of inline comments.

## Function Design

- Endpoint methods are one-liners that call `service.httpRequest` (for example `initiateBooking` in `ClickMe2026/Network/ClickMeAPI+Booking.swift`).
- View models are long. The largest are about 850 lines (`ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`). Extract new logic into helpers or a sibling type rather than growing these files.
- Views are split into `Subviews/` files when a body grows past a few screens of layout.
- Prefer explicit labeled parameters and typed IDs (`UUID`), not raw `String` IDs. Use `String` only for external identifiers such as Stripe `pm_...` ids (see `url(_:stringId:)` in `ClickMe2026/Network/ClickMeAPI.swift`).
- Default values are used for optional query and body fields (`promoCode: String? = nil`).
- Endpoint methods return a typed response, for example `SuccessDataResponse<InitiateBookingData>`, or throw.
- Void-returning async work is written as `async throws` with no return value. Do not return `Bool` success flags for network calls.

## Module Design

- Single app module `ClickMe2026`. Types are `internal` by default. Use `private` for helpers within a file, and `private(set)` for state that only the owner can change (for example `UserManager.me`).
- Tests reach internal types with `@testable import ClickMe2026`.
- `ClickMeAPI` is a `final class` declared in `ClickMe2026/Network/ClickMeAPI.swift`. Feature methods are added in extensions, one file per feature, all under `ClickMe2026/Network/`.
- Add a new endpoint by (1) adding a case to `APIRequestURLs` in `ClickMe2026/Network/APIRequestURLs.swift`, (2) adding the method to the matching `ClickMeAPI+<Feature>.swift` (or a new one), and (3) adding request and response types under `Model/Requests/` and `Model/Responses/`.
- View models and managers are `@MainActor`. `UserManager` is `@MainActor @Observable final class` (`ClickMe2026/Managers/UserManager.swift`). About 75 files use `@MainActor`.
- Use `async`/`await` for new async work (about 30 files). Use `Task { ... }` or `.task { ... }` in views to start work (about 180 `Task {` and 70 `.task` sites). Combine is effectively unused (`import Combine` appears in 3 files).
- Shared singletons use `static let shared`: `UserManager.shared`, `ClickMeAPI.shared`.
- Two observation styles coexist:
- When editing a feature, match the style used by its neighboring view model. For new shared managers, use `@Observable`.
- Not used. Each file imports what it needs.

## Other Patterns

- View models are injected through an initializer. Runtime init builds the view model from feature parameters, and a second `init(viewModel:)` is kept as a preview or test seam:
- Shell-level values are passed through the SwiftUI `Environment` using custom keys (for example `@Environment(\.showMyBookings)` and `@Environment(\.returnToHome)`).
- Use `@ViewBuilder` for conditional composition (about 90 uses). Prefer small computed `some View` properties for sections inside a screen.
- Use `#Preview` blocks, named when showing several states: `#Preview("Client Active")` and `#Preview("Expert Active")` in `ClickMe2026/Views/Screens/Settings/Mode Switching/ModeSwitchView.swift`. About 190 preview blocks exist. Preview harness code must compile in Release too, so do not wrap `#Preview` bodies in `#if DEBUG`.
- Button styles are in `ClickMe2026/Views/Components/ButtonStyles/` (for example `PressScaleButtonStyle.swift`). Reusable async buttons are in `ClickMe2026/Views/Components/Buttons/AsyncSaveButton.swift`.
- Models conform to `Decodable` (or `Codable`) with explicit `CodingKeys` when server keys are `snake_case`:
- Dynamic JSON is modeled with `JSONValue` (`ClickMe2026/Model/Enums/JSONValue.swift`).
- Date parsing and formatting is centralized in `ClickMe2026/Utils/DateUtil.swift` and `ClickMe2026/Network/NetworkService.swift`. Use these instead of creating new `DateFormatter` instances.
- Relative times use `Utils.timeAgo(since:)` (`ClickMe2026/Utils/Utils.swift`).
- Never commit secrets. `ClickMe2026/Debug/PreviewSecrets.swift` is tracked and holds no token: in DEBUG it reads the preview bearer tokens from `CLICKME_PREVIEW_CLIENT_TOKEN` / `CLICKME_PREVIEW_EXPERT_TOKEN` or from the gitignored repo-root `PreviewSecrets.local.json`, and Release reads nothing. Never write a token into the tracked file, and run the Phase 8 JWT scans before any push (D-25). Test credentials come from environment variables or UserDefaults (see `ClickMe2026Tests/Support/SmokeConfig.swift`).

<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

## System Overview

```text

```

## Pattern Overview

- Single app target; all source lives under `ClickMe2026/` (no local feature packages).
- Feature folders under `ClickMe2026/Views/Screens/` are self-contained: `<Name>View.swift`, `<Name>ViewModel.swift`, and a `Subviews/` folder of small, screen-prefixed view components.
- Root navigation is a private `AppRoute` enum held in `@State` in `ClickMe2026App`, not a router object. Mode (client vs expert) is mirrored onto this route.
- Two parallel UI shells share the same services: `HomeClientView` (`Views/Screens/Client Mode/Home/HomeClientView.swift`) and `HomeExpertView` (`Views/Screens/Expert Mode/Home/HomeExpertView.swift`).
- A single `ClickMeAPI.shared` instance is the network entry point; endpoints are grouped by feature in extension files.
- Models are split by direction: `Model/Requests` (Encodable bodies), `Model/Responses` (Decodable envelopes, item types in `Model/Responses/Children/`), `Model/Enums`, `Model/UIModels` (display-facing), `Model/Push`.

## Layers

- Purpose: Bootstrap Firebase/Stripe, route between splash/login/signup/home, and hand push events to routers.
- Location: `ClickMe2026/ClickMe2026App.swift`, `ClickMe2026/ClickMe2026AppDelegate.swift`
- Contains: `@main` App struct, `AppRoute` enum, UIKit delegate for APNs/FCM and `UNUserNotificationCenter`.
- Depends on: `UserManager`, `PushRouter`, `StripeConfiguration`, `PushEvent`.
- Used by: iOS runtime only.
- Purpose: Select the environment and expose per-environment keys.
- Location: `ClickMe2026/Configuration/AppEnvironment.swift`, `ClickMe2026/Configuration/StripeConfiguration.swift`, `ClickMe2026/Environments.plist`
- Contains: `AppEnvironment.current` (parsed once from `Environments.plist` key `Current`, currently `Production`), `AppLinks.privacyPolicy`.
- Depends on: Bundle resources only.
- Used by: `ClickMeAPI.init`, `StripeConfiguration.configure()`, `AgoraManager`.
- Purpose: Colors, fonts, and shared visual primitives.
- Location: `ClickMe2026/Theme/Brand.swift` (global palette, documented as the single source of truth), `ClickMe2026/Theme/BrandFont.swift`, `ClickMe2026/Views/Components/`, `ClickMe2026/Views/Extensions/`
- Contains: `Brand` enum tokens; reusable `ButtonStyles`, `Buttons/AsyncSaveButton.swift`, `ValidatedField.swift`, `Avatar/TopBarAvatarButton.swift`, `Backgrounds/GreenGlowBlobLayer.swift`, `Web/SafariView.swift`.
- Depends on: SwiftUI.
- Used by: every screen.
- Purpose: Own cross-screen state that outlives any single view.
- Location: `ClickMe2026/Managers/`
- Contains:
- Depends on: `ClickMeAPI`, `RealtimeService`, `Valet`, `UserDefaults`, Firebase Messaging, Agora.
- Used by: shells, ViewModels, `ClickMe2026App`.
- Purpose: Socket.IO push channel for chat, presence, booking, and call events.
- Location: `ClickMe2026/Realtime/RealtimeService.swift`, `ClickMe2026/Realtime/RealtimeEvents.swift`
- Contains: `RealtimeService.shared` (`@MainActor`), per-event handler dictionaries keyed by `UUID`, returned as `RealtimeSubscription` tokens. Events (socket names): `message.new`, `message.read`, `user.status`, `typing.start`, `typing.stop`, `booking.update`, `call.ended`; decoded structs live in `RealtimeEvents.swift`.
- Depends on: `socket.io-client-swift`, a JWT from `UserManager`.
- Used by: chat ViewModels, booking/call screens.
- Purpose: Authenticated HTTP and multipart transport plus typed endpoint methods.
- Location: `ClickMe2026/Network/`
- Contains:
- Depends on: `Model/Requests`, `Model/Responses`, `AppEnvironment`.
- Used by: ViewModels (preferred), and a subset of views directly (see Anti-Patterns).
- Purpose: Wire types and display types.
- Location: `ClickMe2026/Model/`
- Contains: `Requests/` (`SignupRequest.swift`, `UpdateUserProfileRequest.swift`, …), `Responses/` (`LoginData.swift`, `ClientHomeData.swift`, `MeData.swift`, `…`), `Responses/Children/` (row/item types such as `ChatThreadItem.swift`, `ExpertBookingItem.swift`), `Enums/` (`BookingStatus.swift`, `UserRole.swift`, `MessageType.swift`, `ErrorCode.swift`, `JSONValue.swift`), `UIModels/` (`UpcomingBooking.swift`, `LoadState.swift`, `BookingTimeSlot.swift`, `ChatDisplayModels.swift`), `Push/PushEvent.swift`.
- Depends on: Foundation only.
- Used by: `Network/`, ViewModels, Views.
- Purpose: All user-facing flows.
- Location: `ClickMe2026/Views/Screens/` (439 Swift files across 10 top-level flows; see STRUCTURE.md).
- Contains: `View` (SwiftUI), `ViewModel` (`@MainActor ObservableObject`, `@Published` state), `Subviews/` (leaf components).
- Depends on: ViewModels, `UserManager`, `CallCenter`, `ClickMeAPI.shared` (default injection).
- Used by: shells and `ClickMe2026App`.

## Data Flow

### Primary Request Path (screen loads data)

### Session Restore and Route Selection (cold launch)

### Realtime Event Path

### Push Notification Path

### Voice Call Path

### State Management

- Cross-screen state lives in singletons: `UserManager` (auth, profile, mode), `CallCenter` (call), `PushRouter` (push), `CategoryStore` (categories), `RealtimeService` (socket).
- Per-screen state lives in `@Published` properties of ViewModels, typically a `LoadState` (`ClickMe2026/Model/UIModels/LoadState.swift`) per section.
- Navigation state lives in `HomeNavigationPath` (`ClickMe2026/Views/Extensions/HomeNavigationPath.swift`), one per tab, owned by the shell with `@StateObject`.
- Persisted state: access and refresh tokens in Valet keychain (`UserManager.valet`, identifier `ClickMe`); `hasSeenOnboarding`, `currentMode`, and the cached profile in `UserDefaults`.

## Key Abstractions

- Purpose: Single source of session truth (who is logged in, which mode, which profile).
- Examples: `ClickMe2026/Managers/UserManager.swift`
- Pattern: `@MainActor @Observable` singleton. Read directly in views; `@Observable` tracks reads without a property wrapper.
- Purpose: Typed REST surface.
- Examples: `ClickMe2026/Network/ClickMeAPI.swift`, `ClickMe2026/Network/ClickMeAPI+Booking.swift`
- Pattern: `final class` singleton with `extension` per feature. Tests replace `NetworkService` through `init(baseURL:service:)`, with `ClickMe2026Tests/Support/MockURLProtocol.swift` as the stub.
- Purpose: Uniform loading/loaded/error state for async sections.
- Examples: `ClickMe2026/Model/UIModels/LoadState.swift`, used by `ExploreClientViewModel.categoriesState`.
- Pattern: `@Published var xState: LoadState` per section.
- Purpose: Route pushes into the correct tab and mode.
- Examples: `ClickMe2026/Views/Extensions/HomeNavigationPath.swift`, `ClickMe2026/Managers/PushRouter.swift`
- Pattern: Typed `Hashable` route values appended to `NavigationPath`. Push events map to `PushDestination` cases such as `.bookingDetail(bookingId:)`.
- Purpose: Render screens without network.
- Examples: `ExploreClientViewModel.init(...)` second initializer; `ClickMe2026/Views/Extensions/PreviewNavHarness.swift`; `ClickMe2026/Debug/PreviewSecrets.swift` (tracked and token-free; tokens come from the gitignored `PreviewSecrets.local.json`).
- Pattern: A ViewModel init that installs canned data as if a load succeeded.

## Entry Points

- Location: `ClickMe2026/ClickMe2026App.swift`
- Triggers: iOS app launch.
- Responsibilities: Root `WindowGroup`, route state machine, keyboard toolbar, mode-to-route mirroring.
- Location: `ClickMe2026/ClickMe2026AppDelegate.swift`
- Triggers: UIKit lifecycle, APNs, FCM token, notification taps and foreground arrivals.
- Responsibilities: Firebase and Stripe configuration, system chrome colors, push token forwarding, `refreshPushTokenBinding()` on every activation.
- Location: `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift`, `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift`
- Triggers: Route becomes `.clientHome` or `.expertHome`.
- Responsibilities: `TabView` shell (client: Explore, Search, Bookings, Chats, Profile; expert: Dashboard, Bookings, Topics, Chats, Profile), per-tab navigation paths, call overlay, push-driven tab selection.
- Location: `ClickMe2026/Views/Screens/Splash/SplashView.swift`
- Triggers: App start.
- Responsibilities: Auto-login attempt and initial route decision.
- Location: `ClickMe2026/Views/Screens/Login Flow/Login/LoginView.swift`
- Triggers: Route `.login` or `.signupSetup`.
- Responsibilities: Email/password sign-in. The `.signupSetup` path passes `startAtSignupSetup: true` and `hydrateFrom:` the expert profile to resume onboarding.

## Architectural Constraints

- **Threading:** UI and all managers (`UserManager`, `CallCenter`, `PushRouter`, `CategoryStore`, `RealtimeService`, `AgoraManager`, all ViewModels) are `@MainActor`. `NetworkService` is a `final class` using async `URLSession` calls and is not actor-isolated. `TokenRefresher` is an actor. Agora delegate callbacks are `nonisolated` and hop to the main actor (`ClickMe2026/Managers/AgoraManager.swift`).
- **Global state:** Singletons `UserManager.shared`, `ClickMeAPI.shared`, `RealtimeService.shared`, `CallCenter.shared`, `PushRouter.shared`, `CategoryStore.shared`, `AppEnvironment.current` (static, parsed once). Shared persistence: Valet keychain identifier `ClickMe`; `UserDefaults.standard` keys `hasSeenOnboarding`, `currentMode`, cached profile, and APNs token.
- **Environment configuration:** `Environments.plist` has `Current = Production`. `Development` and `Staging` currently point to the same `BaseURL` (`https://clickme-backend-production.up.railway.app/api/v1`) and the same test Stripe key, so they are not isolated backends. Switching environments requires editing `Current`, and the Stripe and Agora keys ship in the binary.
- **Mode mirroring:** `ClickMe2026App` mirrors `UserManager.currentMode` onto `AppRoute` only while the route is `.clientHome` or `.expertHome`. Logout forces `.login` when `isLoggedIn` becomes false. Changes to these rules must keep both observers in sync.
- **Single-call invariant:** `CallCenter` holds at most one active call (a single `viewModel`). Any new surface that starts a call must go through `startCall`, and restricted actions should read `isCallActive` or call `attempt(...)`.
- **Circular imports:** Not applicable in the Swift sense. Cross-folder dependencies flow from `Views` to `Managers`, `Network`, and `Model`. `Network` does not import `Views` (verified by search). Three `Managers` files call `ClickMeAPI` directly.
- **Documentation drift:** `ClickMe2026/Views/Extensions/HomeNavigationPath.swift` says tabs share the shell's single `NavigationStack`, while `HomeClientView.swift` and `HomeExpertView.swift` say each tab owns its own stack. The code uses per-tab paths, so the tab-owned-stack description is the accurate one.

## Anti-Patterns

### Views calling `ClickMeAPI.shared` directly

### Mixed observation models

### Models declared in View files

### Per-screen design token enums duplicating the global palette

## Error Handling

- 401 triggers one refresh-and-retry through `TokenRefresher`. If the refresh fails, `UserManager.isAuthRejection` drives logout.
- 403 `ACCOUNT_SUSPENDED` triggers `suspensionHandler`, which clears the session and sets `UserManager.wasSuspended`. The splash/login route shows the message.
- Validation errors decode through `FieldValidationErrorResponse.swift` and `FieldError.swift`, then render on `ValidatedField` components.
- Silent failures in push registration are logged only in `#if DEBUG` (`ClickMe2026AppDelegate`).

## Cross-Cutting Concerns

<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-fast` for a trivial task inline, with no subagents and no PLAN.md
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
