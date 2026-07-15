//
//  UpcomingBookingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class UpcomingBookingsViewModel {


    // MARK: State

    var sessions: [UpcomingSession]
    var loadState: LoadState = .idle

    // MARK: Actions

    var onJoinSession: (UpcomingSession) -> Void
    var onMessage: (UpcomingSession) -> Void
    var onReschedule: (UpcomingSession) -> Void
    var onEarningsDash: () -> Void
    var onAddSession: () -> Void
    var onUpdateAvailability: () -> Void
    var onViewPastHistory: () -> Void

    // MARK: Dependencies

    @ObservationIgnored
    private let api: ClickMeAPI

    /// Client's calendar / current time — injected so tests can freeze
    /// "now" for deterministic isNow / upcoming filtering.
    @ObservationIgnored
    private let now: () -> Date

    // MARK: Init

    init(
        sessions: [UpcomingSession] = [],
        onJoinSession: @escaping (UpcomingSession) -> Void = { _ in },
        onMessage: @escaping (UpcomingSession) -> Void = { _ in },
        onReschedule: @escaping (UpcomingSession) -> Void = { _ in },
        onEarningsDash: @escaping () -> Void = {},
        onAddSession: @escaping () -> Void = {},
        onUpdateAvailability: @escaping () -> Void = {},
        onViewPastHistory: @escaping () -> Void = {},
        api: ClickMeAPI = .shared,
        now: @escaping () -> Date = Date.init
    ) {
        self.sessions = sessions
        self.onJoinSession = onJoinSession
        self.onMessage = onMessage
        self.onReschedule = onReschedule
        self.onEarningsDash = onEarningsDash
        self.onAddSession = onAddSession
        self.onUpdateAvailability = onUpdateAvailability
        self.onViewPastHistory = onViewPastHistory
        self.api = api
        self.now = now
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        sessions: [UpcomingSession] = UpcomingSession.samples
    ) -> UpcomingBookingsViewModel {
        let vm = UpcomingBookingsViewModel(sessions: sessions)
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
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
            let response = try await api.getExpertBookings(page: 1, limit: 50)
            let currentTime = now()
            sessions = response.data.bookings
                .filter { Self.isUpcoming($0, now: currentTime) }
                .sorted { $0.session.startTime < $1.session.startTime }
                .map { Self.mapSession(from: $0, now: currentTime) }
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// "Upcoming" = session hasn't ended AND status isn't terminal.
    private static func isUpcoming(_ item: ExpertBookingItem, now: Date) -> Bool {
        guard item.session.endTime > now else { return false }
        switch item.status.code {
        case .confirmed, .pendingReschedule, .inProgress:
            return true
        case .pendingApproval, .completed, .cancelled, .declined, .missed, .expired:
            return false
        }
    }

    // MARK: - Mapping

    private static func mapSession(from item: ExpertBookingItem, now: Date) -> UpcomingSession {
        return UpcomingSession(
            clientName: item.client.name ?? "Client",
            clientImageURL: item.client.avatarUrl ?? "",
            topic: item.session.topic ?? "Session",
            dateLabel: formatDateLabel(item.session.startTime, now: now),
            earnings: "",
            isNow: item.actions.canJoin
        )
    }

    /// `"Today • 10:30 AM"` / `"Tomorrow • 2:00 PM"` / `"Thu, Jul 11 • 9:00 AM"`.
    private static func formatDateLabel(_ start: Date, now: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let time = timeFormatter.string(from: start)

        if calendar.isDateInToday(start) {
            return "Today • \(time)"
        }
        if calendar.isDateInTomorrow(start) {
            return "Tomorrow • \(time)"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"
        return "\(dateFormatter.string(from: start)) • \(time)"
    }

    // MARK: - Error mapping

}
