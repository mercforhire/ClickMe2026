//
//  ChatConversationsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ChatConversationsViewModel: ObservableObject {


    // MARK: View state
    @Published var searchText: String
    @Published var loadState: LoadState = .idle

    // MARK: Data
    @Published var chats: [ChatPreview]

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Realtime

    /// Held for the VM's lifetime; auto-cancel on deallocation.
    private var realtimeSubscriptions: [RealtimeSubscription] = []

    // MARK: Init

    /// Runtime init — starts empty, `.task { load() }` populates from
    /// `GET /chats`.
    init(
        searchText: String = "",
        chats: [ChatPreview] = [],
        api: ClickMeAPI = .shared
    ) {
        self.searchText = searchText
        self.chats = chats
        self.api = api
        // Subscribe eagerly so events landing before the first fetch
        // completes aren't dropped; the handlers tolerate an empty
        // `chats` array.
        self.realtimeSubscriptions = [
            RealtimeService.shared.onMessageNew { [weak self] event in
                Task { @MainActor in self?.handleMessageNew(event) }
            },
            RealtimeService.shared.onUserStatus { [weak self] event in
                Task { @MainActor in self?.handleUserStatus(event) }
            }
        ]
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        chats: [ChatPreview] = ChatPreview.samples
    ) -> ChatConversationsViewModel {
        let vm = ChatConversationsViewModel(chats: chats)
        vm.loadState = .loaded
        return vm
    }

    // MARK: Derived

    var filteredChats: [ChatPreview] {
        guard !searchText.isEmpty else { return chats }
        return chats.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: Actions

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Load

    /// Fetches `GET /chats` and maps each thread to a `ChatPreview`.
    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
    ///
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    /// Re-fetches `GET /chats` without flipping `loadState` to `.loading`
    /// — so the UI doesn't flash the full-screen spinner. Used when the
    /// user pops back from a chat and we want the row's last-message /
    /// unread-count to reflect their activity. Fetch failures leave the
    /// existing list intact.
    func silentReload() async {
        guard case .loaded = loadState else {
            // Nothing meaningful to preserve yet — fall through to the
            // normal loader so a spinner shows.
            await forceLoad()
            return
        }
        if let response = try? await api.getChats(page: 1, limit: 50) {
            chats = response.data.threads.map(Self.mapThread(from:))
        }
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getChats(page: 1, limit: 50)
            chats = response.data.threads.map(Self.mapThread(from:))
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: - Realtime

    /// Patches the matching thread's preview to reflect a live-arrived
    /// message: swap `lastMessage`, refresh `timeLabel`, and move the
    /// row to the top so the list stays sorted by most-recent activity.
    ///
    /// Unread accounting is intentionally left to the server-sourced
    /// value refreshed by `silentReload()` on pop-back. The backend
    /// team's contract notes `unread_count` isn't reliably maintained
    /// today, so we don't try to increment locally — the ChatView
    /// itself emits `message.read` on message arrival, which will
    /// often zero the count before this list ever re-fetches.
    private func handleMessageNew(_ event: RealtimeMessageNewEvent) {
        guard let idx = chats.firstIndex(where: { $0.threadId == event.threadId }) else {
            // Unknown thread — probably a first-message-from-new-peer
            // scenario. Trigger a full silent refresh to pick up the
            // brand-new row without flashing a spinner.
            Task { await silentReload() }
            return
        }
        let existing = chats[idx]
        let updated = ChatPreview(
            threadId: existing.threadId,
            partnerId: existing.partnerId,
            name: existing.name,
            lastMessage: event.content ?? existing.lastMessage,
            timeLabel: Self.relativeTimeLabel(from: event.timestamp),
            imageURL: existing.imageURL,
            isOnline: existing.isOnline,
            unreadCount: existing.unreadCount
        )
        chats.remove(at: idx)
        chats.insert(updated, at: 0)
    }

    /// A conversation partner's presence changed. Flip the matching row's
    /// online dot in place — we don't need a full refetch for this.
    private func handleUserStatus(_ event: RealtimeUserStatusEvent) {
        guard let idx = chats.firstIndex(where: { $0.partnerId == event.userId }) else { return }
        let existing = chats[idx]
        chats[idx] = ChatPreview(
            threadId: existing.threadId,
            partnerId: existing.partnerId,
            name: existing.name,
            lastMessage: existing.lastMessage,
            timeLabel: existing.timeLabel,
            imageURL: existing.imageURL,
            isOnline: event.status == .online,
            unreadCount: existing.unreadCount
        )
    }

    // MARK: - Mapping

    private static func mapThread(from item: ChatThreadItem) -> ChatPreview {
        ChatPreview(
            threadId: item.threadId,
            partnerId: item.partner.id,
            name: item.partner.name ?? "Chat",
            lastMessage: item.lastMessage ?? "",
            timeLabel: relativeTimeLabel(from: item.lastMsgAt),
            imageURL: item.partner.avatarUrl ?? "",
            isOnline: item.isOnline,
            unreadCount: item.unreadCount
        )
    }

    /// `"10:23 AM"` for today, `"Yesterday"` for yesterday, otherwise
    /// `"MMM d"`. Empty string when nil.
    private static func relativeTimeLabel(from date: Date?) -> String {
        guard let date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    // MARK: - Error mapping

}
