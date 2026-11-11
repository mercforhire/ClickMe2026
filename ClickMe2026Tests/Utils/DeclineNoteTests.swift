//
//  DeclineNoteTests.swift
//  ClickMe2026Tests
//
//  BACK-02 (iOS half): the client Booking Summary shows the expert's decline
//  note on a declined booking. `DeclineNote` maps the code to a reason line and
//  decides whether the card shows at all (03-UI-SPEC EM2, LT1).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Decline note")
@MainActor
struct DeclineNoteTests {

    // MARK: Reason line

    @Test("UNAVAILABLE reads 'Not available at that time' and keeps the expert's text")
    func unavailable() {
        let note = DeclineNote.make(status: "declined", code: "UNAVAILABLE", text: "Out that week")
        #expect(note?.reasonLine == "Not available at that time")
        #expect(note?.text == "Out that week")
    }

    @Test(
        "every listed code maps to its UI-SPEC reason line",
        arguments: [
            ("UNAVAILABLE", "Not available at that time"),
            ("OUTSIDE_EXPERTISE", "Outside their expertise"),
            ("OUT_OF_SCOPE", "Outside their expertise"),
            ("SCHEDULE_CONFLICT", "Schedule conflict"),
            ("CONFLICT", "Schedule conflict"),
            ("PRICING", "Pricing mismatch"),
            ("OTHER", "Other reason")
        ]
    )
    func reasonLines(code: String, expected: String) {
        #expect(DeclineNote.reasonLine(for: code) == expected)
    }

    @Test("a code this build does not know shows no reason line and never the raw code")
    func unknownCode() {
        let note = DeclineNote.make(status: "declined", code: "SOMETHING_NEW", text: "Sorry")
        #expect(note?.reasonLine == nil)
        #expect(note?.text == "Sorry")
        #expect(DeclineNote.reasonLine(for: "SOMETHING_NEW") == nil)
        #expect(DeclineNote.reasonLine(for: nil) == nil)
    }

    @Test("codes are matched exactly, not case-insensitively or by prefix")
    func codeMatchIsExact() {
        #expect(DeclineNote.reasonLine(for: "pricing") == nil)
        #expect(DeclineNote.reasonLine(for: "PRICING ") == nil)
    }

    // MARK: Show or hide

    @Test("a known code with no text still shows the reason line")
    func codeOnly() {
        let note = DeclineNote.make(status: "declined", code: "PRICING", text: nil)
        #expect(note?.reasonLine == "Pricing mismatch")
        #expect(note?.text == nil)
    }

    @Test("text with no code shows the text alone")
    func textOnly() {
        let note = DeclineNote.make(status: "declined", code: nil, text: "Not a fit")
        #expect(note?.reasonLine == nil)
        #expect(note?.text == "Not a fit")
    }

    @Test("no code and blank text means nothing to show (EM2)")
    func nothingToShow() {
        #expect(DeclineNote.make(status: "declined", code: nil, text: "   ") == nil)
        #expect(DeclineNote.make(status: "declined", code: nil, text: "\n") == nil)
        #expect(DeclineNote.make(status: "declined", code: nil, text: nil) == nil)
    }

    @Test("an unknown code with blank text has no reason line and no text, so no card")
    func unknownCodeBlankText() {
        #expect(DeclineNote.make(status: "declined", code: "SOMETHING_NEW", text: " ") == nil)
    }

    @Test("a booking that is not declined never shows the card, whatever the fields hold")
    func notDeclined() {
        for status in ["cancelled", "confirmed", "completed", "missed", "expired", "pending_reschedule", "unknown_status"] {
            #expect(DeclineNote.make(status: status, code: "UNAVAILABLE", text: "Out that week") == nil)
        }
    }

    @Test("a long note is kept whole and trimmed only at its ends")
    func longTextIsNotTruncated() {
        let body = String(repeating: "word ", count: 190) + "end"
        let note = DeclineNote.make(status: "declined", code: "OTHER", text: "\n  " + body + "  \n")
        #expect(note?.text == body)
        #expect((note?.text?.count ?? 0) > 900)
    }

    @Test("markup in the note is kept as the literal characters")
    func markupIsLiteral() {
        let raw = "**bold** [link](https://example.com) <b>x</b>"
        let note = DeclineNote.make(status: "declined", code: nil, text: raw)
        #expect(note?.text == raw)
    }

    // MARK: Decoding

    /// Configured like `NetworkService`'s decoder for the keys the fixture
    /// needs: snake_case keys and fractional-second ISO-8601 dates.
    private static func decodeDetail(extraFields: String) throws -> ClientBookingDetail {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: string)
            }
            return date
        }
        let data = ClientBookingFixtures.detailJSON(status: "declined", extraFields: extraFields)
        return try decoder.decode(SuccessDataResponse<ClientBookingDetail>.self, from: data).data
    }

    @Test("decline_reason_code and decline_reason_text decode when present")
    func decodesPresent() throws {
        let detail = try Self.decodeDetail(
            extraFields: #""decline_reason_code":"PRICING","decline_reason_text":"Too low""#
        )
        #expect(detail.declineReasonCode == "PRICING")
        #expect(detail.declineReasonText == "Too low")
    }

    @Test("a code this build does not know still decodes, as a raw string")
    func decodesUnknownCode() throws {
        let detail = try Self.decodeDetail(
            extraFields: #""decline_reason_code":"SOMETHING_NEW","decline_reason_text":null"#
        )
        #expect(detail.declineReasonCode == "SOMETHING_NEW")
        #expect(detail.declineReasonText == nil)
    }

    @Test("decline_reason_code and decline_reason_text decode when null")
    func decodesNull() throws {
        let detail = try Self.decodeDetail(
            extraFields: #""decline_reason_code":null,"decline_reason_text":null"#
        )
        #expect(detail.declineReasonCode == nil)
        #expect(detail.declineReasonText == nil)
    }

    @Test("a payload without the decline fields still decodes")
    func decodesAbsent() throws {
        let detail = try Self.decodeDetail(extraFields: "")
        #expect(detail.declineReasonCode == nil)
        #expect(detail.declineReasonText == nil)
    }
}
