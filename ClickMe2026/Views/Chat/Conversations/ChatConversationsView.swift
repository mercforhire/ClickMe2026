//
//  ChatConversationsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

enum ChatTab { case clients, internal_ }

struct ChatPreview: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let timeLabel: String
    let imageURL: String
    let isOnline: Bool
    let unreadCount: Int
    let tab: ChatTab
}

// MARK: - Chats View

struct ClickMeChatsView: View {

    @StateObject private var viewModel: ChatConversationsViewModel
    var onSelectChat: (ChatPreview) -> Void

    // MARK: Init

    init(
        viewModel: ChatConversationsViewModel = ChatConversationsViewModel(),
        onSelectChat: @escaping (ChatPreview) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelectChat = onSelectChat
    }

    /// Convenience init that defers to a fresh view model populated with the
    /// supplied chats — preserves the original call site that took a chats array.
    init(
        chats: [ChatPreview],
        onSelectChat: @escaping (ChatPreview) -> Void = { _ in }
    ) {
        self.init(
            viewModel: ChatConversationsViewModel(chats: chats),
            onSelectChat: onSelectChat
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ChatConversationsBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ChatConversationsWordmark()
                    .padding(.top, 52)
                    .padding(.bottom, 20)

                ChatConversationsSearchBar(
                    text: $viewModel.searchText,
                    onClear: { viewModel.clearSearch() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                ChatTabPills(activeTab: $viewModel.activeTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                if viewModel.filteredChats.isEmpty {
                    ChatConversationsEmptyState()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(viewModel.filteredChats) { chat in
                                ChatConversationRow(
                                    chat: chat,
                                    action: { onSelectChat(chat) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
}

// MARK: - Sample data

extension ChatPreview {
    static let samples: [ChatPreview] = [
        ChatPreview(
            name: "Dr. Olivia Bennett",
            lastMessage: "Thank you for the guidance. I'll prepare my thoughts accordingly.",
            timeLabel: "10:23 AM",
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            isOnline: true,
            unreadCount: 0,
            tab: .clients
        ),
        ChatPreview(
            name: "Dr. Olivia Bennett",
            lastMessage: "Yes, 2 PM works perfectly. I've added it to my calendar.",
            timeLabel: "Yesterday",
            imageURL: "https://randomuser.me/api/portraits/women/68.jpg",
            isOnline: false,
            unreadCount: 0,
            tab: .clients
        ),
        ChatPreview(
            name: "Dr. Marcus Carter",
            lastMessage: "I'm looking forward to our session this afternoon.",
            timeLabel: "2 days ago",
            imageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            isOnline: false,
            unreadCount: 2,
            tab: .clients
        ),
        ChatPreview(
            name: "Dr. Sophia Clark",
            lastMessage: "I've sent you a confirmation for our meeting at 2 PM tomorrow.",
            timeLabel: "3 days ago",
            imageURL: "https://randomuser.me/api/portraits/women/55.jpg",
            isOnline: false,
            unreadCount: 0,
            tab: .clients
        ),
        ChatPreview(
            name: "Support Team",
            lastMessage: "Your account has been verified successfully.",
            timeLabel: "1 week ago",
            imageURL: "https://randomuser.me/api/portraits/men/75.jpg",
            isOnline: true,
            unreadCount: 1,
            tab: .internal_
        ),
        ChatPreview(
            name: "ClickMe Admin",
            lastMessage: "New feature rollout scheduled for next Monday.",
            timeLabel: "2 weeks ago",
            imageURL: "https://randomuser.me/api/portraits/women/30.jpg",
            isOnline: false,
            unreadCount: 0,
            tab: .internal_
        ),
    ]
}

// MARK: - Previews

#Preview("Clients Tab") {
    ClickMeChatsView()
        .preferredColorScheme(.dark)
}

#Preview("Internal Tab") {
    ClickMeChatsView(viewModel: ChatConversationsViewModel(activeTab: .internal_))
        .preferredColorScheme(.dark)
}

#Preview("Empty Search") {
    ClickMeChatsView(chats: [])
        .preferredColorScheme(.dark)
}
