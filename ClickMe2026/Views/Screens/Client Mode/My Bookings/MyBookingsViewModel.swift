//
//  MyBookingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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

    /// Retains our `booking.update` subscription. Dropped on `deinit` —
    /// see `RealtimeService.RealtimeSubscription`. Silent-refreshes the
    /// list whenever any booking's status changes server-side, so a
    /// server-driven `BOOKING_COMPLETED` (fired ~15 min after `end_time`
    /// per `docs/ios/CALL-END-SEMANTICS.md`) moves the row from
    /// Upcoming to Past without requiring a manual pull-to-refresh.
    private var bookingUpdateSubscription: RealtimeSubscription?

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

        // Any server-side status transition (BOOKING_COMPLETED, cancel,
        // decline, etc.) fires a `booking.update` event. Silent-refresh
        // both lists so the affected row lands in the right bucket.
        // The list VMs previously only re-fetched on appear or pull-to-
        // refresh, which meant a session that server-completed while
        // this screen was mounted sat in the Upcoming list until the
        // user manually scrolled.
        self.bookingUpdateSubscription = RealtimeService.shared.onBookingUpdate { [weak self] _ in
            Task { @MainActor in await self?.silentReload() }
        }
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

    /// Fetches page 1 of the bookings list. On re-appearance (already
    /// `.loaded`) delegates to `silentReload()` so a freshly-placed booking
    /// shows up without blanking the list back to the loading spinner.
    func load() async {
        if case .loaded = state {
            await silentReload()
            return
        }
        await forceLoad()
    }

    /// Pull-to-refresh handler.
    func reload() async {
        await forceLoad()
    }

    /// Re-fetches in the background without transitioning to `.loading`, so
    /// the current list stays on screen while we update. Failure is silent —
    /// a flaky network on re-appear shouldn't wipe the last known good view.
    func silentReload() async {
        do {
            let upResponse = try await api.getClientBookings(type: .upcoming)
            let pastResponse = try await api.getClientBookings(type: .past)

            // Rejoinable completeds live in the past payload (server
            // flipped status on early hang-up), but their scheduled
            // end hasn't passed — surface them under Upcoming so the
            // user can rejoin.
            let rejoinable = pastResponse.data.bookings.filter(Self.isRejoinableCompleted)
            let upcomingRaw = upResponse.data.bookings + rejoinable

            self.upcomingBookings = upcomingRaw
                .sorted { $0.startTime < $1.startTime }
                .map(Self.mapUpcoming)

            self.pastBookings = pastResponse.data.bookings
                .sorted { $0.startTime > $1.startTime }
                .compactMap(Self.mapPastIfApplicable)
        } catch {
            // Intentionally swallowed — keep the last-known-good list on screen.
        }
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

            let rejoinable = pastResponse.data.bookings.filter(Self.isRejoinableCompleted)
            let upcomingRaw = upResponse.data.bookings + rejoinable

            self.upcomingBookings = upcomingRaw
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
    ///
    /// **Completed-but-not-past exclusion**: if the session was ended
    /// early (status flipped to `.completed`) but its scheduled
    /// `endTime` hasn't passed yet, we treat it as *still upcoming*
    /// so the user can rejoin. `mapPastIfApplicable` returns nil in
    /// that case; the caller promotes those rows into the upcoming
    /// list via `mapUpcoming`.
    private static func mapPastIfApplicable(_ item: ClientBookingItem) -> PastBooking? {
        guard let status = BookingStatus(rawValue: item.status) else { return nil }
        let uiStatus: PastBookingStatus
        switch status {
        case .completed:
            if item.endTime > Date() { return nil }  // still rejoinable
            uiStatus = .completed
        case .cancelled, .declined:   uiStatus = .cancelled
        case .missed, .expired:       uiStatus = .missed
        default:                      return nil
        }
        return mapPast(item, status: uiStatus)
    }

    /// Filter matching `mapPastIfApplicable`'s "still-rejoinable"
    /// exclusion — the caller uses this to pluck those rows out of
    /// the past payload and promote them into the upcoming list.
    private static func isRejoinableCompleted(_ item: ClientBookingItem) -> Bool {
        guard BookingStatus(rawValue: item.status) == .completed else { return false }
        return item.endTime > Date()
    }

    // MARK: - Mapping

    private static func mapUpcoming(_ item: ClientBookingItem) -> UpcomingBooking {
        // Unknown-status rows shouldn't get here — the caller filters to
        // the "upcoming" bucket first — but fall back to `confirmed` to
        // keep the card renderable rather than crashing.
        let status = BookingStatus(rawValue: item.status) ?? .confirmed
        return UpcomingBooking(
            id: item.bookingId,
            expertId: item.expert.id,
            expertName: item.expert.fullName ?? "Expert",
            topic: item.topic ?? "Consultation",
            date: dateString(item.startTime),
            timeRange: timeRangeString(from: item.startTime, to: item.endTime),
            imageURL: item.expert.avatarUrl ?? "",
            startTime: item.startTime,
            endTime: item.endTime,
            status: status,
            meetingType: item.meetingType,
            privateNotePreview: item.privateNotePreview,
            reschedule: item.reschedule
        )
    }

    private static func mapPast(_ item: ClientBookingItem, status: PastBookingStatus) -> PastBooking {
        PastBooking(
            id: item.bookingId,
            expertName: item.expert.fullName ?? "Expert",
            topic: item.topic ?? "Consultation",
            date: dateString(item.startTime),
            timeRange: timeRangeString(from: item.startTime, to: item.endTime),
            status: status,
            privateNotePreview: item.privateNotePreview
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
        UpcomingBooking(id: UUID(), expertId: UUID(), expertName: "Sarah Chen", topic: "Advanced Product Strategy Review",
                        date: "Oct 15, 2024", timeRange: "10:00 AM - 11:00 AM",
                        imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
                        startTime: Date().addingTimeInterval(30 * 60),
                        endTime: Date().addingTimeInterval(90 * 60),
                        status: .confirmed, meetingType: .inAppVoice,
                        privateNotePreview: "Prep: ask about pricing tiers vs current plan.",
                        reschedule: nil),
        // Second sample — pending expert approval. Renders the awaiting banner.
        UpcomingBooking(id: UUID(), expertId: UUID(), expertName: "David Miller", topic: "Machine Learning Consultation",
                        date: "Oct 18, 2024", timeRange: "2:30 PM - 3:30 PM",
                        imageURL: "https://randomuser.me/api/portraits/men/32.jpg",
                        startTime: Date().addingTimeInterval(3 * 3600),
                        endTime: Date().addingTimeInterval(4 * 3600),
                        status: .pendingApproval, meetingType: .inAppVoice,
                        privateNotePreview: nil,
                        reschedule: nil),
        UpcomingBooking(id: UUID(), expertId: UUID(), expertName: "Emily Davis", topic: "UX Research Plan Feedback",
                        date: "Oct 22, 2024", timeRange: "9:00 AM - 10:00 AM",
                        imageURL: "https://randomuser.me/api/portraits/women/68.jpg",
                        startTime: Date().addingTimeInterval(7 * 24 * 3600),
                        endTime: Date().addingTimeInterval(7 * 24 * 3600 + 3600),
                        status: .confirmed, meetingType: .skypeZoom,
                        privateNotePreview: nil,
                        reschedule: nil),
    ]

    static let samplePast: [PastBooking] = [
        PastBooking(id: UUID(), expertName: "Sarah Johnson", topic: "Advanced Marketing Strategy",
                    date: "Oct 25, 2024", timeRange: "2:00 PM - 3:00 PM", status: .completed,
                    privateNotePreview: "Loved the funnel breakdown. Follow up on the retargeting playbook."),
        PastBooking(id: UUID(), expertName: "David Miller", topic: "Product Launch Consultation",
                    date: "Oct 20, 2024", timeRange: "10:00 AM - 11:00 AM", status: .cancelled,
                    privateNotePreview: nil),
        PastBooking(id: UUID(), expertName: "Emily Roberts", topic: "User Experience Audit",
                    date: "Oct 15, 2024", timeRange: "4:00 PM - 5:30 PM", status: .missed,
                    privateNotePreview: nil),
        PastBooking(id: UUID(), expertName: "Michael Brown", topic: "Financial Planning Session",
                    date: "Oct 10, 2024", timeRange: "1:00 PM - 2:00 PM", status: .completed,
                    privateNotePreview: nil),
    ]
}
