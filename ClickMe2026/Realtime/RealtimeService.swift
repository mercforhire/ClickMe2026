//
//  RealtimeService.swift
//  ClickMe2026
//
//  Socket.IO connection to the ClickMe backend. Owns a single
//  `SocketManager` for the whole app; view models subscribe to typed
//  event streams and emit typing / read-receipt updates through this
//  facade. See RealtimeEvents.swift for payload shapes and the
//  backend agent's contract for semantics.
//

import Foundation
import SocketIO

/// A live subscription returned by `RealtimeService.on…` calls.
/// Retain to keep the handler alive; drop the reference (or let it be
/// deallocated with its owner) to auto-unsubscribe. Mirrors the
/// Combine `AnyCancellable` shape.
final class RealtimeSubscription: @unchecked Sendable {
    private let cancel: @Sendable () -> Void
    fileprivate init(cancel: @escaping @Sendable () -> Void) { self.cancel = cancel }
    deinit { cancel() }
}

@MainActor
final class RealtimeService {

    static let shared = RealtimeService()

    // MARK: Connection state

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    /// The JWT the current manager was built with. Kept so we can
    /// no-op `connect(token:)` calls that re-use the same token, and
    /// blow away the manager cleanly on a token change.
    private var connectedToken: String?

    // MARK: Subscribers

    /// Handlers are stored per event by token. Emitting an event walks
    /// the map and invokes each handler; unsubscribe removes by token.
    private var messageNewHandlers: [UUID: @Sendable (RealtimeMessageNewEvent) -> Void] = [:]
    private var messageReadHandlers: [UUID: @Sendable (RealtimeMessageReadEvent) -> Void] = [:]
    private var userStatusHandlers: [UUID: @Sendable (RealtimeUserStatusEvent) -> Void] = [:]
    private var typingStartHandlers: [UUID: @Sendable (RealtimeTypingEvent) -> Void] = [:]
    private var typingStopHandlers: [UUID: @Sendable (RealtimeTypingEvent) -> Void] = [:]
    private var bookingUpdateHandlers: [UUID: @Sendable (RealtimeBookingUpdateEvent) -> Void] = [:]
    private var callEndedHandlers: [UUID: @Sendable (RealtimeCallEndedEvent) -> Void] = [:]

    // MARK: Decoder

    /// Shared decoder for socket payloads. Snake-case → camelCase to
    /// mirror the REST client (see NetworkService.swift), and matches
    /// the backend's server-side JSON convention exactly.
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    // MARK: - Lifecycle

    /// (Re)connects with the caller's JWT. Called from `UserManager`
    /// after login/session-restore, and again after any token refresh.
    /// Idempotent when the token hasn't changed — safe to call from
    /// arbitrary lifecycle hooks without duplicating connections.
    func connect(token: String) {
        if connectedToken == token, socket?.status == .connected {
            return
        }
        disconnect()

        guard let baseURL = URL(string: AppEnvironment.current.baseURL)?
            .deletingLastPathComponent()   // strip `/v1`
            .deletingLastPathComponent()   // strip `/api`
        else {
            return
        }

        let manager = SocketManager(
            socketURL: baseURL,
            config: [
                .log(true),
                .compress,
                .forceWebsockets(true),
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(2)
            ]
        )
        let socket = manager.defaultSocket
        bind(socket: socket)

        self.manager = manager
        self.socket = socket
        self.connectedToken = token

        // JWT rides in the Socket.IO v4 `handshake.auth` payload, not as
        // a URL query param. `.connectParams` sends it via query
        // (which lands in `handshake.query` server-side and the auth
        // middleware silently rejects); `connect(withPayload:)` is the
        // right hatch for Socket.IO-Client-Swift v16.x.
        socket.connect(withPayload: ["token": token])
    }

    /// Tears down the current connection. Called on logout, or as the
    /// first step of a token-changing reconnect.
    func disconnect() {
        socket?.disconnect()
        manager?.disconnect()
        socket = nil
        manager = nil
        connectedToken = nil
    }

    // MARK: - Subscriptions
    //
    // Each `on…` method registers a closure and returns an owning
    // subscription token. Callers keep the returned `RealtimeSubscription`
    // alive to stay subscribed — dropping it cancels. Handlers fire on
    // the main actor.

    func onMessageNew(_ handler: @escaping @Sendable (RealtimeMessageNewEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        messageNewHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.messageNewHandlers.removeValue(forKey: id) }
        }
    }

    func onMessageRead(_ handler: @escaping @Sendable (RealtimeMessageReadEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        messageReadHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.messageReadHandlers.removeValue(forKey: id) }
        }
    }

    func onUserStatus(_ handler: @escaping @Sendable (RealtimeUserStatusEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        userStatusHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.userStatusHandlers.removeValue(forKey: id) }
        }
    }

    func onTypingStart(_ handler: @escaping @Sendable (RealtimeTypingEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        typingStartHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.typingStartHandlers.removeValue(forKey: id) }
        }
    }

    func onTypingStop(_ handler: @escaping @Sendable (RealtimeTypingEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        typingStopHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.typingStopHandlers.removeValue(forKey: id) }
        }
    }

    func onBookingUpdate(_ handler: @escaping @Sendable (RealtimeBookingUpdateEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        bookingUpdateHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.bookingUpdateHandlers.removeValue(forKey: id) }
        }
    }

    func onCallEnded(_ handler: @escaping @Sendable (RealtimeCallEndedEvent) -> Void) -> RealtimeSubscription {
        let id = UUID()
        callEndedHandlers[id] = handler
        return RealtimeSubscription {
            Task { @MainActor in RealtimeService.shared.callEndedHandlers.removeValue(forKey: id) }
        }
    }

    // MARK: - Emit

    /// Emit `message.read` — the caller has seen the listed peer
    /// messages in a thread. Server updates status in the DB and
    /// forwards a receipt to the original sender.
    func emitMessageRead(threadId: UUID, messageIds: [UUID]) {
        guard !messageIds.isEmpty else { return }
        socket?.emit("message.read", [
            "thread_id": threadId.uuidString.lowercased(),
            "message_ids": messageIds.map { $0.uuidString.lowercased() }
        ])
    }

    /// Emit `typing.start` — caller has begun typing in a thread.
    /// Server relays to the partner as `typing.start`.
    func emitTypingStart(threadId: UUID, recipientId: UUID) {
        socket?.emit("typing.start", [
            "thread_id": threadId.uuidString.lowercased(),
            "recipient_id": recipientId.uuidString.lowercased()
        ])
    }

    /// Emit `typing.stop`. Callers should also fire this on
    /// send/blur/timeout so a "…is typing" indicator doesn't stick.
    func emitTypingStop(threadId: UUID, recipientId: UUID) {
        socket?.emit("typing.stop", [
            "thread_id": threadId.uuidString.lowercased(),
            "recipient_id": recipientId.uuidString.lowercased()
        ])
    }

    // MARK: - Wire-up

    /// Attaches all inbound event handlers to a freshly-created socket.
    /// Each handler decodes the raw `[Any]` payload into the typed
    /// event and fans out to registered subscribers.
    private func bind(socket: SocketIOClient) {
        socket.on(clientEvent: .connect) { _, _ in
            // Nothing to do — the server auto-joins the user room on
            // handshake. Kept for future observability hooks.
        }

        socket.on("message.new") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeMessageNewEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.messageNewHandlers.values { handler(event) }
            }
        }

        socket.on("message.read") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeMessageReadEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.messageReadHandlers.values { handler(event) }
            }
        }

        socket.on("user.status") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeUserStatusEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.userStatusHandlers.values { handler(event) }
            }
        }

        socket.on("typing.start") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeTypingEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.typingStartHandlers.values { handler(event) }
            }
        }

        socket.on("typing.stop") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeTypingEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.typingStopHandlers.values { handler(event) }
            }
        }

        socket.on("booking.update") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeBookingUpdateEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.bookingUpdateHandlers.values { handler(event) }
            }
        }

        socket.on("call.ended") { data, _ in
            guard let raw = Self.firstDict(data) else { return }
            Task { @MainActor in
                guard let event: RealtimeCallEndedEvent = RealtimeService.shared.decode(raw) else { return }
                for handler in RealtimeService.shared.callEndedHandlers.values { handler(event) }
            }
        }
    }

    /// Pulls the first JSON-serialisable dictionary out of Socket.IO's
    /// `[Any]` payload envelope and turns it into a `Data` blob so the
    /// hop back to the main actor is Sendable-friendly (raw `[Any]` is
    /// not).
    private static func firstDict(_ raw: [Any]) -> Data? {
        guard let first = raw.first else { return nil }
        return try? JSONSerialization.data(withJSONObject: first)
    }

    /// Decode the pre-serialised payload data into the target event
    /// using the shared snake-case decoder.
    private func decode<T: Decodable>(_ data: Data) -> T? {
        try? decoder.decode(T.self, from: data)
    }
}
