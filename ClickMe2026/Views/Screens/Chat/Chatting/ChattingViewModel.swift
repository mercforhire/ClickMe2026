//
//  ChattingViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ChattingViewModel: ObservableObject {


    // MARK: Identity
    let threadId: UUID?
    let peerName: String
    let peerAvatarURL: String
    /// My display fields — seeded from `UserManager.shared.authUser` at
    /// init, hydrated from `/me` + `/user/profile` in `load()` when the
    /// auth snapshot isn't populated (preview harness, cold launch race).
    /// Published so the input-bar avatar re-renders after hydration.
    @Published private(set) var myAvatarURL: String
    @Published private(set) var myName: String
    /// Auth-user id used to tag `.me` vs. `.them`. Nil until hydrated.
    @Published private var myUserId: UUID?
    /// Peer's user id — derived from the first non-`.me` message we
    /// see. Nil for empty threads (no messages yet) or preview seeds.
    /// Drives the "View Profile" menu action.
    @Published private(set) var peerUserId: UUID?

    // MARK: View state
    @Published var items: [ChatItem]
    @Published var messageText: String
    @Published var showMenu: Bool

    @Published var loadState: LoadState = .idle
    /// No longer set: sends are optimistic (D-01) and the composer stays
    /// usable. Plan 07-02 deletes this flag with the input bar's spinner.
    @Published var isSending: Bool = false
    /// Non-fatal error surfaced from the send-message call.
    @Published var sendError: String?
    /// True while paginating older history in via `loadEarlier()`.
    @Published var isLoadingEarlier: Bool = false
    /// False once the server signals there are no more pages left.
    @Published var hasMoreEarlier: Bool = true

    /// Bumped whenever the view should scroll to the bottom of the
    /// conversation — after the initial fetch and after a successful
    /// send. Deliberately NOT bumped by `loadEarlier`, which prepends
    /// older history and should leave the scroll position alone.
    @Published var scrollToBottomToken: Int = 0

    // MARK: Pagination cursor

    private var oldestLoadedPage: Int = 0

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let pageSize: Int = 30
    /// Owns every send in flight, so this type keeps no send bookkeeping.
    private let sendCoordinator: ChatSendCoordinator

    /// Live subscriptions to `RealtimeService`. Auto-cancel when the
    /// VM is deallocated because each `RealtimeSubscription` fires its
    /// closure in its own `deinit`. Rebuilt on every `attachRealtime()`.
    private var realtimeSubscriptions: [RealtimeSubscription] = []

    /// True while the peer's socket has emitted `typing.start` without a
    /// matching `typing.stop`. Auto-clears via `peerTypingTimeoutTask`
    /// after 6s so a dropped stop event doesn't strand the indicator on
    /// screen.
    @Published private(set) var peerIsTyping: Bool = false
    private var peerTypingTimeoutTask: Task<Void, Never>?

    /// True while our own client has emitted `typing.start` since the
    /// last debounced `typing.stop`. Prevents chatty re-emits on every
    /// keystroke.
    private var iAmTyping: Bool = false
    private var mySelfStopTask: Task<Void, Never>?
    /// How long a silence counts as "stopped typing". Roughly matches
    /// the WhatsApp/Slack cadence and keeps the peer's indicator from
    /// flickering during natural pauses.
    private let typingIdleWindow: UInt64 = 3_000_000_000 // 3s

    // MARK: - Runtime init

    /// Runtime init — fetches messages from `GET /chats/:id/messages`.
    ///
    /// The three identity parameters are a test seam: `ChatView` keeps calling
    /// the four-argument form and gets the signed-in user.
    init(
        threadId: UUID,
        peerName: String,
        peerAvatarURL: String,
        api: ClickMeAPI = .shared,
        myUserId: UUID? = UserManager.shared.authUser?.id,
        myName: String = UserManager.shared.authUser?.firstName ?? "You",
        myAvatarURL: String = UserManager.shared.authUser?.avatarUrl ?? ""
    ) {
        self.threadId = threadId
        self.peerName = peerName
        self.peerAvatarURL = peerAvatarURL
        self.myAvatarURL = myAvatarURL
        self.myName = myName
        self.myUserId = myUserId
        self.peerUserId = nil
        self.items = []
        self.messageText = ""
        self.showMenu = false
        self.api = api
        self.sendCoordinator = ChatSendCoordinator(api: api)
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
        self.peerUserId = nil
        self.items = items
        self.messageText = messageText
        self.showMenu = showMenu
        self.api = .shared
        self.sendCoordinator = ChatSendCoordinator(api: .shared)
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
        // Hydrate our own identity first so message mapping can tag
        // `.me` vs. `.them` correctly. Silent on failure — falls back
        // to whatever seed values we already have.
        await hydrateIdentityIfNeeded()

        do {
            let response = try await api.getChatMessages(id: threadId, page: 1, limit: pageSize)
            oldestLoadedPage = 1
            hasMoreEarlier = (response.data.pagination?.totalPages ?? 1) > 1
            // Server pages contain the newest bucket on page 1, ordered
            // oldest-first *within* the page — exactly the display order.
            // Rendered top-to-bottom that puts the latest message at the
            // bottom of the scroll view.
            // Merge, don't replace: a pending or failed bubble is not on the
            // server yet and must survive a reload (Pitfall 1).
            items = ChatThreadReducer.mergePage(items, page: response.data.messages.map(mapToChatItem(_:)))
            hydratePeerUserIdIfNeeded(from: response.data.messages)
            loadState = .loaded
            scrollToBottomToken &+= 1
            attachRealtime()
            emitReadForVisiblePeerMessages()
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// Populates `myUserId`, `myAvatarURL`, and `myName` when the auth
    /// snapshot isn't loaded yet. Called from `forceLoad()` before the
    /// message fetch so the mine-vs-them mapping works even in preview
    /// harnesses (where the login flow was skipped) or cold-launch races.
    private func hydrateIdentityIfNeeded() async {
        if myUserId == nil {
            if let id = UserManager.shared.authUser?.id {
                myUserId = id
            } else if let me = try? await api.getMe().data {
                myUserId = me.id
            }
        }

        if myAvatarURL.isEmpty || myName.isEmpty || myName == "You" {
            if let profile = try? await api.getUserProfile().data {
                if myAvatarURL.isEmpty, let url = profile.personalDetails.avatarUrl {
                    myAvatarURL = url
                }
                if myName.isEmpty || myName == "You",
                   let first = profile.personalDetails.firstName, !first.isEmpty {
                    myName = first
                }
            }
        }
    }

    /// Latches `peerUserId` to the first sender we see that isn't us.
    /// Called after every fetch; short-circuits once populated so an
    /// admin-broadcast row later in the thread can't overwrite the real
    /// counterparty. Nil on threads with zero peer messages so far —
    /// the "View Profile" menu button becomes a no-op in that case.
    private func hydratePeerUserIdIfNeeded(from messages: [ChatMessageItem]) {
        guard peerUserId == nil else { return }
        peerUserId = messages
            .compactMap(\.senderId)
            .first { $0 != myUserId }
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

            let older = response.data.messages.map(mapToChatItem(_:))
            items.insert(contentsOf: older, at: 0)
            hydratePeerUserIdIfNeeded(from: response.data.messages)
        } catch {
            // Silent — leave hasMoreEarlier alone so user can retry.
        }
    }

    // MARK: - Send (optimistic, D-01)

    /// Appends the current `messageText` as a pending bubble at once, clears the
    /// composer and starts the POST. The bubble is added before the first
    /// suspension point, so it is on screen before the request goes out. The
    /// ack, a failure or a refusal later updates that same bubble through
    /// `applySendOutcome`.
    func sendMessage() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Preview / design path — no threadId; just append locally.
        guard let threadId else {
            withAnimation(.easeInOut(duration: 0.2)) {
                items.append(.message(ChatMessage(
                    serverId: nil, sender: .me, senderName: myName, body: trimmed,
                    avatarURL: myAvatarURL, timestamp: Date(), status: .sent
                )))
            }
            messageText = ""
            scrollToBottomToken &+= 1
            return
        }

        sendError = nil
        let clientMsgId = UUID().uuidString
        let bubble = ChatMessage(
            serverId: nil, sender: .me, senderName: myName, body: trimmed,
            avatarURL: myAvatarURL, timestamp: Date(), status: .sent,
            clientMsgId: clientMsgId, sendState: .sending
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            items = ChatThreadReducer.appendLocal(items, bubble)
        }
        messageText = ""
        scrollToBottomToken &+= 1
        startSend(threadId: threadId, clientMsgId: clientMsgId, text: trimmed)
    }

    /// Hands one send to the coordinator. `retrySend` reuses it with the bubble's
    /// existing `clientMsgId`.
    private func startSend(threadId: UUID, clientMsgId: String, text: String) {
        sendCoordinator.send(threadId: threadId, clientMsgId: clientMsgId, text: text) { [weak self] outcome in
            await self?.applySendOutcome(outcome, clientMsgId: clientMsgId, text: text)
        }
    }

    /// Applies how a POST ended to the bubble that sent it.
    private func applySendOutcome(
        _ outcome: ChatSendCoordinator.Outcome,
        clientMsgId: String,
        text: String
    ) async {
        switch outcome {
        case let .acked(messageId, timestamp, status):
            items = ChatThreadReducer.ack(
                items,
                clientMsgId: clientMsgId,
                serverId: messageId,
                timestamp: timestamp,
                status: status
            )
            // Whatever debounced `typing.stop` we had queued becomes
            // redundant once the message lands — fire immediately so
            // the peer's indicator drops the moment the bubble settles.
            if let threadId, let peerId = peerUserId {
                emitTypingStopIfNeeded(threadId: threadId, peerId: peerId)
            }
        case .keptAsFailed:
            items = ChatThreadReducer.fail(items, clientMsgId: clientMsgId)
        case let .refused(_, message):
            // D-03: the server will never accept this text. Take the bubble
            // away and put the text back, ahead of anything typed since.
            // Plan 07-04 splits this branch by error code.
            items = ChatThreadReducer.remove(items, clientMsgId: clientMsgId)
            messageText = ChatSendCoordinator.restoredText(refused: text, draft: messageText)
            sendError = message
        }
    }

    // MARK: - Retry and delete (D-01)

    /// Resends a Failed bubble with the `client_msg_id` it was first sent with, so
    /// the server's `UNIQUE(thread_id, sender_id, client_msg_id)` removes the
    /// duplicate if the first attempt did reach it (D-01). The bubble keeps its id,
    /// goes back to Sending and becomes Sent on the ack. Does nothing for a bubble
    /// that is not Failed or whose send is still in flight, so a second tap never
    /// starts a second request.
    func retrySend(clientMsgId: String) {
        guard let threadId,
              let bubble = ChatThreadReducer.findMine(items, clientMsgId: clientMsgId),
              bubble.sendState == .failed,
              !sendCoordinator.isInFlight(clientMsgId)
        else { return }
        items = ChatThreadReducer.retry(items, clientMsgId: clientMsgId)
        startSend(threadId: threadId, clientMsgId: clientMsgId, text: bubble.body)
    }

    /// Throws a Failed bubble away (D-01). Local only: no request is made, and
    /// nothing was ever stored (D-02). A bubble that is Sending or Sent stays.
    func deleteFailedMessage(clientMsgId: String) {
        guard let bubble = ChatThreadReducer.findMine(items, clientMsgId: clientMsgId),
              bubble.sendState == .failed,
              !sendCoordinator.isInFlight(clientMsgId)
        else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            items = ChatThreadReducer.remove(items, clientMsgId: clientMsgId)
        }
    }

    /// Awaits every send in flight. Used by tests.
    func awaitInFlightSends() async {
        await sendCoordinator.awaitAll()
    }

    // MARK: - Realtime (Socket.IO)

    /// (Re)subscribes to the events that matter for a single-thread
    /// view. Called after each successful `forceLoad` so a `reload()`
    /// (which resets `loadState`) also refreshes the wiring. Old
    /// subscriptions are released via ARC when the array is replaced.
    private func attachRealtime() {
        realtimeSubscriptions = [
            RealtimeService.shared.onMessageNew { [weak self] event in
                Task { @MainActor in self?.handleMessageNew(event) }
            },
            RealtimeService.shared.onMessageRead { [weak self] event in
                Task { @MainActor in self?.handleMessageRead(event) }
            },
            RealtimeService.shared.onTypingStart { [weak self] event in
                Task { @MainActor in self?.handleTypingStart(event) }
            },
            RealtimeService.shared.onTypingStop { [weak self] event in
                Task { @MainActor in self?.handleTypingStop(event) }
            }
        ]
    }

    /// Live message arrived. Ignore anything not in this thread. Peer
    /// messages are appended, scrolled to, and immediately acked with
    /// a `message.read` so the sender's ticks flip in real time.
    /// My own echoes and a server id already shown add nothing
    /// (`ChatThreadReducer.onIncoming`); re-adding would duplicate.
    /// Internal so tests can drive it.
    func handleMessageNew(_ event: RealtimeMessageNewEvent) {
        guard event.threadId == threadId else { return }
        let bubble = ChatMessage(
            serverId: event.messageId,
            sender: .them,
            senderName: peerName,
            body: event.content ?? "",
            avatarURL: peerAvatarURL,
            timestamp: event.timestamp,
            status: event.status
        )
        let updated = ChatThreadReducer.onIncoming(
            items, bubble, senderId: event.senderId, myId: myUserId
        )
        // The reducer returns `items` untouched when it ignores the event.
        guard updated.count != items.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            items = updated
        }
        if peerUserId == nil { peerUserId = event.senderId }
        scrollToBottomToken &+= 1

        // The user is looking at this bubble right now — mark it read.
        RealtimeService.shared.emitMessageRead(
            threadId: event.threadId,
            messageIds: [event.messageId]
        )
    }

    /// Receipt: the peer just read some of my sent messages. Flip
    /// matching bubbles' `status` so the "Delivered/Read" affordance
    /// re-renders.
    private func handleMessageRead(_ event: RealtimeMessageReadEvent) {
        guard event.threadId == threadId else { return }
        let readSet = Set(event.messageIds)
        for i in items.indices {
            guard case var .message(msg) = items[i],
                  msg.sender == .me,
                  let sid = msg.serverId,
                  readSet.contains(sid),
                  msg.status != .read else { continue }
            msg.status = .read
            items[i] = .message(msg)
        }
    }

    // MARK: Typing indicator — incoming

    private func handleTypingStart(_ event: RealtimeTypingEvent) {
        guard event.threadId == threadId, event.senderId != myUserId else { return }
        peerIsTyping = true
        peerTypingTimeoutTask?.cancel()
        peerTypingTimeoutTask = Task { [weak self] in
            // Safety net — if a `typing.stop` is dropped, this ensures
            // the indicator disappears rather than sticking on screen.
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard !Task.isCancelled else { return }
            self?.peerIsTyping = false
        }
    }

    private func handleTypingStop(_ event: RealtimeTypingEvent) {
        guard event.threadId == threadId, event.senderId != myUserId else { return }
        peerTypingTimeoutTask?.cancel()
        peerTypingTimeoutTask = nil
        peerIsTyping = false
    }

    // MARK: Typing indicator — outgoing

    /// Called by the view when `messageText` changes. Emits
    /// `typing.start` on the first non-empty edit after a quiet period,
    /// then schedules a debounced `typing.stop` for after
    /// `typingIdleWindow` of silence. Cheap to call on every keystroke.
    func notifyMessageTextChanged() {
        guard let threadId, let peerId = peerUserId else { return }
        let hasText = !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !hasText {
            emitTypingStopIfNeeded(threadId: threadId, peerId: peerId)
            return
        }

        if !iAmTyping {
            RealtimeService.shared.emitTypingStart(threadId: threadId, recipientId: peerId)
            iAmTyping = true
        }

        mySelfStopTask?.cancel()
        mySelfStopTask = Task { [weak self] in
            guard let debounce = self?.typingIdleWindow else { return }
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            self?.emitTypingStopIfNeeded(threadId: threadId, peerId: peerId)
        }
    }

    private func emitTypingStopIfNeeded(threadId: UUID, peerId: UUID) {
        guard iAmTyping else { return }
        RealtimeService.shared.emitTypingStop(threadId: threadId, recipientId: peerId)
        iAmTyping = false
        mySelfStopTask?.cancel()
        mySelfStopTask = nil
    }

    /// Emits `message.read` for every peer bubble currently in `items`
    /// that hasn't already been marked `.read`. Called on initial load
    /// so opening a thread with a badge zeroes it out on the server.
    private func emitReadForVisiblePeerMessages() {
        guard let threadId else { return }
        let unread: [UUID] = items.compactMap {
            guard case let .message(m) = $0,
                  m.sender == .them,
                  m.status != .read,
                  let sid = m.serverId else { return nil }
            return sid
        }
        guard !unread.isEmpty else { return }
        RealtimeService.shared.emitMessageRead(threadId: threadId, messageIds: unread)
    }

    // MARK: - Mapping

    /// Thin forwarder so `forceLoad()` and `loadEarlier()` keep their call
    /// sites; the mapping itself lives in `ChatItemMapper`.
    private func mapToChatItem(_ item: ChatMessageItem) -> ChatItem {
        ChatItemMapper.chatItem(
            from: item,
            identity: ChatItemMapper.Identity(
                myUserId: myUserId,
                myName: myName,
                myAvatarURL: myAvatarURL,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            )
        )
    }

    // MARK: - Error mapping

}
