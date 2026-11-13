//
//  FeedbackValidationTests.swift
//  ClickMe2026Tests
//
//  SET-05: the server requires `details` of at least 10 characters
//  (feedback.schema.js `z.string().min(10)`, a JavaScript string length, so
//  UTF-16 units). Below that, iOS sends nothing, keeps what the user typed
//  and shows the inline error.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Feedback validation", .serialized)
struct FeedbackValidationTests {

    // MARK: - Fixtures

    private static let feedbackType = FeedbackTypeItem(
        id: "bug_report",
        label: "Bug Report",
        description: "Something isn't working right."
    )

    private static func makeViewModel(details: String, showDetailsError: Bool = false) -> FeedbackViewModel {
        let successBody = Data("{\"status\":\"success\"}".utf8)
        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, successBody)
        }
        return FeedbackViewModel(
            feedbackTypes: [feedbackType],
            loadState: .loaded,
            selectedType: feedbackType,
            details: details,
            showDetailsError: showDetailsError,
            api: api
        )
    }

    private static func submitCount() -> Int {
        MockURLProtocol.recordedRequests
            .filter { $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/feedback/submit") == true }
            .count
    }

    // MARK: - Too short: nothing is sent

    @Test(
        "Details under 10 trimmed characters send no request and keep the text",
        arguments: [
            "",
            "   ",
            "123456789",
            "  123456789  ",
            "\n\n123456789\n",
        ]
    )
    func tooShortSendsNothing(details: String) async {
        let viewModel = Self.makeViewModel(details: details)

        await viewModel.submit()

        #expect(Self.submitCount() == 0)
        #expect(viewModel.showDetailsError)
        #expect(viewModel.details == details)
        #expect(!viewModel.didSubmit)
    }

    // MARK: - Long enough: one request

    @Test("Exactly 10 characters sends one request")
    func tenCharactersSendsOnce() async {
        let viewModel = Self.makeViewModel(details: "1234567890")

        await viewModel.submit()

        #expect(Self.submitCount() == 1)
        #expect(!viewModel.showDetailsError)
    }

    @Test("Padding around 10 characters is trimmed and still sends")
    func paddedTenCharactersSendsOnce() async {
        let viewModel = Self.makeViewModel(details: "  1234567890  ")

        await viewModel.submit()

        #expect(Self.submitCount() == 1)
    }

    // MARK: - Encoding: UTF-16 units, as the server counts

    @Test("Four emoji (8 UTF-16 units) are refused")
    func fourEmojiRefused() async {
        let viewModel = Self.makeViewModel(details: String(repeating: "\u{1F44D}", count: 4))

        await viewModel.submit()

        #expect(Self.submitCount() == 0)
        #expect(viewModel.showDetailsError)
    }

    @Test("Five emoji (10 UTF-16 units) are accepted")
    func fiveEmojiAccepted() async {
        let viewModel = Self.makeViewModel(details: String(repeating: "\u{1F44D}", count: 5))

        await viewModel.submit()

        #expect(Self.submitCount() == 1)
    }

    // MARK: - Error clearing

    @Test("The error stays while the text is still too short and clears once it is long enough")
    func errorClearsOnlyWhenLongEnough() {
        let viewModel = Self.makeViewModel(details: "abc", showDetailsError: true)

        viewModel.detailsDidChange()
        #expect(viewModel.showDetailsError)

        viewModel.details = "abcdefghij"
        viewModel.detailsDidChange()
        #expect(!viewModel.showDetailsError)
    }

    // MARK: - Rule

    @Test("meetsMinimumLength trims, then counts UTF-16 units")
    func ruleBoundary() {
        #expect(FeedbackViewModel.minimumDetailsLength == 10)
        #expect(!FeedbackViewModel.meetsMinimumLength("123456789"))
        #expect(FeedbackViewModel.meetsMinimumLength("1234567890"))
        #expect(!FeedbackViewModel.meetsMinimumLength("   123456789   "))
    }

    // MARK: - After a successful send (P16.5 D-06, unchanged)

    @Test("A successful send clears the form and shows the thank-you")
    func successClearsForm() async {
        let viewModel = Self.makeViewModel(details: "This is long enough")

        await viewModel.submit()

        #expect(viewModel.details.isEmpty)
        #expect(viewModel.showThanks)
    }
}
