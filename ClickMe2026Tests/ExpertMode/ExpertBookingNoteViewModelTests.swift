//
//  ExpertBookingNoteViewModelTests.swift
//  ClickMe2026Tests
//
//  EXP-16 (D-19): the expert's private booking note is capped at 5,000 UTF-16
//  units as the expert types, shows a counter from 4,500, and saves a
//  whitespace-only note as an empty string (any other text is sent as typed).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Expert booking note", .serialized)
@MainActor
struct ExpertBookingNoteViewModelTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let bookingId = UUID(uuidString: Fixtures.bookingId)!

    nonisolated private static func isPost(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/note") == true
    }

    nonisolated private static func notePosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isPost)
    }

    nonisolated private static func noteBody(_ note: String?) -> Data {
        let value = note.map { "\"\($0)\"" } ?? "null"
        return Data(#"{"status":"success","data":{"booking_id":"\#(Fixtures.bookingId)","note":\#(value)}}"#.utf8)
    }

    /// Serves `GET /bookings/:id/note` (404 when `existing` is nil, else that note) and answers
    /// `POST` with `postStatus`; a 2xx POST echoes the note that was sent.
    private func makeViewModel(existing: String?, postStatus: Int = 200) async -> ExpertBookingNoteViewModel {
        let api = APITestFactory.make { request in
            if Self.isPost(request) {
                guard (200..<300).contains(postStatus) else {
                    return Fixtures.response(
                        for: request,
                        status: postStatus,
                        body: Fixtures.errorBody(code: "INTERNAL_ERROR", message: "Server broke")
                    )
                }
                let sent = request.jsonBodyForTest()?["note"] as? String
                return Fixtures.response(for: request, body: Self.noteBody(sent))
            }
            guard let existing else {
                return Fixtures.response(
                    for: request,
                    status: 404,
                    body: Fixtures.errorBody(code: "NOT_FOUND", message: "Not found")
                )
            }
            return Fixtures.response(for: request, body: Self.noteBody(existing))
        }
        let viewModel = ExpertBookingNoteViewModel(bookingId: Self.bookingId, api: api)
        await viewModel.load()
        return viewModel
    }

    // MARK: - Cap

    @Test("a 6,000 character paste is cut to 5,000 UTF-16 units")
    func longPasteIsCapped() async {
        let viewModel = await makeViewModel(existing: nil)
        viewModel.updateNote(String(repeating: "a", count: 6000))
        #expect(viewModel.noteText.utf16.count == 5000)
        #expect(viewModel.noteLength == 5000)
    }

    @Test("an emoji that would cross the cap is dropped whole, never split")
    func emojiIsNotSplit() async {
        let viewModel = await makeViewModel(existing: nil)
        viewModel.updateNote(String(repeating: "a", count: 4999) + "😀")
        #expect(viewModel.noteText.utf16.count == 4999)
        #expect(viewModel.noteText == String(repeating: "a", count: 4999))
    }

    @Test("text under the cap is kept exactly as typed")
    func shortTextIsUnchanged() async {
        let viewModel = await makeViewModel(existing: nil)
        viewModel.updateNote("  hello 😀 ")
        #expect(viewModel.noteText == "  hello 😀 ")
    }

    // MARK: - Counter

    @Test("the counter is hidden at 4,499 units and shown from 4,500")
    func counterThreshold() async {
        let viewModel = await makeViewModel(existing: nil)
        viewModel.updateNote(String(repeating: "a", count: 4499))
        #expect(viewModel.showsCounter == false)
        viewModel.updateNote(String(repeating: "a", count: 4500))
        #expect(viewModel.showsCounter == true)
    }

    @Test("the counter text groups digits for the locale")
    func counterText() {
        #expect(ExpertBookingNoteViewModel.counterText(length: 4731, locale: Locale(identifier: "en_US")) == "4,731 / 5,000")
        #expect(ExpertBookingNoteViewModel.counterText(length: 5000, locale: Locale(identifier: "en_US")) == "5,000 / 5,000")
        #expect(ExpertBookingNoteViewModel.counterText(length: 4731, locale: Locale(identifier: "de_DE")) == "4.731 / 5.000")
    }

    // MARK: - Normalization

    @Test("whitespace-only text normalizes to empty; other text is sent as typed")
    func normalization() {
        #expect(ExpertBookingNoteViewModel.normalizedForSave("  \n ") == "")
        #expect(ExpertBookingNoteViewModel.normalizedForSave("") == "")
        #expect(ExpertBookingNoteViewModel.normalizedForSave("  hi ") == "  hi ")
    }

    // MARK: - Save

    @Test("a whitespace-only note posts an empty string and the field then reads empty")
    func whitespaceOnlySavesEmpty() async {
        let viewModel = await makeViewModel(existing: nil)
        viewModel.updateNote("   ")
        #expect(viewModel.hasChanges == true)

        await viewModel.save()

        let posts = Self.notePosts()
        #expect(posts.count == 1)
        #expect(posts.first?.jsonBodyForTest()?["note"] as? String == "")
        #expect(viewModel.noteText == "")
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("a failed save keeps the text, reports the error and stays changed")
    func failedSaveKeepsText() async {
        let viewModel = await makeViewModel(existing: "old", postStatus: 500)
        #expect(viewModel.noteText == "old")
        viewModel.updateNote("new")

        await viewModel.save()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.noteText == "new")
        #expect(viewModel.hasChanges == true)
    }

    @Test("a successful save leaves nothing changed")
    func successfulSaveClearsChanges() async {
        let viewModel = await makeViewModel(existing: "old")
        viewModel.updateNote("abc")
        #expect(viewModel.hasChanges == true)

        await viewModel.save()

        #expect(viewModel.hasChanges == false)
        #expect(viewModel.noteText == "abc")
        #expect(viewModel.errorMessage == nil)
    }
}
