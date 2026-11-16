//
//  BookingShortIDTests.swift
//  ClickMe2026Tests
//
//  BOOK-20: one short booking ID format. The fixture UUID is the one the
//  Android Booking Summary test uses (BookingSummaryScreenTest), so both
//  platforms pin the same output.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Booking short ID")
struct BookingShortIDTests {

    private let id = UUID(uuidString: "7F3C9A2B-1D4E-4C8A-9B0F-123456789ABC")!

    @Test("short is '#' plus the first 8 characters of the id, upper-cased")
    func shortForm() {
        #expect(BookingShortID.short(id) == "#7F3C9A2B")
    }

    @Test("the label is 'ID: ' plus the short form")
    func labelForm() {
        #expect(BookingShortID.label(id) == "ID: #7F3C9A2B")
        #expect(BookingShortID.label(id) == "ID: " + BookingShortID.short(id))
    }

    @Test("a UUID built from the lower-case string gives the same short ID")
    func lowerCaseInput() throws {
        let lower = try #require(UUID(uuidString: "7f3c9a2b-1d4e-4c8a-9b0f-123456789abc"))
        #expect(BookingShortID.short(lower) == "#7F3C9A2B")
    }

    @Test("the expert Booking Summary label uses the same rule (EXP-18)")
    func expertSummaryLabel() throws {
        let expertId = try #require(UUID(uuidString: "7f3c9a2b-1d4e-4f6a-9b8c-0d1e2f3a4b5c"))
        let viewModel = ExpertBookingSummaryViewModel(bookingId: expertId)
        #expect(viewModel.bookingIdLabel == "ID: #7F3C9A2B")
        #expect(viewModel.bookingIdLabel == BookingShortID.label(expertId))
    }
}
