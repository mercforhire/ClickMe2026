//
//  MyBookingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class MyBookingsViewModel: ObservableObject {


    // MARK: View state
    @Published var selectedTab: Int
    @Published var glowPulse: Bool

    // MARK: Data
    @Published var upcomingBookings: [UpcomingBooking]
    @Published var pastBookings: [PastBooking]
    @Published var state: LoadState

    // MARK: Dependencies
    private let api: ClickMeAPI

    // MARK: Inits

    /// Runtime init — starts empty; `.task { load() }` populates from
    /// `GET /client/bookings`.
    init(api: ClickMeAPI = .shared) {
        self.selectedTab = 0
        self.glowPulse = false
        self.upcomingBookings = []
        self.pastBookings = []
        self.state = .idle
        self.api = api
    }

    /// Preview seam — installs canned data and marks state as `.loaded` so
    /// the UI renders without hitting the network. Prefer this factory over
    /// a second init to avoid overload ambiguity with the runtime init.
    static func previewSeed(
        selectedTab: Int = 0,
        upcomingBookings: [UpcomingBooking] = sampleUpcoming,
        pastBookings: [PastBooking] = samplePast
    ) -> MyBookingsViewModel {
        let vm = MyBookingsViewModel()
        vm.selectedTab = selectedTab
        vm.upcomingBookings = upcomingBookings
        vm.pastBookings = pastBookings
        vm.state = .loaded
        return vm
    }

    // MARK: - Load

    /// Fetches page 1 of the bookings list. Idempotent — skips if already
    /// loaded (avoids clobbering the preview seed).
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    /// Pull-to-refresh handler.
    func reload() async {
        await forceLoad()
    }

    /// The server already partitions upcoming/past via the required `type`
    /// query param, so we make two calls sequentially. Sequential (not
    /// parallel) to avoid Sendable-conformance issues with concurrent
    /// decoding across actor boundaries — acceptable since this only fires
    /// on tab appear or pull-to-refresh.
    private func forceLoad() async {
        state = .loading
        do {
            let upResponse = try await api.getClientBookings(type: .upcoming)
            let pastResponse = try await api.getClientBookings(type: .past)

            self.upcomingBookings = upResponse.data.bookings
                .sorted { $0.startTime < $1.startTime }
                .map(Self.mapUpcoming)

            self.pastBookings = pastResponse.data.bookings
                .sorted { $0.startTime > $1.startTime }
                .compactMap(Self.mapPastIfApplicable)

            self.state = .loaded
        } catch {
            self.state = .failed(Self.message(for: error))
        }
    }

    /// Server-past bookings map to the 3-case UI enum:
    /// `completed → .completed`, `cancelled / declined → .cancelled`,
    /// `missed / expired → .missed`. Unknown statuses are dropped.
    private static func mapPastIfApplicable(_ item: ClientBookingItem) -> PastBooking? {
        guard let status = BookingStatus(rawValue: item.status) else { return nil }
        let uiStatus: PastBookingStatus
        switch status {
        case .completed:              uiStatus = .completed
        case .cancelled, .declined:   uiStatus = .cancelled
        case .missed, .expired:       uiStatus = .missed
        default:                      return nil
        }
        return mapPast(item, status: uiStatus)
    }

    // MARK: - Mapping

    private static func mapUpcoming(_ item: ClientBookingItem) -> UpcomingBooking {
        UpcomingBooking(
            id: item.bookingId,
            expertName: item.expert.fullName ?? "Expert",
            topic: item.topic ?? "Consultation",
            date: dateString(item.startTime),
            timeRange: timeRangeString(from: item.startTime, to: item.endTime),
            imageURL: item.expert.avatarUrl ?? "",
            startTime: item.startTime
        )
    }

    private static func mapPast(_ item: ClientBookingItem, status: PastBookingStatus) -> PastBooking {
        PastBooking(
            id: item.bookingId,
            expertName: item.expert.fullName ?? "Expert",
            topic: item.topic ?? "Consultation",
            date: dateString(item.startTime),
            timeRange: timeRangeString(from: item.startTime, to: item.endTime),
            status: status
        )
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

    // MARK: Sample data

    static let sampleUpcoming: [UpcomingBooking] = [
        // First sample starts in 30 min — inside the join window (shows button).
        UpcomingBooking(id: UUID(), expertName: "Sarah Chen", topic: "Advanced Product Strategy Review",
                        date: "Oct 15, 2024", timeRange: "10:00 AM - 11:00 AM",
                        imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
                        startTime: Date().addingTimeInterval(30 * 60)),
        UpcomingBooking(id: UUID(), expertName: "David Miller", topic: "Machine Learning Consultation",
                        date: "Oct 18, 2024", timeRange: "2:30 PM - 3:30 PM",
                        imageURL: "https://randomuser.me/api/portraits/men/32.jpg",
                        startTime: Date().addingTimeInterval(3 * 3600)),
        UpcomingBooking(id: UUID(), expertName: "Emily Davis", topic: "UX Research Plan Feedback",
                        date: "Oct 22, 2024", timeRange: "9:00 AM - 10:00 AM",
                        imageURL: "https://randomuser.me/api/portraits/women/68.jpg",
                        startTime: Date().addingTimeInterval(7 * 24 * 3600)),
    ]

    static let samplePast: [PastBooking] = [
        PastBooking(id: UUID(), expertName: "Sarah Johnson", topic: "Advanced Marketing Strategy",
                    date: "Oct 25, 2024", timeRange: "2:00 PM - 3:00 PM", status: .completed),
        PastBooking(id: UUID(), expertName: "David Miller", topic: "Product Launch Consultation",
                    date: "Oct 20, 2024", timeRange: "10:00 AM - 11:00 AM", status: .cancelled),
        PastBooking(id: UUID(), expertName: "Emily Roberts", topic: "User Experience Audit",
                    date: "Oct 15, 2024", timeRange: "4:00 PM - 5:30 PM", status: .missed),
        PastBooking(id: UUID(), expertName: "Michael Brown", topic: "Financial Planning Session",
                    date: "Oct 10, 2024", timeRange: "1:00 PM - 2:00 PM", status: .completed),
    ]
}
