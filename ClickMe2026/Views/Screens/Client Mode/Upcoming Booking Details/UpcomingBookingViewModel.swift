//
//  UpcomingBookingViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
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

    // MARK: Load state

    @Published var state: LoadState

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
        self.bookingIDLabel = "#" + bookingId.uuidString.prefix(8).uppercased()
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
        self.state = .idle
        self.api = api

        // Any live change to this specific booking re-hits the detail
        // endpoint so status / times / meeting-type stay accurate while
        // the screen is on-view.
        let targetId = bookingId
        self.bookingUpdateSubscription = RealtimeService.shared.onBookingUpdate { [weak self] event in
            guard event.bookingId == targetId else { return }
            Task { @MainActor in await self?.reload() }
        }
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
        bookingStatus: BookingStatus = .confirmed
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
        vm.state = .loaded
        return vm
    }

    /// True when the booking still needs the expert's decision. Used by
    /// the view to swap the Join card for a waiting banner.
    var isPendingExpertApproval: Bool {
        bookingStatus == .pendingApproval
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded so it doesn't clobber the
    /// preview seed.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        state = .loading
        do {
            let response = try await api.getClientBookingDetail(id: bookingId)
            apply(response.data)
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    // MARK: - Mapping

    private func apply(_ data: ClientBookingDetail) {
        bookingIDLabel = "#" + data.bookingId.uuidString.prefix(8).uppercased()
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
        // Unknown-status rows shouldn't hit this view — the caller
        // narrows to the upcoming bucket first — but fall back to
        // `confirmed` so we render normally rather than mis-showing the
        // waiting banner.
        bookingStatus = BookingStatus(rawValue: data.status) ?? .confirmed
    }

    // MARK: - Formatting helpers

    private static func priceLabel(topic: ClientBookingDetail.Topic) -> String {
        if topic.isFree { return "Free" }
        if let amount = topic.price?.amount, let currency = topic.price?.currency {
            return "\(currency) \(amount / 100)"
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
