//
//  ChattingViewModelSendTests.swift
//  ClickMe2026Tests
//
//  CHAT-01 (D-01, D-03): a sent message appears at once as a pending bubble,
//  the 201 ack updates that same bubble in place, a network or server failure
//  leaves a Failed bubble, and a refused send returns its text to the composer.
//  Reloads and live events merge through ChatThreadReducer, so they never drop
//  a pending or failed bubble and never add a message twice.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat thread send", .serialized)
@MainActor
struct ChattingViewModelSendTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let threadId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
    nonisolated private static let myId = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
    /// Exactly representable and one millisecond-safe, so the ISO round trip is lossless.
    nonisolated private static let ackTime = Date(timeIntervalSince1970: 1_800_000_000.5)

    typealias Responder = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    // MARK: Stub helpers

    nonisolated private static func isSend(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/send") == true
    }

    nonisolated private static func sendPosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isSend)
    }

    /// A 201 ack whose message id is the request's own `client_msg_id`, so every send gets its own id.
    /// The server time is `ackTime`, plus one second for the text "b", so two sends have distinct
    /// server times in send order however their acks interleave.
    nonisolated private static let ackResponder: Responder = { request in
        let json = request.jsonBodyForTest()
        let clientMsgId = json?["client_msg_id"] as? String ?? ""
        let messageId = UUID(uuidString: clientMsgId) ?? UUID()
        let time = ackTime.addingTimeInterval(json?["content"] as? String == "b" ? 1 : 0)
        let body = ChatFixtures.ack(messageId: messageId, timestamp: time)
        return Fixtures.response(for: request, status: 201, body: body)
    }

    nonisolated private static func errorResponder(status: Int, code: String, message: String) -> Responder {
        { request in
            Fixtures.response(for: request, status: status, body: Fixtures.errorBody(code: code, message: message))
        }
    }

    nonisolated private static let offlineResponder: Responder = { _ in
        throw URLError(.notConnectedToInternet)
    }

    nonisolated private static func isMessagesGet(_ request: URLRequest) -> Bool {
        request.httpMethod == "GET" && request.url?.path.hasSuffix("/messages") == true
    }

    private static func makeAPI(
        onSend: @escaping Responder,
        onMessages: Responder? = nil
    ) -> ClickMeAPI {
        APITestFactory.make { request in
            if isSend(request) { return try onSend(request) }
            if isMessagesGet(request), let onMessages { return try onMessages(request) }
            return Fixtures.response(
                for: request,
                status: 404,
                body: Fixtures.errorBody(code: "NOT_FOUND", message: "Not found")
            )
        }
    }

    /// A view model with a non-empty identity, so no `/me` or `/user/profile` request is made.
    private func makeViewModel(onSend: @escaping Responder, onMessages: Responder? = nil) -> ChattingViewModel {
        ChattingViewModel(
            threadId: Self.threadId,
            peerName: "Peer",
            peerAvatarURL: "",
            api: Self.makeAPI(onSend: onSend, onMessages: onMessages),
            myUserId: Self.myId,
            myName: "Me",
            myAvatarURL: "https://example.invalid/me.png"
        )
    }

    private func messages(_ viewModel: ChattingViewModel) -> [ChatMessage] {
        viewModel.items.compactMap {
            if case let .message(message) = $0 { return message }
            return nil
        }
    }

    // MARK: Optimistic append and ack

    @Test("send appends a pending bubble at once, then the ack updates that same bubble")
    func pendingBubbleThenAckKeepsTheSameBubble() async throws {
        let viewModel = makeViewModel(onSend: Self.ackResponder)
        viewModel.messageText = "hello"
        let tokenBefore = viewModel.scrollToBottomToken

        await viewModel.sendMessage()

        let pending = try #require(messages(viewModel).last)
        #expect(pending.sender == .me)
        #expect(pending.body == "hello")
        #expect(pending.sendState == .sending)
        #expect(pending.clientMsgId != nil)
        #expect(pending.serverId == nil)
        #expect(viewModel.messageText == "")
        #expect(viewModel.scrollToBottomToken == tokenBefore + 1)

        await viewModel.awaitInFlightSends()

        let acked = try #require(messages(viewModel).last)
        #expect(messages(viewModel).count == 1)
        #expect(acked.id == pending.id)
        #expect(acked.serverId == UUID(uuidString: try #require(pending.clientMsgId)))
        #expect(acked.timestamp == Self.ackTime)
        #expect(acked.sendState == .sent)

        let posts = Self.sendPosts()
        #expect(posts.count == 1)
        let body = try #require(posts.first?.jsonBodyForTest())
        #expect(body["client_msg_id"] as? String == pending.clientMsgId)
        #expect(body["content"] as? String == "hello")
    }

    @Test("two sends before any ack keep append order and both end up sent")
    func twoSendsInFlightAtOnce() async throws {
        let viewModel = makeViewModel(onSend: Self.ackResponder)

        viewModel.messageText = "a"
        await viewModel.sendMessage()
        viewModel.messageText = "b"
        await viewModel.sendMessage()

        #expect(messages(viewModel).map(\.body) == ["a", "b"])
        #expect(messages(viewModel).allSatisfy { $0.sendState == .sending })

        await viewModel.awaitInFlightSends()

        #expect(messages(viewModel).map(\.body) == ["a", "b"])
        #expect(messages(viewModel).allSatisfy { $0.sendState == .sent })
        let posts = Self.sendPosts()
        #expect(posts.count == 2)
        let ids = Set(posts.compactMap { $0.jsonBodyForTest()?["client_msg_id"] as? String })
        #expect(ids.count == 2)
    }

    // MARK: Failures that keep the bubble

    @Test("a 500 keeps the bubble in place as failed, with no alert")
    func serverErrorKeepsTheBubbleAsFailed() async throws {
        let viewModel = makeViewModel(onSend: Self.errorResponder(status: 500, code: "INTERNAL_ERROR", message: "Boom"))
        viewModel.messageText = "hello"
        await viewModel.sendMessage()
        let id = try #require(messages(viewModel).last).id

        await viewModel.awaitInFlightSends()

        let failed = try #require(messages(viewModel).last)
        #expect(messages(viewModel).count == 1)
        #expect(failed.id == id)
        #expect(failed.sendState == .failed)
        #expect(viewModel.sendError == nil)
    }

    @Test("a transport failure keeps the bubble in place as failed, with no alert")
    func transportFailureKeepsTheBubbleAsFailed() async throws {
        let viewModel = makeViewModel(onSend: Self.offlineResponder)
        viewModel.messageText = "hello"
        await viewModel.sendMessage()

        await viewModel.awaitInFlightSends()

        let failed = try #require(messages(viewModel).last)
        #expect(failed.sendState == .failed)
        #expect(viewModel.sendError == nil)
    }

    // MARK: Refusals that return the text

    @Test("a 422 removes the bubble, restores the text and shows the server's reason")
    func validationRefusalRestoresTheText() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 422, code: "VALIDATION_ERROR", message: "Bad text")
        )
        viewModel.messageText = "hello"
        await viewModel.sendMessage()

        await viewModel.awaitInFlightSends()

        #expect(messages(viewModel).isEmpty)
        #expect(viewModel.messageText == "hello")
        #expect(viewModel.sendError == "Bad text")
    }

    @Test("a refused send puts its text ahead of what was typed since, on its own line")
    func refusalRestoresAheadOfTheDraft() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 422, code: "VALIDATION_ERROR", message: "Bad text")
        )
        viewModel.messageText = "first"
        await viewModel.sendMessage()
        viewModel.messageText = "draft"

        await viewModel.awaitInFlightSends()

        #expect(viewModel.messageText == "first\ndraft")
    }

    @Test("a 403 THREAD_BLOCKED takes the refused path until plan 07-04")
    func blockedThreadIsRefusedForNow() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 403, code: "THREAD_BLOCKED", message: "You can't message this person")
        )
        viewModel.messageText = "hello"
        await viewModel.sendMessage()

        await viewModel.awaitInFlightSends()

        #expect(messages(viewModel).isEmpty)
        #expect(viewModel.messageText == "hello")
        #expect(viewModel.sendError != nil)
    }

    // MARK: Empty input

    @Test("whitespace-only text appends nothing and makes no request")
    func whitespaceOnlySendsNothing() async throws {
        let viewModel = makeViewModel(onSend: Self.ackResponder)
        viewModel.messageText = "   \n"

        await viewModel.sendMessage()
        await viewModel.awaitInFlightSends()

        #expect(viewModel.items.isEmpty)
        #expect(MockURLProtocol.recordedRequests.isEmpty)
    }

    // MARK: Coordinator

    @Test("a second send for a client_msg_id already in flight makes no request")
    func coordinatorIgnoresADuplicateInFlight() async throws {
        let api = Self.makeAPI(onSend: Self.ackResponder)
        let coordinator = ChatSendCoordinator(api: api)
        let clientMsgId = UUID().uuidString

        coordinator.send(threadId: Self.threadId, clientMsgId: clientMsgId, text: "x") { _ in }
        coordinator.send(threadId: Self.threadId, clientMsgId: clientMsgId, text: "x") { _ in }
        #expect(coordinator.isInFlight(clientMsgId))

        await coordinator.awaitAll()

        #expect(!coordinator.isInFlight(clientMsgId))
        #expect(Self.sendPosts().count == 1)
    }

    // MARK: Reload and live events (Pitfall 1)

    /// Carries a value from the test body into a `@Sendable` stub closure.
    private final class Box: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: String?
        var value: String? {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    nonisolated private static let peerId = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
    nonisolated private static let pageTime = Date(timeIntervalSince1970: 1_800_000_100)

    nonisolated private static func peerRow(_ n: Int, at offset: TimeInterval) -> String {
        ChatFixtures.message(
            id: UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!,
            senderId: peerId,
            content: "peer \(n)",
            createdAt: pageTime.addingTimeInterval(offset)
        )
    }

    private func newEvent(
        id: UUID = UUID(),
        threadId: UUID = ChattingViewModelSendTests.threadId,
        senderId: UUID = ChattingViewModelSendTests.peerId
    ) -> RealtimeMessageNewEvent {
        RealtimeMessageNewEvent(
            messageId: id,
            threadId: threadId,
            senderId: senderId,
            type: .text,
            content: "live",
            timestamp: Self.pageTime,
            status: .sent
        )
    }

    @Test("a reload whose page holds a pending bubble's client_msg_id keeps one row, with the bubble's id")
    func reloadCollapsesIntoThePendingBubble() async throws {
        let clientMsgId = Box()
        let viewModel = makeViewModel(onSend: Self.ackResponder) { request in
            // The server has the message: the page carries the sender's own row.
            let mineId = UUID(uuidString: clientMsgId.value ?? "") ?? UUID()
            let row = ChatFixtures.message(
                id: mineId,
                senderId: Self.myId,
                content: "hello",
                clientMsgId: clientMsgId.value,
                createdAt: Self.ackTime
            )
            return Fixtures.response(for: request, body: ChatFixtures.messagesPage([row]))
        }
        viewModel.messageText = "hello"
        await viewModel.sendMessage()
        let pending = try #require(messages(viewModel).last)
        clientMsgId.value = pending.clientMsgId

        await viewModel.reload()
        await viewModel.awaitInFlightSends()

        let rows = messages(viewModel)
        #expect(rows.count == 1)
        #expect(rows.first?.id == pending.id)
        #expect(rows.first?.sendState == .sent)
        #expect(rows.first?.serverId != nil)
    }

    @Test("a reload without a failed bubble keeps it, after the server rows")
    func reloadKeepsAFailedBubble() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 500, code: "INTERNAL_ERROR", message: "Boom")
        ) { request in
            Fixtures.response(
                for: request,
                body: ChatFixtures.messagesPage([Self.peerRow(1, at: 0), Self.peerRow(2, at: 10)])
            )
        }
        viewModel.messageText = "hello"
        await viewModel.sendMessage()
        await viewModel.awaitInFlightSends()
        let failedId = try #require(messages(viewModel).last).id

        await viewModel.reload()

        let rows = messages(viewModel)
        #expect(rows.map(\.body) == ["peer 1", "peer 2", "hello"])
        #expect(rows.last?.id == failedId)
        #expect(rows.last?.sendState == .failed)
    }

    @Test("a live message for another thread, from me, or already shown adds no row")
    func liveMessageIgnoresForeignOwnAndKnownIds() async throws {
        let shown = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
        let viewModel = makeViewModel(onSend: Self.ackResponder) { request in
            Fixtures.response(for: request, body: ChatFixtures.messagesPage([Self.peerRow(1, at: 0)]))
        }
        await viewModel.load()
        #expect(messages(viewModel).count == 1)

        viewModel.handleMessageNew(newEvent(threadId: UUID()))
        viewModel.handleMessageNew(newEvent(senderId: Self.myId))
        viewModel.handleMessageNew(newEvent(id: shown))
        #expect(messages(viewModel).count == 1)

        viewModel.handleMessageNew(newEvent())
        #expect(messages(viewModel).count == 2)
    }

    @Test("load maps client_msg_id onto a message row and the id and time onto an event row")
    func loadCarriesClientMsgIdAndEventIds() async throws {
        let mineId = UUID(uuidString: "00000000-0000-4000-8000-0000000000a1")!
        let eventId = UUID(uuidString: "00000000-0000-4000-8000-0000000000e1")!
        let eventTime = Self.pageTime.addingTimeInterval(5)
        let viewModel = makeViewModel(onSend: Self.ackResponder) { request in
            let rows = [
                ChatFixtures.message(
                    id: mineId, senderId: Self.myId, content: "mine", clientMsgId: "abc", createdAt: Self.pageTime
                ),
                ChatFixtures.event(id: eventId, createdAt: eventTime)
            ]
            return Fixtures.response(for: request, body: ChatFixtures.messagesPage(rows))
        }

        await viewModel.load()

        let message = try #require(messages(viewModel).first)
        #expect(message.clientMsgId == "abc")
        #expect(message.sender == .me)
        let event = try #require(viewModel.items.compactMap { item -> BookingEvent? in
            if case let .systemEvent(event) = item { return event }
            return nil
        }.first)
        #expect(event.serverId == eventId)
        #expect(event.createdAt == eventTime)
        let eventItem = try #require(viewModel.items.last)
        #expect(eventItem.serverId == eventId)
        #expect(eventItem.orderDate == eventTime)
    }
}
