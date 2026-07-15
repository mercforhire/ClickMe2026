//
//  SignupSmokeTests.swift
//  ClickMe2026Tests
//
//  End-to-end integration coverage for the expert signup flow. Hits the real
//  backend defined by `AppEnvironment.current.baseURL`, one endpoint at a
//  time in the same order the SwiftUI flow calls them:
//
//    1. POST /auth/signup                  (create account, obtain token)
//    2. GET  /auth/email/status            (poll — should be false right after)
//    3. POST /auth/email/resend            (rate-limited on the server side)
//    4. GET  /meta/languages, /meta/expertise-tags (fetch real ids for setup)
//    5. PATCH /expert/profile/setup        (final publish, uses accumulator's builder)
//
//  Each run creates a fresh DB row with a timestamped username/email. There
//  is no explicit cleanup — talk to the backend team about a scheduled
//  sweep of `verify.smoke.*@clickme.test` accounts if this becomes an issue.
//
//  Gated on `CLICKME_TEST_EMAIL` (same knob as `AuthSmokeTests`) so default
//  CI runs stay green. The signup flow itself doesn't need those credentials,
//  but reusing the same gate keeps "hit staging" opt-in behind one switch.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite(
    "Signup · Integration Smoke",
    .serialized,
    .tags(.integration),
    .enabled(if: SmokeConfig.isEnabled, "Set CLICKME_TEST_EMAIL to enable the signup smoke suite.")
)
@MainActor
struct SignupSmokeTests {

    // MARK: - POST /auth/signup

    @Test("signup creates a new account and returns a bearer token")
    func signupReturnsToken() async throws {
        let api = makeRealAPI()
        let (username, email) = uniqueIdentity()

        let response = try await api.signup(SignupRequest(
            username: username,
            email: email,
            password: "Verify123!",
            role: "expert"
        ))

        #expect(response.status == "success")
        #expect(!response.data.token.isEmpty, "Backend did not return a bearer token.")
        #expect(response.data.user.role == .expert)
        #expect(response.data.emailVerified == false,
                "Freshly created account should not be pre-verified.")
    }

    // MARK: - Duplicate account

    @Test("re-signing up with the same email returns a 4xx")
    func signupWithDuplicateEmailFails() async throws {
        let api = makeRealAPI()
        let (username, email) = uniqueIdentity()

        // First create it — should succeed.
        _ = try await api.signup(SignupRequest(
            username: username, email: email, password: "Verify123!", role: "expert"
        ))

        // Second attempt with the same email but a different username must fail.
        do {
            _ = try await api.signup(SignupRequest(
                username: username + "dup",
                email: email,
                password: "Verify123!",
                role: "expert"
            ))
            Issue.record("Second signup with duplicate email unexpectedly succeeded.")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect((400 ... 499).contains(statusCode),
                    "Expected a 4xx duplicate error, got \(statusCode).")
            let decoded = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
            #expect(decoded != nil,
                    "Duplicate-signup response should conform to StandardErrorResponse.")
        }
    }

    // MARK: - GET /auth/email/status + POST /auth/email/resend

    @Test("email verification endpoints require auth and behave sanely")
    func emailStatusAndResend() async throws {
        let api = makeRealAPI()
        let signup = try await freshAccount(api: api)
        api.bearerToken = signup.token

        // Freshly-signed-up account should report `verified: false`.
        let status = try await api.checkEmailVerified()
        #expect(status.status == "success")
        #expect(status.data.verified == false)

        // Resend should either succeed or come back as a well-formed rate-limit.
        do {
            let resend = try await api.resendVerificationEmail()
            #expect(resend.status == "success")
            #expect(!resend.message.isEmpty)
        } catch let NetworkError.httpError(statusCode, data) {
            // 429 is the documented rate-limit response — accept it.
            #expect(statusCode == 429,
                    "Expected 200 or 429 from resend, got \(statusCode).")
            let decoded = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
            #expect(decoded != nil)
        }
    }

    @Test("email/status without a token returns 401")
    func emailStatusRequiresAuth() async throws {
        let api = makeRealAPI()
        api.bearerToken = nil

        do {
            _ = try await api.checkEmailVerified()
            Issue.record("checkEmailVerified without a token unexpectedly succeeded.")
        } catch let NetworkError.httpError(statusCode, _) {
            #expect(statusCode == 401,
                    "Expected 401 unauthorised, got \(statusCode).")
        }
    }

    // MARK: - PATCH /expert/profile/setup (publish)

    @Test("publish sends the full accumulator payload and returns completion data")
    func publishExpertProfile() async throws {
        let api = makeRealAPI()
        let signup = try await freshAccount(api: api)
        api.bearerToken = signup.token

        // Pull real meta ids so the request is server-valid.
        let langs = try await api.getLanguages()
        let tags = try await api.getExpertiseTags()
        let firstLang = try #require(langs.data.languages.first)
        let secondLang = try #require(langs.data.languages.dropFirst().first)
        let firstTag = try #require(tags.data.tags.first)

        // Compose the same way the Review screen does, via the accumulator.
        let accumulator = SignupAccumulator()
        accumulator.firstName = "Verify"
        accumulator.city = "Toronto"
        accumulator.provinceState = "ON"
        accumulator.countryCode = "CAN"
        accumulator.timezone = "America/Toronto"
        accumulator.languages = [firstLang, secondLang]
        accumulator.expertiseTags = [firstTag]
        accumulator.hourlyRateAmount = 8000 // $80.00 in minor units
        accumulator.hourlyRateCurrency = "USD"

        #expect(accumulator.isReadyToPublish,
                "Accumulator should report ready with every required field set.")

        let body = try #require(accumulator.buildSetupExpertProfileRequest())
        let response = try await api.setupExpertProfile(body)

        #expect(response.status == "success")
        #expect(response.data.profileId.uuidString == signup.user.id.uuidString,
                "profile_id should match the auth user's id.")
        #expect((0 ... 100).contains(response.data.completionPercentage))
        // Photo step was skipped in this test, so the backend should list it.
        #expect(response.data.missingFields.contains("profile_image_url"),
                "Missing fields should include profile_image_url when no avatar was uploaded.")
    }

    // MARK: - Guard: builder refuses an incomplete accumulator

    @Test("buildSetupExpertProfileRequest returns nil when required fields are missing")
    func builderRejectsIncomplete() {
        let accumulator = SignupAccumulator()
        // Deliberately leave hourly rate / languages / tags unset.
        accumulator.firstName = "Verify"
        accumulator.city = "Toronto"
        accumulator.provinceState = "ON"
        accumulator.countryCode = "CAN"

        #expect(!accumulator.isReadyToPublish)
        #expect(accumulator.buildSetupExpertProfileRequest() == nil,
                "Builder should refuse to build when required fields are missing.")
    }

    // MARK: - Helpers

    /// Creates a fresh account and returns the `SignupResponse` payload.
    private func freshAccount(api: ClickMeAPI) async throws -> SignupResponse {
        let (username, email) = uniqueIdentity()
        let response = try await api.signup(SignupRequest(
            username: username, email: email, password: "Verify123!", role: "expert"
        ))
        return response.data
    }

    /// Timestamp + random suffix — unique across runs and parallel tests.
    private func uniqueIdentity() -> (username: String, email: String) {
        let stamp = Int(Date().timeIntervalSince1970)
        let jitter = Int.random(in: 100 ... 999)
        let user = "smoke\(stamp)\(jitter)"
        return (user, "verify.smoke.\(stamp)\(jitter)@clickme.test")
    }

    private func makeRealAPI() -> ClickMeAPI {
        let service = NetworkService()
        return ClickMeAPI(baseURL: AppEnvironment.current.baseURL, service: service)
    }
}
