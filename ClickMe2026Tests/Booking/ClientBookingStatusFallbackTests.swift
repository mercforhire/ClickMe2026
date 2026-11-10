//
//  ClientBookingStatusFallbackTests.swift
//  ClickMe2026Tests
//
//  BOOK-18 (review WR-01): a server status this build does not recognise must
//  reach the client booking screens as `.unknown` (neutral), never as
//  `.confirmed`. Drives `UpcomingBookingViewModel` and `MyBookingsViewModel`
//  through their public `load()` against a MockURLProtocol-stubbed API.
//
//  The known-status tests are control cases: they prove the stub harness
//  maps a recognised status correctly, so a failure on the unknown-status
//  test is about the fallback and not the harness.
//
//  Expected result before the WR-01 fix: the unknown-status tests FAIL,
//  because `UpcomingBookingViewModel.apply` and `MyBookingsViewModel.mapUpcoming`
//  fall back to `.confirmed`.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Fixtures

private enum ClientBookingFixture {
    static let bookingId = "11111111-1111-4111-8111-111111111111"
    static let expertId = "22222222-2222-4222-8222-222222222222"
    static let topicId = "33333333-3333-4333-8333-333333333333"
    static let start = "2099-01-01T10:00:00.000Z"
    static let end = "2099-01-01T11:00:00.000Z"
    static let notFound = Data(#"{"status":"error","message":"nope"}"#.utf8)
    static let emptyList = Data(#"{"status":"success","data":{"bookings":[],"pagination":null}}"#.utf8)

    /// `GET /client/bookings/:id` success envelope carrying `status`.
    static func detailBody(status: String) -> Data {
        Data(#"""
        {"status":"success","data":{
          "booking_id":"\#(bookingId)",
          "status":"\#(status)",
          "start_time":"\#(start)",
          "end_time":"\#(end)",
          "meeting_type":"in_app_voice",
          "expert_timezone":"UTC",
          "payment_status":"none",
          "topic":{"id":"\#(topicId)","title":"Free chat","duration_mins":30,"is_free":true,"price":null},
          "expert":{"id":"\#(expertId)","full_name":"Ada Lovelace","avatar_url":null,"title":null},
          "join_link":null,
          "client_notes":null,
          "private_note":null,
          "reschedule":null,
          "authorization_expires_at":null,
          "can_join":null
        }}
        """#.utf8)
    }

    /// `GET /client/bookings?type=upcoming` success envelope with one row carrying `status`.
    static func upcomingListBody(status: String) -> Data {
        Data(#"""
        {"status":"success","data":{"bookings":[{
          "booking_id":"\#(bookingId)",
          "expert":{"id":"\#(expertId)","full_name":"Ada Lovelace","avatar_url":null},
          "topic":"Free chat",
          "start_time":"\#(start)",
          "end_time":"\#(end)",
          "meeting_type":"in_app_voice",
          "status":"\#(status)",
          "private_note_preview":null,
          "reschedule":null
        }],"pagination":null}}
        """#.utf8)
    }
}

/// Builds a success or 404 response for a stubbed request.
private func clientBookingResponse(
    for request: URLRequest,
    status: Int = 200,
    body: Data
) -> (HTTPURLResponse, Data) {
    let http = HTTPURLResponse(
        url: request.url!,
        statusCode: status,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
    )!
    return (http, body)
}

/// True when `state` is `.loaded`. `LoadState` is Equatable, but this keeps the
/// precondition check readable.
@MainActor
private func isLoaded(_ state: LoadState) -> Bool {
    state == .loaded
}

// MARK: - Suite

@Suite("Client booking status fallback (BOOK-18 / WR-01)", .serialized)
@MainActor
struct ClientBookingStatusFallbackTests {

    // MARK: Stubs

    /// Serves one detail payload for the booking id and 404s everything else.
    private func detailAPI(status: String) -> ClickMeAPI {
        let body = ClientBookingFixture.detailBody(status: status)
        let detailPath = "/client/bookings/" + ClientBookingFixture.bookingId
        return APITestFactory.make { request in
            if request.url?.path.hasSuffix(detailPath) == true {
                return clientBookingResponse(for: request, body: body)
            }
            return clientBookingResponse(for: request, status: 404, body: ClientBookingFixture.notFound)
        }
    }

    /// Serves one upcoming row with `status` and an empty past list.
    private func listAPI(status: String) -> ClickMeAPI {
        let upcoming = ClientBookingFixture.upcomingListBody(status: status)
        let empty = ClientBookingFixture.emptyList
        return APITestFactory.make { request in
            let isUpcoming = request.url?.absoluteString.contains("type=upcoming") == true
            return clientBookingResponse(for: request, body: isUpcoming ? upcoming : empty)
        }
    }

    // MARK: - UpcomingBookingViewModel (client Upcoming Booking details)

    @Test("control: a detail with status confirmed maps to .confirmed")
    func detailConfirmedControl() async {
        let vm = UpcomingBookingViewModel(
            bookingId: UUID(uuidString: ClientBookingFixture.bookingId)!,
            api: detailAPI(status: "confirmed")
        )
        await vm.load()
        #expect(isLoaded(vm.state))
        #expect(vm.bookingStatus == .confirmed)
    }

    @Test("control: a detail with status pending_approval maps to .pendingApproval")
    func detailPendingApprovalControl() async {
        let vm = UpcomingBookingViewModel(
            bookingId: UUID(uuidString: ClientBookingFixture.bookingId)!,
            api: detailAPI(status: "pending_approval")
        )
        await vm.load()
        #expect(isLoaded(vm.state))
        #expect(vm.bookingStatus == .pendingApproval)
    }

    @Test("a detail with an unrecognised status maps to .unknown, not .confirmed")
    func detailUnknownStatusIsNeutral() async {
        let vm = UpcomingBookingViewModel(
            bookingId: UUID(uuidString: ClientBookingFixture.bookingId)!,
            api: detailAPI(status: "some_future_status")
        )
        await vm.load()
        #expect(isLoaded(vm.state))
        #expect(vm.bookingStatus == .unknown)
    }

    // MARK: - MyBookingsViewModel (client My Bookings)

    @Test("control: an upcoming row with status pending_approval maps to .pendingApproval")
    func listPendingApprovalControl() async {
        let vm = MyBookingsViewModel(api: listAPI(status: "pending_approval"))
        await vm.load()
        #expect(isLoaded(vm.state))
        #expect(vm.upcomingBookings.map(\.status) == [.pendingApproval])
    }

    @Test("an upcoming row with an unrecognised status maps to .unknown, not .confirmed")
    func listUnknownStatusIsNeutral() async {
        let vm = MyBookingsViewModel(api: listAPI(status: "some_future_status"))
        await vm.load()
        #expect(isLoaded(vm.state))
        #expect(vm.upcomingBookings.map(\.status) == [.unknown])
    }
}
