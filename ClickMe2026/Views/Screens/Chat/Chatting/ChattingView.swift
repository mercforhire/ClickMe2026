//
//  ChattingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Display models

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

struct ChatView: View {

    @StateObject private var viewModel: ChattingViewModel

    @FocusState private var inputFocused: Bool

    // MARK: Init

    /// Runtime init — pushed from `ChatConversationsView` with the tapped
    /// thread's id + display copy.
    init(threadId: UUID, peerName: String, peerAvatarURL: String) {
        _viewModel = StateObject(wrappedValue: ChattingViewModel(
            threadId: threadId,
            peerName: peerName,
            peerAvatarURL: peerAvatarURL
        ))
    }

    /// Preview / test seam.
    init(viewModel: ChattingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ChattingBrand.bg.ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
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
        .alert(
            "Couldn't send message",
            isPresented: Binding(
                get: { viewModel.sendError != nil },
                set: { if !$0 { viewModel.sendError = nil } }
            ),
            presenting: viewModel.sendError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            VStack {
                loadingContent
                inputBar
            }
        case .failed(let message):
            VStack {
                errorContent(message: message)
                inputBar
            }
        case .loaded:
            VStack(spacing: 0) {
                if viewModel.items.isEmpty {
                    ChattingEmptyState(onSendMessage: { inputFocused = true })
                } else {
                    messageList
                }
                inputBar
            }
        }
    }

    // MARK: - Sub-content

    private var inputBar: some View {
        ChattingInputBar(
            myAvatarURL: viewModel.myAvatarURL,
            text: $viewModel.messageText,
            inputFocused: $inputFocused,
            isSending: viewModel.isSending,
            onSend: { Task { await viewModel.sendMessage() } }
        )
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(ChattingBrand.onSurface)
            Text("Loading messages…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ChattingBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ChattingBrand.onSurfaceVar)
            Text("Couldn't load messages")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ChattingBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ChattingBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ChattingBrand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(ChattingBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.hasMoreEarlier {
                        loadEarlierButton
                    }
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

    private var loadEarlierButton: some View {
        Button {
            Task { await viewModel.loadEarlier() }
        } label: {
            HStack(spacing: 6) {
                if viewModel.isLoadingEarlier {
                    ProgressView()
                        .controlSize(.small)
                        .tint(ChattingBrand.onSurfaceVar)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(viewModel.isLoadingEarlier ? "Loading…" : "Load earlier")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(ChattingBrand.onSurfaceVar)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoadingEarlier)
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

// MARK: - Preview harness

private enum ChatPreviewRoute: Hashable { case chat }

private struct ChatPreviewHarness: View {
    let viewModel: ChattingViewModel
    @State private var path: [ChatPreviewRoute] = [.chat]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Chats")
                NavigationLink("Open conversation", value: ChatPreviewRoute.chat)
            }
            .navigationTitle("Chats")
            .navigationDestination(for: ChatPreviewRoute.self) { _ in
                ChatView(viewModel: viewModel)
            }
        }
    }
}

/// Resolves a real `threadId` from `GET /chats` and pushes `ChatView`
/// with that id so `getChatMessages` actually fetches messages.
private struct LiveFetchChattingHarness: View {
    @State private var resolved: (id: UUID, name: String, avatar: String)?
    @State private var errorMessage: String?
    @State private var path: [ChatPreviewRoute] = [.chat]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Chats")
                NavigationLink("Open first conversation", value: ChatPreviewRoute.chat)
            }
            .navigationTitle("Chats")
            .navigationDestination(for: ChatPreviewRoute.self) { _ in
                if let r = resolved {
                    ChatView(threadId: r.id, peerName: r.name, peerAvatarURL: r.avatar)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else {
                    ProgressView("Resolving thread…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .task { await resolveThread() }
                }
            }
        }
    }

    private func resolveThread() async {
        do {
            let response = try await ClickMeAPI.shared.getChats(page: 1, limit: 5)
            guard let first = response.data.threads.first else {
                errorMessage = "No conversations on this account."
                return
            }
            resolved = (first.threadId, "Chat", "")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("With Messages") {
    ChatPreviewHarness(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Empty — Start Conversation") {
    ChatPreviewHarness(viewModel: .previewSeed(items: []))
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return LiveFetchChattingHarness()
        .preferredColorScheme(.dark)
}
