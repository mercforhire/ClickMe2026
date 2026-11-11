//
//  UpcomingBookingViewModelTests.swift
//  ClickMe2026Tests
//
//  BOOK-06: Upcoming Booking details exposes an expert-proposed reschedule and
//  answers it through the shared `RescheduleResponder`, updating in place.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Upcoming booking view model", .serialized)
@MainActor
struct UpcomingBookingViewModelTests {

    private typealias Fixtures = ClientBookingFixtures

    private var bookingUUID: UUID { UUID(uuidString: Fixtures.bookingId)! }
    private var detailPath: String { "/client/bookings/" + Fixtures.bookingId }

    /// Serves one fixed detail payload and 404s everything else.
    private func detailAPI(body: Data) -> ClickMeAPI {
        let path = detailPath
        return APITestFactory.make { request in
            if request.url?.path.hasSuffix(path) == true {
                return Fixtures.response(for: request, body: body)
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
    }

    private func pendingDetail(initiatedBy: String) -> Data {
        Fixtures.detailJSON(
            status: "pending_reschedule",
            reschedule: Fixtures.rescheduleJSON(initiatedBy: initiatedBy, note: "Can we move it?")
        )
    }

    // MARK: Exposure

    @Test("an expert-initiated pending_reschedule detail exposes the proposal and the current start")
    func expertProposalIsExposed() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: pendingDetail(initiatedBy: "expert")))
        await vm.load()
        #expect(vm.pendingProposal?.initiatedBy == .expert)
        #expect(vm.pendingProposal?.note == "Can we move it?")
        #expect(vm.startTime != nil)
    }

    @Test("a confirmed detail exposes no proposal")
    func confirmedHasNoProposal() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: Fixtures.detailJSON()))
        await vm.load()
        #expect(vm.state == .loaded)
        #expect(vm.pendingProposal == nil)
    }

    @Test("a client-initiated proposal is exposed as client-initiated")
    func clientProposalIsExposed() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: pendingDetail(initiatedBy: "client")))
        await vm.load()
        #expect(vm.pendingProposal?.initiatedBy == .client)
    }

    // MARK: Accept in place

    @Test("accept sends one POST, then the screen shows the confirmed booking without leaving .loaded")
    func acceptUpdatesInPlace() async {
        let path = detailPath
        let pending = pendingDetail(initiatedBy: "expert")
        let confirmed = Fixtures.detailJSON(status: "confirmed", reschedule: "null")
        let api = APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if requestPath.hasSuffix("/accept-reschedule") {
                return Fixtures.response(for: request, body: Fixtures.successMessage)
            }
            if requestPath.hasSuffix(path) {
                let accepted = MockURLProtocol.recordedRequests.contains {
                    $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/accept-reschedule") == true
                }
                return Fixtures.response(for: request, body: accepted ? confirmed : pending)
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: api)
        await vm.load()
        #expect(vm.pendingProposal != nil)

        await vm.responder.accept()

        let acceptPosts = MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/accept-reschedule") == true
        }
        #expect(acceptPosts.count == 1)
        #expect(vm.pendingProposal == nil)
        #expect(vm.bookingStatus == .confirmed)
        #expect(vm.state == .loaded)
        #expect(vm.responder.apiError == nil)
    }

    // MARK: Silent refresh

    @Test("a refresh whose GET fails after a successful load keeps the content and .loaded")
    func failedRefreshKeepsContent() async {
        let path = detailPath
        let body = Fixtures.detailJSON()
        let api = APITestFactory.make { request in
            let detailRequests = MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix(path) == true }
            if request.url?.path.hasSuffix(path) == true, detailRequests.count == 1 {
                return Fixtures.response(for: request, body: body)
            }
            return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
        }
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: api)
        await vm.load()
        #expect(vm.state == .loaded)
        let topic = vm.topic
        #expect(topic == "Free chat")

        await vm.refresh()

        #expect(vm.state == .loaded)
        #expect(vm.topic == topic)
    }
}
