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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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
    @Published var joinLink: String
    @Published var preparationNote: String

    // MARK: Load state

    @Published var state: LoadState

    // MARK: Dependencies

    private let api: ClickMeAPI

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
        self.joinLink = ""
        self.preparationNote = ""
        self.state = .idle
        self.api = api
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
        joinLink: String = "skype.com/j/clickme-sarah",
        preparationNote: String = "Please have your current product roadmap and user persona documents ready. We'll be diving deep into the Q4 objectives and identifying key friction points in the user journey."
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
        vm.joinLink = joinLink
        vm.preparationNote = preparationNote
        vm.state = .loaded
        return vm
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
        joinLink = data.joinLink ?? Self.fallbackJoinLabel(for: data.meetingType)
        preparationNote = data.clientNotes ?? ""
    }

    // MARK: - Formatting helpers

    private static func priceLabel(topic: ClientBookingDetail.Topic) -> String {
        if topic.isFree { return "Free" }
        if let amount = topic.price?.amount, let currency = topic.price?.currency {
            return "\(currency) \(amount / 100)"
        }
        return "—"
    }

    private static func fallbackJoinLabel(for type: MeetingType) -> String {
        switch type {
        case .inAppVoice: return "In-app voice call"
        case .skypeZoom:  return "Skype / Zoom"
        }
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
