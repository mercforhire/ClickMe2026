//
//  BookingErrorMapperTests.swift
//  ClickMe2026Tests
//
//  BOOK-14 / PAY-05: one ErrorCode to copy table for booking and reschedule
//  errors, and the two long-lead codes the backend added on 2026-10-28.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("BookingErrorMapper")
struct BookingErrorMapperTests {

    private static let longLead = "Paid sessions can be booked up to 6 days ahead. Please choose an earlier time."
    private static let rescheduleFar =
        "Paid sessions can be rescheduled up to 6 days ahead. Please choose a time within the next 6 days."

    private func httpError(status: Int = 422, code: String?, message: String = "m") -> NetworkError {
        let codePart = code.map { #""code":"\#($0)","# } ?? ""
        let body = #"{"status":"error",\#(codePart)"message":"\#(message)"}"#
        return .httpError(statusCode: status, data: Data(body.utf8))
    }

    // MARK: - ErrorCode decoding

    @Test("the new long-lead and reschedule codes decode")
    func newCodesDecode() {
        #expect(ErrorCode(rawValue: "LONG_LEAD_NOT_AVAILABLE") == .longLeadNotAvailable)
        #expect(ErrorCode(rawValue: "RESCHEDULE_TOO_FAR_AHEAD") == .rescheduleTooFarAhead)
    }

    // MARK: - Copy table

    @Test("both long-lead codes show the 6-day booking copy")
    func longLeadCopy() {
        #expect(BookingErrorMapper.message(for: .longLeadRequiresSavedCard, fallback: "x") == Self.longLead)
        #expect(BookingErrorMapper.message(for: .longLeadNotAvailable, fallback: "x") == Self.longLead)
    }

    @Test("RESCHEDULE_TOO_FAR_AHEAD shows the 6-day reschedule copy")
    func rescheduleCopy() {
        #expect(BookingErrorMapper.message(for: .rescheduleTooFarAhead, fallback: "x") == Self.rescheduleFar)
    }

    @Test("the paid copy is the base for the shared codes")
    func sharedCopy() {
        #expect(BookingErrorMapper.message(for: .slotUnavailable, fallback: "x")
            == "That time slot was just taken. Please pick another.")
        #expect(BookingErrorMapper.message(for: .meetingLinkUnavailable, fallback: "x")
            == "The expert hasn't set up their Skype/Zoom link yet. Please choose in-app voice instead.")
        #expect(BookingErrorMapper.message(for: .bookingAttemptConflict, fallback: "x")
            == "Please try booking again.")
    }

    @Test("a code with no entry, or no code, returns the fallback")
    func fallback() {
        #expect(BookingErrorMapper.message(for: .internalError, fallback: "server text") == "server text")
        #expect(BookingErrorMapper.message(for: nil, fallback: "server text") == "server text")
    }

    // MARK: - Reading the code from an error

    @Test("code(for:) reads a known code from an httpError body")
    func codeKnown() {
        #expect(BookingErrorMapper.code(for: httpError(code: "LONG_LEAD_NOT_AVAILABLE")) == .longLeadNotAvailable)
    }

    @Test("code(for:) is nil for an unknown code, no code, or a non-HTTP error")
    func codeNil() {
        #expect(BookingErrorMapper.code(for: httpError(code: "SOMETHING_NEW")) == nil)
        #expect(BookingErrorMapper.code(for: httpError(code: nil)) == nil)
        #expect(BookingErrorMapper.code(for: URLError(.notConnectedToInternet)) == nil)
    }

    @Test("message(for: Error) maps a known code and falls back to the server message otherwise")
    func messageForError() {
        #expect(BookingErrorMapper.message(for: httpError(code: "LONG_LEAD_NOT_AVAILABLE", message: "raw"))
            == Self.longLead)
        #expect(BookingErrorMapper.message(for: httpError(code: "SOMETHING_NEW", message: "raw")) == "raw")
    }
}
