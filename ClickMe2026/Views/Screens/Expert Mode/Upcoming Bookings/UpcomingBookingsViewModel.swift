//
//  UpcomingBookingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class UpcomingBookingsViewModel {


    // MARK: State

    var sessions: [UpcomingSession]
    /// Terminal / past bookings (completed, cancelled, declined, missed,
    /// expired). Sorted newest-first. Populated alongside `sessions`
    /// from the same `/expert/bookings` fetch — we split into upcoming
    /// vs past client-side so a single round trip drives both tabs.
    var pastSessions: [PastSession] = []
    /// Segmented picker index — 0 = Upcoming, 1 = Past.
    var selectedTab: Int = 0
    var loadState: LoadState = .idle

    // MARK: Actions

    var onJoinSession: (UpcomingSession) -> Void
    var onReschedule: (UpcomingSession) -> Void
    var onUpdateAvailability: () -> Void
    var onViewPastHistory: () -> Void

    // MARK: Dependencies

    @ObservationIgnored
    private let api: ClickMeAPI

    /// Client's calendar / current time — injected so tests can freeze
    /// "now" for deterministic isNow / upcoming filtering.
    @ObservationIgnored
    private let now: () -> Date

    /// Retains our `booking.update` subscription. Silent-refreshes the
    /// lists whenever any booking's status changes server-side — so a
    /// server-driven `BOOKING_COMPLETED` (fired ~15 min after
    /// `end_time` per `docs/ios/CALL-END-SEMANTICS.md`) moves the row
    /// from Upcoming into Past without requiring pull-to-refresh.
    @ObservationIgnored
    private var bookingUpdateSubscription: RealtimeSubscription?

    // MARK: Init

    init(
        sessions: [UpcomingSession] = [],
        onJoinSession: @escaping (UpcomingSession) -> Void = { _ in },
        onReschedule: @escaping (UpcomingSession) -> Void = { _ in },
        onUpdateAvailability: @escaping () -> Void = {},
        onViewPastHistory: @escaping () -> Void = {},
        api: ClickMeAPI = .shared,
        now: @escaping () -> Date = Date.init
    ) {
        self.sessions = sessions
        self.onJoinSession = onJoinSession
        self.onReschedule = onReschedule
        self.onUpdateAvailability = onUpdateAvailability
        self.onViewPastHistory = onViewPastHistory
        self.api = api
        self.now = now

        // Server-driven status transitions (BOOKING_COMPLETED, cancel,
        // decline, etc.) re-partition sessions across upcoming / past.
        // Silent reload so the list doesn't blank to the loading state
        // while the user is watching.
        self.bookingUpdateSubscription = RealtimeService.shared.onBookingUpdate { [weak self] _ in
            Task { @MainActor in await self?.silentReload() }
        }
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        sessions: [UpcomingSession] = UpcomingSession.samples,
        pastSessions: [PastSession] = PastSession.samples,
        selectedTab: Int = 0
    ) -> UpcomingBookingsViewModel {
        let vm = UpcomingBookingsViewModel(sessions: sessions)
        vm.pastSessions = pastSessions
        vm.selectedTab = selectedTab
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

    /// Background refresh that leaves the current list on screen while
    /// the fetch runs — no spinner, no error state flip. Wired to the
    /// `booking.update` socket subscription AND `.onAppear` on the
    /// view so a server-side status transition (e.g. `BOOKING_COMPLETED`
    /// ~15 min after `end_time`) plus a manual return to the tab both
    /// re-partition Upcoming/Past without visible chrome flicker.
    /// Guarded on `.loaded` so it can't race the initial `.task`'s
    /// `forceLoad`. Failure is intentionally silent — keep the
    /// last-known-good list on screen rather than blanking on a
    /// transient network blip.
    func silentReload() async {
        guard case .loaded = loadState else { return }
        try? await runFetch()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            try await runFetch()
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// Actual fetch + partition. Extracted so both `forceLoad` (with
    /// loading-state chrome) and `silentReload` (no chrome) share the
    /// same partitioning logic. Throws so callers own the failure
    /// surface.
    private func runFetch() async throws {
        do {
            // Two fetches — the server partitions upcoming vs past via
            // the required `type` query param (same contract as
            // `/client/bookings`). Sequential rather than parallel to
            // avoid Swift 6 main-actor-isolated Decodable issues across
            // concurrent decodes.
            let upResponse = try await api.getExpertBookings(type: .upcoming, page: 1, limit: 50)
            let pastResponse = try await api.getExpertBookings(type: .past, page: 1, limit: 50)
            let currentTime = now()

            // Rejoinable completeds — status flipped to `.completed`
            // (someone hung up early) but the scheduled end hasn't
            // passed. Surface them under Upcoming so the expert can
            // rejoin from the same card.
            let rejoinable = pastResponse.data.bookings.filter {
                Self.isRejoinableCompleted($0, now: currentTime)
            }

            sessions = (upResponse.data.bookings + rejoinable)
                .filter { Self.isUpcomingOrRejoinable($0, now: currentTime) }
                .sorted { $0.session.startTime < $1.session.startTime }
                .map { Self.mapSession(from: $0, now: currentTime) }

            // Past: newest first so the most recent session is at the
            // top of the list. Rejoinable rows drop out — they're now
            // shown as upcoming instead.
            pastSessions = pastResponse.data.bookings
                .sorted { $0.session.startTime > $1.session.startTime }
                .compactMap { Self.mapPastIfApplicable($0, now: currentTime) }
        } catch {
            throw error
        }
    }

    /// Extends `isUpcoming` to also include completed sessions whose
    /// scheduled end is still in the future — those are rejoinable.
    private static func isUpcomingOrRejoinable(_ item: ExpertBookingItem, now: Date) -> Bool {
        if isUpcoming(item, now: now) { return true }
        return isRejoinableCompleted(item, now: now)
    }

    /// True when the row is `.completed` on the wire but its scheduled
    /// end hasn't passed — the client should surface a Join button so
    /// the user can rejoin the same call.
    private static func isRejoinableCompleted(_ item: ExpertBookingItem, now: Date) -> Bool {
        item.status.code == .completed && item.session.endTime > now
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

    /// "Past" = session has ended (in wall-clock time) OR the status is
    /// terminal. Mirrors the client-side 3-case collapse:
    /// `completed → .completed`, `cancelled / declined → .cancelled`,
    /// `missed / expired → .missed`. Anything that doesn't map returns
    /// nil so we don't render pending-approval rows in the Past tab.
    private static func mapPastIfApplicable(_ item: ExpertBookingItem, now: Date) -> PastSession? {
        let uiStatus: PastBookingStatus
        switch item.status.code {
        case .completed:
            // Completed-but-not-past is rejoinable, not really "past"
            // yet. Drop it here; the caller promotes it into the
            // upcoming list.
            if item.session.endTime > now { return nil }
            uiStatus = .completed
        case .cancelled, .declined:
            uiStatus = .cancelled
        case .missed, .expired:
            uiStatus = .missed
        case .pendingApproval, .confirmed, .pendingReschedule, .inProgress:
            // Not terminal — but still count as past if the session
            // clock has already elapsed. Treat as .missed since
            // there's no completed marker yet.
            guard item.session.endTime <= now else { return nil }
            uiStatus = .missed
        }

        return PastSession(
            bookingId: item.bookingId,
            clientId: item.client.id,
            clientName: item.client.name ?? "Client",
            clientImageURL: item.client.avatarUrl ?? "",
            topic: item.session.topic ?? "Session",
            date: formatDate(item.session.startTime),
            timeRange: formatTimeRange(from: item.session.startTime, to: item.session.endTime),
            status: uiStatus,
            privateNotePreview: item.privateNotePreview
        )
    }

    /// `"Jul 15, 2026"` — full date for past sessions where relative
    /// labels (today/tomorrow) no longer make sense.
    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private static func formatTimeRange(from start: Date, to end: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }

    // MARK: - Mapping

    private static func mapSession(from item: ExpertBookingItem, now: Date) -> UpcomingSession {
        return UpcomingSession(
            bookingId: item.bookingId,
            clientId: item.client.id,
            clientName: item.client.name ?? "Client",
            clientImageURL: item.client.avatarUrl ?? "",
            topic: item.session.topic ?? "Session",
            dateLabel: formatDateLabel(item.session.startTime, now: now),
            earnings: formatEarnings(item.session.earningsBreakdown),
            startTime: item.session.startTime,
            endTime: item.session.endTime,
            meetingType: item.session.meetingType,
            status: item.status.code,
            privateNotePreview: item.privateNotePreview,
            reschedule: item.reschedule
        )
    }

    /// Formats the card's "EARNINGS" value per the Expert Earnings
    /// Breakdown spec (§3). `.booking` → plain, `.expertDefault` →
    /// qualified with `≈`, `.unavailable` / nil → empty string so the
    /// card hides the amount (the "EARNINGS" label itself is also
    /// suppressed by the view). Never falls back to `grossAmount`.
    private static func formatEarnings(_ breakdown: EarningsBreakdown?) -> String {
        guard let breakdown,
              let feeSource = breakdown.feeSource,
              let net = breakdown.netAmount,
              let formatted = formatCurrency(net, code: breakdown.currency)
        else { return "" }
        switch feeSource {
        case .booking:
            return formatted
        case .expertDefault:
            return "≈ \(formatted)"
        case .unavailable:
            return ""
        }
    }

    /// Locale-aware currency formatter. `NumberFormatter.currency`
    /// handles zero-decimal currencies (JPY, KRW, VND, CLP, ISK, XOF,
    /// XAF) off the ISO code — no hardcoded fraction count. Returns
    /// nil when either input is malformed so the caller can hide the
    /// amount instead of printing a bogus string.
    private static func formatCurrency(_ amount: Double, code: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: amount))
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
