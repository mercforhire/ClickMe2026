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
    /// Test seams for read receipts; production reads the live socket.
    private let isRealtimeConnected: () -> Bool
    private let emitMessageRead: (UUID, [UUID]) -> Void
    /// Peer message ids a `message.read` has already gone out for in this thread session.
    private var emittedReadIds: Set<UUID> = []

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
    /// The three identity parameters and the two realtime parameters are test
    /// seams: `ChatView` keeps calling the four-argument form and gets the
    /// signed-in user and the live socket.
    init(
        threadId: UUID,
        peerName: String,
        peerAvatarURL: String,
        api: ClickMeAPI = .shared,
        myUserId: UUID? = UserManager.shared.authUser?.id,
        myName: String = UserManager.shared.authUser?.firstName ?? "You",
        myAvatarURL: String = UserManager.shared.authUser?.avatarUrl ?? "",
        isRealtimeConnected: @escaping () -> Bool = { RealtimeService.shared.isConnected },
        emitMessageRead: @escaping (UUID, [UUID]) -> Void = {
            RealtimeService.shared.emitMessageRead(threadId: $0, messageIds: $1)
        }
    ) {
        self.isRealtimeConnected = isRealtimeConnected
        self.emitMessageRead = emitMessageRead
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
        self.isRealtimeConnected = { false }
        self.emitMessageRead = { _, _ in }
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

    /// Pull to refresh. Also lifts the "unavailable" banner, so a person who was
    /// reinstated can be messaged again without leaving the chat.
    func reload() async {
        blockSession.clearRecipientUnavailable()
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
            emitPendingReads()
        } catch {
            loadState = .failed(error.userMessage)
            return
        }
        // After the messages are on screen, so the scan never delays them.
        await refreshThreadInfo()
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

            // Merge, don't prepend: a row already shown is never added twice and
            // older rows land above newer ones in server-time order (D-11).
            let older = response.data.messages.map(mapToChatItem(_:))
            items = ChatThreadReducer.mergePage(items, page: older)
            hydratePeerUserIdIfNeeded(from: response.data.messages)
            emitPendingReads()
        } catch {
            // Silent — leave hasMoreEarlier alone so user can retry.
        }
    }

    // MARK: - Block state (D-07, D-08)

    /// The per-thread block bookkeeping, held as one value (07-CONTEXT size rule).
    @Published private(set) var blockSession = ChatBlockState.Session()
    var blockState: ChatBlockState { blockSession.block }
    var composerMode: ChatBlockState.ComposerMode { blockSession.composerMode }
    /// Bumped when a send is refused as blocked or unavailable; the view announces the banner.
    var refusedBannerToken: Int { blockSession.refusalCount }
    var isUnblocking: Bool { blockSession.isUnblocking }
    @Published var unblockError: String?
    /// A legacy thread with myself, which offers no block or report entry (CANNOT_REPORT_SELF).
    var isSelfThread: Bool { peerUserId != nil && peerUserId == myUserId }

    /// Takes the Block & Report screen's outcome with no reload (wired in plan 07-05).
    func adoptBlockState(_ state: ChatBlockState) { blockSession.adopt(state) }

    /// Posts `unblock` once per tap sequence (D-07, CHAT-UNBLOCK §6); the banner shows it to the blocker only.
    func unblockFromBanner() async {
        guard let threadId, blockSession.beginUnblock() else { return }
        do {
            _ = try await api.chatAction(id: threadId, action: "unblock")
            blockSession.applyUnblockSucceeded()
        } catch {
            unblockError = blockSession.applyUnblockFailure(error)
        }
    }

    // MARK: - Thread info (D-10)

    /// Looks this thread up in `GET /chats`. A listed thread gives the other
    /// person's id from `partner.id`, so View Profile and typing work before any
    /// peer message arrives (D-10), and its block flags (D-07, D-08). An unlisted
    /// thread keeps its block state (an empty thread is not listed); a failed scan
    /// changes nothing and shows no error (UI-SPEC L2). The first-sender rule in
    /// `hydratePeerUserIdIfNeeded` stands in for the id. A scan that finishes after
    /// the block state changed (an unblock, a block adopted from Report & Block, a
    /// refused send) is stale for the block flags and is dropped, so it can never
    /// undo that change.
    func refreshThreadInfo() async {
        guard let threadId else { return }
        let revision = blockSession.revision
        do {
            let thread = try await ChatThreadLookup.find(threadId: threadId, api: api)
            if let thread { peerUserId = thread.partner.id }
            guard revision == blockSession.revision else { return }
            blockSession.applyScan(found: thread.map(ChatBlockState.ScannedBlock.init(thread:)))
        } catch {
            // Lookup failure keeps the composer; the server still enforces the block.
        }
    }

    /// The chat view reappeared, for example after Report & Block or a profile.
    /// Scans again once the thread has loaded; before that `forceLoad` does it.
    func viewDidAppear() {
        guard case .loaded = loadState else { return }
        Task { await refreshThreadInfo() }
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
        case let .refused(code, message):
            // D-03: the server will never accept this text. Take the bubble
            // away and put the text back, ahead of anything typed since. A blocked
            // or unavailable answer switches to the banner and rescans, no alert.
            items = ChatThreadReducer.remove(items, clientMsgId: clientMsgId)
            updateMessageText(ChatSendCoordinator.restoredText(refused: text, draft: messageText))
            guard blockSession.applySendRefusal(code) else { sendError = message; return }
            await refreshThreadInfo()
        }
    }

    /// Applies typed, pasted or restored text to the composer, cut at 10,000 UTF-16
    /// units on a whole-character boundary so the server never refuses a message
    /// for length (D-04). The text a refused send puts back goes through here too.
    func updateMessageText(_ raw: String) {
        messageText = ChatComposerRules.cap(raw)
    }

    // MARK: - Retry and delete (D-01)

    /// Resends a Failed bubble with the `client_msg_id` it was first sent with, so
    /// the server's `UNIQUE(thread_id, sender_id, client_msg_id)` removes the
    /// duplicate if the first attempt did reach it (D-01). The bubble keeps its id,
    /// goes back to Sending and becomes Sent on the ack. Does nothing for a bubble
    /// that is not Failed or whose send is still in flight, so a second tap never
    /// starts a second request, nor while a banner replaces the composer.
    func retrySend(clientMsgId: String) {
        guard let threadId, composerMode == .normal,
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
            },
            RealtimeService.shared.onConnect { [weak self] in
                Task { @MainActor in self?.realtimeDidConnect() }
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
        emitPendingReads()
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

    /// Emits `message.read` for the loaded peer messages that are unread and not
    /// sent yet (D-16): every page loaded and every live peer message. Only loaded
    /// rows are ever listed, never a whole-thread mark (CHAT-07). An id is
    /// recorded as sent only when the socket is connected, because the socket
    /// library drops an emit made while it is not; the rest go out from
    /// `realtimeDidConnect()`.
    private func emitPendingReads() {
        guard let threadId, isRealtimeConnected() else { return }
        let ids = ChatThreadReducer.unreadPeerIds(items, alreadyEmitted: emittedReadIds)
        guard !ids.isEmpty else { return }
        emitMessageRead(threadId, ids)
        emittedReadIds.formUnion(ids)
    }

    /// The socket connected or reconnected: send the receipts held back while it
    /// was not (Pitfall 4). Internal so tests can drive it.
    func realtimeDidConnect() {
        emitPendingReads()
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
}
