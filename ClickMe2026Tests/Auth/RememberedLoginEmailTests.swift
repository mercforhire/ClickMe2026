//
//  RememberedLoginEmailTests.swift
//  ClickMe2026Tests
//
//  After any sign-out, Login pre-fills the last signed-in email; account
//  deletion forgets it. Runs against `UserManager.shared` (the app's
//  Keychain via Valet in the test host), so the suite is serialized and
//  restores a clean state after each test. No test signs the shared manager
//  out: the sign-out routine runs Firebase and Keychain cleanup on the
//  singleton and would race the suite.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Remembered login email", .serialized)
@MainActor
struct RememberedLoginEmailTests {

    private let userManager = UserManager.shared

    init() {
        UserManager.shared.forgetLastLoginEmail()
    }

    @Test("a successful login stores the trimmed email")
    func remembersTrimmedEmail() {
        userManager.rememberLoginEmail("  ada@example.com \n")
        defer { userManager.forgetLastLoginEmail() }

        #expect(userManager.lastLoginEmail == "ada@example.com")
    }

    @Test("a whitespace-only email is ignored")
    func ignoresWhitespaceOnlyEmail() {
        userManager.rememberLoginEmail("ada@example.com")
        defer { userManager.forgetLastLoginEmail() }

        userManager.rememberLoginEmail("   \n ")

        #expect(userManager.lastLoginEmail == "ada@example.com")
    }

    @Test("Login with no remembered email starts empty")
    func emptyWhenNothingRemembered() {
        let viewModel = LoginViewModel()

        #expect(viewModel.email == "")
        #expect(viewModel.password == "")
    }

    @Test("Login after a sign-out pre-fills the email, password empty")
    func prefillsAfterSignOut() {
        // Every sign-out path funnels through `clearLocalSession()`, which
        // never touches the remembered email, so a remembered value is what
        // a fresh `LoginViewModel` sees after any of them.
        userManager.rememberLoginEmail("ada@example.com")
        defer { userManager.forgetLastLoginEmail() }

        let viewModel = LoginViewModel()

        #expect(userManager.lastLoginEmail == "ada@example.com")
        #expect(viewModel.email == "ada@example.com")
        #expect(viewModel.password == "")
    }

    @Test("the pre-filled email stays editable")
    func prefilledEmailIsEditable() {
        userManager.rememberLoginEmail("ada@example.com")
        defer { userManager.forgetLastLoginEmail() }
        let viewModel = LoginViewModel()

        viewModel.email = "other@example.com"

        #expect(viewModel.email == "other@example.com")
    }

    @Test("an explicit email wins over the remembered one")
    func explicitEmailWins() {
        userManager.rememberLoginEmail("ada@example.com")
        defer { userManager.forgetLastLoginEmail() }

        let viewModel = LoginViewModel(email: "reset@example.com")

        #expect(viewModel.email == "reset@example.com")
    }

    @Test("a successful account deletion forgets the email")
    func deletionForgetsEmail() async {
        userManager.rememberLoginEmail("ada@example.com")
        defer { userManager.forgetLastLoginEmail() }
        let api = APITestFactory.make { request in
            let isDeleteRequest = request.url?.path.hasSuffix("/delete-request") == true
            let body = isDeleteRequest
                ? #"{"status":"success","data":{"deletion_token":"tok-1"}}"#
                : #"{"status":"success","message":"Account deleted"}"#
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(body.utf8))
        }
        let viewModel = DeleteAccountViewModel(
            step: .feedback, selectedReason: .other, password: "hunter2!", api: api
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.step == .deleted)
        #expect(userManager.lastLoginEmail == nil)
        #expect(LoginViewModel().email == "")
    }

    @Test("a failed account deletion keeps the email")
    func failedDeletionKeepsEmail() async {
        userManager.rememberLoginEmail("ada@example.com")
        defer { userManager.forgetLastLoginEmail() }
        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"status":"error","message":"Password is incorrect."}"#.utf8))
        }
        let viewModel = DeleteAccountViewModel(
            step: .feedback, selectedReason: .other, password: "wrong-pw", api: api
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.step != .deleted)
        #expect(userManager.lastLoginEmail == "ada@example.com")
    }
}
