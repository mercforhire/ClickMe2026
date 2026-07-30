//
//  ChattingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Chat View

struct ChatView: View {

    @StateObject private var viewModel: ChattingViewModel

    @FocusState private var inputFocused: Bool

    /// Set from the toolbar menu's "Block or Report" button; triggers the
    /// push into `ReportChatView` via `.navigationDestination(isPresented:)`.
    @State private var showingBlockReport: Bool = false

    /// Provided by the enclosing shell (`HomeClientView` / `HomeExpertView`)
    /// so tapping a booking-lifecycle event row can push its detail screen
    /// onto the Chats tab's stack. Nil outside a shell — e.g. previews or
    /// when opened from a deep-linked context — in which case event rows
    /// remain non-tappable rather than doing nothing.
    @Environment(\.homeNavigationPath) private var homeNavigationPath

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
            Button("View Profile") { openPeerProfile() }
                .disabled(viewModel.peerUserId == nil)
            Button("Block or Report", role: .destructive) {
                showingBlockReport = true
            }
        }
        .navigationDestination(isPresented: $showingBlockReport) {
            if let threadId = viewModel.threadId {
                ReportChatView(
                    threadId: threadId,
                    userName: viewModel.peerName,
                    onBlock: { _ in showingBlockReport = false },
                    onReport: { _, _ in },
                    onDismiss: { showingBlockReport = false }
                )
            }
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
        VStack(spacing: 0) {
            if viewModel.peerIsTyping {
                typingIndicator
            }
            ChattingInputBar(
                myAvatarURL: viewModel.myAvatarURL,
                text: $viewModel.messageText,
                inputFocused: $inputFocused,
                isSending: viewModel.isSending,
                onSend: { Task { await viewModel.sendMessage() } }
            )
        }
        // Debounced typing.start / typing.stop emit lives in the VM;
        // just poke it whenever the input text changes.
        .onChange(of: viewModel.messageText) {
            viewModel.notifyMessageTextChanged()
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.peerIsTyping)
    }

    /// "…is typing" strip shown above the input bar. Copy uses the
    /// peer's display name so multi-conversation stacks don't blur
    /// together.
    private var typingIndicator: some View {
        HStack(spacing: 6) {
            Text("\(viewModel.peerName) is typing…")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ChattingBrand.onSurfaceVar)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .transition(.opacity)
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
                    .foregroundColor(ChattingBrand.myText)
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
            // Only scroll to bottom on signals from the VM — initial load
            // and successful sends. Loading older history (loadEarlier)
            // deliberately doesn't bump the token, so pagination leaves
            // the scroll position where the user is reading.
            //
            // Two-shot fire: `items.append(...)` and the token bump
            // happen in the same render pass, so a naive single
            // `scrollTo` sometimes runs before SwiftUI has laid out the
            // newly-appended bubble — landing at the previous bottom.
            // The first pass catches the fast case; the deferred one
            // catches the LazyVStack materialization case.
            .onChange(of: viewModel.scrollToBottomToken) {
                proxy.scrollTo("bottom", anchor: .bottom)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Fallback for the case where the token has already been
                // bumped before this view appeared (fast fetch, preview
                // seed). No animation — we want the chat to open already
                // at the bottom, not visibly scroll into place.
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
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
        case let .timestamp(label):
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ChattingBrand.onSurfaceVar)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        case let .systemEvent(event):
            Group {
                if event.bookingId != nil {
                    Button {
                        openBookingDetail(for: event)
                    } label: {
                        ChattingSystemEventRow(event: event)
                    }
                    .buttonStyle(.plain)
                } else {
                    ChattingSystemEventRow(event: event)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    /// Routes a tap on a system-event row to the appropriate detail
    /// screen. Terminal states (declined / cancelled / completed /
    /// expired) go to the read-only `BookingSummaryView`; active states
    /// (request / confirmed / rescheduled) go to `UpcomingBookingView`
    /// where the user can still manage the booking. No-op when the
    /// event carries no booking id (legacy rows) or when there's no
    /// shell nav path to push onto (previews).
    /// Push the peer's profile onto the ambient shell nav path. Silently
    /// no-ops when we don't yet know the peer id (empty thread, no
    /// messages loaded) or when we're rendered outside a shell (previews).
    private func openPeerProfile() {
        guard let peerId = viewModel.peerUserId,
              let navPath = homeNavigationPath else { return }
        navPath.push(HomeRoute.peerProfile(
            userId: peerId,
            name: viewModel.peerName,
            avatarURL: viewModel.peerAvatarURL
        ))
    }

    private func openBookingDetail(for event: BookingEvent) {
        guard let bookingId = event.bookingId,
              let navPath = homeNavigationPath else { return }
        if event.isTerminal {
            navPath.push(HomeRoute.bookingSummary(bookingId: bookingId))
        } else {
            navPath.push(HomeRoute.upcomingBooking(bookingId: bookingId))
        }
    }
}

// MARK: - Sample data

extension ChatItem {
    static let sampleConversation: [ChatItem] = [
        .timestamp("Today 10:23 AM"),
        .message(ChatMessage(
            serverId: nil, sender: .them, senderName: "Dr. Olivia Bennett",
            body: "Hi Dr. Bennett, I'm looking forward to our session this afternoon. Could you please share any preparatory materials?",
            avatarURL: "https://randomuser.me/api/portraits/women/44.jpg",
            timestamp: Date().addingTimeInterval(-3600),
            status: .sent
        )),
        .message(ChatMessage(
            serverId: nil, sender: .me, senderName: "Ethan",
            body: "Thank you. You're noted for your hot as match your message?.",
            avatarURL: "https://randomuser.me/api/portraits/men/32.jpg",
            timestamp: Date().addingTimeInterval(-3300),
            status: .sent
        )),
        .systemEvent(BookingEvent(
            icon: "checkmark.square", title: "Booking Confirmed",
            subtitle: "Tomorrow, 2:00 PM", isAccepted: true, avatarURL: nil,
            bookingId: nil, isTerminal: false,
            topicTitle: "30-min strategy call",
            startTime: Date().addingTimeInterval(3600 * 24),
            durationMins: 30
        )),
        .message(ChatMessage(
            serverId: nil, sender: .them, senderName: "Dr. Olivia Bennett",
            body: "Ethan, I've sent you a confirmation for our meeting at 2 PM tomorrow. Please let me know if that time works for you.",
            avatarURL: "https://randomuser.me/api/portraits/women/44.jpg",
            timestamp: Date().addingTimeInterval(-2700),
            status: .sent
        )),
        .message(ChatMessage(
            serverId: nil, sender: .me, senderName: "Ethan",
            body: "Yes, 2 PM works perfectly.",
            avatarURL: "https://randomuser.me/api/portraits/men/32.jpg",
            timestamp: Date().addingTimeInterval(-2400),
            status: .sent
        )),
        .systemEvent(BookingEvent(
            icon: "checkmark.square", title: "Booking Accepted",
            subtitle: nil, isAccepted: true,
            avatarURL: "https://randomuser.me/api/portraits/women/44.jpg",
            bookingId: nil, isTerminal: false,
            topicTitle: "30-min strategy call",
            startTime: Date().addingTimeInterval(3600 * 24),
            durationMins: 30
        )),
    ]
}

// MARK: - Live-fetch harness

/// Resolves a real `threadId` from `GET /chats` and pushes `ChatView`
/// with that id so `getChatMessages` actually fetches messages. Custom
/// async logic — can't be swapped for the generic `PreviewNavHarness`.
private struct LiveFetchChattingHarness: View {
    @State private var resolved: (id: UUID, name: String, avatar: String)?
    @State private var errorMessage: String?

    var body: some View {
        PreviewNavHarness(parentText: "Chats", navTitle: "Chats", rowTitle: "Open first conversation") {
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

    private func resolveThread() async {
        do {
            let response = try await ClickMeAPI.shared.getChats(page: 1, limit: 5)
            guard let first = response.data.threads.first else {
                errorMessage = "No conversations on this account."
                return
            }
            resolved = (first.threadId, "Chat", "")
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("With Messages") {
    PreviewNavHarness(parentText: "Chats", navTitle: "Chats", rowTitle: "Open conversation") {
        ChatView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty — Start Conversation") {
    PreviewNavHarness(parentText: "Chats", navTitle: "Chats", rowTitle: "Open conversation") {
        ChatView(viewModel: .previewSeed(items: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return LiveFetchChattingHarness()
        .preferredColorScheme(.dark)
}
