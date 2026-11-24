# ClickMe for iOS

ClickMe is a marketplace where clients book paid or free sessions with experts. The app is live on the App Store. A session runs as an in-app voice call or over an external Skype or Zoom meeting. The app is built in SwiftUI with Swift 6 strict concurrency and targets iOS 18 and later.

**Download:** [App Store](https://apps.apple.com/app/id6806057145) · [Google Play](https://play.google.com/store/apps/details?id=com.uptrendinvestments.clickmeapp)

## Features

**Clients**
- Explore categories, search experts, read expert profiles and save favourites.
- Book a session with a topic, a time slot and a note, then pay with Stripe PaymentSheet or book a free session.
- Manage bookings: reschedule, cancel with a refund preview, and write reviews after a session.
- Save payment methods and review past payments.

**Experts**
- Dashboard, incoming requests with an accept or decline decision, and confirmed and upcoming bookings.
- Availability slots, topics with prices, and a tax profile.
- Payouts through Stripe Connect onboarding in a web authentication session.

**Shared**
- Email signup with verification, profile photo, tags and timezone, plus login and password reset.
- Switch between client and expert mode with a separate tab shell for each.
- In-app voice calls over Agora, with a join window enforced on the client. Sessions that use an external Skype or Zoom link open that link instead. There is no in-app video.
- Real-time chat over Socket.IO with typing indicators, read receipts, presence, report and block.
- Push notifications through FCM and APNs that route to the right screen.
- Account security, notification settings, feedback, help and account deletion.

## Tech stack

| Area | Technology | Version |
|------|------------|---------|
| Language | Swift, strict concurrency `complete` | 6.0 |
| UI | SwiftUI with Observation, UIKit for system chrome | iOS 18.0 minimum |
| Tooling | Xcode | 26 |
| Payments | stripe-ios-spm (StripePaymentSheet) | 26.2.0 |
| Calls | AgoraRtcEngine_iOS (RtcBasic, voice only) | 4.6.2 |
| Push and analytics | firebase-ios-sdk (Messaging, Analytics) | 12.17.0 |
| Realtime | socket.io-client-swift over Starscream | branch-pinned, 4.0.8 |
| Secure storage | Valet (Keychain, refresh token) | 5.1.0 |
| Networking | Foundation `URLSession` | system |
| Tests | Swift Testing, XCTest for UI tests | bundled with Xcode |
| Style | SwiftLint, SwiftFormat, EditorConfig | see `.swiftlint.yml`, `.swiftformat`, `.editorconfig` |

Pinned package versions are in `ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Architecture

The app is a single target. Each screen is a self-contained folder, shared state lives in a few singleton managers, and all network access goes through one typed API client.

```
ClickMe2026/
  Configuration/   environment selection, Stripe setup
  Debug/           preview-only fixtures
  Managers/        session, calls, push routing, categories
  Model/           Requests, Responses, Enums, UIModels, Push
  Network/         URLSession transport and typed endpoints
  Realtime/        Socket.IO client and event payloads
  Theme/           brand colors and fonts
  Utils/           pure rules and policies
  Views/           Components, Extensions, Screens
```

- Each screen folder holds a View, a ViewModel and a Subviews folder, for example `ClickMe2026/Views/Screens/Client Mode/Make a Booking/`.
- Client and expert shells are `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` and `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift`, each with its own tabs and navigation path.
- Managers are `static let shared` singletons, such as `ClickMe2026/Managers/UserManager.swift` and `ClickMe2026/Managers/CallCenter.swift`.
- `ClickMe2026/Network/ClickMeAPI.swift` is the entry point. Endpoints live in per-feature extensions (`ClickMe2026/Network/ClickMeAPI+*.swift`), and routes are listed in `ClickMe2026/Network/APIRequestURLs.swift`.
- `ClickMe2026/Realtime/RealtimeService.swift` handles chat, presence, booking and call events, typed in `ClickMe2026/Realtime/RealtimeEvents.swift`.
- Wire types are split into `ClickMe2026/Model/Requests/`, `ClickMe2026/Model/Responses/` and `ClickMe2026/Model/Enums/`.
- Business rules are kept as pure types under `ClickMe2026/Utils/` so they can be unit tested without UI.

## Engineering highlights

- **Single-flight token refresh.** `TokenRefresher` is an actor in `ClickMe2026/Network/NetworkService.swift`. Concurrent 401 responses share one in-flight refresh and the original request is retried once. This matters because the server revokes a session when it sees an old refresh token reused. A suspended account is handled by a dedicated handler.
- **One error-to-text path.** `Error.userMessage` in `ClickMe2026/Network/Error+UserMessage.swift` prefers the server's message, and the UI branches on `ClickMe2026/Model/Enums/ErrorCode.swift` instead of matching strings.
- **Swift 6 isolation.** Managers and view models are `@MainActor`. The Agora delegate callbacks in `ClickMe2026/Managers/AgoraManager.swift` are `nonisolated` and hop to the main actor.
- **One rule for Join.** `ClickMe2026/Utils/JoinWindow.swift` decides when Join is shown: the status must be confirmed, in progress or completed, Join opens 60 minutes before the start, and a server-approved reconnect is allowed for 60 minutes after the end. It mirrors the server rule, takes the clock as a parameter and never replaces the server's final check.
- **Push routing.** `ClickMe2026/Managers/PushRouter.swift` maps push events to typed destinations, and `ClickMe2026/Managers/PushForegroundPolicy.swift` decides how a push is shown while the app is open.
- **One call at a time.** `ClickMe2026/Managers/CallCenter.swift` holds at most one active call, so every call entry point goes through the same gate.

## Getting started

Requirements: macOS with Xcode 26 and the iOS 18 SDK.

1. Open `ClickMe.xcodeproj` in Xcode. Swift Package Manager resolves the packages pinned in `ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
2. Select the `ClickMe2026` scheme and an iOS 18 simulator.
3. Build and run.

Configuration:
- `ClickMe2026/Environments.plist` has a `Current` key that selects Development, Staging or Production. Each entry supplies a base URL, a Stripe publishable key and an Agora app ID, read once at launch by `ClickMe2026/Configuration/AppEnvironment.swift`.
- Firebase reads `ClickMe2026/GoogleService-Info.plist`.
- Running on a device requires your own signing team.

## Testing

The test suite has 117 Swift Testing files with 1,313 `@Test` cases under `ClickMe2026Tests/`, covering Auth, Booking, Calls, Chat, ExpertMode, Integration, Model, Network, Push, Settings, Signup and Utils. `ClickMe2026Tests/Support/MockURLProtocol.swift` stubs `URLSession`, and JSON fixtures live in `ClickMe2026Tests/Fixtures/`. `ClickMe2026UITests/` holds 3 XCTest files with screen objects and behaviours. `ClickMe2026/AllTests.xctestplan` runs both targets.

```
xcodebuild test \
  -project ClickMe.xcodeproj \
  -scheme ClickMe2026 \
  -testPlan AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

`scripts/run-smoke-tests.sh` runs smoke tests against a simulator, with test-account credentials read from environment variables.

## Continuous integration

- `.github/workflows/test.yml` runs on pull requests to main and on manual dispatch. On a macOS 26 runner it lints with SwiftLint, resolves packages, builds for testing, runs the AllTests plan on an iPhone 16 simulator and uploads the result bundle on failure.
- `.github/workflows/build.yml` runs on pushes to `release/**` branches and on manual dispatch, with an archive-only option. It archives, exports with `ExportOptions.plist` and uploads to TestFlight. Signing is set up by `.github/actions/code-signing-setup/action.yml`.
- `.github/dependabot.yml` requests weekly Swift and GitHub Actions updates, and `ci_scripts/ci_post_clone.sh` trusts Xcode package plugins and macros.

## Related repositories

- An Android port in Kotlin and Jetpack Compose mirrors this app's folder tree and REST contract.
- A private Node.js and Express backend owns the REST and WebSocket contract.

Both live in separate repositories.
