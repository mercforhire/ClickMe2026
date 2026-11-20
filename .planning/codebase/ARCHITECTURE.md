---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
<!-- refreshed: 2026-11-07 -->

# Architecture

**Analysis Date:** 2026-11-07

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                 SwiftUI App Entry  `ClickMe2026/ClickMe2026App.swift`     │
│   @UIApplicationDelegateAdaptor -> `ClickMe2026AppDelegate.swift`         │
│   Root `AppRoute` state: splash | login | signupSetup | clientHome | expertHome │
└───────────────┬───────────────────────────────┬──────────────────────────┘
                │                               │
                ▼                               ▼
┌──────────────────────────────┐   ┌────────────────────────────────────────┐
│ Auth / Flow screens          │   │ Shells (TabView)                        │
│ `Views/Screens/Splash`       │   │ `Views/Screens/Client Mode/Home/`       │
│ `Views/Screens/Login Flow`   │   │ `Views/Screens/Expert Mode/Home/`       │
│ `Views/Screens/Signup Flow`  │   │  + per-tab `HomeNavigationPath`         │
│ `Views/Screens/Onboarding`   │   │  + CallCenter overlay + PushRouter      │
└──────────────┬───────────────┘   └──────────────────┬─────────────────────┘
               │  feature screens (View + ViewModel + Subviews)          │
               ▼                                                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ViewModels  `Views/Screens/**/<Feature>ViewModel.swift` (ObservableObject) │
│   inject `api: ClickMeAPI = .shared`, publish `LoadState` + data          │
└───────────────┬───────────────────────────────┬─────────────────────────┘
                │                               │
                ▼                               ▼
┌────────────────────────────────┐   ┌──────────────────────────────────────┐
│ Session + app services          │   │ REST client  `Network/ClickMeAPI.swift` │
│ `Managers/UserManager.swift`    │   │  + `Network/ClickMeAPI+<Feature>.swift` │
│ `Managers/CallCenter.swift`     │   │  path table `Network/APIRequestURLs`    │
│ `Managers/PushRouter.swift`     │   └───────────────┬──────────────────────┘
│ `Managers/CategoryStore.swift`  │                   │
│ `Managers/AgoraManager.swift`   │                   ▼
└───────┬─────────────────┬───────┘   ┌──────────────────────────────────────┐
        │                 │           │ `Network/NetworkService.swift`        │
        ▼                 ▼           │  URLSession, JSON codec, 401 refresh  │
┌───────────────┐ ┌──────────────────┐└───────────────┬──────────────────────┘
│ Realtime      │ │ Keychain/UserDef │                │ HTTPS (Bearer JWT)
│ `Realtime/`   │ │ Valet, UserDefaults│              ▼
│ socket.io     │ └──────────────────┘   ┌──────────────────────────────────────┐
└───────┬───────┘                        │ ClickMe backend (`AppEnvironment`)   │
        └────────── WebSocket ──────────▶ │ REST `/api/v1` + Socket.IO          │
                                         └──────────────────────────────────────┘
```

Third-party SDK surface (from `ClickMe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`): Firebase Messaging, Stripe PaymentSheet, Agora RTC, socket.io-client-swift, Valet.

## Pattern Overview

**Overall:** SwiftUI MVVM-style feature modules over a single shared REST client, with app-wide singleton services for session, realtime, calls, and push. Navigation is state-driven at the root and `TabView` + `NavigationStack` inside each shell.

**Key Characteristics:**
- Single app target; all source lives under `ClickMe2026/` (no local feature packages).
- Feature folders under `ClickMe2026/Views/Screens/` are self-contained: `<Name>View.swift`, `<Name>ViewModel.swift`, and a `Subviews/` folder of small, screen-prefixed view components.
- Root navigation is a private `AppRoute` enum held in `@State` in `ClickMe2026App`, not a router object. Mode (client vs expert) is mirrored onto this route.
- Two parallel UI shells share the same services: `HomeClientView` (`Views/Screens/Client Mode/Home/HomeClientView.swift`) and `HomeExpertView` (`Views/Screens/Expert Mode/Home/HomeExpertView.swift`).
- A single `ClickMeAPI.shared` instance is the network entry point; endpoints are grouped by feature in extension files.
- Models are split by direction: `Model/Requests` (Encodable bodies), `Model/Responses` (Decodable envelopes, item types in `Model/Responses/Children/`), `Model/Enums`, `Model/UIModels` (display-facing), `Model/Push`.

## Layers

**App entry and lifecycle:**
- Purpose: Bootstrap Firebase/Stripe, route between splash/login/signup/home, and hand push events to routers.
- Location: `ClickMe2026/ClickMe2026App.swift`, `ClickMe2026/ClickMe2026AppDelegate.swift`
- Contains: `@main` App struct, `AppRoute` enum, UIKit delegate for APNs/FCM and `UNUserNotificationCenter`.
- Depends on: `UserManager`, `PushRouter`, `StripeConfiguration`, `PushEvent`.
- Used by: iOS runtime only.

**Configuration:**
- Purpose: Select the environment and expose per-environment keys.
- Location: `ClickMe2026/Configuration/AppEnvironment.swift`, `ClickMe2026/Configuration/StripeConfiguration.swift`, `ClickMe2026/Environments.plist`
- Contains: `AppEnvironment.current` (parsed once from `Environments.plist` key `Current`, currently `Production`), `AppLinks.privacyPolicy`.
- Depends on: Bundle resources only.
- Used by: `ClickMeAPI.init`, `StripeConfiguration.configure()`, `AgoraManager`.

**Design system:**
- Purpose: Colors, fonts, and shared visual primitives.
- Location: `ClickMe2026/Theme/Brand.swift` (global palette, documented as the single source of truth), `ClickMe2026/Theme/BrandFont.swift`, `ClickMe2026/Views/Components/`, `ClickMe2026/Views/Extensions/`
- Contains: `Brand` enum tokens; reusable `ButtonStyles`, `Buttons/AsyncSaveButton.swift`, `ValidatedField.swift`, `Avatar/TopBarAvatarButton.swift`, `Backgrounds/GreenGlowBlobLayer.swift`, `Web/SafariView.swift`.
- Depends on: SwiftUI.
- Used by: every screen.

**Session and app services (singletons):**
- Purpose: Own cross-screen state that outlives any single view.
- Location: `ClickMe2026/Managers/`
- Contains:
  - `UserManager.swift` (`@MainActor @Observable final class`, `UserManager.shared`): auth state, `me`, `profile`, `expertProfile`, `currentMode`, token persistence, push token binding, logout.
  - `CallCenter.swift` (`@MainActor ObservableObject`, `CallCenter.shared`): the single in-progress voice call, minimize/expand, and "end call to change this" guards.
  - `PushRouter.swift` (`@MainActor ObservableObject`, `PushRouter.shared`): converts `PushEvent` to a `PushDestination` for the shells.
  - `CategoryStore.swift` (`ObservableObject`, `CategoryStore.shared`): cached `/categories` with a 7-day staleness window.
  - `AgoraManager.swift` (`@MainActor ObservableObject`): Agora RTC engine wrapper, mic/speaker state, permission checks.
- Depends on: `ClickMeAPI`, `RealtimeService`, `Valet`, `UserDefaults`, Firebase Messaging, Agora.
- Used by: shells, ViewModels, `ClickMe2026App`.

**Realtime:**
- Purpose: Socket.IO push channel for chat, presence, booking, and call events.
- Location: `ClickMe2026/Realtime/RealtimeService.swift`, `ClickMe2026/Realtime/RealtimeEvents.swift`
- Contains: `RealtimeService.shared` (`@MainActor`), per-event handler dictionaries keyed by `UUID`, returned as `RealtimeSubscription` tokens. Events (socket names): `message.new`, `message.read`, `user.status`, `typing.start`, `typing.stop`, `booking.update`, `call.ended`; decoded structs live in `RealtimeEvents.swift`.
- Depends on: `socket.io-client-swift`, a JWT from `UserManager`.
- Used by: chat ViewModels, booking/call screens.

**Networking:**
- Purpose: Authenticated HTTP and multipart transport plus typed endpoint methods.
- Location: `ClickMe2026/Network/`
- Contains:
  - `NetworkService.swift`: `final class` over `URLSession` (120 s timeout), snake_case JSON decoding with a custom multi-precision date decoder, bearer injection, one-shot 401 refresh-and-retry via `TokenRefresher` (actor), 403 `ACCOUNT_SUSPENDED` callback to `UserManager`, multipart upload.
  - `ClickMeAPI.swift`: `final class ClickMeAPI`, `static let shared`, holds `NetworkService` and `baseURL`; defines URL helpers and list-payload wrappers (`ChatsPayload`, `ExpertBookingsPayload`, etc.).
  - `APIRequestURLs.swift`: enum of endpoint paths with `:id` / `:device_id` placeholders.
  - `ClickMeAPI+<Feature>.swift` (about 20 files: Account, Auth, Booking, Call, Chats, Discovery, Favorites, Payouts, Reviews, Signup, and others): feature-scoped `async throws` methods.
  - `Error+UserMessage.swift`: maps errors to user-facing text.
- Depends on: `Model/Requests`, `Model/Responses`, `AppEnvironment`.
- Used by: ViewModels (preferred), and a subset of views directly (see Anti-Patterns).

**Models:**
- Purpose: Wire types and display types.
- Location: `ClickMe2026/Model/`
- Contains: `Requests/` (`SignupRequest.swift`, `UpdateUserProfileRequest.swift`, …), `Responses/` (`LoginData.swift`, `ClientHomeData.swift`, `MeData.swift`, `…`), `Responses/Children/` (row/item types such as `ChatThreadItem.swift`, `ExpertBookingItem.swift`), `Enums/` (`BookingStatus.swift`, `UserRole.swift`, `MessageType.swift`, `ErrorCode.swift`, `JSONValue.swift`), `UIModels/` (`UpcomingBooking.swift`, `LoadState.swift`, `BookingTimeSlot.swift`, `ChatDisplayModels.swift`), `Push/PushEvent.swift`.
- Depends on: Foundation only.
- Used by: `Network/`, ViewModels, Views.

**Feature screens:**
- Purpose: All user-facing flows.
- Location: `ClickMe2026/Views/Screens/` (439 Swift files across 10 top-level flows; see STRUCTURE.md).
- Contains: `View` (SwiftUI), `ViewModel` (`@MainActor ObservableObject`, `@Published` state), `Subviews/` (leaf components).
- Depends on: ViewModels, `UserManager`, `CallCenter`, `ClickMeAPI.shared` (default injection).
- Used by: shells and `ClickMe2026App`.

## Data Flow

### Primary Request Path (screen loads data)

1. A screen's ViewModel is created with `api: ClickMeAPI = .shared` (for example `ExploreClientViewModel.init(api:)` in `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`).
2. The ViewModel calls a feature method such as `api.<endpoint>()` defined in `ClickMe2026/Network/ClickMeAPI+Discovery.swift`.
3. The method builds the URL from `APIRequestURLs` and calls `NetworkService.httpRequest` (`ClickMe2026/Network/NetworkService.swift`).
4. `NetworkService` applies the bearer token, sends via `URLSession`, decodes the response envelope (snake_case to camelCase, custom ISO-8601 with fractional seconds).
5. On 401 it calls `TokenRefresher.refresh()` (actor) once, then retries. On 403 `ACCOUNT_SUSPENDED` it calls `suspensionHandler`, which `UserManager` wires to clear tokens and disconnect the socket.
6. The ViewModel sets `@Published` data and `LoadState`; the View re-renders.

### Session Restore and Route Selection (cold launch)

1. `ClickMe2026AppDelegate.didFinishLaunching` configures Firebase and Stripe, then sets `UNUserNotificationCenter` and `Messaging` delegates (`ClickMe2026/ClickMe2026AppDelegate.swift`).
2. `ClickMe2026App` starts at `AppRoute.splash` and `SplashScreenView` (`ClickMe2026/Views/Screens/Splash/SplashView.swift`) calls `UserManager.tryAutoLogin()` (`ClickMe2026/Managers/UserManager.swift`).
3. `SplashDestination` maps to `login`, `dashboard(mode)`, or `setupIncomplete`. `ClickMe2026App` writes the matching `AppRoute`.
4. Home shells mount; `UserManager` connects `RealtimeService` with the JWT and `PushRouter` observes pending destinations.

### Realtime Event Path

1. `RealtimeService.connect(token:)` opens a Socket.IO connection (`ClickMe2026/Realtime/RealtimeService.swift`).
2. Socket callbacks hop to `@MainActor` and decode payloads into `RealtimeEvents.swift` structs.
3. Each subscribed screen holds a `RealtimeSubscription`; the handler dictionary is walked to deliver the event. Deallocating the subscription removes its handler.

### Push Notification Path

1. FCM issues a registration token; `messaging(_:didReceiveRegistrationToken:)` calls `UserManager.registerPushToken` (`ClickMe2026/ClickMe2026AppDelegate.swift`).
2. Tapping a notification calls `PushEvent(userInfo:)` then `PushRouter.shared.handleTap(event)`. Foreground arrival calls `handleForegroundArrival`, which also bumps `newNotificationTick` for the notifications list (`ClickMe2026/Managers/PushRouter.swift`).
3. The active shell reads `pendingDestination` and pushes onto its tab's `HomeNavigationPath`.

### Voice Call Path

1. A Join button calls `CallCenter.startCall(...)` (`ClickMe2026/Managers/CallCenter.swift`) instead of presenting a sheet.
2. `CallCenter` holds the `MeetingCallViewModel` (`ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift`). The shells render a full overlay or, when minimized, a floating pill (`CallOverlayHost.swift`).
3. Joining uses `POST /bookings/:id/join` to obtain an Agora token, then `AgoraManager.joinChannel(using:)` (`ClickMe2026/Managers/AgoraManager.swift`).
4. Mode switch, logout, and payment-method screens check `CallCenter.attempt(...)` and block while a call is active.

### State Management

- Cross-screen state lives in singletons: `UserManager` (auth, profile, mode), `CallCenter` (call), `PushRouter` (push), `CategoryStore` (categories), `RealtimeService` (socket).
- Per-screen state lives in `@Published` properties of ViewModels, typically a `LoadState` (`ClickMe2026/Model/UIModels/LoadState.swift`) per section.
- Navigation state lives in `HomeNavigationPath` (`ClickMe2026/Views/Extensions/HomeNavigationPath.swift`), one per tab, owned by the shell with `@StateObject`.
- Persisted state: access and refresh tokens in Valet keychain (`UserManager.valet`, identifier `ClickMe`); `hasSeenOnboarding`, `currentMode`, and the cached profile in `UserDefaults`.

## Key Abstractions

**`UserManager`:**
- Purpose: Single source of session truth (who is logged in, which mode, which profile).
- Examples: `ClickMe2026/Managers/UserManager.swift`
- Pattern: `@MainActor @Observable` singleton. Read directly in views; `@Observable` tracks reads without a property wrapper.

**`ClickMeAPI` + feature extensions:**
- Purpose: Typed REST surface.
- Examples: `ClickMe2026/Network/ClickMeAPI.swift`, `ClickMe2026/Network/ClickMeAPI+Booking.swift`
- Pattern: `final class` singleton with `extension` per feature. Tests replace `NetworkService` through `init(baseURL:service:)`, with `ClickMe2026Tests/Support/MockURLProtocol.swift` as the stub.

**`LoadState`:**
- Purpose: Uniform loading/loaded/error state for async sections.
- Examples: `ClickMe2026/Model/UIModels/LoadState.swift`, used by `ExploreClientViewModel.categoriesState`.
- Pattern: `@Published var xState: LoadState` per section.

**`HomeNavigationPath` and `PushDestination`:**
- Purpose: Route pushes into the correct tab and mode.
- Examples: `ClickMe2026/Views/Extensions/HomeNavigationPath.swift`, `ClickMe2026/Managers/PushRouter.swift`
- Pattern: Typed `Hashable` route values appended to `NavigationPath`. Push events map to `PushDestination` cases such as `.bookingDetail(bookingId:)`.

**Preview seams:**
- Purpose: Render screens without network.
- Examples: `ExploreClientViewModel.init(...)` second initializer; `ClickMe2026/Views/Extensions/PreviewNavHarness.swift`; `ClickMe2026/Debug/PreviewSecrets.swift` (tracked and token-free; tokens come from the gitignored `PreviewSecrets.local.json`).
- Pattern: A ViewModel init that installs canned data as if a load succeeded.

## Entry Points

**`ClickMe2026App` (`@main`):**
- Location: `ClickMe2026/ClickMe2026App.swift`
- Triggers: iOS app launch.
- Responsibilities: Root `WindowGroup`, route state machine, keyboard toolbar, mode-to-route mirroring.

**`ClickMe2026AppDelegate`:**
- Location: `ClickMe2026/ClickMe2026AppDelegate.swift`
- Triggers: UIKit lifecycle, APNs, FCM token, notification taps and foreground arrivals.
- Responsibilities: Firebase and Stripe configuration, system chrome colors, push token forwarding, `refreshPushTokenBinding()` on every activation.

**`HomeClientView` / `HomeExpertView`:**
- Location: `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift`, `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift`
- Triggers: Route becomes `.clientHome` or `.expertHome`.
- Responsibilities: `TabView` shell (client: Explore, Search, Bookings, Chats, Profile; expert: Dashboard, Bookings, Topics, Chats, Profile), per-tab navigation paths, call overlay, push-driven tab selection.

**`SplashScreenView`:**
- Location: `ClickMe2026/Views/Screens/Splash/SplashView.swift`
- Triggers: App start.
- Responsibilities: Auto-login attempt and initial route decision.

**`LoginView`:**
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

**What happens:** 38 Swift files under `ClickMe2026/Views/` outside `*ViewModel.swift` reference `ClickMeAPI.shared` directly. Examples: `ClickMe2026/Views/Screens/Settings/Feedback/FeedbackView.swift`, `ClickMe2026/Views/Screens/Settings/Help/HelpView.swift`, `ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift`. Some of these are preview blocks that set `bearerToken` directly (for example `FeedbackView.swift` line 148).
**Why it's wrong:** Network logic in views is hard to test and bypasses the ViewModel loading and error-state conventions.
**Do this instead:** Put the call in the feature's `ViewModel`, injected with `api: ClickMeAPI = .shared` as in `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientViewModel.swift`.

### Mixed observation models

**What happens:** 59 of 64 ViewModels use `ObservableObject` with `@Published` and `@StateObject`/`@ObservedObject`, and most services (`CallCenter`, `PushRouter`, `CategoryStore`, `AgoraManager`) do too. `UserManager` and 5 ViewModels use `@Observable`, and views read `UserManager.shared` without a property wrapper.
**Why it's wrong:** Two observation systems in one screen force readers to remember which mechanism applies where, and they do not invalidate each other.
**Do this instead:** For new ViewModels, follow the nearest existing sibling (`ObservableObject`). For new shared app state, use `@Observable` like `UserManager`, and read it through a plain `let` reference.

### Models declared in View files

**What happens:** Value types used by a screen are declared in the view file, for example `ExpertCategory` and `Expert` in `ClickMe2026/Views/Screens/Client Mode/Explore/ExploreClientView.swift`.
**Why it's wrong:** The types are invisible to `Model/` and cannot be reused by other flows or decoded from the API without a separate mapping.
**Do this instead:** Put API-facing types in `Model/Responses/Children/`, and keep only presentation-only types in `Model/UIModels/`.

### Per-screen design token enums duplicating the global palette

**What happens:** 40 files under `ClickMe2026/Views/` define `enum <Screen>Brand` in `Subviews/<Screen>Brand.swift` (for example `ChattingBrand` in `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBrand.swift`) with raw hex colors, some of which repeat `Brand` values.
**Why it's wrong:** `Brand.swift` is documented as the single source of truth, but per-screen copies drift when the palette changes.
**Do this instead:** Reference `Brand.*` tokens. Add a new per-screen `*Brand` enum only for values that do not exist in `Brand`.

## Error Handling

**Strategy:** Typed errors from `NetworkService` (`NetworkError` in `ClickMe2026/Network/NetworkService.swift`) and backend `ErrorCode` (`ClickMe2026/Model/Enums/ErrorCode.swift`). ViewModels convert them to user-facing text via `ClickMe2026/Network/Error+UserMessage.swift`.

**Patterns:**
- 401 triggers one refresh-and-retry through `TokenRefresher`. If the refresh fails, `UserManager.isAuthRejection` drives logout.
- 403 `ACCOUNT_SUSPENDED` triggers `suspensionHandler`, which clears the session and sets `UserManager.wasSuspended`. The splash/login route shows the message.
- Validation errors decode through `FieldValidationErrorResponse.swift` and `FieldError.swift`, then render on `ValidatedField` components.
- Silent failures in push registration are logged only in `#if DEBUG` (`ClickMe2026AppDelegate`).

## Cross-Cutting Concerns

**Logging:** `print` statements inside `#if DEBUG` blocks, for example in `NetworkService.logRequest` / `logResponse` and `ClickMe2026AppDelegate`. No logging framework is present.
**Validation:** Client-side field validation in `ClickMe2026/Views/Components/ValidatedField.swift` and `ClickMe2026/Views/Screens/Signup Flow/Initial/Subviews/SignupValidatedField.swift`, with server-side field errors mapped from the backend.
**Authentication:** Bearer JWT plus rotating refresh token. Access and refresh tokens are stored in Valet (`UserManager`); `ClickMeAPI.bearerToken` forwards to `NetworkService`. Expired-token refresh is reactive (on 401), not proactive; `tokenExpiresAt` is stored for a future proactive path.
**Localization:** String catalog at `ClickMe2026/Localizable.xcstrings`.
**Dark theme:** The expert shell forces `.preferredColorScheme(.dark)`, and `ClickMe2026AppDelegate.configureSystemChrome()` pins nav and tab bar appearance to the `#131313` surface.

---

*Architecture analysis: 2026-11-07*
