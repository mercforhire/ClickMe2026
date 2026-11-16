//
//  ClientProfileHistoryEarningsTests.swift
//  ClickMe2026Tests
//
//  Pins what the expert Client Profile history row shows as its amount
//  (BOOK-10, EXP-14): the booking's net earnings from
//  `GET /expert/bookings` -> `session.earnings_breakdown.net_amount` (major
//  units) in `earnings_breakdown.currency`, gated by status exactly as the
//  Android port does (`ClientHistory.AMOUNT_STATUSES`). Rows outside that gate,
//  or with no net amount, show a dash, never gross and never a made-up zero.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Client profile history earnings mapping")
struct ClientProfileHistoryEarningsTests {

    @Test("a confirmed booking shows its net earnings in the booking currency")
    func confirmedShowsNet() throws {
        let row = ClientProfileViewModel.mapBooking(from: try item(status: "confirmed", net: 75.0, currency: "CAD"))
        #expect(row.amountMajor == 75.0)
        #expect(row.currency == "CAD")
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: row.amountMajor, currency: row.currency) == "CA$75.00")
    }

    @Test("a cancelled booking shows a dash even though the feed still sends a breakdown")
    func cancelledShowsDash() throws {
        let row = ClientProfileViewModel.mapBooking(from: try item(status: "cancelled", net: 75.0, currency: "CAD"))
        #expect(row.amountMajor == nil)
        #expect(row.currency == nil)
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: row.amountMajor, currency: row.currency) == "—")
    }

    @Test("a gated booking with no net amount shows a dash, and gross never stands in")
    func nilNetShowsDash() throws {
        let row = ClientProfileViewModel.mapBooking(
            from: try item(status: "confirmed", net: nil, currency: "CAD", feeSource: "unavailable", gross: 100.0)
        )
        #expect(row.amountMajor == nil)
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: row.amountMajor, currency: row.currency) == "—")
    }

    @Test("a row with no earnings breakdown at all shows a dash")
    func missingBreakdownShowsDash() throws {
        let row = ClientProfileViewModel.mapBooking(from: try item(status: "completed", breakdown: nil))
        #expect(row.amountMajor == nil)
        #expect(row.currency == nil)
    }

    @Test(
        "the amount is shown for the five statuses Android shows it for",
        arguments: ["pending_approval", "confirmed", "pending_reschedule", "in_progress", "completed"]
    )
    func shownStatuses(status: String) throws {
        let row = ClientProfileViewModel.mapBooking(from: try item(status: status, net: 42.5, currency: "USD"))
        #expect(row.amountMajor == 42.5)
        #expect(row.currency == "USD")
    }

    @Test(
        "the amount is hidden for cancelled, declined, missed, expired, rescheduled and unknown statuses",
        arguments: ["cancelled", "declined", "missed", "expired", "rescheduled", "some_future_status"]
    )
    func hiddenStatuses(status: String) throws {
        let row = ClientProfileViewModel.mapBooking(from: try item(status: status, net: 42.5, currency: "USD"))
        #expect(row.amountMajor == nil)
        #expect(row.currency == nil)
    }

    @Test("a client with CAD and USD sessions shows each row in its own currency (EXP-14)")
    func mixedCurrenciesStayApart() throws {
        let cad = ClientProfileViewModel.mapBooking(from: try item(status: "confirmed", net: 75.0, currency: "CAD"))
        let usd = ClientProfileViewModel.mapBooking(from: try item(status: "completed", net: 42.5, currency: "USD"))
        let cancelled = ClientProfileViewModel.mapBooking(from: try item(status: "cancelled", net: 42.5, currency: "USD"))

        #expect(ClientProfileBookingCard.amountLabel(amountMajor: cad.amountMajor, currency: cad.currency) == "CA$75.00")
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: usd.amountMajor, currency: usd.currency) == "$42.50")
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: cancelled.amountMajor, currency: cancelled.currency) == "—")
    }

    @Test("earnings_breakdown.net_amount and currency decode from the list row as the backend sends them")
    func breakdownFieldsDecode() throws {
        let decoded = try item(status: "confirmed", net: 75.0, currency: "CAD")
        #expect(decoded.session.earningsBreakdown?.netAmount == 75.0)
        #expect(decoded.session.earningsBreakdown?.currency == "CAD")
        #expect(decoded.session.earningsBreakdown?.feeSource == .booking)
    }

    // MARK: - Fixture

    /// One `GET /expert/bookings` row, as `buildSessionMoney` in the backend's
    /// `expertBooking.controller.js` shapes it: `consultation_fee.amount` and
    /// `earnings_breakdown.net_amount` already in major units, with a currency
    /// code on each. `breakdown: nil` omits the object, as a pre-rollout cached
    /// response would.
    private func item(
        status: String,
        net: Double?,
        currency: String,
        feeSource: String = "booking",
        gross: Double = 100.0
    ) throws -> ExpertBookingItem {
        let netJSON = net.map { String($0) } ?? "null"
        let breakdown = """
        {
          "gross_amount": \(gross),
          "platform_fee": \(net.map { String(gross - $0) } ?? "null"),
          "net_amount": \(netJSON),
          "commission_pct": 15.0,
          "currency": "\(currency)",
          "fee_source": "\(feeSource)"
        }
        """
        return try item(status: status, breakdown: breakdown)
    }

    private func item(status: String, breakdown: String?) throws -> ExpertBookingItem {
        let breakdownField = breakdown.map { ",\n\"earnings_breakdown\": \($0)" } ?? ""
        let json = """
        {
          "booking_id": "6F9619FF-8B86-D011-B42D-00C04FC964FF",
          "client": { "id": "0B6A2E6B-5D1B-4C8E-9C0C-2B7E7F6D5A41", "name": "Sophia Carter", "avatar_url": null },
          "session": {
            "topic": "SEO Audit Review",
            "start_time": "2026-06-05T10:00:00Z",
            "end_time": "2026-06-05T11:00:00Z",
            "meeting_type": "in_app_voice",
            "consultation_fee": { "amount": 100.0, "currency": "CAD", "label": "CA$100.00 / session" }\(breakdownField)
          },
          "status": { "label": "Confirmed", "code": "\(status)", "color_accent": "#00AA00" },
          "actions": { "can_join": false, "can_reschedule": false, "can_message": true },
          "private_note_preview": null,
          "reschedule": null
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExpertBookingItem.self, from: Data(json.utf8))
    }
}
