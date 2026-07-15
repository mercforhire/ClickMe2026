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
    @Published var activeTab: ChatTab

    // MARK: Data
    @Published var chats: [ChatPreview]

    init(
        searchText: String = "",
        activeTab: ChatTab = .clients,
        chats: [ChatPreview] = ChatPreview.samples
    ) {
        self.searchText = searchText
        self.activeTab = activeTab
        self.chats = chats
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
}
