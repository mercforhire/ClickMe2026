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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: View state
    @Published var searchText: String
    @Published var activeTab: ChatTab
    @Published var loadState: LoadState = .idle

    // MARK: Data
    @Published var chats: [ChatPreview]

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    /// Runtime init — starts empty, `.task { load() }` populates from
    /// `GET /chats`.
    init(
        searchText: String = "",
        activeTab: ChatTab = .clients,
        chats: [ChatPreview] = [],
        api: ClickMeAPI = .shared
    ) {
        self.searchText = searchText
        self.activeTab = activeTab
        self.chats = chats
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        activeTab: ChatTab = .clients,
        chats: [ChatPreview] = ChatPreview.samples
    ) -> ChatConversationsViewModel {
        let vm = ChatConversationsViewModel(activeTab: activeTab, chats: chats)
        vm.loadState = .loaded
        return vm
    }

    // MARK: Derived

    var filteredChats: [ChatPreview] {
        let tabFiltered = chats.filter { $0.tab == activeTab }
        guard !searchText.isEmpty else { return tabFiltered }
        return tabFiltered.filter {
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
    /// Backend gap: `ChatThreadItem` currently carries only `partnerId`.
    /// Until the server enriches the response with `partner.name` /
    /// `partner.avatarUrl` / `partner.role`, the list shows generic
    /// placeholders for name+avatar and routes every thread to the
    /// Clients tab (internal_ tab is unreachable).
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
            let response = try await api.getChats(page: 1, limit: 50)
            chats = response.data.threads.map(Self.mapThread(from:))
            loadState = .loaded
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    // MARK: - Mapping

    private static func mapThread(from item: ChatThreadItem) -> ChatPreview {
        ChatPreview(
            threadId: item.threadId,
            name: "Chat",
            lastMessage: item.lastMessage ?? "",
            timeLabel: relativeTimeLabel(from: item.lastMsgAt),
            imageURL: "",
            isOnline: item.isOnline,
            unreadCount: item.unreadCount,
            tab: .clients
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

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
