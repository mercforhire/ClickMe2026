//
//  DeleteAccountViewModelTests.swift
//  ClickMe2026Tests
//
//  SET-06 (D-10, RESEARCH Pitfall 11): a self-delete 409 on either step shows
//  the blocker, leaves the user on the feedback step, and a retry asks the
//  server for a fresh single-use token before DELETE. No test reaches the
//  success path, so the shared manager's remembered email is never touched.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Delete account view model", .serialized)
struct DeleteAccountViewModelTests {

    // MARK: - Helpers

    private nonisolated static func json(
        _ request: URLRequest, status: Int, body: String
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(body.utf8))
    }

    private nonisolated static func errorBody(code: String?, message: String) -> String {
        let codePart = code.map { #""code":"\#($0)","# } ?? ""
        return #"{"status":"error",\#(codePart)"message":"\#(message)"}"#
    }

    /// delete-request answers `requestStatus`/`requestBody`; DELETE answers `deleteStatus`/`deleteBody`.
    private static func makeViewModel(
        requestStatus: Int = 200,
        requestBody: String = #"{"status":"success","data":{"deletion_token":"tok-1"}}"#,
        deleteStatus: Int = 200,
        deleteBody: String = #"{"status":"success","message":"Account deleted"}"#
    ) -> DeleteAccountViewModel {
        let api = APITestFactory.make { request in
            let isDeleteRequest = request.url?.path.hasSuffix("/delete-request") == true
            return isDeleteRequest
                ? json(request, status: requestStatus, body: requestBody)
                : json(request, status: deleteStatus, body: deleteBody)
        }
        return DeleteAccountViewModel(
            step: .feedback, selectedReason: .other, password: "pw-123456", api: api
        )
    }

    private static func deleteRequestCount() -> Int {
        MockURLProtocol.recordedRequests
            .filter { $0.url?.path.hasSuffix("/delete-request") == true }
            .count
    }

    private static func deleteCallCount() -> Int {
        MockURLProtocol.recordedRequests
            .filter { $0.httpMethod == "DELETE" }
            .count
    }

    // MARK: - 409 on delete-request

    @Test("a 409 CLIENT_HAS_UPCOMING_BOOKINGS on delete-request shows the client blocker and sends no DELETE")
    func requestStep409Client() async {
        let viewModel = Self.makeViewModel(
            requestStatus: 409,
            requestBody: Self.errorBody(code: "CLIENT_HAS_UPCOMING_BOOKINGS", message: "server text")
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == .clientUpcoming)
        #expect(viewModel.deletionError == nil)
        #expect(viewModel.passwordError == nil)
        #expect(viewModel.step == .feedback)
        #expect(Self.deleteCallCount() == 0)
    }

    @Test("a 409 SESSION_IN_PROGRESS on delete-request shows the session blocker")
    func requestStep409Session() async {
        let viewModel = Self.makeViewModel(
            requestStatus: 409,
            requestBody: Self.errorBody(code: "SESSION_IN_PROGRESS", message: "server text")
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == .sessionInProgress)
        #expect(viewModel.deletionError == nil)
        #expect(viewModel.step == .feedback)
    }

    @Test("a 409 with an unknown code on delete-request shows the server message, no blocker")
    func requestStep409UnknownCode() async {
        let viewModel = Self.makeViewModel(
            requestStatus: 409,
            requestBody: Self.errorBody(code: "SOMETHING_NEW", message: "Please contact support.")
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == nil)
        #expect(viewModel.deletionError == "Please contact support.")
        #expect(viewModel.step == .feedback)
    }

    @Test("a 409 with no code on delete-request shows the server message, no blocker")
    func requestStep409NoCode() async {
        let viewModel = Self.makeViewModel(
            requestStatus: 409,
            requestBody: Self.errorBody(code: nil, message: "Conflict happened.")
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == nil)
        #expect(viewModel.deletionError == "Conflict happened.")
    }

    // MARK: - 409 on DELETE

    @Test("a 409 EXPERT_HAS_UPCOMING_BOOKINGS on DELETE shows the expert blocker and stays on feedback")
    func deleteStep409Expert() async {
        let viewModel = Self.makeViewModel(
            deleteStatus: 409,
            deleteBody: Self.errorBody(code: "EXPERT_HAS_UPCOMING_BOOKINGS", message: "server text")
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == .expertUpcoming)
        #expect(viewModel.deletionError == nil)
        #expect(viewModel.step == .feedback)
        #expect(Self.deleteCallCount() == 1)
    }

    @Test("a 409 with an unknown code on DELETE shows the server message, no blocker")
    func deleteStep409UnknownCode() async {
        let viewModel = Self.makeViewModel(
            deleteStatus: 409,
            deleteBody: Self.errorBody(code: "SOMETHING_NEW", message: "Try again later.")
        )

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == nil)
        #expect(viewModel.deletionError == "Try again later.")
        #expect(viewModel.step == .feedback)
    }

    // MARK: - Retry

    @Test("a second confirm after a DELETE 409 asks for a fresh token and shows the blocker again")
    func retryAfterDelete409() async {
        let viewModel = Self.makeViewModel(
            deleteStatus: 409,
            deleteBody: Self.errorBody(code: "EXPERT_HAS_UPCOMING_BOOKINGS", message: "server text")
        )

        await viewModel.confirmDeletion()
        #expect(viewModel.blocker == .expertUpcoming)
        #expect(Self.deleteRequestCount() == 1)

        await viewModel.confirmDeletion()

        #expect(Self.deleteRequestCount() == 2)
        #expect(Self.deleteCallCount() == 2)
        #expect(viewModel.blocker == .expertUpcoming)
        #expect(viewModel.step == .feedback)
    }

    @Test("a confirm clears the previous blocker before the next attempt")
    func confirmClearsPreviousBlocker() async {
        let viewModel = Self.makeViewModel(
            requestStatus: 401,
            requestBody: Self.errorBody(code: nil, message: "Password is incorrect.")
        )
        viewModel.blocker = .clientUpcoming

        await viewModel.confirmDeletion()

        #expect(viewModel.blocker == nil)
        #expect(viewModel.passwordError == "Password is incorrect.")
    }
}
