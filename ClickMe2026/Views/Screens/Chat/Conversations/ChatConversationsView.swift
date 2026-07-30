//
//  ChatConversationsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ChatPreview: Identifiable, Hashable {
    /// Server thread id — used both as `Identifiable` id and as the
    /// route target when a row is tapped.
    let threadId: UUID
    /// Counterparty's user id. Kept so live `user.status` events can
    /// find the affected row without having to walk messages.
    let partnerId: UUID
    let name: String
    let lastMessage: String
    let timeLabel: String
    let imageURL: String
    let isOnline: Bool
    let unreadCount: Int

    var id: UUID { threadId }
}

// MARK: - Chats View

struct ChatConversationsView: View {

    @StateObject private var viewModel: ChatConversationsViewModel

    /// Tapped row pushes `ChatView` — attached to the enclosing
    /// NavigationStack via `.navigationDestination(item:)`.
    @State private var pushedChat: ChatPreview?

    // MARK: Init

    init(viewModel: ChatConversationsViewModel = ChatConversationsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ChatConversationsBrand.bg.ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ChatConversationsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $pushedChat) { chat in
            ChatView(
                threadId: chat.threadId,
                peerName: chat.name,
                peerAvatarURL: chat.imageURL
            )
        }
        // When `pushedChat` flips non-nil → nil, the user just popped back
        // from a `ChatView`. Silently refresh so the row's last-message
        // preview and unread badge reflect what happened in there.
        .onChange(of: pushedChat) { oldValue, newValue in
            if oldValue != nil, newValue == nil {
                Task { await viewModel.silentReload() }
            }
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 0) {
            ChatConversationsSearchBar(
                text: $viewModel.searchText,
                onClear: { viewModel.clearSearch() }
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)

            if viewModel.filteredChats.isEmpty {
                ChatConversationsEmptyState()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(viewModel.filteredChats) { chat in
                            ChatConversationRow(
                                chat: chat,
                                action: { pushedChat = chat }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(ChatConversationsBrand.onSurface)
            Text("Loading conversations…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar)
            Text("Couldn't load conversations")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ChatConversationsBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(ChatConversationsBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sample data

extension ChatPreview {
    static let samples: [ChatPreview] = [
        ChatPreview(
            threadId: UUID(),
            partnerId: UUID(),
            name: "Dr. Olivia Bennett",
            lastMessage: "Thank you for the guidance. I'll prepare my thoughts accordingly.",
            timeLabel: "10:23 AM",
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            isOnline: true,
            unreadCount: 0
        ),
        ChatPreview(
            threadId: UUID(),
            partnerId: UUID(),
            name: "Dr. Olivia Bennett",
            lastMessage: "Yes, 2 PM works perfectly. I've added it to my calendar.",
            timeLabel: "Yesterday",
            imageURL: "https://randomuser.me/api/portraits/women/68.jpg",
            isOnline: false,
            unreadCount: 0
        ),
        ChatPreview(
            threadId: UUID(),
            partnerId: UUID(),
            name: "Dr. Marcus Carter",
            lastMessage: "I'm looking forward to our session this afternoon.",
            timeLabel: "2 days ago",
            imageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            isOnline: false,
            unreadCount: 2
        ),
        ChatPreview(
            threadId: UUID(),
            partnerId: UUID(),
            name: "Dr. Sophia Clark",
            lastMessage: "I've sent you a confirmation for our meeting at 2 PM tomorrow.",
            timeLabel: "3 days ago",
            imageURL: "https://randomuser.me/api/portraits/women/55.jpg",
            isOnline: false,
            unreadCount: 0
        ),
        ChatPreview(
            threadId: UUID(),
            partnerId: UUID(),
            name: "Support Team",
            lastMessage: "Your account has been verified successfully.",
            timeLabel: "1 week ago",
            imageURL: "https://randomuser.me/api/portraits/men/75.jpg",
            isOnline: true,
            unreadCount: 1
        ),
        ChatPreview(
            threadId: UUID(),
            partnerId: UUID(),
            name: "ClickMe Admin",
            lastMessage: "New feature rollout scheduled for next Monday.",
            timeLabel: "2 weeks ago",
            imageURL: "https://randomuser.me/api/portraits/women/30.jpg",
            isOnline: false,
            unreadCount: 0
        ),
    ]
}

// MARK: - Previews

// ChatConversations is shown as a tab root in production — no dummy
// "parent" chevron needed. Just wrap in a plain NavigationStack so the
// inline title + toolbar render.

#Preview("Populated") {
    NavigationStack {
        ChatConversationsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty Search") {
    NavigationStack {
        ChatConversationsView(viewModel: .previewSeed(chats: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return NavigationStack {
        ChatConversationsView(viewModel: ChatConversationsViewModel())
    }
    .preferredColorScheme(.dark)
}
