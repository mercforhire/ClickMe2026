//
//  ChattingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

// MARK: - Models

enum MessageSender { case me, them }

enum ChatItem: Identifiable {
    case message(ChatMessage)
    case timestamp(String)
    case systemEvent(BookingEvent)

    var id: String {
        switch self {
        case let .message(m): return m.id.uuidString
        case let .timestamp(t): return "ts_\(t)"
        case let .systemEvent(e): return e.id.uuidString
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: MessageSender
    let senderName: String
    let body: String
    let avatarURL: String
}

struct BookingEvent: Identifiable {
    let id = UUID()
    let icon: String // SF Symbol
    let title: String
    let subtitle: String?
    let isAccepted: Bool
    let avatarURL: String? // nil = no avatar on left
}

// MARK: - Chat View

struct ClickMeChatView: View {

    @StateObject private var viewModel: ChattingViewModel

    @FocusState private var inputFocused: Bool

    // MARK: Init

    init(viewModel: ChattingViewModel = ChattingViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    /// Convenience init mirroring the prior call signature so existing call
    /// sites that pass individual fields still compile.
    init(
        peerName: String = "Dr. Olivia Bennett",
        peerAvatarURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        myAvatarURL: String = "https://randomuser.me/api/portraits/men/32.jpg",
        myName: String = "Ethan",
        items: [ChatItem] = ChatItem.sampleConversation
    ) {
        self.init(viewModel: ChattingViewModel(
            peerName: peerName,
            peerAvatarURL: peerAvatarURL,
            myAvatarURL: myAvatarURL,
            myName: myName,
            items: items
        ))
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ChattingBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.items.isEmpty {
                    ChattingEmptyState(onSendMessage: { inputFocused = true })
                } else {
                    messageList
                }

                ChattingInputBar(
                    myAvatarURL: viewModel.myAvatarURL,
                    text: $viewModel.messageText,
                    selectedPhoto: $viewModel.selectedPhoto,
                    inputFocused: $inputFocused,
                    onSend: viewModel.sendMessage
                )
            }
        }
        .navigationTitle(viewModel.peerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ChattingBrand.navBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { viewModel.showMenu = true } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(ChattingBrand.onSurface)
                }
            }
        }
        .confirmationDialog("Options", isPresented: $viewModel.showMenu, titleVisibility: .hidden) {
            Button("View Profile") {}
            Button("Mute Chat") {}
            Button("Block User", role: .destructive) {}
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.items) { item in
                        chatItemView(item)
                    }
                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.items.count) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func chatItemView(_ item: ChatItem) -> some View {
        switch item {
        case let .message(msg):
            ChattingMessageBubble(message: msg, myName: viewModel.myName)
                .padding(.vertical, 4)
                .padding(.horizontal, 14)
        case let .timestamp(label):
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ChattingBrand.onSurfaceVar)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        case let .systemEvent(event):
            ChattingSystemEventRow(event: event)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
        }
    }
}

// MARK: - Sample data

extension ChatItem {
    static let sampleConversation: [ChatItem] = [
        .timestamp("Today 10:23 AM"),
        .message(ChatMessage(
            sender: .them, senderName: "Dr. Olivia Bennett",
            body: "Hi Dr. Bennett, I'm looking forward to our session this afternoon. Could you please share any preparatory materials?",
            avatarURL: "https://randomuser.me/api/portraits/women/44.jpg"
        )),
        .message(ChatMessage(
            sender: .me, senderName: "Ethan",
            body: "Thank you. You're noted for your hot as match your message?.",
            avatarURL: "https://randomuser.me/api/portraits/men/32.jpg"
        )),
        .systemEvent(BookingEvent(
            icon: "checkmark.square", title: "Booking Confirmed",
            subtitle: "Tomorrow, 2:00 PM", isAccepted: true, avatarURL: nil
        )),
        .message(ChatMessage(
            sender: .them, senderName: "Dr. Olivia Bennett",
            body: "Ethan, I've sent you a confirmation for our meeting at 2 PM tomorrow. Please let me know if that time works for you.",
            avatarURL: "https://randomuser.me/api/portraits/women/44.jpg"
        )),
        .message(ChatMessage(
            sender: .me, senderName: "Ethan",
            body: "Yes, 2 PM works perfectly.",
            avatarURL: "https://randomuser.me/api/portraits/men/32.jpg"
        )),
        .systemEvent(BookingEvent(
            icon: "checkmark.square", title: "Booking Accepted",
            subtitle: nil, isAccepted: true,
            avatarURL: "https://randomuser.me/api/portraits/women/44.jpg"
        )),
    ]
}

// MARK: - Previews

#Preview("With Messages") {
    NavigationStack {
        ClickMeChatView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty — Start Conversation") {
    NavigationStack {
        ClickMeChatView(items: [])
    }
    .preferredColorScheme(.dark)
}
