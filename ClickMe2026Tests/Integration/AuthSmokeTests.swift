//
//  AuthSmokeTests.swift
//  ClickMe2026Tests
//
//  Hits the real backend defined by `AppEnvironment.current.baseURL`.
//  Gated on `CLICKME_TEST_EMAIL` — when the env var is absent the suite is
//  skipped so CI runs stay green. Provide `CLICKME_TEST_PASSWORD` in addition
//  to enable the happy-path login test.
//
//  Do **not** run these in a tight loop; they consume real backend resources
//  and could rate-limit or lock the test account.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite(
    "Auth · Integration Smoke",
    .serialized,
    .tags(.integration),
    .enabled(if: SmokeConfig.isEnabled, "Set CLICKME_TEST_EMAIL (and CLICKME_TEST_PASSWORD) env vars to enable smoke tests.")
)
@MainActor
struct AuthSmokeTests {

    // MARK: - Reachability

    @Test("backend is reachable at the configured base URL")
    func backendIsReachable() async throws {
        let api = makeRealAPI()

        // Login with obvious garbage — we don't care whether it's 401 or 422;
        // we only care that we got a well-formed error response back, i.e. the
        // server is up and speaking the shape our client expects.
        do {
            _ = try await api.login(
                email: "probe-\(UUID().uuidString)@invalid.local",
                password: "definitely-not-the-real-password"
            )
            Issue.record("Login with garbage credentials unexpectedly succeeded.")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect((400 ... 499).contains(statusCode),
                    "Expected a 4xx from the server, got \(statusCode).")
            #expect(!data.isEmpty, "Server returned an empty error body.")
        } catch {
            Issue.record("Backend unreachable or returned an unexpected error: \(error)")
        }
    }

    // MARK: - Invalid credentials

    @Test("login with invalid credentials returns a decodable error body")
    func loginWithInvalidCredentials() async throws {
        let api = makeRealAPI()

        do {
            _ = try await api.login(
                email: "does-not-exist-\(UUID().uuidString)@invalid.local",
                password: "wrongwrongwrong"
            )
            Issue.record("Invalid-credential login unexpectedly succeeded.")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect((400 ... 499).contains(statusCode))

            // Server body should conform to one of our documented error shapes.
            let decoder = JSONDecoder()
            let asStandard = try? decoder.decode(StandardErrorResponse.self, from: data)
            let asFieldErr = try? decoder.decode(FieldValidationErrorResponse.self, from: data)

            #expect(asStandard != nil || asFieldErr != nil,
                    "Server error body did not match either known error shape: \(String(data: data, encoding: .utf8) ?? "<binary>")")
        }
    }

    // MARK: - Forgot password

    @Test("forgotPassword returns a well-formed response for a probe identity")
    func forgotPasswordReturnsWellFormedResponse() async throws {
        let api = makeRealAPI()

        // Use a random probe identity so we never trigger a real reset email
        // to an existing account. Most servers respond with a generic success
        // regardless of whether the account exists (to prevent enumeration),
        // but we accept either shape.
        let probe = "probe-\(UUID().uuidString)@invalid.local"

        do {
            let response = try await api.forgotPassword(identity: probe)
            #expect(response.status == "success")
            #expect(!response.message.isEmpty)
        } catch let NetworkError.httpError(statusCode, data) {
            #expect((400 ... 499).contains(statusCode))

            // The error body should decode into one of our documented shapes.
            let decoder = JSONDecoder()
            let asStandard = try? decoder.decode(StandardErrorResponse.self, from: data)
            let asFieldErr = try? decoder.decode(FieldValidationErrorResponse.self, from: data)
            #expect(asStandard != nil || asFieldErr != nil,
                    "Server error body did not match either known error shape: \(String(data: data, encoding: .utf8) ?? "<binary>")")
        }
    }

    // MARK: - Reset password

    @Test("resetPassword with an unknown-email / bogus code returns 400 EXPIRED_TOKEN")
    func resetPasswordWithBogusCodeReturnsExpiredToken() async throws {
        let api = makeRealAPI()

        // Enumeration-safe design: unknown email / expired / used / max-attempts
        // all fold into 400 EXPIRED_TOKEN. Using a probe email means we never
        // touch a real account's reset flow.
        let probe = "probe-\(UUID().uuidString)@invalid.local"

        do {
            _ = try await api.resetPassword(
                email: probe,
                code: "000000",
                password: "N3wSecur3P@ss!",
                passwordConfirmation: "N3wSecur3P@ss!"
            )
            Issue.record("resetPassword with a bogus code unexpectedly succeeded.")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect(statusCode == 400,
                    "Expected 400 EXPIRED_TOKEN, got \(statusCode).")

            let decoded = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
            #expect(decoded?.code == .expiredToken,
                    "Expected code EXPIRED_TOKEN, got \(String(describing: decoded?.code)).")
        } catch {
            Issue.record("Backend unreachable or returned an unexpected error: \(error)")
        }
    }

    // MARK: - Happy path (needs real credentials)

    @Test(
        "login with valid credentials returns a token and can call /me",
        .enabled(if: SmokeConfig.hasCredentials, "CLICKME_TEST_PASSWORD not set — happy-path login skipped.")
    )
    func loginWithValidCredentials() async throws {
        let email = try #require(SmokeConfig.email)
        let password = try #require(SmokeConfig.password)

        let api = makeRealAPI()
        let loginResponse = try await api.login(email: email, password: password)

        // Verify LoginData shape
        #expect(loginResponse.status == "success")
        #expect(!loginResponse.data.token.isEmpty)
        #expect(!loginResponse.data.user.firstName.isEmpty)

        // Reuse the token to call an authenticated endpoint. This confirms the
        // token works, the bearer header is set correctly, and /me decodes.
        api.bearerToken = loginResponse.data.token
        let me = try await api.getMe()
        #expect(me.status == "success")
        #expect(me.data.role == loginResponse.data.user.role)
        #expect(me.data.email.caseInsensitiveCompare(email) == .orderedSame)
    }

    // MARK: - Helpers

    /// Builds a real `ClickMeAPI` pointed at whatever the active environment is.
    /// Uses the shared URLSession — nothing is mocked.
    private func makeRealAPI() -> ClickMeAPI {
        let service = NetworkService()
        return ClickMeAPI(baseURL: AppEnvironment.current.baseURL, service: service)
    }
}
