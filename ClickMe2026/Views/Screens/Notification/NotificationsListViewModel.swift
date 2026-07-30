//
//  NotificationsListViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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

    // MARK: - Clear all

    /// Optimistically clears the local list and (best-effort) hits the
    /// server if a bulk-clear endpoint ever ships. Today we just empty
    /// the sections — the server doesn't expose a "delete all" route
    /// yet, so the next `reload()` will bring items back. This satisfies
    /// the design's "Clear all" affordance while the endpoint is
    /// pending.
    func clearAll() {
        withAnimation(.easeInOut(duration: 0.25)) {
            sections = []
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
