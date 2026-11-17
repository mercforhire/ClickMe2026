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

    // MARK: Booking ID (BOOK-20)

    @Test("after load, bookingIDLabel is the shared short ID of the booking")
    func bookingIDLabelUsesSharedFormat() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: Fixtures.detailJSON()))
        await vm.load()
        #expect(vm.bookingIDLabel == BookingShortID.short(bookingUUID))
        #expect(vm.bookingIDLabel == "#11111111")
    }

    // MARK: Status pill (BOOK-09)

    @Test("a status this build does not know loads as .unknown and reads as a neutral humanized pill")
    func unknownStatusPill() async {
        let vm = UpcomingBookingViewModel(
            bookingId: bookingUUID,
            api: detailAPI(body: Fixtures.detailJSON(status: "awaiting_payment"))
        )
        await vm.load()
        #expect(vm.bookingStatus == .unknown)
        #expect(vm.statusPill == BookingStatusPill(text: "Awaiting payment", tone: .neutral))
    }

    @Test("a pending_reschedule detail reads Pending reschedule in amber")
    func pendingReschedulePill() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: pendingDetail(initiatedBy: "expert")))
        await vm.load()
        #expect(vm.statusPill == BookingStatusPill(text: "Pending reschedule", tone: .amber))
    }

    @Test("the pill keeps its previous value when a silent refresh fails, then follows the server")
    func pillKeepsValueUntilRefetchLands() async {
        let path = detailPath
        let pending = pendingDetail(initiatedBy: "expert")
        let confirmed = Fixtures.detailJSON(status: "confirmed")
        let api = APITestFactory.make { request in
            let detailRequests = MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix(path) == true }
            guard request.url?.path.hasSuffix(path) == true else {
                return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
            }
            switch detailRequests.count {
            case 1: return Fixtures.response(for: request, body: pending)
            case 2: return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
            default: return Fixtures.response(for: request, body: confirmed)
            }
        }
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: api)
        await vm.load()
        #expect(vm.statusPill.text == "Pending reschedule")

        await vm.refresh()
        #expect(vm.state == .loaded)
        #expect(vm.statusPill.text == "Pending reschedule")

        await vm.refresh()
        #expect(vm.state == .loaded)
        #expect(vm.statusPill == BookingStatusPill(text: "Confirmed", tone: .accent))
    }

    // MARK: Join window (CALL-03)

    /// A fixed clock, so no row depends on when the suite runs.
    private let now = Date(timeIntervalSince1970: 4_070_000_000)

    private func loadedModel(
        status: String = "confirmed",
        start: Date,
        end: Date,
        canJoin: String = "null"
    ) async -> UpcomingBookingViewModel {
        let body = Fixtures.detailJSON(status: status, start: start, end: end, canJoin: canJoin)
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: body))
        await vm.load()
        return vm
    }

    @Test("the join window decodes the expert id, the end time and can_join")
    func joinInputsAreDecoded() async {
        let end = now.addingTimeInterval(5400)
        let vm = await loadedModel(start: now.addingTimeInterval(1800), end: end, canJoin: "true")
        #expect(vm.expertId == UUID(uuidString: Fixtures.expertId))
        #expect(vm.endTime != nil)
        #expect(vm.canJoin == true)
    }

    @Test("a confirmed booking starting in 30 minutes is joinable")
    func confirmedInsideWindow() async {
        let vm = await loadedModel(start: now.addingTimeInterval(1800), end: now.addingTimeInterval(5400))
        #expect(vm.joinWindowOpen(at: now))
    }

    @Test("a confirmed booking starting in 2 hours is not joinable yet")
    func confirmedBeforeWindow() async {
        let vm = await loadedModel(start: now.addingTimeInterval(7200), end: now.addingTimeInterval(10_800))
        #expect(!vm.joinWindowOpen(at: now))
    }

    @Test("a pending_reschedule booking inside the window shows Join but not enabled")
    func pendingRescheduleIsDisabled() async {
        let vm = await loadedModel(
            status: "pending_reschedule",
            start: now.addingTimeInterval(1800),
            end: now.addingTimeInterval(5400)
        )
        #expect(vm.showsJoinCard)
        #expect(!vm.joinWindowOpen(at: now))
    }

    @Test("a completed booking past the first-join edge rejoins only when the server says can_join")
    func completedReconnectTier() async {
        let start = now.addingTimeInterval(-7200)
        let end = now.addingTimeInterval(-1800)
        let allowed = await loadedModel(status: "completed", start: start, end: end, canJoin: "true")
        #expect(allowed.joinWindowOpen(at: now))
        let unknown = await loadedModel(status: "completed", start: start, end: end, canJoin: "null")
        #expect(!unknown.joinWindowOpen(at: now))
    }

    @Test("a pending_approval booking shows the waiting banner, not the Join card")
    func pendingApprovalHidesJoinCard() async {
        let vm = await loadedModel(
            status: "pending_approval",
            start: now.addingTimeInterval(1800),
            end: now.addingTimeInterval(5400)
        )
        #expect(!vm.showsJoinCard)
        #expect(!vm.joinWindowOpen(at: now))
    }

    @Test("before a detail has loaded the window is closed")
    func joinClosedBeforeLoad() {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: Fixtures.detailJSON()))
        #expect(!vm.joinWindowOpen(at: now))
    }

    // MARK: Add to Calendar (G-06-1-summary-calendar)

    @Test("a confirmed future booking offers Add to Calendar with the expert's name in the title")
    func confirmedFutureOffersCalendar() async {
        let start = now.addingTimeInterval(1800)
        let end = now.addingTimeInterval(5400)
        let vm = await loadedModel(status: "confirmed", start: start, end: end)
        #expect(vm.showsAddToCalendar(at: now))
        #expect(
            vm.calendarEvent == BookingCalendarPayload(
                title: "ClickMe \u{00B7} Free chat with Ada Lovelace",
                notes: "In-App Voice",
                startDate: start,
                endDate: end
            )
        )
    }

    @Test("before any load there is no calendar event and no button")
    func calendarClosedBeforeLoad() {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: detailAPI(body: Fixtures.detailJSON()))
        #expect(vm.calendarEvent == nil)
        #expect(!vm.showsAddToCalendar(at: now))
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

    // MARK: Failed refetch after a 2xx (WR-01)

    /// First detail GET returns the expert's proposal, every later one a 500, except
    /// the third when `thirdGetBody` is given. Both answer POSTs succeed. Anything
    /// else is a 404.
    private func failingRefetchAPI(thirdGetBody: Data? = nil) -> ClickMeAPI {
        let path = detailPath
        let pending = pendingDetail(initiatedBy: "expert")
        return APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if request.httpMethod == "POST",
               requestPath.hasSuffix("/accept-reschedule") || requestPath.hasSuffix("/decline-reschedule") {
                return Fixtures.response(for: request, body: Fixtures.successMessage)
            }
            if request.httpMethod == "GET", requestPath.hasSuffix(path) {
                let detailGets = MockURLProtocol.recordedRequests.filter {
                    $0.httpMethod == "GET" && $0.url?.path.hasSuffix(path) == true
                }
                if detailGets.count == 1 {
                    return Fixtures.response(for: request, body: pending)
                }
                if detailGets.count == 3, let thirdGetBody {
                    return Fixtures.response(for: request, body: thirdGetBody)
                }
                return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
    }

    private func detailGetCount() -> Int {
        let path = detailPath
        return MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "GET" && $0.url?.path.hasSuffix(path) == true
        }.count
    }

    private func postCount(suffix: String) -> Int {
        MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "POST" && $0.url?.path.hasSuffix(suffix) == true
        }.count
    }

    @Test("accept whose follow-up detail GETs return 500 clears the proposal and moves to the new time")
    func acceptWithFailedRefetchClearsProposal() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: failingRefetchAPI())
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()
        #expect(vm.pendingProposal != nil)
        let proposedStart = Fixtures.defaultStart.addingTimeInterval(86_400)

        await vm.responder.accept()

        #expect(postCount(suffix: "/accept-reschedule") == 1)
        // The refetch and its single retry both ran and both failed (WR-08).
        #expect(detailGetCount() == 3)
        #expect(vm.pendingProposal == nil)
        #expect(vm.reschedule == nil)
        // WR-08: the old time and the pending status must not outlive the accept.
        #expect(vm.bookingStatus == .confirmed)
        #expect(vm.statusRaw == "confirmed")
        #expect(abs((vm.startTime ?? .distantPast).timeIntervalSince(proposedStart)) < 1)
        #expect(abs((vm.endTime ?? .distantPast).timeIntervalSince(proposedStart.addingTimeInterval(3600))) < 1)
        #expect(vm.canJoin == nil)
        #expect(vm.state == .loaded)
        #expect(vm.responder.apiError == nil)
        #expect(vm.responder.isSubmitting == false)
    }

    @Test("decline whose follow-up detail GETs return 500 clears the proposal and the pending status")
    func declineWithFailedRefetchClearsProposal() async {
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: failingRefetchAPI())
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()
        #expect(vm.pendingProposal != nil)
        let originalStart = vm.startTime

        await vm.responder.decline(reason: "No")

        #expect(postCount(suffix: "/decline-reschedule") == 1)
        #expect(detailGetCount() == 3)
        #expect(vm.pendingProposal == nil)
        #expect(vm.reschedule == nil)
        // WR-08: no "Pending reschedule" pill for a proposal the server dropped; the time is unchanged.
        #expect(vm.bookingStatus != .pendingReschedule)
        #expect(vm.startTime == originalStart)
        #expect(vm.state == .loaded)
        #expect(vm.responder.apiError == nil)
        #expect(vm.responder.isSubmitting == false)
    }

    @Test("a failed refetch is retried once, and the retry's answer replaces the local guess")
    func failedRefetchIsRetriedOnce() async {
        // The decline restored a status other than the `confirmed` the screen assumed.
        let restored = Fixtures.detailJSON(status: "pending_approval")
        let vm = UpcomingBookingViewModel(bookingId: bookingUUID, api: failingRefetchAPI(thirdGetBody: restored))
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()

        await vm.responder.decline(reason: "No")

        #expect(detailGetCount() == 3)
        #expect(vm.bookingStatus == .pendingApproval)
        #expect(vm.statusRaw == "pending_approval")
        #expect(vm.pendingProposal == nil)
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
