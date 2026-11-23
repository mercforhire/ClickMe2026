//
//  UpcomingBookingViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class UpcomingBookingViewModel: ObservableObject {


    // MARK: Identity

    let bookingId: UUID

    // MARK: Loaded content

    @Published var bookingIDLabel: String
    @Published var expertName: String
    @Published var expertTitle: String
    @Published var expertImageURL: String
    @Published var topic: String
    @Published var consultationFee: String
    @Published var date: String
    @Published var timeRange: String
    @Published var expertTimezone: String?
    @Published var paymentStatus: String?
    @Published var meetingType: MeetingType
    @Published var joinLink: String
    @Published var preparationNote: String
    /// Booking status parsed from `ClientBookingDetail.status`. Drives
    /// `isPendingExpertApproval` — used by the view to hide the Join
    /// card and surface a "Waiting for expert to accept" banner instead
    /// while the request is still awaiting the expert's decision.
    @Published var bookingStatus: BookingStatus
    /// The server's status string, kept only so `statusPill` can humanize
    /// `.unknown`. It never decides the text or tone of a known case.
    @Published var statusRaw: String
    /// Pending reschedule proposal from `ClientBookingDetail.reschedule`, or
    /// `nil` when the booking has none. Read through `pendingProposal`.
    @Published var reschedule: RescheduleProposal?
    /// End of the Stripe authorization window. Only decides whether accepting a
    /// proposal needs the payment-conversion disclosure.
    @Published var authorizationExpiresAt: Date?
    /// The booking's current start, the FROM side of the response card and the
    /// join window's opening edge.
    @Published var startTime: Date?
    /// The booking's scheduled end. Feeds the join window and the Cancel rule.
    @Published var endTime: Date?
    /// The expert's profile id, the peer of the call.
    @Published var expertId: UUID?
    /// The server's `can_join` for this booking. Only the reconnect tier of the
    /// join window reads it.
    @Published var canJoin: Bool?

    // MARK: Reschedule response

    /// Answers an expert-proposed time (BOOK-06). Its `refetch` is this model's
    /// silent `refresh()`, so a successful accept or decline updates the screen
    /// in place with no loading spinner (D-03). `onResolved` moves the screen to
    /// the state the server now holds first, so the card, the time and the status
    /// are right even when that refresh fails (WR-01, WR-08).
    let responder: RescheduleResponder

    // MARK: Load state

    @Published var state: LoadState

    /// Newest-refetch gate for `forceLoad()`. A `booking.update` during a
    /// pull-to-refresh (or two events in a row) starts overlapping fetches;
    /// only the most recently started one may write the screen (BOOK-18).
    private var reloads = ReloadGeneration()

    /// Wait before the one retry of the refresh that follows an accepted or
    /// declined reschedule when its first attempt failed (WR-08). Tests shorten it.
    var refetchRetryDelay: Duration = .seconds(2)

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Realtime

    /// Auto-cancels on VM deallocation.
    private var bookingUpdateSubscription: RealtimeSubscription?

    // MARK: Inits

    /// Runtime init — starts empty and hydrates via `GET /client/bookings/:id`
    /// on view appear.
    init(bookingId: UUID, api: ClickMeAPI = .shared) {
        self.bookingId = bookingId
        self.bookingIDLabel = BookingShortID.short(bookingId)
        self.expertName = ""
        self.expertTitle = ""
        self.expertImageURL = ""
        self.topic = ""
        self.consultationFee = ""
        self.date = ""
        self.timeRange = ""
        self.expertTimezone = nil
        self.paymentStatus = nil
        self.meetingType = .inAppVoice
        self.joinLink = ""
        self.preparationNote = ""
        self.bookingStatus = .confirmed
        self.statusRaw = ""
        self.reschedule = nil
        self.authorizationExpiresAt = nil
        self.startTime = nil
        self.endTime = nil
        self.expertId = nil
        self.canJoin = nil
        self.state = .idle
        self.api = api
        self.responder = RescheduleResponder(bookingId: bookingId, api: api)

        // Any live change to this specific booking re-hits the detail
        // endpoint so status / times / meeting-type stay accurate while
        // the screen is on-view.
        let targetId = bookingId
        self.bookingUpdateSubscription = RealtimeService.shared.onBookingUpdate { [weak self] event in
            guard event.bookingId == targetId else { return }
            Task { @MainActor in await self?.refresh() }
        }
        responder.refetch = { [weak self] in await self?.refreshAfterResolution() }
        responder.onResolved = { [weak self] resolution in self?.applyResolution(resolution) }
    }

    /// Preview seam — pre-installs display strings so the canvas can render
    /// without hitting the network.
    static func previewSeed(
        bookingId: UUID = UUID(),
        bookingIDLabel: String = "#CM-98231",
        expertName: String = "Sarah Chen",
        expertTitle: String = "Senior UX Architect",
        expertImageURL: String = sampleImageURL,
        topic: String = "Advanced Product Strategy Review",
        consultationFee: String = "USD 150",
        date: String = "Oct 15, 2024",
        timeRange: String = "10:00 AM - 11:00 AM",
        expertTimezone: String? = "America/Toronto",
        paymentStatus: String? = "held",
        meetingType: MeetingType = .inAppVoice,
        joinLink: String = "",
        preparationNote: String = "Please have your current product roadmap and user persona documents ready. We'll be diving deep into the Q4 objectives and identifying key friction points in the user journey.",
        bookingStatus: BookingStatus = .confirmed,
        reschedule: RescheduleProposal? = nil,
        authorizationExpiresAt: Date? = nil,
        startTime: Date? = Date().addingTimeInterval(3600),
        endTime: Date? = nil,
        expertId: UUID? = UUID(),
        canJoin: Bool? = nil
    ) -> UpcomingBookingViewModel {
        let vm = UpcomingBookingViewModel(bookingId: bookingId)
        vm.bookingIDLabel = bookingIDLabel
        vm.expertName = expertName
        vm.expertTitle = expertTitle
        vm.expertImageURL = expertImageURL
        vm.topic = topic
        vm.consultationFee = consultationFee
        vm.date = date
        vm.timeRange = timeRange
        vm.expertTimezone = expertTimezone
        vm.paymentStatus = paymentStatus
        vm.meetingType = meetingType
        vm.joinLink = joinLink
        vm.preparationNote = preparationNote
        vm.bookingStatus = bookingStatus
        vm.statusRaw = bookingStatus.rawValue
        vm.reschedule = reschedule
        vm.authorizationExpiresAt = authorizationExpiresAt
        vm.startTime = startTime
        vm.endTime = endTime ?? startTime?.addingTimeInterval(3600)
        vm.expertId = expertId
        vm.canJoin = canJoin
        vm.state = .loaded
        return vm
    }

    /// True when the booking still needs the expert's decision. Used by
    /// the view to swap the Join card for a waiting banner.
    var isPendingExpertApproval: Bool {
        bookingStatus == .pendingApproval
    }

    /// The status pill for the details screen (BOOK-09). Decided by the decoded
    /// `bookingStatus`; `statusRaw` only humanizes `.unknown`. Between a load
    /// and the next refetch it keeps its previous value (D-03).
    var statusPill: BookingStatusPill {
        BookingStatusPill.make(status: bookingStatus, rawStatus: statusRaw)
    }

    // MARK: Join

    /// Whether the details screen renders the Join card at all. Every status
    /// but `pending_approval` does; `joinWindowOpen(at:)` decides whether the
    /// button is enabled (Phase 2 D-07, 02-14).
    var showsJoinCard: Bool {
        JoinWindow.showsJoinButton(status: bookingStatus)
    }

    /// True when JOIN CALL and Open in {provider} are enabled at `now`. A display
    /// gate only: the server keeps the final say on `POST /bookings/:id/join`.
    func joinWindowOpen(at now: Date) -> Bool {
        guard let startTime, let endTime else { return false }
        return JoinWindow.isOpen(
            status: bookingStatus,
            start: startTime,
            end: endTime,
            now: now,
            serverCanJoin: canJoin
        )
    }

    // MARK: Add to Calendar (G-06-1-summary-calendar)

    /// The event Add to Calendar puts on the client's calendar, titled
    /// `ClickMe · {topic} with {expert name}`, with the meeting type and the
    /// client's own note as notes. `nil` until both times are known.
    var calendarEvent: BookingCalendarPayload? {
        guard let startTime, let endTime else { return nil }
        return BookingCalendarEventContent.clientEvent(
            topic: topic,
            expertName: expertName,
            start: startTime,
            end: endTime,
            meetingType: meetingType,
            clientMessage: preparationNote
        )
    }

    /// True when the Add to Calendar button is offered at `now`: a booked status
    /// whose end is still ahead. A display gate only; the 60 s timeline passes
    /// `now` so the button goes when the session ends.
    func showsAddToCalendar(at now: Date) -> Bool {
        guard calendarEvent != nil else { return false }
        return BookingCalendarEventContent.isOffered(status: bookingStatus, end: endTime, now: now)
    }

    /// Starts the call for this booking through `CallCenter`, the one path that
    /// reports `POST /join` and `/end`, whichever screen opened the details
    /// (CALL-03). Also the path a Skype/Zoom booking takes (D-10, CALL-08).
    func startCall() {
        guard let expertId, let startTime, let endTime else { return }
        CallCenter.shared.startCall(
            bookingId: bookingId,
            peerId: expertId,
            peerName: expertName,
            peerImageURL: expertImageURL,
            topic: topic,
            scheduledStart: startTime,
            scheduledEnd: endTime,
            meetingType: meetingType,
            isRejoin: bookingStatus == .completed
        )
    }

    /// The proposal to answer, only while the booking is `pending_reschedule`.
    var pendingProposal: RescheduleProposal? {
        bookingStatus == .pendingReschedule ? reschedule : nil
    }

    /// Body of the "Accept the proposed reschedule?" dialog.
    var acceptDialogMessage: String {
        RescheduleResponder.acceptDialogMessage(
            proposal: reschedule,
            authorizationExpiresAt: authorizationExpiresAt,
            now: Date()
        )
    }

    // MARK: - Load

    /// First appearance loads normally; later appearances (for example coming
    /// back from Reschedule) refetch silently so the screen shows the server's
    /// current state without blanking.
    func appeared() async {
        if case .loaded = state {
            await refresh()
        } else {
            await load()
        }
    }

    /// Re-fetches without leaving `.loaded`, so the content stays on screen
    /// while it updates. A failure while loaded keeps the last good content.
    /// Overlapping calls keep only the newest response. When not yet loaded
    /// this runs a forced load instead, so the newest call settles `state`.
    func refresh() async {
        _ = await refreshOnce()
    }

    /// One silent refresh. Returns `false` only when the detail GET failed (the
    /// last good screen is kept), so a caller can try again. A superseded call
    /// returns `true`: the newer call settles the screen.
    private func refreshOnce() async -> Bool {
        guard case .loaded = state else {
            await forceLoad()
            return true
        }
        let token = reloads.begin()
        do {
            let response = try await api.getClientBookingDetail(id: bookingId)
            guard reloads.isCurrent(token) else { return true }
            apply(response.data)
            return true
        } catch {
            // Intentionally swallowed: keep the last known good screen.
            return false
        }
    }

    /// The refresh after a 2xx accept or decline: one retry after a short delay,
    /// because `onResolved` has only guessed the new state and nothing else
    /// repairs it until a socket event or a reopen (WR-08).
    private func refreshAfterResolution() async {
        if await refreshOnce() { return }
        try? await Task.sleep(for: refetchRetryDelay)
        guard !Task.isCancelled else { return }
        _ = await refreshOnce()
    }

    /// Moves the screen to what the server now holds after a 2xx accept or
    /// decline, without waiting for the refetch (WR-01, WR-08).
    ///
    /// Accept: the proposed time becomes the booking's time and the status is
    /// `confirmed` (`acceptReschedule` in the backend). Decline: the backend
    /// restores `reschedule_prev_status` and returns it as `data.status`, so that
    /// status is shown, never a guessed `confirmed` (T-03-23). A status this
    /// build does not know becomes `.unknown`, as on load. When the body carried
    /// no status the status and `canJoin` stay as they were until the refetch.
    private func applyResolution(_ resolution: RescheduleResponder.Resolution) {
        switch resolution {
        case .accepted:
            if let proposal = reschedule {
                startTime = proposal.proposedStart
                endTime = proposal.proposedEnd
                date = Self.dateString(proposal.proposedStart)
                timeRange = Self.timeRangeString(from: proposal.proposedStart, to: proposal.proposedEnd)
            }
            bookingStatus = .confirmed
            statusRaw = BookingStatus.confirmed.rawValue
            canJoin = nil
        case .declined(let restoredStatus):
            if let restoredStatus {
                bookingStatus = BookingStatus(rawValue: restoredStatus) ?? .unknown
                statusRaw = restoredStatus
                canJoin = nil
            }
        }
        reschedule = nil
    }

    /// Idempotent — skips when already loaded so it doesn't clobber the
    /// preview seed.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    /// Fetches `GET /client/bookings/:id` and hydrates the display fields.
    /// Overlapping calls keep only the newest response: a call superseded by
    /// a later one writes neither data nor load state, and the newest call
    /// always settles `state`, so the screen never shows a stale snapshot or
    /// a stranded spinner.
    private func forceLoad() async {
        let token = reloads.begin()
        state = .loading
        do {
            let response = try await api.getClientBookingDetail(id: bookingId)
            guard reloads.isCurrent(token) else { return }
            apply(response.data)
            state = .loaded
        } catch {
            guard reloads.isCurrent(token) else { return }
            state = .failed(Self.message(for: error))
        }
    }

    // MARK: - Mapping

    private func apply(_ data: ClientBookingDetail) {
        bookingIDLabel = BookingShortID.short(data.bookingId)
        expertName = data.expert.fullName ?? "Expert"
        expertTitle = data.expert.title ?? ""
        expertImageURL = data.expert.avatarUrl ?? ""
        topic = data.topic.title
        consultationFee = Self.priceLabel(topic: data.topic)
        date = Self.dateString(data.startTime)
        timeRange = Self.timeRangeString(from: data.startTime, to: data.endTime)
        expertTimezone = data.expertTimezone
        paymentStatus = data.paymentStatus
        meetingType = data.meetingType
        // In-app bookings have no link — the join card renders just a "JOIN
        // CALL" button in that case, so an empty string here is fine.
        joinLink = data.joinLink ?? ""
        preparationNote = data.clientNotes ?? ""
        // A status this build doesn't know stays `.unknown` (BOOK-18), the
        // same rule `BookingStatus.init(from:)` applies, so a new server
        // state is never shown as a confirmed booking.
        bookingStatus = BookingStatus(rawValue: data.status) ?? .unknown
        statusRaw = data.status
        reschedule = data.reschedule
        authorizationExpiresAt = data.authorizationExpiresAt
        startTime = data.startTime
        endTime = data.endTime
        expertId = data.expert.id
        canJoin = data.canJoin
    }

    // MARK: - Formatting helpers

    private static func priceLabel(topic: ClientBookingDetail.Topic) -> String {
        if topic.isFree { return "Free" }
        if let amount = topic.price?.amount, let currency = topic.price?.currency {
            return Money.format(minorUnits: amount, currency: currency)
        }
        return "—"
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private static func timeRangeString(from start: Date, to end: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: Defaults

    static let sampleImageURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuD-ENFxFRN4Pff6e-HrtvXOkZVAENbGDLU3aUuz12EcHXP9HvoTM_zvDWdf4LxyQddQN21Q8YpuIhWRqQGfZh0dpmdR2Ak2nVLOJHYjJ4VnnqUvKZFfnVEqpCh3EEVR4_rFIPxEq0aLuXAl3WZJV77ezuINaUGUNuF8-InR2eBriYCBRpRRcjNis7k0CYuPQqz5rZxoz0bH2GKqD_P6sPF4dRp61iOAwQM6dQLAKVg_5vEwhuvj6qfMbzkar2rx3hF-NkU5NPuUI2g"
}
