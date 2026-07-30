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
    /// True while a POST to `/chats/:id/send` is in flight. Disables the
    /// input and swaps the send button for a spinner.
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
        self.peerUserId = nil
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
        self.peerUserId = nil
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
            items = response.data.messages.map(mapToChatItem(_:))
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
                    serverId: nil, sender: .me, senderName: myName, body: trimmed,
                    avatarURL: myAvatarURL, timestamp: Date(), status: .sent
                )))
            }
            messageText = ""
            scrollToBottomToken &+= 1
            return
        }

        sendError = nil
        isSending = true
        defer { isSending = false }

        let clientMsgId = UUID().uuidString
        do {
            let ack = try await api.sendChatMessage(
                id: threadId,
                type: .text,
                content: trimmed,
                clientMsgId: clientMsgId
            )
            // Server acks with just id/status/timestamp — reconstruct the
            // full ChatMessageItem locally from the ack + what we already
            // know about the sender (ourselves).
            let localItem = ChatMessageItem(
                id: ack.data.messageId,
                threadId: threadId,
                senderId: myUserId,
                sender: myUserId.map {
                    ChatMessageItem.Sender(
                        id: $0,
                        name: myName,
                        avatarUrl: myAvatarURL.isEmpty ? nil : myAvatarURL
                    )
                },
                type: .text,
                content: trimmed,
                status: ack.data.status,
                clientMsgId: clientMsgId,
                eventType: nil,
                eventData: nil,
                createdAt: ack.data.timestamp
            )
            let item = mapToChatItem(localItem)
            withAnimation(.easeInOut(duration: 0.2)) {
                items.append(item)
            }
            messageText = ""
            scrollToBottomToken &+= 1
            // Whatever debounced `typing.stop` we had queued becomes
            // redundant once the message lands — fire immediately so
            // the peer's indicator drops the moment the bubble appears.
            if let peerId = peerUserId {
                emitTypingStopIfNeeded(threadId: threadId, peerId: peerId)
            }
        } catch {
            sendError = error.userMessage
        }
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
    /// My own echoes are dropped — the send-ack already appended the
    /// local bubble; re-adding here would duplicate.
    private func handleMessageNew(_ event: RealtimeMessageNewEvent) {
        guard event.threadId == threadId else { return }
        if event.senderId == myUserId { return }
        // Dedupe against any bubble we already have with this id
        // (e.g. a race between the socket event and a load that
        // happens to include the same message).
        if items.contains(where: {
            if case let .message(m) = $0 { return m.serverId == event.messageId }
            return false
        }) { return }

        let bubble = ChatMessage(
            serverId: event.messageId,
            sender: .them,
            senderName: peerName,
            body: event.content ?? "",
            avatarURL: peerAvatarURL,
            timestamp: event.timestamp,
            status: event.status
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(.message(bubble))
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

    private func mapToChatItem(_ item: ChatMessageItem) -> ChatItem {
        if item.type == .event, let eventType = item.eventType {
            return .systemEvent(bookingEvent(
                from: eventType,
                content: item.content,
                eventData: item.eventData
            ))
        }
        let mine = (item.senderId != nil && item.senderId == myUserId)
        // Prefer server-provided sender info for the peer; fall back to
        // the caller-supplied peer identity for older payloads.
        let displayName = mine
            ? myName
            : (item.sender?.name ?? peerName)
        let displayAvatar = mine
            ? myAvatarURL
            : (item.sender?.avatarUrl ?? peerAvatarURL)
        return .message(ChatMessage(
            serverId: item.id,
            sender: mine ? .me : .them,
            senderName: displayName,
            body: item.content ?? "",
            avatarURL: displayAvatar,
            timestamp: item.createdAt,
            status: item.status
        ))
    }

    /// Maps a booking-lifecycle event to the visual style used by the
    /// sample conversation. Subtitle is the server's `content` if
    /// present (e.g. `"Tomorrow, 2:00 PM"`). `eventData` carries the
    /// server's `{ booking_id, client_id, expert_id, start_time,
    /// end_time, duration_mins, topic_title }` payload — the display
    /// metadata is pulled out so the row can render the booking's topic
    /// name and time inline without a per-row fetch.
    private func bookingEvent(
        from event: MessageEventType,
        content: String?,
        eventData: JSONValue?
    ) -> BookingEvent {
        let bookingId = Self.extractBookingId(from: eventData)
        let topicTitle = Self.extractString(from: eventData, key: "topic_title")
        let startTime = Self.extractDate(from: eventData, key: "start_time")
        let durationMins = Self.extractInt(from: eventData, key: "duration_mins")
        let terminal = Self.isTerminal(event)

        switch event {
        case .bookingRequest:
            return BookingEvent(icon: "envelope", title: "Booking Request",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingConfirmed:
            return BookingEvent(icon: "checkmark.square", title: "Booking Confirmed",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingDeclined:
            return BookingEvent(icon: "xmark.square", title: "Booking Declined",
                                subtitle: content, isAccepted: false, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingCancelled:
            return BookingEvent(icon: "xmark.circle", title: "Booking Cancelled",
                                subtitle: content, isAccepted: false, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingRescheduled:
            return BookingEvent(icon: "clock.arrow.circlepath", title: "Booking Rescheduled",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingCompleted:
            return BookingEvent(icon: "checkmark.seal", title: "Session Completed",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingExpired:
            return BookingEvent(icon: "hourglass", title: "Request Expired",
                                subtitle: content, isAccepted: false, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        }
    }

    /// Whether a booking event represents a finished lifecycle state
    /// (nothing more will happen). Decides whether tapping the row
    /// routes to the read-only summary or the still-actionable
    /// upcoming-booking screen.
    private static func isTerminal(_ event: MessageEventType) -> Bool {
        switch event {
        case .bookingDeclined, .bookingCancelled, .bookingCompleted, .bookingExpired:
            return true
        case .bookingRequest, .bookingConfirmed, .bookingRescheduled:
            return false
        }
    }

    /// Pulls `booking_id` out of the server's `event_data` payload.
    /// Returns nil for legacy events that predate this field or if the
    /// value isn't a valid UUID string.
    private static func extractBookingId(from data: JSONValue?) -> UUID? {
        guard case let .object(dict) = data,
              case let .string(str) = dict["booking_id"] else { return nil }
        return UUID(uuidString: str)
    }

    /// Reads a string field from the server's `event_data` object.
    /// Nil when the payload isn't an object or the field is missing.
    private static func extractString(from data: JSONValue?, key: String) -> String? {
        guard case let .object(dict) = data,
              case let .string(str) = dict[key] else { return nil }
        return str
    }

    /// Reads an integer field from `event_data`. Accepts both raw ints
    /// and stringly-typed numbers (some backends stringify small ints).
    private static func extractInt(from data: JSONValue?, key: String) -> Int? {
        guard case let .object(dict) = data else { return nil }
        switch dict[key] {
        case .int(let v): return v
        case .string(let s): return Int(s)
        case .double(let d): return Int(d)
        default: return nil
        }
    }

    /// Parses an ISO 8601 timestamp field from `event_data`. Fractional
    /// seconds are optional; the server currently emits them
    /// (`.424+00:00`) but we accept both for safety.
    private static let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static func extractDate(from data: JSONValue?, key: String) -> Date? {
        guard let str = extractString(from: data, key: key) else { return nil }
        return isoWithFraction.date(from: str) ?? isoNoFraction.date(from: str)
    }

    // MARK: - Error mapping

}
