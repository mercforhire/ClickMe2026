//
//  ChattingViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ChattingViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Identity
    let threadId: UUID?
    let peerName: String
    let peerAvatarURL: String
    let myAvatarURL: String
    let myName: String
    /// Auth-user id used to tag `.me` vs. `.them`. Read from
    /// `UserManager.shared.authUser?.id` at init time.
    private let myUserId: UUID?

    // MARK: View state
    @Published var items: [ChatItem]
    @Published var messageText: String
    @Published var showMenu: Bool

    @Published var loadState: LoadState = .idle
    /// True while a POST to `/chats/:id/send` is in flight. Disables the
    /// input and swaps the send button for a spinner.
    @Published var isSending: Bool = false
    /// Non-fatal error surfaced from the send-message call.
    @Published var sendError: String?
    /// True while paginating older history in via `loadEarlier()`.
    @Published var isLoadingEarlier: Bool = false
    /// False once the server signals there are no more pages left.
    @Published var hasMoreEarlier: Bool = true

    // MARK: Pagination cursor

    private var oldestLoadedPage: Int = 0

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let pageSize: Int = 30

    // MARK: - Runtime init

    /// Runtime init — fetches messages from `GET /chats/:id/messages`.
    init(
        threadId: UUID,
        peerName: String,
        peerAvatarURL: String,
        api: ClickMeAPI = .shared
    ) {
        self.threadId = threadId
        self.peerName = peerName
        self.peerAvatarURL = peerAvatarURL
        self.myAvatarURL = UserManager.shared.authUser?.avatarUrl ?? ""
        self.myName = UserManager.shared.authUser?.firstName ?? "You"
        self.myUserId = UserManager.shared.authUser?.id
        self.items = []
        self.messageText = ""
        self.showMenu = false
        self.api = api
    }

    // MARK: - Preview init

    /// Preview/design init — no network, uses canned items.
    init(
        peerName: String = "Dr. Olivia Bennett",
        peerAvatarURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        myAvatarURL: String = "https://randomuser.me/api/portraits/men/32.jpg",
        myName: String = "Ethan",
        items: [ChatItem] = ChatItem.sampleConversation,
        messageText: String = "",
        showMenu: Bool = false
    ) {
        self.threadId = nil
        self.peerName = peerName
        self.peerAvatarURL = peerAvatarURL
        self.myAvatarURL = myAvatarURL
        self.myName = myName
        self.myUserId = nil
        self.items = items
        self.messageText = messageText
        self.showMenu = showMenu
        self.api = .shared
    }

    /// Preview seam — installs the canned conversation and marks
    /// `.loaded` so the LoadState router shows content immediately.
    static func previewSeed(
        items: [ChatItem] = ChatItem.sampleConversation
    ) -> ChattingViewModel {
        let vm = ChattingViewModel(items: items)
        vm.loadState = .loaded
        vm.hasMoreEarlier = false
        return vm
    }

    // MARK: - Load (initial + pagination)

    /// Fetches page 1 (newest 30 messages). Idempotent — skips when
    /// already loaded so preview seeds aren't clobbered.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        oldestLoadedPage = 0
        hasMoreEarlier = true
        await forceLoad()
    }

    private func forceLoad() async {
        guard let threadId else {
            // Preview path — nothing to fetch.
            loadState = .loaded
            return
        }
        loadState = .loading
        do {
            let response = try await api.getChatMessages(id: threadId, page: 1, limit: pageSize)
            oldestLoadedPage = 1
            hasMoreEarlier = (response.data.pagination?.totalPages ?? 1) > 1
            // Server returns newest-first; flip so oldest renders at top.
            let ordered = response.data.messages.reversed()
            items = ordered.map(mapToChatItem(_:))
            loadState = .loaded
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    /// Pulls the next older page and prepends it to `items`. No-op when
    /// `hasMoreEarlier` is false.
    func loadEarlier() async {
        guard hasMoreEarlier, !isLoadingEarlier, let threadId else { return }
        isLoadingEarlier = true
        defer { isLoadingEarlier = false }

        let nextPage = oldestLoadedPage + 1
        do {
            let response = try await api.getChatMessages(id: threadId, page: nextPage, limit: pageSize)
            oldestLoadedPage = nextPage
            let totalPages = response.data.pagination?.totalPages ?? nextPage
            hasMoreEarlier = nextPage < totalPages

            let older = response.data.messages.reversed().map(mapToChatItem(_:))
            items.insert(contentsOf: older, at: 0)
        } catch {
            // Silent — leave hasMoreEarlier alone so user can retry.
        }
    }

    // MARK: - Send (wait-for-ack)

    /// POSTs the current `messageText` and, on success, appends the
    /// server's returned message to `items` and clears the input.
    func sendMessage() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        // Preview / design path — no threadId; just append locally.
        guard let threadId else {
            withAnimation(.easeInOut(duration: 0.2)) {
                items.append(.message(ChatMessage(
                    sender: .me, senderName: myName, body: trimmed, avatarURL: myAvatarURL
                )))
            }
            messageText = ""
            return
        }

        sendError = nil
        isSending = true
        defer { isSending = false }

        let clientMsgId = UUID().uuidString
        do {
            let response = try await api.sendChatMessage(
                id: threadId,
                type: .text,
                content: trimmed,
                clientMsgId: clientMsgId
            )
            let item = mapToChatItem(response.data)
            withAnimation(.easeInOut(duration: 0.2)) {
                items.append(item)
            }
            messageText = ""
        } catch {
            sendError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Mapping

    private func mapToChatItem(_ item: ChatMessageItem) -> ChatItem {
        if item.type == .event, let eventType = item.eventType {
            return .systemEvent(bookingEvent(from: eventType, content: item.content))
        }
        let mine = (item.senderId != nil && item.senderId == myUserId)
        return .message(ChatMessage(
            sender: mine ? .me : .them,
            senderName: mine ? myName : peerName,
            body: item.content ?? "",
            avatarURL: mine ? myAvatarURL : peerAvatarURL
        ))
    }

    /// Maps a booking-lifecycle event to the visual style used by the
    /// sample conversation. Subtitle is the server's `content` if
    /// present (e.g. `"Tomorrow, 2:00 PM"`).
    private func bookingEvent(from event: MessageEventType, content: String?) -> BookingEvent {
        switch event {
        case .bookingRequest:
            return BookingEvent(icon: "envelope", title: "Booking Request",
                                subtitle: content, isAccepted: true, avatarURL: nil)
        case .bookingConfirmed:
            return BookingEvent(icon: "checkmark.square", title: "Booking Confirmed",
                                subtitle: content, isAccepted: true, avatarURL: nil)
        case .bookingDeclined:
            return BookingEvent(icon: "xmark.square", title: "Booking Declined",
                                subtitle: content, isAccepted: false, avatarURL: nil)
        case .bookingCancelled:
            return BookingEvent(icon: "xmark.circle", title: "Booking Cancelled",
                                subtitle: content, isAccepted: false, avatarURL: nil)
        case .bookingRescheduled:
            return BookingEvent(icon: "clock.arrow.circlepath", title: "Booking Rescheduled",
                                subtitle: content, isAccepted: true, avatarURL: nil)
        case .bookingCompleted:
            return BookingEvent(icon: "checkmark.seal", title: "Session Completed",
                                subtitle: content, isAccepted: true, avatarURL: nil)
        case .bookingExpired:
            return BookingEvent(icon: "hourglass", title: "Request Expired",
                                subtitle: content, isAccepted: false, avatarURL: nil)
        }
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
