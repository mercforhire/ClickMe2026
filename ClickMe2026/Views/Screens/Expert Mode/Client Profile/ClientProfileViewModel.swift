//
//  ClientProfileViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ClientProfileViewModel: ObservableObject {


    // MARK: State

    /// The client whose profile we're viewing. Required — the view can't
    /// render without an identifier to fetch against.
    let clientId: UUID

    @Published var loadState: LoadState = .idle
    @Published var profile: ExpertClientProfileData?
    @Published var bookingHistory: [ClientBookingHistory] = []

    // MARK: Animation

    @Published var glowPulse: Bool = false

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(clientId: UUID, api: ClickMeAPI = .shared) {
        self.clientId = clientId
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        clientId: UUID = UUID(),
        profile: ExpertClientProfileData? = ClientProfileViewModel.sampleProfile,
        bookingHistory: [ClientBookingHistory] = ClientProfileViewModel.sampleBookingHistory
    ) -> ClientProfileViewModel {
        let vm = ClientProfileViewModel(clientId: clientId)
        vm.profile = profile
        vm.bookingHistory = bookingHistory
        vm.loadState = .loaded
        return vm
    }

    // MARK: Actions

    func startGlowPulse() {
        glowPulse = true
    }

    // MARK: - Load

    /// Fetches the client profile + this expert's booking history filtered
    /// to just this client. Idempotent — skips when already loaded.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            // Sequential fetches — parallel `async let` decoding trips
            // Swift 6's main-actor-isolated Decodable check.
            let profileResponse = try await api.getClientProfile(id: clientId)
            profile = profileResponse.data

            let bookingsResponse = try await api.getExpertBookings(page: 1, limit: 50)
            bookingHistory = bookingsResponse.data.bookings
                .filter { $0.client.id == clientId }
                .sorted { $0.session.startTime > $1.session.startTime }
                .map(Self.mapBooking(from:))

            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: - Mapping

    private static func mapBooking(from item: ExpertBookingItem) -> ClientBookingHistory {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return ClientBookingHistory(
            title: item.session.topic ?? "Session",
            status: mapStatus(from: item.status.code),
            date: dateFormatter.string(from: item.session.startTime),
            amount: 0 // ExpertBookingItem doesn't expose an amount; leave as 0.
        )
    }

    private static func mapStatus(from code: BookingStatus) -> BookingHistoryStatus {
        switch code {
        case .pendingApproval, .confirmed, .pendingReschedule, .inProgress:
            return .upcoming
        case .completed:
            return .completed
        case .cancelled, .declined, .missed, .expired:
            return .cancelled
        }
    }

    // MARK: - Error mapping


    // MARK: - Preview data

    static let sampleProfile = ExpertClientProfileData(
        id: UUID(),
        personalDetails: .init(
            firstName: "Sophia",
            lastName: "Carter",
            fullName: "Sophia Carter",
            avatarUrl: "https://randomuser.me/api/portraits/women/44.jpg",
            bio: "Passionate about connecting with experts and learning new skills."
        ),
        location: .init(
            city: "San Francisco",
            stateProvince: "CA",
            country: "USA",
            timezone: "(GMT-08:00) Pacific Time"
        ),
        languages: ["English", "Spanish"],
        memberSince: Calendar.current.date(byAdding: .month, value: -14, to: Date()),
        relationship: .init(
            totalSessions: 3,
            firstSessionDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            lastSessionDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())
        )
    )

    static let sampleBookingHistory: [ClientBookingHistory] = [
        ClientBookingHistory(title: "SEO Audit Review", status: .upcoming, date: "June 5, 2024", amount: 0),
        ClientBookingHistory(title: "Digital Marketing Strategy", status: .completed, date: "May 12, 2024", amount: 0),
        ClientBookingHistory(title: "Brand Growth Session", status: .completed, date: "Apr 3, 2024", amount: 0),
    ]
}
