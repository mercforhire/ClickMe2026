---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
# Codebase Structure

**Analysis Date:** 2026-11-07

## Directory Layout

```
ClickMe2026/                          # repo root (git)
├── ClickMe2026/                      # app target source (634 Swift files in repo)
│   ├── ClickMe2026App.swift          # @main entry, AppRoute state machine
│   ├── ClickMe2026AppDelegate.swift  # Firebase/Stripe bootstrap, APNs/FCM, notification delegate
│   ├── Configuration/                # AppEnvironment, StripeConfiguration
│   ├── Debug/                        # PreviewSecrets.swift (gitignored)
│   ├── Managers/                     # App-wide singleton services
│   ├── Model/                        # Wire + display types
│   ├── Network/                      # REST client and per-feature endpoint extensions
│   ├── Realtime/                     # Socket.IO service and event payloads
│   ├── Theme/                        # Brand palette and font tokens
│   ├── Utils/                        # DateUtil, Utils
│   ├── Views/                        # All SwiftUI UI (450 files)
│   ├── Preview Content/              # Preview asset catalog
│   ├── Environments.plist            # Dev/Staging/Production base URLs and keys
│   ├── GoogleService-Info.plist      # Firebase client config
│   ├── Info.plist, ClickMe2026.entitlements, PrivacyInfo.xcprivacy
│   ├── Localizable.xcstrings         # String catalog
│   ├── LaunchScreen.storyboard
│   └── AllTests.xctestplan           # Test plan referenced by CI
├── ClickMe2026Tests/                 # XCTest unit + smoke tests
│   ├── Network/Auth/                 # LoginTests, ResetPasswordTests
│   ├── Integration/                  # AuthSmokeTests, SignupSmokeTests (live backend)
│   ├── Support/                      # MockURLProtocol, APITestFactory, SmokeConfig
│   └── Fixtures/Auth/                # JSON fixtures for auth responses
├── ClickMe2026UITests/               # XCUITest page objects and behaviours
│   ├── ViewObjects/                  # HomeView.swift
│   └── Behaviours/                   # RefreshBehaviour.swift
├── Constants/                        # Shared static tables (Countries, Timezones, icons, weekday headers)
├── ClickMe.xcodeproj/                # Xcode project, shared schemes, SPM resolution
├── .github/                          # CI workflows, composite action, PR template
├── ci_scripts/                       # ci_post_clone.sh (Xcode Cloud style hook)
├── scripts/                          # run-smoke-tests.sh
├── .claude/                          # Claude Code settings (settings.local.json)
├── .planning/codebase/               # Generated codebase analysis (this document)
├── CLAUDE.md                         # Project and cross-repo instructions
├── APP_STORE_REVIEW_CHECKLIST.md     # Release checklist
├── CODEOWNERS, ExportOptions.plist   # Ownership and export settings
└── .swiftlint.yml, .swiftformat, .editorconfig  # Lint and format config
```

## Directory Purposes

**`ClickMe2026/Views/Screens/`:**
- Purpose: One folder per user flow. Each feature folder holds a `*View.swift`, a `*ViewModel.swift`, and usually a `Subviews/` folder.
- Contains: 439 Swift files across 10 top-level flows.
- Key files: `Client Mode/Home/HomeClientView.swift`, `Expert Mode/Home/HomeExpertView.swift`, `Splash/SplashView.swift`, `Login Flow/Login/LoginView.swift`, `Signup Flow/SignupAccumulator.swift`.

**`ClickMe2026/Views/Screens/` top-level flows:**
- `Splash/`: launch and auto-login routing (`SplashView.swift`, `SplashViewModel.swift`, `Subviews/ClickMeMark.swift`, `HeartKnotShape.swift`).
- `Login Flow/`: `Login/`, `Forget Password/`, `Set New Password/`, `Password Changed/`.
- `Signup Flow/`: `Initial/`, `Basic Info/` (with `Language Selection/`), `Timezone/`, `Profile Photo/`, `Setup Tags/`, `Verify Email/`, `Overview/`, `Signup Review/`, plus `SignupAccumulator.swift` at the flow root.
- `Onboarding/`: first-run carousel (`OnboardingView.swift`, `OnboardingViewModel.swift`).
- `Client Mode/`: client tabs and flows. `Home/` (shell), `Explore/` (with `Categories Modal/`), `Search/`, `My Bookings/`, `Make a Booking/`, `Booking Summary/`, `Booking Note/`, `Expert Profile/`, `Reviews/`, `Reschedule/`, `Cancellation/`, `Cancellation Policies/`, `Favorites/`, `Payments/`, `Profile/`, `Request Sent/`, `Upcoming Booking Details/`, `Write Review/`.
- `Expert Mode/`: expert tabs and flows. `Home/` (tab shell), `Expert Dashboard/`, `Upcoming Bookings/`, `Incoming Requests/`, `Request decision/`, `Topics/` (with `Topic Editor/`), `Availability/`, `Payouts/`, `Tax Profile/`, `Profile/`, `Client Profile/`, `Booking Summary/`, `Booking Note/`, `Reschedule/`, `Cancellation/`, `Confirmed/`, `Settings/`.
- `Chat/`: `Conversations/` (list), `Chatting/` (thread), `Report and Block/`.
- `Call/`: `Ready/` (pre-call lobby) and `Calling/` (in-call surface, `MeetingCallView.swift`, `CallOverlayHost.swift`, `ExternalMeetingProvider.swift`).
- `Notification/`: `NotificationsListView.swift` and `Subviews/NotificationRow.swift`.
- `Settings/`: `Account Security/`, `Client Profile Settings/`, `Delete account/`, `Feedback/`, `Help/`, `Mode Switching/`, `Notifications/`, `Payment Methods/`.

**`ClickMe2026/Views/Components/`:**
- Purpose: Reusable, feature-agnostic UI.
- Contains: `Avatar/TopBarAvatarButton.swift`, `Backgrounds/GreenGlowBlobLayer.swift`, `Buttons/AsyncSaveButton.swift`, `ButtonStyles/PressScaleButtonStyle.swift`, `Theme/`, `Web/SafariView.swift`, `ValidatedField.swift`.

**`ClickMe2026/Views/Extensions/`:**
- Purpose: View modifiers, environment values, and preview harnesses.
- Contains: `HomeNavigationPath.swift`, `KeyboardDismissToolbar.swift`, `MicPermissionDeniedAlert.swift`, `PreviewNavHarness.swift`, `View+Placeholder.swift`.

**`ClickMe2026/Managers/`:**
- Purpose: App-wide singleton services that hold state across screens.
- Contains: `UserManager.swift`, `CallCenter.swift`, `PushRouter.swift`, `CategoryStore.swift`, `AgoraManager.swift`.

**`ClickMe2026/Network/`:**
- Purpose: HTTP transport and endpoint definitions.
- Contains: `NetworkService.swift` (transport and codecs), `ClickMeAPI.swift` (client core and list payload wrappers), `APIRequestURLs.swift` (path table), `Error+UserMessage.swift`, and `ClickMeAPI+<Feature>.swift` extension files for Account, Analytics, Auth, Availability, Booking, Call, Chats, Clients, Discovery, ExpertProfile, Favorites, Feedback, Me, Media, Meta, Notifications, PaymentMethods, Payouts, Reviews, Signup, Support, TaxProfile, UserProfile, and Users.

**`ClickMe2026/Model/`:**
- Purpose: Data types.
- Contains:
  - `Requests/`: Encodable request bodies (`SignupRequest.swift`, `UpdateUserProfileRequest.swift`, `ReportUserRequest.swift`, …).
  - `Responses/`: Decodable response envelopes (`LoginData.swift`, `MeData.swift`, `ClientHomeData.swift`, `FieldValidationErrorResponse.swift`, …).
  - `Responses/Children/`: Row and item types nested in responses (`ChatThreadItem.swift`, `ExpertBookingItem.swift`, `PaginationMeta.swift`, `TimeSlot.swift`, …).
  - `Enums/`: Backend vocabularies (`BookingStatus.swift`, `UserRole.swift`, `MessageType.swift`, `ErrorCode.swift`, `JSONValue.swift`, `NotificationCategory.swift`).
  - `UIModels/`: Presentation-layer types (`LoadState.swift`, `UpcomingBooking.swift`, `PastBooking.swift`, `BookingTimeSlot.swift`, `ChatDisplayModels.swift`).
  - `Push/PushEvent.swift`: Parsed push payload.
  - Top-level: `Category.swift`, `BookingCalendarPayload.swift`.

**`ClickMe2026/Realtime/`:**
- Purpose: Socket.IO connection and event payloads.
- Contains: `RealtimeService.swift`, `RealtimeEvents.swift`.

**`ClickMe2026/Configuration/`:**
- Purpose: Environment and third-party key selection.
- Contains: `AppEnvironment.swift`, `StripeConfiguration.swift`.

**`ClickMe2026/Theme/`:**
- Purpose: Global design tokens.
- Contains: `Brand.swift` (color palette and documented as the source of truth), `BrandFont.swift`.

**`ClickMe2026/Utils/`:**
- Purpose: Date and general helpers. Contains `DateUtil.swift` and `Utils.swift`.

**`Constants/` (repo root, outside the `ClickMe2026/` source folder):**
- Purpose: Static lookup tables used by views.
- Contains: `Countries.swift`, `Timezones.swift`, `CategoryIconMap.swift`, `WeekdayHeaders.swift`.
- Note: Confirm target membership in `ClickMe.xcodeproj/project.pbxproj` before importing these from new code.

**`ClickMe2026Tests/`:**
- Purpose: Unit and integration tests.
- Contains: `Network/Auth/` (`LoginTests.swift`, `ResetPasswordTests.swift`), `Integration/` (smoke tests that exercise the live backend; configuration in `Support/SmokeConfig.swift`), `Support/` (`MockURLProtocol.swift` stub, `APITestFactory.swift`, `Bundle+Fixtures.swift`), `Fixtures/Auth/*.json`.

**`ClickMe2026UITests/`:**
- Purpose: UI automation with page-object style.
- Contains: `ViewObjects/HomeView.swift`, `Behaviours/RefreshBehaviour.swift`, `ExampleUITests.swift`.

**`.github/`:**
- Purpose: CI.
- Contains: `workflows/test.yml` (runs SwiftLint then tests on `macos-26`, Xcode 26, `AllTests` plan on `iPhone 16` simulator), `workflows/build.yml`, `actions/code-signing-setup/action.yml`, `dependabot.yml`, `pull_request_template.md`.

## Key File Locations

**Entry Points:**
- `ClickMe2026/ClickMe2026App.swift`: SwiftUI `@main` App and route state.
- `ClickMe2026/ClickMe2026AppDelegate.swift`: UIKit delegate for Firebase, Stripe, APNs, FCM, notifications.

**Configuration:**
- `ClickMe2026/Environments.plist`: Environment selector (`Current`) and per-environment `BaseURL`, Stripe publishable key, Agora App ID.
- `ClickMe2026/Configuration/AppEnvironment.swift`: Parses the plist once.
- `ClickMe2026/Info.plist`, `ClickMe2026/ClickMe2026.entitlements`: iOS metadata and app capabilities.
- `ClickMe2026/PrivacyInfo.xcprivacy`: Privacy manifest.
- `.swiftlint.yml`, `.swiftformat`, `.editorconfig`: Lint and format rules (4-space indent, LF, 120-column guidance).

**Core Logic:**
- `ClickMe2026/Managers/UserManager.swift`: Session, mode, and push token lifecycle.
- `ClickMe2026/Network/NetworkService.swift`: Transport and retry.
- `ClickMe2026/Network/ClickMeAPI.swift`: Endpoint entry point.
- `ClickMe2026/Realtime/RealtimeService.swift`: Socket events.
- `ClickMe2026/Managers/CallCenter.swift`: In-call state.

**Testing:**
- `ClickMe2026Tests/Support/MockURLProtocol.swift`: Network stub for unit tests.
- `ClickMe2026/AllTests.xctestplan`: Test plan used by CI.
- `scripts/run-smoke-tests.sh`: Smoke test runner.

## Naming Conventions

**Files:**
- Screen views: `<Feature>View.swift`, for example `ExploreClientView.swift`, `ChattingView.swift`.
- ViewModels: `<Feature>ViewModel.swift` next to the view.
- Screen subviews: `Subviews/<Screen><Element>.swift`, prefixed with the screen name, for example `Subviews/ChattingInputBar.swift`, `Subviews/ExpertProfileHero.swift`.
- Per-screen design tokens: `Subviews/<Screen>Brand.swift` (for example `ChattingBrand.swift`).
- Feature endpoint extensions: `ClickMeAPI+<Feature>.swift` (for example `ClickMeAPI+Booking.swift`).
- Request bodies: `<Action><Thing>Request.swift` in `Model/Requests/`.
- Response envelopes: `<Thing>Data.swift` (for example `ClientHomeData.swift`) or `<Thing>Response.swift`.
- Response row types: `<Thing>Item.swift` in `Model/Responses/Children/`.
- Enums: `<Concept>.swift` in `Model/Enums/`, with values that mirror backend vocabularies.
- Tests: `<Area>Tests.swift` for unit tests, `<Area>SmokeTests.swift` for live smoke tests.

**Directories:**
- Screen folders: Title Case with spaces, matching the user-facing flow name, for example `Client Mode/`, `Login Flow/`, `Delete account/`. Note the inconsistent casing in `Settings/Delete account/` and `Expert Mode/Request decision/`.
- Non-screen folders: PascalCase, for example `Managers/`, `Network/`, `Realtime/`.
- Each screen has a `Subviews/` folder when it has more than a few leaf components.

**Types:**
- Views: `<Name>View` or `<Name>Screen` (`SplashScreenView`, `MeetingCallView`). Shells are `Home<Mode>View`.
- ViewModels: `<Name>ViewModel`.
- Services and singletons: `<Name>Manager`, `<Name>Center`, `<Name>Service`, `<Name>Store`, `<Name>Router`. Most expose a `static let shared` (`AgoraManager` is created by its owner instead).
- Tab enums: `Home<Mode>Tab` (`HomeClientTab`, `HomeExpertTab`).

## Where to Add New Code

**New screen or flow (client or expert):**
- Primary code: `ClickMe2026/Views/Screens/<Mode or Flow>/<Feature>/` containing `<Feature>View.swift` and `<Feature>ViewModel.swift`.
- Leaf components: `ClickMe2026/Views/Screens/<Mode or Flow>/<Feature>/Subviews/`.
- Tests: `ClickMe2026Tests/Network/<Area>/` for API behavior, or `ClickMe2026Tests/Support/` for shared test helpers.
- Register the tab in the shell if it is a top-level tab: `HomeClientView.swift` or `HomeExpertView.swift`, and add a `HomeNavigationPath` `@StateObject` for the tab.

**New API endpoint:**
- Path constant: add to `ClickMe2026/Network/APIRequestURLs.swift`.
- Request body: `ClickMe2026/Model/Requests/<Name>Request.swift`.
- Response: `ClickMe2026/Model/Responses/<Name>Data.swift` (and row types in `Model/Responses/Children/`).
- Method: the matching `ClickMe2026/Network/ClickMeAPI+<Feature>.swift`. Create a new extension file for a new feature area.
- Confirm the route and schema in the backend repo (`src/routes`, `src/schemas`, `openapi/clickme-api.yaml`) before writing these types, as `CLAUDE.md` requires.

**New realtime event:**
- Payload struct: `ClickMe2026/Realtime/RealtimeEvents.swift`.
- Socket binding and handler dictionary: `ClickMe2026/Realtime/RealtimeService.swift` (add `socket.on(...)`, a handler map, and an `onX` subscription method).

**New app-wide service:**
- Implementation: `ClickMe2026/Managers/<Name>.swift`, with `@MainActor` and `static let shared` (follow `CategoryStore.swift`).

**New shared UI component:**
- Feature-agnostic: `ClickMe2026/Views/Components/<Category>/<Name>.swift`.
- Modifier or environment helper: `ClickMe2026/Views/Extensions/`.
- Colors and fonts: add to `ClickMe2026/Theme/Brand.swift` or `BrandFont.swift`, not a new per-screen `*Brand` enum.

**New model or enum:**
- Wire enum: `ClickMe2026/Model/Enums/<Concept>.swift`.
- Presentation-only type: `ClickMe2026/Model/UIModels/<Name>.swift`. Do not declare these inside a view file.

**New utility:**
- Date formatting: `ClickMe2026/Utils/DateUtil.swift`.
- Other helpers: `ClickMe2026/Utils/Utils.swift`.

**New static lookup data:**
- `Constants/<Name>.swift`, after confirming target membership.

## Special Directories

**`ClickMe.xcodeproj/xcuserdata/`:**
- Purpose: Per-user Xcode state (breakpoints, window layout).
- Generated: Yes (by Xcode).
- Committed: Ignored by `.gitignore` (`xcuserdata`). Some files appear in the working tree and must not be added.

**`ClickMe2026/Debug/`:**
- Purpose: Local preview credentials for SwiftUI previews (`PreviewSecrets.swift`).
- Generated: No, hand-written per developer.
- Committed: No. Listed in `.gitignore`. Never commit or quote its contents.

**`ClickMe2026/Preview Content/`:**
- Purpose: Asset catalog for SwiftUI previews.
- Generated: No.
- Committed: Yes.

**`.planning/`:**
- Purpose: Planning artifacts. `.planning/codebase/` holds these analysis documents.
- Generated: Yes (by GSD mapping commands).
- Committed: Owned by the orchestrator. Do not add application code here.

**`.claude/`:**
- Purpose: Claude Code project settings. `settings.local.json` lists additional working directories for the Android and Backend repos.
- Generated: No.
- Committed: Local settings file, do not treat as application configuration.

**`ClickMe2026/Assets.xcassets` and `*.xcassets` (not in this listing, excluded from the `find` output):**
- Purpose: Image, icon, and color assets, including the app icon set.
- Generated: No.
- Committed: Yes.

---

*Structure analysis: 2026-11-07*
