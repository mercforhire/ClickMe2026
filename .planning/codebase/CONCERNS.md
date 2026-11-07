---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
# Codebase Concerns

**Analysis Date:** 2026-11-07

## Tech Debt

**Environment configuration collapses Development and Staging onto production:**
- Issue: `Environments.plist` sets the `BaseURL` to the same production backend host for Development, Staging, and Production. The `Current` key is committed as `Production`. Non-production builds therefore hit live data and live payment/auth flows.
- Files: `ClickMe2026/Environments.plist`, `ClickMe2026/Configuration/AppEnvironment.swift`
- Impact: Test bookings, test accounts, and debug actions can mutate production data. Staging cannot be used as a pre-release gate.
- Fix approach: Point Development and Staging `BaseURL` at their own backend hosts, and add a build-time guard (xcconfig or scheme-level selection) so Release builds cannot be produced with a non-production `Current`.

**Duplicated "forceLoad" view-model pattern:**
- Issue: Nearly every screen view model re-implements the same refresh/load scaffolding (`refresh()` -> `forceLoad()`, loading and error flags, `Task` wrapping) with small variations.
- Files: `ClickMe2026/Views/Screens/Settings/Help/HelpViewModel.swift`, `ClickMe2026/Views/Screens/Settings/Feedback/FeedbackViewModel.swift`, `ClickMe2026/Views/Screens/Settings/Notifications/NotificationSettingsViewModel.swift`, `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryViewModel.swift`, `ClickMe2026/Views/Screens/Expert Mode/Payouts/PayoutsViewModel.swift`, `ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsViewModel.swift`, `ClickMe2026/Views/Screens/Expert Mode/Incoming Requests/IncomingRequestsViewModel.swift`
- Impact: Behavioral drift between screens (some retry, some silently swallow errors, some debounce). Each bug fix must be repeated per screen.
- Fix approach: Extract a shared load-state helper (for example a generic `AsyncLoadable` or `RemoteResourceViewModel<Value>`) and migrate new screens to it before adding more copies.

**Oversized view models and views:**
- Issue: Several files carry too many responsibilities and state fields.
- Files: `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` (858 lines, 24 `@Published` properties), `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift` (807 lines), `ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift` (774 lines), `ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift` (706 lines), `ClickMe2026/Managers/UserManager.swift` (664 lines)
- Impact: High cost to change safely; state transitions (booking confirm, 3DS, reschedule) are hard to reason about.
- Fix approach: Split by flow step (for booking: availability, payment, SCA challenge, confirmation) into coordinators or sub-view-models, each with its own tests.

**Global singletons hold most app state:**
- Issue: Shared mutable singletons are used for core services and are reached directly from views and other managers.
- Files: `ClickMe2026/Network/ClickMeAPI.swift` (`ClickMeAPI.shared`, holds `bearerToken`), `ClickMe2026/Managers/UserManager.swift` (`@MainActor static let shared`), `ClickMe2026/Realtime/RealtimeService.swift` (`RealtimeService.shared`), `ClickMe2026/Managers/CallCenter.swift`, `ClickMe2026/Managers/PushRouter.swift`, `ClickMe2026/Managers/CategoryStore.swift`
- Impact: Tests must mutate shared globals, and preview code writes the bearer token directly into `ClickMeAPI.shared`. Ordering of logout/login side effects is implicit.
- Fix approach: Inject dependencies through initializers at the view-model boundary; keep singletons as composition roots only.

**Realtime handler teardown is fire-and-forget:**
- Issue: Subscription cancellation removes handlers via `Task { @MainActor in RealtimeService.shared.<...>Handlers.removeValue(forKey: id) }`. Removal is asynchronous, so an event can still be delivered to a handler after its owner has been released.
- Files: `ClickMe2026/Realtime/RealtimeService.swift` (lines ~127-283)
- Impact: Stale callbacks can update view models that have already been dismissed. Hard to reproduce, and it can surface as state updates on the wrong thread or after logout.
- Fix approach: Make the handler registry synchronous (serialize on the main actor and remove inline in the cancel path), or make handlers hold weak owners and check liveness before delivery.

**Silent error swallowing in several flows:**
- Issue: Some failures are dropped with empty `catch` blocks or `try?`.
- Files: `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift` (~line 420, silent catch on thread creation with a TODO to surface errors), `ClickMe2026/Managers/UserManager.swift` (`try? valet.setString(...)` in `persist(refreshToken:expiresAt:)`, `clearRefreshCredentials()`)
- Impact: A failed Keychain write means the refresh token is silently not stored, and the user is logged out on the next cold start with no explanation. A failed thread creation leaves the user with no feedback.
- Fix approach: Log Keychain write failures and surface a retriable error for user-initiated actions. Do not discard `Valet` results on the auth path.

## Known Bugs and Incomplete Features

**3DS / SCA retry is incomplete:**
- Symptoms: When `/bookings/confirm` returns `PAYMENT_REQUIRES_ACTION`, the 3DS sheet can only hard-fail if the backend does not return `stripe_account`.
- Files: `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` (`SCAChallenge`, `pendingSCAChallenge`, around line 184)
- Trigger: Any card that requires authentication on a connected-account PaymentIntent.
- Workaround: None in the client. The `stripeAccount` field must be added on the backend (see the TODO at line 184).

**"View Profile" action is a no-op:**
- Symptoms: Tapping the client name's "View Profile" label does nothing.
- Files: `ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionViewModel.swift` (`viewProfileTapped()`, around line 234)
- Trigger: Open an incoming request in Expert Mode and tap "View Profile".
- Workaround: None. Needs a public client profile route.

**Expert profile favorite toggle drops thread-creation errors:**
- Symptoms: If creating a message thread fails, nothing is shown and the user does not know it failed.
- Files: `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift` (around line 420)
- Trigger: Network failure or server error when starting a chat from the profile.
- Workaround: User can retry from the Chats tab.

## Security Considerations

**Socket.IO client logs unconditionally in all build configurations:**
- Risk: `SocketManager` is created with `.log(true)` outside any `#if DEBUG` guard. Socket.IO logs frame and event payloads, which can include message content and identifiers, to the console in Release builds. Device logs can be collected from production devices.
- Files: `ClickMe2026/Realtime/RealtimeService.swift` (`connect(token:)`, around lines 86-95)
- Current mitigation: Network request logging in `ClickMe2026/Network/NetworkService.swift` is wrapped in `#if DEBUG`, and the `Authorization` header is redacted there.
- Recommendations: Wrap `.log(true)` in `#if DEBUG`, or set it to `false` for Release.

**Push-notification identifiers printed outside DEBUG guards:**
- Risk: `ClickMe2026/Managers/UserManager.swift` prints the device ID and a 24-character prefix of the push token in calls such as `print("push: POST /notifications/tokens { device_id: ..., token: ... })"` (around line 563) and in the FCM token fetch path (around lines 622-643). Only some of these calls appear to sit inside `#if DEBUG` blocks, and the coverage should be verified.
- Files: `ClickMe2026/Managers/UserManager.swift`, `ClickMe2026/ClickMe2026AppDelegate.swift` (APNs and FCM prints are guarded, but keep it that way)
- Current mitigation: AppDelegate prints are inside `#if DEBUG`. The token is truncated.
- Recommendations: Wrap every push log in `#if DEBUG`, or route them through `os.Logger` with `privacy: .private`.

**Bearer token and refresh token handling:**
- Risk: The access token lives in `NetworkService.bearerToken` (plain memory) and the refresh token lives in Keychain via Valet (`ClickMe2026/Managers/UserManager.swift`, `valet` created around line 53). The refresh token rotates on every `/auth/refresh`, so a double-refresh race that reuses an old value revokes the session.
- Files: `ClickMe2026/Network/NetworkService.swift` (401 interceptor in `send(_:)`), `ClickMe2026/Managers/UserManager.swift` (`performRefreshCycle()`), `ClickMe2026/Model/Responses/LoginData.swift`
- Current mitigation: Refresh is retried once per request and the 403 `ACCOUNT_SUSPENDED` path clears auth before rethrowing.
- Recommendations: Confirm that `TokenRefresher.refresh()` is single-flight (concurrent 401s share one in-progress refresh). Add a test that fires several 401s concurrently and asserts exactly one `/auth/refresh` call.

**CI disables Xcode package-plugin and macro fingerprint validation:**
- Risk: The TestFlight workflow runs `defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES` and the matching macro setting. This turns off a supply-chain check on third-party plugins and macros during release builds.
- Files: `.github/workflows/build.yml`
- Current mitigation: Packages are resolved from the pinned lockfile in the project, if one is committed.
- Recommendations: Scope the override to a specific, reviewed package, or remove it once the plugins are accepted in Xcode.

**Preview and smoke-test secrets in the working tree:**
- Risk: `ClickMe2026/Debug/PreviewSecrets.swift` is gitignored and holds a client bearer token used by several screen previews (for example `ClickMe2026/Views/Screens/Settings/Feedback/FeedbackView.swift`, `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift`). A token that leaks into a preview build or a shared screenshot grants account access.
- Files: `ClickMe2026/Debug/PreviewSecrets.swift` (gitignored, not reproduced here), `.gitignore`
- Current mitigation: File is gitignored.
- Recommendations: Confirm every reference to `PreviewSecrets` is inside a `#Preview` or `#if DEBUG` block so that a clean checkout still compiles for Release. Rotate any token that was ever shared outside a developer machine.

## Performance Bottlenecks

**Shared `DateFormatter` mutated during decoding:**
- Problem: The custom date decoding strategy in `NetworkService` mutates one shared `DateFormatter` (`formatter.dateFormat = ...`) inside a closure that runs for every decoded timestamp. `DateFormatter` is not thread-safe, and concurrent requests decode on different tasks.
- Files: `ClickMe2026/Network/NetworkService.swift` (`init`, date decoding strategy around lines 84-103)
- Cause: One formatter instance is reused across concurrent decodes, and its format string is changed on each call.
- Improvement path: Create formatters per call, or keep two immutable formatters (one with fractional seconds, one without) and select between them without mutating either.

**Heavy view bodies on dashboards:**
- Problem: Large SwiftUI `body` computations in the dashboard and booking views are rebuilt on every `@Published` change of the parent view model.
- Files: `ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift`, `ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift`
- Cause: Monolithic view bodies and broad `@Published` state.
- Improvement path: Split into subviews that take only the values they render, and scope `@Published` properties per section.

## Fragile Areas

**Socket base-URL derivation:**
- Files: `ClickMe2026/Realtime/RealtimeService.swift` (`connect(token:)`, lines ~77-80)
- Why fragile: The socket URL is derived by calling `deletingLastPathComponent()` twice on `AppEnvironment.current.baseURL` (`.../api/v1`). Changing the REST path shape, or adding a trailing slash, silently breaks the socket with no error (the function `return`s on a nil URL).
- Safe modification: Store the realtime origin explicitly in `Environments.plist` (a `RealtimeURL` key), and log an error when it cannot be resolved.
- Test coverage: None found.

**Environment loading uses `preconditionFailure`:**
- Files: `ClickMe2026/Configuration/AppEnvironment.swift`
- Why fragile: If `Environments.plist` is missing a key or the `Current` value does not match a dictionary entry, the app crashes at first access with no user-visible message.
- Safe modification: Validate the plist in a unit test that loads every environment, so the crash is caught in CI before release.
- Test coverage: None found.

**Date parsing fallback chain:**
- Files: `ClickMe2026/Network/NetworkService.swift` (custom decoder, lines ~84-103)
- Why fragile: The decoder tries a millisecond format, then a no-fraction format, then throws `NetworkError.invalidDate`. Backend changes to timestamp shape (for example, nanosecond precision or a different offset format) fail the whole response decode rather than one field.
- Safe modification: Add decoder tests for each timestamp shape the backend emits. Contract source: `openapi/clickme-api.yaml` in the backend repo.
- Test coverage: Not covered by the existing tests.

**Lint and format rules are relaxed:**
- Files: `.swiftlint.yml` (disables `trailing_comma`, `line_length`, `unused_closure_parameter`), `.editorconfig` (declares `max_line_length = 120`, which SwiftLint does not enforce)
- Why fragile: Long lines and closure-parameter drift are not caught in review or CI.
- Safe modification: Re-enable `line_length` with a warning-level threshold and run SwiftLint in `.github/workflows/test.yml`.

## Scaling Limits

**Single-user session model:**
- Current capacity: One active session per device. `RealtimeService` keeps one `SocketManager` and one `connectedToken`.
- Limit: Switching between Client and Expert modes on one device shares one socket and one token, and `connect(token:)` tears down the socket before re-establishing it.
- Scaling path: Keep one socket per signed-in identity, and key subscriptions by identity so a mode switch does not drop in-flight events.

## Dependencies at Risk

**Socket.IO client and Valet:**
- Risk: `socket.io-client-swift` (via `SocketIO` imports in `ClickMe2026/Realtime/RealtimeService.swift`) and `Valet` (`ClickMe2026/Managers/UserManager.swift`) are third-party libraries on the auth and realtime paths. Upstream maintenance cadence has not been verified in this analysis.
- Impact: A breaking change or abandonment blocks login refresh and realtime messaging together.
- Migration plan: Keep the wrappers thin (`RealtimeService`, `UserManager` Keychain calls) so the underlying library can be swapped. Track versions through Dependabot (`.github/dependabot.yml`).

## Missing Critical Features

**Public client profile route:**
- Problem: The expert's view of a client has no profile screen, so the "View Profile" action is a no-op.
- Blocks: Expert-side trust review before accepting a booking (see `ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionViewModel.swift`).

## Test Coverage Gaps

**Almost no automated tests for view models and services:**
- What's not tested: The codebase has about 618 Swift files. Tests exist only for auth (`ClickMe2026Tests/Network/Auth/LoginTests.swift`, `ClickMe2026Tests/Network/Auth/ResetPasswordTests.swift`) and two smoke suites (`ClickMe2026Tests/Integration/AuthSmokeTests.swift`, `ClickMe2026Tests/Integration/SignupSmokeTests.swift`), totalling about 577 lines. There are no tests for booking, payment, SCA, realtime, refresh-token cycling, or the date decoder. The UI test target (`ClickMe2026UITests/`) contains only a template example.
- Files: `ClickMe2026Tests/`, `ClickMe2026UITests/ExampleUITests.swift`, `ClickMe2026Tests/Support/MockURLProtocol.swift`
- Risk: Changes to the booking flow, token refresh, and realtime event handling ship without regression coverage.
- Priority: High

**Smoke tests depend on a live backend:**
- What's not tested: `ClickMe2026Tests/Integration/*` run against a real server when configured through `ClickMe2026Tests/Support/SmokeConfig.swift` and `scripts/run-smoke-tests.sh`. Their results depend on backend state.
- Files: `ClickMe2026Tests/Integration/AuthSmokeTests.swift`, `ClickMe2026Tests/Integration/SignupSmokeTests.swift`, `scripts/run-smoke-tests.sh`
- Risk: Flaky or environment-dependent results, and possible writes to whichever backend `SmokeConfig` targets (which, given the Environments issue above, may be production).
- Priority: Medium

**Date decoding and environment loading are untested:**
- What's not tested: The custom date decoding strategy in `ClickMe2026/Network/NetworkService.swift`, and the environment loader in `ClickMe2026/Configuration/AppEnvironment.swift`.
- Files: `ClickMe2026/Network/NetworkService.swift`, `ClickMe2026/Configuration/AppEnvironment.swift`
- Risk: A silent decode failure or a crash at launch after a config edit.
- Priority: High

---

*Concerns audit: 2026-11-07*
