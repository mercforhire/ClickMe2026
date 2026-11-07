---
last_mapped_commit: 13b3d3a612555ff44170832840ef11684e30a510
last_mapped_at: 2026-11-07
---
# Testing Patterns

**Analysis Date:** 2026-11-07

## Test Framework

**Runner:**
- Unit and integration tests: Swift Testing (`import Testing`), target `ClickMe2026Tests`. Config: `ClickMe2026/AllTests.xctestplan` (test plan) and the Xcode scheme `ClickMe2026`.
- UI tests: XCTest (`import XCTest`) with the `Salad` page-object helper library (`import Salad`), target `ClickMe2026UITests`.
- Test plan: `/Users/LeonChen/Documents/ClickMe2026/ClickMe2026/AllTests.xctestplan`. It includes both test targets. The `English` configuration (`en` / `GB`) is enabled. The `Dutch` configuration (`nl` / `NL`) is defined but disabled. `testTimeoutsEnabled` is on.
- Swift Testing is the default for new unit tests. Existing XCTest code is limited to the UI target.

**Assertion Library:**
- Swift Testing macros: `#expect(...)`, `#require(...)`, `#expect(throws:)`, and `Issue.record(...)` for explicit failures.
- XCTest assertions are used only in `ClickMe2026UITests/`.

**Run Commands:**

```bash

# Run the whole test plan (what CI runs on PRs to main)

xcodebuild test -project ClickMe2026.xcodeproj -scheme ClickMe2026 \
  -testPlan AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run only the unit test target

xcodebuild test -project ClickMe2026.xcodeproj -scheme ClickMe2026 \
  -only-testing:ClickMe2026Tests

# Run only the integration smoke suite against the real backend (needs credentials)

CLICKME_TEST_EMAIL=you@example.com CLICKME_TEST_PASSWORD=... \
  /Users/LeonChen/Documents/ClickMe2026/scripts/run-smoke-tests.sh

# Watch mode: Not detected (use Xcode's Test navigator or Cmd+U)

# Coverage: Not configured in the scheme or test plan (no codeCoverage settings detected)

```

**CI:**
- `.github/workflows/test.yml` runs on pull requests that target `main` and on manual dispatch. It runs SwiftLint first, then `xcodebuild test` against the `AllTests` plan on an iOS Simulator (`iPhone 16`, Xcode 26, `macos-26` runner).
- `TEST_DEVICE_TYPE` in the workflow is `iPhone 16`, while `scripts/run-smoke-tests.sh` defaults to `iPhone 17`. Keep these in sync when changing the simulator.

## Test File Organization

**Location:**
- Tests live in a separate target folder, not next to the source. Unit tests are under `ClickMe2026Tests/`, mirroring the API layout:
  - `ClickMe2026Tests/Network/Auth/` for endpoint tests of `ClickMeAPI+Auth`.
  - `ClickMe2026Tests/Integration/` for smoke suites that hit the real backend.
  - `ClickMe2026Tests/Support/` for shared helpers.
  - `ClickMe2026Tests/Fixtures/` for JSON fixtures.
- UI tests: `ClickMe2026UITests/Behaviours/` (actions) and `ClickMe2026UITests/ViewObjects/` (screen wrappers).

**Naming:**
- Test files end in `Tests.swift` (`LoginTests.swift`, `ResetPasswordTests.swift`) for unit tests and `SmokeTests.swift` for integration tests (`AuthSmokeTests.swift`, `SignupSmokeTests.swift`).
- Helper files are named after the type they extend or provide: `APITestFactory.swift`, `MockURLProtocol.swift`, `Bundle+Fixtures.swift`, `SmokeConfig.swift`.
- Test struct names match the subject: `struct LoginTests`, `struct ResetPasswordTests`.

**Structure:**

```
ClickMe2026Tests/
├── ExampleTests.swift              # Xcode template placeholder
├── Integration/
│   ├── AuthSmokeTests.swift        # real backend, gated by SmokeConfig
│   └── SignupSmokeTests.swift      # real backend, gated by SmokeConfig
├── Network/
│   └── Auth/
│       ├── LoginTests.swift        # reference pattern for endpoint tests
│       └── ResetPasswordTests.swift
├── Support/
│   ├── APITestFactory.swift
│   ├── Bundle+Fixtures.swift
│   ├── MockURLProtocol.swift
│   └── SmokeConfig.swift
└── Fixtures/
    └── Auth/*.json                 # login_success, login_401, login_422, reset_password_*
```

## Test Structure

**Suite Organization:**
Each test file declares a `@Suite` with a descriptive name in the form `"<Subject> · <area>"`, with `.serialized` when the suite shares the global mock state. The suite struct is `@MainActor` because the API client is main-actor isolated. From `ClickMe2026Tests/Network/Auth/LoginTests.swift`:

```swift
@Suite("ClickMeAPI+Auth · login", .serialized)
@MainActor
struct LoginTests {

    // MARK: - Request shape

    @Test("sends POST to /auth/login with JSON body containing email and password")
    func sendsCorrectRequest() async throws {
        let api = APITestFactory.make { request in
            // return (HTTPURLResponse, Data)
        }

        _ = try await api.login(email: email, password: password)

        #expect(MockURLProtocol.recordedRequests.count == 1)
        let sent = try #require(MockURLProtocol.recordedRequests.first)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "\(APITestFactory.baseURL)/auth/login")
    }

    // MARK: - Success
    // MARK: - Error mapping
    // MARK: - Decoding
}
```

**Patterns:**
- Group tests with `// MARK: - <Area>` comments: request shape, success, error mapping, decoding failure.
- Test names are full sentences in the `@Test("...")` string, not function-name identifiers. Example: `@Test("maps 401 to NetworkError.httpError with decodable StandardErrorResponse")`. Keep the `func` name short and descriptive (`maps401ToHTTPError`).
- Use `#require` to unwrap optionals before using them, so the test stops with a clear failure (`let sent = try #require(MockURLProtocol.recordedRequests.first)`).
- Use `await #expect(throws: NetworkError.self) { ... }` to assert that a call throws a specific error type.
- When the specific error case or payload matters, use a `do { } catch let NetworkError.httpError(statusCode, data) { ... }` block with `Issue.record` in the `catch` fallthrough. This is the pattern in `LoginTests.maps401ToHTTPError`.
- Tags: integration suites carry `.tags(.integration)`, defined in `ClickMe2026Tests/Support/SmokeConfig.swift` as `extension Tag { @Tag static var integration: Tag }`. Use tags to include or exclude them.
- Setup pattern: build the system under test inside each test with a factory. Do not share a `setUp()` (Swift Testing has no `setUp`).
- Teardown pattern: none needed. `APITestFactory.make` resets `MockURLProtocol` at the start of each test.

**Assertion pattern:**

```swift
#expect(response.status == "success")
#expect(response.data.user.role == .expert)
#expect(decoded.errors.first?.field == "password")
```

## Mocking

**Framework:** No third-party mocking library. HTTP is stubbed with a custom `URLProtocol` subclass, `MockURLProtocol`, in `ClickMe2026Tests/Support/MockURLProtocol.swift`.

**How it works:**
- `MockURLProtocol.handler` is a static closure set per test. It receives the `URLRequest` and returns `(HTTPURLResponse, Data)` or throws a transport error.
- `MockURLProtocol.recordedRequests` captures every request that flows through the mock, so tests can assert method, URL, and body.
- `MockURLProtocol.reset()` clears both. `APITestFactory.make` calls it, so every test starts clean.
- The static state is marked `nonisolated(unsafe)`. For this reason, suites that touch it are declared `.serialized`.

**Patterns:**

```swift
// ClickMe2026Tests/Support/APITestFactory.swift
let api = APITestFactory.make { request in
    let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
    )!
    let data = Bundle.tests.jsonData(named: "login_success", subdirectory: "Auth")
    return (response, data)
}
```

Shorthand for a canned status and fixture:

```swift
let api = APITestFactory.make(status: 401, fixture: "login_401")
```

Network errors (transport failure) are simulated by throwing from the handler, which `MockURLProtocol.startLoading` forwards as `didFailWithError`.

**Base URL:** `APITestFactory.baseURL` is `https://test.clickme.local/api/v1`. Assert paths against `"\(APITestFactory.baseURL)/<endpoint>"`.

**Request body assertions:**
- Read the body with `sent.httpBodyOrStreamData()`, then decode with `JSONSerialization` and compare fields. This `URLRequest` extension is duplicated as a `private` helper in both `ClickMe2026Tests/Network/Auth/LoginTests.swift` and `ClickMe2026Tests/Network/Auth/ResetPasswordTests.swift`. Move it into `ClickMe2026Tests/Support/` before adding a third copy.

**What to Mock:**
- All HTTP traffic in unit tests. Route it through `APITestFactory.make`.
- Server responses by fixture (JSON files in `ClickMe2026Tests/Fixtures/`), not by inline strings, when the payload is more than a couple of fields.

**What NOT to Mock:**
- `NetworkService`'s JSON decoding and error mapping. These are the behavior under test. Let the real `ClickMeAPI` and `NetworkService` run against the stubbed session.
- Integration suites should not be mocked. They hit the real backend on purpose. See "Integration Tests" below.

## Fixtures and Factories

**Test Data:**
- JSON fixtures are checked into `ClickMe2026Tests/Fixtures/<Area>/<name>.json`. Current set (all under `Auth/`):
  - `login_success.json`, `login_401.json`, `login_422.json`
  - `reset_password_success.json`, `reset_password_400.json`, `reset_password_422.json`
- Name fixtures as `<endpoint>_<status-or-case>.json`. Keep fixtures in the real server shape, copied from the backend contract (`openapi/clickme-api.yaml` in the backend repo, per the root `CLAUDE.md`).
- Fixtures must contain no real credentials or tokens. Use obviously fake values (for example `ada@example.com`).

**Loading fixtures:**

```swift
// ClickMe2026Tests/Support/Bundle+Fixtures.swift
let data = Bundle.tests.jsonData(named: "login_success", subdirectory: "Auth")
```

`Bundle.tests` resolves the test bundle through a private anchor class. Always use `Bundle.tests`, not `Bundle.main`. `jsonData` calls `fatalError` if the fixture is missing, so a typo fails loudly.

**Inline data:**
- For a one-off malformed payload, use inline JSON: `Data(#"{"status":"success"}"#.utf8)`. This is the pattern in `LoginTests.decodingFailure`.

**Factories:**
- `APITestFactory` (`ClickMe2026Tests/Support/APITestFactory.swift`) builds a `ClickMeAPI` wired to an ephemeral `URLSession` with `MockURLProtocol` installed, and a `NetworkService` with an optional bearer token.
- No model factories exist yet. Build request and response values inline.

**Location:**
- Helpers: `ClickMe2026Tests/Support/`.
- Fixtures: `ClickMe2026Tests/Fixtures/` (added to the test bundle as resources).

## Coverage

**Requirements:** None enforced. No coverage threshold is set in the scheme, test plan, or CI workflow.

**View Coverage:**

```bash

# Enable code coverage in Xcode: Product > Scheme > Edit Scheme > Test > Options > Code Coverage

# Or from the CLI, add: -enableCodeCoverage YES

xcodebuild test -project ClickMe2026.xcodeproj -scheme ClickMe2026 -enableCodeCoverage YES \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Current scope of automated tests:**
- Covered: `ClickMeAPI+Auth` endpoints (login, reset password), plus integration smoke flows for auth and expert signup.
- Not covered by unit tests: all `ViewModel` types, `UserManager`, `NetworkService` retry and refresh logic, `ClickMeAPI` feature extensions other than auth, and all SwiftUI views. `ClickMe2026Tests/ExampleTests.swift` is the Xcode template placeholder and tests nothing in the app.

## Test Types

**Unit Tests:**
- Scope: one `ClickMeAPI` endpoint method per test, verifying request shape (method, URL, body), decoding of a success fixture, and error mapping for 4xx responses.
- Run without network access. Use `APITestFactory.make` only.
- Place in `ClickMe2026Tests/Network/<Area>/`.

**Integration Tests (smoke):**
- Scope: a real backend round trip, one endpoint at a time, in the same order the SwiftUI flow calls them. Examples: `ClickMe2026Tests/Integration/SignupSmokeTests.swift` (signup, email status, resend, meta lookups, profile setup) and `ClickMe2026Tests/Integration/AuthSmokeTests.swift`.
- Gating: every integration suite uses `.enabled(if: SmokeConfig.isEnabled, "...")`. Without `CLICKME_TEST_EMAIL`, the suite is skipped and the default run stays green.
- Credentials are read by `SmokeConfig` (`ClickMe2026Tests/Support/SmokeConfig.swift`) from, in order:
  1. Environment variables `CLICKME_TEST_EMAIL` and `CLICKME_TEST_PASSWORD` (set in the Xcode scheme, or by `scripts/run-smoke-tests.sh`, which forwards them with the `SIMCTL_CHILD_` prefix).
  2. `UserDefaults.standard` under the same keys (launch arguments such as `-CLICKME_TEST_EMAIL you@example.com`).
- Signup smoke tests create a new account per run, with a timestamped `verify.smoke.*@clickme.test` address. There is no cleanup step. Do not reuse production accounts.
- Gate any new real-backend test with `.tags(.integration)` and the same `.enabled(if:)` check.
- `scripts/run-smoke-tests.sh` uses `-only-testing:"ClickMe2026Tests/AuthSmokeTests"`. Add `SignupSmokeTests` to that invocation if it should run from the script.

**E2E / UI Tests:**
- Framework: XCTest with `Salad` page objects. Only the Xcode template and a stub exist:
  - `ClickMe2026UITests/ExampleUITests.swift` (Xcode template).
  - `ClickMe2026UITests/ViewObjects/HomeView.swift`: a `ViewObject` with `identifyingElementId = "HomeView"`, exposing `userEmailLabel` (`staticTexts["userEmailLabel"]`) and `refreshButton` (`buttons["refreshButton"]`).
  - `ClickMe2026UITests/Behaviours/RefreshBehaviour.swift`: a `Behavior` that taps `refreshButton` and returns the view.
- Pattern: view objects describe screen elements by accessibility identifier, and behaviours perform actions and return the next view object. The identifiers these page objects use (`HomeView`, `userEmailLabel`, `refreshButton`) do not appear anywhere in the app source yet (no `accessibilityIdentifier` calls exist in `ClickMe2026/`). Add `.accessibilityIdentifier(...)` to the matching views when UI tests are extended, so the lookups can succeed.

## Common Patterns

**Async Testing:**

```swift
@Test("decodes successful response into SuccessDataResponse<LoginData>")
func decodesSuccessResponse() async throws {
    let api = APITestFactory.make(status: 200, fixture: "login_success")

    let response = try await api.login(email: "ada@example.com", password: "hunter2!")

    #expect(response.status == "success")
}
```

Mark the suite `@MainActor` when it calls `ClickMeAPI` or other main-actor types. Use `async throws` test functions. Do not use `XCTestExpectation` in unit tests.

**Error Testing:**

```swift
await #expect(throws: NetworkError.self) {
    _ = try await api.login(email: "ada@example.com", password: "wrong-pw")
}

do {
    _ = try await api.login(email: "ada@example.com", password: "wrong-pw")
    Issue.record("Expected login to throw for 401")
} catch let NetworkError.httpError(statusCode, data) {
    #expect(statusCode == 401)
    let decoded = try JSONDecoder().decode(StandardErrorResponse.self, from: data)
    #expect(decoded.message == "The email or password is incorrect.")
} catch {
    Issue.record("Expected httpError but got \(error)")
}
```

Assert the status code and the decoded server error body, so the test verifies what the UI will show through `Error.userMessage`.

**Gating a test on configuration:**

```swift
@Suite(
    "Signup · Integration Smoke",
    .serialized,
    .tags(.integration),
    .enabled(if: SmokeConfig.isEnabled, "Set CLICKME_TEST_EMAIL to enable the signup smoke suite.")
)
```

**Gaps to fill first (suggested order):**
1. Remaining endpoints in `ClickMeAPI+*.swift`, using the `LoginTests` pattern and new fixtures under `Fixtures/<Area>/`.
2. Request-building and refresh behavior in `NetworkService` (401 refresh-then-retry, `403 ACCOUNT_SUSPENDED` handler), using `MockURLProtocol` with a stub `TokenRefresher`.
3. Pure logic in view models that does not need UI, such as `MakeABookingViewModel` availability bucketing by client-local date. Build these with `@MainActor` and no SwiftUI.

---

*Testing analysis: 2026-11-07*
