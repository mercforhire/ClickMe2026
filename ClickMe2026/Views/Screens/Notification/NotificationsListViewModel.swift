//
//  NotificationsListViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class NotificationsListViewModel: ObservableObject {

    // MARK: State

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var sections: [NotificationsListSection] = []

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    /// Runtime init — fetches from `GET /notifications` on demand.
    init(api: ClickMeAPI = .shared) {
        self.api = api
    }

    /// Preview / test init — installs canned sections without hitting the
    /// network. Used by the SwiftUI previews to render every state.
    static func previewSeed(
        sections: [NotificationsListSection] = NotificationsListViewModel.defaultSeed
    ) -> NotificationsListViewModel {
        let vm = NotificationsListViewModel()
        vm.sections = sections
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when we already have data so a preview seed
    /// isn't clobbered on first appear.
    func load() async {
        if case .loaded = loadState, !sections.isEmpty { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    /// Background refresh — re-groups notifications without touching
    /// `loadState`. Fires from the view's `.onAppear` so returning to
    /// the list surfaces new arrivals in place instead of blanking to
    /// a spinner. Guarded on `.loaded` so it can't race the initial
    /// `.task { load() }`. Failure is intentionally swallowed.
    func silentReload() async {
        guard case .loaded = loadState else { return }
        do {
            let response = try await api.getNotifications(page: 1, limit: 50)
            sections = Self.group(response.data.notifications)
        } catch {
            // Swallow — see docblock.
        }
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getNotifications(page: 1, limit: 50)
            sections = Self.group(response.data.notifications)
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: - Grouping

    /// Bucket notifications into Today / Yesterday / Earlier by their
    /// `createdAt`. Preserves server-provided ordering within each
    /// section (server sorts newest-first).
    static func group(_ items: [NotificationItem], now: Date = Date()) -> [NotificationsListSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return items.isEmpty ? [] : [NotificationsListSection(kind: .earlier, items: items)]
        }

        var todayItems: [NotificationItem] = []
        var yesterdayItems: [NotificationItem] = []
        var earlierItems: [NotificationItem] = []

        for item in items {
            if item.createdAt >= today {
                todayItems.append(item)
            } else if item.createdAt >= yesterday {
                yesterdayItems.append(item)
            } else {
                earlierItems.append(item)
            }
        }

        var sections: [NotificationsListSection] = []
        if !todayItems.isEmpty {
            sections.append(NotificationsListSection(kind: .today, items: todayItems))
        }
        if !yesterdayItems.isEmpty {
            sections.append(NotificationsListSection(kind: .yesterday, items: yesterdayItems))
        }
        if !earlierItems.isEmpty {
            sections.append(NotificationsListSection(kind: .earlier, items: earlierItems))
        }
        return sections
    }

    // MARK: - Tap routing

    /// Maps a notification row to the app-wide `PushDestination` used by
    /// the shells' navigation logic. Reuses the same routing surface as
    /// real push taps so tap-from-list and tap-from-push land on the
    /// same screen.
    ///
    /// Mirrors the table in `PushRouter.destination(for:)` — when the
    /// backend omits `subCategory` (older payloads), we fall back to a
    /// coarse category-only mapping so the row is still tappable.
    static func destination(for item: NotificationItem) -> PushDestination? {
        switch item.category {
        case .booking:
            // `booking/requests` is a pending expert-decision request —
            // no confirmed booking to summarise, so land on the requests
            // hub rather than a booking-summary view.
            if item.subCategory == "requests" {
                return .incomingRequests
            }
            guard let bookingId = bookingId(in: item.metaData) else { return nil }
            return .bookingDetail(bookingId: bookingId)

        case .session:
            guard let bookingId = bookingId(in: item.metaData) else { return nil }
            if item.subCategory == "ended" {
                return .leaveReview(bookingId: bookingId)
            }
            return .bookingDetail(bookingId: bookingId)

        case .message:
            guard let threadId = threadId(in: item.metaData) else { return nil }
            return .chatThread(threadId: threadId)

        case .review:
            guard let bookingId = bookingId(in: item.metaData) else { return nil }
            if item.subCategory == "nudge" {
                return .leaveReview(bookingId: bookingId)
            }
            return .bookingDetail(bookingId: bookingId)

        case .payout:
            if item.subCategory == "kyc_action" {
                return .kycOnboarding
            }
            return .payouts

        case .account:
            return .accountSecurity
        }
    }

    /// The shared `NetworkService` decoder applies
    /// `.convertFromSnakeCase` to every dictionary key it decodes,
    /// including the raw keys inside `JSONValue.object`. So a payload
    /// like `{"booking_id": "…"}` on the wire arrives here as
    /// `["bookingId": .string("…")]`. Extractors accept both spellings
    /// so we're robust to whichever form the decoder produces.
    private static func bookingId(in meta: JSONValue?) -> UUID? {
        uuidValue(in: meta, forKeys: ["bookingId", "booking_id"])
    }

    private static func threadId(in meta: JSONValue?) -> UUID? {
        uuidValue(in: meta, forKeys: ["threadId", "thread_id", "chatThreadId", "chat_thread_id"])
    }

    private static func uuidValue(in meta: JSONValue?, forKeys keys: [String]) -> UUID? {
        guard case let .object(dict) = meta else { return nil }
        for key in keys {
            if case let .string(raw) = dict[key], let id = UUID(uuidString: raw) {
                return id
            }
        }
        return nil
    }

    // MARK: - Preview seed

    static let defaultSeed: [NotificationsListSection] = {
        let now = Date()
        let two_min_ago = now.addingTimeInterval(-120)
        let half_hour_ago = now.addingTimeInterval(-1_680)
        let yesterday_afternoon = now.addingTimeInterval(-60 * 60 * 20)
        let five_days_ago = now.addingTimeInterval(-60 * 60 * 24 * 5)

        return [
            NotificationsListSection(kind: .today, items: [
                NotificationItem(
                    id: UUID(),
                    userId: UUID(),
                    category: .booking,
                    subCategory: "requests",
                    title: "Booking Request",
                    body: "**Sarah Chen** sent you a booking request for UI Design.",
                    metaData: nil,
                    expiresAt: now.addingTimeInterval(60 * 60 * 24 * 14),
                    isExpertOnly: false,
                    createdAt: two_min_ago
                ),
                NotificationItem(
                    id: UUID(),
                    userId: UUID(),
                    category: .session,
                    subCategory: "reminder",
                    title: "Session Reminder",
                    body: "Your session with **Marcus Chen** starts in 30 minutes.",
                    metaData: nil,
                    expiresAt: now.addingTimeInterval(60 * 60 * 24),
                    isExpertOnly: false,
                    createdAt: half_hour_ago
                ),
            ]),
            NotificationsListSection(kind: .yesterday, items: [
                NotificationItem(
                    id: UUID(),
                    userId: UUID(),
                    category: .review,
                    subCategory: "received",
                    title: "New Review",
                    body: "A client left you a new **5-star review!** Check out what they said.",
                    metaData: nil,
                    expiresAt: now.addingTimeInterval(60 * 60 * 24 * 30),
                    isExpertOnly: false,
                    createdAt: yesterday_afternoon
                ),
            ]),
            NotificationsListSection(kind: .earlier, items: [
                NotificationItem(
                    id: UUID(),
                    userId: UUID(),
                    category: .account,
                    subCategory: "password_changed",
                    title: "Account Security",
                    body: "Your payment method has been successfully updated.",
                    metaData: nil,
                    expiresAt: now.addingTimeInterval(60 * 60 * 24 * 30),
                    isExpertOnly: false,
                    createdAt: five_days_ago
                ),
            ]),
        ]
    }()
}

// MARK: - Section model

struct NotificationsListSection: Identifiable {
    enum Kind: String {
        case today = "TODAY"
        case yesterday = "YESTERDAY"
        case earlier = "EARLIER"

        var title: String { rawValue }
    }

    let kind: Kind
    let items: [NotificationItem]

    var id: String { kind.rawValue }
}
