---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
# External Integrations

**Analysis Date:** 2026-11-07

## APIs & External Services

**ClickMe Backend REST API (primary):**
- Base URL: `https://clickme-backend-production.up.railway.app/api/v1` (same for all environments in `ClickMe2026/Environments.plist`)
- Client: `ClickMe2026/Network/NetworkService.swift` (wraps `URLSession`), with domain extensions in `ClickMe2026/Network/ClickMeAPI.swift` and `ClickMe2026/Network/ClickMeAPI+*.swift`
- Endpoint paths are enumerated in `ClickMe2026/Network/APIRequestURLs.swift`
- Auth: `Authorization: Bearer <access token>` header set in `NetworkService.swift`; public endpoints (login, signup, refresh, password reset) omit it
- Contract source of truth lives in the backend repo (`../ClickMe2026 Backend`): `openapi/clickme-api.yaml`, `src/routes`, `src/controllers`, `src/schemas`

**Stripe (payments):**
- SDK: `stripe-ios-spm` 26.2.0, product `StripePaymentSheet` (`ClickMe2026/Configuration/StripeConfiguration.swift`)
- Client key: publishable key per environment in `ClickMe2026/Environments.plist` (`pk_test_` for Development/Staging, `pk_live_` for Production)
- Flow: backend issues PaymentIntent / SetupIntent and a customer ephemeral key (`ClickMe2026/Model/Responses/PaymentIntentResponse.swift`, `ClickMe2026/Network/ClickMeAPI+PaymentMethods.swift`); PaymentSheet tokenizes cards directly with Stripe, so raw card data never reaches ClickMe servers
- Endpoints touching payments: `/bookings/payment-intent`, `/me/payment-methods`, `/me/payment-methods/setup-intent`, `/me/payment-methods/:id/default`, `/client/transactions`
- Stripe Connect (expert payouts): `/expert/connect/onboard`, `/expert/connect/status`, `/expert/connect/refresh-link`. The Account Link URL is opened in `ASWebAuthenticationSession` (`ClickMe2026/Views/Screens/Expert Mode/Payouts/Subviews/ConnectOnboardingSession.swift`) and returns to the app via the `clickme://` scheme. The file comment states Stripe accepts only HTTPS `return_url`/`refresh_url`, so the callback bridging is expected to happen on the backend side (not verified in this repo)
- Auth: publishable key only in the client. Secret key stays on the backend
- Payout / earnings endpoints: `/expert/payouts/summary`, `/expert/earnings/weekly`, `/expert/earnings/transactions`

**Agora (in-app voice calls):**
- SDK: `AgoraRtcEngine_iOS` 4.6.2, product `RtcBasic`, module `AgoraRtcKit`
- Wrapper: `ClickMe2026/Managers/AgoraManager.swift` (`AgoraRtcEngineKit.sharedEngine(with:delegate:)`, `joinChannel(byToken:channelName:uid:)`)
- App ID: per environment in `ClickMe2026/Environments.plist` (`AgoraAppId`), read via `AppEnvironment.current.agoraAppId`
- Auth: a per-session channel token and channel name are minted by the backend on `POST /bookings/:id/join` (`ClickMe2026/Model/Responses/JoinCallResponse.swift`, `AgoraConfig`). The client never generates Agora tokens
- Call lifecycle endpoints: `/bookings/:id/join`, `/bookings/:id/confirm-connection`, `/bookings/:id/end`
- Call state is held app-wide in `ClickMe2026/Managers/CallCenter.swift`
- Alternate call type: `externalConfig` for Skype or Zoom meetings (`JoinCallResponse.swift`, `.skypeZoom`). The app opens the external meeting link and does not use the Agora SDK for that path

**Firebase Cloud Messaging (push notifications):**
- SDK: `firebase-ios-sdk` 12.17.0 (`FirebaseCore`, `FirebaseMessaging`, `FirebaseAnalytics`)
- Config: `ClickMe2026/GoogleService-Info.plist` (Firebase project identifiers; present, not reproduced here)
- Setup: `FirebaseApp.configure()` and `Messaging.messaging().apnsToken` in `ClickMe2026/ClickMe2026AppDelegate.swift`. APNs token is handed to FCM, and the FCM registration token is delivered via `MessagingDelegate`
- Token registration with backend: `POST /notifications/tokens` (`registerDeviceToken`), `DELETE /notifications/tokens/:device_id` (`unregisterDeviceToken`). Re-registration on launch is driven from `ClickMe2026/ClickMe2026AppDelegate.swift` and `ClickMe2026/Managers/UserManager.swift`
- Push payloads and routing: `ClickMe2026/Managers/PushRouter.swift`, `ClickMe2026/Model/Push/`
- APNs environment: `aps-environment = production` in `ClickMe2026/ClickMe2026.entitlements`

**Firebase Analytics:**
- Linked via the `FirebaseAnalytics` product and initialized through `FirebaseApp.configure()`. No custom Firebase Analytics event calls were located in the app sources. Separately, the app reads the backend's own analytics for expert dashboards (`/expert/analytics/summary`, `/expert/analytics/trends`, `/expert/analytics/popular-topics`, `ClickMe2026/Network/ClickMeAPI+Analytics.swift`). The privacy manifest declares no tracking (`NSPrivacyTracking = false`)

**Real-time (Socket.IO):**
- Client: `socket.io-client-swift` (product `SocketIO`), transport forced to WebSockets (`.forceWebsockets(true)`), with compression and infinite reconnects (2 s wait)
- Wrapper: `ClickMe2026/Realtime/RealtimeService.swift`; event names and payloads: `ClickMe2026/Realtime/RealtimeEvents.swift`
- Host: the Railway backend origin (base URL with `/api/v1` stripped)
- Auth: JWT access token passed in the Socket.IO `handshake.auth` payload via `socket.connect(withPayload: ["token": ...])`
- Contract: `docs/SOCKET-CONTRACT.md` in the backend repo (per `CLAUDE.md`)

**Media upload:**
- Backend endpoint `POST /media/upload` (`uploadMedia`) and avatar endpoints `/user/profile/avatar` (`uploadAvatar`, `deleteAvatar`), implemented through `NetworkService.multipartUpload`
- Storage provider is behind the backend; the client does not talk to a storage SDK directly

**Support, feedback and content:**
- Help center and FAQs: `/help/faqs`, `/help/faqs/search`, `/help/faqs/articles/:id`, all served by the backend (`ClickMe2026/Network/ClickMeAPI+Support.swift`)
- Support tickets: `/help/support/tickets`
- Feedback: `/feedback/types`, `/feedback/submit`
- Trust and safety: `/users/:id/report`

**Third-party hosted assets (images only, no SDK):**
- `https://randomuser.me/api/portraits/...` and `https://i.pravatar.cc/240` - placeholder avatars in SwiftUI previews and mock data
- `https://lh3.googleusercontent.com/aida-public/...` - static image URLs in preview and sample data
- `https://join.skype.com/...` and `https://zoom.us/j/...` - example external meeting URLs in sample data (the production path uses backend-provided links)

**Apple platform services:**
- Apple Push Notification service (APNs), via FCM
- `ASWebAuthenticationSession` - Stripe Connect onboarding flow
- Keychain, via Valet - see Authentication below
- Camera and microphone permissions (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`) for profile photos and voice calls
- Audio session and background audio (`UIBackgroundModes: audio`) for in-call audio

## Data Storage

**Databases:**
- No database client in the iOS app. All persistent data lives on the backend
- Backend database: Supabase (per `CLAUDE.md`; not verified in this repo)

**Local persistence:**
- Keychain via `Valet` (`ClickMe2026/Managers/UserManager.swift`): stores the rotating `refreshToken` under the key `refreshToken`. Access-token expiry (`expiresAt`) is stored separately
- `UserDefaults`: used for non-secret flags and cached state (declared in `ClickMe2026/PrivacyInfo.xcprivacy` with reason `CA92.1`)
- Firebase caches the FCM token across launches (`ClickMe2026/Managers/UserManager.swift`)

**File Storage:**
- Remote: via backend `/media/upload` and avatar endpoints
- Local: bundled assets in `ClickMe2026/Assets.xcassets/`; string catalog in `ClickMe2026/Localizable.xcstrings`

**Caching:**
- None detected beyond `URLSession` defaults and in-memory `CategoryStore` (`ClickMe2026/Managers/CategoryStore.swift`)

## Authentication & Identity

**Auth Provider:**
- Custom, backend-issued JWT auth. No third-party identity SDK (Auth0, Firebase Auth, Google Sign-In, Sign in with Apple) is linked
- Implementation:
  - Login and signup: `POST /auth/login`, `POST /auth/signup`. Response includes an access token, a rotating refresh token and `expiresAt`
  - Refresh: `POST /auth/refresh` via `ClickMeAPI+Auth.swift`. `NetworkService.swift` runs a refresh-then-retry-once interceptor on 401 responses, coordinated by `TokenRefresher` and `UserManager.refreshSession`
  - Email verification: `/auth/email/verify`, `/auth/email/status`, `/auth/email/resend`
  - Password: `/auth/password/forgot`, `/auth/password/reset`, `/user/password`
  - Account deletion: `/user/account/delete-request`
- Token storage: refresh token in Keychain (Valet); access token held in memory and sent as a Bearer header
- Suspension handling: a `403 ACCOUNT_SUSPENDED` response triggers `suspensionHandler`, which clears tokens and disconnects the socket (`NetworkService.swift`, `UserManager.swift`)
- Auth-related test fixtures: `ClickMe2026Tests/Fixtures/Auth/`

## Monitoring & Observability

**Error Tracking:**
- None detected (no Sentry, Crashlytics or Bugsnag SDK in `Package.resolved`)

**Logs:**
- Console logging via `print(...)` calls (about 20 in `ClickMe2026/Network/` and `ClickMe2026/Managers/`); no `os.Logger` or third-party logging framework is used. Socket.IO logging is enabled with `.log(true)` in `ClickMe2026/Realtime/RealtimeService.swift`. Agora log filter set to `info` in `ClickMe2026/Managers/AgoraManager.swift`
- Request logging in `NetworkService.swift` redacts `Authorization` header values

**Analytics:**
- Firebase Analytics (linked, see above)

## CI/CD & Deployment

**Hosting:**
- Backend: Railway (`clickme-backend-production.up.railway.app`)
- iOS distribution: App Store Connect / TestFlight

**CI Pipeline:**
- GitHub Actions
  - `.github/workflows/test.yml`: SwiftLint, `xcodebuild build-for-testing` and `test-without-building` on `macos-26`, test-result artifact upload via `actions/upload-artifact@v7`
  - `.github/workflows/build.yml`: archive and export with `ExportOptions.plist`, upload to TestFlight on `release/**` pushes or `workflow_dispatch`
- Code signing: `.github/actions/code-signing-setup/action.yml` (composite action; certificate material comes from GitHub secrets and is not stored in the repo)
- Swift package caching: `actions/cache@v5` keyed on `Package.resolved`
- Xcode package plugin validation is bypassed in CI via `defaults write` (`ci_scripts/ci_post_clone.sh`, `.github/workflows/*.yml`)

## Environment Configuration

**Required env vars / config keys:**
- `Environments.plist` keys per environment: `BaseURL`, `StripePublishableKey`, `AgoraAppId`
- `Current` key in `Environments.plist` selects the active environment
- `GoogleService-Info.plist` must match the Firebase project for push to work
- Smoke tests only: `CLICKME_TEST_EMAIL`, `CLICKME_TEST_PASSWORD`, optional `SIMULATOR`, `SCHEME`, `PROJECT`, `CONFIGURATION` (`scripts/run-smoke-tests.sh`)
- Stripe placeholder guard: the string `REPLACE_ME` in `StripePublishableKey` triggers an assertion at launch

**Secrets location:**
- No backend or server secrets are in this repo. Stripe secret keys, Agora certificates and Firebase server credentials live in the backend and Firebase/Agora consoles
- Refresh tokens live in the device Keychain via Valet
- CI signing material is provided by GitHub Actions secrets (referenced by `.github/actions/code-signing-setup/action.yml`)
- `.env` files: none detected

## Webhooks & Callbacks

**Incoming:**
- Push notifications: APNs/FCM delivered to the app; handled in `ClickMe2026/ClickMe2026AppDelegate.swift` (`UNUserNotificationCenterDelegate`) and routed by `ClickMe2026/Managers/PushRouter.swift`
- Deep links: custom URL scheme `clickme://` (`ClickMe2026/Info.plist`, `CFBundleURLTypes`). Used by Stripe Connect return flow in `ConnectOnboardingSession.swift`
- Socket.IO server events: `ClickMe2026/Realtime/RealtimeEvents.swift`

**Outgoing:**
- Device token registration: `POST /notifications/tokens`
- REST calls to the backend listed under APIs above. No outgoing webhooks are sent from the client
- Stripe Connect return/refresh redirects use HTTPS and are expected to bridge back to `clickme://` on the backend (see `ConnectOnboardingSession.swift`)

## Cross-Project Dependencies

- `ClickMe_Android` is a port of this app and uses the same REST and Socket.IO contract (per `CLAUDE.md`)
- Backend repo `../ClickMe2026 Backend` owns the API contract. Any change to `ClickMe2026/Network/` or `ClickMe2026/Model/` should be checked against its routes, controllers and schemas first

---

*Integration audit: 2026-11-07*
