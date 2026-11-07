---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
# Coding Conventions

**Analysis Date:** 2026-11-07

## Naming Patterns

**Files:**
- One primary type per file, named after the type: `ClickMe2026/Network/NetworkService.swift` holds `NetworkService`; `ClickMe2026/Theme/Brand.swift` holds `enum Brand`.
- Screen folders hold a view, its view model, and a `Subviews/` folder for child views. Example: `ClickMe2026/Views/Screens/Client Mode/Make a Booking/` contains `MakeABookingView.swift`, `MakeABookingViewModel.swift`, and `Subviews/`.
- View model files end in `ViewModel.swift` (for example `ClickMe2026/Views/Screens/Chat/Chatting/ChattingViewModel.swift`). Screen views end in `View.swift`. Some older or secondary screens use other suffixes, such as `ExpertProfileHomeScreen.swift` in `ClickMe2026/Views/Screens/Expert Mode/Profile/`.
- Network extensions are named `ClickMeAPI+<Feature>.swift`, for example `ClickMe2026/Network/ClickMeAPI+Booking.swift`.
- Request and response models live in `ClickMe2026/Model/Requests/` and `ClickMe2026/Model/Responses/`. Response types end in `Data` or `Response`, for example `LoginData.swift`, `PaymentIntentResponse.swift`, `SuccessDataResponse.swift`.
- Enums that mirror server values are in `ClickMe2026/Model/Enums/` (for example `BookingStatus.swift`, `ErrorCode.swift`, `UserRole.swift`).
- Folder names with spaces are used for screens (`Client Mode/`, `Login Flow/`, `Request decision/`). New folders under `Views/Screens/` should follow that existing pattern, because the directory names are shown to Xcode groups.

**Types:**
- `UpperCamelCase` for all types, including enums, structs, protocols, and classes.
- Feature-scoped types are prefixed with the screen name. Subviews of `MakeABookingView` are named `MakeABookingExpertCard`, `MakeABookingTopicPicker`, `MakeABookingCalendarCard`, and `MakeABookingBrand`. Keep that prefix for any new subview.
- Namespaces are caseless `enum`s with `static` members: `enum Brand` (`ClickMe2026/Theme/Brand.swift`), `enum Utils` (`ClickMe2026/Utils/Utils.swift`), `enum APIRequestURLs`.
- View structs do not always carry the `View` suffix. `struct MakeABooking: View` is declared in `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift`, while other screens use `...View`. Prefer the `...View` suffix for new screens.

**Functions and methods:**
- `lowerCamelCase` verb-first names: `initiateBooking(expertId:topicId:)`, `createPaymentIntent(...)`, `newBookingAttempt()` in `ClickMe2026/Network/ClickMeAPI+Booking.swift` and `MakeABookingViewModel.swift`.
- Network endpoint methods mirror the endpoint's purpose, not the HTTP verb. Use `login`, `signup`, `initiateBooking`, not `postLogin`.
- Argument labels are full words and use `id` suffixes: `expertId: UUID`, `bookingAttemptId: UUID`.

**Variables and properties:**
- `lowerCamelCase`. Identifiers are spelled `Id` (not `ID`) in names: `expertId`, `topicId`, `threadId`, `bookingId`. Keep this spelling for consistency with existing call sites.
- Published view state uses `@Published var` inside `ObservableObject` view models, and `private(set) var` inside observable managers (see `ClickMe2026/Managers/UserManager.swift`).
- Error text is exposed as `@Published var apiError: String?` in view models (used across most `*ViewModel.swift` files). `var errorMessage: String?` also appears in a few files. Prefer `apiError` for new view models.

**Enum cases:**
- Swift cases are `lowerCamelCase`. Server raw values are `snake_case` or `SCREAMING_SNAKE_CASE`, declared explicitly:
  ```swift
  // ClickMe2026/Model/Enums/BookingStatus.swift
  enum BookingStatus: String, Decodable {
      case pendingApproval    = "pending_approval"
      case confirmed
      case pendingReschedule  = "pending_reschedule"
  ```
- Error codes from the server are modeled as `enum ErrorCode: String, Decodable` in `ClickMe2026/Model/Enums/ErrorCode.swift`, with `SCREAMING_SNAKE_CASE` raw values.

**Constants:**
- Static constants use `static let` on a namespace type, such as `Brand.primary` and `APITestFactory.baseURL`.
- Brand colors and tokens are declared `nonisolated static let` so they can be read from any actor context (`ClickMe2026/Theme/Brand.swift`).

## Code Style

**Formatting:**
- Indentation: 4 spaces, LF line endings, final newline, trailing whitespace trimmed. Defined in `/Users/LeonChen/Documents/ClickMe2026/.editorconfig`.
- `max_line_length = 120` is set in `.editorconfig`. The line-length lint rule is disabled, so the limit is advisory. Long argument lists are broken one argument per line, with the closing parenthesis on its own line (see `ClickMe2026/Network/ClickMeAPI+Booking.swift`).
- Multi-line boolean or closure conditions put the opening brace on its own line when the condition spans lines:
  ```swift
  if let netError = self as? NetworkError,
     case let .httpError(_, data) = netError,
     let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
  {
  ```
  (`ClickMe2026/Network/Error+UserMessage.swift`, and `ClickMe2026/Network/NetworkService.swift`.)
- Single-line `guard let ... else { ... }` and `else`-on-same-line style is used for simple cases.
- Column alignment is used for enum raw values and short declarations, for example `case pendingApproval    = "pending_approval"`.

**Formatting tool:**
- SwiftFormat config at `/Users/LeonChen/Documents/ClickMe2026/.swiftformat`: `--indent 4`, `--disable unusedArguments`, `--disable redundantRawValues`. The `redundantRawValues` rule is disabled so explicit raw values stay in enums such as `BookingStatus`.
- No `swiftformat` run is wired into CI. Format manually to match surrounding code.

**Linting:**
- SwiftLint, configured in `/Users/LeonChen/Documents/ClickMe2026/.swiftlint.yml`. Disabled rules: `trailing_comma`, `line_length`, `unused_closure_parameter`.
- SwiftLint runs in CI as the first step of `.github/workflows/test.yml` through `cirruslabs/swiftlint-action@v1`. Lint failures block PRs to `main`.

## Import Organization

**Order:**
1. `Foundation` (and system frameworks such as `SwiftUI`, `UIKit`, `UserNotifications`, `Observation`).
2. Third-party SDKs, for example `import Valet`, `import FirebaseMessaging` (`ClickMe2026/Managers/UserManager.swift`).
3. Test-only: `import Testing`, `import XCTest`, and `@testable import ClickMe2026` in test targets.

Imports are not alphabetised. Keep the group order above, and keep `@testable import` on the line after the framework import in tests.

**Path Aliases:**
- Not used. Swift modules are referenced by name. There are no path aliases or Swift package aliases in the project.

## Error Handling

**Network layer (`ClickMe2026/Network/`):**
- Transport and HTTP failures are thrown as `NetworkError` (`ClickMe2026/Network/NetworkService.swift`): `invalidURL`, `invalidResponse`, `httpError(statusCode:data:)`, `decodingFailed(Error)`, `encodingFailed(Error)`, `invalidDate`.
- A non-2xx response throws `.httpError` with the raw body. Callers decode the body as `StandardErrorResponse` or `FieldValidationErrorResponse` (`ClickMe2026/Model/Responses/`).
- Endpoint methods are `async throws` and return a typed `SuccessDataResponse<T>` or a plain payload type. They do not swallow errors.
- A 401 on an authenticated request triggers the refresh interceptor (`authTokenRefresher`) once, then retries. A `403 ACCOUNT_SUSPENDED` triggers `suspensionHandler` and still rethrows.

**User-facing messages:**
- Convert any `Error` to a display string with the `Error.userMessage` extension in `ClickMe2026/Network/Error+UserMessage.swift`. It prefers the server `message` from `StandardErrorResponse`, then `LocalizedError.errorDescription`, then `localizedDescription`.
  ```swift
  } catch {
      apiError = error.userMessage
  }
  ```
- Do not write a new private `errorMessage(for:)` helper in a view model. Use `userMessage`.

**View models:**
- Async work is wrapped in `do { try await ... } catch { ... }`. The catch sets a `@Published` error string (`apiError`) that the view renders. Catch blocks are common (about 150 in the app target). Use them in any new network call.
- `try?` is used for best-effort reads where failure is acceptable (for example, optional decoding). Do not use `try?` for writes or for requests whose failure must be shown to the user.
- `try!` and `fatalError` do not appear in app code. `fatalError` is used only in test support (`ClickMe2026Tests/Support/Bundle+Fixtures.swift`).
- Force casts (`as!`) are not used in app code.
- Use `guard` for early exit on missing state rather than nested `if let`.

**Server error codes:**
- Branch on `ErrorCode` values (`ClickMe2026/Model/Enums/ErrorCode.swift`) when the UI needs different behavior per error, for example `BOOKING_ATTEMPT_CONFLICT`. Do not string-match on `message`.

## Logging

**Framework:** `print()`. The app does not use `os.Logger` or `NSLog` for new logging.

**Patterns:**
- Request and response logging is gated behind `#if DEBUG` in `ClickMe2026/Network/NetworkService.swift` (`logRequest`, `logResponse`). The `Authorization` header is redacted to `Bearer …` before printing.
- Push notification diagnostics use a `push:` prefix so they can be filtered in the Xcode console: `print("push: APNs registration FAILED = ...")` in `ClickMe2026/ClickMe2026AppDelegate.swift` and `ClickMe2026/Managers/UserManager.swift`.
- Do not log tokens, passwords, or full user payloads. The existing `print("push: TAP received. Full userInfo:")` in `ClickMe2026AppDelegate.swift` is development-only diagnostics; do not copy it into other flows.
- Wrap new debug-only logging in `#if DEBUG ... #endif`.

## Comments

**When to Comment:**
- Explain the why, the server contract, or a non-obvious race or retry rule. Examples: the attempt-id explanation in `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`, and the 422 and 409 behavior documented on `createPaymentIntent` in `ClickMe2026/Network/ClickMeAPI+Booking.swift`.
- Reference the backend doc when the behavior is part of the API contract, for example `docs/ios/USER-REPORTING.md` §4 (cited in `NetworkService.swift`). See the root `CLAUDE.md` for the cross-repo contract locations.
- Do not restate what the code does.

**Section markers:**
- `// MARK: - Section name` is the standard section divider. It is used about 1,370 times in the app target. Common sections: `// MARK: - Body`, `// MARK: Inits`, `// MARK: Loaded content`, `// MARK: Selections`, `// MARK: - POST /auth/signup`.

**File headers:**
- Every Swift file starts with the Xcode header block:
  ```swift
  //
  //  MakeABookingViewModel.swift
  //  ClickMe2026
  //
  //  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
  //
  ```
  Newer files use `Created by Leon Chen on YYYY-MM-DD.` plus the copyright line. Older files say `ClickMe` or `ClickMeAPI` instead of `ClickMe2026` on the second line (for example `ClickMe2026/Network/NetworkService.swift`). Use the current form for new files.

**JSDoc/TSDoc (Swift doc comments):**
- Use `///` doc comments on types and on public or internal methods. Use `- Parameter name:` for non-obvious parameters (see `ClickMe2026Tests/Support/APITestFactory.swift`).
- Put `- Parameters:` text in the doc comment instead of inline comments.

## Function Design

**Size:**
- Endpoint methods are one-liners that call `service.httpRequest` (for example `initiateBooking` in `ClickMe2026/Network/ClickMeAPI+Booking.swift`).
- View models are long. The largest are about 850 lines (`ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift`). Extract new logic into helpers or a sibling type rather than growing these files.
- Views are split into `Subviews/` files when a body grows past a few screens of layout.

**Parameters:**
- Prefer explicit labeled parameters and typed IDs (`UUID`), not raw `String` IDs. Use `String` only for external identifiers such as Stripe `pm_...` ids (see `url(_:stringId:)` in `ClickMe2026/Network/ClickMeAPI.swift`).
- Default values are used for optional query and body fields (`promoCode: String? = nil`).

**Return values:**
- Endpoint methods return a typed response, for example `SuccessDataResponse<InitiateBookingData>`, or throw.
- Void-returning async work is written as `async throws` with no return value. Do not return `Bool` success flags for network calls.

## Module Design

**Exports:**
- Single app module `ClickMe2026`. Types are `internal` by default. Use `private` for helpers within a file, and `private(set)` for state that only the owner can change (for example `UserManager.me`).
- Tests reach internal types with `@testable import ClickMe2026`.

**Network extensions:**
- `ClickMeAPI` is a `final class` declared in `ClickMe2026/Network/ClickMeAPI.swift`. Feature methods are added in extensions, one file per feature, all under `ClickMe2026/Network/`.
- Add a new endpoint by (1) adding a case to `APIRequestURLs` in `ClickMe2026/Network/APIRequestURLs.swift`, (2) adding the method to the matching `ClickMeAPI+<Feature>.swift` (or a new one), and (3) adding request and response types under `Model/Requests/` and `Model/Responses/`.

**State and concurrency:**
- View models and managers are `@MainActor`. `UserManager` is `@MainActor @Observable final class` (`ClickMe2026/Managers/UserManager.swift`). About 75 files use `@MainActor`.
- Use `async`/`await` for new async work (about 30 files). Use `Task { ... }` or `.task { ... }` in views to start work (about 180 `Task {` and 70 `.task` sites). Combine is effectively unused (`import Combine` appears in 3 files).
- Shared singletons use `static let shared`: `UserManager.shared`, `ClickMeAPI.shared`.

**Observation:**
- Two observation styles coexist:
  - `ObservableObject` with `@Published` and `@StateObject` is the majority style (about 64 files), for example `MakeABookingViewModel` in `ClickMe2026/Views/Screens/Client Mode/Make a Booking/`.
  - `@Observable` with the `Observation` import is used in newer code (about 10 files), for example `UserManager` and `ClickMe2026/Views/Screens/Splash/SplashViewModel.swift`.
- When editing a feature, match the style used by its neighboring view model. For new shared managers, use `@Observable`.

**Barrel files:**
- Not used. Each file imports what it needs.

## Other Patterns

**Views:**
- View models are injected through an initializer. Runtime init builds the view model from feature parameters, and a second `init(viewModel:)` is kept as a preview or test seam:
  ```swift
  // ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingView.swift
  init(viewModel: MakeABookingViewModel) {
      _viewModel = StateObject(wrappedValue: viewModel)
  }
  ```
- Shell-level values are passed through the SwiftUI `Environment` using custom keys (for example `@Environment(\.showMyBookings)` and `@Environment(\.returnToHome)`).
- Use `@ViewBuilder` for conditional composition (about 90 uses). Prefer small computed `some View` properties for sections inside a screen.
- Use `#Preview` blocks, named when showing several states: `#Preview("Client Active")` and `#Preview("Expert Active")` in `ClickMe2026/Views/Screens/Settings/Mode Switching/ModeSwitchView.swift`. About 190 preview blocks exist. Preview harness code must compile in Release too, so do not wrap `#Preview` bodies in `#if DEBUG`.
- Button styles are in `ClickMe2026/Views/Components/ButtonStyles/` (for example `PressScaleButtonStyle.swift`). Reusable async buttons are in `ClickMe2026/Views/Components/Buttons/AsyncSaveButton.swift`.

**Codable and JSON:**
- Models conform to `Decodable` (or `Codable`) with explicit `CodingKeys` when server keys are `snake_case`:
  ```swift
  // ClickMe2026/Model/Requests/ReportUserRequest.swift
  enum CodingKeys: String, CodingKey { ... }
  ```
- Dynamic JSON is modeled with `JSONValue` (`ClickMe2026/Model/Enums/JSONValue.swift`).

**Dates:**
- Date parsing and formatting is centralized in `ClickMe2026/Utils/DateUtil.swift` and `ClickMe2026/Network/NetworkService.swift`. Use these instead of creating new `DateFormatter` instances.
- Relative times use `Utils.timeAgo(since:)` (`ClickMe2026/Utils/Utils.swift`).

**Secrets:**
- Never commit secrets. `ClickMe2026/Debug/PreviewSecrets.swift` is git-ignored and must stay out of source control. Test credentials come from environment variables or UserDefaults (see `ClickMe2026Tests/Support/SmokeConfig.swift`).

---

*Convention analysis: 2026-11-07*
